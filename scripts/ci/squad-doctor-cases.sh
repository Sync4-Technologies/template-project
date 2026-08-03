#!/usr/bin/env bash
# Casos de comportamento do `squad-doctor.py` — foco no CAMINHO DE ESCRITA.
#
# O dry-run se prova sozinho rodando; o --apply MOVE arquivos do usuario e por
# isso e o unico caminho do plugin que pode destruir algo. Fixture com HOME
# falso e `claude` stubado: nada real e tocado.
#
# UP-26 (dois sentidos) + UP-31 (variar tambem o FORMATO da entrada): para cada
# regra, o caso que ela deve pegar E o que ela nao pode pegar.
#
# Chamado por hooks-smoke.sh (job `hooks-smoke` do plugin-ci).
set -uo pipefail

unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_CONFIG_PARAMETERS 2>/dev/null || true

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOCTOR="$ROOT/plugin/scripts/squad-doctor.py"

falhou=0
ok()   { echo "  OK: $1"; }
fail() { echo "  FALHOU: $1"; falhou=1; }

FAKE=$(mktemp -d)
trap 'rm -rf "$FAKE"' EXIT

CACHE="$FAKE/.claude/plugins/cache/pdati/dev-squad/2.2.0"
mkdir -p "$CACHE/agents" "$CACHE/template/agents" "$CACHE/scripts" \
         "$FAKE/.claude/agents" "$FAKE/bin" "$FAKE/projetos"

# agentes que o PLUGIN tem
for a in backend-engineer qa-engineer code-reviewer; do echo "# $a" > "$CACHE/agents/$a.md"; done
echo "# tech-lead" > "$CACHE/template/agents/tech-lead.md"

# squad-migrate stubado: o doctor so consome o --json dele
cat > "$CACHE/scripts/squad-migrate.py" <<'STUB'
#!/usr/bin/env python3
import json, sys
proj = sys.argv[sys.argv.index("--project") + 1] if "--project" in sys.argv else "?"
print(json.dumps({"projeto": proj, "estado": "plugin-puro", "achados": [],
                  "acoes_seguras": [], "decisoes": [{"tema": "x", "acao": "y"}],
                  "versao_registrada": "2.2.0", "versao_instalada": "2.2.0"}))
STUB
chmod +x "$CACHE/scripts/squad-migrate.py"

# `claude` stubado: marketplace e plugin ja presentes, update no-op
cat > "$FAKE/bin/claude" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  *"marketplace list"*) echo "pdati" ;;
  *"plugin list"*)      echo "dev-squad@pdati — enabled" ;;
  *)                    echo "ok" ;;
esac
STUB
chmod +x "$FAKE/bin/claude"

doctor() { HOME="$FAKE" PATH="$FAKE/bin:$PATH" python3 "$DOCTOR" "$@" 2>&1; }
semear_agentes() {
  rm -rf "$FAKE/.claude/agents" "$FAKE/.claude/agents-disabled"
  mkdir -p "$FAKE/.claude/agents"
  echo "sombra"  > "$FAKE/.claude/agents/backend-engineer.md"   # mesmo nome do plugin
  echo "sombra"  > "$FAKE/.claude/agents/tech-lead.md"          # so em template/agents
  echo "meu"     > "$FAKE/.claude/agents/meu-agente-proprio.md" # NAO existe no plugin
}

# ===========================================================================
echo "[squad-doctor] dry-run nao escreve"
# ===========================================================================
semear_agentes
OUT=$(doctor --roots "$FAKE/projetos")
[ -f "$FAKE/.claude/agents/backend-engineer.md" ] && [ ! -d "$FAKE/.claude/agents-disabled" ] \
  && ok "dry-run: nenhum arquivo movido, agents-disabled nem criado" \
  || fail "dry-run escreveu (agents-disabled existe ou o arquivo sumiu)"
[[ "$OUT" == *"DRY-RUN"* ]] && ok "dry-run se anuncia na saida" || fail "faltou o aviso de DRY-RUN"

# ===========================================================================
echo "[squad-doctor] --apply move SO as sombras"
# ===========================================================================
semear_agentes
doctor --roots "$FAKE/projetos" --apply >/dev/null
[ -f "$FAKE/.claude/agents-disabled/backend-engineer.md" ] \
  && ok "sombra de agents/ movida (nome bate com o do plugin)" \
  || fail "sombra nao foi movida"
[ -f "$FAKE/.claude/agents-disabled/tech-lead.md" ] \
  && ok "sombra de template/agents/ tambem conta" \
  || fail "agente de template/agents nao foi reconhecido como sombra"
# contra-prova: o que NAO e do plugin nao pode ser tocado
[ -f "$FAKE/.claude/agents/meu-agente-proprio.md" ] && [ ! -f "$FAKE/.claude/agents-disabled/meu-agente-proprio.md" ] \
  && ok "agente proprio do usuario NAO foi movido (contra-prova)" \
  || fail "moveu agente que nao e do plugin — destruicao de trabalho do usuario"
