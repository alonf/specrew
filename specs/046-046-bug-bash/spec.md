# Feature Specification: Specrew v0.27.2 Bug-Bash Bundle

**Feature Branch**: `046-046-bug-bash`  
**Created**: 2026-05-25  
**Status**: Draft  
**Input**: F-046 Bug-Bash Brief — Resolving 5 post-release defects empirically surfaced during the F-045 v0.27.1 closeout session on 2026-05-25.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Stale-State Detection Parity for 'retro' Boundary (Priority: P1)

An operator or agent runs `specrew start` or `specrew review` at the `retro` boundary of a feature iteration where `review.md` has already been accepted. The stale-state detector evaluates the state without triggering any false-positive late boundary sync warnings.

**Why this priority**: Stale-state false positives block normal iteration progression and lead to manual state workarounds.

**Independent Test**:

- Create a test fixture where `session_state.boundary_type` in `start-context.json` is set to `retro` and `review.md` has `Overall Verdict: accepted`.
- Run `specrew-start.ps1` and assert that no warning is emitted.
- Run negative test where `session_state.boundary_type` is set to `tasks` but `review.md` is accepted, and assert that the warning STILL fires.

**Acceptance Scenarios**:

1. **Given** a project has its boundary type at `retro` and `review.md` is accepted, **When** stale-state check runs, **Then** no warning is emitted.
2. **Given** a project has its boundary type at `tasks` and `review.md` is accepted, **When** stale-state check runs, **Then** a warning is emitted.

---

### User Story 2 - Atomic Inline Boundary Verdict Recording (Priority: P1)

An agent or developer runs `sync-boundary-state.ps1` to advance a boundary (e.g., to `iteration-closeout` or `feature-closeout`). The script atomically advances the `session_state.boundary_type` AND appends to `boundary_enforcement.verdict_history` and updates `last_authorized_boundary` inline without requiring a manual `specrew start` re-entry.

**Why this priority**: Prevents cursor-to-audit-trail drift which breaks downstream governance validation.

**Independent Test**:

- Run `sync-boundary-state.ps1 -BoundaryType iteration-closeout` against a mock `start-context.json`.
- Verify that both `session_state.boundary_type` and `boundary_enforcement.last_authorized_boundary` have advanced to `iteration-closeout`.
- Verify that `boundary_enforcement.verdict_history` has a new, fully formed audit row.

**Acceptance Scenarios**:

1. **Given** a project has boundary enforcement enabled, **When** `sync-boundary-state.ps1` is invoked, **Then** both `session_state` and `boundary_enforcement` sections are updated atomically.

---

### User Story 3 - accepted Artifact Protection in Scaffolding (Priority: P1)

A developer or agent re-runs `scaffold-review-artifact.ps1`, `scaffold-retro-artifact.ps1`, or `scaffold-reviewer-artifacts.ps1`. The scaffolders inspect target files and preserve any existing accepted verdicts, annotations, or evidence, instead writing the new stubs to sibling `.pending` files and printing a warning.

**Why this priority**: Prevents loss of human-annotated review evidence during subsequent runs.

**Independent Test**:

- Create an existing `review.md` with `Overall Verdict: accepted`.
- Run `scaffold-review-artifact.ps1` and verify that the original `review.md` is unchanged, a `review.md.pending` is created, and a clear console warning is printed.

**Acceptance Scenarios**:

1. **Given** a target markdown file exists with a populated verdict or task pass/fail evidence, **When** any scaffolder is re-run, **Then** the existing file is preserved and scaffolding outputs to a `.pending` file.

---

### User Story 4 - Resilient Prose-Name Boundary Translation (Priority: P2)

An operator runs `sync-boundary-state.ps1` with a common prose boundary alias (such as `implement` or `spec`). The tool transparently maps it to its canonical name (`review-signoff` or `specify`) without failing, or emits a highly clear suggestion if an invalid name is provided.

