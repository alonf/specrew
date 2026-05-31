# Tasks: Multi-Session Foundation

**Feature**: 051-multi-session-foundation  
**Branch**: 051-multi-session-foundation  
**Total Tasks**: 101 (Iteration 2a decomposition refined 2026-05-31: +4 sub-tasks T020b/T020c/T026b/T033b)  
**Iterations**: 5 (Iteration 1 ~11 SP, Iteration 2a ~12 SP, Iteration 2b ~13 SP, Iteration 3 ~13.5 SP, Iteration 4 ~13 SP — all within the ≤20 SP cap)  
**Total Effort**: ~62.5 SP (honest re-estimate 2026-05-31; Iteration 2a refined 10→12 SP at plan-time via the planning workflow; supersedes the inflated 139 SP markup from the 48→97 expansion — see [iterations/001/capacity-reestimate.md](iterations/001/capacity-reestimate.md))  
**Status**: Ready for before-implement hardening gate  

---

## Overview

This tasks artifact defines a complete, dependency-ordered implementation plan for F-051 Multi-Session Foundation across 5 iterations (1, 2a, 2b, 3, 4). Each task is mapped to one or more functional requirements (FR-001 through FR-043) and user stories (US1 through US10). Tasks are organized by iteration and organized to enable:

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

- [ ] T001 [P] Create PowerShell module manifest updates scaffold in `Specrew.psd1` for session mode feature module support [effort: 0.5 SP] [FR-001] [governance: module-structure]
- [ ] T002 Review `.specrew/config.yml` schema structure and add session_mode configuration key definition (FR-001) [effort: 0.5 SP] [governance: schema-definition]
- [ ] T003 [P] Create file classification schema document in `.specify/config.yml` defining per-session file patterns (`.specrew/last-*`, `.specify/feature.json`, `.specrew/start-context.json`, `.specrew/host-history.json`, `.specrew/.cache/`, `.squad/sessions/`, `.squad/decisions/inbox/`, `.specrew/last-validator-summary.json`) [effort: 0.5 SP] [FR-004]

### Session Mode Configuration (Phase 1, US1 → FR-001, FR-002, FR-003)

- [ ] T004 [US1] Create `scripts/specrew-config.ps1` + `scripts/internal/session-config.ps1` with `Set-SessionMode` function to update `.specrew/config.yml` session_mode field and validate value is `single` or `multi` (FR-001, FR-002) [effort: 1 SP] [SC: SC-001]
- [ ] T005 [US1] Implement CLI command entry point `specrew config set session_mode <value>` via `scripts/specrew-config.ps1` dispatched from the `config` case in `scripts/specrew.ps1`, with success message and error handling (FR-002) [effort: 0.5 SP] [SC: SC-001]
- [ ] T006 [P] [US1] Add default session_mode initialization logic to `specrew init` flow to set `session_mode: single` when not present in `.specrew/config.yml` (FR-003) [effort: 0.5 SP]
- [ ] T007 [P] [US1] Create acceptance test for session mode configuration: verify `specrew config set session_mode multi` persists to config file and `specrew config set session_mode single` reverts it [effort: 0.5 SP] [test: acceptance]
- [ ] T008 [P] [US1] Create acceptance test for session mode defaults: verify fresh `specrew init` results in `session_mode: single` in `.specrew/config.yml` [effort: 0.5 SP] [test: acceptance]

### File Classification & Gitignore Management (Phase 1, US2 → FR-004, FR-005, FR-006)

- [ ] T009 [US2] Create `scripts/internal/file-classification.ps1` with file classification schema function defining rules for: shared (committed, identical), per-session (gitignored), append-only-shared (committed, atomic append), regenerable (generated from shared sources) (FR-004) [effort: 1 SP] [SC: SC-001]
- [ ] T010 [P] [US2] Implement gitignore generation logic in `scripts/internal/file-classification.ps1` to create/update `.gitignore` with patterns for per-session files: `.specrew/last-*`, `.specify/feature.json`, `.specrew/start-context.json`, `.specrew/host-history.json`, `.specrew/.cache/`, `.squad/sessions/`, `.squad/decisions/inbox/`, `.specrew/last-validator-summary.json` (FR-005) [effort: 1 SP] [SC: SC-001]
- [ ] T011 [P] [US2] Integrate gitignore generation into `specrew init` flow to call file-classification logic and update `.gitignore` on each init run (FR-005) [effort: 0.5 SP]
- [ ] T012 [US2] Implement `git rm --cached` cleanup in `scripts/internal/file-classification.ps1` to remove previously tracked per-session files from git index without deleting from working directory (FR-006) [effort: 0.5 SP] [SC: SC-001]
- [ ] T013 [US2] Create cleanup step in `specrew init` to invoke `git rm --cached` for any per-session files that were previously committed (FR-006) [effort: 0.5 SP]
- [ ] T014 [P] [US2] Create acceptance test for gitignore generation: verify `.gitignore` excludes all per-session file patterns after `specrew init` [effort: 0.5 SP] [test: acceptance]
- [ ] T015 [P] [US2] Create acceptance test for git cleanup: verify previously tracked per-session files are removed from git index via `git rm --cached` without deleting working directory copies [effort: 0.5 SP] [test: acceptance]

