# Hand-over to feature 203: findings from 205 iteration 002

**From**: feature 205 (workshop lens order), iteration 002 | **Written**: 2026-11-13

Feature 205 does not edit files under `scripts/internal/continuous-co-review/` or the review engine. Iteration 001's
hand-overs H-001 to H-014 are in `specs/205-workshop-lens-order/iterations/001/handover-to-203.md` (sealed); numbering
continues here.

## H-015 — after a closed iteration, the clarify sync opens no approval point

**Severity**: medium. A spec amendment for a later iteration reaches planning with no approval of its own.

**Failure scenario**: with the last iteration closed (last authorized boundary `iteration-closeout`), a spec amendment
is written for the next iteration and the clarify sync is run. It exits 0 and writes its boundary records, but opens
no crossing (`pending_verdict_has_pending: false`), and `start-context.json` still names `iteration-closeout`. Nothing
asks the human to approve the amendment before planning.

**Observed**: 2026-11-13, feature 205 Amendment A1, sync bound to `881bc45b`. The maintainer ruled that A1 is approved
at the plan boundary. Recorded as DRIFT-205-INTAKE-005 and iteration 002's DRIFT-003.

**Proposed class closure (for 203 to decide)**: a clarify after a closed iteration opens a crossing like any other
boundary, or the plan crossing names the amendment it carries and refuses to proceed without it.

**Status**: open; owner feature 203.

## H-016 — the reviewer's prompt calls the workshop records binding, but is not given them

**Severity**: medium. The reviewer is told to validate against records it never receives.

**Failure scenario**: `scripts/internal/continuous-co-review/worktree-reviewer.ps1:1139` says "the workshop records +
design-analysis are BINDING" and asks the reviewer to validate against each design lens. The files the reviewer is
given come from `scripts/internal/continuous-co-review/review-design-context.ps1:104-133`: spec.md, the latest
design-analysis.md, the latest plan.md and `contracts/`. The feature's `workshop/` folder is not among them, so a lens
answer reaches the reviewer only if a writer copied it into those files.

**Observed**: 2026-11-13, found by 205's iteration 002 research and confirmed by the reviewer session. Records only:
feature 205 does not touch those files.

**Proposed class closure (for 203 to decide)**: give the reviewer the feature's `workshop/` records, or narrow the
prompt to the files it is given. Proposal 177 is the general fix.

**Status**: open; owner feature 203.

## H-017 — an INCONCLUSIVE fixture result fails the Deterministic gate

**Severity**: low to medium. A gate goes red on a commit that cannot have caused it, and the result says nothing about
the code.

**Failure scenario**: `tests/unit/pretag-slice3-certify-findings.tests.ps1` case f3 runs the stop hook's capped
evidence-absent path. Once in CI it "emitted nothing at all — the cap path was never reached", and the test reported
`INCONCLUSIVE (fixture defect, NOT a pass)` with exit 2. The F-198 suite counts exit 2 as a failure, so the Deterministic
gate failed and the Contract lane was skipped.

**Observed**: 2026-11-13, feature 205, Specrew CI run 43420704956 on `7d3b55b9` (a commit that changed only iteration
002's `design-analysis.md`), Deterministic gate job 131871436437 attempt 1; attempt 2 passed. Recorded in 205's
iteration 002 drift log as DRIFT-005.

**Proposed class closure (for 203 to decide)**: make the fixture deterministic about reaching the cap path (for example
wait for the hook's journal entry before reading its output), or have the suite report INCONCLUSIVE separately from a
failure so a fixture defect does not read as a regression.

**Status**: open; owner feature 203.
