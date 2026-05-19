# Drift Log: Iteration 002

**Schema**: v1
**Feature Ref**: `specs/011-specrew-start-conditional-pause/spec.md`
**Iteration Ref**: `specs/011-specrew-start-conditional-pause/iterations/002/plan.md`
**Updated**: 2026-05-11

## Purpose

This drift log tracks deviations from the iteration 002 plan during execution. Any change to scope, requirements, task definitions, or effort estimates during implementation or review must be recorded here with rationale.

## Drift Events

### 2026-05-11: Baseline hash regex parsing bug (corrected during test execution)

**Type**: Implementation bug discovered during T049 test execution  
**Severity**: Medium (detector false negatives)  
**Status**: Resolved

**Description**: During T049 test execution, Test 4 in `specrew-start-pause-and-confirm.ps1` failed because the baseline hash regex in `Get-BaselineCommitHash` function (line 1867) lacked the multiline flag `(?m)`. The regex pattern `'^\s*baseline_commit_hash:\s*([0-9a-f]{40})\s*$'` could not match the baseline hash when YAML frontmatter included multi-line fields (e.g., `session_loaded_files_changed` list). Without the multiline flag, `^` and `$` anchors matched only string start/end, not line boundaries within the frontmatter block.

**Impact**: When frontmatter had multiple fields, baseline hash parsing failed, causing `Get-BaselineCommitHash` to return null. This defaulted baseline to HEAD, causing detector to always return empty (baseline == HEAD means no diff), resulting in false negatives (changes not detected, pause-and-confirm not triggered).

**Resolution**: Added multiline flag to regex: `'(?m)^\s*baseline_commit_hash:\s*([0-9a-f]{40})\s*$'` at line 1867 in `scripts/specrew-start.ps1`. All tests now pass (6/6 passing in comprehensive test lane).

**Rationale**: This was a latent bug in Iteration 001 infrastructure that only manifested in Iteration 002 when YAML frontmatter grew beyond single-line baseline hash. The bug violated FR-003 (detector correctness) but was caught and fixed during T049 test execution before commit. No spec authority violation because fix was required for conformance and was completed within iteration scope.

**Artifacts**: `scripts/specrew-start.ps1` line 1867 (regex correction)

---

## Monitoring Areas

Areas of elevated risk where drift is more likely to occur during Iteration 002 execution:

1. **Pause-and-confirm correctness**: The pause-and-confirm directive must inject only when detector reports changed session-loaded files, not on every resume. False positives would over-pause and add friction; false negatives would miss the case where the user needs to inject directives. Monitor detector accuracy and pause-and-confirm conditional logic during implementation.

2. **Directive injection fidelity**: The `-PostRestartDirective` parameter must prepend custom text verbatim as the first instruction before any pause-and-confirm or auto-continue logic. Prepending order is critical for user directive priority. Monitor parameter handling and prepending sequence during implementation.

3. **Handoff visibility coverage**: Detector result, changed-files list, and custom directives must be visible in regenerated `.specrew/last-start-prompt.md` and testable via scaffold-replay-path assertions per test-integrity corpus row 16. Visibility output that exists only in runtime state but not in user-facing handoff prompt is insufficient. Monitor scaffold-replay-path test coverage during test fixture writing and implementation.

4. **Corpus seeding completeness**: Known-traps corpus entry for auto-handoff-bypass pattern must be seeded in `.specrew/quality/known-traps.md` per FR-008 closure criterion (T055, 1 story_point included in iteration 002 scope). Missing corpus row breaks closure. Monitor T055 completion and corpus entry format during polish phase.

5. **Auto-continue preservation**: Auto-continue behavior for routine resumes (no changes) must remain intact from Iteration 001. Regression would break spec 001 Session 2026-05-04 baseline. Monitor Iteration 001 tests (`specrew-start-auto-continue-preservation.ps1`) during Iteration 002 implementation to catch any accidental regression.

6. **Signature stability**: `-PostRestartDirective` parameter must be optional with default empty string; breaking changes to `specrew-start.ps1` signature violate FR-006. Monitor parameter declaration and default handling during implementation.

7. **Test-integrity scaffold-replay-path discipline**: All visibility output (pause-and-confirm messages, file lists, custom directives) must be tested through scaffold-replay-path, not just runtime state inspection. Tests that only assert state-file content without invoking the user-facing scaffold path do not satisfy handoff coverage per test-integrity corpus row 16 from specs/005. Monitor T045 fixture and test writing to ensure scaffold-replay-path assertions are included.

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
