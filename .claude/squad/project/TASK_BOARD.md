# TASK_BOARD.md — dev-squad (upstream)

> Kanban da squad. Este repo mantém e evolui o **plugin dev-squad**. Produto AgentesIA arquivado em `archive/agentesia/` (2026-07-26).

---

## Current Focus

- **Ultima sessao:** 2026-07-26 por Pablo (3a sessao do dia: governanca reconciliada — repo assumido como upstream do plugin; produto AgentesIA arquivado; UP-08 em execucao)
- **Em andamento:** GOV-UPSTREAM no PR #41 (CI 4/4 verde no runner self-hosted — primeira vez sem danca de protection desde o billing morrer)
- **Proximo passo:** 1) merge PR #41 -> develop -> main, tag v1.8.1, marketplace update; 2) batalha trokey em sessao nova (plugin 1.8.1)
- **Bloqueios:** nenhum — UP-08 ativo contorna o billing (revert quando billing voltar ~2026-08-01: card UP-08-REVERT)
- **Branch ativo:** chore/governanca-upstream-up08 (worktree suspicious-meninsky)
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
| BATALHA-TROKEY | Validação em batalha do plugin 1.8.0 no trokey-franchising | TL | Sessão nova lá; achados → LESSONS → v1.9 |
| UP-08-REVERT | Quando billing voltar (~2026-08-01): `gh variable delete CI_RUNNER` nos 2 repos + desligar runner | DevOps | Runbook: trokey `ops/self-hosted-runner.md` §"Quando o billing voltar" |

---

## 🔵 Doing

| ID | Tarefa | Agente | Responsável |
|----|--------|--------|------------|
| GOV-UPSTREAM | Governança reconciliada: board/arquitetura/CLAUDE.md refletem upstream do plugin; AgentesIA arquivado | TL | TL (PR #41 — CI verde, aguardando merge) |

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

**Histórico do produto AgentesIA:** ver `archive/agentesia/TASK_BOARD.md`.
