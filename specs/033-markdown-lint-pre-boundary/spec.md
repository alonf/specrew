# Feature Specification: Markdown Lint Pre-Boundary Auto-Fix Discipline

**Feature Branch**: `chore-088-markdown-lint-pre-boundary`
**Proposal**: [Proposal 088](../../proposals/088-markdown-lint-pre-boundary-auto-fix-discipline.md)
**Created**: 2026-05-22
**Status**: Draft
**Version**: v0.24.3 slice (process-optimization bundle, slot 2)

## Clarifications

### Session 2026-05-22

- **Q: Should the gate auto-apply markdownlint fixes and AUTO-COMMIT them, or auto-apply and require the Crew to commit?** → **A: Auto-apply only; require the Crew to commit. Auto-commit would obscure the lint fixes from the audit trail. Manual commit produces a clean `chore(lint):` commit visible in git history.**

- **Q: How does the gate behave when markdownlint-cli isn't available (e.g., offline machine, npm registry blocked)?** → **A: Emit a `[markdownlint-gate] markdownlint-cli unavailable; skipping gate (warning)` line and proceed with the boundary sync. Same graceful degradation pattern as the validator's missing-git handling.**

## User Scenarios & Testing

### User Story 1 — Boundary sync auto-fixes lint and halts for commit (Priority: P1)

A Crew member finishes implementation work and invokes `Invoke-SpecrewBoundaryStateSync` (typically via the canonical sync slash commands per Proposal 090). The new pre-sync gate runs `markdownlint-cli --fix` on the changed `.md` files, auto-applies fixes, and HALTS the sync with a clear directive: "auto-fixed N files; commit the fixes and re-run sync." The Crew commits the auto-fixed files in a `chore(lint):` commit and re-invokes the sync, which now passes.

**Why this priority**: Primary user journey. Eliminates the catch-fix-retry cycle that's been costing ~10-15 min per occurrence on every PR.

**Independent Test**: Modify a markdown file to introduce an MD032 violation, stage, invoke boundary-sync. Expect HALT with directive + auto-applied fix visible in `git diff`.

**Acceptance Scenarios**:

1. **Given** changed `.md` files contain auto-fixable violations (MD032/MD047/MD009/MD027), **When** boundary-sync runs, **Then** the gate auto-applies fixes and HALTS with a clear `commit the fixes and re-run sync` directive (AC1, AC3).
2. **Given** no `.md` files in diff, **When** boundary-sync runs, **Then** the gate is a no-op (passes silently) (AC2).

---

### User Story 2 — Unfixable violations surface clearly (Priority: P1)

A Crew member introduces a markdown violation that markdownlint-cli cannot auto-fix (e.g., MD013 line-too-long, MD024 duplicate-heading). The gate runs `--fix` (no-op for that rule), then runs a second pass without `--fix` to detect remaining violations. It HALTS the sync with `file:line: rule` messages and a directive to fix manually.

**Why this priority**: Semantic violations need human attention. Auto-fix isn't enough.

**Independent Test**: Add a duplicate heading to a markdown file, invoke boundary-sync. Expect HALT with `file:line: MD024 duplicate-heading` message.

**Acceptance Scenarios**:

1. **Given** changed `.md` files contain unfixable violations, **When** boundary-sync runs, **Then** gate HALTS with `file:line: rule` messages (AC4).
2. **Given** a mix of fixable + unfixable violations, **When** gate runs, **Then** fixable ones get auto-applied AND unfixable ones surface in the HALT message (AC4).

---

### User Story 3 — Graceful degradation when markdownlint-cli is unavailable (Priority: P2)

A Crew member runs on an offline machine where `npx --yes markdownlint-cli` fails (no Node.js, network blocked, etc.). The gate emits a warning and proceeds with the boundary sync. The Crew doesn't get stuck.

**Why this priority**: Resilience. The gate shouldn't be a hard blocker on environments that don't support it.

**Independent Test**: Mock `npx` to return non-zero. Invoke boundary-sync. Expect warning + sync proceeds.

**Acceptance Scenarios**:

1. **Given** `npx --yes markdownlint-cli` fails to launch, **When** gate runs, **Then** warning emitted AND sync proceeds normally (AC5).

---

### User Story 4 — Gate auto-scopes via Proposal 083's base-ref helper (Priority: P1)

