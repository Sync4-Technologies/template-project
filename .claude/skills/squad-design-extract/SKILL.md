---
name: squad-design-extract
description: Conduz Product Designer em extração reverse-engineer de Design System de UI existente sem documentação. Use em projeto legado quando primeira feature visual chega e não há DS docs.
---

# Skill — Design System Extract (Reverse Engineer)

> **Owner:** Product Designer | **Revisão:** 90 dias | **Obsolescência:** processo de extração mudar significativamente

Conduz o PD na extração de DS de produto existente sem documentação visual.

---

## Quando usar

- Projeto existente sob domínio da squad (Fluxo 3 ou 5)
- Não há `.claude/squad/project/design-system/` populado
- Primeira feature visual chegou — bloqueia implementação até DS estar documentado
- TL acionou você para extrair antes de Frontend/Mobile prosseguirem

## Quando NÃO usar

- Projeto novo → use `/squad-design-system-new`
- DS já documentado, só validar drift → use `/squad-design-audit`
- Mudança/refresh visual → decisão estrutural; PD propõe + TL orquestra

---

## Regra fundamental

**Você NÃO propõe mudanças nesta skill.** Apenas documenta o que existe.

Mudanças visuais em produto existente são decisões estruturais que envolvem usuário, brand, retrabalho. Não cabe extração apresentar refresh embutido.

Drift e inconsistências encontradas são **registradas** (não corrigidas) para o TL priorizar depois.

---

## Sua tarefa como Claude (atuando como Product Designer)

### 1. Coletar input

Receba:

- **Acesso à UI existente** — produção, staging, ou screenshots se UI não está acessível
- **Codebase frontend/mobile** — para inspecionar valores reais (CSS, Tailwind config, theme files)
- **Brand guidelines** (se existem em outro lugar — Notion, Figma, PDF)
- **Lista de telas-chave** do TL/PO (priorizadas — não precisa cobrir 100% de cara)

### 2. Inspeção sistemática

#### Cores

- Inspecionar 10-20 telas representativas
- Coletar **todas** as cores usadas em texto, backgrounds, borders, ícones
- Agrupar tons similares (tolerância ~5% de variação)
- Identificar cor primária (mais usada para CTAs)
- Identificar uso semântico (error vermelho, success verde, warning amarelo)

Ferramentas: inspecionar CSS computado, `theme.ts`/`tailwind.config.js`, design tokens em código.

#### Tipografia

- Famílias usadas (font-family)
- Pesos (font-weight)
- Tamanhos recorrentes (mapear escala)
- Line-heights
- Letter-spacing se relevante

#### Espaçamento

- Coletar margins/paddings recorrentes
- Identificar escala (geralmente múltiplos de 4 ou 8)
- Detectar inconsistências (12 vs 13 vs 14 — escolher o mais comum)

#### Componentes recorrentes

Identificar componentes que aparecem em múltiplas telas:

- Buttons (variantes e estados)
- Inputs (text fields, selects, checkboxes, radios)
- Cards
- Modals/Dialogs
- Tables/Lists
- Headers, footers, navegação

Para cada um, mapear:
- Estados encontrados (default, hover, disabled, etc.) — alguns podem faltar
- Variantes (filled, outlined, etc.)
- Dimensões (altura, padding interno)

#### Patterns

- Empty states (qual UX quando lista vazia?)
- Error handling (inline? toast? modal?)
- Loading (skeleton? spinner? progress?)
- Navigation (sidebar? bottom tabs? tabs no topo?)
- Forms (validação inline? on submit?)

#### Acessibilidade atual

Detectar nível atual (sem julgar — apenas documentar):

- Contraste em texto principal
- Tap targets
- Focus visível
- Labels semânticos
- Suporte a screen readers

### 3. Documentar em `.claude/squad/project/design-system/`

Popular o diretório com **o que existe** (não com o ideal):

```
tokens/
  colors.md         # paleta extraída + uso semântico observado
  typography.md     # escala observada
  spacing.md        # escala extraída
  shadows.md        # elevações observadas (se aplicável)
  radius.md         # border-radius observados
  motion.md         # se houver animações documentáveis
components/
  button.md         # variantes e estados observados
  input.md
  ...
patterns/
  empty-states.md   # patterns existentes
  ...
accessibility.md    # nível atual observado
```

### 4. Registrar inconsistências (sem propor correção)

