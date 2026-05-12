# Sistema de Engenharia com Agentes

## Objetivo

Este repositório define um sistema de desenvolvimento de software baseado em agentes especializados.

O objetivo é padronizar a forma como sistemas são:

- concebidos
- projetados
- implementados
- validados
- operados

Garantindo:

- qualidade consistente
- decisões governadas
- escalabilidade técnica
- previsibilidade na execução

---

## Escopo

Este modelo é genérico e reutilizável.

Ele pode ser aplicado a diferentes tipos de projetos, independentemente de:

- domínio de negócio
- stack tecnológica
- tamanho do sistema

Adaptações devem ser feitas nos artefatos de projeto (PRD, arquitetura, contratos), não na estrutura do sistema de agentes.

---

## Estrutura de Pastas

```
/ (raiz do projeto — livre para arquivos do produto)
│
├── README.md                  ← entrada principal
├── AGENTS.md                  ← índice de agentes (tool-agnostic)
├── CLAUDE.md                  ← este arquivo (governança e fluxos)
│
└── .claude/
    ├── settings.json          ← config de hooks (opt-in)
    ├── skills/                ← skills Claude Code (workflows automatizados)
    ├── hooks/                 ← scripts de hooks (SessionStart, PostToolUse)
    └── squad/
        ├── template/          ← imutável (sobrescrito em update do template)
        │   ├── agents/                  ← definições dos 14 agentes
        │   ├── docs/
        │   │   ├── PRD-template.md
        │   │   ├── stack-conventions/   (backend, frontend, mobile)
        │   │   └── design-system/README.md
        │   ├── memory/
        │   │   ├── ADR/                 ← ADR-template + defaults 001-005
        │   │   └── agent-memory/README.md   ← governança
        │   └── contracts/               ← README + example.openapi.yaml
        │
        └── project/           ← estado vivo (preservado em update)
            ├── ARCHITECTURE.md
            ├── DECISIONS_LOG.md
            ├── TASK_BOARD.md
            ├── PRD.md                   ← criado durante uso
            ├── ADR/                     ← ADRs específicos do projeto
            ├── agent-memory/            ← 14 skeletons populados
            ├── contracts/               ← contratos reais
            ├── design-system/           ← tokens, componentes, patterns
            ├── docs/                    ← specs funcionais, fluxos
            └── runbooks/                ← procedimentos de incidente, DR
```

---

## O que vai em cada pasta

### `.claude/squad/template/` (imutável)

Contém o template estático da squad. **Sobrescrito** em updates futuros do template.

- `agents/` — 14 specs de agentes (roles conceituais; **não** subagents Claude Code)
- `docs/PRD-template.md` — template para PRD do projeto
- `docs/stack-conventions/` — convenções idiomáticas por linguagem (Architect consulta; Engineers consultam)
- `docs/design-system/README.md` — índice/governança do DS (PD popula `project/design-system/`)
- `memory/ADR/` — ADR-template + 5 ADRs default da squad (001-005)
- `memory/agent-memory/README.md` — governança de agent memory
- `contracts/README.md` + `example.openapi.yaml` — convenções de contratos

### `.claude/squad/project/` (estado vivo)

Contém o **estado** populado durante execução. **Preservado** em updates.

- `ARCHITECTURE.md` — visão atual da arquitetura
- `DECISIONS_LOG.md` — decisões rápidas
- `TASK_BOARD.md` — kanban de tarefas
- `PRD.md` — PRD real do projeto (criado pelo PO)
- `ADR/` — ADRs específicos do projeto (ADR-NNN+)
- `agent-memory/` — 14 skeletons populados pelos agentes
- `contracts/` — APIs reais (OpenAPI, JSON Schema, Zod)
- `design-system/` — tokens, componentes, patterns (mantido pelo PD)
- `docs/` — specs funcionais, fluxos específicos
- `runbooks/` — procedimentos de incidente, DR

### `.claude/skills/` e `.claude/hooks/`

