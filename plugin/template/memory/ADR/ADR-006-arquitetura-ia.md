# ADR-006 — Arquitetura de Features de IA (default do template)

**Status:** Aceita
**Data:** 2026-07-05
**Autor:** Architect

---

## Contexto

Novos projetos da squad têm IA no centro do produto. Sem um default arquitetural, cada feature de IA re-decide do zero: qual padrão de acesso a conhecimento, single-call ou agentic, qual modelo, como falhar com segurança. Lições de projeto real mostraram que decisões de IA tomadas ad hoc geram custo imprevisível, guardrails documentados-mas-não-implementados e features não-avaliáveis.

Este ADR define os defaults. O Architect valida cada feature de IA contra ele (e registra desvios em ADR do projeto).

---

## Decisão

### 1. Escada de complexidade — começar no degrau mais baixo (simplicidade é eixo de produto)

| Degrau | Quando | Custo/risco |
|---|---|---|
| **1. Single-call** (prompt + structured output) | Classificação, extração, geração pontual | Menor. Default absoluto |
| **2. Single-call + contexto direto** (docs no prompt + cache) | Corpus pequeno/estável que cabe no contexto | Baixo — prompt caching torna barato |
| **3. Tool use** (modelo decide buscar/agir) | Precisa de dados dinâmicos ou ações | Médio — cada tool é superfície de ataque (OWASP LLM) |
| **4. RAG** (pipeline de retrieval próprio) | Corpus grande/dinâmico/multi-tenant citável | Médio-alto — ver `stack-conventions/ai/rag.md` |
| **5. Agentic** (loop multi-step autônomo) | Tarefa aberta, multi-etapa, que justifica autonomia | Alto — só com justificativa explícita no design |

Subir um degrau exige justificativa registrada. "Agentic por default" é over-engineering.

### 2. Fine-tuning: exceção, não caminho

Fine-tune só para estilo/formato consistente em altíssimo volume — nunca para injetar conhecimento (RAG/contexto resolve, atualizável sem re-treino). Exige ADR próprio do projeto.

### 3. Escolha de modelo = capability × custo × latência (por caso de uso)

- Roteamento por tarefa: modelo forte no núcleo, modelo rápido/barato (Haiku-tier) em classificação/roteamento/pré-filtro
- Custo por interação é RNF do PRD §5 — a escolha deve caber nele
- IDs/preços atuais: `stack-conventions/ai/anthropic.md` (nunca de memória)

### 4. Guardrails e falha segura (por design, não por revisão)

- Fallback determinístico definido NO DESIGN: provider fora / timeout / refusal → fila+retry, resposta padrão ou modo degradado — nunca silêncio, nunca 500 cru
- Kill-switch: feature de IA crítica atrás de flag (ADR-003)
- Guardrails do PRD §5 ("o agente NUNCA...") implementados como código/eval adversarial — comentário não é enforcement (lição AM-20/AM-23)
- Output do modelo validado por schema antes de qualquer uso por código

### 5. Avaliação embutida

Toda feature de IA nasce com golden set + critérios de aprovação (PRD §5) e eval de regressão no fluxo (`stack-conventions/ai/evals.md`). Sem eval → incompleta.

---

## Consequências

**Positivas:** decisões de IA comparáveis entre features; custo previsível; simplicidade defensável contra hype ("precisa mesmo de agente?"); segurança e avaliação desde o design.

**Negativas / trade-offs:** degrau 1-2 pode exigir refactor quando o caso de uso crescer (aceito — YAGNI: refactor com evidência é mais barato que complexidade especulativa); roteamento multi-modelo adiciona uma decisão por feature.

**Revisão:** quando o provider/API mudar de forma estrutural, ou quando ≥2 features do projeto precisarem desviar do mesmo default (sinal de que o default está errado).
