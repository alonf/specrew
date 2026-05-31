# Data Model: Multi-Session Foundation

**Feature**: 051-multi-session-foundation
**Date**: 2026-05-31
**Purpose**: Define entities, attributes, relationships, and validation rules for F-051 multi-session coordination state. This model is the authoritative reference the reviewer uses to verify implementation fidelity (FR-001 through FR-043) before code lands.

## Storage overview

F-051 persists state across six file-backed surfaces. Three are git-tracked shared state, three are gitignored per-session state. The split is the load-bearing design decision of the feature.

| Surface | Path | Category (FR-004) | Format |
| --- | --- | --- | --- |
| Session mode flag | `.specrew/config.yml` (`session_mode` key) | shared | YAML |
| Session locks | `.specrew/active-sessions.yml` | per-session (gitignored) | YAML |
| Feature claims | `.squad/active-features.yml` | append-only-shared | YAML |
| Identity (shared) | `.squad/identity/now.md` | shared | Markdown + frontmatter |
| Identity (transient) | `.squad/identity/session-state.yml` | per-session (gitignored) | YAML |
| Append-only logs | `.squad/events/lifecycle-events.jsonl`, `.specrew/session-start.log` (future Iteration 4) | append-only-shared | JSON Lines |
| Per-iteration decisions | `.squad/decisions/iteration-NNN/decisions.md` | append-only-shared mirror | Markdown |

## Entity: SessionModeConfig

**Purpose**: The single project-level switch that gates all multi-developer behavior (US1 → FR-001, FR-002, FR-003).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `session_mode` | enum | No (defaults) | MUST be `single` or `multi`; any other value rejected with a validation error | Project collaboration mode |
| `stale_lock_threshold_hours` | integer | No | > 0; defaults to 24 (FR-011) | Optional override for stale-lock auto-clear window |

### Lifecycle / Relationships

Created implicitly with default `session_mode: single` at `specrew init` when absent (FR-003). Mutated only via `specrew config set session_mode <value>` (FR-002). When `multi`, it enables collision detection (US3), claim warnings (US4), per-iteration decision splitting (FR-017), and suppresses redundant multi-dev recommendations (FR-024). When `single`, the auto-detection surfaces (US6) may *recommend* flipping it but never flip it automatically.

## Entity: SessionLockEntry

**Purpose**: Represents one active `specrew start` session, enabling concurrent-session collision detection (US3 → FR-007 through FR-011).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `feature_id` | string | Yes | Non-empty; matches a feature ref | Feature the session is working |
| `user` | string | Yes | Non-empty | Git/OS user identity |
| `machine_fingerprint` | string | Yes | Non-empty; local-only (FR-043) | Hostname+username-derived local identifier |
| `session_start_time` | ISO 8601 timestamp | Yes | Valid UTC timestamp | When the session began |
| `last_heartbeat_time` | ISO 8601 timestamp | Yes | Valid UTC timestamp; >= session_start_time | Liveness marker; staleness measured against this |

### Lifecycle / Relationships

Created on `specrew start` (FR-008), refreshed via heartbeat, removed on normal session end (FR-009). Auto-cleared when `last_heartbeat_time` is older than `stale_lock_threshold_hours` (default 24h) at the next session start (FR-011). Multiple entries coexist for *different* features; a second entry for the *same* feature_id triggers the collision warning (FR-010, SC-002: warning within 2s). Writes MUST be atomic (write-temp-rename) to survive millisecond races (Edge Case: simultaneous claims). Corrupt/invalid YAML is treated as empty and recreated with a logged warning (Edge Case).

## Entity: FeatureClaimEntry

**Purpose**: Advisory Layer-1 claim that a developer is working a feature, for team coordination (US4 → FR-012 through FR-016).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `feature_id` | string | Yes | Non-empty | Claimed feature |
| `claimed_by` | string | Yes | Format `user@machine` | Claiming developer identity |
| `claim_start_time` | ISO 8601 timestamp | Yes | Valid UTC | When the claim was created (specify boundary) |
| `last_refresh_time` | ISO 8601 timestamp | Yes | Valid UTC; >= claim_start_time | Updated each boundary crossing |
| `branch_name` | string | Yes | Non-empty | Feature branch the claim is on |

