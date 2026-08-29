---
proposal: 216
title: Temporal Spec Model — Current Intent as a Derived Projection with Authorized Keyframes
status: draft
phase: phase-3
estimated-sp: 25-40
priority-tier: 2
type: methodology
discussion: 2026-08-29 maintainer conference-slide discussion ("The Spec Is the Source of Truth" is too broad)
depends-on: []
composes-with:
  - 010 # Multi-Developer Reconciliation — this proposal may DISSOLVE a substantial part of its spec-content conflict class rather than solve it
  - 115 # Spec-First Concurrent Development Workflow — 216 supplies the justification 115 currently lacks
  - 056 # Specrew Readonly Mode — adjacent: both concern what a non-authoring reader may safely conclude from project state
  - 156 # Design Analysis Lens Knowledge Catalog — workshop-decisions.yml is a producer-manifest precedent for structured, projectable records
  - 145 # Structured Multi-Phase Reviewer — a reviewer needs "what is current" before it can judge "what changed"
---

## Why

**"The spec is the source of truth" is a category error, not merely an
over-broad claim.** A specification is *normative*: it says what may be built.
Code is *descriptive*: it says what exists. A norm and a fact cannot contradict
each other the way two facts can — they can only diverge, and the divergence is
the entire subject of this methodology. Asking which one "wins" presumes a
contest that does not exist.

Once that is seen, the useful question is not *which artifact is true* but
*true about what*:

| Artifact | Answers |
|---|---|
| Code | What the system does |
| Current spec | What it is meant to do |
| Active change spec | What it is meant to do next |
| Closed iterations | Why it became this way |

Specrew today has three of those four. **It has no product-level answer to
"what is this system meant to do now."**

### The measured gap

Measured in this repository on 2026-08-29:

- **2,342 Markdown files** under `specs/`, **24 MB**, **~2.19 million words**
- **77 feature directories**, 62 of them with iterations, **156 iteration
  directories**
- **36 feature-level current-view artifacts** (`current-architecture.md`,
  `requirement-reconciliation.md`) across those 77 features

An agent — or a new contributor — asking "how does this system work?" faces two
million words with no entry point and no way to tell which of it is still true.

### The prototype already exists, at the wrong scope

Specrew did not miss this problem; it solved it twice, partially, and by hand:

- **`current-architecture.md` is derived** — it carries `Source Iteration Ref`
  and `Last Updated` and points at the latest iteration's artifacts. But it is
  **feature-scoped**, and it answers "which iteration is newest" rather than
  "what does this behave like now."
- **`requirement-reconciliation.md` is authored** — F-197's is signed "Crew
  coordinator (maintainer-approved reconciliation)", dated 2026-07-01, written
  reactively to clean up one worktree cutover. Authored records drift; that is
  the lesson F-199's own retro recorded as *"authored counts drift; derived
  counts do not."*
- **`specs/197-continuous-co-review/spec.md:55`** carries an "Architecture
  Reconciliation" section stating that named FRs "describe the superseded
  machinery." **A feature spec that must warn readers which of its own
  requirements no longer hold is the defect stated in the artifact's own voice.**

The socket for the fix is also already cut: every `product-domain.yml` carries
`product_id` and `product_context_ref`, null in every project.

### Prior art

- **Spec Kit** now documents *multiple* spec persistence models rather than
  mandating one: a **flow-forward** model where completed feature directories
  stay unchanged as historical records and new behavior means a new feature
  directory, and a **living spec** model where `spec.md` is revised and
  downstream plan/tasks are regenerated. Its docs name the flow-forward
  trade-off explicitly — related decisions spread across directories and need
  naming or lineage mechanisms. Spec Kit also ships an active-feature mechanism
  (`.specify/feature.json` / `SPECIFY_FEATURE_DIRECTORY`) so commands resolve
  context from the active feature rather than searching every `spec.md`.
  <https://github.com/github/spec-kit>
- **OpenSpec** separates `openspec/specs/` (current system behavior),
  `openspec/changes/<change>/` (proposed delta) and
  `openspec/changes/archive/` (historical record). Archiving a change merges its
  ADDED/MODIFIED/REMOVED requirements into the current specs while preserving
  the full change. Its docs describe the main specs as how the system
  *currently* behaves. <https://github.com/Fission-AI/OpenSpec>

