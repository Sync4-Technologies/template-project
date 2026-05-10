# Stack Conventions

> Convenções específicas por stack. Cada documento define **quando usar**, **tooling**, **layout**, **padrões idiomáticos** e **comandos**.
>
> Architect consulta estes documentos ao decidir stack do projeto. Engineers consultam o documento da stack ativa ao implementar.

---

## Como funciona

1. **Architect** decide a stack no início do projeto, considerando os critérios "Quando usar" de cada documento
2. Decisão registrada em ADR específico do projeto (ex: `memory/ADR/ADR-NNN-stack-projeto.md`)
3. Stack ativa documentada em `memory/ARCHITECTURE.md` → seção "Stack Conventions Doc"
4. **Engineers** consultam o documento da stack ativa quando recebem tarefas

---

## Stacks suportadas

### Backend

| Stack | Documento | Pontos fortes |
|-------|-----------|---------------|
| Node.js + TypeScript | [`backend/nodejs.md`](backend/nodejs.md) | I/O intensivo, tempo real, compartilhamento de tipos com frontend |
| Python | [`backend/python.md`](backend/python.md) | AI/ML, data pipelines, APIs simples |
| PHP | [`backend/php.md`](backend/php.md) | CMS, e-commerce maduro, ecosistema Laravel/Symfony |
| Java | [`backend/java.md`](backend/java.md) | Sistemas enterprise, alta concorrência, ecosistema Spring |
| Go | [`backend/go.md`](backend/go.md) | Performance crítica, microserviços, ferramentas de infra |

### Frontend

| Stack | Documento | Pontos fortes |
|-------|-----------|---------------|
| React + Next.js | [`frontend/react.md`](frontend/react.md) | SSR/SSG, ecosistema maduro, SEO |
| Vue + Nuxt | [`frontend/vue.md`](frontend/vue.md) | Curva mais suave, menos boilerplate, prototipagem |

### Mobile

| Stack | Documento | Pontos fortes |
|-------|-----------|---------------|
| Flutter (Dart) | [`mobile/flutter.md`](mobile/flutter.md) | Performance nativa, código único, UI consistente |
| React Native | [`mobile/react-native.md`](mobile/react-native.md) | Reúso de skill React, ecosistema JS, flexibilidade |

---

## Adicionar nova stack

1. Architect propõe nova stack em ADR
2. Criar documento em `docs/stack-conventions/{categoria}/{stack}.md`
3. Espelhar estrutura dos documentos existentes (Quando usar / Tooling / Layout / Padrões / Comandos / Anti-patterns)
4. Atualizar tabela neste README
5. Submeter para review do Tech Lead

---

## Estrutura padrão de cada documento

Todo documento de stack convention deve conter:

1. **Quando usar esta stack** — critérios objetivos
2. **Quando NÃO usar** — condições de exclusão
3. **Versões e dependências**
4. **Tooling obrigatório** (linter, formatter, type checker, test runner)
5. **Layout do projeto** (com Hexagonal/Clean Architecture aplicado)
6. **Convenções de código** (naming, idiomáticos da linguagem)
7. **Padrão de testes** (unit, integration, E2E)
8. **Migrations** (backend) ou **State management** (frontend/mobile)
9. **Logging e Observabilidade**
10. **Performance**
11. **Segurança específica da stack**
12. **Comandos padrão**
13. **Anti-patterns a evitar**

---

## Fonte autoritativa

- **Padrão arquitetural geral** (Hexagonal, Clean Architecture mobile, Atomic Design): `agents/{name}.md` + `memory/ADR/ADR-002-arquitetura-hexagonal.md`
- **Convenções idiomáticas da linguagem/framework**: este diretório (stack-conventions)
- **Stack ativa do projeto**: `memory/ARCHITECTURE.md` + ADR específico do projeto

Em caso de conflito entre stack-convention e ADR-002 (Hexagonal): vale ADR-002.
