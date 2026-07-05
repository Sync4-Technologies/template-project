# AI Stack Convention — Evals (qualidade de features de IA)

> **Regra da squad: "sem eval → feature de IA incompleta"** — o equivalente IA de "sem teste → tarefa incompleta".
> pytest/vitest validam código; evals validam COMPORTAMENTO do modelo. Os dois são obrigatórios.

## Quando uma eval é obrigatória

- Toda feature onde um LLM produz output consumido por usuário ou por código
- Toda mudança de **prompt, modelo, contexto, tools ou parâmetros** de uma feature existente → rodar a eval de regressão ANTES do merge (QA gate)

## Golden set (a base de tudo)

- `evals/{feature}/golden/` — casos versionados no repo, ao lado do prompt versionado (`contracts/prompts/`)
- Composição mínima: casos representativos do uso real + edge cases + **casos adversariais** (prompt injection tentando quebrar guardrails, pedidos fora de escopo, PII no input)
- Cada caso: `input` (mensagem + contexto), `expected` (output exato, critérios, ou rubrica), `tags` (happy/edge/adversarial)
- Tamanho: começar com 20-50 casos por feature; crescer a cada bug real encontrado (bug de comportamento vira caso do golden set — mesmo loop do self-review)
- Dados sintéticos com tamanhos/formatos REALISTAS; PII anonimizada

## Métodos de avaliação (do mais barato pro mais caro)

| Método | Quando | Como |
|---|---|---|
| **Assertion programática** | Output estruturado (JSON schema, enum, formato) | Validar schema + regras de negócio em código — determinístico, roda em todo CI |
| **String/regex match** | Respostas com conteúdo obrigatório/proibido | ex: "nunca menciona concorrente X", "sempre inclui disclaimer" |
| **LLM-as-judge** | Qualidade subjetiva (tom, utilidade, aderência à persona) | Modelo avaliador com rubrica explícita por critério, score por critério (não nota única), modelo do judge ≥ modelo avaliado. Rubrica vaga = loop ruidoso — critérios independentes e verificáveis ("resposta cita a fonte" e não "resposta é boa") |
| **Human review** | Amostragem periódica + casos que o judge marca como borderline | Painel pequeno, critérios da mesma rubrica |

## Critérios de aprovação (definidos no PRD §5)

- Score mínimo no golden set (ex: ≥95% nos happy/edge)
- **Zero tolerância** nos adversariais de segurança: vazamento de PII, violação de guardrail, execução de instrução injetada
- Regressão: score da versão nova ≥ score da versão em produção (ratchet — nunca regride)

## Integração no fluxo da squad

1. **QA define os cenários de eval ANTES da implementação** (TDD aplicado a IA) — junto com os testes de código
2. Engineer implementa; self-review §3 inclui "branch que altera prompt/modelo/contexto tem eval de regressão"
3. **CI**: evals programáticas rodam em todo PR que toca a feature; LLM-as-judge roda no PR (custo controlado: só a feature alterada) ou como gate pré-deploy
4. Resultado registrado no PR (score por tag); queda de score = REJECTED
5. Produção: amostragem contínua (N% das interações reais avaliadas pelo judge) alimenta o golden set

## Anti-patterns (block)

- Feature de IA aprovada só com unit tests que MOCKAM o modelo (verde-falso — mesmo padrão do AM-54: mock do sink esconde a classe)
- Rubrica de judge com critério único e vago ("qualidade geral 1-10")
- Golden set que nunca cresce (bugs reais não viram casos)
- Rodar eval só depois do merge
- Comparar scores entre modelos/judges diferentes sem recalibrar a rubrica
