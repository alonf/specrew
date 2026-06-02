# Quickstart: Design Gate Runtime Hardening

**Feature**: 141-design-gate-runtime-hardening  
**Last verified**: 2026-06-02 (Iteration 2 delivered: start-packet correctness, host wording, stale-session recovery)

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

## Iteration 2 (delivered 2026-06-02): start-packet correctness + stale-session recovery

- **No empty `specs//` paths (FR-011)**: the greenfield/intake orientation block no longer emits
  a `file:///<project-root-url>/specs/<feature>/` browse URL (which collapses to `specs//` when the
  coordinator substitutes an empty `<feature>` per Rule 48); it emits explicit-placeholder guidance
  instead, and a resolved-feature resume still surfaces the concrete browse paths. Verify:
  `pwsh -File tests/integration/multi-host-launch-path.tests.ps1` (Test 9b), or run a greenfield
  `specrew start --host claude -NoLaunch` and confirm the prompt contains no `specs//`.
- **Host-accurate launch wording (FR-014)**: the launch guidance is host-neutral — `Approval mode:`
  (not `Copilot approval mode`) plus a host-aware delegation line. Verify: same test (Test 18b), or a
  greenfield `specrew start --host claude` shows no `Copilot` terminology.
- **Stale cross-worktree session recovery (FR-024)**: a saved session anchored to a deleted/external
  feature worktree is detected stale; recovery choice A does NOT re-anchor to it and instead requests
  confirm-gated cleanup that clears ONLY the runtime session refs (start-context `session_state` + the
  matching `active-sessions` entry) — never feature artifacts, never lifecycle commits — and the
  cleared state sticks across the same start run. Verify:
  `pwsh -File tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1` and
  `pwsh -File tests/integration/start-recovery-flow.tests.ps1` (end-to-end confirm->clear).
- **Gate harness clean exit (T004)**: the design-analysis plan-boundary gate returns `Valid` with a
  clean `$LASTEXITCODE` (no stray error) on a valid artifact. Verify:
  `pwsh -File tests/unit/design-gate-runtime-hardening.tests.ps1`.

## Iteration 3 (future)

- **Downstream warnings (FR-012)**: run a lifecycle command in a greenfield/downstream project →
  only genuinely actionable warnings appear.
- **Greenfield baseline (FR-013)**: bootstrap a fresh greenfield project and record the first
  boundary → the baseline commit resolves to a real hash and is consistent across start context
  and boundary state.
