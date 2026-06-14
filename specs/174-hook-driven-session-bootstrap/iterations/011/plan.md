# Iteration Plan: 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 32/32 story_points
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
- **Fix C (verdict-integrity, FR-026)** — stop fabrication and capture the human's REAL verdict.
  **Refined by decision `f174-i011-verdict-authority-stop-hook`** (resurfaced before implementation): the
  verdict authority moved OFF params-only boundary-sync (which has no agent-unforgeable human signal) onto
  the transcript-reading Stop/UserPromptSubmit hook. So the work split: **T005 narrows to "sync STOPS
  fabricating"** — it records the mechanical crossing only; never advances `last_authorized_boundary`, never
  appends/fabricates `verdict_history`, never attributes to the git committer. **T004 becomes the verdict
  AUTHORITY** — the hook captures the human's recognized token tied to the boundary (via the packet
  boundary-marker) and ADVANCES the gate; identity only from a proven host surface else unattributed;
  ambiguous/contradictory/untied → un-authorized; each entry tagged with its evidence source. The
  **second-chance explicit re-confirm** (hook-misses + hookless antigravity) rides Fix B's honest-pending
  surface (T006). C after A.
- **Fix B (committed ≠ authorized resume, FR-027)** — the resume + `specrew where` read
  `last_authorized_boundary` as decisive, surface "awaiting verdict," never auto-advance. B consumes
  the honest state A+C produce.
- **Fix D/E (DF-1/DF-2, small)** — pointer-mode recap synthesis (D) + version/branch in the directive
  (E). Independent; sequencing-free; first to defer if the iteration overruns.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Expose a TESTED agent-callable authoring surface around the handover writer (DF-7) — shipped as the `specrew handover author` dispatcher command, the reachable replacement for the un-exported `Write-SpecrewHandoverContext` (drift D-005); the FR-022 directive now NAMES it | FR-022 | US-3 | 2 | Implementer | `scripts/specrew-handover.ps1`, `scripts/specrew.ps1`, `Specrew.psd1`, `scripts/internal/specrew-bootstrap-provider.ps1`, `tests/bootstrap/**` | done | TBD | 2 | |
| T002 | Mechanical Stop-hook packet capture (A2, LOAD-BEARING) — capture the rendered boundary packet into the body + set `active_boundary`; non-skippable | FR-022 | US-3 | 3 | Implementer | `scripts/internal/bootstrap/HandoverStore.ps1`, `scripts/internal/*stop*` | done | TBD | 3 | |
| T003 | Clobber guard — capture MUST NOT overwrite a richer authored body with placeholder/stale (SC-015) | FR-022 | US-3 | 2 | Implementer | `scripts/internal/bootstrap/HandoverStore.ps1` | done | TBD | 2 | |
| T004 | Verdict AUTHORITY (the Stop/UserPromptSubmit hook) — capture the human's recognized verdict token tied to the boundary (via the packet boundary-marker) and ADVANCE `last_authorized_boundary` + append `verdict_history` (evidence-source `hook-captured-from-transcript`); ambiguous/contradictory/untied → un-authorized + surface; identity only from a proven host surface else unattributed | FR-026 | US-3 | 3 | Implementer | `scripts/internal/bootstrap/*` | done | TBD | 3 | |
| T005 | Boundary-sync STOPS fabricating — records the mechanical crossing only; NEVER advances `last_authorized_boundary`, NEVER appends/fabricates `verdict_history`, NEVER attributes to the git committer. (Verdict capture+consumption moved to T004 hook + T006 re-confirm per decision `f174-i011-verdict-authority-stop-hook`.) | FR-026 | US-3 | 3 | Implementer | `scripts/internal/sync-boundary-state.ps1` | done | TBD | 3 | |
| T006 | Committed ≠ authorized resume + `specrew where` — read `last_authorized_boundary` decisive; surface "awaiting verdict"; never auto-advance | FR-027 | US-3 | 3 | Implementer | `scripts/internal/specrew-bootstrap-provider.ps1`, `scripts/specrew-where.ps1` | done | TBD | 3 | |
| T007 | Deterministic SC-acceptance consolidation — bind each SC's proof (written alongside T001–T006) into one auditable, GREEN-together acceptance (`Sc012to015Acceptance.Tests.ps1`: present + run + matrix); the deterministic floor under the real-host re-dogfood | SC-012, SC-013, SC-014, SC-015 | US-3 | 3 | Implementer | `tests/bootstrap/**` | done | TBD | 3 | |
| T008 | DF-1 pointer-mode recap synthesis — surface each done lens's DECISION (one line, extracted from its `## Decision` headings) + a SYNTHESIZE-the-recap directive instruction, not just lens names; `Get-SpecrewLensDecisionSummary` + `done_decisions` on `Get-SpecrewWorkshopProgress` + the in-flight directive render (3 mirrors) with a names fallback | FR-002, FR-022 | US-3 | 2 | Implementer | `scripts/internal/bootstrap/ProjectMetadataAccessor.ps1`, `scripts/internal/specrew-bootstrap-provider.ps1`, `tests/bootstrap/**` | done | TBD | 2 | |
| T009 | DF-2 version/branch in the bootstrap directive — embed the resolved Specrew version (manifest) + git branch as LITERAL values in the directive text so a pointer-mode host renders a complete banner (Format-BootstrapDirective `-SpecrewVersion`/`-Branch` + a resolved-values line, fail-soft; provider resolves branch before the render claim; 3 mirrors) | FR-002 | US-1 | 1 | Implementer | `scripts/internal/specrew-bootstrap-provider.ps1`, `tests/bootstrap/**` | done | TBD | 1 | |
| T010 | Hook-deploy Layer 1 — proactive provisioning at init+update for ALL hook-capable registry hosts (claude/codex/copilot/cursor), not PATH-detected only; preserve user entries, replace only Specrew-owned, respect opt-outs, fail open, launcher provisioned even when no host binary is present (+ tests) | FR-028 | US-3 | 3 | Implementer | `hosts/_registry.ps1`, `scripts/internal/refocus-deploy-integration.ps1`, `tests/**` | done | TBD | 3 | |
| T011 | Hook-deploy Layer 2 — `specrew hooks` (status / install / remove, optional --host) command (dispatcher-only, no project-setup gate) + a non-mirrored `Get-SpecrewHooksStatus` inspector (installed/missing/stale/opted-out/failed; stale = regenerate-and-compare); register in dispatch + FileList + usage (+ tests) | FR-028 | US-3 | 4 | Implementer | `scripts/specrew.ps1`, `scripts/specrew-hooks.ps1`, `scripts/internal/specrew-hook-health.ps1`, `Specrew.psd1`, `tests/**` | done | TBD | 4 | |
| T012 | Hook-deploy Layer 3 — degradation diagnostic on EXISTING always-loaded surfaces (copilot-instructions + refocus core + `specrew-hooks` skill): warn ONCE per session when in a Specrew project but the bootstrap directive did not arrive; `Test-SpecrewBootstrapDirectiveArrived` helper + warn-once gate; honest residual-gap doc for claude/codex/cursor (no new always-loaded files) (+ tests) | FR-028 | US-3 | 3 | Implementer | `scripts/internal/specrew-hook-health.ps1`, `.squad/templates/copilot-instructions.md`, `extensions/specrew-speckit/refocus/general.md`, `tests/**` | done | TBD | 3 | |

