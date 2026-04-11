# Docker

**Scope:** Container builds, multi-stage, security, local development.

## Rules
- Multi-stage builds — separate build and runtime stages
- `node:<version>-slim` or distroless for runtime images
- Non-root user in runtime stage
- Pinned image versions — never use `latest`
- `.dockerignore` to exclude node_modules, .git, tests
- `HEALTHCHECK` on every service container
- No secrets in build args or layers

## Best Practices
- Order Dockerfile instructions by change frequency (static first, code last)
- Copy package.json before source for layer caching
- Use `--no-cache` flag in CI builds
- Single process per container

## docker-compose
- Named volumes for data persistence
- Health checks with depends_on conditions
- Environment variables via .env file (not hardcoded)
- Network isolation between services
