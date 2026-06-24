# Validator Lag Note — Feature 197 Grandfathered Iterations

**Date**: 2026-06-24
**Scope**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (`-FullRun`, per-iteration)
**Ruling applied**: 2026-06-24 maintainer ruling — **anti-fabrication outranks green-baseline**.
"No NEW uncharacterized red" does not mean "fabricate-to-green." Governance artifacts that were never
recorded (review verdicts, Task Verdicts, Gap Ledgers, retros) must NOT be authored after the fact; doing
so would fabricate governance that never happened.

## Per-iteration validator status (this feature)

| Iteration | Status | Validator result | Disposition |
| --------- | ------ | ---------------- | ----------- |
| 001 | complete | PASS (exit 0) | Unchanged; pre-existing. |
| 002 | abandoned | PASS (exit 0) | Terminal status set to `abandoned` (honest: closed without completing the review). NOT grandfathered. |
| 003 | complete | FAIL | Grandfathered (see below). |
| 004 | complete | FAIL | Grandfathered (see below). |
| 005 | complete | PASS (exit 0) | Completed honestly from real recorded data (Effort Model + Overall Verdict + Gap Ledger). |
| 006 | planning | PASS (exit 0) | In planning; no review/retro ceremony due yet. |

002 is recorded as `abandoned` rather than grandfathered: it genuinely reached the implement -> review
boundary with implementation complete but the review was never finished (no review-signoff verdict, no
Task Verdicts, no retro, no closeout — see `iterations/002/state.md`). `abandoned` is the factual
terminal status, and under it the validator no longer demands the never-produced review/retro artifacts,
so 002 PASSES without authoring anything that did not happen.

## Grandfathered iterations — exact failing checks and why accepted

These iterations remain validator-FAIL. The failing checks were ADDED to the validator AFTER these
iterations closed, and the artifacts they now demand (completed review verdicts, Task Verdicts tables,
retrospectives) were NEVER recorded for these iterations. Authoring that content now would FABRICATE
governance that never happened, which the 2026-06-24 ruling forbids. They are therefore left failing and
documented here.

### Iteration 003 (`specs/197-continuous-co-review/iterations/003`)

Validator FAIL — failing checks (`validate-governance.ps1 -IterationPath ... -FullRun`):

- `review.md must contain a populated Task Verdicts table` — no per-task review verdicts were ever
  recorded for 003 (its `review.md` carries a recommended Overall Verdict line but no Task Verdicts
  table).
- `retro.md is missing required section: Estimation Accuracy`
- `retro.md is missing required section: Drift Summary`
- `retro.md is missing required section: Improvement Actions`
- `retro.md must capture process notes via 'Process Notes' or both 'What Went Well' and 'What Didn't Go
  Well'` — no retrospective was ever conducted for 003.

Mechanical fixes already applied to 003 (Schema / Baseline Ref / Story column) are kept. No review-verdict
or retro CONTENT was authored.

### Iteration 004 (`specs/197-continuous-co-review/iterations/004`)

Validator FAIL — failing checks:

- `plan.md Effort Model section is missing required setting 'Time Limit (hours)'`
- `plan.md Effort Model section is missing required setting 'Defer Strategy'`
- `review.md must record a valid overall verdict (accepted | needs-rework | blocked)`
- `review.md must contain a populated Task Verdicts table`
- `retro.md is missing required section: Estimation Accuracy`
- `retro.md is missing required section: Drift Summary`
- `retro.md is missing required section: Improvement Actions`
- `retro.md must capture process notes via 'Process Notes' or both 'What Went Well' and 'What Didn't Go
  Well'`

The two Effort Model rows COULD be added mechanically (they are config-shape fields, not fabricated
governance) — but the review verdict, Task Verdicts, and retro sections were never recorded and are NOT
authored. 004 is left failing as a grandfathered iteration; its Effort Model rows are left untouched so
the iteration is documented here as a single grandfathered unit rather than partially patched.

## Systemic root cause (the real fix is a validator slice, not these notes)

The validator already grandfathers SOME checks for closed/past-implementation iterations:

- `Test-PlanEffortModel` grandfathers `Capacity per Iteration` (and the Capacity-line total) against the
  plan's OWN stated value for non-in-flight iterations.
- `Test-IterationCloseoutEvidence` is gated by `Test-IterationRequiresCanonicalStateSchema` and does not
  fire for these pre-schema iterations.

But the specific checks that re-fail these closed iterations have **no schema-version / baseline
grandfathering** and are enforced unconditionally whenever a `review.md` / `retro.md` exists or the status
routes through the `reviewing` / `retro` / `complete` switch branch:

- `review.md` Overall Verdict, populated Task Verdicts table, and Gap Ledger section
  (`Test-ReviewArtifact`).
- `retro.md` Estimation Accuracy, Drift Summary, Improvement Actions, and a process-notes section
  (`Test-RetroArtifact`).
- `plan.md` Effort Model `Time Limit (hours)` and `Defer Strategy` settings (`Test-PlanEffortModel`).

Because these checks carry no schema-version baseline, the validator re-fails already-closed iterations
every time the check set is tightened. The durable fix is a validator-grandfathering slice (a
schema-version / closed-before baseline that exempts iterations closed before a check was introduced,
mirroring the capacity-grandfathering and canonical-state-schema cutoff that already exist). This note is
the interim record until that slice lands.
