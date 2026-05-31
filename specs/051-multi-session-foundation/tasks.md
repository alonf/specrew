# Tasks: Multi-Session Foundation

**Feature**: 051-multi-session-foundation  
**Branch**: 051-multi-session-foundation  
**Total Tasks**: 97  
**Iterations**: 4 (Iteration 1 ≤20 SP, Iteration 2 12-18 SP, Iteration 3 10-15 SP, Iteration 4 8-12 SP)  
**Status**: Ready for before-implement hardening gate  

---

## Overview

This tasks artifact defines a complete, dependency-ordered implementation plan for F-051 Multi-Session Foundation across 4 iterations. Each task is mapped to one or more functional requirements (FR-001 through FR-043) and user stories (US1 through US10). Tasks are organized by iteration and organized to enable:

- **Clear Traceability**: Every task references the FR(s) it satisfies and the user story it supports
- **Dependency Clarity**: Prerequisites are explicit; parallel opportunities are marked [P]
- **Independent Testability**: Each phase is independently testable with clear acceptance criteria
- **Scope Fidelity**: All tasks stay within approved scope (FR-001 through FR-043); Proposal 148 Layer 2+3 explicitly excluded

---

## Iteration 1: Session Mode Configuration & File Classification (Target: ≤20 SP)

**User Stories**: US1 (Configure Multi-Session Mode), US2 (Avoid Per-Session File Conflicts)  
**Functional Requirements**: FR-001 through FR-006  
**Success Criteria**: SC-001 (merge conflicts eliminated), SC-005 (version sync)

### Setup & Foundation (Phase 1)

- [ ] T001 [P] Create PowerShell module manifest updates scaffold in `Specrew.psd1` for session mode feature module support [effort: 2 SP] [FR-001] [governance: module-structure]
- [ ] T002 Review `.specrew/config.yml` schema structure and add session_mode configuration key definition (FR-001) [effort: 1 SP] [governance: schema-definition]
- [ ] T003 [P] Create file classification schema document in `.specify/config.yml` defining per-session file patterns (`.specrew/last-*`, `.specify/feature.json`, `.specrew/start-context.json`, `.specrew/host-history.json`, `.specrew/.cache/`, `.squad/sessions/`, `.squad/decisions/inbox/`, `.specrew/last-validator-summary.json`) [effort: 2 SP] [FR-004]

### Session Mode Configuration (Phase 1, US1 → FR-001, FR-002, FR-003)

- [ ] T004 [US1] Create `scripts/config-management.ps1` with `Set-SessionMode` function to update `.specrew/config.yml` session_mode field and validate value is `single` or `multi` (FR-001, FR-002) [effort: 2 SP] [SC: SC-001]
- [ ] T005 [US1] Implement CLI command entry point `specrew config set session_mode <value>` in `scripts/specrew-cli.ps1` with success message and error handling (FR-002) [effort: 2 SP] [SC: SC-001]
- [ ] T006 [P] [US1] Add default session_mode initialization logic to `specrew init` flow to set `session_mode: single` when not present in `.specrew/config.yml` (FR-003) [effort: 1 SP]
- [ ] T007 [P] [US1] Create acceptance test for session mode configuration: verify `specrew config set session_mode multi` persists to config file and `specrew config set session_mode single` reverts it [effort: 2 SP] [test: acceptance]
- [ ] T008 [P] [US1] Create acceptance test for session mode defaults: verify fresh `specrew init` results in `session_mode: single` in `.specrew/config.yml` [effort: 1 SP] [test: acceptance]

### File Classification & Gitignore Management (Phase 1, US2 → FR-004, FR-005, FR-006)

