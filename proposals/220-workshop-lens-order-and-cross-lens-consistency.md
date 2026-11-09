---
proposal: 220
title: Workshop Lens Order and Cross-Lens Consistency - Problem Space Before Solution Space, a Back-Check After Every Lens, and a Final Sweep
status: draft
phase: phase-2
estimated-sp: 20-30
priority-tier: 2
discussion: maintainer conversation 2026-11-09 during Feature 203 (beta5 stabilization) - "part of it is about the problem domains, the requirements, the NFR, constraints and so on. The other part is an analysis about the solution domain, like architecture, components, technology, and code standard. I wonder if the order of lenses is correct"; ruling - "change the order as suggested, and in any end of lens, we need to check if we influenced an already passed lens, and at the end we need to do a final sweep"
---

# Workshop Lens Order and Cross-Lens Consistency

## Why

The design workshop's lenses cover two different kinds of question. Some describe the **problem space**: who the
users are, what hurts, which qualities matter and how much, which constraints are binding, what data is sensitive,
which outside systems must be honoured. Others choose the **solution space**: the decomposition, the building
blocks, the storage, the contracts, the authentication mechanism, how the code is written. Solution decisions are
supposed to be driven by problem facts. Today the workshop asks a structural question before the quality attributes
that should drive it, the order itself is defined in four places that disagree, and nothing checks whether a later
lens changed what an earlier one decided.

### Evidence (main at `dd204c5c`, unless noted)

- **architecture-core runs before requirements-nfr.** The workshop skill lists the lenses as `architecture-core`,
  `component-design`, `requirements-nfr`, ... (`extensions/specrew-speckit/squad-templates/skills/design-workshop.md:24`).
  architecture-core asks "Which design method / decomposition style governs the structure", "What are the major
  building blocks" and "Which areas are volatile and should be isolated"
  (`extensions/specrew-speckit/knowledge/design-lenses/architecture-core.md:25-31`). requirements-nfr, one lens later,
  asks "Which NFRs are design drivers for this slice?" and "Which requirements need a measurable threshold?"
  (`requirements-nfr.md:25-27`). The structure is chosen before its drivers are known.
- **The system's own metadata already places structure later.** `index.yml` gives architecture-core and
  component-design `default_phase: design-analysis`, and requirements-nfr, ui-ux and security-compliance
  `specify-clarify-design-analysis` (`knowledge/design-lenses/index.yml:12,18,31,49,62`). The skill's Method step 1
  says the workshop "*gathers* inputs and constraints; the system **structure** ... is designed *with* them at the
  design-analysis step - not decided in intake" (`design-workshop.md:178-180`). The methodology says the workshop is
  used in two places, intake and the design-analysis stop (`docs/methodology/design-workshop-methodology.md:37-42`).
  The agenda then runs the structural lens first, in intake.
- **The order is defined four times, and no two agree.**

  | Source | Order after product-domain |
  |---|---|
  | Workshop skill (`design-workshop.md:24-25`) | architecture-core, component-design, requirements-nfr, ui-ux, data-storage, security-compliance, integration-api, devops-operations, observability-resilience, code-implementation |
  | Lens catalog (`index.yml`) | architecture-core, requirements-nfr, data-storage, ui-ux, devops-operations, integration-api, security-compliance, observability-resilience, component-design, code-implementation |
  | Methodology, Band 2 (`design-workshop-methodology.md:182-190`) | architecture-core, component-design, requirements-nfr, ui-ux, data-storage, security-compliance, integration-api, devops-operations, observability-resilience |
  | Feature 203's confirmed agenda (`specs/203-beta5-stabilization/lens-applicability.json`, branch `203-beta5-stabilization` at `524da54c`) | architecture-core, requirements-nfr, ui-ux, security-compliance, devops-operations, observability-resilience, code-implementation |

