# Tasks: PR Lint Scoping

**Input**: Design documents from `/specs/026-ci-lint-pr-scoping/`  
**Prerequisites**: plan.md (required), spec.md (required)

**Organization**: Single chore phase with sequential milestones.

## Format: `- [ ] T### [P?] [assigned_to: ...] [effort: ...] Description with exact file path(s) (Trace: ...)`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[assigned_to]**: Responsible owner role
- **[effort]**: Relative effort estimate (`S`, `M`, `L`)

---

## Phase 1: PR Validation Scoping (Chore Bundle)

**Goal**: Implement `-ChangedOnly` mode in `validate-governance.ps1` and route PR jobs to scoped path.

**Verification**: Integration test passes; PR job scopes to changed iterations; push-to-main job retains full-repo validation.

### Implementation

- [ ] T001 [P] [assigned_to: Implementer] [effort: S] Add `-ChangedOnly` parameter to `extensions/specrew-speckit/scripts/validate-governance.ps1`; default behavior (full-repo validation) unchanged when parameter absent (Trace: spec AC#1, Scope Boundaries)

- [ ] T002 [P] [assigned_to: Implementer] [effort: M] Create `Get-ChangedIterations` helper function in `extensions/specrew-speckit/scripts/validate-governance.ps1` to enumerate changed files from git diff (base..head), identify touched iteration paths under `specs/*/iterations/<N>/`, include global-state surfaces (`.specrew/`, `.squad/identity/`, `.specify/feature.json`), and return filtered iteration list for scoped validation (Trace: spec Design, Scope Boundaries)

- [ ] T003 [assigned_to: Implementer] [effort: S] Update `.github/workflows/specrew-ci.yml` to add conditional: if `on: pull_request` event, compute changed files via git diff (base..head), identify changed iterations and global state, and pass scoped paths to `validate-governance.ps1`; if `on: push` to main, invoke validation without scoping (full-repo path unchanged) (Trace: spec AC#3, AC#5)

- [ ] T004 [P] [assigned_to: Implementer] [effort: M] Create integration test in `tests/integration/validate-governance-changed-only.tests.ps1` to verify: (a) scoped validation receives correct changed-iteration list, (b) violations in unmodified iterations are not reported (regression guard), (c) global-state surfaces included in scope detection, (d) full-repo validation on push-to-main includes all iterations, (e) fallback to full validation if diff base cannot be resolved (Trace: spec AC#3, AC#4, AC#5)

- [ ] T005 [P] [assigned_to: Implementer] [effort: S] Add changelog entry in `CHANGELOG.md` documenting PR validation scoping as a governance optimization, referencing spec.md and noting CI latency improvement and changed-iteration-only behavior (Trace: Deliverables)

### Validation & Polish

- [ ] T006 [assigned_to: Implementer] [effort: S] Run integration test suite to confirm all scoping paths pass and no regressions in existing validation workflow (Trace: Validation Notes, Acceptance Criteria)

- [ ] T007 [assigned_to: Implementer] [effort: S] Verify workflow YAML syntax and dry-run scoped validation against a PR surface to confirm iteration filtering logic and conditional dispatch (Trace: Validation Notes)

**Checkpoint**: All deliverables complete, integration test passing, changelog recorded. Ready for PR submission.

---

## Dependencies & Execution Order

### Parallelizable (no blocking deps)
- T001, T002: Validator modifications (different files, no inter-dependency)
- T004, T005: Integration test and changelog (independent content)

### Sequential
- T003: Depends on T001, T002 (workflow conditional routes to updated scripts)
- T006, T007: Validation milestone after all implementation tasks complete

### Execution Path
1. Start T001 + T002 + T004 + T005 in parallel
2. Await T001 + T002 completion
3. Execute T003 (workflow update)
4. Execute T006 + T007 (validation)
5. Checkpoint: Ready for PR

---

## Notes

- Single chore slice, no user stories
- No external dependencies introduced; existing Git CLI and validation infrastructure sufficient
- Validation gate: integration test must pass before PR submission
- Changelog entry documents feature for user visibility
- Push-to-main full-repo validation unchanged (truth-check path preserved)
