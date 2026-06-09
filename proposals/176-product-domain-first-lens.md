---
proposal: 176
title: Product & Problem Domain Lens (first workshop lens)
status: candidate
phase: phase-2
estimated-sp: 6-10
priority-tier: 2
discussion: surfaced 2026-06-09 by the maintainer after observing that the design workshop still starts too close to solution/design decisions. The missing first lens is the product/problem-domain lens: who the users and stakeholders are, what pain is being solved, what system/context exists today, what constraints apply, what MVP means, what the longer vision is, and what alternatives/competitors shape the decision. Web research on product discovery, service discovery, product-vision, design-sprint, opportunity-tree, and competitive-analysis patterns confirmed this should be a pre-technical grounding lens that runs before the existing design lens applicability selection.
---

# Product & Problem Domain Lens (first workshop lens)

## Why

The current Specrew design lenses start too close to the solution. They help the
Crew decide architecture, data, integration, security, observability, UI,
components, and implementation craft, but they do not force the first product
conversation:

- Who is this for?
- Who cares besides the direct user?
- What pain, opportunity, or job is being addressed?
- What happens today without this product or feature?
- What existing system is being changed, extended, or replaced?
- What constraints shape the solution before technical design starts?
- What is the MVP, what is deliberately out of scope, and what is the longer
  product vision?
- What alternatives, competitors, or current workarounds does the solution need
  to beat?

That gap lets the Crew treat a solution request as sufficient context. It may
build the requested thing while never grounding the problem, user, stakeholder,
business/process context, or adoption path. The result can be technically
correct but product-wrong: good requirements for the wrong problem.

The research baseline points the same way:

- service/product discovery should understand users, policy/business intent,
  constraints, existing services, and whether to proceed before delivery;
- product vision tools separate target users, needs, product value, and business
  goals;
- project/poster and design-sprint patterns expose the problem, assumptions,
  possible solutions, validation, and decision points before implementation;
- opportunity-tree style product discovery connects desired outcomes to user
  opportunities, candidate solutions, and experiments;
- competitive analysis and business-model tools add alternatives,
  differentiation, cost/revenue, channels, and adoption context.

Specrew needs this as the **first workshop lens**, not as another technical lens
after architecture has already started.

## What

Add a required first design-workshop lens with working id `product-domain`.

This lens runs before the existing lens applicability selector. It answers:

1. What product/problem context is known?
2. What is unknown and must be confirmed with the human?
3. Which existing lenses should be activated because of the product context?
4. Which assumptions are accepted for now, and what evidence level backs them?
5. What product-domain facts must be carried into `spec.md`, `plan.md`,
   `tasks.md`, review, and later variance disclosure?

The lens is mandatory, but depth is adaptive. Even a tiny feature gets a light
pass that records why deeper product discovery is not warranted.

## Lens decision areas

### 1. Users, customers, and stakeholders

Capture distinct roles, not a single generic "user":

- direct users;
- buyers, sponsors, and budget owners;
- administrators, operators, support, auditors, compliance reviewers;
- internal teams or external partners affected by the product;
- people harmed by bad output, downtime, data loss, or confusing behavior.

The lens should explicitly separate **user**, **customer/buyer**, **operator**,
and **stakeholder** when those roles differ.

### 2. Pain, jobs, and current workaround

Capture the problem in product terms:

- the pain, opportunity, job-to-be-done, or operational gap;
- what users do today without the product or feature;
- what breaks, takes too long, costs too much, causes risk, or creates support
  load;
- the cost of doing nothing.

### 3. Existing system and context

Record whether this is:

- a new product;
- an extension to an existing product;
- a replacement for an existing system;
- an integration into a broader ecosystem;
- a migration, modernization, automation, or process change.

The lens should produce a small context map when useful: surrounding systems,
humans, data sources, channels, integrations, and ownership boundaries.

### 4. Constraints

Capture constraints before technical choices:

- budget/capex/opex;
- schedule and deadline pressure;
- staffing and support model;
- technology/platform constraints;
- procurement, licensing, and vendor constraints;
- data residency, privacy, security, regulatory, and compliance constraints;
- deployment, operations, and support constraints;
- organizational/process constraints.

### 5. Outcomes and success metrics

Record intended outcomes in measurable terms where possible:

- user outcome;
- business/process outcome;
- operational outcome;
- quality/outcome metric;
- leading indicator for MVP;
- longer-term success signal.

This is not a replacement for requirements/NFR. It is the reason the
requirements matter.

### 6. MVP, non-goals, and vision

Capture:

- MVP: smallest valuable product/feature slice;
- non-goals and explicit out of scope;
- later vision and likely expansion path;
- what must remain easy to change later;
- what would make the first version a failure even if it works technically.

