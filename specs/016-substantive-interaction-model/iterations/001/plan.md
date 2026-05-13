# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20 story_points
**Started**: 2026-05-14
**Completed**:

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | The coordinator prompt MUST require Squad to stop and request explicit human authorization after EACH of the 7 iteration boundary commits: planning, hardening-gate-and-implementation-auth, implementation, review-boundary, review-verdict-signoff, retro-boundary, and iteration-closeout. These 7 iteration boundaries MUST be enumerated by name in the coordinator prompt. `feature-closeout` remains a separate feature-level boundary and is not part of the per-iteration count. **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-002 | The coordinator prompt MUST explicitly forbid bundled boundary advances. The rule: "Each boundary commit requires its own immediately-preceding authorization; one human authorization advances at most one boundary." Even when the user says "continue" or provides broad multi-step authorization, Squad MUST NOT emit multiple boundary commits without intervening explicit per-boundary authorization. **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-003 | The coordinator prompt MUST clarify that "continue" from the user means "advance to the next single boundary stop, then halt and ask." Squad MUST treat "continue" as a single-step instruction, not a license for autonomous multi-boundary advance. **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-004 | The coordinator prompt MUST include a worked example showing the compliant 7-authorization-per-iteration pattern with explicit authorization phrasing for each boundary (matching the dogfooding pattern established in Features 011-014). **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-005 | The coordinator prompt MUST include a worked example showing a violating bundled-advance pattern (Squad emitting review + retro + closeout commits without intervening authorization) and the validator FAIL response. **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-006 | `validate-governance.ps1` MUST be extended with hard-validator rule `validation-fail.bundled-boundary-advance` that: detects when 2 or more boundary commits exist in the commit history since the most recent human authorization recorded in `.squad/decisions.md`, emits structured FAIL output naming the offending commit pair, the iteration, and the missing intervening authorization, and returns non-zero exit code so the validator can be used as a CI gate. **Owner role**: Validator steward. **Delivery window**: Iteration 1. | — |
| FR-007 | The validator MUST recognize the canonical boundary-commit signature patterns (subject-line regex). Recognition MUST be subject-line-pattern-based, not file-content-based, to keep the rule mechanical and fast. The canonical patterns are listed in the Implementation Boundary section. **Owner role**: Validator steward. **Delivery window**: Iteration 1. | — |
| FR-008 | Squad MUST auto-generate the canonical human-authorization shape in `.squad/decisions.md` from the user's authorization paste. Required captured fields: Decision ID, Type (`authorization` or `sign-off`), Boundary, Approving Human, Recorded At (ISO 8601 UTC), Commit Reference, Authorization Text (verbatim). The boundary inspection flow MUST allow the user to review or override the generated metadata before advancing. **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-009 | Paired authorizations (hardening-gate sign-off + implementation authorization) MUST be recorded as TWO distinct entries in `.squad/decisions.md`, even when the user supplies one authorization paste. Squad MUST auto-generate the pair as separate entries; single-entry multi-boundary authorizations are rejected as bundled. **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-010 | The coordinator prompt MUST require Squad's boundary handoffs to use Feature 014's three-section format AND populate each section substantively. For planning, implementation, review, and retro, "What I just did" MUST include at least 3 specific identifiers (commit hash, `file:///` path, FR-###, T###, or decision reference) AND at least 50 words. For iteration-closeout and feature-closeout, the section MAY satisfy a soft OR threshold (either the identifier count OR the word-count threshold). These thresholds are fixed for Feature 016 and MUST NOT be made tunable per project. "Why I stopped" MUST name the specific boundary phase being entered (not generic "next step"). "What I need from you" MUST be a specific actionable request naming the boundary, the inspection target(s), and the verdict required. This requirement applies to Squad's console handoffs only, not downstream artifact bodies. **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-011 | `validate-governance.ps1` MUST be extended with soft-validator rule `soft-warning.thin-what-i-just-did` that fires when the "What I just did" section of a boundary handoff fails the fixed threshold for its lifecycle phase: planning, implementation, review, and retro require both the identifier count and the 50-word minimum; iteration-closeout and feature-closeout require at least one of those two thresholds. This rule remains soft-warning throughout Feature 016. **Owner role**: Validator steward. **Delivery window**: Iteration 1. | — |
| FR-012 | `validate-governance.ps1` MUST be extended with soft-validator rule `soft-warning.unspecific-stop-boundary` that fires when "Why I stopped" content does not name the specific boundary phase. The validator MUST cross-reference the current iteration state to detect mismatches (e.g., Squad says "next is review" but the iteration is at retro boundary). **Owner role**: Validator steward. **Delivery window**: Iteration 1. | — |
| FR-013 | `validate-governance.ps1` MUST be extended with soft-validator rule `soft-warning.unactionable-user-request` that fires once per handoff when "What I need from you" content does not name (a) the specific boundary being authorized, (b) the inspection target(s) as `file:///` references, AND (c) the verdict required. The emitted warning MUST list every missing component (`boundary-name`, `inspection-target`, `verdict-required`) in that single warning. **Owner role**: Validator steward. **Delivery window**: Iteration 1. | — |
| FR-014 | The coordinator prompt MUST include worked examples of substantive vs thin handoffs for each lifecycle phase, with annotations explaining what makes each section substantive. **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-015 | The coordinator prompt MUST require `file:///` URL format for ALL artifact references in Squad's narration and boundary stop messages. Bare relative paths or bare absolute paths in narration are forbidden. **Owner role**: Governance steward. **Delivery window**: Iteration 1. | — |
| FR-016 | `validate-governance.ps1` MUST implement the bare-path-in-boundary-handoff rule as a parameterized severity rule so rollout can change by configuration rather than rewrite. In Iteration 1, the rule emits `soft-warning.bare-path-in-boundary-handoff`; in Iteration 2, after exemption-list integration tests prove bounded false positives, the same rule flips to `validation-fail.bare-path-in-boundary-handoff`. The rule fires when a boundary stop message contains a bare path reference outside approved exemption contexts. **Owner role**: Validator steward. **Delivery window**: Iteration 1-2. | — |
| FR-017 | `validate-governance.ps1` MUST be extended with soft-validator rule `soft-warning.bare-path-in-narration` that fires when non-boundary Squad text (in-flight progress updates, tool-call narration) contains bare path references. Lower severity than the boundary-handoff rule because in-flight narration is less critical for click-through. **Owner role**: Validator steward. **Delivery window**: Iteration 1. | — |
| FR-018 | The validator MUST define explicit exemptions for paths in: shell-command arguments (e.g., `git add specs/...`), inline-code blocks, log output, JSON/YAML literals, regex patterns, and file glob arguments. Projects MAY extend that exemption list via `.specrew/config.yml`, but each extension MUST carry recorded human approval with approver name and rationale so exemption growth remains reviewable. These contexts contain paths but are not intended for click-through navigation. **Owner role**: Validator steward. **Delivery window**: Iteration 1. | — |
| FR-019 | When Squad cites an artifact via `file:///` URL, the validator MUST check that the file actually exists at that path. Citations to non-existent paths emit soft-warning `soft-warning.broken-file-url-reference`. **Owner role**: Validator steward. **Delivery window**: Iteration 1. | — |
| FR-020 | New corpus rows MUST be added to `.specrew/quality/known-traps.md`: Category `boundary-discipline`, ID `bundled-boundary-advance` — validator-enforced per FR-006; Category `interaction-model`, ID `thin-handoff-summary` — validator-enforced per FR-011-013 and marked as future graduation-candidate while remaining soft-warning in Feature 016; Category `interaction-model`, ID `bare-path-in-handoff` — validator-enforced per FR-016-017 with cross-reference notes documenting its Iteration 1 soft-warning state and Iteration 2 hard-fail graduation; Category `interaction-model`, ID `thin-artifact-content` — passive/not validator-enforced in Feature 016, recorded only as future candidacy for artifact-scope expansion. Each row MUST cite the implementing FRs and integration tests (if any). **Owner role**: Quality steward. **Delivery window**: Iteration 2. | — |
| FR-021 | Integration tests MUST exercise each new rule against synthetic violating fixtures (must emit warning/FAIL) and compliant fixtures (must NOT emit). Test coverage MUST use scaffold-replay-path patterns per the test-integrity corpus row. Exemption-list integration tests MUST explicitly demonstrate bounded false positives before FR-016 severity flips from Iteration 1 soft-warning to Iteration 2 hard-fail. **Owner role**: Quality steward. **Delivery window**: Iteration 2. | — |
| FR-022 | The README "Recommended Lifecycle" section and validator documentation MUST be updated to describe the three-pillar interaction model with explicit reference to the 7-authorization pattern, the essence-in-console expectation, the click-through navigation convention, and the validator's scope limitation to Squad-authored handoffs/artifacts rather than conversation transcripts or user-typed text. **Owner role**: Documentation steward. **Delivery window**: Iteration 2. | — |
| FR-023 | The per-feature handoff template MUST include explicit worked examples of substantive boundary handoffs for each of the 7 boundaries. **Owner role**: Documentation steward. **Delivery window**: Iteration 2. | — |
| FR-024 | Related historical corpus rows MUST be cross-referenced from this feature's new corpus rows so future readers can trace the full enforcement evolution: Feature 012's `human-handoff-id-context` (numeric ID descriptors); Feature 014's `empty-user-action-section` (placeholder text in user-action section); Feature 014's `transitional-stop-claim` (transitional narration disguised as stop). **Owner role**: Quality steward. **Delivery window**: Iteration 2. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: Mixed frontend and backend/service signals are present in the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | TBD | Populate after task decomposition and approval gating |
| Discovery/Spikes | TBD | Capture any required risk-reduction work revealed during planning |
| Implementation | TBD | Sum planned delivery tasks once the task table is complete |
| Review | TBD | Estimate review/demo effort after verdict flow is defined |
| Rework | TBD | Expected needs-work buffer if review finds gaps |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, FR-022, FR-023, FR-024
- User stories represented in current scope: 
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.