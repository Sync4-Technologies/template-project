# Plugin `dev-squad` — AI Software Squad

Governança completa para projetos conduzidos por squad de agentes Claude Code: 5 papéis main-thread + 11 subagents nativos, 16 skills, hooks de memória viva e templates de qualidade.

## Instalação

```bash
# 1. Adicionar o marketplace (uma vez por máquina; lê a branch default do repo)
/plugin marketplace add Sync4-Technologies/template-project

# 2. Instalar o plugin (escopo user — vale pra todos os projetos da máquina)
/plugin install dev-squad@pdati

# 3. Verificar
claude plugin list              # dev-squad@pdati — enabled
claude plugin details squad     # 16 skills, 3 hooks, ~870 tok always-on

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
| Specs main-thread (5) + subagents nativos (11), 16 skills, 3 hooks, docs (self-review, stack-conventions, design-system), templates (PRD, ADR, LESSONS_LEARNED), CI examples | `.claude/squad/project/` — ARCHITECTURE, TASK_BOARD, DECISIONS_LOG, ADRs do projeto, agent-memory, LESSONS_LEARNED, contracts, `SQUAD_VERSION` |

**Regra de governança:** não editar arquivos do plugin dentro de um projeto. Gap no sistema da squad → registrar no `LESSONS_LEARNED.md` do projeto (skill `/squad-handoff`, step 2c) → backportar aqui (upstream) → nova versão → projetos atualizam explicitamente. Isso fecha o ciclo de drift que motivou o plugin.

## Versionamento

- SemVer. Toda mudança de comportamento de agente/skill/hook = bump de versão + entrada no changelog do repo.
- Cada projeto grava a versão em uso em `.claude/squad/project/SQUAD_VERSION` — auditável qual governança valia em cada fase.
- Update é ação explícita do usuário (`/plugin` → update), nunca silencioso.

## Migração de projetos com template clonado (layout legado)

Rodar `/squad-init` no projeto — a skill detecta o layout legado, preserva `.claude/squad/project/`, remove as cópias locais de template/skills/hooks (com confirmação) e grava `SQUAD_VERSION`.

## Changelog

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
