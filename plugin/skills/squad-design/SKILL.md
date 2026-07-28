---
name: squad-design
description: "Conduz Product Designer em trabalho de Design System, em 3 modos: new (propor DS para projeto novo com UI, após PRD), extract (reverse-engineer de DS de UI existente sem docs) e audit (drift periódico de consistência visual em produto maduro). Use quando projeto novo precisa de DS, quando primeira feature visual chega em legado sem docs, ou trimestralmente em produto >6 meses em produção. Substitui as antigas /squad-design-system-new, /squad-design-extract e /squad-design-audit."
---

# Skill — Squad Design (new / extract / audit)

Conduz o PD no ciclo de vida do Design System. Um núcleo comum + 3 modos.

## Seleção de modo

| Situação | Modo |
|----------|------|
| Projeto novo com UI, PRD aprovado, DS não existe | **new** |
| Projeto existente SEM `.claude/squad/project/design-system/` populado; primeira feature visual bloqueada | **extract** |
| DS documentado; checar consistência (cadência trimestral em produto >6 meses, pré-release grande, ou após rajada de features visuais) | **audit** |

Não usar para decisão pontual sobre componente isolado (não exige skill) nem para refresh visual (decisão estrutural: PD propõe, TL orquestra).

---

## Núcleo comum (vale para os 3 modos)

- **Baseline por Path** (fonte: squad-core §J + ADR-005): se `.claude/squad/project/design-system/source.md` existe → **Path 1 (Externo)**, baseline é o repo externo na version pinned + overrides locais (`tokens-override.md`, `components-custom/`, `patterns-custom/`). Senão → **Path 2 (Inline)**, baseline é o próprio `design-system/`. Repos externos suportados: `${CLAUDE_PLUGIN_ROOT}/template/docs/design-system/external-repos.md`.
- **PD documenta e propõe; decisão estrutural é do usuário via TL** (mudar DS, migrar Path, refresh, componente novo oficial). Nenhum modo executa mudança visual por conta própria.
- **Drift é registrado, priorizado e vira task** — nunca corrigido silenciosamente. Registro em `agent-memory/product-designer.md`; tasks com tag `design-debt` no TASK_BOARD.
- **Estrutura do DS doc**: `${CLAUDE_PLUGIN_ROOT}/template/docs/design-system/README.md` (tokens/ · components/ · patterns/ · accessibility.md).
- Report final ao TL sempre com: data, escopo coberto, achados por severidade, próximo passo. Esqueleto por modo abaixo — campos, sem prosa.

---

## Modo NEW — propor DS para projeto novo

1. **Coletar contexto**: PRD (tipo de produto, usuário, identidade), stack escolhida (afeta libs), restrições (brand, paleta corporativa, fontes). Perguntas-chave ao usuário: B2C/B2B/e-commerce/dev-tool/brand-heavy? Identidade existente? Modo escuro? Plataformas? A11y além de WCAG 2.1 AA?
2. **Direção estética ANTES do DS** (decisão do usuário): rodar passo 5a do product-designer.md — framework de 4 perguntas (propósito/tom/constraints/diferenciação, da skill `frontend-design`), 2-3 referências do usuário, propor 3-4 direções (bg/accent/typeface + racional), usuário escolhe. Sem direção declarada = slop garantido.
3. **Propor DS** — default por plataforma (ADR-005 v2): Web React → shadcn/ui+Tailwind+Radix · Web Vue → shadcn-vue+Tailwind · Flutter → Material 3 nativo · RN → react-native-paper. Material 3 web (MUI/Vuetify) é alternativa documentada. Alternativa exige justificativa: brand-heavy → shadcn custom · enterprise denso → Carbon · e-commerce → Polaris/M3 · dev tools → Atlassian · custom total (raro; ADR detalhado).
4. **Decidir Externo vs Inline**: Externo quando há repo externo suportado + squad reutiliza baseline entre projetos + atualizações devem propagar. Inline quando brand radicalmente único, legado já extraído inline, compliance impede externo, ou projeto pequeno/curto. Output: Path + (repo URL + version pinned) ou justificativa inline.
5. **Tokens iniciais**: cores (seed, semânticas primary/secondary/error/success/warning/info, surfaces, text tones, mapeamento dark) · tipografia (famílias display/body/mono, escala M3, pesos 400/500/700, line-heights) · espaçamento (múltiplos de 4: 4-96) · radius, shadows (elevações 0-5), motion (150/250/400ms + easings). Material You: definir só o seed.
6. **Componentes-chave MVP**: Inputs (Button, TextField, Checkbox, Radio, Switch, Select) · Feedback (Alert, Toast, Progress, Spinner, Skeleton) · Surfaces (Card, Dialog, BottomSheet) · Navigation (AppBar, NavRail/Drawer, BottomNav, Tabs) · Data (Table, List, Chip, Avatar). Cada um: variantes + estados (default/hover/active/disabled/loading/error/focused).
7. **Documentar** conforme Path: Externo → `source.md` (do template `source.md.template`) + `tokens-override.md` só com divergências + `components-custom/`/`patterns-custom/` se houver — NÃO duplicar o que o repo externo já tem. Inline → estrutura completa do README do DS.
8. **Propor ao TL → gate do usuário**. Report: contexto (produto/plataformas/dark/restrições) · DS proposto + justificativa · tokens (primária, tipografia, escala, dark) · componentes e patterns cobertos · a11y AA via [...] · aderência ADR-005 ou ADR próprio de desvio · próximo passo. Aprovado → detalhar doc final (cada token com tabela, cada componente com estados, a11y consolidada) e notificar TL; ajustes → incorporar antes de detalhar; rejeitado → alternativa.

