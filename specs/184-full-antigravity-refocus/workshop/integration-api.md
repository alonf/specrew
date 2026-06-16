# Integration API Lens

## Decision

Antigravity integration uses the same Specrew dispatcher contract after host
normalization, but the Antigravity hook event/output contract is host-specific.
Use `PreInvocation` as the primary Antigravity carrier for bootstrap and B3
refocus injection, keep `Stop` for handover, and do not emit `injectSteps` from
`PostToolUse` unless a valid Antigravity tool-hook output schema is separately
proven.

## Contract Sequence

```text
agy runtime
    |
    | workspace .agents/hooks.json
    | named hook definition: specrew-refocus
    v
+---------------------------+
| Antigravity hook event    |
| PreInvocation / Stop      |
+-------------+-------------+
              |
              | stdin JSON:
              | conversationId, transcriptPath,
              | workspacePaths, invocationNum
              v
+---------------------------+
| specrew-hook-launch.ps1   |
| per-machine launcher      |
+-------------+-------------+
              |
              v
+---------------------------+
| SpecrewHookDispatcher     |
| -HostKind antigravity     |
+-------------+-------------+
              |
       +------+--------------------+
       |                           |
       v                           v
PreInvocation                  Stop
bootstrap + B3                 handover save
injectSteps output             decision=allow output
```

## Producers And Consumers

- Producer: Antigravity CLI (`agy`) hook runtime.
- Consumer: Specrew per-machine hook launcher and project dispatcher.
- Contract owner: Specrew owns the deployed hook definition and dispatcher
  command shape; Antigravity owns event names, input JSON, and allowed output
  schemas.

## Event Mapping

- `PreInvocation` maps to Specrew `PreInvocation` and carries bootstrap plus B3
  refocus injection through Antigravity `injectSteps`.
- `Stop` maps to Specrew `Stop` and carries handover through the existing
  handover provider path; empty/allow output is shaped as `{ "decision":
  "allow" }`.
- `PreToolUse` and `PostToolUse` are real Antigravity events and include
  `conversationId`, `stepIdx`, `toolCall`, `transcriptPath`, and
  `workspacePaths`, but they are not selected as refocus injection carriers in
  this feature.
- `PostInvocation` accepts `injectSteps` and can inject into a follow-on
  invocation, but it is not the primary carrier because it deliberately creates
  another invocation cycle.

## Compatibility And Versioning

- The hook config remains workspace `.agents/hooks.json` using a named
  definition so user hooks can be preserved.
- Specrew must update the Antigravity host manifest rather than branching in
  deployer code.
- `conversationId` is the session identity for per-session state and is stable
  across `agy --conversation` resume.
- F-184 must update the previous bounded-support claim: Antigravity has
  `PostToolUse`, but `PostToolUse` is not injection-safe with the current
  `injectSteps` output shape.

## Error And Retry Behavior

- Hook failures remain fail-open for the host session.
- Invalid Antigravity output schemas must be avoided. The spike proved
  `injectSteps` from `PostToolUse` is rejected with `unknown field
  "injectSteps"` and can deny the tool call.
- If Antigravity input JSON is malformed or missing the real session id,
  Specrew must fail loud through existing warnings and avoid false full-refocus
  claims.

## Validation Obligations

- Real `agy` run proves `PreInvocation` hook firing and `injectSteps`
  injection.
- Real `agy` run proves `Stop` hook firing and handover preservation.
- Real `agy --conversation <id>` run proves `conversationId` stability across
  exit and re-entry.
- Real `agy` run proves B3 injects only on true boundary changes through the
  selected Antigravity carrier.
- Regression evidence records that `PostToolUse` fires but is not used for
  `injectSteps` until a valid schema is proven.

## Evidence

See
`file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/workshop/integration-api-hook-spike.md`
for the real-host hook experiment.

## Confirmation

The human accepted the experiment result and the corrected integration decision:
now that Antigravity hook behavior is known, proceed with `PreInvocation` as the
primary B2/B3 carrier, `Stop` for handover, and `PostToolUse` as observed but
not injection-safe for refocus payloads.
