# Feature Specification: Retire Top-Level Evaluation Surface

**Feature Branch**: `170-retire-evaluation-surface`
**Created**: 2026-06-06
**Status**: Draft
**Input**: Proposal 169 (`proposals/169-retire-top-level-evaluation-surface.md`) — retire `evaluation/` as a top-level public surface while preserving the process-quality scorer as test support. The implementation was produced ahead of governance by a Codex session on 2026-06-06 and adopted onto this branch as commit `3b6a3e0d` ("adoption snapshot"); this feature verifies, finishes, and governs that work rather than re-implementing it.

## Clarifications

### Session 2026-06-06

Clarify was **skipped with recorded rationale**, human-approved at the specify
verdict (boundary commit `c7d32a7f`): the spec is sourced from decision-complete
Proposal 169 (AC1-AC6 enumerated and maintainer-approved), the intake lens
workshop resolved the only open design question (scorer classification,
human-confirmed), and the requirements checklist records zero unresolved QC
items with no `[NEEDS CLARIFICATION]` markers in this spec. The same verdict
explicitly authorized proceeding to plan with the workshop record standing as
the design decision for this non-substantive 1-2 SP hygiene slice.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Repository reads truthfully (Priority: P1)

A contributor or evaluator browsing the repository no longer finds a top-level `evaluation/` directory implying Specrew ships a maintained public evaluation harness. The repository surface matches the actual maintained behavior: a deterministic process-quality regression helper that lives with the tests that consume it.

**Why this priority**: The stale surface actively misleads readers about what the product does — the core motivation of Proposal 169.

**Independent Test**: `git ls-files evaluation/` returns nothing; repo browsing and user-facing docs contain no claim of a current `evaluation/` workflow.

**Acceptance Scenarios**:

1. **Given** the feature branch, **When** listing tracked files, **Then** no tracked path begins with `evaluation/` (AC1).
2. **Given** the user-facing docs, **When** searching for `evaluation/`, **Then** the only mentions explain the retirement (e.g., "through the CI integration tests rather than a public `evaluation/` surface") rather than advertising a current workflow (AC5).

---

### User Story 2 - CI keeps its lifecycle-quality regression net (Priority: P1)

CI continues to validate lifecycle artifact and phase adherence through the process-quality scorer, now located at `tests/support/process-quality-scorer.ps1`, with the two existing integration tests as the supported entry points. The move is invisible to CI semantics.

**Why this priority**: The scorer is the live value being preserved; losing it would regress deterministic lifecycle-quality checking.

**Independent Test**: Run both integration tests on the feature branch; both pass, and the generated report lands outside any tracked top-level surface.

**Acceptance Scenarios**:

1. **Given** the moved scorer, **When** `tests/integration/process-quality-scorer.ps1` runs, **Then** it passes (AC2).
2. **Given** the moved scorer, **When** `tests/integration/process-quality-report.ps1` runs, **Then** it passes and writes its generated report to untracked scratch/test-result space (AC3).
3. **Given** the multi-host lifecycle smoke test, **When** it runs, **Then** it parses the moved scorer and preserves the Linux-safe forward-slash path assertion (AC4).

---

### User Story 3 - The move is traceable, history is preserved (Priority: P2)

A maintainer can reconstruct why the scorer was moved rather than deleted from the proposal/index audit trail, and historical specs, retros, and frozen test fixtures that mention `evaluation/` remain untouched as shipped evidence.

**Why this priority**: Audit-trail and history-preservation discipline; secondary to the behavioral outcomes above.

**Independent Test**: Proposal 169 exists on `main` with INDEX entry recording the classification decision; historical artifacts (e.g., `tests/unit/fixtures/015-*` fixtures) are byte-identical to their pre-feature state.

**Acceptance Scenarios**:

1. **Given** `proposals/INDEX.md` and Proposal 169, **When** a maintainer reads them, **Then** the move-not-delete classification rationale is recorded (AC6).
2. **Given** historical specs/retros/fixtures mentioning `evaluation/`, **When** the feature closes, **Then** they are unmodified (out-of-scope guard).

### Edge Cases

