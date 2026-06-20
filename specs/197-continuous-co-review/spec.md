# Feature Specification: Continuous Co-Review

**Feature Branch**: `197-continuous-co-review`  
**Created**: 2026-06-17  
**Status**: Draft  
**Input**: User description: "Start Proposal 197 — Continuous Co-Review — as a
Specrew software feature. First iteration must create the host-neutral spine and
design as new files only, including the review contract, forced findings schema,
git-diff change-set, blackboard review-thread protocol, deterministic blocking
gate, orchestrator git-diff loop trigger, headless-floor spawn adapters, and a
read-only rung 2b fresh-context reviewer."

## Product-Domain Summary

- **Depth**: standard (feature_standalone)
- **Users and stakeholders**: Primary users are Specrew implementers, Spec
  Stewards, reviewers, and maintainers working through lifecycle checkpoints;
  downstream Specrew project teams benefit indirectly through fewer late review
  surprises.
- **Pain/job**: Proposal 145 review runs late at review-signoff, after design
  drift and abstraction leaks are already expensive. Continuous co-review
  re-checks checkpoint change-sets against the approved design contract while
  fixes are still cheap.
- **MVP**: Iteration 001 delivers the host-neutral rung 2b spine: reviewer
  contract, forced findings JSON schema, git-diff change-set, blackboard
  protocol, standalone blocking gate, orchestrator checkpoint loop trigger,
  headless-floor adapters, and fresh-context read-only reviewer.
- **Send-back repair**: Iteration 002 preserves the completed Iteration 001
  spine and repairs reviewer-definition correctness by making Specrew's
  canonical reviewer instructions, v2 request content, prompt injection,
  mutation guard, and SC-012 manual path explicit and testable.
- **Always-on extension**: Iteration 003 makes co-review mandatory and automatic
  at every implement checkpoint (the pair-programming navigator reviewing each
  increment), enforced by a deterministic per-stop gate wired into the shared
  boundary-advance surface under human-authorized F-184 coordination, instead of
  a single signoff-time run.
- **Non-goals**: Rung 1, PostToolUse hook triggers, Proposal 139 heavy
  foundation work, and edits to F-184-protected host-runtime/hook/provider/
  registry/refocus/shared governance surfaces are out of scope.
- **Constraints**: Run against this worktree's Specrew module, never run
  `specrew update` in this repo, use markdownlint before every commit, treat
  `C:\Dev\183-stability-quality-bundle` as read-only sibling context, and plan
  for a later branch merge with F-184.
- **Full record**: see `workshop/product-domain.md` and
  `workshop/product-domain.yml`.

## Clarifications

### Session 2026-06-17

No critical ambiguities detected worth formal clarification; specify approvals
and Proposal 197 guardrails are already represented in the requirements, scope
boundaries, assumptions, and success criteria.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Review each checkpoint against the design contract (Priority: P1)

As a Specrew implementer, I need a read-only reviewer to evaluate the current
checkpoint change-set against the approved design contract before I advance, so
design drift and abstraction leaks are caught while they are still cheap to fix.

**Why this priority**: This is the core shift-left value of Proposal 197. Without
checkpoint review and gate feedback, the feature does not reduce late
review-signoff surprises.

**Independent Test**: Can be tested by creating a checkpoint baseline, making a
small design-violating change, running the inline review loop, and verifying that
a blocking finding is produced and prevents checkpoint advancement.

**Acceptance Scenarios**:

1. **Given** a checkpoint baseline and a design contract, **When** changed files
   introduce a violation of a recorded design decision, **Then** the reviewer
   returns a structured blocking finding that references the violated decision.
2. **Given** a checkpoint has only advisory concerns, **When** the review loop
   completes, **Then** the checkpoint may advance while advisory findings remain
   recorded for follow-up.
3. **Given** a blocking finding is accepted and fixed, **When** the change-set is
   reviewed again, **Then** the finding can be marked resolved and the gate no
   longer blocks on it.

---

### User Story 2 - Preserve an auditable editor-reviewer thread (Priority: P2)

As a Spec Steward or reviewer, I need every inline finding and editor disposition
to be recorded in a durable blackboard artifact, so acceptance, rejection,
rationale, and unresolved blocking state can be reviewed later.

**Why this priority**: The deterministic gate depends on reliable state, and
human reviewers need to see why a checkpoint was allowed or blocked.

**Independent Test**: Can be tested by producing sample findings, accepting one,
rejecting another with rationale, and verifying that the blackboard artifact
contains valid entries with the expected disposition states.

**Acceptance Scenarios**:

1. **Given** a reviewer returns findings, **When** the orchestrator records the
   review result, **Then** a `.specrew/review/inline/...` review-thread artifact
   exists with each finding, severity, kind, design reference, and disposition.
2. **Given** an editor rejects a finding, **When** the rejection is recorded,
   **Then** the blackboard captures the rationale as a boundary-variance record
   rather than silently discarding the finding.
3. **Given** a blackboard artifact contains malformed or incomplete finding
   state, **When** the gate validator runs, **Then** the checkpoint does not
   advance until the artifact is corrected or escalated.

---

### User Story 3 - Run everywhere through a host-neutral headless floor (Priority: P3)

As a Specrew maintainer, I need the reviewer spawn contract to work across the
supported hosts without depending on host-specific hooks or in-session subagent
features, so Proposal 197 remains host-neutral and does not conflict with the
in-flight host-runtime rewrite.

**Why this priority**: Cross-host availability is required for Specrew itself,
but it is secondary to establishing the review contract and gate semantics.

**Independent Test**: Can be tested by invoking each declared headless-floor
adapter with the same diff and design context, and verifying that each adapter
can request a structured findings response without writing to the source tree.

**Acceptance Scenarios**:

1. **Given** a supported host is available only through headless prompt mode,
   **When** the review loop needs a fresh reviewer, **Then** the matching spawn
   adapter can invoke that host and request the forced findings output.
2. **Given** a host offers richer in-session subagent capabilities, **When** the
   first iteration runs, **Then** the feature still uses the headless-floor
   contract and treats richer surfaces as later optimizations.
3. **Given** F-184 is actively rewriting hook, provider, registry, and refocus
   surfaces, **When** this feature adds its first-iteration artifacts, **Then**
   it avoids editing those protected surfaces.

### Edge Cases

- The reviewer returns invalid, partial, or non-JSON output.
- The change-set includes out-of-band edits made outside the editor host.
- A checkpoint has no diff relative to the baseline.
- A finding points to a file or line that moved after a fix.
- Multiple findings describe the same underlying design violation.
- The same blocking finding remains unresolved after the allowed review/fix
  rounds.
- A supported host command is missing or times out.
- A blackboard artifact is missing, duplicated, or has an unknown schema version.
- A reviewer recommends code edits even though the reviewer is read-only.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The feature MUST define a host-neutral
  `review(diff, designContext) -> findings[]` reviewer contract with deterministic
  inputs, outputs, and failure states. Owner: Architect. Delivery: Iteration 001.
