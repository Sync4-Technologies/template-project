# Relatório de Diagnóstico AgentesIA

**Data:** 2026-06-23  
**Executado por:** Tech Lead (Cursor Agent)  
**Escopo inicial:** Backend `b643b05` · Frontend `ac16d68` · Destino Railway  
**Atualizado:** Backend `1229605` · Frontend `4199467` (pós Fase A+B)  
**Modo:** Diagnóstico + resoluções documentadas

---

## ✅ Atualização pós Fase A + B — 2026-06-23

| Bloqueador original | Resolução |
|--------------------|-----------|
| Sem railway.toml / Procfile | ✅ `railway.toml` criado em ambos os repos (`9f9892d`, `6ddc3a8`) |
| Worker ARQ não configurado | ✅ `Dockerfile.worker` criado (`9f9892d`) |
| Dockerfile Python 3.11 | ✅ Atualizado para 3.12 (`9f9892d`) |
| alembic no CMD (race condition) | ✅ Movido para `releaseCommand` no `railway.toml` |
| Fixes não commitados | ✅ SEC-005 auth loop (`4a7feb2`) + arq_pool dev (`286df2d`) |
| FRONTEND_URL / CORS | ✅ Documentado no GUIA_RAILWAY.md; config via env vars Railway |
| ruff 202 violações | ✅ 0 violações — `1229605` |
| Bundle 1.2 MB | ✅ Split em 8 chunks, maior 411 kB — `4199467` |
| Switches notificações enganosos | ✅ disabled + "Em breve" — `4199467` |
| ESLint 5 warnings | ✅ 0 warnings — `4199467` |
| /forgot-password sem rota | ✅ Página dedicada criada — `4199467` |

**Estado atual:** pronto para configuração do projeto Railway no painel.  
**Referência:** [GUIA_RAILWAY.md](docs/GUIA_RAILWAY.md)

**Pendente (Sprint 4):**
- Cobertura ≥80% (atual 66%)
- E2E Playwright
- CD pipeline (OPS-001 — após deploy Railway)
- `request_id` no worker
- SLOs / alertas

> As seções abaixo preservam o diagnóstico **original** (pré Fase A) como registro histórico.

---

## Sumário Executivo (snapshot pré Fase A — histórico)

O código em `main` está **maduro para piloto técnico**: 184 testes backend passando, build frontend OK, correções críticas de segurança (SSRF, créditos atômicos, egress Evolution) **confirmadas no código**. Porém **não está pronto para deploy Railway imediato**: faltam artefatos de deploy (`railway.toml`, serviço worker), dois fixes importantes estão **só no working directory** (não commitados), o `Dockerfile` usa **Python 3.11** enquanto o projeto padronizou **3.12**, e `FRONTEND_URL` default (`localhost:3000`) não bate com Vite dev (`8080`). Redis e worker são **obrigatórios** em produção — o fix local de `arq_pool` só tolera Redis ausente em `development`, não em `production`.

---

## 🔴 Bloqueadores de Deploy

| # | Item | Evidência |
|---|------|-----------|
| 1 | **Sem configuração Railway** nos repos | Não existe `railway.toml` nem `Procfile` em backend ou frontend |
| 2 | **Worker ARQ não configurado para deploy** | `Dockerfile` CMD só roda `alembic + uvicorn`; worker (`python -m arq core.queue.worker.WorkerSettings`) precisa de **segundo serviço** Railway |
| 3 | **Redis obrigatório em produção** | Webhooks enfileiram via `get_arq_pool()`; em `APP_ENV=production` falha de Redis **derruba** startup da API (comportamento atual em `main` remoto) |
| 4 | **Fixes críticos não commitados** | `arq_pool.py` (backend) e loop auth (frontend) existem só localmente — deploy a partir de `origin/main` **não** inclui essas correções |
| 5 | **`FRONTEND_URL` / CORS** | Default backend `http://localhost:3000`; frontend dev em `8080`. Em Railway, `FRONTEND_URL` e `VITE_API_URL` devem ser definidos explicitamente ou CORS/cookies quebram |
| 6 | **Postgres gerenciado + migrações** | `alembic current` falhou localmente (sem Postgres válido); em Railway é preciso `release`/`preDeploy` com `alembic upgrade head` e `DATABASE_URL` async correta |

---

## 🟡 Problemas Importantes (corrigir antes do piloto)

