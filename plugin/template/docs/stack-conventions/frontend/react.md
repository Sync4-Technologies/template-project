# Stack Convention — React + Next.js

> Supported frameworks: **Next.js** (SSR/SSG, full-stack app, SEO) or **React + Vite** (internal dashboard SPA).

---

## When to use this stack

Choose React (with Next.js) when:

- **SEO matters** — landing pages, blog, e-commerce, marketing site (Next.js SSR/SSG)
- **Complex apps with many screens** — most mature library ecosystem
- **Team already fluent in React** — vast developer pool
- **Type sharing with Node.js backend** — TypeScript end-to-end
- **Server Components + Server Actions** (Next.js App Router) — modern full-stack
- **Hybrid app** with some SSR pages and others SPA
- **Need rich ecosystem** — UI libs (shadcn/ui, Radix, MUI, Mantine), forms (React Hook Form), tables (TanStack Table)
- **Mature i18n and a11y** — react-i18next, react-aria

Choose React + Vite (without Next.js) when:

- **Internal dashboard / Admin panel** — no SSR/SEO needed
- **Simple SPA** with auth behind login
- **Ultra-fast dev build**
- **Embedded in another app** (microfrontend)

## When NOT to use

- **Small team without React experience** — learning curve is real
- **Purely static marketing site without interactivity** — Astro or plain HTML are simpler
- **Simple-logic app with tight deadline** — Vue/Nuxt usually has less boilerplate

---

## Versions and dependencies

| Item | Minimum version |
|------|-----------------|
| Node.js | ≥ 20 LTS |
| TypeScript | ≥ 5.4 |
| React | ≥ 18.3 (prefer 19 when stable) |
| Next.js | ≥ 15 (App Router) |
| pnpm | ≥ 9 |

### Standard libraries

| Need | Library |
|------|---------|
| UI library | shadcn/ui (preferred) or Radix UI primitives |
| Styling | Tailwind CSS (preferred) or CSS Modules |
| State management | Zustand (simple) or Redux Toolkit (complex) |
| Server state / data fetching | TanStack Query (preferred) or SWR |
| Forms | React Hook Form + Zod resolver |
| Validation | Zod |
| HTTP client | native fetch + TS wrapper, or ky (preferred over axios) |
| Testing | Vitest (preferred) or Jest + React Testing Library |
| E2E | Playwright (preferred) or Cypress |
| i18n | next-intl (Next.js) or react-i18next |
| Auth | NextAuth.js / Auth.js or Clerk |
| Tables | TanStack Table |
| Date | date-fns or Day.js (not Moment.js — abandoned) |
| Animations | Framer Motion |
| Icons | lucide-react |
| Feature flags | LaunchDarkly SDK or Unleash Proxy SDK |
| Analytics | Posthog or Mixpanel |
| Observability | Sentry (errors) + Vercel Analytics |

---

## Required tooling

| Tool | Purpose |
|------|---------|
| **ESLint** | Linter (`eslint-config-next` + `@typescript-eslint/strict`) |
| **Prettier** | Formatter |
| **TypeScript** | Type check (`tsc --noEmit`) |
| **Vitest** + **React Testing Library** | Test runner |
| **Playwright** | E2E |
| **Storybook** | Visual component documentation |
| **lighthouse-ci** | Performance budget in pipeline |
| **bundle-analyzer** | Bundle size analysis |
| **husky + lint-staged** | Pre-commit hooks |
| **commitlint** | Commit conventions |

---

## Project layout

### Next.js App Router (preferred)

```
src/
├── app/                              # App Router (routes)
│   ├── (marketing)/                  # route group
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── (app)/                        # authenticated area
│   │   ├── layout.tsx
│   │   ├── dashboard/
│   │   └── settings/
│   ├── api/                          # route handlers
│   ├── layout.tsx                    # root layout
│   └── globals.css
│
├── components/                       # Atomic Design
│   ├── atoms/
│   ├── molecules/
│   ├── organisms/
│   ├── templates/
│   └── ui/                           # shadcn/ui generated
│
├── features/                         # feature-based (vertical slices)
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── api/                      # data fetching
│   │   ├── schemas/                  # Zod
│   │   └── types/
│   └── orders/
│       └── ...
│
├── hooks/                            # shared hooks
├── lib/                              # utilities, helpers
│   ├── api/                          # HTTP client
│   ├── auth/
│   └── utils.ts
├── providers/                        # context providers (Query, Theme, etc.)
├── styles/                           # design tokens, globals
├── i18n/                             # locales
└── types/                            # shared types
```

