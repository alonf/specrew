# Hand-over to feature 203: findings 206 does not fix

**From**: feature 206 (bug bash), iteration 001 | **Opened**: 2026-11-11 by T004 | **Status**: closed 2026-11-13 by T018,
with ten items (HO-206-1 to HO-206-10)

Feature 206 does not edit `scripts/internal/continuous-co-review/` or the capture stores under
`scripts/internal/bootstrap/` (maintainer rule: feature 203 is rewriting them). Each section below is one item,
with its own evidence and a proposed owner. The maintainer decides the owner; 206 only proposes. Trace: FR-004,
FR-005.

## HO-206-1 — `empty-result-retry.Tests.ps1` fails intermittently: output the fake agent wrote is read as empty

- **Bug list**: item 3 (`specs/206-bug-bash/bug-list.md`).
- **Evidence**:
  - Run 42715079692, attempt 1, ubuntu-latest, commit `700e6127`: case "retries once and recovers" failed with
    `Expected '"run_id":"t108"' to match <empty>` (the retry's stdout was empty); passed on rerun.
  - Run 42743719583, attempt 1, ubuntu-latest, commit `cf01f599` (feature 205, records-only): case "does NOT
    retry a non-empty result" failed at line 87, `Expected 1 ... but got 2` (the first attempt's output read as
    empty); `03bc4c5b` passed about 40 minutes earlier.
- **Cause: not found.** Not reproduced: 200 of 200 passes on Linux (WSL Ubuntu 24.04, 2 cores, idle and under CPU
  load), and 300 standalone replays of the capture pattern on Windows lost no output.
- **One candidate, unproven**: `Invoke-ContinuousCoReviewAgentInWorktree`
  (`scripts/internal/continuous-co-review/worktree-reviewer.ps1:1598`) keeps stdout only if the `ReadToEndAsync`
  task already shows `RanToCompletion` when `WaitForExit(slice)` returns; that wait does not wait for the reader to
  reach end-of-stream. Both sightings fit it.
- **Recurrence log**: the table under item 3 in the bug list; any new sighting is added there with its run id.
- **Proposed owner**: feature 203 (the file is in its protected area).

## HO-206-2 — the Windows review-runtime job hung past its limit and left no log

- **Bug list**: item 7.
- **Evidence**: Cross-Platform Validation run 42913380735 on `435332da`, job "Deterministic fake-provider review
  runtime (windows-latest)", step "Run bounded deterministic review fault and conformance suites". Started
  2026-11-10T22:18:51Z, cancelled 22:48:51Z (30 minutes, against 5 minutes on `7f9cf310`, run 42740875424). The
  job limit is `timeout-minutes: 25`; the step has none. GitHub returned `BlobNotFound` for the log, so where it
  stopped is unknown. `435332da` changed only Markdown and `.specrew/iteration-config.yml`.
- **Cause: not found.** The step runs `tests/continuous-co-review/**`, 203's area.
- **Proposed owner**: feature 203 for the hang itself. Feature 206's iteration 002 (T019) proposes the step's own
  `timeout-minutes`, shorter than the job's, so a hang fails with its log kept; the workflow file is not in 203's
  protected paths.

## HO-206-3 — FR-066's mint guard, with T091 and T093: one finding

- **Bug list**: item 4 ("What the needs-rework review asked for").
- **Evidence**: `specs/198-beta2-hardening/iterations/011/review.md` (verdict `needs-rework`) asked for:
  - T092's certification of FR-066/FR-068/FR-018, closure trigger "iteration 011 closes when beta3 delivers
    FR-066's mint guard from its design spike";
  - T091 (FR-068, SC-025 composition clause), decision `f198-i011-t091-defer-sc025-beta3-vehicle`;
  - T093 (FR-018 campaign-mode halt text), decision `f198-i011-t093-defer-relief-valve-back-registration`.

  No evidence that any of the three was delivered. FR-066 entered beta3 only as a carry-ledger line
  (`beta3-carry-ledger.md` at `b9c5bacb`, section F); features 201 to 205 do not mention it; T091 and T093 have no
  trace in 199, 201 or 202.
- **Its test**: `tools/pending/fr066-first-boundary-arrival.pending.ps1`, RED by design. **Not run** by 206: it
  exercises the boundary machinery.
- **Ruling (maintainer, 2026-11-10)**: 198/011 is marked abandoned (T007), review unchanged; FR-066's mint guard,
  T091 and T093 become one finding owned by feature 203's follow-up.
- **Proposed owner**: feature 203's follow-up (per the ruling).

## HO-206-4 — DRIFT-198-I010-004: authority-store containment covers resolution, not enumeration

