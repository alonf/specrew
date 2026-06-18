# Data and Storage Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-16
**Depth**: Light
**Confirmation**: human-confirmed (lens-question scope)

## Data Types and Ownership

```text
Session/journal runtime state
  Owner: hook dispatcher/provider path
  Files: .specrew/runtime/refocus-state-*.json and related journal/dedupe/breaker state
  Decision: per-launch fallback token replaces global unknown when host session ID is missing/malformed.

Start/context and closeout state
  Owner: sync-boundary-state / closeout flow
  Files: .specrew/start-context.json, dashboard/closeout artifacts as applicable
  Decision: closeout sync reflects real upstream/dirty/dashboard state; do not silently preserve stale dashboard on auto-detect.

Deployed extension mirror
  Owner: source change task + mirror parity checkpoint
  Files: .specify/extensions/specrew-speckit/... mirrors source extension files
  Decision: source is authoritative; mirror follows source for touched files.

Antigravity hook configuration
  Owner: hook deployment path
  Files: project-scoped .agents/hooks.json using the current official Antigravity hook contract
  Decision: Specrew-owned hook entries are merge-managed and preserve user hook entries.

Tests/scratch state
  Owner: test fixtures
  Files: temp/scratch git repos and synthetic SessionStart event payloads
  Decision: fixtures are disposable and must not read or depend on the real repo's dirty state.
```

No database or migration system is introduced.

## Consistency, Retention, and Migration

Consistency:

- Runtime state writes remain local-file based and best-effort.
- Session identity fix prevents cross-session key collision from missing IDs.
- Side-by-side Copilot, Claude, and Codex in one VS Code worktree remains
  advisory concurrency only.
- Switching between already-open hosts can leave stale chat context; disk
  artifacts are authoritative.
- Rolling handover is latest-writer-wins, not a lock.
- True parallel implementation should use separate worktrees.
- Closeout sync derives dashboard/message state from current repo artifacts, not
  cached assumptions.
- Antigravity hook configuration writes are merge-aware and do not replace
  unrelated user hook entries.

Retention:

- Runtime journal/dedupe/breaker files keep existing retention behavior.
- Synthetic test fixtures are disposable.
- Governed spec/plan/evidence artifacts remain durable.

Migration:

- No migration is required for old `refocus-state-unknown.json` files.
- New writes avoid creating or depending on global `unknown`.
- Cleanup of historical local runtime files is optional/manual.
- No migration is required for old Antigravity launcher-only sessions; new hook
  provisioning updates the support path after installation/update.

## Validation Evidence

```text
1. Session state
   Tests create missing/blank/malformed session IDs and verify new runtime state does not collapse into global unknown.

2. Multi-host advisory behavior
   Tests or manual evidence show same-worktree concurrent-session state is advisory and non-blocking.

3. Closeout state
   Tests prove closeout dashboard/message output is regenerated from current artifacts for auto-detect paths.

4. Test fixtures
   Tests prove scratch git state is isolated from the real worktree.

5. Antigravity hook config
   Tests prove Specrew-owned Antigravity hook entries can be added, refreshed, removed, and opt-out respected without clobbering user hooks.
```