### Lifecycle / Relationships

Created when the developer crosses the **specify** boundary (FR-013). `last_refresh_time` is refreshed monotonically at every boundary sync while the feature is active (FR-014, SC-008: 100% refresh rate). A start against an already-claimed feature surfaces a Layer-1 warning with claim details + continue/decline prompt (FR-015); continuing preserves the existing claim and records the current local session lock, while declining exits before a lock is recorded. Removed at feature-closeout when the feature is found in main's merge history (FR-016). A manually-removed claim is re-added on next boundary refresh if the session is still active (Edge Case). Distinct from SessionLockEntry: claims are advisory and span the whole feature lifecycle; locks are protective and exist only while a session is live.

## Entity: MultiDevSignal

**Purpose**: Computed (non-persisted) evidence that a project has shifted to multi-developer use (US6 → FR-020 through FR-024).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `schema_version` | string | Yes | `v1` | Aggregate signal object schema |
| `session_mode` | enum | Yes | `single` or `multi` | Current configuration mode |
| `unique_git_author_count` | integer | Yes | >= 0; positive signal at >= 2 | Recent unique git author emails |
| `unique_machine_count` | integer | Yes | >= 0; positive signal at >= 2 | Unique local active-session machine fingerprints counted but not exposed |
| `concurrent_write_count` | integer | Yes | >= 0; positive signal at >= 1 | Close-together shared-state write pairs |
| `branch_fanout_count` | integer | Yes | >= 0; positive signal at >= 3 | Feature branch fan-out count |
| `has_multi_developer_signal` | bool | Yes | Derived from counts | Whether any detector fired |
| `recommendation_suppressed` | bool | Yes | True when `session_mode == multi` | Suppression flag for FR-024 |
| `recommendation_message` | string/null | No | Null when suppressed or no signal; must not include rich fingerprints | User-facing recommendation |
| `summary` | string | Yes | Coarse counts only | Boundary/dashboard note text |

### Lifecycle / Relationships

Computed on-demand at `specrew start`, `specrew where`, and boundary-sync; never persisted as a durable project record (recomputed each time). Detectors: 2+ git author emails in last 90 days; 2+ machine fingerprints in `.specrew/active-sessions.yml`; close-together shared-state writes; branch fan-out (3+ feature branches) (FR-020). When any positive signal exists AND `session_mode == single`, a recommendation is surfaced at Welcome Orientation (FR-021), `specrew where` (FR-022), and boundary-sync output (FR-023); when `session_mode == multi`, the aggregate still records the signal but `recommendation_message` is null and `recommendation_suppressed` is true (FR-024, SC-007: 0-2s latency). Advisory only — never mutates config and never exposes rich machine fingerprints (Edge Case: single dev with multiple emails can ignore).

## Entity: IterationDecisionLedger

**Purpose**: Per-iteration mirror of the legacy `.squad/decisions.md` ledger to reduce shared-file merge conflicts when multi-session mode is enabled (US5 → FR-017).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `iteration_number` | string | Yes | Normalized to `NNN` | Iteration owning this mirrored ledger |
| `entries` | markdown blocks | No | Entries are copied from `## ...` decision sections with matching iteration metadata | Decision history for that iteration |
| `source_path` | path | Yes | `.squad/decisions.md` | Backward-compatible source ledger |

### Lifecycle / Relationships

Generated by `Split-SpecrewDecisionsByIteration` from legacy decision entries. Boundary sync invokes the splitter only when `session_mode == multi`; single-session projects keep legacy behavior. The mirror is deterministic and idempotent: re-running the splitter converges to the same per-iteration files and does not duplicate entries.

## Entity: LifecycleEventRecord

