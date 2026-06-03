# Iteration State: 002

**Schema**: v1
**Last Completed Task**: T006
**Tasks Remaining**: (none — all iteration-002 tasks complete)
**In Progress**: (none)
**Baseline Ref**: 464e0d3e97cf031525447690447fe81d8e98b7d4
**Updated**: 2026-06-03T00:28:23Z
**Current Phase**: review-signoff
**Iteration Status**: reviewing

## Execution Summary

Slice 1 (FR-024 stale cross-worktree session recovery) committed as `075b09e2`:

- **T007 (done)** — Stale-session detection + recovery guard. As directed by the maintainer (2026-06-02), the recovery/session-state functions were extracted out of `scripts/specrew-start.ps1` (4461 → 3963 lines) into a dot-sourceable helper `scripts/internal/session-recovery.ps1` (compatibility wrapper at `specrew-start.ps1:56-60`; added to `Specrew.psd1` FileList). `Test-SpecrewStaleSessionState` flags a saved `feature_path` that is missing or outside the current worktree; `Resolve-SpecrewRecoverySelection` choice A refuses to re-anchor to such a path and requests confirm-gated cleanup. Runtime-verified (direct entry-script run + unit tests).
- **T008 (done)** — Confirm-gated cleanup execution `Clear-SpecrewStaleSessionReference` (clears only start-context `session_state` + the matching `active-sessions` entry; never touches `specs/**`; makes no commits) plus a pure enforcement bridge `Invoke-SpecrewStaleSessionCleanupDecision`, wired into the live recovery flow via `Read-SpecrewYesNo` (EOF-safe → no-op in CI). Cleanup execution runtime-tested at the function level (mutates real fixtures).
- **T009 (done)** — Function/unit-level regression tests in `tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1` (detection, guard, cleanup execution, enforcement decision, + Group 7 strict merge-detection) PLUS the **end-to-end enforcement integration test** in `tests/integration/start-recovery-flow.tests.ps1`: it drives the real `specrew start` interactive flow (stale missing-path session → choice A → confirm `y`) and asserts the cleanup STICKS end-to-end — refs cleared, sibling session + `specs/**` artifacts preserved, no commits, and the regenerated start-context records no active session.
- **Strict merge-detection root-cause fix (commit `65e157fa`, part of T009/FR-024 regression coverage)** — `Test-SpecrewFeatureMergedToMain` matched `git log --grep` on the bare numeric feature id, so a Feature 049 merge whose body said "Proposal 120 + 141" falsely classified Feature 141 as merged and triggered the stale-state re-anchor that opened the 2026-06-02 recovery session. Fixed in BOTH copies (`scripts/internal/session-recovery.ps1` config-driven date + `scripts/internal/sync-boundary-state.ps1` hardcoded window) to grep the FULL feature-ref slug as a `--fixed-strings` exact substring, never the bare number. Added **Group 7** to the FR-024 unit test (a "Proposal 120 + 141" body does NOT mark Feature 141 merged; a genuine `alonf/141-design-gate-runtime-hardening` merge still IS detected) and corrected two integration fixtures (`stale-state-detection`, `feature-051-iteration2a-callsite-wiring`) whose unrealistic bare-number merge messages were only green because of this bug. `specrew start` re-run confirms the false re-anchor is gone (`recovery_session: null`). This strengthens T009/FR-024 regression coverage but does **NOT** complete FR-024.

**FR-024 is COMPLETE (2026-06-02).** The T009 end-to-end enforcement test landed; getting it to pass required three fixes in this slice:

1. **Test-harness stdout-drain deadlock fixed** — `Invoke-InteractiveStart` called `WaitForExit()` before `ReadToEnd()`, so the child blocked once the OS pipe buffer filled under `specrew start`'s heavy recovery transcript. Now drains stdout/stderr via `ReadToEndAsync()` from process start, so the buffer never fills.
2. **Enforcement gap fixed (real defect the e2e caught — see drift-log Event 1)** — the confirm-gated cleanup cleared `start-context.json` `session_state`, but the same `specrew start` run's end-of-run regeneration re-serialized the stale in-memory `$validatedSessionState` and silently re-anchored the deleted feature (`active=true`). The cleanup did NOT stick for `start-context.json` (active-sessions.yml cleared correctly), so the next start would re-detect the same stale session in a loop. Fixed in `scripts/specrew-start.ps1`: after a confirmed+cleared cleanup, `$validatedSessionState` is nulled so the regenerated context records no active session (mode → intake-or-resume). The unit test could not catch this because it exercises `Clear-SpecrewStaleSessionReference` in isolation; only the e2e flow surfaced it.
3. **`Test-SpecrewFeatureBranchExists` stderr noise fixed** — see the note below.

Latent follow-up (not chased here, out of scope): the start-context regeneration round-trips `recorded_at` through `ConvertTo-Json`/`ConvertFrom-Json`, coercing the ISO-8601 string to a culture-formatted `MM/dd/yyyy` DateTime. Moot once `session_state` is null after cleanup, but worth fixing on the session-preserved path.

Regression green this slice (re-run after the FR-024 e2e + start-flow fix): `start-recovery-flow` (6/6, incl. the new FR-024 e2e enforcement test), `design-gate-runtime-hardening` unit (all groups incl. Group 7; 0 transcript-noise lines), `stale-state-detection` (5/5), `feature-051-iteration2a-callsite-wiring` (6/6).

**Transcript noise — FIXED this slice.** `Test-SpecrewFeatureBranchExists` now redirects the `git show-ref` stderr (`2>$null`); the decision is taken purely from `$LASTEXITCODE`, so behavior is unchanged. The FR-024 unit test re-run emits **0** `fatal: not a git repository` lines (verified), so the previously-noted noise is gone and the transcript is clean.

