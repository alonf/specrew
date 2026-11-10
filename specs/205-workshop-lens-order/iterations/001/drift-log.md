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

**Total drift events**: 4
**Resolution rate**: 100% (4/4 resolved for this feature; DRIFT-001 and DRIFT-004 class closure open)
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
