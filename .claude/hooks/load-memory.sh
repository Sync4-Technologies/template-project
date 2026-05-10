#!/usr/bin/env bash
# Hook: SessionStart
# Carrega memória viva da squad no contexto inicial da sessão.
# Falha silenciosa se arquivos não existirem (template novo sem memória ainda).

set -u

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MEMORY_DIR="${PROJECT_ROOT}/memory"

# Falha silenciosa: se memory/ não existe ainda (projeto recém-criado), não há nada a carregar
if [[ ! -d "${MEMORY_DIR}" ]]; then
  echo "{}"
  exit 0
fi

OUTPUT="=== SQUAD MEMORY LOADED (SessionStart) ===\n"

# ARCHITECTURE.md (visão atual)
if [[ -f "${MEMORY_DIR}/ARCHITECTURE.md" ]]; then
  OUTPUT+="\n--- memory/ARCHITECTURE.md (head) ---\n"
  OUTPUT+="$(head -50 "${MEMORY_DIR}/ARCHITECTURE.md" 2>/dev/null || echo "(empty)")\n"
fi

# TASK_BOARD.md (tarefas em andamento — Doing/Review/Blocked)
if [[ -f "${MEMORY_DIR}/TASK_BOARD.md" ]]; then
  OUTPUT+="\n--- memory/TASK_BOARD.md (Doing/Review/Blocked) ---\n"
  awk '
    /^## (🔄 Doing|👀 Review|🚫 Blocked)/{flag=1; print; next}
    /^## /{flag=0}
    flag
  ' "${MEMORY_DIR}/TASK_BOARD.md" 2>/dev/null | head -50 >&2 || true
  OUTPUT+="$(awk '
    /^## (🔄 Doing|👀 Review|🚫 Blocked)/{flag=1; print; next}
    /^## /{flag=0}
    flag
  ' "${MEMORY_DIR}/TASK_BOARD.md" 2>/dev/null | head -50)\n"
fi

# DECISIONS_LOG.md (decisões recentes — últimas 10 linhas de tabela)
if [[ -f "${MEMORY_DIR}/DECISIONS_LOG.md" ]]; then
  OUTPUT+="\n--- memory/DECISIONS_LOG.md (recent) ---\n"
  OUTPUT+="$(grep -E '^\|.*\|' "${MEMORY_DIR}/DECISIONS_LOG.md" 2>/dev/null | tail -10)\n"
fi

# ADRs ativos (lista)
if [[ -d "${MEMORY_DIR}/ADR" ]]; then
  OUTPUT+="\n--- memory/ADR/ (active ADRs) ---\n"
  OUTPUT+="$(ls "${MEMORY_DIR}/ADR" 2>/dev/null | grep -v template | sort)\n"
fi

# Output JSON for Claude Code hook protocol
# additionalContext is appended to system context; suppressOutput hides this from user
printf '%s' "$(cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$(echo -e "${OUTPUT}" | sed 's/"/\\"/g' | tr '\n' ' ' | tr -s ' ')"
  }
}
EOF
)"
