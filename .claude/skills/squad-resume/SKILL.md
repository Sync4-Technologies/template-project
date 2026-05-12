---
name: squad-resume
description: Conduz Tech Lead em retomada de projeto por novo usuário (ou mesmo usuário após pausa). Lê Current Focus, Session Log, PRs abertos e apresenta resumo acionável. Use ao iniciar sessão de trabalho num projeto onde alguém parou antes.
---

# Skill — Squad Resume (Retomada de Sessão)

> **Owner:** Tech Lead | **Revisão:** 90 dias | **Obsolescência:** workflow multi-user mudar significativamente

Conduz TL no onboarding rápido de novo usuário (ou retomada após pausa) sem perder contexto do trabalho anterior.

---

## Quando usar

- Usuário (mesmo ou outro) inicia sessão em projeto existente
- Após pausa >1 dia
- Quando outro dev/usuário assume trabalho
- Logo após `git clone` do projeto

## Quando NÃO usar

- Primeira sessão do projeto (use `/squad-new-project` em vez disso)
- Sessão imediatamente após `/squad-handoff` pelo mesmo usuário (contexto fresco)
- Apenas para olhar status sem retomar trabalho — use `/squad-status` (mais leve)

---

## Sua tarefa como Claude (atuando como Tech Lead)

### 1. Carregar contexto inicial

O hook `SessionStart` já carregou ARCHITECTURE/TASK_BOARD/DECISIONS_LOG/ADRs. Suplementar com:

```bash
git log --oneline -10
gh pr list --state open --json number,title,headRefName,url
git branch --show-current
git status --short
```

### 2. Ler Current Focus

Em `.claude/squad/project/TASK_BOARD.md` → seção "Current Focus":

- Última sessão (quando, quem)
- Em andamento
- Próximo passo (acionável)
- Bloqueios
- PR ativo
- Branch ativo
- Modo do projeto

Se "Current Focus" está com `[a preencher]` ou desatualizado (≥7 dias da última sessão e há commits recentes):

→ Alertar usuário: "Current Focus parece desatualizado. Sugiro confirmar estado real antes de prosseguir."

### 3. Ler últimas 3 entradas de Session Log

Em `.claude/squad/project/DECISIONS_LOG.md` → seção "Session Log":

Pegar as 3 últimas entradas para entender trajetória recente:

- O que foi feito nas sessões anteriores
- Decisões tomadas
- ADRs criados

### 4. Listar PRs abertos

Para cada PR aberto, identificar:

- Quem abriu
- Estado de revisão (aguardando review, aprovado, changes requested)
- Linkagem com cards em TASK_BOARD `Review`
- É trabalho do usuário atual ou de outro?

### 5. Listar tarefas ativas (Doing/Review/Blocked)

Em `.claude/squad/project/TASK_BOARD.md`:

- `Doing` — em andamento
- `Review` — aguardando QA/CR/SE (linkar PR)
- `Blocked` — com causa explícita

### 6. Apresentar resumo ao usuário

Formato:

```
=== RESUME — [Projeto] — YYYY-MM-DD ===

🎯 Onde estamos:
[1-2 linhas com estado atual do projeto]

📋 Última sessão: [data] por [usuário]
[resumo da última entrada de Session Log]

🔄 Em andamento:
- [card 1 — agente — status]
- [card 2 ...]

👀 Em revisão:
- PR #N: [título] — aguardando [reviewer]
- ...

🚫 Bloqueios:
- [se houver]

➡️ Próximo passo recomendado:
[ação específica e concreta lida do Current Focus, ou inferida]

⚠️ Contexto crítico:
- [decisões recentes que afetam próximo passo]
- [overrides em design-system se Path 1]
- [feature flags ativas relevantes]

Pronto para começar?
- "sim" → executo próximo passo
- "ajuste" → você redirecciona
- "status" → detalhes completos
```

### 7. Aguardar input do usuário

Possíveis respostas:

- **Confirmar** → prosseguir com próximo passo (delegar ao agente apropriado)
- **Redirecionar** → user define nova direção; atualizar Current Focus se relevante
- **Pedir detalhe** → mostrar TASK_BOARD/agent-memory específico
- **Recusar e começar algo novo** → user define; documentar mudança de prioridade em DECISIONS_LOG

### 8. Documentar retomada (opcional)

Se a retomada envolve mudança significativa de direção, adicionar entrada em Session Log:

```markdown
| YYYY-MM-DD | [usuário] | Retomada: [direção tomada vs Current Focus anterior] | (em andamento) | — |
```

---

## Diferença vs `/squad-status`

| Característica | `/squad-resume` | `/squad-status` |
|---------------|-----------------|-----------------|
| Quando | Início de sessão | Qualquer momento |
| Output | Resumo + próximo passo + aguardar input | Snapshot rápido sem direção |
| Objetivo | Onboard + retomada | Visibilidade |
| Duração | 5-15 min | 1-2 min |

Use `/squad-resume` para começar trabalho. Use `/squad-status` para checar progresso sem mudar direção.

---

## Anti-patterns (rejeitar)

- Não ler Current Focus → começar trabalho sem contexto
- Ignorar PRs abertos → duplicar trabalho de outro usuário
- Não confirmar direção com usuário → assumir continuidade automática
- Skip Session Log → perder contexto de decisões recentes
- Atualizar Current Focus de outra sessão sem confirmar com usuário

---

## Referências

- TASK_BOARD: `.claude/squad/project/TASK_BOARD.md` → "Current Focus"
- DECISIONS_LOG: `.claude/squad/project/DECISIONS_LOG.md` → "Session Log"
- Agent memory: `.claude/squad/project/agent-memory/`
- Skill par: `/squad-handoff` (encerramento)
- Skill leve: `/squad-status` (snapshot)
- TL spec: `.claude/squad/template/agents/tech-lead.md` → "Multi-user Continuity"
- CLAUDE.md → "Multi-user Continuity"
