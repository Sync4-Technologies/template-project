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

---

## Checklist obrigatório — feature com MARCADOR de idempotência (AM-43)

Vale para sweep, job periódico, retry, "notificar uma vez", `processed_at`/`notified_at`/`*_sent_at`.
Duas famílias de defeito que **suíte 100% verde não pega** (2 marcos seguidos, 23 achados de review):

- [ ] **O WHERE da marcação leva o marcador E o predicado de ESTADO.** `updateMany({where:{id, notifiedAt:null}})` só fecha a corrida entre dois ticks do MESMO job. Contra uma transação de USUÁRIO que muda outra coluna (concluir a tarefa, ganhar o lead), falta `status`. Filtro de estado no SELECT do candidato **não** substitui: entre o SELECT e o UPDATE a linha muda. Sintoma: notificação e **evento de domínio falsos**, que a automação a jusante consome.
- [ ] **Todo campo de elegibilidade que muda RESETA os marcadores** — e **por MUDANÇA de valor, nunca por presença da chave no payload**. Sem reset, adiar um prazo deixa o marcador do prazo antigo e o alerta morre para sempre (sem corrida nenhuma). Resetando por presença, um PATCH de formulário que reenvia o campo inalterado re-arma o job e **duplica** alerta e evento. As duas pontas são a mesma pergunta: *o marcador ainda corresponde ao valor que ele marca?*
- [ ] **Teste de corrida com lock explícito**, além do sequencial. `SELECT ... FOR UPDATE` numa conexão dedicada força a ordem; `setTimeout` é flake. Sem isso, "dois ticks seguidos" passa verde com a corrida aberta.
- [ ] **O teste prova o MECANISMO, não a consequência.** "Terminal não tem prazo vivo" passa verde com o filtro ausente. Produza o estado por escrita direta e asserte que o candidato **não é selecionado**.

## Checklist obrigatório — e2e com SETUP (AM-44)

- [ ] **Todo POST/PATCH de setup asserta o status** (`expect(res.status).toBe(201)`). Seed silencioso mascara 4xx e desloca o sintoma para testes sem relação com a causa — um 422 engolido no `beforeAll` já deixou uma suíte inteira rodando com a configuração errada por dias, com os vermelhos aparecendo em dois testes que nada tinham a ver.
- [ ] **Comparação de tempo ancora no valor LIDO do sistema** (GET do registro + delta), nunca no relógio local: app e banco têm relógios diferentes, e a diferença aparece como flake inexplicável.
