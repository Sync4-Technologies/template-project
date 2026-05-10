# Stack Convention — Python

> Supported frameworks: **FastAPI** (preferred for APIs and AI/ML) or **Django** (full-stack monolithic apps with rich ORM).

---

## When to use this stack

Choose Python when:

- **AI/ML pipelines** — ecosystem (PyTorch, TensorFlow, scikit-learn, HuggingFace) is dramatically superior
- **Data engineering** — Pandas, Polars, Spark (PySpark), Airflow, dbt, dlt
- **Simple-to-medium APIs** with FastAPI — type hints + Pydantic = excellent DX
- **LLM model integration** — LangChain, LangGraph, official SDKs (anthropic, openai)
- **Scripts and automation** — clean syntax, vast ecosystem
- **Notebooks and scientific prototyping** — Jupyter, IPython
- **CMS and admin dashboards** — Django Admin gives you the UI for free
- **Team with scientific/data background** — Python is lingua franca

## When NOT to use

- **Massive CPU-bound concurrency** — GIL is limiting; prefer Go/Rust
- **Highest-throughput I/O applications** — Node.js/Go perform better
- **Hard latency budgets** — slow startup, unpredictable GC
- **Type sharing with frontend** — no TypeScript-like

---

## Versions and dependencies

| Item | Minimum version |
|------|-----------------|
| Python | ≥ 3.12 (prefer 3.13) |
| pip + venv | Replace with **uv** (preferred) or **Poetry** |
| Frameworks: FastAPI ≥ 0.110 | Django ≥ 5.0 |

### Frameworks

| Framework | When to use |
|-----------|-------------|
| **FastAPI** | REST/WebSocket APIs, AI/ML services, microservices |
| **Django** | Full-stack apps with Admin, monoliths with strong ORM modeling |
| **Litestar** | Modern alternative to FastAPI with rich plugins |

### Standard libraries

| Need | Library |
|------|---------|
| ORM | SQLAlchemy 2.x (preferred) or Django ORM |
| Migrations | Alembic (preferred) or Django Migrations |
| Validation | Pydantic v2 |
| HTTP client | httpx (preferred over requests — async-ready) |
| Logging | structlog or loguru |
| Testing | pytest + pytest-asyncio + pytest-cov |
| Tracing/Metrics | OpenTelemetry SDK |
| Auth | python-jose (JWT) or Authlib (OAuth) |
| Queue/Jobs | Celery + Redis or RQ (simpler) |
| Cache | redis-py |
| AI/LLM | anthropic, openai, langchain, langgraph |
| Data | pandas, polars |

### Dependency management

- **uv** (preferred) — extremely fast, drop-in replacement for pip
- **Poetry** — mature alternative
- **Never** `pip install` directly — always via `pyproject.toml`

---

## Required tooling

| Tool | Purpose |
|------|---------|
| **ruff** | Linter + formatter (replaces flake8, black, isort, pyupgrade) |
| **mypy** | Type check (strict mode) |
| **pytest** | Test runner |
| **pytest-cov** | Coverage |
| **pre-commit** | Pre-commit hooks |

### Minimum pyproject.toml

```toml
[tool.ruff]
target-version = "py312"
line-length = 100
select = ["E", "F", "W", "I", "N", "UP", "S", "B", "A", "C4", "T20", "RET", "SIM"]
ignore = ["S101"]  # asserts in tests

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

## Project layout (Hexagonal)

```
src/
├── domain/                      # core
│   ├── entities/                # entities (dataclass or Pydantic)
│   ├── ports/                   # protocols (typing.Protocol) — interfaces
│   └── services/                # domain services
│
├── application/
│   └── use_cases/               # each use case = one class or function
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
│   └── di/                      # dependency-injector or manual
│
└── main.py                      # ASGI app factory
```

### Django

In Django, map bounded contexts to **apps**:
- `apps/<context>/domain/` — non-ORM entities
- `apps/<context>/application/` — use cases
- `apps/<context>/adapters/` — views, repositories, models (Django ORM here)
- `apps/<context>/admin.py`, `urls.py` — Django config

---

## Code conventions

### Naming

- **snake_case** for variables, functions, modules, files
- **PascalCase** for classes
- **UPPER_SNAKE_CASE** for constants
- **_underscore_prefix** for "private" (convention, not enforcement)

### Type hints required

```python
# REQUIRED in new code
def calculate_total(items: list[OrderItem], discount: Decimal = Decimal("0")) -> Decimal:
    ...

# Protocols for ports (avoid forced inheritance)
from typing import Protocol

class UserRepository(Protocol):
    async def find_by_id(self, user_id: UUID) -> User | None: ...
    async def save(self, user: User) -> None: ...
