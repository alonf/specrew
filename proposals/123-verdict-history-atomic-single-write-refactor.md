---
proposal: 123
title: Verdict-History Atomic Single-Write Refactor (Boundary-Sync Atomicity Hardening)
status: candidate
phase: phase-2
estimated-sp: 5-8
priority-tier: 2
discussion: surfaced 2026-05-26 by Copilot's PR #934 review of F-046 v0.27.2; documented in F-046 findings.md Post-Review Note for Bug 2; explicit follow-up to F-046's "near-atomic sequential" achievement
---

# Verdict-History Atomic Single-Write Refactor

## Why

F-046 v0.27.2 Bug 2 ("Boundary cursor advances without verdict_history append") promised "Option A atomic single-pass" architecture in spec.md but the shipped implementation is **near-atomic sequential** — two separate writes to `.specrew/start-context.json`:

1. `Add-SpecrewBoundaryAuthorization` (in `shared-governance.ps1:1546`) reads start-context.json, mutates `boundary_enforcement`, writes via `Write-Utf8FileAtomic`
2. `Update-SpecrewStartContext` (in `sync-boundary-state.ps1:486-533`) reads start-context.json again (post-step-1), mutates `session_state`, writes via `Write-Utf8FileAtomic`

Each individual write is filesystem-atomic (write-temp-then-rename). But the SEQUENCE of two writes has a window — measured in milliseconds — where the file is in an intermediate state: `boundary_enforcement.last_authorized_boundary` advanced + `verdict_history` appended, but `session_state.boundary_type` still on the previous value. Crash / interruption / power-loss in that window leaves the file in a state the validator would not classify as drift (both fields are valid; they just don't match each other).

Copilot's PR #934 review correctly identified this as a real architectural finding:

> `Add-SpecrewBoundaryAuthorization` persists `boundary_enforcement` by writing `.specrew/start-context.json`, and later `Update-SpecrewStartContext` writes the same file again for `session_state`. That means the "atomic" cursor+audit update is still two separate file writes, leaving a window where one section advanced without the other (crash/interruption => drift, just in the opposite direction). Consider computing both updates against one in-memory context and performing a single atomic write for the merged document.

F-046's findings.md Post-Review Note (Bug 2) documents the limitation and the mitigations in place (each write is atomic; both functions carry idempotency guards; re-running sync converges). The mitigations make the gap acceptable for v0.27.2 but the architectural finding deserves a proper fix as a follow-up.

## What

Refactor `Add-SpecrewBoundaryAuthorization`'s public signature so it returns the modified in-memory context object rather than persisting itself. Then `Invoke-SpecrewBoundaryStateSync` composes both deltas (boundary_enforcement update from the new function + session_state update from `New-SpecrewSessionState`) into one merged document and persists in a single `Write-Utf8FileAtomic` call.

### Pillar 1: Function signature refactor (~2-3 SP)

Split `Add-SpecrewBoundaryAuthorization` into two functions:

| Function | Behavior | Used by |
|---|---|---|
| `Get-SpecrewBoundaryAuthorizationDelta` (NEW) | Computes the boundary_enforcement mutation in-memory; returns the modified state hashtable; does NOT persist. Pure function. | `Invoke-SpecrewBoundaryStateSync` (calls then merges with session_state update); any future caller that wants composed atomic writes |
| `Add-SpecrewBoundaryAuthorization` (REFACTORED, signature preserved for backward compat) | Calls `Get-SpecrewBoundaryAuthorizationDelta` then persists. Existing callers continue to work. | Any direct invocation that doesn't need atomic composition with other updates |

This is a non-breaking refactor — `Add-SpecrewBoundaryAuthorization` keeps its current public signature; new callers can opt into the in-memory variant via `Get-SpecrewBoundaryAuthorizationDelta`.

### Pillar 2: Atomic composition in sync-boundary-state.ps1 (~2 SP)

Update `Invoke-SpecrewBoundaryStateSync` (in `scripts/internal/sync-boundary-state.ps1:1070-1113`) to:

1. Read start-context.json once into `$existingContext`
2. Call `Get-SpecrewBoundaryAuthorizationDelta` (Pillar 1) against `$existingContext` to get the boundary_enforcement delta
3. Compute session_state delta in-memory
4. Merge both into one composite context object
5. Persist via single `Write-Utf8FileAtomic` call

The two-write sequence becomes a one-write atomic update.

### Pillar 3: Test coverage (~1-2 SP)

Extend `tests/integration/boundary-sync-atomic.tests.ps1` (created in F-046):

- Assert single-write behavior (e.g., via file-mtime delta check, or via a wrapper around Write-Utf8FileAtomic that counts invocations)
- Assert crash-recovery semantics: simulate write interrupted at temp-file stage; re-running sync converges atomically to the correct end state

### Pillar 4: Caller audit + migration (~1 SP)

Audit all 17+ call sites of `Add-SpecrewBoundaryAuthorization` (from F-046 review evidence) and decide which should migrate to `Get-SpecrewBoundaryAuthorizationDelta` for atomic composition vs which legitimately need the standalone persist path. Document the migration decision in a comment block at each call site.

## How

| Step | File | Effort |
|---|---|---|
| Pillar 1 split function | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) | 2-3 SP |
| Pillar 2 atomic composition in sync | `scripts/internal/sync-boundary-state.ps1` | 2 SP |
| Pillar 3 test extensions | `tests/integration/boundary-sync-atomic.tests.ps1` | 1-2 SP |
| Pillar 4 caller audit + migration decisions | walk through grep results; add `# atomic-composition: opt-in / standalone-ok` comments | 1 SP |

