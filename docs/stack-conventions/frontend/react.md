# Stack Convention — React + Next.js

> Frameworks suportados: **Next.js** (SSR/SSG, app full-stack, SEO) ou **React + Vite** (SPA dashboard interno).

---

## Quando usar esta stack

Escolher React (com Next.js) quando:

- **SEO importa** — landing pages, blog, e-commerce, marketing site (Next.js SSR/SSG)
- **Apps complexos com muitas telas** — ecosistema de libraries é o mais maduro
- **Time já domina React** — pool de devs vasto
- **Compartilhamento de tipos com backend Node.js** — TypeScript end-to-end
- **Server Components + Server Actions** (Next.js App Router) — full-stack moderno
- **App híbrido** com algumas páginas SSR e outras SPA
- **Ecosistema rico necessário** — UI libs (shadcn/ui, Radix, MUI, Mantine), forms (React Hook Form), tables (TanStack Table)
- **i18n e a11y maduros** — react-i18next, react-aria

Escolher React + Vite (sem Next.js) quando:

- **Dashboard interno / Admin panel** — sem necessidade de SSR/SEO
- **SPA simples** com auth atrás de login
- **Build ultra-rápido** durante desenvolvimento
- **Embedded em outra app** (microfrontend)

## Quando NÃO usar

- **Time pequeno sem experiência React** — curva de aprendizado é real
- **Marketing site puramente estático sem interatividade** — Astro ou HTML puro são mais simples
- **App com lógica simples e prazo curto** — Vue/Nuxt costuma ter menos boilerplate

---

## Versões e dependências

| Item | Versão mínima |
|------|---------------|
| Node.js | ≥ 20 LTS |
| TypeScript | ≥ 5.4 |
| React | ≥ 18.3 (preferencial 19 quando estável) |
| Next.js | ≥ 15 (App Router) |
| pnpm | ≥ 9 |

### Bibliotecas padrão

| Necessidade | Biblioteca |
|-------------|-----------|
| UI library | shadcn/ui (preferencial) ou Radix UI primitives |
| Styling | Tailwind CSS (preferencial) ou CSS Modules |
| State management | Zustand (simples) ou Redux Toolkit (complexo) |
| Server state / data fetching | TanStack Query (preferencial) ou SWR |
| Forms | React Hook Form + Zod resolver |
| Validação | Zod |
| HTTP client | fetch nativo + wrapper TS, ou ky (preferencial sobre axios) |
| Testing | Vitest (preferencial) ou Jest + React Testing Library |
| E2E | Playwright (preferencial) ou Cypress |
| i18n | next-intl (Next.js) ou react-i18next |
| Auth | NextAuth.js / Auth.js ou Clerk |
| Tables | TanStack Table |
| Date | date-fns ou Day.js (não Moment.js — abandonado) |
| Animations | Framer Motion |
| Icons | lucide-react |
| Feature flags | LaunchDarkly SDK ou Unleash Proxy SDK |
| Analytics | Posthog ou Mixpanel |
| Observability | Sentry (errors) + Vercel Analytics |

---

## Tooling obrigatório

| Tool | Propósito |
|------|-----------|
| **ESLint** | Linter (`eslint-config-next` + `@typescript-eslint/strict`) |
| **Prettier** | Formatter |
| **TypeScript** | Type check (`tsc --noEmit`) |
| **Vitest** + **React Testing Library** | Test runner |
| **Playwright** | E2E |
| **Storybook** | Documentação visual de componentes |
| **lighthouse-ci** | Performance budget na pipeline |
| **bundle-analyzer** | Análise de bundle size |
| **husky + lint-staged** | Pre-commit hooks |
| **commitlint** | Convenção de commits |

---

## Layout do projeto

### Next.js App Router (preferencial)

```
src/
├── app/                              # App Router (rotas)
│   ├── (marketing)/                  # grupo de rotas
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── (app)/                        # área autenticada
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
├── hooks/                            # hooks compartilhados
├── lib/                              # utilities, helpers
│   ├── api/                          # client HTTP
│   ├── auth/
│   └── utils.ts
├── providers/                        # context providers (Query, Theme, etc.)
├── styles/                           # design tokens, globals
├── i18n/                             # locales
└── types/                            # tipos compartilhados
```

