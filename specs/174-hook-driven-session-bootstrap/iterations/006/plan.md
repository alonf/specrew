# Iteration Plan: 006

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 20/20 story_points
**Started**: 2026-06-09
**Completed**:

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity `<consumed>/<cap> <unit>`. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Scope Summary

Iteration 006 closes the greenfield dogfood's deepest finding: **the SessionStart hook ORIENTS but does
not DRIVE.** `specrew start` does three things the hook path does not: (1) writes the full ~48-rule launch
contract to `.specrew/last-start-prompt.md` via `Get-StartPrompt`; (2) initializes `boundary_enforcement`
in `.specrew/start-context.json`; (3) instructs the host to READ those files and follow the governed
lifecycle. The iter-1-5 bootstrap injects only a thin orient+menu directive — so on Claude the agent could
skip the workshop and drive from Spec Kit's `create-new-feature.ps1`, and on Codex no orientation reached
the model at all.

**Goal:** make the hook hand the agent the SAME launch contract + state `specrew start` does, by **REUSING
`specrew start`'s generator — not hand-rolling a second thin directive (no drift)** (maintainer charter
`f174-i006-charter`). Prove the foundation END-TO-END on the one PROVEN injecting host (Claude); ENUMERATE
codex / copilot / cursor injection as explicit clean follow-on re-tests; Antigravity (no hook) stays
`specrew start`-driven.

**The load-bearing assertion (the live-wiring floor) is what catches every dev-tree-only "works" claim**
(the iter-5 D-009 lesson): it runs in a real DEPLOYED scratch project, not the dev tree.

## Design / Architecture (the design pass)

### The seam (confirmed by orientation, 2026-06-09)

- **Contract generator** = `Get-StartPrompt` (in `scripts/specrew-start.ps1`) → the full handoff. Its
  helper tree is PART in sourceable libs already (`Invoke-SpecrewCoordinatorPromptSurgery` in
  `coordinator-prompt-surgery.ps1`; `Get-CoordinatorResumePromptBlock` in `coordinator-resume.ps1`) and
  PART still inline in specrew-start.ps1 (`Get-TeamRosterPromptBlock`, `Get-ProjectStatePromptBlock`,
  routing/brownfield/delivery-guidance blocks).
- **State init** = ALREADY reusable standalone functions: `Get-SpecrewBoundaryEnforcementState`
  (`.NeedsMigration`) + `Initialize-SpecrewBoundaryEnforcementState -CurrentBoundary`. They PRESERVE the
  existing session anchor and write ONLY the `boundary_enforcement` block. The hook calls them directly —
  no `Save-StartArtifacts` (which is a LAUNCHER monolith: git baseline, session frontmatter, host
  selection, approval/launch mode — none of which the hook, a non-launcher, may set).
- **Injection** = `Write-InjectionOutput` (`specrew-hook-dispatcher.ps1`) already defines per-host shapes
  (claude/codex/copilot `additionalContext`; cursor `hookSpecificOutput.additionalContext`). SessionStart
  IS an injection event. Whether each shape REACHES the model is the empirical open question.
- **Deployment is RESOLVED** (`deploy-refocus-hooks.ps1`): claude/codex/copilot/cursor each get a
  SessionStart-class hook; Antigravity has no branch = the no-hook fallback host. Do NOT re-derive.
- **Dedupe** = `Test-SpecrewLauncherBootstrapRecent` (launcher-then-hook → one bootstrap).

### Options considered

