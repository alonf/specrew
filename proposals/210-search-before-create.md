---
proposal: 210
title: Search-Before-Create - Reuse Discipline at Design and Implement Time
status: candidate
phase: phase-2
priority-tier: 2
estimated-sp: 4-6
discussion: maintainer observation 2026-07-20 during F-198 Iteration 008 - "instead of reusing existing code for crosscutting concerns, or reusing a component that has the specific responsibility, the AI coding agent just recreates the same functionality. Do we have any feature or instructions in Specrew to prevent it?"
---

# Search-Before-Create

## Why

AI coding agents recreate existing functionality instead of reusing the component that already owns
the responsibility. The pattern is strongest exactly where reuse matters most - crosscutting
concerns (path resolution, process spawning, timestamp formatting, retry/timeout handling) - because
those are the capabilities an agent can most plausibly re-derive from scratch without noticing the
existing owner.

Specrew already ships three countermeasure layers, and a 2026-07-20 audit found all three share one
blind spot:

1. **Design time.** The component-design lens activates on "the change risks duplicated logic,
   hidden coupling, or unclear ownership" and requires new abstractions to be justified by
   variation, complexity, or reuse.
2. **Implement time.** The `specrew-code-rules` skill (Feature 177 / Proposal 163) surfaces the
   feature's implementation-rules manifest plus the canonical `code-rules.yml` catalog per task,
   including `code-rule.normalize-state` ("avoid duplicated/derivable state; keep canonical
   ownership clear") and `code-rule.avoid-common-utility-libs` ("extract a package only when the
   reuse boundary is real").
3. **Review time.** Catalog rules carry `enforcement_mode: [review]`, making duplication-adjacent
   rules formal review criteria.

The blind spot: **all three layers are rule-shaped, but the failure is retrieval-shaped.** An agent
does not recreate a trunk resolver because it disagrees with a reuse rule - it recreates one because
it never learned the existing resolver exists. A rule saying "avoid duplication" cannot fire in the
agent's head if the search never happened. Supporting evidence from the audit:

- The F-198 campaign reviewer prompt carries no "does this re-implement an existing owner?"
  dimension - even the enforcement layer catches duplication only incidentally.
- The Specrew repository's own single-owner culture ("the ONE machinery source", "the ONE load
  seam", `co-review-trunk-resolver.ps1` "replaces the duplicated 'main' defaults + ad-hoc candidate
  loops") was produced by human review pressure across many correction rounds, not by any shipped
  instruction. Consumer projects inherit the rules but not the pressure.
- Small direct fixes skip the design lenses entirely - and that is exactly where duplication happens
  most.

The unlock is that Specrew already generates a capability inventory every iteration and then never
feeds it forward: `code-map.md` is produced at review closeout (one of the six review-evidence
envelope files) and consumed by nobody at design or implement time.

## What

Insert the search-before-create discipline at the two points the maintainer named: the design
workshop and the implementation phase. Review coverage arrives through the existing
`enforcement_mode: [review]` mechanism rather than a new surface.

### W1 - Design workshop: existing-component context injection

When a lens session starts (component-design, architecture-core, and integration-api first; other
lenses may opt in), the workshop resolves and injects a bounded **"Existing capability owners"**
context block:

- **Source**: the freshest available `code-map.md` (any iteration - freshest wins) plus the module
  inventory (manifest/FileList or equivalent), resolved read-only.
- **Selection**: relevance-filtered against the feature's stated scope and the lens topic (lexical
  keyword match first; no embedding infrastructure), bounded top-N with a link to the full map.
- **Absence**: a project with no code-map yet gets a one-line notice plus the live-search fallback
  (below) instead of a silent skip.

Every new-component decision recorded by the lens gains a mandatory **reuse-disposition line**:
`reuse <owner>`, `extend <owner>`, or `new - justified by <variation|complexity|reuse-boundary>`.
This is the lens's existing justify-language made evidence-bearing: the disposition is written into
the lens record, so review and retro can audit it.

### W2 - Implementation phase: the search-before-create obligation

- **New catalog rule** `code-rule.search-before-create` (`enforcement_mode: [review]`): before
  introducing a new crosscutting helper, component, or utility, search for an existing owner and
  record one line in the task evidence naming what the search found and why it does or does not fit.
  The obligation is the search, not the reuse - the `new - justified` arm is always legitimate.
