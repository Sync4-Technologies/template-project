# ADR-004 — Skills e Hooks da Squad

**Status:** Aceita
**Data:** 2026-05-09
**Autor:** Tech Lead

---

## Contexto

A squad executa workflows repetitivos (Fluxo 1, criação de PRD, review de flags, threat model, scope-change, decisão de stack, incidente). Sem automação:

- Workflows longos exigem que usuário se lembre dos passos
- Skill execution varia entre desenvolvedores
- Memória do sistema (TASK_BOARD, ARCHITECTURE, DECISIONS_LOG) raramente é carregada no contexto inicial — agentes operam com info parcial
- Sob pressão (incidente Sev1), checklist mental falha

Claude Code suporta dois mecanismos de automação:

- **Skills** — capacidades reutilizáveis invocadas via `/skill-name`, com prompt estruturado e contexto pré-carregado
- **Hooks** — automação que dispara em eventos (SessionStart, PreToolUse, PostToolUse, UserPromptSubmit, etc.)

---

## Decisão

Adotar **skills e hooks de forma seletiva** para automatizar workflows repetitivos da squad, com governança rígida que evita explosão de skills não-usadas.

### Skills (13)

#### Skills de fluxo geral
| Skill | Trigger | Owner |
|-------|---------|-------|
| `/squad-new-project` | Início de Fluxo 1 (projeto novo) | TL |
| `/squad-prd-template` | PO cria PRD | PO |
| `/squad-threat-model` | SE Fase 1 (arquitetura) | SE |
| `/squad-flag-audit` | Review mensal de feature flags | TL |
| `/squad-scope-change` | Mudança de escopo durante execução | TL |
| `/squad-stack-decision` | Architect decide stack do projeto | Architect |
| `/squad-incident` | Sev1/Sev2 em produção | TL |

#### Skills de Design System
| Skill | Trigger | Owner |
|-------|---------|-------|
| `/squad-design` | Ciclo de vida do DS — modos new (projeto novo), extract (legado sem doc) e audit (drift periódico) | PD |

#### Skills de continuidade multi-usuário
| Skill | Trigger | Owner |
|-------|---------|-------|
| `/squad-handoff` | Final de sessão preparando handoff | TL |
| `/squad-resume` | Início de sessão retomando trabalho | TL |
| `/squad-status` | Snapshot rápido do projeto | TL |

### Hooks (3)

| Hook | Evento | Ação | Opt-in? |
|------|--------|------|---------|
| `load-memory` | SessionStart | Carrega `.claude/squad/project/` (TASK_BOARD ativo, decisões recentes, ADRs) no contexto da sessão | Ativo por default |
| `architecture-reminder` | PostToolUse em Edit/Write em `.claude/squad/project/ARCHITECTURE.md` | Lembra de atualizar `.claude/squad/project/DECISIONS_LOG.md` | Ativo por default |
| `memory-update-reminder` | PreToolUse em Bash `git commit` | Sugere atualizar memory quando commit toca código sem memory correspondente | Opt-in via settings.json |

### CI Enforcement (opt-in)

Templates em `${CLAUDE_PLUGIN_ROOT}/template/ci/`:

| Template | Tipo | Quando usar |
|----------|------|-------------|
| `memory-check.yml.example` | GitHub Actions | Validação automática em PRs |
| `pre-commit.example` | Git hook local | Aviso antes de commit local |
| `README.md` | Documentação | Como instalar e customizar |

### Localização

- Skills: `${CLAUDE_PLUGIN_ROOT}/skills/{skill-name}/SKILL.md`
- Hooks: `.claude/settings.json` (config) + `${CLAUDE_PLUGIN_ROOT}/hooks/*.sh` (scripts)
- CI templates: `${CLAUDE_PLUGIN_ROOT}/template/ci/`

---

## Governança

### Critério para criar nova skill

Skill é justificada apenas quando o workflow:

- Repete **≥ 3 vezes** em projetos diferentes OU **≥ 5 vezes** num único projeto
- Tem passos suficientes para errar (≥ 4 passos com risco de pular gate)
- Não muda toda semana (workflows instáveis viram skills obsoletas)

