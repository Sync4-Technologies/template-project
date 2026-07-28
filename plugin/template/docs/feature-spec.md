# Mini-spec de feature — template

> Copiar para `.claude/squad/project/specs/<ID-da-task>.md`. Um arquivo por feature/task não-trivial.
> Contrato: Architect. Critérios e cenários: QA. Engineer implementa CONTRA este arquivo; Code Reviewer cobra contra ele.
> Alvo: ~40 linhas. Spec que precisa de mais provavelmente é 2 tasks.

---

```markdown
# <ID> — <título curto>

**Objetivo (1 linha):** [que problema do usuário isto resolve]
**Modo:** MVP | Production · **Crítica:** sim/não (se sim: SE Fase 1 feita? link)

## Contrato (Architect)

[API: método + rota + request/response com tipos + erros possíveis.
Frontend: props/tipos + estados. Evento/job: payload + garantias.]

## Critérios de aceite (QA, com PO)

- [ ] [comportamento observável 1 — verificável por comando/teste]
- [ ] [comportamento observável 2]

## Cenários de teste (QA — escritos ANTES da implementação)

### Principais
- [dado X, quando Y, então Z]

### Erro
- [input inválido / dependência fora / permissão negada → comportamento esperado]

### Edge
- [limite, vazio, concorrência, idempotência — o que se aplicar]

## Fora de escopo

- [o que esta task explicitamente NÃO faz — mata scope creep na revisão]
```

---

Regras:

- Cenário sem forma verificável por comando não entra — reescrever até ser testável (squad-core §G).
- Mudou o comportamento durante a implementação? A spec muda JUNTO (mesmo PR) — spec desatualizada é pior que sem spec.
- Reviewer usa a spec como contrato: implementado ≠ especificado → achado, independente de "funcionar".
