# Component Design Lens Workshop

## Lens

- **Lens ID**: `component-design`
- **Depth**: full
- **Confirmation**: human-confirmed
- **Confirmation scope**: lens-question

## Decision Agenda

- What decomposition vocabulary should bind the component map for Iteration 001?
- What responsibilities belong together, and what should stay separate?
- Which dependencies point inward versus outward?
- Where should reviewer visibility, temporary request bundles, cleanup, and concurrency be owned?
- Where should external JSON schemas be decoupled from internal runtime models?
- What extension mechanism fits provider adapters without overbuilding Iteration 001?

## Agreed Component Direction

Iteration 001 uses a layered/modular component design with a provider adapter seam. Stable review contracts sit
inward, provider-specific command adapters sit outward, and the orchestrator depends on contracts plus interfaces
rather than provider command details. Reviewer visibility is policy plus review bundle only in this first slice;
hard OS/filesystem sandboxing remains deferred future hardening. External JSON schemas/DTOs remain decoupled from
internal runtime models, and concrete request bundles are per-run immutable artifacts that are not reused.

Temporary execution workspace lifecycle is owned by `ReviewRunWorkspaceManager`, which creates unique per-run
workspaces, coordinates bundle placement, owns cleanup, preserves workspaces only under explicit debug mode, and
prevents concurrent run collisions across worktrees and within a single worktree. Durable review evidence is
written separately by `ReviewBlackboardWriter` under `.specrew/review/inline/<run-id>/...`.

Provider extensibility uses composition plus a static in-repo provider adapter registry selected by explicit
configuration, with a capability-discovery and human-authorization path for host/model selection. Full dynamic
plugin discovery, multi-reviewer fan-out, quorum policy, quota probing, and hard sandboxing are future features,
not Iteration 001 requirements.

## Component Map

```text
+--------------------------------------------------------------------------------+
| Orchestration Layer                                                            |
|                                                                                |
|  CheckpointReviewOrchestrator                                                  |
|      |                                                                         |
|      v                                                                         |
|  CheckpointDiffProvider                                                        |
|      |                                                                         |
|      v                                                                         |
|  ReviewRequestBuilder                                                          |
+------+-------------------------------------------------------------------------+
       |
       +------------------------------+
       |                              |
       v                              v
+----------------------------+   +-----------------------------------------------+
| Contract Layer             |   | Context Packaging Layer                        |
|                            |   |                                               |
|  ReviewContractSchemas     |   |  DesignContextCollector                       |
|  ReviewerProviderConfig    |   |  ReviewVisibilityPolicyBuilder                |
|                            |   |  ReviewBundleBuilder                          |
+-------------+--------------+   +--------------------+--------------------------+
              |                                       |
              +-------------------+-------------------+
                                  |
                                  v
+--------------------------------------------------------------------------------+
| Execution Layer                                                               |
|                                                                                |
|  ReviewRunWorkspaceManager                                                     |
|      |                                                                         |
|      v                                                                         |
|  ReviewProviderCatalog                                                         |
|      |                                                                         |
|      v                                                                         |
|  ProviderCapabilityDiscovery                                                   |
|      |                                                                         |
|      v                                                                         |
|  ReviewerSelectionPolicy                                                       |
|      |                                                                         |
|      v                                                                         |
|  HumanAuthorizationGate                                                        |
|      |                                                                         |
|      v                                                                         |
|  ReviewerExecutionEngine                                                       |
|      |                                                                         |
|      v                                                                         |
|  ProviderSpawnAdapterRegistry                                                  |
|      |                                                                         |
|      v                                                                         |
|  ProviderSpawnAdapter                                                          |
|      |                                                                         |
|      +--> ClaudePromptAdapter                                                  |
|      +--> CodexExecAdapter                                                     |
|      +--> CopilotPromptAdapter                                                 |
|      +--> CursorAgentPromptAdapter                                             |
|      +--> AntigravityPromptAdapter                                             |
+------+-------------------------------------------------------------------------+
       |
       v
+--------------------------------------------------------------------------------+
| Result and Gate Layer                                                          |
|                                                                                |
|  ReviewResultNormalizer                                                        |
|      |                                                                         |
|      v                                                                         |
|  InlineReviewGateEvaluator                                                     |
+------+-------------------------------------------------------------------------+
       |
       v
+--------------------------------------------------------------------------------+
| Persistence Layer                                                              |
|                                                                                |
|  ReviewBlackboardWriter                                                        |
+--------------------------------------------------------------------------------+
```