### Metadata obrigatória de cada skill

Toda skill deve declarar:

- **Dono** (TL, PO, Architect, etc.) — responsável por manutenção
- **Contexto** (qual workflow automatiza)
- **Prazo de revisão** (default 90 dias) — quando reavaliar utilidade
- **Critério de obsolescência** — quando deve ser removida (ex: workflow descontinuado, repetição cessou)

### Processo de criação (semi-autônomo)

Skills **não são criadas autonomamente** por agentes:

1. TL (ou outro agente) detecta padrão repetido durante orquestração
2. TL propõe skill ao usuário com motivação:
   - Nome
   - Workflow automatizado
   - Frequência observada (quantas vezes repetiu)
   - Esboço da skill
3. Usuário aprova / ajusta / rejeita
4. Skill criada por TL ou Engineer designado, com metadata obrigatória
5. Registrada em `.claude/squad/project/DECISIONS_LOG.md` com tag `skill-created`
6. **Trimestralmente:** TL revisa skills ativas; sem uso em 90 dias → remover

### Critério para hook

Hooks devem:

- Ser **opt-in** (cada projeto ativa explicitamente em `.claude/settings.json`)
- Ser **não-intrusivos** (não bloquear ação do usuário sem causa clara)
- Ser **rápidos** (≤ 1s) — não fazer chamadas de rede
- Ter **fallback** silencioso em caso de falha (hook quebrado não trava o usuário)

---

## Alternativas Consideradas

### A1. Sem automação (status quo)
- **Prós:** simplicidade máxima
- **Contras:** workflows variam por execução; gates pulados sob pressão
- **Status:** rejeitado — squad operacional precisa de checklist consistente

### A2. Automação total (skills para todo workflow)
- **Prós:** padronização extrema
- **Contras:** explosão de skills (30+ em 6 meses); manutenção alta; rigidez excessiva
- **Status:** rejeitado — viola YAGNI

### A3. Skills criadas autonomamente por agentes
- **Prós:** evolução automática da squad
- **Contras:** quality decay; pollution; viola "tudo via TL"; explosão sem curadoria
- **Status:** rejeitado em favor de **semi-autônomo** (proposta acima)

### A4. Plugin Claude Code completo
- **Prós:** instalação `/plugin install squad`; versionamento; marketplace
- **Contras:** lock-in Claude Code (perde aspecto tool-agnostic); template approach foi mantido (ver decisão anterior)
- **Status:** adiado — reconsiderar quando squad estabilizar e houver 4+ projetos

---

## Trade-offs Assumidos

- 7 skills iniciais + 2 hooks = baixo custo de manutenção
- Governança rígida (90 dias para revisão) previne explosão
- Hooks opt-in evita imposição em projetos que não querem automação
- Tradeoff: workflows ainda podem evoluir; skill desatualizada vira ruído (mitigado por revisão trimestral)

---

## Consequências

### Positivas
- Workflows críticos (Fluxo 1, scope-change, incidente) ganham checklist consistente
- Memória do sistema carregada automaticamente no início da sessão
- Sob pressão (Sev1), skill conduz passo-a-passo
- Onboarding novo: skills são auto-explicativas (nome + descrição)
- Aderência a gates aumenta (skill exige passos)

### Negativas / Riscos
- Skills podem ficar desatualizadas se squad evoluir e skill não acompanhar
- Risco de "skill cult" — usar skill mesmo quando não cabe (mitigado por critério de uso)
- Hooks que falham silenciosamente podem mascarar problemas (mitigado por log)

### Neutras
- Skills/hooks são específicos do Claude Code; outras ferramentas (Cursor, Aider) ignoram
- Cada projeto pode customizar `${CLAUDE_PLUGIN_ROOT}/skills/` localmente (override permitido)

---

## Critérios de Revisão

Esta decisão deve ser revisada se:

- Skills criadas não atingirem ≥ 3 usos em 90 dias (sinal de over-engineering)
- Hooks causarem fricção repetida (sinal de intrusão excessiva)
- Padrão de uso da squad mudar significativamente (workflows novos não cobertos)
- Decisão de migrar para plugin Claude Code (substitui parte das skills)
