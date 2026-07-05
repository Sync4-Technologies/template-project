# AI Stack Convention — Anthropic (Claude API)

> Consulted by the AI Engineer before ANY task that calls Claude. Same authority rules as other stack conventions.
> API surface drifts fast — when in doubt, verify against the live docs/Models API instead of trusting memory. Cached facts below: 2026-07.

## When to use this stack

- Product features powered by LLM (agents, copilots, classification, extraction, generation)
- Default provider per ADR-001 unless the project's ADR says otherwise

## SDKs (official only)

| Language | Package | Client |
|---|---|---|
| Python | `anthropic` | `anthropic.Anthropic()` / `AsyncAnthropic()` |
| TypeScript | `@anthropic-ai/sdk` | `new Anthropic()` |

Never call the REST API with hand-rolled `fetch`/`requests` when an official SDK exists. Never use OpenAI-compatible shims.

## Model selection

**Use ONLY exact model IDs — never invent or append date suffixes.** Verify live via `client.models.list()` / `client.models.retrieve(id)`.

| Model | ID | Use for | $/MTok in/out (cached 2026-06) |
|---|---|---|---|
| Claude Opus 4.8 | `claude-opus-4-8` | Default for agentic/complex work | $5 / $25 |
| Claude Sonnet 5 | `claude-sonnet-5` | High-volume production, near-Opus coding | $3 / $15 |
| Claude Haiku 4.5 | `claude-haiku-4-5` | Classification, routing, simple/latency-critical | $1 / $5 |
| Claude Fable 5 | `claude-fable-5` | Only when explicitly required (hardest long-horizon work; premium pricing, special API behavior — refusal fallbacks, always-on thinking) | $10 / $50 |

Route by task: expensive model for the core capability, Haiku for classification/pre-filtering around it. **Cost per interaction is an RNF** (PRD §5 Produto de IA) — model choice must be justified against it (ADR-006-arquitetura-ia).

## Request conventions (current API — training priors are stale)

- **Thinking:** `thinking: {type: "adaptive"}` on 4.6+ models. `budget_tokens` is REMOVED on Opus 4.7/4.8, Sonnet 5, Fable 5 (400). Control depth with `output_config: {effort: "low"|"medium"|"high"|"xhigh"|"max"}`.
- **Sampling:** `temperature`/`top_p`/`top_k` are REMOVED on Opus 4.7/4.8, Sonnet 5, Fable 5 (400). Steer with prompting.
- **No assistant prefill** on 4.6+ (400). Use structured outputs instead.
- **Streaming is the default** for anything that can produce long output (`max_tokens > ~16K` requires it — SDK HTTP timeouts). Use `messages.stream()` + `get_final_message()`/`finalMessage()`.
- **`max_tokens`:** ~16000 non-streaming, ~64000 streaming; only lower with a hard reason (classification ~256).

## Structured outputs (contract discipline applied to LLMs)

Every output consumed by code MUST be schema-validated — "tudo é contrato" applies to model output.

- Python: `client.messages.parse(..., output_format=PydanticModel)` → `response.parsed_output`
- TypeScript: `output_config: {format: zodOutputFormat(schema)}` via `messages.parse`
- Raw: `output_config: {format: {type: "json_schema", schema: {...}}}` (top-level `output_format` on `create()` is deprecated)
- Tools: `strict: true` on the TOOL definition (not on `tool_choice`) + `additionalProperties: false`

## Tool use

- Prefer the SDK **tool runner** (`@beta_tool` / `betaZodTool`) for standard loops; manual loop only when you need approval gates, custom logging, or conditional execution
- Tool descriptions are **prescriptive about WHEN to call** ("Call this when the user asks about current prices"), not just what it does
- Parallel tool results: ALL `tool_result` blocks in ONE user message
- Failed tool → `tool_result` with `is_error: true` (never drop it)
- Tools with side effects (send, pay, delete) → require confirmation or approval gate; LLM output is untrusted input to your tools (see security-engineer.md OWASP LLM checklist: excessive agency)

## Prompt caching (mandatory for repeated context)

Prefix match — any byte change invalidates everything after it. Render order: `tools` → `system` → `messages`.

- **Frozen system prompt**: no timestamps, UUIDs, user names, or conditional sections interpolated into `system`. Dynamic context goes late in `messages`
- Deterministic tool order (sort by name); never swap tools/model mid-conversation
- Breakpoint (`cache_control: {type: "ephemeral"}`) on the last stable block; max 4 per request
- **Verify**: `usage.cache_read_input_tokens` > 0 on repeated requests — zero means a silent invalidator (audit for `datetime.now()`, unsorted JSON, varying tool set)

## Cost & observability (RNF — not optional in Production Mode)

- Log per request: model, `usage.input_tokens`, `output_tokens`, `cache_read_input_tokens`, latency, feature tag → dashboard of cost per feature (devops-engineer.md)
- `count_tokens` endpoint for pre-flight estimates — NEVER tiktoken (wrong tokenizer, undercounts 15-20%+)
- Batches API for non-latency-sensitive volume (50% price)
- Budget alert per tenant/feature per PRD §5

## Error handling

- Catch typed exceptions most-specific-first: `RateLimitError` (429, honor `retry-after`) → `APIStatusError`/5xx (retry w/ backoff — SDK retries 2x by default) → `APIConnectionError`. Never string-match error messages
- Fallback determinístico when the provider is down (PRD §5): queue + retry, canned response, or degraded mode — never silent failure
- 4xx (except 429) = bug in the request — do not retry blindly

## Security

- API key via env/secret manager only; never in code, logs, or client bundles
- No PII in prompts logged verbatim — redact before persisting (LGPD)
- Model output rendered to users or passed to tools = untrusted (sanitize/validate before the sink)
- Full checklist: security-engineer.md → OWASP LLM Top 10

## Anti-patterns (block)

- Inventing/date-suffixing model IDs
- `budget_tokens`, sampling params, or prefill on 4.7+/Sonnet 5/Fable 5 code
- Parsing free-text model output with regex when structured outputs exist
- `tiktoken` for Claude token counts
- Retry loop hand-rolled around SDK (it already retries) without honoring `retry-after`
- Cache breakpoints on volatile content; timestamp in system prompt
- Feature de IA sem eval (see `evals.md` — "sem eval → feature de IA incompleta")
