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

**Total drift events**: 23
**Resolution rate**: 100% (23/23 resolved for this feature; DRIFT-001, DRIFT-004 to DRIFT-023 class closure open)
**Specification drift**: None detected

## Events

### DRIFT-001 — the quality-profile resolver read the stack as Node plus a browser SPA (observation, recurrence)

- **Observed**: 2026-11-10, before-plan, `resolve-quality-profile.ps1` against this worktree. The resolver matched
  the presets `node-rest-with-postgres` (score 90) and `react-spa-public` (score 80), and declared stack surfaces
  "Node.js http-api" and "TypeScript/JavaScript browser-spa". This feature's surfaces are PowerShell scripts, lens
  markdown and tests.
- **Recurrence of**: feature 203's DRIFT-001, recorded at 203's plan verdict on 2026-10-31
  (`specs/203-beta5-stabilization/iterations/001/drift-log.md` on branch `203-beta5-stabilization`). 202's plan
  recorded the same misreading on 2026-10-13.
- **Requirement**: the plan's quality planning inputs (before-plan).
- **Resolution**: corrected by hand in plan.md, "Quality plan (resolved profile, corrected)", recorded at the
  maintainer's design-analysis verdict (note 3, 2026-11-10).
- **Class closure**: NONE — the resolver is outside 205's scope; the class stays open as recorded at 203 (it will
  misread the next feature in this repository too).

### DRIFT-002 — the design-analysis draft was pushed before the iteration plan existed, turning Specrew CI red (crew choice)

- **Observed**: 2026-11-10, commit `839ce7c9` (design-analysis draft plus the scaffolded iteration folder). Specrew CI
  run 42724688753 failed in Lint, step "Validate iteration governance (push)", where
  `validate-governance.ps1 -ProjectPath . -ChangedOnly` reported
  `specs/205-workshop-lens-order/iterations/001: Missing required artifact: plan.md`. Deterministic gate and
  Contract lane were skipped. Test and Cross-Platform Validation passed.
- **Was the push required by the lifecycle?** No. **It was the crew's choice.** Before the verdict, the
  design-analysis stop requires the draft and a Human Decision that names the commit containing it. A boundary
  sync's `verdict-commit-durable` preflight requires that commit on origin, but the design-analysis stop runs no
  boundary sync. The crew pushed under the standing push permission, whose condition is "a boundary step needs the
  commit on origin", and that condition did not hold here. So this is a crew sequencing error, not a process
  defect, and no finding is raised against the lifecycle.
- **Resolution**: the maintainer approved continuing to plan.md with `839ce7c9` red. The first push that includes
  the iteration plan is expected to clear it, and if it does not, it goes back to the maintainer. Standing rule for
  205 (maintainer, 2026-11-10): before every push, run `validate-governance.ps1 -ProjectPath . -ChangedOnly` and
  the CI markdownlint command, and push only if both exit 0.
- **Class closure**: that standing local validation step, recorded in the crew's memory as well.

### DRIFT-003 — the lens decision-point extractor does not see product-domain's numbered list (finding, kept by the maintainer at the plan verdict)

- **Observed**: 2026-11-10, planning SC-002. `Get-SpecrewLensDecisionPoints -LensId product-domain` returns 0 points,
  because product-domain's `## Design Decision Points` is a numbered list (`1. **Users ...**`), and the extractor
  folds only `-`/`*` bullets. code-implementation, which uses bullets, returns 7.
- **Impact on 205**: SC-002 treats product-domain as 0 before and 0 after. The FR-005 tagging checks must recognise
  numbered items as decision points, so that product-domain's eight areas are still proven to sit under exactly one
  sub-heading. 205 does not change the extractor, because changing it is outside the spec.
- **Class closure**: NONE — changing the extractor is outside 205's spec. Candidate for the extractor's owner: fold
  numbered items too, or state that product-domain is excluded from extraction by design.

