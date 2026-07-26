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
| UP-02 | Isentar do check UP-01 pushes cujo refspec e tag (`git push origin vX.Y.Z`, `--tags`) ou que nao empurram a branch atual | `plugin/hooks/push-gate.sh` | Pendente (v1.6.1) |

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

## Indice de acoes

| ID | Acao (resumo) | Arquivo-alvo | Status |
|----|---------------|--------------|--------|
| UP-01 | push-gate avisa sobre PR mergeado da branch | plugin/hooks/push-gate.sh | Feito (v1.6.0) |
| UP-02 | UP-01 isenta push de tag/refspec que nao e a branch | plugin/hooks/push-gate.sh | Pendente (v1.6.1) |
| UP-03 | push-gate: restaurar leitura de `cwd` do payload (regressao 1.5.0 -> 1.6.0) | plugin/hooks/push-gate.sh | Feito (v1.7.0) |
| UP-04 | push-gate le SQUAD_SKIP_GATE do comando (escape inacionavel por agente) | plugin/hooks/push-gate.sh | Feito (v1.8.0) |
| UP-05 | Revisar desenho do push-gate -> ADVISORY por padrao, enforce opt-in | plugin/hooks/push-gate.sh | Feito (v1.8.0) |
| UP-06 | Match de `git push` por substring bloqueia commit que so MENCIONA push | plugin/hooks/push-gate.sh | Feito (v1.8.0) |
| UP-07 | plugin-ci com runner parametrizavel (CI_RUNNER) — fallback legitimo pro billing | .github/workflows/plugin-ci.yml | Feito (v1.8.0) |
| UP-08 | Registrar runner self-hosted (org-level) na maquina do Pablo | acao do usuario | Feito (2026-07-26) |
| UP-10 | setup-python condicional ao cloud — self-hosted macOS usa python3 local | .github/workflows/plugin-ci.yml | Feito (PR #41) |
| UP-09 | Skills mandavam `claude plugin update dev-squad` — CLI exige id COMPLETO `dev-squad@pdati`; nome curto falha com "Plugin not found" (falhou pro usuario na 1a tentativa real do passo novo) | plugin/skills/squad-resume + squad-handoff | Feito (v1.8.1) |
