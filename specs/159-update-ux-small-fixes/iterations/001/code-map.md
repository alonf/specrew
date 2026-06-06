# Code Map: Iteration 001

**Schema**: v1
**Feature**: 159-update-ux-small-fixes

## Changed Implementation Surfaces

| Path | Purpose | Requirements |
| --- | --- | --- |
| `scripts/specrew-update.ps1` | Central stale-module downgrade guard and actionable refusal before mutating update work. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `scripts/specrew.ps1` | Replace fixed slash-command minimum gate with project-baseline staleness compatibility and local manifest runtime resolution. | FR-006, FR-009 |
| `scripts/specrew-version.ps1` | Routine version UX reports installed/project compatibility without `0.24.0` baseline noise. | FR-006, FR-007 |
| `scripts/internal/version-check.ps1` | Remove fixed `0.24.0` slash-command minimum helper from active version infrastructure. | FR-006, FR-007 |

## Changed Active Guidance Surfaces

| Path | Purpose | Requirements |
| --- | --- | --- |
| `extensions/specrew-speckit/squad-templates/skills/specrew-version/SKILL.md` | Canonical skill template compatibility wording. | FR-006, FR-007 |
| `.agents/skills/specrew-version/SKILL.md` | Active generated Codex/agents skill copy; parity with canonical stale wording cleanup. | FR-006, FR-009 |
| `.claude/skills/specrew-version/SKILL.md` | Active generated Claude skill copy; parity with canonical stale wording cleanup. | FR-006, FR-009 |
| `.github/skills/specrew-version/SKILL.md` | Active generated GitHub skill copy; parity with canonical stale wording cleanup. | FR-006, FR-009 |
| `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Canonical governance wording; one-line approved overlap with Feature 141. | FR-006, FR-009 |
| `.github/agents/squad.agent.md` | Active generated governance copy; one-line stale wording cleanup only. | FR-006, FR-009 |

## Changed Test Surfaces

| Path | Purpose | Requirements |
| --- | --- | --- |
| `tests/integration/update-command.ps1` | Stale refusal, deterministic protected-surface snapshot, equal/newer no-regression. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-008 |
| `tests/integration/slash-command-compatibility.tests.ps1` | Active-message scan with `rg` and `Select-String` fallback. | FR-006, FR-008 |
| `tests/integration/slash-command-routing.tests.ps1` | Updated version surface expectation after fixed minimum removal. | FR-006, FR-008 |
| `tests/integration/slash-command-distribution.tests.ps1` | Fixed stale assertion wording discovered during extended adjacent test review. | FR-008 |
