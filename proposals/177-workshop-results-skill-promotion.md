---
proposal: 177
title: Workshop Results Skill Promotion and Implementation Context Packs
status: candidate
phase: phase-2
estimated-sp: 14-22
priority-tier: 2
discussion: surfaced 2026-06-10 while Feature 177 (software-development-rules / code-implementation lens) was being designed. The maintainer liked the F-177 pattern where workshop-selected implementation rules are captured in a structured manifest and exposed to the coding agent through a static reader skill, then asked whether other durable workshop results such as UI/UX and architecture decisions should also become skills so agents always have the information at hand.
---

# Workshop Results Skill Promotion and Implementation Context Packs

## Why

Specrew's workshop artifacts capture useful design knowledge, but the knowledge
does not always reach the agent at the moment it writes or reviews code.

Feature 177 introduces a strong pattern for implementation rules:

- stable rule content lives in a catalog;
- the workshop records per-feature selections in a structured manifest;
- a static `specrew-code-rules` skill reads the active feature manifest and
  guides the implementer;
- the system prompt carries only a pointer, not a duplicated wall of rules.

That pattern should not be limited to code craft. Other workshop results can be
equally important at implementation time:

- product/domain context: users, stakeholders, pain, non-goals, vocabulary;
- architecture rules: boundaries, service ownership, dependency direction,
  error handling, state ownership, integration style;
- UI/UX rules: design system, accessibility floor, navigation, form behavior,
  empty/loading/error states, density and layout conventions;
- quality/testing rules: required evidence, test realism, fixture policy,
  reviewer expectations, negative-case coverage.

Today these are mostly stored as feature artifacts. The agent may read them if
the coordinator remembers to surface them, but they are not consistently
"always at hand." The result is predictable drift: code follows generic agent
habits instead of the product's chosen design rules.

The fix is not to turn every workshop note into a permanent prompt. The fix is a
promotion mechanism that distinguishes durable project knowledge from
feature-local decisions and transient research.

## Grounding From Feature 177

This proposal generalizes the current Feature 177 workshop decisions:

- **Architecture-core**: content belongs in stable data; selection belongs in a
  per-feature manifest; delivery belongs in one static reader skill; prompts
  carry only pointers.
- **Component-design**: use a static generic reader skill deployed once to every
  host, plus one per-feature manifest in a known location. Do not rewrite host
  skills per feature.
- **Requirements/NFR**: dogfood must prove the agent actually uses the rules;
  file presence is not enough.
- **Product-domain**: many rules are product-level and stable, then re-open only
  for feature deltas or new stack/language choices.

The same spine can support other lens outputs.

## What

Add a **Workshop Result Promotion** mechanism with two output classes:

1. **Durable managed skills** for project/product rules that should repeatedly
   guide agents across features.
2. **Implementation context packs** for the current feature's working set:
   selected durable rules, feature-specific deltas, active decisions, and links
   back to source artifacts.

The key rule: skills are durable memory; context packs are the current working
set.

## Promotion Taxonomy

Every material workshop statement gets classified before promotion:

| Classification | Example | Output |
| --- | --- | --- |
| Product/project durable | "All UI forms prevent Enter-key reload"; "Services depend inward only"; "Use caller-owned DTOs" | Managed skill + structured project record |
| Feature delta | "This feature may add one adapter under `scripts/internal`"; "This screen uses the dense dashboard table variant" | Feature context pack + feature workshop artifact |
| Temporary assumption | "Assume single tenant until clarified" | Feature artifact only, carried as assumption |
| Research snapshot | "Provider X supports hook Y as of 2026-06-10" | Source-backed artifact, optional summarized context pack entry |
| One-off rejected option | Architecture alternative not chosen | Feature artifact only |

Promotion must be explicit. A workshop artifact does not become a durable skill
just because it exists.

## Proposed Skill Family

The feature should add a small managed skill family, not a skill per lens note.

### `specrew-product-context`

