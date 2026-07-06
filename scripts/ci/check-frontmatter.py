#!/usr/bin/env python3
"""Valida o YAML frontmatter de todas as skills do plugin.

Pega a classe de bug da Fase B (frontmatter que não parseia -> skill carrega
com metadata vazia silenciosamente). Falha se: frontmatter ausente, YAML
inválido, `name`/`description` ausentes, ou `name` != nome do diretório.
"""
import sys
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERRO: pyyaml não instalado (pip install pyyaml)")
    sys.exit(2)

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "plugin" / "skills"

errors = []
skills = sorted(SKILLS.glob("*/SKILL.md"))
if not skills:
    errors.append(f"nenhuma skill encontrada em {SKILLS}")

for f in skills:
    rel = f.relative_to(ROOT)
    text = f.read_text(encoding="utf-8")
    m = re.match(r"\A---\n(.*?)\n---\n", text, re.S)
    if not m:
        errors.append(f"{rel}: frontmatter ausente ou sem delimitadores ---")
        continue
    try:
        data = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        errors.append(f"{rel}: YAML inválido — {str(e).splitlines()[0]}")
        continue
    if not isinstance(data, dict):
        errors.append(f"{rel}: frontmatter não é um mapa YAML")
        continue
    for field in ("name", "description"):
        if not data.get(field) or not isinstance(data[field], str):
            errors.append(f"{rel}: campo obrigatório '{field}' ausente/vazio")
    if data.get("name") and data["name"] != f.parent.name:
        errors.append(f"{rel}: name '{data['name']}' != diretório '{f.parent.name}'")

if errors:
    print(f"FALHOU — {len(errors)} erro(s):")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print(f"OK — {len(skills)} skills com frontmatter válido")
