#!/usr/bin/env bash
# Hook: PreToolUse (matcher: Bash) — ÚNICO hook do plugin neste evento.
#
# Funde `push-gate.sh` + `memory-update-reminder.sh` (v2.0). Antes, todo comando
# Bash da sessão pagava DOIS subprocessos python, quase sempre para concluir
# "não é push nem commit -> exit 0": o parse caro rodava antes do teste barato.
# Agora: ZERO subprocesso no caso comum, UM no pior caso.
#
# Duas responsabilidades, independentes:
#   [push]   gate determinístico — avisa quando o marcador não cobre o HEAD
#            (advisory por padrão desde v1.8.0/UP-05; enforce é opt-in), e avisa
#            quando a branch tem PR MERGED/CLOSED (UP-01).
#   [commit] reminder de memória — commit que toca código de produção sem tocar
#            `.claude/squad/project/` sugere onde registrar (advisory, opt-in).
#
# Modo ENFORCE (bloqueio duro no push, opt-in por projeto):
#   - env SQUAD_GATE_ENFORCE=1 (via "env" no settings.json do projeto), OU
#   - arquivo .claude/squad/project/gate-enforce no repo-alvo
# Escape (só relevante no enforce): SQUAD_SKIP_GATE=1 — aceito no env do processo
# e INLINE no comando (UP-04: o hook roda no processo do harness, antes do shell
# do comando existir, então o prefixo inline não chega ao env).

set -u

INPUT="$(cat)"

# ---------------------------------------------------------------------------
# EARLY-EXIT BARATO — o ponto da fusão.
#
# Isto NÃO é a volta da UP-06. Aqui a substring é FILTRO NEGATIVO, nunca decisão:
# execução implica menção, logo a AUSÊNCIA da substring prova que não é execução
# e o descarte é seguro. A PRESENÇA não decide nada — cai no parser preciso
# abaixo (primeiro verbo por segmento, heredoc descartado), que é quem decide.
# A direção do erro é o que importa: falso positivo aqui custa um python que já
# rodava antes; falso negativo é impossível.
# ---------------------------------------------------------------------------
case "$INPUT" in
  *push*|*commit*) ;;
  *) exit 0 ;;
esac

