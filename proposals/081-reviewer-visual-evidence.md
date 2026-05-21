---
proposal: 081
title: Reviewer Visual Evidence — Multi-Type Diagrams + Explanatory Omissions + Mermaid Mandate
status: candidate
phase: phase-2
estimated-sp: 33-43
discussion: tbd
---

# Reviewer Visual Evidence — Multi-Type Diagrams + Explanatory Omissions

## Why

`review-diagrams.md` is supposed to give a reviewer a visual understanding of what changed in an iteration. Today it has two failure modes:

1. **Opaque omissions**: When the scaffolder decides a diagram isn't worth generating, it writes `_omitted_` with no explanation in the body. The reviewer has no idea whether the diagram was omitted because:
   - There was no relevant structural change (legitimate)
   - The change is below a hard-coded threshold (heuristic skip)
   - The change shape doesn't match any of the scaffolder's two diagram types (structure + flow only)
   - The scaffolder hit an error (silent failure)

2. **Narrow diagram catalog**: Only two diagram types exist (Structure, Flow), and both are based on inter-module edges and entrypoint changes. For most Specrew internal work — in-place enhancements, new helper functions, validator rule additions — neither applies. Result: review-diagrams.md is empty 80%+ of iterations.

### User direction (2026-05-21)

> "Diagrams are intended to enhance the reviewer capability to understand the system and the changes (like comparing a flow before and after). There is no point to provide diagrams if there was no change, but `__omitted__` is not an explanation why we do not see a diagram — so maybe we need to say that there is no significant change. So, again, diagrams and graphs are important when they are needed. New class hierarchy, new db schema, changes flow, emphasizing a what-if scenario, explaining component (classes, functions, services, ...) dependencies."

### Empirical motivation

F-028's own iteration 001 closeout (the feature that ships the reviewer-evidence integrity mechanism) demonstrated the gap concretely:

```markdown
## Structure Diagram
_omitted_

## Flow Diagram
_omitted_

## Omissions
- Structure diagram omitted: inter-module edges (0) below threshold (2).
- Flow diagram omitted: entrypoints changed (0) below threshold (1).
```

F-028 added a new helper function, a new validator rule, and a new flag — substantial changes — but received zero visual evidence because they were "in-place enhancements" that don't cross structure/flow thresholds. The reviewer had to read code to understand what was added; the visual surface gave nothing.

## What (5 Pillars, phased)

### Pillar 1: Explanatory Omissions (replaces `_omitted_` with clarity)

Whenever a diagram is not generated, the file states **why** in human-readable terms. Replace the universal `_omitted_` placeholder with one of these contexts:

| Context | Message in evidence file |
|---|---|
| No relevant change detected | `No <diagram-type> diagram: this iteration did not change <relevant-axis>` |
| Below significance threshold | `No <diagram-type> diagram: change scope is below significance threshold for this diagram type` |
| Not applicable to change shape | `No <diagram-type> diagram: this iteration's change shape (e.g., in-place enhancement) is better visualized as <suggested-alternative-diagram>` |
| Scaffolder error | `<diagram-type> diagram generation failed: <error-message>` (also logged to validator) |

The omission section at the bottom of `review-diagrams.md` becomes a structured table:

```markdown
| Diagram Type | Status | Reason |
|---|---|---|
| Structure | omitted | This iteration changes existing files in-place; no new modules added. |
| Flow | omitted | No new or changed entrypoints. |
| Class Hierarchy | rendered | See above. |
| Dependency Graph | omitted | No new imports/requires/using statements detected. |
| DB Schema | not applicable | No SQL/migration files in this iteration's diff. |
| Sequence (Before/After) | rendered | See above. |
```

### Pillar 2: Multi-Type Diagram Catalog

Add four new diagram types, in addition to the existing Structure + Flow:

