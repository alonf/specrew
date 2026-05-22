---
proposal: 100
title: Friction Dial (Composable Strictness Surface for Boundary Discipline, Verdict Acceptance, and Reconciliation Posture)
status: candidate
phase: phase-2
estimated-sp: 10-15
discussion: ad-hoc 2026-05-22 session
---

# Friction Dial (Composable Strictness Surface for Boundary Discipline, Verdict Acceptance, and Reconciliation Posture)

## Why

Specrew's lifecycle discipline is currently expressed at two extremes:

1. **Strict** (what the 2026-05-22 F-039 implementation session enacted via maintainer paste-prompt scaffolding): exact verdict shapes required, ambiguous prose rejected, reconciliation regression on silence, drift-log per verdict, single-boundary verdicts only.
2. **Autonomous** (Proposal 066 `--autonomous`, shipped 2026-05-20): host-level autopilot advances across boundaries without per-boundary input.

The reality between these extremes is currently undefined. **An expert developer who has internalized Specrew's methodology doesn't want strict-mode friction every session, but they also don't want full autopilot.** They want graduated control: brief verdicts the parser still recognizes (`approved`, `continue`), drift-log per major boundary not per micro-step, batched reconciliation, optional silent advancement at low-stakes boundaries.

This proposal isn't introducing a new feature — it's **knitting three existing dial pieces into a coherent surface**:

- **Proposal 015** (Expertise-Aware Adaptive Interaction, candidate): provides the developer-expertise classification — beginner / intermediate / expert.
- **Proposal 047** (Project Governance Profile, candidate): provides the init-time preference-capture surface where dial settings get configured.
- **Proposal 066** (Gate-Respecting Default + `--autonomous` Opt-In, shipped 2026-05-20): the only binary dial that currently exists at the host layer.

None of those three currently reference each other. None defines how the Crew's installed instruction files consult the dial setting. None defines the persistence schema. This proposal closes that gap.

### Empirical motivation

The 2026-05-22 F-039 implementation session demonstrated:

- The maintainer (an experienced Specrew developer) typed roughly 20 distinct SDLC-discipline directives across paste prompts because no installed file enumerated the strict-mode rules.
- Multiple verdict cycles surfaced procedural friction (e.g., the second clarify-pass micro-divergence loop) that an expert dev would naturally bypass with a brief verdict — but the parser-to-be-built (F-039) is currently designed to reject anything other than the exact strict-mode shape.
- The maintainer's own observation captured in mid-session:

> "Not always we want the Crew to stop, it depends on the expertise of the human dev and their preferences."

That observation is the structural prompt for this proposal. Proposal 099 documents strict-mode in installed files; this proposal makes strict-mode the safe default while exposing the dial for graduation.

### What this is NOT

- NOT a relaxation of F-039 / Proposal 065. F-039's **mechanical floor** (skill-level authorization gate, fail-closed semantics, bypass audit trail) stays universal. The dial controls only what **counts as authorization** at the parser layer, not whether the gate fires.
- NOT a "remove all friction" proposal. The dial's lowest setting still preserves audit-trail completeness and the bypass-with-mandatory-reason emergency escape.
- NOT scope expansion of Proposal 015 / 047 / 066. This proposal explicitly composes them; it does not re-invent any of their surfaces.

## What (Four Pillars)

### Pillar 1 — Three canonical strictness modes

The dial has three named settings, in increasing order of relaxation:

