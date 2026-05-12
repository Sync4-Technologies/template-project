---
name: squad-incident
description: Conduz Tech Lead em resposta a incidente Sev1/Sev2 em produção (triagem, hotfix, comunicação, post-mortem). Use sob pressão de incidente — passos críticos não podem ser pulados.
---

# Skill — Incident Response (Sev1/Sev2)

> **Owner:** Tech Lead | **Revisão:** 90 dias | **Obsolescência:** processo de incidente mudar significativamente

Esta skill conduz o TL em **resposta a incidente Sev1/Sev2 em produção**. Sob pressão, checklist mental falha — siga esta skill para garantir que nada crítico seja pulado.

---

## Quando usar

- Sev1 detectado (sistema fora / dados comprometidos)
- Sev2 detectado (degradação significativa)
- Reportado por usuário, Support Engineer, ou monitoring/alerta

## Quando NÃO usar

- Sev3+ (bug não crítico, workaround existe) → fluxo normal de bug
- Falso alarme antes de confirmar → confirmar primeiro

---

## Classificação de severidade

| Severidade | Critério | Resposta |
|-----------|---------|----------|
| **Sev1** | Sistema indisponível para todos / dados comprometidos / falha de segurança ativa | Hotfix imediato; post-mortem ≤48h |
| **Sev2** | Degradação significativa para maioria / funcionalidade crítica indisponível com workaround impraticável | Fluxo acelerado sem pular gates; post-mortem ≤72h |
| **Sev3+** | Bug não crítico, workaround simples | Backlog normal |

---

## Sua tarefa como Claude (atuando como TL — Incident Commander)

### 1. CONFIRMAR severidade (≤ 5 min)

NÃO assuma. Confirme:

- [ ] Sintoma observável (logs, métricas, screenshot, reprodução)
- [ ] Escopo do impacto (todos usuários? subset? região?)
- [ ] Duração da indisponibilidade (quando começou?)
- [ ] Se há workaround para usuários

**Se não conseguir confirmar Sev1/Sev2 em ≤5 min → trate como Sev1 (better safe)**.

### 2. ABRIR canal de incidente (≤ 5 min)

- Canal dedicado (Slack/Teams) — criar se não existe
- Designar **Incident Commander (IC)** — você (TL) por padrão; pode delegar a DevOps oncall
- Notificar stakeholders conforme severidade:
  - **Sev1:** TL + DevOps + Security Engineer + PO + gerência
  - **Sev2:** TL + DevOps + agente afetado + PO

### 3. DIAGNOSTICAR causa raiz (paralelo ao mitigation)

Equipe paralela:

- **DevOps** — logs, métricas, infra (verificar deploy recente, falha de dependência, recurso exaurido)
- **Backend/Frontend/Mobile** — agente afetado verifica código suspeito
- **Security Engineer** — se há suspeita de breach

Documente em tempo real no canal:
```
[HH:MM] Sintoma observado
[HH:MM] Hipótese 1 testada — resultado
[HH:MM] Causa raiz identificada — [descrição]
```

### 4. DECIDIR mitigação imediata

Opções (em ordem de preferência):

1. **Feature flag kill switch** — se feature em flag, desligar (segundos, sem deploy)
2. **Rollback de deploy** — se incidente coincide com deploy recente
3. **Hotfix com revert** — reverter commit causal
4. **Hotfix com correção** — desenvolver e deployar correção mínima
5. **Mitigação manual** — restart de serviço, scaling, etc.

### 5. EXECUTAR mitigação (Sev1: ≤30 min de detecção)

#### Para Sev1: hotfix pode pular Code Reviewer detalhado

Gates **obrigatórios** mesmo em Sev1:
- [ ] QA fast review (smoke test do hotfix)
- [ ] DevOps validação de pipeline + deploy
- [ ] Security Engineer fast review (se incidente envolve segurança)

Code Reviewer **detalhado** pode ser pulado em Sev1 (responsabilidade sua de TL — registrar decisão).

#### Para Sev2: fluxo normal acelerado (sem pular gates)
- CI verde
- QA + Code Reviewer + Security Engineer (Fase 2 se aplicável)
- Quality Gates
- Deploy

