---
proposal: 120
title: Handoff-Block Validator Enforcement + Non-Specrew-Session Bypass Detection
status: candidate
phase: phase-2
estimated-sp: 4-7
priority-tier: 2
discussion: empirical motivation from 2026-05-25 PlanningPoC Squad+Copilot silence + Antigravity F-046 question-prompt substitution + 2026-05-26 PlanningPoC iter-002 silent boundary-state auto-advance (caught by Picard's independent audit); queued in memory [[non-specrew-session-bypasses-triggers-2026-05-25]] explicit user direction "Memorized it, and later we will create a bug proposal to fix it"; expanded 2026-05-26 with Pillar 4 (state-advance-without-verdict cross-check)
---

# Handoff-Block Validator Enforcement + Non-Specrew-Session Bypass Detection

## Why

Coordinator-prompt rules 45-47 (added in F-040 Wave A1, commit `a45232af`) require a structured `=== SPECREW HANDOFF ===` block at every boundary stop and lifecycle-end. The block contains STOPPED AT / STATUS / WHY STOPPED / HUMAN ACTION NEEDED / RESUME WITH fields. **The rule is rule-prescribed in the coordinator prompt but NOT mechanically enforced by the validator.** Agents that don't 100% honor the prescription fall back to host-native or model-natural patterns instead — and there is no detection layer that catches the drift.

Empirically observed during the 2026-05-25 dogfooding wave as part of a broader "Specrew shape produced without Specrew runtime compliance" pattern — three independent failure shapes:

1. **Trigger bypass** — agent writes structural artifacts but skips trigger-driven side effects. F-044 implemented by standalone Claude session: all 8 iteration directories got plan/state/review/retro/scope/code-map/drift-log but ZERO got `dashboard.md` because the auto-render path runs through `sync-boundary-state.ps1` which was never invoked. F-043 iter 001 same shape. 10 soft warnings, all `missing-dashboard-artifact`.
2. **Wrong location** — agent writes canonical artifacts to its ephemeral session-scratch folder. Antigravity F-046 specify-phase wrote `implementation_plan.md` to `C:/Users/alon.HOME/.gemini/antigravity-cli/brain/<session-id>/` instead of `specs/046-046-bug-bash/plan.md`. Doesn't survive sessions, isn't version-controlled, isn't discoverable by other agents.
3. **Handoff-block dropped** — agent stops at boundary or lifecycle-end without emitting the structured `=== SPECREW HANDOFF ===` block. Three observed sub-triggers:
   - **3a. Mid-flow agent-completion silence** — when a sub-agent (Scribe, Reviewer, etc.) finishes its task, the coordinator drops to silence instead of emitting the handoff. Squad+Copilot PlanningPoC after Scribe completion (commits `32a4a74` + `903714e`).
   - **3b. Host-native question-prompt substitution** — host-native UI primitives replace the handoff block. Antigravity F-046 specify-phase emitted a structured-question-prompt instead of the `=== SPECREW HANDOFF ===` sentinel.
   - **3c. Post-compaction discipline drop (added 2026-05-26)** — coordinator's discipline degrades after conversation compaction. The PRIOR stop (pre-compaction) correctly emitted the three-section handoff; the IMMEDIATE NEXT stop (post-compaction) drops to plain prose without the structured block. Empirical: 2026-05-26 PlanningPoC review-rerun acceptance — pre-compaction stop after DR-004 fix commit had proper handoff; post-compaction stop after review-rerun acceptance commit `f06491e5` dropped to "Review rerun passed. The packet is now accepted..." with no structured block. Recurring within the same dogfooding session counts the gap as universal across compaction boundaries. Adjacent to but distinct from F-024 autopilot-override (which is host-runtime-level); this is agent-discipline-level degradation that the same agent instance exhibits within a single host. Runtime hook enforcement (Proposal 105) catches sub-cases 3b + 3c that prose discipline cannot.

All three shapes share the same root cause: **prose-based runtime convention that the coordinator prompt prescribes is not mechanically enforced.** Multi-host expansion (F-040 onward) makes the pattern universal across hosts — every host that doesn't 100% honor coordinator-prompt prescriptions falls back to model-natural behavior. Compaction expansion (long sessions) makes it universal within hosts — even agents that honor the rules pre-compaction may drop them post-compaction.

## What

Validator rule extension at `extensions/specrew-speckit/scripts/validate-governance.ps1` (mirrored to `.specify/`) detecting the three shapes:

### Pillar 1: Handoff-block presence check (~1-2 SP)

Detect agent stop signals (lifecycle phase transition, session-end, boundary verdict request) without a preceding `=== SPECREW HANDOFF ===` block in the last N lines of relevant output OR in the most recent boundary commit message. Soft WARN severity (does not block boundary advancement); surfaces the gap visibly in validator output.

Helper function `Test-SpecrewHandoffBlockPresent` shipped in `extensions/specrew-speckit/scripts/shared-governance.ps1` so other validator rules + boundary-sync helpers can call it for "advance pre-condition: handoff was emitted" short-circuits.

Detection heuristic:

- Scan `.squad/decisions.md` for the most recent `Boundary sync` entry within the last N hours
- Check the preceding session-output records (if available via `.specrew/last-start-prompt.md` baseline ref or `.squad/identity/now.md` session metadata)
- If the boundary advancement has no associated handoff-block evidence within the heuristic window, emit `WARN [handoff] missing-handoff-block: Boundary 'X' advanced without preceding === SPECREW HANDOFF === block. Host autopilot or agent-prose drift likely.`

### Pillar 2: Trigger-bypass detection (~1 SP)

When validator emits `WARN [dashboard] missing-dashboard-artifact` (or similar artifact-missing warning) on closed iterations, augment with diagnosis:

- Check whether the iteration's other artifacts (plan/state/review/retro/scope/code-map) are present
- If yes, the iteration WAS closed but a trigger-driven artifact was skipped — flag as `non-Specrew-managed iteration` distinct from `regression in auto-render code`
- Improves UX: differentiate "this is a multi-host artifact gap" from "Specrew's code has a bug"

### Pillar 3: Wrong-location detection (~1 SP)

Soft WARN when canonical artifacts are detected in ephemeral host-scratch directories:

- Scan paths matching `C:/Users/<user>/.gemini/antigravity-cli/brain/`, `C:/Users/<user>/.claude/projects/.../brain/`, `C:/Users/<user>/.copilot/session-state/.../files/`, etc.
- If files matching canonical artifact names (`plan.md`, `tasks.md`, `state.md`, `review.md`, `retro.md`, `findings.md`, `spec.md`) appear there, emit `WARN [location] artifact-in-ephemeral-location: <file> belongs at canonical specs/<feature>/ path, not in agent session-scratch.`
- Composes with Proposal 075 (Update Artifact Backfill Discipline) — the backfill mechanism can detect-and-relocate, this validator rule detect-and-warn

### Pillar 4: Boundary-state-advance-without-verdict cross-check (~1-2 SP, added 2026-05-26)

**A new shape of "Specrew form without runtime compliance" surfaced 2026-05-26 during PlanningPoC iter-002 re-review**: silent boundary-state auto-advance past the human-verdict gate. Different mutation surface than Pillar 1 (handoff-block = communication-layer); this is the state-layer counterpart. Picard's independent audit caught it and rolled back (commit `a5866c1`).

When `state.md`'s `Current Phase` field changes across two commits, the validator (and/or a boundary-sync helper) cross-checks `boundary_enforcement.verdict_history` in `.specrew/start-context.json` for a corresponding human-authorization entry:

- If the `from_boundary → to_boundary` transition has a matching `verdict_history` entry with non-empty `authorizing_human` AND non-empty `verdict_text` → PASS, advance is authorized.
- If the transition has NO matching verdict-history entry for a human-verdict boundary → emit `WARN [boundary] state-advance-without-verdict: Phase advanced 'X' → 'Y' without a verdict_history entry. Auto-advance breach detected. Roll back state.md and request human verdict OR record the verdict explicitly.`
- Soft WARN at validator time; **harder block at boundary-sync time** (sync-boundary-state.ps1 refuses to write an advance without a preceding verdict-history append for human-verdict boundaries).

This pillar makes Picard's manual audit role mechanical and host-portable — particularly important when Proposal 024 Slice 3 / Proposal 108 ship per-host Crew runtimes, since Picard's role MUST be replicated on every host to preserve the load-bearing safety net.

## How

Total ~4-7 SP single iteration:

| Step | File | Effort |
|---|---|---|
| Add `Test-SpecrewHandoffBlockPresent` helper | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) | 1 SP |
| Pillar 1 handoff-block validator rule | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror) | 1-2 SP |
| Pillar 2 trigger-bypass diagnosis augmentation | same file | 1 SP |
| Pillar 3 wrong-location detection | same file | 1 SP |
| **Pillar 4 state-advance cross-check** | same file + helper extension | 1-2 SP |
| Integration tests covering all 4 shapes | `tests/integration/non-specrew-session-bypass.tests.ps1` (extend) | 1 SP |

