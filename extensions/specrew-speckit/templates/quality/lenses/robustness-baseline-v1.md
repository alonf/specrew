# Lens Checklist: robustness-baseline v1

| Field | Value |
| --- | --- |
| Lens ID | `robustness-baseline` |
| Version | `v1.0.0` |
| Purpose | Capture the Phase 1 resilience and failure-semantics checks that prevent silent operational gaps. |
| Default Row Statuses | `pass`, `fail`, `not-applicable`, `advisory` |

## Scope

Use this lens when the feature introduces service boundaries, retries, background execution, concurrency, long-lived resources, or failure-handling logic. Record explicit not-applicable rationale when resiliency-oriented checks do not materially apply.

## Row Status Vocabulary

| Status | Meaning |
| --- | --- |
| `pass` | Evidence shows the reviewed path handles the concern as required. |
| `fail` | The concern applies and the implementation leaves the risk unresolved. |
| `not-applicable` | The feature shape does not materially require this check; rationale must be recorded. |
| `advisory` | The issue is visible for follow-up but not a blocking Phase 1 requirement. |

## Checklist Items

| Item ID | Concern | Concrete Check | Acceptance Criteria | Row Status | Evidence / Notes |
| --- | --- | --- | --- | --- | --- |
| ROB-001 | Failure semantics | Trace the primary failure paths for changed operations. | Each meaningful failure mode returns or records an intentional outcome rather than a silent swallow, crash loop, or ambiguous partial success. | `pass \| fail \| not-applicable` | |
| ROB-002 | Retry and idempotency | Review retries, replays, or repeated requests where side effects can occur. | Retried work is explicitly idempotent or guarded against duplicate side effects; missing retry safety is recorded as a failure or not applicable. | `pass \| fail \| not-applicable` | |
| ROB-003 | Timeouts and backoff | Inspect blocking or remote-call behavior. | Remote or long-running operations use bounded waits, timeout handling, or a documented reason the path is synchronous and safe. | `pass \| fail \| advisory \| not-applicable` | |
| ROB-004 | Resource lifecycle | Check allocation and cleanup for files, sockets, connections, and subscriptions. | Acquired resources are deterministically released or lifecycle ownership is explicit and reviewable. | `pass \| fail \| not-applicable` | |
| ROB-005 | Concurrency correctness | Review materially concurrent paths for race or ordering hazards. | Shared-state mutation, event sequencing, and async coordination have an explicit guard, serialization strategy, or documented non-applicability. | `pass \| fail \| not-applicable` | |
| ROB-006 | Degraded operation | Verify behavior when downstream tools or services are unavailable. | The feature exposes a clear degraded mode, surfaced failure, or compensating evidence path instead of silently pretending success. | `pass \| fail \| advisory \| not-applicable` | |

## Upgrade Guidance

When new robustness traps are learned from review or production evidence:

1. Propose the new or changed rows in this source file and describe the triggering defect pattern in the change log.
2. Review each proposed row for whether it should become blocking, remain advisory, or be deferred.
3. Bump the lens version only after the reviewed checklist delta is approved.
4. Update preset references separately so stack-specific adoption stays explicit and independently versioned.

## Change Log

| Version | Date | Change | Review Notes |
| --- | --- | --- | --- |
| `v1.0.0` | 2026-05-07 | Initial Phase 1 baseline covering failure semantics, retry safety, timeouts, cleanup, concurrency, and degraded-mode handling. | Establishes the reviewed operational baseline without implying later-phase hardening workflows. |
