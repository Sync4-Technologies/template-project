# DECISIONS_LOG.md

> Registro de decisões rápidas que não justificam um ADR formal.
> Para decisões arquiteturais maiores, usar `.claude/squad/project/ADR/`.
> Formato: uma linha por decisão, mais contexto quando necessário.

---

## Como usar

- Registrar aqui quando: decisão rápida, trade-off simples, escolha entre duas opções equivalentes
- Registrar em ADR quando: impacto sistêmico, decisão irreversível, afeta múltiplos componentes

---

## Log

| Data | Decisão | Contexto | Impacto | Autor |
|------|---------|---------|--------|-------|
| YYYY-MM-DD | [O que foi decidido] | [Por que / qual problema] | [Módulos / contratos afetados] | [TL / Architect / etc.] |

---

## Exemplo

| Data | Decisão | Contexto | Impacto | Autor |
|------|---------|---------|--------|-------|
| 2026-01-15 | Usar UUID v7 como PK em todas as entidades | UUID v4 não é ordenável, afeta queries de paginação por cursor | Todas as entidades do domínio | Architect |
| 2026-01-20 | Validar inputs no controller E no service | Defense in depth; service pode ser chamado fora do HTTP context | Backend engineers devem replicar validação nas duas camadas | Tech Lead |
| 2026-01-22 | Aprovado tech-debt: sem cache em /search por ora | Complexidade não justificada no MVP; revisar na Sprint 5 | Performance de busca aceitável até 10k registros | Tech Lead |
