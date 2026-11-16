# Drift Log: Iteration 002

**Schema**: v2

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 4 (DRIFT-001 to DRIFT-004)
**Resolution rate**: 4 of 4 handled locally; each entry's Class closure line states its product class
**Specification drift**: None detected

## Events

### DRIFT-001 — Two maintainer decisions made before this folder existed (maintainer's decisions; pointer)

- **Where they are recorded**: in `docs/beta5-findings.md`, in the note dated 2026-11-16, pushed as `2cacad73` at 03:19
  local. This folder could not be pushed before its plan exists (B5F-083), and the reviewer session ruled that the
  decisions should not wait in a scratch note.
- **"203, here: \"launcher: wait\""** (03:13 local on 2026-11-16, relayed by the reviewer session). The project's Claude
  hook launcher is not redeployed until 203 merges or the maintainer decides otherwise. Still owed: T006's launcher
  half, the plain-text refusals (iteration 001's DRIFT-046). Its placement is in this iteration's design analysis.
- **"rerun: add HookRenderDedupe"** (02:56 local on 2026-11-16, relayed). For 203, which owns the test: one rerun only on
  a push of records only, with the sighting recorded; no exception on a push that changes code. The suite's timing
  cases are on this iteration's first-batch list.
- **Class closure**: NONE — process decisions; no code changed.

### DRIFT-002 — The before-plan resolve misread the stack again (finding, B5F-085)

- **What happened**: `resolve-quality-profile.ps1 -ProjectPath .` (2026-11-16, about 03:15 local) returned exit 0 and
  `quality-profile.custom-composition.v1`, built from `node-rest-with-postgres` (90) and `react-spa-public` (80), with
  surfaces api-runtime (Node.js) and browser-ui. It wrote no file. This repository is PowerShell scripts. It is the same
  misread as iteration 001's DRIFT-001; the maintainer said at the plan verdict of 2026-10-31 that it "will misread the
  next feature too".
- **Handling**: corrected by hand in this iteration's plan, as in iteration 001.
- **Class closure**: NONE — B5F-085, a candidate for feature 206's list.

### DRIFT-003 — The iteration scaffold's own defects, met while opening this iteration (findings, B5F-081 to B5F-084)

- **The scaffold** (`scaffold-iteration-artifacts.ps1 -SpecDirectory specs/203-beta5-stabilization -IterationNumber
  002`, run after a dry run and a trial on a scratch clone) wrote this folder's `state.md`, `drift-log.md` and `quality/`
  files, and also `specs/203-beta5-stabilization/contracts/mechanical-findings.schema.json` at feature level. That file is
  the scaffold's own shipped schema and is kept as shipped (the reviewer session's ruling; B5F-084).
- **On the scratch trial**: the fresh folder failed the governance lane on its own `hardening-gate.md` ("overall verdict
  should be 'ready' based on the concern rows but found 'blocked'", B5F-081); the template has 3 x MD038 in its own text
  (B5F-082); and the folder cannot be pushed without `plan.md` (B5F-083). So this folder is committed with the design
  analysis and pushed with `plan.md` at the plan boundary, as feature 205 did, and the hardening rows are filled by the
  planning that decides them.
- **Class closure**: NONE — B5F-081, B5F-082 and B5F-084 are candidates for feature 206's list; B5F-083 is placed with
  B5F-050 and B5F-059 in this iteration's design analysis.

<!--
  Every new ### DRIFT-... event includes:

  - **Class closure**: the executable mechanism that makes the next instance impossible or loud

  If the change fixes only this instance, write NONE — <why class closure is not in scope>.
  A bare Resolution: FIXED is not class closure.
-->

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

### DRIFT-004 — Site 13 failed alone on a docs-only push (CI sighting; evidence for the first-batch fix)

- **The run**: Specrew CI `43785562285` on `2cacad73` (one Markdown file, `docs/beta5-findings.md`), attempt 1. The
  Deterministic gate failed at 01:26:41Z (03:26 local, 2026-11-16) in the F-198 honesty regression suite, "1 of 132
  FAILED", and the Contract lane was skipped. Test and Cross-Platform Validation were green.
- **The case**: `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`, "a FAILED lease owner-handoff STOPS
  the spawned supervisor ...": "Expected $null or empty, because a supervisor whose lease handoff failed must not keep
  running unprotected, but got System.Diagnostics.Process (pwsh)." This is B5F-051's site 13 (`Stop-Process -Force` with
  no wait in `co-review-service.ps1:216`). It passed on `7daceb7d` an hour earlier.