### Iteration 1 Validation & Documentation

> **Plan-boundary note (2026-05-31 repair):** `data-model.md`, `quickstart.md`, `research.md`, `contracts/multi-session-foundation.md`, and `review-diagrams.md` were authored at the plan boundary per the Spec-Kit plan-boundary artifact discipline (coordinator Rule 54 + F-054 precedent). T016/T017 are re-scoped from "create" to "verify-and-keep-accurate as Iteration-1 code lands" — the create work is already done; these tasks now cover keeping the artifacts in sync with shipped behavior.

- [ ] T016 [P] Verify `specs/051-multi-session-foundation/quickstart.md` stays accurate against the shipped Iteration-1 session-mode + file-classification behavior; update any drifted commands/expected output [effort: 0.5 SP] [governance: documentation]
- [ ] T017 Verify `specs/051-multi-session-foundation/data-model.md` SessionModeConfig + FileClassificationRule entities match the shipped Iteration-1 schema; reconcile any attribute drift [effort: 0.5 SP] [governance: data-model]
- [ ] T018 Run all Iteration 1 acceptance tests and document results in test summary artifact [effort: 0.5 SP] [test: acceptance-suite]
- [ ] T019 Execute Specrew validator on updated module to ensure backward compatibility and no regressions [effort: 0.5 SP] [test: regression-check]

---

## Iteration 2a: Collision Detection & Feature Claims (Target: ≤20 SP; re-estimated ~12 SP)

**User Stories**: US3 (Detect Concurrent Session Collisions), US4 (Claim Features)  
**Functional Requirements**: FR-007 through FR-016 (+ FR-043 fingerprint privacy, population-side only)  
**Success Criteria**: SC-002 (collision warning within 2s), SC-008 (claim refresh 100%)  
**On-disk iteration dir**: `iterations/002` (zero-padded; `-IterationNumber 002`). Label "Iteration 2a" is prose only.

> **Split note (2026-05-31):** original Iteration 2 packed 4 user stories (~23 SP honest estimate, over its cap). Per "split, don't raise" it was divided into **2a** (US3+US4 — lock/claim primitives) and **2b** (US5+US6 — conflict-reduction + multi-dev detection). All FRs preserved.
>
> **Decomposition refined 2026-05-31 (planning workflow, honest re-sum 10→12 SP):** idiomatic `scripts/internal/` paths (D-002 fix); explicit existing-file wiring globs (no new dispatch case — `specrew-start.ps1` for FR-008/010/011/015; `sync-boundary-state.ps1` for FR-009/013/014/016); `Write-SpecrewFileAtomic` EXTRACTED to a shared helper (not duplicated); 3 net-new tasks (T020b fingerprint, T026b race test, T033b 2a validation) the prior decomposition missed; `.specrew/active-sessions.yml` added to gitignore patterns (FR-005 gap). Decision blessed: lock = local (same-machine/worktree); cross-machine collision is the committed claims file's job (see drift D-003).

### Session Management & Collision Detection (Phase 2a, US3 → FR-007 through FR-011)

