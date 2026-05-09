---
name: api-and-interface-design
description: API and interface design for REST endpoints and TypeScript contracts. Contract-first, consistent errors, boundary validation, additive evolution, predictable naming, idempotency keys, deprecation policy.
---
# API and Interface Design

**Scope:** Design of REST endpoints and TypeScript interfaces — contracts, error semantics, validation boundaries, evolution, and deprecation.

## Core Principles

- **Hyrum's Law** — every observable behaviour will be depended on by someone. Implication: treat any shipped behaviour as part of the contract, even when undocumented.
- **One-Version Rule** — keep one live contract per surface; evolve it additively. Only branch versions when a breaking change is unavoidable.

## Rules

### Five Pillars
- **Contract First** — define the schema (OpenAPI / TypeScript types) before writing handlers or callers
- **Consistent Error Semantics** — one error envelope across the whole surface; one mapping from failure class to HTTP status
- **Validate at Boundaries** — parse and reject at every untrusted edge; trust internal calls
- **Prefer Addition Over Modification** — add new optional fields and endpoints rather than changing or removing existing ones
- **Predictable Naming** — same concept uses the same name everywhere; same name never means two things

### REST
- Resources are plural nouns (`/users`, `/orders`) — never verbs in paths
- All list endpoints paginate from day one (`limit`, `cursor` or `page`) — never return unbounded arrays
- `PATCH` for partial updates, `PUT` only for full replacement
- Filtering and sorting via query params (`?status=active&sort=-createdAt`) — never in the body for GET
- `POST` creates, returns `201` with a `Location` header pointing at the new resource
- Status codes match meaning: `400` for ALL client-side validation errors (malformed input, missing required fields, type mismatches), `401` unauthenticated, `403` unauthorised, `404` missing, `409` state conflict (including idempotency-key mismatch), `422` reserved strictly for well-formed input that violates a business rule (e.g. "cannot cancel an already-shipped order") — if in doubt, prefer `400` or `409` and skip `422`

### TypeScript
- Discriminated unions for variant types — never optional flags that mean different things together
- Separate `Input` and `Output` interfaces — request shape is not response shape
- Branded types for IDs (`type UserId = string & { __brand: 'UserId' }`) — prevent cross-entity ID mixups
- Exported types are the contract — treat changes the same as API changes

### Boundary Catalog
Boundaries that REQUIRE validation:
- HTTP edge — incoming request bodies, query params, path params, headers
- Queue / event consumers — Kafka, SQS, pub/sub message payloads
- Third-party API responses — never trust the shape of an external response
- Database reads of external or untrusted data — JSON columns, user-provided blobs
- CLI arguments and file inputs

NOT boundaries — do not re-validate:
- Internal function calls between trusted modules in the same service
- Calls between layers within a request that already passed boundary validation

### Versioning Strategy
- Default: evolve additively — new optional fields, new endpoints, deprecation windows
- Breaking change unavoidable + public API: URI version (`/v2/...`)
- Breaking change unavoidable + internal API: header version (`Accept-Version: 2`)
- Never use query-param versioning (`?version=2`) — caches and proxies handle it inconsistently

### Idempotency
For non-GET endpoints that create or mutate billable, externally-visible, or otherwise non-replayable state:
- Accept an `Idempotency-Key` header from the client
- Persist the key plus the response for at least 24 hours
- On replay with the same key and matching request fingerprint: return the original response
- On replay with the same key but a different request fingerprint, reject with `409 Conflict`
- Request fingerprint = stable hash (e.g. SHA-256) of the canonical-JSON body (sorted keys, normalised whitespace)

### Deprecation
- Mark deprecated fields in OpenAPI / TypeScript types and on responses (`Deprecation: true`, `Sunset: <HTTP-date>` per RFC 8594 — HTTP-date is RFC 7231 / RFC 9110 format, e.g. `Sun, 06 Nov 1994 08:49:37 GMT`, NOT RFC 3339)
- Public APIs: minimum 90-day deprecation window before removal
- Internal APIs: announce in changelog and give consumers at least one release cycle
- Never silently change the meaning of an existing field — add a new one and deprecate the old

## Patterns

- One canonical error envelope: `{ code, message, details? }` — every endpoint, every status
- Parse-don't-validate at the edge — convert raw input to a typed domain object once, then trust it
- Pagination response shape stays consistent: `{ items, nextCursor }` or `{ items, page, total }` — pick one and apply everywhere
- `PATCH` follows JSON Merge Patch semantics (RFC 7396) — `null` clears a field, an omitted field is left unchanged. Do not invent per-endpoint variants.
- Return the created or updated resource in the response body — saves callers a round trip

## Verification

Checklist before merging an API or interface change:
- Schemas are typed end-to-end (OpenAPI / zod / TypeScript types match)
- Single error envelope used across all endpoints in the surface
- Validation runs at every boundary listed above, and only there
- Every list endpoint paginates
- New fields are additive and optional; no existing field changed shape or meaning
- Naming is consistent with existing endpoints and types
- Mutating endpoints accept `Idempotency-Key` where state is non-replayable
- Deprecated fields/endpoints carry `Deprecation` and `Sunset` markers
- Types and OpenAPI doc are versioned and committed together with the code
