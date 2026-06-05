# Feature Specification: Specrew Update Downgrade Guard and Compatibility Message Cleanup

**Feature Branch**: `159-update-ux-small-fixes`  
**Created**: 2026-06-05  
**Status**: Draft  
**Input**: User description: "Implement Proposal 159 Tier 1 only, clean stale 0.24.0 slash-command compatibility messaging, avoid Feature 141 and Proposal 160 worktrees, and validate according to Proposal 145."

## Scope Source

This feature implements the Tier 1 bug fix from `proposals/159-specrew-update-module-staleness-guard.md`.
Tier 2 self-update / re-dispatch is explicitly out of scope.

The work is intentionally separate from:

- Feature 141 design-lens intake/runtime work.
- Proposal 160 path-resolver and managed-skill sidecar work in the separate worktree.
- Any release promotion, beta publish, or stable tag operation.

## Clarifications

### Session 2026-06-05

- Q: Should the stale-module guard apply only to default Specrew asset refresh, or to every mutating `specrew update` scope? → A: Apply it broadly to every mutating update scope, including `--all`, `--specrew`, `--spec-kit`, and `--squad`; an older running Specrew module must not mutate a newer-baseline project at all.
- Q: Should `0.24.0` be removed everywhere or only from active user-facing/generated guidance? → A: Remove or reword it from active generated governance, active slash-command skill templates, and routine update/version UX; keep historical references in changelogs, closed specs, proposals, and migration history where they describe the actual release line.
- Q: How should Proposal 145 be applied for this small fix? → A: Apply Proposal 145 at review-signoff through branch hygiene, functional correctness, non-functional review, code quality, test-integrity checks, collision/scope review, claim-to-evidence verification, and an explicit gap ledger.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Refuse Project Downgrade From Stale Module (Priority: P1)

As a Specrew project maintainer, I want `specrew update` to refuse when the running Specrew module is older than the project baseline, so a stale local install cannot silently downgrade project governance/runtime assets.

**Why this priority**: This is the data-integrity bug from Proposal 159. A single routine update command can currently rewrite a newer project backward.

**Independent Test**: Can be tested by creating a Specrew-managed scratch project, setting `.specrew/config.yml` `specrew_version` newer than the running module version, running mutating `specrew update`, and verifying the command exits non-zero before any protected file changes.

**Acceptance Scenarios**:

1. **Given** a project records `specrew_version` newer than the running module version, **When** the user runs mutating `specrew update`, **Then** the command refuses before modifying `.specrew/config.yml`, `.specify/extensions/**`, `.squad/**`, host skill surfaces, or generated runtime assets.
2. **Given** a stale running module refusal, **When** the command reports the error, **Then** it tells the user to run `Update-Module Specrew` or set `SPECREW_MODULE_PATH` to a matching development tree.
3. **Given** the command refuses, **When** the user inspects the working tree, **Then** the project baseline and managed assets remain byte-for-byte unchanged from before the command.

---

### User Story 2 - Preserve Equal/Newer Update Behavior (Priority: P2)

As a maintainer with a current or newer running module, I want `specrew update` to behave as it did before this fix, so normal update flows are not slowed or narrowed.

**Why this priority**: The guard must be precise; it should prevent downgrades without changing valid refresh/update behavior.

**Independent Test**: Can be tested by running the existing update-command integration flow with project baseline equal to or older than the running module and confirming the expected config refresh, extension refresh, and per-platform reporting remain unchanged.

**Acceptance Scenarios**:

1. **Given** the running module version equals the project `specrew_version`, **When** mutating `specrew update` runs, **Then** current Specrew asset refresh behavior remains unchanged.
2. **Given** the running module version is newer than the project `specrew_version`, **When** mutating `specrew update` runs, **Then** current upgrade-forward behavior remains unchanged.
3. **Given** `specrew update --info` is run, **When** the project has any baseline state, **Then** info mode remains read-only.

---

### User Story 3 - Remove Active Old-Baseline Noise (Priority: P3)

As a normal Specrew user, I do not want active generated governance or routine version/update UX to present `0.24.0` as a current minimum compatibility baseline, because Specrew is still alpha and there are no supported active projects that old.

**Why this priority**: The current generated governance and version skill text creates stale operational noise and makes old compatibility history look like a current support policy.

**Independent Test**: Can be tested by scanning active generated governance templates, version/update skill templates, and routine `specrew version` output/help for current-baseline `0.24.0` messaging while leaving historical changelog/spec/proposal records intact.

**Acceptance Scenarios**:

1. **Given** active generated governance templates are refreshed, **When** a user reads routine lifecycle or slash-command guidance, **Then** they do not see `0.24.0` described as the current minimum compatibility baseline.
2. **Given** a user runs routine `specrew version` help or report, **When** the command displays slash-command compatibility details, **Then** it does not present `0.24.0` as a current user-facing minimum baseline.
3. **Given** historical artifacts such as proposals, closed specs, changelog entries, or release records mention `0.24.0`, **When** the cleanup runs, **Then** those historical records remain unchanged unless they are active generated guidance.

### Edge Cases

