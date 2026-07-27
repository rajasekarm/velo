---
name: ticket-id-derivation
description: Shared ticket-ID derivation contract — the ticket-ID shape plus the three rules every candidate must pass regardless of source (left boundary, anchored validation, non-ticket key exclusion), ordered source lookup with first-valid-match tie-break, the opt-in user-prompt fallback with re-ask limit, prefix de-duplication, and the HALT / SOFT-FALLBACK terminal hook. Consumed by commit-protocol.md and pr-protocol.md, each of which binds only its source commands, its prompt participation, and its terminal behavior.
---
# Ticket ID Derivation

**Scope**: how to resolve a ticket ID for a git-facing artifact (a commit subject, a PR title), and what to do when no ID can be resolved. This skill owns only the parts that are identical for every consumer. It does NOT own what the ID is used for: subject and title shapes, type enums, length limits, description resolution, body templates, and command invocation all stay in the consuming skill.

Consumers bind exactly three things: their **source list** (see Consumer binding contract), their **prompt participation**, and their **terminal behavior**. Everything else below is fixed.

## Ticket ID shape

A ticket ID is an uppercase project key, a hyphen, and a number. The key begins with a letter and may contain digits after that first letter — `AGT-123`, `A11Y-42`, and `V2-17` are all in contract.

| Form | Pattern | Used for |
|---|---|---|
| Validation | `^[A-Z][A-Z0-9]*-[0-9]+$` | Accepting or rejecting a candidate — **every** candidate, whatever its source |
| Search | `(^\|[^A-Za-z0-9])[A-Z][A-Z0-9]*-[0-9]+` | Locating a candidate inside a larger text stream; the leading character is boundary context, not part of the ID |

Three rules govern every candidate. They are invariant — no consumer relaxes, extends, or restates them.