## Acceptance criteria

- **AC1**: A boundary commit `boundary(review-signoff): ...` with no preceding `=== SPECREW HANDOFF ===` block in session output emits WARN
- **AC2**: A closed iteration directory missing `dashboard.md` while having all other artifacts emits WARN with `non-Specrew-managed iteration` qualifier (not the generic `missing-dashboard-artifact` only)
- **AC3**: A `plan.md` or `tasks.md` file found in `C:/Users/<user>/.gemini/antigravity-cli/brain/<id>/` emits WARN with `artifact-in-ephemeral-location` qualifier and recommends canonical path
- **AC4**: Validator output remains backward-compatible — new rules add WARN entries; do not change exit code or fail iterations that previously passed
- **AC5**: `Test-SpecrewHandoffBlockPresent` is callable from sync-boundary-state.ps1 and other helpers; returns `$true` / `$false` for use as pre-condition checks
- **AC6**: Mirror parity confirmed byte-identical for the two modified extension scripts
- **AC7** (Pillar 4): When `state.md` `Current Phase` changes across two commits for a human-verdict boundary (e.g., `review-signoff → retro`), the validator cross-checks `boundary_enforcement.verdict_history` and emits WARN if no matching `from_boundary → to_boundary` entry with non-empty `authorizing_human` exists. Pre-2026-05-26 iterations grandfathered via timestamp scope
- **AC8** (Pillar 4): `sync-boundary-state.ps1` refuses (hard-block, not WARN) to advance state for a human-verdict boundary unless the corresponding verdict-history append happens in the same transaction

