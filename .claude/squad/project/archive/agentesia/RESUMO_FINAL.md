# RESUMO_FINAL — AgentesIA

> Documento de entrega da squad de engenharia.  
> **Data:** 2026-06-01 · **Modo:** Production Mode · **Tech Lead:** squad AgentesIA  
> **Última revisão:** pós Sprint 3 (mídia inbound + multi-LLM)

---

## 1. Visão geral do projeto

### O que é o AgentesIA

**AgentesIA** é uma plataforma **multi-tenant SaaS** para criar, configurar e operar **agentes de IA conectados ao WhatsApp**. O tenant define prompts, tools, versões de agente e conexões (Z-API ou Evolution); mensagens recebidas no WhatsApp entram por webhook, são processadas em fila assíncrona pelo runtime (LLM + tool-calling) e a resposta volta ao canal, com débito de créditos e registro de uso.

**Proposta de valor:** permitir que empresas lancem assistentes de atendimento/vendas no WhatsApp sem montar infra de LLM, filas, billing e integrações do zero.

**Público-alvo:** PMEs e times de produto/ops que precisam de agentes conversacionais no WhatsApp com painel web, métricas e planos pagos.

### Stack tecnológica final

| Camada | Tecnologia | Notas pós-squad |
|--------|------------|-----------------|
| **Backend** | Python 3.12, FastAPI, SQLAlchemy 2 async, Alembic | 9 migrações; services extraídos nos domínios principais |
| **Fila** | arq + Redis 7 | Pool ARQ reutilizável; cron housekeeping |
| **LLM** | OpenAI, Anthropic, Groq | Gateway com allowlists por provider |
| **Auth** | JWT HS256 + cookies httpOnly + refresh opaco rotacionado | Rate limit via Redis em produção |
| **Billing** | Stripe (Checkout, webhooks, Customer Portal) | Idempotência `stripe_events` |
| **Storage** | Cloudflare R2 / S3 (boto3) | `core/storage/media.py` para inbound |
| **Observabilidade** | structlog, Prometheus `/metrics`, `/health/ready`, `X-Request-ID` | SLOs/alertas ainda não definidos |
| **Frontend** | React 18, TypeScript, Vite 5, TanStack Query 5 | Porta dev **8080** |
| **UI** | shadcn/ui + Radix + Tailwind | Tema escuro; tokens WCAG para badges |
| **Testes BE** | pytest + pytest-asyncio + aiosqlite | **184** testes coletados |
| **Testes FE** | Vitest + Playwright (infra) | Cobertura E2E ainda mínima |
| **CI** | GitHub Actions | ruff (app/api/core/db) + pytest unit + integration |
| **Infra local** | Docker Compose: Postgres 16, Redis 7, api, worker, Adminer | Dev alternativo: SQLite + `init_sqlite_dev.py` |

### Repositórios e branches principais

| Repositório | Path local | Remote | Branch principal | HEAD (2026-06-01) |
|-------------|------------|--------|------------------|-------------------|
| Backend | `/Users/vinii/Downloads/files/saas-agentes-backend` | `Sync4-Technologies/saas-agentes-backend` | `main` | `b643b05` |
| Frontend | `/Users/vinii/ia-reply` | `Sync4-Technologies/saas-agentes-frontend` | `main` | `ac16d68` |
| Governança | `/Users/vinii/template-project` | (squad / template) | — | TASK_BOARD, ADRs, docs |

