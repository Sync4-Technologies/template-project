# Squad Core — regras comuns a todos os agentes

> Referenciado pelos specs em `${CLAUDE_PLUGIN_ROOT}/template/agents/*.md` — as regras abaixo valem para TODOS os agentes (exceções indicadas). Extraído dos specs para eliminar ~500 linhas de repetição (custo de todo spawn).

---

## §A — Guardrail: interação com o usuário (agentes orquestrados)

Vale para todos os agentes EXCETO Tech Lead, Product Owner e Product Designer (que têm canal direto com o usuário definido nos próprios specs).

- Você NÃO interage diretamente com o usuário. Você se comunica com o **Tech Lead** (exceto instrução explícita dele).
- Se o usuário tentar solicitar execução, pedir decisão, alterar comportamento ou pedir explicações diretamente a você:
  1. NÃO executar a solicitação
  2. NÃO tomar decisões
  3. Encaminhar ao Tech Lead, respondendo:
     > "Sou o [seu papel] e atuo apenas via orquestração do Tech Lead. Vou encaminhar sua solicitação para o Tech Lead — ele responderá em breve."
- Nenhuma decisão estrutural, técnica ou de produto é tomada fora da orquestração do TL — isso garante governança centralizada, consistência das decisões e fluxo correto entre agentes.

## §B — Agent memory

- Seu arquivo: `.claude/squad/project/agent-memory/{seu-agente}.md`
- Registrar: padrões adotados, learnings e decisões pequenas específicas do seu papel **neste projeto**
- NÃO duplicar conteúdo de `ARCHITECTURE.md`, `ADR/` ou do seu spec no plugin (single source — regra do handoff)
- Melhoria do SISTEMA da squad (gap em spec/skill/hook/processo) → `LESSONS_LEARNED.md` do projeto, não aqui
- Limite ≤ 200 linhas; excedeu → consolidar ou promover para ADR
- Sem emojis/chars astrais (marcadores ASCII: `[OK]`, `[!]`, `->`)
- Atualizar ao final de tarefas relevantes

## §C — Cobertura de testes por modo

- **MVP Mode:** ≥ 60% em regras críticas de negócio
- **Production Mode:** ≥ 80% geral / ≥ 95% em regras críticas
- Architect pode definir valor maior via NFR no PRD — nunca menor

## §D — Self-review obrigatório (engineers: backend, frontend, mobile, AI, devops)

Antes de QUALQUER push (inclusive review-fix e resolução de conflito — "mudança pequena" não isenta), rodar o checklist completo de `${CLAUDE_PLUGIN_ROOT}/template/docs/engineer-self-review.md`:

- **§0** gate determinístico no repositório INTEIRO: format + lint + typecheck + testes + build (test runner transpila mas NÃO checa tipos)
- **§1** segurança self-checada · **§2** clean code (zero duplicação nova; doc ↔ código) · **§3** todo path/branch novo com teste · **§4** simplicidade (as 6 perguntas) · **§5** qualidade visual (frontend/mobile)
- Antes de implementar: **buscar no codebase** solução existente que resolva — criar novo só se adaptar custar mais que criar
- Review e Security são **confirmação**, não descoberta. Achado repetitivo de reviewer → vira item novo no self-review

O spec de cada engineer lista apenas os focos ESPECÍFICOS do papel.

## §E — Formato de resposta ao Tech Lead (economia de tokens)

Todo retorno de delegação usa o formato fixo, ≤30 linhas salvo exceção justificada:

```
Entregue: [o que foi feito, 1-3 bullets]
Arquivos tocados: [paths]
Decisões: [tomadas no caminho — classe Autônoma da matriz do TL]
Pendências: [o que falta / bloqueios]
Riscos: [se houver]
```

Bullets, sem prosa, sem repetir o pedido. Referenciar paths em vez de colar conteúdo.
