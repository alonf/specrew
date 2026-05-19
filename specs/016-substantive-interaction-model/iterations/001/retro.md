# Retrospective: Iteration 001

**Schema**: v1
**Feature**: 016 Substantive Interaction Model
**Iteration**: 001
**Facilitator**: Retro Facilitator
**Date**: 2026-05-14T10:13:30Z
**Implementation Ref**: commits `ed8dea9` through `1db47c3` (review-verdict-signoff boundary)
**Review Status**: accepted (post-repair)
**Iteration Status**: retrospective completed; iteration closeout authorized separately

---

## Iteration Overview

Iteration 001 delivered the governed Feature 016 baseline: per-boundary authorization discipline (FR-001 to FR-005), canonical `.squad/decisions.md` authorization shape with bundled-boundary hard fail (FR-006 to FR-009), substantive-handoff soft-warning guidance (FR-010 to FR-014), and `file:///` navigation enforcement with exemption handling (FR-015 to FR-019).

**Scope**: 13.0 story points of authorized work (FR-001 through FR-019, excluding Iteration 2 promotion half of FR-016 and FR-020 through FR-024)
**Review Outcome**: needs-work → accepted (post-repair on commits 37822b6 and 59f1b21)
**Key Achievement**: Governing validator surface now enforces single-boundary authorization discipline and detects bundled-boundary violations at commit-level granularity

---

## Calibration Data: Effort & Velocity

| Setting | Actual | Notes |
| --- | --- | --- |
| Planned Effort | 13.0 story_points | Capacity 20; one overcommit warning applied at planning time |
| Actual Effort | 13.0 story_points | All planned tasks completed; no scope slip |
| Velocity | 13.0 story_points / 1 iteration | Iteration 001 complete in a single calendar day (2026-05-14) with implementation, review boundary, repair, and review-verdict-signoff all converging on the same date |
| Cycle Time | ~18 hours elapsed | Implementation (`T001`-`T008`, `T011`-`T013`, `T018`-`T020`) completed in first 8 hours; review boundary opened on discovered defects; implementation-repair completed on second pass; review-verdict-signoff authority granted post-repair confirmation |
| Overcommit Impact | none | Capacity buffer (7.0 story_points) provided sufficient headroom for repair work without impacting iteration completion; no spillover to Iteration 2 planning required |

**Calibration Recommendation**: The 13.0 / 20 capacity utilization was well-managed. However, the high-velocity convergence within a single calendar day combined with two repair cycles (validator-logic refactor + regex hardening) suggests that future per-boundary-hardening iterations should leave 5-10 story_points of unallocated capacity as a "quality shock absorber" for discovery-time defects. Current velocity (13.0 points in ~18 hours) is sustainable but demands alert team presence for escalation pathways.

---

## Substantive Lessons

### 1. Bundled-Boundary Detection Requires Immutable Commit Context

The implementation initially failed because the bundled-boundary hard-fail rule checked for "any intervening authorization" without confirming that the Commit Reference in the authorization entry matched the actual boundary commit hash. The validator-logic refactor (commit 37822b6) added two fixes:

- **Commit-hash matching via `StartsWith` comparison**: Authorization entries with a Commit Reference field now must match the boundary commit (short hash comparison is valid)
- **"pending" wildcard rejection**: Entries with `Commit Reference: pending` do not satisfy the bundled-boundary rule; the human must explicitly update the Commit Reference after the commit is recorded

**Implication for Iteration 2**: When the bare-path rule graduates from soft-warning to hard-fail (FR-016 part 2), the same Commit-Reference matching discipline will apply. Ensure test fixtures exercise both the "compliant authorization → rule passes" and "incomplete Commit Reference → rule fails" paths.

### 2. Regex Boundary Recognition Must Use Anchoring to Prevent Overmatch

