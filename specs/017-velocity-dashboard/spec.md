# Feature Specification: Velocity Dashboard ("Where Am I?")

**Feature Branch**: `017-velocity-dashboard`  
**Created**: 2026-05-14  
**Status**: Implementation Active  
**Input**: User description: "Activate Feature 017 — Velocity Dashboard ('Where Am I?') using `C:\Dev\SpecrewDraft\velocity-dashboard.md` as the source intent, `C:\Dev\Specrew\proposals\009-velocity-dashboard.md` as the public framing reference, generate `specs/017-velocity-dashboard/spec.md` from scratch, defer the 10 clarify-time questions to `/speckit.clarify`, update `.specify/feature.json`, and move Proposal 009 from draft to active on this feature branch."

## Problem Statement

At iteration close, the human developer needs one trustworthy view that answers three practical questions without opening a stack of artifacts: what has already shipped, what is still in flight, and where the project is heading next.

Specrew already stores the underlying signals across feature specs, iteration records, retrospectives, roadmap planning, and active-feature pointers, but those signals are scattered. The resulting burden is cognitive rather than mechanical: the developer has to reconstruct recent delivery history, estimate pace, infer remaining effort, and remember roadmap context from multiple files and prior conversations.

This feature introduces a console-first dashboard that turns those dispersed signals into a single "Where am I?" view. The dashboard must help the developer understand current status, recent momentum, roadmap position, and likely remaining effort while staying aligned with Specrew's boundary-driven workflow and console-centric interaction model.

## Clarifications

### Session 2026-05-15

- Q: Should the iteration `dashboard.md` record behave primarily as a historical snapshot, a regenerable current view, or support both patterns explicitly? → A: The per-iteration `dashboard.md` artifact is a historical snapshot captured at closeout; rerunning the dashboard later produces a new live view but does not silently rewrite stored closeout artifacts.
- Q: Should compact mode have a fixed line budget or a configurable one-screen budget? → A: Compact mode uses a fixed v1 budget of at most 24 lines so closeout handoffs stay consistent and testable across environments.
- Q: Should the projection section communicate time-to-target, effort remaining only, or both? → A: The dashboard shows both raw remaining story points and time-to-target estimates, with explicit uncertainty language so readers can audit the underlying effort basis.
- Q: When roadmap phases include partially completed features, how should partial shipped effort contribute to phase progress? → A: Roadmap shipped effort counts actual story points from closed iterations even when the containing feature is not fully complete yet, while the phase remains visually in-progress until the broader work is shipped.
- Q: What exact pre-multi-developer user experience should the reserved team-oriented invocation provide? → A: `--Team` remains visible, prints a friendly not-yet-available explanation, and then falls back to rendering the personal dashboard instead of failing destructively.
- Q: Should any auto-invocation surfaces exist beyond the core iteration-closeout and feature-closeout flows? → A: No; v1 limits automatic invocation to iteration-closeout and feature-closeout boundaries and defers hook-based or other ambient automation.
- Q: Should the latest dashboard also live in a top-level living document in addition to per-iteration artifacts? → A: No; v1 keeps durable dashboard artifacts only in the iteration and feature-closeout records to avoid adding a second mutable source that could drift.
- Q: Should the pace calculation use calendar days, working days, or a selectable policy? → A: Pace uses calendar days in v1 because the rule is simple, reproducible, and does not require locale- or holiday-specific calendars.
- Q: Should the dashboard stay descriptive only, or also hint at the next likely feature? → A: The dashboard stays descriptive in v1 and does not predict the next likely feature.
- Q: Which environment-level color suppression conventions, if any, should be treated as first-class alongside explicit command flags? → A: In addition to `--NoColor`, the dashboard honors `NO_COLOR`, dumb-terminal detection, and non-TTY output when deciding to render monochrome.
- Q: Which on-demand command is canonical, and should project-status Squad requests use the same dashboard? → A: `specrew where` is the canonical on-demand dashboard command, `specrew status` is a supported alias for discoverability, and repository/project-status Squad requests route to the same dashboard renderer while non-project conversational status requests do not.
- Q: What visual vocabulary should the v1 dashboard use for pace, history, projections, and plan-vs-reality? → A: V1 stays console-first, monochrome-safe, and low-noise by using only horizontal bars, progress bars, and at most one tiny sparkline; story point velocity appears as a headline metric with explicit sample basis, recent history appears as horizontal bars plus compact recent-iterations tables, predictions use remaining story points plus ETA with explicit uncertainty, and burndowns, pie charts, scatterplots, and dense daily charts are deferred.
- Q: Should the dashboard show only recent delivery history or also include a longer-horizon iteration-level view of trajectory? → A: The dashboard MUST include both a recent-iterations variance view for immediate plan-vs-reality scrutiny AND a full-history iteration summary bar chart for zoomed-out big-picture awareness of long-term trajectory, using compact horizontal bars to respect the console-rendering and line-budget constraints.

