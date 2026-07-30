# Plugin `dev-squad` — AI Software Squad

Governança completa para projetos conduzidos por squad de agentes Claude Code: 5 papéis main-thread + 11 subagents nativos, 14 skills, hooks de memória viva e templates de qualidade.

## Instalação

```bash
# 1. Adicionar o marketplace (uma vez por máquina; lê a branch default do repo)
/plugin marketplace add Sync4-Technologies/template-project

# 2. Instalar o plugin (escopo user — vale pra todos os projetos da máquina)
/plugin install dev-squad@pdati

# 3. Verificar
claude plugin list              # dev-squad@pdati — enabled
claude plugin details squad     # 14 skills, 3 hooks, ~870 tok always-on

# 4. Reiniciar a sessão Claude Code (plugin carrega na próxima sessão)

# 5. No projeto (uma vez):
/squad-init                     # cria .claude/squad/project/ + SQUAD_VERSION
```

Passo a passo completo com troubleshooting: README do repositório → "Distribuição e Versionamento (Plugin)".

## Uso

| Situação | Comando |
|----------|---------|
| Adotar a squad num projeto (novo ou existente) | `/squad-init` — cria `.claude/squad/project/` (memória) + `SQUAD_VERSION` |
| Projeto novo do zero | `/squad-new-project` |
| Retomar trabalho | `/squad-resume` (obrigatório como 1º passo de retomada) |
| Encerrar sessão | `/squad-handoff` |
| Antes de deploy em PaaS | `/squad-deploy-preflight` |

Skills completas: ver `skills/`. Specs main-thread (TL, PO, PD, Architect, SE): `template/agents/`. Subagents nativos (engineers, QA, reviewers, advisor): `agents/`. Checklist de qualidade dos engineers: `template/docs/engineer-self-review.md`.

## Arquitetura: plugin × projeto

| Vive no plugin (estático, versionado aqui) | Vive no projeto (estado) |
|---|---|
| Specs main-thread (5) + subagents nativos (11), 14 skills, 3 hooks, docs (self-review, stack-conventions, design-system), templates (PRD, ADR, LESSONS_LEARNED), CI examples | `.claude/squad/project/` — ARCHITECTURE, TASK_BOARD, DECISIONS_LOG, ADRs do projeto, agent-memory, LESSONS_LEARNED, contracts, `SQUAD_VERSION` |

**Regra de governança:** não editar arquivos do plugin dentro de um projeto. Gap no sistema da squad → registrar no `LESSONS_LEARNED.md` do projeto (skill `/squad-handoff`, step 2c) → backportar aqui (upstream) → nova versão → projetos atualizam explicitamente. Isso fecha o ciclo de drift que motivou o plugin.

## Versionamento

- SemVer. Toda mudança de comportamento de agente/skill/hook = bump de versão + entrada no changelog do repo.
- Cada projeto grava a versão em uso em `.claude/squad/project/SQUAD_VERSION` — auditável qual governança valia em cada fase.
- Update é ação explícita do usuário (`/plugin` → update), nunca silencioso.

## Migração / atualização de projeto (automatizada)

```bash
scripts/squad-migrate.py --project .            # diagnóstico (dry-run)
scripts/squad-migrate.py --project . --apply    # executa só o determinístico
```

Funciona em qualquer estado (template clonado, híbrido, plugin puro) e em qualquer máquina: inventaria as cópias locais, classifica cada uma por **direção do diff** contra a união de todas as versões do cache (defasada = seguro remover; linha exclusiva = escalar; sem par = artefato do projeto), e aponta o resto — hooks locais no `settings.json`, contratos na memória (AM-30), gate órfão (AM-34), `hooksPath` absoluto (AM-38), governança defasada. Nunca toca `.claude/squad/project/`, `.env` ou código. Detalhe do critério e o que fazer com as decisões: `/squad-init` → "Migração".

## Changelog

### 1.14.0 (2026-07-29)

Backport do trokey-franchising (AM-42..AM-47) — dois marcos consecutivos entregues com o protocolo de review caçador renderam 23 achados sobre suítes 100% verdes. As duas famílias que se repetiram viraram checklist, e o pre-check da 1.12.0 levou um fix urgente.

