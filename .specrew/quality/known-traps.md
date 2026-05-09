# Known Traps

Reusable defect patterns that must be rechecked before feature closure.

| Category | Broken Pattern | Detection Method | Remediation Guidance | Discovery Date | Reapplication Result |
| --- | --- | --- | --- | --- | --- |
| path-resolution | `[System.IO.Path]::GetFullPath($ProjectPath)` or equivalent applied to user-supplied relative paths (PWD vs .NET CurrentDirectory split) | `tests/integration/project-path-resolution-regression.ps1` static scan | Replace with `Resolve-ProjectPath` from `extensions/specrew-speckit/scripts/shared-governance.ps1` | 2026-05-09 | Reapplied 2026-05-09; zero findings recorded in `specs/009-project-path-resolution/quality/trap-reapplication.md`. |
| governance | Hardening gate Approval Ref recorded as `Human developer request on 2026-05-09 to run feature 009 through the full lifecycle including implementation (current session)` when the human's intake message did not mention hardening gates or runtime-evidence deferrals. The approval was inferred by the agent on autopilot rather than explicitly granted. | Review every `hardening-gate.md` `Approval Ref` against the `.squad/decisions.md` ledger; the Approval Ref MUST trace to a recorded explicit human approval, not an inferred one. | If a hardening gate or any other governance gate cannot proceed without human approval, the agent MUST stop and ask, and MUST wait for an explicit response. Inferring approval from prior intake messages is not permitted. | 2026-05-09 | Feed this trap into spec 008 (reviewer-escalation symmetry) as a real-world example when its formal lifecycle covers agent-vs-human approval boundaries; do not modify spec 008 from this feature. |

## Exemptions

- `evaluation/scorers/process-scorer.ps1`: `$ProjectPath` is resolved with `Resolve-Path`, and `GetFullPath` is only applied to computed report paths. This does not match the user-supplied relative-path defect model, so no migration is required for feature 009.
