# Feature Closeout: Continuous Co-Review

**Schema**: v1
**Feature**: 197-continuous-co-review
**Branch**: 197-continuous-co-review
**Closed**: 2026-07-09
**Status**: COMPLETE — branch-ready evidence only; release steps each need their own human authorization
**Closer**: Claude, authorized by Alon Fliess (review-signoff, retro, and iteration-closeout verdicts captured 2026-07-09; feature-closeout gate presented at this closeout)

## Executive Summary

Feature 197 ships **continuous co-review**: an independent, human-authorized AI reviewer — on a
different harness than the code-writer — reviews each implement checkpoint in an OS-contained
ephemeral worktree, and review-signoff **fails closed** until real co-review evidence exists. The
feature closes as **0.40.0** (beta-before-stable; this branch is version-bumped to 0.40.0 with the
`beta1`-style prerelease stamped at publish).

The shipped architecture, hardened across ten iterations: a Stop-hook **navigator** auto-fires
detached reviews at checkpoints (digest-keyed dedup, never blocks the session) with a synchronous
`specrew review --live` door for gate evidence; a **stripped worktree** materialized FROM the
certified reviewed-state digest tree (reviewed content ≡ certified content by construction);
**host-neutral reviewer selection** from the one catalog seam (strongest eligible reviewer on a
DIFFERENT harness, honour-or-surface `--host`, labelled same-host fallback); **OS-native process
containment** (Windows Job Object `KILL_ON_JOB_CLOSE` / Unix `setsid`+PGID, WSL-validated both
directions); a **tiered evidence gate** (completeness/independence/budget labels; full+independent
auto-allows; degraded needs a recorded human ack); a **five-option remediation menu** carried
one-shot on round-state; **round threading** with escalation-latch (surface-once, human-close,
convergence-clear) and **resolved-by-deferral** semantics (recorded human deferrals verified
in-tree); **implementer test evidence** (digest-bound suite records injected into the worktree,
spot-checks armed as forgery detection) that cut review cost from ~880s budget-deaths to 2–7-minute
evidence-backed reviews; and **never-false-green** throughout (empty results retry once then fail
loud with a cause diagnostic; a ceiling halt is never a pass).

**The closing week's evidence is the feature's own product**: its reviewers found six real defects
in the feature and its artifacts (doctrine drift, the reviewed-vs-certified identity gap, the dedup
identity gap, the evidence-forgery surface, the auto-fire baseline scope, the fire-time digest
race); a first downstream consumer project (`tesr197local`) ran the full loop — auto-fires, round
threading, remediation walks, honest loud failures — found OUR distribution bugs, and had its own
feature code genuinely improved by review findings. Every defect was fixed same-day or deferred by
recorded maintainer decision into named fast-follow homes.

## Delivered Scope (by iteration)

| Iteration | Closed | Scope | Status |
| --- | --- | --- | --- |
| 001–006 | 2026-06 (artifacts per iteration; pre-index closes — F-075 backfill class, non-blocking) | The first-cut engine and its hardening arc: design analysis + planted-violation validation (001), early gate/evidence work (002–004), dogfood + quality evidence (005), hardening gate (006). Superseded in architecture by the 008 cutover; the gate/evidence contracts carried forward. | complete |
| 007–008 | design-phase | Reviewer result-delivery harness survey + subtree scoping seed (007); the worktree-engine design + workshop and the cutover decision (008): detached stripped-worktree reviewer as THE one method, deleting the diff-cramming first cut. | complete |
| 009 | 2026-07-02 | The graceful-degradation spine: partial harvest + prose salvage, time extension, detach-leak fix, Option-A `escalated_to_human` parking, round-ceiling with VISIBLE escalation (false-green killed), codex reliability findings; shipped `0.39.0-beta1`. 7.50 SP delivered, 4 robustness tasks honestly deferred to 010. | complete |
| 010 | 2026-07-09 | Robustness completion: OS-native containment (T100/T091, WSL hard gate), independence fallback (T093), tiered evidence gate (T094), remediation menu (T096), material-turn gate (T099), escalation latch (T106), reviewer-instruction fold (T107), empty-retry + diagnostic (T108), flush-race forensic closure (T109), cross-host validation incl. same-day antigravity wiring (T110), implementer test evidence (T111 send-back). Plus the review-round hardening: host-neutral core (D-002), identity unification (D-004), digest-keyed dedup (D-005), config-aware budgets (D-006), deferral convergence (DEC-009). 26.00/26 SP, 12/12 tasks, 6 drift events 100% resolved. | complete |

## Tests and Validation (recorded at this closeout on the branch tree)

