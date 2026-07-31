# TASK_BOARD.md — dev-squad (upstream)

> Kanban da squad. Este repo mantém e evolui o **plugin dev-squad**. Produto AgentesIA arquivado em `archive/agentesia/` (2026-07-26).

---

## Current Focus

- **Ultima sessao:** 2026-07-30 por Pablo — FASE 2 inteira (2.1-2.5) + backport do trokey; DUAS releases (v2.0.0 e v2.1.0)
- **Em andamento:** nada. **Propagacao concluida (2026-07-31)**: os 3 consumidores em 2.1.0 — trokey `5533918`, concilia `cf1f2bf`, jobtracker `1bd373d`. O BREAKING foi no-op no trokey e no jobtracker; no concilia exigiu acao (CLAUDE.md documentava hook removido). **v2.0.0 e v2.1.0 RELEASED** — tags `v2.0.0` (`1ff6eac`) e `v2.1.0` (`50372a2`) confirmadas no remoto; plugin user-scope em **2.1.0**. PRs #67, #68, #69, #70, #71 mergeados; #66 FECHADO (obsoleto: o fix dele ja saira na 1.13.1 por outro caminho; conteudo de licao reaproveitado no #69). Nenhum PR aberto. Reconciliacao desta sessao: SQUAD_VERSION 1.13.0 -> 1.13.1 (automatica)
- **Proximo passo:** (a) **GATE-PRECHECK-SEMVER** — fix do pre-check (range sem espaco perde o teto). Bloqueia o porte do pre-check nos 3 consumidores, que ficaram com versoes ANTIGAS e diferentes entre si: concilia com a original (compara por igualdade), jobtracker com a intermediaria (sem teto), trokey com a dele (#96); (b) **UP-29**: dar gatilho executavel ao gate "CR aprovou" no fluxo de release — hoje ele so roda se alguem lembrar; (c) FASE 3 (metricas que geram acao, itens 3.1-3.4). **A validacao da 2.0.0/2.1.0 em uso real segue nao feita** — a propagacao aconteceu antes dela por decisao do usuario, e o `pre-bash.sh` ainda nao rodou uma sessao inteira em lugar nenhum
- **Bloqueios:** nenhum
- **Branch ativo:** `chore/handoff-v210` (worktree `squad-resume-f0c4cd`); `main` em `50372a2` (v2.1.0), `develop` em `948a7af`
- **Modo do projeto:** Production

### v2.0.0 — o que muda para quem consome (BREAKING)

`push-gate.sh` e `memory-update-reminder.sh` **removidos**, fundidos em `pre-bash.sh`. Acao em cada projeto: `grep -rn 'push-gate\|memory-update-reminder' .claude/settings.json` — se houver referencia por path, trocar por `${CLAUDE_PLUGIN_ROOT}/hooks/pre-bash.sh`. Sem override, nada a fazer. **O `squad-migrate --apply` NAO grava o SQUAD_VERSION sozinho neste salto** (delta com `[BREAKING]`, por desenho) — os 3 consumidores exigem passagem manual.

Este repo foi verificado: nenhum override em `.claude/settings.json` (projeto, local ou user).

### Primeiro `achados-review > 0` num PR de sistema do upstream

O CR independente **rejeitou** o PR #67 com 2 MAJOR, ambos reproduzidos e corrigidos antes do merge: (1) `--force-with-lease` classificada como flag de valor separado fazia o parser engolir o remote — push de outra branch disparava o aviso da UP-01, e **o teste passava pelo motivo errado**, usando a propria branch (UP-26 violada dentro do arquivo que a cita); (2) o refresh do cache de PR rodava depois do aviso, entao estado terminal se auto-perpetuava por 24h sem a auto-correcao que o hook antigo tinha. Mais 4 MINOR. O criterio de sucesso da Fase 0 (`0 achados` deixar de ser o normal) agora se manifesta fora da batalha trokey.

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
| GATE-PRECHECK-SEMVER | **Pre-check aprova Node fora do range quando o `engines.node` nao tem ESPACO entre as constraints.** A 1.13.1 trocou a comparacao por igualdade por um loop `for c in ${node_range}` — que separa por espaco. `">=22.0.0<23.0.0"` (forma valida de semver, usada pelo concilia) vira UM token: o `>=22` e avaliado, o teto `<23` e PERDIDO, e Node 26 passa. Provado no ambiente real: sem espaco PASSA, com espaco ABORTA, `">=22"` PASSA. Consequencia: os 3 projetos ficaram SEM o porte do pre-check novo nesta reconciliacao, porque portar seria regressao no concilia (hoje ele aborta certo, por acidente da comparacao antiga). **Fix:** tokenizar comparadores por regex (`(>=|<=|>|<|\^|~)?\s*\d+`) em vez de split por whitespace | DevOps | Achado ao propagar a 2.1.0 (2026-07-31); bloqueia o porte do pre-check nos 3 consumidores |
| GATE-PRECHECK-MONOREPO | Pre-check de ambiente so confere node_modules da RAIZ; em monorepo pnpm um workspace pode estar sem deps (caso concilia: packages/ui) | TL | Achado na reconciliacao 1.12; candidato a proxima release |
| CI-LINT-OPENAPI | Lint dos OpenAPI movidos para packages/contracts no concilia e jobtracker — hoje sao doc, nao contrato verificado (2 estavam com YAML invalido e ninguem sabia) | DevOps | AM-30 fez a metade: contrato esta no repo, falta o CI olhar |
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
| v2.0.0 | FASE 2 — hooks PreToolUse fundidos em `pre-bash.sh` com early-exit (83.6ms -> 5.1ms por comando Bash, -94%), `gh pr view` fora do caminho sincrono, fast lane, "feature critica" por materialidade, M0+delegacao de merge. UP-02 fechada. Suite de comportamento do hook: 35 assercoes | 2026-07-30 (PRs #67/#68, tag `1ff6eac`) |
| v2.1.0 | Backport trokey AM-42..AM-46 (marcador de idempotencia, seed de e2e sem assert, reviewer de contexto limpo, hooksPath do dispatcher) | 2026-07-30 (PRs #69/#71, tag `50372a2`) |
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