# ---------------------------------------------------------------------------
# Parse único do payload (stdin não pode ser lido duas vezes; e um python é o
# orçamento). Devolve 5 linhas: cwd, is_push, is_commit, skip_inline, refspecs.
#
# `cwd` é a worktree onde o comando roda — usar isso em vez de
# $CLAUDE_PROJECT_DIR é o que corrige o bug worktree-blind (AM-18/UP-03).
# ---------------------------------------------------------------------------
PAYLOAD=$(printf '%s' "$INPUT" | python3 -c '
import json, sys, re

def bail():
    print(""); print("0"); print("0"); print("0"); print("")
    sys.exit(0)

try:
    d = json.load(sys.stdin)
    cwd = d.get("cwd", "") or ""
    cmd = d.get("tool_input", {}).get("command", "") or ""
except Exception:
    bail()

# Melhor esforço: descarta corpos de heredoc (<<EOF ... EOF) antes de analisar.
stripped = re.sub(
    r"<<-?\s*([\x27\"]?)(\w+)\1.*?\n\s*\2\s*(\n|$)", "\n", cmd, flags=re.S
)

GIT_OPTS = r"(\s+(-C\s+\S+|-c\s+\S+|--[\w-]+(=\S+)?))*"
push = commit = 0
refspecs = []

for seg in re.split(r"&&|\|\||;|\||\n", stripped):
    seg = seg.strip()
    # pula atribuicoes de env no inicio do segmento (VAR=x git push ...)
    while re.match(r"^[A-Za-z_][A-Za-z0-9_]*=\S*\s+", seg):
        seg = re.sub(r"^[A-Za-z_][A-Za-z0-9_]*=\S*\s+", "", seg, count=1)

    m = re.match(r"^(command\s+)?git" + GIT_OPTS + r"\s+push(\s|$)", seg)
    if m:
        push = 1
        # UP-02: o que este push empurra. Posicionais depois do remote; flags e
        # seus valores fora. Vazio = empurra a branch atual (upstream/default).
        rest = seg[m.end():].split()
        FLAG_WITH_VALUE = ("--repo", "-o", "--push-option", "--receive-pack",
                           "--exec", "--force-with-lease")
        positional = []
        skip_next = False
        for tok in rest:
            if skip_next:
                skip_next = False
                continue
            if tok.startswith("-"):
                if tok in FLAG_WITH_VALUE:
                    skip_next = True
                continue
            positional.append(tok)
        if "--tags" in rest or "--mirror" in rest:
            refspecs.append("__TAGS__")
        # positional[0] e o remote; o resto sao refspecs
        refspecs.extend(positional[1:])
        continue

    if re.match(r"^(command\s+)?git" + GIT_OPTS + r"\s+commit(\s|$)", seg):
        commit = 1

skip = 1 if re.search(r"(^|\s)SQUAD_SKIP_GATE=1(\s|$)", cmd) else 0

print(cwd); print(push); print(commit); print(skip); print(" ".join(refspecs))
' 2>/dev/null)

CWD=$(printf '%s\n' "$PAYLOAD" | sed -n '1p')
IS_PUSH=$(printf '%s\n' "$PAYLOAD" | sed -n '2p')
IS_COMMIT=$(printf '%s\n' "$PAYLOAD" | sed -n '3p')
SKIP_INLINE=$(printf '%s\n' "$PAYLOAD" | sed -n '4p')
REFSPECS=$(printf '%s\n' "$PAYLOAD" | sed -n '5p')

# Nem push nem commit EXECUTADO (só mencionado) -> seguir
[ "$IS_PUSH" = "1" ] || [ "$IS_COMMIT" = "1" ] || exit 0

# PROJECT_ROOT prioriza o cwd real do comando (worktree correto). Fallback para
# $CLAUDE_PROJECT_DIR e $(pwd) para Claude Code sem `cwd` no payload.
PROJECT_ROOT="${CWD:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

# Sem squad no projeto — checa PROJECT_ROOT e $CLAUDE_PROJECT_DIR para cobrir
# subagent em worktree (compartilha object db/config com a main).
if [ ! -d "${PROJECT_ROOT}/.claude/squad/project" ] && \
   [ ! -d "${CLAUDE_PROJECT_DIR:-/nonexistent}/.claude/squad/project" ]; then
  exit 0
fi

cd "$PROJECT_ROOT" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# ===========================================================================
# RAMO COMMIT — reminder de memória (não bloqueia nunca; sai em JSON no stdout)
# ===========================================================================
REMINDER=""
if [ "$IS_COMMIT" = "1" ]; then
  STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")
  if [ -n "$STAGED" ] && \
     printf '%s\n' "$STAGED" | grep -qE "^(src/|lib/|app/|backend/|frontend/|mobile/|api/|services/|domain/|adapters/|application/|infrastructure/)" && \
     ! printf '%s\n' "$STAGED" | grep -qE "\.claude/squad/project/(DECISIONS_LOG\.md|ARCHITECTURE\.md|ADR/|agent-memory/)"; then
    REMINDER="Reminder: commit inclui mudanças em código de produção mas NÃO há atualização correspondente em .claude/squad/project/ (DECISIONS_LOG.md, ARCHITECTURE.md, ADR/ ou agent-memory/). Considere: (a) decisão técnica relevante → registrar em DECISIONS_LOG.md; (b) decisão estrutural → criar ADR específico do projeto; (c) mudança arquitetural → atualizar ARCHITECTURE.md; (d) learning do agente → atualizar agent-memory/{agente}.md. Se a mudança não tem implicação documental, pode prosseguir com commit. Para handoff multi-usuário, considere /squad-handoff antes de encerrar sessão."
  fi
fi

emit_reminder_and_exit() {
  if [ -n "$REMINDER" ]; then
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "${REMINDER}"
  }
}
EOF
  fi
  exit 0
}

# ===========================================================================
# RAMO PUSH — gate determinístico
# ===========================================================================
[ "$IS_PUSH" = "1" ] || emit_reminder_and_exit

# Modo do gate: advisory (padrão) ou enforce (opt-in do projeto)
ENFORCE=0
if [ "${SQUAD_GATE_ENFORCE:-0}" = "1" ] || [ -f "${PROJECT_ROOT}/.claude/squad/project/gate-enforce" ]; then
  ENFORCE=1
fi

# Escape consciente — env do processo OU inline no comando (UP-04)
if [ "${SQUAD_SKIP_GATE:-0}" = "1" ] || [ "$SKIP_INLINE" = "1" ]; then
  echo "[pre-bash] SQUAD_SKIP_GATE=1 — gate pulado conscientemente (registrar o porquê no PR)." >&2
  emit_reminder_and_exit
fi

# No modo enforce, um aviso bloqueia; no advisory, informa e deixa passar.
warned() {
  if [ "$ENFORCE" = "1" ]; then
    echo "[pre-bash] BLOQUEADO (modo enforce ativo neste projeto). Escape consciente: SQUAD_SKIP_GATE=1 inline no comando." >&2
    exit 2
  fi
  emit_reminder_and_exit
}

