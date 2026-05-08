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
