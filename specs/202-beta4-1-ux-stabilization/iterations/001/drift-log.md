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
**Resolution rate**: 71% (5/7 resolved; DRIFT-004 and DRIFT-006 open)
**Specification drift**: 1 (spec-updated at design-analysis)

## Events

### DRIFT-001 — FR-018 used the branch as a reconciliation source; the branch is not the feature (resolved)

- **Observed**: 2026-10-13, design-analysis co-design (DA-5). As approved at specify, FR-018 said a stale pointer is reconciled "from the branch and the in-flight work". The maintainer corrected this: this worktree ran feature 199 on branch `201-first-run-experience`, so the branch name is evidence of nothing.
- **Requirement**: FR-018, and US4 scenario 2 (spec.md).
- **Resolution**: spec-updated, by human decision at design-analysis. The precedence is now (1) the in-flight controller or pending crossing, (2) the pointer if written for the current branch, (3) the branch name as a hint only, always disclosing which source decided. US4 scenario 2 was updated to match. The data-storage lens binding `pointer-branch-guard: stale-on-branch-mismatch-reconcile-disclose` still holds.
- **Class closure**: NONE. This is a requirement correction, not a code defect; the resolver test for SC-006 pins the precedence order, including the 199-on-201 case.

### DRIFT-002 — the design-analysis gate disclosed its required format one layer per refusal (observation)

- **Observed**: 2026-10-13, plan sync for iteration 001. Three consecutive refusals each named a different layer of the required design-analysis format. The first named missing Alternatives, Crew Recommendation, Human Decision fields and a detectable flow. The second named the Simplest, Reasonable and By-the-book labels. The third named per-option fields (Architectural pattern, Quality features considered, Effort estimate, Reversibility cost, a Mermaid diagram). Each refusal was accurate, but none listed the complete contract, so the agent spent three repair cycles. No human turn was consumed.
- **Requirement**: adjacent to FR-020 (B4F-102: a refusal names the producing step). The producing step exists (`New-SpecrewDesignAnalysisArtifact`, design-analysis-gate.ps1 ~950), and its scaffold would have carried the full format. The refusal never named it.
- **Resolution**: the content was restructured to the format with no change to any agreed decision. T013 (FR-020) is extended in scope to cover this case: the plan-gate refusal names the scaffold step and reports every missing field in one pass.
- **Class closure**: T013's fixture asserts that a design-analysis missing several layers gets one refusal listing all of them, together with the scaffold step.

### DRIFT-003 — T005's 3-OS workflow change contradicts the workshop's devops-operations skip (resolved by human decision)

- **Observed**: 2026-10-13, at the plan verdict. The confirmed workshop agenda skipped devops-operations with the reason "No pipeline or deployment change in scope". Plan W5/T005 changes `.github/workflows/**` so that fault-injection case (e), two real processes appending at once, runs on Windows, macOS and Linux (FR-025).
- **Requirement**: FR-025 (case (e) on three operating systems), against the devops-operations skip reason in lens-applicability.json.
- **Resolution**: human-decision (maintainer, plan verdict 2026-10-13). The workflow change stays. It is kept minimal: only what runs case (e) on the existing OS matrix, with no new jobs, publication or deployment change. T005's acceptance states that the workflow diff is reviewed like code. The skip reason in the confirmed agenda is not rewritten; this entry records the exception.
- **Class closure**: NONE. This is a scope exception decided by the maintainer, not a defect. T005's acceptance pins the review requirement.

### DRIFT-004 — the tasks verdict was not captured because a context compaction landed between the packet and the reply (open)

