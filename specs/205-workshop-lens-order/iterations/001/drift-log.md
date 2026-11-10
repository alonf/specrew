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

**Total drift events**: 8
**Resolution rate**: 100% (8/8 resolved for this feature; DRIFT-001, DRIFT-004 to DRIFT-008 class closure open)
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