- [ ] T020 Create `scripts/internal/session-management.ps1` (Read-ActiveSessions, Write-ActiveSessions over `.specrew/active-sessions.yml`); EXTRACT `Write-SpecrewFileAtomic` from `session-config.ps1` into shared `scripts/internal/atomic-write.ps1` (reused, not duplicated); corrupt YAML → empty + logged warning; register both new modules in `Specrew.psd1` FileList (alphabetical) (FR-007) [effort: 1 SP] [governance: filelist]
- [ ] T020b [US3] Create `Get-MachineFingerprint` local-only helper (hostname+username-derived; FR-043 local-only, zero network/telemetry) to populate `machine_fingerprint` on lock entries; full fingerprint written ONLY to gitignored `active-sessions.yml` (FR-007, FR-043 population-side) [effort: 0.5 SP] [governance: security]
- [ ] T020c [US3] Add `.specrew/active-sessions.yml` to `$script:SpecrewPerSessionPatterns` in `scripts/internal/file-classification.ps1` (iter-1 patterns do NOT match it → would be committed); record the lock-is-local vs US3.1-cross-machine reconciliation in drift-log (D-003) (FR-005 gap, FR-007) [effort: 0.5 SP] [governance: classification]
- [ ] T021 [US3] Implement `Register-SessionLock` (append SessionLockEntry on `specrew start`; atomic write); wire into existing `scripts/specrew-start.ps1` at session-launch (no new dispatch case) (FR-008) [effort: 1 SP] [owner: scripts/specrew-start.ps1]
- [ ] T022 [US3] Implement `Remove-SessionLock`; wire into `scripts/internal/sync-boundary-state.ps1` at `feature-closeout` (no `specrew stop` trigger exists; FR-011 staleness is the real liveness path) (FR-009) [effort: 0.5 SP] [owner: sync-boundary-state.ps1]
- [ ] T023 [US3] Implement `Test-SessionCollision` (return colliding entry or null); wire into `scripts/specrew-start.ps1` to display "Another active session detected for feature <id> (started by <user>@<machine> at <ts>)…" (FR-010) [effort: 1 SP] [SC: SC-002] [owner: scripts/specrew-start.ps1]
- [ ] T024 [US3] Implement `Clear-StaleSessionLocks(thresholdHours=config default 24)` (read-modify-write via shared atomic primitive; emit notice; return count); wire into `scripts/specrew-start.ps1` before collision check (FR-011) [effort: 1 SP] [owner: scripts/specrew-start.ps1]
- [ ] T025 [P] [US3] Acceptance test (real temp-repo, no mocks): two concurrent `specrew start` on same feature → 2nd gets collision warning within 2s (FR-010, SC-002) [effort: 0.5 SP] [test: acceptance] [SC: SC-002]
- [ ] T026 [P] [US3] Acceptance test: seed lock with last_heartbeat_time >24h → cleared with notice + correct count; corrupt-YAML safe-degradation (FR-011 + Edge Case) [effort: 0.5 SP] [test: acceptance]
- [ ] T026b [US3] Acceptance test — deterministic controlled-interleave atomic-write/race (Edge Case): assert always-valid YAML after clobber + last-write-wins is real + FR-014 refresh re-adds clobbered claim + duplicate surfaced (covers active-sessions.yml + active-features.yml) (FR-007, FR-012) [effort: 0.5 SP] [test: acceptance]

### Feature Claims Tracking (Phase 2a, US4 → FR-012 through FR-016)

- [ ] T027 Create `scripts/internal/feature-claims.ps1` (Read-FeatureClaims, Write-FeatureClaims over `.squad/active-features.yml`) reusing the shared atomic-write helper; corrupt YAML → empty + warning; register in `Specrew.psd1` FileList (claims file is committed/append-only-shared, unlike the gitignored lock) (FR-012) [effort: 1 SP] [governance: filelist]
- [ ] T028 [US4] Implement `Add-FeatureClaim` (upsert-by-feature_id; claimed_by=user@machine coarse only, no localhash) at the specify boundary; wire into `scripts/internal/sync-boundary-state.ps1` keyed on `BoundaryType='specify'` (FR-013) [effort: 0.5 SP] [SC: SC-008] [owner: sync-boundary-state.ps1]
- [ ] T029 [US4] Implement `Update-FeatureClaim` (monotonic last_refresh_time) on every boundary crossing; wire into `scripts/internal/sync-boundary-state.ps1` on each `BoundaryType` (FR-014) [effort: 0.5 SP] [SC: SC-008] [owner: sync-boundary-state.ps1]
- [ ] T030 [US4] Implement concurrent-claim Layer-1 warning + "Continue anyway?": (a) y/Y/yes records BOTH claims + session note; (b) n/N/no exits without a session; wire detection into `scripts/specrew-start.ps1` (FR-015) [effort: 1 SP] [owner: scripts/specrew-start.ps1]
- [ ] T031 [US4] Implement `Remove-FeatureClaim` at feature-closeout when merged-to-main (reuse `Test-SpecrewFeatureMergedToMain`); wire into `scripts/internal/sync-boundary-state.ps1` (FR-016) [effort: 0.5 SP] [owner: sync-boundary-state.ps1]
- [ ] T032 [P] [US4] Acceptance test (real surfaces): claim recorded @specify, last_refresh_time advanced @plan/tasks (SC-008), removed @closeout-when-merged; manually-removed-claim re-add while session active (Edge Case) (FR-013/014/016) [effort: 0.5 SP] [test: acceptance] [SC: SC-008]
- [ ] T033 [P] [US4] Acceptance test: two developers same feature → Layer-1 warning with claim details; continue (both recorded) and decline (exits, no session) variants (FR-015) [effort: 0.5 SP] [test: acceptance]

