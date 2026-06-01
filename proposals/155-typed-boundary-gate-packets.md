---
proposal: 155
title: Typed Boundary Gate Packets
status: draft
phase: phase-2
estimated-sp: 10-16
priority-tier: 1
discussion: surfaced 2026-06-01 during Feature 139 release-recovery dogfooding after repeated D-004/D-005 escapes showed that prompt guidance and stored handoff evidence cannot reliably control the human-visible gate packet
composes-with:
  - 007  # Substantive Interaction Model
  - 016  # Outcome Scoring
  - 056  # Specrew Readonly Mode
  - 120  # Handoff Contract Validator Enforcement
  - 151  # Boundary Handoff Contract Unification
  - 154  # Boundary Authorization Prompt Truth
---

# Typed Boundary Gate Packets

## Why

Specrew's lifecycle depends on human approval at boundaries. The human should know what happened, why the lifecycle stopped, what needs review, what happens next, and what choices can still change direction before the next phase begins.

Feature 139 hardened the boundary prompt truth problem for `v0.30.0-beta2`: generated prompts must not fabricate authorization, must stop at human-judgment gates, and must use the six-section human re-entry packet instead of thin approval prose. During the same dogfooding cycle, two additional failures appeared:

- **D-004**: artifact references in the primary packet could still be bare paths even when the legacy `=== SPECREW HANDOFF ===` block used `file:///` links.
- **D-005**: stored packet evidence could validate while the human-visible packet diverged from it.

Those failures expose the deeper gap: Specrew does not own the authoritative gate message. The model still authors critical gate text as free-form console prose, and the host usually does not expose a pre-send hook where Specrew can validate or rewrite the final answer before the human sees it.

Prompt instructions help, but they are advisory. The governance object at a boundary must be rendered, validated, stored, and approved as a durable artifact.

## What

Introduce typed boundary gate packets. The AI provides structured facts and recommendations; Specrew renders the authoritative human packet from a gate-specific schema and template.

The core flow:

1. Agent reaches a lifecycle boundary.
2. Agent provides structured packet fields.
3. Specrew renders the typed packet using the boundary-specific template.
4. Specrew validates the rendered packet.
5. Specrew stores the exact packet as durable gate evidence with a packet ID and hash.
6. Boundary state records the packet ID and hash.
7. The agent presents the rendered packet verbatim.
8. The human approves, sends back, or discusses that packet ID.

The authoritative approval target becomes the packet, not loose chat prose. The AI can still discuss the situation, but discussion that changes direction must either preserve the current packet or produce an amended packet before approval.

### Artifact layout

Add a `gates/` directory under each feature:

```text
specs/<feature>/gates/
  feature/
    clarify-to-plan.md
    plan-to-tasks.md
    feature-closeout-to-release-closeout.md
  iterations/
    001/
      tasks-to-before-implement.md
      before-implement-to-implement.md
      implement-to-review.md
      review-to-retro.md
      retro-to-iteration-closeout.md
      iteration-closeout-to-feature-closeout.md
```

Every packet has frontmatter:

```yaml
---
packet_id: gate-139-iter-001-implement-to-review-20260601T120501Z
feature: 139-boundary-authorization-prompt-truth
iteration: "001"
from_boundary: implement
to_boundary: review
source_commit: e02e89e0
rendered_at: 2026-06-01T12:05:01Z
validation_status: pass
packet_hash: sha256:<hash>
visible_packet_required: true
---
```

The body contains the rendered human packet. The packet file is both human-readable and machine-verifiable.

Because gate artifacts remain editable after the boundary, the packet must also pin the artifact references to the gate commit. The human-visible link opens the current workspace copy for convenience, while the packet evidence records the exact commit version that was reviewed.

### Packet schema

Every packet type includes the six common sections:

1. `What I Just Did`
2. `Why I Stopped`
3. `What Needs Your Review`
4. `What Happens Next`
5. `Discussion Prompts`
6. `What I Need From You`

Each packet also carries typed metadata:

- feature ID and slug
- iteration number when applicable
- from-boundary and to-boundary
- source commit or pending commit state
- review targets with canonical `file:///` URLs and commit-pinned retrieval metadata
- release blockers
- test evidence
- dirty-state classification
- discussion prompts with defaults and consequences
- allowed response options
- packet ID and hash

### Review target pinning

Every review target in `What Needs Your Review` should be represented as structured data before rendering:

```yaml
review_targets:
  - label: closeout-dashboard.md
    path: specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md
    file_url: file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md
    as_of_commit: 91c9ede1
    retrieval_command: git show 91c9ede1:specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md
    review_focus: Feature closeout status, D-004/D-005 acceptance, release blockers.
```

The rendered packet may keep the visible prose concise, but the durable packet file must preserve enough information to recover the exact referenced content later:

```text
Review closeout-dashboard.md:
file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md
As reviewed at commit: 91c9ede1
Exact content: git show 91c9ede1:specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md
```

This creates two review modes:

- **Current workspace navigation**: open the `file:///` link during the active review.
- **Historical audit**: use `git show <commit>:<path>` to reconstruct exactly what the gate packet referenced when the human approved it.

### Gate-specific packet types

Each boundary has a typed template with additional required fields:

#### Clarify to plan

- spec summary
- clarification decisions
- unresolved assumptions
- planning consequences
- review targets
- discussion prompts about scope or architecture

#### Plan to tasks

- plan artifacts produced
- architecture choices
- high-risk decisions
- what can still change cheaply
- what becomes harder after tasking
- expected tasking outputs

#### Tasks to before-implement

- task count and FR/SC coverage
- traceability status
- implementation-readiness risks
- expected hardening gate inputs
- code-write boundary warning

#### Before-implement to implement

- hardening gate verdict
- implementation scope
- expected files or modules
- test strategy
- release-blocking concerns
- explicit code-write approval requirement

#### Implement to review

- commits made
- files changed
- tests run, including failures and timeouts
- drift events
- dirty-state classification
- review surfaces

#### Review to retro

- review verdict
- FR/SC coverage
- remaining risks
- release follow-ups
- evidence surfaces

#### Retro to iteration-closeout

- lessons learned
- accepted gaps
- carry-forward actions
- iteration closeout expectations

#### Iteration-closeout to feature-closeout

- iteration completion status
- dashboards
- drift and gap status
- remaining feature-level work

#### Feature-closeout to release-closeout

- feature acceptance status
- release blockers
- beta package verification plan
- published-host replay requirements
- stable-promotion stop conditions

### Functional requirements

- **FR-001**: Specrew MUST render boundary gate packets from structured data instead of relying on free-form AI-authored gate prose as the authoritative approval object.
- **FR-002**: Specrew MUST store every rendered gate packet under `specs/<feature>/gates/`.
- **FR-003**: Every stored packet MUST include packet ID, feature, boundary names, source commit state, rendered timestamp, validation status, and packet hash.
- **FR-004**: Boundary state MUST record the packet ID and packet hash for the current human-judgment stop.
- **FR-005**: A lifecycle boundary MUST NOT advance unless the corresponding packet is stored and validates successfully.
- **FR-006**: Packet validation MUST require all six common human re-entry sections.
- **FR-007**: Packet validation MUST require every artifact, file, or directory reference in packet prose to use `file:///` URL form unless inside an explicit command or code exemption.
- **FR-008**: Packet validation MUST check the primary packet body, not only the legacy `=== SPECREW HANDOFF ===` block.
- **FR-009**: If legacy handoff compatibility output remains, it MUST NOT satisfy packet validation by itself.
- **FR-010**: Specrew MUST reject a packet where the primary six-section packet contains bare paths even if the legacy handoff block contains compliant `file:///` links.
- **FR-011**: The packet renderer SHOULD normalize known local paths into `file:///` URLs before validation.
- **FR-012**: Packet validation MUST require release blockers and test failures/timeouts to be explicit when present.
- **FR-013**: Packet validation MUST require dirty working-tree classifications when dirty files are present at a boundary.
- **FR-014**: Human approval MUST target the packet ID or the currently active packet recorded in boundary state.
- **FR-015**: Discussion that changes direction MUST produce either an amended packet or an explicit no-change decision before boundary approval.
- **FR-016**: The packet validator MUST provide actionable errors that name the non-compliant section and offending reference.
- **FR-017**: Specrew MUST provide a replay or inspection command to show the last gate packet for the active feature.
- **FR-018**: Review and closeout artifacts MUST be able to reconstruct what packet was approved at each boundary.
- **FR-019**: Every review target in a packet MUST record the artifact path, canonical `file:///` URL, as-of commit, and exact `git show <commit>:<path>` retrieval command.
- **FR-020**: The as-of commit for each review target MUST default to the gate commit when the target exists in that tree; if a target is generated after the gate commit, the packet MUST record the correct later source commit explicitly.
- **FR-021**: Packet validation MUST verify that each review target path exists at its recorded as-of commit unless the target is explicitly marked `pending`, `external`, or `not-yet-committed` with rationale.
- **FR-022**: Packet replay MUST preserve both navigation links and historical retrieval commands so a reviewer can inspect the exact referenced file version even after later commits modify the artifact.

### Acceptance criteria

