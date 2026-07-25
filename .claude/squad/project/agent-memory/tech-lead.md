# Agent Memory — Tech Lead

> Última atualização: 2026-07-05

> Memória especializada deste agente neste projeto. Ler `plugin/template/memory/agent-memory/README.md` para regras de escopo (≤200 linhas).

---

## Padrões adotados neste projeto

- [2026-07-05] Fluxo de release do plugin: branch -> PR develop (plugin-ci 4 jobs) -> PR develop->main -> tag vX.Y.Z -> `claude plugin marketplace update pdati` + `claude plugin update dev-squad@pdati`. Branch protection exige os 4 jobs (enforce_admins).
- [2026-07-05] Toda mudanca em skill/hook do plugin: rodar localmente antes de commitar os 4 checks (`scripts/ci/*.py`, `hooks-smoke.sh`, `claude plugin validate`) — pegaram 4 bugs reais nesta sessao.

<!-- Ex: Modo de operação atual: MVP (transição para Production prevista em [data]) -->
<!-- Ex: Conflitos QA × CR resolvidos sempre em ≤1 ciclo via reunião curta -->

- [padrão] — [data] — [breve justificativa]

---

## Learnings acumulados

- [2026-07-05] bash: `python3 - <<EOF` + pipe de dados NAO coexistem (heredoc consome o stdin) — passar dados via env var (`X="$OUT" python3 -c '...os.environ...'`). Errei 2x na mesma sessao.
- [2026-07-05] python inline em bash com aspas simples quebra com aspas simples no codigo — preferir heredoc + env.
- [2026-07-05] `gh pr merge N | tail` as vezes engole o output — confirmar com `gh pr view N --json state`.
- [2026-07-05] Descricao YAML de skill com `:` sem aspas quebra o frontmatter silenciosamente — `claude plugin validate` pega; virou job do plugin-ci.

<!-- Ex: Refatorações grandes neste projeto exigem feature flag por padrão; mitigamos retrabalho -->

- [data] [learning] [contexto]

---

## Decisões pequenas (não viraram ADR)

<!-- Ex: Aprovado tech-debt em /search (sem cache no MVP); revisar Sprint 5 -->

- [data] [decisão] [contexto]

---

## Referências

- **ADRs relacionados:**
- **DECISIONS_LOG.md relacionados:**
- **Seções de ARCHITECTURE.md relacionadas:**
