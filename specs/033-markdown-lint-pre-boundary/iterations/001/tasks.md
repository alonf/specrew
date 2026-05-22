# Tasks: Markdown Lint Pre-Boundary Auto-Fix Discipline (Proposal 088)

**Feature**: 033-markdown-lint-pre-boundary
**Proposal**: 088
**Version**: v0.24.3
**Spec**: [spec.md](../../spec.md)
**Plan**: [plan.md](plan.md)
**Branch**: `chore-088-markdown-lint-pre-boundary`
**Capacity**: 5.25 story_points

---

## Executive Summary

**Goal**: Add a pre-sync gate to `Invoke-SpecrewBoundaryStateSync` that auto-fixes markdownlint violations at boundary time, eliminating the catch-fix-retry cycle that's cost ~30 min today across 3 PRs.

**Scope**: 2 helpers + 1 integration point + tests + closeout.

**User Stories**: US-1 through US-4
**Functional Requirements**: FR-001 through FR-008
**Acceptance Criteria**: AC1 through AC6

---

## Phase 1: Setup & Context

### T001: Verify Implementation Context (0.25 SP)

**Acceptance Criteria**:

- [X] On branch `chore-088-markdown-lint-pre-boundary` off main
- [X] `shared-governance.ps1` located at `extensions/specrew-speckit/scripts/`
- [X] `sync-boundary-state.ps1` located at `scripts/internal/`
- [X] `Get-SpecrewLocalScopeBaseRef` (from Proposal 083) confirmed available for reuse
- [X] Mirror paths confirmed at `.specify/extensions/specrew-speckit/`

**Owner**: Spec Steward
**Trace**: All FRs (orientation)

---

## Phase 2: Helpers

### T002: Add Get-ChangedMarkdownFiles Helper (0.5 SP)

**Objective**: Helper that returns `.md` files in current diff, scoped via Proposal 083's base-ref helper.

**Acceptance Criteria**:

- [X] Add `Get-ChangedMarkdownFiles` to `extensions/specrew-speckit/scripts/shared-governance.ps1`
- [X] Reuses `Get-SpecrewLocalScopeBaseRef` from Proposal 083 to identify base ref
- [X] Returns array of `.md` file paths in the diff (empty array if base ref undetectable)
- [X] Filters out files outside the project root (defensive)
- [X] Mirror at `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` matches byte-for-byte

**Owner**: Implementer
**Trace**: FR-001, AC6

---

### T003: Add Invoke-MarkdownLintAutoFix Helper (1.0 SP)

**Objective**: Helper that runs markdownlint-cli --fix + detects auto-fixed files + collects unfixable violations.

**Acceptance Criteria**:

- [X] Add `Invoke-MarkdownLintAutoFix` to `extensions/specrew-speckit/scripts/shared-governance.ps1`
- [X] Accepts: `-MarkdownFiles` (array of paths) and `-ProjectRoot`
- [X] Invokes `npx --yes markdownlint-cli --fix` against the files
- [X] Detects which files were modified via SHA256 hash comparison (before vs after `--fix`); hash-based detection avoids false positives on untracked files compared to `git diff --quiet`
- [X] Runs a SECOND pass (no `--fix`) to collect remaining unfixable violations as `file:line: rule` strings
- [X] If `npx`/`markdownlint-cli` fails to launch (exit code indicating "not found"), returns `MarkdownLintUnavailable=$true` flag
- [X] Returns `[pscustomobject]@{ AutoFixedFiles = @(); UnfixableViolations = @(); MarkdownLintUnavailable = $false }`
- [X] Mirror matches byte-for-byte

**Owner**: Implementer
**Trace**: FR-002, FR-005, AC1, AC4, AC5

---

## Phase 3: Boundary Sync Integration

### T004: Integrate Pre-Sync Gate (1.0 SP)

**Objective**: Add `Invoke-PreBoundaryMarkdownLintGate` function + call from `Invoke-SpecrewBoundaryStateSync` BEFORE state-file writes.

**Acceptance Criteria**:

- [X] Add `Invoke-PreBoundaryMarkdownLintGate` function in `scripts/internal/sync-boundary-state.ps1`
- [X] Function calls `Get-ChangedMarkdownFiles` first; if 0 results, returns silently (no-op)
- [X] If 1+ results, calls `Invoke-MarkdownLintAutoFix`
- [X] If `MarkdownLintUnavailable=$true`: emit `[markdownlint-gate] markdownlint-cli unavailable; skipping gate (warning)` and return
- [X] If `AutoFixedFiles.Count > 0`: throw with directive "auto-fixed N file(s); review the diff, commit as 'chore(lint): auto-fix markdownlint violations', then re-run boundary-sync"
- [X] If `UnfixableViolations.Count > 0`: throw with `file:line: rule` messages
- [X] Call `Invoke-PreBoundaryMarkdownLintGate` at the START of `Invoke-SpecrewBoundaryStateSync`, BEFORE any state-file writes

**Owner**: Implementer
**Trace**: FR-003, FR-004, AC1, AC2, AC3, AC4

---

## Phase 4: Testing

### T005: Integration Tests (1.5 SP)

**Acceptance Criteria**:

- [X] Create `tests/integration/boundary-sync-markdownlint-gate.tests.ps1`
- [X] Test 1: clean .md file → gate is a no-op (no-op assertion via test fixture)
- [X] Test 2: auto-fixable violation (MD032) → gate HALTs with directive + auto-fix applied to file
- [X] Test 3: unfixable violation (MD024 duplicate-heading) → gate HALTs with file:line message
- [X] Test 4: markdownlint-cli unavailable (mock npx) → gate emits warning + proceeds
- [X] Test 5: 0 changed .md files (test fixture: empty branch diff) → gate not invoked
- [X] Test exits 0 when all assertions pass

**Owner**: Test Owner
**Trace**: FR-007

---

## Phase 5: Mirror Parity + Closeout

### T006: Mirror Parity Sweep (0.25 SP)

- [X] `shared-governance.ps1` SHA256-matches across primary and mirror

**Owner**: Implementer
**Trace**: FR-006

---

### T007: CHANGELOG + INDEX + Closeout Artifacts (0.5 SP)

**Acceptance Criteria**:

- [X] CHANGELOG.md entry under `### Changed` (or `### Added`) referencing Proposal 088 and empirical motivation
- [X] proposals/INDEX.md: 088 moves from Candidate to Shipped
- [X] iterations/001/review.md (self-review)
- [X] iterations/001/retro.md
- [X] iterations/001/drift-log.md
- [X] iterations/001/state.md (final state)
- [X] iterations/001/dashboard.md (iteration snapshot)
- [X] iterations/001/quality/hardening-gate.md
- [X] closeout-dashboard.md (feature-level)

**Owner**: Spec Steward + Retro Facilitator
**Trace**: FR-008

---

### T008: Branch Push + PR + Copilot Review + Merge (0.25 SP)

**Acceptance Criteria**:

- [X] Branch pushed to origin
- [X] PR opened with full description
- [X] Wait for GitHub Copilot PR review per memory `[[feedback-check-github-copilot-pr-review-2026-05-22]]`
- [X] Address every finding
- [X] CI passes
- [X] PR merged with `--merge`

**Owner**: Spec Steward (acting maintainer)
**Trace**: closeout

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
