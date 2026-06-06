# Quality Evidence: Iteration 001

**Feature**: 161-managed-skill-preserving-guard
**Iteration**: 001
**Status**: planning (runtime evidence collected during/after implementation)

## Stack Tooling Evidence (gate: `stack-tooling-evidence`)

| Surface | Selected Tooling | Command | Status |
| --- | --- | --- | --- |
| PowerShell deploy logic + harness | direct pwsh integration tests | `pwsh -File tests/integration/managed-skill-stuck-preserving.tests.ps1` (×2 for determinism) | planned |
| F-160 regression guard | existing fixture | `pwsh -File tests/integration/managed-runtime-sidecar.tests.ps1` | planned |
| Mechanical lenses | repo mechanical checks | `pwsh -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` | planned |
| Governance | repo validator | `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` | planned |
| Markdown | markdownlint | `npx markdownlint` on touched md files at each boundary commit | in-use |

## Scenario Outcome Record (filled by T003/T008)

| Scenario | Expectation | Observed Outcome | Run 1 | Run 2 |
| --- | --- | --- | --- | --- |
| S1 marker-present legacy dir | removed-legacy-managed-skill | pending | — | — |
| S2 user-authored legacy dir | preserved + byte-identical | pending | — | — |
| S3 current-canonical, no marker | removed (F-160 guard) | pending | — | — |
| S4 stale-canonical, no marker | PROBE — outcome captured | pending | — | — |
| S5 second deploy run | idempotent / no-change | pending | — | — |
| S6 active roots | SKILL.md + marker in all 4 roots | pending | — | — |

## Reachability Findings (filled by T004)

Pending investigation.

## Verdict Record (filled by T005; gates T006/T007)

| Field | Value |
| --- | --- |
| Outcome | pending |
| Code path | pending |
| Reachability | pending |
| Fix applied | pending |

## Quality Lens Review (gate: `quality-lens-review`)

Lens execution records land in `lenses/*.md` after implementation; see the
hardening gate for the planning baseline.
