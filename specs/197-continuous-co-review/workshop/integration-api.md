# Integration-API Lens Workshop

## Lens

- **Lens ID**: `integration-api`
- **Depth**: full
- **Confirmation**: human-confirmed
- **Confirmation scope**: lens-question

## Contract Sequence

```text
Integration contract sequence

+----------------------+       ReviewRequest v1        +-----------------------+
| Orchestrator         |------------------------------->| Provider Adapter      |
| owns contract build  |  local file/stdin + safe argv  | translates host CLI   |
+----------+-----------+                                +-----------+-----------+
           |                                                        |
           |                                                        v
           |                                           +------------------------+
           |                                           | Fresh Reviewer Process |
           |                                           | emits stdout JSON      |
           |                                           +-----------+------------+
           |                                                       |
           | FindingsResult v1 OR InfrastructureFailure v1         |
           +<------------------------------------------------------+
           |
           | writes ReviewThread v1 + GateVerdict v1
           v
+-------------------------------+       validates        +--------------------+
| .specrew/review/inline/run-id |----------------------->| Gate Validator     |
| durable contract artifacts    |                        | pass/block/unsafe  |
+-------------------------------+                        +--------------------+

Provider/model selection path

+------------------+     discover installed hosts      +-------------------+
| Specrew Adapter  |----------------------------------->| claude / codex    |
| Registry/Config  |                                    | copilot / cursor  |
|                  |<-----------------------------------| antigravity       |
+--------+---------+     capabilities / configured IDs  +-------------------+
         |
         | present available authorized choices + recommendation
         v
+------------------+
| Human Approval   |
| host/model/cost  |
+------------------+
```

## Agenda Raised

- What integration style should connect the orchestrator, provider adapters, fresh reviewer process, durable artifacts, and gate validator?
- What owns the contracts and how are schema versions handled?
- Are reviewer operations synchronous, asynchronous, streaming, retried, or replayable?
- What is the error envelope for findings, infrastructure failures, malformed output, and unsafe gate state?
- When and how does the human choose reviewer AI host/model?
- How are model catalogs discovered without hardcoding volatile model IDs?
- What compatibility fixtures prove producer and consumer expectations?

## Decisions and Agreement

Iteration 001 uses a local, host-neutral, contract-first integration style. The orchestrator creates a versioned review request, invokes a provider adapter through safe argv or equivalent APIs, accepts only stdout JSON as the reviewer result, and writes durable blackboard/gate artifacts. The first slice does not use REST, GraphQL, gRPC, queues, daemons, streaming review, or in-session subagent APIs as its integration contract.

Specrew owns the stable contracts and versioning policy. Provider adapters translate host-specific CLI behavior into Specrew-owned shapes rather than defining their own result protocols. The versioned contract set includes:

- `ReviewRequest`
- `FindingsResult`
- `ReviewThread`
- `GateVerdict`
- `InfrastructureFailure`

Unknown major versions, malformed required fields, and malformed durable gate/blackboard state are unsafe and blocking. Additive optional fields are allowed inside a compatible version.

Reviewer runs are synchronous and bounded in Iteration 001. The orchestrator starts one fresh reviewer process, waits until completion or timeout, parses stdout once, writes durable artifacts, and returns pass/block/failure. There is no automatic retry by default because retry can duplicate cost and hide provider instability. A replay or rerun creates a new run ID and provenance record rather than overwriting old evidence.

The error envelope keeps successful findings separate from infrastructure failures. Timeout, nonzero exit, empty stdout, invalid JSON, schema mismatch, missing provider, command invocation failure, or unavailable requested model becomes `InfrastructureFailure`. Malformed durable blackboard or gate state becomes unsafe `GateVerdict`. None of these are treated as "no findings."

Provider/model selection happens before the first review run for a checkpoint, after Specrew computes the change-set and before invoking the adapter. Specrew discovers installed headless hosts for Codex, Claude, Copilot, Cursor, and Antigravity, intersects them with allowed project/run configuration, and presents available authorized choices when selection is missing, non-default, paid, external, or newly added.

The reviewer recommendation should favor the strongest available review-class model and prefer cross-host or cross-model independence when available and authorized. If the code-authoring agent is Claude and a strong Codex/GPT-family reviewer is available and authorized, recommend Codex/GPT-family review; if the authoring agent is Codex/GPT-family and a Claude Opus-class reviewer is available and authorized, recommend Claude. Same-host fresh-context review remains valid when cross-host review is unavailable, unaffordable, unauthorized, or explicitly not chosen.

