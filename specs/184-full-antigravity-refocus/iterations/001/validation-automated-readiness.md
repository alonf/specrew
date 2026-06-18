# T007 Automated Validation, Mirror Parity, and FileList Readiness

## Verdict

PASS after repair.

## Repair During T007

The first governance validation found one real active-iteration defect:
`state.md` had been manually changed to `Current Phase: implement`, but the
validator canonical set only allows boundary names. T007 repaired this by
restoring `Current Phase: before-implement`, which is the last authorized
boundary while implementation tasks execute.

The follow-up scoped governance run passes for
`specs/184-full-antigravity-refocus/iterations/001`. Repository-wide historical
warnings remain outside F-184: old closed iterations missing dashboards and old
handoff-evidence warnings.

## Automated Runtime Tests

| Command | Result |
| --- | --- |
| `pwsh -NoProfile -File tests/bootstrap/HostEventAdapter.Tests.ps1` | PASS |
| `pwsh -NoProfile -File tests/bootstrap/SessionStateAccessor.Tests.ps1` | PASS |
| `pwsh -NoProfile -File tests/bootstrap/ClassificationEngine.Tests.ps1` | PASS |
| `pwsh -NoProfile -File tests/bootstrap/SessionBootstrapManager.Tests.ps1` | PASS |
| `pwsh -NoProfile -File tests/integration/refocus-dispatcher.tests.ps1` | PASS |
| `pwsh -NoProfile -File tests/integration/refocus-deploy.tests.ps1` | PASS |
| `pwsh -NoProfile -File tests/integration/specrew-hooks-command.tests.ps1` | PASS |
| `pwsh -NoProfile -File tests/bootstrap/Regression.Tests.ps1` | PASS |

## FileList and Release Readiness

| Check | Result |
| --- | --- |
| `(Test-ModuleManifest .\Specrew.psd1).FileList` | PASS; FileList imports and includes bootstrap/refocus provider surfaces. |
| `pwsh -NoProfile -File tests/integration/filelist-completeness.tests.ps1` | PASS; 308 FileList entries checked and shipping-root coverage is bidirectional. |
| `pwsh -NoProfile -File tests/integration/publish-module-harness.tests.ps1` | PASS; Docker publish harness, FileList validation, version pin checks, and workflow wiring present. |
| `pwsh -NoProfile -File tests/unit/wrapper-filelist-parity.tests.ps1` | PASS |
| `pwsh -NoProfile -File tests/unit/wrapper-registry-parity.tests.ps1` | PASS |

## Mirror Parity

SHA-256 hashes match across source, extension, and deployed `.specify` copies for
the touched refocus/bootstrapping surfaces:

| Surface | Result |
| --- | --- |
| `specrew-hook-dispatcher.ps1` | PASS |
| `specrew-bootstrap-provider.ps1` | PASS |
| `specrew-handover-provider.ps1` | PASS |
| `refocus.ps1` | PASS |

## Governance Validation

| Command | Result |
| --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` | Initial FAIL; caught the noncanonical `Current Phase: implement` defect in active state. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -IterationPath specs/184-full-antigravity-refocus/iterations/001 -NoParallel` | PASS after repair; historical warnings only. |

## Remaining Validation

T008 still owns real-host `agy` proof for B3 delivery, self-marker behavior,
per-session anchor persistence, Stop handover, exit/re-entry, and the final
Proposal 145 review evidence.
