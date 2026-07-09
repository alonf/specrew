# Data Model: Continuous Co-Review

Iteration 001 uses versioned JSON/Markdown filesystem artifacts and PowerShell DTOs that mirror the contract schemas. Durable artifacts are written under `.specrew/review/inline/<run-id>/...`; temporary request bundles are per-run, immutable, and cleanup-owned. Iteration 002 preserves that spine and evolves the reviewer input/prompt model so runtime correctness comes from an injected canonical reviewer definition rather than host-local agent auto-loading.

## Entities

### ReviewContract

Stable host-neutral interface for `review(diff, designContext) -> findings[]`.

Fields: `schema_version`, `contract_id`, `input_contracts`, `output_contracts`, `allowed_side_effects`, `failure_states`.

Rules: unknown major versions are unsafe; required fields must be well-typed; Iteration 001 must not claim hard OS/filesystem sandboxing.

### DesignContext

Bounded context used to judge design conformance.

Fields: `spec_refs`, `workshop_refs`, `implementation_rules_ref`, `quality_rules`, `visibility_policy`, `content`, `sources`.

Rules: include current spec and relevant design decisions; exclude credentials, token stores, raw prompts/transcripts, unrelated temp files, secret values, and ambient machine state.

### CheckpointBaseline

Git reference or recorded checkpoint point used to compute the current change-set.

Fields: `checkpoint_id`, `baseline_ref`, `baseline_type`, `created_at`, `source_artifact_ref`.

Rules: missing or ambiguous baseline blocks advancement as deterministic failure.

### ChangeSet

Reviewable diff between checkpoint baseline and current worktree.

Fields: `change_set_id`, `baseline_ref`, `diff_ref` or `diff_inline`, `diff_content`, `diff_hash`, `changed_paths`, `reviewable_path_count`, `excluded_paths`, `no_reviewable_diff_reason`.

Rules: derive from `git diff`; no reviewable diff creates `ReviewRunSkipped`, not silent success.

### ReviewerInstruction

Canonical Specrew-owned reviewer definition.

Fields: `schema_version`, `instruction_id`, `canonical_path`, `content`, `content_hash`, `rubric_phases`, `workshop_validation_policy`, `claim_design_trace_policy`, `report_falsification_policy`, `visibility_policy`, `do_policy`, `round_protocol`, `created_at`.

Rules: canonical source is `scripts/internal/continuous-co-review/code-review-agent.md`; host-folder/native copies are not authoritative; content hash is carried into `ReviewRequest.v2` and `ReviewPrompt`.

### RoundContext

Review/fix round state supplied to the reviewer.

Fields: `round_number`, `prior_findings`, `max_rounds`, `prior_run_ids`, `non_convergence_policy`.

Rules: round number is required; prior findings are explicit, even when empty; non-convergence follows the configured initial review plus one fix-verification round unless later approved.

### ReviewRequest

Canonical reviewer input.

Fields: `schema_version` (`2.0` for Iteration 002), `run_id`, `checkpoint_id`, `baseline_ref`, `review_kind`, `change_set`, `design_context`, `reviewer_instruction`, `round_number`, `prior_findings`, `visibility_policy`, `do_policy`, `allowed_paths`, `forbidden_paths`, `provider_request`, `output_contract`, `request_hash`, `created_at`.

Rules: required before spawn; `run_id` is unique/normalized; active `review_kind` is `code-change-set`; `change_set` carries exact diff content or a content-addressed diff source; `design_context` carries content and sources; `reviewer_instruction` carries canonical path and content hash; `output_contract` is `FindingsResult.v1`; paid/non-default/external/new provider/model requests require authorization.

### ReviewPrompt

Exact prompt sent through the headless host transport.

Fields: `schema_version`, `run_id`, `prompt_id`, `review_request_hash`, `reviewer_instruction_hash`, `design_context_sources`, `diff_hash`, `round_number`, `prior_finding_ids`, `visibility_policy`, `do_policy`, `output_contract`, `prompt_content`, `prompt_hash`, `created_at`.

Rules: built by the prompt composer from `ReviewRequest.v2` plus canonical instruction content; adapters receive this composed prompt and remain transport-only; tests must inspect `prompt_content` or the exact prompt file and fail on empty/bypassed prompts.

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

Fields: `schema_version`, `invocation_id`, `run_id`, `attempt_number`, `adapter_id`, `requested_host`, `requested_model`, `actual_host`, `actual_model`, `argv_summary`, `working_directory_ref`, `prompt_ref`, `read_only_mode_requested`, `read_only_mode_supported`, `timeout_seconds`, `stdout_capture_policy`, `stderr_capture_policy`, `exit_code`, `failure_category`, `started_at`, `ended_at`.

Rules: safe argv/equivalent invocation; adapter receives a composed prompt rather than owning rubric text; use host read-only/no-write flags where supported; full stdout/stderr/raw transcripts not durable by default; timeout/nonzero/empty/invalid output maps to `InfrastructureFailure`.

### WorkspaceMutationGuard

Uniform pre/post mutation invalidation boundary around reviewer execution.

Fields: `guard_id`, `run_id`, `pre_source_fingerprint`, `post_source_fingerprint`, `pre_git_status`, `post_git_status`, `pre_specrew_state_fingerprint`, `post_specrew_state_fingerprint`, `mutated`, `mutation_kinds`, `invalidates_run`, `created_at`.

Rules: source, Git, or Specrew-state mutation invalidates the run even if the host lacks a read-only flag; mutation evidence is recorded but never copied back as a fix.

### HostAgentMirror

Best-effort native-host copy of the canonical reviewer instruction.

Fields: `mirror_id`, `host`, `canonical_path`, `mirror_path`, `canonical_content_hash`, `mirror_content_hash`, `sync_status`, `authoritative`, `last_checked_at`.

Rules: `authoritative` is always false; runtime prompt injection must succeed without the mirror; stale or missing mirrors are consistency findings, not runtime sources of truth.

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
CheckpointBaseline -> ChangeSet -> ReviewRequest.v2 -> ReviewPrompt -> SpawnInvocation -> FindingsResult | InfrastructureFailure
ReviewRequest.v2 -> DesignContext(content, sources)
ReviewRequest.v2 -> ReviewerInstruction -> ReviewPrompt
ReviewRequest.v2 -> RoundContext
ReviewPrompt -> Host adapters (transport only)
ReviewRequest -> ReviewerProviderConfig -> ProviderCapability -> ReviewerSelection -> SpawnInvocation
SpawnInvocation -> WorkspaceMutationGuard -> GateVerdict(unsafe when mutated)
ReviewerInstruction -> HostAgentMirror(best-effort, non-authoritative)
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
created -> request_built -> prompt_composed -> capability_checked -> authorized -> mutation_guard_started -> invoked -> mutation_guard_checked -> normalized -> persisted -> gated -> cleanup_recorded
created -> skipped
any active state -> infrastructure_failure_or_unsafe
mutation_guard_checked(mutated) -> invalidated_unsafe
```
