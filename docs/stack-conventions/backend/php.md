# Stack Convention — PHP

> Frameworks suportados: **Laravel** (preferencial para web apps e APIs full-stack) ou **Symfony** (preferencial para projetos enterprise modulares).

---

## Quando usar esta stack

Escolher PHP quando:

- **CMS e e-commerce** — ecosistema maduro (Magento, WooCommerce, Shopware)
- **Apps com Admin/CRUD pesado** — Laravel Nova, Filament aceleram dramaticamente
- **Time já domina PHP** — produtividade alta com Laravel/Symfony
- **Hospedagem barata e vasta** — qualquer shared hosting roda PHP
- **APIs com necessidade de Eloquent/Doctrine ORM** maduro
- **Projetos com prazo agressivo e CRUD denso** — Laravel é "batteries included"
- **Integração com WordPress** ou ecosistemas legados PHP

## Quando NÃO usar

- **Real-time/WebSockets de alto volume** — Node.js/Go superam
- **AI/ML** — ecosistema Python é incomparável
- **Microserviços com altíssima concorrência** — preferir Go
- **Sistemas com necessidade de threads ou concorrência nativa robusta** — workers PHP-FPM têm modelo limitado

---

## Versões e dependências

| Item | Versão mínima |
|------|---------------|
| PHP | ≥ 8.3 (preferencial 8.4 quando estável) |
| Composer | ≥ 2.7 |
| Frameworks: Laravel ≥ 11 | Symfony ≥ 7.1 |

### Frameworks

| Framework | Quando usar |
|-----------|-------------|
| **Laravel** | Projetos web full-stack, APIs com Admin, prototipagem rápida, e-commerce |
| **Symfony** | Projetos enterprise modulares, microserviços, máxima customização |
| **Slim / Lumen** | Microserviços minimalistas (raro hoje em dia) |

### Bibliotecas padrão

| Necessidade | Biblioteca |
|-------------|-----------|
| ORM | Eloquent (Laravel) ou Doctrine (Symfony) |
| Migrations | Laravel Migrations ou Doctrine Migrations |
| Validação | Laravel Validation ou Symfony Validator |
| HTTP client | Guzzle ou Symfony HttpClient |
| Logging | Monolog (padrão de facto) |
| Testing | Pest (preferencial) ou PHPUnit |
| Tracing | OpenTelemetry PHP |
| Auth | Laravel Sanctum/Passport ou LexikJWTAuthenticationBundle |
| Queue | Laravel Queue (Redis/SQS) ou Symfony Messenger |
| Cache | Redis via predis ou phpredis |

---

## Tooling obrigatório

| Tool | Propósito |
|------|-----------|
| **PHPStan** (level 8 ou 9) ou **Psalm** | Static analysis |
| **PHP-CS-Fixer** ou **Laravel Pint** | Formatter (PSR-12) |
| **Rector** | Refactoring automático e upgrades |
| **Pest** ou **PHPUnit** | Test runner |
| **Composer audit** | CVE scanning |

### phpstan.neon mínimo

```yaml
parameters:
  level: 8
  paths:
    - src
    - tests
  treatPhpDocTypesAsCertain: false
```

---

## Layout do projeto (Hexagonal)

### Laravel

```
src/
├── Domain/                      # núcleo
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
│   │   ├── Controllers/         # adapters inbound
│   │   └── Requests/            # form requests (validation)
│   └── Messaging/
│
app/                             # padrão Laravel (mantido para framework)
├── Console/
├── Exceptions/
├── Http/
└── Providers/                   # binding de DI: ports → adapters
```

### Symfony

Symfony naturalmente acomoda Hexagonal:

```
src/
├── Domain/
│   └── ...
├── Application/
│   └── ...
└── Infrastructure/
    ├── Doctrine/
    ├── Http/
    └── Symfony/                # bundles, configs específicas
```

---

## Convenções de código

### Naming (PSR-1, PSR-4, PSR-12)

- **PascalCase** para classes
- **camelCase** para métodos e properties
- **UPPER_SNAKE_CASE** para constantes
- **snake_case** para tabelas e colunas em DB (Eloquent converte)
- 1 classe por arquivo, namespace casado com path

### Strict types obrigatório

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

### Imutabilidade onde possível

- `readonly` properties (PHP 8.1+)
- Value Objects imutáveis
- Entities mutáveis apenas via métodos de domínio

### Type hints em tudo

