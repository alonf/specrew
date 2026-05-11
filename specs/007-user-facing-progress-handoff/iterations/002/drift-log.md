# Drift Log: Iteration 002

**Schema**: v1  
**Feature**: 007-user-facing-progress-handoff  
**Iteration**: 002  
**Last Updated**: 2026-05-11

---

## Summary

| Metric | Count |
|--------|-------|
| Total drift events | 1 |
| Resolved via implementation correction | 1 |
| Resolved via spec update | 0 |
| Resolved via revert | 0 |
| Deferred for later decision | 0 |
| Escalated to human decision | 0 |

---

## Event Log

### DR-001 — FR-017 review-link enforcement/observability gap

- **Detected**: 2026-05-11 during review
- **Task ID**: T010
- **Requirement**: FR-017; Iteration 002 risk dimension `Review-link navigation compatibility`
- **Severity**: Moderate
- **Deviation**: The iteration documented the `file:///` review-link rule and added `soft-warning.review-file-reference-format` to the checklist, but the runtime validator does not emit that warning and the validation lane has no contract test proving the rule is enforced. A reviewer replay using a local review request with only a plain Windows path still returned `status: pass`.
- **Impact**: FR-017 is documented but not enforced or observable, and the hardening-gate evidence overstates the runtime completeness of the review-link slice.
- **Resolution Path**: Implemented runtime detection for missing `file:///` review URIs, added an integration test and validation-lane coverage, and corrected hardening-gate evidence to reflect the executable warning.
- **Recorded At**: 2026-05-11 (review phase)
- **Closed At**: 2026-05-11 (closure confirmed by accepted re-review)

---

## Monitoring Areas

The following areas are identified as drift-sensitive and should be monitored during implementation:

1. **Soft-validator detection logic accuracy**: T007 implementation must match T006 design document specification for missing progress status, missing next step, and three-or-more-acronyms pattern detection. Any deviation from T006 specification is drift.

2. **Integration test coverage integrity**: T008 must exercise actual soft-validator runtime path (not just checklist artifact validation). Using mock internal state instead of invoking validator runtime is drift from test-integrity trap requirements.

3. **Validation lane authorization documentation**: T009 must document exact authorized soft-validator commands in both plan.md task definition AND hardening-gate concern evidence. List mismatch between plan and hardening-gate is drift (validation-lane-completeness trap).

4. **Post-implementation evidence recording accuracy**: T010 post-implementation evidence recording must update all applicable concern fields in hardening-gate.md from `pending-post-implementation` to `recorded` and update Post-Implementation Verification field to `✅ COMPLETE`. Incomplete or inconsistent evidence recording is drift.

5. **Plain-language-first absorption**: T007 soft-validator must implement detection rule from T006 design without adding or removing requirements. Changing the governance-term candidate set without documented justification is drift.

6. **Soft-warning vs. hard-blocking behavior**: T007 soft-validator must flag missing handoff fields without blocking response delivery. Adding hard-blocking exit codes or exceptions for handoff incompleteness alone is drift from FR-016 requirement.

7. **Pre-implementation hardening gate boundary**: The hardening-gate.md artifact is a planning-time document created before implementation authorization, not an implementation deliverable. Moving hardening-gate creation into T010 scope or treating it as a runtime task is drift from the planning/human-authorization boundary discipline.

8. **Review-file navigation regression**: T010 polish must preserve the new FR-017 rule that local file review requests use a `file:///` URI with the absolute Windows path. Reverting to plain text paths only, or documenting a different primary format without explicit human approval, is drift from the accepted review workflow.

---

## Resolution Guidelines

When drift is detected:

1. **Document immediately**: Record the event in this log with timestamp, task ID, description, and impact
2. **Classify**: Determine if resolution requires spec update, revert, deferral, or human decision
3. **Route**: If ambiguity exists about whether implementation matches spec intent, escalate to Spec Steward or Feature Owner before proceeding
4. **Trace**: Update traceability records if resolution changes requirement mapping

---

## Notes

- This iteration's scope is runtime implementation of already-specified handoff validation behavior; substantial drift is unlikely if T006 design document is followed faithfully
- Iteration 001 delivered zero drift events; this pattern should continue in Iteration 002 if implementation stays within Phase 3 boundaries
- Any temptation to expand soft-validator scope beyond the three core rules (missing progress status, missing next step, jargon-first lead) should be deferred to feature closeout or future enhancement
- The pre-implementation hardening-gate.md is a planning-time artifact, not an implementation task. T010 records post-implementation evidence only, not gate creation. Planning stops at the hardening-gate sign-off / human authorization boundary.
- Review found a real FR-017 gap: documentation rollout alone does not satisfy the hardened-governance boundary when the checklist advertises an executable warning but the validator and lane cannot observe a missing `file:///` review URI.
- Accepted re-review confirmed the repair landed in all required layers: checklist parity, validator enforcement, validation-lane observability, and hardening-gate/state truth.