The gate only checks `.md` files in the current diff (per `Get-SpecrewLocalScopeBaseRef` from Proposal 083). On a feature branch with no `.md` changes, the gate doesn't invoke `markdownlint-cli` at all.

**Why this priority**: Performance. Don't lint unchanged files; matches the auto-scope discipline established by Proposal 083.

**Independent Test**: Branch with 0 changed `.md` files → invoke boundary-sync. Expect 0 markdownlint invocations.

**Acceptance Scenarios**:

1. **Given** 0 changed `.md` files in current diff, **When** gate runs, **Then** `markdownlint-cli` not invoked AND gate completes in <100ms (AC6).
2. **Given** N changed `.md` files, **When** gate runs, **Then** only those N files are passed to markdownlint-cli (AC6).

---

## Functional Requirements

- **FR-001**: System MUST add a helper function `Get-ChangedMarkdownFiles` to `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) that reuses `Get-SpecrewLocalScopeBaseRef` (from Proposal 083) to identify `.md` files in the current diff (AC6).

- **FR-002**: System MUST add a helper function `Invoke-MarkdownLintAutoFix` to `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) that:
  - Accepts a list of `.md` file paths
  - Invokes `npx --yes markdownlint-cli --fix` against those files
  - Detects which files (if any) were modified by `--fix` via SHA256 hash comparison (before vs after). Hash-based detection is more robust than `git diff --quiet` because it handles untracked files correctly.
  - Returns a structured result with `AutoFixedFiles` (array of modified file paths) and `UnfixableViolations` (array of `file:line: rule` strings from a follow-up no-fix pass) (AC1, AC4).

- **FR-003**: `Invoke-SpecrewBoundaryStateSync` (in `scripts/internal/sync-boundary-state.ps1`) MUST invoke a new pre-sync gate function `Invoke-PreBoundaryMarkdownLintGate` BEFORE writing any state files (AC1, AC3).

- **FR-004**: The pre-sync gate MUST:
  - Call `Get-ChangedMarkdownFiles` to identify scoped `.md` files
  - If 0 files: pass silently (no-op)
  - If 1+ files: call `Invoke-MarkdownLintAutoFix`
  - If `Invoke-MarkdownLintAutoFix` returns `AutoFixedFiles.Count > 0`: throw with directive "auto-fixed N file(s); review the diff, commit the fixes as 'chore(lint): auto-fix markdownlint violations', then re-run boundary-sync"
  - If `UnfixableViolations.Count > 0`: throw with `file:line: rule` messages and directive to edit manually (AC1, AC4).

- **FR-005**: When `markdownlint-cli` invocation fails (e.g., npx returns non-zero with "command not found"), the gate MUST emit `[markdownlint-gate] markdownlint-cli unavailable; skipping gate (warning)` and proceed without throwing (AC5).

- **FR-006**: Mirror parity MUST be preserved across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` for `shared-governance.ps1`.

- **FR-007**: Integration tests in `tests/integration/boundary-sync-markdownlint-gate.tests.ps1` MUST cover: clean files (no-op), auto-fixable violations (HALT + auto-fix applied), unfixable violations (HALT with file:line), markdownlint unavailable (warn + proceed), auto-scope discipline (0 changed `.md` files → no invocation).

- **FR-008**: CHANGELOG.md MUST contain an entry under `Changed` (or `Added`) referencing Proposal 088, the empirical motivation (3 catch-fix-retry cycles in one day), and the new gate behavior.

## Out of Scope

- Auto-commit of lint fixes (Crew commits manually for audit trail)
- Memoization of lint results (deferred to Proposal 086 Pillar 1 composition)
- Pre-commit git hook (boundary-sync gate is the Specrew-managed enforcement point)
- PSScriptAnalyzer auto-fix (limited tool support; future enhancement)

## Acceptance Criteria Summary

| AC | Verifies | Trace |
|---|---|---|
| AC1 | Gate auto-applies fixes + HALTS with commit directive | FR-002, FR-003, FR-004 |
| AC2 | Gate is a no-op when 0 `.md` files in diff | FR-001, FR-004 |
| AC3 | Gate fires BEFORE state-file writes | FR-003 |
| AC4 | Unfixable violations surface clearly with file:line | FR-002, FR-004 |
| AC5 | Graceful degradation when markdownlint-cli unavailable | FR-005 |
| AC6 | Auto-scope via Proposal 083's base-ref helper | FR-001 |

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
