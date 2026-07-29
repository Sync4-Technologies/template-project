# ADR-005 — Design System (default por plataforma + Alternativas)

**Status:** Aceita (v2 — 2026-07-05: default web passa a shadcn/ui + Tailwind; Material 3 segue default mobile)
**Data:** 2026-05-11 (v1) / 2026-07-05 (v2)
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

### Default por plataforma (v2)

O default único (Material 3 em tudo) descolou da prática: os projetos web reais da squad usam shadcn/Tailwind — default que ninguém segue não é default. v2 adota **default por plataforma**:

| Plataforma | Default | Implementação |
|---|---|---|
| **Web (React)** | **shadcn/ui + Tailwind + Radix** | componentes copiados pro repo (ownership total), tokens via CSS variables |
| **Web (Vue)** | shadcn-vue + Tailwind (ou Vuetify se Material fizer sentido pro produto) | idem |
| **Mobile Flutter** | Material 3 nativo (`useMaterial3: true`) | inalterado |
| **Mobile React Native** | `react-native-paper` (Material 3) | inalterado |

Material 3 web (MUI v6+ / Vuetify) passa a ALTERNATIVA documentada — preferir quando o produto pede a linguagem Material (ex: suíte que convive com apps Google, brand Material-first) ou paridade visual estrita web↔mobile é requisito.

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

1. **Manter o default da plataforma** sempre que possível (web: shadcn/ui + Tailwind; mobile: Material 3)
2. **Para escolher alternativa:**
   - Justificativa concreta baseada em requisitos do PRD
   - ADR específico do projeto documentando trade-offs
   - Aprovação via TL → usuário (decisão estrutural)
3. **Para projetos existentes:**
   - Product Designer **extrai DS atual** antes de propor qualquer mudança
   - Documentação do existente é prioridade #1
   - Mudança de DS em produto existente é decisão grande (refresh visual) — exige ADR + aprovação do usuário

---

## Por que default POR PLATAFORMA (racional da v2)

- **Web (shadcn/ui + Tailwind + Radix):** componentes copiados para o repo — ownership total, sem lock-in de lib; tokens em CSS variables; controle visual fino sem lutar contra opinião de terceiro. É o que os projetos web reais da squad já usavam.
- **Mobile (Material 3):** nativo no Flutter (`useMaterial3`) e coberto por `react-native-paper` no RN — a11y e patterns prontos, Material You dá identidade via paleta seed sem sair do DS. Trocar isso por DS próprio no mobile custa caro e entrega pouco.
- **Por que não um default único:** o único anterior (Material 3 em tudo) descolou da prática — default que ninguém segue não é default. Custo assumido: web e mobile não têm paridade visual estrita out-of-box; quando paridade é requisito, Material 3 web (MUI/Vuetify) é a alternativa documentada.

### Alternativas rejeitadas (ainda válidas)

- **Sem default, PD decide tudo:** cada projeto reinventa; quebra o padrão entre projetos da squad.
- **Tailwind puro sem DS:** utility CSS não é design system — sem componentes nem patterns prontos.

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
- Projeto legado onde DS já foi extraído inline (via `/squad-design (modo extract)`)
- Restrição de compliance impede repo externo
- Projeto pequeno/curto onde overhead não justifica

### Repos externos suportados

Lista atualizada em `${CLAUDE_PLUGIN_ROOT}/template/docs/design-system/external-repos.md`:

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

## Consequências e trade-offs

**Positivas:** default claro por plataforma, alinhado ao que a squad já pratica; PD adapta (paleta, tipografia, componentes-chave) em vez de criar do zero; a11y vem de fábrica nos dois lados; ownership dos componentes na web.

**Negativas / riscos:** sem paridade visual estrita web↔mobile no default (alternativa Material 3 web quando for requisito); dois vocabulários de componente para o PD manter; brand-heavy no mobile sente M3 limitante — alternativa via ADR do projeto; migração futura de DS é custosa, mitigada por tokens centralizados.

**Neutras:** tokens seguem convenção semântica (cores, escala tipográfica) compatível com ambos; ADR de projeto sempre referencia esta ADR.

---

## Critérios de Revisão

Revisar se: um dos defaults perder tração/manutenção · >50% dos projetos novos precisarem de alternativa (sinal de default errado) · paridade web↔mobile virar requisito recorrente (então o default único Material volta à mesa) · surgir DS com melhor fit cross-platform.
- Squad adicionar nova stack que não tenha Material 3 maduro
