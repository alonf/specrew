# Observability-Resilience Lens Workshop

## Lens

- **Lens ID**: `observability-resilience`
- **Depth**: medium
- **Confirmation**: human-confirmed
- **Confirmation scope**: lens-question

## Request / Failure-Mode Flow

```text
Checkpoint trigger
  |
  v
Diff classifier
  |-- no reviewable diff --> ReviewRunSkipped
  |                         GateVerdict: pass/no-op
  |
  v
ReviewRequest
  - run_id
  - checkpoint_id / baseline_ref
  - request_hash
  - schema_version
  - review_kind
  - allowed context refs
  - requested provider/model policy
  |
  v
SpawnInvocation attempt(s)
  - invocation_id
  - adapter_id
  - requested/actual host+model
  - argv/working-dir summary
  - timeout
  - normalized exit/failure status
  |
  |-- availability failure --> bounded authorized fallback, max one fallback attempt
  |                            no silent downgrade; actual host/model recorded
  |
  v
FindingsResult OR InfrastructureFailure
  |
  v
ReviewThread + GateVerdict
  - unresolved blocking count
  - dispositions/fix evidence refs
  - escalation ref after capped rounds
  - cleanup status
```

## Agenda Raised

- What should be logged or recorded so a maintainer can reconstruct a review run?
- What correlation identifiers must flow through request, findings, thread, and gate artifacts?
- What validation or health/readiness checks prove the path is usable locally?
- Which failures are expected operational outcomes versus exceptional code defects?
- What timeout, retry, idempotency, replay, cleanup, and recovery policy applies?
- What must not be logged or persisted because of cost, noise, or secret exposure?

## Decisions and Agreement

Operational evidence is split into three related artifacts rather than one giant combined record. `ReviewRequest` is the canonical reviewer input contract and contains the diff reference or content, design-context references, review kind, schema version, allowed paths, requested output schema, provider/model request, and correlation/run id. `SpawnInvocation` records local adapter execution details such as adapter id, command/argv shape, timeout, working directory or temp workspace, stdout/stderr capture policy, exit code, and normalized failure category. `ReviewRun` is the durable audit index tying the attempt together: run id, checkpoint baseline, request hash/reference, invocation summary, requested and actual host/model, findings/result references, review-thread reference, gate-verdict reference, timestamps, and cleanup status. Raw prompts, raw provider transcripts, and secrets are not stored in durable evidence by default.

`run_id` is the primary correlation key across the request, invocation, findings result, review thread, and gate verdict. Required supporting identifiers include checkpoint id, baseline ref, request hash, schema version, review kind, adapter id, requested host/model, actual host/model, per-finding ids, thread id, gate verdict id, unresolved blocking count, and escalation reference when the capped review/fix loop cannot converge. Finding ids are stable within a run; cross-run deduplication or resolution uses normalized fingerprint fields rather than blindly reusing the same finding id.

Iteration 001 requires schema and fixture validation, local provider capability checks, and a controlled fake or fixture adapter path that can exercise the ReviewRequest, FindingsResult, InfrastructureFailure, ReviewThread, and GateVerdict contracts end to end. A real AI-host smoke test is allowed only when explicitly configured and authorized; it is not mandatory for every environment because provider/model availability and paid/external authorization can legitimately differ.

The failure taxonomy separates normal operational outcomes from implementation defects. No reviewable diff is an explicit `ReviewRunSkipped` outcome with a pass/no-op gate verdict, not an infrastructure failure and not a silent skip. Missing host command, unavailable requested model, provider/model not authorized, transient provider outage, timeout, nonzero adapter exit, empty stdout, invalid JSON, schema mismatch, malformed durable review-thread state, and unresolved blocking finding after capped rounds are expected operational outcomes with structured evidence and unsafe/blocking gate behavior as appropriate. Internal invariant breaks such as invalid run-id creation, unsafe workspace path normalization, self-contradictory gate counts, known-good fixture writer errors, cleanup outside the owned workspace, or unsafe command construction are code defects and should fail implementation validation rather than be normalized into ordinary reviewer outcomes.

Availability issues are handled through bounded explicit retry/fallback rather than ignored. Reviewer invocation may use an ordered provider/host/model priority list from explicit non-secret configuration. Each candidate must be allowed and authorized before use. Iteration 001 permits at most one fallback attempt after the primary candidate when the failure category is availability-related. There is no silent downgrade: same-host fallback, weaker model fallback, paid/non-default use, or loss of cross-host independence must be authorized by policy or human decision and recorded through requested and actual host/model metadata. If the bounded policy is exhausted, the result is an InfrastructureFailure and unsafe/blocking gate state.

Replay is explicit and creates a new run id and new provenance. Previous runs remain immutable evidence. Multiple attempts for the same checkpoint may be linked through checkpoint id and request hash. Request bundles are immutable per run and must not be reused. Writes are idempotent by run id and should fail on accidental overwrite. Temporary workspace cleanup is best-effort and recorded after durable outcome persistence; cleanup failure must not hide a valid finding or convert a blocked run into a pass.

Durable artifacts store structured, redacted, schema-owned evidence. They must not deliberately persist environment variables, credentials, tokens, provider auth files, local secret stores, raw provider transcripts, raw prompt text by default, unrelated repository files outside selected review context, unrelated temp files, shell history, full stdout/stderr that may contain secrets or provider-internal noise, or provider quota/account details beyond normalized availability or cost-category status. Raw debug preservation is available only through explicit debug configuration with a warning that secret material may be present.