### Vite SPA

```
src/
├── components/                       # Atomic Design
├── features/
├── hooks/
├── lib/
├── pages/                            # routes via React Router
├── providers/
└── main.tsx
```

---

## Code conventions

### Naming

- **PascalCase** for components and component files (`UserCard.tsx`)
- **camelCase** for hooks (`useAuth`), utilities, props
- **kebab-case** for folders (except components — use PascalCase or consistent kebab)
- **PascalCase** for types and interfaces (no `I` prefix)
- **UPPER_SNAKE_CASE** for global constants

### Components

```tsx
// 1 component per file
// component is a function, not a class
// props typed with interface or type

interface UserCardProps {
  user: User;
  onEdit?: (id: string) => void;
}

export function UserCard({ user, onEdit }: UserCardProps) {
  return (
    <article className="rounded-md border p-4">
      <h2 className="text-lg font-semibold">{user.name}</h2>
      <p className="text-sm text-muted-foreground">{user.email}</p>
      {onEdit && (
        <Button onClick={() => onEdit(user.id)}>Edit</Button>
      )}
    </article>
  );
}
```

### Atomic Design

| Layer | Example |
|-------|---------|
| **Atoms** | Button, Input, Label, Icon |
| **Molecules** | FormField (Label + Input + Error), SearchBox |
| **Organisms** | Header, UserCard, OrderTable |
| **Templates** | DashboardLayout, AuthLayout |
| **Pages** | route components in `app/` |

Business logic **never** in atoms/molecules. Hooks or organisms orchestrate.

### Server vs Client Components (Next.js App Router)

- **Default:** Server Component (no JS on client)
- **`'use client'`** only when there's interactivity, state hooks, or browser APIs
- Avoid marking parent component as client if children can be server

#### Server-only env — hard rules (production incidents behind each one)

- **Any fetch that needs server-only env (secret, internal URL) = Server Action or route handler. NEVER called from a client component.** In the browser, env without `NEXT_PUBLIC_` is silently `undefined` (fail-silent — a `?? 'localhost'` fallback masks it further); secrets are stripped from the bundle → unauthenticated requests. Build, tests (mocked fetch) and lint all stay green; it only breaks in production runtime.
- **A module read by both Server and Client Components must not read server-only env at module top-level.** Split the module explicitly (server lib vs client lib) — "looks universal" is how the bug ships.
- **`NEXT_PUBLIC_*` is BUILD-time:** it must exist as `ARG`+`ENV` in the Dockerfile before `next build` and as a buildArg in the PaaS config. Setting it as a runtime var does nothing to an already-built bundle.
- Code review grep: client component (`'use client'`) importing anything that uses `process.env.*` without `NEXT_PUBLIC_` = **BLOCKER**.

```tsx
// page.tsx — Server Component (default)
export default async function DashboardPage() {
  const data = await fetchData();          // server-side
  return <DashboardClient data={data} />;
}

// DashboardClient.tsx
'use client';
export function DashboardClient({ data }) {
  const [filter, setFilter] = useState('');
  // ...
}
```

### State management

- **Server state:** TanStack Query (cache, revalidation, mutations)
- **Global client state:** Zustand (Redux only in complex cases with time-travel)
- **Local component state:** useState, useReducer
- **URL state:** searchParams (Next.js) or React Router

### Data fetching (Next.js App Router)

```tsx
// Server Component — direct fetch
async function UsersPage() {
  const users = await fetch('https://api.example.com/users', {
    next: { revalidate: 60 }
  }).then(r => r.json());
  return <UserList users={users} />;
}

// Client — TanStack Query
'use client';
function UsersClient() {
  const { data, isPending } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers
  });
}
```

