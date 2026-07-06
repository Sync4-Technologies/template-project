#!/usr/bin/env python3
"""Valida que referências ${CLAUDE_PLUGIN_ROOT}/... nos docs do plugin
apontam para arquivos/diretórios que existem em plugin/.

Refs com placeholders ({...}, *, N, xxx) são ignoradas (são templates).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PLUGIN = ROOT / "plugin"

REF = re.compile(r"\$\{CLAUDE_PLUGIN_ROOT\}/([A-Za-z0-9_\-./]+)")
PLACEHOLDER = re.compile(r"\{|\*|/xxx|/NNN|\.\.\.")

errors = []
checked = 0
for f in sorted(PLUGIN.rglob("*")):
    if f.suffix not in (".md", ".sh", ".json", ".example", ".template") or not f.is_file():
        continue
    rel = f.relative_to(ROOT)
    for m in REF.finditer(f.read_text(encoding="utf-8", errors="replace")):
        path = m.group(1).rstrip(".")  # remove pontuação de fim de frase
        if PLACEHOLDER.search(path):
            continue
        checked += 1
        target = PLUGIN / path
        if path.endswith("/"):
            if not target.is_dir():
                errors.append(f"{rel}: diretório inexistente -> {path}")
        elif not target.exists():
            errors.append(f"{rel}: alvo inexistente -> {path}")

if errors:
    # dedup mantendo ordem
    seen, uniq = set(), []
    for e in errors:
        if e not in seen:
            seen.add(e)
            uniq.append(e)
    print(f"FALHOU — {len(uniq)} referência(s) quebrada(s):")
    for e in uniq:
        print(f"  - {e}")
    sys.exit(1)

print(f"OK — {checked} referências verificadas")