## Scope Boundaries

### In Scope

- A new "where" dashboard experience with canonical on-demand access via `specrew where`, a supported `specrew status` alias, a dedicated script entry point, and repository/project-status Squad routing to the same dashboard renderer.
- A single-screen summary of active work, recent shipped work, delivery pace, roadmap progress, and remaining effort.
- A restrained visual policy that keeps dashboard rendering console-first, monochrome-safe, and low-noise through compact bars, progress bars, tables, and at most one tiny sparkline.
- A structured roadmap source that replaces ad hoc or hardcoded roadmap assumptions.
- A semantic color theme and readable monochrome fallback for environments that do not support or should not use color.
- Automatic dashboard generation at iteration-closeout, including durable per-iteration artifacts.
- User-facing education so a new or returning developer can understand what the dashboard means and how to maintain its inputs.
- Forward-compatible design for future multi-developer support without implementing the full multi-developer view in this feature.

### Out of Scope

- A browser-based dashboard, HTML export, or Methodology Site rendering.
- General conversational "status" responses unrelated to repository/project state; only repository/project-status Squad requests route to the dashboard renderer in v1.
- Full team or per-developer attribution views; this feature only reserves room for that future capability.
- Burndown charts, pie charts, scatterplots, dense daily charts, cycle-time analytics, predictive prioritization, or other advanced delivery analytics beyond the bounded dashboard scope.
- Reworking the larger lifecycle, artifact contract, or boundary system introduced by prior features.
- Real-time in-iteration telemetry beyond a concise description of the currently active feature and iteration position.
- Additional automation surfaces such as Git hooks, post-merge hooks, or pre-push hooks; v1 limits automatic rendering to iteration-closeout and feature-closeout flows.
- A top-level living dashboard artifact such as `.specrew/where-we-are.md`; v1 keeps durable dashboard records only with the relevant closeout artifacts.
- Predictive "next likely feature" hints or other forecasted prioritization suggestions.

## Relationship to Existing Features

- **Feature 013 — Validator Hardening** provides the soft-warning and governance-validation patterns this feature extends for dashboard artifacts and roadmap drift.
- **Feature 014 — Handoff Format Scoping** provides the boundary-handoff structure that this dashboard enriches at iteration-closeout.
- **Feature 015 — Public-Readiness Pass** established public documentation surfaces that this feature now extends with dashboard education and lifecycle guidance.
- **Feature 016 — Substantive Interaction Model** established the console-first, stop-at-boundary interaction model that this dashboard composes with directly.
- **Proposal 009 — Velocity Dashboard** supplies the public framing for why the feature matters and where it belongs on the roadmap.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Understand current project position quickly (Priority: P1)

A developer can invoke the dashboard through `specrew where`, the `specrew status` alias, or a repository/project-status Squad request and immediately see what is active now, what recently shipped, how the project has been moving, and how far the roadmap still extends.

**Why this priority**: The feature's core value is decision support at the moment the developer asks "where am I?" If that answer is not clear in one view, the dashboard fails its primary purpose.

**Independent Test**: Run the dashboard in a repository with active work plus several closed features and verify that a fresh reviewer can summarize current work, recent deliveries, pace, and roadmap position without opening additional artifacts first.

**Acceptance Scenarios**:

1. **Given** a repository with an active feature and previously closed features, **When** the developer runs `specrew where`, runs `specrew status`, or asks Squad to show the current project status, **Then** the same dashboard renderer shows a clearly labeled view of active work, recent shipped work, a headline velocity metric with explicit sample basis, roadmap position, and remaining effort in a consistent order.
2. **Given** a developer reviewing the dashboard after an iteration close, **When** they read the output, **Then** they can identify what has been completed so far, inspect recent shipped history as horizontal bars and compact tables, see the full-history iteration summary to understand long-term delivery trajectory, and see what broad work remains ahead without decoding dense chart types.
3. **Given** a developer wants to assess whether the project's velocity is trending up, down, or stabilizing, **When** they view the dashboard, **Then** the full-history iteration summary bar chart communicates the delivery pattern across all closed iterations so they can spot trends without opening historical records.
4. **Given** the dashboard references specific features or artifacts, **When** the developer reads the output in the Specrew environment, **Then** the references are presented in a drill-down-friendly form that supports deeper inspection.

---

### User Story 2 - Trust the dashboard as a faithful summary (Priority: P1)

A developer can rely on the dashboard because it is derived from canonical project records, stays resilient when records are incomplete, and surfaces uncertainty without crashing or silently misleading.

