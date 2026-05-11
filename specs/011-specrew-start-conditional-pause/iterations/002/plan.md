# Iteration Plan: 002

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: executing  
**Capacity**: 20/20 story_points
**Planned Start**: 2026-05-11  
**Started**: 2026-05-11  
**Completed**: —
**Closed**: —  
**Hardening-Gate Sign-Off**: ✅ **SIGNED-OFF** by Alon Fliess on 2026-05-11  
**Implementation Authorization**: ✅ **AUTHORIZED** for implementation on 2026-05-11 following hardening-gate sign-off  
**Review Completed**: —  
**Review Verdict**: —

## Summary

Iteration 002 is the user-facing slice for feature `011-specrew-start-conditional-pause`. It carries **Phase 4 (User Story 2: pause-and-confirm) + Phase 5 (User Story 3: optional parameter) + the Iteration 002 share of Phase 6 (corpus seeding, visibility testing, changed-files-detected path coverage)** — the pause-and-confirm directive injection, optional `-PostRestartDirective` parameter, detector visibility in handoff prompt, known-traps corpus seeding for the auto-handoff bypass pattern, and comprehensive scaffold-replay-path assertions for user-visible output.

This is a 20-point slice building directly on Iteration 001 detector and baseline tracking infrastructure. Iteration 001 established the change detection mechanism, baseline commit tracking in YAML frontmatter, and auto-continue preservation for routine resumes. Iteration 002 completes the user-facing behavior: pause-and-confirm messaging when session-loaded files changed, the optional `-PostRestartDirective` parameter for power users, detector visibility output, and corpus seeding per FR-008 closure criterion. T057 comprehensive documentation updates are deferred to feature closeout.

**Primary Focus**: Pause-and-confirm directive injection when detector reports changes, optional `-PostRestartDirective` parameter support with prepending logic, detector visibility in `.specrew/last-start-prompt.md`, known-traps corpus seeding for the auto-handoff-bypass pattern, and scaffold-replay-path coverage for all visibility output  
**Target Slice**: Phase 4 + Phase 5 + Iteration 002 share of Phase 6 (`T043`-`T056`)  
**Execution Status**: Hardening-gate signed off by Alon Fliess on 2026-05-11; implementation authorized on 2026-05-11  
**Capacity Note**: 20 story_points; T057 documentation deferred to closeout  
**Deferred Follow-On**: Comprehensive documentation updates (T057) deferred to feature closeout

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-003 | Pause-and-Confirm Directive Injection | ✅ `T043`-`T049` | Script maintainer, Test infrastructure maintainer | Inject PAUSE-AND-CONFIRM directive when detector reports changes, with clear message, file list, and confirmation prompt |
| FR-005 | PostRestartDirective Parameter | ✅ `T050`-`T054` | Script maintainer, Test infrastructure maintainer | Implement optional `-PostRestartDirective` parameter for prepending custom directives |
| FR-008 | Known-Traps Corpus Seeding | ✅ `T055` | Quality governance maintainer | Seed known-traps corpus entry for auto-handoff-bypass pattern discovered on 2026-05-11 |
| FR-009 | Detector Visibility in Handoff | ✅ `T048` (US2), `T044`-`T045` (tests) | Script maintainer, Test infrastructure maintainer | Detector result must be visible in regenerated handoff prompt and testable via scaffold-replay-path |
| FR-010 | Deterministic Test Coverage | ✅ `T043`-`T046` (US2), `T050`-`T052` (US3), `T056` (validation lane) | Test infrastructure maintainer, Review-operations maintainer | Scaffold-replay-path assertions for all visibility output per test-integrity corpus row 16 |
| TG-002 | User Story 2 Coverage | ✅ `T043`-`T049` | Script maintainer, Test infrastructure maintainer | Pause-and-confirm coverage for changed session-loaded files |
| TG-003 | User Story 3 Coverage | ✅ `T050`-`T054` | Script maintainer, Test infrastructure maintainer | Optional parameter support for custom post-restart directives |
| TG-004 | Known-Traps Integration | ✅ `T055` | Quality governance maintainer | Explicit corpus seeding as closure criterion |
| TG-006 | Scaffold-Replay-Path Coverage | ✅ `T045`, `T049`, `T054` | Test infrastructure maintainer, Review-operations maintainer | All visibility output tested through scaffold-replay-path, not just runtime state |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope limited to Phase 4 + Phase 5 + Iteration 002 share of Phase 6 (pause-and-confirm, parameter, corpus seeding, visibility) from approved spec.md; comprehensive documentation deferred if capacity requires |
| **Traceability** | ✅ PASS | Every task maps to user-facing FRs (FR-003, FR-005, FR-008, FR-009) plus FR-010 for test coverage and TG-002/TG-003/TG-004/TG-006 for user story and governance requirements |
| **Ownership** | ✅ PASS | Task owners align to Specrew roles in spec.md Requirement Ownership & Delivery |
| **Capacity** | ✅ PASS | 20/20 story_points with T055 corpus seeding retained in scope and T057 documentation deferred to closeout |
| **Execution Support** | ✅ PASS | Planning artifacts, hardening-gate artifact ready for sign-off, detector infrastructure from Iteration 001 available for user-facing behavior implementation |

