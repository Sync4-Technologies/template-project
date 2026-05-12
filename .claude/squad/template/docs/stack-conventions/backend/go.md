# Stack Convention — Go

> Supported frameworks: **Gin** (preferred — most adopted), **Echo** (idiomatic alternative), **Chi** (minimalist), or **plain net/http** (tiny microservices).

---

## When to use this stack

Choose Go when:

- **Performance-critical** — high throughput, low latency (P99 ms)
- **Microservices** — fast startup, low footprint, single binary
- **Massive concurrency** — goroutines + channels are a sweet spot
- **Infra tooling** — CLIs, daemons, agents, sidecars (Docker, Kubernetes, Terraform are all Go)
- **Strict memory limits** — efficient GC, no JVM overhead
- **gRPC services** — protobuf + Go is a natural combination
- **Cloud-native** — Kubernetes, Prometheus, Helm — all Go
- **High-traffic APIs** — fast as Node, more predictable
- **Single-binary deploys** — no runtime, no external deps

## When NOT to use

- **AI/ML** — Python ecosystem dominates
- **CRUD-dense with Admin UI** — Go is verbose for CRUD; Laravel/Rails win on productivity
- **Team without concurrent systems experience** — misused goroutines become race conditions
- **Niche library ecosystem** — Java/Python often have more mature options
- **Very rich domain modeling** — Go lacks expressive generics (improved in 1.18+ but still limited)

---

## Versions and dependencies

| Item | Minimum version |
|------|-----------------|
| Go | ≥ 1.22 (prefer 1.23+) |
| go modules | native |

### Frameworks

| Framework | When to use |
|-----------|-------------|
| **Gin** | REST APIs, rich middleware, larger community |
| **Echo** | Idiomatic alternative, similar performance |
| **Chi** | Minimalist, aligned with `net/http` |
| **Fiber** | Inspired by Express; performance via fasthttp (non-stdlib) |
| **net/http** | Tiny microservices, maximum control |

### Standard libraries

| Need | Library |
|------|---------|
| ORM/Query | sqlc (preferred — generates code), GORM (full ORM), or sqlx |
| Migrations | golang-migrate (preferred), goose, atlas |
| Validation | go-playground/validator |
| HTTP client | native net/http (sufficient) or resty |
| Logging | log/slog (stdlib Go 1.21+) or zerolog |
| Testing | testing (stdlib) + testify/assert + testcontainers-go |
| Tracing/Metrics | OpenTelemetry Go SDK |
| Auth | golang-jwt/jwt/v5 |
| Queue | NATS, RabbitMQ (rabbitmq/amqp091-go), Kafka (segmentio/kafka-go) |
| Cache | go-redis/redis/v9 |
| DI | wire (preferred — compile-time) or fx (runtime) |
| Mock | gomock or mockery |

---

## Required tooling

| Tool | Purpose |
|------|---------|
| **gofmt** + **goimports** | Formatter (non-negotiable) |
| **golangci-lint** | Meta-linter (config with 30+ linters) |
| **go vet** | Static analysis (built-in) |
| **staticcheck** | Advanced linter (included in golangci-lint) |
| **govulncheck** | CVE scanning (official) |
| **gocyclo** | Cyclomatic complexity |

### Minimum .golangci.yml

```yaml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gofmt
    - goimports
    - revive
    - gosec
    - bodyclose
    - sqlclosecheck
    - errorlint
    - exhaustive
    - gocyclo

linters-settings:
  gocyclo:
    min-complexity: 15
  errcheck:
    check-type-assertions: true
```

---

## Project layout (Hexagonal)

Adopt `golang-standards/project-layout` adapted to Hexagonal:

