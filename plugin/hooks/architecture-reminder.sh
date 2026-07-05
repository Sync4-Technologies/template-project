#!/usr/bin/env bash
# Hook: PostToolUse on Edit/Write em memory/ARCHITECTURE.md
# Lembra de atualizar memory/DECISIONS_LOG.md quando há mudança estrutural relevante.
# Falha silenciosa em qualquer erro.

set -u

# Lê input JSON do stdin
INPUT="$(cat)"

# Extrai file_path do tool_input (Edit/Write)
FILE_PATH="$(echo "${INPUT}" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)"

# Só dispara se o arquivo é .claude/squad/project/ARCHITECTURE.md
if [[ "${FILE_PATH}" != *".claude/squad/project/ARCHITECTURE.md" ]]; then
  exit 0
fi

# Output JSON para Claude Code hook protocol
# additionalContext aparece como reminder ao Claude
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Reminder: .claude/squad/project/ARCHITECTURE.md foi atualizado. Considere registrar a decisão em .claude/squad/project/DECISIONS_LOG.md (ou ADR específico do projeto em .claude/squad/project/ADR/ se for decisão estrutural significativa). Atualize a data de 'Última atualização' no header de ARCHITECTURE.md."
  }
}
EOF
