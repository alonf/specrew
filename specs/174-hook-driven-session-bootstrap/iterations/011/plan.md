# Iteration Plan: 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 22/22 story_points
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

> **HUMAN-APPROVED CAPACITY RAISE to 22 (plan verdict `f174-i011-plan-tasks-approved`).** The maintainer
> raised the iteration cap from 20 to 22 to keep the DF-3/4/5/7 cluster one coherent iteration (DF-1/DF-2
> are small and touch the same bootstrap/directive surface as the core — splitting them would add more
> lifecycle overhead than risk reduction). Estimates are NOT deflated to fit. **Defer priority if
> execution overruns: T008/T009 (DF-1/DF-2) FIRST — never the integrity core (T001–T006), never the T007
> tests, never the re-dogfood acceptance.**

## Scope Summary

Fix the **DF-3/4/5/7 boundary-authoring + verdict-integrity cluster** surfaced by the iteration-010
multi-host dogfood, per the locked decisions
(`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/011/fix-plan-draft.md`)
and the specify/clarify/plan rulings. Requirements: **FR-022** (iteration-011 amendment — capture ≠
author; mechanical Stop-hook persistence is load-bearing), **FR-026** (verdict-integrity), **FR-027**
(committed ≠ authorized resume), plus **SC-012/013/014/015**. DF-1/DF-2 trace to FR-002/FR-022 (no new
FR). Out of scope: DF-6 (cursor — within F-174, a later iteration), DF-8 (governance-edit — separate
proposal).

## Why this iteration

The cluster is one causal chain: `Write-SpecrewHandoverContext` not agent-callable (DF-7) → boundary
packet + `active_boundary` never persist (DF-3) → resume reads committed-as-approved (DF-4) → a bare
"continue" advanced two un-authorized boundaries + a FABRICATED verdict (DF-5). Core principle: **do
NOT rely on agent compliance for integrity-critical state** — the fixes must be mechanical/captured.

## Approach (sequence A → C → B → D/E)

- **Fix A (authoring, FR-022)** — A3 hybrid: a TESTED agent-callable command/skill (fast-path) **plus**
  the LOAD-BEARING, non-skippable Stop-hook capture of the rendered packet into the body + setting
  `active_boundary`; **plus the clobber guard** (never overwrite a richer authored body — SC-015). A
  first: the authored packet must land before anything can read or verify it.
- **Fix C (verdict-integrity, FR-026)** — capture the human's recognized verdict token tied to the
  boundary; boundary-sync consumes THAT; stop fabrication; identity only from a proven host surface
  else unknown/unattributed; ambiguous/contradictory/untied → un-authorized. C after A.
- **Fix B (committed ≠ authorized resume, FR-027)** — the resume + `specrew where` read
  `last_authorized_boundary` as decisive, surface "awaiting verdict," never auto-advance. B consumes
  the honest state A+C produce.
- **Fix D/E (DF-1/DF-2, small)** — pointer-mode recap synthesis (D) + version/branch in the directive
  (E). Independent; sequencing-free; first to defer if the iteration overruns.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Expose a TESTED public/agent-callable authoring command/skill around the handover writer — PROVE/EXPORT the callable surface (do NOT assume `Write-SpecrewHandoverContext` is exported; exporting + testing it is part of this task) | FR-022 | US-3 | 2 | Implementer | `scripts/internal/bootstrap/HandoverStore.ps1`, `Specrew.psd1`, `scripts/specrew*.ps1`, `.claude/skills/**` | planned | TBD | | |
