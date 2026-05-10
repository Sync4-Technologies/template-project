# Stack Convention — Node.js (TypeScript)

> Frameworks suportados: **NestJS** (preferencial para projetos grandes) ou **Express** (APIs simples). Sempre TypeScript.

---

## Quando usar esta stack

Escolher Node.js + TypeScript quando:

- **I/O intensivo** — alto volume de requests, real-time (WebSockets, SSE), streaming
- **Compartilhamento de tipos com frontend** — monorepo com React/Next.js consumindo tipos do backend
- **Ecosistema JS no time** — desenvolvedores já dominam JS/TS
- **Tempo real** — chat, notificações push, dashboards live
- **Microserviços orquestrados via API** — lightweight, startup rápido
- **APIs GraphQL** — Apollo Server tem ótima maturidade
- **Edge functions** — Vercel/Cloudflare Workers compatíveis
- **Backend-for-Frontend (BFF)** — agregação para mobile/web

## Quando NÃO usar

- **CPU-bound pesado** (processamento de imagem/vídeo, ML inference) — preferir Python/Go
- **Cálculos numéricos intensos** — falta de SIMD nativo, GC pause
- **AI/ML pipelines** — ecosistema Python é dramaticamente superior
- **Sistemas com requisitos hard real-time** — GC imprevisível
- **Equipes sem experiência em assincronismo** — async/await mal usado vira pesadelo

---

## Versões e dependências

| Item | Versão mínima |
|------|---------------|
| Node.js | ≥ 20 LTS (preferir 22 LTS quando disponível) |
| TypeScript | ≥ 5.4 |
| pnpm | ≥ 9 (preferencial sobre npm/yarn por velocidade e disk usage) |

### Frameworks

| Framework | Quando usar |
|-----------|-------------|
| **NestJS** | Projetos médios/grandes com necessidade de DI, módulos, decorators, integrações enterprise |
| **Express** | APIs simples, microserviços lightweight, prototipagem rápida |
| **Fastify** | Performance acima da média sem opinião arquitetural forte |

### Bibliotecas padrão

| Necessidade | Biblioteca |
|-------------|-----------|
| ORM | Prisma (preferencial) ou TypeORM |
| Validação | Zod (preferencial) ou class-validator |
| HTTP client | undici (nativo Node ≥ 18) ou axios |
| Logging | pino (estruturado, fast) |
| Testing | Vitest (preferencial) ou Jest |
| Tracing/Metrics | OpenTelemetry SDK |
| Auth | passport.js (estratégias) ou implementação própria com JOSE para JWT |
| Migrations | Prisma Migrate ou node-pg-migrate |
| Queue/Jobs | BullMQ (Redis) |
| Cache | ioredis |

---

## Tooling obrigatório

| Tool | Propósito |
|------|-----------|
| **ESLint** | Linter (config: `@typescript-eslint/strict` + `eslint-plugin-import`) |
| **Prettier** | Formatter |
| **TypeScript** | Type check (`tsc --noEmit` em CI) |
| **Vitest** ou **Jest** | Test runner |
| **husky + lint-staged** | Pre-commit hooks |
| **commitlint** | Convenção de commits (Conventional Commits) |

### Configuração de TypeScript (tsconfig.json mínimo)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  }
}
```

---

## Layout do projeto (Hexagonal)

```
src/
├── domain/                      # núcleo — sem deps externas
│   ├── entities/                # entidades + value objects
│   ├── ports/                   # interfaces (repositories, gateways)
│   └── services/                # serviços de domínio (sem orquestração)
│
├── application/                 # orquestração de domínio
│   └── use-cases/               # cada use case = uma operação de negócio
│
├── adapters/
│   ├── inbound/                 # entrada
│   │   ├── http/                # controllers, routes, middlewares
│   │   ├── messaging/           # consumers (RabbitMQ, Kafka)
│   │   └── cli/                 # comandos CLI
│   │
│   └── outbound/                # saída
│       ├── persistence/         # repositórios (Prisma, etc.)
│       ├── http-clients/        # clients para APIs externas
│       └── messaging/           # producers
│
├── infrastructure/              # cross-cutting
│   ├── config/                  # env, secrets
│   ├── logging/                 # logger setup
│   ├── observability/           # tracing, metrics
│   └── di/                      # composição de dependências
│
└── main.ts                      # bootstrap
```

### NestJS

Em NestJS, mapear:
- `domain/` → `src/<bounded-context>/domain/`
- `application/` → use cases como `*.use-case.ts`
- `adapters/inbound/http/` → `*.controller.ts` + `*.module.ts`
- `adapters/outbound/persistence/` → `*.repository.ts` (impl) + token de DI

### Express

Sem DI nativo — usar **awilix** ou **tsyringe** para inversão de dependência.

---

## Convenções de código

### Naming

- **camelCase** para variáveis, funções, métodos
- **PascalCase** para classes, types, interfaces, enums
- **UPPER_SNAKE_CASE** para constantes globais
- **kebab-case** para nomes de arquivo (ex: `user-repository.ts`)
- **Sem prefix `I`** em interfaces (`UserRepository`, não `IUserRepository`)

### Imports

```typescript
// ordem: built-in → externo → interno (paths absolutos) → relativo
import { readFile } from 'node:fs/promises';
import { z } from 'zod';
import { UserRepository } from '@domain/ports/user-repository';
import { logger } from '../infrastructure/logger';
```

### Async/await

- **Sempre** preferir `async/await` sobre `.then()`
- Não bloquear event loop com operações síncronas pesadas
- Usar `Promise.all()` para paralelismo, `Promise.allSettled()` quando falhas parciais são aceitas
- **Nunca** misturar callbacks com promises sem `util.promisify()`

### Error handling

- Lançar erros tipados (subclasses de `Error`) com mensagens claras
- Errors de domínio: `DomainError`, `ValidationError`, `NotFoundError`, `UnauthorizedError`
- Adapter inbound (controller) traduz erro de domínio em HTTP status apropriado
- **Nunca** retornar `null` quando o esperado é uma entidade — lançar `NotFoundError`
- Usar `Result<T, E>` pattern (ex: `neverthrow`) em funções com falha previsível

### Validação

- Zod para schemas de entrada (HTTP body, query, params)
- Validação no adapter inbound, antes de chegar ao use case
- Nunca confiar em dados externos no domain

```typescript
// adapters/inbound/http/users.controller.ts
const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(255),
});

