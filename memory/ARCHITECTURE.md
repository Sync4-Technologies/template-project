# ARCHITECTURE.md

> Fonte de verdade da arquitetura do sistema.
> Atualizar sempre que houver mudança estrutural relevante.
> Última atualização: [data]

---

## Visão Geral

[Descrição em 2–3 parágrafos do que o sistema faz, seu propósito e principais características.]

---

## Modo de Operação

- [ ] MVP Mode
- [ ] Production Mode

**Justificativa:** [Por que este modo foi escolhido]

---

## Stack Tecnológica

| Camada | Tecnologia | Versão | ADR | Stack Convention |
|--------|-----------|--------|-----|------------------|
| Backend | | | | `docs/stack-conventions/backend/{stack}.md` |
| Frontend | | | | `docs/stack-conventions/frontend/{stack}.md` |
| Mobile | | | | `docs/stack-conventions/mobile/{stack}.md` |
| Banco de dados principal | | | | |
| Cache | | | | |
| IA / LLM | | | | |
| Infraestrutura | | | | |
| CI/CD | | | | |
| Cloud | | | | |

Ver detalhes em `memory/ADR/ADR-001-stack.md` e ADR específico do projeto.

### Stack Conventions Doc (fonte de convenções idiomáticas)

| Camada | Documento aplicável |
|--------|---------------------|
| Backend | [preencher com link relativo após decisão] |
| Frontend | [preencher com link relativo após decisão] |
| Mobile | [preencher com link relativo após decisão] |

Engineers consultam estes documentos ao implementar.

---

## Bounded Contexts

### [Context 1 — Nome]
- **Responsabilidade:** [O que este contexto faz]
- **Entidades principais:** [Lista]
- **Dependências:** [Outros contextos que este consome]
- **Expõe:** [Contratos / APIs que este fornece]

### [Context 2 — Nome]
- **Responsabilidade:**
- **Entidades principais:**
- **Dependências:**
- **Expõe:**

---

## Componentes do Sistema

| Componente | Tipo | Responsabilidade | Contrato |
|-----------|------|-----------------|--------|
| | API REST / gRPC / Event | | |
| | Frontend SPA / SSR | | |
| | Worker / Consumer | | |
| | Scheduler | | |

---

## Fluxos Principais

### Fluxo 1 — [Nome do fluxo]
```
[Ator] → [Componente A] → [Componente B] → [Resultado]
```

### Fluxo 2 — [Nome do fluxo]
```
[Ator] → [Componente A] → [Componente B] → [Resultado]
```

---

## Modelo de Dados Conceitual

[Diagrama textual ou lista de entidades com relacionamentos principais]

```
[Entidade A] 1─── N [Entidade B]
[Entidade B] N─── N [Entidade C]
```

---

## Decisões Estruturais

| Decisão | Escolha | Alternativa rejeitada | ADR |
|---------|---------|----------------------|-----|
| Arquitetura geral | | | |
| Estratégia de autenticação | | | |
| Estratégia de cache | | | |
| Estratégia de mensageria | | | |

---

## Dependências Externas

| Serviço | Propósito | SLA | Fallback | Compliance |
|---------|-----------|-----|---------|-----------|
| | | | | |

---

## Padrões Adotados

- **Backend:** [Hexagonal (Ports & Adapters) — default — ver `memory/ADR/ADR-002-arquitetura-hexagonal.md` | OU camadas tradicionais se justificado em ADR específico]
- **AI:** [Hexagonal aplicada — domain isolado de adapters de LLM/tools/MCP]
- **Frontend:** [Atomic Design]
- **Mobile:** [Clean Architecture mobile (alinhada com Hexagonal)]
- **API:** [ex: REST + OpenAPI, versionamento por URL /v1/]
- **Eventos:** [ex: Event-driven via RabbitMQ / Kafka / SQS]
- **Segurança:** [ex: JWT + refresh token, RBAC]
- **Feature Flags:** [ferramenta + governança — ver `memory/ADR/ADR-003-feature-flags.md`]
- **Design System:** [DS escolhido — ver `memory/ADR/ADR-005-design-system.md` e `/docs/design-system/`]

---

## Design System Doc

| Item | Valor |
|------|-------|
| DS escolhido | [Material 3 (default) / shadcn-ui / Carbon / Polaris / Atlassian / Custom] |
| Versão | [versão] |
| Implementação | [MUI vN / Vuetify / Material Web Components / react-native-paper / Flutter Material / etc.] |
| Documentação | `/docs/design-system/` |
| ADR autoritativa | `memory/ADR/ADR-005-design-system.md` |
| ADR específico (se DS != default) | [link] |
| Última extração / audit | [data se aplicável] |

---

## Observabilidade

| Componente | Logs | Métricas | Tracing | Alertas |
|-----------|------|---------|--------|--------|
| | | | | |

---

## SLOs Definidos (Production Mode)

| Serviço | Disponibilidade | Latência P95 | Latência P99 |
|---------|----------------|-------------|-------------|
| | | | |

---

## Backup / Disaster Recovery

| Componente | Frequência de backup | Retenção | RTO | RPO | Localização |
|-----------|---------------------|----------|-----|-----|------------|
| | | | | | |

### Estratégia de DR

- **Multi-AZ:** [sim/não]
- **Multi-Region:** [sim/não — quando aplicável]
- **Runbook de DR:** [link para `/docs/runbooks/disaster-recovery.md`]
- **Última validação de restore:** [data]
- **Última DR drill:** [data]

---

## Estratégia de Deploy

- **Estratégia:** [Blue-Green / Canary / Feature Flags / Direct]
- **Rollback:** automático em falha de health check, manual ≤ 5min
- **Feature Flags:** [ferramenta utilizada]
- **Branching:** [Trunk-Based / GitFlow]