**Capacity: 32/32** (T001–T009 = 22; T010–T012 hook-deploy hardening = 3+4+3 = 10). Cap raised 22→32 for the
maintainer-pre-approved hook-deploy hardening (decision `f174-i011-hook-deploy-hardening`; "I already consider the
extra sp ... and approved"). The `f174-i011-cap-revert-obligation` (restore global default 20 at closeout) still
stands. Defer priority on overrun: T008/T009 first.

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
| Capacity per Iteration | 32 |
| Iteration Bounding | scope |
| Time Limit (hours) | n/a |
| Overcommit Threshold | 1.0 |
| Defer Strategy | manual |
| Calibration Enabled | true |

> Capacity per Iteration RAISED 20 → 22 (plan verdict `f174-i011-plan-tasks-approved`, cluster coherence) → 32
> (mid-implement scope amendment `f174-i011-hook-deploy-hardening`, maintainer pre-approved the hook-deploy
> hardening SP). Estimates not deflated. The `f174-i011-cap-revert-obligation` (restore global default 20 at
> closeout) still stands — the closeout revert restores the GLOBAL default regardless of iter-011's consumed.

## Traceability Summary

- **FR-022** (capture ≠ author; mechanical persistence load-bearing): T001 (tested callable surface),
  T002 (load-bearing Stop capture), T003 (clobber guard). SC-012, SC-015.
- **FR-026** (verdict-integrity): T004 (hook is the verdict AUTHORITY — captures the human token + advances
  the gate + identity-only-if-proven), T005 (sync STOPS fabricating — mechanical crossing only), T006
  (second-chance explicit re-confirm for hook-misses + hookless antigravity). SC-013. Split per decision
  `f174-i011-verdict-authority-stop-hook`.
- **FR-027** (committed ≠ authorized resume): T006. SC-014.
- **FR-002 / FR-022** (small fixes — clarify instruction 5): T008 (DF-1), T009 (DF-2).
- **FR-028** (hook install/discovery hardening — mid-implement scope amendment `f174-i011-hook-deploy-hardening`):
  T010 (layer 1 proactive provisioning, SC-016), T011 (layer 2 `specrew hooks` command, SC-017), T012 (layer 3
  degradation diagnostic, SC-018).
- **SC-012/013/014/015**: T007 (deterministic tests) + the re-dogfood acceptance gate (run at review).
- **SC-016/017/018**: T010/T011/T012 carry their own deterministic tests (tests folded per task).

## Clarify rulings carried into the plan

- **Match-strictness (instruction 1)**: T004 builds against a recognized verdict token tied to the named
  boundary; ambiguous/contradictory/untied → un-authorized + surfaced (never "any human turn").
- **Antigravity fallback (instruction 2)**: no-hook hosts record un-authorized; T006 + the acceptance gate
  guarantee resume / `specrew start` surfaces "awaiting verdict," never infers approval or auto-advances.
- **SC-013 (instruction 3)** tightened + **SC-015 clobber (instruction 4)** added in the spec; T005/T007
  and T003/T007 carry their proofs.

## Phase Baseline

Baseline: iteration-010 HEAD (`c5756473`) — F-174 iteration 010 closed (accepted, delivered scope).
