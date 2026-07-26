# Licoes Aprendidas — template-project (upstream da dev-squad)

> Documento vivo do SISTEMA da squad. Escopo e formato: `plugin/template/LESSONS_LEARNED-template.md`.
> Ultima atualizacao: 2026-07-05

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

## Indice de acoes

| ID | Acao (resumo) | Arquivo-alvo | Status |
|----|---------------|--------------|--------|
| UP-01 | push-gate avisa sobre PR mergeado da branch | plugin/hooks/push-gate.sh | Feito (v1.6.0) |
