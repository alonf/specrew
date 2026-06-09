# Feature Specification: Product & Problem Domain Lens (first workshop lens)

**Feature Branch**: `176-product-domain-lens`
**Created**: 2026-06-09
**Status**: Draft
**Input**: Implement Proposal 176 — add a required first design-workshop lens (`product-domain`) that grounds product/problem context before technical lens selection. Source: `proposals/176-product-domain-first-lens.md`.

## Summary

Specrew's design lenses (architecture, data, ui-ux, security, integration, devops,
requirements/NFR, observability, component) all start close to the solution. None
forces the first *product* conversation: who the feature is for, what pain it
addresses, what exists today, what constraints apply, what the MVP and non-goals
are, and what alternatives it must beat. That gap lets the Crew treat a solution
request as sufficient context and build something technically correct but
product-wrong.

This feature adds a required first design-workshop lens, working id
`product-domain`, that runs **before** the existing technical-lens applicability
selector. It captures product/problem context at an adaptive depth
(Light / Standard / Deep), tags every material statement with an evidence quality,
persists a human-readable and a structured record, summarizes the decisions into
`spec.md`, and is enforced at the specify boundary so the grounding cannot be
skipped or satisfied by a batch "confirm all" answer.

### Locked intake decisions

- **Enforcement**: extend the existing specify-boundary gate to require the
  product-domain record with the SC-026-style `confirmation` / `confirmation_scope`
  provenance, reusing the proven floor that already rejects batch approval. No
  parallel validator subsystem.
- **`research-needed` blocking**: a `research-needed` evidence tag blocks the plan
  boundary only when it is load-bearing (affects feasibility, MVP scope, or major
  cost/risk); otherwise it is recorded and carried forward.

### Deferred by dependency reality (not by choice)

- **FR-007 (Proposal 156 `workshop-decisions.yml`)** — that artifact does not exist
  on disk. The structured `product-domain.yml` is designed *forward-compatible* with
  156's consumer shape, so wiring it later is a connection, not a redesign.
- **FR-008 (Proposal 162 product-level inheritance)** — the two-tier product-level
  context does not exist on disk. The lens records feature-only context now and is
  shaped to accept inherited product-level context later.

### Out of scope

- Replacing requirements/NFR, architecture, or component design.
- Building a full product-management suite.
- Requiring heavy discovery for trivial utilities (adaptive depth + explicit skip
  reasons prevent this).
- Mandatory competitive analysis for every small internal tool.
- The mechanical slot-in itself — whether `product-domain` becomes a new first-stage
  workshop phase ahead of the selector or a row in `applicability-map.json` — is a
  design-analysis decision; this spec stays behavioral.

## Clarifications

### Session 2026-06-09

- **Resolved in the intake design workshop (approved at the specify verdict):** the
  enforcement model (extend the existing specify-gate with SC-026 provenance, not
  conduct-only prose — FR-010); `research-needed` blocking (conditional, load-bearing
  gaps only — FR-011); the lens id (`product-domain`); the per-feature artifact location
  (`specs/<feature>/workshop/` — FR-005); and the build decomposition (the human-confirmed
  component map in `lens-applicability.json` + `workshop/component-design.md`).
- **Carried as the approve-with-instructions verdict:** the multi-host deploy wording
  distinguishes the five supported hosts (Claude, Copilot/GitHub, Codex/Agents, Cursor,
  Antigravity) from the four on-disk managed-skill surfaces; Antigravity is supported,
  not excluded (FR-013, SC-007).
- **Q — Does Light depth ask competitive/alternative questions?** **A (default):** No.
  Light depth captures the current workaround and out-of-scope but does not require
  competitive/alternative analysis — that lives in Standard/Deep. This matches the
  proposal's depth model and the "no mandatory competitive analysis for small internal
  tools" out-of-scope line (now reflected in FR-003).
- **Sizing:** single iteration; proposal estimate 6-10 SP; capacity planning confirms at
  plan time (maintainer-approved).
