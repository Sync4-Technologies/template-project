# Stack Convention — Vue + Nuxt

> Supported frameworks: **Nuxt 3** (preferred — full-stack SSR/SSG) or **Vue 3 + Vite** (SPA).

---

## When to use this stack

Choose Vue (with Nuxt) when:

- **Smoother learning curve** than React — fast onboarding
- **Less boilerplate** — Composition API + SFC (Single File Component)
- **Team new to modern frontend** — Vue has excellent documentation
- **Fast prototyping** — `<script setup>` is enormously productive
- **Modern full-stack app** — Nuxt 3 + Nitro server
- **SEO matters** — Nuxt SSR/SSG
- **Consolidated stack (template-style)** — Vuetify, Quasar, Element Plus
- **Team prefers explicit reactivity** (refs, computed)
- **Smaller complexity surface** compared to React Server Components

## When NOT to use

- **Need a massive developer pool** — React has more devs in market
- **React-only ecosystem critical** — some specific libs only exist in React
- **Microfrontend embedded in React** — additional runtime overhead
- **Team already experienced in React** — no reason to switch

---

## Versions and dependencies

| Item | Minimum version |
|------|-----------------|
| Node.js | ≥ 20 LTS |
| TypeScript | ≥ 5.4 |
| Vue | ≥ 3.4 |
| Nuxt | ≥ 3.13 |
| pnpm | ≥ 9 |

### Standard libraries

| Need | Library |
|------|---------|
| UI library | Nuxt UI (preferred), Vuetify, Element Plus, PrimeVue |
| Styling | Tailwind CSS (preferred via @nuxtjs/tailwindcss) |
| State | Pinia (official) |
| Server state | TanStack Query Vue or `useFetch`/`useAsyncData` (Nuxt) |
| Forms | VeeValidate + Zod or FormKit |
| Validation | Zod |
| HTTP | $fetch native (Nuxt — ofetch) |
| Testing | Vitest + Vue Test Utils |
| E2E | Playwright |
| i18n | @nuxtjs/i18n |
| Auth | @sidebase/nuxt-auth |
| Icons | @nuxt/icon |
| Date | date-fns or Day.js |
| Feature flags | LaunchDarkly Vue SDK or Unleash Proxy |

---

## Required tooling

| Tool | Purpose |
|------|---------|
| **ESLint** | Linter (`@nuxt/eslint`) |
| **Prettier** | Formatter |
| **TypeScript** | Type check (`vue-tsc --noEmit`) |
| **Vitest** + **Vue Test Utils** | Test runner |
| **Playwright** | E2E |
| **Histoire** or **Storybook** | Visual documentation |
| **lighthouse-ci** | Performance budget |

---

## Project layout (Nuxt 3)

```
.
├── app.vue                          # root
├── error.vue                        # error page
│
├── pages/                           # file-based routing
│   ├── index.vue
│   ├── dashboard/
│   │   ├── index.vue
│   │   └── [id].vue
│   └── settings.vue
│
├── layouts/                         # layouts
│   ├── default.vue
│   └── auth.vue
│
├── components/                      # Atomic Design
│   ├── atoms/
│   ├── molecules/
│   ├── organisms/
│   └── ui/
│
├── features/                        # vertical slices
│   ├── auth/
│   │   ├── components/
│   │   ├── composables/             # use* hooks
│   │   ├── api/
│   │   └── schemas/
│   └── orders/
│
├── composables/                     # shared composables
├── stores/                          # Pinia stores
├── server/                          # Nitro server
│   ├── api/                         # /api/* routes
│   └── middleware/
├── middleware/                      # client middleware (auth, etc.)
├── plugins/                         # Nuxt plugins
├── public/                          # static assets
├── assets/                          # processed assets
├── i18n/                            # locales
└── nuxt.config.ts
```

### Vite SPA (without Nuxt)

```
src/
├── main.ts
├── App.vue
├── router/
├── views/                           # routes
├── components/                      # Atomic Design
├── composables/
├── stores/                          # Pinia
└── assets/
```

---

## Code conventions

### Naming

