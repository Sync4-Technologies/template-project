# Stack Convention — Java

> Supported frameworks: **Spring Boot** (preferred — enterprise ecosystem) or **Quarkus** (cloud-native, fast startup, GraalVM).

---

## When to use this stack

Choose Java when:

- **Enterprise systems** with stringent requirements (banking, telco, healthcare)
- **High concurrency** with mature thread model (Virtual Threads in Java 21+)
- **Critical Spring ecosystem** (Spring Security, Spring Data, Spring Cloud)
- **Team experienced in JVM** — vast developer pool
- **Complex integrations** with legacy (mainframes, ESBs, SOAP systems)
- **Long-lived backends** with 5+ years of maintenance
- **On-premise apps** with cloud restrictions
- **Need for rigorous strong typing** with expressive generics

## When NOT to use

- **Ultra-fast startup** (lambdas, edge) — prefer Go or Java with GraalVM Native Image
- **AI/ML** — Python dominates
- **Fast prototyping** — high boilerplate vs Python/Node.js
- **Extremely limited memory** — JVM consumes a lot (mitigated by Native Image)
- **Small teams without JVM experience** — significant learning overhead

---

## Versions and dependencies

| Item | Minimum version |
|------|-----------------|
| Java | ≥ 21 LTS (prefer 21+ for Virtual Threads) |
| Build tool | Maven ≥ 3.9 or Gradle ≥ 8.5 (Kotlin DSL preferred) |
| Spring Boot | ≥ 3.3 |
| Quarkus | ≥ 3.10 |

### Frameworks

| Framework | When to use |
|-----------|-------------|
| **Spring Boot** | Default — richest ecosystem (Security, Data, Cloud, Integration) |
| **Quarkus** | Cloud-native, ultra-fast startup, GraalVM Native Image |
| **Micronaut** | Modern Spring alternative with compile-time DI |

### Standard libraries

| Need | Library |
|------|---------|
| ORM | Spring Data JPA + Hibernate or Spring Data JDBC |
| Migrations | Flyway (preferred) or Liquibase |
| Validation | Bean Validation (Hibernate Validator) |
| HTTP client | RestClient (Spring 6.1+) or WebClient (reactive) or OpenFeign |
| Logging | SLF4J + Logback |
| Testing | JUnit 5 + Mockito + AssertJ + Testcontainers |
| Tracing/Metrics | Micrometer + OpenTelemetry |
| Auth | Spring Security + JWT (jjwt or nimbus-jose-jwt) |
| Queue | Spring AMQP (RabbitMQ), Spring Kafka |
| Cache | Spring Cache + Caffeine or Redis |
| Mapping | MapStruct (preferred over reflection) |

---

## Required tooling

| Tool | Purpose |
|------|---------|
| **SpotBugs** or **ErrorProne** | Static analysis |
| **Checkstyle** | Code style |
| **PMD** | Code quality |
| **JaCoCo** | Test coverage |
| **Spotless** | Formatter (Google Java Format) |
| **OWASP Dependency-Check** | CVE scanning |

### Minimum build.gradle.kts

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

## Project layout (Hexagonal)

### Spring Boot

```
src/main/java/com/company/app/
├── domain/                          # core
│   ├── user/
│   │   ├── model/                   # entities, value objects
│   │   ├── port/                    # interfaces (UserRepository, etc.)
│   │   └── service/                 # domain services
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

### DI configuration

- Constructor injection **mandatory** (avoid `@Autowired` on fields)
- `@Bean` in config classes for explicit wirings when needed
- `@Primary`, `@Qualifier` for multiple implementations

---

## Code conventions

### Naming (Google Java Style)

- **PascalCase** for classes, interfaces, enums
- **camelCase** for methods, variables
- **UPPER_SNAKE_CASE** for constants (`static final`)
- Packages **lowercase** without underscores

### Records for DTOs (Java 14+)

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

### Immutability

- `final` on local variables and parameters (Spotless can enforce)
- Records for Value Objects and DTOs
- `Collections.unmodifiableList()` or `List.copyOf()` for immutable collections
- Builders (Lombok `@Builder` or Records with builders) for complex entities

### Optional for nullable returns

```java
public Optional<User> findById(UUID id) { ... }

// correct usage
userRepository.findById(id)
    .map(this::toResponse)
    .orElseThrow(() -> new NotFoundException("user not found"));

// NEVER: optional.get() without ifPresent/orElse
```

### Idiomatic streams

```java
List<UserResponse> active = users.stream()
    .filter(User::isActive)
    .map(this::toResponse)
    .toList();                                   // Java 16+