**Purpose**: JSON Lines boundary event record for append-only lifecycle logging (US5 → FR-018).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `schema` | string | Yes | `v1` | JSONL record schema |
| `recorded_at` | ISO 8601 timestamp | Yes | Valid UTC | Event write time |
| `event_type` | string | Yes | Non-empty | Event type, currently `boundary-sync` |
| `payload` | object | Yes | JSON object | Boundary metadata such as feature, iteration, task, and auth commit |

### Lifecycle / Relationships

Appended to `.squad/events/lifecycle-events.jsonl` by boundary sync. Each line is one complete JSON object. Invalid historical lines are skipped with a warning rather than crashing readers.

## Entity: FileClassificationRule

**Purpose**: Static categorization of a Specrew-managed path pattern that drives `.gitignore` generation and git-index cleanup (US2 → FR-004 through FR-006).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `pattern` | glob string | Yes | Valid glob | Path pattern the rule covers |
| `category` | enum | Yes | One of `shared`, `per-session`, `append-only-shared`, `regenerable` | Classification |
| `reason` | string | Yes | Non-empty | Why this pattern is in this category |

### Canonical per-session patterns (FR-005)

`.specrew/last-*`, `.specify/feature.json`, `.specrew/start-context.json`, `.specrew/host-history.json`, `.specrew/.cache/`, `.squad/sessions/`, `.squad/decisions/inbox/`, `.specrew/last-validator-summary.json`, `.specrew/active-sessions.yml` (FR-005 gap fix from Iteration 2a), and (FR-036) `.squad/identity/session-state.*`.

### Lifecycle / Relationships

Defined statically in Specrew configuration. Applied at `specrew init` (and re-init) to merge per-session patterns into `.gitignore` without duplicating existing entries or destroying comments/structure (Edge Case), and to run `git rm --cached` on any per-session path already tracked — removing it from the index without deleting the working copy (FR-006, matching the F-049 `437338f6` pattern). The full rule set generates the complete `.gitignore` block (SC-001: zero per-session merge conflicts).

## Entity: SessionStateSplit (identity split)

**Purpose**: Decouple git-tracked shared identity from gitignored transient session state so fresh worktrees don't inherit stale `session_state_*` and trigger spurious recovery (US9 + US10 → FR-035 through FR-043).

### Attributes — shared (`.squad/identity/now.md`, tracked)

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `focus_area` | string | Yes | MUST NOT contain `session_state_*` fields (FR-038) | Crew focus |
| body | markdown | Yes | No `session_state_` tokens | Shared identity prose |

### Attributes — transient (`.squad/identity/session-state.yml`, gitignored)

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `session_state_active` | bool | Yes | — | Whether a session is active |
| `session_state_boundary` | string | Yes | Canonical boundary name | Current boundary |
| `session_state_feature_path` | string | Yes | — | Active feature path |
| `session_state_iteration` | string | No | — | Active iteration |
| `session_state_auth_commit` | string | No | git SHA | Last boundary auth commit |
| `session_state_recorded_at` | ISO 8601 | Yes | Valid UTC | When recorded |

### Lifecycle / Relationships

Migration strips `session_state_*` from `now.md`, writes them to `session-state.yml`, commits the now.md change, and adds `.squad/identity/session-state.*` to `.gitignore` (FR-035, FR-036, FR-037). At `specrew start`, a tracked-file guard greps for `session_state_` in git-tracked files and errors if any are found (FR-038). **Brand-new worktree detection** (FR-039): empty/missing `active-sessions.yml` + no recent boundary commits on the current branch + no iteration dirs matching the inherited feature_path ⇒ brand-new ⇒ skip A/B/C recovery, go straight to specify (FR-040). **Genuine inconsistency** (FR-041): inherited feature_path mismatches current branch AND iteration dirs exist for it ⇒ show A/B/C. Every detection signal + decision logged to `.specrew/session-start.log` (FR-042). Fingerprints stay local-only (FR-043).
