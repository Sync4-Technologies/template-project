# Template Project — AI Software Squad

Template reutilizável para construir produtos de software com uma squad de **agentes de IA especializados**, sob governança rigorosa, com qualidade e segurança inegociáveis.

A squad é semi-autônoma (usuário aprova decisões críticas) e capaz de:

- Criar projetos novos do zero
- Continuar projetos existentes
- Refatorar projetos legados
- Suportar e evoluir projetos em produção

---

## Visão Geral

A squad organiza 14 agentes especializados (Product Owner, Tech Lead, Architect, Product Designer, Engineers, QA, Code Reviewer, Security, DevOps, Support, Data) com fronteiras claras de responsabilidade, fluxos definidos e quality gates obrigatórios.

Princípios orientadores:

- **Qualidade e segurança são inegociáveis**
- **TDD obrigatório** — nada implementado sem teste
- **Contratos antes de código** — APIs e schemas definidos primeiro
- **Hexagonal por padrão** em backend e camada de IA
- **Feature flags em features críticas** com governança rígida
- **Observabilidade e resiliência** desde o design
- **Memória do sistema** mantida viva e auditável

---

## Quick Start

### Você quer iniciar um projeto novo

1. Clone este template para um novo repositório
2. Acione o **Product Owner** OU rode a skill **`/squad-prd-template`** diretamente
3. PO oferece **dois modos** para construir o PRD — você escolhe:

   #### 1️⃣ Modo Briefing
   Você tem um briefing pronto (texto, documento, notas).
   - Cola o briefing no chat (ou aponta o arquivo)
   - PO lê, estrutura no formato de PRD
   - PO pergunta apenas sobre **lacunas detectadas** (RNFs faltando, critérios vagos, etc.)
   - Resultado: PRD completo + suas respostas das lacunas

   #### 2️⃣ Modo Entrevista
   Você não tem briefing pronto ou prefere construir guiado.
   - PO conduz **entrevista estruturada** passo a passo
   - Perguntas sobre: problema, usuário-alvo, escopo, fluxos, RNFs, critérios de aceite, métricas, riscos
   - PO monta PRD progressivamente conforme suas respostas
   - Resultado: PRD completo construído do zero

   **Híbrido permitido:** PO pode trocar de modo a qualquer momento (ex: briefing vago → entrevista de gaps específicos).

