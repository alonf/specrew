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

**Total drift events**: 12
**Resolution rate**: 100% (5/5 resolved for this feature; DRIFT-001 to DRIFT-003 and DRIFT-005 class closure open; DRIFT-004 is a planning decision)
**Specification drift**: None detected

## Events

### DRIFT-001 — the quality-profile resolver read the stack as Node plus a browser SPA again (observation, recurrence)

- **Observed**: 2026-11-13, before-plan for iteration 002. `resolve-quality-profile.ps1` returned
  `quality-profile.custom-composition.v1` with stack signals `node-rest-with-postgres` and `react-spa-public`, and the
  plan scaffold called the scope "frontend-oriented".
- **Real stack**: PowerShell 7 scripts, lens markdown, the spec template and tests.
- **Resolution**: the plan states the real stack; the profile's required dimensions (code quality, design quality,
  verification confidence, maintainability) still apply.
- **Class closure**: NONE — the resolver is outside 205's scope. Recurrence of iteration 001's DRIFT-001 and feature
  203's plan-verdict finding.

### DRIFT-002 — the iteration plan scaffold rejects every requirement of this spec when given a scope (finding)

- **Observed**: 2026-11-13. `scaffold-iteration-plan.ps1 -RequirementScope FR-022,FR-024` refused with
  `Requirement(s) not found in spec: FR-022,FR-024`, although both are in `spec.md`'s Functional Requirements. The same
  script with no scope listed them. The plan was scaffolded without a scope and its scope written by hand, as in
  iteration 001.
- **Class closure**: NONE — the scaffold is part of the deployed extension. Candidate for feature 203's hand-over.

### DRIFT-003 — after a closed iteration, the clarify sync opens no approval point (finding, handed over)

- **Observed**: 2026-11-13. Recorded first as DRIFT-205-INTAKE-005 (feature-level intake drift log), before this
  iteration's folder existed. The clarify sync for Amendment A1 recorded its boundary but opened no crossing, so the
  amendment reaches planning with no approval of its own.
- **Resolution**: the maintainer approves A1 at this iteration's plan boundary.
- **Class closure**: NONE — the sync is feature 203's area. Handed over as H-015.

### DRIFT-004 — the review-signoff crossing is not planned capacity in this iteration (maintainer's decision)

- **Decided**: 2026-11-13, 13:19 local, by the maintainer, relayed by the reviewer session under the wider delegation
  with the question and the time. The question: the recorded Light workshop run is the only proof that the new
  workshop behaviour works, and its 2 SP were spent on the review-signoff crossing line, which does no work; option 1
  keeps the crossing line and moves the run to iteration 003, option 2 drops the crossing line and puts the run back.
  The maintainer's answer: "2".
- **Effect**: T026 is the recorded Light workshop run (2 SP, last, SC-012) instead of the crossing line. The plan stays
  at 20/20. The crossing's cost is not planned capacity in this iteration; the retro reports its actual cost, as
  iteration 001's did.
- **What it reverses**: the iteration 001 retro's calibration line (2 SP for the review-signoff crossing until H-003 and
  H-007 are fixed), for this iteration only.
- **Class closure**: NONE — a planning decision by the maintainer, not a defect. The underlying cost belongs to H-003
  and H-007 (feature 203); the retro reports it.

### DRIFT-005 — an INCONCLUSIVE test result failed the Deterministic gate on a records-only commit (external CI failure; handed over)

- **Observed**: 2026-11-13, Specrew CI run 43420704956 on `7d3b55b9`, Deterministic gate job (attempt 1), the F-198
  honesty regression suite: 1 of 131 files failed, `tests/unit/pretag-slice3-certify-findings.tests.ps1`, exit 2. The
  test reported itself `INCONCLUSIVE (fixture defect, NOT a pass)`, case f3: "the capped evidence-absent invocation
  emitted nothing at all — the cap path was never reached". Every other case in the file passed. The Contract lane was
  skipped.
- **Cause, as far as 205 can see**: `7d3b55b9` changed only iteration 002's `design-analysis.md`; the same suite passed
  on `2011e854` just before.
