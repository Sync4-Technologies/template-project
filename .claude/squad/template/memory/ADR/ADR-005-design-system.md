# ADR-005 — Design System (Material 3 Default + Alternativas)

**Status:** Aceita
**Data:** 2026-05-11
**Autor:** Product Designer + Architect + Tech Lead

---

## Contexto

A squad cobre técnica (Architect, Engineers) e produto (PO), mas faltava ownership claro de **design**. Sem isso:

- Projetos novos: Frontend/Mobile inventam tokens → divergência visual
- Projetos existentes sem doc de DS: impossível manter padrão; mudanças produzem drift
- Mudanças estruturais visuais (refresh, dark mode, DS migration): sem agente para coordenar

Decisão: criar agente **Product Designer** com responsabilidade de conteúdo do DS, mantendo Architect responsável pela estrutura técnica.

Esta ADR define o **DS padrão** e **alternativas suportadas**.

---

## Decisão

### Default: Material Design 3

Adotar **Material Design 3** (Material You) como Design System padrão do template.

**Implementações por stack:**

- **Web (React):** MUI v6+ (`@mui/material`) ou Material Web Components
- **Web (Vue):** Vuetify (Material 3 support)
- **Mobile Flutter:** Material 3 nativo (`useMaterial3: true`)
- **Mobile React Native:** `react-native-paper` ou `react-native-material-you`

### Alternativas suportadas

Product Designer pode escolher alternativa quando há justificativa concreta:

| DS | Quando preferir | Implementação típica |
|----|----------------|---------------------|
| **shadcn/ui** | Brand-heavy custom, controle fino | React + Tailwind + Radix UI |
| **Carbon Design System (IBM)** | Enterprise B2B densos | `@carbon/react` |
| **Polaris (Shopify)** | E-commerce | `@shopify/polaris` |
| **Atlassian Design System** | Dev tools, productivity | `@atlaskit/*` |
| **Custom** | Brand exige (raro) | Tailwind + tokens custom |

### Regra de escolha

1. **Manter Material 3 como default** sempre que possível
2. **Para escolher alternativa:**
   - Justificativa concreta baseada em requisitos do PRD
   - ADR específico do projeto documentando trade-offs
   - Aprovação via TL → usuário (decisão estrutural)
3. **Para projetos existentes:**
   - Product Designer **extrai DS atual** antes de propor qualquer mudança
   - Documentação do existente é prioridade #1
   - Mudança de DS em produto existente é decisão grande (refresh visual) — exige ADR + aprovação do usuário

---

## Por que Material 3 como Default

### Prós

- **Open source** e mantido pelo Google
- **Maduro e completo** — vasto component library
- **Cross-platform** — funciona em Web (MUI) e Mobile (Flutter nativo, RN libs)
- **Material You** — temas dinâmicos baseados em cor seed
- **Acessibilidade built-in** (Material guidelines incluem a11y)
- **Patterns ricos** para B2C e enterprise
- **Ecosistema** — libs prontas, documentação extensa, comunidade ativa
- **Mobile-first friendly** — fácil adaptive Material 3 (Android) + Cupertino-like (iOS) quando necessário

### Contras (mitigados)

- **"Cara de Google"** — mitigado por customização de paleta seed e fonte (Material You preserva identidade)
- **Componentes opinionated** — mitigado por possibilidade de override granular
- **Menos enxuto que shadcn/ui** — aceitável; ganho de funcionalidades compensa

---

## Alternativas Consideradas

### A1. shadcn/ui como default
- **Prós:** muito enxuto, Tailwind nativo, controle total
- **Contras:** apenas React; Mobile precisa de outro DS; não é "design system" canônico (é mais um component starter)
- **Status:** rejeitado como default — limita cross-platform

### A2. Sem default (PD decide tudo)
- **Prós:** máxima flexibilidade
- **Contras:** cada projeto reinventa; sem padrão entre projetos da squad; oversight do PD em cada projeto
- **Status:** rejeitado — quebra princípio de template padronizado

### A3. Tailwind sem DS canônico
- **Prós:** zero opinião visual
- **Contras:** não é um DS — é só utility CSS; sem patterns prontos
- **Status:** rejeitado — viola "padrão visual inegociável"

---

## Estratégia de uso: Externo vs Inline (Modelo B híbrido)