Semântica oficial Claude Code:
- `skills/` — 10 skills da squad (`/squad-new-project`, `/squad-prd-template`, etc.)
- `hooks/` — `load-memory.sh` (SessionStart), `architecture-reminder.sh` (PostToolUse)
- `settings.json` — configuração opt-in dos hooks

### Regra

Se não está documentado nas pastas acima → **não existe**.

A raiz do projeto fica **livre** para arquivos do produto (`src/`, `tests/`, `package.json`, etc.).

---

## Estrutura de Agentes

Os agentes estão definidos em `.claude/squad/template/agents/`. Para índice tabular com modelo de cada um, ver [AGENTS.md](AGENTS.md).

---

## Papéis dos Agentes

> Resumo. Definição completa de cada agente em `.claude/squad/template/agents/{name}.md`. Índice tabular em [AGENTS.md](AGENTS.md).

### Opus (decisão e raciocínio sistêmico)

- **[Product Owner](.claude/squad/template/agents/product-owner.md)** — define o quê construir, regras de negócio, critérios de aceite
- **[Tech Lead](.claude/squad/template/agents/tech-lead.md)** — orquestração, governança técnica, plano de execução
- **[Architect](.claude/squad/template/agents/architect.md)** — arquitetura, domínio (DDD), contratos, decisão de stack
- **[Security Engineer](.claude/squad/template/agents/security-engineer.md)** — threat modeling, compliance, auth/authz, pentest review
- **[Product Designer](.claude/squad/template/agents/product-designer.md)** — Design System, UX, UI, acessibilidade visual (consultor com canal direto ao usuário; gate em features visuais críticas)

### Sonnet (execução)

- **[Backend Engineer](.claude/squad/template/agents/backend-engineer.md)** — APIs, lógica de negócio, persistência
- **[Frontend Engineer](.claude/squad/template/agents/frontend-engineer.md)** — interface web, Atomic Design, integração com backend
- **[Mobile Engineer](.claude/squad/template/agents/mobile-engineer.md)** — apps iOS/Android, Clean Architecture mobile
- **[AI Engineer](.claude/squad/template/agents/ai-engineer.md)** — agentes de IA, prompts, MCP, tools
- **[QA Engineer](.claude/squad/template/agents/qa-engineer.md)** — testes (TDD), validação de comportamento
- **[Code Reviewer](.claude/squad/template/agents/code-reviewer.md)** — qualidade do código, OWASP no código
- **[DevOps Engineer](.claude/squad/template/agents/devops-engineer.md)** — CI/CD, infra, observabilidade, SRE
- **[Support Engineer](.claude/squad/template/agents/support-engineer.md)** — monitoramento de issues, triagem (bug vs melhoria)
- **[Data Engineer](.claude/squad/template/agents/data-engineer.md)** — pipelines, modelagem analítica (consultor)

---

## Regra de Interação

O usuário pode interagir diretamente com:
- **Product Owner** — o quê construir, regras de negócio
- **Tech Lead** — orquestração técnica, status
- **Product Designer** — questões visuais e UX (quando alocado ou acionado pelo usuário)

Frontend Engineer e Mobile Engineer podem tirar **dúvidas pontuais** com Product Designer diretamente (canal aberto). **Decisões** visuais sempre via TL orquestrando.

Todos os outros agentes:
- NÃO falam com o usuário
- Respondem apenas ao Tech Lead

---

## Hierarquia

```
Usuário (autoridade máxima)
├── Product Owner — define o QUÊ (par do Tech Lead e Product Designer)
├── Tech Lead — define o COMO e orquestra
├── Product Designer — define visual/UX (consultor; quando alocado é peer)
│
└── Tech Lead orquestra os demais:
    ├── Architect
    ├── Backend / Frontend / Mobile / AI Engineer
    ├── QA / Code Reviewer / Security Engineer
    ├── DevOps Engineer
    ├── Support Engineer (monitoramento e triagem)
    └── Data Engineer (consultor — acionado quando necessário)
```