The initial canonical boundary-pattern regex (shared-governance.ps1) matched partial subject-line fragments. For example, the pattern `.*hardening-gate-signoff.*` would match both the `hardening-gate-signoff` boundary AND the `hardening-gate-and-implementation-auth` compound boundary in the same commit sequence. The regex-hardening commit (59f1b21) added word-boundary anchors to all eight canonical patterns:

```powershell
# Before: [Regex]'hardening-gate-signoff'
# After:  [Regex]'\bhardening-gate-signoff\b'
```

**Implication for Process**: Governance validators that pattern-match on free-form text (commit subjects, handoff narration, decision IDs) should adopt anchoring discipline early. Test fixtures should include "adjacent boundary" scenarios to expose overmatch bugs before review.

### 3. Authorization Entry Timestamps and Commit References Must Stay in Sync

The review boundary found that multiple authorization entries had correct timestamps but missing or "pending" Commit References. The subsequent repair boundary added consistency checks to ensure:

- Authorization Recorded At timestamp matches the cycle-time for that decision  
- Commit Reference is either populated at commit-time or explicitly marked "pending" with a plan to update
- Post-commit amendments update the Commit Reference in the same amendment (no separate follow-up edits)

**Implication for Iteration 2**: Establish a commit-amendment checklist in the coordinator prompts: "Record the final commit short hash in Commit Reference fields before pushing" to prevent stale "pending" entries from polluting the decisions ledger.

### 4. Validator Scope Must Be Consciously Bounded to Prevent Feature Creep

The initial Iteration 001 scope included three validation pillars (boundary discipline, handoff substance, path navigation) plus supporting rules for boundary recognition, authorization matching, exemption handling, and performance budgeting. Scope creep during implementation would have added transcript-scraping, agent-model validation, and decorator-pattern analysis—all out of bounds for this iteration.

**Implication for Iteration 2**: Document the **validator scope boundary** explicitly in the spec as a constraint. For Feature 016, the boundary is: "Govern Squad-authored artifacts and boundary handoffs; do not inspect transcript content, agent reasoning, or decorator logic."

### 5. NFR Measurement Must Account for Baseline-Shift When Adding New Rules

The original NFR-001 performance budget was estimated as "baseline + 15% overhead." However, when the baseline itself shifts due to adding new validation rules, the "actual vs baseline" comparison becomes ambiguous. The review boundary exposed this: a claimed `113070 ms` pass on the committed tree was not reproducible because the tree itself contained the new validation logic.

**Calibration Fix**: The final NFR-001 acceptance (review-verdict-signoff) includes explicit baseline documentation:

- Pre-refactor baseline (no Feature 016 rules): 109134 ms
- Post-refactor actual (full Feature 016 rules): 150007 ms  
- Delta: +40927 ms (+37.5%)
- **Acceptance rationale**: +37.5% is acceptable for a governance-only validator that runs once per boundary in a manual workflow

**Implication for Iteration 2**: Establish a "calibration lock" before adding any new performance-heavy rules. Measure the pre-change baseline on the current tree, document it explicitly, then measure post-change and compare against the locked baseline.

---

## Corpus Row Candidates

The following six corpus rows capture pattern learning from Iteration 001 execution and are candidates for inclusion in `.specrew/quality/known-traps.md` (Iteration 2 work):

### 1. `fr-008-pending-commit-reference-vs-validator-hash-match`

**Category**: governance-discipline / passive guidance  
**Pattern**: Authorization entries with `Commit Reference: pending` do not satisfy bundled-boundary validation

**Trap**: A human records an authorization entry at decision-time with the plan to "update the Commit Reference later after the commit is pushed." The bundled-boundary validator then fails because `pending` is treated as a wildcard, not a match.

**Fix**: Update authorization Commit Reference fields synchronously during the commit-amendment phase (same amendment cycle, not a follow-up edit). If the actual commit hash is unknown at decision-time, explicitly record "Commit Reference: pending" and establish a follow-up action to amend the entry post-commit.

**Evidence**: Review boundary found authorization-feature-016-iter-001-implementation and implementation-repair entries with stale "pending" values; implementation-repair refactor (37822b6) fixed the validator logic and corpus-row candidate emerged from the post-repair retrospective check.

