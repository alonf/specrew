# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/009-project-path-resolution/spec.md`
**Iteration Ref**: `specs/009-project-path-resolution/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Implementer (Copilot)
**Reviewed At**: 2026-05-10T00:00:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `not-needed` | Keep the slice bounded to `tests\manual\copilot-squad-smoke.ps1`, `tests\manual\copilot-squad-confidence-lane.ps1`, the `evaluation\scorers\process-scorer.ps1` migration-or-exemption decision, and the regression/static-scan extension; add no credentials, network calls, or spec-008 edits. | `true` | This audit-gap slice stays inside local PowerShell harnesses, scorer output, and deterministic repo checks. The only meaningful security control is holding scope at the named local artifacts and preventing unrelated surface expansion. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Preserve missing-tool skip/fail behavior in the manual smoke/confidence scripts, keep trace/report writes explicit, and require any `process-scorer.ps1` migration or exemption to preserve the current JSON/report contract with fail-closed messaging when the bounded audit cannot complete. | `true` | Validation lanes completed successfully and the manual harnesses preserved skip/fail behavior while the scorer exemption retained its report contract. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `true` | Re-running this slice only rewrites local traces, reports, or regression findings for the same repository inputs. No queued retries, external mutations, or non-idempotent side effects are introduced by the bounded harness/scorer work. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Land deterministic proof across `tests\manual\copilot-squad-smoke.ps1`, `tests\manual\copilot-squad-confidence-lane.ps1`, and the regression/static-scan extension, then record whether `evaluation\scorers\process-scorer.ps1` migrated into the bounded audit or was explicitly exempted with reviewable evidence. | `true` | Regression lane passed with static scan clean, and the process-scorer exemption was documented. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | Keep trace persistence deterministic, avoid introducing long-lived background services, and preserve operator-visible outcomes when the confidence lane launches Copilot live versus manual-handoff modes or skips due to missing tools. | `true` | Trace persistence remains deterministic with no new background services; validation lane outputs confirm the harnesses still emit operator-visible status. | `—` |

## Notes

- Runtime evidence for the bounded audit-gap slice was recorded via the full validation lane on 2026-05-10.
- Scope is intentionally limited to `tests\manual\copilot-squad-smoke.ps1`, `tests\manual\copilot-squad-confidence-lane.ps1`, the possible `evaluation\scorers\process-scorer.ps1` migration-or-exemption decision, and the regression/static-scan extension. Spec 008 is out of scope and must remain untouched by this slice.
- Explicit human execution approval for this slice is recorded verbatim in the iteration plan/state artifacts: `I am explicitly authorizing the work below; do all of it in this same session without asking for additional approvals beyond the explicit human checkpoints named below.`
