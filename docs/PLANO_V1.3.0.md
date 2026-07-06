# Plano de Execução — squad v1.3.0

> Origem: avaliação de 2026-07-05 pós-v1.2.0 — "o que falta pra melhor squad".
> Tese da release: **converter governança de prosa em mecanismo**. Regra escrita degrada em sessão longa; hook/CI/script não. Três frentes: enforcement mecânico (E), CI do próprio plugin (F), métricas reais em vez de auto-relato (G).
> Fonte canônica: `plugin/`. Versão alvo: **1.3.0** (minor).

---

## Fase E — Enforcement mecânico nos projetos

Hoje `pre-commit-quality` é example opt-in e o gate pré-push é instrução. Vira máquina:

| # | Entrega | Arquivos | Critério de aceite |
|---|---------|----------|--------------------|
| E1 | **`/squad-init` INSTALA os gates** (com confirmação do usuário, não example): copia `pre-commit-quality` para `.githooks/` + `git config core.hooksPath .githooks`; gera workflow de CI real do projeto a partir de template por stack (lint + test + build + memory-check) | `plugin/skills/squad-init/SKILL.md` (passo novo) + `plugin/template/ci/squad-ci.yml.template` (novo — placeholders por stack) | Projeto pós-init tem hook ativo e workflow commitado; commit com lint quebrado FALHA localmente (não é aviso) |
| E2 | **Push-gate via hook do plugin**: novo `plugin/hooks/push-gate.sh` (PreToolUse, matcher Bash) — detecta `git push` e BLOQUEIA (exit 2) se o gate determinístico não rodou para o HEAD atual. Mecânica: `pre-commit-quality` grava marcador `.git/squad-gate-ok` com o hash da árvore validada; push-gate compara. Só ativa se `.claude/squad/project/` existe (inofensivo fora de projeto squad). Escape consciente documentado: `SQUAD_SKIP_GATE=1` (equivalente do `--no-verify`, logado) | `plugin/hooks/push-gate.sh` (novo) + `plugin/hooks/hooks.json` + `plugin/template/ci/pre-commit-quality.example` (grava marcador) | Num repo fixture: push sem gate → bloqueado com mensagem acionável; após rodar gate → passa; `SQUAD_SKIP_GATE=1` → passa com aviso |

**Avaliado e descartado (YAGNI):** hook mecânico de "screenshot antes de Engineer Done" — detectar "é tela nova" por heurística é frágil; falso positivo custa mais que o gate humano do TL. Fica como regra (TL bloqueia) até haver evidência de furo em batalha.

## Fase F — CI do próprio plugin (o repo upstream se testa)

O YAML quebrado da Fase B só foi pego por validação manual. "Sem teste → incompleto" vale pra squad também:

| # | Entrega | Arquivos | Critério de aceite |
|---|---------|----------|--------------------|
| F1 | **Workflow `plugin-ci.yml`** no repo (PR + push em develop/main), 4 jobs: (a) `validate` — instala Claude CLI e roda `claude plugin validate .` e `validate plugin`; (b) `frontmatter` — script python valida YAML frontmatter de TODAS as skills (pega a classe do bug da Fase B); (c) `hooks-smoke` — `bash -n` nos `.sh` + executa `load-memory.sh` com fixture de projeto (com e sem `project/`) validando JSON de saída + persona; (d) `links` — checker de links/paths internos de `plugin/` (referências `${CLAUDE_PLUGIN_ROOT}/...` apontam pra arquivos existentes) | `.github/workflows/plugin-ci.yml` (novo) + `scripts/ci/check-frontmatter.py` + `scripts/ci/check-plugin-paths.py` (novos) + fixture em `scripts/ci/fixtures/` | PR que quebra frontmatter, hook ou path interno fica VERMELHO; os 4 jobs rodam verdes no estado atual |
| F2 | **Branch protection** (passo manual documentado): develop/main exigem plugin-ci verde | README → "Distribuição e Versionamento" (nota) | Documentado; ativação é clique no GitHub (registrar como feito) |

## Fase G — Métricas de saúde coletadas, não auto-relatadas

Auto-relato do handoff mente (lição recorrente). Dado vem do GitHub:

| # | Entrega | Arquivos | Critério de aceite |
|---|---------|----------|--------------------|
| G1 | **`squad-metrics.sh`** no plugin: dado um repo (e opcionalmente um range/PR), coleta via `gh api`: achados por PR (review comments + reviews `CHANGES_REQUESTED`), ciclos de CI por PR (runs com conclusão failure antes do success no mesmo head), retrabalho (PRs reabertos/reverts). Output: linha `saude: achados-review=N ciclos-ci=N retrabalho=N` + tabela por PR | `plugin/scripts/squad-metrics.sh` (novo diretório `scripts/` no plugin) | Rodado contra ESTE repo (PRs #12–#22 reais) produz números corretos conferíveis à mão |
| G2 | **Handoff roda o script** (step 5d): auto-relato vira fallback explícito quando `gh` indisponível | `plugin/skills/squad-handoff/SKILL.md` | Step 5d instrui executar o script e colar o output |
| G3 | **Status usa o script** pra tendência | `plugin/skills/squad-status/SKILL.md` | Bloco de saúde vem de dado coletado |

---

## Fora de escopo (registrado, aguarda validação em batalha)

- **Anti-over-governance** (calibrar custo da cerimônia; MVP Mode desligando gates de verdade) — precisa dos dados de G rodando em ≥1 projeto real antes de cortar
- **Agentes nativos de plugin** (tools restritas por papel, model por agente) — v2 do modelo de delegação; muda arquitetura, merece release própria
- **Paralelismo com worktrees** — junto com agentes nativos

## Ordem, release e verificação

1. **F primeiro** (CI do plugin) — protege todo o resto do trabalho, inclusive E e G
2. **E** (enforcement nos projetos)
3. **G** (métricas) — validar G1 contra os PRs reais deste repo
4. Bump `1.3.0` + changelog + PR → develop → main + tag + update na máquina

Verificação de release:
- `claude plugin validate` verde; plugin-ci verde no PR da própria release (dogfooding imediato)
- Push-gate testado em repo fixture (bloqueia / passa / escape)
- `squad-metrics.sh` conferido contra 3 PRs deste repo à mão
- Teste de mesa: `/squad-init` num diretório fixture instala hook + workflow

Critério de sucesso da release (mensurável): a partir da v1.3, "ciclos-ci=1" deixa de depender de disciplina — o push com gate quebrado não acontece.
