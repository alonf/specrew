---
name: "specrew-design-workshop"
description: "Run Specrew's per-lens design workshop and collaborative design-analysis. Use whenever you work the design lenses for a feature: at specify/intake (the lens workshop) and at the design-analysis stop (co-design the architecture), and RE-INVOKE at the start of EACH new lens (architecture, data, ui-ux, security, integration, devops, requirements/NFR, observability, component). Triggers: design, design lens, lens workshop, design-analysis, architecture, trade-offs, co-design, explore options, decompose, or moving from one lens to the next. Tells you to facilitate each lens as a discussion, surface diagrams the human can actually SEE (console ASCII inline; mermaid/html to a file with a clickable file:/// link), co-design components/responsibilities/flows WITH the human instead of handing over finished options, capture the agreements, and which per-lens md to load."
domain: "lifecycle-design"
confidence: "high"
source: "Specrew Feature 141 Amendments A4/A5/A6 — per-lens workshop + visuals + collaborative co-design, relocated from the launch prompt into this skill (iteration 010) for point-of-use focus."
disallowed-tools: AskUserQuestion
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
`integration-api`, `devops-operations`, `observability-resilience`, `code-implementation`. For each lens you work:

1. **Load that lens's md** (`design-lenses/<lens-id>.md`) for its `## Design Decision Points` and
   `## Workshop Conduct` — that is the lens's focused agenda. Do not improvise it from memory.
2. **Facilitate** the discussion for that lens (the method below).
3. **Record** the decisions + agreement.
4. **Re-invoke this skill** and go to the next lens.

The per-lens *knowledge* is in the lens md; this skill is the *method* that ties the lenses together. Keep
both in view.

