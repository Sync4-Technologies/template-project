# DECISIONS_LOG.md — AgentesIA

> Decisões rápidas (linha por linha). Decisões pesadas viram ADR.
> Formato: [DATA] [AGENTE] DECISÃO | MOTIVO

---

## Decisões existentes (identificadas na análise inicial)

[2025-Q1] [Architect] Auth por cookie httpOnly, não Bearer no cliente | Segurança: tokens inacessíveis ao JS, proteção contra XSS
[2025-Q1] [Architect] Multi-tenant shared-schema com tenant_id manual | Simplicidade de MVP; sem RLS por ora
[2025-Q1] [Architect] Fila arq/Redis para desacoplar webhook do runtime | Webhook retorna 200 imediatamente; runtime pode ser lento
[2025-Q1] [Architect] Plugin registry auto-discovery para tools | Permite adicionar tools sem modificar o gateway
[2025-Q1] [Architect] Dedup de webhooks por Redis SETNX TTL 5min | Garante idempotência sem tabela dedicada
[2025-Q1] [Architect] Refresh tokens opacos com rotação (hash sha256 no DB) | Sem exposição do token real; rotação invalida roubo
[2025-Q1] [Architect] Fernet para criptografar credenciais WhatsApp no DB | Tokens de provedor nunca em plaintext
[2025-Q1] [Architect] Stripe com tabela stripe_events para idempotência | Webhooks Stripe podem repetir — dedup obrigatório
[2025-Q1] [Architect] TanStack Query como estado de servidor no frontend | Cache, refetch, mutations padronizados; sem Redux
[2025-Q1] [Architect] shadcn/ui + Tailwind como design system base | Radix acessível + composição flexível
[2025-Q1] [Frontend] Polling configurado por recurso (conexões 30s, conversas 15s, msgs 5s) | refetchIntervalInBackground:false para reduzir custo
[2025-Q1] [Frontend] staleTime:Infinity em dados imutáveis (tools, plans, packages) | Evita refetches desnecessários
[2025-Q1] [Frontend] Erro 5xx/rede preserva sessão (não desloga) | UX deliberada: instabilidade não expulsa o usuário
[2025-Q1] [Frontend] open-redirect guard no login: valida path antes de redirecionar | Segurança: location.state.from não confiável cegamente
[2025-Q1] [Frontend] usePatchAgent lê nome do cache RQ ao pausar/ativar | Workaround: backend exige name no PATCH mesmo para is_active

---

[2026-06-01] [Backend] DEBT-012: `search_on_catalog` removida via migração 0008 + `sanitize_tool_names` | Tool saiu do registry; agentes antigos não quebram em silêncio
[2026-06-01] [Architect] FEAT-014: desenho em `docs/FEAT-014-runtime-media.md` antes de código | Parsers → media_input → runtime; depende de FEAT-017 para persistência
[2026-06-01] [Backend] FEAT-017: `MediaStorage` boto3 S3-compat (R2) | upload_bytes, presigned_get, delete; falha explícita se não configurado
[2026-06-01] [Backend] FEAT-018: cron ARQ 03:00 `cleanup_expired_tokens` | refresh revogados/expirados; email/reset usados ou expirados
[2026-06-01] [DevOps] CI: ruff em app/api/core/db + pytest unit + integration | Gates ampliados sem lintar legado inteiro de uma vez
[2026-06-01] [Backend] CORS dev: regex `localhost|127.0.0.1` qualquer porta | Vite 8080 e cadastro local validados
[2026-06-01] [Backend] FEAT-014: Whisper + vision OpenAI; download via safe_get; early_reply se multimedia off | Doc FEAT-014-runtime-media.md; migração 0009

## Decisões da squad (a partir do kickoff)

[KICKOFF] [Tech Lead] Adotar este template de squad no AgentesIA | Governança, qualidade e memória do projeto
[KICKOFF] [Tech Lead] Priorizar SEC-001 (SSRF send_to_webhook) no Sprint 1 | Vetor de segurança real em produção
[KICKOFF] [Tech Lead] Priorizar BUG-001/002 (créditos + ordem commit) no Sprint 1 | Risco de integridade financeira e reenvio
[KICKOFF] [Tech Lead] Manter openai como único provider por ora | anthropic/groq causam ValueError — não anunciar sem implementar

---

## Decisões resolvidas no kickoff (pelo usuário)

