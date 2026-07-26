# TASK_BOARD.md — AgentesIA

> Kanban da squad. Mover tarefas conforme progresso. Atualizar a cada sessão.

---

## Current Focus

- **Ultima sessao:** 2026-07-26 por Pablo (sessao de SISTEMA: v1.6.0 released — subagents nativos + advisor + Modo Delegado + UP-01; produto AgentesIA nao foi tocado)
- **Em andamento:** OPS-RAILWAY (deploy Railway piloto — Vinicius) segue como estava
- **Proximo passo (sistema):** batalha no trokey-franchising com a v1.6 valendo (squad-init JA RODADO la; plugin 1.6.0 user-scope — basta sessao nova + /squad-resume); achados -> LESSONS -> v1.6.1/v1.7 (UP-02 ja na fila)
- **Proximo passo (produto):** retomar OPS-RAILWAY com /squad-resume + rodar /squad-deploy-preflight antes do deploy
- **Bloqueios:** billing do GitHub Actions esgotado — CI nao roda; merge em develop/main exige suspender/restaurar required checks a mao (feito nos #31/#32) ate resolver
- **Branch ativo:** claude/squad-resume-b3e72a (worktree do upstream; tudo mergeado ate v1.6.0, tag pushada)
- **Modo do projeto:** Production

---

## 🔴 BLOQUEANTE / Segurança crítica

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| — | — | — | — |

---

## 🟠 Todo — Correção de bugs e consistência

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| — | — | — | — |

---

## 🟡 Todo — Débito técnico / Refatoração

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| — | — | — | — |

---

## 🟢 Todo — Features incompletas (produto)

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| — | — | — | — |

---

## 🔵 Review

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| — | — | — | — |

---

## 🔵 Doing

| ID | Tarefa | Agente | Responsável |
|----|--------|--------|------------|
| OPS-RAILWAY | Deploy Railway piloto (painel + smoke test) | DevOps / TL | Vinicius |

### OPS-RAILWAY — Deploy Railway (piloto)

**Status:** In Progress  
**Prioridade:** P0  
**Responsável:** Vinicius  
**Relacionado:** OPS-001 (CD), [GUIA_RAILWAY.md](docs/GUIA_RAILWAY.md)

#### Escopo
- [ ] Criar projeto Railway (`agentesia`)
- [ ] Plugin PostgreSQL 16
- [ ] Plugin Redis 7
- [ ] Serviço `api` — Dockerfile, release command `alembic upgrade head`, health `/health`
- [ ] Serviço `worker` — `Dockerfile.worker`, sem release command
- [ ] Serviço `frontend` — Static Site, `VITE_API_URL` em build time
- [ ] Env vars produção configuradas (sem secrets no repo)
- [ ] Stripe webhook endpoint criado (`/billing/webhook`)
- [ ] Smoke test: `/health/ready` OK, auth, agente, simulador, WhatsApp
- [ ] Domínios próprios (pós-piloto)

#### Artefatos (scaffold — Done)
- `saas-agentes-backend/railway.toml` (`9f9892d`)
- `saas-agentes-backend/Dockerfile.worker` (`9f9892d`)
- `ia-reply/railway.toml` (`6ddc3a8`)
- `.claude/squad/project/docs/GUIA_RAILWAY.md`

#### Notas
- `VITE_API_URL` é build-time — rebuild obrigatório se domínio da API mudar
- `DATABASE_URL` Railway precisa de sufixo `+asyncpg` / `+psycopg2` (manual)
- Variáveis Stripe: `STRIPE_PRICE_FREE`, `STRIPE_PRICE_STARTER`, `STRIPE_PRICE_PRO`
- `/health/ready` retorna HTTP 503 se DB ou Redis degradado

---

## ✅ Done

| ID | Tarefa | Concluído em |
|----|--------|-------------|
| — | Análise de arquitetura inicial (backend + frontend) | Kickoff |
| SEC-001 | SSRF `send_to_webhook` via `safe_post` (ADR-006) | 2026-06-01 — `3ffe037` |
| DEBT-011 | Anti DNS rebinding | 2026-06-01 — `3ffe037` |
| SEC-002 | Rate limit slowapi → Redis | 2026-06-01 — `dd5a7f2` |
| BUG-001 | Débito atômico de créditos | 2026-06-01 — `909904b` |
| BUG-002 | Commit antes de `send_text` | 2026-06-01 — `94bb43d` |
| SEC-003 | Evolution `safe_post` / `safe_get` | 2026-06-01 — `640aa0e` |
| SEC-004 | Reset-password token single-use + TTL | 2026-06-01 — `39798e1` |
| BUG-003 | Commit único via `get_db` (ADR-007) | 2026-06-01 — `eb3b355` |
| BUG-004 | Pool ARQ reutilizável | 2026-06-01 — `e9d8dd5` |
| BUG-005 | Bypass email dev sem Resend | 2026-06-01 — `568729d` |
| FEAT-001 | Rota `/reset-password` frontend | 2026-06-01 — frontend `4f8a0bf` |
| DEBT-009 | Configurações sem dados fake | 2026-06-01 — frontend `4f8a0bf` |
| BUG-006 | `DEFAULT_OPENAI_MODEL` unificado | 2026-06-01 — frontend `4f8a0bf` |
| BUG-007 | `useUsage` em `useBilling` | 2026-06-01 — frontend `4f8a0bf` |
| BUG-008 | Configurações sem tenant.id como API key | 2026-06-01 — frontend `4f8a0bf` |
| FEAT-020 | CI GitHub Actions (pytest unit) | 2026-06-01 — workflow `.github/workflows/ci.yml` |
| DEBT-001 | Services: connections, conversations, metrics, tenants | 2026-06-01 — backend `da9d0ee` |
| FEAT-012 | Limite de agentes por plano na criação | 2026-06-01 — backend `da9d0ee` |
| DEBT-014 | Toggle senha Login alinhado ao ResetPassword | 2026-06-01 — frontend `b4f7b2c` |
| FEAT-002 | Reenvio + confirmação de email | 2026-06-01 — backend `11c9880`, frontend Sprint 2 |
| DEBT-002 | AgentEditorPage modularizado | 2026-06-01 — hook + 6 componentes de aba |
| FEAT-011 | Onboarding condicional (skip se já há agentes) | 2026-06-01 — frontend `abe17c7` |
| FEAT-003 | Aba Multimodal no editor (`multimedia.image/document`) | 2026-06-01 — frontend `abe17c7` |
| FEAT-004 | Aba Áudio no editor (`multimedia.audio`) | 2026-06-01 — frontend `abe17c7` |
| FEAT-005 | Aba Follow-up (`followup_*` em multimedia + tool schedule_followup) | 2026-06-01 — frontend `abe17c7` |
| FEAT-006 | Histórico de versões (sheet + duplicar/restaurar rascunho) | 2026-06-01 — frontend `d2a6710` |
| FEAT-007 | Config de tools (`tool_config`, ex. send_to_webhook) | 2026-06-01 — frontend `d2a6710` |
| FEAT-008 | Toolbar do prompt (negrito/itálico/variável/templates) | 2026-06-01 — frontend `d2a6710` |
| FEAT-009 | Tool calls no simulador | 2026-06-01 — frontend `d2a6710`, backend `a6b0d24` |
| FEAT-010 | Tema escuro (ThemeProvider + toggle) | 2026-06-01 — frontend `d2a6710` |
| DEBT-003 | OnboardingWizard modularizado (hook + 4 steps + shell) | 2026-06-01 — frontend batch |
| DEBT-004 | Hooks dedicados; `useData` virou barrel de re-export | 2026-06-01 — frontend batch |
| FEAT-013 | Stripe Customer Portal (`POST /billing/portal`) | 2026-06-01 — backend + frontend batch |
| FEAT-016 | Allowlist OpenAI (`core/llm/allowed_models` + GET openai-models) | 2026-06-01 — backend + frontend batch |
| DEBT-005 | Toast legado removido (só Sonner) | 2026-06-01 — frontend batch hygiene |
| DEBT-006 | `NavLink.tsx` removido | 2026-06-01 — frontend batch hygiene |
| DEBT-007 | Primitivos shadcn não usados removidos (~24 arquivos) | 2026-06-01 — frontend batch hygiene |
| DEBT-008 | Gráficos/onboarding com tokens CSS (`chartTokens`) | 2026-06-01 — frontend batch hygiene |
| DEBT-010 | Python 3.12 + `.venv` único (`.python-version`, README) | 2026-06-01 — backend batch hygiene |
| FEAT-019 | Observabilidade: X-Request-ID, `/health/ready`, `/metrics` Prometheus | 2026-06-01 — backend batch hygiene |
| DEBT-012 | Migração `search_on_catalog` + sanitize em API/registry + front sem catálogo | 2026-06-01 — Sprint 3 |
| FEAT-017 | `core/storage/media.py` (R2/S3 boto3 upload/download/presign) | 2026-06-01 — Sprint 3 |
| FEAT-018 | Cron ARQ `cleanup_expired_tokens` (refresh/email/reset) | 2026-06-01 — Sprint 3 |
| FEAT-021 | README + `scripts/test_flow.py` alinhados a cookies httpOnly | 2026-06-01 — Sprint 3 |
| FEAT-020+ | CI: ruff (app/core/api/db) + pytest unit + integration | 2026-06-01 — Sprint 3 |
| DEV-LOCAL | SQLite dev (`init_sqlite_dev.py`) + CORS regex localhost/127.0.0.1 | 2026-06-01 — validação local |
| FEAT-014 | Runtime mídia inbound: parsers Z-API/Evolution, `media_input`, `media_metadata` | 2026-06-01 — Sprint 3 |
| DEBT-013 | WCAG badges: tokens `success-subtle` / `warning-subtle` + propagação no app | 2026-06-01 — pós Sprint 3 |
| FEAT-015 | LLM Anthropic + Groq no gateway (`/agents/llm-models/{provider}`) | 2026-06-01 — pós Sprint 3 |
| SEC-005 | Fix loop auth/refresh com cookies stale | 2026-06-23 — frontend `4a7feb2` |
| DEV-002 | arq_pool tolerante a Redis em `APP_ENV=development` | 2026-06-23 — backend `286df2d` |
| OPS-SCAFFOLD | Railway scaffold (Dockerfile 3.12, worker, railway.toml) | 2026-06-23 — backend `9f9892d`, frontend `6ddc3a8` |
| QUALITY-001 | Ruff 202 → 0 violações (escopo CI) | 2026-06-23 — backend `1229605` |
| QUALITY-002 | Bundle split, MetricasPage deps, notificações, `/forgot-password` | 2026-06-23 — frontend `4199467` |
| UX-001 | errorHandler: mensagem de erro correta do backend | 2026-06-23 — frontend `b881154` |
| UX-002 | Billing: preços corretos + Enterprise "Sob consulta" | 2026-06-23 — frontend `b881154` |
| UX-003 | OfflineBanner: feedback de rede offline | 2026-06-23 — frontend `b881154` |
| UX-004 | Landing hero: first paint visível (sem opacity-0) | 2026-06-23 — frontend `b881154` |
| UX-005 | Onboarding: não bloqueia UI durante wizard | 2026-06-23 — frontend `b881154` |
| UX-006 | Conexões: botão único de criação | 2026-06-23 — frontend `b881154` |
| UX-007 | Banner setup: condicional correto + dismiss | 2026-06-23 — frontend `b881154` |

---

## Fase A — concluída `2026-06-23`

- [x] SEC-005 — fix loop auth/refresh (frontend `4a7feb2`)
- [x] fix(DEV) — arq_pool tolerante a Redis em development (backend `286df2d`)
- [x] chore(deploy) — Dockerfile Python 3.12 + worker + railway.toml (backend `9f9892d`)
- [x] chore(deploy) — railway.toml + .env.example frontend (`6ddc3a8`)

## Fase B — concluída `2026-06-23`

- [x] chore(quality) — ruff 202 → 0 violações (backend `1229605`)
- [x] fix(quality) — switches notificações disabled + "Em breve" (frontend `4199467`)
- [x] fix(quality) — exhaustive-deps MetricasPage zerado (frontend `4199467`)
- [x] fix(quality) — bundle split manualChunks, maior chunk 411 kB (frontend `4199467`)
- [x] fix(quality) — /forgot-password página dedicada + rota GuestRoute (frontend `4199467`)

## Fase C — concluída `2026-06-23`

- [x] fix(UX) — errorHandler: hierarquia error.message → detail → fallback + "Sem conexão" (frontend `b881154`)
- [x] fix(UX) — Billing: preços alinhados ao backend (Free/Starter/Pro/Business/Enterprise "Sob consulta") (frontend `b881154`)
- [x] fix(UX) — OfflineBanner: banner fixo no topo ao detectar offline/online (frontend `b881154`)
- [x] fix(UX) — Landing hero: animação sem opacity-0, first paint visível (frontend `b881154`)
- [x] fix(UX) — Onboarding: overlay sem bloquear cliques (pointer-events-none) (frontend `b881154`)
- [x] fix(UX) — Conexões: botão único "+ Nova conexão" (frontend `b881154`)
- [x] fix(UX) — Banner setup: some após criar agente + botão Dispensar (frontend `b881154`)

---

## Priorização atual (pós Fase A+B+C)

**Em andamento:** OPS-RAILWAY — configurar painel Railway ([GUIA_RAILWAY.md](docs/GUIA_RAILWAY.md))

**Sprint 4 — após deploy Railway:**
1. OPS-001 — CD completo (staging → prod)
2. QA-001 — gate cobertura ≥80% / ≥95% críticos
3. FEAT-014b — mídia outbound (send_audio/send_image)
4. QA-002 — E2E Playwright (login → agente → simular)
5. OBS-001 — SLOs, alertas Prometheus, Grafana

**Débitos conhecidos (P1/P2):**
- request_id não propaga HTTP → worker (observabilidade)
- Créditos debitados antes de send_text (integridade financeira)
- Cobertura de testes: worker 46%, billing_service 41%, media_input 42%

**Histórico Sprint 1–3 + Fases A/B/C:** ver tabela Done acima.