## Named Responsibilities

### Orchestration Layer

- `CheckpointReviewOrchestrator` — owns checkpoint review-run lifecycle: start, package, execute, normalize,
  evaluate, persist, and return pass/block/failure.
- `CheckpointDiffProvider` — computes the bounded git diff/change-set from the checkpoint baseline without
  owning provider details or gate policy.
- `ReviewRequestBuilder` — assembles the explicit reviewer request payload from diff, review kind, visibility
  policy, design context, and provider/model configuration.

### Contract Layer

- `ReviewContractSchemas` — owns stable external JSON schemas for request, result, finding, provenance,
  execution failure, and gate verdict.
- `ReviewerProviderConfig` — owns explicit provider/model/cost authorization shape and validation before any
  paid or non-default reviewer process can spawn.

### Context Packaging Layer

- `DesignContextCollector` — gathers approved spec/workshop/rules excerpts into bounded reviewer context.
- `ReviewVisibilityPolicyBuilder` — records allowed paths, forbidden paths, and review-scope policy as contract
  evidence; it does not claim hard filesystem isolation.
- `ReviewBundleBuilder` — writes a per-run immutable request bundle that feeds the fresh reviewer process;
  bundles are not reused across runs.

### Execution Layer

- `ReviewRunWorkspaceManager` — creates unique per-run temp workspaces, coordinates bundle placement, owns
  cleanup, preserves workspaces only under explicit debug mode, and prevents concurrent run collisions.
- `ReviewProviderCatalog` — static in-repo catalog of supported adapter types, allowed provider/model
  configuration, default/fallback policy, and cost/authorization metadata.
- `ProviderCapabilityDiscovery` — checks installed headless hosts and discovers model IDs using explicit
  config/allowlists first, official model-list commands where available, reliable CLI help/introspection where
  available, or human-entered model IDs.
- `ReviewerSelectionPolicy` — recommends the strongest available review-class model and favors cross-host or
  cross-model reviewer independence when available and authorized, without hardcoding volatile model IDs.
- `HumanAuthorizationGate` — obtains explicit user approval for non-default, paid, external, or newly added
  provider/model use and blocks rather than silently downgrading unavailable requested models.
- `ReviewerExecutionEngine` — runs one fresh-context read-only-by-contract reviewer process, preferably with
  cwd set to the review bundle directory, enforces timeout, and captures exit/stdout/stderr.
- `ProviderSpawnAdapterRegistry` — static in-repo registry that selects exactly one configured provider adapter
  for Iteration 001 after capability discovery and authorization.
- `ProviderSpawnAdapter` — stable adapter interface that maps a review bundle and config to a provider command
  invocation.
- `ClaudePromptAdapter` — command adapter for `claude -p`.
- `CodexExecAdapter` — command adapter for `codex exec`.
- `CopilotPromptAdapter` — command adapter for `copilot -p`.
- `CursorAgentPromptAdapter` — command adapter for `cursor-agent -p`.
- `AntigravityPromptAdapter` — command adapter for antigravity `-p`.

### Result and Gate Layer

- `ReviewResultNormalizer` — validates stdout JSON and maps timeout, nonzero exit, empty output, invalid JSON,
  malformed findings, or unknown blocking disposition into structured failures/findings.
- `InlineReviewGateEvaluator` — applies deterministic blocking rules and decides whether the checkpoint can
  advance.

### Persistence Layer

- `ReviewBlackboardWriter` — writes durable review-thread/findings/verdict/provenance artifacts under
  `.specrew/review/inline/<run-id>/...`; it may store request summaries/hashes rather than the entire temporary
  bundle.

## Key Flow

