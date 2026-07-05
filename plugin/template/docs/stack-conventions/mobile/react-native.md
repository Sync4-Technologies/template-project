# Stack Convention — React Native (TypeScript)

> Supported frameworks: **Expo** (preferred — managed workflow + EAS) or **bare React Native** (full control, custom native plugins).

---

## When to use this stack

Choose React Native when:

- **Team already fluent in React/JS** — massive skill reuse
- **Code sharing with web** — TypeScript end-to-end (but shared UI is limited — prefer logic/types/clients)
- **Rich JS ecosystem needed** — npm packages, mature libs
- **Fast iteration** — Hot Reload, OTA updates via CodePush/EAS Update
- **Relatively simple custom native plugins** — written in Swift/Kotlin if needed
- **Hybrid web/mobile teams** — devs work on both
- **Apps with mostly standard UI** (no need for ultra-custom UI)
- **Need for OTA updates** — push JS without going through the store

## When NOT to use

- **Critical performance** with complex animations — Flutter usually wins
- **Ultra-customized and unique UI** — Flutter renders everything natively
- **Team already experienced in Flutter/Dart** — no reason to switch
- **Strict app size restrictions** — RN bridge adds overhead
- **Deep custom native integrations** — possible but painful (mitigated by New Architecture)
- **Heavy background services** — limitations on both platforms

---

## Versions and dependencies

| Item | Minimum version |
|------|-----------------|
| Node.js | ≥ 20 LTS |
| TypeScript | ≥ 5.4 |
| React Native | ≥ 0.74 (prefer 0.75+ with New Architecture) |
| Expo SDK | ≥ 51 (if Expo) |
| iOS deployment target | 13.4 |
| Android: minSdkVersion | 24 (Android 7.0) |

### Expo vs Bare

| Scenario | Choice |
|----------|--------|
| Standard app without custom native plugins | **Expo Managed** |
| Need for custom native plugins | **Expo + Dev Client** or **Bare** |
| Migration from existing RN | Evaluate case-by-case |
| Beginner team | **Expo** (much smoother curve) |
| OTA updates | **Expo + EAS Update** or **CodePush** (bare) |

### Standard libraries

| Need | Library |
|------|---------|
| Navigation | **react-navigation** or **expo-router** (file-based, preferred in Expo) |
| State management | **Zustand** (preferred) or **Redux Toolkit** |
| Server state | **TanStack Query** |
| Forms | **React Hook Form** + Zod |
| Validation | **Zod** |
| HTTP | **fetch** + ofetch (or **axios**) |
| Local storage | **react-native-mmkv** (preferred — fast) or AsyncStorage |
| Secure storage | **expo-secure-store** or **react-native-keychain** |
| Database | **drizzle-orm** + expo-sqlite (preferred) or WatermelonDB |
| UI library | **gluestack-ui**, **tamagui** (preferred cross-platform), or **react-native-paper** |
| Icons | **lucide-react-native** or **expo-symbols** |
| Animations | **react-native-reanimated** (v3) + react-native-gesture-handler |
| Testing | **Jest** + React Native Testing Library |
| E2E | **Detox** or **Maestro** |
| i18n | **i18next** + react-i18next |
| Auth | Custom JWT or **Clerk Expo** |
| Crash reporting | **Sentry** or **Firebase Crashlytics** |
| Analytics | **Posthog** or **firebase_analytics** |
| Image | **expo-image** (preferred — caching, modern formats) |
| Performant lists | **FlashList** (Shopify) or FlatList |
| Feature flags | **LaunchDarkly RN SDK** or **Unleash Proxy** |

---

## Required tooling

| Tool | Purpose |
|------|---------|
| **ESLint** | Linter (config: `@react-native`) |
| **Prettier** | Formatter |
| **TypeScript** | Type check (`tsc --noEmit`) |
| **Jest** + RN Testing Library | Test runner |
| **Detox** or **Maestro** | E2E |
| **Reactotron** or Flipper (in older projects) | DevTools |
| **EAS** (Expo) | Build and submit |
| **Husky + lint-staged** | Pre-commit |

---

## Project layout (Clean Architecture)

```
src/
├── app/                                  # Expo Router (file-based) or screens
│   ├── (auth)/                           # route group
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
│   │   ├── domain/                       # core
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
│   ├── components/                       # shared Atomic Design
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

## Code conventions

### Naming

- **PascalCase** for components and files (`UserCard.tsx`)
- **camelCase** for hooks (`useAuth`), utilities, props
- **kebab-case** for folders
- **PascalCase** for types/interfaces (no `I` prefix)

### Components (function + TypeScript)

```tsx
// 1 component per file
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

| Layer | Example |
|-------|---------|
| **Atoms** | Button, Input, Text, Icon |
| **Molecules** | FormField, Card |
| **Organisms** | Header, UserList |
| **Templates** | layouts in `app/` |
| **Pages/Screens** | screens inside features |

Platform-specific via `Platform.OS` or suffixed files (`Component.ios.tsx`, `Component.android.tsx`).

### State management

- **Server state:** TanStack Query
- **Global client state:** Zustand (Redux Toolkit in complex cases)
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

- Error Boundaries for render failures (react-error-boundary)
- TanStack Query: `onError` or `error`
- Toasts for feedback (react-native-toast-message or native)
- Sentry captures crashes in production

### Platform-Adaptive UI