### Forms (React Hook Form + Zod)

```tsx
const schema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(255),
});

type FormData = z.infer<typeof schema>;

function UserForm() {
  const { register, handleSubmit, formState } = useForm<FormData>({
    resolver: zodResolver(schema)
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {formState.errors.email && <ErrorMessage />}
    </form>
  );
}
```

### Error handling

- Error Boundaries for render failures
- `error.tsx` in Next.js routes for loading/server errors
- TanStack Query: `onError` or hook's `error`
- Toasts for feedback (sonner or react-hot-toast)

### Imports

```tsx
// order: react/next → external → absolute internal → relative
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { fetchUsers } from '@/lib/api/users';
import { UserCard } from './UserCard';
```

---

## Testing standards

### Pyramid

| Layer | Tool | Coverage by mode |
|-------|------|------------------|
| Unit (utils, hooks) | Vitest | MVP ≥60% critical / Production ≥80% |
| Component | Vitest + Testing Library | MVP ≥50% / Production ≥80% |
| Integration | Vitest + MSW (mock API) | Production ≥70% |
| E2E | Playwright | Critical happy paths |
| Visual regression | Chromatic or Percy | Production: optional |
| Accessibility | axe-core via Playwright | Required in critical features |

### Structure

- `*.test.tsx` next to the component
- MSW to mock APIs in tests
- Storybook for visual documentation + smoke testing

### Accessibility in tests

```tsx
import { axe } from 'jest-axe';

it('should have no a11y violations', async () => {
  const { container } = render(<UserForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

---

## State management in detail

### Server state (TanStack Query)

- Automatic cache
- Smart revalidation (focus, reconnect, interval)
- Optimistic updates via `onMutate`
- Don't duplicate server state in Zustand/Redux

### Client global state (Zustand)

```tsx
import { create } from 'zustand';

interface AuthStore {
  user: User | null;
  setUser: (user: User | null) => void;
}

export const useAuth = create<AuthStore>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));
```

---

## Accessibility (WCAG 2.1 AA — required)

- Semantic labels on all interactive elements
- Minimum contrast 4.5:1 (normal text), 3:1 (large text)
- Keyboard navigation in all flows
- Visible and ordered focus
- ARIA only when semantic HTML isn't sufficient
- Screen reader tested in critical features
- Don't rely on color alone to convey state
- Forms with `<label>` associated to `<input>`
- `<button>` for actions, `<a>` for navigation

---

## Internationalization (i18n)

### next-intl (App Router)

```tsx
// messages/pt-BR.json
{ "greeting": "Olá, {name}" }

// component
import { useTranslations } from 'next-intl';

