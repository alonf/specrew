# Retrospective: Iteration 002

**Schema**: v1
**Iteration**: Iteration 002 (Re-Review: FR-008 Repair, 2026-05-15, post-repair)
**Completed**: 2026-05-15
**Facilitated By**: Retro Facilitator
**Authorized By**: Alon Fliess

## Execution Summary

Iteration 002 implementation delivered the full authorized 17.0 SP slice covering FR-020 through FR-024, the Iteration 2 graduation portion of FR-016, and the accepted Iteration 001 carryovers (FR-008 post-commit Commit Reference synchronization, canonical UTC seconds-precision `Recorded At` formatting, post-commit verification protocol formalization, stale-reference scan mandate, and selected passive-guidance row graduations).

The review boundary discovered a blocking FR-008 post-commit synchronization defect on the live repository (missing-temp-file move error), which required bounded implementation repair. The repaired helper now resolves ledger paths to absolute coordinates, verifies temp-file existence before moving, and emits clear path-specific errors. Live-execution testing confirms the synchronization helper completes cleanly on a real git-controlled repository fixture, and the three blocked hardening-gate concerns (error-handling-expectations, retry-idempotency-requirements, operational-resilience-concerns) are now verified. The repo validator passes at 179550 ms and remains truthful on the green tree.

---

## Corpus-Row Candidates

Six corpus-row candidates were identified across Feature 016 Iteration 002 execution:

### Primary Findings

1. **`fr-008-live-execution-vs-fixture-test-divergence`** — validation-discipline
   - **Evidence**: The FR-008 post-commit synchronization helper passed all scratch-workspace replay tests (synthetic fixtures) but failed on the live repository due to a path-resolution mismatch (process current directory vs PowerShell location). Initial implementation did not isolate the defect early enough.
   - **Durability Rule**: Automation-dependent helpers (FR-008 post-commit sync, Authorization ledger updates) must include live-repository test fixtures in the implementation task definition, not rely solely on synthetic workspace replays. Exercise the real helper flow against a real git-controlled repository to surface path-resolution or permission issues before review boundary.
   - **Applicable When**: Any feature implementing governance automation that depends on filesystem operations, git state, or ledger synchronization.

2. **`local-vs-origin-truth-surface-drift`** — lifecycle-discipline
   - **Evidence**: During Feature 016 Iteration 002 review-boundary work, local tree updates had not been pushed to origin, creating ambiguity about which version was the authoritative reference for review evidence and post-commit synchronization. This drift delayed boundary clarity and required explicit reconciliation (`git status --branch` + `git log --oneline -1 origin/HEAD`).
   - **Durability Rule**: At every lifecycle boundary, include an explicit verification step before the boundary-signoff commit: "Local HEAD equals origin HEAD after push." Document the exact command output in the boundary commit message to make the durable truth surface explicit.
   - **Applicable When**: Any multi-session or multi-user feature work where local and origin branches might diverge during active development.

3. **`coordinator-prompt-chat-output-must-mirror-validator-enforced-artifact-discipline`** — interaction-model
   - **Evidence**: Feature 016 iteration boundaries are enforced by validators on artifact structure (FR-016 bare-path rules, FR-020-024 corpus row presence) but the coordinator guidance prompts must match validator expectations or teams inherit silent non-compliance. The handoff template, reviewer checklist, and Spec Kit surfaces must all reflect the same artifact-discipline expectations.
   - **Durability Rule**: When validator rules are added, update all three artifact-generation surfaces: (1) coordinator prompts (Spec Kit planning + reviewer guidance), (2) handoff templates and checklist wording, (3) integration test fixtures that prove the rule behavior. Validator enforcement + prompt/template alignment = durable discipline.
   - **Applicable When**: Adding new structural rules or governance requirements that span multiple coordinator surfaces.

4. **`nfr-budget-recalibration-trigger`** — estimation-discipline
   - **Evidence**: Feature 016 Iteration 002 planned at 17.0 SP and delivered ~22-25 SP actual (+30-50% variance), driven primarily by self-referential governance work (authorization ledger updates tracking their own lifecycle) and live-repository testing discovery friction. This variance is systematic and repeatable for governance-automation features, not a one-time scheduling miss.
   - **Durability Rule**: For features with automation-dependent governance (FR-008 post-commit flow, authorization ledger self-reference), plan with +30-50% variance buffer. Do not reduce base estimates; increase the iteration capacity band to 20-25 SP for complex governance-automation features. Explicitly budget 3-5 SP for discovery and integration testing on live repositories.
   - **Applicable When**: Planning iterations involving self-referential lifecycle automation or cross-artifact synchronization (e.g., Feature 016-017 governance work).