A squad adota **Modelo B** como preferencial: DS base em **repo externo** centralizado + **override local** por projeto.

### Path 1 — Externo (preferencial)

Projeto referencia repo externo + lista apenas overrides locais.

**Repo padrão para Material 3:**
- URL: `https://github.com/Sync4-Technologies/design-system-material3`
- Mantido pela squad central
- Versionamento SemVer (tags `v1.0.0`, `v1.1.0`, etc.)

**Estrutura no projeto:**

```
.claude/squad/project/design-system/
├── source.md                ← qual DS, repo, version, customizações
├── tokens-override.md       ← apenas o que diverge do baseline
├── components-custom/       ← componentes específicos do projeto
└── patterns-custom/         ← patterns específicos
```

**Quando preferir Externo:**
- Há repo externo disponível para o DS (ver `external-repos.md`)
- Projeto adota baseline + customizações locais (paleta seed, tipografia)
- Squad tem múltiplos projetos com mesmo DS base
- Atualizações centrais devem propagar

### Path 2 — Inline

Projeto contém DS completo (sem referenciar repo externo).

**Quando preferir Inline:**
- Brand-heavy custom com identidade visual radicalmente única
- Projeto legado onde DS já foi extraído inline (via `/squad-design-extract`)
- Restrição de compliance impede repo externo
- Projeto pequeno/curto onde overhead não justifica

### Repos externos suportados

Lista atualizada em `.claude/squad/template/docs/design-system/external-repos.md`:

| DS | Repo | Status |
|----|------|--------|
| Material 3 | `Sync4-Technologies/design-system-material3` | Default (em construção) |

### Governance dos repos externos

- **Manutenção:** squad central de design (ou PD lead da organização)
- **PRs:** qualquer PD pode contribuir; squad central aprova
- **Releases:** squad central decide cadência (recomendado trimestral)
- **Breaking changes:** comunicar via CHANGELOG.md + notificar TLs dos projetos consumidores

### Padrões de consumo do repo externo

| Padrão | Quando usar |
|--------|-------------|
| **Doc-only** (default) | Frontend/Mobile lê specs do repo externo manualmente |
| **Vendoring** (snapshot) | Copia `tokens.json` para projeto; controle granular |
| **Git submodule** | Embarcar repo como submodule (raro) |
| **NPM package** | Quando repo publica como `@org/ds-{nome}` |

### ADR específico do projeto

Cada projeto cria ADR específico que registra:

- Path escolhido (Externo ou Inline)
- Repo externo + version pinned (se Externo)
- Justificativa de Inline (se aplicável)
- Padrão de consumo (Doc-only, vendoring, submodule, package)
- Customizações principais

---

## Trade-offs Assumidos

- Material 3 tem opinião visual forte — projetos que precisam de identidade radicalmente diferente migram para alternativa (esperado em ~10-20% dos projetos)
- Componentes Material 3 são mais "pesados" que shadcn/ui — overhead aceitável para benefício de a11y + patterns prontos
- Cross-platform Material 3 não é perfeitamente uniforme (iOS prefere Cupertino) — PD pode definir adaptive UI quando aplicável

---

## Consequências

### Positivas

- Padrão visual claro por default em todos os projetos da squad
- Onboarding rápido para devs (Material 3 amplamente conhecido)
- Cross-platform funciona out-of-box (Web + Mobile)
- Acessibilidade default
- PD pode focar em **adaptação** (paleta seed, tipografia, componentes-chave) ao invés de criar do zero
- Material You permite identidade visual sem sair do DS

### Negativas / Riscos

- Projetos com brand-heavy podem sentir M3 limitante — alternativa via ADR
- "Cara de Material" em alguns projetos pode ser indesejada — Material You + customização mitigam
- Migração futura para outro DS é custosa (mitigado por design tokens centralizados)

### Neutras

- Convenção de tokens segue padrão Material 3 (cores semânticas, escala de tipografia, etc.)
- ADR específico do projeto sempre referencia esta ADR

---

## Critérios de Revisão

Esta decisão deve ser revisada se:

- Material 3 perder tração ou Google descontinuar suporte
- Mais de 50% dos projetos novos precisarem de alternativa (sinal de que default está errado)
- Surgir DS comparável com melhor cross-platform fit
- Squad adicionar nova stack que não tenha Material 3 maduro
