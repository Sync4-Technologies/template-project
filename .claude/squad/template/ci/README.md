# CI Enforcement (Opcional)

> Templates de CI/git hooks para projetos que querem **enforcement automatizado** de disciplina de memória da squad.
> Estes templates são **opt-in** — projeto decide adotar copiando para localização ativa.

---

## O que está aqui

| Template | Quando usar |
|----------|-------------|
| `memory-check.yml.example` | GitHub Actions workflow validando PRs |
| `pre-commit.example` | Hook git local de pre-commit |

---

## Instalação (opcional por projeto)

### Workflow GitHub Actions

```bash
# Copiar para localização ativa
mkdir -p .github/workflows
cp .claude/squad/template/ci/memory-check.yml.example .github/workflows/memory-check.yml

# Customizar regras conforme necessário
# Commit + push — workflow ativa em PRs
```

### Pre-commit hook local

```bash
# Copiar para localização ativa
mkdir -p .githooks
cp .claude/squad/template/ci/pre-commit.example .githooks/pre-commit
chmod +x .githooks/pre-commit

# Configurar git para usar .githooks/
git config core.hooksPath .githooks
```

---

## O que cada template valida

### `memory-check.yml.example` (GitHub Actions)

Em cada PR:

1. **Detecta** mudanças em código de produção (`src/`, `lib/`, etc.)
2. **Verifica** se há atualização correspondente em:
   - `.claude/squad/project/DECISIONS_LOG.md`
   - `.claude/squad/project/ARCHITECTURE.md`
   - `.claude/squad/project/ADR/` (novo ADR)
   - `.claude/squad/project/agent-memory/` (atualização de skeleton)
3. **Gera comment** no PR se não há atualização — **warning, não fail** por default
4. **Em Production Mode:** pode escalar para fail (configurável)

### `pre-commit.example` (Git hook local)

Mesma lógica do GitHub Actions, mas roda **localmente antes do commit**:

- Detecta arquivos staged em código de produção
- Verifica se há atualização em memory no mesmo commit
- Sugere atualização (sem bloquear por default)

---

## Filosofia

Estes templates **complementam**, não substituem, a disciplina manual da squad. São redes de segurança:

- **Não bloqueiam** trabalho (por default — projeto pode endurecer)
- **Sugerem** quando há gap
- **Aceleram** detecção de inconsistência multi-usuário

Combinados com:
- Skill `/squad-handoff` (encerramento)
- Skill `/squad-resume` (retomada)
- Hook `memory-update-reminder.sh` (PreToolUse, opt-in)

...formam camada robusta de continuidade.

---

## Customização por projeto

Templates são **starting points**. Projeto pode:

- Endurecer (fail em PR ao invés de warning)
- Relaxar (apenas log, sem comment)
- Adicionar regras específicas (ex: exigir ADR para mudanças em `domain/`)
- Integrar com outros CIs (CircleCI, GitLab CI, etc.)

Manter customizações documentadas em ADR específico do projeto.

---

## Referências

- ADR-004 (Skills e Hooks): `.claude/squad/template/memory/ADR/ADR-004-skills-e-hooks.md`
- Skill `/squad-handoff`: `.claude/skills/squad-handoff/SKILL.md`
- Skill `/squad-resume`: `.claude/skills/squad-resume/SKILL.md`
- Hook `memory-update-reminder.sh`: `.claude/hooks/memory-update-reminder.sh`
- CLAUDE.md → "Multi-user Continuity"
