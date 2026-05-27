---
proposal: 135
title: Per-User-Story Multi-View Design Diagram Coverage (Static + Dynamic + Data + Deployment)
status: candidate
phase: phase-2
estimated-sp: 15-25
priority-tier: 2
discussion: empirically motivated 2026-05-27 by user observation across multiple feature reviews — current `review-diagrams.md` artifacts typically contain only 1-2 diagrams (single view, often just one static OR one flow), insufficient for comprehensive design visibility. Needed: every significant user story implemented in an iteration should have its applicable multi-view diagram set (structural + behavioral + data + deployment where relevant), BEFORE implementation (planning artifact) AND AFTER implementation (per-iteration state), PLUS cross-iteration consolidated design view (out-of-iteration). Composes with Proposal 012 (Visual Artifact Extension — Pillar 4 of interaction model), Proposal 121 (Review-Diagrams Mermaid Template Hardening — Mermaid is the rendering tech), Proposal 011 (Architecture Intent Checkpoint — natural integration point), Proposal 030 (Quality Hardening Bundle — form-vs-meaning: "has diagrams" vs "has the RIGHT diagrams"), Proposal 063 (Substantive Intake Questioning — sibling capability lifting methodology rigor at lifecycle boundaries).
---

# Per-User-Story Multi-View Design Diagram Coverage

## Why

Current state (empirically observed across F-045 → F-049 review cycles 2026-05-26/27 and prior dogfooding): the `iterations/<N>/review-diagrams.md` artifact typically contains **one or two diagrams** — usually a single static (component) view OR a single dynamic (sequence/flow) view, sometimes both, rarely the full multi-view design picture a non-trivial feature warrants.

A reviewer reading `review-diagrams.md` today often gets:

- ONE class/component diagram showing "the new code structure"
- (sometimes) ONE sequence diagram showing "the main flow"
- (rarely) anything else

This is insufficient for design visibility:

- **Static-only view** hides the behavioral interactions — reader can see what classes exist but not how they collaborate
- **Dynamic-only view** hides the structural shape — reader can see the message flow but not what owns what state
- **No data layer view** when iterations touch persistence — reader has no ERD or schema diagram for new entities, relationships, or migrations
- **No deployment view** for microservice / cross-process / cross-host iterations — reader can't see the runtime topology
- **No per-user-story granularity** — when an iteration implements 3 user stories, having ONE combined diagram conflates concerns instead of letting the reader navigate per-story

User direction (2026-05-27):

> "When I am reviewing the architecture, especially with the diagram, I see usually one or two diagrams. It is nice but not enough. We need to have the two view of the system components: i.e classes/services (static view) and flows (dynamic view), and for DB - an ERD or similar diagram. Other diagrams such as deployment (for micro services for example) can also be useful. When looking at the current diagrams we usually have one or two static/flow diagrams and that it. We need to look at all significant user stories in the spec, see which one implemented in the iteration and provide all the required design diagrams - before implementation, and out of iterations, the combined iterations diagram after the implementation."

### What's missing structurally

| Dimension | Current | Needed |
|---|---|---|
| **View types** | Often 1 (static OR dynamic) | 4 canonical views (static + dynamic + data + deployment) — applicability-driven |
| **Per-story granularity** | Iteration-level combined diagrams | Per-significant-user-story diagram set within the iteration |
| **Timing** | After-the-fact review artifact | BEFORE-implementation (design-drives-code) AND AFTER-implementation (state-of-the-design) |
| **Cross-iteration view** | None | Out-of-iterations consolidated design view that combines all per-iteration changes into a coherent system-level picture |
| **Applicability rules** | Implicit — Reviewer decides what to include | Explicit per-iteration triggers (touches persistence → ERD required; touches infra → deployment required; etc.) |

### Why this matters now

Specrew's value proposition is **spec-governed AI-coded software** with full lifecycle audit trail. The audit trail is incomplete if the design layer is sparse:

