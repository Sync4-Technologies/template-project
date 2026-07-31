# Licoes Aprendidas — template-project (upstream da dev-squad)

> Documento vivo do SISTEMA da squad. Escopo e formato: `plugin/template/LESSONS_LEARNED-template.md`.
> Ultima atualizacao: 2026-07-26

---

## 1. Push em branch de PR ja mergeado gera commit orfao (severidade: MEDIO)

### O que aconteceu

Commit `e3369f9` (guia de instalacao) foi pushado na branch do PR #12 minutos DEPOIS do merge — ficou fora do develop sem ninguem notar; exigiu PR #13 dedicado.

### Causa raiz

Processo: nenhum passo verifica o estado do PR antes de push em branch que tem PR associado. A licao AM-64 (re-verificar contra o remoto) cobria resume, nao push.

### Acao corretiva

| ID | Acao | Arquivo a modificar | Status |
|----|------|---------------------|--------|
| UP-01 | Antes de push em branch com PR: `gh pr view --json state` — MERGED/CLOSED -> novo PR, nao push na branch morta. Candidato a check no hook push-gate (v1.6) | `plugin/hooks/push-gate.sh` | Feito (v1.6.0) |

### Principio

Branch de PR mergeado esta morta — push nela e trabalho invisivel.

---

## 2. UP-01 bloqueia push de TAG a partir de branch com PR mergeado (severidade: BAIXO)

### O que aconteceu

Release da propria v1.6.0: `git push origin v1.6.0` rodou a partir da branch cujo PR #31 acabara de ser mergeado. So passou porque a sessao ainda rodava o hook 1.5.0 (sem UP-01). Com 1.6.0 ativo, o release teria sido bloqueado — falso positivo: o check olha o PR da BRANCH, nao o refspec pushado.

### Causa raiz

`push-gate.sh` (UP-01) nao distingue push de branch de push de tag/refspec explicito.

### Acao corretiva

| ID | Acao | Arquivo a modificar | Status |
|----|------|---------------------|--------|
| UP-02 | Isentar do check UP-01 pushes cujo refspec e tag (`git push origin vX.Y.Z`, `--tags`) ou que nao empurram a branch atual | `plugin/hooks/pre-bash.sh` | Implementado na FASE 2 (fusao dos hooks); chega a main na v2.0.0. Coberto por `scripts/ci/pre-bash-cases.sh` nos dois sentidos: tag/--tags/outra-branch nao disparam, `main:main` e `HEAD` ainda disparam |

### Principio

Gate novo se testa contra o proprio fluxo de release antes de valer — o refspec importa, nao so a branch corrente.

---

## 3. push-gate valida o repo da SESSAO, nao o repo do push (severidade: ALTO)

### O que aconteceu

Sessao aberta no `template-project`; trabalho de reconciliacao feito no `trokey-franchising` via `cd /Users/.../trokey-franchising && git push ...`. O gate do trokey foi rodado por inteiro e passou (170 suites, 1370 testes), gravando o marcador correto: `squad-gate-ok` == `HEAD^{tree}` == `1827245`.

O push foi bloqueado assim mesmo. `CLAUDE_PROJECT_DIR` estava VAZIO, entao o hook caiu no fallback `$(pwd)` — o cwd do processo do harness, que e o worktree do `template-project`. Resultado: leu o marcador (inexistente) e o HEAD do `template-project` e barrou um push cujo gate estava legitimamente verde, em outro repositorio, que ele nunca olhou.

Agravante: nenhuma saida legitima sobra pro agente. `SQUAD_SKIP_GATE=1` inline nao chega ao hook (ele le o env do processo do harness, que existe antes do shell do comando — ver AM-23 do trokey). A unica saida ao alcance seria escrever o marcador do repo errado na mao, ou seja, forjar a atestacao. Push teve que ser delegado ao terminal do usuario.

### Causa raiz

**REGRESSAO, nao bug novo.** A 1.5.0 ja resolvia isto:

```sh
PROJECT_ROOT="${CWD:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"   # 1.5.0 — le `cwd` do payload
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"           # 1.6.0 — worktree-awareness perdida
```

O comentario da 1.5.0 nomeava o bug: *"`cwd` e a worktree onde o `git push` esta sendo executado — usar isso em vez de `$CLAUDE_PROJECT_DIR` corrige o bug worktree-blind"*. A 1.6.0 adicionou o UP-01 partindo de uma base sem o fix e perdeu tres blocos: a leitura de `cwd`, a checagem dupla de squad (PROJECT_ROOT + CLAUDE_PROJECT_DIR) e o comentario que proibia `--git-common-dir`.

O sintoma que observei (cross-repo) e o mesmo que o AM-18 do trokey descreve para subagent em worktree isolada: o hook le o marcador do lugar errado. Uma causa, dois sintomas.

**O payload ja traz `cwd`** — nao ha o que parsear do comando. A correcao e RESTAURAR o codigo da 1.5.0, nao inventar parsing de `cd`.

