---
name: squad-threat-model
description: Conduz Security Engineer em threat modeling Fase 1 sobre arquitetura proposta (antes de contratos finalizados). Use quando feature crítica entra em fase de arquitetura.
---

# Skill — Threat Model (Security Engineer Fase 1)

> **Owner:** Security Engineer | **Revisão:** 90 dias | **Obsolescência:** processo de SE Fase 1 mudar significativamente

Esta skill conduz o SE em **threat modeling Fase 1** sobre arquitetura proposta — antes de contratos finalizados, antes de implementação.

---

## Quando usar

- Architect entregou arquitetura proposta (passo 7 do Fluxo 1)
- Feature é classificada como **crítica** (ver `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Critério feature crítica")
- Arquitetura ainda permite ajustes (contratos não finalizados)

## Quando NÃO usar

- Feature não é crítica (skill é para Fase 1 obrigatória apenas em críticas)
- Arquitetura já está implementada → use Fase 2 manualmente
- Pentest review pós-implementação → use checklist de SE Fase 2

---

## Definição de "feature crítica"

Conforme `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` (fonte autoritativa):

- autenticação e autorização
- processamento de pagamentos
- acesso a dados Confidencial ou Restrito
- integrações com sistemas externos sensíveis
- qualquer rota que processe dados pessoais (LGPD/GDPR)

---

## Sua tarefa como Claude (atuando como SE)

### 1. Coletar input

Antes de iniciar, leia:

- Arquitetura proposta (do Architect)
- PRD → seção RNFs (classificação de dados, compliance, auditoria)
- `.claude/squad/project/ARCHITECTURE.md` (estado atual)
- ADRs relacionados

### 2. Threat Model (matriz STRIDE adaptada)

Para cada **ativo crítico** identificado, preencha:

```
Ativo: [nome — ex: token JWT, dados de cartão, sessão de usuário]
Classificação: [Público / Interno / Confidencial / Restrito]
Atores: [quem pode atacar — anônimo, autenticado, insider, sistema externo]
Vetores possíveis:
  - Injection (SQL, NoSQL, command, LDAP)
  - Broken authentication
  - Broken authorization (IDOR, BOLA)
  - Sensitive data exposure
  - SSRF
  - XSS / CSRF (se aplicável)
  - MITM
  - Replay attacks
  - Privilege escalation
  - Prompt injection (se IA)
Impacto se sucesso: [breach, indisponibilidade, perda financeira, regulatório]
Probabilidade: [Alta / Média / Baixa]
Mitigação proposta: [controle técnico específico]
Custo da mitigação: [Baixo / Médio / Alto]
Aprovação do usuário necessária? [sim / não — sim se mudança arquitetural significativa, custo elevado, ou mudança de escopo]
```

### 3. Validações específicas

#### Auth/Authz
- [ ] Autenticação robusta (MFA quando dados sensíveis)
- [ ] Senhas: Argon2id ou bcrypt cost ≥12
- [ ] Tokens: expiração curta (≤15min) + refresh rotativo
- [ ] Autorização por recurso (não só role) — IDOR/BOLA mitigado
- [ ] Logout invalida sessão no servidor
- [ ] Rate limiting em endpoints de auth

#### Criptografia
- [ ] TLS 1.2+ em trânsito (1.3 preferencial)
- [ ] Dados sensíveis em repouso: AES-256 ou equivalente
- [ ] Sem criptografia customizada (usa libs estabelecidas)
- [ ] Gestão de chaves: rotação documentada, armazenamento seguro (KMS/vault)
- [ ] Sem dados sensíveis em logs / URLs / mensagens de erro

#### Compliance (conforme PRD)
- [ ] **LGPD/GDPR:** consentimento, direito ao esquecimento, portabilidade, notificação de breach
- [ ] **PCI DSS:** dados de cartão via gateway (sem PAN no backend), logs sem PAN
- [ ] **HIPAA:** PHI criptografado, auditoria de acesso

#### Secrets
- [ ] Sem segredos em código
- [ ] Sem segredos em logs
- [ ] Variáveis de ambiente protegidas (vault, secrets manager)
- [ ] Rotação documentada

#### Surface de ataque
- [ ] CORS configurado explicitamente (sem `*` com auth)
- [ ] Headers de segurança (CSP, HSTS, X-Frame-Options)
- [ ] Input validation em todas as fronteiras
- [ ] Output encoding correto

### 4. Classificar resultado

- **APROVADO** — sem vulnerabilidades críticas/altas
- **APROVADO COM RECOMENDAÇÕES** — vulnerabilidades baixas/médias; registrar em `.claude/squad/project/TASK_BOARD.md` com tag `security`
- **REJEITADO** — vulnerabilidade crítica/alta; arquitetura precisa ajuste

### 5. Mitigações que exigem aprovação do usuário

Quando mitigação implica:
- Mudança arquitetural significativa
- Custo elevado (operacional ou licença)
- Impacto em prazo
- Trade-off de produto
- Compliance que exige decisão de negócio

→ **TL apresenta ao usuário**. Decisão registrada em ADR.

### 6. Reportar ao Tech Lead

Formato:

```
THREAT MODEL — [Feature]
Data: [YYYY-MM-DD]
Modo: [MVP / Production]

Resultado: [APROVADO / APROVADO COM RECOMENDAÇÕES / REJEITADO]

Threats identificados: [N]
Threats críticos/altos: [N]

Tabela de threats: [conforme passo 2]

Mitigações que exigem aprovação do usuário: [lista]

Recomendações para TASK_BOARD: [lista de ações com prioridade]

Próximo passo: [Architect ajusta / Continuar para contratos / Apresentar ao usuário]
```

### 7. Loop de feedback com Architect

Threats identificados podem alterar contratos. Architect ajusta arquitetura/contratos antes de prosseguir. Re-validação em ≤ 2 iterações típicas.

---

## Anti-patterns (rejeitar)

- Tokens sem expiração
- Senhas em texto plano ou hash fraco (MD5, SHA1)
- Autorização apenas por role (sem verificação de recurso)
- Dados sensíveis em logs ou URLs
- CORS aberto (`*`) com autenticação
- Criptografia customizada
- Ausência de rate limiting em endpoints de auth
- Default-allow em flag de auth/authz quando serviço de flags indisponível

---

## Referências

- Regras de SE: `${CLAUDE_PLUGIN_ROOT}/template/agents/security-engineer.md`
- ADR Hexagonal: `${CLAUDE_PLUGIN_ROOT}/template/memory/ADR/ADR-002-arquitetura-hexagonal.md`
- ADR Feature Flags: `${CLAUDE_PLUGIN_ROOT}/template/memory/ADR/ADR-003-feature-flags.md`
- OWASP Top 10: <https://owasp.org/www-project-top-ten/>
- STRIDE: <https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats>
