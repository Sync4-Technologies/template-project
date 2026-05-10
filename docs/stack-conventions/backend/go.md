# Stack Convention — Go

> Frameworks suportados: **Gin** (preferencial — mais usado), **Echo** (alternativa idiomática), **Chi** (minimalista) ou **net/http** puro (microserviços minúsculos).

---

## Quando usar esta stack

Escolher Go quando:

- **Performance crítica** — alto throughput, baixa latência (P99 ms)
- **Microserviços** — startup rápido, footprint baixo, single binary
- **Concorrência massiva** — goroutines + channels são sweet spot
- **Tooling de infra** — CLIs, daemons, agents, sidecars (Docker, Kubernetes, Terraform são Go)
- **Sistemas com limites de memória rígidos** — GC eficiente, no JVM overhead
- **gRPC services** — protobuf + Go é combinação natural
- **Cloud-native** — Kubernetes, Prometheus, Helm — todos Go
- **APIs com tráfego massivo** — rápido como Node, mais previsível
- **Single-binary deploys** — sem runtime, sem deps externas

## Quando NÃO usar

- **AI/ML** — ecosistema Python domina
- **CRUD denso com Admin UI** — Go é verboso para CRUD; Laravel/Rails ganham produtividade
- **Time sem experiência em sistemas concorrentes** — goroutines mal usadas viram race conditions
- **Ecosistema de libraries para nicho específico** — Java/Python costumam ter mais opções maduras
- **Domain modeling muito rico** — Go não tem generics expressivos como Java/Scala (melhorou com 1.18+ mas ainda limitado)

---

## Versões e dependências

| Item | Versão mínima |
|------|---------------|
| Go | ≥ 1.22 (preferencial 1.23+) |
| go modules | nativo |

### Frameworks

| Framework | Quando usar |
|-----------|-------------|
| **Gin** | APIs REST, middleware rico, comunidade maior |
| **Echo** | Alternativa idiomática, performance similar |
| **Chi** | Minimalista, alinhado com `net/http` |
| **Fiber** | Inspirado em Express; performance via fasthttp (não-stdlib) |
| **net/http** | Microserviços minúsculos, máximo controle |

### Bibliotecas padrão

| Necessidade | Biblioteca |
|-------------|-----------|
| ORM/Query | sqlc (preferencial — gera código), GORM (full ORM) ou sqlx |
| Migrations | golang-migrate (preferencial), goose, atlas |
| Validação | go-playground/validator |
| HTTP client | net/http nativo (suficiente) ou resty |
| Logging | log/slog (stdlib Go 1.21+) ou zerolog |
| Testing | testing (stdlib) + testify/assert + testcontainers-go |
| Tracing/Metrics | OpenTelemetry Go SDK |
| Auth | golang-jwt/jwt/v5 |
| Queue | NATS, RabbitMQ (rabbitmq/amqp091-go), Kafka (segmentio/kafka-go) |
| Cache | go-redis/redis/v9 |
| DI | wire (preferencial — compile-time) ou fx (runtime) |
| Mock | gomock ou mockery |

---

## Tooling obrigatório

| Tool | Propósito |
|------|-----------|
| **gofmt** + **goimports** | Formatter (não-negociável) |
| **golangci-lint** | Meta-linter (config com 30+ linters) |
| **go vet** | Static analysis (built-in) |
| **staticcheck** | Linter avançado (incluído no golangci-lint) |
| **govulncheck** | CVE scanning (oficial) |
| **gocyclo** | Complexidade ciclomática |

### .golangci.yml mínimo

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

## Layout do projeto (Hexagonal)

Adotar layout `golang-standards/project-layout` adaptado para Hexagonal:

```
.
├── cmd/                          # entrypoints (main packages)
│   ├── api/
│   │   └── main.go
│   └── worker/
│       └── main.go
│
├── internal/                     # código privado da aplicação
│   ├── domain/                   # núcleo
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
├── pkg/                          # código exportável (raro — pensar bem)
├── api/                          # protobuf, OpenAPI specs
├── migrations/                   # SQL migrations
├── scripts/                      # build/deploy scripts
└── go.mod
```

### Internal package

- Pacote `internal/` impede que código externo importe — isola implementação
- `pkg/` apenas se realmente vai ser library reutilizável

---

## Convenções de código

### Naming (idiomático Go)

- **camelCase** para variáveis, funções não-exportadas
- **PascalCase** para exportadas (públicas)
- **MixedCaps**, não snake_case
- Pacotes em **lowercase** sem underscore (`userrepo`, não `user_repo`)
- Receivers de método com inicial curta (`u *User`, não `user *User`)
- Interfaces pequenas com sufixo `-er` quando faz sentido (`Reader`, `Repository`)

### Error handling idiomático

```go
// retornar erro como último valor
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

// uso: sempre verificar erro imediatamente
user, err := svc.Create(ctx, dto)
if err != nil {
    return fmt.Errorf("create user: %w", err)
}
```

### Erros tipados via `errors.Is` e `errors.As`

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

### Context propagation obrigatório

- **Toda função que faz I/O** recebe `ctx context.Context` como primeiro parâmetro
- Propagar para downstream calls
- Cancelamento via `ctx.Done()`

### Goroutines e channels

