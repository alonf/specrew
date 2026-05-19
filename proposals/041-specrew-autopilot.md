---
proposal: 041
title: Specrew Autopilot (Experiment + Production Feature)
status: candidate
phase: phase-4
estimated-sp: 28
discussion: tbd
---

# Specrew Autopilot (Experiment + Production Feature)

## Why

Specrew's current design assumes a human-in-loop at every boundary. The autopilot question: where can boundaries operate autonomously without compromising correctness, and what's the empirical pass-rate at different autopilot strictness levels?

Dual-purpose proposal:

1. **Experiment**: measure Specrew's methodological maturity by progressively removing human-in-loop at boundaries. Capture pass-rate per boundary class per task type. Findings feed back into validator hardening + corpus.

2. **Production feature**: for simple, low-risk projects (e.g., quick prototypes, scratch experiments), an autopilot mode that runs the lifecycle end-to-end without paste-authorization at each boundary. Targets the long tail of "I just want a quick prototype" usage that doesn't justify the full ceremony.

High article/talk value: an empirical autopilot study is a strong July 1 talk topic ("how much can we trust Specrew alone?").

## What

### Experiment side (~5-10 SP)

- Add `--autopilot=<level>` flag to `specrew start`
- Levels: `off` (current default), `mechanical` (per [038](038-adaptive-boundary-discipline.md) mechanical-execution class), `aggressive` (also human-judgment for low-risk task types), `full` (all boundaries auto-progress unless safety-critical)
- Per-run telemetry: which boundaries auto-progressed, repair-cycle counts, validator state, final review verdict
- Empirical dashboard: pass-rate per autopilot level per task type
- Run on a corpus of small toy features for measurement

### Production feature side (~20-25 SP)

- Productionize the autopilot levels with proper boundary handoff semantics
- Project-level autopilot policy in `.specrew/autopilot.yml` (default level, per-task-type overrides)
- Safety-critical boundary list (hardening gates, review verdicts touching security/auth surfaces — never autopilot)
- Audit trail in `.squad/decisions.md` for every autopilot decision
- Composes with [040](040-token-economy-governance.md): autopilot is most valuable when L1 tier is Lightweight/Economy (cost arbitrage in favor of letting cheap models run further)

### Out of scope

- Autopilot on safety-critical operations (production deploys, destructive git operations, public API changes) — those stay human-in-loop regardless
- Autopilot defaults that match production maturity (start at `off`; user opts in)

## Effort

- **Iteration 1 — Experiment** (~5-10 SP): flag + telemetry + measurement runs on toy corpus
- **Iteration 2 — Productionize** (~15-20 SP): policy file, audit trail, integration with [038](038-adaptive-boundary-discipline.md) boundary classes, safety-critical list

**Total**: ~20-30 SP across 2 iterations

## Phase placement

**Phase 4** (Token Economy + Autopilot Experiment) — composes naturally with [040](040-token-economy-governance.md). HARD PREREQUISITES:

- [040](040-token-economy-governance.md) Token Economy (cost guardrails)
- [024](024-multi-host-runtime-abstraction.md) Multi-Host CORE (so headless autopilot can run on Claude Code / Codex / other runtimes that support better unattended workflows than Copilot CLI's current REPL-only model)

## Open questions

1. Should the experiment-side findings be public (talk material) or kept internal as Specrew's methodology calibration data?
2. Autopilot levels: 4 fixed levels (off/mechanical/aggressive/full) or continuous (e.g., per-boundary-class enable/disable)?
3. What's the safety-critical-boundary list, and who maintains it?
4. Token-economy integration: should `--autopilot` automatically downgrade L1 tier (cheaper models)?
5. Should autopilot honor `[038](038-adaptive-boundary-discipline.md)`'s boundary-class taxonomy exactly, or define its own progression rules?
6. Failure-mode: if autopilot hits a validator failure deep in a lifecycle, does it bail-and-revert or pause-and-handoff?

## Risks

- Autopilot run that completes "successfully" but produces low-quality output (form-correct, meaning-wrong) — exactly the failure mode [030](030-quality-hardening-bundle.md) is designed to catch. Tight composition needed.
- Public talk material requires honest negative findings; user (Alon) is committed to that framing per the existing Clipboard corpus quality analysis.

## Cross-references

- Hard prerequisite: [040](040-token-economy-governance.md), [024](024-multi-host-runtime-abstraction.md)
- Composes with [038](038-adaptive-boundary-discipline.md) (boundary-class progression rules)
- Composes with [030](030-quality-hardening-bundle.md) (catches form-correct/meaning-wrong autopilot failures)
- Composes with [017](017-learning-loop-closure.md) (autopilot findings feed back into corpus)

## Status history

- 2026-05-13: initial idea capture
- 2026-05-16: hard prerequisites identified (Token Economy + Multi-Host CORE)
- 2026-05-18: promoted to candidate proposal during memory→proposals consolidation
