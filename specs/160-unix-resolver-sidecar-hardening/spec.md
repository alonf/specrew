# Feature Specification: Unix Resolver Sidecar Hardening Investigations

**Feature Branch**: `160-unix-resolver-sidecar-hardening`
**Created**: 2026-06-03
**Status**: Draft
**Input**: User description: "Create a governed Specrew feature for the
Feature-140 fast-follow investigations, without blind-fixing shipped module
behavior."

## Clarifications

### 2026-06-03

- Q: Should planning prefer real Unix/macOS PowerShell reproduction first, with
  deterministic cross-platform fixture fallback?
  A: Yes. Prefer real Unix/macOS PowerShell evidence first, and use a
  deterministic cross-platform fixture as fallback when it proves equivalent
  path or marker semantics.
- No additional clarify questions are open. The feature remains
  investigation-first: reproduce before fixing, and record not-confirmed
  evidence instead of modifying behavior when a finding cannot be reproduced.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Prove Resolver Path Behavior (Priority: P1)

As a Specrew maintainer, I need a deterministic investigation of resolver path
checks so that any fix to development-tree or installed-module resolution is
based on reproduced behavior rather than suspicion.

**Why this priority**: Resolver misclassification can make Specrew run stale
installed module code even when a developer expects the local tree to be used.
That creates high trust risk, but changing resolver logic without proof could
break working installations.

**Independent Test**: The investigation can be tested independently by running
the resolver probe on Unix/macOS PowerShell or a deterministic cross-platform
path fixture and recording whether the current resolver fails before any
behavior change is made.

**Acceptance Scenarios**:

1. **Given** the current resolver uses a path expression that embeds Windows
   backslash separators, **When** the probe runs on Unix/macOS PowerShell or the
   deterministic path fixture, **Then** the evidence records whether the path is
   treated as the intended nested path or as a literal name.
2. **Given** the resolver failure is reproduced, **When** a focused fix is
   proposed or implemented, **Then** Windows and Unix regression tests prove the
   separator-safe resolver behavior.
3. **Given** the resolver failure is not reproduced, **When** the investigation
   closes, **Then** no resolver behavior is changed and the evidence states
   that the finding was not confirmed.

---

### User Story 2 - Prove Managed Refresh Marker Behavior (Priority: P1)

As a Specrew maintainer, I need a fixture that proves how `.specrew-managed`
markers are created and read during sidecar refresh so that managed files are
refreshed and user-edited unmanaged files are preserved intentionally.

**Why this priority**: Incorrect marker handling can leave canonical managed
runtime files stale or overwrite user-owned edits. Both outcomes damage trust
in init/update/start flows.

**Independent Test**: The investigation can be tested independently by running
a fresh init/update/start fixture or a direct deploy-logic fixture against
`deploy-squad-runtime.ps1` and related deployed mirrors, then comparing marker
presence, refresh behavior, and preserve behavior.

**Acceptance Scenarios**:

1. **Given** a canonical file intended to be Specrew-managed, **When** the
   fixture deploys or refreshes it, **Then** the evidence records whether the
   corresponding `.specrew-managed` marker is created and later recognized.
2. **Given** a managed file has canonical changes, **When** the fixture refreshes
   it, **Then** the file is refreshed only if marker behavior proves it is
   managed.
3. **Given** an unmanaged or user-edited file has no valid managed marker,
   **When** the fixture refreshes it, **Then** the file is preserved and the
   preserve decision is visible in evidence.

---

### User Story 3 - Close Unconfirmed Findings Without Fixes (Priority: P2)

As a Specrew maintainer, I need each suspected fast-follow to close with explicit
evidence even when not confirmed so that the project does not invent a fix or
hide unresolved uncertainty.

**Why this priority**: These are investigations, not predetermined
implementation tasks. The lifecycle must make non-reproducible findings visible
without forcing speculative code changes.

**Independent Test**: The closure can be tested by inspecting the final review
and investigation evidence to confirm each finding is marked confirmed or not
confirmed, with matching implementation scope.

**Acceptance Scenarios**:

1. **Given** either suspected issue is not reproducible, **When** the iteration
   closes, **Then** the relevant evidence records the attempted repro path,
   actual result, and "not confirmed" disposition.
2. **Given** either suspected issue is confirmed, **When** implementation
   proceeds, **Then** only the focused confirmed behavior is changed and tests
   cover the corrected path.

### Edge Cases

- The Unix/macOS repro environment is unavailable in the local workspace; the
  investigation must use a deterministic cross-platform path fixture or stop
  with explicit environment-blocked evidence instead of guessing.
- PowerShell normalizes one path construction API but not another; the evidence
  must identify the exact API and input shape under test.
- A file looks canonical by path but lacks a valid `.specrew-managed` marker;
  the fixture must treat marker semantics as authoritative unless the confirmed
  bug proves otherwise.
- Related deployed mirrors disagree with the source deploy script; the evidence
  must name the diverging file surfaces before any fix is proposed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST create resolver-path repro evidence before any
  resolver behavior is modified.
  - **Owner roles**: Spec Steward, Implementer, Reviewer
  - **Delivery window**: Iteration 001
