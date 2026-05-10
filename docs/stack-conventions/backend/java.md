# Stack Convention — Java

> Frameworks suportados: **Spring Boot** (preferencial — ecosistema enterprise) ou **Quarkus** (cloud-native, startup rápido, GraalVM).

---

## Quando usar esta stack

Escolher Java quando:

- **Sistemas enterprise** com requisitos rigorosos (banking, telco, healthcare)
- **Alta concorrência** com modelo de threads maduro (Virtual Threads no Java 21+)
- **Ecosistema Spring** crítico (Spring Security, Spring Data, Spring Cloud)
- **Time já experiente em JVM** — pool de devs vasto
- **Integrações complexas** com legado (mainframes, ESBs, sistemas SOAP)
- **Backends de longa vida** com manutenção de 5+ anos
- **Apps que rodam on-premise** com restrições de cloud
- **Necessidade de strong typing rígido** com generics expressivos

## Quando NÃO usar

- **Startup ultra-rápido** (lambdas, edge) — preferir Go ou Java com GraalVM Native Image
- **AI/ML** — Python domina
- **Prototipagem rápida** — boilerplate alto vs Python/Node.js
- **Memória extremamente limitada** — JVM consome bastante (mitigado por Native Image)
- **Times pequenos sem experiência JVM** — overhead de aprendizado significativo

---

## Versões e dependências

| Item | Versão mínima |
|------|---------------|
| Java | ≥ 21 LTS (preferencial 21+ para Virtual Threads) |
| Build tool | Maven ≥ 3.9 ou Gradle ≥ 8.5 (Kotlin DSL preferencial) |
| Spring Boot | ≥ 3.3 |
| Quarkus | ≥ 3.10 |

### Frameworks

| Framework | Quando usar |
|-----------|-------------|
| **Spring Boot** | Default — ecosistema mais rico (Security, Data, Cloud, Integration) |
| **Quarkus** | Cloud-native, startup ultra-rápido, GraalVM Native Image |
| **Micronaut** | Alternativa moderna a Spring com compile-time DI |

### Bibliotecas padrão

| Necessidade | Biblioteca |
|-------------|-----------|
| ORM | Spring Data JPA + Hibernate ou Spring Data JDBC |
| Migrations | Flyway (preferencial) ou Liquibase |
| Validação | Bean Validation (Hibernate Validator) |
| HTTP client | RestClient (Spring 6.1+) ou WebClient (reativo) ou OpenFeign |
| Logging | SLF4J + Logback |
| Testing | JUnit 5 + Mockito + AssertJ + Testcontainers |
| Tracing/Metrics | Micrometer + OpenTelemetry |
| Auth | Spring Security + JWT (jjwt ou nimbus-jose-jwt) |
| Queue | Spring AMQP (RabbitMQ), Spring Kafka |
| Cache | Spring Cache + Caffeine ou Redis |
| Mapping | MapStruct (preferencial sobre reflexão) |

---

## Tooling obrigatório

| Tool | Propósito |
|------|-----------|
| **SpotBugs** ou **ErrorProne** | Static analysis |
| **Checkstyle** | Code style |
| **PMD** | Code quality |
| **JaCoCo** | Cobertura de testes |
| **Spotless** | Formatter (Google Java Format) |
| **OWASP Dependency-Check** | CVE scanning |

### build.gradle.kts mínimo

```kotlin
plugins {
    id("org.springframework.boot") version "3.3.0"
    id("io.spring.dependency-management") version "1.1.5"
    id("com.diffplug.spotless") version "6.25.0"
    id("org.owasp.dependencycheck") version "9.2.0"
    java
    jacoco
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

spotless {
    java {
        googleJavaFormat()
        removeUnusedImports()
    }
}

tasks.test {
    useJUnitPlatform()
    finalizedBy(tasks.jacocoTestReport)
}

jacoco {
    toolVersion = "0.8.12"
}
```

---

## Layout do projeto (Hexagonal)

### Spring Boot

