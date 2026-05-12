---
name: squad-prd-template
description: Conduz Product Owner na criação de PRD completo (objetivo, escopo, RNFs, critérios de aceite, riscos). Use quando há novo produto/feature a documentar antes de qualquer trabalho técnico.
---

# Skill — PRD Template

> **Owner:** Product Owner | **Revisão:** 90 dias | **Obsolescência:** template `.claude/squad/template/docs/PRD-template.md` removido ou substituído

Esta skill conduz o PO na criação de PRD completo seguindo o template oficial.

---

## Quando usar

- Início de Fluxo 1 (projeto novo)
- Nova feature significativa em projeto existente
- Refatoração com mudança de comportamento (Fluxo 4)
- Escopo dado pelo usuário ainda não está documentado

## Quando NÃO usar

- Bug fix simples (não precisa de PRD)
- Melhoria triada pelo Support Engineer (PO documenta com formato menor)
- PRD já existe e é só ajuste pequeno

---

## Estrutura do PRD (10 seções)

Conforme `.claude/squad/template/docs/PRD-template.md`:

1. **Objetivo** — o que e por que existe
2. **Usuário Alvo** — perfis, contexto, necessidade
3. **Escopo** — IN / OUT explícitos
4. **Requisitos Funcionais** — happy path, alternativos, regras de negócio, estados
5. **Requisitos Não-Funcionais** — performance, disponibilidade, volumetria, segurança, compliance, i18n, cobertura de testes
6. **Critérios de Aceite** — histórias de usuário com Dado/Quando/Então testáveis
7. **Métricas de Sucesso** — baseline + meta 30/90 dias
8. **Dependências** — externas, internas
9. **Riscos** — probabilidade × impacto × mitigação
10. **Histórico de Revisões**

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
3. Mapear conteúdo nas 10 seções do PRD:
   - O que já está coberto → estruturar
   - O que falta → marcar como gap
4. Listar gaps detectados ao usuário com prioridade:
   - **Críticos:** objetivo, escopo IN/OUT, RNFs em Production Mode, critérios de aceite
   - **Importantes:** métricas, dependências, riscos, idiomas
   - **Recomendados:** revisões, edge cases não cobertos
5. Fazer perguntas dirigidas **somente sobre lacunas** (não re-perguntar o que está claro)
6. Montar PRD completo combinando briefing original + respostas das lacunas
7. Apresentar ao usuário para validação (passo 6)

#### Modo 2 — Entrevista

1. Conduzir sequência de perguntas estruturadas (passos 1-5 desta skill — leia abaixo)
2. Construir PRD progressivamente conforme respostas
3. Confirmar com usuário a cada bloco antes de prosseguir
4. Apresentar PRD final para validação (passo 6)

#### Switch dinâmico (durante o processo)

Você pode propor mudança de modo a qualquer momento se detectar:

- **Briefing vago** → "Detectei lacunas em [X]. Posso te entrevistar nesses pontos específicos?"
- **Entrevista travada** → "Notei que você prefere escrever. Quer enviar o resto em texto livre que eu organizo?"

Hibridização é OK e recomendada quando o usuário tem partes claras e outras vagas.

---

### 1. Coletar contexto inicial (Modo Entrevista — passos 1-5)

> Em **Modo Briefing**, este passo é apenas para preencher lacunas. Em **Modo Entrevista**, faça todas as perguntas.

Pergunte ao usuário (em ordem):

- **Problema:** qual dor o produto/feature resolve?
- **Usuário alvo:** quem usa? Persona principal e secundárias?
- **Valor:** qual ganho mensurável?
- **Constraints:** prazo, orçamento, compliance, integrações obrigatórias?

### 2. Detectar modo do projeto

- **MVP Mode:** validação de hipótese, time-to-market crítico
- **Production Mode:** sistema com SLA, compliance obrigatório, alta volumetria

Modo afeta seções de RNF (cobertura, observabilidade, SLOs).

### 3. Conduzir cada seção

- Para cada seção, pergunte 1-3 questões direcionadas
- Não aceite "depois preencho" — RNFs especialmente são bloqueantes
- Se usuário não souber RNF (ex: throughput esperado), capture **estimativa + plano de validar**

### 4. RNFs obrigatórios em Production Mode

- Latência P50/P95/P99
- SLA de disponibilidade
- RTO/RPO
- Volumetria (usuários simultâneos, transações/dia)
- Classificação de dados (Público/Interno/Confidencial/Restrito)
- Compliance aplicável (LGPD/GDPR/PCI/HIPAA)
- Idiomas suportados

### 5. Critérios de aceite

Cada história deve ter critérios **testáveis**:

```
US-01 — [Nome]
Como [perfil], Quero [ação], Para [valor].

Critérios:
- [ ] CA-01: Dado X, quando Y, então Z (verificável)
- [ ] CA-02: Dado X, quando Y com erro, então W (cenário de erro)
- [ ] CA-03: [edge case]
```

Rejeitar critérios vagos ("Sistema deve ser rápido" → "P95 ≤ 500ms").

### 6. Apresentar e capturar feedback

- Mostrar PRD completo
- Pedir aprovação explícita do usuário
- Capturar ajustes
- Iterar até aprovação

### 7. Salvar e propagar

- Salvar em `.claude/squad/project/PRD.md`
- Registrar criação em `.claude/squad/project/DECISIONS_LOG.md`
- Notificar TL (PRD aprovado, prosseguir com plano)

---

## Anti-patterns (rejeitar)

- Critérios subjetivos ("intuitivo", "rápido", "fácil")
- RNFs ausentes em Production Mode
- Escopo aberto ("flexível conforme demanda")
- Descrição de UI em vez de comportamento
- Regras implícitas ("o usuário sabe que...")
- Métricas sem baseline ou meta

---

## Referências

- Template: `.claude/squad/template/docs/PRD-template.md`
- Regras do PO: `.claude/squad/template/agents/product-owner.md`
- Modos: `CLAUDE.md` → "MVP vs Production Mode"
