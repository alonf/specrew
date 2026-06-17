# Coverage Evidence: F-184 Iteration 001

## Summary

All in-scope automated validation commands passed after the T008 repair. Manual
real-host Antigravity evidence is machine-local and recorded separately.

## Automated Commands

| Command | Result |
| --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/HostEventAdapter.Tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/SessionStateAccessor.Tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/ClassificationEngine.Tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/SessionBootstrapManager.Tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/Regression.Tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/refocus-dispatcher.tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/refocus-deploy.tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/specrew-hooks-command.tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/filelist-completeness.tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/publish-module-harness.tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/unit/wrapper-filelist-parity.tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/unit/wrapper-registry-parity.tests.ps1` | PASS |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -IterationPath specs/184-full-antigravity-refocus/iterations/001 -NoParallel` | PASS for F-184; non-blocking warnings only, including historical dashboard/handoff warnings and the expected missing `dashboard.md` warning before iteration-closeout render. |
| `git diff --check` | PASS |
| `markdownlint specs/184-full-antigravity-refocus/iterations/001/review.md specs/184-full-antigravity-refocus/iterations/001/code-map.md specs/184-full-antigravity-refocus/iterations/001/coverage-evidence.md specs/184-full-antigravity-refocus/iterations/001/dependency-report.md specs/184-full-antigravity-refocus/iterations/001/review-diagrams.md specs/184-full-antigravity-refocus/iterations/001/reviewer-index.md specs/184-full-antigravity-refocus/iterations/001/implementation-completion-review-145.md specs/184-full-antigravity-refocus/iterations/001/real-host-antigravity-evidence.md` | PASS |
| `(Test-ModuleManifest .\Specrew.psd1)` | PASS; version `0.37.0`, FileList count `308`. |
| SHA-256 comparison for `deploy-refocus-hooks.ps1` source/extension/`.specify` copies | PASS; all hashes `BDC510891F04699C2C868F1CF2C8AD1D4CD390B184626FB7FFE2D2ABEB990FBF`. |

The initial all-in-one test loop timed out at the shell timeout and was not used
as pass evidence. The same commands were rerun in smaller groups and passed.

## Requirement Coverage

| Requirement | Evidence |
| --- | --- |
| FR-001 | `HostEventAdapter.Tests.ps1`, `refocus-dispatcher.tests.ps1`, real-host state file. |
| FR-002 | `SessionStateAccessor.Tests.ps1`, `SessionBootstrapManager.Tests.ps1`, real-host state file. |
| FR-003 | `refocus-dispatcher.tests.ps1`, `Regression.Tests.ps1`, real-host B3 journal. |
| FR-004 | `ClassificationEngine.Tests.ps1`, `SessionBootstrapManager.Tests.ps1`, real-host bootstrap journal. |
| FR-005 | `refocus-deploy.tests.ps1`, `specrew-hooks-command.tests.ps1`, real-host PreInvocation/Stop logs and handover. |
| FR-006 | `refocus-dispatcher.tests.ps1` provider-crash and corrupt-state cases. |
| FR-007 | `refocus-deploy.tests.ps1`, `specrew-hooks-command.tests.ps1`. |
| FR-008 | Documentation artifact and markdown validation. |
| FR-009 | Real-host evidence artifact and review claim ledger. |
| FR-010 | T001 discovery, dispatcher tests, and real-host no-refactor proof. |

## Manual Real-Host Evidence

See file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/iterations/001/real-host-antigravity-evidence.md.

Key result: Antigravity CLI `1.0.8` executed `PreInvocation` and `Stop`, B3
was recorded exactly once for conversation
`eba5a643-d9cc-44b4-94ae-8e55d03ca139` after a boundary change, unchanged
resume did not reinject, and same-session markers did not warn as competing.
