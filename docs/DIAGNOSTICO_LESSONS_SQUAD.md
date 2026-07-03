# Diagnóstico — LESSONS_LEARNED (Concilia) × Template da Squad

> Data: 2026-07-03. Gerado a partir de `docs/LESSONS_LEARNED.md` (projeto Concilia, Ondas 0–8, 27 seções, ações AM-01..AM-66) cruzado com leitura completa deste template (13 agentes, 13 skills, 3 hooks, ADRs default).
> Cada linha mapeia lição -> arquivo do template -> mudança proposta.
>
> **STATUS: P0 APLICADO em 2026-07-03** (temas A, B, C, I, J, K — commit `5f202e7`). **P1 APLICADO em 2026-07-03** (temas D, E, F, L — `LESSONS_LEARNED-template.md` criado; security/TL/CR/PRD/PO/architect/PD/QA/README/agent-memory atualizados; skill squad-stack-decision com eixos de produto). Pendente: P2 (G — skill deploy-preflight + devops PaaS; H — stack-conventions).

---

## Contexto

- Este repo é o **template genérico da squad**. O `CLAUDE.md` da raiz é do projeto piloto AgentesIA.
- O LESSONS_LEARNED foi gerado no projeto real **Concilia** (NestJS/Next.js/pnpm/Railway). Várias ações foram aplicadas **na cópia do template dentro do Concilia** (marcadas "[OK] Aplicado"), mas **nunca backportadas para cá**. Três arquivos que o doc referencia como existentes no template do Concilia **não existem neste repo**: `docs/engineer-self-review.md`, `ci/pre-commit-quality.example`, `LESSONS_LEARNED-template.md`.

## Estado atual do template (verificado)

| Já existe e cobre bem | Não existe / gap |
|---|---|
| 13 agentes com DoD, quality gates CI, TDD, feature-flags governance (ADR-003), threat model Fase 1, incident + post-mortem, handoff/resume, memória (TASK_BOARD/DECISIONS_LOG/ADR/agent-memory ≤200 linhas) | `engineer-self-review.md`; `pre-commit-quality.example`; `LESSONS_LEARNED-template.md`; gate local format+lint+typecheck nos DoD; verificação ativa de deploy; `git fetch`+cross-check no resume; proibição de emojis na memória; regras de token security; testes contra DB real como gate |

---

# PARTE 1 — Lições do LESSONS_LEARNED

## Tema A — Qualidade na origem / self-review (P0 — §16, §20, §21 CRÍTICOS)

Causa raiz sistêmica: engineer entrega "compila + happy-path verde" e terceiriza qualidade pra review; gates determinísticos (format/lint/typecheck) falham em CI porque ninguém roda o gate completo local.

| Lição | Arquivo do template | Mudança |
|---|---|---|
| AM-36 | `.claude/squad/template/docs/engineer-self-review.md` (**NOVO**) | Checklist-mestre: §0 gate determinístico completo (format+lint+typecheck+test no repo todo, não só arquivos tocados), §1 segurança (PII/secret em log, cardinalidade, fail-closed, cross-tenant, validação antes do sink), §2 clean code (DRY em cópias, doc↔código), §3 testes (todo branch novo tem teste, determinismo, cobertura ≥ floor) |
| AM-24/33/37 | `agents/{backend,frontend,mobile,ai,devops}-engineer.md` -> Definition of Done | Item obrigatório: gate de qualidade local completo ANTES de todo push (inclusive review-fix e resolução de conflito — "mudança pequena" não isenta) + self-review completo |
| AM-38 | `agents/qa-engineer.md` -> Quality Gates | Validar: todo path/branch novo do diff tem teste de comportamento; cobertura não regrediu; determinismo (anti-flaky); engineer rodou self-review |
| AM-39 | `agents/tech-lead.md` -> Fluxo TDD | Gate 4b pré-CI: TL não encaminha pra CI/review sem self-review do engineer. Review = confirmação, não descoberta |
| AM-40 | `agents/code-reviewer.md` + `agents/security-engineer.md` | Loop de feedback: achado repetitivo -> registrar em LESSONS + adicionar item ao self-review (lista cresce até review virar confirmação) |
| AM-25/34 | `.claude/squad/template/ci/pre-commit-quality.example` (**NOVO**) | Hook bloqueante format:check+lint+typecheck; bypass consciente `--no-verify`; instalação documentada no onboarding |

