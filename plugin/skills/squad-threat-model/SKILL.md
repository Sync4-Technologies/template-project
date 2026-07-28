---
name: squad-threat-model
description: Conduz Security Engineer em threat modeling Fase 1 sobre arquitetura proposta (antes de contratos finalizados). Use quando feature crítica entra em fase de arquitetura.
---

# Skill — Threat Model (Security Engineer Fase 1)

Conduz o SE em **threat modeling Fase 1** sobre arquitetura proposta — antes de contratos finalizados, antes de implementação. Método, checklists, classificação e anti-patterns vivem em `${CLAUDE_PLUGIN_ROOT}/template/agents/security-engineer.md` — esta skill conduz o fluxo, não duplica o spec.

## Quando usar

- Architect entregou arquitetura proposta (passo 7 do Fluxo 1)
- Feature é **crítica** — definição autoritativa: `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Critério feature crítica"
- Arquitetura ainda permite ajustes (contratos não finalizados)

## Quando NÃO usar

- Feature não é crítica (Fase 1 é obrigatória apenas em críticas)
- Pós-implementação / pentest review → Fase 2 (subagent `security-reviewer`)

---

## Sua tarefa como Claude (atuando como SE)

### 1. Coletar input

Arquitetura proposta (do Architect) · PRD → RNFs (classificação de dados, compliance, auditoria) · `.claude/squad/project/ARCHITECTURE.md` · ADRs relacionados.

### 2. Threat Model (matriz STRIDE adaptada)

Para cada **ativo crítico** identificado, preencher:

```
Ativo: [ex: token JWT, dados de cartão, sessão de usuário]
Classificação: [Público / Interno / Confidencial / Restrito]
Atores: [anônimo, autenticado, insider, sistema externo]
Vetores possíveis: [injection · broken auth · broken authz (IDOR/BOLA) ·
  sensitive data exposure · SSRF · XSS/CSRF · MITM · replay · privilege escalation]
  — feature com LLM: cobrir também a superfície IA de
  security-engineer.md → "Checklist LLM/IA" (ler a seção)
Impacto se sucesso: [breach, indisponibilidade, perda financeira, regulatório]
Probabilidade: [Alta / Média / Baixa]
Mitigação proposta: [controle técnico específico] | Custo: [Baixo / Médio / Alto]
Aprovação do usuário necessária? [sim / não]
```

### 3. Validações específicas (checklists do spec)

Aplicar sobre a arquitetura os checklists de security-engineer.md — **"Revisão de Auth/Authz"**, **"Criptografia"**, **"Compliance"**, **"Padrões obrigatórios de Auth/Token"** e secrets — ler as seções e verificar item a item. Parâmetros e itens de superfície adicionais desta fase:

- [ ] Senhas: Argon2id ou bcrypt cost ≥12 · tokens: expiração ≤15min + refresh rotativo
- [ ] CORS configurado explicitamente (sem `*` com auth) · headers de segurança (CSP, HSTS, X-Frame-Options)
- [ ] Input validation em todas as fronteiras · output encoding correto

### 4. Classificar resultado

**APROVADO / APROVADO COM RECOMENDAÇÕES / REJEITADO** — critérios em security-engineer.md → "Classificação do resultado". Recomendações → `.claude/squad/project/TASK_BOARD.md` com tag `security`; REJEITADO → arquitetura precisa de ajuste.

### 5. Mitigações que exigem aprovação do usuário

Critérios para escalar (mudança arquitetural significativa, custo elevado, prazo, trade-off de produto, compliance de negócio): security-engineer.md → "Mitigações críticas — aprovação do usuário". **TL apresenta ao usuário**; decisão registrada em ADR.

### 6. Reportar ao Tech Lead

```
THREAT MODEL — [Feature] — YYYY-MM-DD — modo [MVP / Production]
Resultado: [APROVADO / APROVADO COM RECOMENDAÇÕES / REJEITADO]
Threats identificados: [N] (críticos/altos: [N]) — tabela do passo 2
Mitigações que exigem aprovação do usuário: [lista]
Recomendações para TASK_BOARD: [lista com prioridade]
Próximo passo: [Architect ajusta / continuar para contratos / apresentar ao usuário]
```

### 7. Loop de feedback com Architect

Threats identificados podem alterar contratos. Architect ajusta arquitetura/contratos antes de prosseguir; re-validação em ≤2 iterações típicas.

---

- **Owner:** Security Engineer · **Par:** Fase 2 roda no subagent `security-reviewer`
- **Fonte:** `${CLAUDE_PLUGIN_ROOT}/template/agents/security-engineer.md` (checklists, classificação, anti-patterns a bloquear)
