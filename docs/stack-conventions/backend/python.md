# Stack Convention — Python

> Frameworks suportados: **FastAPI** (preferencial para APIs e AI/ML) ou **Django** (apps full-stack monolíticos com ORM rico).

---

## Quando usar esta stack

Escolher Python quando:

- **AI/ML pipelines** — ecosistema (PyTorch, TensorFlow, scikit-learn, HuggingFace) é dramaticamente superior
- **Data engineering** — Pandas, Polars, Spark (PySpark), Airflow, dbt, dlt
- **APIs simples e médias** com FastAPI — type hints + Pydantic = excelente DX
- **Integração com modelos LLM** — LangChain, LangGraph, oficiais SDKs (anthropic, openai)
- **Scripts e automações** — sintaxe limpa, ecosistema vasto
- **Notebooks e prototipagem científica** — Jupyter, IPython
- **CMS e dashboards admin** — Django Admin gera interface gratuitamente
- **Time com background científico/dados** — Python é lingua franca

## Quando NÃO usar

- **Concorrência massiva CPU-bound** — GIL limita; preferir Go/Rust
- **Aplicações de altíssimo throughput em I/O** — Node.js/Go performam melhor
- **Sistemas com hard latency budgets** — startup lento, GC imprevisível
- **Compartilhamento de tipos com frontend** — sem TypeScript-like

---

## Versões e dependências

| Item | Versão mínima |
|------|---------------|
| Python | ≥ 3.12 (preferencial 3.13) |
| pip + venv | Substituir por **uv** (preferencial) ou **Poetry** |
| Frameworks: FastAPI ≥ 0.110 | Django ≥ 5.0 |

### Frameworks

| Framework | Quando usar |
|-----------|-------------|
| **FastAPI** | APIs REST/WebSocket, AI/ML services, microserviços |
| **Django** | Apps full-stack com Admin, monolitos com forte modelagem ORM |
| **Litestar** | Alternativa moderna a FastAPI com plugins ricos |

### Bibliotecas padrão

| Necessidade | Biblioteca |
|-------------|-----------|
| ORM | SQLAlchemy 2.x (preferencial) ou Django ORM |
| Migrations | Alembic (preferencial) ou Django Migrations |
| Validação | Pydantic v2 |
| HTTP client | httpx (preferencial sobre requests — async-ready) |
| Logging | structlog ou loguru |
| Testing | pytest + pytest-asyncio + pytest-cov |
| Tracing/Metrics | OpenTelemetry SDK |
| Auth | python-jose (JWT) ou Authlib (OAuth) |
| Queue/Jobs | Celery + Redis ou RQ (mais simples) |
| Cache | redis-py |
| AI/LLM | anthropic, openai, langchain, langgraph |
| Data | pandas, polars |

### Gerenciamento de dependências

- **uv** (preferencial) — extremamente rápido, drop-in para pip
- **Poetry** — alternativa madura
- **Nunca** `pip install` direto — sempre via `pyproject.toml`

---

## Tooling obrigatório

| Tool | Propósito |
|------|-----------|
| **ruff** | Linter + formatter (substitui flake8, black, isort, pyupgrade) |
| **mypy** | Type check (modo strict) |
| **pytest** | Test runner |
| **pytest-cov** | Cobertura |
| **pre-commit** | Hooks pre-commit |

### pyproject.toml mínimo

```toml
[tool.ruff]
target-version = "py312"
line-length = 100
select = ["E", "F", "W", "I", "N", "UP", "S", "B", "A", "C4", "T20", "RET", "SIM"]
ignore = ["S101"]  # asserts em testes

[tool.ruff.format]
quote-style = "double"

[tool.mypy]
python_version = "3.12"
strict = true
disallow_any_generics = true
warn_return_any = true
warn_unused_ignores = true

[tool.pytest.ini_options]
addopts = "--strict-markers --cov=src --cov-report=term-missing --cov-fail-under=80"
testpaths = ["tests"]
asyncio_mode = "auto"
```

---

## Layout do projeto (Hexagonal)

```
src/
├── domain/                      # núcleo
│   ├── entities/                # entidades (dataclass ou Pydantic)
│   ├── ports/                   # protocolos (typing.Protocol) — interfaces
│   └── services/                # serviços de domínio
│
├── application/
│   └── use_cases/               # cada use case = uma classe ou função
│
├── adapters/
│   ├── inbound/
│   │   ├── http/                # FastAPI routers, dependencies
│   │   ├── messaging/           # consumers
│   │   └── cli/                 # Typer commands
│   │
│   └── outbound/
│       ├── persistence/         # SQLAlchemy repositories
│       ├── http_clients/        # httpx clients
│       └── messaging/           # producers
│
├── infrastructure/
│   ├── config/                  # Pydantic Settings
│   ├── logging/
│   ├── observability/
│   └── di/                      # dependency-injector ou manual
│
└── main.py                      # ASGI app factory
```

### Django

Em Django, mapear bounded contexts como **apps**:
- `apps/<context>/domain/` — entidades não-ORM
- `apps/<context>/application/` — use cases
- `apps/<context>/adapters/` — views, repositories, models (Django ORM aqui)
- `apps/<context>/admin.py`, `urls.py` — config Django

---

## Convenções de código

### Naming

- **snake_case** para variáveis, funções, módulos, arquivos
- **PascalCase** para classes
- **UPPER_SNAKE_CASE** para constantes
- **_underscore_prefix** para "privado" (convenção, não enforcement)

### Type hints obrigatórios

```python
# OBRIGATÓRIO em código novo
def calculate_total(items: list[OrderItem], discount: Decimal = Decimal("0")) -> Decimal:
    ...

# Protocols para ports (evita herança forçada)
from typing import Protocol

class UserRepository(Protocol):
    async def find_by_id(self, user_id: UUID) -> User | None: ...
    async def save(self, user: User) -> None: ...
```

