# Coverage Evidence: Iteration 006

**Schema**: v1
**Reviewed**: 2026-07-16
**Overall Verdict**: accepted
**Reviewed-State Digest**: `bedc0172de77fda277f764cd07b90d5af291e2cc`

## Tests Run

| Command / evidence | Result | Binding |
| --- | --- | --- |
| Focused authority/ingress/orchestrator Pester lane | 52 passed, 0 failed, 0 skipped | File-primary pair plus timing/strict-ingress core |
| `pwsh -NoProfile -File tests/f198-iteration006-foundation.ps1 -RecordEvidence` | 93 passed, 0 failed, 0 skipped; 24.727 s | HEAD `2157017f`; digest `bedc0172...` |
| `pwsh -NoProfile -File tests/f198-regression-suite.ps1 -PerTestTimeoutSeconds 300` | all 45 registered suites green; 393.5 s | Pre-commit full regression, unchanged committed implementation |
| `Invoke-Pester tests/integration/packaged-artifact-deploy.Tests.ps1` | 2 passed, 0 failed, 0 skipped | Staged module import and FileList completeness |
| `run-i006-t050-claude-v6` | complete valid current pass; zero findings; 507.609 s | Exact digest `bedc0172...`; verified containment/termination |
| Bidirectional traceability | PASS, 10/10 tasks and 14/14 scoped FR/SC requirements | No orphan task, invalid ref, or uncovered scoped requirement |

## Requirement Coverage

| Requirement | Iteration 006 status | Executable evidence |
| --- | --- | --- |
| FR-057 | verified foundation | Cutover, core, store, and orchestrator suites |
| FR-058 | verified foundation | Immutable reservation/spend/claim/reconciliation store tests |
| FR-059 | verified code-target foundation | Real external Git target, origin integrity, current/moved classification tests |
| FR-060 | verified common contract plus Claude file-primary slice | Core/ingress tests and the prose-file rejection/raw-file acceptance pair; remaining adapters stay Iteration 007 |
| FR-061 | verified core semantics; production runtimes deferred | Timeout-after-termination ordering and runtime fixture tests; three production OS adapters stay Iteration 007 |
| FR-062 | verified foundation policy | Visible reruns, human allowance, partial findings, lineage, deterministic recovery tests |
| FR-063 | verified foundation timing/preflight | Preflight-before-spend, live clock, derived duration bounds, informational progress tests |
| FR-064 | verified foundation conformance only | 93-test foundation plus 45-suite registry; five live harness smokes/three-OS matrix stay Iteration 007 |
| FR-065 | verified delivery boundary | Cutover map and explicit Iteration 006/007 split; no Beta3 adapter claim |
| SC-017 | satisfied for foundation | Barrier-synchronized one-winner reservation and claim fixtures |
| SC-018 | satisfied for code-target foundation | Exact disposable target and unchanged origin proof |
| SC-019 | intentionally incomplete | Five real harnesses and three production platforms remain Iteration 007 |
| SC-020 | satisfied for core/fake-runtime slice | Timeout, partial, recovery, moved-snapshot, strict-ingress fixtures; production OS proof remains Iteration 007 |
| SC-021 | partially satisfied as planned | Timing, cost, diagnostics, progress foundation; production heartbeat/usage/retro projection remain Iteration 007 |

## Integrity Notes

- Strict ingress never salvages prose-wrapped output; v2 and v5 remain immutable invalid-output evidence.
- v6 independently reran the 93-test foundation on the exact reviewed tree.
- PSScriptAnalyzer was not installed, so no analyzer result is claimed. Parser, JSON, manifest, loader/FileList, and whitespace checks passed.