| # | Item | Detalhe |
|---|------|---------|
| 1 | **Dockerfile Python 3.11 vs projeto 3.12** | `FROM python:3.11-slim` vs `.python-version` / README 3.12 |
| 2 | **Cobertura 66%** (app+core) | Abaixo do gate Production Mode (≥80%) |
| 3 | **Ruff: 202 violações** no escopo ampliado | CI só linta subset; repo inteiro tem débito (160× E501 line-too-long) |
| 4 | **Débito antes do envio WhatsApp** | Créditos debitados após LLM, **antes** de `send_text` — se envio falhar, crédito já foi consumido |
| 5 | **`request_id` não propaga ao worker** | Middleware HTTP define `X-Request-ID`; jobs ARQ usam `connection_id`/`message_id`, sem correlação webhook→job |
| 6 | **Bundle frontend 1.2 MB** | Warning Vite >500 kB; impacto LCP em mobile |
| 7 | **Notificações em Configurações** | Switches com `defaultChecked` + toast "em breve" — UX enganosa (não persiste) |
| 8 | **Forgot password** | Fluxo embutido no `/login` (botão), sem rota `/forgot-password` dedicada |
| 9 | **`.env.example` frontend** | Só `VITE_API_URL`; falta documentar cookies cross-origin / domínio produção |
| 10 | **Adminer vs Vite porta 8080** | Conflito em docker-compose local (documentado no RESUMO_FINAL) |

---

## 🟢 OK — Confirmado funcionando

### Segurança e integridade (código lido)

| Check | Status | Onde |
|-------|--------|------|
| `core/safe_http.py` existe | ✅ | `safe_post`, `safe_get` com pin IP + SNI |
| Usado em `send_to_webhook` | ✅ | `core/tools/send_to_webhook/handler.py` |
| Usado em `EvolutionAdapter` | ✅ | `core/channel/evolution.py` |
| `debit_credits()` atômico | ✅ | `UPDATE ... RETURNING` com `CASE` clamp — `credits_service.py` |
| Commit antes de `send_text` (runtime) | ✅ | `agent_runtime.py` L350 commit → L353 `send_text` |
| Rate limit Redis (não memória em prod) | ✅ | `rate_limit_storage_uri_resolved` → `redis_url` por padrão |
| Reset password single-use | ✅ | `_claim_password_reset_token` atômico — `auth_service.py` + testes SEC-004 |
| `APP_ENV` distingue dev/prod | ✅ | `is_production`, `skip_email_delivery_in_dev`, arq_pool (fix local) |

**Nota sobre `get_db()`:** em requests HTTP, `commit()` ocorre ao **final** do request (`database.py`). Rotas HTTP de webhook **não** chamam WhatsApp diretamente — enfileiram job. O runtime no **worker** faz commit **antes** do envio externo (BUG-002).

### Frontend

| Check | Status |
|-------|--------|
| `tenant.id` como API Key | ✅ Removido; aba API mostra empty state honesto |
| Dados fake sessões/webhooks | ✅ Substituídos por empty states + "em breve" |
| `ThemeProvider` + persistência | ✅ `storageKey="agentesia-theme"` via `next-themes` |
| TypeScript | ✅ `tsc --noEmit` sem erros |
| Build produção | ✅ `npm run build` sucesso |
| ESLint | ✅ 0 erros, 5 warnings (`react-hooks/exhaustive-deps` em MetricasPage) |

### Testes

| Métrica | Valor |
|---------|-------|
| Coletados | **184** |
| Passando | **184** |
| Falhando | **0** |
| Skipped | **0** |
| Cobertura (app+core) | **66%** |

### Migrações Alembic

- Histórico **linear** (9 revisões, sem branches)
- **HEAD:** `0009_message_media_metadata`
- `alembic current` não executou (Postgres local indisponível / credenciais inválidas) — histórico via `alembic history` OK

### Fluxo WhatsApp (código)

| Etapa | Status |
|-------|--------|
| Dedup Redis SETNX TTL 5min | ✅ `api/webhooks/router.py` `_is_duplicate` |
| Enfileira `process_webhook_message` | ✅ Z-API e Evolution |
| Worker processa runtime | ✅ `core/queue/worker.py` |
| Retry ARQ | ✅ `retry_jobs=True`, `max_tries=3`, `job_timeout=120` |
| Abort sem retry (payload inválido, sem crédito, etc.) | ✅ `return` explícito no worker |

---

## 1. Estado dos repositórios

