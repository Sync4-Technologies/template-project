# PRD — [Nome do Produto / Feature]

> **Status:** Rascunho / Em revisão / Aprovado pelo usuário  
> **Autor:** Product Owner  
> **Data:** YYYY-MM-DD  
> **Aprovado por:** [usuário] em [data]

---

## 1. Objetivo

[O que este produto / feature faz e por que existe. Uma frase clara.]

**Problema que resolve:** [Qual dor ou necessidade endereça]

---

## 2. Usuário Alvo

| Perfil | Contexto | Necessidade principal |
|--------|---------|----------------------|
| [Perfil 1] | [Como usa o sistema] | [O que precisa fazer] |
| [Perfil 2] | | |

---

## 3. Escopo

### IN — O que será construído
- [item 1]
- [item 2]

### OUT — O que NÃO está no escopo
- [item 1]
- [item 2]

---

## 4. Requisitos Funcionais

### Fluxo Principal (Happy Path)
1. [Passo 1]
2. [Passo 2]
3. [Resultado esperado]

### Fluxos Alternativos
- **Quando [condição]:** [comportamento esperado]
- **Quando [condição]:** [comportamento esperado]

### Regras de Negócio
- RN01: [Regra explícita e verificável]
- RN02: [Regra explícita e verificável]

### Estados e Transições
```
[Estado A] → [ação] → [Estado B]
[Estado B] → [ação] → [Estado C]
[Estado B] → [ação de erro] → [Estado A]
```

---

## 5. Requisitos Não-Funcionais

> Obrigatório em **Production Mode**. Fortemente recomendado em MVP.
> O Architect pode elevar os valores abaixo — nunca reduzir sem aprovação do usuário.

### Performance
- Latência P50: [ex: ≤ 200ms]
- Latência P95: [ex: ≤ 500ms]
- Latência P99: [ex: ≤ 1s]
- Throughput esperado: [ex: 1.000 req/s em pico]

### Disponibilidade
- SLA alvo: [ex: 99.9% — máximo 8.7h downtime/ano]
- RTO (Recovery Time Objective): [ex: ≤ 30min]
- RPO (Recovery Point Objective): [ex: ≤ 1h]

### Volumetria
- Usuários simultâneos esperados: [ex: 5.000]
- Transações por dia: [ex: 500.000]
- Volume de dados estimado: [ex: 100GB/mês]
- Crescimento esperado: [ex: 10x em 12 meses]

### Segurança
- Classificação dos dados: [Público / Interno / Confidencial / Restrito]
- Requisitos de auditoria: [ex: todo acesso a dados sensíveis deve ser logado]
- Autenticação: [ex: JWT + MFA para dados confidenciais]
- Autorização: [ex: RBAC com roles: admin, user, readonly]

### Compliance / Regulação
- [ ] LGPD — dados pessoais de brasileiros
- [ ] GDPR — dados de cidadãos da UE
- [ ] PCI DSS — processamento de cartão
- [ ] HIPAA — dados de saúde
- [ ] SOC 2 — auditoria de segurança
- **Outros:** [especificar]

### Cobertura de Testes
- MVP Mode: ≥ 60% em regras críticas de negócio
- Production Mode: ≥ 80% geral / ≥ 95% em regras críticas
- **Este projeto:** [preencher — Architect pode definir valor maior]

### Internacionalização
- Idiomas suportados: [ex: pt-BR (padrão), en-US]
- Localização: [ex: moeda BRL, fuso horário America/São_Paulo]

---

## 6. Critérios de Aceite

> Devem ser objetivos, verificáveis e convertíveis em testes.

### US-01 — [Nome da história]
**Como** [perfil de usuário],  
**Quero** [ação / funcionalidade],  
**Para** [objetivo / valor].

**Critérios de aceite:**
- [ ] CA-01: [Dado X, quando Y, então Z]
- [ ] CA-02: [Dado X, quando Y com erro, então W]
- [ ] CA-03: [Edge case]

### US-02 — [Nome da história]
**Como** [perfil de usuário],  
**Quero** [ação / funcionalidade],  
**Para** [objetivo / valor].

**Critérios de aceite:**
- [ ] CA-01:
- [ ] CA-02:

---

## 7. Métricas de Sucesso

| Métrica | Baseline atual | Meta em 30 dias | Meta em 90 dias |
|---------|--------------|----------------|----------------|
| [Métrica 1] | | | |
| [Métrica 2] | | | |

---

## 8. Dependências

- [Serviço / API externo que esta feature depende]
- [Outra feature que deve estar pronta antes]

---

## 9. Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|-------------|--------|----------|
| [risco 1] | Alta/Média/Baixa | Alto/Médio/Baixo | [ação] |

---

## 10. Histórico de Revisões

| Data | Autor | Mudança |
|------|-------|---------|
| [data] | PO | Criação inicial |
| [data] | [quem] | [o que mudou e por quê] |