- Scorer invoked from a non-repo-root working directory: path resolution must not regress (`tests/integration/project-path-resolution-regression.ps1` covers the moved path).
- Report scratch directory absent on a fresh clone: the report test must create or tolerate the missing directory rather than fail.
- Windows vs Linux path separators: the smoke test's forward-slash assertion must hold against the moved scorer path on both families (AC4).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST NOT contain a tracked top-level `evaluation/` directory (AC1).
- **FR-002**: The process-quality scorer MUST live at `tests/support/process-quality-scorer.ps1`, classified as test infrastructure — not product runtime, not a public evaluation harness (workshop decision, human-confirmed).
- **FR-003**: `tests/integration/process-quality-scorer.ps1` MUST pass using the moved scorer (AC2).
- **FR-004**: `tests/integration/process-quality-report.ps1` MUST pass and write its generated report outside any tracked top-level surface (AC3).
- **FR-005**: The multi-host lifecycle smoke test MUST parse the moved scorer and preserve the Linux-safe forward-slash path assertion (AC4).
- **FR-006**: User-facing docs MUST NOT advertise `evaluation/` as a current public workflow; explanatory retirement wording is permitted (AC5).
- **FR-007**: Maintainer-facing proposal/index surfaces MUST record why the scorer was moved rather than deleted (AC6).
- **FR-008**: Historical specs, retros, and frozen test fixtures referencing `evaluation/` MUST remain unmodified (history preservation).

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: US1 → FR-001, FR-006; US2 → FR-002..FR-005; US3 → FR-007, FR-008.
- **TG-002**: Owner roles — Implementer (FR-001..FR-006), Spec Steward (FR-007, FR-008), Reviewer (verification evidence for all FRs).
- **TG-003**: All FRs deliver in iteration 001 (single-iteration slice, 1-2 SP).
- **TG-004**: Known conflict: the implementation predates this spec (adoption snapshot `3b6a3e0d`). Reconciliation path: the implement phase verifies the adopted changes against FR-001..FR-008 and fixes any gap before review; drift is recorded in `drift-log.md`.

### Key Entities

- **Process-quality scorer**: PowerShell test-support library (`tests/support/process-quality-scorer.ps1`) computing lifecycle artifact/phase adherence scores; consumed only by the two integration-test entry points.
- **Generated process-quality report**: transient test output; written to untracked scratch/test-result space; never a tracked repository artifact.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `git ls-files evaluation/` returns zero entries on the feature branch.
- **SC-002**: Both process-quality integration tests exit 0 on the feature branch, with the report written to untracked space.
- **SC-003**: The multi-host lifecycle smoke test passes, including the scorer-parse and forward-slash path assertions.
- **SC-004**: A scan of active surfaces (`docs/`, `extensions/`, `.specify/`, `.github/`, `.squad/`, `scripts/`, `tests/`, `templates/`) finds no `evaluation/` reference other than (a) intentional retirement-explanation wording, (b) frozen historical fixtures under `tests/unit/fixtures/`, and (c) archived historical ledgers (e.g., `.squad/decisions-archive.md`) preserved unmodified under the same history-preservation rule as FR-008. *(Class (c) added at implement: the T005 scan surfaced archive-ledger hits the original wording did not enumerate; recorded in the drift log.)*
- **SC-005**: Proposal 169 is recorded in `proposals/INDEX.md` with the classification rationale, and its status is flipped at feature closeout.

## Assumptions

- The adopted implementation (commit `3b6a3e0d`) is substantially complete; the remaining work is verification, gap-fixing, and governance evidence — not greenfield implementation.
- CI job names and the process-quality test semantics are unchanged (proposal out-of-scope list).
- Frozen fixtures under `tests/unit/fixtures/015-public-readiness-pass/` intentionally keep their `evaluation/` mentions as historical test inputs.
- The deferred outcome-quality scorer remains out of scope; any future public evaluation surface would be designed fresh as its own governed slice.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Spec Steward (delegated: claude).
- **Iteration Facilitator**: Planner (delegated: claude).
- **Capacity Model**: story points; 20 SP iteration cap; this slice is 1-2 SP in a single iteration.
- **Drift Signals**: `drift-log.md` per iteration; `validate-governance.ps1` at every boundary commit; repo-wide `evaluation/` reference scan at review (SC-004).
- **Human Oversight Points**: specify, clarify, plan, tasks, before-implement, review-signoff, retro, iteration-closeout, feature-closeout (per `boundary_enforcement.policy_classes`).
