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

### Problem questions

No problem questions: the problem facts this lens needs come from product-domain, requirements-nfr and the problem sections of the other lenses; this lens chooses the solution.

### Solution questions

- What must be logged, measured, traced, or reported to understand behavior?
- What correlation/context should flow through logs or events?
- What health checks, readiness checks, or validation commands are needed?
- What errors are expected, and which are exceptional?
- What retry, timeout, idempotency, circuit, compensation, or recovery pattern
  applies?
- What is the cost of observability, and what should not be logged?

## Handed Forward From Earlier Lenses

Shown at every depth as recommendation lines, in this lens's one recommendation list. Each line names the earlier
lens that asked it and the answer's key. A product-domain answer comes from the feature's product-domain record
(`areas.<key>`); another lens's answer comes from that lens's workshop record. The line shows it as
"<lens>: <answer>", or "<lens>: not stated" when that is the answer or the lens did not run. The human accepts it
or changes it for this lens.

- product-domain `operators` — recommend "product-domain: <its answer, or not stated>" (already answered in product-domain; not asked again here) → spec.md Problem Context: Who operates it, and when
- product-domain `budget` — recommend "product-domain: <its answer, or not stated>" (already answered in product-domain; not asked again here) → spec.md Problem Context: Budget
- requirements-nfr `slo_alerting` — recommend "requirements-nfr: <its answer, or not stated>" (already answered in requirements-nfr; not asked again here) → spec.md Problem Context: Operating needs
- requirements-nfr `expected_failures` — recommend "requirements-nfr: <its answer, or not stated>" (already answered in requirements-nfr; not asked again here) → spec.md Problem Context: Operating needs
- security-compliance `never_logged` — recommend "security-compliance: <its answer, or not stated>" (already answered in security-compliance; not asked again here) → spec.md Problem Context: Operating needs
- devops-operations `operator_diagnosis` — recommend "devops-operations: <its answer, or not stated>" (already answered in devops-operations; not asked again here) → spec.md Problem Context: Operating needs

## Depth Model

The agenda's depth for this lens decides what it asks.

- **Light**, **Standard** and **Deep** — the questions above are asked as before. The handed-forward lines are
  shown at every depth as **recommendation lines**, once, as one list, closed by the same typed reply as the
  questions. "accept" takes every line as shown; changing a line is part of the same reply.

## Workshop Conduct

- **Diagram for this lens**: request trace / failure-mode flow — render it as **console ASCII inline** so the human sees it in the conversation (a fenced mermaid block is source text, not a picture, on a terminal host); any mermaid/svg/html file is an *additional* artifact whose clickable `file:///` link you surface in the same message.
- **Facilitate, do not dictate**: raise the Design Decision Points above as a discussion, trace a request and a failure mode and agree the signals and the failure handling, capture the human's decisions and explicit agreement, iterate until they say "move on" (and when a reply is NOT that phrase, open your next message with one line naming what you recorded and that the lens stays open until they type "move on" or "skip" - never leave the human to infer it from a repeated question), and record the agreement (never leave it only in the chat scrollback).
- **Re-invoke the `specrew-design-workshop` skill** before moving to the next lens.

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