# `--git-dir` num worktree retorna `.git/worktrees/<name>` — é lá que o
# pre-commit-quality do subagent grava o marcador. NÃO usar `--git-common-dir`,
# que devolve o `.git` compartilhado (main worktree) e reintroduz o bug AM-18.
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || exit 0
BRANCH=$(git branch --show-current 2>/dev/null)

# --- UP-01: branch cujo PR já está MERGED/CLOSED está morta ---------------
# 2.2 do plano: `gh pr view` sai do caminho SÍNCRONO. O push lê o cache gravado
# pelo push anterior (zero rede) e dispara o refresh em BACKGROUND para o
# próximo. Consequência aceita e explícita: numa branch que morreu agora, o
# aviso chega no push SEGUINTE — o custo da UP-01 é trabalho invisível
# acumulado, que um push de atraso não muda. Antes, todo push pagava segundos
# de rede no caminho crítico para um check fail-open.
#
# UP-02: push que não empurra a branch atual (tag, refspec explícito de outra
# ref, --tags) não é o caso da UP-01 — a branch morta não está sendo tocada.
CHECK_UP01=1
if [ -n "$REFSPECS" ]; then
  CHECK_UP01=0
  for ref in $REFSPECS; do
    case "$ref" in
      "$BRANCH"|"$BRANCH":*|HEAD|HEAD:*) CHECK_UP01=1 ;;
    esac
  done
fi

PR_CACHE="$GIT_DIR/squad-pr-state"
if [ "$CHECK_UP01" = "1" ] && [ -n "$BRANCH" ]; then
  NOW=$(date +%s 2>/dev/null || echo 0)

  if [ -r "$PR_CACHE" ]; then
    # formato: <branch>TAB<state>TAB<epoch>
    C_BRANCH=$(cut -f1 "$PR_CACHE" 2>/dev/null)
    C_STATE=$(cut -f2 "$PR_CACHE" 2>/dev/null)
    C_EPOCH=$(cut -f3 "$PR_CACHE" 2>/dev/null)
    : "${C_EPOCH:=0}"
    AGE=$(( NOW - C_EPOCH ))
    # >24h é velho demais: nome de branch se recicla, e estado terminal antigo
    # de outra encarnação da branch geraria aviso falso.
    if [ "$C_BRANCH" = "$BRANCH" ] && [ "$AGE" -lt 86400 ] && \
       { [ "$C_STATE" = "MERGED" ] || [ "$C_STATE" = "CLOSED" ]; }; then
      cat >&2 <<UPMSG
[pre-bash] AVISO (UP-01): a branch '$BRANCH' tem PR $C_STATE — branch morta.
Push aqui tende a ser trabalho invisível. O caminho normal é branch nova a partir da base:
  git fetch origin && git switch -c <nova-branch> origin/<base>
(estado lido do cache local, sem rede; refresh em background para o próximo push)
UPMSG
      warned
    fi
  fi

  # Refresh assíncrono para o próximo push. Fail-open: sem gh, sem auth,
  # timeout ou processo morto pelo harness -> o cache só não atualiza.
  if command -v gh >/dev/null 2>&1; then
    (
      ST=$(gh pr view "$BRANCH" --json state --jq .state 2>/dev/null)
      if [ -n "$ST" ]; then
        printf '%s\t%s\t%s\n' "$BRANCH" "$ST" "$NOW" > "$PR_CACHE.tmp" 2>/dev/null \
          && mv "$PR_CACHE.tmp" "$PR_CACHE" 2>/dev/null
      fi
    ) >/dev/null 2>&1 &
    disown 2>/dev/null || true
  fi
fi

# --- marcador do gate determinístico -------------------------------------
HEAD_TREE=$(git rev-parse "HEAD^{tree}" 2>/dev/null) || exit 0
MARKER=$(cat "$GIT_DIR/squad-gate-ok" 2>/dev/null || echo "")

[ "$MARKER" = "$HEAD_TREE" ] && emit_reminder_and_exit

cat >&2 <<'MSG'
[pre-bash] AVISO: o gate determinístico não validou o HEAD atual.
Recomendado antes do push: rodar o gate completo (format + lint + typecheck + testes):
  .githooks/pre-commit-quality   (grava o marcador ao passar)
Se o hook não está instalado neste projeto, instale via /squad-init (passo de gates).
Rebase/amend invalida o marcador — re-rodar o gate é o comportamento esperado.
MSG
warned
