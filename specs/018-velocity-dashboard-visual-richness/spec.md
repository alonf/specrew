# Feature Specification: Velocity Dashboard Visual Richness + PoC-Parity Restoration

**Feature Branch**: `018-velocity-dashboard-visual-richness`  
**Created**: 2026-05-15  
**Status**: Approved  
**Input**: User description: "Velocity Dashboard Visual Richness + PoC-Parity Restoration"

## Clarifications

### Session 2026-05-15

- Q: Release versioning for this follow-up? → A: Ship as v0.18.0 as a new feature release.
- Q: What is the default rendering mode? → A: Use rich rendering by default with a `--ASCII` opt-out.
- Q: What terminal capability detection policy governs rich rendering? → A: Require UTF-8-capable output plus ANSI support, honor `--ASCII` and `$env:NO_UNICODE`, use `$env:LANG` on Linux/macOS, and fall back gracefully when Windows virtual terminal support is unavailable.
- Q: How many entries appear in Recent Shipped by default? → A: Show 6 entries by default and allow override with `--RecentCount N`.
- Q: What is the default rich-mode bar width? → A: Use a 28-character bar by default and allow override with `--BarWidth N`.
- Q: Where does the sparkline appear? → A: Render the sparkline only in the Velocity section.
- Q: How should lengthy roadmap phase descriptions render? → A: Show the description line for every phase and truncate only beyond 80 characters with `...`.
- Q: How should the header show time context? → A: Show both `Today: YYYY-MM-DD` and `Captured: {ISO-timestamp}` on the header context line.
- Q: Where should the active-feature arrow indicator appear? → A: Use the arrow as a prefix before the active feature label.
- Q: How should stored closeout dashboard snapshots render rich output? → A: Strip ANSI escape sequences in stored snapshots while preserving Unicode glyphs.
- Q: Are empty-state messages configurable? → A: Keep empty-state messages fixed and non-configurable in this feature.
- Q: What are the Windows compatibility rules for richer semantic emphasis? → A: Use ANSI emphasis only when `$Host.UI.SupportsVirtualTerminal` is true and otherwise fall back gracefully.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read a richer dashboard at a glance (Priority: P1)

A developer can open the Velocity Dashboard and immediately understand current work, recent shipped work, velocity context, roadmap progress, and footer guidance through a visually richer console presentation that restores the information density proven useful in the earlier proof of concept.

**Why this priority**: The feature exists to improve first-impression clarity and screenshot quality without changing lifecycle behavior. If the richer dashboard is not immediately more readable than Feature 017, the follow-up does not deliver its purpose.

**Independent Test**: Render the dashboard in a rich-capability terminal using representative project history and verify that a reviewer can identify the active feature, recent shipped items, velocity trend, roadmap phase details, and section boundaries from one screen without consulting supporting artifacts.

**Acceptance Scenarios**:

1. **Given** a repository with an active feature, recent shipped features, and roadmap data, **When** the developer views the dashboard in a rich-capability terminal, **Then** the dashboard uses richer visual primitives, richer semantic emphasis, restored information surfaces across the header, Active Work, Recent Shipped, Velocity, Roadmap, and Footer, and one velocity sparkline.
2. **Given** a repository whose roadmap phases include descriptive text, **When** the developer views the roadmap section, **Then** each rendered phase includes both its progress summary and its human-readable description so the roadmap is understandable without opening the roadmap source file.
3. **Given** a repository with no active feature or no recently shipped features, **When** the developer views the dashboard, **Then** the affected sections render explicit empty-state guidance instead of leaving silent gaps.

---

### User Story 2 - Trust the dashboard across terminal capabilities (Priority: P1)

A developer can trust the dashboard to stay readable in both rich and monochrome environments, preserving Feature 017's compatibility guarantees while upgrading the richer presentation where supported.

**Why this priority**: The follow-up must not trade accessibility or compatibility for visual polish. Rich rendering only creates value if the fallback remains dependable and understandable.

**Independent Test**: Render the dashboard once in a rich-capability environment and once in a monochrome-safe environment, then verify that both outputs preserve the same core meaning, with the rich mode adding denser presentation and the fallback remaining plain, readable, and free of unintended color or symbol dependence.

