# Plano de Evolução da Squad — Diagnóstico e Roadmap

> Auto-análise solicitada por Pablo em 2026-07-26/28. Método: 2 auditores independentes (skills+templates; engineers+specs main-thread) + análise direta do TL (reviewers, hooks, LESSONS, métricas de 24 PRs).
> **Nada foi alterado** — este documento é diagnóstico + plano, aguardando aprovação.

---

## Sumário executivo

| Frente | Achado central | Tamanho |
|--------|---------------|---------|
| **Review frouxo** | Gate de review é teatro por desenho: CR instruído a ser "confirmação", sem método de caça, sem exigência de evidência, rodando em sonnet; QA nunca executa nada | achados-review=**0 em 24 PRs** |
| **Tokens** | ~30-35% do sistema é gordura (duplicação, retórica, cerimônia) | ~5.200 linhas cortáveis de ~16.100 auditadas |
| **Performance** | 2 subprocessos python em TODO comando Bash; chamada de rede dentro de hook; sem via rápida para tarefa trivial | ~100-200ms × milhares de execuções/sessão |
| **Bugs funcionais** | 5 achados de passagem (referência fantasma, links quebrados, padrão UP-06 não propagado, etc.) | — |
| **Métricas** | `achados-review=0` lido como saúde quando é sintoma de gate morto; nenhuma métrica gera ação | — |

---

## 1. Diagnóstico: por que o Code Review não pega nada

Dado objetivo: **24 PRs em 3 sessões, achados-review=0, retrabalho=0.** Audits externos (audit code / audit security) acham "muitas falhas". Não é azar — é desenho. Dez causas, em ordem de peso:

### 1.1 Complacência institucionalizada (a arma do crime)
`plugin/agents/code-reviewer.md` §"Loop de Feedback → Self-Review" diz literalmente:

> "Você é rede de segurança (**confirmação**), não inspeção primária (descoberta). [...] PR chegar sem achados é o normal, não a exceção."

Isso foi desenhado para um loop de self-review maduro que não existe ainda. Efeito real: o CR é **instruído a esperar zero achados**. Zero achados vira confirmação do sistema funcionando — o KPI está invertido.

### 1.2 Categorias sem método de caça
O arquivo tem 389 linhas de **O QUE** olhar (correção, arquitetura, qualidade, segurança, performance, DS, flags) e **zero linhas de COMO** caçar. Sem protocolo (listar arquivos do diff → para cada função tocada, ler chamadores → seguir data flow → greps dirigidos por categoria de vulnerabilidade), o modelo lê o diff, faz pattern-match superficial e aprova. Verbos do prompt são de confirmação ("você verifica: lógica correta") — pressupõem a propriedade em vez de procurar a violação. Audit externo pergunta "onde está errado?"; o CR pergunta "está ok?".

### 1.3 Modelo fraco no gate mais importante
`code-reviewer.md` frontmatter: `model: sonnet`. O security-reviewer usa `opus`. Os audits externos do Pablo rodam no modelo forte da sessão. Review de código sutil é exatamente onde tier de modelo mais importa.

### 1.4 Sem contrato de evidência
"Feedback: problemas encontrados, explicação objetiva" — vago. Compare com o security-reviewer (74 linhas, bem desenhado): formato obrigatório `vetor → impacto → mitigação, ordenado por severidade` + verificação mitigação-por-mitigação. O CR não é obrigado a produzir `file:line` + cenário de falha + severidade, nem a documentar o que investigou e refutou.

### 1.5 QA valida relatórios, não executa
`qa-engineer.md` (575 linhas): em **nenhuma linha** o QA é mandado EXECUTAR algo. Verbos: "validar/garantir/verificar". Toda evidência exigida é do engineer. Com `All tools` disponível, o QA pode rodar a suíte — o prompt nunca cobra. O TL tem a regra "verificar via git status, não confiar no relatório"; o QA não tem equivalente.

### 1.6 Cláusula perigosa no QA
"Se houver dúvida: você ajusta os testes, não o código" — lido literalmente por subagent, autoriza enfraquecer asserção para o teste passar. Falta: "ajustar = corrigir cenário com base em PO/Architect, nunca afrouxar para ficar verde".

