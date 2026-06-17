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