### Iteration 2a Validation & Documentation

- [ ] T033b Run all 2a acceptance tests + `validate-governance.ps1` (the validator IS the audit, retro action 9); record coverage-evidence naming each new 2a test file as EXECUTED (closes the F-049 iter-5 / F-050 iter-2 coverage-drift trap); verify data-model SessionLockEntry + FeatureClaimEntry match shipped schema; confirm sync `-IterationNumber 002` (retro action 8) (FR-007, FR-016) [effort: 0.5 SP] [test: validation]

---

## Iteration 2b: Conflict Reduction & Multi-Developer Auto-Detection (Target: ≤20 SP; re-estimated ~13 SP)

**User Stories**: US5 (Reduce Shared-File Merge Conflicts), US6 (Detect Multi-Developer Activity)  
**Functional Requirements**: FR-017 through FR-024  
**Success Criteria**: SC-003 (multi-dev detection), SC-006 (merge conflict elimination), SC-007 (recommendation within 0-2s)

### Shared File Merge Conflict Reduction (Phase 2b, US5 → FR-017, FR-018, FR-019)

- [x] T034 [P] Create `scripts/decisions-split.ps1` to split `.squad/decisions.md` into per-iteration files under `.squad/decisions/iteration-NNN/decisions.md` when in multi-session mode (FR-017) [effort: 1 SP] [SC: SC-006]
- [x] T035 [US5] Create function to detect when multi-session mode is enabled and apply per-iteration split to decisions at boundary-sync time (FR-017) [effort: 0.5 SP] [SC: SC-006]
- [x] T036 [P] Create `scripts/append-only-logs.ps1` to implement JSON Lines format (one JSON object per line) for append-only log files, enabling atomic appends and mechanical conflict resolution (FR-018) [effort: 1 SP] [SC: SC-006]
- [x] T037 [US5] Implement JSON Lines writer function for lifecycle event logging (FR-018) [effort: 0.5 SP]
- [x] T038 [P] Create `scripts/psd1-sort.ps1` to alphabetically sort the `Specrew.psd1` FileList array during boundary-sync writes to minimize merge conflicts (FR-019) [effort: 0.5 SP] [SC: SC-006]
- [x] T039 [US5] Integrate psd1 alphabetical sort into boundary-sync process to re-sort FileList before writing updates (FR-019) [effort: 0.5 SP]
- [x] T040 [P] [US5] Create acceptance test for decisions split: verify two features both recording decisions result in per-iteration files with no merge conflicts [effort: 0.5 SP] [test: acceptance] [SC: SC-006]
- [x] T041 [P] [US5] Create acceptance test for psd1 sort: verify FileList array is alphabetically sorted after boundary-sync [effort: 0.5 SP] [test: acceptance]

### Multi-Developer Auto-Detection (Phase 2b, US6 → FR-020 through FR-024)

