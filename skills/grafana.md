# Grafana

**Scope:** Dashboard design, alerting, SLO panels, Prometheus and Loki data sources.

## Rules

- Every service gets a standard dashboard: RED metrics, error rate, latency histogram, active traces link
- Use template variables for `service`, `env`, and `instance` — never hardcode values in panels
- Prefer time series panels for trends, stat panels for current values, table panels for breakdowns
- Set meaningful panel titles and descriptions — dashboards are read by on-call engineers under pressure
- Use consistent colour conventions: green = healthy, yellow = warning, red = critical
- Link dashboards to each other (service → dependency, metric panel → trace explorer)
- Store all dashboards as JSON in version control — no manual-only dashboards in production

## Dashboard Structure

Every service dashboard must have these rows:

```
1. Overview       — request rate, error rate, p50/p95/p99 latency (stat panels)
2. Traffic        — requests/sec by endpoint (time series)
3. Errors         — error rate by endpoint and error type (time series + table)
4. Latency        — latency histograms by endpoint (heatmap or time series)
5. Dependencies   — downstream service health (if applicable)
6. Infrastructure — CPU, memory, pod restarts (if applicable)
```

## SLO Panels

For services with SLOs, add a dedicated SLO row:

```
- Error budget remaining (gauge panel, thresholds at 50% and 25%)
- Burn rate (time series, alert threshold line)
- SLO compliance over 7d / 30d (stat panels)
```

## Alerting

- Alerts in Grafana should mirror Alertmanager rules — don't define alerts in two places
- Use Grafana alerts only for dashboard-specific visual alerts, not for PagerDuty routing
- All production alerts route through Alertmanager

## Loki Integration

- Use derived fields to link log lines to Jaeger traces (match trace ID pattern, link to Jaeger UI)
- Add a Logs panel to every service dashboard linked to the service's Loki stream
- Use label filters, not regex on log content — label queries are indexed and fast

## Verification

```bash
# Validate dashboard JSON before committing
grafana-dash-lint dashboard.json
```
