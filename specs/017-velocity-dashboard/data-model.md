# Data Model: Velocity Dashboard

## 1. DashboardSnapshot

**Purpose**: Represents the rendered "Where Am I?" view at one invocation or closeout moment.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `snapshot_id` | string | Stable identifier for a rendered snapshot or stored artifact instance |
| `captured_at` | datetime | Timestamp for live rendering or closeout capture |
| `capture_kind` | enum (`live`, `iteration-closeout`, `feature-closeout`) | Distinguishes ad hoc views from durable artifacts |
| `repository_identity` | object | Repository/branch header context shown in the dashboard |
| `summary_line` | string | One-line summary of active feature, phase highlight, velocity, and ETA cues |
| `active_work` | object | Current feature/iteration state summary |
| `active_phase` | RoadmapPhaseRecord/null | Roadmap phase associated with the active feature when available |
| `velocity_headline` | object | Recent pace metric, sample basis, optional sparkline/trend text |
| `recent_shipped` | array<FeatureDeliveryRecord> | Most recent shipped features/iterations displayed as bars |
| `recent_iteration_variance` | array<IterationVarianceRow> | Planned vs. actual recent iterations table |
| `full_history_summary` | array<HistoryBarRow> | Closed-iteration story-point summary across the full history |
| `roadmap_progress` | array<RoadmapPhaseRecord> | Ordered roadmap phases with derived shipped progress |
| `remaining_effort_projection` | object | Remaining story points, ETA, and confidence language |
| `eta_scopes` | array<ProjectionScope> | Multi-scope ETA rows (active feature, current phase, roadmap) |
| `warnings` | array<DashboardWarning> | Calm, bounded quality/setup messages shown to the user |
| `render_mode` | enum (`full`, `compact`) | Full or 24-line compact rendering |
| `color_mode` | enum (`semantic-color`, `monochrome`) | Effective theme choice after environment checks |

### Validation Rules

- Must render the same section order across all supported invocation surfaces.
- Iteration identifiers must follow `feature-NNN.iter-MM` across recent shipped, variance, and history views.
- Compact rendering must remain within the fixed 24-line budget.
- Missing roadmap or malformed artifacts must not block creation of the rest of the snapshot.
- Stored snapshots must clearly state they are historical artifacts and may differ from a later live rerun.

### State Transitions

`assembled` → `rendered-live`  
`assembled` → `captured-as-iteration-artifact`  
`assembled` → `captured-as-feature-artifact`

Stored artifact states are immutable after capture.

## 2. RoadmapPhaseRecord

**Purpose**: Defines one roadmap phase from `.specrew/roadmap.yml` and the derived shipped state
displayed in roadmap progress.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `phase_id` | string | Stable phase identifier |
| `order` | integer | Rendering order in the roadmap |
| `name` | string | Human-readable phase name |
| `description` | string | Short descriptive context for the phase |
| `planned_effort_sp` | integer | Human-maintained total planned story points |
| `declared_status` | enum (`queued`, `in-progress`, `shipped`) | Maintainer-declared phase status |
| `feature_refs` | array<string> | Feature directories included in the phase |
| `derived_shipped_effort_sp` | integer | Story points derived from closed iteration records |
| `remaining_effort_sp` | integer | Planned minus derived shipped points, bounded at zero |
| `overage_story_points` | integer | Story points shipped beyond the plan (0 when not drifted-over) |
| `effective_status` | enum (`queued`, `in-progress`, `shipped`, `drifted`, `drifted-over`) | Display/validator-facing status after comparison |

### Validation Rules

- `phase_id`, `name`, `planned_effort_sp`, and at least one feature ref are required.
- `planned_effort_sp` must be non-negative.
- `derived_shipped_effort_sp` is computed, never user-entered.
- Declared status that materially conflicts with derived shipped effort must emit a bounded drift warning.

### State Transitions

`queued` → `in-progress` → `shipped`  
Any state can surface `drifted` as a validation/display overlay when declarations and history diverge.

## 3. FeatureDeliveryRecord

