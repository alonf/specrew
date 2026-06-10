# Feature Specification: Code & Implementation Lens (software-development-rules workshop lens)

**Feature Branch**: `177-software-development-rules-lens`
**Created**: 2026-06-10
**Status**: Draft
**Input**: "Add a software development rules workshop lens, find the related proposal." Related proposal: `proposals/163-code-implementation-lens.md` (Code & Implementation Lens). Maintainer scope ruling: build the FULL feature, not the proposal's record-only V1.

## Summary

Specrew's design lenses cover *what the system is* (architecture, data, ui-ux, security,
integration, devops, requirements/NFR, observability, component, product-domain). **None covers
*how the code is written*** — the implementation craft. Today those decisions (language version,
DI posture, file/function size, comment policy, packaging, per-stack dilemmas, the maintainer's 49
default rules) are made ad-hoc during `implement` instead of decided up front like every other
design dimension.

This feature adds a `code-implementation` design-workshop lens that captures implementation-craft
rules **with the human at design time** and then **actively guides the coding agent at implement
time** via a generated guidance skill. Enforcement is **guidance, not a gate**: there is no
review-time mechanical conformance check (no Proposal 145) and no parallel code-quality engine.

The lens is **data-driven**: the 49 maintainer default rules + per-stack defaults live in a
canonical `code-rules.yml` catalog (stable IDs, grouped). A workshop turn presents them without a
wall, the human selects/decides/adds rules (including ingesting a company coding guideline), and the
result is a per-feature `implementation-rules.yml` manifest. A static, multi-host `specrew-code-rules`
skill reads that manifest at implement time and composes a baseline + per-feature overlay to guide
the agent. The feature is **self-contained and forward-compatible** with the unshipped Proposal 156
(`workshop-decisions.yml`) and Proposal 162 (product-level inheritance).

## Design Workshop Intake *(captured 2026-06-10)*

The intake design workshop ran the product-domain phase + six technical lenses; full records are
under `specs/177-software-development-rules-lens/workshop/` and `lens-applicability.json`.

- **Product-domain** (Standard) — primary user is the coding agent at implement time; the pain is the
  missing "how the code is written" lens; load-bearing outcome is the agent following the rules.
- **architecture-core** (full) — producer→manifest→consumer spine; **data-driven catalog** (not
  prose-only); **one** guidance skill consumed by current + future (Proposal 139) sub-agents, with
  rule content in data and only a pointer in the system prompt; forward-compat `context_scope` hooks;
  advisory posture (no new hard gate).
- **component-design** (full) — catalog / producer / per-feature artifacts / consumer / wiring / tests;
  static generic reader skill (baseline + per-feature overlay); reference-by-ID manifest; reuse the
  existing deploy engine.
- **requirements-nfr** (medium) — FR-001..FR-012; quality drivers usability(rule-volume) >
  maintainability/forward-compat > multi-host parity > testability; runtime/dogfood validation, not
  file-presence.
- **ui-ux** (medium) — two surfaces: a human-facing guideline-first grouped checklist with set/unset +
  custom rules; an agent-facing baseline + task-scoped + per-feature-overlay guidance shape.
- **integration-api** (medium) — registration + catalog/overlay + manifest contracts; fail-open
  everywhere; always-applicable-for-code-features.
- **devops-operations** (light) — ships with the module (FileList + `.specify/` mirror) + deploys to
  host skill dirs via the engine; minor bump 0.34.0 → 0.35.0, beta-before-stable.

## Clarifications

### Session 2026-06-10 (maintainer rulings)

- **Full feature, not the proposal's record-only V1** — the full intake (all decision points +
  per-stack dilemmas + 49 rules grouped).
- **No Proposal-145 verification** — no review-time conformance gate, no parallel code-quality engine.
- **A resulting guidance skill is required** — it actively guides the implementing agent when it writes
  code (the load-bearing deliverable beyond record-capture).
- **Run cadence** — the code rules are mostly product-level and stable: decided once at a product-level
  workshop, inherited per feature, re-opened only when a feature introduces a **new technology or
  programming language**. Ship forward-compatible with Proposal 162 (`context_scope` hooks); V1 writes
  `feature_standalone`.
- **Guideline-first** — the lens asks for an existing coding guideline (yours/company) first, the way
  ui-ux asks about Figma; if present it is ingested (assisted mapping + extraction); company-level
  guidelines persist to a reusable project overlay.
- **Multi-host skill deployment is reused, not rebuilt** — the new skill is added as a managed skill
  *definition* (data) and the existing `deploy-squad-runtime.ps1` engine fans it to all hosts; a
  reusable `Deploy-SpecrewSkill` extraction is filed as a sibling, not built here.

