# Feature 203 iteration 001 review, Round C: extension scripts, dispatcher, hosts

This round's focus is the area below. The whole tree is frozen and in scope; spend your time on this area first.

## What this iteration changed

- **What changed**: feature 203 iteration 001, from `fca9067e` (the before-implement baseline) to `32d2af39`:
  298 commits, 330 files, +25,215 / -6,885 lines. The frozen tree has no diff in it. The full list of
  changed files with their line counts is in `docs/review-scope/changed-files.txt`. Read that list before
  choosing what to open.
- **The iteration's contract**: `specs/203-beta5-stabilization/spec.md` and
  `specs/203-beta5-stabilization/iterations/001/plan.md` (the task table: T001 to T013 done, T014 planned).
  The engine resolves both automatically.
- **Not defects of this iteration** (deferred by the maintainer's rulings; do not report them as missing):
  - FR-041: drift entries do not carry the turn identity yet (iteration 002).
  - FR-042: replay through Copilot's and Codex's real hooks across a compaction, and the Codex out-of-tail
    case (iteration-002 three-host walk).
  - The out-of-band boundary approval decision (iteration 002).
  - Two suites known red under B5F-036: `project-path-resolution-regression.ps1` and
    `validator-hardening-iteration2.ps1`.
  - T014 (pin advance): the live hooks still run engine `a56ac787`. This round reviews the source, not the
    deployed engine.
- **Stripped from the frozen tree**: `.specify/**`, `.specrew/**`, `.squad/**`. The `.specify` copies are mirrors of
  `extensions/specrew-speckit/`; review the `extensions/` source.
- **Severity**: a blocking or major finding states a concrete failure scenario. Prefer one proven defect over
  several suspicions.
- **If you have a shell**: the frozen tree is a git worktree at `32d2af39`; `git diff fca9067e -- <path>` shows the
  iteration's change to a file.

## Focus: Round C: extension scripts, dispatcher, hosts

**Files changed in this area:**

| File | +/- | Tasks (requirements) |
|---|---|---|
| `extensions/specrew-speckit/scripts/turn-end-store.ps1` | +395 / -300 | T011 (FR-046), T002 |
| `.../shared-governance.ps1` | +339 / -23 | T013 (sender check in the cycle-scoped verdict matcher, health line) |
| `.../specrew-hook-dispatcher.ps1` and `scripts/internal/specrew-hook-dispatcher.ps1` | +288 / -19 each | T002 (FR-014), T013 (peer origin rule) |
| `.../deploy-refocus-hooks.ps1` (and its `scripts/internal` twin) | +222 / -34 | T002 |
| `.../live-engine-resolution.ps1` | +162 / -0 | T002 (FR-014) |
| `.../design-decision-store.ps1`, `record-design-decision.ps1` | +178 / -16 | T004 |
| `.../specrew-conformance-provider.ps1` | +120 / -66 | T011 (FR-046) |
| `.../declare-turn-end.ps1` | +21 / -93 | T011 |
| `.../workshop-authority-store.ps1` | +60 / -3 | T013 (workshop sender check) |
| `.../specrew-*-provider.ps1` (4) | small | T002 |
| `hosts/{antigravity,claude,copilot,cursor}/host.psd1` | +36 / -0 | T003, T013 |

**Attack these:**

1. **A configured pin that falls back.** Can any engine load or hook path run the worktree's source, or the
   installed module, when a pin is configured but missing, corrupt or moved?
2. **Peer and host origin rules.** Can a cross-session message or a host-injected prompt be classified as a typed
   user prompt by the dispatcher defaults or by any `host.psd1`?
3. **The Stop check (FR-046).**
   - Can a reply pass with a decision part missing, or with an approval line it did not offer?
   - Does the check fail open when the pending-verdict record is absent?
4. **The verdict matcher's mandatory `-ProjectRoot`.** Look for:
   - a caller that omits it;
   - a `hook-captured*` verdict accepted without the sender check;
   - a workshop getter that skips it.
