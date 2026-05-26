# Findings Ledger: F-047 Trust-Hardening Bug-Bash Bundle

**Feature**: `047-bug-bash-trust-hardening`
**Release target**: v0.27.3
**Status**: implementation complete; awaiting review sign-off

> Each item records: Surface · Repro / what-shows-the-gap · Validation Criterion · Evidence Pointer · Status.

## Item 1 — Handoff-block validator enforcement (FR-001/002/003)

- **Surface**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror), `shared-governance.ps1` (helper).
- **Repro / gap**: Across F-046 (Antigravity) + PlanningPoC, boundary commits landed with no preceding handoff block and nothing detected it.
- **Validation criterion**: WARN (not FAIL) emitted for missing block; dashboard-missing diagnosis differentiates non-Specrew-managed vs auto-render regression; wrong-location WARN for ephemeral-dir artifacts.
- **Evidence pointer**: `tests/integration/non-specrew-session-bypass.tests.ps1`; scoped validator output shows WARN-only missing-handoff, dashboard-diagnosis, and wrong-location checks.
- **Status**: implemented.

## Item 2 — Post-compaction handoff-drop acceptance test (FR-004)

- **Surface**: `tests/integration/non-specrew-session-bypass.tests.ps1`.
- **Repro / gap**: 2026-05-26 PlanningPoC (commit f06491e5) — proper handoff pre-compaction, dropped immediately post-compaction.
- **Validation criterion**: missing handoff + compaction marker ⇒ WARN; fails-closed if Item 1 detector regresses.
- **Evidence pointer**: `tests/integration/non-specrew-session-bypass.tests.ps1` post-compaction fixture.
- **Status**: implemented.

## Item 3 — Review-diagrams mermaid template hardening (FR-005/006/007)

- **Surface**: `validate-governance.ps1` (+ mirror), `scaffold-reviewer-artifacts.ps1` (+ mirror), per-host Reviewer charters.
- **Repro / gap**: 2026-05-25 PlanningPoC iter-001 review passed lint with ` ```text ` ASCII trees; no validator caught the missing Mermaid.
- **Validation criterion**: soft-WARN when no ` ```mermaid ` block; scaffolder emits Mermaid skeleton; charter directive present.
- **Evidence pointer**: `tests/integration/non-specrew-session-bypass.tests.ps1`; `tests/integration/reviewer-artifacts.ps1`; reviewer charter template directive.
- **Status**: implemented.

## Item 4 — Downstream-language audit + regex check (FR-008/009)

- **Surface**: the coordinator HANDOFF prose — `scripts/specrew-start.ps1`'s handoff/decision sections + `extensions/specrew-speckit/prompts/coordinator-*.md`; `validate-governance.ps1` regex (scoped to `=== SPECREW HANDOFF ===` regions).
- **Repro / gap**: 2026-05-26 PlanningPoC handoff prose referenced an internal feature number a downstream user cannot decode.
- **Scope discovery (2026-05-26, planning)**: the brief's named `installed-instructions/` directory **does not exist** in the repo. A repo-wide scan for the three patterns found **2,432 occurrences across 250 files** — almost all legitimate internal references in `proposals/`, `docs/`, `specs/`, `tests/`, `.squad/decisions/`, `CHANGELOG.md`. Item 4 is therefore scoped to the **downstream-user-facing HANDOFF prose only** (FR-008 pinned scope); internal artifact trees are explicitly excluded so the rule does not WARN on the ~2,400 legitimate internal references. The `SPECREW HANDOFF` literal currently appears in user-facing form in `scripts/specrew-start.ps1` (34 pattern hits in its prose).
- **Validation criterion**: 0 internal refs remain in in-scope handoff prose; validator WARNs on a planted ref inside a handoff region and does NOT WARN on the same token in a proposal/spec.
- **Evidence pointer**: `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `scripts/specrew-start.ps1`, and `tests/integration/non-specrew-session-bypass.tests.ps1`.
- **Status**: implemented.

## Item 5 — Skill-catalog empty-dir UX (FR-010)

- **Surface**: `scripts/internal/skill-catalog-state.ps1`, `detect-hosts.ps1`.
- **Repro / gap**: empty skill dir ⇒ `HasMissingRoots=false` (no repair) but per-host check WARNs "missing" — contradictory signal.
- **Validation criterion**: empty skill root ⇒ `HasMissingRoots=true`, auto-repair fires, no residual WARN.
- **Evidence pointer**: `scripts/internal/skill-catalog-state.ps1`; `tests/integration/non-specrew-session-bypass.tests.ps1`.
- **Status**: implemented.

## Item 6 — Feature-closeout SDLC actions in HANDOFF (FR-011)

- **Surface**: per-host coordinator-prompt templates; optional sync-boundary-state post-closeout output.
- **Repro / gap**: F-046 (Antigravity) emitted only "review the dashboard" at feature-closeout; F-045 (Codex) emitted the full PR sequence — host inconsistency.
- **Validation criterion**: every per-host closeout HANDOFF template contains push/PR/review/merge action items.
- **Evidence pointer**: `scripts/specrew-start.ps1`; `tests/integration/non-specrew-session-bypass.tests.ps1`.
- **Status**: implemented.

## Item 7 — tasks-progress.yml resume reconciliation (FR-012)

- **Surface**: `scripts/specrew-start.ps1` regeneration path.
- **Repro / gap**: 2026-05-26 Claude resume on F-046 — snapshot read all-pending and said "Start T001" despite tasks.md all `[x]`.
- **Validation criterion**: regeneration derives per-task status from `tasks.md` `[x]` + `state.md` (tasks.md authoritative).
- **Evidence pointer**: `scripts/internal/task-progress.ps1`; `tests/integration/non-specrew-session-bypass.tests.ps1`; `tests/integration/start-command.ps1`.
- **Status**: implemented.

## Release / parity evidence

- **Version evidence**: `.specrew/config.yml`, `extensions/specrew-speckit/extension.yml`, `.specify/extensions/specrew-speckit/extension.yml`, and `Specrew.psd1` now declare `0.27.3`; `CHANGELOG.md` and `README.md` include the release line.
- **Mirror parity evidence**: SHA256 parity passed for `shared-governance.ps1`, `validate-governance.ps1`, and `scaffold-reviewer-artifacts.ps1`.
- **Verification evidence**: `tests/integration/non-specrew-session-bypass.tests.ps1`, `tests/integration/reviewer-artifacts.ps1`, `tests/integration/substantive-interaction-model-handoff-test.ps1`, `tests/integration/start-command.ps1`, script syntax parse, mechanical checks, and scoped governance validation all passed.

## Follow-up findings (out of F-047 scope)

- **Cross-feature authorization-cursor bleed**: `boundary_enforcement.last_authorized_boundary` is global (not feature-scoped); F-046's T004 backward-guard then refuses to record a new feature's early-boundary verdicts. Belongs to the verdict-history atomic refactor follow-up. Handled operationally in F-047 via a one-time cursor reset at the before-implement gate.
