# Coordinator Handoff Scoping Contract

**Date**: 2026-05-12
**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)

## Purpose

Define the governed response-type contract for the coordinator's top-level human-facing output after feature 014 narrows the scope of the existing three-section stop-message format.

## Scope

This contract applies only to the coordinator's top-level user-facing response surface.

### In Scope

- Final stop messages
- In-flight progress updates
- Warning identifiers tied to misuse of the stop-message format
- Readable identifier-context expectations for both governed response types

### Out of Scope

- Sub-agent-authored output
- Raw tool output or Copilot-rendered tool-call result blocks
- Redesigning the existing three-section stop-message format
- Positive `soft-info.well-scoped-handoff`
- Reverse symmetric warning for silent real stops rendered as progress updates

## Response-Type Selection Matrix

| Scenario | Required Response Type | Format Rule | User-Action Section |
| --- | --- | --- | --- |
| Human must approve, clarify, review, or otherwise unblock the next lifecycle step | `final-stop-message` | Use the existing three-section stop-message format | Required and substantive |
| Squad is still actively working, waiting on background work, or transitioning internally | `in-flight-progress-update` | Use concise single-line prose | Omit entirely |
| Session-opening acknowledgement with no current human action required | `in-flight-progress-update` | Use concise single-line prose | Omit entirely |
| Mixed transition + true human blocker | `final-stop-message` only if a real immediate human action exists | Three-section stop-message format wins | Required and substantive |

## Final Stop Message Contract

### Required Structure

1. **What I just did**
2. **Why I stopped**
3. **What I need from you**

### Required Semantics

- `What I just did` states substantive progress.
- `Why I stopped` states the real human-blocked reason the coordinator cannot continue safely.
- `What I need from you` states one substantive immediate human action.

### Not Allowed

- Empty user-action sections
- Placeholder user-action phrases
- Transitional or internal waiting narration presented as the stop reason when no human action is actually needed

## In-Flight Progress Update Contract

### Required Structure

- Single-line progress prose only

### Required Semantics

- State what is happening now
- Make clear that Squad is still in motion
- Do not request human action unless the response should instead be a final stop message

### Not Allowed

- Reusing the three-section stop-message format when no human action is required
- Introducing a new structured `Action | Status | Next` format in this feature

## Warning Contract

| Warning ID | Trigger | Must Not Trigger On |
| --- | --- | --- |
| `soft-warning.empty-user-action-section` | A final stop message whose `What I need from you` section is empty or non-substantive | A short but real approval, review, or clarification request |
| `soft-warning.transitional-stop-claim` | A final stop message whose `Why I stopped` section is really in-flight wait/transition narration | A genuine human-blocked stop that also mentions waiting or deferred work |

## Fixed Placeholder Phrase List

The initial repository-maintained placeholder list for `soft-warning.empty-user-action-section` is:

- `Nothing yet`
- `No action needed`
- `No action required`
- `Nothing to do`
- `No further action needed`

This list is owned in code and tests for this feature and is not a user-configurable surface.

## Identifier-Context Applicability

The existing `human-handoff-id-context` rule applies to:

- `final-stop-message`
- `in-flight-progress-update`

Readable identifier-context requirements remain additive and do not replace the response-type selector above.

## Worked Examples

### Correct Final Stop Message

```text
What I just did
Updated the coordinator guidance and validator wording for stop-vs-progress scoping.

Why I stopped
I cannot continue to the next lifecycle step until you confirm the scoped wording is acceptable.

What I need from you
Review and approve the planned wording change before Iteration 002 proof work starts.
```

### Correct In-Flight Progress Update

```text
I updated the planning artifacts and I am still waiting on background research synthesis; no human action is needed yet.
```

### Mis-scoped Transitional Stop Claim

```text
Why I stopped
I am waiting for the validator run to finish and then I will continue.

What I need from you
No action needed.
```

Expected warnings:

- `soft-warning.empty-user-action-section`
- `soft-warning.transitional-stop-claim`
