---
name: prometheus
description: Prometheus metrics collection, PromQL, alerting rules, recording rules. RED metrics, histogram buckets, naming conventions, low-cardinality labels, SLO thresholds.
---
# Prometheus

**Scope:** Metrics collection, PromQL, alerting rules, and recording rules.

## Rules

- Follow metric naming: `<service>_<operation>_<unit>` (e.g. `api_request_duration_seconds`)
- Use standard units: `_seconds`, `_bytes`, `_total` (for counters), `_ratio`
- Counters always end in `_total`
- Never use high-cardinality labels — no user IDs, email addresses, or UUIDs as label values
- Every service exposes RED metrics: Rate (requests/sec), Errors (error rate), Duration (latency histogram)
- Histograms over summaries — summaries can't be aggregated across instances
- Use `le` buckets that match your actual SLO thresholds (e.g. 0.1, 0.25, 0.5, 1.0, 2.5)
- Recording rules for any PromQL query used in dashboards or alerts — don't run expensive queries at scrape time

## Metric Types

- **Counter**: monotonically increasing values (requests, errors, bytes sent)
- **Gauge**: values that go up and down (active connections, queue depth, memory)
- **Histogram**: latency and size distributions with configurable buckets
- **Summary**: avoid — use histograms

## Patterns

```
# RED metrics for an HTTP service
http_requests_total{method, route, status_code}
http_request_duration_seconds{method, route, status_code} (histogram)
http_request_errors_total{method, route, error_type}

# Background job
job_runs_total{job_name, status}
job_duration_seconds{job_name} (histogram)

# Queue consumer
queue_messages_processed_total{queue, status}
queue_processing_duration_seconds{queue} (histogram)
queue_depth{queue} (gauge)
```

## Alerting Rules

Every alert must have:
- `severity` label: `critical`, `warning`, or `info`
- `runbook_url` annotation pointing to a real runbook
- A `for` duration to avoid flapping (minimum 2m for warnings, 5m for critical)
- Human-readable `summary` and `description` annotations

```yaml
- alert: HighErrorRate
  expr: rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High error rate on {{ $labels.service }}"
    description: "Error rate is {{ $value | humanizePercentage }} over the last 5 minutes."
    runbook_url: "https://runbooks.internal/high-error-rate"
```

## Verification

```bash
promtool check rules alerts.yml
promtool check rules recording_rules.yml
```