- Downstream maintainers reading `specs/<F>/` later cannot reconstruct the design intent from 1-2 diagrams
- Cross-feature dependencies are invisible without cross-iteration consolidation
- The "review" boundary is impoverished — the Reviewer sees only the static or dynamic slice, never both, never the data, never the deployment
- Pre-implementation design discipline (the "think before you code" loop the methodology promises) is absent when diagrams are written AFTER the fact

External users adopting Specrew get a methodology that sells deep design rigor but ships shallow diagram artifacts. Closing this gap is methodology-critical for the external-tester window opening ~Sept 2026.

## What — Six Pillars

### Pillar 1: Canonical diagram-view taxonomy (~1-2 SP)

Define the four canonical view types Specrew expects, with applicability rules:

| View | Mermaid diagram type | When required | Optional alternatives |
|---|---|---|---|
| **Static / Structural** | `classDiagram`, `flowchart` (component shape), `C4Component` (where supported) | Any iteration implementing user-facing code or service boundaries | UML class, component, package |
| **Dynamic / Behavioral** | `sequenceDiagram`, `flowchart` (process shape), `stateDiagram-v2` | Any iteration with multi-step user interactions OR multi-component collaboration | UML sequence, activity, state machine |
| **Data** | `erDiagram` | Iteration touches persistence layer (entities, repositories, schema migrations) | UML class with stereotype `<<entity>>`, PlantUML ERD |
| **Deployment** | `flowchart` (deployment shape), `C4Deployment` (where supported) | Iteration touches infrastructure, multi-process, microservice topology, host boundaries | UML deployment, infrastructure-as-code visualization |

Applicability is derived mechanically from iteration scope:

- Iteration tasks tagged with file paths in `backend/` + `Entities/` / `Repositories/` / `Migrations/` → ERD required
- Iteration tasks tagged with file paths in `infra/` / `deployment/` / `helm/` / `docker-compose*` → deployment required
- Default Static + Dynamic required for any non-trivial iteration
- Doc-only / refactor-only iterations (per Proposal 055 slice catalog) have lighter requirements

Taxonomy file ships at `extensions/specrew-speckit/data/diagram-view-taxonomy.yml` so future hosts / new view types can be added per-project or per-profile (composes with Proposal 052 Profile System).

### Pillar 2: Per-user-story design artifact organization (~3-5 SP)

Restructure design artifacts from single `iterations/<N>/review-diagrams.md` to per-user-story sub-organization:

```text
specs/<F>/iterations/<N>/diagrams/
  index.md                          # navigation surface listing all per-story design files
  US1-<short-slug>/
    structural.md                   # static view(s)
    behavioral.md                   # dynamic view(s)
    data.md                         # ERD (if applicable)
    deployment.md                   # deployment view (if applicable)
  US2-<short-slug>/
    structural.md
    behavioral.md
  US3-<short-slug>/
    structural.md
    behavioral.md
    data.md
```

Existing `review-diagrams.md` deprecates to `diagrams/index.md` (navigation surface) plus per-story sub-files. Backward compatibility: `review-diagrams.md` continues to be accepted for legacy iterations; new iterations use the directory structure.

The structure makes it mechanically obvious which user stories have insufficient design coverage — if `US3/structural.md` is missing or skeleton-only, validator flags it.

### Pillar 3: BEFORE-implementation design checkpoint (~3-4 SP)

Add a design checkpoint to the planning lifecycle (composes with Proposal 011 Architecture Intent Checkpoint — that proposal proposes an 8th boundary inside `/speckit.plan`; this proposal proposes the artifact emitted at that checkpoint):

- At `/speckit.plan` boundary (after the iteration plan exists but BEFORE `before-implement`), the Planner produces the per-user-story design diagrams
- These are PLANNING artifacts — they may be revised during implementation, but the initial commit represents design intent BEFORE code is written
- Diagrams committed at this boundary land at `specs/<F>/iterations/<N>/diagrams/` (same location as Pillar 2)
- The `before-implement` boundary verdict cannot be issued by the human if any required per-US diagram is missing

