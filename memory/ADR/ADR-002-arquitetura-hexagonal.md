# ADR-002 — Arquitetura Hexagonal (Ports & Adapters)

**Status:** Aceita
**Data:** 2026-05-09
**Autor:** Architect

---

## Contexto

A squad precisa de um padrão arquitetural preferencial para backend e camada de IA que:
- isole o domínio (regras de negócio) de detalhes externos (HTTP, DB, fila, LLM)
- permita evolução sem retrabalho massivo
- facilite testes unitários do domínio sem mocks de infra
- viabilize troca de provedores externos (DB, LLM, gateway de pagamento) sem reescrita

A camada tradicional controller/service/repository funciona em projetos simples mas acopla domínio a frameworks (FastAPI, Express, NestJS) e a tecnologias específicas de persistência.

---

## Decisão

**Arquitetura Hexagonal (Ports & Adapters) é o padrão preferencial em backend e em IA quando couber.**

Estrutura:

```
Domain (centro)        ← entidades, regras de negócio, ports (interfaces)
   ▲
   │
Application            ← use cases que orquestram o domain via ports
   ▲
   │
Adapters (borda)       ← HTTP controllers, DB repositories, LLM clients, MCP tools
                         (implementam os ports)
```

### Quando usar (default)

- Features críticas (auth, pagamento, dados sensíveis, integrações)
- Domínio rico (regras de negócio complexas, invariantes não triviais)
- Expectativa de evolução (produto vai escalar, requisitos mudam)
- Troca previsível de provedor (LLM, gateway, DB managed)
- Multi-platform com lógica compartilhada

### Quando NÃO usar (justificar em ADR específico)

- CRUD simples sem regras de negócio relevantes
- Dashboards e ferramentas internas
- Scripts e automações pontuais
- MVP ultra-curto onde simplicidade > flexibilidade

Nestes casos, usar camadas tradicionais (controller/service/repository) é aceitável. Architect documenta a decisão em ADR específico do projeto.

---

## Aplicação por agente

### Backend Engineer
- `domain/` — entidades, value objects, ports (interfaces de repositório, gateways)
- `application/` — use cases (orquestram domain via ports)
- `adapters/inbound/` — HTTP controllers, CLI handlers, message consumers
- `adapters/outbound/` — DB repositories, external API clients, queue producers

### AI Engineer
- `domain/` — lógica de prompt, validação de output, orquestração de agentes
- `application/` — use cases (responder pergunta, classificar texto, agente conversacional)
- `adapters/inbound/` — HTTP/MCP/CLI handlers
- `adapters/outbound/` — LLM client (Anthropic/OpenAI), tools, memory store

Permite trocar provedor LLM (ex: Anthropic → OpenAI) sem afetar domain.

### Mobile (Clean Architecture mobile já alinhada)
A separação UI / State / Domain / Data já corresponde à Hexagonal — nada novo a fazer, apenas confirmar terminologia.

### Frontend
Atomic Design já cobre componentização. Hexagonal não agrega valor proporcional ao custo. Manter Atomic Design.

---

## Alternativas Consideradas

### Camadas tradicionais (controller/service/repository)
- **Prós:** simples, baixo boilerplate, padrão amplamente conhecido
- **Contras:** acopla domain a framework, dificulta troca de provedor, mistura regras com infra
- **Status:** aceitável em projetos simples; rejeitado como default

### Clean Architecture (Robert Martin)
- **Prós:** muito similar a Hexagonal, mais camadas formais (entities/use cases/interface adapters/frameworks)
- **Contras:** mais boilerplate; sobreposição com Hexagonal sem ganho prático
- **Status:** Hexagonal é simplificação suficiente

### Onion Architecture
- **Prós:** similar a Hexagonal
- **Contras:** sem diferença prática relevante para nosso contexto
- **Status:** Hexagonal preferido por terminologia mais difundida

---

## Trade-offs Assumidos

- Mais boilerplate inicial (interfaces, organização em camadas)
- Curva de aprendizado para devs novos no padrão
- Em troca: domain testável sem infra, troca de provedor sem retrabalho, evolução controlada

---

## Consequências

### Positivas
- Domain isolado e testável unitariamente
- Adapters trocáveis (DB, LLM, gateway) sem afetar regras
- Testes de domínio rápidos (sem rede, sem DB)
- Convergência com Clean Architecture mobile
- Combina excepcionalmente bem com feature flags (adapters podem ser comutados por flag)

### Negativas / Riscos
- Mais arquivos e camadas em projetos pequenos = over-engineering
- Risco de purismo arquitetural travar entrega — Architect deve aplicar com pragmatismo

### Neutras
- Convenção de nomenclatura (ports/adapters) deve ser explícita em README do módulo

---

## Critérios de Revisão

Esta decisão deve ser revisada se:
- Padrão dominante na indústria mudar significativamente
- Custo de boilerplate impactar throughput em projetos comprovadamente simples
- Surgir alternativa equivalente com menor complexidade
