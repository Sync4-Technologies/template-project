# Stack Convention — Flutter (Dart)

> Google's official framework for cross-platform apps with own rendering (Skia/Impeller) — native performance.

---

## When to use this stack

Choose Flutter when:

- **Native performance is priority** — consistent 60fps in lists, animations, transitions
- **Single codebase for iOS + Android** — maximum reuse (90%+)
- **Rich custom UI** — Flutter renders everything, no native widget limitations
- **Complex animations** — AnimationController, Hero transitions, custom painters
- **Team willing to learn Dart** — easy language but different
- **Additional cross-platform** (Web, Desktop) with same codebase
- **Apps with unique visual identity** (not standard Material/Cupertino)
- **Reproducible builds and clean CI/CD**
- **Excellent hot reload and DX**

## When NOT to use

- **Team already experienced in React Native** — no reason to switch
- **Massive JS code reuse with web** — RN shares React/JS
- **Deep native SDK integrations not covered by plugins** — possible but costly
- **Small app embedded in existing native app** — Flutter embedding overhead
- **Extreme app size restrictions** — Flutter adds ~5MB to APK

---

## Versions and dependencies

| Item | Minimum version |
|------|-----------------|
| Flutter | ≥ 3.22 (prefer 3.24+) |
| Dart | ships with Flutter (≥ 3.4) |
| Android: minSdkVersion | 21 (Android 5.0) |
| iOS deployment target | 12.0 |

### Standard libraries

| Need | Library |
|------|---------|
| State management | **BLoC** (preferred — scalable) or **Riverpod** (modern) |
| Routing | **go_router** (official) |
| HTTP | **dio** (preferred) or native http |
| Validation | dart_either + manual or form_validator |
| Local storage | **drift** (typed SQLite ORM) or **isar** (fast NoSQL) |
| Key-value | **shared_preferences** (simple) or **flutter_secure_storage** (sensitive) |
| DI | **get_it** + **injectable** (codegen) |
| Testing | flutter_test, mocktail, bloc_test |
| Code gen | freezed (data classes), json_serializable |
| Logging | logger or talker |
| i18n | **flutter_localizations** + intl + ARB files |
| Feature flags | LaunchDarkly Flutter SDK or Unleash Proxy |
| Analytics | firebase_analytics or mixpanel_flutter |
| Crash reporting | sentry_flutter or firebase_crashlytics |
| Image cache | cached_network_image |
| Animations | flutter_animate (preferred) |

---

## Required tooling

| Tool | Purpose |
|------|---------|
| **dart format** | Formatter (built-in) |
| **dart analyze** | Static analysis (built-in) |
| **very_good_analysis** or **lints** | Lint rules pack |
| **build_runner** | Code generation (freezed, injectable, drift) |
| **flutter_gen** | Asset generation |
| **flutter_test** | Test runner |
| **integration_test** | E2E |

### Minimum analysis_options.yaml

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    require_trailing_commas: true
```

---

## Project layout (Clean Architecture)

```
lib/
├── main.dart                            # entry point
├── app.dart                             # MaterialApp/CupertinoApp
│
├── core/                                # cross-cutting
│   ├── config/                          # env, constants
│   ├── di/                              # get_it setup
│   ├── error/                           # failures, exceptions
│   ├── network/                         # dio interceptors
│   ├── theme/                           # design tokens, themes
│   ├── routing/                         # go_router config
│   ├── localization/                    # i18n setup
│   └── utils/
│
├── features/                            # vertical slices
│   ├── auth/
│   │   ├── data/                        # outbound adapters
│   │   │   ├── datasources/             # remote (API), local (DB)
│   │   │   ├── models/                  # DTOs
│   │   │   └── repositories/            # impl of domain repository
│   │   │
│   │   ├── domain/                      # feature core
│   │   │   ├── entities/                # domain entities
│   │   │   ├── repositories/            # interfaces (ports)
│   │   │   └── usecases/                # use cases
│   │   │
│   │   └── presentation/                # inbound adapters
│   │       ├── bloc/                    # BLoCs/Cubits
│   │       ├── pages/                   # Screens
│   │       └── widgets/                 # Atomic Design (atoms, molecules, organisms)
│   │
│   └── orders/
│       └── ...
│
├── shared/                              # widgets/utilities reused across features
│   ├── widgets/
│   └── extensions/
│
└── l10n/                                # ARB files (i18n)

