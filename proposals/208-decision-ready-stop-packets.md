---
proposal: 208
title: Decision-Ready Stop Packets - Identifier Glossing, Position Context, Consequence-Bearing Options, Conditional Visualization
status: candidate
phase: phase-2
priority-tier: 2
estimated-sp: 6-9
discussion: maintainer request 2026-07-16, mid-decision during the F-198 Iteration 006 T050 allowance stop - "The agent talks with task numbers, like: close T050, but for me (human), I don't always remember what T050 is about. So I need more context. [...] Remember the goal - to provide to the human all required information for the human to provide a good instructions and to take the correct decision."
---

# Decision-Ready Stop Packets

## Why

Every human-judgment stop exists so the human can give good instructions and make the correct
decision. Today's packets frequently fail that test in four observable ways, all seen live on
2026-07-16 during F-198 Iteration 006:

1. **Bare identifiers.** The Crew asked for an allowance decision phrased around "close T050".
   Task, requirement, and drift identifiers (`T050`, `FR-057`, `SC-019`, `DRIFT-198-I006-001`)
   are agent-memory artifacts, not human-memory artifacts: the maintainer had to interrupt the
   decision with "what is T050?" before answering. Every such lookup is decision latency the
   packet was supposed to eliminate.
2. **Missing position.** The five-section packet (lifecycle Rule 46A) and six-section boundary
   packet (Rule 46) say what happened, but not always *where we are* - which feature, iteration,
   and task the pending decision belongs to. A returning human reconstructs position from memory
   or scrollback.
3. **Consequence-free options.** Verdict options render as labels ("1. Approve as-is") without
   cost or effect. The information that actually drives a correct verdict - wall-clock, paid
   provider spend, what closes versus stays open, what becomes hard to reverse - lives elsewhere
   in the packet or not at all.
4. **Prose-only description of structural work.** When a stop reports structural change (a flow
   implemented, components added, a state machine reshaped), prose alone under-communicates what
   a small console sketch shows at a glance. The design workshop already proved the ASCII-first
   norm works on every terminal host; packets never adopted it.

The acceptance principle for all four: **a stop packet is complete when the human can decide
without asking a follow-up question.**

## What

- **W1 - Identifier gloss rule (prose contract).** Any task/requirement/criterion/drift
  identifier in human-facing prose is glossed on first use per message: "T050 (the independent
  review task)", "FR-057 (campaign/run authority model)". The gloss comes from the identifier's
  authoritative title (the plan/tasks table row, the spec requirement heading), shortened -
  never a freshly invented paraphrase that can drift from the artifact. Exemptions: tables that
  carry a title column, code/command blocks, and machine-facing artifacts (JSON, YAML, ledgers).
- **W2 - Position line.** Every packet opens with one line locating the decision before
  narrating it: `Position: feature 198-beta2-hardening / iteration 006 / T050 (independent
  review) - awaiting allowance decision`. Sourced from `session_state` plus the pending-verdict
  machinery; when the canonical cursor is stale (the F-198 Iteration 006 cross-iteration
  matcher incident), the packet renders the iteration-artifact truth and says so rather than
  the stale cursor.
- **W3 - Consequence-bearing options.** Each option in "What I Need From You" and each verdict
  menu entry carries one clause of consequence: expected wall-clock, paid spend (provider
  slots, tokens), what closes or remains open, and reversibility. Example: "1. Authorize one
  run (~12 min, one paid slot; a clean result closes T050)". Defaults name what the default
  costs, not only that it is the default.
- **W4 - Conditional console visualization.** When a stop describes structural work - new or
  changed components, an implemented flow, a state-machine change - the "What I Just Did" or
  "What Happens Next" section includes a small in-band ASCII flow or component sketch, reusing
  the design-workshop ASCII-first surfacing rule. Explicitly conditional: trivial stops
  (status answers, single-file fixes, question answers) get no diagram, because a diagram on
  every stop becomes noise that hides the decision.
- **W5 - Templates plus advisory-first enforcement.** Update the Rule 46/46A packet templates
  and packet teaching (refocus fragments, boundary-packet scaffolds) to carry W1-W4. The
  conformance Stop provider gains an advisory-first lint on the rendered packet - bare
  identifier without a nearby gloss, missing position line - reported as a warning, never a
  block (the F-033 advisory-first precedent). Paired tests cover both directions: a compliant
  packet passes silently; a bare-identifier packet warns.