- **No remaining material ambiguities** require a human clarify question — the interactive
  workshop already resolved the open design questions, so this clarify pass records
  resolutions rather than opening new ones (clarify discipline #3).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Product-first grounding before any technical lens (Priority: P1)

As the Crew coordinator starting a feature, before I select or work any technical
design lens, I run the `product-domain` lens: I choose an adaptive depth and record
why, capture the product/problem context (users and stakeholders, pain/job and
current workaround, existing system/context, constraints, outcomes, MVP/non-goals/
vision, and alternatives) at that depth, tag every material statement with an
evidence quality, and persist both a human-readable and a structured record. A
solution-first request is reframed into the problem and product context first.

**Why this priority**: This is the feature. Without the first product conversation,
every later lens can be technically sound and still solve the wrong problem.

**Independent Test**: Run a feature intake; confirm a product-domain record is
produced before the applicability questionnaire is answered, declares a depth with a
reason, captures the depth-appropriate decision areas, and carries evidence tags on
material statements.

**Acceptance Scenarios**:

1. **Given** a new feature intake, **When** the workshop begins, **Then** the
   `product-domain` lens runs and produces its record before any technical-lens
   applicability question is answered.
2. **Given** a tiny utility, **When** the lens runs, **Then** it selects Light depth,
   records why deeper discovery is not warranted, and still captures user/stakeholder,
   pain/job, MVP, out-of-scope, and key constraints.
3. **Given** a solution-first request ("build X"), **When** the lens runs, **Then**
   the Crew reframes it into the problem/product context before proceeding to design.
4. **Given** a material product statement the Crew cannot verify, **When** it is
   recorded, **Then** it is tagged `assumed`, `unknown`, or `research-needed` rather
   than stated as fact.

### User Story 2 - The grounding cannot be skipped or faked at the gate (Priority: P2)

As a maintainer reviewing a spec, I rely on the specify boundary refusing to advance
unless a genuine product-domain record exists with honest confirmation provenance. A
batch / agenda-level "confirm all" must not count as product-domain confirmation, and
a missing or malformed record must block the boundary.

**Why this priority**: Specrew's own history shows prose-only conduct is skimmed or
collapsed on some hosts; the deterministic floor is what makes the grounding real.

**Independent Test**: Present a product-domain record whose confirmation is a batch
approval and confirm the specify gate fails; present a genuine `human-confirmed` /
`lens-question` record and confirm it passes.

**Acceptance Scenarios**:

1. **Given** no product-domain record, **When** the specify gate runs, **Then** it
   fails with a clear reason.
2. **Given** a record whose `confirmation_scope` is a batch/agenda approval, **When**
   the gate runs, **Then** it fails (FR-009 enforced).
3. **Given** a `research-needed` statement flagged load-bearing (feasibility/MVP/
   cost/risk), **When** the plan boundary is attempted, **Then** it is blocked until
   researched or explicitly accepted.
4. **Given** a `research-needed` statement that is not load-bearing, **When** the plan
   boundary is attempted, **Then** it advances with the gap recorded.

### User Story 3 - Consistent across hosts and forward-compatible (Priority: P3)

As an adopter on any supported host, the product-domain conduct behaves identically
across the host-managed skill surfaces, and the structured record is shaped so that
the later Proposal 156 and Proposal 162 wiring connects without redesign.

**Why this priority**: Multi-host parity and forward-compatibility protect the
investment and prevent drift, but they do not block the core grounding behavior.

**Independent Test**: Diff the conduct across the host skill copies (parity holds);
validate `product-domain.yml` against the documented 156-forward-compatible shape.

**Acceptance Scenarios**:

1. **Given** the managed skill surfaces of the supported hosts (four physical locations
   on disk today), **When** the conduct is compared, **Then** the product-domain conduct
   is identical (drift fails the parity check).
2. **Given** a completed `product-domain.yml`, **When** it is validated against the
   documented forward-compatible shape, **Then** it conforms (so 156 can consume it
   later).

### Edge Cases

- A feature whose request is purely a solution ("add a button") with no stated
  problem — the lens must still extract or solicit the pain/job before design.
- A feature where the human explicitly delegates or skips the lens — recorded honestly
  as `human-delegated` / `explicit-delegation` or `human-skipped` / `explicit-skip`,
  never a fabricated agreement.
- A `research-needed` gap whose load-bearing status is itself unclear — default to
  treating it as load-bearing (block) until the human rules otherwise.
- The lens catalog or skill copy is absent on a host — graceful degradation, surfaced,
  never a silent skip of the grounding.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The workshop MUST run the `product-domain` lens before technical-lens
  applicability selection. Owner: Planner/Implementer. Window: Iteration 001.
- **FR-002**: The lens MUST choose a depth (Light / Standard / Deep) based on risk and
  novelty, and record why. Depth-selection rules: new product / unclear product context /
  major pivot / new user segment / new workflow / migration or replacement / regulated or
  high-risk area → Standard or Deep; later feature in a known product → Light (or Delta once
  Proposal 162 ships); tiny bug fix or narrow internal utility → Light. Owner: Implementer.
  Window: Iteration 001.
- **FR-003**: The lens MUST capture, at the selected depth, the product/problem
  context: users and stakeholders (separating user / customer-buyer / operator /
  stakeholder when they differ), pain/job and current workaround or existing system,
  constraints, MVP / non-goals / vision, intended outcomes, and — at Standard/Deep
  depth — alternatives / competitors; Light depth records the current workaround and
  out-of-scope without requiring competitive analysis. Owner: Implementer.
  Window: Iteration 001.
- **FR-004**: The lens MUST tag material product-domain statements with an evidence
  quality from {`known`, `assumed`, `unknown`, `research-needed`}. Owner: Implementer.
  Window: Iteration 001.
- **FR-005**: The lens MUST persist a human-readable record
  (`specs/<feature>/workshop/product-domain.md`) and a structured record
  (`specs/<feature>/workshop/product-domain.yml`) recording depth, answers,
  assumptions, evidence tags, skipped areas, and follow-up research. Owner:
  Implementer. Window: Iteration 001.
- **FR-006**: `spec.md` MUST summarize the product-domain decisions without becoming
  the sole source of truth. Owner: Spec Steward. Window: Iteration 001.
- **FR-007**: The structured product-domain record MUST be forward-compatible with the
  Proposal 156 `workshop-decisions.yml` consumer shape. *Actual emission into
  `workshop-decisions.yml` is DEFERRED because 156 is unshipped; the record's shape is
  built and schema-tested now so the later wiring is a connection.* Owner: Implementer.
  Window: Iteration 001 (shape only).
- **FR-008**: When Proposal 162 product-level context exists, the feature-level
  product-domain lens MUST inherit it and record only deltas, contradictions, or
  accepted updates. *DEFERRED because 162 is unshipped; the lens records feature-only
  context now and is shaped to accept inherited context later.* The structured record
  MUST carry a stable optional `product_id` / `product_context_ref` field as the
  forward-compatible inheritance hook (shape only, schema-validated; no inheritance
  behavior built now). Owner: Implementer. Window: deferred (post-162), hook this iteration.
- **FR-009**: Batch approval of the lens agenda MUST NOT count as product-domain
  confirmation. Owner: Reviewer/Implementer. Window: Iteration 001.
- **FR-010**: The specify-boundary gate MUST require a valid product-domain record —
  present, depth + reason recorded, material statements evidence-tagged, and carrying a
  `confirmation` provenance (`human-confirmed | human-delegated | human-skipped`) with a
  matching `confirmation_scope` (`lens-question | explicit-delegation | explicit-skip`),
  reusing the existing SC-026 floor — and MUST reject a record whose provenance is a
  batch/agenda approval. Owner: Implementer/Reviewer. Window: Iteration 001.
- **FR-011**: A `research-needed` evidence tag MUST block the plan boundary only when it
  is flagged load-bearing (affects feasibility, MVP scope, or major cost/risk); a
  non-load-bearing `research-needed` tag MUST be recorded and carried, not block. Owner:
  Implementer. Window: Iteration 001.
- **FR-012**: The lens conduct MUST reframe a solution-first request into the problem/
  product context before design proceeds, and MUST surface — before plan — any
  discovery that the requested feature is not aligned to the pain, MVP, constraints, or
  alternatives. Owner: Spec Steward/Reviewer. Window: Iteration 001.
- **FR-013**: The product-domain conduct change MUST deploy to the host-managed skill
  surfaces used by all supported hosts — Claude, Copilot/GitHub, Codex/Agents, Cursor,
  and Antigravity, as applicable — through the managed-skill deploy path, and a
  host-parity check MUST guard the surfaces against drift. The current on-disk
  managed-skill surfaces are four physical locations (`.claude/skills`, `.cursor/rules`,
  `.github/skills`, and the shared `.agents/skills`) that the five supported hosts map
  onto as applicable; the requirement is per supported host, not per physical directory,
  and nothing here marks Antigravity unsupported. Owner: Implementer. Window: Iteration 001.
- **FR-014**: The product-domain lens MUST run before EVERY feature at adaptive depth — it is
  not a one-time pass. The structured record MUST carry a `context_scope` field
  (`feature_standalone | product_baseline | feature_delta`); V1 always writes
  `feature_standalone`. The lens MUST NOT re-run full competitive/business discovery for every
  feature unless the feature changes the product context, and MUST NOT treat inherited product
  context as silently valid when a feature contradicts it — it records the divergence and the
  reason. The `product_baseline` / `feature_delta` delta-inheritance behavior is OWNED by
  Proposal 162 and DEFERRED; V1 builds the feature-level pass and the forward-compatible
  `context_scope` + `product_id` / `product_context_ref` hooks. Owner: Implementer/Spec
  Steward. Window: Iteration 001 (feature_standalone + hooks); delta deferred (post-162).

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story maps to one or more functional requirements
  (US1 → FR-001..FR-006, FR-012, FR-014; US2 → FR-009..FR-011; US3 → FR-007, FR-008, FR-013,
  FR-014).
- **TG-002**: Each requirement identifies expected owner role(s) (recorded inline above).
- **TG-003**: Each requirement identifies its intended iteration/delivery window
  (recorded inline above; FR-008 explicitly deferred).
- **TG-004**: Any known spec/implementation conflict includes an explicit reconciliation
  path: FR-007/FR-008 are reconciled by building forward-compatible shapes now and
  recording the deferral in `drift-log.md` with the 156/162 dependency citation.

### Key Entities *(include if feature involves data)*

- **ProductDomainRecord**: the per-feature record in two forms — human-readable
  (`product-domain.md`) and structured (`product-domain.yml`). Attributes: selected
  depth + reason, per-decision-area answers, assumptions, evidence-tagged statements,
  skipped areas with reasons, follow-up research, and confirmation provenance.
- **EvidenceTag**: one of `known` | `assumed` | `unknown` | `research-needed`, attached
  to each material product-domain statement.
- **Depth**: one of `Light` | `Standard` | `Deep`, selected per feature with a recorded
  reason.
- **ProductDomainLens**: the catalog knowledge file (`product-domain.md` in the design-
  lens catalog) defining the decision areas, depth model, evidence vocabulary, and
  conduct rules.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a feature intake, the product-domain record is produced before the
  applicability questionnaire is answered (ordering verifiable in the artifact stream /
  test).
- **SC-002**: The record declares a depth (Light/Standard/Deep) with a recorded reason;
  depth selection is covered by tests for all three depths.
- **SC-003**: Every material product-domain statement in the structured record carries
  an evidence tag from {known, assumed, unknown, research-needed}; a record with an
  untagged material statement fails validation.
- **SC-004**: Both a human-readable (`product-domain.md`) and a structured
  (`product-domain.yml`) record exist under `workshop/` after intake; absence of either
  fails the specify gate.
- **SC-005**: The specify gate rejects a product-domain record whose confirmation
  provenance is a batch/agenda approval (a test asserts a batch-approved record fails),
  enforcing FR-009.
- **SC-006**: A `research-needed` tag blocks the plan boundary only when flagged
  load-bearing; two tests cover the blocking and the non-blocking path.
- **SC-007**: The product-domain conduct is identical across all managed skill surfaces
  of the supported hosts (a host-parity test passes; injected drift fails it).
- **SC-008**: The structured `product-domain.yml` validates against the documented
  Proposal 156-forward-compatible shape (schema test), so 156 wiring is a later
  connection.
- **SC-009**: The structured record carries a `context_scope` field constrained to
  {`feature_standalone`, `product_baseline`, `feature_delta`}, writing `feature_standalone`
  in V1; a schema test asserts the field is present and enum-constrained, and the depth
  selector is covered by tests that map risk/novelty inputs to Light/Standard/Deep.

## Assumptions

- Proposal 156 (`workshop-decisions.yml`) and Proposal 162 (two-tier product-level
  context) are NOT shipped on disk; FR-007/FR-008 are deferred to forward-compatible
  shape only, recorded in `drift-log.md`.
- The lens working id is `product-domain`; per-feature artifacts live under
  `specs/<feature>/workshop/`, matching the existing `workshop/<lens-id>.md` convention.
- The existing specify-boundary gate and the SC-026 `confirmation` / `confirmation_scope`
  provenance machinery are the enforcement substrate; this feature extends them rather
  than adding a parallel validator.
- "Multi-host" means all five supported hosts (Claude, Copilot/GitHub, Codex/Agents,
  Cursor, Antigravity); their `specrew-design-workshop` conduct currently lives in four
  on-disk managed-skill surfaces (`.claude/skills`, `.cursor/rules`, `.github/skills`,
  `.agents/skills`, each carrying a `.specrew-managed` marker) that the hosts map onto as
  applicable. The exact host→surface mapping and deploy-source wiring are resolved at
  plan time; no supported host is excluded.
- The mechanical slot-in (first-stage phase vs `applicability-map.json` row) is decided
  at the design-analysis stop; this spec is behavioral.

## Governance Alignment *(mandatory)*

- **Spec Steward**: accountable for spec integrity and the FR-006 / FR-012 reframing and
  summary obligations.
- **Iteration Facilitator**: Planner role; owns cadence and the deferral bookkeeping for
  FR-007/FR-008.
- **Capacity Model**: story points (SP); 20 SP iteration cap; proposal sizing 6-10 SP.
- **Drift Signals**: `drift-log.md` records the 156/162 deferrals; the validator and the
  new specify-gate floor detect missing/malformed product-domain records and conduct
  drift across host copies.
- **Human Oversight Points**: specify, clarify, plan, tasks, before-implement,
  review-signoff, retro, and feature-closeout boundaries each require an explicit human
  verdict.
