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
├── contracts/           (contratos versionados do projeto)
└── docs/                (docs específicos do projeto)
```

Cabeçalhos mínimos (TASK_BOARD, DECISIONS_LOG) seguem o formato dos exemplos em `${CLAUDE_PLUGIN_ROOT}/template/memory/`. Memória SEM emojis (marcadores ASCII: `[OK]`, `[!]`, `->`).

### 3. Registrar versão da squad

Gravar em `.claude/squad/project/SQUAD_VERSION` a versão do plugin em uso (campo `version` de `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`) + data. Atualizar a cada upgrade do plugin — permite saber quais regras governaram cada fase do projeto.

### 4. CLAUDE.md do projeto

Se o projeto não tem `CLAUDE.md`, criar um mínimo com:

- Contexto do projeto (1 parágrafo) + modo de operação (MVP / Production — perguntar ao usuário)
- Ponteiro para as fontes de verdade (`.claude/squad/project/*`)
- Pré-sessão: `/squad-resume` obrigatório como 1º passo de retomada
- Regra: **não editar arquivos do plugin/template dentro do projeto** — gap no sistema da squad vai para `LESSONS_LEARNED.md` do projeto e é backportado ao plugin (upstream)

### 5. Hooks (opcional, recomendado)

Os hooks do plugin (SessionStart carrega memória; reminders de ARCHITECTURE/memory) já ficam ativos com o plugin instalado — nada a copiar. Opt-out: desabilitar o plugin no projeto.

### 6. Commit inicial

`chore: squad init — estrutura de memória + SQUAD_VERSION`

Apresentar ao usuário o que foi criado + próximo passo (`/squad-new-project` para projeto novo sem PRD; `/squad-resume` para projeto em andamento).

---

## Migração de projeto com template clonado (layout legado)

1. Manter `.claude/squad/project/` intacto (a memória é do projeto)
2. Criar `SQUAD_VERSION` (passo 3)
3. Remover do projeto: `.claude/squad/template/`, `.claude/skills/squad-*`, `.claude/hooks/{load-memory,architecture-reminder,memory-update-reminder}.sh` e as entradas correspondentes em `.claude/settings.json` (o plugin passa a fornecer tudo)
4. Confirmar com o usuário ANTES de remover (mostrar lista) — customizações locais do template viram candidatas a backport no upstream, não podem ser perdidas
5. Commit: `chore: migra squad de template clonado para plugin squad@<versão>`

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
