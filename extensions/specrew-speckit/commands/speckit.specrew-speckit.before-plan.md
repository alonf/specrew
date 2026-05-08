---
description: "Validate requirement and quality-governance readiness before planning"
---

# Validate Requirement and Quality-Profile Readiness

Before planning proceeds, verify the active specification is ready for implementation planning and that the applicable quality-governance inputs are explicit enough to render into the plan.

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
5. When the planned slice includes Phase 2 hardening-gate scope (`FR-031` through `FR-033`), keep the lifecycle boundary explicit in the planning inputs:
   - the resolver output remains planning input, not proof that hardening review already happened
   - the plan must make it clear that `quality/hardening-gate.md` sign-off is required before implementation starts
   - any unresolved critical security, resilience, or operational concern will need explicit human-approved deferral before implementation may proceed
6. Keep unsupported or later-phase quality behavior explicit as deferred. Do not imply hardening-gate sign-off, dedicated bug-hunter execution, strongest-class routing enforcement, known-traps workflows, or quality-drift automation as implemented in this pre-plan check unless the current slice truly delivers them.
7. If iteration artifacts already exist, you may run `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` for an additional governance check.

## Failure behavior

If readiness is not clear, do not continue to planning. Explain whether the blocker is missing requirement clarity, missing quality-profile inputs, missing hardening-lifecycle framing for a Phase 2 slice, or unresolved not-applicable/deferred reasoning, and direct the user back to clarification or resolver repair before planning continues.
