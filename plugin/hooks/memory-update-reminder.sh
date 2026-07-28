#!/usr/bin/env bash
# Hook: PreToolUse on Bash (git commit)
# Lembra de atualizar memory quando há mudanças em código sem atualização correspondente em DECISIONS_LOG/ARCHITECTURE/ADR.
# Não bloqueia — apenas adiciona contexto sugestivo ao Claude.
# Opt-in via .claude/settings.json.

set -u

# Lê input JSON do stdin
INPUT="$(cat)"

# Detecta EXECUÇÃO de `git commit` (não menção — padrão UP-06 do push-gate):
# heredocs descartados, split por segmento, primeiro verbo de cada segmento.
IS_COMMIT="$(echo "${INPUT}" | python3 -c "
import json, sys, re
try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', {}).get('command', '') or ''
except Exception:
    print('0'); sys.exit(0)

stripped = re.sub(
    r'<<-?\s*([\x27\"]?)(\w+)\1.*?\n\s*\2\s*(\n|$)', '\n', cmd, flags=re.S
)

hit = 0
for seg in re.split(r'&&|\|\||;|\||\n', stripped):
    toks = seg.strip().split()
    while toks and re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', toks[0]):
        toks = toks[1:]
    if len(toks) >= 2 and toks[0] == 'git' and toks[1] == 'commit':
        hit = 1
        break
print(hit)
" 2>/dev/null)"

if [[ "${IS_COMMIT}" != "1" ]]; then
  exit 0
fi

# Identifica arquivos no staged via git
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "${PROJECT_ROOT}" 2>/dev/null || exit 0

# Lista de arquivos staged (vazia se nada staged)
STAGED="$(git diff --cached --name-only 2>/dev/null || echo "")"

if [[ -z "${STAGED}" ]]; then
  exit 0
fi

# Detectar se há mudança em código de produção
HAS_CODE_CHANGE=false
if echo "${STAGED}" | grep -qE "^(src/|lib/|app/|backend/|frontend/|mobile/|api/|services/|domain/|adapters/|application/|infrastructure/)" 2>/dev/null; then
  HAS_CODE_CHANGE=true
fi

# Se não há mudança em código, sair (sem reminder)
if [[ "${HAS_CODE_CHANGE}" != "true" ]]; then
  exit 0
fi

# Detectar se há atualização correspondente em memory
HAS_MEMORY_UPDATE=false
if echo "${STAGED}" | grep -qE "\.claude/squad/project/(DECISIONS_LOG\.md|ARCHITECTURE\.md|ADR/|agent-memory/)" 2>/dev/null; then
  HAS_MEMORY_UPDATE=true
fi

# Se há mudança em código MAS não há atualização em memory, sugerir reminder
if [[ "${HAS_CODE_CHANGE}" == "true" && "${HAS_MEMORY_UPDATE}" != "true" ]]; then
  REMINDER="Reminder: commit inclui mudanças em código de produção mas NÃO há atualização correspondente em .claude/squad/project/ (DECISIONS_LOG.md, ARCHITECTURE.md, ADR/ ou agent-memory/). Considere: (a) decisão técnica relevante → registrar em DECISIONS_LOG.md; (b) decisão estrutural → criar ADR específico do projeto; (c) mudança arquitetural → atualizar ARCHITECTURE.md; (d) learning do agente → atualizar agent-memory/{agente}.md. Se a mudança não tem implicação documental, pode prosseguir com commit. Para handoff multi-usuário, considere /squad-handoff antes de encerrar sessão."

  # JSON output for Claude Code hook protocol
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "${REMINDER}"
  }
}
EOF
  exit 0
fi

# Nenhum alerta necessário — sair silencioso
exit 0
