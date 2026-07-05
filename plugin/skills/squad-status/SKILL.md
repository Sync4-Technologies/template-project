---
name: squad-status
description: Snapshot rápido do estado do projeto (TASK_BOARD counts, ADRs recentes, PRs abertos, commits recentes, feature flags ativas). Use a qualquer momento durante sessão para checar progresso sem mudar direção. Mais leve que /squad-resume.
---

# Skill — Squad Status (Snapshot Rápido)

> **Owner:** Tech Lead | **Revisão:** 90 dias | **Obsolescência:** workflow operacional mudar significativamente

Snapshot leve do projeto. Não onboarda nem decide próximo passo — apenas mostra estado.

---

## Quando usar

- Checar progresso durante sessão ativa
- Antes de delegar tarefa (verificar carga em cada coluna)
- Antes de mergir PR (verificar gates)
- Em revisão semanal/quinzenal do TL
- Após pausa curta (<1 dia, contexto fresco)

## Quando NÃO usar

- Início de sessão de trabalho com retomada → use `/squad-resume`
- Encerrar sessão preparando handoff → use `/squad-handoff`
- Audit completo de DS → use `/squad-design-audit`
- Audit completo de feature flags → use `/squad-flag-audit`

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

# Métricas de saúde (últimas entradas `saude:` do Session Log — squad-handoff step 5d)
grep -o "saude: [^|]*" .claude/squad/project/DECISIONS_LOG.md | tail -3
```

Ler:

- `.claude/squad/project/TASK_BOARD.md` → contagem por coluna
- `.claude/squad/project/DECISIONS_LOG.md` → últimas 3 entradas de Session Log
- `.claude/squad/project/ADR/` → lista de ADRs específicos do projeto
- `.claude/squad/project/agent-memory/` → arquivos modificados recentemente

### 2. Apresentar snapshot

Formato (≤200 palavras):

```
=== STATUS — [Projeto] — YYYY-MM-DD HH:MM ===

📊 TASK_BOARD:
- Todo: N
- Doing: N (agentes: [lista])
- Review: N (PRs: [#1, #2])
- Blocked: N (causas: [breve])
- Done: N (esta semana)

🔀 PRs abertos: N
- #N — [título] — [reviewDecision]
- ...

📝 Commits últimos 10:
[lista compacta]

📈 Saúde da squad (últimas 3 sessões — tendência):
- achados-review/PR: [N N N] | ciclos-ci/PR: [N N N] | retrabalho: [N N N]
- (meta: 0 achados, 1 ciclo — piora consistente = pauta de checkpoint)

🏗️ ADRs do projeto: N
- ADR-NNN: [título]
- ...

🎯 Current Focus (TASK_BOARD):
- [Em andamento atual]

🚩 Feature flags ativas: N
[se aplicável — listar via API do provedor]

⚠️ Atenção:
- [bloqueios críticos]
- [PRs sem review há >3 dias]
- [tarefas em Doing há >7 dias]
- [flags > 90 dias sem decisão]

🆗 Sem alertas críticos
```

### 3. Não tomar ações

Diferente de `/squad-resume` e `/squad-handoff`, esta skill **não** modifica memory. Apenas reporta.

Exceção: se detectar inconsistência crítica (ex: PR mergeado mas TASK_BOARD não atualizado), alertar mas NÃO corrigir automaticamente — sugerir ação ao usuário.

### 4. Cadência sugerida

- **Diária** em projetos ativos (≥1 commit/dia)
- **Semanal** em projetos com cadência menor
- **Ad-hoc** antes de reunião de status, revisão de sprint, ou decisão grande

---

## Diferenças vs outras skills

| Skill | Modifica memory? | Aguarda input? | Duração típica |
|-------|------------------|----------------|----------------|
| `/squad-resume` | Sim (Session Log) | Sim (próximo passo) | 5-15 min |
| `/squad-handoff` | Sim (várias seções) | Não (encerra) | 10-20 min |
| `/squad-status` | **Não** | **Não** | 1-2 min |

---

## Anti-patterns (rejeitar)

- Modificar memory durante status — não é objetivo
- Apresentar status >300 palavras — perde valor de snapshot rápido
- Sugerir mudanças sem o usuário pedir
- Tomar decisões — apenas reportar

---

## Referências

- TASK_BOARD: `.claude/squad/project/TASK_BOARD.md`
- DECISIONS_LOG: `.claude/squad/project/DECISIONS_LOG.md`
- ADRs: `.claude/squad/project/ADR/`
- Agent memory: `.claude/squad/project/agent-memory/`
- Skills relacionadas: `/squad-resume`, `/squad-handoff`, `/squad-flag-audit`, `/squad-design-audit`
