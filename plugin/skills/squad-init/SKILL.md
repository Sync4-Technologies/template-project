---
name: squad-init
description: Inicializa a estrutura de memória da squad num projeto (`.claude/squad/project/`) a partir do plugin — TASK_BOARD, DECISIONS_LOG, ARCHITECTURE, agent-memory, LESSONS_LEARNED e SQUAD_VERSION. Use uma única vez ao adotar a squad num projeto novo ou existente (substitui o antigo clone do template).
---

# Skill — Squad Init (Inicialização de Projeto)

Cria a estrutura de **memória viva** do projeto. O conteúdo estático (specs de agentes, docs, stack-conventions, templates) permanece no plugin — só o ESTADO do projeto vive no repositório.

## Quando usar

- Adoção da squad num projeto novo ou existente (uma única vez)
- Migração de projeto que usava o template clonado (ver "Migração" abaixo)

## Quando NÃO usar

- Projeto já tem `.claude/squad/project/` populado → nada a fazer (rodar `/squad-resume`)

---

## Sua tarefa como Claude (atuando como Tech Lead)

### 1. Verificar estado

- `.claude/squad/project/` já existe e populado → abortar e sugerir `/squad-resume`
- Existe `.claude/squad/template/` local (layout legado de clone) → seguir para "Migração"

### 2. Criar estrutura de memória

```
.claude/squad/project/
├── ARCHITECTURE.md      (stub: visão geral, stack — preencher no kickoff)
├── TASK_BOARD.md        (Current Focus + colunas Todo/Doing/Review/Blocked/Done)
├── DECISIONS_LOG.md     (tabela de decisões + Session Log)
├── LESSONS_LEARNED.md   (copiar de ${CLAUDE_PLUGIN_ROOT}/template/LESSONS_LEARNED-template.md)
├── SQUAD_VERSION        (versão do plugin — ver passo 3)
├── ADR/                 (vazio — ADRs do projeto)
├── agent-memory/        (um .md por agente, a partir de ${CLAUDE_PLUGIN_ROOT}/template/memory/agent-memory/)
└── docs/                (docs específicos do projeto)
```

**NÃO criar `contracts/` na memória da squad.** Os contratos vivem na fonte única do repositório — o pacote que os apps importam e o build compila (ex: `packages/contracts/src/`). Copiar contrato para a memória cria dois arquivos mantidos à mão, sem nada que force a sincronia: a cópia diverge em silêncio e passa a mentir. Convenção completa em `${CLAUDE_PLUGIN_ROOT}/template/contracts/README.md`.

Cabeçalhos mínimos (fonte autoritativa — não há arquivo de exemplo):

- **TASK_BOARD.md**: seção `## Current Focus` (Última sessão / Em andamento / Próximo passo / Bloqueios / PR ativo / Branch ativo / Modo do projeto) + colunas `## Bloqueante`, `## Todo`, `## Doing`, `## Review`, `## Done` como tabelas `| ID | Tarefa | Agente | Observação |`
- **DECISIONS_LOG.md**: tabela `| Data | Quem | Decisão | Contexto | Link |` + seção `## Session Log` (1 entrada por sessão: `[data] [usuário] resumo | saude: métricas (N PRs)`)

Memória SEM emojis (marcadores ASCII: `[OK]`, `[!]`, `->`).

### 3. Registrar versão da squad

Gravar em `.claude/squad/project/SQUAD_VERSION` a versão do plugin em uso (campo `version` de `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`) + data. Atualizar a cada upgrade do plugin — permite saber quais regras governaram cada fase do projeto.

### 4. CLAUDE.md do projeto

Se o projeto não tem `CLAUDE.md`, criar um mínimo com:

- **Papel: "Claude atua como Tech Lead da squad"** — orquestra agentes, delega implementação, guarda quality gates (o hook SessionStart do plugin reforça isso, mas o CLAUDE.md é a declaração canônica do projeto)
- Contexto do projeto (1 parágrafo) + modo de operação (MVP / Production — perguntar ao usuário)
- Ponteiro para as fontes de verdade (`.claude/squad/project/*`)
- Pré-sessão: `/squad-resume` obrigatório como 1º passo de retomada
- Regra: **não editar arquivos do plugin/template dentro do projeto** — gap no sistema da squad vai para `LESSONS_LEARNED.md` do projeto e é backportado ao plugin (upstream)

### 5. Instalar os gates de qualidade (com confirmação do usuário — recomendado forte)

