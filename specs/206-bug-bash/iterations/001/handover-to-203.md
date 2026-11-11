# Hand-over to feature 203: findings 206 does not fix

**From**: feature 206 (bug bash), iteration 001 | **Opened**: 2026-11-11 by T004 | **Status**: open (T018 closes
it, after adding anything T014 or the other tasks find that belongs to 203)

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
- **Iteration 198/010**: open (`state.md` `reviewing`, phase `review-signoff`; `plan.md` `planning`); no
  `review.md`. It sits in T005's table awaiting the maintainer's ruling; 206 marks it nothing.
- **Proposed owner**: feature 203, whatever the maintainer rules for the iteration: the defect is in 203's
  protected file.

## HO-206-5 — two suites run `specrew-update.ps1` with no home redirect and rewrite the real home's hook files

- **Bug list**: item 8.
- **Evidence**: `tests/integration/deployed-extension-marker-on-update.tests.ps1:64` and
  `tests/integration/receipt-outcomes-retired.tests.ps1:28` run `scripts/specrew-update.ps1 -ProjectPath <temp>`
  and set neither `HOME` nor `USERPROFILE` (read 2026-11-11). Both are named in `.specrew/verification-plan.json`'s
  lanes; neither is in a CI workflow. 11 more test scripts mention `specrew-update.ps1` (listed under item 8; a
  mention is not proof of a call). T014 reads them and adds what it finds here.
- **Cross-references**: feature 205's H-001 (`specs/205-workshop-lens-order/iterations/001/handover-to-203.md` on
  `205-workshop-lens-order`: the review preflight rewrote four real-home hook files in run
  `run-20261110-221211306-a1cb90e2`); feature 203's B5F-039 (`docs/beta5-findings.md` on `203-beta5-stabilization`,
  open, owner feature 203), with B5F-042 (the preflight does not redirect the home for the suites it runs).
- **Not run on this machine** (maintainer's instruction). No fix in 206 unless the maintainer rules one.
- **Proposed owner**: feature 203, under B5F-039.