### 6. COMUNICAR durante incidente

#### Cadência mínima (conforme `.claude/squad/template/agents/devops-engineer.md`)

| Severidade | Update interno | Update externo (status page) |
|-----------|---------------|------------------------------|
| Sev1 | a cada 15min | a cada 30min |
| Sev2 | a cada 30min | a cada 1h |
| Sev3+ | quando relevante | opcional |

#### Conteúdo de cada update
```
[HH:MM] STATUS UPDATE
Status: [Investigando / Mitigando / Resolvido / Monitorando]
Impacto: [serviços afetados, % usuários]
Ações em andamento: [o que está sendo feito agora]
Próximo update: [HH:MM]
```

#### Status page público (Sev1/Sev2)
- Atualizar em statuspage.io ou equivalente
- Linguagem clara, sem jargão técnico
- Sem expor detalhes de segurança em breach (LGPD: notificação separada)

### 7. CONFIRMAR resolução

Antes de declarar resolvido:
- [ ] Sintoma original cessou (verificar com a fonte que reportou)
- [ ] Métricas voltaram ao baseline
- [ ] Sem novos sintomas relacionados
- [ ] Monitoramento ativo por ≥ 30min após mitigação (Sev1) ou ≥ 1h (Sev2)

### 8. POST-MORTEM (blameless)

#### Prazos obrigatórios
- **Sev1:** ≤ 48h após resolução
- **Sev2:** ≤ 72h após resolução
- **Sev3+:** opcional; registrar decisão em `.claude/squad/project/DECISIONS_LOG.md`

#### Estrutura (formato em `.claude/squad/template/agents/devops-engineer.md`)

```
POST-MORTEM — [título]
Data/hora do incidente: [início] - [fim]
Duração: [tempo total]
Severidade: [Sev1/Sev2]
Impacto: [usuários, serviços, financeiro]

Timeline:
[HH:MM] Evento 1
[HH:MM] Evento 2
...

Root Cause: [descrição técnica]

Fatores contribuintes:
- [fator 1]
- [fator 2]

O que funcionou bem:
- [item]

O que não funcionou:
- [item]

Ações corretivas:
| Ação | Responsável | Prazo | Tag |
|------|-------------|-------|-----|
| [ação 1] | [quem] | [data] | post-mortem |

Lições aprendidas:
- [lesson]
```

### 9. PROPAGAR aprendizados

- Adicionar runbook em `.claude/squad/project/runbooks/[tipo].md` se incidente é recorrente ou tem mitigação repetível
- Atualizar `.claude/squad/project/ARCHITECTURE.md` se há mudança estrutural
- Criar ADR se decisão técnica relevante foi tomada
- Atualizar `.claude/squad/project/DECISIONS_LOG.md` com tag `post-mortem`
- Adicionar ações corretivas em `.claude/squad/project/TASK_BOARD.md`

### 10. RATIFICAR com usuário (se autoridade temporária foi assumida)

Conforme política de indisponibilidade do usuário (`CLAUDE.md`):
- Se você assumiu decisões críticas durante Sev1 sem aprovação prévia
- Ratificar com usuário em ≤ 24h após retorno
- Decisões registradas com tag `tl-autonomous`

---

## Anti-patterns (rejeitar)

- Pular comunicação durante incidente "porque está ocupado mitigando" → designe outro IC
- Hotfix sem QA fast review → bloquear, mesmo em Sev1
- Hotfix sem Security Engineer review se incidente envolve segurança
- Post-mortem culpando indivíduos (blameless é obrigatório)
- Resolver e esquecer (sem post-mortem) → tag `post-mortem-pendente`
- Comunicar resolvido antes de confirmar (≥30min de monitoramento)

---

## Referências

- TL flow Sev1/Sev2/Sev3+: `.claude/squad/template/agents/tech-lead.md` → "Fluxo de Bug em Produção"
- DevOps incident comm: `.claude/squad/template/agents/devops-engineer.md` → "Comunicação Durante Incidente"
- Post-mortem template: `.claude/squad/template/agents/devops-engineer.md` → "Post-Mortem Blameless"
- CLAUDE.md: "Fluxo de Bug em Produção"