Reads product-level and current-feature product context:

- users and stakeholders;
- pain/job/current workaround;
- MVP, vision, non-goals;
- vocabulary and domain concepts;
- constraints and evidence quality;
- active feature deltas.

This skill is the durable consumer surface for Proposal 176 and Proposal 162.

### `specrew-architecture-rules`

Reads product architecture and feature architecture deltas:

- macro architecture and decomposition style;
- module/service/component boundaries;
- dependency direction and allowed coupling;
- state ownership and data-flow rules;
- integration and error-handling posture;
- approved divergences and their reasons.

This skill should not re-run design analysis. It surfaces already-approved
architecture decisions at coding/review time.

### `specrew-ui-ux-rules`

Reads UI/UX design-system and current feature UI decisions:

- visual and layout conventions;
- component library and component use rules;
- accessibility floor;
- navigation and interaction patterns;
- form behavior, empty/loading/error states;
- mobile/responsive expectations;
- active screen/flow deltas.

It is relevant only when the feature has a UI surface. No UI feature, no
surfacing beyond an explicit "not applicable" line.

### `specrew-quality-rules`

Reads quality and testing expectations:

- test realism and fixture policy;
- evidence requirements;
- negative-case expectations;
- reviewer anti-patterns;
- required local/CI checks;
- stack-specific test strategy.

This skill is advisory in V1. Future Proposal 145-style conformance can consume
the same structured records.

### `specrew-code-rules`

Feature 177 remains the pilot for implementation-craft rules:

- code style and naming;
- composition and abstraction posture;
- stack/language defaults;
- API and DTO boundaries;
- observability, robustness, security-context flow;
- tests and review evidence at code level.

This proposal composes with F-177 rather than replacing it.

## Artifact Model

### Product/project level

Store durable promoted records under a project-owned location, for example:

```text
.specrew/context/
  product-context.yml
  architecture-rules.yml
  ui-ux-rules.yml
  quality-rules.yml
  code-rules.yml              # or the catalog-backed F-177 record
```

Each record should include:

```yaml
schema: v1
scope: product_baseline
source_artifacts:
  - specs/176-product-domain-lens/workshop/product-domain.md
last_reviewed_at: "2026-06-10T00:00:00Z"
reviewed_by: human
evidence_quality: known | assumed | researched | research-needed
freshness:
  recheck_on:
    - new product direction
    - new platform
    - new programming language
    - major architecture divergence
rules:
  - id: architecture.dependency-direction
    summary: "Dependencies point inward; adapters depend on core, not reverse."
    status: active
    precedence: project-default
```

### Feature level

Each feature gets a working-set context pack:

```text
specs/<feature>/context-pack.yml
specs/<feature>/context-pack.md
```

The context pack references durable records and adds feature deltas:

```yaml
schema: v1
feature: "177-software-development-rules-lens"
inherits:
  product_context: .specrew/context/product-context.yml
  architecture_rules: .specrew/context/architecture-rules.yml
  quality_rules: .specrew/context/quality-rules.yml
feature_deltas:
  - id: code.stack
    source: specs/177-software-development-rules-lens/workshop/code-implementation.md
    summary: "PowerShell implementation; no runtime analyzer gate in V1."
active_skill_surfaces:
  - specrew-code-rules
  - specrew-quality-rules
```

The context pack is what the coordinator injects before implementation and
review. The skills are what the agent consults for durable detail.

## Precedence Rules

When sources disagree, precedence must be deterministic:

1. Human-approved feature spec/plan/task decision.
2. Human-approved feature context pack delta.
3. Product/project durable skill record.
4. Specrew default catalog.
5. Generic agent preference.

Conflicts at levels 1-3 require a recorded variance or divergence. The agent
must not silently pick the convenient source.

## Lifecycle

1. Product-domain / architecture / UI / quality / code lenses ask whether any
   decisions are durable beyond the feature.
