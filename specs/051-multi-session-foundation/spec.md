# Feature Specification: Multi-Session Foundation

**Feature Branch**: `051-multi-session-foundation`  
**Created**: 2026-05-30  
**Status**: Draft  
**Input**: User description: "F-051 Multi-Session Foundation. Carved from Proposals 010 + 134 with 4-iteration split (~45-65 SP total). Empirical motivation: F-051's own 2026-05-30 launch hit inherited-stale-state problem at `specrew start`, requiring manual A/B/C recovery on fresh worktree. Required scope: 1. session_mode config flag (single|multi), runtime-switchable via `specrew config set session_mode multi` 2. file classification + gitignore generation at init for per-session files (`.specrew/last-*`, `.specify/feature.json`) matching the F-049 `437338f6` git-rm-cached pattern 3. session-state collision detection via `.specrew/active-sessions.yml` lock file with warning on concurrent `specrew start` in the same project 4. `.squad/active-features.yml` claim model with Layer 1 same-feature warning; claim refresh occurs at multiple lifecycle points, not only PR merge 5. anti-conflict tactics: split `.squad/decisions.md` per iteration, use JSON Lines for append-only logs, alphabetical-sort `Specrew.psd1` FileList at boundary-sync 6. session-mode auto-detection signals (multiple git author emails, multiple machine fingerprints, multiple concurrent session-state writes, branch fan-out pattern) and recommendation surface at Welcome Orientation + `specrew where` dashboard + boundary-sync output 7. Spec-Kit upgrade investigation + execution: determine how Spec-Kit is installed on this machine, find a working upgrade mechanism, upgrade to 0.8.18, validate Specrew against it 8. `specrew update` baseline-bump bug fix so `.specrew/config.yml` `specrew_version` matches the installed module version 9. split .squad/identity/now.md to separate git-tracked shared content (focus_area, body) from per-session transient fields (session_state_active, session_state_boundary, session_state_feature_path, session_state_iteration, session_state_auth_commit, session_state_recorded_at) into new gitignored split file (.squad/identity/session-state.yml or session-state.json); 10. fresh-worktree detection at specrew start to skip stale-state A/B/C recovery prompt when state is empty and no in-flight feature artifacts exist, preserving prompt for genuinely inconsistent state"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure Multi-Session Mode (Priority: P1)

A Specrew project maintainer needs to enable multi-developer collaboration on their project when a second team member joins.

**Why this priority**: Foundation for all multi-developer functionality. Without this configuration capability, no other multi-session features can be used.

**Independent Test**: Can be fully tested by running `specrew config set session_mode multi` in a Specrew project and verifying the configuration persists in `.specrew/config.yml`.

**Acceptance Scenarios**:

1. **Given** a Specrew project in single-session mode, **When** developer runs `specrew config set session_mode multi`, **Then** the `.specrew/config.yml` file is updated with `session_mode: multi` and a success message is displayed
2. **Given** a project already in multi-session mode, **When** developer runs `specrew config set session_mode single`, **Then** the configuration reverts to single-session mode
3. **Given** a fresh Specrew init, **When** no session_mode is configured, **Then** the project defaults to single-session mode

---

### User Story 2 - Avoid Per-Session File Conflicts (Priority: P1)

Two developers working on different features simultaneously should not encounter git merge conflicts on ephemeral session-state files like `.specrew/last-start-prompt.md` or `.specify/feature.json`.

**Why this priority**: Eliminates the most common merge conflict pain point in multi-developer Specrew usage. Directly impacts developer experience on every multi-developer project.

**Independent Test**: Can be tested by having two developers (or two git worktrees) run concurrent `specrew start` sessions on different features, then attempting to merge their branches. No conflicts should occur on session-state files.

**Acceptance Scenarios**:

1. **Given** a multi-session-enabled project, **When** `specrew init` is run (or re-run), **Then** the `.gitignore` file is updated to exclude `.specrew/last-*`, `.specify/feature.json`, `.specrew/start-context.json`, `.specrew/host-history.json`, and other per-session files
2. **Given** two developers working on separate features, **When** both run `specrew start` and advance through lifecycle phases, **Then** their per-session files remain local and do not appear in `git status` for commit
3. **Given** existing tracked per-session files in git history, **When** file classification is applied, **Then** the files are removed from git index with `git rm --cached` and added to `.gitignore`

---

### User Story 3 - Detect Concurrent Session Collisions (Priority: P1)

