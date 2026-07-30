#!/usr/bin/env bash
# Smoke test dos hooks do plugin.
# 1. Sintaxe de todos os .sh
# 2. load-memory.sh num projeto COM squad -> JSON válido + persona TL + ADRs do plugin
# 3. load-memory.sh num projeto SEM squad -> {} limpo
# 4. pre-bash.sh: comportamento (gate, UP-01/02/04/06, reminder) — pre-bash-cases.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN="$ROOT/plugin"
FIXTURE="$ROOT/scripts/ci/fixtures/project-with-squad"

echo "[1/4] bash -n em todos os hooks"
for f in "$PLUGIN"/hooks/*.sh; do
  bash -n "$f"
  echo "  syntax OK: $(basename "$f")"
done

echo "[2/4] load-memory.sh com projeto squad (fixture)"
OUT=$(CLAUDE_PROJECT_DIR="$FIXTURE" CLAUDE_PLUGIN_ROOT="$PLUGIN" "$PLUGIN/hooks/load-memory.sh")
HOOK_OUT="$OUT" python3 -c '
import json, os
d = json.loads(os.environ["HOOK_OUT"])
ctx = d["hookSpecificOutput"]["additionalContext"]
assert d["hookSpecificOutput"]["hookEventName"] == "SessionStart"
assert "VOCE ATUA COMO TECH LEAD" in ctx, "persona TL ausente"
assert "ARCHITECTURE.md (head)" in ctx, "ARCHITECTURE ausente"
assert "Doing" in ctx, "TASK_BOARD Doing ausente"
assert "ADR-001-stack.md" in ctx, "ADRs do plugin ausentes"
assert "ADR-001-exemplo.md" in ctx, "ADR do projeto ausente"
print("  JSON + persona + memoria OK (%d chars)" % len(ctx))
'

echo "[3/4] load-memory.sh sem projeto squad (deve retornar {})"
TMP=$(mktemp -d)
OUT=$(CLAUDE_PROJECT_DIR="$TMP" CLAUDE_PLUGIN_ROOT="$PLUGIN" "$PLUGIN/hooks/load-memory.sh")
rm -rf "$TMP"
[ "$OUT" = "{}" ] || { echo "  FALHOU: esperado {}, veio: $OUT"; exit 1; }
echo "  {} limpo OK"

echo "[4/4] pre-bash.sh — comportamento"
"$ROOT/scripts/ci/pre-bash-cases.sh"

echo "hooks-smoke: TUDO OK"
