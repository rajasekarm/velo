# ClickHouse

**Scope:** Analytics database, MergeTree engines, materialized views, time-series.

## Rules
- ReplacingMergeTree or AggregatingMergeTree — never plain MergeTree for mutable data
- Always ORDER BY in table definitions — this IS the primary index
- Materialized views for pre-aggregating high-volume streams
- Never SELECT * — always project needed columns
- toStartOfHour / toDate for time bucketing
- AggregateFunction(uniq, ...) for approximate distinct counts at scale

## Pipeline Pattern
1. Kafka engine table (ingestion)
2. Materialized view (transformation)
3. Target MergeTree table (storage + query)

## Performance
- Partition by month or day for time-series data
- Use LowCardinality for string columns with few distinct values
- Avoid JOINs on large tables — denormalise instead
- Use PREWHERE for selective filters on large scans
