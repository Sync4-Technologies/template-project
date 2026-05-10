---
name: squad-new-project
description: Conduz Fluxo 1 (projeto novo sem artefatos) — PO cria PRD, TL cria plano, Architect define arquitetura, ciclo TDD/CI/revisões/deploy. Use quando o usuário inicia um projeto novo do zero.
---

# Skill — Squad New Project (Fluxo 1)

> **Owner:** Tech Lead | **Revisão:** 90 dias | **Obsolescência:** workflow descontinuado

Esta skill conduz o **Fluxo 1** de projeto novo sem artefatos prévios, conforme `CLAUDE.md` → "Fluxos de Projeto".

---

## Quando usar

- Usuário acionou squad com briefing de produto/feature novo
- Não há PRD, contratos, arquitetura ou código prévio
- Projeto é greenfield

## Quando NÃO usar

- Projeto existente para continuidade → use Fluxo 3 manualmente
- Projeto com artefatos prontos (PRD entregue) → use Fluxo 2 manualmente
- Refatoração → use Fluxo 4 manualmente

---

## Passos do Fluxo 1 (15)

Cada passo abaixo lista o agente responsável. Ver spec completo em `agents/{nome}.md`.

```
1. Usuário aciona [Product Owner](../../../agents/product-owner.md) com briefing
2. PO cria: PRD + Spec Funcional + Histórias com critérios de aceite (incluindo RNFs) — usa skill /squad-prd-template
3. PO apresenta ao usuário
4. Usuário aprova, ajusta ou rejeita (GATE — bloqueia tudo)
5. PO registra mudanças em memory/DECISIONS_LOG.md
6. [Tech Lead](../../../agents/tech-lead.md) recebe PRD aprovado → cria plano de execução
7. TL aciona [Architect](../../../agents/architect.md) → define arquitetura + stack — Architect usa skill /squad-stack-decision
8. TL aciona [Security Engineer](../../../agents/security-engineer.md) (Fase 1) para threat model — features críticas — SE usa skill /squad-threat-model
9. TL aciona [Data Engineer](../../../agents/data-engineer.md) como consultor — quando arquitetura envolver pipelines, DW, ML data prep
10. Architect ajusta arquitetura conforme threat model (≤2 iterações típicas)
11. TL apresenta arquitetura ao usuário (decisões de stack + mitigações de segurança)
12. Usuário aprova, ajusta ou rejeita (GATE — bloqueia implementação)
13. Architect define contratos em /contracts (OpenAPI / JSON Schema / TypeScript)
14. [QA Engineer](../../../agents/qa-engineer.md) define testes → Engineers ([Backend](../../../agents/backend-engineer.md) / [Frontend](../../../agents/frontend-engineer.md) / [Mobile](../../../agents/mobile-engineer.md) / [AI](../../../agents/ai-engineer.md)) implementam → CI (testes/lint/build/SAST) → em paralelo após CI verde: QA exploratório + [Code Reviewer](../../../agents/code-reviewer.md) + Security Engineer (Fase 2 features críticas) → Quality Gates (TL integra) → [DevOps](../../../agents/devops-engineer.md) deploy (canary/blue-green em Production Mode)
15. TL valida entrega final e atualiza memória do sistema (ARCHITECTURE.md, DECISIONS_LOG.md, TASK_BOARD.md → Done)
```

---

## Sua tarefa como Claude

1. **Confirmar** com o usuário que é projeto novo sem artefatos
2. **Acionar Product Owner** primeiro:
   - Apresentar-se como PO
   - Pedir briefing inicial (problema, usuário-alvo, MVP scope)
   - Conduzir criação de `docs/PRD.md` baseado em `docs/PRD-template.md`
   - Garantir RNFs (performance, disponibilidade, volumetria, segurança, compliance, i18n)
3. **Apresentar PRD** ao usuário e capturar feedback
4. **Aguardar aprovação explícita** do usuário antes de prosseguir (gate obrigatório)
5. **Transferir para Tech Lead** após PRD aprovado
6. TL cria plano de execução incluindo:
   - Modo (MVP vs Production)
   - Complexidade
   - Módulos afetados
   - Riscos
   - Tarefas paralelas/sequenciais
7. **Continuar passos 7-15** orquestrando agentes apropriados

---

## Gates obrigatórios (não pular)

- PRD aprovado pelo usuário (passo 4)
- Arquitetura aprovada pelo usuário (passo 12)
- Stack aprovada pelo usuário (passo 12)
- Contratos definidos (passo 13)
- CI verde antes de revisões humanas (passo 14)
- QA + CR + SE aprovados antes de deploy
- Deploy estável + observabilidade ativa antes de "Done"

---

## Outputs esperados ao final

- `docs/PRD.md` aprovado
- `memory/ARCHITECTURE.md` atualizado
- `memory/ADR/ADR-NNN-stack-projeto.md` (decisão de stack)
- `memory/ADR/ADR-NNN-arquitetura.md` se houver decisões estruturais não-padrão
- `/contracts/*.api.yaml`, `*.schema.ts`, etc.
- Código implementado em `src/` ou equivalente
- Pipeline CI/CD verde
- Sistema deployado e monitorado
- `memory/DECISIONS_LOG.md` atualizado

---

## Referências

- Fluxos completos: `CLAUDE.md` → "Fluxos de Projeto"
- Definition of Done Global: `CLAUDE.md` → "Definition of Done Global"
- Modos MVP/Production: `CLAUDE.md` → "MVP vs Production Mode"