- **Handling**: 203's own pushes have no rerun exception for it, so the crew asked. One rerun on the reviewer session's
  routine ruling, for this push only: attempt 2 green, every job run (Lint, the firewall, the Deterministic gate and the
  Contract lane). The reviewer session will ask the maintainer whether 203's records-only rule should cover site 13 and
  `empty-result-retry` as it covers HookRenderDedupe.
- **Class closure**: NONE — site 13's fix is proposed for this iteration's first batch (design-analysis.md).

### DRIFT-005 — A Windows hang in the deterministic suites step on feature 206's push (evidence; handed over)

- **The run**: on 206's push `fdb42f2d` (release script, publish workflow, publish test; nothing 203's suites read),
  Cross-Platform Validation `43793714104`, attempt 1, the Windows job "Deterministic fake-provider review runtime"
  (job `133057670105`) hung in the step "Run bounded deterministic review fault and conformance suites". It started at
  02:44:26Z (04:44 local, 2026-11-16), never completed, and was cancelled at 30 minutes against the job's
  `timeout-minutes: 25`. No log was kept (BlobNotFound). The same step took 133 s on `53bc6574` and 130 s on attempt 2
  (job `133068036828`, all 8 jobs green). Feature 206 records it as DRIFT-206-I002-012 at `eac9e210`; the reviewer
  session handed it over.
- **A possibility, not a finding**: a review process that does not exit on Windows, site 13's family (`Stop-Process`
  with no wait).
- **What the step has** (`.github/workflows/cross-platform-validation.yml:243`, `:299-364`): no per-suite time limit.
  On Windows it runs 14 suites one after another in the step's own `pwsh` through `Invoke-Pester -Output Detailed`,
  with no step-level `timeout-minutes`; only the job's 25 minutes bound it. It prints `--- deterministic suite: <path>`
  before each suite, so the live log would have named the suite and the last test; the job-level cancel lost that log.
  The cancel came five minutes after the job's limit.
- **Class closure**: NONE — the plan's flaky-test task takes a per-suite time limit that names the suite and stops its
  process tree, and a step-level `timeout-minutes` below the job's so a hang fails the step and keeps its log.

### DRIFT-006 — The maintainer's nine design decisions and "203 rerun: yes", relayed

- **The words**: "OK for all", typed by the maintainer to the reviewer session specrewreviewer-98 at 11:34 local on
  2026-11-16 and relayed under the wider delegation, answering two lines quoted in design-analysis.md's Human Decision.
- **What they decide**: Option A, A-buffered, merge then a follow-up feature, the first-batch order as recommended, the
  pin advance placed after the first batch's round (the advance itself still needs their typed `advance the pin`),
  B5F-077's link removed, the t008 lane measured first, T006's launcher half with F3's push (refining "launcher: wait"
  of 03:13), the rest of the census later. The merge shape is recorded in `.squad\decisions.md` as
  `f203-i002-merge-then-follow-up`.
- **"203 rerun: yes"**: on 203's records-only pushes, a sole failure of site 13 (`co-review-service.Tests.ps1:129`) or
  `empty-result-retry.Tests.ps1` is rerun once without asking and the sighting recorded; a second failure stops; no
  exception on a push that touches code. HookRenderDedupe stays as ruled at 02:56.
- **Not an approval**: no boundary is crossed by it; the plan boundary takes the maintainer's own typed verdict.
- **Class closure**: NONE — a record of a decision, not a defect.
