---
name: python
description: Server-side Python with strict typing. FastAPI, pydantic v2 validation, uv dependency management, ruff, mypy strict, async I/O, SQLAlchemy 2.0, pytest.
---
# Python

**Scope:** Server-side Python services with strict typing. Applies to all Python backend work; a Python project is governed by this skill, not by the Node.js skill.

## Rules
- `mypy --strict` passes — every function annotated, no implicit `Any`, no untyped defs
- Every endpoint has input validation at the boundary — use pydantic v2 models, never hand-rolled dict checks
- `uv` for environments and dependencies; `pyproject.toml` + `uv.lock` committed. No `requirements.txt`, no pip, no poetry
- `ruff` for both formatting and linting (`ruff format`, `ruff check`). No black, no flake8, no isort as a separate tool
- `async`/`await` for all I/O; never block the event loop with sync calls in an async path
- Structured logging via stdlib `logging` with a per-module `getLogger(__name__)` — never `print()`
- Timezone-aware UTC datetimes only (`datetime.now(UTC)`); never naive datetimes
- Secrets from environment or a secret manager — never hardcoded. Load into a typed settings object and validate at startup, not at import time
- No bare `except:` — catch specific exceptions, raise typed ones from services
- psycopg (v3) for PostgreSQL; SQLAlchemy 2.0 `Mapped[...]` / `mapped_column` declarative style
- Pin the Python version in the repo (`.python-version`) so toolchains match across machines

## Patterns
- FastAPI with an app factory (`create_app()`) so tests construct isolated apps
- Dependency injection via `Depends` for settings, sessions, and providers
- Routers stay thin — I/O shaping only; logic lives in services
- Typed exceptions raised in services, mapped to the error envelope by a single handler layer
- `Protocol` for swappable seams (providers, clients) — structural typing over inheritance
- Streaming responses for large payloads — don't buffer whole files in memory
- pytest + pytest-asyncio; test APIs in-process with `httpx.AsyncClient` + `ASGITransport` (no live server needed)

Project-specific pins — exact Python version, chosen libraries, module layout — come from the project's engineering design doc where one exists. This skill sets the floor, not the whole contract.

## Verification
```bash
uv run ruff check && uv run mypy app && uv run pytest
```