Product Owner, Tech Lead e Product Designer (quando alocado) são **pares**:
- Não se subordinam mutuamente
- PO define o quê; TL define como e orquestra; PD define visual/UX
- Divergências entre eles são resolvidas pelo usuário
- Support Engineer escala issues **sempre via TL** (orquestrador único). TL roteia: bug fica com TL; melhoria é encaminhada ao PO
- Product Designer é **consultor** — fora do fluxo padrão; alocado pelo TL ou acionado pelo usuário. Frontend/Mobile podem consultar PD para dúvidas pontuais; decisões via TL

---

## Fluxo de Execução

1. Product Owner define PRD e Especificação Funcional
2. Usuário aprova ou ajusta
3. Tech Lead cria plano
4. Architect define arquitetura + stack
5. Security Engineer (Fase 1) faz threat model sobre arquitetura — em features críticas
6. Tech Lead apresenta arquitetura ao usuário
7. Usuário aprova ou rejeita
8. Architect define contratos em `.claude/squad/project/contracts/`
9. QA define testes (TDD)
10. Engineers implementam
11. CI automatizado: testes + lint + build + SAST (gate técnico)
12. **Em paralelo** (após CI verde): QA exploratório + Code Reviewer + Security Engineer (Fase 2 em features críticas)
13. Tech Lead integra Quality Gates
14. DevOps executa deploy (canary/blue-green em Production Mode)
15. Tech Lead valida entrega final + atualiza memória

---

## Gate Obrigatórios

Nenhuma execução pode avançar sem:
- PRD aprovado (pelo usuário)
- Arquitetura aprovada (pelo usuário)
- Testes definidos (TDD)
- QA aprovado (comportamento)
- Code Reviewer aprovado (código)
- Security Engineer aprovado (features críticas)

---

## Modelos por Agente

### Opus (decisão e raciocínio sistêmico)
- Product Owner
- Tech Lead
- Architect
- Security Engineer
- Product Designer

### Sonnet (execução)
- Backend Engineer
- Frontend Engineer
- Mobile Engineer
- AI Engineer
- QA Engineer
- Code Reviewer
- DevOps Engineer
- Support Engineer
- Data Engineer

---

## Princípios Universais

Aplicáveis a todos os agentes de engenharia. Cada agente referencia estes princípios em vez de redefini-los.

### DRY (Don't Repeat Yourself)
Nenhuma lógica deve existir em dois lugares. Abstrair quando há repetição real (não especulativa).

### KISS (Keep It Simple, Stupid)
A solução mais simples que resolve o problema é a correta. Complexidade só entra quando há necessidade real.

### YAGNI (You Ain't Gonna Need It)
Não construir o que não está no escopo atual. Sem abstração para "casos futuros" hipotéticos.

### SOLID
- **S** — Single Responsibility: cada classe/módulo faz UMA coisa
- **O** — Open/Closed: aberto para extensão, fechado para modificação
- **L** — Liskov Substitution: subtipos substituíveis sem quebrar contratos
- **I** — Interface Segregation: interfaces específicas > interfaces gordas
- **D** — Dependency Inversion: dependa de abstrações, nunca de implementações concretas

### Atomic Design (Frontend / Mobile)
- Atoms → Molecules → Organisms → Templates → Pages
- Cada componente independente e testável isoladamente
- Design tokens centralizados; nenhum valor mágico inline

### Hexagonal (Backend / AI — quando couber)
- Domain isolado de adapters externos (HTTP, DB, LLM, queue)
- Default em features críticas e domínio rico
- Ver `.claude/squad/template/memory/ADR/ADR-002-arquitetura-hexagonal.md` para critérios

### Feature Flags (default em features críticas)
- Toda feature crítica nova entra atrás de flag por padrão
- Governança rígida: dono, prazo 90 dias, kill switch testado, review mensal
- Combina com Hexagonal (adapter trocável por flag)
- Ver `.claude/squad/template/memory/ADR/ADR-003-feature-flags.md` para regras completas