export function Greeting({ name }: { name: string }) {
  const t = useTranslations();
  return <p>{t('greeting', { name })}</p>;
}
```

### Rules

- **No hardcoded strings** in components
- Languages declared in PRD (see `${CLAUDE_PLUGIN_ROOT}/template/docs/PRD-template.md`)
- Consider RTL (Arabic, Hebrew) in global projects
- Native formatters: `Intl.DateTimeFormat`, `Intl.NumberFormat`

---

## Aesthetics & motion (anti-slop)

- **Before building any screen, invoke the official Anthropic `frontend-design` skill** (plugin `frontend-design@claude-plugins-official`) with the project aesthetic direction from the PD mini-spec. It forces a committed direction (purpose/tone/constraints/differentiation) instead of the generic default.
- Fallback when the plugin is not installed — hard rule: NEVER default to generic AI aesthetics (overused fonts like Inter/Roboto/system, purple-gradient-on-white schemes, cookie-cutter layouts). Use the project direction from `design-system/README.md`: distinctive typography, cohesive palette, context-specific character.
- **Motion is part of Done**: state transitions animate (skeleton→content fade, not pop); interactive elements give hover/focus/press feedback; durations/easings come from the DS `motion.md` tokens; always respect `prefers-reduced-motion`.
- Variety across proposals comes from propose-then-pick (3-4 directions), not sampling params (`temperature` is rejected on current models).

## Design Tokens

- **Tailwind config** centralized (colors, spacing, typography)
- **shadcn/ui** based on CSS variables — easy theming
- In multi-platform projects (Web + Mobile), tokens come from a single source (Style Dictionary) — Frontend maintains, Mobile validates parity
- Nothing hardcoded in components (colors, sizes)

---

## Performance

### Web Vitals (Production Mode)

| Metric | Target |
|--------|--------|
| LCP | ≤ 2.5s |
| INP | ≤ 200ms |
| CLS | ≤ 0.1 |

### Techniques

- **Image optimization** — `next/image` (lazy, responsive, AVIF/WebP)
- **Font optimization** — `next/font` (no FOIT/FOUT, self-hosted)
- **Code splitting** — `dynamic()` for heavy components
- **Server Components** whenever possible (zero JS shipped)
- **Streaming** with Suspense for slow content
- **Bundle analyzer** — monitor bundle size in pipeline
- **Lighthouse CI** with budget in pipeline
- **Judicious memoization** (`useMemo`, `useCallback`, `memo`) — don't use prophylactically

---

## Feature Flags

See `${CLAUDE_PLUGIN_ROOT}/template/memory/ADR/ADR-003-feature-flags.md` and `${CLAUDE_PLUGIN_ROOT}/agents/frontend-engineer.md`.

- Flag check at the **route** or **organism** level, never in atoms
- Local cache + deterministic fallback
- Loading state while flag loads
- Provider SDK (LaunchDarkly React SDK, Unleash Proxy SDK)

---

## Stack-specific security

- **CSP** (Content Security Policy) configured (`next.config.js` headers)
- **HTTPS** required in production (Next.js + Vercel default)
- **httpOnly cookies** for session tokens (not localStorage)
- **CSRF** mitigated by SameSite=Lax cookies + Origin verification
- Sanitize HTML before `dangerouslySetInnerHTML` (DOMPurify) — prefer not using it
- Public variables: prefix `NEXT_PUBLIC_` (Next.js) — audit so secrets don't leak
- Server Actions: validate input with Zod before processing
- Headers: X-Frame-Options, X-Content-Type-Options, Referrer-Policy

---

## Standard commands

```bash
# install
pnpm install

# dev
pnpm dev                                     # Next.js dev server

# build
pnpm build
pnpm start                                   # production server

# test
pnpm test                                    # vitest
pnpm test:watch
pnpm test:cov

# E2E
pnpm test:e2e                                # playwright

# lint + format
pnpm lint                                    # eslint
pnpm format                                  # prettier
pnpm typecheck                               # tsc --noEmit

# storybook
pnpm storybook
pnpm build-storybook

# bundle analysis
pnpm analyze                                 # @next/bundle-analyzer

# CI
pnpm typecheck && pnpm lint && pnpm test:cov && pnpm build && pnpm test:e2e
```

---

## Anti-patterns (block)

- Business logic in UI component
- Global state for something local (`useState` vs Zustand)
- Server state duplicated in client store
- `any` without justification
- `useEffect` for data fetching (use TanStack Query)
- `any` in props
- Giant components (> 200 lines) — extract
- Inline styles for things that should be tokens
- `dangerouslySetInnerHTML` without sanitization
- Hardcoded text (no i18n)
- Fetch without error/loading handling
- `key={index}` in dynamic lists
- Prophylactic `useMemo`/`useCallback` (overhead)
- Accessibility ignored (no labels, no contrast, no keyboard nav)
- Bloated bundle (importing entire lib instead of specific functions)

---

## References

- React: <https://react.dev/>
- Next.js: <https://nextjs.org/docs>
- TanStack Query: <https://tanstack.com/query/latest>
- React Hook Form: <https://react-hook-form.com/>
- Tailwind CSS: <https://tailwindcss.com/docs>
- shadcn/ui: <https://ui.shadcn.com/>
- Testing Library: <https://testing-library.com/docs/react-testing-library/intro>
- Web Vitals: <https://web.dev/vitals/>