### Session 2026-06-10 (clarify pass — light)

The intake workshop resolved every open fork with the maintainer (record-vs-full, skill granularity,
deployment, ID-vs-embed, guideline-first, overlay-in-V1, cadence, gate posture, applicability), and the
maintainer approved the spec at the specify verdict. No material question remains that requires the
human. The following plan-adjacent defaults are resolved by the Crew and recorded here (no new scope):

- **Stack resolution** — the lens resolves the feature's stack by asking the human at the lens turn,
  using repo/plan inference as a pre-filled hint (mirrors the stack-aware-tool-selection human-approval
  rule). The resolved stack drives which catalog slice + applicability-filtered rules are presented.
- **Enforcement-mode metadata** — each catalog rule carries an `enforcement-mode` field as
  *informational* metadata (how the rule would be verified: analyzer / test / review) that the guidance
  skill surfaces so the agent can self-check. It is **not gated** in V1 (consistent with the no-145
  ruling) and is forward-compatible with a future 145 verifier.
- **Catalog authoring fidelity + location** — `code-rules.yml` encodes Proposal 163's 49 rules
  one-entry-per-rule with stable IDs, grouped + scope-tagged; the exact on-disk path (design-lens
  knowledge dir) is a plan-time detail.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Coding agent is guided by the feature's code rules at implement time (Priority: P1)

As the coding agent during `implement`, I am actively guided by the craft rules chosen for this
feature so the code I write reflects the agreed posture (DI, naming, size, error handling, security
context, etc.) without the maintainer re-pasting rules.

**Why this priority**: This is the load-bearing outcome — the whole reason to capture rules is that
the agent then follows them. Baseline guidance is valuable even before any per-feature capture.

**Independent Test**: With a feature `implementation-rules.yml` present (and also with none), invoke
the `specrew-code-rules` skill and verify it surfaces the correct baseline + per-feature overlay rules
for the task at hand, and that generated code reflects them (dogfood).

**Acceptance Scenarios**:

1. **Given** a feature with a manifest selecting "DTO projection across services", **When** the agent
   writes a cross-service call, **Then** the skill surfaces that binding decision and the code follows it.
2. **Given** a feature with **no** manifest, **When** the agent writes code, **Then** the skill still
   surfaces the catalog `baseline-default` rules (baseline mode).
3. **Given** the agent is writing a React component, **When** it consults the skill, **Then** only the
   client/UI-relevant rules (render purity, event-loop) are surfaced, not the C++ or service rules.

---

### User Story 2 - Human captures the feature's code rules in the workshop, no wall (Priority: P1)

As the human developer, at design time I decide this feature's code rules in a workshop: I'm asked
first whether I have a coding guideline, I review a grouped checklist pre-checked at sensible defaults,
I set/unset rules, I add my own, and I'm never shown all 49 rules as a flat wall.

**Why this priority**: Without design-time capture there is nothing feature-specific to guide with, and
the rule-volume UX is the make-or-break usability driver.

**Independent Test**: Run the lens in the workshop on a sample feature; verify the guideline-first
question, stack resolution, grouped pre-checked checklist, set/unset, custom-rule entry, and that a
schema-valid `implementation-rules.yml` + `workshop/code-implementation.md` + `lens-applicability.json`
record are produced.

**Acceptance Scenarios**:

1. **Given** the lens starts, **When** it opens, **Then** the first question asks for an existing
   coding guideline (paste / point / none).
2. **Given** a pasted company guideline, **When** ingested, **Then** matching catalog rules are
   pre-checked, conflicts are flagged for the human, and new rules are added as custom items with
   provenance.
3. **Given** no guideline, **When** the checklist is presented, **Then** baseline + language rules are
   pre-checked (review, not author), only the consequential decision-prompts need a pick, and the human
   can uncheck any rule or add a free-text custom rule.

---

### User Story 3 - Data-driven catalog + reusable company-guideline overlay (Priority: P2)

As the maintainer, the 49 default rules + per-stack defaults ship as one data-driven catalog with
stable IDs, and a company guideline ingested once at product level is inherited by every feature.

**Why this priority**: The catalog is the single source of truth the lens, skill, and future 156/145
all depend on; the overlay realizes the product-level cadence.

**Independent Test**: Validate `code-rules.yml` (unique/stable IDs, schema-valid, 49 rules + per-stack
present + grouped + scope-tagged); add a `code-rules.local.yml` overlay and verify additive + override
merge that never drops shipped rules.