### 1.7 Ancoragem pelo orquestrador
TL delega "o engineer entregou X, revise" — o CR revisa a moldura do resumo, não o diff cru. Audit externo chega sem narrativa prévia.

### 1.8 Uma passada só
Audit externo eficaz faz varredura por categoria em passadas separadas + verificação adversarial dos achados. O CR faz uma leitura única multi-critério.

### 1.9 TDD sem entregável definido
A fase de definição do QA (cenários antes) não tem formato: onde vivem os cenários, como o engineer consome. Sem artefato, a validação posterior não tem contrato contra o qual cobrar.

### 1.10 Métrica cega
`saude: achados-review=0` registrado 3× no Session Log como se fosse saúde. Zero achados em PR não-trivial deveria disparar alarme de gate morto, não celebração.

**Contraexemplo interno:** o security-reviewer (74 linhas) tem o desenho certo — single-source, opus, formato com evidência, mitigação-por-mitigação. O CR nunca recebeu esse tratamento. A v1.6 fez o split do SE e parou.

---

## 2. Diagnóstico: gasto de tokens (~30-35% do sistema é gordura)

### 2.1 Números por área (auditoria completa, arquivo por arquivo)

| Área | Linhas | Cortável | % |
|------|--------|----------|---|
| Skills (15) | 2.776 | ~1.200 | 43% |
| Subagents (11) + specs main-thread (5) | 6.890 | ~2.400 | 35% |
| Templates memory+docs | 2.050 | ~330 | 16% |
| Stack-conventions (13) | 4.360 | ~1.100 | 25% |
| **Total auditado** | **~16.100** | **~5.200** | **~32%** |

Impacto recorrente: resume/handoff/status (630 linhas juntas) rodam em quase toda sessão → corte para ~410 economiza 2.5-3k tokens/sessão, todo dia. tech-lead.md (1.008 linhas, o arquivo mais carregado) → ~600. Ciclo completo de squad: ~30k tokens a menos.

### 2.2 Padrões de desperdício (top 8)

1. **Skill que cola o conteúdo do doc que ela cita como fonte** — threat-model duplica security-engineer.md; incident duplica devops; stack-decision duplica stack-conventions/README; prd-template duplica PRD-template. ~215 linhas.
2. **Trio de design = 728 linhas (26% das skills) para os eventos mais raros** — new/extract/audit compartilham ~40%; critério "Externo vs Inline" existe em 5 lugares. Fusão → ~250 linhas.
3. **Regra compartilhada re-derivada em N arquivos** apesar de fonte única declarada: governança de flags em 8 arquivos (ADR-003 é a fonte); cobertura 60/80/95 em 17 arquivos (squad-core §C); DS Path 1/2 em 4 (ADR-005); emoji/ASCII em 5; diagrama hexagonal em 4; snippet gate-ok em 5.
4. **Scaffolding retórico uniforme** em 13 de 14 agents: Identidade poética, "Regras Absolutas" filosóficas, org chart "Relação com outros agentes" (executor só fala com TL de qualquer forma), "Comunicação", "Regra Final". 60-100 linhas/arquivo. `advisor.md` (61 linhas) prova que dá para ser denso.
5. **Cerimônia de output**: templates de relatório de 28-45 linhas em 5 skills (status tem template de 38 linhas e regra "≤200 palavras" no mesmo arquivo).
6. **Anti-patterns que negam os próprios passos** — 15/15 skills têm a seção; maioria dos itens é o passo N reescrito em negativo. ~130 linhas.
7. **tech-lead.md narra o fluxo de revisão 3× e o gate de arquitetura 2× em seções consecutivas** (mesma frase repetida).
8. **frontend × mobile ~120 linhas quase-clone** (bloco DS verbatim, i18n, DoD) — candidato a bloco "ui-engineer" no squad-core.
9. **handoff §3 spawna N agentes para escrever ≤10 linhas de memória cada** — cada spawn carrega spec de 450-660 linhas. Milhares de tokens para gerar dezenas. TL escreve direto.
10. **Stack-conventions ~25-30% genérico** (tsconfig completo, naming conventions, async/await — o modelo já sabe). O que paga: gotchas de produção reais, comandos, "when NOT to use".