Princípio: *"CI não é onde se descobre erro determinístico — é onde se confirma que não há. Qualidade é de quem escreve, não de quem revisa."*

## Tema B — "Merged ≠ Deployed" (P0 — §22, §25, §27 CRÍTICOS)

Caso real: Onda 7 inteira merged mas NUNCA deployada (4 camadas de falha); onboarding nunca funcionou em runtime (cascata de 7 bugs, DB 11 migrations atrás) — tudo com healthz 200 e "deploy SUCCESS" stale.

| Lição | Arquivo do template | Mudança |
|---|---|---|
| AM-41 | `skills/squad-handoff/SKILL.md` + DoD do TL (`tech-lead.md`) | "Deploy verificado" = VERIFICAÇÃO ativa (deployment SUCCESS no SHA esperado + health), nunca copiar texto anterior do board |
| AM-51 | `agents/devops-engineer.md` | Gate pós-merge: cruzar commit do deployment com HEAD esperado; healthz 200 não prova nada (deploy velho responde 200) |
| AM-44 | `agents/backend-engineer.md` + self-review | Env var fail-closed nova = provisionar no secret manager faz parte do Done (senão crash-loop no 1º deploy real) |
| AM-55 | `agents/devops-engineer.md` | `migrate status` contra a DB do ambiente é gate de deploy (healthz não pega schema atrasado); idealmente `migrate deploy` no release |
| AM-56/60 | DoD global (README/`tech-lead.md`) + `agents/qa-engineer.md` | Smoke E2E de 1 fluxo crítico no ambiente real após cada deploy; fluxo multi-passo (onboarding/MFA/reset) exige E2E app real + DB real antes de Done |
| AM-42 | `agents/devops-engineer.md` | CI de push (branch principal) tão verde quanto o de PR — gates que diferem PR-vs-push travam deploy silenciosamente |

## Tema C — Continuidade resume/handoff + hook (P0 — §1, §8, AM-64/65)

Caso real: resume leu develop stale e a sessão **re-implementou 8 fatias já mergeadas** (AM-64); emoji truncado no meio pelo hook (versão Concilia) quebrou `/squad-resume` com API Error 400 (AM-65).

| Lição | Arquivo do template | Mudança |
|---|---|---|
| AM-64 | `skills/squad-resume/SKILL.md` | Step 1: `git fetch origin` + para cada item "entregue" no Current Focus, confirmar commit/PR em `git log origin/<main>` antes de tratar como pendente |
| §8.3 | `skills/squad-resume/SKILL.md` | Ler `ARCHITECTURE.md` COMPLETO quando o próximo passo exigir (hook só carrega head de 50 linhas) |
| §8.4 | `skills/squad-resume/SKILL.md` | Carregar `agent-memory/{agente-relevante}.md` conforme próximo passo do Current Focus |
| §8.5 | `skills/squad-resume/SKILL.md` | Session delta: `git log --after="última entrada do Session Log"` |
| §8.1/8.2 | `skills/squad-handoff/SKILL.md` | ARCHITECTURE.md e LESSONS_LEARNED.md como steps ATIVOS com perguntas-gatilho meta-squad (gap em spec de agente? skill perdeu passo? hook falhou? processo causou retrabalho? regra faltando no CLAUDE.md?) — não checklist passivo |
| AM-27 | `skills/squad-handoff/SKILL.md` | Pergunta: "engineer rodou format+lint+typecheck no último commit?" |
| AM-65 | `skills/squad-handoff/SKILL.md` + convenção de memória | Memória sem emojis/chars astrais (usar `[OK]`, `[!]`, `->`). Verificado: o `load-memory.sh` DESTE template trunca por linhas em str Python + `json.dumps` (codepoint-safe) — o bug de bytes era da versão evoluída no Concilia. Regra vale como guarda para futuras modificações do hook |
| AM-01 | README.md (governança) + candidato `CLAUDE.md`-template | Checklist pré-sessão com `/squad-resume` obrigatório como 1º passo |

## Tema D — LESSONS_LEARNED como pilar do sistema (P1 — §8.6)

| Lição | Arquivo do template | Mudança |
|---|---|---|
| — | `.claude/squad/template/LESSONS_LEARNED-template.md` (**NOVO** — o doc do Concilia referencia este path; não existe) | Template com estrutura: o que falhou / causa raiz / ação corretiva (tabela AM-xx com arquivo-alvo + status) / princípio |
| §8.6 | README.md + `memory/agent-memory/README.md` | LESSONS_LEARNED como pilar de continuidade; distinção: melhoria de sistema da squad -> LESSONS; learning técnico do agente -> agent-memory |

