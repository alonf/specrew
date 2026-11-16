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

**Total drift events**: 10
**Resolution rate**: 100% (10/10 resolved)
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

### DRIFT-206-I002-008 — the Phase 5 push was red on a structural guard no 206 lane runs (crew error)

- **Observed**: 2026-11-15. On `686811a6`, Specrew CI run 43752912081 (Deterministic gate, job 132931975184) and
  Cross-Platform Validation run 43752912089 (the fake-provider review runtime on macOS, Windows and Ubuntu) failed on
  one test, `tests/continuous-co-review/unit/path-identity.Tests.ps1`: "STRUCTURAL: no path comparison decides case
  from the OS family outside the primitive (offenders: sync-boundary-state.ps1:174)". T023's
  `Test-SpecrewPathInsideProject` chose case-insensitive comparison from `$IsWindows`/`$IsMacOS`. The five lanes were
  green in the review layout: none of them runs that guard. Not bug list item 13's flake; not rerun.
- **Resolution**: `43fb545c`. The check asks `Get-ContinuousCoReviewPathComparison -WhenUndetermined 'distinct'`, a
  doubtful path counts as outside, and it compares exactly when the primitive cannot be loaded. The primitive (feature
  203's file) is read and called, not changed. path-identity 17/17 and resume-path-inside-project 8/8 in the layout;
  the five lanes green.
- **The other repository-wide guards CI runs that 206's lanes do not** (read from `tests/f198-regression-suite.ps1`,
  the Deterministic gate's registry of 131 suites):
  `tests/continuous-co-review/unit/path-identity.Tests.ps1` (case and path-identity scans of the tree),
  `tests/continuous-co-review/unit/consumer-language.Tests.ps1` (every user-facing decision message free of machinery
  vocabulary and unglossed identifiers; relevant to T023's refusal and T025's warning), and
  `tests/continuous-co-review/unit/authority-control-consumer-guard.Tests.ps1` (every declared authority control has a
  production consumer). The self-leak firewall is a job of its own and is run before any push touching
  `extensions/` or `.specify/`.
- **Class closure**: `f206-structural-guards`, a new lane of 206's verification plan (the reviewer's ruling,
  2026-11-15). All three join it when the plan moves to iteration 002 for the first review round, so the review's
  preflight and the pre-push run both carry them. The push of this entry went out with the governance check red, because
  the command did not stop on that failure; the next push gates on it.
- **In the lane (2026-11-15, its first run in the review layout):** path identity and authority-control consumers. The
  consumer-language suite failed there on one case: it counts the design-workshop instruction surfaces with
  `git ls-files`, and the review preflight restores `.specify` untracked, so the project mirror is not counted (green in
  CI, where it is tracked). It is feature 203's test, so it stays in CI's Deterministic gate only, and the layout limit
  goes into iteration 002's hand-over to 203.

### DRIFT-206-I002-009 — a records commit pushed while the governance check was failing (crew error)

