# Iteration Plan: 010 — Lean resume reconciliation + workshop/gate-stop tracking

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 12/20 story_points
**Started**: 2026-06-11
**Feature**: 174-hook-driven-session-bootstrap
**Opened**: 2026-06-11 (maintainer-approved, after the iteration-009 cross-host dogfood + the design review)
**Baseline**: iteration-009 HEAD (`e4822428`)

## Why this iteration

Iteration 009's live cross-host dogfood proved the hook-primary handover is never hollow and hands off across
hosts, but reframed its VALUE (drift D-016, defer entry `f174-i009-defer-reconciliation-to-010`):

1. **The resume replays a stale snapshot.** `SessionBootstrapManager` never re-computes the delta on
   SessionStart, so when the last Stop predates the latest work (codex/copilot have no PostToolUse; a hard
   kill fires no Stop), the resume shows stale context and never directs the agent to read what changed.
2. **PostToolUse mid-turn refresh is the wrong lever.** The durable state is on disk (workshop lens files,
   the tree), so refreshing every tool call snapshots something cheaply re-derivable on resume — at a
   `git status`-per-tool-call cost.
3. **The workshop lens / gate-stop is not surfaced** — it is only inferable from the listed files.
4. **`from_host: host`** in the workshop-skill `--source workshop` refresh (it does not pass `--host-kind`).

## Approach (maintainer-agreed in the dogfood design review)

Re-cast the handover as a **lean pointer + grounding + non-durable intent**, and move the work to the RESUME
read (which is cheap), not the write frequency. The resume must stay lean — the budget is already spent on
loading the Specrew contract — so it GROUNDS + POINTS; the agent (already paying the context cost) does the
reading.

- **Resume reconciliation (the core):** SessionStart re-computes the cheap `Get-SpecrewSessionDelta` (one
  `git status`) and emits a reconciliation directive: *"last captured stop was `<boundary>`; files changed
  since: `[...]`; read them and continue from the real state — the snapshot may predate your latest work."*
- **Dial PostToolUse back:** off-by-default / throttled (the durable state is on disk). Write on Stop for
  grounding; reconcile on resume. Reclaim the per-tool-call cost.
- **Tracking surfacing:** fold the workshop lens-progress (done / in-progress / next, from
  `lens-applicability.json` + `workshop/`) and the precise gate-stop state into the handover + the resume
  directive, so "which phase" is explicit, not inferred.
- **`from_host` fix:** the workshop-skill refresh passes `--host-kind` (or the provider resolves the real
  host), killing the `from_host: host` mislabel.
- **Test debt carried from iteration 009:** the codex array-shape self-heal regression test.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T001 | Resume reconciliation: `SessionBootstrapManager` re-computes the cheap delta on SessionStart + emits the reconciliation directive ("last stop X; changed since [...]; read + continue") | FR-022 | US-1 | 3 | Implementer | planned |
| T002 | Dial PostToolUse back: off-by-default / throttled in `refocus-scopes.json` + `deploy-refocus-hooks.ps1` (write on Stop, reconcile on resume) | FR-009 | US-1 | 2 | Implementer | planned |
| T003 | Tracking surfacing: workshop lens-progress (done/next) + gate-stop state from `lens-applicability.json` + `workshop/`, folded into the handover + resume directive | FR-022 | US-1 | 3 | Implementer | planned |
| T004 | Fix `from_host: host`: the workshop-skill `--source workshop` refresh passes `--host-kind` (or the provider resolves the real host) | FR-009 | US-1 | 1 | Implementer | planned |
| T005 | Carried test debt: committed regression test for the codex array-shape `~/.codex/hooks.json` self-heal | SC-004 | US-1 | 1 | Implementer | planned |
| T006 | Tests: resume reconciliation (stale-snapshot -> re-computed delta + directive), PostToolUse-dialed-back, tracking surfacing, from_host | SC-004 | US-1 | 2 | Implementer | planned |

**Capacity: 12/20** (T001 3 + T002 2 + T003 3 + T004 1 + T005 1 + T006 2 = 12). Hand-driven dev iteration on
the iter-009 baseline; the resume reconciliation is the load-bearing change.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments. |

## Traceability Summary

- **FR-022** (the handover enables resume to restore useful context): T001 (reconciliation), T003 (tracking
  surfacing) — the load-bearing realization, evolving the iter-009 snapshot into an actively-reconciled
  resume.
- **FR-009** (the hook-driven session bootstrap): T002 (PostToolUse dial-back), T004 (from_host fix).
- **SC-004** (test integrity): T005 (codex self-heal test debt), T006 (the iteration's tests).

## Out of scope (fast-follow)

- Transcript-tail enrichment (lift the rendered packet / last user instruction from the host transcript) —
  strictly additive on top of the reconciliation base.
- The `scaffold-reviewer-artifacts.ps1` StrictMode `.Count` crash (found at the iter-009 close) — a separate
  tooling-defect chore.