- **[fix] O pre-check de ambiente da 1.12.0 abortava todo push em Node acima do mínimo.** Ele extraía o primeiro número do range de `engines.node` e comparava por **igualdade**: num projeto que pede `">=22"`, o v26 (que **satisfaz** o range) era barrado com "pede major 22" — e a mensagem oferecia `--no-verify` como saída. Um pre-check cujo propósito declarado é *"obstáculo ensina o hábito do --no-verify"* virou o obstáculo e ensinou a burla. Agora respeita o operador: `>=`/`>` reprovam só abaixo do mínimo **e** acima do teto quando o range é fechado (`">=22.0.0 <23.0.0"`, o caso que motivou o pre-check original, segue reprovando v26); pin e caret exigem o major. Roda depois do `cd` para a raiz, para checar o repositório e não o diretório de chamada. Verificado nos 12 casos das 3 formas de range. **Quem já reconciliou para 1.12.0 tem o gate quebrado — atualizar é urgente**
- **Checklist de marcador de idempotência** (`template/docs/feature-spec.md`, `backend-engineer`): (a) o WHERE da marcação leva o marcador **e** o predicado de estado — marcador sozinho só fecha a corrida entre dois ticks do mesmo job, não contra a transação do usuário; (b) campo de elegibilidade que muda **reseta** os marcadores, por mudança de valor e nunca por presença da chave no payload — as duas pontas do mesmo erro, uma mata o alerta para sempre, a outra duplica alerta e evento; (c) teste de corrida com lock explícito, e que prove o **mecanismo**, não a consequência
- **Seed de e2e sem assert de status vira regra** (`qa-engineer`, `backend-engineer`): um 422 engolido no `beforeAll` deixou uma suíte rodando com a configuração errada por dias, com os vermelhos aparecendo em dois testes sem relação com a causa. Comparação de tempo ancora no valor lido do sistema, nunca no relógio local (~300 ms entre host e Postgres bastaram)
- **Marco que herda lições pede reviewer de contexto limpo** (`tech-lead` §6): quem ditou a lição tem viés de confirmação ao checar se foi seguida — o reviewer novo achou 2 MAJOR, um deles dentro da correção ditada pelo reviewer anterior. Re-verificar fechamento, ao contrário, volta ao mesmo reviewer. Junto: achado que alcança código já em produção se corrige no mesmo ciclo, em commit separado e com teste discriminante
- **Hook novo não vale até o repo principal trocar de branch** (`/squad-init` passo 5, `/squad-resume` 3c): `core.hooksPath` é absoluto e o dispatcher resolve o script no working tree do **principal** — parado em outra branch, o hook sai `exit 0` em silêncio em todas as worktrees, com o arquivo presente na worktree e já em `main`
- **Porte de script é código, não documentação** (`/squad-init`, `/squad-resume`): copiar executável do template para o projeto exige rodá-lo uma vez no ambiente real antes de commitar. Foi assim que o pre-check quebrado chegou a um projeto

### 1.13.0 (2026-07-29)

Reconciliação de governança deixa de ser trabalho manual quando não há nada a decidir.

- **`squad-migrate.py` reconcilia sozinho o delta sem BREAKING**: lê o changelog do plugin instalado entre a versão registrada no projeto e a atual, e classifica. Delta **sem** item marcado `[BREAKING]` → gravar o `SQUAD_VERSION` é ação **segura** (nada a decidir no projeto), executada com `--apply` e com linha de histórico dizendo o que foi incorporado. Delta **com** BREAKING → cada item vira ação a tratar e o bump **não** acontece: bump antes de tratar apaga o único sinal de que havia trabalho pendente (AM-35). Fecha o ciclo em que toda release nova defasava os projetos e a reconciliação era montada à mão
- **[fix] Detecção de BREAKING por marcador, não por palavra**: a primeira versão marcava a entrada da 1.11.0 como breaking porque o texto dela *menciona* "itens BREAKING" ao descrever o procedimento de reconciliação. É o mesmo erro que a UP-06 pegou no push-gate (substring confundindo menção com execução), agora em terceira forma — o critério passou a ser o marcador `[BREAKING]` entre colchetes

