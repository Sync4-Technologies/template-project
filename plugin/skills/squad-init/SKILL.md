---
name: squad-init
description: Inicializa a estrutura de memória da squad num projeto (`.claude/squad/project/`) a partir do plugin — TASK_BOARD, DECISIONS_LOG, ARCHITECTURE, agent-memory, LESSONS_LEARNED e SQUAD_VERSION. Use uma única vez ao adotar a squad num projeto novo ou existente (substitui o antigo clone do template).
---

# Skill — Squad Init (Inicialização de Projeto)

> **Owner:** Tech Lead | **Revisão:** 90 dias | **Obsolescência:** estrutura de memória do projeto mudar

Cria a estrutura de **memória viva** do projeto. O conteúdo estático (specs de agentes, docs, stack-conventions, templates) permanece no plugin — só o ESTADO do projeto vive no repositório.

---

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

   Em seguida, **adaptar os comandos do hook à stack** do projeto (bloco de detecção no topo do script; comandos vêm da stack-convention → "Standard commands"). Ao passar, o hook grava o marcador `$GIT_DIR/squad-gate-ok` — é ele que o push-gate do plugin verifica.

   **Provar o efeito antes de declarar feito (AM-35).** Instalado não é ativo. Faça **um commit real** e confira:

   ```bash
   [ "$(cat "$(git rev-parse --git-dir)/squad-gate-ok" 2>/dev/null)" = "$(git rev-parse 'HEAD^{tree}')" ] \
     && echo "gate CONECTADO" || echo "gate ORFAO — o hook não está na cadeia"
   ```

   Marcador defasado depois de um commit = gate órfão. Não marcar o passo como concluído nesse estado: ou encadeia, ou registra explicitamente como pendência aceita (no `SQUAD_VERSION` e no `LESSONS_LEARNED`), com a decisão do usuário.

2. **CI do projeto** (workflow real, não example):
   ```bash
   mkdir -p .github/workflows
   cp ${CLAUDE_PLUGIN_ROOT}/template/ci/squad-ci.yml.template .github/workflows/squad-ci.yml
   ```
   **Preencher os `TODO(stack)`** com os comandos da stack-convention (setup, install com lockfile, format/lint/typecheck, testes com cobertura, build). Workflow com TODO restante FALHA de propósito — não deixar placeholder em produção.

3. Informar: o **push-gate** do plugin (hook PreToolUse) bloqueia `git push` sem o gate rodado no HEAD atual; escape consciente `SQUAD_SKIP_GATE=1` (registrar o porquê no PR).

Os demais hooks do plugin (SessionStart carrega memória + persona; reminders) já ficam ativos com o plugin instalado — nada a copiar. Opt-out: desabilitar o plugin no projeto.

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

## Migração de projeto com template clonado (layout legado)

1. Manter `.claude/squad/project/` intacto (a memória é do projeto)
2. Criar `SQUAD_VERSION` (passo 3)
3. Remover do projeto: `.claude/squad/template/`, `.claude/skills/squad-*`, `.claude/hooks/{load-memory,architecture-reminder,memory-update-reminder}.sh` e as entradas correspondentes em `.claude/settings.json` (o plugin passa a fornecer tudo)
4. Confirmar com o usuário ANTES de remover (mostrar lista) — customizações locais do template viram candidatas a backport no upstream, não podem ser perdidas
5. Commit: `chore: migra squad de template clonado para plugin dev-squad@<versão>`

---

## Anti-patterns (rejeitar)

- Copiar specs de agentes/docs do plugin pro projeto "por garantia" → duplicação = drift (a razão de o plugin existir)
- Inicializar sem SQUAD_VERSION → impossível auditar qual governança valia em cada fase
- Sobrescrever `.claude/squad/project/` existente

---

## Referências

- Template de memória: `${CLAUDE_PLUGIN_ROOT}/template/memory/`
- LESSONS template: `${CLAUDE_PLUGIN_ROOT}/template/LESSONS_LEARNED-template.md`
- Skill seguinte: `/squad-new-project` (projeto novo) ou `/squad-resume` (retomada)
