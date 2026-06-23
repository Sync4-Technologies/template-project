# Guia Railway — AgentesIA

> **Data:** 2026-06-23 · Pós Fase A + Fase B  
> Backend HEAD: `1229605` · Frontend HEAD: `4199467`

---

## Visão geral da arquitetura Railway

```
Railway Project: agentesia
├── api          (Web Service — Dockerfile)
├── worker       (Worker Service — Dockerfile.worker)
├── postgres     (Plugin PostgreSQL 16)
├── redis        (Plugin Redis 7)
└── frontend     (Static Site — dist/)
```

O repositório backend já inclui `railway.toml` com `releaseCommand` (`alembic upgrade head`), healthcheck `/health` e `Dockerfile.worker` para o serviço ARQ.

---

## PASSO 1 — Criar o projeto Railway

1. Acesse [railway.app](https://railway.app) → **New Project**
2. Nome: `agentesia`
3. Não adicione nada ainda — vamos criar serviço por serviço

---

## PASSO 2 — Plugins de infraestrutura (primeiro)

Crie os plugins **antes** dos serviços de app — as connection strings geradas serão usadas nas env vars.

### 2a. PostgreSQL

- **New** → **Database** → **PostgreSQL**
- Versão: **16** (se disponível; caso contrário 15)
- Nome do serviço: `postgres`
- Após criar, vá em **Variables** e copie a URL base
- Você precisará das **duas versões** abaixo para o backend:

```bash
# asyncpg (runtime FastAPI)
DATABASE_URL=postgresql+asyncpg://user:pass@host:port/db

# psycopg2 (Alembic release command)
DATABASE_URL_SYNC=postgresql+psycopg2://user:pass@host:port/db
```

> Railway fornece `DATABASE_URL` sem prefixo de driver. Adicione `+asyncpg` e `+psycopg2` manualmente ao configurar as env vars do serviço `api`.

### 2b. Redis

- **New** → **Database** → **Redis**
- Versão: **7**
- Nome do serviço: `redis`
- Após criar, copie `REDIS_URL` → formato `redis://default:pass@host:port`

---

## PASSO 3 — Serviço `api` (backend)

### Criar

- **New** → **GitHub Repo** → `Sync4-Technologies/saas-agentes-backend`
- Branch: `main`
- Nome do serviço: `api`
- Build: Railway detecta `Dockerfile` + `railway.toml`
- **Não faça deploy ainda** — configure as env vars primeiro

### Variáveis de ambiente

Vá em **api → Variables → Raw Editor** e cole (substituindo pelos valores reais):

```bash
# === App ===
APP_ENV=production
APP_URL=https://<dominio-api>.railway.app
FRONTEND_URL=https://<dominio-frontend>.railway.app

# === Segredos ===
# Gerar: openssl rand -hex 32
SECRET_KEY=<64-char-hex>
# Gerar: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
ENCRYPTION_KEY=<fernet-key>

# === Banco de dados ===
DATABASE_URL=postgresql+asyncpg://<user>:<pass>@<host>:<port>/<db>
DATABASE_URL_SYNC=postgresql+psycopg2://<user>:<pass>@<host>:<port>/<db>

# === Redis ===
REDIS_URL=redis://default:<pass>@<host>:<port>
RATE_LIMIT_STORAGE_URI=redis://default:<pass>@<host>:<port>

# === LLM ===
OPENAI_API_KEY=sk-...
# ANTHROPIC_API_KEY=         # opcional
# GROQ_API_KEY=              # opcional

# === Email ===
RESEND_API_KEY=re_...

# === Stripe ===
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRICE_FREE=price_...
STRIPE_PRICE_STARTER=price_...
STRIPE_PRICE_PRO=price_...

# === Storage R2 (opcional — mídia inbound) ===
# R2_ACCESS_KEY=
# R2_SECRET_KEY=
# R2_BUCKET=agentesia-media
# R2_ENDPOINT_URL=https://<account>.r2.cloudflarestorage.com
# R2_PUBLIC_URL=https://media.<seudominio>.com

# === Porta (opcional — Dockerfile expõe 8000) ===
PORT=8000
```

> **Atenção:** `APP_URL` e `FRONTEND_URL` devem bater com os domínios reais **sem barra final**. Em produção o CORS aceita **somente** `FRONTEND_URL` (`allow_credentials=True`).

> **PORT:** o `railway.toml` atual usa `uvicorn ... --port 8000`. Se o Railway exigir a variável `PORT` dinâmica, altere o `startCommand` para `--port ${PORT:-8000}` ou configure networking para mapear na porta 8000 do container.

### Release command (migrações)

O `railway.toml` no repo já define:

```toml
[[deploy.releaseCommand]]
command = "alembic upgrade head"
```

Confirme em **api → Settings → Deploy** que o pre-deploy/release command está ativo (ou configure manualmente se o painel não ler o toml).

### Health check

Em **api → Settings → Deploy** (ou via `railway.toml`):

- Health Check Path: `/health`
- Health Check Timeout: `30`

### Deploy

- Clique em **Deploy** no serviço `api`
- Acompanhe os logs: `alembic upgrade head` → `Uvicorn running`
- Verifique:

```bash
curl -s https://<dominio-api>.railway.app/health
# {"status":"ok"}

curl -s https://<dominio-api>.railway.app/health/ready
# {"status":"ready","checks":{"database":{"ok":true,...},"redis":{"ok":true,...}}}
# HTTP 503 se alguma dependência falhar (status "degraded")
```

---

## PASSO 4 — Serviço `worker` (ARQ)

### Criar

- **New** → **GitHub Repo** → mesmo repo `saas-agentes-backend`
- Branch: `main`
- Nome do serviço: `worker`
- **Settings → Build → Dockerfile Path:** `Dockerfile.worker`
- **Sem** release command (migrações só no `api`)
- **Sem** health check HTTP (worker não expõe porta)

### Variáveis de ambiente

Em **worker → Variables**: use **Reference Variables** do projeto ou copie do `api`.

O worker precisa no mínimo: `APP_ENV`, `DATABASE_URL`, `REDIS_URL`, `SECRET_KEY`, `ENCRYPTION_KEY`, `OPENAI_API_KEY` (+ `ANTHROPIC_API_KEY` / `GROQ_API_KEY` se usados).

> **Dica:** Shared Variables no nível do projeto evitam duplicação.

### Deploy

- Deploy → logs devem mostrar o worker ARQ iniciando (`arq` / jobs registrados)
- Status **Running** nos logs é suficiente (sem endpoint HTTP)

---

## PASSO 5 — Frontend (Static Site)

### Opção A — Static Site (recomendada)

- **New** → **GitHub Repo** → `Sync4-Technologies/saas-agentes-frontend`
- Branch: `main`
- Build Command: `npm ci && npm run build`
- Output Directory: `dist`
- Nome do serviço: `frontend`

### Opção B — `railway.toml` no repo

O frontend inclui `railway.toml` com Nixpacks + `npx serve dist`. Alternativa: Static Site no painel (sem `serve` em runtime).

### Variável de build (crítica)

```bash
VITE_API_URL=https://<dominio-api>.railway.app
```

> Injetada em **build time**. Mudança de domínio da API exige **rebuild** do frontend.

### Deploy

- Acesse o domínio → landing page
- `/login` sem erros CORS no DevTools (Network)

---

## PASSO 6 — Domínios

### Domínios Railway temporários

Cada serviço gera `*.railway.app` — use para smoke test inicial.

### Domínios próprios (piloto)

| Serviço | DNS sugerido |
|---------|--------------|
| `api` | `api.seudominio.com` → CNAME Railway |
| `frontend` | `app.seudominio.com` ou raiz → CNAME |

Após domínios próprios, atualize e **rebuild frontend**:

- `APP_URL=https://api.seudominio.com`
- `FRONTEND_URL=https://app.seudominio.com`
- `VITE_API_URL=https://api.seudominio.com`

---

## PASSO 7 — Stripe webhook

1. Stripe Dashboard → **Developers → Webhooks → Add endpoint**
2. URL: `https://<dominio-api>.railway.app/billing/webhook`
3. Eventos sugeridos:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
4. Copie **Signing Secret** (`whsec_...`) → `STRIPE_WEBHOOK_SECRET` no `api`
5. Re-deploy do `api`

---

## PASSO 8 — Smoke test

Execute nesta ordem.

### 8a. API básica

```bash
curl -s https://<dominio-api>.railway.app/health
curl -s https://<dominio-api>.railway.app/health/ready | jq .
curl -s https://<dominio-api>.railway.app/metrics | head -5
```

### 8b. Fluxo auth completo

```bash
# Cadastro (aliases name / company_name aceitos pelo backend)
curl -s -X POST https://<dominio-api>.railway.app/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Piloto","email":"piloto@teste.com","password":"Senha123!","company_name":"Empresa Piloto"}' \
  | jq .

# Login (cookies httpOnly)
curl -s -c cookies.txt -X POST https://<dominio-api>.railway.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"piloto@teste.com","password":"Senha123!"}' \
  | jq .

# Tenant autenticado
curl -s -b cookies.txt https://<dominio-api>.railway.app/tenants/me | jq .
```

Ou use o script oficial:

```bash
cd saas-agentes-backend
python scripts/test_flow.py
# (ajuste BASE_URL no script ou via env para o domínio Railway)
```

### 8c. Agente + simulador

Requer versão **published** — mais fácil via UI após login.

```bash
AGENT_ID=<uuid>

curl -s -b cookies.txt -X POST "https://<dominio-api>.railway.app/agents/${AGENT_ID}/simulate" \
  -H "Content-Type: application/json" \
  -d '{"message":"Olá, como funciona?"}' \
  | jq .
```

### 8d. Browser (manual)

1. `https://<dominio-frontend>.railway.app`
2. Cadastro → confirmação email (Resend) ou bypass se não configurado
3. Login → `/app/agentes`
4. Criar agente → publicar → simulador
5. `/app/billing` (Stripe)
6. Tema escuro persiste no reload
7. `/forgot-password` → email de recuperação

### 8e. Worker (WhatsApp)

Conexão Z-API ou Evolution no painel → mensagem teste.

Logs do `worker` (exemplos):

```
webhook_job_started
runtime_processed
webhook_job_finished
```

---

## PASSO 9 — Checklist pré-abertura para usuários

| Item | Como verificar |
|------|----------------|
| `/health/ready` → `status: ready` | `curl` (HTTP 200) |
| Migrações em HEAD `0009` | logs do release command |
| Worker rodando | Railway dashboard / logs |
| Email confirmação | cadastro + Resend |
| Stripe checkout | plano em test mode |
| Webhook WhatsApp | mensagem real |
| CORS OK | DevTools sem erro CORS |
| Cookies httpOnly | DevTools → Application |
| Tema escuro | reload |
| Forgot password | `/forgot-password` |

---

## Referência rápida — variáveis por serviço

| Variável | `api` | `worker` | `frontend` |
|----------|-------|----------|------------|
| `APP_ENV` | ✅ production | ✅ production | — |
| `APP_URL` | ✅ | ✅ | — |
| `FRONTEND_URL` | ✅ (CORS) | — | — |
| `SECRET_KEY` | ✅ | ✅ | — |
| `ENCRYPTION_KEY` | ✅ | ✅ | — |
| `DATABASE_URL` | ✅ | ✅ | — |
| `DATABASE_URL_SYNC` | ✅ (Alembic) | — | — |
| `REDIS_URL` | ✅ | ✅ | — |
| `RATE_LIMIT_STORAGE_URI` | ✅ | — | — |
| `OPENAI_API_KEY` | ✅ | ✅ | — |
| `ANTHROPIC_API_KEY` | opcional | opcional | — |
| `GROQ_API_KEY` | opcional | opcional | — |
| `RESEND_API_KEY` | ✅ | — | — |
| `STRIPE_*` | ✅ | — | — |
| `R2_*` | ✅ | ✅ | — |
| `VITE_API_URL` | — | — | ✅ build time |
| `PORT` | ✅ 8000 | — | — |

---

## Problemas comuns e soluções

| Sintoma | Causa provável | Solução |
|---------|---------------|---------|
| API startup falha | Redis indisponível em `production` | Verificar plugin Redis + `REDIS_URL` |
| `alembic upgrade head` falha | `DATABASE_URL_SYNC` sem `+psycopg2` | Corrigir prefixo do driver |
| CORS bloqueando frontend | `FRONTEND_URL` errado ou com `/` final | Domínio exato do frontend |
| Cookies não persistem | Domínios cruzados | Mesmo site ou `FRONTEND_URL` = origem real |
| Worker não processa | `REDIS_URL` diferente api/worker | Shared variables |
| Stripe webhook 400 | `STRIPE_WEBHOOK_SECRET` errado | `whsec_` do endpoint criado |
| Build frontend falha | `VITE_API_URL` ausente | Definir antes do build |
| Loop auth no login | cookies stale | fix SEC-005 em `4199467` |

---

## Artefatos no repositório (Fase A)

| Arquivo | Repo | Função |
|---------|------|--------|
| `Dockerfile` | backend | API Python 3.12 + uvicorn |
| `Dockerfile.worker` | backend | Worker ARQ |
| `railway.toml` | backend | build, health, release command |
| `railway.toml` | frontend | build nixpacks (opcional) |
| `.env.example` | ambos | referência de variáveis |

---

*Relacionado: [DIAGNOSTICO_RAILWAY.md](../DIAGNOSTICO_RAILWAY.md) · [RESUMO_FINAL.md](../RESUMO_FINAL.md)*