---

## MVP vs Production Mode

A definição de modo é responsabilidade do **Tech Lead** com base no contexto do projeto.

### MVP Mode
| Aspecto | Comportamento |
|---------|--------------|
| Cobertura de testes | ≥ 60% em regras críticas |
| Observabilidade | Logs estruturados (mínimo) |
| Arquitetura | Monólito modular (preferencial) |
| SRE | Health checks básicos; sem SLOs formais |
| Chaos Engineering | Não obrigatório |
| Post-mortem | Informal |
| Security Engineer | Consultado para features críticas |

### Production Mode
| Aspecto | Comportamento |
|---------|--------------|
| Cobertura de testes | ≥ 80% geral / ≥ 95% em regras críticas |
| Observabilidade | Completa (logs + métricas + tracing + alertas) |
| Arquitetura | Definida pelo Architect conforme NFRs |
| SRE | SLOs definidos, error budgets, circuit breakers |
| Chaos Engineering | Quando aplicável |
| Post-mortem | Formal (≤ 48h Sev1, ≤ 72h Sev2) |
| Security Engineer | Obrigatório para features críticas |

**Regra:** O Architect pode elevar requisitos de cobertura via NFR no PRD — nunca abaixo do mínimo do modo.

---

## Regras de Qualidade

- TDD obrigatório
- contratos obrigatórios
- segurança obrigatória
- cobertura mínima de testes: conforme modo (ver seção "MVP vs Production Mode")

---

## Governança

- Nenhum agente decide fora do seu escopo
- Conflitos são resolvidos pelo Tech Lead
- O usuário pode vetar qualquer decisão

---

## Memória do Sistema

Arquivos obrigatórios:
- .claude/squad/project/ARCHITECTURE.md
- .claude/squad/project/ADR/
- .claude/squad/project/TASK_BOARD.md
- .claude/squad/project/contracts/

Regra:
Se não está documentado, não existe.

---

## Definition of Done Global

> **Engineer Done** vs **Squad Done** (esta lista):
> - **Engineer Done** = código pronto para revisão (definido em cada `.claude/squad/template/agents/{engineer}.md`). Inclui: implementação, testes verdes localmente e no CI, contratos respeitados, README, metadata de feature flag.
> - **Squad Done** (esta lista) = entregue em produção. Inclui Engineer Done + revisões + deploy + observabilidade + memória atualizada.
>
> Engineers entregam **Engineer Done**; pipeline + DevOps + TL fecham para **Squad Done**.

Uma entrega só está em **Squad Done** quando TODOS os itens abaixo estão atendidos:

- [ ] Código implementado e revisado
- [ ] Testes passando (cobertura conforme modo)
- [ ] Contratos respeitados e atualizados em `/contracts`
- [ ] QA aprovou comportamento
- [ ] Code Reviewer aprovou qualidade do código
- [ ] Security Engineer aprovou (features críticas)
- [ ] Pipeline CI/CD verde
- [ ] Deploy realizado com sucesso
- [ ] Sistema monitorado (logs disponíveis; alertas ativos em Production)
- [ ] Rollback testado (Production Mode)
- [ ] README do módulo atualizado
- [ ] `.claude/squad/project/ARCHITECTURE.md` atualizado (quando há mudança estrutural)
- [ ] `.claude/squad/project/DECISIONS_LOG.md` atualizado (quando há decisão relevante)
- [ ] `.claude/squad/project/TASK_BOARD.md` atualizado (tarefa movida para Done)
- [ ] Feature flag definida e testada em ambos os paths (features críticas) — ver `.claude/squad/template/memory/ADR/ADR-003-feature-flags.md`
- [ ] Product Designer aprovou (apenas em features visuais críticas) — ver `.claude/squad/template/memory/ADR/ADR-005-design-system.md`
- [ ] Aderência ao Design System em `.claude/squad/project/design-system/` (sem hardcoded tokens; patterns respeitados)

---

## Guardrails

