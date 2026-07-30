#!/usr/bin/env python3
"""squad-migrate — diagnostica e migra um projeto para o plugin dev-squad puro.

Resolve o problema real: projetos adotados em epocas diferentes ficam em estados
diferentes (template clonado, hibrido, plugin puro) e a atualizacao era manual,
projeto por projeto, maquina por maquina. Aqui a parte deterministica e automatica;
so o que e decisao humana sobe para o usuario.

Uso:
    squad-migrate.py [--project DIR] [--apply] [--plugin-cache DIR]

    (sem --apply)  DRY-RUN: inventario + plano, nada e tocado (default)
    --apply        executa as acoes classificadas como SEGURAS
    --json         saida legivel por maquina (para a skill consumir)

Como decide o que e seguro (a ideia central):
    O que importa nao e "o arquivo local difere do plugin?" — quase sempre difere,
    porque o plugin evoluiu. O que importa e a DIRECAO da diferenca:

      nenhuma linha exclusiva do local  -> copia DEFASADA (o plugin contem tudo que
                                           ela tem, e mais) -> remover e seguro
      linhas exclusivas do local        -> conteudo que existe SO ali: customizacao
                                           deliberada ou patch local -> ESCALAR, com
                                           as linhas exclusivas no relatorio
      sem par no plugin                 -> artefato proprio do projeto -> PRESERVAR

    A comparacao roda contra TODAS as versoes no cache e usa a de melhor casamento
    (a que deixa menos linhas exclusivas). Assim funciona tambem em projeto pre-plugin,
    onde nao existe SQUAD_VERSION confiavel para servir de referencia. Comparar so com
    a versao atual diria "tudo divergiu" e enterraria o sinal que importa.

Nunca toca: .claude/squad/project/ (memoria do projeto), .env, codigo do produto.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

CACHE_DEFAULT = Path.home() / ".claude/plugins/cache/pdati/dev-squad"

# Diretorios locais que o plugin passou a fornecer (legado de template clonado).
# destino_no_plugin=None -> o diretorio inteiro e legado, sem equivalente 1:1.
DUPLICADOS = [
    (".claude/skills", "skills"),
    (".claude/hooks", "hooks"),
    (".claude/agents", "agents"),
    (".claude/squad/template", "template"),
]


def versoes_no_cache(cache: Path) -> list[str]:
    if not cache.is_dir():
        return []
    vs = [d.name for d in cache.iterdir() if d.is_dir() and re.match(r"^\d+\.\d+\.\d+$", d.name)]
    return sorted(vs, key=lambda v: [int(x) for x in v.split(".")])


def ler_squad_version(proj: Path) -> str | None:
    f = proj / ".claude/squad/project/SQUAD_VERSION"
    if not f.is_file():
        return None
    m = re.search(r"(\d+\.\d+\.\d+)", f.read_text(encoding="utf-8", errors="replace"))
    return m.group(1) if m else None


def arquivos(base: Path) -> list[Path]:
    return sorted(p for p in base.rglob("*") if p.is_file())


# Ruido do proprio layout legado: a copia local referencia o template clonado, o
# plugin referencia ${CLAUDE_PLUGIN_ROOT}. E a MESMA linha escrita em dois layouts —
# sem normalizar, cada referencia dessas viraria "customizacao local" e o relatorio
# afogaria o sinal real em dezenas de falsos positivos.
NORMALIZACOES = [
    (re.compile(r"\.claude/squad/template/"), "${CLAUDE_PLUGIN_ROOT}/template/"),
    (re.compile(r"\.claude/skills/"), "${CLAUDE_PLUGIN_ROOT}/skills/"),
    (re.compile(r"\.claude/hooks/"), "${CLAUDE_PLUGIN_ROOT}/hooks/"),
    (re.compile(r"\$\{CLAUDE_PROJECT_DIR\}/\.claude/"), "${CLAUDE_PLUGIN_ROOT}/"),
]


# Linha sem conteudo proprio: separador de tabela, regua, bullet vazio. Comparar isso
# gera falso positivo por padding, nao por semantica.
ESTRUTURAL = re.compile(r"^[|\-:\s#*>=_`+.]+$")


def _linhas(p: Path) -> set[str]:
    txt = p.read_text(encoding="utf-8", errors="replace")
    out = set()
    for l in txt.splitlines():
        l = l.strip()
        if not l or ESTRUTURAL.match(l):
            continue
        for pat, rep in NORMALIZACOES:
            l = pat.sub(rep, l)
        # padding de coluna de tabela markdown e reindentacao nao sao customizacao
        l = re.sub(r"\s+", " ", l)
        out.add(l)
    return out


def classificar(local_dir: Path, ref_dirs: list[tuple[str, Path]]) -> dict:
    """Classifica cada arquivo local pela DIRECAO do diff contra o melhor casamento.

    defasados  = o plugin contem tudo que o local tem (nenhuma linha exclusiva) -> seguro remover
    exclusivos = local tem linha que nao existe em nenhuma versao do plugin -> escalar
    sem_par    = nao existe no plugin -> artefato do projeto
    """
    out: dict = {"defasados": [], "exclusivos": {}, "sem_par": []}

    # Uniao de TODAS as linhas de TODAS as versoes do diretorio no plugin. Escopo de
    # DIRETORIO, nao de arquivo: conteudo que apenas MUDOU DE ARQUIVO entre versoes
    # (o trio de design fundido em squad-design, blocos movidos para squad-core) nao
    # pode contar como customizacao local. E versao antiga entra tambem: linha que o
    # plugin ja teve e depois removeu e conteudo dele, obsoleto no maximo.
    uniao: set[str] = set()
    tem_par: set[str] = set()
    for _v, d in ref_dirs:
        for pf in arquivos(d):
            uniao |= _linhas(pf)
            tem_par.add(str(pf.relative_to(d)))

    for f in arquivos(local_dir):
        rel = str(f.relative_to(local_dir))
        if rel not in tem_par:
            out["sem_par"].append(rel)
            continue
        sobra = _linhas(f) - uniao
        if sobra:
            out["exclusivos"][rel] = sorted(sobra)[:6]
        else:
            out["defasados"].append(rel)
    return out


def delta_changelog(cache: Path, ver_de: str | None, ver_ate: str | None) -> dict:
    """Le o changelog do plugin instalado e devolve as entradas ESTRITAMENTE acima de
    `ver_de` ate `ver_ate`, marcando quais tem item BREAKING.

    E isso que decide se a reconciliacao pode ser automatica: delta sem BREAKING nao
    pede acao no projeto — o registro pode ser gravado direto. Com BREAKING, cada item
    e uma acao potencial e o bump so acontece ao final, depois de tratadas.
    """
    out: dict = {"entradas": [], "breaking": [], "lido_de": None}
    if not (ver_de and ver_ate):
        return out
    readme = cache / ver_ate / "README.md"
    if not readme.is_file():
        return out
    out["lido_de"] = str(readme)
    chave = lambda v: [int(x) for x in v.split(".")]
    atual, corpo = None, []
    for linha in readme.read_text(encoding="utf-8", errors="replace").splitlines():
        m = re.match(r"^###\s+(\d+\.\d+\.\d+)", linha)
        if m:
            if atual and chave(ver_de) < chave(atual) <= chave(ver_ate):
                out["entradas"].append({"versao": atual, "linhas": corpo})
            atual, corpo = m.group(1), []
        elif atual:
            corpo.append(linha)
    if atual and chave(ver_de) < chave(atual) <= chave(ver_ate):
        out["entradas"].append({"versao": atual, "linhas": corpo})

    # MARCADOR `[BREAKING]`, nao a palavra solta: a entrada da 1.11.0 descreve o
    # procedimento de reconciliacao e cita "itens BREAKING" no texto — mencao, nao
    # marcacao. Mesmo erro que a UP-06 pegou no push-gate (substring confundia mencao
    # com execucao), agora em terceira forma.
    marcador = re.compile(r"\[BREAKING\]", re.I)
    for e in out["entradas"]:
        for l in e["linhas"]:
            if marcador.search(l):
                out["breaking"].append({"versao": e["versao"], "item": l.strip()[:220]})
    return out


def gravar_versao(proj: Path, nova: str, entradas: list[dict]) -> str:
    """Grava a versao nova no SQUAD_VERSION preservando o conteudo e anexando uma linha
    de historico por versao incorporada."""
    f = proj / ".claude/squad/project/SQUAD_VERSION"
    t = f.read_text(encoding="utf-8")
    antiga = re.search(r"(\d+\.\d+\.\d+)", t)
    if antiga:
        t = t.replace(antiga.group(1), nova, 1)
    vs = ", ".join(e["versao"] for e in entradas) or nova
    t = t.rstrip("\n") + (
        f"\n# reconciliacao automatica (squad-migrate --reconcile): {vs} incorporada(s) — "
        f"nenhum item BREAKING no delta, nada a decidir no projeto\n")
    f.write_text(t, encoding="utf-8")
    return str(f)


def git(proj: Path, *args: str) -> str:
    try:
        r = subprocess.run(["git", "-C", str(proj), *args],
                           capture_output=True, text=True, check=False)
        return r.stdout.strip()
    except Exception:
        return ""


def diagnosticar(proj: Path, cache: Path) -> dict:
    d: dict = {"projeto": str(proj), "achados": [], "acoes_seguras": [], "decisoes": []}

    versoes = versoes_no_cache(cache)
    instalada = versoes[-1] if versoes else None
    registrada = ler_squad_version(proj)
    d["versao_instalada"] = instalada
    d["versao_registrada"] = registrada

    tem_memoria = (proj / ".claude/squad/project").is_dir()
    dirs_legado = [(l, p) for l, p in DUPLICADOS if (proj / l).is_dir()]

    if not tem_memoria:
        d["estado"] = "nao-adotado"
        d["achados"].append("sem .claude/squad/project/ — rodar /squad-init, nao migrar")
        return d
    d["estado"] = "hibrido-legado" if dirs_legado else "plugin-puro"

    d["versoes_comparadas"] = versoes

    for local, sub in dirs_legado:
        ldir = proj / local
        refs = [(v, cache / v / sub) for v in versoes if (cache / v / sub).is_dir()]
        cls = classificar(ldir, refs)
        n_def, n_exc, n_sp = len(cls["defasados"]), len(cls["exclusivos"]), len(cls["sem_par"])
        d["achados"].append(
            f"{local}: {n_def} copia(s) DEFASADA(S) (o plugin contem tudo), "
            f"{n_exc} com linha exclusiva, {n_sp} sem par no plugin")
        if n_def and not (n_exc or n_sp):
            d["acoes_seguras"].append({"tipo": "remover_dir", "alvo": local,
                                       "porque": f"{n_def} arquivos defasados; o plugin fornece versao igual ou mais nova"})
        elif n_def:
            d["acoes_seguras"].append({"tipo": "remover_arquivos", "alvo": local,
                                       "arquivos": cls["defasados"],
                                       "porque": "defasados — o plugin contem tudo que eles tem"})
        if n_exc:
            d["decisoes"].append({"tema": f"{local}: {n_exc} arquivo(s) com conteudo que existe SO ali",
                                  "arquivos": list(cls["exclusivos"].keys()),
                                  "amostras": cls["exclusivos"],
                                  "acao": "ler as linhas exclusivas: se for patch local que o plugin ja resolve, "
                                          "descartar; se for regra que o plugin nao tem, virar lesson/backport ANTES de remover"})
        if n_sp:
            d["decisoes"].append({"tema": f"{local}: {n_sp} arquivo(s) sem par no plugin",
                                  "arquivos": cls["sem_par"],
                                  "acao": "artefato proprio do projeto — confirmar antes de remover"})

    # settings.json apontando para hooks locais
    s = proj / ".claude/settings.json"
    if s.is_file() and ".claude/hooks/" in s.read_text(encoding="utf-8", errors="replace"):
        d["decisoes"].append({"tema": "settings.json registra hooks LOCAIS",
                              "acao": "o plugin registra os proprios hooks; manter os dois roda em "
                                      "duplicado. Remover o bloco `hooks` do settings.json do projeto"})

    # contratos na memoria (AM-30)
    c = proj / ".claude/squad/project/contracts"
    if c.is_dir() and any(c.iterdir()):
        d["decisoes"].append({"tema": "contratos versionados na memoria da squad (AM-30)",
                              "acao": "fonte unica e o pacote de contratos do repo; se nao existe, "
                                      "mover para o repo ou registrar excecao. NAO remover cegamente — "
                                      "pode ser o unico lugar onde vivem"})

    # gate local: instalado mas fora da cadeia de hooks?
    if (proj / ".githooks").is_dir():
        hp = git(proj, "config", "core.hooksPath")
        if not hp:
            d["acoes_seguras"].append({"tipo": "git_config", "alvo": "core.hooksPath=.githooks",
                                       "porque": ".githooks existe mas nenhum gerenciador o chama — gate ORFAO (AM-34)"})
        elif Path(hp).is_absolute():
            d["achados"].append(f"core.hooksPath e absoluto ({hp}) — em repo com worktree resolve pro "
                                "principal e o gate nao roda nas worktrees (AM-38); relativo `.githooks` e mais seguro")

    if registrada and instalada and registrada != instalada:
        delta = delta_changelog(cache, registrada, instalada)
        d["delta"] = delta
        if delta["entradas"] and not delta["breaking"]:
            d["acoes_seguras"].append({
                "tipo": "gravar_versao", "alvo": f"SQUAD_VERSION -> {instalada}",
                "versao": instalada, "entradas": delta["entradas"],
                "porque": f"delta {registrada}->{instalada} ({len(delta['entradas'])} versao(oes)) "
                          "sem nenhum item BREAKING no changelog — nada a decidir no projeto"})
        elif delta["breaking"]:
            d["decisoes"].append({
                "tema": f"governanca defasada COM breaking: {registrada} -> {instalada}",
                "arquivos": [f"{b['versao']}: {b['item']}" for b in delta["breaking"]],
                "acao": "cada item BREAKING e uma acao potencial no projeto. Tratar primeiro "
                        "(/squad-resume passo 0b) e so ao final gravar a versao nova — bump antes "
                        "apaga o unico sinal de que havia trabalho pendente"})
        else:
            d["decisoes"].append({
                "tema": f"governanca defasada: projeto {registrada} vs instalada {instalada}",
                "acao": "changelog do delta nao encontrado no plugin instalado — reconciliar "
                        "manualmente (/squad-resume passo 0b)"})
    return d


def aplicar(proj: Path, plano: dict) -> list[str]:
    feitas = []
    for a in plano["acoes_seguras"]:
        t = a["tipo"]
        if t == "remover_dir":
            shutil.rmtree(proj / a["alvo"], ignore_errors=True)
            feitas.append(f"removido {a['alvo']}/")
        elif t == "remover_arquivos":
            base = proj / a["alvo"]
            for rel in a["arquivos"]:
                (base / rel).unlink(missing_ok=True)
            for dirp in sorted((p for p in base.rglob("*") if p.is_dir()), reverse=True):
                if not any(dirp.iterdir()):
                    dirp.rmdir()
            feitas.append(f"removidos {len(a['arquivos'])} arquivo(s) de {a['alvo']}/")
        elif t == "git_config":
            k, v = a["alvo"].split("=", 1)
            subprocess.run(["git", "-C", str(proj), "config", k, v], check=False)
            feitas.append(f"git config {k}={v}")
        elif t == "gravar_versao":
            f = gravar_versao(proj, a["versao"], a["entradas"])
            feitas.append(f"SQUAD_VERSION -> {a['versao']} ({f})")
    return feitas


def imprimir(plano: dict, aplicado: list[str] | None) -> None:
    print(f"=== squad-migrate — {plano['projeto']} ===")
    comp = ",".join(plano.get("versoes_comparadas") or []) or "nenhuma"
    print(f"estado: {plano['estado']} | registrada: {plano.get('versao_registrada')} "
          f"| instalada: {plano.get('versao_instalada')}")
    print(f"comparado contra: {comp}")
    if plano["achados"]:
        print("\nAchados:")
        for a in plano["achados"]:
            print(f"  - {a}")
    if plano["acoes_seguras"]:
        print("\nAcoes SEGURAS (deterministicas):")
        for a in plano["acoes_seguras"]:
            extra = f" ({len(a['arquivos'])} arquivos)" if a.get("arquivos") else ""
            print(f"  - [{a['tipo']}] {a['alvo']}{extra}\n      porque: {a['porque']}")
    if plano["decisoes"]:
        print("\nDECISOES do usuario (nao automatizaveis):")
        for dd in plano["decisoes"]:
            print(f"  - {dd['tema']}")
            print(f"      -> {dd['acao']}")
            amostras = dd.get("amostras") or {}
            for f in (dd.get("arquivos") or [])[:8]:
                print(f"         · {f}")
                for linha in (amostras.get(f) or [])[:3]:
                    print(f"             so-no-local: {linha[:88]}")
            if len(dd.get("arquivos") or []) > 8:
                print(f"         · ... +{len(dd['arquivos']) - 8}")
    if aplicado is None:
        print("\nDRY-RUN — nada foi tocado. Rode com --apply para executar as acoes seguras.")
    else:
        print("\nAplicado:")
        for f in aplicado:
            print(f"  [OK] {f}")
        print("\nRevise com `git status`/`git diff` e commite. As DECISOES seguem abertas.")


def main() -> int:
    ap = argparse.ArgumentParser(description="Diagnostica/migra um projeto para o plugin dev-squad puro")
    ap.add_argument("--project", default=".", help="raiz do projeto (default: cwd)")
    ap.add_argument("--plugin-cache", default=str(CACHE_DEFAULT), help="cache do plugin")
    ap.add_argument("--apply", action="store_true", help="executa as acoes seguras")
    ap.add_argument("--json", action="store_true", help="saida JSON")
    args = ap.parse_args()

    proj = Path(args.project).resolve()
    if not proj.is_dir():
        print(f"projeto nao encontrado: {proj}", file=sys.stderr)
        return 2

    plano = diagnosticar(proj, Path(args.plugin_cache))
    aplicado = aplicar(proj, plano) if args.apply else None
    if args.json:
        print(json.dumps({**plano, "aplicado": aplicado}, ensure_ascii=False, indent=2))
    else:
        imprimir(plano, aplicado)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