## Tema E — Segurança (P1 — §4, §15, §26)

| Lição | Arquivo do template | Mudança |
|---|---|---|
| AM-20 | `agents/code-reviewer.md` + DoD engineers | Token de segurança não merge sem CONSUMER funcional + teste E2E: aceita válido; rejeita revoked; rejeita expired; verifiers vizinhos rejeitam scope errado. Comentário documentando intenção NÃO é evidência |
| AM-21 | `agents/security-engineer.md` | Nunca compartilhar segredo de assinatura entre fluxos distintos — cada scope = secret próprio (blast radius) |
| AM-22 | `agents/security-engineer.md` | Revoke implica lookup (DB/blocklist por jti) em CADA request — setar `revoked_at` sem invalidar token = token vale até TTL |
| AM-23 | `agents/code-reviewer.md` | Grep: comentário "MFA/step-up required" exige decorator+guard correspondentes; mismatch = REPROVADO |
| AM-53/54 | `agents/qa-engineer.md` + self-review §3 | Invariante que vive no banco (enum/constraint/RLS/trigger) exige ≥1 teste de integração contra DB REAL — mock do sink esconde a classe inteira (verde-falso) |
| §4 | `agents/security-engineer.md` checklist | Bypass de auth exige fail-fast em non-development; baseline delay de timing acima do caminho feliz; URLs públicas com enforcement de protocolo no schema de config |
| AM-66 | `agents/backend-engineer.md` + `security-engineer.md` + `qa-engineer.md` | Exception filter preserva status de erros conhecidos (4xx não vira 500 — observabilidade mente); default de rate-limit revisado contra tráfego real de cliente típico (SPA ≠ endpoint isolado) |

## Tema F — Processo do Tech Lead (P1 — §3, §9, §10, §19, §24)

| Lição | Arquivo do template | Mudança |
|---|---|---|
| §3 anti-padrão 2 | `agents/tech-lead.md` | Máx 2 subagentes Opus paralelos (3 Sonnet) — rate limit |
| §3 anti-padrão 4 / AM-06 | `agents/tech-lead.md` + `code-reviewer.md` | Decisão em `// TODO`/comentário -> DECISIONS_LOG no mesmo commit |
| AM-12 | `agents/tech-lead.md` (governança) | Tech-debt de duplicação cross-app resolvido ANTES da N+1ª ocorrência do mesmo padrão |
| §10 | `agents/tech-lead.md` | Delegações grandes (20+ fixes) partir em 2-3 menores com checkpoint tsc/tests entre elas |
| §9 | `agents/tech-lead.md` | Verificar entrega de cada subagente via `git status`, não confiar só no relatório; gate nunca-executado = gate que não existe (billing CI off => gate manual local obrigatório — AM-09) |
| §19.1 | `agents/tech-lead.md` | Ao retomar débito de diagnóstico antigo, re-verificar a premissa no código/log real antes de implementar a "solução" registrada (hipótese §18 estava errada por 2 ondas) |
| AM-47/48 | `agents/tech-lead.md` (orquestração de PRs) | Stacked PRs: preferir PRs pequenos mergeados rápido; se stacked inevitável, merge-commit (não squash) ou recipe de merge train (retarget base -> merge -X ours -> push -> squash) |
| §18/19 | `agents/qa-engineer.md` | Flaky vs regressão: falha em teste que não toca código do PR = infra/flaky; investigar isolamento (serial p/ integração, pool/conexão determinística), não aceitar rerun como estado permanente |

## Tema G — DevOps / deploy / Docker (P2 — §2, §13, §14, §23, §25)