5. **`repair-cycles-cascade-from-bookkeeping-misalignment`** — process-discipline
   - **Evidence**: The FR-008 post-commit synchronization defect required root-cause analysis, implementation repair, live-execution test fixture creation, cleanup verification, and retro-boundary analysis—a multi-cycle repair spanning implementation → review → repair → retro. The defect was not in FR-016 logic but in FR-008 bookkeeping helper infrastructure, yet it blocked the entire Feature 016 Iteration 002 review verdict.
   - **Durability Rule**: Repair cycles triggered by infrastructure defects (ledger writes, commit-reference synchronization, helper automation) cascade through multiple boundaries. Isolate carryover-infrastructure work in dedicated tasks upfront (e.g., FR-008 helper live-testing as a separate T007 acceptance criterion) rather than treating it as review-boundary discovery. This prevents silent blockage and keeps repair scopes bounded.
   - **Applicable When**: Iterations carrying forward infrastructure from prior features without fresh integration testing on the live repository.

6. **`worktree-pattern-for-clean-review-and-repair`** — lifecycle-discipline (positive pattern)
   - **Evidence**: Feature 016 Iteration 002 review-boundary work and FR-008 repair were conducted in a dedicated `C:\Dev\Specrew-review` worktree separate from the main repository at `C:\Dev\Specrew`. This isolation allowed review-boundary repairs and local-vs-origin reconciliation without impacting concurrent feature development, and enabled explicit verification of "local HEAD equals origin HEAD" at boundary close.
   - **Durability Rule**: Establish review-boundary and repair-cycle work in a dedicated worktree. Use explicit branch-tracking (`git branch --set-upstream-to=origin/<branch>`) and post-push verification (`git status --branch` + `git log --oneline -1 origin/HEAD`) to ensure local truth matches origin before boundary signoff. This pattern prevents silent local-only changes and enables clean, reversible repair cycles.
   - **Applicable When**: Any multi-session or multi-boundary feature (review → repair → retro) where clean isolation and explicit truth-surface verification are needed.

---

## Estimation Learnings

**Planned Effort**: 17.0 story_points  
**Actual Effort**: ~22-25 story_points (including post-review FR-008 repair and retro-boundary work)  
**Variance**: +30-50% under-estimation

### Root Causes

1. **Self-Referential Feature Complexity**: Feature 016 requires the implementation of governance automation that tracks its own lifecycle (authorization ledger updates, post-commit verification). This self-referential nature creates discovery friction where the team uncovers dependencies between artifacts during implementation rather than upfront.

2. **Live-Repository Synchronization Defects**: The FR-008 post-commit helper failure (missing-temp-file move error) was not anticipated during planning. Scratch-workspace replay proved the logic was sound, but the live repository path exposed a process-current-directory vs PowerShell-location discrepancy that required debugging and repair cycles.

3. **Bounded Repair Discipline**: The FR-008 repair was properly bounded to the synchronization helper path and live-execution test fixture, but the repair cycles (root-cause analysis, test-fixture setup, atomic-write verification, cleanup verification) added ~5-8 SP of unplanned work after review opened.

### Recommendation for Future Iterations

- **Front-load live-repository testing** for automation-dependent features like FR-008. Do not rely only on synthetic workspace replays; exercise the real helper flow early during implementation to surface path-resolution or permission issues.
- **Plan for +30-50% variance buffer** on features with self-referential lifecycle automation. The coordination overhead between planning artifacts, implementation code, and post-commit verification surfaces is not fully captured by traditional task decomposition.
- **Explicitly budget for repair cycles** when automation is involved. Include a dedicated "automation-integration-and-live-testing" task in the implementation plan rather than treating it as implicit.

---

## Deferrals and Out-of-Scope Work

Three deferral items were explicitly preserved from this iteration:

1. **Standalone Fractional-Second Parser Support** (deferred post-Iteration 002)
   - **Rationale**: Canonical UTC seconds-precision `Recorded At` format is sufficient for the Feature 016 scope. Full fractional-second parsing is a future enhancement for high-frequency audit scenarios.
   - **Next Owner**: Feature 017+ decision.

2. **Standalone Stale-Reference Soft-Validator Support** (deferred post-Iteration 002)
   - **Rationale**: The mandatory stale-reference scan in `Invoke-InteractionModelStaleReferenceScan` is adequate for catching broken `file:///` links after boundary commits. A soft-validator variant (warning-only, pre-commit) is deferred to a future quality-hardening iteration.
   - **Next Owner**: Feature 018+ governance enhancement.

3. **Validator Performance Optimization** (deferred post-Iteration 002)
   - **Rationale**: The 179550 ms repo validator runtime is stable but higher than pre-Feature-016 baselines. Optimization work (caching, parallel rule evaluation, rule-set pruning) is deferred to a dedicated performance-hardening iteration after Iteration 003.
   - **Next Owner**: Feature 019+ performance task.

Additionally, one approved deferral from planning was upheld:
- **`self-referential-feature-sp-surcharge`** (explicit deferred task): Planning acknowledged that Feature 016's self-referential governance work would likely exceed standard effort assumptions. This deferral is validated by actual variance (+30-50%), and the pattern should inform future feature estimation.

---

## Positive Learnings

### Learning 1: Bounded Implementation-Repair Discipline Prevents Scope Creep

Feature 016 Iteration 002 discovered a live-repository defect in the FR-008 post-commit synchronization helper during review boundary. The team authorized a **bounded repair only** (FR-008 helper + live-execution test fixture) without expanding to related work like validator performance tuning, handler retry logic, or state-machine redesign. This discipline kept the repair within ~5-8 SP of unplanned effort rather than spiraling into a larger rework cycle.

