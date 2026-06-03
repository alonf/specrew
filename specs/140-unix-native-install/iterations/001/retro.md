# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-02
**Review verdict**: accepted (Crew Reviewer) → maintainer review-signoff **APPROVE WITH DEFERRED RUNTIME PROOF**

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1 | 1 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 2 | 2 | 0 |
| T006 | 2 | 2 | 0 |
| T007 | 4 | 4 | 0 |
| T008 | 2 | 2 | 0 |
| T009 | 2 | 2 | 0 |

**Average variance**: 0 SP. No task overflowed its estimate; the two real bugs (read-only-automatic-variable
assignments) and drift D-001 were caught and resolved *within* their owning task's scope, so the 1 SP rework
headroom (19/20) was not consumed. (AI-execution caveat: SP variance here is "did the task overflow its planned
scope," not clock-time — discovery/rework signal lives in *What Didn't Go Well* below, not in this table.)

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | included | included | 0 | Spec/clarify/plan/tasks approved at boundaries; 2-iteration split decided at plan→tasks. |
| Discovery/Spikes | 0 | 0 | 0 | Architecture resolved via Proposal 153 + clarify; no separate spike. |
| Implementation | 15 | 15 | 0 | T001-T005, T007. Two read-only-var bugs caught by tests, fixed in-scope; no overflow. |
| Review | 4 | 4 | 0 | T006, T009 (bidirectional parity) + review pass + Proposal 145 7-phase structured review. |
| Rework | buffer | 0 | -1 (unused) | 1 SP headroom not needed; fixes absorbed in-task. |

## Drift Summary

- Total drift events: 1
- Resolved via spec update: 1 (D-001 — data-model + contracts corrected from "copy" to "symlink")
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- **platform-not-proxy discipline held.** Git Bash on Windows was used only for `bash -n` syntax checking,
  never as a stand-in for the Ubuntu/macOS runtime verdict. The Unix runtime was *cleanly deferred* to
  Iteration 2 CI rather than faked green on a proxy — and that deferral is classified explicitly as accepted
  scope in `review-145.md`, not buried as a missed gate.
- **Tests caught two real bugs before they could ship.** `$home` (in `Resolve-SpecrewBinDir`) and `$IsWindows`
  (in the installer test) are PowerShell read-only automatic variables; both assignment bugs surfaced as test
  failures, not runtime surprises. The installer decision-matrix and producer/consumer parity tests earned
  their keep.
- **Closed the FileList directional blind-spot class by construction.** generate-then-commit with a `-Check`
  drift guard + *bidirectional* parity (registry↔wrapper AND FileList↔disk) structurally prevents the
  v0.27.3 / v0.28.0-beta.1 FileList-omission shape (a new file missing from `FileList` → runtime crash). The
  parity is enforced as a unit test, not a convention.
- **Security lens applied up front, not retrofitted.** All five maintainer-flagged surfaces (bin-dir
  confinement, `curl|sh` trust wording, argument forwarding, symlink resolution, `pwsh`/ExecutionPolicy) were
  reviewed as a first-class lens during implementation.
- **The 2-iteration split kept Iteration 1 honest.** Splitting at plan→tasks (core vs. runtime+CI+docs+release
  gate) produced a fully unit-tested platform-agnostic core (22 checks, 19/20 SP) instead of an oversized
  single iteration that would have mixed unverifiable runtime claims with proven logic.

## What Didn't Go Well

- **Scaffold-before-populate ordering.** `scaffold-iteration-artifacts` ran before the iteration `plan.md`
  carried its Required Quality Gates + Phase 2 hardening references, so the `quality/` artifacts weren't
  produced on the first pass. Fixed by populating `plan.md` then re-running the scaffold — but the ordering
  cost a round-trip.
- **Install-method (copy vs. symlink) was a design decision discovered at implement time, not plan time
  (drift D-001).** The contracts/data-model initially specified *copy*; a copied wrapper resolves its module
  root to `$HOME` (the symlink-resolution loop has nothing to follow), which would have broken FR-003. Caught
  during implementation and corrected, but it should have been a plan-time decision because the wrapper's
  self-location *depends* on being a symlink.
- **`.pending` atomic-write staging files were briefly staged** (a `git add` over a scaffold-touched dir),
  then removed and gitignored. Minor, but a reminder to read `git status` before bulk-staging scaffold output.
- **Edit-before-Read friction.** Several edits failed "File has not been read yet" because the file had been
  inspected via `Get-Content` rather than the Read tool, which is what the edit gate tracks.

## Improvement Actions

1. Owner: Planner | Phase: next planning | Type: process | Expected effect: populate the iteration `plan.md`
   (Required Quality Gates + Phase 2 hardening refs) **before** running `scaffold-iteration-artifacts`, so
   quality artifacts generate on the first pass.
2. Owner: Planner/Spec Steward | Phase: next iteration design | Type: implementation | Expected effect: when a
   wrapper self-locates via symlink resolution, treat the install method (symlink vs. copy) as a **plan-time,
   contract-level** decision — capture it in data-model/contracts at plan, not implement.
3. Owner: Reviewer | Phase: next review | Type: process | Expected effect: keep bidirectional parity
   (registry↔wrapper↔FileList↔disk) as a standing review check for any command-surface change (it already
   caught the blind-spot class; make it a habit, not a one-off).

## Calibration Suggestion

- Suggested capacity adjustment: 20 → 20 (no change).
- Rationale: 19/20 consumed with 0 SP average variance and unused 1 SP rework headroom — the 20 SP cap fit this
  iteration well. The split (rather than a cap raise) is what kept it in-bounds, consistent with the
  "20 SP cap is intentional; split don't raise" project stance.

## Signals for Next Iteration (Iteration 2 — the deferred runtime proof)

These are the **accepted Iteration 2 obligations** carried by the APPROVE WITH DEFERRED RUNTIME PROOF verdict —
not a backlog wishlist:

- **install.sh bootstrap** (FR-007 / FR-014) — `curl | sh` entrypoint with the trust wording reviewed in the
  security lens.
- **Ubuntu + macOS CI lanes** that execute the wrappers + installer *for real* (T011) + the parity-cascade
  drift-diff CI job (FR-009 / FR-011). **Do not pull these into Iteration 1.**
- **Unix runtime proof**: symlink install, live PATH membership, quoting / paths-with-spaces argument
  forwarding, the `pwsh`-missing exit-127 path, and actual wrapper execution on Ubuntu/macOS.
- **Native-first docs** (US4 / FR-012).
- **Greenfield + brownfield installed-validation release gate** (FR-015 / SC-006) — including the
  **carry-forward Spec Kit 0.9.0 installed validation** (0.9.0 support is merged to `main` but unreleased; it
  must be validated on a real install before any release).
- **Hardening-gate re-raise (deferral must not evaporate)**: Iteration 2's hardening gate MUST re-raise
  `security-surface`, `error-handling-expectations`, and `test-integrity-targets` as `Blocking: true`, closeable
  only with `runtime-evidence` / `recorded` from the Ubuntu/macOS CI runtime proof — so the Iteration-1
  `Blocking: false` deferral is forced to resolve, not silently dropped.
- **No beta/stable publish** without explicit maintainer authorization.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in
  Retrospective ceremony, then filled with iteration evidence.
- Iteration 1 is accepted **only** for the platform-agnostic core (generator, committed wrappers, installer
  decision logic, FileList/package parity, unit-tested dispatch). The Unix runtime proof is owed by Iteration 2.