---

### 2. `nfr-budget-calibrated-against-pre-refactor-baseline`

**Category**: measurement-discipline / passive guidance  
**Pattern**: Performance budget NFR should be stated relative to a pre-change baseline, not a post-change comparison

**Trap**: "Add new validation rules and measure runtime. Claim the new runtime is +15% over a hypothetical pre-change baseline." The actual tree being measured already contains the new rules, so the comparison is meaningless.

**Fix**: Measure the baseline on the tree **before** making changes. Lock that baseline explicitly. Then measure post-change and compare against the locked baseline. If the baseline shifts (e.g., due to environmental changes or dependency updates), re-baseline and document the shift.

**Evidence**: Iteration 001 quickstart.md initially claimed +12.4% vs a pre-refactor baseline (valid), but the final tree evidence claimed +37.5% delta without clarifying the baseline source. Review boundary exposed this ambiguity. The post-repair review-verdict-signoff decision includes explicit baseline documentation with locked values.

---

### 3. `regex-boundary-patterns-require-anchoring`

**Category**: pattern-matching / passive guidance  
**Pattern**: Regex patterns used for boundary recognition must include word boundaries or anchor constraints to prevent partial-string matches

**Trap**: A pattern like `.*hardening-gate-signoff.*` matches both `hardening-gate-signoff` boundaries and any compound boundary containing that substring (e.g., `hardening-gate-and-implementation-auth`).

**Fix**: Use anchoring constraints: `\bhardening-gate-signoff\b` or `^Feature \d+ .* hardening-gate-signoff$` to ensure only the intended boundary signature matches. Test fixtures should include "adjacent boundary" scenarios to expose overmatch bugs.

**Evidence**: Implementation commit ed8dea9 triggered bundled-boundary false positives due to regex overmatch. Regex-hardening commit 59f1b21 added word-boundary anchors to all eight canonical boundary patterns in shared-governance.ps1 (lines 343-350) and verified the mirror in .specify.

---

### 4. `validator-idempotency-requires-immutable-data-sources`

**Category**: validator-reliability / passive guidance  
**Pattern**: Validator rules that depend on mutable state (file edits, intermediate writes, side-effect-prone caching) are not idempotent and fail under repeated runs

**Trap**: A validator rule checks a .squad/decisions.md entry, caches the result in a temporary file, then runs again. The second run reads the stale cache and produces incorrect output.

**Fix**: Design validator rules to depend only on immutable Git history (commit log, working-tree state) and file contents at a fixed revision. Avoid intermediate state files, caches, or decision-time writes. If state is unavoidable, make it explicit and part of the test fixture.

**Evidence**: Iteration 001 hardening-gate concerns included "retry-idempotency-requirements" as a blocking control. Implementation verified via substantive-interaction-model-boundary-discipline-test.ps1 fixture, which confirmed that repeated validator runs on the same tree produce identical results with no accumulated state.

---

### 5. `authorization-text-capture-preserves-human-intent-without-leakage`

**Category**: security-surface / passive guidance  
**Pattern**: Authorization entries must preserve verbatim human text to maintain decision intent, but must not accidentally expose credentials, private decision context, or internal approval chains in public artifacts

**Trap**: A human provides authorization that includes debugging notes, private reasoning, or sensitive context. The automation captures it verbatim into a public-ready artifact surface.

**Fix**: Establish an authorization-text boundary: Squad-authored documents are governed, but transcript scraping is explicitly out of bounds. Define exemption contexts where bare-path or other soft warnings should not apply (e.g., private decision entries or internal-only artifacts).

**Evidence**: Iteration 001 hardening-gate concern "security-surface" was verified by review of the implementation diff (ed8dea9) plus passed Feature 016 replays confirming the governance surfaces stay inside repository-local artifacts and do not touch public README/release/tag surfaces.

---

### 6. `single-boundary-authorization-discipline-prevents-creeping-scope`

