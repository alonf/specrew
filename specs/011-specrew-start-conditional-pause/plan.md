# Implementation Plan: Conditional Pause on specrew-start When Session-Loaded Files Changed

**Branch**: `011-specrew-start-conditional-pause` | **Date**: 2026-05-11 | **Spec**: `specs/011-specrew-start-conditional-pause/spec.md`
**Input**: Feature specification from `/specs/011-specrew-start-conditional-pause/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Feature 011 refines the auto-continue behavior from spec 001 Session 2026-05-04 to detect when session-loaded files (behavioral files like `.github/agents/squad.agent.md`, `.squad/agents/*/charter.md`, etc.) have been committed between Copilot restarts, and pauses the lifecycle to allow the user to inject first-message directives before auto-continuing. The feature adds a change detector to `specrew-start.ps1` that compares a baseline commit (tracked in `.specrew/last-start-prompt.md`) against HEAD, triggers a PAUSE-AND-CONFIRM directive when changes are detected, preserves auto-continue behavior when no changes exist, and optionally accepts a `-PostRestartDirective` parameter for power-user prepended directives. The implementation is split across two iterations: Iteration 001 covers detector logic, baseline tracking, auto-continue preservation, signature stability, and error fidelity; Iteration 002 covers pause-and-confirm injection, the optional parameter, visibility output, comprehensive tests, and known-traps corpus seeding.

## Technical Context

**Language/Version**: PowerShell 7+ (same as existing `specrew-start.ps1`)  
**Primary Dependencies**: Git (for `git diff --name-only`), PowerShell stdlib (YAML frontmatter parsing)  
**Storage**: `.specrew/last-start-prompt.md` (transient session-state file, existing mechanism)  
**Testing**: PowerShell Pester integration tests (same as existing Specrew test suite)  
**Target Platform**: Windows PowerShell 7+ and POSIX-compatible PowerShell with Git  
**Project Type**: CLI scaffolding script (PowerShell module)  
**Performance Goals**: Change detector must complete in <100ms for typical repos (baseline assumption: <500 commits, <100 session-loaded paths)  
**Constraints**: No new runtime dependencies; Git must be available in PATH; baseline commit hash must be precisely recorded and retrievable  
**Scale/Scope**: Single entry point (`specrew-start.ps1`); change detection scoped to session-loaded paths only (approximately 15-20 path globs total)

## Phase 1 Quality Planning

> This feature modifies a single entry point (`specrew-start.ps1`) with bounded scope: change detector logic, baseline tracking, pause-and-confirm directive injection, and parameter handling. Phase 1 covers the core functionality (Iteration 001: detector + baseline + preserve auto-continue + preserve signatures + error fidelity; Iteration 002: pause injection + parameter + visibility + tests + corpus seeding).

**Phase Scope**: `phase-1-first-slice`  
**Inferred Quality Profile**: `quality-profile.cli-script-integration-focused.v1` (PowerShell script modification with git integration and user-facing handoff output)  
**Selected preset ref**: `quality-profile.cli-script-integration-focused.v1`

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `cli-entrypoint` | `scripts/specrew-start.ps1` | PowerShell 7+ | Core entry point; change detector logic lands here |
| `session-state-file` | `.specrew/last-start-prompt.md` | YAML frontmatter + markdown | Baseline tracking and pause-and-confirm messaging |
| `git-integration` | Git commands (`git diff --name-only`, baseline commit comparison) | Git CLI | Change detection depends on git diff accuracy |
| `test-integration` | `tests/integration/specrew-start-*.ps1` | Pester + PowerShell test scaffolding | Deterministic test coverage for detector, pause, parameter handling |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| `correctness-of-change-detection` | required | Change detection must be precise; false negatives bypass the pause (regression), false positives over-pause |
| `baseline-tracking-durability` | required | Baseline commit hash must survive serialization/deserialization and be precisely comparable; drift here breaks the detector |
| `user-visible-output-fidelity` | required | Pause-and-confirm messages and file lists must be clear and testable through scaffold-replay-path assertions (per test-integrity corpus) |
| `backward-compatibility` | required | Auto-continue behavior for routine resumes must not regress; signature changes to `specrew-start.ps1` are not permitted (except new optional `-PostRestartDirective` parameter) |
| `performance` | required | Change detector must complete quickly (<100ms baseline assumption) to avoid noticeable delay in handoff rendering |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `cli-script-integration-focused` | PowerShell CLI modification with git integration and test coverage |
| Mechanical Checks | `test-integrity`, `anti-pattern` (detect unconditional auto-continue bypass), `dead-field` (stale baseline_commit_hash) | Evidence recorded in test suite and linting |
| Ecosystem Tools | PowerShell Pester test runner, Git CLI, PowerShell linters (PSScriptAnalyzer) | Free/community baseline; integrated with existing Specrew test harness |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `detector-accuracy` | test-integrity | Deterministic tests in `tests/integration/specrew-start-change-detector.ps1` | planned |
| `baseline-tracking-correctness` | mechanical | Tests for YAML frontmatter serialization/deserialization in `tests/integration/specrew-start-baseline-tracking.ps1` | planned |
| `pause-and-confirm-visibility` | test-integrity (scaffold-replay-path) | Tests invoking `scaffold-reviewer-artifacts.ps1` and `specrew-review.ps1` to assert pause messages in output | planned |
| `auto-continue-preservation` | test-integrity | Tests for routine resumes without session-loaded changes | planned |
| `signature-preservation` | mechanical | Scan `specrew-start.ps1` parameters and documented entry points to confirm no breaking changes | planned |
| `parameter-handling` | test-integrity | Tests for `-PostRestartDirective` parameter prepending | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `concurrency-correctness-review` | Single-threaded script; no concurrent execution model | None needed |
| `security-surface-hardening` | No new security boundaries; git commands are trusted, baseline hash is read-only state | None needed |
| `performance-profiling` | Baseline assumption: <100ms acceptable; no real-time constraints | Monitor if detector slows down for large repos (>10k commits) |
| `distributed-system-correctness` | Not applicable; local script with local git state | None needed |

### Explicit Phase 2+ Deferrals (Updated for Iteration 001 Planning)

- ✅ Iteration 001 planning-time hardening gate is created at `specs/011-specrew-start-conditional-pause/iterations/001/quality/hardening-gate.md` (T031 scope, complete).
- Phase 2 Iteration 002 planning will update hardening-gate evidence for pause-and-confirm behavior, visibility, parameter handling, and comprehensive testing (separate iteration 002 gate artifact).
- Phase 2 strongest-class lens routing, specialist bug-hunter review for pause-and-confirm behavior, and quality-drift logic remain deferred until Iteration 002 planning.
- Mixed-stack override workflows and reference-implementation comparison remain deferred for future iterations.
- Known-traps corpus seeding is deferred to Iteration 002 (Iteration 002 includes task T055 for corpus entry creation).

## Phase 1 Hardening Gate and Iteration 001 Planning

> Phase 1 Iteration 001 planning includes the planning-time hardening-gate artifact at `specs/011-specrew-start-conditional-pause/iterations/001/quality/hardening-gate.md`, which documents Phase 1 quality concerns (detector accuracy, baseline tracking durability, auto-continue preservation, signature stability, error-message preservation) and five canonical concerns. This planning-time gate is ready for Alon Fliess's strongest-available class review before implementation authorization. Phase 2 hardening planning and Polish phase work (pause-and-confirm behavior, visibility output testing, known-traps corpus seeding) are deferred until Iteration 002 planning.

**Phase 1 Iteration 001 Hardening Gate**: Created at `specs/011-specrew-start-conditional-pause/iterations/001/quality/hardening-gate.md`  
**Gate Overall Verdict**: ready (awaiting review and human sign-off)  
**Gate Scope**: Detector infrastructure, baseline tracking, auto-continue preservation, signature/error-message stability; User Story 2 (pause-and-confirm), User Story 3 (parameter support), and Polish phase explicitly deferred to Iteration 002  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: Deferred; Iteration 002 includes task T055 to seed corpus entry for "auto-handoff bypass when session-loaded files change" pattern

### Hardening Focus Areas (Planned for Iteration 001 & Deferred to Iteration 002)

| Focus Area | Phase / Iteration | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Detector logic correctness | Phase 1+Phase 2 / Iteration 001 | Planning-time hardening gate at `iterations/001/quality/hardening-gate.md` (created); integration tests in `tests/integration/specrew-start-change-detector.ps1` | created |
| Baseline tracking durability | Phase 1+Phase 2 / Iteration 001 | Planning-time hardening gate (created); round-trip tests in `tests/integration/specrew-start-baseline-tracking.ps1` | created |
| Auto-continue preservation | Phase 1+Phase 2 / Iteration 001 | Planning-time hardening gate (created); preservation tests in `tests/integration/specrew-start-auto-continue-preservation.ps1` | created |
| Signature stability | Phase 1+Phase 2 / Iteration 001 | Planning-time hardening gate (created); signature verification in T035 | created |
| Error message preservation | Phase 1+Phase 2 / Iteration 001 | Planning-time hardening gate (created); error message checking in T036 | created |
| Pause-and-confirm visibility | Phase 2 / Iteration 002 (deferred) | Iteration 002 planning-time hardening gate; scaffold-replay-path tests in `tests/integration/specrew-start-pause-and-confirm.ps1` | deferred-to-iteration-002 |
| Parameter handling correctness | Phase 2 / Iteration 002 (deferred) | Iteration 002 planning-time hardening gate; parameter tests in `tests/integration/specrew-start-parameter-handling.ps1` | deferred-to-iteration-002 |
| Known-traps corpus seeding | Phase 3 / Iteration 002 (deferred) | Corpus entry in `.specrew/quality/known-traps.md` created by task T055 | deferred-to-iteration-002 |

### Explicit Later Deferrals

- ✅ Iteration 001 hardening gate creation is complete (sign-off and blocking semantics now ready for Alon Fliess strongest-available review).
- Implementation authorization is explicitly distinct from hardening-gate sign-off; implementation remains blocked pending gate review.
- Full line-by-line lens execution evidence and runtime-only final proof for pause-and-confirm behavior remain deferred until Iteration 002 planning/review.
- Known-traps corpus seeding and trap reapplication remain deferred until Iteration 002 scope explicitly includes TR-001.
- Strongest-class routing enforcement details and requested-versus-effective execution evidence for Iteration 002 pause-and-confirm behavior remain deferred until specialist review is routed for Iteration 002 planning.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: ✅ Plan scope maps to approved spec artifacts. Feature 011 spec defines FR-001 through FR-010, TG-001 through TG-006, and SC-001 through SC-006. Plan covers both iterations required to deliver all FRs and TGs.

- **Layering Gate**: ✅ Changes classified as Spec Kit layer (specrew-start.ps1 is part of Spec Kit bootstrap). Feature remains additive to spec 001 Session 2026-05-04 auto-continue clarification; no override.

- **Traceability Gate**: ✅ Planned deliverables link to requirements:
  - Iteration 001: Detector (FR-001), baseline tracking (FR-002), auto-continue preservation (FR-004), signature stability (FR-006), error fidelity (FR-007) → supports TG-001, TG-002, TG-005
  - Iteration 002: Pause-and-confirm (FR-003, FR-009), parameter (FR-005), visibility (FR-009, TG-006), tests (FR-010), corpus (FR-008) → supports TG-002, TG-003, TG-004, TG-006

- **Ownership Gate**: ✅ Explicit role ownership:
  - Spec Steward: Alon Fliess (owns approval of detector logic, pause-and-confirm message formatting, baseline-tracking mechanism)
  - Iteration Facilitator: Specrew lifecycle maintainers (ensure test-integrity corpus guidance is followed for scaffold-replay-path assertions)
  - Implementer: Squad agent (follow planning and deliver detector logic, parameter handling, test coverage)

- **Capacity Gate**: ✅ Effort units and iteration capacity:
  - Iteration 001: ~10-12 story points (detector logic + baseline tracking + signature preservation + integration tests for core paths)
  - Iteration 002: ~8-10 story points (pause-and-confirm injection + parameter handling + visibility assertions + scaffold-replay-path tests + corpus seeding)
  - Total: ~18-22 story points, bounded within standard iteration capacity

- **Drift/Reconciliation Gate**: ✅ Drift detection and escalation:
  - Drift signals: Any regression of auto-continue behavior for routine resumes; any visibility output added without scaffold-replay-path test assertions; any failure to pause when session-loaded files are changed
  - Escalation: Weekly review of test results during implementation; immediate escalation if auto-continue behavior regresses

- **Verification Gate**: ✅ Process and outcome verification:
  - Acceptance criteria validation via deterministic integration tests (SC-006: end-to-end scenario with baseline tracking, change detection, pause-and-confirm rendering, user confirmation, coordinator resume)
  - Test coverage includes all core paths: routine resume (no changes), session-loaded file change detected, `-PostRestartDirective` parameter prepending
  - Pre-merge gate: All integration tests pass, spec 001 FR-024 contract preserved, visibility output testable via scaffold-replay-path

## Project Structure

### Documentation (this feature)

```text
specs/011-specrew-start-conditional-pause/
├── plan.md                          # This file (/speckit.plan command output)
├── spec.md                          # Feature specification (input)
├── research.md                      # Phase 0 output (if needed, likely empty for this feature)
├── data-model.md                    # Phase 1 output (entities: Change Detector, Session-Loaded Paths, Baseline Commit, PAUSE-AND-CONFIRM Directive)
├── quickstart.md                    # Phase 1 output (quick reference for detector behavior)
├── contracts/                       # Phase 1 output (if any; likely minimal for this feature)
│   └── [none; no external contracts needed]
├── quality/
│   └── trap-reapplication.md        # Reapplication evidence (if trap reapplication occurs)
├── iterations/
│   ├── 001/
│   │   ├── plan.md                  # Iteration 001 planning (Phase 1 + Phase 2 foundational)
│   │   └── quality/
│   │       └── hardening-gate.md    # Iteration 001 Phase 1+Phase 2 hardening gate (planning-time artifact, created)
│   └── 002/
│       └── [future iteration planning]
└── tasks.md                         # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
scripts/
├── specrew-start.ps1                # Main modification: add change detector, baseline tracking, pause-and-confirm, parameter handling

tests/
├── integration/
│   ├── specrew-start-change-detector.ps1           # Tests for git diff logic and session-loaded path detection
│   ├── specrew-start-baseline-tracking.ps1         # Tests for YAML frontmatter serialization of baseline_commit_hash
│   ├── specrew-start-pause-and-confirm.ps1         # Tests for pause-and-confirm directive injection and visibility
│   ├── specrew-start-parameter-handling.ps1        # Tests for -PostRestartDirective parameter prepending
│   ├── specrew-start-auto-continue-preservation.ps1 # Tests for routine resume behavior (no changes = auto-continue)
│   └── specrew-start-end-to-end.ps1                # End-to-end test (SC-006: baseline → change → detect → pause → confirm → resume)

.specrew/
└── quality/
    └── known-traps.md               # Corpus entry seeded during Iteration 002: "auto-handoff bypass when session-loaded files change"
```

**Structure Decision**: Single-file modification (`scripts/specrew-start.ps1`) with supporting integration test suite. No new library or module structure needed. Changes are additive and scoped to change detector, baseline tracking, and directive injection logic. Session-state file (`.specrew/last-start-prompt.md`) uses existing YAML frontmatter structure with new `baseline_commit_hash` field.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**Status**: ✅ Constitution Check passed with zero violations. No complexity tracking entries needed.

---

## Iteration Structure and Planning Boundary

**Two-Iteration Plan**: This feature is planned as two bounded iterations reflecting the dependency graph and prioritization of user-facing behavior.

### Iteration 001: Foundation + Core Detector + Signature Preservation
**Scope**: FR-001, FR-002, FR-004, FR-006, FR-007  
**Focus**: Detector logic, baseline tracking, auto-continue preservation, signature stability, error fidelity  
**Approximate Effort**: ~10-12 story points  
**Deliverables**:
- Change detector logic in `specrew-start.ps1` (FR-001: runs `git diff --name-only` against baseline, detects session-loaded path changes)
- Baseline commit tracking in `.specrew/last-start-prompt.md` YAML frontmatter (FR-002: `baseline_commit_hash` field)
- Auto-continue preservation when no changes detected (FR-004: regenerated handoff includes auto-continue directive per spec 001)
- Signature and documented behavior preservation (FR-006: no breaking changes to entry points, arguments, defaults)
- Error message preservation (FR-007: existing error paths unchanged, new pause messages are additive)
- Integration tests for detector accuracy and baseline tracking durability
- **Planning artifact**: `specs/011-specrew-start-conditional-pause/plan.md` (this document, created during feature planning)

**Quality Gates (Iteration 001)**:
- Detector correctly identifies session-loaded file changes via `git diff --name-only`
- Baseline commit hash is correctly serialized and deserialized in YAML frontmatter
- Auto-continue behavior is preserved for routine resumes (no changes = auto-continue)
- Signature and documented behavior remain stable
- Error messages preserved; new messages additive

**Pre-Implementation Readiness**: After Iteration 001 planning is approved, Phase 1 design artifacts (research.md, data-model.md, quickstart.md) will be generated. Iteration 001 implementation will not begin until explicit authorization is recorded in `.squad/decisions.md`.

### Iteration 002: User-Facing Features + Visibility + Comprehensive Testing + Corpus Seeding
**Scope**: FR-003, FR-005, FR-008, FR-009, FR-010  
**Focus**: Pause-and-confirm injection, optional -PostRestartDirective parameter, visibility output, comprehensive tests, known-traps corpus seeding  
**Approximate Effort**: ~8-10 story points  
**Deliverables**:
- Pause-and-confirm directive injection when session-loaded files change (FR-003: clear message, file list, user confirmation prompt)
- `-PostRestartDirective` parameter support (FR-005: optional string parameter, prepended to handoff, appears verbatim)
- Detector visibility in regenerated handoff (FR-009: structured field showing which files changed)
- Comprehensive integration test coverage including scaffold-replay-path assertions (FR-010: deterministic tests for detector, pause, parameter, visibility)
- Known-traps corpus entry seeding (FR-008: document "auto-handoff bypass" pattern in `.specrew/quality/known-traps.md`)
- **Planning artifact**: `specs/011-specrew-start-conditional-pause/iterations/002/quality/hardening-gate.md` (to be created during Iteration 002 planning)

**Quality Gates (Iteration 002)**:
- Pause-and-confirm message clearly states which files changed and requests user confirmation
- `-PostRestartDirective` parameter prepends user directive verbatim to handoff
- Visibility output is testable via scaffold-replay-path assertions (not just runtime state inspection)
- All core paths covered by deterministic integration tests (routine resume, session-loaded file change, parameter prepending)
- Known-traps corpus entry documents the pattern, detection method, remediation guidance, discovery date

**Pre-Implementation Readiness**: After Iteration 002 planning is approved, Iteration 002 hardening-gate.md will be created at `specs/011-specrew-start-conditional-pause/iterations/002/quality/hardening-gate.md` and reviewed. Iteration 002 implementation will not begin until explicit authorization is recorded in `.squad/decisions.md`.

---

## Planning-Time Decisions and Traceability

**Decision 1: Two-Iteration Structure**  
Rationale: Iteration 001 (detector + baseline + preservation) represents a stable intermediate milestone: the core change-detection infrastructure is complete and testable, but pause-and-confirm and user-facing features are deferred. Iteration 002 adds visibility, user directives, and comprehensive testing. This split aligns with the specification's own structure (FRs grouped by functionality priority) and allows for staged human review and approval.

**Decision 2: Pause-and-Confirm Deferred to Iteration 002**  
Rationale: The pause-and-confirm directive injection (FR-003) depends on the detector and baseline-tracking infrastructure (FR-001, FR-002) being complete and correct. Deferring pause injection to Iteration 002 allows Iteration 001 to focus on correctness of the foundation and gives time for human review of the detector logic before adding user-facing behavior.

**Decision 3: Known-Traps Corpus Seeding in Iteration 002**  
Rationale: The corpus entry documents the pattern discovered on 2026-05-11 (auto-handoff bypass when session-loaded files change). This entry should be seeded as part of the feature delivery to ensure the pattern is captured in the project's trap knowledge base. Iteration 002 includes explicit task TR-001 for corpus seeding.

**Decision 4: Quality Profile Selection**  
Rationale: Feature 011 is a focused PowerShell CLI script modification with clear git integration and test coverage. The `quality-profile.cli-script-integration-focused.v1` preset was selected to reflect the stack (PowerShell + Git) and risk areas (change detection accuracy, user-visible output fidelity, backward compatibility).

---

## Feature Plan Approval and Boundary

**Planning Completion**: This feature plan document constitutes the feature-level planning boundary. It includes:
- ✅ Feature summary and technical context
- ✅ Phase 1 quality planning (risk dimensions, quality gates, tooling)
- ✅ Phase 2 hardening planning outline (deferred to Iteration 002)
- ✅ Constitution Check (all gates passed)
- ✅ Project structure and artifact locations
- ✅ Two-iteration split with clear FRs, deliverables, and quality gates per iteration
- ✅ Planning-time decisions with traceability

**Next Steps**:
1. **Phase 0 Research** (if needed): Generate `research.md` to resolve any NEEDS CLARIFICATION entries. For this feature, all technical context is clear; research.md may be minimal or omitted.
2. **Phase 1 Design**: Generate `data-model.md` (entities: Change Detector, Session-Loaded Paths, Baseline Commit, PAUSE-AND-CONFIRM Directive) and `quickstart.md`.
3. ✅ **Iteration 001 Planning**: `specs/011-specrew-start-conditional-pause/iterations/001/plan.md` created with explicit task breakdown (detector logic, baseline tracking, preservation, tests, error handling); hardening-gate.md created at `specs/011-specrew-start-conditional-pause/iterations/001/quality/hardening-gate.md`.
4. **Iteration 002 Planning**: Create `specs/011-specrew-start-conditional-pause/iterations/002/plan.md` with explicit task breakdown (pause injection, parameter, visibility, comprehensive tests, corpus seeding) and `specs/011-specrew-start-conditional-pause/iterations/002/quality/hardening-gate.md`.

**Feature Plan Path**: `C:\Dev\Specrew\specs\011-specrew-start-conditional-pause\plan.md`
