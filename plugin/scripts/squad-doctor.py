#!/usr/bin/env python3
"""squad-doctor — poe uma MAQUINA inteira no plugin dev-squad.

O `squad-migrate.py` resolve UM projeto. Faltavam as duas pontas que sobravam
para a mao e por isso eram esquecidas:

  (A) MAQUINA — marketplace + plugin instalados, e os restos do modelo antigo
      em `~/.claude` neutralizados. Agente user-scope com o mesmo nome de um
      agente do plugin SOMBREIA o do plugin: a sessao carrega a copia velha e
      ninguem percebe (foi assim que 9 duplicatas ficaram ativas por semanas).
  (B) FROTA — descobrir TODOS os projetos com squad e rodar o diagnostico em
      cada um. Migrar projeto por projeto de cabeca e como as versoes divergem:
      tres projetos da mesma maquina terminaram em tres estados diferentes.

O que este script NAO faz, de proposito: decidir o que e customizacao local.
Esse criterio (direcao do diff) vive no squad-migrate, que e chamado aqui — uma
fonte so.

Uso:
    squad-doctor.py [--roots DIR ...] [--apply] [--json]

    (sem --apply)  DRY-RUN: inventario + plano, nada e tocado (default)
    --apply        executa as acoes SEGURAS da maquina e propaga o --apply
                   para o squad-migrate de cada projeto

Nada e apagado. Restos user-scope sao MOVIDOS para `~/.claude/agents-disabled/`
(reversivel com um `mv`).
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

PLUGIN_ID = "dev-squad@pdati"
MARKETPLACE = "pdati"
MARKETPLACE_SRC = "Sync4-Technologies/template-project"
HOME_CLAUDE = Path.home() / ".claude"
CACHE = HOME_CLAUDE / "plugins/cache/pdati/dev-squad"


def sh(*args: str, timeout: int = 180) -> tuple[int, str]:
    """Roda comando e devolve (rc, saida). Nunca levanta."""
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return p.returncode, (p.stdout + p.stderr).strip()
    except Exception as e:  # noqa: BLE001 - diagnostico nunca derruba o script
        return 1, f"{type(e).__name__}: {e}"


def versoes_instaladas() -> list[str]:
    if not CACHE.is_dir():
        return []
    def chave(v: str) -> tuple:
        return tuple(int(x) if x.isdigit() else 0 for x in v.split("."))
    return sorted([d.name for d in CACHE.iterdir() if d.is_dir()], key=chave)


def plugin_root() -> Path | None:
    """Raiz da versao mais nova no cache — de onde sai o squad-migrate."""
    vs = versoes_instaladas()
    return (CACHE / vs[-1]) if vs else None


# ---------------------------------------------------------------- fase A: maquina

def diagnostico_maquina() -> dict:
    d: dict = {"achados": [], "acoes_seguras": [], "decisoes": []}

    vs = versoes_instaladas()
    d["versoes_no_cache"] = vs
    d["versao_instalada"] = vs[-1] if vs else None

    # marketplace registrado?
    rc, out = sh("claude", "plugin", "marketplace", "list")
    if rc != 0:
        d["achados"].append("`claude` CLI indisponivel — sem ela nao da para instalar nem atualizar o plugin")
        return d
    if MARKETPLACE not in out:
        d["acoes_seguras"].append({
            "tipo": "marketplace_add",
            "alvo": MARKETPLACE_SRC,
            "porque": f"marketplace `{MARKETPLACE}` nao registrado nesta maquina",
        })

    # plugin instalado?
    rc, out = sh("claude", "plugin", "list")
    if "dev-squad" not in out:
        d["acoes_seguras"].append({
            "tipo": "plugin_install",
            "alvo": PLUGIN_ID,
            "porque": "plugin nao instalado (escopo user vale para todos os projetos)",
        })
    else:
        d["acoes_seguras"].append({
            "tipo": "plugin_update",
            "alvo": PLUGIN_ID,
            "porque": "conferir/aplicar a versao mais nova publicada",
        })

    # restos do modelo antigo em ~/.claude
    root = plugin_root()
    nomes_plugin: set[str] = set()
    if root:
        for sub in ("agents", "template/agents"):
            p = root / sub
            if p.is_dir():
                nomes_plugin |= {f.stem for f in p.glob("*.md")}

    agentes_user = HOME_CLAUDE / "agents"
    if agentes_user.is_dir() and nomes_plugin:
        sombras = sorted(f.name for f in agentes_user.glob("*.md") if f.stem in nomes_plugin)
        if sombras:
            d["acoes_seguras"].append({
                "tipo": "mover_sombras",
                "alvo": ", ".join(sombras),
                "porque": "agente user-scope com o MESMO nome de um do plugin sombreia o do plugin — "
                          "a sessao carrega a copia velha em silencio. Move para agents-disabled/",
            })
        proprios = sorted(f.name for f in agentes_user.glob("*.md") if f.stem not in nomes_plugin)
        if proprios:
            d["achados"].append(
                f"{len(proprios)} agente(s) user-scope que NAO existem no plugin — deixados como estao "
                f"(sao seus, nao restos): {', '.join(proprios[:5])}"
                + (" ..." if len(proprios) > 5 else "")
            )

    for legado in ("skills", "commands"):
        p = HOME_CLAUDE / legado
        if p.is_dir() and any(p.iterdir()):
            d["decisoes"].append({
                "tema": f"~/.claude/{legado}/ com conteudo",
                "acao": f"o plugin registra as proprias {legado}; copia user-scope do modelo antigo roda "
                        f"em paralelo e diverge. Conferir item a item — pode haver coisa sua ai, "
                        f"por isso NAO e automatico",
            })

    s = HOME_CLAUDE / "settings.json"
    if s.is_file():
        try:
            if '"hooks"' in s.read_text(encoding="utf-8", errors="replace"):
                d["decisoes"].append({
                    "tema": "~/.claude/settings.json registra hooks",
                    "acao": "se apontarem para hooks do modelo antigo, rodam DUPLICADOS com os do plugin. "
                            "Conferir os paths; os do plugin nao precisam de registro manual",
                })
        except OSError:
            pass

    return d


def aplicar_maquina(plano: dict) -> list[str]:
    feito: list[str] = []
    for a in plano["acoes_seguras"]:
        t = a["tipo"]
        if t == "marketplace_add":
            rc, out = sh("claude", "plugin", "marketplace", "add", MARKETPLACE_SRC)
            feito.append(f"[{'OK' if rc == 0 else 'FALHOU'}] marketplace add {MARKETPLACE_SRC}")
        elif t == "plugin_install":
            rc, out = sh("claude", "plugin", "install", PLUGIN_ID)
            feito.append(f"[{'OK' if rc == 0 else 'FALHOU'}] plugin install {PLUGIN_ID}")
        elif t == "plugin_update":
            sh("claude", "plugin", "marketplace", "update", MARKETPLACE)
            rc, out = sh("claude", "plugin", "update", PLUGIN_ID)
            linha = out.splitlines()[-1] if out else ""
            feito.append(f"[{'OK' if rc == 0 else 'FALHOU'}] plugin update — {linha}")
        elif t == "mover_sombras":
            destino = HOME_CLAUDE / "agents-disabled"
            destino.mkdir(parents=True, exist_ok=True)
            movidos = []
            for nome in [x.strip() for x in a["alvo"].split(",")]:
                origem = HOME_CLAUDE / "agents" / nome
                if origem.is_file():
                    alvo = destino / nome
                    if alvo.exists():
                        alvo = destino / f"{origem.stem}.dup{origem.suffix}"
                    shutil.move(str(origem), str(alvo))
                    movidos.append(nome)
            if movidos:
                feito.append(f"[OK] {len(movidos)} agente(s) movido(s) para agents-disabled/: {', '.join(movidos)}")
    return feito


# ------------------------------------------------------------------ fase B: frota

def descobrir_projetos(roots: list[Path], profundidade: int = 3) -> list[Path]:
    achados: set[Path] = set()
    for root in roots:
        if not root.is_dir():
            continue
        base_depth = len(root.parts)
        for dirpath, dirnames, _ in os.walk(root):
            p = Path(dirpath)
            if len(p.parts) - base_depth > profundidade:
                dirnames[:] = []
                continue
            # nao descer em worktrees/caches: geram dezenas de falsos projetos
            dirnames[:] = [d for d in dirnames
                           if d not in {"node_modules", ".git", "worktrees", "archive", "cache"}]
            if (p / ".claude/squad").is_dir():
                achados.add(p)
                dirnames[:] = []
    return sorted(achados)


def diagnosticar_projeto(migrate: Path, proj: Path, apply_: bool) -> dict:
    args = [str(migrate), "--project", str(proj), "--json"]
    if apply_:
        args.append("--apply")
    rc, out = sh(*args, timeout=300)
    try:
        return json.loads(out[out.index("{"):out.rindex("}") + 1])
    except Exception:
        return {"projeto": str(proj), "estado": "ERRO", "erro": out[:200],
                "achados": 0, "acoes_seguras": 0, "decisoes": 0,
                "versao_registrada": None, "versao_instalada": None}


# ------------------------------------------------------------------------ saida

def imprimir(maquina: dict, projetos: list[dict], feito_maquina: list[str] | None) -> None:
    print("=== squad-doctor — MAQUINA ===")
    print(f"cache: {', '.join(maquina.get('versoes_no_cache') or ['(vazio)'])}"
          f" | instalada: {maquina.get('versao_instalada') or '-'}")

    if maquina["achados"]:
        print("\nAchados:")
        for a in maquina["achados"]:
            print(f"  - {a}")
    if maquina["acoes_seguras"]:
        print("\nAcoes SEGURAS (deterministicas):")
        for a in maquina["acoes_seguras"]:
            print(f"  - [{a['tipo']}] {a['alvo']}")
            print(f"      porque: {a['porque']}")
    if maquina["decisoes"]:
        print("\nDECISOES do usuario (nao automatizaveis):")
        for d in maquina["decisoes"]:
            print(f"  - {d['tema']}")
            print(f"      -> {d['acao']}")
    if feito_maquina:
        print("\nAplicado (maquina):")
        for f in feito_maquina:
            print(f"  {f}")

    print(f"\n=== squad-doctor — FROTA ({len(projetos)} projeto(s) com squad) ===")
    if projetos:
        largura = max(len(Path(p["projeto"]).name) for p in projetos)
        print(f"  {'projeto'.ljust(largura)}  {'registrada':>10}  {'estado':<14}  pendencias")
        for p in projetos:
            nome = Path(p["projeto"]).name.ljust(largura)
            reg = str(p.get("versao_registrada") or "-").rjust(10)
            est = str(p.get("estado") or "-")[:14].ljust(14)
            # os campos vem como LISTA no --json do squad-migrate, nao como contagem
            def n(campo: str) -> int:
                v = p.get(campo)
                return len(v) if isinstance(v, list) else int(v or 0)
            pend = []
            if n("acoes_seguras"):
                pend.append(f"{n('acoes_seguras')} auto")
            if n("decisoes"):
                pend.append(f"{n('decisoes')} decisao")
            if n("achados"):
                pend.append(f"{n('achados')} achado")
            print(f"  {nome}  {reg}  {est}  {', '.join(pend) or 'nada'}")
        print("\n  Detalhe de cada um: squad-migrate.py --project <dir>")

    def _n(p: dict, campo: str) -> int:
        v = p.get(campo)
        return len(v) if isinstance(v, list) else int(v or 0)
    total_dec = sum(_n(p, "decisoes") for p in projetos)
    if total_dec:
        print(f"\n[!] {total_dec} decisao(oes) esperando voce — nenhuma foi tocada.")
    print("\n[!] Plugin novo so vale na PROXIMA sessao do Claude Code (UP-01). "
          "Reinicie antes de usar a governanca nova.")


def main() -> int:
    ap = argparse.ArgumentParser(description="Poe uma maquina inteira no plugin dev-squad")
    ap.add_argument("--roots", nargs="*", default=None,
                    help="diretorios onde procurar projetos (default: ~/srv, ~/dev, ~/projects, ~/code)")
    ap.add_argument("--apply", action="store_true", help="executa as acoes seguras")
    ap.add_argument("--json", action="store_true", dest="as_json", help="saida JSON")
    args = ap.parse_args()

    maquina = diagnostico_maquina()
    feito = aplicar_maquina(maquina) if args.apply else None

    root = plugin_root()
    migrate = (root / "scripts/squad-migrate.py") if root else None

    roots = [Path(r).expanduser() for r in args.roots] if args.roots else [
        Path.home() / d for d in ("srv", "dev", "projects", "code")
    ]
    projetos: list[dict] = []
    if migrate and migrate.is_file():
        for proj in descobrir_projetos(roots):
            projetos.append(diagnosticar_projeto(migrate, proj, args.apply))
    else:
        maquina["achados"].append(
            "squad-migrate.py nao encontrado no cache — instale o plugin primeiro "
            "(rode este script com --apply) e rode de novo para a frota")

    if args.as_json:
        print(json.dumps({"maquina": maquina, "aplicado_maquina": feito, "projetos": projetos},
                         ensure_ascii=False, indent=2))
        return 0

    imprimir(maquina, projetos, feito)
    if not args.apply:
        print("\nDRY-RUN — nada foi tocado. Rode com --apply para executar as acoes seguras.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