Regra vira máquina, não prosa. Perguntar ao usuário e, confirmado, executar:

1. **Gate local bloqueante** (pre-commit):

   ```bash
   mkdir -p .githooks
   cp ${CLAUDE_PLUGIN_ROOT}/template/ci/pre-commit-quality.example .githooks/pre-commit-quality
   chmod +x .githooks/pre-commit-quality
   ```

   **Antes de mexer em `core.hooksPath`, DETECTE o gerenciador de hooks do projeto (AM-34).** Sobrescrever `core.hooksPath` num repo que usa husky/lefthook **desliga o gerenciador** — quem instala percebe e não aplica, e o gate fica órfão: arquivo presente, ninguém chamando. É o pior dos dois mundos, e passa despercebido porque o artefato existe.

   ```bash
   git config core.hooksPath   # husky => .husky/_ ; lefthook => .lefthook ; vazio => sem gerenciador
   ls .husky/pre-commit .lefthook.yml .pre-commit-config.yaml 2>/dev/null
   ```

   | Situação | Ação |
   |---|---|
   | **husky** (`core.hooksPath` = `.husky/_`) | NÃO tocar em `core.hooksPath`. Encadear: acrescentar `./.githooks/pre-commit-quality` ao final de `.husky/pre-commit` (depois do `lint-staged`) |
   | **lefthook** | Adicionar um `command` no hook `pre-commit` do `lefthook.yml` apontando pro script |
   | **pre-commit (Python)** | Adicionar um hook `local` de `entry: .githooks/pre-commit-quality` no `.pre-commit-config.yaml` |
   | **nenhum gerenciador** | Aí sim: `.githooks/pre-commit` chamando o script + `git config core.hooksPath .githooks` |

   Em seguida, **adaptar os comandos do hook à stack** do projeto (bloco de detecção no topo do script; comandos vêm da stack-convention → "Standard commands"). Ao passar, o hook grava o marcador `$GIT_DIR/squad-gate-ok` — é ele que o `pre-bash` do plugin verifica.

   **Provar o efeito antes de declarar feito (AM-35).** Instalado não é ativo. Fazer **um commit real** e rodar o snippet canônico de squad-core §M (`${CLAUDE_PLUGIN_ROOT}/template/docs/squad-core.md`): marcador acompanhou o HEAD = gate CONECTADO; defasado = gate ÓRFÃO — o hook não está na cadeia. Não marcar o passo como concluído nesse estado: ou encadeia, ou registra explicitamente como pendência aceita (no `SQUAD_VERSION` e no `LESSONS_LEARNED`), com a decisão do usuário.

   **[!] Em WORKTREE paralela, hook novo não vale até o repo PRINCIPAL trocar de branch (AM-42).** `core.hooksPath` é caminho ABSOLUTO do principal, e o dispatcher (husky `_/h`, lefthook) resolve o script irmão no **working tree DELE**. Com o principal parado em outra branch, o arquivo não existe lá e o hook sai `exit 0` **em silêncio, em TODAS as worktrees** — mesmo com o hook presente na worktree que empurra e já mergeado em `main`. Antes de declarar conectado: `git -C <principal> branch --show-current` + conferir o arquivo no working tree do principal. Caso real: gate "instalado", PR mergeado, memória atualizada, nada rodando (trokey-franchising, 2026-07-29).

   **Porte de script é código, não documentação (AM-46).** Ao copiar `pre-commit-quality.example` (ou qualquer executável do template) para o projeto, **execute uma vez no ambiente real antes de commitar**. Um porte não executado já entregou um pre-check que abortava todo push por comparar range de `engines.node` com igualdade — ver o comentário `[!] RESPEITAR O OPERADOR` no próprio example.

2. **CI do projeto** (workflow real, não example):
   ```bash
   mkdir -p .github/workflows
   cp ${CLAUDE_PLUGIN_ROOT}/template/ci/squad-ci.yml.template .github/workflows/squad-ci.yml
   ```
   **Preencher os `TODO(stack)`** com os comandos da stack-convention (setup, install com lockfile, format/lint/typecheck, testes com cobertura, build). Workflow com TODO restante FALHA de propósito — não deixar placeholder em produção.

3. Informar: o **`pre-bash`** do plugin (hook PreToolUse em Bash) AVISA em `git push` sem o gate rodado no HEAD atual — advisory por padrão desde a v1.8.0, não bloqueia. Bloqueio duro é opt-in do projeto (`SQUAD_GATE_ENFORCE=1` ou arquivo `.claude/squad/project/gate-enforce`); escape consciente `SQUAD_SKIP_GATE=1` inline no comando (registrar o porquê no PR).

