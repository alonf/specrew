# Feature Specification: Beta-Before-Stable SDLC Discipline

**Feature Branch**: `048-beta-before-stable-sdlc`  
**Created**: 2026-05-26  
**Status**: Draft  
**Input**: F-048 request from Alon Fliess: codify the beta-before-stable
release discipline after F-047. Decisions are fixed: coordinator-prompt
feature-closeout must carry the full Steps 5-14 sequence from Proposal 060
and Proposal 131; `docs/release-discipline.md` must codify
`[[feedback-beta-publish-before-stable-2026-05-26]]`; a post-merge release
audit-trail mechanism must produce a structured release record plus a
human-readable per-feature narrative, using a trailing one-file PR for
locked-main repositories and an opt-in `release_audit_direct_to_main: true`
shortcut for unlocked repositories.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Agent-Owned Beta-Before-Stable Handoff (Priority: P1)

A Specrew coordinator reaches feature-closeout. The generated handoff makes it
clear that the agent owns the SDLC execution and the human owns approvals and
manual validation. The handoff enumerates Steps 5-14: push the feature branch,
open a PR, self-review and monitor automated review, merge, tag beta, verify
prerelease publication, pause for human PASS/FAIL, loop on FAIL with the next
beta, tag stable after PASS, publish stable, and stop before new feature work.

**Why this priority**: This fixes the F-047 closeout regression where adding
PR steps to `HUMAN ACTION NEEDED` made the agent stop before PR creation. The
beta-before-stable rule only works if the coordinator knows which steps the
agent drives and where human approval is required.

**Independent Test**: Render or inspect the coordinator feature-closeout
handoff template and assert both `AGENT NEXT ACTION:` and
`HUMAN ACTION NEEDED:` rows are present, and all Steps 5-14 appear with the
required semantics.

**Acceptance Scenarios**:

1. **Given** a feature reaches feature-closeout, **When** the coordinator
   emits the handoff, **Then** `AGENT NEXT ACTION:` instructs the agent to
   execute Steps 5-14 and pause at approval/verdict points.
2. **Given** the same handoff, **When** a human reads it, **Then**
   `HUMAN ACTION NEEDED:` asks for approvals and the Step 11 manual
   prerelease PASS/FAIL verdict, not for the human to perform agent-owned
   push/PR/tag/publish work.
3. **Given** the Step 11 human verdict is FAIL, **When** the coordinator
   resumes, **Then** the handoff semantics direct a fix loop that tags the
   next beta and repeats prerelease verification before stable promotion.

---

### User Story 2 - Release Discipline Documentation (Priority: P1)

A maintainer or contributor needs a durable policy document explaining how
Specrew releases move from feature-closeout to stable publication. The project
includes `docs/release-discipline.md`, codifying the
`[[feedback-beta-publish-before-stable-2026-05-26]]` standing rule: every
runtime-affecting feature publishes beta first, the human validates the
installed prerelease from PSGallery, and stable publication happens only after
an explicit PASS verdict.

**Why this priority**: Prompt wording alone is easy to lose or misread. The
release discipline must exist as reviewed project documentation that explains
the rule, exceptions, human validation evidence, and failure loop.

**Independent Test**: Inspect `docs/release-discipline.md` and assert it
documents Steps 5-14, the PASS/FAIL gate, proposal-only exemptions,
locked-main audit behavior, and the opt-in direct-main shortcut.

**Acceptance Scenarios**:

1. **Given** a contributor opens the release discipline documentation,
   **When** they read the feature-closeout section, **Then** they can identify
   the exact beta-before-stable sequence and required human PASS verdict.
2. **Given** a feature is proposal-only and changes no runtime artifact,
   **When** the contributor checks the policy, **Then** the document explains
   why no beta publication is required.
3. **Given** the beta validation fails, **When** the contributor checks the
   policy, **Then** the document explains the beta.N fix loop and forbids
   stable publication until PASS.

---

### User Story 3 - Post-Merge Release Audit Trail (Priority: P1)

After a feature PR merges and beta/stable publication completes, the Crew
records what happened in a durable release audit artifact. The artifact
contains structured release-record fields for tooling and a human-readable
per-feature narrative for maintainers. For locked-main repositories, the
record is committed through a trailing one-file PR per feature after stable
publication; for unlocked repositories, an explicit
`release_audit_direct_to_main: true` configuration flag allows direct commit to
main.

**Why this priority**: The beta-before-stable lifecycle produces important
post-merge facts: merge SHA, beta tag(s), package verification, PASS/FAIL
evidence, stable tag, and publish result. Without a post-merge audit trail,
future reviewers cannot reconstruct whether the release discipline was
followed.

**Independent Test**: Run the planned release-audit command or helper against
a synthetic completed feature and assert it produces one human-readable file
with a structured record section, records the beta/stable evidence, and chooses
the correct locked-main PR path unless `release_audit_direct_to_main: true` is
set.

**Acceptance Scenarios**:

1. **Given** a feature has merged, beta published, human PASS recorded, and
   stable published, **When** release audit capture runs, **Then** the audit
   artifact records the merge SHA, PR number, beta tag(s), package
   verification, human PASS evidence, stable tag, and stable publish
   verification.
2. **Given** the repository is configured for locked-main behavior, **When**
   release audit capture runs, **Then** it prepares or opens a trailing
   one-file PR containing only the per-feature audit narrative/record.
3. **Given** `release_audit_direct_to_main: true` is configured, **When**
   release audit capture runs in an unlocked repository, **Then** it commits
   the audit artifact directly to main using the same schema and content
   rules.
4. **Given** required release evidence is missing, **When** audit capture
   runs, **Then** it refuses to mark the audit complete and reports the
   missing fields.

---

### User Story 4 - Release Workflow Verification and Guardrails (Priority: P2)

A reviewer needs automated confidence that the new SDLC language, docs, and
audit mechanism remain aligned. Tests verify the feature-closeout template,
release discipline documentation, release audit schema, config flag behavior,
and mirror parity for any extension template or script changes.

**Why this priority**: This feature changes governance behavior. It must be
hard to regress back to human-owned PR creation, stable-before-beta
publication, or undocumented post-merge release evidence.

**Independent Test**: Run the focused integration tests for handoff format,
release audit generation, release discipline documentation, and mirror parity;
assert all pass.

**Acceptance Scenarios**:

1. **Given** a future template edit removes any Step 5-14 item, **When** tests
   run, **Then** the handoff-format test fails.
2. **Given** a future docs edit removes the human PASS requirement, **When**
   tests run, **Then** the documentation coverage test fails.
3. **Given** a release audit artifact is missing required structured fields,
   **When** validation runs, **Then** the schema or integration test fails.

### Edge Cases

- **Proposal-only changes**: A feature that only updates proposals or planning
  docs and changes no runtime artifact does not require beta/stable publishing,
  but any release audit note must make the exemption explicit.
- **Multiple beta failures**: The audit record must support `beta.1`,
  `beta.2`, and later beta attempts with their individual failure/PASS
  evidence.
- **Locked-main repositories**: The default path must not require direct push
  to protected `main`; it must support a trailing audit-only PR.
- **Unlocked repositories**: The direct-main shortcut must be opt-in and
  explicit; absence of the flag keeps the safer trailing-PR behavior.
- **Human verdict integrity**: Stable publication must not proceed from a
  missing, ambiguous, or non-PASS human verdict.
- **No new feature work**: After stable publication and audit capture, the
  lifecycle stops before beginning another feature.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The coordinator-prompt feature-closeout handoff template MUST
  include an `AGENT NEXT ACTION:` row that instructs the agent to execute
  Steps 5-14 with explicit pauses for human approvals and verdicts.
- **FR-002**: The coordinator-prompt feature-closeout handoff template MUST
  include a `HUMAN ACTION NEEDED:` row that asks the human to approve agent
  actions and provide the Step 11 prerelease manual test PASS/FAIL verdict.
- **FR-003**: Steps 5-14 MUST cover, in order: push branch, create PR,
  self-review and monitor automated review, merge with merge-commit history,
  tag/push `v<version>-beta.1`, verify prerelease package publication, pause
  for human prerelease validation, loop on FAIL with incremented beta tags,
  tag/push stable after PASS, verify stable publication, and stop before new
  feature work.
- **FR-004**: The Step 12 fail loop MUST support multiple failed prereleases
  and MUST require a new beta tag plus repeated prerelease verification before
  stable promotion.
- **FR-005**: The feature MUST add `docs/release-discipline.md` documenting
  the beta-before-stable standing rule, Steps 5-14, human validation evidence,
  proposal-only exemptions, locked-main audit flow, direct-main opt-in, and
  stable-promotion criteria.
- **FR-006**: The release discipline documentation MUST state that stable
  publication is blocked until the human reports an explicit PASS on the
  installed prerelease package.
- **FR-007**: The feature MUST provide a release audit mechanism that records,
  for each released feature, structured fields for feature reference, PR
  number, merge SHA, beta tags, package verification evidence, human verdicts,
  stable tag, stable package verification, audit capture timestamp, and audit
  completion status.
- **FR-008**: The release audit mechanism MUST include a human-readable
  per-feature narrative artifact that can be reviewed independently of tooling.
- **FR-009**: The default release audit write path MUST support locked-main
  repositories by preparing or opening a trailing one-file PR that contains the
  per-feature release audit artifact after stable publication.
- **FR-010**: The project configuration MUST support an opt-in
  `release_audit_direct_to_main: true` flag that permits direct commit of the
  same release audit artifact to `main` in unlocked repositories.
- **FR-011**: The direct-main shortcut MUST be disabled unless the flag is
  explicitly set to `true`; missing or false configuration MUST use the
  trailing one-file PR path.
- **FR-012**: The release audit mechanism MUST refuse to mark an audit complete
  when required release evidence is missing or when the human verdict is not
  explicit PASS.
- **FR-013**: The feature MUST include focused tests for handoff template
  shape, Step 5-14 coverage, release discipline documentation coverage, release
  audit record generation, missing-evidence behavior, and direct-main flag
  behavior.