4. PO salva `.claude/squad/project/PRD.md` baseado em [`.claude/squad/template/docs/PRD-template.md`](.claude/squad/template/docs/PRD-template.md)
5. Aprove o PRD (gate obrigatório)
6. Tech Lead orquestra o resto seguindo [Fluxo 1 do CLAUDE.md](CLAUDE.md#fluxos-de-projeto)

**Recomendação:** se ainda não pensou em escopo/usuário/regras → Modo Entrevista. Se já tem documento → Modo Briefing.

### Você quer continuar um projeto existente sob este template

1. `git pull` para sincronizar
2. Inicie sessão Claude Code no diretório (hook SessionStart carrega memory automaticamente)
3. Acione **`/squad-resume`** — **obrigatório como 1º passo de toda retomada** (não opcional). TL faz `git fetch` + cross-check do Current Focus contra o git remoto, lê Session Log e PRs abertos, apresenta delta + próximo passo acionável. Pular o resume já causou re-implementação de trabalho inteiro já mergeado
4. Confirme direção ou redirecione
5. Ao encerrar sessão significativa, acione **`/squad-handoff`** — TL atualiza memory para próximo usuário (continuidade multi-user)

Ver [`CLAUDE.md` → "Multi-user Continuity"](CLAUDE.md#multi-user-continuity-handoffresume) para workflow completo.

### Você quer refatorar

Acione o **Product Owner** com objetivo da refatoração (o quê e por quê). Fluxo 4 do CLAUDE.md aplica.

### Você quer reportar bug ou pedir melhoria

- **Bug:** acione o Tech Lead diretamente OU registre issue no tracker (Support Engineer triage)
- **Melhoria:** acione o Product Owner

Severidades: Sev1 (sistema fora) / Sev2 (degradação) / Sev3+ (não crítico). Ver [Fluxo de Bug em Produção](CLAUDE.md#fluxo-de-bug-em-produção).

---

## Estrutura do Projeto

```
/ (raiz livre para arquivos do produto: src/, tests/, package.json, etc.)
│
├── README.md             ← este arquivo
├── AGENTS.md             ← índice dos 14 agentes (tool-agnostic)
├── CLAUDE.md             ← governança, fluxos, gates, modos
│
└── .claude/
    ├── settings.json     ← config de hooks (opt-in)
    ├── skills/           ← skills Claude Code (14 skills da squad)
    ├── hooks/            ← scripts de hooks (load-memory, architecture-reminder)
    └── squad/
        ├── template/             ← imutável (sobrescrito em update)
        │   ├── agents/                  ← 14 agentes
        │   ├── docs/
        │   │   ├── PRD-template.md
        │   │   ├── stack-conventions/   (backend, frontend, mobile)
        │   │   └── design-system/README.md
        │   ├── memory/
        │   │   ├── ADR/                 ← ADR-template + 5 defaults
        │   │   └── agent-memory/README.md
        │   └── contracts/               ← README + example
        │
        └── project/              ← estado vivo (preservado em update)
            ├── ARCHITECTURE.md
            ├── DECISIONS_LOG.md
            ├── TASK_BOARD.md
            ├── PRD.md                   ← criado durante uso
            ├── ADR/                     ← ADRs específicos do projeto
            ├── agent-memory/            ← 14 skeletons populados
            ├── contracts/               ← contratos reais
            ├── design-system/           ← tokens, componentes, patterns
            ├── docs/                    ← specs funcionais
            └── runbooks/                ← incidentes, DR
```

---

## Agentes

Quatorze agentes com fronteiras claras. Modelos por agente:

### Opus (decisão e raciocínio sistêmico)

| Agente | Papel |
|--------|-------|
| [Product Owner](.claude/squad/template/agents/product-owner.md) | O quê construir, regras de negócio, critérios de aceite |
| [Tech Lead](.claude/squad/template/agents/tech-lead.md) | Orquestração, governança técnica, plano de execução |
| [Architect](.claude/squad/template/agents/architect.md) | Arquitetura, domínio (DDD), contratos, decisão de stack |
| [Security Engineer](.claude/squad/template/agents/security-engineer.md) | Threat modeling, compliance, auth/authz, pentest |
| [Product Designer](.claude/squad/template/agents/product-designer.md) | Design System, UX, UI, acessibilidade visual (consultor — canal direto ao usuário) |

### Sonnet (execução)

| Agente | Papel |
|--------|-------|
| [Backend Engineer](.claude/squad/template/agents/backend-engineer.md) | APIs, lógica de negócio, persistência |
| [Frontend Engineer](.claude/squad/template/agents/frontend-engineer.md) | Interface web, Atomic Design |
| [Mobile Engineer](.claude/squad/template/agents/mobile-engineer.md) | Apps iOS/Android, Clean Architecture mobile |
| [AI Engineer](.claude/squad/template/agents/ai-engineer.md) | Agentes de IA, prompts, MCP, tools |
| [QA Engineer](.claude/squad/template/agents/qa-engineer.md) | Testes (TDD), validação de comportamento |
| [Code Reviewer](.claude/squad/template/agents/code-reviewer.md) | Qualidade do código, OWASP no código |
| [DevOps Engineer](.claude/squad/template/agents/devops-engineer.md) | CI/CD, infra, observabilidade, SRE |
| [Support Engineer](.claude/squad/template/agents/support-engineer.md) | Triagem de issues (bug vs melhoria) |
| [Data Engineer](.claude/squad/template/agents/data-engineer.md) | Pipelines, modelagem analítica (consultor) |

### Hierarquia e canais

```
Usuário (autoridade máxima)
├── Product Owner — define o QUÊ (par do Tech Lead e Product Designer)
├── Tech Lead — define o COMO e orquestra
├── Product Designer — define visual/UX (consultor; quando alocado é peer)
└── Demais agentes — respondem ao Tech Lead
```

- **PO, TL e Product Designer** podem interagir diretamente com o usuário
- **Demais agentes** respondem ao Tech Lead
- **Frontend/Mobile** podem tirar **dúvidas pontuais** com Product Designer (canal aberto); **decisões** visuais sempre via TL
- **Support Engineer** escala issues via TL (canal único); TL roteia bugs/melhorias
- **Divergências PO/TL/PD** → resolvidas pelo usuário

---

## Modos de Operação

O Tech Lead define o modo conforme contexto do projeto.

### MVP Mode

| Aspecto | Comportamento |
|---------|---------------|
| Cobertura de testes | ≥ 60% em regras críticas |
| Observabilidade | Logs estruturados (mínimo) |
| Arquitetura | Monólito modular preferencial |
| SRE | Health checks básicos; sem SLOs formais |
| Chaos Engineering | Não obrigatório |
| Post-mortem | Informal |
| Security Engineer | Consultado para features críticas |

### Production Mode

| Aspecto | Comportamento |
|---------|---------------|
| Cobertura de testes | ≥ 80% geral / ≥ 95% em regras críticas |
| Observabilidade | Completa (logs + métricas + tracing + alertas) |
| Arquitetura | Definida pelo Architect conforme NFRs |
| SRE | SLOs definidos, error budgets, circuit breakers |
| Chaos Engineering | Quando aplicável |
| Post-mortem | Formal (≤ 48h Sev1, ≤ 72h Sev2) |
| Security Engineer | Obrigatório para features críticas |
| Deploy | Canary / Blue-Green / Feature Flags |

---

## Práticas Críticas

### TDD First

Nenhuma implementação começa sem critérios de aceite, contratos e testes definidos. QA define cenários antes de Engineers implementarem. CI passa testes automaticamente.

### Arquitetura Hexagonal (Ports & Adapters)

Padrão preferencial em **backend** e **camada de IA** quando couber. Domain isolado de adapters externos (HTTP, DB, LLM, queue). Ver [`.claude/squad/template/memory/ADR/ADR-002-arquitetura-hexagonal.md`](.claude/squad/template/memory/ADR/ADR-002-arquitetura-hexagonal.md).

```
domain/        → entidades, regras, ports (interfaces)
application/   → use cases que orquestram domain via ports
adapters/
  ├── inbound/  → HTTP controllers, MCP handlers, message consumers
  └── outbound/ → DB repositories, LLM clients, external APIs
```

### Design System (Material 3 default)

Documentação viva do DS em `.claude/squad/project/design-system/`. Mantido pelo **Product Designer**; consumido por Frontend/Mobile.

**Default:** Material Design 3 (cross-platform Web + Mobile, open source, maduro)

**Alternativas suportadas:** shadcn/ui, Carbon (IBM), Polaris (Shopify), Atlassian DS, Custom — PD justifica em ADR específico do projeto.

**Em projetos existentes sem doc:** PD extrai DS da UI atual quando primeira feature visual chega (skill `/squad-design-extract`).

Ver [`.claude/squad/template/memory/ADR/ADR-005-design-system.md`](.claude/squad/template/memory/ADR/ADR-005-design-system.md).

### Stack Conventions

Convenções idiomáticas por linguagem/framework em `.claude/squad/template/docs/stack-conventions/`. Cada documento define **quando usar**, **tooling**, **layout**, **padrões idiomáticos**, **comandos** e **anti-patterns**.

**Backend:** Node.js, Python, PHP, Java, Go
**Frontend:** React + Next.js, Vue + Nuxt
**Mobile:** Flutter, React Native

Architect consulta ao decidir stack do projeto. Engineers consultam o documento da stack ativa ao implementar.

Ver índice: [`.claude/squad/template/docs/stack-conventions/README.md`](.claude/squad/template/docs/stack-conventions/README.md).

### Skills e Hooks (Claude Code)

A squad inclui automações opcionais via Claude Code. Ver [`.claude/squad/template/memory/ADR/ADR-004-skills-e-hooks.md`](.claude/squad/template/memory/ADR/ADR-004-skills-e-hooks.md).

**Skills disponíveis (14):**

| Comando | Quando usar |
|---------|-------------|
| `/squad-new-project` | Início de Fluxo 1 (projeto novo sem artefatos) |
| `/squad-prd-template` | PO criando PRD completo |
| `/squad-threat-model` | SE Fase 1 sobre arquitetura proposta |
| `/squad-flag-audit` | TL review mensal de feature flags |
| `/squad-scope-change` | Mudança de escopo durante execução |
| `/squad-stack-decision` | Architect decide stack do projeto |
| `/squad-incident` | Resposta a Sev1/Sev2 em produção |
| `/squad-deploy-preflight` | DevOps valida Docker/env/migrations localmente ANTES de deploy em PaaS |
| `/squad-design-system-new` | Product Designer propõe DS para projeto novo com UI |
| `/squad-design-extract` | Product Designer extrai DS da UI de projeto existente sem doc |
| `/squad-design-audit` | Product Designer audita consistência visual em produto maduro |
| `/squad-handoff` | TL conduz encerramento de sessão preparando handoff |
| `/squad-resume` | TL conduz retomada de projeto por novo usuário |
| `/squad-status` | TL apresenta snapshot rápido do estado do projeto |

**Hooks ativos:**

- `SessionStart` → carrega `.claude/squad/project/` (ARCHITECTURE, TASK_BOARD, DECISIONS_LOG, ADRs) no contexto inicial
- `PostToolUse` em edição de `.claude/squad/project/ARCHITECTURE.md` → lembra de atualizar `.claude/squad/project/DECISIONS_LOG.md`
- `PreToolUse` em `git commit` (opt-in) → sugere atualizar memory quando há commit de código sem memory correspondente

**CI Enforcement (opcional):**

Templates em [`.claude/squad/template/ci/`](.claude/squad/template/ci/) para projetos que querem enforcement automatizado da disciplina de memory:

- [`memory-check.yml.example`](.claude/squad/template/ci/memory-check.yml.example) — GitHub Actions valida PRs (comment em PR sugerindo update de memory)
- [`pre-commit.example`](.claude/squad/template/ci/pre-commit.example) — git hook local (aviso antes de commit)
- [`README.md`](.claude/squad/template/ci/README.md) — instalação, customização e governança

Opt-in: copiar para localização ativa (`.github/workflows/` para CI, `.githooks/` para git hooks). Default não-bloqueante (warning, não fail). Projeto pode endurecer em Production Mode.

Skills/hooks são governadas por critério rigoroso (≥3 usos para criar; revisão trimestral; remover não-usadas em 90 dias). Não são criadas autonomamente — TL propõe, usuário aprova.

### Feature Flags (default em features críticas)

Toda feature crítica nova entra atrás de flag por padrão. Governança obrigatória: dono, prazo de remoção (default 90 dias), kill switch testado, review mensal. Ver [`.claude/squad/template/memory/ADR/ADR-003-feature-flags.md`](.claude/squad/template/memory/ADR/ADR-003-feature-flags.md).

Critério "feature crítica":
- autenticação e autorização
- processamento de pagamentos
- acesso a dados Confidencial ou Restrito
- integrações com sistemas externos sensíveis
- qualquer rota que processe dados pessoais (LGPD/GDPR)

### Segurança em Camadas

Cada agente tem fronteira clara de segurança:

| Agente | Fronteira |
|--------|-----------|
| Architect | Por DESIGN (classificação, threat model alto nível, criptografia, modelo de acesso) |
| Code Reviewer | DO CÓDIGO (OWASP no código, validação, sanitização) |
| Security Engineer | COMO ESPECIALIDADE (threat modeling profundo, compliance, pentest) |
| QA Engineer | DO COMPORTAMENTO (auth/authz funciona, inputs maliciosos) |
| DevOps Engineer | DA INFRAESTRUTURA (secrets, IAM, rede, SAST) |
| AI Engineer | DA CAMADA IA (prompt injection, vazamento via output, isolamento de contexto) |
| Tech Lead | Coordenação e veto final em conflitos |

Security Engineer é acionado em **duas fases**:
1. **Fase de Arquitetura** — threat model sobre arquitetura proposta (mais barato mitigar cedo)
2. **Fase de Revisão** — auth/authz, criptografia, compliance, pentest review antes do deploy

---

## Quality Gates

Toda execução passa por gates obrigatórios:

| Gate | Quem decide | Bloqueia |
|------|-------------|----------|
| PRD aprovado | Usuário | Toda execução |
| Arquitetura aprovada | Usuário | Implementação |
| Stack aprovada | Usuário | Implementação |
| Contratos definidos | Architect → TL | Implementação |
| Testes definidos | QA | Implementação (TDD) |
| CI verde | Pipeline (auto) | Revisões humanas |
| QA aprovou | QA | Code Review |
| Code Reviewer aprovou | CR | Security Review |
| Security Engineer aprovou | SE | Quality Gates (features críticas) |
| Quality Gates passaram | TL | Deploy |
| Deploy estável | DevOps + TL | Done |

### Fluxo de Revisão (Paralelo)

Após CI verde, três dimensões avaliadas **em paralelo**:

```
CI verde → ┬─→ QA Engineer (comportamento)
           ├─→ Code Reviewer (qualidade do código)
           └─→ Security Engineer (Fase 2 — features críticas)
                              │
                              ▼
                       Quality Gates (TL integra)
                              │
                              ▼
                        Deploy (DevOps)
```

Falha em qualquer dimensão → volta para dev → CI roda → revisão refaz só o que mudou.

---

## Definition of Done Global

Uma entrega só está completa quando:

- [ ] Código implementado e revisado
- [ ] Self-review do engineer completo + gate determinístico local verde ([`engineer-self-review.md`](.claude/squad/template/docs/engineer-self-review.md))
- [ ] Testes passando (cobertura conforme modo)
- [ ] Contratos respeitados e atualizados em `/contracts`
- [ ] QA aprovou comportamento
- [ ] Code Reviewer aprovou qualidade do código
- [ ] Security Engineer aprovou (features críticas)
- [ ] Pipeline CI/CD verde
- [ ] Deploy realizado e **VERIFICADO**: deployment SUCCESS no SHA esperado + migrations do ambiente aplicadas (Merged ≠ Deployed; healthz não basta)
- [ ] Smoke E2E de 1 fluxo crítico validado no ambiente real pós-deploy
- [ ] Sistema monitorado (logs disponíveis; alertas ativos em Production)
- [ ] Rollback testado (Production Mode)
- [ ] README do módulo atualizado
- [ ] `.claude/squad/project/ARCHITECTURE.md` atualizado (quando há mudança estrutural)
- [ ] `.claude/squad/project/DECISIONS_LOG.md` atualizado (quando há decisão relevante)
- [ ] `.claude/squad/project/TASK_BOARD.md` atualizado (tarefa movida para Done)
- [ ] Feature flag definida e testada em ambos os paths (features críticas)

---

## Memória do Sistema

A squad mantém **memória viva** do projeto:

### Memória Compartilhada (`/memory`)

| Arquivo | Propósito |
|---------|-----------|
| `ARCHITECTURE.md` | Visão atual da arquitetura |
| `DECISIONS_LOG.md` | Decisões rápidas (linha por linha) |
| `TASK_BOARD.md` | Kanban de tarefas (Todo / Doing / Review / Done) |
| `ADR/` | Decisões arquiteturais versionadas |
| `agent-memory/` | Memória especializada por agente (≤ 200 linhas cada) |
| `LESSONS_LEARNED.md` | Melhorias do **sistema da squad** (specs, skills, hooks, processo) — template em [`LESSONS_LEARNED-template.md`](.claude/squad/template/LESSONS_LEARNED-template.md) |

**Regra:** se não está documentado aqui, **não existe**.

**Distinção crítica:** learning técnico do projeto (gotcha de lib, padrão de código) → `agent-memory`. Melhoria do sistema da squad (gap em spec, skill, hook, processo) → `LESSONS_LEARNED.md`, sempre citando o arquivo a modificar + ação concreta.

### Architecture Decision Records (ADRs)

ADRs ativos:

- [`ADR-001-stack.md`](.claude/squad/template/memory/ADR/ADR-001-stack.md) — opções de stack padrão (Architect decide por projeto)
- [`ADR-002-arquitetura-hexagonal.md`](.claude/squad/template/memory/ADR/ADR-002-arquitetura-hexagonal.md) — Hexagonal preferencial em backend e AI
- [`ADR-003-feature-flags.md`](.claude/squad/template/memory/ADR/ADR-003-feature-flags.md) — Flags default em features críticas

Template para novos ADRs: [`.claude/squad/template/memory/ADR/ADR-template.md`](.claude/squad/template/memory/ADR/ADR-template.md).

### Agent Memory

Cada agente mantém arquivo em `.claude/squad/project/agent-memory/{agent-name}.md` com:
- Padrões adotados pelo agente neste projeto
- Learnings acumulados
- Decisões pequenas que não viram ADR
- Links para ADR e seções de ARCHITECTURE.md

Limite ≤ 200 linhas por arquivo. Tech Lead audita trimestralmente. Ver [`.claude/squad/template/memory/agent-memory/README.md`](.claude/squad/template/memory/agent-memory/README.md) para governança.

---

## Contratos (`/contracts`)

Toda integração entre componentes é definida por contrato versionado.

| Tipo | Formato |
|------|---------|
| APIs REST | OpenAPI 3.1 (YAML) |
| Schemas de validação | JSON Schema ou Zod (TypeScript) |
| Interfaces | TypeScript types |
| Eventos / mensagens | AsyncAPI ou JSON Schema |

Mudanças breaking → bump major. Mudanças não-breaking → bump minor. Mudança não versionada → bloqueia implementação.

Exemplo funcional: [`.claude/squad/template/contracts/example.openapi.yaml`](.claude/squad/template/contracts/example.openapi.yaml).

---

## Fluxos de Projeto

Cinco fluxos suportados, todos definidos em [CLAUDE.md → Fluxos de Projeto](CLAUDE.md#fluxos-de-projeto):

1. **Projeto novo** (sem artefatos) — PO cria PRD do zero
2. **Projeto novo com artefatos** — usuário entrega PRD pronto, PO organiza
3. **Continuidade** — TL lê estado e cria plano
4. **Refatoração** — PO documenta objetivo e crítico, TL avalia impacto
5. **Manutenção/Evolução** — Support Engineer triage + PO/TL orquestram

---

## Política de Indisponibilidade do Usuário

Múltiplos gates dependem de aprovação do usuário. Quando o usuário está indisponível:

| Gate | Comportamento |
|------|---------------|
| PRD inicial / Arquitetura / Stack | Bloqueia execução |
| Scope change | Continua no escopo aprovado original |
| Sev1 hotfix | TL assume autoridade temporária; usuário ratifica depois |
| Sev2 hotfix | Aguarda 1h; depois TL pode proceder |
| Sev3+ | Aguarda |

Decisões autônomas → registradas em `.claude/squad/project/DECISIONS_LOG.md` com tag `tl-autonomous`. TL ratifica em até 24h após retorno do usuário.

---

## Princípios de Produto

Toda aplicação criada pela squad é avaliada em **6 eixos** — critério de decisão em todo gate (plano, arquitetura, review):

1. **Qualidade** — funciona, testado, sem regressão
2. **Simplicidade de solução** — a menor solução que atende o requisito (simplicidade tem peso igual a escalabilidade)
3. **Facilidade de uso** — usuário leigo completa o fluxo crítico sem ajuda
4. **Escalabilidade** — escala o que o PRD pede (volumetria declarada), não o hipotético
5. **Resiliência** — degradação graciosa: falha de dependência tem comportamento definido (timeout, retry, fallback, kill-switch)
6. **Expansibilidade** — pontos de extensão DECLARADOS no PRD são extensíveis; o resto segue YAGNI

---

## Princípios Universais

Aplicáveis a todos os agentes de engenharia:

- **DRY** — sem repetição real (não especulativa)
- **KISS** — solução mais simples que resolve
- **YAGNI** — sem construir para casos hipotéticos
- **SOLID** — Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion
- **Atomic Design** (Frontend / Mobile) — Atoms → Molecules → Organisms → Templates → Pages
- **Hexagonal** (Backend / AI quando couber) — domain isolado de adapters
- **Feature Flags default** em features críticas
- **Qualidade na origem** — engineer pega o próprio erro via self-review ([`engineer-self-review.md`](.claude/squad/template/docs/engineer-self-review.md)); review e security confirmam, não descobrem
- **Merged ≠ Deployed** — "deployado" é estado observado (SHA + migrations + smoke E2E), nunca inferido do merge
- **Economia de tokens** — comunicação inter-agente direta e por referência (paths, não cópia de conteúdo); respostas de subagente em formato fixo curto; informação de memória em UM lugar, referenciada nos demais

---

## Distribuição e Versionamento (Plugin)

A squad é distribuída como **plugin Claude Code** — este repositório é o **upstream oficial** e também o marketplace:

```bash
/plugin marketplace add Sync4-Technologies/template-project
/plugin install squad@pdati
```

- **Fonte canônica:** [`plugin/`](plugin/) (skills, hooks, specs de agentes, docs, templates). Toda melhoria entra AQUI primeiro.
- **Adoção em projeto:** `/squad-init` cria `.claude/squad/project/` (memória viva) + `SQUAD_VERSION` — o projeto carrega só o ESTADO; o comportamento vem do plugin, versionado.
- **Versionamento:** SemVer no `plugin/.claude-plugin/plugin.json`; update é explícito por máquina/usuário, nunca silencioso. `SQUAD_VERSION` no projeto registra qual governança valia em cada fase.
- **Regra anti-drift:** proibido editar arquivos do plugin/template dentro de um projeto. Gap no sistema → `LESSONS_LEARNED.md` do projeto → backport aqui → bump de versão → projetos atualizam.
- **Layout legado (clone do template):** continua funcionando para projetos existentes; `/squad-init` migra (preserva `project/`, remove cópias locais com confirmação). O diretório `.claude/` deste repo mantém a cópia legada até a migração dos projetos ativos — mudanças novas vão em `plugin/`.

---

## Como Estender ou Customizar

### Adicionar um novo agente
1. Criar `.claude/squad/template/agents/{name}.md` (espelhar estrutura existente)
2. Criar `.claude/squad/project/agent-memory/{name}.md` (template)
3. Atualizar `AGENTS.md` (tabela)
4. Atualizar `CLAUDE.md` (Modelos por Agente, Hierarquia se afetado)

### Mudar a stack do projeto
1. Architect propõe 2-3 opções com trade-offs em `.claude/squad/project/ADR/ADR-NNN-stack-projeto.md`
2. Tech Lead apresenta ao usuário
3. Usuário aprova/veta
4. Atualizar `.claude/squad/project/ARCHITECTURE.md` → seção "Stack Tecnológica"

### Adicionar um novo fluxo de projeto
1. Tech Lead propõe em [CLAUDE.md → Fluxos de Projeto](CLAUDE.md#fluxos-de-projeto)
2. Validar não há sobreposição com fluxos existentes
3. Documentar gates obrigatórios

### Customizar regras de qualidade
- Cobertura de testes pode ser **elevada** via NFR no PRD (Architect) — nunca reduzida abaixo do mínimo do modo
- Outras regras → discutir com Tech Lead, registrar em ADR

---

## Governança e Fontes de Verdade

| Tópico | Fonte autoritativa |
|--------|---------------------|
| Identidade da squad | [`AGENTS.md`](AGENTS.md) |
| Regras gerais, fluxos, gates | [`CLAUDE.md`](CLAUDE.md) |
| Modelos por agente | `CLAUDE.md` → "Modelos por Agente" |
| Regras de cada agente | `.claude/squad/template/agents/{name}.md` |
| Estado atual do sistema | `.claude/squad/project/ARCHITECTURE.md` |
| Decisões versionadas | `.claude/squad/project/ADR/` |
| Decisões rápidas | `.claude/squad/project/DECISIONS_LOG.md` |
| Tarefas em andamento | `.claude/squad/project/TASK_BOARD.md` |
| Contratos do sistema | `.claude/squad/project/contracts/` |
| PRD e specs | `/docs/` |
| Padrões de squad | Aqui (este README) |

Em caso de conflito entre arquivos: **CLAUDE.md prevalece**.

---

## Modelo Mental para o Usuário

Quando você quer algo construído ou suportado, **só fala com PO ou TL**.

- **Quer algo novo, tem dúvida sobre comportamento, regra de negócio, escopo?** → fale com **Product Owner**
- **Quer algo técnico, mudança de prioridade, status, bug?** → fale com **Tech Lead**

Se errar o canal, eles encaminham para o correto. Você nunca precisa saber qual agente faz o quê — TL e PO orquestram.

---

## Documentos para Leitura Inicial

Ordem recomendada para entender este template:

1. **`README.md`** (você está aqui)
2. **[`AGENTS.md`](AGENTS.md)** — índice dos agentes
3. **[`CLAUDE.md`](CLAUDE.md)** — governança e fluxos completos
4. **[`.claude/squad/template/agents/tech-lead.md`](.claude/squad/template/agents/tech-lead.md)** — orquestração
5. **[`.claude/squad/template/agents/product-owner.md`](.claude/squad/template/agents/product-owner.md)** — definição de produto
6. **[`.claude/squad/template/memory/ADR/ADR-001-stack.md`](.claude/squad/template/memory/ADR/ADR-001-stack.md)** — opções de stack padrão
7. **[`.claude/squad/template/memory/ADR/ADR-002-arquitetura-hexagonal.md`](.claude/squad/template/memory/ADR/ADR-002-arquitetura-hexagonal.md)** — padrão arquitetural
8. **[`.claude/squad/template/memory/ADR/ADR-003-feature-flags.md`](.claude/squad/template/memory/ADR/ADR-003-feature-flags.md)** — governança de flags
9. **[`.claude/squad/template/docs/PRD-template.md`](.claude/squad/template/docs/PRD-template.md)** — template para PRD de feature/produto

---

## Filosofia

> O objetivo não é gerar código.
>
> O objetivo é construir sistemas **corretos, sustentáveis, escaláveis, seguros, resilientes e observáveis**.

A squad é uma ferramenta de governança. Cada agente especialista tem uma responsabilidade clara. Cada gate existe por uma razão. Cada artefato tem uma fonte de verdade.

Se algo não está documentado aqui ou em uma das fontes de verdade, **não existe**. Se uma execução pula um gate, **bloqueie**. Se há ambiguidade, **escale**.

Qualidade e segurança não são opcionais.

---

## Licença e Atribuição

Este template é uma estrutura de governança e práticas — não contém código de produto. Adapte livremente para seus projetos.
