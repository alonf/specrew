---
description: "Validate execution readiness before implementation"
---

# Validate Execution Readiness

## Boundary authorization gate

Before any boundary-advancing work, run:

```powershell
. .\.specify\extensions\specrew-speckit\scripts\shared-governance.ps1
$authorization = Test-SpecrewBoundaryAuthorization -ProjectRoot . -CurrentBoundary 'tasks' -RequestedBoundary 'before-implement'
if (-not $authorization.Authorized) {
  Write-Output (Write-SpecrewBoundaryAuthorizationDirective -CurrentBoundary $authorization.CurrentBoundary -RequestedBoundary $authorization.RequestedBoundary -DirectiveSentinel $authorization.DirectiveSentinel)
  throw $authorization.Reason
}
```

Before implementation starts, confirm the active iteration artifacts are approved and execution-ready.

## Required checks

1. Confirm the latest iteration plan has an approval verdict and is still the active source of truth.
2. Verify execution is not bypassing unresolved review findings or missing phase artifacts.
3. Run `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` when iteration artifacts are available.
4. When the active iteration includes Phase 2 hardening-gate scope (`FR-031` through `FR-033`), confirm `quality/hardening-gate.md` exists and records explicit review of:
   - security surface analysis
   - error-handling expectations
   - retry and idempotency requirements
   - test-integrity targets
5. For a Phase 2 hardening slice, confirm the hardening gate status is implementation-ready:
   - explicit sign-off is recorded, or
   - each unresolved critical concern has explicit human developer deferral approval recorded
6. Do not treat `TBD`, omitted rationale, or agent-only deferral decisions as implementation-ready for critical security, resilience, or operational concerns.
7. Keep later quality behavior truthful. Do not claim dedicated bug-hunter execution, strongest-class routing enforcement, known-traps workflows, or quality-drift automation are already active unless the current slice actually delivered them.

## Lifecycle-adjacent command: /speckit.analyze (before-implement)

Surface `/speckit.analyze` at this before-implement boundary, but only after `/speckit.tasks` has produced a complete `tasks.md`. It requires the full artifact set — `spec.md`, `plan.md`, and `tasks.md` — and performs an additive cross-artifact consistency and quality review across them.

- It is **additive** to Specrew governance validation: it complements the governance checks and **does not replace** them.
- It is only meaningful once a complete `tasks.md` exists; there is nothing for it to analyze before tasks are generated.
- If you reach `/speckit.analyze` before a complete `tasks.md` exists, do not run it prematurely — return at the before-implement boundary after `/speckit.tasks` completes.

## Failure behavior

If governance validation fails, approvals are incomplete, or the Phase 2 hardening gate is missing sign-off / human-approved deferral coverage, stop implementation, report the concrete blocking artifact or verdict, explain why it blocks implementation, and state the next valid human action.
