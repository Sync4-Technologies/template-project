---
name: squad-scope-change
description: Conduz Tech Lead em fluxo de mudança de escopo durante execução (impacto, aprovação do usuário, propagação). Use quando usuário pede mudança em projeto em andamento.
---

# Skill — Scope Change

> **Owner:** Tech Lead | **Revisão:** 90 dias | **Obsolescência:** processo de scope-change mudar significativamente

Esta skill conduz o TL no fluxo de **mudança de escopo durante execução**, conforme `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Gestão de Mudança de Escopo".

---

## Quando usar

- Usuário pede alteração em feature em andamento
- Issue com label `scope-change` aberta no tracker
- Architect/Engineers reportam que requisito implícito está fora do escopo aprovado
- Bug descoberto que exige decisão sobre se é bug ou novo escopo

## Quando NÃO usar

- Bug claro dentro do escopo aprovado → fluxo normal de bug
- Refatoração sem mudança de comportamento → use Fluxo 4
- Feature nova não relacionada → use Fluxo 1 ou 2

---

## Sua tarefa como Claude (atuando como TL)

### 1. Capturar mudança proposta

Documente:

- **Origem:** quem solicitou (usuário, PO, Engineer)
- **Mudança:** o que muda em comportamento, regras, fluxos
- **Motivação:** por que (problema descoberto, oportunidade, requisito não previsto)
- **Urgência:** bloqueante? pode aguardar?

### 2. Avaliar impacto técnico

Análise estruturada:

#### Contratos
- [ ] Contratos em `.claude/squad/project/contracts/` afetados? Quais?
- [ ] Mudança breaking ou non-breaking?
- [ ] Backend, Frontend, Mobile, AI afetados?

#### Testes
- [ ] Testes já escritos pelo QA precisam ser refeitos?
- [ ] Cobertura existente aplica?
- [ ] Novos cenários (happy + erro + edge) precisam ser definidos?

#### Código
- [ ] Código já implementado precisa ser revertido/refatorado?
- [ ] Quanto trabalho perdido (estimativa em horas/dias)?

#### Arquitetura
- [ ] Mudança exige alteração arquitetural?
- [ ] ADRs precisam ser revisados ou criados?

#### Segurança
- [ ] Threat model precisa ser refeito (Fase 1)?
- [ ] Compliance afetado?

#### Riscos
- [ ] Risco de regressão em outras features
- [ ] Risco de prazo
- [ ] Risco de débito técnico (atalhos sob pressão)

### 3. Estimar retrabalho

Para cada agente afetado, estime:

| Agente | Esforço estimado | Tarefas afetadas |
|--------|-----------------|------------------|
| PO | [horas/dias] | Atualizar PRD, specs, critérios |
| Architect | [horas/dias] | Revisar arquitetura, ADRs, contratos |
| Backend | [horas/dias] | Refatorar X, refazer Y |
| Frontend | [horas/dias] | ... |
| Mobile | [horas/dias] | ... |
| QA | [horas/dias] | Redefinir testes, refazer cenários |
| Security | [horas/dias] | Re-validar threats |
| DevOps | [horas/dias] | Pipeline, deploys |

### 4. Apresentar análise ao usuário

Formato:

```
SCOPE CHANGE PROPOSAL — [título]
Data: YYYY-MM-DD
Origem: [quem solicitou]

Mudança proposta:
[descrição clara]

Motivação:
[por que]

Impacto técnico:
- Contratos afetados: [lista]
- Testes a refazer: [N cenários]
- Código a refatorar: [estimativa]
- Arquitetura: [mudança ou não]
- Segurança: [re-threat model ou não]

Estimativa de retrabalho: [horas/dias por agente]

Riscos:
- [risco 1]: [mitigação]
- [risco 2]: [mitigação]

Alternativas consideradas:
- [alt 1]: [trade-off]
- [alt 2]: [trade-off]

Recomendação: [aprovar / aprovar com ajustes / rejeitar]
```

### 5. Capturar decisão do usuário

Aguardar aprovação **explícita** (gate obrigatório). Opções:

- **Aprovar como está** — prosseguir com propagação
- **Aprovar com ajustes** — refinar antes de prosseguir
- **Rejeitar** — manter escopo original; documentar pedido para futuro
- **Adiar** — analisar mais profundo antes de decidir

### 6. Propagar (após aprovação)

Notificar agentes afetados em sequência:

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

- Mover tarefas em andamento que precisam ser refeitas para "Todo" com tag `scope-change`
- Adicionar novas tarefas geradas pela mudança
- Documentar bloqueios em "Blocked" se necessário

---

## Anti-patterns (rejeitar)

- Mudança de escopo sem análise de impacto → bloquear
- Implementação sem aprovação explícita do usuário → bloquear
- "Já que estamos refazendo X, aproveita e muda Y também" sem aprovação → bloquear
- Esconder retrabalho do usuário → bloquear

---

## Referências

- TL processo: `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Gestão de Mudança de Escopo"
- PO recebimento: `${CLAUDE_PLUGIN_ROOT}/template/agents/product-owner.md` → "Gestão de Mudança de Escopo (Recebimento)"
- DECISIONS_LOG.md: `.claude/squad/project/DECISIONS_LOG.md`
- TASK_BOARD.md: `.claude/squad/project/TASK_BOARD.md`