### 7. Alternatives, competitors, and differentiation

Capture the competitive or alternative landscape:

- direct competitors;
- internal alternatives;
- manual workflows and spreadsheets;
- existing tools users already have;
- build-vs-buy options;
- why this solution should exist;
- which dimension must be better: cost, speed, usability, reliability,
  integration, automation, trust, accuracy, compliance, or ownership.

For internal tools, "competitor" often means current workaround or existing
enterprise platform, not a commercial market rival.

### 8. Adoption, rollout, and change impact

Capture:

- pilot/beta/rollout plan;
- migration needs;
- training and documentation needs;
- backwards compatibility;
- support handoff;
- adoption risk and incentives.

### 9. Evidence quality and assumptions

Every material product-domain statement should be tagged:

- `known`: backed by user/maintainer input, existing artifact, analytics, or
  production evidence;
- `assumed`: reasonable but not verified;
- `unknown`: not yet known; user explicitly accepted proceeding with the gap;
- `research-needed`: must be researched before plan or before implementation.

This prevents confident product fiction.

## Depth model

### Light

Use for tiny utilities, spikes, personal tools, or narrow bug fixes.

Required output:

- user/stakeholder;
- pain/job;
- MVP;
- out of scope;
- key constraints;
- why deeper discovery is not needed.

### Standard

Use for normal product features.

Includes Light plus:

- current workaround;
- existing system/context;
- success metrics;
- assumptions/evidence quality;
- adoption/rollout notes;
- alternatives/competitors.

### Deep

Use for new products, major workflow changes, regulated/high-risk domains,
multi-team systems, migrations, commercial products, or unclear business
strategy.

Includes Standard plus:

- stakeholder map;
- context diagram;
- competitive landscape;
- business model or value model;
- migration/change-management strategy;
- validation/research plan;
- evidence gaps that block plan or implementation.

## Artifacts

The result should not live only as scattered prose in `spec.md`.

MVP artifact set:

- `specs/<feature>/workshop/product-domain.md` - human-readable product-domain
  record for the feature;
- `specs/<feature>/workshop/product-domain.yml` - structured record of the
  selected depth, answers, assumptions, evidence tags, skipped areas, and
  follow-up research;
- `spec.md` - concise summary of product-domain decisions, not the sole source;
- Proposal 156 `workshop-decisions.yml` - canonical selected/skipped/deferred
  decision stream consumed by plan, implement, review, Proposal 145 conformance,
  and Proposal 174 variance reconciliation.

When Proposal 162 is active, product-level answers should be persisted once in a
project-level artifact such as:

- `.specrew/product-domain.md`;
- `.specrew/product-domain.yml`.

Per-feature product-domain workshops then inherit the product-level context and
record only feature-specific deltas, contradictions, or updates.

## Conduct rules

- The lens cannot be satisfied by approving an agenda or by a batch "confirm all
  lenses" answer. It needs scoped product-domain confirmation or explicit
  scoped "not applicable" evidence.
- A solution-first user request must be reframed into the problem and product
  context before the Crew proceeds to design.
- Unknowns may be accepted only when the Crew states the gap and the human
  approves proceeding with that assumption.
- If the lens discovers that the requested feature is not aligned to the pain,
  MVP, constraints, or competitive landscape, the Crew must surface that before
  plan.
- Later-stage changes to product-domain assumptions are handled through
  Proposal 174 variance disclosure and artifact reconciliation.

## Applicability

`product-domain` is always applicable, with adaptive depth.

Examples:

- Tiny personal CLI: Light.
- Internal team automation: Light or Standard, depending on users/workflow risk.
- SaaS feature: Standard.
- New product, replacement system, regulated workflow, commercial launch,
  multi-team platform, migration, or cloud/provider selection: Deep.
- Existing product with Proposal 162 product context: inherited product-domain
  plus feature delta.

## Functional requirements for the eventual feature

- **FR-001**: The workshop SHALL run `product-domain` before technical lens
  applicability selection.
- **FR-002**: The workshop SHALL choose Light/Standard/Deep depth and record why.
- **FR-003**: The workshop SHALL capture users, stakeholders, pain/job, current
  workaround or existing system, constraints, MVP/non-goals/vision, outcomes,
  and alternatives at the selected depth.
- **FR-004**: The workshop SHALL tag material product-domain statements with
  evidence quality (`known`, `assumed`, `unknown`, `research-needed`).
- **FR-005**: The workshop SHALL persist a human-readable product-domain record
  and a structured product-domain record for the feature.
- **FR-006**: `spec.md` SHALL summarize the product-domain decisions without
  becoming the only source of truth.
