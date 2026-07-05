# Plano de Execução — squad v1.1.0

> Origem: varredura de 2026-07-05 (pós-release v1.0.1) sobre 4 eixos definidos pelo usuário:
> semiautonomia com qualidade, frontend melhor, IA no centro dos novos projetos.
> Fonte canônica de toda mudança: `plugin/` (regra anti-drift). Versão alvo: **1.1.0** (minor — só adições de comportamento).

---

## Fase A — IA no centro (prioridade 1)

Gap confirmado: PRD sem seção IA; zero stack-convention de IA; security sem OWASP LLM; nenhum ADR de arquitetura IA; sem eval harness.

| # | Entrega | Arquivos | Critério de aceite |
|---|---------|----------|--------------------|
| A1 | Seção **"Produto de IA"** no PRD (obrigatória quando IA é núcleo): casos de uso IA, modelo/provider, **custo por interação como RNF**, latência de inferência (P50/P95), política de dados/PII no contexto, fallback determinístico, critérios de evals | `plugin/template/docs/PRD-template.md` + `plugin/template/agents/product-owner.md` (RNFs espelhados) + `plugin/skills/squad-new-project/SKILL.md` (passo 2 pergunta: "qual o papel da IA neste produto?" — resposta define se seção é obrigatória) | PRD de projeto AI-first não passa no gate do PO sem a seção preenchida |
| A2 | **`stack-conventions/ai/`** — 3 arquivos: `anthropic.md` (SDK py/ts, model ids atuais, streaming, tool use, structured outputs, prompt caching, context management, controle de custo), `rag.md` (chunking, embeddings, retrieval + avaliação de retrieval), `evals.md` (golden sets versionados, LLM-as-judge, regressão de prompt, integração CI) | `plugin/template/docs/stack-conventions/ai/{anthropic,rag,evals}.md` + `README.md` do índice | AI Engineer consulta convention antes de task (mesma regra dos outros engineers) |
| A3 | **Evals como quality gate**: "sem eval → feature de IA incompleta" (equivalente IA do "sem teste → incompleto") | `plugin/template/agents/ai-engineer.md` (DoD += evals passando: golden set + regressão de prompt), `plugin/template/agents/qa-engineer.md` (quality gate: feature IA exige eval), `plugin/template/docs/engineer-self-review.md` §3 (branch que altera prompt/modelo/contexto → eval de regressão) | Feature IA sem golden set não chega em review |
| A4 | **OWASP LLM Top 10 no Security**: prompt injection (direto/indireto via dados), insecure output handling (output de LLM é input não-confiável), vazamento de PII via contexto/logs de prompt, excessive agency de tools (least privilege por tool, confirmação p/ ações irreversíveis), model DoS/custo | `plugin/template/agents/security-engineer.md` (checklist novo) + `plugin/skills/squad-threat-model/SKILL.md` (superfície IA no STRIDE) | Threat model de feature com LLM cobre os 5 itens |
| A5 | **ADR-006-arquitetura-ia.md** (default do template): decisão RAG vs tool-use vs fine-tune; single-call vs agentic (agentic só com justificativa); guardrails e kill-switch (liga com ADR-003); política de escolha de modelo (capability vs custo) | `plugin/template/memory/ADR/ADR-006-arquitetura-ia.md` | Architect cita o ADR em decisão de feature IA |
| A6 | **Observabilidade de IA**: tokens/custo/latência por feature como métrica padrão (não menção solta) | `plugin/template/agents/devops-engineer.md` + `ai-engineer.md` (DoD: métricas expostas) | Dashboard/log estruturado com custo por feature em Production Mode |

## Fase B — Frontend (prioridade 2)

Gap confirmado: PD só revisa "feature crítica"; sem checklist visual; ninguém roda/olha a tela; ADR-005 default (M3) descolado da prática (shadcn/MUI nos projetos reais); sem patterns de página.

