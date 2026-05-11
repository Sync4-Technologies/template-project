# Stack Convention — PHP

> Supported frameworks: **Laravel** (preferred for full-stack web apps and APIs) or **Symfony** (preferred for modular enterprise projects).

---

## When to use this stack

Choose PHP when:

- **CMS and e-commerce** — mature ecosystem (Magento, WooCommerce, Shopware)
- **Apps with heavy Admin/CRUD** — Laravel Nova, Filament dramatically accelerate delivery
- **Team already fluent in PHP** — high productivity with Laravel/Symfony
- **Cheap and widespread hosting** — any shared hosting runs PHP
- **APIs needing mature Eloquent/Doctrine ORM**
- **Aggressive deadline projects with dense CRUD** — Laravel is "batteries included"
- **WordPress integration** or legacy PHP ecosystems

## When NOT to use

- **High-volume real-time/WebSockets** — Node.js/Go outperform
- **AI/ML** — Python ecosystem is incomparable
- **Microservices with extreme concurrency** — prefer Go
- **Systems needing native threads or robust concurrency** — PHP-FPM workers have a limited model

---

## Versions and dependencies

| Item | Minimum version |
|------|-----------------|
| PHP | ≥ 8.3 (prefer 8.4 when stable) |
| Composer | ≥ 2.7 |
| Frameworks: Laravel ≥ 11 | Symfony ≥ 7.1 |

### Frameworks

| Framework | When to use |
|-----------|-------------|
| **Laravel** | Full-stack web projects, APIs with Admin, fast prototyping, e-commerce |
| **Symfony** | Modular enterprise projects, microservices, maximum customization |
| **Slim / Lumen** | Minimalist microservices (rare today) |

### Standard libraries

| Need | Library |
|------|---------|
| ORM | Eloquent (Laravel) or Doctrine (Symfony) |
| Migrations | Laravel Migrations or Doctrine Migrations |
| Validation | Laravel Validation or Symfony Validator |
| HTTP client | Guzzle or Symfony HttpClient |
| Logging | Monolog (de facto standard) |
| Testing | Pest (preferred) or PHPUnit |
| Tracing | OpenTelemetry PHP |
| Auth | Laravel Sanctum/Passport or LexikJWTAuthenticationBundle |
| Queue | Laravel Queue (Redis/SQS) or Symfony Messenger |
| Cache | Redis via predis or phpredis |

---

## Required tooling

| Tool | Purpose |
|------|---------|
| **PHPStan** (level 8 or 9) or **Psalm** | Static analysis |
| **PHP-CS-Fixer** or **Laravel Pint** | Formatter (PSR-12) |
| **Rector** | Automated refactoring and upgrades |
| **Pest** or **PHPUnit** | Test runner |
| **Composer audit** | CVE scanning |

### Minimum phpstan.neon

```yaml
parameters:
  level: 8
  paths:
    - src
    - tests
  treatPhpDocTypesAsCertain: false
```

---

## Project layout (Hexagonal)

### Laravel

```
src/
├── Domain/                      # core
│   ├── User/
│   │   ├── Entity/
│   │   ├── Repository/          # interfaces (ports)
│   │   ├── Service/
│   │   └── Exception/
│   └── Order/
│       └── ...
│
├── Application/
│   └── User/
│       ├── CreateUser/          # use case
│       │   ├── CreateUserUseCase.php
│       │   └── CreateUserDto.php
│       └── UpdateUser/
│
├── Infrastructure/
│   ├── Persistence/
│   │   └── Eloquent/            # Eloquent repositories (impl)
│   ├── Http/
│   │   ├── Controllers/         # inbound adapters
│   │   └── Requests/            # form requests (validation)
│   └── Messaging/
│
app/                             # standard Laravel (kept for framework)
├── Console/
├── Exceptions/
├── Http/
└── Providers/                   # DI binding: ports → adapters
```

### Symfony

Symfony naturally accommodates Hexagonal:

```
src/
├── Domain/
│   └── ...
├── Application/
│   └── ...
└── Infrastructure/
    ├── Doctrine/
    ├── Http/
    └── Symfony/                # bundles, framework-specific configs
```

---

## Code conventions

### Naming (PSR-1, PSR-4, PSR-12)

- **PascalCase** for classes
- **camelCase** for methods and properties
- **UPPER_SNAKE_CASE** for constants
- **snake_case** for DB tables and columns (Eloquent converts)
- 1 class per file, namespace matching path

### Strict types required

```php
<?php

declare(strict_types=1);

namespace App\Domain\User\Entity;

final class User
{
    public function __construct(
        public readonly UserId $id,
        public readonly Email $email,
        private string $name,
    ) {}

    public function rename(string $name): void
    {
        if (trim($name) === '') {
            throw new InvalidNameException();
        }
        $this->name = $name;
    }
}
```

### Immutability where possible

- `readonly` properties (PHP 8.1+)
- Immutable Value Objects
- Entities mutable only via domain methods

### Type hints everywhere

- Parameters, return types, properties
- Generics via PHPDoc (`@param array<int, User>`) — PHPStan validates

