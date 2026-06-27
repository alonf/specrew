# Implementation Plan — Feature 197 Iteration 009: Reviewer Robustness

**Branch**: `197-continuous-co-review` | **Date**: 2026-06-28 | **Spec**: [spec.md](../../spec.md)
**Design-analysis**: [design-analysis.md](./design-analysis.md) (`co_design: true`; R1-R6 agreed with the maintainer)
**Stage**: plan (approved design-analysis -> plan, 2026-06-28)
**Status**: planning

## Summary

Iteration 009 hardens the worktree co-reviewer's **degraded paths** after live EnglishIntake field evidence showed it is field-unstable on real change-sets (large diff -> timeout -> "no parseable findings" -> signoff-gate deadlock; silent `--host` override; unenforced timeout that ran 1h12m on a 1200s budget). Guiding principle (maintainer ruling 2026-06-28): **any review is better than nothing; the gate must never hard-deadlock.** No new architecture — R1-R6 extend the existing pipeline at named seams (the design-analysis component map).

## Approach

Extend named seams in `scripts/internal/continuous-co-review/`; a reviewer-instruction-contract change for incremental emission; cross-platform process control for the hard timeout. PowerShell 7.x, Pester 5.5, **no new dependencies**. Acceptance bar = deployed-and-fires + the degraded-path behaviours proven, not unit-green. No F-184 protected-surface edits.

## Task sequence (phased by leverage)

**Phase 1 — relieve the live deadlock (highest leverage):**

- **T091 [R5]** hard timeout: independent watchdog + process-group/job-object **tree-kill** + stdio-redirect + 5s SIGTERM->SIGKILL graceful flush. **WSL-validated (hard acceptance gate).** ~3.0 SP
- **T090 [R1]** incremental finding-emission (reviewer instruction contract: one JSON object per line to a findings file) + harvest-the-clean-prefix on kill + prose-salvage floor. ~2.5 SP

**Phase 2 — the human remediation surface:**

- **T096 [R6]** remediation menu at the next Stop (more time / different host / narrow scope: code-process-file-function / accept partial / override), choice carried via `co-review-round-state.json` to the re-run; scope-narrowing extends the existing user-code/subtree scoping. ~3.0 SP
- **T093 [R3]** pre-flight independence check + labelled same-host fallback (fire immediately, never block; the answer upgrades the next run). ~1.5 SP
- **T092 [R2]** post-hoc time-extension option + a pre-flight generous-budget heuristic for large diffs. ~1.5 SP

**Phase 3 — the honest gate:**

- **T094 [R4 + D5]** 3-dimension evidence label (completeness / independence / budget); tiered allow (full+independent auto; partial OR same-host need a recorded first-class ack verdict); never-deadlock; degraded-review blocking-finding override with a recorded reason. ~2.5 SP

**Phase 4 — cleanup:**

- **T095** resolve the T083-T085 collision (renumber the iter-008 addendum -> T087-T089). ~0.5 SP

**Capacity**: ~14.5 / 20 SP. Within cap.

## Acceptance gates

- **R5 WSL-validation (hard gate)**: the hard timeout + process-tree kill proven on WSL (`wsl -e bash -c "pwsh -File ..."`), not Windows-only — a configured timeout actually kills the reviewer tree with no orphaned children. The live failure being fixed: `--timeout-seconds 1200` ran 1h12m.
- **Never-deadlock acceptance**: a timed-out review yields harvestable partial findings + the remediation menu; the signoff gate never blocks on "no parseable verdict".
- **Deploy-completeness smoke**: the degraded paths fire in a deployed consumer project (EnglishIntake-class), not only self-host unit tests.
- **Degraded-evidence honesty**: a `partial` / `same-host` signoff records a first-class human ack verdict in the durable evidence trail.

## Quality gates

Pester 5.5 unit/integration for: watchdog-kills-the-tree (cross-platform), incremental-harvest-on-kill, prose-salvage fallback, the remediation-menu choice round-trip via round-state, tiered gate allow/ack, degraded-block override. Protected-surface guard (no F-184 host/hook/provider/registry/refocus/shared-governance edits). Markdownlint before boundary commits.

## Out of scope / deferrals

- Automated live cross-host CI (Proposals 181/194) — unchanged deferral.
- The lifecycle-pointer / state-truth durable fix (Proposals 142/193) — a SEPARATE feature after F-197.
- Formal iteration-closeout of the never-closed iters 001/006/007 (anti-fabrication ruling).
- iter-008 plan.md backfill + closed-index rebuild (deferred governance hygiene).
