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

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Sem squad no projeto -> não interferir
[ -d "${PROJECT_ROOT}/.claude/squad/project" ] || exit 0

# Escape consciente
if [ "${SQUAD_SKIP_GATE:-0}" = "1" ]; then
  echo "[push-gate] SQUAD_SKIP_GATE=1 — gate pulado conscientemente (registrar o porquê no PR)." >&2
  exit 0
fi

# Extrair o comando do payload JSON do hook (stdin)
CMD=$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("command", ""))
except Exception:
    print("")
' 2>/dev/null)

# Não é git push -> seguir
case "$CMD" in
  *"git push"*) ;;
  *) exit 0 ;;
esac

cd "$PROJECT_ROOT" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

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
