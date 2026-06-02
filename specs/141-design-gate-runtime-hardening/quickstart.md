# Quickstart: Design Gate Runtime Hardening

**Feature**: 141-design-gate-runtime-hardening  
**Last verified**: 2026-06-02 (planning-time; commands finalize during Iteration 1)

## Run it

```powershell
# Validate a design-analysis artifact against the gate (Feature 140 helper, extended in iter 1)
pwsh -NoProfile -Command ". ./scripts/internal/design-analysis-gate.ps1; Test-SpecrewDesignAnalysisArtifact -ProjectRoot . -FeatureRef '<feature>' -IterationNumber '001' | ConvertTo-Json"

# Focused tests (names finalize during implementation)
pwsh -File tests/unit/design-analysis-gate.tests.ps1
pwsh -File tests/integration/design-analysis-boundary.tests.ps1
```

## Try the canonical scenario (Iteration 1)

1. Reach the design-analysis stop for a substantive iteration. The scaffold emits
   `specs/<feature>/iterations/<NNN>/design-analysis.md` from the template.
   Expected: the freshly scaffolded artifact matches the Feature 140 validator
   contract (problem framing, decision points, ≥2 options with required fields,
   Crew recommendation, empty Human Decision).
2. Attempt to author `plan.md` before filling the artifact / before a human
   decision. Expected: the pre-plan validator blocks with an actionable message
   naming the missing section, and `plan.md` is not authored.
3. Fill the artifact, render the typed gate packet, and record a human decision
   (`approved for plan with Option <X>`). Expected: a narrow durable packet is
   stored under `specs/<feature>/gates/` and the pre-plan validator returns
   `valid: true` with the selected option.
4. Proceed to plan. Expected: `plan.md` is authored and the selected option is
   preserved as authoritative input.

## Verify the edge cases

- **Missing recommendation**: remove the Crew recommendation → validation fails.
- **Missing human decision**: leave Human Decision empty → plan-boundary blocked.
- **Lenses absent (downstream)**: no lens files present → the Applicable Lenses
  section degrades gracefully (states none applicable) rather than erroring.

## Smoke-bundle scenarios (later iterations)

- **Start-packet paths (iter 2)**: generate a start packet → no emitted path
  contains `specs//`.
- **Host wording (iter 2)**: launch on the Claude host → generated guidance shows
  no Copilot approval-mode wording.
- **Downstream warnings (iter 3)**: run a lifecycle command in a greenfield/
  downstream project → only genuinely actionable warnings appear.
- **Greenfield baseline (iter 3)**: bootstrap a fresh greenfield project and record
  the first boundary → the baseline commit resolves to a real hash and is
  consistent across start context and boundary state.