| T002 | Mechanical Stop-hook packet capture (A2, LOAD-BEARING) — capture the rendered boundary packet into the body + set `active_boundary`; non-skippable | FR-022 | US-3 | 3 | Implementer | `scripts/internal/bootstrap/HandoverStore.ps1`, `scripts/internal/*stop*` | planned | TBD | | |
| T003 | Clobber guard — capture MUST NOT overwrite a richer authored body with placeholder/stale (SC-015) | FR-022 | US-3 | 2 | Implementer | `scripts/internal/bootstrap/HandoverStore.ps1` | planned | TBD | | |
| T004 | Verdict capture from transcript — recognized token tied to the boundary; ambiguous/contradictory/untied → un-authorized + surface | FR-026 | US-3 | 3 | Implementer | `scripts/internal/bootstrap/*`, `scripts/internal/sync-boundary-state.ps1` | planned | TBD | | |
| T005 | Boundary-sync integrity — consume the captured verdict; stop fabrication; identity only from proven surface else unattributed; no git-committer | FR-026 | US-3 | 3 | Implementer | `scripts/internal/sync-boundary-state.ps1` | planned | TBD | | |
| T006 | Committed ≠ authorized resume + `specrew where` — read `last_authorized_boundary` decisive; surface "awaiting verdict"; never auto-advance | FR-027 | US-3 | 3 | Implementer | `scripts/internal/specrew-bootstrap-provider.ps1`, `scripts/specrew-where.ps1` | planned | TBD | | |
| T007 | Deterministic tests — authoring round-trip (SC-012), clobber-preserve (SC-015), verdict-integrity unattributed + un-authorized (SC-013), committed ≠ authorized (SC-014) | SC-012, SC-013, SC-014, SC-015 | US-3 | 3 | Implementer | `tests/bootstrap/**` | planned | TBD | | |
| T008 | DF-1 pointer-mode recap synthesis — push pointer-mode hosts to synthesize a decisions recap, not just lens names (first to defer if overrun) | FR-002, FR-022 | US-3 | 2 | Implementer | `scripts/internal/specrew-bootstrap-provider.ps1` | planned | TBD | | |
| T009 | DF-2 version/branch carried in the bootstrap directive so the pointer-mode banner is complete (first to defer if overrun) | FR-002 | US-1 | 1 | Implementer | `scripts/internal/specrew-bootstrap-provider.ps1` | planned | TBD | | |

**Capacity: 22/22** (T001–T009 = 2+3+2+3+3+3+3+2+1). Human-approved cap raise (plan verdict). Defer
priority on overrun: T008/T009 first.

## Acceptance gate (review evidence — NOT an SP-counted task)

A focused **re-dogfood** is the iteration acceptance gate (clarify/plan instruction 4): a **fresh-session,
real-host** proof of the DF-3/4/5/7 scenario — one host authors a boundary handover; a DIFFERENT host
resumes and inherits the AUTHORED packet (not placeholders, SC-012); a bare "continue" does NOT advance
an un-authorized boundary and the sync does NOT fabricate/mis-attribute a verdict (SC-013); the resume
surfaces "awaiting verdict" (SC-014). The **no-hook Antigravity** behavior is recorded HONESTLY (records
un-authorized + reconciles via `specrew start`; never infers approval). Real-host behavior is the gate,
per the iteration-010 falsification lesson — green synthetic tests (T007) are necessary, not sufficient.

## Effort Model

| Setting | Value |
| ------- | ----- |
| Effort Unit | story_points |
| Capacity per Iteration | 22 |
| Iteration Bounding | scope |
| Time Limit (hours) | n/a |
| Overcommit Threshold | 1.0 |
| Defer Strategy | manual |
| Calibration Enabled | true |

> Capacity per Iteration RAISED 20 → 22 for this iteration by human-approved plan verdict
> (`f174-i011-plan-tasks-approved`) to keep the cluster coherent; estimates not deflated.

## Traceability Summary

- **FR-022** (capture ≠ author; mechanical persistence load-bearing): T001 (tested callable surface),
  T002 (load-bearing Stop capture), T003 (clobber guard). SC-012, SC-015.
- **FR-026** (verdict-integrity): T004 (capture), T005 (sync integrity + identity). SC-013.
- **FR-027** (committed ≠ authorized resume): T006. SC-014.
- **FR-002 / FR-022** (small fixes — clarify instruction 5): T008 (DF-1), T009 (DF-2).
- **SC-012/013/014/015**: T007 (deterministic tests) + the re-dogfood acceptance gate (run at review).

## Clarify rulings carried into the plan

- **Match-strictness (instruction 1)**: T004 builds against a recognized verdict token tied to the named
  boundary; ambiguous/contradictory/untied → un-authorized + surfaced (never "any human turn").
- **Antigravity fallback (instruction 2)**: no-hook hosts record un-authorized; T006 + the acceptance gate
  guarantee resume / `specrew start` surfaces "awaiting verdict," never infers approval or auto-advances.
- **SC-013 (instruction 3)** tightened + **SC-015 clobber (instruction 4)** added in the spec; T005/T007
  and T003/T007 carry their proofs.

## Phase Baseline

Baseline: iteration-010 HEAD (`c5756473`) — F-174 iteration 010 closed (accepted, delivered scope).
