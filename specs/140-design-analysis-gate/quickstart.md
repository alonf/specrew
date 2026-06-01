# Quickstart: Minimal Design Alternatives / Architecture Intake Gate

**Feature**: 140-design-analysis-gate  
**Last verified**: 2026-06-02

## Run it

From the repository root after implementation:

```powershell
pwsh -File tests/unit/design-analysis-gate.tests.ps1
pwsh -File tests/integration/design-analysis-boundary.tests.ps1
pwsh -File tests/integration/boundary-sync-atomic.tests.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

The exact focused test filenames may be adjusted during implementation, but the command set must include artifact validation, active plan-boundary blocking, sync atomicity, and governance validation.

## Try the canonical scenario

1. Start or fixture a new substantive feature at clarify/before-plan.
   Expected result: the feature is classified as requiring design analysis before plan.

2. Create `specs/<feature>/iterations/001/design-analysis.md` with problem framing, decision points, Simplest and Reasonable alternatives, Crew recommendation, and an empty Human Decision section.
   Expected result: artifact structure is accepted, but plan-boundary advancement is still blocked because the human decision is missing.

3. Add a Human Decision section with a verdict equivalent to `approved for plan with Option B`, the chosen option, human reason or modifications, and a commit hash.
   Expected result: active plan-boundary enforcement allows plan to advance for that feature/iteration.

4. Generate `plan.md`.
   Expected result: the plan references the selected option and any human modifications as authoritative planning input.

## Verify the edge cases

1. Missing artifact:
   A new substantive iteration without `design-analysis.md` must fail or hold plan-boundary advancement.

2. Missing recommendation:
   An artifact with alternatives but no populated Crew recommendation must fail or hold plan-boundary advancement.

3. Conditional By-the-book:
   A two-option artifact must pass when it clearly states that By-the-book is not meaningfully distinct for the slice.

4. Compatibility:
   Existing projects or already in-flight features without historical design-analysis artifacts must not hard-fail unexpectedly after update.

5. Scope guard:
   Unix install, shell wrapper, bootstrap, beta publish, and stable publish paths must remain untouched.
