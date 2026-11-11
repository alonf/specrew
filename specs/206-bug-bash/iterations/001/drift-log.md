# Drift Log: Iteration 001

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
**Resolution rate**: 57% (4/7 resolved; 001 open until T007 lands; 006 open until T009 lands; 007 deferred to
iteration 002 as bug list item 12)
**Specification drift**: None detected (process drift only)

## Events

### DRIFT-206-I001-001 — the OVERRIDE 5 revert, pushed alone, turned Specrew CI red on two iterations

- **Recorded**: 2026-11-11, at the maintainer's instruction.
- **Run**: Specrew CI run 42918626688 on `a3778f1a` (the revert of OVERRIDE 5, pushed alone by the
  maintainer's choice of "two plain pushes, no history rewrite"). Lint failed; the Deterministic gate and
  Contract lane were skipped. Test and Cross-Platform Validation were green.
- **Trigger**: the revert touched `.specrew/iteration-config.yml`, one of the validator's global-state paths,
  relative to the push base `435332da`. So `-ChangedOnly` fell back to the whole repository
  (`global-state-changed`, 159 iterations).
- **Failures, and what fixes each**:
  - `198-beta2-hardening/011`: "Complete iterations require review.md overall verdict 'accepted' (found
    'needs-rework')". The nightly's existing failure; fixed by T007 (marked abandoned by the maintainer's
    ruling).
  - `206-bug-bash/001`: "plan.md Capacity total '22' does not match iteration-config capacity_per_iteration
    '20'" (Capacity line and Effort Model). At `a3778f1a` the plan still read 21.75/22; fixed by `99eb5132`
    (20/20, T016 and T017 deferred to iteration 002), which is in the second push.
- **Process miss**: the revert was not validated on its own before it was pushed. The local runs validated
  the two commits together (and changed-only against `origin/main`, not against the push base CI uses), so
  the 206/001 failure was not seen. The maintainer had expected 198/011 only.
- **Class closure**: NONE — no executable guard is added in this feature; the working rule from here on is to
  validate each pushed head alone, changed-only against the push base CI will use (`SPECREW_SCOPE_BASE_REF`
  set to the previous pushed commit), before every push.

### DRIFT-206-I001-002 — external change to a real-home hook file during T001

- **Recorded**: 2026-11-11, at the maintainer's instruction.
- **What**: `~/.codex/hooks.json` changed between the T001 baseline hash (03:30:55 local) and the pre-test
  hash (03:32:18 local). File time 03:31:38 local, 43 seconds after the baseline.
- **Hashes (SHA-256)**: baseline `b3a87829a11e8c2e7f2b360dd4ed0e7220749ec52c59f81009fdea622555dc94`;
  changed to `8adb8157fb01749d2931b5a6223228ad1885d6d73240fbd3517ee40b49ff0e16`. The other 9 files in the
  set were unchanged; no file added or removed.
- **Cause**: feature 203's session (the maintainer's finding). No 206 test or script was running; the T001
  test run itself left all 10 files unchanged.
- **Resolution**: 206 stopped and restored nothing. The file was restored outside 206 and a new baseline at
  10:42:51 local matched the first baseline on all 10 files; T001 resumed.
- **Class closure**: NONE — the writer is outside 206. Working rule from here on (maintainer): a hash change
  while none of 206's own tests or scripts ran is reported in one line and work continues on anything that
  runs no Specrew script; a full stop applies only when the change falls inside one of 206's own runs.

### DRIFT-206-I001-003 — T006 changed a test file outside its owned files: the W51 fixture

