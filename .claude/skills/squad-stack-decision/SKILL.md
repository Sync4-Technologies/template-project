---
name: squad-stack-decision
description: Conduz Architect na decisão de stack do projeto, consultando stack-conventions e apresentando 2-3 opções com trade-offs. Use quando início de projeto novo ou mudança de stack.
---

# Skill — Stack Decision

> **Owner:** Architect | **Revisão:** 90 dias | **Obsolescência:** stack-conventions reorganizadas ou ADR-001 substituído

Esta skill conduz o Architect na decisão de stack do projeto, consultando os documentos em `docs/stack-conventions/`.

---

## Quando usar

- Início de projeto novo (Fluxo 1 ou 2)
- Migração de stack em projeto existente (decisão grande)
- Avaliação de adicionar nova camada (ex: adicionar mobile a projeto web)

## Quando NÃO usar

- Atualização menor de versão de framework (não é decisão de stack)
- Adicionar lib pontual (não é stack)
- Customização local de tooling

---

## Sua tarefa como Claude (atuando como Architect)

### 1. Coletar input do PRD

Antes de propor opções, leia:

- **PRD** — RNFs (performance, disponibilidade, volumetria, compliance, idiomas)
- **Contexto da squad** — expertise do time (TL informa)
- **Restrições operacionais** — infra existente, integrações obrigatórias
- **Modo do projeto** — MVP ou Production (afeta tolerância a complexidade)

### 2. Identificar camadas necessárias

Para cada camada, decidir se aplica:

- **Backend?** Sempre (com raríssimas exceções)
- **Frontend web?** Há UI no browser?
- **Mobile?** Há app iOS/Android?
- **AI?** Há agentes, prompts, integrações com LLM?
- **Data?** Há pipelines, DW, ML data prep?

### 3. Para cada camada, consultar stack-conventions

Para **Backend**:

| Stack | Documento | Critério primário |
|-------|-----------|-------------------|
| Node.js + TS | `docs/stack-conventions/backend/nodejs.md` | I/O intensivo, real-time, ecosistema JS |
| Python | `docs/stack-conventions/backend/python.md` | AI/ML, data, APIs simples |
| PHP | `docs/stack-conventions/backend/php.md` | CMS, e-commerce, Admin pesado |
| Java | `docs/stack-conventions/backend/java.md` | Enterprise, alta concorrência |
| Go | `docs/stack-conventions/backend/go.md` | Performance, microserviços, infra |

Para **Frontend**:

| Stack | Documento | Critério primário |
|-------|-----------|-------------------|
| React + Next.js | `docs/stack-conventions/frontend/react.md` | SSR/SSG, ecosistema maduro, SEO |
| Vue + Nuxt | `docs/stack-conventions/frontend/vue.md` | Curva suave, menos boilerplate |

Para **Mobile**:

| Stack | Documento | Critério primário |
|-------|-----------|-------------------|
| Flutter | `docs/stack-conventions/mobile/flutter.md` | Performance nativa, UI consistente |
| React Native | `docs/stack-conventions/mobile/react-native.md` | Reúso skill React, OTA updates |

Ler seções **"Quando usar"** e **"Quando NÃO usar"** de cada candidata.

### 4. Avaliar contra critérios do projeto

Matriz de decisão:

```
Critério               | Peso | Stack A | Stack B | Stack C
-----------------------|------|---------|---------|--------
Aderência a NFRs       | Alto |  X/10   |  Y/10   |  Z/10
Expertise do time      | Alto |  X/10   |  Y/10   |  Z/10
Maturidade da stack    | Médio|  X/10   |  Y/10   |  Z/10
Compliance suportado   | Alto |  X/10   |  Y/10   |  Z/10
Custo operacional      | Médio|  X/10   |  Y/10   |  Z/10
Ecossistema de libs    | Médio|  X/10   |  Y/10   |  Z/10
Time-to-market         | Médio|  X/10   |  Y/10   |  Z/10
```

### 5. Avaliar fornecedores externos (se aplicável)

Conforme `agents/architect.md` → "Avaliação de Fornecedores Externos":

- Custo total (licença + operação + scaling)
- Lock-in (estratégia de saída)
- SLA do fornecedor vs SLA do produto
- Fallback em indisponibilidade
- Compliance (LGPD/GDPR/PCI/HIPAA suporta?)
- Maturidade e suporte

### 6. Apresentar 2-3 opções ao Tech Lead

Formato:

```
STACK DECISION PROPOSAL — [Camada]
Data: YYYY-MM-DD

Contexto do projeto:
- Modo: [MVP / Production]
- NFRs relevantes: [lista]
- Expertise do time: [resumo informado pelo TL]

Opções:

### Opção 1 — [Stack A] (RECOMENDADA)
- Stack convention: docs/stack-conventions/[path]
- Quando usar (do convention): [resumo]
- Trade-offs:
  - Prós: [lista]
  - Contras: [lista]
- Aderência aos critérios: [score / justificativa]

### Opção 2 — [Stack B]
[mesma estrutura]

### Opção 3 — [Stack C]
[mesma estrutura]

Recomendação técnica: Opção [N]
Motivo: [justificativa em 2-3 linhas]
```

### 7. Tech Lead revisa contexto operacional

TL valida:
- Pipeline existente suporta?
- Infra disponível compatível?
- Time tem capacidade real (não só "já viu")?
- Prazo permite curva de aprendizado se stack nova?

### 8. Conflito Architect × Tech Lead

Se TL discorda da sua recomendação:
- TL pode pedir revisão de trade-offs
- TL pode pedir opções adicionais
- TL **não pode** sobrescrever sua decisão técnica unilateralmente
- Persistindo divergência → escalar ao usuário

### 9. Apresentar ao usuário (TL conduz)

TL apresenta opções + recomendação ao usuário. Usuário aprova/ajusta/veta.

### 10. Registrar decisão

Criar `memory/ADR/ADR-NNN-stack-projeto.md` baseado em `memory/ADR/ADR-template.md`:

- Status: Aceita
- Contexto: por que foi necessária
- Decisão: stack escolhida + versões
- Alternativas consideradas: outras opções com motivo de rejeição
- Trade-offs: o que abrimos mão
- Consequências: positivas, negativas, neutras
- Critérios de revisão: quando reavaliar

### 11. Atualizar ARCHITECTURE.md

`memory/ARCHITECTURE.md` → seção "Stack Tecnológica":
- Tecnologia escolhida + versão
- Link para ADR
- Link para stack convention aplicável

E seção "Stack Conventions Doc" com link para spec ativa.

---

## Anti-patterns (rejeitar)

- Escolher stack pela "novidade" sem avaliar maturidade
- Escolher pelo CV-driven development (dev quer aprender)
- Ignorar expertise do time
- Sem ADR registrando decisão
- Stack hardcoded em código de agentes (deve estar em ADR + ARCHITECTURE.md)

---

## Referências

- ADR-001 (opções padrão): `memory/ADR/ADR-001-stack.md`
- Stack conventions: `docs/stack-conventions/README.md`
- Architect: `agents/architect.md` → "Decisão de Stack"
- TL papel: `agents/tech-lead.md` → "Decisão de Stack"
