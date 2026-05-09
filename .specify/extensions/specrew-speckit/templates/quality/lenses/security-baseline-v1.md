# Lens Checklist: security-baseline v1

| Field | Value |
| --- | --- |
| Lens ID | `security-baseline` |
| Version | `v1.0.0` |
| Purpose | Establish the minimum reviewable security baseline for Phase 1 stack-aware quality governance. |
| Default Row Statuses | `pass`, `fail`, `not-applicable`, `advisory` |

## Scope

Use this lens when the active feature exposes security-sensitive paths, handles untrusted input, relies on credentials or tokens, or publishes externally reachable behavior. Keep execution evidence row-level and explicit.

## Row Status Vocabulary

| Status | Meaning |
| --- | --- |
| `pass` | Evidence shows the check was satisfied for the reviewed scope. |
| `fail` | Evidence shows the check was required and is currently unsatisfied. |
| `not-applicable` | The feature does not exercise the risk; record the rationale. |
| `advisory` | The concern is worth tracking but is not a blocking Phase 1 failure. |

## Checklist Items

| Item ID | Concern | Concrete Check | Acceptance Criteria | Row Status | Evidence / Notes |
| --- | --- | --- | --- | --- | --- |
| SEC-001 | Trust boundaries | Identify every untrusted entry point touched by the feature. | All externally sourced inputs, callbacks, messages, and config values are named or linked to a concrete interface boundary. | `pass \| fail \| not-applicable` | |
| SEC-002 | Input handling | Validate or constrain untrusted input before business logic or persistence. | The implementation rejects, sanitizes, or bounds malformed input with an explicit rule per entry point. | `pass \| fail \| not-applicable` | |
| SEC-003 | AuthN/AuthZ | Review authentication and authorization assumptions for changed paths. | Protected behavior has an explicit auth check or documented not-applicable rationale; no privileged path relies on implicit trust. | `pass \| fail \| not-applicable` | |
| SEC-004 | Secret handling | Check credentials, tokens, keys, and connection strings for safe handling. | No secret is hard-coded, echoed into logs, or written to a repo-tracked artifact; runtime sourcing is explicit. | `pass \| fail \| not-applicable` | |
| SEC-005 | Dependency exposure | Review dependency or package changes for new attack surface. | Newly introduced packages, services, or privilege boundaries have a documented reason and no known unsupported risk is silently ignored. | `pass \| fail \| advisory \| not-applicable` | |
| SEC-006 | Sensitive output | Inspect logs, errors, and diagnostics for sensitive leakage. | Errors and telemetry omit secrets, tokens, and unnecessary sensitive payload data while preserving actionable troubleshooting context. | `pass \| fail \| not-applicable` | |

## Upgrade Guidance

When a new recurring security trap is discovered:

1. Add or revise checklist rows in the extension source instead of editing scaffolded downstream copies first.
2. Bump the semantic version when reviewer-approved scope changes materially alter expected execution.
3. Record whether each new row is immediately approved, explicitly deferred, or advisory-only for the current adoption cycle.
4. Update any preset references only after the reviewed lens version is accepted.

## Change Log

| Version | Date | Change | Review Notes |
| --- | --- | --- | --- |
| `v1.0.0` | 2026-05-07 | Initial Phase 1 baseline with trust-boundary, input-handling, auth, secret, dependency, and leakage checks. | Establishes the reviewed minimum security checklist source for FR-022 through FR-026. |
