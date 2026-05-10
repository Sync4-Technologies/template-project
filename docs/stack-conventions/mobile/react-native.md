# Stack Convention — React Native (TypeScript)

> Frameworks suportados: **Expo** (preferencial — managed workflow + EAS) ou **bare React Native** (controle total, plugins nativos custom).

---

## Quando usar esta stack

Escolher React Native quando:

- **Time já domina React/JS** — reúso massivo de skill
- **Compartilhamento de código com web** — TypeScript end-to-end (mas UI compartilhada é limitada — preferir lógica/types/clients)
- **Ecosistema JS rico necessário** — npm packages, libs maduras
- **Iteração rápida** — Hot Reload, OTA updates via CodePush/EAS Update
- **Plugins nativos custom relativamente simples** — escrita em Swift/Kotlin se necessário
- **Times híbridos web/mobile** — devs trabalham em ambos
- **Apps com UI majoritariamente padrão** (sem necessidade de UI ultra-custom)
- **Need for OTA updates** — push de JS sem passar pela store

## Quando NÃO usar

- **Performance crítica** com animações complexas — Flutter geralmente vence
- **UI ultra-customizada e única** — Flutter renderiza tudo nativamente
- **Time já experiente em Flutter/Dart** — sem motivo de mudar
- **Restrições rigorosas de tamanho de app** — RN bridge adiciona overhead
- **Integrações nativas profundas e custom** — possível mas penoso (mitigado por New Architecture)
- **Background services pesados** — limitações em ambas plataformas

---

## Versões e dependências

| Item | Versão mínima |
|------|---------------|
| Node.js | ≥ 20 LTS |
| TypeScript | ≥ 5.4 |
| React Native | ≥ 0.74 (preferencial 0.75+ com New Architecture) |
| Expo SDK | ≥ 51 (se Expo) |
| iOS deployment target | 13.4 |
| Android: minSdkVersion | 24 (Android 7.0) |

### Expo vs Bare

| Cenário | Escolha |
|---------|---------|
| App padrão sem plugins nativos custom | **Expo Managed** |
| Necessidade de plugins nativos custom | **Expo + Dev Client** ou **Bare** |
| Migração de RN existente | Avaliar caso-a-caso |
| Time iniciante | **Expo** (curva muito mais suave) |
| OTA updates | **Expo + EAS Update** ou **CodePush** (bare) |

### Bibliotecas padrão

| Necessidade | Biblioteca |
|-------------|-----------|
| Navigation | **react-navigation** ou **expo-router** (file-based, preferencial em Expo) |
| State management | **Zustand** (preferencial) ou **Redux Toolkit** |
| Server state | **TanStack Query** |
| Forms | **React Hook Form** + Zod |
| Validação | **Zod** |
| HTTP | **fetch** + ofetch (ou **axios**) |
| Storage local | **react-native-mmkv** (preferencial — fast) ou AsyncStorage |
| Secure storage | **expo-secure-store** ou **react-native-keychain** |
| Database | **drizzle-orm** + expo-sqlite (preferencial) ou WatermelonDB |
| UI library | **gluestack-ui**, **tamagui** (preferencial cross-platform) ou **react-native-paper** |
| Icons | **lucide-react-native** ou **expo-symbols** |
| Animations | **react-native-reanimated** (v3) + react-native-gesture-handler |
| Testing | **Jest** + React Native Testing Library |
| E2E | **Detox** ou **Maestro** |
| i18n | **i18next** + react-i18next |
| Auth | Custom JWT ou **Clerk Expo** |
| Crash reporting | **Sentry** ou **Firebase Crashlytics** |
| Analytics | **Posthog** ou **firebase_analytics** |
| Image | **expo-image** (preferencial — caching, modern formats) |
| Lists performantes | **FlashList** (Shopify) ou FlatList |
| Feature flags | **LaunchDarkly RN SDK** ou **Unleash Proxy** |

---

## Tooling obrigatório

