# Product & Problem Domain — Feature 177 (software-development-rules / code-implementation lens)

**Depth**: Standard — Specrew is a known product and Proposal 163 completed the 2026-06-08
research baseline, so most context is `known`; but this is a substantive methodology addition
(a full new design lens + an implement-time guidance skill + plan/implement wiring), so it
earns current-workaround, success-metrics, and alternatives.

**Context scope**: `feature_standalone` (Proposal 162 product-level inheritance not yet shipped;
this lens ships forward-compatible hooks).

**Confirmation**: `human-confirmed` / `lens-question` — the maintainer read the full framing and
explicitly agreed ("I read all again, I agree with your insights").

## 1. Users / stakeholders

- **Primary user**: the Crew/coding agent at `implement` time — the direct consumer of the
  resulting guidance skill. The feature's center of gravity is *guiding the agent*. `known`
- **Secondary user**: the human developer who answers the lens at design time and reviews the
  captured rules. `known`
- **Buyer / maintainer**: Alon — sets the default 49-rule code posture. `known`
- **Operator**: the `plan` / `implement` phases (and Reviewer) that consume the captured
  constraints. `known`
- **Harmed if bad**: future maintainers inheriting inconsistent, refactor-prone code; reviewers
  who cannot trace *why* code was written a given way. `assumed`

## 2. Pain / job / current workaround

- **Pain**: the design lenses cover *what the system is*; none covers *how the code is written*.
  Implementation-craft decisions are made ad-hoc during `implement`. `known`
- **Current workaround**: rules scattered — pasted into prompts ad-hoc; generic Implementer
  charter; no design-time capture and no implement-time surfacing of a feature's chosen rules. `known`
- **Cost of nothing**: inconsistent craft, avoidable refactors, the agent re-derives or ignores
  craft rules every feature. `assumed`

## 3. Existing system / context

- Extension of the existing design-lens system (F-141 machinery + F-176 first lens); plugs into
  `index.yml`, `applicability-map.json`, the `specrew-design-workshop` skill, and the specify /
  design-analysis gates. `known`
- **New surface**: an implement-time guidance skill surfacing the captured rules to the coding
  agent. `known`

## 4. Constraints (binding)

- No Proposal-145 mechanical conformance gate / no parallel code-quality engine. `known`
- Self-contained: `workshop-decisions.yml` (156) + the 145 verifier do not exist on disk → ship
  forward-compatible. `known`
- Multi-host deployment for the lens md + the new skill. `known`
- Rule-volume UX: the 49 rules + per-stack dilemmas must use the grouping model. `known`
- Release mechanics: PowerShell/Windows authoring, markdownlint, FileList + `extension.yml`
  version bump for new deployable files. `known`
- No stale tech: check current LTS at workshop time. `known`

## 5. Outcomes / success metrics

- Design time: a feature's implementation-craft rules captured as a structured, human-chosen
  manifest. `known`
- Implement time: the coding agent is *actively guided* by those rules via the skill — the
  load-bearing outcome. `known`
- Leading indicator: dogfood shows generated code reflecting the chosen rules without the
  maintainer re-pasting them. `assumed`

## 6. MVP / non-goals / vision

- **MVP** (full-feature ruling): full lens content (all decision points + per-stack dilemmas +
  49 rules grouped) + structured manifest + implement-time guidance skill + plan→implement wiring.
- **Non-goals**: the 145 review-time conformance gate; building the generic 156 producer or 145
  verifier; auto-running stack analyzers as a hard CI gate.
- **Vision**: when 156/145 ship, the manifest plugs into the generic spine; an analyzer-config
  enforced mode can follow.
- **v1 failure even if it works**: the agent ignores the captured rules at implement time, or the
  49 rules overwhelm the human at design time. `assumed`

## 7. Alternatives / differentiation

- **A — status quo**: rules in the charter/prompt — not feature-scoped, not human-chosen, skimmed.
- **B — static `.editorconfig`/constitution only**: no design intent, no per-feature choice, no
  agent guidance.
- **C — the 145 mechanical gate**: explicitly rejected (parallel engine / over-engineering).
- **Differentiation**: design-time human-chosen **+** implement-time agent-surfaced, self-contained.
  Must beat status-quo prompt-paste on consistency, traceability, and the agent following craft rules.

## 8. Adoption / rollout / change impact

- Ships beta-first, dogfooded on Claude first; it is the 2nd lens and joins the standard workshop run.
- **Run-cadence ruling (maintainer, 2026-06-10)**: the code rules are mostly **product-level and
  stable** — decide them **once at a product-level workshop**, then each feature **inherits** them and
  re-opens only the parts a **new technology or programming language** changes. Forward-compatible with
  Proposal 162 via the `context_scope` / `product_baseline` / `feature_delta` hooks (like F-176). This
  reduces per-feature burden and answers Proposal 163's open per-stack-depth question: stable craft
  posture once, per-stack re-ask only on new stack/language. `known`
