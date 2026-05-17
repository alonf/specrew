# Data Model: Session-State Durability & In-Flight Progress Tracking

**Feature**: 020-session-state-durability  
**Date**: 2026-05-19  
**Purpose**: Define entities, attributes, relationships, and validation rules for session-state tracking

---

## Entity: Session-State Record

**Purpose**: Represents the current lifecycle position for a Specrew project. Stored across multiple files for Squad/Copilot integration.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --------- | ---- | -------- | --------------- | ----------- |
| `active_feature` | String (feature number) | Yes | Pattern: `^\d{3}$` (e.g., "020") | Feature currently in progress; empty if no active feature |
| `current_boundary` | Enum | Yes | One of: `specify`, `clarify`, `plan`, `tasks`, `review-signoff`, `iteration-closeout`, `feature-closeout`, `no-active-feature` | Current lifecycle boundary |
| `iteration_number` | Integer | No | Range: 1-99 | Current iteration; null if not in implementation |
| `task_id` | String | No | Pattern: `^T\d{3}$` (e.g., "T005") | Current in-progress task; null if not at task level |
| `last_completed_boundary` | String | No | Free text | Description of last completed boundary (e.g., "planning complete") |
| `last_completed_commit_hash` | String (git SHA) | No | Pattern: `^[0-9a-f]{7,40}$` | Git commit hash of last boundary event |
| `recorded_at` | Timestamp | Yes | ISO 8601 format | When this state was recorded |
| `worktree_path` | String (absolute path) | Yes | Valid filesystem path | Worktree where this feature is active |
| `next_roadmap_item` | String | No | Free text | Informational: next roadmap item after closeout |

### Storage Locations

Session-State Record is **denormalized** across four files for maximum compatibility with Squad and Spec Kit:

1. **`.specrew/last-start-prompt.md`**: Human-readable prompt text including feature name, boundary, next steps
2. **`.specrew/start-context.json`**: Machine-readable JSON with `active_feature`, `current_boundary`, `recorded_at`
3. **`.squad/identity/now.md`**: Squad-specific "current focus" text including feature and boundary
4. **`.squad/decisions.md`**: Decision log with boundary-event entries including commit hashes and timestamps

**Consistency Rule**: All four files MUST reference the same `active_feature` and `current_boundary`. Stale-state detection enforces this at `specrew start`.

### State Transitions

```text
[no-active-feature] 
  -> specify (feature activation via speckit.specify)
  -> clarify (clarify command completes)
  -> plan (speckit.plan completes)
  -> tasks (speckit.tasks completes)
  -> review-signoff (review/demo ceremony completes)
  -> iteration-closeout (iteration closeout commits)
  -> [loop back to plan if more iterations, else proceed to feature-closeout]
  -> feature-closeout (feature merge to main)
  -> [no-active-feature]
```

### Validation Rules

- **VR-001**: If `current_boundary` is `iteration-closeout`, `iteration_number` MUST be present
- **VR-002**: If `current_boundary` is `no-active-feature`, `active_feature` MUST be empty
- **VR-003**: `recorded_at` timestamp MUST be within last 30 days (stale-state signal if older)
- **VR-004**: If `task_id` is present, `current_boundary` MUST be `tasks` (task tracking only during implementation)

---

## Entity: Task Progress Entry

**Purpose**: Represents execution state for a single task within an iteration. Enables mid-iteration progress tracking and post-reboot recovery.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --------- | ---- | -------- | --------------- | ----------- |
| `task_id` | String | Yes | Pattern: `^T\d{3}$`; unique within `tasks-progress.yml` | Stable task identifier (e.g., "T005") |
| `status` | Enum | Yes | One of: `pending`, `in-progress`, `complete`, `blocked` | Current task status |
| `started_at` | Timestamp | Conditional | ISO 8601; required if status is `in-progress` or `complete` or `blocked` | When task transitioned to `in-progress` |
| `completed_at` | Timestamp | Conditional | ISO 8601; required if status is `complete` | When task transitioned to `complete` |
| `blocked_reason` | String | Conditional | Required if status is `blocked`; max 500 chars | Why task is blocked |
| `assigned_to` | String | No | Role name (e.g., "Implementer") | Owner role from `tasks.md` |

### Storage Location

**File**: `specs/<feature>/iterations/<NNN>/tasks-progress.yml` (sibling to `tasks.md`)

**Format**: YAML array of task progress entries