Os demais hooks do plugin (SessionStart carrega memória + persona; architecture-reminder pós-Edit) já ficam ativos com o plugin instalado — nada a copiar. Opt-out: desabilitar o plugin no projeto.

### 5b. Plugin complementar (projeto COM UI)

Recomendar instalar o plugin oficial da Anthropic de estética frontend (dependência declarada, não copiada):

```bash
claude plugin install frontend-design@claude-plugins-official
```

Registrar no `SQUAD_VERSION` (`plugins-complementares: frontend-design`). O PD usa o framework dele no passo de direção estética; o Frontend Engineer o invoca ao implementar telas.

### 6. Commit inicial

`chore: squad init — estrutura de memória + SQUAD_VERSION`

Apresentar ao usuário o que foi criado + próximo passo (`/squad-new-project` para projeto novo sem PRD; `/squad-resume` para projeto em andamento).

---

## Migração de projeto legado → plugin puro (AUTOMATIZADA)

Não fazer à mão: `${CLAUDE_PLUGIN_ROOT}/scripts/squad-migrate.py` faz o inventário e separa o que é determinístico do que é decisão. Funciona em qualquer estado (template clonado, híbrido, plugin puro) e em qualquer máquina.

```bash
# 1) DIAGNÓSTICO — dry-run, não toca em nada
${CLAUDE_PLUGIN_ROOT}/scripts/squad-migrate.py --project .

# 2) executa só o que ele classificou como SEGURO
${CLAUDE_PLUGIN_ROOT}/scripts/squad-migrate.py --project . --apply
```

**Como ele decide** (a parte que importa entender): comparar "o arquivo local difere do plugin?" não serve — quase sempre difere, porque o plugin evoluiu. O critério é a **direção** da diferença, contra a **união de todas as versões no cache, em escopo de diretório**:

| Classificação | Significa | Ação |
|---|---|---|
| **defasado** | toda linha do arquivo local existe em alguma versão do plugin | remover é seguro — o plugin fornece igual ou mais novo |
| **linha exclusiva** | há conteúdo que nenhuma versão do plugin teve | ESCALAR com as linhas no relatório |
| **sem par** | arquivo não existe no plugin | artefato do projeto — preservar |

Escopo de diretório e versões antigas incluídas de propósito: conteúdo que apenas **mudou de arquivo** (trio de design fundido em `/squad-design`, blocos movidos para `squad-core`) ou que o plugin **removeu depois** (ADR-005 reescrita) não é customização local. Sem isso o relatório afoga o sinal real em dezenas de falsos positivos — medido no primeiro caso real: 46 arquivos "para decidir" caíram para 29, com o resto legível.

Ele também detecta, sem tocar: `settings.json` registrando hooks locais (rodariam em duplicado com os do plugin), contratos versionados na memória (AM-30), gate órfão (`.githooks` sem `core.hooksPath` — AM-34), `core.hooksPath` absoluto em repo com worktree (AM-38) e governança defasada.

**O que ele NUNCA toca:** `.claude/squad/project/` (memória do projeto), `.env`, código do produto.

Depois do `--apply`:

1. Revisar `git status`/`git diff` — a memória do projeto tem de estar intacta
2. Resolver as DECISÕES do relatório: linha exclusiva que é regra útil vira lesson/backport ANTES de o arquivo morrer
3. Remover o bloco `hooks` do `.claude/settings.json` se ele aponta para `.claude/hooks/` local
4. Reconciliar a governança (`/squad-resume` passo 0b) e só então gravar a versão nova no `SQUAD_VERSION`
5. Commit: `chore(squad): migra de template clonado para plugin dev-squad@<versão>`

---

## Anti-patterns (rejeitar)

- Copiar specs de agentes/docs do plugin pro projeto "por garantia" → duplicação = drift (a razão de o plugin existir)
- Inicializar sem SQUAD_VERSION → impossível auditar qual governança valia em cada fase

---

- **Owner:** Tech Lead · **Par:** `/squad-new-project` (projeto novo) · `/squad-resume` (retomada)
- **Fonte:** `${CLAUDE_PLUGIN_ROOT}/template/memory/` (estrutura) · `${CLAUDE_PLUGIN_ROOT}/template/LESSONS_LEARNED-template.md`