- **Option A — extract a shared launch-contract generator lib (CHOSEN).** Move `Get-StartPrompt` + its
  remaining inline prompt-block helpers into a new sourceable internal lib
  (`scripts/internal/launch-contract.ps1`). `specrew-start.ps1` dot-sources it (behavior-preserving —
  guarded by the existing specrew-start integration tests). The bootstrap provider dot-sources the SAME
  lib and calls `Get-StartPrompt` with hook-available inputs (project state, session state) and NULL
  launcher-only inputs (roster/routing — the hook makes no casting decisions, so those blocks degrade
  gracefully). ONE generator → no drift (the maintainer's hard requirement).
- **Option B — hook shells out to `specrew start --no-launch` (REJECTED).** Reuses the generator but
  couples the hook to the launcher's top-level flow (host selection, window launch, casting) it has no
  business invoking; heavier, slower, and it fabricates/clobbers launcher state. The hook is not a
  launcher (advisor blocker).
- **Option C — hand-roll a second contract in the hook (REJECTED).** Exactly the "thin directive / drift"
  the maintainer forbade.

### Component map (IDesign seams; what changes)

```text
   specrew-start.ps1 ─────────┐         specrew-bootstrap-provider.ps1 (Adapter)
   (launcher; unchanged       │              │  renders injection (additionalContext):
    behavior)                 │              │  "READ last-start-prompt.md + start-context.json,
        │ dot-sources         │              │   FOLLOW the governed lifecycle, do not bypass gates"
        ▼                     │              ▼
   ┌─────────────────────────────────┐   SessionBootstrapManager.ps1 (Manager)
   │ launch-contract.ps1 (NEW lib)   │◀──── gather hook inputs → Get-StartPrompt → surgery
   │  Get-StartPrompt + prompt-block │      → write last-start-prompt.md (narrow atomic write)
   │  helpers (moved, behavior-kept) │      → ensure boundary_enforcement (preserve-merge anchor)
   └─────────────────────────────────┘              │
        ▲ dot-sources (hook path)                    ▼
        └──────────────────────────  Get-/Initialize-SpecrewBoundaryEnforcementState (existing)
```

- **`launch-contract.ps1`** (NEW shared lib): the one generator, dot-sourced by BOTH callers.
- **`SessionBootstrapManager`** (existing Manager): orchestrates gather → generate → write contract →
  ensure state.
- **`specrew-bootstrap-provider`** (existing Adapter): injects the read-and-follow contract (replaces the
  iter-5 thin orient/menu) + the resume handover surface.
- **BoundaryEnforcement funcs** (existing): preserve-merge the anchor; the hook never clobbers it.

### Per-host injection model (parity-set = plumbing-green AND injection-observed)

The on-disk writes (contract + `boundary_enforcement`) are **host-agnostic — they ALWAYS happen**, so even
a non-injecting host has the files for a subsequent `specrew start`. INJECTION is verified in TWO parts —
the spec's SC-009-vs-SC-008 auto-vs-manual split, applied forward so a plumbing-green host is never
mistaken for an injecting one (the build != live trap one level up that this iteration exists to kill):

- **Plumbing (AUTO — T038 / SC-011)** — the contract + state are written and read back on disk in a
  DEPLOYED layout AND the provider EMITS the per-host injection. CI-able. The D-009 fix.
- **Injection-reaches-model (MANUAL per-host OBSERVATION — T039 / FR-024)** — whether the host runtime
  actually delivers the injected `additionalContext` to the model. NOT assertable on disk; a clean dogfood
  observation only (Codex's confounded run is exactly why this can't be a file assertion).
- **Claude** — plumbing via T038; injection-reaches-model satisfied by DIRECT OBSERVATION this iteration.
- **codex / copilot / cursor** — injection shape exists; delivery UNPROVEN (Codex's run was CONFOUNDED).
  ENUMERATED as explicit clean follow-on re-tests (T039; the full re-tests are the next slice — past the
  20 SP cap; surfaced at before-implement for the maintainer to cut).
- **Antigravity** — no hook → `specrew start` fallback.
- **Parity set = plumbing floor green AND injection observed-to-reach-model. `specrew start` fallback =
  Antigravity + any hooked-but-non-injecting host.**

### The load-bearing live-wiring floor (T038 — Claude, DEPLOYED scratch project)

Asserts the round-trip in a real installed-module layout (NOT the dev tree; `evidence_locus: deployed`):

1. SessionStart writes `boundary_enforcement` ON DISK (start-context.json) + the full contract to
   last-start-prompt.md.
2. A working turn + Stop captures the iteration intent into `last-start-prompt.md` (when there is no start
   prompt) + the agent-authored handover ON DISK.
3. A FRESH resume READS them back (contract + handover surface).

This is the assertion that would have caught every dev-tree-only "works" claim (D-009).

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-023 (new) | B2 emits the SAME launch contract + initializes `boundary_enforcement` as `specrew start`, by REUSING its generator (no re-authored directive) — the hook DRIVES, not merely orients | US-1 |
| FR-024 (new) | Per-host injection is EMPIRICALLY established; parity set = injecting hosts (hook drives); `specrew start` fallback = Antigravity (no hook) + any hooked-but-non-injecting host | US-1 |
| FR-022 | The deferred LIVE wiring (iter-5 D-009) is delivered: the agent-authored handover fires end-to-end in a DEPLOYED session | US-3 |
| FR-002 | The injected directive carries the full contract (read-and-follow), not the thin orient+menu | US-1 |
| FR-001 | B2 becomes the primary DRIVING bootstrap path on injecting hosts | US-1 |
| FR-006 / FR-008 | `specrew start` = cross-host driver + host-selection + fallback; docs/claims repositioned (hook = orientation/resume + drive-on-injecting-hosts) | US-2 |
| SC-011 (new) | The deployed live-wiring floor passes on Claude (the round-trip on disk) | US-1 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T035a | Characterization FIRST (the suite did NOT pin the contract — confirmed): add a test asserting `Get-StartPrompt`'s invariant contract markers (Lifecycle Quick Reference, the governance-scripts table, the boundary-authorization block, the boundary-policy line) survive in `last-start-prompt.md` AND `boundary_enforcement` is initialized in `start-context.json` after a `specrew start` run — the genuine regression net the extraction needs | FR-023 | US-1 | 1 | Implementer | tests/integration | done | claude | 1 | — |
| T035 | Extract `scripts/internal/launch-contract.ps1` (move `Get-StartPrompt` + inline prompt-block helpers out of specrew-start.ps1; specrew-start dot-sources it; behavior-preserving — GUARDED by the T035a characterization) | FR-023 | US-1 | 4 | Implementer | scripts/internal/launch-contract.ps1, scripts/specrew-start.ps1 | done | claude | 4 | — |
| T036 | SessionBootstrapManager calls the shared generator on SessionStart (gather project/session inputs; null launcher-only roster/routing) → write `last-start-prompt.md` (narrow atomic write) → ensure `boundary_enforcement` via Get-/Initialize-SpecrewBoundaryEnforcementState (preserve-merge the anchor) | FR-023, FR-001 | US-1 | 3 | Implementer | scripts/internal/bootstrap/SessionBootstrapManager.ps1 | planned | — | — | — |
| T037 | Bootstrap provider injects the read-and-follow contract (replace the iter-5 thin orient/menu directive) + the resume handover surface; dedupe-safe (never clobber a fresh launcher contract via Test-SpecrewLauncherBootstrapRecent) | FR-002, FR-007 | US-1 | 2 | Implementer | scripts/internal/specrew-bootstrap-provider.ps1, scripts/internal/bootstrap/DirectiveEngine.ps1 | planned | — | — | — |
| T038 | The DEPLOYED live-wiring floor on Claude (load-bearing; `evidence_locus: deployed`): a real installed-module scratch project asserts the 3-part round-trip — SessionStart writes boundary_enforcement + contract on disk; a working turn + Stop captures intent into last-start-prompt.md + the handover on disk; a fresh resume reads them back | FR-022, FR-024, SC-011 | US-1 | 4 | Implementer | tests/integration | planned | — | — | — |
| T039 | Per-host injection: the deployed floor (T038) auto-proves PLUMBING; injection-REACHES-model is a manual per-host OBSERVATION (Claude satisfied by direct observation this iteration); enumerate codex/copilot/cursor injection-reaches-model clean re-tests as EXPLICIT follow-on (not silently dropped); Antigravity → specrew start fallback | FR-024, FR-005 | US-1 | 1 | Implementer | specs/174-hook-driven-session-bootstrap | planned | — | — | — |
| T040 | evidence_locus carry: add an `evidence_locus` field (values dev-tree or deployed) to the 145 claim-ledger + the hardening-gate concern schema; review REFUSES "delivered-live" on dev-tree-only evidence; file as a Proposal-145 reviewer-family candidate (reconcile on the #2216 rebase) | FR-024 | US-1 | 2 | Implementer | extensions/specrew-speckit | planned | — | — | — |
| T041 | dormant-SessionEnd cleanup carry: delete SessionEndHandoverManager.ps1 + FileList entry + SessionEndHandover.Tests + the timestamped Write-/Get-SpecrewHandover funcs + the inaccurate "REUSED" design-record phrase | FR-009 | US-3 | 2 | Implementer | scripts/internal/bootstrap | planned | — | — | — |
| T042 | Docs / F-174 claims repositioned WITH the honesty guard: Claude driving is PROVEN; codex/copilot/cursor are plumbing-ready but injection-UNVERIFIED → `specrew start` fallback until per-host confirmed (NEVER "all-host parity" on Claude-only evidence); specrew start = cross-host driver + host-selection + fallback | FR-008 | US-2 | 1 | Implementer | docs | planned | — | — | — |

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

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Serial single-Implementer: the extract (T035) -> manager-calls-generator (T036) -> provider-injects
  (T037) -> deployed floor (T038) chain is sequential (each depends on the prior); the carries (T040 evidence_locus,
  T041 cleanup, T042 docs) and the enumeration (T039) follow.
- T035 is the LIR-001 risk task (touching specrew-start.ps1, the cross-host driver) — behavior-preserving
  extraction, the specrew-start integration suite is the regression floor; run it before T036.
- T038 is the LOAD-BEARING deployed floor — it gates the iteration's "works" claim and must run on the
  installed-module layout, not the dev tree.
- Recommendation: serial; no Junior/Senior split.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Design pass (this plan) co-settled from the maintainer charter `f174-i006-charter` + the 2026-06-09 host/injection correction. |
| Discovery/Spikes | 0 | Seam confirmed by orientation (no new research). |
| Implementation | 20 | T035a + T035-T042 (T035a added after the characterization finding; see Notes). |
| Review | 2 | 145 review + the evidence_locus mechanism + the deployed-floor gate. |
| Rework | 0 | at cap; no buffer (honest re-baseline). |

## Traceability Summary

- Requirement scope: FR-023 (new — contract+state parity via generator reuse), FR-024 (new — per-host
  injection parity model), FR-022 (deferred live wiring delivered), FR-002/FR-001 (driving directive),
  FR-006/FR-008 (fallback + docs), FR-009 (dormant cleanup), SC-011 (new — deployed live-wiring floor).
- User stories: US-1 (the hook drives), US-2 (docs), US-3 (handover live + cleanup).
- Honors charter `f174-i006-charter`: reuse the generator (T035/T036, not a thin directive); per-host
  injection first-class (T038/T039); carries folded in (T040 evidence_locus, T041 cleanup); the deployed
  live-wiring floor is load-bearing (T038).
- **Scope honesty (20 SP cap, intentional — split don't raise):** iter-6 = FOUNDATION + Claude-proven (19
  SP). codex/copilot/cursor injection re-tests are ENUMERATED (T039) as explicit follow-on, NOT done this
  iteration — pulling them in would exceed 20 SP (split into a follow slice). Surfaced at before-implement
  for the maintainer to cut.

## Notes

- Capacity 20/20: per-task SP (T035a 1 + T035 4 + 3+2+4+1+2+2+1) = 20. At cap (honest re-baseline).
- **T035a re-baseline (before-implement instruction #2):** the characterization check FOUND the
  specrew-start suite does NOT pin the contract (it tests the directive-block wrapping + pause-and-confirm,
  not `Get-StartPrompt`'s contract content or the `boundary_enforcement` init). T035a (build the genuine
  characterization net) was split out + SP re-baselined 19→20 BEFORE the extraction — not silently
  absorbed into T035's 4. Drift D-010.
- T035 reuses, does not rewrite, `Get-StartPrompt` — minimizing the LIR-001 risk; the only specrew-start
  change is moving functions to a dot-sourced lib + dot-sourcing it.
- **T035 SP RISK (surfaced at before-implement):** "behavior-preserving, guarded by the specrew-start
  integration suite" is only as strong as what that suite CHARACTERIZES. The suite EXISTS, but T035 must
  FIRST verify it actually pins the contract (`Get-StartPrompt` output + the `boundary_enforcement` init)
  and ADD a characterization assertion if it does not — otherwise the extraction could silently alter the
  contract and stay green. If the characterization is missing, T035 may exceed its 4 SP estimate.
- Sub-agents OUT OF SCOPE (single-agent only); per-worktree handover merge stays deferred (memory
  `f174-subagent-handover-merge-consideration`).
- The before-implement gate is the single human stop for this iteration (maintainer directive: design pass
  first, then stop at before-implement). APPROVED WITH INSTRUCTIONS (`f174-i006-before-implement-approved`).
- **Multi-host injection follow-on is a TRACKED slice now** (honesty guard 1b): the codex/copilot/cursor
  injection-reaches-model re-tests are scheduled as `f174-followup-multihost-injection-verification`
  (candidate iter-7 / proposal), NOT a vague enumeration — that slice delivers the "all hosts" intent;
  iter-6 ships Claude-driving-in-practice + host-agnostic plumbing.
- **T042 honesty guard (1a):** docs say Claude driving PROVEN; codex/copilot/cursor plumbing-ready but
  injection-UNVERIFIED → specrew start fallback. Never "all-host parity" on Claude-only evidence.
