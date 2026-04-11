# PostgreSQL

**Scope:** Schema design, indexing, query optimisation, migrations.

## Rules
- Parameterised queries always ($1, $2 ...) — never string interpolation
- Indexes based on query shape: btree for equality/range, GIN for JSONB/full-text, partial for filtered subsets, composite for multi-column WHERE
- Migrations are forward-only, backwards-compatible, and safe for zero-downtime deploys
- Use transactions for multi-statement operations
- CTEs for readability, lateral joins for row-level aggregation
- Always consider NULL handling in constraints and queries

## Schema Conventions
- `created_at` and `updated_at` timestamps on every table
- NOT NULL by default — nullable columns are the exception, not the rule
- Foreign keys with appropriate ON DELETE behaviour
- UNIQUE constraints where business logic demands it

## Performance
- EXPLAIN ANALYZE before and after optimisation
- Avoid SELECT * — project only needed columns
- LIMIT on all user-facing queries
- Connection pooling (pgbouncer or application-level)
- Vacuum tuning for high-write tables

## Migrations
- Never rename columns in a single step — add new, migrate data, drop old
- NOT NULL on existing columns requires a default value
- Large table alterations may need concurrent index creation
- Always test migration against a copy of production data size