### Backend (`saas-agentes-backend`)

```
Branch: main (up to date with origin/main)
HEAD: b643b05
Stashes: nenhum
```

**Alterações não commitadas:**

| Arquivo | Δ |
|---------|---|
| `core/queue/arq_pool.py` | +20 / −5 linhas |

**Últimos commits:**
```
b643b05 feat(FEAT-015): Anthropic e Groq no LLMGateway
a15de34 feat(FEAT-014): runtime de mídia inbound
f2b17dc feat(sprint-3): DEBT-012, FEAT-017/018, dev SQLite, CORS e CI
...
```

### Frontend (`ia-reply`)

```
Branch: main (up to date with origin/main)
HEAD: ac16d68
Stashes: nenhum
```

**Alterações não commitadas:**

| Arquivo | Δ |
|---------|---|
| `src/lib/api.ts` | +46 linhas (auth_session_dead, redirect) |
| `src/contexts/AuthContext.tsx` | +16 linhas (skip fetch rotas públicas) |
| `src/lib/auth.ts` | +3 linhas (`resetAuthSession` no login) |

**Últimos commits:**
```
ac16d68 fix(DEBT-013): contraste WCAG badges
77e2e33 fix(DEBT-012): remove search_on_catalog
...
```

### Governança (`template-project`)

- `RESUMO_FINAL.md` untracked (gerado nesta sessão anterior)
- Demais artefatos squad com mudanças pré-existentes fora do escopo deste diagnóstico

---

## 2. Fixes pendentes — confirmar e localizar

### 2a. Backend — `arq_pool` tolerante a Redis

**Arquivo:** `core/queue/arq_pool.py`

| Pergunta | Resposta |
|----------|----------|
| Lança exceção se Redis indisponível? | **Sim** em `production`; **Não** em `development` (fix local) |
| Checagem `APP_ENV == "development"`? | **Sim** — `settings.app_env == "development"` no `except` |
| Fix implementado? | **Sim**, no working directory |
| Commitado? | **Não** |

Comportamento do fix:
- `init_arq_pool()` retorna `None` em dev se Redis recusar conexão
- `get_arq_pool()` ainda levanta `RuntimeError` se pool `None` (webhooks falham ao enfileirar)
- **Railway com `APP_ENV=production`:** startup continua **falhando** sem Redis (comportamento correto para prod)

### 2b. Frontend — loop auth

**Arquivos:** `src/lib/api.ts`, `src/contexts/AuthContext.tsx`, `src/lib/auth.ts`

| Proteção | Implementada? |
|----------|---------------|
| Flag `auth_session_dead` + `sessionStorage` | ✅ |
| Skip refresh se sessão morta | ✅ |
| Redirect só fora de rotas públicas | ✅ `/login`, `/cadastro`, `/reset-password` |
| Skip `GET /tenants/me` em rotas públicas | ✅ também `/`, `/precos`, `/confirm-email` |
| `resetAuthSession()` após login | ✅ |
| Segundo 401 após `_retry` → sem novo refresh | ✅ |
| Commitado? | **Não** |

**Risco residual:** usuário autenticado em `/app/*` com cookies inválidos ainda dispara 1 ciclo refresh antes de marcar sessão morta; com fix commitado, não há loop infinito nem reload storm.

---

## 3. Varredura de segurança e integridade (checklist)

### Backend

- [x] `core/safe_http.py` existe e é usado em `send_to_webhook` e `EvolutionAdapter`
- [x] `debit_credits()` usa UPDATE atômico único
- [x] Runtime worker: `commit()` **antes** de `adapter.send_text()` (não depois)
- [x] Rate limit usa `storage_uri` resolvido para Redis (não memória, salvo override `memory://`)
- [x] Reset password token invalidado após uso (single-use atômico)
- [x] `APP_ENV` lido via `settings.app_env` / `is_production`

### Frontend

- [x] `tenant.id` não exibido como API Key (aba API = empty state)
- [x] Configurações sem dados fake enganosos (sessão atual = navegador atual, explícito)
- [x] `ThemeProvider` com `storageKey` — tema persiste no reload

---

## 4. Cobertura de testes

```bash
184 tests collected
184 passed in ~30s
TOTAL coverage (app+core): 66%
```

### Módulos com cobertura baixa (<50%)

