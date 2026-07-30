# CLAUDE.md — dev-squad (upstream do plugin)

> Este arquivo prevalece sobre ~/.claude/CLAUDE.md global.
> Governança para o desenvolvimento do **plugin dev-squad** (marketplace pdati).

---

## Contexto do projeto

Este repositório é o upstream do plugin `dev-squad`: aqui o plugin é desenvolvido, testado, versionado e publicado. O repo consome o próprio plugin (dogfooding, decisão D1 de 2026-07-05).

O produto AgentesIA que originou este repo está **arquivado** em `.claude/squad/project/archive/agentesia/` (2026-07-26). Não há código de produto aqui.

**Modo de operação: Production Mode**

---

## Agentes ativos neste projeto

| Agente | Foco |
|--------|------|
| Tech Lead | Orquestração, releases, quality gates, LESSONS |
| DevOps Engineer | CI (plugin-ci), runner, branch protection |
| QA Engineer | Checks locais, smoke de hooks |
| Code Reviewer | Qualidade de skills/hooks/agents do plugin |

Trabalho aqui é majoritariamente de **sistema** (governança, skills, hooks, templates) — engineers de produto (backend/frontend/mobile) raramente são acionados.

---

## Fontes de verdade

| Tópico | Arquivo |
|--------|---------|
| Arquitetura do repo | `.claude/squad/project/ARCHITECTURE.md` |
| Backlog | `.claude/squad/project/TASK_BOARD.md` |
| Decisões + Session Log | `.claude/squad/project/DECISIONS_LOG.md` |
| Lições (UP-*/AM-*) | `.claude/squad/project/LESSONS_LEARNED.md` |
| Versão da governança | `.claude/squad/project/SQUAD_VERSION` |
| Produto arquivado | `.claude/squad/project/archive/agentesia/` |

---

## Regras críticas do projeto

1. **Toda mudança em skill/hook/agent roda os checks locais ANTES de commitar**: `scripts/ci/*.py`, `plugin/hooks` smoke, `claude plugin validate` — pegaram bugs reais em toda release. **Isto é máquina, não prosa:** `.githooks/pre-commit` roda os 4 e grava o marcador do push-gate. `core.hooksPath` é config local (não versionável) — em clone novo, rodar uma vez: `git config core.hooksPath .githooks`
2. Release segue o fluxo: branch → PR `develop` (plugin-ci verde) → PR `develop`→`main` → tag `vX.Y.Z` → `claude plugin marketplace update pdati` + `claude plugin update dev-squad@pdati`
3. Plugin atualizado **só aplica na sessão seguinte** — nunca assumir que a sessão atual roda a versão recém-instalada (UP-01/UP-09)
4. Branch protection com `enforce_admins` em `develop` e `main` — sem porta dos fundos; exceção via ritual documentado (UP-02)
5. Mudança validada em batalha antes de considerar madura: campo atual é trokey-franchising; achados viram LESSONS (UP-*/AM-*)
6. Versionamento SemVer; breaking change em skill/hook = major-minor com `!` no commit
7. Nunca commitar `.env` ou credenciais; tokens de runner/registro não vão para o repo

---

## Gates obrigatórios

| Gate | Quem decide | Bloqueia |
|------|------------|---------|
| Checks locais verdes | Engineer | Commit |
| plugin-ci verde (4 jobs) | Pipeline | Merge em develop/main |
| Code Reviewer aprovou | CR | Release |
| LESSONS atualizado | TL | Encerramento de release com achados |

---

## Contexto para carregar no início de cada sessão

O hook SessionStart já carrega head de ARCHITECTURE/TASK_BOARD/DECISIONS_LOG. Se retomando sessão: rodar `/squad-resume` para o Tech Lead apresentar o estado.
