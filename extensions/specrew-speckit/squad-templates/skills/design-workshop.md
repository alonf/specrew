---
name: "specrew-design-workshop"
description: "Run Specrew's per-lens design workshop and collaborative design-analysis. Use whenever you work the design lenses for a feature: at specify/intake (the lens workshop) and at the design-analysis stop (co-design the architecture), and RE-INVOKE at the start of EACH new lens (architecture, data, ui-ux, security, integration, devops, requirements/NFR, observability, component). Triggers: design, design lens, lens workshop, design-analysis, architecture, trade-offs, co-design, explore options, decompose, or moving from one lens to the next. Tells you to facilitate each lens as a discussion, surface diagrams the human can actually SEE (console ASCII inline; mermaid/html to a file with a clickable file:/// link), co-design components/responsibilities/flows WITH the human instead of handing over finished options, capture the agreements, and which per-lens md to load."
domain: "lifecycle-design"
confidence: "high"
source: "Specrew Feature 141 Amendments A4/A5/A6 — per-lens workshop + visuals + collaborative co-design, relocated from the launch prompt into this skill (iteration 010) for point-of-use focus."
---

# specrew-design-workshop

**Type**: Facilitation Skill
**Schema**: v1
**Status**: Active design-lifecycle conduct

## Purpose

Drive the design lenses as a real, point-of-use **workshop** — not a checklist skimmed once at launch. Each
time you reach a lens, this skill is loaded fresh so the conduct is in focus exactly when you use it. **It is
self-contained: one load gives you everything you need for the current lens.** Because most hosts do not
guarantee a fresh reload per turn, **re-invoke this skill (or re-read it) at the start of each new lens.**

## The Big Picture (read this first, every time)

