# Security

**Scope:** Application security — OWASP Top 10, auth/authz, input validation, secrets management, API security.

## Rules

- Never trust user input — validate and sanitise at every system boundary
- Never hardcode secrets — environment variables or secret manager only
- Auth on every endpoint — explicit allow, not explicit deny
- Principle of least privilege — request only what's needed, grant only what's required
- Never log sensitive data — passwords, tokens, PII, card numbers
- Always use parameterised queries — never string-concatenate SQL
- Set security headers on every HTTP response
- Tokens must be short-lived — rotate, don't extend

## OWASP Top 10 Checklist

| Risk | What to check |
|---|---|
| Injection | SQL, NoSQL, command injection — parameterised queries everywhere |
| Broken Auth | Weak passwords, missing rate limiting, insecure token storage |
| Sensitive Data Exposure | PII in logs, unencrypted data at rest, verbose error messages |
| Security Misconfiguration | Default credentials, open ports, debug mode in production |
| XSS | Unsanitised user content rendered in HTML, missing CSP headers |
| Insecure Deserialisation | Untrusted data deserialised without validation |
| Broken Access Control | Missing authorisation checks, IDOR vulnerabilities |
| Using Vulnerable Components | Outdated dependencies with known CVEs |
| Insufficient Logging | Missing audit logs for auth events, no anomaly detection |
| SSRF | Unvalidated URLs in server-side requests |

## Auth/Authz

- Use JWT for stateless auth — short expiry (15m access, 7d refresh)
- Validate token signature, expiry, and issuer on every request
- RBAC over ABAC for most systems — simpler to reason about
- Check permissions at the service layer, not just the API gateway
- Never expose internal user IDs in public API responses — use opaque identifiers

```typescript
// Always validate at boundary
const token = req.headers.authorization?.replace('Bearer ', '');
if (!token) return res.status(401).json({ code: 'UNAUTHORIZED' });

const payload = verifyJwt(token); // throws if invalid
if (!hasPermission(payload.role, req.route)) return res.status(403).json({ code: 'FORBIDDEN' });
```

## Input Validation

- Validate with zod at every API boundary — reject unknown fields (`strip()` or `strict()`)
- Validate file uploads: type, size, content (don't trust MIME type alone)
- Sanitise HTML input — use a whitelist allowlist library, never a blocklist

```typescript
const schema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
}).strict(); // reject unknown fields
```

## Secrets Management

- All secrets via environment variables or secret manager (AWS Secrets Manager, Vault)
- Rotate secrets regularly — design for rotation from day one
- Never commit `.env` files — `.env.example` with dummy values only
- Audit secret access in production

## HTTP Security Headers

Every response must include:

```
Content-Security-Policy: default-src 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000; includeSubDomains
Referrer-Policy: strict-origin-when-cross-origin
```

## API Security

- Rate limit all public endpoints — by IP and by user
- Return generic error messages to clients — never expose stack traces or internal details
- Use HTTPS only — no HTTP fallback in production
- Validate `Content-Type` on POST/PUT requests
- CORS: explicit allowlist, never `*` in production

## Verification

```bash
# Check for known vulnerabilities in dependencies
npm audit --audit-level=high

# Check for secrets accidentally committed
git log -p | grep -iE "(password|secret|token|key)\s*="
```
