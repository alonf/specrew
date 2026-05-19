---
proposal: 017
title: Learning Loop Closure
status: candidate
phase: phase-2
estimated-sp: 13
discussion: tbd
---

# Learning Loop Closure

## Why

Specrew's retro → corpus → enforcement pipeline is human-curated end-to-end. Retros capture lessons, but graduating those lessons to enforced validator rules requires a human to:

1. Read the retro
2. Identify recurring patterns
3. Draft a corpus row in `.specrew/quality/known-traps.md`
4. (Eventually) write a validator rule

Every arrow is a manual step. If attention slips, lessons accumulate in retros without ever becoming enforced rules. This was observed empirically: the same boundary-claim-without-commit pattern recurred across Features 014 and 015 despite being captured in retros — because nobody promoted the retro lesson to a validator rule until Feature 016 explicitly required it.

This proposal closes the loop with mechanical enforcement of the corpus-row graduation pipeline.

## What

Two mechanisms ("Mechanism A" + "Mechanism B" per the Feature-005-Phase-2 source):

**Mechanism A — Mandatory corpus-row graduation in retros**:

- Validator rule: every `retro.md` MUST contain a `## Corpus Row Candidates` section with at least one entry
- Hard-fail on retros without this section
- Forces the "what should be enforced going forward?" question to be answered explicitly per iteration

**Mechanism B — Pre-implementation corpus consultation**:

- Before each iteration's implementation begins, Squad consults recent retros + known-traps and surfaces relevant traps in the iteration plan
- Coordinator-prompt rule: "Before implementation, consult `.specrew/quality/known-traps.md` and recent retros; for each relevant trap, document how the implementation avoids it"

This is a focused subset of the queued Feature-005-Phase-2 lens-execution work, which covers more.

## Effort

~12-15 SP across 1-2 iterations.

## Phase placement

Phase 2 — high-leverage early in Phase 2 because it formalizes the pipeline that Feature 016's six corpus-row candidates (and other future candidates) flow through. Recommended slot: 2.4 (after graduation candidates).

## Open questions

1. Hard-fail vs soft-warning for missing `## Corpus Row Candidates` section?
2. Minimum entry count — 1 or 0 (empty section counts as "explicitly considered, nothing to add")?
3. How many recent retros to consult — last 3? Last N where N = iteration count?
4. Auto-promotion of corpus-row-candidate to passive-guidance vs require explicit human action?
5. Format for "how implementation avoids known trap X" — checklist or free-text?

## Risks

- **Section-stuffing**: developers might add "no candidates this iteration" to satisfy the rule. Mitigation: the entry count is informational; the value is the question being asked.
- **Retro length growth**: more required sections = longer retros. Mitigation: section template; brief acceptable.
- **Consultation overhead**: pre-implementation scan adds time. Mitigation: ~30 seconds added to iteration setup; once-per-iteration cost.

## Cross-references

- Source: split out from queued Feature-005-Phase-2 lens-execution work (full scope deferred to Phase 4)
- Justified by: Feature 016's six corpus-row candidates surfacing during execution — needs durable enforcement pipeline
- Composes with: Proposal 014 (Red Team Agent) — Red Team findings feed corpus pipeline via this proposal's mechanisms
- Foundation for: methodology's claim of "self-improving through enforced learning"

## Status history

- 2026-05-14: candidate captured during Rule 15 first-real-world-test memory entry; recognized as load-bearing for the corpus-row graduation pipeline
