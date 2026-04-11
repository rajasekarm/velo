# Node.js / TypeScript

**Scope:** Server-side Node.js with TypeScript strict mode.

## Rules
- TypeScript strict mode — no `any`, async/await only
- Every endpoint has input validation at the boundary — use zod
- Structured logging (JSON) with request IDs for traceability
- Graceful shutdown: drain connections on SIGTERM
- Secrets from environment or secret manager — never hardcoded
- pg (node-postgres) for PostgreSQL, @clickhouse/client for ClickHouse
- Connection pooling with sensible limits and health checks
- API versioning strategy decided upfront for public endpoints

## Patterns
- Express or Fastify for HTTP
- Async error handling via middleware, not per-route try/catch
- Worker threads for CPU-bound work, never block the event loop
- Streaming for large payloads — don't buffer in memory

## Verification
```bash
npx tsc --noEmit
```
