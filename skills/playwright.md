---
name: playwright
description: Playwright end-to-end browser testing, page objects, API mocking, visual regression. data-testid selectors, page.route mocking, parallel execution, traces on retry.
---
# Playwright

**Scope:** End-to-end browser testing, page objects, API mocking, visual regression.

## Rules
- Page Object Model for all e2e tests — no raw selectors in test files
- `data-testid` attributes for selectors — never CSS classes or tag names
- API mocking via `page.route()` for isolated UI tests
- Parallel execution by default, serial only when tests share state
- Screenshots on failure, trace on retry
- `expect(locator).toBeVisible()` before interactions — no implicit waits

## Structure
- Test files: `e2e/<feature>.spec.ts`
- Page objects: `e2e/pages/<PageName>.ts`
- Fixtures: `e2e/fixtures/`
- One describe per user flow, one test per scenario

## Patterns
- Setup via API calls, not UI clicks (faster, more reliable)
- Clean up test data after each test
- Use test.describe.configure({ mode: 'serial' }) only when order matters
- Global setup for auth state (storageState)
