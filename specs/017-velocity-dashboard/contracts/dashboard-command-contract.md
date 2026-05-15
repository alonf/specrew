# Contract: Dashboard Command Surface

## Purpose

Define the user-facing behavior shared by all Velocity Dashboard invocation surfaces.

## Supported Invocation Surfaces

| Surface | Canonical | Required Behavior |
| --- | --- | --- |
| `specrew where` | yes | Render the full dashboard using canonical repository records |
| `specrew status` | no (alias) | Render behaviorally equivalent output to `specrew where` |
| `scripts/specrew-where.ps1` | no | Invoke the same renderer used by the CLI dispatcher |
| Repository/project-status Squad routing | no | Route clearly project-scoped status requests to the same renderer |
| `--Team` path | reserved | Explain that team mode is not yet available, then render the personal dashboard |

## Required Inputs

- Active feature pointer from `.specify/feature.json`
- Feature specs and relevant iteration/retro artifacts under `specs/`
- Structured roadmap input from `.specrew/roadmap.yml` when present
- Terminal/environment signals for color and TTY behavior

## Output Contract

All supported invocation surfaces must preserve this ordered section model:

1. Top summary line (active feature, phase, velocity, ETA cues)
2. Repository identity context
3. Active work
4. Velocity headline with explicit sample basis
5. Recently shipped work
6. Recent iterations plan-vs-reality table
7. Full-history iteration summary bar chart
8. Roadmap progress
9. Remaining effort and projection (multi-scope ETA)
10. Data quality or setup guidance

## Rendering Constraints

- Console-first only; no browser or HTML output in v1
- Monochrome-safe and low-noise
- Use horizontal bars, progress bars, compact tables, and at most one tiny sparkline
- Compact mode is fixed at a maximum of 24 lines
- Burndowns, pie charts, scatterplots, and dense daily charts are forbidden in v1
- Iteration identifiers must follow `feature-NNN.iter-MM` across shipped, variance, and history lines

## Color Contract

The renderer must use semantic color only when appropriate and must fall back to readable monochrome
when any of the following applies:

- explicit `--NoColor` / `--no-color`
- `NO_COLOR` environment variable
- dumb-terminal detection
- non-TTY output

## Failure / Degradation Contract

- Missing roadmap file must not block other dashboard sections.
- Missing or malformed artifacts must emit bounded warnings and partial rendering.
- No closed features/history must produce an explanatory empty-state message, not a failure.
- The renderer must not crash or return an empty dashboard solely because one source artifact is unusable.

## Compatibility Rules

- `specrew where` is the canonical discovery/help surface.
- `specrew status` remains an alias for discoverability.
- Conversational routing is limited to repository/project-status requests; unrelated status prompts do
  not automatically invoke the dashboard.