- **FR-002**: The feature MUST define a forced findings JSON schema that includes
  finding id, file location, severity, kind, design reference, reviewer comment,
  disposition, and resolution metadata. Owner: Architect. Delivery: Iteration
  001.
- **FR-003**: The feature MUST compute review change-sets from `git diff` against
  a checkpoint baseline so tool-call edits, formatter changes, generated files,
  hand edits, and merge effects are all visible. Owner: Implementer. Delivery:
  Iteration 001.
- **FR-004**: The feature MUST provide a blackboard review-thread protocol and
  artifact location under `.specrew/review/inline/...`, owned by the orchestrator
  rather than by the reviewer sub-agent. Owner: Architect. Delivery: Iteration
  001.
- **FR-005**: The feature MUST define editor dispositions for each finding:
  accept and fix, reject with rationale, mark resolved, or escalate to a human
  when convergence fails. Owner: Spec Steward. Delivery: Iteration 001.
- **FR-006**: The feature MUST define a standalone deterministic gate validator
  that blocks checkpoint advancement while any unresolved `blocking` finding
  exists. Owner: Reviewer. Delivery: Iteration 001.
- **FR-007**: The gate validator MUST treat malformed blackboard state, invalid
  findings schema, or unknown blocking disposition as not safe to advance until
  corrected or escalated. Owner: Reviewer. Delivery: Iteration 001.
- **FR-008**: The first iteration MUST trigger inline review from the orchestrator
  git-diff loop at checkpoint boundaries, not from a PostToolUse or other hook
  trigger. Owner: Iteration Facilitator. Delivery: Iteration 001.
- **FR-009**: The first iteration MUST use rung 2b as the default reviewer mode:
  a fresh-context, read-only reviewer sub-agent fed the diff and design contract.
  Owner: Spec Steward. Delivery: Iteration 001.
- **FR-010**: The reviewer MUST be least-privilege and read-only with respect to
  source files; its only allowed durable output is the findings result consumed
  by the orchestrator. Owner: Security Reviewer. Delivery: Iteration 001.
- **FR-011**: The design context supplied to the reviewer MUST include the current
  spec, workshop/design decisions, applicable design/convention skills, and
  relevant quality/testability rules. Owner: Spec Steward. Delivery: Iteration
  001.
- **FR-012**: The feature MUST add new headless-floor spawn adapter artifacts for
  `claude -p`, `codex exec`, `copilot -p`, `cursor-agent -p`, and antigravity
  `-p`. Owner: Implementer. Delivery: Iteration 001.
- **FR-013**: The first iteration MUST avoid editing F-184-protected hook,
  provider, registry, host-runtime, refocus, and shared governance surfaces.
  Owner: Spec Steward. Delivery: Iteration 001.
- **FR-014**: The feature MUST make Proposal 145 review-signoff remain the final
  aggregate backstop; continuous co-review supplements it and does not replace
  it. Owner: Reviewer. Delivery: Iteration 001.
- **FR-015**: The feature MUST document how Proposal 197 later graduates to
  cross-host or cross-model reviewer rungs without changing the stable contract.
  Owner: Architect. Delivery: Iteration 001.
- **FR-016**: The feature MUST require explicit reviewer provider/model
  configuration and user authorization before spawning any paid or non-default
  reviewer process. Owner: Spec Steward. Delivery: Iteration 001.
- **FR-017**: The feature MUST author a Specrew-owned canonical reviewer
  instruction file at
  `scripts/internal/continuous-co-review/code-review-agent.md`; this file is
  the reviewer definition and MUST encode Proposal 145 rubric phases,
  workshop-decision conformance, claim/design trace, report-falsification,
  explicit per-lens validation of workshop results, visibility policy,
  do-policy, and the review/fix round protocol. Owner: Spec Steward. Delivery:
  Iteration 002.
- **FR-018**: Runtime correctness MUST depend on injecting the canonical
  reviewer instruction content into the actual headless `-p`/`exec` prompt
  sent to adapters; native host-folder or agent-file mirrors MAY exist only as
  consistency/best-effort copies and MUST NOT be relied on for correctness.
  Owner: Architect. Delivery: Iteration 002.
- **FR-019**: `ReviewRequest` MUST evolve to schema version `2.0` carrying
  design-context content and sources, exact diff/change-set content,
  `round_number`, `prior_findings`, `visibility_policy`, `do_policy`,
  reviewer-instruction metadata/content hash, and output contract
  `FindingsResult.v1`. Owner: Architect. Delivery: Iteration 002.
- **FR-020**: Reviewer invocation MUST request read-only host behavior where a
  supported headless host exposes such a flag or mode, and MUST enforce a
  uniform mutation guard that invalidates the run when source, Git, or Specrew
  state changes during reviewer execution. Owner: Security Reviewer. Delivery:
  Iteration 002.
- **FR-021**: Deterministic tests MUST assert that the actual outbound prompt
  contains the Proposal 145 rubric, canonical reviewer instruction content,
  design-context content, exact diff/change-set content, round number, prior
  findings, visibility policy, do-policy, and `FindingsResult.v1` output
  contract; fixtures MUST fail when the prompt is empty or bypassed. Owner:
  Reviewer. Delivery: Iteration 002.
- **FR-022**: The SC-012 manual runbook MUST invoke the exact implemented
  orchestrator/prompt-composer path that produces the injected prompt, not a
  handwritten common prompt copied into host CLIs. Owner: Spec Steward.
  Delivery: Iteration 002.
- **FR-023**: Before Iteration 002 implementation starts, the feature branch
  MUST merge or rebase latest remote `main` and resolve conflicts; a large
  conflict surface MAY be split into a preparatory sync task but MUST happen
  before reviewer-definition runtime work. Owner: Iteration Facilitator.
  Delivery: Iteration 002.
- **FR-024**: Continuous co-review MUST run automatically at every implement
  checkpoint ("stop"), reviewing the incremental change-set since the prior
  checkpoint, so the navigator checks each increment as it is written rather than
  only at review-signoff. This fulfills the FR-008 checkpoint-boundary trigger
  intent and still MUST NOT use PostToolUse or file-edit hooks. Owner: Iteration
  Facilitator. Delivery: Iteration 003.
- **FR-025**: A deterministic gate floor MUST refuse review-signoff unless the
  current state is co-reviewed: a co-review run with a pass or escalated verdict
  MUST exist whose recorded `diff_hash`, recomputed from its `baseline_ref` to the
  current working tree, still matches (proving the working tree has not drifted
  since it passed). Missing evidence, a stale `diff_hash`, malformed durable state,
  or an unresolved blocking verdict MUST block. Because the co-review baseline
  advances only on a pass, this single current-state check transitively proves
  every prior increment was reviewed without per-increment git-history
  archaeology. The gate floor MUST be enforced at the non-protected boundary-sync
  chokepoint (`Invoke-SpecrewBoundaryStateSync` in
  `scripts/internal/sync-boundary-state.ps1`, which already hosts throw-to-refuse
  gates). Owner: Reviewer. Delivery: Iteration 003.