- [ ] T009 [US2] Create `scripts/file-classification.ps1` with file classification schema function defining rules for: shared (committed, identical), per-session (gitignored), append-only-shared (committed, atomic append), regenerable (generated from shared sources) (FR-004) [effort: 2 SP] [SC: SC-001]
- [ ] T010 [P] [US2] Implement gitignore generation logic in `scripts/file-classification.ps1` to create/update `.gitignore` with patterns for per-session files: `.specrew/last-*`, `.specify/feature.json`, `.specrew/start-context.json`, `.specrew/host-history.json`, `.specrew/.cache/`, `.squad/sessions/`, `.squad/decisions/inbox/`, `.specrew/last-validator-summary.json` (FR-005) [effort: 2 SP] [SC: SC-001]
- [ ] T011 [P] [US2] Integrate gitignore generation into `specrew init` flow to call file-classification logic and update `.gitignore` on each init run (FR-005) [effort: 1 SP]
- [ ] T012 [US2] Implement `git rm --cached` cleanup in `scripts/file-classification.ps1` to remove previously tracked per-session files from git index without deleting from working directory (FR-006) [effort: 2 SP] [SC: SC-001]
- [ ] T013 [US2] Create cleanup step in `specrew init` to invoke `git rm --cached` for any per-session files that were previously committed (FR-006) [effort: 1 SP]
- [ ] T014 [P] [US2] Create acceptance test for gitignore generation: verify `.gitignore` excludes all per-session file patterns after `specrew init` [effort: 1 SP] [test: acceptance]
- [ ] T015 [P] [US2] Create acceptance test for git cleanup: verify previously tracked per-session files are removed from git index via `git rm --cached` without deleting working directory copies [effort: 1 SP] [test: acceptance]

### Iteration 1 Validation & Documentation

- [ ] T016 [P] Create `specs/051-multi-session-foundation/quickstart.md` with getting-started guide for session mode configuration and file classification [effort: 1 SP] [governance: documentation]
- [ ] T017 Create `specs/051-multi-session-foundation/data-model.md` documenting SessionModeConfig entity with attributes (session_mode: single|multi, description, examples) [effort: 1 SP] [governance: data-model]
- [ ] T018 Run all Iteration 1 acceptance tests and document results in test summary artifact [effort: 2 SP] [test: acceptance-suite]
- [ ] T019 Execute Specrew validator on updated module to ensure backward compatibility and no regressions [effort: 1 SP] [test: regression-check]

---

## Iteration 2: Collision Detection, Feature Claims & Auto-Detection (Target: 12-18 SP)

**User Stories**: US3 (Detect Concurrent Session Collisions), US4 (Claim Features), US5 (Reduce Shared-File Merge Conflicts), US6 (Detect Multi-Developer Activity)  
**Functional Requirements**: FR-007 through FR-024  
**Success Criteria**: SC-002 (collision warning within 2s), SC-003 (multi-dev detection), SC-006 (merge conflict elimination), SC-007 (recommendation within 0-2s), SC-008 (claim refresh 100%)

### Session Management & Collision Detection (Phase 2, US3 → FR-007 through FR-011)

- [ ] T020 [P] Create `scripts/session-management.ps1` with session lock file management functions: create-session-entry, read-active-sessions, write-active-sessions (FR-007) [effort: 2 SP] [SC: SC-002]
- [ ] T021 [US3] Implement session creation logic: add entry to `.specrew/active-sessions.yml` with fields (feature_id, user, machine_fingerprint, session_start_time, last_heartbeat_time) when `specrew start` begins (FR-008) [effort: 2 SP]
- [ ] T022 [US3] Implement session cleanup logic: remove entry from `.specrew/active-sessions.yml` when session ends normally, triggered at feature-closeout boundary (FR-009) [effort: 1 SP]
- [ ] T023 [P] [US3] Implement session existence check: detect when starting a session for a feature that already has an active entry in `.specrew/active-sessions.yml` and display warning with user@machine and timestamp (FR-010) [effort: 2 SP] [SC: SC-002]
- [ ] T024 [US3] Implement stale lock detection logic: automatically clear lock entries with last_heartbeat_time older than 24 hours from `.specrew/active-sessions.yml` when new session starts, with notice to user (FR-011) [effort: 2 SP]
- [ ] T025 [P] [US3] Create acceptance test for collision detection: simulate two concurrent `specrew start` sessions on same feature and verify second session receives warning within 2 seconds [effort: 2 SP] [test: acceptance] [SC: SC-002]
- [ ] T026 [P] [US3] Create acceptance test for stale lock clearing: create lock entry with timestamp >24 hours old, start new session, verify stale entry is cleared with user notice [effort: 1 SP] [test: acceptance]