```

### Error handling

- **Checked exceptions** only when caller MUST handle them
- **RuntimeException** for domain errors (`DomainException`, `NotFoundException`)
- Global `@RestControllerAdvice` or `@ControllerAdvice` for HTTP translation
- **Never** `catch (Exception e)` without rethrow or clear action
- Don't swallow InterruptedException — always `Thread.currentThread().interrupt()`

### Validation

- Bean Validation (`@Valid`, `@NotNull`, `@Email`, etc.) in the controller
- Custom validators for complex rules
- Domain re-validates invariants

```java
@PostMapping
public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
    User user = createUserUseCase.execute(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(user));
}
```

---

## Testing standards

### Pyramid

| Layer | Tool | Coverage by mode |
|-------|------|------------------|
| Unit (domain + use cases) | JUnit 5 + Mockito + AssertJ | MVP ≥60% critical / Production ≥95% critical |
| Integration (adapters + DB) | @SpringBootTest + Testcontainers | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | RestAssured or MockMvc | Critical happy paths |
| Architecture | ArchUnit | Hexagonal compliance |
| Load | JMeter or Gatling | Production: PRD NFRs |

### ArchUnit to enforce Hexagonal

```java
@AnalyzeClasses(packages = "com.company.app")
class ArchitectureTest {

    @ArchTest
    static final ArchRule domain_does_not_depend_on_infrastructure =
        noClasses().that().resideInAPackage("..domain..")
            .should().dependOnClassesThat().resideInAPackage("..infrastructure..");
}
```

### Testcontainers required for integration tests

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
# default folder: src/main/resources/db/migration
# naming: V1__init.sql, V2__add_users_table.sql

./gradlew flywayMigrate
./gradlew flywayInfo
./gradlew flywayValidate
```

### Rules

- Every migration **forward-only** in Production (preferred)
- **Expand-contract** for breaking changes (no `down`, but planned in phases)
- Backup confirmed before destructive migration
- Migration tested on staging with realistic volume
- Migration > 5min → maintenance window or online schema change (gh-ost, pt-online-schema-change)

---

## Logging and Observability

### Structured SLF4J + Logback (JSON in production)

```java
private static final Logger log = LoggerFactory.getLogger(UserService.class);

log.info("user_created", kv("userId", user.getId()), kv("email", user.getEmail()));
```

### Rules

- Always structured (JSON in production)
- Correlation ID via Spring Cloud Sleuth or MDC
- Never log sensitive data
- Micrometer + OpenTelemetry for tracing/metrics in Production
- Actuator endpoints exposed on internal network (`/actuator/health`, `/actuator/metrics`)

---

## Performance

- **Virtual Threads** (Java 21) for I/O-heavy workloads
- **Connection pooling** via HikariCP (Spring Boot default — tune `maximum-pool-size`)
- Cache via Spring Cache + Caffeine (in-memory) or Redis (distributed)
- **Async** via `@Async` or `CompletableFuture` for parallel tasks
- Profiling: JFR (Java Flight Recorder), async-profiler, VisualVM
- **GraalVM Native Image** (Spring Boot 3+ or Quarkus) for sub-second startup

---

## Stack-specific security

- **Spring Security** required in APIs
- BCrypt or Argon2 for passwords (Spring Security `PasswordEncoder`)
- JWT validation via established library (jjwt, nimbus-jose-jwt)
- CORS configured explicitly (never `*` with auth)
- CSRF enabled in apps with sessions (disable only in stateless APIs with token)
- OWASP Dependency-Check in pipeline
- Security headers via Spring Security
- SQL Injection: JPA parameterizes — **never** concatenate with native `Query`
- XXE: disable DTD/external entity processing in XML parsers

---

## Standard commands

### Gradle

```bash
# build
./gradlew build                              # compile + test + jar

# dev
./gradlew bootRun

# test
./gradlew test                               # unit
./gradlew integrationTest                    # if separate
./gradlew jacocoTestReport                   # coverage

# lint
./gradlew spotlessCheck
./gradlew spotlessApply
./gradlew check                              # spotless + tests + checkstyle

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

## Anti-patterns (block)

- Field injection (`@Autowired` on fields) — use constructor injection
- `null` returned when an entity is expected — use `Optional` or throw exception
- Mutable static state
- Catching `Exception` without rethrow
- Domain importing JPA/Spring (framework pollution in core)
- Business logic in controller
- Repository returning raw JPA entity (map to domain entity)
- Lazy loading without care (LazyInitializationException)
- N+1 queries (use `JOIN FETCH` or `@EntityGraph`)
- `System.out.println` in production code
- `Thread.sleep()` in handlers (use async)
- Servlet APIs in the domain
- Swallowing InterruptedException without `Thread.currentThread().interrupt()`

---

## References

- Java: <https://docs.oracle.com/en/java/javase/21/>
- Spring Boot: <https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/>
- Quarkus: <https://quarkus.io/guides/>
- ArchUnit: <https://www.archunit.org/userguide/html/000_Index.html>
- Google Java Style: <https://google.github.io/styleguide/javaguide.html>
- Effective Java (Joshua Bloch) — canonical reference
