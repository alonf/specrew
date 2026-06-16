# Integration API Hook Spike

## Status

Evidence captured. This is not the final `integration-api` lens decision.

## Environment

- Date: 2026-06-17
- Host: Google Antigravity CLI via `agy`
- Probe workspace: `C:\Temp\agy-hook-probe`
- Injection probe workspace: `C:\Temp\agy-inject-probe`
- Primary event-fire conversation:
  `e14810e4-7f19-4533-96ea-eccc81d28b2d`

## Hook Configuration Shape Observed

Antigravity loaded `.agents/hooks.json` from the workspace.

Working non-tool event shape:

```json
{
  "probe-turn-events": {
    "enabled": true,
    "PreInvocation": [
      {
        "type": "command",
        "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File C:/Temp/agy-hook-probe/hooks/log-hook.ps1 PreInvocation",
        "timeout": 20
      }
    ]
  }
}
```

Working tool event shape:

```json
{
  "probe-tool-events": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File C:/Temp/agy-hook-probe/hooks/log-hook.ps1 PreToolUse",
            "timeout": 20
          }
        ]
      }
    ]
  }
}
```

Note: quoted `-File "C:/..."` paths failed when invoked by Antigravity; the
unquoted path worked because the probe path had no spaces. Specrew production
uses `launcher-encoded`, which avoids this quoting problem.

## Event Fire Results

Antigravity loaded 2 named hooks and 5 total handlers. The following event
handlers fired in a real `agy --print` run that used `list_dir`:

```text
PreInvocation
PostToolUse
PreToolUse
PostToolUse
PostInvocation
PostToolUse
PreInvocation
PostInvocation
Stop
```

The clean focused tool-call run produced:

```text
PreInvocation  conversationId=e14810e4-7f19-4533-96ea-eccc81d28b2d invocationNum=0 initialNumSteps=10
PreToolUse     conversationId=e14810e4-7f19-4533-96ea-eccc81d28b2d stepIdx=12 tool=list_dir
PostToolUse    conversationId=e14810e4-7f19-4533-96ea-eccc81d28b2d stepIdx=12 tool=list_dir
PostInvocation conversationId=e14810e4-7f19-4533-96ea-eccc81d28b2d invocationNum=0 initialNumSteps=10
PreInvocation  conversationId=e14810e4-7f19-4533-96ea-eccc81d28b2d invocationNum=1 initialNumSteps=13
PostInvocation conversationId=e14810e4-7f19-4533-96ea-eccc81d28b2d invocationNum=1 initialNumSteps=13
Stop           conversationId=e14810e4-7f19-4533-96ea-eccc81d28b2d terminationReason=NO_TOOL_CALL fullyIdle=true
```

## Payload Fields Observed

`PreInvocation` / `PostInvocation` include:

```json
{
  "artifactDirectoryPath": "C:/Users/alon.HOME/.gemini/antigravity-cli/brain/<conversationId>",
  "conversationId": "<conversationId>",
  "initialNumSteps": 10,
  "invocationNum": 0,
  "transcriptPath": "C:/Users/alon.HOME/.gemini/antigravity-cli/brain/<conversationId>/.system_generated/logs/transcript_full.jsonl",
  "workspacePaths": ["C:/Temp/agy-hook-probe"]
}
```

`PreToolUse` includes:

```json
{
  "artifactDirectoryPath": "C:/Users/alon.HOME/.gemini/antigravity-cli/brain/<conversationId>",
  "conversationId": "<conversationId>",
  "stepIdx": 12,
  "toolCall": {
    "args": {
      "DirectoryPath": "C:\\Temp\\agy-hook-probe"
    },
    "name": "list_dir"
  },
  "transcriptPath": "C:/Users/alon.HOME/.gemini/antigravity-cli/brain/<conversationId>/.system_generated/logs/transcript_full.jsonl",
  "workspacePaths": ["C:/Temp/agy-hook-probe"]
}
```

`PostToolUse` includes the same tool call plus `error` and enriched action
metadata in `toolCall.args`.

`Stop` includes:

```json
{
  "conversationId": "<conversationId>",
  "error": "",
  "executionNum": 0,
  "fullyIdle": true,
  "terminationReason": "NO_TOOL_CALL",
  "transcriptPath": "C:/Users/alon.HOME/.gemini/antigravity-cli/brain/<conversationId>/.system_generated/logs/transcript_full.jsonl",
  "workspacePaths": ["C:/Temp/agy-hook-probe"]
}
```

## Resume Behavior

Running:

```text
agy --conversation e14810e4-7f19-4533-96ea-eccc81d28b2d --dangerously-skip-permissions --print "Answer exactly: RESUMED"
```

preserved the same `conversationId` in `PreInvocation`, `PostInvocation`, and
`Stop`. This supports using `conversationId` as Antigravity's per-session
refocus state key.

## Injection Output Results

`PreInvocation` accepts Antigravity `injectSteps` output:

```json
{
  "injectSteps": [
    {
      "ephemeralMessage": "HOOK_MARKER: Reply exactly PREINV_MARKER"
    }
  ]
}
```

Transcript evidence: conversation `18fb819b-27bb-47c9-8dd7-997c3b9a96fa`
responded `PREINV_MARKER`.

`PostInvocation` also accepts `injectSteps` output and causes a follow-on
invocation:

```json
{
  "injectSteps": [
    {
      "ephemeralMessage": "HOOK_MARKER: Reply exactly POSTINV_MARKER"
    }
  ]
}
```

Transcript evidence: conversation `2c8010a7-4737-4e0e-a49f-20b2a3d4ff10`
responded `POSTINV_MARKER` after `PostInvocation` injected the marker.

`PostToolUse` does fire, but it rejects `injectSteps`:

```text
tool post-hook jsonhook__probe-posttool-injection_PostToolUse_0_0 failed:
failed to unmarshal result from hook via protojson:
unknown field "injectSteps"
```

In that run, the rejected `PostToolUse` output caused the tool call to be
denied with an empty reason. Therefore Specrew must not emit Antigravity
`injectSteps` from `PostToolUse` unless a different valid tool-hook output
schema is proven.

`Stop` accepts:

```json
{
  "decision": "allow"
}
```

## Design Implications

- Antigravity has real hook coverage for all five event names in this local
  `agy` run: `PreInvocation`, `PostInvocation`, `PreToolUse`, `PostToolUse`,
  and `Stop`.
- `conversationId` is stable across exit/re-entry via `agy --conversation`.
- `PreInvocation` is the safest candidate for Antigravity bootstrap plus B3
  refocus injection because it accepts `injectSteps` and runs before each model
  invocation.
- `PostInvocation` is a viable secondary injection carrier, but it creates a
  follow-on invocation and should be used deliberately.
- `PostToolUse` is an observation/trigger surface, not a proven injection
  surface. The current `injectSteps` output shape is invalid there and can
  interfere with tool execution.
- F-184 should update the integration design from "Antigravity lacks
  PostToolUse" to "Antigravity has PostToolUse, but PostToolUse injection is
  not proven and `injectSteps` is known-invalid for that event."