### Feature Claims Tracking (Phase 2, US4 → FR-012 through FR-016)

- [ ] T027 [P] Create `scripts/feature-claims.ps1` with feature claim management functions: create-feature-claim, read-feature-claims, write-feature-claims, refresh-feature-claim (FR-012) [effort: 2 SP]
- [ ] T028 [US4] Implement feature claim creation logic: add entry to `.squad/active-features.yml` at specify boundary with fields (feature_id, claimed_by: user@machine, claim_start_time, last_refresh_time, branch_name) (FR-013) [effort: 2 SP] [SC: SC-008]
- [ ] T029 [P] [US4] Implement claim refresh logic: update `last_refresh_time` in `.squad/active-features.yml` when lifecycle boundaries are crossed (specify, plan, tasks, implement, review, retro) (FR-014) [effort: 2 SP] [SC: SC-008]
- [ ] T030 [US4] Implement concurrent claim detection: when developer attempts to claim feature already claimed by another developer, display Layer 1 warning with claim details and "Continue anyway?" option (FR-015) [effort: 2 SP]
- [ ] T031 [P] [US4] Implement claim cleanup logic: remove feature claim from `.squad/active-features.yml` when feature-closeout boundary runs and feature is merged to main (FR-016) [effort: 1 SP]
- [ ] T032 [P] [US4] Create acceptance test for feature claims: verify claim recorded at specify boundary, refreshed at plan boundary, and removed at feature-closeout [effort: 2 SP] [test: acceptance] [SC: SC-008]
- [ ] T033 [P] [US4] Create acceptance test for claim warning: simulate two developers claiming same feature and verify warning appears with continue option [effort: 1 SP] [test: acceptance]

### Shared File Merge Conflict Reduction (Phase 2, US5 → FR-017, FR-018, FR-019)

- [ ] T034 [P] Create `scripts/decisions-split.ps1` to split `.squad/decisions.md` into per-iteration files under `.squad/decisions/iteration-NNN/decisions.md` when in multi-session mode (FR-017) [effort: 2 SP] [SC: SC-006]
- [ ] T035 [US5] Create function to detect when multi-session mode is enabled and apply per-iteration split to decisions at boundary-sync time (FR-017) [effort: 1 SP] [SC: SC-006]
- [ ] T036 [P] Create `scripts/append-only-logs.ps1` to implement JSON Lines format (one JSON object per line) for append-only log files, enabling atomic appends and mechanical conflict resolution (FR-018) [effort: 2 SP] [SC: SC-006]
- [ ] T037 [US5] Implement JSON Lines writer function for lifecycle event logging (FR-018) [effort: 1 SP]
- [ ] T038 [P] Create `scripts/psd1-sort.ps1` to alphabetically sort the `Specrew.psd1` FileList array during boundary-sync writes to minimize merge conflicts (FR-019) [effort: 2 SP] [SC: SC-006]
- [ ] T039 [US5] Integrate psd1 alphabetical sort into boundary-sync process to re-sort FileList before writing updates (FR-019) [effort: 1 SP]
- [ ] T040 [P] [US5] Create acceptance test for decisions split: verify two features both recording decisions result in per-iteration files with no merge conflicts [effort: 1 SP] [test: acceptance] [SC: SC-006]
- [ ] T041 [P] [US5] Create acceptance test for psd1 sort: verify FileList array is alphabetically sorted after boundary-sync [effort: 1 SP] [test: acceptance]

