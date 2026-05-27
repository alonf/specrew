# Retrospective: Iteration 003

**Schema**: v1
**Date**: 2026-05-28

## Execution Summary

**Capacity**: 23.45/25 story_points (delivered, within budget)  
**Tasks**: 34/34 done (100% completion)  
**Review Verdict**: initially REJECT (6 blocking issues) → repaired → ACCEPT  
**Phases**: planning → executing → reviewing → repair-cycle → review-signoff  

## Task Verdicts

All 34 tasks passed review after repair cycle:

- T001-T008: Core intake engine and helpers (8 tasks, mirror parity verified)
- T009-T016: YAML catalogs and auto-decision defaults (8 tasks, data integrity verified)
- T017-T018: Future extension hook directories created (2 tasks)
- T019: Stack-detection mechanism (1 task)
- T020-T025: User-profile persistence and slash-command deployment (6 tasks)
- T026-T028: Prompt/agent/workflow integration (3 tasks)
- T029-T034: Test coverage and regression suite (6 tasks, all scoped checks passing)

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 21-25 SP | ~6 SP | 0 | Cleared at tasks boundary; architectural pivot (engine + data) was approved, capacity increase justified by SC-006 extensibility proof. |
| Discovery/Spikes | none | ~1 SP | +1 SP | Fresh review rejection triggered spec-steward repair cycle; not originally planned but necessary for achieving review-signoff. |
| Implementation | 14-19 SP | ~13 SP | -1 to +4 SP | Core engine delivery predictable; YAML catalog data work lighter than initially feared; mirror-parity verification added confidence. |
| Review | 0 SP | ~3 SP | +3 SP | Initial submission rejected; 6 blocking issues required systematic repair work before acceptance; this was a process learning moment about validation fidelity. |
| Rework | 0 SP | ~1 SP | +1 SP | Spec Steward repair cycle addressed schema mismatch (FR-024), auto-path semantics (FR-023), and evidence gaps (SC-005). Prevented iteration repeat. |

## Drift Summary

**Drift-log reference**: `specs/049-pipeline-hardening-intake/iterations/003/drift-log.md`

| Event | Severity | Category | Resolution |
| ----- | -------- | -------- | ---------- |
| FR-024 schema mismatch | critical | implementation | Updated user-profile.ps1 to use correct field names (expertise.*instead of expertise_dials.*) |
| FR-023 auto-path broken | critical | implementation | Preserved "auto" as string; fixed coercion to numeric 0 |
| Lifecycle artifacts state mismatch | minor | process | Updated plan.md status="reviewing" and marked all 34 tasks done |
| Fabricated timestamps | critical | governance | Applied exact commit timestamps from reviewer evidence |
| Missing SC-005 evidence | minor | documentation | Added Mode A threshold measurement (100% rate exceeds 70% threshold) |

**Summary**: 5 drift events detected during review; all resolved via spec-steward repair cycle before acceptance. No deferred or escalated issues.

## What Went Well

1. **Architectural pivot was sound.** The shift from inline prompt/workflow changes to a discrete engine + data architecture (FR-028..FR-031) paid off: all 34 tasks delivered, extension hook directories reserved for future growth, and SC-006 extensibility proof verified (5th persona added as YAML-only data with zero engine edits). This sets up Feature 049 for long-term maintenance and customization without code churn.

2. **Mirror parity discipline succeeded.** SHA256 verification confirmed that `extensions/specrew-speckit/scripts/intake/*` and `.specify/extensions/specrew-speckit/scripts/intake/*` remain in perfect synchronization across all core modules (7 helpers + engine). This parity discipline is working as intended and unblocks future host-agnostic deployment.

3. **Systematic repair cycle prevented iteration repeat.** When the initial review rejection surfaced 6 blocking issues (FR-024 schema, FR-023 auto-path, timestamps, state drift, missing evidence, and extension/`.specify` parity), the Spec Steward repair work addressed all of them without reopening Iteration 004 or asking for a planning reset. This demonstrates the spec-repair authority is effective.

4. **Quality bar held firm.** The reviewer's rejection was decisive and evidence-driven (not political). All 34 task verdicts pass-/needs-work calls were grounded in requirement traceability, not effort. This gives confidence in the review discipline.

## What Didn't Go Well