**Acceptance Scenarios**:

1. **Given** the shipped catalog, **When** validated, **Then** every rule has a unique stable id,
   group, scope, and applicability, and the 49 maintainer rules + per-stack defaults are present.
2. **Given** a project overlay adding two rules and overriding one default, **When** merged, **Then**
   both new rules appear and the override applies, and no shipped rule is silently dropped.

---

### User Story 4 - Multi-host deployment, parity, and forward-compatibility (Priority: P3)

As Specrew, the lens + skill deploy identically to every host and the manifest is forward-compatible
with the unshipped 156/162 spine.

**Why this priority**: Required for the feature to work across hosts and to plug into the future generic
spine, but it rides on existing machinery.

**Independent Test**: Run init/update; verify `specrew-code-rules` is present and identical in every
active host skill root (parity test); verify the manifest carries `context_scope` + stable IDs as the
156 join key.

**Acceptance Scenarios**:

1. **Given** init/update, **When** it completes, **Then** the new skill exists in every active host
   skill dir with a `.specrew-managed` marker and passes the parity test.
2. **Given** a written manifest, **When** inspected, **Then** it carries `context_scope=feature_standalone`
   and stable rule IDs suitable for a future 156 adapter.

### Edge Cases

- **No manifest** → the skill falls back to catalog baseline rules (baseline mode), never errors.
- **Manifest references an unknown rule ID** (catalog changed) → the skill warns and skips the unknown
  ID (fail-open), surfaced, never crashes.
- **Malformed project overlay** → warn and use the shipped catalog.
- **Guideline ingestion fails / unparseable** → fall back to the manual checklist; do not block.
- **Non-code feature** (doc-only/config-only) → the lens is skipped with an explicit reason.
- **Conflicting guideline rule vs a shipped default** → flagged for the human's decision, never silently
  overridden.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A `code-implementation` lens MUST exist and be registered in the catalog (`index.yml`,
  `applicability-map.json`, the `specrew-design-workshop` lens map, the `$lensIds` test list), with a
  lens md carrying the decision spine, per-stack dilemma sections, run-cadence, and workshop conduct.
- **FR-002**: A data-driven `code-rules.yml` catalog MUST ship with Specrew encoding the 49 maintainer
  default rules + per-stack defaults, each with a stable `id`, `group`
  (baseline-default / decision-prompt / applicability-filtered / enforcement-mode), `scope`
  (cross-language / language:&lt;x&gt; / framework:&lt;y&gt;), applicability, and default.
- **FR-003**: Run via the workshop, the lens MUST resolve the feature's stack and present rules via the
  grouping model (baseline stated as defaults+exceptions; decision-prompts surfaced; applicability-filtered
  shown only when the context applies), capturing the human's selections/decisions and checked/unchecked
  state without presenting a flat wall.
- **FR-004**: The workshop MUST write a schema-valid, reference-by-ID `implementation-rules.yml`
  (selected rule IDs, checked/unchecked state, per-rule decision/enforcement, resolved stack, custom
  rules, provenance, and `context_scope`), a human-readable `workshop/code-implementation.md`, and the
  `lens-applicability.json` record.
