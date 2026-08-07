# Workshop Record: security-compliance (full)

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Confirmation**: human-confirmed (S1/S2/S4 picked from rendered options after
discussion; S3 confirmed with a human amendment — floor 600)

## Trust-boundary map (agreed)

```text
             TRUST BOUNDARY MAP — reviewer containment (203)

  ┌──────────────────── ORIGIN REPO (the protected asset) ────────────────────┐
  │  working tree · .git · .specrew runtime state · governance scripts        │
  │     ▲  threat (OBSERVED 2026-07-08): permissions-skipped reviewer left    │
  │     │  its worktree, ran origin Pester suites, hung an interactive        │
  │     │  script, fired a REAL `specrew review --live` against the origin    │
  └─────┼──────────────────────────────────────────────────────────────────────┘
        │  W1  worktree relocates OUTSIDE origin root (system temp)  [structural]
        │  W2  origin-absolute paths stripped from reviewer bundle   [structural]
        │  W3  confinement contract in slim prompt + spawn contract  [instructional]
        │  W4  origin-access detector → 'containment-violated', loud [detective]
  ┌─────┴──────────────── REVIEWER WORKTREE (relocated) ──────────────────────┐
  │  materialized from the CERTIFIED digest tree (identity fix, shipped)      │
  │  W5 ONE machinery list feeds digest strip AND worktree strip              │
  │  W6 stripped-paths teaching (reviewer told what is absent, and why)       │
  └────────────────────────────────────────────────────────────────────────────┘
   Process containment (Job Object / setsid): SHIPPED — every kill reaps the tree
```

Origin-discovery leak paths (established in discussion):

- **Path A (mechanical)**: the materialized tree has no `.git` of its own;
  living UNDER the origin root, any git command walks up and operates on the
  origin. W1 relocation to system temp kills the upward walk.
- **Path B (self-inflicted)**: committed governance docs carry origin-absolute
  `file:///` paths (Rule 52) into the reviewer bundle. W2 strips/relativizes.

Trust model (recorded): the reviewer is trusted for **judgment**, not with the
**origin** — independence means the certifying party cannot touch the asset it
certifies. Inside its worktree it keeps full capability. Git revert is a
safety net only for tracked content; the real escape cost was side effects
(live API spend, budget burn) and untracked local state — hence containment,
not recovery, is the fix. OS path-jails (AppContainer/Landlock) stay out of
scope: per-OS, non-host-neutral; Job Objects/cgroups govern process lifetime
and resources, not filesystem paths.

## S1 — Enforcement floor (decided)

**W1–W3 + W4 as cheap detector.** W4 rides the T100 child-process registry
(cwd/commandline sampling); after W1 relocation, an origin-root-prefixed path
in a reviewer child process is a high-precision signal. On detection: mark
the run `containment-violated`, fail LOUD, never kill mid-flight (false kills
would reintroduce the budget-death class).

## S2 — W5 machinery-path alignment (decided)

**Path-granular ONE list**, consumed identically by both strips:

```text
  EXCLUDED both sides (host machinery):
    .claude/**  .agents/**  .cursor/**  .copilot/**
    .github/copilot-instructions.md
    .github/instructions/**  .github/prompts/**  .github/agents/**
  INCLUDED both sides (real reviewable content):
    .github/workflows/**  + everything else (source, specs, docs, tests)
  guard: every list change ships a reviewer-can-still-see-it regression test
```

Settles the `.claude/settings.local.json` false-positive class (never again
reviewed as an app change) and answers the proposal's open question #2:
workflows are consumer content, host dirs are machinery.

## S3 — T096 teaching posture (decided, amended)

Halt/timeout texts name the exact sanctioned command
(`specrew review --remediate more-time --timeout-seconds <n>`) and the config
key (`co_review_timeout_seconds`), state that a bare `--live` rerun will NOT
re-review past the ceiling, and never suggest touching runtime state.
Enforcement stays at input provenance: remediation/budget increases accepted
only from genuinely human-typed commands (T096); the agent never
self-escalates. Automatic bounded escalation stays out (Proposal 102 opt-in
umbrella).

**Budget resolution order**: explicit flag → project config → catalog
per-host `default_timeout_seconds` → **600 floor** (maintainer amendment:
"300 is too short according to all our tests" — field kills at 180/300/400 vs
hosts measured 400–870). The floor is the *terminal fallback*, not a clamp —
an explicit lower value stays accepted (DEC-197-I010-007 explicit-beats-config)
and draws the W14 warning, which keys off the RESOLVED value.

## S4 — W15 independence defaulting (decided)

**Env cascade + provenance field.** The manual `--live` door resolves the
code-writer host via `--code-writer-host` flag → `SPECREW_HOST` →
`SPECREW_ACTIVE_HOST` (explicit flag wins), and the run evidence records
`independence_source: flag | env | unverified` so D5-bearing independence
labels are auditable. SEC-004 fail-closed treatment of `unverified` stays.
