# Stack Convention — Node.js (TypeScript)

> Supported frameworks: **NestJS** (preferred for large projects) or **Express** (simple APIs). Always TypeScript.

---

## When to use this stack

Choose Node.js + TypeScript when:

- **I/O-intensive** — high request volume, real-time (WebSockets, SSE), streaming
- **Type sharing with frontend** — monorepo with React/Next.js consuming backend types
- **JS ecosystem on the team** — developers already fluent in JS/TS
- **Real-time** — chat, push notifications, live dashboards
- **API-orchestrated microservices** — lightweight, fast startup
- **GraphQL APIs** — Apollo Server is mature
- **Edge functions** — Vercel/Cloudflare Workers compatibility
- **Backend-for-Frontend (BFF)** — aggregation for mobile/web

## When NOT to use

- **Heavy CPU-bound work** (image/video processing, ML inference) — prefer Python/Go
- **Intensive numerical computation** — no native SIMD, GC pauses
- **AI/ML pipelines** — Python ecosystem is dramatically superior
- **Hard real-time requirements** — unpredictable GC
- **Teams without async experience** — misused async/await becomes a nightmare

---

## Versions and dependencies

| Item | Minimum version |
|------|-----------------|
| Node.js | ≥ 20 LTS (prefer 22 LTS when available) |
| TypeScript | ≥ 5.4 |
| pnpm | ≥ 9 (preferred over npm/yaml for speed and disk usage) |

### Frameworks

| Framework | When to use |
|-----------|-------------|
| **NestJS** | Medium/large projects needing DI, modules, decorators, enterprise integrations |
| **Express** | Simple APIs, lightweight microservices, fast prototyping |
| **Fastify** | Above-average performance without strong architectural opinion |

### Standard libraries

| Need | Library |
|------|---------|
| ORM | Prisma (preferred) or TypeORM |
| Validation | Zod (preferred) or class-validator |
| HTTP client | undici (Node ≥ 18 native) or axios |
| Logging | pino (structured, fast) |
| Testing | Vitest (preferred) or Jest |
| Tracing/Metrics | OpenTelemetry SDK |
| Auth | passport.js (strategies) or in-house with JOSE for JWT |
| Migrations | Prisma Migrate or node-pg-migrate |
| Queue/Jobs | BullMQ (Redis) |
| Cache | ioredis |

---

## Required tooling

| Tool | Purpose |
|------|---------|
| **ESLint** | Linter (config: `@typescript-eslint/strict` + `eslint-plugin-import`) |
| **Prettier** | Formatter |
| **TypeScript** | Type check (`tsc --noEmit` in CI) |
| **Vitest** or **Jest** | Test runner |
| **husky + lint-staged** | Pre-commit hooks |
| **commitlint** | Commit conventions (Conventional Commits) |

### Minimum TypeScript config (tsconfig.json)

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

## Project layout (Hexagonal)

```
src/
├── domain/                      # core — no external deps
│   ├── entities/                # entities + value objects
│   ├── ports/                   # interfaces (repositories, gateways)
│   └── services/                # domain services (no orchestration)
│
├── application/                 # domain orchestration
│   └── use-cases/               # each use case = one business operation
│
├── adapters/
│   ├── inbound/                 # entry
│   │   ├── http/                # controllers, routes, middlewares
│   │   ├── messaging/           # consumers (RabbitMQ, Kafka)
│   │   └── cli/                 # CLI commands
│   │
│   └── outbound/                # exit
│       ├── persistence/         # repositories (Prisma, etc.)
│       ├── http-clients/        # external API clients
│       └── messaging/           # producers
│
├── infrastructure/              # cross-cutting
│   ├── config/                  # env, secrets
│   ├── logging/                 # logger setup
│   ├── observability/           # tracing, metrics
│   └── di/                      # dependency composition
│
└── main.ts                      # bootstrap
```

### NestJS

In NestJS, map:
- `domain/` → `src/<bounded-context>/domain/`
- `application/` → use cases as `*.use-case.ts`
- `adapters/inbound/http/` → `*.controller.ts` + `*.module.ts`
- `adapters/outbound/persistence/` → `*.repository.ts` (impl) + DI token

### Express

No native DI — use **awilix** or **tsyringe** for dependency inversion.

---

## Code conventions

### Naming

- **camelCase** for variables, functions, methods
- **PascalCase** for classes, types, interfaces, enums
- **UPPER_SNAKE_CASE** for global constants
- **kebab-case** for filenames (e.g., `user-repository.ts`)
- **No `I` prefix** on interfaces (`UserRepository`, not `IUserRepository`)

### Imports

```typescript
// order: built-in → external → internal (absolute paths) → relative
import { readFile } from 'node:fs/promises';
import { z } from 'zod';
import { UserRepository } from '@domain/ports/user-repository';
import { logger } from '../infrastructure/logger';
```

### Async/await

- **Always** prefer `async/await` over `.then()`
- Don't block the event loop with heavy synchronous operations
- Use `Promise.all()` for parallelism, `Promise.allSettled()` when partial failures are acceptable
- **Never** mix callbacks with promises without `util.promisify()`

### Error handling

- Throw typed errors (subclasses of `Error`) with clear messages
- Domain errors: `DomainError`, `ValidationError`, `NotFoundError`, `UnauthorizedError`
- Inbound adapter (controller) translates domain errors to appropriate HTTP status
- **Never** return `null` when an entity is expected — throw `NotFoundError`
- Use `Result<T, E>` pattern (e.g., `neverthrow`) in functions with predictable failure

### Validation

- Zod for input schemas (HTTP body, query, params)
- Validation in the inbound adapter, before reaching the use case
- Never trust external data in the domain

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

