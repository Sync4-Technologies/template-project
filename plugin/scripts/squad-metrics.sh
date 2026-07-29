#!/usr/bin/env bash
# squad-metrics — métricas de saúde da squad coletadas do GitHub (não auto-relato).
#
# Uso: squad-metrics.sh [--repo owner/nome] [--limit N]
#   --repo   default: repo do diretório atual (gh repo view)
#   --limit  últimos N PRs mergeados (default: 10)
#
# Métricas (leitura em squad-handoff 5d):
#   achados-review  = comentários inline + reviews CHANGES_REQUESTED. LEITURA DUPLA (v1.9.0):
#                     0 achados COM revisão registrada = alarme de gate morto; 0 achados SEM
#                     revisão = o dado não existe (review rodou em sessão, fora do GitHub)
#   revisoes        = reviews registradas no GitHub — separa "reviewer não achou" de "reviewer
#                     nunca rodou" (AM-39: `achados=0` sozinho não distinguia os dois)
#   ciclos-ci       = runs failure com trabalho REAL + 1. Runs cujos jobs têm 0 steps (billing
#                     esgotado, runner fora) são DESCARTADOS e reportados à parte — contá-los
#                     dava média 98.0 sem uma única falha de código (AM-39)
#   retrabalho      = PRs de revert mergeados citando PRs do range (aproximação; meta: 0)
#
# Saída: tabela por PR + linha `saude:` pronta pro Session Log (squad-handoff step 5d).
set -euo pipefail

REPO=""
LIMIT=10
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    *) echo "arg desconhecido: $1" >&2; exit 2 ;;
  esac
done

command -v gh >/dev/null 2>&1 || { echo "gh CLI não disponível — usar auto-relato como fallback (handoff 5d)"; exit 3; }
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) || { echo "não é repo GitHub — informe --repo"; exit 2; }
fi

PRS_JSON=$(gh pr list --repo "$REPO" --state merged --limit "$LIMIT" \
  --json number,title,headRefName,createdAt,mergedAt --jq 'sort_by(.number)')

export SM_REPO="$REPO" SM_PRS="$PRS_JSON"

python3 <<'PY'
import json, os, subprocess, time

repo = os.environ["SM_REPO"]
prs = json.loads(os.environ["SM_PRS"])
if not prs:
    print("nenhum PR mergeado encontrado")
    raise SystemExit(0)

def gh(*args, tentativas=3):
    """Erro de API do gh e transiente com frequencia (rate limit, rede) — 1 falha nao pode
    derrubar a coleta inteira no meio."""
    ultimo = None
    for _ in range(tentativas):
        r = subprocess.run(["gh"] + list(args), capture_output=True, text=True)
        if r.returncode == 0:
            return r.stdout.strip()
        ultimo = (r.returncode, r.stderr.strip()[:200])
        time.sleep(1.5)
    raise RuntimeError(f"gh falhou {tentativas}x: {ultimo}")

MAX_RUNS_INSPECIONADOS = 20  # teto de chamadas por PR; excedente é reportado, não silenciado

def falha_com_trabalho_real(run_id):
    """False quando todos os jobs do run têm 0 steps — sintoma de billing esgotado /
    runner indisponível (AM-39). Na dúvida (erro de API) conta como falha real."""
    try:
        steps = gh("api", f"repos/{repo}/actions/runs/{run_id}/jobs",
                   "--jq", "[.jobs[].steps | length] | add // 0")
        return int(steps or 0) > 0
    except Exception:
        return True