- **FR-005**: A new `specrew-code-rules` skill MUST deploy to every host skill surface via the existing
  deploy engine; it MUST be a static generic reader that resolves the active feature, reads the manifest
  at the known location, and composes baseline (catalog `baseline-default` rules) + overlay (the
  feature's selected rules/decisions) to guide the coding agent.
- **FR-006**: `plan.md` MUST convert the selected rules into implement constraints (Planner directive),
  and the Implementer charter/coordinator MUST carry a thin pointer to consult the `specrew-code-rules`
  skill and follow `implementation-rules.yml`.
- **FR-007**: The manifest MUST carry forward-compatible `context_scope`
  (`product_baseline` / `feature_delta` / `feature_standalone`) hooks; V1 writes `feature_standalone`
  and MUST NOT build Proposal 162 inheritance behavior; the conduct records the cadence (re-open
  per-stack only on new technology/language).
- **FR-008**: With no manifest, the skill MUST still surface the catalog `baseline-default` rules
  (baseline-only mode).
- **FR-009**: The human MUST be able to set/unset individual rules and add custom rules.
- **FR-010**: The lens MUST open with a "source of code-rules truth" question — whether the human has an
  existing coding guideline (paste / point / none) — the way ui-ux asks about Figma.
- **FR-011**: When a guideline is provided, the lens MUST perform assisted ingestion: map it onto the
  catalog (auto-check matches, flag conflicts for the human), and extract rules not in the catalog as
  custom items, recording provenance. No deterministic guideline parser is required.
- **FR-012**: Custom rules MUST be accepted via free-text OR a pasted document, captured into the
  per-feature manifest, with company/org-level rules persistable to a reusable project overlay
  (`code-rules.local.yml`) that merges additively + per-rule override and never silently drops a shipped
  rule.

### Deferred / Out of Scope

- **Deferred (dependency reality)**: Proposal 156 `workshop-decisions.yml` emission — the manifest is
  shaped forward-compatible (stable IDs as the join key); 156 does not exist on disk.
- **Deferred**: Proposal 162 product-level inheritance behavior — hooks only.
- **Out of scope by ruling**: Proposal 145 review-time conformance verification / any parallel
  code-quality gate.
- **Out of scope (future)**: an analyzer-config "enforced mode" that configures + requires stack tooling.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story maps to one or more functional requirements (US1→FR-005/FR-007/FR-008;
  US2→FR-001/FR-003/FR-004/FR-009/FR-010/FR-011/FR-012; US3→FR-002/FR-012; US4→FR-005/FR-007).
- **TG-002**: Owner roles — Spec Steward (lens md + catalog content), Implementer (skill, manifest
  writer, registration, wiring), Reviewer (tests + parity), with the maintainer owning the default rule
  posture.
- **TG-003**: Delivery window — single feature, expected 2 iterations (see Governance Alignment).
- **TG-004**: Any spec/implementation conflict (e.g., a host's skill root differing from the assumed
  set) MUST be recorded in `drift-log.md` with a reconciliation path.

### Key Entities

- **Rule catalog (`code-rules.yml`)**: the shipped 49 rules + per-stack defaults; each rule has id,
  group, scope, applicability, default, enforcement-mode; the single source of truth.
- **Project overlay (`code-rules.local.yml`)**: user/company rules layered additively over the catalog
  (the ingested-guideline home; product-baseline tier).
- **Per-feature manifest (`implementation-rules.yml`)**: selected rule IDs + checked/unchecked +
  decisions + resolved stack + custom rules + provenance + `context_scope`; validated against
  `implementation-rules.schema.json`.
- **Guidance skill (`specrew-code-rules`)**: the static, multi-host reader composing baseline + overlay
  for the agent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The lens is registered and selectable; registration tests pass (lens id present in
  `index.yml`, `applicability-map.json`, the design-workshop lens map, and `$lensIds`).
- **SC-002**: Running the lens on a feature produces a schema-valid `implementation-rules.yml` +
  `workshop/code-implementation.md` + a `lens-applicability.json` record with confirmation provenance.
- **SC-003**: After init/update, `specrew-code-rules` is present and identical in every active host
  skill dir (multi-host parity test green).
- **SC-004**: At implement time the skill surfaces the selected rules and generated code reflects them —
  **validated by dogfood, not file-presence**.
- **SC-005**: The catalog has unique/stable rule IDs, validates against its schema, and contains the 49
  maintainer rules + per-stack defaults, grouped and scope-tagged.
- **SC-006**: With no manifest, the skill still surfaces baseline-default rules.
- **SC-007**: The rule-volume UX holds — the human is never shown a flat wall; only material rules need a
  decision — **validated by the dogfood human experience**.

## Assumptions

- The existing design-lens machinery (F-141) and first lens (F-176) are the integration substrate;
  this lens follows that proven pattern.
- The existing `deploy-squad-runtime.ps1` engine is the single owner of multi-host skill fan-out; the
  new skill is added as data, not new deployment code.
- Proposals 156, 162, and 145 are unshipped on disk; this feature is self-contained and
  forward-compatible, not dependent on them.
- The active-feature resolution mechanism (from start-context) is reused for the skill to find the
  manifest; no new resolution mechanism is built.
- Authoring is PowerShell/Windows; markdownlint, FileList, `extension.yml` version, and `.specify/`
  mirror parity are explicit release tasks.

## Governance Alignment *(mandatory)*

- **Spec Steward**: baseline Spec Steward role — owns spec integrity + the lens md/catalog content.
- **Iteration Facilitator**: Planner + Retro Facilitator — cadence and blockers.
- **Capacity Model**: Story Points; 20 SP per-iteration cap (intentional AI-context sizing).
- **Drift Signals**: `drift-log.md` per iteration + the governance validator; mirror-parity and
  registration tests detect structural drift.
- **Human Oversight Points**: specify, clarify, design-analysis (co-design), before-implement,
  review-signoff, retro, iteration-closeout, feature-closeout — all human-judgment boundaries.
