---
name: squad-flag-audit
description: Conduz Tech Lead em review mensal de feature flags ativas (governance ADR-003). Use uma vez por mês ou quando flags > 90 dias acumularem.
---

# Skill — Feature Flag Audit (Review Mensal)

Conduz o TL em **review mensal de feature flags ativas**. Governança (metadata obrigatória, kill switch, review mensal): squad-core §H, fonte ADR-003.

## Quando usar

- Cadência mensal regular (TL agenda) · antes de release significativa (limpar flags concluídas)
- Flag > 90 dias sem decisão · > 20 flags ativas sem review recente

## Quando NÃO usar

- Decisão pontual sobre 1 flag · criação de flag nova (processo padrão)

---

## Sua tarefa como Claude (atuando como TL)

### 1. Coletar lista de flags ativas

Pedir ao DevOps (ou consultar diretamente): todas as flags ativas no provedor (LaunchDarkly / Unleash / Flipt) · metadata (dono, tipo, prazo, criação) · métricas de uso (% de tráfego por variante, último acesso) · flags sem código correspondente (órfãs) · flags sem testes on/off.

### 2. Para cada flag, decidir

| Status | Decisão | Ação |
|--------|---------|------|
| **Manter** | Em uso ativo, dentro do prazo | Renovar prazo se necessário; atualizar metadata |
| **Promover** | Variante "on" estável; rollout 100% concluído | Remover flag check do código; tarefa com tag `flag-cleanup` |
| **Remover** | Feature descontinuada ou variante "off" venceu | Remover flag + código condicional; tarefa em TASK_BOARD |
| **Adiar** | Precisa input adicional (PO, usuário) | Marcar para próximo review; documentar bloqueio |
| **Tech-debt** | > 90 dias sem decisão e sem dono ativo | Tag `tech-debt`; backlog priorizado |

### 3. Validar metadata

- [ ] **Dono** declarado e ainda válido (TL ou PO) · **prazo** definido (default 90 dias) · **tipo** (`release` / `experiment` / `ops` / `permission`)
- [ ] **Kill switch testado** em staging · **testes cobrem ambos paths** (on/off)
- [ ] **Default-deny** em features sensíveis (auth, pagamento) quando flag indisponível

Falha em qualquer item → bloquear merge de PRs novos que dependem dessa flag até regularização.

### 4. Identificar flags problemáticas

- **> 90 dias sem decisão** → tag `tech-debt` + TASK_BOARD + prazo de remoção ≤30 dias
- **Órfãs (sem código)** → remover do provedor imediatamente; documentar em DECISIONS_LOG
- **Sem dono ativo** → reatribuir a TL ou PO; ninguém quer = candidata a remoção
- **Baixo uso (<1% tráfego em 30 dias)** → experimento concluído? abandonada? provavelmente promover ou remover

### 5. Registrar resultado

Em `.claude/squad/project/DECISIONS_LOG.md` com tag `flag-audit`:

```
| YYYY-MM-DD | Flag audit mensal: X mantidas, Y promovidas, Z removidas, W adiadas | Review periódico ADR-003 | Flags afetadas e ações | Tech Lead |
```

Detalhamento em `agent-memory/tech-lead.md` se houver decisões relevantes.

### 6. Atualizar TASK_BOARD

Um card por flag a promover/remover/regularizar: `[FLAG-AUDIT-NN] [ação] flag [nome]` — agente responsável, prioridade, tag `flag-cleanup`, contexto (1 linha).

### 7. Reportar ao usuário (resumo)

```
FLAG AUDIT — YYYY-MM-DD
Flags ativas: N — mantidas X · promovidas Y · removidas Z · adiadas W · tech-debt V
Problemáticas: sem dono [lista] · >90 dias [lista] · órfãs [lista]
Tarefas adicionadas ao TASK_BOARD: [lista] | Próximo review: YYYY-MM-DD
```

---

## Anti-patterns (rejeitar)

- Manter flag indefinidamente "porque pode ser útil depois"
- Reatribuir dono a alguém sem aprovação dessa pessoa
- Promover flag sem confirmar estabilidade da variante "on" (≥ 30 dias 100% sem incidente)
- Remover flag sem confirmar que código condicional foi limpo

---

- **Owner:** Tech Lead · **Par:** DevOps valida metadata na pipeline (devops-engineer.md → "Feature Flags")
- **Fonte:** squad-core §H · `${CLAUDE_PLUGIN_ROOT}/template/memory/ADR/ADR-003-feature-flags.md` · `${CLAUDE_PLUGIN_ROOT}/template/agents/tech-lead.md` → "Feature Flags"
