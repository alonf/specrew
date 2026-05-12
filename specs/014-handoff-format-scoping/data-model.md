# Data Model: Handoff Format Scoping

**Date**: 2026-05-12
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Entities

### Coordinator Response Type

The selector that classifies the coordinator's top-level human-facing response as either a final stop message or an in-flight progress update.

| Field | Type | Description |
| --- | --- | --- |
| `response_type` | enum (`final-stop-message` / `in-flight-progress-update`) | Governs which presentation format is allowed |
| `human_is_bottleneck` | boolean | `true` only when the next lifecycle step genuinely depends on human action |
| `surface_scope` | enum (`coordinator-top-level`) | Explicitly excludes sub-agent output and tool-rendered result blocks |
| `descriptive-id-context_required` | boolean | `true` for both governed response types |

**Validation rules**:
- `final-stop-message` is valid only when `human_is_bottleneck == true`.
- `in-flight-progress-update` is required when Squad is still working, waiting on background work, or transitioning internally.
- Session-opening acknowledgements follow the same selector and are not exempt.

---

### Final Stop Message

The existing three-section coordinator response used only when a human action is required now.

| Field | Type | Description |
| --- | --- | --- |
| `what_i_just_did` | string | Substantive progress status |
| `why_i_stopped` | string | True reason the human is now the blocker |
| `what_i_need_from_you` | string | Substantive immediate human action |
| `substantive_action_present` | boolean | `true` when the user-action section contains a real request |

**Validation rules**:
- Must preserve the existing three-section format unchanged.
- All three sections must contain substantive content.
- Brevity alone does not make a valid user action non-substantive.

---

### In-Flight Progress Update

The concise coordinator response used when work is still in motion and no human action is needed yet.

| Field | Type | Description |
| --- | --- | --- |
| `progress_note` | string | Single-line prose describing current in-flight status |
| `human_action_required_now` | boolean | Must be `false` |
| `mentions_transition_or_wait` | boolean | Allowed, because the response is explicitly in-flight |

**Validation rules**:
- Must omit the user-action section.
- Remains deliberately unstructured single-line prose.
- Still inherits the readable identifier-context rule when identifiers appear.

---

### Empty User-Action Section Warning

The additive soft warning emitted when a final stop message claims a stop without a substantive user action.

| Field | Type | Description |
| --- | --- | --- |
| `warning_id` | string | `soft-warning.empty-user-action-section` |
| `matched_phrase` | string? | Placeholder phrase that triggered the warning, when applicable |
| `section_empty` | boolean | `true` when the section is blank or effectively blank |
| `response_type_under_review` | enum | Must be `final-stop-message` |

**Validation rules**:
- Fires when `what_i_need_from_you` is empty or matches a repository-maintained placeholder phrase.
- Remains advisory and does not block response delivery.
- Must not fire on a short but substantive approval request.

---

### Transitional Stop Claim Warning

The additive soft warning emitted when a stop claim is really transitional narration.

| Field | Type | Description |
| --- | --- | --- |
| `warning_id` | string | `soft-warning.transitional-stop-claim` |
| `transition_signal` | string | The in-flight / waiting / transition cue that triggered review |
| `substantive_action_present` | boolean | Whether a real human action was also present |
| `response_type_under_review` | enum | Usually a malformed `final-stop-message` |

**Validation rules**:
- Fires when `why_i_stopped` describes waiting, background work, or internal transition instead of a real human blocker.
- Especially relevant when no substantive user action is identified.
- Must not fire on a legitimate human-blocked stop message that also mentions waiting.

---

### Placeholder Phrase List

The fixed repository-maintained list of non-substantive user-action phrases used by the validator and tests.

| Field | Type | Description |
| --- | --- | --- |
| `phrases` | string[] | Repository-owned literal phrases |
| `storage_mode` | enum (`code-and-tests`) | Not configurable by end users in this feature |
| `reviewability` | boolean | Humans must be able to see why a phrase matched |

**Initial list**:
- `Nothing yet`
- `No action needed`
- `No action required`
- `Nothing to do`
- `No further action needed`

---

### Handoff Identifier-Context Rule

The existing readable-reference rule from feature 012, with applicability extended to both governed response types.

| Field | Type | Description |
| --- | --- | --- |
| `rule_id` | string | `human-handoff-id-context` |
| `applies_to` | string[] | `final-stop-message`, `in-flight-progress-update` |
| `excluded_surfaces` | string[] | quoted material, code blocks, raw tool output, Copilot-rendered result blocks |

**Validation rules**:
- Identifier references remain readable on first pass in both response types.
- The rule stays additive and does not replace stop-vs-progress selection logic.

## Relationships

- `Coordinator Response Type` determines whether the response must satisfy `Final Stop Message` rules or `In-Flight Progress Update` rules.
- `Empty User-Action Section Warning` evaluates the `Final Stop Message` entity and uses the `Placeholder Phrase List`.
- `Transitional Stop Claim Warning` evaluates the `Final Stop Message` entity against the selector implied by `Coordinator Response Type`.
- `Handoff Identifier-Context Rule` applies across both governed response types and remains orthogonal to the new warning logic.

## State Transition Notes

- Normal flow is `in-flight-progress-update` → `final-stop-message` only when the human becomes the actual bottleneck for the next lifecycle step.
- Mixed cases resolve to `final-stop-message` only if there is a real immediate human action; otherwise the response remains `in-flight-progress-update`.
