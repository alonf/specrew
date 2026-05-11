# Iteration State: 002

**Schema**: v1
**Last Completed Task**: none (iteration 002 planning complete; awaiting hardening-gate sign-off and implementation authorization)
**Tasks Remaining**: 20 story_points (T043-T056 planned; T057 deferred to closeout)
**In Progress**: none
**Baseline Ref**: commit fb926fe (iteration 001 closeout) + iteration 002 planning boundary commit
**Updated**: 2026-05-11
**Current Phase**: planning
**Iteration Status**: Planning complete; hardening-gate artifact ready for sign-off; awaiting implementation authorization

## Execution Summary

**Status**: Iteration 002 planning is complete. Phase 4 + Phase 5 + Iteration 002 share of Phase 6 tasks (`T043`-`T056`) have been planned, traced to requirements, assigned to owners, and estimated. T057 comprehensive documentation (1 story_point) is deferred to feature closeout. The hardening-gate artifact is ready for sign-off. Implementation authorization will follow hardening-gate sign-off.

**Planned Surfaces**:
- Pause-and-confirm directive injection when detector reports changed session-loaded files (T047)
- Detector visibility output in `.specrew/last-start-prompt.md` showing changed-files list (T048)
- Optional `-PostRestartDirective` parameter for prepending custom directives (T053)
- Known-traps corpus seeding for auto-handoff-bypass pattern per FR-008 closure criterion (T055)
- Comprehensive integration test lane (T056)

**Deferred Surfaces**:
- Comprehensive documentation updates (T057) — feature closeout

**Planning Notes**:
- Iteration 002 builds directly on Iteration 001 detector and baseline tracking infrastructure
- Pause-and-confirm logic injects when detector reports changed session-loaded files
- Custom directive prepending happens before pause-and-confirm or auto-continue logic
- All visibility output tested through scaffold-replay-path, not just runtime state
- Known-traps corpus entry is a FR-008 closure criterion and included in iteration 002 scope (T055, 1 story_point)

## Iteration Scope

This iteration carries **Phase 4 (User Story 2: pause-and-confirm) + Phase 5 (User Story 3: optional parameter) + Iteration 002 share of Phase 6 (corpus seeding per FR-008 closure criterion, visibility testing, changed-files-detected path coverage)** — the pause-and-confirm directive injection, optional `-PostRestartDirective` parameter, detector visibility in handoff prompt, known-traps corpus seeding for the auto-handoff bypass pattern, and comprehensive scaffold-replay-path assertions for user-visible output.

**Planned Tasks**: `T043`-`T056` (20 story_points) — *(all tasks planned; none in progress)*  
**Deferred to Closeout**: `T057` documentation updates deferred to feature closeout

## Decisions and Handoff

- **Planning Approval**: ✅ **AUTHORIZED** — Planning approval granted by Alon Fliess on 2026-05-11 for Iteration 002
- **Hardening-Gate Sign-Off**: *(pending hardening-gate artifact sign-off)*
- **Implementation Authorization**: *(pending hardening-gate sign-off)* — Implementation authorization will follow hardening-gate sign-off
- **Next Action**: Await explicit human sign-off on hardening-gate artifact before opening implementation

## Task Status

| Task | Status | Notes |
| ---- | ------ | ----- |
| T043 | planned | Write test fixtures for session-loaded file change scenarios in `tests/integration/fixtures/specrew-start-detector/with-changes/` |
| T044 | planned | Write deterministic tests in `tests/integration/specrew-start-pause-and-confirm.ps1` asserting pause-and-confirm directive injection and message format |
| T045 | planned | Write scaffold-replay-path visibility tests in `tests/integration/specrew-start-pause-and-confirm.ps1` asserting pause messages render correctly in handoff output |
| T046 | planned | Write tests in `tests/integration/specrew-start-change-detector.ps1` confirming detector correctly identifies changed session-loaded paths (extend Iteration 001 detector tests) |
| T047 | planned | Implement pause-and-confirm directive injection in `scripts/specrew-start.ps1` with clear message, file list, and confirmation prompt |
| T048 | planned | Implement detector visibility output in `.specrew/last-start-prompt.md` showing structured field with changed-files list |
| T049 | planned | Run test suite for T043-T046 against T047-T048 implementation and verify pause-and-confirm messages render correctly in scaffold-replay-path output |
| T050 | planned | Write test fixtures for parameter scenarios in `tests/integration/fixtures/specrew-start-detector/parameter-variants/` |
| T051 | planned | Write deterministic tests in `tests/integration/specrew-start-parameter-handling.ps1` asserting `-PostRestartDirective` parameter acceptance and prepending behavior |
| T052 | planned | Write end-to-end tests in `tests/integration/specrew-start-end-to-end.ps1` asserting parameter prepending works correctly in combined scenarios |
| T053 | planned | Implement `-PostRestartDirective` parameter support in `scripts/specrew-start.ps1` with optional string parameter (default empty) and verbatim prepending |
| T054 | planned | Run test suite for T050-T052 against T053 implementation and verify parameter acceptance and custom directive rendering |
| T055 | planned | Seed known-traps corpus entry in `.specrew/quality/known-traps.md` documenting the "auto-handoff bypass when session-loaded files change" pattern per FR-008 closure criterion |
| T056 | planned | Run comprehensive integration test lane on committed state (all six detector/baseline/auto-continue/pause-and-confirm/parameter/end-to-end tests) |

**Total Tasks in Iteration**: 14 (T043-T056)  
**Total Effort**: 20 story_points

**Deferred Tasks**:
- T057 (documentation, 1 story_point) — feature closeout

## Pre-Implementation Checklist

Before implementation authorization:

- [ ] Hardening-gate artifact signed off by Alon Fliess
- [ ] All canonical concerns evaluated with honest pre-implementation analysis
- [ ] Feature-specific concerns documented with blocking status and evidence expectations
- [ ] Governance validator passes on planning-time artifact tree
- [ ] Iteration 001 closeout complete and green (detector and baseline infrastructure available)

## Notes

- Phase 4 + Phase 5 + Iteration 002 share of Phase 6 work planned: pause-and-confirm directive injection, optional parameter support, corpus seeding per FR-008 closure criterion, and visibility testing.
- All planning tasks are complete; hardening-gate artifact ready for sign-off.
- Iteration 002 awaits explicit human sign-off on hardening-gate before implementation authorization.
- T057 comprehensive documentation updates deferred to feature closeout.
- Quality profile: `quality-profile.cli-script-integration-focused.v1` per plan.md (inherited from Iteration 001).
- Hardening-gate artifact path: `specs/011-specrew-start-conditional-pause/iterations/002/quality/hardening-gate.md`.
- Drift-log path: `specs/011-specrew-start-conditional-pause/iterations/002/drift-log.md`.