- **Resolution**: the reviewer session ruled one rerun (routine, under the maintainer's delegation). The rerun of job
  131871436437 passed (attempt 2: Lint, Self-leak firewall, Deterministic gate and Contract lane all green). The plan
  sync then ran bound to `7d3b55b9`. Recorded after the plan verdict, so no commit fell between the sync and the
  verdict.
- **Class closure**: NONE — the test and the stop-hook cap belong to feature 203. Handed over as H-017. It is a
  different test from those in H-006, and an inconclusive result that fails a gate is its own shape.

### DRIFT-006 — the scaffolded state.md lacked two canonical fields once the plan moved to executing (local check; fixed)

- **Observed**: 2026-11-13, local `validate-governance.ps1 -ProjectPath . -ChangedOnly` before pushing the
  before-implement boundary commit `22337b64`: iteration 002 `state.md` "is missing canonical field 'Current Phase'"
  and "... 'Iteration Status'". The same state.md passed CI on `f23f8941`; the verdict capture had moved the
  iteration plan's Status from planning to executing in between.
- **Cause, as far as 205 can see**: the iteration scaffold creates state.md without the two fields. The file passed
  while the plan said planning, and failed once the verdict capture moved the plan to executing. The capture moves
  plan.md but leaves state.md without the fields the validator then requires.
- **Resolution**: stopped before the push and reported. The maintainer answered "yes" to adding the two lines. The
  reviewer session then ruled the values (routine, under the maintainer's delegation): the same lines iteration 001
  carried during its build, `Current Phase: before-implement` (the last authorized boundary, not the activity) and a
  bare `Iteration Status: executing`, with the commit and next task in the Execution Summary. One records commit, the
  checks rerun, then both commits pushed.
- **Class closure**: NONE — the scaffold and the verdict capture belong to feature 203. Handed over as H-018.

### DRIFT-007 — the plan filed four problem questions under a solution lens (plan defect; placement ruled by the reviewer)

- **Observed**: 2026-11-13, at T021. The plan's twelve-question table (and spec FR-025's last line) put four questions
  under observability-resilience's `### Problem questions`. That lens is `space: solution` in index.yml by the
  maintainer's plan-verdict ruling of 2026-11-10, and has "No problem questions". lens-order-parity (FR-005c) fails a
  solution lens with problem questions and says the tag goes to the maintainer.
- **Ruling**: the reviewer session, under the maintainer's workshop delegation, 2026-11-13. Options that retag or move
  the lens were not open, since they would reverse the 2026-11-10 ruling. Each question goes where its subject lives:
  operator diagnosis to devops-operations; SLO/alerting and the domain's expected failures to requirements-nfr; what
  must never be logged to security-compliance; the observability budget is product-domain's budget fact.
  observability-resilience receives all four as hand-forward lines.
- **Resolution**: done as ruled. **FR-024's source is widened**: a hand-forward line may come from any earlier lens,
  not only product-domain, in the same line form, naming its source lens and the answer's key. The section is renamed
  `## Handed Forward From Earlier Lenses`, and the length test checks that the source runs earlier and defines the key.
  The recorded length numbers moved with the reviewer's agreement: Light 51/16/21 (was projected 51/16/18), Standard
  and Deep 66/16/6 (was 63/16/6). Light's must-answer count stays at 51. The plan's table, hand-forward text and length
  table are updated. No tag, lens order or parity rule changed.
- **Open (closed by DRIFT-010)**: spec FR-025's last line still named observability-resilience, and FR-024 still named
  only product-domain as a source. The maintainer decided to reword both; see DRIFT-010.
- **Class closure**: NONE — a planning error caught by the existing FR-005c check before anything shipped; that check
  is the mechanism that made it loud.

### DRIFT-008 — the deployed spec template copy is left without `## Problem Context` (as T024 directs)

- **Observed**: 2026-11-13, T024. The source `templates/specify/templates/spec-template.md` gains `## Problem Context`
  (the eleven consumer lines). Neither project-only deploy script (`deploy-speckit-extension.ps1`,
  `deploy-squad-runtime.ps1`) writes `.specify/templates/spec-template.md`; the init/update template deploy does, and
  `specrew update` is on the never-run list in this worktree.
- **Resolution**: the deployed copy is left as it is, per T024. The consumer test reads the source. Reported at the
  review stop: a project gets the new section on its next `specrew update`.
- **Class closure**: NONE — not a defect; the copy is refreshed by the normal update path outside this worktree.

### DRIFT-009 — macOS hook-output journal wrote two appends twice (external CI failure; handed over at higher severity)

- **Observed**: 2026-11-13, Cross-Platform Validation run 43478045076 on `0b3fc589`, attempt 1, job 132066984294
  "Deterministic fake-provider review runtime (macos-latest)", step "Hook-output journal concurrent append (case e)
  and outage buffer" (`tests/unit/journal-fault-injection.tests.ps1`): "FAIL: (e) the journal holds exactly one line
  per append (4002/4000)" and "FAIL: (e) no degraded health transition" (the health record went degraded, then
  recovered). The same job was green on Windows and Ubuntu; every other job of the run was green.
