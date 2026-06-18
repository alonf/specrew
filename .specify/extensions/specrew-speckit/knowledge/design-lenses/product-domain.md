# Product & Problem Domain Lens

## Lens ID

`product-domain`

## Purpose

Force the first **product** conversation before any technical design lens runs. The other
lenses (architecture, data, ui-ux, security, integration, devops, requirements/NFR,
observability, component) start close to the solution; none asks who the feature is for,
what pain it solves, what exists today, what constraints apply, what the MVP and non-goals
are, or what alternatives it must beat. Without that grounding the Crew can build a
solution request that is technically correct but **product-wrong** — good requirements for
the wrong problem. This lens is the pre-technical grounding that prevents confident product
fiction.

## When this lens runs (first-stage phase)

`product-domain` is **always applicable** and runs as a **first-stage workshop phase, before
the technical-lens applicability questionnaire** — not as a row in `applicability-map.json`
and not gated by a yes/no question. Depth is adaptive: even a tiny feature gets a Light pass
that records why deeper discovery is not warranted. The deterministic selector that chooses
the technical lenses is untouched; this phase precedes it.

## Applicability Signals

- Always. The only decision is the depth (see Depth Model), chosen by risk and novelty.

## Design Decision Points

Capture these product/problem areas at the selected depth:

1. **Users, customers, and stakeholders** — separate **user**, **customer/buyer**,
   **operator**, and **stakeholder** when they differ; include who is harmed by bad output,
   downtime, or confusing behavior.
2. **Pain, jobs, and current workaround** — the pain / job-to-be-done / operational gap; what
   users do today without this; the cost of doing nothing.
3. **Existing system and context** — new product / extension / replacement / integration /
   migration; a small context map of surrounding systems, data, channels, and ownership when
   useful.
4. **Constraints** — budget, schedule, staffing, technology/platform, procurement/licensing,
   data residency/privacy/security/compliance, deployment/operations, organizational.
5. **Outcomes and success metrics** — user, business/process, operational, and quality
   outcomes in measurable terms where possible; the leading indicator for the MVP.
6. **MVP, non-goals, and vision** — smallest valuable slice; explicit out-of-scope; later
   vision; what must stay easy to change; what would make v1 a failure even if it works.
7. **Alternatives, competitors, and differentiation** — direct competitors, internal
   alternatives, manual workflows/spreadsheets, existing tools, build-vs-buy; which dimension
   must be better (cost, speed, usability, reliability, integration, automation, trust,
   accuracy, compliance, ownership). For internal tools, "competitor" usually means the
   current workaround or an existing enterprise platform, not a market rival.
8. **Adoption, rollout, and change impact** — pilot/beta/rollout, migration, training/docs,
   backwards compatibility, support handoff, adoption risk and incentives.

## Depth Model

Choose Light / Standard / Deep by **risk and novelty**, and record why.

- **Light** — tiny utilities, spikes, personal tools, narrow bug fixes. Required output:
  user/stakeholder, pain/job, MVP, out-of-scope, key constraints, and **why deeper discovery
  is not needed**. Light does NOT require competitive/alternative analysis.
- **Standard** — normal product features. Light plus: current workaround, existing
  system/context, success metrics, assumptions/evidence quality, adoption/rollout notes, and
  alternatives/competitors.
- **Deep** — new products, major workflow changes, regulated/high-risk domains, multi-team
  systems, migrations, commercial products, or unclear business strategy. Standard plus:
  stakeholder map, context diagram, competitive landscape, business/value model,
  migration/change-management strategy, validation/research plan, and the evidence gaps that
  block plan or implementation.

Depth-selection rules:

- first feature / new product / unclear product context → Standard or Deep;
- later feature in a known product → Light (or Delta once Proposal 162 ships);
- tiny bug fix / narrow internal utility → Light;
- major pivot, new user segment, new workflow, migration/replacement, regulated/high-risk
  area → Standard or Deep.

## Evidence Vocabulary

Tag every **material** product-domain statement with its evidence quality. This is what
prevents confident product fiction.

- `known` — backed by user/maintainer input, an existing artifact, analytics, or production
  evidence.
- `assumed` — reasonable but not verified.
- `unknown` — not yet known; the human explicitly accepted proceeding with the gap.
- `research-needed` — must be researched before plan or implementation. A `research-needed`
  statement carries `load_bearing: true|false`: a load-bearing gap (it affects feasibility,
  MVP scope, or major cost/risk) **blocks the plan boundary** until researched or explicitly
  accepted; a non-load-bearing one is recorded and carried.

