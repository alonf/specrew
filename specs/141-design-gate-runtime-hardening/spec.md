# Feature Specification: Design Gate Runtime Hardening + Smoke-Test Bundle

**Feature Branch**: `141-design-gate-runtime-hardening`  
**Created**: 2026-06-02  
**Status**: Draft  
**Input**: User description: "Specify a new feature `design-gate-runtime-hardening` covering the full smoke-test hardening bundle, split into iterations. Iteration 1 stays focused on the design-gate runtime path; later iterations carry the four smoke-test bugs. Include Proposal 156 lens catalog only as lightweight read-only input. Typed/rendered packets only for the design-analysis gate, not full Proposal 155."  
**Source Proposals**: file:///C:/Dev/Specrew-design-analysis/proposals/137-design-alternatives-analysis-gate.md (parent gate), file:///C:/Dev/Specrew-design-analysis/proposals/155-typed-boundary-gate-packets.md (typed packet — scoped to design-analysis only), Proposal 156 Design Analysis Lens Knowledge Catalog (lightweight read-only slice; lives on main)  
**Builds on**: Feature 140 (file:///C:/Dev/Specrew-design-analysis/specs/140-design-analysis-gate/) — the design-analysis gate helper and plan-boundary enforcement this feature hardens.

## Context

Feature 140 shipped the minimal design-analysis gate: a validator helper
(`scripts/internal/design-analysis-gate.ps1`) plus enforcement wired into the
`plan` boundary-sync path. That enforcement fires at boundary sync — after plan
artifacts already exist. The gate is real but not yet *felt* end to end: nothing
scaffolds the `design-analysis.md` artifact for the Crew to fill, the human
approval object is still free-form coordinator prose, and `plan.md` can be
authored before the design decision is validated. Separately, a manual smoke of
the Feature 140 runtime surfaced four concrete defects in the launch/runtime
path that must be fixed without losing them to backlog.

This feature hardens the design-gate runtime into an enforced, human-felt
experience and folds in the smoke-test defect bundle, split across iterations.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enforced Design Analysis Before Plan (Priority: P1)

As a human developer approving Specrew lifecycle work, I need the design-analysis
gate to be enforced *before* `plan.md` is authored — not just acknowledged at
boundary sync afterward — so a substantive plan can never be produced before the
design decision exists and is valid.

**Why this priority**: This closes the core gap left by Feature 140. Boundary-sync
enforcement runs after plan artifacts are already written; the value of the gate
is preventing plan content from being shaped before the design is chosen.

**Independent Test**: Run a substantive iteration through clarify/before-plan and
confirm (a) a conformant `design-analysis.md` is scaffolded for the iteration,
(b) attempting to produce `plan.md` while the artifact is missing/invalid or the
Human Decision is absent is blocked with an actionable message, and (c) once the
artifact and a recorded human decision are valid, plan authoring proceeds.

**Acceptance Scenarios**:

1. **Given** a substantive iteration at the design-analysis stop, **When** the
   gate is reached, **Then** a `design-analysis.md` artifact is scaffolded whose
   structure matches the Feature 140 validator contract (problem framing,
   decision points, alternatives with required per-option fields, Crew
   recommendation, Human Decision).
2. **Given** a missing or structurally invalid `design-analysis.md`, **When**
   `plan.md` generation is attempted, **Then** the attempt is blocked before any
   substantive `plan.md` content is written, with a message naming the missing
   artifact or section.
3. **Given** a valid `design-analysis.md` whose Human Decision section has no
   chosen option or commit hash, **When** `plan.md` generation is attempted,
   **Then** the attempt is blocked until a human decision is recorded.
4. **Given** a valid artifact and a recorded human decision, **When** plan
   authoring proceeds, **Then** the human-selected option and modifications are
   preserved as authoritative plan input.

---

### User Story 2 - Typed, Rendered Design-Analysis Gate Packet (Priority: P1)

As a human approving the design-analysis stop, I need the approval object to be a
Specrew-rendered, validated packet built from typed fields — not just free-form
coordinator prose — so the gate packet I approve is consistent, complete, and
trustworthy for the design-analysis boundary specifically.

**Why this priority**: Free-form prose packets drift from the underlying decision
record (the D-004/D-005 class behind Proposal 155). Rendering the design-analysis
packet from typed fields makes the human-visible approval object reliable. Scoping
it to this one gate keeps the slice small.

**Independent Test**: Provide typed design-analysis packet fields and confirm
Specrew renders a packet containing the required human re-entry sections and the
`approved for plan with Option <X>` verdict shape, validates it, and refuses to
advance the design-analysis boundary when required fields or `file:///` references
are missing.

**Acceptance Scenarios**:

1. **Given** typed design-analysis packet fields, **When** the packet is rendered,
   **Then** it contains the required human re-entry sections and pins review
   targets as `file:///` references.
2. **Given** a rendered packet missing a required section or containing bare
   (non-`file:///`) artifact references in its prose, **When** packet validation
   runs, **Then** validation fails with an actionable message naming the section
   and offending reference.
3. **Given** a validated design-analysis packet, **When** the human approves with
   a chosen option, **Then** the chosen option propagates into the Human Decision
   section and plan input.

---

### User Story 3 - Applicable Design Lenses Surfaced in Design Analysis (Priority: P2)

As a developer doing design analysis, I want the Crew to reference the repo-local
design-lens files and render an "Applicable Lenses" section in `design-analysis.md`
that lists only the lenses that actually apply to my feature — chosen by a short
applicability questionnaire (recorded as JSON) — so the option comparison is informed
by the relevant lens knowledge without noise and without a heavy new subsystem.

**Why this priority**: This raises design-analysis quality by reusing existing lens
files and tailoring them per feature. Per Amendment A1 (2026-06-03), the
questionnaire-driven selection (FR-025) is now in scope for Iteration 4; only the
truly-deep Proposal 156 automation (overrides, schema-validation enforcement, broad
cross-phase automation) remains deferred.

**Independent Test**: Run design analysis for a feature with a clear quality profile,
answer the applicability questionnaire, and confirm `design-analysis.md`'s "Applicable
Lenses" section names exactly the selected lenses, that re-running with the same answers
yields the same set (deterministic), that a recorded JSON artifact explains each
include/exclude, that it degrades gracefully when no lenses/answers exist, and that no
project-local override, lens-schema validator, or broad lens automation was introduced.

**Acceptance Scenarios**:

1. **Given** existing repo-local lens files and recorded questionnaire answers, **When**
   design analysis runs for a substantive feature, **Then** `design-analysis.md` includes
   an "Applicable Lenses" section listing exactly the lenses the answers select
   (foundational always-on + specialized lenses gated by a "yes"), read-only.
2. **Given** the same recorded answers, **When** selection runs again, **Then** the
   selected lens set is identical (deterministic), and the JSON artifact records why each
   lens was or was not selected.
3. **Given** the scope boundary, **When** review inspects the change, **Then** no
   project-local lens override, lens-schema validator, or broad cross-phase lens-loading
   automation was added by this feature (the questionnaire selection is in scope; the
   deeper 156 automation is not).
4. **Given** a downstream project with no lens catalog or no answers, **When** design
   analysis runs, **Then** the "Applicable Lenses" section degrades gracefully (states
   none available) rather than erroring.

---

### User Story 4 - Correct Start-Packet Artifact Paths (Priority: P2)

As a developer reading a generated start packet, I need every artifact path to be
complete so I never see broken `specs//...` references with an empty feature
segment.

**Why this priority**: Empty path segments in the human-visible start packet break
clickable references and erode trust in the handoff. Smoke-test defect.

**Independent Test**: Generate a start packet in a scenario that previously
produced an empty `specs//...` segment and confirm every emitted artifact path
contains a non-empty feature segment.

**Acceptance Scenarios**:

1. **Given** a launch/resume scenario, **When** the start packet is generated,
   **Then** no emitted artifact path contains an empty segment such as `specs//`.
2. **Given** a feature reference is unavailable, **When** the start packet is
   generated, **Then** the packet either omits the path or emits an explicit
   placeholder rather than a malformed empty-segment path.

---

### User Story 5 - Quiet, Trustworthy Greenfield/Downstream Runs (Priority: P2)

As a developer in a greenfield or downstream project, I need Specrew to suppress
warnings that do not apply so genuine signals are not buried in noise.

**Why this priority**: Noisy spurious warnings in fresh/downstream projects train
users to ignore warnings, defeating the governance signal. Smoke-test defect.

**Independent Test**: Run lifecycle commands in a freshly bootstrapped greenfield
project and in a downstream project and confirm warnings that do not apply to that
project class are not emitted.

**Acceptance Scenarios**:

1. **Given** a freshly bootstrapped greenfield project, **When** a lifecycle
   command runs, **Then** warnings that only apply to the Specrew self-host or to
   in-flight history are not emitted.
2. **Given** a downstream project, **When** a lifecycle command runs, **Then** the
   emitted warnings are limited to ones genuinely actionable in that project.

---

### User Story 6 - Correct Fresh-Greenfield Baseline Commit Handling (Priority: P2)

As a developer starting a brand-new greenfield project, I need the lifecycle
baseline commit to be established and resolved correctly so boundary state and
baseline references do not point at a missing or wrong commit.

**Why this priority**: A wrong or missing baseline commit corrupts boundary-state
provenance from the very first boundary. Smoke-test defect.

**Independent Test**: Bootstrap a fresh greenfield project, run the first
lifecycle boundary, and confirm the baseline commit reference resolves to a real
commit and is recorded consistently in start context and boundary state.

**Acceptance Scenarios**:

1. **Given** a fresh greenfield project with no prior history, **When** the first
   boundary is recorded, **Then** the baseline commit reference resolves to a real
   commit hash.
2. **Given** the baseline commit is recorded, **When** subsequent boundaries read
   it, **Then** the recorded baseline is consistent across start context and
   boundary state.

---

### User Story 7 - Host-Accurate Launch Wording (Priority: P3)

As a developer launching on a specific host, I need runtime/launch wording to match
that host so I never see another host's terminology, such as "Copilot approval
mode" during a Claude launch.

**Why this priority**: Wrong-host wording is a correctness and trust defect in the
generated guidance, even though it is cosmetic. Smoke-test defect.

**Independent Test**: Launch on the Claude host and confirm no Copilot-specific (or
other non-selected-host) wording appears in the generated guidance; repeat per host.

**Acceptance Scenarios**:

1. **Given** a Claude-host launch, **When** the start guidance is generated,
   **Then** it contains no Copilot-specific approval-mode wording or other
   non-selected-host terminology.
2. **Given** any selected host, **When** the start guidance is generated, **Then**
   host-conditional wording reflects the selected host only.

---

### Edge Cases

- A trivial, doc-only, or small-fix iteration reaches the pre-plan path; the
  enforced-before-plan behavior must respect Feature 140's narrow applicability
  rule and not hard-block non-substantive work.
- The design-analysis artifact exists but the scaffold and the validator contract
  disagree on a required section; the scaffold MUST match the validator contract
  so a freshly scaffolded artifact is not immediately invalid.
- `plan.md` already exists from a prior run; re-entering the design-analysis stop
  must not treat the stale plan as approval, and must still require a valid current
  decision before regenerating plan content.
- A smoke-bug fix would require touching a Unix-install/shell-wrapper/bootstrap file
  owned by the parallel Unix feature; the fix must stay minimal and explicitly
  scoped, or be deferred with a recorded reason.
- Lens files are absent or empty in a downstream project; the "Applicable Lenses"
  section must degrade gracefully (state none applicable) rather than error.

## Requirements *(mandatory)*

### Functional Requirements

#### Design-gate runtime path (Iteration 1 focus)

- **FR-001**: Specrew MUST scaffold a per-iteration `design-analysis.md` whose
  structure conforms to the Feature 140 validator contract (problem framing,
  decision points, alternatives with required per-option fields, Crew
  recommendation, Human Decision), so a freshly scaffolded artifact is shaped to
  pass validation once filled.
- **FR-002**: Specrew MUST validate the design-analysis artifact before `plan.md`
  is generated for a substantive iteration, in addition to the existing Feature
  140 plan-boundary-sync enforcement.
- **FR-003**: Specrew MUST prevent substantive `plan.md` content from being
  authored until the design-analysis artifact is structurally valid AND the Human
  Decision section records a chosen option and commit hash.
- **FR-004**: Specrew MUST render the design-analysis human gate packet from typed
  fields rather than relying solely on free-form coordinator prose.
- **FR-005**: Specrew MUST validate the rendered design-analysis gate packet for
  the required human re-entry sections, the `approved for plan with Option <X>`
  verdict shape, and `file:///` artifact references before the design-analysis
  boundary advances toward plan.
- **FR-006**: The typed/rendered packet capability in this feature MUST be scoped
  to the design-analysis gate only. It MUST NOT implement the full Proposal 155
  multi-boundary typed-packet architecture (per-boundary `gates/` layout across
  all boundaries, packet hashing/replay command, all gate-type templates) within
  this feature.
- **FR-007**: Specrew MUST preserve the human-selected option and modifications as
  authoritative plan input, continuing Feature 140 FR-012 behavior through the
  hardened pre-plan path.
- **FR-008**: Specrew MUST build on the existing Feature 140 design-analysis-gate
  helper and plan-boundary enforcement rather than rewriting them.

#### Lens catalog + applicability selection (Iterations 4-6; amended 2026-06-04 — Amendments A1, A2, A3)

- **FR-009**: The repo-local design-lens knowledge (`extensions/specrew-speckit/knowledge/design-lenses/`)
  MUST inform the lifecycle, not merely a single design-analysis section: for each selected lens, its
  **Design Decision Points** surface into the work so the requirements (specify), the design's option
  comparison, and the plan are genuinely informed by the lens knowledge (not a list of names). The
  design analysis MUST address each selected lens (enforced by FR-026). *(Amended — A3: broadened from
  "render an Applicable Lenses section in design-analysis.md" to "inform requirements + design + plan.")*
- **FR-025**: Specrew MUST determine lens applicability via an **interactive, expertise-adapted
  applicability questionnaire** the Crew poses to the human **early — before clarify (FR-027)** —
  covering the material areas (user-facing UI? auth/secrets/PII/compliance? persistent data? external
  service/API integration? deployment/CI/release changes? performance/scale or resilience?). The Crew
  MUST **ask the human** these questions, adapting question depth to the recorded user-profile expertise
  dials per the F-016 interaction model (concise expert-level questions where a dial is high; explain +
  recommend a default where it is low), surface the resulting lens decisions for confirmation, and MUST
  NOT silently auto-resolve a material lens area. Answers are recorded as a JSON artifact; lens
  selection from the answers remains a **deterministic, LLM/network-free function** of the answers + a
  question→lens map (foundational always-on; specialized gated by their mapped answer), so identical
  answers yield the same set and the JSON is the audit trail. *(Amended — A3: was "a fixed questionnaire
  that MAY be answered by the Crew"; the Iteration 4-5 deterministic selector + sibling map + decision-
  point extractor are retained as the mechanism.)*
- **FR-026**: The pre-plan design-analysis gate MUST enforce **lens coverage** — for each lens the
  FR-025 questionnaire selected, the design analysis MUST record that the lens's decision points were
  addressed (a deterministic per-lens "Addressed:" coverage entry, with explicit grandfathering — not
  inferred from missing entries). The gate MUST block `plan.md` when a selected lens is unaddressed,
  naming it. The check is deterministic and LLM/network-free (it verifies a non-placeholder coverage
  entry per selected lens; it does not judge semantics — an anti-omission backstop, not a quality
  guarantee).
- **FR-027**: The lens-applicability intake (FR-025) MUST run as an **early lifecycle step, before
  clarify**, so its recorded answers are an input that shapes the requirements (specify), the clarify
  questions, the design analysis, and the plan — not only the `design-analysis.md` "Applicable Lenses"
  section. The selected lenses' decision points MUST be available to those earlier phases. *(New — A3.)*
- **FR-028**: File references MUST obey their rendering context. Human-facing **console/terminal** prose
  (orientation, boundary packets, narration) uses bare `file:///` URLs (terminal-clickable); **persisted
  `.md` artifacts** (design-gate packets, review, design-analysis, retro, etc.) use markdown links
  `[text](relative-path)` so they navigate in an editor — a reference MAY carry both. The boundary-handoff
  bare-path rule MUST honor this context and MUST NOT flag non-path `token/token` prose (e.g. `RRT/Bug1`,
  `FR/SC`) as a bare path. *(New — A3; supersedes the blanket "bare `file:///` everywhere" reading of the
  packet rule.)*
- **FR-010**: The lens integration MUST stay scoped. The A3 re-scope changes **when** the questionnaire
  runs (early — FR-027), **who** answers (the human, interactively — FR-025), and **how** the answers
  flow (into requirements/design/plan — FR-009); it **retains** the Iteration 4-5 engine (deterministic
  selector, sibling map, decision-point extractor, FR-026 coverage gate). **Truly-deep Proposal 156
  automation — project-local lens overrides, validation of the lens FILES against a schema, and broad
  cross-phase lens automation — remains deferred** and MUST NOT be implemented here. The questionnaire +
  "Applicable Lenses" surface MUST degrade gracefully (state "none available") when the catalog or the
  answers are absent (e.g. a downstream project without lenses).

> **Amendment A1 (2026-06-03, maintainer-directed):** FR-009/FR-010 were originally pre-deferred
> (2026-06-02) as a *lightweight read-only* surface-the-catalog slice, with all selection
> automation deferred to Proposal 156's deeper scope. They are now **un-deferred into Iteration 4**
> and expanded to include questionnaire-driven applicability selection (FR-025). **Rationale:** the
> selection work is ~12-15 SP (one iteration, under the 20 SP cap) and the release-overhead of a
> separate feature (branch + universal beta-publish + manual install validation + PR + closeout)
> is not justified for that size when Feature 141 is already open and will ship one release cycle.
> Only the *truly-deep* 156 items (overrides, schema-validation enforcement, broad automation) stay
> deferred. Because FR-025 introduces a new mechanism + artifact, Iteration 4 is **substantive** and
> runs the design-analysis gate (FR-001..FR-008) it built — the first such use within this feature.
>
> **Amendment A2 (2026-06-03, maintainer-directed):** Iteration 4 shipped the selection plumbing +
> a lens-name list, which under-delivered FR-009's stated intent ("the option comparison *informed
> by* the lens knowledge"). **Iteration 5** completes it as the complete, state-of-the-art package:
> FR-009 now surfaces each selected lens's **Design Decision Points** into the analysis, and **FR-026
> (new)** makes the pre-plan gate **enforce lens coverage** (block `plan.md` if a selected lens is
> unaddressed). This **un-defers the enforcement** that A1/FR-010 had parked; only validation of the
> lens FILES against a schema + project-local overrides + broad cross-phase automation stay deferred.
> Maintainer directive: "implement all, the complete package, state of the art."
>
> **Amendment A3 (2026-06-04, maintainer-directed after an empirical manual end-to-end test):** A fresh
> greenfield run of the Iteration 4-5 lens feature surfaced that it **missed its core intent** — the
> questionnaire was *auto-answered by the agent* at the *design-analysis stop* (post-clarify). The
> maintainer's intent is that lens selection is an **interactive, expertise-adapted human intake**
> (FR-025) run **early, before clarify** (FR-027), so its answers shape the requirements, clarify,
> design, and plan (FR-009), and that file references obey a **console-vs-persisted context model**
> (FR-028). The Iteration 4-5 *mechanics* (selector, sibling map, decision-point extractor, FR-026
> coverage gate) are sound and **retained as the engine**; what changes is the placement, the
> interactivity, and the flow. **Iteration 5 is closed (mechanics delivered); the re-scope is built in
> Iteration 6.** Two cross-feature flow bugs the test exposed (downstream `Specrew.psd1` FileList-sort
> warning; handoff-validator `token/token` bare-path false-positive) are bundled — see the Smoke-test
> bug bundle. Maintainer directive: "extend the effort to do things right — replan, fix all."

#### Smoke-test bug bundle (later iterations, kept in this feature)

- **FR-011**: Generated start/handoff packets MUST NOT emit empty or malformed
  artifact path segments (e.g., `specs//...`); every emitted artifact path MUST
  contain a non-empty feature segment or omit/placeholder the path explicitly.
- **FR-012**: Greenfield and downstream projects MUST NOT surface spurious
  governance/runtime warnings that do not apply to a freshly bootstrapped or
  downstream project.
- **FR-013**: A fresh greenfield project's baseline commit MUST be established and
  resolved to a real commit hash, recorded consistently across start context and
  boundary state.
- **FR-014**: Generated launch/runtime guidance MUST present host-accurate wording
  and MUST NOT leak another host's terminology (e.g., "Copilot approval mode")
  during a launch on a different host.
- **FR-015**: The four smoke-test defects (FR-011 through FR-014) MUST remain
  within this feature and MUST NOT be pushed to a separate feature.
- **FR-029**: Boundary-state sync MUST NOT emit a spurious `Specrew.psd1` FileList-sort
  warning in a downstream project that has no module manifest; the FileList-sort step is a
  Specrew-repo-only operation and MUST be guarded (skipped when no `Specrew.psd1` is present).
  (Added 2026-06-04 — Amendment A3; manual-test flow bug. The companion handoff `token/token`
  bare-path false-positive is covered by FR-028.) Lower-priority manual-test observations —
  `.specify/feature.json` being gitignored while the agent attempts to stage it, and the
  version-display inconsistency (`0.31.1-beta1` banner vs `0.31.1` config vs `0.31.0` installed)
  — are noted for triage but are not blocking FRs.

#### Sequencing, scope, and governance

- **FR-016**: This feature MUST be delivered across multiple iterations: Iteration
  1 delivers the design-gate runtime path (FR-001 through FR-008) plus FR-022/FR-023
  validator robustness (firm), at 18 SP. FR-009/FR-010/FR-025 (Applicable Lenses +
  questionnaire-driven selection) were pre-deferred (2026-06-02) but are now scheduled as
  **Iteration 4** (un-deferred 2026-06-03 — Amendment A1); Iterations 2-3 delivered the
  smoke-test bug fixes (FR-011..FR-014 + FR-024). The plan MUST propose the concrete
  iteration split and a capacity model.
- **FR-017**: This feature MUST NOT force Feature 140 feature-closeout; Feature 140
  remains open behind its dirty working-tree gate, and this feature stacks on the
  Feature 140 branch tip.
- **FR-018**: This feature MUST NOT publish beta or stable release artifacts.
- **FR-019**: This feature MUST avoid touching Unix install, shell wrapper, and
  bootstrap files owned by the parallel Unix-install feature unless a smoke-bug fix
  genuinely requires it, in which case the change MUST be minimal and explicitly
  scoped.
- **FR-020**: Specrew MUST render, validate, AND persist the design-analysis gate
  packet as part of the enforced pre-plan flow: the packet is stored under
  `specs/<feature>/gates/` (design-analysis gate only, scoped per FR-006, not
  generalized to other boundaries), and the pre-plan validator MUST fail when the
  durable packet is missing or invalid. (Smoke-amended 2026-06-02 from "preferred"
  to required after the external smoke showed packet persistence was an unused
  helper that never produced a `gates/` artifact in the real flow.)
- **FR-021**: Specrew MUST enforce "no substantive `plan.md` before the
  design-analysis artifact and human design-gate decision are valid" via
  coordinator-prompt enforcement plus a callable pre-plan validator in Iteration 1.
  The binding requirement is the outcome (substantive `plan.md` is not authored
  before a valid artifact and a recorded human decision), not a specific host-hook
  mechanism. Host-native write-blocking hook enforcement (Proposal 105) MUST NOT be
  pulled into Iteration 1.

#### Validator robustness (folded into Iteration 1 per 2026-06-02 directive)

These two requirements were discovered while dogfooding the design gate for this
very feature; they directly affect the design-gate runtime path and stay in
Feature 141. They are folded into Iteration 1 when within the cap; if both do not
fit, they become a named later-iteration obligation **within this feature** rather
than deferring to another feature.

- **FR-022**: The design-analysis validator's By-the-book detection MUST tolerate
  normal authored prose (for example, "By the book" with or without a hyphen)
  while still enforcing the required option shape (Simplest and Reasonable
  mandatory; By-the-book conditional and not forced).
- **FR-023**: The Crew Recommendation parsing MUST identify exactly one selected
  recommended option and MUST NOT fail solely because rejected or alternative
  options are mentioned contextually in the recommendation rationale.

#### Stale cross-worktree session recovery (folded into Iteration 2, 2026-06-02)

- **FR-024**: `specrew start` session recovery MUST classify saved session state as
  stale runtime state when the saved session's feature path no longer exists, or it
  points to a completed/merged feature outside the current worktree. In that case it
  MUST NOT re-anchor to a deleted external worktree path; it MUST offer a safe
  cleanup that clears the stale `active-sessions`/`start-context` references WITHOUT
  touching feature artifacts or making lifecycle commits; it MUST report the current
  branch, the stale feature refs, and the selected active-feature candidate; and it
  MUST require explicit human confirmation before performing cleanup. Regression
  coverage MUST cover this scenario. (Discovered 2026-06-02 in the Linux/native-install
  smoke: a stale Feature 051 `active-sessions.yml` entry + obsolete 051 paths in
  start-context/last-start-prompt re-anchored recovery to a deleted worktree
  `C:\Dev\Specrew-051`, blocking continuation of the active feature.)

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit
  reconciliation path.
- **TG-005**: Planning MUST preserve the hard scope limits in this spec (scoped
  typed packet, lightweight lenses, no release publishing, no Feature 140 closeout
  force, Unix-surface exclusion).
- **TG-006**: Review MUST classify each delivered behavior as implemented,
  enforced, observable, and documented, and record gaps before closeout.
- **TG-007**: The scaffolded `design-analysis.md` and the Feature 140 validator
  contract MUST stay reconciled; a contract change MUST update the scaffold and
  vice versa.

### Requirement Ownership

| Requirement | Owner Role(s) | Delivery Window |
| --- | --- | --- |
| FR-001 | Implementer, Reviewer | Iteration 1 |
| FR-002 | Implementer, Reviewer | Iteration 1 |
| FR-003 | Implementer, Reviewer | Iteration 1 |
| FR-004 | Implementer, Reviewer | Iteration 1 |
| FR-005 | Implementer, Reviewer | Iteration 1 |
| FR-006 | Spec Steward, Planner, Reviewer | Iteration 1 |
| FR-007 | Planner, Implementer, Reviewer | Iteration 1 |
| FR-008 | Implementer, Reviewer | Iteration 1 |
| FR-009 | Implementer, Reviewer | Iteration 4 (A1); re-scoped to Iteration 6 (informs requirements/design/plan — A3) |
| FR-010 | Spec Steward, Planner, Reviewer | Iteration 4 (A1); re-scoped Iteration 6 (engine retained — A3) |
| FR-025 | Implementer, Reviewer | Iteration 4 (A1); re-scoped to Iteration 6 (interactive, expertise-adapted, early — A3) |
| FR-026 | Implementer, Reviewer | Iteration 5 (added 2026-06-03 — Amendment A2; lens-coverage enforcement) |
| FR-027 | Implementer, Reviewer | Iteration 6 (added 2026-06-04 — Amendment A3; lens intake before clarify) |
| FR-028 | Implementer, Reviewer | Iteration 6 (added 2026-06-04 — Amendment A3; console-vs-persisted file references) |
| FR-011 | Implementer, Reviewer | Later iteration |
| FR-012 | Implementer, Reviewer | Later iteration |
| FR-013 | Implementer, Reviewer | Later iteration |
| FR-014 | Implementer, Reviewer | Later iteration |
| FR-015 | Spec Steward, Planner, Reviewer | All iterations |
| FR-016 | Planner, Spec Steward | Planning |
| FR-017 | Spec Steward, Reviewer | All iterations |
| FR-018 | Spec Steward, Reviewer | All iterations |
| FR-019 | Spec Steward, Implementer, Reviewer | All iterations |
| FR-020 | Implementer, Reviewer | Iteration 1 |
| FR-021 | Implementer, Reviewer | Iteration 1 |
| FR-022 | Implementer, Reviewer | Iteration 1 (if within cap) |
| FR-023 | Implementer, Reviewer | Iteration 1 (if within cap) |
| FR-024 | Implementer, Reviewer | Iteration 2 |
| TG-001 | Planner, Reviewer | All iterations |
| TG-002 | Planner, Reviewer | All iterations |
| TG-003 | Planner, Reviewer | All iterations |
| TG-004 | Spec Steward, Reviewer | All iterations |
| TG-005 | Spec Steward, Planner, Reviewer | All iterations |
| TG-006 | Reviewer | All iterations |
| TG-007 | Spec Steward, Implementer, Reviewer | Iteration 1 |

### Key Entities

- **Design Analysis Artifact**: The per-iteration `design-analysis.md`; this
  feature scaffolds it conformant to the Feature 140 validator contract.
- **Design-Analysis Gate Packet**: The human approval object for the
  design-analysis boundary, rendered from typed fields and validated (scoped to
  this one gate, not the full Proposal 155 packet system).
- **Pre-Plan Enforcement Point**: The runtime point at which design-analysis
  validity is checked before `plan.md` is authored, in addition to the existing
  plan-boundary-sync check.
- **Applicable Lenses Section**: A read-only section in `design-analysis.md`
  naming relevant existing repo-local lens files.
- **Smoke-Test Defect**: One of the four runtime defects (start-packet path,
  downstream warning noise, greenfield baseline commit, host wording leak) carried
  in later iterations of this feature.
- **Start/Handoff Packet**: The generated launch/resume guidance whose path
  correctness and host-accurate wording are hardened here.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a substantive iteration, a conformant `design-analysis.md` is
  scaffolded whose freshly scaffolded shape passes the Feature 140 validator's
  structural checks once filled.
- **SC-002**: Attempting to author substantive `plan.md` with a missing or invalid
  design-analysis artifact, or without a recorded human decision, is blocked before
  plan content is written, with an actionable message.
- **SC-003**: After a valid artifact and recorded human decision, plan authoring
  proceeds and the selected option/modifications appear as plan input.
- **SC-004**: The design-analysis gate packet is rendered from typed fields and
  validated for required sections, verdict shape, and `file:///` references; an
  invalid packet blocks the boundary.
- **SC-005**: The typed-packet capability is demonstrably scoped to the
  design-analysis gate; no full Proposal 155 multi-boundary packet system is
  introduced.
- **SC-006**: `design-analysis.md` includes an "Applicable Lenses" section listing the
  lenses selected by the FR-025 questionnaire (foundational always-on + specialized lenses
  gated by their answer), and degrades gracefully when the catalog or answers are absent; no
  lens override / schema-validation / broad-automation subsystem is added.
- **SC-015**: Lens selection is a deterministic function of the recorded questionnaire JSON —
  identical answers yield an identical "Applicable Lenses" set across runs — and the JSON records
  the per-lens include/exclude rationale. (Added 2026-06-03 — Amendment A1.)
- **SC-016**: A design analysis that leaves a selected lens unaddressed FAILS the pre-plan gate, and
  the failure names the unaddressed lens; once every selected lens carries a non-placeholder
  "Addressed:" coverage entry, the gate passes. The check is deterministic and LLM/network-free.
  (Added 2026-06-03 — Amendment A2; FR-026.)
- **SC-017**: The lens-applicability intake runs before clarify, and its recorded answers are
  demonstrably available as input to the requirements, clarify questions, design analysis, and plan
  (not only the design-analysis "Applicable Lenses" section). (Added 2026-06-04 — Amendment A3; FR-027.)
- **SC-018**: The lens questionnaire is posed to the human interactively — no material lens area is
  silently auto-resolved — and the question depth adapts to the recorded user-profile expertise dials
  (concise where high; explain + recommend where low). (Added 2026-06-04 — Amendment A3; FR-025.)
- **SC-019**: Console/terminal prose renders file references as `file:///` URLs while persisted `.md`
  artifacts render them as navigable markdown links, and the boundary-handoff bare-path rule does not
  flag non-path `token/token` prose (e.g. `RRT/Bug1`, `FR/SC`). (Added 2026-06-04 — Amendment A3; FR-028.)
- **SC-007**: No generated packet emits an empty path segment such as `specs//`.
- **SC-008**: A freshly bootstrapped greenfield project and a downstream project
  emit no spurious warnings outside their genuinely-actionable set.
- **SC-009**: A fresh greenfield baseline commit resolves to a real commit hash and
  is recorded consistently in start context and boundary state.
- **SC-010**: Launch guidance on a given host contains no other host's terminology.
- **SC-011**: The implementation avoids Unix install, shell wrapper, bootstrap,
  beta-publish, and stable-publish surfaces except for minimal, explicitly-scoped
  smoke-bug fixes where unavoidable.
- **SC-012**: Focused tests cover the pre-plan block/pass behavior, packet
  render/validate behavior, and each of the four smoke-test defects.
- **SC-013**: The plan records the concrete iteration split and capacity model and
  keeps each iteration within the intentional per-iteration story-point cap.
- **SC-014**: The validator accepts a well-authored design-analysis artifact whose
  By-the-book option uses normal prose and whose recommendation names one option
  while mentioning rejected options contextually, and still rejects a genuinely
  multi-recommendation or malformed-option artifact (FR-022, FR-023).

## Assumptions

- The current non-Squad coordinator-prose runtime is the primary execution mode;
  per the clarify decision, "block before plan.md" is realized as a generated
  coordinator instruction plus a callable pre-plan validator in Iteration 1, with
  no host-native hooks (Proposal 105 deferred).
- The Feature 140 validator contract
  (file:///C:/Dev/Specrew-design-analysis/specs/140-design-analysis-gate/contracts/design-analysis-gate.md)
  is the authoritative shape the scaffold must match.
- Existing repo-local lens files under the extension templates directory are the
  read-only lens source for the "Applicable Lenses" section.
- The four smoke-test defects are reproducible; precise root-cause confirmation and
  fixtures are gathered when each defect's iteration is planned.
- This feature stacks on the Feature 140 branch tip because it depends on Feature
  140 runtime code that is not yet merged to main.
- Each iteration stays within the intentional per-iteration story-point cap; the
  plan splits work accordingly rather than raising the cap.

## Scope Limits *(mandatory)*

- Typed/rendered packets are scoped to the design-analysis gate only; do not
  implement full Proposal 155.
- Durable packet storage, if included, is scoped to the design-analysis gate only
  (under `specs/<feature>/gates/` or equivalent); do not generalize to other
  boundaries.
- Do not pull host-native hook enforcement (Proposal 105) into Iteration 1.
- Lens integration: Iteration 4 adds questionnaire-driven applicability selection (FR-025,
  un-deferred per Amendment A1); still defer the truly-deep Proposal 156 scope — project-local
  overrides, lens-schema validation enforcement, and broad cross-phase automation.
- Keep all four smoke-test bugs inside this feature; do not push them to another
  feature.
- Do not force Feature 140 feature-closeout past its dirty working-tree gate.
- Do not publish beta or stable release artifacts.
- Avoid Unix install, shell wrapper, and bootstrap surfaces except minimal,
  explicitly-scoped, unavoidable smoke-bug fixes.
- Do not rewrite the Feature 140 helper or its plan-boundary enforcement; extend
  them.

## Clarifications

### Session 2026-06-02

- Q: How should "block before `plan.md` is authored" (FR-021) be enforced in
  Iteration 1? A: Coordinator-prompt enforcement plus a callable pre-plan
  validator. The binding requirement is the outcome — the Crew MUST NOT author
  substantive `plan.md` before the design-analysis artifact and the human
  design-gate decision are valid. Host-native hook enforcement (Proposal 105) is
  explicitly NOT pulled into Iteration 1.
- Q: Must the typed design-analysis gate packet be persisted (FR-020)? A: The
  minimum acceptable behavior is render-and-validate from typed fields. A durable
  "155-lite" packet for the design-analysis gate is preferred when it stays narrow
  and cheap; if included, it is scoped to the design-analysis gate only (e.g., under
  `specs/<feature>/gates/` or an equivalent design-analysis-scoped path) and is not
  generalized to all boundaries.
- Q: What is the iteration split (FR-016)? A: Multi-iteration feature in a single
  feature. Iteration 1 hardens the design-gate runtime path only: exact
  `design-analysis.md` scaffold/template, pre-plan validation before `plan.md`,
  typed/rendered design-gate packet. (Lens inclusion was pre-deferred from Iteration 1 and is
  now Iteration 4 — questionnaire-driven selection, Amendment A1.) Later iterations stay in this
  feature: Iterations 2-3 cover the four smoke-test defects: empty `specs//...` start-packet
  paths, noisy downstream
  warnings, fresh greenfield baseline commit handling, and host wording leaks. The
  plan proposes the concrete split and capacity model.
- Q: How should feature 141 relate to the unmerged Feature 140 branch (FR-017)? A:
  Stacking 141 on the Feature 140 tip is acceptable because Iteration 1 depends on
  Feature 140 runtime code that is not yet on main. The dependency is kept explicit
  in the artifacts, and the branch is ready to rebase/refresh after Feature 140
  merges.

### Scope addition 2026-06-02 (post design-analysis)

- The two Feature 140 validator-brittleness behaviors found while dogfooding the
  design gate (token-exact By-the-book detection; recommendation parser failing on
  more than one option token) are folded into this feature as FR-022 and FR-023.
  They are NOT separate future-feature work. Fold both into Iteration 1 when within
  the 20 SP cap; if both do not fit, keep them in Feature 141 as a named
  later-iteration obligation rather than deferring to another feature.
- Lens pre-deferral: to keep Iteration 1 at 18 SP with implementation headroom
  (the runtime gate path already touches scaffold, validator, packet, boundary
  wiring, and parser behavior), FR-009/FR-010 (Applicable Lenses) were pre-deferred
  from Iteration 1. They are now scheduled as **Iteration 4** and expanded with
  questionnaire-driven selection (FR-025) per Amendment A1 — deferred-within-feature,
  not dropped; FR-022/FR-023 stayed firm in Iteration 1.

### Smoke amendment 2026-06-02 (post external manual smoke)

An external manual smoke (`C:\Temp\SpecrewTrials\test1234`, feature
`001-azure-bicep-upgrade-scanner`) sent the iteration back from review. The smoke
proved the helpers were not wired into the enforced flow. The following are
in-scope Iteration 1 corrections (see `iterations/001/manual-smoke.md`):

- FR-020 elevated from "preferred" to **required-in-flow**: the pre-plan validator
  fails when the durable `gates/` packet is missing/invalid, so packet persistence
  is enforced, not optional.
- FR-002/FR-003/FR-021: the generated handoff mandates the explicit sequence
  (record decision → render packet → validate → persist → call the pre-plan
  validator) before `plan.md`; the pre-plan validator is the enforcement point, the
  at-sync plan-boundary gate is the artifact/decision backstop.
- FR-008 refinement (decision-commit integrity): the Human Decision records the
  commit that contains the populated decision (distinct from the design-analysis
  draft commit); the validator rejects recording the draft commit as the decision
  commit.
- FR-004 refinement (handoff depth): the template/handoff presents a per-option
  "design principle / why this matters" rationale.
- FR-009/FR-010 (lens activation): confirmed **not** activated in the smoke; this was
  expected for Iteration 1 because lenses were pre-deferred — now scheduled as Iteration 4
  with questionnaire-driven selection (FR-025, Amendment A1), not an Iteration 1 in-scope failure.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Owns scope boundaries (scoped packet, lightweight lenses,
  smoke-bug containment, Unix-surface exclusion, no release publishing) and keeps
  the scaffold reconciled with the Feature 140 validator contract.
- **Iteration Facilitator**: Planner proposes the multi-iteration split and
  capacity model; Iteration 1 is the design-gate runtime path, later iterations are
  the smoke-test bugs.
- **Capacity Model**: Multi-iteration feature; each iteration stays within the
  intentional per-iteration story-point cap. The plan proposes the exact split and
  per-iteration capacity; the total is expected to span roughly three to four
  iterations.
- **Drift Signals**: Drift is indicated by any mismatch among the scaffolded
  `design-analysis.md`, the Feature 140 validator contract, plan input, boundary
  state, packet evidence, and review evidence.
- **Human Oversight Points**: Human review is required after specify before
  clarify, after clarify (and this feature's own design-analysis stop) before plan,
  after plan before tasks, before implementation, at review signoff, at iteration
  closeout, and at feature closeout.