| Mode | Verdict acceptance | Reconciliation rule | Drift-log granularity | Compound verdict | Default for |
|---|---|---|---|---|---|
| **strict** | exact shapes only (`approved for <boundary>-boundary entry`, `rejected for <boundary>`, `parked`) | spec silence = clarify regression; done-condition lockdown active | per-verdict entry | single-boundary only | new users; downstream installs before grounding; high-risk feature work |
| **default** | exact shapes preferred, common ambiguous prose accepted (`approved`, `looks good`, `continue` → advance one boundary per Rule 14A) | spec silence = note in drift-log but advance if scope is clearly preserved | per major boundary (plan/review-signoff/feature-closeout) | up to 2 boundaries via `X AND Y` | grounded developers who have shipped 1+ Specrew features |
| **autonomous** | brief shapes acceptable; intake stage stays interactive | reconciliation deferred to review-boundary batch | batched at iteration-closeout | chain mode (advance to <target>) | overnight runs, repeated routine slices, expert solo developers |

The three modes are **canonical** — installed files refer to them by name. Future modes are additions to the catalog, not free-form configuration.

### Pillar 2 — Persistence schema in `.specrew/config.yml`

Add a `friction` section to the project-level Specrew config:

```yaml
friction:
  mode: strict           # one of: strict | default | autonomous
  set_at: '2026-05-22T...Z'
  set_by: 'Alon Fliess (init-time intake)'
  override_history:
    - from_mode: strict
      to_mode: default
      reason: 'Shipped 5 features; verdict-shape strictness now creates more friction than value'
      recorded_at: '2026-05-22T...Z'
```

Project-level setting. Session-level override via `specrew start --friction default` is permitted but is not persisted — it's transient for that session.

### Pillar 3 — Init-time capture flow (composes with Proposals 015 + 047)

The dial value gets set in one of three ways:

1. **`specrew init`-time intake** (the canonical pathway, composes with Proposal 047): the init flow asks the developer two questions:
   - "What's your familiarity with Specrew methodology?" — feeds Proposal 015's expertise classification, defaults the dial:
     - new / beginner → `strict`
     - intermediate → `default`
     - expert → `default` (NOT `autonomous` — autonomous requires explicit opt-in beyond expertise level)
   - "Do you want to override the default for this project?" — if yes, lets the developer pick explicitly.
2. **Explicit `specrew config friction <mode>`** (or whatever CLI surface lands per Proposal 033 Specrew Governance CLI): manual override at any time. Recorded in `override_history`.
3. **Session-level `specrew start --friction <mode>`**: transient; doesn't persist. For one-off "I'm tired, let me run autonomous tonight" usage.

If `.specrew/config.yml` lacks a `friction` section (pre-100 installs), the Crew treats it as `strict` until the developer explicitly sets one. This is the safe default migration path.

### Pillar 4 — Crew consultation surface (composes with F-039 / Proposal 065)

When this proposal ships, the following installed files gain a dial-consultation block:

- **`coordinator/specrew-governance.md` Rule 14A** is extended: "Apply boundary discipline at the strictness level configured in `.specrew/config.yml` `friction.mode` (default: strict). Strict mode requires exact verdict shape per `feedback-verdict-boundary-naming`; default mode accepts grounded prose advancing one boundary; autonomous mode batches verdicts at iteration-closeout."
- **Each agent charter** gains a one-line reference under "How I Work": "I apply the strictness level configured in `.specrew/config.yml` `friction.mode`."
- **F-039's `Parse-SpecrewBoundaryVerdict`** (Proposal 065 Pillar 2) consults `friction.mode` and accepts different verdict-shape sets per mode. The function signature already takes `[string[]]$CanonicalBoundaries`; this proposal adds `[string]$FrictionMode = (Get-SpecrewFrictionMode)`.
- **`specrew start`** prints a one-line posture banner at launch including the active friction mode. (Companion to Proposal 098 Launch Posture Visibility — composes; doesn't require 098 to ship first.)
- **`specrew where`** dashboard adds a FRICTION section showing the active mode, any session override, and a count of bypasses or verdict-shape mismatches in the active session.

## How (implementation plan)

This proposal ships after F-039 / Proposal 065 lands so the verdict-parser surface exists to compose with.

| Step | What | File(s) | Effort |
|---|---|---|---|
| 1 | Define schema | `.specrew/config.yml` schema migration; new `friction` section + validator rule | 1.0 SP |
| 2 | Helper `Get-SpecrewFrictionMode` | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) | 0.5 SP |
| 3 | Helper `Set-SpecrewFrictionMode` | same; appends to `override_history` | 0.5 SP |
| 4 | Init-time intake question | `specrew init` flow; composes with Proposals 015 + 047 | 1.5 SP |
| 5 | Session-level `--friction` flag | `scripts/specrew-start.ps1` | 0.75 SP |
| 6 | `Parse-SpecrewBoundaryVerdict` composes with friction mode | F-039 surface; gated on Proposal 065 implementation | 1.5 SP |
| 7 | Coordinator-governance Rule 14A extension | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | 0.5 SP |
| 8 | Agent charter references | five agent charters | 0.5 SP |
| 9 | Launch banner posture line | `scripts/specrew-start.ps1` (composes with Proposal 098) | 0.5 SP |
| 10 | `specrew where` FRICTION section | `scripts/specrew-where.ps1` | 0.75 SP |
| 11 | `specrew config friction <mode>` CLI | composes with Proposal 033 Specrew Governance CLI | 1.0 SP |
| 12 | Tests | mode persistence; intake-flow; session override; parser composition; bypass audit | 1.5 SP |
| 13 | Mirror parity + CHANGELOG + INDEX | as usual | 0.5 SP |