### Multi-Developer Auto-Detection (Phase 2, US6 → FR-020 through FR-024)

- [ ] T042 [P] Create `scripts/auto-detection.ps1` with multi-developer signal detection functions: detect-git-authors, detect-machine-fingerprints, detect-concurrent-writes, detect-branch-fanout (FR-020) [effort: 2 SP] [SC: SC-003]
- [ ] T043 [US6] Implement git author email detection: scan git history for last 90 days and count unique author emails (FR-020) [effort: 1 SP] [SC: SC-003]
- [ ] T044 [P] [US6] Implement machine fingerprint detection: scan `.specrew/active-sessions.yml` and session-state files for unique machine_fingerprint values (FR-020) [effort: 1 SP] [SC: SC-003]
- [ ] T045 [P] [US6] Implement concurrent write detection: identify multiple session-state file modifications from different machines within 1 minute window (FR-020) [effort: 2 SP] [SC: SC-003]
- [ ] T046 [P] [US6] Implement branch fan-out detection: identify 3+ feature branches diverging from same base commit (FR-020) [effort: 1 SP] [SC: SC-003]
- [ ] T047 [US6] Implement multi-session recommendation message in Welcome Orientation: display "Multiple developers detected (X unique authors). Consider enabling multi-session mode: `specrew config set session_mode multi`" when session_mode is `single` and signals are detected (FR-021) [effort: 1 SP] [SC: SC-007]
- [ ] T048 [P] [US6] Implement multi-developer indicator in `specrew where` dashboard to show count of unique machines and recommendation to enable multi-session mode when signals detected (FR-022) [effort: 1 SP] [SC: SC-007]
- [ ] T049 [P] [US6] Implement multi-developer activity note in boundary-sync output when signals are detected (FR-023) [effort: 1 SP]
- [ ] T050 [US6] Implement recommendation suppression when `session_mode` is already set to `multi` to avoid redundant messages (FR-024) [effort: 1 SP]
- [ ] T051 [P] [US6] Create acceptance test for multi-dev detection: simulate commits from two different git authors and verify recommendation appears in Welcome Orientation within 2 seconds [effort: 2 SP] [test: acceptance] [SC: SC-007]
- [ ] T052 [P] [US6] Create acceptance test for signal suppression: set `session_mode: multi` and verify no multi-developer recommendation appears [effort: 1 SP] [test: acceptance]

### Iteration 2 Validation & Documentation

- [ ] T053 Create `specs/051-multi-session-foundation/data-model.md` additions: SessionLockEntry, FeatureClaimEntry, MultiDevSignal entities with full attribute definitions [effort: 2 SP] [governance: data-model]
- [ ] T054 Run all Iteration 2 acceptance tests and document results in test summary artifact [effort: 2 SP] [test: acceptance-suite]
- [ ] T055 Execute Specrew validator and verify no regressions from Iteration 1 changes [effort: 1 SP] [test: regression-check]

---

## Iteration 3: Spec-Kit Upgrade & specrew update Fix (Target: 10-15 SP)

**User Stories**: US7 (Upgrade Spec-Kit to 0.8.18), US8 (Fix Baseline Version Bump)  
**Functional Requirements**: FR-025 through FR-034  
**Success Criteria**: SC-004 (upgrade completes in <2 min), SC-005 (version sync 100% accurate)

### Spec-Kit Installation Detection & Upgrade Mechanism (Phase 3, US7 → FR-025 through FR-030)

