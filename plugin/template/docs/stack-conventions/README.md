# Stack Conventions

> Stack-specific conventions per language/framework. Each document defines **when to use**, **tooling**, **layout**, **idiomatic patterns**, and **commands**.
>
> Architect consults these documents when deciding the project stack. Engineers consult the active stack's document while implementing.
>
> **Note:** these conventions are intentionally written in English to align with upstream documentation, library docs, and community standards. The rest of the squad (agents, CLAUDE.md, skills, ADRs) remains in Portuguese until full migration.

---

## How it works

1. **Architect** decides the stack at project start, using each document's "When to use" criteria
2. Decision is recorded in a project-specific ADR (e.g. `.claude/squad/project/ADR/ADR-NNN-stack-projeto.md`)
3. Active stack is documented in `.claude/squad/project/ARCHITECTURE.md` → "Stack Conventions Doc" section
4. **Engineers** consult the active stack's document when receiving tasks

---

## Supported stacks

### Backend

| Stack | Document | Strengths |
|-------|----------|-----------|
| Node.js + TypeScript | [`backend/nodejs.md`](backend/nodejs.md) | I/O-intensive, real-time, type sharing with frontend |
| Python | [`backend/python.md`](backend/python.md) | AI/ML, data pipelines, simple APIs |
| PHP | [`backend/php.md`](backend/php.md) | CMS, mature e-commerce, Laravel/Symfony ecosystem |
| Java | [`backend/java.md`](backend/java.md) | Enterprise systems, high concurrency, Spring ecosystem |
| Go | [`backend/go.md`](backend/go.md) | Performance-critical, microservices, infra tooling |

### Frontend

| Stack | Document | Strengths |
|-------|----------|-----------|
| React + Next.js | [`frontend/react.md`](frontend/react.md) | SSR/SSG, mature ecosystem, SEO |
| Vue + Nuxt | [`frontend/vue.md`](frontend/vue.md) | Smoother learning curve, less boilerplate, prototyping |

### Mobile

| Stack | Document | Strengths |
|-------|----------|-----------|
| Flutter (Dart) | [`mobile/flutter.md`](mobile/flutter.md) | Native performance, single codebase, consistent UI |
| React Native | [`mobile/react-native.md`](mobile/react-native.md) | React skill reuse, JS ecosystem, flexibility |

---

## Adding a new stack

1. Architect proposes the new stack in an ADR
2. Create the document in `${CLAUDE_PLUGIN_ROOT}/template/docs/stack-conventions/{category}/{stack}.md`
3. Mirror the structure of existing documents (When to use / Tooling / Layout / Patterns / Commands / Anti-patterns)
4. Update the table in this README
5. Submit for Tech Lead review

---

## Standard structure of each document

Every stack convention document must contain:

1. **When to use this stack** — objective criteria
2. **When NOT to use** — exclusion conditions
3. **Versions and dependencies**
4. **Required tooling** (linter, formatter, type checker, test runner)
5. **Project layout** (with Hexagonal/Clean Architecture applied)
6. **Code conventions** (naming, language idioms)
7. **Testing standards** (unit, integration, E2E)
8. **Migrations** (backend) or **State management** (frontend/mobile)
9. **Logging and Observability**
10. **Performance**
11. **Stack-specific security**
12. **Standard commands**
13. **Anti-patterns to avoid**

---

## Authoritative sources

- **General architectural pattern** (Hexagonal, mobile Clean Architecture, Atomic Design): `${CLAUDE_PLUGIN_ROOT}/template/agents/{name}.md` + `${CLAUDE_PLUGIN_ROOT}/template/memory/ADR/ADR-002-arquitetura-hexagonal.md`
- **Language/framework idiomatic conventions:** this directory (stack-conventions)
- **Active project stack:** `.claude/squad/project/ARCHITECTURE.md` + project-specific ADR

In case of conflict between a stack-convention and ADR-002 (Hexagonal): ADR-002 prevails.
