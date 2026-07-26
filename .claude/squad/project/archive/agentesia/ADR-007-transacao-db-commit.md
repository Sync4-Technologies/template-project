# ADR-007: Fronteira de transação DB (BUG-003)

**Status:** Aceito  
**Data:** 2026-06-01

## Contexto

`get_db()` faz `commit()` ao final de cada request HTTP. Services e routers também chamavam `commit()`, gerando transações duplicadas e risco de estado parcial se algo falhar após um commit intermediário.

## Decisão

| Caminho | Quem commita |
|---------|----------------|
| **HTTP (FastAPI)** | Somente `get_db()` ao fim do request |
| **Services em HTTP** | `flush()` quando precisar de ID; sem `commit()` |
| **Routers** | Sem `commit()` |
| **Worker ARQ** (`AsyncSessionLocal` sem `get_db`) | `AgentRuntime` e jobs com commits explícitos quando necessário |
| **Stripe webhook (`BillingService`)** | `commit()` apenas no handler de erro, para persistir `StripeEvent` failed após `rollback()` |

## Consequências

- Uma unidade de trabalho por request HTTP.
- Runtime mantém commit antes de `send_text` (BUG-002) no worker.
- Testes unitários que chamam services direto devem `await db.commit()` no teste (fora do `get_db`).