- Subagentes não interagem com o usuário (exceto PO e TL)
- Nenhuma implementação começa sem contratos
- Nenhuma entrega passa sem QA + Code Review
- Nenhuma feature crítica vai para produção sem Security Engineer

---

## Regra de Bloqueio Global

Se qualquer agente identificar:

- ambiguidade
- falta de contrato
- inconsistência

A execução deve parar imediatamente.

Nenhum agente pode “seguir mesmo assim”.

---

## Proibição de Pular Etapas

É proibido:

- iniciar implementação sem TDD
- iniciar TDD sem arquitetura
- iniciar arquitetura sem PRD

Se isso ocorrer → bloquear

---

## Consistência de Artefatos

Todos os agentes devem garantir alinhamento entre:

- PRD
- arquitetura
- contratos
- testes

Se houver divergência → escalar

---

## Fronteiras de Segurança

Segurança é responsabilidade de TODOS, mas cada agente tem fronteira clara:

| Agente | Fronteira |
|--------|----------|
| **Architect** | Segurança por DESIGN (classificação de dados, threat model alto nível, modelo de acesso, criptografia) |
| **Code Reviewer** | Segurança DO CÓDIGO (OWASP no código, validação, sanitização, vulnerabilidades) |
| **Security Engineer** | Segurança como ESPECIALIDADE (threat modeling profundo, compliance, pentest review, auth/authz flows) |
| **QA Engineer** | Segurança DO COMPORTAMENTO (auth/authz funciona, inputs maliciosos, testes de segurança) |
| **DevOps Engineer** | Segurança DA INFRAESTRUTURA (secrets, IAM, rede, SAST na pipeline) |
| **AI Engineer** | Segurança DA CAMADA IA (prompt injection, vazamento via output, tools/MCP, isolamento de contexto) |
| **Tech Lead** | Coordenação e veto final em conflitos de segurança |

---

## Fluxos de Projeto

### Fluxo 1 — Projeto Novo (sem artefatos)
```
1. Usuário aciona PO com briefing
2. PO cria: PRD + Spec Funcional + Histórias com critérios de aceite (incluindo RNFs)
3. PO apresenta ao usuário
4. Usuário aprova, ajusta ou rejeita
5. PO registra mudanças em `.claude/squad/project/DECISIONS_LOG.md`
6. TL recebe PRD aprovado → cria plano de execução
7. TL aciona Architect → define arquitetura + stack
7a. TL aciona Product Designer (paralelo a Architect) — quando projeto tem UI: propõe DS (Material 3 default ou alternativa justificada), define tokens iniciais e componentes-chave
8. TL aciona Security Engineer (Fase 1) para threat model sobre arquitetura — em features críticas
9. TL aciona Data Engineer como consultor — quando arquitetura envolver pipelines, DW, ML data prep
10. Architect ajusta arquitetura + Product Designer ajusta DS conforme threats e contexto
11. TL apresenta arquitetura + DS proposto ao usuário (incluindo decisões de stack e mitigações de segurança)
12. Usuário aprova, ajusta ou rejeita
13. Architect define contratos em `.claude/squad/project/contracts/`
13a. Product Designer documenta DS em .claude/squad/project/design-system/ (tokens + componentes + patterns)
14. QA define testes → Engineers implementam → CI (testes/lint/build/SAST) → em paralelo: QA exploratório + Code Review + Security Engineer (Fase 2 em features críticas) + Product Designer review (em features visuais críticas) → Quality Gates (TL integra) → DevOps deploy (canary/blue-green em Production)
15. TL valida entrega final e atualiza memória do sistema
```

### Fluxo 2 — Projeto Novo com Artefatos Existentes
```
1. Usuário entrega artefatos (PRD, specs, contratos, etc.)
2. PO lê artefatos e organiza nas pastas corretas (/docs, /contracts, /memory)
3. PO pode oferecer sugestões e críticas ao usuário
4. Usuário aprova (pode ignorar sugestões do PO — tem autoridade total)
5. TL recebe PRD aprovado → segue Fluxo 1 a partir do passo 6
Nota: usuário tem autoridade total para ignorar sugestões do PO
```

