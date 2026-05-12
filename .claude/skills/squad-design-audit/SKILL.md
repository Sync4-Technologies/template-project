---
name: squad-design-audit
description: Conduz Product Designer em audit periódico de consistência visual em produto maduro. Compara telas atuais com docs do DS, identifica drift e propõe priorização. Use trimestralmente em produtos com >6 meses em produção.
---

# Skill — Design Audit (Drift Detection)

> **Owner:** Product Designer | **Revisão:** 90 dias | **Obsolescência:** processo de audit mudar significativamente

Conduz o PD em audit periódico de consistência visual de um produto.

---

## Quando usar

- Cadência sugerida: **trimestral** em produtos maduros (>6 meses em produção)
- Quando TL detectar reclamações de inconsistência visual
- Antes de release significativa (limpar drift acumulado)
- Após período de alta velocidade (muitas features visuais em pouco tempo)

## Quando NÃO usar

- Produto novo (sem histórico para auditar)
- Sem `.claude/squad/project/design-system/` populado → use `/squad-design-extract` primeiro
- Decisão pontual sobre componente → não exige audit

---

## Sua tarefa como Claude (atuando como Product Designer)

### 1. Coletar baseline

#### Identificar Path do projeto (Externo vs Inline)

Ler `.claude/squad/project/design-system/source.md`:
- Se existe → **Path 1 (Externo)**: baseline é o repo externo na version pinned
- Se não existe → **Path 2 (Inline)**: baseline é o próprio `.claude/squad/project/design-system/`

#### Para Path 1 (Externo)

- **Baseline:** repo externo na version pinned em `source.md` (clonar/checkout para inspeção)
- **Overrides locais:** `tokens-override.md`, `components-custom/`, `patterns-custom/`
- **Codebase:** theme files, design tokens em código, componentes implementados
- **Telas em produção:** lista priorizada pelo TL/PO (foco em fluxos críticos)
- **Issues visuais reportadas:** issues no tracker com label `visual` / `ui` / `design-debt`

#### Para Path 2 (Inline)

- **DS docs:** `.claude/squad/project/design-system/` (estado atual da documentação)
- **Codebase:** theme files, design tokens em código, componentes implementados
- **Telas em produção:** lista priorizada pelo TL/PO (foco em fluxos críticos)
- **Issues visuais reportadas:** issues no tracker com label `visual` / `ui` / `design-debt`

### 2. Inspeção por categoria

#### Tokens em uso

- Comparar tokens declarados em `.claude/squad/project/design-system/tokens/` com tokens efetivamente usados no código
- Detectar:
  - **Tokens documentados mas não usados** — candidatos a remoção
  - **Valores hardcoded** que deveriam ser tokens — drift
  - **Tokens "fantasma"** usados no código mas não documentados — drift

#### Componentes

Comparar specs em `.claude/squad/project/design-system/components/` com implementações:

- Estados faltando (componente documenta hover mas implementação não tem)
- Variantes não documentadas (implementação tem variante "compact" não documentada)
- Drift de propriedades (padding, altura, border-radius diferentes da spec)

#### Patterns

- Empty states uniformes entre telas?
- Error handling consistente?
- Loading skeleton vs spinner usado de forma coerente?
- Navegação respeita pattern documentado?

#### Acessibilidade

- Contraste em texto secundário ainda OK?
- Focus visível em todos os componentes interativos?
- Tap targets respeitados em mobile?
- Suporte a `prefers-reduced-motion` implementado em animações novas?

#### Telas similares com look diferente

Detectar inconsistências entre telas que deveriam ser similares:

- Lista de pedidos vs lista de produtos — usam mesmo pattern de Card?
- Modal de confirmação vs modal de input — mesmo header style?
- Form de cadastro vs form de edição — mesmo layout?

#### Drift entre Override Local e Baseline Externo (Path 1 apenas)

Aplicável só quando `source.md` existe:

- **Overrides obsoletos:** override existe localmente mas baseline (repo externo na version pinned) já tem o mesmo valor → remover override
- **Overrides candidatos a promoção:** override resolve problema que outros projetos da squad teriam — documentar em `source.md` → "Override → contribuição central"
- **Drift de version:** repo externo lançou nova version desde último bump? Avaliar changelog para detectar mudanças relevantes
- **Conflito de version:** override local depende de token que foi renomeado/removido em version mais nova do repo externo