**Why this priority**: Visibility is only useful if the developer trusts the summary. A brittle or misleading dashboard would create false confidence and damage the workflow.

**Independent Test**: Exercise the dashboard against fixture repositories with complete data, partial data, malformed data, and missing roadmap configuration, and confirm that it renders useful output plus bounded warnings instead of failing hard.

**Acceptance Scenarios**:

1. **Given** some state or retro artifacts are missing or malformed, **When** the dashboard runs, **Then** it skips the unusable records, emits bounded warnings, and still renders the rest of the view.
2. **Given** roadmap information and feature history disagree, **When** the dashboard computes roadmap progress, **Then** the mismatch becomes visible through the dashboard or validator surfaces rather than remaining hidden.
3. **Given** roadmap configuration has not been created yet, **When** a developer runs the dashboard for the first time, **Then** they receive a helpful setup message and still see the other dashboard sections.

---

### User Story 3 - Receive the dashboard as part of normal lifecycle work (Priority: P2)

A developer encounters the dashboard naturally at iteration-closeout and can learn how to interpret and maintain it without reading source code.

**Why this priority**: The dashboard should become part of the working method, not a forgotten optional command. Education and automatic surfacing are what make the visibility durable.

**Independent Test**: Complete an iteration-closeout flow after this feature ships and confirm that the dashboard is generated automatically, stored as an iteration artifact, and explained by the user-facing documentation.

**Acceptance Scenarios**:

1. **Given** an iteration-closeout boundary occurs after this feature ships, **When** Squad performs the boundary workflow, **Then** it generates the dashboard, includes it in the handoff, and stores the iteration artifact in the feature's iteration record.
2. **Given** a new or returning developer asks for help, **When** they use the command help and dashboard documentation, **Then** they can understand each section and maintain the roadmap input without consulting implementation code.
3. **Given** a developer notices the reserved team-view flag, **When** they try it before multi-developer support exists, **Then** they receive a clear, non-destructive explanation of the current limitation.

---

### Edge Cases

- The repository may have no closed features yet; the dashboard still needs to explain the absence of historical delivery data without implying failure.
- Some features may have inconsistent or incomplete iteration records; the dashboard must avoid overclaiming certainty from partial history.
- The active feature pointer may exist while its iteration history is still sparse; the dashboard should still identify active work without inventing detail.
- Roadmap configuration may be missing, stale, or only partially decomposed into concrete features; roadmap output must remain understandable under each condition.
- Color-capable and color-restricted terminals must both receive readable output.
- Automatic iteration-closeout generation must not make historical pre-dashboard iterations appear invalid.
- The reserved team-view pathway must not block the personal view or imply that multi-developer support already exists.
- A stored closeout snapshot may differ from a later live rerun; the artifact must remain clearly attributable to its original closeout moment rather than implying live freshness.

## Requirements *(mandatory)*

### Functional Requirements

#### Pillar 1: Dashboard Rendering

- **FR-001**: Specrew MUST provide a "where am I" dashboard whose canonical on-demand CLI command is `specrew where`. `specrew status` MUST be supported as a discoverability alias, the dedicated script entry point MUST invoke the same feature, and all of these command surfaces MUST render equivalent dashboard content. **Owner role**: CLI steward. **Delivery window**: Iteration 1.
- **FR-002**: The dashboard MUST build its summary from canonical project records, including the active-feature pointer, feature specifications, iteration state records, retrospective records, product configuration, and the structured roadmap source introduced by this feature. **Owner role**: Data steward. **Delivery window**: Iteration 1.
- **FR-003**: The dashboard MUST render a consistent ordered summary containing: repository identity context, active work, a headline story-point velocity metric with explicit calendar-day sample basis, recently shipped features, a compact recent-iterations table covering iteration size and duration, a full-history iteration summary showing completed story points per iteration across all closed iterations to support long-term trajectory awareness, roadmap position, and both remaining-effort totals plus time-to-target projections with explicit uncertainty language. The velocity section MAY include one tiny recent-pace sparkline, but recent story-points-per-day detail MUST NOT be a primary v1 visual. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-004**: V1 dashboard visuals MUST stay console-first, monochrome-safe, and low-noise by using only horizontal bars, progress bars, compact tables, and at most one tiny sparkline. Burndowns, pie charts, scatterplots, and dense daily charts MUST NOT appear in v1. Recently shipped history MUST be shown as a horizontal bar list of recent shipped iterations or features, full-history iteration trajectory MUST be shown as a compact iteration summary bar (displaying story points per iteration in sequence) to communicate long-term delivery patterns without dense visualization, roadmap and phase status MUST be backed by progress bars, and projections MUST use remaining story points plus ETA lines with explicit uncertainty. **Owner role**: UX steward. **Delivery window**: Iteration 1.
- **FR-005**: V1 MUST show plan versus reality through a recent-iterations variance table that includes planned story points, actual story points, delta, and elapsed calendar days for each recent iteration. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-006**: The dashboard MUST apply a semantic color treatment when color is available and MUST fall back to a clearly readable monochrome rendering when color is unavailable or intentionally disabled. **Owner role**: UX steward. **Delivery window**: Iteration 1.
- **FR-007**: The dashboard MUST provide a compact rendering mode suitable for iteration-closeout handoffs and single-screen inspection, while preserving the dashboard's essential meaning. The v1 compact rendering MUST use a fixed maximum budget of 24 lines rather than a user-configurable line target. **Owner role**: UX steward. **Delivery window**: Iteration 1.
- **FR-008**: Missing, malformed, or partially inconsistent source artifacts MUST produce bounded warnings and partial rendering rather than a crash or empty dashboard. **Owner role**: Reliability steward. **Delivery window**: Iteration 1.
- **FR-009**: The dashboard MUST reserve a team-oriented invocation path for future multi-developer support and, until that feature exists, respond with a clear not-yet-available experience that preserves user trust by explaining the limitation and then rendering the personal dashboard view. **Owner role**: Product steward. **Delivery window**: Iteration 1.