```
.
├── cmd/                          # entrypoints (main packages)
│   ├── api/
│   │   └── main.go
│   └── worker/
│       └── main.go
│
├── internal/                     # application-private code
│   ├── domain/                   # core
│   │   ├── user/
│   │   │   ├── user.go           # entity
│   │   │   ├── repository.go     # interface (port)
│   │   │   ├── service.go        # domain service
│   │   │   └── errors.go         # domain errors
│   │   └── order/
│   │       └── ...
│   │
│   ├── application/
│   │   └── usecase/
│   │       ├── create_user.go
│   │       └── update_user.go
│   │
│   ├── adapter/
│   │   ├── inbound/
│   │   │   ├── http/             # Gin handlers
│   │   │   ├── grpc/
│   │   │   └── messaging/
│   │   │
│   │   └── outbound/
│   │       ├── persistence/      # PostgreSQL repos (sqlc/sqlx/gorm)
│   │       ├── httpclient/
│   │       └── messaging/
│   │
│   └── infrastructure/
│       ├── config/
│       ├── logger/
│       ├── observability/
│       └── di/                   # wire generated code
│
├── pkg/                          # exportable code (rare — think carefully)
├── api/                          # protobuf, OpenAPI specs
├── migrations/                   # SQL migrations
├── scripts/                      # build/deploy scripts
└── go.mod
```

### internal package

- `internal/` prevents external code from importing — isolates implementation
- `pkg/` only if it's actually a reusable library

---

## Code conventions

### Naming (idiomatic Go)

- **camelCase** for variables and unexported functions
- **PascalCase** for exported (public)
- **MixedCaps**, not snake_case
- Packages **lowercase** without underscore (`userrepo`, not `user_repo`)
- Method receivers with short initials (`u *User`, not `user *User`)
- Small interfaces with `-er` suffix when it makes sense (`Reader`, `Repository`)

### Idiomatic error handling

```go
// return error as last value
func (s *UserService) Create(ctx context.Context, dto CreateUserDTO) (*User, error) {
    if err := dto.Validate(); err != nil {
        return nil, fmt.Errorf("validate: %w", err)
    }
    user, err := s.repo.Save(ctx, dto)
    if err != nil {
        return nil, fmt.Errorf("save user: %w", err)
    }
    return user, nil
}

// usage: always check error immediately
user, err := svc.Create(ctx, dto)
if err != nil {
    return fmt.Errorf("create user: %w", err)
}
```

### Typed errors via `errors.Is` and `errors.As`

```go
var (
    ErrNotFound      = errors.New("not found")
    ErrAlreadyExists = errors.New("already exists")
)

// caller
if errors.Is(err, ErrNotFound) {
    return c.JSON(404, ...)
}
```

### Mandatory context propagation

- **Every function that does I/O** receives `ctx context.Context` as the first parameter
- Propagate to downstream calls
- Cancellation via `ctx.Done()`

### Goroutines and channels

- **Always** have a clear channel owner (who closes it)
- `sync.WaitGroup` to wait for completion
- `errgroup.Group` (golang.org/x/sync/errgroup) for parallelism with errors
- **Never** leak goroutines (always have a way to terminate)
- Race detector in CI: `go test -race ./...`

### Pointers vs values

- Slices, maps, channels: already reference types — pass by value
- Large structs (>~100 bytes): pass pointer
- Receivers: consistency (all pointers or all values within a struct)
- Small immutable value types: pass by value

### Validation

- `go-playground/validator` for structs in the inbound adapter
- Validation **before** the use case
- Domain re-validates invariants (defense in depth)

```go
type CreateUserRequest struct {
    Email string `json:"email" validate:"required,email"`
    Name  string `json:"name" validate:"required,min=1,max=255"`
}
```

---

## Testing standards

### Pyramid

| Layer | Tool | Coverage by mode |
|-------|------|------------------|
| Unit (domain + use cases) | testing + testify | MVP ≥60% critical / Production ≥95% critical |
| Integration (adapters + DB) | testcontainers-go | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | net/http/httptest | Critical happy paths |
| Race | `go test -race` | Always |
| Load | k6 or vegeta | Production: PRD NFRs |
| Fuzz | `go test -fuzz` (Go 1.18+) | Inputs from external origin |

### Structure

- `*_test.go` next to file (same package — access to unexported)
- External-package tests in `*_test.go` with `package x_test`
- Table-driven tests preferred

