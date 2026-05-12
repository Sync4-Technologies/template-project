# External Design System Repos (mantidos pela squad)

> Repos externos de Design System suportados pela squad como **fonte de referência**.
> PD consulta este arquivo ao decidir DS para projeto novo (Modelo B — preferencial).
> Para Modelo A (inline), PD popula DS completo em `.claude/squad/project/design-system/` sem referenciar repo externo.

---

## Repos suportados

| DS | Repo | Status | Tipo de projeto |
|----|------|--------|-----------------|
| **Material 3** | [`Sync4-Technologies/design-system-material3`](https://github.com/Sync4-Technologies/design-system-material3) | Default — em construção | Multi-plataforma (Web MUI + Mobile Flutter/RN) |

---

## Como adicionar novo repo externo

Quando squad central decide criar/adotar novo DS canônico:

1. Repo criado em organização da squad
2. Estrutura mínima (ver "Estrutura recomendada" abaixo)
3. Atualizar tabela "Repos suportados" acima
4. ADR no template (ou ADR específico do projeto piloto) registra adoção
5. PD passa a oferecer como opção em `/squad-design-system-new`

---

## Estrutura recomendada de repo externo

```
design-system-{nome}/
├── README.md                      ← visão geral, version, como consumir
├── CHANGELOG.md                   ← histórico de versions
├── tokens/                        ← tokens base (baseline)
│   ├── colors.md
│   ├── colors.json                ← consumível por código
│   ├── typography.md
│   ├── spacing.md
│   ├── shadows.md
│   ├── radius.md
│   └── motion.md
├── components/                    ← specs por componente
│   ├── button.md
│   ├── input.md
│   ├── card.md
│   ├── modal.md
│   └── ...
├── patterns/                      ← UX patterns
│   ├── empty-states.md
│   ├── error-handling.md
│   ├── loading.md
│   └── navigation.md
├── accessibility.md               ← padrão WCAG + práticas
└── implementations/               ← opcional: snippets de código por stack
    ├── react-mui.md
    ├── vue-vuetify.md
    ├── flutter-material3.md
    └── rn-paper.md
```

### Versionamento

- **SemVer:** breaking change visual → major; novo componente → minor; ajuste de spec → patch
- Tag git por version (`v1.0.0`, `v1.1.0`, etc.)
- CHANGELOG.md atualizado a cada release

---

## Como consumir repo externo em projeto

Ver `.claude/squad/template/docs/design-system/source.md.template` para template de `source.md` no projeto.

### Padrões de consumo

| Padrão | Descrição | Quando usar |
|--------|-----------|-------------|
| **Doc-only** | Frontend/Mobile lê specs do repo externo manualmente | Default — simples, baixa fricção |
| **Vendoring** | Copia `tokens.json` + snapshots para `project/design-system/` | Quando offline access é importante; controle granular de version |
| **Git submodule** | Embarca repo externo como submodule | Quando Frontend precisa de assets/binários do repo |
| **NPM package** | Repo publica como `@org/ds-{nome}` em registry | Maturidade alta; código pronto para `import` |

### Default recomendado

**Doc-only + vendoring de `tokens.json`**:

- Frontend/Mobile lê specs (md files) direto do repo externo
- `tokens.json` baixado do repo (na version pinned) para `project/design-system/tokens.json`
- Update = redownload + bump version em `source.md`

---

## Governance

### Repo externo

| Responsabilidade | Quem |
|------------------|------|
| Manutenção do repo | Squad central de design (ou PD lead da organização) |
| PRs de mudança | Qualquer PD da squad pode contribuir; squad central aprova |
| Release de version | Squad central decide cadência |
| Breaking changes | Comunicar via CHANGELOG.md + notificar TLs dos projetos consumidores |

### Override por projeto

| Responsabilidade | Quem |
|------------------|------|
| Decisão de override local | PD do projeto + TL aprova |
| Documentar em `source.md` + `tokens-override.md` | PD do projeto |
| Identificar promoção (override → contribuição central) | PD em audit periódico |

---

## Quando NÃO usar repo externo

PD deve escolher **inline** (não externo) quando:

- Brand-heavy custom com identidade visual única (raro)
- Projeto pequeno/curto onde overhead de referência supera ganho
- Projeto legado onde DS extraído (`/squad-design-extract`) é tão específico que não justifica externalizar
- Restrição de compliance impede usar repo externo

Cada caso de inline é justificado em ADR específico do projeto.

---

## Referências

- ADR autoritativa: `.claude/squad/template/memory/ADR/ADR-005-design-system.md`
- Source template: `.claude/squad/template/docs/design-system/source.md.template`
- DS index (no projeto): `.claude/squad/template/docs/design-system/README.md`
- Product Designer spec: `.claude/squad/template/agents/product-designer.md`
