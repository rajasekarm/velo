---
name: opentelemetry
description: Distributed tracing instrumentation with OpenTelemetry, trace context propagation, sampling, Jaeger backend. Span naming, async context, error recording, baggage.
---
# OpenTelemetry & Jaeger

**Scope:** Distributed tracing instrumentation, trace context propagation, sampling, Jaeger as the tracing backend.

## Rules

- Use OpenTelemetry SDK — never instrument directly against Jaeger client libraries
- Every inbound request creates a root span; every outbound call creates a child span
- Span names must be meaningful: `HTTP POST /users`, `db.query users.find`, `queue.publish user.created`
- Never put high-cardinality data in span names — use span attributes instead
- Always propagate trace context across async boundaries: HTTP headers, message queue metadata, scheduled jobs
- Set span status to `ERROR` and record the exception when an operation fails
- Use baggage sparingly — it propagates to all downstream services

## Span Naming Conventions

```
HTTP:     "<METHOD> <route_pattern>"        → "GET /users/:id"
DB:       "db.<operation> <table>"          → "db.query users"
Queue:    "queue.<operation> <topic>"       → "queue.publish order.created"
Cache:    "cache.<operation> <key_pattern>" → "cache.get session"
External: "<service>.<operation>"           → "stripe.createPayment"
```

## Span Attributes

Always include on HTTP spans:
- `http.method`, `http.route`, `http.status_code`
- `http.request_content_length`, `http.response_content_length`

Always include on DB spans:
- `db.system` (e.g. `postgresql`), `db.name`, `db.operation`, `db.statement` (sanitised — no user values)

Always include on all spans:
- `service.name`, `service.version`, `deployment.environment`

## Context Propagation

```typescript
// HTTP — use W3C TraceContext headers (OTel default)
// Propagator handles inject/extract automatically with instrumentation libraries

// Message queues — manually propagate
const carrier = {};
propagator.inject(context.active(), carrier);
await queue.publish({ ...message, _tracing: carrier });

// On consumer side
const ctx = propagator.extract(context.active(), message._tracing);
context.with(ctx, () => processMessage(message));
```

## Sampling

- Development: sample 100%
- Production: use probabilistic sampling at 10-20% for high-traffic services
- Always sample: errors, slow requests (> 2x p95 latency), and requests with `X-Debug-Trace: true` header
- Use Jaeger's adaptive sampling for automatic rate adjustment

## Jaeger Setup

```typescript
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';

const exporter = new JaegerExporter({
  endpoint: process.env.JAEGER_ENDPOINT, // never hardcode
});
```

## Verification

```bash
# Confirm traces are reaching Jaeger
curl http://localhost:16686/api/services
```