- **FR-026**: True per-stop always-on review MUST be triggered from the host
  Stop/turn-boundary hook so the navigator reviews each completed increment (a
  real checkpoint, routed through the FR-032 gate-review dispatcher — never on
  every casual yield) and blocks on an unresolved blocking finding. Because the
  hook surface is F-184-protected, this trigger MUST be wired under the
  human-authorized F-184 coordination (2026-06-20) and MUST NOT regress existing
  hook behavior. All five supported harnesses are expected to carry the Stop hook,
  so the navigator is the primary path on every host; the FR-025 gate floor is a
  universal defense-in-depth backstop for a missed, crashed, or degraded hook
  fire, never a per-host hookless downgrade. Owner: Spec Steward. Delivery:
  Iteration 003.
- **FR-027**: The co-review baseline MUST rebaseline per checkpoint to the prior
  checkpoint reference so each stop reviews only its incremental diff (the
  pair-programming increment), not the whole iteration. Owner: Implementer.
  Delivery: Iteration 003.
- **FR-028**: The navigator reviewer MUST be authorized once per project through
  explicit provider/model configuration and then run at every checkpoint without
  per-run reauthorization, satisfying the cost-authorization rule (FR-016) via
  one-time configuration rather than blocking each automatic run. Owner: Spec
  Steward. Delivery: Iteration 003.
- **FR-029**: A blocking finding at an implement checkpoint MUST stop advancement
  and surface the human re-entry packet/escalation under the existing two-round
  convergence cap (NFR-005), rather than allowing the next checkpoint to start.
  Owner: Reviewer. Delivery: Iteration 003.
- **FR-030**: The Stop-hook navigator MUST reuse Specrew's existing host-neutral
  hook/runtime abstraction (host registry, host handlers, hook dispatcher) so all
  five supported harnesses (Claude, Codex, Copilot, Cursor, Antigravity) are
  covered through one seam without per-host conditionals. All five are expected to
  expose the Stop hook through the abstraction; the FR-025 gate floor is retained
  as a universal backstop for a missed or degraded hook fire, not as a per-host
  hookless tier. Per-host Stop-hook behavior MUST be verified empirically rather
  than trusted from stale host-capability comments. Owner: Architect. Delivery:
  Iteration 003.
- **FR-031**: Iteration 003 narrowly relaxes the FR-008 "no hook trigger"
  constraint for the Stop/turn-boundary hook only (a checkpoint-boundary trigger),
  which remains distinct from and MUST NOT introduce PostToolUse or per-file-edit
  triggers. Owner: Spec Steward. Delivery: Iteration 003.
- **FR-032**: The Stop-hook trigger MUST route through a single 197-owned
  gate-review dispatcher invoked by one host-hook call. The dispatcher MUST
  determine whether the stop is a real checkpoint and which gate it belongs to,
  then dispatch only to a reviewer registered for that gate through a gate-keyed
  registry. Iteration 003 registers exactly one reviewer (code review at implement
  checkpoints); design-lens, plan, tasks, and spec gates remain unregistered
  no-op extension points, and casual non-checkpoint stops MUST be no-ops. Adding a
  future per-gate reviewer MUST be a registry entry, not a hook change. Owner:
  Architect. Delivery: Iteration 003.

### Non-Functional Requirements

- **NFR-001 Deterministic failure handling**: Timeout, nonzero exit, empty
  reviewer output, invalid JSON, malformed findings, or unknown blocking
  dispositions MUST block checkpoint advancement as structured infrastructure
  failures or unsafe gate states.
- **NFR-002 Auditability**: Each review run MUST record a run id, checkpoint
  baseline, diff summary or hash, request summary or hash, findings,
  dispositions, and gate verdict so the pass/block decision can be reconstructed.
- **NFR-003 Finding traceability**: Every finding MUST carry a stable finding
  id, source run id, design/spec reference, applicable file location,
  disposition, fix evidence reference, and resolution state.
- **NFR-004 Fix verification**: Blocking findings MUST NOT be resolved by a
  text-only "fixed" marker; resolution requires changed diff evidence,
  reviewer re-check evidence, or explicit human escalation/defer rationale.
- **NFR-005 Review/fix convergence**: Iteration 001 MUST cap the review/fix loop
  at two rounds: the initial review plus one fix-verification round. If the same
  blocking finding remains unresolved, checkpoint advancement stops and the
  issue escalates to a human decision.
- **NFR-006 Compatibility**: Iteration 001 MUST remain new-file and host-neutral
  relative to F-184-protected hook, provider, registry, host-runtime, refocus,
  and shared governance surfaces.
- **NFR-007 Least-privilege honesty**: The reviewer MUST be described as
  read-only by contract and by review-bundle scope only; Iteration 001 MUST NOT
  claim hard OS or filesystem sandboxing.
- **NFR-008 Concurrency safety**: Review runs MUST use unique run ids and
  per-run workspaces, MUST NOT reuse request bundles, and MUST make cleanup an
  owned workspace-manager responsibility.
- **NFR-009 Cost control**: Paid or non-default reviewer provider/model spawning
  MUST require explicit configuration and user authorization.
- **NFR-010 Maintainability and testability**: The feature MUST preserve stable
  schemas, provider adapter seams, and a standalone deterministic gate validator
  that can be tested without host integration.
- **NFR-011 Observability and reconstruction**: Each review attempt or skipped
  review MUST leave enough structured evidence to reconstruct why the gate passed,
  blocked, failed infrastructurally, or skipped without depending on raw provider
  transcripts.

### Data and Storage Requirements

- **DS-001 Filesystem-only storage**: Iteration 001 MUST use versioned filesystem
  artifacts only for durable review evidence and gate state; it MUST NOT
  introduce a database, queue, cache, event stream, search index, blob store, or
  external data provider.
- **DS-002 Durable review system of record**: `.specrew/review/inline/<run-id>/...`
  MUST be the durable system of record for run metadata, findings, dispositions,
  fix evidence references, gate verdicts, provenance, and schema version data.
- **DS-003 Temporary bundle lifecycle**: Review request bundles MUST be immutable
  per-run temporary workspace artifacts owned by `ReviewRunWorkspaceManager`,
  MUST NOT be reused across runs, and MUST be cleaned by default unless explicit
  debug preservation is enabled.
- **DS-004 Schema safety**: Durable review artifacts MUST carry schema version
  information, and unknown or malformed schema versions MUST be treated as
  unsafe gate states.
- **DS-005 Evidence commit policy**: Durable review artifacts MUST be committed
  when they serve as lifecycle boundary evidence; temporary request bundles MUST
  NOT be committed by default.

### Security and Compliance Requirements

- **SEC-001 Trusted reviewer context**: The reviewer is a trusted component and
  MAY inspect repository context needed for correct design-conformance review.
  Iteration 001 MUST NOT artificially blind the reviewer from normal repository
  context when doing so would reduce review quality.
- **SEC-002 Secret and ambient-state exclusion**: Review bundles and durable
  artifacts MUST NOT deliberately include environment variables, credentials,
  access tokens, token stores, local private config, unrelated temporary files,
  raw prompts, raw provider transcripts, or secret values.