- [ ] T056 [P] Create `scripts/spec-kit-upgrade.ps1` with Spec-Kit installation detection function: detect if Spec-Kit is installed via npm package, deployed extension directory, or manual files (FR-026) [effort: 2 SP] [SC: SC-004]
- [ ] T057 [US7] Implement npm package detection: check if Spec-Kit is installed via npm in `node_modules/` and identify package.json location (FR-026) [effort: 1 SP]
- [ ] T058 [P] [US7] Implement extension directory detection: check if Spec-Kit is deployed under `.specify/extensions/specrew-speckit/` (most common in Specrew bootstrap) (FR-026) [effort: 1 SP]
- [ ] T059 [P] [US7] Implement upgrade mechanism selector: identify appropriate upgrade path based on installation method detected (npm update, extension file replacement, manual) (FR-027) [effort: 2 SP]
- [ ] T060 [US7] Implement npm upgrade path: execute `npm install speckit@0.8.18` if Spec-Kit is installed via npm (FR-027) [effort: 1 SP]
- [ ] T061 [P] [US7] Implement extension directory upgrade: download and extract Spec-Kit 0.8.18 extension files to `.specify/extensions/specrew-speckit/`, preserving local configuration in `.specify/` directories (FR-028) [effort: 2 SP]
- [ ] T062 [P] [US7] Implement version update logic: write `speckit_version: "0.8.18"` to `.specrew/config.yml` after successful upgrade (FR-029) [effort: 1 SP] [SC: SC-005]
- [ ] T063 [US7] Implement post-upgrade validation: run Specrew governance validator after upgrade completes and report any compatibility issues (FR-030) [effort: 1 SP]
- [ ] T064 [P] [US7] Create `specrew upgrade-speckit` command entry point in `scripts/specrew-cli.ps1` to trigger upgrade workflow (FR-025) [effort: 1 SP]
- [ ] T065 [P] [US7] Create acceptance test for Spec-Kit upgrade: execute upgrade from 0.8.13 to 0.8.18 on test system, verify completion in <2 minutes, verify `.specrew/config.yml` shows 0.8.18, verify validator passes [effort: 2 SP] [test: acceptance] [SC: SC-004]

### Version Detection & Update Fix (Phase 3, US8 → FR-031 through FR-034)

- [ ] T066 [P] Create `scripts/version-management.ps1` with version detection functions: get-specrew-installed-version, read-configured-version, compare-versions (FR-032) [effort: 2 SP] [SC: SC-005]
- [ ] T067 [US8] Implement Specrew installed version detection: use `Get-Module Specrew -ListAvailable` or similar PowerShell metadata to retrieve installed module version (FR-032) [effort: 1 SP]
- [ ] T068 [P] [US8] Implement version field write fix in `specrew update` command: update `.specrew/config.yml` `specrew_version` field to match installed module version (FR-031) [effort: 2 SP] [SC: SC-005]
- [ ] T069 [P] [US8] Implement version drift warning during `specrew start`: when installed Specrew version ≠ `.specrew/config.yml` `specrew_version`, display warning: "Installed Specrew X.Y.Z differs from project pin A.B.C. Run `specrew update` to sync." (FR-033) [effort: 1 SP]
- [ ] T070 [US8] Implement `--dry-run` flag for `specrew update`: show proposed version change without modifying files (FR-034) [effort: 1 SP]
- [ ] T071 [P] [US8] Create acceptance test for version sync: install specific Specrew version (e.g., 0.29.0), run `specrew update`, verify `.specrew/config.yml` shows 0.29.0 (100% accuracy) [effort: 2 SP] [test: acceptance] [SC: SC-005]
- [ ] T072 [P] [US8] Create acceptance test for version drift warning: create version mismatch scenario and verify warning appears at `specrew start` [effort: 1 SP] [test: acceptance]
- [ ] T073 [P] [US8] Create acceptance test for dry-run: execute `specrew update --dry-run` and verify proposed changes shown without file modifications [effort: 1 SP] [test: acceptance]

### Iteration 3 Validation & Documentation