- **Machine-recorded suite evidence** (T111 recorder, digest-bound to the reviewed tree):
  continuous-co-review **258/0** (2 env-guarded skips), unit **10/0**, integration-review-command
  **7/0**, integration-live-wiring **34/0**; WSL validation passed during T091/T100 (dead-supervisor
  orphan-kill both directions).
- **Governance validator: PASS** on the committed tree (canonical defers matched, hardening-gate
  runtime evidence recorded 5/5, dashboards rendered).
- **Gate evidence**: promoted run `20260709T005739948-ce763555` — full/independent/normal, `pass`,
  0 findings, anchored to the reviewed head — produced by a deferral-aware reviewer that verified
  the maintainer's recorded decisions in its worktree.
- **Cross-host reality** (SC-012/SC-022, honest scope): claude exercised as the governed code-writer
  (live hooks all sessions); codex AND antigravity exercised end-to-end as independent reviewers
  (both doors, real findings, real flake-recoveries); copilot headless vector probe-validated
  (catalog row pending); cursor-agent installed-but-unauthorized. Evidence:
  `iterations/010/quality/cross-host-validation.md`.
- **Downstream consumer validation**: `tesr197local` ran init → workshop → implement → checkpoint
  auto-fires → remediation → findings-fixed on the deployed module (its iteration-001 gate closes
  via the T094 ack path; its scaffold-baseline housekeeping queued).

## Known Non-Blocking Warnings (dispositions)

- Reviewer **filesystem** confinement is instructional (process containment enforced; observed
  origin-path escape, nothing mutated) → **Proposal 203 W1–W4** (DEFER-197-I010-003).
- Evidence recorder trusts caller-supplied numbers (prompt honesty + spot-check teeth shipped
  interim) → **203 W8**; auto-fire baselines are merge-base (over-reviews, never under) → **203 W9**
  (DEFER-197-I010-003/FR-027); fire-time digest not threaded to the detached child (bookkeeping
  drift, certified≡reviewed holds) → **203 W10**. All per DEC-197-I010-008.
- Host-machinery digest/worktree asymmetry + stripped-paths reviewer teaching → **203 W5–W6**.
- Bootstrap deploys dev-repo-wired forge workflows + un-gitignored host config into consumers; init
  leaves the scaffold uncommitted → **Proposal 204 W1–W5b**, issue **#2909**.
- Model priority / quota-group walk-down / failure classification / opt-in fallback chain / per-host
  budget floors + defaults-only auto-escalation → **Proposal 102 Pillar 5 addendum**.
- `tests/unit` public-readiness suite is fully red **on main** (branch carries the fixture fix;
  main's deeper breakage undiagnosed) → issue **#2908**, reconcile at PR time.
- Copilot/cursor-agent reviewer breadth (consent-scoped) → DEFER-197-I010-001; copilot vector
  probe-validated (NOTE-197-I010-005).

## Branch Hygiene

- Working tree: clean except the untracked `.specrew/review/` runtime evidence store (never
  tracked by design — the gate reads it from disk).
- Branch: **259 commits ahead of `origin/main`, 9 behind** (main gained PR #2905 mid-feature);
  **not yet pushed at closeout** — push is release step 5. The behind-commits reconcile during the
  PR step per the standing pattern.
- Versions: `Specrew.psd1` ModuleVersion **0.40.0**; `.specrew/config.yml` specrew_version
  **0.40.0**; README badge + active-line updated; CHANGELOG carries the full `0.40.0-beta.1` entry.

## What This Closeout Does NOT Authorize

Release, tag, merge, PR creation, and push-to-main **each require their own human authorization**
(release-discipline steps 5–14: push → PR → host-review addressed → merge → beta tag/publish →
**maintainer clean-environment manual E2E** → stable promotion). This closeout records branch-ready
evidence only.

## State schema / fixture maintenance

New durable runtime shapes introduced by F-197 (`review-run.json` envelope with evidence labels,
`findings-result` normalization, `co-review-round-state.json`, test-evidence records,
reviewer-hosts registry) are covered by producer/consumer contract fixtures under
`tests/continuous-co-review/fixtures/contracts/`; no legacy-version fixture is required (the
`.specrew/review/**` store is runtime state, versioned by `schema_version` fields, not a migrating
committed schema).

## Follow-up

- **Proposal 203** (reviewer containment + identity hardening, W1–W10) — first in queue.
- **Proposal 204** (consumer CI methodology gateway + distribution hygiene, W1–W5b; #2909).
- **Proposal 102** (Pillar 5: models/quota/budget) + the copilot reviewer catalog row.
- Issue **#2908** (main test breakage) — at PR time.
- Release notes: the CHANGELOG `0.40.0-beta.1` entry is written; release-notes doc follows the
  publish per house pattern.
