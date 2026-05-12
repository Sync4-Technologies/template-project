---
name: squad-handoff
description: Conduz Tech Lead no encerramento de sessão preparando handoff para próximo usuário. Atualiza Current Focus, Session Log, agent-memory. Use ao final de sessão de trabalho significativa para garantir continuidade sem perda de contexto.
---

# Skill — Squad Handoff (Encerramento de Sessão)

> **Owner:** Tech Lead | **Revisão:** 90 dias | **Obsolescência:** workflow multi-user mudar significativamente

Conduz TL no encerramento de sessão, garantindo que próximo usuário (mesmo ou outro) retome sem perder contexto.

---

## Quando usar

- Final de sessão de trabalho com mudanças relevantes (≥1 commit)
- Antes de ausência prolongada (>1 dia sem mexer no projeto)
- Quando outro dev/usuário vai assumir o trabalho
- Após decisão arquitetural relevante (mesmo sem encerrar sessão)

## Quando NÃO usar

- Sessão de exploração sem commits (não há o que registrar)
- Mudanças triviais sem impacto em fluxo (typo, formatação)
- Uma reunião de discussão sem decisão tomada

---

## Sua tarefa como Claude (atuando como Tech Lead)

### 1. Revisar estado do trabalho

Coletar:

- `git status` — verifica arquivos não-committed
- `git log --oneline origin/main..HEAD` — commits desta sessão
- `gh pr list --state open` — PRs abertos
- `git branch --show-current` — branch ativo

Identificar:

- O que foi feito (commits)
- O que está em revisão (PRs abertos)
- O que está em andamento mas não-commited (arquivos modificados)
- O que estava em `Doing`/`Review` e mudou de estado

### 2. Atualizar TASK_BOARD.md

Em `.claude/squad/project/TASK_BOARD.md`:

#### Mover cards entre colunas conforme estado real

- Tarefas concluídas (PRs mergeados) → `Done`
- Tarefas em PR aberto → `Review` (linkar PR)
- Tarefas paradas com bloqueio → `Blocked` (descrever causa)
- Tarefas iniciadas mas não-commited → permanecem em `Doing`

#### Atualizar "Current Focus" no topo

```markdown
- **Última sessão:** YYYY-MM-DD por [usuário]
- **Em andamento:** [tarefa principal — link para card]
- **Próximo passo:** [ação específica e concreta — quem retomar saberá exatamente o que fazer]
- **Bloqueios:** [se houver]
- **PR ativo:** [link se aplicável]
- **Branch ativo:** [nome do branch]
- **Modo do projeto:** [MVP / Production]
```

**Próximo passo** deve ser **acionável**, não vago. Exemplos:

- ✅ "Implementar testes de integração para `auth/login` use case (Backend)"
- ❌ "Continuar trabalho de auth"

### 3. Atualizar agent-memory dos agentes envolvidos

Para cada agente que teve atuação relevante na sessão:

1. Acionar o agente
2. Pedir para atualizar `.claude/squad/project/agent-memory/{agent}.md` com:
   - Padrões adotados nesta sessão
   - Learnings (o que descobriu, o que evitar)
   - Decisões pequenas que não viraram DECISIONS_LOG

Confirmar atualização antes de prosseguir.

### 4. Escrever entrada em Session Log

Em `.claude/squad/project/DECISIONS_LOG.md` → seção "Session Log":

```markdown
| YYYY-MM-DD | [usuário] | [resumo 1-2 linhas] | [commits] | [ADRs/decisões] |
```

Resumo deve responder: **o que foi feito** + **o que ficou pendente**.

### 5. Verificar PRs abertos

```bash
gh pr list --state open --json number,title,headRefName,url
```

Para cada PR aberto:

- Linkar no card correspondente em `Review`
- Anotar status de reviews (aprovado? mudanças pendentes?)
- Identificar se aguarda ação do próximo usuário ou de revisor externo

### 6. Confirmar consistência da memory

Checklist antes de encerrar:

- [ ] `ARCHITECTURE.md` reflete estado atual? Atualizado se houve mudança estrutural?
- [ ] ADRs novos criados em `project/ADR/` se houve decisão estrutural?
- [ ] `DECISIONS_LOG.md` tem entrada para cada decisão rápida tomada?
- [ ] `TASK_BOARD.md` Current Focus + cards em colunas corretas?
- [ ] `agent-memory/{relevantes}.md` atualizados?
- [ ] Session Log tem entrada da sessão atual?
- [ ] Mudanças relevantes commitadas (não-commited = invisível para próximo usuário)?

Se qualquer ❌, resolver antes de encerrar.

### 7. Gerar handoff message

Texto final para próximo usuário (User B). Apresentar como conclusão da sessão:

```
=== HANDOFF — [Projeto] — YYYY-MM-DD ===

Status atual:
- [breve resumo do estado do projeto]

Próximo passo:
- [ação específica que próximo usuário deve tomar]

Contexto crítico:
- [decisões ou descobertas que próximo usuário precisa saber]

PRs abertos:
- #N — [título] — [status]

Bloqueios:
- [se houver]

Onde ler primeiro:
1. `.claude/squad/project/TASK_BOARD.md` → "Current Focus"
2. `.claude/squad/project/DECISIONS_LOG.md` → "Session Log" (última entrada)
3. PRs abertos no GitHub
4. Acionar `/squad-resume` para retomada guiada
```

Apresentar este texto ao usuário ANTES de finalizar a sessão.

### 8. Confirmar commit final

Se há mudanças em memory files (TASK_BOARD, DECISIONS_LOG, agent-memory) decorrentes deste handoff:

- Criar commit dedicado: `chore: handoff prep — update memory and current focus`
- Push se aplicável

---

## Anti-patterns (rejeitar)

- Handoff sem atualizar Current Focus → próximo usuário fica perdido
- "Próximo passo" vago tipo "continuar X" — deve ser específico
- Esquecer de mover cards no TASK_BOARD → estado desatualizado confunde
- Não logar sessão em Session Log → granularidade temporal se perde
- Handoff antes de commitar mudanças em memory → trabalho de organização se perde
- Memory files com TODOs não preenchidos (`[a definir]`) deixados em produção

---

## Referências

- TASK_BOARD: `.claude/squad/project/TASK_BOARD.md` → "Current Focus"
- DECISIONS_LOG: `.claude/squad/project/DECISIONS_LOG.md` → "Session Log"
- Agent memory: `.claude/squad/project/agent-memory/`
- Skill par: `/squad-resume` (retomada)
- TL spec: `.claude/squad/template/agents/tech-lead.md` → "Multi-user Continuity"
- CLAUDE.md → "Multi-user Continuity"
