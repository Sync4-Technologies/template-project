---
name: squad-prd-template
description: Conduz Product Owner na criação de PRD completo (objetivo, escopo, RNFs, critérios de aceite, riscos). Use quando há novo produto/feature a documentar antes de qualquer trabalho técnico.
---

# Skill — PRD Template

> **Owner:** Product Owner | **Revisão:** 90 dias | **Obsolescência:** template `docs/PRD-template.md` removido ou substituído

Esta skill conduz o PO na criação de PRD completo seguindo o template oficial.

---

## Quando usar

- Início de Fluxo 1 (projeto novo)
- Nova feature significativa em projeto existente
- Refatoração com mudança de comportamento (Fluxo 4)
- Escopo dado pelo usuário ainda não está documentado

## Quando NÃO usar

- Bug fix simples (não precisa de PRD)
- Melhoria triada pelo Support Engineer (PO documenta com formato menor)
- PRD já existe e é só ajuste pequeno

---

## Estrutura do PRD (10 seções)

Conforme `docs/PRD-template.md`:

1. **Objetivo** — o que e por que existe
2. **Usuário Alvo** — perfis, contexto, necessidade
3. **Escopo** — IN / OUT explícitos
4. **Requisitos Funcionais** — happy path, alternativos, regras de negócio, estados
5. **Requisitos Não-Funcionais** — performance, disponibilidade, volumetria, segurança, compliance, i18n, cobertura de testes
6. **Critérios de Aceite** — histórias de usuário com Dado/Quando/Então testáveis
7. **Métricas de Sucesso** — baseline + meta 30/90 dias
8. **Dependências** — externas, internas
9. **Riscos** — probabilidade × impacto × mitigação
10. **Histórico de Revisões**

---

## Sua tarefa como Claude (atuando como PO)

### 1. Coletar contexto inicial

Pergunte ao usuário (em ordem):

- **Problema:** qual dor o produto/feature resolve?
- **Usuário alvo:** quem usa? Persona principal e secundárias?
- **Valor:** qual ganho mensurável?
- **Constraints:** prazo, orçamento, compliance, integrações obrigatórias?

### 2. Detectar modo do projeto

- **MVP Mode:** validação de hipótese, time-to-market crítico
- **Production Mode:** sistema com SLA, compliance obrigatório, alta volumetria

Modo afeta seções de RNF (cobertura, observabilidade, SLOs).

### 3. Conduzir cada seção

- Para cada seção, pergunte 1-3 questões direcionadas
- Não aceite "depois preencho" — RNFs especialmente são bloqueantes
- Se usuário não souber RNF (ex: throughput esperado), capture **estimativa + plano de validar**

### 4. RNFs obrigatórios em Production Mode

- Latência P50/P95/P99
- SLA de disponibilidade
- RTO/RPO
- Volumetria (usuários simultâneos, transações/dia)
- Classificação de dados (Público/Interno/Confidencial/Restrito)
- Compliance aplicável (LGPD/GDPR/PCI/HIPAA)
- Idiomas suportados

### 5. Critérios de aceite

Cada história deve ter critérios **testáveis**:

```
US-01 — [Nome]
Como [perfil], Quero [ação], Para [valor].

Critérios:
- [ ] CA-01: Dado X, quando Y, então Z (verificável)
- [ ] CA-02: Dado X, quando Y com erro, então W (cenário de erro)
- [ ] CA-03: [edge case]
```

Rejeitar critérios vagos ("Sistema deve ser rápido" → "P95 ≤ 500ms").

### 6. Apresentar e capturar feedback

- Mostrar PRD completo
- Pedir aprovação explícita do usuário
- Capturar ajustes
- Iterar até aprovação

### 7. Salvar e propagar

- Salvar em `docs/PRD.md`
- Registrar criação em `memory/DECISIONS_LOG.md`
- Notificar TL (PRD aprovado, prosseguir com plano)

---

## Anti-patterns (rejeitar)

- Critérios subjetivos ("intuitivo", "rápido", "fácil")
- RNFs ausentes em Production Mode
- Escopo aberto ("flexível conforme demanda")
- Descrição de UI em vez de comportamento
- Regras implícitas ("o usuário sabe que...")
- Métricas sem baseline ou meta

---

## Referências

- Template: `docs/PRD-template.md`
- Regras do PO: `agents/product-owner.md`
- Modos: `CLAUDE.md` → "MVP vs Production Mode"