### Functional requirements

High-level capabilities (candidate form):

- Glossed identifiers on first use in all human-facing prose, sourced from authoritative titles.
- A position line in every human-judgment and material-work packet.
- Consequence clauses on every rendered verdict/option list.
- Conditional ASCII visualization for structural-work stops, none for trivial stops.
- Advisory-first packet lint in the conformance provider, host-neutral, with paired tests.

### Out of scope

- Changing *when* packets are demanded. Suppression policy - including the workshop-intermediate
  stop already specified as FR-056/SC-016 in the F-198 spec - stays owned by that feature; this
  proposal only changes what a packet contains when one is owed.
- Rich rendering (mermaid-required output, images): terminal hosts are the floor; ASCII-first.
- Auto-generating glosses via an extra model call at stop time; glosses come from artifacts the
  session already holds.
- Blocking enforcement of the new content rules (advisory-first only until dogfood evidence
  justifies more).

## Effort

- **Iteration 1 (~6-9 SP)**: templates + teaching updates (~2 SP); position-line plumbing from
  `session_state`/pending-verdict machinery (~1-2 SP); conformance-provider advisory lint with
  paired tests (~2-3 SP); dogfood calibration of the W4 trigger heuristic (~1-2 SP).
- **Total**: ~6-9 SP, single iteration.

## Phase placement

Phase-2. Natural scheduling partner: the FR-056 (workshop-intermediate stop) implementation
already queued for F-198 Iteration 007 - both change the same engine surface (the conformance
Stop provider and packet rendering), so one implementer can carry both without re-learning the
area. Not a Beta2 release blocker.

## Open questions

1. Warn versus block for a missing gloss/position line - advisory-first is recommended here;
   should any packet class (boundary verdict stops) eventually hard-require the position line?
2. Gloss source of truth: always the artifact title (plan/tasks/spec heading), or may the agent
   shorten it, and by how much before it counts as an invented paraphrase?
3. When the canonical cursor and iteration artifacts disagree (the F-198 stale-matcher class),
   which does the position line render, and how does it disclose the divergence?
4. W4 trigger: agent judgment, or a deterministic classifier (e.g., stop follows commits
   touching more than N non-test files, or introduces new functions/components)?
5. Should the gloss rule extend beyond packets to commit messages, drift-log prose, and state
   records, or is packet prose the right first scope?
6. Should gloss density adapt to the Crew Interaction Profile (Proposal 015's
   expertise-aware interaction) - e.g., terse glosses for a maintainer, fuller ones for a new
   user?

## Risks

- **Over-verbosity**: glossing every mention bloats packets. Mitigated by first-use-per-message
  scope, table exemptions, and title-derived (not narrative) glosses.
- **Stale or wrong glosses**: a wrong description is worse than a bare identifier. Mitigated by
  requiring artifact-derived titles rather than agent paraphrase (open question 2 bounds this).
- **Lint false positives**: identifiers legitimately quoted from historical text or inside code
  spans. Mitigated by advisory-first severity and code-span/table exemptions.
- **Diagram noise**: if the W4 condition is too loose, every stop grows a sketch and packets
  become slower to read, not faster. Mitigated by the explicit trivial-stop exclusion and
  dogfood calibration before any enforcement.

## Cross-references

- Related proposals: 015 (expertise-aware adaptive interaction - gloss depth could follow the
  profile), 146 (refocus - teaching fragments carry the new packet rules), 155 (typed boundary
  gate packets - the typed fields are where the position line and option consequences can live
  structurally), 207 (behavior-evaluation harness - packet compliance is a natural scenario).
- Source artifacts: F-198 spec FR-056/SC-016 (workshop-intermediate stop - same engine surface,
  explicitly out of scope here); the 2026-07-16 F-198 Iteration 006 T050 allowance stop that
  motivated this proposal.
- Composability with: the Rule 46/46A packet contracts; the conformance Stop provider's
  existing packet-shape validation.

## Status history

- 2026-07-16: created as candidate. Maintainer request during the F-198 Iteration 006 T050
  allowance decision, generalized from "gloss task numbers" to the decision-readiness contract
  above.
