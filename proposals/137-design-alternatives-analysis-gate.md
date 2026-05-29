---
proposal: 137
title: Design Alternatives Analysis Gate (New Lifecycle Boundary Between Clarify and Plan)
status: candidate
phase: phase-2
estimated-sp: 28-40
priority-tier: 1
discussion: surfaced 2026-05-27 during F-049 iter-3 plan-boundary design conversation. Third scope-expansion-via-design-conversation event in F-049 alone (iter-4 absorbed Proposal 120; iter-3 absorbed Proposal 015 explicit-dial + user-profile; iter-3 absorbed engine + data architecture). Empirically proves the design dilemma surfaces at the WRONG lifecycle moment (plan boundary) — should surface ONE boundary earlier as a sanctioned design-alternatives gate. User direction explicit 2026-05-27 — "after clarifying, before the plan, we need another architecture and design gate. In this gate the Crew propose at least two design approach for implementing the feature, sometimes three approach. The simplest, the reasonable and the by the book. Taking into account all quality features. And it can do that by writing, and by creating diagrams for each option and provide a link to that diagram. It can recommend the best feature and ask for an opinion."
---

# Design Alternatives Analysis Gate

## Why

Spec Kit's `/speckit.analyze` is **NOT a design-analysis gate** — it's a post-tasks cross-artifact consistency checker (read-only; runs after `/speckit.tasks`; detects duplication, ambiguity, terminology drift, coverage gaps). Verified by reading `file:///C:/Dev/Specrew/.github/agents/speckit.analyze.agent.md`. Spec Kit's full lifecycle (`constitution → specify → clarify → plan → tasks → analyze → checklist → implement → taskstoissues`) has **no mechanism for comparing 2-3 design approaches before planning locks in one**. This is a genuinely new methodology surface.

Specrew today inherits this gap. Agents proceed from clarify → before-plan → plan in a single direction, picking a design implicitly during planning. The human can only reject the plan AFTER the fact, which causes substantial rework.

### Empirical evidence — the pattern is recurring

**F-049 alone produced 3 scope-expansion-via-design-conversation events** at plan boundary (single session, 2026-05-27/28):

1. **iter-4 absorbed Proposal 120 5-Pillar Bypass Detection** — design dilemma about closeout governance scope surfaced when human noticed the iter-4 plan didn't yet incorporate the approved Pillar 5 (committed-tree enforcement)
2. **iter-3 absorbed Proposal 015 explicit-dial + user-profile persistence** — design dilemma about expertise-dial UX surfaced when human asked "do we need more personas? where do we store the dial?"
3. **iter-3 absorbed engine + data architecture** — design dilemma about volatile-area encapsulation surfaced when human asked "do we need to capture intake-question logic in its own script?"

Each was caught and absorbed cleanly, but the absorption cost was real (full lifecycle re-runs through specify → clarify → before-plan → plan → tasks for each).

**Other empirical instances of the same pattern across the broader dogfooding history**:

- **PlanningPoC iter-001 silent Aspose.CAD dependency** (2026-05-27, `[[project-plan-time-dependency-intent-proposal-candidate-2026-05-27]]`) — design decision (commercial library with license cost + size cap) made during plan/implement without ever being surfaced as a choice. Maintainer noticed at "can I run it" inspection 4 iterations later.
- **WSL trial autopilot scope creep** (2026-05-18, `[[project-wsl-trial-autopilot-clarify-gap-2026-05-18]]`) — substantive scope decisions resolved silently during clarify; F-016 + F-020 boundaries worked but Squad's autopilot bypassed the intake interview entirely.
- **Gym test 2-pause intake** (2026-05-19, `[[project-gym-test-intake-questioning-gap-2026-05-19]]`) — fresh greenfield with only 2 human pauses; auto-resolved tech stack, permission model, db, frontend type, hosting, auth.
- **PlanningPoC iter-006 ACadSharp silent swap proposal** (2026-05-27, `[[project-dilemma-surfacing-protocol-proposal-candidate-2026-05-27]]`) — agent proposed swapping Aspose for ACadSharp without surfacing as a comparable-options decision.
- **Antigravity over-claim incidents** (multiple, `[[project-antigravity-review-boundary-hallucination-2026-05-27]]`) — agents commit design choices without checkpoint; F-046 bypassed 4 sequential approval gates; F-048 claimed automated-feedback fully addressed without checking all hosts; F-049 claimed iteration-planning completed with 4 files uncommitted.

