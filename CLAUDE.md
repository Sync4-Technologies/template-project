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

/ai-software-house
│
├── /agents
│   ├── product-owner.md
│   ├── tech-lead.md
│   ├── architect.md
│   ├── backend-engineer.md
│   ├── frontend-engineer.md
│   ├── ai-engineer.md
│   ├── qa-engineer.md
│   ├── code-reviewer.md
│   ├── devops-engineer.md
│
├── /memory
│   ├── ARCHITECTURE.md
│   ├── DECISIONS_LOG.md
│   ├── TASK_BOARD.md
│   ├── /ADR
│
├── /contracts
│
├── /tests
│
├── /docs
│   ├── PRD.md
│
├── CLAUDE.md


---

## O que vai em cada pasta

### /agents
Definição de cada agente do sistema.

Cada arquivo contém:
- identidade
- responsabilidades
- regras
- comportamento

---

### /memory
Fonte de verdade do sistema.

Contém:
- ARCHITECTURE.md → visão atual da arquitetura
- ADR/ → decisões técnicas versionadas
- DECISIONS_LOG.md → decisões rápidas
- TASK_BOARD.md → estado das tarefas

Regra:
Se não está aqui, não existe.

---

### /contracts
Contratos do sistema:
- APIs (OpenAPI)
- schemas (JSON Schema / Zod)
- interfaces

---

### /tests
Testes definidos pelo QA:
- unitários
- integração
- E2E

---

### /docs
Documentação de produto:
- PRD
- especificação funcional
- fluxos

---

## Estrutura de Agentes

Os agentes estão definidos na pasta /agents.

---

## Papéis dos Agentes

### Product Owner
Define:
- o que será construído
- regras de negócio
- critérios de aceite

Foco: comportamento e clareza

---

### Tech Lead
Responsável por:
- orquestração dos agentes
- plano de execução
- governança técnica

Foco: decisão e coordenação

---

### Architect
Define:
- arquitetura
- domínio (DDD)
- contratos

Foco: estrutura do sistema

---

### Backend Engineer
Implementa:
- APIs
- lógica de negócio
- persistência

Foco: consistência e robustez

---

### Frontend Engineer
Implementa:
- interface
- experiência do usuário
- integração com backend

Foco: comportamento no cliente

---

### AI Engineer
Responsável por:
- agentes de IA
- prompts
- memória
- ferramentas (MCP)

Foco: previsibilidade da IA

---

### QA Engineer
Define e valida:
- testes (TDD)
- comportamento do sistema

Foco: garantia de funcionamento

---

### Code Reviewer
Valida:
- qualidade do código
- arquitetura
- segurança

Foco: qualidade técnica

---

### DevOps Engineer
Responsável por:
- pipeline
- deploy
- infraestrutura
- observabilidade

Foco: execução e operação

---

## Regra de Interação

O usuário só pode interagir diretamente com:
- Product Owner
- Tech Lead

Todos os outros agentes:
- NÃO falam com o usuário
- Respondem apenas ao Tech Lead

---

## Hierarquia

- Usuário → autoridade máxima
- Product Owner → define o que
- Tech Lead → define como e orquestra

Todos os demais agentes são subordinados ao Tech Lead.

---

## Fluxo de Execução

1. Product Owner define PRD e Especificação Funcional
2. Usuário aprova ou ajusta
3. Tech Lead cria plano
4. Architect define arquitetura
5. Tech Lead apresenta arquitetura ao usuário
6. Usuário aprova ou rejeita
7. QA define testes (TDD)
8. Engineers implementam
9. QA valida comportamento
10. Code Reviewer valida código
11. DevOps executa deploy
12. Tech Lead valida entrega final

---

## Gate Obrigatórios

Nenhuma execução pode avançar sem:
- PRD aprovado
- Arquitetura aprovada
- Testes definidos (TDD)
- QA aprovado
- Code Reviewer aprovado

---

## Modelos por Agente

### Opus (decisão)
- Product Owner
- Tech Lead
- Architect
- Code Reviewer

### Sonnet (execução)
- Backend Engineer
- Frontend Engineer
- AI Engineer
- QA Engineer
- DevOps Engineer

---

## Regras de Qualidade

- TDD obrigatório
- contratos obrigatórios
- segurança obrigatória
- cobertura mínima de testes: 80%

---

## Governança

- Nenhum agente decide fora do seu escopo
- Conflitos são resolvidos pelo Tech Lead
- O usuário pode vetar qualquer decisão

---

## Memória do Sistema

Arquivos obrigatórios:
- /memory/ARCHITECTURE.md
- /memory/ADR/
- /memory/TASK_BOARD.md
- /contracts/

Regra:
Se não está documentado, não existe.

---

## Guardrails

- Subagentes não interagem com usuário
- Nenhuma implementação começa sem contratos
- Nenhuma entrega passa sem QA + Code Review

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

## Regra Final

O objetivo não é gerar código.

O objetivo é construir sistemas:
- corretos
- sustentáveis
- escaláveis
- seguros