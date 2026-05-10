# Stack Convention — Flutter (Dart)

> Framework oficial Google para apps multiplataforma com renderização própria (Skia/Impeller) — performance nativa.

---

## Quando usar esta stack

Escolher Flutter quando:

- **Performance nativa é prioridade** — 60fps consistente em listas, animações, transições
- **Código único para iOS + Android** — máximo reúso (90%+)
- **UI customizada e rica** — Flutter renderiza tudo, sem limitações de widgets nativos
- **Animações complexas** — AnimationController, Hero transitions, custom painters
- **Time disposto a aprender Dart** — linguagem fácil mas diferente
- **Multi-plataforma adicional** (Web, Desktop) com mesma codebase
- **Apps com identidade visual única** (não Material/Cupertino padrão)
- **Builds reprodutíveis e CI/CD limpo**
- **Hot reload e DX excelentes**

## Quando NÃO usar

- **Time já experiente em React Native** — sem motivo de mudar
- **Reúso massivo de código JS com web** — RN comparte React/JS
- **Integração profunda com SDKs nativos não cobertos por plugins** — possível mas custoso
- **App pequeno integrado em app nativo existente** — overhead de embedding Flutter
- **Restrições de tamanho de app extremas** — Flutter adiciona ~5MB ao APK

---

## Versões e dependências

| Item | Versão mínima |
|------|---------------|
| Flutter | ≥ 3.22 (preferencial 3.24+) |
| Dart | vem com Flutter (≥ 3.4) |
| Android: minSdkVersion | 21 (Android 5.0) |
| iOS deployment target | 12.0 |

### Bibliotecas padrão

| Necessidade | Biblioteca |
|-------------|-----------|
| State management | **BLoC** (preferencial — escalável) ou **Riverpod** (moderno) |
| Routing | **go_router** (oficial) |
| HTTP | **dio** (preferencial) ou http nativo |
| Validação | dart_either + manual ou form_validator |
| Local storage | **drift** (SQLite ORM tipado) ou **isar** (NoSQL rápido) |
| Key-value | **shared_preferences** (simples) ou **flutter_secure_storage** (sensível) |
| DI | **get_it** + **injectable** (codegen) |
| Testing | flutter_test, mocktail, bloc_test |
| Code gen | freezed (data classes), json_serializable |
| Logging | logger ou talker |
| i18n | **flutter_localizations** + intl + ARB files |
| Feature flags | LaunchDarkly Flutter SDK ou Unleash Proxy |
| Analytics | firebase_analytics ou mixpanel_flutter |
| Crash reporting | sentry_flutter ou firebase_crashlytics |
| Image cache | cached_network_image |
| Animations | flutter_animate (preferencial) |

---

## Tooling obrigatório

| Tool | Propósito |
|------|-----------|
| **dart format** | Formatter (built-in) |
| **dart analyze** | Static analysis (built-in) |
| **very_good_analysis** ou **lints** | Lint rules pack |
| **build_runner** | Code generation (freezed, injectable, drift) |
| **flutter_gen** | Asset generation |
| **flutter_test** | Test runner |
| **integration_test** | E2E |

### analysis_options.yaml mínimo

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

## Layout do projeto (Clean Architecture)

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
│   │   │   └── repositories/            # impl de domain repository
│   │   │
│   │   ├── domain/                      # núcleo da feature
│   │   │   ├── entities/                # entidades de domínio
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
├── shared/                              # widgets/utilities reusados entre features
│   ├── widgets/
│   └── extensions/
│
└── l10n/                                # ARB files (i18n)

test/                                    # unit + widget tests (espelha lib/)
integration_test/                        # E2E
```

### Mapeamento Hexagonal → Clean Architecture mobile

| Hexagonal | Flutter |
|-----------|---------|
| Domain | `features/<f>/domain/` |
| Application (use cases) | `features/<f>/domain/usecases/` |
| Adapters inbound | `features/<f>/presentation/` |
| Adapters outbound | `features/<f>/data/` |

---

## Convenções de código

### Naming (Effective Dart)

- **lowerCamelCase** para variáveis, funções, métodos, parâmetros
- **UpperCamelCase** para classes, enums, typedefs, mixins
- **lowercase_with_underscores** para nomes de arquivo e diretórios
- **SCREAMING_CAPS** apenas para constantes verdadeiramente globais

### Imutabilidade obrigatória em entidades

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

- **Sempre** usar `const` quando possível (otimiza rebuilds)
- Linter `prefer_const_constructors` enforce

### Null safety estrito

- Modo `strict-casts`, `strict-inference`, `strict-raw-types`
- Evitar `!` (force unwrap) — usar guard clauses

```dart
// RUIM
final email = user!.email;

// BOM
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

### Error handling com Either (dartz ou fpdart)

- Domain expressa falha como tipo (`Either<Failure, T>`)
- Adapters traduzem exceptions de baixo nível para `Failure`
- UI consome resultado

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

