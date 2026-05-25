---
proposal: 115
title: Spec-First Concurrent Development Workflow — Spec-PR Serialization + Per-Developer Implementation Branches
status: candidate
phase: phase-3
estimated-sp: 28-38
priority-tier: 3
type: methodology
discussion: tbd
depends-on: []
composes-with:
  - 010 # Multi-Developer Reconciliation (Phase 5, 75 SP — covers FR-provenance + PR-time conflict classifier + Spec Steward mediator; 115 covers the workflow SHAPE that 010's machinery serves)
  - 057 # Roadmap Spine + Input Adapter Pattern (multi-dev visibility flows through roadmap)
  - 028 # Specrew Lifecycle Hardening + Proposal Metadata (task ownership metadata schema)
  - 035 # Session-State Durability (per-developer session isolation)
blocks: []
audience: methodology
---

# Spec-First Concurrent Development Workflow — Spec-PR Serialization + Per-Developer Implementation Branches

## Why

Today's Specrew lifecycle assumes **one developer per feature** through all 9 canonical boundaries (specify → clarify → plan → tasks → before-implement → implement → review-signoff → retro → iteration-closeout → feature-closeout). The model is elegant for solo work and small teams, but it serializes all developers behind whoever owns the active feature.

For teams that want to parallelize work without going through Proposal 010's full 75-SP multi-developer reconciliation, there's a leaner middle ground: **split the lifecycle into a sequential spec phase and a parallel implementation phase**. The spec phase produces an artifact (spec.md + plan.md + tasks.md) complete enough that multiple developers can implement task subsets independently. The implementation phase forks per-developer, with reconciliation only at PR-time.

User insight (2026-05-25 release-day discussion):

> "Spec PR merges first → per-developer feature branches → independent iterations."

This captures the model precisely:

1. **Phase A (sequential, single-dev, on main)**: One developer (or pair) runs specify → clarify → plan → tasks. Output committed as a "spec PR" with `.specs/<NNN>-<slug>/{spec.md, plan.md, tasks.md}` plus task-ownership metadata. PR reviewed + merged to main.
2. **Phase B (parallel, multi-dev, branches off main)**: Each developer branches from the now-merged spec, claims one or more tasks, runs implement → review-signoff → retro → iteration-closeout for their slice. PRs back to main in dependency order.
3. **Phase C (sequential, optional)**: Feature-closeout aggregates per-developer iterations into a feature-level retro + closeout-dashboard once all task PRs have merged.

The value proposition: most spec drift comes from incomplete tasks.md or unclear FR ownership at clarify time. If the spec phase produces a *truly complete* artifact, the implementation phase becomes embarrassingly parallel. Specrew's role shifts from "single-dev lifecycle guard" to "spec quality gate + reconciliation surface".

This is a smaller, more pragmatic capability than Proposal 010 (Multi-Developer Reconciliation, 75 SP). 115 captures ~60-70% of the team-scaling value at ~40% of the scope by deferring the hard problems (FR-provenance, automated conflict classification, Spec Steward mediator) to 010.

## What — Three-Phase Workflow Definition

### Phase A: Sequential Spec Phase (Single Branch off Main)

Single developer runs the spec phase to completion. The 4 sequential boundaries:

1. `specify` → `spec.md` (problem statement + acceptance criteria)
2. `clarify` → human-in-the-loop questions resolved; `.specrew/decisions.md` appended
3. `plan` → `plan.md` (technical approach + architecture decisions)
4. `tasks` → `tasks.md` with **per-task ownership candidates** (new field)

New `tasks.md` schema addition:

```markdown
## T003 — Add Cursor host package manifest

**Status**: pending
**Owner**: (unassigned)
**Owner candidates**: alice, bob
**Estimated SP**: 2
**Depends on**: T001, T002
**Independence**: high (no shared files with T001/T002 after merge)
**Description**: ...
```

`Owner` is the actual assignment (filled at Phase A close or Phase B start). `Owner candidates` is the spec author's suggestion. `Independence` rates how parallelizable this task is relative to its dependencies (low / medium / high). High-independence tasks are safe to parallelize; low-independence may need coordination.