### 1.12.0 (2026-07-29)

Migração e atualização de projeto deixam de ser trabalho manual.

- **Novo `scripts/squad-migrate.py`**: diagnostica e migra um projeto para o plugin puro em qualquer estado (template clonado, híbrido, já puro) e em qualquer máquina. Dry-run por padrão; `--apply` executa só o que é determinístico. O critério não é "difere do plugin?" (quase sempre difere, o plugin evoluiu) e sim a **direção** da diferença contra a **união de todas as versões do cache, em escopo de diretório**: toda linha do arquivo local já vista em alguma versão → cópia defasada, seguro remover; linha que nenhuma versão teve → escalar. Escopo de diretório e versões antigas incluídas de propósito, para que conteúdo que apenas mudou de arquivo (trio de design → `/squad-design`) ou que o plugin removeu depois (ADR-005 reescrita) não conte como customização local — no primeiro caso real isso derrubou "arquivos para decidir" de 46 para 29
- Detecta sem tocar: `settings.json` com hooks locais (rodariam duplicados com os do plugin), contratos versionados na memória (AM-30), gate órfão (AM-34), `core.hooksPath` absoluto em repo com worktree (AM-38), governança defasada. **Nunca toca** `.claude/squad/project/`, `.env` ou código
- `/squad-init` → seção "Migração" reescrita: o passo manual de 5 itens virou o script + o que fazer com as decisões que ele levanta
- **Gate valida o AMBIENTE antes de medir qualidade**: `pre-commit-quality.example` ganhou pre-check que compara `engines.node` do projeto com o Node em uso e confere `node_modules`, abortando com mensagem acionável ("use `nvm use 22`") em vez de morrer no meio com erro do package manager. Motivo: nos 3 projetos da squad o gate estava vermelho por ambiente no mesmo dia (Node fora do range, `node_modules` incompleto, serviço de teste faltando) — gate que falha por ambiente vira obstáculo, e obstáculo ensina o hábito do `--no-verify`

### 1.11.0 (2026-07-29)

Backport da batalha em `trokey-franchising` (AM-36 a AM-41) — a primeira validação em campo da governança 1.9/1.10. **Resultado da batalha: o protocolo funcionou** — 12 achados no PR do marco M4 (2 MAJOR provados por execução) contra 291 testes verdes, num histórico de 24 PRs com zero achados.

- **[fix] Coletor de métricas media o que não existe (AM-39)**: `squad-metrics.sh` contava runs de CI que falharam com **0 steps executados** (billing esgotado, runner fora) — a média de uma sessão saiu **98.0** sem uma única falha de código. Agora descarta e reporta quantos descartou. Também: runs limitados à **janela de vida do PR** (PR cujo head é `develop`/`main` herdava o histórico inteiro da branch, mesma classe do UP-14), `retry` em erro transiente do `gh`, e nenhum truncamento silencioso
- **[fix] `achados-review=0` era ambíguo e o script celebrava zero**: não distinguia "reviewer rodou e não achou" (alarme, pela 1.9.0) de "reviewer nunca rodou". O coletor ainda imprimia `[OK] metas atingidas (achados=0…)` — resíduo do contrato pré-1.9.0 **dentro do código**. Nova saída reporta `revisoes` ao lado de `achados` com leitura tripla, e explicita o ponto cego: o reviewer da squad roda em sessão (subagent) e não posta review no GitHub, então `revisoes=0` significa "o dado não está aqui", não "o gate falhou"
- **Resume reporta a versão CARREGADA, não a instalada (AM-36)**: passo 0 agora informa as **três** — em execução (derivada do path do próprio `SKILL.md`), instalada, registrada no projeto — com ação por divergência. Sessão rodou 1.6.0 acreditando estar em 1.9.0 e o trabalho que dependia do protocolo novo rodou sob o antigo
- **Reconciliação deixa de ser só um aviso (AM-36/AM-37)**: passo 0b novo com procedimento de 5 passos — ler o changelog entre a versão registrada e a atual, derivar ações dos itens BREAKING, executar o mecânico, escalar o que é decisão, registrar o adiado. Antes, `/squad-resume` detectava a divergência e parava ali; as duas reconciliações reais foram montadas à mão
- **Trabalho dependente de versão só em sessão pós-upgrade (AM-37)**: regra no `tech-lead.md` — verificar a versão em execução ANTES de delegar estreia de protocolo ou spec recém-mudada, não depois de receber o resultado
- **Gate e testes em FOREGROUND (AM-40)**: delegação exige a instrução literal; subagent que lança em background e encerra reporta `completed` com o gate pendente. TL confere o disco (`git status`, marcador, arquivo esperado) — "completed" não é prova de execução
- **Retentativa de gate reseta estado compartilhado (AM-41)**: guidance em squad-core §M — sem reset (ou namespace de chaves por run), a segunda passada herda contador de rate-limit e cache da primeira, e flake ambiental vira falso QUEBRADO
- **[fix] 5 frases-eco do contrato pré-1.9.0** sobreviveram à Fase 0 nos 4 engineers e no security-engineer ("review = confirmação", "rede de segurança (confirmação)") — reincidência do UP-15, corrigida na varredura deste backport