### Fluxo 3 — Projeto Existente para Continuidade
```
1. Usuário aciona TL com pedido de continuidade
2. TL lê codebase + `.claude/squad/project/` (`ARCHITECTURE.md`, `TASK_BOARD.md`, `ADR/`)
3. TL aciona PO para: atualizar docs se necessário, confirmar prioridades
4. PO alinha com usuário
5. TL cria plano de continuidade baseado no estado atual
6. Quando primeira feature VISUAL chega: TL verifica .claude/squad/project/design-system/. Se não existe → TL aciona Product Designer (/squad-design-extract) para extrair DS da UI atual antes de Frontend/Mobile prosseguirem
7. Fluxo padrão para as tarefas definidas
```

### Fluxo 4 — Projeto Existente para Refatoração
```
1. Usuário aciona PO com objetivo da refatoração (o QUÊ e POR QUÊ)
2. PO documenta: estado atual vs estado desejado, critérios de aceite
3. Usuário aprova escopo
4. TL avalia impacto técnico → cria plano com análise de risco
5. TL apresenta plano + riscos ao usuário
6. Usuário aprova
7. Fluxo padrão com atenção extra a: testes de regressão, compatibilidade de contratos
```

### Fluxo 5 — Projeto Sob Domínio da Squad (Manutenção/Evolução)
```
Para melhorias:
  - Usuário aciona PO → PO documenta → usuário aprova → TL orquestra

Para bugs (via usuário):
  - Usuário aciona TL diretamente
  - TL avalia: se for bug → cria plano de correção; se for melhoria → encaminha para PO

Para bugs (via Support Engineer):
  - Support Engineer monitora issue tracker (Linear/GitHub)
  - Triage: bug real → TL | melhoria → PO | dúvida → TL
  - TL pode reclassificar: bug identificado como melhoria → encaminha ao PO
  - PO documenta melhoria → usuário aprova → PO atualiza docs → TL orquestra
```

---

## Fluxo de Bug em Produção

### Sev1 — Sistema fora ou dados comprometidos
```
1. Support Engineer ou usuário identifica e reporta ao TL
2. TL confirma severidade e aciona hotfix imediatamente
3. Gates obrigatórios: QA + DevOps + Security Engineer (fast review)
4. Code Reviewer detalhado pode ser pulado em Sev1 (responsabilidade do TL)
5. Deploy do hotfix com aprovação mínima
6. Post-mortem formal obrigatório em ≤ 48h
```

### Sev2 — Degradação significativa
```
1. Fluxo normal acelerado (sem pular gates)
2. TL coordena resolução urgente
3. Post-mortem formal obrigatório em ≤ 72h
```

### Sev3+ — Bug não crítico
```
1. Issue vai para `.claude/squad/project/TASK_BOARD.md` como backlog normal
2. Segue fluxo padrão de desenvolvimento
```

---

## Política de Indisponibilidade do Usuário

Múltiplos gates dependem da aprovação do usuário. Quando o usuário está indisponível:

| Gate | Comportamento |
|------|---------------|
| PRD inicial | Bloqueia execução; pausar até resposta |
| Aprovação de arquitetura | Bloqueia execução; pausar até resposta |
| Decisão de stack | Bloqueia execução; pausar até resposta |
| Scope change | Bloqueia execução; trabalho continua no escopo aprovado |
| Sev1 (sistema fora) | TL assume autoridade temporária; usuário ratifica posteriormente |
| Sev2 | Aguardar 1h; depois TL pode proceder e ratificar depois |
| Sev3+ | Sem urgência; aguardar |

### Regra

- Decisões tomadas sem aprovação explícita → registrar em `.claude/squad/project/DECISIONS_LOG.md` com tag `tl-autonomous`
- TL é responsável por ratificar com usuário em até 24h após retorno
- Squad não pode permanecer travada indefinidamente em projetos não-críticos — aplicar judgment

