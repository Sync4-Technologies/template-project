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

---

## Session Log

> Granularidade temporal de continuidade entre usuários. Entrada por sessão de trabalho relevante.
> Atualizado por skill `/squad-handoff` automaticamente, ou manualmente pelo TL.
> Lido por skill `/squad-resume` ao iniciar nova sessão.

| Data | Usuário | Resumo da sessão | Commits | ADRs/Decisões criadas |
|------|---------|-------------------|---------|------------------------|
| YYYY-MM-DD | [nome] | [1-2 linhas do que foi feito] | abc123, def456 | ADR-NNN, decisão X |

### Exemplo

| Data | Usuário | Resumo da sessão | Commits | ADRs/Decisões criadas |
|------|---------|-------------------|---------|------------------------|
| 2026-02-10 | Pablo | Setup inicial: PRD aprovado, stack escolhida (Node+Next), ADR-001 do projeto criado | a1b2c3, d4e5f6 | ADR-006-stack-projeto, decisão UUID v7 |
| 2026-02-12 | João | Implementou auth (use case + tests), preparou PR #12 | g7h8i9 | — |
| 2026-02-14 | Pablo | Review do PR #12, ajustes de segurança, merge | j0k1l2, m3n4o5 | Decisão: refresh token rotativo (em DECISIONS_LOG) |

### Regra

- Última entrada deve refletir estado atual antes de encerrar sessão
- TL atualiza ao final via `/squad-handoff` ou manualmente
- Entrada vazia significa sessão não-trabalhada (não criar entrada toda vez que abre editor)