- **Two lenses ask the same question.** architecture-core: "Which constraints are binding, and which are
  preferences?" (`architecture-core.md:32`). requirements-nfr: "Which constraints are mandatory rather than
  preferences?" (`requirements-nfr.md:26`). architecture-core also owns "What is deliberately out of scope"
  (`architecture-core.md:33`), a problem-space question.
- **Several lenses mix both spaces in one list.** security-compliance asks what data is sensitive and which actions
  need audit records (problem) beside who authenticates and which authorization model applies (solution)
  (`security-compliance.md:24-29`). ui-ux asks for the primary user journeys (problem) beside whether data
  operations are client-side, server-side or streamed (solution) (`ui-ux.md:27-28`). data-storage, integration-api
  and devops-operations have the same shape.
- **A later lens cannot amend an earlier one.** The skill asks the crew to record cross-lens decisions in a
  `bindings` object and says "the controller stops on a conflict before the workshop can finish"
  (`design-workshop.md:408-410`); `Test-SpecrewWorkshopDecisionBindings`
  (`scripts/internal/bootstrap/ProjectMetadataAccessor.ps1`) returns `workshop-decision-binding-conflict`. A conflict
  is a dead stop, with no governed way to reopen the earlier lens and amend its decision. An influence that is not
  encoded as a binding is not caught at all, and no step looks at the decisions together before the spec is written.

## What

### Maintainer decisions (2026-11-09)

1. Change the order: the problem-space lenses first, the solution-space lenses after them.
2. At the end of every lens, check whether it influenced a lens already passed.
3. At the end, run a final sweep.

### Proposed details (open for clarify)

The rest of this section is the proposed shape of those three decisions. Where it goes beyond them (the second
sweep, the section split, the amendment record) it is marked as proposed, and the open questions below list it.

#### 1. One order, from one source

`knowledge/design-lenses/index.yml` becomes the only definition of the order. The skill, the methodology, the agenda
writer and the deployed copies read it or are checked against it; none keeps its own list.

**Problem space** (intake, before `speckit-specify` writes the spec):

1. `product-domain` - users, pain, MVP, non-goals (unchanged; already first).
2. `requirements-nfr` - quality attributes and their priority, measurable thresholds, binding constraints versus
   preferences, and scope. It takes over architecture-core's "binding constraints" and "out of scope" questions, so
   the duplicate disappears.
3. The problem sections of the applicable lenses: personas and journeys (ui-ux); sensitive data, regulation and
   audit obligations (security-compliance); data ownership, retention and migration obligations (data-storage);
   outside systems and contracts that must be honoured (integration-api); where it must run and who operates it
   (devops-operations).

**Solution space** (the design-analysis stop, after specify and clarify):

1. `architecture-core` - decomposition style, building blocks, volatility, now driven by the recorded NFRs and
   constraints.
2. `component-design` - responsibilities, coupling, dependency direction, seams.
3. The solution sections of the applicable lenses: storage and consistency, contracts and protocols, the identity
   and authorization mechanism, interaction design and state, hosting and rollout.
