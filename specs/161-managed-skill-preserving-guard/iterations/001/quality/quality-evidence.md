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

## Scenario Outcome Record (T003, 2026-06-06)

| Scenario | Expectation | Observed Outcome | Run 1 | Run 2 |
| --- | --- | --- | --- | --- |
| S1 marker-present legacy dir | removed-legacy-managed-skill | removed | pass | pass |
| S2 user-authored legacy dir | preserved + byte-identical | preserved, byte-identical | pass | pass |
| S2b non-catalog `specrew-*` dir | preserved (no-definition path) | preserved | pass | pass |
| S3 current-canonical (slash), no marker | removed (F-160 guard) | removed | pass | pass |
| S3g current-canonical (generic), no marker | removed (F-160 guard) | removed | pass | pass |
| S4 stale-canonical (slash), no marker | PROBE — outcome captured | **preserved (frozen)** | recorded | recorded |
| S4g stale-canonical (generic), no marker | PROBE — outcome captured | **preserved (frozen)** | recorded | recorded |
| S5 second deploy run | idempotent / no-change | idempotent | pass | pass |
| S6 active roots | SKILL.md + marker in all 4 roots | deployed | pass | pass |
| S7 real-historical generic (v0.21-era), no marker | PROBE — outcome captured | **preserved (frozen)** | recorded | recorded |

Identical OUTCOME-SUMMARY across both full runs (SC-001 determinism).

## Reachability Findings (T004)

See the iteration evidence note (`../evidence.md`): released Specrew
v0.21.0–v0.23.0 (2026-05-18..19) deployed generic + slash skills into
`.copilot/skills` with no markers and no front matter; markers were never
written to that root by any version; generic template content drifted from
v0.26.0 (2026-05-23). The four generic legacy dirs from that window are
frozen forever on upgrade. Slash dirs are recovered by the legacy-signature
fallback and are NOT stuck.

## Verdict Record (T005; gates T006/T007)

| Field | Value |
| --- | --- |
| Outcome | **CONFIRMED** (misclassified AND reachable) |
| Code path | `deploy-squad-runtime.ps1::Test-IsManagedLegacySkillDirectory` — (a) generic-kind equality fallback vs CURRENT LegacyContent (reachable, S7); (b) leading-`---` front-matter heuristic (S4/S4g, synthetic) |
| Reachability | v0.21.0–v0.23.0 bootstrap → v0.26.0+ upgrade; artifacts: 4 generic skill dirs in `.copilot/skills` |
| Fix applied | pending human release of T006 at the verdict boundary stop |

## Quality Lens Review (gate: `quality-lens-review`)

Lens execution records land in `lenses/*.md` after implementation; see the
hardening gate for the planning baseline.
