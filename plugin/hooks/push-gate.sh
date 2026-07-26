#!/usr/bin/env bash
# Hook: PreToolUse (matcher: Bash)
# ADVISORY por padrão (v1.8.0): avisa quando o gate determinístico não validou o
# HEAD atual, mas NÃO bloqueia. Quem decide é o usuário/TL, não o hook.
# Mecânica: pre-commit-quality grava a árvore validada em $GIT_DIR/squad-gate-ok;
# aqui comparamos com HEAD^{tree}.
#
# Racional da mudança (UP-05): 4 falsos positivos em 2 sessões (tag, refspec,
# cross-repo, menção em mensagem de commit) — bloqueio duro transfere o custo do
# erro do hook para o usuário. Aviso carrega a mesma informação sem sequestrar o fluxo.
#
# Modo ENFORCE (bloqueio duro, opt-in por projeto):
#   - env SQUAD_GATE_ENFORCE=1 (via "env" no settings.json do projeto), OU
#   - arquivo .claude/squad/project/gate-enforce presente no repo-alvo
#
# Escape (só relevante no modo enforce): SQUAD_SKIP_GATE=1 — aceito tanto no env
# do processo quanto INLINE no comando (UP-04: o hook roda no processo do harness,
# antes do shell do comando existir, então o prefixo inline não chegava ao env).
set -u

# Extrai tudo do payload em UMA chamada python (stdin não pode ser lido duas vezes).
# `cwd` é a worktree onde o comando roda — usar isso em vez de $CLAUDE_PROJECT_DIR
# corrige o bug worktree-blind (AM-18/UP-03; fix da 1.5.0 restaurado na 1.7.0).
# A detecção de `git push` é por PRIMEIRO VERBO de cada segmento (&&, ;, |, quebra
# de linha), com corpos de heredoc removidos antes (UP-06: substring na string
# inteira tratava MENÇÃO como EXECUÇÃO — commit cuja mensagem citava `git push`
# era barrado).
PAYLOAD=$(python3 -c '
import json, sys, re
try:
    d = json.load(sys.stdin)
    cwd = d.get("cwd", "") or ""
    cmd = d.get("tool_input", {}).get("command", "") or ""
except Exception:
    print(""); print("0"); print("0"); sys.exit(0)

# Melhor esforço: descarta corpos de heredoc (<<EOF ... EOF) antes de analisar.
stripped = re.sub(
    r"<<-?\s*([\x27\"]?)(\w+)\1.*?\n\s*\2\s*(\n|$)", "\n", cmd, flags=re.S
)

push = 0
for seg in re.split(r"&&|\|\||;|\||\n", stripped):
    seg = seg.strip()
    # pula atribuicoes de env no inicio do segmento (VAR=x git push ...)
    while re.match(r"^[A-Za-z_][A-Za-z0-9_]*=\S*\s+", seg):
        seg = re.sub(r"^[A-Za-z_][A-Za-z0-9_]*=\S*\s+", "", seg, count=1)
    if re.match(r"^(command\s+)?git(\s+(-C\s+\S+|-c\s+\S+|--[\w-]+(=\S+)?))*\s+push(\s|$)", seg):
        push = 1
        break

skip = 1 if re.search(r"(^|\s)SQUAD_SKIP_GATE=1(\s|$)", cmd) else 0
print(cwd); print(push); print(skip)
' 2>/dev/null)

CWD=$(printf '%s\n' "$PAYLOAD" | sed -n '1p')
IS_PUSH=$(printf '%s\n' "$PAYLOAD" | sed -n '2p')
SKIP_INLINE=$(printf '%s\n' "$PAYLOAD" | sed -n '3p')

# Não é git push (executado, não mencionado) -> seguir
[ "$IS_PUSH" = "1" ] || exit 0

# PROJECT_ROOT prioriza o cwd real do comando (worktree correto). Fallback para
# $CLAUDE_PROJECT_DIR e $(pwd) para compatibilidade com Claude Code sem `cwd` no payload.
PROJECT_ROOT="${CWD:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

# Sem squad no projeto — checa tanto PROJECT_ROOT quanto $CLAUDE_PROJECT_DIR pra
# cobrir subagent worktree (que compartilha o marker/config do main via git object db).
if [ ! -d "${PROJECT_ROOT}/.claude/squad/project" ] && \
   [ ! -d "${CLAUDE_PROJECT_DIR:-/nonexistent}/.claude/squad/project" ]; then
  exit 0
fi

# Modo do gate: advisory (padrão) ou enforce (opt-in do projeto)
ENFORCE=0
if [ "${SQUAD_GATE_ENFORCE:-0}" = "1" ] || [ -f "${PROJECT_ROOT}/.claude/squad/project/gate-enforce" ]; then
  ENFORCE=1
fi

# Escape consciente — env do processo OU inline no comando (UP-04)
if [ "${SQUAD_SKIP_GATE:-0}" = "1" ] || [ "$SKIP_INLINE" = "1" ]; then
  echo "[push-gate] SQUAD_SKIP_GATE=1 — gate pulado conscientemente (registrar o porquê no PR)." >&2
  exit 0
fi

cd "$PROJECT_ROOT" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Saída: no modo enforce bloqueia (exit 2); no advisory avisa e deixa passar (exit 0).
finish() {
  if [ "$ENFORCE" = "1" ]; then
    echo "[push-gate] BLOQUEADO (modo enforce ativo neste projeto). Escape consciente: SQUAD_SKIP_GATE=1 inline no comando." >&2
    exit 2
  fi
  exit 0
}

# UP-01: branch com PR já MERGED/CLOSED está morta — push nela é trabalho invisível.
# Fail-open: sem gh, sem auth ou timeout -> não interferir.
BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ] && command -v gh >/dev/null 2>&1; then
  PR_STATE=$(gh pr view "$BRANCH" --json state --jq .state 2>/dev/null || echo "")
  if [ "$PR_STATE" = "MERGED" ] || [ "$PR_STATE" = "CLOSED" ]; then
    cat >&2 <<UPMSG
[push-gate] AVISO (UP-01): a branch '$BRANCH' tem PR $PR_STATE — branch morta.
Push aqui tende a ser trabalho invisível. O caminho normal é branch nova a partir da base:
  git fetch origin && git switch -c <nova-branch> origin/<base>
UPMSG
    finish
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
[push-gate] AVISO: o gate determinístico não validou o HEAD atual.
Recomendado antes do push: rodar o gate completo (format + lint + typecheck + testes):
  .githooks/pre-commit-quality   (grava o marcador ao passar)
Se o hook não está instalado neste projeto, instale via /squad-init (passo de gates).
Rebase/amend invalida o marcador — re-rodar o gate é o comportamento esperado.
MSG
finish
