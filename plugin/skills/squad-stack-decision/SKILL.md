---
name: squad-stack-decision
description: Conduz Architect na decisão de stack do projeto, consultando stack-conventions e apresentando 2-3 opções com trade-offs. Use quando início de projeto novo ou mudança de stack.
---

# Skill — Stack Decision

Conduz o Architect na decisão de stack do projeto. Autoridade, processo e regra de conflito: `${CLAUDE_PLUGIN_ROOT}/template/agents/architect.md` → "Decisão de Stack" — esta skill estrutura a condução; o spec é a fonte.

## Quando usar

- Início de projeto novo (Fluxo 1 ou 2)
- Migração de stack em projeto existente (decisão grande)
- Avaliação de adicionar nova camada (ex: adicionar mobile a projeto web)

## Quando NÃO usar

- Atualização menor de versão de framework · lib pontual · customização local de tooling — não é decisão de stack

---

## Sua tarefa como Claude (atuando como Architect)

### 1. Coletar input do PRD

- **PRD** — RNFs (performance, disponibilidade, volumetria, compliance, idiomas)
- **Contexto da squad** — expertise do time (TL informa)
- **Restrições operacionais** — infra existente, integrações obrigatórias
- **Modo do projeto** — MVP ou Production (afeta tolerância a complexidade)

### 2. Identificar camadas necessárias

Backend? (quase sempre) · Frontend web? (há UI no browser?) · Mobile? (app iOS/Android?) · AI? (agentes, prompts, LLM?) · Data? (pipelines, DW, ML data prep?)

### 3. Consultar stack-conventions por camada

Índice das stacks suportadas, com critério primário e path de cada documento: `${CLAUDE_PLUGIN_ROOT}/template/docs/stack-conventions/README.md`. Para cada candidata, ler as seções **"Quando usar"** e **"Quando NÃO usar"** do documento da stack.

### 4. Avaliar contra critérios do projeto

Matriz de decisão (score por opção, com peso): aderência a NFRs (alto) · expertise do time (alto) · compliance suportado (alto) · maturidade da stack (médio) · custo operacional (médio) · ecossistema de libs (médio) · time-to-market (médio).

### 5. Avaliar fornecedores externos (se aplicável)

Critérios (custo, lock-in, SLA, fallback, compliance, maturidade): architect.md → "Avaliação de Fornecedores Externos" — avaliação documentada + fallback definido + ADR.

### 6. Apresentar 2-3 opções ao Tech Lead

Esqueleto:

```
STACK DECISION PROPOSAL — [Camada] — YYYY-MM-DD
Contexto: modo · NFRs relevantes · expertise do time
Por opção (2-3, uma RECOMENDADA):
  stack convention (path) · quando usar (do convention) · prós/contras ·
  aderência aos critérios (score) · eixos de produto (1 linha por eixo onde a opção
  diverge — qualidade/simplicidade/facilidade/escalabilidade/resiliência/expansibilidade;
  simplicidade tem peso igual a escalabilidade)
Recomendação técnica: Opção [N] — motivo (2-3 linhas)
```

### 7. Tech Lead revisa contexto operacional

Pipeline existente suporta? Infra compatível? Time tem capacidade real (não só "já viu")? Prazo permite curva de aprendizado se stack nova?

### 8. Conflito Architect × Tech Lead

TL pode pedir revisão de trade-offs ou opções adicionais; **não pode** sobrescrever sua decisão técnica unilateralmente. Divergência persistindo → escalar ao usuário (regra completa no spec).

### 9. Apresentar ao usuário (TL conduz)

TL apresenta opções + recomendação. Usuário aprova/ajusta/veta — **toda decisão de stack vai ao usuário**.

### 10. Registrar decisão

Criar `.claude/squad/project/ADR/ADR-NNN-stack-projeto.md` a partir de `${CLAUDE_PLUGIN_ROOT}/template/memory/ADR/ADR-template.md` — incluir alternativas consideradas (com motivo de rejeição), trade-offs e critérios de revisão.

### 11. Atualizar ARCHITECTURE.md

`.claude/squad/project/ARCHITECTURE.md` → seção "Stack Tecnológica" (tecnologia + versão, link para ADR e para a convention) e seção "Stack Conventions Doc" (spec ativa).

---

## Anti-patterns (rejeitar)

- Escolher stack pela "novidade" sem avaliar maturidade · CV-driven development (dev quer aprender)
- Stack hardcoded em código de agentes (deve estar em ADR + ARCHITECTURE.md)

---

- **Owner:** Architect
- **Fonte:** `${CLAUDE_PLUGIN_ROOT}/template/agents/architect.md` → "Decisão de Stack" e "Avaliação de Fornecedores Externos" · `${CLAUDE_PLUGIN_ROOT}/template/docs/stack-conventions/README.md` · ADR-001 (opções padrão)
