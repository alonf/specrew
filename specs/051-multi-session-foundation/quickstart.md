# Quickstart: Multi-Session Foundation

**Feature**: 051-multi-session-foundation
**Last verified**: 2026-05-31 (planning artifact — verified against implemented behavior at review boundary)

This walkthrough shows how to exercise the Iteration-1 surface (session mode + file classification) and the later collision/claim/identity-split behavior. Iteration 1 (FR-001 through FR-006) is the foundation; later iterations add the runtime coordination it gates.

## Run it

```powershell
# From a Specrew-managed project root
pwsh -File scripts/specrew.ps1 config set session_mode multi   # enable multi-session (FR-002)
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .   # confirm no regressions
Invoke-Pester tests/                                               # run the acceptance + governance suites
```

## Try the canonical scenario (Iteration 1: US1 + US2)

1. **Enable multi-session mode.** Run `specrew config set session_mode multi`.
   - Expected: `.specrew/config.yml` now contains `session_mode: multi` and a success line is printed (FR-001, FR-002).
2. **Revert and confirm default.** Run `specrew config set session_mode single`.
   - Expected: config reverts to `single` (Acceptance Scenario US1.2).
3. **Confirm fresh-init default.** In a brand-new `specrew init` project, inspect `.specrew/config.yml`.
   - Expected: `session_mode: single` even though it was never set explicitly (FR-003, Acceptance Scenario US1.3).
4. **Generate the per-session gitignore.** Run `specrew init` (or re-run it).
   - Expected: `.gitignore` now excludes `.specrew/last-*`, `.specify/feature.json`, `.specrew/start-context.json`, `.specrew/host-history.json`, `.specrew/.cache/`, `.squad/sessions/`, `.squad/decisions/inbox/`, `.specrew/last-validator-summary.json`, and `.squad/identity/session-state.*` (FR-005).
5. **Verify index cleanup.** If any per-session file was previously committed, confirm it was removed from the git index but still exists on disk.
   - Expected: `git status` shows it untracked; the working-tree file is intact (FR-006, `git rm --cached` pattern).

## Verify the edge cases

- **Concurrent session collision (US3 → FR-010).** With a live session for feature `051`, start a second session for `051` from another worktree.
  - Expected: a warning naming the other `user@machine` and start time, within 2 seconds (SC-002).
- **Stale lock auto-clear (FR-011).** Hand-edit an `active-sessions.yml` entry's `last_heartbeat_time` to >24h ago, then start a session.
  - Expected: the stale lock is cleared with a notice; your session starts cleanly.
- **Feature claim warning (US4 → FR-015).** Claim feature `051`, then attempt to start it as a different `user@machine`.
  - Expected: `"Feature 051 is currently claimed by ... Continue anyway?"` — `y` records both claims and proceeds; `n` exits without creating a session.
- **Brand-new worktree skips recovery (US9/US10 → FR-039/FR-040).** Clone a fresh worktree from main (inheriting old `session_state_*`), then `specrew start --feature 051-new` on a brand-new branch with no iteration dirs/boundary commits.
  - Expected: NO A/B/C stale-state prompt; you land directly in the new-feature specify flow. The decision + signals are logged to `.specrew/session-start.log` (FR-042).
- **Genuine inconsistency still prompts (FR-041).** In a worktree that *does* have iteration dirs for an inherited feature whose path mismatches the current branch, run `specrew start`.
  - Expected: the A/B/C recovery prompt IS shown (recovery preserved for true conflicts).
- **Tracked-file leak guard (FR-038).** Ensure no git-tracked file contains a `session_state_` token after the identity split.
  - Expected: `specrew start`'s guard passes; if a tracked file leaks `session_state_`, it errors with the offending path.

## What "done" looks like

Two developers run a full specify→plan→tasks→implement→review cycle on different features concurrently with zero merge conflicts on per-session files (SC-001), collision/claim warnings fire correctly, the Spec-Kit upgrade to 0.8.18 validates clean (SC-004), and `specrew update` leaves `specrew_version` exactly matching the installed module (SC-005).