**Why this priority**: Simplifies user interaction and prevents script failures due to minor nomenclature variances.

**Independent Test**:

- Invoke `sync-boundary-state.ps1 -BoundaryType implement` and verify it succeeds and synchronizes to `review-signoff`.
- Invoke `sync-boundary-state.ps1 -BoundaryType invalid` and verify it throws a clean error listing all valid canonical boundaries and aliases.

**Acceptance Scenarios**:

1. **Given** an operator provides a common prose alias, **When** boundary sync runs, **Then** the alias is mapped to the canonical boundary name.

---

### User Story 5 - Bounded Scope and Known Non-Defect Documentation (Priority: P3)

The team records a running `findings.md` log detailing all Repros, Root Causes, and Validation Criteria. It also includes a detailed documentation note explaining that the skill-catalog warning fired because the directory existed but was empty, proving auto-repair works on all start paths.

**Why this priority**: Maintains alignment and prevents re-discovery of known non-defects.

**Independent Test**:

- Confirm `findings.md` is fully populated and checked.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The stale-state detector MUST treat `retro` as a valid allowed boundary when `review.md` is accepted.
- **FR-002**: `sync-boundary-state.ps1` MUST update `boundary_enforcement.last_authorized_boundary` and append to `boundary_enforcement.verdict_history` inline (Option A atomicity) when boundary enforcement is active.
- **FR-003**: The boundary sync helper MUST check if the target boundary is already authorized to avoid duplicate history lines or invalid backward moves.
- **FR-004**: All scaffolders MUST check if target files contain populated verdicts (e.g. `Overall Verdict: accepted`) or non-stub verdicts before overwriting, instead writing to a sibling `.pending` file with a console warning.
- **FR-005**: `sync-boundary-state.ps1` and `Invoke-SpecrewBoundaryStateSync` MUST remove their static `[ValidateSet(...)]` restriction and dynamically map common prose aliases (`implement` -> `review-signoff`, `spec` -> `specify`, etc.) to canonical names or throw helpful errors.
- **FR-006**: Feature-intake documentation MUST record all bug details in a durable `findings.md` ledger.
- **FR-007**: Any changes to `extensions/specrew-speckit/scripts/` MUST be mirrored in `.specify/extensions/specrew-speckit/scripts/` to maintain parity.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Story 1 maps to FR-001.
- **TG-002**: Story 2 maps to FR-002, FR-003.
- **TG-003**: Story 3 maps to FR-004.
- **TG-004**: Story 4 maps to FR-005.
- **TG-005**: Story 5 maps to FR-006.
- **TG-006**: FR-007 is a global governance constraint applying to all extension edits.

### Key Entities *(include if feature involves data)*

- **BoundaryState**: Represents the active boundary, history of authorized verdicts, and transition cursor.
- **ScaffoldArtifact**: Represents review/retro markdown files that are generated and protected.
- **BugFinding**: Represents findings in `findings.md`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of start invocations at the `retro` boundary with an accepted `review.md` pass without stale-state warnings.
- **SC-002**: 100% of `sync-boundary-state.ps1` runs atomically synchronize both cursor and verdict history.
- **SC-003**: 0 accepted files are overwritten by scaffolders. Sibling `.pending` files are generated instead.
- **SC-004**: Common prose aliases are mapped to canonical names with 100% accuracy.
- **SC-005**: 0 unresolved findings in the `findings.md` ledger.
- **SC-006**: 0 failing integration tests.

## Assumptions

- The bug-bash is confined to the five listed defects only.
- Existing legacy and non-bug behaviors remain unchanged.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Codex (session executor) under requestor authority from Alon Fliess.
- **Iteration Facilitator**: Squad Coordinator.
- **Capacity Model**: Single-iteration bug-bash defect-bundle closure.
- **Drift Signals**: Spec-to-plan/task mismatch, unresolved findings, pointer drift.
- **Human Oversight Points**: Specify completion, before-implement, retro, feature-closeout.
