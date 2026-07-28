---
name: squad-incident
description: Conduz Tech Lead em resposta a incidente Sev1/Sev2 em produção (triagem, hotfix, comunicação, post-mortem). Use sob pressão de incidente — passos críticos não podem ser pulados.
---

# Skill — Incident Response (Sev1/Sev2)

Conduz o TL em **resposta a incidente Sev1/Sev2 em produção**. Sob pressão, checklist mental falha — siga esta skill para garantir que nada crítico seja pulado. Definição de severidades e responsabilidades do TL: `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Fluxo de Bug em Produção".

## Quando usar

- Sev1 (sistema fora / dados comprometidos) ou Sev2 (degradação significativa) detectado
- Reportado por usuário, Support Engineer, ou monitoring/alerta

## Quando NÃO usar

- Sev3+ (bug não crítico, workaround existe) → fluxo normal de bug
- Falso alarme antes de confirmar → confirmar primeiro

---

## Sua tarefa como Claude (atuando como TL — Incident Commander)

### 1. CONFIRMAR severidade (≤ 5 min)

NÃO assuma. Confirme:

- [ ] Sintoma observável (logs, métricas, screenshot, reprodução)
- [ ] Escopo do impacto (todos usuários? subset? região?)
- [ ] Duração da indisponibilidade (quando começou?)
- [ ] Se há workaround para usuários

**Se não conseguir confirmar Sev1/Sev2 em ≤5 min → trate como Sev1 (better safe).**

### 2. ABRIR canal de incidente (≤ 5 min)

- Canal dedicado (Slack/Teams) — criar se não existe
- Designar **Incident Commander (IC)** — você (TL) por padrão; pode delegar a DevOps oncall
- Notificar stakeholders: **Sev1** → TL + DevOps + Security Engineer + PO + gerência · **Sev2** → TL + DevOps + agente afetado + PO

### 3. DIAGNOSTICAR causa raiz (paralelo ao mitigation)

- **DevOps** — logs, métricas, infra (deploy recente, falha de dependência, recurso exaurido)
- **Backend/Frontend/Mobile** — agente afetado verifica código suspeito
- **Security Engineer** — se há suspeita de breach

Documentar em tempo real no canal: `[HH:MM] sintoma observado / hipótese testada — resultado / causa raiz identificada`.

### 4. DECIDIR mitigação imediata (ordem de preferência)

1. **Feature flag kill switch** — se feature em flag, desligar (segundos, sem deploy)
2. **Rollback de deploy** — se incidente coincide com deploy recente
3. **Hotfix com revert** — reverter commit causal
4. **Hotfix com correção** — desenvolver e deployar correção mínima
5. **Mitigação manual** — restart de serviço, scaling, etc.

### 5. EXECUTAR mitigação (Sev1: ≤30 min da detecção)

**Sev1** — Code Reviewer detalhado pode ser pulado (responsabilidade sua de TL — registrar decisão). Gates **obrigatórios** mesmo assim:

- [ ] QA fast review (smoke test do hotfix)
- [ ] DevOps validação de pipeline + deploy
- [ ] Security Engineer fast review (se incidente envolve segurança)

**Sev2** — fluxo normal acelerado, sem pular gates: CI verde · QA + Code Reviewer + SE (Fase 2 se aplicável) · Quality Gates · deploy.

### 6. COMUNICAR durante incidente

Cadência mínima por severidade (interna e status page) e infraestrutura de comunicação: `${CLAUDE_PLUGIN_ROOT}/agents/devops-engineer.md` → "Comunicação Durante Incidente" — ler e seguir. Cada update:

```
[HH:MM] STATUS UPDATE
Status: [Investigando / Mitigando / Resolvido / Monitorando]
Impacto: [serviços, % usuários] | Ações em andamento: [...] | Próximo update: [HH:MM]
```

Status page público (Sev1/Sev2): linguagem clara, sem jargão técnico; sem expor detalhes de segurança em breach (LGPD: notificação separada).

### 7. CONFIRMAR resolução

- [ ] Sintoma original cessou (verificar com a fonte que reportou)
- [ ] Métricas voltaram ao baseline · sem novos sintomas relacionados
- [ ] Monitoramento ativo por ≥30min após mitigação (Sev1) ou ≥1h (Sev2)

### 8. POST-MORTEM (blameless)

Prazos obrigatórios: **Sev1 ≤48h** · **Sev2 ≤72h** · Sev3+ opcional (registrar decisão em `.claude/squad/project/DECISIONS_LOG.md`). Estrutura: usar o formato de `${CLAUDE_PLUGIN_ROOT}/agents/devops-engineer.md` → "Post-Mortem Blameless"; ações corretivas com responsável + prazo + tag `post-mortem`.

### 9. PROPAGAR aprendizados

- Runbook em `.claude/squad/project/runbooks/[tipo].md` se incidente é recorrente ou tem mitigação repetível
- `ARCHITECTURE.md` se há mudança estrutural · ADR se decisão técnica relevante
- `DECISIONS_LOG.md` com tag `post-mortem` · ações corretivas no `TASK_BOARD.md`

### 10. RATIFICAR com usuário (se autoridade temporária foi assumida)

Conforme política de indisponibilidade do usuário (`CLAUDE.md`): decisões críticas tomadas durante Sev1 sem aprovação prévia → ratificar com usuário em ≤24h após retorno; registradas com tag `tl-autonomous`.

---

## Anti-patterns (rejeitar)

- Pular comunicação durante incidente "porque está ocupado mitigando" → designe outro IC
- Resolver e esquecer (sem post-mortem) → tag `post-mortem-pendente`

---

- **Owner:** Tech Lead
- **Fonte:** tech-lead.md → "Fluxo de Bug em Produção" · devops-engineer.md → "Comunicação Durante Incidente" e "Post-Mortem Blameless" (paths completos nos passos acima)
