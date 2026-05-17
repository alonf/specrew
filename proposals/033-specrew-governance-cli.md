---
proposal: 033
title: Specrew Governance CLI
status: draft
phase: phase-2
estimated-sp: 18
discussion: tbd
---

# Specrew Governance CLI

## Why

Specrew governs everything DOWNSTREAM of the human (lifecycle boundaries, validators, ceremonies, hardening gates) but the human-facing UPSTREAM surfaces are unstructured. Three gaps observed 2026-05-16:

1. **Roadmap updates** — `.specrew/roadmap.yml` is hand-edited YAML. No CLI, no schema validator, no lifecycle hook on `/speckit.specify` to auto-register the new feature.
2. **Proposal lifecycle** — `proposals/*.md` files are hand-edited markdown with manual frontmatter. `INDEX.md` is hand-maintained. Promoting a proposal from candidate to draft, or graduating a proposal into a feature spec, is a manual multi-file edit. Proposal 028 (Public Proposals Surface lifecycle hardening) captures some of this as queued.
3. **Feature creation** — Starting a new feature means commanding Squad to create the spec directory, run `/speckit.specify`, branch from main, update `.specify/feature.json`. The downstream maintainer has no first-class command surface.

The asymmetry: Specrew runs governed lifecycle work, but the human's GOVERNANCE-OF-GOVERNANCE (controlling the roadmap, lifecycle of proposals, starting features) is unstructured. For downstream projects adopting Specrew, this is a poor onboarding story — there's no documented "this is HOW you control your roadmap" surface beyond "ask Squad to do it."

## What

A set of `specrew propose`, `specrew roadmap`, and `specrew feature` CLI commands that provide structured, schema-aware, validator-enforced surfaces for the three governance artifacts. CLI ships first (works today via PowerShell); slash-command versions are deferred to Proposal 032 (which depends on Multi-Host Runtime Abstraction CORE per the 2026-05-16 Squad coupling analysis).

### Five pillars

1. **Roadmap CLI** — `specrew roadmap show / add-feature / update-phase / add-phase / remove-feature / validate`
2. **Proposal CLI** — `specrew propose create / list / show / status / specify / validate`. The load-bearing command is `propose specify <NNN>` which graduates a draft proposal into an active feature spec (branches from main, creates `specs/NNN-<feature-name>/`, runs `/speckit.specify` with proposal content as source, flips proposal status to `active`)
3. **Feature CLI** — `specrew feature new / list / current / status` (recommended deferred to Iteration 2 to keep MVP tight)
4. **Validator integration** — new soft WARN rules at validate-governance time: `roadmap-schema-invalid`, `proposal-frontmatter-invalid`, `proposal-index-divergence`, `roadmap-feature-ref-missing`
5. **Documentation** — `docs/governance-cli-guide.md` "Specrew for Project Maintainers" guide, README install-section pointer, `--help` on every command

### CLI surface (Iteration 1 MVP)

| Command | Purpose |
|---|---|
| `specrew roadmap show` | Display current roadmap (composes with `specrew where`) |
| `specrew roadmap add-feature <name> --phase <id> --planned-sp <N>` | Append feature ref to phase, adjust planned_effort_sp |
| `specrew roadmap update-phase <id> [--planned-sp N] [--name X] [--description Y] [--status S]` | Re-plan a phase atomically with diff preview |
| `specrew roadmap add-phase <id> --name X --description Y --planned-sp N` | Extend roadmap with a new phase |
| `specrew roadmap validate` | Schema check + drift detection |
| `specrew propose create <name>` | Scaffold new proposal from `_template.md` |
| `specrew propose list [--status X]` | List proposals filtered by status |
| `specrew propose show <NNN>` | Display single proposal |
| `specrew propose status <NNN> --to <state>` | Manage proposal lifecycle status |
| `specrew propose specify <NNN>` | Graduate proposal to active feature spec (LOAD-BEARING) |
| `specrew propose validate` | Schema check + INDEX.md regen |

## Effort

- **Iteration 1 MVP** (Pillars 1, 2, 4, 5): ~15-20 SP
- **Iteration 2** (Pillar 3 Feature CLI + lifecycle hooks): ~10-15 SP

Single-iteration MVP is the recommended ship scope.

## Phase placement

**Phase 2 priority** — slot between Feature 019 Distribution Module (currently in flight) and the Phase 3 Multi-Host CORE anchor. Rationale:

- The gap is real TODAY and affects every roadmap update / proposal promotion / feature creation
- The MVP can talk directly to `.specrew/roadmap.yml` and `proposals/*` without depending on Multi-Host CORE's canonical-state abstraction
- When Multi-Host CORE ships, refactor the CLI internals to talk to the canonical-state interface — user-facing commands stay identical
- Shipping before Multi-Host CORE means the abstraction work has a real consumer to design against (the CLI), not a hypothetical one

## Open questions

1. Iteration split — defer Feature CLI to Iteration 2, or include in Iteration 1?
2. Proposal numbering — strict next-integer, or allow gaps for reserved ranges?
3. `propose specify` boundary protocol — run through `/speckit.specify` automatically, or stop at branch-and-feature-json-update for explicit human-authorized advance?
4. INDEX.md regeneration — auto on every status/create, or only on explicit `--regen`?
5. Pillar 4 validator rule severity — WARN initially, or some FAIL?
6. Proposal 028 status post-ship — supersede entirely, or keep as the coordinator-prompt half?
7. Cross-platform behavior — inherits from Feature 019 (`Join-Path` everywhere + WSL verification)
8. CLI dispatcher integration — extend existing `scripts/specrew.ps1` to route `roadmap`, `propose`, `feature` subcommands
9. Autopilot integration — `--non-interactive` flag + machine-readable status codes for future autopilot driver use
10. Multi-Host CORE composition — design CLI internals with a thin adapter layer so Multi-Host CORE can swap the file-format coupling cleanly

## Risks

- **Scope creep into Feature CLI**: Pillar 3 can expand. Mitigation: explicit Iteration 1 vs Iteration 2 split.
- **Conflict with Proposal 028 scope**: this feature absorbs Proposal 028's surface. Mitigation: explicit "Proposal 028 superseded" decision at clarify time.
- **Coupling to current file layouts**: CLI talks to file paths directly today. Mitigation: thin adapter layer; Multi-Host CORE can swap the format coupling cleanly.
- **Validator noise**: starting new rules at WARN may surface noisy warnings on existing projects. Mitigation: introduce rules one at a time; allow per-rule overrides.

## Cross-references

- Proposal 028 (Public Proposals Surface lifecycle hardening) — ABSORBED by this feature
- Proposal 024 (Multi-Host Runtime Abstraction CORE) — composes; CLI internals refactor when CORE ships
- Proposal 032 (Specrew Slash-Command Surface) — wraps these CLI commands as slash commands when shipped (depends on Multi-Host CORE)
- Proposal 013 (Methodology Site) — gains a CLI Reference page once the CLI ships
- Proposal 031 (Distribution Module) — CLI scripts ship in the PSGallery module bundle
- Feature 019 Distribution Module (in flight) — clarify-time decisions (Join-Path, WSL verification, signing) apply identically to this feature's cross-platform behavior

## Status history

- 2026-05-16 evening: candidate captured after the user observed the governance-of-governance gap during a Squad-driven Feature 019 clarify session. Promoted to draft status with full source-spec content captured.