**Purpose**: Aggregates canonical feature/iteration evidence used for active work, recent shipped
history, roadmap progress, and projections.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `feature_ref` | string | Feature directory identifier such as `017-velocity-dashboard` |
| `spec_path` | string | Path to the feature spec |
| `feature_title` | string | Human-readable feature name |
| `feature_status` | string | Current lifecycle status from canonical artifacts |
| `derived_status` | string | Status derived from iteration/review/retro evidence instead of spec frontmatter |
| `active_iteration_ref` | string/null | Current active iteration when applicable |
| `planned_story_points` | integer | Planned story points from the relevant iteration/feature context |
| `delivered_story_points` | integer | Closed/actual delivered points derived from iteration history |
| `remaining_story_points` | integer | Planned minus delivered story points, bounded at zero |
| `closed_iterations` | array<string> | Closed iteration identifiers contributing to shipped totals |
| `started_at` | datetime/null | Earliest relevant in-flight timestamp if known |
| `closed_at` | datetime/null | Most recent shipped timestamp if known |

### Validation Rules

- Must be derived from canonical feature specs, iteration records, and retros rather than free text.
- Partial history is allowed, but missing fields must downgrade confidence and emit warnings instead
  of inventing values.

## 4. VelocitySampleWindow

**Purpose**: Captures the recent closed-iteration slice used to summarize pace and confidence.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `window_id` | string | Identifier for the sample basis |
| `sample_policy` | enum (`calendar-days`) | Pace policy; v1 is fixed to calendar days |
| `included_iterations` | array<string> | Closed iterations included in the recent pace calculation |
| `sample_size` | integer | Number of iterations used |
| `total_story_points` | number | Sum of delivered points in the window |
| `average_elapsed_days` | number | Mean calendar-day duration for the sample |
| `points_per_day` | number | Headline velocity metric |
| `trend_tokens` | string/null | Optional tiny sparkline or simple trend indicator |
| `confidence_level` | enum (`low`, `moderate`, `high`) | Confidence language shown with projections |

### Validation Rules

- Uses calendar days only in v1.
- Must disclose sample size and basis whenever pace is shown.
- Sparse history is allowed but must reduce confidence and avoid overclaiming precision.

## 5. ProjectionScope

**Purpose**: Captures a single ETA scope for active feature, current phase, or full roadmap.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `scope_id` | enum (`active-feature`, `current-phase`, `roadmap`) | Which scope the projection represents |
| `remaining_effort_sp` | integer | Remaining story points for the scope |
| `eta_text` | string | ETA string such as `TBD`, `roadmap shipped`, or `12 calendar day(s)` |
| `confidence_level` | enum (`low`, `moderate`, `high`) | Confidence language aligned to velocity sample mapping |

## 6. DashboardArtifact

**Purpose**: Durable stored markdown artifact created automatically at closeout.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `artifact_path` | string | `specs/<feature>/iterations/<NNN>/dashboard.md` or `specs/<feature>/closeout-dashboard.md` |
| `artifact_kind` | enum (`iteration-dashboard`, `feature-closeout-dashboard`) | Artifact type |
| `source_snapshot_id` | string | Snapshot persisted into the artifact |
| `captured_at` | datetime | Historical capture time |
| `baseline_ref` | string/null | Closeout baseline reference if available |
| `schema_version` | string | Artifact schema/version marker |
| `historical_notice` | string | Explicit notice that the file is a historical snapshot |

### Validation Rules

- Required for post-feature iteration closeouts after rollout.
- Must not be silently regenerated in place later.
- Historical iterations that predate the feature are grandfathered.

### State Transitions

`pending-closeout-generation` → `captured` → `retained-immutable`

## 7. DashboardInvocationSurface

**Purpose**: The supported entry paths that must resolve to the same renderer.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `surface_id` | enum (`where`, `status-alias`, `script-entry`, `project-status-routing`, `team-fallback`) | Invocation path |
| `canonical` | boolean | Whether the surface is the primary entry point |
| `supports_compact` | boolean | Whether compact mode is allowed |
| `supports_no_color` | boolean | Whether no-color behavior is honored |
| `fallback_behavior` | string/null | Team-mode fallback or setup guidance text |

### Validation Rules

- `specrew where` is canonical.
- `specrew status` must be behaviorally equivalent.
- Repository/project-status Squad requests must route to the same renderer.
- `--Team` must explain the limitation and then render the personal dashboard.

## Relationships

- A `DashboardSnapshot` aggregates one `VelocitySampleWindow`, zero or more `FeatureDeliveryRecord`
  entries, and zero or more `RoadmapPhaseRecord` entries.
- A `DashboardArtifact` persists exactly one `DashboardSnapshot`.
- A `DashboardInvocationSurface` triggers one `DashboardSnapshot` render.
- `RoadmapPhaseRecord.feature_refs` resolve to one or more `FeatureDeliveryRecord` items.
