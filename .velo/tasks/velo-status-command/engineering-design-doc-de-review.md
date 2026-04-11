# Distinguished Engineer Review: velo:status Command

> Reviewer: Distinguished Engineer
> Date: 2026-04-11
> Doc reviewed: `engineering-design-doc.md` v1.0
> PRD reviewed: `prd.md` v1.0

---

## Distinguished Engineer Review

### Critical (must fix before build)

**1. Phase name inconsistency between PRD schema and engineering design doc schema**

The PRD's `status.json` schema example uses `"engineering-design-doc"` as a phase name (L238 of PRD). The engineering design doc's TypeScript interface comment (Data Models, L130) lists `"engineering-doc"` as the canonical name for the same phase, and the concrete JSON example (L199) confirms `"engineering-doc"`. The command output example (L68) also renders it as `"engineering-doc"`.

This is a contract collision. The PRD is the source of truth for the schema, and the engineering design doc must align with it — or explicitly supersede it with justification. If the canonical name becomes `"engineering-doc"`, every reference in `new.md`, `task.md`, the Gate interface (`"engineering-doc-approval"` vs `"engineering-design-doc-approval"`), and the approval gate name in the concrete JSON must all agree. Right now they do not: the Gate interface hardcodes `"engineering-doc-approval"` (Data Models), but the gates concrete JSON example uses `"engineering-doc-approval"` — while the PRD's gates example uses `"engineering-design-doc-approval"` (L292-295 of PRD).

A downstream engineer implementing `new.md` modifications and a separate engineer implementing `status.md` rendering will produce incompatible output from this ambiguity alone.

**Fix**: Pick one canonical string (`"engineering-doc"` is the shorter and more consistent choice given D10), update the TypeScript interface comment, the concrete JSON example, the Gate interface, and the PRD schema example to agree. Document the canonical phase name list explicitly in a single authoritative table in the engineering design doc.

---

**2. Status Write Protocol does not specify how Velo identifies which agent entry to update**

The protocol (After an agent returns) says: "Update the matching agent entry (last entry with that name and `status: 'in_progress'`)". This works for sequential single-instance agents. It breaks in two real cases that `new.md` already produces:

- **Parallel agents in the same phase**: `be-engineer` and `fe-engineer` both have `status: "in_progress"` simultaneously in the build phase. If a third parallel agent with the same name were spawned (revision loop), the "last entry with that name" rule would match the wrong entry.
- **Revision cycles**: The engineering design doc review loop in `new.md` can spawn `tech-lead` multiple times. During the revision loop, there can be two `tech-lead` entries: one `"completed"` (original run) and one `"in_progress"` (revision run). The "last entry with that name and status in_progress" rule handles this correctly — but only as long as the match is by name AND status. The engineering design doc should make this matching rule explicit, not implicit.

More critically: the protocol does not specify a stable entry identifier. Using `(name, in_progress)` as the lookup key means two parallel agents with the same name cannot be distinguished. While the current agent roster does not have duplicate-named parallel agents, this is a latent bug that will surface the moment the workflow is extended.

**Fix**: Add a `run_id` field (UUID or monotonic integer) to `AgentEntry`, written at spawn time and used as the stable key for the post-return update. The write protocol then becomes: "Update the entry with matching `run_id`." This is robust across parallel, sequential, and revision scenarios.

---

### Significant (should fix)

**3. The `Gate.name` type is a closed enum that will break when new gates are added**

```typescript
name: "prd-approval" | "engineering-doc-approval";
```

This is hardcoded to exactly two values. `new.md` already has two approval gates; any future command that adds a third gate (e.g., a security review gate, a deployment approval gate) requires a schema change to the TypeScript interface and any code that reads/validates it. Using a closed union here bakes today's workflow into the schema permanently.

The PRD's `Gate.name` example in the schema section uses the same values but does not indicate they should be a closed enum. Given that D4 says the agents array is append-only and designed for extensibility (revision cycles), gates should follow the same philosophy.

**Fix**: Change `Gate.name` to `string` and add a comment documenting the known values as of v1. This matches the `PhaseName = string` treatment applied to phases.

---

**4. No specification for how `new.md` and `task.md` handle JSON read-modify-write**

The Status Write Protocol section describes what to write at each lifecycle event. It does not specify how Velo reads the existing `status.json`, modifies it in memory, and writes it back atomically. For a Velo agent (an LLM running tool calls), the write pattern is: read file → modify → overwrite. If two parallel agents (e.g., `be-engineer` and `fe-engineer`) both complete nearly simultaneously and both trigger a phase-completion write (updating `phases[build].status = "completed"`), there is a race: the second write overwrites the first agent's update.

