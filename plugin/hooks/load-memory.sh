#!/usr/bin/env bash
# Hook: SessionStart
# Carrega memória viva da squad no contexto inicial da sessão.
# Falha silenciosa se arquivos não existirem (template novo sem estado ainda).

set -u

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_DIR="${PROJECT_ROOT}/.claude/squad/project"
# ADRs default do template vêm do plugin; fallback pro layout legado (template clonado no projeto)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -n "${PLUGIN_ROOT}" && -d "${PLUGIN_ROOT}/template/memory/ADR" ]]; then
  TEMPLATE_ADR_DIR="${PLUGIN_ROOT}/template/memory/ADR"
else
  TEMPLATE_ADR_DIR="${PROJECT_ROOT}/.claude/squad/template/memory/ADR"
fi

# Se project/ não existe (projeto ainda não inicializado — rodar /squad-init), retornar contexto vazio
if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "{}"
  exit 0
fi

# Gerar contexto via Python para garantir JSON válido
python3 <<EOF
import json
import os
from pathlib import Path

project_dir = Path("${PROJECT_DIR}")
template_adr_dir = Path("${TEMPLATE_ADR_DIR}")
plugin_root = "${PLUGIN_ROOT}"

parts = ["=== SQUAD ATIVA (plugin squad) ==="]

# Persona: projeto com squad inicializada -> Claude atua como Tech Lead
persona = [
    "VOCE ATUA COMO TECH LEAD desta squad (salvo instrucao contraria no CLAUDE.md do projeto):",
    "- Orquestra os agentes especializados; nao implementa direto — delega e valida quality gates",
    "- Spec completa do papel: " + (plugin_root + "/template/agents/tech-lead.md" if plugin_root else ".claude/squad/template/agents/tech-lead.md"),
    "- Specs main-thread (PO, PD, Architect, SE) no mesmo diretorio; executores/reviewers/advisor sao subagents nativos do plugin (Task tool); skills /squad-* disponiveis",
    "- Retomada de sessao: rodar /squad-resume ANTES de qualquer trabalho",
    "",
    "=== SQUAD MEMORY LOADED (SessionStart) ===",
]
parts.extend(persona)

# ARCHITECTURE.md (head)
arch = project_dir / "ARCHITECTURE.md"
if arch.exists():
    content = arch.read_text(errors="replace").splitlines()[:50]
    parts.append("\n--- project/ARCHITECTURE.md (head) ---")
    parts.extend(content)

# TASK_BOARD.md (Doing/Review/Blocked)
tb = project_dir / "TASK_BOARD.md"
if tb.exists():
    lines = tb.read_text(errors="replace").splitlines()
    flag = False
    section_lines = []
    for line in lines:
        if line.startswith("## ") and any(s in line for s in ("Doing", "Review", "Blocked")):
            flag = True
            section_lines.append(line)
        elif line.startswith("## "):
            flag = False
        elif flag:
            section_lines.append(line)
    if section_lines:
        parts.append("\n--- project/TASK_BOARD.md (Doing/Review/Blocked) ---")
        parts.extend(section_lines[:50])

# DECISIONS_LOG.md (last 10 table rows)
dl = project_dir / "DECISIONS_LOG.md"
if dl.exists():
    lines = [l for l in dl.read_text(errors="replace").splitlines() if l.startswith("|")]
    if lines:
        parts.append("\n--- project/DECISIONS_LOG.md (recent) ---")
        parts.extend(lines[-10:])

# Project-specific ADRs
project_adr = project_dir / "ADR"
if project_adr.exists():
    adrs = sorted(p.name for p in project_adr.glob("*.md"))
    if adrs:
        parts.append("\n--- project/ADR/ (project-specific) ---")
        parts.extend(adrs)

# Template ADRs (squad defaults)
if template_adr_dir.exists():
    adrs = sorted(p.name for p in template_adr_dir.glob("*.md") if "template" not in p.name)
    if adrs:
        parts.append("\n--- template/ADR/ (squad defaults) ---")
        parts.extend(adrs)

context = "\n".join(parts)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": context
    }
}))
EOF
