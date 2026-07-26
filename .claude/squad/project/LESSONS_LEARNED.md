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

## Indice de acoes

| ID | Acao (resumo) | Arquivo-alvo | Status |
|----|---------------|--------------|--------|
| UP-01 | push-gate avisa sobre PR mergeado da branch | plugin/hooks/push-gate.sh | Feito (v1.6.0) |
| UP-02 | UP-01 isenta push de tag/refspec que nao e a branch | plugin/hooks/push-gate.sh | Pendente (v1.6.1) |