---

## Phase 1 Quality Planning

**Phase Scope**: `phase-4-us2-pause-and-confirm` + `phase-5-us3-parameter-support` + `phase-6-corpus-visibility` — pause-and-confirm directive injection, optional parameter support, corpus seeding, visibility testing  
**Inferred Quality Profile**: `quality-profile.cli-script-integration-focused.v1` (inherited from Iteration 001)  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell CLI modification with git integration, YAML frontmatter handling, user-facing message injection, deterministic test coverage for pause-and-confirm and parameter paths, and scaffold-replay-path assertions for visibility output.

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Pause-and-confirm correctness | `required` | Pause-and-confirm directive must inject when session-loaded files changed, list files clearly, and allow user input before Squad continues; incorrect injection breaks user workflow |
| Directive injection fidelity | `required` | Custom `-PostRestartDirective` parameter must prepend verbatim text as first instruction before pause-and-confirm or auto-continue logic; prepending order breaks user directive priority |
| Handoff visibility coverage | `required` | Detector result, changed-files list, and custom directives must be visible in regenerated `.specrew/last-start-prompt.md` and testable via scaffold-replay-path; missed visibility output breaks user feedback loop |
| Corpus seeding completeness | `required` | Known-traps corpus entry for auto-handoff-bypass pattern must be seeded in `.specrew/quality/known-traps.md` per FR-008; missing corpus row breaks closure criterion |
| Auto-continue preservation | `required` | Auto-continue behavior for routine resumes (no changes) must remain intact from Iteration 001; regression breaks spec 001 Session 2026-05-04 baseline |
| Signature stability | `required` | `-PostRestartDirective` parameter must be optional with default empty string; signature breaking changes violate FR-006 |
| Performance | `required` | Pause-and-confirm message generation and parameter prepending must complete in <100ms baseline assumption to avoid noticeable delay in handoff rendering |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T043 | Write test fixtures for session-loaded file change scenarios (committed change to `.github/agents/squad.agent.md`, committed changes to `.squad/agents/*/charter.md`, mixed changes) in `tests/integration/fixtures/specrew-start-detector/with-changes/` | FR-003 | US2 | 1 | Test infrastructure maintainer | `tests/integration/fixtures/specrew-start-detector/with-changes/` | planned | — | — | — |
| T044 | Write deterministic tests in `tests/integration/specrew-start-pause-and-confirm.ps1` asserting that pause-and-confirm directive is injected when detector reports changed session-loaded files and message format includes file list | FR-003, FR-009 | US2 | 1 | Test infrastructure maintainer | `tests/integration/specrew-start-pause-and-confirm.ps1` | planned | — | — | — |
| T045 | Write scaffold-replay-path visibility tests in `tests/integration/specrew-start-pause-and-confirm.ps1` invoking `scaffold-reviewer-artifacts.ps1` and `specrew-review.ps1` to assert pause messages render correctly in handoff output (per test-integrity corpus from specs/005) | FR-009, FR-010 | US2 | 2 | Test infrastructure maintainer | `tests/integration/specrew-start-pause-and-confirm.ps1` | planned | — | — | — |
| T046 | Write tests in `tests/integration/specrew-start-change-detector.ps1` confirming detector correctly identifies changed session-loaded paths via `git diff --name-only` (extend Iteration 001 detector tests to cover changed-files case) | FR-001 | US2 | 1 | Test infrastructure maintainer | `tests/integration/specrew-start-change-detector.ps1` | planned | — | — | — |
| T047 | Implement pause-and-confirm directive injection in `scripts/specrew-start.ps1` when detector reports changed files: clear message stating "Session-loaded files changed:", file list from `git diff --name-only` output, user confirmation/directive prompt | FR-003 | US2 | 3 | Script maintainer | `scripts/specrew-start.ps1` | planned | — | — | — |
| T048 | Implement detector visibility output in `.specrew/last-start-prompt.md` YAML frontmatter and/or markdown section showing structured field with list of changed files (e.g., `## Session-Loaded Files Changed: .github/agents/squad.agent.md`) for user readback | FR-009 | US2 | 2 | Script maintainer | `scripts/specrew-start.ps1` | planned | — | — | — |
| T049 | Run test suite for T043-T046 against T047-T048 implementation and verify pause-and-confirm messages render correctly in scaffold-replay-path output | FR-003, FR-009, FR-010 | US2 | 1 | Review-operations maintainer | `tests/integration/specrew-start-*.ps1` | planned | — | — | — |
| T050 | Write test fixtures for parameter scenarios (with parameter + no changes, with parameter + with changes, without parameter, empty parameter string) in `tests/integration/fixtures/specrew-start-detector/parameter-variants/` | FR-005 | US3 | 1 | Test infrastructure maintainer | `tests/integration/fixtures/specrew-start-detector/parameter-variants/` | planned | — | — | — |
| T051 | Write deterministic tests in `tests/integration/specrew-start-parameter-handling.ps1` asserting `-PostRestartDirective` parameter is accepted, custom directive prepended verbatim, parameter is optional, empty/null handled gracefully | FR-005 | US3 | 1 | Test infrastructure maintainer | `tests/integration/specrew-start-parameter-handling.ps1` | planned | — | — | — |
| T052 | Write end-to-end tests in `tests/integration/specrew-start-end-to-end.ps1` asserting parameter prepending works correctly in combined scenarios (baseline → no changes → custom directive → auto-continue; baseline → changes → custom directive → pause-and-confirm → resume) per SC-006 acceptance scenario | FR-005 | US3 | 2 | Test infrastructure maintainer | `tests/integration/specrew-start-end-to-end.ps1` | planned | — | — | — |
| T053 | Implement `-PostRestartDirective` parameter support in `scripts/specrew-start.ps1` parameter list (optional string, default empty), prepend parameter value to regenerated `.specrew/last-start-prompt.md` before pause-and-confirm or auto-continue logic, ensure prepended text appears verbatim | FR-005 | US3 | 2 | Script maintainer | `scripts/specrew-start.ps1` | planned | — | — | — |
| T054 | Run test suite for T050-T052 against T053 implementation and verify parameter is accepted, custom directives render correctly in handoff, parameter optional behavior correct | FR-005 | US3 | 1 | Review-operations maintainer | `tests/integration/specrew-start-*.ps1` | planned | — | — | — |
| T055 | Seed known-traps corpus entry in `.specrew/quality/known-traps.md` documenting the "auto-handoff bypass when session-loaded files change" pattern (discovery date 2026-05-11, category: governance, broken pattern, detection method, remediation guidance) per FR-008 requirements | FR-008 | Polish | 1 | Quality governance maintainer | `.specrew/quality/known-traps.md` | planned | — | — | — |
| T056 | Run comprehensive integration test lane: `tests\integration\specrew-start-change-detector.ps1`, `tests\integration\specrew-start-baseline-tracking.ps1`, `tests\integration\specrew-start-auto-continue-preservation.ps1`, `tests\integration\specrew-start-pause-and-confirm.ps1`, `tests\integration\specrew-start-parameter-handling.ps1`, and `tests\integration\specrew-start-end-to-end.ps1` on committed state | FR-010 | Polish | 1 | Review-operations maintainer | `tests/integration/specrew-start-*.ps1` | planned | — | — | — |