- **Recorded**: 2026-11-11, at the maintainer's instruction (T006 ruling, condition 3).
- **What**: `tests/integration/closed-iterations-are-history.tests.ps1` is not in T006's owned files. Its shared
  fixture (`New-TwoIterationProject`) closed iteration 001 only through `**Current Phase**: iteration-closeout`
  plus `RETRO COMPLETE`, which is the state.md text heuristic that FR-008a removes from the closed definition.
  After T006, W51 part 2 read that iteration as open and failed ("closed-iteration filter: 1 closed iterations
  skipped" not printed).
- **Change**: the fixture's state.md gains `**Iteration Status**: complete`, plus a comment naming the reason.
  W51's point is kept: the iteration is closed by its own state.md, with no closed-index entry.
- **Approval**: the maintainer, 2026-11-11 ("approved to add Iteration Status: complete to its test iteration").
- **Resolution**: lands in T006's fix commit.
- **Class closure**: NONE — a one-off fixture follow-up to a definition change the maintainer ruled on; no
  mechanism is needed to stop a test from following a ruled definition.

### DRIFT-206-I001-004 — T002 changed a deployed file without refreshing its hash

- **Recorded**: 2026-11-11, at the maintainer's instruction (T006 ruling, hash-file item 4).
- **What**: T002's fix commit `6acb84aa` edited the `.specify` mirror of `validate-governance.ps1` and left its
  entry in `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json` at the old value. The
  validator's deployed-machinery integrity check then reports "The deployed Specrew machinery ... does not match
  what was installed" for every iteration with a review.md that it validates. T006's uncommitted change added
  `shared-governance.ps1` to the mismatch.
- **Evidence**: hashes computed the way the check computes them (`Get-SpecrewDeployedExtensionManifest`,
  CR-stripped, SHA-256) match the file at `6acb84aa~1` for both files; from `6acb84aa`, `validate-governance.ps1`
  differs. `tests/integration/validate-governance-changed-only.tests.ps1` failed 3 assertions on it, all with
  this error (run from this worktree, a short path, on the T006 working tree).
- **Why nothing caught it**: 206's own iteration has no review.md, so 206's validator runs stayed green, and no
  CI workflow runs the suite that fails (bug-list item 10).
- **Resolution**: `52662ebc` refreshes T002's entry (old `7cee2741...e3bc`, new `a7076e71...518f`); T006's fix
  commit refreshes both entries for its own change. Values in the bug-list item.
- **Class closure**: a working rule from the maintainer (2026-11-11): any commit that touches a file under
  `.specify/extensions/specrew-speckit/` refreshes the hash file in the same commit. The executable guard (a CI
  step) is proposed in bug-list item 10; no workflow is changed in this feature yet.

### DRIFT-206-I001-005 — T006's comments cited a feature id in the deployed surface; Specrew CI went red

- **Recorded**: 2026-11-11.
- **Run**: Specrew CI run 43068147301 on `b76dd4d8`. "Self-leak firewall (deploy surface)" failed, and the
  Deterministic gate failed on the same check (`tests/unit/self-leak-lint.tests.ps1`, 1 of 131). Test and
  Cross-Platform Validation were green (the macOS fault-matrix case passed).
- **What**: six comments added by T006 in `extensions/specrew-speckit/scripts/shared-governance.ps1` (4) and
  `validate-governance.ps1` (2) began with the feature id `F-206`, which the self-leak lint refuses in files
  deployed to consumer projects.
- **Process miss**: the pre-push checks were markdownlint and validate -ChangedOnly only; the self-leak lint
  (`scripts/internal/lint-self-leak.ps1`) was not run locally. It reproduced the 6 hits before the fix and is
  green after.
- **Resolution**: the comments name the requirement and the rule, not the feature; the `.specify` mirrors and
  their hash entries are refreshed in the same commit.
- **Second miss, same push sequence**: the fix and this entry were pushed as `dc932cda` although validate
  -ChangedOnly had failed on this entry's Class closure format; the push step tested the home-hash script's exit
  code instead of the validator's. Specrew CI run 43071573503 went red at Lint for it (Deterministic gate skipped).
  `f37e639d` fixed the format; its CI runs (Specrew CI 43071834486, Test, Cross-Platform Validation) were all green.
- **Class closure**: NONE — no executable guard is added in this feature; working rule from here on: the self-leak
  lint joins 206's pre-push checks whenever a push touches `extensions/` or `.specify/`.
  The push step now checks the validator's own exit code.

### DRIFT-206-I001-006 — the validator had no way to mark an iteration abandoned once retro.md exists

- **Recorded**: 2026-11-11, at the maintainer's instruction (T007 ruling, condition 5).
- **What**: T007 marks 198/011 and 197/006 abandoned by ruling. Both have a `retro.md`. The validator accepts
  only `retro` or `complete` as plan.md `Status` for an iteration with a `retro.md` ("plan.md status 'abandoned'
  is stale"), and a plan at `retro` is held to the review-verdict rule ("Complete iterations require review.md
  overall verdict 'accepted'"). No plan status says "abandoned" and passes.
- **197/006**: keeps plan.md at `Status: retro` with state.md at `Iteration Status: abandoned`, following
  174/007 (state.md `abandoned`, plan.md `executing`). It has no `review.md`, so the review-verdict rule does not
  fire, and it passes. Its Disposition section says why plan.md keeps `retro`.
- **198/011**: has a `review.md` with verdict `needs-rework`; neither form passes. Its abandonment is held back
  from T007's push (maintainer, 2026-11-11, option 1).
- **Resolution**: T009 adds the rule, test first: an iteration whose state.md says `abandoned` with a recorded
  ruling is not held to the plan-status rule or the review-verdict rule; `abandoned` with no recorded ruling
  still gets both. 198/011's abandonment lands in T009's push. Open until then.
- **Class closure**: T009's validator rule and its tests: abandonment by recorded ruling becomes a status the
  validator accepts after `retro.md`, and an unrecorded `abandoned` stays refused.

### DRIFT-206-I001-007 — the three push runs on 4f315689 are stuck as queued; 4f315689 has no Specrew CI result

- **Recorded**: 2026-11-12, at the maintainer's instruction.
- **What**: the push of `4f315689` (2026-11-11 20:26Z) created Test 43096082467, Specrew CI 43096082485 and
  Cross-Platform Validation 43096082509. All three stayed `queued` with 0 jobs (API `updated_at` 20:26:38Z). Runs
  of other workflows on `main` with the same runner label (`ubuntu-latest`) kept completing, and GitHub's status
  page showed Actions operational. Feature 205's push runs from 20:30Z are stuck the same way.
- **GitHub refuses to clear them**: cancel answers "Cannot cancel a workflow run that is completed";
  force-cancel answers "Cannot cancel a workflow run that has not been queued yet" (HTTP 409); re-run answers
  "cannot be rerun; its workflow file may be broken". The three runs are still listed as queued.
- **Re-checked on demand**: Test 43112873232 and Cross-Platform Validation 43112877362 were started manually on
  `4f315689` (workflow_dispatch) at 22:34Z; both started at once and both are green.
- **Not re-checked**: Specrew CI has no manual trigger, so **`4f315689` has no Specrew CI result of its own**.
  Its changes are re-checked only as part of the next push, `ad31b2d5` (T008), whose Specrew CI run is
  43113590639.
- **Resolution**: none possible from here for the stuck runs; Specrew CI's missing manual trigger is bug list
  item 12, a candidate for iteration 002 (no workflow changed now).
- **Class closure**: NONE — the stuck runs are a GitHub-side state this feature cannot change; the gap that
  left a commit without a re-check is bug list item 12, deferred to iteration 002 by the maintainer.

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