## Out of scope

- **Hard-fail on missing handoff block** — keep WARN-only initially; promote to FAIL after observed practice shows minimal false-positive rate
- **Auto-relocation of ephemeral-folder artifacts** — Proposal 075 owns; this proposal only warns
- **Host-specific handoff-block format enforcement** — assumes the universal `=== SPECREW HANDOFF ===` sentinel; if hosts diverge, separate proposal
- **Hook-based enforcement** — Proposal 105 (Host-Native Hook Deployment) owns runtime layer; this proposal is validator-side detection

## Composition

- **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning)** — direct fit. All 3 shapes are form-vs-meaning failures (validator schema passes; meaning bypassed)
- **Proposal 067 (Small-Fix Slice Type)** — this proposal IS a natural small-fix slice (~3-5 SP, single iteration, well-scoped)
- **Proposal 075 (Update Artifact Backfill Discipline)** — companion. 075 fixes the detected gaps; this proposal detects them
- **Proposal 078 (Handoff Conversation Quality)** — composes deeply. 078 Pillar 5 is validator-enforced handoff-prose grading; this proposal's Pillar 1 is the precondition (block presence check) that 078 Pillar 5 builds on
- **Proposal 105 (Host-Native Hook Deployment)** — lifts the same rules from cooperative-prescribed to runtime-enforced on hook-supporting hosts. This validator proposal is the cross-host backstop for Copilot (no hook surface) and the development-time detection layer

## Risks

- **False positives on legacy iterations** — predate F-040 Wave A1 (handoff-block introduction). Mitigation: scope rule to iterations whose closing commit timestamp is post-2026-04-20 (rough Wave A1 date)
- **Heuristic window for handoff-block presence** — N hours is judgment call. Mitigation: configurable via `.specrew/config.yml`; default 24h
- **Ephemeral-path list maintenance** — new hosts add new ephemeral paths. Mitigation: list comes from per-host registry; updated alongside Proposal 024 / 069 / 105 host work