- **Evidence**: `specs/198-beta2-hardening/iterations/010/drift-log.md`, DRIFT-198-I010-004, open and blocking:
  "T082's containment covers path RESOLUTION, not ENUMERATION; -041 is NOT delivered". A security defect on the
  read path at four enumeration sites in `scripts/internal/continuous-co-review/review-authority-store.ps1` (lines
  200, 309, 362, 447 when recorded). T082 (DRIFT-198-I009-041, reparse-point containment, FR-008, 5.0 SP) was
  corrected from `done` to `needs-rework` on 2026-08-01.
- **Iteration 198/010**: ruled abandoned and superseded (maintainer, 2026-11-11, T005 stop), applied in T007.
  Its `state.md` says that DRIFT-198-I010-004 stays open and was handed to 203 here; T082 stays `needs-rework`.
- **Proposed owner**: feature 203, whatever the maintainer rules for the iteration: the defect is in 203's
  protected file.

## HO-206-5 — three suites run `specrew-update.ps1` with no home redirect and rewrite the real home's hook files

- **Bug list**: item 8.
- **Evidence**: `tests/integration/deployed-extension-marker-on-update.tests.ps1:64` and
  `tests/integration/receipt-outcomes-retired.tests.ps1:28` run `scripts/specrew-update.ps1 -ProjectPath <temp>`
  and set neither `HOME` nor `USERPROFILE` (read 2026-11-11). Both are named in `.specrew/verification-plan.json`'s
  lanes; neither is in a CI workflow. `tests/integration/distribution-module-update.ps1:213-216` does the same
  through `Invoke-ModuleScript` (added by the maintainer 2026-11-11). 10 more test scripts mention
  `specrew-update.ps1` (listed under item 8; a mention is not proof of a call). T014 reads them and adds what it
  finds here. Feature 203's census (2026-11-11) found 16 test files that can write the home hook files; they are listed under bug list item 8 and none is run from 206's worktree.
- **Cross-references**: feature 205's H-001 (`specs/205-workshop-lens-order/iterations/001/handover-to-203.md` on
  `205-workshop-lens-order`: the review preflight rewrote four real-home hook files in run
  `run-20261110-221211306-a1cb90e2`); feature 203's B5F-039 (`docs/beta5-findings.md` on `203-beta5-stabilization`,
  open, owner feature 203), with B5F-042 (the preflight does not redirect the home for the suites it runs).
- **Not run on this machine** (maintainer's instruction). No fix in 206 unless the maintainer rules one.
- **Proposed owner**: feature 203, under B5F-039.

## HO-206-6 — the macOS review-runtime job failed a fault-matrix case: process-group membership probe

- **Bug list**: item 9.
- **Evidence**: Cross-Platform Validation run 42994018357 on `a9ad8aa0`, job 130433482347 "Deterministic
  fake-provider review runtime (macos-latest)". `review-cross-platform-fault-matrix.Tests.ps1`, case "rejects
  prose-wrapped output from the codex fake process through strict ingress with no hidden retry":
  `macos-process-group-unavailable:macos-process-group-probe-membership-failed` (thrown at
  `review-macos-runtime-port.ps1:116`); 12 of 13 passed. Passed on `b31ec257` (run 42990069953) 30 minutes
  earlier; the push changed nothing the suite loads.
- **Cause: not found.** Not rerun (maintainer). A recurrence on 206's next push stops 206's work and is reported.
- **Proposed owner**: feature 203 (its area).

## HO-206-7 — 198/009 is in the closed index while its state file says it is in review

- **Evidence**: `.specrew/closed-iterations.yml` lists `198-beta2-hardening/009` (entry from the 2026-08-06
  rebuild), while `specs/198-beta2-hardening/iterations/009/state.md` says `Current Phase: review-signoff`,
  `Iteration Status: reviewing`. Found by T005's table (group E,
  `specs/206-bug-bash/iterations/001/closed-open-table.md`).
- **Ruling (maintainer, 2026-11-11)**: change neither; keep it in this hand-over. Under the new definition it is
  closed by the index, as the validator already treats it; the dashboard check does not judge it (status is not
  `complete`).
- **Proposed owner**: the maintainer decides; 206 changes nothing.

## HO-206-8 — `co-review-service.Tests.ps1`: a supervisor kept running after a failed lease handoff (Deterministic gate)

- **Bug list**: item 13.
- **Evidence**: Specrew CI run 43116326615 on `03bc7a48`, job 130846956739 "Deterministic gate", 1 of 131 failed:
  `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`, "a FAILED lease owner-handoff STOPS the
  spawned supervisor, marks the registry failed, and releases the lease" - the `pwsh` supervisor process was
  still alive when the test checked.
