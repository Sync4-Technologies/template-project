# Plugin `squad` — AI Software Squad

Governança completa para projetos conduzidos por squad de agentes Claude Code: 14 specs de agentes, 15 skills, hooks de memória viva e templates de qualidade.

## Instalação

```bash
# 1. Adicionar o marketplace (uma vez por máquina; lê a branch default do repo)
/plugin marketplace add Sync4-Technologies/template-project

# 2. Instalar o plugin (escopo user — vale pra todos os projetos da máquina)
/plugin install squad@pdati

# 3. Verificar
claude plugin list              # squad@pdati — enabled
claude plugin details squad     # 15 skills, 3 hooks, ~870 tok always-on

# 4. Reiniciar a sessão Claude Code (plugin carrega na próxima sessão)

# 5. No projeto (uma vez):
/squad-init                     # cria .claude/squad/project/ + SQUAD_VERSION
```

Passo a passo completo com troubleshooting: README do repositório → "Distribuição e Versionamento (Plugin)".

## Uso

| Situação | Comando |
|----------|---------|
| Adotar a squad num projeto (novo ou existente) | `/squad-init` — cria `.claude/squad/project/` (memória) + `SQUAD_VERSION` |
| Projeto novo do zero | `/squad-new-project` |
| Retomar trabalho | `/squad-resume` (obrigatório como 1º passo de retomada) |
| Encerrar sessão | `/squad-handoff` |
| Antes de deploy em PaaS | `/squad-deploy-preflight` |

Skills completas: ver `skills/`. Specs dos agentes: `template/agents/`. Checklist de qualidade dos engineers: `template/docs/engineer-self-review.md`.

## Arquitetura: plugin × projeto

| Vive no plugin (estático, versionado aqui) | Vive no projeto (estado) |
|---|---|
| Specs dos 14 agentes, 15 skills, 3 hooks, docs (self-review, stack-conventions, design-system), templates (PRD, ADR, LESSONS_LEARNED), CI examples | `.claude/squad/project/` — ARCHITECTURE, TASK_BOARD, DECISIONS_LOG, ADRs do projeto, agent-memory, LESSONS_LEARNED, contracts, `SQUAD_VERSION` |

**Regra de governança:** não editar arquivos do plugin dentro de um projeto. Gap no sistema da squad → registrar no `LESSONS_LEARNED.md` do projeto (skill `/squad-handoff`, step 2c) → backportar aqui (upstream) → nova versão → projetos atualizam explicitamente. Isso fecha o ciclo de drift que motivou o plugin.

## Versionamento

- SemVer. Toda mudança de comportamento de agente/skill/hook = bump de versão + entrada no changelog do repo.
- Cada projeto grava a versão em uso em `.claude/squad/project/SQUAD_VERSION` — auditável qual governança valia em cada fase.
- Update é ação explícita do usuário (`/plugin` → update), nunca silencioso.

## Migração de projetos com template clonado (layout legado)

Rodar `/squad-init` no projeto — a skill detecta o layout legado, preserva `.claude/squad/project/`, remove as cópias locais de template/skills/hooks (com confirmação) e grava `SQUAD_VERSION`.

## Changelog

### 1.1.0 (2026-07-05)
- **IA no centro**: seção "Produto de IA" no PRD (custo/interação como RNF, evals, guardrails); `stack-conventions/ai/` (anthropic, rag, evals); gate "sem eval → feature de IA incompleta"; checklist OWASP LLM Top 10 no Security; ADR-006-arquitetura-ia; observabilidade de IA no DevOps
- **Frontend**: mini-spec do PD obrigatória pra toda tela; checklist visual (self-review §5); gate "rodou e olhou" (screenshots dos 4 estados); ADR-005 v2 (default web = shadcn/ui + Tailwind); biblioteca de page-patterns
- **Semiautonomia**: Matriz de Autonomia (autônoma/lote/gate) + checkpoint de aprovações em lote no TL; métricas de saúde da squad no handoff e no /squad-status

### 1.0.1 (2026-07-05)
- Hook SessionStart injeta persona Tech Lead em projeto com squad inicializada

### 1.0.0 (2026-07-05)
- Release inicial: 15 skills, 14 agentes, 3 hooks, template completo (pós-diagnóstico LESSONS_LEARNED P0+P1+P2)

## Origem

Extraído do repositório `template-project` após diagnóstico de lições aprendidas em projeto real (ver `docs/DIAGNOSTICO_LESSONS_SQUAD.md` no repo). v1.0.0 = estado pós-aplicação P0+P1+P2 do diagnóstico.