- [x] T042 [P] Create `scripts/auto-detection.ps1` with multi-developer signal detection functions: detect-git-authors, detect-machine-fingerprints, detect-concurrent-writes, detect-branch-fanout (FR-020) [effort: 1 SP] [SC: SC-003]
- [x] T043 [US6] Implement git author email detection: scan git history for last 90 days and count unique author emails (FR-020) [effort: 0.5 SP] [SC: SC-003]
- [x] T044 [P] [US6] Implement machine fingerprint detection: scan `.specrew/active-sessions.yml` and session-state files for unique machine_fingerprint values (FR-020) [effort: 0.5 SP] [SC: SC-003]
- [x] T045 [P] [US6] Implement concurrent write detection: identify multiple session-state file modifications from different machines within 1 minute window (FR-020) [effort: 1 SP] [SC: SC-003]
- [x] T046 [P] [US6] Implement branch fan-out detection: identify 3+ feature branches diverging from same base commit (FR-020) [effort: 0.5 SP] [SC: SC-003]
- [x] T047 [US6] Implement multi-session recommendation message in Welcome Orientation: display "Multiple developers detected (X unique authors). Consider enabling multi-session mode: `specrew config set session_mode multi`" when session_mode is `single` and signals are detected (FR-021) [effort: 0.5 SP] [SC: SC-007]
- [x] T048 [P] [US6] Implement multi-developer indicator in `specrew where` dashboard to show count of unique machines and recommendation to enable multi-session mode when signals detected (FR-022) [effort: 0.5 SP] [SC: SC-007]
- [x] T049 [P] [US6] Implement multi-developer activity note in boundary-sync output when signals are detected (FR-023) [effort: 0.5 SP]
- [x] T050 [US6] Implement recommendation suppression when `session_mode` is already set to `multi` to avoid redundant messages (FR-024) [effort: 0.5 SP]
- [x] T051 [P] [US6] Create acceptance test for multi-dev detection: simulate commits from two different git authors and verify recommendation appears in Welcome Orientation within 2 seconds [effort: 0.5 SP] [test: acceptance] [SC: SC-007]
- [x] T052 [P] [US6] Create acceptance test for signal suppression: set `session_mode: multi` and verify no multi-developer recommendation appears [effort: 0.5 SP] [test: acceptance]

### Iteration 2b Validation & Documentation

- [x] T053 Verify `specs/051-multi-session-foundation/data-model.md` SessionLockEntry, FeatureClaimEntry, MultiDevSignal entities match the shipped 2a/2b schema; reconcile any attribute drift (entities authored at plan boundary) [effort: 0.5 SP] [governance: data-model]
- [x] T054 Run all Iteration 2a+2b acceptance tests and document results in test summary artifact [effort: 0.5 SP] [test: acceptance-suite]
- [x] T055 Execute Specrew validator and verify no regressions from Iteration 1/2a changes [effort: 0.5 SP] [test: regression-check]

---

## Iteration 3: Spec-Kit Upgrade & specrew update Fix (Target: ≤20 SP; re-estimated ~13.5 SP)

**User Stories**: US7 (Upgrade Spec-Kit to 0.8.18), US8 (Fix Baseline Version Bump)  
**Functional Requirements**: FR-025 through FR-034  
**Success Criteria**: SC-004 (upgrade completes in <2 min), SC-005 (version sync 100% accurate)

### Spec-Kit Installation Detection & Upgrade Mechanism (Phase 3, US7 → FR-025 through FR-030)

- [ ] T056 [P] Create `scripts/spec-kit-upgrade.ps1` with Spec-Kit installation detection function: detect if Spec-Kit is installed via npm package, deployed extension directory, or manual files (FR-026) [effort: 1 SP] [SC: SC-004]
- [ ] T057 [US7] Implement npm package detection: check if Spec-Kit is installed via npm in `node_modules/` and identify package.json location (FR-026) [effort: 0.5 SP]
- [ ] T058 [P] [US7] Implement extension directory detection: check if Spec-Kit is deployed under `.specify/extensions/specrew-speckit/` (most common in Specrew bootstrap) (FR-026) [effort: 0.5 SP]
- [ ] T059 [P] [US7] Implement upgrade mechanism selector: identify appropriate upgrade path based on installation method detected (npm update, extension file replacement, manual) (FR-027) [effort: 1 SP]
- [ ] T060 [US7] Implement npm upgrade path: execute `npm install speckit@0.8.18` if Spec-Kit is installed via npm (FR-027) [effort: 0.5 SP]
- [ ] T061 [P] [US7] Implement extension directory upgrade: download and extract Spec-Kit 0.8.18 extension files to `.specify/extensions/specrew-speckit/`, preserving local configuration in `.specify/` directories (FR-028) [effort: 1.5 SP]
- [ ] T062 [P] [US7] Implement version update logic: write `speckit_version: "0.8.18"` to `.specrew/config.yml` after successful upgrade (FR-029) [effort: 0.5 SP] [SC: SC-005]
- [ ] T063 [US7] Implement post-upgrade validation: run Specrew governance validator after upgrade completes and report any compatibility issues (FR-030) [effort: 0.5 SP]
- [ ] T064 [P] [US7] Create `specrew upgrade-speckit` command entry point in `scripts/specrew-cli.ps1` to trigger upgrade workflow (FR-025) [effort: 0.5 SP]
- [ ] T065 [P] [US7] Create acceptance test for Spec-Kit upgrade: execute upgrade from 0.8.13 to 0.8.18 on test system, verify completion in <2 minutes, verify `.specrew/config.yml` shows 0.8.18, verify validator passes [effort: 1 SP] [test: acceptance] [SC: SC-004]