This is not theoretical: `new.md` explicitly runs FE and BE engineers in parallel. Both will trigger the "After an agent returns" write. If they return within the same tool-call window, the phase transition write from one will clobber the other's agent entry update.

**Fix**: The protocol should specify that each write must: (1) read the current `status.json` before writing, (2) merge the new data into the existing document, (3) write the full document back. Additionally, the "After a phase completes" write should be triggered only by whichever agent is last to finish in the phase — not independently by each agent. The engineering design doc should make this sequencing explicit with a note like: "The phase completion write is idempotent and may be performed by Velo (the orchestrating command) after all parallel agents in the phase have returned, not by individual agents."

---

**5. US-2 (agent details with artifacts, duration, tokens) is marked P1 but the schema is fully specified as P0**

The data model includes `duration_ms`, `tokens`, `tool_uses`, `artifacts`, and `error` on every agent entry. The Status Write Protocol requires writing all of these at agent return time (Step "After an agent returns"). This means the full data collection burden is baked into `new.md` and `task.md` modifications regardless of priority.

However, the rendering of this data in `velo:status` is deferred to P1 (US-2). This creates an inconsistency: the write side is P0 (must happen for any status file to be useful), but the read/display side is partially P1. The engineering design doc should explicitly acknowledge this: "All fields are written at agent return time in v1 (write-path is P0). The status command renders the full agent detail block (artifacts, tokens, tool_uses) as P1 — in P0 it may display only name, phase, outcome, and duration."

Without this clarification, the build engineer modifying `new.md` does not know whether to implement the full field set or a subset. This will cause scope confusion.

---

### Minor (worth noting)

**6. The `--json` flag outputs "raw `status.json` content" — this needs precision**

The command interface says `--json` outputs "raw `status.json` content". For a task with no slug argument, this is the `status.json` of the most recently modified task. For `--list --json`, the meaning is undefined — is it an array of all `status.json` documents, or a summary object? The engineering design doc notes `--list` and `--json` are mutually exclusive with `slug`, but does not address their combination with each other.

If `--list --json` is not supported, the error output table should include it. If it is supported, the output shape must be defined.

---

**7. Stale detection heuristic (D5) uses `task.updated_at`, not agent-level timestamps**

The stale detection rule is: "flag if `updated_at` is >30 minutes old and any agent entry has `status: 'in_progress'`". The `updated_at` field is on the `task` metadata and is updated on every write. This means a task with a long-running agent that is actively writing partial results (which it does not — agents do not write to `status.json` themselves) would never go stale. But more importantly: if a crash occurs after the pre-spawn write but before any subsequent write, `task.updated_at` reflects the spawn time, which is correct. The heuristic works for this case.

The edge case is: if a non-crashed, actively running agent takes >30 minutes (large codebases, slow models), it will be incorrectly flagged as stale. The 30-minute threshold is an assumption about agent runtime that may not hold. This should be documented as a known limitation with a note that the threshold is tunable.

---

**8. `commands/status.md` has no description of how it resolves "most recently modified task"**

The command defaults to "most recently modified task by `status.json` mtime". The engineering design doc does not specify whether "mtime" means filesystem modification time (`stat`), the `task.updated_at` field in the JSON, or both (with one as fallback). These can diverge if the file is copied, synced via cloud storage, or if `updated_at` is not correctly maintained. The implementation should pick one source of truth and document it. Recommendation: use `task.updated_at` from within the JSON, since it is deterministic and portable across filesystems.

---

**9. Phase duration is not stored in the `Phase` object — only derivable**

`Phase` has `started_at` and `completed_at` but no `duration_ms`. `AgentEntry` has `duration_ms` explicitly. The rendering example shows phase duration in the table ("10m 00s"). The status command will need to compute this on the fly from `completed_at - started_at`. This is fine, but it is an inconsistency: agent duration is pre-computed and stored, phase duration is not. There is no engineering reason for the asymmetry. Either store both pre-computed or derive both. As-is it is a minor implementation gotcha that a build engineer will notice.

---

### Verdict

**REVISE**

Two Critical issues (phase name collision, missing stable agent entry identifier) and two Significant issues (closed Gate enum, unspecified read-modify-write protocol for parallel agents) must be resolved before build begins. The parallel-agent write race in particular will produce silent data corruption in the most common `velo:new` scenario (parallel FE + BE build phase) — it is not a corner case.