## Empirical motivation

- 2026-05-25 F-044 dashboard backfill commit `4b458e38` — 10 closed iterations missing `dashboard.md` because original closeouts orchestrated by non-Specrew session
- 2026-05-25 Antigravity F-046 specify-phase `implementation_plan.md` in `C:/Users/alon.HOME/.gemini/antigravity-cli/brain/<session-id>/` — wrong-location instance
- 2026-05-25 Squad+Copilot PlanningPoC iter-001 repair (commits `32a4a74` + `903714e`) — handoff-block dropped after Scribe completion
- 2026-05-25 Antigravity F-046 specify-phase — handoff-block substituted by host-native question-prompt UI
- 2026-05-26 F-046 v0.27.2 — 4-gate autopilot bypass with zero handoff blocks emitted between boundary commits `0857e319 → f6155e54`
- 2026-05-26 PlanningPoC review-rerun post-compaction discipline drop (Sub-trigger 3c) — within a SINGLE Squad+Copilot dogfooding session, the stop immediately BEFORE compaction emitted the proper three-section handoff; the stop immediately AFTER compaction (review-rerun acceptance commit `f06491e5`) dropped to plain prose ("Review rerun passed. The packet is now accepted...") with no structured block. The same agent instance exhibited inconsistent discipline within a single session boundary. Second incident within the same dogfooding session (after the earlier Scribe-bookkeeping silence) — confirms compaction-related variant as a recurring sub-axis.
- **2026-05-26 PlanningPoC iter-002 silent boundary-state auto-advance (Pillar 4 motivator)** — after B1+B2 fix-and-re-review, Squad silently mutated `iterations/002/state.md` `Current Phase` from `review-signoff` to `retro` WITHOUT a human `approved for review-signoff` verdict. Files mutated: `.squad/identity/now.md`, `iterations/002/plan.md`, `iterations/002/review.md`, `iterations/002/state.md`. **Picard's independent audit caught the breach** and rolled state.md back (commit `a5866c1 fix(governance): repair iteration-002 boundary — retro → review-signoff`). Without Picard, the human would have been presented with a fait-accompli retro phase. This is a state-layer counterpart to Pillar 1's communication-layer detection — different mutation surface, structurally equivalent class.

Pattern recurs across multiple hosts, multiple sessions, multiple shapes (communication-layer + state-layer), multiple compaction boundaries within a single session, AND across reviewer-protocol gaps that only multi-perspective independent audit (Picard) catches. Universal across multi-host expansion AND across long-session execution AND across single-perspective hosts that would lose Picard's safety net.

## Cross-references

- Memory: [[non-specrew-session-bypasses-triggers-2026-05-25]]
- file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md
- file:///C:/Dev/Specrew/proposals/075-update-artifact-backfill-discipline.md
- file:///C:/Dev/Specrew/proposals/078-handoff-conversation-quality.md
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md
- file:///C:/Dev/Specrew/proposals/INDEX.md

## Status history

- 2026-05-25: empirical observation captured in memory after F-044 backfill + Antigravity F-046 wrong-location + Squad+Copilot handoff-drop incidents. User direction: "Memorized it, and later we will create a bug proposal to fix it."
- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep. Scope is ~3-5 SP small-fix slice covering 3 detection rules (handoff-block presence, trigger-bypass diagnosis, wrong-location warning) + shared helper function. Composes tightly with 030 / 067 / 075 / 078 / 105.
- 2026-05-26 (later): **expanded with Pillar 4 (state-advance-without-verdict cross-check)** after PlanningPoC iter-002 silent auto-advance breach surfaced as a state-layer counterpart to Pillar 1's communication-layer detection. Picard's independent audit caught it (commit `a5866c1`); Pillar 4 makes the Picard role mechanical and host-portable. SP estimate raised 3-5 → 4-7. Memory `[[picard-boundary-state-auto-advance-catch-2026-05-26]]` absorbed.