- **SEC-003 Mutation boundary**: The reviewer process MAY read needed repository
  context and call its authorized provider/model, but MUST NOT directly edit
  source files, stage commits, push branches, or mutate Specrew state.
- **SEC-004 Provider/model authorization**: Reviewer invocation MUST be limited
  to allowed project or run configuration, and any non-default, paid, external,
  or newly added provider/model MUST require explicit human authorization before
  use.
- **SEC-005 Safe provider adapter invocation**: Provider adapters MUST invoke
  CLIs with structured argument arrays or equivalent safe invocation APIs rather
  than concatenating untrusted shell strings, and MUST use Specrew-generated or
  normalized run IDs and paths.
- **SEC-006 Redacted audit evidence**: Durable review evidence MAY include
  findings, traceability IDs, provider/model/run metadata, status, bounded
  snippets needed to explain findings, and audit/provenance metadata, but MUST
  redact secret values and MUST NOT persist raw ambient machine state.
- **SEC-007 Canonical instruction integrity**: Reviewer instruction content
  MUST be read from the Specrew-owned canonical file and represented by a
  content hash in the request/prompt evidence so host-local mirrors cannot
  silently become authoritative.
- **SEC-008 Enforced read-only invocation posture**: Host adapters MUST pass
  supported read-only/no-write flags or equivalent mode controls when available
  and record when a host has no such flag, without weakening the mutation guard.
- **SEC-009 Mutation invalidation boundary**: If the reviewer process mutates
  source files, Git index/history, or Specrew state, the run MUST be recorded as
  invalid/unsafe and MUST NOT be treated as a reviewer finding pass or as a fix.

### Integration and API Requirements

- **INT-001 Local contract-first integration**: Iteration 001 MUST integrate the
  orchestrator, provider adapters, reviewer process, durable artifacts, and gate
  validator through local file/stdin/stdout/CLI contracts rather than REST,
  GraphQL, gRPC, queues, daemons, streaming APIs, or in-session subagent APIs.
- **INT-002 Specrew-owned versioned contracts**: Specrew MUST own versioned
  `ReviewRequest`, `FindingsResult`, `ReviewThread`, `GateVerdict`, and
  `InfrastructureFailure` contracts; provider adapters MUST translate
  host-specific CLI behavior into those shapes.
- **INT-003 Schema compatibility policy**: Unknown major versions, malformed
  required fields, and malformed durable gate or blackboard state MUST be
  treated as unsafe and blocking; compatible additive optional fields MAY be
  accepted within a compatible version.
- **INT-004 Synchronous bounded operation**: Reviewer runs MUST be synchronous
  and bounded in Iteration 001: one fresh reviewer process per attempt,
  timeout-bound wait, one stdout parse, and durable artifact write. Availability
  fallback MAY use at most one additional authorized candidate attempt, and replay
  MUST create a new run ID and provenance record.
- **INT-005 Distinct error envelope**: Timeout, nonzero exit, empty stdout,
  invalid JSON, schema mismatch, missing provider, command invocation failure,
  unavailable requested model, or malformed durable state MUST be represented as
  infrastructure failure or unsafe gate state and MUST NOT be treated as "no
  findings."
- **INT-006 Reviewer host/model discovery**: Specrew MUST discover installed
  supported headless hosts for Codex, Claude, Copilot, Cursor, and Antigravity,
  intersect them with project/run configuration, and present available
  authorized choices when selection is missing, non-default, paid, external, or
  newly added.
- **INT-007 Review-class model preference**: Reviewer selection SHOULD favor the
  strongest available review-class model and cross-host or cross-model
  independence when available and authorized, while keeping same-host
  fresh-context review valid when cross-host review is unavailable,
  unauthorized, unaffordable, or explicitly not chosen.
- **INT-008 Volatile model catalog handling**: Model IDs MUST be treated as
  data/config rather than hardcoded contract policy. Capability discovery SHOULD
  use explicit config or allowlists first, official model-list commands when
  available, reliable CLI help/introspection when available, then human-entered
  model IDs. Runtime review MUST NOT depend on live web search.
- **INT-009 Compatibility fixture floor**: Planning MUST include producer and
  consumer fixtures for valid request/result/thread/verdict shapes and
  deterministic infrastructure failures, and each headless-floor adapter MUST
  prove it can return either a valid result or deterministic infrastructure
  failure.
- **INT-010 Prompt-composer boundary**: The orchestrator MUST compose a
  complete `ReviewPrompt` from `ReviewRequest.v2`, canonical reviewer
  instruction content, design-context content, exact diff/change-set content,
  round context, visibility policy, do-policy, and the `FindingsResult.v1`
  output contract before adapter invocation.
- **INT-011 Transport-only adapters**: Host adapters MUST receive the composed
  prompt as their transport payload and MUST NOT own reviewer rubric text,
  policy wording, prior-finding semantics, durable writes, or gate verdicts.
- **INT-012 Host mirror non-authority**: Any native host-folder or agent-file
  copy of `code-review-agent.md` is a best-effort mirror only; runtime behavior
  MUST remain correct when that mirror is absent, stale, or ignored by the host.
- **INT-013 ReviewRequest v2 compatibility**: Unknown major versions remain
  unsafe; v2 fixtures MUST prove producer/consumer compatibility for
  instruction metadata, design-context content/sources, exact diff content,
  round context, prior findings, visibility/do policies, and output contract.

### DevOps and Operations Requirements

- **OPS-001 Local hosting model**: Iteration 001 MUST run as a local Specrew
  tool/module-command path in the developer checkout/session and MUST NOT
  introduce a server, daemon, queue, cloud resource, background service, or
  hosted reviewer worker.
- **OPS-002 Local spine ownership**: Proposal 197 MUST own only the local review
  spine: review contracts/schemas, provider adapter interfaces, static provider
  catalog/config references, durable artifact writer, and local validator/test
  fixtures. Git, PowerShell/Specrew runtime, installed AI host CLIs, provider
  accounts/quotas, branch protection, and PR review remain external or
  human-owned prerequisites.
- **OPS-003 Contract-level environment parity**: Contract schema validation,
  producer/consumer fixtures, deterministic infrastructure failures, durable
  artifact shape, reviewer mutation boundary, and no-silent-downgrade behavior
  MUST be equivalent across local validation environments. Installed
  providers/models and paid/external authorization MAY differ and MUST surface as
  capability or authorization outcomes.
- **OPS-004 Non-secret configuration**: Proposal 197 MAY define explicit
  non-secret provider/model/config policy and per-run authorization evidence, but
  MUST NOT collect, store, copy, normalize, bundle, or persist provider
  credentials, environment variables, token stores, unrelated private config, raw
  provider transcripts, or secret values.
- **OPS-005 CI/CD posture**: Iteration 001 MUST rely on local validation plus
  existing GitHub PR governance for rollout and MUST NOT add a new GitHub
  Actions workflow, mutate branch protection, publish a release, or automate
  rollout/rollback unless explicitly re-scoped.
