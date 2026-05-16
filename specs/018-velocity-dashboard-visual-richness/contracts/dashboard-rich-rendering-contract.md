# Contract: Dashboard Rich Rendering Surface

## Purpose

Define the Feature 018 rendering behavior shared by the dashboard's live CLI surfaces.

## Invocation Surfaces

The following surfaces must continue to resolve to the same underlying dashboard semantics:

| Surface | Canonical | Required Behavior |
| --- | --- | --- |
| `specrew where` | yes | Render the full enriched dashboard |
| `specrew status` | no (alias) | Remain behaviorally equivalent to `specrew where` |
| `scripts/specrew-where.ps1` | no | Invoke the same renderer and option contract |

## Required Flags

| Flag | Default | Contract |
| --- | --- | --- |
| `--ASCII` | off | Force monochrome/ASCII-safe fallback rendering |
| `--no-color` | off | Disable ANSI emphasis |
| `--RecentCount N` | `6` | Control Recent Shipped entry count without changing the underlying data set |
| `--BarWidth N` | `28` | Control the width of rich-mode shipped bars |

## Rendering Rules

- Rich mode is the default only when terminal capability checks indicate eligibility.
- Monochrome fallback must remain readable and semantically equivalent.
- The Velocity section is the only location where a sparkline may appear.
- Recent Shipped rows must show richer shipped-history density, including feature-oriented labeling,
  bar visualization, iteration-count context, and close date.
- Roadmap rows must include status markers, progress summary, phase name, and a description line.
- The active feature must be visually emphasized with the active-feature arrow in rich mode.

## Capability / Fallback Rules

- `--ASCII` always forces fallback.
- `NO_COLOR`, `NO_UNICODE`, dumb terminals, redirected output, and missing required host capability
  must prevent rich rendering.
- Windows ANSI emphasis requires `$Host.UI.SupportsVirtualTerminal`.
- Linux/macOS capability detection must respect UTF-8-capable output and locale signals such as `LANG`.

## Empty-State Rules

- Missing active work must render an explicit fixed empty-state message.
- Missing shipped history must render an explicit fixed empty-state message.
- Insufficient velocity history must render an explicit fixed explanation.
- Missing roadmap context must preserve other sections and render bounded guidance.

## Compatibility Rules

- Feature 017 lifecycle triggers, closeout behavior, and command ordering remain unchanged.
- All existing Feature 017 dashboard tests must continue to pass.
- Rich mode adds density only; it must not change the underlying dashboard meaning.