### 2.3 Peso morto especulativo
- `external-repos.md` (132 linhas): estrutura de governance completa para um registro com **1 repo "em construção"**.
- Header "Owner/Revisão 90 dias/Obsolescência" nas 15 skills: nenhum mecanismo verifica revisão. 30 linhas de governança morta.
- ADR-005: ~80 linhas argumentando "por que Material 3" — obsoletas desde que o default web virou shadcn.

---

## 3. Diagnóstico: performance e gargalos de fluxo

### 3.1 Runtime (hooks)
1. ~~**Todo comando Bash paga 2 subprocessos python**~~ — **RESOLVIDO (2026-07-30, item 2.1)**. Medição confirmou a ordem de grandeza do diagnóstico: 83.6ms/comando com os dois hooks, 5.1ms com o `pre-bash.sh` unificado.
2b. ~~**`gh pr view` (rede) dentro do hook**~~ — **RESOLVIDO (2026-07-30, item 2.2)**: cache local + refresh em background.
2. **`gh pr view` (rede) dentro do hook** a cada push real (UP-01) — segundos no caminho crítico, fail-open mas lento.
3. `architecture-reminder` em todo Edit/Write — aceitável (barato, dirigido), manter.

### 3.2 Fluxo (orquestração)
4. **Sem via rápida para tarefa trivial**: fix de 5 linhas com teste já falhando percorre QA-define → engineer → CI → QA-valida + CR = 4+ spawns. A matriz de autonomia gradua decisões, não cerimônia.
5. **"Feature crítica" over-dispara**: "qualquer rota que processe dados pessoais" torna quase todo endpoint de SaaS crítico → SE 2 fases + flag + kill-switch para tudo. Falta qualificador de materialidade.
6. **M0 serializa no merge do usuário**: fluxo manda mergear M0 antes de spawnar back/front, e merge default é do usuário — orquestração para esperando clique. Delegação de merge v1.8.0 existe mas o fluxo M0 não instrui pedi-la junto.
7. **Dois regimes de espera sobrepostos** no TL (checkpoint em lote vs política de indisponibilidade antiga) — convida leitura conservadora (parar mais).

---

## 4. Bugs funcionais (achados de passagem — corrigir independente do resto)

| # | Bug | Onde |
|---|-----|------|
| B1 | Referência fantasma: manda seguir "formato dos exemplos em template/memory/" — exemplos não existem → boards inconsistentes entre projetos | squad-init:48 |
| B2 | 9 links markdown quebrados (`[x](../../../${CLAUDE_PLUGIN_ROOT}/...)` mistura path relativo com variável) | squad-new-project |
| B3 | ~~Padrão UP-06 não propagado: `*"git commit"*` substring casa MENÇÃO, não execução~~ — **FEITO (v1.10.0)**; a cópia deixou de existir na v2.0.0 (hooks fundidos) | ex-`memory-update-reminder.sh:23` |
| B4 | Sintaxe `[${VAR}/...](../${VAR}/...)` dobra tokens e gera link morto | backend:46-50, frontend, mobile, ai, architect |
| B5 | advisor pinna `model: claude-fable-5` (ID completo envelhece; resto usa alias) | advisor.md frontmatter |

---

## 5. Plano de evolução (fases; nada executado ainda)

### FASE 0 — Reviewer de verdade (v1.9.0) — ataca a queixa central
> Critério de sucesso: achados-review > 0 em PRs não-triviais; audit externo posterior acha ≤ 20% do que acha hoje.