Specrew inherits Spec Kit's flow-forward model. **This proposal keeps it as the
storage model and adds the projection OpenSpec gets from merge-on-archive —
using Specrew's own authorization and sealing machinery rather than copying
OpenSpec's.**

**Living-spec is rejected outright, and the reason is specific to Specrew.** A
review signed off against a `spec.md` later edited in place leaves a signoff
naming a document that no longer exists — evidence binding, the reviewed-state
digest and the iteration seal all point at content that silently moved. Spec Kit
can offer living-spec because it stakes nothing on a spec's identity at a point
in time. Specrew stakes everything on it.

## What

### 1. Three levels, one door

| Level | Artifact | Nature |
|---|---|---|
| Product | current intent | **derived projection**, one canonical path |
| Feature + active iteration | what is changing now | authored, governed |
| Closed iterations | why it became this way | sealed, never rewritten |

**A feature is a unit of change, not a unit of description.** A product's
behavior is the merge of everything shipped; no single feature directory can
describe it, which is exactly why `current-architecture.md` can only point at
its own latest iteration. The current view therefore belongs at **product**
scope, on the `product_id` / `product_context_ref` hook that already exists.

Agents get **one door, not a resolution order.** A documented search order
("current, then active, then history") is a judgment call, and judgment is what
gets skipped under load — F-199's F-3 finding is an agent inventing a refusal
the code never had. If "how does this work now" has exactly one path, there is
no order to get wrong. History stays reachable; it is not on the default path.

### 2. Merge at iteration-closeout

Changing what "current" means is an authority-bearing act, so it happens at a
boundary that already carries a human authorization and produces a seal. The
moment an iteration's record is frozen is the moment its requirements become
current. No new ceremony.

### 3. Derived, with a truth gate

The projection is recomputed from `(ordered sealed iterations, recorded
supersessions)` and verified, never authored. This is **the same rule F-199
landed as T021 for phase mirrors, one level up**: one writer per authority,
enumerated mirrors, a truth check between them. A derived view that can be
recomputed cannot become the file nobody updated.

Supersession must be a **recorded fact, not an inference**. The drift log
already carries requirement-cited decisions; that is the second input.

### 4. Keyframes — the consolidation mechanism

A projection over the entire history of a long-lived project degrades exactly
the way a video stream of nothing but delta frames degrades: cost grows with
history, a single bad supersession propagates forever, and answering "why is
this requirement the way it is" means replaying everything.

**A keyframe is an authorized, materialized snapshot of current intent.** After
one is cut, the projection replays only the iterations *since* that keyframe.

Properties that make it a keyframe rather than a cache:

- **It is authorized.** A human signs that this *is* current intent. Without
  that it is a derived artifact asserting more than its inputs support.
- **It closes its inputs.** Iterations before it stay readable as history and
  stop being projection inputs.
- **It is materialized**, so a reader with no history can answer "what is this
  system" from one file.

**Natural cadence: the release.** A version tag already means "this is what the
product is now," and Specrew already treats release as a governed act. Cutting
the keyframe at release costs no new boundary.

For **large or multi-developer projects**, keyframes stop being an optimization
and become structural: more iterations per unit time means faster projection
growth, and per-capability keyframes (one per bounded area rather than one per
product) may be required. That is an open question below, not a settled design.

### 5. Merging multiple developers

**Norms serialize; facts parallelize.** Two developers cannot both be
authoritative about what current intent *is* — that is not a tooling limit, it
is what "normative" means. But they can produce code in parallel and merge it,
because facts compose.

That is precisely **Proposal 115's** three-phase shape (sequential spec PR →
parallel per-developer task branches → aggregation). 115 currently reads as a
workflow someone invented; this is why it is correct rather than merely
convenient.

**And it changes the shape of Proposal 010.** A derived current view **cannot
have a merge conflict** — it is recomputed, not merged. The spec-content
conflict class then collapses to concurrent edits of the *active* spec, which
115 already serializes. 010's hardest open question — *"what counts as
overlapping behavior?"* — is hard because it tries to diff normative prose; a
projection never performs that diff. **Hypothesis to test against 010's
taxonomy, not a claim: a substantial part of its 75 SP may be pricing a problem
this removes.**