- **OPS-006 Reviewer-agent CI/CD E2E compatibility**: Proposal 197 MUST preserve
  contract hooks and fixtures so a downstream or companion CI/CD E2E proposal can
  exercise request creation, adapter invocation, reviewer process or controlled
  fake, result/failure envelope, durable artifacts, and gate verdict end-to-end.
- **OPS-007 No new service identity**: Iteration 001 MUST NOT introduce a new
  service identity. The local human developer/operator owns provider auth and
  cost authorization; any CI/CD service identity or harness belongs to the
  downstream CI/CD E2E proposal.

### Observability and Resilience Requirements

- **OBS-001 Evidence split**: Iteration 001 MUST separate reviewer input,
  adapter execution, and durable audit index responsibilities into
  `ReviewRequest`, `SpawnInvocation`, and `ReviewRun` artifacts or equivalent
  contract sections.
- **OBS-002 Correlation chain**: `run_id` MUST be the primary correlation key
  across request, invocation, findings result, review thread, and gate verdict
  artifacts, with checkpoint id, baseline ref, request hash, schema version,
  adapter id, requested/actual host/model, finding ids, thread id, verdict id,
  unresolved blocking count, and escalation ref recorded where applicable.
- **OBS-003 Readiness floor**: Planning MUST include schema/fixture validation,
  local adapter capability checks, and a controlled fake or fixture adapter path
  that exercises valid findings and deterministic infrastructure failures end to
  end. Real AI-host smoke MUST be optional and explicitly configured/authorized.
- **OBS-004 Explicit skipped run**: A trigger or checkpoint with no reviewable
  diff MUST produce an explicit `ReviewRunSkipped` or equivalent no-op evidence
  record and pass/no-op gate verdict rather than being treated as an error or
  silently ignored.
- **OBS-005 Failure taxonomy**: Dependency, configuration, authorization,
  provider availability, timeout, malformed output, malformed durable state, and
  non-convergence failures MUST be represented as structured operational
  outcomes, while internal invariant violations MUST fail validation as code
  defects.
- **OBS-006 Bounded availability fallback**: Reviewer invocation MAY use an
  ordered provider/host/model priority list from explicit non-secret
  configuration, but Iteration 001 MUST allow at most one availability fallback
  attempt, MUST require each candidate to be authorized before use, and MUST
  record requested and actual host/model provenance without silent downgrade.
- **OBS-007 Replay and idempotency**: Replay MUST create a new run id and
  provenance record. Review request bundles MUST be immutable per run, MUST NOT
  be reused, and durable writes SHOULD be idempotent by run id and fail on
  accidental overwrite.
- **OBS-008 Cleanup evidence**: Temporary run workspace cleanup MUST happen after
  durable outcome persistence, MUST record cleanup status, and MUST NOT convert a
  valid finding or block into a pass if cleanup fails.
- **OBS-009 Redacted evidence boundary**: Durable artifacts MUST persist
  structured redacted evidence only. Raw prompts, raw provider transcripts, full
  stderr/stdout, environment variables, credentials, token stores, unrelated
  files, unrelated temp state, and provider account/quota details MUST be omitted
  by default unless explicit debug preservation is enabled with warning.
- **OBS-010 Prompt injection evidence**: Each review run MUST record enough
  structured evidence to prove which canonical reviewer instruction hash,
  design-context sources, diff hash/content source, round number, prior finding
  ids, visibility policy, do-policy, and output contract were injected, without
  committing raw transcripts by default.
- **OBS-011 Empty-prompt falsification**: Fixture tests MUST falsify the prompt
  path by failing if the adapter can pass while receiving an empty prompt,
  request-only JSON without the reviewer rubric, or fixture-owned substitute
  prompt text.
- **OBS-012 Mutation guard evidence**: Run evidence MUST record pre/post source,
  Git, and Specrew-state mutation guard checks and mark mutation as an unsafe
  invalidated run.

### Implementation Craft Requirements

- **IMPL-001 Code-rules source of truth**: Proposal 197 implementation MUST use
  the current Specrew implementation methods and
  `specs/197-continuous-co-review/implementation-rules.yml` as the binding
  code-rules source of truth; no external guideline or example project is
  ingested for this feature.
- **IMPL-002 Resolved stack**: Implementation MUST target PowerShell 7.x
  scripts/modules plus Markdown, YAML, and JSON governance artifacts and schemas,
  with deterministic Pester tests and local file/stdin/stdout/process-exit
  contracts.
- **IMPL-003 Structured operational outcomes**: Expected reviewer operational
  outcomes MUST be represented as structured records/artifacts, while internal
  invariant, schema, or code defects MUST fail loudly in tests and review rather
  than being disguised as infrastructure failures.
- **IMPL-004 Adapter extension posture**: Host/provider behavior MUST use
  PowerShell-friendly function/module Strategy seams and declared capability
  descriptors; core orchestration MUST NOT grow repeated host-name conditionals
  for each supported provider.
- **IMPL-005 Contract validation posture**: Review request, capability,
  invocation, result, thread, verdict, run, skipped-run, and infrastructure
  failure artifacts MUST be validated at input, execution, and output boundaries
  with deterministic schema and fixture coverage.
- **IMPL-006 Dependency posture**: Iteration 001 MUST use existing project tools
  and MUST NOT add a new runtime, test, build, PowerShell, npm, Python, or .NET
  package dependency unless explicitly re-scoped with version, license, source,
  canonical URL, maintenance/security, compatibility, cost/quota, coupling,
  replaceability, and test-impact evidence.
- **IMPL-007 Packaging posture**: Reusable Proposal 197 implementation surfaces
  MUST ship through existing Specrew module/deployment mechanisms and avoid a
  new separate package or broad common utility library in Iteration 001.
- **IMPL-008 Canonical reviewer definition source**: The canonical
  `code-review-agent.md` file MUST live under
  `scripts/internal/continuous-co-review/` and be loaded by a feature-local
  prompt composer; host-folder copies are generated or maintained only as
  non-authoritative mirrors.
- **IMPL-009 ReviewRequest v2 and prompt composer**: The implementation MUST
  keep request building, prompt composition, adapter invocation, result
  normalization, blackboard writing, and gate evaluation as separate
  feature-local responsibilities.
- **IMPL-010 No fixture masking**: Tests and fixtures MUST inspect the actual
  adapter-bound prompt string or prompt file produced by the composer; fixture
  findings MUST NOT be able to satisfy tests while the composed prompt is empty
  or missing the canonical reviewer definition.
- **IMPL-011 Pre-implementation sync**: Iteration 002 implementation MUST begin
  with a latest-remote-`main` merge or rebase and conflict repair before editing
  runtime code for the reviewer-definition repair.

### Scope Boundaries

**In scope for Iteration 001**:

- New host-neutral contract, schema, protocol, validator, and adapter artifacts.
- Checkpoint-level orchestrator loop using a git-diff change-set.
- Read-only rung 2b fresh-context reviewer path.
- Durable blackboard review-thread state under `.specrew/review/inline/...`.
- Deterministic blocking gate as a standalone validator.
- Headless-host and model capability discovery for Codex, Claude, Copilot,
  Cursor, and Antigravity, without quota/usage probing.
- Local non-secret configuration and local validation fixtures needed to expose
  reviewer-agent contract hooks for downstream CI/CD E2E coverage.
- The per-feature code implementation manifest and code-rule guidance needed to
  bind planning, implementation, and review to the approved craft decisions.

**In scope for Iteration 002 reviewer-definition repair**:

- Canonical reviewer instruction file at
  `scripts/internal/continuous-co-review/code-review-agent.md`.
- `ReviewRequest.v2`, `ReviewerInstruction`, `ReviewPrompt`, `RoundContext`,
  `WorkspaceMutationGuard`, and `HostAgentMirror` planning/runtime contracts.
- Prompt-composer path that injects canonical reviewer instruction content into
  the actual adapter-bound headless prompt.
- Read-only host invocation flags where supported plus uniform source/Git/
  Specrew mutation invalidation.
- Deterministic prompt-fixture tests and SC-012 manual runbook updates that use
  the exact injected-prompt path.
- Latest remote `main` synchronization before implementation.

**In scope for Iteration 003 always-on per-checkpoint co-review**:

- Automatic navigator co-review at every implement checkpoint with a per-stop
  incremental baseline.
- A deterministic per-checkpoint gate floor added to the non-protected
  boundary-sync chokepoint, including a review-signoff backstop that blocks
  signoff unless every increment carries passing or escalated co-review evidence.
- A Stop/turn-boundary hook navigator wired through Specrew's existing
  host-neutral hook/runtime abstraction (under authorized F-184 coordination) so
  all five harnesses are covered through one seam as the primary path, with the
  gate floor retained as a universal backstop for any missed hook fire.
- A narrow FR-008 relaxation for the Stop hook only, never PostToolUse or
  per-file-edit triggers.
- A 197-owned gate-review dispatcher behind one host-hook call, with a gate-keyed
  registry holding a single registrant (code review at implement) and unregistered
  no-op slots for future per-gate reviewers (design-lens, plan, tasks, spec).
- One-time per-project navigator authorization so automatic runs need no per-run
  cost reauthorization.
- Reuse of the existing rung 2b runtime spine, request/prompt/adapter, blackboard,
  gate evaluator, and two-round convergence cap without reopening the
  Iteration 001/002 spine.

**Out of scope for Iteration 001**:

- Proposal 197 rung 1 cross-host reviewer on Proposal 139 foundation.
- PostToolUse or hook-based triggers.
- Proposal 139 heavy foundation work.
- Direct edits to F-184-protected host-runtime, hook, provider, registry, refocus,
  and shared governance surfaces.
- The protected-surface list explicitly includes `hosts/_registry.ps1`,
  `hosts/_team-canonical.ps1`, `hosts/claude/handlers.ps1`,
  `hosts/codex/handlers.ps1`, `hosts/copilot/handlers.ps1`,
  `scripts/specrew-host.ps1`, `scripts/specrew-hooks.ps1`,
  `scripts/internal/host-runtime-inventory.ps1`,
  `scripts/internal/host-history.ps1`,
  `scripts/internal/host-flag-translation.ps1`,
  `scripts/internal/specrew-hook-dispatcher.ps1`,
  `scripts/internal/specrew-hook-health.ps1`,
  `scripts/internal/refocus.ps1`,
  `scripts/internal/refocus-deploy-integration.ps1`,
  `extensions/specrew-speckit/scripts/provider-adapter.ps1`,
  `extensions/specrew-speckit/scripts/provider-generic.ps1`,
  `extensions/specrew-speckit/scripts/provider-github.ps1`,
  `extensions/specrew-speckit/scripts/capability-detector.ps1`,
  `extensions/specrew-speckit/scripts/refocus.ps1`,
  `extensions/specrew-speckit/scripts/shared-governance.ps1`, and the mirrored
  `.specify/extensions/specrew-speckit/scripts/` equivalents.
- Direct integration into `validate-governance.ps1` without coordination.
- Long-lived reviewer reuse, multi-reviewer fan-out/quorum, retro-informed
  review, and non-code review kinds such as plan, tasks, spec, or design review.
  The contract may preserve extension points for these future features, but
  Iteration 001 does not implement them.
- Live web search as a runtime dependency for model selection.
- Provider token quota or usage probing.
- New GitHub Actions workflow or branch-protection mutation for Proposal 197
  Iteration 001.
- CI/CD E2E implementation itself; Proposal 197 exposes the reviewer-agent hooks
  and fixtures for a downstream or companion CI/CD proposal.
- New runtime, test, build, PowerShell, npm, Python, or .NET package dependencies
  unless explicitly re-scoped through the dependency policy.
- Rung 1, PostToolUse/hook triggers, Proposal 139 foundation work, Proposal 196
  provenance work, automated live CI, new dependencies, F-184 protected file
  edits, edits to `proposals/197-continuous-co-review.md`, and commits
  containing `.squad/agents/spec-steward/history.md` remain out of scope for
  Iteration 002.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery
  window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit
  reconciliation path.
- **TG-005**: Tasks generated later MUST preserve the new-files-only constraint
  unless a human explicitly approves coordination with F-184 owners.
- **TG-006**: Review artifacts produced by this feature MUST remain auditable
  from the checkpoint baseline through gate verdict.
- **TG-007**: Security-sensitive review evidence MUST preserve enough
  provenance to govern the run while redacting secret values and excluding raw
  ambient machine state.
- **TG-008**: Contract and adapter tasks generated later MUST include
  compatibility fixture coverage for producer and consumer expectations.
- **TG-009**: Planning MUST preserve reviewer-agent contract hooks for the
  downstream CI/CD E2E proposal without absorbing CI/CD implementation into
  Iteration 001 unless explicitly re-scoped.
- **TG-010**: Review observability evidence MUST trace each run or skipped run
  from checkpoint trigger through request/invocation/result/thread/verdict, while
  preserving the redacted-evidence boundary.
- **TG-011**: Planning and implementation tasks MUST reference
  `implementation-rules.yml` and carry the approved code-rule and dependency
  policy into implementer and reviewer handoffs.
- **TG-012**: Planning MUST avoid provider-file naming collisions with F-184.
  Proposal 197 "provider adapters" mean reviewer-agent host/model adapters and
  capability records; they MUST NOT be implemented by changing F-184 repository
  provider files or by reusing ambiguous provider filenames that obscure the
  reviewer-agent domain.
- **TG-013**: Iteration 002 planning and tasks MUST preserve the completed
  Iteration 001 spine, add only the focused reviewer-definition repair scope,
  and map every new task to at least one FR/SC plus
  `implementation-rules.yml`.
- **TG-014**: Iteration 002 planning MUST make host-folder/native-agent copies
  non-authoritative and must trace runtime correctness to the composed prompt
  injected through the orchestrator/prompt-composer path.

