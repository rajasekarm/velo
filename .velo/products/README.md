# .velo/products/

Per-product context files. Each product gets its own directory with a `context.md` that the PM reads at session start and appends to at session end.

---

## Purpose

Gives the PM continuity across sessions. When a user briefs the PM on a product, the PM checks this directory first, loads prior decisions, and picks up where the last session left off — without requiring the user to re-explain context.

---

## Directory structure

```
.velo/products/
  <product-slug>/
    context.md
```

No example products are included. Create a product directory only when the PM first encounters a new product slug.

---

## File format

```
---
slug: <product-slug>
aliases: [comma, separated, alt, names]
---

# <Product name> — Context

YYYY-MM-DD: <one-line decision or rejected direction>
YYYY-MM-DD: <one-line decision or rejected direction>
```

- `slug`: the canonical product identifier (lowercase-kebab-case)
- `aliases`: alternate names the PM should match against (e.g. slug `auth` might have aliases `[authentication, sso, login]`)
- Body: chronological log of decisions and rejected directions — one date-stamped one-liner per line, no prose dumps

---

## Length cap

**120 lines maximum** (including frontmatter). When the cap is hit, prune the oldest entries that are clearly superseded by newer decisions on the same topic. Always write a single replacement line: `YYYY-MM-DD: [pruned N entries — see git history]`.

---

## Slug naming

- Lowercase kebab-case only: `user-auth`, `billing`, `search-v2`
- Prefer short, stable names over descriptive phrases
- When in doubt, use the domain noun: `billing` not `billing-and-payments`

---

## Relation to tasks

Each task in `.velo/tasks/<task-slug>/` should contain a `product.txt` file with the product slug it belongs to. This lets `/velo:new` load the correct product context when spawning the PM.

Example `.velo/tasks/add-sso-login/product.txt`:
```
auth
```

The PM writes this file after resolving the product slug in Workflow Mode.