- **FR-014**: Any change to files under `extensions/specrew-speckit/` that has
  a deployed mirror under `.specify/extensions/specrew-speckit/` MUST be kept
  byte-identical with the mirror.
- **FR-015**: The feature MUST update durable project planning metadata
  affected by shipping Proposal 060 and Proposal 131 scope, including proposal
  status/index notes where applicable.
- **FR-016**: Release-tagging, package-publish, and direct-main audit behavior
  MUST be documented and implemented so the agent cannot treat missing
  credentials, missing PR state, missing workflow result, or missing human PASS
  as a successful release.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: US1 maps to FR-001, FR-002, FR-003, and FR-004. Owner:
  Spec Steward + Implementer. Delivery: iteration 001.
- **TG-002**: US2 maps to FR-005 and FR-006. Owner: Spec Steward. Delivery:
  iteration 001.
- **TG-003**: US3 maps to FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, and
  FR-016. Owner: Planner + Implementer. Delivery: iteration 001 or iteration
  002 if planning splits the audit mechanism from template/docs work.
- **TG-004**: US4 maps to FR-013, FR-014, and FR-015. Owner: Reviewer.
  Delivery: every implementation iteration.
- **TG-005**: Any conflict between the single-file trailing PR requirement and
  the structured-plus-narrative audit requirement MUST be reconciled by storing
  structured record data inside the one human-readable per-feature audit file,
  unless the implementation plan explicitly justifies a different one-file
  shape.
- **TG-006**: Any new release or audit command surface MUST be documented in
  the plan, contract artifact, release discipline docs, and tests before
  implementation closes.

### Key Entities *(include if feature involves data)*

- **ReleaseLifecycleStep**: A numbered SDLC action from Step 5 through Step 14,
  including the actor, required evidence, and pause/continue semantics.
- **FeatureCloseoutHandoff**: The generated handoff block at feature-closeout,
  containing `AGENT NEXT ACTION:` and `HUMAN ACTION NEEDED:` rows.
- **ReleaseAuditRecord**: Machine-readable release evidence for one feature:
  feature ref, PR, merge SHA, beta attempts, package verification, human
  verdict, stable publish evidence, and status.
- **ReleaseAuditNarrative**: The per-feature human-readable audit artifact
  that includes the structured record and explanatory release timeline.
- **ReleaseAuditConfig**: Project configuration controlling whether audit
  capture uses the default trailing one-file PR or the explicit direct-main
  shortcut.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of feature-closeout handoff template checks find both
  `AGENT NEXT ACTION:` and `HUMAN ACTION NEEDED:` rows with all Steps 5-14 in
  order.
- **SC-002**: A synthetic FAIL at Step 11 produces a documented loop back to
  beta tagging and does not permit stable publication.
- **SC-003**: `docs/release-discipline.md` exists and covers Steps 5-14,
  explicit PASS gating, proposal-only exemptions, locked-main audit PRs,
  direct-main opt-in, and no-new-feature-work after release.
- **SC-004**: A synthetic completed release produces one per-feature audit
  artifact containing all required structured fields and a readable narrative.
- **SC-005**: With default configuration, audit capture selects the trailing
  one-file PR path; with `release_audit_direct_to_main: true`, it selects
  direct-main capture.
- **SC-006**: Missing merge SHA, package verification, or explicit human PASS
  causes audit completion to fail or remain incomplete in tests.
- **SC-007**: Mirror parity is byte-identical for every modified mirrored
  extension file.
- **SC-008**: Focused integration tests and governance validation pass with no
  unapproved FAIL findings.

## Assumptions

- F-047 is closed: PR #985 merged at `19a0c5e4`, and v0.27.3/v0.27.4 stable
  were already published before this feature begins.
- The publish workflow primitives for beta and stable tags already exist; this
  feature focuses on lifecycle codification, documentation, and audit capture
  unless planning discovers a missing primitive that blocks the requirements.
- `release_audit_direct_to_main: true` is intended for unlocked repositories
  like this one; protected-main repositories should use the trailing one-file
  PR path by default.
- The one-file trailing PR requirement is satisfied by one per-feature audit
  file that contains both structured record data and the human-readable
  narrative.
- Exact schema, file names, CLI command shape, and iteration split are delegated
  to the Crew during planning, as requested by the human developer.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Specrew Crew Coordinator under requestor authority from
  Alon Fliess.
- **Iteration Facilitator**: Specrew Crew Coordinator.
- **Capacity Model**: One or two implementation iterations depending on the
  planned size of the audit mechanism; template/docs work must land before
  audit automation.
- **Drift Signals**: Missing Step 5-14 coverage, prompt/docs mismatch,
  audit-schema/test mismatch, release evidence accepted without PASS, mirror
  parity divergence, or direct-main behavior without explicit opt-in.
- **Human Oversight Points**: Specify completion, clarify outcome,
  before-implement approval, review sign-off, retro, feature-closeout PR/merge,
  beta PASS/FAIL verdict, stable release approval, and lifecycle-end.
