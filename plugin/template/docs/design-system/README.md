# Design System

> Documentação viva do Design System deste projeto.
> Mantido pelo **Product Designer**. Consumido por **Frontend Engineer** e **Mobile Engineer**.
> Estrutura técnica (formato dos tokens, build pipeline, sincronização Web/Mobile) é responsabilidade do **Architect**.

---

## Dois caminhos: Externo vs Inline

O projeto pode usar DS de **duas formas**:

### Path 1 — Externo (preferencial)

Projeto referencia repo externo mantido pela squad central (ex: `Sync4-Technologies/design-system-material3`) + lista apenas overrides locais.

**Estrutura no projeto:**

```
.claude/squad/project/design-system/
├── source.md                ← qual DS, repo externo, version, customizações
├── tokens-override.md       ← apenas o que diverge do baseline
├── components-custom/       ← componentes específicos do projeto
└── patterns-custom/         ← patterns específicos
```

**Quando usar:** sempre que possível. Material 3 (default), Carbon, Polaris e outros DS canônicos têm repos suportados — ver `external-repos.md`.

### Path 2 — Inline

Projeto contém DS completo (sem referenciar repo externo).

**Estrutura no projeto:**

```
.claude/squad/project/design-system/
├── README.md                ← qual DS, justificativa de inline
├── tokens/
│   ├── colors.md
│   ├── colors.json
│   ├── typography.md
│   ├── spacing.md
│   ├── shadows.md
│   ├── radius.md
│   └── motion.md
├── components/
│   ├── button.md
│   ├── input.md
│   └── ...
├── patterns/
│   ├── empty-states.md
│   ├── error-handling.md
│   ├── loading.md
│   └── navigation.md
└── accessibility.md
```

**Quando usar:**
- Brand-heavy custom com identidade visual única
- Projeto legado onde DS já foi extraído inline (`/squad-design-extract`) e não vale externalizar
- Restrição de compliance impede usar repo externo

ADR específico do projeto justifica escolha de inline.

---

## Decisão (PD escolhe no início do projeto)

Critérios para **Externo**:

- Há repo externo disponível para o DS escolhido (ver `external-repos.md`)
- Projeto pode adotar baseline + customizar tokens-seed (cor primária, tipografia)
- Squad tem múltiplos projetos com mesmo DS base (evitar duplicação)
- Atualização central do DS deve propagar

Critérios para **Inline**:

- Brand exige identidade visual radicalmente diferente de qualquer DS canônico
- Projeto legado com DS já extraído inline e migração não justifica esforço
- Compliance impede dependências externas
- Projeto pequeno/curto onde overhead de referência supera ganho

PD escolhe; TL valida; ADR registra.

---

## Convenções de documentação

### Tokens (Path 2 — inline; ou em repo externo para Path 1)

```markdown
# Tokens — Cores

## Paleta semântica

| Token | Valor | Uso |
|-------|-------|-----|
| `color-primary` | #6750A4 | Ação principal, links, foco |
| `color-on-primary` | #FFFFFF | Texto sobre primary |
| `color-error` | #B3261E | Erros, validações negativas |

## Modo escuro

Tabela com tokens equivalentes em dark mode.
```

### Componentes (Path 2 — inline; ou em repo externo para Path 1)

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

- default, hover, active, disabled, loading, focused

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
```

### tokens-override.md (Path 1 — Externo)

```markdown
# Tokens Override

> Apenas o que diverge do baseline em [repo externo @ version].

## Cores

| Token | Baseline | Override local |
|-------|----------|----------------|
| color-primary | #6650A4 | #6750A4 |

## Tipografia

| Token | Baseline | Override local |
|-------|----------|----------------|
| font-family-base | "Roboto Flex" | "Inter" |
```

---

## Regras

- **Nada hardcoded** em componentes — sempre via tokens
- **Componente fora do DS** = exceção que exige justificativa em `components-custom/`
- **Mudança em token primário** = decisão estrutural → TL orquestra
- **Drift detectado em audit** = entra em `.claude/squad/project/TASK_BOARD.md` com tag `design-debt`
- **Documentação desatualizada** = bloqueia release até regularização
- Path 1: `source.md` sempre tem version pinned (commit SHA ou tag); nunca `main`/`latest`

---

## Fluxos relacionados

### Projeto novo
1. PD usa `/squad-design-system-new` para conduzir decisão
2. **Externo:** preenche `source.md`, identifica overrides → `tokens-override.md`
3. **Inline:** popula `tokens/`, `components/`, `patterns/`, `accessibility.md` completo
4. ADR específico do projeto registra escolha
5. Frontend/Mobile consomem ao implementar

### Projeto existente (primeira vez aqui)
1. Tech Lead aciona Product Designer
2. PD usa `/squad-design-extract` para reverse-engineer da UI atual
3. PD avalia: DS extraído é similar a algum externo conhecido (`external-repos.md`)?
   - **Sim:** documenta inline por ora; propõe migração para externo em sprint futura (ADR)
   - **Não:** mantém inline definitivo
4. Frontend/Mobile só implementam features visuais após este diretório existir

### Update do DS (Path 1 — Externo)
1. Squad central libera nova version no repo externo
2. PD do projeto avalia changelog + compatibility
3. Bump em `source.md` → nova version + audit visual (`/squad-design-audit`)
4. Tarefas resultantes em `TASK_BOARD.md` com tag `ds-update`

### Audit periódico
1. PD roda `/squad-design-audit` (sugerido trimestral em produtos maduros)
2. Path 1: compara overrides locais vs baseline do repo externo na version atual
3. Path 2: compara telas atuais com `tokens/`, `components/`, `patterns/`
4. Drift documentado em `TASK_BOARD.md` (tag `design-debt`)
5. TL prioriza correções

---

## Referências

- ADR autoritativa: `${CLAUDE_PLUGIN_ROOT}/template/memory/ADR/ADR-005-design-system.md`
- ADR específico do projeto: [link se aplicável]
- Repos externos suportados: `external-repos.md`
- Template `source.md` (Path 1): `source.md.template`
- Product Designer: `${CLAUDE_PLUGIN_ROOT}/template/agents/product-designer.md`
- Frontend Engineer: `${CLAUDE_PLUGIN_ROOT}/agents/frontend-engineer.md`
- Mobile Engineer: `${CLAUDE_PLUGIN_ROOT}/agents/mobile-engineer.md`
- Architect (estrutura técnica): `${CLAUDE_PLUGIN_ROOT}/template/agents/architect.md`