| # | Ação | Arquivo |
|---|------|---------|
| 0.1 | **Reescrever code-reviewer.md do zero** no molde do security-reviewer: ~120 linhas, protocolo de caça em passadas (1ª: mapa do diff + chamadores de cada função tocada; 2ª: caça dirigida por categoria com greps concretos; 3ª: adversarial nos 3 pontos de maior risco), contrato de output `file:line → cenário de falha concreto → severidade`, obrigação de listar "investigado e refutado" (mín. 5 hipóteses em PR não-trivial), remover TODA a seção "confirmação/PR sem achados é o normal" | plugin/agents/code-reviewer.md |
| 0.2 | **`model: opus` no code-reviewer** (paridade com security-reviewer; gate crítico não roda em tier econômico) | idem, frontmatter |
| 0.3 | **QA executa ou não aprova**: aprovação DEVE conter comando executado + output real (X passed/Y failed) + cobertura extraída de artefato; "sem evidência executável = não aprovado". Corrigir cláusula "ajusta os testes" (nunca afrouxar asserção). **Entregável TDD vira mini-spec de feature (SDD leve)**: 1 arquivo por feature (contrato + critérios de aceite + cenários, ~40 linhas) em `.claude/squad/project/specs/`, criado por Architect+QA, consumido pelo engineer, cobrado pelo CR — fecha os 30% que faltavam de Spec-Driven Development sem tooling pesado | plugin/agents/qa-engineer.md + template/docs/feature-spec.md |
| 0.4 | **Anti-ancoragem**: TL entrega ao CR o diff/branch + objetivo da task — nunca o resumo do engineer | template/agents/tech-lead.md (§ revisão) |
| 0.5 | **Inverter a métrica**: `achados-review=0` em 3+ PRs não-triviais consecutivos = alarme de gate morto no handoff (não sinal de saúde) | squad-handoff + tech-lead.md |
| 0.6 | **Skill `/squad-audit`** (opcional): formaliza o audit periódico que o Pablo roda na mão — multi-passada, code+security, no modelo forte, com verificação adversarial dos achados. Barato de criar: é o desenho do 0.1 em modo repo-inteiro | plugin/skills/squad-audit |
| 0.7 | **Loop engineering como regra de governança**: toda delegação define critério de saída verificável por comando (teste/lint/build) + limite de iterações; sem critério verificável, tarefa volta ao TL. 1 parágrafo no squad-core | template/docs/squad-core.md |

### FASE 1 — Dieta de tokens (v1.9.x)
> Critério: -25-30% linhas no sistema sem perda de comportamento; resume+handoff+status ≤ 410 linhas somadas.

| # | Ação | Economia |
|---|------|----------|
| 1.1 | squad-core rodada 2: absorver flags-governance (pointer p/ ADR-003), mapa de fronteiras de segurança, bloco ui-engineer (frontend∩mobile), DoD comum, bloco plugin-update, snippet gate-ok, footer padrão de 3 linhas | ~500 linhas |
| 1.2 | Reescrever tech-lead.md 1008→~600 (fluxo de revisão 1×, gate de arquitetura 1×, remover SOLID/OWASP que são de CR/SE, fundir os 2 regimes de espera) | ~400 |
| 1.3 | Fundir trio de design em `squad-design` (modos new/extract/audit) | ~450 |
| 1.4 | Skills: cortar duplicação-com-spec, templates de relatório, anti-patterns-espelho, headers de governança morta | ~750 |
| 1.5 | Engineers + architect + PO/PD: cortar scaffolding retórico, deduplicar via squad-core | ~1.000 |
| 1.6 | handoff §3: TL escreve agent-memory direto (spawn só se houve delegação real com contexto que TL não viu); remover §6 double-pass | ~50 + spawns |
| 1.7 | Corrigir B1-B5 | — |
| 1.8 | Stack-conventions: cortar genérico, manter gotchas/comandos/"when NOT" | ~1.100 (baixa prioridade — carrega sob demanda) |

