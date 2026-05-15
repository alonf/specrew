# Data Model: Velocity Dashboard Visual Richness + PoC-Parity Restoration

## 1. DashboardRenderingProfile

**Purpose**: Captures the rendering policy chosen for one dashboard invocation or stored snapshot.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `rendering_mode` | enum (`rich`, `monochrome`) | Effective presentation mode after capability detection and user overrides |
| `ansi_enabled` | boolean | Whether semantic ANSI emphasis may be emitted live |
| `unicode_enabled` | boolean | Whether Unicode glyphs may be emitted live |
| `ascii_forced` | boolean | True when `--ASCII` explicitly forced fallback |
| `fallback_reason` | string/null | Human-readable reason rich mode was not used |
| `recent_count` | integer | Number of Recent Shipped entries to display |
| `bar_width` | integer | Width used for shipped/progress bar rendering |
| `snapshot_strip_ansi` | boolean | Whether persisted artifacts must remove ANSI escapes |

### Validation Rules

- `rendering_mode = rich` requires `unicode_enabled = true`.
- Live ANSI emphasis requires supported terminal capability; stored artifacts always strip ANSI.
- `recent_count` defaults to `6` and must be positive.
- `bar_width` defaults to `28` and must be positive.

## 2. RichDashboardSnapshot

**Purpose**: The assembled dashboard view after Feature 018 visual enrichment is applied.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `captured_at` | datetime | UTC capture timestamp rendered in the header |
| `today_anchor` | date | `Today: YYYY-MM-DD` value shown in the header |
| `render_profile` | DashboardRenderingProfile | Effective rendering policy for this invocation |
| `header_rule` | string | Horizontal separator text used in rich mode |
| `active_work` | ActiveWorkPresentation/null | Active feature and iteration emphasis payload |
| `velocity_summary` | VelocityPresentation | Numeric pace headline, sample basis, and optional sparkline |
| `recent_shipped` | array<RecentShippedEntry> | Up to `recent_count` shipped entries with dense bars and metadata |
| `roadmap_rows` | array<RoadmapPhasePresentation> | Roadmap phases with state markers, progress, and descriptions |
| `warnings` | array<string> | Bounded guidance and degraded-mode explanations |
| `footer_note` | string | Final orienting guidance line |

### Validation Rules

- Section order must stay compatible with Feature 017.
- Empty states must be explicit for missing active work, shipped history, sparse velocity, and missing roadmap context.
- Rich additions must not introduce lifecycle or analytics changes outside the approved pillars.

## 3. ActiveWorkPresentation

**Purpose**: Displays current feature context with clearer emphasis than Feature 017.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `feature_ref` | string | Active feature identifier |
| `feature_title` | string | Human-readable active feature title |
| `arrow_prefix` | string | Rich-mode active-feature indicator, `→` in rich mode |
| `status_text` | string | Active feature status summary |
| `iteration_label` | string/null | Active iteration identifier |
| `iteration_phase` | string/null | Current iteration phase/state text |
| `inflight_summary` | string/null | Planned/delivered/remaining summary |
| `empty_state_message` | string/null | Fixed guidance when no active feature exists |

### Validation Rules

- The arrow indicator is shown only for active work emphasis.
- Monochrome rendering must preserve the same active-state meaning without depending on the Unicode arrow.

## 4. VelocityPresentation

**Purpose**: Represents the enriched Velocity section while keeping numeric pace primary.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `points_per_day` | decimal | Headline delivered pace |
| `sample_size` | integer | Closed iterations included in the pace summary |
| `sample_basis_text` | string | Explicit basis/insufficient-history explanation |
| `confidence` | enum (`low`, `moderate`, `high`) | Confidence label carried forward from Feature 017 |
| `sparkline` | string/null | Velocity-only Unicode block-element sparkline |
| `recent_values` | array<decimal> | Pace values backing the sparkline |
| `insufficient_history_message` | string/null | Fixed explanation when the sparkline/headline cannot be meaningfully derived |

### Validation Rules

- Sparkline appears only in the Velocity section.
- Sparkline remains subordinate to the numeric headline and sample-basis text.
- Monochrome rendering degrades gracefully without changing the underlying pace meaning.

## 5. RecentShippedEntry

**Purpose**: A denser shipped-history row shown in the Recent Shipped section.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `feature_prefix` | string | `F-NNN` style feature-oriented prefix |
| `iteration_label` | string | Iteration identifier |
| `short_name` | string | Readable shortened feature name |
| `delivered_story_points` | decimal | Delivered story points shown in the row |
| `iteration_count` | integer | Closed-iteration count contributing to the shipped feature |
| `close_date` | date | Close date shown in the row |
| `bar_text` | string | Rendered 28-character default bar or overridden width |
| `status_marker` | string | Rich-mode shipped marker (`✓`) or monochrome substitute |

### Validation Rules

- Default bar width is `28` unless overridden.
- Default count is `6` rows unless overridden.
- Empty state must render a fixed explanatory message when no shipped history exists.

## 6. RoadmapPhasePresentation

**Purpose**: The roadmap-ready display row and description line for each phase.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `phase_id` | string | Stable roadmap phase identifier |
| `phase_name` | string | Human-readable phase name |
| `status_marker` | string | Rich marker for shipped/active/queued (`✓`, `◐`, `○`) or fallback substitute |
| `progress_summary` | string | Planned vs derived progress summary |
| `description_line` | string | Human-readable description shown on its own line |
| `description_truncated` | boolean | Whether truncation was needed beyond 80 characters |
| `is_active_phase` | boolean | Whether the active feature belongs to this phase |

### Validation Rules

- Every phase description renders on its own line.
- Descriptions truncate only beyond 80 characters and use `...`.
- Status markers must remain comprehensible in monochrome mode.

## 7. PersistedDashboardArtifact

**Purpose**: Represents a stored iteration-closeout or feature-closeout dashboard snapshot.

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `artifact_path` | string | Stored Markdown snapshot path |
| `capture_kind` | enum (`iteration-closeout`, `feature-closeout`) | Which closeout flow produced the artifact |
| `render_profile` | DashboardRenderingProfile | Rendering policy in effect at capture time |
| `dashboard_text` | string | Persisted dashboard payload after ANSI stripping |
| `unicode_preserved` | boolean | Whether Unicode glyphs remain in the stored payload |
| `ansi_stripped` | boolean | Whether ANSI escape sequences were removed |
| `encoding` | enum (`utf-8-no-bom`) | Required file encoding |
| `line_endings` | enum (`lf`) | Required line ending policy for fixtures/artifacts |
| `historical_notice` | string | Explicit notice that this is a closeout-time snapshot |

### Validation Rules

- Stored artifacts must never retain ANSI escapes.
- Stored artifacts may preserve Unicode glyphs.
- Historical immutability rules from Feature 017 continue unchanged.

## Relationships

- `RichDashboardSnapshot` includes one `DashboardRenderingProfile`, zero or one `ActiveWorkPresentation`,
  one `VelocityPresentation`, zero or more `RecentShippedEntry` rows, and zero or more
  `RoadmapPhasePresentation` rows.
- `PersistedDashboardArtifact` stores exactly one `RichDashboardSnapshot` after ANSI stripping rules are
  applied.