test/                                    # unit + widget tests (mirrors lib/)
integration_test/                        # E2E
```

### Hexagonal → Mobile Clean Architecture mapping

| Hexagonal | Flutter |
|-----------|---------|
| Domain | `features/<f>/domain/` |
| Application (use cases) | `features/<f>/domain/usecases/` |
| Inbound adapters | `features/<f>/presentation/` |
| Outbound adapters | `features/<f>/data/` |

---

## Code conventions

### Naming (Effective Dart)

- **lowerCamelCase** for variables, functions, methods, parameters
- **UpperCamelCase** for classes, enums, typedefs, mixins
- **lowercase_with_underscores** for filenames and directories
- **SCREAMING_CAPS** only for truly global constants

### Required immutability in entities

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    required DateTime createdAt,
  }) = _User;
}
```

### Const constructors

- **Always** use `const` when possible (optimizes rebuilds)
- Linter `prefer_const_constructors` enforces it

### Strict null safety

- Mode `strict-casts`, `strict-inference`, `strict-raw-types`
- Avoid `!` (force unwrap) — use guard clauses

```dart
// BAD
final email = user!.email;

// GOOD
if (user == null) return;
final email = user.email;
```

### State management (BLoC)

```dart
// auth_event.dart
sealed class AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested(this.email, this.password);
}

// auth_state.dart
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);
}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

// auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;

  AuthBloc(this._loginUseCase) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _loginUseCase.execute(event.email, event.password);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }
}
```

### Use case pattern

```dart
class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<Either<Failure, User>> execute(String email, String password) async {
    if (!_isValidEmail(email)) {
      return Left(ValidationFailure('Invalid email'));
    }
    return _repository.login(email, password);
  }
}
```

### Error handling with Either (dartz or fpdart)

- Domain expresses failure as a type (`Either<Failure, T>`)
- Adapters translate low-level exceptions to `Failure`
- UI consumes the result

### Dependency Injection (get_it + injectable)

```dart
@module
abstract class AppModule {
  @lazySingleton
  Dio dio() => Dio();

  @lazySingleton
  AuthRepository authRepository(AuthRemoteDataSource ds) =>
      AuthRepositoryImpl(ds);
}
```

---

## Testing standards

### Pyramid

| Layer | Tool | Coverage by mode |
|-------|------|------------------|
| Unit (domain + use cases) | flutter_test + mocktail | MVP ≥60% critical / Production ≥95% critical |
| BLoC | bloc_test | Production ≥80% |
| Widget | flutter_test | MVP ≥50% / Production ≥80% |
| Integration | integration_test | Critical happy paths |
| Golden tests | flutter_test (matchesGoldenFile) | Critical visual components |

### Structure

```
test/
├── core/
├── features/
│   └── auth/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── helpers/                            # test utilities, mocks

integration_test/
├── auth_flow_test.dart
└── checkout_flow_test.dart
```

### Mocktail (preferred over mockito)

```dart
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  test('returns User on success', () async {
    when(() => repository.login(any(), any()))
        .thenAnswer((_) async => Right(testUser));

    final result = await useCase.execute('a@b.com', 'pass');

    expect(result.isRight(), true);
  });
}
```

---

## Accessibility (WCAG 2.1 AA)

- **Semantics widget** for screen readers (TalkBack, VoiceOver)
- **Tap targets** minimum 48x48 (Material) / 44x44 (Cupertino)
- Minimum contrast 4.5:1
- Support system font size (`MediaQuery.textScaleFactor`)
- Don't rely on color alone for information
- Test with TalkBack/VoiceOver in critical features
- `excludeSemantics: false` in decorative widgets

```dart
Semantics(
  label: 'Add new task',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.add),
    onPressed: _onAdd,
  ),
)
```

---

## Internationalization (Flutter Localizations)

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

```json
// lib/l10n/app_en.arb
{
  "greeting": "Hello, {name}!",
  "@greeting": {
    "placeholders": { "name": { "type": "String" } }
  }
}
```

