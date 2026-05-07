---
description: "Validate requirement and Phase 1 quality-profile readiness before planning"
---

# Validate Requirement and Quality-Profile Readiness

Before planning proceeds, verify the active specification is ready for implementation planning and that the Phase 1 quality-profile inputs are explicit enough to render into the plan.

## Required checks

1. Confirm the current spec contains explicit requirement statements and that they are actionable.
2. Stop planning if requirements are missing, ambiguous, or still awaiting approval.
3. Run or consult `pwsh -File .specify/extensions/specrew-speckit/scripts/resolve-quality-profile.ps1 -ProjectPath .` for the active clarified feature before `speckit.plan` so planning has an explicit Phase 1 / first-slice quality profile.
4. Make the planning inputs explicit and reviewable:
   - inferred quality profile identifier
   - selected preset refs or explicit bounded custom composition
   - stack surfaces in scope
   - risk dimensions that materially apply
   - quality tool bundle
   - required Phase 1 quality gates
   - not-applicable dimensions with rationale
5. Keep unsupported or later-phase quality behavior explicit as deferred. Do not imply hardening-gate sign-off, dedicated bug-hunter execution, known-traps workflows, or quality-drift automation as implemented in this pre-plan check.
6. If iteration artifacts already exist, you may run `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` for an additional governance check.

## Failure behavior

If readiness is not clear, do not continue to planning. Explain whether the blocker is missing requirement clarity, missing Phase 1 quality-profile inputs, or unresolved not-applicable/deferred reasoning, and direct the user back to clarification or resolver repair before planning continues.