Terceiro sintoma do mesmo hook em duas sessoes (UP-01 tag, UP-02 refspec, UP-03 cross-repo). Pelo criterio do proprio LESSONS do trokey (AM-22: workaround repetido e sinal de modelo errado), o padrao ja pede revisao do desenho, nao um quarto remendo pontual.

**Quarto furo, descoberto ao escrever esta propria licao:** o commit que registra UP-03 foi BLOQUEADO pelo push-gate. O comando era `git switch && git add && git commit -F -`, sem nenhum push — mas o heredoc da mensagem citava `` `cd <repo> && git push` `` ao descrever o bug. O teste do hook e `case "$CMD" in *"git push"*)`, substring na string inteira do comando: qualquer commit, script ou documentacao que MENCIONE `git push` e tratado como push. O gate barra quem escreve sobre ele.

### Acao corretiva

| ID | Acao | Arquivo a modificar | Status |
|----|------|---------------------|--------|
| UP-03 | RESTAURAR o codigo da 1.5.0: ler `cwd` do payload e usar como PROJECT_ROOT (`${CWD:-${CLAUDE_PROJECT_DIR:-$(pwd)}}`), mais a checagem dupla de squad e o comentario `--git-dir` vs `--git-common-dir`. NAO parsear `cd` do comando — o payload ja traz `cwd` | `plugin/hooks/push-gate.sh` | Feito (v1.7.0) — PR #36, merge `e5a8e22`. UP-01 preservado; validado em 5 cenarios com contra-prova |
| UP-04 | Ler `SQUAD_SKIP_GATE` tambem de `tool_input.command` (o payload ja traz a string), nao so do env do processo — hoje o escape documentado e inacionavel por agente | `plugin/hooks/push-gate.sh` | Feito (v1.8.0) |
| UP-05 | Revisar o desenho do push-gate como um todo (4 falsos positivos em 2 sessoes) antes de aceitar novo remendo pontual | `plugin/hooks/push-gate.sh` | Feito (v1.8.0) — decisao do usuario: ADVISORY por padrao (avisa, nao bloqueia); enforce opt-in por projeto |
| UP-06 | Match de `git push` nao pode ser substring da string inteira: bloqueia commit cuja MENSAGEM cita `git push`. Parsear o comando efetivo (primeiro verbo por segmento `&&`/`;`/`\|`) e ignorar corpo de heredoc/aspas | `plugin/hooks/push-gate.sh` | Feito (v1.8.0) |

### Principio

Hook que le o comando para decidir SE atua tem que ler o mesmo comando para decidir SOBRE O QUE atua. Inferir o alvo por contexto de processo enquanto o alvo real esta escrito no comando produz falso positivo silencioso — e um gate cuja unica saida acionavel e forjar o marcador ensina exatamente o que ele existe para impedir.

Corolario do quarto furo: reconhecer comando por substring confunde MENCAO com EXECUCAO. O gate precisa parsear o que vai rodar, nao procurar texto no que foi digitado.

---

## 4. Required check que so fica verde apagando a protection e ritual, nao controle (severidade: ALTO)

### O que aconteceu

Billing do GitHub Actions esgotado: todos os jobs falham com 0 steps. Os 4 required checks do repo ficam vermelhos por infra, nao por codigo. Para mergear os PRs #33, #34, #35 e #36, o fluxo foi: DELETE dos required_status_checks -> merge -> PUT restaurando a protection. Quatro vezes no mesmo dia, a mao, com janela em que a branch aceitava merge sem CI nenhum.

Pergunta do usuario que resume o problema: "qual o sentido de bloquear, se vou contornar apagando?"

### Causa raiz

O check obrigatorio tinha UM caminho para o verde (GHA cloud). Quando esse caminho morre por causa externa, o gate nao degrada — vira obstaculo que so se satisfaz sendo removido. O trokey ja tinha resolvido isso no proprio ci.yml (AM-25): `runs-on` parametrizado por variavel de repo, roteando para runner self-hosted com um flip. O plugin-ci deste repo nao tinha o mesmo fallback.

### Acao corretiva

