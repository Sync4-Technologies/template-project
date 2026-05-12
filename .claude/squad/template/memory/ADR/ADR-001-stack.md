# ADR-001 — Stack Tecnológica Padrão do Template

**Status:** Aceita (padrão do template — substituível por projeto)  
**Data:** 2026-05-08  
**Autor:** Architect

---

## Contexto

O template de squad de agentes precisa de uma stack de referência que:
- Seja conhecida e madura
- Cubra os casos de uso mais comuns (web, mobile, AI, infra)
- Seja flexível o suficiente para ser substituída por projeto

A decisão de stack final é sempre do **Architect**, por projeto, com aprovação do usuário.
Esta ADR registra as **opções padrão** — não é prescritiva.

---

## Decisão

Adotar as seguintes opções como stack padrão do template, cabendo ao Architect escolher entre as alternativas listadas conforme os requisitos de cada projeto:

### Backend
- **Python / FastAPI** — para projetos AI-heavy, data pipelines, APIs simples
- **Node.js / NestJS** — para projetos com grande quantidade de I/O, real-time, ecosistema JS
- **Node.js / Express** — para APIs simples sem necessidade de opinionated framework

**Critério de escolha:** natureza do domínio, expertise do time, NFRs de performance

### Frontend
- **React / Next.js** — SSR quando SEO é requisito; SPA quando não é
- **React puro (Vite)** — para dashboards internos e admin panels

### Mobile
- **Flutter (Dart)** — quando há necessidade de alta performance nativa e código único
- **React Native (TypeScript)** — quando o time já domina React e precisa de flexibilidade

**Critério de escolha:** expertise do time, performance necessária, acesso a APIs nativas

### Banco de Dados
- **PostgreSQL** — banco principal para dados relacionais (padrão)
- **Redis / Valkey** — cache, sessões, filas simples, rate limiting

### AI / Agentes
- **LangChain** — para pipelines RAG e agentes simples
- **LangGraph** — para agentes com estado e fluxos complexos
- **API direta (Anthropic / OpenAI)** — quando overhead de framework não se justifica

### Infraestrutura
- **Docker** — containerização de todos os serviços
- **Docker Compose** — desenvolvimento local
- **Terraform** — infraestrutura como código para cloud

### CI/CD
- **GitHub Actions** — pipeline CI/CD principal

### Cloud
- **AWS** — provedor padrão
  - ECS (containers)
  - S3 (storage)
  - EC2 (quando necessário)
  - RDS (PostgreSQL gerenciado)
  - ElastiCache (Redis gerenciado)

### Testes
- **Jest / Vitest** — testes unitários e de integração (Node.js / React)
- **Pytest** — testes unitários e de integração (Python)
- **Playwright** — testes E2E web
- **Detox** — testes E2E mobile React Native
- **Flutter Test** — testes E2E mobile Flutter

---

## Alternativas Consideradas

### Go (backend)
- **Prós:** performance excelente, compilado, tipagem forte
- **Contras:** curva de aprendizado, menos libs para AI/ML
- **Status:** válido para projetos de alta performance sem AI

### Vue.js / Nuxt (frontend)
- **Prós:** mais simples, menos boilerplate
- **Contras:** ecosistema menor, menos libs enterprise
- **Status:** válido para projetos menores

### GCP / Azure (cloud)
- **Prós:** recursos específicos (BigQuery, Azure OpenAI)
- **Contras:** menos padronizado no template
- **Status:** válido quando há requisito específico

---

## Trade-offs Assumidos

- Priorizamos maturidade e ecosistema sobre performance máxima
- JavaScript/TypeScript como linguagem dominante facilita compartilhamento de tipos entre frontend e backend (quando Node.js)
- AWS como padrão simplifica o template mas cria dependência de provedor

---

## Consequências

### Positivas
- Stack bem documentada com vasta comunidade
- Facilidade de onboarding de novos desenvolvedores
- Ferramentas de teste maduras

### Negativas / Riscos
- Lock-in relativo em AWS (mitigado por IaC com Terraform)
- Python e Node.js na mesma squad exige conhecimento em duas linguagens

---

## Critérios de Revisão

Esta decisão deve ser revisada se:
- Um projeto exigir performance além da capacidade do Node.js
- O ecosistema AI evoluir significativamente para outra linguagem
- O custo de AWS tornar-se proibitivo