rows, tot_ach, tot_cic, tot_rev = [], 0, 0, 0
infra_desc, truncados = 0, 0
for pr in prs:
    n = pr["number"]
    inline = int(gh("api", f"repos/{repo}/pulls/{n}/comments", "--jq", "length") or 0)
    reviews = json.loads(gh("api", f"repos/{repo}/pulls/{n}/reviews",
                            "--jq", "[.[] | {state}]") or "[]")
    changes_req = sum(1 for r in reviews if r.get("state") == "CHANGES_REQUESTED")
    achados = inline + changes_req
    revisoes = len(reviews)
    branch = pr["headRefName"]
    # Janela de vida do PR: sem isso, PR cujo head e branch longeva (release develop->main,
    # sync main->develop) herda o historico INTEIRO de falhas daquela branch.
    ini, fim = pr.get("createdAt") or "", pr.get("mergedAt") or "9999"
    try:
        ids = json.loads(gh("api", f"repos/{repo}/actions/runs?head_branch={branch}&per_page=100",
                            "--jq", '[.workflow_runs[] | select(.conclusion=="failure") '
                                    '| {id, created_at}]') or "[]")
        ids = [r["id"] for r in ids if ini <= r.get("created_at", "") <= fim]
        if len(ids) > MAX_RUNS_INSPECIONADOS:
            truncados += len(ids) - MAX_RUNS_INSPECIONADOS
            ids = ids[:MAX_RUNS_INSPECIONADOS]
        reais = [i for i in ids if falha_com_trabalho_real(i)]
        infra_desc += len(ids) - len(reais)
        ciclos = len(reais) + 1
    except Exception:
        ciclos = 1  # sem Actions no branch
    rows.append((n, pr["title"][:52], achados, revisoes, ciclos))
    tot_ach += achados
    tot_cic += ciclos
    tot_rev += revisoes

nums = {r[0] for r in rows}
retrab = 0
try:
    fixes = json.loads(gh("pr", "list", "--repo", repo, "--state", "merged", "--limit", "50",
                          "--search", "revert in:title", "--json", "number,body,title") or "[]")
    for f in fixes:
        text = (f.get("body") or "") + (f.get("title") or "")
        if any(f"#{n}" in text for n in nums):
            retrab += 1
except Exception:
    pass

print(f"{'PR':>5}  {'achados':>7}  {'revisoes':>8}  {'ciclos-ci':>9}  título")
for n, t, a, rv, c in rows:
    print(f"#{n:>4}  {a:>7}  {rv:>8}  {c:>9}  {t}")
media = tot_cic / len(rows)
print()
print(f"saude: achados-review={tot_ach} revisoes={tot_rev} ciclos-ci-media={media:.1f} "
      f"retrabalho={retrab} (base: {len(rows)} PRs)")

if infra_desc:
    print(f"[i] {infra_desc} run(s) failure descartado(s): 0 steps executados "
          f"(billing/runner, nao qualidade) — AM-39")
if truncados:
    print(f"[i] {truncados} run(s) failure NAO inspecionado(s) (teto de {MAX_RUNS_INSPECIONADOS}/PR) "
          f"— ciclos-ci pode estar subestimado")

# Leitura da metrica (v1.9.0 desinverteu achados-review; AM-39 separou "nao achou" de "nao rodou")
if tot_rev == 0:
    print("[!] ZERO revisoes registradas no GitHub. Se o review rodou em sessao (subagent "
          "code-reviewer), os achados NAO estao neste numero — registrar a contagem real no "
          "Session Log a mao. Se nao rodou review nenhum: gate de review nao existiu neste range")
elif tot_ach == 0:
    print("[!] ALARME: revisoes rodaram e produziram ZERO achados. Em PR nao-trivial isso e "
          "sinal de gate morto (reviewer complacente), nao de saude — exigir 'Caca documentada' "
          "e pautar com o usuario")
else:
    print(f"[OK] gate de review produzindo sinal ({tot_ach} achados em {tot_rev} revisoes). "
          "Achado repetitivo vira item do engineer-self-review (loop de feedback)")
if media > 1.05:
    print(f"[!] ciclos-ci {media:.1f} acima da meta (1) — investigar causa real antes de "
          "tratar como qualidade")
if retrab:
    print(f"[!] retrabalho={retrab} (meta 0) — revert indica falha que passou por todos os gates")
PY
