# Data Model: Continuous Co-Review

Iteration 001 uses versioned JSON/Markdown filesystem artifacts and PowerShell DTOs that mirror the contract schemas. Durable artifacts are written under `.specrew/review/inline/<run-id>/...`; temporary request bundles are per-run, immutable, and cleanup-owned.

## Entities

### ReviewContract

Stable host-neutral interface for `review(diff, designContext) -> findings[]`.

Fields: `schema_version`, `contract_id`, `input_contracts`, `output_contracts`, `allowed_side_effects`, `failure_states`.

Rules: unknown major versions are unsafe; required fields must be well-typed; Iteration 001 must not claim hard OS/filesystem sandboxing.

### DesignContext

Bounded context used to judge design conformance.

Fields: `spec_refs`, `workshop_refs`, `implementation_rules_ref`, `quality_rules`, `visibility_policy`.

Rules: include current spec and relevant design decisions; exclude credentials, token stores, raw prompts/transcripts, unrelated temp files, secret values, and ambient machine state.

### CheckpointBaseline

Git reference or recorded checkpoint point used to compute the current change-set.

Fields: `checkpoint_id`, `baseline_ref`, `baseline_type`, `created_at`, `source_artifact_ref`.

Rules: missing or ambiguous baseline blocks advancement as deterministic failure.

### ChangeSet

Reviewable diff between checkpoint baseline and current worktree.

Fields: `change_set_id`, `baseline_ref`, `diff_ref` or `diff_inline`, `diff_hash`, `changed_paths`, `reviewable_path_count`, `excluded_paths`, `no_reviewable_diff_reason`.

Rules: derive from `git diff`; no reviewable diff creates `ReviewRunSkipped`, not silent success.

### ReviewRequest

Canonical reviewer input.

Fields: `schema_version`, `run_id`, `checkpoint_id`, `baseline_ref`, `review_kind`, `change_set`, `design_context_refs`, `allowed_paths`, `forbidden_paths`, `provider_request`, `output_contract`, `request_hash`, `created_at`.

Rules: required before spawn; `run_id` is unique/normalized; Iteration 001 active `review_kind` is `code-change-set`; paid/non-default/external/new provider/model requests require authorization.

### ReviewRunWorkspace

Temporary per-run workspace and immutable request bundle location.

Fields: `workspace_id`, `run_id`, `path`, `bundle_ref`, `debug_preserve`, `cleanup_status`, `created_at`, `cleaned_at`.

Rules: generated/normalized path; no bundle reuse; cleanup failure is recorded and cannot convert block/finding to pass.

### ReviewerProviderConfig

Explicit non-secret provider/model selection and authorization shape.

Fields: `allowed_adapters`, `preferred_candidates`, `requested_host`, `requested_model`, `cost_category`, `external_provider`, `authorization_required`, `authorization_record_ref`, `timeout_seconds`, `fallback_policy`.

Rules: no credentials/tokens/environment values; non-default/paid/external/new providers require authorization; at most one availability fallback; no silent downgrade.

### ProviderCapability

Discovered/configured capability record for a headless host.

Fields: `adapter_id`, `host`, `command`, `headless_prompt_args`, `installed`, `model_ids`, `model_id_source`, `supports_stdout_json_request`, `availability_status`, `discovery_evidence`.

Rules: discovery order is explicit config/allowlist, official model-list command where available, reliable CLI help/introspection, then human-entered IDs; no runtime live web search dependency.

### ReviewerSelection

Recommendation and chosen provider/model.

Fields: `selection_id`, `run_id`, `requested_candidate`, `recommended_candidate`, `actual_candidate`, `independence_class`, `authorization_record_ref`, `fallback_used`, `fallback_reason`.

Rules: prefer strongest available review-class and cross-host/model independence when available and authorized; same-host fresh-context remains valid when justified.

### SpawnInvocation

Adapter execution record for one reviewer attempt.

Fields: `schema_version`, `invocation_id`, `run_id`, `attempt_number`, `adapter_id`, `requested_host`, `requested_model`, `actual_host`, `actual_model`, `argv_summary`, `working_directory_ref`, `timeout_seconds`, `stdout_capture_policy`, `stderr_capture_policy`, `exit_code`, `failure_category`, `started_at`, `ended_at`.

