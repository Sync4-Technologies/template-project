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

### 2b. ARCHITECTURE.md (step ATIVO — não checklist passivo)

Perguntar explicitamente: **"Houve mudança estrutural nesta sessão (componente, fluxo, stack, integração)?"**

- **Sim** → editar `ARCHITECTURE.md` AGORA (não deixar para depois) + atualizar "Última atualização"
- **Não** → confirmar e seguir

### 2c. LESSONS_LEARNED.md (step ATIVO — melhorias do SISTEMA da squad)

Perguntas-gatilho (responder cada uma):

1. Gap em spec de agente causou erro/retrabalho?
2. Alguma skill perdeu passo obrigatório ou tem passo inútil?
3. Hook deixou de carregar contexto necessário?
4. Processo da squad causou retrabalho?
5. Falta regra no CLAUDE.md do projeto?

**Sim em qualquer uma** → registrar em `LESSONS_LEARNED.md` citando o **arquivo a modificar + ação concreta**. Learning técnico de projeto (gotcha de lib, padrão de código) NÃO vai aqui — vai em agent-memory.

### 3. Atualizar agent-memory dos agentes envolvidos

Para cada agente que teve atuação relevante na sessão:

1. Acionar o agente
2. Pedir para atualizar `.claude/squad/project/agent-memory/{agent}.md` com:
   - Padrões adotados nesta sessão
   - Learnings (o que descobriu, o que evitar)
   - Decisões pequenas que não viraram DECISIONS_LOG

Confirmar atualização antes de prosseguir.

**Regras de escrita de memória (todas as memórias do handoff):**

- **Sem emojis / chars fora do BMP** — usar marcadores ASCII (`[OK]`, `[!]`, `->`). Char astral truncado por hook já quebrou resume com API Error 400.
- **Single source por tipo de informação:** estado de tarefa → só TASK_BOARD; decisão → só DECISIONS_LOG; learning técnico → só agent-memory; melhoria de sistema → só LESSONS_LEARNED. Nos demais lugares, REFERENCIAR (1 linha), nunca repetir conteúdo. Informação duplicada custa tokens na escrita e em TODA leitura futura.

### 4. Escrever entrada em Session Log

Em `.claude/squad/project/DECISIONS_LOG.md` → seção "Session Log":

```markdown
| YYYY-MM-DD | [usuário] | [resumo 1-2 linhas] | [commits] | [ADRs/decisões] |
```

Resumo deve responder: **o que foi feito** + **o que ficou pendente**. **Máx 5 linhas** — referências de commit/PR, não narrativa (o `git log` já conta a história; não duplicar).

### 5. Verificar PRs abertos

```bash
gh pr list --state open --json number,title,headRefName,url
```

Para cada PR aberto:

- Linkar no card correspondente em `Review`
- Anotar status de reviews (aprovado? mudanças pendentes?)
- Identificar se aguarda ação do próximo usuário ou de revisor externo

### 5b. Verificar deploy (ATIVO — "Merged ≠ Deployed")

Se houve merge no branch de deploy nesta sessão, **VERIFICAR** (rodar o check, nunca copiar o valor anterior do board):

- Deployment com status SUCCESS **no SHA/commit esperado** (cruzar commit do deployment com o HEAD mergeado)
- Migrations do ambiente aplicadas (`migrate status` limpo)
- Smoke de 1 fluxo crítico contra a URL deployada (healthz 200 não prova nada — deploy velho responde 200)

Divergência (merged mas não deployado) → registrar como bloqueio explícito no Current Focus.

### 5c. Gate de qualidade do engineer

Perguntar: **"O engineer rodou format + lint + typecheck (gate completo, repo inteiro) no último commit?"**

- Não/incerto → rodar agora; vermelho = resolver antes do handoff (próximo usuário não herda CI quebrado)

### 5d. Métricas de saúde da squad (COLETADAS, não auto-relatadas)

Rodar o coletor (dado vem do GitHub — auto-relato mente):

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/squad-metrics.sh --limit <PRs da sessão>
```

Colar a linha `saude: ...` do output junto à entrada do Session Log.

- **achados-review** (comentários de review + CHANGES_REQUESTED) — meta 0 (mede se o self-review funciona; achado repetido → item novo no engineer-self-review.md via loop de feedback)
- **ciclos-ci** (runs failure + 1 por PR) — meta 1 (o push-gate deveria tornar >1 impossível)
- **retrabalho** (reverts citando PRs do range) — meta 0

Fallback (sem `gh` disponível): registrar auto-relato marcado como `saude(auto-relato): ...` — explicitar que não é dado coletado.

Semiautonomia só é segura com medição — tendência piorando = pauta do próximo checkpoint com o usuário.

### 6. Confirmar consistência da memory

Checklist antes de encerrar (valida o que os steps 2b/2c/3 já fizeram):

- [ ] `ARCHITECTURE.md` atualizado se houve mudança estrutural? (step 2b)
- [ ] `LESSONS_LEARNED.md` atualizado se houve gap de sistema da squad? (step 2c)
- [ ] ADRs novos criados em `project/ADR/` se houve decisão estrutural?
- [ ] `DECISIONS_LOG.md` tem entrada para cada decisão rápida tomada?
- [ ] `TASK_BOARD.md` Current Focus + cards em colunas corretas?
- [ ] `agent-memory/{relevantes}.md` atualizados, sem emojis?
- [ ] Session Log tem entrada da sessão atual (≤5 linhas)?
- [ ] Métricas de saúde registradas (achados-review / ciclos-ci / retrabalho)? (step 5d)
- [ ] Deploy verificado no SHA esperado (se houve merge)? (step 5b)
- [ ] **Anti-redundância:** alguma informação escrita em 2 lugares? → deixar em 1 e referenciar
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
- **Copiar status de deploy da sessão anterior sem re-verificar** → "5 serviços SUCCESS" stale escondeu semanas de deploy quebrado (Merged ≠ Deployed)
- **Emojis/chars astrais em memory files** → hook de truncamento pode quebrar o resume da próxima sessão
- **Mesma informação em 2+ arquivos de memória** → duplicação custa tokens em toda sessão futura; single source + referência
- **Handoff message narrativa** → referencia board/log/PRs em 1 linha por item, não repete conteúdo

---

## Referências

- TASK_BOARD: `.claude/squad/project/TASK_BOARD.md` → "Current Focus"
- DECISIONS_LOG: `.claude/squad/project/DECISIONS_LOG.md` → "Session Log"
- Agent memory: `.claude/squad/project/agent-memory/`
- Skill par: `/squad-resume` (retomada)
- TL spec: `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Multi-user Continuity"
- CLAUDE.md → "Multi-user Continuity"