**Example**:
```yaml
- task_id: "T001"
  status: "complete"
  started_at: "2026-05-19T10:00:00Z"
  completed_at: "2026-05-19T11:30:00Z"
  assigned_to: "Implementer"

- task_id: "T002"
  status: "in-progress"
  started_at: "2026-05-19T11:35:00Z"
  assigned_to: "Implementer"

- task_id: "T003"
  status: "pending"
  assigned_to: "Reviewer"
```

### State Transitions

```text
pending -> in-progress (started_at recorded)
in-progress -> complete (completed_at recorded)
in-progress -> blocked (blocked_reason required)
blocked -> in-progress (blocked_reason cleared)
```

**Immutability Rule**: Once `status` is `complete`, task MUST NOT transition back to `in-progress` or `pending` (progress is forward-only).

### Validation Rules

- **VR-005**: `task_id` MUST exist in sibling `tasks.md` file (task progress references valid task)
- **VR-006**: If `status` is `complete`, `started_at` and `completed_at` MUST both be present
- **VR-007**: `completed_at` MUST be after `started_at` (temporal consistency)
- **VR-008**: If `status` is `blocked`, `blocked_reason` MUST be non-empty
- **VR-009**: Task IDs MUST remain stable across `tasks.md` regenerations (if `tasks.md` is regenerated with different IDs, `tasks-progress.yml` becomes orphaned and requires manual reconciliation)

---

## Entity: Worktree State

**Purpose**: Represents feature lifecycle in a specific git worktree. Derived at runtime from `git worktree list` and `.specify/feature.json`; no persistent storage.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --------- | ---- | -------- | --------------- | ----------- |
| `worktree_path` | String (absolute path) | Yes | Valid filesystem path from `git worktree list` | Absolute path to worktree |
| `worktree_exists` | Boolean | Yes | Derived: `true` if path exists on disk, `false` if git-worktree-list shows it but path missing | Whether worktree directory is accessible |
| `active_feature` | String (feature number) | No | Pattern: `^\d{3}$` or empty | Active feature in this worktree; empty if no active feature |
| `current_boundary` | String | No | Free text | Current boundary from worktree's `.specrew/start-context.json` |
| `last_activity_timestamp` | Timestamp | No | ISO 8601 | Most recent `recorded_at` timestamp from worktree's session-state files |
| `git_branch` | String | Yes | Git branch name from `git worktree list` | Current git branch for this worktree |

### Derivation Logic

1. Run `git worktree list --porcelain` from repository root
2. For each worktree path in output:
   - Check if path exists on disk → set `worktree_exists`
   - Read `<worktree>/.specify/feature.json` → extract `feature_directory` field → derive `active_feature` (feature number from path)
   - Read `<worktree>/.specrew/start-context.json` → extract `current_boundary`
   - Read `<worktree>/.specrew/start-context.json` → extract `recorded_at` → set `last_activity_timestamp`
   - Extract branch name from `git worktree list` output → set `git_branch`

### Performance Requirements

- **PR-001**: Derivation MUST complete within 2 seconds for up to 10 worktrees
- **PR-002**: Derivation MUST handle missing `.specify/feature.json` gracefully (worktree with no active feature)
- **PR-003**: Derivation MUST handle inaccessible worktree paths gracefully (annotate as "(path not found)")

### Validation Rules

- **VR-010**: If `worktree_exists` is `false`, `specrew where --worktrees` MUST annotate with "(path not found)" and suggest `git worktree prune`
- **VR-011**: If `.specify/feature.json` is missing or `feature_directory` is empty, `active_feature` MUST be empty (valid state: worktree exists but has no active feature)

---

## Entity: Version Check Cache

**Purpose**: Caches PSGallery latest-version query result to minimize network calls. Shared across `specrew start`, `specrew init`, `specrew update`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --------- | ---- | -------- | --------------- | ----------- |
| `latest_version` | String (semver) | Yes | Pattern: `^\d+\.\d+\.\d+$` (e.g., "0.8.0") | Latest Specrew version available on PSGallery |
| `checked_at` | Timestamp | Yes | ISO 8601 | When PSGallery was last queried |
| `cache_valid_until` | Timestamp | Yes | ISO 8601; `checked_at + 24 hours` | When cache expires |

### Storage Location

**File**: `.specrew/version-check-cache.json`

**Format**: JSON object

**Example**:
```json
{
  "latest_version": "0.8.0",
  "checked_at": "2026-05-19T10:00:00Z",
  "cache_valid_until": "2026-05-20T10:00:00Z"
}
```

### Cache Lifecycle