Total ~5-8 SP. Phase 2, small-fix slice shape (Proposal 067).

## Acceptance criteria

- **AC1**: `Get-SpecrewBoundaryAuthorizationDelta` is a pure function (does not touch the filesystem); returns the modified state hashtable
- **AC2**: `Add-SpecrewBoundaryAuthorization` keeps its current public signature; existing callers work unchanged
- **AC3**: `Invoke-SpecrewBoundaryStateSync` performs exactly ONE `Write-Utf8FileAtomic` call per sync invocation when boundary_enforcement is active (verified by test wrapper)
- **AC4**: After the refactor, both `session_state.boundary_type` and `boundary_enforcement.last_authorized_boundary` either both advance OR both remain unchanged — no intermediate state observable in start-context.json
- **AC5**: Crash-recovery test: simulating interrupt at the temp-file rename stage leaves either the old or new state; never an intermediate; re-running sync converges
- **AC6**: All 17+ `Add-SpecrewBoundaryAuthorization` call sites audited and annotated with migration decision
- **AC7**: Mirror parity preserved (extensions/ === .specify/extensions/)
- **AC8**: F-046's existing `boundary-sync-atomic.tests.ps1` still passes (no regression)

## Out of scope

- **Refactoring `Set-SpecrewBoundaryEnforcementState`** — orthogonal; separate slice if needed
- **Cross-file atomicity** (e.g., decisions.md + start-context.json updated atomically together) — much bigger scope; out
- **Distributed-system atomicity** (multi-developer concurrent boundary syncs) — Proposal 010 (Multi-Developer Reconciliation) owns; out
- **Removing the pre-existing `Add-SpecrewBoundaryAuthorization` API** — backward-compat required; standalone path preserved

## Composition

- **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning)** — adjacent. The two-write window is a form-vs-meaning gap at the persistence layer
- **Proposal 010 (Multi-Developer Reconciliation)** — composes. Single-write atomicity is a prerequisite for clean multi-developer cursor merging
- **Proposal 035 (Session-State Durability)** — same file (start-context.json) is the subject; this refactor strengthens 035's durability story
- **Proposal 067 (Small-Fix Slice Type)** — natural fit; 5-8 SP single-iteration shape
- **F-046 v0.27.2** — direct prerequisite; this proposal lands the architectural goal that F-046 declared

## Risks

- **Backward compatibility on `Add-SpecrewBoundaryAuthorization` signature** — must be preserved for the 17+ callers. Mitigation: keep current function as thin wrapper around new delta+persist sequence
- **In-memory mutation order matters** — boundary_enforcement update must compose cleanly with session_state update. Mitigation: write integration test that exercises both happy-path + race-window scenarios
- **Temp-file rename atomicity on Windows** — `Write-Utf8FileAtomic` uses MoveFile; semantics differ slightly from POSIX rename. Mitigation: existing helper has been battle-tested; no change to that primitive
- **Caller migration churn** — 17+ call sites is a lot to touch. Mitigation: Pillar 4 only annotates with migration decision; actual migration to the in-memory variant is per-caller and can be deferred

## Empirical motivation

2026-05-26 Copilot PR #934 review of F-046 v0.27.2. Comment quoted in full:

> `Add-SpecrewBoundaryAuthorization` persists `boundary_enforcement` by writing `.specrew/start-context.json`, and later `Update-SpecrewStartContext` writes the same file again for `session_state`. That means the "atomic" cursor+audit update is still two separate file writes, leaving a window where one section advanced without the other (crash/interruption => drift, just in the opposite direction). Consider computing both updates against one in-memory context and performing a single atomic write for the merged document.

F-046 findings.md Post-Review Note acknowledged the limitation, documented the mitigations (each write is filesystem-atomic; idempotency guards in both functions; re-running sync converges), and explicitly queued this proposal as the follow-up:

> True single-write atomicity (compute both deltas in one in-memory context, then `Write-Utf8FileAtomic` once) requires refactoring `Add-SpecrewBoundaryAuthorization`'s public signature to return the modified context instead of persisting itself, plus updating all other callers. That's out of scope for F-046 (a bug-bash bundle). Queued as a follow-up small-fix slice alongside Proposal 105 (Host-Native Hook Deployment) work.

## Cross-references

- file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md
- file:///C:/Dev/Specrew/proposals/035-session-state-durability.md
- file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md
- file:///C:/Dev/Specrew/specs/046-046-bug-bash/findings.md (Bug 2 Post-Review Note)
- file:///C:/Dev/Specrew/specs/046-046-bug-bash/iterations/001/review.md
- PR #934 review comments

## Status history

- 2026-05-26: candidate proposal drafted as follow-up to F-046 v0.27.2 PR #934 Copilot review finding on Bug 2 atomicity. Architectural finding acknowledged in F-046 findings.md Post-Review Note; this proposal lands the proper fix.
