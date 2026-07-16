# Observability and resilience reassessment

**Status**: complete
**Iteration**: 005

## Confirmed observability depth

Durable bounded JSON facts are the primary operational record. This local on-demand workflow does not add OpenTelemetry, a metrics store, dashboards, an alerting system, or a separate logging subsystem.

```text
review requested
      |
      v
cheap preflight ------------------------> failed: actionable diagnostic
      |
      v
claim + allowance reservation
      |
      v
reviewer launched
      |
      +---- informational progress ----> initiating CLI / status reader
      |
      +---- completes -----------------> validate -> publish result
      |
      +---- timeout / crash
                |
                +---- terminate and verify process tree dead
                +---- capture bounded partial output
                +---- publish incomplete result with failure reason
                +---- release claim
                +---- schedule permitted rerun
```

## Signal classes

Informational signals improve usability but do not establish review authority:

```text
stage change
elapsed time and remaining deadline
process-tree liveness
output activity since the previous update
optional validated finding count
```

- Stage changes are shown immediately and a low-cost periodic heartbeat is shown while the reviewer runs.
- `output activity observed` is not described as semantic review progress. A harness may work silently, and output activity may not represent a finding.
- A finding count is shown only when an adapter has received a complete schema-valid checkpoint. Beta2 does not parse incomplete JSON or harness-specific console prose while it is being written.
- Reliable structured streaming may be an optional future adapter capability; it is not part of the five-harness Beta2 completion floor.
- Failure of an informational heartbeat does not invalidate an otherwise proven result.

Authority-bearing evidence includes target identity, invocation/spend, process start and terminal outcome, deadline and termination evidence, containment outcome, result validation, and snapshot currentness. Missing authority-bearing evidence prevents the result from approving the snapshot.

Every safe diagnostic is correlated by campaign ID, run ID, target digest, harness and observed version, lifecycle stage, UTC timestamp, controller-observed duration, outcome category, and bounded actionable detail.

## Timeout result publication

Timeout is an explicit result, not an absent-file convention:

```text
deadline reached
      |
      v
terminate reviewer process tree
      |
      v
verify process tree is dead
      |
      v
close streams + capture bounded partial candidate
      |
      v
validate usable partial findings
      |
      v
publish controller-generated result.json + report.md
```

The terminal result uses `completion: partial`, `verdict: incomplete`, `runtime_outcome: timed-out`, observed deadline and elapsed duration, `termination_verified`, a clear summary, and any valid recovered partial findings. Publication occurs only after termination is verified so late reviewer output cannot race the controller result. The separate immutable terminal lifecycle fact retains the process-control evidence.

Every invoked run likewise publishes one terminal authoritative result for other post-invocation outcomes. A preflight failure before invocation remains a non-spent run outcome and is not misrepresented as a completed review.

## Status, health, and failure behavior

- The initiating CLI displays concise progress and the final outcome; status reconstructs campaign/run state from durable facts after restart.
- Preflight reports installed, configured, and contract-compatible separately from authenticated-and-live. It does not claim live authentication without a real probe.
- Expected failure categories include unavailable harness, authentication failure, launch failure, timeout, invalid result, identity mismatch, containment violation, and moved snapshot. Each supplies a stable category and actionable next step.
- Conflicting immutable facts or contradictory identities are exceptional repository corruption and fail closed with the relevant run and conflict identified.
- There are no hidden retries. Recovery and reruns use visible run identities and authorized allowance.
- Production timings record controller-observed UTC start/end plus monotonic duration and system-observed provenance. Test-injected clocks cannot masquerade as runtime evidence.
- Credentials, raw environments, full prompts, and unrestricted raw model output are not logged. Bounded results, safe diagnostics, identity, timing, lifecycle, and containment evidence persist.

## Retrospective evidence

Validated complete and partial findings are structured evidence sources for retrospective problem descriptions:

```text
validated findings
       |
       v
deduplicate by finding lineage
       |
       v
classify: fixed / unresolved / snapshot-moved / partial
       |
       v
retro problem descriptions
  + campaign / run / finding identity
  + harness and reviewed target
  + completeness and relevance provenance
```

The retrospective consumes authoritative JSON rather than parsing Markdown. Partial findings may describe problems, but their provenance remains visible and they cannot be presented as evidence that a review completed.

## Acceptance evidence

- Timeout testing proves the complete process tree is dead within a small measured tolerance before result publication.
- Restart testing proves status reconstruction and incomplete-sequence reconciliation.
- Runs with findings are distinguishable from operationally failed runs.
- Invalid or contradictory facts fail closed and identify the conflicting run evidence.
- Diagnostics are checked for credential and raw-environment leakage.
- Each of the five real-harness smokes supplies runtime evidence; fixtures alone do not establish real harness health.
- Finding lineage and provenance are traceable into retrospective problem descriptions.

## Human agreement

The maintainer confirmed harness-neutral stage, elapsed-time, liveness, and output-activity progress; semantic counts only from validated checkpoints; durable facts rather than a telemetry subsystem; the separation of informational signals from authority-bearing evidence; explicit post-kill timeout result publication; actionable health/failure reporting; directly observed timing provenance; and complete/partial findings as provenance-preserving retrospective evidence before this lens was closed.