router.post('/users', async (req, res) => {
  const data = createUserSchema.parse(req.body);
  const result = await createUserUseCase.execute(data);
  res.status(201).json(result);
});
```

---

## Padrão de testes

### Pirâmide

| Camada | Ferramenta | Cobertura por modo |
|--------|-----------|--------------------|
| Unit (domain + use cases) | Vitest | MVP ≥60% críticas / Production ≥95% críticas |
| Integration (adapters) | Vitest + Testcontainers | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | Vitest + supertest | Happy paths críticos |
| Load/Performance | k6 | Production: NFRs do PRD |

### Estrutura

- `*.spec.ts` colocado **ao lado** do arquivo testado
- Nunca usar dados de produção
- Testcontainers para PostgreSQL/Redis em testes de integração
- Mocks apenas para serviços externos (HTTP); banco real via Testcontainers

### TDD obrigatório

- QA define cenários antes da implementação
- Implementação só passa quando testes verdes

---

## Migrations

### Prisma Migrate

```bash
# criar migration
pnpm prisma migrate dev --name add_users_table

# aplicar em produção
pnpm prisma migrate deploy
```

### Regras (ver `agents/backend-engineer.md` → Migrations)

- Toda migration **reversível** (down testado)
- **Expand-contract** em mudanças breaking (Production)
- Backup confirmado antes de migration destrutiva
- Migrations testadas em staging com volume realista
- Migration > 5min → janela de manutenção ou background job

---

## Logging e Observabilidade

### Logger estruturado (pino)

```typescript
import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
  redact: ['req.headers.authorization', '*.password', '*.token'],
});
```

### Regras

- **Sempre** logar com contexto estruturado (não string concatenada)
- Correlation ID em toda requisição (middleware)
- Nunca logar dados sensíveis (PII, tokens, senhas) — use `redact`
- Tracing via OpenTelemetry em Production Mode
- Métricas via prom-client expostas em `/metrics`

---

## Performance

- **Streams** para arquivos grandes (não carregar em memória)
- **Connection pooling** em DB (Prisma faz por padrão)
- Cache via Redis para queries pesadas
- **Cluster mode** ou múltiplas instâncias atrás de load balancer (Node single-threaded)
- Worker threads para CPU-bound (Worker Threads API)
- Profiling: `clinic.js` (doctor, flame, bubbleprof)

---

## Segurança específica

- `helmet` para headers HTTP de segurança
- Rate limiting via `express-rate-limit` ou `@fastify/rate-limit`
- CORS configurado explicitamente (nunca `*` em produção com auth)
- JWT via JOSE (não jsonwebtoken — abandonado)
- Bcrypt para senhas (cost ≥ 12) ou Argon2id (preferencial)
- `process.env` validado no boot via Zod (fail-fast)
- npm audit / `pnpm audit` na pipeline (SAST)
- Snyk ou Dependabot para CVEs em deps

---

## Comandos padrão

```bash
# install
pnpm install

# dev
pnpm dev                                    # ts-node-dev ou tsx watch

# build
pnpm build                                  # tsc

# test
pnpm test                                   # vitest run
pnpm test:watch                             # vitest
pnpm test:cov                               # vitest run --coverage

# lint + format
pnpm lint                                   # eslint . --max-warnings=0
pnpm format                                 # prettier --write .
pnpm typecheck                              # tsc --noEmit

# migrations
pnpm prisma migrate dev
pnpm prisma migrate deploy

# CI (tudo de uma vez)
pnpm typecheck && pnpm lint && pnpm test:cov && pnpm build
```

---

## Anti-patterns (bloquear)

- `any` sem justificativa documentada
- Mistura de callback e promise sem util.promisify
- Lógica de negócio em controller (adapter inbound)
- Importação de Prisma/ORM no domain
- `console.log` em código de produção (use logger)
- `process.exit()` espalhado (deixar para boot/shutdown)
- Sync I/O em request handlers (`readFileSync`, etc.)
- Repos retornando ORM models cru (mapear para entidades de domínio)
- Validação de input só no service (sempre no adapter inbound também)
- Magic numbers / strings — extrair para constantes
- Try/catch que apenas logam e seguem (silencia bugs)

---

## Referências

- TypeScript: <https://www.typescriptlang.org/docs/>
- NestJS: <https://docs.nestjs.com/>
- Prisma: <https://www.prisma.io/docs>
- Pino: <https://getpino.io/>
- OpenTelemetry Node: <https://opentelemetry.io/docs/instrumentation/js/>
