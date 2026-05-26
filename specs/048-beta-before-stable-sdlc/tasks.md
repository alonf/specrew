# Tasks: F-048 Beta-Before-Stable SDLC Discipline

**Input**: Design documents from `specs/048-beta-before-stable-sdlc/`  
**Prerequisites**: `plan.md`, `spec.md`, `data-model.md`,
`contracts/beta-before-stable-sdlc.md`, `quickstart.md`  
**Scope Guardrail**: Two iterations. Iteration 001 ships the coordinator
handoff/docs/test policy surface. Iteration 002 ships release-audit CLI/helper,
schema, config flag, and audit validation. Stable publication remains blocked
without explicit human PASS evidence.

## Iteration 001: SDLC Prompt + Documentation

### Phase 1: Handoff Ownership Template

- [x] T001 [P] [assigned_to: Reviewer] [effort: S] Add failing handoff-format fixtures that assert feature-closeout output contains both `AGENT NEXT ACTION:` and `HUMAN ACTION NEEDED:` rows, lists Steps 5-14 in order, and describes the Step 12 beta fail-loop. (Trace: FR-001, FR-002, FR-003, FR-004, FR-013, SC-001, SC-002)
- [x] T002 [assigned_to: Spec Steward] [effort: M] Update coordinator-prompt and governance template surfaces so feature-closeout handoff assigns Steps 5-14 to the agent and approvals/PASS-FAIL to the human. Include `scripts/specrew-start.ps1`, `extensions/specrew-speckit/prompts/*`, coordinator squad template guidance, host rules only if they contain feature-closeout wording, and `.specify/` mirrors where applicable. (Trace: FR-001, FR-002, FR-003, FR-004, FR-014, SC-001, SC-002, SC-007)

### Phase 2: Release Discipline Documentation

- [x] T003 [P] [assigned_to: Reviewer] [effort: S] Add documentation coverage assertions for `docs/release-discipline.md`: Steps 5-14, explicit PASS gate, proposal-only exemption, locked-main trailing audit PR, direct-main opt-in, and stop-before-new-feature behavior. (Trace: FR-005, FR-006, FR-013, SC-003)
- [x] T004 [assigned_to: Spec Steward] [effort: M] Create `docs/release-discipline.md` codifying `[[feedback-beta-publish-before-stable-2026-05-26]]`, including PSGallery beta validation commands, PASS/FAIL evidence, beta.N loop, stable promotion, audit capture, and proposal-only exemptions. (Trace: FR-005, FR-006, SC-003)

### Phase 3: Proposal Metadata + Iteration 001 Verification

- [x] T005 [assigned_to: Spec Steward] [effort: S] Update `proposals/060-prerelease-channel-staging.md`, `proposals/131-coordinator-prompt-sdlc-ownership-clarification.md`, and `proposals/INDEX.md` to reflect the F-048 shipped/in-progress scope without claiming Iteration 002 audit automation until it lands. (Trace: FR-015)
- [ ] T006 [assigned_to: Reviewer] [effort: S] Verify mirror parity for every modified `extensions/specrew-speckit/` file with a `.specify/extensions/specrew-speckit/` counterpart. (Trace: FR-014, SC-007)
- [ ] T007 [assigned_to: Reviewer] [effort: S] Run Iteration 001 focused tests plus scoped governance validation; record evidence in iteration quality artifacts. (Trace: FR-013, FR-014, FR-016, SC-001, SC-002, SC-003, SC-007, SC-008)

## Iteration 002: Post-Merge Release Audit Trail

### Phase 4: Audit Tests First

- [ ] T008 [P] [assigned_to: Reviewer] [effort: M] Add release-audit test fixtures for successful capture, missing merge/package/verdict evidence, explicit FAIL verdict, default trailing one-file PR mode, and `release_audit_direct_to_main: true` direct-main mode. (Trace: FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-016, SC-004, SC-005, SC-006, SC-008)

### Phase 5: Audit Helper + CLI

- [ ] T009 [assigned_to: Implementer] [effort: M] Implement `scripts/internal/release-audit.ps1` to generate and validate `docs/releases/<feature-ref>.md` with `specrew.release-audit.v1` front matter plus narrative body. (Trace: FR-007, FR-008, FR-012, FR-016, SC-004, SC-006)
- [ ] T010 [assigned_to: Implementer] [effort: M] Implement `scripts/specrew-release-audit.ps1` and route `specrew release-audit capture|validate` through `scripts/specrew.ps1`, including argument whitelist/help text and dry-run/test-friendly behavior. (Trace: FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-016, SC-004, SC-005, SC-006)
- [ ] T011 [assigned_to: Implementer] [effort: S] Add explicit `release_audit_direct_to_main: true` support in `.specrew/config.yml` parsing while preserving default trailing one-file PR behavior when the flag is missing or false. (Trace: FR-009, FR-010, FR-011, SC-005)
- [ ] T012 [assigned_to: Implementer] [effort: S] Update packaging/file-list surfaces if the new release-audit scripts must ship in the Specrew module. (Trace: FR-013, FR-016, SC-008)

### Phase 6: Audit Docs/Contracts + Verification

- [ ] T013 [assigned_to: Spec Steward] [effort: S] Reconcile `contracts/beta-before-stable-sdlc.md`, `quickstart.md`, and release discipline docs with the final CLI/schema details if implementation changes any planned names or flags. (Trace: FR-005, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, SC-003, SC-004, SC-005, SC-006)
- [ ] T014 [assigned_to: Reviewer] [effort: S] Run release-audit tests, focused handoff/docs tests, syntax checks, mirror parity, and scoped governance validation. (Trace: FR-013, FR-014, FR-016, SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007, SC-008)
- [ ] T015 [assigned_to: Reviewer] [effort: S] Complete review evidence for release safety: implemented, enforced, observable, and documented dimensions for template ownership, PASS-gated stable publish, audit artifact completeness, and direct-main opt-in. (Trace: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-016, SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-008)

## Release & Closeout

- [ ] T016 [assigned_to: Implementer] [effort: S] Perform F-048 release bookkeeping at feature closeout: target `0.27.6` from the current `0.27.5` stable baseline, update manifests/changelog/docs as required, and use the newly codified beta-before-stable SDLC for publication. (Trace: FR-005, FR-006, FR-007, FR-008, FR-013, FR-016, SC-003, SC-004, SC-006, SC-008)
