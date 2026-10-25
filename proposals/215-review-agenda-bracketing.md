---
proposal: 215
title: Review Agenda Bracketing
status: candidate
phase: unphased
estimated-sp: 3-5
discussion: tbd
---

# Review Agenda Bracketing

## Why

Beta3 established that a review must declare what it examined: `examined_paths` is recorded as a
fact, a complete run that examined no source is degraded, and a present-but-empty declaration means
zero coverage rather than no declaration. That closes the question *what did the reviewer actually
read* — after the fact.

It leaves the question *what did the reviewer set out to read* entirely unasked. The gap is not
theoretical; it is the shape of the most expensive review failure of the cycle. On the KeyContextAI
walk, a run examined the implementation and returned fourteen findings describing components as
missing — because the resolver handed it the whole-feature design against a single sliced iteration.
The reviewer read real code, declared real coverage, and measured it against the wrong yardstick.
Nothing in the evidence chain could say so, because the chain records what was read and never what
the reviewer believed it was reviewing. The frame defect was found by a human reading fourteen
findings and recognising they were artifacts.

Prior art names the mechanism directly. Venya Brodetskiy's progressive code review (dev.to,
Zio-Net skills) makes the reviewer **propose its agenda and get it confirmed before spending
effort** — what is in scope, what needs detail, at what depth, in what order — on the reasoning that
reviewing in the wrong order spends attention on details while the decisions governing them go
unchallenged. Specrew cannot adopt the interactive confirmation for campaign reviewers (they run
contained and non-interactive by design, and conversation would reopen the containment surface), but
the *declaration* survives the containment boundary intact, and it is the half that makes the
failure mechanically detectable.

## What

Extend the reviewer contract so a run declares its **intended scope before reviewing**, alongside
the coverage it declares after. Two declarations then bracket the review:

```
declared agenda   (before)  →  the review  →  examined_paths (after)
```

and the gap between them becomes a first-class, checkable fact:

- **Examined but never proposed** — the reviewer wandered outside the frame it was given.
- **Proposed but never examined** — the reviewer abandoned scope it accepted; a complete verdict
  covering less than it undertook is exactly the overclaim W33 exists to prevent, one layer earlier.
- **Agenda contradicts the resolved frame** — the reviewer's own statement of what it is reviewing
  disagrees with the iteration scope the campaign resolved for it. That is the W30 failure, visible
  at the moment it happens rather than reconstructible from artifact findings afterwards.

The agenda is recorded as a run fact like every other, so the derived independence block can state
what the run set out to do beside what it did, and a record cannot claim a frame the run never held.

### Functional requirements

High-level capabilities (candidate stage):

- The reviewer request bundle asks for an agenda declaration; the harness contract carries it, and a
  run that returns none is treated as undeclared (fail-open, matching the `examined_paths` ramp —
  absence is legacy, an empty declaration is a claim of nothing).
- The agenda is persisted as a run fact with the same immutability as the rest of the store.
- Ingest computes the bracket comparison — proposed vs examined vs resolved frame — and records the
  divergences as facts rather than judging them.
- The gate consumes divergence: a frame contradiction disqualifies the run as signoff evidence; a
  proposed-but-unexamined gap degrades it the way narrow declared coverage does; examined-beyond-
  agenda is recorded and surfaced, not refused (a reviewer reading more than asked is not a defect).
- The human-facing surfaces state divergence in consumer language, never in internal ids.

### Out of scope

- **Interactive agenda confirmation for campaign reviewers** — containment is not negotiable; the
  reviewer declares, the machinery checks, no conversation crosses the boundary.
- **Human-side staged reading** — that is Proposal 212's Mechanism 4, the other end of the same
  idea; this proposal is the reviewer end only.
- **Scoring agenda quality.** Whether an agenda was *wise* is judgement; whether it was *kept* is
  mechanical. Only the mechanical half is in scope.

## Effort

- **Iteration 1 (~3 SP)**: contract extension, agenda as a run fact, ingest-time bracket comparison
  recorded as facts, fail-open on absence.
- **Iteration 2 (~1-2 SP)**: gate consumption (disqualify / degrade / surface), derived-block
  rendering, consumer-language surfaces.
- **Total**: ~4 SP (3-5 range).

## Phase placement

Beta4. Composes with W29/W30 (frame resolution — this makes their correctness checkable rather than
assumed), W33 (declared coverage — the same ramp shape, applied to intent), and Proposal 212's
Mechanism 4, which adopts the human-facing half of the same prior art. Natural companion to
Proposal 213: the walk harness is where a reviewer that abandons its declared agenda can be
adversarially provoked rather than waited for.

## Open questions

- **Agenda granularity**: paths, components, or lenses? Paths compare mechanically against
  `examined_paths` with no new vocabulary; lenses read better to a human but need a mapping. Likely
  paths plus a free-text framing line, decided at draft stage.
- **Frame-contradiction detection**: comparing a reviewer's prose framing against the resolved
  iteration scope is a judgement unless the agenda is structured. This argues for the structured
  half being load-bearing and the prose being evidence for the human, not input to the gate.
- **Harness support**: each host port must carry the agenda request and return; hosts that cannot
  are undeclared rather than refused, per the fail-open ramp.
