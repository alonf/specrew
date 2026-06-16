# T009 Real-Host Validation Evidence

**Schema**: v1
**Task**: T009 - Real-host validation evidence
**Trace**: SC-008, SC-009, TG-004
**Recorded At**: 2026-06-16T10:53:30Z
**Overall Verdict**: pass

## Scope

T009 validates the bounded real-host slice for Antigravity after T006:

- Antigravity must load and fire project-local `.agents/hooks.json` hooks in a real `agy` host, not only deterministic dispatcher tests.
- `PreInvocation` must reach the Specrew dispatcher through the installed hook path and produce Antigravity `injectSteps[].ephemeralMessage` bootstrap output.
- `Stop` must fire in the real host and return a successful Antigravity stop decision path.
- The final Antigravity hook-output envelope must remain under the 10,000 character host cap.
- This is bounded support evidence only; it is not a full parity claim with Claude, Codex, Copilot, or Cursor.

## Installed Binding

Command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\specrew-hooks.ps1 install --host antigravity
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\specrew-hooks.ps1 status --host antigravity
```

Result:

- Status reported `antigravity installed`.
- The installed `.agents/hooks.json` uses encoded PowerShell commands that decode to:
  - `& 'C:/Users/alon.HOME/.specrew/specrew-hook-launch.ps1' -Event 'PreInvocation' -HostKind antigravity`
  - `& 'C:/Users/alon.HOME/.specrew/specrew-hook-launch.ps1' -Event 'Stop' -HostKind antigravity`
- The launcher is generated per-machine and resolves the project dispatcher from host event/root/cwd signals, so the hook no longer depends on Antigravity running commands from the project root.

## Real Host Run

Command:

```powershell
agy --log-file .specrew\runtime\agy-t009-launcher-stop.log --print "Reply with exactly: OK" --add-dir . --print-timeout 5m
```

Evidence:

- `file:///C:/Dev/183-stability-quality-bundle/.specrew/runtime/agy-t009-launcher-stop.log` records `loaded 1 named hooks from 1 hooks.json file(s)`.
- The same log records `Loaded hooks.json from C:\Dev\183-stability-quality-bundle\.agents\hooks.json: 1 named hooks, 2 total handlers`.
- The same log records `JSON hook "jsonhook__specrew-refocus_PreInvocation_0_0": executing command`.
- The same log records `JSON hook "jsonhook__specrew-refocus_Stop_0_0": executing command`.
- No `JSON hook command stderr`, `failed to call custom`, `exit status`, `LAUNCH_FAILED`, `PROVIDER_FAILED`, or Specrew `WARN` lines were present in the passing run.
- `file:///C:/Dev/183-stability-quality-bundle/.specrew/runtime/bootstrap-journal.jsonl` records Antigravity bootstrap entries for conversation `3701c64a-7cf3-46b1-a47d-28e816345807`.
- `file:///C:/Dev/183-stability-quality-bundle/.specrew/handover/session-handover.md` was updated at the Stop hook time (`2026-06-16 13:53` local), confirming the real Stop path reached handover storage.

## Envelope Check

Command:

```powershell
$eventJson = '{"conversationId":"t009-envelope","workspacePaths":["C:/Dev/183-stability-quality-bundle"],"hookEventName":"PreInvocation"}'
$out = & pwsh -NoProfile -ExecutionPolicy Bypass -File .specify\extensions\specrew-speckit\scripts\specrew-hook-dispatcher.ps1 -Event PreInvocation -HostKind antigravity -EventJson $eventJson
```

Result:

- Dispatcher exit code: `0`
- Antigravity JSON stdout length: `6637` characters
- `injectSteps[0].ephemeralMessage` length: `6560` characters
- Stderr: empty
- Result: pass, final Antigravity host-facing JSON envelope is under the 10,000 character cap.

## Defect Reproduction and Repair

The earlier real-host run in `file:///C:/Dev/183-stability-quality-bundle/.specrew/runtime/agy-t009-fixed.log` proved Antigravity loaded and fired hooks but failed the Specrew command:

- It loaded `.agents/hooks.json`.
- It fired `PreInvocation` and `Stop`.
- It failed with `The argument './.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1' is not recognized as the name of a script file.`

The repair replaces the Antigravity relative dispatcher command with the cwd-robust per-machine launcher, encoded to avoid Antigravity's Windows quote-passthrough behavior.

## Pass/Fail Matrix

| Criterion | Result | Evidence |
| --------- | ------ | -------- |
| SC-008 real hook-firing Antigravity host, not just `agy` CLI presence | pass | `agy-t009-launcher-stop.log` loaded `.agents/hooks.json` and executed `PreInvocation` |
| SC-008 explicit pass/fail for real-host run | pass | This artifact records `Overall Verdict: pass` with concrete log evidence |
| SC-009 real `Stop` hook fires | pass | `agy-t009-launcher-stop.log` executed `jsonhook__specrew-refocus_Stop_0_0` |
| SC-009 Stop path updates durable handover | pass | `session-handover.md` timestamp updated at Stop hook time |
| TG-004 bounded Antigravity support remains honest | pass | Evidence covers only `.agents/hooks.json`, `PreInvocation`, `Stop`, launcher dispatch, and fallback-compatible bounded support |
| Non-Claude final envelope under 10k | pass | Antigravity JSON stdout measured `6637` chars |

## Notes

- A shorter 2-minute run in `file:///C:/Dev/183-stability-quality-bundle/.specrew/runtime/agy-t009-launcher.log` proved repeated `PreInvocation` firing but timed out before Stop. It is not used as the Stop pass criterion.
- The validated support claim remains bounded: project-local `.agents/hooks.json`, `PreInvocation` bootstrap injection, `Stop` handover decision, and fallback guidance through `specrew start --host antigravity`.
