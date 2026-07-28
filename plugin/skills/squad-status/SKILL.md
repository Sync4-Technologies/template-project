---
name: squad-status
description: Snapshot rápido do estado do projeto (TASK_BOARD counts, ADRs recentes, PRs abertos, commits recentes, feature flags ativas). Use a qualquer momento durante sessão para checar progresso sem mudar direção. Mais leve que /squad-resume.
---

# Skill — Squad Status (Snapshot Rápido)

Snapshot leve do projeto. Não onboarda nem decide próximo passo — apenas mostra estado. Não modifica memory (diferente de `/squad-resume` e `/squad-handoff`), não aguarda input, dura 1-2 min.

## Quando usar

- Checar progresso durante sessão ativa · antes de delegar tarefa (carga por coluna) · antes de mergir PR (gates)
- Revisão semanal/quinzenal do TL · após pausa curta (<1 dia, contexto fresco)

## Quando NÃO usar

- Início de sessão com retomada → `/squad-resume`
- Encerrar sessão preparando handoff → `/squad-handoff`
- Audit completo de DS → `/squad-design` (modo audit) · de flags → `/squad-flag-audit`

---

## Sua tarefa como Claude (atuando como Tech Lead)

### 1. Coletar dados rapidamente

Executar em paralelo:

```bash
# Git state
git log --oneline -10
git branch --show-current
git status --short

# PRs
gh pr list --state open --json number,title,headRefName,reviewDecision

# TASK_BOARD counts (Python or grep)

# Métricas de saúde — coletar do GitHub (fallback: últimas entradas `saude:` do Session Log)
${CLAUDE_PLUGIN_ROOT}/scripts/squad-metrics.sh --limit 10 2>/dev/null || \
  grep -o "saude: [^|]*" .claude/squad/project/DECISIONS_LOG.md | tail -3
```

Ler: `.claude/squad/project/TASK_BOARD.md` (contagem por coluna) · `DECISIONS_LOG.md` (últimas 3 entradas de Session Log) · `ADR/` (ADRs do projeto) · `agent-memory/` (modificados recentemente).

### 2. Apresentar snapshot (≤200 palavras)

Campos, nesta ordem:

```
=== STATUS — [Projeto] — YYYY-MM-DD HH:MM ===
📊 TASK_BOARD: Todo N · Doing N (agentes) · Review N (PRs) · Blocked N (causas) · Done N (semana)
🔀 PRs abertos: #N — [título] — [reviewDecision]
📝 Commits: [últimos 10, lista compacta]
📈 Saúde (últimas 3 sessões — tendência): achados-review/PR · ciclos-ci/PR · retrabalho
   (meta: 0 achados, 1 ciclo — piora consistente = pauta de checkpoint)
🏗️ ADRs do projeto: ADR-NNN — [título]
🎯 Current Focus: [em andamento atual]
🚩 Flags ativas: N [se aplicável]
⚠️ Atenção: bloqueios críticos · PRs sem review >3 dias · Doing >7 dias · flags >90 dias
   — ou "🆗 Sem alertas críticos"
```

### 3. Não tomar ações

Esta skill **não** modifica memory — apenas reporta. Exceção: inconsistência crítica detectada (ex: PR mergeado mas TASK_BOARD não atualizado) → alertar mas NÃO corrigir automaticamente; sugerir ação ao usuário.

### 4. Cadência sugerida

**Diária** em projetos ativos (≥1 commit/dia) · **semanal** em cadência menor · **ad-hoc** antes de reunião de status ou decisão grande.

---

- **Owner:** Tech Lead · **Par:** `/squad-resume` (retomada) · `/squad-handoff` (encerramento)
- **Fonte:** memória em `.claude/squad/project/` (TASK_BOARD, DECISIONS_LOG, ADR/, agent-memory/)