### Async I/O

- FastAPI naturalmente async — usar `async def` em routes que fazem I/O
- `httpx.AsyncClient` para HTTP externo
- SQLAlchemy 2.x com `AsyncSession` para DB
- **Nunca** misturar `time.sleep()` com `asyncio.sleep()`
- **Nunca** chamar função async sem `await`

### Pydantic v2 para validação e schemas

```python
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=255)
    age: int | None = Field(default=None, ge=0, le=150)

class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    name: str
    created_at: datetime

    model_config = {"from_attributes": True}
```

### Error handling

- **Exceções tipadas** — herança de classe base (`DomainError`, `ValidationError`, `NotFoundError`)
- Adapter inbound traduz para HTTPException no FastAPI
- **Nunca** capturar `Exception` genérico (silencia bugs) — capturar exceções específicas
- Usar `try/except` apenas onde há ação clara de tratamento

### FastAPI dependency injection

```python
# adapters/inbound/http/users.py
from fastapi import APIRouter, Depends

router = APIRouter()

@router.post("/users", status_code=201, response_model=UserResponse)
async def create_user(
    payload: CreateUserRequest,
    use_case: CreateUserUseCase = Depends(get_create_user_use_case),
) -> UserResponse:
    user = await use_case.execute(payload.model_dump())
    return UserResponse.model_validate(user)
```

---

## Padrão de testes

### Pirâmide

| Camada | Ferramenta | Cobertura por modo |
|--------|-----------|--------------------|
| Unit (domain + use cases) | pytest | MVP ≥60% críticas / Production ≥95% críticas |
| Integration (adapters) | pytest + Testcontainers | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | pytest + httpx.AsyncClient | Happy paths críticos |
| Load/Performance | Locust ou k6 | Production: NFRs do PRD |

### Estrutura

```
tests/
├── unit/
│   └── domain/
├── integration/
│   ├── adapters/
│   └── conftest.py             # fixtures compartilhadas
├── e2e/
└── fixtures/                   # dados de teste versionados
```

### Testcontainers para Postgres/Redis

```python
import pytest
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def postgres():
    with PostgresContainer("postgres:16") as pg:
        yield pg.get_connection_url()
```

---

## Migrations

### Alembic (com SQLAlchemy)

```bash
# gerar migration baseada em mudança nos models
alembic revision --autogenerate -m "add_users_table"

# aplicar
alembic upgrade head

# reverter
alembic downgrade -1
```

### Regras

- Toda migration reversível (down implementado e testado)
- **Expand-contract** em breaking changes (Production)
- Backup confirmado antes de migration destrutiva
- Migration testada em staging com volume realista
- Migration > 5min → janela de manutenção ou job em background

---

## Logging e Observabilidade

### structlog (estruturado)

```python
import structlog

logger = structlog.get_logger()

# uso
logger.info("user_created", user_id=str(user.id), email=user.email)
```

### Regras

- **Sempre** estruturado (key-value), não f-string concatenada
- Correlation ID via middleware (FastAPI middleware)
- Nunca logar dados sensíveis (PII, tokens, senhas)
- OpenTelemetry para tracing distribuído em Production
- Prometheus metrics via prometheus-client

---

## Performance

- **Async I/O** sempre que possível (FastAPI)
- **Connection pooling** no SQLAlchemy (configurar `pool_size`)
- Cache via Redis para queries pesadas
- **Workers** múltiplos via uvicorn `--workers N` (driblar GIL)
- Para CPU-bound: ProcessPoolExecutor ou Celery workers
- Profiling: cProfile, py-spy, scalene
- Polars > Pandas para datasets grandes

---

## Segurança específica

- `python-jose` ou `authlib` para JWT (validação rigorosa)
- `passlib` com Argon2 para senhas
- Pydantic Settings para validação de env (fail-fast)
- `safety` ou `pip-audit` para CVEs (na pipeline)
- `bandit` para SAST de código Python
- CORS via FastAPI middleware (nunca `*` em produção com auth)
- Rate limiting via slowapi
- SQL injection: SQLAlchemy parametriza queries — **nunca** concatenar SQL

---

## Comandos padrão

```bash
# install (uv)
uv sync

# dev
uvicorn src.main:app --reload --port 8000

# test
pytest                                      # tudo
pytest tests/unit                           # só unit
pytest --cov=src --cov-report=html          # com cobertura HTML

# lint + format
ruff check .
ruff format .
mypy src/

# migrations
alembic revision --autogenerate -m "..."
alembic upgrade head

# CI (tudo de uma vez)
ruff check . && ruff format --check . && mypy src/ && pytest --cov=src --cov-fail-under=80
```

---

## Anti-patterns (bloquear)

- Funções sem type hints em código novo
- `from module import *`
- Mutable default args (`def f(x=[])`)
- Captura de `Exception` genérico
- `print()` em código de produção (use logger)
- Lógica de negócio dentro de routes/views
- Importar SQLAlchemy/Django ORM no domain
- `time.sleep()` em código async (use `asyncio.sleep`)
- Misturar Pydantic models com entidades de domínio (mapear)
- Queries N+1 (usar `selectinload`, `joinedload`)
- Magic numbers / strings — usar Enum ou constantes
- Bare `try/except: pass` (silencia bugs)

---

## Referências

- Python: <https://docs.python.org/3/>
- FastAPI: <https://fastapi.tiangolo.com/>
- Pydantic: <https://docs.pydantic.dev/latest/>
- SQLAlchemy 2.x: <https://docs.sqlalchemy.org/en/20/>
- Ruff: <https://docs.astral.sh/ruff/>
- uv: <https://docs.astral.sh/uv/>