##### Example Dashboard Output

> **Note**: This example is illustrative, not normative. The requirements and acceptance scenarios remain the source of truth for dashboard behavior. The following represents the shape and information density a developer would see when running `specrew where` in a healthy project state.

```
SPECREW VELOCITY DASHBOARD
Summary: feature-017 (In Progress · phase executing) | Velocity 2.25 SP/day (5 closed iterations, moderate) | ETA: feature 5d · phase 34d · roadmap 60d
Repo: alonf/specrew | Branch: 017-velocity-dashboard | Captured: 2026-05-15T12:00:00Z

ACTIVE WORK
  Feature: 017-velocity-dashboard (Velocity Dashboard) | status In Progress
  Iteration: feature-017.iter-001 | planned 11 SP | phase EXECUTING | started 2026-05-05
  In-flight: 11 SP planned · 0 SP delivered · 11 SP remaining

VELOCITY
  Recent pace: 2.25 SP/day (last 5 closed iterations; 45 SP / 20 total days, avg 4.0) | confidence moderate
  Trend: 12 / 10 / 9 / 8 / 6

RECENT SHIPPED
  ▓▓▓▓▓▓▓ feature-016.iter-002 (12 SP) · Closed 2026-05-14
  ▓▓▓▓▓▓ feature-016.iter-001 (10 SP) · Closed 2026-05-08
  ▓▓▓▓▓ feature-015.iter-002 (9 SP)  · Closed 2026-05-03

RECENT ITERATIONS (PLAN VS REALITY)
  Iter                  Planned Actual Delta Days
  feature-016.iter-002     11     12   +1   4
  feature-016.iter-001     10     10    0   3
  feature-015.iter-002      9      9    0   5

FULL HISTORY
  feature-016.iter-002 12 SP ##########
  feature-016.iter-001 10 SP ########
  feature-015.iter-002  9 SP #######
  feature-015.iter-001  8 SP ######
  feature-014.iter-001  6 SP ####

ROADMAP
  Phase 2: Developer Experience (current): [#####...........] 38% | declared in-progress | effective in-progress | derived 45/120 SP
  Phase 3: Visibility: [................]  0% | declared queued | effective queued | derived 0/60 SP

PROJECTION
  Active feature remaining: 11 SP | ETA: 5 calendar day(s) | confidence moderate
  Current phase remaining: 75 SP | ETA: 34 calendar day(s) | confidence moderate
  Roadmap remaining: 135 SP | ETA: 60 calendar day(s) | confidence moderate

WARNINGS
  No active dashboard warnings.
```

**How to read this example:**

- **Summary** condenses active feature status, current phase, recent pace, and multi-scope ETA signals into one quick-glance line.
- **ACTIVE WORK** shows what feature is currently in flight, including the derived status, consistent `feature-NNN.iter-MM` naming, and the highlighted current phase.
- **VELOCITY** supplies the story-points-per-calendar-day rate with an explicit sample window (5 iterations, 45 SP across 20 total days) and confidence mapping.
- **RECENT SHIPPED** shows the last shipped iterations as horizontal bars proportional to effort, with closure date context.
- **RECENT ITERATIONS (PLAN VS REALITY)** compares what was planned to what was actually delivered, helping spot consistency issues or team variability.
- **FULL HISTORY** renders all closed iterations as compact horizontal bars so the developer can spot trends without opening a spreadsheet.
- **ROADMAP** uses progress bars, declared/effective status, and the current-phase highlight to show where the project stands against the broader plan.
- **PROJECTION** communicates remaining story points and ETA across active feature, current phase, and roadmap scopes with explicit confidence language.
- **WARNINGS** is a bounded warning list that explains the basis of the dashboard and any limitations so the reader is not misled.