**Acceptance Scenarios**:

1. **Given** a rich-capability terminal, **When** the dashboard renders, **Then** it may use Unicode block elements, richer semantic emphasis, status markers, and a sparkline while preserving the same section order and meaning established by Feature 017.
2. **Given** a monochrome-restricted or non-rich environment, **When** the dashboard renders, **Then** it falls back to ASCII-safe, monochrome-safe output with substitute markers and without losing the underlying status information.
3. **Given** an existing Feature 017 dashboard workflow, **When** this feature is introduced, **Then** the dashboard's lifecycle triggers, behavioral boundaries, and closeout semantics remain unchanged because this feature is limited to presentation-layer enrichment plus corresponding validation and documentation updates.

---

### User Story 3 - Adopt the richer view without regressions (Priority: P2)

A product steward can adopt the richer dashboard knowing that existing Feature 017 behavior, fixture coverage, and rendering performance remain within the established budget for a moderately sized repository.

**Why this priority**: The change is intentionally a single-iteration follow-up. It must prove that richer presentation can land without reopening lifecycle scope, breaking prior tests, or slowing the dashboard beyond the agreed rendering budget.

**Independent Test**: Execute the existing dashboard validation suite plus new rich-mode and monochrome-mode fixtures on a representative repository and confirm that the full dashboard still renders within the existing time budget.

**Acceptance Scenarios**:

1. **Given** the existing Feature 017 validation suite, **When** the richer dashboard is introduced, **Then** all previously valid dashboard behaviors continue to pass and remain semantically intact.
2. **Given** dedicated rich-mode and monochrome-mode fixtures, **When** the validation suite runs, **Then** the richer surfaces, fallback substitutions, roadmap descriptions, and sparkline behavior are each verified explicitly.
3. **Given** a repository with 16 features of representative history, **When** the dashboard renders, **Then** the richer presentation completes within the established 1.5 second rendering budget.

---

### Edge Cases

- The repository may have no active feature; the Active Work section must show an explicit empty state rather than a blank gap.
- The repository may have no recently shipped features; the Recent Shipped section must explain that there is no shipped history yet.
- The repository may not have enough closed iteration history to support a meaningful velocity trend; the Velocity section must explain the insufficiency instead of implying a misleading trend.
- The roadmap may be absent or partially populated; the dashboard must preserve other sections and explain the missing roadmap context clearly.
- Rich-mode symbols may not be appropriate in some terminal contexts; the fallback mode must preserve meaning with ASCII-safe substitutes.
- Long phase descriptions, feature names, or identifiers may exceed the preferred line width; the dashboard must remain readable without obscuring the section's meaning.
- A repository may include equal or near-equal recent velocity samples; the sparkline must still communicate a stable trend rather than appearing broken.
- Stored closeout dashboard snapshots may be reviewed in Markdown or plain text; persisted output must strip ANSI escape sequences while preserving readable Unicode glyphs.

## Requirements *(mandatory)*

### Functional Requirements

#### Scope and Follow-up Discipline

- **FR-001**: The feature MUST remain a single-iteration, presentation-layer follow-up to Feature 017 and MUST NOT change dashboard lifecycle triggers, closeout behavior, or broader workflow boundaries. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-002**: The feature MUST focus on five pillars only: richer visual primitives, restored PoC-parity information density, one velocity sparkline addition beyond PoC parity, backward-compatible validation coverage, and documentation updates. **Owner role**: Spec steward. **Delivery window**: Iteration 1.
- **FR-003**: The following items MUST remain out of scope for this feature: working-days projection, MVP-versus-1.0 two-horizon distinction, minimum-days velocity window stretching, bootstrapped-date anchor changes that require session-state schema updates, and configurable velocity sample windowing. **Owner role**: Product steward. **Delivery window**: Iteration 1.

#### Pillar 1: Visual Primitives