- A project config has no `specrew_version`: mutating update should keep existing behavior and not refuse only because the baseline is absent.
- A project config has an unparsable `specrew_version`: mutating update should fail clearly rather than guessing downgrade safety.
- A module or project version includes prerelease display metadata: downgrade comparison should use the existing semantic-version comparison behavior unless planning identifies a safer local comparator.
- A mutating update is requested with `--spec-kit`, `--squad`, or `--all`: no project mutation should occur from an older running Specrew module than the project baseline.
- Historical `0.24.0` references in archived specs/proposals must not be rewritten as part of this small-fix scope.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `specrew update` MUST read the running Specrew module/source version and the target project's recorded `.specrew/config.yml` `specrew_version` before any mutating update action.
  - **Owner role**: Implementer
  - **Delivery window**: Iteration 001
- **FR-002**: For any mutating `specrew update` scope, if the running Specrew version is older than the project baseline, the command MUST exit non-zero before changing `.specrew/config.yml`, `.specify/extensions/**`, `.squad/**`, host skill surfaces, or generated runtime assets.
  - **Owner role**: Implementer
  - **Delivery window**: Iteration 001
- **FR-003**: The downgrade-refusal message MUST be actionable and MUST mention both `Update-Module Specrew` and `SPECREW_MODULE_PATH` as remediation paths.
  - **Owner role**: Implementer
  - **Delivery window**: Iteration 001
- **FR-004**: When the running Specrew version is equal to or newer than the project baseline, existing mutating `specrew update` behavior MUST remain unchanged.
  - **Owner role**: Implementer
  - **Delivery window**: Iteration 001
- **FR-005**: `specrew update --info` MUST remain read-only and MUST NOT mutate the project as part of downgrade checking.
  - **Owner role**: Implementer
  - **Delivery window**: Iteration 001
- **FR-006**: Active generated governance, active slash-command skill templates, and routine version/update UX MUST NOT present `0.24.0` as the current minimum slash-command compatibility baseline.
  - **Owner role**: Spec Steward
  - **Delivery window**: Iteration 001
- **FR-007**: Historical records MAY retain `0.24.0` references when those references document the actual Feature 024 release line, prior proposals, closed specs, changelog history, or migration history.
  - **Owner role**: Spec Steward
  - **Delivery window**: Iteration 001
- **FR-008**: Tests MUST cover downgrade refusal, protected-file no-mutation on refusal, equal/newer no-regression, and active `0.24.0` messaging cleanup.
  - **Owner role**: Reviewer
  - **Delivery window**: Iteration 001
- **FR-009**: Implementation MUST NOT modify Proposal 160 path-resolver/sidecar surfaces or Feature 141 design-lens intake surfaces except for unavoidable shared governance text explicitly approved during planning.
  - **Owner role**: Reviewer
  - **Delivery window**: Iteration 001

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path.
- **TG-005**: Review MUST apply Proposal 145 discipline: branch hygiene, functional correctness, non-functional review, code quality, test integrity, collision/scope safety, and claim-to-evidence checks.

### Key Entities *(include if feature involves data)*

- **Running Specrew Version**: The version carried by the module/source tree executing `specrew update`, currently derived from the active extension/module manifest.
- **Project Specrew Baseline**: The target project's recorded `.specrew/config.yml` `specrew_version`.
- **Update Scope**: The requested update target set: Specrew, Spec Kit, Squad, or combinations such as `--all`.
- **Protected Managed Assets**: Files and directories that must not change during stale-module refusal: `.specrew/config.yml`, `.specify/extensions/**`, `.squad/**`, host skill roots, generated runtime assets, and refreshed templates.
- **Active Compatibility Message**: User-facing or generated governance text that normal users see during current update/version/lifecycle operation, excluding historical records.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A stale-module mutating `specrew update` exits non-zero and preserves protected files byte-for-byte in the regression test.
- **SC-002**: The refusal output includes `Update-Module Specrew` and `SPECREW_MODULE_PATH`.
- **SC-003**: Equal and newer module scenarios continue to pass the existing update-command regression coverage.
- **SC-004**: Active generated governance and routine version/update surfaces no longer show `0.24.0` as a current minimum compatibility baseline.
- **SC-005**: Proposal 145 review evidence explicitly classifies the implementation as implemented, enforced, observable, and documented, with a gap ledger for any missing dimension.
- **SC-006**: Changed-file review confirms no intentional edits landed in Feature 141 design-lens intake work or Proposal 160 path-resolver/sidecar work.

## Assumptions

- Tier 1 is the only Proposal 159 scope in this feature; no `--self-update` or child-process module update is implemented.
- Existing version parsing helpers should be reused where practical instead of adding a new semantic-version stack.
- Active `0.24.0` cleanup targets generated/routine UX and tests that enforce that stale user-facing claim, not archived historical artifacts.
- The current branch `159-update-ux-small-fixes` is the dedicated branch for this small-fix feature.
- Existing unrelated working-tree changes are out of scope and must not be reverted or folded into this feature.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Preserve Proposal 159 scope, keep Tier 2 out, and define the active-vs-historical `0.24.0` cleanup boundary.
- **Iteration Facilitator**: Keep this as one small iteration with no collision against Feature 141 or Proposal 160 worktrees.
- **Capacity Model**: Story points; target 5 SP for a single Tier 1 iteration with 1 SP buffer for test/message cleanup.
- **Drift Signals**: Trace FR/SC coverage in `tasks.md`; record any scope broadening in `drift-log.md`; review changed-file list against Feature 141 and Proposal 160 watchouts.
- **Human Oversight Points**: Human approval after specify, after plan/tasks/before-implement, and before implementation begins.