```go
func TestUser_Rename(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr error
    }{
        {"valid", "Alice", nil},
        {"empty", "", ErrInvalidName},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            u := &User{}
            err := u.Rename(tt.input)
            if !errors.Is(err, tt.wantErr) {
                t.Errorf("got %v, want %v", err, tt.wantErr)
            }
        })
    }
}
```

---

## Migrations

### golang-migrate

```bash
# create
migrate create -ext sql -dir migrations -seq create_users_table

# apply
migrate -path migrations -database "$DATABASE_URL" up

# revert
migrate -path migrations -database "$DATABASE_URL" down 1
```

### Rules

- Every migration reversible (down tested)
- **Expand-contract** for breaking changes (Production)
- Migrations tested on staging with realistic volume
- Backup confirmed before destructive migration
- Migration > 5min → maintenance window or online schema change

---

## Logging and Observability

### log/slog (stdlib Go 1.21+)

```go
import "log/slog"

logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))

logger.Info("user created", "user_id", user.ID, "email", user.Email)
```

### Rules

- Always structured (JSON in production)
- Correlation ID via context.Context + middleware
- Never log sensitive data
- OpenTelemetry for distributed tracing in Production
- Metrics via Prometheus client (`prometheus/client_golang`)

---

## Performance

- Goroutines are cheap but **not infinite** — use a pool when it makes sense (ants, semaphore)
- **sync.Pool** for reusing expensive objects (buffers, etc.)
- Connection pooling in DB (database/sql does this by default; tune `SetMaxOpenConns`)
- **pprof** for profiling: `import _ "net/http/pprof"` on an internal endpoint
- Benchmarks: `go test -bench=. -benchmem`
- Race detector in CI without fail
- Statically linked single binary: `CGO_ENABLED=0 go build -ldflags="-s -w"`

---

## Stack-specific security

- `govulncheck` in pipeline (official Go)
- `gosec` (included in golangci-lint)
- bcrypt for passwords (`golang.org/x/crypto/bcrypt`)
- JWT via `golang-jwt/jwt/v5` (validate all claims, not only signature)
- CORS via `rs/cors`
- Rate limiting via `ulule/limiter` or custom middleware (token bucket)
- Security headers via middleware
- SQL injection: use prepared statements (`?` placeholders), never `fmt.Sprintf`
- TLS via `crypto/tls` — minimum version 1.2
- Validate all inputs before reaching the domain

---

## Standard commands

```bash
# install deps
go mod download
go mod tidy

# dev (hot reload)
air                                          # github.com/cosmtrek/air

# test
go test ./...                                # all
go test -race ./...                          # with race detector
go test -cover ./...                         # with coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out             # HTML report

# lint + format
gofmt -w .
goimports -w .
golangci-lint run

# vulnerability check
govulncheck ./...

# build
go build -o bin/api ./cmd/api
CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/api ./cmd/api

# migrations
migrate -path migrations -database "$DATABASE_URL" up

# CI
go mod verify && \
gofmt -l . | tee /dev/stderr | (! read) && \
golangci-lint run && \
govulncheck ./... && \
go test -race -cover ./...
```

---

## Anti-patterns (block)

- Ignoring error with `_` without clear reason
- `panic` in production code (only in main for fatal init failures)
- Goroutine without cancellation mechanism (leaks)
- Channel without clear ownership (who closes?)
- Receiving `interface{}` when a concrete type works
- Using `init()` for complex logic (hurts tests)
- `util` or `helpers` package (organize by domain)
- Mutex on exported struct (encapsulate)
- Business logic in HTTP handler
- Importing `database/sql` directly in the domain
- Naming like `MyService`, `IRepository` (verbose, non-idiomatic)
- `time.Sleep` in tests instead of proper synchronization
- Struct embedding to inherit behavior (Go favors explicit composition)

---

## References

- Effective Go: <https://go.dev/doc/effective_go>
- Go Code Review Comments: <https://github.com/golang/go/wiki/CodeReviewComments>
- Standard Go Project Layout: <https://github.com/golang-standards/project-layout>
- Uber Go Style Guide: <https://github.com/uber-go/guide/blob/master/style.md>
- Go by Example: <https://gobyexample.com/>
- golangci-lint: <https://golangci-lint.run/>