```text
checkpoint boundary
  -> CheckpointReviewOrchestrator
  -> CheckpointDiffProvider
  -> ReviewRequestBuilder
  -> ReviewContractSchemas + ReviewerProviderConfig
  -> DesignContextCollector + ReviewVisibilityPolicyBuilder + ReviewBundleBuilder
  -> ReviewRunWorkspaceManager
  -> ReviewProviderCatalog
  -> ProviderCapabilityDiscovery
  -> ReviewerSelectionPolicy
  -> HumanAuthorizationGate
  -> ReviewerExecutionEngine
  -> ProviderSpawnAdapterRegistry
  -> ProviderSpawnAdapter
  -> one provider-specific adapter
  -> ReviewResultNormalizer
  -> InlineReviewGateEvaluator
  -> ReviewBlackboardWriter
  -> pass/block/failure returned to checkpoint flow
```

## Binding Component Decisions

- Decomposition vocabulary is layered/modular with an adapter seam.
- Dependency direction is stable contract inward, provider adapters outward.
- Reviewer visibility is policy plus review bundle only in Iteration 001; hard sandboxing is deferred.
- External JSON schemas/DTOs are decoupled from internal runtime models.
- Temp bundle lifecycle is owned by `ReviewRunWorkspaceManager`; bundles are per-run, immutable, cleanup-owned,
  and not reused.
- Extension mechanism is composition plus a static provider adapter registry selected by config, capability
  discovery, reviewer-selection policy, and human authorization.
- Provider/model selection favors the strongest available review-class model and cross-host/cross-model
  independence when available and authorized; model IDs remain data/config because model catalogs are volatile.
- Iteration 001 does not probe provider token quota or usage. If a requested provider/model is unavailable, the
  run blocks or requests new authorization rather than silently downgrading.

## Iteration 002 Send-Back Addendum: Reviewer Definition Components

The reviewer-definition repair preserves the layered/modular design and adds explicit components around reviewer
instruction ownership, prompt composition, round context, and mutation detection. Reviewer semantics stay in core
definition/context/prompt components; host adapters remain transport-only edges. The canonical reviewer
instruction is a Markdown runtime artifact, `scripts/internal/continuous-co-review/code-review-agent.md`, and
host-folder copies are deployment mirrors only.

```text
Proposed component map — reviewer-definition repair

+----------------------------------------------------------------------------------+
| Orchestration Layer                                                              |
|                                                                                  |
|  CheckpointReviewOrchestrator                                                    |
|      |                                                                           |
|      +--> CheckpointDiffProvider                                                 |
|      |                                                                           |
|      +--> ReviewRoundContextBuilder                                              |
|      |                                                                           |
|      v                                                                           |
|  ReviewRequestBuilder                                                            |
+------+---------------------------------------------------------------------------+
       |
       +-------------------------------+----------------------------------+
       |                               |                                  |
       v                               v                                  v
+-----------------------------+  +--------------------------------+  +----------------------+
| Contract Layer              |  | Definition + Context Layer      |  | Policy Layer         |
|                             |  |                                |  |                      |
|  ReviewRequestSchema.v2     |  |  ReviewerInstructionSource     |  |  ReviewPolicyBuilder |
|  FindingsResultSchema.v1    |  |  DesignContextCollector        |  |  ReadOnlyPolicy      |
|  InfrastructureFailure      |  |  ReviewPromptComposer          |  |  VisibilityPolicy    |
|  MutationViolationEvidence  |  +---------------+----------------+  |  DoPolicy            |
+-------------+---------------+                  |                   +----------+-----------+
              |                                  |                              |
              +----------------------+-----------+------------------------------+
                                     |
                                     v
+----------------------------------------------------------------------------------+
| Workspace + Execution Layer                                                      |
|                                                                                  |
|  ReviewRunWorkspaceManager                                                       |
|      |                                                                           |
|      v                                                                           |
|  WorkspaceMutationGuard                                                          |
|      |                                                                           |
|      v                                                                           |
|  ReviewerExecutionEngine                                                         |
|      |                                                                           |
|      v                                                                           |
|  ReviewerHostAdapterRegistry                                                     |
|      |                                                                           |
|      +--> ReviewerHostAdapter: ClaudePrompt                                      |
|      +--> ReviewerHostAdapter: CodexExec                                         |
|      +--> ReviewerHostAdapter: CopilotPrompt                                     |
|      +--> ReviewerHostAdapter: CursorAgentPrompt                                 |
|      +--> ReviewerHostAdapter: AntigravityPrompt                                 |
+------+---------------------------------------------------------------------------+
       |
       v
+----------------------------------------------------------------------------------+
| Result + Gate + Persistence Layer                                                 |
|                                                                                  |
|  ReviewResultNormalizer                                                          |
|      |                                                                           |
|      v                                                                           |
|  InlineReviewGateEvaluator                                                       |
|      |                                                                           |
|      v                                                                           |
|  ReviewBlackboardWriter                                                          |
|      |                                                                           |
|      v                                                                           |
|  HostAgentMirrorDeployer                                                         |
|  (copy code-review-agent.md to managed host folders; not runtime execution path)  |
+----------------------------------------------------------------------------------+
```

