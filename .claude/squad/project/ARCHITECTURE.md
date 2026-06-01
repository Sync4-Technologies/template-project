# ARCHITECTURE.md — AgentesIA

> Fonte de verdade da arquitetura atual. Atualizar sempre que houver mudança estrutural.
> Última atualização: kickoff da squad

---

## Visão geral

Plataforma multi-tenant SaaS para criação e operação de agentes de IA conectados ao WhatsApp. O fluxo central é:

```
Webhook (WhatsApp) → Fila Redis/arq → AgentRuntime (LLM + tool-calling) → Resposta no WhatsApp → Débito de créditos
```

---

## Stack tecnológica

### Backend
| Camada | Tecnologia | Observações |
|--------|-----------|-------------|
| Linguagem | Python 3.11 / 3.12 | Dois venvs no repo — padronizar |
| Web framework | FastAPI + Uvicorn (ASGI) | |
| ORM | SQLAlchemy 2.0 async | `Mapped`, `mapped_column` |
| Driver async | asyncpg | Driver sync psycopg2 para Alembic |
| Migrações | Alembic | 7 revisões lineares |
| Fila | arq + Redis 7 | Redis Streams |
| LLM | AsyncOpenAI | Único provider implementado; anthropic/groq declarados mas não implementados |
| Auth | python-jose (JWT HS256) + bcrypt | Cookie httpOnly; fallback Bearer para API/testes |
| Cripto | Fernet (cryptography) | Tokens WhatsApp criptografados antes de persistir |
| Billing | Stripe | Checkout + webhooks com idempotência |
| Email | Resend | `from:` ainda placeholder |
| HTTP client | httpx | Canais WhatsApp + tools |
| Rate limit | slowapi | **Storage em memória — não compartilhado entre workers** |
| Logs | structlog | Sem métricas/tracing (Prometheus/OTel ausente) |
| Testes | pytest + pytest-asyncio + aiosqlite | SQLite in-memory |

### Frontend
| Camada | Tecnologia | Observações |
|--------|-----------|-------------|
| Framework | React 18.3 + TypeScript 5.8 | SPA, sem SSR |
| Build | Vite 5.4 + swc | Porta dev 8080, alias `@→src` |
| Roteamento | React Router DOM 6.30 | |
| Estado servidor | TanStack Query 5.83 | `staleTime: 30s`; polling configurado por recurso |
| Estado cliente | React Context (AuthContext) + useState | Sem Redux/Zustand |
| HTTP | Axios 1.14 | Cookie httpOnly; interceptor de refresh com fila |
| UI | shadcn/ui + Radix + Tailwind 3.4 | ~45 primitivos; tokens HSL em `index.css` |
| Forms | React Hook Form 7.61 + Zod 3.25 | |
| Gráficos | Recharts 2.15 | |
| Testes | Vitest 3.2 + Playwright | Infra configurada, cobertura quase zero |

### Infra (docker-compose local)
- PostgreSQL 16-alpine
- Redis 7-alpine
- Adminer
- Serviços: `api` (uvicorn) + `worker` (arq)

---

## Estrutura de pastas

### Backend
```
app/            → Bootstrap FastAPI: main.py, config.py (Settings), database.py
api/            → Camada HTTP por domínio (router.py + schemas.py)
  ├── deps.py             → Dependências de auth
  ├── auth/ agents/ connections/ conversations/
  ├── metrics/ tenants/ tools/ billing/ webhooks/
core/           → Lógica de negócio e integrações
  ├── security.py         → Hash, JWT, Fernet, SSRF guard
  ├── services/           → agent_service, auth_service, billing_service (EM TRANSIÇÃO — incompleto)
  ├── runtime/            → agent_runtime.py — loop LLM
  ├── llm/                → gateway.py (router de provider) + openai_provider.py
  ├── channel/            → base.py (ABC ChannelAdapter) + zapi.py + evolution.py
  ├── queue/              → worker.py (arq jobs)
  ├── tools/              → registry.py (auto-discovery) + handlers por tool
  └── email/              → service.py (Resend)
db/             → models.py + migrations/ (Alembic)
tests/          → unit/ + integration/
scripts/        → check_env.py, setup.py, test_flow.py
```