This example assumes a healthy state: complete roadmap, sufficient history, and no malformed records. The dashboard will scale the rendering and emit warnings if records are sparse, incomplete, or missing.

#### Pillar 2: Structured Roadmap Source

- **FR-010**: Specrew MUST introduce a structured roadmap source under `.specrew/roadmap.yml` that describes phases, planned effort, descriptive status context, and the feature groupings used by the dashboard's roadmap view. **Owner role**: Roadmap steward. **Delivery window**: Iteration 1.
- **FR-011**: The dashboard MUST derive shipped roadmap progress from actual recorded feature delivery data rather than requiring users to manually declare shipped totals inside the roadmap file. Phase progress MUST count actual story points from closed iterations even when a listed feature is only partially complete, while preserving an in-progress phase state until the broader feature set is finished. **Owner role**: Roadmap steward. **Delivery window**: Iteration 1.
- **FR-012**: The dashboard and validation surfaces MUST detect materially inconsistent roadmap states, including phase-status declarations that conflict with known shipped work, and MUST direct the maintainer toward reconciliation. **Owner role**: Governance steward. **Delivery window**: Iteration 1.
- **FR-013**: If `.specrew/roadmap.yml` is absent, the dashboard MUST still render its non-roadmap sections and MUST explain how the maintainer can configure roadmap support. **Owner role**: Roadmap steward. **Delivery window**: Iteration 1.
- **FR-014**: Specrew MUST document the roadmap source format, its semantics, and its maintenance expectations in user-facing documentation so the roadmap can be updated without reading implementation code. **Owner role**: Documentation steward. **Delivery window**: Iteration 1.

#### Pillar 3: Color Theme

- **FR-015**: The dashboard MUST use a semantic theme in which shipped/completed work, active/in-progress work, queued/not-started work, blocked/problem states, and repository identity/header information are visually distinguishable. **Owner role**: UX steward. **Delivery window**: Iteration 1.
- **FR-016**: The dashboard's color semantics MUST be defined centrally so future theme adjustments can be made consistently rather than by editing scattered rendering logic. **Owner role**: Maintainability steward. **Delivery window**: Iteration 1.
- **FR-017**: The roadmap view MUST use consistent visual markers for shipped, in-progress, and queued phases so phase state is understandable even during quick scans. **Owner role**: UX steward. **Delivery window**: Iteration 1.
- **FR-018**: The no-color behavior MUST respect explicit user intent, the `NO_COLOR` environment convention, dumb-terminal detection, and non-TTY output, while continuing to produce legible output in non-color contexts. **Owner role**: UX steward. **Delivery window**: Iteration 1.

#### Pillar 4: Auto-Invocation at Iteration-Closeout

- **FR-019**: The iteration-closeout workflow MUST include automatic dashboard generation so the developer receives the "Where we are" view as part of the normal lifecycle rather than by manual reminder alone. **Owner role**: Governance steward. **Delivery window**: Iteration 2.
- **FR-020**: Each post-feature iteration-closeout MUST produce a durable `dashboard.md` artifact under the corresponding iteration record so future readers can inspect what the dashboard reported at closeout time. That artifact is a historical snapshot and MUST NOT be silently regenerated in place later. **Owner role**: Artifact steward. **Delivery window**: Iteration 2.
- **FR-021**: Feature-closeout workflow MUST also support a full dashboard rendering that reflects the feature's contribution to broader roadmap progress and store it as `specs/<feature>/closeout-dashboard.md`. No separate project-level living dashboard artifact is created in v1. **Owner role**: Governance steward. **Delivery window**: Iteration 2.
- **FR-022**: Governance validation MUST emit a soft warning when a post-feature iteration-closeout is missing its required dashboard artifact, while grandfathering historical iterations created before this feature existed. **Owner role**: Validator steward. **Delivery window**: Iteration 2.
- **FR-023**: The addition of dashboard generation MUST compose with the existing boundary discipline without requiring a new boundary type or altering the established boundary naming model. **Owner role**: Governance steward. **Delivery window**: Iteration 2.

#### Pillar 5: User Education