### 1.10.0 (2026-07-28)

Fase 1 do plano de evolução: **dieta de tokens** — ~32% do sistema era gordura (duplicação, retórica, cerimônia). Squad-core vira fonte única; specs e skills enxutos sem perda de comportamento.

- **[BREAKING] Trio de design fundido em `/squad-design`**: as skills `/squad-design-system-new`, `/squad-design-extract` e `/squad-design-audit` (728 linhas, ~40% compartilhado) viram UMA skill com modos `new`/`extract`/`audit` (~100 linhas). Núcleo comum (baseline Path 1/2, governança de drift, formato de report) declarado uma vez
- **squad-core §H-§N (fonte única, rodada 2)**: flags (§H→ADR-003), fronteiras de segurança (§I), UI engineering (§J), DoD comum (§K), ciclo de versão do plugin (§L), snippet gate-ok canônico (§M), formato de skill (§N). Regra compartilhada vive num lugar; specs referenciam
- **tech-lead.md 1012→268 linhas**: fluxo de revisão narrado 1× (era 3×), gate de arquitetura 1× (era 2×), regimes de espera fundidos na matriz de autonomia, SOLID/OWASP devolvidos aos donos (CR/SE). Removida a frase "Review = confirmação" que contradizia o reviewer caçador da 1.9.0
- **15 specs de agentes enxutos** (advisor.md como régua): engineers 1917→622, QA/DevOps/Data/Support 1743→498, main-thread 2170→686. Intocáveis preservados e verificados: regras de evidência do QA (1.9.0), método Fase 1 do SE, lessons AM-*/UP-*, âncoras de seção citadas por skills
- **Skills sem cerimônia**: headers de governança morta removidos (rodapé §N de ≤3 linhas), skills que colavam conteúdo dos specs que citam agora referenciam (threat-model, incident, stack-decision, prd-template), anti-patterns-espelho cortados, templates de relatório em esqueleto
- **handoff mais barato**: TL escreve agent-memory direto (spawn só quando houve delegação real com contexto que o TL não viu); checklist §6 de double-pass removido
- **Bugs do diagnóstico**: B1 cabeçalhos de board inline no squad-init (referência fantasma); B2 links quebrados; B3 memory-update-reminder detecta EXECUÇÃO de commit, não menção (UP-06); B4 links `[${VAR}](...)` viram paths; B5 advisor `model: fable`

### 1.9.0 (2026-07-28)

Fase 0 do plano de evolução: **reviewer de verdade** — ataca a causa raiz de `achados-review=0` em 24 PRs (gate de review era teatro por desenho).