- **Observed**: 2026-11-15. `3ca2f46a` (DRIFT-206-I002-008's entry) was pushed although `validate-governance
  -ChangedOnly` had just failed on it ("missing required Class closure"): the shell call printed the check's exit code
  and went on to `git push`. Specrew CI run 43755677442 shows it: Lint job 132939119745 red on that entry, the
  Deterministic gate and the Contract lane skipped. Outside the maintainer's allowances; the reviewer has told the
  maintainer. The second time on 2026-11-15 that a check's failure did not stop what came after it (the first is
  DRIFT-206-I002-008).
- **Resolution**: `7bdb0943`, with markdownlint and governance green first: the label in the validator's form.
- **Class closure**: `safe-push.ps1`, a script in the crew's scratchpad, not in the repository (the reviewer's ruling,
  2026-11-15). It is the only way this crew pushes: it refuses `main` and a difference holding
  `.squad/active-features.yml`; runs the CI markdownlint command and `validate-governance -ChangedOnly` against the last
  pushed commit, and `lint-self-leak` when `extensions/` or `.specify/` changed; for anything that is not a record,
  requires the five lanes green in the review layout on a clean tree at a commit with only records since; and pushes
  only if every check exits 0.

### DRIFT-206-I002-010 — round 1's findings: nine fixed before round 2 (human-decision)

- **Round 1** (`cmp-206-bug-bash-i002`, run `run-20261115-233001030-c21b0c2f`, head `7c006d67`): verdict findings, 10
  findings, none blocking; two reported major and demoted for stating no concrete failure scenario (F1, the
  start-written record taking a user's uncommitted edit to `copilot-instructions.md` as Specrew's; F2, SC-001's fixture
  carrying this machine's absolute identity path). The crew checked each against the code: nine are real, F8 is noted.
- **Decision**: the maintainer's words to the reviewer, at 02:16 local on 2026-11-16, "For 206, agree", to option 1:
  fix F1 to F7, F9 and F10 now, a failing test first and one finding per commit, about 1.5 SP on a plan at 20 of 20;
  then Phase 6; round 2 reviews the fixes with the next phases. Relayed by the reviewer (specrewreviewer-98); not an
  answer to the engine's open round question, which stays the maintainer's.
- **The reviewer's conditions**: F1 first, its test showing that exact case and T003's classifier still pausing once
  the file is out of the record; F2 next, and SC-001's script is not registered per push until F2's fix is green in CI
  on all three systems; F3 resolves links through the path-identity helper and refuses when it cannot tell; F7 runs a
  real sync on a temp fixture, and the phase's other tests are checked for the same source-text shape; every fix
  through the gated push script with the six lanes in the review layout; past about 2 SP, stop and tell the reviewer.
- **Resolution** (2026-11-16): the nine fixed, each RED first and one finding per commit: F1 `409df238` (the shared
  `copilot-instructions.md` never in the record; T003's classifier pauses on the user's edit), F2 `541708af` (SC-001's
  fixture writes the copied identity path relative), F3 `1553dbdc` (a junction or symlink below the project is outside,
  through the one reparse-point policy; unknown is outside), F4 `79c3c224` (an outside session path not adopted is
  cleared before it is written back), F5 `0245115a` (a record region per writing step, none spanning a prompt), F6
  `5bbaec3b` and F9 `f87330bd` (SC-001's temp folder per run; every case in the fixture), F7 `55d42b72` (a real
  boundary sync on a temp project; mutation-checked), F10 `32244053` (comment). SC-001's supervised run 6: six checks
  pass, home and repository unchanged. Not yet in CI.
- **The phase's other source-text cases** (the reviewer's condition 4): three remain, each a wiring check with a
  behavioural one beside it: start's regions (F5's region case and T020's end-to-end), init's probe call (the
  probe's unit case and SC-001's run, which leaves no probe folder in the repository), and SC-001's identity call
  (supervised run 6). Listed for round 2.
- **Effort**: within the reviewer's 2 SP bound; no task moved.
- **Class closure**: NONE — a decision on review findings, not a defect.

### DRIFT-206-I002-011 — T028's fix lies partly outside the files the task names (plan-correction)

- **Recorded**: 2026-11-16, by the crew, at T028.
- **What**: T028 names `tests/integration/distribution-module-publish.ps1` and `scripts/release/**` as its files.
  There is no `scripts/release/` folder: the release script the suite calls is `scripts/internal/invoke-module-release.ps1`.
  The refusal also needs its one caller to ask for the publish, which is a line in `.github/workflows/publish-module.yml`.
- **Done**: the fix changed those two files, plus the suite (`619b1a85`). Each change is limited to the publish
  confirmation. The new unit suite `tests/unit/release-script-refuses-unasked-publish.tests.ps1` pins the workflow's line.
- **Not done**: the publish suite was not run here. Whether it runs per push or stays excluded is the maintainer's ruling,
  which is the task's own stop.
- **Class closure**: NONE — this is a wrong path in one task's file list, not a recurring mechanism.
