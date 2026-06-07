# Feature Specification: New-User Profile Setup Copy

**Feature Branch**: `172-profile-setup-ux-copy`
**Created**: 2026-06-07
**Status**: Draft
**Input**: Proposal 170 (`proposals/170-new-user-profile-setup-copy.md`)

## User Scenarios & Testing

### User Story 1 - First-run setup is understandable (Priority: P1)

A new Specrew user configuring the Crew Interaction Profile can understand that
each setting controls Specrew's collaboration behavior, not the user's job title
or self-rated professional seniority.

**Independent Test**: Inspect the setup metadata and prompt-normalization helper
through the user-profile integration test.

**Acceptance Scenarios**:

1. **Given** first-run setup, **When** the scale is displayed, **Then** it
   describes guide/collaborate/concise behavior and recommended defaults.
2. **Given** each decision area, **When** the setup asks for a value, **Then**
   the question asks how much guidance the user wants in that area.

### User Story 2 - Compatibility is preserved (Priority: P1)

Existing user profiles, schema keys, and runtime persona IDs continue to work
unchanged while the first-run prompt becomes clearer.

**Independent Test**: Existing F-049/F-141 profile integration assertions remain
green.

**Acceptance Scenarios**:

1. **Given** a legacy profile, **When** Specrew loads it, **Then** the stable
   `expertise.*` keys and persona IDs are unchanged.
2. **Given** first-run setup, **When** the user presses Enter, **Then** the value
   is normalized to `auto`.

## Requirements

- **FR-001**: First-run setup MUST explain that the profile controls how much
  guidance Specrew gives across decision areas.
- **FR-002**: First-run setup MUST use behavior-centered scale wording:
  guide me, collaborate, be concise, and auto/recommended defaults.
- **FR-003**: Each setup decision area MUST have setup-specific prompt metadata
  that asks how much guidance the user wants.
- **FR-004**: Blank or whitespace first-run input MUST normalize to `auto`.
- **FR-005**: Case-insensitive `auto` MUST normalize to canonical `auto`.
- **FR-006**: Numeric input from 1 through 10 MUST normalize to canonical string
  form; out-of-range or invalid input MUST be rejected.
- **FR-007**: Existing `DisplayLabel`, `ExpertiseKey`, and `PersonaId` values
  MUST remain unchanged.

## Success Criteria

- **SC-001**: `tests/integration/f049-i003-intake-engine-tests.ps1` exits 0.
- **SC-002**: Markdown lint passes for proposal and feature artifacts touched
  by this slice.
- **SC-003**: `git diff` shows no persisted-profile schema migration.

## Governance Alignment

- **Spec Steward**: Spec Steward (delegated: codex).
- **Implementer**: Implementer (delegated: codex).
- **Reviewer**: Reviewer discipline follows Proposal 145: claims must map to
  actual file changes and test output, not narrative assertion.
- **Drift Signals**: `iterations/001/drift-log.md`.
- **Human Oversight Points**: The maintainer directly authorized proposal,
  worktree, and implementation on 2026-06-07.
