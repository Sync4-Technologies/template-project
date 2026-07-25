# Agent Memory

> Memória especializada por agente. Cada agente mantém um arquivo aqui com padrões adotados, learnings e decisões pequenas específicas do seu papel **neste projeto**.

---

## O que vai aqui

- Padrões adotados pelo agente neste projeto (ex: convenção de nomenclatura usada pelo Backend, design tokens específicos do Frontend)
- Learnings acumulados (ex: "esta lib funciona bem aqui pelo motivo X")
- Decisões pequenas recorrentes que não justificam ADR formal
- Links para ADRs, contratos ou seções de ARCHITECTURE.md relacionadas
- Contexto operacional acumulado pelo agente

## O que NÃO vai aqui

- Arquitetura geral → vai em `.claude/squad/project/ARCHITECTURE.md`
- Decisões estruturais → vai em `.claude/squad/project/ADR/`
- Decisões rápidas que afetam múltiplos agentes → vai em `.claude/squad/project/DECISIONS_LOG.md`
- Regras gerais do papel → vai em `${CLAUDE_PLUGIN_ROOT}/template/agents/{name}.md` (main-thread) ou `${CLAUDE_PLUGIN_ROOT}/agents/{name}.md` (subagents)
- Regras de negócio → vai em `.claude/squad/project/PRD.md` e specs funcionais
- Melhoria do SISTEMA da squad (gap em spec/skill/hook/processo) → vai em `.claude/squad/project/LESSONS_LEARNED.md` (com arquivo a modificar + ação concreta)

**Regra de escrita:** sem emojis/chars astrais — usar `[OK]`, `[!]`, `->` (hook de carregamento trunca por bytes em algumas versões; char astral cortado quebra a sessão seguinte).

---

## Limite

- **Máx 200 linhas por arquivo**
- Excedeu → consolidar entradas antigas, promover para ADR, ou mover learning relevante para ARCHITECTURE.md

---

## Atualização

- O próprio agente atualiza ao final de tarefas relevantes
- Toda entrada com data
- Entradas obsoletas → remover (não acumular ruído)

---

## Auditoria

- Tech Lead revisa trimestralmente
- Agent memory desatualizada > 90 dias = sinal de alerta (agente não está aprendendo ou não está sendo usado)
- TL pode promover learnings recorrentes para ADR ou ARCHITECTURE.md

---

## Estrutura padrão de cada arquivo

```
# Agent Memory — [Nome do Agente]

> Última atualização: YYYY-MM-DD

## Padrões adotados neste projeto
- [padrão] — [data] — [breve justificativa]

## Learnings acumulados
- [data] [learning] [contexto]

## Decisões pequenas
- [data] [decisão] [contexto]

## Referências
- ADRs relacionados:
- Contratos relacionados:
- Seções de ARCHITECTURE.md relacionadas:
```