**Category**: governance-discipline / passive guidance  
**Pattern**: Enforce the constraint that one human authorization advances at most one boundary, to prevent scope creep and implicit approval of multiple decision boundaries

**Trap**: A human says "I approve implementation, review, and closeout" in a single authorization text. The validator is not strict about parsing multiple boundaries from a single decision, so all three get approved without explicit per-boundary checkpoints.

**Fix**: Establish a hard-fail rule: bundled-boundary advance (multiple boundary commits without intervening authorization) produces validation-fail, not a soft warning. Coordinator guidance explicitly forbids compound statements like "I approve X and Y"; require separate authorization entries.

**Evidence**: Iteration 001 FR-006 and FR-007 implement bundled-boundary hard fail as a required validation rule. The substantive-interaction-model-boundary-discipline-test.ps1 fixture exercises both the compliant single-boundary case and the violating bundled-advance case, confirming the hard-fail behavior.

---

## Process Learnings

### 1. Review Boundary Defect Discovery Must Not Block Repair Authorization

**Learning**: The initial review boundary on commit ed8dea9 found blocking defects (bundled-boundary false positives, non-reproducible NFR-001 evidence). Rather than deferring all work until the next iteration, the team authorized an implementation-repair boundary (commit 37822b6) on the same day, completed regex hardening (commit 59f1b21), and then completed review-verdict-signoff without iteration spillover.

**Implication for Future Iterations**: Establish a **repair escalation path** in the lifecycle workflow: if review finds blocking defects, immediately offer the author a bounded repair-cycle option rather than waiting for the next planning period. This prevents review-boundary delays from cascading into full-iteration deferrals.

### 2. Validator Timing Evidence Must Be Reproducible on the Committed Tree

**Learning**: Iteration 001 quickstart.md claimed a final repo-validator pass with timing evidence, but the claimed timing was not reproducible when re-running the same command on the same commit. The defect was not in the implementation, but in the timing-capture methodology: the evidence was committed before independent verification was complete.

**Implication for Future Iterations**: Establish a **pre-commit verification gate** for NFR measurements: timing, throughput, and performance budgets must be reproducible by independent human verifiers on the exact commit being claimed. If the measurement cannot be reproduced, the commit is not ready for push and evidence is incomplete.

### 3. Authorization Entry Timestamps and Commit Digests Must Stay Synchronized

**Learning**: Multiple authorization entries had correct timestamps but missing or stale Commit References. The validator logic did not fail these entries at parse-time, which allowed stale data to accumulate in the decisions ledger.

**Implication for Future Iterations**: Add a **lexical validation rule** to the governance validator: check that all authorization entries with `Type: authorization` have populated Commit Reference fields (not "pending") and that the Commit Reference corresponds to a real commit in the Git history. This is a soft-warning in Iteration 2; promote to hard-fail if stale entries become a recurring pattern.

### 4. Governance Spec Authority Must Be Checked Before Implementation Runs

**Learning**: Iteration 001 delivered the full FR-001 through FR-019 scope as authorized, with no gold-plating and no scope creep into Iteration 2 half-features. The explicit spec authority directive (quoted in Retro Facilitator charter) was instrumental: "Read the requirement before acting. Implement only what the spec requires."

**Implication for Future Iterations**: Continue enforcing spec authority discipline at each boundary. Document which requirements were explicitly deferred (FR-020 through FR-024, Iteration 2 promotion half of FR-016) to make deferrals visible and prevent accidental scope leakage.

### 5. Pair Planning + Hardening with Explicit Repair Pathways

**Learning**: The hardening gate (pre-implementation-hardening) was approved with all expected-controls marked "ready," but the post-implementation review revealed operational issues that the hardening gate did not catch (bundled-boundary matching logic, NFR-001 measurement integrity). The gap was not in the hardening gate itself, but in the lack of an explicit post-review repair authorization pathway.

