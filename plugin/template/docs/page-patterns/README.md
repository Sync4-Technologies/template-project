# Page Patterns — specs prontos de página

> Usados pelo **Product Designer** como base da mini-spec (product-designer.md → passo 5b): PD parte do pattern e ADAPTA ao produto — nunca do zero. Qualidade sobe, custo cai.
> Cada pattern define estrutura, hierarquia, estados e componentes — em cima do DS do projeto (ADR-005: web shadcn/ui + Tailwind, mobile Material 3).

| Pattern | Arquivo | Cobre |
|---|---|---|
| Dashboard | [`dashboard.md`](dashboard.md) | Visão geral com métricas, gráficos e atividade recente |
| CRUD (lista + form) | [`crud-list-form.md`](crud-list-form.md) | Listagem com busca/filtro/paginação + criação/edição |
| Auth | [`auth.md`](auth.md) | Login, registro, reset de senha, MFA |
| Settings | [`settings.md`](settings.md) | Configurações de conta/workspace em seções |
| Onboarding | [`onboarding.md`](onboarding.md) | Primeiro uso guiado em passos |

Regras transversais (valem pra todo pattern):

- **4 estados obrigatórios** por área de dados: loading (skeleton com a MESMA estrutura do conteúdo), empty (mensagem + ação primária, nunca área branca), error (mensagem acionável + retry), sucesso
- **1 ação primária por tela** — visualmente dominante; secundárias subordinadas
- **Responsivo**: mobile-first; tabela vira lista de cards abaixo de ~768px
- **A11y**: foco visível, navegação por teclado no fluxo principal, labels em todo input, contraste AA
- Textos de exemplo REALISTAS (nomes longos, números grandes) nas validações

**Patterns definem ESTRUTURA, não estética.** A cara da tela vem da direção estética do projeto (product-designer.md passo 5a + skill `frontend-design` da Anthropic) — o mesmo pattern de dashboard fica brutalist num produto e editorial noutro.

Pattern novo: criar aqui quando o mesmo tipo de tela se repetir em ≥2 projetos (mesma regra de skills — ≥N usos).
