# ADR-006 — Egress HTTP seguro contra SSRF e DNS rebinding

**Status:** Aceita
**Data:** 2026-06-01
**Autor:** Architect + Security Engineer (orquestrado pelo Tech Lead)
**Relacionado:** SEC-001, DEBT-011 (TASK_BOARD)

---

## Contexto

A tool `send_to_webhook` (`core/tools/send_to_webhook/handler.py`) envia dados para uma
`webhook_url` controlada pelo tenant **sem nenhuma validação** — fazendo `httpx.post(webhook_url, ...)`
direto. Isso é um vetor de **SSRF** real: um tenant pode apontar o webhook para
`http://169.254.169.254/...` (metadata de cloud), `http://127.0.0.1`, ou serviços internos da VPC.

O guard existente `validate_external_url` (`core/security.py`) já era aplicado ao adapter
Evolution, mas tem duas limitações:

1. **Não era chamado** pela tool `send_to_webhook` (SEC-001).
2. Sofre de **TOCTOU / DNS rebinding** (DEBT-011): ele resolve o DNS, valida que os IPs são
   públicos e retorna a **string da URL**. O `httpx` depois resolve o DNS **de novo** no momento
   do connect. Um atacante com DNS de TTL baixo faz o hostname resolver para um IP público durante
   a validação e para um IP interno (169.254.169.254 / 10.x) no envio real.

Em **Production Mode**, qualquer rota/feature que processe URL fornecida por tenant é feature
crítica e exige Security Engineer.

---

## Decisão

**Toda requisição HTTP de saída para URLs controladas por tenant deve passar por um helper único
que valida, resolve, fixa (pin) o IP público e conecta diretamente nesse IP** — eliminando a
janela de rebinding.

1. `core/security.py` passa a expor `resolve_validated_url(url) -> ValidatedTarget`, que valida
   (HTTPS obrigatório, hostname não bloqueado, **todos** os IPs resolvidos públicos) e retorna o
   alvo já resolvido (hostname, porta e IPs públicos fixados). `validate_external_url` é mantido
   (retorna a string) para compatibilidade com os callers atuais.
2. Novo módulo `core/safe_http.py` com `safe_post(...)`:
   - resolve+valida via `resolve_validated_url`;
   - conecta no **IP fixado** (`https://<ip>:<porta>/...`);
   - preserva `Host:` original e usa `extensions={"sni_hostname": hostname}` para que o
     **handshake TLS e a verificação de certificado continuem contra o hostname real** (cert não
     quebra, e não há segunda resolução DNS).
3. `send_to_webhook` passa a usar `safe_post`; URL inválida/bloqueada vira erro tratado para o LLM
   (não exceção não capturada).

---

## Alternativas Consideradas

### Alternativa 1 — Só chamar `validate_external_url` antes do post (fix mínimo do SEC-001)
- **Prós:** 1 linha, simples.
- **Contras:** não fecha DEBT-011 — a segunda resolução do httpx reabre o rebinding.
- **Motivo da rejeição:** o usuário pediu SEC-001 + DEBT-011 juntos; fix parcial deixaria o vetor aberto.

### Alternativa 2 — Resolver e passar a URL com IP, sem SNI
- **Prós:** elimina rebinding.
- **Contras:** quebra a verificação TLS (certificado é do hostname, não do IP) → ou erro de cert
  ou `verify=False` (inaceitável).
- **Motivo da rejeição:** abriria mão de verificação de certificado.

### Alternativa 3 — Resolver dependente de transporte custom (resolver hook no httpcore)
- **Prós:** centraliza no transporte.
- **Contras:** mais acoplamento/complexidade do que o ganho; httpx não expõe hook de DNS estável.
- **Motivo da rejeição:** KISS — `sni_hostname` extension resolve com menos código.

---

## Trade-offs Assumidos

- Abrimos mão de seguir redirects automaticamente nesse caminho (um redirect para destino interno
  reabriria SSRF). `safe_post` não segue redirect; se o webhook depender de 3xx, o cliente trata.
- Pin no **primeiro** IP público resolvido; se o host tem múltiplos IPs e um falha, não há failover
  nessa entrega (aceitável para webhook de saída).

---

## Consequências

### Positivas
- SEC-001 fechado: `send_to_webhook` valida a URL.
- DEBT-011 fechado: sem janela de rebinding (conecta no IP validado, TLS contra hostname real).
- Helper reutilizável (`safe_post`) para futuros egressos de tenant.

### Negativas / Riscos
- IPv6 e hosts multi-IP têm cobertura simples (primeiro IP). Documentado.

### Neutras (mudanças operacionais)
- Adapter **Evolution** (`core/channel/evolution.py`) usa `base_url` de tenant com `httpx` puro e
  valida só na escrita (connections router) — **superfície residual de rebinding**. Fica como
  follow-up (novo card SEC-003) para migrar para `safe_post`; fora do escopo desta entrega.
- Adapter **Z-API** usa host fixo `api.z-api.io` (não controlado por tenant) — sem ação.

---

## Critérios de Revisão

Esta decisão deve ser revisada se:
- httpx mudar o contrato de `extensions["sni_hostname"]`.
- Surgir necessidade de failover entre múltiplos IPs ou de seguir redirects com revalidação por hop.
- Egress de tenant crescer a ponto de justificar um proxy de saída dedicado (egress gateway).
