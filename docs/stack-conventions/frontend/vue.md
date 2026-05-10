# Stack Convention — Vue + Nuxt

> Frameworks suportados: **Nuxt 3** (preferencial — SSR/SSG full-stack) ou **Vue 3 + Vite** (SPA).

---

## Quando usar esta stack

Escolher Vue (com Nuxt) quando:

- **Curva de aprendizado mais suave** que React — onboarding rápido
- **Menos boilerplate** — Composition API + SFC (Single File Component)
- **Time iniciante em frontend moderno** — Vue tem documentação excelente
- **Prototipagem rápida** — `<script setup>` é tremendamente produtivo
- **App full-stack moderno** — Nuxt 3 + Nitro server
- **SEO importa** — Nuxt SSR/SSG
- **Stack consolidada (template-style)** — Vuetify, Quasar, Element Plus
- **Time prefere reatividade explícita** (refs, computed)
- **Menor surface de complexidade** comparado a React Server Components

## Quando NÃO usar

- **Pool de devs deve ser massivo** — React tem mais devs no mercado
- **Ecosistema React-only crítico** — algumas libs específicas só existem em React
- **Microfrontend embarcado em React** — sobrecarga de runtime adicional
- **Time já experiente em React** — sem motivo de mudar

---

## Versões e dependências

| Item | Versão mínima |
|------|---------------|
| Node.js | ≥ 20 LTS |
| TypeScript | ≥ 5.4 |
| Vue | ≥ 3.4 |
| Nuxt | ≥ 3.13 |
| pnpm | ≥ 9 |

### Bibliotecas padrão

| Necessidade | Biblioteca |
|-------------|-----------|
| UI library | Nuxt UI (preferencial), Vuetify, Element Plus, PrimeVue |
| Styling | Tailwind CSS (preferencial via @nuxtjs/tailwindcss) |
| State | Pinia (oficial) |
| Server state | TanStack Query Vue ou `useFetch`/`useAsyncData` (Nuxt) |
| Forms | VeeValidate + Zod ou FormKit |
| Validação | Zod |
| HTTP | $fetch nativo (Nuxt — ofetch) |
| Testing | Vitest + Vue Test Utils |
| E2E | Playwright |
| i18n | @nuxtjs/i18n |
| Auth | @sidebase/nuxt-auth |
| Icons | @nuxt/icon |
| Date | date-fns ou Day.js |
| Feature flags | LaunchDarkly Vue SDK ou Unleash Proxy |

---

## Tooling obrigatório

| Tool | Propósito |
|------|-----------|
| **ESLint** | Linter (`@nuxt/eslint`) |
| **Prettier** | Formatter |
| **TypeScript** | Type check (`vue-tsc --noEmit`) |
| **Vitest** + **Vue Test Utils** | Test runner |
| **Playwright** | E2E |
| **Histoire** ou **Storybook** | Documentação visual |
| **lighthouse-ci** | Performance budget |

---

## Layout do projeto (Nuxt 3)

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
├── composables/                     # composables compartilhados
├── stores/                          # Pinia stores
├── server/                          # Nitro server
│   ├── api/                         # routes /api/*
│   └── middleware/
├── middleware/                      # client middleware (auth, etc.)
├── plugins/                         # plugins Nuxt
├── public/                          # assets estáticos
├── assets/                          # assets processados
├── i18n/                            # locales
└── nuxt.config.ts
```

### Vite SPA (sem Nuxt)

```
src/
├── main.ts
├── App.vue
├── router/
├── views/                           # rotas
├── components/                      # Atomic Design
├── composables/
├── stores/                          # Pinia
└── assets/
```

---

## Convenções de código

### Naming

- **PascalCase** para componentes (`UserCard.vue`)
- **camelCase** para composables (`useAuth`)
- **camelCase** para props, métodos
- **kebab-case** ao usar componente em template (`<user-card />`) **OU** PascalCase (`<UserCard />`) — Vue aceita ambos; padronizar projeto-a-projeto
- **PascalCase** para types/interfaces

### Composition API + `<script setup>` (preferencial)

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

| Camada | Exemplo |
|--------|---------|
| **Atoms** | UButton, UInput, UIcon |
| **Molecules** | FormField, SearchBox |
| **Organisms** | Header, UserCard, OrderTable |
| **Templates** | layouts/default.vue, layouts/auth.vue |
| **Pages** | pages/*.vue |

### Composables (equivalente a React hooks)

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

- `useFetch` — SSR + cache automático
- `useAsyncData` — controle manual sobre fetch
- `$fetch` — chamada direta (não-cached, evitar em template)

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
- `error.vue` para erros de página
- `useFetch` retorna `error` ref
- Toasts via Nuxt UI ou vue-sonner

---

## Padrão de testes

### Pirâmide

| Camada | Ferramenta | Cobertura por modo |
|--------|-----------|--------------------|
| Unit (composables, utils) | Vitest | MVP ≥60% críticas / Production ≥80% |
| Component | Vue Test Utils + Testing Library Vue | MVP ≥50% / Production ≥80% |
| Integration | Vitest + MSW | Production ≥70% |
| E2E | Playwright | Happy paths críticos |
| Accessibility | axe-core via Playwright | Obrigatório em features críticas |

### Testing Library Vue (preferencial sobre Vue Test Utils direto)

```typescript
import { render, screen } from '@testing-library/vue';
import UserCard from '~/components/UserCard.vue';

