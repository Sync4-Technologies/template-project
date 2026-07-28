# DECISIONS_LOG.md — dev-squad (upstream)

> Decisões rápidas (linha por linha). Decisões pesadas viram ADR.
> Formato: [DATA] [AGENTE] DECISÃO | MOTIVO
> Histórico do produto AgentesIA (decisões + session log até v1.8.0): `archive/agentesia/DECISIONS_LOG.md`

---

## Decisões do sistema (plugin dev-squad)

[2026-07-05] [Usuário+TL] Squad empacotada como plugin `dev-squad` no marketplace pdati; este repo migrado para consumir o próprio plugin (D1) | Dogfooding: upstream valida o que publica
[2026-07-25] [Usuário] enforce_admins mantido nas branch protections | "Sem porta dos fundos" — exceções via ritual documentado (UP-02)
[2026-07-26] [Usuário] v1.8.0 "simplificar": push-gate advisory por padrão (enforce opt-in), menção ≠ execução, skip inline, delegação de merge | Reduzir atrito sem perder sinal de qualidade
[2026-07-26] [Usuário+TL] **Repo assumido como upstream do plugin dev-squad; produto AgentesIA arquivado em `archive/agentesia/`** | Código do produto nunca viveu aqui; board/arquitetura/CLAUDE.md descreviam projeto que não existe mais neste repo — governança agora reflete o propósito real
[2026-07-26] [Usuário+TL] UP-08 aprovado: runner self-hosted org-level Sync4 + `CI_RUNNER=self-hosted` nos 2 repos | Billing Actions esgotado até ~2026-08-01; mata a dança de suspender/restaurar protection
[2026-07-26] [TL] SQUAD_VERSION reconciliado 1.1.0 → 1.8.0 | Registro estava 2 major-minors atrás do plugin instalado (mesmo padrão trokey 1.4→1.6)
[2026-07-28] [Usuário] Plano de evolução aprovado (docs/PLANO_EVOLUCAO_SQUAD.md) + Fase 0 executada | Diagnóstico: review-teatro (achados=0 em 24 PRs), ~32% do sistema cortável
[2026-07-28] [Usuário] Loop engineering = princípio no squad-core (§G); SDD = mini-spec leve; **Scrum Master rejeitado** (cerimônia de coordenação humana que agentes não precisam); painel de custo em 2 degraus (OTEL primeiro) | Anti-over-engineering
[2026-07-28] [Usuário] CI_RUNNER=self-hosted também em concilia e contracts- (dormente: workflows não leem a var; contracts- intocado por ordem do usuário) | Preparação p/ runner org-wide
[2026-07-28] [PENDENTE-Usuário] Manter runner como default permanente vs voltar ao cloud quando billing retornar (~2026-08-01) | Trade-offs apresentados (disponibilidade, ambiente divergente, recursos); decisão registrará aqui

---

## Session Log

[2026-07-28] [Pablo+TL] Sessao longa (26->28): (1) UP-08 FECHADO — runner self-hosted org-level `sync4-mac-local` + CI_RUNNER em 4 repos + UP-10 (setup-python condicional; instalador exige sudo + /Users/runner) — primeiro release inteiro com CI verde real sem danca de protection; (2) governanca upstream: AgentesIA arquivado em archive/agentesia/, board/ARCHITECTURE/CLAUDE.md reescritos, SQUAD_VERSION 1.1.0->1.8.0 — v1.8.1 (PRs #41/#42, inclui fix UP-09 que estava sem release); (3) auto-analise da squad (2 auditores + TL): review-teatro diagnosticado (UP-12), ~32% do sistema cortavel — plano em docs/PLANO_EVOLUCAO_SQUAD.md; (4) Fase 0 executada — v1.9.0 (PRs #43/#44, tag `eb71355`): reviewer cacador opus, QA executa, mini-spec SDD, anti-ancoragem, metrica desinvertida, /squad-audit, par.G. UP-11 registrado (tag antes de confirmar merge). Plugin 1.9.0 user-scope (aplica no restart). Pendente: batalha trokey com 1.9.0 (estreia do reviewer); Fase 1 apos batalha; decisao runner permanente vs cloud. | saude: achados-review=0 retrabalho=0 ciclos-ci-media=27.0 POLUIDO (attempts de estabilizacao do runner no PR #41; achados=0 esperado — PRs de sistema sem spawn de CR; metrica passa a valer com o reviewer novo na batalha) (4 PRs)

[2026-07-26/2a] [Pablo+TL] Sessao de sistema (2a do dia): v1.7.0 E v1.8.0 released (PRs #33-#38 mergeados; tag v1.8.0 em `58713b4`; plugin atualizado 1.6.0->1.8.0 user-scope, aplica na proxima sessao). v1.7.0 = backport trokey AM-18..35 (sessao paralela; AM-18 era REGRESSAO da 1.6.0 — fix da 1.5.0 perdido). v1.8.0 = decisao do usuario "simplificar": push-gate ADVISORY por padrao (enforce opt-in), mencao != execucao (UP-06), skip inline (UP-04), CI_RUNNER no plugin-ci (UP-07), ciclo de update handoff/resume, delegacao de merge, advisor em Fable 5. Trokey: reconciliacao 1.4->1.6 (trokey#86 mergeado), gate orfao la registrado (AM-34/35), encadeamento husky ADIADO por decisao do usuario. UP-03..09 no LESSONS. Pendente: UP-08 (runner self-hosted org-level — sem ele a danca de protection continua), batalha trokey. | saude: achados-review=0 retrabalho=0; ciclos-ci-media=20.0 POLUIDO por outage de billing (jobs 0-steps), sem sinal real (5 PRs)

[2026-07-26] [Pablo+TL] Sessao de sistema: v1.6.0 released (PR #31 -> develop `5ab8b44`, #32 -> main `7ab9f8d`, tag v1.6.0) — 11 subagents nativos em plugin/agents/ (10 executores + advisor; security split Fase1/Fase2), Protocolo de Duvida (squad-core §F), Modo Delegado (lista critica de 6 no TL), UP-01 no push-gate. 9 agents user-scope duplicados movidos pra ~/.claude/agents-disabled. Plugin 1.6.0 instalado. Billing do Actions morto: merges via suspender/restaurar required checks (Pablo a mao; protecoes verificadas restauradas). UP-02 registrado no LESSONS (UP-01 x push de tag). Pendente: batalha trokey-franchising com v1.6; billing. | saude: achados-review=0 retrabalho=0; ciclos-ci-media=9.0 POLUIDO por outage de billing (jobs 0-steps), nao e sinal de qualidade (2 PRs)

[2026-07-05] [Pablo+TL] Sessao de sistema: diagnostico LESSONS_LEARNED (66 acoes) aplicado (P0/P1/P2); squad empacotada como plugin dev-squad v1.0.0->v1.5.0 (marketplace pdati, PRs #12-#28 todos mergeados, tags v1.0.0..v1.5.0). Releases: 1.1.0 IA no centro + frontend + semiautonomia; 1.2.0 squad-core dedup; 1.3.0 mecanismos (plugin-ci, push-gate, squad-metrics); 1.4.0 estetica/fluidez (frontend-design); 1.5.0 rename. Este repo migrado pro proprio plugin (D1); branch protection ativa. Pendente: validacao em batalha. | saude: achados-review=0 ciclos-ci-media=1.0 retrabalho=0 (17 PRs, coletado)

> Sessões anteriores (produto AgentesIA, 2026-06-01 a 2026-06-23): `archive/agentesia/DECISIONS_LOG.md`
