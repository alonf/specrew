# Discovery Spike: Antigravity B3 on PreInvocation

**Task**: T001
**Date**: 2026-06-17
**Verdict**: PASS
**Scope**: FR-003, FR-010, SC-009, TG-004, TG-005

## Inputs

- Real-host hook spike:
  file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/workshop/integration-api-hook-spike.md
- Runtime dispatcher:
  file:///C:/Dev/183-stability-quality-bundle/scripts/internal/specrew-hook-dispatcher.ps1
- Antigravity host manifest:
  file:///C:/Dev/183-stability-quality-bundle/hosts/antigravity/host.psd1
- Refocus provider catalog:
  file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/refocus-scopes.json

## Probe Results

| Probe | Evidence | Result |
| --- | --- | --- |
| `agy` availability | `agy --version` returned `1.0.8` on this machine. | PASS |
| Antigravity PreInvocation fires before each model invocation | Real-host spike recorded `PreInvocation` with `conversationId`, `invocationNum`, `initialNumSteps`, `transcriptPath`, and `workspacePaths`. | PASS |
| PreInvocation can inject into the model | Real-host spike proved `injectSteps` from `PreInvocation` caused the model to respond with the injected marker. | PASS |
| PostToolUse is not a safe Antigravity injection carrier | Real-host spike proved `PostToolUse` fires but rejects `injectSteps` with `unknown field "injectSteps"` and can interfere with the tool call. | PASS |
| Stable Antigravity session identity exists | Real-host spike proved `conversationId` remained stable across `agy --conversation <id>` resume. | PASS |
| Current dispatcher can read the boundary cursor before emission | `Get-BoundaryCursor` reads `.specrew/start-context.json` synchronously inside the dispatcher before provider output is assembled. | PASS |
| Existing B3 state machinery is host-neutral | `Test-B3ShouldInject`, session state paths, journal, dedupe, and breaker are keyed by sanitized host session id and do not depend on Claude/Codex/Copilot/Cursor-specific output. | PASS |

## Split-Guard Rows

| Trigger | Required Evidence | Finding | Result |
| --- | --- | --- | --- |
| `fresh-boundary-cursor` | Demonstrate the cursor used by B3 is available before the model turn. | Antigravity `PreInvocation` fires before the invocation, and the dispatcher reads `.specrew/start-context.json` before provider execution. The cursor is therefore available before emitting `injectSteps`. | PASS |
| `exactly-once-b3` | Demonstrate existing dedupe/breaker can prevent duplicate B3 injection. | Existing B3 logic anchors on first sight, stays silent on unchanged cursor, emits on cursor change, dedupes channel-1 fingerprints, records journal outcomes, and trips the existing breaker on repeat/token runaway. F-184 only needs to classify Antigravity `PreInvocation` as a B3 carrier. | PASS |
| `bounded-host-model` | Demonstrate no non-Antigravity shared host contract change is required. | Required runtime work is bounded to adding Antigravity `PreInvocation` to the refocus provider event set, extending dispatcher B3-carrier detection to `HostKind=antigravity` + `Event=PreInvocation`, and updating Antigravity manifest/docs/tests. No new host abstraction or dependency is required. | PASS |

## Implementation Binding

Proceed with T002-T005 under these constraints:

- Reuse `Test-B3ShouldInject`, the existing per-session refocus state file,
  journal, dedupe, and breaker.
- Do not emit Antigravity `injectSteps` from `PostToolUse`.
- `PreInvocation` may carry B2 bootstrap and B3 refocus, but B3 must be silent on
  first sight and on unchanged boundaries.
- `conversationId` is the Antigravity state key when present; no global
  `unknown` key is allowed.
- If implementation requires changing non-Antigravity host contracts, stop for a
  human split/defer decision.

## Residual Notes

- A scratch dispatcher probe without `SPECREW_MODULE_PATH` showed an installed
  stale module can make the bootstrap provider fail open before Antigravity
  support is packaged. This is not a split-guard failure for F-184 because the
  release package will carry the current bootstrap components, but T007 must
  include FileList/release readiness so the packaged module contains the
  updated Antigravity-aware bootstrap components.
