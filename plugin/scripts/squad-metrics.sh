#!/usr/bin/env bash
# squad-metrics — métricas de saúde da squad coletadas do GitHub (não auto-relato).
#
# Uso: squad-metrics.sh [--repo owner/nome] [--limit N]
#   --repo   default: repo do diretório atual (gh repo view)
#   --limit  últimos N PRs mergeados (default: 10)
#
# Métricas (metas da squad):
#   achados-review  = comentários inline de review + reviews CHANGES_REQUESTED (meta: 0)
#   ciclos-ci       = runs de CI com conclusão failure no branch do PR + 1 (meta: 1)
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
  --json number,title,headRefName,mergedAt --jq 'sort_by(.number)')

export SM_REPO="$REPO" SM_PRS="$PRS_JSON"

python3 <<'PY'
import json, os, subprocess

repo = os.environ["SM_REPO"]
prs = json.loads(os.environ["SM_PRS"])
if not prs:
    print("nenhum PR mergeado encontrado")
    raise SystemExit(0)

def gh(*args):
    r = subprocess.run(["gh"] + list(args), capture_output=True, text=True, check=True)
    return r.stdout.strip()

rows, tot_ach, tot_cic = [], 0, 0
for pr in prs:
    n = pr["number"]
    inline = int(gh("api", f"repos/{repo}/pulls/{n}/comments", "--jq", "length") or 0)
    changes_req = int(gh("api", f"repos/{repo}/pulls/{n}/reviews",
                         "--jq", '[.[] | select(.state=="CHANGES_REQUESTED")] | length') or 0)
    achados = inline + changes_req
    branch = pr["headRefName"]
    try:
        fails = int(gh("api", f"repos/{repo}/actions/runs?head_branch={branch}&per_page=100",
                       "--jq", '[.workflow_runs[] | select(.conclusion=="failure")] | length') or 0)
        ciclos = fails + 1
    except Exception:
        ciclos = 1  # sem Actions no branch
    rows.append((n, pr["title"][:52], achados, ciclos))
    tot_ach += achados
    tot_cic += ciclos

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

hdr_pr, hdr_a, hdr_c = "PR", "achados", "ciclos-ci"
print(f"{hdr_pr:>5}  {hdr_a:>7}  {hdr_c:>9}  título")
for n, t, a, c in rows:
    print(f"#{n:>4}  {a:>7}  {c:>9}  {t}")
media = tot_cic / len(rows)
print()
print(f"saude: achados-review={tot_ach} ciclos-ci-media={media:.1f} retrabalho={retrab} (base: {len(rows)} PRs)")
if tot_ach == 0 and media <= 1.05 and retrab == 0:
    print("[OK] metas atingidas (achados=0, ciclos=1, retrabalho=0)")
else:
    print("[!] fora da meta — achado repetitivo vira item do engineer-self-review (loop de feedback)")
PY