---

## Multi-user Continuity (Handoff/Resume)

Squad é projetada para **handoff entre usuários**: User A inicia projeto, User B retoma sem perder contexto.

### Pilares de continuidade

| Pilar | Onde |
|-------|------|
| **Pointer "onde paramos"** | `.claude/squad/project/TASK_BOARD.md` → seção "Current Focus" |
| **Granularidade temporal** | `.claude/squad/project/DECISIONS_LOG.md` → seção "Session Log" |
| **Estado das tarefas** | `.claude/squad/project/TASK_BOARD.md` → colunas Todo/Doing/Review/Blocked/Done |
| **Decisões estruturais** | `.claude/squad/project/ADR/` |
| **Decisões rápidas** | `.claude/squad/project/DECISIONS_LOG.md` |
| **Learnings por agente** | `.claude/squad/project/agent-memory/` |
| **Arquitetura atual** | `.claude/squad/project/ARCHITECTURE.md` |
| **Carregamento automático** | Hook `SessionStart` (`load-memory.sh`) |

### Workflow padrão de handoff/resume

#### Encerrando sessão (User A)

1. **Acionar `/squad-handoff`** — TL conduz checklist:
   - Mover cards no TASK_BOARD conforme estado real
   - Atualizar "Current Focus" com próximo passo acionável
   - Atualizar agent-memory dos agentes envolvidos
   - Registrar entrada em Session Log
   - Verificar PRs abertos linkados a cards
   - Commit de organização de memory se necessário
2. **Resumo gerado** apresentado como handoff message

#### Retomando sessão (User B ou User A após pausa)

1. `git pull` para sincronizar
2. Iniciar sessão Claude Code no diretório (hook `SessionStart` carrega memory automaticamente)
3. **Acionar `/squad-resume`** — TL conduz:
   - Ler Current Focus + últimas 3 entradas de Session Log
   - Listar PRs abertos + commits recentes + tarefas ativas
   - Apresentar resumo + próximo passo
4. User confirma direção ou redireciona

#### Snapshot rápido durante sessão

- **`/squad-status`** — TL apresenta snapshot leve sem mudar direção (≤2 min)

### Disciplina mínima exigida

Para continuidade funcionar:

- **Commits frequentes** — trabalho não-committed = invisível para próximo usuário
- **Memory atualizada antes de encerrar** — Current Focus + Session Log + agent-memory relevantes
- **Decisões registradas** — DECISIONS_LOG (rápidas) ou ADR (estruturais), não só em chat
- **PRs linkados** — cards em "Review" referenciam PR explicitamente
- **Acionamento de `/squad-handoff`** ao encerrar sessão significativa (≥1 commit relevante)

### Enforcement (camadas)

| Camada | Tipo |
|--------|------|
| Manual via skills (`/squad-handoff`, `/squad-resume`) | Comportamento orientado |
| Hook `architecture-reminder.sh` (PostToolUse) | Lembrete ao editar ARCHITECTURE.md |
| Hook `memory-update-reminder.sh` (PreToolUse, opt-in) | Lembrete ao fazer `git commit` com mudança em código sem memory |
| CI workflow `memory-check.yml` (opt-in) | Comentário em PR sugerindo atualização |
| Pre-commit hook local (opt-in) | Aviso antes de commit |

Hooks e CI são **não-bloqueantes por default** (apenas warning). Projeto pode endurecer em Production Mode.

### Limitação conhecida

Conversation history com Claude Code (`~/.claude/projects/...`) **não migra entre usuários** — é local. Decisões "soft" tomadas em chat se perdem se não viram entrada em DECISIONS_LOG ou ADR.

**Mitigação:** disciplina de registrar decisões relevantes em memory durante (ou ao final) da sessão.

---

## Regra Final

O objetivo não é gerar código.

O objetivo é construir sistemas:
- corretos
- sustentáveis
- escaláveis
- seguros
- resilientes
- observáveis