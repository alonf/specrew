# Feature Specification: Review Evidence Integrity

**Feature Branch**: `028-review-evidence-integrity`  
**Created**: 2025-03-19  
**Status**: Clarified  
**Source**: Proposal 073 (Review Evidence Integrity: Pre-Review Commit Gate + Form-vs-Meaning Detection)

---

## Overview

The Specrew review phase produces evidence artifacts (`review-diagrams.md`, `code-map.md`, `dependency-report.md`, `coverage-evidence.md`) that downstream reviewers rely on to understand what changed in an iteration. These artifacts are computed via `git diff baseline...HEAD`, which assumes implementation work is committed by review time. **That assumption is currently not enforced**, creating a form-vs-meaning gap where an iteration can declare tasks complete but contain zero committed changes—making review evidence silently empty while reviewer-facing signals show "work complete."

This feature hardens the review boundary by:

1. Adding a pre-review commit gate validator rule
2. Providing a reusable form-vs-meaning parity helper for other validators
3. Emitting defensive warnings when review evidence is incomplete
4. Enabling re-runnability of review artifact scaffolders (idempotent updates)
5. Composing as the foundational slice of Proposal 030's quality hardening bundle

---

## Clarifications

### Session 2025-03-19

- Q1 (Severity for Partial Completion): **Resolved** → Option 3 (threshold-based severity). **Decision**: Zero-diff (declared ≥1 task complete AND git diff empty) is a hard failure boundary and triggers an `error`-level validation failure. Partial mismatches (declared > observed, but both > 0) are treated as `warning`-level unless observed diff is zero, in which case they become `error`. This preserves the form-vs-meaning integrity check while allowing graceful degradation for partial progress.
- Q2 (Baseline Ref Flexibility): **Resolved** → Option 1 (Fixed to declared baseline). **Decision**: The pre-review validator MUST always use the baseline reference already recorded in iteration metadata (e.g., `state.md`). No override flags or auto-detection logic; the baseline is part of the iteration's contract and must be explicit and auditable. This ensures methodology enforcement and clear accountability for baseline selection.
- Q4 (Handling Edge Case – Empty Iteration): **Resolved** → Option 3 (null context check). **Decision**: Validator logic will check declared task count only. If declared task count = 0 AND git diff is empty, treat iteration as legitimate (spec/clarify phase, no implementation required) and do not raise failure. If declared task count ≥ 1 AND git diff is empty, treat as form-vs-meaning gap and raise `error`-level failure. This avoids false positives for spec-only iterations while catching incomplete implementation handoffs.
- Q3 (Human Annotation Preservation on Re-run): **Resolved** → Option 2 (Overwrite and warn). **Decision**: When scaffolder is re-invoked with `-Force`, artifacts are cleanly overwritten with current git diff data. Default behavior uses an interactive confirmation prompt (`-Confirm:$true`) to warn the user that human annotations will be lost. Non-interactive contexts (CI/CD, automation) can use `-Confirm:$false` to bypass the prompt. Human annotations must be preserved by developers in `review.md` (separate from generated artifacts), per documentation convention. This ensures accurate, current review evidence while providing escape hatches for automation.
- Q5 (Integration with Optional CLI / Proposal 033): **Resolved** → Option 1 (Defer to 033). **Decision**: Feature 028 implements only the scaffolder `-Force` flag for idempotent re-runnability. The optional `specrew review-evidence regenerate` CLI command surface is deferred to Proposal 033 for wrapping and integration with the broader governance CLI. This simplifies 028's scope and allows 033 to own the CLI design surface.
- Q6 (Composition with Proposal 030 – Test-FormMeaningParity API Stability): **Resolved** → Option 1 (Immutable API with generic-comparator design constraint). **Decision**: The `Test-FormMeaningParity` helper signature and return structure are frozen as v1 immutable API. The helper will follow a generic-comparator design pattern that allows 030 to add new specialized helpers without modifying this one. During planning, sketch the signature and validate it covers 2–3 anticipated Proposal 030 use cases before implementation. This ensures stability for downstream consumers while allowing 030 to extend without breaking changes.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 – Reviewer Detects Uncommitted Implementation (Priority: P1)