Comparar:
- `tokens-override.md` (local) vs `tokens/colors.md`, `tokens/typography.md`, etc. (repo externo @ version pinned)
- `components-custom/` (local) vs `components/` (repo externo @ version pinned)
- `patterns-custom/` (local) vs `patterns/` (repo externo @ version pinned)

### 3. Priorizar drift detectado

Para cada item de drift:

| Severidade | Critério | Ação |
|-----------|---------|------|
| **Crítica** | Quebra de identidade, acessibilidade comprometida, confusão para usuário | Correção priorizada (próxima sprint) |
| **Alta** | Inconsistência visível, drift em componente-base | Tag `design-debt`, próximas 1-2 sprints |
| **Média** | Drift menor, afeta poucas telas | Tag `design-debt`, backlog |
| **Baixa** | Token não usado, polish | Tag `design-debt`, sem urgência |

### 4. Reportar ao Tech Lead

Formato:

```
DESIGN AUDIT — [projeto]
Data: YYYY-MM-DD
Período coberto: [último audit / desde início se primeiro]
Path do projeto: [Externo (vN.N.N) / Inline]
Telas auditadas: N

Resumo:
- Drift crítico: N itens
- Drift alto: N itens
- Drift médio: N itens
- Drift baixo: N itens

[Se Path 1 — Externo]
Overrides obsoletos detectados: N (remover; baseline já cobre)
Overrides candidatos a promoção (PR no repo externo): N
Version atual do repo externo: vN.N.N (pinned em source.md)
Última version disponível upstream: vN.N.N
Bump recomendado? [sim/não — justificativa]

Drift crítico (correção priorizada):
1. [item] — [tela/componente] — [proposta de correção]
2. ...

Drift alto:
1. ...

Drift médio:
1. ...

Drift baixo:
1. ...

Tokens não usados (candidatos a remoção): [lista]

Variantes não documentadas (drift de spec): [lista]

Acessibilidade — pontos de atenção: [lista]

Telas inconsistentes entre si: [lista de pares]

Próximo audit sugerido: [data — 3 meses]

Tarefas adicionadas ao TASK_BOARD: [N tarefas com tag `design-debt`]
```

### 5. Registrar tarefas no TASK_BOARD

Para cada drift de severidade média ou superior:

```
### [DESIGN-AUDIT-NN] Corrigir drift: [descrição]
- **Agente:** Frontend Engineer / Mobile Engineer
- **Prioridade:** Alta / Média / Baixa
- **Tag:** design-debt
- **Contexto:** Audit YYYY-MM-DD — [tela/componente]
- **Spec correta:** [link para `.claude/squad/project/design-system/...`]
- **Bloqueios:** Nenhum
```

### 6. Atualizar agent-memory

Em `.claude/squad/project/agent-memory/product-designer.md`, registrar:

```
## Audit [data]

Cobertura: N telas
Drift total: N itens (crítico: X, alto: Y, médio: Z, baixo: W)

Padrões recorrentes de drift detectados:
- [padrão 1]
- [padrão 2]

Ações no DS doc:
- Documentar variante "compact" do Button (descoberta no codebase)
- Remover tokens não-usados: ...

Lessons:
- Próximo audit: focar mais em telas X, Y (acumularam drift)
```

### 7. Propor melhorias no DS (se aplicável)

Audit pode revelar necessidade de:

- Adicionar variantes oficiais (drift comum vira spec)
- Atualizar tokens (modo escuro incompleto, paleta ampliada)
- Adicionar patterns (caso de uso recorrente sem pattern)

Estas mudanças no DS são **decisões estruturais** — você propõe ao TL, TL orquestra (Architect + Frontend + Mobile).

---

## Anti-patterns (rejeitar)

- Audit sem priorização (todo drift é igual? não)
- Propor mudanças no DS sem orquestração do TL
- Listar inconsistência sem proposta de correção
- Ignorar issues reportadas pelo time/usuário
- Audit que vira lista interminável que ninguém prioriza (foque em crítico + alto)
- Audit sem registrar próxima data (cadência se perde)

---

## Referências

- Product Designer: `.claude/squad/template/agents/product-designer.md`
- DS doc: `.claude/squad/project/design-system/`
- ADR-005: `.claude/squad/template/memory/ADR/ADR-005-design-system.md`
- TASK_BOARD: `.claude/squad/project/TASK_BOARD.md`
- Tag `design-debt` documentada em `.claude/squad/project/TASK_BOARD.md` → "Tags"