This implements the methodology promise of "think before you code" via the lifecycle gate. Without this pillar, diagrams remain after-the-fact artifacts and the design discipline is purely cosmetic.

### Pillar 4: AFTER-implementation design refresh (~2-3 SP)

After implementation completes (at `review-signoff` boundary), the Reviewer is responsible for updating the per-US diagrams to match the actually-implemented design.

- Diagrams updated in-place at `specs/<F>/iterations/<N>/diagrams/<US-slug>/`
- Diff between BEFORE-implementation diagrams (Pillar 3) and AFTER-implementation diagrams (Pillar 4) becomes an implicit drift record (composes with `drift-log.md` artifact)
- Reviewer charter requires verification that diagrams reflect committed code, not just planned code (Pillar 5 of Proposal 120 — `git ls-tree` verification of cited files — extends naturally here: Reviewer verifies diagram-referenced class names / file paths exist in HEAD)

### Pillar 5: Out-of-iteration cross-iteration consolidated view (~3-5 SP)

After each iteration closes, the iteration-level diagrams get consolidated into a feature-level cross-iteration view at `specs/<F>/diagrams/` (feature-level, out of any iteration):

```text
specs/<F>/diagrams/
  index.md                          # navigation: which user stories landed in which iterations
  combined-structural.md            # cross-iteration static view (all USes shipped to-date)
  combined-behavioral.md            # cross-iteration dynamic view (key flows across all USes)
  combined-data.md                  # cross-iteration ERD (all entities + relationships shipped)
  combined-deployment.md            # cross-iteration deployment (if applicable)
  evolution.md                      # how the design evolved iteration-to-iteration (delta narrative)
```

Cross-iteration consolidation runs at iteration-closeout boundary as a tooling step (composes with `sync-boundary-state.ps1` and dashboard-render machinery). Automated where possible (e.g., merge structural diagrams by combining class lists, dedup, layout); human-curated where automation fails (delta narrative, evolution.md).

Cross-iteration view IS the feature-level architecture artifact — the thing a maintainer reads to understand "what does this feature look like architecturally" without needing to read every per-iteration diagram set.

### Pillar 6: Validator enforcement + Reviewer charter discipline (~3-5 SP)

**Validator rule** at `extensions/specrew-speckit/scripts/validate-governance.ps1` (mirrored to `.specify/`):

For each iteration containing implementer tasks (excluding doc-only / refactor-only per Proposal 055 slice-type):

1. Parse spec.md for user stories (lines matching `### User Story \d`)
2. Determine which US's are in scope of the current iteration (cross-reference tasks.md `Trace:` columns for `US\d` references)
3. For each in-scope US:
   - Verify `specs/<F>/iterations/<N>/diagrams/US<N>-<slug>/structural.md` exists + non-empty Mermaid `classDiagram` / `flowchart` / `C4Component` block
   - Verify `specs/<F>/iterations/<N>/diagrams/US<N>-<slug>/behavioral.md` exists + non-empty Mermaid `sequenceDiagram` / `flowchart` / `stateDiagram-v2` block
   - If iteration touches persistence: verify `data.md` exists + non-empty `erDiagram` block
   - If iteration touches infra: verify `deployment.md` exists + non-empty deployment-shape block
4. Emit WARN per missing diagram during iter-1 of Pillar 6 rollout; promote to FAIL at iter-2 (gated rollout to avoid breaking in-flight features)

**Reviewer charter discipline** (composes with Proposal 121 Mermaid hardening + Proposal 120 Pillar 5 file-tree verification):

- Reviewer MUST verify diagrams are SUBSTANTIVE (non-placeholder, non-skeleton, actually describing the implemented design)
- Reviewer MUST cite specific diagrams + per-US sections in review.md evidence
- Reviewer cannot issue `accepted` verdict if any required per-US diagram is missing OR is placeholder-only

## How

Multi-iteration feature, ~15-25 SP. Suggested iteration breakdown:

| Iter | Scope | SP |
|---|---|---|
| 1 | Pillars 1+2: diagram-view taxonomy + per-US directory structure + scaffolder updates (extends `scaffold-reviewer-artifacts.ps1` to produce per-US diagram skeletons); backward-compat for legacy `review-diagrams.md` | 5-7 |
| 2 | Pillars 3+4: BEFORE-implementation Planner-emitted diagrams gating before-implement boundary + AFTER-implementation Reviewer-updated diagrams at review-signoff; charter directives | 5-8 |
| 3 | Pillars 5+6: cross-iteration consolidation tooling + validator rule for completeness check + Reviewer charter discipline for substantive-diagram verification | 5-10 |

Splittable. Pillars 1+2+6 (taxonomy + per-US structure + validator) could ship as a smaller initial slice (~10-15 SP) leaving Pillars 3+4+5 (BEFORE/AFTER timing + cross-iteration view) for follow-up.

## Acceptance criteria

- **AC1**: `extensions/specrew-speckit/data/diagram-view-taxonomy.yml` exists with 4 canonical view types + applicability rules + Mermaid-type defaults
- **AC2**: New iterations use per-US sub-directory structure at `specs/<F>/iterations/<N>/diagrams/US<N>-<slug>/`; `scaffold-reviewer-artifacts.ps1` produces skeleton files per US
- **AC3**: Legacy `review-diagrams.md` continues to validate without error (backward-compat); validator emits informational message recommending per-US migration
- **AC4** (Pillar 3): Planner produces per-US design diagrams at `/speckit.plan` boundary; `before-implement` boundary cannot be issued if any required diagram is missing or skeleton-only
- **AC5** (Pillar 4): Reviewer updates per-US diagrams at `review-signoff` boundary to match implemented design; charter directive requires `git ls-tree` verification that diagram-referenced class/file names exist in HEAD
- **AC6** (Pillar 5): `specs/<F>/diagrams/` consolidated view auto-generated at iteration-closeout; combines per-US diagrams from all iterations; `evolution.md` captures delta narrative
- **AC7** (Pillar 6): Validator detects missing required diagrams per applicability rules; phased WARN→FAIL rollout
- **AC8**: Reviewer cannot issue `accepted` verdict when any required per-US diagram is missing or placeholder-only (charter directive + validator gate)
- **AC9**: Integration tests cover: applicability rules correctly trigger required diagrams; backward-compat with legacy `review-diagrams.md`; cross-iteration consolidation produces valid merged Mermaid

## Out of scope

- Auto-generating diagrams from code (UML-from-source) — too host-and-language-specific; future Proposal
- Rendering pipeline beyond Mermaid (PlantUML, Graphviz, etc.) — Proposal 121 owns the rendering tech; this proposal builds on whatever Mermaid-or-successor 121 establishes
- Diagram review platforms / interactive editors — markdown-rendered Mermaid is the deliverable surface; richer tooling is future work
- Specific architecture style enforcement (microservices vs monolith vs serverless) — this proposal enforces COMPLETENESS of design artifacts, not style choice; style choice is per-project + per-Proposal 052 profile

## Composition

