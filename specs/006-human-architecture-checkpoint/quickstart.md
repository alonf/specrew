# Quickstart: Human Architecture Intent Checkpoint

**Feature**: 006-human-architecture-checkpoint  
**Audience**: Feature developers, spec stewards, team architects  
**Purpose**: Practical guide to invoking the checkpoint, approving architecture direction, and recording decisions

---

## Quick Overview

The architecture intent checkpoint is an **automatic pre-step** in the `/speckit.plan` command. When you run `/speckit.plan` to generate an implementation plan:

1. Squad generates a brief describing the proposed architecture
2. The brief is presented to you in chat
3. You review, ask questions, and approve (or reject)
4. Your decision is recorded in plan.md
5. Plan generation continues (or returns to spec clarification if you reject the direction)

**No separate command needed**. Just run `/speckit.plan` as usual.

---

## Workflow: Step by Step

### Step 0: Prepare (Prerequisites)

- ✓ Spec is clarified (completed `/speckit.clarify` or equivalent)
- ✓ You are available to review the architecture brief (10–30 minutes)
- ✓ You understand the feature's technical scope

### Step 1: Invoke Planning

```bash
/speckit.plan
```

**What happens**:
- Speckit loads your spec.md
- Checkpoint is automatically invoked
- Squad generates an architecture intent brief

**Expected output** (in Copilot chat):

```
🏗️ Architecture Intent Checkpoint — Feature 006-human-architecture-checkpoint

Generating architecture intent brief based on your spec...

# Architecture Intent Brief: [FEATURE]

## Design Approach

[Squad's proposed 1–2 paragraph summary of the architecture]

## Affected Surfaces

- [Surface 1]: [justification]
- [Surface 2]: [justification]

...

## Open Questions

1. **Should we use approach A or approach B?**
   - Option A: [advantages/disadvantages]
   - Option B: [advantages/disadvantages]
   - Recommendation: [Squad's recommendation]

...

---

✅ **Next**: Review this brief and provide your approval or constraints.

**You can**:
- ✅ Approve: "This looks good, proceed"
- ✅ Approve with constraints: "Approved, but add constraint: [constraint]"
- ✅ Reject direction: "I don't like this approach; try [alternative]"
- ✅ Ask clarifying questions: "What happens if we do X instead?"
- ✅ Defer: "I need time to discuss; let's revisit [date]"
```

### Step 2: Review the Brief

Read through the brief carefully:

- **Design Approach**: Is the high-level direction sound?
- **Affected Surfaces**: Will the right modules be touched?
- **Expected Changes**: Do the data model, API, and workflow changes make sense?
- **Dependencies**: Are the new libraries/frameworks acceptable?
- **Implications**: Security, performance, reliability — are they addressed?
- **Open Questions**: Do you agree with Squad's recommendations?

### Step 3: Provide Feedback

Choose one of the following actions:

#### Action A: Approve (No Constraints)

If you agree with the proposed direction, say:

```
Approved. Proceed with planning.
```

Or more naturally:

```
This looks good. Let's go with this approach.
```

**Result**: Your approval is recorded in plan.md § Architecture Intent Review. Planning continues.

---

#### Action B: Approve with Constraints

If you approve the overall direction but need to add constraints:

```
Approved. But add these constraints:
- Do not use ORM for the data layer; use raw SQL instead
- All API endpoints must be rate-limited
- Security: Authentication must use OAuth2 (not custom tokens)
```

**Result**: Your approval and constraints are recorded in plan.md. Planning continues. Task generation will incorporate these constraints.

---

#### Action C: Ask Clarifying Questions

If you need more information before deciding:

```
I like the overall direction, but have a few questions:

1. What's the performance impact of approach A vs. B for the [metric]?
2. How does this interact with existing [component]?
3. Can we defer [decision] to Phase 2?
```

**Result**: Squad clarifies or revises the brief based on your questions. You can then approve, approve with constraints, or reject.

---

#### Action D: Reject and Request Reconsideration

If you disagree with the proposed direction:

```
I don't like this approach. It's too coupled to [component].

Can you reconsider:
- Alternative: Decouple via event bus (mentioned in the brief)
- Constraint: Must maintain current API contract
- Assumption to reconsider: [assumption from brief that you challenge]
```

**Result**: Squad generates a new brief with the revised direction. You review and decide again.

**Note**: Planning does not proceed until you approve a direction.

---

#### Action E: Defer Decision

If you cannot decide immediately:

```
I need to discuss this with the team.
Can we revisit tomorrow at [time]?
```

