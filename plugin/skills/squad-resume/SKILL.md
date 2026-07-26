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

### 0. Verificar versão do plugin (uma linha, antes de tudo)

A sessão FIXA a versão do plugin no início e não troca no meio — regressões já entraram por sessão rodando hook antigo (UP-01 passou no próprio release da 1.6.0 por isso). Verificar se há versão mais nova:

```bash
claude plugin update dev-squad 2>&1 | tail -3
```

- Reportou atualização → avisar o usuário: **"Plugin atualizado para X.Y.Z, mas esta sessão continua na versão antiga — aplicar exige reiniciar a sessão."** Perguntar se prefere reiniciar agora (contexto ainda é pequeno no resume) ou seguir e reiniciar depois.
- Já na última versão → seguir sem comentário.
- Comparar também com `.claude/squad/project/SQUAD_VERSION`: se o projeto registra versão mais antiga que a instalada, a reconciliação de governança está pendente (ver caso trokey 1.4→1.6: governança de duas versões atrás rodando sem ninguém notar).

### 1. Carregar contexto inicial (com git fetch obrigatório)

O hook `SessionStart` já carregou head de ARCHITECTURE/TASK_BOARD/DECISIONS_LOG/ADRs. **NÃO recarregar o que o hook já trouxe.** Suplementar com:

```bash
git fetch origin
git log --oneline -10 origin/<branch-principal>
gh pr list --state open --json number,title,headRefName,url
git branch --show-current
git status --short
```

**`git fetch` é obrigatório** — resume em estado local stale já causou re-implementação de trabalho inteiro já mergeado.

**Cross-check "entregue":** para cada item marcado como entregue/OK no Current Focus, confirmar o commit/PR em `git log origin/<branch-principal>` ANTES de tratar qualquer coisa como pendente. Current Focus é texto manual — envelhece e mente; o git remoto é a verdade.

**ARCHITECTURE.md completo:** o hook carrega só as primeiras 50 linhas. Se o próximo passo for arquitetural (mudança estrutural, novo domínio, decisão de stack), ler o arquivo COMPLETO. Caso contrário, head + seções relevantes bastam (economia de tokens).

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

### 3. Ler últimas 3 entradas de Session Log + calcular session delta

Em `.claude/squad/project/DECISIONS_LOG.md` → seção "Session Log":

Pegar as 3 últimas entradas para entender trajetória recente:

- O que foi feito nas sessões anteriores
- Decisões tomadas
- ADRs criados

**Session delta** — o que mudou desde a última entrada do Session Log:

```bash
git log --oneline --after="<data da última entrada do Session Log>" origin/<branch-principal>
```

Apresentar como bloco "Desde última sessão" no resumo. Delta vazio + Current Focus antigo = provável estado stale; delta cheio = trabalho de outro usuário para incorporar.

### 3b. Carregar agent-memory relevante

Com base no "Próximo passo" do Current Focus, carregar SÓ o `agent-memory/{agente-relevante}.md` (backend → `backend-engineer.md`, frontend → `frontend-engineer.md`, deploy → `devops-engineer.md`, etc.). Não carregar a memória de todos os agentes — só a de quem vai executar (economia de tokens).

### 3c. Conferir se o gate local está CONECTADO (AM-35)

Barato e não-negociável — uma linha. O gate pode existir no disco e nunca ter rodado:

```bash
[ "$(cat "$(git rev-parse --git-dir)/squad-gate-ok" 2>/dev/null)" = "$(git rev-parse 'HEAD^{tree}')" ] \
  && echo "gate OK no HEAD" || echo "gate NAO validou o HEAD atual"
```

Marcador defasado em relação ao `HEAD` **depois de commits recentes** é sinal de gate órfão — instalado mas fora da cadeia de hooks (causa típica: `core.hooksPath` de um gerenciador como husky que não chama o script; ver `/squad-init` passo 5). Não é o mesmo que "ainda não commitei nada": compare com a data do último commit.

Se estiver órfão: reportar no bloco "Contexto crítico" do resumo, **não consertar sozinho** — encadear hook é mudança de infra do repo e pode já ter sido adiada por decisão do usuário (conferir `SQUAD_VERSION` e `LESSONS_LEARNED` antes de propor).

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

📦 Desde última sessão (git delta):
- [commits/PRs em origin desde a última entrada — ou "nenhum"]

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
- **Pular `git fetch` / confiar no Current Focus sem cross-check no git remoto** → re-implementar trabalho já mergeado
- **Re-resumir o projeto inteiro a cada retomada** → o resumo é delta + próximo passo + bloqueios, não a história do projeto (tokens)
- Carregar agent-memory de todos os agentes → só a do agente do próximo passo
- **Tratar lição marcada `[OK] Aplicado` como resolvida sem prova de efeito** → ação fechada contra a existência do arquivo some do radar justamente por parecer resolvida (AM-35)

---

## Referências

- TASK_BOARD: `.claude/squad/project/TASK_BOARD.md` → "Current Focus"
- DECISIONS_LOG: `.claude/squad/project/DECISIONS_LOG.md` → "Session Log"
- Agent memory: `.claude/squad/project/agent-memory/`
- Skill par: `/squad-handoff` (encerramento)
- Skill leve: `/squad-status` (snapshot)
- TL spec: `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Multi-user Continuity"
- CLAUDE.md → "Multi-user Continuity"