### Vite SPA

```
src/
├── components/                       # Atomic Design
├── features/
├── hooks/
├── lib/
├── pages/                            # rotas via React Router
├── providers/
└── main.tsx
```

---

## Convenções de código

### Naming

- **PascalCase** para componentes e arquivos de componentes (`UserCard.tsx`)
- **camelCase** para hooks (`useAuth`), utilities, props
- **kebab-case** para folders (exceto componentes — usar PascalCase ou kebab consistente)
- **PascalCase** para types e interfaces (sem prefix `I`)
- **UPPER_SNAKE_CASE** para constantes globais

### Componentes

```tsx
// 1 componente por arquivo
// componente é function, não class
// props tipadas com interface ou type

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

| Camada | Exemplo |
|--------|---------|
| **Atoms** | Button, Input, Label, Icon |
| **Molecules** | FormField (Label + Input + Error), SearchBox |
| **Organisms** | Header, UserCard, OrderTable |
| **Templates** | DashboardLayout, AuthLayout |
| **Pages** | route components em `app/` |

Lógica de negócio **nunca** em atoms/molecules. Hooks ou organisms orquestram.

### Server vs Client Components (Next.js App Router)

- **Default:** Server Component (sem JS no cliente)
- **`'use client'`** apenas quando há: interatividade, hooks de estado, browser APIs
- Evitar marcar componente parent como client se children podem ser server

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

- **Server state:** TanStack Query (cache, revalidação, mutations)
- **Client state global:** Zustand (Redux só em casos complexos com time-travel)
- **Component state local:** useState, useReducer
- **URL state:** searchParams (Next.js) ou React Router

### Data fetching (Next.js App Router)

```tsx
// Server Component — fetch direto
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

- Error Boundaries para falhas de render
- `error.tsx` em rotas Next.js para erros de loading/server
- TanStack Query: `onError` ou `error` do hook
- Toasts para feedback (sonner ou react-hot-toast)

### Imports

```tsx
// ordem: react/next → externos → internos absolutos → relativos
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { fetchUsers } from '@/lib/api/users';
import { UserCard } from './UserCard';
```

---

## Padrão de testes

### Pirâmide

| Camada | Ferramenta | Cobertura por modo |
|--------|-----------|--------------------|
| Unit (utils, hooks) | Vitest | MVP ≥60% críticas / Production ≥80% |
| Component | Vitest + Testing Library | MVP ≥50% / Production ≥80% |
| Integration | Vitest + MSW (mock API) | Production ≥70% |
| E2E | Playwright | Happy paths críticos |
| Visual regression | Chromatic ou Percy | Production: opcional |
| Accessibility | axe-core via Playwright | Obrigatório em features críticas |

### Estrutura

- `*.test.tsx` ao lado do componente
- MSW para mockar APIs em testes
- Storybook para documentação visual + smoke testing

### Acessibilidade no teste

```tsx
import { axe } from 'jest-axe';

it('should have no a11y violations', async () => {
  const { container } = render(<UserForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

---

## State management detalhado

### Server state (TanStack Query)

- Cache automático
- Revalidação inteligente (focus, reconnect, interval)
- Optimistic updates via `onMutate`
- Não duplicar server state em Zustand/Redux

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

## Acessibilidade (WCAG 2.1 AA — obrigatório)

- Labels semânticos em todos elementos interativos
- Contraste mínimo 4.5:1 (texto normal), 3:1 (texto grande)
- Navegação por teclado em todos fluxos
- Focus visível e ordenado
- ARIA apenas quando HTML semântico não dá conta
- Screen reader testado em features críticas
- Não depender só de cor para comunicar estado
- Forms com `<label>` associado a `<input>`
- `<button>` para ações, `<a>` para navegação

---

## Internacionalização (i18n)

### next-intl (App Router)

```tsx
// messages/pt-BR.json
{ "greeting": "Olá, {name}" }