1. **Cache Miss**: If file doesn't exist or `cache_valid_until` is in the past, query PSGallery
2. **Cache Hit**: If `cache_valid_until` is in the future, use cached `latest_version` (no network call)
3. **Cache Write**: After successful PSGallery query, write `latest_version`, `checked_at`, `cache_valid_until` to file

### Validation Rules

- **VR-012**: `cache_valid_until` MUST equal `checked_at + 24 hours` (24-hour cache policy)
- **VR-013**: If cache file is corrupted (invalid JSON, missing fields), treat as cache miss and re-query PSGallery
- **VR-014**: If PSGallery query fails (network error, timeout), delete cache file and fail silently (no stale cache data)

---

## Relationships

```text
Session-State Record (1) <----references----> (0..1) Task Progress Entry
  (via task_id attribute in Session-State Record)

Worktree State (1) <----contains----> (0..1) Session-State Record
  (derived: each worktree has at most one active feature with one session-state record)

Session-State Record (1) <----validated-by----> (N) Stale-State Checks
  (merge-detection, branch-existence, authorization-record, cross-file consistency)

Version Check Cache (1) <----shared-by----> (3) Commands
  (specrew start, specrew init, specrew update all read/write same cache file)
```

---

## Data Integrity Constraints

### Atomicity Guarantees

- **AG-001**: Each session-state file update MUST use write-temp-then-rename pattern (per-file atomicity)
- **AG-002**: Cross-file atomicity is best-effort; stale-state detection compensates for mid-sync crashes
- **AG-003**: If any file write fails (disk full, permission denied), original file MUST be preserved (no partial writes)

### Consistency Guarantees

- **CG-001**: At `specrew start`, all four session-state files MUST reference same `active_feature` and `current_boundary` (enforced by stale-state detection)
- **CG-002**: `tasks-progress.yml` task IDs MUST match task IDs in sibling `tasks.md` (orphaned progress entries flagged for manual reconciliation)
- **CG-003**: Version check cache MUST never be stale by more than 24 hours (enforced by `cache_valid_until` check)

### Durability Guarantees

- **DG-001**: Session-state files MUST survive system reboot (files persisted to disk with OS filesystem sync)
- **DG-002**: Task progress MUST survive `tasks.md` regeneration (separate `tasks-progress.yml` file preserves progress)
- **DG-003**: Worktree state derivation MUST NOT persist across reboots (pure derivation ensures accuracy, no stale persistent state)

---

## Schema Versioning

**Current Schema Version**: `v1`  
**Versioning Strategy**: If session-state file format changes in future features, add `schema_version` field to `.specrew/start-context.json`. Migration logic added to `specrew start` to upgrade v1 → v2.

**Backward Compatibility**: Existing projects without session-state files (pre-F020) MUST gracefully initialize all files with `no-active-feature` state on first `specrew start` post-F020 deployment.

---

## Edge Cases & Failure Modes

### EC-001: Mid-Sync System Crash
**Scenario**: System crashes after updating `.specrew/last-start-prompt.md` but before updating `.squad/identity/now.md`.  
**Detection**: Stale-state detection identifies cross-file inconsistency at next `specrew start`.  
**Recovery**: User prompted to re-anchor or manually fix state; no silent corruption.

### EC-002: Task ID Renumbering
**Scenario**: `tasks.md` regenerated with tasks renumbered (T001 becomes T005, etc.).  
**Detection**: `tasks-progress.yml` references task IDs not found in current `tasks.md`.  
**Recovery**: User prompted to reconcile manually or discard stale progress; old IDs annotated as "task not found".

### EC-003: Worktree Path Moved
**Scenario**: Git worktree moved on disk but `git worktree list` still references old path.  
**Detection**: `worktree_exists` check fails (path not found).  
**Recovery**: `specrew where --worktrees` annotates with "(path not found)" and suggests `git worktree prune`.

### EC-004: Bootstrap Date Missing
**Scenario**: `.specrew/config.yml` lacks `bootstrap_date` field (brownfield project or legacy project).  
**Detection**: Stale-state detection merge-check reads bootstrap_date, finds it missing.  
**Recovery**: Fallback to `git log main --since="90 days ago"` with verbose warning that bounded search used default 90-day window.

### EC-005: PSGallery Unreachable
**Scenario**: Network offline or PSGallery API down when version check runs.  
**Detection**: PSGallery query times out (>10s) or returns error.  
**Recovery**: Version check fails silently with verbose logging; `specrew start` continues without warning; cache file deleted if exists.
