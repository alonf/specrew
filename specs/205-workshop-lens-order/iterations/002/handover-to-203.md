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

## H-018 — the verdict capture moves plan.md to executing but leaves state.md without the fields the validator then requires

**Severity**: low. The push of a boundary commit fails the local check on a file the boundary did not touch.

**Failure scenario**: the iteration scaffold writes `state.md` without `**Current Phase**` and `**Iteration Status**`.
While the plan says planning, the validator accepts it. The before-implement verdict capture moves the iteration
`plan.md` Status to executing; from then on `validate-governance.ps1 -ChangedOnly` fails: "state.md is missing
canonical field 'Current Phase'" and "... 'Iteration Status'".

**Observed**: 2026-11-13, feature 205, iteration 002, local check before pushing the before-implement boundary commit
`22337b64` (CI had passed the same state.md on `f23f8941`). Recorded in 205's iteration 002 drift log as DRIFT-006.

**Proposed class closure (for 203 to decide)**: have the scaffold write the two fields from the start, or have the
verdict capture set them when it moves plan.md, so the file the validator requires is written by the step that makes
it required.

**Status**: open; owner feature 203.

## H-019 — the hook-output journal writes concurrent appends twice on macOS (higher severity)

**Severity**: higher, as feature 206 rated HO-206-10. This is not a timing assertion. The journal's retry wrote a line
that had already landed, so a hook output record can appear twice. The health record also went degraded under a load
the test expects it to absorb.

**Failure scenario**: `tests/unit/journal-fault-injection.tests.ps1` case (e) part 1 runs 4 writers with 1,000 appends
each against the hook-output journal. On macOS the journal held 4,002 lines for 4,000 appends ("FAIL: [macos] (e) the
journal holds exactly one line per append (4002/4000)"), and "FAIL: [macos] (e) no degraded health transition" (health
records: degraded, then recovered three times).

**Observed**: 2026-11-13, feature 205, Cross-Platform Validation run 43478045076 on `0b3fc589`, job 132066984294
(macos-latest), attempt 1. Attempt 2 (job 132081743155) passed, after one rerun the reviewer ruled under the
maintainer's delegation. Windows and Ubuntu were green on attempt 1. 205 changed nothing in the dispatcher or the test.
Recorded in 205's iteration 002 drift log as DRIFT-009.

**Second failure of the same case on macOS in two days, with a different symptom**: feature 206's HO-206-10 (run
43315180135 on `103a5e3b`, job 131521200957) saw case (e) part 2 fail: dispatcher pairs 2 to 5 exited non-zero and 8 of
10 stop reasons were missing from the journal, while part 1 passed. Here part 1 failed instead: lines written twice.
Lost records there, duplicated records here, both under concurrent appends on macOS.

**Proposed class closure (for 203 to decide)**: make the journal append idempotent across a retry, for example by
checking whether the record's id already landed before retrying, or by appending under an exclusive lock that the
retry also holds. Have the test print each writer's retries and the duplicated lines, so the next failure shows which
append was repeated.

**Status**: open; owner feature 203.

## H-020 — second sighting of B5F-067: the Windows review-runtime step hangs to the job limit with no log

**Severity**: as feature 203 rated B5F-067. This is not a new item. A hang leaves no log, so the hung suite cannot be
named, and the job's limit is the only stop.

**Failure scenario**: Cross-Platform Validation, job "Deterministic fake-provider review runtime (windows-latest)",
step "Run bounded deterministic review fault and conformance suites". The step runs its suites in one process under
the job's 25-minute limit. When one suite hangs, the job is cancelled and GitHub keeps no log.

**Observed**: 2026-11-13, feature 205, run 43494561579 on `70c8cea9` (a commit that changed only `spec.md` and the
drift log), attempt 1, job 132124152471: the step started at 21:44 local and the job was cancelled at 22:11 local. The
log request returns "BlobNotFound". The same job took 5 to 6 minutes on the branch's seven earlier runs. Attempt 2
(job 132456949975, 2026-11-14) passed in 5 min 22 s, after one rerun the reviewer ruled under the maintainer's
delegation. Recorded in 205's iteration 002 drift log as DRIFT-012.

**First sighting**: feature 203's B5F-067, run 43270394765 on 203's branch, 2026-11-12.

**Proposed class closure**: B5F-067's own proposal: run each suite under its own limit and print its name as it starts,
so a hang names its suite and ends before the job limit.

**Status**: open; owner feature 203 (B5F-067).