**Render before you ask — the question may only reference what is on screen (A6/A7/FR-037).** Before you
raise ANY confirm/approve question (a structured menu on hosts that preserve the preceding message, or a typed
"does this work? / move on? / approve" prompt) about the lens **agenda + depths**, a per-lens diagram, the
component map, an options/trade-off set, or a design verdict — the thing you are asking about MUST already be
**rendered in your assistant message in THIS exchange**, in prose / console-ASCII the human can see. The
question may reference ONLY content that is on screen. **Never** ask from a count ("8 lenses", "13
components"), a summary ("the agenda", "the map"), or a "shown above / as proposed" that was not actually
shown. The failure mode this exists to stop is **menu-before-render**: render + explain, THEN ask. **Be verbose**
— explain the agenda / diagram / map / options fully in prose first, and make the question and choices
self-explanatory (not a terse "does this work? — 8 lenses").

**Claude safety rule:** the canonical `claude-disallowed-tools: AskUserQuestion` policy is materialized as
`disallowed-tools: AskUserQuestion` only in the deployed Claude skill. Claude's picker can replace the preceding
assistant message, so the workshop MUST use a visible prose question with numbered choices and wait for the
human's typed answer. Do not try to re-enable, emulate, or call the picker. Other hosts retain their structured
question UX when it preserves the rendered context. (testLenses8/11 and the Beta2 Article Amplifier manual test
showed Claude asking the human to confirm an agenda/component map that never appeared, while Copilot and
Antigravity rendered + explained the content first.)

**The `file:///` links go in your prose before the question, too (dogfood finding).** When a confirm/approve
question references or asks the human to review an artifact — the spec, a lens workshop record, the
design-analysis, a diagram file — emit the **bare clickable `file:///` links in your assistant message in THIS
exchange**, never only inside structured question fields and never as a bare "see the file above". Structured
question UIs may not linkify `file:///`; Claude's picker is disabled for this skill because it can drop the
whole preceding message. Rule 14A's clickable-`file:///` guarantee must therefore hold *at* the confirmation,
carried by visible prose.

**(A8/FR-041) Open each lens with a presentation + an open question, never a menu** (The Method step 3) — this is
what actually rendered the lens content on Claude in the dogfood (the per-lens open has no competing menu, so
the content cannot collapse into one). **Governing model (dogfood-proven):** content whose next move is *open
discussion* renders reliably. On Claude, content immediately before `AskUserQuestion` can be swallowed by the
picker; the deployed skill therefore removes that tool for the whole workshop. This is a capability-level
guard, not another conduct instruction or hidden marker. An earlier catalog-at-open front-load was reverted
because it still skimmed on Claude and was redundant on prose hosts that render the agenda inline.

## First stage — the product-domain phase (run before everything, Feature 176)

Before the lens applicability agenda (The Method below), run the **product-domain** first-stage
phase — the pre-technical product/problem grounding. It is **always applicable** and runs FIRST,
before any technical lens or the applicability questionnaire. It is NOT a row in
`applicability-map.json`; it is the first-stage phase ahead of the deterministic selector.

1. **Load the lens** `design-lenses/product-domain.md` for its decision areas, depth model,
   evidence vocabulary, run cadence, and conduct.
2. **Select the depth** (Light / Standard / Deep) by **risk and novelty**, and say why. A tiny
   utility gets a Light pass that records why deeper discovery is not warranted.
3. **Reframe a solution-first request into the problem.** When the human asks to "build X", surface
   who it is for, the pain/job, the MVP, the non-goals, and the constraints BEFORE any design. If the
   requested feature is not aligned to the pain / MVP / constraints / alternatives, surface that
   before plan.
4. **Capture the product context** at the selected depth (users and stakeholders; pain/job and
   current workaround; existing system/context; constraints; outcomes; MVP/non-goals/vision;
   alternatives at Standard/Deep), and **tag every material statement** with its evidence quality
   (`known` / `assumed` / `unknown` / `research-needed`; a `research-needed` carries `load_bearing`).
   Honest tags prevent confident product fiction.
5. **No batch confirmation (FR-009).** The phase cannot be satisfied by approving an agenda or a batch
   "confirm all". It needs scoped product-domain confirmation, or an explicit, honestly recorded
   "you decide" / "skip". Record the provenance (`human-confirmed` / `human-delegated` /
   `human-skipped`) and its matching scope.
6. **Persist both records** under `specs/<feature>/workshop/`: `product-domain.yml` (structured,
   schema-validated against `contracts/product-domain.schema.json`) and `product-domain.md`
   (human-readable), and summarize the decisions into `spec.md` — not as the sole source. The
   specify-gate floor REQUIRES this for a substantive feature before specify syncs; an absent record
   is surfaced, never silently skipped.

**Run cadence**: the product-domain phase runs before EVERY feature at adaptive depth — not once. In
V1 every feature is `context_scope: feature_standalone`; once Proposal 162 ships, later features run
in delta mode (`feature_delta`) against the inherited product baseline (`product_baseline`).

Only after the product-domain phase is captured do you move to the lens applicability agenda below.

## The code-implementation lens (auto-on for code features; Feature 177)

The `code-implementation` lens captures *how the code is written* (implementation craft) as binding
constraints for implement. It is **always-applicable for any feature that writes code** (auto-on; skip
only doc-only / config-only slices, with a recorded reason). It is **conduct-driven** — NOT a row in
`applicability-map.json` (drift D-001), exactly like `product-domain`: you include it for code features
without a yes/no applicability question. Work it **after the technical lenses** (it depends on the
resolved stack + the architecture decision). Load its md
`design-lenses/code-implementation.md` for the decision spine, per-stack dilemmas, the grouping model, the
run-cadence, and the full conduct. The conduct in brief:

1. **Source of code-rules truth FIRST** (the Figma-equivalent question): ask whether the human has an
   existing coding guideline OR one or more **example projects** to emulate (a GitHub repo, a local path,
   or other) for code style, language constructs, and patterns — or none.
2. **Assisted ingestion** (when a guideline / example project is provided; agent-reasoning, no parser):
   map it onto the `code-rules.yml` catalog (auto-check matches, flag conflicts for the human), and extract
   non-catalog conventions as custom rules with provenance (`from-guideline` / `from-example-project` +
   the source ref). Company/org-level rules persist to the reusable project overlay `code-rules.local.yml`
   (additive + per-rule override; never drops a shipped rule).
3. **Resolve the stack**, then present the **grouped, pre-checked set/unset checklist** — baseline stated
   as a summary (exceptions only), the consequential decision-prompts paced (offer all-at-once OR
   one-at-a-time), applicability-filtered rules shown only when their context applies. **Never a flat wall.**
4. **Dependency selection (FR-013)**: present **"use existing project tools / no new dependency" first**
   plus options; for any chosen dependency capture version, license, source org, canonical URL, maintenance
   signal, security/advisory status, compatibility, cost/quota, coupling weight, replaceability, and test
   implications into the manifest `dependency_policy`.
5. **Capture** the selections/decisions/custom-rules/dependency-policy by authoring the per-feature
   `implementation-rules.yml` manifest (reference-by-ID), schema-validated against the manifest schema
   `implementation-rules.schema.json` (beside the lens in the design-lens catalog), plus the human-readable
   `workshop/code-implementation.md`; record the lens in `lens-applicability.json`. (Like `product-domain`,
   you author the record by hand following the schema -- you do NOT call a PowerShell writer; the lens
   helper validates, it is not invoked mid-workshop.)
6. **Run cadence**: the rules are mostly product-level — decide once at a product-level workshop, inherit
   per feature, re-open only the parts a new technology or programming language changes
   (`context_scope` hooks; V1 `feature_standalone`; forward-compatible with Proposal 162).

The **implement-time half** is the separate `specrew-code-rules` skill, which reads this manifest while the
coding agent writes code and surfaces the rules task-scoped. The acceptance gate is the deployed dogfood
(SC-004/SC-007/SC-008), not unit-green.

## The Method (the same for every lens)

1. **Frame the phases + hand over the agenda (A6/FR-034, A7/FR-040).** Tell the human up front: the workshop
   *gathers* inputs and constraints; the system **structure** (components, responsibilities, flows) is designed
   *with* them at the design-analysis step — not decided in intake. So they know the collaboration is coming.
   **Before the heavy prep, keep them oriented (FR-040):** say plainly that you are *preparing the workshop and
   it will take a moment* (so a pause does not read as a hang), and hand them the **agenda as an assignment** —
   list the lenses you will work and, for each, the decision it will ask of them — so they can think or research
   while you load. The wait becomes preparation, and a prepared human engages per-lens (which is what keeps the
   integrity rule in step 6 honest). **Tell the human they can just talk (dogfood finding):** in the same
   framing, say plainly that at any lens, if a question is unclear, they want to open a file, or they need more
   detail, they can simply *type* it (for example "explain more") — you will explain, then re-ask. On Claude,
   typed conversation is the required path because `AskUserQuestion` is disabled for this skill; on other hosts
   the human may still type instead of picking a menu option.
2. **Infer applicability, then confirm (A4/FR-025).** Propose which lenses apply WITH your reasoning; ask the
   human only to confirm or adjust. Never make them answer obvious yes/no applicability; never silently
   auto-resolve a material area. **Render the agenda IN-BAND before asking for confirmation — fill this
   template; do NOT cram the lens list into a question UI** (a prose "render first" gets skimmed on some hosts;
   the filled template is what the human reads while you prepare):

   ```text
   Workshop agenda — <N> lenses

   <lens-id> (<full | medium | light>) — <the decision this lens will ask you to make for THIS feature>
   <lens-id> (<full | medium | light>) — <the decision …>
   ...
   Skipped: <lens-id> — <why it does not apply here>
   ```

   Fill ONE line per applicable lens with its depth and the **concrete decision it raises** (not just the lens
   name); render the whole filled block in your message, THEN ask the human to confirm or adjust it. On Claude,
   render numbered typed choices in prose and wait for the human; on another host, a structured confirm menu may
   reference the already-visible block.
   **The moment the human confirms the agenda, PERSIST it (F-174 — before opening lens 1):** write the
   feature-level `lens-applicability.json` NOW with `workshop_intake: true`, `confirmation_required: true`, and
   the confirmed `selected` lens-id list (the per-lens `workshop` records are added later, as each lens completes
   per step 6). A resume can only compute the remaining agenda if the agenda itself is on disk; an agenda that
   lives only in the scrollback is lost on exit (observed: an unpersisted agenda made a resuming host re-run
   specify instead of continuing the workshop).
   **Agenda confirmation is not lens-question confirmation.** This confirm point approves only the selected
   lens list and depths. It does NOT answer the lenses. Do NOT offer or accept a batch shortcut such as "Confirm
   all as proposed", "approve all lens decisions", or "use the proposed decisions for every lens" as
   `human-confirmed` / `lens-question`. After the agenda is confirmed, every selected lens still needs its own
   lens-specific turn and its own human answer, explicit delegation, or explicit skip.
3. **Per-lens facilitated discussion — open with a presentation + an OPEN question, never a menu first (A4/FR-025, A8/FR-041b).**
   The **first turn of every lens** MUST be you *presenting* the lens — its decision points, and as it develops
   its diagram / component map — followed by an **open, free-text question** ("how should we approach this?",
   "what are your constraints?"). Do **NOT** open a lens with an `AskUserQuestion` / structured menu: that is the
   move that lets the content collapse into the menu's question field and never get rendered (the A8
   `AskUserQuestion` tool-gravity failure). On Claude the tool is unavailable for the entire skill; use visible
   prose and typed numbered choices. On other hosts, a structured menu remains useful only **after** the lens's
   content is on screen, for a crisp discrete choice (e.g. the decomposition vocabulary in step 5). Binary
   test: did this lens open with a rendered presentation, or with a menu? Open with the presentation.
   **One selected lens = one lens turn.** Do NOT bundle several selected lenses into one combined presentation
   and one "confirm all" question, even for a tiny feature or light-depth lenses. A lens turn may summarize the
   already-confirmed agenda, but it must focus on exactly one lens's decision points, ask for that lens's answer,
   and wait for the human (or an explicit "you decide for this lens" / "skip this lens") before moving on.
   **Keep the controller-owned workshop state durable and complete (FR-055/FR-056).** Before you stop and wait
   for an answer, ensure the applicability artifact for the CURRENT workshop scope exists and reflects the current
   confirmed agenda. During specify/intake, authority is the feature-level
   `specs/<feature>/lens-applicability.json`; during design analysis it is the exact iteration's
   `specs/<feature>/iterations/<NNN>/lens-applicability.json`. Never invent an iteration during feature intake.
   Do not rely on a model-authored hidden marker, an environment variable, or a host question-tool transcript:
   hosts can omit, transform, or swallow those surfaces. The Stop controller derives `active` only from the exact
   scoped artifact's nonempty, unique selected agenda and its strict ordered completion records. While that state
   is valid and incomplete, ordinary lens questions remain conversational and the generic five-section
   non-boundary packet is suppressed; a real lifecycle boundary still has precedence.
   **Finish each lens durably in this order:** write the nonempty `workshop/<lens-id>.md` decision record first,
   then persist that lens's full step-6 entry with `moved_on: true`. On the final selected lens, that second write
   makes the workshop `complete` and ordinary Stop behavior resumes immediately. A loose flag, missing record,
   duplicate/out-of-order lens, malformed artifact, or mismatched confirmation is invalid and cannot keep the
   exception active. Never render the generic five-section packet merely to ask or answer an ordinary lens
   question; use the six-section packet only for a genuine lifecycle boundary.
   **Carry binding decisions across lenses.** Before opening a new lens, reread the completed records' durable
   `bindings`. A delegated/default decision may fill an unresolved gap, but it MUST NOT contradict an earlier
   human-confirmed binding. If the human intentionally changes a binding, reconcile every affected lens record
   to the same value before moving on; never leave two durable answers for one architectural fact.
   **Pace a dense lens — after presenting, you MUST offer all-at-once OR one-at-a-time (A8/FR-041b UX, every host).**
   A lens with several decision points (architecture-core, component-design, security-compliance) lands as an
   overwhelming **wall** if you present everything and end with one open question that secretly bundles five
   subjects — and a numbered list of subjects reads like pickable options when it is not. So on a dense lens
   (**three or more** decision points) your closing move **MUST** offer the human a **pacing choice** — *answer it
   all in one go, or have me take you through the decisions one at a time* (then ask decision 1, wait for the
   answer, then decision 2, …, each as its own focused question). This is **not optional on a dense lens and
   applies on every host** — a single open question covering five subjects is as hard on Copilot/Codex/Antigravity
   as on Claude; do not bundle. Respect their pick; never force the whole wall on someone who wants to step
   through it. A light single-decision lens skips the offer — just ask the one open question. Then, for
   the current lens, raise its decision points (from its
   md), offer options where useful, capture the human's needs + decisions + explicit agreement, and **iterate
   until the human says "move on"** before the next lens. Adapt depth to the user-profile expertise dials
   (concise where high; explain + recommend a default where low). Right-size — not a fixed nine-lens marathon.
   **Match the question FORM to the question**: for a discrete, enumerable choice (e.g. decomposition
   vocabulary — IDesign / Clean Architecture / modular; one service vs split; fixed vs open taxonomy), spell
   out every option and an explicit "other / let me explain" path so the human can pick fast. On Claude this is
   a numbered prose list answered by typing; elsewhere it may be a structured multiple-choice question after
   the supporting content is visible. For a genuinely open question, discuss in prose. Both are fine — do not
   force a discrete pick into long prose, nor an open design question into a rigid one-shot MCQ. **Surface EVERY
   selected lens to the human and get a real answer before you record it (A7/FR-038):** intake is NOT "specific
   enough" until each selected lens has either the human's confirmation OR an explicit "you decide / skip" from
   them. You may NOT decide after a few questions that intake is done and then write up the remaining lenses
   yourself — that is the exact failure this rule exists to stop. When you move to the next lens (loading it
   lazily), announce it so the pause is legible: *"preparing lens X of N: &lt;lens&gt; — get ready, this one
   decides …"* (FR-040).
