---
name: squad-scope-change
description: Conduz Tech Lead em fluxo de mudança de escopo durante execução (impacto, aprovação do usuário, propagação). Use quando usuário pede mudança em projeto em andamento.
---

# Skill — Scope Change

Conduz o TL no fluxo de **mudança de escopo durante execução**, conforme `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Gestão de Mudança de Escopo".

## Quando usar

- Usuário pede alteração em feature em andamento
- Issue com label `scope-change` aberta no tracker
- Architect/Engineers reportam requisito implícito fora do escopo aprovado
- Bug descoberto que exige decisão: é bug ou novo escopo?

## Quando NÃO usar

- Bug claro dentro do escopo aprovado → fluxo normal de bug
- Refatoração sem mudança de comportamento → Fluxo 4
- Feature nova não relacionada → Fluxo 1 ou 2

---

## Sua tarefa como Claude (atuando como TL)

### 1. Capturar mudança proposta

- **Origem:** quem solicitou (usuário, PO, Engineer)
- **Mudança:** o que muda em comportamento, regras, fluxos
- **Motivação:** por que (problema descoberto, oportunidade, requisito não previsto)
- **Urgência:** bloqueante? pode aguardar?

### 2. Avaliar impacto técnico

- **Contratos** — contratos na fonte única do repo afetados? breaking ou non-breaking? quais apps (backend/frontend/mobile/AI)?
- **Testes** — cenários do QA a refazer? cobertura existente aplica? novos cenários (happy + erro + edge)?
- **Código** — implementado a reverter/refatorar? quanto trabalho perdido (estimativa)?
- **Arquitetura** — mudança arquitetural? ADRs a revisar/criar?
- **Segurança** — threat model a refazer (Fase 1)? compliance afetado?
- **Riscos** — regressão em outras features · prazo · débito técnico (atalhos sob pressão)

### 3. Estimar retrabalho

Tabela `| Agente | Esforço estimado | Tarefas afetadas |` — uma linha por agente afetado (PO, Architect, engineers, QA, Security, DevOps).

### 4. Apresentar análise ao usuário

```
SCOPE CHANGE PROPOSAL — [título] — YYYY-MM-DD — origem: [quem]
Mudança proposta: [descrição] | Motivação: [por que]
Impacto técnico: contratos · testes a refazer · código a refatorar · arquitetura · segurança
Estimativa de retrabalho: [tabela do passo 3]
Riscos: [risco → mitigação]
Alternativas consideradas: [alt → trade-off]
Recomendação: [aprovar / aprovar com ajustes / rejeitar]
```

### 5. Capturar decisão do usuário

Aguardar aprovação **explícita** (gate obrigatório): **aprovar** → propagar · **aprovar com ajustes** → refinar antes · **rejeitar** → manter escopo, documentar pedido para futuro · **adiar** → analisar mais fundo.

### 6. Propagar (após aprovação)

1. **PO** atualiza PRD, specs, critérios de aceite
2. **Architect** atualiza arquitetura/contratos/ADRs
3. **QA** redefine testes
4. **Engineers** continuam com escopo atualizado
5. **Security Engineer** re-valida (se aplicável)

### 7. Registrar em DECISIONS_LOG.md

```
| YYYY-MM-DD | Scope change aprovado: [resumo] | [motivação] | [módulos afetados, retrabalho estimado] | Tech Lead |
```

Tag: `scope-change`

### 8. Atualizar TASK_BOARD

Tarefas a refazer → "Todo" com tag `scope-change` · adicionar novas tarefas geradas · documentar bloqueios em "Blocked" se necessário.

---

## Anti-patterns (rejeitar)

- "Já que estamos refazendo X, aproveita e muda Y também" sem aprovação → bloquear
- Esconder retrabalho do usuário → bloquear

---

- **Owner:** Tech Lead · **Par:** PO no recebimento (product-owner.md → "Gestão de Mudança de Escopo (Recebimento)")
- **Fonte:** `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Gestão de Mudança de Escopo"
