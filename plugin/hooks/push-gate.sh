#!/usr/bin/env bash
# Hook: PreToolUse (matcher: Bash)
# Bloqueia `git push` se o gate determinístico não validou a árvore do HEAD atual.
# Mecânica: pre-commit-quality grava a árvore validada em $GIT_DIR/squad-gate-ok;
# aqui comparamos com HEAD^{tree}. Regra vira máquina (PLANO_V1.3.0 Fase E2).
#
# Só atua quando:
#   - o comando contém `git push`
#   - o projeto tem squad inicializada (.claude/squad/project/)
#   - SQUAD_SKIP_GATE != 1 (escape consciente, análogo ao --no-verify)
# Fora disso: exit 0 (inofensivo).
set -u

# Extrai `cwd` + `command` do payload JSON do hook (stdin) em UMA chamada python
# (stdin não pode ser lido duas vezes). `cwd` é a worktree onde o `git push` está
# sendo executado — usar isso em vez de $CLAUDE_PROJECT_DIR corrige o bug
# worktree-blind: subagents em worktrees isoladas gravam o marker em
# .git/worktrees/<name>/squad-gate-ok, mas $CLAUDE_PROJECT_DIR aponta pra main
# worktree — o hook lia o marker do lugar errado e bloqueava pushes legítimos.
PAYLOAD=$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("cwd", "") or "")
    print(d.get("tool_input", {}).get("command", "") or "")
except Exception:
    print("")
    print("")
' 2>/dev/null)

CWD=$(printf '%s\n' "$PAYLOAD" | sed -n '1p')
CMD=$(printf '%s\n' "$PAYLOAD" | sed -n '2p')

# PROJECT_ROOT prioriza o cwd real do comando (worktree correto). Fallback para
# $CLAUDE_PROJECT_DIR e $(pwd) para compatibilidade com Claude Code sem `cwd` no payload.
PROJECT_ROOT="${CWD:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

# Sem squad no projeto — checa tanto PROJECT_ROOT quanto $CLAUDE_PROJECT_DIR pra
# cobrir subagent worktree (que compartilha o marker/config do main via git object db).
if [ ! -d "${PROJECT_ROOT}/.claude/squad/project" ] && \
   [ ! -d "${CLAUDE_PROJECT_DIR:-/nonexistent}/.claude/squad/project" ]; then
  exit 0
fi

# Escape consciente
if [ "${SQUAD_SKIP_GATE:-0}" = "1" ]; then
  echo "[push-gate] SQUAD_SKIP_GATE=1 — gate pulado conscientemente (registrar o porquê no PR)." >&2
  exit 0
fi

# Não é git push -> seguir
case "$CMD" in
  *"git push"*) ;;
  *) exit 0 ;;
esac

cd "$PROJECT_ROOT" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# UP-01: branch com PR já MERGED/CLOSED está morta — push nela é trabalho invisível.
# Fail-open: sem gh, sem auth ou timeout -> não interferir.
BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ] && command -v gh >/dev/null 2>&1; then
  PR_STATE=$(gh pr view "$BRANCH" --json state --jq .state 2>/dev/null || echo "")
  if [ "$PR_STATE" = "MERGED" ] || [ "$PR_STATE" = "CLOSED" ]; then
    cat >&2 <<UPMSG
[push-gate] BLOQUEADO (UP-01): a branch '$BRANCH' tem PR $PR_STATE — branch morta.
Push aqui é trabalho invisível. Crie branch nova a partir da base atualizada e abra novo PR:
  git fetch origin && git switch -c <nova-branch> origin/<base>
Escape consciente (raro — ex: reabrir PR fechado de propósito): SQUAD_SKIP_GATE=1 git push ...
UPMSG
    exit 2
  fi
fi

# `--git-dir` num worktree retorna `.git/worktrees/<name>` — é onde o
# pre-commit-quality do subagent grava o marker. NÃO usar `--git-common-dir`,
# que retorna o `.git` compartilhado (main worktree) e reintroduz o bug.
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || exit 0
HEAD_TREE=$(git rev-parse "HEAD^{tree}" 2>/dev/null) || exit 0
MARKER=$(cat "$GIT_DIR/squad-gate-ok" 2>/dev/null || echo "")

if [ "$MARKER" = "$HEAD_TREE" ]; then
  exit 0
fi

cat >&2 <<'MSG'
[push-gate] BLOQUEADO: o gate determinístico não validou o HEAD atual.
Antes de pushar, rode o gate completo do repositório (format + lint + typecheck + testes):
  .githooks/pre-commit-quality   (grava o marcador ao passar)
Se o hook não está instalado neste projeto, instale via /squad-init (passo de gates).
Rebase/amend invalida o marcador — re-rodar o gate é o comportamento esperado.
Escape consciente (emergência, nunca rotina): SQUAD_SKIP_GATE=1 git push ...
MSG
exit 2