- **The `specrew-code-rules` skill surfaces the capability map** at its existing per-task
  re-invocation, so the inventory is in front of the agent while it writes - the rule text alone is
  not retrieval.
- **Degraded mode**: consumer projects without a code-map yet fall back to a bounded live search
  (glob/grep by responsibility keywords over the source tree). The map is the accelerator; the
  search is the obligation.

### Functional requirements

- **FR-210-1**: The design workshop injects a bounded, relevance-filtered existing-capability-owners
  block at lens start for the component-design, architecture-core, and integration-api lenses,
  sourced from the freshest code-map plus module inventory, with graceful absence behavior.
- **FR-210-2**: Lens records require a reuse-disposition line (`reuse`/`extend`/`new - justified`)
  for every new-component decision.
- **FR-210-3**: `code-rules.yml` gains `code-rule.search-before-create` with review enforcement and
  a decision-prompt entry consistent with the catalog's existing shape.
- **FR-210-4**: The `specrew-code-rules` skill resolves and surfaces the freshest capability map at
  invocation, with the bounded live-search fallback when no map exists.
- **FR-210-5**: Task evidence for any new crosscutting capability carries a one-line search citation
  (what was searched, what was found, why it does/doesn't fit) - cheap, non-gating, review-auditable.

### Out of scope

- **Mechanical clone/similarity detection** - expensive, noisy, and it fires after the duplicate
  exists; this proposal prevents, not detects.
- **A new component registry or database** - `code-map.md` is the existing owner of "what
  capabilities exist"; building a second inventory would violate the proposal's own rule.
- **Write-time blocking gates** - Feature 177's stance holds: guidance while writing, enforcement at
  review, no mechanical conformance gate.
- **Retroactive de-duplication sweeps** of existing code (schedule separately if ever wanted).

## Effort

4-6 SP total: workshop injection with the lens-record disposition 1.5-2 SP; catalog rule, skill
surfacing, and fallback 1-1.5 SP; review-instructions touch-up 0.5 SP; fixtures and regression
tests 1-2 SP.

## Phase placement

Phase-2 (Beta3 window). Touches workshop skill templates, the code-rules catalog and skill template,
and review instructions - all assets that deploy to consumers, so it rides a normal minor release.
Natural partner of Proposal 208 (decision-ready packets - same "give the human/agent the context at
the decision point" principle) and Proposal 207 (the behavioral-evaluation harness is the right
instrument to prove this instruction actually changes agent behavior rather than adding ceremony).

## Open questions

1. Which additional lenses (data-storage? devops-operations?) should receive the injection after the
   first three prove out.
2. The trigger heuristic for FR-210-5: all new files, or only crosscutting-shaped ones
   (util/helper/common/shared name-and-path patterns plus anything the lens did not design)?
3. Code-map freshness in consumer projects with long-running iterations - is freshest-wins plus the
   live-search complement enough, or should the map carry a staleness banner?

## Risks

- **Ceremony creep**: if the evidence line degenerates into boilerplate, the discipline is dead
  weight. Mitigation: one line, bounded top-N context, advisory-first posture (the Proposal 208
  lesson) - and Proposal 207 evaluation before any escalation to lint.
- **Stale map misdirects**: an old code-map can name owners that moved. Mitigation: freshest-wins
  resolution plus the live-search complement; the map accelerates, the search decides.
- **Forced false reuse**: pressure to reuse can bend a design onto the wrong component. Mitigation:
  the `new - justified` arm is a first-class outcome; the rule demands the search, never the reuse.

## Cross-references

- Component-design lens (`extensions/specrew-speckit/knowledge/design-lenses/component-design.md`) -
  the design-time justify-language this proposal makes evidence-bearing.
- Code-rules catalog and skill (Feature 177 / Proposal 163;
  `extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml`,
  `extensions/specrew-speckit/squad-templates/skills/code-rules.md`) - the implement-time carrier.
- `code-map.md` review-closeout artifact (F-198 finalization envelope) - the existing capability
  inventory this proposal feeds forward.
- Proposal 207 (agent instruction behavioral evaluation) - the proof instrument.
- Proposal 208 (decision-ready stop packets) - the advisory-first precedent.

## Status history

- 2026-07-20: Authored as candidate from the F-198 Iteration 008 maintainer discussion; scoped to
  the two insertion points the maintainer named (design workshop context injection, implementation
  phase obligation) with review coverage via the existing enforcement mode.