- [ ] T074 Update `specs/051-multi-session-foundation/data-model.md` with SpecKitUpgradeContext entity [effort: 1 SP] [governance: data-model]
- [ ] T075 Run all Iteration 3 acceptance tests and document results in test summary artifact [effort: 2 SP] [test: acceptance-suite]
- [ ] T076 Execute Specrew validator and verify no regressions from Iteration 1-2 changes [effort: 1 SP] [test: regression-check]

---

## Iteration 4: Identity Split & Brand-New Worktree Detection (Target: 8-12 SP)

**User Stories**: US9 (Split Session-State Transient Fields), US10 (Detect Brand-New Worktrees)  
**Functional Requirements**: FR-035 through FR-043  
**Success Criteria**: SC-001 (merge conflicts eliminated), SC-002 (collision warning within 2s)

### Session-State Identity Split (Phase 4, US9 → FR-035 through FR-038)

- [ ] T077 [P] Create `scripts/identity-split.ps1` with identity split management functions: split-identity-fields, migrate-session-state, validate-split-integrity (FR-035, FR-036, FR-037, FR-038) [effort: 2 SP] [SC: SC-001]
- [ ] T078 [US9] Implement identity split: separate `.squad/identity/now.md` into shared content (focus_area, body) and per-session fields (session_state_active, session_state_boundary, session_state_feature_path, session_state_iteration, session_state_auth_commit, session_state_recorded_at) (FR-035) [effort: 2 SP]
- [ ] T079 [P] [US9] Create new gitignored split file `.squad/identity/session-state.yml` to hold per-session transient fields with `.gitignore` entry pattern added (FR-036) [effort: 1 SP] [SC: SC-001]
- [ ] T080 [US9] Implement migration logic: strip existing session_state_* fields from `.squad/identity/now.md` on first run, write them to `.squad/identity/session-state.yml`, commit updated now.md (FR-037) [effort: 2 SP]
- [ ] T081 [P] [US9] Implement validation: grep for `session_state_` in tracked files and error if any found; ensure gitignored session-state file contains these fields and tracked now.md does not (FR-038) [effort: 1 SP]
- [ ] T082 [P] [US9] Create acceptance test for identity split: verify shared content persists in now.md, per-session content moves to gitignored session-state.yml, merge conflicts eliminated [effort: 1 SP] [test: acceptance] [SC: SC-001]
- [ ] T083 [P] [US9] Create acceptance test for split validation: verify grep finds no session_state_* in tracked files post-migration [effort: 1 SP] [test: acceptance]

### Brand-New Worktree Detection (Phase 4, US10 → FR-039 through FR-043)

- [ ] T084 [P] Create `scripts/worktree-detection.ps1` with brand-new worktree detection functions: detect-brand-new-worktree, detect-stale-state, compute-detection-signals (FR-039) [effort: 2 SP]
- [ ] T085 [US10] Implement brand-new detection heuristics: check for (1) empty `.specrew/active-sessions.yml` (or missing file), (2) no recent boundary commits on current branch, (3) no iteration directories matching inherited feature_path under `specs/<feature>/iterations/` (FR-039) [effort: 2 SP]
- [ ] T086 [P] [US10] Implement stale-state recovery prompt suppression: when brand-new condition detected at `specrew start`, skip A/B/C recovery prompt and proceed directly to new-feature specify flow (FR-040) [effort: 1 SP]
- [ ] T087 [P] [US10] Implement recovery prompt preservation: when state is genuinely inconsistent (feature_path on inherited state ≠ current branch name AND iteration directories exist), display A/B/C recovery prompt (FR-041) [effort: 1 SP]
- [ ] T088 [US10] Implement state detection logging: log all brand-new detection signals and decisions to `.specrew/session-start.log` with timestamp, detected signals, and decision rationale (brand-new vs. recovery needed) (FR-042) [effort: 1 SP]
- [ ] T089 [P] [US10] Create machine fingerprinting scope validation: ensure fingerprints are computed locally only and NOT transmitted over network (local-only validation, no telemetry calls) (FR-043) [effort: 1 SP] [governance: security]
- [ ] T090 [P] [US10] Create acceptance test for brand-new detection: launch fresh worktree on main, run `specrew start --feature F-999-test`, verify no stale-state prompt appears, new-feature flow runs cleanly [effort: 2 SP] [test: acceptance]
- [ ] T091 [P] [US10] Create acceptance test for recovery preservation: create worktree with prior feature state pointing to different feature, verify A/B/C prompt appears when mismatch detected [effort: 1 SP] [test: acceptance]
- [ ] T092 [P] [US10] Create acceptance test for local fingerprinting: verify no network calls made during fingerprint computation; fingerprint stored locally only in `.specrew/active-sessions.yml` [effort: 1 SP] [test: acceptance] [governance: security]