### Frontend
```
src/
├── components/
│   ├── ui/               → ~45 primitivos shadcn/ui
│   ├── landing/          → 11 seções da landing page
│   ├── app/              → AppLayout, OnboardingWizard, TipBanner, EmptyState
│   └── ProtectedRoute / GuestRoute / ErrorBoundary
├── contexts/AuthContext.tsx
├── hooks/
│   ├── useData.ts        → GOD FILE: connections, conversations, metrics, tools, tenant
│   ├── useAgents.ts      → CRUD de agentes + versões + simulate
│   ├── useBilling.ts     → planos, pacotes, usage, invoices, checkout
│   └── useConnections/Conversations/Metrics/Tools.ts → SHIMS de re-export de useData
├── lib/
│   ├── api.ts            → Axios singleton + interceptor refresh
│   ├── auth.ts           → login/register/logout/forgot/changePassword
│   ├── errorHandler.ts / monitoring.ts / metricsByAgent.ts / invoices.ts / utils.ts
├── pages/
│   ├── Index / Login / Cadastro / Precos / NotFound
│   └── app/ → AgentesPage, AgentEditorPage, ConexoesPage,
│              ConversasPage, MetricasPage, BillingPage, ConfiguracoesPage
└── types/index.ts        → Todas as interfaces de domínio
```

---

## Modelo de domínio

```
Tenant (raiz)
 ├─1:N─ Agent
 │        └─1:N─ AgentVersion   [draft|published|deprecated]
 │                  └─1:N (SET NULL)─ ChannelConnection.agent_version_id
 ├─1:N─ ChannelConnection       [provider: zapi|evolution; tokens Fernet]
 │        └─1:N─ Conversation   [UNIQUE connection_id+contact_phone]
 │                  └─1:N─ Message [role: user|assistant|tool]
 ├─1:N─ UsageEvent              [event_type: message_sent|tool_called|credit_purchased]
 ├─1:N─ RefreshToken            [token_hash sha256, rotação a cada refresh]
 ├─1:N─ EmailConfirmationToken
 └─1:N─ PasswordResetToken

StripeEvent                     [idempotência de webhooks]
```

PKs são UUID. Multi-tenant por `tenant_id` em todas as tabelas (shared-schema, sem RLS).

---

## Arquitetura e padrões

### Padrão geral: Layered com Ports & Adapters parcial

```
HTTP (api/*/router.py)
  → Service (core/services/*)         [parcialmente adotado — EM TRANSIÇÃO]
  → Runtime / Gateway / Adapters (core/*)
  → Models (db/models.py) via AsyncSession
```

### Adapters implementados
- `ChannelAdapter` (ABC) → `ZAPIAdapter` + `EvolutionAdapter`
- Normalizam payloads heterogêneos para `CanonicalMessage`

### LLM Gateway
- `LLMGateway` roteia por `request.provider`
- Apenas `openai` implementado; `anthropic` e `groq` declarados mas causarão `ValueError`

### Plugin registry de tools (auto-discovery)
- `core/tools/registry.py` varre subpastas e registra `handler.py` que exportem `TOOL_NAME / TOOL_DESCRIPTION / TOOL_SCHEMA / execute`
- Tools ativas: `get_current_datetime`, `save_contact_info`, `schedule_followup`, `send_to_webhook`, `search_on_web`
- `search_on_catalog` **removida** sem migração — agentes que a referenciem ficam com tool ignorada em runtime

### Fluxo de mensagem recebida
```
1. POST /webhooks/{provider}/{secret}    → valida webhook_secret, dedup Redis (SETNX TTL 5min)
2. Enfileira job arq                     → retorna 200 imediatamente
3. worker.py processa job                → instancia AgentRuntime
4. AgentRuntime                          → reconstrói histórico (últimas 20 msgs)
                                         → chama LLMGateway (OpenAI Chat Completions)
                                         → executa tool_calls via registry
                                         → adapter.send_text() → WhatsApp
                                         → commit: Message + UsageEvent + créditos
```

---

## Autenticação e segurança

