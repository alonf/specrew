# Retrospective: Iteration 011

**Schema**: v1
**Date**: 2026-05-25

**Feature**: F-044 Per-Host Architecture Refactor

> Seventh LIVE-TRACKED iteration of F-044. Smoke-test-prep bug-fix slice with user-specified Option 1 (two-defaults model).

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.5 | 0.5 | 0 |
| T002 | 1 | 1 | 0 |
| T003 | 0.5 | 0.5 | 0 |
| T004 | 0.5 | 0.5 | 0 |
| T005 | 0.5 | 0.5 | 0 |

**Average variance**: 0 SP at the task level. Clean iteration with explicit user-stated scope; no surprises.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.25 | 0.25 | 0 | Plan + scope decision via AskUserQuestion |
| Discovery/Spikes | 0.25 | 0.25 | 0 | Root-cause traced via `Get-ChildItem ... \| Sort-Object Name` grep |
| Implementation | 2 | 2 | 0 | T001 + T002 + T003 + T004 |
| Review | 0.25 | 0.25 | 0 | Test + lint |
| Rework | 0.25 | 0 | -0.25 | Buffer unused — no rework |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Resolved during this iteration: 0

## Improvement Actions

- **Smoke-test-prep dogfood as a first-class methodology mode**: this is the second iteration in F-044 (iter-009 was the first, iter-011 the second) triggered by the user discovering a UX regression while preparing to run a manual test — before the test actually ran. Worth capturing as a methodology pattern: "pre-test rehearsal" surfaces UX gaps that don't appear in code review.
- **Unique-priority validator candidate**: as more hosts are added, two hosts could legitimately claim the same MenuPriority. Add a validator rule to flag duplicate priorities across hosts. ~1 SP future small-fix candidate.

## What Went Well

- **Single root-cause + user-specified fix = textbook iteration**. AskUserQuestion narrowed the scope decision (Option 1 vs Option 2 for --host flag default). Plan written, executed, closed in ~3 SP.
- **Tests caught regression**: the existing Test 1 in `host-registry.tests.ps1` was asserting alphabetical order (`antigravity, claude, codex, copilot`). Updating it to priority order forced explicit recognition of the change — no silent regression.
- **Smoke-verify caught it immediately**: `pwsh -Command ". 'hosts/_registry.ps1'; Get-RegisteredHostKinds"` showed the new order before commit. ~2-second feedback loop.

## What Didn't Go Well

- **Smoke-test-prep DID catch the bug** before live test, but a property test for "menu default is the highest-priority installed host" would have caught it during F-043 / iter-001 architecturally. Empirical evidence for Pillar 4 (Bug → Regression Test First): the test that PROVES priority ordering didn't exist before this iteration. Now it does (Test 1b).
- **The empirical methodology-rigor ranking from the cross-host smoke test was used directly**: Claude > Codex > Copilot > Antigravity. This is a strong opinion baked into config — could surprise external users who expect Copilot first (default for years). Mitigation: documentation explicitly explains the priority + the `--host` flag non-interactive default still falls back to copilot, preserving backwards-compatibility for automation.

## Methodology Lessons

### Smoke-test-prep dogfood is a high-signal regression-discovery mode

iter-009 (bare URI) and iter-011 (menu default) were both triggered by user UX observations during smoke-test PREP (not during the test itself). Pattern: when a developer prepares to run a multi-step workflow, they read the UI carefully and catch regressions a casual user would miss. Encoding this as a methodology mode ("pre-test rehearsal mode") might unlock systematic UX-regression catching.

### Two-defaults model as a pattern

When a single concept (host default) has two distinct contexts (interactive vs non-interactive), forcing one default into both contexts produces friction. Allowing two contextual defaults preserves both UX paths' optimization. This pattern generalizes — could apply to logging verbosity (interactive vs CI), prompt approval mode (TTY vs headless), etc.

## Carry-Over to Next Iteration / Feature

- F-043 + F-044 bundled PR (#844) now has iter-011 alongside iter-001..009. iter-010 still reserved for PR-review cleanup (separate slice).
- Future small-fix candidate: unique-priority validator rule.
- Future methodology consideration: formalize "smoke-test-prep" as a Specrew mode.

## Velocity Snapshot

- F-044's 10 iterations totaled: 18 + 6 + 4 + 3 + 8 + 4 + 7 + 10 + 2.5 + 3 = 65.5 SP delivered against ~200 SP nominal capacity (20/iter × 10).
- True throughput: 65.5 SP across ~3 weeks of dogfood-driven discovery + repair + docs work.
- iter-011 took ~30 minutes wall-clock — bug-fix slice with clear user-stated scope and tight test discipline.