The pattern is **systemic, not anecdotal**. Every empirical instance traces to the same root cause: **substantive design decisions get resolved during code-shaped lifecycle phases (plan, implement, review) when they should be resolved during a dedicated design-shaped phase that doesn't currently exist**.

### Why the existing alternatives don't close the gap

| Existing mechanism | Why it doesn't substitute |
|---|---|
| **`/speckit.clarify` substantive questions (Proposal 063)** | Asks about WHAT to build (requirements clarity); doesn't ask HOW to build (architectural alternatives) |
| **`/speckit.plan` reviewing** | Plan already commits to ONE design; rejection causes full plan rebuild |
| **Architecture Intent Checkpoint (Proposal 011)** | Single-design discussion inside plan; doesn't surface 2-3 alternatives for comparison |
| **`/speckit.analyze` (Spec Kit post-tasks)** | Read-only consistency check AFTER tasks generated; way too late |
| **Per-user-story diagrams (Proposal 135)** | Diagrams of the ALREADY-chosen design; doesn't compare alternatives |
| **Reviewer at review-signoff** | Catches integrity issues post-implementation; way too late for design choice |

None of these surface alternatives BEFORE plan picks one. This proposal fills that exact gap.

## What — Six Pillars

### Pillar 1: New lifecycle boundary at `design-analysis` (~3-5 SP)