| Módulo | Cobertura |
|--------|-----------|
| `core/tools/search_on_web/handler.py` | 18% |
| `core/services/billing_service.py` | 41% |
| `core/runtime/media_input.py` | 42% |
| `core/queue/worker.py` | 46% |
| `core/services/metrics_service.py` | 46% |
| `core/services/connection_service.py` | 50% |

### Gaps (sem arquivo `test_*` dedicado óbvio)

~27 módulos core/app sem test file direto (ex.: `worker.py`, `anthropic_provider`, `groq_provider`, `agent_runtime` — parte coberta indiretamente por `test_runtime_*`, `test_webhooks`, etc.)

---

## 5. Qualidade de código

### Backend — ruff (`app/ api/ core/ db/`)

| Código | Qtd |
|--------|-----|
| E501 line-too-long | 160 |
| N999 invalid-module-name | 24 |
| I001 unsorted-imports | 12 |
| F401 unused-import | 4 |
| Outros | 2 |
| **Total** | **202** |

CI atual linta este escopo — violações existem mas **não necessariamente bloqueiam** se CI não falha (verificar workflow).

### Frontend — TypeScript

```
npx tsc --noEmit → 0 erros
```

### Frontend — ESLint

```
5 warnings (MetricasPage — react-hooks/exhaustive-deps)
0 errors
```

---

## 6. Dependências e build

### Backend

- `import app.main` → **OK**
- Pacotes outdated (amostra): fastapi, bcrypt, boto3, cryptography, etc. — nenhum crítico de segurança identificado nesta passagem

### Frontend — build

```
✓ built in 4.53s
dist/assets/index-CTBjavcE.js  1,226.17 kB │ gzip: 350.52 kB
⚠ chunk > 500 kB
```

---

## 7. Configuração Railway

### Arquivos encontrados

| Repo | railway.toml | Procfile | Dockerfile | .env.example |
|------|--------------|----------|------------|--------------|
| Backend | ❌ | ❌ | ✅ | ✅ (completo) |
| Frontend | ❌ | ❌ | ❌ | ✅ (só `VITE_API_URL`) |

### Dockerfile backend (atual)

```dockerfile
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
```

| Item | Status |
|------|--------|
| Migrations no start | ✅ no CMD |
| Uvicorn produção | ✅ (sem `--reload`) |
| Worker ARQ | ❌ não incluído |
| Python version | ⚠️ 3.11-slim (projeto = 3.12) |

### Variáveis `.env.example` vs RESUMO_FINAL

Backend `.env.example` cobre: DB, Redis, auth, LLMs, Stripe, Resend, R2, `APP_ENV`, `APP_URL`, `FRONTEND_URL`. **Alinhado** com seção 8 do RESUMO_FINAL.

### Serviços Railway recomendados (mínimo)

1. **API** — web, Dockerfile ou Nixpacks, `alembic upgrade head && uvicorn ...`
2. **Worker** — background, `python -m arq core.queue.worker.WorkerSettings`
3. **PostgreSQL** — plugin Railway
4. **Redis** — plugin Railway
5. **Frontend** — static site, `npm run build`, servir `dist/`

---

## 8. UX — problemas visuais e funcionais (inspeção de código)

| Página / fluxo | Empty states | Loading | Erros | Mobile / responsivo |
|----------------|--------------|---------|-------|---------------------|
| `/login` | N/A | submit state | toast + validação Zod | form padrão shadcn |
| `/cadastro` | N/A | submit | toast | OK estrutural |
| Forgot password | Inline no Login | botão async | toast sucesso/erro | sem página dedicada |
| `/reset-password` | GuestRoute | submit | validação min 8 chars | toggle a11y OK |
| `/app/agentes` | EmptyState component | RQ isLoading | erro RQ | grid responsivo |
| Editor 6 abas | Prompt/Tools/Simulator/Multimodal/Áudio/Follow-up + histórico sheet | spinner full page | 404/erro com CTA voltar | tabs scroll horizontal |
| Simulador | — | mutation pending | timeout 60s | tool_calls expostos (FEAT-009) |
| `/app/conexoes` | EmptyState | RQ + QR polling 5s/30s | toasts | wizard multi-step |
| `/app/billing` | planos RQ | skeletons | stripe portal errors | cards |
| `/app/configuracoes` | API/webhooks honestos | mutation loaders | hooks toast | tabs sidebar |
| Notificações tab | — | — | toast "em breve" | switches não persistem ⚠️ |
| Sessões ativas | 1 card "esta sessão" | — | texto "em breve" | OK |