| Lição | Arquivo do template | Mudança |
|---|---|---|
| AM-16 | `.claude/skills/squad-deploy-preflight/SKILL.md` (**NOVO**, generalizado do "squad-railway-deploy") | Pre-flight de deploy PaaS: docker build local de cada Dockerfile, diff env vars exigidas (schema de config) vs env do provider, context/rootDirectory match, build order de workspace |
| AM-18/43 | `agents/devops-engineer.md` | Gotchas PaaS: watchPatterns não disparam em mudança só de Dockerfile; cache mounts BuildKit rejeitados; rootDirectory×context; secrets novos por release |
| AM-45/46 | `agents/devops-engineer.md` + runbook template | Diagnóstico billing CI: TODOS os jobs falham em segundos, runner vazio, sem logs = billing/conta, NÃO YAML. Runbook de contingência CI-morto |
| AM-49 | `agents/devops-engineer.md` | Dockerfile de monorepo builda pacotes por GLOB (`--filter "./packages/*"`), nunca lista explícita |
| AM-50/52 | self-review (gate docker) + `devops-engineer.md` | `.dockerignore` na RAIZ do contexto excluindo `**/dist`+`**/node_modules`; validação fiel: limpar artefatos locais antes de `docker build --no-cache` (simula contexto git do provider) |
| AM-02/10 | `agents/devops-engineer.md` | Smoke `docker build` local antes de qualquer push que toque Docker/deps/build-config (iteração remota é 5-10× mais lenta) |
| §2 | `agents/devops-engineer.md` | Padrões multi-stage: NODE_ENV timing, init (tini) p/ signal propagation, deps de runtime (openssl) em todos os stages que precisam |

## Tema H — Stack-específicos -> stack-conventions (P2 — §11, §14, §17, §27)

| Lição | Arquivo do template | Mudança |
|---|---|---|
| AM-28/29/57 | `docs/stack-conventions/frontend/react.md` + `agents/frontend-engineer.md` + `code-reviewer.md` | SSR/RSC: fetch com env server-only = Server Action/route handler, nunca client component; `NEXT_PUBLIC_*` é build-time (ARG+ENV no Dockerfile); CR grep `'use client'` importando `process.env` sem `NEXT_PUBLIC_` = BLOCKER |
| AM-14/62 | `docs/stack-conventions/backend/nodejs.md` | NestJS: SWC builder via `nest-cli.json` desde o início (tsx/esbuild ignora decorator metadata); nunca `eslint --fix` cego — `consistent-type-imports` elide classes de DI e quebra boot |
| AM-17/19 | `docs/stack-conventions/backend/nodejs.md` | Matriz NODE_ENV × ambiente (development/staging/production/test): efeitos em validação de config, logger transport, install de deps |
| AM-61 | `docs/stack-conventions/backend/nodejs.md` | Mexeu em `package.json` -> commitar lockfile da RAIZ junto (senão `--frozen-lockfile` quebra todos os builds) |
| AM-58 | `agents/backend-engineer.md` | Asset não-compilado (`.md`, `.json`, fixtures) exige cópia explícita pro build output + try/catch no leitor (404, não 500) |
| AM-59 | `agents/backend-engineer.md` | Fetch outbound sempre com `User-Agent`+`Accept` (CDN/WAF bloqueia UA-less de datacenter); `!res.ok` ≠ "serviço fora" — logar status real; truncar campos de fonte externa aos limites da coluna |
| AM-63 | `agents/architect.md` | Governança de contratos: pacote de contratos só vale se CONSUMIDO — fonte de verdade é o backend (DTO+controller); contrato órfão = drift silencioso |
| §12 | `agents/qa-engineer.md` (ou docs de teste) | Comportamento por design (ex: step-up MFA com TTL curto) documentado na collection/fixtures de teste — evita diagnóstico falso |

---

# PARTE 2 — Diretrizes do usuário (além do LESSONS_LEARNED)

## Tema I — Economia de tokens na comunicação da squad (P0)

Problema atual: specs enormes (tech-lead 846 linhas; 13 agentes ≈ 7.000 linhas), delegações e relatórios sem limite de tamanho, conteúdo re-colado entre agentes.

| Diretriz | Arquivo do template | Mudança |
|---|---|---|
| Delegação enxuta | `agents/tech-lead.md` (protocolo de delegação) | Delegar por REFERÊNCIA, não por cópia: apontar paths (PRD, contrato, ADR) que o subagente lê sozinho; incluir só o delta de contexto que não está em arquivo. Proibir colar conteúdo integral de arquivos na delegação |
| Relatório padrão curto | Todos os `agents/*.md` (seção "Formato de resposta") | Formato fixo de retorno do subagente: Entregue / Arquivos tocados / Decisões / Pendências / Riscos — bullets, sem prosa, sem repetir o pedido. Limite explícito (ex: ≤30 linhas salvo exceção justificada) |
| Sem re-derivação | `agents/tech-lead.md` | TL não re-explica estado que o hook/skill já carregou; não repete quality gates na íntegra a cada delegação — referencia a seção da spec |
| Specs mais enxutas (médio prazo) | `agents/*.md` | Refactor: extrair seções repetidas entre agentes (feature flags, modos MVP/Production, hierarquia) para doc único referenciado — 13 cópias hoje. Reduz tokens de todo spawn de agente |
| Comunicação direta | README.md (princípios) | Princípio: comunicação técnica direta, sem cerimônia entre agentes; cada mensagem inter-agente responde "o que o receptor precisa pra agir", nada mais |

