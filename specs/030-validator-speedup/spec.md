# Feature Specification: Local Validator Auto-Scope for Feature-Branch Invocations

**Feature Branch**: `chore-083-local-validator-speedup`  
**Proposal**: [Proposal 083](file:///C:/Dev/Specrew-083/proposals/083-local-validator-speedup.md)  
**Created**: 2026-05-21  
**Status**: Draft  
**Version**: v0.24.2 small-fix slice

## Clarifications

### Session 2026-05-21

- **Q: Should performance thresholds (e.g., "under 5 seconds") trigger runtime warnings or timeout fallback behavior?** → **A: No. Performance thresholds are observational validation guidance for planning/review only. No timeout warnings, timeout fallback behavior, or runtime timeout semantics are added to the validator itself. The speedup is measured empirically as an acceptance signal for QA sign-off and documented in CHANGELOG evidence only.**

## User Scenarios & Testing

### User Story 1 - Maintainer Invokes Validator Locally on Feature Branch (Priority: P1)

A maintainer is working on a feature branch and manually invokes `validate-governance.ps1` to check their changes without any explicit flags. The validator should automatically detect they're on a feature branch, discover the base branch (e.g., `origin/main`), and **run in changed-only mode** against files touched since the base. This reduces run time from ~1+ minute (full repo) to seconds (scoped to changed iterations).

**Why this priority**: This is the primary user journey. It directly delivers the empirical speedup motivation from F-029, where the Crew repeatedly validated without `-ChangedOnly` flags during boundary transitions, incurring minutes of cumulative runtime per boundary that should have been seconds.

**Independent Test**: Running the validator on a feature branch (e.g., `029-baseline-hygiene` touching 1 iteration) without flags should complete in seconds and emit `[validator-scope]` confirming auto-scoped run with iteration/file counts.

**Acceptance Scenarios**:

1. **Given** a feature branch with changes to 1-2 iterations, **When** running `validate-governance.ps1` with no flags, **Then** validator auto-applies `-ChangedOnly` against detected base and completes in seconds (AC2, AC6).
2. **Given** a feature branch where base ref is detectable (via `GITHUB_BASE_REF`, `origin/HEAD`, or `origin/main`), **When** running the validator, **Then** `[validator-scope]` banner shows scoped mode with accurate iteration and file count (AC6).
3. **Given** on `main` branch, **When** running validator with no flags, **Then** full repo validation is performed (AC5, AC6).

---

### User Story 2 - Squad Governance Agent Needs Full-Repo Validation (Priority: P2)

A Squad agent is performing feature-closeout validation and needs to ensure no cross-feature drift across the entire repository. Even though they're on a feature branch, they need a full-repo run. They pass the explicit `-FullRun` flag to bypass auto-scope and force a complete validation.

**Why this priority**: Supporting deliberate full-repo runs keeps the auto-scope default safe and discipline-visible in audit trails. This is essential for maintenance workflows where comprehensive validation is necessary.

**Independent Test**: Passing `-FullRun` on any branch (feature or main) should force full-repo validation regardless of auto-scope heuristics and emit appropriate `[validator-scope]` banner.

**Acceptance Scenarios**:

1. **Given** on a feature branch with detectable base, **When** running `validate-governance.ps1 -FullRun`, **Then** validator ignores auto-scope and runs full repo (AC3).
2. **Given** `-FullRun` flag is passed, **When** validator completes, **Then** `[validator-scope]` banner indicates full-repo mode (AC6).

---

### User Story 3 - Validator Gracefully Handles Undetectable Base (Priority: P2)

A developer is in a detached HEAD state or working with a repository that has no remote configured. The validator cannot detect a base branch. It should fall back to full-repo validation cleanly and emit an informational banner explaining why auto-scope didn't apply.

**Why this priority**: Edge-case resilience. The validator should never fail due to undetectable base; it should degrade gracefully and communicate clearly.

**Independent Test**: Running the validator in a detached HEAD or no-remote scenario should complete full-repo validation and emit a `[validator-scope]` banner with explanation.

**Acceptance Scenarios**:

1. **Given** in detached HEAD state with no upstream, **When** running validator with no flags, **Then** full-repo validation executes and `[validator-scope]` banner shows `base-undetectable` explanation (AC7).
2. **Given** no remote configured, **When** running validator, **Then** same graceful fallback with clear info banner (AC7).

---

### User Story 4 - Explicit `-ChangedOnly` Flag Preserves Existing Behavior (Priority: P1)

Users who already pass `-ChangedOnly` explicitly (with or without `-BaseBranch`) should see no behavior change. The explicit flag continues to work as before.

**Why this priority**: Backward compatibility is essential. Existing scripts and automation must continue to work unchanged.

**Independent Test**: Passing `-ChangedOnly -BaseBranch origin/main` should behave identically to pre-083 behavior.

**Acceptance Scenarios**:

1. **Given** `-ChangedOnly` flag is explicitly passed, **When** validator runs, **Then** changed-only mode applies regardless of auto-scope heuristics (AC4).

---

### Edge Cases

- What happens when multiple remotes are configured and `origin` is not the conventional upstream? → v1 assumes conventional `origin` remote; users with non-conventional names can pass `-ChangedOnly -BaseBranch <ref>` explicitly (out of scope per proposal).
- How does the validator handle a detached HEAD with upstream tracking? → `git symbolic-ref refs/remotes/origin/HEAD` will not resolve; falls back to trying `origin/main` or `origin/master`.
- What if the user is on `origin/develop` (non-standard default branch)? → Helper tries `origin/main` and `origin/master` as fallbacks; if neither exists, returns `$null` and falls back to full repo (AC7).
- Does auto-scope apply if user is on main branch but manually passes no flags? → No. On main/master, validator defaults to full repo regardless of detectable base (AC5).

## Requirements

### Functional Requirements

- **FR-001**: System MUST implement `Get-SpecrewLocalScopeBaseRef` helper function in `scripts/internal/shared-governance.ps1` and mirrored locations with the documented priority chain: (1) `$env:GITHUB_BASE_REF` if set, (2) `git symbolic-ref refs/remotes/origin/HEAD`, (3) `git for-each-ref refs/remotes/origin/main refs/remotes/origin/master`, (4) return `$null` if none resolve (AC1).

- **FR-002**: `validate-governance.ps1` MUST detect when invoked on a feature branch (not on main/master) with a detectable base ref and auto-apply `-ChangedOnly` against that base if neither `-ChangedOnly`, `-FullRun`, nor `-BaseBranch` are explicitly passed (AC2).

- **FR-003**: `validate-governance.ps1` MUST accept a new `-FullRun` flag that, when passed, bypasses all auto-scope heuristics and forces full-repository validation (AC3).

- **FR-004**: Explicit `-ChangedOnly` flag (with or without `-BaseBranch`) MUST preserve current behavior and take precedence over auto-scope logic when passed (AC4).

- **FR-005**: On `main` or `master` branch, `validate-governance.ps1` MUST default to full-repository validation (no auto-scope), even if base ref is detectable (AC5).

- **FR-006**: Every `validate-governance.ps1` run MUST emit a `[validator-scope]` stdout banner as the first informational output with accurate scope details:
  - For auto-scoped runs: `[validator-scope] auto-scoped to <base-ref>..HEAD (<iteration-count> iterations, <file-count> files in diff)`
  - For full-repo runs on main: `[validator-scope] full-repo (on main; <iteration-count> iterations)`
  - For full-repo runs due to undetectable base: `[validator-scope] full-repo (base-undetectable; <iteration-count> iterations)`
  - For explicit `-FullRun`: `[validator-scope] full-repo (-FullRun override; <iteration-count> iterations)` (AC6).

- **FR-007**: When base ref is undetectable (no remote configured or detached HEAD with no upstream), validator MUST fall back to full-repo validation cleanly and emit a clear info banner (AC7).

- **FR-008**: Coordinator governance prompt in `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` and mirrored at `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` MUST document that local validator runs now auto-scope by default on feature branches and that `-FullRun` is the explicit opt-out (AC8).

- **FR-009**: Reviewer charter in `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` and mirrored at `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` MUST note the auto-scope default and `-FullRun` opt-out for clarity when Squad agents validate locally (AC8).

- **FR-010**: Test suite in `tests/integration/validate-governance-changed-only.tests.ps1` MUST be extended to cover detection logic across: on-main default, feature-branch with detectable base, no-remote scenario, detached HEAD, multiple remotes, explicit `-FullRun` opt-out, explicit `-ChangedOnly` preservation, and `[validator-scope]` banner accuracy (AC6, AC3, AC4).

- **FR-011**: CHANGELOG.md MUST contain an entry under `Changed` section referencing Proposal 083, empirical motivation from F-029 (validator speedup during boundary lifecycle), and documentation of `-FullRun` as the opt-out for deliberate full-repo runs (AC9).

- **FR-012**: All modified scripts and templates MUST maintain mirror parity across primary and mirror locations:
  - `scripts/internal/shared-governance.ps1` ↔ `extensions/specrew-speckit/scripts/shared-governance.ps1`
  - `scripts/internal/validate-governance.ps1` ↔ `extensions/specrew-speckit/scripts/validate-governance.ps1`
  - `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` ↔ `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
  - `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` ↔ `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` (AC8).

### Traceability & Governance Requirements

- **TG-001**: Each user story maps to one or more functional requirements.
  - US1 (Maintainer local invocation) → FR-002, FR-006
  - US2 (Squad full-repo override) → FR-003, FR-006
  - US3 (Graceful edge-case fallback) → FR-007, FR-006
  - US4 (Backward-compatible explicit flags) → FR-004

- **TG-002**: Each requirement identifies intended owner role(s):
  - FR-001 through FR-007: Primary owner: Specrew maintainer (implementation)
  - FR-008 and FR-009: Co-owner: Squad governance steward (documentation sync)
  - FR-010: Test owner: QA / Integration test maintainer
  - FR-011: CHANGELOG owner: Release coordinator
  - FR-012: Mirror parity owner: Specrew maintainer (governance)

- **TG-003**: Each requirement identifies intended iteration/delivery:
  - All FR-001 through FR-012: v0.24.2 (this slice)

- **TG-004**: No known spec/implementation conflicts. Proposal 083 is well-scoped and composition with Proposals 082 and 081 is orthogonal (all ship in v0.24.2 bundle if F-029 closes in time).

### Key Entities

**No data entities created or modified** by this feature. The feature manipulates existing script control flow and state detection (git branch state, base ref detection) but introduces no new persistent entities.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Validator run on a feature-branch touching 1 iteration completes in under 5 seconds (auto-scoped mode), demonstrating speedup from ~1+ minute full-repo baseline. **Note**: This is an empirical acceptance criterion only; no runtime timeouts or timeout warnings are added to the validator itself (performance thresholds are observational validation guidance for review/planning, not new product behavior).

- **SC-002**: `[validator-scope]` banner appears as the first line of every validator run with accurate scope type (auto-scoped, full-repo, full-repo with reason).

- **SC-003**: 100% of integration test cases pass, including edge cases: on-main, on-feature-with-detectable-base, no-remote, detached HEAD, `-FullRun` override, explicit `-ChangedOnly` preservation.

- **SC-004**: Zero regressions in existing CI workflows (ci(lint-scoping) GITHUB_BASE_REF path continues to work; existing `-ChangedOnly` calls continue to work).

- **SC-005**: Squad governance documentation (coordinator prompt + reviewer charter) is updated and reviewed, confirming that the Crew (all agents) understand the auto-scope default and `-FullRun` opt-out without needing ad-hoc clarification.

- **SC-006**: CHANGELOG entry is present and captures empirical motivation (F-029 boundary validator runtime reduction) and `-FullRun` opt-out availability for future reference. **Note**: CHANGELOG entry documents the speedup as an acceptance signal and outcome evidence, not as a new runtime warning or timeout mechanism.

## Assumptions

- **Target environment**: PowerShell 5.1+ on Windows (same as existing codebase).
- **Git availability**: `git` command is available in PATH (same as existing CI/CD assumptions).
- **Remote naming**: v1 assumes conventional `origin` remote for base detection. Users with non-standard remote names can pass `-BaseBranch` explicitly.
- **Scope safety**: Narrowed global-state pathspec list (from PR #384 `chore(validator-perf-dedupe)`) makes auto-scope fallback to full repo safe—fewer false positives, so auto-scope is reliable.
- **Existing machinery reuse**: Feature reuses existing `-ChangedOnly` flag, `Get-ChangedIterations` helper, and global-state pathspec list from prior work (ci(lint-scoping) and PR #384). No new scoping machinery is required.
- **Backward compatibility**: Existing scripts and automation that pass explicit flags (e.g., `-ChangedOnly -BaseBranch`) continue to work unchanged.
- **No caching**: Speedup comes from running less (scoped validation), not from caching results.

## Governance Alignment

- **Spec Steward**: Specrew maintainer (Alon Fliess) — accountable for specification integrity and alignment with Proposal 083.

- **Iteration Facilitator**: Specrew maintainer — accountable for delivery cadence and coordination with v0.24.2 bundle (Proposals 082, 081, others).

- **Capacity Model**: Small-fix slice (~5 SP). Included in v0.24.2 reliability bundle per Proposal 067 scope framework.

- **Drift Signals**:
  - Validator runs locally but no `[validator-scope]` banner appears → implementation incomplete
  - `-FullRun` flag accepted but auto-scope still applies → logic error
  - Feature branch with detectable base takes > 10 seconds → auto-scope not applied, or scoping logic regressed (observational only; no runtime timeout enforced)
  - CHANGELOG missing or vague on `-FullRun` → documentation drift
  - Mirror parity broken (primary vs. extensions/specrew-speckit vs. .specify/extensions) → sync error

- **Human Oversight Points**:
  - Code review of FR-001 through FR-007 implementation and mirror updates
  - QA sign-off on AC1–AC9 via integration test execution
  - Squad steward review of FR-008 and FR-009 (governance prompt + charter updates)
  - Release coordinator review of CHANGELOG entry (FR-011)

## Context & Cross-References

- **Proposal 083**: [Local Validator Speedup](file:///C:/Dev/Specrew-083/proposals/083-local-validator-speedup.md)
- **Proposal INDEX**: [Terminology Guidance](file:///C:/Dev/Specrew-083/proposals/INDEX.md) (use "the Crew" for agent team in new prose)
- **Empirical Motivation (F-029)**: Session evidence from 2026-05-21 where boundary-lifecycle validator invocations ran full-repo unscoped, incurring minutes of cumulative runtime
- **Prior Art**: `ci(lint-scoping)` (shipped; CI-side auto-scope), PR #384 `chore(validator-perf-dedupe)` (shipped; narrowed pathspec list)
- **Related Proposals** (v0.24.2 bundle):
  - Proposal 082 (Boundary Commit + Upstream Push Discipline): Complements with per-boundary commit discipline
  - Proposal 081 (Reviewer Visual Evidence): Sibling small-fix slice
- **Composition**: Orthogonal to existing `-ChangedOnly` and `-BaseBranch` flags; reuses existing machinery; no conflicts anticipated.