**Result**: Planning pauses. Checkpoint waits for your decision. (Refer to your team's escalation policy if you need to delegate the decision.)

---

### Step 4: Decision is Recorded

Once you approve (with or without constraints), Copilot records your decision in plan.md:

**Example output in plan.md**:

```markdown
## Architecture Intent Review

*Approved: 2026-05-09 by [Your Name] (Spec Steward, architect-level authority)*
*Brief generated by: Squad Copilot at 2026-05-09T14:30:00Z*

### Accepted Implementation Direction

The feature will integrate the checkpoint as a before_plan hook in the existing Speckit
extension mechanism. The checkpoint generates a brief, surfaces it to the human, and
blocks task generation until approval is recorded.

### Rejected Alternatives

- **Separate /speckit.architecture-intent command**: Rejected because it requires two
  separate invocations and is less integrated with existing workflow.

### Human Constraints and Forbidden Paths

- Must integrate with existing before_plan hook; do not break existing workflows
- Decision records must be stored in plan.md (Phase 1)
- Approval must block task generation; no auto-proceeding without human decision

### Key Decisions

| Decision Point | Decision | Rationale |
| --- | --- | --- |
| Brief format | Markdown, chat-based | Human-friendly; easy to review and discuss |
| Storage location | plan.md § Architecture Intent Review | Single source of truth; auditable; visible to all agents |
| Ledger integration | Deferred to Phase 2 | Simpler Phase 1; defer if demand exists |

### Unresolved Questions

- Should the brief be stored as a separate artifact? (Deferred to Phase 2)

### Traceability

- Brief generated by: Squad Copilot
- Brief generation timestamp: 2026-05-09T14:30:00Z
- Approval recorded by: [Your Name]
- Approval timestamp: 2026-05-09T15:00:00Z
- Approval authority: architect
- Decision status: active
```

### Step 5: Planning Continues

After your approval is recorded, `/speckit.plan` continues:

1. **Plan body generation**: Squad generates the plan body including Architecture Intent Review section
2. **Plan finalization**: plan.md is written with your approved direction and constraints visible
3. **Task Generation** (subsequent step, after plan.md exists): `/speckit.tasks` generates task.md, incorporating your constraints

---

## Key Decisions and Constraints

### When is Checkpoint Approval Required?

**Checkpoint runs for**:
- ✅ Non-trivial features (architectural choices exist)
- ✅ Features affecting public APIs, data models, persistence, dependencies, or security
- ✅ Any feature with meaningful trade-offs or alternatives

**Checkpoint may be skipped for**:
- ✓ Small bug fixes (no architectural choices)
- ✓ Routine refactors (following existing patterns)
- ✓ Features where the spec already gives clear direction (checkpoint notes this and confirms)

### What Counts as a Constraint?

**Valid constraints** (specific, testable):
- ✅ "Use PostgreSQL for persistence" (specific, verifiable)
- ✅ "Do not use ORM; use raw SQL" (clear forbidden path)
- ✅ "API endpoints must be rate-limited" (verifiable in tasks/code)
- ✅ "Authentication must support OAuth2 and SAML" (concrete requirement)

**Vague constraints** (rejected):
- ❌ "Keep it simple" (not testable)
- ❌ "Make it fast" (not measurable without units)
- ❌ "Use best practices" (not specific)

---

## Decision Scenarios

### Scenario 1: You Approve the Brief as-Is

**Brief proposes**: Integrate checkpoint as a hook in existing before_plan mechanism.

**Your response**: "This looks good."

**Result**: Approval recorded. Planning continues immediately.

**Time**: ~5–10 minutes.

---

### Scenario 2: You Approve with Architecture Constraints

**Brief proposes**: Use REST API for the new endpoint.

**Your response**: 
```
Approved with constraint: Must support gRPC as an alternative endpoint
(for internal services). REST is the primary, but gRPC layer must be designed upfront.
```

**Result**: Constraint recorded. Task generation will design both REST and gRPC endpoints.

**Time**: ~15–20 minutes (including clarification questions).

---

### Scenario 3: You Challenge an Assumption

**Brief assumes**: "User input is always well-formed; validation happens upstream."

**Your response**:
```
I disagree with the assumption that input is always well-formed.
In practice, we've seen malformed input reach this layer.

Can you reconsider the approach to include defensive validation?
```

**Result**: Squad regenerates the brief with defensive validation included.

**Time**: ~30 minutes (includes regeneration and re-review).

---

### Scenario 4: Human Is Unavailable

**Situation**: You're the Spec Steward, but you're unavailable for 2 days.

**What happens**: Checkpoint displays a message:

```
⏸️ Waiting for approval from [Your Name] (Spec Steward).

To escalate, contact your team's architect lead or refer to your
team's escalation policy: [link to policy].

Planning is paused until someone approves the proposed direction.
```

**Team's options**:
1. Wait for you to return (if you'll return soon)
2. Escalate to backup architect (per team policy)
3. Revisit the spec (if the brief is rejected)

**No auto-proceed** — approval is mandatory.

---

## Troubleshooting

### Problem: "Spec is too vague to generate meaningful brief"

**Checkpoint output**:
```
❌ Checkpoint failed: Spec is insufficient to generate a meaningful brief.

Please clarify:
  - What is the scope of [unclear section]?
  - Which modules will be affected?
  - What are the key design trade-offs?

Returning to spec clarification.
```

**Solution**: Run `/speckit.clarify` to fill in the gaps. Then retry `/speckit.plan`.

---

### Problem: "Brief proposes something I strongly disagree with"

**Your response**:
```
I don't agree with this approach. It couples us to [component] too tightly.

Please regenerate with the constraint: Must remain loosely coupled to [component].
Consider: event-driven architecture or [other pattern].
```

**What happens**: Squad regenerates the brief with your constraint. You review again.

---

### Problem: "I have questions, but not enough info to decide"

**Your response**:
```
Before I approve, I need to understand:

1. How does this handle [edge case]?
2. What's the rollback strategy if [scenario] happens?
3. Can we defer [decision] to the implementation phase?
```

**What happens**: Squad clarifies. You get more detail. Then you approve or ask more questions.

---

## Best Practices

### For Spec Stewards and Architects

1. **Be present**: The checkpoint runs immediately after you invoke `/speckit.plan`. Budget 15–30 minutes to review and decide.

2. **Ask clarifying questions**: Don't just approve or reject. Understand the trade-offs. Ask "What if...?" questions.

3. **Record constraints explicitly**: If you have preferences (e.g., prefer PostgreSQL, must support offline-first), add them as constraints. Don't rely on memory.

4. **Reference the brief in your decisions**: When you approve or add constraints, reference the specific parts of the brief you're responding to. This makes decisions traceable.

5. **Escalate conflicts early**: If the proposed direction conflicts with other ongoing work, escalate immediately so Squad can adjust. Don't discover the conflict during implementation.

### For Squad Agents

1. **Listen to constraints**: Read the Architecture Intent Review section of plan.md carefully. Incorporate all constraints into task design.

2. **Flag conflicts early**: If a task you're designing violates a recorded constraint, pause and escalate to the human with options.

3. **Keep the brief visible**: When generating tasks or implementation code, reference the approved direction. Link tasks back to the architecture intent.

---

## Reference: Architecture Intent Review Section

After you approve, your decision appears in plan.md like this:

```markdown
## Architecture Intent Review

*Approved: [DATE] by [YOUR NAME] ([YOUR ROLE])*
*Brief generated by: Squad Copilot at [TIMESTAMP] within `/speckit.plan`*

### Accepted Implementation Direction
[Your approved direction, directly quoting or paraphrasing your decision]

### Rejected Alternatives
[Alternatives from the brief that you rejected]

### Human Constraints and Forbidden Paths
- [Constraint 1]
- [Constraint 2]

### Key Decisions
[Table of decisions and rationale]

### Unresolved Questions
[Questions deferred to later phases]

### Traceability
[Metadata linking brief to approval]
```

This section remains in plan.md for the lifetime of the feature, serving as the record of what architecture was approved and what constraints must be honored.

---

## Next Steps

1. **Review**: Read the architecture brief carefully
2. **Decide**: Approve, approve with constraints, ask questions, or defer
3. **Plan Continues**: Once you decide, task generation proceeds or returns to clarification
4. **Implement**: Implementation agents read your approved direction in plan.md and honor your constraints
5. **Review**: During code review, reference the Architecture Intent Review to verify alignment

---

## Questions?

- **"Can I change my mind?"**: Yes, if you discover new information, you can request a new architectural decision. Return to the human with options.
- **"What if the brief is wrong?"**: Ask clarifying questions or request Squad to reconsider. The checkpoint waits for your decision.
- **"What if I'm not sure?"**: Ask clarifying questions. Checkpoint doesn't block on questions; it only blocks on unapproved directions.

---

## Related Artifacts

- **spec.md**: Feature specification (your input to the checkpoint)
- **plan.md**: Implementation plan (includes Architecture Intent Review with your decision)
- **research.md**: Technical decisions and unknowns resolved during planning
- **data-model.md**: Entities and data structures affected by the feature
- **contracts/**: Public interfaces and API contracts