A human or agent reviewer encounters an iteration marked "complete" in `state.md` with all task verdicts showing "pass", but review diagrams are empty or missing. With this feature, the reviewer can:

1. **See a loud warning** at the top of `review-diagrams.md` and related artifacts stating that declared completion does not match the git diff
2. **Understand the root cause** via clear messaging pointing to the pre-review commit gate and Proposal 073
3. **Know how to remediate** by returning to the implementation phase to commit the work

**Why this priority**: This is the primary user-facing outcome—reviewers must never be silently misled by empty evidence.

**Independent Test**: A complete iteration whose `state.md` declares tasks finished but has an empty `git diff baseline...HEAD` triggers a loud, visible warning in all review artifacts. The reviewer can read the artifact and immediately understand the issue without needing to debug the lifecycle.

**Acceptance Scenarios**:

1. **Given** `state.md` declares task completion AND `git diff baseline...HEAD` is empty, **When** review artifacts are generated, **Then** a prominent warning appears at the top of `review-diagrams.md` and other scaffolded artifacts
2. **Given** a reviewer reads the warning, **When** they look for next steps, **Then** they see guidance to commit the implementation and re-run scaffold with `scaffold-reviewer-artifacts.ps1 -Force`
3. **Given** implementation is later committed, **When** review artifacts are regenerated, **Then** the warning disappears and diagrams are populated accurately

---

### User Story 2 – Validator Gate Blocks Incomplete Iterations (Priority: P1)

A Squad member or agent attempts to advance an iteration from `implement` → `review` when implementation work is not committed. The `validate-governance.ps1` script:

1. **Detects the gap** by reading `state.md` for completed task count and comparing to `git diff baseline...HEAD`
2. **Emits a HARD validation failure** with category `review-evidence-integrity`, severity `error`
3. **Provides remediation guidance** including file:/// URLs to `state.md` and the baseline ref

**Why this priority**: This gate enforces the methodology boundary—implementation must be committed before review can advance. Without this, the form-vs-meaning gap is not caught.

**Independent Test**: Running `validate-governance.ps1` against an iteration whose `state.md` declares ≥1 completed task but has an empty diff produces a validation failure that blocks advancement. Running the same validator on a clean iteration (both declared and observed completion match) produces no false-positive failures.

**Acceptance Scenarios**:

1. **Given** `state.md` declares task completion AND `git diff baseline...HEAD` is empty, **When** `validate-governance.ps1` runs, **Then** a validation failure with category `review-evidence-integrity` is emitted
2. **Given** the same iteration with both declared and committed implementation, **When** `validate-governance.ps1` runs, **Then** no false-positive failure is raised
3. **Given** an iteration with no declared task completion and empty diff (e.g., spec/clarify only), **When** `validate-governance.ps1` runs, **Then** no failure is raised

---

### User Story 3 – Test-FormMeaningParity Helper Enables Broader Form-vs-Meaning Checks (Priority: P2)