## Tema J — Handoff/resume sem redundância (P0 — complementa Tema C)

Problema: handoff hoje grava estado em 4 lugares (Current Focus, Session Log, agent-memory, handoff message) com sobreposição; resume recarrega tudo. Informação duplicada = tokens gastos 2× (na escrita e em TODA leitura futura de sessão).

| Diretriz | Arquivo do template | Mudança |
|---|---|---|
| Single source por tipo de informação | `skills/squad-handoff/SKILL.md` | Regra: estado de tarefa -> só TASK_BOARD; decisão -> só DECISIONS_LOG; learning técnico -> só agent-memory; melhoria de sistema -> só LESSONS_LEARNED. Handoff message REFERENCIA (1 linha por item), nunca repete conteúdo |
| Session Log enxuto | `skills/squad-handoff/SKILL.md` | Entrada ≤5 linhas: data, o que mudou (refs de commit/PR), próximo passo. NÃO narrar o que `git log` já mostra |
| Current Focus = só o próximo passo | `skills/squad-handoff/SKILL.md` | 1 bloco curto acionável; histórico não fica no Current Focus (vai pro Session Log/board Done) |
| Resume carrega delta, não tudo | `skills/squad-resume/SKILL.md` + `hooks/load-memory.sh` | Resume apresenta: delta desde última sessão + Current Focus + bloqueios. Não re-resumir o projeto inteiro a cada retomada; ARCHITECTURE completo só quando o próximo passo é arquitetural (senão head + seções relevantes) |
| Limites de crescimento | `hooks/load-memory.sh` + `memory/agent-memory/README.md` | agent-memory já tem teto de 200 linhas — adicionar teto análogo para Session Log (rotacionar/arquivar entradas antigas); DECISIONS_LOG no hook segue 10 últimas |
| Anti-redundância como gate do handoff | `skills/squad-handoff/SKILL.md` | Checklist final: "alguma informação foi escrita em 2 lugares? Se sim, deixar em 1 e referenciar" |

## Tema K — Anti-over-engineering (P0)

| Diretriz | Arquivo do template | Mudança |
|---|---|---|
| Checklist de simplicidade (as 6 perguntas) | `docs/engineer-self-review.md` (§ novo "Simplicidade") + DoD de `{backend,frontend,mobile,ai}-engineer.md` | Antes de entregar, responder: (1) Preciso de tantas linhas? (2) Tem solução mais simples? (3) Consigo reaproveitar solução existente com baixa adaptação? (4) Estou usando Clean Code? (5) Clean Architecture? (6) Respeito SOLID? — resposta "não" em 1-3 = simplificar antes do review |
| Reuso antes de criar | `agents/{backend,frontend,mobile,ai}-engineer.md` | Passo obrigatório pré-implementação: buscar no codebase util/service/componente existente que resolva; criar novo só se adaptação custar mais que criação (e registrar o porquê) |
| TL guarda o escopo | `agents/tech-lead.md` | Gate de plano: rejeitar design com abstração especulativa (YAGNI) — camada/interface/config sem 2º caso de uso real não entra; hexagonal/DDD só onde ADR-002 já diz que agrega (domínio rico), não por default |
| CR rejeita complexidade | `agents/code-reviewer.md` | Critério explícito de REJEITADO: complexidade desnecessária (indireção sem ganho, padrão aplicado sem necessidade, código > necessário para o requisito) |
| Architect dimensiona | `agents/architect.md` | Arquitetura proposta deve ser a MÍNIMA que atende PRD+RNFs; toda camada extra justificada em ADR com o requisito que a exige |

## Tema L — Princípios de produto das aplicações da squad (P1)

Seis eixos: **qualidade, simplicidade de solução, facilidade de uso, escalabilidade, resiliência, expansibilidade**.