### Rules

- **No hardcoded strings** in widgets
- Versioned ARB files
- Languages declared in PRD
- RTL via `Directionality` (natively supported)

---

## Design Tokens and Theme

```dart
class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    textTheme: AppTextStyles.textTheme,
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}
```

- Tokens centralized in `core/theme/`
- In multi-platform projects (Web + Mobile), tokens come from a single source (Style Dictionary) — Mobile validates parity
- Nothing hardcoded in widgets

---

## Performance

### Targets (required)

- **60fps** in critical lists and animations
- **No perceptible jank** on reference device (mid-range Android and iOS)
- **App start** ≤ 2s cold on mid-range device

### Techniques

- **`const` constructors** in every widget that can be const
- **`ListView.builder`** or `SliverList` for long lists (lazy)
- **`cached_network_image`** with disk cache
- **Correct image resize** (don't download 4K to display 200x200)
- **Animations** via `AnimationController` or `flutter_animate`
- **Avoid rebuild waste** — use `BlocSelector`, `select` in Riverpod, `const` widgets
- **Profile mode** to measure real performance (`flutter run --profile`)
- **DevTools Performance** to identify jank

---

## Feature Flags (offline-aware)

See `.claude/squad/template/memory/ADR/ADR-003-feature-flags.md` and `.claude/squad/template/agents/mobile-engineer.md`.

- Persistent local cache (shared_preferences or flutter_secure_storage)
- Reasonable TTL + use cache if offline
- Deterministic fallback
- Default-deny in critical features if flag unavailable
- Consider minimum app version (old flags in non-updatable old apps)
- Provider SDK (LaunchDarkly Flutter SDK)

---

## Stack-specific security

- **flutter_secure_storage** for tokens (Keychain/EncryptedSharedPreferences)
- **Certificate pinning** in production (dio_certificate_pinning)
- **Obfuscation** in release build (`flutter build --obfuscate --split-debug-info=...`)
- **No screenshots** on sensitive screens (`SystemChrome.setEnabledSystemUIMode`)
- **Root/jailbreak detection** in financial apps (flutter_jailbreak_detection)
- **Don't** log sensitive data
- **Input validation** in forms before sending
- **Dependency check** with `flutter pub outdated --mode=null-safety`
- **HTTPS only** (don't allow cleartext in iOS Info.plist and Android network_security_config.xml)

---

## Standard commands

```bash
# install
flutter pub get

# code generation
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs

# i18n
flutter gen-l10n

# dev
flutter run                              # debug
flutter run --profile                    # profile (real perf)
flutter run --release                    # local release

# test
flutter test                             # unit + widget
flutter test --coverage                  # with coverage
flutter test integration_test/           # integration

# lint + format
dart format .
dart analyze

# build
flutter build apk --release --obfuscate --split-debug-info=build/symbols
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
flutter build ios --release --obfuscate --split-debug-info=build/symbols

# CI
flutter pub get && \
flutter analyze && \
flutter test --coverage && \
dart format --set-exit-if-changed .
```

---

## Anti-patterns (block)

- Business logic inside widget (extract to BLoC/use case)
- `setState` in large features (use BLoC/Riverpod)
- Async `BuildContext` (after `await` without checking `mounted`)
- Hardcoded text
- Hardcoded colors and spacings
- `print()` in production code (use logger)
- Force unwrap (`!`) without need
- Long lists without `ListView.builder`
- Large images without resize
- StatefulWidget when StatelessWidget suffices
- Missing `const` on candidate widgets
- Importing UI package in domain
- Memory leaks (listeners not disposed, controllers not disposed)
- Tap target < 48px

---

## References

- Flutter: <https://docs.flutter.dev/>
- Dart: <https://dart.dev/guides>
- BLoC: <https://bloclibrary.dev/>
- Riverpod: <https://riverpod.dev/>
- go_router: <https://pub.dev/packages/go_router>
- Effective Dart: <https://dart.dev/effective-dart>
- Very Good Analysis: <https://pub.dev/packages/very_good_analysis>
- Flutter Performance: <https://docs.flutter.dev/perf>