## Slice: FR-011 (empty `specs//` paths) + FR-014 (host-wording leak)

Reproduce-first, committed in this slice:

- **T001 (done)** — Reproduced both defects. FR-011: the empty `specs//` is born when the coordinator substitutes the `<feature>` placeholder per Rule 48 with no feature (greenfield/intake); confirmed via the renderer `Get-SpecrewHostOrientationBlock` emitting a `file:///…/specs/<feature>/` browse URL even when `$FeatureRef` is empty (a file-layer grep is vacuous because the file holds the literal placeholder). FR-014: a greenfield `specrew start --host claude` prints "Copilot approval mode: allow-all" (`specrew-start.ps1`, unconditional). Recorded in the drift-log Reproduction Evidence section.
- **T002 (done, FR-011)** — `Get-SpecrewHostOrientationBlock` now guards the "What you can browse" line: when `$FeatureRef` is empty it emits explicit-placeholder guidance (no `file:///…/specs/<feature>/` URL that collapses to `specs//`); a resolved-feature resume still surfaces the concrete browse paths. Renderer-level reproduce-first test in `tests/integration/multi-host-launch-path.tests.ps1` (Test 9b).
- **T003 (done, FR-014)** — Two host-wording leaks fixed in `scripts/specrew-start.ps1`: the approval-mode launch line is now host-neutral ("Approval mode:" not "Copilot approval mode"), and the new-window delegation success line uses the host-aware `$hostLabel` instead of a hardcoded "Delegated to Copilot". Test 18b asserts both are absent. Runtime-verified: greenfield `--host claude` now prints "Approval mode: allow-all" and the greenfield browse line carries no collapsing feature URL.
- **T005 (in-progress)** — FR-011 (no `specs//`) + FR-014 (per-host wording) test coverage landed; the clean-harness-exit portion is paired with T004 (deferred) and remains.

Regression green this slice: `multi-host-launch-path` (incl. Test 9b + Test 18b), `start-recovery-flow` (6/6), `start-command`.

**Still remaining (per maintainer sequencing):** T004 (gate-harness trailing `$LASTEXITCODE` exit cleanup) and T006 (docs). FR-011/FR-014 were prioritized first; T004/docs are the later slice.

## Boundary Authorization Reconciliation (2026-06-02)

Honest reconciliation — NOT a backdated record. Implementation of iteration 002 (FR-024, FR-011, FR-014) had already proceeded this session under the maintainer's explicit per-slice go-aheads, but `boundary_enforcement.verdict_history` was never written, so `specrew start` resumed at `before-implement` with an empty verdict ledger (the validator soft-warned `state-advance-without-verdict`). The missing `tasks -> before-implement` authorization was recorded **now** via `Add-SpecrewBoundaryAuthorization` with the **current** commit (`2e80e9e2`) and timestamp (`2026-06-02T23:24:28Z`) and `authorizing_human: Alon Fliess` — deliberately **not** backdated to the original `07294d58` / `2026-06-02T18:48:03Z`. The verdict_history entry lives in file:///C:/Dev/Specrew-design-analysis/.specrew/start-context.json (the canonical runtime location the validator reads; gitignored), so this committed note is its durable audit trail.

## Slice: T004 (verify-clean) + T005 close

- **T004 (done — verify-clean, maintainer-approved disposition 2026-06-02).** Reproduce-first showed the iteration-1 smoke symptoms are not produced by any committed code path: `GATE_VALID: True` is in no source (improvised manual echo), `Invoke-SpecrewDesignAnalysisPlanBoundaryGate` returns `Valid=True` with `$LASTEXITCODE=0` and no stray error on a valid artifact (verified on 141/001 and a unit fixture), and both quality/prereq command paths resolve. No code change; closed with a durable guard test in file:///C:/Dev/Specrew-design-analysis/tests/unit/design-gate-runtime-hardening.tests.ps1 (asserts clean exit code + path resolution). See drift-log Reproduction Evidence.
- **T005 (done).** All three test concerns covered: no `specs//` (FR-011 Test 9b) + per-host wording (FR-014 Test 18b) in `multi-host-launch-path.tests.ps1`, and clean harness exit (the T004 guard) in the feature-141 unit test.

## Slice: T006 (docs/review evidence) + implement-phase complete

- **T006 (done).** Updated file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/quickstart.md (Iteration 2 delivered section with concrete verification steps + test names for FR-011/FR-014/FR-024 + the gate clean-exit) and file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/contracts/design-gate-runtime-hardening.md (as-built Iteration 2 surface: the orientation-block guard, host-neutral launch wording, strict merge detection, the stale-session recovery/cleanup functions, and the gate clean-exit invariant; FR-012/FR-013 reshaped to the Iteration 3 smoke-bundle).

**All iteration-002 tasks are complete (T001-T009).** The implement phase is done; the iteration is stopped at the **review-signoff** gate awaiting the maintainer's verdict. The boundary has NOT been crossed (no review-signoff verdict recorded); review.md + reviewer artifacts will follow the maintainer authorizing review.

## Notes

- Update this file after each task completes.
- Keep task identifiers aligned to plan.md.

<!-- >>> specrew-managed escalation-state >>> -->
## Repair Escalation

- **Status**: inactive
- **Artifact**: (none)
- **Gate**: (none)
- **Failure Count**: 0
- **Current Tier**: efficiency
- **Current Owner**: (none)
- **Locked Out Agents**: (none)
- **Last Escalated**: (none)
- **Resolved At**: (none)
- **Notes**: (none)
<!-- <<< specrew-managed escalation-state <<< -->