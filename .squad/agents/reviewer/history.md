# Reviewer History

Project-specific learnings and patterns discovered during work.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->

## Learnings

- 2026-05-08: Contract-gap closure reviews should verify that each accepted gap lands in three places when relevant: a binding functional requirement, explicit traceability coverage, and a reviewable evidence artifact definition. Presence in only one of those layers is not enough to preserve enforceability.
- 2026-05-08: When an iteration scope is split across iterations, `state.md` must stay iteration-local. Deferred feature work belongs on the next iteration artifact, not in the prior iteration's `Tasks Remaining`, or lifecycle status and closure evidence drift immediately.
- 2026-05-08: For formal review/demo, passing slice tests is insufficient. Re-check the live iteration `plan.md` task statuses, phase metadata, and reviewer-packet scaffold path, because review readiness can still fail on artifact truth or helper crashes after implementation looks complete.
- 2026-05-08: Review closeout on Phase 1 quality slices is still blocked if the reviewer packet leaves non-mechanical gates `planned`. Add `Category` metadata to `Required Quality Gates`, rerun `scaffold-reviewer-artifacts.ps1`, and keep the Gap Ledger at `No known gaps remain.` or an explicit fixed-now/deferred classification.
- 2026-05-08: When a planning repair claims a previously missing iteration boundary is fixed, verify three things separately before clearing implementation: the feature-level plan/tasks now express a capacity-true multi-iteration split, the target iteration artifacts exist and stay synchronized, and `validate-governance.ps1 -IterationPath <iteration>` passes on that specific slice. If all three hold, the remaining blocker is coordination-only human execution approval, not another planning defect.
- 2026-05-08: When a fixture-only setup task is intentionally bounded before scenario content exists, prefer empty root directories plus precise lifecycle truth over speculative scenario placeholders; that keeps later task ownership and evidence expectations honest.
- 2026-05-08: For Phase 2 governance helpers, centralize Markdown-table parsing and approval-reference resolution together, then prove them with one integration path that mixes human-approved deferrals and still-blocking `tbd` concerns. That keeps later validator work focused on policy enforcement instead of re-solving artifact parsing.
- 2026-05-08: For approved-deferral hardening fixtures, keep the scenario truthful by pairing `quality\hardening-gate.md` with a canonical fixture-local `.squad\decisions.md` entry; otherwise the case only models a claimed defer, not an actually approved one.
- 2026-05-08: When extending an existing governance regression suite with future-phase scenarios, fork from the suite's passing fixture baseline and vary only the new gate artifact plus approval evidence. That keeps the later test signal on the intended gate instead of reintroducing unrelated baseline failures.
- 2026-05-08: Hardening-gate contract coverage should assert three bounded states separately—`blocked`, `deferred-with-approval`, and `ready`—and prove them through the shared parser/approval helpers so fixture drift is caught before `run-hardening-gate.ps1` or `validate-governance.ps1` starts depending on the same contract.
- 2026-05-08: When validator enforcement starts depending on a later-phase hardening artifact, bind the check to the concrete Phase 2 planning metadata and the shared hardening-state helper together. That keeps verdict names, artifact paths, and human-approval semantics aligned across scaffolding, orchestration, fixtures, and fail-closed governance.
- 2026-05-08: When an iteration introduces a new fail-closed gate, require that same iteration to pass the live gate under accepted review before moving to retro. A self-approved defer would erase the dogfood signal and weaken closure evidence.