| Tool | Propósito |
|------|-----------|
| **ESLint** | Linter (config: `@react-native`) |
| **Prettier** | Formatter |
| **TypeScript** | Type check (`tsc --noEmit`) |
| **Jest** + RN Testing Library | Test runner |
| **Detox** ou **Maestro** | E2E |
| **Reactotron** ou Flipper (em projetos antigos) | DevTools |
| **EAS** (Expo) | Build e submit |
| **Husky + lint-staged** | Pre-commit |

---

## Layout do projeto (Clean Architecture)

```
src/
├── app/                                  # Expo Router (file-based) ou screens
│   ├── (auth)/                           # grupo de rotas
│   │   ├── login.tsx
│   │   └── register.tsx
│   ├── (app)/
│   │   ├── _layout.tsx
│   │   ├── home.tsx
│   │   └── settings.tsx
│   └── _layout.tsx
│
├── features/                             # vertical slices
│   ├── auth/
│   │   ├── data/                         # outbound adapters
│   │   │   ├── api/                      # HTTP clients
│   │   │   ├── storage/                  # local persistence
│   │   │   └── repositories/             # impl
│   │   │
│   │   ├── domain/                       # núcleo
│   │   │   ├── entities/
│   │   │   ├── repositories/             # interfaces (ports)
│   │   │   └── usecases/
│   │   │
│   │   └── presentation/                 # inbound adapters
│   │       ├── components/               # Atomic Design
│   │       ├── hooks/                    # use* hooks
│   │       └── screens/
│   │
│   └── orders/
│       └── ...
│
├── shared/
│   ├── components/                       # Atomic Design compartilhado
│   ├── hooks/
│   └── utils/
│
├── core/
│   ├── di/                               # composition root
│   ├── theme/                            # design tokens
│   ├── i18n/
│   ├── network/                          # http client + interceptors
│   ├── storage/                          # MMKV setup
│   └── observability/
│
└── types/
```

---

## Convenções de código

### Naming

- **PascalCase** para componentes e arquivos (`UserCard.tsx`)
- **camelCase** para hooks (`useAuth`), utilities, props
- **kebab-case** para folders
- **PascalCase** para types/interfaces (sem prefix `I`)

### Componentes (function + TypeScript)

```tsx
// 1 componente por arquivo
import { View, Text, Pressable } from 'react-native';

interface UserCardProps {
  user: User;
  onPress?: (id: string) => void;
}

export function UserCard({ user, onPress }: UserCardProps) {
  return (
    <Pressable
      onPress={() => onPress?.(user.id)}
      accessibilityRole="button"
      accessibilityLabel={`User ${user.name}`}
    >
      <View style={styles.container}>
        <Text style={styles.name}>{user.name}</Text>
        <Text style={styles.email}>{user.email}</Text>
      </View>
    </Pressable>
  );
}
```

### Atomic Design + Platform-Adaptive

| Camada | Exemplo |
|--------|---------|
| **Atoms** | Button, Input, Text, Icon |
| **Molecules** | FormField, Card |
| **Organisms** | Header, UserList |
| **Templates** | layouts em `app/` |
| **Pages/Screens** | screens dentro de features |

Plataforma-específico via `Platform.OS` ou suffixed files (`Component.ios.tsx`, `Component.android.tsx`).

### State management

- **Server state:** TanStack Query
- **Global client state:** Zustand (Redux Toolkit em casos complexos)
- **Local component state:** useState, useReducer
- **Forms:** React Hook Form + Zod

```tsx
// store
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { storage } from '@/core/storage/mmkv-storage';

export const useAuthStore = create(
  persist(
    (set) => ({
      user: null as User | null,
      setUser: (user: User | null) => set({ user }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => storage),
    }
  )
);
```

### Forms (React Hook Form + Zod)

```tsx
const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

function LoginScreen() {
  const { control, handleSubmit, formState } = useForm({
    resolver: zodResolver(schema),
  });

  return (
    <Controller
      control={control}
      name="email"
      render={({ field, fieldState }) => (
        <TextInput
          value={field.value}
          onChangeText={field.onChange}
          error={fieldState.error?.message}
        />
      )}
    />
  );
}
```

### Error handling

