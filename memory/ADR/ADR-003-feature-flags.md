# ADR-003 — Feature Flags como Default em Features Críticas

**Status:** Aceita
**Data:** 2026-05-09
**Autor:** Architect

---

## Contexto

A squad opera com modos MVP e Production. Em ambos, há necessidade de:
- desacoplar deploy de release (deploy != release)
- permitir rollback sem redeploy (kill switch instantâneo)
- habilitar canary trivial (rollout gradual via percentual)
- viabilizar A/B testing
- mitigar risco de features novas em produção

Estratégia atual de "feature flags só em casos de risco" subutiliza essas capacidades. Em projetos com cadência alta de deploy, flag default amplia drasticamente a flexibilidade operacional.

---

## Decisão

**Toda feature crítica nova entra atrás de feature flag por padrão.**

Critério "feature crítica" (definido no CLAUDE.md raiz e tech-lead.md):
- autenticação e autorização
- processamento de pagamentos
- acesso a dados Confidencial ou Restrito
- integrações com sistemas externos sensíveis
- qualquer rota que processe dados pessoais (LGPD/GDPR)
- qualquer mudança que afete fluxo crítico de negócio

Features não-críticas (UI tweaks, refactors internos, docs) podem ir sem flag.

---

## Ferramenta padrão

Architect decide por projeto entre:

| Ferramenta | Tipo | Quando usar |
|-----------|------|-------------|
| **LaunchDarkly** | SaaS | Times maduros, alto volume, A/B testing avançado |
| **Unleash** | Self-hosted (open-source) | Quando dados não podem sair da infra; controle total |
| **Flipt** | Lightweight self-hosted | Projetos pequenos; baixa complexidade operacional |
| **Homegrown** | Construído internamente | Apenas em casos extremos (ex: compliance proíbe) — Architect justifica em ADR |

Decisão registrada em ADR específico do projeto.

---

## Governança Obrigatória

### Toda flag tem
- **Dono** (Tech Lead ou Product Owner)
- **Prazo de remoção** (data definida no momento da criação; default 90 dias)
- **Tipo:** `release`, `experiment`, `ops` (kill switch), `permission`
- **Kill switch testado** em staging antes do go-live

### Flag > 90 dias
- Tag `tech-debt` aplicada
- Entra em backlog (`memory/TASK_BOARD.md`) para remoção
- Revisada em review mensal de flags

### Review mensal
- Tech Lead coordena
- Lista todas as flags ativas
- Decide: manter / remover / promover (rollout 100% e remover código condicional)
- Resultado registrado em `memory/DECISIONS_LOG.md`

### Testes
- Cobrir ambos os paths (on / off)
- Em features críticas, ambos os caminhos passam pelo CI
- QA inclui cenário de "flag desligada em produção" se aplicável

---

## Aplicação por agente

### Backend Engineer
- Flag check no entry point (controller ou use case)
- NÃO espalhar `if flag.enabled` por todo o código
- Implementação condicional via Hexagonal: adapter A vs adapter B selecionado por flag

### Frontend Engineer
- Flag fetch + cache local + fallback determinístico se servidor indisponível
- Componentes condicionais no nível de rota ou organism, não em atoms

### Mobile Engineer
- **Atenção especial:** mobile não pode forçar update
- Flags devem funcionar offline (cache local persistente)
- Flags persistem em versões antigas do app (server-driven)
- SDK do provedor com retry e fallback

### AI Engineer
- Versão de prompt atrás de flag (`prompt_v1` vs `prompt_v2`)
- Permite rollout gradual de prompts e A/B testing
- Flag por adapter de LLM (provedor primário vs fallback)

### DevOps Engineer
- Pipeline valida que feature flag está definida antes do deploy
- Monitora consumo de flags (uso, latência da API de flags)
- Configura observabilidade por flag (qual % de tráfego em qual variante)

### QA Engineer
- Testes cobrem on/off em features críticas
- Cenário "flag não disponível" → fallback determinístico funciona

### Code Reviewer
- Flag check só no entry point (rejeita espalhamento)
- Garante que ambos os caminhos têm teste

### Security Engineer
- Considera flags como kill switch de segurança (vuln descoberta → desliga feature em segundos sem deploy)
- Valida que flag de auth/authz é à prova de falhas (default-deny se serviço de flags indisponível)

---

## Alternativas Consideradas

### Manter status quo (flags só em risco/coordenação)
- **Prós:** menos complexidade, menos flags antigas
- **Contras:** rollback exige deploy, canary manual, A/B testing limitado
- **Status:** rejeitado — perde flexibilidade operacional crítica

### Flags em todas as features (sem critério)
- **Prós:** máxima flexibilidade
- **Contras:** explosão de flags antigas, matrix de teste impraticável, complexidade alta
- **Status:** rejeitado — overhead supera benefício em features triviais

### Trunk-based sem flags (deploy direto)
- **Prós:** simplicidade extrema
- **Contras:** rollback caro, sem canary, sem A/B
- **Status:** aceitável só em projetos super pequenos

---

## Trade-offs Assumidos

- Complexidade de matrix de teste (on/off por flag) — mitigado por governança rígida
- Tech debt de flags antigas — mitigado por prazo de 90 dias e review mensal
- Custo de ferramenta SaaS (LaunchDarkly) — mitigado por opção self-hosted (Unleash/Flipt)
- Code paths múltiplos exigem disciplina de revisão

---

## Consequências

### Positivas
- Deploy desacoplado de release
- Kill switch instantâneo (resposta rápida a incidentes/vulns)
- Canary trivial via flag percentual
- A/B testing fácil
- Combina excepcionalmente bem com Hexagonal (adapter trocável por flag)
- Permite "deploy frequente, release coordenado"

### Negativas / Riscos
- Sem governança → flags antigas viram tech debt explosivo
- Complexidade de teste pode crescer
- Custo de ferramenta SaaS

### Neutras
- Convenção de nomenclatura de flags (snake_case, prefixo por área)
- Documentação de cada flag em código (comentário + link para issue/ADR)

---

## Critérios de Revisão

Esta decisão deve ser revisada se:
- Custo de ferramenta tornar-se proibitivo
- Governança não conseguir conter explosão de flags antigas (>50 ativas sem dono)
- Projeto for tão pequeno que default não se justifique