```
src/main/java/com/company/app/
├── domain/                          # núcleo
│   ├── user/
│   │   ├── model/                   # entities, value objects
│   │   ├── port/                    # interfaces (UserRepository, etc.)
│   │   └── service/                 # serviços de domínio
│   └── order/
│       └── ...
│
├── application/
│   └── usecase/
│       ├── CreateUserUseCase.java
│       └── UpdateUserUseCase.java
│
├── adapter/
│   ├── inbound/
│   │   ├── rest/                    # @RestController
│   │   ├── messaging/               # @KafkaListener / @RabbitListener
│   │   └── grpc/
│   │
│   └── outbound/
│       ├── persistence/             # JpaRepository implementations
│       ├── http/                    # external API clients
│       └── messaging/               # producers
│
├── infrastructure/
│   ├── config/                      # @Configuration classes
│   ├── security/
│   ├── observability/
│   └── exception/                   # GlobalExceptionHandler
│
└── Application.java                 # @SpringBootApplication
```

### Configuração de DI

- Constructor injection **obrigatória** (evitar `@Autowired` em fields)
- `@Bean` em config classes para wirings explícitos quando necessário
- `@Primary`, `@Qualifier` para múltiplas implementações

---

## Convenções de código

### Naming (Google Java Style)

- **PascalCase** para classes, interfaces, enums
- **camelCase** para métodos, variáveis
- **UPPER_SNAKE_CASE** para constantes (`static final`)
- Pacotes em **lowercase** sem underscore

### Records para DTOs (Java 14+)

```java
public record CreateUserRequest(
    @NotBlank @Email String email,
    @NotBlank @Size(max = 255) String name
) {}

public record UserResponse(
    UUID id,
    String email,
    String name,
    Instant createdAt
) {}
```

### Imutabilidade

- `final` em variáveis locais e parâmetros (Spotless pode forçar)
- Records para Value Objects e DTOs
- `Collections.unmodifiableList()` ou `List.copyOf()` para coleções imutáveis
- Builders (Lombok `@Builder` ou Records com builders) para entidades complexas

### Optional para retornos nullable

```java
public Optional<User> findById(UUID id) { ... }

// uso correto
userRepository.findById(id)
    .map(this::toResponse)
    .orElseThrow(() -> new NotFoundException("user not found"));

// NUNCA: optional.get() sem ifPresent/orElse
```

### Streams idiomáticos

```java
List<UserResponse> active = users.stream()
    .filter(User::isActive)
    .map(this::toResponse)
    .toList();                                   // Java 16+
```

### Error handling

- **Checked exceptions** apenas para casos onde caller PRECISA tratar
- **RuntimeException** para erros de domínio (`DomainException`, `NotFoundException`)
- `@RestControllerAdvice` ou `@ControllerAdvice` global para tradução em HTTP
- **Nunca** `catch (Exception e)` sem rethrow ou ação clara
- Não engolir InterruptedException — sempre `Thread.currentThread().interrupt()`

### Validação

- Bean Validation (`@Valid`, `@NotNull`, `@Email`, etc.) no controller
- Custom validators para regras complexas
- Domain re-valida invariantes

```java
@PostMapping
public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
    User user = createUserUseCase.execute(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(user));
}
```

---

## Padrão de testes

### Pirâmide

| Camada | Ferramenta | Cobertura por modo |
|--------|-----------|--------------------|
| Unit (domain + use cases) | JUnit 5 + Mockito + AssertJ | MVP ≥60% críticas / Production ≥95% críticas |
| Integration (adapters + DB) | @SpringBootTest + Testcontainers | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | RestAssured ou MockMvc | Happy paths críticos |
| Architecture | ArchUnit | Aderência a Hexagonal |
| Load | JMeter ou Gatling | Production: NFRs do PRD |

### ArchUnit para enforçar Hexagonal

```java
@AnalyzeClasses(packages = "com.company.app")
class ArchitectureTest {

    @ArchTest
    static final ArchRule domain_does_not_depend_on_infrastructure =
        noClasses().that().resideInAPackage("..domain..")
            .should().dependOnClassesThat().resideInAPackage("..infrastructure..");
}
```

### Testcontainers obrigatório para integration tests

```java
@Testcontainers
@SpringBootTest
class UserRepositoryIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
    }
}
```

---

## Migrations

### Flyway

