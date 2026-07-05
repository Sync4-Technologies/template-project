# AGENTS.md

> Índice tool-agnostic da squad de agentes deste projeto.
> Para regras detalhadas, ver `CLAUDE.md` (governança) e `plugin/template/agents/` (definições por agente).

---

## O que é este projeto

Squad de engenharia de software baseada em agentes especializados. O objetivo é padronizar a forma como sistemas são concebidos, projetados, implementados, validados e operados, garantindo qualidade, segurança e governança consistentes.

---

## Agentes

| Agente | Arquivo | Modelo | Papel |
|--------|---------|--------|-------|
| Product Owner | [`plugin/template/agents/product-owner.md`](plugin/template/agents/product-owner.md) | Opus | Define o quê construir, regras de negócio, critérios de aceite |
| Tech Lead | [`plugin/template/agents/tech-lead.md`](plugin/template/agents/tech-lead.md) | Opus | Orquestração, governança técnica, plano de execução |
| Architect | [`plugin/template/agents/architect.md`](plugin/template/agents/architect.md) | Opus | Arquitetura, domínio (DDD), contratos, decisão de stack |
| Security Engineer | [`plugin/template/agents/security-engineer.md`](plugin/template/agents/security-engineer.md) | Opus | Threat modeling, compliance, auth/authz, pentest review |
| Product Designer | [`plugin/template/agents/product-designer.md`](plugin/template/agents/product-designer.md) | Opus | Design System, UX, UI, acessibilidade visual (consultor com canal direto ao usuário) |
| Backend Engineer | [`plugin/template/agents/backend-engineer.md`](plugin/template/agents/backend-engineer.md) | Sonnet | APIs, lógica de negócio, persistência |
| Frontend Engineer | [`plugin/template/agents/frontend-engineer.md`](plugin/template/agents/frontend-engineer.md) | Sonnet | Interface web, Atomic Design, integração com backend |
| Mobile Engineer | [`plugin/template/agents/mobile-engineer.md`](plugin/template/agents/mobile-engineer.md) | Sonnet | Apps iOS/Android, Clean Architecture mobile |
| AI Engineer | [`plugin/template/agents/ai-engineer.md`](plugin/template/agents/ai-engineer.md) | Sonnet | Agentes de IA, prompts, MCP, tools |
| QA Engineer | [`plugin/template/agents/qa-engineer.md`](plugin/template/agents/qa-engineer.md) | Sonnet | Testes (TDD), validação de comportamento |
| Code Reviewer | [`plugin/template/agents/code-reviewer.md`](plugin/template/agents/code-reviewer.md) | Sonnet | Qualidade do código, OWASP no código |
| DevOps Engineer | [`plugin/template/agents/devops-engineer.md`](plugin/template/agents/devops-engineer.md) | Sonnet | CI/CD, infra, observabilidade, SRE |
| Support Engineer | [`plugin/template/agents/support-engineer.md`](plugin/template/agents/support-engineer.md) | Sonnet | Triagem de issues (bug vs melhoria) |
| Data Engineer | [`plugin/template/agents/data-engineer.md`](plugin/template/agents/data-engineer.md) | Sonnet | Pipelines, modelagem analítica (consultor) |

---

## Fontes de verdade

- **`CLAUDE.md`** → regras gerais, fluxos, gates obrigatórios, modos MVP/Production, fronteiras de segurança
- **`plugin/template/agents/{name}.md`** → identidade, regras e comportamento de cada agente
- **`plugin/template/`** → template imutável (agents, docs, memory/ADR defaults, contracts) — sobrescrito em update
- **`.claude/squad/project/`** → estado vivo do projeto (ARCHITECTURE.md, DECISIONS_LOG.md, TASK_BOARD.md, ADR/, agent-memory/, contracts/, design-system/, docs/, runbooks/) — preservado em update
- **`plugin/template/docs/stack-conventions/`** → convenções idiomáticas por linguagem/framework (Architect decide; Engineers consultam)
- **`plugin/skills/`** → skills Claude Code que automatizam workflows da squad (`/squad-new-project`, `/squad-prd-template`, etc.). Ver `plugin/template/memory/ADR/ADR-004-skills-e-hooks.md`
- **`plugin/hooks/`** + **`.claude/settings.json`** → hooks opt-in (carregamento de memória no SessionStart, lembretes em mudanças estruturais)

---

## Hierarquia

```
Usuário (autoridade máxima)
├── Product Owner — define o QUÊ (par do Tech Lead e Product Designer)
├── Tech Lead — define o COMO e orquestra
├── Product Designer — define visual/UX (consultor; peer quando alocado)
│
└── Tech Lead orquestra os demais:
    └── Architect, Engineers, QA, Code Reviewer, Security, DevOps, Support, Data
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
| Regras detalhadas de cada agente | `plugin/template/agents/{name}.md` |
| Fluxos, gates, governança | `CLAUDE.md` |
| Hierarquia e canais de comunicação | `CLAUDE.md` → "Hierarquia" e "Regra de Interação" |

### Regra de manutenção

Mudança que afeta este índice:
- adicionar/remover/renomear agente → atualizar `AGENTS.md` + `CLAUDE.md` ("Estrutura de Pastas" e "Modelos por Agente")
- mudança de modelo de agente → atualizar `CLAUDE.md` ("Modelos por Agente") **primeiro**, depois espelhar aqui

Mudanças em fluxos, gates ou regras → atualizar **só** `CLAUDE.md`.