**Recommendation**: Future review-boundary defects should follow this pattern: (1) classify the defect scope narrowly, (2) repair only the defect boundary, (3) test the repaired artifact in isolation, (4) defer broader optimization or related hardening to later iterations. This keeps review cycles bounded and maintains trust in the iteration planning process.

### Learning 2: Live-Repository Testing Surfaces Automation Defects Earlier

The initial implementation of `Sync-InteractionModelAuthorizationCommitReference` passed all scratch-workspace replay tests, but failed on the live repository due to a path-resolution mismatch (process current directory vs PowerShell location). Adding a live-execution test fixture to `tests\integration\substantive-interaction-model-iteration2.ps1` (exercising the helper against a real git-controlled repo with relative project-root invocation and an intentional location mismatch) caught this defect decisively.

**Recommendation**: For automation-dependent features, include at least one live-repository test fixture in the implementation task definition. Do not rely solely on synthetic workspace replays. This shifts defect discovery from review boundary to implementation boundary.

### Learning 3: Stale-Reference Scan Discipline Prevents Silent Broken-Link Bugs

Iteration 002 introduced the mandatory stale-reference scan after every boundary commit (`Invoke-InteractionModelStaleReferenceScan`). This scan flags missing `file:///` targets while staying clean on valid in-repo URLs. Early in drafting, review.md had bare filesystem paths mixed with `file:///` URLs; the scan caught this inconsistency before the review-boundary commit landed.

**Recommendation**: Enforce stale-reference scanning as a pre-commit gate for any iteration that updates handoff documentation or lifecycle artifacts. This is a low-cost, high-signal validation that prevents downstream boundaries from inheriting broken navigation.

### Learning 4: Reconciliation Between Local and Origin Truth Surfaces Requires Explicit Checkpoints

During Feature 016 Iteration 002 review-boundary work, a local-vs-origin truth-surface drift was observed. The local tree had updates that had not yet been pushed, creating ambiguity about which version was the authoritative reference for review evidence. Explicit post-push verification (`git status --branch` + `git log --oneline -1 origin/HEAD`) reconciled local and origin state.

**Recommendation**: At every lifecycle boundary, include an explicit verification step: "Local HEAD equals origin HEAD after push." Document the exact command output in the boundary commit message. This prevents silent state ambiguity and makes the durable truth surface explicit.

---

## Variance Analysis and Retrospective Ledger

| Item | Planned | Actual | Variance | Notes |
| --- | --- | --- | --- | --- |
| Core implementation (T001-T013) | 12.0 SP | 12.0 SP | 0% | Delivered on plan; task decomposition was accurate. |
| Review boundary | 2.0 SP | 3.5-4.0 SP | +75-100% | Includes FR-008 defect discovery, root-cause analysis, and repair coordination. |
| Implementation repair (FR-008) | 0 SP (unplanned) | 5-8 SP | N/A | Bounded repair: helper path fix + live-execution test fixture. |
| Retro boundary | 0 SP (unplanned) | 3-4 SP | N/A | Includes corpus capture, estimation analysis, and deferral documentation. |
| **Total Iteration Effort** | **17.0 SP** | **~22-25 SP** | **+30-50%** | Self-referential governance work and live-repository testing drove variance. |

### Estimation Confidence for Future Iterations

- **Iteration 001 (10.0 SP planned, 10.0 SP actual)**: 100% accuracy on well-scoped, Phase 1 documentation and guidance work.
- **Iteration 002 (17.0 SP planned, ~22-25 SP actual)**: 65-70% accuracy on proof, corpus, and automation work. Discovery friction and live-repository testing added unplanned effort.

**Recommendation**: For Feature 017+ iterations involving automation or governance self-reference, add a dedicated 3-5 SP buffer for discovery and integration testing. Do not reduce the base estimate; increase the capacity band to 20-25 SP for complex features.

---

## Handoff to Iteration Closeout

Feature 016 Iteration 002 retro boundary is now complete. The following artifacts are durable and ready for the next phase:

1. **Iteration 002 Closed State**: All 13 planned tasks completed and reviewed. Implementation repair (FR-008) is verified and committed. The three blocked hardening-gate concerns are now verified.
2. **Corpus Contributions**: Six corpus-row candidates documented with categories, evidence, and durability rules. Selected carryover rows reconfirmed with current evidence.
3. **Deferral Record**: Three explicitly deferred items captured with rationale and next-owner recommendations.
4. **NFR-001 Baseline Update**: Validator runtime stable at 179550 ms; growth captured for post-Iteration 002 optimization planning.
5. **Process Improvements**: Bounded-repair discipline, live-repository testing, stale-reference scanning, and local-vs-origin verification checkpoints are now durable patterns for future features.

**Next Boundary**: Iteration closeout (Feature 015 Iteration 002 references FR-002 and FR-003 for closeout guidance per the iteration plan).

---

**Retro Boundary Ref**: This artifact records the retro boundary for Feature 016 Iteration 002 only. Iteration closeout remains a separate future step, authorized by explicit human action.