- **Senhas**: bcrypt direto (truncamento silencioso a 72 bytes)
- **JWT**: HS256, access token 15min (`type=access`, `sub=tenant_id`)
- **Refresh tokens**: opacos (`secrets.token_urlsafe(64)`), guardados como hash sha256, com rotação
- **Transporte**: cookies httpOnly (`samesite=strict`, `secure` em produção); fallback `Authorization: Bearer`
- **Gates**: `get_current_tenant` → `require_active_tenant` → `require_verified_tenant`
- **Criptografia de credenciais**: tokens WhatsApp cifrados com Fernet
- **SSRF guard**: `validate_external_url` em `core/security.py` — aplicado à Evolution, **NÃO aplicado à tool `send_to_webhook`** (gap de segurança crítico)
- **Dedup webhooks**: Redis `SETNX` TTL 5 min por `message_id`
- **Stripe**: validação de assinatura HMAC + idempotência via tabela `stripe_events`

---

## Rotas da API

| Prefixo | Endpoints principais | Auth |
|---------|---------------------|------|
| `/auth` | login, register, refresh, logout, forgot-password, confirm-email, reset-password, change-password | Rate limit por IP |
| `/agents` | CRUD + versions + publish + duplicate + simulate | require_verified_tenant |
| `/connections` | CRUD + qrcode | require_verified_tenant |
| `/conversations` | list + messages | require_verified_tenant |
| `/metrics` | overview + by-agent | require_verified_tenant |
| `/tenants` | me (GET/PATCH) | require_verified_tenant |
| `/tools` | catálogo | require_verified_tenant |
| `/billing` | plans, packages, usage, invoices, subscribe, credits, webhook | webhook: sem JWT |
| `/webhooks` | zapi/{secret}, evolution/{secret} | webhook_secret na URL |
| `/health` | liveness | público |

---

## Gaps e estado incompleto

### Funcionalidades declaradas mas não implementadas
- Providers LLM: anthropic, groq (schema declara, gateway causa ValueError)
- Multimídia: `AgentVersion.multimedia` e `CanonicalMessage` suportam áudio/imagem, runtime processa só texto
- Storage S3/R2: boto3 configurado, sem código de upload
- `context_id` (thread OpenAI): campo existe, não usado — histórico reconstruído a cada chamada
- Reenvio de email de confirmação: endpoint inexistente
- Reset de senha: backend implementado, **frontend não tem a rota `/reset-password`**
- Verificação de e-mail: badge no frontend, sem fluxo de reenvio

### UI placeholders (frontend)
- Abas do editor: Multimodal, Áudio, Follow-up → só `toast.info("em breve")`
- Configurar tools por agente: `tool_configs` preservado, UI nunca edita
- Histórico/gestão de versões: botão existe, só toast
- Notificações, troca de workspace, upload de foto/logo, webhooks, sessões, 2FA, exportar dados → todos placeholders
- **Sessões ativas e Webhooks em Configurações mostram dados HARDCODED** (enganoso)
- Tema escuro: `next-themes` instalado, sem toggle nem ThemeProvider

### Débito técnico crítico
- **SSRF em `send_to_webhook`**: webhook_url do cliente não passa por SSRF guard — vetor real
- **Débito de créditos não atômico**: sem `SELECT FOR UPDATE`, corrida possível em msgs concorrentes
- **Envio antes do commit**: `adapter.send_text()` antes do `commit()` — reenvio possível em retry
- **Rate limit em memória**: não compartilhado entre workers/réplicas
- **Refatoração de services pela metade**: connections/conversations/metrics/tenants ainda inline no router
- **Dois sistemas de toast**: Sonner (usado) + Toaster shadcn (morto)
- **`useData.ts` god file** com shims de re-export espalhados

---

## Decisões de arquitetura em vigor

Ver `ADR/` para decisões formais. Decisões rápidas em `DECISIONS_LOG.md`.

- Auth por cookie httpOnly (não Bearer no cliente) — deliberado para segurança
- Multi-tenant shared-schema com `tenant_id` manual — sem RLS
- Fila arq/Redis para desacoplar webhook do runtime
- Plugin registry auto-discovery para tools
- TanStack Query como estado de servidor no frontend
- shadcn/ui + Tailwind como design system base