When two developers accidentally work on the same feature simultaneously, they should receive a clear warning before state corruption occurs.

**Why this priority**: Prevents data loss and state corruption. Critical safety mechanism for multi-developer projects.

**Independent Test**: Can be tested by starting two `specrew start` sessions pointing to the same feature directory concurrently and verifying a collision warning is displayed in the second session.

**Acceptance Scenarios**:

1. **Given** Developer A has started `specrew start` for feature F-051 (session active), **When** Developer B starts `specrew start` for the same feature F-051 from a different machine or worktree, **Then** Developer B sees a warning: "Another active session detected for feature 051-multi-session-foundation (started by [user]@[machine] at [timestamp]). Concurrent work may cause conflicts."
2. **Given** a stale lock entry in `.specrew/active-sessions.yml` from a crashed session (timestamp > 24 hours old), **When** a new session starts, **Then** the stale lock is automatically cleared with a notice
3. **Given** a developer finishing their session normally, **When** they close the Specrew session, **Then** their entry in `.specrew/active-sessions.yml` is removed

---

### User Story 4 - Claim Features to Prevent Overlap (Priority: P2)

Developers should be able to claim features they are working on so the team can see who is working on what and avoid duplicate effort.

**Why this priority**: Improves team coordination and prevents wasted effort. Less critical than collision detection because it's advisory rather than protective.

**Independent Test**: Can be tested by running `specrew start` on a feature, verifying the claim is recorded in `.squad/active-features.yml`, and checking that another developer attempting to claim the same feature receives a warning.

**Acceptance Scenarios**:

1. **Given** Developer A starts work on feature F-051, **When** the specify boundary is crossed, **Then** an entry is added to `.squad/active-features.yml` recording the claim (feature ID, developer identity, machine fingerprint, start time, last refresh time)
2. **Given** Developer A has claimed feature F-051, **When** Developer B attempts to start the same feature, **Then** Developer B receives a warning: "Feature 051 is currently claimed by [user]@[machine] (last active [time ago]). Continue anyway?" — acceptance variants: (a) Developer B selects "Continue anyway" (y/Y/yes) and proceeds with their session, with both claims recorded in `.squad/active-features.yml` and a note logged in their session; (b) Developer B declines (n/N/no) and the `specrew start` command exits without creating a session
3. **Given** a feature claim exists, **When** lifecycle boundaries are crossed (specify, plan, tasks, implement, review, retro), **Then** the claim's last_refresh timestamp is updated
4. **Given** a feature is merged to main, **When** the feature-closeout boundary sync runs, **Then** the claim is removed from `.squad/active-features.yml`

---

### User Story 5 - Reduce Shared-File Merge Conflicts (Priority: P2)

When multiple developers work on different features simultaneously, they should experience minimal merge conflicts on shared governance files.

**Why this priority**: Reduces friction during multi-developer collaboration but doesn't prevent work from proceeding. Developers can manually resolve conflicts if needed.

**Independent Test**: Can be tested by having two developers modify different features that both touch shared files (like decisions.md), then merging their branches and verifying conflicts are minimized or have structured resolution paths.

**Acceptance Scenarios**:

1. **Given** two developers working on separate features that both record decisions, **When** they both update `.squad/decisions.md`, **Then** the decisions are split into per-iteration files under `.squad/decisions/iteration-NNN/decisions.md`, reducing merge conflicts to iteration-specific files
2. **Given** multiple developers recording lifecycle events, **When** appending entries to shared logs, **Then** logs use JSON Lines format (one JSON object per line) with atomic append operations, making merge conflicts rare and mechanically resolvable when they occur
3. **Given** two features both updating the Specrew.psd1 FileList at boundary sync, **When** both branches are ready to merge, **Then** the FileList entries are automatically sorted alphabetically, reducing conflicts to true duplicates rather than ordering differences

---

### User Story 6 - Detect Multi-Developer Activity Automatically (Priority: P2)

A project should automatically detect when it has shifted from single-developer to multi-developer usage and recommend enabling multi-session mode.

**Why this priority**: Helps teams discover the feature when they need it, without requiring them to read documentation first.

**Independent Test**: Can be tested by simulating multi-developer signals (different git author emails, different machine IDs in session state) and verifying the recommendation appears in relevant surfaces.

**Acceptance Scenarios**:

1. **Given** a project with commits from multiple git author emails (e.g., <alice@example.com>, <bob@example.com>), **When** `specrew start` runs, **Then** a recommendation message is shown: "Multiple developers detected (2 unique authors in recent history). Consider enabling multi-session mode: `specrew config set session_mode multi`"
2. **Given** session-state writes from different machine fingerprints, **When** `specrew where` dashboard is displayed, **Then** a multi-developer indicator is shown with the count of unique machines and a recommendation to enable multi-session mode
3. **Given** git branch history showing multiple concurrent feature branches (fan-out pattern), **When** boundary-sync runs, **Then** output includes a note about multi-developer activity detected
4. **Given** a project already in multi-session mode, **When** these signals are present, **Then** no redundant recommendation is shown (recommendation is suppressed)

---

### User Story 7 - Upgrade Spec-Kit to 0.8.18 (Priority: P1)

The Specrew project maintainer needs to upgrade the project's Spec-Kit version from 0.8.13 to 0.8.18 to support new capabilities and ensure compatibility.

**Why this priority**: Required infrastructure upgrade that unblocks the rest of F-051. Spec-Kit 0.8.18 includes fixes and features needed by multi-session foundation.

**Independent Test**: Can be tested by running the upgrade command and verifying that `.specrew/config.yml` reflects `speckit_version: 0.8.18` and Specrew still functions correctly.

**Acceptance Scenarios**:

1. **Given** a Specrew project with `speckit_version: 0.8.13`, **When** the upgrade command is invoked, **Then** the system detects how Spec-Kit is installed (npm package, deployed extension directory, or other), identifies the correct upgrade mechanism, performs the upgrade, and updates `.specrew/config.yml`
2. **Given** Spec-Kit is installed via deployed extension (likely scenario for this repo), **When** the upgrade runs, **Then** the extension files under `.specify/extensions/specrew-speckit/` are updated to version 0.8.18 while preserving any local configuration or customization
3. **Given** the upgrade completes, **When** Specrew validator runs, **Then** no version compatibility warnings appear and the project passes validation

---

### User Story 8 - Fix Baseline Version Bump (Priority: P1)

When a developer runs `specrew update` to refresh the project's Specrew baseline, the `.specrew/config.yml` file should accurately reflect the installed module version.

**Why this priority**: Fixes a known bug that causes version mismatch confusion. Essential for accurate project metadata and tooling version reconciliation.

**Independent Test**: Can be tested by installing a specific Specrew version (e.g., 0.29.0), running `specrew update`, and verifying `.specrew/config.yml` shows `specrew_version: 0.29.0`.

**Acceptance Scenarios**:

1. **Given** Specrew module version 0.29.0 is installed, **When** `specrew update` is run, **Then** `.specrew/config.yml` is updated with `specrew_version: "0.29.0"` (exactly matching the installed version)
2. **Given** a version mismatch between installed Specrew (0.29.0) and config file (0.28.0), **When** `specrew start` runs, **Then** a warning is displayed: "Installed Specrew 0.29.0 differs from project pin 0.28.0. Run `specrew update` to sync or install the pinned version."
3. **Given** `specrew update` is run with `--dry-run` flag, **When** the command executes, **Then** the proposed version change is shown without modifying files

---

### User Story 9 - Split Session-State Transient Fields from Shared Identity (Priority: P1)

Developers launching new worktrees on feature branches must not inherit stale `session_state_*` fields from `.squad/identity/now.md`, which trigger unnecessary recovery prompts at `specrew start` on brand-new branches where no prior work exists.

**Why this priority**: Eliminates noise and friction during brand-new feature launches in multi-session environments. F-051's own 2026-05-30 launch experienced this problem: the inherited feature path from the previous feature (F-050) triggered stale-state recovery on a fresh branch. Decoupling shared identity from per-session state prevents this coupling.

**Independent Test**: Can be tested by (1) running `specrew start` on a fresh feature branch in a new worktree cloned from main, (2) verifying the session starts without prompting for stale-state recovery, and (3) confirming `.squad/identity/now.md` contains only shared content (focus_area, body) while per-session state resides in the new gitignored file.

**Acceptance Scenarios**:

1. **Given** `.squad/identity/now.md` in main branch with BOTH shared content (focus_area, body) AND per-session fields (session_state_active, session_state_boundary, session_state_feature_path, session_state_iteration, session_state_auth_commit, session_state_recorded_at), **When** migration runs, **Then** the per-session fields are stripped from now.md, now.md is updated and committed, and a new file `.squad/identity/session-state.yml` (or `.json`) is created with only the per-session fields and added to `.gitignore`
2. **Given** a fresh worktree with `.squad/identity/now.md` inherited from main (containing old session_state fields but no actual in-flight features), **When** `specrew start` is invoked on a brand-new feature branch, **Then** the stale-state recovery prompt (A/B/C) is SKIPPED; the feature launch proceeds directly to new-feature specify flow
3. **Given** the new split-file structure is in place, **When** a developer runs `specrew start` within an existing worktree with genuinely inconsistent state (e.g., feature_path points to a feature that doesn't match the current branch), **Then** the stale-state recovery prompt is SHOWN as before, preserving recovery behavior for true conflicts
4. **Given** a `.gitignore` entry for `.squad/identity/session-state.*`, **When** multiple developers work on different features, **Then** per-session state files remain local and do not create merge conflicts

---

### User Story 10 - Detect Brand-New Worktrees to Skip Stale-State Recovery (Priority: P1)

A developer cloning a fresh worktree to launch a new feature should go directly to feature-setup without navigating stale-state recovery logic, even if `.squad/identity/now.md` (or the new session-state file) contains inherited session references.

**Why this priority**: Reduces friction during parallel-development ramp-up. Enables fast new-feature launches while preserving safety for genuinely inconsistent state. Direct blocker for pleasant multi-session UX.

**Independent Test**: Can be tested by (1) launching a fresh worktree on main, (2) running `specrew start --feature F-999-test-feature`, (3) verifying no stale-state prompt appears, and (4) checking that the new-feature flow (config → init → specify boundary entry) runs cleanly.

**Acceptance Scenarios**:

1. **Given** a brand-new worktree (empty or minimal `.specrew/` and `.squad/` directories), **When** `specrew start --feature <NEW>` is invoked, **Then** the system detects brand-new condition (empty `.specrew/active-sessions.yml`, no iteration directories matching inherited feature_path, no boundary commits on this branch), skips the A/B/C stale-state prompt, and enters new-feature specify flow directly
2. **Given** inherited session_state pointing to feature F-050 but the worktree has never seen a commit on any feature branch, **When** `specrew start --feature F-051-new` is invoked, **Then** the inherited state is recognized as orphaned; brand-new detection SKIPS the recovery prompt
3. **Given** the worktree DOES have prior feature state (e.g., iteration directories for the inherited feature), **When** session_state points to a different feature or boundary, **Then** this is flagged as genuine inconsistency; the A/B/C recovery prompt is SHOWN to resolve the mismatch
4. **Given** a developer finishes a feature and the feature-closeout boundary runs, **When** the session-state file is reset to empty, **Then** the next `specrew start` on a new feature is treated as brand-new again (no stale-state recovery prompt)

---

### Edge Cases

- What happens when `.specrew/active-sessions.yml` is corrupted or contains invalid YAML? System should log a warning, treat the file as empty, and recreate it with the current session entry.
- What happens when a developer force-stops their session (Ctrl+C, machine crash) without cleanup? The active-sessions lock becomes stale. After 24 hours, the stale lock is auto-cleared. Before 24 hours, a warning is shown but work can continue. Rationale for 24-hour threshold: balances safety (preserving multi-day feature branches) against clearing obviously-dead sessions.
- What happens when two developers claim the same feature at the exact same millisecond? The `.squad/active-features.yml` update should be atomic (write-temp-rename pattern). If a true race occurs, both claims are recorded and the next refresh detects the conflict and surfaces it.
- What happens when `.gitignore` already contains some per-session file patterns but not all? The file classification logic should merge new patterns without duplicating existing ones, preserving comments and structure.
- What happens when a developer manually edits `.squad/active-features.yml` and removes their claim? The next boundary refresh detects the claim is missing and re-adds it if the session is still active. If the session has ended, no action is taken.
- What happens when upgrading Spec-Kit fails due to network issues or permission errors? The upgrade command should provide a clear error message with troubleshooting guidance (check network, check file permissions, try manual install) and leave the system in the previous working state. Edge handling strengthened per soft-gap guidance: logs at each step, validates checksums pre/post upgrade, provides rollback instructions.
- What happens when `specrew update` is run in a dirty working directory with uncommitted changes? The command should warn that uncommitted changes exist and recommend committing or stashing before updating. Optionally allow `--force` to proceed anyway.
- What happens when detecting multi-developer activity in a repo that's actually a single developer with multiple email addresses or machines? The recommendation is advisory, not mandatory. The developer can ignore it or configure multi-session mode to suppress the recommendation.
- What happens when `.squad/identity/now.md` is corrupted or missing on a brand-new worktree? The system treats it as an empty/fresh state and does not attempt recovery. A new session-state file is initialized as needed.
- What happens when `.squad/identity/session-state.yml` (the new split file) is missing or has stale data? On brand-new detection, the session-state file is treated as empty. On re-entry to an existing worktree, the file is validated; if corrupt, it is reset and a warning is logged.
- What happens when a developer has two parallel worktrees with different feature branches but the same inherited session_state from main? The brand-new-detection logic runs independently per worktree (checking for local iteration directories and boundary commits on the current branch). Each worktree is evaluated separately, so both can start fresh features without conflict.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a `session_mode` configuration flag in `.specrew/config.yml` with two valid values: `single` and `multi`
- **FR-002**: System MUST provide a CLI command `specrew config set session_mode <value>` that updates `.specrew/config.yml` and validates the value is either `single` or `multi`
- **FR-003**: System MUST default to `single` session mode when no explicit `session_mode` is configured
- **FR-004**: System MUST classify Specrew-managed files into four categories: shared (must be committed and identical across developers), per-session (must be gitignored), append-only-shared (committed with atomic append discipline), and regenerable (generated from shared sources)
- **FR-005**: System MUST generate or update `.gitignore` during `specrew init` or when file classification changes to exclude per-session files: `.specrew/last-*`, `.specify/feature.json`, `.specrew/start-context.json`, `.specrew/host-history.json`, `.specrew/.cache/`, `.squad/sessions/`, `.squad/decisions/inbox/`, `.specrew/last-validator-summary.json`
- **FR-006**: System MUST remove previously tracked per-session files from git index using `git rm --cached` when file classification is applied
- **FR-007**: System MUST maintain a `.specrew/active-sessions.yml` file containing active session entries with fields: feature_id, user, machine_fingerprint, session_start_time, last_heartbeat_time
- **FR-008**: System MUST add an entry to `.specrew/active-sessions.yml` when a `specrew start` session begins
- **FR-009**: System MUST remove an entry from `.specrew/active-sessions.yml` when a session ends normally
- **FR-010**: System MUST detect when starting a session for a feature that already has an active entry in `.specrew/active-sessions.yml` and display a warning to the developer
- **FR-011**: System MUST automatically clear stale lock entries (last_heartbeat_time older than 24 hours) from `.specrew/active-sessions.yml` when a new session starts. Rationale: 24-hour threshold balances safety (preserving multi-day feature branches and developer breaks) against clearing obviously-dead sessions and unblocking worktrees. Configurable via `.specrew/config.yml` `stale_lock_threshold_hours` if needed (optional, defaults to 24).
- **FR-012**: System MUST maintain a `.squad/active-features.yml` file containing feature claims with fields: feature_id, claimed_by (user@machine), claim_start_time, last_refresh_time, branch_name
- **FR-013**: System MUST add a claim entry to `.squad/active-features.yml` when a developer crosses the specify boundary for a feature
- **FR-014**: System MUST update the `last_refresh_time` in the feature claim when lifecycle boundaries are crossed (specify, plan, tasks, implement, review, retro)
- **FR-015**: System MUST detect when a developer attempts to claim a feature that is already claimed by another developer and display a Layer 1 warning with claim details and option to continue
- **FR-016**: System MUST remove a claim from `.squad/active-features.yml` when the feature-closeout boundary sync runs and the feature is merged to main
- **FR-017**: System MUST split `.squad/decisions.md` into per-iteration files under `.squad/decisions/iteration-NNN/decisions.md` when in multi-session mode
- **FR-018**: System MUST use JSON Lines format (one JSON object per line) for append-only log files to enable atomic appends and mechanical conflict resolution
- **FR-019**: System MUST alphabetically sort the `Specrew.psd1` FileList array during boundary-sync writes to minimize merge conflicts
- **FR-020**: System MUST detect multi-developer activity signals: multiple git author emails in recent history (last 90 days), multiple machine fingerprints in session state writes, multiple concurrent session-state file writes, branch fan-out pattern (3+ feature branches diverging from same base)
- **FR-021**: System MUST display a multi-session recommendation message during Welcome Orientation when multi-developer signals are detected and session_mode is `single`
- **FR-022**: System MUST display a multi-developer indicator in the `specrew where` dashboard when signals are detected, including count of unique developers and machines
- **FR-023**: System MUST include multi-developer activity note in boundary-sync output when signals are detected
- **FR-024**: System MUST suppress multi-session recommendations when `session_mode` is already set to `multi`
- **FR-025**: System MUST provide a command or automated process to upgrade the project's Spec-Kit installation from version 0.8.13 to 0.8.18
- **FR-026**: System MUST detect how Spec-Kit is installed in the current project (npm package, deployed extension directory, manual files)
- **FR-027**: System MUST identify the appropriate upgrade mechanism based on the installation method detected
- **FR-028**: System MUST execute the upgrade while preserving local configuration and customization in `.specify/` directories
- **FR-029**: System MUST update `.specrew/config.yml` `speckit_version` field to `"0.8.18"` after successful upgrade
- **FR-030**: System MUST validate that Specrew functions correctly with Spec-Kit 0.8.18 after upgrade by running the governance validator
- **FR-031**: System MUST fix the `specrew update` command to write the installed Specrew module version to `.specrew/config.yml` `specrew_version` field
- **FR-032**: System MUST detect the installed Specrew module version from PowerShell module metadata (Get-Module or Get-InstalledModule)
- **FR-033**: System MUST display a drift warning during `specrew start` when installed Specrew version differs from `.specrew/config.yml` `specrew_version`
- **FR-034**: System MUST support a `--dry-run` flag for `specrew update` that shows proposed changes without modifying files
- **FR-035**: System MUST split `.squad/identity/now.md` to separate git-tracked shared content (focus_area, body) from per-session transient fields (session_state_active, session_state_boundary, session_state_feature_path, session_state_iteration, session_state_auth_commit, session_state_recorded_at)
- **FR-036**: System MUST create a new gitignored split file (`.squad/identity/session-state.yml` or `.squad/identity/session-state.json`) to hold per-session transient fields, with an entry in `.gitignore` for the new file pattern
- **FR-037**: System MUST include migration logic that strips existing session_state_* fields from `.squad/identity/now.md` and writes them to the new split file, then commits the change to now.md
- **FR-038**: System MUST validate at specrew start that the split between shared and per-session content is enforced; git-tracked files MUST NOT contain session_state_* fields (detector: grep for `session_state_` in tracked files and error if any are found). The gitignored session-state file may contain these fields.
- **FR-039**: System MUST detect brand-new worktree condition at `specrew start` using these heuristic signals: empty `.specrew/active-sessions.yml` (or missing file), no recent boundary commits on the current feature branch, and no iteration directories matching the inherited feature_path under `specs/<feature>/iterations/`
- **FR-040**: System MUST skip the stale-state recovery A/B/C prompt when brand-new condition is detected and proceed directly to new-feature specify flow
- **FR-041**: System MUST preserve the A/B/C recovery prompt when state is genuinely inconsistent (e.g., feature_path on inherited state does not match current branch AND iteration directories exist for that path), detecting this condition by comparing inherited feature_path with current branch name and checking for local iteration evidence
- **FR-042**: System MUST log all brand-new detection signals and decisions to `.specrew/session-start.log` for debugging purposes, including timestamp, detected signals, and decision rationale (brand-new vs. recovery needed)
- **FR-043**: Machine fingerprinting for session state MUST be local-only and MUST NOT be transmitted over the network; fingerprints are used only for in-project collision detection and multi-developer signal aggregation

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements
- **TG-002**: Each requirement MUST identify expected owner role(s): Implementer (FR-001 through FR-043), Reviewer (validation of multi-session mode, file classification, collision detection, upgrade process, split identity files, brand-new worktree detection)
- **TG-003**: Each requirement MUST identify intended iteration or delivery window:
  - Iteration 1 (up to 20 SP): FR-001 to FR-006 (session mode config + file classification) — preserves P1 foundation scope
  - Iteration 2 (12-18 SP): FR-007 to FR-024 (collision detection + feature claims + auto-detection) — preserves session coordination scope
  - Iteration 3 (10-15 SP): FR-025 to FR-034 (Spec-Kit upgrade + specrew update fix) — preserves infrastructure scope
  - Iteration 4 (8-12 SP): FR-035 to FR-043 (identity split + brand-new worktree detection + privacy) — NEW: addresses stale-state recovery and UX friction
  - Total: ~45-65 SP across 4 iterations; Iteration 1 capacity capped at 20 SP per TG-005 to enable fast validation; subsequent iterations sized accordingly
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path. No known conflicts exist at specification time.
- **TG-005**: Iteration 1 MUST remain at or under 20 SP to allow fast foundation validation and unblock parallel work (Iteration 1 acts as dependency gate for Iterations 2-4)

### Key Entities *(include if feature involves data)*

- **SessionLockEntry**: Represents an active Specrew session in `.specrew/active-sessions.yml`
  - Attributes: feature_id (string), user (string), machine_fingerprint (string), session_start_time (ISO 8601 timestamp), last_heartbeat_time (ISO 8601 timestamp)
  - Lifecycle: Created when session starts, updated periodically (heartbeat), removed when session ends or after 24 hours of staleness
  - Relationships: One entry per active session per feature; multiple entries can exist for different features

- **FeatureClaimEntry**: Represents a developer's claim on a feature in `.squad/active-features.yml`
  - Attributes: feature_id (string), claimed_by (string in format "user@machine"), claim_start_time (ISO 8601 timestamp), last_refresh_time (ISO 8601 timestamp), branch_name (string)
  - Lifecycle: Created at specify boundary, refreshed at each subsequent boundary, removed at feature-closeout
  - Relationships: One claim per feature; concurrent claims on same feature trigger warnings

- **MultiDevSignal**: Represents detected evidence of multi-developer activity
  - Attributes: signal_type (enum: git_authors | machine_fingerprints | concurrent_writes | branch_fanout), detected_at (timestamp), evidence_count (integer), evidence_details (string)
  - Lifecycle: Detected at runtime during `specrew start`, `specrew where`, or boundary-sync; not persisted, computed on-demand
  - Relationships: Multiple signals can be present; used to trigger recommendation logic

- **FileClassificationRule**: Represents the categorization of a Specrew-managed file path pattern
  - Attributes: pattern (glob string), category (enum: shared | per-session | append-only-shared | regenerable), reason (string)
  - Lifecycle: Defined statically in Specrew configuration; applied during `specrew init` or when classification changes
  - Relationships: Many rules define the complete classification scheme; rules are applied to generate `.gitignore` entries

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Two developers working on different features can complete a full specify-plan-tasks-implement-review lifecycle cycle concurrently without encountering merge conflicts on per-session files (success rate: 100% in test scenarios)
- **SC-002**: When two developers start work on the same feature within 5 minutes of each other, the second developer receives a collision warning within 2 seconds of starting their session
- **SC-003**: Multi-developer activity detection identifies projects with 2+ developers within one `specrew start` command after the second developer commits (detection accuracy: 100% for defined signal types)
- **SC-004**: Spec-Kit upgrade from 0.8.13 to 0.8.18 completes successfully in under 2 minutes with all governance validators passing afterward (success rate: 100% in supported installation scenarios)
- **SC-005**: `specrew update` command accurately reflects the installed Specrew module version in `.specrew/config.yml` with zero version mismatches after running the command (accuracy: 100%)
- **SC-006**: Merge conflicts on shared governance files (`.squad/decisions.md`, `Specrew.psd1` FileList) are eliminated or mechanically resolved when anti-conflict tactics (per-iteration split, JSON Lines, alphabetical sort) are applied. Measured by: (a) zero conflict markers remain after applying auto-sort to FileList and per-iteration split to decisions; (b) JSON Lines log merges produce no ambiguous duplicate entries; (c) all merge commits on files changed by tactics show clean merges or single-line resolutions. Success: 100% of concurrent feature-work merge attempts on these files complete without manual conflict resolution.
- **SC-007**: Developers receive a recommendation to enable multi-session mode within one command execution after multi-developer signals are first detected (recommendation latency: 0-2 seconds)
- **SC-008**: Feature claims are accurately maintained across lifecycle boundaries with `last_refresh_time` updated at each boundary (100% update rate at specify, plan, tasks, implement, review, retro boundaries)

## Assumptions

- Target users are developers working in Specrew-governed projects who have basic familiarity with git workflows and PowerShell commands
- Multi-session mode is opt-in; single-session remains the default and continues to work without changes
- Developers have appropriate file system permissions to modify `.specrew/`, `.specify/`, and `.squad/` directories and their contents
- Git is available and configured in the project environment (required for detecting git author emails and branch patterns)
- Machine fingerprinting can be achieved through a combination of hostname, username, and/or system-specific identifiers available in PowerShell
- Spec-Kit installation for this project is via deployed extension directory under `.specify/extensions/specrew-speckit/` (the standard Specrew bootstrap pattern)
- Atomic file writes can be achieved through PowerShell write-temp-rename pattern (write to `.tmp` file, then `Move-Item -Force`)
- Stale session locks are defined as locks with `last_heartbeat_time` older than 24 hours
- The F-049 commit `437338f6` git-rm-cached pattern refers to the process of removing tracked files from git index without deleting them from the working directory
- Proposals 010 and 134 are design references that define the full scope of multi-developer reconciliation; F-051 implements a minimal "Phase 1" subset
- Iteration slicing is 4 iterations based on the 45-65 SP estimate, with each iteration focused on a coherent subsystem: Iteration 1 (config + file classification), Iteration 2 (collision detection + claims + auto-detection), Iteration 3 (upgrade + bug fix), Iteration 4 (identity split + brand-new worktree detection)

## Governance Alignment *(mandatory)*

- **Spec Steward**: Specrew Spec Steward agent (accountable for specification integrity and drift detection between this spec, plan, tasks, and implementation)
- **Iteration Facilitator**: Specrew Planner agent (accountable for iteration cadence, capacity planning, and blocker escalation)
- **Capacity Model**: Story Points (SP); estimated 45-65 SP total across 4 iterations (Iteration 1: up to 20 SP, Iteration 2: 12-18 SP, Iteration 3: 10-15 SP, Iteration 4: 8-12 SP). Iteration 1 is capped at 20 SP per TG-005 to enable fast foundation validation and unblock parallel work. Single developer delivery model.
- **Drift Signals**:
  - Semantic drift: Detected by comparing implemented collision detection logic against FR-007 through FR-016 (active-sessions + feature claims) and identity split logic against FR-035 through FR-043
  - Scope drift: Detected if implementation adds multi-developer features not scoped in FR-001 through FR-043 (such as cross-project coordination, network-based locking, real-time collaborative editing, or file-surface overlap detection per Proposal 148 Layer 2)
  - Test coverage drift: Detected if acceptance scenarios for P1 user stories (US1-US10) lack corresponding test cases or evidence
  - Quality drift: Detected if concurrent session scenarios are not validated under race conditions (two developers starting sessions within milliseconds) and brand-new worktree detection is not tested with various inherited-state combinations
- **Human Oversight Points**:
  - Specify boundary: Human review of this spec for completeness and alignment with Proposals 010/134 intent
  - Before-implement boundary: Human approval required after hardening gate review (security review of file write operations, race condition analysis, validation of atomic write patterns, identity split validation)
  - Review boundary: Human verification of multi-session mode behavior through manual testing (two developers, two machines or worktrees, concurrent feature work) and brand-new worktree detection testing
  - Feature-closeout boundary: Human approval before merge to main, including validation that Spec-Kit 0.8.18 is functional, `specrew update` fix is verified, and identity split is durably enforced

## Scope Boundaries *(mandatory)*

**OUT OF SCOPE (Proposal 148 Layers 2+3):**

F-051 implements ONLY Layer 1 of multi-developer coordination (same-feature claim + warning). The following related features are explicitly out of scope and tracked in Proposal 148:

- **Layer 2** (File-Surface Overlap Warning): Comparison of plan `Owner File Globs` to active branches' git-diff surfaces to warn of file-level collision risk at `specrew start` for new features. This feature requires plan infrastructure that F-051 does not establish.
- **Layer 3** (Predictive Feature-Pair Selection): Ranking of candidate features by collision likelihood and recommending safest pairs for concurrent work. This feature depends on Layer 2 and advanced feature metadata not in F-051 scope.

Proposal 148 is a candidate for F-054+, after F-051 establishes the foundation and F-052/F-053 ship.

**Empirical Motivation:**

F-051's own 2026-05-30 launch experienced the inherited-stale-state problem that items 9 and 10 address. When the new feature branch was cloned to a fresh worktree with inherited `.squad/identity/now.md` from main (containing old session_state from F-050), `specrew start` triggered the stale-state A/B/C recovery prompt even though the fresh branch had no prior work. This noise would amplify with more concurrent sessions. Items 9 and 10 eliminate this friction and make the specify boundary UX pleasant for parallel-development ramp-up.
