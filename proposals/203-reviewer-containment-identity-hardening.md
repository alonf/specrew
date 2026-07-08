---
proposal: 203
title: Reviewer Containment + Identity Hardening (F-197 fast-follow bundle)
status: candidate
phase: phase-2
priority-tier: 1
discussion: surfaced 2026-07-08/09 from the F-197 iteration-010 review-signoff dogfood — the day the feature reviewed itself and its first deployed consumer project. Three related gaps recorded on the self-host ledger (DEFER-197-I010-003, NOTE-197-I010-004 addendum, and the T111 standing-practice question) all concern the same seam — what the reviewer can TOUCH, what it can SEE, and what the gate CERTIFIES — and compose into one hardening bundle.
---

# Reviewer Containment + Identity Hardening

## Why

F-197 shipped OS-native **process** containment (Job Object / setsid — proven: every kill today reaped
the whole tree) and, late in iteration 010, **identity unification** (the worktree materializes from
the certified digest tree — D-197-I010-004). The dogfood that validated those also exposed the three
residual gaps in the same seam:

1. **Filesystem confinement is instructional, not enforced** (DEFER-197-I010-003, observed
   2026-07-08): a permissions-skipped antigravity reviewer left its worktree and operated on the
   ORIGIN repo by absolute path — ran the origin's Pester suites, probed
   `scripts/internal/sync-boundary-state.ps1` into an interactive hang that burned its whole budget,
   and one probe fired a REAL `specrew review --live` against the origin (a live codex run). Two
   enabling factors: origin-absolute paths are learnable from committed governance docs (the Rule 52
   `file:///` convention), and the worktree materializes UNDER the origin repo root, so any
   git-upward discovery inside it resolves to the origin. Process containment held; nothing was
   mutated — but the vector allows it.
2. **Host-machinery paths diverge between the digest and the worktree** (NOTE-197-I010-004
   addendum): the DIGEST identity excludes `.git/.specrew/.squad/.specify` but INCLUDES `.claude/**`
   and `.github/**`, while the WORKTREE strips marker-detected machinery dirs. Content the reviewer
   may never see can therefore be certified (the D-197-I010-004 FR-025 family, scoped to machinery
   paths), and un-strippable local host config (`.claude/settings.local.json`) gets reviewed as app
   changes. Observed downstream 2026-07-09: a consumer-project reviewer flagged the deployed hook
   config as "pointing at a missing `.specify` dispatcher" — a false positive by construction,
   because `.specify` is intentionally stripped from its worktree.
3. **Reviewers are not told what is stripped**: the slim prompt never says machinery paths are
   intentionally absent, so honest reviewers raise absence findings for references INTO machinery
   (finding class observed twice on 2026-07-09).

## What

- **W1 — Worktree relocation**: materialize reviewer worktrees OUTSIDE the origin repo root (system
  temp, as the ephemeral-root default already supports) so git-upward discovery inside the worktree
  can never resolve to the origin. One materialization-call change + tests.
- **W2 — Origin-path hygiene in the bundle**: strip/relativize origin-absolute paths from the
  reviewer-visible context (`.review/process/**`, injected design docs) so the origin location is
  not handed to the reviewer by our own artifacts.
- **W3 — Confinement contract in the prompt + spawn contract**: a hard rule (worktree-only
  operations; origin paths are out of bounds; running lifecycle/governance scripts is out of scope)
  in `Get-ContinuousCoReviewSlimPrompt` and `reviewer-spawn-contract.md`.
- **W4 — Origin-path watchdog (evaluate)**: detect origin-repo access from the reviewer tree (e.g.
  origin-side sentinel state changes, or child-process cwd/commandline sampling the T100 registry
  already enables) and FAIL the run loudly (`containment-violated`), never silently. Evaluate cost
  vs. signal; the enforcement floor may remain W1-W3 if the watchdog is disproportionate.
- **W5 — Machinery-path alignment**: ONE machinery list consumed by BOTH the digest strip and the
  worktree strip (host dirs `.claude/.github/.agents/.cursor/.copilot` handled identically on both
  sides — excluded from both, or included in both with the worktree keeping them). Kills the
  certified-but-unreviewable class for machinery paths; `.github/workflows/**` needs an explicit
  decision (REAL reviewable content for consumers — likely included in both).
- **W6 — Stripped-paths teaching**: one prompt block naming what is intentionally absent from the
  worktree, with the instruction not to raise absence findings for references into those paths
  (runtime evidence, not Test-Path, is the correct verification shape for machinery).
- **W7 — T111 standing practice (decide)**: whether implementer agents are REQUIRED to record test
  evidence after suite runs (refocus rule, or a PostToolUse hook auto-recording Pester/vitest
  results) so reviewers always find digest-matched evidence. Today it is voluntary; the 2026-07-08
  budget-death arc shows what its absence costs.

## Out of scope

- Model/quota fallback (Proposal 102 Pillar 5 addendum owns it).
- Consumer CI template hygiene (Proposal 204).
- Cross-host sandbox APIs (host-native sandboxing differs per harness; this bundle is
  harness-neutral machinery only).

## Effort

~5-8 SP: W1/W3/W6 are small and mechanical (1-2 SP together); W2 and W5 are careful list/refactor
work with regression tests (2-3 SP); W4 is the open-ended one (evaluate first, 1-3 SP if pursued);
W7 is a decision + a small hook/refocus change (1 SP).

## Phase placement

Post-0.40.0 fast-follow, first in the queue (it hardens the trust story the release ships with; the
release itself is safe because every failure mode is loud-and-honest, and the identity fix already
closed the certification gap for ordinary source).

## Open questions

1. W4: is a watchdog worth its complexity, or do W1-W3 reduce the residual risk below the bar?
2. W5: are `.github/workflows` consumer-reviewable content (include both sides) while
   `.claude`/`.agents`/`.cursor`/`.copilot` are machinery (exclude both sides)?
3. W7: hook-automated evidence recording vs. refocus-instructed duty — which fails better when the
   toolchain is not PowerShell (vitest, cargo, pytest)?

## Risks

- Over-stripping (W2/W5) could hide REAL review content — every list change needs a
  reviewer-can-still-see-it regression test (the D-197-I010-003/-004 lesson: exclusions are
  false-allow vectors).
- The watchdog (W4) must never kill legitimate in-worktree work — false containment kills would
  reintroduce the budget-death class T111 just fixed.

## Cross-references

- F-197 iteration 010: D-197-I010-004 (identity unification, shipped), DEFER-197-I010-003,
  NOTE-197-I010-004 (+ addendum), DEC-197-I010-005 — `.squad/decisions.md`.
- [102 Cross-Model Independent Reviewer](102-cross-model-independent-reviewer.md) — Pillar 5
  addendum (model priority / quota walk-down) — the sibling fast-follow.
- [204 Consumer CI Methodology Gateway](204-consumer-ci-methodology-gateway.md) — the distribution
  side of the same dogfood findings.
- [103 Agent-Class Threat Surface](103-agent-class-threat-surface.md) — the threat-catalog frame the
  observed escape instantiates.

## Status history

- **2026-07-09**: status set to `candidate`. Drafted from the F-197 iteration-010 dogfood ledger at
  maintainer direction ("copy all your recording legends to either github issues or proposals").