- **PascalCase** for components (`UserCard.vue`)
- **camelCase** for composables (`useAuth`)
- **camelCase** for props, methods
- **kebab-case** when using component in template (`<user-card />`) **OR** PascalCase (`<UserCard />`) — Vue accepts both; standardize per project
- **PascalCase** for types/interfaces

### Composition API + `<script setup>` (preferred)

```vue
<script setup lang="ts">
import { ref, computed } from 'vue';
import type { User } from '~/types';

interface Props {
  user: User;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  edit: [id: string];
}>();

const fullName = computed(() => `${props.user.firstName} ${props.user.lastName}`);

function handleEdit() {
  emit('edit', props.user.id);
}
</script>

<template>
  <article class="rounded-md border p-4">
    <h2 class="text-lg font-semibold">{{ fullName }}</h2>
    <p class="text-sm text-muted-foreground">{{ user.email }}</p>
    <UButton @click="handleEdit">Edit</UButton>
  </article>
</template>
```

### Atomic Design

| Layer | Example |
|-------|---------|
| **Atoms** | UButton, UInput, UIcon |
| **Molecules** | FormField, SearchBox |
| **Organisms** | Header, UserCard, OrderTable |
| **Templates** | layouts/default.vue, layouts/auth.vue |
| **Pages** | pages/*.vue |

### Composables (React hooks equivalent)

```typescript
// composables/useAuth.ts
export function useAuth() {
  const user = useState<User | null>('auth.user', () => null);

  async function login(email: string, password: string) {
    const result = await $fetch<User>('/api/auth/login', {
      method: 'POST',
      body: { email, password }
    });
    user.value = result;
  }

  return { user, login };
}
```

### State management (Pinia)

```typescript
// stores/auth.ts
import { defineStore } from 'pinia';

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null);
  const isAuthenticated = computed(() => !!user.value);

  function setUser(u: User | null) {
    user.value = u;
  }

  return { user, isAuthenticated, setUser };
});
```

### Data fetching (Nuxt)

```typescript
// pages/users/[id].vue
<script setup lang="ts">
const route = useRoute();
const { data: user, error, pending } = await useFetch(`/api/users/${route.params.id}`);
</script>
```

- `useFetch` — SSR + automatic cache
- `useAsyncData` — manual fetch control
- `$fetch` — direct call (non-cached, avoid in template)

### Forms (VeeValidate + Zod)

```vue
<script setup lang="ts">
import { useForm } from 'vee-validate';
import { toTypedSchema } from '@vee-validate/zod';
import { z } from 'zod';

const schema = toTypedSchema(z.object({
  email: z.string().email(),
  name: z.string().min(1).max(255),
}));

const { handleSubmit, errors, defineField } = useForm({ validationSchema: schema });
const [email, emailAttrs] = defineField('email');

const onSubmit = handleSubmit(async (values) => {
  // ...
});
</script>
```

### Error handling

- Error Boundaries via `<NuxtErrorBoundary>` (Nuxt 3)
- `error.vue` for page errors
- `useFetch` returns `error` ref
- Toasts via Nuxt UI or vue-sonner

---

## Testing standards

### Pyramid

| Layer | Tool | Coverage by mode |
|-------|------|------------------|
| Unit (composables, utils) | Vitest | MVP ≥60% critical / Production ≥80% |
| Component | Vue Test Utils + Testing Library Vue | MVP ≥50% / Production ≥80% |
| Integration | Vitest + MSW | Production ≥70% |
| E2E | Playwright | Critical happy paths |
| Accessibility | axe-core via Playwright | Required in critical features |

### Testing Library Vue (preferred over Vue Test Utils direct)

```typescript
import { render, screen } from '@testing-library/vue';
import UserCard from '~/components/UserCard.vue';

it('renders user info', () => {
  render(UserCard, { props: { user: { name: 'Alice', email: 'a@b.com' } }});
  expect(screen.getByText('Alice')).toBeInTheDocument();
});
```

---

## Accessibility (WCAG 2.1 AA — required)

See conventions in `.claude/squad/template/docs/stack-conventions/frontend/react.md` (same WCAG rules apply).

- Labels on all interactive elements
- Minimum contrast 4.5:1
- Keyboard navigation
- Visible focus
- ARIA when semantic HTML isn't sufficient
- Screen reader tested in critical features
- Automatic validation via axe-core

---

## Internationalization (@nuxtjs/i18n)

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  modules: ['@nuxtjs/i18n'],
  i18n: {
    locales: [
      { code: 'pt-BR', file: 'pt-BR.json' },
      { code: 'en-US', file: 'en-US.json' }
    ],
    defaultLocale: 'pt-BR',
  }
});
```

```vue
<script setup lang="ts">
const { t } = useI18n();
</script>

<template>
  <p>{{ t('greeting', { name: 'Alice' }) }}</p>
</template>
```

### Rules

- **No hardcoded strings**
- Languages declared in PRD
- RTL in global projects
- Native formatters for dates/numbers

---

## Design Tokens

- **Tailwind config** centralized
- **Nuxt UI** based on design tokens — easy theming
- In multi-platform projects (Web + Mobile), tokens come from a single source (Style Dictionary)
- Nothing hardcoded in components

---

## Performance

### Web Vitals (Production Mode)

Same React targets (LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1).

### Nuxt-specific techniques

- **Server Components** (Nuxt 3.9+) — `<MyComponent server-only />`
- **Lazy components** — `<LazyMyHeavy />` (auto-import + code split)
- **Image optimization** — `<NuxtImg>` (lazy, responsive, modern formats)
- **Payload extraction** in SSG
- **Hybrid rendering** — `routeRules` for mix of SSR/SSG/CSR/ISR
- **`useState` in SSR** — preserves state between server/client
- Bundle analysis: `nuxt analyze`

---

## Feature Flags

See `.claude/squad/template/memory/ADR/ADR-003-feature-flags.md` and `.claude/squad/template/agents/frontend-engineer.md`.

Same React rules:
- Flag check at route or organism level (not in atoms)
- Local cache + fallback
- Provider SDK

---

## Stack-specific security

- **CSP** via `nuxt-security` module
- **HTTPS** required
- **httpOnly cookies** for tokens (not localStorage)
- **CSRF** mitigated by SameSite=Lax + Origin verification
- `v-html` only with trusted input (Vue doesn't sanitize by default — use DOMPurify)
- Public variables: `runtimeConfig.public` in Nuxt — don't leak secrets
- Server routes (Nuxt): validate input with Zod
- Headers via `nuxt-security` or middleware

---

## Standard commands

```bash
# install
pnpm install

# dev
pnpm dev

# build
pnpm build
pnpm preview                                 # local build preview

# generate (SSG)
pnpm generate

# test
pnpm test                                    # vitest
pnpm test:e2e                                # playwright

# lint + format
pnpm lint
pnpm format
pnpm typecheck                               # vue-tsc --noEmit

# bundle analysis
pnpm analyze                                 # nuxt analyze

# CI
pnpm typecheck && pnpm lint && pnpm test && pnpm build && pnpm test:e2e
```

---

## Anti-patterns (block)

- Options API in new code (use Composition API)
- Business logic in template
- Mutating props (Vue warns, but avoid)
- `v-html` with non-sanitized input
- Inline styles that should be tokens
- Hardcoded text
- `useFetch` in watcher (race conditions) — use separate `watch`
- Pinia store for purely local state
- Composables returning non-reactive object (loses reactivity)
- `ref` vs `reactive` mismatched (rule: prefer `ref` for consistency)
- `v-for` without `:key`
- Giant components (> 200 lines)
- Mixing Options API `<script>` with `<script setup>` in same file
- Accessibility ignored

---

## References

- Vue 3: <https://vuejs.org/guide/introduction.html>
- Nuxt 3: <https://nuxt.com/docs>
- Pinia: <https://pinia.vuejs.org/>
- VueUse: <https://vueuse.org/> (ready-made composables)
- Tailwind CSS: <https://tailwindcss.com/docs>
- Nuxt UI: <https://ui.nuxt.com/>
- Vue Test Utils: <https://test-utils.vuejs.org/>
- Vue Style Guide: <https://vuejs.org/style-guide/>
