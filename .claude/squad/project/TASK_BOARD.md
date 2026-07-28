# TASK_BOARD.md — dev-squad (upstream)

> Kanban da squad. Este repo mantém e evolui o **plugin dev-squad**. Produto AgentesIA arquivado em `archive/agentesia/` (2026-07-26).

---

## Current Focus

- **Ultima sessao:** 2026-07-28 por Pablo (2a do dia: Fase 1 dieta de tokens executada e released — v1.10.0; checklist de batalha trokey preparado)
- **Em andamento:** nada — PRs #47/#48/#49 mergeados; v1.10.0 released e instalada (aplica na proxima sessao)
- **Proximo passo:** BATALHA TROKEY em sessao nova com plugin 1.10.0 — estreia do reviewer cacador em PR real + primeira rodada da governanca enxuta. Reconciliacao la e 1.6->1.10.0: usar o checklist entregue na sessao (blocos A/B validos; versao-alvo agora 1.10.0; item novo: /squad-design substitui o trio de design)
- **Bloqueios:** nenhum — runner self-hosted ativo contorna billing (revert ~2026-08-01: card UP-08-REVERT)
- **Branch ativo:** main (worktree squad-resume-0af529 encerrado no handoff)
- **Modo do projeto:** Production

---

## 🔴 Bloqueante

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| — | — | — | — |

---

## 🟠 Todo

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| BATALHA-TROKEY | Validação em batalha do plugin 1.10.0 no trokey-franchising (reviewer caçador + governança enxuta da Fase 1) | TL | Sessão nova lá; reconciliação 1.6→1.10.0 com checklist entregue; achados → LESSONS → próxima release |
| FASE-1C | Dieta opcional: stack-conventions ~1.100 linhas cortáveis (genérico fora; gotchas/comandos ficam) | TL | Baixa prioridade — carrega sob demanda, não pesa em toda sessão |
| FASE-2 | Performance/fluxo (hooks early-exit, fast lane, qualificar "feature crítica") | TL | [plano](docs/PLANO_EVOLUCAO_SQUAD.md) |
| FASE-3 | Métricas acionáveis + OTEL degrau 1 | TL | [plano](docs/PLANO_EVOLUCAO_SQUAD.md) |
| UP-08-REVERT | Quando billing voltar (~2026-08-01): `gh variable delete CI_RUNNER` nos 4 repos + desligar runner | DevOps | Runbook: trokey `ops/self-hosted-runner.md` §"Quando o billing voltar" |

---

## 🔵 Doing

| ID | Tarefa | Agente | Responsável |
|----|--------|--------|------------|
| — | — | — | — |

---

## 🔵 Review

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| — | — | — | — |

---

## ✅ Done (sistema — releases do plugin)

| ID | Entrega | Concluído em |
|----|---------|-------------|
| v1.0.0–v1.5.0 | Squad empacotada como plugin (marketplace pdati); IA no centro, squad-core dedup, plugin-ci/push-gate/metrics, frontend-design, rename dev-squad | 2026-07-05 (PRs #12–#28) |
| v1.6.0 | 11 subagents nativos + advisor, Protocolo de Dúvida, Modo Delegado, UP-01 | 2026-07-26 (PRs #31/#32) |
| v1.7.0 | Backport trokey AM-18..35 (AM-18 era regressão da 1.6.0) | 2026-07-26 (PRs #33–#36) |
| v1.8.0 | Push-gate advisory, menção≠execução, skip inline, CI_RUNNER, ciclo update handoff/resume, delegação de merge | 2026-07-26 (PRs #37/#38, tag `58713b4`) |
| UP-08 | Runner self-hosted org-level `sync4-mac-local` + `CI_RUNNER=self-hosted` (template-project, trokey, concilia, contracts-) + UP-10 (setup-python condicional) — 4/4 jobs verdes no PR #41 | 2026-07-26 |
| GOV-UPSTREAM | Governança upstream: AgentesIA arquivado, board/ARCHITECTURE/CLAUDE.md reescritos, SQUAD_VERSION reconciliado — v1.8.1 | 2026-07-28 (PRs #41/#42, tag `90e95f3`) |
| FASE-0 | Reviewer caçador (opus, 3 passadas, contrato de evidência), QA executa, mini-spec SDD, anti-ancoragem, métrica desinvertida, /squad-audit, squad-core §G — v1.9.0 | 2026-07-28 (PRs #43/#44, tag `eb71355`) |
| FASE-1 | Dieta de tokens −6.058 linhas: squad-core §H-§N fonte única, tech-lead 1012→268, 15 specs + 12 skills enxutos, /squad-design funde trio (BREAKING), handoff §3 direto, bugs B1-B5, changelog 1.9.0 retroativo — v1.10.0 | 2026-07-28 (PRs #47/#48/#49, tag `6676309`) |
| CHECKLIST-TROKEY | Checklist de reconciliação 1.6→1.10 + batalha preparado com estados verificados no repo trokey (espelho contracts/, gate órfão, specs/) | 2026-07-28 (entregue ao usuário) |

**Histórico do produto AgentesIA:** ver `archive/agentesia/TASK_BOARD.md`.