**Total**: ~10-11 SP. Single iteration; ships after F-039.

## Composition with Other Proposals

| Proposal | Relationship |
|---|---|
| **Proposal 015** (Expertise-Aware Adaptive Interaction, candidate) | Component pillar. 015 provides the expertise classification that defaults the dial at init time. This proposal does NOT re-invent 015's expertise dial; it consumes it. If 015 hasn't shipped, init-time capture defaults to a direct three-mode question. |
| **Proposal 047** (Project Governance Profile, candidate) | Component pillar. 047 provides the init-time preference-capture surface. This proposal adds `friction.mode` to that surface. |
| **Proposal 066** (Gate-Respecting Default + `--autonomous` Opt-In, shipped) | Predecessor. 066's binary dial is the seed of this surface. After this proposal ships, `--autonomous` becomes shorthand for `--friction autonomous` (alias preserved for backward compatibility). |
| **Proposal 065 / F-039** (Launch-Mode Boundary Enforcement, in flight) | Mechanical complement. F-039's mechanism stays universal; this proposal's dial controls verdict-parser acceptance only. F-039 ships first; this proposal layers on. |
| **Proposal 099** (Installed-File SDLC Instruction Audit, candidate) | Companion. 099 documents strict-mode in installed files; this proposal frames how the documented rules relax. Slice 1 of 099 (Recognized Verdict Shapes catalog) explicitly references this proposal's three modes once both land. |
| **Proposal 063** (Substantive Intake Questioning, F-040 next) | Composes. 063's intake catalog includes a "review cadence preference" category that maps to this proposal's friction setting. The intake question becomes a single canonical question rather than 12 separate ones. |
| **Proposal 033** (Specrew Governance CLI, draft) | Composes. The `specrew config friction <mode>` command lives on the 033 CLI surface. |
| **Proposal 098** (Launch Posture Visibility, candidate) | Composes. 098's launch banner surfaces the active friction mode; this proposal provides the mode value. |
| **Proposal 030** (Quality Hardening Bundle, draft) | Composes. The form-vs-meaning verification pillar of 030 likely tightens at higher friction modes; this proposal exposes the dial axis. |

## Acceptance Signals

