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

The following three were found by the FIRST properly-budgeted codex auto-fire (run
`20260708T235143936`, 408s, 2026-07-09) reviewing the fixes themselves, verified-true against
source, and deferred by maintainer decision DEC-197-I010-008 (the beta ships loud-and-honest; the
interim prompt-honesty fix landed same-night so T111 never overclaims):

- **W8 — Runner-observed evidence recorder (codex f1)**: `Write-ContinuousCoReviewTestEvidence`
  persists CALLER-SUPPLIED numbers — nothing observes the run, so the evidence is forgeable by the
  implementer path (exactly the party the falsification stance distrusts). Fix: an execution wrapper
  (`Invoke-ContinuousCoReviewRecordedTestRun`) that RUNS the suite itself (Pester `-PassThru`,
  vitest/JUnit adapters later) and records what IT observed — the recorded `command` stays the
  reviewer's cheap re-run handle. Interim (shipped): the prompt says implementer-recorded (never
  machine-observed) and arms spot-checks as forgery detection with blocking teeth.
- **W9 — Per-checkpoint incremental baselines for the auto path (codex f2)**: the navigator fires
  without `BaselineRef`, so the orchestrator anchors to the trunk merge-base and every checkpoint
  review re-reads the WHOLE feature diff — safe but slow/noisy, and against FR-027's incremental
  intent (it also explains the 408s runtime of the run that reported it). Fix: the navigator records
  the last-REVIEWED checkpoint identity and threads it as the next fire's baseline (falling back to
  merge-base when none), with the signoff `--live` doctrine unchanged (merge-base anchor).
- **W10 — Freeze the fire-time digest through the detached chain (codex f3)**: the fire computes the
  checkpoint digest for dedup but the detached child recomputes later, so edits landing in between
  are reviewed as "the checkpoint" (what is CERTIFIED is still what was reviewed — the drift is
  checkpoint bookkeeping, not false-allow). Fix: pass the fire-time tree id through the detached
  entry; the digest tree PERSISTS as a git object, so the child can materialize the exact frozen
  checkpoint and label the run stale-vs-current when the tree has moved.