### Version Detection & Update Fix (Phase 3, US8 → FR-031 through FR-034)

- [ ] T066 [P] Create `scripts/version-management.ps1` with version detection functions: get-specrew-installed-version, read-configured-version, compare-versions (FR-032) [effort: 1 SP] [SC: SC-005]
- [ ] T067 [US8] Implement Specrew installed version detection: use `Get-Module Specrew -ListAvailable` or similar PowerShell metadata to retrieve installed module version (FR-032) [effort: 0.5 SP]
- [ ] T068 [P] [US8] Implement version field write fix in `specrew update` command: update `.specrew/config.yml` `specrew_version` field to match installed module version (FR-031) [effort: 0.5 SP] [SC: SC-005]
- [ ] T069 [P] [US8] Implement version drift warning during `specrew start`: when installed Specrew version ≠ `.specrew/config.yml` `specrew_version`, display warning: "Installed Specrew X.Y.Z differs from project pin A.B.C. Run `specrew update` to sync." (FR-033) [effort: 0.5 SP]
- [ ] T070 [US8] Implement `--dry-run` flag for `specrew update`: show proposed version change without modifying files (FR-034) [effort: 0.5 SP]
- [ ] T071 [P] [US8] Create acceptance test for version sync: install specific Specrew version (e.g., 0.29.0), run `specrew update`, verify `.specrew/config.yml` shows 0.29.0 (100% accuracy) [effort: 0.5 SP] [test: acceptance] [SC: SC-005]
- [ ] T072 [P] [US8] Create acceptance test for version drift warning: create version mismatch scenario and verify warning appears at `specrew start` [effort: 0.5 SP] [test: acceptance]
- [ ] T073 [P] [US8] Create acceptance test for dry-run: execute `specrew update --dry-run` and verify proposed changes shown without file modifications [effort: 0.5 SP] [test: acceptance]

### Iteration 3 Validation & Documentation

- [ ] T074 Update `specs/051-multi-session-foundation/data-model.md` with SpecKitUpgradeContext entity [effort: 0.5 SP] [governance: data-model]
- [ ] T075 Run all Iteration 3 acceptance tests and document results in test summary artifact [effort: 0.5 SP] [test: acceptance-suite]
- [ ] T076 Execute Specrew validator and verify no regressions from Iteration 1/2a/2b changes [effort: 0.5 SP] [test: regression-check]

---

## Iteration 4: Identity Split & Brand-New Worktree Detection (Target: ≤20 SP; re-estimated ~13 SP)

**User Stories**: US9 (Split Session-State Transient Fields), US10 (Detect Brand-New Worktrees)  
**Functional Requirements**: FR-035 through FR-043  
**Success Criteria**: SC-001 (merge conflicts eliminated), SC-002 (collision warning within 2s)

### Session-State Identity Split (Phase 4, US9 → FR-035 through FR-038)

- [ ] T077 [P] Create `scripts/identity-split.ps1` with identity split management functions: split-identity-fields, migrate-session-state, validate-split-integrity (FR-035, FR-036, FR-037, FR-038) [effort: 1 SP] [SC: SC-001]
- [ ] T078 [US9] Implement identity split: separate `.squad/identity/now.md` into shared content (focus_area, body) and per-session fields (session_state_active, session_state_boundary, session_state_feature_path, session_state_iteration, session_state_auth_commit, session_state_recorded_at) (FR-035) [effort: 1 SP]
- [ ] T079 [P] [US9] Create new gitignored split file `.squad/identity/session-state.yml` to hold per-session transient fields with `.gitignore` entry pattern added (FR-036) [effort: 0.5 SP] [SC: SC-001]
- [ ] T080 [US9] Implement migration logic: strip existing session_state_* fields from `.squad/identity/now.md` on first run, write them to `.squad/identity/session-state.yml`, commit updated now.md (FR-037) [effort: 1 SP]
- [ ] T081 [P] [US9] Implement validation: grep for `session_state_` in tracked files and error if any found; ensure gitignored session-state file contains these fields and tracked now.md does not (FR-038) [effort: 0.5 SP]
- [ ] T082 [P] [US9] Create acceptance test for identity split: verify shared content persists in now.md, per-session content moves to gitignored session-state.yml, merge conflicts eliminated [effort: 0.5 SP] [test: acceptance] [SC: SC-001]
- [ ] T083 [P] [US9] Create acceptance test for split validation: verify grep finds no session_state_* in tracked files post-migration [effort: 0.5 SP] [test: acceptance]