4. **Surface visuals IN-BAND so the human can SEE them (A5/A6/FR-030–FR-031/FR-037).** On a terminal/console
   host a fenced ```mermaid``` block is **source text, not a rendered picture** — only **console ASCII**
   actually renders inline. So the diagram you show the human MUST be **console ASCII art rendered directly in
   your message** (boxes, arrows, labels) — reach for ASCII first and by default. Use mermaid / svg / html only
   as a *richer, additional* artifact written to a file under the workshop folder — and when you do, you MUST
   emit its clickable `file:///` link in the SAME message. A diagram the human cannot see is NOT surfaced;
   never let the human reach a decision while a diagram lives only in a file or only as mermaid source. A
   per-lens diagram is **expected** for the structural lenses (architecture, data, security, integration,
   devops) and any UI-bearing feature (ui-ux: a layout sketch). Intake is bidirectional: offer to plot the
   lens's diagram AND ask whether the human has an existing diagram/Figma/whiteboard photo to bring. **At ANY
   approval point — "approve" / "move on" / "co-design" / "does this work as the baseline" — the diagram or
   component map MUST be rendered in console-ASCII IN THE SAME MESSAGE as the question; NEVER stand in a
   reference to it (a file path, or a bare count like "13 components" / "4 managers"). The human approves what
   is on screen, not what is in a file.** Persist the keeper to the workshop file AFTER and IN ADDITION TO the
   in-band render (step 6) — never INSTEAD of it. (Empirically: testLenses8 on the Claude host wrote the
   component map to the workshop file and asked the human to approve "13 named components" it never showed,
   while Copilot and Antigravity rendered it in-band first — writing the file is not surfacing.)