4. `observability-resilience`.
5. `code-implementation`, last, as today. (Proposal 214's skills lens, when it ships, stays after it.)

**Proposed:** each lens keeps its id and file and gains two tagged sections, `## Problem questions` and
`## Solution questions`, instead of being split into two files. A lens selected at intake is preselected for its
solution pass at design-analysis, where the human confirms or adjusts it. A lens with questions in only one space
says so.

**Loop-back stays allowed.** Real design moves between the spaces. A solution fact that is fixed from outside - an
existing system, a mandated technology, a platform already chosen - is recorded as a problem-space constraint, as
product-domain already permits ("whether a technology is already externally fixed as a constraint").

#### 2. A back-check at the end of every lens

When a lens is confirmed, before the next one opens, the crew checks every earlier confirmed lens, in both spaces,
for four kinds of influence: the new decision **contradicts** an earlier one, makes it **moot**, **adds a
constraint** it did not account for, or **changes a threshold** it relied on.

- **No influence:** one line naming the lenses checked. No question is asked, so a lens with no influence costs the
  human no extra turn.
- **Influence found:** the crew renders each affected lens, its recorded decision, the influence, and the proposed
  amendment. The human approves, adjusts or rejects it with a typed reply, which gets a receipt like any lens
  confirmation.
- **Proposed record:** the amendment is appended to the earlier lens's record (`amendments[]`: the amending lens,
  the change, the reason, the human's receipt). The original decision and its receipt are kept. A receipt is never
  rewritten or invalidated silently.
- **Bindings:** a `bindings` conflict enters this flow instead of stopping the workshop dead. An unresolved
  conflict still blocks the workshop from finishing.

#### 3. The final sweep

**Proposed: twice**, because the order now spans two stops.

- **Before the spec is written** (end of the problem space): all problem-space decisions together. It looks for
  contradictions across lenses, constraints that no requirement reflects, requirements that need a measurable
  threshold and have none, open "decide later" items, and unresolved bindings. Each finding becomes an amendment
  (section 2) or a recorded clarify question. The sweep's result is rendered to the human before specify runs.
- **At the end of design-analysis** (end of the solution space): every solution decision traces to an NFR, a
  constraint or a requirement. An untraced decision is flagged. A design that forces a change to the spec goes back
  through clarify; it is never edited into the spec silently. A problem-space lens amended here goes through
  section 2's flow as well.

### Functional requirements

- **FR-001**: `index.yml` MUST be the only definition of the lens order and of each lens's space. A test MUST fail
  when the skill, the methodology, the agenda writer or any deployed copy lists a different order.
- **FR-002**: The intake workshop MUST run product-domain, then requirements-nfr, then the problem sections of the
  applicable lenses, before `speckit-specify` writes the spec.
- **FR-003**: The design-analysis stop MUST run architecture-core, component-design, the solution sections of the
  applicable lenses, observability-resilience, then code-implementation.
- **FR-004**: requirements-nfr MUST own the binding-constraint and scope questions; architecture-core MUST NOT ask
  them.
- **FR-005**: Each lens file MUST mark its problem questions and its solution questions; a lens with questions in
  only one space MUST say so.
- **FR-006**: After each lens is confirmed, the crew MUST check every earlier confirmed lens for contradiction,
  mootness, a new constraint, or a changed threshold, and MUST record the check in the lens record (lenses checked,
  influences found).
- **FR-007**: A back-check that finds no influence MUST render one line and MUST NOT ask the human a question.
- **FR-008**: A back-check that finds an influence MUST render the affected lens, its recorded decision and the
  proposed amendment, and MUST record an amendment only on the human's typed reply, with its receipt. The original
  decision and its receipt MUST be preserved.
- **FR-009**: A `bindings` conflict MUST enter the FR-008 flow; an unresolved conflict MUST still block the workshop
  from finishing.
- **FR-010**: Before the spec is written, a final sweep MUST check the problem-space decisions together for
  contradictions, unreflected constraints, missing measurable thresholds, open "decide later" items and unresolved
  bindings, and MUST render its result to the human.
- **FR-011**: At the end of design-analysis, a final sweep MUST check that every solution decision traces to an NFR,
  constraint or requirement; a design that forces a spec change MUST route through clarify.
- **FR-012**: An externally fixed solution fact MUST be recordable as a problem-space constraint.
- **FR-013**: Features past their workshop MUST be unaffected. A feature mid-workshop MUST keep its confirmed agenda
  and order. The new order applies to agendas confirmed after this ships.
- **FR-014**: Evidence MUST include scripted workshop fixtures in which (a) lens N changes a constraint lens M relied
  on and the back-check catches it; (b) two lenses contradict without a binding and the final sweep catches it;
  (c) a lens with no influence adds no human turn.

### Out of scope

- The product-level and feature-level workshop split (Proposal 162). This proposal works within today's per-feature
  workshop and composes with 162 when it ships.
- New lenses, or new questions beyond moving architecture-core's two problem questions to requirements-nfr and
  tagging each lens's existing questions by space.
- Detecting influence automatically beyond `bindings`. The back-check is the crew's judgment, confirmed by the
  human; the final sweeps and the fixtures are the backstop.

## Effort

- **Iteration 1 (~10-15 SP)**: `index.yml` as the single order with a space tag per lens; problem and solution
  sections in every lens file; architecture-core's constraint and scope questions moved to requirements-nfr; the
  skill and the methodology updated to read the one order; the order-parity test (FR-001); migration (FR-013).
- **Iteration 2 (~10-15 SP)**: the end-of-lens back-check and its record; the amendment record and the
  `bindings` flow; both final sweeps; the evidence fixtures (FR-014).
- **Total**: ~20-30 SP.

## Phase placement

Phase 2, Tier 2 methodology quality, beside 210 and 214, which also change how the workshop runs. Iteration 1 is
independent and small; iteration 2 builds on the workshop authority records (`workshop-authority.jsonl` receipts)
that already exist. Not inside Feature 203.

## Open questions

1. Two sweeps or one? The maintainer asked for "a final sweep"; this proposal recommends one at each stop, because
   the order now spans intake and design-analysis.
2. Two tagged sections per lens file, or separate problem and solution lens files? This proposal recommends
   sections. Can a lens's solution pass be deselected at design-analysis when its problem pass ran at intake?
3. Should the intake sweep be enforced by the specify gate (as the product-domain record is today), or stay
   workshop conduct with the record as evidence?
4. Where does an amendment to a problem-space lens found at design-analysis land once the spec exists: the lens
   record plus a clarify question, or, after Proposal 216, a spec amendment?
5. Does the back-check scale with lens depth, for example a one-line check for a Light lens and a per-lens
   comparison for a Deep one?
6. A session resumed mid-workshop must know whether a back-check is pending. Is that part of the existing lens
   checkpoint, or a separate field?
7. Should every constraint and threshold be encoded as a `binding`, so more influences are caught deterministically?

## Risks

- **More turns, more fatigue.** Mitigation: FR-007 makes a no-influence back-check silent apart from one line; the
  sweeps render one list each.
- **The crew misses an influence.** The back-check is judgment. Mitigation: `bindings` stay deterministic, the two
  sweeps look at all decisions together, and the FR-014 fixtures prove both catch the cases they are for.
- **The order drifts again.** Mitigation: FR-001's parity test fails on any second definition.
- **Record-shape changes break existing workshop records or the SC-021 floor** (`scripts/internal/design-analysis-gate.ps1`).
  Mitigation: new fields are optional and marker-gated, following the gate's existing grandfather pattern.
- **A design that reaches back into the spec is resisted as friction.** Mitigation: routing through clarify is the
  existing path; this proposal only makes it explicit instead of silent.

## Cross-references

- Related proposals: 162 (two-tier product-then-feature workshop), 210 (search-before-create, injects into the
  workshop), 214 (skills lens, runs after code-implementation), 216 (temporal spec model, for spec amendments),
  212 (reading validation at human gates).
- Shipped features: 176 (product-domain first stage), 177 (code-implementation lens).
- Source artifacts: `extensions/specrew-speckit/squad-templates/skills/design-workshop.md`,
  `extensions/specrew-speckit/knowledge/design-lenses/`, `docs/methodology/design-workshop-methodology.md`,
  `scripts/internal/design-analysis-gate.ps1`, `scripts/internal/bootstrap/ProjectMetadataAccessor.ps1`.

## Status history

- 2026-11-09: drafted as `draft` from the maintainer's ruling on the lens order, the end-of-lens back-check and the
  final sweep. Items beyond those three decisions are marked as proposed and listed as open questions.
