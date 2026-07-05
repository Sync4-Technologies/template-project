# Lições Aprendidas — [Projeto]

> Documento vivo do **sistema da squad**. Copiar para `.claude/squad/project/LESSONS_LEARNED.md` no início do projeto.
> Atualizar no `/squad-handoff` (step 2c) sempre que uma pergunta-gatilho disparar.
> Ultima atualizacao: [YYYY-MM-DD]

---

## Propósito (o que vai aqui vs o que NÃO vai)

| Vai aqui | NÃO vai aqui (destino correto) |
|---|---|
| Gap em spec de agente que causou erro/retrabalho | Learning técnico de lib/stack → `agent-memory/{agent}.md` |
| Skill com passo faltando ou passo inútil | Decisão de arquitetura → ADR |
| Hook que deixou de carregar contexto | Decisão rápida → DECISIONS_LOG |
| Processo da squad que causou retrabalho | Estado de tarefa → TASK_BOARD |
| Regra faltando no CLAUDE.md do projeto | |

**Toda entrada obriga:** arquivo do sistema a modificar + ação concreta. Lição sem ação corretiva rastreável é desabafo, não lição.

**Regras de escrita:** sem emojis/chars astrais (usar `[OK]`, `[!]`, `->`); entradas enxutas; referenciar commits/PRs, não narrar.

---

## Template de seção (copiar por lição)

## N. [Título curto — contexto/fase] (severidade: CRÍTICO | ALTO | MÉDIO)

### O que aconteceu

[2-5 linhas. Sintoma observado + evidência (commit/PR/log). Sem narrativa.]

### Causa raiz

[A causa no SISTEMA da squad (spec/skill/hook/processo/regra), não no código. Se a causa é código, a lição é "por que o processo não pegou".]

### Ação corretiva

| ID | Ação | Arquivo a modificar | Status |
|----|------|---------------------|--------|
| AM-NN | [ação concreta e verificável] | [path do arquivo do sistema] | Pendente / [OK] Aplicado (ref) |

### Princípio (opcional — quando a lição generaliza)

[1-2 linhas memoráveis. Ex: "CI não é onde se descobre erro determinístico — é onde se confirma que não há."]

---

## Índice de ações (manter atualizado)

| ID | Ação (resumo) | Arquivo-alvo | Status |
|----|---------------|--------------|--------|
| AM-01 | | | Pendente |

---

## Ciclo de vida de uma lição

1. **Registrar** — no handoff (step 2c) ou no momento do incidente.
2. **Aplicar no projeto** — corrigir a cópia local do sistema (spec/skill/hook/CLAUDE.md do projeto).
3. **Backport ao upstream** — lição genérica (não específica da stack/projeto) deve virar melhoria no repositório template da squad. NUNCA deixar o fix só na cópia local (drift sem canal de retorno).
4. **Fechar** — marcar `[OK] Aplicado` com referência de commit. Ao retomar ação antiga, **re-verificar a premissa no código/log real** antes de implementar (hipóteses registradas envelhecem e podem estar erradas).