### DRIFT-004 — every boundary records empty handoff evidence, so the validator warns handoff-block-missing (finding)

- **Observed**: 2026-11-10. Local `validate-governance.ps1` warns
  `[trust-hardening] handoff-block-missing` for each boundary commit: specify `7a4e6d7a` and `700e6127`, clarify
  `6d85718a`, plan `04ef9a72`, and tasks `0140eff0`.
- **Cause**: each boundary sync appends an event to `.specrew/handoff-evidence.json` (`sync-boundary-state.ps1:2049`,
  `Add-SpecrewHandoffEvidence`) carrying `-HandoffText`. The coordinator authors the six-section packet *after* the
  sync, so no text is passed, and every event records `response_text: ""` and `handoff_present: false`.
  `Test-SpecrewHandoffBlockPresent` accepts the six-section headings, but there is nothing to read.
- **Impact**: a soft warning only. `Write-TrustHardeningWarning` counts it as soft and never sets the exit code. A
  hard failure needs recorded packet text that fails the handoff validator, which empty text cannot produce, so
  review-signoff and closeout do not refuse on it. The file is gitignored (`.gitignore:26`), so CI never sees it.
  The warning repeats at every later boundary.
- **Resolution**: reported to the maintainer at the tasks verdict (2026-11-10). No change in 205.
- **Class closure**: NONE — it is outside 205's scope. Candidate for the sync/turn-end owner: record the packet at
  turn end, when it exists (the turn-end script already holds the declared packet), instead of at sync time.

### DRIFT-005 — Cross-Platform Validation failed fetching Pester from the PowerShell Gallery (finding, not caused by 205)

- **Observed**: 2026-11-10, Cross-Platform Validation run 42734434753 (attempt 1) on `12837d26`, a docs-only commit.
  - Job: "Deterministic fake-provider review runtime (windows-latest) — never live support evidence".
  - Step: "Verify PowerShell and install pinned Pester".
  - Exact message: `Install-Package: No match was found for the specified search criteria and module name 'Pester'. Try Get-PSRepository to see all available registered module repositories.`, thrown as `pester-allusers-install-failed`.
  - The other 7 jobs passed, including the same job on ubuntu-latest and macos-latest. Test passed.
- **Pattern for feature 206 (bug bash)**: this is the **second CI red on this feature not caused by its commit**. The
  first was DRIFT-205-INTAKE-001: the co-review retry test failed once in the Deterministic gate on a docs-only commit
  (`workshop/intake-drift-log.md`). This one is a gate that depends on a live download from the PowerShell Gallery,
  and it fails when the Gallery does.
- **Resolution**: the maintainer approved one rerun of the failed job (attempt 2), with no further rerun if it fails
  the same way. T005 onward stays on hold until all three workflows are green on `12837d26`. Rerun result: attempt 2 of run 42734434753 concluded **success**, all 8 jobs, the Windows job included. Specrew CI and Test on `12837d26` also passed, with no job skipped.
- **Class closure**: NONE — the CI workflow is outside 205's scope. Candidate for 206: vendor or cache the pinned
  Pester (or retry the Gallery fetch with a clear infrastructure-failure label), so a Gallery outage reads as
  infrastructure, not as a red gate.

### DRIFT-006 — a turn opened by the maintainer's `!` command got no turn token, so the turn-end declaration was refused (finding)

- **Observed**: 2026-11-10. The maintainer typed `! gh auth refresh -h github.com -s workflow` to add the `workflow`
  scope after a rejected push (the T016 push of `03bc4c5b`). That turn began with the `!` command's output, not a
  typed message, and no `[specrew-turn]` line was issued. After pushing, the crew declared the turn end with the most
  recent token it had, which was from the previous turn. The check said:
  `Turn-end declaration refused: the token '14f181c5e1bc4a7f957a9473b895dacd' matches no live session in this project (0 live tokens).`
- **Impact**: none on the work. The push and CI were unaffected, and the turn ended without its declaration record.
  The maintainer was told in the reply.