You are facilitating a design conversation with a human, **one lens at a time**. The lenses live in
`extensions/specrew-speckit/knowledge/design-lenses/` (deployed under the project's design-lens catalog):
`architecture-core`, `component-design`, `requirements-nfr`, `ui-ux`, `data-storage`, `security-compliance`,
`integration-api`, `devops-operations`, `observability-resilience`. For each lens you work:

1. **Load that lens's md** (`design-lenses/<lens-id>.md`) for its `## Design Decision Points` and
   `## Workshop Conduct` — that is the lens's focused agenda. Do not improvise it from memory.
2. **Facilitate** the discussion for that lens (the method below).
3. **Record** the decisions + agreement.
4. **Re-invoke this skill** and go to the next lens.

The per-lens *knowledge* is in the lens md; this skill is the *method* that ties the lenses together. Keep
both in view.

## The Method (the same for every lens)

1. **Frame the phases (A6/FR-034).** Tell the human up front: the workshop *gathers* inputs and constraints;
   the system **structure** (components, responsibilities, flows) is designed *with* them at the design-analysis
   step — not decided in intake. So they know the collaboration is coming.
2. **Infer applicability, then confirm (A4/FR-025).** Propose which lenses apply WITH your reasoning; ask the
   human only to confirm or adjust. Never make them answer obvious yes/no applicability; never silently
   auto-resolve a material area.
3. **Per-lens facilitated discussion (A4/FR-025).** For the current lens, raise its decision points (from its
   md), offer options where useful, capture the human's needs + decisions + explicit agreement, and **iterate
   until the human says "move on"** before the next lens. Adapt depth to the user-profile expertise dials
   (concise where high; explain + recommend a default where low). Right-size — not a fixed nine-lens marathon. **Match the question FORM to the question**: for a discrete, enumerable choice (e.g. decomposition vocabulary — IDesign / Clean Architecture / modular; one service vs split; fixed vs open taxonomy) ask a **multiple-choice question with the full options spelled out and an explicit "other / let me explain" path** so the human can pick fast; for a genuinely open question, discuss in prose. Both are fine — do not force a discrete pick into long prose, nor an open design question into a rigid one-shot MCQ.
4. **Surface visuals IN-BAND so the human can SEE them (A5/A6/FR-030–FR-031/FR-037).** On a terminal/console
   host a fenced ```mermaid``` block is **source text, not a rendered picture** — only **console ASCII**
   actually renders inline. So the diagram you show the human MUST be **console ASCII art rendered directly in
   your message** (boxes, arrows, labels) — reach for ASCII first and by default. Use mermaid / svg / html only
   as a *richer, additional* artifact written to a file under the workshop folder — and when you do, you MUST
   emit its clickable `file:///` link in the SAME message. A diagram the human cannot see is NOT surfaced;
   never let the human reach a decision while a diagram lives only in a file or only as mermaid source. A
   per-lens diagram is **expected** for the structural lenses (architecture, data, security, integration,
   devops) and any UI-bearing feature (ui-ux: a layout sketch). Intake is bidirectional: offer to plot the
   lens's diagram AND ask whether the human has an existing diagram/Figma/whiteboard photo to bring.
5. **Co-design — do NOT hand down finished options (A6/FR-035/FR-036).** At the design-analysis stop:
   - **Co-decide the design method / decomposition style** (DDD bounded-contexts, IDesign volatility-based,
     modular monolith, microservices, layered) as an expertise-adapted discussion; record the choice as a
     binding constraint. Not a bare multiple-choice prompt; do not silently assume it.
   - **Co-build the component map**: present **every component BY NAME with its one-line responsibility**
     (e.g. `CatalogManager — owns plan + exercise CRUD and search`), **never a bare count** like "4 managers,
     3 engines"; render it as an in-band console-ASCII diagram; invite the human to rename, split, merge, or
     reassign; walk at least one key **flow** (user + system actions) through it together; iterate until the
     human agrees the decomposition, responsibilities, and flows are right.
   - **Only then present the remaining trade-off options** (transport, store technology, granularity) for the
     human's verdict — the leftover consequential choices, not the whole design handed down.
   - Where the human's architecture expertise is low you MAY drive the decomposition and explain more, but you
     MUST still confirm the responsibilities and flows with them, not author them silently.
6. **Capture the agreements (A4/A6/SC-021/SC-025).**
   - Per-lens workshop record in the feature-level `lens-applicability.json` (`workshop_intake: true`, the
     `selected` lenses, and a per-lens `workshop` record: agenda + decision/agreement + depth + a `moved_on`
     marker). **Persist each keeper diagram you render for a lens** (the trust-boundary diagram, the ERD, the
     component map, the sequence, etc.) — write the ASCII (or mermaid) to a workshop folder,
     `specs/<feature>/workshop/<lens-id>.md`, and set that lens's `diagram` field to a **reference to that
     file** (the path + a one-line caption), NOT a prose description. A diagram that lives only in the chat
     scrollback is lost; the workshop folder makes the design reviewable from the artifacts.
   - At design-analysis, a `## Co-Design Record` in `design-analysis.md` with the agreed
     component-to-responsibility map + at least one agreed flow + a human-agreed marker, and — when ui-ux is in
     scope — the **agreed UI/screen layout** (the ASCII sketch the human approved). Set `co_design: true` in the
     iteration's `lens-applicability.json` so the deterministic co-design-record floor applies. An agreement
     that lives only in the chat scrollback is lost.
7. **Re-invoke this skill for the next lens.** State which lens is next and reload this conduct + that lens's md.

## When to Use

- At `speckit.specify` / intake, before the specify boundary syncs — run the lens workshop so the spec is
  lens-informed.
- At the design-analysis stop — co-design the architecture before `plan.md`.
- **At the start of each new lens** — re-invoke for fresh, focused conduct.

## Review Standard

This skill is only doing its job when, in the human's view of the conversation: each applicable lens was a
genuine discussion (not a one-shot MCQ); diagrams were SEEN in-band (ASCII inline or a clickable link); the
components were named with responsibilities and co-designed before options; and every agreement (lenses,
co-design map, UI layout) was written to an artifact, not left in the scrollback.