- Parâmetros, retornos, properties
- Generics via PHPDoc (`@param array<int, User>`) — PHPStan valida

### Error handling

- Exceções tipadas (`DomainException`, `NotFoundException`, `ValidationException`)
- **Nunca** `catch (\Exception $e)` genérico sem rethrow
- Adapter inbound traduz exceção em HTTP (Laravel: handler global; Symfony: ExceptionListener)

### Validação

- Form Requests no Laravel ou Symfony Validator
- Validação **antes** do use case
- Domain re-valida invariantes (defesa em profundidade)

---

## Padrão de testes

### Pirâmide

| Camada | Ferramenta | Cobertura por modo |
|--------|-----------|--------------------|
| Unit (domain + use cases) | Pest/PHPUnit | MVP ≥60% críticas / Production ≥95% críticas |
| Integration (adapters + DB) | Pest + RefreshDatabase | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | Pest + Laravel TestCase | Happy paths críticos |
| Load | k6 | Production: NFRs do PRD |

### Estrutura

```
tests/
├── Unit/
│   └── Domain/
├── Feature/                    # Laravel terminology = integration
│   └── Http/
└── fixtures/
```

### Pest preferencial sobre PHPUnit clássico

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

### Regras

- Toda migration reversível (`down()` testado)
- **Expand-contract** em breaking changes (Production)
- Backup confirmado antes de migration destrutiva
- Foreign keys explícitas
- Migrations testadas em staging com volume realista

---

## Logging e Observabilidade

### Monolog estruturado

```php
use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Monolog\Formatter\JsonFormatter;

$handler = new StreamHandler('php://stdout', Logger::INFO);
$handler->setFormatter(new JsonFormatter());

$logger = new Logger('app');
$logger->pushHandler($handler);
```

### Regras

- Sempre JSON estruturado em produção
- Correlation ID via middleware
- Nunca logar dados sensíveis (use `processors` para redaction)
- OpenTelemetry para tracing em Production
- Métricas via Prometheus PHP exporter ou pushgateway

---

## Performance

- **OPcache** habilitado em produção (obrigatório)
- **Preloading** (PHP 7.4+) para frameworks (Symfony preload, Laravel Octane)
- **Laravel Octane** com Swoole/RoadRunner para cargas altas
- **Workers** múltiplos via PHP-FPM (configurar `pm`)
- Cache via Redis para queries e responses
- Queues (Laravel Queue, Symfony Messenger) para tarefas pesadas
- Profiling: Blackfire ou Tideways

---

## Segurança específica

- **CSRF** ativo (Laravel/Symfony fazem por padrão; manter)
- **XSS**: usar `e()` (Laravel) ou Twig escape (Symfony)
- **SQL Injection**: ORM parametriza — nunca concatenar SQL
- **Mass Assignment**: `$fillable` ou `$guarded` em Eloquent; DTOs em Symfony
- Argon2id para senhas (Laravel/Symfony default)
- `composer audit` na pipeline
- Roave/SecurityAdvisories no composer.json (bloqueia deps com CVE)
- HTTPS obrigatório (force_https em produção)
- Headers de segurança via middleware (`secure_headers/middleware`)

---

## Comandos padrão

### Laravel

```bash
# install
composer install

# dev
php artisan serve

# test
./vendor/bin/pest                           # ou phpunit

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
symfony serve                               # ou php -S
./vendor/bin/pest
./vendor/bin/phpstan analyse
php bin/console doctrine:migrations:migrate
```

---

## Anti-patterns (bloquear)

- Sem `declare(strict_types=1)` em arquivos novos
- `mixed` ou ausência de type hint
- Lógica de negócio em controller
- Eloquent/Doctrine no domain (importar ORM)
- `dd()` ou `var_dump()` em produção
- Mass Assignment sem `$fillable` definido
- Capturar `\Exception` sem rethrow
- Magic methods abusados (`__call`, `__get`)
- Service Container resolvido em runtime no domínio (DI explícita)
- Queries N+1 (usar `with()` em Eloquent, joins em Doctrine)
- `env()` direto fora de configs (em Laravel) — usar `config()`

---

## Referências

- PHP: <https://www.php.net/manual/en/>
- Laravel: <https://laravel.com/docs/>
- Symfony: <https://symfony.com/doc/current/>
- PHPStan: <https://phpstan.org/>
- Pest: <https://pestphp.com/>
- Rector: <https://getrector.com/>
- PSR-12: <https://www.php-fig.org/psr/psr-12/>
