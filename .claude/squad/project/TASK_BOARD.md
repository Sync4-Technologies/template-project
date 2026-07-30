# TASK_BOARD.md — dev-squad (upstream)

> Kanban da squad. Este repo mantém e evolui o **plugin dev-squad**. Produto AgentesIA arquivado em `archive/agentesia/` (2026-07-26).

---

## Current Focus

- **Ultima sessao:** 2026-07-29/30 por Pablo (sessao longa; 4 releases: v1.10.0 dieta, v1.11.0 backport da batalha, v1.12.0 migracao automatizada, v1.13.0 reconciliacao automatica)
- **Em andamento:** nada. PRs #47-#62 mergeados; v1.13.0 released e instalada (aplica na proxima sessao). `develop` == `main` == `2b5881c`
- **Proximo passo:** FASE-2 do plano (docs/PLANO_EVOLUCAO_SQUAD.md itens 2.1-2.5: fundir os 2 hooks PreToolUse com early-exit, tirar `gh pr view` do caminho sincrono, fast lane no TL, qualificar "feature critica", M0+delegacao de merge). A batalha trokey JA ACONTECEU e validou a Fase 0 — o plano pedia essa validacao antes da Fase 2, e ela veio
- **Bloqueios:** nenhum no upstream
- **Branch ativo:** main
- **Modo do projeto:** Production

### Resultado da batalha (o que a Fase 0 provou em campo)

`achados-review=12` no marco M4 do trokey (2 MAJOR provados por execucao, corrigidos com teste permanente) contra **291 testes verdes** e um historico de 24 PRs com zero achados. QA executou 14/14 criterios. O criterio de sucesso da Fase 0 esta atingido: `0 achados` deixou de ser o normal.

### Estado dos 3 projetos consumidores (verificado nesta sessao)

| Projeto | SQUAD_VERSION | Gate local | Pendencia |
|---|---|---|---|
| trokey-franchising | 1.12.0 | conectado (`.husky/pre-push`), verde | CI remoto vermelho pelo flake `vehicle-lookup` (AM-41 sem fix definitivo: falta namespace de chaves por run) + **sem branch protection** — ligar so depois do flake |
| concilia | 1.12.0 | conectado, verde | migrado de template clonado (13 skills locais) nesta sessao; AM-30 resolvido |
| jobtracker | 1.12.0 | conectado, verde | AM-30 resolvido; 2 OpenAPI tinham YAML invalido e ninguem sabia |

Os tres ficam defasados por 1 versao (1.12 vs 1.13 instalada) — **e a ultima vez que isso e trabalho manual**: o delta 1.12->1.13 nao tem `[BREAKING]`, entao `squad-migrate --apply` grava sozinho na proxima sessao de cada um.

**trokey-assesment:** projeto encerrado (ultimo commit ha 5 semanas, tem RESUMO_FINAL.md) — NAO precisa de init nem reconciliacao.

---

## 🔴 Bloqueante

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| — | — | — | — |

---

## 🟠 Todo

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| FASE-1C | Dieta opcional: stack-conventions ~1.100 linhas cortáveis (genérico fora; gotchas/comandos ficam) | TL | Baixa prioridade — carrega sob demanda, não pesa em toda sessão |
| GATE-PRECHECK-MONOREPO | Pre-check de ambiente so confere node_modules da RAIZ; em monorepo pnpm um workspace pode estar sem deps (caso concilia: packages/ui) | TL | Achado na reconciliacao 1.12; candidato a proxima release |
| CI-LINT-OPENAPI | Lint dos OpenAPI movidos para packages/contracts no concilia e jobtracker — hoje sao doc, nao contrato verificado (2 estavam com YAML invalido e ninguem sabia) | DevOps | AM-30 fez a metade: contrato esta no repo, falta o CI olhar |
| FASE-2 | Performance/fluxo — itens 2.1-2.5 (2.6 e 2.7 ja feitos). **Proximo passo da sessao** | TL | [plano](docs/PLANO_EVOLUCAO_SQUAD.md); batalha ja validou a Fase 0 |
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
| BATALHA-TROKEY | **Fase 0 validada em campo**: achados-review=12 no M4 (2 MAJOR provados por execucao) contra 291 testes verdes e historico de 24 PRs com zero achados; QA executou 14/14 | 2026-07-29 (trokey PR #91) |
| v1.11.0 | Backport da batalha (AM-36..41): coletor de metricas honesto (media 98.0 era billing, nao qualidade), resume reporta as 3 versoes + procedimento de reconciliacao, delegacao em FOREGROUND, gate reseta estado compartilhado; 5 frases-eco pre-1.9.0 varridas | 2026-07-29 (PRs #54/#55, tag `8486d74`) |
| v1.12.0 | squad-migrate.py (migracao/atualizacao automatizada, criterio por direcao do diff) + gate valida AMBIENTE antes de medir qualidade + gate instalado no proprio upstream (nunca rodava) | 2026-07-29 (PRs #57/#58/#59/#60, tag `c89ca13`) |
| v1.13.0 | Reconciliacao automatica do delta sem `[BREAKING]`; deteccao por MARCADOR (UP-06 em 3a forma) | 2026-07-30 (PRs #61/#62, tag `2b5881c`) |
| CONSUMIDORES | concilia migrado de template clonado (13 skills locais, 42 arquivos de template); AM-30 resolvido nos 3 (espelho de contratos fora, OpenAPI para o repo, doc de dominio separado); 2 OpenAPI com YAML invalido corrigidos; gates conectados e verdes nos 3 | 2026-07-29/30 |
| CHECKLIST-TROKEY | Checklist de reconciliação 1.6→1.10 + batalha preparado com estados verificados no repo trokey (espelho contracts/, gate órfão, specs/) | 2026-07-28 (entregue ao usuário) |

**Histórico do produto AgentesIA:** ver `archive/agentesia/TASK_BOARD.md`.