2. The workshop writes normal feature artifacts first.
3. A promotion pass classifies material statements as durable, feature delta,
   assumption, research snapshot, or artifact-only.
4. Durable items update `.specrew/context/*` only after explicit human approval.
5. Feature deltas write `specs/<feature>/context-pack.*`.
6. `specrew start`, `specrew-refocus`, `before-implement`, and review bootstrap
   surface a compact context-pack pointer plus the relevant skill names.
7. Implementer and Reviewer consult the same context pack and skills.

## Gates And Validation

V1 should enforce structure, not subjective quality:

- schema-valid durable records and context packs;
- source artifact paths exist;
- every promoted item has scope, source, evidence quality, and freshness rule;
- managed skills deploy with multi-host parity;
- feature context pack lists only existing skills;
- conflicting overrides require a variance/divergence record.

Quality is dogfooded:

- Does the coding agent follow the promoted rules without the human re-pasting
  them?
- Does review use the same records to judge the implementation?
- Does the human see a concise working set instead of a wall of every rule?

## Non-Goals

- No per-feature rewriting of host skill files.
- No promotion of every workshop note into durable project memory.
- No replacement for `spec.md`, `plan.md`, `tasks.md`, or workshop artifacts.
- No new mechanical conformance engine in V1.
- No stale competitive/research snapshot treated as permanent product truth.
- No prompt-bloat approach where all rules are pasted into every coordinator
  prompt.

## Risks And Mitigations

| Risk | Mitigation |
| --- | --- |
| Skill sprawl | Small fixed skill family; generic readers, not per-feature skill generation |
| Stale rules | `last_reviewed_at`, freshness triggers, explicit re-open rules |
| Hidden authority | Every promoted rule links to source artifact and human approval |
| Prompt bloat | Context pack is compact; skills are on-demand detail |
| Feature-specific decisions leaking globally | Promotion classification plus human approval before durable writes |
| Conflicting guidance | Deterministic precedence and variance records |
| File-presence false confidence | Dogfood checks agent behavior, not only deployed files |

## Acceptance Criteria

- AC1: Workshop artifacts can declare promotion candidates with scope,
  evidence quality, source, and freshness metadata.
- AC2: A product/project durable decision can be promoted to a managed skill
  record and surfaced by the matching skill.
- AC3: A feature-specific decision can be included in `context-pack.yml` without
  changing durable project rules.
- AC4: The implementation bootstrap surfaces a compact context pack and relevant
  skill names before code is written.
- AC5: UI/UX, architecture, quality, product, and code-rule surfaces are all
  supported by the generic pattern.
- AC6: Multi-host skill deployment remains parity-checked.
- AC7: A dogfood feature proves the agent follows at least one promoted
  architecture/UI/quality/code rule without the maintainer re-pasting it.

## Effort And Phasing

Recommended scope: 14-22 SP, likely two iterations.

Iteration 1:

- promotion taxonomy and schemas;
- context-pack writer/renderer;
- one pilot durable skill beyond `specrew-code-rules`, preferably
  `specrew-architecture-rules` or `specrew-product-context`;
- bootstrap/refocus/before-implement surfacing.

Iteration 2:

- UI/UX and quality skill readers;
- multi-host parity tests;
- conflict/variance handling;
- dogfood feature proving implementation-time use.

## Relationships

- Builds on Proposal 162 (product-level once, feature delta later).
- Builds on Proposal 176 / Feature 176 (product-domain first lens).
- Generalizes the Feature 177 `specrew-code-rules` pattern.
- Composes with Proposal 156 (`workshop-decisions.yml`) when it ships.
- Feeds future Proposal 145 conformance checks without implementing 145 now.
- Composes with Proposal 139 sub-agents: sub-agents should receive the context
  pack pointer and relevant skill names, not a duplicated wall of project rules.
- Composes with Proposal 175 supplemental packs: packs can contribute source-
  backed context, but only durable decisions are promoted to skills.