Em `.claude/squad/project/agent-memory/product-designer.md`:

```
## Drift detectado na extração [data]

- Cor "primary" tem 3 variações em uso (#6750A4, #6850A0, #6650A8) — assumimos #6750A4 (mais comum: 60% das ocorrências)
- Botão tem 2 alturas concorrentes (40px e 48px) — documentamos como variante "compact" (40) e "default" (48); diferença pode ser intencional ou drift
- Espaçamento entre cards inconsistente (16px / 20px / 24px) — assumimos 16px na escala documentada
- ...
```

Reportar ao TL. TL decide se drift entra em backlog (`.claude/squad/project/TASK_BOARD.md` com tag `design-debt`) ou se é aceitável manter.

### 5. Identificar DS subjacente (se reconhecível)

Tentar identificar se o produto usa um DS:

- **Material:** botões com elevação, FAB, snackbar
- **iOS HIG:** se mobile com Cupertino patterns
- **Bootstrap/Tailwind genérico:** sem patterns específicos
- **Custom:** identidade visual única

Esta inferência ajuda Frontend/Mobile entender contexto, mas **não muda nada na implementação** — produto existente continua como está.

### 5.5. Avaliar similaridade com repo externo conhecido

Consultar `.claude/squad/template/docs/design-system/external-repos.md` para verificar se o DS inferido tem repo externo suportado pela squad.

Se inferido como Material 3 e repo `Sync4-Technologies/design-system-material3` está disponível:

- **Documentar inline POR ORA** (esta skill não propõe mudanças visuais)
- **Propor migração futura para externo** em sprint específica
- Criar entrada em `.claude/squad/project/agent-memory/product-designer.md`:
  ```
  ## Migração potencial DS → externo (data)
  - DS inferido: Material 3 (com customizações)
  - Repo externo disponível: Sync4-Technologies/design-system-material3
  - Razão para adiar migração: extração documentou estado atual; migração é decisão estrutural (ver ADR-005)
  - Sprint sugerida para avaliar: [definir com TL após audit]
  ```

Se inferido como Custom / sem similar externo:

- Manter inline definitivo
- Justificar em ADR específico do projeto (criar ADR-NNN no `project/ADR/`)

**Regra crítica:** esta skill não migra para externo automaticamente. Migração é decisão estrutural que envolve usuário (via TL).

### 6. Apresentar resultado ao Tech Lead

Formato:

```
DESIGN EXTRACTION — [projeto]
Data: YYYY-MM-DD
Telas inspecionadas: N
Cobertura estimada: X% das telas do produto

DS inferido: [Material / iOS / Bootstrap / Custom / Misto]

Tokens documentados em .claude/squad/project/design-system/tokens/:
- N cores semânticas mapeadas
- N tamanhos de tipografia
- Escala de espaçamento: [valores]

Componentes documentados em .claude/squad/project/design-system/components/:
- [N componentes]

Patterns documentados em .claude/squad/project/design-system/patterns/:
- [N patterns]

Acessibilidade atual: [nível observado]
- Contraste: [OK / pontos de atenção]
- Tap targets: [OK / pontos de atenção]
- Focus: [OK / pontos de atenção]

Drift detectado: N pontos (lista em `.claude/squad/project/agent-memory/product-designer.md`)

Próximo passo: 
- Frontend/Mobile podem prosseguir com features visuais usando esta documentação
- TL prioriza correção de drift em backlog (tag `design-debt`)
```

### 7. Notificar destrava

Após documentação publicada, Frontend/Mobile podem implementar a feature visual que aguardava. Notifique TL.

---

## Anti-patterns (rejeitar)

- Propor mudanças visuais durante extração (não é o escopo)
- Documentar o "ideal" ao invés do "existente"
- Esconder drift detectado (sempre reportar ao TL)
- Pular telas-chave (cobertura mínima negociada com TL)
- Inventar tokens que não existem na UI atual
- Aplicar Material 3 ou outro DS como se fosse a verdade quando produto tem identidade própria

---

## Referências

- Product Designer: `.claude/squad/template/agents/product-designer.md`
- Fluxo 3 (continuidade): `CLAUDE.md` → "Fluxos de Projeto"
- DS doc template: `.claude/squad/template/docs/design-system/README.md`
- ADR-005 (DS default): `.claude/squad/template/memory/ADR/ADR-005-design-system.md`