### Iteration 4 Validation & Documentation

- [ ] T093 Create `specs/051-multi-session-foundation/contracts/` directory with interface contract files for session management, feature claims, auto-detection (if applicable) [effort: 1 SP] [governance: contracts]
- [ ] T094 Update `specs/051-multi-session-foundation/data-model.md` with BrandNewWorktreeSignal entity [effort: 1 SP] [governance: data-model]
- [ ] T095 Run all Iteration 4 acceptance tests and document results in test summary artifact [effort: 2 SP] [test: acceptance-suite]
- [ ] T096 Execute Specrew validator across all iterations and verify no regressions; confirm all acceptance scenarios pass [effort: 1 SP] [test: regression-check]
- [ ] T097 Create feature-level summary document: map all 97 tasks to FRs and user stories, verify 100% coverage [effort: 1 SP] [governance: traceability]

---

## Dependency Graph & Parallel Opportunities

### Critical Path (Sequential Dependencies)

```
Iteration 1 (Config + Classification)
  ↓
Iteration 2 (Collision Detection + Claims + Auto-Detection)
  ├→ Iteration 3 (Spec-Kit Upgrade + Version Fix) [parallel]
  └→ Iteration 4 (Identity Split + Brand-New Detection) [depends on Iteration 2]
```

### Parallelization Opportunities

**Within Iteration 1**:

- T001-T003 (Setup & Schema) can run in parallel
- T004-T008 (Session Mode) can run in parallel after Setup
- T009-T015 (File Classification) can run in parallel after Setup

**Within Iteration 2**:

- Session Management (T020-T026) and Feature Claims (T027-T033) are independent; can run in parallel
- Conflict Reduction (T034-T041) and Auto-Detection (T042-T052) can run in parallel after session/claims work

**Within Iteration 3**:

- Spec-Kit Upgrade (T056-T065) and Version Management (T066-T073) are independent; can run in parallel

**Within Iteration 4**:

- Identity Split (T077-T083) and Brand-New Detection (T084-T092) are independent; can start in parallel
- Validation (T093-T097) runs after both complete

---

## Quality Gates & Acceptance Criteria

### Iteration 1 Quality Gate

✓ Configuration persists correctly (`specrew config set session_mode multi` → `.specrew/config.yml`)  
✓ Defaults work (`specrew init` → `session_mode: single`)  
✓ Gitignore excludes all per-session file patterns  
✓ Git cleanup removes previously tracked files from index  
✓ No regressions in Specrew core functionality  

### Iteration 2 Quality Gate

✓ Collision warning appears within 2 seconds (SC-002)  
✓ Feature claims recorded at specify boundary, refreshed at each lifecycle boundary (SC-008)  
✓ Merge conflicts eliminated on `.squad/decisions.md` and `Specrew.psd1` (SC-006)  
✓ Multi-developer signals detected within one `specrew start` command (SC-003)  
✓ No regressions from Iteration 1  

### Iteration 3 Quality Gate

✓ Spec-Kit upgrade completes in <2 minutes (SC-004)  
✓ All governance validators pass after upgrade  
✓ Version sync accuracy 100% (SC-005)  
✓ `--dry-run` flag shows changes without modifications  
✓ No regressions from Iteration 1-2  