Insert a sanctioned boundary between `clarify` (or Specrew's `before-plan` extension) and `plan`:

```text
Current 9 boundaries:    specify → clarify → before-plan → plan → tasks → before-implement → implement → review-signoff → retro → iteration-closeout → feature-closeout

Proposed 10 boundaries:  specify → clarify → before-plan → [NEW: design-analysis] → plan → tasks → before-implement → implement → review-signoff → retro → iteration-closeout → feature-closeout
```

The new boundary is **mandatory for substantive iterations**; **skippable for trivial slice types** (chore, small-fix, bug-fix, doc-only per Proposal 055 slice-type catalog). Slice-type detection determines applicability per Proposal 055 rules. Walking-skeleton iterations (per Proposal 129) MAY also skip if the prior iteration's design-analysis still applies.

Verdict shape (per `[[feedback-verdict-boundary-naming-2026-05-22]]` discipline): `approved for plan with Option <X>` — names BOTH the boundary AND the chosen option.

### Pillar 2: 3-flavor design alternatives template (~3-4 SP)

The Crew proposes **at minimum 2, typically 3** design alternatives following a standardized flavor template:

| Flavor | Approach | Quality Features | Typical Use |
|---|---|---|---|
| **A: Simplest** | Minimum-viable shape; honest about gaps + future-cost | Bare-minimum applicable lenses | Throwaway prototypes, time-pressure delivery, clear-path features |
| **B: Reasonable** | Balanced; defers some by-the-book gold-plating | Quality-bundle preset (security baseline, robustness baseline, test-integrity) | Default for production features; balanced cost-of-build vs cost-of-future-change |
| **C: By the book** | Full-quality shape; all applicable lenses + idiomatic patterns | Comprehensive: security + robustness + maintainability + retry-idempotency + concurrency-correctness where applicable | Mission-critical features, regulated domains, long-lived foundations |

Each flavor specifies:

- **Name + approach summary** (1-2 paragraphs)
- **Architectural pattern** (e.g., layered + repository pattern; engine + data; event-sourced; microservices; serverless)
- **Quality features considered** (which lenses apply, which are deferred)
- **Effort estimate** (relative SP band)
- **Reversibility cost** (how easy/expensive to migrate to a different flavor later)
- **Trade-offs** (explicit upside + downside)
- **Mermaid diagram** (1 per flavor; embedded inline OR linked in `design-analysis-diagrams/<flavor>.mmd`)
- **Recommended-for context** (when this flavor is the right pick)

The Crew is REQUIRED to produce all flavors that are genuinely distinct. If only 2 are meaningfully different, ship 2 (not 3 with a contrived third). If 3rd flavor adds no real choice, the Crew states this explicitly.

Optional 4th flavor: **D: Idiomatic-for-stack** — when the detected stack has a strongly idiomatic pattern that doesn't map cleanly to simplest/reasonable/by-the-book (e.g., Erlang/OTP supervisor trees, Smalltalk image-based, BEAM hot-code-loading); ship D when relevant.

### Pillar 3: `design-analysis.md` artifact + diagram subdirectory (~3-4 SP)

New artifact at `specs/<F>/iterations/<NNN>/design-analysis.md` (per-iteration; some iterations may rely on prior iteration's analysis if applicable):

```text
specs/<F>/iterations/<NNN>/
├── design-analysis.md                       # the analysis itself
└── design-analysis-diagrams/                 # mermaid files per flavor
    ├── A-simplest.mmd
    ├── B-reasonable.mmd
    ├── C-by-the-book.mmd
    └── chosen.mmd                            # symlink/copy of chosen flavor's diagram (populated post-decision)
```

`design-analysis.md` structure:

```markdown
# Design Analysis — Feature <F> / Iteration <NNN>

## Problem framing

(1-2 paragraphs distilled from spec.md User Stories + clarify outcomes — what we're solving + key constraints)

## Decision points

(numbered list of substantive architectural decisions this iteration must make — e.g., "(1) storage layer: in-memory vs SQLite vs Postgres", "(2) intake-logic shape: inline vs engine + data", "(3) UI rendering: SSR vs CSR vs static")

## Alternatives

### Option A: Simplest — <approach-name>

**Approach**: <1-2 paragraph summary>
**Architectural pattern**: <pattern name>
**Quality features**: <list>
**Effort estimate**: <SP band>
**Reversibility cost**: <Low/Medium/High>
**Trade-offs**:
- (+) <upside>
- (−) <downside>
**Recommended for**: <context>
**Diagram**: file:///<path>/design-analysis-diagrams/A-simplest.mmd

### Option B: Reasonable — <approach-name>

(same structure)

### Option C: By the book — <approach-name>

(same structure)

## Crew recommendation

(Crew picks ONE option as recommended; states reasoning in 2-3 paragraphs covering the decision points; identifies any condition under which the recommendation would flip)

## Human decision

(Populated AFTER verdict)
- **Chosen option**: <A | B | C | other>
- **Reason**: <human's reasoning>
- **Modifications**: <any tweaks to the chosen option's scope>
- **Decided at commit**: <hash>
```

The artifact lives forever as the durable record of why the iteration's design was chosen. Future maintainers reading `specs/<F>/` can answer "why did they build it this way" by reading this single file.

### Pillar 4: Crew recommendation + human verdict integration (~2-3 SP)

The Crew is REQUIRED to **recommend** one of the alternatives (not just present neutrally). Reasoning:

- Neutral presentation pushes decision burden entirely onto the human; defeats the purpose
- The Crew has more context (just-completed clarify, repo signals, applicable quality lenses); should leverage that
- Recommendation forces the Crew to articulate WHY one option fits this context — which is often the most useful part of the artifact

Default recommendation rules:

- **Default to B (Reasonable)** unless context strongly favors A or C
- Recommend A when: time-pressure context, throwaway/prototype intent, OR when reversibility is clearly high (cheap to upgrade later)
- Recommend C when: regulated domain (healthcare/fintech), security-critical surface, long-lived foundation, OR when reversibility cost is clearly low (hard to upgrade later)
- Recommend D (when applicable) when: stack idiomatic pattern is strongly aligned with the problem AND the team is fluent in that pattern

Human verdict format: `approved for plan with Option <X>` (where X = A | B | C | D | modified-A | modified-B | etc.).

If the human modifies a chosen option's scope ("Option B but skip the cache layer"), the modification gets recorded in the **Human decision** section + becomes the basis for plan generation.

If the human rejects all options: `rejected for design-analysis` + named gap; Crew refines or proposes new alternatives.

### Pillar 5: Multi-host `/speckit.design-analysis` slash command (~5-7 SP)

New slash command following F-021 multi-host deployment pattern:

- `.claude/skills/speckit-design-analysis.md`
- `.github/skills/speckit-design-analysis.md`
- `.agents/skills/speckit-design-analysis.md`

Plus the agent/prompt/workflow files following Spec Kit conventions:

- `.github/prompts/speckit.design-analysis.prompt.md`
- `.github/agents/speckit.design-analysis.agent.md`
- `.specify/workflows/speckit/workflow.yml` (new step inserted between clarify and plan)
- `.specify/extensions.yml` (new `before_design_analysis` + `after_design_analysis` hooks; Specrew adds `specrew-speckit.sync-design-analysis` to after-hook for boundary state)

Specrew's `extensions/specrew-speckit/scripts/` gains:

- `specrew-speckit.before-design-analysis.ps1` — readiness check before analysis (clarify must be complete; slice-type detection)
- `specrew-speckit.sync-design-analysis.ps1` — boundary state persistence after analysis (records chosen option in `.specrew/boundary-state.json` or equivalent)

Slice-type aware: chore/small-fix/bug-fix/doc-only slices skip the gate per Proposal 055 catalog. Substantive slices (new-feature, refactor with architectural change, enabler) require it.

### Pillar 6: Validator integration + boundary enforcement (~3-5 SP)

Validator rule at `extensions/specrew-speckit/scripts/validate-governance.ps1` (mirrored to `.specify/`):

For each iteration meeting the slice-type applicability rule:

1. Verify `specs/<F>/iterations/<NNN>/design-analysis.md` exists + non-empty
2. Verify it contains at minimum 2 alternative sections (Options A + B)
3. Verify each alternative has all required fields (approach, pattern, quality features, effort, reversibility, trade-offs, diagram link, recommended-for)
4. Verify `design-analysis-diagrams/` subdirectory exists + contains 1 mermaid file per alternative + each is non-empty + parses as valid Mermaid
5. Verify the **Crew recommendation** section is populated (not placeholder)
6. Verify the **Human decision** section is populated BEFORE plan boundary can advance (committed-hash + chosen option + reason)
7. Phased rollout: WARN at iter-1 of Pillar 6 deployment; promote to FAIL at iter-2 (gated to avoid breaking in-flight features)

Boundary enforcement: `before-plan` boundary cannot complete (and `plan` cannot start) unless design-analysis verdict has been recorded. This is the structural enforcement that converts the gate from prose-discipline to runtime-discipline. Composes with Proposal 105 (host-native hook deployment) for `PreToolUse` enforcement.

## How

Multi-iteration feature, ~28-40 SP. Suggested iteration breakdown:

| Iter | Scope | SP |
|---|---|---|
| 1 | Pillars 1+3: lifecycle boundary insertion + `design-analysis.md` artifact format + diagram-subdirectory structure + scaffolder updates | 7-10 |
| 2 | Pillar 2: 3-flavor template + default recommendation rules + optional D-flavor for stack-idiomatic patterns | 6-9 |
| 3 | Pillars 4+5: Crew recommendation + human verdict shape + multi-host slash command deployment + agent/prompt/workflow + boundary state persistence | 8-12 |
| 4 | Pillar 6: validator rule + phased WARN→FAIL rollout + integration with Proposal 105 PreToolUse enforcement | 7-9 |

Splittable. Pillars 1+2+3 (lifecycle boundary + template + artifact) could ship as a smaller initial slice (~15-22 SP) leaving Pillars 4+5+6 (recommendation enforcement + slash command + validator) for follow-up — but Pillar 4 (Crew recommendation) is the empirically most valuable piece, so prefer NOT to defer it.

Alternative splitting: Pillars 1+3+4 ships the minimal viable gate (~12-17 SP); Pillars 2+5+6 ship as quality/enforcement follow-up (~16-23 SP).

## Acceptance criteria

- **AC1**: `specs/<F>/iterations/<NNN>/design-analysis.md` artifact exists for substantive iterations per Proposal 055 slice-type catalog
- **AC2**: New lifecycle boundary `design-analysis` inserted between clarify (or Specrew's before-plan extension) and plan; verdict shape `approved for plan with Option <X>`
- **AC3**: 3-flavor template (simplest/reasonable/by-the-book) ships with applicability rules; optional D-flavor for stack-idiomatic patterns
- **AC4**: Each alternative includes approach + pattern + quality features + effort + reversibility + trade-offs + Mermaid diagram link + recommended-for context
- **AC5**: Crew recommendation section is populated (not placeholder); default recommendation rules ship as documented
- **AC6**: Human decision section recorded BEFORE plan boundary can advance; committed-hash + chosen option + reason captured
- **AC7**: `/speckit.design-analysis` slash command deploys to `.claude/skills/`, `.github/skills/`, `.agents/skills/` per F-021 pattern; agent/prompt/workflow files present per Spec Kit conventions
- **AC8**: Validator rule (Pillar 6) detects missing design-analysis artifact + missing alternatives + missing recommendation + missing human decision per applicability rules
- **AC9**: Slice-type-aware applicability: chore/small-fix/bug-fix/doc-only slices skip the gate; substantive slices require it
- **AC10**: Integration tests cover applicability rules + 2-flavor minimum + diagram validation + recommendation population + human verdict propagation to plan
- **AC11**: Backward compatibility: in-flight features at clarify boundary at deployment time get a phased migration path (existing-feature opt-in for one iteration before WARN→FAIL promotion)

## Out of scope

- **Forcing specific architectural patterns** (microservices vs monolith vs serverless) — this proposal enforces COMPARISON of alternatives; choice remains per-project + per-context
- **Auto-generating Mermaid diagrams from code** — Crew authors diagrams during analysis; UML-from-source is future Proposal scope (related to Proposal 025 JIT codebase cartography)
- **Cross-feature design-alternatives view** — this proposal scopes per-iteration analysis; cross-feature architectural narrative remains the feature-level diagrams scope (Proposal 135 Pillar 5)
- **Replacing `/speckit.analyze`** — Spec Kit's analyze still runs at its current position (post-tasks consistency check); this proposal is orthogonal and additive
- **Implicit alternative detection** — Crew explicitly authors alternatives; future "detect implicit design forks during clarify" remains scope for a separate proposal (related to Proposal 015 expertise-aware adaptive interaction)
- **Automated reversibility-cost calculation** — Crew estimates qualitatively (Low/Medium/High); quantitative reversibility-cost modeling is future scope

## Composition

| Proposal | Relationship |
|---|---|
| **Proposal 011 (Architecture Intent Checkpoint)** | Direct ancestor — 011 proposes an 8th boundary inside `/speckit.plan` for architecture discussion; THIS proposal extends 011 from "single-design discussion" to "multi-alternative comparison" + moves the boundary EARLIER (before plan, not inside plan) |
| **Proposal 053 (Autopilot Decision Transparency)** | Direct synergy — this gate is where the transparency conversion HAPPENS. Autopilot dies at this boundary because every substantive design decision is surfaced as a multi-option pick. 053 + 137 = no silent design decisions |
| **Proposal 063 (Substantive Intake Questioning)** | Direct sibling — 063 asks about WHAT to build (clarify-phase); 137 asks about HOW to build (design-analysis-phase). Both lift methodology rigor at lifecycle boundaries. Compose perfectly |
| **Proposal 081 (Reviewer Visual Evidence — Mermaid Mandate)** | Diagram convention from 081 reuses here; design-analysis diagrams compose with review diagrams (same rendering tech) |
| **Proposal 121 (Review-Diagrams Mermaid Template Hardening)** | Mermaid template patterns from 121 apply to design-analysis diagrams (Pillar 2 each-alternative diagram requirement) |
| **Proposal 128 (Decomposition-Strategy Clarify Question)** | Adjacent — 128 surfaces decomposition strategy at clarify; THIS surfaces design alternatives at NEW boundary. 128 informs which decomposition the alternatives align with (e.g., walking-skeleton vs layered) |
| **Proposal 135 (Per-User-Story Multi-View Design Diagrams)** | Composes naturally — 135 fleshes out diagrams for the CHOSEN design as plan input; 137 surfaces alternatives BEFORE one is chosen. 137 + 135 = full design-rigor pipeline |
| **Proposal 055 (Slice-Type Catalog)** | Applicability driver — slice-type catalog determines which slices require design-analysis vs skip; chore/small-fix/bug-fix/doc-only skip; substantive slices require |
| **Proposal 105 (Host-Native Hook Deployment)** | Direct enforcement layer — `PreToolUse` hooks on plan-boundary can mechanically enforce design-analysis-verdict-required-first |
| **Proposal 052 (Specrew Profile System)** | Profile overrides — strict-quality profile may force C-flavor for all iterations; rapid-prototype profile may allow A-flavor default. Profile-aware applicability per 052 architecture |
| **Proposal 047 (Project Governance Profile)** | Project-level overrides — per-project default recommendation rules (e.g., "always default to C for this regulated-domain project") |
| **Proposal 120 (5-Pillar Bypass Detection) Pillar 5** | Same family — both verify the audit-trail matches reality; 120 Pillar 5 = file-tree verification, this proposal = decision-record verification |
| **Memory `[[project-dilemma-surfacing-protocol-proposal-candidate-2026-05-27]]`** | This proposal IS the concrete formalization of the dilemma surfacing protocol concept. Memory entry becomes obsolete on this proposal's promotion |
| **Memory `[[project-plan-time-dependency-intent-proposal-candidate-2026-05-27]]`** | Adjacent — dependency-intent artifact composes with this gate (dependency choices surface as part of alternatives' "approach" + "quality features" sections) |
| **Proposal 039 (Squad Upstream Reconciliation)** | Strategic — this proposal is a candidate for Spec Kit upstream contribution; Spec Kit lifecycle currently has no equivalent. Open dialog with Brady Gaster channel per `[[reference-brady-gaster-squad-inventor-2026-05-25]]` |

## Strategic upside

Since Spec Kit doesn't have this — and the Brady Gaster channel is open per `[[reference-brady-gaster-squad-inventor-2026-05-25]]` — Proposal 137 becomes a **dual-purpose ship**:

- **Specrew differentiation**: real methodology innovation, not "spec-kit with extra ceremony"
- **Spec Kit upstream contribution candidate**: same pattern as Proposal 039 (Squad upstream reconciliation); Brady's positive reception of Specrew + connection to Spec Kit team makes this a natural conversation topic once F-051 ships empirical evidence

Brady was interested in Specrew as "a nice evolution of spec-kit". Proposal 137 is exactly the kind of evolution that's interesting to upstream.

## Risks

- **Gate burden** — adding a new mandatory boundary may feel heavy for small iterations. Mitigation: slice-type-aware applicability (Proposal 055 catalog) skips trivial slices; substantive slices get the gate
- **Crew may produce shallow alternatives** — risk that the Crew lists 3 superficially different options without substantive distinction. Mitigation: Pillar 6 validator requires non-trivial differences in quality-features + reversibility-cost sections; Reviewer charter discipline at review-signoff verifies the chosen option matches what was built
- **Human decision burden** — requiring human verdict at every substantive iteration adds approval load. Mitigation: Crew recommendation defaults to B (Reasonable) so quick-approval is the common path; human only needs to dig in when they disagree with the recommendation
- **Diagram authoring overhead** — Crew must produce N Mermaid diagrams per iteration. Mitigation: diagrams can be lightweight (component sketch, sequence flow); not required to be production-grade. Compose with Proposal 135 if AFTER-plan diagram fleshing is owned by 135
- **Phased-rollout transition pain** — in-flight features at clarify boundary at deployment time. Mitigation: AC11 explicit migration path; WARN→FAIL phased rollout
- **Slice-type misclassification** — small-fix that should have been substantive escapes the gate. Mitigation: Reviewer charter at review-signoff has authority to flag slice-type misclassification + retroactively require design-analysis if scope is found to be larger than declared

## Acceptance signals (operational)

- **Signal 1**: Empirically measure scope-expansion-via-design-conversation events per feature. F-049 had 3; target ≤0.5 average per feature post-Proposal 137 ship
- **Signal 2**: Plan-boundary rejection rate for "wrong design choice" should drop materially after Proposal 137 deploys (alternatives surfaced upstream catch the disagreement earlier)
- **Signal 3**: Iteration capacity overrun rate for "scope grew during plan" should drop (design-analysis surfaces architectural scope before plan locks in tasks)
- **Signal 4**: Maintainer reading `specs/<F>/iterations/<NNN>/design-analysis.md` 6 months later can answer "why did we build it this way" in one read
- **Signal 5**: External adopters cite "structured design alternatives gate" as a Specrew differentiator vs vanilla spec-driven tools

## Status history

- 2026-05-27: candidate proposal drafted as part of F-049 iter-3 design conversation. Empirical motivation: 3 scope-expansion-via-design-conversation events in single F-049 session + 4+ prior empirical instances (PlanningPoC iter-001 Aspose silent choice, WSL trial autopilot, Gym test 2-pause intake, PlanningPoC iter-006 ACadSharp silent swap, multiple Antigravity over-claim incidents). Six pillars: new lifecycle boundary + 3-flavor template + design-analysis.md artifact + Crew recommendation + multi-host slash command + validator enforcement. ~28-40 SP, 4 iterations, splittable. Verified vs Spec Kit upstream: `/speckit.analyze` is NOT a design-analysis gate (post-tasks consistency check); Spec Kit has no equivalent; Proposal 137 is upstream-contribution candidate per Proposal 039 pattern.

## Cross-references

- **Empirical motivation**: F-049 iter-3 + iter-4 scope expansions 2026-05-27/28 (3 events in single session); PlanningPoC iter-001 + iter-006; WSL trial; Gym test; Antigravity over-claim incidents
- file:///C:/Dev/Specrew/proposals/011-architecture-intent-checkpoint.md — direct ancestor
- file:///C:/Dev/Specrew/proposals/053-autopilot-decision-transparency.md — direct synergy
- file:///C:/Dev/Specrew/proposals/063-substantive-intake-questioning.md — direct sibling
- file:///C:/Dev/Specrew/proposals/081-reviewer-visual-evidence.md — diagram convention
- file:///C:/Dev/Specrew/proposals/121-review-diagrams-mermaid-template-hardening.md — Mermaid template patterns
- file:///C:/Dev/Specrew/proposals/128-decomposition-strategy-clarify-question.md — adjacent at clarify boundary
- file:///C:/Dev/Specrew/proposals/135-per-user-story-multi-view-design-diagrams.md — composes for AFTER-plan diagram fleshing
- file:///C:/Dev/Specrew/proposals/055-always-in-flow-bug-fix-lifecycle.md — slice-type applicability driver
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md — direct enforcement layer
- file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md — profile overrides
- file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md — project-level overrides
- file:///C:/Dev/Specrew/proposals/120-handoff-block-validator-enforcement.md — same audit-trail-vs-reality family
- file:///C:/Dev/Specrew/proposals/039-squad-upstream-reconciliation.md — Spec Kit upstream contribution pattern
- Memory: [[project-dilemma-surfacing-protocol-proposal-candidate-2026-05-27]] (formalized by this proposal)
- Memory: [[project-plan-time-dependency-intent-proposal-candidate-2026-05-27]] (composes)
- Memory: [[reference-brady-gaster-squad-inventor-2026-05-25]] (strategic upstream channel)
- Spec Kit upstream verification: file:///C:/Dev/Specrew/.github/agents/speckit.analyze.agent.md (confirms `/speckit.analyze` is post-tasks consistency check, not design-analysis gate)
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