- **FR-024**: The dashboard command help MUST identify `specrew where` as the canonical invocation, `specrew status` as its alias, explain the dedicated script entry point, and explain how to interpret supported flags and modes. **Owner role**: Documentation steward. **Delivery window**: Iteration 2.
- **FR-025**: Specrew MUST add dedicated dashboard documentation explaining the meaning of each section, how to read pace responsibly, when the dashboard appears automatically, and how to maintain its roadmap inputs. **Owner role**: Documentation steward. **Delivery window**: Iteration 2.
- **FR-026**: The README lifecycle guidance MUST explain that the dashboard is part of normal iteration-closeout behavior and summarize the value it provides. **Owner role**: Documentation steward. **Delivery window**: Iteration 2.
- **FR-027**: Public-facing documentation MUST include a representative sample of the dashboard's shape so first-time readers can recognize the experience before they run the command. **Owner role**: Documentation steward. **Delivery window**: Iteration 2.
- **FR-028**: A first-time invocation without roadmap configuration MUST provide an onboarding-quality setup message that points users toward the relevant documentation and does not read like a failure. **Owner role**: Documentation steward. **Delivery window**: Iteration 2.
- **FR-029**: The main Specrew command discovery surface MUST list `specrew where` as the dashboard's canonical command and identify `specrew status` as an alias so users can find it without prior tribal knowledge. **Owner role**: CLI steward. **Delivery window**: Iteration 2.
- **FR-030**: Repository/project-status natural-language requests made to Squad (for example, "show the current project status") MUST route to the same dashboard renderer used by `specrew where` so the conversational and command surfaces stay aligned. Requests asking for other kinds of status MUST remain outside this routing behavior unless they are clearly about repository/project state. **Owner role**: Interaction steward. **Delivery window**: Iteration 2.

#### Cross-Cutting Requirements

- **FR-031**: Specrew's known-traps and validation ecosystem MUST include a dashboard-specific drift case for stale roadmap declarations or other conditions that would make the dashboard materially misleading. **Owner role**: Governance steward. **Delivery window**: Iteration 2.
- **FR-032**: Automated test coverage MUST exercise the dashboard against representative repository states including healthy history, fresh-project history, malformed history, and missing roadmap configuration. **Owner role**: Test steward. **Delivery window**: Iteration 2.
- **FR-033**: The production dashboard MAY evolve from the existing proof of concept, but the shipped feature MUST improve on that proof of concept by supporting structured roadmap input, lifecycle integration, user education, command-surface consistency, and validation/test coverage. **Owner role**: Product steward. **Delivery window**: Iteration 2.

#### Pillar 6: Dashboard Fidelity & Projection Refinements

- **FR-034**: The dashboard MUST render a top summary line that compresses active feature identity, current phase, headline velocity, and multi-scope ETA cues into a single quick-glance sentence. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-035**: The active-work section MUST surface the feature title, derived status, active iteration identifier, planned versus delivered story points, and the iteration start date when available. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-036**: Feature status MUST be derived from canonical artifacts (iteration state, review verdicts, retrospectives, closeout artifacts, and active-feature pointers) rather than the spec frontmatter. **Owner role**: Governance steward. **Delivery window**: Iteration 1.
- **FR-037**: Iteration identifiers MUST use one consistent naming convention across active work, recent shipped, variance, history, and roadmap references (`feature-NNN.iter-MM`). **Owner role**: UX steward. **Delivery window**: Iteration 1.
- **FR-038**: The active iteration's current phase MUST be highlighted in the summary line and active-work section whenever iteration state data is available. **Owner role**: UX steward. **Delivery window**: Iteration 1.
- **FR-039**: The velocity sample window MUST use up to the 10 most recent closed iterations (or fewer when history is sparse) and disclose sample size plus total story-point basis. **Owner role**: Data steward. **Delivery window**: Iteration 1.
- **FR-040**: Velocity confidence MUST map to sample size as follows: 1–3 closed iterations = low, 4–9 = moderate, 10+ = high. The dashboard MUST never claim high confidence with fewer than 10 closed iterations. **Owner role**: Data steward. **Delivery window**: Iteration 1.
- **FR-041**: When derived shipped effort exceeds planned effort for a roadmap phase, the phase MUST surface an explicit `drifted-over` effective status and emit a bounded drift warning. **Owner role**: Governance steward. **Delivery window**: Iteration 1.
- **FR-042**: Roadmap rendering MUST show both declared and effective status for each phase and identify which phase is currently active for the in-flight feature. **Owner role**: Roadmap steward. **Delivery window**: Iteration 1.
- **FR-043**: The projection section MUST provide multiple ETA scopes: active feature, current roadmap phase, and total roadmap, each with remaining effort and ETA text. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-044**: The dashboard MUST compute in-flight remaining effort from planned minus delivered story points and present it explicitly without implying precision when data is missing. **Owner role**: Reliability steward. **Delivery window**: Iteration 1.
- **FR-045**: When velocity inputs are unavailable, the dashboard MUST render projection lines with TBD ETA text and low confidence while still showing remaining-effort totals if they can be derived. **Owner role**: Reliability steward. **Delivery window**: Iteration 1.
- **FR-046**: When roadmap data is missing or partial, the summary line and projection sections MUST degrade gracefully without suppressing the rest of the dashboard. **Owner role**: Reliability steward. **Delivery window**: Iteration 1.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 maps to FR-001 through FR-009, FR-015 through FR-017, FR-030, and FR-034 through FR-046.
- **TG-002**: User Story 2 maps to FR-002, FR-008, FR-010 through FR-014, FR-018, FR-031, and FR-032.
- **TG-003**: User Story 3 maps to FR-019 through FR-030.
- **TG-004**: Any planning work that follows this specification MUST preserve the one-boundary-at-a-time authorization model introduced by Feature 016; this specification does not authorize planning, tasks, or implementation to begin automatically without the next explicit boundary decision.
- **TG-005**: The source draft's deferred policy choices, the command-surface clarification, and the dashboard visual-policy clarification captured on 2026-05-15 are now explicit planning inputs rather than implicit implementation decisions.

