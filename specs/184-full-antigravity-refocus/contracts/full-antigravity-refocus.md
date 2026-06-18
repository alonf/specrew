# Contract: Full Antigravity Refocus

## Hook Carrier Contract

| Antigravity Event | Specrew Use | Output Contract |
| --- | --- | --- |
| `PreInvocation` | Bootstrap and B3 refocus injection | `injectSteps` only when Specrew has content to inject. |
| `Stop` | Rolling handover save | Antigravity decision JSON, preserving F-183 behavior. |
| `PostToolUse` | Observed but not used for refocus injection | MUST NOT emit `injectSteps` in F-184. |
| `PostInvocation` | Observed, not default carrier | MAY remain unused unless later evidence approves it. |

## Split-Guard Contract

The discovery spike must write evidence rows for these triggers:

| Trigger | Required Evidence |
| --- | --- |
| `fresh-boundary-cursor` | Demonstrates the cursor used by B3 is available before the model turn. |
| `exactly-once-b3` | Demonstrates existing dedupe/breaker can prevent duplicate B3 injection. |
| `bounded-host-model` | Demonstrates no non-Antigravity shared host contract change is required. |

Any `FAIL` value blocks implementation beyond discovery and requires a human
split/defer decision.

## State Contract

- `conversationId` is the Antigravity session identity.
- The sanitized session id is the only valid state key when `conversationId` is
  present.
- `unknown` is not a valid Antigravity state key when a real id exists.
- `SessionStateAccessor` owns state read/write.

## Documentation Contract

Docs must reach host-level content parity before release, but support status is
evidence-gated:

- before real-host proof: candidate / pending validation / machine-local
- after beta evidence: beta
- after stable release validation: stable / verified

## Release Contract

F-184 stacks on F-183. The next beta and stable releases cover the combined
F-183 + F-184 Antigravity support. Stable promotion is blocked until:

- real-host `agy` evidence passes
- beta install validation passes
- legacy upgrade/config migration validation passes