Model names are volatile, so model IDs are data/config rather than hardcoded contract policy. Adapter capability discovery uses this order:

1. Explicit project configuration or allowlist.
2. Official host CLI model-list command when available.
3. Reliable CLI help/introspection where available.
4. Human-entered model ID.

Runtime review does not depend on live web search. Web research can be used by maintainers when updating adapter defaults or documentation, but not as a required runtime dependency. Iteration 001 does not inspect remaining token quota or account usage. The human authorizes the chosen host/model/cost/effort level. If the requested model is unavailable, Specrew blocks or asks for new authorization rather than silently downgrading to a cheaper model.

## Compatibility Test Floor

Iteration 001 planning should include producer/consumer fixtures for:

- valid `ReviewRequest`
- valid `FindingsResult`
- timeout/nonzero/invalid-json `InfrastructureFailure`
- valid `ReviewThread`
- `GateVerdict` states for pass, blocked, and unsafe

Each headless-floor adapter must prove it can accept the request contract and return either a valid result or a deterministic infrastructure failure.

## Iteration 002 Send-Back Addendum: Reviewer Definition Integration Contract

### Reviewer-Definition Integration Sequence

```text
Reviewer-definition integration sequence

+---------------------------+
| Canonical instruction     |
| code-review-agent.md      |
| Specrew-owned Markdown    |
+-------------+-------------+
              |
              | load + hash
              v
+---------------------------+       ReviewRequest.v2        +--------------------------+
| ReviewerInstructionSource |------------------------------>| ReviewRequestBuilder     |
| owns canonical text       | instruction metadata/content  | owns structured request  |
+-------------+-------------+                               +------------+-------------+
              |                                                          |
              |                                                          | structured fields:
              |                                                          | design_context.content
              |                                                          | diff/change_set content
              |                                                          | round_number
              |                                                          | prior_findings
              |                                                          | visibility_policy
              |                                                          | do_policy
              |                                                          v
              |                                             +--------------------------+
              +-------------------------------------------->| ReviewPromptComposer     |
                            canonical instruction content   | owns rendered prompt     |
                                                            +------------+-------------+
                                                                         |
                                                                         | complete prompt string
                                                                         v
+---------------------------+       safe argv/stdin/prompt   +--------------------------+
| Host Adapter Edge         |<-------------------------------| ReviewerExecutionEngine  |
| Claude/Codex/Copilot/     |                                | owns invocation + guard  |
| Cursor/Antigravity/Fixture|                                +------------+-------------+
+-------------+-------------+                                             |
              |                                                           | isolated workspace
              | provider stdout/stderr/exit                               | pre/post mutation scan
              v                                                           v
+---------------------------+                                +--------------------------+
| FindingsResult.v1 OR      |------------------------------->| ResultNormalizer + Gate  |
| InfrastructureFailure.v1  |                                | owns valid/invalid state |
+---------------------------+                                +--------------------------+

Non-authoritative mirror side path:

+---------------------------+        copy for consistency       +-------------------------+
| code-review-agent.md      |---------------------------------->| .github/.claude/.agents |
| canonical source          |                                   | host mirror folders      |
+---------------------------+                                   +-------------------------+
Runtime correctness does not depend on host auto-loading these mirrors.
```

### Send-Back Integration Agenda

- Should the send-back introduce `ReviewRequest.v2` as the required request contract for reviewer-definition
  injection, while keeping `FindingsResult.v1` as the output contract?
- Which component owns each contract/source seam, and how do host adapters stay transport-only?
- Should reviewer-definition execution remain synchronous and bounded, with explicit reruns instead of silent
  retry?
- How should replay, run identity, and `prior_findings` prevent unresolved blocking findings from disappearing?
- Which failures become `InfrastructureFailure.v1`, and which become invalid review execution or unsafe gate
  state?
- Which producer/consumer fixtures prove schema evolution and actual prompt delivery across all five adapters?

### Decisions and Agreement

Iteration 002 introduces `ReviewRequest.v2` as the required request contract for reviewer-definition injection
and keeps `FindingsResult.v1` as the only valid stdout output contract. `ReviewRequest.v2` owns required fields
for reviewer instruction source metadata/content hash, design context content and sources, exact diff or selected
change-set payload, `round_number`, `prior_findings`, `visibility_policy`, `do_policy`, and an output contract
declaration requiring `FindingsResult.v1`. `ReviewRequest.v1` remains an Iteration 001 artifact shape; unknown
major request versions block as infrastructure/contract failures, while additive optional `v2` fields are allowed
only when the required semantic fields remain present.

