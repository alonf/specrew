# Feature Specification: PR Review Integration (Minimal Viable Slice)

**Feature Branch**: `chore-089-pr-review-integration`
**Proposal**: [Proposal 089](../../proposals/089-pr-review-integration-address-pr-review-gate.md)
**Created**: 2026-05-22
**Status**: Draft
**Version**: v0.24.3 slice (final slot)

## Clarifications

### Session 2026-05-22

- **Q: Which pillars of Proposal 089 ship here?** → **A: Minimal viable slice — the artifact schema + host-detection helper + a soft (non-blocking) validator warning when the artifact is missing under host-with-auto-review conditions. Hard-blocking gate + new boundary insertion deferred to Proposal 089 follow-up.**

- **Q: What about Copilot-found issues during the v0.24.3 bundle?** → **A: This session has been demonstrating the discipline live — every PR's Copilot findings were captured + addressed in fix commits. F-038's artifact templates and validator soft-warning institutionalize the pattern so future PRs don't depend on the maintainer remembering.**

- **Q: How is host detected?** → **A: `gh` CLI presence + git remote URL containing `github.com` → infer GitHub Copilot reviewer is available. Crude but correct in 99% of cases. Other hosts (GitLab, Bitbucket) fall through to "no auto-review" until their detection is added.**

## User Scenarios & Testing

### User Story 1 — Soft warning surfaces when artifact missing (Priority: P1)

A developer (or the Crew) runs the validator on an iteration that has a feature-closeout boundary state recorded but no `pr-review-resolution.md` artifact, on a repo where GitHub Copilot review is available. Validator emits a soft warning suggesting the artifact be created. NOT blocking.

**Acceptance Scenarios**:

1. **Given** a host with auto-review, **When** validator runs on an iteration past pr-open boundary without resolution artifact, **Then** emits soft warning `[pr-review-soft-warning] ... resolve Copilot findings before merging.` (AC1).
2. **Given** the same setup with the artifact present, **When** validator runs, **Then** no warning (AC2).
3. **Given** a host without auto-review (no `gh` CLI / non-GitHub remote), **When** validator runs, **Then** no warning regardless of artifact state (AC3).

---

### User Story 2 — Artifact template + helper for resolution path (Priority: P1)

The Crew (or maintainer) has a documented schema for the artifact. `Get-SpecrewPrReviewResolutionPath` helper returns the canonical path so the Crew always writes to the right location.

**Acceptance Scenarios**:

1. **Given** an iteration directory, **When** `Get-SpecrewPrReviewResolutionPath` invoked, **Then** returns `specs/<feature>/iterations/<N>/pr-review-resolution.md` (AC4).
2. **Given** the spec markdown, **When** inspected, **Then** documents the canonical schema (findings, outcome fix, root-cause fix, won't fix) (AC5).

---

### User Story 3 — Cross-platform host detection (Priority: P2)

`Test-HostProvidesAutomatedPrReview` returns a hashtable with `Active`, `Host`, and `Reviewer` properties. Works on Windows/Linux/macOS.

**Acceptance Scenarios**:

1. **Given** `gh` is installed AND remote contains `github.com`, **When** test runs, **Then** returns `@{ Active = $true; Host = 'github'; Reviewer = 'copilot-pull-request-reviewer' }` (AC6).
2. **Given** `gh` not installed OR remote doesn't contain `github.com`, **When** test runs, **Then** returns `@{ Active = $false }` (AC7).

---

## Functional Requirements

- **FR-001**: System MUST add `Get-SpecrewPrReviewResolutionPath` helper to `shared-governance.ps1` (+ mirror). Takes `-IterationPath`; returns the conventional artifact path `specs/<feature>/iterations/<N>/pr-review-resolution.md`.

- **FR-002**: System MUST add `Test-HostProvidesAutomatedPrReview` helper to `shared-governance.ps1` (+ mirror). Returns `@{ Active = bool; Host = string; Reviewer = string }`. GitHub detection: `gh` CLI executable on PATH AND git remote URL contains `github.com`. Other hosts return `Active = $false` (extensible via future PRs).

- **FR-003**: System MUST add a soft (non-blocking) validator surface that, when an iteration's state shows it's past the pr-open boundary AND the host has auto-review available AND the artifact is missing, emits `[pr-review-soft-warning] ...` to stdout. Soft = does NOT contribute to exit code; informational only.

- **FR-004**: System MUST NOT block PR merge or iteration closeout when the artifact is missing. The full hard-blocking gate is explicitly out of scope here (deferred to follow-up Proposal 089 Pillar 2 work).

- **FR-005**: Mirror parity MUST be preserved across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` for `shared-governance.ps1`.

- **FR-006**: Integration tests at `tests/integration/pr-review-integration.tests.ps1` MUST cover: helpers present + mirror parity; path helper returns canonical location; host detection logic; soft warning is non-blocking.

- **FR-007**: CHANGELOG.md MUST contain an entry under `Changed` referencing Proposal 089, motivation, and composition with the Copilot review discipline live-demonstrated through this bundle.

## Out of Scope

- **Hard-blocking lifecycle gate** at address-pr-review boundary — deferred to follow-up Proposal 089 Pillar 2 work (requires boundary state machine extension).
- **New sync command** for address-pr-review — deferred. Crew authors `pr-review-resolution.md` manually for now.
- **Multi-host detection beyond GitHub** — GitLab Code Suggestions, Bitbucket, etc. covered in future PRs.
- **Automated Copilot finding extraction** — Crew/maintainer manually populates the artifact based on PR comments; future enhancement could `gh api repos/.../pulls/<N>/comments` and pre-fill.
- **CI enforcement** — soft-warning is local-only; CI doesn't enforce.

## Acceptance Criteria Summary

| AC | Verifies | Trace |
|---|---|---|
| AC1 | Soft warning when artifact missing on supported host | FR-003 |
| AC2 | No warning when artifact present | FR-003 |
| AC3 | No warning on unsupported host | FR-002, FR-003 |
| AC4 | Path helper returns canonical location | FR-001 |
| AC5 | Spec documents the schema | FR-007 |
| AC6 | Host detection positive | FR-002 |
| AC7 | Host detection negative | FR-002 |

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
