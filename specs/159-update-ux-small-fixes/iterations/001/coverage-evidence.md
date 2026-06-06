# Coverage Evidence: Iteration 001

**Schema**: v1
**Feature**: 159-update-ux-small-fixes
**Recorded**: 2026-06-06

## Tests Run

| Command | Exit | Coverage |
| --- | --- | --- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\update-command.ps1` | 0 | Stale refusal, deterministic no-mutation snapshots, equal/newer update behavior, info-mode read-only. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\slash-command-compatibility.tests.ps1` | 0 | Active `0.24.0` cleanup scan, default scanner, `Select-String` fallback, version command tolerance. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\slash-command-routing.tests.ps1` | 0 | Dispatcher/version surface compatibility after fixed-minimum removal. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\version-checks.tests.ps1` | 0 | Existing version mismatch warning behavior remains non-blocking and actionable. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\slash-command-distribution.tests.ps1` | 0 | Active skill distribution and repaired post-bootstrap slash-surface assertion. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\slash-command-multi-path.tests.ps1` | 0 | Generated skill copies remain byte-identical across active roots. |
| PowerShell parser tokenization over changed `.ps1` files | 0 | Syntax sanity for changed scripts and integration tests. |
| `pwsh -File .specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` | 0 | Lifecycle/governance validation. |

## Requirement Coverage

| Requirement | Evidence |
| --- | --- |
| FR-001 | `scripts/specrew-update.ps1`; update-command Test 0. |
| FR-002 | update-command Test 0 stale refusal across all mutating scopes. |
| FR-003 | update-command Test 0 refusal output assertions. |
| FR-004 | update-command Tests 3, 5, and 6. |
| FR-005 | update-command Test 2. |
| FR-006 | slash-command compatibility Test 3 active-message scan. |
| FR-007 | Active scan excludes historical records; no historical artifact cleanup was performed. |
| FR-008 | This test matrix plus parser/governance checks. |
| FR-009 | Review-signoff collision check and narrow generated-surface diffs. |

## Known Warnings

- Governance validation still reports two pre-existing repository warnings outside Feature 159: Feature 048 dashboard auto-render regression and Feature 140 verdict-history warning.