### Traceability Map

- **Story 1** maps to FR-001, FR-002, FR-003, FR-006, FR-007, FR-008, FR-009,
  FR-010, FR-011, SEC-001, SEC-003, SEC-004, SEC-005, INT-001, INT-002,
  INT-003, INT-004, INT-005, INT-009, OPS-001, OPS-002, OPS-003, OPS-004,
  OPS-005, OPS-007, OBS-001, OBS-002, OBS-003, OBS-004, OBS-005, OBS-006,
  OBS-007, OBS-008, OBS-009, IMPL-001, IMPL-002, IMPL-003, IMPL-004,
  IMPL-005, IMPL-006, IMPL-007, and TG-011.
- **Story 2** maps to FR-002, FR-004, FR-005, FR-006, FR-007, and FR-014.
- **Story 3** maps to FR-001, FR-008, FR-009, FR-010, FR-012, FR-013, FR-015,
  FR-016, SEC-002, SEC-004, SEC-005, SEC-006, INT-006, INT-007, INT-008,
  OPS-006, OBS-003, OBS-006, OBS-009, IMPL-004, IMPL-006, IMPL-007, TG-009,
  and TG-011.
- **Iteration 002 reviewer-definition repair** maps to FR-017, FR-018, FR-019,
  FR-020, FR-021, FR-022, FR-023, SEC-007, SEC-008, SEC-009, INT-010,
  INT-011, INT-012, INT-013, OBS-010, OBS-011, OBS-012, IMPL-008, IMPL-009,
  IMPL-010, IMPL-011, TG-013, TG-014, and SC-013 through SC-018.
- **Iteration 003 always-on per-checkpoint co-review** maps to FR-024, FR-025,
  FR-026, FR-027, FR-028, FR-029, FR-030, FR-031, FR-032, and SC-019 through
  SC-023, and builds on the Iteration 001 gate (FR-006, FR-007) and
  checkpoint-trigger (FR-008) seams.

### Key Entities *(include if feature involves data)*

- **Review Contract**: The stable interface describing reviewer inputs, outputs,
  allowed side effects, and failure handling.
- **Design Context**: The package of spec, design decisions, conventions, and
  quality rules used to judge whether a diff conforms to the approved design.
- **Checkpoint Baseline**: The git reference or recorded point used to compute
  the current checkpoint change-set.
- **Change-Set**: The diff between checkpoint baseline and current worktree state
  that is sent to the reviewer.
- **Finding**: A structured reviewer result with id, location, severity, kind,
  design reference, comment, disposition, and resolution metadata.
- **Review Thread**: The durable blackboard record that contains findings,
  editor responses, rationales, state transitions, and escalation notes.
- **Gate Verdict**: The deterministic decision that a checkpoint may advance,
  must remain blocked, or requires human escalation.
- **Spawn Adapter**: A host-specific invocation wrapper that satisfies the
  host-neutral reviewer contract through a headless prompt floor.
- **Provider Capability Discovery**: The adapter capability step that detects
  installed supported headless hosts and discovers or accepts model identifiers.
- **Reviewer Selection Policy**: The policy that recommends a host/model for a
  review run based on availability, authorization, strength for review, and
  independence from the code-authoring model when available.
- **Review Request**: The canonical reviewer input contract containing the diff
  reference and exact diff content, design-context content and sources, review
  kind, schema version, allowed paths, output schema request, provider/model
  request, reviewer-instruction metadata/content hash, round context, visibility
  policy, do-policy, and run correlation id.
- **Reviewer Instruction**: The canonical Specrew-owned reviewer definition
  loaded from `scripts/internal/continuous-co-review/code-review-agent.md`.
- **Review Prompt**: The exact composed prompt sent to headless host adapters,
  including canonical instruction content, design context, exact diff, round
  context, prior findings, visibility policy, do-policy, and output contract.
- **Round Context**: The current review round number and prior findings used to
  enforce the review/fix round protocol.
- **Workspace Mutation Guard**: The pre/post source, Git, and Specrew-state
  check that invalidates a run if reviewer execution mutates the workspace.
- **Host Agent Mirror**: A best-effort copy of the canonical reviewer
  instruction into native host-folder conventions; never an authority for
  runtime correctness.
- **Spawn Invocation**: The adapter execution record containing host adapter,
  argv/command summary, timeout, workspace, capture policy, exit status, and
  normalized failure category for one reviewer attempt.
- **Review Run**: The durable audit index tying checkpoint, request, invocation,
  result, review thread, gate verdict, timestamps, provider/model provenance, and
  cleanup evidence together.
- **ReviewRunSkipped**: A structured no-op outcome for a checkpoint trigger with
  no reviewable diff.
- **Infrastructure Failure**: A structured operational failure such as missing
  host, unauthorized provider/model, timeout, malformed output, or malformed
  durable state that prevents safe gate advancement.
- **Implementation Rules Manifest**: The per-feature code-rule manifest that
  records selected craft rules, custom Proposal 197 constraints, dependency
  posture, and implementation provenance for planning, implementation, and
  review.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A design-violating checkpoint fixture produces at least one
  blocking finding with a valid design reference in 100% of required gate tests.
- **SC-002**: A checkpoint with an unresolved blocking finding is prevented from
  advancing in 100% of validator runs.
- **SC-003**: A checkpoint with only resolved blocking findings and any number of
  advisory or nit findings can advance in 100% of validator runs.
- **SC-004**: The blackboard artifact for a reviewed checkpoint contains a
  complete disposition trail for every finding in 100% of acceptance tests.
- **SC-005**: Each supported headless-floor adapter can invoke a reviewer request
  and return a parseable result or a deterministic failure status within the
  configured timeout.
- **SC-006**: The first-iteration artifact set changes no files in the protected
  F-184 surfaces.
- **SC-007**: The review loop detects out-of-band worktree changes because the
  change-set is based on git diff rather than editor-host events.
- **SC-008**: Human escalation occurs after the documented non-convergence limit
  instead of allowing indefinite editor-reviewer ping-pong.
- **SC-009**: A no-reviewable-diff checkpoint produces a durable skipped-run
  record and pass/no-op gate verdict without spawning a reviewer.
- **SC-010**: An availability failure on the primary authorized reviewer candidate
  can use at most one authorized availability fallback attempt and records
  requested and actual host/model provenance. A specifically requested model that
  is unavailable remains a hard block unless the human has already authorized the
  exact alternate candidate; it is never silently downgraded to a weaker model.
- **SC-011**: The generated implementation plan and tasks reference
  `implementation-rules.yml`, and no first-iteration task adds a new dependency
  without the required dependency-policy evidence.
- **SC-012**: Before feature closeout, the maintainer-run manual real-host
  validation records a parseable blocking finding for the canonical
  planted-design-violation fixture on each available authorized host
  (`claude -p`, `codex exec`, `copilot -p`, `cursor-agent -p`, and
  `antigravity -p`). A crash, empty output, non-finding result, or finding that
  does not name the violated design decision is not accepted as a pass.