Rules: safe argv/equivalent invocation; full stdout/stderr/raw transcripts not durable by default; timeout/nonzero/empty/invalid output maps to `InfrastructureFailure`.

### FindingsResult and Finding

Structured reviewer result and individual concern.

Fields: result `schema_version`, `run_id`, `status`, `reviewer`, `findings`, `result_hash`, `created_at`; finding `finding_id`, `source_run_id`, `fingerprint`, `location`, `severity`, `kind`, `design_reference`, `comment`, `disposition`, `resolution`.

Rules: parse as JSON and satisfy schema; unresolved `blocking` blocks; every finding has stable id, design/spec reference, location when applicable, disposition, and resolution state.

### Disposition

Editor/orchestrator response to a finding.

Fields: `disposition_id`, `finding_id`, `state`, `rationale`, `fix_evidence_ref`, `review_round`, `actor_role`, `recorded_at`.

Rules: rejection requires rationale; blocking resolution requires changed diff evidence, reviewer re-check evidence, or explicit human escalation/defer rationale; unknown blocking disposition is unsafe.

### ReviewThread

Durable blackboard record.

Fields: `schema_version`, `thread_id`, `run_id`, `checkpoint_id`, `findings`, `dispositions`, `resolution_summary`, `escalation_ref`, `created_at`, `updated_at`.

Rules: stored under `.specrew/review/inline/<run-id>/...`; missing/duplicated/malformed/unknown schema is unsafe; owned by orchestrator, not reviewer.

### GateVerdict

Deterministic checkpoint advancement decision.

Fields: `schema_version`, `verdict_id`, `run_id`, `checkpoint_id`, `state`, `unresolved_blocking_count`, `blocking_finding_ids`, `unsafe_reasons`, `round_count`, `escalation_ref`, `created_at`.

Rules: pass is impossible with unresolved blocking findings; malformed state is unsafe; same blocking finding after initial plus one fix-verification round escalates; no diff produces skipped/pass-no-op.

### ReviewRun and ReviewRunSkipped

Audit index and explicit no-op evidence.

Fields: `schema_version`, `run_id`, `checkpoint_id`, `baseline_ref`, request/invocation/result/thread/verdict refs, requested/actual host-model, cleanup status, status, timestamps, or skipped `reason`.

Rules: `run_id` is primary correlation key; durable writes are idempotent by run id; replay creates new run id; no raw prompts/transcripts/secrets/ambient state.

### InfrastructureFailure

Structured operational failure that prevents safe advancement.

Fields: `schema_version`, `failure_id`, `run_id`, `invocation_id`, `category`, `message`, `safe_details`, `retryable`, `fallback_allowed`, `created_at`.

Rules: never treated as no findings; secret values/raw transcripts/ambient state excluded; internal invariant defects fail validation.

## Relationships

```text
CheckpointBaseline -> ChangeSet -> ReviewRequest -> SpawnInvocation -> FindingsResult | InfrastructureFailure
ReviewRequest -> DesignContext
ReviewRequest -> ReviewerProviderConfig -> ProviderCapability -> ReviewerSelection -> SpawnInvocation
FindingsResult -> Finding -> Disposition -> ReviewThread -> GateVerdict
ReviewRun indexes request, invocation, result/failure, thread, verdict, cleanup
No reviewable ChangeSet -> ReviewRunSkipped -> GateVerdict(pass/no-op)
ImplementationRulesManifest constrains all implementation/review tasks
```

## State Transitions

Finding disposition:

```text
open -> accepted_fix_pending -> resolved
open -> rejected_with_rationale
open | accepted_fix_pending -> escalated_to_human
```

Gate verdict:

```text
pending -> pass | blocked | unsafe | escalated | skipped(pass/no-op)
```

Review run:

```text
created -> request_built -> capability_checked -> authorized -> invoked -> normalized -> persisted -> gated -> cleanup_recorded
created -> skipped
any active state -> infrastructure_failure_or_unsafe
```