- **FR-002**: The resolver investigation MUST run on Unix/macOS PowerShell or
  use a deterministic cross-platform path test that proves how embedded
  backslash separators are interpreted.
  - **Owner roles**: Implementer, Reviewer
  - **Delivery window**: Iteration 001
- **FR-003**: If the resolver issue is confirmed, the system MUST use
  separator-safe path construction such as normalized multi-segment `Join-Path`
  calls or an equivalent platform-safe API.
  - **Owner roles**: Implementer, Reviewer
  - **Delivery window**: Iteration 001, only after confirmation
- **FR-004**: If the resolver issue is confirmed and fixed, regression tests
  MUST cover both Windows and Unix path behavior.
  - **Owner roles**: Implementer, Reviewer
  - **Delivery window**: Iteration 001, only after confirmation
- **FR-005**: The managed-refresh investigation MUST create a fixture for fresh
  init/update/start behavior or direct deploy logic covering
  `deploy-squad-runtime.ps1` and related deployed mirrors.
  - **Owner roles**: Implementer, Reviewer
  - **Delivery window**: Iteration 001
- **FR-006**: The managed-refresh fixture MUST prove whether
  `.specrew-managed` marker creation and marker recognition are correct or
  broken.
  - **Owner roles**: Implementer, Reviewer
  - **Delivery window**: Iteration 001
- **FR-007**: If managed-refresh marker behavior is confirmed broken, the
  system MUST fix only the marker-controlled refresh/preserve behavior and
  avoid unrelated deploy-runtime changes.
  - **Owner roles**: Implementer, Reviewer
  - **Delivery window**: Iteration 001, only after confirmation
- **FR-008**: If managed-refresh marker behavior is confirmed and fixed, tests
  MUST prove that managed files refresh from canonical sources and unmanaged or
  user-edited files are preserved.
  - **Owner roles**: Implementer, Reviewer
  - **Delivery window**: Iteration 001, only after confirmation
- **FR-009**: If either suspected issue is not reproducible, the system MUST
  record investigation evidence and close that finding as not confirmed without
  changing shipped behavior for that finding.
  - **Owner roles**: Spec Steward, Reviewer
  - **Delivery window**: Iteration 001
- **FR-010**: The implementation MUST NOT push changes, touch unrelated
  untracked/runtime files, or include docs updates except where confirmed
  behavior changes make documentation necessary.
  - **Owner roles**: Implementer, Reviewer
  - **Delivery window**: Iteration 001

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery
  window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit
  reconciliation path.
- **TG-005**: Each investigation MUST carry a confirmed, not-confirmed, or
  environment-blocked disposition before review signoff.

### Key Entities *(include if feature involves data)*

- **Resolver Path Probe**: A deterministic test or script scenario that captures
  path construction inputs, platform behavior, expected resolver target, and
  actual resolver target.
- **Managed Refresh Fixture**: A temporary test fixture that models canonical
  runtime files, deployed mirrors, `.specrew-managed` markers, and user-edited
  files.
- **Investigation Finding**: A recorded disposition for each suspected issue,
  including evidence source, confirmed state, changed files if any, and
  rationale for fix or no-fix.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Both suspected issues have explicit evidence showing confirmed,
  not confirmed, or environment-blocked status before implementation closure.
- **SC-002**: No resolver or sidecar deploy behavior is changed unless a failing
  repro exists first for that behavior.
- **SC-003**: Confirmed resolver fixes include passing Windows and Unix path
  regression coverage.
- **SC-004**: Confirmed managed-refresh fixes include passing coverage for
  managed refresh and unmanaged/user-edited preserve behavior.
- **SC-005**: The final review identifies every source, mirror, test, and docs
  file touched, and confirms no unrelated untracked/runtime files were modified.

## Assumptions

- Iteration 001 is investigation-first and may end with no code change if the
  suspected failures are not reproducible.
- The preferred resolver proof is a real Unix/macOS PowerShell run; a
  deterministic cross-platform fixture is acceptable when it proves the same
  path semantics without relying on the current host OS.
- The `.specrew-managed` marker is the intended authority for
  refresh-from-canonical versus preserve-user-edits decisions unless this
  investigation proves a different current contract.
- Documentation changes are in scope only when confirmed behavior changes alter
  user-visible or maintainer-visible expectations.
- Existing unrelated workspace changes are out of scope and must remain
  untouched.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Owns investigation scope, confirmation criteria, and no-fix
  disposition language.
- **Iteration Facilitator**: Owns boundary stops, task sequencing, and explicit
  handling of blocked repro environments.
- **Capacity Model**: One focused iteration with two independently testable
  investigation slices and conditional fix work only after confirmation.
- **Drift Signals**: Drift is present if code changes appear before repro
  evidence, if docs change without confirmed behavior, or if either finding
  lacks a final disposition.
- **Human Oversight Points**: Human approval is required before planning,
  before implementation, at review signoff, during retro, and at feature
  closeout.
