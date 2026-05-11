---
name: squad-design-system-new
description: Conduz Product Designer em proposta de Design System para projeto novo com UI. Define DS (Material 3 default ou alternativa justificada), tokens iniciais e componentes-chave. Use no início de projeto novo após PRD aprovado.
---

# Skill — Design System Novo

> **Owner:** Product Designer | **Revisão:** 90 dias | **Obsolescência:** processo de seleção/definição de DS mudar significativamente

Conduz o PD na proposta inicial de Design System em projeto novo com UI.

---

## Quando usar

- Projeto novo com UI (Fluxo 1) após PRD aprovado
- Início de produto onde DS não existe ainda
- Decisão tomada pelo TL de incluir PD no projeto (sinal: projeto tem UI relevante)

## Quando NÃO usar

- Projeto existente sem doc → use `/squad-design-extract`
- Audit de DS existente → use `/squad-design-audit`
- Decisão pontual sobre componente isolado (não exige skill)

---

## Sua tarefa como Claude (atuando como Product Designer)

### 1. Coletar contexto

Antes de propor DS, leia:

- **PRD** — tipo de produto, usuário-alvo, identidade visual desejada (se mencionada)
- **Stack** — backend/frontend/mobile escolhido pelo Architect (afeta libs de DS disponíveis)
- **Restrições** — brand existente da empresa, paleta corporativa, fontes mandatórias

Perguntas-chave para o usuário (via TL ou direto):
- Tipo de produto (B2C / B2B / e-commerce / dev tool / brand-heavy)?
- Há identidade visual existente da empresa para respeitar?
- Modo escuro é requisito?
- Plataformas (Web only / Web + Mobile)?
- Acessibilidade tem requisitos além de WCAG 2.1 AA (ex: AAA, regulação específica)?

### 2. Propor DS

#### Default: Material 3 (ver `memory/ADR/ADR-005-design-system.md`)

Use Material 3 como ponto de partida sempre que possível:

- Web React: MUI v6+
- Web Vue: Vuetify
- Flutter: Material 3 nativo (`useMaterial3: true`)
- React Native: react-native-paper ou equivalente

#### Quando propor alternativa

Apresente alternativa **com justificativa** quando:

- **Brand-heavy custom** (controle visual fino) → shadcn/ui + Tailwind
- **Enterprise B2B denso** (Salesforce, dashboards complexos) → Carbon (IBM)
- **E-commerce** → Polaris (Shopify) ou Material 3
- **Dev tools / productivity** → Atlassian DS
- **Restrição extrema de identidade** → Custom (raro; exige ADR detalhado)

### 3. Definir tokens iniciais

#### Cores

- **Paleta seed** (cor principal de identidade)
- **Cores semânticas:** primary, secondary, tertiary, error, success, warning, info
- **Surface tones:** surface, surface-variant, background
- **Text tones:** on-primary, on-surface, on-error, etc.
- **Modo escuro:** mapeamento de cada token

Para Material You: definir apenas seed; algoritmo gera resto.

#### Tipografia

- **Famílias:** display / body / mono
- **Escala:** display-large/medium/small, headline-l/m/s, title-l/m/s, body-l/m/s, label-l/m/s
- **Pesos:** regular (400), medium (500), bold (700)
- **Line-heights** e **letter-spacing** por escala

#### Espaçamento

- Escala em múltiplos de 4: `4, 8, 12, 16, 24, 32, 48, 64, 96`
- Tokens: `spacing-xs`, `spacing-sm`, `spacing-md`, `spacing-lg`, `spacing-xl`, `spacing-2xl`...

#### Outros

- **Border radius:** `radius-none`, `radius-sm`, `radius-md`, `radius-lg`, `radius-full`
- **Shadows:** elevações 0-5 (Material) ou conjunto custom
- **Motion:** durações (fast 150ms / standard 250ms / slow 400ms) + easings

### 4. Identificar componentes-chave para MVP

Lista mínima usualmente:

- **Inputs:** Button, TextField, Checkbox, Radio, Switch, Select
- **Feedback:** Alert/Banner, Snackbar/Toast, ProgressBar, Spinner, Skeleton
- **Surfaces:** Card, Dialog/Modal, BottomSheet (mobile)
- **Navigation:** AppBar/Header, NavRail/NavDrawer, BottomNav (mobile), Tabs
- **Data:** Table, List, Chip, Avatar

Pra cada um, indicar:
- Variantes (filled, outlined, text para Button, etc.)
- Estados padrão (default, hover, active, disabled, loading, error, focused)

### 5. Documentar em `/docs/design-system/`

Popular estrutura conforme `docs/design-system/README.md`:

- `tokens/colors.md`, `typography.md`, `spacing.md`, `shadows.md`, `radius.md`, `motion.md`
- `components/{button,input,card,modal,...}.md`
- `patterns/{empty-states,error-handling,loading,navigation}.md`
- `accessibility.md`

### 6. Apresentar proposta ao Tech Lead

Formato:

```
DESIGN SYSTEM PROPOSAL — [projeto]
Data: YYYY-MM-DD

Contexto:
- Tipo de produto: [...]
- Plataformas: [Web / Mobile / Web+Mobile]
- Modo escuro: [sim/não]
- Restrições de brand: [...]

DS proposto: [Material 3 / outro]
Justificativa: [se não-default, motivo concreto]

Tokens iniciais:
- Cor primária: [#XXXXXX] — [tom semântico]
- Tipografia: [família] — [escala usada]
- Espaçamento base: [escala]
- Modo escuro: [sim/não com mapeamento]

Componentes-chave especificados: [lista]
Patterns documentados: [lista]

Acessibilidade: WCAG 2.1 AA garantida via [...]

ADR-005 referência: [confirmar aderência ou justificar desvio]
ADR específico do projeto: [criar `memory/ADR/ADR-NNN-stack-projeto-design.md` se DS != default]

Próximo passo: TL apresenta ao usuário para aprovação (gate).
```

### 7. Aguardar aprovação do usuário (gate)

DS proposto vai ao usuário via TL. Possíveis resultados:

- **Aprovado** — popular `/docs/design-system/` em detalhe; Frontend/Mobile podem começar
- **Aprovado com ajustes** — incorporar mudanças (paleta, tipografia) antes de detalhar
- **Rejeitado** — voltar para proposta alternativa (raro)

### 8. Documentação final

Com aprovação, populá-la em `/docs/design-system/` em nível adequado para Frontend/Mobile consumirem:

- Cada token doc com tabela completa
- Cada componente com todos os estados + exemplo de uso
- Cada pattern com diagrama ou descrição estruturada
- `accessibility.md` consolidado

Notificar TL que DS está pronto para consumo.

---

## Anti-patterns (rejeitar)

- Escolher DS pela "novidade" sem avaliar maturidade
- Escolher pelo gosto pessoal sem aderência ao tipo de produto
- Ignorar restrições de brand existente
- Definir tokens sem modo escuro quando requisito
- Pular acessibilidade
- Especificar componente sem todos os estados
- Adotar DS não-suportado por uma das plataformas do projeto

---

## Referências

- Product Designer: `agents/product-designer.md`
- ADR-005 (DS default): `memory/ADR/ADR-005-design-system.md`
- Estrutura do DS doc: `docs/design-system/README.md`
- Material 3: <https://m3.material.io/>
- shadcn/ui: <https://ui.shadcn.com/>
- Carbon: <https://carbondesignsystem.com/>
- Polaris: <https://polaris.shopify.com/>
- Atlassian DS: <https://atlassian.design/>
