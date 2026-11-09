# Feature Specification: Workshop Lens Order (Proposal 220)

**Feature Branch**: `205-workshop-lens-order`
**Created**: 2026-11-10
**Status**: Draft
**Input**: Proposal 220 (`proposals/220-workshop-lens-order-and-cross-lens-consistency.md`), its iteration 1. The scope was set by the maintainer and the design workshop recorded under `specs/205-workshop-lens-order/workshop/`.

## Workshop Summary

The workshop records under `workshop/` are the source of truth. This section summarizes them.

- **Product-domain (Light)**:
  - Who it affects: the human in a Specrew design workshop and the crew agent that runs it.
  - The pain: a structural question is asked before the qualities that drive it are known. The lens order is defined in five places that disagree (the skill, index.yml, the methodology, the before-specify command, and per-feature agendas). Two lenses ask the binding-constraints question.
  - The fix: one order in index.yml, and problem space before solution space.
- **Iterations** (scope amendment, 2026-11-10):
  - Iteration 1 (this spec's delivery scope): order, tagging, parity proof, migration.
  - Iteration 2: problem-space completeness, filling thin problem-side questions. It gets its own short workshop.
  - Iteration 3: the two-pass split (proposal FR-002/FR-003), the end-of-lens back-check, amendments and final sweeps. It waits for feature 203 to merge.
- **requirements-nfr**: binding constraints and scope (moved here from architecture-core); the parity proof; the tagging proof; the failure output.
- **architecture-core**:
  - Order option A, with the problem section asked first inside every lens.
  - Prose lists are kept and parity-checked.
  - Full lists must match exactly; partial lists keep relative order.
  - The skill states that index.yml wins.
- **data-storage**:
  - `space: problem | solution | both` in index.yml, with list position as the order.
  - `###` sub-headings inside `## Design Decision Points`.
  - A mixed bullet is split, keeping its words.
  - No new agenda field.
- **devops-operations**:
  - The failure message names the two project-only deploy scripts.
  - Full-content comparison of the touched copies.
  - A named CI step, markdownlint before each push, and CI followed to conclusion after each push.
  - The skill sentence gains "a confirmed agenda keeps the order it was confirmed in".
- **code-implementation**:
  - Repo conventions, PowerShell 7, test-first, the existing refusal helper, no new dependency.
  - Reviewer: codex.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Problem facts come before structure (Priority: P1)

A human running a new feature's design workshop is asked what qualities, constraints and obligations matter before being asked to choose a decomposition, storage model, protocol or hosting.

**Why this priority**: This is the maintainer's ruling and the reason for the feature.

**Independent Test**: Confirm a new agenda that selects lenses from both spaces. The confirmed order follows index.yml: product-domain, then requirements-nfr, then ui-ux, security-compliance, data-storage, integration-api and devops-operations, then architecture-core, component-design, observability-resilience and code-implementation. Inside a lens, the problem questions come before its solution questions.

**Acceptance Scenarios**:

1. **Given** a new feature, **When** the crew renders the agenda in index.yml order, **Then** the agenda writer accepts it.
2. **Given** a new feature, **When** the crew renders architecture-core ahead of requirements-nfr, **Then** the agenda writer refuses. The refusal names the out-of-order lenses and the index.yml order, and does not reorder anything.
3. **Given** any lens file, **When** the crew opens that lens, **Then** its problem questions are listed before its solution questions.

---

### User Story 2 - The order cannot drift again (Priority: P1)

A maintainer changes the lens order or adds a lens. Every surface that disagrees is reported in one test run, with the fix for each.

**Why this priority**: The order drifted into five definitions because nothing checked them.

**Independent Test**: Run the parity test on today's tree. It fails and reports every disagreeing surface in one run. After the change, it passes.

**Acceptance Scenarios**:

1. **Given** a full lens list (the skill's list, the methodology catalog tables, the catalog README, the before-specify command list) whose order or membership differs from index.yml, **When** the parity test runs, **Then** it fails with the file and line, the expected order, the order found, and the fix.
2. **Given** a lens added to index.yml only, **When** the parity test runs, **Then** every full list fails until it carries the new lens.
3. **Given** a partial list, such as an example agenda, whose lenses keep index.yml's relative order, **When** the parity test runs, **Then** it passes without an exemption.
4. **Given** a new ordered run of three or more lens ids anywhere in shipped text, out of relative order and not exempted, **When** the parity test runs, **Then** it fails.
5. **Given** a file under `specs/` or `proposals/`, **When** the parity test runs, **Then** that file is neither scanned nor changed.
6. **Given** a deployed copy that differs from its source, **When** the parity test runs, **Then** it fails, and the message names the two project-only deploy commands and says they never write to the home folder.
7. **Given** several mismatches, **When** the parity test runs, **Then** every one is reported in that single run.

---

### User Story 3 - Each lens's questions are tagged by space, and the tagging cannot drift (Priority: P2)

A crew agent, or the iteration 3 back-check, can tell which questions of each lens are problem-space and which are solution-space. A test proves the tags and index.yml agree.

**Why this priority**: The tagging enables problem-first within a lens, and it is the base for iterations 2 and 3.

**Independent Test**: Run the tagging checks over all 11 lens files and index.yml.

**Acceptance Scenarios**:

1. **Given** a lens file, **When** the checks run, **Then** it has `### Problem questions` and `### Solution questions` inside `## Design Decision Points`. A one-space lens keeps the empty heading with the line "No <space> questions: <reason>".
2. **Given** a decision point outside both sub-headings, **When** the checks run, **Then** they fail.
3. **Given** a lens whose index.yml `space` disagrees with the sub-headings its file actually fills, **When** the checks run, **Then** they fail.
4. **Given** the tagged files, **When** `Get-SpecrewLensDecisionPoints` runs for each lens, **Then** it returns exactly the points under both sub-headings.

---

### User Story 4 - Features already in or past their workshop are unaffected (Priority: P2)

A project that updates Specrew in the middle of a workshop keeps its confirmed agenda and its order.

**Why this priority**: Required by FR-013. A changed agenda mid-workshop reads as lost answers.

**Independent Test**: Take an agenda confirmed in the old order (architecture-core first), resume it under the new code, and complete it.

**Acceptance Scenarios**:

1. **Given** an agenda confirmed before this release, **When** the workshop resumes and lenses close, **Then** nothing re-checks or reorders it, and it completes.
2. **Given** an agenda still pending confirmation at the release, **When** it is confirmed, **Then** the new order rule applies.

---

### User Story 5 - Iteration 2 gets its input (Priority: P3)

While tagging each lens, the crew lists every problem-side gap it sees for that lens, for example data-storage never asking what data exists, how sensitive it is, how much there is, or what must be carried over.

**Why this priority**: This is iteration 2's input, and it costs little because the tagging pass reads every question anyway.

**Independent Test**: The gap list exists, has an entry (or "none seen") for each of the 11 lenses, and changes no lens question.

**Acceptance Scenarios**:

1. **Given** the tagging pass, **When** it completes, **Then** a per-lens gap list is recorded in the feature's iteration artifacts and no question was added.

### Edge Cases

- A lens with questions in only one space (for example requirements-nfr, or architecture-core after the move) keeps both sub-headings, with a one-line reason under the empty one.
- A bullet that mixes both spaces is split into two bullets that keep its words and meaning. Every split is listed in the plan.
- A partial list that legitimately differs from index.yml's relative order needs an exemption with a stated reason. The exemption list is shown to the maintainer and is expected to be close to empty.
- A workshop test that is already red before this feature is reported to the maintainer as a finding, with its failure. It is neither fixed silently nor left out silently.
- product-domain and code-implementation have differently shaped sections. They get the same two sub-headings.

## Requirements *(mandatory)*

Requirement ids keep proposal 220's numbers where the maintainer named them. FR-015 and later are new in this feature. The proposal's FR-002, FR-003, FR-006 to FR-012 and FR-014 belong to iteration 3 (see TG-003).

### Functional Requirements

- **FR-001**: `index.yml` MUST be the only definition of the lens order and each lens's space. A parity test MUST check:
  - every full list (the skill's list, the methodology catalog tables, the catalog README, the before-specify command list) for exact order and membership
  - every partial list for index.yml's relative order
  - every other ordered run of three or more lens ids in shipped text, excluding `specs/` and `proposals/`; such a run fails unless it is in relative order or carries an exemption with a reason
  - every deployed copy of a touched file for full-content equality with its source, ignoring the deploy wrapper

  The test MUST name the full surfaces in its own code.
- **FR-004**: requirements-nfr MUST own the binding-constraint and scope questions, and architecture-core MUST NOT ask them. architecture-core's "Which constraints are binding, and which are preferences?" duplicates requirements-nfr's existing "Which constraints are mandatory rather than preferences?", so the two are merged into requirements-nfr's existing question. Only the scope question ("What is deliberately out of scope for this iteration?") is added to requirements-nfr.
- **FR-005**: Each lens file MUST carry `### Problem questions` and `### Solution questions` inside `## Design Decision Points`. A one-space lens MUST keep the empty heading with a one-line reason. Every decision point MUST sit under exactly one sub-heading. A test MUST prove these, prove that each file agrees with index.yml's `space`, and prove that `Get-SpecrewLensDecisionPoints` returns exactly the tagged points for every lens.
- **FR-013**: Agendas confirmed before this release MUST NOT be re-checked or reordered. The order check MUST run only when an agenda is confirmed. A test MUST prove that an old-order confirmed agenda resumes and completes.
- **FR-015**: `index.yml` MUST give each lens a `space` of `problem`, `solution` or `both`, and a lens's position in the list MUST be the order:
  - product-domain, requirements-nfr: problem
  - ui-ux, security-compliance, data-storage, integration-api, devops-operations: both
  - architecture-core, component-design, observability-resilience, code-implementation: solution

  These tags are the expected result, not a target to force. If tagging finds a lens whose questions disagree with its expected tag, the crew MUST bring that lens to the maintainer before deciding. A question MUST NOT be filed under the wrong heading to make the check pass.
- **FR-016**: The agenda writer MUST refuse a new agenda whose selected lenses break index.yml's relative order. It MUST refuse through the existing refusal helper, naming the out-of-order lenses and the index.yml order, with one action, and MUST NOT reorder silently.
- **FR-017**: The workshop skill and methodology MUST describe the single-pass order from index.yml, with each lens's problem questions asked before its solution questions.
- **FR-018**: The workshop skill MUST state that if any list disagrees with index.yml, index.yml wins, and that a confirmed agenda keeps the order it was confirmed in.
- **FR-019**: A mismatch report MUST name the file and line, the expected order, the order found, and the fix, and one run MUST report every mismatch. For a deployed copy, the fix MUST name `deploy-speckit-extension.ps1 -ProjectPath . -RefreshExisting` and `deploy-squad-runtime.ps1 -ProjectPath .`, say they write inside the project only, and say they also restamp `.squad` runtime files.
- **FR-020**: The tagging pass MUST record a per-lens list of problem-side gaps as iteration 2's input, and MUST NOT add or reword questions, apart from the split rule and the FR-004 move.
- **FR-021**: Every existing workshop test MUST be run locally and its result reported. Named `specrew-ci.yml` steps MUST cover the new parity test, the extended agenda-confirmation test, and every existing workshop test that covers a file this feature touches and passes. An already-red workshop test MUST be reported as a finding.
- **FR-022**: Proposal 220 MUST move to `status: active` with `shipped-as: feature-205`. Its status history MUST gain a line recording the three iterations (1: order, tagging, parity, migration; 2: problem-space completeness; 3: two-pass split, back-check, amendments and sweeps after 203), the fifth order surface found at intake (the before-specify command list), and the choice of order option A. `proposals/INDEX.md` MUST follow in both its table row and its summary line.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story maps to functional requirements:
  - US1: FR-015, FR-016, FR-017
  - US2: FR-001, FR-019
  - US3: FR-005
  - US4: FR-013, FR-018
  - US5: FR-020
  - FR-004, FR-021 and FR-022 cut across the stories.
- **TG-002**: The implementer owns all FRs, the reviewer (codex co-review) owns review evidence, and the spec steward owns drift.
- **TG-003**: All FRs above are in iteration 001. Problem-space completeness is iteration 002. Iteration 003, after 203 merges, holds the two-pass split (proposal FR-002/FR-003), the back-check, amendments and sweeps (proposal FR-006 to FR-012, FR-014).
- **TG-004**: Any spec or implementation conflict is recorded in the iteration drift log and routed through clarify, never edited silently into this spec.

### Key Entities

- **Lens catalog entry** (`index.yml`): id, file, `space` (new), default_phase (unchanged), categories. Its list position is the order.
- **Lens file**: `## Design Decision Points` with `### Problem questions` and `### Solution questions`.
- **Order surface**: a shipped text location listing lenses, classified in the test as full or partial.
- **Exemption**: a surface that must differ, with its stated reason.
- **Problem-side gap list**: per lens, the problem questions it lacks. Iteration 2's input.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the pre-change tree, the parity test fails and reports every disagreeing order surface, at least the five known ones, in a single run. After the change it passes.
- **SC-002**: All 11 lens files pass the tagging checks, and for each lens the extractor returns exactly the tagged points. For every lens, the post-change count is the pre-change count plus one per split bullet in that lens, with two adjustments: architecture-core has two fewer (its constraints question merged into requirements-nfr's, its scope question moved), and requirements-nfr has one more (the scope question). No other lens changes count.
- **SC-003**: The exemption list is shown to the maintainer, and every entry has a reason.
- **SC-004**: The old-order agenda fixture resumes and completes, and an out-of-order new agenda is refused with zero reordering.
- **SC-005**: The named CI steps pass on the feature branch's push, and Specrew CI, Test and Cross-Platform Validation all conclude green with no skipped gate job.
- **SC-006**: The problem-side gap list covers all 11 lenses.

## Clarifications

### Session 2026-11-10

- No open questions. The maintainer approved recording this at the specify verdict ("Clarify may record 'no open questions'"). The intake workshop resolved the ambiguities that clarify would otherwise raise, and the maintainer's five corrections at the specify review closed the rest:
  - the two-pass split is assigned to iteration 3
  - FR-015's tags are the expected result, and a disagreement goes to the maintainer
  - the FR-004 merge and the corrected SC-002 formula
  - FR-022, the proposal status
  - the before-specify list counts as a full list
- Clarify ran only after Specrew CI, Test and Cross-Platform Validation all concluded green on `700e6127` with no skipped job, as the maintainer instructed. Specrew CI passed on its approved single rerun; the first-attempt failure is recorded as DRIFT-205-INTAKE-001 in `workshop/intake-drift-log.md`.

## Assumptions

- The two-pass split (proposal FR-002/FR-003) is out of iteration 1. The maintainer assigned it to iteration 3 on 2026-11-10, with the back-check, amendments and sweeps.
- The before-specify command list is a full list. The maintainer confirmed this on 2026-11-10.
- `Read-IntakeYamlDocument -Kind lenses` parses `space` as bare or quoted and keeps list order. This was verified on a scratch copy on 2026-11-10.
- The two deploy scripts refresh every checked copy, including `.cursor`, and never write to the home folder. This was verified in scratch on 2026-11-10.
- `scripts/specrew-update.ps1` is never run in this worktree while 203 is unmerged: it writes to the home folder, and on main it cannot redirect.
- Feature 204 is reserved for init/bootstrap work. Feature 203, its pin and `C:\Dev\specrew-b4f-142` are untouched.

## Governance Alignment *(mandatory)*

- **Spec Steward**: the spec-steward role, with the maintainer as the final authority on scope.
- **Iteration Facilitator**: the Claude coordinator for this session.
- **Capacity Model**: story points. Iteration 001 is estimated at about 10 to 15 SP (proposal 220 effort).
- **Drift Signals**: the parity and tagging tests, the iteration drift log, and codex co-review findings.
- **Human Oversight Points**: every boundary (specify, clarify, plan, tasks, before-implement, review signoff, retro, closeout). Also markdownlint before each push and CI followed to conclusion after each push.