- **Same gap as feature 203's DRIFT-054**, reached by a different route: a turn that starts without a typed message
  gets no token. There, the turn had no typed message; here, it began with a `!` shell command.
- **Class closure**: NONE — the turn-token hooks are outside 205's scope. Candidate for the turn-end owner: issue a
  token, or accept an explicit "no token this turn" declaration, when a turn starts from a `!` command or another
  non-typed input.

### DRIFT-007 — `empty-result-retry` failed again on a records-only commit (finding; second sighting of DRIFT-205-INTAKE-001)

- **Observed**: 2026-11-10, Specrew CI run 42743719583, attempt 1, on `cf01f599` (records only: this drift log and
  three `.squad` record files). Job "Deterministic gate", runner `ubuntu-latest`, step "F-198 honesty regression
  suite (NFR-007)": 1 of 131 files failed, `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1`.
  - Case: "does NOT retry a non-empty result (single spawn, no retry telemetry)".
  - Assertion: "Expected 1, because a healthy result must not be re-run, but got 2."
  - Contract lane was skipped because it waits on the failed gate.
- **Same code passed**: `03bc4c5b` passed every job about 40 minutes earlier, and `cf01f599` changed no code.
  DRIFT-205-INTAKE-001 was the first sighting of this test file failing (a different case).
- **Resolution**: the maintainer approved one rerun of the failed job. Attempt 2 concluded **success**: Self-leak
  firewall, Lint, Deterministic gate and Contract lane all passed, and all 10 workshop lens-order steps passed. Test
  (42743719636) and Cross-Platform Validation (42743720145) on `cf01f599` passed on the first attempt.
- **Class closure**: NONE — the test and the code under it belong to feature 203 (continuous co-review) and are bug 3
  of feature 206. Neither is touched by 205.

### DRIFT-008 — the review preflight ran feature 202's verification plan, and two of its suites rewrote the maintainer's real home hook files (finding; hand-over to 203)