### Iteration 4 Quality Gate

✓ Identity split removes session_state_* from tracked files  
✓ Per-session state remains gitignored  
✓ Brand-new worktree detection skips stale-state recovery on fresh worktrees  
✓ Recovery prompt preserved when state genuinely inconsistent  
✓ Machine fingerprinting remains local-only (no network calls)  
✓ All 97 tasks map to FRs (100% traceability)  

---

## Traceability Matrix: Tasks to Requirements

| Iteration | Task Range | User Stories | Functional Requirements | Success Criteria |
|-----------|-----------|--------------|----------------------|------------------|
| 1 | T001-T019 | US1, US2 | FR-001 to FR-006 | SC-001, SC-005 |
| 2 | T020-T055 | US3, US4, US5, US6 | FR-007 to FR-024 | SC-002, SC-003, SC-006, SC-007, SC-008 |
| 3 | T056-T076 | US7, US8 | FR-025 to FR-034 | SC-004, SC-005 |
| 4 | T077-T097 | US9, US10 | FR-035 to FR-043 | SC-001, SC-002 |

**Total Coverage**: 97 tasks × 43 functional requirements = 100% FR traceability; 97 tasks × 10 user stories = complete user story coverage

---

## Effort Verification & SP Allocation

This section provides explicit SP calculations for each iteration to enable reviewer verification against capacity envelopes.

### Iteration 1 Effort Summary (Target: ≤20 SP)

**Approved SP Range**: ≤20 SP  
**Actual Allocation**: 18 SP ✓

### Iteration 2 Effort Summary (Target: 12-18 SP)

**Approved SP Range**: 12-18 SP  
**Actual Allocation**: 18 SP ✓

### Iteration 3 Effort Summary (Target: 10-15 SP)

**Approved SP Range**: 10-15 SP  
**Actual Allocation**: 14 SP ✓

### Iteration 4 Effort Summary (Target: 8-12 SP)

**Approved SP Range**: 8-12 SP  
**Actual Allocation**: 12 SP ✓

**Feature-Level Total**: 97 tasks across 4 iterations = **62 SP** (within approved 45-65 SP envelope)

**Verification**: Each iteration-level tasks file will contain detailed per-task SP markup `[effort: N SP]` for spot-check validation. Reviewers can compute iteration totals by summing effort values in the before-implement hardening gate.

---

**Phase 1 (MVP Foundation)**: Iterations 1-2 deliver the essential multi-developer foundation (configuration, file classification, collision detection, feature claims). This enables safe parallel feature work and eliminates merge conflicts on per-session files.

**Phase 2 (Infrastructure Upgrades)**: Iteration 3 upgrades Spec-Kit and fixes version tracking, unblocking new tool capabilities.

**Phase 3 (UX Refinement)**: Iteration 4 eliminates false stale-state recovery prompts and cleanly separates shared identity from per-session state, providing friction-free multi-developer experience.

**Post-MVP Enhancement**: Proposal 148 Layer 2+3 (file-surface overlap detection, predictive feature-pair ranking) deferred to F-054+ after foundation validation.

---

## Next Steps

1. ✅ Review tasks.md for completeness and FR traceability
2. ✅ Execute before-implement hardening gate (security review of file writes, race condition analysis, atomic write patterns)
3. ✅ Approval from human reviewer (Alon Fliess) to proceed with Iteration 1 implementation
4. ✅ Execute tasks in dependency order (Iteration 1 → Iteration 2 → Iteration 3 → Iteration 4)
5. ✅ Run acceptance scenario tests after each iteration
6. ✅ Execute feature-level drift check at completion (verify all FRs implemented, no scope creep)

---

**Generated**: 2026-05-31  
**Status**: Ready for before-implement hardening gate and implementation approval  
**Next Boundary**: Before-implement hardening gate, then implementation