- **Sempre** ter dono claro do channel (quem fecha)
- `sync.WaitGroup` para esperar conclusão
- `errgroup.Group` (golang.org/x/sync/errgroup) para paralelismo com erro
- **Nunca** vazar goroutines (sempre ter forma de finalizar)
- Race detector em CI: `go test -race ./...`

### Pointers vs values

- Slices, maps, channels: já são reference types — passar por valor
- Structs grandes (>~100 bytes): passar pointer
- Receivers: consistência (todos pointers ou todos values em uma struct)
- Pequenos value types imutáveis: passar por valor

### Validação

- `go-playground/validator` para structs no adapter inbound
- Validação **antes** do use case
- Domain re-valida invariantes (defesa em profundidade)

```go
type CreateUserRequest struct {
    Email string `json:"email" validate:"required,email"`
    Name  string `json:"name" validate:"required,min=1,max=255"`
}
```

---

## Padrão de testes

### Pirâmide

| Camada | Ferramenta | Cobertura por modo |
|--------|-----------|--------------------|
| Unit (domain + use cases) | testing + testify | MVP ≥60% críticas / Production ≥95% críticas |
| Integration (adapters + DB) | testcontainers-go | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | net/http/httptest | Happy paths críticos |
| Race | `go test -race` | Sempre |
| Load | k6 ou vegeta | Production: NFRs do PRD |
| Fuzz | `go test -fuzz` (Go 1.18+) | Inputs com origem externa |

### Estrutura

- `*_test.go` ao lado do arquivo (mesma package — acesso a unexported)
- Testes de package externo em `*_test.go` com `package x_test`
- Table-driven tests preferenciais

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
# criar
migrate create -ext sql -dir migrations -seq create_users_table

# aplicar
migrate -path migrations -database "$DATABASE_URL" up

# reverter
migrate -path migrations -database "$DATABASE_URL" down 1
```

### Regras

- Toda migration reversível (down testado)
- **Expand-contract** em breaking changes (Production)
- Migrations testadas em staging com volume realista
- Backup confirmado antes de migration destrutiva
- Migration > 5min → janela de manutenção ou online schema change

---

## Logging e Observabilidade

### log/slog (stdlib Go 1.21+)

```go
import "log/slog"

logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))

logger.Info("user created", "user_id", user.ID, "email", user.Email)
```

### Regras

- Sempre estruturado (JSON em produção)
- Correlation ID via context.Context + middleware
- Nunca logar dados sensíveis
- OpenTelemetry para tracing distribuído em Production
- Métricas via Prometheus client (`prometheus/client_golang`)

---

## Performance

- Goroutines são baratas mas **não infinitas** — usar pool quando faz sentido (ants, semaphore)
- **sync.Pool** para reuso de objetos caros (buffers, etc.)
- Connection pooling em DB (database/sql faz por padrão; ajustar `SetMaxOpenConns`)
- **pprof** para profiling: `import _ "net/http/pprof"` em endpoint interno
- Benchmarks: `go test -bench=. -benchmem`
- Race detector em CI sem fail
- Single binary statically linked: `CGO_ENABLED=0 go build -ldflags="-s -w"`

---

## Segurança específica

- `govulncheck` na pipeline (oficial Go)
- `gosec` (incluído no golangci-lint)
- bcrypt para senhas (`golang.org/x/crypto/bcrypt`)
- JWT via `golang-jwt/jwt/v5` (validar todos claims, não só assinatura)
- CORS via `rs/cors`
- Rate limiting via `ulule/limiter` ou middleware custom (token bucket)
- Headers de segurança via middleware
- SQL injection: usar prepared statements (`?` placeholders), nunca `fmt.Sprintf`
- TLS via `crypto/tls` — minimum version 1.2
- Validar todos inputs antes de chegar ao domínio

---

## Comandos padrão

```bash
# install deps
go mod download
go mod tidy

# dev (hot reload)
air                                          # github.com/cosmtrek/air

# test
go test ./...                                # tudo
go test -race ./...                          # com race detector
go test -cover ./...                         # com cobertura
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

## Anti-patterns (bloquear)

- Ignorar erro com `_` sem motivo claro
- `panic` em código de produção (apenas em main para fatais de inicialização)
- Goroutine sem mecanismo de cancelamento (vaza)
- Channel sem dono claro (quem fecha?)
- Receber `interface{}` quando tipo concreto serve
- Usar `init()` para lógica complexa (dificulta testes)
- Pacote `util` ou `helpers` (organizar por domínio)
- Mutex em struct exportada (encapsular)
- Lógica de negócio em handler HTTP
- Importar `database/sql` direto no domain
- Nomenclatura como `MyService`, `IRepository` (verboso, não-idiomático)
- `time.Sleep` em testes ao invés de sincronização adequada
- Embedding de struct para herdar comportamento (Go favorece composição explícita)

---

## Referências

- Effective Go: <https://go.dev/doc/effective_go>
- Go Code Review Comments: <https://github.com/golang/go/wiki/CodeReviewComments>
- Standard Go Project Layout: <https://github.com/golang-standards/project-layout>
- Uber Go Style Guide: <https://github.com/uber-go/guide/blob/master/style.md>
- Go by Example: <https://gobyexample.com/>
- golangci-lint: <https://golangci-lint.run/>
