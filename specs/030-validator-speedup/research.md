# Research Notes: Local Validator Auto-Scope for Feature-Branch Invocations

**Status**: Complete (all clarifications resolved in spec)  
**Session**: 2026-05-21  
**Reviewed**: spec.md (lines 1–200), proposal.md (lines 1–161)

---

## Clarification State

### Resolved Clarifications (Spec Session 2026-05-21)

**Q1**: Should performance thresholds (e.g., "under 5 seconds") trigger runtime warnings or timeout fallback behavior?

**A1**: No. Performance thresholds are observational validation guidance for planning/review only. No timeout warnings, timeout fallback behavior, or runtime timeout semantics are added to the validator itself. The speedup is measured empirically as an acceptance signal for QA sign-off and documented in CHANGELOG evidence only.

**Decision**: Performance is measured empirically; thresholds are observational, not enforced.  
**Rationale**: Keeps implementation focused on scoping logic, not timeout semantics. Accepts runtime measurement risk: if speedup doesn't materialize, integration tests will capture it; operators can adjust scoping strategy in future iterations.  
**Alternatives Considered**: (1) Add runtime timeouts with fallback—rejected as scope creep; (2) Make thresholds hard gates—rejected as over-engineered for a local observational metric.

---

## Technical Context Resolution

### Base Ref Detection Strategy

**Decision**: Four-tier priority chain for base-ref detection.

| Priority | Source | Trigger | Behavior |
|----------|--------|---------|----------|
| 1 | `$env:GITHUB_BASE_REF` | Set in CI environment | Use as-is (CI path from `ci(lint-scoping)`) |
| 2 | `git symbolic-ref refs/remotes/origin/HEAD` | Resolves to default upstream branch | Parse and use the resolved ref |
| 3 | `git for-each-ref refs/remotes/origin/main refs/remotes/origin/master` | Fallback to conventional defaults | Use first match (prefer main) |
| 4 | `$null` | None of above resolve | Fall back to full-repo with info banner |

**Rationale**: Mirrors `ci(lint-scoping)` for consistency; handles CI path, standard git config, and fallback to conventional names. Edge cases (detached HEAD, no remote, non-origin upstreams) are handled gracefully without error.

**Alternatives Considered**: 
- (Rejected) Hard-fail if base undetectable: Would break in detached HEAD or no-remote scenarios.
- (Rejected) Prompt user interactively: Out of scope for local validator (no user interaction expected).
- (Rejected) Scan multiple remotes: v1 assumes conventional `origin`; users with non-standard remotes can pass `-BaseBranch` explicitly.

---

### Auto-Scope Default Behavior Logic

**Decision**: Feature branches get auto-scope by default; truth branches (main/master) always run full-repo; explicit flags are honored; edge cases fall back gracefully.

```
if ( explicitly passed [-ChangedOnly] )
  → Honor (backward compatible)
if ( explicitly passed [-FullRun] )
  → Full-repo, bypass auto-scope (opt-out)
if ( on [main|master] branch )
  → Full-repo (truth branch always runs full)
if ( on feature branch AND base detectable )
  → Auto-apply [-ChangedOnly] against detected base (new default)
if ( on feature branch AND base undetectable )
  → Full-repo + info banner explaining why
```

**Rationale**: 
- Feature branches get speedup by default: addresses the primary user journey (US-1).
- Truth branches never auto-scoped: prevents accidental unscoped runs on main/master.
- Explicit flags honored: preserves backward compatibility (US-4) and supports deliberate override (US-2).
- Edge cases fall back gracefully: prevents failures in detached HEAD or no-remote scenarios (US-3).

**Alternatives Considered**:
- (Rejected) Auto-scope everywhere: Would break truth-branch validation discipline.
- (Rejected) Require explicit `-ChangedOnly`: Defeats the speedup goal for local invocations.
- (Rejected) Fail on undetectable base: Breaks in detached HEAD or no-remote environments.

---

### Scope Reporting Strategy

**Decision**: Every run emits `[validator-scope]` stdout line as the first informational output with scope type and relevant counts.

| Run Type | Banner Format |
|----------|---------------|
| Auto-scoped | `[validator-scope] auto-scoped to origin/main...HEAD (3 iterations, 5 files in diff)` |
| On main branch | `[validator-scope] full-repo (on main; 44 iterations)` |
| Base undetectable | `[validator-scope] full-repo (base-undetectable; 44 iterations)` |
| `-FullRun` override | `[validator-scope] full-repo (-FullRun override; 44 iterations)` |

**Rationale**: Transparent reporting without ceremony. Users see scope at a glance; audit trails capture scope decision automatically. Composes naturally with existing `[validator-timing]` line from PR #384.

