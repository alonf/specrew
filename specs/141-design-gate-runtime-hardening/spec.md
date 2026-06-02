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
so the option comparison is informed by the existing lens knowledge without a heavy
new subsystem.

**Why this priority**: This raises design-analysis quality cheaply by reusing
existing lens files. It is explicitly the lightweight, read-only slice of Proposal
156; deeper lens automation is deferred.

**Independent Test**: Run design analysis for a feature with a clear quality
profile and confirm `design-analysis.md` contains an "Applicable Lenses" section
naming the relevant existing lens files, and confirm no project-local override,
lens-schema validation, or broad lens automation was introduced.

**Acceptance Scenarios**:

1. **Given** existing repo-local lens files, **When** design analysis runs for a
   substantive feature, **Then** `design-analysis.md` includes an "Applicable
   Lenses" section referencing the relevant lenses read-only.
2. **Given** the lightweight scope, **When** review inspects the change, **Then**
   no project-local lens override, lens-schema validator, or broad lens-loading
   automation was added by this feature.

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

#### Lens catalog (Iteration 1, lightweight read-only)

- **FR-009**: Specrew SHOULD reference the existing repo-local design-lens files as
  read-only input and render an "Applicable Lenses" section in `design-analysis.md`
  naming the lenses relevant to the active feature.
- **FR-010**: The lens integration in this feature MUST remain lightweight and
  read-only. Project-local lens overrides, lens-schema validation, and broad lens
  automation (Proposal 156 deeper scope) MUST be deferred and MUST NOT be
  implemented here unless a cheap, obvious path is found and explicitly approved.

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

#### Sequencing, scope, and governance

- **FR-016**: This feature MUST be delivered across multiple iterations: Iteration
  1 delivers the design-gate runtime path (FR-001 through FR-008, plus FR-009/
  FR-010 if cheap); later iterations deliver the smoke-test bug fixes. The plan
  MUST propose the concrete iteration split and a capacity model.
- **FR-017**: This feature MUST NOT force Feature 140 feature-closeout; Feature 140
  remains open behind its dirty working-tree gate, and this feature stacks on the
  Feature 140 branch tip.
- **FR-018**: This feature MUST NOT publish beta or stable release artifacts.
- **FR-019**: This feature MUST avoid touching Unix install, shell wrapper, and
  bootstrap files owned by the parallel Unix-install feature unless a smoke-bug fix
  genuinely requires it, in which case the change MUST be minimal and explicitly
  scoped.
- **FR-020**: Specrew MUST at minimum render-and-validate the design-analysis gate
  packet from typed fields. Durable persistence of the rendered packet is preferred
  when it stays narrow and cheap; if included, the stored packet MUST be scoped to
  the design-analysis gate only (e.g., under `specs/<feature>/gates/` or an
  equivalent design-analysis-scoped path) and MUST NOT be generalized to other
  boundaries (continuing FR-006).
- **FR-021**: Specrew MUST enforce "no substantive `plan.md` before the
  design-analysis artifact and human design-gate decision are valid" via
  coordinator-prompt enforcement plus a callable pre-plan validator in Iteration 1.
  The binding requirement is the outcome (substantive `plan.md` is not authored
  before a valid artifact and a recorded human decision), not a specific host-hook
  mechanism. Host-native write-blocking hook enforcement (Proposal 105) MUST NOT be
  pulled into Iteration 1.

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
| FR-009 | Implementer, Reviewer | Iteration 1 (if cheap) |
| FR-010 | Spec Steward, Planner, Reviewer | Iteration 1 |
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
- **SC-006**: `design-analysis.md` includes an "Applicable Lenses" section
  referencing relevant existing lens files when lenses apply, and degrades
  gracefully when none apply; no lens override/schema/automation subsystem is added.
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
- Lens integration is lightweight read-only (Applicable Lenses section); defer
  Proposal 156 overrides, schema validation, and broad automation.
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
  typed/rendered design-gate packet, and optional lightweight read-only Proposal 156
  lens inclusion. Later iterations stay in this feature and cover the four
  smoke-test defects: empty `specs//...` start-packet paths, noisy downstream
  warnings, fresh greenfield baseline commit handling, and host wording leaks. The
  plan proposes the concrete split and capacity model.
- Q: How should feature 141 relate to the unmerged Feature 140 branch (FR-017)? A:
  Stacking 141 on the Feature 140 tip is acceptable because Iteration 1 depends on
  Feature 140 runtime code that is not yet on main. The dependency is kept explicit
  in the artifacts, and the branch is ready to rebase/refresh after Feature 140
  merges.

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
