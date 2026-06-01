# CLAUDE.md — AgentesIA Squad

> Este arquivo prevalece sobre ~/.claude/CLAUDE.md global.
> Governança, fluxos e gates para o projeto AgentesIA.

---

## Contexto do projeto

Plataforma multi-tenant SaaS para criação e operação de agentes de IA conectados ao WhatsApp.
Stack: FastAPI (backend) + React/TypeScript (frontend) + PostgreSQL + Redis/arq.

**Modo de operação atual: Production Mode** (confirmado pelo usuário no kickoff)

---

## Modo de operação

### Production Mode (atual)
- Cobertura de testes: ≥ 80% geral / ≥ 95% em regras críticas (auth, billing, runtime)
- Observabilidade: completa (logs + métricas + tracing + alertas) — FEAT-019 vira pré-requisito de Squad Done
- SRE: SLOs definidos, error budgets, rollback testado
- Post-mortem: formal (Sev1 ≤ 48h / Sev2 ≤ 72h)
- Security Engineer: **obrigatório** em toda feature crítica (auth, billing, dados pessoais, tools, integrações)
- CI/CD: pipeline obrigatório (FEAT-020) antes de deploy

---

## Agentes ativos neste projeto

| Agente | Foco imediato |
|--------|--------------|
| Tech Lead | Orquestração, priorização, quality gates |
| Backend Engineer | FastAPI, SQLAlchemy, runtime, services |
| Frontend Engineer | React, TanStack Query, hooks, páginas |
| Security Engineer | SSRF, rate limit, auth |
| QA Engineer | Testes unitários e de integração |
| Code Reviewer | OWASP no código, qualidade |

---

## Fontes de verdade

| Tópico | Arquivo |
|--------|---------|
| Arquitetura atual | `.claude/squad/project/ARCHITECTURE.md` |
| Backlog priorizado | `.claude/squad/project/TASK_BOARD.md` |
| Decisões rápidas | `.claude/squad/project/DECISIONS_LOG.md` |
| ADRs | `.claude/squad/project/ADR/` |
| PRD | `.claude/squad/project/PRD.md` (a criar) |

---

## Regras críticas do projeto

### Segurança
1. **Nunca** aceitar `webhook_url` sem passar por `validate_external_url` (SEC-001 aberto)
2. **Nunca** commitar `.env`, `.env.docker` ou `cookies.txt`
3. Credenciais de provedor **sempre** criptografadas com Fernet antes de persistir
4. SSRF guard obrigatório em qualquer URL fornecida por tenant

### Backend
5. Toda nova rota protegida usa `require_verified_tenant` (salvo webhooks e billing/webhook)
6. Novos services seguem padrão de `auth_service` / `billing_service` (não inline no router)
7. Pool arq: não criar/fechar pool por request — usar pool reutilizável
8. Débito de créditos: usar update atômico, não read-then-write

### Frontend
9. Novos hooks de dados usam TanStack Query — sem fetch manual
10. Estado de servidor: nunca duplicar em useState o que está no cache do RQ
11. Imports de hooks: sempre do arquivo dedicado, não de `useData.ts` diretamente
12. Cores: sempre usar tokens CSS (`var(--primary)`) — nunca HSL hardcoded

### Qualidade
13. TDD: QA define cenários antes de implementar
14. Nenhum dado fake apresentado como real ao usuário

---

## Gates obrigatórios

| Gate | Quem decide | Bloqueia |
|------|------------|---------|
| PRD aprovado | Usuário | Toda execução |
| Arquitetura aprovada | Usuário | Implementação |
| SEC-001 fechado | Security Engineer | Deploy de qualquer feature que use tools |
| Testes definidos | QA | Implementação (TDD) |
| CI verde | Pipeline | Revisões |
| QA aprovou | QA | Code Review |
| Code Reviewer aprovou | CR | Deploy |

---

## Fluxos ativos

### Fluxo de bug (padrão)
1. Identificar no TASK_BOARD.md (BUG-*)
2. QA define cenário de teste que reproduz
3. Backend/Frontend corrige
4. QA valida
5. Code Reviewer aprova
6. Mover para Done

### Fluxo de feature nova
1. PO valida contra PRD (ou cria entry no PRD)
2. Security Engineer consultado se a feature toca auth/billing/dados pessoais/tools
3. Architect define contrato (API ou tipo TypeScript)
4. QA define cenários
5. Engineer implementa
6. Code Review → Security Review (se aplicável)
7. Done

---

## Contexto para carregar no início de cada sessão

Sempre ler antes de começar:
1. `.claude/squad/project/ARCHITECTURE.md` — estado atual
2. `.claude/squad/project/TASK_BOARD.md` — o que está pendente
3. `.claude/squad/project/DECISIONS_LOG.md` — decisões tomadas

Se retomando sessão: rodar `/squad-resume` para o Tech Lead apresentar o estado.