The following two are round-ceiling UX findings from the downstream consumer dogfood
(2026-07-09, tesr197local — the ceiling chicken-and-egg its agent named precisely: "the ceiling
blocks the very re-review that would confirm the finding is gone"); maintainer-directed to ship in
0.40.0-**beta2**:

- **W11 — The ceiling-halt message must teach the sanctioned door**: the halt text told the agent to
  "reset the co-review round state so review resumes" — pointing at STATE SURGERY instead of the
  designed escape (`specrew review --remediate more-time --timeout-seconds <n>`: human-typed,
  ceiling-bypassing, one-shot per T096). The downstream agent burned two full review rounds
  rediscovering tribal knowledge one sentence would have carried. Fix: the ceiling-halt escalation
  text (and the reap's surfacing note) name the exact remediation command and state that a bare
  `--live` rerun will NOT re-review past the ceiling; never suggest touching runtime state.
- **W12 — Fix-responsive rounds do not burn the ceiling**: the ceiling exists to stop SPIN (same
  findings, no movement) but cannot tell progress from spin — a round that RESOLVED prior findings
  while finding new ones (legitimate onion-peeling: round 1 found f1; round 2 confirmed f1 fixed AND
  found f2) still counts toward the ceiling, so honest progress gets halted and every subsequent run
  ceiling-halts without reviewing. Fix: a round whose verdict resolves at least one threaded prior
  finding (or whose flagged files changed since the finding) resets — or does not increment — the
  round counter; only true no-movement rounds climb toward escalation.

Second field batch (2026-07-09, tesr197local on the published 0.40.0-beta1 — the first-ever E2E on
gallery bits; both gates fired CORRECTLY, the findings are about what the correctness costs):

- **W13 — Machine-managed iteration trackers stale the review digest**: a human-approved
  reconciliation of `state.md`/`tasks-progress.yml` (bookkeeping repaired to match the already
  accepted `review.md`; zero reviewable content changed) altered the reviewed-state digest, so the
  signoff gate demanded a fresh live review to re-anchor evidence — a full reviewer cycle spent on a
  tracker edit. `specs/**` is digest identity BY DESIGN (spec/plan/tasks edits must stale evidence),
  but `iterations/*/state.md` and `iterations/*/tasks-progress.yml` are machine-managed DERIVED
  bookkeeping, not reviewable content — the acceptance truth lives in `review.md` plus the run
  records, never in the trackers. Fix: add exactly `specs/*/iterations/*/state.md` and
  `specs/*/iterations/*/tasks-progress.yml` to the DIGEST-IDENTITY strip list in
  `reviewed-state-digest.ps1` — narrowly; spec/plan/tasks/review/retro themselves stay identity.
  Needs the reviewer-can-still-see-it regression test (the strip-list false-allow discipline) plus
  its inverse: a tracker-only edit must NOT stale evidence.
- **W14 — Warn when an explicit `--timeout-seconds` undercuts the resolved config budget**: the
  project config carried `co_review_timeout_seconds: 600`, but the driving agent passed
  `--timeout-seconds 180` (then 400) and the reviewer was killed before producing anything —
  explicit-beats-config is the correct precedence (DEC-197-I010-007), yet the CLI accepted a
  guaranteed-to-fail downgrade silently. Fix: one warning line at budget resolution when the
  explicit value is below the config/default it overrides ("explicit 180s < configured 600s;
  reviews typically need the configured budget"), so the operator sees the downgrade before losing
  a review cycle to it.
- **W16 — Per-host default review budgets belong in the catalog**: the shipped watchdog default is
  a flat 300 seconds for EVERY host (`Get-ContinuousCoReviewNavigatorTimeoutSeconds -Default 300`),
  `specrew init` does not scaffold `co_review_timeout_seconds`, and the catalog carries no budget
  column — yet the field timings disagree per host: antigravity needs 600-870s (measured on the
  self-host repo; its own `--print-timeout` had to be lifted to 15m so OUR watchdog owns the kill),
  and claude needed ~400-600s on the same machine (three tesr197local checkpoint reviews died at
  180/300/400s while a 7-second CLI probe proved the host healthy — pure budget, not infra). The
  only reason the test project survives is a hand-edited config value; every fresh consumer gets
  300s against hosts that need more. Budget is HOST data, and the catalog is the single
  harness-data seam: add a `default_timeout_seconds` column per row; resolution becomes explicit
  flag -> project config -> catalog per-host default -> 300 floor. W14's downgrade warning then
  keys off the RESOLVED value, so an explicit 180 against claude's catalog 600 warns even in
  projects that never touched their config.
- **W15 — The manual `--live` door should default the code-writer host from the session**: a manual
  `specrew review --live --host <reviewer>` without `--code-writer-host` records
  `independence: 'unverified'` (correctly treated as not-independent, SEC-004) even when the
  session env knows exactly who is implementing — the `--list-hosts` path ALREADY resolves the
  code-writer via `--code-writer-host` -> `SPECREW_HOST` -> `SPECREW_ACTIVE_HOST`, but the live
  door leaves it null. Field effect (tesr197local): the operator restarted with copilot as the
  implementer and a claude reviewer — genuinely independent — yet the evidence could not say so,
  and the status surface read as if reviewer independence had not improved. Fix: apply the same
  env cascade as `--list-hosts` when the flag is absent (explicit flag still wins); the label then
  reflects the real session instead of defaulting to unprovable.

## Out of scope

- Model/quota fallback (Proposal 102 Pillar 5 addendum owns it).
- Consumer CI template hygiene (Proposal 204).
- Cross-host sandbox APIs (host-native sandboxing differs per harness; this bundle is
  harness-neutral machinery only).

## Effort

~6-10 SP: W1/W3/W6 are small and mechanical (1-2 SP together); W2 and W5 are careful list/refactor
work with regression tests (2-3 SP); W4 is the open-ended one (evaluate first, 1-3 SP if pursued);
W7 is a decision + a small hook/refocus change (1 SP); W13 is a two-line strip-list change whose
cost is the paired regression tests (1 SP); W14 is one warning line (well under 1 SP).

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

- **2026-07-09 (beta-1 E2E)**: amended - W13/W14 added from the first E2E on published gallery bits (tesr197local): a governance-tracker reconcile staled the review digest and cost a full live review (W13); an explicit downward `--timeout-seconds` override was accepted silently and killed the reviewer before output (W14).
- **2026-07-09 (later)**: amended - W11/W12 round-ceiling UX findings added from the downstream consumer dogfood (the ceiling chicken-and-egg); maintainer-directed to ship as 0.40.0-beta2 ("Add it to 203 and we will do it as beta 2").
- **2026-07-09**: status set to `candidate`. Drafted from the F-197 iteration-010 dogfood ledger at
  maintainer direction ("copy all your recording legends to either github issues or proposals").
