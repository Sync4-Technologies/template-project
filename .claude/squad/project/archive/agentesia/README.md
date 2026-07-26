# Archive — Produto AgentesIA

> Artefatos do produto AgentesIA (SaaS multi-tenant de agentes IA + WhatsApp), arquivados em 2026-07-26.

## Por que arquivado

Este repositório nasceu como projeto AgentesIA e foi progressivamente convertido em **upstream do plugin dev-squad** (a partir de 2026-07-05, migração D1). O código do produto (`saas-agentes-backend`, `ia-reply`) nunca viveu neste repo — os artefatos de squad aqui referenciavam repositórios externos.

Em 2026-07-26 o usuário confirmou: propósito deste repo é **manter e evoluir o plugin dev-squad**. Board, arquitetura, ADRs e docs do produto foram movidos para cá para preservar histórico sem poluir a governança ativa.

## Conteúdo

| Arquivo | O que era |
|---------|-----------|
| `TASK_BOARD.md` | Kanban completo do AgentesIA (Sprint 1–3, Fases A/B/C, OPS-RAILWAY em Doing) |
| `ARCHITECTURE.md` | Arquitetura FastAPI + React + PostgreSQL + Redis/arq do produto |
| `DECISIONS_LOG.md` | Decisões do produto + Session Log completo (inclui sessões de sistema até v1.8.0) |
| `ADR-006` / `ADR-007` | Egress HTTP seguro (SSRF) / estratégia de commit DB |
| `DIAGNOSTICO_RAILWAY.md`, `RESUMO_FINAL.md`, `docs/` | Deploy Railway (OPS-RAILWAY), runtime de mídia, relatório UX |

## Se o produto for retomado

Retomar em repositório próprio com `/squad-init` e copiar estes artefatos para a nova estrutura `.claude/squad/project/`.
