# Research: Velocity Dashboard

## Decision 1: Use one shared dashboard renderer for all project-status surfaces

**Decision**: Implement a single PowerShell dashboard renderer shared by `specrew where`, the
`specrew status` alias, a dedicated script entry point, and repository/project-status Squad routing.

**Rationale**: The spec requires equivalent content across command and conversational project-status
surfaces. The existing repository already uses switch-based command dispatch in `scripts/specrew.ps1`
and PowerShell script entry points, so adding one renderer behind multiple entry paths preserves
behavioral parity instead of duplicating formatting logic.

**Alternatives considered**:

- Separate renderers for CLI and conversational routing — rejected because drift between outputs
  would undermine trust.
- Alias-only support without a dedicated script — rejected because the spec explicitly reserves a
  dedicated script entry point.

## Decision 2: Keep rendering console-first with ASCII-safe bars, compact tables, and fixed compact mode

**Decision**: Use plain-text/ASCII-first horizontal bars, progress bars, compact tables, and at
most one tiny sparkline. Compact mode is a fixed 24-line summary that preserves header, active work,
velocity, recent shipped work, recent variance, roadmap status, and projection/warning context.

**Rationale**: The feature is explicitly console-first, monochrome-safe, and low-noise. ASCII-safe
rendering minimizes terminal compatibility risk and transcript capture issues, while the fixed
24-line budget keeps closeout handoffs consistent and testable.

**Alternatives considered**:

- Unicode-heavy or color-dependent charts — rejected because they degrade in monochrome and non-TTY
  contexts.
- Configurable compact line budgets — rejected because the spec clarifies a fixed v1 budget.
- Burndowns, scatterplots, pie charts, or dense daily graphs — rejected by FR-004 and the clarified
  visual-policy decisions.

## Decision 3: Treat color as optional and explicitly suppressible

**Decision**: Centralize dashboard theme semantics and honor explicit no-color intent, `NO_COLOR`,
dumb-terminal detection, and non-TTY output before using semantic colors.

**Rationale**: The repo currently uses direct PowerShell foreground-color calls in multiple scripts,
but the dashboard needs a predictable, testable policy that preserves meaning when color is absent.
Centralizing the decision keeps future theme changes coherent and prevents scattered rendering logic.

**Alternatives considered**:

- Always render with color when the host supports it — rejected because explicit user and environment
  intent must take precedence.
- No color support at all — rejected because semantic highlighting is still useful in capable
  terminals.

## Decision 4: Use `.specrew/roadmap.yml` as a manual planning source with automatically derived shipped progress

**Decision**: Add `.specrew/roadmap.yml` with a phase-based schema that stores human-maintained
phase metadata (`id`, `name`, `description`, `planned_effort_sp`, `status`, ordered feature refs)
while deriving shipped effort from closed iteration history instead of manual shipped totals.

**Rationale**: The roadmap must remain human-maintainable and forward-compatible, but FR-011
forbids manually declared shipped totals as the source of truth. A light YAML schema paired with
derived shipped progress preserves traceability to canonical feature/iteration records and supports
future expansion without inventing a new database-like artifact.

**Alternatives considered**:

- Manual shipped totals inside the roadmap file — rejected because they create misleading drift.
- A separate central velocity ledger — rejected because it duplicates data already present in
  canonical iteration artifacts.
- Featureless phase descriptions with no refs — rejected because traceability would be lost.

## Decision 5: Detect roadmap drift and missing dashboard artifacts as bounded governance warnings

**Decision**: Extend validator/known-traps coverage to emit soft warnings for materially inconsistent
roadmap states, missing required post-feature `dashboard.md` snapshots, and other dashboard-specific
misleading conditions.

**Rationale**: The spec requires dashboard trustworthiness without turning the roadmap into a brittle
blocker for every workflow. The existing repo already uses validator-driven governance checks and
known-traps documentation, so soft warnings are the right additive mechanism for drift visibility.

**Alternatives considered**:

- Hard-fail validation for every roadmap inconsistency — rejected because the roadmap is a planning
  aid and should degrade gracefully.
- No drift checks — rejected because silent misleading output would violate the constitution and
  FR-012 / FR-031.

## Decision 6: Store immutable closeout snapshots beside iteration and feature artifacts

**Decision**: Generate `specs/<feature>/iterations/<NNN>/dashboard.md` at iteration closeout and
`specs/<feature>/closeout-dashboard.md` at feature closeout, both marked as historical snapshots and
never silently regenerated in place.

**Rationale**: The clarified spec explicitly distinguishes live reruns from stored closeout
artifacts. Co-locating snapshots with the relevant feature/iteration records matches existing
artifact conventions and avoids introducing a mutable top-level "current dashboard" file that could
drift from closeout history.

**Alternatives considered**:

- A single live `.specrew/where-we-are.md` file — rejected by clarified scope and because it would
  create a second mutable truth surface.
- Rewriting historical dashboard artifacts on rerun — rejected because it destroys closeout-time
  truth.

## Decision 7: Verify the feature through deterministic PowerShell fixture coverage

**Decision**: Cover the dashboard with PowerShell integration/unit-style tests that exercise healthy,
fresh-project, malformed-history, missing-roadmap, compact-mode, no-color, and team-fallback cases.

**Rationale**: The repo already uses PowerShell replay-style integration scripts and optional
ScriptAnalyzer checks. Extending that deterministic harness is lower-risk and more consistent than
introducing a new test runner or relying on manual inspection alone.

**Alternatives considered**:

- Manual validation only — rejected because the spec requires durable trust and non-crashing
  behavior.
- A new JS/TS test harness — rejected because the existing PowerShell workflow already covers this
  repository's automation surfaces.