```bash
# pasta padrão: src/main/resources/db/migration
# nomenclatura: V1__init.sql, V2__add_users_table.sql

./gradlew flywayMigrate
./gradlew flywayInfo
./gradlew flywayValidate
```

### Regras

- Toda migration **forward-only** em Production (preferencial)
- **Expand-contract** em breaking changes (sem `down`, mas planejado em fases)
- Backup confirmado antes de migration destrutiva
- Migration testada em staging com volume realista
- Migration > 5min → janela de manutenção ou online schema change (gh-ost, pt-online-schema-change)

---

## Logging e Observabilidade

### SLF4J + Logback estruturado (JSON em produção)

```java
private static final Logger log = LoggerFactory.getLogger(UserService.class);

log.info("user_created", kv("userId", user.getId()), kv("email", user.getEmail()));
```

### Regras

- Sempre estruturado (JSON em produção)
- Correlation ID via Spring Cloud Sleuth ou MDC
- Nunca logar dados sensíveis
- Micrometer + OpenTelemetry para tracing/metrics em Production
- Actuator endpoints expostos em rede interna (`/actuator/health`, `/actuator/metrics`)

---

## Performance

- **Virtual Threads** (Java 21) para I/O-heavy workloads
- **Connection pooling** via HikariCP (default Spring Boot — ajustar `maximum-pool-size`)
- Cache via Spring Cache + Caffeine (in-memory) ou Redis (distribuído)
- **Async** via `@Async` ou `CompletableFuture` para tarefas paralelas
- Profiling: JFR (Java Flight Recorder), async-profiler, VisualVM
- **GraalVM Native Image** (Spring Boot 3+ ou Quarkus) para startup sub-segundo

---

## Segurança específica

- **Spring Security** obrigatório em APIs
- BCrypt ou Argon2 para senhas (Spring Security `PasswordEncoder`)
- JWT validation com biblioteca estabelecida (jjwt, nimbus-jose-jwt)
- CORS configurado explicitamente (nunca `*` com auth)
- CSRF habilitado em apps com session (desabilitar apenas em APIs stateless com token)
- OWASP Dependency-Check na pipeline
- Headers de segurança via Spring Security
- SQL Injection: JPA parametriza — **nunca** concatenar com `Query` nativa
- XXE: desabilitar processamento de DTD/external entities em parsers XML

---

## Comandos padrão

### Gradle

```bash
# build
./gradlew build                              # compile + test + jar

# dev
./gradlew bootRun

# test
./gradlew test                               # unit
./gradlew integrationTest                    # se separado
./gradlew jacocoTestReport                   # cobertura

# lint
./gradlew spotlessCheck
./gradlew spotlessApply
./gradlew check                              # roda spotless + tests + checkstyle

# migrations
./gradlew flywayMigrate

# CVE scan
./gradlew dependencyCheckAnalyze

# CI
./gradlew clean check jacocoTestReport
```

### Maven

```bash
mvn clean verify
mvn spring-boot:run
mvn test
mvn flyway:migrate
mvn dependency-check:check
```

---

## Anti-patterns (bloquear)

- Field injection (`@Autowired` em fields) — usar constructor injection
- `null` retornado quando o esperado é entidade — usar `Optional` ou lançar exception
- Mutable static state
- Captura de `Exception` sem rethrow
- Domínio importando JPA/Spring (poluição de framework no core)
- Lógica de negócio em controller
- Repositório retornando entidade JPA cru (mapear para entity de domínio)
- Lazy loading sem cuidado (LazyInitializationException)
- N+1 queries (usar `JOIN FETCH` ou `@EntityGraph`)
- `System.out.println` em código de produção
- `Thread.sleep()` em handlers (use async)
- Servlet APIs no domain
- Engolir InterruptedException sem `Thread.currentThread().interrupt()`

---

## Referências

- Java: <https://docs.oracle.com/en/java/javase/21/>
- Spring Boot: <https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/>
- Quarkus: <https://quarkus.io/guides/>
- ArchUnit: <https://www.archunit.org/userguide/html/000_Index.html>
- Google Java Style: <https://google.github.io/styleguide/javaguide.html>
- Effective Java (Joshua Bloch) — referência canônica