- **FR-007**: The structured product-domain decisions SHALL feed Proposal 156
  `workshop-decisions.yml` so Proposal 145 can verify selected decisions and
  Proposal 174 can reconcile later variance.
- **FR-008**: When Proposal 162 product-level context exists, the feature-level
  product-domain lens SHALL inherit it and record only deltas, contradictions,
  or accepted updates.
- **FR-009**: Batch approval of the lens agenda SHALL NOT count as
  product-domain confirmation.

## Out of scope

- Replacing requirements/NFR, architecture, or component design.
- Building a full product-management suite.
- Requiring heavy discovery for trivial utilities.
- Making competitive analysis mandatory for every small internal tool.
- Replacing Proposal 162's two-tier product/app workshop structure.
- Replacing Proposal 175's supplemental domain/platform analysis packs.

## Composition map

- [[156-design-analysis-lens-knowledge-catalog]] - adds `product-domain` to the
  lens catalog and emits structured decisions into `workshop-decisions.yml`.
- [[162-two-tier-product-then-feature-workshop]] - product-domain becomes part
  of the product-level context that later features inherit.
- [[163-code-implementation-lens]] - implementation craft should be selected in
  service of the product-domain constraints and outcomes, not independently.
- [[164-risk-assessment-mitigation-workshop]] - product-domain failure modes
  seed the risk register.
- [[174-boundary-variance-disclosure]] - later changes to product-domain
  assumptions must be disclosed and reconciled at gates.
- [[175-supplemental-domain-platform-analysis-packs]] - product-domain context
  helps decide which supplemental packs apply.
- [[145-structured-multi-phase-reviewer]] - verifies that selected
  product-domain decisions were carried into spec/plan/tasks/review evidence.

## Research anchors

Research checked 2026-06-09.

- GOV.UK Service Manual - discovery phase:
  <https://www.gov.uk/service-manual/agile-delivery/how-the-discovery-phase-works>
- U.S. Digital.gov - discovery operations guide:
  <https://digital.gov/guides/discovery-operations/>
- Roman Pichler - Product Vision Board:
  <https://www.romanpichler.com/tools/product-vision-board/>
- Atlassian Team Playbook - Project Poster:
  <https://www.atlassian.com/team-playbook/plays/project-poster>
- GV - The Design Sprint:
  <https://www.gv.com/sprint/>
- Product Talk - Opportunity Solution Tree:
  <https://www.producttalk.org/opportunity-solution-tree/>
- Strategyzer - Business Model Canvas:
  <https://www.strategyzer.com/library/the-business-model-canvas>
- Aha! - Competitive analysis:
  <https://www.aha.io/roadmapping/guide/product-strategy/competitive-analysis>

## Sizing

- **MVP (~6-10 SP)**:
  - lens file + catalog registration + applicability ordering (~2 SP);
  - prompt/conduct updates for first-lens behavior and no-batch-confirmation
    evidence (~1-2 SP);
  - feature-level `product-domain.md` / `product-domain.yml` artifact writer
    (~1-2 SP);
  - `workshop-decisions.yml` integration (~1-2 SP);
  - tests for light/standard/deep selection, artifact persistence,
    evidence-tagging, and agenda-approval non-equivalence (~1-2 SP).
- Product-level persistence under Proposal 162 can ship as a follow-up or be
  bundled if 162 is active.

## Open questions

- Should the lens id be `product-domain`, `problem-domain`, or
  `product-context`?
- Should feature artifacts live under `workshop/` or directly at
  `specs/<feature>/product-domain.md`?
- Should Light depth still ask competitive/alternative questions, or only
  record current workaround/out-of-scope?
- Should `research-needed` assumptions block plan by default, or only when they
  affect feasibility/MVP/major cost/risk?
- Should a first feature in a new repo automatically offer to promote its
  product-domain record into the Proposal 162 product-level artifact?

## Risks

- **Workshop bloat**: product discovery can become too large. Mitigation:
  adaptive depth and explicit skip reasons.
- **False certainty**: the Crew may invent market/user facts. Mitigation:
  evidence tags and human confirmation.
- **Duplicate requirements**: product-domain can overlap `spec.md`. Mitigation:
  product-domain records why/context; `spec.md` records user stories,
  requirements, and success criteria.
- **Internal-tool mismatch**: competitive analysis can sound irrelevant.
  Mitigation: alternatives include workarounds, spreadsheets, existing internal
  systems, and build-vs-buy.
- **Stale product context**: product assumptions change. Mitigation: Proposal
  174 variance disclosure and Proposal 162 re-openable product context.

## Status history

- 2026-06-09: Candidate created after maintainer identified the missing first
  workshop lens: product/problem-domain grounding before any technical design
  lenses.