- Error Boundaries para falhas de render (react-error-boundary)
- TanStack Query: `onError` ou `error`
- Toasts para feedback (react-native-toast-message ou nativos)
- Sentry captura crashes em produção

### Platform-Adaptive UI

```tsx
import { Platform } from 'react-native';

const styles = StyleSheet.create({
  container: {
    paddingTop: Platform.OS === 'ios' ? 44 : 24,  // safe area
  },
});

// OU usar SafeAreaView (preferencial)
import { SafeAreaView } from 'react-native-safe-area-context';
```

### Imports

```tsx
// ordem: react/react-native → externos → absolutos → relativos
import { useEffect } from 'react';
import { View, Text } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/shared/components/atoms/Button';
import { fetchUsers } from '@/features/users/data/api';
```

---

## Padrão de testes

### Pirâmide

| Camada | Ferramenta | Cobertura por modo |
|--------|-----------|--------------------|
| Unit (utils, hooks, use cases) | Jest | MVP ≥60% críticas / Production ≥95% críticas |
| Component | RN Testing Library | MVP ≥50% / Production ≥80% |
| Integration | Jest + MSW | Production ≥70% |
| E2E | Detox ou Maestro | Happy paths críticos |
| Snapshot (cuidado!) | Jest | Apenas componentes muito estáveis |

### React Native Testing Library

```tsx
import { render, screen, fireEvent } from '@testing-library/react-native';

it('calls onPress when tapped', () => {
  const onPress = jest.fn();
  render(<UserCard user={mockUser} onPress={onPress} />);

  fireEvent.press(screen.getByText(mockUser.name));

  expect(onPress).toHaveBeenCalledWith(mockUser.id);
});
```

### E2E (Detox preferencial em iOS+Android)

```js
describe('Login flow', () => {
  it('logs in successfully', async () => {
    await element(by.id('email-input')).typeText('a@b.com');
    await element(by.id('password-input')).typeText('password');
    await element(by.id('login-button')).tap();
    await expect(element(by.id('home-screen'))).toBeVisible();
  });
});
```

---

## Acessibilidade (WCAG 2.1 AA)

- `accessibilityLabel`, `accessibilityRole`, `accessibilityHint`
- `accessibilityState` para estados (selected, disabled, expanded)
- Tap targets mínimos: 44x44 (iOS) / 48x48 (Android)
- Contraste mínimo 4.5:1
- Suporte a tamanho de fonte do sistema (`PixelRatio`, `useWindowDimensions`)
- Não depender só de cor para informação
- Teste com VoiceOver (iOS) e TalkBack (Android) em features críticas
- `accessibilityViewIsModal` para modais

```tsx
<Pressable
  accessibilityRole="button"
  accessibilityLabel="Add new task"
  accessibilityHint="Opens new task form"
  onPress={onAdd}
>
  <Icon name="plus" />
</Pressable>
```

---

## Internacionalização (i18next)

```tsx
// i18n/index.ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

i18n.use(initReactI18next).init({
  resources: {
    'pt-BR': { translation: require('./pt-BR.json') },
    'en-US': { translation: require('./en-US.json') },
  },
  lng: 'pt-BR',
  fallbackLng: 'en-US',
});
```

```tsx
import { useTranslation } from 'react-i18next';

function Greeting({ name }: { name: string }) {
  const { t } = useTranslation();
  return <Text>{t('greeting', { name })}</Text>;
}
```

### Regras

- **Nenhuma string hardcoded**
- Idiomas declarados no PRD
- RTL: `I18nManager.isRTL` + estilos lógicos (start/end vs left/right)

---

## Design Tokens

- Centralizados em `core/theme/`
- Em projetos multi-plataforma (Web + Mobile), tokens vêm de fonte única (Style Dictionary) — Mobile valida paridade com Frontend
- StyleSheet imutáveis (`StyleSheet.create`)
- Tamagui ou gluestack-ui acomodam tokens nativamente
- Nada hardcoded em componentes

---

## Performance

### Targets (obrigatório)

- **60fps** em listas e animações críticas
- **JS thread** sem bloqueios (não fazer trabalho pesado em handler)
- **App start** ≤ 3s frio em dispositivo médio

