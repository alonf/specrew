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

The command set covers artifact validation, active plan-boundary blocking, sync atomicity, and governance validation.

## Try the canonical scenario

1. Start or fixture a new substantive feature at clarify/before-plan.
   Expected result: the feature is classified as requiring design analysis before plan when the active session is on the same feature, `.specrew/config.yml` declares `specrew_version` 0.30.0 or later, the current boundary is specify/clarify/before-plan, and the spec contains substantive feature signals.

2. Create `specs/<feature>/iterations/001/design-analysis.md` with problem framing, decision points, Simplest and Reasonable alternatives, Crew recommendation, and an empty Human Decision section.
   Expected result: artifact structure is accepted, but plan-boundary advancement is still blocked because the human decision is missing.

3. Add a Human Decision section with a verdict equivalent to `approved for plan with Option B`, the chosen option, human reason or modifications, and a commit hash.
   Expected result: active plan-boundary enforcement allows plan to advance for that feature/iteration.

4. Generate `plan.md`.
   Expected result: the plan references the selected option and any human modifications as authoritative planning input.

5. Sync the plan boundary with `sync-boundary-state.ps1 -BoundaryType plan -FeatureRef <feature> -IterationNumber 001 -AuthCommitHash <commit>`.
   Expected result: the sync helper rechecks the active design-analysis evidence before writing lifecycle state.

## Verify the edge cases

1. Missing artifact:
   A new substantive iteration without `design-analysis.md` must fail or hold plan-boundary advancement.

2. Missing recommendation:
   An artifact with alternatives but no populated Crew recommendation must fail or hold plan-boundary advancement.

3. Conditional By-the-book:
   A two-option artifact must pass when it clearly states that By-the-book is not meaningfully distinct for the slice.

4. Compatibility:
   Existing projects or already in-flight features without historical design-analysis artifacts must not hard-fail unexpectedly after update. The narrow hard-block applies to active same-feature substantive plan-boundary syncs on Specrew 0.30.0 or later, and to any feature/iteration that has opted in by creating `design-analysis.md`.

5. Scope guard:
   Unix install, shell wrapper, bootstrap, beta publish, and stable publish paths must remain untouched.
