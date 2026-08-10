# Requirements-NFR Lens Record: 199-beta3-stabilization

**Feature**: 199-beta3-stabilization
**Depth**: medium
**Captured**: 2026-08-10
**Confirmation**: human-confirmed (typed rulings on N1-N4, the acceptance bar, and two additions)

## Quality priorities (agreed)

```text
Priority  Quality attribute            Driven by         Measured as
────────  ───────────────────────────  ────────────────  ─────────────────────────────
1         Bounded spend, human control  item 1 (F8 loop)  no round runs without an
                                                          unspent human authorization
2         Gate coherence (no wedge)     items 1,2 (F5)    stop-here lands in one action;
                                                          zero stale-blocks on
                                                          records-only deltas
3         Consumer comprehensibility    items 7,8,3       zero machinery nouns; glossed
                                                          IDs; capture matches contract
4         Install accessibility         item 4 (F1)       default CurrentUser/OneDrive
                                                          install runs campaigns
5         First-run bootstrap           item 5 (F2/F3)    fresh project + init →
                                                          preflight passes
```

## N1 — Default round budget per digest: 4 (bridge)

Semantics: the engine-owned pause is the economics control — every round is
individually human-authorized (single-run grants only; grant KINDS are beta4's
vocabulary cluster). The budget is only the RUNAWAY FUSE for when instructions fail:
at 0 the engine hard-refuses new rounds until an explicit human reset (the existing
allowance-reset action).

**Human-recorded rationale**: 4 is deep enough that a legitimate round-5-class blocker
(T067 precedent: real blockers in rounds 1, 2, and 5) doesn't hit the reset ceremony
mid-flow, small enough that a runaway dies fast.

## N2 — Review windows (durable)

codex-class default window: 900 seconds (planning-scale digests; T067: silent timeout
at 300 s, real findings inside 900 s). Other hosts untouched (closed scope). The
timeout message names `co_review_timeout_seconds` per the U4 message shape.

## N3 — Spend accounting: reviewer-invoked-only (durable)

A round consumes allowance ONLY if a reviewer process was actually invoked.
`preflight-failed`, `claim-contended`, `launch-failed` publish run records (honest
history) but consume nothing — aligned to the legacy engine's spend-class rule
(`Get-ContinuousCoReviewRoundSpendClass`). Acceptance fixture reproduces T067's three
infrastructure failures leaving the allowance untouched.

## N4 — Default env_refs allowlist (durable)

Names-only pass-through, sized for git/dotnet/npm:
`PATH, PATHEXT, SYSTEMROOT, COMSPEC, TEMP, TMP, TMPDIR, HOME, USERPROFILE, APPDATA,
LOCALAPPDATA, PROGRAMFILES, PROGRAMFILES(X86), PROGRAMDATA`
(TMPDIR added by the human for POSIX alongside TEMP/TMP.) Project-specific additions
are the consumer's one-line edit; the failure message names `env_refs` with the exact
line to add.

## The confirmed SC set for specify (each a RED-first fixture through the shipped entry point)

1. After every campaign round the decision surface renders and nothing spends until a
   numbered human reply.
2. Budget exhaustion hard-refuses continuation without an explicit human reset.
3. Zero `review-stale` firings on records-only deltas; an authorized in-flight run
   suppresses the block; a pending pause decision is quiet.
4. Stop-here composes frozen-tree verification + residual acceptance + gate sync as
   one action.
5. Leading approval phrase with trailing instructions captures as
   approve-with-instructions; capture scans past non-verdict turns; "clarify"/"prompt"
   as plain English never flip classification (iteration 011 reproductions).
6. Cloud-placeholder install hydrates and verifies; junction/symlink still refuses;
   refusal message consumer-shaped.
7. Fresh project + `specrew init` passes campaign preflight.
8. Infrastructure failures leave the allowance intact.
9. Zero machinery nouns and zero unglossed IDs in rendered consumer surfaces.
10. Banner renders the full prerelease version (0.40.0-beta3).

## Addition 1 (human) — The reviewer prompt contract (item 1's design lineage)

The reviewer's task changes from a findings-goal to a VERDICT-goal: it determines
whether the artifact is safe to proceed on. A justified clean verdict naming what was
verified and found sound is a successful, explicitly blessed output. Every finding must
state a concrete failure scenario (inputs/state producing observable wrong behavior) or
it is not a finding. Output is ranked and capped. This attacks gold-plating at its
mechanism — a goal-oriented reviewer must be able to satisfy its goal by saying ship.
The machine-readable consequence tags stay in beta4's instrument-panel scope.

## Addition 2 (human) — ID gloss rule

Confirmed as already recorded in the ui-ux lens record (U2) and its bindings:
human-visible prose renders every task/requirement/finding ID with a short plain
description via a helper requiring id + title (unglossed ID = failing test); records
keep bare IDs canonical.