**Alternatives Considered**:
- (Rejected) Require `-Verbose` flag: Scope reporting should be always-on for observability.
- (Rejected) Log to file only: Scope reporting in stdout allows immediate user feedback.

---

## Dependency & Composition Analysis

### Prerequisite Infrastructure (Already Shipped)

| Artifact | Shipped Version | Purpose | Status |
|----------|-----------------|---------|--------|
| `ci(lint-scoping)` chore | v0.24.0 | CI-side auto-scope with `-ChangedOnly` flag and `Get-ChangedIterations` helper | ✅ Ready; Proposal 083 reuses this machinery |
| PR #384 `chore(validator-perf-dedupe)` | v0.24.1 | Narrowed global-state pathspec list to load-bearing surfaces only | ✅ Ready; makes auto-scope safe by reducing fallback-to-full-repo false positives |

**Decision**: Reuse existing machinery without modification. Proposal 083 adds layer on top (base-ref detection, auto-scope default) without changing existing flags or helpers.

**Rationale**: Reduces risk (no changes to tested code); leverages proven performance gains from CI path.

---

### v0.24.2 Bundle Composition

**Proposal 083 (this slice)**: Local validator auto-scope (~5 SP)  
**Proposal 082**: Boundary Commit + Upstream Push Discipline (~5 SP)  
**Proposal 081**: Reviewer Visual Evidence (~3 SP)  
**Proposed Pairing**: Ship Proposals 082 + 083 + 081 together in v0.24.2 if F-029 closes in time.

**Composition Rationale**:
- 082 (boundary discipline) + 083 (fast validator) together make per-boundary cost low enough for discipline to be sustainable.
- 081 (visual evidence) is orthogonal; complements both.
- All three are small-fix slices (~13 SP total) fitting v0.24.2 reliability bundle scope.

**Decision**: Proceed with Proposal 083 planning independently; coordinate with 082 and 081 during task generation if both are approved.

---

### Mirror Parity Requirements

**Decision**: Four mirror parity locations must be kept in sync:

| Primary | Mirror 1 | Mirror 2 |
|---------|----------|----------|
| `scripts/internal/shared-governance.ps1` | `extensions/specrew-speckit/scripts/shared-governance.ps1` | `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` |
| `scripts/internal/validate-governance.ps1` | `extensions/specrew-speckit/scripts/validate-governance.ps1` | `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` |
| N/A (documentation) | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` |
| N/A (documentation) | `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` |

**Rationale**: Specrew maintains three code branches (primary, extension, and mirrored extension). Changes must be applied to all three to avoid drift. Task T-009 includes mirror parity verification sweep.

**Alternatives Considered**:
- (Rejected) Maintain only primary: Extensions would lag, breaking Squad governance.
- (Rejected) Automate sync: Would require CI infrastructure change (out of scope v1).

---

## Test Coverage Plan

**Decision**: Extended integration test suite in `tests/integration/validate-governance-changed-only.tests.ps1` covers all scenarios.

| Scenario | Test Case | Expected Behavior |
|----------|-----------|-------------------|
| On main branch, no flags | Should run full-repo | `[validator-scope] full-repo (on main; 44 iterations)` |
| On feature branch, base detectable, no flags | Should auto-scope | `[validator-scope] auto-scoped to origin/main...HEAD (3 iterations, 5 files in diff)` |
| No remote, no flags | Should fallback to full-repo | `[validator-scope] full-repo (base-undetectable; 44 iterations)` |
| Detached HEAD, no flags | Should fallback to full-repo | `[validator-scope] full-repo (base-undetectable; 44 iterations)` |
| `-FullRun` on feature branch | Should bypass auto-scope | `[validator-scope] full-repo (-FullRun override; 44 iterations)` |
| Explicit `-ChangedOnly -BaseBranch origin/main` on feature branch | Should honor explicit flag | `[validator-scope]` shows scoped mode with provided base |
| Banner accuracy | All runs should emit banner with correct counts | Counts match actual iteration and file diffs |

**Rationale**: Covers primary path (US-1), override path (US-2), edge cases (US-3), and backward compatibility (US-4). Empirical speedup measurement (SC-001) is captured as integration test runtime assertion.

---

## Constitution Alignment Checklist

| Principle | Requirement | Alignment in Proposal 083 |
|-----------|-------------|--------------------------|
| **I. The Spec Is Authoritative** | Spec drives implementation | ✅ Implementation plan derived from spec requirements (FR-001 through FR-012); no scope creep beyond spec |
| **II. Specrew Is A Layered System** | Changes assigned to correct layer | ✅ Spec Kit layer (helper in scripts/, template docs); no Squad layer changes required |
| **III. Integrate Through Supported Extension Surfaces** | Use supported extension points | ✅ PowerShell scripts and markdown templates; no direct GitHub Copilot hacks |
| **IV. Compatibility Is A Product Requirement** | Forward compatibility maintained | ✅ Backward-compatible with existing `-ChangedOnly` and `-BaseBranch` flags; no breaking changes |
| **V. Dual-Toolchain Prerequisite** | PowerShell 5.1+, Git, Python/Node available | ✅ Assumes PowerShell 5.1+ and git availability (same as existing codebase) |
| **VI. Runtime-Layer Technology Neutrality** | Language-neutral above runtime layer | ✅ Configuration and scripts; no custom code language choice |
| **VII. Artifact Hierarchy Of Authority** | Constitution > Spec > Plan > Tasks > Memory > Code | ✅ Plan derived from spec; tasks derived from plan; no subordinate layer overrides |
| **VIII. Reconciliation Over Silent Divergence** | Surface conflicts explicitly | ✅ No known conflicts; edge cases handled gracefully with clear banners |
| **IX. Mandatory Feature And Iteration Traceability** | Every task traces to feature/story | ✅ All tasks (T-001–T-010) trace to FRs and user stories in spec |
| **X. Non-Interference With External Integrations** | Coexist with other extensions | ✅ No breaking changes to existing CI workflows or integrations |
| **XI. Explicit Collision Handling** | Hard-stop collisions detected | ✅ No known collisions; proposal is orthogonal to existing machinery |
| **XII. Namespaced Behavior** | Commands/hooks explicitly namespaced | ✅ New helper name-spaced as `Get-SpecrewLocalScopeBaseRef`; new flag `-FullRun` is explicit |
| **XIII. Required Spec Stewardship** | Spec steward defined and auditable | ✅ Spec Steward: Specrew maintainer (Alon Fliess) |
| **XIV. Mandatory Iteration Facilitation** | Iteration flow responsibility explicit | ✅ Iteration Facilitator: Specrew maintainer; v0.24.2 bundle cadence documented |
| **XV. Human Oversight Is First-Class** | Humans in approval/prioritization | ✅ Code review gate, QA sign-off, governance review, and release coordination required |
| **XVI. Capacity-Aware Iterations** | Measurable effort model | ✅ 5 SP estimated capacity; effort distributed across 10 tasks (3 SP core, 1.25 SP docs/tests, 1.25 SP oversight) |
| **XVII. Planning Starts From Approved Specs** | Planning driven by spec | ✅ Plan derived entirely from spec and proposal; no ad-hoc additions |
| **XVIII. Explicit Task Ownership** | Task owner, rationale, traceability | ✅ All tasks define owner, requirement link, and story link (see plan.md tasks table) |
| **XIX. Inspectable Delivery Lifecycle** | Planning/execution/review/retrospective | ✅ Planning (plan.md ✅), execution (tasks T-001–T-010), review gates (code review, QA, governance), retrospective (v0.24.2 closeout) |
| **XX. Drift Detection Is First-Class** | Drift monitoring active | ✅ Drift signals defined in spec (lines 180–184); mirror parity sweep (T-009) detects sync errors |
| **XXI. Verification Is Mandatory** | Process and artifact verification | ✅ Integration test coverage (T-007), mirror parity sweep (T-009), code review and QA gates |
| **XXII. Governance Over Convenience** | Governance prevails | ✅ Spec authority respected; no convenience shortcuts that violate spec |
| **XXIII. Specrew Is Testable As A Product** | Specrew itself evaluated | ✅ Integration tests evaluate validator behavior (process) and outcomes (scoped runs faster) |
| **XXIV. End-To-End Evaluation Is Mandatory** | Multi-layer evaluation | ✅ Tests evaluate planning process, implementation, and empirical outcomes |
| **XXV. Process And Outcome Are Co-Equal** | Process integrity + outcome | ✅ Code review validates process; integration tests validate outcomes (banner, speedup, edge cases) |
| **XXVI. Constitution Changes Are Intentional** | Amendment changes explicit | ✅ No constitution amendments required for Proposal 083; existing governance applies |
| **XXVII. Specrew Evolves Through Explicit Layer Design** | Layer assignment explicit | ✅ Changes classified as Spec Kit layer (helpers, templates); no Squad layer changes |

**Overall Alignment**: ✅ **PASS** — Proposal 083 fully aligns with all 27 constitutional principles.

---

## Summary: Ready for Implementation Planning

- ✅ Specification fully clarified; no [NEEDS CLARIFICATION] markers remain.
- ✅ All technical unknowns resolved (base-ref detection, auto-scope logic, scope reporting, test strategy).
- ✅ Dependencies and composition analyzed (reuses existing machinery; orthogonal to proposals 082, 081).
- ✅ Constitution alignment verified; all 27 principles satisfied.
- ✅ Research complete; no blocking clarifications or technical risks.

**Status**: Ready to proceed with Phase 1 planning (design artifacts and contract definitions).