- **[BREAKING] code-reviewer reescrito como caçador de defeitos** (389→~95 linhas, molde do security-reviewer): protocolo de 3 passadas (mapa do diff + chamadores; caça dirigida por categoria; adversarial nos pontos de maior risco), `model: opus`, contrato de saída com `file:line` + cenário de falha concreto + severidade, mínimo de 5 hipóteses investigadas documentadas ("Caça documentada") em PR não-trivial. Removida a instrução "PR sem achados é o normal" (complacência por desenho)
- **QA executa ou não aprova**: aprovação exige comando executado + output real + cobertura extraída pelo próprio QA — auditar relatório do engineer não é validação. Cláusula "ajusta os testes" corrigida: nunca enfraquecer asserção para ficar verde
- **Mini-spec de feature (SDD leve)**: `specs/<ID>.md` por feature (contrato + critérios de aceite + cenários), criada por Architect+QA, consumida pelo engineer, cobrada pelo CR — template em `template/docs/feature-spec.md`
- **Anti-ancoragem**: TL entrega ao reviewer o diff cru + objetivo, nunca o resumo do engineer
- **Métrica desinvertida**: `achados-review=0` em 3+ PRs não-triviais consecutivos = alarme de gate morto no handoff, não sinal de saúde
- **Nova skill `/squad-audit`**: audit periódico code+security multi-passada com verificação adversarial dos achados
- **squad-core §G (loop fechado)**: toda delegação define critério de saída verificável por comando + limite de 3 iterações

### 1.8.0 (2026-07-26)

Simplificação e agilidade: menos bloqueio, mais aviso — o custo do falso positivo sai do usuário.

- **[BREAKING] push-gate vira ADVISORY por padrão (UP-05)**: avisa quando o gate não validou o HEAD (ou a branch tem PR mergeado — UP-01), mas **não bloqueia mais**. Commit, push e PR fluem sem interrupção. Racional: 4 falsos positivos em 2 sessões (tag, refspec, cross-repo, menção em mensagem) — bloqueio duro transferia o custo do erro do hook para o usuário. Modo enforce (bloqueio duro) é opt-in por projeto: `SQUAD_GATE_ENFORCE=1` no env ou arquivo `.claude/squad/project/gate-enforce`
- **push-gate reconhece EXECUÇÃO, não menção (UP-06)**: detecção de `git push` por primeiro verbo de cada segmento (`&&`, `;`, `|`, quebra de linha), com corpos de heredoc descartados — commit cuja mensagem cita `git push` não dispara mais o hook
- **`SQUAD_SKIP_GATE=1` aceito inline no comando (UP-04)**: o hook roda no processo do harness, antes do shell do comando existir — o prefixo inline nunca chegava ao env, tornando o escape documentado inacionável por agente
- **plugin-ci com runner parametrizável (UP-07)**: `runs-on: ${{ vars.CI_RUNNER || 'ubuntu-latest' }}` no próprio CI do plugin (o template já tinha via AM-25). Billing do Actions morto deixa de significar "suspender/restaurar branch protection para mergear": `gh variable set CI_RUNNER --body self-hosted` e o check roda local e fica verde de verdade. Princípio: check obrigatório precisa de caminho alternativo legítimo para o verde — gate que só se satisfaz sendo removido é ritual, não controle
- **Ciclo de atualização do plugin fecha nas duas pontas**: `/squad-handoff` (passo 9) roda `claude plugin update dev-squad` ao ENCERRAR a sessão — o restart que vem a seguir aplica de graça, e a próxima sessão já nasce na versão nova. `/squad-resume` (passo 0) confere na retomada e avisa se ainda há update pendente (rede de segurança para sessão que não teve handoff). Compara também com `SQUAD_VERSION` do projeto para apontar reconciliação pendente. Regressões já entraram por sessão rodando hook antigo (UP-01 no release da 1.6.0)
- **Delegação de merge (tech-lead.md)**: default continua "merge é do usuário", mas o usuário pode delegar ao TL explicitamente, com escopo e prazo, registrado em `DECISIONS_LOG` — expira sozinho, não sobrevive à sessão salvo prazo explícito
- **Advisor em Fable 5**: `model: claude-fable-5` no frontmatter do advisor (era `opus`)

### 1.7.0 (2026-07-26)

Backport das lições da batalha em `trokey-franchising` (AM-18 a AM-35).