- **SC-013**: The repository contains
  `scripts/internal/continuous-co-review/code-review-agent.md`, and review tests
  verify it includes the Proposal 145 rubric phases, workshop-decision
  conformance, claim/design trace, report-falsification, explicit per-lens
  validation, visibility policy, do-policy, and round protocol.
- **SC-014**: Prompt-composer tests prove the actual outbound adapter prompt
  includes the canonical reviewer instruction content/hash, design-context
  content, exact diff/change-set content, `round_number`, prior findings,
  visibility policy, do-policy, and `FindingsResult.v1` output instruction.
- **SC-015**: `ReviewRequest` schema/fixture validation accepts version `2.0`
  with required reviewer instruction, design-context content/sources, exact diff
  content, round context, prior findings, visibility/do policies, and output
  contract, and rejects missing required fields.
- **SC-016**: Mutation-guard tests prove source, Git, or Specrew-state mutation
  during reviewer execution invalidates the run uniformly even if host-specific
  read-only flags are unavailable.
- **SC-017**: Adapter contract tests prove host adapters receive only the
  composed prompt/transport payload and do not own reviewer rubric text or rely
  on native host-folder agent copies.
- **SC-018**: SC-012 manual validation invokes the implemented
  orchestrator/prompt-composer path and fails documentation review if it uses a
  handwritten common prompt.
- **SC-019**: With a design violation planted at an implement checkpoint, the
  per-checkpoint gate blocks advancement to the next checkpoint in 100% of
  validator runs until the finding is resolved or escalated.
- **SC-020**: Each implement checkpoint produces co-review evidence keyed to that
  checkpoint's baseline; advancing without fresh, baseline-matched evidence is
  blocked in 100% of validator runs.
- **SC-021**: A clean checkpoint (no unresolved blocking findings) advances after
  recording pass evidence with exactly one navigator run per checkpoint, so
  always-on review does not require human intervention on clean increments.
- **SC-022**: The Stop-hook navigator fires through the shared host abstraction on
  all five supported harnesses (Claude, Codex, Copilot, Cursor, Antigravity), and
  the deterministic gate floor backstops any missed or degraded hook fire, proven
  across all five harness adapters in 100% of cross-host fixture runs.
- **SC-023**: The gate-review dispatcher spawns the code reviewer only at implement
  checkpoints; a casual non-checkpoint stop and a stop at an unregistered gate
  (e.g., plan) each produce zero navigator spawns in 100% of dispatcher fixture
  runs.

## Assumptions

- The first iteration resolves the proposal default rung to **rung 2b**:
  fresh-context read-only reviewer. Rung 1 and hook-triggered review remain
  deferred.
- Checkpoint granularity is checkpoint-level and may be scoped by changed file or
  component; per-micro-edit review is intentionally avoided to reduce thrash.
- The blackboard location is `.specrew/review/inline/...` and is separate from
  Proposal 145 review artifacts, with future augmentation allowed.
- Gate severity policy is: unresolved `blocking` findings block advancement;
  `advisory` and `nit` findings are recorded but do not block.
- Non-convergence defaults to two review/fix rounds before human escalation,
  unless a later design decision changes the round cap.
- Reviewer model selection in Iteration 001 discovers installed supported hosts
  and recommends the strongest available review-class model, favoring cross-host
  or cross-model independence when available and authorized. Same-host
  fresh-context review remains valid when cross-host review is unavailable,
  unauthorized, unaffordable, or explicitly not chosen.
- Provider/model availability may be temporarily unreliable. Iteration 001 uses a
  bounded explicit fallback policy rather than ignoring availability issues or
  adding full provider-routing infrastructure. Fallback is scoped to availability
  only: a primary authorized host/model candidate is unreachable, at most one
  explicitly authorized alternate may be tried, and otherwise the run fails
  loudly. Requested-model-unavailable is a hard block, not permission to choose a
  weaker model.
- Each review run uses a fresh bounded reviewer process in Iteration 001. Reused
  long-lived reviewers, multi-reviewer fan-out, stronger Job Object/cgroup
  lifecycle isolation, retro-informed context, and plan/tasks/spec/design review
  kinds are future features captured for later proposal work.
- The review request records provider/model selection and must not spawn a paid
  or non-default reviewer without explicit user-approved configuration.
- Model IDs are volatile and are stored as data/config, not hardcoded contract
  policy. Runtime review does not depend on live web search, and Iteration 001
  does not probe provider token quota or usage.
- The reviewer is trusted for read access to repository context needed for
  review, but it is not trusted to mutate source files, Specrew state, or Git
  state during the review run.
- Review bundles and durable artifacts exclude ambient machine state and secret
  values even when the reviewer is trusted.
- Trigger default is the orchestrator git-diff checkpoint loop. PostToolUse and
  Proposal 146 refocus-based triggers are not part of this iteration.
- `validate-governance.ps1` is shared and will not be modified without explicit
  coordination.
- Proposal 197 code follows the current Specrew implementation methods and the
  feature-local implementation rules manifest rather than a separate external
  coding guideline.
- If a downstream CI/CD E2E proposal is named later, it should compose with
  Proposal 181, Live Cross-Host E2E Automation, and the Proposal 194 canary path
  rather than creating a fresh isolated E2E lane.
- Iteration 001 must ship a maintainer-facing manual-validation runbook and a
  canonical planted-design-violation fixture so real host behavior can be
  checked before feature closeout without adding an automated live cross-host CI
  harness.
- Iteration 002 does not reopen or rewrite the completed Iteration 001 spine; it
  layers the reviewer-definition repair over the existing orchestrator, request,
  adapter, blackboard, and gate seams.
- Native host-folder reviewer-agent files may help humans inspect consistency,
  but the runtime must remain correct when those host-specific files are absent,
  stale, ignored, or unsupported.
- Latest remote `main` synchronization is a required preparatory step before
  Iteration 002 implementation touches runtime code.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Spec Steward for Specrew, accountable for preserving Proposal
  197 scope, resolving proposal open questions into assumptions, and blocking
  drift into F-184 surfaces.
- **Iteration Facilitator**: Planner/iteration facilitator for Specrew, accountable
  for converting this specification into an additive Iteration 001 plan without
  starting deferred rungs.
- **Capacity Model**: Proposal estimate is 13-21 SP overall. Iteration 001 is the
  host-neutral spine and read-only rung 2b slice only; planning must size it
  separately before implementation.
- **Drift Signals**: Any task that edits protected host-runtime, hook, provider,
  registry, refocus, or shared governance files is drift. Any implementation that
  relies on PostToolUse for Iteration 001 is drift. Any reviewer that writes
  source files is drift.
- **Human Oversight Points**: Human approval is required before planning, before
  any protected-surface coordination, before changing the rung default, and before
  integrating with shared governance validators.
- **Iteration 003 authorization (2026-06-20)**: The maintainer authorized
  always-on per-checkpoint co-review and coordinated integration with the
  F-184-protected shared boundary-advance surface, satisfying the
  protected-surface and shared-governance human-oversight points for Iteration
  003 scope and planning.
