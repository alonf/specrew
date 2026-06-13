# Iteration Plan: 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 19/20 story_points
**Started**: 2026-06-13
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

> **Capacity 19/20 (the integrity core fits); the DF-1/DF-2 capacity call is the plan verdict.** The
> committed table (Fix A/B/C + deterministic tests, T001–T007 = 19 SP) fits the 20 cap. The two small
> fixes DF-1/DF-2 (3 SP) are kept explicit + tracked in the **Carried (capacity-gated)** section below —
> they push the cluster to 22 SP, over cap. The maintainer's call at the plan verdict: raise the cap to
> a human-approved 22 (the "make it bulletproof" path, like iteration 010's 22/20) and pull them in, or
> land them as an iteration-012 fast-follow. Either way they remain explicit tasks (clarify instruction 5).

## Scope Summary

Fix the **DF-3/4/5/7 boundary-authoring + verdict-integrity cluster** surfaced by the iteration-010
multi-host dogfood, per the locked decisions
(`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/011/fix-plan-draft.md`)
and the specify/clarify rulings. Requirements in scope: **FR-022** (iteration-011 amendment —
capture ≠ author; mechanical Stop-hook persistence is load-bearing), **FR-026** (verdict-integrity),
**FR-027** (committed ≠ authorized resume), plus **SC-012/013/014/015**. DF-1/DF-2 trace to existing
FR-002/FR-022 (no new FR) and are carried explicitly (capacity-gated). Out of scope: DF-6 (cursor —
within F-174, a later iteration), DF-8 (governance-edit — separate proposal).

## Why this iteration

The cluster is one causal chain: `Write-SpecrewHandoverContext` not agent-callable (DF-7) → boundary
packet + `active_boundary` never persist (DF-3) → resume reads committed-as-approved (DF-4) → a bare
"continue" advanced two un-authorized boundaries + a FABRICATED verdict (DF-5). Core principle: **do
NOT rely on agent compliance for integrity-critical state** — the fixes must be mechanical/captured,
not instructional.

## Approach (sequence A → C → B, then carried D/E)

- **Fix A (authoring, FR-022)** — A3 hybrid: an agent-callable command/skill (fast-path) **plus** the
  LOAD-BEARING, non-skippable Stop-hook capture of the rendered packet into the body + setting
  `active_boundary`; **plus the clobber guard** (never overwrite a richer authored body — SC-015). A
  is first: the authored packet must land before anything can read or verify it.
- **Fix C (verdict-integrity, FR-026)** — capture the human's recognized verdict token tied to the
  boundary; boundary-sync consumes THAT; stop fabrication; identity only from a proven host surface
  else unknown/unattributed; ambiguous/contradictory/untied → un-authorized. C after A.
- **Fix B (committed ≠ authorized resume, FR-027)** — the resume + `specrew where` read
  `last_authorized_boundary` as decisive, surface "awaiting verdict," never auto-advance. B consumes
  the honest state A+C produce.
- **Fix D/E (DF-1/DF-2, carried — capacity-gated)** — pointer-mode recap synthesis (D) + version/branch
  in the directive (E). Independent; sequencing-free.
- **Acceptance** — a focused re-dogfood of the DF-3/4/5/7 scenario is the iteration acceptance gate (run
  at review; real-host behavior is the gate, per the iteration-010 falsification lesson).

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Expose an agent-callable authoring command/skill (A1 fast-path; wraps `Write-SpecrewHandoverContext`) | FR-022 | US-3 | 2 | Implementer | `scripts/internal/bootstrap/HandoverStore.ps1`, `scripts/specrew*.ps1`, `.claude/skills/**` | planned | TBD | | |
| T002 | Mechanical Stop-hook packet capture (A2, LOAD-BEARING) — capture the rendered boundary packet into the body + set `active_boundary`; non-skippable | FR-022 | US-3 | 3 | Implementer | `scripts/internal/bootstrap/HandoverStore.ps1`, `scripts/internal/*stop*` | planned | TBD | | |
| T003 | Clobber guard — capture MUST NOT overwrite a richer authored body with placeholder/stale (SC-015) | FR-022 | US-3 | 2 | Implementer | `scripts/internal/bootstrap/HandoverStore.ps1` | planned | TBD | | |
| T004 | Verdict capture from transcript — recognized token tied to the boundary; ambiguous/contradictory/untied → un-authorized + surface | FR-026 | US-3 | 3 | Implementer | `scripts/internal/bootstrap/*`, `scripts/internal/sync-boundary-state.ps1` | planned | TBD | | |
| T005 | Boundary-sync integrity — consume the captured verdict; stop fabrication; identity only from proven surface else unattributed; no git-committer | FR-026 | US-3 | 3 | Implementer | `scripts/internal/sync-boundary-state.ps1` | planned | TBD | | |
| T006 | Committed ≠ authorized resume + `specrew where` — read `last_authorized_boundary` decisive; surface "awaiting verdict"; never auto-advance | FR-027 | US-3 | 3 | Implementer | `scripts/internal/specrew-bootstrap-provider.ps1`, `scripts/specrew-where.ps1` | planned | TBD | | |
| T007 | Deterministic tests — authoring round-trip (SC-012), clobber-preserve (SC-015), verdict-integrity unattributed + un-authorized (SC-013), committed ≠ authorized (SC-014) | SC-012, SC-013, SC-014, SC-015 | US-3 | 3 | Implementer | `tests/bootstrap/**` | planned | TBD | | |

**Capacity: 19/20** (T001–T007 = 2+3+2+3+3+3+3). The re-dogfood of the DF-3/4/5/7 scenario is the
iteration ACCEPTANCE gate (SC-012/013/014), run at review — not an SP-counted task.

## Carried (capacity-gated): DF-1 / DF-2 — the plan-verdict capacity call

These two small fixes are explicit, tracked tasks (clarify instruction 5 — they must not disappear) but
they push the cluster to **22 SP, over the 20 cap**, so they sit here pending the maintainer's capacity
verdict: **(a)** raise the cap to a human-approved **22** and fold them into the committed table (one
coherent iteration, the "bulletproof" path), or **(b)** land them as an **iteration-012 fast-follow**.

| Task | Title | Requirement | Story | Effort |
| ---- | ----- | ----------- | ----- | ------ |
| T008 | DF-1 pointer-mode recap synthesis — push pointer-mode hosts to synthesize a decisions recap, not just lens names | FR-002, FR-022 | US-3 | 2 |
| T009 | DF-2 version/branch carried in the bootstrap directive so the pointer-mode banner is complete | FR-002 | US-1 | 1 |

## Effort Model

| Setting | Value |
| ------- | ----- |
| Effort Unit | story_points |
| Capacity per Iteration | 20 |
| Iteration Bounding | scope |
| Time Limit (hours) | n/a |
| Overcommit Threshold | 1.0 |
| Defer Strategy | manual |
| Calibration Enabled | true |

## Traceability Summary

- **FR-022** (capture ≠ author; mechanical persistence load-bearing): T001 (command fast-path), T002
  (load-bearing Stop capture), T003 (clobber guard). SC-012, SC-015.
- **FR-026** (verdict-integrity): T004 (capture), T005 (sync integrity + identity). SC-013.
- **FR-027** (committed ≠ authorized resume): T006. SC-014.
- **FR-002 / FR-022** (small fixes — clarify instruction 5): T008 (DF-1), T009 (DF-2), carried capacity-gated.
- **SC-012/013/014/015**: T007 (deterministic tests) + the re-dogfood acceptance gate (run at review).

## Clarify rulings carried into the plan

- **Match-strictness (instruction 1)**: T004 builds against a recognized verdict token tied to the named
  boundary; ambiguous/contradictory/untied → un-authorized + surfaced (never "any human turn").
- **Antigravity fallback (instruction 2)**: no-hook hosts record un-authorized; T006 guarantees resume /
  `specrew start` surfaces "awaiting verdict," never infers approval or auto-advances.
- **SC-013 (instruction 3)** tightened + **SC-015 clobber (instruction 4)** added in the spec; T005/T007
  and T003/T007 carry their proofs.

## Phase Baseline

Baseline: iteration-010 HEAD (`c5756473`) — F-174 iteration 010 closed (accepted, delivered scope).