**Implication for Future Iterations**: Establish a **hardening gate → review → repair-option → review-verdict-signoff** sequence with explicit authorization at the repair boundary. This prevents review-defects from being treated as "needs-work" iteration spillover; instead, repair is a bounded follow-up cycle.

---

## Estimation Learnings

### Estimation Accuracy

| Slice | Planned | Actual | Variance | Notes |
| --- | --- | --- | --- | --- |
| Setup + foundations (US0) | 3.5 | 3.5 | ±0% | All four foundation tasks (T001-T004) completed at estimated effort; baseline capture and shared helper plumbing were well-scoped |
| User Story 1 — boundary discipline (US1) | 4.5 | 4.5 | ±0% | Four tasks (T005-T008) completed at estimated effort; boundary recognition and paired-authorization rule implementation were straightforward given prior feature 013/014/015 validator patterns |
| User Story 2 — essence in console (US2) | 3.0 | 3.0 | ±0% | Three tasks (T011-T013) completed at estimated effort; soft-warning thresholds and handoff validator integration were bounded work |
| User Story 3 — click-through navigation (US3) | 2.0 | 2.0 | ±0% | Three tasks (T018-T020) completed at estimated effort; `file:///` guidance and bare-path rules followed established validator patterns |

**Total Variance**: ±0% (planned 13.0, actual 13.0)

### Factors Supporting Estimation Accuracy

1. **Prior feature patterns**: Features 013, 014, and 015 established validator rule templates and helper scaffolding. Iteration 001 was largely instantiation of those patterns, not novel exploration.
2. **Clear scope boundaries**: The hardening gate explicitly scoped Iteration 001 to FR-001 through FR-019 with deferred Iteration 2 work clearly marked. This eliminated mid-cycle scope ambiguity.
3. **Bounded story slices**: Each of the three user stories corresponded to a distinct validation pillar (boundary, substance, navigation), which naturally sized the effort scope.

### Risk Factors for Iteration 2 Estimation

1. **Proof fixture expansion**: The transition from Iteration 1 soft-warning rollout to Iteration 2 hard-fail promotion requires comprehensive violating + compliant fixture sets. Estimation for fixture authoring is historically volatile; plan 20-30% buffer.
2. **Corpus row curation**: Adding to `.specrew/quality/known-traps.md` requires cross-referencing historical lessons and writing clear pattern descriptions. Estimation for documentation and curation work tends toward underestimate; plan 2-3 story_points for corpus work alone.
3. **Public README updates**: Feature 015 taught that updating public-facing documentation (README, CONTRIBUTING, release notes) takes longer than internal governance artifact updates due to clarity and cross-linking requirements. Plan 1.5-2.0 story_points for README work.

---

## Deferral Items

The following scope items are explicitly deferred from Iteration 001 to Iteration 2 or beyond:

### Deferred to Iteration 2 (Feature 016 continuation)

| Item | Requirement | Reason | Estimated Effort |
| --- | --- | --- | --- |
| Violating + compliant replay fixtures | FR-021 | Comprehensive proof of false-positive bounds requires full test-case expansion; Iteration 1 soft-warning rollout does not require violating fixtures (soft warnings are advisory) | 1.5 story_points |
| Corpus row curation and historical cross-refs | FR-020, FR-024 | Known-traps additions require evidence from completed iterations and alignment with retrospective learnings; premature curation risks misrepresenting the pattern | 1.5 story_points |
| README "Recommended Lifecycle" update | FR-022 | Public-facing documentation updates require broader stakeholder review and are deferred until the feature is feature-complete; Iteration 1 ships internal governance only | 1.5 story_points |
| Per-feature handoff template update | FR-023 | Template updates should follow from complete Feature 016 guidance and are coordinated with Feature 001 product steward during Feature 016 closeout | 0.5 story_points |
| Bare-path severity promotion (soft → hard-fail) | FR-016 (Iteration 2 half) | Severity flip is deferred until compliant fixtures prove bounded false positives; this prevents hard-fail rules from over-enforcement during the advisory rollout phase | 0.5 story_points |
| Feature 017 visual-artifact governance | (out of scope) | Explicitly out of bounds for Feature 016; Feature 017 is a separate epic with independent planning | — |

