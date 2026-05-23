---
proposal: 057
title: Roadmap Spine + Input Adapter Pattern (Configurable Roadmap Population)
status: partially-shipped
shipped-as: fix-bundle 162bcdb9 — stub-bootstrap slice only (scaffold-governance.ps1 writes a minimal `.specrew/roadmap.yml` with a single 'Phase 1: Initial Delivery' planning row at `specrew init`). Does NOT implement the input-adapter system (manual / GitHub Issues / Linear / etc.) — that scope stays candidate. Inline-shipped during F-040 calc-v2 dogfooding 2026-05-23.
shipped-in: v0.26.0
phase: phase-3
estimated-sp: 28
actual-sp: 1  # stub-bootstrap slice only; remaining 27 SP scope below stays candidate
discussion: tbd
---

# Roadmap Spine + Input Adapter Pattern

## Status notes (2026-05-23)

The stub-bootstrap slice shipped inline as part of the F-040 dogfooding fix bundle
(commit `162bcdb9`). `specrew init` now writes a minimal `.specrew/roadmap.yml` so the
dashboard's ROADMAP section has content in fresh projects. The remaining 27 SP of the
full proposal stays candidate:

- Input adapters: manual / GitHub Issues / Linear / Jira / Azure DevOps / iteration-end auto-sync
- Init-time adapter configuration wizard
- Dashboard renderer integration (read roadmap.yml as canonical source for ROADMAP section)
- Per-adapter pull-and-merge semantics
- Conflict resolution when an adapter and a manual edit collide

The stub-bootstrap unblocks dashboard rendering in fresh projects today without locking
in any adapter contract. The full proposal can resume from this state.

## Why

`specrew where` (the dashboard from F-017/F-018) and Specrew's lifecycle priority decisions both depend on `.specrew/roadmap.yml` for "what's planned" / "what's queued" knowledge. But how does `roadmap.yml` itself get populated?

Today, the answer is implicit and manual: the maintainer hand-edits `roadmap.yml`. This works for Specrew's own development (single maintainer, Specrew uses proposals/ as its design pipeline). It does NOT scale to downstream projects that:

- Use external issue trackers (GitHub Issues / GitHub Projects / Linear / Jira / Azure DevOps)
- Have multi-developer teams contributing ideas concurrently
- Want priority signals to flow from a board / project management tool into the dashboard
- Run automated iteration-end syncs to keep planned work fresh
- Want a one-shot CSV/JSON import for migration from prior tooling

This proposal establishes `roadmap.yml` as the **single canonical source of truth** for dashboard + priority decisions, and defines **a configurable input-adapter pattern** through which various sources can populate it. Multiple adapters can be combined. The project chooses its adapter mix at `specrew init` time (or first `specrew start` if unconfigured).

Without this architecture:

- Every downstream project has to invent its own roadmap-population mechanism
- The relationship between external tools (Jira, GitHub Projects) and Specrew's lifecycle is undefined
- Multi-user contribution to the roadmap has no sanctioned pattern
- Specrew's own use of `proposals/` as a design pipeline can't be cleanly offered to downstream projects as an option

## Background and design context

This proposal emerged from a sequence of methodology questions during F-022 (2026-05-18 — 2026-05-19):

1. **Should the proposals/ pattern propagate to downstream projects?** Resolution: opt-in `proposal-driven-design` profile per [Proposal 052](file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md). Some projects benefit; others don't. Make it a choice.
2. **In a no-proposals project, how does the dashboard show roadmap?** Resolution: dashboard reads `roadmap.yml` regardless. Pre-spec ideation lives in whatever input the project chooses.
3. **How do priorities get set?** Resolution: explicit hierarchy (spec status > roadmap.yml order > external tracker > maintainer judgment).
4. **How does roadmap.yml itself get populated when multiple sources are available?** This proposal.

The architectural insight is that `roadmap.yml` is a SPINE — the dashboard depends on it; all sources INPUT to it. Decoupling the source from the surface lets each project choose its source(s) without changing the surface.

## What

### Architecture

```text
Input adapters (multiple, optional, configurable)
       ↓
   roadmap.yml (canonical source of truth)
       ↓
   Dashboard + priority decisions + velocity projections
```

The dashboard's contract becomes simple: read `roadmap.yml`. Adapters' contract becomes simple: produce or update entries in `roadmap.yml`. Configuration determines which adapters are active.

### Three pillars

#### Pillar 1: Adapter interface

A versioned interface that all adapters implement. At minimum:

- **`Get-AdapterStatus`** — health-check and configuration completeness
- **`Get-NewItems`** — return items from the source that aren't yet in `roadmap.yml`
- **`Get-StatusChanges`** — return status updates for items already in `roadmap.yml`
- **`Sync-RoadmapEntries`** — apply pending updates to `roadmap.yml` (with conflict-resolution semantics, see Pillar 3)