### Error handling

- Typed exceptions (`DomainException`, `NotFoundException`, `ValidationException`)
- **Never** generic `catch (\Exception $e)` without rethrow
- Inbound adapter translates exception to HTTP (Laravel: global handler; Symfony: ExceptionListener)

### Validation

- Laravel Form Requests or Symfony Validator
- Validation **before** the use case
- Domain re-validates invariants (defense in depth)

---

## Testing standards

### Pyramid

| Layer | Tool | Coverage by mode |
|-------|------|------------------|
| Unit (domain + use cases) | Pest/PHPUnit | MVP ≥60% critical / Production ≥95% critical |
| Integration (adapters + DB) | Pest + RefreshDatabase | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | Pest + Laravel TestCase | Critical happy paths |
| Load | k6 | Production: PRD NFRs |

### Structure

```
tests/
├── Unit/
│   └── Domain/
├── Feature/                    # Laravel terminology = integration
│   └── Http/
└── fixtures/
```

### Pest preferred over classic PHPUnit

```php
it('creates a user with valid data', function () {
    $useCase = app(CreateUserUseCase::class);

    $user = $useCase->execute(
        new CreateUserDto(email: 'a@b.com', name: 'John')
    );

    expect($user->email->value())->toBe('a@b.com');
});
```

---

## Migrations

### Laravel Migrations

```bash
php artisan make:migration create_users_table
php artisan migrate
php artisan migrate:rollback
```

### Doctrine Migrations (Symfony)

```bash
php bin/console doctrine:migrations:diff
php bin/console doctrine:migrations:migrate
```

### Rules

- Every migration reversible (`down()` tested)
- **Expand-contract** for breaking changes (Production)
- Backup confirmed before destructive migration
- Foreign keys explicit
- Migrations tested on staging with realistic volume

---

## Logging and Observability

### Structured Monolog

```php
use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Monolog\Formatter\JsonFormatter;

$handler = new StreamHandler('php://stdout', Logger::INFO);
$handler->setFormatter(new JsonFormatter());

$logger = new Logger('app');
$logger->pushHandler($handler);
```

### Rules

- Always JSON-structured in production
- Correlation ID via middleware
- Never log sensitive data (use `processors` for redaction)
- OpenTelemetry for tracing in Production
- Metrics via Prometheus PHP exporter or pushgateway

---

## Performance

- **OPcache** enabled in production (mandatory)
- **Preloading** (PHP 7.4+) for frameworks (Symfony preload, Laravel Octane)
- **Laravel Octane** with Swoole/RoadRunner for high loads
- **Multiple workers** via PHP-FPM (configure `pm`)
- Cache via Redis for queries and responses
- Queues (Laravel Queue, Symfony Messenger) for heavy tasks
- Profiling: Blackfire or Tideways

---

## Stack-specific security

- **CSRF** active (Laravel/Symfony default; keep it)
- **XSS:** use `e()` (Laravel) or Twig escape (Symfony)
- **SQL Injection:** ORM parameterizes — never concatenate SQL
- **Mass Assignment:** `$fillable` or `$guarded` in Eloquent; DTOs in Symfony
- Argon2id for passwords (Laravel/Symfony default)
- `composer audit` in pipeline
- Roave/SecurityAdvisories in composer.json (blocks deps with CVEs)
- HTTPS required (force_https in production)
- Security headers via middleware (`secure_headers/middleware`)

---

## Standard commands

### Laravel

```bash
# install
composer install

# dev
php artisan serve

# test
./vendor/bin/pest                           # or phpunit

# lint + analysis
./vendor/bin/pint                           # formatter
./vendor/bin/phpstan analyse                # static analysis
./vendor/bin/rector process --dry-run       # refactor preview

# migrations
php artisan migrate
php artisan migrate:rollback

# CI
composer install && \
./vendor/bin/pint --test && \
./vendor/bin/phpstan analyse && \
./vendor/bin/pest --coverage --min=80
```

### Symfony

```bash
composer install
symfony serve                               # or php -S
./vendor/bin/pest
./vendor/bin/phpstan analyse
php bin/console doctrine:migrations:migrate
```

---

## Anti-patterns (block)

- No `declare(strict_types=1)` in new files
- `mixed` or no type hint
- Business logic in controller
- Eloquent/Doctrine in the domain (importing ORM)
- `dd()` or `var_dump()` in production
- Mass Assignment without `$fillable` defined
- Catching `\Exception` without rethrow
- Abused magic methods (`__call`, `__get`)
- Service Container resolved at runtime in the domain (explicit DI)
- N+1 queries (use `with()` in Eloquent, joins in Doctrine)
- `env()` outside configs (in Laravel) — use `config()`

---

## References

- PHP: <https://www.php.net/manual/en/>
- Laravel: <https://laravel.com/docs/>
- Symfony: <https://symfony.com/doc/current/>
- PHPStan: <https://phpstan.org/>
- Pest: <https://pestphp.com/>
- Rector: <https://getrector.com/>
- PSR-12: <https://www.php-fig.org/psr/psr-12/>
