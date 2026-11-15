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

**Total drift events**: 7
**Resolution rate**: 100% (7/7 resolved)
**Specification drift**: FR-015 and FR-016 corrected by the design decision (DRIFT-206-I002-003)

## Events

### DRIFT-206-I002-001 — bug item 13's fifth sighting, rerun under the standing exception

- **Observed**: 2026-11-15. Specrew CI run 43709472794 attempt 1 on `ce604236` (records only), job 132798404429
  "Deterministic gate": `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`, "Expected $null or empty
  ... but got System.Diagnostics.Process (pwsh)", 1 of 131, the only failure; the Contract lane was skipped.
- **Resolution**: rerun once without asking under the maintainer's standing exception: attempt 2 green, every job run.
  Recorded in bug list item 13.
- **Class closure**: NONE — the test and its code are feature 203's (HO-206-8); this sighting goes into iteration
  002's hand-over to 203.

### DRIFT-206-I002-002 — the plan scaffold rejects any requirement scope (recurrence of 205's DRIFT-002)

- **Observed**: 2026-11-15. `scaffold-iteration-plan.ps1 -RequirementScope FR-015,FR-016` and a scope of eleven
  requirements, FR-003 among them, all refused with "Requirement(s) not found in spec". With no scope it scaffolds.
  The scope was written by hand, as feature 205 did.
- **Also**: the iteration artifact scaffold wrote a drift log with no trailing newline and hardening rows whose
  placeholders fail markdownlint (MD047, MD038), and an Overall Verdict of `blocked` that the validator refuses once
  the rows are filled. Each was corrected in the iteration 002 records.
- **Class closure**: NONE — the scaffolds are part of the deployed extension. For iteration 002's hand-over to 203,
  beside 205's H-015 class.

### DRIFT-206-I002-003 — FR-015 and FR-016 corrected by the design decision (spec-updated)

- **What**: the maintainer chose Option B (2026-11-15). Under D1-a, FR-015 covers a task deferred by a recorded
  decision only, and feature 203's T014 (scheduled after sign-off by the plan) stays with proposal 206. Under D2-a,
  FR-016 accepts the record-before-verdict state with a warning where `start-context.json` is absent (CI cannot see it:
  it is ignored by git). SC-009 gains that case.
- **Resolution**: spec-updated in `fd032d72`, before any implementation.
- **Class closure**: NONE — a design decision, not a defect.

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

### DRIFT-206-I002-004 — the design analysis was written freehand, and the plan sync's design gate refused it

- **Observed**: 2026-11-15. `sync-boundary-state.ps1 -BoundaryType plan -IterationNumber 002 -AuthCommitHash 5099ba32`
  refused in `design-analysis-gate.ps1`: the Alternatives had no populated Simplest or Reasonable option, and the
  By-the-book option lacked the seven required fields and a diagram. The draft named its options by content ("Clear of
  203", "Remove the recurring costs", "By the book") with prose, not in the template's shape. The sync wrote nothing.
- **Resolution**: the Alternatives section rewritten in the template's shape, with the same three options under the
  same letters (A Simplest, B Reasonable, C By-the-book), each with Approach, Architectural pattern, Quality features
  considered, Effort estimate, Reversibility cost, Trade-offs and a Mermaid diagram. The decision points, sizes, cut and
  the maintainer's recorded choice (Option B) are unchanged. `Test-SpecrewDesignAnalysisArtifact` and
  `Invoke-SpecrewDesignAnalysisPlanBoundaryGate` both return Valid, Option B selected and recommended, before the
  sync is run again.
- **Class closure**: NONE — a crew error; plan-stage rule 6 (author into the scaffold) already covers it. The crew's
  practice from here: scaffold the design analysis with `New-SpecrewDesignAnalysisArtifact` and check it with the gate
  before the decision stop.

### DRIFT-206-I002-005 — the reviewer's rulings on the before-implement discussion prompts (human-decision)

- **What**: 2026-11-15, after the maintainer's "approved for before-implement". The reviewer (specrewreviewer-98) told
  the maintainer the answers first and sent them on the maintainer's approval, with no objection raised; routine
  rulings under the delegation, not approvals.
  1. `/speckit.analyze` is not run: the traceability check covers the same links, and governance passes on the
     iteration.
  2. The first review round runs after Phase 5 (T020 to T025), on three conditions:
     - before asking for it, all five lanes run green in the review's own layout, built as the engine builds it, with
       the environment the launch really has (HOME included);
     - `--timeout-seconds` is sized from the lanes' measured time in that layout plus the reviewer's pass, and the
       number is stated in the request;
     - the round's scope file is committed before the round, with T037's two brief additions in it, and the tree holds
       nothing the sign-off sync counts as an uncommitted product or methodology path.
  Each round is still the maintainer's typed approval.
- **Also**: no quiet is needed for feature 203 now (its review is signed off, its sweeps done). T020 and T022 fixtures
  and any supervised run stay inside temp folders the crew creates; home hashed before and after every run.
- **Resolution**: recorded; applied at the Phase 5 review request.
- **Class closure**: NONE — a ruling, not a defect.

### DRIFT-206-I002-006 — T021 changed the census guard's pin, a file outside its owned list

- **What**: 2026-11-15. With T021's fixture fix committed, the f206-census-guard lane failed in the review layout (1 of
  76): `tests/unit/every-suite-is-named-by-a-lane.tests.ps1` still pinned iteration 001's ruling that
  `validator-hardening-iteration2.ps1` is excluded with a `red:` reason. That ruling (maintainer, 2026-11-12) named its
  own next step, green and then the release manifest, which T021 did; T021's owned files did not list the guard.
- **Resolution**: the pin moved to the guard's release-only list, and a new assertion holds the script to fixtures in a
  temp folder that copy only what git does not ignore (false on the pre-T021 script, true now); 76 of 76.
- **Also found by the layout, in T020's own test**: one case escaped a null `USERNAME` (unset in the preflight's
  emptied environment) into an empty pattern, which matches everything (`9acf6cec`); and the new suite was named by
  no lane (`c9db9184`). Each layout red came from this crew's change, none from the product.
- **Class closure**: NONE — the review-request conditions (DRIFT-206-I002-005) already run the lanes in the layout
  before every push of code.

### DRIFT-206-I002-007 — T023 changed a release-cadence integration test outside its owned files

- **What**: 2026-11-15. `tests/integration/closeout-identity-schema-parity.tests.ps1` pinned the identity file's
  `session_state_feature_path` as an absolute, quoted path ending in `specs\022-hotfix-schema-tests`: the very value
  bug list item 23 removes from a tracked file. T023 owns `tests/unit/**` only.
- **Resolution**: the pin now expects the relative path, `specs/022-hotfix-schema-tests`, which the frontmatter writer
  leaves unquoted. The test was read, not run: it runs `specrew start` without pointing the user profile at a temp file
  and builds its fixture under this repository's `.scratch/`; it is release cadence, so CI does not run it per push.
  The conversion and the reader are proven by `tests/unit/resume-path-inside-project.tests.ps1`.
- **Class closure**: NONE — the release-cadence suites that run `specrew start` without the profile redirect are
  bug list item 8's and feature 203's private-test-home class.
