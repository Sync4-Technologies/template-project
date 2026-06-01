# TASK_BOARD.md — AgentesIA

> Kanban da squad. Mover tarefas conforme progresso. Atualizar a cada sessão.

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
| DEBT-013 | Contraste de badges `text-success`/`text-warning` sobre `/10` < 4.5:1 (WCAG 1.4.3) — corrigir no DS e propagar | Product Designer + Frontend | Sistêmico/pré-existente; apontado no PD review do FEAT-001 |

---

## 🟢 Todo — Features incompletas (produto)

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| FEAT-015 | Providers LLM alternativos: implementar anthropic e/ou groq | Backend | Gateway preparado, apenas openai funciona |

---

## 🔵 Review

| ID | Tarefa | Agente | Observação |
|----|--------|--------|-----------|
| — | — | — | — |

---

## 🔵 Doing

| ID | Tarefa | Agente | Responsável |
|----|--------|--------|------------|
| — | — | — | — |

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

---

## Priorização sugerida para Sprint 1

**Concluído:** SEC-001…004, BUG-001…005

**Próximo:**
1. FEAT-020 (CI/CD) — desbloqueia gates de produção
2. Merge frontend `squad/frontend-fixes` (FEAT-001, DEBT-009, BUG-006/007/008)
3. DEBT-001 (extração services restantes)
4. FEAT-012 (limites de plano)
