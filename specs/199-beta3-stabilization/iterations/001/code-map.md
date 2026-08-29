# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-08-21
**Baseline Ref**: 78f68e4563c612c7cf1bd1d0cecadd826c887f6c
**Test-to-Code Ratio**: 174:134

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **13 completed task(s)**, but the git diff against baseline `78f68e4563c612c7cf1bd1d0cecadd826c887f6c` contains **462 file(s)**.
>
> **Severity**: WARNING
> **Implication**: Review evidence may be incomplete or misleading.
>
> **Possible causes**:
>
> - Implementation work was not committed before scaffolding review artifacts
> - Task status markers in plan.md or review.md do not match actual progress
> - Baseline reference in state.md is stale or incorrect
>
> **Remediation**:
>
> 1. Verify implementation is committed: `git diff 78f68e4563c612c7cf1bd1d0cecadd826c887f6c...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .agents/skills/specrew-code-rules/.specrew-managed | 4 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .agents/skills/specrew-code-rules/SKILL.md | 93 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .agents/skills/specrew-design-workshop/SKILL.md | 85 | 35 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .agents/skills/specrew-drift-check/SKILL.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .agents/skills/specrew-local-build/SKILL.md | 119 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .agents/skills/specrew-refocus/SKILL.md | 2 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .agents/skills/specrew-update/SKILL.md | 2 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/settings.local.json | 13 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/skills/specrew-code-rules/.specrew-managed | 4 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/skills/specrew-code-rules/SKILL.md | 93 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/skills/specrew-design-workshop/SKILL.md | 85 | 35 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/skills/specrew-drift-check/SKILL.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/skills/specrew-gate-stop/SKILL.md | 27 | 8 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/skills/specrew-local-build/SKILL.md | 119 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/skills/specrew-refocus/SKILL.md | 2 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/skills/specrew-review/SKILL.md | 2 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .claude/skills/specrew-update/SKILL.md | 2 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .copilot/skills/specrew-capacity-planning/SKILL.md | 0 | 82 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .copilot/skills/specrew-drift-check/SKILL.md | 0 | 103 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .copilot/skills/specrew-traceability-check/SKILL.md | 0 | 70 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .cursor/rules/specrew-code-rules/.specrew-managed | 4 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .cursor/rules/specrew-code-rules/SKILL.md | 93 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .cursor/rules/specrew-design-workshop/SKILL.md | 85 | 35 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .cursor/rules/specrew-drift-check/SKILL.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .cursor/rules/specrew-local-build/SKILL.md | 119 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .cursor/rules/specrew-review/SKILL.md | 6 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .cursor/rules/specrew-update/SKILL.md | 2 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .cursor/rules/specrew-user-profile/SKILL.md | 179 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/agents/speckit.specify.agent.md | 9 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/agents/squad.agent.md | 55 | 29 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/copilot-instructions.md | 50 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/skills/specrew-code-rules/.specrew-managed | 4 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/skills/specrew-code-rules/SKILL.md | 93 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/skills/specrew-design-workshop/SKILL.md | 85 | 35 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/skills/specrew-drift-check/SKILL.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/skills/specrew-local-build/SKILL.md | 119 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/skills/specrew-refocus/SKILL.md | 2 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/skills/specrew-review/SKILL.md | 2 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/skills/specrew-update/SKILL.md | 2 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/workflows/publish-module.yml | 35 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/workflows/specrew-ci.yml | 17 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .github/workflows/test.yml | 1 | 1 | T005, T008 | Implementer |
| .gitignore | 10 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/.specrew-extension-runtime.json | 659 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-clarify.md | 1 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-feature-closeout.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-iteration-closeout.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-plan.md | 1 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-retro.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-review-signoff.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md | 2 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-tasks.md | 1 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/data/self-leak-deny-list.json | 6 | 12 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/knowledge/design-lenses/README.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md | 13 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml | 9 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/knowledge/design-lenses/product-domain.md | 11 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/refocus/before-implement.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/refocus/general.md | 1 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/refocus/implement.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/refocus/review-signoff.md | 9 | 8 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/refocus/specify.md | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/brownfield-merge.ps1 | 4 | 4 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/collision-detect.ps1 | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1 | 257 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/conformance-turn-delta.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/create-governed-feature.ps1 | 122 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1 | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1 | 21 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 108 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/initialize-workshop-controller-state.ps1 | 19 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/intake/helpers/Detect-RepoStack.ps1 | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/intake/helpers/Read-IntakeYaml.ps1 | 18 | 17 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/manage-escalation-state.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1 | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/provider-adapter.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/refocus.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1 | 286 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/resolve-quality-profile.ps1 | 35 | 35 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/run-hardening-gate.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 | 18 | 12 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-governance.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1 | 27 | 11 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-retro-artifact.ps1 | 40 | 10 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-review-artifact.ps1 | 37 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 131 | 29 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 | 1498 | 12 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1 | 73 | 13 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 | 699 | 28 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-handover-provider.ps1 | 4 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 112 | 20 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 10 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/test-consumer-assumptions.ps1 | 1 | 0 | T005, T008 | Implementer |
| .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 | 599 | 26 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1 | 533 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/directives/drift-reporting.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/skills/design-workshop.md | 85 | 35 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/skills/drift-check.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/skills/gate-stop.md | 27 | 8 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/squad-templates/skills/specrew-update/SKILL.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specify/extensions/specrew-speckit/validators/handoff-governance-validator.ps1 | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/config.yml | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/release-gate-suites.txt | 354 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/review/contracts/findings-result.schema.json | 64 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/review/contracts/gate-verdict.schema.json | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/review/contracts/infrastructure-failure.schema.json | 37 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/review/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/review/contracts/review-request.schema.json | 133 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/review/contracts/review-thread.schema.json | 37 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/review/contracts/reviewer-spawn-contract.md | 47 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/review/contracts/spawn-invocation.schema.json | 31 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/review/signoff-gate/latest.json | 23 | 11 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/reviewer-hosts.json | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .specrew/verification-plan.json | 108 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .squad/active-features.yml | 5 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .squad/agents/implementer/charter.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .squad/agents/reviewer/charter.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .squad/casting/registry.json | 5 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .squad/decisions.md | 171 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .squad/events/lifecycle-events.jsonl | 9 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| .squad/identity/now.md | 7 | 7 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| AGENTS.md | 49 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| CLAUDE.md | 49 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| Specrew.psd1 | 20 | 4 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| Specrew.psm1 | 49 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| docs/getting-started.md | 14 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| docs/methodology/self-leak-firewall.md | 24 | 6 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| docs/release-notes-v0.40.0-beta3.md | 212 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-clarify.md | 1 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-feature-closeout.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-iteration-closeout.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-plan.md | 1 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-retro.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-review-signoff.md | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md | 2 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-tasks.md | 1 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/data/self-leak-deny-list.json | 6 | 12 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md | 13 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml | 9 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/knowledge/design-lenses/product-domain.md | 11 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/refocus/before-implement.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/refocus/general.md | 1 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/refocus/implement.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/refocus/review-signoff.md | 8 | 7 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/refocus/specify.md | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/brownfield-merge.ps1 | 4 | 4 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/collision-detect.ps1 | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1 | 257 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/conformance-turn-delta.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/create-governed-feature.ps1 | 122 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1 | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1 | 21 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/initialize-workshop-controller-state.ps1 | 19 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/intake/helpers/Detect-RepoStack.ps1 | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/intake/helpers/Read-IntakeYaml.ps1 | 18 | 17 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/manage-escalation-state.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1 | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/provider-adapter.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/refocus.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1 | 286 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/resolve-quality-profile.ps1 | 35 | 35 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/run-hardening-gate.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 | 18 | 12 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-governance.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1 | 27 | 11 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-retro-artifact.ps1 | 40 | 10 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-review-artifact.ps1 | 37 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 131 | 29 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/shared-governance.ps1 | 1498 | 12 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1 | 73 | 13 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 | 699 | 28 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/specrew-handover-provider.ps1 | 4 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | 112 | 20 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/sync-boundary-state.ps1 | 10 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/test-consumer-assumptions.ps1 | 1 | 0 | T005, T008 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 599 | 26 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/scripts/workshop-authority-store.ps1 | 533 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/squad-templates/directives/drift-reporting.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/design-workshop.md | 85 | 35 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/drift-check.md | 2 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/squad-templates/skills/gate-stop.md | 27 | 8 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| extensions/specrew-speckit/validators/handoff-governance-validator.ps1 | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| hosts/_contract.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| hosts/claude/host.psd1 | 3 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/decisions-split.ps1 | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/init/post-bootstrap-output.ps1 | 7 | 7 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/init/spec-kit-deploy.ps1 | 15 | 1 | T005, T008 | Implementer |
| scripts/internal/bootstrap/ConversationCaptureAccessor.ps1 | 273 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/bootstrap/HandoverStore.ps1 | 244 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/bootstrap/HumanAuthorityStore.ps1 | 1825 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/bootstrap/ProjectMetadataAccessor.ps1 | 183 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/.specrew-runtime.json | 252 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/_load.ps1 | 6 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1 | 7 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1 | 461 | 11 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/hook-health-receipt.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/host-support-doctor.ps1 | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/host-support-tier.ps1 | 4 | 4 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/reparse-tag-policy.ps1 | 192 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/review-authority-core.ps1 | 495 | 6 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/review-authority-store.ps1 | 204 | 7 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1 | 955 | 16 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/review-design-context.ps1 | 48 | 6 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/review-identity-contracts.ps1 | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/review-result-ingestor.ps1 | 232 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/review-run-index-writer.ps1 | 29 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1 | 661 | 24 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/reviewed-state-digest.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/reviewer-candidate-prompt.md | 9 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/reviewer-host-catalog.ps1 | 9 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/signoff-gate-wiring.ps1 | 43 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/test-evidence-recorder.ps1 | 6 | 6 | T005, T008 | Implementer |
| scripts/internal/continuous-co-review/verification-plan-contract.ps1 | 2 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/verification-plan-materializer.ps1 | 162 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/verification-plan-runner.ps1 | 89 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/verification-plan-supplier.ps1 | 4 | 4 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/worktree-navigator.ps1 | 209 | 20 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1 | 11 | 4 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/continuous-co-review/worktree-reviewer.ps1 | 49 | 9 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/coordinator-prompt-surgery.ps1 | 6 | 6 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/dashboard-renderer.ps1 | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/deploy-refocus-hooks.ps1 | 21 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/design-analysis-gate.ps1 | 159 | 18 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/detect-hosts.ps1 | 5 | 4 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/file-classification.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/gate-preflight.ps1 | 222 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/install-local-build.ps1 | 178 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/invoke-module-release.ps1 | 8 | 235 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/launch-contract.ps1 | 26 | 10 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/lint-self-leak.ps1 | 44 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/module-packaging.ps1 | 356 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/refocus.ps1 | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/review-engine-resolution.ps1 | 63 | 14 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/specrew-bootstrap-provider.ps1 | 73 | 13 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/specrew-consumer-language.ps1 | 119 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/specrew-handover-provider.ps1 | 4 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/specrew-hook-dispatcher.ps1 | 112 | 20 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/specrew-hook-health.ps1 | 103 | 10 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/sync-boundary-state.ps1 | 280 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/task-progress.ps1 | 13 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/test-publish-harness.ps1 | 2 | 2 | T005, T008 | Implementer |
| scripts/internal/user-profile.ps1 | 43 | 43 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/internal/version-check.ps1 | 28 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/specrew-gate-preflight.ps1 | 19 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/specrew-hooks-doctor.ps1 | 3 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/specrew-init.ps1 | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/specrew-install-shell-wrappers.ps1 | 6 | 6 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/specrew-review.ps1 | 1073 | 16 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/specrew-start.ps1 | 5 | 6 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/specrew.ps1 | 10 | 2 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/t060-local-macos-smoke.ps1 | 5 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| scripts/t060-local-platform-smoke.ps1 | 5 | 5 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/185-host-neutral-gate-enforcement/CONTINUATION.md | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/contracts/beta3-stabilization.md | 89 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/data-model.md | 81 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/gates/design-analysis-001.md | 46 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/design-analysis.md | 1113 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/drift-log.md | 8196 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/lens-applicability.json | 4 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/plan.md | 119 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/quality/beta3-walk-findings-mitigation.md | 54 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/quality/claude-deep-review-mitigation.md | 99 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/quality/hardening-gate.md | 50 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/quality/mechanical-findings.json | 11 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/quality/quality-evidence.md | 17 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/quality/walk4-fd2ef095-remediation-brief.md | 84 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/review.md | 101 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/state.md | 53 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/iterations/001/tasks-progress.yml | 83 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/plan.md | 105 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/quickstart.md | 56 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/review-diagrams.md | 74 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| specs/199-beta3-stabilization/spec.md | 107 | 29 | T005, T008 | Implementer |
| specs/199-beta3-stabilization/tasks.md | 163 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| templates/coordinator-instructions.md | 45 | 3 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| templates/github/workflows/specrew-methodology-gate.yml | 1 | 1 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| templates/squad/agents/implementer/history.md | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| templates/squad/agents/planner/history.md | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| templates/squad/agents/retro-facilitator/history.md | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| templates/squad/agents/reviewer/charter.md | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| templates/squad/agents/reviewer/history.md | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| templates/squad/agents/scribe/history.md | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| templates/squad/agents/spec-steward/history.md | 1 | 0 | T001, T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T013 | Implementer |
| tests/bootstrap/BannerPrereleaseVersion.Tests.ps1 | 94 | 0 | T005, T008 | Implementer |
| tests/bootstrap/BootstrapProvider.Tests.ps1 | 5 | 1 | T005, T008 | Implementer |
| tests/bootstrap/ConversationCapture.Tests.ps1 | 141 | 0 | T005, T008 | Implementer |
| tests/bootstrap/CoordinatorFrontLoad.Tests.ps1 | 15 | 14 | T005, T008 | Implementer |
| tests/bootstrap/DeployedHostConfig.Tests.ps1 | 18 | 4 | T005, T008 | Implementer |
| tests/bootstrap/DirectiveDeliveryCap.Tests.ps1 | 3 | 3 | T005, T008 | Implementer |
| tests/bootstrap/DispatcherSessionStartPolicy.Tests.ps1 | 2 | 2 | T005, T008 | Implementer |
| tests/bootstrap/DispatcherTranscriptDelivery.Tests.ps1 | 26 | 1 | T005, T008 | Implementer |
| tests/bootstrap/HookCommandCwdResolution.Tests.ps1 | 10 | 9 | T005, T008 | Implementer |
| tests/bootstrap/HostDeliveryPolicy.Tests.ps1 | 4 | 4 | T005, T008 | Implementer |
| tests/bootstrap/ProjectMetadataAccessor.Tests.ps1 | 39 | 1 | T005, T008 | Implementer |
| tests/continuous-co-review/governance/protected-surface-guard.Tests.ps1 | 5 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/integration/escalation-latch-wiring.Tests.ps1 | 10 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/integration/signoff-gate-digest-promotion.Tests.ps1 | 6 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/integration/signoff-gate-digest-threading.Tests.ps1 | 6 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/advisory-names-the-humans-act.Tests.ps1 | 359 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/authority-control-consumer-guard.Tests.ps1 | 121 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/baseline-provenance-fact.Tests.ps1 | 121 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/campaign-activation-implementation-premise.Tests.ps1 | 157 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/campaign-default-run-id-mint.Tests.ps1 | 74 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/campaign-pause-core.Tests.ps1 | 505 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/campaign-pause-wiring.Tests.ps1 | 838 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/campaign-stop-authority.Tests.ps1 | 440 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/campaign-stop-here-landing.Tests.ps1 | 201 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/campaign-stop-here-real-ports.Tests.ps1 | 200 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/campaign-two-governor-adjudication.Tests.ps1 | 125 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/checkpoint-diff-provider.Tests.ps1 | 15 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/clean-review-can-be-signed-off.Tests.ps1 | 177 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/consumer-language.Tests.ps1 | 385 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1 | 90 | 5 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/copilot-cli-contract.Tests.ps1 | 15 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/flush-race-forensic.Tests.ps1 | 34 | 4 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/host-support-tier.Tests.ps1 | 15 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/human-authority-store.Tests.ps1 | 69 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/inline-review-gate-evaluator.Tests.ps1 | 15 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/inline-reviewer-containment.Tests.ps1 | 11 | 4 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/non-convergence-escalation.Tests.ps1 | 17 | 2 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/partial-more-time-note.Tests.ps1 | 6 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/path-identity.Tests.ps1 | 37 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/records-only-covers-what-deployment-writes.Tests.ps1 | 139 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/records-only-delta-survives-its-own-round.Tests.ps1 | 89 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/refusal-names-a-reachable-action.Tests.ps1 | 153 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/reparse-admission-premise.Tests.ps1 | 194 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/reparse-tag-policy.Tests.ps1 | 394 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-authority-store-mutation-gate.Tests.ps1 | 7 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-blackboard-writer.Tests.ps1 | 15 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-boundary-campaign-evidence.Tests.ps1 | 126 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-derived-independence.Tests.ps1 | 417 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-examined-coverage.Tests.ps1 | 164 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-frame-and-evidence-honesty.Tests.ps1 | 569 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-public-campaign-command.Tests.ps1 | 53 | 12 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-record-authorship.Tests.ps1 | 246 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-result-ingestor.Tests.ps1 | 15 | 2 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-signoff-evidence-gate.Tests.ps1 | 80 | 68 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-spend-allowance.Tests.ps1 | 313 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/review-window-codex-default.Tests.ps1 | 120 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/reviewer-host-catalog.Tests.ps1 | 15 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/reviewer-host-grant-write-scope.Tests.ps1 | 28 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/reviewer-independence-fallback.Tests.ps1 | 7 | 1 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/reviewer-prompt-contract.Tests.ps1 | 184 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/signoff-gate-wiring.Tests.ps1 | 81 | 21 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/signoff-override-survives-its-own-preflight.Tests.ps1 | 133 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/t060-local-platform-smoke.Tests.ps1 | 7 | 1 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/verification-plan-materializer.Tests.ps1 | 128 | 0 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/verification-plan-runner.Tests.ps1 | 129 | 3 | T005, T008 | Implementer |
| tests/continuous-co-review/unit/worktree-reviewer-machinery-paths.Tests.ps1 | 24 | 1 | T005, T008 | Implementer |
| tests/f198-regression-suite.ps1 | 52 | 9 | T005, T008 | Implementer |
| tests/full-powershell-test-sweep.ps1 | 195 | 0 | T005, T008 | Implementer |
| tests/integration/approve-round-decision.Tests.ps1 | 194 | 0 | T005, T008 | Implementer |
| tests/integration/baseline-hygiene.tests.ps1 | 61 | 9 | T005, T008 | Implementer |
| tests/integration/bootstrap-resolver-guard.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/integration/cap-exhaustion-is-documented.tests.ps1 | 138 | 0 | T005, T008 | Implementer |
| tests/integration/ci-registry-lane-tooling.Tests.ps1 | 84 | 0 | T005, T008 | Implementer |
| tests/integration/closed-iterations-are-history.tests.ps1 | 164 | 0 | T005, T008 | Implementer |
| tests/integration/closeout-lifecycle-sync-commands.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/integration/conformance-detection.tests.ps1 | 196 | 17 | T005, T008 | Implementer |
| tests/integration/continuous-co-review-update-resync.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/integration/contract-parity-side-by-side.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/integration/coordinator-guard-precision.tests.ps1 | 8 | 6 | T005, T008 | Implementer |
| tests/integration/deploy-extension-missing-source-tolerance.tests.ps1 | 4 | 0 | T005, T008 | Implementer |
| tests/integration/deployed-extension-marker-on-update.tests.ps1 | 142 | 0 | T005, T008 | Implementer |
| tests/integration/design-workshop-claude-tool-safety.tests.ps1 | 4 | 1 | T005, T008 | Implementer |
| tests/integration/dispatcher-stop-block.tests.ps1 | 18 | 0 | T005, T008 | Implementer |
| tests/integration/distribution-module-publish.ps1 | 30 | 5 | T005, T008 | Implementer |
| tests/integration/extension-registration-format.tests.ps1 | 2 | 1 | T005, T008 | Implementer |
| tests/integration/gate-stop-skill.tests.ps1 | 17 | 3 | T005, T008 | Implementer |
| tests/integration/governed-feature-workshop-controller.tests.ps1 | 78 | 0 | T005, T008 | Implementer |
| tests/integration/hooks-reconcile.Tests.ps1 | 132 | 0 | T005, T008 | Implementer |
| tests/integration/host-detection-ux.tests.ps1 | 18 | 0 | T005, T008 | Implementer |
| tests/integration/init-verification-plan.Tests.ps1 | 123 | 0 | T005, T008 | Implementer |
| tests/integration/instruction-deploy.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/integration/launch-mode-boundary-enforcement.tests.ps1 | 2 | 2 | T005, T008 | Implementer |
| tests/integration/lifecycle-boundary-sync.tests.ps1 | 22 | 0 | T005, T008 | Implementer |
| tests/integration/multi-host-launch-path.tests.ps1 | 35 | 13 | T005, T008 | Implementer |
| tests/integration/multi-host-lifecycle-smoke.tests.ps1 | 6 | 4 | T005, T008 | Implementer |
| tests/integration/no-code-without-approval.tests.ps1 | 257 | 0 | T005, T008 | Implementer |
| tests/integration/non-specrew-session-bypass.tests.ps1 | 4 | 5 | T005, T008 | Implementer |
| tests/integration/packaged-artifact-deploy.Tests.ps1 | 14 | 0 | T005, T008 | Implementer |
| tests/integration/post-bootstrap-output.tests.ps1 | 31 | 0 | T005, T008 | Implementer |
| tests/integration/pr-review-integration.tests.ps1 | 24 | 30 | T005, T008 | Implementer |
| tests/integration/product-domain-multihost.tests.ps1 | 4 | 3 | T005, T008 | Implementer |
| tests/integration/prose-alias-sync.tests.ps1 | 24 | 0 | T005, T008 | Implementer |
| tests/integration/psgallery-check.tests.ps1 | 11 | 5 | T005, T008 | Implementer |
| tests/integration/refocus-channels.tests.ps1 | 7 | 5 | T005, T008 | Implementer |
| tests/integration/refocus-deploy.tests.ps1 | 44 | 8 | T005, T008 | Implementer |
| tests/integration/review-evidence-integrity.tests.ps1 | 62 | 3 | T005, T008 | Implementer |
| tests/integration/review-record-survives-its-own-commit.tests.ps1 | 307 | 0 | T005, T008 | Implementer |
| tests/integration/session-orientation-rendered.tests.ps1 | 139 | 0 | T005, T008 | Implementer |
| tests/integration/shipped-orchestration-arrival.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/integration/slash-command-coexistence.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/integration/slash-command-compatibility.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/integration/specify-workshop-routing.tests.ps1 | 70 | 2 | T005, T008 | Implementer |
| tests/integration/specrew-start-auto-continue-preservation.ps1 | 2 | 2 | T005, T008 | Implementer |
| tests/integration/stale-state-detection.tests.ps1 | 6 | 0 | T005, T008 | Implementer |
| tests/integration/stale-state-retro.tests.ps1 | 6 | 0 | T005, T008 | Implementer |
| tests/integration/start-recovery-flow.tests.ps1 | 9 | 1 | T005, T008 | Implementer |
| tests/integration/stopblock-deployed-binding.tests.ps1 | 7 | 1 | T005, T008 | Implementer |
| tests/integration/tier2-dry-run-ci.tests.ps1 | 10 | 0 | T005, T008 | Implementer |
| tests/integration/validate-governance-changed-only.tests.ps1 | 39 | 10 | T005, T008 | Implementer |
| tests/integration/verdict-capture-blocks.tests.ps1 | 159 | 4 | T005, T008 | Implementer |
| tests/integration/version-info-states.tests.ps1 | 17 | 0 | T005, T008 | Implementer |
| tests/integration/workshop-agenda-confirmation.tests.ps1 | 313 | 0 | T005, T008 | Implementer |
| tests/integration/workshop-controller-initialization.tests.ps1 | 4 | 1 | T005, T008 | Implementer |
| tests/integration/workshop-material-packet-language.tests.ps1 | 209 | 0 | T005, T008 | Implementer |
| tests/integration/workshop-state-transition-table.tests.ps1 | 181 | 0 | T005, T008 | Implementer |
| tests/integration/workshop-typed-turn-authority.tests.ps1 | 137 | 0 | T005, T008 | Implementer |
| tests/manual/multi-host-smoke.ps1 | 5 | 5 | T005, T008 | Implementer |
| tests/manual/review-production-harness-dry-run.ps1 | 102 | 0 | T005, T008 | Implementer |
| tests/unit/authorization-ref-not-the-advice.tests.ps1 | 95 | 0 | T005, T008 | Implementer |
| tests/unit/banner-ids-are-glossed.tests.ps1 | 108 | 0 | T005, T008 | Implementer |
| tests/unit/boundary-correction-ledger.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/unit/boundary-ratchet.tests.ps1 | 36 | 2 | T005, T008 | Implementer |
| tests/unit/budget-resolution.tests.ps1 | 1 | 1 | T005, T008 | Implementer |
| tests/unit/constraint-change-visibility.Tests.ps1 | 104 | 0 | T005, T008 | Implementer |
| tests/unit/coverage-is-a-decision.tests.ps1 | 228 | 0 | T005, T008 | Implementer |
| tests/unit/deployed-extension-integrity.tests.ps1 | 129 | 0 | T005, T008 | Implementer |
| tests/unit/design-analysis-gate.tests.ps1 | 6 | 1 | T005, T008 | Implementer |
| tests/unit/design-gate-code-implementation-artifact.tests.ps1 | 46 | 5 | T005, T008 | Implementer |
| tests/unit/design-gate-runtime-hardening.tests.ps1 | 5 | 2 | T005, T008 | Implementer |
| tests/unit/drift-class-closure.Tests.ps1 | 55 | 0 | T005, T008 | Implementer |
| tests/unit/every-suite-is-named-by-a-lane.tests.ps1 | 102 | 0 | T005, T008 | Implementer |
| tests/unit/feature-018-dashboard.tests.ps1 | 12 | 0 | T005, T008 | Implementer |
| tests/unit/full-sweep-direct-exit.tests.ps1 | 52 | 0 | T005, T008 | Implementer |
| tests/unit/gate-preflight.Tests.ps1 | 92 | 0 | T005, T008 | Implementer |
| tests/unit/instruction-file-merge.tests.ps1 | 3 | 3 | T005, T008 | Implementer |
| tests/unit/lens-conduct-delivery.tests.ps1 | 20 | 4 | T005, T008 | Implementer |
| tests/unit/maintainer-skill-host-parity.tests.ps1 | 138 | 0 | T005, T008 | Implementer |
| tests/unit/module-packaging-identity.tests.ps1 | 221 | 0 | T005, T008 | Implementer |
| tests/unit/module-wrapper-windows-drive-equals.tests.ps1 | 47 | 0 | T005, T008 | Implementer |
| tests/unit/no-automatic-variable-collisions.tests.ps1 | 96 | 0 | T005, T008 | Implementer |
| tests/unit/no-internal-ids-in-emitted-strings.tests.ps1 | 143 | 0 | T005, T008 | Implementer |
| tests/unit/pause-choice-carries-round-approval.tests.ps1 | 121 | 0 | T005, T008 | Implementer |
| tests/unit/pretag-slice4-capture-containment.tests.ps1 | 7 | 0 | T005, T008 | Implementer |
| tests/unit/regression-harness-isolation.tests.ps1 | 45 | 3 | T005, T008 | Implementer |
| tests/unit/review-approve-round-host-resolution.tests.ps1 | 120 | 0 | T005, T008 | Implementer |
| tests/unit/review-engine-resolution.tests.ps1 | 16 | 0 | T005, T008 | Implementer |
| tests/unit/review-flag-whitelist-parity.tests.ps1 | 101 | 0 | T005, T008 | Implementer |
| tests/unit/reviewer-closeout-artifacts-generate.tests.ps1 | 103 | 0 | T005, T008 | Implementer |
| tests/unit/round-approval-typed-authority.tests.ps1 | 2578 | 0 | T005, T008 | Implementer |
| tests/unit/scaffold-migration-and-pending.tests.ps1 | 158 | 0 | T005, T008 | Implementer |
| tests/unit/scaffold-writes-once.tests.ps1 | 110 | 0 | T005, T008 | Implementer |
| tests/unit/self-leak-lint.tests.ps1 | 25 | 2 | T005, T008 | Implementer |
| tests/unit/session-orientation-obligation.tests.ps1 | 102 | 0 | T005, T008 | Implementer |
| tests/unit/slash-command-arg-whitelist.tests.ps1 | 22 | 4 | T005, T008 | Implementer |
| tests/unit/spec-kit-preflight-path.Tests.ps1 | 30 | 0 | T005, T008 | Implementer |
| tests/unit/task-progress-no-demotion.tests.ps1 | 106 | 0 | T005, T008 | Implementer |
| tests/unit/workshop-refusal-contract.tests.ps1 | 59 | 0 | T005, T008 | Implementer |

## Public-API Delta

### Added

- Write-AtomicUtf8NoBom (.specify/extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1)
- New-SpecrewWorkshopAgendaRefusal (.specify/extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1)
- Get-CanonicalWorkshopAgendaText (.specify/extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1)
- Resolve-ProjectRoot (.specify/extensions/specrew-speckit/scripts/create-governed-feature.ps1)
- Invoke-FeatureScaffold (.specify/extensions/specrew-speckit/scripts/create-governed-feature.ps1)
- Get-ScaffoldRecord (.specify/extensions/specrew-speckit/scripts/create-governed-feature.ps1)
- Remove-RetiredManagedRuntimeFiles (.specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1)
- Write-AtomicUtf8NoBom (.specify/extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1)
- Get-Sha256ForBytes (.specify/extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1)
- Get-FileSha256 (.specify/extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1)
- Get-CanonicalPendingState (.specify/extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1)
- Initialize-SpecrewPreexistingArtifacts (.specify/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Test-SpecrewFileExistedBeforeThisRun (.specify/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Select-SpecrewProductSourcePaths (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewUnauthorizedSourceDrift (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCampaignId (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCampaignEvidenceState (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewDeployedExtensionMarkerPath (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewDeployedExtensionManifest (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewDeployedExtensionMarker (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewDeployedExtensionIntegrity (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewAuthorshipPath (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewReviewAuthorshipSourcePath (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewRecordPathMatch (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewReviewAuthorshipObservation (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewAuthorship (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewDerivedCoverageSourcePath (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCoverageState (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCoverageLine (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewCoverageAuthorityHash (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewCoverageDeferralRoot (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewCoverageDeferralPhrase (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewCoverageDeferralAuthorization (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewCoverageDeferralAuthorization (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewCoverageDeferralCurrent (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewIterationSealPath (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewIterationSealManifest (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewIterationSeal (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewIterationSealIntegrity (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Resolve-SpecrewActiveFeatureRef (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewLifecycleExecutionRecordPath (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewedTreeSourceDrift (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCurrentTreeId (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewRunCoversCurrentSource (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewRunCandidates (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewQualifyingIndependentRun (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewDerivedIndependenceBlock (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewEmbeddedIndependenceBlock (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewCapFactPath (.specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1)
- Test-SpecrewCapFactRecorded (.specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1)
- Write-SpecrewCapFact (.specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1)
- Test-SpecrewUntouchedFeatureSpecScaffold (.specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1)
- Get-DispatcherHookOutputHash (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Write-DispatcherHookOutputAuthorityRecord (.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Test-DriftLogClassClosure (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReviewDerivedIndependenceBlock (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ClosedIterationSeals (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-DeployedExtensionIntegrity (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ScaffoldPendingSiblings (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReviewRecordAuthorship (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReviewCitedRunEvidence (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-SourceWithoutImplementAuthorization (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-SpecrewWorkshopAuthorityReceiptPath (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopResponseAuthority (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopAuthorityHash (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopRepairProposalPath (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopRepairAuthorityPath (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopFileSha256 (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Resolve-SpecrewWorkshopStateTransition (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopRepairAuthorization (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Write-SpecrewWorkshopRepairAuthorization (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopRefusalContractText (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- ConvertTo-SpecrewWorkshopAgendaBinding (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopAgendaDigest (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopAgendaChangedLenses (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Test-SpecrewWorkshopAgendaVisibleInText (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- ConvertTo-SpecrewWorkshopSourceEvent (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Test-SpecrewWorkshopHumanResponseText (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Test-SpecrewWorkshopResponseIsHookOutput (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Write-SpecrewWorkshopAuthorityReceipt (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopAuthorityReceipt (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Test-SpecrewWorkshopAuthorityReceipt (.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewReviewCampaignEvidenceState (Specrew.psm1)
- Write-AtomicUtf8NoBom (extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1)
- New-SpecrewWorkshopAgendaRefusal (extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1)
- Get-CanonicalWorkshopAgendaText (extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1)
- Resolve-ProjectRoot (extensions/specrew-speckit/scripts/create-governed-feature.ps1)
- Invoke-FeatureScaffold (extensions/specrew-speckit/scripts/create-governed-feature.ps1)
- Get-ScaffoldRecord (extensions/specrew-speckit/scripts/create-governed-feature.ps1)
- Write-AtomicUtf8NoBom (extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1)
- Get-Sha256ForBytes (extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1)
- Get-FileSha256 (extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1)
- Get-CanonicalPendingState (extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1)
- Initialize-SpecrewPreexistingArtifacts (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Test-SpecrewFileExistedBeforeThisRun (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Select-SpecrewProductSourcePaths (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewUnauthorizedSourceDrift (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCampaignId (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCampaignEvidenceState (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewDeployedExtensionMarkerPath (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewDeployedExtensionManifest (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewDeployedExtensionMarker (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewDeployedExtensionIntegrity (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewAuthorshipPath (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewReviewAuthorshipSourcePath (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewRecordPathMatch (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewReviewAuthorshipObservation (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewAuthorship (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewDerivedCoverageSourcePath (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCoverageState (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCoverageLine (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewCoverageAuthorityHash (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewCoverageDeferralRoot (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewCoverageDeferralPhrase (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewCoverageDeferralAuthorization (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewCoverageDeferralAuthorization (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewCoverageDeferralCurrent (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewIterationSealPath (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewIterationSealManifest (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-SpecrewIterationSeal (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewIterationSealIntegrity (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Resolve-SpecrewActiveFeatureRef (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-SpecrewLifecycleExecutionRecordPath (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewedTreeSourceDrift (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewCurrentTreeId (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewRunCoversCurrentSource (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewReviewRunCandidates (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewQualifyingIndependentRun (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewDerivedIndependenceBlock (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewEmbeddedIndependenceBlock (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-SpecrewCapFactPath (extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1)
- Test-SpecrewCapFactRecorded (extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1)
- Write-SpecrewCapFact (extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1)
- Test-SpecrewUntouchedFeatureSpecScaffold (extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1)
- Get-DispatcherHookOutputHash (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Write-DispatcherHookOutputAuthorityRecord (extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1)
- Test-DriftLogClassClosure (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReviewDerivedIndependenceBlock (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ClosedIterationSeals (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-DeployedExtensionIntegrity (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ScaffoldPendingSiblings (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReviewRecordAuthorship (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReviewCitedRunEvidence (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-SourceWithoutImplementAuthorization (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-SpecrewWorkshopAuthorityReceiptPath (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopResponseAuthority (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopAuthorityHash (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopRepairProposalPath (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopRepairAuthorityPath (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopFileSha256 (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Resolve-SpecrewWorkshopStateTransition (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopRepairAuthorization (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Write-SpecrewWorkshopRepairAuthorization (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopRefusalContractText (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- ConvertTo-SpecrewWorkshopAgendaBinding (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopAgendaDigest (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopAgendaChangedLenses (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Test-SpecrewWorkshopAgendaVisibleInText (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- ConvertTo-SpecrewWorkshopSourceEvent (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Test-SpecrewWorkshopHumanResponseText (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Test-SpecrewWorkshopResponseIsHookOutput (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Write-SpecrewWorkshopAuthorityReceipt (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewWorkshopAuthorityReceipt (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Test-SpecrewWorkshopAuthorityReceipt (extensions/specrew-speckit/scripts/workshop-authority-store.ps1)
- Get-SpecrewConditionalConjunctionPattern (scripts/internal/bootstrap/ConversationCaptureAccessor.ps1)
- Test-SpecrewConditionalDeferralClause (scripts/internal/bootstrap/ConversationCaptureAccessor.ps1)
- Get-SpecrewPromptEntryBoundaryVerdict (scripts/internal/bootstrap/ConversationCaptureAccessor.ps1)
- Invoke-SpecrewTypedAuthorityCapture (scripts/internal/bootstrap/HandoverStore.ps1)
- Get-SpecrewReviewSignoffOverrideRoot (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewHumanAuthorityHash (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- ConvertTo-SpecrewHumanAuthoritySourceEvent (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewReviewSignoffOverrideRequest (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Read-SpecrewReviewSignoffOverrideRequest (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewReviewSignoffOverrideAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewReviewSignoffOverrideAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewAuthorityApprovalLine (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewReviewRoundApprovalRoot (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewQuestionUiObservationPath (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewQuestionUiPhraseObservation (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewQuestionUiPhraseObservation (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Clear-SpecrewQuestionUiPhraseObservation (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewAgentSessionSignalNames (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Test-SpecrewInsideAgentSession (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Test-SpecrewReviewRoundApprovalPhrase (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewReviewRoundApprovalAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewAuthorityFlagPhraseMap (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewNonAuthorityFlagExemptions (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewTypedTurnIdentity (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewExhaustedTurnLedgerPath (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Test-SpecrewTypedTurnExhausted (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewCrossChannelMint (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewCrossChannelMintObservation (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewAuthorityLedgerDamageObservation (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Register-SpecrewExhaustedTurn (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewReviewRoundApprovalAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Test-SpecrewApprovalIsWithdrawn (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- ConvertTo-SpecrewAuthorityInstant (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewPauseDecisionRoot (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewPendingPauseIdentity (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Test-SpecrewPauseDecisionPhrase (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewPauseDecisionAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewPauseDecisionAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Complete-SpecrewPauseDecisionAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Set-SpecrewReviewRoundApprovalMintedRef (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewDeliveredRoundForMintedRef (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewDeliveredRoundForCapture (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewUnconsumedDeliveryPath (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewUnconsumedDeliveryFact (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewUnconsumedDeliveryFact (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Clear-SpecrewUnconsumedDeliveryFact (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Test-SpecrewApprovalWithdrawalPhrase (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewApprovalWithdrawal (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Complete-SpecrewReviewRoundApprovalAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Resolve-SpecrewRoundEntitlementOutcome (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewRoundDeliveryJournal (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewAllowanceResetRoot (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Test-SpecrewAllowanceResetPhrase (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Write-SpecrewAllowanceResetAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewAllowanceResetAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Complete-SpecrewAllowanceResetAuthorization (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-SpecrewLandedResetForAllowanceCapture (scripts/internal/bootstrap/HumanAuthorityStore.ps1)
- Get-ReviewCampaignFindingMixLines (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1)
- Format-ReviewCampaignOutstandingPause (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1)
- Format-ReviewCampaignPauseSurface (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1)
- Get-ReviewCampaignRouteSentence (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1)
- Build-ContinuousCoReviewNavigatorAgentDirective (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1)
- Get-ReviewCampaignActionSentence (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1)
- Build-ReviewCampaignNavigatorAgentDirective (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1)
- Get-ReviewCampaignCrossingField (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1)
- Resolve-SpecrewReparseDisposition (scripts/internal/continuous-co-review/reparse-tag-policy.ps1)
- Test-SpecrewReparseRefusesRead (scripts/internal/continuous-co-review/reparse-tag-policy.ps1)
- Get-SpecrewReparseDispositionForItem (scripts/internal/continuous-co-review/reparse-tag-policy.ps1)
- Get-SpecrewReparseTagDisposition (scripts/internal/continuous-co-review/reparse-tag-policy.ps1)
- Get-SpecrewReparseRefusalMessage (scripts/internal/continuous-co-review/reparse-tag-policy.ps1)
- ConvertTo-ReviewAuthorityTimestamp (scripts/internal/continuous-co-review/review-authority-core.ps1)
- Resolve-ReviewCampaignPauseDecision (scripts/internal/continuous-co-review/review-authority-core.ps1)
- Test-ReviewCampaignPendingPauseQuiet (scripts/internal/continuous-co-review/review-authority-core.ps1)
- New-ReviewCampaignPendingPauseFact (scripts/internal/continuous-co-review/review-authority-core.ps1)
- New-ReviewCampaignBudgetResetFact (scripts/internal/continuous-co-review/review-authority-core.ps1)
- New-ReviewCampaignPauseDecisionFact (scripts/internal/continuous-co-review/review-authority-core.ps1)
- Test-ReviewCampaignContinuationAuthorized (scripts/internal/continuous-co-review/review-authority-core.ps1)
- Test-ReviewAuthorityExaminedPathsField (scripts/internal/continuous-co-review/review-authority-core.ps1)
- Test-ReviewAuthorityFactPathContained (scripts/internal/continuous-co-review/review-authority-store.ps1)
- Write-ReviewCampaignPendingPauseFact (scripts/internal/continuous-co-review/review-authority-store.ps1)
- Write-ReviewCampaignPauseDecisionFact (scripts/internal/continuous-co-review/review-authority-store.ps1)
- Write-ReviewCampaignBudgetResetFact (scripts/internal/continuous-co-review/review-authority-store.ps1)
- Get-ReviewCampaignLatestBudgetReset (scripts/internal/continuous-co-review/review-authority-store.ps1)
- Get-ReviewCampaignPauseRecords (scripts/internal/continuous-co-review/review-authority-store.ps1)
- Get-ReviewCampaignPendingPause (scripts/internal/continuous-co-review/review-authority-store.ps1)
- Get-ReviewCampaignLatestPause (scripts/internal/continuous-co-review/review-authority-store.ps1)
- Get-ReviewCampaignRoundBudgetTotal (scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1)
- Get-ReviewCampaignRoundBudgetState (scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1)
- New-ReviewCampaignAuthorityStoreRefusal (scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1)
- Add-ReviewCampaignRoundPause (scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1)
- Invoke-ReviewCampaignStopHereLanding (scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1)
- Test-ReviewFindingStatesFailureScenario (scripts/internal/continuous-co-review/review-result-ingestor.ps1)
- Resolve-ReviewFindingGatingEligibility (scripts/internal/continuous-co-review/review-result-ingestor.ps1)
- Test-ReviewExaminedPathIsSource (scripts/internal/continuous-co-review/review-result-ingestor.ps1)
- Resolve-ReviewDeclaredCoverage (scripts/internal/continuous-co-review/review-result-ingestor.ps1)
- Get-SpecrewCarriedSignoffOverrideAuthorization (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Test-ReviewCampaignDeltaIsRecordsOnly (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Test-ReviewCampaignPathIsFeatureProcessRecord (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Get-ContinuousCoReviewRecordedSignoffGateDecision (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Get-ReviewCampaignChangedPathsSinceResult (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Test-ReviewCampaignResultReleasesBoundary (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Test-ReviewCampaignResultIsCompleteCurrent (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Test-ReviewCampaignDispositionAcceptsResult (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- New-ContinuousCoReviewStarterVerificationPlan (scripts/internal/continuous-co-review/verification-plan-materializer.ps1)
- Get-ContinuousCoReviewStarterVerificationTemplates (scripts/internal/continuous-co-review/verification-plan-materializer.ps1)
- Get-ContinuousCoReviewVerificationFailureDiagnosis (scripts/internal/continuous-co-review/verification-plan-runner.ps1)
- Test-ReviewCampaignCoverageDeltaHasImplementation (scripts/internal/continuous-co-review/worktree-navigator.ps1)
- Get-ReviewCampaignRecordedPendingCrossing (scripts/internal/continuous-co-review/worktree-navigator.ps1)
- New-SpecrewGatePreflightCheck (scripts/internal/gate-preflight.ps1)
- Get-SpecrewGatePreflightMarkdownValue (scripts/internal/gate-preflight.ps1)
- Get-SpecrewGatePreflightStatus (scripts/internal/gate-preflight.ps1)
- Get-SpecrewGatePreflightTaskState (scripts/internal/gate-preflight.ps1)
- ConvertFrom-SpecrewGatePreflightIdList (scripts/internal/gate-preflight.ps1)
- Invoke-SpecrewGatePreflight (scripts/internal/gate-preflight.ps1)
- Write-InstallInfo (scripts/internal/install-local-build.ps1)
- Get-SelfProvenanceFileAnnotation (scripts/internal/lint-self-leak.ps1)
- Write-ReleaseInfo (scripts/internal/module-packaging.ps1)
- Get-SpecrewVersionFromConfig (scripts/internal/module-packaging.ps1)
- Set-SpecrewManifestReleaseMetadata (scripts/internal/module-packaging.ps1)
- Get-SpecrewManifestReleaseInfo (scripts/internal/module-packaging.ps1)
- ConvertTo-ManifestPrerelease (scripts/internal/module-packaging.ps1)
- Resolve-ReleaseStamp (scripts/internal/module-packaging.ps1)
- New-ReleaseScratchRoot (scripts/internal/module-packaging.ps1)
- Copy-ReleaseFile (scripts/internal/module-packaging.ps1)
- New-ReleaseStageRoot (scripts/internal/module-packaging.ps1)
- Get-ReleaseBuildId (scripts/internal/module-packaging.ps1)
- Get-SpecrewPackageContentSha256 (scripts/internal/module-packaging.ps1)
- Write-ReleaseBuildStamp (scripts/internal/module-packaging.ps1)
- Read-SpecrewReviewRuntimeManagedText (scripts/internal/review-engine-resolution.ps1)
- Format-SpecrewIdGloss (scripts/internal/specrew-consumer-language.ps1)
- Get-SpecrewUnglossedId (scripts/internal/specrew-consumer-language.ps1)
- Get-SpecrewBannedConsumerNoun (scripts/internal/specrew-consumer-language.ps1)
- Get-SpecrewUnprovenFaultAttribution (scripts/internal/specrew-consumer-language.ps1)
- Get-DispatcherHookOutputHash (scripts/internal/specrew-hook-dispatcher.ps1)
- Write-DispatcherHookOutputAuthorityRecord (scripts/internal/specrew-hook-dispatcher.ps1)
- Get-SpecrewHookInspectionText (scripts/internal/specrew-hook-health.ps1)
- Get-SpecrewHookMissingEventRegistrations (scripts/internal/specrew-hook-health.ps1)
- Get-SpecrewGitFileTextAtCommit (scripts/internal/sync-boundary-state.ps1)
- Get-SpecrewConstraintValue (scripts/internal/sync-boundary-state.ps1)
- Get-SpecrewConstraintChanges (scripts/internal/sync-boundary-state.ps1)
- Publish-SpecrewConstraintChangeRecords (scripts/internal/sync-boundary-state.ps1)
- Assert-SpecrewAuthorityMachineryReady (scripts/specrew-review.ps1)
- inside (specs/199-beta3-stabilization/iterations/001/drift-log.md)
- via (specs/199-beta3-stabilization/iterations/001/drift-log.md)
- as (specs/199-beta3-stabilization/iterations/001/drift-log.md)
- with (specs/199-beta3-stabilization/iterations/001/drift-log.md)
- rather (specs/199-beta3-stabilization/iterations/001/drift-log.md)
- is (specs/199-beta3-stabilization/iterations/001/drift-log.md)
- and (specs/199-beta3-stabilization/iterations/001/drift-log.md)
- script (tests/bootstrap/BannerPrereleaseVersion.Tests.ps1)
- New-CaptureTurn (tests/bootstrap/ConversationCapture.Tests.ps1)
- Get-CaptureVerdictFor (tests/bootstrap/ConversationCapture.Tests.ps1)
- script (tests/continuous-co-review/unit/advisory-names-the-humans-act.Tests.ps1)
- script (tests/continuous-co-review/unit/authority-control-consumer-guard.Tests.ps1)
- script (tests/continuous-co-review/unit/baseline-provenance-fact.Tests.ps1)
- script (tests/continuous-co-review/unit/campaign-activation-implementation-premise.Tests.ps1)
- script (tests/continuous-co-review/unit/campaign-default-run-id-mint.Tests.ps1)
- script (tests/continuous-co-review/unit/campaign-pause-core.Tests.ps1)
- script (tests/continuous-co-review/unit/campaign-pause-wiring.Tests.ps1)
- script (tests/continuous-co-review/unit/campaign-stop-authority.Tests.ps1)
- script (tests/continuous-co-review/unit/campaign-stop-here-landing.Tests.ps1)
- script (tests/continuous-co-review/unit/campaign-stop-here-real-ports.Tests.ps1)
- script (tests/continuous-co-review/unit/campaign-two-governor-adjudication.Tests.ps1)
- New-DispositionFixture (tests/continuous-co-review/unit/clean-review-can-be-signed-off.Tests.ps1)
- Invoke-Disposition (tests/continuous-co-review/unit/clean-review-can-be-signed-off.Tests.ps1)
- script (tests/continuous-co-review/unit/consumer-language.Tests.ps1)
- script (tests/continuous-co-review/unit/records-only-covers-what-deployment-writes.Tests.ps1)
- script (tests/continuous-co-review/unit/records-only-delta-survives-its-own-round.Tests.ps1)
- script (tests/continuous-co-review/unit/refusal-names-a-reachable-action.Tests.ps1)
- script (tests/continuous-co-review/unit/reparse-admission-premise.Tests.ps1)
- script (tests/continuous-co-review/unit/review-boundary-campaign-evidence.Tests.ps1)
- script (tests/continuous-co-review/unit/review-derived-independence.Tests.ps1)
- script (tests/continuous-co-review/unit/review-examined-coverage.Tests.ps1)
- New-WalkShapedProject (tests/continuous-co-review/unit/review-frame-and-evidence-honesty.Tests.ps1)
- script (tests/continuous-co-review/unit/review-frame-and-evidence-honesty.Tests.ps1)
- script (tests/continuous-co-review/unit/review-record-authorship.Tests.ps1)
- New-GateCampaignResult (tests/continuous-co-review/unit/review-signoff-evidence-gate.Tests.ps1)
- Add-CleanCampaignResult (tests/continuous-co-review/unit/review-signoff-evidence-gate.Tests.ps1)
- Add-CampaignClaimWithoutResult (tests/continuous-co-review/unit/review-signoff-evidence-gate.Tests.ps1)
- script (tests/continuous-co-review/unit/review-window-codex-default.Tests.ps1)
- script (tests/continuous-co-review/unit/reviewer-prompt-contract.Tests.ps1)
- New-WiringCampaignResult (tests/continuous-co-review/unit/signoff-gate-wiring.Tests.ps1)
- Add-WiringCleanCampaignResult (tests/continuous-co-review/unit/signoff-gate-wiring.Tests.ps1)
- script (tests/continuous-co-review/unit/signoff-override-survives-its-own-preflight.Tests.ps1)
- New-StarterProject (tests/continuous-co-review/unit/verification-plan-materializer.Tests.ps1)
- script (tests/continuous-co-review/unit/verification-plan-runner.Tests.ps1)
- Start-SweepFile (tests/full-powershell-test-sweep.ps1)
- Complete-SweepFile (tests/full-powershell-test-sweep.ps1)
- script (tests/integration/approve-round-decision.Tests.ps1)
- Write-Pass (tests/integration/cap-exhaustion-is-documented.tests.ps1)
- Fail (tests/integration/cap-exhaustion-is-documented.tests.ps1)
- New-Transcript (tests/integration/cap-exhaustion-is-documented.tests.ps1)
- Invoke-Stop (tests/integration/cap-exhaustion-is-documented.tests.ps1)
- Get-SessionStateRoot (tests/integration/cap-exhaustion-is-documented.tests.ps1)
- script (tests/integration/ci-registry-lane-tooling.Tests.ps1)
- script (tests/integration/closed-iterations-are-history.tests.ps1)
- script (tests/integration/deployed-extension-marker-on-update.tests.ps1)
- Get-OutputHash (tests/integration/dispatcher-stop-block.tests.ps1)
- Assert-True (tests/integration/governed-feature-workshop-controller.tests.ps1)
- Write-Pass (tests/integration/hooks-reconcile.Tests.ps1)
- Fail (tests/integration/hooks-reconcile.Tests.ps1)
- New-DispatcherCommand (tests/integration/hooks-reconcile.Tests.ps1)
- Write-Pass (tests/integration/init-verification-plan.Tests.ps1)
- Fail (tests/integration/init-verification-plan.Tests.ps1)
- New-GovernedProject (tests/integration/init-verification-plan.Tests.ps1)
- Get-PlanPath (tests/integration/init-verification-plan.Tests.ps1)
- Add-LifecycleCampaignResult (tests/integration/lifecycle-boundary-sync.tests.ps1)
- script (tests/integration/no-code-without-approval.tests.ps1)
- Test-CommandTargetsSpecrewDispatcher (tests/integration/refocus-deploy.tests.ps1)
- Write-CampaignResult (tests/integration/review-evidence-integrity.tests.ps1)
- script (tests/integration/review-record-survives-its-own-commit.tests.ps1)
- Assert-True (tests/integration/session-orientation-rendered.tests.ps1)
- Invoke-Stop (tests/integration/session-orientation-rendered.tests.ps1)
- Invoke-StopWithTranscript (tests/integration/session-orientation-rendered.tests.ps1)
- Expand-HookCommandText (tests/integration/stopblock-deployed-binding.tests.ps1)
- New-CaptureTranscript (tests/integration/verdict-capture-blocks.tests.ps1)
- Get-CaptureLedger (tests/integration/verdict-capture-blocks.tests.ps1)
- Assert-True (tests/integration/workshop-agenda-confirmation.tests.ps1)
- Add-TypedReply (tests/integration/workshop-agenda-confirmation.tests.ps1)
- Add-AgendaReplyThroughShippedProvider (tests/integration/workshop-agenda-confirmation.tests.ps1)
- Invoke-ShippedWorkshopProvider (tests/integration/workshop-agenda-confirmation.tests.ps1)
- Assert-True (tests/integration/workshop-material-packet-language.tests.ps1)
- Add-TypedReply (tests/integration/workshop-material-packet-language.tests.ps1)
- Invoke-ProviderStop (tests/integration/workshop-material-packet-language.tests.ps1)
- Assert-True (tests/integration/workshop-state-transition-table.tests.ps1)
- New-PendingController (tests/integration/workshop-state-transition-table.tests.ps1)
- Copy-Controller (tests/integration/workshop-state-transition-table.tests.ps1)
- Assert-True (tests/integration/workshop-typed-turn-authority.tests.ps1)
- Write-Pass (tests/unit/authorization-ref-not-the-advice.tests.ps1)
- Fail (tests/unit/authorization-ref-not-the-advice.tests.ps1)
- Assert-True (tests/unit/banner-ids-are-glossed.tests.ps1)
- Get-EmittedStringLiterals (tests/unit/banner-ids-are-glossed.tests.ps1)
- Invoke-ConstraintVisibilityGit (tests/unit/constraint-change-visibility.Tests.ps1)
- New-ConstraintVisibilityRepo (tests/unit/constraint-change-visibility.Tests.ps1)
- script (tests/unit/coverage-is-a-decision.tests.ps1)
- script (tests/unit/deployed-extension-integrity.tests.ps1)
- Invoke-ClassClosureFixture (tests/unit/drift-class-closure.Tests.ps1)
- Assert-True (tests/unit/every-suite-is-named-by-a-lane.tests.ps1)
- Fail (tests/unit/full-sweep-direct-exit.tests.ps1)
- New-PreflightRepo (tests/unit/gate-preflight.Tests.ps1)
- script (tests/unit/maintainer-skill-host-parity.tests.ps1)
- script (tests/unit/module-packaging-identity.tests.ps1)
- Write-Pass (tests/unit/module-wrapper-windows-drive-equals.tests.ps1)
- Write-Fail (tests/unit/module-wrapper-windows-drive-equals.tests.ps1)
- script (tests/unit/no-automatic-variable-collisions.tests.ps1)
- script (tests/unit/no-internal-ids-in-emitted-strings.tests.ps1)
- Assert-True (tests/unit/pause-choice-carries-round-approval.tests.ps1)
- Get-RoundApprovalPredicate (tests/unit/pause-choice-carries-round-approval.tests.ps1)
- Assert-True (tests/unit/review-approve-round-host-resolution.tests.ps1)
- Get-HostResolutionGuardConditions (tests/unit/review-approve-round-host-resolution.tests.ps1)
- Assert-True (tests/unit/review-flag-whitelist-parity.tests.ps1)
- Get-ScriptAst (tests/unit/review-flag-whitelist-parity.tests.ps1)
- script (tests/unit/reviewer-closeout-artifacts-generate.tests.ps1)
- script (tests/unit/round-approval-typed-authority.tests.ps1)
- Write-SpecrewFileAtomic (tests/unit/round-approval-typed-authority.tests.ps1)
- script (tests/unit/scaffold-migration-and-pending.tests.ps1)
- script (tests/unit/scaffold-writes-once.tests.ps1)
- Assert-True (tests/unit/session-orientation-obligation.tests.ps1)
- ConvertTo-FlowedText (tests/unit/session-orientation-obligation.tests.ps1)
- Invoke-NativeCommandForOutput (tests/unit/spec-kit-preflight-path.Tests.ps1)
- script (tests/unit/task-progress-no-demotion.tests.ps1)
- Assert-True (tests/unit/workshop-refusal-contract.tests.ps1)
- Test-AgendaRefusalCoverage (tests/unit/workshop-refusal-contract.tests.ps1)

### Removed

- Write-ReleaseInfo (scripts/internal/invoke-module-release.ps1)
- Get-SpecrewVersionFromConfig (scripts/internal/invoke-module-release.ps1)
- Set-SpecrewManifestReleaseMetadata (scripts/internal/invoke-module-release.ps1)
- Get-SpecrewManifestReleaseInfo (scripts/internal/invoke-module-release.ps1)
- ConvertTo-ManifestPrerelease (scripts/internal/invoke-module-release.ps1)
- Resolve-ReleaseStamp (scripts/internal/invoke-module-release.ps1)
- New-ReleaseScratchRoot (scripts/internal/invoke-module-release.ps1)
- Copy-ReleaseFile (scripts/internal/invoke-module-release.ps1)
- New-ReleaseStageRoot (scripts/internal/invoke-module-release.ps1)
- Write-PassRun (tests/continuous-co-review/unit/review-signoff-evidence-gate.Tests.ps1)
- Write-WiringPassRun (tests/continuous-co-review/unit/signoff-gate-wiring.Tests.ps1)

## Module Hotspots

- Threshold: 250 changed lines per file
- .specify/extensions/specrew-speckit/.specrew-extension-runtime.json (659 changed lines)
- .specify/extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1 (257 changed lines)
- .specify/extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1 (286 changed lines)
- .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 (1510 changed lines)
- .specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 (727 changed lines)
- .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 (625 changed lines)
- .specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1 (533 changed lines)
- .specrew/release-gate-suites.txt (354 changed lines)
- extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1 (257 changed lines)
- extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1 (286 changed lines)
- extensions/specrew-speckit/scripts/shared-governance.ps1 (1510 changed lines)
- extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 (727 changed lines)
- extensions/specrew-speckit/scripts/validate-governance.ps1 (625 changed lines)
- extensions/specrew-speckit/scripts/workshop-authority-store.ps1 (533 changed lines)
- scripts/internal/bootstrap/ConversationCaptureAccessor.ps1 (278 changed lines)
- scripts/internal/bootstrap/HumanAuthorityStore.ps1 (1825 changed lines)
- scripts/internal/continuous-co-review/.specrew-runtime.json (252 changed lines)
- scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1 (472 changed lines)
- scripts/internal/continuous-co-review/review-authority-core.ps1 (501 changed lines)
- scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1 (971 changed lines)
- scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1 (685 changed lines)
- scripts/internal/module-packaging.ps1 (356 changed lines)
- scripts/internal/sync-boundary-state.ps1 (285 changed lines)
- scripts/specrew-review.ps1 (1089 changed lines)
- specs/199-beta3-stabilization/iterations/001/design-analysis.md (1113 changed lines)
- specs/199-beta3-stabilization/iterations/001/drift-log.md (8196 changed lines)
- tests/continuous-co-review/unit/advisory-names-the-humans-act.Tests.ps1 (359 changed lines)
- tests/continuous-co-review/unit/campaign-pause-core.Tests.ps1 (505 changed lines)
- tests/continuous-co-review/unit/campaign-pause-wiring.Tests.ps1 (838 changed lines)
- tests/continuous-co-review/unit/campaign-stop-authority.Tests.ps1 (440 changed lines)
- tests/continuous-co-review/unit/consumer-language.Tests.ps1 (385 changed lines)
- tests/continuous-co-review/unit/reparse-tag-policy.Tests.ps1 (394 changed lines)
- tests/continuous-co-review/unit/review-derived-independence.Tests.ps1 (417 changed lines)
- tests/continuous-co-review/unit/review-frame-and-evidence-honesty.Tests.ps1 (569 changed lines)
- tests/continuous-co-review/unit/review-spend-allowance.Tests.ps1 (313 changed lines)
- tests/integration/no-code-without-approval.tests.ps1 (257 changed lines)
- tests/integration/review-record-survives-its-own-commit.tests.ps1 (307 changed lines)
- tests/integration/workshop-agenda-confirmation.tests.ps1 (313 changed lines)
- tests/unit/round-approval-typed-authority.tests.ps1 (2578 changed lines)