- **Observed**: 2026-10-13, tasks boundary. The maintainer replied `approved for tasks - Run T001 first...` after Claude Code had compacted the context. `last_authorized_boundary` stayed `plan`. The read-only capture check returned the older `clarify -> plan` pair; the classifier reads the reply as `approve` for `tasks`.
- **Requirement**: FR-026 neighbourhood (per-feature capture state), and the governing principle "verdicts stay explicit typed replies".
- **Resolution**: proceeded on the verdict as the pending-verdict artifact directs ("AUTHORITY IN FLIGHT"). No authorization was written by the agent. The Stop backstop is checked at the end of the turn. If the ledger still lacks the tasks verdict, the maintainer is asked once for the recording path. Recorded as B4F-112 (beta5 candidate).
- **Class closure**: NONE in 202 unless the maintainer pulls B4F-112 into Tier 1. Capture must survive a compaction and say when a verdict-shaped reply was not captured.

### DRIFT-005 — T001 ran before the before-implement verdict, and measured new host facts (resolved by human decision)

- **Observed**: 2026-10-13. tasks.md places T001 after the before-implement verdict. The maintainer's tasks verdict moved it ahead, as measurement only, in scratch directories with no product code. Results are in research.md, "T001 measurements".
- **Requirement**: FR-024; DA-3; DA-4.
- **Resolution**: human-decision. For Claude and Copilot, DA-3 and DA-4 both hold, so the plan needs no amendment for them. Three facts refine task acceptance without changing scope:
  - Copilot fires the prompt hook before SessionStart (T008 keys "first prompt" on the prompt event).
  - Copilot dismissals produce no hook event and use the strings "User cancelled the request." and "User responded: <default>", not "User skipped question" (T002 registry fixture; B4F-113).
  - Hook stdin arrives as UTF-8 while the hook process's console input encoding is `ibm437` (T002 and T014 decode bytes explicitly).
  - **Codex** needed persisted hook trust. The maintainer chose option a at the tasks verdict. The three trusted hooks were confirmed to be the scratch capture hooks and nothing else. The trust entry was recorded in research.md and then removed, and the scratch folder was deleted. DA-3 and DA-4 hold for Codex too. **No validated host fails DA-3 or DA-4, so the plan is not amended.**
- **Class closure**: the T001 fixtures under `tests/fixtures/hook-payloads/` pin these facts for T002's contract test.

### DRIFT-006 — the readiness verdict reported READY for implementation before any before-implement verdict (open; T011 scope)

- **Observed**: 2026-10-13, before-implement preparation. `readiness-verdict.ps1` printed "Overall verdict: READY for implementation - 'before-implement' is authorized (this iteration's cycle is authorized through 'feature-closeout')". The ledger's `last_authorized_boundary` is `tasks`, and `verdict_history` holds no `approved for before-implement` for 202. The check reads feature 199's completed cycle as 202's.
- **Requirement**: FR-026 (all per-feature runtime state keyed to the new feature on a new-feature reset; B4F-109 widened at clarify). A false READY first line is the B4F-071 hazard: a crew can announce implementation on it.
- **Resolution**: not acted on. Implementation waits for the human verdict regardless. T011's scope already covers it ("all per-feature runtime state keyed to the new feature"). Its acceptance gains one check: the readiness verdict for a new feature never reports a prior feature's cycle as authorization.
- **Class closure**: T011's `new-feature-reset` test asserts that the readiness verdict for 202, before its before-implement verdict, is not READY.

### DRIFT-007 — the validator counts the T001 evidence fixtures as unauthorized product source (resolved by human decision)

- **Observed**: 2026-10-13. `validate-governance.ps1` FAIL `source-without-implement-authorization` named the seven Codex fixtures under `tests/fixtures/hook-payloads/codex/`, committed after the tasks authorization was recorded.
- **Requirement**: the maintainer's tasks verdict authorized committing T001's findings as evidence, with no product code. Fixtures are recorded host payloads, not code.
- **Resolution**: human-decision (tasks verdict). No revert. The before-implement verdict, when given, covers them under the validator's own rule.
- **Class closure**: NONE. The validator's source classification treats all of `tests/**` as source; whether recorded-evidence fixtures should be exempt is not 202 scope.
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