**Tema escuro:** `ThemeToggle` em AppLayout e Configurações; `next-themes` persiste em `localStorage` key `agentesia-theme`.

---

## 9. Fluxo WhatsApp end-to-end

```
POST /webhooks/{provider}/{secret}
  → valida secret, parse adapter
  → Redis SETNX dedup (5 min)
  → arq.enqueue_job("process_webhook_message")
  → 200 OK imediato

Worker process_webhook_message
  → pre-checks (conexão, tenant, créditos, versão published)
  → AgentRuntime.process()
      → LLM + tools
      → debit_credits (atômico)
      → commit DB
      → adapter.send_text()
  → erros recuperáveis: raise → arq retry (max 3)
```

| Pergunta | Resposta |
|----------|----------|
| Dedup SETNX? | Sim |
| Worker processa após webhook? | Sim |
| Retry LLM/falhas rede? | Sim, `max_tries=3` |
| Débito antes/depois envio? | **Antes** do `send_text`, **depois** do LLM |
| `request_id` no worker? | Não propagado do HTTP; logs com `connection_id`, `message_id` |

---

## 10. Banco de dados — migrações

```
0001 → ... → 0008_strip_search_on_catalog → 0009_message_media_metadata (HEAD)
```

- Linear: **sim**
- HEAD = 0009: **sim**
- `depends_on` quebrado: **não detectado**

---

## 📋 Fixes Pendentes não Commitados (resumo)

| Repo | Arquivo(s) | Estado | Impacto se deploy sem commit |
|------|------------|--------|------------------------------|
| Backend | `core/queue/arq_pool.py` | Implementado, WIP | Dev local sem Redis falha startup; prod inalterado |
| Frontend | `api.ts`, `AuthContext.tsx`, `auth.ts` | Implementado, WIP | Loop auth com cookies stale em `/app` ou após reload |

**Diff total:** backend 1 arquivo (+20/−5) · frontend 3 arquivos (+60/−5)

---

## 🏗️ Configuração Railway — o que falta

1. Criar projeto Railway com **5 componentes** (API, Worker, Postgres, Redis, Frontend static)
2. Definir variáveis: `DATABASE_URL`, `REDIS_URL`, `SECRET_KEY`, `ENCRYPTION_KEY`, `OPENAI_API_KEY`, `APP_ENV=production`, `APP_URL`, `FRONTEND_URL`, Stripe/Resend/R2 conforme uso
3. **Release command** ou CMD com `alembic upgrade head`
4. **Serviço worker** separado com mesmo env + `python -m arq core.queue.worker.WorkerSettings`
5. Frontend: `VITE_API_URL=https://<api-railway-domain>` no build time
6. Atualizar `Dockerfile` para Python 3.12 (recomendado)
7. **Commitar** fixes auth + avaliar se `arq_pool` dev-only deve ir para `main` ou ficar só local

---

## 📊 Métricas de Qualidade

| Métrica | Valor |
|---------|-------|
| Testes | **184** passando / **0** falhando / **184** coletados |
| Cobertura estimada (app+core) | **66%** |
| Erros TypeScript | **0** |
| Violações ruff (app/api/core/db) | **202** |
| ESLint errors | **0** (5 warnings) |
| Build frontend | **OK** |
| Import backend | **OK** |

---

## 🔧 Recomendações de Ação (priorizadas)

1. **Commitar** fixes frontend (loop auth) — bloqueia UX em piloto com sessões stale.
2. **Criar artefatos Railway**: `railway.toml` ou docs com 2 serviços (api + worker), Postgres, Redis.
3. **Corrigir Dockerfile** → Python 3.12; considerar não rodar `alembic` no mesmo processo que uvicorn em multi-replica (usar release command).
4. **Definir env produção**: `FRONTEND_URL`, `APP_URL`, `APP_ENV=production`, secrets gerados.
5. **Commitar ou reverter** `arq_pool` dev-tolerance — não afeta Railway prod, mas limpa working tree.
6. **Smoke test pós-deploy**: `scripts/test_flow.py`, webhook teste, mensagem WhatsApp real.
7. **Antes de abrir usuários**: gate cobertura 80%, E2E login→agente→simular, alertas `/metrics`.
8. **Opcional piloto**: code-split frontend para reduzir bundle 1.2 MB.

---

*Próximo passo sugerido: aprovar este relatório → prompt de correções + commits + scaffold Railway.*