## Run Cadence

The product-domain lens is **NOT run only once** — it runs **before every feature, at adaptive
depth**.

- **V1 (Proposal 176; Proposal 162 not shipped)**: every feature gets a feature-level
  product-domain pass with `context_scope: feature_standalone`.
- **Future (Proposal 162 shipped)**: the lens still runs per feature but in **delta mode**
  (`context_scope: feature_delta`) — inherit the product-level baseline
  (`context_scope: product_baseline`) and ask only what is new, changed, contradictory, or
  feature-specific. Proposal 162 owns the persistent baseline + inheritance behavior; 176
  builds the feature-level pass and the forward-compatible `product_id` / `product_context_ref`
  / `context_scope` hooks.
- Do **not** re-run full competitive/business discovery for every feature unless the feature
  changes the product context. Do **not** treat inherited product context as silently valid
  when a feature contradicts it — record the divergence and the reason.

## Workshop Conduct

- **Run this phase FIRST**, before the technical-lens applicability agenda. Announce it; load
  this lens; select the depth and state the reason.
- **Reframe a solution-first request into the problem.** When the human asks to "build X",
  surface the problem, user, pain, MVP, and constraints before proceeding to design. If the
  requested feature is not aligned to the pain, MVP, constraints, or alternatives, surface
  that **before plan**.
- **Tag evidence honestly.** Mark `assumed` / `unknown` / `research-needed` rather than
  stating an unverified claim as fact. Accept an `unknown` only when the human approves
  proceeding with the stated gap.
- **No batch confirmation.** The lens cannot be satisfied by approving an agenda or a batch
  "confirm all". It needs scoped product-domain confirmation, or an explicit scoped
  "not applicable" / "you decide" recorded honestly. Record the provenance
  (`human-confirmed` / `human-delegated` / `human-skipped`) and its matching scope.
- **Persist both records** (see Artifacts) before the specify boundary syncs, and summarize
  the decisions into `spec.md` without making it the sole source.
- **Re-invoke the `specrew-design-workshop` skill** before moving to the first technical lens.

## Question Bank

- Who is this for, and who else cares (buyer, operator, the harmed party)?
- What do users do today, and what does doing nothing cost?
- Is this a new product, an extension, a replacement, or a migration?
- Which constraints are binding before any technical choice?
- What is the smallest valuable slice, and what is explicitly out of scope?
- What must this beat — a competitor, a spreadsheet, an existing platform — and on which
  dimension?
- Which product claims are `known`, and which are `assumed` / `unknown` / `research-needed`?

## Alternative Dimensions

This lens is always applicable; its "alternatives" are the depth choice:

- **Simplest (Light)**: minimal grounding for a tiny/low-risk slice; record why deeper is not
  needed.
- **Reasonable (Standard)**: full product grounding for a normal feature.
- **By the book (Deep)**: stakeholder map, context + competitive analysis, business model, and
  a validation/research plan for new products, regulated domains, or migrations.

## Plan Obligations

- `spec.md` summarizes the product-domain decisions (not the sole source).
- The plan carries the constraints, MVP, non-goals, and any `research-needed` gaps forward.
- Load-bearing `research-needed` gaps are resolved or explicitly accepted before plan.

## Validation Signals

- A human-readable record and a structured record exist under the workshop folder.
- Every material statement carries an evidence tag.
- The specify gate confirms a genuine (non-batch) confirmation provenance.
- The requested feature is visibly aligned to the captured pain, MVP, and constraints.

## Artifacts

- `specs/<feature>/workshop/product-domain.md` — the human-readable product-domain record.
- `specs/<feature>/workshop/product-domain.yml` — the structured record (depth, per-area
  answers, evidence-tagged statements, skipped areas, follow-up research, confirmation
  provenance, and the `product_id` / `product_context_ref` / `context_scope` hooks). Validates
  against `specs/<feature>/contracts/product-domain.schema.json` (forward-compatible with
  Proposal 156 consumption; emission deferred).

## Source Notes

- GOV.UK Service Manual — discovery phase; U.S. Digital.gov — discovery operations.
- Roman Pichler — Product Vision Board; Atlassian — Project Poster; GV — Design Sprint.
- Product Talk — Opportunity Solution Tree; Strategyzer — Business Model Canvas; Aha! —
  Competitive analysis. (Research checked 2026-06-09; see Proposal 176.)