| Proposal | Relationship |
|---|---|
| **Proposal 012 (Visual Artifact Extension)** | Direct parent. 012 Pillar 4 of the interaction model establishes that Specrew has visual artifacts as first-class lifecycle outputs; THIS proposal specifies WHAT those artifacts must contain (multi-view, per-US, before+after, cross-iteration) |
| **Proposal 121 (Review-Diagrams Mermaid Template Hardening)** | Small-fix-slice that established Mermaid as the rendering tech for review-diagrams + Reviewer charter mandate. THIS proposal extends 121 from "use Mermaid" to "use Mermaid in a comprehensive multi-view structure per user story." Possible bundle: 121 + 135 ship together as the diagram-quality bundle |
| **Proposal 011 (Architecture Intent Checkpoint)** | 011 proposes an 8th boundary inside `/speckit.plan` for architecture discussion; THIS proposal specifies the diagram artifacts emitted at that checkpoint. 011 + 135 Pillar 3 + 135 Pillar 6 form a complete "design before code" gate |
| **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning)** | Diagram completeness is form-vs-meaning: "review-diagrams.md exists" passes form; "review-diagrams.md has the 4 canonical views per US" is the meaning check. Pillar 6 validator rule fits naturally inside 030's form-vs-meaning surface |
| **Proposal 063 (Substantive Intake Questioning)** | Sibling capability — 063 lifts intake rigor; 135 lifts design rigor. Both improve methodology depth at lifecycle boundaries. Composable; ship independently |
| **Proposal 120 (5-Pillar Bypass Detection) Pillar 5 (Reviewer file-tree verification)** | 120 Pillar 5 verifies cited files exist in cited tree; THIS proposal Pillar 4 extends to verify diagram-referenced class / file names exist in HEAD. Same family of "verify the claim matches the artifact" |
| **Proposal 052 (Specrew Profile System)** | Diagram-view taxonomy ships per-project in profile-aware way — e.g., `monolith-profile` may not need deployment view; `microservices-profile` always needs it. Profile overrides per Proposal 052 architecture |
| **Proposal 075 (Update Artifact Backfill Discipline)** | Legacy iterations without per-US diagrams need backfill mechanism; 075 owns the backfill discipline; THIS proposal defines what to backfill |
| **Proposal 055 (Slice-Type Catalog)** | Different slice types (bug-fix, refactor, doc-only) have different diagram requirements; applicability rules per Pillar 1 derive from slice-type catalog |

## Acceptance signals (operational)

Concrete success criteria for adoption:

- **Signal 1**: A fresh reader picking up a feature's `specs/<F>/diagrams/` index after closure can navigate to "what does User Story 3 look like architecturally" in one click
- **Signal 2**: Reviewer rejection rate for "diagram coverage insufficient" stabilizes near zero after Pillar 6 ships (the validator catches the gap upstream)
- **Signal 3**: Cross-iteration consolidated views are read at least once per feature post-closeout (instrumented via dashboard render count or similar)
- **Signal 4**: External users (post-2026-09 adopters) cite "rich design artifact coverage" as a Specrew differentiator versus vanilla AI-coding tools

## Status history

- 2026-05-27: candidate proposal drafted after user observation across F-045 → F-049 review cycles that `review-diagrams.md` artifacts typically contain only 1-2 diagrams (insufficient multi-view coverage). Six pillars: canonical view taxonomy + per-US directory structure + BEFORE-implementation Planner-emitted + AFTER-implementation Reviewer-updated + cross-iteration consolidation + validator/charter enforcement. ~15-25 SP, 3 iterations, splittable into smaller initial slice (Pillars 1+2+6 ~10-15 SP).

## Cross-references

- **Empirical motivation**: 2026-05-27 user direction across F-045 → F-049 review pattern
- file:///C:/Dev/Specrew/proposals/012-visual-artifact-extension.md — direct parent
- file:///C:/Dev/Specrew/proposals/011-architecture-intent-checkpoint.md — composes with Pillar 3 (BEFORE-implementation)
- file:///C:/Dev/Specrew/proposals/121-review-diagrams-mermaid-template-hardening.md — rendering tech foundation
- file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md — form-vs-meaning fit for Pillar 6 validator
- file:///C:/Dev/Specrew/proposals/063-substantive-intake-questioning.md — sibling capability
- file:///C:/Dev/Specrew/proposals/120-handoff-block-validator-enforcement.md — Pillar 5 verifies file-tree; this proposal Pillar 4 extends similar verification to diagram references
- file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md — profile-aware applicability per project
- file:///C:/Dev/Specrew/proposals/075-update-artifact-backfill-discipline.md — backfill for legacy iterations
- file:///C:/Dev/Specrew/proposals/055-always-in-flow-bug-fix-lifecycle.md — slice-type catalog drives applicability rules
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
