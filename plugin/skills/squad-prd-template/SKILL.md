---
name: squad-prd-template
description: Conduz Product Owner na criação de PRD completo (objetivo, escopo, RNFs, critérios de aceite, riscos). Use quando há novo produto/feature a documentar antes de qualquer trabalho técnico.
---

# Skill — PRD Template

Conduz o PO na criação de PRD completo. Estrutura autoritativa (11 seções): `${CLAUDE_PLUGIN_ROOT}/template/docs/PRD-template.md` — ler o template antes de conduzir; papel e regras do PO: `${CLAUDE_PLUGIN_ROOT}/template/agents/product-owner.md`.

**Regra de IA (sempre):** primeira pergunta do PO — **"qual o papel da IA neste produto?"** (núcleo / acessória / ausente). Papel núcleo torna a seção 5 do PRD (Produto de IA: modelo/provider, custo por interação, latência de inferência, dados/PII no contexto, evals, guardrails) obrigatória e bloqueante.

## Quando usar

- Início de Fluxo 1 (projeto novo) · nova feature significativa · refatoração com mudança de comportamento (Fluxo 4) · escopo dado pelo usuário ainda não documentado

## Quando NÃO usar

- Bug fix simples · melhoria triada pelo Support Engineer (PO documenta com formato menor) · PRD já existe e é só ajuste pequeno

---

## Sua tarefa como Claude (atuando como PO)

### 0. Escolher modo de criação (sempre o primeiro passo)

Antes de qualquer outra ação, **pergunte ao usuário** como prefere construir o PRD:

> "Para construirmos o PRD, você tem duas opções:
>
> **1️⃣ Modo Briefing** — você me apresenta um briefing já estruturado (texto livre, documento, notas) e eu transformo no PRD completo, fazendo perguntas apenas sobre lacunas detectadas.
>
> **2️⃣ Modo Entrevista** — eu conduzo uma entrevista estruturada passo a passo, e construímos o PRD juntos a partir do zero.
>
> Qual prefere? (1 ou 2)"

#### Modo 1 — Briefing

1. Aguardar usuário entregar briefing (cola texto ou aponta arquivo)
2. Ler briefing **completo** antes de qualquer pergunta
3. Mapear conteúdo nas 11 seções do template: o que está coberto → estruturar; o que falta → gap
4. Listar gaps ao usuário com prioridade — **críticos:** objetivo, escopo IN/OUT, RNFs em Production Mode, critérios de aceite · **importantes:** métricas, dependências, riscos, idiomas · **recomendados:** revisões, edge cases
5. Fazer perguntas dirigidas **somente sobre lacunas** (não re-perguntar o que está claro)
6. Montar PRD completo combinando briefing + respostas
7. Apresentar para validação (passo 6)

#### Modo 2 — Entrevista

1. Conduzir perguntas estruturadas (passos 1-5 abaixo)
2. Construir PRD progressivamente, confirmando com usuário a cada bloco
3. Apresentar PRD final para validação (passo 6)

#### Switch dinâmico

- **Briefing vago** → "Detectei lacunas em [X]. Posso te entrevistar nesses pontos específicos?"
- **Entrevista travada** → "Notei que você prefere escrever. Quer enviar o resto em texto livre que eu organizo?"

Hibridização é OK e recomendada quando o usuário tem partes claras e outras vagas.

### 1. Coletar contexto inicial

> Em Modo Briefing, apenas para preencher lacunas; em Modo Entrevista, todas as perguntas.

- **Problema:** qual dor o produto/feature resolve?
- **Usuário alvo:** quem usa? Persona principal e secundárias?
- **Valor:** qual ganho mensurável?
- **Constraints:** prazo, orçamento, compliance, integrações obrigatórias?

### 2. Detectar modo do projeto

**MVP** (validação de hipótese, time-to-market crítico) ou **Production** (SLA, compliance obrigatório, alta volumetria) — afeta as seções de RNF (cobertura, observabilidade, SLOs).

### 3. Conduzir cada seção

- 1-3 questões direcionadas por seção do template
- Não aceitar "depois preencho" — RNFs especialmente são bloqueantes
- Usuário não sabe um RNF (ex: throughput)? Capturar **estimativa + plano de validar**

### 4. RNFs obrigatórios em Production Mode

Lista completa e valores esperados: product-owner.md → "Requisitos Não-Funcionais (RNF)" — cobrar cada item (latência, SLA, RTO/RPO, volumetria, classificação de dados, compliance, idiomas); nenhum pode ficar em aberto.

### 5. Critérios de aceite

Cada história com critérios **testáveis**:

```
US-01 — [Nome]
Como [perfil], Quero [ação], Para [valor].
- [ ] CA-01: Dado X, quando Y, então Z (verificável)
- [ ] CA-02: [cenário de erro]  ·  CA-03: [edge case]
```

Rejeitar critérios vagos ("Sistema deve ser rápido" → "P95 ≤ 500ms").

### 6. Apresentar e capturar feedback

Mostrar PRD completo · pedir aprovação explícita · capturar ajustes · iterar até aprovação.

### 7. Salvar e propagar

Salvar em `.claude/squad/project/PRD.md` · registrar em `.claude/squad/project/DECISIONS_LOG.md` · notificar TL (PRD aprovado, prosseguir com plano).

---

## Anti-patterns (rejeitar)

- Critérios subjetivos ("intuitivo", "rápido", "fácil") · métricas sem baseline ou meta
- Escopo aberto ("flexível conforme demanda") · regras implícitas ("o usuário sabe que...")
- Descrição de UI em vez de comportamento

---

- **Owner:** Product Owner
- **Fonte:** `${CLAUDE_PLUGIN_ROOT}/template/docs/PRD-template.md` (estrutura) · `${CLAUDE_PLUGIN_ROOT}/template/agents/product-owner.md` (RNFs, gate de aprovação)