- **AC-001**: Running a boundary sync without a stored validated packet fails.
- **AC-002**: A packet with bare `specs/...`, `.specrew/...`, `.squad/...`, `README.md`, `tests/...`, or similar artifact references outside code/command exemptions fails validation.
- **AC-003**: A fixture where the primary packet is non-compliant but the legacy handoff block is compliant fails validation.
- **AC-004**: A valid packet with all review targets expressed as `file:///` URLs passes validation and records a packet hash.
- **AC-005**: Boundary state records the active packet ID and hash.
- **AC-006**: The packet replay command displays the stored packet exactly as validated.
- **AC-007**: Feature 139 D-004 and D-005 failure shapes are covered by regression tests.
- **AC-008**: Existing gates can still show a legacy compatibility block during transition, but the primary typed packet is the only authoritative approval object.
- **AC-009**: A packet review target without an as-of commit or `git show <commit>:<path>` retrieval command fails validation.
- **AC-010**: A packet review target whose path does not exist at the recorded as-of commit fails validation unless it carries an explicit pending/external/not-yet-committed classification and rationale.
- **AC-011**: After a referenced artifact is changed by a later commit, packet replay still identifies and retrieves the original reviewed content via the recorded `git show` command.

### Out of scope

- Forking VS Code, Copilot, Claude, Codex, Antigravity, PowerShell, or terminal hosts.
- OS-level read-only flags or ACL enforcement for closed artifacts.
- Replacing human discussion with rigid forms.
- Full release automation beyond packet approval semantics.
- Solving task-progress idempotency or active-feature scoping; that is a related follow-up defect, not this packet architecture.

## Effort

- **Iteration 1 (~6-9 SP)**: Packet artifact layout, shared renderer, common schema, validator, packet hash/state recording, and replay command.
- **Iteration 2 (~4-7 SP)**: Gate-specific templates, migration of existing boundary sync paths, Feature 139 D-004/D-005 regression fixtures, docs, and transitional legacy-block compatibility rules.
- **Total**: ~10-16 SP

## Phase placement

Phase 2, high-priority governance hardening.

This should land near the Feature 139 release-recovery sequence because it turns the current prompt-level boundary-packet discipline into a script-enforced governance object. It composes with Proposal 151 and the in-flight Proposal 154 but goes one layer deeper: 151/154 define what the packet should say; this proposal makes the packet a typed artifact that Specrew renders, validates, stores, and asks the human to approve.

## Open questions

1. Should the packet renderer accept structured JSON from the agent, a PowerShell object, or markdown frontmatter plus body fields?
2. Should the first implementation support all boundary types or start with the high-risk gates: `clarify-to-plan`, `before-implement-to-implement`, `implement-to-review`, and `feature-closeout-to-release-closeout`?
3. Should packet approval require the human to name the packet ID explicitly, or can "approve" apply to the active packet in boundary state?
4. How long should the legacy `=== SPECREW HANDOFF ===` compatibility block remain after typed packets ship?
5. Should packet files be amended on discussion or should every amended packet produce a new file with a new hash?
6. Should review targets always pin to the gate commit, or should the renderer allow per-target commits when artifacts are intentionally generated after the gate commit?

## Risks

- **Host can still add extra prose**: The host may display additional AI text around the packet. Mitigation: only the stored packet ID/hash is authoritative; extra prose is informational.
- **Perceived bureaucracy**: Packet IDs and hashes can feel heavy. Mitigation: keep the six human-friendly sections as the visible body and tuck metadata into frontmatter.
- **Template rigidity**: Gate-specific templates might miss unusual cases. Mitigation: include structured `additional_context` and `discussion_prompts` fields while keeping validation on invariant fields.
- **Transition confusion**: Legacy handoff block and typed packet may coexist briefly. Mitigation: clearly mark typed packet as authoritative and legacy block as compatibility-only.
- **False confidence if agent does not emit verbatim**: The AI may summarize instead of presenting the rendered packet. Mitigation: boundary approval targets the stored packet; future host integrations can improve exact display but are not required for governance correctness.
- **Reference drift after approval**: Linked markdown files can change after the packet is approved. Mitigation: every review target carries the as-of commit and `git show <commit>:<path>` command for exact historical reconstruction.

## Cross-references

- Related proposals: [007](007-substantive-interaction-model.md), [056](056-specrew-readonly-mode.md), [120](120-handoff-block-validator-enforcement.md), [151](151-boundary-handoff-contract-unification.md), Proposal 154 (Boundary Authorization Prompt Truth, in-flight on the Feature 139 release-recovery branch)
- Composability with: Feature 139 D-004/D-005 evidence, release-closeout packet validation, future closed-artifact immutability, and task-progress active-feature scoping.
- Source artifacts: Feature 139 release-recovery dogfooding discussion on 2026-06-01.

## Status history

- 2026-06-01: status set to draft. Captured from Feature 139 release-recovery discussion after repeated visible-packet vs stored-evidence escapes showed that prompt-only enforcement is insufficient.