[2026-06-01] [Usuário] Modo de operação: **Production Mode** | Cobertura ≥80% geral / ≥95% críticas; observabilidade completa; SE obrigatório em features críticas
[2026-06-01] [Usuário] FEAT-015 providers LLM: **manter só openai por ora** | anthropic/groq não anunciados sem implementar
[2026-06-01] [Usuário] BUG-003 estratégia de commit: **Architect decide via ADR** | BUG-003 bloqueado até o ADR sair
[2026-06-01] [Usuário] DEBT-010 runtime Python: **adiado** | checar compatibilidade de libs antes de escolher 3.11 vs 3.12

## Session Log

[2026-06-01] [Tech Lead] Onboarding da squad no AgentesIA + cópia dos artefatos para .claude/squad/project/; CLAUDE.md raiz substituído (MVP→Production)
[2026-06-01] [Architect+Security] ADR-006: egress HTTP seguro (SSRF + pin de IP anti-rebinding) — fecha SEC-001 e DEBT-011
[2026-06-01] [Backend+QA] SEC-001 + DEBT-011 implementados: `safe_post` em core/safe_http.py, `send_to_webhook` validado, `resolve_validated_url` com pin de IP. 30 testes verdes; ruff+mypy OK nos arquivos tocados. Aguardando Code Review + CI (FEAT-020).
[2026-06-01] [Tech Lead] Identificada superfície residual de rebinding no adapter Evolution → novo card SEC-003 no TASK_BOARD
[2026-06-01] [Frontend] Lote frontend entregue: DEBT-009, FEAT-001, BUG-006/007/008. tsc + eslint + vite build + vitest verdes. Aguardando Code Review.
[2026-06-01] [Frontend] BUG-006: `src/lib/models.ts` como fonte única de `DEFAULT_OPENAI_MODEL` (gpt-4.1-mini) | Editor e OnboardingWizard divergiam
[2026-06-01] [Frontend] BUG-007: `useBilling` é a fonte canônica de `useUsage`; shim em `useData` removido | Regra: hooks importados do arquivo dedicado
[2026-06-01] [Frontend] BUG-008/DEBT-009: removidos dados enganosos (tenant.id como API key, sessões e webhooks fake) → empty states honestos | Integridade do que é mostrado como real
[2026-06-01] [Frontend] FEAT-001: `/reset-password` como GuestRoute, contrato backend `{token, new_password}` (min 8) | Fluxo de recuperação estava quebrado
[2026-06-01] [Code Reviewer] Lote frontend **APROVADO**; 2 nits: dead `navigate` (corrigido) + token-na-URL para Security validar (→ SEC-004)
[2026-06-01] [Product Designer] Lote frontend: ajustes incorporados em ResetPassword (toggle ≥40px + focus-ring); contraste de badges é sistêmico do DS → DEBT-013; uniformizar Login → DEBT-014
[2026-06-01] [Tech Lead] Commits bloqueados: repos com WIP não-commitado entrelaçado ao lote desta sessão | Aguardando usuário commitar WIP primeiro (decisão: feature branch + push/PR para meu lote por cima)
[2026-06-01] [Tech Lead] Frontend: checkpoint WIP commitado na main (010394d, reverti meus hunks via match exato); lote isolado em squad/frontend-fixes (4f8a0bf) — pushed. Compare: /compare/main...squad/frontend-fixes
[2026-06-01] [Tech Lead] Backend: split limpo do meu lado era inseguro (refatorei o validate_external_url do WIP, sem o original exato). Usuário commitou o WIP (276a18c); meu lote isolado em squad/sec-egress-ssrf (c7736eb) por cima — pushed. ruff+mypy+pytest(30) verdes. Compare: /compare/main...squad/sec-egress-ssrf
[2026-06-01] [Tech Lead] Nota: base 276a18c ficou quebrada (connections/router importa validate_external_url, revertido ao scaffold); branch squad/sec-egress-ssrf restaura a função e conserta o import
[2026-06-01] [Usuário] Merge PR SEC-001/DEBT-011 na main backend (`3ffe037`) — cards fechados
[2026-06-01] [Backend] SEC-002: slowapi `storage_uri` → `redis_url` (limits RedisStorage), `key_prefix=agentesia`; testes com `memory://` no conftest; branch `squad/sec-002-rate-limit-redis` pushed
[2026-06-01] [Usuário] Merge SEC-002 na main backend (`dd5a7f2`)
[2026-06-01] [Backend] BUG-001: `debit_credits()` com UPDATE atômico (`CASE` clamp 0); `AgentRuntime` deixa de fazer read-then-write; teste concorrente (3× débito → saldo 1)
[2026-06-01] [Usuário] Merge BUG-001 na main backend (`909904b`)
[2026-06-01] [Backend] BUG-002: `AgentRuntime` persiste assistant + commit antes de `send_text`; retry reenvia via `_pending_committed_reply` sem novo LLM
[2026-06-01] [Usuário] Merge BUG-002 na main backend (`94bb43d`)
[2026-06-01] [Security+Backend] SEC-003: `EvolutionAdapter` usa `safe_post`/`safe_get` em todas as chamadas HTTP; `safe_get` adicionado em core/safe_http.py (ADR-006)
[2026-06-01] [Usuário] Merge SEC-003 na main backend (`640aa0e`)
[2026-06-01] [Security+Backend] SEC-004: reset-password com `UPDATE … RETURNING` (single-use atômico), TTL via `password_reset_token_expire_minutes`, invalida tokens anteriores no forgot, revoga refresh tokens no reset
[2026-06-01] [Usuário] Autonomia total: branch → implement → merge sem consulta; reportar resumo por lote
[2026-06-01] [Architect] ADR-007: commit só em `get_db` (HTTP); worker/runtime mantém commits explícitos
[2026-06-01] [Backend] BUG-003 merge main `eb3b355`
[2026-06-01] [Backend] BUG-004 pool ARQ compartilhado merge main `e9d8dd5`
[2026-06-01] [Backend] BUG-005 dev sem Resend: auto `email_verified` + log com link merge main `568729d`
[2026-06-01] [Backend] DEBT-001: `ConnectionService`, `ConversationService`, `MetricsService`, `TenantService`; routers finos
[2026-06-01] [Backend] FEAT-012: `plan_limits.assert_can_create_agent` + plano `free` em PLANS; HTTP 403 `plan_agent_limit`
[2026-06-01] [Backend] Teste flaky worker: `AsyncSessionLocal` aponta para engine de teste (mesmo DB in-memory)
[2026-06-01] [Frontend] DEBT-014: toggle senha Login com área 40px + focus-ring (paridade ResetPassword)
[2026-06-01] [Sprint 2] FEAT-002: POST /auth/resend-confirmation; GET /tenants/me com require_active_tenant; UI ConfirmEmail + VerifyEmailGate
[2026-06-01] [Sprint 2] DEBT-002: AgentEditorPage → useAgentEditorForm + tabs (Prompt/Tools/Simulator) + constants
[2026-06-01] [Frontend] FEAT-011: onboarding só se `useAgents().length === 0` e sem flag localStorage
[2026-06-01] [Frontend] FEAT-003/004/005: `multimedia` JSON (image/audio/document + followup_*) persistido via PUT versão; payload usa `tool_config` (API)
[2026-06-01] [Frontend] Follow-up UI liga `schedule_followup` na lista de tools ao ativar follow-up
[2026-06-01] [Frontend] FEAT-006: restaurar versão = POST duplicate + editar novo rascunho (não editar published in-place)
[2026-06-01] [Frontend] FEAT-007: `config_fields` da API → dialog; estado `tool_config` no form (não só cache da versão)
[2026-06-01] [Backend] FEAT-009: `SimulateResponse.tool_calls` com name/arguments/result por iteração do runtime
[2026-06-01] [Frontend] DEBT-003: onboarding em `components/onboarding/` (hook + steps); `OnboardingWizard` só orquestra
[2026-06-01] [Frontend] DEBT-004: implementação em `useConnections`, `useConversations`, `useMetrics`, `useTools`, `useTenant`; `useData` deprecated barrel
[2026-06-01] [Backend] FEAT-013: `POST /billing/portal` → Stripe Billing Portal Session; cria customer se ausente
[2026-06-01] [Backend] FEAT-016: allowlist em `core/llm/allowed_models.py`; exposta em `GET /agents/openai-models`
[2026-06-01] [Frontend] DEBT-005/007: apenas Sonner; removidos toast shadcn e componentes ui órfãos
[2026-06-01] [Frontend] DEBT-008: `lib/chartTokens.ts` lê variáveis CSS para Recharts
[2026-06-01] [Backend] DEBT-010: Python 3.12 canônico; `.venv312` obsoleto (gitignore `.venv*/`)
[2026-06-01] [Backend] FEAT-019: `RequestContextMiddleware`, `/health/ready`, `/metrics` (prometheus-client)
[2026-06-01] [Backend] DEBT-011 já entregue em SEC-001/ADR-006 (`safe_http` + IP pinado); revalidado nos testes de segurança

## Decisões pendentes (aguardando aprovação do usuário)

[ ] DEBT-010: confirmar runtime Python (3.11 vs 3.12) após checagem de libs
[ ] BUG-003: aguardando ADR de estratégia de commit (Architect)