```

### Async I/O

- FastAPI is naturally async — use `async def` in routes that do I/O
- `httpx.AsyncClient` for external HTTP
- SQLAlchemy 2.x with `AsyncSession` for DB
- **Never** mix `time.sleep()` with `asyncio.sleep()`
- **Never** call an async function without `await`

### Pydantic v2 for validation and schemas

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

- **Typed exceptions** — inherit from a base class (`DomainError`, `ValidationError`, `NotFoundError`)
- Inbound adapter translates to FastAPI HTTPException
- **Never** catch generic `Exception` (silences bugs) — catch specific exceptions
- Use `try/except` only where there's a clear handling action

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

## Testing standards

### Pyramid

| Layer | Tool | Coverage by mode |
|-------|------|------------------|
| Unit (domain + use cases) | pytest | MVP ≥60% critical / Production ≥95% critical |
| Integration (adapters) | pytest + Testcontainers | MVP ≥40% / Production ≥80% |
| E2E (HTTP) | pytest + httpx.AsyncClient | Critical happy paths |
| Load/Performance | Locust or k6 | Production: PRD NFRs |

### Structure

```
tests/
├── unit/
│   └── domain/
├── integration/
│   ├── adapters/
│   └── conftest.py             # shared fixtures
├── e2e/
└── fixtures/                   # versioned test data
```

### Testcontainers for Postgres/Redis

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

### Alembic (with SQLAlchemy)

```bash
# generate migration based on model changes
alembic revision --autogenerate -m "add_users_table"

# apply
alembic upgrade head

# revert
alembic downgrade -1
```

### Rules

- Every migration reversible (down implemented and tested)
- **Expand-contract** for breaking changes (Production)
- Backup confirmed before destructive migration
- Migration tested on staging with realistic volume
- Migration > 5min → maintenance window or background job

---

## Logging and Observability

### structlog (structured)

```python
import structlog

logger = structlog.get_logger()

# usage
logger.info("user_created", user_id=str(user.id), email=user.email)
```

### Rules

- **Always** structured (key-value), not concatenated f-strings
- Correlation ID via middleware (FastAPI middleware)
- Never log sensitive data (PII, tokens, passwords)
- OpenTelemetry for distributed tracing in Production
- Prometheus metrics via prometheus-client

---

## Performance

- **Async I/O** whenever possible (FastAPI)
- **Connection pooling** in SQLAlchemy (configure `pool_size`)
- Cache via Redis for heavy queries
- **Multiple workers** via uvicorn `--workers N` (work around the GIL)
- For CPU-bound: ProcessPoolExecutor or Celery workers
- Profiling: cProfile, py-spy, scalene
- Polars > Pandas for large datasets

---

## Stack-specific security

- `python-jose` or `authlib` for JWT (rigorous validation)
- `passlib` with Argon2 for passwords
- Pydantic Settings for env validation (fail-fast)
- `safety` or `pip-audit` for CVEs (in the pipeline)
- `bandit` for SAST of Python code
- CORS via FastAPI middleware (never `*` in production with auth)
- Rate limiting via slowapi
- SQL injection: SQLAlchemy parameterizes queries — **never** concatenate SQL

---

## Standard commands

```bash
# install (uv)
uv sync

# dev
uvicorn src.main:app --reload --port 8000

# test
pytest                                      # everything
pytest tests/unit                           # unit only
pytest --cov=src --cov-report=html          # with HTML coverage

# lint + format
ruff check .
ruff format .
mypy src/

# migrations
alembic revision --autogenerate -m "..."
alembic upgrade head

# CI (everything at once)
ruff check . && ruff format --check . && mypy src/ && pytest --cov=src --cov-fail-under=80
```

---

## Anti-patterns (block)

- Functions without type hints in new code
- `from module import *`
- Mutable default args (`def f(x=[])`)
- Catching generic `Exception`
- `print()` in production code (use the logger)
- Business logic inside routes/views
- Importing SQLAlchemy/Django ORM in the domain
- `time.sleep()` in async code (use `asyncio.sleep`)
- Mixing Pydantic models with domain entities (map them)
- N+1 queries (use `selectinload`, `joinedload`)
- Magic numbers / strings — use Enum or constants
- Bare `try/except: pass` (silences bugs)

---

## References

- Python: <https://docs.python.org/3/>
- FastAPI: <https://fastapi.tiangolo.com/>
- Pydantic: <https://docs.pydantic.dev/latest/>
- SQLAlchemy 2.x: <https://docs.sqlalchemy.org/en/20/>
- Ruff: <https://docs.astral.sh/ruff/>
- uv: <https://docs.astral.sh/uv/>