### Brand-New Worktree Detection (Phase 4, US10 → FR-039 through FR-043)

- [ ] T084 [P] Create `scripts/worktree-detection.ps1` with brand-new worktree detection functions: detect-brand-new-worktree, detect-stale-state, compute-detection-signals (FR-039) [effort: 1 SP]
- [ ] T085 [US10] Implement brand-new detection heuristics: check for (1) empty `.specrew/active-sessions.yml` (or missing file), (2) no recent boundary commits on current branch, (3) no iteration directories matching inherited feature_path under `specs/<feature>/iterations/` (FR-039) [effort: 1 SP]
- [ ] T086 [P] [US10] Implement stale-state recovery prompt suppression: when brand-new condition detected at `specrew start`, skip A/B/C recovery prompt and proceed directly to new-feature specify flow (FR-040) [effort: 0.5 SP]
- [ ] T087 [P] [US10] Implement recovery prompt preservation: when state is genuinely inconsistent (feature_path on inherited state ≠ current branch name AND iteration directories exist), display A/B/C recovery prompt (FR-041) [effort: 0.5 SP]
- [ ] T088 [US10] Implement state detection logging: log all brand-new detection signals and decisions to `.specrew/session-start.log` with timestamp, detected signals, and decision rationale (brand-new vs. recovery needed) (FR-042) [effort: 0.5 SP]
- [ ] T089 [P] [US10] Create machine fingerprinting scope validation: ensure fingerprints are computed locally only and NOT transmitted over network (local-only validation, no telemetry calls) (FR-043) [effort: 0.5 SP] [governance: security]
- [ ] T090 [P] [US10] Create acceptance test for brand-new detection: launch fresh worktree on main, run `specrew start --feature F-999-test`, verify no stale-state prompt appears, new-feature flow runs cleanly [effort: 0.5 SP] [test: acceptance]
- [ ] T091 [P] [US10] Create acceptance test for recovery preservation: create worktree with prior feature state pointing to different feature, verify A/B/C prompt appears when mismatch detected [effort: 0.5 SP] [test: acceptance]
- [ ] T092 [P] [US10] Create acceptance test for local fingerprinting: verify no network calls made during fingerprint computation; fingerprint stored locally only in `.specrew/active-sessions.yml` [effort: 0.5 SP] [test: acceptance] [governance: security]

### Iteration 4 Validation & Documentation

- [ ] T093 Verify `specs/051-multi-session-foundation/contracts/multi-session-foundation.md` covers the shipped session-management, feature-claims, and auto-detection surfaces; reconcile any drift (contract authored at plan boundary) [effort: 0.5 SP] [governance: contracts]
- [ ] T094 Update `specs/051-multi-session-foundation/data-model.md` with BrandNewWorktreeSignal entity [effort: 0.5 SP] [governance: data-model]
- [ ] T095 Run all Iteration 4 acceptance tests and document results in test summary artifact [effort: 0.5 SP] [test: acceptance-suite]
- [ ] T096 Execute Specrew validator across all iterations and verify no regressions; confirm all acceptance scenarios pass [effort: 0.5 SP] [test: regression-check]
- [ ] T097 Create feature-level summary document: map all 101 tasks to FRs and user stories, verify 100% coverage [effort: 0.5 SP] [governance: traceability]

---

## Dependency Graph & Parallel Opportunities

### Critical Path (Sequential Dependencies)

```
Iteration 1 (Config + Classification)
  ↓
Iteration 2a (Collision Detection + Feature Claims)
  ↓
Iteration 2b (Conflict Reduction + Multi-Dev Auto-Detection)
  ├→ Iteration 3 (Spec-Kit Upgrade + Version Fix) [parallel]
  └→ Iteration 4 (Identity Split + Brand-New Detection) [depends on Iteration 2a/2b]
```

### Parallelization Opportunities

**Within Iteration 1**:

- T001-T003 (Setup & Schema) can run in parallel
- T004-T008 (Session Mode) can run in parallel after Setup
- T009-T015 (File Classification) can run in parallel after Setup

**Within Iteration 2a**:

- Session Management (T020-T026) and Feature Claims (T027-T033) are independent; can run in parallel

