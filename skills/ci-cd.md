---
name: ci-cd
description: CI/CD with GitHub Actions pipelines, deployment workflows, release automation. Pinned action SHAs, secrets handling, branch protection, dependency caching.
---
# CI/CD

**Scope:** GitHub Actions pipelines, deployment workflows, release automation.

## Rules
- Every repo has at minimum: lint, typecheck, test, build steps
- Secrets via `${{ secrets.* }}` — never hardcoded values or env vars in workflow files
- Pin action versions to full SHA, not tags (`uses: actions/checkout@<sha>`)
- Fail fast on lint/typecheck before running expensive test suites
- Branch protection on main — require passing CI before merge
- Cache dependencies (`actions/cache` or `actions/setup-node` with cache) to reduce build time
- Separate workflows for CI (on PR) and CD (on merge to main)

## GitHub Actions Structure
- `.github/workflows/ci.yml` — runs on pull_request and push to main
- `.github/workflows/deploy.yml` — runs on push to main only (after CI passes)
- Reusable workflows (`.github/workflows/reusable-*.yml`) for shared steps across repos

## CI Pipeline Order
1. Checkout + dependency install (with cache)
2. Lint (`eslint`, `prettier --check`)
3. Typecheck (`tsc --noEmit`)
4. Unit tests (`vitest run`, `jest`)
5. Build (`tsc`, `docker build`)
6. Integration tests (if applicable, with service containers)
7. Upload artifacts / coverage reports

## CD Pipeline
- Build and push Docker image with commit SHA tag + `latest`
- Deploy to staging automatically on merge to main
- Deploy to production via manual approval (`environment: production`)
- Run smoke tests / health checks post-deploy
- Rollback strategy documented in workflow comments

## Security
- Use `permissions` block — least privilege per job (`contents: read`, `packages: write`)
- Use OIDC for cloud provider auth — no long-lived access keys
- Dependabot or Renovate for dependency updates
- `CODEOWNERS` file for workflow file changes
- No `pull_request_target` with checkout of PR head (injection risk)

## Best Practices
- Jobs should be independent and parallelisable where possible
- Use `matrix` strategy for multi-version or multi-platform testing
- Set `timeout-minutes` on every job to prevent runaway builds
- Use `concurrency` groups to cancel superseded runs on the same branch
- Artifacts for build outputs, test reports, and coverage
- Status checks as GitHub commit statuses for PR visibility
