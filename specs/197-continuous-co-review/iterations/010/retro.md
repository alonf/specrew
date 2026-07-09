# Iteration 010 Retro

**Feature**: 197-continuous-co-review
**Iteration**: 010 (robustness completion + reviewer-instruction fold — the F-197 closing iteration, ships as 0.40.0)
**Date**: 2026-07-09 (work window 2026-07-02 authorization → 2026-07-09 review-signoff approval)
**Provenance**: written at the retro boundary from the live session record — `state.md`,
`drift-log.md` (D-197-I010-001..006), `review.md`, `tasks-progress.yml`, `.squad/decisions.md`
(DEC-197-I010-004..009, NOTE-001..005), and the promoted review evidence chain.

## What went well

- **The feature validated itself recursively — every layer of the machinery caught a real defect in
  the machinery.** The antigravity verification round caught the iteration's own doc/test doctrine
  drift (D-003). The FIRST run ever to consume T111 implementer evidence used its reclaimed budget
  (141s vs four ~880s budget-deaths) to find the reviewed-vs-certified identity gap (D-004). A
  navigator AUTO-FIRE — firing unprompted on a checkpoint — caught its own dedup keying defect
  (D-005) in 132s. And the deferral mechanism's first exercise exposed that human-deferred findings
  had no convergence path at all (DEC-009). Four structural defects, each found by the exact
  mechanism it lived in, none findable by the green suite.
- **The T111 send-back paid for itself within one run.** The maintainer's root-cause instinct
  ("tell the reviewer the tests already passed — provide proofs") converted the review budget-death
  loop into 2–7 minute evidence-backed reviews: digest-bound machine-recorded suite evidence,
  injected only on an exact tree match, with spot-checks armed as forgery detection.
- **Host-neutrality (D-002) proved out in production the same day it shipped.** When codex went
  hard-down mid-boundary, antigravity was wired as the independent reviewer via one catalog data row
  plus a human authorization — zero core changes — and carried the verification rounds. Later, the
  copilot headless vector was probe-validated the same way (one row away, NOTE-005). The T108
  empty-exit-0 retry recovered live flakes on BOTH harnesses.