5. **Co-design — do NOT hand down finished options (A6/FR-035/FR-036).** At the design-analysis stop:
   - **Co-decide the design method / decomposition style** (DDD bounded-contexts, IDesign volatility-based,
     modular monolith, microservices, layered) as an expertise-adapted discussion; record the choice as a
     binding constraint. Not a bare multiple-choice prompt; do not silently assume it.
   - **Co-build the component map — render the FULL form, never a summary or a count.** Whenever you present
     the component map (at the component-design lens AND at the design-analysis stop), put this IN YOUR MESSAGE,
     in order: **(1)** a **console-ASCII diagram** of all components on their layers with dependency arrows;
     **(2) then a named list grouped by the decomposition vocabulary** you bound at the design-method step —
     Managers / Engines / ResourceAccessors for IDesign; bounded contexts / aggregates / entities for DDD;
     layers for layered; services for microservices — with **EVERY component named and its one-line
     responsibility** (e.g. `TrayClient — owns the tray UI + global hotkey`). **NEVER a bare count** ("6
     resource accessors", "3 engines") and never a "map above" / file reference — list every component by name.
     ONLY after the diagram + the full named list are on screen do you ask the human to approve / rename /
     split / merge / reassign, and walk at least one key **flow** (user + system actions) through it together.
     **If they ask for a change, re-render the updated diagram + list, then ask again** — iterate until the
     human agrees the decomposition, responsibilities, and flows are right. **Use this fill-in template so the
     form is consistent** — copy it into your message and replace every `<...>`, list EVERY component (never a
     count), group by your chosen vocabulary, render it in-band BEFORE the approve/change question, and
     re-render the filled template on any change:

     ```text
     Proposed component map

     <console-ASCII diagram: every component on its layer, dependency arrows pointing inward>

     <vocabulary group 1 — Managers | Bounded Contexts | Layers | Services>:
       <ComponentName> — <one-line responsibility>
       <ComponentName> — <one-line responsibility>
     <vocabulary group 2 — Engines | Aggregates | ...>:
       <ComponentName> — <one-line responsibility>
     <vocabulary group 3 — Resource Accessors | Repositories | ...>:
       <ComponentName> — <one-line responsibility>

     Key flow: <actor action> -> <Component> -> <Component> -> <outcome>
     ```

   - **Only then present the remaining trade-off options** (transport, store technology, granularity) for the
     human's verdict — the leftover consequential choices, not the whole design handed down.
   - Where the human's architecture expertise is low you MAY drive the decomposition and explain more, but you
     MUST still confirm the responsibilities and flows with them, not author them silently.
6. **Capture the agreements (A4/A6/SC-021/SC-025).**
   - Per-lens workshop record in the feature-level `lens-applicability.json` — set `workshop_intake: true`,
     `confirmation_required: true`, the `selected` lens-id list, and a SINGLE top-level `workshop` object
     **keyed by lens id**, each value carrying the EXACT fields the gate checks: `agenda` (array of questions
     raised), `decision` (a SINGLE STRING summarizing the decision + agreement), `depth`, `moved_on: true`, and
     **`confirmation`** — the provenance, one of `human-confirmed | human-delegated | human-skipped` (A7/FR-039,
     SC-026), plus **`confirmation_scope`** — `lens-question` for `human-confirmed`, `explicit-delegation` for
      `human-delegated`, or `explicit-skip` for `human-skipped`. Exact shape — get it right the first time:

     Record every load-bearing or cross-lens decision in an optional `bindings` object using stable lowercase
     keys and token values. Reuse the same key whenever another lens touches that decision. Repeated values must
     match exactly; the controller stops on a conflict before the workshop can finish.

      ```json
      { "workshop_intake": true, "confirmation_required": true, "selected": ["architecture-core"],
        "workshop": { "architecture-core": { "agenda": ["q1","q2"], "decision": "what was decided + agreed", "depth": "full", "moved_on": true, "confirmation": "human-confirmed", "confirmation_scope": "lens-question", "bindings": { "article-initiation": "on-demand" } } } }
      ```

     It is `workshop` -> `<lens-id>` -> fields (NOT `<lens-id>` -> `workshop`), and `decision` is a singular
     string, NOT a `decisions` array — the inverted nesting or a `decisions` array FAILS the SC-021 gate. Extra
     fields (such as the `diagram` reference below) are fine. **Persist each keeper diagram you render for a lens** (the trust-boundary diagram, the ERD, the
     component map, the sequence, etc.) — write the ASCII (or mermaid) to a workshop folder,
     `specs/<feature>/workshop/<lens-id>.md`, and set that lens's `diagram` field to a **reference to that
     file** (the path + a one-line caption), NOT a prose description. A diagram that lives only in the chat
     scrollback is lost; the workshop folder makes the design reviewable from the artifacts.
   - **Integrity — never manufacture agreement (A7/FR-038, SC-026).** Set `confirmation: human-confirmed` and
     `confirmation_scope: lens-question` ONLY for a lens whose substantive workshop questions you actually
     surfaced and the human confirmed. Lens approval is not workshop-question approval. If the human explicitly
     said "you decide" or "skip" for that lens's questions, set `human-delegated` + `explicit-delegation` or
     `human-skipped` + `explicit-skip` and say so honestly in `decision` — do NOT write a fabricated "the human
     agreed to X" for a lens they never saw. **A batch confirmation is not valid provenance:** if the human says
     "confirm all as proposed" at the agenda or summary level, that confirms only the agenda/scope and cannot
     produce `human-confirmed` / `lens-question` for any lens. If the human explicitly delegates a shortcut such
     as "you decide the remaining lenses", record each affected lens as `human-delegated` +
     `explicit-delegation`, not `human-confirmed`. **Count self-check before you record:** you are about to write
     N lens records — you must have asked, or been explicitly told to decide/skip, N times, one lens at a time.
     If you stopped early, go back and surface the rest; you may not declare intake "specific enough" and fill in
     the remaining lenses yourself. The SC-026 gate blocks the specify boundary until every selected lens carries
     a `confirmation` and matching `confirmation_scope` — but it cannot see transcript truthfulness; that
     integrity is on you, and the Squad re-dogfood checks it.
   - At design-analysis, a `## Co-Design Record` in `design-analysis.md` with the agreed
     component-to-responsibility map + at least one agreed flow + a human-agreed marker, and — when ui-ux is in
     scope — the **agreed UI/screen layout** (the ASCII sketch the human approved). Set `co_design: true` in the
     iteration's `lens-applicability.json` so the deterministic co-design-record floor applies. An agreement
     that lives only in the chat scrollback is lost.
7. **Checkpoint this lens durable, THEN re-invoke for the next (F-174 — survive a mid-workshop exit/switch).**
   The workshop is long, and an exit or host-switch mid-workshop is expected, not exceptional — so make each
   lens durable the moment you finish it, never "all at the end". BEFORE you move to the next lens:
   **(a) persist the Markdown decision record FIRST** at the exact current scope's
   `workshop/<lens-id>.md` — `specs/<feature>/workshop/<lens-id>.md` during specify/intake, or
   `specs/<feature>/iterations/<NNN>/workshop/<lens-id>.md` during design analysis; **(b) ONLY AFTER that
   nonempty file exists**, write the lens's complete `lens-applicability.json` entry from step 6 with
   `moved_on: true`; **(c)** refresh the rolling handover through the core save path by running the handover
   provider with `--source workshop` (one line; the SAME path the hooks use):
   `pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/specrew-handover-provider.ps1 --project-root . --source workshop`
   — this captures the freshly-written `workshop/` files into the handover so a resuming session inherits the
   progress. (On the Claude host the `PostToolUse` hook ALSO refreshes the handover automatically the moment you
   write the lens record; this explicit call is the cross-host fallback where PostToolUse is not wired.) A
   session that resumes then reads the handover + the `workshop/` folder and **continues from the next
   un-persisted lens instead of restarting the workshop**. A lens that lives only in the chat scrollback is lost
   on exit; a persisted lens is not. Then state which lens is next and reload this conduct + that lens's md.

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
