# Drift Log: Iteration 002

**Schema**: v1
**Feature Ref**: `specs/011-specrew-start-conditional-pause/spec.md`
**Iteration Ref**: `specs/011-specrew-start-conditional-pause/iterations/002/plan.md`
**Updated**: 2026-05-11

## Purpose

This drift log tracks deviations from the iteration 002 plan during execution. Any change to scope, requirements, task definitions, or effort estimates during implementation or review must be recorded here with rationale.

## Drift Events

*(No drift events recorded yet; iteration 002 is in planning phase)*

---

## Monitoring Areas

Areas of elevated risk where drift is more likely to occur during Iteration 002 execution:

1. **Pause-and-confirm correctness**: The pause-and-confirm directive must inject only when detector reports changed session-loaded files, not on every resume. False positives would over-pause and add friction; false negatives would miss the case where the user needs to inject directives. Monitor detector accuracy and pause-and-confirm conditional logic during implementation.

2. **Directive injection fidelity**: The `-PostRestartDirective` parameter must prepend custom text verbatim as the first instruction before any pause-and-confirm or auto-continue logic. Prepending order is critical for user directive priority. Monitor parameter handling and prepending sequence during implementation.

3. **Handoff visibility coverage**: Detector result, changed-files list, and custom directives must be visible in regenerated `.specrew/last-start-prompt.md` and testable via scaffold-replay-path assertions per test-integrity corpus row 16. Visibility output that exists only in runtime state but not in user-facing handoff prompt is insufficient. Monitor scaffold-replay-path test coverage during test fixture writing and implementation.

4. **Corpus seeding completeness**: Known-traps corpus entry for auto-handoff-bypass pattern must be seeded in `.specrew/quality/known-traps.md` per FR-008 closure criterion. Missing corpus row breaks closure. Monitor T055 completion and corpus entry format during polish phase.

5. **Auto-continue preservation**: Auto-continue behavior for routine resumes (no changes) must remain intact from Iteration 001. Regression would break spec 001 Session 2026-05-04 baseline. Monitor Iteration 001 tests (`specrew-start-auto-continue-preservation.ps1`) during Iteration 002 implementation to catch any accidental regression.

6. **Signature stability**: `-PostRestartDirective` parameter must be optional with default empty string; breaking changes to `specrew-start.ps1` signature violate FR-006. Monitor parameter declaration and default handling during implementation.

7. **Test-integrity scaffold-replay-path discipline**: All visibility output (pause-and-confirm messages, file lists, custom directives) must be tested through scaffold-replay-path, not just runtime state inspection. Tests that only assert state-file content without invoking the user-facing scaffold path do not satisfy handoff coverage per test-integrity corpus row 16 from specs/005. Monitor T045 fixture and test writing to ensure scaffold-replay-path assertions are included.

8. **Documentation deferral decision**: T057 comprehensive documentation updates are planned but can be deferred to later polish or closeout if capacity requires. If deferred, the deferral decision must be explicit and recorded in this drift log with rationale (e.g., "T057 deferred to feature closeout to prioritize test coverage and corpus seeding within 20-point capacity").

---

## Spec Authority Violations

*(No violations recorded; iteration 002 is in planning phase)*

---

## Resolution Notes

*(No resolutions recorded; iteration 002 is in planning phase)*

---

## Notes

- This drift log is created during planning and will be updated during implementation, review, and retrospective.
- All drift events must be recorded with date, description, rationale, and resolution status.
- Monitoring areas identify elevated-risk concerns where drift is more likely; these are not violations unless actual drift occurs.
- Spec authority violations are a specific subset of drift events where the implementation deviates from requirements defined in `spec.md` without explicit approval.