### Técnicas

- **FlashList** ou **FlatList** com `getItemLayout`, `keyExtractor`, `removeClippedSubviews`
- **react-native-reanimated** v3 para animações (roda na UI thread)
- **expo-image** com cache de disco
- **Image resize** correto
- **InteractionManager.runAfterInteractions** para tarefas que podem esperar
- **Memo cuidadoso** (React.memo, useMemo) — não profilático
- **New Architecture** (Fabric + TurboModules) habilitada quando possível
- **Hermes** habilitado em produção (default em Expo)
- **ProGuard/R8** para Android release
- Profiling: Flipper, RN DevTools, Hermes profiler

---

## Feature Flags (offline-aware)

Ver `memory/ADR/ADR-003-feature-flags.md` e `agents/mobile-engineer.md`.

- Cache local persistente (MMKV)
- TTL razoável + uso de cache se offline
- Fallback determinístico
- Default-deny em features críticas se flag indisponível
- Considerar versão mínima de app (flags antigas em apps antigos não atualizáveis)
- SDK do provedor (LaunchDarkly RN SDK)

---

## Segurança específica

- **Secure storage** para tokens (expo-secure-store / react-native-keychain) — nunca AsyncStorage para sensíveis
- **Certificate pinning** em produção (react-native-ssl-pinning)
- **Hermes obfuscation** + ProGuard/R8
- **No screenshots** em telas sensíveis (`flag_secure` Android, `applicationDidEnterBackground` iOS)
- **Root/jailbreak detection** em apps financeiros (jail-monkey)
- **Não** logar dados sensíveis (Sentry: configurar `beforeSend` para redact)
- **HTTPS only** (ATS no iOS, network_security_config no Android)
- **Variáveis públicas:** `EXPO_PUBLIC_*` (Expo) — auditar para não vazar secrets
- **Deep link validation** — não confiar em parâmetros sem validar
- `npm audit` ou `pnpm audit` na pipeline

---

## Comandos padrão

### Expo

```bash
# install
pnpm install

# dev
pnpm start                                   # Metro + dev menu
pnpm ios                                     # iOS sim
pnpm android                                 # Android emulator

# test
pnpm test                                    # jest
pnpm test:e2e                                # detox

# lint + format
pnpm lint
pnpm format
pnpm typecheck                               # tsc --noEmit

# build (EAS)
eas build --platform ios --profile production
eas build --platform android --profile production

# submit
eas submit --platform ios
eas submit --platform android

# OTA update
eas update --branch production

# CI
pnpm typecheck && pnpm lint && pnpm test --coverage && pnpm build:check
```

### Bare RN

```bash
# iOS
cd ios && pod install && cd ..
pnpm ios

# Android
pnpm android

# build release
cd ios && fastlane build_release
cd android && ./gradlew assembleRelease
```

---

## Anti-patterns (bloquear)

- Lógica de negócio em componente
- `setState` em features grandes (use Zustand/Redux)
- AsyncStorage para tokens (use Secure Storage)
- Cores e espaçamentos hardcoded
- Texto hardcoded
- `console.log` em produção (use logger ou Sentry)
- Listas longas sem FlashList/FlatList
- Imagens sem cache (use expo-image)
- Animações no JS thread (use Reanimated)
- Bridge calls síncronas em handler (bloqueia UI)
- Componentes gigantes
- Tap target < 44/48
- Acessibilidade ignorada
- Memo profilático (overhead sem ganho)
- `any` sem justificativa
- Falta de tratamento de offline em features críticas

---

## Referências

- React Native: <https://reactnative.dev/docs/getting-started>
- Expo: <https://docs.expo.dev/>
- Expo Router: <https://docs.expo.dev/router/introduction/>
- Reanimated: <https://docs.swmansion.com/react-native-reanimated/>
- TanStack Query: <https://tanstack.com/query/latest>
- Zustand: <https://zustand-demo.pmnd.rs/>
- Tamagui: <https://tamagui.dev/>
- React Native Testing Library: <https://callstack.github.io/react-native-testing-library/>
- Detox: <https://wix.github.io/Detox/>