| ID | Acao | Arquivo a modificar | Status |
|----|------|---------------------|--------|
| UP-07 | plugin-ci com `runs-on: ${{ vars.CI_RUNNER \|\| 'ubuntu-latest' }}` — billing morto vira `gh variable set CI_RUNNER --body self-hosted`, check roda local e fica verde de verdade | `.github/workflows/plugin-ci.yml` | Feito (v1.8.0) |
| UP-08 | Registrar o runner self-hosted na maquina do Pablo (de preferencia a nivel de ORG Sync4-Technologies, servindo template-project e trokey com um runner so) — sem isso o UP-07 e so a tomada na parede | acao do usuario (runbook: trokey `ops/self-hosted-runner.md`) | Feito (2026-07-26: runner `sync4-mac-local` org-level online; CI_RUNNER=self-hosted em template-project, trokey, concilia, contracts-; prova de efeito: PR #41 com 4/4 jobs verdes no runner) |
| UP-10 | `actions/setup-python` quebra em runner self-hosted macOS: instalador do toolcache exige sudo E assume `/Users/runner` (so existe no runner cloud). `AGENT_TOOLSDIRECTORY` via `.env` nao propagou. Fix: `if: ${{ vars.CI_RUNNER == '' }}` no setup-python e no pip install — self-hosted usa o python3 da maquina (mesmo interpretador dos checks locais) | `.github/workflows/plugin-ci.yml` | Feito (PR #41) |

### Principio

Check obrigatorio precisa de caminho alternativo LEGITIMO para o verde. Se a unica saida quando a infra falha e remover o check, o check nao protege nada nesses momentos — só treina todo mundo a remover. Mesmo principio do AM-23 do trokey (gate sem caminho de conformidade acionavel), agora na camada de CI.

---

## 5. Gate de review sem metodo nem contrato de evidencia = teatro (severidade: ALTO)

### O que aconteceu

achados-review=0 em 24 PRs ao longo de 3 sessoes, enquanto audits externos pedidos pelo usuario achavam "muitas falhas". Auto-analise (2026-07-28, docs/PLANO_EVOLUCAO_SQUAD.md) achou a causa no DESENHO: code-reviewer instruido a ser "confirmacao, nao descoberta" com "PR sem achados e o normal"; handoff codificava `achados-review — meta 0`; CR em model sonnet; QA nunca executava nada (auditava relatorio do engineer); TL entregava resumo do engineer ao reviewer (ancoragem).

### Causa raiz

Metrica invertida + prompt de confirmacao + ausencia de protocolo de caca e de contrato de evidencia. O sistema PEDIA zero achados e recebia exatamente isso.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-12 | Fase 0 do plano: reviewer cacador (3 passadas, opus, file:line + cenario + Caca documentada), QA executa-ou-nao-aprova, mini-spec SDD, anti-ancoragem no TL, metrica desinvertida (0 em 3+ PRs nao-triviais = alarme), /squad-audit, squad-core par.G loop fechado | plugin/agents/code-reviewer.md, qa-engineer.md, tech-lead.md, squad-handoff, squad-core, squad-audit | Feito (v1.9.0) — prova de efeito pendente: batalha trokey |

### Principio

Metrica cuja meta e zero achados treina o gate a nao achar. Gate de qualidade se mede pelo que ENCONTRA e documenta (caca), nao pelo que aprova. Zero saudavel so existe com caca documentada.

---

## 6. Tag de release antes de confirmar o merge aponta pro commit errado (severidade: BAIXO)

### O que aconteceu

Release v1.9.0: `gh pr merge 44` retornou mensagem pedindo `--admin` (falha transiente de propagacao de checks) e NAO mergeou; o comando seguinte tagueou `origin/main` — que ainda era o main ANTIGO. Tag v1.9.0 nasceu apontando para o release anterior. Detectado na hora (marketplace reportou "already at 1.8.1"), corrigido com tag -f + push -f.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-11 | Fluxo de release: apos `gh pr merge`, SEMPRE confirmar `gh pr view --json state == MERGED` E `git fetch && git log -1 origin/main` conter o merge ANTES de taguear. Encadear merge+tag num comando so e proibido | skills squad-handoff/resume (fluxo de release) + agent-memory tech-lead | Registrado (fix de skill vai na Fase 1) |

### Principio

Tag e imutavel na percepcao dos consumidores — nasceu errada, alguem ja pode ter baixado. Confirmar o estado remoto entre cada par de passos irreversiveis do release.

---

## 7. Release sem changelog no README passa em todos os gates (severidade: BAIXO)

### O que aconteceu

v1.9.0 released completa (CI verde, tag, marketplace) sem entrada de changelog no plugin/README.md — nenhum check cobra; gap so foi notado no resume da sessao seguinte. Consumidor que atualiza nao tem como saber o que mudou sem ler git log do upstream.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-13 | Changelog da versao no README como passo explicito do fluxo de release | ARCHITECTURE.md (fluxo de release) | Feito (2026-07-28: fluxo atualizado; changelog 1.9.0 escrito retroativamente na v1.10.0) |

### Principio

Passo de release que nenhum gate cobra e passo que some sob pressao. Ou vira item do fluxo escrito, ou vira check.

---

## 8. plugin-ci duplicava suite em PR cujo HEAD e develop/main (severidade: MEDIO)

### O que aconteceu

Gatilhos `push: [develop, main]` e `pull_request: [develop, main]` sobrepostos. Quando o HEAD do PR e a propria develop/main (release `develop->main`, sync `main->develop`), o SHA ja tinha suite do evento `push` (do merge anterior) e ganhava outra do `pull_request` — DUAS suites no MESMO SHA. Com required checks, o PR fica BLOCKED ate a segunda fechar, mesmo com a primeira 4/4 verde: #44, #46 e #49 (v1.10.0).

**Diagnostico refinado por medicao** (`gh api .../check-runs`, contagem de `check_suite.id` unicos): PR de feature branch = 1 suite (#47, #48, #50); PR com head develop/main = 2 (#49, #51). A anotacao original dizia "todo PR duplica" — era generalizacao a partir dos casos visiveis (que eram todos releases). Medir antes de corrigir mudou o fix.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-14 | `push` restrito a `main` (verificacao pos-merge do release); `pull_request` cobre os PRs. Nada entra em develop/main fora de PR (enforce_admins), entao push em develop era so re-execucao | .github/workflows/plugin-ci.yml | Feito (2026-07-28) |

### Principio

Gate duplicado nao e rigor em dobro — e custo em dobro e sinal pela metade. E: contar o fenomeno antes de corrigi-lo; a hipotese formada no calor do bloqueio descreveu o sintoma, nao a causa.

---

## 9. Reescrita de spec quebra consumidores em silencio: frases-eco e ancoras (severidade: MEDIO)

### O que aconteceu

Na Fase 1 (dieta), dois modos de quebra silenciosa: (a) a Fase 0 reescreveu o code-reviewer mas a frase-eco "Review = confirmacao, nao descoberta" SOBREVIVEU no tech-lead.md — dois arquivos ativos com contratos de review opostos por 1 release; (b) skills citam specs por ancora `arquivo -> "Secao"` e a reescrita renomeou headings — 5 ancoras quebraram (3 do proprio TL), + 2 ja estavam mortas de releases anteriores (flag-audit). check-plugin-paths valida paths, nao ancoras.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-15 | Reescrita de spec exige, no mesmo PR: grep de frases-eco do contrato antigo nos demais arquivos + verificacao das ancoras `-> "Secao"` que apontam pro arquivo reescrito | processo (delegacao de reescrita); candidato a check de CI (ancoras) na Fase 2/3 | Aplicado a mao na Fase 1 (5 realinhadas + 2 mortas corrigidas); check automatico pendente |

### Principio

Contrato entre arquivos vive nos DOIS lados. Reescrever um lado sem varrer o outro deixa o sistema contando duas historias.

---

## 10. Coletor de metricas media 98.0 sem uma falha de codigo; e celebra zero achados (severidade: ALTO)

### O que aconteceu

Backport da batalha trokey (AM-39). O `squad-metrics.sh` produzia numeros sem sentido por tres causas independentes, todas confirmadas com dado real:

1. **Runs de 0 steps contavam como ciclo de CI** — billing esgotado/runner fora derruba o job sem executar nada; media da sessao trokey saiu **98.0** sem uma unica falha de codigo. Medido no upstream: **57 runs** descartaveis nos ultimos 3 PRs.
2. **PR cujo head e branch longeva herdava o historico inteiro dela** — sync `main->develop` e release `develop->main` consultavam `head_branch=main`, trazendo TODAS as falhas historicas da branch. Mesma classe do UP-14 (head develop/main se comporta diferente).
3. **`achados-review=0` era ambiguo** — nao distinguia "reviewer rodou e nao achou" (ALARME pela 1.9.0) de "reviewer nunca rodou" (o caso do trokey). Pior: o script imprimia **`[OK] metas atingidas (achados=0...)`**, ou seja, o coletor continuava celebrando zero DEPOIS de a Fase 0 ter desinvertido a metrica na documentacao — frase-eco da mesma classe da UP-15, agora em codigo.

Descoberto tambem que o reviewer da squad roda **em sessao** (subagent) e nao posta review no GitHub: coletar do GitHub subestima por desenho. A batalha teve 12 achados reais e o GitHub mostra 0 revisoes.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-16 | Coletor: descartar runs sem steps (reportando quantos), limitar runs a janela de vida do PR, reportar `revisoes` ao lado de `achados`, trocar o `[OK] achados=0` pela leitura tripla (0 revisoes = dado ausente / 0 achados com revisao = alarme / achados>0 = sinal), retry em erro transiente do `gh`, e nunca truncar em silencio | `plugin/scripts/squad-metrics.sh` + `squad-handoff` 5d | [OK] 2026-07-29 — provado no dado: trokey **98.0 -> 2.0** (e o 2.0 tem causa real: flake do vehicle-lookup), upstream 1.0 |

### Principio

Metrica que nao distingue "nao aconteceu" de "aconteceu e deu zero" nao mede nada — e coletor que imprime elogio contradizendo a regra vigente ensina a ignorar a regra. Contar so o que teve trabalho real; expor o ponto cego em vez de reportar zero confortavel.

---

## 11. Detectar divergencia de governanca nao e reconciliar (severidade: ALTO)

### O que aconteceu

`/squad-resume` comparava `SQUAD_VERSION` com a versao instalada e avisava "reconciliacao pendente" — e parava ali. Nao havia procedimento: nas duas reconciliacoes reais (trokey 1.4->1.6 e 1.6->1.10) a lista de acoes foi montada **a mao pelo TL**, lendo git log e changelog do upstream. Sem isso, o aviso e ruido: o projeto segue rodando governanca velha com a divergencia registrada.

Agravante da mesma familia (AM-36): a sessao reportava a versao **instalada**, nao a **em execucao**. Sessao trokey rodou 1.6.0 acreditando estar em 1.9.0 — o trabalho que dependia do protocolo novo rodou sob o antigo.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-17 | `/squad-resume` passo 0: reportar SEMPRE as tres versoes (em execucao — derivada do path do proprio SKILL.md — - instalada - registrada no projeto) com tabela de acao por divergencia (AM-36) | `plugin/skills/squad-resume/SKILL.md` | [OK] 2026-07-29 |
| UP-18 | `/squad-resume` passo 0b: procedimento de reconciliacao em 5 passos — ler o changelog entre a versao registrada e a atual, derivar acoes dos BREAKING, executar o mecanico, escalar o que e decisao, registrar o adiado no DECISIONS_LOG | `plugin/skills/squad-resume/SKILL.md` | [OK] 2026-07-29 |
| UP-19 | Regra do TL: trabalho que depende da versao da governanca so comeca em sessao iniciada DEPOIS do upgrade — verificar antes de delegar (AM-37) | `plugin/template/agents/tech-lead.md` | [OK] 2026-07-29 |

### Principio

Aviso sem procedimento vira paisagem. E versao "instalada" nao governa nada — governa a que esta carregada no processo; reportar a errada e pior que nao reportar, porque cria confianca falsa.

---

## 12. Alinhar memoria numa branch com texto DIFERENTE do da outra garante conflito na release (severidade: MEDIO)

### O que aconteceu

UP-14 e o item 3.3 foram mergeados so em `develop` (release adiada por decisao do usuario). Os arquivos de memoria foram no mesmo PR, entao `main` passou a servir o diagnostico ANTIGO da UP-14. Para corrigir isso o TL abriu o PR #53 levando **so os arquivos de memoria** para main — com o texto **reescrito** ("implementado em develop, aguarda release" em vez de "Feito"), porque em main o fix ainda nao existia e marcar `Feito` violaria AM-35.

O raciocinio estava certo e o resultado foi um conflito garantido: as duas branches passaram a ter edicoes divergentes nas MESMAS linhas. O TL previu em voz alta que "o merge da proxima release reconcilia naturalmente" — nao reconciliou: o PR #55 (release) abriu com `CONFLICT` em `LESSONS_LEARNED.md` e `PLANO_EVOLUCAO_SQUAD.md`, e a resolucao teve que ser manual (branch de resolucao + PR extra).

### Causa raiz

Duas verdades simultaneas sobre o MESMO texto (em main o fix nao existe; em develop existe) foram escritas como duas versoes do texto. Merge de arquivo nao sabe qual "verdade" vence — ve duas edicoes concorrentes na mesma linha.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-22 | Status de acao corretiva escrito de forma **branch-agnostica e imutavel**: `Implementado no PR #NN; chega a main na vX.Y.Z` — vale nas duas branches ao mesmo tempo, nao precisa ser reescrito quando a release sai, e nao conflita. Alternativa aceitavel: NAO levar memoria para main fora da release e aceitar a janela de defasagem, registrando-a no Current Focus (1 linha) | processo de release (ARCHITECTURE.md) + habito de escrita do LESSONS | [OK] 2026-07-29 — resolucao do #55 adotou o lado do develop; regra registrada |

### Principio

Memoria e arquivo versionado: manter duas redacoes do mesmo fato em duas branches nao e "cada uma diz sua verdade", e conflito agendado. Escrever o status em forma que sobreviva ao merge (referencia ao PR e a versao, nunca "esta/nao esta aqui") custa uma frase e economiza um PR de resolucao.

---

## 13. Reconciliacao automatizavel ficou de fora da release em que foi prometida (severidade: BAIXO)

### O que aconteceu

Ao explicar por que o `SQUAD_VERSION` nao se atualizava sozinho, o TL desenhou a solucao (auto-bump quando o delta nao tem BREAKING), disse "vale implementar na proxima release" — e cortou a v1.12.0 SEM ela. O usuario cobrou na sessao seguinte. Nada se perdeu, mas a promessa virou divida invisivel: nao estava em card, nem em lesson, nem no plano.

Ao implementar, o proprio codigo repetiu a UP-06 em TERCEIRA forma: a deteccao de BREAKING usava `"BREAKING" in linha`, e a entrada da 1.11.0 — que descreve o procedimento de reconciliacao e cita "itens BREAKING" no texto — foi marcada como breaking. Mencao tratada como marcacao, de novo. Criterio corrigido para o marcador `[BREAKING]` entre colchetes.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-23 | Proposta de melhoria aceita em conversa vira CARD no board na hora, nao promessa no meio de um paragrafo — senao a release seguinte sai sem ela e ninguem lembra | TASK_BOARD (habito do TL) | [OK] 2026-07-29 |
| UP-24 | Reconciliacao automatica do delta sem BREAKING (`squad-migrate --apply` grava o SQUAD_VERSION); com BREAKING nao grava, so lista as acoes | plugin/scripts/squad-migrate.py + squad-resume 0b | [OK] 2026-07-29 (v1.13.0) |
| UP-25 | Pre-check respeita operador do range de engines.node + roda depois do `cd` (bloqueava TODO push com range aberto) | template/ci/pre-commit-quality.example | [OK] 2026-07-30 |
| UP-26 | Teste de guarda exige caso adversarial (o que ela reprova errado), nao so o que aprova certo | processo + qa-engineer.md | [OK] registrado; backport pendente |
| UP-27 | Porte de codigo executavel do template exige execucao no ambiente real (AM-46 trokey) | squad-resume 0b + tech-lead.md | Pendente |
| UP-28 | Teste que roda dentro de hook do git tem que dar `unset GIT_DIR/GIT_INDEX_FILE`: `git -C` NAO sobrepoe essas vars | scripts/ci/pre-bash-cases.sh | [OK] 2026-07-30 |
| UP-29 | Gate "CR aprovou" existe na tabela do CLAUDE.md mas NENHUM passo do fluxo de release aciona o reviewer — rodou por proposta avulsa e achou 2 MAJOR | tech-lead.md fluxo de release + CLAUDE.md | Pendente |
| UP-30 | Handoff que fica so em `develop` e invisivel para quem retoma de `main` (branch default): os anteriores chegavam de carona nas releases | /squad-handoff passo 8 | Pendente |
| UP-31 | Testar "nos dois sentidos" nao basta quando as duas direcoes compartilham a MESMA premissa nao examinada (7 cenarios do pre-check, todos com range COM espaco) | template/ci/pre-commit-quality.example + qa-engineer.md | Pendente |

### Principio

"Fica pra proxima" dito em prosa nao sobrevive a release. E reconhecer comando/marcador por substring erra sempre do mesmo jeito: o texto que FALA sobre a coisa e confundido com a coisa. Terceira ocorrencia (push-gate, coletor de metricas, changelog) — o padrao agora e conhecido: marcador delimitado, nunca palavra solta.


## 14. Testei so o caso que confirmava meu desenho — e entreguei um gate que bloqueava todo push (severidade: ALTO)

### O que aconteceu

O pre-check de ambiente que eu adicionei na v1.12.0 tinha DOIS defeitos, e o primeiro **abortava todo `git push`** em qualquer projeto cujo `engines.node` fosse um range aberto:

1. **Comparacao ignorava o operador do range.** O parser pegava o primeiro numero de `">=22"` e comparava com IGUALDADE contra o major em uso. Node 26 satisfaz `>=22`, mas o gate abortava com "pede major 22" — e a mensagem oferecia `--no-verify` como saida. **Um pre-check cujo proposito declarado era "obstaculo ensina o habito do --no-verify" virou exatamente esse obstaculo, e ainda ensinava a burla.**
2. **Rodava ANTES do `cd` para a raiz** do repo, lendo `package.json`/`node_modules` do diretorio de onde o hook foi chamado.

Nao fui eu que descobri: outra sessao (trokey, PR #96) quebrou o gate em `main`, diagnosticou e corrigiu, registrando AM-46/AM-47 com "backport URGENTE". Eu ia encerrar a sessao sem isso — os 3 projetos reconciliam para 1.13.0 na proxima sessao e herdariam o gate quebrado.

**Causa raiz do MEU erro:** testei tres cenarios e todos confirmavam o desenho — `">=22.0.0 <23.0.0"` com Node 26 (reprova certo), `node_modules` ausente (reprova certo), ambiente OK (passa). **Nunca testei range aberto.** Testei o caminho que validava minha hipotese e chamei de "testado nos 3 cenarios" no proprio PR. E o viés de confirmacao que eu passei o dia inteiro consertando no reviewer — aplicado a mim mesmo, sem perceber.

### Acao corretiva

| ID | Acao | Arquivo | Status |
|----|------|---------|--------|
| UP-25 | Pre-check respeita o OPERADOR do range (`>=`/`>` reprovam so abaixo do minimo; `<`/`<=` cobrem upper bound; pin/caret/til exigem o major) e roda DEPOIS do `cd` para a raiz | plugin/template/ci/pre-commit-quality.example | [OK] 2026-07-30 — testado nos DOIS sentidos, com Node 22 e 26 reais |
| UP-26 | Teste de guarda/validacao exige o caso que a REPROVA errado, nao so o que ela aprova certo: para cada regra, um caso que deve passar e um que deve falhar. "Testado em 3 cenarios" sem caso adversarial nao e teste, e confirmacao | processo (auto-review antes de abrir PR) + `qa-engineer.md` (backport candidato) | [OK] registrado; backport ao spec do QA pendente |
| UP-27 | Porte de codigo EXECUTAVEL do template para um projeto exige execucao no ambiente real antes do commit (AM-46 do trokey) — reconciliacao que altera script nao e mudanca de doc | `/squad-resume` passo 0b + tech-lead.md | Pendente (proxima release) |
| UP-28 | Suite chamada de dentro de um hook do git herda `GIT_DIR`/`GIT_INDEX_FILE` do repo de fora, e **`git -C <outro-repo>` nao sobrepoe** essas vars: o teste opera no indice do repo errado. Sintoma exato: VERDE rodado a mao, VERMELHO dentro do gate — o pior formato, porque acusa o codigo em vez do teste. Todo script de teste que cria repo fixture comeca com `unset` das GIT_*. Parente da AM-41 (estado herdado entre passadas do gate), agora vindo do ambiente em vez do disco | `scripts/ci/pre-bash-cases.sh` | [OK] 2026-07-30 — reproduzido com `GIT_DIR=/tmp/fake.git` e verificado nos dois estados |
| UP-29 | O `CLAUDE.md` lista "Code Reviewer aprovou" como gate obrigatorio de release, e o `tech-lead.md` descreve o protocolo de review — mas **nenhum passo executavel do fluxo aciona o reviewer**. Nesta sessao ele so rodou porque o TL propos e o usuario mandou; achou **2 MAJOR** num hook que roda em todo comando Bash de toda sessao, ambos ja aprovados por 4 checks de CI e 19 assercoes proprias. Sem o acionamento avulso, os dois estariam em `main`. Gate que depende de alguem lembrar nao e gate — e a mesma classe da AM-35 (acao fechada contra a existencia do artefato, nunca contra o efeito). Acao: o fluxo de release ganha passo explicito "spawnar `code-reviewer` antes do PR de release; PR de sistema tambem", e o `/squad-handoff` passa a exigir a contagem de achados no Session Log (o coletor nao ve review de subagent — AM-39) | `tech-lead.md` (fluxo de release) + `CLAUDE.md` do projeto + `/squad-handoff` passo 5d | Pendente (proxima release) |
| UP-30 | **Handoff que fica so em `develop` e invisivel para quem retoma de `main`.** `main` e a branch default: clone novo e worktree nova caem nela. Os handoffs anteriores chegaram la **de carona nas releases** — o handoff sempre vinha ANTES da release, entao o PR `develop`->`main` levava os dois juntos. Isso escondeu a regra ate a sessao em que o ultimo handoff veio DEPOIS da ultima release: a `main` ficou dizendo "v2.1.0 esta em develop e ainda NAO foi taggeada" (falso) e sem a UP-29. Quem retomasse de `main` refaria uma release ja feita — exatamente o que o passo 1 do `/squad-resume` tenta detectar. Levar `develop` para `main` NAO exige bump nem tag: sync de memoria e PR normal. Acao: `/squad-handoff` passo 8 ganha "se o handoff vier depois da ultima release da sessao, abrir PR `develop`->`main` so de sync, sem tag" | `/squad-handoff` passo 8 | Pendente (proxima release) |
| UP-31 | **Caso adversarial nao cobre premissa compartilhada.** A UP-26 (testar nos dois sentidos) foi seguida na 1.13.1: 7 cenarios, com e sem teto, aprovando e reprovando. Todos os 7 usavam `engines.node` com ESPACO entre as constraints — e o fix novo separa por espaco. Range sem espaco (`">=22.0.0<23.0.0"`, forma valida) perde o teto e aprova Node 26. A tabela de teste variava o QUE se testa e mantinha fixo o FORMATO da entrada; nenhum dos dois sentidos tocava a premissa. Regra: alem de "o que a regra reprova errado", perguntar **"qual formato de entrada meus casos nunca variam?"** — separador, encoding, ordem, caixa, ausencia do campo. Terceira ocorrencia do tema nesta sessao (com o teste da UP-02 que passava pelo fallback e o gate que so avisava sem se auto-corrigir): o teste confirmava a implementacao em vez de interrogar a entrada | `plugin/template/ci/pre-commit-quality.example` + `qa-engineer.md` (backport candidato) | Pendente — card GATE-PRECHECK-SEMVER no board |

### Principio

Guarda que reprova o caso legitimo e pior que guarda ausente: ela treina a burla que existia para impedir. E o teste que so exercita o caminho felizes da regra mede a minha confianca, nao a regra — a assimetria (aprova certo / reprova certo) e obrigatoria.


## Indice de acoes

| ID | Acao (resumo) | Arquivo-alvo | Status |
|----|---------------|--------------|--------|
| UP-01 | push-gate avisa sobre PR mergeado da branch | plugin/hooks/push-gate.sh | Feito (v1.6.0) |
| UP-02 | UP-01 isenta push de tag/refspec que nao e a branch | plugin/hooks/pre-bash.sh | Implementado na FASE 2; chega a main na v2.0.0 |
| UP-03 | push-gate: restaurar leitura de `cwd` do payload (regressao 1.5.0 -> 1.6.0) | plugin/hooks/push-gate.sh | Feito (v1.7.0) |
| UP-04 | push-gate le SQUAD_SKIP_GATE do comando (escape inacionavel por agente) | plugin/hooks/push-gate.sh | Feito (v1.8.0) |
| UP-05 | Revisar desenho do push-gate -> ADVISORY por padrao, enforce opt-in | plugin/hooks/push-gate.sh | Feito (v1.8.0) |
| UP-06 | Match de `git push` por substring bloqueia commit que so MENCIONA push | plugin/hooks/push-gate.sh | Feito (v1.8.0) |
| UP-07 | plugin-ci com runner parametrizavel (CI_RUNNER) — fallback legitimo pro billing | .github/workflows/plugin-ci.yml | Feito (v1.8.0) |
| UP-08 | Registrar runner self-hosted (org-level) na maquina do Pablo | acao do usuario | Feito (2026-07-26) |
| UP-10 | setup-python condicional ao cloud — self-hosted macOS usa python3 local | .github/workflows/plugin-ci.yml | Feito (PR #41) |
| UP-11 | Release: confirmar MERGED + fetch antes de taguear (tag nasceu no commit errado) | ARCHITECTURE.md (fluxo de release) | [OK] Efeito provado (release v1.10.0: leitura stale pos-merge detectada ANTES da tag; sequencia segurou) |
| UP-12 | Review-teatro: reviewer cacador + QA executa + metrica desinvertida (Fase 0 do plano) | agents + skills + squad-core | Feito (v1.9.0), prova pendente na batalha |
| UP-13 | Changelog no README como passo do fluxo de release | ARCHITECTURE.md | Feito (2026-07-28) |
| UP-14 | plugin-ci: `push` so em main — elimina suite dupla em PR com head develop/main | .github/workflows/plugin-ci.yml | Feito (2026-07-28), prova de efeito no proximo release PR |
| UP-15 | Reescrita de spec: grep de frases-eco + ancoras no mesmo PR | processo + candidato a check CI | Aplicado a mao (Fase 1 e backport); check pendente. **Reincidiu:** 5 frases "review = confirmacao" sobreviveram a Fase 0 nos 4 engineers + security-engineer, e o proprio coletor imprimia `[OK] achados=0` — corrigidas em 2026-07-29 |
| UP-16 | Coletor de metricas: descartar runs de 0 steps, janela do PR, `revisoes` ao lado de `achados`, leitura tripla, retry no gh | plugin/scripts/squad-metrics.sh | [OK] 2026-07-29 (trokey 98.0 -> 2.0 no dado real) |
| UP-17 | Resume reporta as 3 versoes (em execucao / instalada / registrada) — AM-36 | plugin/skills/squad-resume/SKILL.md | [OK] 2026-07-29 |
| UP-18 | Resume ganha procedimento de reconciliacao (5 passos, a partir do changelog) | plugin/skills/squad-resume/SKILL.md | [OK] 2026-07-29 |
| UP-19 | TL: trabalho dependente de versao de governanca so em sessao pos-upgrade — AM-37 | plugin/template/agents/tech-lead.md | [OK] 2026-07-29 |
| UP-20 | Delegacao exige gate/testes em FOREGROUND; TL confere disco, nao aceita "completed" — AM-40 | tech-lead.md + 4 engineers | [OK] 2026-07-29 |
| UP-21 | Guidance de gate: retentativa reseta estado compartilhado (ou namespace por run) — AM-41 | squad-core §M | [OK] 2026-07-29 |
| UP-22 | Status de acao corretiva em forma branch-agnostica (`Implementado no PR #NN; chega a main na vX.Y.Z`) — texto divergente entre branches conflita na release | processo de release + escrita do LESSONS | [OK] 2026-07-29 |
| UP-23 | Melhoria aceita em conversa vira card na hora (a promessa de auto-reconciliacao ficou fora da v1.12.0) | TASK_BOARD (habito do TL) | [OK] 2026-07-29 |
| UP-24 | Reconciliacao automatica do delta sem `[BREAKING]`; deteccao por MARCADOR, nao por palavra (UP-06 em 3a forma) | squad-migrate.py + squad-resume 0b | [OK] 2026-07-29 (v1.13.0) |
| UP-09 | Skills mandavam `claude plugin update dev-squad` — CLI exige id COMPLETO `dev-squad@pdati`; nome curto falha com "Plugin not found" (falhou pro usuario na 1a tentativa real do passo novo) | plugin/skills/squad-resume + squad-handoff | Feito (v1.8.1) |
