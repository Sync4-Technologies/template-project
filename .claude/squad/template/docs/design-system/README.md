# Design System

> Documentação viva do Design System deste projeto.
> Mantido pelo **Product Designer**. Consumido por **Frontend Engineer** e **Mobile Engineer**.
> Estrutura técnica (formato dos tokens, build pipeline, sincronização Web/Mobile) é responsabilidade do **Architect**.

---

## Design System escolhido

**DS:** [Material 3 / shadcn-ui / Carbon / Polaris / Atlassian / Custom]
**Versão:** [versão do DS ou da lib]
**ADR:** [link para ADR específico deste projeto, derivado de `.claude/squad/template/memory/ADR/ADR-005-design-system.md`]
**Justificativa (se não-default):** [breve motivação se DS escolhido não é Material 3]

---

## Estrutura

```
/.claude/squad/project/design-system/
├── README.md            # este arquivo (índice)
├── tokens/
│   ├── colors.md        # paleta + uso semântico
│   ├── typography.md    # famílias, pesos, tamanhos, line-heights
│   ├── spacing.md       # escala (4, 8, 12, 16, 24, 32, 48, 64…)
│   ├── shadows.md       # elevações
│   ├── radius.md        # border-radius por tamanho
│   └── motion.md        # durações e easings
├── components/
│   ├── button.md
│   ├── input.md
│   ├── card.md
│   ├── modal.md
│   └── ...
├── patterns/
│   ├── empty-states.md
│   ├── error-handling.md
│   ├── loading.md
│   └── navigation.md
└── accessibility.md
```

---

## Convenções de documentação

### Tokens

Cada token doc segue formato:

```markdown
# Tokens — Cores

## Paleta semântica

| Token | Valor | Uso |
|-------|-------|-----|
| `color-primary` | #6750A4 | Ação principal, links, foco |
| `color-on-primary` | #FFFFFF | Texto sobre primary |
| `color-error` | #B3261E | Erros, validações negativas |
| ... | | |

## Paleta tonal (Material You)

- Primary tone 10: ...
- Primary tone 40: ...
- (gerada por algoritmo a partir do seed)

## Modo escuro

Tabela com tokens equivalentes em dark mode.
```

### Componentes

Cada componente doc segue formato:

```markdown
# Component — Button

## Anatomia

[diagrama ou descrição das partes]

## Variantes

| Variante | Quando usar |
|----------|-------------|
| filled | Ação primária |
| outlined | Ação secundária |
| text | Ação terciária / cancel |

## Estados

- default
- hover
- active
- disabled
- loading
- focused

## Acessibilidade

- ARIA roles
- Keyboard support
- Contraste mínimo (4.5:1)
- Tap target mínimo (44x44 iOS / 48x48 Android)

## Tokens usados

- background: color-primary
- text: color-on-primary
- padding: spacing-12
- radius: radius-medium

## Exemplos de uso

[código + screenshot]
```

### Patterns

Cada pattern doc descreve um problema recorrente de UX e o tratamento padrão:

- Quando aparece
- Comportamento esperado
- Componentes envolvidos
- Variações por contexto

---

## Regras

- **Nada hardcoded** em componentes — sempre via tokens
- **Componente fora do DS** = exceção que exige justificativa
- **Mudança em token primário** = decisão estrutural → TL orquestra
- **Drift detectado em audit** = entra em `.claude/squad/project/TASK_BOARD.md` com tag `design-debt`
- **Documentação desatualizada** = bloqueia release até regularização

---

## Fluxos relacionados

### Projeto novo
1. Product Designer propõe DS (default Material 3) via `/squad-design-system-new`
2. Tokens iniciais + componentes-chave documentados aqui
3. Frontend/Mobile consomem ao implementar

### Projeto existente (primeira vez aqui)
1. Tech Lead aciona Product Designer
2. PD usa `/squad-design-extract` para reverse-engineer da UI atual
3. Popula este diretório com o que existe (não propõe mudanças)
4. Frontend/Mobile só implementam features visuais após este diretório existir

### Mudança / Adição de componente
1. Necessidade detectada (Frontend, Mobile, PO, PD)
2. Se já tem pattern aqui → seguir
3. Se não tem → TL orquestra (PD especifica → Frontend/Mobile implementam)
4. Documentação atualizada antes do Squad Done

### Audit periódico
1. PD roda `/squad-design-audit` (sugerido trimestral em produtos maduros)
2. Drift documentado em `.claude/squad/project/TASK_BOARD.md`
3. TL prioriza correções

---

## Referências

- ADR autoritativa: `.claude/squad/template/memory/ADR/ADR-005-design-system.md`
- ADR específico do projeto: [link se aplicável]
- Product Designer: `.claude/squad/template/agents/product-designer.md`
- Frontend Engineer: `.claude/squad/template/agents/frontend-engineer.md`
- Mobile Engineer: `.claude/squad/template/agents/mobile-engineer.md`
- Architect (estrutura técnica): `.claude/squad/template/agents/architect.md`