1. **Left boundary.** A candidate must not be preceded by a letter or a digit — a candidate never starts mid-token, so `fooY-42` yields nothing rather than `Y-42`. This is what the search form's leading `(^|[^A-Za-z0-9])` enforces, and it is why the extraction idiom below is two-stage: `grep -o` returns that boundary character as part of its match, so a second pass trims the candidate out of it. Nothing constrains what *follows* the number, so a branch like `AGT-123-add-retry` still yields `AGT-123`.
2. **Whole-candidate validation.** Once extracted, a candidate must satisfy the anchored validation form. Extraction and validation are separate steps: extraction proposes, validation decides.
3. **Non-ticket key exclusion.** Reject any candidate whose key is a standards, algorithm, or encoding token rather than a project key. These are structurally indistinguishable from real ticket IDs — no pattern accepts `AGT-123` and rejects `SHA-256` — so exclusion is by name:

   ```
   SHA SHA1 SHA2 SHA3 MD5 UTF UCS ISO IEC RFC IEEE ANSI AES RSA
   TLS SSL HTTP CVE CWE PEP UTC GMT RGB RGBA X86 ARM COVID BASE
   ```

   The list is a seed, not a closed set: reject any other candidate whose key is plainly a technical token and not a project key. Exclusion applies **only to extracted candidates** — see [Prompting the user](#prompting-the-user), where the user is authoritative.

A candidate that fails any of the three is **not a match**. It does not become the ticket ID, and it does not end the lookup.

## Source lookup order

The consumer declares an **ordered list of sources**. Check them in that order and stop at the first source that yields a match. The order is the precedence rule: an earlier source always wins over a later one, so no separate cross-source tie-break is needed.

A consumer declares only the **source command** for each shell-backed source (see [Consumer binding contract](#consumer-binding-contract)). The extraction, validation, and exclusion around it are owned here, and are identical for every source:

```
TICKET=$(<source-command> \
  | grep -oE '(^|[^A-Za-z0-9])[A-Z][A-Z0-9]*-[0-9]+' \
  | grep -oE '[A-Z][A-Z0-9]*-[0-9]+' \
  | grep -vxE '(SHA[0-9]*|MD5|UTF|UCS|ISO|IEC|RFC|IEEE|ANSI|AES|RSA|TLS|SSL|HTTP|CVE|CWE|PEP|UTC|GMT|RGBA?|X86|ARM|COVID|BASE)-[0-9]+' \
  | head -1)
```

Line by line: locate candidates with a left boundary, trim the boundary character off, drop excluded keys, take the first survivor. The exclusion filter sits **before** `head -1` deliberately — a source whose text mentions `SHA-256` and later refers to `AGT-123` resolves to `AGT-123`, not to nothing.

A source may also be non-shell (for example, reading a value out of recent conversation context). Such a source still yields at most one candidate, and that candidate is subject to the same three rules — a value read from context is validated exactly as one extracted by the pipeline. Validation is a property of the candidate, never of where it came from.

Because a failed candidate is not a match, a source that yields only invalid candidates counts as **empty** and the lookup continues to the next source. If every declared source comes back empty, what happens next is the consumer's prompt-participation declaration: a consumer that declares the prompt falls through to Prompting the user below; a consumer that declines it applies its terminal behavior immediately. The prompt is never one of the consumer's declared sources — when declared, it is the fixed final step of the derivation.

### Multiple matches

If a single source contains more than one distinct candidate, the **first one that passes validation wins** (`head -1`, applied after exclusion). Do not attempt to disambiguate, do not concatenate, and do not ask the user to choose between them.

## Prompting the user

The prompt is opt-in: it runs only for consumers whose binding declares it (see [Consumer binding contract](#consumer-binding-contract)). A consumer that declines the prompt applies its terminal behavior directly when all declared sources are empty — the user is not asked.

For a consumer that declares the prompt: when all declared sources are empty, ask the user via `ask-options`, using this wording:

```
No ticket ID found in branch, commits, or context. What is the ticket ID? (e.g. AGT-123)
```

If a consumer's declared sources are not branch, commits, and context, it substitutes its own source names in the first sentence; the second sentence and the example are fixed.

Validate the response against the **validation form** `^[A-Z][A-Z0-9]*-[0-9]+$`. The [non-ticket key exclusion](#ticket-id-shape) does **not** apply here: exclusion is a heuristic for guessing intent out of prose, and at the prompt there is nothing to guess — the user is authoritative. A project whose real key happens to be an excluded token is still committable, because the user can always name it here.

On invalid or empty input, re-ask — **up to 3 attempts total**. After the third invalid or empty response, stop asking and apply the consumer's declared terminal behavior.

## Prefix de-duplication

Before a resolved ticket ID is prefixed onto a description, strip any ticket prefix the description already carries, so it is not doubled:

```
sed -E 's/^\[[A-Z][A-Z0-9]*-[0-9]+\][[:space:]]*-?[[:space:]]*//'
```

This strips a leading bracketed ticket ID plus one immediately following separator (whitespace and/or a single hyphen). Its key pattern tracks the shape above, so a widened key (`[A11Y-42] - fix contrast`) de-duplicates like any other. It matches on shape alone — the exclusion list is not consulted, because the goal here is to avoid a doubled prefix, not to decide what the ID is. It strips nothing else: it does not touch a bracketed token in any other position, and it does not sanitize characters. Any further sanitization of the description is the consumer's concern, applied after this step.

## Terminal behavior

Every consumer declares exactly one terminal behavior, which fires when derivation ends with no ticket ID — all declared sources empty, and, for a consumer that declared the prompt, the user did not supply a valid ID within 3 attempts.

| Hook | Meaning |
|---|---|
| `HALT` | Stop. Do NOT perform the consumer's action, and do not perform any of its side effects. Surface the consumer's declared halt message to the user. The ticket ID is mandatory for that consumer. |
| `SOFT-FALLBACK` | Proceed without a ticket prefix, using the consumer's declared no-ticket form. The calling agent then surfaces the consumer's declared notice alongside its normal output, so the user knows the prefix is missing and how to fix it. |

Under `HALT`, halting is ordinary blocker handling — the consumer stops and reports; it does not invent a bespoke failure mode. Under `SOFT-FALLBACK`, emitting the notice is the caller's responsibility, not a flag on whatever command the consumer runs.

## Consumer binding contract

A consuming skill MUST declare all three of these in its own text, and MAY declare nothing else about derivation:

1. **Source list** — its sources in precedence order. Sources are consumer-specific by construction: what is meaningful for an artifact that already exists (a range of commits) is meaningless for one that does not exist yet.
2. **Prompt participation** — whether [Prompting the user](#prompting-the-user) runs when all its sources come back empty. Declared, the prompt runs with the fixed wording and re-ask limit above; declined, the terminal behavior fires immediately. There is no default: a binding silent on prompt participation is **invalid**, and the remedy is to fix the consumer's declaration — never to guess a behavior on its behalf.
3. **Terminal behavior** — either `HALT` or `SOFT-FALLBACK`, plus the exact message text that behavior surfaces (`HALT`: the halt message; `SOFT-FALLBACK`: the no-ticket output form and the caller notice).

### Granularity of a source declaration

A shell-backed source is declared as **the bare source command and nothing more** — the command that produces the text stream, with no pipeline attached:

```
1. Branch name — `git branch --show-current`
2. Commit subjects in range — `git log <base>..HEAD --format=%s`
```

Everything downstream of that command is owned here: the extraction pipeline, both patterns, the boundary rule, the exclusion list, and `head -1`. A consumer that writes a `grep -oE`, a `grep -vxE`, a `head -1`, or a literal `[A-Z][A-Z0-9]*-[0-9]+` anywhere in its own text is **violating this contract**, even if its copy currently agrees with this file. Copies do not track edits: a shape change here reaches a consumer that declared only a command, and silently bypasses one that pasted the pattern.

This applies to prose as well as code blocks. A consumer that needs to name the shape to a user — in a halt message, say — refers to [Ticket ID shape](#ticket-id-shape) rather than inlining the pattern, so the message cannot drift out of agreement with the rule it describes. A non-shell source is declared the same way: name what is read, not how a candidate is pulled out of it.

Consumers reference the sections above by anchor rather than restating them. Current consumers: `commit-protocol.md` and `pr-protocol.md`, each declaring its own binding inline.

## What this skill does NOT do

- Does not define any output format. Subject lines, titles, type enums, and length limits belong to the consumer.
- Does not resolve the description text that a ticket ID gets prefixed onto.
- Does not run git, create commits, or open PRs.
- Does not decide whether a ticket ID is mandatory — that is the consumer's terminal-behavior declaration.