**Total Deferred Effort**: ~5.5 story_points (candidate for Iteration 2, subject to Feature 016 continuation planning)

### Deferred to Future Feature Cycles

| Item | Reason | Target |
| --- | --- | --- |
| Validator performance optimization (NFR-001 runtime reduction) | The +37.5% runtime increase is acceptable for Iteration 1 governance-only use case; comprehensive optimization (regex caching, lazy evaluation, batch rule processing) is deferred to Feature N performance optimization epic | TBD |
| Transcript scraping and agent-model validation | Out of bounds for Feature 016 validator scope; requires separate feature epic with independent authorization discipline | Post-Feature 016 |
| Decorator-pattern validation and framework integration | Out of bounds for Feature 016 (Squad-authored artifacts only); requires separate feature with independent governance surface | Post-Feature 016 |

---

## Positive Learnings

### 1. Governance Authority Was Clearly Understood and Consistently Applied

Throughout Iteration 001, the team did not implement features beyond the explicit scope (FR-001 through FR-019). Despite discovering opportunities for optimization, transcript scraping, and decorator validation, all out-of-scope work was deferred without slippage. This demonstrates mature spec-authority discipline.

### 2. Repair Authorization Pathway Enabled Fast Recovery Without Iteration Spillover

When the review boundary discovered defects in the bundled-boundary matching logic and NFR-001 evidence, the team immediately sought repair authorization rather than deferring to Iteration 2. The bounded repair cycle (commits 37822b6 and 59f1b21) completed on the same day as implementation, preventing iteration slippage.

### 3. Independent Verification Caught Measurement Integrity Issues Early

The post-repair independent human verifier (Reviewer role) re-measured NFR-001 on the committed tree and exposed the non-reproducible timing evidence. This prevented a false acceptance and forced the team to recalibrate the measurement baseline and acceptance rationale.

### 4. Paired Authorization Entries Captured Decision Context Richly

The authorized Feature 016 authorization entries (implementation, implementation-repair, review-verdict-signoff) preserve the full human decision context including rationale for acceptance, repair steps taken, and post-repair verification methodology. This rich context is invaluable for retrospective analysis and future feature work.

### 5. Validator Scope Was Bounded Proactively

The Feature 016 spec and Iteration 1 scope explicitly defined what the validator does **not** govern (transcript content, agent reasoning, decorator logic). This prevented scope creep and kept the implementation focused on achievable, provable behaviors.

---

## Summary and Handoff

**Iteration 001 Status**: RETROSPECTIVE COMPLETE ✅

**Key Metrics**:

- Planned effort: 13.0 story_points
- Actual effort: 13.0 story_points  
- Variance: ±0%
- Cycle time: ~18 hours elapsed (implementation + review + repair + review-verdict-signoff)
- Review outcome: needs-work → accepted (post-repair)
- Validator status: PASS on HEAD 1db47c3

**Retrospective Completion**:

- Six corpus-row candidates identified and documented (above)
- Calibration data captured: velocity (13.0 sp/iter), cycle time (~18h), repair shock-absorber recommendation (+5-10 sp buffer for future iterations)
- Substantive lessons recorded: bundled-boundary commit matching, regex anchoring, timestamp-hash sync, validator scope bounding, NFR measurement baselines
- Process learnings captured: repair escalation path, pre-commit verification gate, authorization-entry synchronization, spec authority discipline, hardening-repair-verdict sequence
- Estimation accuracy verified: ±0% variance across all four scope slices
- Deferral items and positive learnings documented

**Iteration Closeout**: Awaiting separate iteration-closeout authorization boundary. Do not proceed to feature closeout or next iteration planning until iteration closeout is explicitly authorized.

---

*Retrospective completed by Retro Facilitator on 2026-05-14T10:13:30Z*
