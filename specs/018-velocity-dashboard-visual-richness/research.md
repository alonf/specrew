# Research: Velocity Dashboard Visual Richness + PoC-Parity Restoration

## Decision 1: Keep one shared renderer and enrich it rather than introducing parallel rich/fallback implementations

**Decision**: Extend the existing dashboard renderer in `scripts/internal/dashboard-renderer.ps1` so the
same snapshot assembly and section ordering drive rich-mode output, monochrome fallback, and stored
snapshot artifacts.

**Rationale**: Feature 017 already established one trusted dashboard pipeline shared by `specrew where`,
`specrew status`, the dedicated script entry point, and closeout artifact generation. Reusing that path
preserves behavioral parity and lowers drift risk while keeping this feature inside the approved
presentation-only scope.

**Alternatives considered**:

- A separate rich-mode renderer — rejected because it would duplicate section logic and increase drift risk.
- Rich-only formatting injected at write time — rejected because stored artifacts and tests also need the
  same semantic model.

## Decision 2: Rich mode defaults on only when terminal eligibility is explicit and fallback remains the always-safe path

**Decision**: Rich mode will be the default only when the dashboard detects a capable environment:
interactive output, UTF-8-safe rendering, Unicode not explicitly disabled, and ANSI emphasis support when
needed. The renderer must honor `--ASCII`, `NO_COLOR`, `NO_UNICODE`, dumb terminals, redirected output,
and missing Windows virtual-terminal support by falling back cleanly.

**Rationale**: The spec explicitly requires rich-by-default behavior without sacrificing compatibility.
The current Feature 017 implementation already centralizes color-mode decisions, so the safest upgrade is
to widen capability detection rather than assume every console can render Unicode blocks and ANSI safely.

**Alternatives considered**:

- Always render rich mode unless `--ASCII` is set — rejected because non-TTY and incompatible hosts would
  emit broken or misleading output.
- Never render rich mode by default — rejected because the clarified requirement explicitly wants rich mode
  when the host is eligible.

## Decision 3: Use Unicode blocks, semantic markers, and horizontal rules in rich mode, but preserve ASCII-only substitutes for comprehension

**Decision**: Rich mode will use Unicode block characters (`█`, `░`), a velocity sparkline made from
block elements (`▁▂▃▄▅▆▇█`), status markers (`✓`, `◐`, `○`), the active-feature arrow (`→`), bold/ANSI
emphasis where supported, and horizontal rules (`─`). Monochrome mode will keep ASCII-safe bars, plain
markers, and no ANSI dependence while preserving the same meaning and section order.

**Rationale**: The approved pillars explicitly call for richer primitives and PoC-parity density, but
Feature 017 compatibility remains a product requirement. The best fit is an additive two-presentation
model where rich mode adds visual density and fallback keeps every state understandable without Unicode or
color.

**Alternatives considered**:

- Color-only enhancement without Unicode glyphs — rejected because it would miss the approved visual
  richness goal and remain weaker for screenshots/readability.
- Unicode-only enhancement without ASCII substitutes — rejected because fallback comprehension would fail.

## Decision 4: Restore PoC-parity density through bounded CLI knobs, not broader analytics expansion

**Decision**: Restore the Today/Captured anchors, roadmap descriptions, bold section framing, explicit
empty states, richer Recent Shipped rows, velocity sample-basis text, and the active-feature arrow while
adding only two bounded operator knobs: `--RecentCount N` (default 6) and `--BarWidth N` (default 28).

**Rationale**: The spec requires higher information density but explicitly defers broader analytical
changes such as new velocity-window controls or projection-model changes. Default count and width knobs
preserve PoC scanning density without expanding the feature into a new analytics or configuration project.

**Alternatives considered**:

- Add multiple new dashboard tuning parameters — rejected because the approved scope intentionally excludes
  broader configurability.
- Hardcode every density choice with no override — rejected because the spec explicitly approves Recent
  Count and Bar Width overrides.

## Decision 5: Confine the sparkline to the Velocity section and keep it subordinate to the numeric headline

**Decision**: Add exactly one sparkline to the Velocity section, derived from recent closed-iteration
pace values and rendered after the numeric summary/sample basis. No other dashboard section receives a
new chart or secondary graph.

**Rationale**: The spec authorizes a single bounded new visualization beyond PoC parity and names the
Velocity section as its only valid home. Keeping it subordinate to the headline pace summary reinforces
that the dashboard remains explanatory rather than chart-heavy.

**Alternatives considered**:

- Add sparklines to Recent Shipped or Full History — rejected because that exceeds the approved scope.
- Replace the numeric summary with the sparkline — rejected because the spec requires the sparkline to
  remain secondary.

## Decision 6: Persist stored dashboards with ANSI stripped but Unicode preserved

**Decision**: Closeout snapshot artifacts will continue to store rendered dashboard text inside Markdown,
but the persisted content must remove ANSI escape sequences while preserving Unicode glyphs and section
semantics.

**Rationale**: Stored snapshots are historical evidence that may be reviewed in Markdown viewers, plain
text editors, or CI artifacts. ANSI codes create noisy, unreadable artifacts there, while Unicode glyphs
still improve clarity when preserved correctly.

**Alternatives considered**:

- Persist raw ANSI-colored output — rejected because artifact readability and portability would degrade.
- Downgrade stored snapshots all the way to ASCII — rejected because the spec explicitly allows Unicode to
  remain even after ANSI is stripped.

## Decision 7: Treat encoding consistency and regression replay as first-class validation surfaces

**Decision**: Extend the existing Feature 017 dashboard replay harness with dedicated rich-mode and
monochrome-mode fixtures, verify UTF-8 without BOM plus LF line endings for text fixtures/artifacts, and
keep the existing Feature 017 unit/integration suite green.

**Rationale**: This feature is primarily presentational, so regressions will show up in rendered text and
fixture snapshots more than in data-model changes. The existing PowerShell fixture harness is already the
repository's trusted contract lane for dashboard behavior, making it the right place to prove additive
richness and fallback safety.

**Alternatives considered**:

- Manual visual review only — rejected because the spec requires durable regression coverage.
- Introduce a new snapshot-testing framework outside PowerShell — rejected because the current harness is
  already aligned with the repository's CLI/governance toolchain.