### FASE 2 — Performance e fluxo (v2.0)
| # | Ação |
|---|------|
| 2.1 | ~~Fundir os 2 hooks PreToolUse Bash num script único com early-exit shell barato~~ — **FEITO (2026-07-30)**: `pre-bash.sh` substitui push-gate + memory-update-reminder (BREAKING). Medido: 83.6ms -> 5.1ms por comando Bash (**-94%**, 16.3x). Ganho extra: o ramo de commit herdou o fix worktree-aware (AM-18/UP-03) que a cópia nunca recebeu |
| 2.2 | ~~Tirar `gh pr view` do caminho síncrono do push~~ — **FEITO (2026-07-30)**: cache em `$GIT_DIR/squad-pr-state` (TTL 24h) lido sem rede + refresh em background para o push seguinte. Aviso da UP-01 chega um push depois numa branch que morreu agora — trade-off explícito no changelog. **UP-02 fechada de carona** (pendente desde v1.6.1) |
| 2.3 | **Fast lane no TL**: tarefa trivial (fix ≤ ~20 linhas com teste existente, copy, config) pula QA-define; engineer + CR em passada única. Critério objetivo escrito, não subjetivo |
| 2.4 | Qualificar "feature crítica" com materialidade (dados pessoais além de identificadores de sessão; dinheiro; authz) |
| 2.5 | M0: propor delegação de merge junto com a proposta do M0 (1 linha no fluxo) |
| 2.6 | ~~Fundir política de indisponibilidade na matriz de autonomia (1 regime só)~~ — **FEITO na Fase 1** (tech-lead.md reescrito já saiu com regime único) |
| 2.7 | ~~UP-14: plugin-ci duplicava suite em PR com head develop/main~~ — **FEITO (2026-07-28)**: `push` restrito a `main`; prova de efeito no próximo release PR |

### FASE 3 — Métricas que geram ação (v2.x)
| # | Ação |
|---|------|
| 3.1 | Redefinir linha de saúde: `achados-review/PR-não-trivial` (alvo > 0), `achados-audit-externo` (alvo → 0), `spawns/tarefa` (eficiência), latência CI |
| 3.2 | Regra de leitura no handoff: cada métrica fora do alvo → 1 linha de ação ou justificativa. Métrica sem consequência 2 sessões seguidas → deletar a métrica |
| 3.3 | ~~ADR-005: remover argumentação obsoleta do Material 3 web~~ — **FEITO (2026-07-28)**: racional reescrito para default-por-plataforma; "A1 shadcn rejeitado" removida (contradizia a v2); trade-offs/consequências/critérios de revisão realinhados (218→~170 linhas) |
| 3.4 | **Observabilidade de custo (degrau 1)**: ligar OpenTelemetry nativo do Claude Code → Grafana local (ou `ccusage` sobre os JSONL) para custo/tokens por sessão. Painel web custom (degrau 2, live por agente/tarefa) só se o degrau 1 deixar pergunta sem resposta — dogfooding da squad quando vier |

### Decisões de escopo discutidas (2026-07-28)

- **Loop engineering**: incorporado como princípio (0.7), não como camada/papel novo — Fase 0 já é loop engineering aplicado (fechar loops com sinal objetivo).
- **SDD**: squad já fazia ~70% (PRD → contrato → cenários → código); mini-spec unificada (0.3) fecha o resto. Tooling pesado de spec rejeitado.
- **Scrum Master**: **rejeitado** — cerimônia para coordenação humana que agentes não precisam; necessidades legítimas (métricas, acompanhamento, retro) já têm dono (Fase 3, item 3.4, LESSONS). Revisitar se 3+ humanos simultâneos.
- **Painel web**: aprovado em 2 degraus (3.4); começar por ferramentas prontas, não por build custom.

### Ordem recomendada e esforço

1. **Fase 0** primeiro — é a dor relatada, e é pequena (2 arquivos reescritos + 3 ajustes). 1 sessão.
2. **Fase 1** em 2-3 PRs (squad-core+agents; skills; conventions). 1-2 sessões. Validar em batalha no trokey entre elas.
3. **Fase 2** junto ou logo após (2.1-2.2 são triviais; 2.3-2.6 são mudanças de governança no TL). 1 sessão.
4. **Fase 3** no handoff seguinte à Fase 0 (as métricas novas precisam do reviewer novo produzindo dados).

### Riscos
- **Corte agressivo pode remover instrução que segurava comportamento** — mitigação: cada PR de dieta passa batalha no trokey antes do próximo; LESSONS registra qualquer regressão comportamental (mesmo mecanismo AM-18 que pegou a regressão da 1.6.0).
- **Reviewer rigoroso demais → falso positivo e atrito** — mitigação: contrato exige cenário de falha concreto por achado (sem cenário, não é achado); métrica de retrabalho continua monitorada.
- **Opus no CR aumenta custo por review** — aceito: gate de qualidade é onde tier paga; volume de PRs é baixo.
