---
proposal: 047
title: Project Governance Profile (Init-Time Preference Capture)
status: candidate
phase: phase-2
estimated-sp: 20
discussion: tbd
---

# Project Governance Profile (Init-Time Preference Capture)

## Why

Every authorization paste to Squad today repeats the same governance dials: how many autonomous repair cycles before halting, validator severity, push frequency, scope drift tolerance, wall-clock budgets. The dials are stable per-project — what's right for a research-stage feature is different from what's right for a production hardening pass — but the friction of re-specifying them in every authorization erodes the methodology's ergonomics.

Concrete recent example: during F-020 Iteration 2 (night of 2026-05-18), the user introduced an autonomous-repair budget mid-flight (3 cycles before surfacing) because Squad's default was either "stop on first failure" (too tight, forced round-trips) or "repair indefinitely" (too loose, risked F-019-style 22-iteration cascades). The right policy turned out to be neither default — it was a 3-cycle bounded budget that needed to be specified in the authorization. That preference should have lived in `.specrew/config.yml` from `specrew init`, not been negotiated mid-iteration.

This proposal captures governance preferences at init time, persists them in the project config, and lets them flow into every authorization without re-specification. Squad reads the project profile as governance policy by default; authorization pastes only need to deviate when overriding.

## What

### Four-surface model

Each surface has a distinct best-use:

| Surface | Best use | Example |
|---|---|---|
| `specrew init` interactive prompts | First-time setup, all dials at once | Walk user through defaults during bootstrap |
| `specrew init --<flag>` non-interactive | Automation, CI, dotfile-driven setup | `specrew init --repair-budget 5 --use-defaults` |
| `specrew start --<flag>` session override | Temporary deviation from configured defaults | `specrew start --repair-budget 1` |
| `specrew config` standalone CLI | Inspect, change, reset, export/import | `specrew config repair-budget 5` |
| `/specrew.config` slash command | View/edit from inside Squad session | `/specrew.config repair-budget 5` (depends on 032) |

### Precedence chain

```
session flag (--repair-budget 1)
  → env var (SPECREW_REPAIR_BUDGET=2)
    → project config (.specrew/config.yml: repair_budget: 5)
      → module default (shipped: 3)
```

Higher in the chain wins. Standard CLI tool pattern (`git config`, `npm config`).

### Initial dial catalog (10 dials for v1)

| Dial | Default | Range / Values | Notes |
|---|---|---|---|
| `repair_budget` | 3 | 1–10 | Autonomous repair cycles before halting |
| `repair_wall_clock_minutes` | 30 | 5–120 | Max time on single failing test |
| `validator_severity` | `fail-only` | `fail-only` \| `warn-blocking` | Whether WARN findings block |
| `push_frequency` | `per-commit` | `per-commit` \| `at-boundaries` \| `manual` | Push hygiene policy |
| `dashboard_auto_render` | `true` | bool | Auto-render `specrew where` at iteration/feature closeout (proposal 046) |
| `iteration_default_capacity` | 20 | 5–100 | Default story points per iteration |
| `boundary_tightness` | `hard-stop` | `hard-stop` \| `auto-advance-mechanical` (per 038) | When Squad pauses for human |
| `ci_suppress_prompts` | `true` | bool | Suppress interactive prompts in CI contexts |
| `multi_developer_mode` | `false` | bool | Enables proposal-010 reconciliation machinery |
| `scope_drift_tolerance` | `strict` | `strict` \| `relaxed` | Reviewer behavior on scope expansion |

### Storage model

Extend `.specrew/config.yml` (already exists from F-019) with a `governance:` block:

```yaml
specrew_version: "0.19.0"
bootstrap_date: "2026-05-04"
governance:
  schema_version: 1
  repair_budget: 3
  repair_wall_clock_minutes: 30
  validator_severity: fail-only
  push_frequency: per-commit
  dashboard_auto_render: true
  iteration_default_capacity: 20
  boundary_tightness: hard-stop
  ci_suppress_prompts: true
  multi_developer_mode: false
  scope_drift_tolerance: strict
```

### Schema versioning + migration framework

Each release that changes dials needs deterministic migration:

- **New dials**: added with default value if missing on next `specrew update`
- **Removed dials**: archived under `governance.deprecated.<dial>` (not silently dropped — visible via `specrew config --show-deprecated`)
- **Renamed dials**: translation layer in migration script
- **Bumped defaults**: new module default applies only to fresh `specrew init`; existing projects retain old value with a notice
- **`specrew config --reset`**: returns all dials to current module defaults

Migration runs automatically at `specrew update`; rollback path is `git restore .specrew/config.yml`.

### How Squad consumes the profile

- Squad reads `.specrew/config.yml` `governance.*` at session start
- Each authorization paste is parsed against the profile; explicit overrides in the paste win, defaults flow through
- Stop conditions in authorizations become declarative ("use project profile") rather than enumerative
- Drift-log entries cite the effective governance value at the time of the event, so retros can audit "we hit the budget" without ambiguity

### Distribution

Profile ships with the module (proposal 031 distribution surface). New projects bootstrap with module defaults. `specrew update` migrates existing project profiles forward.

## Effort

Two iterations, ~18-22 SP total.

- **Iteration 1** (~10 SP):
  - Config schema + storage extension
  - Migration framework (read/write/migrate, with schema_version field)
  - `specrew config` standalone CLI (view/set/reset/export/import)
  - `specrew init --<flag>` non-interactive flag support
  - `specrew start --<flag>` session override support
  - Bounds + type validation
  - Unit tests for precedence chain + migration