// componente
import { useTranslations } from 'next-intl';

export function Greeting({ name }: { name: string }) {
  const t = useTranslations();
  return <p>{t('greeting', { name })}</p>;
}
```

### Regras

- **Nenhuma string hardcoded** em componentes
- Idiomas declarados no PRD (ver `docs/PRD-template.md`)
- Considerar RTL (árabe, hebraico) em projetos globais
- Formatadores nativos: `Intl.DateTimeFormat`, `Intl.NumberFormat`

---

## Design Tokens

- **Tailwind config** centralizada (cores, espaçamentos, tipografia)
- **shadcn/ui** baseado em CSS variables — fácil tematizar
- Em projetos multi-plataforma (Web + Mobile), tokens vêm de fonte única (Style Dictionary) — Frontend mantém, Mobile valida paridade
- Nada hardcoded em componentes (cores, tamanhos)

---

## Performance

### Web Vitals (Production Mode)

| Métrica | Target |
|---------|--------|
| LCP | ≤ 2.5s |
| INP | ≤ 200ms |
| CLS | ≤ 0.1 |

### Técnicas

- **Image optimization** — `next/image` (lazy, responsive, AVIF/WebP)
- **Font optimization** — `next/font` (no FOIT/FOUT, self-hosted)
- **Code splitting** — `dynamic()` para componentes pesados
- **Server Components** sempre que possível (zero JS shipped)
- **Streaming** com Suspense para conteúdo lento
- **Bundle analyzer** — monitorar bundle size na pipeline
- **Lighthouse CI** com budget na pipeline
- **Memoization** judiciosa (`useMemo`, `useCallback`, `memo`) — não usar profilaticamente

---

## Feature Flags

Ver `memory/ADR/ADR-003-feature-flags.md` e `agents/frontend-engineer.md`.

- Flag check em **rota** ou **organism**, nunca em atoms
- Cache local + fallback determinístico
- Loading state enquanto carrega flag
- SDK do provedor (LaunchDarkly React SDK, Unleash Proxy SDK)

---

## Segurança específica

- **CSP** (Content Security Policy) configurada (`next.config.js` headers)
- **HTTPS** obrigatório em produção (Next.js + Vercel default)
- **httpOnly cookies** para tokens de sessão (não localStorage)
- **CSRF** mitigado por SameSite=Lax cookies + verificação Origin
- Sanitizar HTML antes de `dangerouslySetInnerHTML` (DOMPurify) — preferir não usar
- Variáveis públicas: prefix `NEXT_PUBLIC_` (Next.js) — auditar para não vazar secrets
- Server Actions: validar input com Zod antes de processar
- Headers: X-Frame-Options, X-Content-Type-Options, Referrer-Policy

---

## Comandos padrão

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

## Anti-patterns (bloquear)

- Lógica de negócio em componente UI
- Estado global para coisa local (`useState` vs Zustand)
- Server state duplicado em store cliente
- `any` sem justificativa
- `useEffect` para data fetching (use TanStack Query)
- `any` em props
- Componentes gigantes (> 200 linhas) — extrair
- Inline styles para coisas que deveriam ser tokens
- `dangerouslySetInnerHTML` sem sanitização
- Texto hardcoded (sem i18n)
- Fetch sem tratamento de erro/loading
- `key={index}` em listas dinâmicas
- `useMemo`/`useCallback` profiláticos (criar overhead)
- Acessibilidade ignorada (sem labels, sem contraste, sem keyboard nav)
- Bundle bloated (importar lib inteira ao invés de funções específicas)

---

## Referências

- React: <https://react.dev/>
- Next.js: <https://nextjs.org/docs>
- TanStack Query: <https://tanstack.com/query/latest>
- React Hook Form: <https://react-hook-form.com/>
- Tailwind CSS: <https://tailwindcss.com/docs>
- shadcn/ui: <https://ui.shadcn.com/>
- Testing Library: <https://testing-library.com/docs/react-testing-library/intro>
- Web Vitals: <https://web.dev/vitals/>