**Total Effort**: 20 story_points (T057 documentation deferred to closeout; included tasks T043-T056)

---

## Planned Execution Order

1. **User Story 2 (Pause-and-Confirm)**: `T043`, `T044`, `T045`, `T046` in parallel—test fixtures and assertions for pause-and-confirm scenarios and scaffold-replay-path visibility
2. **User Story 2 (Implementation)**: `T047`, `T048` can be coded in parallel or sequentially depending on implementation coupling
3. **User Story 2 (Validation)**: `T049` validates all US2 tests pass against pause-and-confirm implementation
4. **User Story 3 (Parameter Support)**: `T050`, `T051`, `T052` in parallel—test fixtures and assertions for parameter scenarios
5. **User Story 3 (Implementation)**: `T053` implements parameter prepending logic
6. **User Story 3 (Validation)**: `T054` validates all US3 tests pass against parameter implementation
7. **Polish Phase**: `T055` (corpus seeding) and `T056` (validation lane) run after all implementations complete; `T057` (documentation) deferred to closeout
8. Stop at `T056`; feature 011 continues with closeout after iteration 002 completes

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| `T057` | Closeout | Comprehensive documentation updates deferred to feature closeout; visibility output in handoff prompt and scaffold-replay-path coverage are sufficient for user comprehension in early rollout |

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20.0 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | The Planner must make any future deferral decision explicit. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |

## Concurrency Rationale