Phase A closes with a "spec PR" containing only spec.md + plan.md + tasks.md + supporting artifacts (no implementation). PR reviewed for spec quality (no code review yet) and merged to main.

### Phase B: Parallel Implementation Phase (Per-Developer Branches off Main)

Each developer:

1. Pulls latest main (now containing the merged spec)
2. Creates feature branch off main: `git checkout -b <NNN>-<slug>-<developer-id>` (e.g., `045-cursor-host-alice`)
3. Claims tasks via `specrew task claim T003 T005` (new CLI surface — composes with Proposal 028 task metadata extensions)
4. Runs `specrew start --host <kind> "implementing T003 + T005 — Cursor manifest + skill catalog deployment"`
5. Specrew's lifecycle treats this as a normal feature with the iteration cycle, but:
   - **scope is the claimed task subset**, not the full feature
   - **iteration numbering is per-developer** (alice has her own `iterations/001/`, bob has his own `iterations/001/` on their respective branches)
   - **feature-closeout is gated by all developers' iteration-closeouts merging**, not just one
6. Per-developer iteration PRs go back to main as each developer completes their slice
7. Reviewer (per-PR, normal review process — composes with 089) approves on PR-by-PR basis

PR ordering follows task dependencies: T003 depends on T001 → T001's PR must land before T003's. Specrew's planner records the dep-graph in `tasks.md`; PR-time validator checks that prerequisite tasks are merged.

### Phase C: Feature-Closeout (Sequential, Optional, On Main)

When all task PRs are merged to main:

1. `specrew feature close <NNN>` runs feature-level retro + closeout-dashboard
2. Closeout aggregates per-developer iterations into a single dashboard view: which developer owned which tasks, total SP, iteration count across all developers, cross-developer learnings (e.g., "alice and bob both hit the same VS Code extension API quirk in different tasks; promote to corpus")
3. Feature-level retro identifies workflow drag points (was task ownership clear? did dep-graph hold up? were there cross-task refactors that should've been planned at spec time?)

Phase C is OPTIONAL for small teams — one developer can wear the closeout hat. Required for teams >2 to surface coordination learnings.

## How — Implementation Surface

### New `tasks.md` Schema Fields

| Field | Purpose | Optional? |
|---|---|---|
| `Owner candidates` | Spec author's suggested owners (comma-sep) | Yes (used when known at spec time) |
| `Owner` | Actual claiming developer | Yes (unset until claimed) |
| `Independence` | high / medium / low — parallelization safety rating | Yes (defaults to medium) |
| `Depends on` | Existing field — task-ID dependencies | Already exists in tasks.md |

Schema bump in `extensions/specrew-speckit/templates/tasks-template.md` + validator update.

### New CLI Surface

| Command | Purpose |
|---|---|
| `specrew task list` | Show all tasks in current feature with status + owner |
| `specrew task claim <task-id>...` | Claim one or more tasks for current developer (writes to `.specrew/task-assignments.yml`) |
| `specrew task release <task-id>...` | Release claimed tasks (return to unassigned pool) |
| `specrew task show <task-id>` | Show single task detail |
| `specrew feature parallel-status <NNN>` | Cross-developer view: who owns which tasks, branch names, PR status, iteration progress |

Composes with Proposal 033 (Specrew Governance CLI) — these are natural additions to the `specrew task` surface.

### New State File: `.specrew/task-assignments.yml`

Per-feature task ownership ledger. Tracked in git (not in `.gitignore`) so all developers see authoritative assignments:

```yaml
schema-version: 1
feature: 045
spec-ref: 'specs/045-cursor-host-package/'
assignments:
  - task: T001
    owner: alice
    branch: 045-cursor-host-alice
    claimed-at: '2026-05-26T09:00:00Z'
    iteration: 1
    pr: '#900'
    status: in-flight
  - task: T003
    owner: alice
    branch: 045-cursor-host-alice
    claimed-at: '2026-05-26T09:00:00Z'
    iteration: 1
    pr: '#900'  # T001 + T003 in same iteration (alice's choice; allowed if same branch)
    status: in-flight
  - task: T002
    owner: bob
    branch: 045-cursor-host-bob
    claimed-at: '2026-05-26T09:15:00Z'
    iteration: 1
    pr: null
    status: in-flight
  - task: T004
    owner: null
    status: unassigned
```

PR-time validator reads this to confirm claimed tasks are accounted for + dependency tasks are merged.

### Per-Developer Iteration Isolation

Today's iteration directory layout: `specs/<NNN>-<slug>/iterations/<III>/`. Globally numbered, single-developer assumption.

Under 115, two patterns considered:

**Option 1 (recommended)**: Each developer's branch has their own `iterations/<III>/` numbering (local-to-branch). Specs are shared (merged from Phase A spec PR) but iterations diverge per-branch. After PRs merge, main contains a UNION of all developers' iterations.

**Option 2**: Centrally-coordinated iteration numbering via a remote allocator (e.g., GitHub issue counter). More complex; adds external dependency.

Recommend Option 1 for the minimum-viable slice. Naming collision is handled by per-developer subdirectory: `iterations/<III>-<developer-id>/` if the same iteration number is used by 2 developers on different branches. Most cases won't collide because developers are typically on different iteration counts.

### PR-Time Validator

Extend `extensions/specrew-speckit/scripts/validate-governance.ps1` with:

- Check `.specrew/task-assignments.yml` claims against PR scope (PR-touched files should correspond to claimed tasks)
- Check that all dependency tasks (per `tasks.md Depends on`) are merged before this PR can land
- Cross-PR consistency: same task should not be claimed by multiple developers concurrently

### Documentation

- `docs/multi-developer-workflow.md` — full walkthrough from spec PR through parallel implementation through feature closeout
- `docs/user-guide.md` — add "Working in a team" section pointing to multi-developer-workflow
- `README.md` — single paragraph on team mode + link

## Open Questions

1. **Spec PR review semantics?** Today a feature spec is reviewed by Crew agents (planner, reviewer). Should Phase A spec PR also be reviewed by *human teammates* in addition to Crew agents? Recommend yes — spec quality matters more in concurrent mode because errors compound across N implementers.

2. **Spec amendment after Phase B starts?** If a developer in Phase B discovers a spec gap (missing FR, ambiguous acceptance criterion), what's the protocol? Options: (a) raise an amendment PR back to main spec; pause all Phase B developers until amendment lands; (b) handle locally via decisions.md addendum + flag to other devs. Recommend (a) for high-impact gaps, (b) for local clarifications. Need explicit guidance in docs.

3. **Cross-task refactors?** A developer working on T005 realizes they need to refactor a file owned by T003 (assigned to bob). Options: (a) coordinate with bob to merge his T003 first; (b) include the refactor in T005 + reconcile at PR-time; (c) raise an unowned "shared refactor" task that gets claimed via the same mechanism. Recommend (a) when bob is near complete, (c) when bob hasn't started, (b) for trivial cases.

4. **Solo-developer compatibility?** Most users will be solo. The new task-assignment machinery should be **opt-in or transparent** — solo developers shouldn't have to interact with task-assignments.yml at all unless they want to. Default: solo flow infers owner=`$(git config user.name)` automatically + skips multi-dev surfacing.

5. **Per-developer skill / artifact deployment?** When alice runs `specrew start --host claude` and bob runs `specrew start --host codex` on their branches, the `.specrew/team/`, `.specify/`, `.squad/` etc. files need to be consistent. Today they are because there's only one developer; under 115 they could drift. Recommend: artifacts are git-tracked (already are) + Phase A spec PR establishes the canonical config; Phase B developers inherit. Composes with Proposal 116's reconciliation machinery if config evolves mid-implementation.

6. **GitHub Issues / Linear integration?** Many teams already use external trackers for task assignment. Should `task-assignments.yml` be the source-of-truth, or should it sync from / to external trackers? Recommend: standalone for v1; integration adapters (composes with Proposal 057 Input Adapter Pattern) as Phase 4 follow-up.

7. **Conflict on `tasks.md`?** Phase A merges tasks.md to main with all tasks defined. If a developer in Phase B needs to add a sub-task they didn't anticipate, that's a tasks.md edit. Options: (a) require amendment PR to main tasks.md before sub-task work begins; (b) allow per-branch task additions as inline sub-IDs (T003.1, T003.2) that reconcile to main at feature-closeout. Recommend (b) for non-blocking sub-tasks, (a) for tasks that need cross-developer coordination.

## Composition Notes

### With Proposal 010 (Multi-Developer Reconciliation — Phase 5, 75 SP)

115 and 010 are sequential layers:

- **115** establishes the workflow SHAPE (spec-PR-first + per-developer branches + task-assignment ledger). Simpler reconciliation: PR-time validator + dependency check.
- **010** adds the heavy reconciliation MACHINERY (FR-provenance tracking, automated conflict classification at PR-time, Spec Steward mediator for cross-developer spec disputes).

Recommendation: ship 115 first as a leaner team-scaling capability (~28-38 SP, Phase 3). Use it for ~3-6 months on real teams. Then ship 010 as the next layer once empirical data identifies where the conflict-classification + mediator machinery actually pays off. Risk of shipping 010 without 115 first: building 75 SP of reconciliation infrastructure based on speculation about team friction patterns.

### With Proposal 057 (Roadmap Spine + Input Adapter Pattern)

057's roadmap.yml is the cross-feature visibility surface. 115 introduces per-developer feature progress. Combining: roadmap.yml surfaces "feature 045 has 4 tasks: 2 in-flight (alice), 1 in-flight (bob), 1 unassigned". Composes naturally as a roadmap-dashboard extension.

### With Proposal 028 (Lifecycle Hardening + Proposal Metadata)

028's task-metadata schema needs the Owner / Owner candidates / Independence fields. 115's tasks.md schema additions live in 028's space. Could ship together if 028 is still drafting; otherwise 115 extends 028's schema.

### With Proposal 035 (Session-State Durability)

035 covers per-developer session isolation (each developer has their own `.specrew/state/` that doesn't cross-pollute). Already addresses one major concurrent-development concern; 115 builds on this assumption.

## Not in Scope

- Automated task auto-assignment (skill-based matching, workload balancing) — out of scope; humans claim tasks
- FR-provenance tracking and automated cross-developer spec-conflict classification — that's Proposal 010
- Real-time collaborative editing of spec.md / plan.md during Phase A — out of scope; spec phase remains single-author (or pair-author via traditional pair programming)
- Cross-feature concurrent work — 115 covers within-feature concurrency only; cross-feature concurrency is a separate scaling axis already partially supported via independent feature branches
- Distributed-system style consensus protocols for task ownership — `.specrew/task-assignments.yml` is git-tracked with PR review for changes; that's sufficient consistency for human-scale teams

## Empirical Motivation Captured

- **2026-05-25** — User raised the question while planning v0.27.x next-step work: "How do we handle concurrent multi-developer work without Proposal 010's full 75-SP scope?" User-invented model: spec-PR-first serialization → per-developer feature branches → independent iterations. This proposal captures that model.
- **Industry pattern** — The model mirrors common open-source RFC processes: design doc reviewed and merged first; implementation tasks parallelized across contributors. Specrew makes this explicit at the methodology layer instead of relying on team convention.
- **Project history** — Specrew's own development has been solo + sequential (Alon as solo developer with Crew agents). The need for 115 emerged at the boundary where Specrew transitions from "solo tool" to "team-ready tool" — coinciding with v0.27.0's public-flip and external-tester onboarding.

## Status History

- **2026-05-25** — Drafted as user-invented methodology proposal during v0.27.0 launch-day next-step planning. Candidate status. Phase 3 sequencing (post-Cursor + Aider/Amp/OpenCode Tier-1 wave; before Proposal 010's full reconciliation infrastructure). Composes with shipped + drafted infrastructure (057, 028, 035) — no hard prereqs beyond the existing per-host architecture.