Adapters declare their identity, their source-of-truth URL/path, and any required credentials/configuration. Per-adapter sub-schema in `.specrew/config.yml`.

#### Pillar 2: Adapter catalog

Initial built-in adapters (shipped with Specrew core):

| Adapter | Source | Sync mode | Default? |
|---|---|---|---|
| **`manual`** | User edits `roadmap.yml` directly | Synchronous | Yes (always-available fallback) |
| **`proposals`** | `proposals/*.md` (requires `proposal-driven-design` profile) | On proposal status change | Off (opt-in via profile) |
| **`iteration-end-sync`** | Runs at each iteration-closeout to sync from the primary configured external source | Boundary-triggered | On (when external source configured) |

Built-in adapters shipped as profiles (per [Proposal 052](file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md)):

| Profile | Source | Sync mode |
|---|---|---|
| `adapter-github-issues` | GitHub Issues with configured label | MCP / `gh` CLI; on-demand or scheduled |
| `adapter-github-projects` | GitHub Projects board columns | MCP / `gh` CLI; on-demand or scheduled |
| `adapter-linear` | Linear API | Linear MCP server |
| `adapter-jira` | Jira API | Jira MCP / vendor API |
| `adapter-azure-devops` | Azure DevOps Work Items | Azure DevOps MCP / vendor API |

Utility adapter (one-shot):

| Adapter | Source | Mode |
|---|---|---|
| **`bulk-import`** | CSV / JSON file | One-shot at config time |

Community-contributed adapters can extend the catalog via the profile system. Each new adapter is ~5-10 SP to implement against the interface.

#### Pillar 3: Configuration UX and conflict resolution

**At `specrew init`** (or first `specrew start` if unconfigured), the user is prompted:

```text
Roadmap source configuration
=============================

The dashboard reads from .specrew/roadmap.yml. You can populate it via:

  [1] Manual — edit roadmap.yml directly (default fallback)
  [2] Proposals — proposals/ directory (requires proposal-driven-design profile)
  [3] GitHub Issues — pull from issues with a configured label
  [4] GitHub Projects — pull from a project board
  [5] Linear / Jira / Azure DevOps — pull from a vendor API
  [6] Bulk import — one-shot from CSV/JSON

You can combine multiple. Selected adapters:
```

The user selects one or more (multi-select). Configuration is stored in `.specrew/config.yml`:

```yaml
roadmap:
  primary_source: github-projects   # adapter that "owns" entries by default
  adapters:
    - id: manual
      enabled: true
    - id: proposals
      enabled: true
    - id: github-projects
      enabled: true
      config:
        project_id: "abc-123"
        column_map:
          Backlog: phase-2
          In Progress: phase-2-active
  sync:
    iteration_end_auto_sync: true
    daily_sync_enabled: false
```

**Conflict resolution semantics** when multiple adapters disagree about the same entry:

- Each entry in `roadmap.yml` records its `source: <adapter-id>` and `last_synced_at: <timestamp>`
- Priority hierarchy: `manual > primary_source > other_adapters`
- Manual edits to roadmap.yml always win (the maintainer override semantics)
- Soft validator WARN when two adapters provide different status for the same feature
- Conflict resolution is surfaced in the dashboard (e.g., "feature-NNN: GitHub Projects says `in-progress`, Linear says `done` — manual reconciliation needed")

### Multi-user numbering — deferred to Proposal 010

When multiple users contribute proposals / specs / iterations concurrently, numbering collisions become real. Five options analyzed during 2026-05-19 discussion:

| Option | Pattern | Recommendation |
|---|---|---|
| A | Atomic broker (`.specrew/next-numbers.json`) | Small teams, frequent pulls |
| B | User-prefixed numbers (`alonf-056-name.md`) | Large open-source; PR-heavy |
| C | Branch + rebase resolution | Rarely right — too much churn |
| D | Content-addressed (UUID) + assigned-number aliases | Large teams |
| **E** | **PR-assigned numbers (RFC tradition)** | **Recommended default for multi-user** |
| F | Hybrid UUID + assigned-number | Combines D + E |

**Recommended pattern for multi-user mode**: Option E. Local development uses `proposal-TBD-name.md` placeholders. PR merge to main triggers automation that:

1. Determines the next available number (queries main's existing files)
2. Renames the file (`proposal-TBD-name.md` → `proposal-NNN-name.md`)
3. Updates the `proposal:` field in frontmatter
4. Updates INDEX.md
5. Best-effort cross-reference update (notify if cross-references in other files need manual touch-up)

This is the standard RFCs/PEPs/TC39-proposals tradition.

**This proposal does NOT implement multi-user numbering.** It belongs in [Proposal 010 (Multi-Developer Reconciliation)](file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md), which has Phase 5 placement and ~75 SP scope. Proposal 057 only establishes the adapter pattern; Proposal 010 handles the concurrent-user mechanics including numbering.

### Pre-spec phase interaction

`roadmap.yml` entries describe planned work that may not yet have a spec. The pre-spec phase pattern choice (per [memory note](file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_pre_spec_phase_in_downstream_projects_2026_05_19.md)) determines where pre-spec ideas live:

- **Pattern A — External issue tracker** (default for downstream projects): pre-spec lives in GitHub Issues / Linear / Jira / Azure DevOps. Specrew governs only specced+ work. Adapter pulls priorities into `roadmap.yml`; ideation stays in the tracker.
- **Pattern B — Skeleton specs** (discouraged): all ideas get a spec.md in Draft status. `roadmap.yml` lists them.
- **Pattern C — `proposal-driven-design` profile**: pre-spec lives in `proposals/`. Proposals adapter populates `roadmap.yml`.

Adapters and pre-spec patterns compose:

| Pre-spec pattern | Compatible adapters |
|---|---|
| A (external tracker) | `manual` + one of `github-issues / github-projects / linear / jira / azure-devops` |
| B (skeleton specs) | `manual` only (skeleton specs aren't "ideas to track") |
| C (proposals profile) | `manual` + `proposals` (composes naturally) |
| **Hybrid** | `manual` + `proposals` + external tracker (community-extensible workflow) |

### Dashboard implications

The dashboard surface (`specrew where`) gains a few new features (composes with [Proposal 048](file:///C:/Dev/Specrew/proposals/048-dashboard-velocity-metric-refinement.md)):

- **`--planned` flag**: show specs in Draft / Clarified / Planned status as a "queue" section between RECENT SHIPPED and PROJECTION
- **Adapter status indicator**: show which adapters are configured + when they last synced
- **Priority drift warning**: if the active feature doesn't match the next-up in `roadmap.yml`, WARN with explicit drift signal
- **Conflict surface**: when two adapters disagree, surface the conflict in the dashboard so the maintainer can reconcile

These are dashboard work, composing with Proposal 048's velocity-refinement scope.

## Effort

**~25-30 SP across two iterations**.

### Iteration 1 (~12 SP) — Core adapter pattern

- Adapter interface definition (versioned, four key methods) (~2 SP)
- `manual` adapter (read/write `roadmap.yml` cleanly with metadata fields) (~2 SP)
- `iteration-end-sync` adapter (hook into iteration-closeout boundary) (~2 SP)
- `proposals` adapter (when `proposal-driven-design` profile present; otherwise no-op) (~2 SP)
- Init-time configuration UX (~2 SP)
- Adapter health-check + status indicator surface (~1 SP)
- Tests + documentation (~1 SP)

### Iteration 2 (~13-15 SP) — First external adapters + dashboard integration

- `adapter-github-issues` profile (~3 SP)
- `adapter-github-projects` profile (~4 SP)
- One vendor adapter (recommend `adapter-linear` for first vendor — clean API) (~3 SP)
- Dashboard `--planned` flag + adapter status + drift warning (~2 SP)
- Conflict-resolution validator rule (soft WARN when adapters disagree) (~1 SP)
- Tests + documentation (~1 SP)

Other vendor adapters (`adapter-jira`, `adapter-azure-devops`, `bulk-import`) become follow-up community-contributed profiles per [Proposal 052](file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md). Each is ~5-10 SP to implement against the interface.

## Phase placement

**Phase 3 (Runtime Abstraction & Spec Fidelity)**, sibling to:

- [Proposal 024 (Multi-Host Runtime Abstraction)](file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md) — extensibility infrastructure
- [Proposal 052 (Specrew Profile System)](file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md) — profile-extensibility pattern (the adapter system rides on top)

This proposal explicitly **depends on Proposal 052** for the profile mechanism that hosts external adapters. Sequencing: 052 ships first; 057 builds on its profile pattern.

## Open questions

1. **Adapter interface spec**: what's the canonical shape? Recommend a 4-method interface (`Get-AdapterStatus`, `Get-NewItems`, `Get-StatusChanges`, `Sync-RoadmapEntries`) but the exact API + return schemas need design at planning time.
2. **`roadmap.yml` schema extension**: per-entry `source` + `last_synced_at` metadata adds fields. Migration path for existing roadmap.yml entries (currently no metadata)?
3. **Adapter authentication**: how do `github-projects` / `linear` / `jira` adapters store credentials? Recommend per-adapter config block in `.specrew/config.yml` with reference to env vars or a secrets file (never plaintext credentials in the config).
4. **Sync frequency**: should adapters poll on a schedule (daily? hourly?), only on `specrew start`, only at iteration-end, or all of the above? Configurable per-adapter.
5. **Conflict-resolution policy**: who wins when manual edits and external-tracker edits disagree? Recommend manual wins (override semantics), but is there a "force adapter override" path for projects that want the tracker to be authoritative?
6. **Bidirectional sync?**: should adapters PUSH back to the source (e.g., when a spec ships, mark the GitHub Project card as done)? Or read-only? Recommend read-only for v1; bidirectional as a follow-up if demand exists.
7. **Adapter discovery**: do users browse a community-adapter catalog, or are adapters explicitly listed in Specrew docs?
8. **Multi-source attribution in dashboard**: when an entry comes from multiple sources, how is that surfaced? Composite source field?
9. **Pre-population at init**: should `specrew init --primary-source=github-projects --project-id=abc-123` work as a non-interactive setup?
10. **CI integration**: should there be a `specrew roadmap sync` CLI command for CI to call as part of a scheduled sync? Composes with [Proposal 033 (Specrew Governance CLI)](file:///C:/Dev/Specrew/proposals/033-specrew-governance-cli.md).

## Risks

- **Vendor API drift**: external trackers' APIs change. Each vendor adapter is its own maintenance burden. Mitigation: per-adapter profile means each adapter has its own SemVer pin to its vendor SDK; profile owners (Specrew core for anchor adapters; community for others) are accountable for keeping up.
- **Credential security**: storing credentials for external trackers is sensitive. Mitigation: never plaintext in config; reference env vars / secrets file / OS keychain.
- **Sync conflicts hard to debug**: when an entry diverges, why? Mitigation: per-entry `source` + `last_synced_at` metadata + adapter logs in `.specrew/log/`.
- **MCP dependency**: some adapters depend on MCP servers (GitHub MCP, Linear MCP, etc.). Mitigation: fall back to vendor CLI / API when MCP unavailable; document the dependency tree.
- **Profile-system dependency**: this proposal depends on Proposal 052 shipping first. Mitigation: explicit sequencing in phase placement.
- **Multi-user numbering**: not solved here; deferred to Proposal 010. Mitigation: this proposal only works in single-maintainer mode until Proposal 010 ships; document the limitation explicitly.

## Cross-references

- **[Proposal 010 (Multi-Developer Reconciliation)](file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md)** — owns multi-user numbering specifics (Option E PR-assigned numbers recommended)
- **[Proposal 028 (Public Proposals Surface)](file:///C:/Dev/Specrew/proposals/028-public-proposals-surface.md)** — proposals adapter integration with INDEX auto-generation
- **[Proposal 033 (Specrew Governance CLI)](file:///C:/Dev/Specrew/proposals/033-specrew-governance-cli.md)** — `specrew roadmap sync / import / list` commands
- **[Proposal 047 (Project Governance Profile)](file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md)** — adapter selection becomes a configurable dial
- **[Proposal 048 (Dashboard Velocity Metric Refinement)](file:///C:/Dev/Specrew/proposals/048-dashboard-velocity-metric-refinement.md)** — dashboard surface for the "queue" section + drift warning
- **[Proposal 052 (Specrew Profile System)](file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md)** — profile-extensibility pattern (this proposal builds on it)
- **Memory: [Proposals pattern as opt-in profile (2026-05-19)](file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_proposals_pattern_as_opt_in_profile_2026_05_19.md)** — `proposal-driven-design` profile activates the proposals adapter
- **Memory: [Pre-spec phase in downstream projects (2026-05-19)](file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_pre_spec_phase_in_downstream_projects_2026_05_19.md)** — pre-spec pattern choice context
- **Memory: [Roadmap spine + input adapters (2026-05-19)](file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_roadmap_spine_input_adapters_2026_05_19.md)** — original architecture capture
- **F-017 / Proposal 009 (Velocity Dashboard)** — established the dashboard that depends on `roadmap.yml`
- **F-018 (Velocity Dashboard Visual Richness)** — extended the dashboard surface

## Status history

- 2026-05-19: candidate captured after maintainer (Alon Fliess) laid out the architectural framework during the F-022 review-boundary in flight. The capture consolidates three related methodology decisions surfaced during F-022:
  - Proposals as opt-in profile (not core methodology)
  - Pre-spec phase pattern choice (A external tracker / B skeleton specs / C proposals profile)
  - Roadmap spine + input adapters (this proposal)
  
  Multi-user numbering was discussed and Option E (PR-assigned numbers) recommended; this proposal references but defers to [Proposal 010](file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md) for the implementation.
