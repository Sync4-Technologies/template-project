---
name: squad-handoff
description: Conduz Tech Lead no encerramento de sessão preparando handoff para próximo usuário. Atualiza Current Focus, Session Log, agent-memory. Use ao final de sessão de trabalho significativa para garantir continuidade sem perda de contexto.
---

# Skill — Squad Handoff (Encerramento de Sessão)

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

**O TL escreve direto** em `.claude/squad/project/agent-memory/{agent}.md` para cada agente com atuação relevante: padrões adotados, learnings, decisões pequenas que não viraram DECISIONS_LOG. Spawnar o agente para escrever a própria memória SÓ quando houve delegação real na sessão com contexto que o TL não viu (relatório §E não capturou tudo) — spawn carrega a spec inteira do agente para escrever ~10 linhas; não pagar esse custo por cerimônia.

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

- **achados-review** × **revisoes** (AM-39) — o coletor só vê o GitHub, e o reviewer da squad roda **em sessão** (subagent), sem postar review no PR. Por isso: `revisoes=0` significa que **o dado não está lá**, não que o gate falhou — nesse caso, anotar a contagem real da sessão à mão (ex.: `achados-review=12 (em sessao, subagent)`). Com `revisoes>0` e `achados=0` em PR não-trivial → **ALARME de gate morto** (reviewer complacente), não saúde. Zero saudável só existe com "Caça documentada" no review. Achado repetido → item novo no `engineer-self-review.md`
- **ciclos-ci** (runs failure COM trabalho real + 1, dentro da janela de vida do PR) — meta 1. Runs de 0 steps (billing/runner) são descartados e reportados à parte: contá-los deu média 98.0 sem uma falha de código (AM-39). Acima da meta → achar a causa antes de chamar de qualidade (flake conhecido conta como CI vermelho permanente e mata o sinal)
- **retrabalho** (reverts citando PRs do range) — meta 0

Fallback (sem `gh` disponível): registrar auto-relato marcado como `saude(auto-relato): ...` — explicitar que não é dado coletado.

Semiautonomia só é segura com medição — tendência piorando = pauta do próximo checkpoint com o usuário.

### 6. Consistência da memory

Os steps 2-5 SÃO a verificação — não re-conferir item a item o que acabou de ser feito. Só dois cortes transversais antes de encerrar: **anti-redundância** (informação escrita em 2 lugares → deixar em 1 e referenciar) e **decisão estrutural da sessão sem ADR** → criar agora.

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

### 9. Atualizar o plugin ANTES do fim da sessão (o restart aplica de graça)

O harness só aplica versão nova de plugin no restart da sessão. O handoff é o momento perfeito: a sessão está acabando de qualquer forma, então atualizar AGORA significa que o próximo `/squad-resume` já entra na versão nova — sem sessão perdida rodando hook/skill antigo.

```bash
claude plugin update dev-squad@pdati 2>&1 | tail -3
# id COMPLETO nome@marketplace — so "dev-squad" falha com "Plugin not found"
```

- Reportou atualização → informar no handoff message: "Plugin atualizado para X.Y.Z — aplica na próxima sessão."
- Já na última versão → seguir sem comentário.
- Se a versão nova muda governança (gates, hooks, fluxos), registrar uma linha no Session Log — o próximo usuário precisa saber sob quais regras vai operar.

Par com o passo 0 do `/squad-resume` (verificação na retomada): o handoff atualiza, o resume confere. Se ambos rodam, nenhuma sessão opera com plugin defasado sem saber. Regressões já entraram exatamente por esse furo (UP-01 passou no próprio release da 1.6.0 porque a sessão rodava o hook 1.5.0).

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

Owner: Tech Lead · Skill par: `/squad-resume` · Fonte: `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Multi-user Continuity"
