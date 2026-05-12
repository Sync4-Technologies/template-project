---
name: squad-flag-audit
description: Conduz Tech Lead em review mensal de feature flags ativas (governance ADR-003). Use uma vez por mês ou quando flags > 90 dias acumularem.
---

# Skill — Feature Flag Audit (Review Mensal)

> **Owner:** Tech Lead | **Revisão:** 90 dias | **Obsolescência:** ADR-003 substituído ou processo automatizado externamente

Esta skill conduz o TL em **review mensal de feature flags ativas** conforme governance do ADR-003.

---

## Quando usar

- Cadência mensal regular (TL agenda)
- Antes de release significativa (limpar flags concluídas)
- Quando notificado de flag > 90 dias sem decisão
- Ao detectar > 20 flags ativas sem review recente

## Quando NÃO usar

- Decisão pontual sobre 1 flag (não precisa de skill)
- Criação de flag nova (use processo padrão de criação)

---

## Sua tarefa como Claude (atuando como TL)

### 1. Coletar lista de flags ativas

Pedir ao DevOps (ou consultar diretamente):

- Todas as flags ativas no provedor (LaunchDarkly / Unleash / Flipt)
- Metadata: dono, tipo, prazo, data de criação
- Métricas de uso: % de tráfego em cada variante, último acesso
- Flags sem código correspondente (orfãs)
- Flags sem testes cobrindo on/off

### 2. Para cada flag, decidir

Apresentar ao usuário/TL para decisão:

| Status | Decisão | Ação |
|--------|---------|------|
| **Manter** | Flag ainda em uso ativo, dentro do prazo | Renovar prazo se necessário; atualizar metadata |
| **Promover** | Variante "on" estável; rollout 100% concluído | Remover flag check do código; tarefa em TASK_BOARD com tag `flag-cleanup` |
| **Remover** | Feature descontinuada ou variante "off" venceu | Remover flag + código condicional; tarefa em TASK_BOARD |
| **Adiar** | Decisão precisa input adicional (PO, usuário) | Marcar para próximo review; documentar bloqueio |
| **Tech-debt** | > 90 dias sem decisão e sem dono ativo | Tag `tech-debt`; entrar em backlog priorizado |

### 3. Validar metadata

Para cada flag, verificar:

- [ ] **Dono** declarado e ainda válido (TL ou PO)
- [ ] **Prazo** definido (default 90 dias da criação)
- [ ] **Tipo** declarado: `release` / `experiment` / `ops` / `permission`
- [ ] **Kill switch testado** em staging
- [ ] **Testes cobrem ambos paths** (on/off)
- [ ] **Default-deny** em features sensíveis (auth, pagamento) quando flag indisponível

Falha em qualquer item → bloquear merge de PRs novos que dependem dessa flag até regularização.

### 4. Identificar flags problemáticas

#### Flags > 90 dias sem decisão
- Aplicar tag `tech-debt`
- Adicionar a `.claude/squad/project/TASK_BOARD.md`
- Atribuir prazo de remoção (≤ 30 dias)

#### Flags órfãs (sem código)
- Remover do provedor imediatamente
- Documentar em `.claude/squad/project/DECISIONS_LOG.md`

#### Flags sem dono ativo
- Reatribuir a TL ou PO conforme contexto
- Se ninguém quer = candidata a remoção

#### Flags com baixo uso (< 1% tráfego em 30 dias)
- Avaliar: experimento concluído? feature abandonada?
- Provavelmente promover ou remover

### 5. Registrar resultado

Em `.claude/squad/project/DECISIONS_LOG.md` com tag `flag-audit`:

```
| YYYY-MM-DD | Flag audit mensal: X mantidas, Y promovidas, Z removidas, W adiadas | Review periódico ADR-003 | Lista de flags afetadas e ações | Tech Lead |
```

Detalhamento em `.claude/squad/project/agent-memory/tech-lead.md` se houver decisões relevantes.

### 6. Atualizar TASK_BOARD

Para cada flag a promover/remover/regularizar:

```
### [FLAG-AUDIT-NN] Remover flag `feature_x` (promovida em 2026-05-09)
- **Agente:** Backend Engineer / Frontend Engineer
- **Prioridade:** Média
- **Tags:** flag-cleanup
- **Contexto:** Variante "on" rollout 100% há 30 dias; estabilizou
- **Bloqueios:** Nenhum
```

### 7. Reportar ao usuário (resumo)

Após review:

```
FLAG AUDIT — YYYY-MM-DD

Flags ativas: N
- Mantidas: X
- Promovidas (rollout 100% + cleanup): Y
- Removidas: Z
- Adiadas: W
- Tech-debt: V

Flags problemáticas identificadas:
- Sem dono: [lista]
- > 90 dias: [lista]
- Órfãs: [lista]

Próximo review: YYYY-MM-DD (mês seguinte)

Tarefas adicionadas ao TASK_BOARD: [lista]
```

---

## Anti-patterns (rejeitar)

- Manter flag indefinidamente "porque pode ser útil depois"
- Reatribuir dono a alguém sem aprovação dessa pessoa
- Promover flag sem confirmar estabilidade da variante "on" (≥ 30 dias 100% sem incidente)
- Remover flag sem confirmar que código condicional foi limpo

---

## Referências

- ADR-003: `.claude/squad/template/memory/ADR/ADR-003-feature-flags.md`
- TL governance: `.claude/squad/template/agents/tech-lead.md` → "Coordenação de Feature Flags"
- DevOps validation: `.claude/squad/template/agents/devops-engineer.md` → "Feature Flags"
- Code Reviewer enforcement: `.claude/squad/template/agents/code-reviewer.md` → "Valida uso de Feature Flags"
