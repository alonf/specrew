# Contract: Architecture Intent Checkpoint Hook API

**Contract Version**: 1.0.0  
**Effective**: Phase 1 (implementation)  
**Endpoint**: Speckit `before_plan` hook  
**Parties**: Spec Kit layer (hook framework) ↔ Squad layer (brief generation) ↔ Human (checkpoint approver)

## Overview

This contract defines the interface and behavior of the architecture intent checkpoint hook. The checkpoint is invoked as a blocking pre-step within the `/speckit.plan` command, after spec loading and before plan body generation.

## Hook Invocation

### Trigger

- **When**: Inside `/speckit.plan`, after spec loading and before plan body generation
- **Condition**: The spec.md file is marked as "clarified" or complete; no outstanding clarification actions remain
- **Blocking**: Yes. If checkpoint approval is not recorded, plan body generation and plan.md finalization do not proceed
- **EXPLICIT SEQUENCING**: spec.md (complete) → `/speckit.plan` invoked → checkpoint generates brief → human reviews/decides → approval recorded in planning context → plan body generated including Architecture Intent Review section → plan.md finalized

### Input Signature

```powershell
function Invoke-ArchitectureIntentCheckpoint {
    param(
        [string]$FeatureId,           # e.g., "006-human-architecture-checkpoint"
        [string]$SpecPath,             # Path to spec.md
        [string]$CurrentBranch,        # Git branch name
        [hashtable]$SpecContent,       # Parsed spec.md as object
        [string]$RepositoryRoot        # Root of the repository
    )
}
```

### Output Signature

```powershell
@{
    CheckpointPassed = $true | $false            # Did the checkpoint complete successfully?
    BriefGenerated = $true | $false              # Was a brief generated and presented?
    ApprovalRecorded = $true | $false            # Was human approval recorded?
    DecisionMetadata = @{                        # Structured decision record
        FeatureId = $FeatureId
        RecordedAt = [datetime]
        RecordedBy = [string]                    # Human name
        AcceptedDirection = [string]
        HumanConstraints = @([string])           # List of constraints
        ApprovalAuthority = "architect" | "tech-lead" | "product-owner" | "team-consensus"
    }
    ErrorMessage = [string] | $null              # If CheckpointPassed = $false
    EscalationMessage = [string] | $null         # If human unavailable or decision deferred
}
```

## Brief Generation Contract

### Brief Input (to Squad agent)

The Squad agent receives:

```yaml
feature_id: string                    # e.g., "006-human-architecture-checkpoint"
spec_content: object                  # Complete parsed spec.md
current_branch: string                # Git branch name
repository_root: string               # Root of repository
additional_context:
  recent_commits: list[string]        # Recent commit messages (for context)
  file_structure: object              # High-level directory structure
  technology_stack: object            # Language, frameworks, dependencies detected
  existing_patterns: list[string]     # Common patterns found in codebase
```

### Brief Output (from Squad agent)

The Squad agent generates a structured brief (see data-model.md § Entity 1: Architecture Intent Brief) containing:

1. **Design Approach** (1–2 paragraphs): High-level summary of the proposed direction
2. **Affected Surfaces** (list): Modules, files, boundaries that will change
3. **Expected Changes** (structured): Data model, API, workflow, storage changes
4. **Dependency Choices** (list): New frameworks, libraries, versions
5. **Implications** (object): Security, performance, migration, reliability implications
6. **Assumptions** (list): Known assumptions about spec, codebase, architecture
7. **Alternatives Considered** (list): Alternative approaches and trade-off analysis
8. **Open Questions** (list): Decisions requiring human preference or authority

**Format**: Markdown with embedded YAML frontmatter for structured fields

**Validation**:
- Must be substantive (not a placeholder or template)
- All required sections present
- Alternatives required only when they materially differ in cost, risk, or reversibility; routine convention-following features may omit alternatives
- All questions have explicit options and Squad's recommendation

## Human Approval Contract

### Human Interaction Flow

1. **Checkpoint presents brief** to human in chat/CLI interface
2. **Human reviews** the brief and can:
   - **Ask clarifying questions**: "What is the impact of choice X?"
   - **Request modifications**: "Can you reconsider approach Y?"
   - **Approve (clean)**: "OK, I approve this direction" (counts as success)
   - **Approve with constraints**: "Approved, but add constraint: do not use ORM" (counts as success)
   - **Reject**: "I disagree with this approach; try Z instead" (requires revision)
   - **Defer**: "I need more time; let's revisit tomorrow" (requires follow-up)

3. **Decision Recording**: Once human provides approval (clean or with constraints), checkpoint records decision in planning context BEFORE plan body generation proceeds

### Human Input Formats Supported

- **Clean approval** (natural language): "This looks good, proceed" → checkpoint success, no constraints added
- **Approval with constraints** (natural language): "Approved, but we must use PostgreSQL" → checkpoint success, constraints recorded
- **Rejection** (natural language): "I don't like the ORM approach; use raw SQL instead" → checkpoint must regenerate or revise
- **Clarifying questions** (natural language): "How will this affect performance?" → checkpoint continues interaction
- **Deferral** (natural language): "I need to discuss this with the team; revisit tomorrow" → checkpoint pauses, planning does not finalize

### Timeout and Escalation

- **Timeout**: If human does not respond within [TBD, configurable] time, checkpoint displays escalation message and links to team's escalation policy
- **Escalation policy**: Team defines who to contact if primary Spec Steward is unavailable (e.g., backup architect, tech lead)
- **No auto-proceed**: Checkpoint does not auto-approve or proceed without explicit human decision

