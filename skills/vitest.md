---
name: vitest
description: Vitest/Jest unit and integration testing, mocking, ESM-native test runner. describe/it structure, supertest HTTP integration, factories over fixtures, typed mocks.
---
# Vitest / Jest

**Scope:** Unit and integration testing, mocking, ESM-native test runner.

## Rules
- One `describe` per module, one `it` per behaviour
- Mock external dependencies (pg, kafkajs, axios, fetch) — test logic, not I/O
- Test error paths for every async function
- Factories over fixtures — build test data inline, keep it minimal
- No `any` in test files — type your mocks
- `supertest` for HTTP endpoint integration tests

## Structure
- Unit tests: `src/__tests__/<name>.test.ts` or co-located `<name>.test.ts`
- Integration tests: `src/__tests__/integration/<name>.test.ts`
- Test names describe behaviour: "returns 404 when user not found"

## Patterns
- `beforeEach` for per-test setup, `beforeAll` for expensive shared setup
- Restore all mocks in `afterEach`
- Prefer `toEqual` over `toBeTruthy` — specific assertions catch more bugs
- Snapshot tests only for serialised output (JSON, HTML), never for logic

## k6 Load Testing
- Stages: ramp-up -> sustained -> ramp-down
- Thresholds: `http_req_duration p(95) < N`, `http_req_failed rate < 0.01`
- Parameterise via `__ENV`: BASE_URL, VUs
- `group()` + `check()` for logical test grouping
- Load test files: `load-tests/<name>.k6.ts`
