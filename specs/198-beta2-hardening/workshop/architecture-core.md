# Workshop Record: architecture-core (full)

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Confirmation**: human-confirmed ("Yes for all" — A1/A2/A3; A4 approved as drafted)

## A1 — Decomposition style (binding constraint)

Inherit Specrew's existing decomposition: **data-driven catalogs behind stable
seams + host-neutral governed scripts**. Every new volatile thing in this
bundle becomes *data* (deny-list file, catalog `default_timeout_seconds`
column, single machinery-path list, release model in
`repository-governance.yml`) — never host-conditional code.

## Seam map (agreed)

```text
                        SPECREW SELF-HOST REPO
  ┌─────────────────────────────────────────────────────────────────┐
  │  AUTHOR-TIME SURFACES                                           │
  │   templates/**  squad-templates/**  refocus/**  skills/**       │
  │        │  205-W1 deny-list lint scans EXACTLY the deploy        │
  │        │  allowlist (205-W3: deny-by-default manifest)          │
  │        ▼                                                        │
  │  DEPLOY SURFACE (specrew init / update)                         │
  │   distribution-module-init.ps1 ── 204-W3 surgery                │
  │   templates/github/workflows/* ── 204-W1 gateway, W2 path fix   │
  │   update heal path (F-116)     ── 204-W5, #2903 refocus sync,   │
  │                                    205-W5 detect-then-heal      │
  ├─────────────────────────────────────────────────────────────────┤
  │  GOVERNANCE CORE (host-neutral)                                 │
  │   sync-boundary-state.ps1 ──── #2906 detect-at-next-stop        │
  │   shared-governance.ps1 ────── Test-SpecrewBoundaryAuthorization│
  │                                (dead code → real call sites)    │
  │   digest identity computation ─ 203-W13 conditional tracker     │
  │                                 strip (honesty check)           │
  ├─────────────────────────────────────────────────────────────────┤
  │  REVIEWER RUNTIME                                               │
  │   worktree materialization ─── 203-W1 relocate outside origin   │
  │   slim prompt + spawn contract─ 203-W3/W6 confinement teaching  │
  │   round ceiling / budgets ───── 203-W11/W12/W14/W16             │
  │   evidence recorder ─────────── 203-W8 runner-observed          │
  │   checkpoint baselines/digest ─ 203-W9/W10                      │
  ├─────────────────────────────────────────────────────────────────┤
  │  DATA SEAMS (volatility isolated as data — repo doctrine)       │
  │   reviewer-host-catalog.ps1 ─── 203-W16 default_timeout_seconds │
  │   deny-list file (NEW) ──────── 205-W6 one list, both sides     │
  │   machinery-path list (ONE) ─── 203-W5 digest strip ≡ worktree  │
  │   repository-governance.yml ─── 204-W7 release-model resolver   │
  ├─────────────────────────────────────────────────────────────────┤
  │  SUBSTRATE                                                      │
  │   Spec-Kit pin 0.8.4 → 0.12.9 (breaking: --ai → --integration)  │
  │   Squad pin 0.9.1 → 0.11.0 (clean)                              │
  └─────────────────────────────────────────────────────────────────┘
```

## A2 — #2906 fix shape (agreed)

Deterministic ratchet in sync + shared authorization primitive; hooks stay
surfacing-only. Confirmed host-neutral: the enforcement rides the one code
path proven to fire on the worst-case non-stopping host (the Copilot forensic
run called sync at each crossing — that is how the mechanical record exists).

```text
  agent calls sync-boundary-state.ps1 (boundary N)
        │
        ├─ record mechanical crossing (F-174 unchanged)
        ├─ compute delta: lifecycle position vs last_authorized_boundary
        │
        ├─ delta ≤ 1 boundary ahead → record pending-verdict, proceed (today)
        └─ delta > 1 (a prior boundary never human-approved)
              → REFUSE this sync: exit loud "unreconciled skipped boundary"
              → reconciliation = retroactive human approval (advance cursor)
                OR revert to last approved AuthCommitHash (confirm first)
```

Covering set for the delta check (`Test-SpecrewBoundaryAuthorization`
resurrected as the single shared primitive):

```text
  DETERMINISTIC TOUCHPOINTS (host-neutral, no hook needed)     on delta
  ──────────────────────────────────────────────────────────   ─────────
  sync-boundary-state.ps1  (every boundary advance)            REFUSES 2nd unapproved advance
  validate-governance.ps1  (boundary commits, iter close)      FAIL finding: skipped boundary
  resume / specrew start reconciliation (F-174)                "awaiting verdict" re-confirm
  before-implement gate + feature-closeout gate                hard-block
  ──────────────────────────────────────────────────────────
  HOST HOOKS (Stop / FR-011 conformance provider)              surfacing/UX only — nudge,
                                                               never the teeth
```

Honest limit (recorded): one boundary of work can happen unapproved on a
non-stopping host; it is caught at the next deterministic touchpoint and
discarded if not retro-approved. An agent that dodges every touchpoint is not
running Specrew; its artifacts fail every gate.

## A3 — W13 conditional tracker strip (agreed)

Fail-closed conditional bypass; scope `specs/*/iterations/*/state.md` +
`tasks-progress.yml` only; spec/plan/tasks/review/retro stay unconditional
identity; reviewers still SEE trackers (staleness, not visibility).

```text
  tracker-only edit lands after accepted review
        │
        ├─ claims move TOWARD the accepted record ──→ digest bypass: evidence fresh
        ├─ claims INCREASE beyond the accepted record ──→ stales, exactly as today
        └─ checker can't parse / can't map a claim ──→ FAIL-CLOSED: stales as today
```

"Claims" = task statuses, capacity lines, test counts — canonical enums,
compared mechanically. Two mandated regression tests: reconcile-toward-truth
does not stale; falsify-forward does.

## A4 — Iteration slicing (agreed)

```text
  Iteration 001 — SUBSTRATE + FIREWALL-FIRST                (~5 SP)
    Spec-Kit 0.12.9 bump (fix --ai hard-break) + Squad 0.11.0
    205-W1 deny-list lint + 205-W6 deny-list data file + 205-W2 rule
    → every template touched later is born clean, on the new substrate

  Iteration 002 — GOVERNANCE CORRECTNESS CORE               (~6-8 SP)
    #2906 ratchet + detect/reconcile   203-W13 conditional strip
    203-W14 downgrade warning          203-W16 catalog budgets
    203-W15 independence defaulting

  Iteration 003 — REVIEWER CONTAINMENT + ROUND ECONOMY      (~6-8 SP)
    203 W1-W6 (relocation, path hygiene, confinement contract, W4
    evaluate, W5 machinery alignment, W6 stripped-paths teaching)
    203 W7 decision, W8 observed evidence, W9/W10 baselines + frozen
    digest, W11/W12 ceiling teaching + fix-responsive rounds

  Iteration 004 — DISTRIBUTION + RELEASE                    (~5-6 SP)
    204 W1-W7 (gateway, surgery, W5b bootstrap commit, release-model
    resolver) + 205 W3/W4/W5 + #2903 + release bookkeeping + v0.40.0-beta2
```

Order rationale: toolchain first so everything is tested on the new substrate
exactly once; lint first so nothing is retro-scrubbed; #2906 before
containment (p0); distribution last because 204/205 deploy-side work converges
on the same manifest surgery and the release rides out with it.