- **FR-004**: The dashboard MUST provide a richer rendering mode for capable terminals that upgrades Feature 017's ASCII-first appearance with denser visual primitives, fuller semantic emphasis, bold section labeling, clearer section separation, active-feature emphasis, and status markers for shipped, active, and queued roadmap states. When rich-mode output is persisted into stored closeout dashboard snapshots, ANSI escape sequences MUST be stripped while readable Unicode glyphs are preserved. **Owner role**: UX steward. **Delivery window**: Iteration 1.
- **FR-005**: The dashboard MUST run in rich mode by default when terminal capability checks indicate eligibility, and MUST preserve a monochrome-safe fallback that communicates the same meaning as the richer mode by using ASCII-safe bars, substitute status markers, and no dependency on color or Unicode-only glyphs for comprehension. Eligibility MUST honor `--ASCII` and `$env:NO_UNICODE`, use UTF-8-capable output detection plus `$env:LANG` on Linux/macOS, require `$Host.UI.SupportsVirtualTerminal` for Windows ANSI emphasis, and fall back gracefully when those conditions are not met. Empty-state guidance introduced by this feature MUST remain fixed rather than user-configurable. **Owner role**: UX steward. **Delivery window**: Iteration 1.

#### Pillar 2: PoC-Parity Information Density

- **FR-006**: The header MUST provide both immediate identity context and temporal context, including a human-readable `Today: YYYY-MM-DD` anchor, a `Captured: {ISO-timestamp}` value, and a clear visual separation from the rest of the dashboard. **Owner role**: CLI steward. **Delivery window**: Iteration 1.
- **FR-007**: The Active Work section MUST highlight the active feature more clearly than Feature 017 by using the active-feature arrow indicator as a prefix before the active feature label, include iteration-state context, and show a fixed explicit empty-state message when no active feature is set. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-008**: The Recent Shipped section MUST restore denser shipped-history scanning by showing feature-oriented identifiers, 28-character visual completion bars by default, delivered story-point totals, iteration counts, close dates, readable short names, and a fixed explicit empty state when shipped history is unavailable. The section MUST show 6 entries by default and allow operator overrides through `--RecentCount N` and `--BarWidth N`. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-009**: The Velocity section MUST preserve the headline pace summary from Feature 017 while also showing the sample basis used for that summary and a fixed clear explanation when there is insufficient history to support the calculation. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-010**: Existing Feature 017 sections for plan-versus-reality, full-history trajectory, projection, and warnings MUST remain present and behaviorally consistent, with this feature limited to visual-enrichment follow-up rather than analytical-scope expansion. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-011**: The Roadmap section MUST render per-phase status markers, progress summaries, phase names, and the roadmap phase description field so that roadmap intent is visible directly in the dashboard. Each phase description MUST render on its own detail line and only truncate when it exceeds 80 characters, using `...` to indicate truncation. **Owner role**: Roadmap steward. **Delivery window**: Iteration 1.
- **FR-012**: The Footer MUST include a visually separated concluding note that preserves Feature 017's orienting guidance while matching the richer presentation style of the rest of the dashboard. **Owner role**: UX steward. **Delivery window**: Iteration 1.

#### Pillar 3: Velocity Sparkline

- **FR-013**: The Velocity section MUST add exactly one new visualization beyond PoC parity: a compact sparkline that appears only in the Velocity section, communicates recent delivered-pace trend using a denser graphical vocabulary, and remains subordinate to the numeric pace summary. **Owner role**: Product steward. **Delivery window**: Iteration 1.
- **FR-014**: The sparkline MUST be derived from recent closed-iteration pace values and MUST degrade gracefully in monochrome-safe contexts without changing the underlying velocity meaning. **Owner role**: UX steward. **Delivery window**: Iteration 1.

#### Pillar 4: Backward Compatibility and Validation

- **FR-015**: All existing Feature 017 dashboard tests and accepted behaviors MUST continue to pass after this feature lands. **Owner role**: Reliability steward. **Delivery window**: Iteration 1.
- **FR-016**: The validation suite MUST gain dedicated rich-mode fixtures that verify the richer primitives, denser information surfaces, roadmap descriptions, and velocity sparkline. **Owner role**: Test steward. **Delivery window**: Iteration 1.
- **FR-017**: The validation suite MUST gain dedicated monochrome-mode fixtures that verify ASCII-safe fallback rendering, substitute markers, and absence of rich-mode-only dependence for comprehension. **Owner role**: Test steward. **Delivery window**: Iteration 1.
- **FR-018**: The richer dashboard MUST preserve Feature 017's rendering performance budget and complete within 1.5 seconds on a representative 16-feature repository. **Owner role**: Reliability steward. **Delivery window**: Iteration 1.