- **Not caused by 206**: `03bc7a48` is a Markdown-only commit; its parent `ad31b2d5`, with the same code, was
  green on all three workflows. 206 does not edit `scripts/internal/continuous-co-review/`.
- **Cause: not found.** Not rerun (maintainer, 2026-11-12). A recurrence on 206's next push stops 206's work and
  is reported.
- **Proposed owner**: feature 203 (its area).
- **Second sighting (2026-11-13), higher priority:** Specrew CI run 43411715314 on `75ddb2b9`, job 131841569510, the same
  case at `:129`, on a push that touched only 206's review plan files, a CI step, the lane guard and records. It
  stopped every step after it in the Deterministic gate, so a registered per-push step (206's T015 step, including
  T002's suite) did not run, and the Contract lane was skipped. Raised to a higher priority for feature 203, like
  HO-206-10. The failed job is rerun once (reviewer ruling under the maintainer's delegation); no workaround in 206.
- **Third sighting (2026-11-13):** Specrew CI run 43423416387 attempt 1 on `7f346037`, job 131879951424, the same case
  and error, the only failure. Rerun once under the maintainer's standing exception for this test (14:28 local,
  2026-11-13): attempt 2 green (job 131885538324).
- **Fourth sighting (2026-11-13):** Specrew CI run 43500243627 attempt 1 on `c91766df`, job 132146041562, the same case
  and error, the only failure. Rerun once under the same exception: attempt 2 green (Deterministic gate job
  132151298400). Four sightings in two days, on pushes that never touched `scripts/internal/continuous-co-review/`.

## HO-206-9 — `review-posix-runtime.Tests.ps1`: stream-drain budget exceeded on macOS

- **Bug list**: item 14.
- **Evidence**: Cross-Platform Validation run 43116326613 on `03bc7a48`, job 130845171704 "Deterministic
  fake-provider review runtime (macos-latest)": `tests/continuous-co-review/unit/review-posix-runtime.Tests.ps1:126`,
  "observes both stream drains concurrently under one bounded wall-clock budget", 360 ms against a 250 ms limit.
  Different from HO-206-6 (the process-group probe).
- **Not caused by 206**: same evidence as HO-206-8; the same job was green on `ad31b2d5` (run 43113590661).
- **Cause: not found.** Not rerun (maintainer, 2026-11-12). A recurrence on 206's next push stops 206's work and
  is reported.
- **Proposed owner**: feature 203 (its area).

## HO-206-10 — `journal-fault-injection.tests.ps1`: concurrent Stop dispatchers exit non-zero on macOS (higher severity)

- **Bug list**: item 27.
- **Evidence**: Cross-Platform Validation run 43315180135 on `103a5e3b`, job 131521200957 "Deterministic fake-provider
  review runtime (macos-latest)", step "Hook-output journal concurrent append (case e) and outage buffer". Case (e)
  part 2: dispatcher pair 1 exits 0; pairs 2 to 5 each exit non-zero; 8 of 10 stop reasons are missing from the
  journal. Part 1 (4 writers, 4,000 appends) passed.
- **Severity: higher than HO-206-8 and HO-206-9.** This is not a timing assertion: real dispatcher processes failed
  under concurrent Stop, and their stop reasons were not journaled.
- **What the log shows about why: nothing.** The test discards each dispatcher's stdout and stderr and prints no exit
  code (`tests/unit/journal-fault-injection.tests.ps1`, part 2). A first step for the owner is to print them.
- **Not caused by 206**: the same job was green on `d258e060` (run 43274075221); 206 never changed the dispatcher or
  the test.
- **Not rerun** (reviewer ruling 2026-11-12, under the maintainer's delegation). A recurrence on 206's next push stops
  206's work and is reported.
- **Proposed owner**: feature 203.

## Closing (T018, 2026-11-13)

- **Ten items handed over**: HO-206-1 to HO-206-10. Each has its evidence and a proposed owner. HO-206-10 (the macOS
  journal case, bug list item 27) was added at T015 at a higher severity than the timing class.
- **Considered, not handed over**: bug list items 23 (`specrew start` writes into a feature outside its project),
  25 (`specrew init` probes Squad in the install root) and the start-only boundary authorization with no verdict.
  None is in feature 203's area. They are on `specrew-start-facts.md` for the maintainer's iteration 002 decision
  on `specrew start`. Feature 203 found the authorization item itself (its B5F-066).
- No later 206 finding belongs to 203. A recurrence of HO-206-8, -9 or -10 on 206's pushes would stop 206's work
  and be reported. None recurred on `66d70fa3`.