### Key Entities *(include if feature involves data)*

- **Dashboard Snapshot**: A bounded summary of project state at a particular invocation or closeout moment, including active work, recent shipped work, pace, roadmap progress, and remaining effort signals; when stored at closeout, it is a historical record rather than a live-updating file.
- **Roadmap Phase Record**: A structured description of one roadmap phase, including its identity, descriptive status context, planned effort, associated feature set, and shipped-effort contribution derived from closed iterations.
- **Feature Delivery Record**: The combined feature-spec, iteration-state, and retrospective evidence used to determine what has shipped and how much effort has been completed.
- **Velocity Sample Window**: The recent slice of delivered work used to summarize project pace for the dashboard.
- **Dashboard Artifact**: The durable iteration-closeout record that captures the rendered dashboard for later inspection.
- **Education Surface**: The help text and written documentation that explain what the dashboard shows and how maintainers keep its inputs accurate.
- **Dashboard Invocation Surface**: The aligned set of entry paths for the dashboard, including `specrew where` as canonical CLI invocation, `specrew status` as alias, the dedicated script entry point, and repository/project-status Squad routing to the same renderer.

## Non-Functional Constraints

- **NFR-001**: Dashboard rendering <= 1.5s on a 16-feature repo; budget calibrated from Iteration 1 empirical measurement.
- **NFR-002**: The dashboard must remain readable in both rich console environments and plain-text capture contexts; visual policy follows FR-004 to ensure monochrome-safe, low-noise rendering.
- **NFR-003**: The feature must stay additive: it should improve visibility without changing unrelated lifecycle behavior.
- **NFR-004**: User-facing warnings and setup messages must be specific, calm, and remediation-oriented rather than opaque or noisy.
- **NFR-005**: The roadmap source must remain forward-compatible with future multi-developer expansion.
- **NFR-006**: Historical iterations created before this feature ships must remain valid even though they lack dashboard artifacts.
- **NFR-007**: The dashboard's visibility signals must avoid encouraging simplistic "velocity as target" misuse by preserving context and uncertainty.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a repository with active and recently shipped work, a developer can explain within 60 seconds what is currently active, what shipped recently, the headline velocity sample basis, the recent plan-versus-reality trend, and the project's broad roadmap position using only the dashboard output.
- **SC-002**: In fixture coverage spanning healthy, sparse, malformed, and no-roadmap states, the dashboard completes without a hard crash in 100% of exercised scenarios.
- **SC-003**: A fresh reviewer can identify shipped, active, and queued status correctly from the dashboard's visual treatment in at least 90% of sample interpretation checks.
- **SC-004**: The first iteration-closeout after this feature ships produces a durable dashboard artifact and includes dashboard content in the closeout handoff without requiring a manual reminder.
- **SC-005**: A new maintainer can add or update a roadmap phase successfully using the written documentation and example format without consulting implementation code.
- **SC-006**: Dashboard-specific validation catches at least one intentionally stale-roadmap fixture as misleading rather than allowing it to pass silently.
- **SC-007**: The dashboard becomes part of normal lifecycle use by appearing in the next real iteration-closeout and feature-closeout flows after the feature is delivered.

## Assumptions