#### Pillar 5: Documentation

- **FR-019**: User-facing dashboard documentation MUST be updated so developers can understand the richer presentation, the fallback behavior, the `--ASCII`, `--RecentCount N`, and `--BarWidth N` controls, the Unicode and ANSI eligibility rules, the stored-snapshot ANSI stripping policy, and the new validation expectations without reading source code. **Owner role**: Documentation steward. **Delivery window**: Iteration 1.
- **FR-020**: Dashboard documentation updates MUST cover the dashboard guide, top-level product guidance where dashboard claims appear, and the manual quickstart used to validate the dashboard experience by hand. **Owner role**: Documentation steward. **Delivery window**: Iteration 1.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User story coverage MUST trace as follows: Story 1 maps to FR-004 and FR-006 through FR-013; Story 2 maps to FR-001, FR-005, FR-010, FR-014, and FR-017; Story 3 maps to FR-015 through FR-020.
- **TG-002**: Every functional requirement in this feature identifies an expected owner role inline to preserve stewardship clarity.
- **TG-003**: Every functional requirement in this feature identifies Iteration 1 as its intended delivery window, reinforcing the single-iteration scope boundary.
- **TG-004**: Any implementation discovered to alter lifecycle behavior, closeout semantics, or broader analytical scope beyond the five pillars MUST be treated as drift against this specification and reconciled before work continues.

### Key Entities *(include if feature involves data)*

- **Dashboard Surface**: A named section of the Velocity Dashboard, including Header, Active Work, Recent Shipped, Velocity, Plan vs Reality, Full History, Roadmap, Warnings, and Footer.
- **Rendering Mode**: The presentation style used for the same dashboard meaning, including a richer mode for capable terminals and a monochrome-safe fallback mode.
- **Velocity Sample**: The recent closed-iteration pace history that supports the numeric velocity summary and the compact sparkline.
- **Roadmap Phase Summary**: The dashboard-ready view of a roadmap phase, including its status, progress, name, and human-readable description.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In stakeholder review, readers can identify the active feature, recent shipped history, current velocity context, roadmap phase intent, and footer guidance from one dashboard view without opening additional artifacts first.
- **SC-002**: The richer dashboard renders within 1.5 seconds or less on a representative repository containing 16 features of project history.
- **SC-003**: All previously accepted Feature 017 dashboard validations continue to pass after this follow-up is introduced.
- **SC-004**: Rich-mode and monochrome-mode validation fixtures both pass and together verify the five pillars without requiring lifecycle changes.
- **SC-005**: Dashboard documentation is sufficient for a new reviewer to understand the richer view and the fallback mode without reading implementation code.

## Assumptions

- This feature extends the shipped Feature 017 dashboard rather than replacing it with a new workflow or artifact model.
- The underlying project records used by Feature 017 remain the canonical source for active work, shipped history, velocity, and roadmap context.
- Richer presentation is valuable only if the same core dashboard meaning remains available in monochrome-safe environments.
- The PoC serves as a shaping reference for information density and visual richness, while this feature remains free to improve on it in bounded ways such as the velocity sparkline.
- This follow-up targets v0.18.0 as a new feature release rather than a patch hotfix because it adds new presentation capability and validation scope.
- Documentation, fixtures, and performance validation are part of the feature scope even though this `/speckit.specify` boundary only creates the specification artifacts.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Spec Steward for Specrew, requested by Alon Fliess, owns specification integrity for this follow-up.
- **Iteration Facilitator**: Product steward coordinates the single Iteration 1 delivery and guards against scope expansion beyond presentation-layer follow-up.
- **Capacity Model**: One implementation iteration sized for a bounded presentation-layer enhancement to the shipped dashboard.
- **Drift Signals**: Lifecycle behavior changes, added analytics beyond the five pillars, loss of fallback readability, regression of Feature 017 tests, or breach of the 1.5 second rendering budget indicate drift.
- **Human Oversight Points**: Clarification decisions are now recorded in this spec, with further review reserved for implementation planning and pre-release confirmation of visual parity, fallback behavior, and performance.