## Versioning and migration

**What happens to an existing project, including Specrew itself.**

The load-bearing constraint: **a product current view cannot be retroactively
derived from 77 feature directories**, because requirement identity is
feature-scoped — `FR-017` in F-197 and `FR-017` in F-199 are different
requirements wearing the same name. There is no mechanical merge over that.

**Therefore the migration story and the keyframe mechanism are the same
mechanism.** Bootstrapping an existing project *is* cutting its first keyframe:
generate a candidate from whatever is derivable, have a human correct and
authorize it, and start the projection from there. Nothing before the first
keyframe is replayed.

Consequences, stated as commitments:

- **Non-breaking by construction.** A project that never cuts a keyframe is
  unaffected. `specrew update` migrates nothing and rewrites no spec.
- **Existing artifacts keep their meaning.** `current-architecture.md` stays —
  feature-scoped "which iteration is newest" is still a real question.
  `requirement-reconciliation.md` becomes redundant *going forward* once
  supersession is structured; existing ones remain as history and are not
  rewritten.
- **No historical spec is edited, ever.** The audit property is the reason
  living-spec was rejected; this proposal must not reintroduce it by the back
  door.
- **Specrew itself is the hardest case and the first dogfood** — 77 features,
  156 iterations, 2.19M words, 36 partial current-views. If the bootstrap is
  tolerable here it is tolerable anywhere.

## Effort

- **Slice 1 (~8-12 SP)**: product-scope current-view artifact on the existing
  `product_id` hook; keyframe cut-and-authorize at release; bootstrap path for
  an existing project. Deliverable on its own — a project gets one door.
- **Slice 2 (~10-15 SP)**: structured supersession records; projection from
  sealed iterations since the last keyframe; truth gate on the projection.
- **Slice 3 (unpriced)**: requirement identity. Dominates the estimate and is
  the reason the range is wide. Do not start slices 1-2 assuming this is small.

## Open questions

1. **Requirement identity — load-bearing.** Stable scoped IDs, or a
   product-level capability namespace that feature FRs map into? No mechanical
   merge exists until this is answered. This is the question the beta4 workshop
   must settle first.
2. **Keyframe cadence.** Release-tagged, every N iterations, or human-chosen?
3. **Per-capability keyframes** for large projects, or one per product?
4. Projection output format — one document, or a set per capability?
5. Does the truth gate recompute at every boundary or only at closeout?
6. Does the projection carry non-functional requirements and constraints, or
   only FRs?

## Risks

- **The current view becomes another authored artifact that rots.** Mitigated
  only by deriving it and gating it; if either is dropped in implementation the
  proposal has produced a fourth stale document with more authority than the
  three it summarizes.
- **Requirement-identity migration is expensive** and may tempt a partial
  implementation that merges only some requirements — which is worse than none,
  because the gaps are invisible.
- **Keyframe authorization becomes ceremony.** If cutting a keyframe costs a
  boundary stop nobody wants, keyframes will not be cut and the projection
  degrades as designed-against.
- **Two million words is also a token-cost problem**, and a current view that
  is itself enormous solves nothing. Size is a design constraint, not an
  afterthought.

## Cross-references

- Proposal 010 — Multi-Developer Reconciliation. May be substantially reduced;
  see the hypothesis above.
- Proposal 115 — Spec-First Concurrent Development Workflow. This supplies its
  justification.
- Proposal 056 — Specrew Readonly Mode. Adjacent: what a non-authoring reader
  may safely conclude from project state.
- Spec Kit persistence models and active-feature mechanism —
  <https://github.com/github/spec-kit>
- OpenSpec current-specs / changes / archive —
  <https://github.com/Fission-AI/OpenSpec>
- F-199 iteration 002 T021 — the mirror-with-truth-gate rule this generalizes.
- F-199 iteration 001 retro, lesson 7 — "authored counts drift; derived counts
  do not."

## Status history

- 2026-08-29: drafted from a maintainer conference-slide discussion. Empirical
  measurements taken against this repository at commit-time; prior art verified
  against current Spec Kit and OpenSpec documentation. Numbering starts at 216
  because 211-215 exist on `main` and not on this branch.