- **Observed**: 2026-11-11, review round 1 (approved by the maintainer's typed `approved for review round`). Run
  `run-20261110-221211306-a1cb90e2` in campaign `cmp-205-workshop-lens-order-i001` ended `preflight-failed` after
  1,745 s: `verification-command-failed:iteration-003-governance-202,f199-class-guards-a:diagnostics-require-command-scoped-disclosure`.
  The reviewer was never invoked, and the engine reports that no round was used.
- **Cause 1, the stale plan**: `.specrew/verification-plan.json` (plan id `f199.i003.slice.v1`, last re-pointed
  2026-10-21 in `ede19399`) still names 10 lanes of features 202 and 199 (102 suites). One lane validates 202's
  iteration 003, which no longer applies.
- **Cause 2, the home writes**: four real-home hook files changed at 00:36:54 to 00:36:55 local, inside the preflight
  window (00:12 to 00:41): `~/.specrew/specrew-hook-launch.ps1`, `~/.codex/hooks.json`, `~/.cursor/hooks.json`
  and `~/.copilot/hooks/specrew-refocus.json`. Before, the three host files pointed at
  `~/.specrew/hooks/b958cbe133e6a88ee358f7c5f89d5a67/specrew-hook-launch.ps1`, and the root launcher was 10,804 bytes
  with live-engine pin handling. After, they pointed at the root launcher, which was 6,772 bytes with no pin
  handling: main's layout. The crew first read the direction backwards; the maintainer corrected it.
- **The suites that wrote them** (read only, not rerun): two suites in the plan run `scripts/specrew-update.ps1`
  against a temp project without redirecting the home folder. `specrew-update.ps1` calls
  `Invoke-RefocusHookDeployment` without `-UserHomeOverride`, so `deploy-refocus-hooks.ps1` writes the real home.
  - `tests/integration/deployed-extension-marker-on-update.tests.ps1` (line 64), lane `f199-slice-suites-a`, the
    second-to-last lane. Its timing fits the 00:36:55 write best.
  - `tests/integration/receipt-outcomes-retired.tests.ps1` (line 28), lane `f202-slice-suites-a`, an early lane. It
    would have written the same layout earlier in the run. The file times show only the last write.
  - Checked and cleared: `cross-host-workshop` and `turn-record-contract` pass `-UserHomeOverride` to a fixture home;
    `extension-deploy-refocus-digests` runs `deploy-speckit-extension.ps1`, which does not deploy hooks; the other
    matches were file names in lists or comments.
- **Resolution**: with the maintainer's permission for exactly those four files, the crew restored them from the
  backup taken before the T013 run, kept the changed versions in a second folder and deleted nothing. The hashes
  after the copy match the backup, and all three host files point at the `hooks/b958…` launcher again. The maintainer
  compared the four files with the backup and accepted the restore.
- **Plan re-pointed** (maintainer decision, 2026-11-11): `.specrew/verification-plan.json` (now `f205.i001.v1`) holds
  two commands, both labelled with this entry:
  - `iteration-001-governance-205`: governance validation of this iteration.
  - `f205-lens-order-suites`: the parity test and the 10 workshop suites, each read first and found to write only
    under the system temp folder.

  Before and after the next preflight the crew hashes every file under `~/.specrew/hooks/`,
  `~/.specrew/hook-bindings/`, `~/.specrew/specrew-hook-launch.ps1`, `~/.codex/hooks.json`, `~/.cursor/hooks.json`
  and both files in `~/.copilot/hooks/`, and stops on any change.
- **Side effect**: `tests/unit/every-suite-is-named-by-a-lane.tests.ps1` compares the plan with the suites on disk. It
  now fails when run locally, because the plan names 11 suites, not 40 or more. It is not in any CI workflow or the
  F-198 registry. The mechanism it offers, parking the carried-forward lanes in
  `.specrew/verification-plan.signoff-lanes.json`, was not used: the parked lanes run before signoff, and they include
  the two suites that write the home folder.
- **Class closure**: NONE — the review preflight and both suites belong to feature 203's area and are not edited by
  205. Handed over to 203 as a finding:
  `specs/205-workshop-lens-order/iterations/001/handover-to-203.md`.

### DRIFT-009 — `~/.codex/hooks.json` changed during review round 2, from another feature's test run (observation)

- **Observed**: 2026-11-11, review round 2, run `run-20261111-012900593-ccd284fa` in campaign
  `cmp-205-workshop-lens-order-i001`. The 10-file home hash set taken after the round showed one change:
  `~/.codex/hooks.json` was written at 03:31:38 local (SHA-256 `8ADB8157…`). Before the round it was `B3A87829…`.
  The other 9 files were unchanged. The crew touched nothing and reported it.
- **Cause** (per the maintainer): feature 203's test run, in another worktree, changed the file at 03:31. It was not
  this round's preflight: the re-pointed 205 plan runs no suite that writes the home folder (DRIFT-008).
- **Resolution**: the maintainer restored the file. By 03:37:51 it was back at `B3A87829…` with its original
  timestamp. After the maintainer lifted the hold, the crew re-hashed the set: all 10 files match the known-good set,
  and `~/.codex/hooks.json` is SHA-256 `b3a87829a11e8c2e7f2b360dd4ed0e7220749ec52c59f81009fdea622555dc94`.
- **Limit of the check**: a before-and-after hash shows only the end state. A write that is put back before the
  after-hash is invisible to it. This one was caught only because the after-hash ran before the restore.
- **Class closure**: NONE — the writer is feature 203's test run, outside 205's scope. The same class (a suite
  writing the real home folder) is already handed over to 203 as H-001.

### DRIFT-010 — T011 changed 18 deployed copies without refreshing their hashes; the check runs only once a review record exists (finding)

- **Observed**: 2026-11-11, writing the iteration 001 review record. `validate-governance.ps1 -ChangedOnly` failed:
  "The deployed Specrew machinery under .specify/extensions/specrew-speckit does not match what was installed
  (modified: commands/speckit.specrew-speckit.before-specify.md, knowledge/design-lenses/applicability-map.json,
  knowledge/design-lenses/architecture-core.md, knowledge/design-lenses/code-implementation.md,
  knowledge/design-lenses/component-design.md)." The same check passed on the same tree before the review record
  existed.
- **What it compares**: the sha256 of each deployed file (`Get-SpecrewDeployedExtensionManifest`) against the hash
  record `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json` (`managed_files`), in
  `Test-SpecrewDeployedExtensionIntegrity`. It does not read the installed module. The message lists only the first 5
  drifted files; 18 had drifted.
- **Why only now**: `Test-DeployedExtensionIntegrity` is called only from the review-record validation in
  `validate-governance.ps1`, so a deployed-copy change made at implement time is invisible until a `review.md` exists.
- **Cause**: T011 refreshed the deployed copies through the two deploy scripts in `9040b34c` (T005 to T011), but the
  hash record was last written at `2ea34f92` and was not refreshed. All 18 drifted files changed only in `9040b34c`, and
  each deployed copy is byte-identical to its source under `extensions/specrew-speckit/`.
- **Resolution**: the 18 `sha256` values in the hash record were refreshed in place, as feature 203 did in `43ec7bfc`,
  without `specrew update` (the maintainer's ruling). The check then reports 0 drifted and 0 missing.
- **Class closure**: NONE — the check's placement and the deploy scripts not writing the hash record are validator and
  deploy behaviour outside 205's scope; feature 206 hit the same thing today.

### DRIFT-011 — the crew set state.md and plan.md to the review phase ahead of the boundary sync (crew error)

- **Observed**: 2026-11-11, at the review-signoff sync. In `cf173030` the crew set state.md to Current Phase
  `review-signoff` and Iteration Status `reviewing`, and plan.md to Status `reviewing`, by hand. The last authorized
  boundary is still `before-implement`, so the sync refused with `[iteration-state-truth-gate]`: state.md and plan.md
  were ahead of the authority record.
- **Resolution**: both lines were put back to `before-implement` / `executing`, which match the record. The sync
  mirrors the phase when it records the crossing. T016 stays done; that is task truth, not phase.
- **Class closure**: NONE — the sync's state-truth gate already catches this and refused before any state change; the
  crew's own rule is that phase lines move only through the sync.

### DRIFT-012 — no review.md can pass both the local governance check and CI (finding)

- **Observed**: 2026-11-11, review record for iteration 001 (`cf173030`). The governance check derives an
  independent-review block for `review.md` from the review authority store under `.specrew/review/`, which is
  gitignored, so it exists only on the machine that ran the review.
  - Locally the store holds three runs, and the check observed the implementing session writing `review.md`, so it
    requires the derived block: a four-bullet block naming tree `bf289776` as the last tree a completed run read.
  - CI's store is empty, so CI derives a two-bullet block. With the local block in the file, Specrew CI run
    `43066362500` failed Lint on the mismatch, and the Deterministic gate and Contract lane were skipped.
  - Without the block, the local check fails ("block required"). No single text passes both.
- **Resolution**: the maintainer approved one exception to the pre-push rule: `review.md` returns without the derived
  block, with a plain statement of what its independence rests on, and is pushed with only the local "derived
  independent-review block required" error failing. CI passes on it.
- **Class closure**: NONE — the validator and the review store are feature 203's area. Handed over as H-002.

### DRIFT-013 — the sync needs review.md with the pre-review phase lines; the governance check refuses that pair (finding)

- **Observed**: 2026-11-11 and 2026-11-12, at the review-signoff sync. The sync needs three things of the commit it binds
  to: `review.md` present (`[owed-artifact] Boundary 'review-signoff' is missing owed evidence: review.md`), state.md and
  plan.md still at the last authorized boundary (`before-implement` / `executing`, the state-truth gate), and the
  commit on origin (`verdict-commit-durable`). The governance check refuses plan Status `executing` once `review.md`
  exists, locally and in CI. So the commit the sync binds to always fails the check, and every feature gets one red
  Specrew CI commit at review-signoff.
- **Correction**: this entry first said the sync needs the phase lines and the check needs the review phase, and the
  crew removed `review.md` by the revert `e2748a53` to let the sync run. The real sync then refused for the missing
  `review.md`; the preflight-only run does not check owed artifacts, so it had passed.
- **Resolution** (maintainer's ruling, 2026-11-12): `review.md` is restored with the phase lines pre-review and pushed
  with two named local failures ("derived block required", "plan executing with review.md") and Specrew CI red on Lint
  only for that one push. The sync binds to that commit, and the records push after it must be fully green. Feature 202
  iteration 003 took the same path in `a7e2b74c`.
- **Class closure**: NONE — the sync and the validator are feature 203's area. Handed over as H-003.

### DRIFT-014 — the deployed-file check names 5 of 18 drifted files and offers only specrew update (finding)

- **Observed**: 2026-11-11, DRIFT-010's check. The message lists `Select-Object -First 5` of the drifted files, with no
  count, so 18 drifted files read as five. Its only remedy is `specrew update --project-path ...`, which rewrites the
  deployed copies from the installed module and, in a Specrew checkout, would replace the feature's own deployed
  changes. It does not mention refreshing the hash record when the deployed copies are the intended ones.
- **Resolution**: the full list was taken from `Test-SpecrewDeployedExtensionIntegrity` directly, and the record was
  refreshed in place (`6331d2be`).
- **Class closure**: NONE — the check is validator behaviour outside 205's scope. Handed over as H-004.

### DRIFT-015 — Windows journal-fault-injection timing failure on cf173030 (external CI failure)

- **Observed**: 2026-11-11, Cross-Platform Validation run `43066363241` on `cf173030`, Windows job "Deterministic
  fake-provider review runtime", step "Hook-output journal concurrent append (case e) and outage buffer".
  journal-fault-injection reported 2 failures: "the fire's first wait runs out the 1000 ms budget (2,650 ms)" and
  "three waits on a held lock add 2,653 ms". `cf173030` changed only records. The same job was green on `d5d1ae06`
  and `eec3745b`.
- **Resolution**: recorded as an external CI failure (runner timing); not rerun. If it fails again on the next push,
  the crew stops and reports.
- **Class closure**: NONE — the suite and its timing budget belong to the review runtime, outside 205's scope.

### DRIFT-016 — CI on 8c7f3323 stayed queued for two hours without a job, and could not be cancelled (external CI failure)

- **Observed**: 2026-11-11 to 2026-11-12. The push of `8c7f3323` at 22:30 local created Specrew CI `43096458260`,
  Test `43096458451` and Cross-Platform Validation `43096458281`. About two hours later all three were still `queued`
  with no job created. Feature 206's three runs from 22:26 local were stuck the same way, and nothing was in progress
  anywhere in the repository. GitHub's status page showed Actions as operational.
- **Cancel refused**: with the maintainer's approval the crew tried to cancel all three. The cancel call answered
  "Cannot cancel a workflow run that is completed", while the same runs still read `queued`. The force-cancel call
  answered HTTP 409 "Cannot cancel a workflow run that has not been queued yet." Specrew CI has no
  `workflow_dispatch` trigger, so it cannot be started again by hand on the same commit. Feature 206's crew got the
  same refusals for cancel and re-run on its stuck runs.
- **Resolution** (maintainer's ruling, 2026-11-12): Test and Cross-Platform Validation were started by hand on
  `8c7f3323` (`workflow_dispatch`): Test `43113642311` and Cross-Platform Validation `43113646042`, both at 00:39 local.
  The sync runs once both are green and the governance check and markdownlint pass locally. **`8c7f3323` has no Specrew
  CI result of its own**: the stuck run `43096458260` is its only Specrew CI run. Specrew CI gets its run on the next
  push, which carries the sync records and the restored review record, and that run must be green before the
  review-signoff packet.
- **Class closure**: NONE — GitHub Actions' queue is outside the repository.

### DRIFT-017 — a session resume rewrote state.md and created tasks-progress.yml (finding)

- **Observed**: 2026-11-12 00:18:28 local, after a machine restart. The session-start hook ran the bootstrap provider
  in welcome-back mode. It reached `coordinator-resume.ps1` (line 165, `Get-TaskProgressSummary`), which calls
  `Sync-IterationTaskProgress` in `scripts/internal/task-progress.ps1`. That wrote a new, untracked
  `specs/205-workshop-lens-order/iterations/001/tasks-progress.yml`, and `Update-IterationStateFromTaskProgress`
  rewrote the tracked `state.md`. The rewrite changed Iteration Status from `executing` to `ready-for-review`, rewrote
  two field values, and added a managed task-progress summary block. Nobody ran a command; opening a session did it.
  The rewrite also dropped the blank line before `## Notes`, so the rewritten file fails markdownlint (MD032, MD022);
  `8c7f3323`'s own state.md passes.
- **Why it matters**: state.md's phase lines are checked by the boundary sync's state-truth gate (DRIFT-011, DRIFT-013).
  A resume that moves them can make the next sync refuse, or make a commit carry a status nobody chose.
- **Resolution**: neither file is committed (the maintainer's ruling). The crew runs the sync preflight with them as
  they are, and restores state.md to HEAD only if the preflight refuses on it.
- **Class closure**: NONE — the resume path and the task-progress writer are feature 203's area. Handed over as H-005.

### DRIFT-018 — review-runtime tests depend on runner speed (finding, handed over)

- **Observed**: 2026-11-10 to 2026-11-12, five review-runtime test failures on shared runners across features 205 and
  206, each on a commit that could not have caused it (DRIFT-015 is one of them).
- **Census**: at the maintainer's request the crew listed every review-runtime test site that depends on runner speed:
  14 sites in three classes (speed caps, real deadlines that must succeed, kill-then-check), plus two sleep barriers.
  One of them, the macOS process-group membership wait's 1,000 ms default, is a product defect, not only a test issue.
  The full table and seven proposals are in H-006.
- **Resolution**: handed over; no further work by 205.
- **Class closure**: NONE — the review engine, its tests and the hook dispatcher are feature 203's area. Handed over as
  H-006.

### DRIFT-019 — a partial sign-off given before review.md is written is voided by writing it, so this path costs two approvals (finding)

- **Observed**: 2026-11-11 and 2026-11-12. The maintainer's first partial-coverage approval was bound to tree
  `c515195b` (request `override-0154fc5b01bd0d281913edfa`). The review-signoff sync needs `review.md` in the commit it
  binds to (DRIFT-013), and writing it moved the tree. The sync bound to `b56aaeda` then refused:
  `review-signoff refused (latest-result-not-current): The latest campaign result remains useful evidence but targets a moved or earlier snapshot and cannot authorize the current tree.`
  The maintainer approved partial coverage a second time, for tree `b3857cb7` (request
  `override-8f8d952577533deb363dd645`), and the sync passed.
- **Why it matters**: the second approval adds no review. It re-approves the same code, because the record the sync
  itself requires moved the tree. Every partial sign-off on this path costs the human two approvals.
- **Resolution**: second approval given; sync passed on 2026-11-12 11:37 local.
- **Class closure**: NONE — the sign-off gate is feature 203's area. Handed over as H-007.

### DRIFT-020 — a refused sync rewrites the tracked file `.specrew/review/signoff-gate/latest.json` (finding)

- **Observed**: 2026-11-12 02:43 local. The refused review-signoff sync (DRIFT-019) rewrote the tracked
  `.specrew/review/signoff-gate/latest.json`, committed in `eec3745b`, from decision `allow` (reason
  `human-authorized-partial-override`, tree `c515195b`) to `block` (reason `latest-result-not-current`, tree
  `b3857cb7`, override null), and opened the new request in it.
- **Why it matters**: a refusal leaves a tracked file dirty, and the dirty file is part of the tree the new request is
  bound to. Restoring it to HEAD would move that tree, and committing it would record a refusal as the sign-off state.
  The crew left it as it was until the passing sync rewrote it to `allow`.
- **Resolution**: committed in its passing state in the boundary commit `fd2834bf`.
- **Class closure**: NONE — the sign-off gate is feature 203's area. Handed over as H-008.

### DRIFT-021 — the turn-end declaration was refused: the only token shown had been used by the previous turn (finding)

- **Observed**: 2026-11-12, the turn that ran the review-signoff sync. Its `[specrew-turn]` line repeated token
  `c2722297…`, which the previous turn had already declared and the Stop hook had consumed. The declaration was refused
  twice: `Turn-end declaration refused: the token 'c2722297f0ab428ab8883d8f4230e4af' matches no live session in this project (1 live token).`
  The one live token on disk belonged to a different session (the session resume at 2026-11-12 00:18 local), and the
  crew did not use it.
- **Impact**: the review-signoff packet was presented without a declaration record, so the script's packet check did
  not run (see DRIFT-022). The maintainer was told in the reply. The verdict was captured on the next turn.
- **Same class as DRIFT-006**: a turn ends up with no live token of its own.
- **Class closure**: NONE — the turn-token hooks are feature 203's area. Handed over as H-009.

### DRIFT-022 — the review-coverage line from the pending-stop record was left out of the review-signoff packet (crew error)

- **Observed**: 2026-11-12. The sync's pending-stop record carried a review-coverage line, and the crew's packet did not
  include it. The record was consumed when the verdict was captured, so the crew no longer has its text. The
  maintainer's reviewer read it before then; its opening, as the reviewer quoted it (truncated there):
  `Review coverage: last delivered review run-20261111-012900593-ccd284fa covered tree bf289776; 4 source file(s) changed since; 2 of 4 rounds remaining in campaign cmp-205-wor...`
- **Why it matters**: the launch contract requires the coverage line at every stop where the controller provides one,
  so that the human sees coverage drift. This packet's verdict was a partial-coverage sign-off, exactly where that
  line matters most.
- **Resolution**: recorded; the crew reads the pending-stop record's coverage line into every later packet.
- **Class closure**: NONE — the packet check that would catch it runs only when the turn-end declaration is accepted
  (DRIFT-021), and the Stop hook's fallback supplied the approval line and marker but not the coverage line. Handed
  over as H-010.

### DRIFT-023 — the derived-block item did not fire locally on `b56aaeda`, and fires now (finding)

- **Observed**: 2026-11-12. Before the `b56aaeda` push the local governance check failed on one item only, "plan.md
  status 'executing' is stale". After the verdict moved plan.md to `reviewing`, the boundary commit's tree fails on
  one item only: `review.md carries no derived independent-review block, and this record was written after the block existed (its authorship was observed: implementing-session).`
  `review.md` is unchanged since `b56aaeda`.
- **The crew's reading**: the item fires only once the iteration is in a review phase. On `cf173030` plan.md was
  `reviewing` and it fired; on `b56aaeda` plan.md was `executing` and it did not; on `fd2834bf` plan.md is `reviewing`
  and it fires. This reading comes from the three observations, not from the validator's source.
- **Resolution** (maintainer's ruling, 2026-11-12): a standing exception for feature 205, for this item only. The
  record stays without the block (B5F-049: without the block CI only warns, with it CI fails, as on `cf173030`). Any
  other local governance failure still stops the push.
- **Class closure**: NONE — the validator is feature 203's area. Added to H-002.
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
