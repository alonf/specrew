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

**Total drift events**: 5
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