- **The first downstream consumer validated the whole loop end-to-end** (`tesr197local`,
  2026-07-09): checkpoint auto-fires, round threading, the remediation walk, honest loud failures —
  and its properly-budgeted reviews found REAL feature defects there (a weak round-trip property
  test, a line-ending portability bug) that its agent fixed. It also found OUR defects: the --live
  budget fossil (D-006) and the untracked-scaffold/bootstrap-baseline saga (204-W5b, #2909).
- **Human-verdict discipline held under pressure.** Six fix-now decisions and two deferrals were
  each explicitly maintainer-authorized and recorded (DEC-004..009); the deferral is verifiable
  in-tree by reviewers; nothing was self-granted, and the one full+independent escalation was closed
  by a human decision exactly as D5 demands.

## What hurt (friction -> learning)

1. **The two-doors drift class (the headline learning).** The --live door ran iteration-002's
   hardcoded 120s budget for two months after the auto path was fixed to 300s + config — because the
   lesson was applied where it was learned and never propagated to the sibling path. It survived
   because every insider passed an explicit flag; the first outsider (the consumer project) hit it
   verbatim. **Learning: a lesson fixed on one path is a bug report for its siblings — one resolver
   per concern, every door calls it** (now: both doors share `Get-ContinuousCoReviewNavigatorTimeoutSeconds`;
   a regression test pins the door default).
2. **Identity must be ONE object everywhere.** Three separate gaps came from identity plurality:
   materialization archived HEAD while the gate digested the working tree (D-004); dedup keyed on
   HEAD-tree while everything else moved to the digest (D-005); the fire-time digest is still not
   threaded to the detached child (203-W10, deferred). **Learning: when a certified identity exists,
   every consumer — materializer, gate, dedup, fire — must consume THAT object; each parallel
   identity is a future false-allow or coverage hole.**
3. **A human decision without machine-readable semantics is a deadlock.** The deferral decision was
   recorded, the reviewer READ it — and still escalated, because the round teaching had no deferral
   vocabulary and D5 (correctly) forbids overriding full+independent blocks. T094's never-deadlock
   covered degraded evidence but not human-deferred findings. **Learning: every human verdict class
   needs an explicit convergence rule in the machinery** (now: RESOLVED-BY-DEFERRAL on every round,
   in-tree record verification required, escalation items never self-perpetuate).
4. **Agentic CLIs must be probed in scratch directories, never a governed cwd.** The copilot
   viability probe ran in the self-host repo; its session hooks fired the Specrew bootstrap and
   rewrote iteration state (git-restored; NOTE-005). Live evidence for 203's confinement theme —
   an agentic host in a governed directory self-bootstraps and mutates state.
5. **Evidence honesty needs teeth at the wording level.** The recorder's prompt overclaimed
   "machine-recorded from actual runs" for caller-supplied numbers (codex f1); separately, the
   reviewer caught fabricated future timestamps in tasks-progress.yml. Both corrected the same way:
   claims cut down to what the mechanism carries (implementer-recorded + spot-check teeth;
   git-derived timestamps). **Learning: the falsification stance applies to OUR OWN artifacts
   first.**
6. **Shared-account quota is a real operational constraint.** The self-host loops and the consumer
   project drew the same antigravity quota group; the Gemini five-hour window emptied mid-boundary
   and probes/reviews contended. The model-group quota lesson (independent windows per group) is now
   design input for the 102 walk-down.

## Estimation Accuracy

Planned 24.00/26 story_points (11 tasks, the D2 cap-raise to 26); delivered **26.00/26** — the
planned 24.00 plus the maintainer-authorized T111 send-back (2.00 SP, DEC-004) which consumed the
headroom exactly. All 12 tasks done; zero deferred-out. The six review-round/dogfood fixes
(D-002..D-006 + the deferral machinery) were absorbed as review-remediation work per the established
fix-round convention rather than task rows — the honest reading is that the review-signoff phase
carried roughly an additional task's worth of unplanned-but-real hardening, consistent with the
iter-005/iter-009 learning that integration-heavy dogfood surfaces plan-invisible work. Wall-clock:
implementation 2026-07-08 07:47Z → 09:52Z (planned tasks, per git-derived tasks-progress
timestamps); T111 2026-07-08 19:52Z → 20:26Z; the review-signoff convergence arc spanned 2026-07-08
09:45Z → 2026-07-09 01:01Z including two reviewer-harness outages and six fix-or-defer rounds.

## Drift Summary

`drift-log.md` records **6 events, 100% resolved** + 1 carried-finding closure
(D-197-I009-003 REFUTED with forensic evidence, T109). By finder: the boundary sync (D-001), the
maintainer's architecture review (D-002 host-neutrality), the feature's own reviewers (D-003 doctrine
drift, D-004 identity unification, D-005 dedup identity), and the downstream consumer project (D-006
budget drift). No in-scope requirement drift — FR-033..FR-040 + SC-024/SC-025 stayed fixed; every
event was implementation/doc/process against standing decisions.

## Improvement Actions

Fixed this iteration (beyond the 12 planned tasks):

- [x] Host-neutral core enforced: catalog-only harness data + guard test (D-002).
- [x] Teaching-doc/test doctrine sweep + honest timestamps (D-003).
- [x] Reviewed identity == certified identity: worktree materializes from the digest tree; `--live`
  reviews uncommitted work (D-004).
- [x] Checkpoint identity == certified identity: digest-keyed auto-fire dedup, content-addressed
  (D-005).
- [x] Config-aware --live budget (explicit → config → 300s), regression-pinned (D-006).
- [x] Implementer test-evidence pipeline (T111) + honest evidence wording + spot-check teeth.
- [x] RESOLVED-BY-DEFERRAL round semantics with in-tree verification; escalation items never
  self-perpetuate (DEC-009).
- [x] Antigravity reviewer wired + field-validated; copilot headless vector probe-validated
  (NOTE-005).
- [x] F-197 user documentation complete (changelog, README, user guide, api-reference,
  troubleshooting, data-contracts, how-to, getting-started, architecture, shipped squad charter).
- [x] Pre-existing public-readiness fixture lag root-caused + fixed (tests/unit 10/10; main's
  deeper breakage filed as #2908).

Carried to the fast-follow proposals (all maintainer-authorized):

- [ ] **Proposal 203** (W1–W10): worktree relocation + origin-path hygiene + confinement contract +
  watchdog evaluation + machinery digest/worktree alignment + stripped-paths teaching + T111
  standing practice + runner-observed recorder (W8) + per-checkpoint incremental baselines (W9) +
  fire-time digest freeze (W10).
- [ ] **Proposal 204** (W1–W5b): consumer methodology-gate CI template + work-kind path fix +
  self-host lane removal + settings gitignore + update-time healing + init bootstrap commit
  (#2909).
- [ ] **Proposal 102** (Pillar 5 addendum): ranked model priority within harness, quota-group-aware
  walk-down, failure classification, opt-in fallback chain, per-host budget floors +
  defaults-only auto-escalation.
- [ ] Copilot reviewer catalog row (probe-validated vector, NOTE-005).
- [ ] Main-branch reconciliation at PR time (#2908; PR #2905 landed on main mid-feature).

Deferred beyond F-197 (standing): the durable lifecycle-pointer fix (Proposals 142/193); automated
live cross-host CI (Proposals 181/194).

## Process Notes

- **The convergence loop's state machine is now closed and field-proven**: clean trees pass (×3),
  fixed findings converge (×2), human-deferred findings converge (×1, after DEC-009), infrastructure
  failures surface the remediation menu (×many). Every path exercised on real runs this iteration.
- **Verdict capture via the marker + Stop hook worked at every boundary stop**, including the
  multi-day-gap resume and the six-section packet discipline; the pending-verdict artifact remained
  authoritative throughout.
- **Consumer-project ack**: `tesr197local`'s iteration-001 closes via the T094 ack-degraded path
  (residual blocks are Specrew's own untracked scaffold — the 204-W5b root cause); its scaffold
  baseline commit is queued as its post-signoff housekeeping.
- **Release posture**: 0.40.0-beta.1 ships loud-and-honest with the known-limitations table recorded
  (CHANGELOG Notes + DEC-008); core guarantees (never-false-green, loud failures, human-gated
  overrides, digest-fresh gate, reviewed==certified) all hold; the beta → maintainer clean-env E2E →
  stable path is unchanged.