## Padrão de testes

### Pirâmide

| Camada | Ferramenta | Cobertura por modo |
|--------|-----------|--------------------|
| Unit (domain + use cases) | flutter_test + mocktail | MVP ≥60% críticas / Production ≥95% críticas |
| BLoC | bloc_test | Production ≥80% |
| Widget | flutter_test | MVP ≥50% / Production ≥80% |
| Integration | integration_test | Happy paths críticos |
| Golden tests | flutter_test (matchesGoldenFile) | Componentes visuais críticos |

### Estrutura

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

### Mocktail (preferencial sobre mockito)

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

## Acessibilidade (WCAG 2.1 AA)

- **Semantics widget** para screen readers (TalkBack, VoiceOver)
- **Tap targets** mínimos 48x48 (Material) / 44x44 (Cupertino)
- Contraste mínimo 4.5:1
- Suporte a tamanho de fonte do sistema (`MediaQuery.textScaleFactor`)
- Não depender só de cor para informação
- Teste com TalkBack/VoiceOver em features críticas
- `excludeSemantics: false` em widgets decorativos

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

## Internacionalização (Flutter Localizations)

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

### Regras

- **Nenhuma string hardcoded** em widgets
- ARB files versionados
- Idiomas declarados no PRD
- RTL via `Directionality` (suportado nativo)

---

## Design Tokens e Tema

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

- Tokens centralizados em `core/theme/`
- Em projetos multi-plataforma (Web + Mobile), tokens vêm de fonte única (Style Dictionary) — Mobile valida paridade
- Nada hardcoded em widgets

---

## Performance

### Targets (obrigatório)

- **60fps** em listas e animações críticas
- **Sem jank** perceptível em dispositivo de referência (médio Android e iOS)
- **App start** ≤ 2s frio em dispositivo médio

### Técnicas

- **`const` constructors** em todo widget que pode ser const
- **`ListView.builder`** ou `SliverList` para listas longas (lazy)
- **`cached_network_image`** com cache de disco
- **Image resize** correto (não baixar 4K para mostrar 200x200)
- **Animations** via `AnimationController` ou `flutter_animate`
- **Avoid rebuild waste** — usar `BlocSelector`, `select` em Riverpod, `const` widgets
- **Profile mode** para medir performance real (`flutter run --profile`)
- **DevTools Performance** para identificar jank

---

## Feature Flags (offline-aware)

Ver `memory/ADR/ADR-003-feature-flags.md` e `agents/mobile-engineer.md`.

- Cache local persistente (shared_preferences ou flutter_secure_storage)
- TTL razoável + uso de cache se offline
- Fallback determinístico
- Default-deny em features críticas se flag indisponível
- Considerar versão mínima de app (flags antigas em apps antigos não atualizáveis)
- SDK do provedor (LaunchDarkly Flutter SDK)

---

## Segurança específica

- **flutter_secure_storage** para tokens (Keychain/EncryptedSharedPreferences)
- **Certificate pinning** em produção (dio_certificate_pinning)
- **Obfuscação** no build release (`flutter build --obfuscate --split-debug-info=...`)
- **No screenshots** em telas sensíveis (`SystemChrome.setEnabledSystemUIMode`)
- **Root/jailbreak detection** em apps financeiros (flutter_jailbreak_detection)
- **Não** logar dados sensíveis
- **Validação de input** em forms antes de enviar
- **Dependency check** com `flutter pub outdated --mode=null-safety`
- **HTTPS only** (não permitir cleartext em iOS Info.plist e Android network_security_config.xml)

---

## Comandos padrão

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
flutter run --profile                    # profile (perf real)
flutter run --release                    # release local

# test
flutter test                             # unit + widget
flutter test --coverage                  # com cobertura
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

## Anti-patterns (bloquear)

- Lógica de negócio dentro de widget (extrair para BLoC/use case)
- `setState` em features grandes (use BLoC/Riverpod)
- `BuildContext` async (após `await` sem checar `mounted`)
- Texto hardcoded
- Cores e espaçamentos hardcoded
- `print()` em código de produção (usar logger)
- Force unwrap (`!`) sem necessidade
- Listas longas sem `ListView.builder`
- Imagens grandes sem resize
- StatefulWidget quando StatelessWidget basta
- Falta de `const` em widgets candidatos
- Importar pacote de UI no domain
- Memory leaks (listeners não dispose, controllers não dispose)
- Tap target < 48px

---

## Referências

- Flutter: <https://docs.flutter.dev/>
- Dart: <https://dart.dev/guides>
- BLoC: <https://bloclibrary.dev/>
- Riverpod: <https://riverpod.dev/>
- go_router: <https://pub.dev/packages/go_router>
- Effective Dart: <https://dart.dev/effective-dart>
- Very Good Analysis: <https://pub.dev/packages/very_good_analysis>
- Flutter Performance: <https://docs.flutter.dev/perf>