**Anti-patterns**: DS por novidade/gosto sem aderência ao produto · ignorar brand existente · tokens sem dark quando requisito · componente sem todos os estados · DS não suportado por uma das plataformas.

---

## Modo EXTRACT — documentar DS de UI existente

**Regra fundamental: você NÃO propõe mudanças neste modo. Documenta o que EXISTE, não o ideal.** Drift vai para registro; TL prioriza depois.

1. **Input**: acesso à UI (prod/staging/screenshots), codebase (CSS computado, `tailwind.config`/theme files, tokens em código), brand guidelines externas se houver, lista de telas-chave priorizada pelo TL/PO.
2. **Inspeção sistemática** (10-20 telas representativas): cores (todas em texto/bg/border/ícone; agrupar tons ~5%; primária = mais usada em CTAs; uso semântico) · tipografia (famílias, pesos, escala recorrente, line-heights) · espaçamento (margins/paddings recorrentes; escala em múltiplos de 4 ou 8; na inconsistência, o mais comum) · componentes recorrentes (buttons/inputs/cards/modals/tables/navegação — estados e variantes ENCONTRADOS, dimensões) · patterns (empty states, error handling, loading, navigation, forms) · a11y atual (contraste, tap targets, focus, labels, screen readers — documentar sem julgar).
3. **Documentar o que existe** na estrutura padrão do DS doc (tokens/ components/ patterns/ accessibility.md).
4. **Registrar drift SEM corrigir** no agent-memory do PD (ex.: "primary tem 3 variações — assumimos a mais comum (60%)"; "botão com 2 alturas — documentadas como variantes, pode ser drift"). Reportar ao TL, que decide backlog (`design-debt`) ou aceitar.
5. **Identificar DS subjacente** se reconhecível (Material/iOS HIG/Bootstrap-genérico/custom) — contexto para engineers, não muda implementação. Se inferido igual a repo externo suportado: documentar inline POR ORA, registrar proposta de migração futura no agent-memory (migração = decisão estrutural via TL, nunca automática). Custom → inline definitivo + ADR do projeto.
6. **Report ao TL**: telas inspecionadas + cobertura % · DS inferido · N tokens/componentes/patterns documentados · a11y observada · N pontos de drift (registro no agent-memory) · destrava: Frontend/Mobile podem implementar com esta doc; TL prioriza drift.

**Anti-patterns**: propor mudança durante extração · documentar o ideal em vez do existente · esconder drift · inventar tokens que não existem na UI · tratar DS externo como verdade quando o produto tem identidade própria.

---

## Modo AUDIT — drift periódico em produto maduro

1. **Baseline** conforme Path (núcleo comum) + issues com label `visual`/`ui`/`design-debt` + telas priorizadas pelo TL/PO (fluxos críticos).
2. **Inspeção por categoria**: tokens (documentados-não-usados; hardcoded que deveria ser token; "fantasma" usado-não-documentado) · componentes (estados faltando, variantes não documentadas, drift de propriedades vs spec) · patterns (empty/error/loading/navegação coerentes entre telas?) · a11y (contraste secundário, focus, tap targets, `prefers-reduced-motion` em animações novas) · telas similares com look divergente (pares lista×lista, modal×modal, form×form). **Path 1 apenas**: overrides obsoletos (baseline já cobre → remover) · overrides candidatos a promoção (PR no repo externo) · drift/conflito de version (changelog do upstream vs pinned; override dependendo de token renomeado).
3. **Priorizar**: Crítica (identidade quebrada, a11y comprometida) → próxima sprint · Alta (inconsistência visível, componente-base) → `design-debt` 1-2 sprints · Média → `design-debt` backlog · Baixa (token não usado, polish) → sem urgência.
4. **Report ao TL**: período coberto · Path (+version pinned e upstream, bump recomendado? — Path 1) · contagem por severidade · críticos e altos com tela/componente + proposta · tokens não usados · variantes não documentadas · a11y · pares inconsistentes · próximo audit (+3 meses) · N tasks criadas.
5. **Tasks no TASK_BOARD** para severidade ≥ média: `[DESIGN-AUDIT-NN]` com agente (Frontend/Mobile), prioridade, tag `design-debt`, spec correta linkada.
6. **Agent-memory**: cobertura, drift total por severidade, padrões recorrentes, ações no DS doc, foco do próximo audit.
7. **Melhorias no DS** reveladas pelo audit (variante oficial, tokens, pattern novo) → propor ao TL; TL orquestra (decisão estrutural).

**Anti-patterns**: audit sem priorização · lista interminável que ninguém prioriza (foco em crítico+alto) · inconsistência sem proposta · ignorar issues reportadas · sem data do próximo audit.

---

Owner: Product Designer · Spec: `${CLAUDE_PLUGIN_ROOT}/template/agents/product-designer.md` · Fontes: ADR-005 + squad-core §J + `${CLAUDE_PLUGIN_ROOT}/template/docs/design-system/README.md`