- Specrew will continue to treat feature specs, iteration state, retrospectives, and `.specify/feature.json` as canonical sources for lifecycle state.
- The roadmap will be maintained by humans as a lightweight planning artifact even though shipped progress is derived automatically where possible.
- The dashboard remains console-first for this feature; richer visual or web surfaces belong to later work.
- V1 visual design stays monochrome-safe and low-noise by centering horizontal bars, progress bars, compact tables, and at most one tiny sparkline instead of chart-heavy analytics.
- Natural-language Squad routing is limited to requests that are clearly about current repository/project status so the dashboard remains a trustworthy project-state surface rather than a generic conversational status reply.
- Multi-developer support is intentionally deferred, so this feature only needs a forward-compatible placeholder for team-oriented behavior.
- The proof-of-concept dashboard script is useful as a shaping reference but is not itself the canonical specification.
- Pace and projection calculations use calendar days in v1 so results remain simple to reproduce from repository timestamps.
- Recent story-points-per-day detail, if preserved at all, is a secondary expanded-mode aid rather than a primary v1 visual surface.

## Iteration Breakdown

### Iteration 1 - Core dashboard, roadmap source, semantic theme, and fidelity refinements

- Deliver FR-001 through FR-018 and FR-034 through FR-046.
- Establish the structured roadmap source and the initial dashboard rendering experience.
- Ship the compact view, monochrome fallback, resilient partial-data handling, and future-team placeholder behavior.

### Iteration 2 - Lifecycle integration, education, and validation

- Deliver FR-019 through FR-033.
- Integrate the dashboard into closeout workflows, documentation, discovery surfaces, and validation/test coverage.
- Make the dashboard durable and understandable as part of the normal Specrew method.

## Dependencies

### Hard Dependencies

1. **Feature 013 — Validator Hardening** for additive soft-warning patterns and governance validation structure.
2. **Feature 014 — Handoff Format Scoping** for iteration-closeout handoff structure.
3. **Feature 015 — Public-Readiness Pass** for README and public-facing lifecycle documentation surfaces.
4. **Feature 016 — Substantive Interaction Model** for console-first closeout behavior and single-boundary authorization discipline.

### Forward-Looking Complements

- **Proposal 013 — Methodology Site** may later reuse dashboard snapshots as showcase material.
- **Multi-Developer Reconciliation** will eventually turn the reserved team-oriented dashboard path into a real capability.

## Risks and Mitigations

- **Misleading pace signals**: Developers could over-focus on velocity as a target. **Mitigation**: treat pace as context, keep educational guidance explicit, and preserve uncertainty in projections.
- **Roadmap drift**: Human-maintained roadmap data may diverge from actual shipped state. **Mitigation**: derive shipped progress from real feature evidence where possible and add drift validation.
- **Terminal variability**: Color and rendering may differ across environments. **Mitigation**: use semantic fallbacks and keep monochrome readability first-class.
- **Artifact staleness**: Stored dashboard artifacts may age even though project state changes. **Mitigation**: treat stored dashboard files as explicit historical snapshots of their closeout moment and use ad hoc command reruns for current-state views rather than rewriting the historical record.
- **Scope creep**: Analytics and extra automation could sprawl. **Mitigation**: keep this feature bounded to the five stated pillars and defer extras explicitly.

## Implementation Boundary

The existing proof-of-concept dashboard is a shaping reference, not the final contract. The production feature must preserve the core visibility intent while adding structured roadmap input, lifecycle integration, education surfaces, and validation coverage that the proof of concept does not yet provide.

The implementation phase may refine rendering internals, parsing strategy, and command wiring, but it must not narrow the feature below the five-pillar scope captured here.

## Cross-References

- `file:///C:/Dev/SpecrewDraft/velocity-dashboard.md` — authoritative source intent for Feature 017.
- `file:///C:/Dev/Specrew/proposals/009-velocity-dashboard.md` — public framing reference and roadmap placement.
- `file:///C:/Dev/SpecrewDraft/specrew-where-poc.ps1` — proof-of-concept dashboard reference.
- `file:///C:/Dev/Specrew-017/.specify/feature.json` — active-feature pointer updated by this specify boundary.

## Clarification Resolution Log

This clarification boundary is complete. The prior deferred policy choices, command-surface decisions, and the v1 dashboard visual-policy clarification added on 2026-05-15 were integrated into this specification under `## Clarifications` and the affected requirement, scenario, success-criteria, and assumption sections.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Feature 017 spec steward on behalf of the Specrew governance workflow.
- **Iteration Facilitator**: The Squad + human-review pair operating the standard Specrew iteration lifecycle.
- **Capacity Model**: Story-point-based delivery over two bounded iterations (~11 SP then ~8 SP, ~19 SP total).
- **Drift Signals**: Validator warnings, stale roadmap detection, missing dashboard artifact detection, and mismatch between dashboard output and canonical lifecycle records.
- **Human Oversight Points**: Clarification is complete for the deferred policy questions; planning authorization was granted at the Feature 017 planning boundary on 2026-05-15; implementation repairs proceed under explicit human request; the next oversight point is the review boundary.