- **AC1**: After this proposal ships, `specrew init` on a fresh project asks the friction question (or accepts the Proposal 015 expertise-mapped default) and persists the choice to `.specrew/config.yml`. Verified by integration test running init flow.
- **AC2**: `Parse-SpecrewBoundaryVerdict` (Proposal 065's helper) accepts different verdict-shape sets per friction mode. Strict mode rejects `approved` (no boundary named); default mode accepts it as one-boundary advance; autonomous mode batches at iteration-closeout. Verified by integration test against each mode.
- **AC3**: `specrew start --friction default` overrides the project-level setting for one session without persisting. Verified by integration test.
- **AC4**: Launch banner prints friction mode at session start. `specrew where` dashboard shows FRICTION section. Verified by integration test.
- **AC5**: Existing pre-100 projects without a `friction` section in `.specrew/config.yml` default to `strict` until explicitly configured. Verified by integration test against a pre-100 fixture.
- **AC6**: Mode transitions are recorded in `override_history` with reason + timestamp. Verified by integration test running `Set-SpecrewFrictionMode` multiple times.
- **AC7**: Coordinator governance Rule 14A and agent charters reference `friction.mode`. Verified by structural grep test.
- **AC8**: `--autonomous` flag (Proposal 066) remains backward-compatible as an alias for `--friction autonomous`. Verified by integration test.
- **AC9**: F-039's emergency `--bypass-boundary-enforcement` still requires `--reason` regardless of friction mode. Bypass is orthogonal to dial setting. Verified by integration test.
- **AC10**: Mirror parity across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` for all touched files.

## Out of Scope

- **Re-implementing Proposal 015's expertise dial.** This proposal consumes 015's classification; it does not duplicate it. If 015 ships without a clean classification interface, that's a 015 defect, not this proposal's.
- **Per-feature friction overrides.** The dial is project-level + session-level. Per-feature granularity would defeat the purpose (every feature could declare itself autonomous, regressing the methodology guarantee). Out of scope.
- **Auto-promotion based on history** (e.g., "you've shipped 5 features in strict mode without rework — would you like to dial down?"). Maybe a future enhancement; not in MVP. Manual promotion via `specrew config friction default` only.
- **Cross-project friction profiles** (e.g., "my preferred mode for new projects"). Each project owns its setting; no cross-project state.
- **Friction-aware CI semantics.** CI runs are always effectively `strict` for truth-check purposes; CI doesn't read `friction.mode`.
- **Emergency bypass override.** F-039's `--bypass-boundary-enforcement` is orthogonal — it disables enforcement entirely, regardless of friction mode. It is not "friction = lowest".

## Default Behavior Summary

| Scenario | Effective mode |
|---|---|
| Fresh `specrew init` on greenfield project, no prior dial setting | `strict` (until set during init flow) |
| Existing pre-100 project upgraded to Specrew with this proposal shipped | `strict` (until explicit `specrew config friction <mode>` runs) |
| Expert dev running `specrew init` and answering "I've shipped 5+ Specrew features" | `default` (NOT `autonomous`) |
| Dev passes `specrew start --friction autonomous` for one overnight run | `autonomous` for that session; project setting unchanged |
| `--autonomous` legacy flag from Proposal 066 | aliased to `--friction autonomous` for backward compat |
| Emergency bypass (`--bypass-boundary-enforcement`) | orthogonal; suspends enforcement regardless of friction mode |

## Cross-References

- **Empirical motivation**: 2026-05-22 ad-hoc session. Maintainer observation captured mid-F-039 implementation.
- **Companion**: Proposal 099 (Installed-File SDLC Instruction Audit) — documents strict mode in installed files.
- **Component pillars**: Proposals 015, 047, 066 (existing dial-related surfaces).
- **Mechanical complement**: Proposal 065 / F-039 (the universal mechanical floor).
- **Composes-with**: Proposals 033, 063, 098, 030.
- **Memory anchors**:
  - `feedback-verdict-boundary-naming-2026-05-22` (verdict shape rule — applies to strict mode)
  - `project-f024-boundary-compaction-breach-2026-05-20` (incident that exposed the binary 066 dial as insufficient)
- **INDEX**: file:///C:/Dev/Specrew/proposals/INDEX.md
