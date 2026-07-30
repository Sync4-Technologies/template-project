#!/usr/bin/env bash
# Casos de comportamento do hook `pre-bash.sh` (PreToolUse/Bash).
#
# UP-26: testar nos DOIS sentidos. Cada regra tem caso que ela DEVE pegar e caso
# que ela NÃO pode pegar — a falha do pre-check da 1.12.0 passou por só exercitar
# o que a regra aprova certo.
#
# Chamado por hooks-smoke.sh (job `hooks-smoke` do plugin-ci).
set -uo pipefail

# Este script roda TAMBÉM de dentro do .githooks/pre-commit (o gate local chama o
# hooks-smoke). Um hook do git recebe GIT_DIR/GIT_INDEX_FILE do repo de fora no
# ambiente, e `git -C <outro-repo>` NÃO sobrepõe essas variáveis: sem o unset, os
# comandos abaixo operam no índice do repo real em vez do fixture — verde quando
# rodado à mão, vermelho dentro do gate. Isolar o ambiente é parte do teste.
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_CONFIG_PARAMETERS \
      GIT_AUTHOR_DATE GIT_COMMITTER_DATE 2>/dev/null || true

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT/plugin/hooks/pre-bash.sh"

falhou=0
ok()   { echo "  OK: $1"; }
fail() { echo "  FALHOU: $1"; falhou=1; }

# --- fixture: repo git de verdade, com squad -------------------------------
REPO=$(mktemp -d)
trap 'rm -rf "$REPO"' EXIT
git -C "$REPO" init -q -b main
git -C "$REPO" config user.email ci@example.com
git -C "$REPO" config user.name CI
mkdir -p "$REPO/.claude/squad/project" "$REPO/src"
echo x > "$REPO/src/app.py"
git -C "$REPO" add -A
git -C "$REPO" -c core.hooksPath=/dev/null commit -q -m "base"
GIT_DIR_REPO="$REPO/.git"
HEAD_TREE=$(git -C "$REPO" rev-parse 'HEAD^{tree}')

# repo SEM squad
BARE=$(mktemp -d)
trap 'rm -rf "$REPO" "$BARE"' EXIT
git -C "$BARE" init -q -b main
git -C "$BARE" config user.email ci@example.com
git -C "$BARE" config user.name CI
echo x > "$BARE/f.txt"
git -C "$BARE" add -A
git -C "$BARE" -c core.hooksPath=/dev/null commit -q -m base

# run <cwd> <command> -> grava RC/OUT/ERR
run() {
  local cwd="$1" cmd="$2"
  local payload
  payload=$(CWD="$cwd" CMD="$cmd" python3 -c '
import json, os
print(json.dumps({"cwd": os.environ["CWD"],
                  "tool_input": {"command": os.environ["CMD"]}}))')
  OUT=$(printf '%s' "$payload" | "$HOOK" 2>"$REPO/.stderr")
  RC=$?
  ERR=$(cat "$REPO/.stderr")
}

marker_set()   { echo "$HEAD_TREE" > "$GIT_DIR_REPO/squad-gate-ok"; }
marker_clear() { rm -f "$GIT_DIR_REPO/squad-gate-ok"; }
cache_write()  { printf '%s\t%s\t%s\n' "$1" "$2" "$(date +%s)" > "$GIT_DIR_REPO/squad-pr-state"; }
cache_clear()  { rm -f "$GIT_DIR_REPO/squad-pr-state"; }

# ===========================================================================
echo "[pre-bash] early-exit e detecção de execução"
# ===========================================================================
marker_clear; cache_clear

run "$REPO" 'ls -la'
[ "$RC" = 0 ] && [ -z "$OUT" ] && [ -z "$ERR" ] \
  && ok "comando trivial: silencioso (early-exit, zero python)" \
  || fail "comando trivial deveria ser no-op (rc=$RC out='$OUT' err='$ERR')"

# UP-06: mensagem que CITA push não é push
run "$REPO" "$(printf 'git commit -F - <<EOF\nfix: descreve o bug\n\nO gate barrava git push aqui.\nEOF')"
case "$ERR" in
  *"gate determinístico não validou"*) fail "UP-06 regrediu: menção a push tratada como execução" ;;
  *) ok "UP-06: mensagem de commit citando 'git push' não dispara o gate" ;;
esac

# palavra solta contendo 'push' num comando qualquer
run "$REPO" 'grep -rn "push" docs/'
[ "$RC" = 0 ] && [ -z "$ERR" ] \
  && ok "grep por 'push' não dispara o gate" \
  || fail "grep por 'push' disparou o gate (err='$ERR')"

# ===========================================================================
echo "[pre-bash] gate determinístico (marcador)"
# ===========================================================================
marker_clear
run "$REPO" 'git push origin main'
[ "$RC" = 0 ] && [[ "$ERR" == *"não validou o HEAD atual"* ]] \
  && ok "push sem marcador: AVISA e passa (advisory)" \
  || fail "push sem marcador deveria avisar em advisory (rc=$RC err='$ERR')"

marker_set
run "$REPO" 'git push origin main'
[ "$RC" = 0 ] && [ -z "$ERR" ] \
  && ok "push com marcador válido: silencioso" \
  || fail "push com marcador válido deveria ser silencioso (err='$ERR')"

