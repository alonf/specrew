# Observability And Resilience Lens

## Lens ID

`observability-resilience`

## Purpose

Ensure the design can explain what happened, detect failure, fail safely, and
recover. This lens ties runtime truth to logs, metrics, traces, health checks,
alerts, and error-handling decisions.

## Applicability Signals

- The feature runs in production, CI, install scripts, background jobs,
  distributed systems, user workflows, or long-lived operations.
- Failures may be partial, intermittent, remote, retried, asynchronous, or hard
  for a user to diagnose.
- The feature makes claims about reliability, availability, performance,
  operability, self-healing, or supportability.

## Design Decision Points

- What must be logged, measured, traced, or reported to understand behavior?
- What correlation/context should flow through logs or events?
- What health checks, readiness checks, or validation commands are needed?
- What errors are expected, and which are exceptional?
- What retry, timeout, idempotency, circuit, compensation, or recovery pattern
  applies?
- What is the cost of observability, and what should not be logged?

## Question Bank

- How will a user or operator know the feature worked?
- How will they know it failed, and what should they do next?
- What telemetry distinguishes user error, dependency failure, configuration
  failure, code bug, and platform outage?
- Which operations are safe to retry?
- What state must be idempotent to avoid duplicates or corruption?
- What is the timeout behavior and user-facing message?
- What SLI/SLO or acceptance signal matters for this feature?
- What evidence should review require before accepting runtime claims?

## Alternative Dimensions

- **Simplest**: clear errors and local logs for the new path.
- **Reasonable**: structured logs, correlation, health/readiness checks, retry
  policy, idempotency notes, and targeted failure tests.
- **By the book**: OpenTelemetry-style traces, metrics, dashboards, alerts,
  SLOs, runbooks, chaos/failure-mode tests, and recovery automation.

## Plan Obligations

- Record failure modes, error handling, retry/idempotency, and telemetry.
- Separate syntax/static checks from runtime proof.
- Define review evidence for each operational claim.

## Validation Signals

- Failure paths are exercised in tests or manual smoke.
- Review can trace a failure from symptom to diagnosis evidence.
- Runtime proof is not replaced with form-only evidence.

## Source Notes

- Book Chapter 6.
- Course Modules 1, 2, and 5.