| Diagram type | When to render | Mermaid form |
|---|---|---|
| **Class Hierarchy** | New `class X : Y` (C#), `class X(Y)` (Python), `extends Y` (Java/JS), `Inherits` (PowerShell), etc., detected in changed files | `classDiagram` with inheritance arrows |
| **Dependency Graph** | New `using` / `import` / `require` / `Add-Type` statements in changed files | `flowchart LR` with module-to-module arrows |
| **DB Schema** | New `CREATE TABLE` / `ALTER TABLE` in `*.sql` or migration files | `erDiagram` |
| **Sequence (Before/After)** | Control-flow change in a function (e.g., new conditional, new call path, removed branch) | Two `sequenceDiagram` blocks side-by-side or stacked |

Each detector is a language-aware regex pass over the changed files' diffs. Conservative: emit diagram ONLY when the detection is confident. Otherwise emit explanatory omission per Pillar 1.

### Pillar 3: Adaptive Selection Logic

The scaffolder runs all six detectors (Structure, Flow, Class Hierarchy, Dependency, DB Schema, Sequence) and emits the ones whose detection fires. The output evidence file always has all six headings (with rendered content or explanatory omission per Pillar 1) so reviewers know what was checked. Adaptive means: zero, one, or many diagrams render per iteration — driven by detection, not by hardcoded type.

### Pillar 4: Before/After Diff Diagrams for Flow Changes

When a control flow change is detected (sequence diagram type), emit BOTH the before-state and the after-state side-by-side. This is the highest-value diagram for reviewer comprehension — it lets the reviewer SEE the change as a delta rather than reading two versions of the same function and inferring the diff mentally.

Use cases:
- Adding/removing a conditional branch
- Adding a new call site to an existing function
- Adding a new failure path
- Replacing a sync call with an async call
- Adding a retry/backoff
- Replacing an inline check with a helper call

### Pillar 5: Reviewer "What to look at" Pointers

Each rendered diagram gets a one-line pointer above it telling the reviewer what to focus on:

```markdown
## Class Hierarchy

**Look at**: The new `Test-FormMeaningParity` helper now joins the
`shared-governance.ps1` module's existing parity helpers; confirm
naming + visibility conventions match the existing API surface.

```mermaid
classDiagram
   ...
```

This is metadata derived from change-detection results (e.g., "X new classes added", "Y dependencies added") plus the change's shape ("in-place enhancement to shared module", "new entrypoint added to public surface").

### Pillar 6: Mermaid-First Diagram Format Mandate

ALL Specrew artifacts that show visual or structural information MUST use `mermaid` fenced code blocks. Bare ` ``` ` fenced blocks are reserved for content that is genuinely code/text (CLI invocations, file contents, raw output, sample configurations) — they are FORBIDDEN as a wrapper for content that is diagrammatic in intent.

#### Empirical motivation (2026-05-21)

F-029's `specs/029-baseline-hygiene/iterations/001/review.md` lines 165-222 contains FOUR sections labeled "Happy Path," "Alternative Flow 1," "Alternative Flow 2," and "Error Flow." All four are wrapped in bare ` ``` ` fenced blocks with arrow-notation styling (`→ step X`). They LOOK like diagrams. They render in VS Code's markdown preview as monospace text. The maintainer opened the file expecting visual flow diagrams and got text.

This is the universal pattern this pillar mandates against.

#### Format evaluation

| Format | VS Code native | GitHub native | GitLab native | Verdict |
|---|---|---|---|---|
| **Mermaid** | ✅ since VS Code 1.79 (2023) | ✅ since 2022 | ✅ | **MANDATED** as primary |
| PlantUML | ❌ requires extension | ❌ | ❌ | Opt-in escape valve only via Proposal 047 governance dial |
| D2 | ❌ extension | ❌ | ❌ | Not approved |
| DOT / Graphviz | ❌ extension | ❌ | ❌ | Not approved |
| Excalidraw / draw.io | ❌ (GUI editors, embedded SVG/PNG) | ❌ | ❌ | Not approved as in-markdown diagram source |
| Bare ` ``` ` styled to look diagrammatic | Renders as monospace text only | Same | Same | **FORBIDDEN** for diagram-purpose content |

Mermaid is the only format that renders natively in VS Code AND GitHub AND GitLab without setup. Specrew artifacts are reviewed across all three surfaces; mandating a non-universal format would mean diagrams that render in one place but not another. PlantUML is more powerful for some specialized diagrams (deployment, complex sequences with notes, archimate-style architecture) but its extension-coupling makes it wrong as the default.

#### Required mermaid diagram-type mapping

Per content shape, the convention is:

| Content shape | Mermaid type | Used in |
|---|---|---|
| Actor-to-actor interactions over time | `sequenceDiagram` | review.md flows, spec.md user stories, retro.md cause-effect chains |
| Decision tree, conditional branching, algorithm flow | `flowchart TD` or `flowchart LR` | plan.md architecture, control-flow documentation |
| Inheritance, composition, type relationships | `classDiagram` | code-map.md, review-diagrams.md when classes change |
| Module-to-module dependencies | `flowchart LR` (or `graph LR`) | code-map.md, review-diagrams.md when imports/usings change |
| Database entities and relationships | `erDiagram` | spec.md data model, review-diagrams.md when schema changes |
| Lifecycle state machine | `stateDiagram-v2` | spec.md state transitions, retro.md status flows |
| Iteration / release timeline | `gantt` | iteration plans, release planning |
| Hierarchical decomposition | `mindmap` | retro.md cause-effect, decomposition exercises |

#### Where this applies in Specrew

This is NOT just a scaffolder rule. It applies to:

- Reviewer-authored content (`review.md`, `retro.md`, `closeout.md`) — the Reviewer and Retro Facilitator agents use mermaid blocks when showing flows/diagrams
- Scaffolder-generated content (`code-map.md`, `dependency-report.md`, `review-diagrams.md`, `coverage-evidence.md`) — the scaffolder emits mermaid, never bare diagram-styled text
- Spec author content (`spec.md`, `plan.md`, iteration plans) — humans + Spec Steward use mermaid blocks for any visual/structural information
- Proposal documents (`proposals/*.md`) — going forward, proposal authors (humans + LLMs) use mermaid blocks when showing flows
- User-facing documentation (`docs/user-guide.md`, `docs/getting-started.md`, etc.) — mermaid for any visual

#### Allowed bare ` ``` ` usage (not diagram-purpose)

The mandate does NOT forbid bare code blocks universally. They remain correct for:

- CLI invocations: ` ```powershell `, ` ```bash `, ` ```pwsh `, or bare ` ``` ` for shell sessions
- File content samples: configuration files, YAML/JSON snippets (` ```yaml `, ` ```json `, or bare ` ``` `)
- Raw command output (` ```text `)
- Code snippets
- Path lists in plain text

The distinction: **is the content's intent to convey visual structure or sequencing?** If yes → mermaid. If the intent is to convey literal text/code/commands → bare or language-tagged code block.

#### Governance enforcement

- Coordinator governance prompt gains a rule: "Any artifact that shows a flow, structure, hierarchy, dependency, schema, or state machine MUST use a mermaid fenced block of the appropriate type. Bare code blocks styled to look diagrammatic are forbidden."
- Reviewer charter gains: "When authoring flows in review.md or retro.md, use mermaid `sequenceDiagram`, `flowchart`, or appropriate type. Verify diagrams render in VS Code's markdown preview before claiming readiness."
- Spec Steward charter gains: "When the spec requires showing structural relationships (data model, user-story flow), use mermaid. Reject specs that use bare code blocks for diagram-purpose content."
- Scaffolder (per Pillars 1-3 of this proposal): emits only mermaid blocks for diagram surfaces.
- Future Tier 3 work could add a markdownlint custom rule that flags bare ` ``` ` blocks containing arrow notation (`→` or `-->`) or numbered-step-with-indent patterns common to text-styled-diagrams.

## How (phased implementation plan)

### Phase 1 — Explanatory Omissions (Tier 1, ~5 SP)

Drop-in improvement. Replaces `_omitted_` everywhere with structured per-type reasons. No new diagram types yet.

| Step | File | Effort |
|---|---|---|
| Refactor `scaffold-reviewer-artifacts.ps1` to emit per-type omission reasons | `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` | 2 SP |
| Add the structured omission-status table to the `review-diagrams.md` template | same file | 1 SP |
| Update `.specrew/iteration-config.yml` schema to support per-type reasoning text | `.specrew/iteration-config.yml` | 0.5 SP |
| Tests covering each omission message | `tests/integration/reviewer-artifacts.ps1` | 1 SP |
| Mirror parity (extensions/ + .specify/extensions/) | both mirrors | 0.5 SP |

**Ship target**: composes with v0.25.0 or v0.25.1 (post-v0.24.2 bundle).

### Phase 1b — Pillar 6 Mermaid Mandate (text-only, ~3 SP)

Independent of Phase 1's scaffolder work. Pure methodology-text addition. Can ship as small-fix slice in v0.24.2 bundle alongside Proposal 082 Tier 1 (both text-only methodology integrity fixes).

| Step | File | Effort |
|---|---|---|
| Add Pillar-6 rule to coordinator governance prompt | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (+ mirror) | 0.5 SP |
| Add mermaid responsibility to Reviewer + Spec Steward + Retro Facilitator + Planner charters | `agents/{reviewer,spec-steward,retro-facilitator,planner}/charter.md` (+ mirror) | 1 SP |
| Add `## Diagram Format Convention` section to user-guide with the mermaid-type catalog | `docs/user-guide.md` | 0.5 SP |
| Update existing proposals/specs that have bare-` ``` ` diagram-styled content as a one-pass cleanup (F-029 `review.md` is the immediate instance; spot-check `proposals/*.md` for similar) | various | 0.5 SP |
| Mirror parity sweep | both mirrors | 0.5 SP |

**Ship target**: v0.24.2 bundle as small-fix slice per Proposal 067.

### Phase 2 — Two Most-Universal New Diagram Types (Tier 2, ~12 SP)

Class Hierarchy + Dependency Graph. Most languages support these naturally; they apply to the broadest set of changes.

| Step | Effort |
|---|---|
| Detector: class hierarchy changes (C#, Python, PowerShell-class, JavaScript, TypeScript, Java, Go, Rust) | 4 SP |
| Detector: dependency graph changes (`using`, `import`, `require`, `Add-Type`, `from X import Y`) | 3 SP |
| Generators: emit mermaid class diagram + dependency flowchart | 2 SP |
| Tests across each supported language | 2 SP |
| Mirror parity | 1 SP |

### Phase 3 — DB Schema + Sequence (Before/After) (Tier 3, ~15 SP)

Higher-value but more complex generators.

| Step | Effort |
|---|---|
| Detector: DB schema changes (SQL files, migration files in common ORMs — EF Core, Django, Alembic, Knex, Prisma) | 4 SP |
| Generator: ER diagram in mermaid | 3 SP |
| Detector: control-flow changes (function diff with branch/call-site analysis) | 5 SP |
| Generator: before/after sequence diagrams | 2 SP |
| Tests | 1 SP |

### Phase 4 — Adaptive Selection + Reviewer Pointers (Tier 4, ~5 SP)

Tie everything together; add the per-diagram "what to look at" hints.

| Step | Effort |
|---|---|
| Adaptive selection: run all six detectors per iteration, emit results | 2 SP |
| Reviewer pointer derivation from detection metadata | 2 SP |
| Documentation in `docs/user-guide.md` explaining the multi-type evidence | 1 SP |

**Total across phases**: ~40 SP. Phase 1b alone (~3 SP, Pillar 6 mermaid mandate) is text-only and ships as a small-fix slice in v0.24.2. Phase 1 (~5 SP, scaffolder explanatory omissions) ships in v0.25.0. Phases 2-4 (~32 SP, multi-type diagram catalog + adaptive selection) ship later or fold into Proposal 030.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 030 (Quality Hardening Bundle)** | This proposal IS one of the quality-evidence-hardening pieces 030 would absorb. Could ship as a slice of 030 or stand alone. |
| **Proposal 073 → Feature 028 (Review Evidence Integrity, shipped)** | F-028 added the form-vs-meaning warning to reviewer artifacts. This proposal extends that quality discipline to the diagrams surface. Sibling work. |
| **Proposal 020 (Spec-Scenario Integration Test Mandate, candidate)** | If sequence diagrams (Pillar 4) render before/after flow, they could double as test-scenario visualizations. Composes. |
| **Proposal 080 (Specrew File Reference, candidate)** | review-diagrams.md gets a per-file entry in 080's catalog; this proposal defines what "green" means for that file. Composes. |
| **Proposal 074 (Code Commentary Standards, draft)** | 074 governs in-code documentation; 081 governs review-artifact documentation. Sibling docs-quality features. |
| **Future: Per-feature visual contract** | Some features (DB migrations, API redesigns) could declare REQUIRED diagram types in their spec. Out of scope here; composable later. |

## Acceptance signals

- **AC0 (Pillar 6 — Phase 1b)**: Specrew artifacts (`spec.md`, `plan.md`, `review.md`, `retro.md`, `closeout.md`, scaffolder outputs, proposals, user-facing docs) contain no bare ` ``` ` fenced blocks for diagram-purpose content. Diagrammatic intent → mermaid block of the appropriate type. Verified by spot-check across F-029 and recent proposals + a one-pass cleanup of existing offenders.
- **AC0b (Pillar 6 — Phase 1b)**: Coordinator governance prompt and Reviewer/Spec Steward/Planner/Retro Facilitator charters explicitly require mermaid for diagrams. `docs/user-guide.md` has a "Diagram Format Convention" section with the mermaid-type catalog.
- **AC1**: `review-diagrams.md` no longer contains the bare token `_omitted_` anywhere. Every section either renders a diagram or explains why it doesn't, in human-readable text. (Tier 1)
- **AC2**: Six diagram types implemented: Structure, Flow, Class Hierarchy, Dependency Graph, DB Schema, Sequence (Before/After). (Tiers 1-3)
- **AC3**: Each diagram type has a deterministic detection rule that fires only when confidence is high; otherwise the section explains the skip per Pillar 1. (Tiers 1-3)
- **AC4**: When a control-flow change is detected, before AND after sequence diagrams render side-by-side or stacked. (Tier 3)
- **AC5**: Each rendered diagram has a "Look at:" reviewer pointer above it derived from detection metadata. (Tier 4)
- **AC6**: Structured omission-status table appears at the bottom of `review-diagrams.md` with rows for all six diagram types and statuses (`rendered` / `omitted` / `not applicable` / `failed`). (Tier 1)
- **AC7**: F-028's own iteration evidence (the dogfooding case) is re-scaffolded with the new logic and produces at least a Class Hierarchy diagram (the `Test-FormMeaningParity` + `Test-PreReviewCommitGate` additions), a Dependency Graph (new internal calls), and a Sequence Before/After (the new pre-review gate path). Validation by maintainer inspection.
- **AC8**: Tests cover detection correctness for each of the six diagram types across at least two languages per detector (where applicable).

## Out of scope

- **Real-time interactive diagrams**: Static mermaid only.
- **Architectural diagrams beyond changed surface**: This proposal renders changes, not full system architecture. A separate "system architecture diagram" surface could compose later.
- **Cross-iteration diagram comparison**: This iteration's diagrams vs previous iteration's diagrams. Composable future work.
- **AI-generated diagram annotations**: Reviewer pointers are derived from deterministic detection metadata, not LLM commentary. AI-narrated diagrams are a separate concern.
- **Diagram quality scoring**: We trust the deterministic detectors; we don't try to score "is this a good diagram".

## Cross-references

- **User direction**: 2026-05-21 conversation, "diagrams are important when they are needed — new class hierarchy, new db schema, changes flow, emphasizing a what-if scenario, explaining component dependencies"
- **F-028 empirical evidence**: file:///C:/Dev/Specrew/specs/028-review-evidence-integrity/iterations/001/review-diagrams.md (the dogfooding case where the omission gap was first surfaced)
- **Current scaffolder threshold logic**: `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` lines 1198-1230
- **Current diagram thresholds**: `.specrew/iteration-config.yml` lines 77-83
- **Proposal 073 (Review Evidence Integrity)**: file:///C:/Dev/Specrew/proposals/073-review-evidence-integrity.md
- **Proposal 030 (Quality Hardening Bundle)**: file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- **Proposal 080 (Specrew File Reference)**: file:///C:/Dev/Specrew/proposals/080-specrew-file-reference.md
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