Reviewer semantics are centrally owned and must not leak into host adapters. `ReviewerInstructionSource` owns
reading the canonical `scripts/internal/continuous-co-review/code-review-agent.md` and producing source/hash
metadata. `ReviewRequestBuilder` owns the structured `ReviewRequest.v2` data. `ReviewPromptComposer` owns
rendering the complete outbound prompt from the canonical instruction plus `ReviewRequest.v2` fields.
`ReviewerExecutionEngine` owns isolated workspace setup, adapter invocation, timeout handling, mutation guard,
stdout/stderr/exit capture, and cleanup. Host adapters own only command path, argv/stdin/prompt flag shape,
host-supported read-only or permission flags, and raw execution-result normalization; they do not own Proposal
145 rubric wording, visibility policy wording, do-policy wording, prior-finding verification semantics, durable
artifact writes, or gate verdicts.

Reviewer-definition execution remains synchronous and bounded. Each run builds `ReviewRequest.v2`, composes the
complete injected prompt, creates an isolated review workspace, captures the pre-review baseline, invokes exactly
one host adapter process with the composed prompt, captures stdout/stderr/exit/timeout, captures the post-review
baseline, classifies output as `FindingsResult.v1` or `InfrastructureFailure.v1`, classifies any workspace
mutation as invalid review execution, writes durable evidence through orchestrator-owned code, and discards the
isolated workspace unless debug preservation is explicitly enabled. There is no silent automatic retry by
default; a manual rerun or fix-verification round creates a new `run_id` and preserves old evidence.

Reruns are append-only replayable evidence, not idempotent overwrites. Each invocation receives a unique `run_id`
that links the `ReviewRequest.v2` snapshot/hash, composed prompt evidence or approved non-secret summary,
selected diff/change-set hash, adapter/host/model metadata, `FindingsResult.v1` or `InfrastructureFailure.v1`,
mutation-guard result, and gate verdict/dispositions. For round 2, `prior_findings` contains prior blocking
findings requiring verification, including finding id, source run id, violated design/spec reference, relevant
file/location when available, and expected resolution evidence or disposition state. The reviewer instruction
must require verification of each prior blocking finding and must not silently drop unresolved prior findings.

The failure envelope separates infrastructure failures from invalid review execution and unsafe gate states.
Missing host executable, unavailable requested model, command invocation failure, timeout, nonzero exit without
valid findings, empty stdout, invalid JSON, schema mismatch, unsupported required host capability, unsupported
required invocation shape, or host-specific prompt flag ambiguity that prevents safe execution becomes
`InfrastructureFailure.v1`. Missing canonical instruction in the composed prompt, incomplete prompt semantics,
non-`FindingsResult.v1` reviewer output, reviewer mutation in the isolated workspace, malformed durable
blackboard/gate artifacts, or a prior blocking finding disappearing without resolved/deferred/escalated
disposition becomes invalid review execution or unsafe gate state. If a host lacks a reliable read-only flag,
that limitation is recorded as unsupported capability; policy/do-policy and the isolated mutation guard still
apply, and the adapter does not claim host-enforced read-only.

### Compatibility Test Floor

Producer-side fixtures must include a valid `ReviewRequest.v2` with reviewer instruction metadata/hash, design
context content and sources, exact diff/change-set content, `review_round.round_number`, `prior_findings`,
`visibility_policy`, `do_policy`, and `output_contract = FindingsResult.v1`. Invalid fixtures must cover missing
reviewer instruction metadata, missing design context content, missing diff/change-set content, missing round
number, missing prior findings on a verification round, missing policies, and unknown major request version.

Composer and adapter consumer fixtures must capture the actual outbound prompt and assert that it contains the
rubric, design context, diff, round, prior findings, and policies. The fixture adapter full-path test must prove
request to composed prompt to adapter input capture to `FindingsResult.v1` to gate verdict. Infrastructure
failure fixtures must cover missing host, timeout, nonzero exit, empty stdout, invalid JSON, schema mismatch,
requested model unavailable, and unsupported required invocation shape. A mutation fixture must prove a reviewer
process changing an isolated workspace file is captured by the mutation guard and produces an invalid/unsafe
result rather than a pass.

Claude, Codex, Copilot, Cursor, and Antigravity adapter fixtures each must prove they receive a complete
composed prompt, keep transport shape at the edge, return `FindingsResult.v1` or deterministic
`InfrastructureFailure.v1`, and assert host read-only support when available or explicitly mark it unsupported.