it('renders user info', () => {
  render(UserCard, { props: { user: { name: 'Alice', email: 'a@b.com' } }});
  expect(screen.getByText('Alice')).toBeInTheDocument();
});
```

---

## Acessibilidade (WCAG 2.1 AA — obrigatório)

Ver convenções em `docs/stack-conventions/frontend/react.md` (mesmas regras WCAG aplicam).

- Labels em todos elementos interativos
- Contraste mínimo 4.5:1
- Navegação por teclado
- Focus visível
- ARIA quando HTML semântico não dá conta
- Screen reader testado em features críticas
- Validação automática via axe-core

---

## Internacionalização (@nuxtjs/i18n)

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

### Regras

- **Nenhuma string hardcoded**
- Idiomas declarados no PRD
- RTL em projetos globais
- Formatadores nativos para datas/números

---

## Design Tokens

- **Tailwind config** centralizada
- **Nuxt UI** baseado em design tokens — fácil tematizar
- Em projetos multi-plataforma (Web + Mobile), tokens vêm de fonte única (Style Dictionary)
- Nada hardcoded em componentes

---

## Performance

### Web Vitals (Production Mode)

Mesmos targets do React (LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1).

### Técnicas Nuxt-específicas

- **Server Components** (Nuxt 3.9+) — `<MyComponent server-only />`
- **Lazy components** — `<LazyMyHeavy />` (auto-import + code split)
- **Image optimization** — `<NuxtImg>` (lazy, responsive, modern formats)
- **Payload extraction** em SSG
- **Hybrid rendering** — `routeRules` para mix de SSR/SSG/CSR/ISR
- **`useState` em SSR** — preserva estado entre server/client
- Bundle analysis: `nuxt analyze`

---

## Feature Flags

Ver `memory/ADR/ADR-003-feature-flags.md` e `agents/frontend-engineer.md`.

Mesmas regras do React:
- Flag check em rota ou organism (não em atoms)
- Cache local + fallback
- SDK do provedor

---

## Segurança específica

- **CSP** via `nuxt-security` module
- **HTTPS** obrigatório
- **httpOnly cookies** para tokens (não localStorage)
- **CSRF** mitigado por SameSite=Lax + verificação Origin
- `v-html` apenas com input confiável (Vue não sanitiza por padrão — usar DOMPurify)
- Variáveis públicas: `runtimeConfig.public` no Nuxt — não vazar secrets
- Server routes (Nuxt): validar input com Zod
- Headers via `nuxt-security` ou middleware

---

## Comandos padrão

```bash
# install
pnpm install

# dev
pnpm dev

# build
pnpm build
pnpm preview                                 # preview build local

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

## Anti-patterns (bloquear)

- Options API em código novo (usar Composition API)
- Lógica de negócio em template
- Mutar props (Vue avisa, mas evitar)
- `v-html` com input não-sanitizado
- Inline styles que deveriam ser tokens
- Texto hardcoded
- `useFetch` em watcher (race conditions) — usar `watch` separado
- Pinia store para estado puramente local
- Composables que retornam objeto sem reatividade (perde reactivity)
- `ref` vs `reactive` mal escolhidos (regra: prefira `ref` por consistência)
- `v-for` sem `:key`
- Componentes gigantes (> 200 linhas)
- Misturar `<script>` Options API com `<script setup>` no mesmo arquivo
- Acessibilidade ignorada

---

## Referências

- Vue 3: <https://vuejs.org/guide/introduction.html>
- Nuxt 3: <https://nuxt.com/docs>
- Pinia: <https://pinia.vuejs.org/>
- VueUse: <https://vueuse.org/> (composables prontos)
- Tailwind CSS: <https://tailwindcss.com/docs>
- Nuxt UI: <https://ui.nuxt.com/>
- Vue Test Utils: <https://test-utils.vuejs.org/>
- Vue Style Guide: <https://vuejs.org/style-guide/>