# enforce bloqueia
marker_clear
touch "$REPO/.claude/squad/project/gate-enforce"
run "$REPO" 'git push origin main'
[ "$RC" = 2 ] && [[ "$ERR" == *"BLOQUEADO"* ]] \
  && ok "enforce + sem marcador: BLOQUEIA (exit 2)" \
  || fail "enforce deveria bloquear com exit 2 (rc=$RC)"

# UP-04: escape inline no comando
run "$REPO" 'SQUAD_SKIP_GATE=1 git push origin main'
[ "$RC" = 0 ] && [[ "$ERR" == *"gate pulado conscientemente"* ]] \
  && ok "UP-04: SQUAD_SKIP_GATE=1 inline passa mesmo em enforce" \
  || fail "escape inline deveria passar (rc=$RC err='$ERR')"
rm -f "$REPO/.claude/squad/project/gate-enforce"

# ===========================================================================
echo "[pre-bash] UP-01 por cache + UP-02 (refspec)"
# ===========================================================================
marker_set
cache_write main MERGED
run "$REPO" 'git push origin main'
[[ "$ERR" == *"UP-01"* ]] \
  && ok "UP-01: cache MERGED da branch atual avisa (sem rede)" \
  || fail "UP-01 deveria avisar com cache MERGED (err='$ERR')"

cache_write main OPEN
run "$REPO" 'git push origin main'
[[ "$ERR" != *"UP-01"* ]] \
  && ok "UP-01: cache OPEN não avisa" \
  || fail "UP-01 não deveria avisar com PR OPEN"

# UP-02: push de tag / refspec que não é a branch atual
cache_write main MERGED
run "$REPO" 'git push origin v1.0.0'
[[ "$ERR" != *"UP-01"* ]] \
  && ok "UP-02: push de tag não dispara UP-01" \
  || fail "UP-02: push de tag disparou UP-01 (err='$ERR')"

run "$REPO" 'git push origin --tags'
[[ "$ERR" != *"UP-01"* ]] \
  && ok "UP-02: push --tags não dispara UP-01" \
  || fail "UP-02: --tags disparou UP-01"

run "$REPO" 'git push origin outra-branch'
[[ "$ERR" != *"UP-01"* ]] \
  && ok "UP-02: push de outra branch não dispara UP-01" \
  || fail "UP-02: refspec de outra branch disparou UP-01"

# contra-prova da UP-02: refspec explícito DA branch atual ainda dispara
run "$REPO" 'git push origin main:main'
[[ "$ERR" == *"UP-01"* ]] \
  && ok "UP-02: refspec explícito da branch atual AINDA dispara UP-01" \
  || fail "refspec main:main deveria disparar UP-01 (err='$ERR')"

run "$REPO" 'git push --force-with-lease origin main'
[[ "$ERR" == *"UP-01"* ]] \
  && ok "UP-02: flag com valor não confunde o parser de refspec" \
  || fail "--force-with-lease quebrou o parse de refspec (err='$ERR')"
cache_clear

# ===========================================================================
echo "[pre-bash] reminder de memória (ramo commit)"
# ===========================================================================
echo y >> "$REPO/src/app.py"
git -C "$REPO" add src/app.py
run "$REPO" 'git commit -m "feat: muda codigo"'
[[ "$OUT" == *"additionalContext"* ]] \
  && ok "commit em src/ sem memória: emite reminder" \
  || fail "deveria emitir reminder (out='$OUT')"
printf '%s' "$OUT" | python3 -c 'import json,sys; json.load(sys.stdin)' \
  && ok "reminder é JSON válido" || fail "reminder não é JSON válido"

echo z >> "$REPO/.claude/squad/project/DECISIONS_LOG.md"
git -C "$REPO" add .claude/squad/project/DECISIONS_LOG.md
run "$REPO" 'git commit -m "feat: muda codigo e registra"'
[ -z "$OUT" ] \
  && ok "commit com memória atualizada: sem reminder" \
  || fail "não deveria emitir reminder (out='$OUT')"

# commit+push no MESMO comando: gate avisa E reminder sai
git -C "$REPO" reset -q; git -C "$REPO" add src/app.py; marker_clear
run "$REPO" 'git commit -m "feat: x" && git push origin main'
[[ "$ERR" == *"não validou o HEAD atual"* ]] && [[ "$OUT" == *"additionalContext"* ]] \
  && ok "commit && push: gate avisa no stderr e reminder sai no stdout" \
  || fail "commit && push deveria produzir os dois (out='$OUT' err='$ERR')"

# ===========================================================================
echo "[pre-bash] projeto sem squad"
# ===========================================================================
run "$BARE" 'git push origin main'
[ "$RC" = 0 ] && [ -z "$ERR" ] && [ -z "$OUT" ] \
  && ok "repo sem .claude/squad/project: no-op" \
  || fail "repo sem squad deveria ser no-op (rc=$RC err='$ERR')"

if [ "$falhou" -ne 0 ]; then
  echo "pre-bash-cases: FALHOU"
  exit 1
fi
echo "pre-bash-cases: TUDO OK"