Future validator rules (and Proposal 030's broader bundle) need a reusable way to compare declared state against observed reality. This feature provides:

1. **A `Test-FormMeaningParity` helper** (PowerShell function in `shared-governance.ps1`) that accepts declared and observed counts
2. **Structured return values** (Declared, Observed, Gap, Severity) that other validators can compose into their own rules
3. **An example implementation** in the pre-review commit gate showing how to invoke the helper

**Why this priority**: This helper is the seed for Proposal 030. Without it, form-vs-meaning checks would be redundant across multiple rules. This is a P2 because it's design/architecture work that unblocks future feature slices.

**Independent Test**: The helper can be invoked independently with test-case inputs (declared=5, observed=2) and returns the expected structure without side effects. Other validators can compose it without understanding its implementation details.

**Acceptance Scenarios**:

1. **Given** a call to `Test-FormMeaningParity -Declared 10 -Observed 0`, **When** the helper returns, **Then** it contains `Gap: $true` and `Severity: error`
2. **Given** a call with `Declared 0 -Observed 0`, **When** the helper returns, **Then** it contains `Gap: $false` and `Severity: info`
3. **Given** a call with `Declared 5 -Observed 3`, **When** the helper returns, **Then** it contains `Gap: $true` and `Severity: warning` (per Q1 resolution: partial completion with both declared and observed > 0 → warning)

---

### User Story 4 – Idempotent Review Artifact Regeneration (Priority: P2)

A reviewer or Squad member wants to re-run `scaffold-reviewer-artifacts.ps1` after implementation is late-committed, without losing previously generated output or creating duplicated content.

1. **The scaffolder detects existing artifacts** and can overwrite cleanly with a `-Force` switch
2. **An interactive confirmation prompt** warns before overwriting (default `-Confirm:$true`), with `-Confirm:$false` escape hatch for non-interactive contexts
3. **Human annotations** are preserved by developers in `review.md` (separate artifact), and re-integrated after scaffolding

**Why this priority**: This ensures that even when the pre-review gate fails to fire (e.g., in an existing iteration), humans can manually refresh evidence post-commit. P2 because it's a manual fallback after P1 automation.

**Independent Test**: Running `scaffold-reviewer-artifacts.ps1` twice on the same iteration with `-Force` produces identical output without duplicates or errors. Subsequent runs with updated git history reflect the new diff accurately.

**Acceptance Scenarios**:

1. **Given** review artifacts already exist, **When** scaffolder is re-invoked with `-Force`, **Then** an interactive confirmation prompt appears warning that human annotations will be lost, and upon confirmation, artifacts are cleanly overwritten with current git diff data
2. **Given** review artifacts contain human-added notes, **When** scaffolder is re-run, **Then** developers are guided to preserve annotations in `review.md` (separate artifact) and re-integrate after scaffolding. With `-Confirm:$false`, no prompt is shown (non-interactive contexts)
3. **Given** a non-interactive context (CI/CD), **When** scaffolder is invoked with `-Confirm:$false`, **Then** the confirmation prompt is skipped and re-run proceeds immediately
4. **Given** implementation is later committed, **When** scaffolder is re-run with `-Force`, **Then** the warning disappears and diagrams reflect the new diff accurately

---

### Edge Cases

- **Empty iteration (spec/clarify only, no implementation phase)**: If declared task count = 0 and git diff is empty, no false-positive gate failure should fire
- **Partial implementation**: Some tasks committed, others not—validator should report the gap clearly (declared vs. observed counts)
- **Declared baseline only**: The pre-review gate always uses the baseline recorded in iteration metadata (`state.md`); no custom baseline override or auto-detection
- **Merge commits in diff**: Baseline ref may include merge commits—the diff calculation must handle these correctly
- **Reviewer manually edits artifacts**: Human annotations are preserved in `review.md` (separate from generated artifacts per Q3 resolution). Re-running scaffolder with `-Force` will overwrite generated artifacts after an interactive confirmation prompt (unless `-Confirm:$false` is used)

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST read `state.md` to extract the list of completed tasks in the current iteration
- **FR-002**: System MUST execute `git diff --name-only <baseline_ref>...HEAD` to determine committed file changes
- **FR-003**: Validator rule MUST emit a HARD validation failure with category `review-evidence-integrity` and severity `error` when `state.md` declares ≥1 completed task AND git diff is empty
- **FR-004**: Validator failure message MUST include file:/// URL to `state.md`, the baseline ref, and remediation hint: "Implementation tasks were marked complete but no files have been committed since baseline. Commit the implementation work before review can produce meaningful evidence."
- **FR-005**: Scaffolder MUST emit a loud warning at the top of `review-diagrams.md`, `code-map.md`, and `dependency-report.md` when form-vs-meaning gap is detected
- **FR-006**: Warning text MUST include the statement: "⚠️ **Review evidence may be misleading**: this iteration's `state.md` declares completed tasks but the git diff against baseline is empty. Implementation work may be uncommitted. See Proposal 073 and the pre-review commit gate."
- **FR-007**: Scaffolder MUST continue producing output even when gap is detected (do not block—this is a downstream signal)
- **FR-008**: `Test-FormMeaningParity` helper MUST accept parameters for Declared count and Observed count and return a structured object with fields: Declared, Observed, Gap (bool), Severity (error|warning|info)
- **FR-009**: `scaffold-reviewer-artifacts.ps1` MUST support a `-Force` switch to cleanly overwrite existing review artifacts, with default interactive confirmation via `-Confirm:$true` and a non-interactive escape hatch `-Confirm:$false` for CI/CD contexts
- **FR-010**: When `-Force` is used and `-Confirm:$true` (default), scaffolder MUST emit a warning prompt: "⚠️ Re-running with `-Force` will overwrite existing review artifacts. Human annotations should be maintained in `review.md` and re-integrated after scaffolding. Continue?"
- **FR-011**: System MUST be idempotent—re-running scaffolder on the same iteration produces consistent output without duplicates
- **FR-012**: Documentation convention: human annotations and reviewer notes MUST be maintained in `review.md` (separate artifact), not in generated review artifacts (`review-diagrams.md`, `code-map.md`, etc.)

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 (Reviewer detects uncommitted work) maps to FR-005, FR-006, FR-007 (scaffolder warnings)
- **TG-002**: User Story 2 (Validator gate blocks incomplete iterations) maps to FR-001, FR-002, FR-003, FR-004 (validator rule)
- **TG-003**: User Story 3 (Test-FormMeaningParity helper) maps to FR-008 (helper function)
- **TG-004**: User Story 4 (Idempotent regeneration) maps to FR-009, FR-010, FR-011, FR-012 (interactive confirmation, idempotent scaffolder, annotation preservation convention)
- **TG-005**: Implementation owner: Squad (engineering team driving Specrew development)
- **TG-006**: Validator rule execution phase: Implement→Review transition (or `before-review` governance gate)
- **TG-007**: Target iteration: Feature 028 implementation iteration (estimated 15–20 story points per Proposal 073)
- **TG-008**: Any conflict between form (declared state) and meaning (committed evidence) MUST be surfaced as a validation failure, never silently masked as "below threshold"

### Key Entities

- **Iteration State** (`state.md`): Declares completed tasks, task verdicts, build/test evidence for the current iteration
- **Git Baseline**: Reference commit (e.g., `baseline...HEAD`) used to compute diff for the iteration
- **Review Evidence Artifacts**: `review-diagrams.md`, `code-map.md`, `dependency-report.md`, `coverage-evidence.md`—computed from git diff
- **Validation Result**: Structured output from `validate-governance.ps1` with category, severity, and remediation guidance
- **Form-vs-Meaning Gap**: The difference between declared task completion (form) and committed file changes (meaning)

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pre-review commit gate (Pillar 1): Running `validate-governance.ps1` against an iteration with declared completion + empty diff produces a validation failure that blocks advancement, while iterations with matching declared and observed completion produce no false positives
- **SC-002**: Form-vs-meaning detection (Pillar 2): The `Test-FormMeaningParity` helper function is production-ready and composable by other validator rules, with clear API documentation
- **SC-003**: Scaffolder warnings (Pillar 3): When form-vs-meaning gap is detected, a loud warning ⚠️ is emitted at the top of every review artifact, replacing the previous silent "below threshold" message
- **SC-004**: Review-evidence re-runnability (Pillar 4): `scaffold-reviewer-artifacts.ps1 -Force` safely re-invokes on previously-scaffolded iterations with interactive confirmation prompt (default `-Confirm:$true`) and `-Confirm:$false` escape hatch, producing consistent, duplicate-free output
- **SC-005**: Human annotation preservation convention: Documentation confirms that human annotations belong in `review.md`, not in generated artifacts. Developers understand that re-running scaffolder with `-Force` will overwrite generated artifacts and prompts provide guidance on this convention
- **SC-006**: Integration test coverage: `tests/integration/review-evidence-integrity.tests.ps1` passes all scenarios (gap detected when applicable, no false positives, re-runnability after late commits, confirmation prompt behavior with and without `-Confirm:$false`)
- **SC-007**: Empirical validation: Replaying the 2026-05-21 snake-game smoke trial under this gate blocks at review-boundary advance with clear error message, instead of silently producing empty diagrams
- **SC-008**: Regression prevention: All existing iterations in Specrew dev repo (F-009 through F-072) continue to validate cleanly with no regressions
- **SC-009**: Proposal 030 composition: When Quality Hardening Bundle (030) ships, it absorbs the `Test-FormMeaningParity` helper without modification—the API defined here is the seed for 030's broader scope

---

## Assumptions

- **A1**: The `baseline` ref in each iteration's metadata (e.g., `state.md` or iteration-level config) is reliably available and correctly identifies the baseline for the iteration
- **A2**: `git diff --name-only <baseline>...HEAD` is the authoritative source of committed file changes; working-tree changes are out of scope
- **A3**: An iteration is "complete" only if `state.md` explicitly declares one or more tasks in a completed state (parsing is deterministic)
- **A4**: Empty git diff is the only form-vs-meaning gap addressed in this feature; other gaps (review verdicts ↔ test results, plan tasks ↔ implementation tasks) are deferred to Proposal 030
- **A5**: The pre-review commit gate runs in the validator governance plane (same plane as Proposal 004 validator rules)
- **A6**: Scaffolder continues to produce output even when gap is detected (do not block); the gate is the blocking mechanism
- **A7**: Existing iterations in the Specrew repo will continue to pass validation cleanly—this feature is a new rule, not a retroactive enforcement
- **A8**: The `specrew review-evidence regenerate` CLI command (Pillar 4) is optional and deferred to Proposal 033 integration; scaffolder `-Force` flag is the primary idempotent mechanism in this feature

---

## Known Limitations & Deferred Behaviors

### Merge-Commit Handling (Defer to Proposal 030)

**Limitation**: The diff computation `git diff <baseline>...HEAD` (three-dot syntax) uses the merge-base algorithm, which can produce counterintuitive results when the commit graph contains merge commits between baseline and HEAD. Specifically:

- If a feature branch is merged into the iteration's branch and then the diff is computed, the merge-base may be different from the intended baseline, potentially masking or incorrectly including files in the diff.
- This limitation does not affect linear commit histories (the most common case in Specrew's single-feature-per-iteration model), but becomes visible in complex rebase or cherry-pick scenarios.

**Rationale for Deferral**: This limitation is acknowledged here to prevent masking in Proposal 030's future work (which will add more form-vs-meaning detection rules and may generalize diff-computation logic). Feature 028 operates under the assumption that iteration baselines are well-defined and the commit history is reasonably linear. When Proposal 030 ships and adds broader form-vs-meaning verification, the merge-handling question will be revisited as part of that bundle's scope.

**Workaround (if needed)**: Ensure that each iteration's baseline is set *after* any merges in the feature branch are complete, or avoid merging during the iteration to keep the history linear. Proposal 030's governance bundle will provide more sophisticated handling.

---

## Design Decisions Requiring Clarification

The following design questions have been identified and must be resolved during the `/speckit.clarify` phase:

### Design Q1: Severity Level for Partial Completion [RESOLVED]

**Context**: In the `Test-FormMeaningParity` helper, when some tasks are declared complete but the diff shows fewer (or zero) committed changes.

**Resolution** (Session 2025-03-19): Threshold-based severity with zero-diff as hard failure boundary.

- **Zero-diff case** (declared ≥1 task, observed = 0): `error` (hard failure, blocks advancement)
- **Partial mismatch** (declared > observed, but observed > 0): `warning` (logged, non-blocking)
- **Full match** (declared = observed): `info` (no gap)

This satisfies the form-vs-meaning integrity requirement while allowing graceful handling of partial progress.

---

### Design Q2: Baseline Ref Flexibility

**Status**: ✓ **RESOLVED** (see Clarifications → Q2)

**Decision**: Fixed to declared baseline. The pre-review validator MUST always use the iteration's declared baseline reference, with no override flexibility.

- Baseline ref is read from iteration metadata (e.g., `state.md`) and is non-negotiable
- No `validate-governance.ps1 -Baseline <custom>` override flag
- No auto-detection from git history
- Baseline is part of the iteration's contract and must be explicit

**Implementation Impact**: The validator reads the baseline directly from metadata and computes `git diff <baseline>...HEAD` with that explicit ref. This ensures methodology enforcement and clear auditability—any deviation from the declared baseline is a governance violation that must be caught at the methodology level, not accommodated with override logic.

---

### Design Q3: Human Annotation Preservation on Re-run

**Status**: ✓ **RESOLVED** (see Clarifications → Q3)

**Context**: Pillar 4 (Idempotent scaffolder) allows review artifacts to be regenerated after late commits. Humans may have added notes or annotations to existing artifacts.

**Decision**: Overwrite and warn with interactive confirmation.

- Default behavior: scaffolder prompts with `-Confirm:$true` before overwriting, warning that human annotations will be lost
- Non-interactive escape hatch: `-Confirm:$false` bypasses the prompt (for CI/CD and automation)
- Artifacts are cleanly regenerated with current git diff data
- Human annotations are preserved by developers in `review.md` (separate from generated artifacts)

**Implementation Impact**: `scaffold-reviewer-artifacts.ps1 -Force` invokes an interactive confirmation prompt by default (`-Confirm:$true`). The prompt warns: "⚠️ Re-running with `-Force` will overwrite existing review artifacts. Human annotations should be maintained in `review.md` and re-integrated after scaffolding. Continue?" Non-interactive contexts can suppress the prompt with `-Confirm:$false`. This ensures accurate, current artifacts while providing escape hatches for automation and clear guidance for human developers on where to persist annotations.

---

### Design Q4: Handling Edge Case – Empty Iteration (Spec/Clarify Only)

**Status**: ✓ **RESOLVED** (see Clarifications → Q4)

**Decision**: Use null context check based on declared task count only.

- If declared task count = 0 AND `git diff baseline...HEAD` is empty → iteration is legitimate (spec/clarify phase). No validation failure.
- If declared task count ≥ 1 AND `git diff baseline...HEAD` is empty → form-vs-meaning gap detected. Raise `error`-level failure.

**Implementation Impact**: The pre-review validator will read the completed task count from `state.md` (or metadata) and use that as the sole heuristic to distinguish legitimate empty iterations from incomplete implementations. No additional metadata fields or flags are required.

---

### Design Q5: Integration with Optional CLI (Pillar 4 / Proposal 033)

**Status**: ✓ **RESOLVED** (see Clarifications → Q5)

**Decision**: Feature 028 implements only the scaffolder `-Force` flag for idempotent re-runnability. The optional `specrew review-evidence regenerate` CLI command surface is deferred to Proposal 033.

**Implementation Impact**: `scaffold-reviewer-artifacts.ps1` gains a `-Force` switch that cleanly overwrites existing artifacts. No CLI command wrapper is added in this feature; 033 will define the `specrew review-evidence regenerate` surface and invoke the scaffolder flag as its backend.

---

### Design Q6: Composition with Proposal 030 – Test-FormMeaningParity API Stability

**Status**: ✓ **RESOLVED** (see Clarifications → Q6)

**Context**: The `Test-FormMeaningParity` helper defined in Pillar 2 is the seed for Proposal 030's broader form-vs-meaning bundle. Other rules will depend on this API.

**Decision**: Immutable API (v1) with generic-comparator design constraint.

- The helper's signature and return structure are frozen; 030 adds new helpers, not modify this one
- Design follows a generic-comparator pattern that allows specialization without signature breakage
- Simple for consumers; extensibility is via composition, not modification

**Implementation Impact**: During planning, sketch the `Test-FormMeaningParity` signature and validate it covers 2–3 anticipated Proposal 030 use cases (e.g., form-vs-meaning checks for different entity types) before implementation begins. This ensures the immutable API is stable for the full scope of 030's downstream dependency.

---

## Composition with Other Proposals

| Proposal | Relationship |
|----------|---|
| **030 (Quality Hardening Bundle, draft)** | This proposal is 030's first concrete sub-slice; provides the `Test-FormMeaningParity` foundation that 030 expands with additional form-vs-meaning rules |
| **004 (Validator Hardening, shipped F-013)** | New validator rule plugs into the same validator-governance plane that 004 established |
| **042 (Specrew Integration Test Suite, candidate)** | New integration test folds into 042's broader matrix when 042 ships |
| **033 (Specrew Governance CLI, draft)** | Pillar 4's optional `specrew review-evidence regenerate` CLI surface composes with 033's `specrew` command structure |
| **054 (Pre-Merge End-to-End Lifecycle Verification Gate, candidate)** | 054 catches drift at PR-merge time across the lifecycle; 073 catches the implementation→review gap before merge is even attempted. Complementary lifecycle-stage coverage |
| **F-016 / F-066 (boundary discipline, shipped)** | The review boundary is one of the lifecycle boundaries. 073 sharpens what it means for that boundary to advance: review can't advance until implementation is committed |
| **F-026 (PR-CI lint scoping, shipped)** | The validator rule that 073 adds operates at the same plane as 026's scoping work. Both contribute to the validate-governance.ps1 surface |
| **011 (Architecture Intent Checkpoint, draft)** | 011's 8th-boundary-checkpoint pattern in `/speckit.plan` is structurally similar to the pre-review gate here. Could share governance-gate infrastructure |

---

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess (governance/quality owner)
- **Iteration Facilitator**: Squad (Specrew engineering team)
- **Capacity Model**: 15–20 story points (estimated per Proposal 073); one feature iteration
- **Drift Signals**:
  - Validator rule is invoked at implement→review boundary; any form-vs-meaning gap is surfaced as validation failure (hard blocker)
  - Scaffolder warnings appear in review artifacts when gap is detected (loud, visible signal)
  - Integration test suite (`review-evidence-integrity.tests.ps1`) validates all three scenarios; test failure = implementation drift
  - Proposal 030 integration: `Test-FormMeaningParity` API must be stable and composable without modification; API signature validated against 2–3 anticipated 030 use cases before implementation
- **Human Oversight Points**:
  - **Pre-implementation (clarify)**: Resolve design questions before planning; Q1–Q6 complete
  - **During planning**: Sketch `Test-FormMeaningParity` signature and validate against 2–3 Proposal 030 use cases before implementation begins
  - **Mid-implementation (review)**: Validator rule + scaffolder warnings must be tested against 2026-05-21 snake-game smoke trial
  - **Feature closeout**: Ensure no regressions in existing iterations (F-009 through F-072)
  - **Post-ship (Proposal 030)**: `Test-FormMeaningParity` API must not require modification when 030 absorbs it

---

## Empirical Motivation

On 2026-05-21, a fresh `specrew init` snake-game smoke test ran the full lifecycle and produced an iteration where:

- `state.md` declared `Status: completed`, `Last Completed Task: T011`, `Tasks Remaining: 0`
- `review.md` recorded 11 task verdicts, all `pass`, with build/test evidence
- Working tree contained 20+ C# files implementing the snake game (`find src tests -name '*.cs'`)
- **`review-diagrams.md` emitted: "Structure diagram omitted: modules touched (0) below threshold (3). Flow diagram omitted: entrypoints changed (0) below threshold (1)."**
- `git log` showed only Squad session-state commits; none of the implementation files were tracked
- `git status --short` showed every implementation file as `??` (untracked)

This is a textbook **form-vs-meaning gap**: the review system silently accepted the form (declared completion) without detecting the meaning (no committed changes). Review evidence appeared incomplete but not obviously broken—reviewers would see "work complete" alongside empty diagrams and be unable to distinguish between "trivial change" and "uncommitted work."

---

## References

- **Proposal 073 source**: file:///C:/Dev/Specrew/proposals/073-review-evidence-integrity.md
- **Proposal 030 (Quality Hardening Bundle)**: file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- **Proposal 004 (Validator Hardening, shipped)**: file:///C:/Dev/Specrew/proposals/004-validator-hardening.md
- **Proposal 011 (Architecture Intent Checkpoint, draft)**: file:///C:/Dev/Specrew/proposals/011-architecture-intent-checkpoint.md
- **Proposal 033 (Specrew Governance CLI, draft)**: file:///C:/Dev/Specrew/proposals/033-specrew-governance-cli.md
- **Validator script**: file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/validate-governance.ps1
- **Reviewer scaffolder**: file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1
- **Shared governance helpers**: file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/shared-governance.ps1
- **Empirical evidence**: Snake-game smoke trial output at `specs/001-console-snake-game/iterations/001/review-diagrams.md`
- **Proposal INDEX**: file:///C:/Dev/Specrew/proposals/INDEX.md