- Current roster snapshot: Script maintainer, Test infrastructure maintainer, Review-operations maintainer, Quality governance maintainer, Documentation maintainer
- Technology and scope signals: PowerShell CLI modification with user-facing message injection, deterministic test coverage, scaffold-replay-path assertions
- Task dependency graph: `T043`-`T046` are independent test fixtures/assertions; `T047`-`T048` implement pause-and-confirm and visibility; `T049` validates US2; `T050`-`T052` are independent parameter test fixtures/assertions; `T053` implements parameter prepending; `T054` validates US3; `T055`-`T057` are independent polish tasks
- Workstream separability: High. Test fixtures can be written before implementation. US2 and US3 can be implemented in parallel after detector infrastructure is available from Iteration 001. Polish tasks are independent.
- Shared-surface conflict risk: Low. All changes scoped to single entry point (`scripts/specrew-start.ps1`) and test files; YAML frontmatter manipulation is serialized. Corpus seeding and documentation updates are independent.
- Recommendation: Run test fixture writing in parallel (T043-T046, T050-T052), then implementation (T047-T048, T053) with parallel validation (T049, T054), then polish (T055-T057) in parallel or sequentially.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Iteration slicing, this plan document, traceability packaging, hardening-gate artifact creation |
| Discovery/Spikes | 0 | Feature design already complete; no separate spike authorized |
| Implementation | 8 | Pause-and-confirm logic (T047-T048), parameter support (T053), corpus seeding (T055) |
| Testing | 5 | Test fixture setup (T043-T046, T050-T052), validation runs (T049, T054, T056) |
| Review | 1 | Review validation results, pause-and-confirm messages, and parameter prepending logic; hardening-gate sign-off before implementation |
| Rework | 0 | Small buffer reserved if tests fail or edge cases emerge |

## Implementation Approval

- **Planning Approval**: ✅ **AUTHORIZED** — Planning approval granted by Alon Fliess on 2026-05-11 for Iteration 002
- **Hardening-Gate Sign-Off**: ✅ **SIGNED-OFF** by Alon Fliess on 2026-05-11
- **Implementation Authorization**: ✅ **AUTHORIZED** — Implementation authorization granted by Alon Fliess on 2026-05-11 following hardening-gate sign-off
- **Authorized Scope**: Feature 011 iteration 002 (Phase 4 + Phase 5 + Iteration 002 share of Phase 6 — pause-and-confirm directive injection, optional `-PostRestartDirective` parameter, detector visibility in handoff, known-traps corpus seeding, scaffold-replay-path coverage for visibility output, tasks T043 through T056, 20 story points)
- **Authorized Activities**: Implementation, review, retrospective, and closeout
- **Boundary Note**: Planning approval is explicitly distinct from implementation authorization. Planning authorization on 2026-05-11 authorizes the bounded scope (Phase 4 + Phase 5 + Iteration 002 share of Phase 6 pause-and-confirm and parameter features) for hardening-gate preparation and planning-time quality gate sign-off. Implementation authorization granted on 2026-05-11 following hardening-gate sign-off by Alon Fliess, authorizing execution start. T057 comprehensive documentation updates are deferred to feature closeout to keep the iteration bounded at 20 story_points while retaining T055 corpus seeding in iteration 002 scope.

## Notes

- This plan carries Phase 4 + Phase 5 + Iteration 002 share of Phase 6 work—pause-and-confirm directive injection, optional parameter support, corpus seeding per FR-008 closure criterion, and visibility testing—building directly on Iteration 001 detector and baseline tracking infrastructure.
- `T043`-`T046` write test fixtures and assertions for pause-and-confirm scenarios, including scaffold-replay-path visibility testing per test-integrity corpus row 16.
- `T047`-`T048` implement pause-and-confirm directive injection and detector visibility output in `.specrew/last-start-prompt.md`.
- `T049` runs the US2 test suite to confirm pause-and-confirm messages render correctly in scaffold-replay-path output.
- `T050`-`T052` write test fixtures and assertions for `-PostRestartDirective` parameter scenarios.
- `T053` implements parameter prepending logic in `specrew-start.ps1` with optional string parameter (default empty).
- `T054` runs the US3 test suite to confirm parameter is accepted and custom directives render correctly.
- `T055` seeds the known-traps corpus entry for the auto-handoff-bypass pattern per FR-008 closure criterion (1 story point; included in iteration 002 scope).
- `T056` runs the comprehensive integration test lane to confirm all detector, baseline, auto-continue, pause-and-confirm, and parameter paths pass.
- T057 comprehensive documentation updates are deferred to feature closeout.
- Iteration 002 completes feature 011 user-facing behavior including corpus seeding; feature closure requires all tasks green, validation lane passing, and documentation completed in closeout.