- **[fix] push-gate volta a ser worktree-aware (AM-18 — regressão)**: o `PROJECT_ROOT` derivava de `$CLAUDE_PROJECT_DIR`, que aponta para a main worktree; subagents com `isolation: worktree` gravavam marcador legítimo em `.git/worktrees/<nome>/squad-gate-ok` e tinham o push bloqueado. O hook agora lê o `cwd` do payload do PreToolUse (fallback `$CLAUDE_PROJECT_DIR`/`$(pwd)`). O fix existia na 1.5.0 e **foi perdido na 1.6.0** ao adicionar o UP-01 sobre a base antiga; UP-01 preservado. Validado em 5 cenários (worktree com marcador válido passa; main sem marcador bloqueia; `SQUAD_SKIP_GATE=1` passa; não-push é no-op; contra-prova com o hook 1.6.0 bloqueando o caso legítimo)
- **Fonte única de contrato (AM-30)**: o Architect não versiona mais cópia do contrato em `.claude/squad/project/contracts/` — a fonte é o pacote de contratos do repo, e a memória guarda ponteiro. Snapshot legível, se necessário, é gerado no CI. `/squad-init` deixa de criar o diretório; 6 referências ao espelho atualizadas (README, security-engineer, security-reviewer, squad-scope-change, squad-new-project, tech-lead)
- **Contract-first via marco M0 (AM-19)**: ampliar contrato compartilhado exige PR só-de-contrato mergeado ANTES de paralelizar backend e frontend — elimina o mirror local e o rebase manual em cadeia
- **Gate encadeado, não sobrescrito (AM-34)**: `/squad-init` passo 5 detecta husky/lefthook/pre-commit e **encadeia** o `pre-commit-quality`, mantendo o `core.hooksPath` do gerenciador. Sobrescrever desligava o husky, então a instrução não era aplicada e o gate ficava órfão — arquivo presente, ninguém chamando
- **Fechamento por efeito, não por existência (AM-35)**: ação corretiva só vira `[OK] Aplicado` com efeito observado uma vez (tabela de critérios no `tech-lead.md`); `/squad-resume` passa a conferir na retomada se o marcador do gate bate com o `HEAD`
- **Alteração de contrato compartilhado (AM-28)**: a delegação passa a exigir varredura dos construtores inline do payload (helpers de teste e `.send({...})` em e2e de outros módulos) no mesmo marco; o gate que vale é o completo do TL, com aviso sobre pipe mascarando exit code
- **Subagente em worktree DEVE commitar (AM-27)**: "sem push, sem PR" era lido como "sem commit" e deixava trabalho untracked que o `git worktree remove --force` apaga. Explicitado no `tech-lead.md` e no `backend-engineer.md`
- **Memória não duplica o repo (AM-31)**: regra geral no `tech-lead.md` — cópia de artefato vivo sem gerador diverge em silêncio e mente pior que a ausência
- **Diagnóstico Testcontainers × contexto do Docker (AM-32/33)** no `backend-engineer.md`: `docker info` verde não prova runtime para o Testcontainers (contexto vs socket fixo)
- **CI com runner parametrizável (AM-25)**: `runs-on: ${{ vars.CI_RUNNER || 'ubuntu-latest' }}` no template — um flip de variável tira o CI do cloud quando o billing trava, sem editar workflow

### 1.6.0 (2026-07-25)
- **Subagents nativos**: 10 executores (backend/frontend/mobile/data/ai/devops engineer, qa-engineer, code-reviewer, security-reviewer, support-engineer) viram agentes nativos do plugin em `agents/` — modelo por papel resolvido pelo frontmatter (`model: sonnet`/`opus` → sempre a versão mais recente), tools restritas por mecanismo (reviewers e advisor read-only), contexto isolado por delegação. Papéis de decisão (TL, PO, Architect, PD, SE Fase 1) permanecem main-thread em `template/agents/`
- **Security split**: Fase 1 (threat model, decisão com usuário) main-thread; Fase 2 (revisão pós-implementação) = subagent `security-reviewer` Opus read-only que lê os checklists do spec do SE (single source)
- **Advisor**: subagent Opus read-only de segunda opinião — TL/PO/PD/Architect/SE acionam em dúvida genuína (2+ opções defensáveis, custo de errar alto); contexto limpo elimina viés de ancoragem
- **Protocolo de Dúvida** (squad-core §F): subagent com dúvida bloqueante PARA e retorna `Dúvidas:` no relatório — nunca inventa; TL responde e continua a mesma execução
- **Modo Delegado** (TL → Matriz de Autonomia): usuário declara delegação explícita → só a lista crítica interrompe (irreversível/destrutivo, dinheiro, segurança, contrato público, escopo, arquitetura nível ADR); resto decide + registra `[AUTO]` no DECISIONS_LOG; gates de qualidade seguem mecânicos
- **UP-01**: push-gate bloqueia push em branch cujo PR já está MERGED/CLOSED (branch morta = trabalho invisível); fail-open sem `gh`