- **Iteration 2** (~8-12 SP):
  - Interactive prompts during `specrew init` (with "skip and use defaults" fast path)
  - `/specrew.config` slash command integration (depends on proposal 032)
  - Squad coordinator-prompt updates to consume project profile as governance default
  - Drift-log integration (cite effective governance value)
  - End-to-end integration tests
  - Documentation: `docs/governance-profile.md` + README section

## Phase placement

**Phase 2**, post-F-020. Three sequencing options:

- **Option A (combined with 032)**: ship as 25-30 SP combined feature with proposal 032 (slash commands). Composition tight — `/specrew.config` is one of the slash commands. Single narrative: "Specrew becomes installable, surfaces as first-class tool, AND captures your governance preferences."

- **Option B (sequential after 032 + 046)**: 032 ships first (slash command surface), 046 ships (auto-render), then 047 ships and the `/specrew.config` integration just works. Cleaner per-feature scope.

- **Option C (parallel with 032)**: 047 Iter 1 (config + standalone CLI) ships independently; 047 Iter 2 ships after 032 closes (slash command tie-in).

Recommended: **Option B** — sequential, clearer per-feature scope, lowest risk of scope tangle. Bumps post-F-020 queue to: 032 → 046 → 047.

## Open questions

1. **Interactive UX**: full step-through prompt during `specrew init` (10 questions), or condensed batch ("repair budget [3]: ___ / validator severity [fail-only]: ___ / ... / accept all? [y/N]")?
2. **Default-changing-on-upgrade semantics**: when a module bumps a default (e.g., `repair_budget` goes from 3 → 5), should existing projects auto-adopt or stay pinned?
3. **CI fast-path**: how does `specrew init` behave in a CI context where interactive prompts must be skipped? Auto-apply `--use-defaults` if `CI=true` env var present?
4. **Multi-host implications** (proposal 024): if Specrew runs on Claude Code / Codex via Multi-Host CORE, do they read the same project profile? Likely yes — `.specrew/config.yml` is host-neutral.
5. **Profile inheritance / templates**: can a project inherit from a "team profile" (e.g., shared by all an org's projects)? Defer to v2.
6. **Profile validation at start**: should `specrew start` warn if profile values look stale (e.g., `multi_developer_mode: false` when project has 4 contributors per `git log`)?
7. **Audit trail**: should profile changes be logged to a profile-change-log file for retros? "We changed repair_budget from 3 to 5 because of X incident."
8. **Per-feature override**: can a feature spec override the project profile for its lifecycle? (E.g., a security-sensitive feature wants `validator_severity: warn-blocking` for just that feature.)
9. **Dial deprecation policy**: how long does a deprecated dial remain in archived state before removal?
10. **Default catalog growth**: 10 dials for v1 — how do we decide which future dials promote from custom to first-class?

## Risks

- **Decision fatigue**: 10 prompts at init time is friction. Mitigation: "skip and use defaults" fast path; defaults chosen carefully to fit the majority case.
- **Schema migration bugs**: a botched migration on `specrew update` could corrupt existing projects. Mitigation: dry-run mode, automatic backup of pre-migration config, `--rollback` flag.
- **Authorization-pastes becoming opaque**: if Squad always consumes the profile, the user can't see at a glance what governance is in effect. Mitigation: every authorization session prints "Effective governance: <summary>" at start; `specrew config --show` displays current state.
- **Slash-command dependency on 032**: if 032 slips, the `/specrew.config` integration ships incomplete. Mitigation: design 047 Iter 1 to be useful standalone (without slash commands); 047 Iter 2 layers the slash command on top.
- **Multi-host divergence**: if `.specrew/config.yml` semantics differ between Squad / Claude Code / Codex hosts, the profile becomes per-host instead of project-level. Mitigation: lock the schema as host-neutral; hosts that need host-specific config use a separate file.

## Cross-references

- **Proposal 015 (Expertise-Aware Adaptive Interaction)** — complementary: 015 *infers* preferences from observed user behavior; 047 lets the user *declare* them explicitly. Both should coexist; explicit declarations override inferred ones.
- **Proposal 032 (Slash-Command Surface)** — composes tightly: `/specrew.config` is one of the slash commands in 032's V1 catalog.
- **Proposal 038 (Adaptive Boundary Discipline)** — the `boundary_tightness` dial IS the form-vs-meaning slider 038 wants to make explicit. 038's three-class taxonomy (human-judgment / mechanical-execution / strategic-progression) maps cleanly to dial values.
- **Proposal 046 (Auto-Render Dashboard)** — the `dashboard_auto_render` dial controls 046's behavior.
- **Proposal 035 / F-020 (Session-State Durability)** — `.specrew/config.yml` durability is established by F-020; this proposal extends what lives there.
- **Proposal 044 (Downstream Quality Baseline Bootstrap)** — composes: 044 adds stack-aware quality configs at `specrew init`; 047 adds governance preferences at the same boundary. Could share the prompt flow.
- **Proposal 010 (Multi-Developer Reconciliation)** — `multi_developer_mode: true` activates 010's machinery.
- **Proposal 024 (Multi-Host Runtime Abstraction)** — profile must remain host-neutral so any runtime reads it identically.

## Status history

- 2026-05-18: candidate captured after F-020 Iteration 2 introduced an autonomous-repair budget mid-flight via authorization paste. The friction of re-specifying governance dials per authorization motivated capturing them at init-time durably. Designed as a four-surface model (init / start / config CLI / slash command) with a 10-dial v1 catalog.
