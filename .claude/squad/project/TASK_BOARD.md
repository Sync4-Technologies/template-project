# TASK_BOARD.md

> Kanban em markdown. Estado atual das tarefas da squad.
> Atualizar após cada mudança de status.

---

## 🎯 Current Focus

> Pointer "onde paramos". Atualizado a cada sessão pelo TL (skill `/squad-handoff` automatiza).
> Primeiro lugar que User B olha ao retomar (skill `/squad-resume` lê esta seção primeiro).

- **Última sessão:** YYYY-MM-DD por [usuário]
- **Em andamento:** [tarefa principal — link para card abaixo]
- **Próximo passo:** [ação específica e concreta]
- **Bloqueios:** [se houver]
- **PR ativo:** [link se aplicável]
- **Branch ativo:** [nome do branch]
- **Modo do projeto:** [MVP / Production]

---

## Formato do Card

```
### [ID] Título da tarefa
- **Agente:** Backend Engineer / QA / etc.
- **Prioridade:** Alta / Média / Baixa
- **Sprint:** [número ou nome]
- **Contexto:** [link para PRD / contrato / ADR relevante]
- **Bloqueios:** [nenhum / descrição]
```

---

## 📋 Todo

<!-- Tarefas priorizadas mas não iniciadas -->

### [TASK-001] Exemplo: Definir contratos da API de autenticação
- **Agente:** Architect
- **Prioridade:** Alta
- **Sprint:** 1
- **Contexto:** PRD/auth.md
- **Bloqueios:** Aguardando aprovação do PRD pelo usuário

---

## 🔄 Doing

<!-- Máximo 1 tarefa por agente ao mesmo tempo -->

---

## 👀 Review

<!-- Aguardando QA e/ou Code Review e/ou Security Review -->

---

## ✅ Done

<!-- Tarefas concluídas (mover para cá após todos os gates passarem) -->

---

## 🚫 Blocked

<!-- Tarefas bloqueadas com causa explícita -->

---

## 🏷️ Tags

- `tech-debt` — débito técnico aprovado com ciência
- `hotfix` — correção urgente em produção
- `scope-change` — mudança de escopo durante execução
- `security` — tarefa com impacto em segurança
- `breaking-change` — altera contrato existente
- `design-debt` — drift visual identificado em audit do Product Designer
- `ds-update` — bump de version do DS externo
- `flag-cleanup` — remoção de feature flag após rollout 100%
- `handoff` — tarefa preparada para retomada por outro usuário
