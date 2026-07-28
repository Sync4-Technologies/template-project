# ARCHITECTURE.md — dev-squad (upstream)

> Fonte de verdade da arquitetura deste repositório. Atualizar a cada mudança estrutural.
> Última atualização: 2026-07-28 (v1.9.0: 16ª skill /squad-audit + template feature-spec)

---

## Propósito

Este repositório é o **upstream do plugin `dev-squad`** (marketplace `pdati`): aqui o plugin é desenvolvido, testado, versionado e publicado. Não há código de produto — a arquitetura do antigo produto AgentesIA está em `archive/agentesia/ARCHITECTURE.md`.

## Estrutura

```
plugin/                      # o plugin em si (fonte publicada)
├── agents/                  # 11 subagents nativos (engineers, QA, reviewers, advisor)
├── skills/                  # 16 skills /squad-* (resume, handoff, init, audit, preflight, ...)
├── hooks/                   # hooks.json + load-memory, push-gate, reminders
├── scripts/                 # scripts internos do plugin
└── template/                # templates copiados por /squad-init (agents main-thread, ADRs, memória)
scripts/ci/                  # checks do plugin-ci (rodáveis localmente)
docs/                        # planos de release e diagnósticos do plugin
.claude/squad/project/       # memória viva DESTE repo (board, decisões, lessons)
memory/                      # memória auxiliar
```

## Fluxo de release

1. Branch `feat/*` ou `chore/*` → PR para `develop` (plugin-ci: 4 jobs)
2. PR `develop` → `main` (release)
3. Tag `vX.Y.Z` + `claude plugin marketplace update pdati` + `claude plugin update dev-squad@pdati`
4. Plugin aplica na sessão seguinte (restart)

Versão instalada user-scope; projetos consumidores (ex.: trokey-franchising) reconciliam governança via `SQUAD_VERSION`.

## CI e proteção de branch

- **plugin-ci** (4 jobs obrigatórios): scripts em `scripts/ci/*.py` + `hooks-smoke.sh` + `claude plugin validate` — todos rodáveis localmente antes do push.
- Branch protection em `develop` e `main` com `enforce_admins` (sem porta dos fundos).
- `runs-on: ${{ vars.CI_RUNNER || 'ubuntu-latest' }}` — variável `CI_RUNNER=self-hosted` roteia para runner local (UP-08, contorno do billing); remover a variável restaura GitHub-hosted.

## Validação em batalha

Mudanças do plugin são validadas em projetos reais (trokey-franchising é o campo atual). Achados viram entradas em `LESSONS_LEARNED.md` (UP-*/AM-*) e alimentam a próxima release.