## Testing standards

### Pyramid

| Layer | Tool | Coverage by mode |
|-------|------|------------------|
| Unit (domain + use cases) | Vitest | MVP ≥60% critical / Production ≥95% critical |
| Integration (adapters) | Vitest + Testcontainers | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | Vitest + supertest | Critical happy paths |
| Load/Performance | k6 | Production: PRD NFRs |

### Structure

- `*.spec.ts` colocated **next to** the file under test
- Never use production data
- Testcontainers for PostgreSQL/Redis in integration tests
- Mocks only for external services (HTTP); real database via Testcontainers

### TDD required

- QA defines scenarios before implementation
- Implementation only passes when tests are green

---

## Migrations

### Prisma Migrate

```bash
# create migration
pnpm prisma migrate dev --name add_users_table

# apply in production
pnpm prisma migrate deploy
```

### Rules (see `${CLAUDE_PLUGIN_ROOT}/agents/backend-engineer.md` → Migrations)

- Every migration **reversible** (down tested)
- **Expand-contract** for breaking changes (Production)
- Backup confirmed before destructive migration
- Migrations tested on staging with realistic volume
- Migration > 5min → maintenance window or background job

---

## Logging and Observability

### Structured logger (pino)

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

### Rules

- **Always** log with structured context (not concatenated strings)
- Correlation ID on every request (middleware)
- Never log sensitive data (PII, tokens, passwords) — use `redact`
- OpenTelemetry tracing in Production Mode
- Metrics via prom-client exposed at `/metrics`

---

## Performance

- **Streams** for large files (don't load into memory)
- **Connection pooling** in DB (Prisma does this by default)
- Cache via Redis for heavy queries
- **Cluster mode** or multiple instances behind a load balancer (Node is single-threaded)
- Worker threads for CPU-bound work (Worker Threads API)
- Profiling: `clinic.js` (doctor, flame, bubbleprof)

---

## Stack-specific security

- `helmet` for HTTP security headers
- Rate limiting via `express-rate-limit` or `@fastify/rate-limit`
- CORS configured explicitly (never `*` in production with auth)
- JWT via JOSE (not jsonwebtoken — abandoned)
- Bcrypt for passwords (cost ≥ 12) or Argon2id (preferred)
- `process.env` validated at boot via Zod (fail-fast)
- npm audit / `pnpm audit` in pipeline (SAST)
- Snyk or Dependabot for dependency CVEs

---

## Deployment & runtime gotchas (learned in production)

### NODE_ENV semantics matrix

`NODE_ENV` has multiple independent effects (config validation strictness, logger transports, dependency installation). Wrong combination = crash. Standard matrix:

| Environment | NODE_ENV | Why |
|---|---|---|
| Local dev | `development` | dev-only transports (pino-pretty) available; relaxed config checks |
| PaaS staging/develop | `staging` | strict config checks with stubs; NO dev-only deps in prod bundle (`development` here crashes on missing devDeps) |
| PaaS production | `production` | strict checks with real values; devDeps pruned |
| CI tests | `test` | separate Zod enum value |

Document each effect explicitly in `config.schema.ts` (Zod enum comment).

### NestJS specifics

- **Dev server:** use SWC builder via `nest-cli.json` (`decorators: true`, `decoratorMetadata: true`) from day one. `tsx`/plain esbuild silently drops `emitDecoratorMetadata` → DI receives `undefined` → boot crash.
- **Never run blind `eslint --fix` on services/repositories.** `consistent-type-imports` converts DI-injected classes to `import { type X }`; with `emitDecoratorMetadata` the import is elided → `design:paramtypes` loses the class → runtime boot crash (tsc does NOT catch this). Injected classes = value imports; only pure types/DTOs/enums = `type` imports.
- **Exception filter must preserve known error status** — 4xx (incl. 429 from rate-limiters returning plain objects) must never become generic 500.

### Monorepo / lockfile

- Touched any `package.json` → commit the ROOT `pnpm-lock.yaml` in the same commit. `git add apps/` misses the root lock → `--frozen-lockfile` (CI/Docker default) fails for the whole monorepo.
- Dockerfiles build internal packages by GLOB (`pnpm --filter "./packages/*" build`), never an explicit list.

### Outbound HTTP

- Always send `User-Agent` + `Accept` on outbound `fetch` — CDN/WAF (e.g. Cloudflare) blocks UA-less datacenter requests with 403/429 that look like "service down".
- Log the real upstream status; `!res.ok` ≠ "unavailable".
- Truncate every externally-sourced field to its column limit before persisting (avoids P2000-class runtime errors on real data).

---

## Standard commands

```bash
# install
pnpm install

# dev
pnpm dev                                    # ts-node-dev or tsx watch

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

# CI (everything at once)
pnpm typecheck && pnpm lint && pnpm test:cov && pnpm build
```

---

## Anti-patterns (block)

- `any` without documented justification
- Mixing callbacks and promises without util.promisify
- Business logic in controller (inbound adapter)
- Importing Prisma/ORM in the domain
- `console.log` in production code (use the logger)
- `process.exit()` scattered (reserve for boot/shutdown)
- Sync I/O in request handlers (`readFileSync`, etc.)
- Repos returning raw ORM models (map to domain entities)
- Input validation only in the service (always also in the inbound adapter)
- Magic numbers / strings — extract to constants
- Try/catch that only logs and continues (silences bugs)

---

## References

- TypeScript: <https://www.typescriptlang.org/docs/>
- NestJS: <https://docs.nestjs.com/>
- Prisma: <https://www.prisma.io/docs>
- Pino: <https://getpino.io/>
- OpenTelemetry Node: <https://opentelemetry.io/docs/instrumentation/js/>
