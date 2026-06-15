# Iteration Plan: 010 — Resilient resume reconciliation + host-universal recovery

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 22/20 story_points
**Started**: 2026-06-11
**Feature**: 174-hook-driven-session-bootstrap
**Opened**: 2026-06-11 (maintainer-approved; scope finalized after the Prop-145 review + resilience audit)
**Baseline**: iteration-009 HEAD (`e4822428`)

> **HUMAN-APPROVED OVERCOMMIT (22/20).** The maintainer's bar is "robustness first, then restart performance;
> leave nothing open in this area." The resilience audit (workflow `wnd4i6d98`) found real common-path defects
> and an antigravity recovery hole; the maintainer explicitly authorized one over-capacity robustness iteration
> rather than a split, accepting the extra story points.

## Why this iteration

Drift D-016 (`f174-i009-defer-reconciliation-to-010`) + the Proposal-145 review + the 6-dimension resilience
audit. Guiding priority: **robustness, then restart performance.** Findings that force the scope:

1. **Resume replays a stale snapshot** — `SessionBootstrapManager` never re-computes the delta on SessionStart.
2. **`specrew start` recovers NOTHING** — it has zero handover/bootstrap references; the resume surface is
   hook-only, so **antigravity** (no hooks) can neither capture nor recover. The recovery path must be SHARED.
3. **Real common-path bugs:** the hollow-handover detector is dead code (M2); handover write failures are
   silently swallowed + a concurrent-writer race on fixed temp names (M3); copilot/cursor may silently drop
   the whole SessionStart surface like codex does (M1).
4. **Non-durable conversation** isn't captured anywhere; `from_host: host` mislabel.

## Approach (robustness-first; restart stays cheap)

- **Shared resume reconciliation (the core):** one cheap `Get-SpecrewSessionDelta` (a single `git status`) +
  a reconciliation directive ("last stop X; changed since [...]; read + continue") in a component called by
  BOTH the SessionStart hook AND `specrew start` — so recovery is host-universal incl. antigravity. The resume
  stays a lean pointer (grounding + pointer + intent), never heavy analysis — that is the performance bound.
- **Conversation capture, best-effort per host:** read the host transcript where exposed (Claude
  `transcript_path`) on Stop (+ PostToolUse), so the non-durable intent survives; mark the honest floor where
  a host exposes no transcript.
- **Fix the bugs (robustness):** M2 hollow detector (mean it or delete it), M3 writer (surface failures,
  per-PID temp, corrupt-read `.old` fallback), M1 copilot/cursor surface verification + lean-pointer fallback.
- **Tracking surfacing, `from_host` fix, docs** for the honest residuals.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T001 | Resume reconciliation in a SHARED component: re-compute the cheap delta + the "changed since last stop -> read + continue" directive | FR-022 | US-1 | 3 | Implementer | done |
| T002 | Conversation capture, best-effort per host (read the transcript where exposed — Claude `transcript_path` — on Stop + mid-turn; honest floor elsewhere) | FR-022 | US-1 | 4 | Implementer | done |
| T003 | Tracking surfacing (workshop lens-progress + gate-stop state into the handover + directive) **+ M2: fix-or-delete the dead hollow-handover detector** | FR-022 | US-1 | 4 | Implementer | done |
| T004 | Fix `from_host: host` — the workshop-skill `--source workshop` refresh passes `--host-kind` | FR-009 | US-1 | 1 | Implementer | done |
| T005 | Codex array-shape `~/.codex/hooks.json` self-heal regression test | SC-004 | US-1 | 1 | Implementer | done |
| T006 | Tests (reconciliation, conversation, tracking, from_host, **hard-kill simulation**, per-host) **+ M3: surface handover write failures, per-PID temp names (kill the writer race), `.old` fallback on corrupt read** | SC-004 | US-1 | 3 | Implementer | done |
| T007 | M1: copilot/cursor oversized-`additionalContext` surface verification + lean-pointer fallback (so the SessionStart surface — incl. the reconciliation directive — isn't silently dropped) | FR-002 | US-1 | 2 | Implementer | done |
| T008 | `specrew start` reads the handover + runs the SHARED reconciliation -> **antigravity + every `specrew start` launch recovers context** (host-universal recovery, not hook-only) | FR-022 | US-1 | 3 | Implementer | done |
| T009 | Docs: antigravity's no-hook/no-capture limit (recover-via-`specrew start`, work survives on disk) + the universal hard-kill conversation-loss floor | FR-008 | US-2 | 1 | Implementer | done |

**Capacity: 22/20** (T001 3 + T002 4 + T003 4 + T004 1 + T005 1 + T006 3 + T007 2 + T008 3 + T009 1 = 22).
**Human-approved overcommit** (maintainer: robustness > capacity for this iteration).

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

- **FR-022** (resume restores useful context): T001 (shared reconciliation), T002 (conversation), T003
  (tracking), T008 (specrew start recovery) — the load-bearing realization.
- **FR-009 / FR-002** (hook-driven bootstrap + surfacing): T004 (from_host), T007 (copilot/cursor surface).
- **FR-008** (docs): T009.
- **SC-004** (test integrity): T005, T006 (incl. the M3 writer hardening + hard-kill simulation).

## Honest residuals (marked, not pretended-covered — to be documented in T009)

- **Hard-kill conversation loss is UNIVERSAL and UNCLOSABLE.** SIGKILL/crash/power-loss fires no hook on any
  host; the non-durable conversation tail since the last capture is lost. Durable state (git/fs) always
  survives + is re-derived on resume. On Claude, "last capture" is the last PostToolUse (seconds); on
  codex/copilot/cursor, the last graceful Stop.
- **Antigravity cannot CAPTURE** (no hooks). It RECOVERS via `specrew start` + reconciliation (T008); its work
  survives on disk and is re-derived by the next session. Documented in T009.

## Out of scope (separate chore, different subsystem)

- `scaffold-reviewer-artifacts.ps1` StrictMode `.Count` crash (governance tooling, not handover/resume).
