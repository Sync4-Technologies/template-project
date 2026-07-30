---
name: squad-resume
description: Conduz Tech Lead em retomada de projeto por novo usuário (ou mesmo usuário após pausa). Lê Current Focus, Session Log, PRs abertos e apresenta resumo acionável. Use ao iniciar sessão de trabalho num projeto onde alguém parou antes.
---

# Skill — Squad Resume (Retomada de Sessão)

Conduz TL no onboarding rápido de novo usuário (ou retomada após pausa) sem perder contexto do trabalho anterior.

## Quando usar

- Usuário (mesmo ou outro) inicia sessão em projeto existente
- Após pausa >1 dia · quando outro dev/usuário assume · logo após `git clone`

## Quando NÃO usar

- Primeira sessão do projeto → `/squad-new-project`
- Sessão imediatamente após `/squad-handoff` pelo mesmo usuário (contexto fresco)
- Apenas olhar status sem retomar trabalho → `/squad-status` (snapshot leve, 1-2 min vs 5-15 min)

---

## Sua tarefa como Claude (atuando como Tech Lead)

### 0. Versão do plugin: reportar a CARREGADA, não a instalada (AM-36)

A sessão FIXA a versão do plugin no início e não troca no meio. "Instalada" e "em execução nesta sessão" são coisas diferentes — regressões entraram exatamente por essa confusão (UP-01 no release da 1.6.0; sessão trokey rodando 1.6.0 acreditando ser 1.9.0). São **três** números:

```bash
# 1) versão EM EXECUÇÃO: derivar do path deste próprio SKILL.md (o único dado confiável)
#    .../plugins/cache/pdati/dev-squad/<VERSAO>/skills/squad-resume/SKILL.md
# 2) versão instalada (maior no cache)
ls -1 ~/.claude/plugins/cache/pdati/dev-squad | sort -V | tail -1
# 3) governança registrada no projeto
head -1 .claude/squad/project/SQUAD_VERSION
# e checar se há release mais nova disponível:
claude plugin update dev-squad@pdati 2>&1 | tail -3   # id COMPLETO nome@marketplace
```

**Reportar as três no resumo, sempre** (uma linha: `plugin: rodando X.Y.Z · instalado A.B.C · projeto registra D.E.F`). Divergência:

| Situação | Ação |
|---|---|
| rodando < instalado | **AVISAR ALTO:** esta sessão NÃO tem a governança nova. Trabalho que depende da versão (estreia de protocolo de review, spec de agente mudada) exige sessão nova — ver AM-37 no `tech-lead.md`. Perguntar se reinicia agora (contexto ainda pequeno) |
| `plugin update` trouxe versão nova | avisar que aplica só na próxima sessão; oferecer reiniciar |
| projeto registra < rodando | **reconciliação de governança pendente** → passo 0b (não seguir para o trabalho sem isso) |
| tudo igual | seguir sem comentário |

### 0b. Reconciliação de governança (quando SQUAD_VERSION < versão em execução)

Detectar não é reconciliar. Governança de duas versões atrás já rodou sem ninguém notar (trokey 1.4→1.6, depois 1.6→1.10). Procedimento:

0. **Tentar a via automática primeiro** (plugin 1.13.0+):

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/squad-migrate.py --project .          # diagnóstico
${CLAUDE_PLUGIN_ROOT}/scripts/squad-migrate.py --project . --apply   # grava se for seguro
```

Delta sem item `[BREAKING]` no changelog → o script grava o `SQUAD_VERSION` com a linha de histórico e a reconciliação está feita; reportar e seguir. Delta **com** BREAKING → ele lista os itens e NÃO grava; seguir os passos abaixo e só gravar ao final.

1. **Ler o que mudou** — changelog do plugin em execução, só o trecho entre a versão registrada e a atual: `${CLAUDE_PLUGIN_ROOT}/README.md` → seção "Changelog". Itens **BREAKING** são os que exigem ação no projeto.
2. **Montar a lista de ações** a partir dos BREAKING: skill renomeada/fundida (grep do nome antigo no `CLAUDE.md` e na memória do projeto), regra de agente que mudou (conferir se `agent-memory/` contradiz a spec nova), default invertido (ex.: push-gate advisory), artefato novo esperado (ex.: `specs/`).
3. **Executar o que é mecânico** (renomear referência, criar diretório, atualizar `SQUAD_VERSION` com uma linha por versão pulada).
4. **Escalar o que é decisão** — item que muda comportamento do projeto (encadear gate, ligar enforce) vai ao usuário com recomendação; não decidir sozinho.
5. **Registrar** no `DECISIONS_LOG` do projeto: o que foi aplicado, o que ficou adiado e por quê. Adiamento sem registro reaparece como surpresa na próxima reconciliação.

Reconciliação de 2+ versões acumuladas é sessão própria — não empilhar com a primeira tarefa do dia.

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

Em `.claude/squad/project/TASK_BOARD.md` → "Current Focus": última sessão (quando, quem) · em andamento · próximo passo (acionável) · bloqueios · PR ativo · branch ativo · modo do projeto.

Se está com `[a preencher]` ou desatualizado (≥7 dias da última sessão e há commits recentes) → alertar: "Current Focus parece desatualizado. Sugiro confirmar estado real antes de prosseguir."

### 3. Ler últimas 3 entradas de Session Log + calcular session delta

Em `.claude/squad/project/DECISIONS_LOG.md` → "Session Log": 3 últimas entradas (o que foi feito, decisões tomadas, ADRs criados).

**Session delta** — o que mudou desde a última entrada do Session Log:

```bash
git log --oneline --after="<data da última entrada do Session Log>" origin/<branch-principal>
```

Apresentar como bloco "Desde última sessão" no resumo. Delta vazio + Current Focus antigo = provável estado stale; delta cheio = trabalho de outro usuário para incorporar.

### 3b. Carregar agent-memory relevante

Com base no "Próximo passo" do Current Focus, carregar SÓ o `agent-memory/{agente-relevante}.md` (backend → `backend-engineer.md`, frontend → `frontend-engineer.md`, deploy → `devops-engineer.md`, etc.). Não carregar a memória de todos os agentes — só a de quem vai executar (economia de tokens).

### 3c. Conferir se o gate local está CONECTADO (AM-35)

Barato e não-negociável — rodar o snippet canônico de squad-core §M (`${CLAUDE_PLUGIN_ROOT}/template/docs/squad-core.md`). Marcador defasado APÓS commits recentes = gate órfão — instalado mas fora da cadeia de hooks (causa típica: `core.hooksPath` de um gerenciador como husky que não chama o script; ver `/squad-init` passo 5). Não é o mesmo que "ainda não commitei nada": comparar com a data do último commit.

Se estiver órfão: reportar no bloco "Contexto crítico" do resumo, **não consertar sozinho** — encadear hook é mudança de infra do repo e pode já ter sido adiada por decisão do usuário (conferir `SQUAD_VERSION` e `LESSONS_LEARNED` antes de propor).

### 4. Listar PRs abertos

Para cada PR: quem abriu · estado de revisão (aguardando review, aprovado, changes requested) · linkagem com cards em TASK_BOARD `Review` · é trabalho do usuário atual ou de outro?

### 5. Listar tarefas ativas (Doing/Review/Blocked)

Em `.claude/squad/project/TASK_BOARD.md`: `Doing` (em andamento) · `Review` (aguardando QA/CR/SE — linkar PR) · `Blocked` (com causa explícita).

### 6. Apresentar resumo ao usuário

Campos, nesta ordem (compacto — delta + próximo passo, não a história do projeto):

```
=== RESUME — [Projeto] — YYYY-MM-DD ===
🎯 Onde estamos: [1-2 linhas]
📋 Última sessão: [data] por [usuário] — [resumo da entrada do Session Log]
📦 Desde última sessão (git delta): [commits/PRs em origin — ou "nenhum"]
🔄 Em andamento: [card — agente — status]
👀 Em revisão: [PR #N — título — aguardando reviewer]
🚫 Bloqueios: [se houver]
➡️ Próximo passo recomendado: [ação concreta do Current Focus, ou inferida]
⚠️ Contexto crítico: [decisões recentes / overrides de DS / flags ativas / gate órfão]

Pronto para começar? ("sim" → executo próximo passo · "ajuste" → você redireciona · "status" → detalhes)
```

### 7. Aguardar input do usuário

- **Confirmar** → prosseguir com próximo passo (delegar ao agente apropriado)
- **Redirecionar** → usuário define nova direção; atualizar Current Focus se relevante
- **Pedir detalhe** → mostrar TASK_BOARD/agent-memory específico
- **Recusar e começar algo novo** → usuário define; documentar mudança de prioridade em DECISIONS_LOG

### 8. Documentar retomada (opcional)

Se a retomada envolve mudança significativa de direção, adicionar entrada em Session Log:

```markdown
| YYYY-MM-DD | [usuário] | Retomada: [direção tomada vs Current Focus anterior] | (em andamento) | — |
```

---

## Anti-patterns (rejeitar)

- **Pular `git fetch` / confiar no Current Focus sem cross-check no git remoto** → re-implementar trabalho já mergeado
- **Re-resumir o projeto inteiro a cada retomada** → o resumo é delta + próximo passo + bloqueios, não a história do projeto (tokens)
- Atualizar Current Focus de outra sessão sem confirmar com usuário
- **Tratar lição marcada `[OK] Aplicado` como resolvida sem prova de efeito** → ação fechada contra a existência do arquivo some do radar justamente por parecer resolvida (AM-35)

---

- **Owner:** Tech Lead · **Par:** `/squad-handoff` (encerramento) · `/squad-status` (snapshot leve)
- **Fonte:** `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Multi-user Continuity" · memória em `.claude/squad/project/` (TASK_BOARD → "Current Focus", DECISIONS_LOG → "Session Log")