1. **Initial submission contained validation gaps that reached review.** The implementation drifted on 5 separate fronts—schema field names (FR-024), auto-path semantics (FR-023), lifecycle state artifacts, timestamps, and evidence completeness—without being caught before submission. This reveals a weakness in pre-review validation or task owner oversight during task completion. The fact that the Reviewer had to manually diagnose these issues suggests the Implementer's own validation/self-review was insufficient.

2. **Boundary-commit discipline was violated.** No commits were made when drifts were discovered during the repair cycle. The final state shows all repairs bundled into a single "chore(state): repair review-signoff handoff" commit, rather than incremental atomic commits at each fix boundary. This violates Proposal 082 Tier 1 boundary-commit discipline and makes the history harder to audit. **Action: reinforce boundary-commit expectations before next iteration.**

3. **Review rejection was not anticipated in planning.** The iteration plan did not reserve capacity for a potential rejection + repair cycle. When the rejection happened, the repair work consumed 1-3 SP that weren't pre-allocated, creating an unplanned phase. Future iteration planning should account for review risk or pre-submission validation gates.

4. **Extension / `.specify` parity was a late discovery.** Mirror parity was a requirement (TG-014) but wasn't explicitly validated during implementation. The reviewer had to spot-check SHA256 hashes manually. This suggests the Implementer did not run their own parity checks during task completion. **Action: add explicit parity-check assertions to test scaffolds.**

## Improvement Actions

1. **Owner**: Spec Steward | **Phase**: before-next-implementation | **Type**: process  
   **Action**: Clarify pre-review validation checklist in task acceptance criteria. For tasks involving schema persistence (like FR-024) or multi-surface feature parity (like FR-023 + extension/`.specify` intake), require Implementer to run schema round-trip and SHA256 parity checks BEFORE marking the task done. Document the commands in the task README.  
   **Expected effect**: Reduce pre-review schema/parity drift from 5 issues → 0-1.

2. **Owner**: Implementer | **Phase**: next-iteration | **Type**: process  
   **Action**: Enforce boundary-commit discipline per Proposal 082 Tier 1. Require atomic commits at each task completion boundary, not bundled repairs. Use git blame / git log to verify commit granularity during review.  
   **Expected effect**: Improve audit trail clarity and catch partial fixes earlier.

3. **Owner**: Planner | **Phase**: before-iteration-004-planning | **Type**: process  
   **Action**: Reserve 2-3 SP capacity buffer in future iterations for potential review-rejection + repair cycles. Frame this as "validation risk" in the iteration plan's Phase Variance.  
   **Expected effect**: Reduce unplanned phase overflow from +1-3 SP → 0.

4. **Owner**: Reviewer | **Phase**: before-next-review | **Type**: process  
   **Action**: Create a reusable SHA256 parity-check script (`verify-mirror-parity.ps1`) that can be called from test scaffolds for any feature requiring extension/`.specify` synchronization. Include it in the F-016 review-evidence template.  
   **Expected effect**: Shift parity validation left from manual review → automated testing.

## Calibration Suggestion

**Capacity baseline for Iteration 004+**: suggest 22-25 SP (no change from baseline)  

**Rationale**:

- Iteration 003 delivered within estimated 21-25 SP band (23.45 actual), demonstrating forecast accuracy despite the mid-iteration repair cycle.
- The architectural pivot (engine + data) has stabilized; future architecture/intake work should be slightly more predictable than raw data-only additions.
- However, review-rejection risk remains non-zero. Recommend reserving 2-3 SP in iteration plans as "validation buffer" rather than raising the headline capacity.
- Iteration 004 (Proposal 120 five-pillar bypass detection) shifts focus to feature-gating and intake-optimization, which is lower-risk than architectural change. Keep baseline at 22-25 SP unless new TG discovers higher complexity.

## Notes

- **Iteration 004 status**: Untouched per reviewer instruction. Reserved for Proposal 120 (five-pillar bypass detection: FR-018..FR-022, SC-004).
- **Boundary-commit discipline**: This iteration revealed violations of Proposal 082 Tier 1 (per retro signal). Recommend validator-rule prioritization in upcoming release.
- **Drift recovery**: All 5 drift events from drift-log.md were resolved in-place via spec-steward repair cycle. No escalation to human decision or deferral required.
- **This artifact scaffolded from**: plan.md, state.md, drift-log.md, review.md, quality-evidence.md, and tasks-progress.yml.