[ ! -f "$FAKE/.claude/agents/backend-engineer.md" ] \
  && ok "move, nao copia" || fail "original ficou para tras"

# ===========================================================================
echo "[squad-doctor] colisao em agents-disabled nao sobrescreve"
# ===========================================================================
semear_agentes
mkdir -p "$FAKE/.claude/agents-disabled"
echo "ANTIGO-PRECIOSO" > "$FAKE/.claude/agents-disabled/backend-engineer.md"
doctor --roots "$FAKE/projetos" --apply >/dev/null
[ "$(cat "$FAKE/.claude/agents-disabled/backend-engineer.md")" = "ANTIGO-PRECIOSO" ] \
  && ok "arquivo pre-existente em agents-disabled preservado" \
  || fail "sobrescreveu conteudo que ja estava em agents-disabled"
[ -f "$FAKE/.claude/agents-disabled/backend-engineer.dup.md" ] \
  && ok "colisao grava como .dup" || fail "faltou o .dup na colisao"

# ===========================================================================
echo "[squad-doctor] o que exige julgamento vira DECISAO, nunca acao"
# ===========================================================================
semear_agentes
mkdir -p "$FAKE/.claude/skills/minha-skill"
echo "x" > "$FAKE/.claude/skills/minha-skill/SKILL.md"
printf '{"hooks":{"PreToolUse":[]}}\n' > "$FAKE/.claude/settings.json"
OUT=$(doctor --roots "$FAKE/projetos" --apply)
[[ "$OUT" == *"skills/ com conteudo"* ]] && ok "~/.claude/skills vira DECISAO" || fail "skills nao virou decisao"
[[ "$OUT" == *"settings.json registra hooks"* ]] && ok "hooks no settings do usuario vira DECISAO" || fail "hooks do settings nao virou decisao"
[ -f "$FAKE/.claude/skills/minha-skill/SKILL.md" ] \
  && ok "--apply NAO apagou ~/.claude/skills (contra-prova)" \
  || fail "apagou skills do usuario — decisao virou acao"
rm -f "$FAKE/.claude/settings.json"; rm -rf "$FAKE/.claude/skills"

# ===========================================================================
echo "[squad-doctor] descoberta de projetos"
# ===========================================================================
mkdir -p "$FAKE/projetos/app-real/.claude/squad/project"
mkdir -p "$FAKE/projetos/app-real/node_modules/lixo/.claude/squad"
mkdir -p "$FAKE/projetos/app-real/.claude/worktrees/wt1/.claude/squad"
mkdir -p "$FAKE/projetos/sem-squad/src"
OUT=$(doctor --roots "$FAKE/projetos")
[[ "$OUT" == *"app-real"* ]] && ok "acha projeto com .claude/squad" || fail "nao achou o projeto"
[[ "$OUT" != *"sem-squad"* ]] && ok "ignora diretorio sem squad" || fail "listou projeto sem squad"
[[ "$OUT" == *"1 projeto(s)"* ]] \
  && ok "nao conta node_modules nem worktrees como projeto (contra-prova)" \
  || fail "contou falso projeto (node_modules/worktrees)"

# ===========================================================================
echo '[squad-doctor] sem a CLI claude nao quebra'
# ===========================================================================
# PATH so com o diretorio vazio derrubaria o proprio python3 (rc=127): resolver
# o interpretador ANTES e chamar por caminho absoluto. O que tem que sumir do
# PATH e a CLI `claude`, nao o resto do mundo.
VAZIO=$(mktemp -d); trap 'rm -rf "$FAKE" "$VAZIO"' EXIT
PY_BIN=$(command -v python3)
OUT=$(HOME="$FAKE" PATH="$VAZIO" "$PY_BIN" "$DOCTOR" --roots "$FAKE/projetos" 2>&1); RC=$?
[ "$RC" = 0 ] && [[ "$OUT" == *"CLI indisponivel"* ]] \
  && ok "sem \`claude\` no PATH: reporta achado e sai 0 (fail-open)" \
  || fail "quebrou sem a CLI (rc=$RC)"

# ===========================================================================
echo "[squad-doctor] lembrete da UP-01"
# ===========================================================================
OUT=$(doctor --roots "$FAKE/projetos")
[[ "$OUT" == *"PROXIMA sessao"* ]] \
  && ok "avisa que o plugin so vale na proxima sessao (UP-01)" \
  || fail "faltou o lembrete da UP-01"

if [ "$falhou" -ne 0 ]; then
  echo "squad-doctor-cases: FALHOU"
  exit 1
fi
echo "squad-doctor-cases: TUDO OK"
