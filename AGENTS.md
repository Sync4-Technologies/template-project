# AGENTS.md

> Índice tool-agnostic da squad de agentes deste projeto.
> Para regras detalhadas, ver `CLAUDE.md` (governança) e `/.claude/squad/template/agents/` (definições por agente).

---

## O que é este projeto

Squad de engenharia de software baseada em agentes especializados. O objetivo é padronizar a forma como sistemas são concebidos, projetados, implementados, validados e operados, garantindo qualidade, segurança e governança consistentes.

---

## Agentes

| Agente | Arquivo | Modelo | Papel |
|--------|---------|--------|-------|
| Product Owner | [`.claude/squad/template/agents/product-owner.md`](.claude/squad/template/agents/product-owner.md) | Opus | Define o quê construir, regras de negócio, critérios de aceite |
| Tech Lead | [`.claude/squad/template/agents/tech-lead.md`](.claude/squad/template/agents/tech-lead.md) | Opus | Orquestração, governança técnica, plano de execução |
| Architect | [`.claude/squad/template/agents/architect.md`](.claude/squad/template/agents/architect.md) | Opus | Arquitetura, domínio (DDD), contratos, decisão de stack |
| Security Engineer | [`.claude/squad/template/agents/security-engineer.md`](.claude/squad/template/agents/security-engineer.md) | Opus | Threat modeling, compliance, auth/authz, pentest review |
| Product Designer | [`.claude/squad/template/agents/product-designer.md`](.claude/squad/template/agents/product-designer.md) | Opus | Design System, UX, UI, acessibilidade visual (consultor com canal direto ao usuário) |
| Backend Engineer | [`.claude/squad/template/agents/backend-engineer.md`](.claude/squad/template/agents/backend-engineer.md) | Sonnet | APIs, lógica de negócio, persistência |
| Frontend Engineer | [`.claude/squad/template/agents/frontend-engineer.md`](.claude/squad/template/agents/frontend-engineer.md) | Sonnet | Interface web, Atomic Design, integração com backend |
| Mobile Engineer | [`.claude/squad/template/agents/mobile-engineer.md`](.claude/squad/template/agents/mobile-engineer.md) | Sonnet | Apps iOS/Android, Clean Architecture mobile |
| AI Engineer | [`.claude/squad/template/agents/ai-engineer.md`](.claude/squad/template/agents/ai-engineer.md) | Sonnet | Agentes de IA, prompts, MCP, tools |
| QA Engineer | [`.claude/squad/template/agents/qa-engineer.md`](.claude/squad/template/agents/qa-engineer.md) | Sonnet | Testes (TDD), validação de comportamento |
| Code Reviewer | [`.claude/squad/template/agents/code-reviewer.md`](.claude/squad/template/agents/code-reviewer.md) | Sonnet | Qualidade do código, OWASP no código |
| DevOps Engineer | [`.claude/squad/template/agents/devops-engineer.md`](.claude/squad/template/agents/devops-engineer.md) | Sonnet | CI/CD, infra, observabilidade, SRE |
| Support Engineer | [`.claude/squad/template/agents/support-engineer.md`](.claude/squad/template/agents/support-engineer.md) | Sonnet | Triagem de issues (bug vs melhoria) |
| Data Engineer | [`.claude/squad/template/agents/data-engineer.md`](.claude/squad/template/agents/data-engineer.md) | Sonnet | Pipelines, modelagem analítica (consultor) |

---

## Fontes de verdade

- **`CLAUDE.md`** → regras gerais, fluxos, gates obrigatórios, modos MVP/Production, fronteiras de segurança
- **`.claude/squad/template/agents/{name}.md`** → identidade, regras e comportamento de cada agente
- **`.claude/squad/template/`** → template imutável (agents, docs, memory/ADR defaults, contracts) — sobrescrito em update
- **`.claude/squad/project/`** → estado vivo do projeto (ARCHITECTURE.md, DECISIONS_LOG.md, TASK_BOARD.md, ADR/, agent-memory/, contracts/, design-system/, docs/, runbooks/) — preservado em update
- **`.claude/squad/template/docs/stack-conventions/`** → convenções idiomáticas por linguagem/framework (Architect decide; Engineers consultam)
- **`.claude/skills/`** → skills Claude Code que automatizam workflows da squad (`/squad-new-project`, `/squad-prd-template`, etc.). Ver `.claude/squad/template/memory/ADR/ADR-004-skills-e-hooks.md`
- **`.claude/hooks/`** + **`.claude/settings.json`** → hooks opt-in (carregamento de memória no SessionStart, lembretes em mudanças estruturais)

---

## Hierarquia

```
Usuário (autoridade máxima)
├── Product Owner — define o QUÊ (par do Tech Lead)
└── Tech Lead — define o COMO e orquestra
    └── todos os outros agentes
```

- **PO, TL e Product Designer** podem interagir diretamente com o usuário
  - PO: o quê construir, regras de negócio
  - TL: orquestração técnica, status
  - Product Designer: questões visuais e UX (quando alocado ou acionado pelo usuário)
- Demais agentes respondem ao TL (orquestrador único)
- Support Engineer escala issues via TL; TL roteia: bug fica com TL, melhoria é encaminhada ao PO
- Frontend/Mobile podem tirar **dúvidas pontuais** com Product Designer (canal aberto); **decisões** visuais são orquestradas via TL
- Divergências entre PO/TL/PD são resolvidas pelo usuário

---

## Fonte autoritativa

Este arquivo é **índice**. Para qualquer conflito, vale CLAUDE.md.

| Tópico | Fonte autoritativa |
|--------|-------------------|
| Modelos por agente | `CLAUDE.md` → "Modelos por Agente" |
| Regras detalhadas de cada agente | `.claude/squad/template/agents/{name}.md` |
| Fluxos, gates, governança | `CLAUDE.md` |
| Hierarquia e canais de comunicação | `CLAUDE.md` → "Hierarquia" e "Regra de Interação" |

### Regra de manutenção

Mudança que afeta este índice:
- adicionar/remover/renomear agente → atualizar `AGENTS.md` + `CLAUDE.md` ("Estrutura de Pastas" e "Modelos por Agente")
- mudança de modelo de agente → atualizar `CLAUDE.md` ("Modelos por Agente") **primeiro**, depois espelhar aqui

Mudanças em fluxos, gates ou regras → atualizar **só** `CLAUDE.md`.
