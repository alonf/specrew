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

**Amendment 2026-05-28 — Reviewers discover lessons BEFORE retro, in more precise form.** F-049 iter-3 review-signoff demonstrated that an independent reviewer with explicit playbook context produces methodology lessons during the review work product itself (concrete file:line citations, specific verification techniques that caught the gap, structured findings). Retro is too late for the CAPTURE step; retro is the right place for the TRIAGE step. The original Mechanism A + B framework was retro-only as both capture + triage; this amendment adds Mechanism C to capture at review-time and separates capture from triage architecturally. Input expansion: retro.md only → `review.md` + `retro.md` + `pr-review-resolution.md` (composes with Proposal 089 PR Review Integration + Proposal 140 Reviewer Instruction Surface).

## What

Three mechanisms (originally Mechanism A + B; Mechanism C added 2026-05-28 amendment):

**Mechanism A — Mandatory corpus-row graduation in retros**:

- Validator rule: every `retro.md` MUST contain a `## Corpus Row Candidates` section with at least one entry
- Hard-fail on retros without this section
- Forces the "what should be enforced going forward?" question to be answered explicitly per iteration

**Mechanism B — Pre-implementation corpus consultation**:

- Before each iteration's implementation begins, Squad consults recent retros + known-traps and surfaces relevant traps in the iteration plan
- Coordinator-prompt rule: "Before implementation, consult `.specrew/quality/known-traps.md` and recent retros; for each relevant trap, document how the implementation avoids it"

**Mechanism C — Reviewer Instruction Candidates pipeline (added 2026-05-28)**:

Separates CAPTURE (review-time, precise) from TRIAGE (retro-time, deliberate). Composes with Proposal 140 (Reviewer Instruction Surface) which ships the durable methodology destination.

Capture stage (during review-signoff):

- `review.md` template gains `## Reviewer Instruction Candidates` subsection
- Reviewer captures methodology lessons during the review work product:
  - Form-without-runtime-compliance patterns observed (Shape 1-8 from `docs/methodology/lifecycle-discipline.md` Shape Catalog)
  - Verification techniques that caught (or would have caught) a gap (schema diff, type-contract trace, escape-hatch end-to-end, multi-altitude verification, SC-clause audit)
  - Spec coverage holes
  - Reviewer-discipline gaps the current playbook doesn't address
- Concrete file:line citations + structured findings (not deferred to retro)

Triage stage (during retro):

- `retro.md` template gains `## Triage Reviewer Instruction Candidates` subsection
- Retro processes the review.md inputs from the iteration (and pr-review-resolution.md from address-pr-review-gate per Proposal 089):
  - **PROMOTE → durable methodology** (`.specrew/review/reviewer-instructions.md` or `.local.md` overlay via Proposal 140 channel)
  - **PROMOTE → defect catalog** (`.specrew/quality/known-traps.md` — composes with Mechanism A)
  - **PROMOTE → validator proposal** (new proposal candidate for mechanical enforcement)
  - **DEFER → recurring observation; revisit next iteration**
  - **DROP → not actionable**

This creates clean artifact distinctions:

- `known-traps.md` = compact defect catalog (what bugs look like)
- `reviewer-instructions.md` = how to review (operational discipline; via Proposal 140)
- `retro.md` = how the team learned (the journey + triage)
- validators = mechanical enforcement (what's automatable)

This is a focused subset of the queued Feature-005-Phase-2 lens-execution work, which covers more.

### Expanded learning-loop inputs (post-2026-05-28 amendment)

Pre-amendment: learning loop fed only by `retro.md` (Mechanism A's `## Corpus Row Candidates`).

Post-amendment: learning loop fed by:

- `retro.md` (Mechanism A's `## Corpus Row Candidates` — unchanged)
- `review.md` (Mechanism C's `## Reviewer Instruction Candidates` — added 2026-05-28)
- `pr-review-resolution.md` (Mechanism C input via Proposal 089 composition — PR review findings that surface methodology lessons)

Triage discipline (Mechanism C) consolidates all three input channels at retro time. Each candidate is processed once; classification is explicit; downstream destinations (durable methodology / defect catalog / validator proposal / DEFER / DROP) are explicit per candidate.

## Effort

Originally ~12-15 SP across 1-2 iterations (Mechanism A + B only).

Post-2026-05-28 amendment: **~16-20 SP across 2-3 iterations** (Mechanism A + B + C):

- Mechanism A (validator rule for corpus-row section in retro.md): ~3-5 SP
- Mechanism B (pre-implementation corpus consultation): ~5-7 SP
- Mechanism C (Reviewer Instruction Candidates pipeline; review.md template + retro.md triage subsection + input integration with pr-review-resolution.md): ~3-5 SP
- Composition tests across all three mechanisms: ~2 SP

Mechanism C composes with Proposal 140 (Reviewer Instruction Surface ships the `.specrew/review/reviewer-instructions.md` destination) + Proposal 089 (PR Review Integration provides pr-review-resolution.md input). If 140 ships standalone first, Mechanism C work shrinks because the destination surface is already in place.

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
- **Composes with (added 2026-05-28)**:
  - file:///C:/Dev/Specrew/proposals/140-reviewer-instruction-surface.md — Mechanism C destination surface (Pillar 5 ships the same review.md + retro.md template work from the playbook-deployment side; tight composition)
  - file:///C:/Dev/Specrew/proposals/089-pr-review-integration-address-pr-review-gate.md — Mechanism C input source (pr-review-resolution.md)
  - file:///C:/Dev/Specrew/proposals/099-installed-file-sdlc-instruction-audit.md — Cluster 8 (Reviewer Discipline) amendment 2026-05-28 names the broader gap that Mechanism C addresses for the reviewer-side
  - file:///C:/Dev/Specrew/proposals/102-cross-model-independent-reviewer.md — cross-reviewer findings flow through Mechanism C same as single-reviewer findings
- Foundation for: methodology's claim of "self-improving through enforced learning"

## Status history

- **2026-05-14**: candidate captured during Rule 15 first-real-world-test memory entry; recognized as load-bearing for the corpus-row graduation pipeline.
- **2026-05-28**: amended. Added Mechanism C (Reviewer Instruction Candidates pipeline). Expanded learning-loop inputs from `retro.md` only to `review.md` + `retro.md` + `pr-review-resolution.md`. Effort bumped from ~12-15 SP to ~16-20 SP. Composes with Proposal 140 (ships destination surface) + Proposal 089 (pr-review input). Amendment empirically motivated by F-049 iter-3 review-signoff 2026-05-28 demonstrating that reviewers discover methodology lessons BEFORE retro in more precise form than the original retro-only capture model assumed.
