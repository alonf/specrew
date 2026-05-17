---
proposal: 036
title: Lifecycle Branch Reconciliation
status: draft
phase: phase-2
estimated-sp: 13
discussion: tbd
---

# Lifecycle Branch Reconciliation

## Why

Single-developer SDLC concurrent-edit safety: a feature branch can fall behind `main` for the duration of a multi-iteration feature (weeks). Manual merge brings risk of:

- Stale governance artifacts colliding (roadmap.yml, validator definitions, coordinator prompts)
- Auth-record commit references becoming invalid if rebase is used
- Reconciliation gaps where `specs/<feature>/` artifacts drift from main's lifecycle conventions
- No structured "merge plan" surface for what needs human attention before merging

User framing: "a pillar in our SDLC, promotes stability and correctness." Required precursor to Phase 5 Multi-Developer Reconciliation.

## What

Source spec drafted at file:///C:/Dev/SpecrewDraft/branch-reconciliation.md (~330 lines, 10 clarify-time questions).

### Five pillars

1. **Reconciliation timing** — three triggers:
   - **R1 post-planning**: after `/speckit.plan` succeeds (before implementation begins)
   - **R2 pre-PR**: at feature-closeout boundary before PR creation
   - **R3 on-request**: explicit `specrew reconcile` command for ad-hoc reconciliation

2. **File-class conflict matrix** — `.specrew/merge-policy.yml` declares per-file-class policy:
   - Lifecycle artifacts (specs, iterations) — never conflict from main; if they do, structural error
   - Validator/governance files — merge-conflict requires explicit human resolution
   - Code files — standard 3-way merge with conflict markers
   - Roadmap / docs — heuristic merge with operator notification

3. **Merge plan artifact** — `.specrew/merge-plan.md` captures what's being reconciled, conflict classes touched, validator state before/after, files needing human attention. Drives the operator's decision.

4. **Post-merge verification** — after reconciliation:
   - Validator runs on the merged tree
   - Stale-reference scan on file:/// URLs in iteration artifacts
   - Dashboard re-render to surface any drift
   - Auth-record integrity check (commit references in `.squad/decisions.md`)

5. **Boundary integration + audit trail** — reconciliation events recorded in `.squad/decisions.md` with timestamps, conflict classes, and operator resolutions. Composes with Substantive Interaction Model (F-016) for handoff format.

### LOCKED architectural constraint

**MERGE only, NEVER rebase.** F-016 commit-reference auth records (in `.squad/decisions.md`) would be invalidated by rebase. Locked at feature-spec time; not a clarify-time choice.

### Out of scope

- Multi-developer reconciliation (Phase 5 / Proposal 010 territory)
- Auto-resolving conflicts without operator review
- Force-pushing or history rewriting

## Effort

- **Iteration 1** (~7-9 SP): R1 + R2 timing triggers + merge-plan artifact + post-merge validator run
- **Iteration 2** (~4-6 SP): R3 on-request command + cross-class conflict matrix + dashboard integration
- **Total**: ~12-15 SP

Single-developer precursor to Phase 5 Multi-Developer Reconciliation (~75 SP, Proposal 010); deliberately scoped smaller.

## Phase placement

**Phase 2**, after F-019 (shipped) and **before any concurrency-introducing feature** AND **before public flip** so external contributors meet a stable reconciliation pattern.

## Open questions

1. Should R1 (post-planning) and R2 (pre-PR) reconciliation be MANDATORY or OPT-IN?
2. File-class matrix granularity — start with 4 broad classes or aim for 10+ specific?
3. Conflict-marker format for governance files (standard `<<<<<<<` markers vs structured YAML conflict-block)?
4. Should `specrew reconcile` block on validator failure or proceed with operator override?
5. Dashboard surface for in-flight reconciliation state (yes/no, per-feature)?
6-10: full clarify-time question set in the source spec.

## Risks

- Merge plan generation may be expensive on large branches; need bounded computation
- Operator fatigue if R1+R2 fire on every feature (mitigation: make R1 conditional on main-drift threshold, e.g., 10+ commits behind)

## Cross-references

- Hard prerequisite for [010](010-multi-developer-reconciliation.md) (multi-developer scope inherits the single-developer machinery)
- Composes with [035](035-session-state-durability.md) (reconciliation events update durable state files)
- Source artifact: file:///C:/Dev/SpecrewDraft/branch-reconciliation.md

## Status history

- 2026-05-16: captured as memory; source spec drafted same session
- 2026-05-18: promoted to draft proposal during memory→proposals consolidation