### Added Responsibilities

- `ReviewRoundContextBuilder` — supplies `round_number` and `prior_findings`, including prior blocking findings
  and claimed resolutions, without deciding the gate verdict.
- `ReviewRequestSchema.v2` — owns the structured input contract fields for design context content, exact diff
  content, round number, prior findings, visibility policy, do-policy, and reviewer-instruction metadata/content
  hash.
- `MutationViolationEvidence` — records pre/post mutation evidence when a reviewer writes in the isolated
  workspace.
- `ReviewerInstructionSource` — reads the canonical reviewer instruction and exposes its content/hash to request
  and prompt composition; it does not depend on host-folder auto-load behavior.
- `ReviewPromptComposer` — renders the complete host prompt from the canonical reviewer definition,
  `ReviewRequest.v2`, design context, diff, round context, prior findings, visibility policy, and do-policy.
- `ReviewPolicyBuilder`, `ReadOnlyPolicy`, `VisibilityPolicy`, and `DoPolicy` — construct and carry explicit
  review-only and supplied-context-only constraints.
- `WorkspaceMutationGuard` — captures pre/post isolated-workspace baselines, records mutation diffs, and
  invalidates mutated review results.
- `HostAgentMirrorDeployer` — copies the canonical reviewer instruction into managed host folders for
  consistency and discoverability only; it is not part of the required runtime execution path.

### Binding Send-Back Component Decisions

- Responsibility boundaries stay separated by reason-to-change: instruction source, structured request builder,
  prompt composer, round context, mutation guard, host adapters, and host mirror deployment are distinct.
- Dependencies remain inward to contracts and policies, with host-specific behavior limited to the
  adapter/catalog seam. The prompt composer and contracts stay host-neutral.
- The repair uses PowerShell function/module seams plus explicit Markdown/JSON artifacts. It does not add dynamic
  plugins, generated code, provider SDKs, or a host-native agent-file execution dependency.
- `ReviewRequest.v2` is the structured input contract; `FindingsResult.v1` remains the only valid reviewer stdout
  contract; prompt text is generated from those fields and is not the source-of-truth contract.
- Adapter extension remains convention-based adapter files plus catalog/config. The centralized reviewer
  definition applies to every host through prompt injection.

### Send-Back Key Flow

```text
checkpoint boundary
  -> CheckpointReviewOrchestrator
  -> CheckpointDiffProvider
  -> ReviewRoundContextBuilder
  -> DesignContextCollector + ReviewPolicyBuilder
  -> ReviewerInstructionSource
  -> ReviewRequestBuilder (ReviewRequest.v2)
  -> ReviewPromptComposer (complete injected host prompt)
  -> ReviewRunWorkspaceManager (isolated workspace)
  -> WorkspaceMutationGuard (pre snapshot)
  -> ReviewerExecutionEngine
  -> ReviewerHostAdapterRegistry
  -> one ReviewerHostAdapter
  -> WorkspaceMutationGuard (post snapshot)
  -> ReviewResultNormalizer
  -> InlineReviewGateEvaluator
  -> ReviewBlackboardWriter
```