### 1.5.0 (2026-07-05)
- **Rename**: plugin `squad` → **`dev-squad`** (skills mantêm o prefixo `/squad-*`). Quem instalou como `squad`: `claude plugin uninstall squad@pdati` → `claude plugin marketplace update pdati` → `claude plugin install dev-squad@pdati`

### 1.4.0 (2026-07-05)
- **Estética e fluidez**: integração com o plugin oficial `frontend-design` da Anthropic (dependência declarada, instalada pelo `/squad-init` em projeto com UI); PD ganha passo 5a "Direção estética" (framework propósito/tom/constraints/diferenciação + 3-4 direções pro usuário escolher + referências do dono); mini-spec herda a direção; review de tela crítica reprova slop mesmo aderente aos tokens; self-review §5 exige micro-interações/transições (`prefers-reduced-motion` respeitado); react.md com regra anti-slop e motion como parte do Done

### 1.3.0 (2026-07-05)
- **Governança vira mecanismo**: hook `push-gate` bloqueia `git push` sem gate determinístico rodado no HEAD (marcador gravado pelo `pre-commit-quality`; escape `SQUAD_SKIP_GATE=1`); `/squad-init` INSTALA os gates (hook local + `squad-ci.yml` do projeto com TODO(stack) que falha até ser preenchido)
- **O plugin se testa**: workflow `plugin-ci` no upstream (validate, frontmatter das skills, smoke dos hooks, checker de referências internas)
- **Métricas coletadas, não auto-relatadas**: `scripts/squad-metrics.sh` (achados de review, ciclos de CI, retrabalho via gh api); handoff e /squad-status usam o coletor — auto-relato vira fallback explícito

### 1.2.0 (2026-07-05)
- **Dedup de specs (D2)**: seções repetidas dos 14 agentes extraídas para `template/docs/squad-core.md` (§A guardrail de interação, §B agent memory, §C cobertura por modo, §D self-review comum, §E formato de resposta ao TL) — ~480 linhas a menos no total dos specs; cada spec mantém só o que é específico do papel

### 1.1.0 (2026-07-05)
- **IA no centro**: seção "Produto de IA" no PRD (custo/interação como RNF, evals, guardrails); `stack-conventions/ai/` (anthropic, rag, evals); gate "sem eval → feature de IA incompleta"; checklist OWASP LLM Top 10 no Security; ADR-006-arquitetura-ia; observabilidade de IA no DevOps
- **Frontend**: mini-spec do PD obrigatória pra toda tela; checklist visual (self-review §5); gate "rodou e olhou" (screenshots dos 4 estados); ADR-005 v2 (default web = shadcn/ui + Tailwind); biblioteca de page-patterns
- **Semiautonomia**: Matriz de Autonomia (autônoma/lote/gate) + checkpoint de aprovações em lote no TL; métricas de saúde da squad no handoff e no /squad-status

### 1.0.1 (2026-07-05)
- Hook SessionStart injeta persona Tech Lead em projeto com squad inicializada

### 1.0.0 (2026-07-05)
- Release inicial: 15 skills, 14 agentes, 3 hooks, template completo (pós-diagnóstico LESSONS_LEARNED P0+P1+P2)

## Origem

Extraído do repositório `template-project` após diagnóstico de lições aprendidas em projeto real (ver `docs/DIAGNOSTICO_LESSONS_SQUAD.md` no repo). v1.0.0 = estado pós-aplicação P0+P1+P2 do diagnóstico.