Branches de feature da squad foram mergeadas em `main` (backend: 6 PRs formais #1–#6; demais commits diretos na `main`). Branches remotas legadas (`squad/*`, `feat/*`) podem ser arquivadas após validação.

---

## 2. Estado inicial (antes da squad)

### O que existia

- **Backend funcional** com FastAPI: auth cookie-first, CRUD de agentes/versões, conexões Z-API/Evolution, webhooks, runtime OpenAI, tools via registry, billing Stripe, fila arq.
- **Frontend SPA** com landing, login/cadastro, painel `/app` (agentes, conexões, conversas, métricas, billing, configurações), onboarding wizard, editor de agente (parcial).
- **Docker Compose** para Postgres + Redis + api + worker.
- **~90 testes** backend no commit inicial (`91eab80`).
- **7 revisões Alembic** lineares.

### Principais problemas na análise inicial

| Área | Problema |
|------|----------|
| Segurança | **SSRF** em `send_to_webhook` — URL do tenant sem validação |
| Segurança | **DNS rebinding** no egress HTTP (validação TOCTOU) |
| Segurança | Evolution adapter com `httpx` direto em URL de tenant |
| Integridade | Débito de créditos **não atômico** (corrida concorrente) |
| Integridade | `send_text()` **antes** do `commit()` — risco de reenvio |
| Infra | Rate limit slowapi em **memória** — não compartilhado entre workers |
| Arquitetura | Commits duplicados (router + `get_db`) |
| Arquitetura | Pool ARQ criado/fechado por request |
| Produto | Reset de senha no backend **sem rota no frontend** |
| Produto | UI com **dados hardcoded** (sessões, webhooks) — enganoso |
| Produto | Abas do editor (multimodal, áudio, follow-up) só toast "em breve" |
| LLM | anthropic/groq declarados no schema mas **não implementados** |
| Mídia | Parsers e runtime só texto |
| DX | Dois venvs Python; `useData.ts` god file; sem CI |

### Débitos e riscos no kickoff

- Vetor SSRF real em produção (SEC-001 bloqueante).
- Perda financeira por corrida de créditos (BUG-001).
- Modo **Production** exigido pelo usuário: ≥80% cobertura, observabilidade completa, SE em features críticas — gap grande em relação ao estado inicial.
- PRD formal **não existia** no kickoff (governança via ARCHITECTURE + TASK_BOARD).

---

## 3. O que foi entregue — por sprint

### Sprint 1 — Fundação e segurança

| ID | Problema | Solução | Commit / PR |
|----|----------|---------|-------------|
| **SEC-001** | SSRF em `send_to_webhook` | `core/safe_http.py` + `safe_post` com pin de IP e SNI; tool usa helper validado | `3ffe037` — PR #1 |
| **DEBT-011** | DNS rebinding no egress | `resolve_validated_url` + conexão no IP fixado (ADR-006) | `3ffe037` — PR #1 |
| **SEC-002** | Rate limit em memória | slowapi `RedisStorage` via `REDIS_URL` / `RATE_LIMIT_STORAGE_URI` | `dd5a7f2` — PR #2 |
| **BUG-001** | Débito de créditos com corrida | `debit_credits()` UPDATE atômico com `CASE` clamp | `909904b` — PR #3 |
| **BUG-002** | Envio WhatsApp antes do commit | Persistência + commit antes de `send_text`; retry sem novo LLM | `94bb43d` — PR #4 |
| **SEC-003** | Evolution sem egress seguro | `EvolutionAdapter` migra para `safe_post` / `safe_get` | `640aa0e` — PR #5 |
| **SEC-004** | Reset token reutilizável | Single-use atômico, TTL, revoga refresh no reset | `39798e1` — PR #6 |
| **BUG-003** | Commits duplicados HTTP | Fronteira única: só `get_db()` commita em HTTP (ADR-007) | `eb3b355` |
| **BUG-004** | Pool ARQ por request | Pool global no lifespan (`core/queue/arq_pool.py`) | `e9d8dd5` |
| **BUG-005** | Cadastro bloqueado sem Resend | Dev: auto `email_verified` + log com link de confirmação | `568729d` |
| **FEAT-020** | Sem CI | GitHub Actions: pytest on push/PR | `fa7756f` |
| **DEBT-001** | Lógica inline nos routers | `ConnectionService`, `ConversationService`, `MetricsService`, `TenantService` | `da9d0ee` |
| **FEAT-012** | Sem limite de agentes por plano | `plan_limits.assert_can_create_agent` + plano `free` | `da9d0ee` |
| **FEAT-001** | Sem `/reset-password` no frontend | GuestRoute + formulário alinhado ao backend | frontend `4f8a0bf` |
| **DEBT-009** | Dados fake em Configurações | Empty states honestos; removidos sessões/webhooks mock | frontend `4f8a0bf` |
| **BUG-006** | Modelo OpenAI divergente editor/onboarding | `src/lib/models.ts` como fonte única (`gpt-4.1-mini`) | frontend `4f8a0bf` |
| **BUG-007** | `useUsage` duplicado em `useData` | Canônico em `useBilling.ts` | frontend `4f8a0bf` |
| **BUG-008** | `tenant.id` exibido como API key | Removido; UX corrigida | frontend `4f8a0bf` |
| **DEBT-014** | Toggle senha Login sem a11y | Paridade com ResetPassword (40px, focus-ring) | frontend `b4f7b2c` |

### Sprint 2 — Produto e editor

| ID | Problema | Solução | Commit / PR |
|----|----------|---------|-------------|
| **FEAT-002** | Sem reenvio/confirmação de email | `POST /auth/resend-confirmation`; `ConfirmEmail` + `VerifyEmailGate` | backend `11c9880` + frontend Sprint 2 |
| **DEBT-002** | `AgentEditorPage` monolítico | Hook `useAgentEditorForm` + 6 componentes de aba | frontend `8ca3b05` |
| **FEAT-011** | Onboarding sempre aparecia | Condicional: só se zero agentes e sem flag localStorage | frontend `abe17c7` |
| **FEAT-003** | Aba Multimodal placeholder | Persistência `multimedia.image/document` | frontend `abe17c7` |
| **FEAT-004** | Aba Áudio placeholder | `multimedia.audio` | frontend `abe17c7` |
| **FEAT-005** | Aba Follow-up placeholder | `followup_*` + liga `schedule_followup` | frontend `abe17c7` |
| **FEAT-006** | Histórico de versões só toast | Sheet com duplicar/restaurar rascunho | frontend `d2a6710` |
| **FEAT-007** | Tools sem UI de config | Dialog `tool_config` (ex. `send_to_webhook`) | frontend `d2a6710` |
| **FEAT-008** | Toolbar do prompt vazia | Negrito/itálico/variável/templates | frontend `d2a6710` |
| **FEAT-009** | Simulador sem tool calls | `SimulateResponse.tool_calls` no backend + UI | backend `a6b0d24`, frontend `d2a6710` |
| **FEAT-010** | Sem tema escuro | `ThemeProvider` + toggle | frontend `d2a6710` |
| **DEBT-003** | OnboardingWizard monolítico | `components/onboarding/` hook + 4 steps | frontend `3044289` |
| **DEBT-004** | God file `useData.ts` | Hooks dedicados; barrel deprecated | frontend `3044289` |
| **FEAT-013** | Sem Stripe Customer Portal | `POST /billing/portal` | backend `50f1873` + frontend batch |
| **FEAT-016** | Modelos OpenAI hardcoded | `allowed_models.py` + `GET /agents/openai-models` | backend `50f1873` + frontend batch |
| **DEBT-005** | Dois sistemas de toast | Apenas Sonner | frontend `32d6b47` |
| **DEBT-006** | `NavLink.tsx` morto | Removido | frontend batch |
| **DEBT-007** | ~24 primitivos shadcn órfãos | Removidos | frontend batch |
| **DEBT-008** | Cores hardcoded em gráficos | `chartTokens.ts` lê CSS vars | frontend batch |
| **DEBT-010** | Dois venvs Python | Python **3.12** canônico, `.python-version` | backend `66c6a0e` |
| **FEAT-019** | Sem observabilidade básica | `X-Request-ID`, `/health/ready`, `/metrics` Prometheus | backend `66c6a0e` |

### Sprint 3 — Mídia e multi-LLM

| ID | Problema | Solução | Commit / PR |
|----|----------|---------|-------------|
| **DEBT-012** | Tool `search_on_catalog` órfã | Migração `0008` + `sanitize_tool_names` + remoção no front | backend `f2b17dc`, frontend `77e2e33` |
| **FEAT-017** | Sem storage R2/S3 | `core/storage/media.py` (upload, presign, delete) | backend `f2b17dc` |
| **FEAT-018** | Tokens expirados acumulam | Cron ARQ 03:00 `cleanup_expired_tokens` | backend `f2b17dc` |
| **FEAT-021** | README/scripts com Bearer legado | `test_flow.py` e docs alinhados a cookies | backend `f2b17dc` |
| **FEAT-020+** | CI estreito | ruff em app/api/core/db + pytest unit + integration | backend `f2b17dc` |
| **DEV-LOCAL** | Dev local difícil sem Docker | SQLite + `init_sqlite_dev.py`; CORS regex localhost | backend `f2b17dc` |
| **FEAT-014** | Runtime ignorava mídia inbound | Parsers Z-API/Evolution, `media_input.py`, migração `0009` | backend `a15de34` |
| **DEBT-013** | Badges success/warning baixo contraste | Tokens `--success-subtle` / `--warning-subtle` + `statusTokens.ts` | frontend `ac16d68` |
| **FEAT-015** | Só OpenAI no gateway | `AnthropicProvider`, `GroqProvider`, `GET /agents/llm-models/{provider}` | backend `b643b05` |

**Correções locais pós-Sprint 3 (não commitadas no momento da redação):**

- Backend: `arq_pool` tolera Redis ausente em `development` (API sobe para dev sem fila).
- Frontend: loop infinito `tenants/me` ↔ `auth/refresh` com cookies inválidos (`auth_session_dead` + skip fetch em rotas públicas).

---

## 4. Decisões arquiteturais (ADRs)

ADRs **do produto** em `.claude/squad/project/ADR/`:

| ADR | Título | Decisão | Motivo |
|-----|--------|---------|--------|
| **ADR-006** | Egress HTTP seguro contra SSRF e DNS rebinding | `resolve_validated_url` + `safe_post`/`safe_get` com pin de IP e `sni_hostname` | Fechar SEC-001 e DEBT-011; eliminar janela TOCTOU do httpx |
| **ADR-007** | Fronteira de transação DB | HTTP: commit só em `get_db()`; worker/runtime: commits explícitos | BUG-003; uma unidade de trabalho por request; evita estado parcial |

**Decisões rápidas relevantes** (ver `DECISIONS_LOG.md`):

- Auth cookie httpOnly (não Bearer no browser).
- Multi-tenant shared-schema com `tenant_id` manual.
- Fila arq/Redis para desacoplar webhook do runtime.
- Plugin registry auto-discovery para tools.
- Dedup webhook Redis SETNX TTL 5 min.
- Production Mode adotado pelo usuário no kickoff.

> ADRs em `.claude/squad/template/memory/ADR/` (001–005) são do **template da squad**, não decisões específicas do AgentesIA.

---

## 5. Métricas da entrega

| Métrica | Início (kickoff) | Final |
|---------|------------------|-------|
| **Testes backend** | ~90 (`91eab80`) | **184** coletados |
| **PRs mergeados (backend)** | 0 | **6** PRs formais (#1–#6) + merges diretos na `main` |
| **PRs mergeados (frontend)** | 0 | Commits diretos na `main` (branch `squad/frontend-fixes` integrada) |
| **Arquivos alterados (estimativa)** | — | Backend: **~109 arquivos**, +6496/−1352 linhas · Frontend: **~98 arquivos**, +4133/−4949 linhas |
| **Migrações Alembic** | 7 | **9** (`0008` tools sanitize, `0009` media metadata) |

### Tasks fechadas por categoria

| Categoria | Quantidade | IDs |
|-----------|------------|-----|
| **SEC** | 4 | SEC-001, SEC-002, SEC-003, SEC-004 |
| **BUG** | 8 | BUG-001 … BUG-008 |
| **FEAT** | 21 | FEAT-001 … FEAT-021 (incl. FEAT-020 CI ampliado) |
| **DEBT** | 14 | DEBT-001 … DEBT-014 (DEBT-011 via ADR-006) |
| **DEV** | 1 | DEV-LOCAL |
| **Análise** | 1 | Kickoff architecture review |
| **Total Done** | **49** itens no TASK_BOARD | |

---

## 6. Estado atual do produto

### Pronto para produção (com infra correta)

- Auth completo: registro, login, refresh rotacionado, logout, forgot/reset password, confirmação e reenvio de email.
- CRUD agentes + versões + publicar/duplicar/simular.
- Editor funcional: prompt, tools, multimodal/áudio/follow-up, histórico de versões, simulador com tool calls.
- Conexões WhatsApp (Z-API/Evolution) com tokens Fernet.
- Webhooks com dedup Redis; runtime LLM (OpenAI, Anthropic, Groq) + tools.
- **Mídia inbound** fase 1: áudio (Whisper) e imagem (vision) quando flags `multimedia` ativas.
- Billing Stripe: planos, créditos, webhooks idempotentes, Customer Portal.
- Métricas e conversas com polling TanStack Query.
- Segurança crítica Sprint 1 fechada (SSRF, rate limit Redis, créditos atômicos, egress Evolution).
- Observabilidade básica: health, readiness, Prometheus metrics, request ID.
- CI backend verde (ruff parcial + pytest).

### Implementado mas depende de infra

| Componente | Requisito |
|------------|-----------|
| Fila / webhooks assíncronos | **Redis** + **worker arq** |
| Rate limit em produção | **Redis** (`RATE_LIMIT_STORAGE_URI` ou `REDIS_URL`) |
| Persistência real | **PostgreSQL** (SQLite só dev local) |
| Upload mídia inbound | **R2/S3** (`R2_*` env vars) |
| Email transacional | **Resend** (`RESEND_API_KEY`) |
| Pagamentos | **Stripe** keys + webhook público |
| LLM | **OPENAI_API_KEY** mínimo; Anthropic/Groq opcionais |

### Fora do escopo / incompleto

- **FEAT-014 fase 2:** envio outbound de mídia pelo agente.
- Extração de **PDF/documentos** no runtime.
- **80% cobertura** e **≥95% em paths críticos** (gate Production não atingido).
- **SLOs, alertas, tracing** (OTel) — FEAT-019 é base, não operação completa.
- **Pipeline de deploy** produção (FEAT-020 cobre CI, não CD).
- **E2E Playwright** com cobertura real.
- Placeholders de produto: 2FA, exportar dados, upload logo, notificações, sessões ativas (UI futura).
- **PRD** formal não criado.
- Ruff/lint em **100%** do backend — escopo CI zerado (`1229605`); repo completo opcional

---

## 7. Backlog remanescente

O TASK_BOARD reflete **OPS-RAILWAY** em Doing (configuração do painel). Itens abaixo são o backlog técnico pós Fase A+B:

#### Itens fechados após Sprint 3 (Fase A+B — 2026-06-23)

| ID | Task | Commit |
|----|------|--------|
| SEC-005 | fix loop auth/refresh frontend | `4a7feb2` |
| DEV-002 | arq_pool tolerante Redis em dev | `286df2d` |
| OPS-SCAFFOLD | scaffold Railway (Dockerfile.worker, railway.toml, Python 3.12) | `9f9892d`, `6ddc3a8` |
| QUALITY-001 | ruff 0 violações | `1229605` |
| QUALITY-002 | bundle split + exhaustive-deps + notificações + /forgot-password | `4199467` |

#### Backlog aberto

| Prioridade | ID sugerido | Tarefa |
|------------|-------------|--------|
| **P0** | OPS-RAILWAY | Configurar projeto Railway no painel + smoke test ([GUIA_RAILWAY.md](docs/GUIA_RAILWAY.md)) |
| **P0** | OPS-001 | CD pipeline (scaffold Railway feito — próximo passo após smoke test) |
| **P0** | FEAT-014b | Mídia **outbound** (send_audio/send_image via adapter) |
| **P0** | QA-001 | Gate cobertura **≥80%** / **≥95%** críticos no CI |
| **P1** | FEAT-022 | Extração de texto em **documentos/PDF** inbound |
| **P1** | OBS-001 | SLOs, error budgets, alertas Prometheus |
| **P1** | QA-002 | Suite **E2E** Playwright (login → criar agente → simular) |
| **P2** | DEBT-015 | Ruff/mypy em todo o repo backend (escopo CI já zerado) |
| **P2** | FEAT-023 | Sessões ativas + revogação (backend + UI real) |
| **P2** | DOC-001 | **PRD** formal + atualizar ARCHITECTURE.md pós-squad |
| **P3** | FEAT-024 | `context_id` OpenAI threads (hoje histórico reconstruído) |
| **P3** | FEAT-025 | 2FA, export LGPD, webhooks de tenant |

---

## 8. Guia de go-live

### Infra obrigatória

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Frontend   │────▶│  API (Uvicorn)│────▶│ PostgreSQL  │
│  (CDN/Vite) │     │  :8000        │     │  16+        │
└─────────────┘     └───────┬──────┘     └─────────────┘
                            │
                    ┌───────┴───────┐
                    ▼               ▼
              ┌──────────┐   ┌──────────┐
              │  Redis 7 │   │  Worker  │
              │  arq     │   │  arq     │
              └──────────┘   └──────────┘
```

Opcional mas recomendado: **Cloudflare R2** (mídia), **Resend** (email), **Stripe** (billing).

### Variáveis de ambiente críticas

**Backend**

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `DATABASE_URL` | Sim | `postgresql+asyncpg://...` |
| `DATABASE_URL_SYNC` | Sim | URL sync para Alembic |
| `REDIS_URL` | Sim | `redis://host:6379/0` |
| `SECRET_KEY` | Sim | JWT HS256 (≥64 chars) |
| `ENCRYPTION_KEY` | Sim | Fernet para tokens WhatsApp |
| `OPENAI_API_KEY` | Sim* | Runtime e simulador |
| `APP_ENV` | Sim | `production` em prod |
| `APP_URL` | Sim | URL pública da API |
| `FRONTEND_URL` | Sim | CORS e links de email |
| `STRIPE_SECRET_KEY` | Se billing | |
| `STRIPE_WEBHOOK_SECRET` | Se billing | |
| `RESEND_API_KEY` | Se email | Sem ela: sem confirmação real |
| `R2_ACCESS_KEY` / `R2_SECRET_KEY` / `R2_BUCKET` / `R2_ENDPOINT_URL` | Se mídia persistida | |
| `ANTHROPIC_API_KEY` / `GROQ_API_KEY` | Opcional | Providers alternativos |
| `RATE_LIMIT_STORAGE_URI` | Prod multi-worker | Deve apontar Redis |

**Frontend**

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `VITE_API_URL` | Sim | URL da API (ex. `https://api.seudominio.com`) |

### Ordem de deploy

```bash
# 1. Infra: Postgres + Redis
# 2. Backend: migrações
docker compose exec api alembic upgrade head
# ou em bare metal:
alembic upgrade head

# 3. Subir API
uvicorn app.main:app --host 0.0.0.0 --port 8000

# 4. Subir worker (obrigatório para WhatsApp)
python -m arq core.queue.worker.WorkerSettings

# 5. Build e deploy frontend
cd ia-reply && npm ci && npm run build
# servir dist/ via CDN ou nginx

# 6. Configurar webhook Stripe apontando para /billing/webhook
# 7. Configurar webhooks Z-API/Evolution → /webhooks/{provider}/{secret}
```

### Smoke test antes de abrir para usuários

```bash
# API viva
curl -s https://api.example.com/health
curl -s https://api.example.com/health/ready   # deve incluir Redis/DB

# Fluxo auth (script oficial)
cd saas-agentes-backend
python scripts/test_flow.py

# Manual no browser
# 1. Cadastro + confirmação email (ou bypass dev)
# 2. Login → painel /app/agentes
# 3. Criar agente, publicar versão
# 4. Simular no editor (tool call visível)
# 5. Criar conexão WhatsApp (QR)
# 6. Enviar mensagem teste → resposta no WhatsApp
# 7. Verificar débito de créditos em /app/billing
```

**Atenção dev local:** Adminer no compose usa porta **8080** — conflita com Vite do frontend; em dev use portas distintas ou só um dos dois.

---

## 9. Próximos passos sugeridos (Sprint 4)

1. **Operação produção:** CD (staging → prod), Postgres gerenciado, Redis gerenciado, worker em processo separado, secrets em vault.
2. **Qualidade Production Mode:** meta de cobertura no CI, E2E críticos, post-mortem template.
3. **FEAT-014 fase 2 + documentos:** completar loop multimídia e PDF.
4. **Observabilidade operacional:** dashboards Grafana, alertas em `/metrics`, SLO latência webhook→resposta.
5. **Produto:** PRD v1, priorizar sessões ativas e webhooks de tenant se houver demanda.
6. **Higiene:** commitar fixes auth loop + arq dev; arquivar branches `squad/*`; atualizar `ARCHITECTURE.md` (ainda reflete kickoff).

---

## Referências

| Artefato | Caminho |
|----------|---------|
| Arquitetura (atualizar) | `.claude/squad/project/ARCHITECTURE.md` |
| Task board | `.claude/squad/project/TASK_BOARD.md` |
| Decisões | `.claude/squad/project/DECISIONS_LOG.md` |
| FEAT-014 design | `.claude/squad/project/docs/FEAT-014-runtime-media.md` |
| Governança | `TASK_BOARD.md`, `DIAGNOSTICO_RAILWAY.md`, `RESUMO_FINAL.md` |
| Deploy Railway | [docs/GUIA_RAILWAY.md](docs/GUIA_RAILWAY.md) |
| Backend README | `saas-agentes-backend/README.md` |

---

*Documento gerado pela squad AgentesIA em Production Mode. Para retomar trabalho: `/squad-resume`.*