| # | Entrega | Arquivos | Critério de aceite |
|---|---------|----------|--------------------|
| B1 | **Mini-spec visual obrigatória pra TODA tela nova** (não só crítica): propósito, hierarquia, estados, componentes do DS, spacing — formato de ~15 linhas, PD produz rápido; gate pesado continua só nas críticas | `plugin/template/agents/product-designer.md` (novo fluxo "mini-spec") + `frontend-engineer.md`/`mobile-engineer.md` (não implementam tela sem mini-spec) | Tela nova sem mini-spec = bloqueada pelo TL |
| B2 | **Checklist de qualidade visual** no self-review (§5 novo): escala de spacing consistente, hierarquia tipográfica, estados obrigatórios (loading/empty/error/skeleton), responsivo (3 breakpoints), dark mode quando aplicável, foco visível/navegação por teclado | `plugin/template/docs/engineer-self-review.md` (§5 "Qualidade visual — frontend/mobile") + DoD de `frontend-engineer.md` e `mobile-engineer.md` | Tela entregue sem estado empty/error definido = REJECTED no CR |
| B3 | **Gate "rodou e olhou"**: antes de Engineer Done, rodar o app e capturar screenshot dos estados principais (loading/empty/error/happy); em tela crítica, PD revisa a IMAGEM (não o código). Fecha o furo §27 do Concilia ("nunca clicado por navegador real") na origem | `frontend-engineer.md` (DoD), `qa-engineer.md` (cenário visual), `product-designer.md` (review por screenshot) | Engineer Done de tela inclui screenshots anexados |
| B4 | **ADR-005 v2 — default por plataforma**: web = **shadcn/ui + Tailwind** (prática real dos projetos), mobile = Material 3; M3 web vira alternativa documentada | `plugin/template/memory/ADR/ADR-005-design-system.md` + refs em `product-designer.md` e `docs/design-system/` | Projeto web novo sem restrição de brand parte de shadcn sem discussão |
| B5 | **Biblioteca de page-patterns**: specs prontos e adaptáveis — `dashboard.md`, `crud-list-form.md`, `auth.md` (login/registro/reset), `settings.md`, `onboarding.md` (estrutura, hierarquia, estados, componentes por pattern) | `plugin/template/docs/page-patterns/*.md` + índice + ref no `product-designer.md` | PD parte do pattern e adapta, nunca do zero |

## Fase C — Semiautonomia com medição (prioridade 3)

| # | Entrega | Arquivos | Critério de aceite |
|---|---------|----------|--------------------|
| C1 | **Matriz de Autonomia** no TL: decisão reversível+barata+interna (naming, lib utilitária, refactor local, ordem de tasks) = autônoma + registro `tl-autonomous`; decisão irreversível/cara/externa (schema público, gasto, deploy prod, escopo, segurança) = gate. Elimina o binário atual ("nada sem aprovação" × política de indisponibilidade) | `plugin/template/agents/tech-lead.md` (tabela) + README (semiautonomia explicada) | TL não interrompe o usuário pra decisão da coluna autônoma |
| C2 | **Aprovações em lote**: TL acumula decisões pendentes e apresenta em checkpoint único (fim de fase/chunk), em vez de N interrupções | `tech-lead.md` (protocolo de checkpoint) | ≤1 interação de aprovação por chunk salvo urgência |
| C3 | **Métricas de saúde da squad** no handoff: nº de achados CR/SE por PR (meta 0 — mede se o self-review funciona), ciclos de CI por PR (meta 1), retrabalho (tasks reabertas). Registradas no Session Log, 1 linha | `plugin/skills/squad-handoff/SKILL.md` (step novo) + `squad-status` (exibe tendência) | Handoff sem métricas = checklist falha |

## Fase D — Estrutural (prioridade 4)

| # | Entrega | Arquivos | Critério de aceite |
|---|---------|----------|--------------------|
| D1 | **Remover layout legado do repo** (`.claude/squad/template/`, `.claude/skills/squad-*`, hooks squad em `.claude/hooks/` + entradas no settings.json) — o próprio repo passa a usar o plugin (dogfooding via `/squad-init` modo migração). Pré-condição: AgentesIA (`.claude/squad/project/` deste repo) migrado | repo raiz (remoções) + `.claude/settings.json` | Repo sem duplicação; `grep -r "squad/template" .claude/` vazio (exceto project refs históricos) |
| D2 | *(médio prazo — pode sair da v1.1.0)* Extrair seções repetidas dos 14 specs (feature flags, modos MVP/Production, hierarquia, guardrails de interação) para `template/docs/squad-core.md` referenciado — corta ~30-40% dos tokens de spawn | `plugin/template/agents/*.md` + novo `squad-core.md` | Specs referenciam, não repetem; spawn de agente mais barato |

---

## Ordem de execução e releases

1. **Fase A completa** → maior impacto nos projetos novos (AI-first)
2. **Fase B completa**
3. **Fase C** (pequena)
4. Bump `1.1.0` + changelog no README do plugin + `claude plugin validate` + PR → develop → main + update nas máquinas
5. **Fase D1** em PR separado (remoção — revisar com calma); D2 fica pra v1.2.0

Cada fase: aplicar → self-review do diff → commit (padrão acordado). Fases A e B são as maiores (~15 arquivos cada, incl. novos).

## Verificação

- `claude plugin validate` verde (plugin + marketplace)
- Smoke: hook persona + skills carregam
- Teste de mesa: PRD de exemplo AI-first passa pelo fluxo novo (pergunta IA no squad-new-project → seção IA no PRD → threat model com OWASP LLM → eval gate)
- Piloto real: migrar AgentesIA (`/squad-init` modo migração) e rodar uma feature de ponta a ponta com os gates novos

## Fora de escopo (registrado, não esquecido)

- D2 (dedup de specs) → v1.2.0
- Agentes nativos de plugin (invocáveis via Task com frontmatter) em vez de specs-doc → avaliar na v2 (muda o modelo de delegação do TL)
- Skill `squad-eval-run` (executor de evals) → depois que `evals.md` definir o formato