| Diretriz | Arquivo do template | Mudança |
|---|---|---|
| Manifesto | README.md (ou `CLAUDE.md`-template) | Seção "Princípios de produto" com os 6 eixos como critério de decisão em todo gate (plano, arquitetura, review) |
| PRD cobre os 6 eixos | `docs/PRD-template.md` + `agents/product-owner.md` | RNFs mapeiam explicitamente: escalabilidade (volumetria/crescimento), resiliência (degradação graciosa, retry, fallback), expansibilidade (o que deve ser extensível vs YAGNI), usabilidade (critérios testáveis) |
| Arquitetura avaliada contra os eixos | `agents/architect.md` + `skills/squad-stack-decision/SKILL.md` | Proposta de arquitetura/stack apresenta trade-off nos 6 eixos (tabela curta) — simplicidade tem peso igual a escalabilidade: escala-se o que o PRD pede, não o hipotético |
| UX como gate | `agents/product-designer.md` + `agents/qa-engineer.md` | Facilidade de uso validável: QA inclui cenário de "caminho do usuário leigo"; PD audita fricção nos fluxos críticos |
| Resiliência testável | `agents/qa-engineer.md` + `agents/devops-engineer.md` | Production Mode: cenário de falha de dependência (timeout, indisponibilidade) com comportamento esperado definido — liga com fallback determinístico (ai-engineer) e kill-switch (ADR-003) |

## Tema M — Distribuição do template: por projeto vs global (decisão estrutural)

**Recomendação: manter agentes/skills DENTRO do projeto + formalizar este repo como upstream versionado.**

Fundamentos:
- Reprodutibilidade: governance versionada com o projeto; atualizar global mudaria comportamento de todos os projetos em andamento silenciosamente.
- Multi-usuário: `git clone` distribui a squad (handoff entre usuários é pilar); global exige configurar/sincronizar cada máquina.
- Customização por stack sem condicionais globais.
- Tokens: local do arquivo não muda custo (spec carregada no spawn igual nos dois modelos).

O problema real do modelo atual é o **drift sem canal de retorno** (provado: fixes AM-xx aplicados no template do Concilia nunca voltaram pra cá). Correção:

| Mudança | Onde |
|---|---|
| Este repo = upstream oficial do template, com tag/versão a cada leva de melhorias | README.md (seção "Distribuição e versionamento") |
| Mecanismo de sync nos projetos: script `squad-update.sh` (sincroniza `template/`+`skills/`+`hooks/`, nunca `project/`) — evolução futura: empacotar como plugin do Claude Code (agents+skills+hooks+versionamento nativos) | novo `scripts/squad-update.sh` + README |
| Regra de governance: proibido editar `template/` dentro de projeto — gap vai pro LESSONS_LEARNED do projeto -> backport no upstream -> update | README.md + `skills/squad-handoff/SKILL.md` |
| Versão do template registrada no projeto (ex: `SQUAD_VERSION` em `project/`) para saber que regras governavam cada fase | template + squad-resume |

---

## Priorização sugerida (quando decidir aplicar)

1. **P0** (A+B+C do LESSONS + I+J+K do usuário): ataca os 3 rótulos CRÍTICOS do doc, os fixes de resume/handoff já validados no Concilia (§8 traz os commits de referência `1a66fc0`/`138cb31`), economia de tokens e anti-over-engineering.
2. **P1** (D+E+F+L): segurança de tokens, pilar LESSONS, processo TL, princípios de produto.
3. **P2** (G+H): DevOps/PaaS e stack-conventions (só valem quando projeto usa a stack).

Sinergia: I/J/K reduzem custo de TODAS as sessões futuras — aplicar junto com A/B/C num único passe pelos mesmos arquivos (tech-lead.md, engineers, handoff/resume) evita retrabalho.

## Observações finais

- `docs/LESSONS_LEARNED.md` está **untracked** no repo principal — decidir se commita (é doc do Concilia com detalhes do projeto; alternativa: manter fora e commitar só o `LESSONS_LEARNED-template.md` genérico).
- 3 arquivos a CRIAR no template: `engineer-self-review.md`, `pre-commit-quality.example`, `LESSONS_LEARNED-template.md`.
- `hooks/load-memory.sh` deste template verificado: trunca por linhas em str Python + `json.dumps` -> codepoint-safe. O bug AM-65 (bytes crus) era da versão evoluída no Concilia; manter a convenção "memória sem emojis" como guarda.