- **Cause, as far as 205 can see**: not 205's change. The push touched lens files, the workshop skill, the spec
  template, two tests and one CI step; nothing in the hook dispatcher or its journal. Two appends written twice reads
  as the journal's retry writing a line that had already landed: product behaviour in the dispatcher, not a slow test.
- **Resolution**: reported to the maintainer; one rerun ruled by the reviewer session under the maintainer's
  delegation (not covered by the standing co-review-service exception). Attempt 2 passed: macOS job 132081743155 and
  every other job green. `0b3fc589` is fully green.
- **Class closure**: NONE — the dispatcher's journal belongs to feature 203's area. Handed over as H-019 at the higher
  severity feature 206 gave HO-206-10 (the first macOS failure of the same case, with a different symptom).

### DRIFT-010 — spec FR-024 and FR-025 reworded to match the placement ruling (maintainer's decision)

- **Decided**: 2026-11-13, 21:36 local, by the maintainer, relayed by the reviewer session under the wider delegation
  with their words and the time. Asked whether to reword FR-024 and FR-025 to match what was built, their answer: "2:
  yes".
- **Cause**: DRIFT-007. The placement ruling moved observability-resilience's four problem questions to the lenses
  whose subject they are, and widened FR-024's source; the spec still said what the plan had said before.
- **Change**: `spec.md` FR-024 now says an answer may be handed forward from any earlier lens that defines it, not only
  product-domain, and the source lens must run earlier in index.yml; the "not stated" line names its source lens.
  FR-025 lists the four questions under the lenses that hold them (requirements-nfr twice, security-compliance,
  devops-operations) and says observability-resilience, a solution lens with no problem questions, receives them
  handed forward, with the observability budget as product-domain's budget fact. Nothing else in the spec changed.
- **Class closure**: NONE — a spec wording update decided by the maintainer; FR-005c and the length test's consumer
  check already make a misplaced question or an undefined hand-forward source loud.

### DRIFT-011 — the recorded Light workshop run (T026) is answered by the reviewer session, each reply confirmed by the maintainer first (maintainer's decision)

- **Decided**: 2026-11-13, 21:36 local, by the maintainer, relayed by the reviewer session under the wider delegation
  with their words and the time: "1: you answer, but with me, meaning you write here first your answer and the
  reason - in short. I say - send, or ask to change".
- **Plan said**: the maintainer types the replies in a host session.
- **Effect**: for every workshop question the reviewer session writes its proposed reply and a short reason in its own
  session; the maintainer says "send" or asks for a change; only then does the reviewer send the reply to the workshop
  session. The maintainer opens the host session, since the reviewer cannot open an interactive one. The T026 evidence
  records it this way: the replies were sent by the reviewer session, each confirmed by the maintainer beforehand; they
  are not the maintainer's typed turns in the workshop session. The run proves that a lens shows its recommendations
  as one list, that "accept" closes it, that the compliance question is asked at Light, and that the maintainer read
  and agreed each answer. It does not prove a person typing in that session. On this engine the workshop hook records
  the reviewer's messages as typed replies (feature 203's B5F-064); the evidence file is the truthful record of who
  answered.
- **Class closure**: NONE — a decision on how the evidence is gathered, not a defect.

### DRIFT-012 — the Windows review-runtime job hung and was cancelled at its limit, with no log kept (external CI failure; handed over as a second sighting)

- **Observed**: 2026-11-13, Cross-Platform Validation run 43494561579 on `70c8cea9`, attempt 1, job 132124152471
  "Deterministic fake-provider review runtime (windows-latest)". The step "Run bounded deterministic review fault and
  conformance suites" started at 21:44 local and never finished; the job was cancelled at 22:11 local, past its
  25-minute limit. GitHub kept no log for the cancelled job (the log request returns "BlobNotFound"), so which suite
  hung cannot be read. Every other job of the run was green, and the same suites passed on macOS and Ubuntu. On the
  seven runs of this branch before it, the same Windows job took 5 to 6 minutes.
- **Cause, as far as 205 can see**: not 205's change. `70c8cea9` and `2cba60de` changed only `spec.md` and this drift
  log.
- **Resolution**: reported to the maintainer; one rerun ruled by the reviewer session under the maintainer's
  delegation (not covered by the standing co-review-service exception). Attempt 2 passed on 2026-11-14 (Windows job
  132456949975, 5 min 22 s; every job green). `70c8cea9` is fully green.
- **Class closure**: NONE — the suites and the step belong to feature 203's area. Feature 203 already holds the same
  failure as B5F-067 (run 43270394765, 2026-11-12), with a proposal to run each suite under its own limit and print
  its name as it starts. Handed over as H-020, a second sighting of B5F-067, not a new item.

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
