# Structured Logging (Pino + Loki)

**Scope:** Structured logging with Pino in Node.js services, log aggregation with Loki.

## Rules

- Use Pino — no Winston, no console.log in production code
- All logs are JSON — no string concatenation, no template literals as messages
- Log at the right level — don't log INFO for every function call, don't swallow errors as WARN
- Every log line must include `traceId` and `spanId` for log-trace correlation in Grafana
- Never log sensitive data: passwords, tokens, PII, full request bodies with credentials
- Use child loggers to bind request-scoped context — don't pass context as individual fields on every call
- Loki labels must be low-cardinality: `service`, `env`, `level` only. Everything else goes in the log line.

## Log Levels

| Level | When to use |
|---|---|
| `fatal` | Process is about to crash |
| `error` | Operation failed, requires attention |
| `warn` | Unexpected state, but handled — worth monitoring |
| `info` | Significant business events (user signed up, payment processed) |
| `debug` | Developer-useful detail — disabled in production |
| `trace` | Verbose internals — never in production |

## Setup

```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  formatters: {
    level: (label) => ({ level: label }), // use string level, not numeric
  },
  base: {
    service: process.env.SERVICE_NAME,
    env: process.env.NODE_ENV,
    version: process.env.SERVICE_VERSION,
  },
});
```

## Request Context (Child Logger)

```typescript
// Bind trace context to every log in the request lifecycle
const reqLogger = logger.child({
  requestId: req.id,
  traceId: trace.getActiveSpan()?.spanContext().traceId,
  spanId: trace.getActiveSpan()?.spanContext().spanId,
  userId: req.user?.id,
});

reqLogger.info({ route: req.path }, 'request received');
```

## Patterns

```typescript
// Good — structured, context in object
logger.error({ err, orderId }, 'payment failed');

// Bad — unstructured
logger.error(`payment failed for order ${orderId}: ${err.message}`);

// Good — business event with relevant context
logger.info({ userId, planId, amount }, 'subscription created');

// Bad — too noisy, no business value
logger.info('entering processPayment function');
```

## Loki Label Strategy

Labels are indexed — keep them low-cardinality:

```
{service="api", env="production", level="error"}
```

Do not use as labels: `userId`, `requestId`, `traceId`, `route` — these go in the log line, queried with `|=` or `| json`.

## Log-Trace Correlation

Ensure every log line includes `traceId` and `spanId`. In Grafana, configure a derived field on the Loki data source to detect `traceId` and link directly to Jaeger.

## Verification

```bash
# Confirm logs are structured JSON
node -e "require('./src/logger')" | pino-pretty

# Confirm Loki is receiving logs
curl http://localhost:3100/ready
```