## Decision Recording Contract

### Recording Location and Format

Decisions are recorded DURING planning, before plan body is generated. The finalized `plan.md` MUST include the **Architecture Intent Review** section:

```markdown
## Architecture Intent Review

*Approved: 2026-05-09 by Alon Fliess (Spec Steward, architect-level authority)*
*Brief generated by: Squad Copilot at 2026-05-09T14:30:00Z*

### Accepted Implementation Direction

[Concise statement of approved approach, directly referencing the brief]

### Rejected Alternatives

[List of alternatives from the brief that were rejected and why]

### Human Constraints and Forbidden Paths

- [Explicit constraint 1: e.g., "do not use ORM for this data model"]
- [Explicit constraint 2]
- [Explicit constraint N]

### Key Decisions

| Decision Point | Decision | Rationale |
| --- | --- | --- |
| [e.g., persistence model] | [chosen approach] | [human or brief rationale] |

### Unresolved Questions

- [Question 1, deferred until: [date or phase]]
- [Question 2, deferred until: [date or phase]]

### Traceability

- Brief generated by: Squad Copilot
- Brief generation timestamp: 2026-05-09T14:30:00Z
- Approval recorded by: Alon Fliess
- Approval timestamp: 2026-05-09T15:00:00Z
- Approval authority: architect
- Decision status: active
```

### Validation of Recorded Decision

Before task generation proceeds, the checkpoint validates:

1. ✓ Architecture Intent Review section is present in plan.md
2. ✓ Approved direction is a non-empty, substantive statement (not "TBD" or placeholder)
3. ✓ Constraints are specific and testable (not vague like "make it good")
4. ✓ Human approval signature (name, timestamp, authority level) is recorded
5. ✓ Brief reference is present (timestamp, generator)

If any validation fails, the checkpoint blocks task generation and returns an error.

## Enforcement Contract

### During Task Generation

Task generators (e.g., `/speckit.tasks` command) MUST:

1. Read the Architecture Intent Review section of plan.md
2. Incorporate constraints into task design and acceptance criteria
3. Ensure no task proposes a choice that conflicts with recorded constraints
4. Reference the approved direction in task descriptions so reviewers understand the architectural context

### During Implementation

Implementation agents and reviewers MUST:

1. Check the Architecture Intent Review section before making implementation decisions
2. If a proposed choice conflicts with a recorded constraint or direction, escalate to the human with:
   - Explanation of the conflict
   - Proposed alternatives (proceed as planned, revise direction, or defer)
   - Explicit request for human decision
3. Do not silently diverge from the approved direction

### Drift Detection

If any of the following conditions are true, a drift signal is triggered:

1. Plan.md lacks an Architecture Intent Review section → Checkpoint was bypassed
2. Tasks are created before Approval Status records `checkpoint_approved: true` → Checkpoint was bypassed
3. Implementation proposal conflicts with recorded constraint → Constraint was not enforced
4. Task descriptions do not reference the approved direction → Brief context was lost

Drift signals require explicit escalation to the human for resolution.

## Error Handling

### Scenario: Spec is too vague to generate meaningful brief

**Behavior**: Checkpoint returns error: "Spec is insufficient to generate a meaningful architecture brief. Please return to spec clarification to clarify [specific gaps]."

**Action**: Planning does not proceed; user is directed back to `/speckit.clarify`.

### Scenario: Squad cannot propose a direction given the spec

**Behavior**: Checkpoint returns error with explanation: "Cannot generate a meaningful brief because [reason: e.g., 'no architectural choices needed; follows existing patterns']. Proceeding with standard planning approach."

**Action**: If this is acceptable (e.g., small bug fix, routine refactor), plan generation proceeds without architectural decision gate. This is not a failure; it is a valid outcome.

### Scenario: Human is unavailable to approve

**Behavior**: Checkpoint displays message: "Waiting for human approval from [Spec Steward]. To escalate, contact [escalation path per team policy]."

**Action**: Planning stalls; no auto-proceed. Team resolves via escalation policy.

### Scenario: Human rejects the proposed direction

**Behavior**: Checkpoint records rejection and returns control to the human with: "Proposed direction rejected. Please provide alternative direction or ask Squad to reconsider. Options: [alternatives presented in brief]."

**Action**: Human either selects an alternative or requests Squad to generate a new brief with different assumptions. Planning does not advance until human approves a direction.

## Success Criteria (Contract Compliance)

A checkpoint implementation complies with this contract if:

1. ✓ Checkpoint is invoked as a blocking pre-step within `/speckit.plan` after spec loading and before plan body generation
2. ✓ Brief is generated by Squad and presented to human in chat/CLI
3. ✓ Human can approve, reject, constrain, or defer; all options are honored
4. ✓ Decision is recorded in plan.md § Architecture Intent Review
5. ✓ Task generation is blocked until approval is recorded
6. ✓ Constraints are visible to task generators and implementation agents
7. ✓ Drift is detected if checkpoint is bypassed or constraints are violated
8. ✓ Escalation paths are defined and followed when human is unavailable

## References

- **Data Model**: `data-model.md` (Architecture Intent Brief, Decision Record, Approval Status)
- **Specification**: `spec.md` § Functional Requirements FR-001 through FR-006
- **Constitution**: `constitution.md` § Principles VIII (Reconciliation), XIII (Spec Stewardship), XV (Human Oversight)