**Within Iteration 2b**:

- Conflict Reduction (T034-T041) and Auto-Detection (T042-T052) can run in parallel

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

### Iteration 2a Quality Gate

✓ Collision warning appears within 2 seconds (SC-002)  
✓ Feature claims recorded at specify boundary, refreshed at each lifecycle boundary (SC-008)  
✓ No regressions from Iteration 1  

### Iteration 2b Quality Gate

✓ Merge conflicts eliminated on `.squad/decisions.md` and `Specrew.psd1` (SC-006)  
✓ Multi-developer signals detected within one `specrew start` command (SC-003)  
✓ Recommendation surfaced within 0-2s when signals detected and mode is single (SC-007)  
✓ No regressions from Iteration 1/2a  

### Iteration 3 Quality Gate

✓ Spec-Kit upgrade completes in <2 minutes (SC-004)  
✓ All governance validators pass after upgrade  
✓ Version sync accuracy 100% (SC-005)  
✓ `--dry-run` flag shows changes without modifications  
✓ No regressions from Iteration 1/2a/2b  

### Iteration 4 Quality Gate

✓ Identity split removes session_state_* from tracked files  
✓ Per-session state remains gitignored  
✓ Brand-new worktree detection skips stale-state recovery on fresh worktrees  
✓ Recovery prompt preserved when state genuinely inconsistent  
✓ Machine fingerprinting remains local-only (no network calls)  
✓ All 101 tasks map to FRs (100% traceability)  

---

## Traceability Matrix: Tasks to Requirements

| Iteration | Task Range | User Stories | Functional Requirements | Success Criteria |
|-----------|-----------|--------------|----------------------|------------------|
| 1 | T001-T019 | US1, US2 | FR-001 to FR-006 | SC-001, SC-005 |
| 2a | T020-T033b | US3, US4 | FR-007 to FR-016 (+FR-043 pop.) | SC-002, SC-008 |
| 2b | T034-T055 | US5, US6 | FR-017 to FR-024 | SC-003, SC-006, SC-007 |
| 3 | T056-T076 | US7, US8 | FR-025 to FR-034 | SC-004, SC-005 |
| 4 | T077-T097 | US9, US10 | FR-035 to FR-043 | SC-001, SC-002 |

**Total Coverage**: 101 tasks × 43 functional requirements = 100% FR traceability; 101 tasks × 10 user stories = complete user story coverage

---

## Effort Verification & SP Allocation

This section provides explicit SP calculations for each iteration to enable reviewer verification against capacity envelopes. Numbers below are the **honest re-estimate (2026-05-31)** computed by summing the per-task `[effort]` markup — see [iterations/001/capacity-reestimate.md](iterations/001/capacity-reestimate.md). They supersede the earlier 18/18/14/12 = 62 SP figures, which were stale against the 48→97 task expansion (`3da2b23b`) and arithmetically incorrect (actual per-task markup then summed to 139 SP; the inflation has been corrected, not the cap raised).

| Iteration | Scope | Cap | Re-estimated SP | Tasks |
| --- | --- | --- | --- | --- |
| 1 | Session mode config + file classification (US1, US2) | ≤20 | 11.0 | 19 |
| 2a | Collision detection + feature claims (US3, US4) | ≤20 | 12.0 | 18 |
| 2b | Conflict reduction + multi-dev auto-detect (US5, US6) | ≤20 | 13.0 | 22 |
| 3 | Spec-Kit upgrade + version fix (US7, US8) | ≤20 | 13.5 | 21 |
| 4 | Identity split + brand-new worktree (US9, US10) | ≤20 | 13.0 | 21 |

**Feature-Level Total**: 101 tasks across 5 iterations = **62.5 SP** (within the approved 45-65 SP envelope; every iteration within the ≤20 SP cap per TG-005). Iteration 2a refined 10→12 SP at plan-time (planning workflow, 2026-05-31; +4 sub-tasks). Reviewers can re-verify by summing the per-task `[effort: N SP]` values within each iteration section.

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
4. ✅ Execute tasks in dependency order (Iteration 1 → 2a → 2b → 3 → 4)
5. ✅ Run acceptance scenario tests after each iteration
6. ✅ Execute feature-level drift check at completion (verify all FRs implemented, no scope creep)

---

**Generated**: 2026-05-31  
**Status**: Ready for before-implement hardening gate and implementation approval  
**Next Boundary**: Before-implement hardening gate, then implementation