```tsx
import { Platform } from 'react-native';

const styles = StyleSheet.create({
  container: {
    paddingTop: Platform.OS === 'ios' ? 44 : 24,  // safe area
  },
});

// OR use SafeAreaView (preferred)
import { SafeAreaView } from 'react-native-safe-area-context';
```

### Imports

```tsx
// order: react/react-native → external → absolute → relative
import { useEffect } from 'react';
import { View, Text } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/shared/components/atoms/Button';
import { fetchUsers } from '@/features/users/data/api';
```

---

## Testing standards

### Pyramid

| Layer | Tool | Coverage by mode |
|-------|------|------------------|
| Unit (utils, hooks, use cases) | Jest | MVP ≥60% critical / Production ≥95% critical |
| Component | RN Testing Library | MVP ≥50% / Production ≥80% |
| Integration | Jest + MSW | Production ≥70% |
| E2E | Detox or Maestro | Critical happy paths |
| Snapshot (careful!) | Jest | Only very stable components |

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

### E2E (Detox preferred for iOS+Android)

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

## Accessibility (WCAG 2.1 AA)

- `accessibilityLabel`, `accessibilityRole`, `accessibilityHint`
- `accessibilityState` for states (selected, disabled, expanded)
- Minimum tap targets: 44x44 (iOS) / 48x48 (Android)
- Minimum contrast 4.5:1
- Support system font size (`PixelRatio`, `useWindowDimensions`)
- Don't rely on color alone for information
- Test with VoiceOver (iOS) and TalkBack (Android) in critical features
- `accessibilityViewIsModal` for modals

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

## Internationalization (i18next)

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

### Rules

- **No hardcoded strings**
- Languages declared in PRD
- RTL: `I18nManager.isRTL` + logical styles (start/end vs left/right)

---

## Design Tokens

- Centralized in `core/theme/`
- In multi-platform projects (Web + Mobile), tokens come from a single source (Style Dictionary) — Mobile validates parity with Frontend
- Immutable StyleSheets (`StyleSheet.create`)
- Tamagui or gluestack-ui accommodate tokens natively
- Nothing hardcoded in components

---

## Performance

### Targets (required)

- **60fps** in critical lists and animations
- **JS thread** without blocks (don't do heavy work in handler)
- **App start** ≤ 3s cold on mid-range device

### Techniques

- **FlashList** or **FlatList** with `getItemLayout`, `keyExtractor`, `removeClippedSubviews`
- **react-native-reanimated** v3 for animations (runs on UI thread)
- **expo-image** with disk cache
- **Correct image resize**
- **InteractionManager.runAfterInteractions** for tasks that can wait
- **Careful memo** (React.memo, useMemo) — not prophylactic
- **New Architecture** (Fabric + TurboModules) enabled when possible
- **Hermes** enabled in production (default in Expo)
- **ProGuard/R8** for Android release
- Profiling: Flipper, RN DevTools, Hermes profiler

---

## Feature Flags (offline-aware)

See `${CLAUDE_PLUGIN_ROOT}/template/memory/ADR/ADR-003-feature-flags.md` and `${CLAUDE_PLUGIN_ROOT}/template/agents/mobile-engineer.md`.

- Persistent local cache (MMKV)
- Reasonable TTL + use cache if offline
- Deterministic fallback
- Default-deny in critical features if flag unavailable
- Consider minimum app version (old flags in non-updatable old apps)
- Provider SDK (LaunchDarkly RN SDK)

---

## Stack-specific security

- **Secure storage** for tokens (expo-secure-store / react-native-keychain) — never AsyncStorage for sensitive
- **Certificate pinning** in production (react-native-ssl-pinning)
- **Hermes obfuscation** + ProGuard/R8
- **No screenshots** on sensitive screens (`flag_secure` Android, `applicationDidEnterBackground` iOS)
- **Root/jailbreak detection** in financial apps (jail-monkey)
- **Don't** log sensitive data (Sentry: configure `beforeSend` for redaction)
- **HTTPS only** (ATS on iOS, network_security_config on Android)
- **Public variables:** `EXPO_PUBLIC_*` (Expo) — audit so secrets don't leak
- **Deep link validation** — don't trust parameters without validation
- `npm audit` or `pnpm audit` in pipeline

---

## Standard commands

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

# release build
cd ios && fastlane build_release
cd android && ./gradlew assembleRelease
```

---

## Anti-patterns (block)

- Business logic in component
- `setState` in large features (use Zustand/Redux)
- AsyncStorage for tokens (use Secure Storage)
- Hardcoded colors and spacings
- Hardcoded text
- `console.log` in production (use logger or Sentry)
- Long lists without FlashList/FlatList
- Images without cache (use expo-image)
- Animations on JS thread (use Reanimated)
- Synchronous bridge calls in handler (blocks UI)
- Giant components
- Tap target < 44/48
- Accessibility ignored
- Prophylactic memo (overhead without gain)
- `any` without justification
- Missing offline handling in critical features

---

## References

- React Native: <https://reactnative.dev/docs/getting-started>
- Expo: <https://docs.expo.dev/>
- Expo Router: <https://docs.expo.dev/router/introduction/>
- Reanimated: <https://docs.swmansion.com/react-native-reanimated/>
- TanStack Query: <https://tanstack.com/query/latest>
- Zustand: <https://zustand-demo.pmnd.rs/>
- Tamagui: <https://tamagui.dev/>
- React Native Testing Library: <https://callstack.github.io/react-native-testing-library/>
- Detox: <https://wix.github.io/Detox/>
