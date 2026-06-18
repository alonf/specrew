# Integration and API Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-16
**Depth**: Medium
**Confirmation**: human-confirmed (lens-question scope)

## Contract Surfaces

```text
Host hook event contract
  Producer: AI host hook runtime
  Consumer: specrew-hook-dispatcher.ps1 / providers
  Contract: SessionStart payload may omit or malform session_id; dispatcher must tolerate it.

Dispatcher/provider output contract
  Producer: dispatcher + bootstrap/refocus providers
  Consumer: AI host model context
  Contract: stdout is the delivery channel where verified for the host; non-empty governed directive under cap; exit 0 even on degraded fallback.

Refocus/session journal contract
  Producer: SessionStart dispatcher/provider
  Consumer: specrew where / refocus status / dedupe / breaker
  Contract: session key is sanitized and per-launch fallback when host ID is absent; no global unknown collapse.

Closeout sync contract
  Producer: sync-boundary-state.ps1
  Consumer: lifecycle artifacts, dashboard, human closeout packet
  Contract: dirty classification, push/commit message, and dashboard path are derived from repo/upstream state.

Mirror parity contract
  Producer: source extension files
  Consumer: deployed .specify extension copy
  Contract: touched files remain byte-aligned between source and deployed mirror.

GitHub/proposal linkage
  Producer: feature closeout
  Consumer: GitHub issues/proposals
  Contract: close #2446/#1627/#1761 at feature closeout with fixing commits; proposals referenced but not silently edited.

Antigravity hook contract
  Producer: Antigravity project hook runtime
  Consumer: Specrew hook dispatcher/provider
  Contract: Specrew uses project-scoped .agents/hooks.json with Antigravity-specific schema; map only verified Antigravity events and output semantics.
```

## Compatibility and Error Semantics

Hook providers:

- Always exit 0 for provider failure fallback, because host hook failures must
  not block the host session.
- Emit explicit degraded-governance text, not raw exception text.
- Keep fallback under the same cap assumptions as normal output.

Session IDs:

- Accept host-specific payload variance.
- Sanitization must produce filesystem-safe/runtime-key-safe names.
- Missing IDs get a generated per-launch token stable for that launch, not for
  all launches.

Closeout sync:

- No upstream remote means no “must be pushed” instruction.
- Auto-detect closeout must regenerate dashboard rather than preserving stale
  output.
- `.specify` classification handles extensions and companion state/config files
  as one coherent dirty surface.

Mirror parity:

- Source is authoritative.
- Mirror copies are compatibility artifacts for the active dogfood project and
  must match touched source files.

GitHub issues:

- Issue closure happens at feature closeout, not during implementation.

Antigravity:

- Treat Antigravity as project-scoped for Specrew hook deployment:
  `.agents/hooks.json`, closer to Claude's project-local model than Codex/Copilot
  user-global config.
- Do not use global `~/.gemini/config` for Specrew's project hooks unless a later
  design explicitly chooses per-machine launcher indirection.
- The schema is Antigravity-specific, not assumed Claude-compatible.
- Do not claim direct-launch bootstrap or rolling-handover parity until
  Antigravity event injection/capture behavior is verified.

## Fast Delta: Antigravity Hook Support

### A1 — Contract Binding

Use Antigravity hook support as a new host binding, but only after implementation
verifies:

1. Config location: project-scoped `.agents/hooks.json` for Specrew.
2. Config schema: named hook wrapper shape, event names, matcher fields, command
   hooks, timeout, and user-entry preservation rules.
3. Event mapping: map only verified Antigravity events to Specrew SessionStart
   or Stop-style behavior.
4. Output semantics: verify how a command hook returns added context, decisions,
   or diagnostics; do not assume stdout behaves like Claude/Codex/Cursor.
5. Compatibility posture: until verified, Antigravity support is hook config
   support under validation, not full parity.

### A2 — Provisioning and Release Path

- `specrew init`, `specrew update`, and `specrew hooks install/status/remove`
  include Antigravity once `RefocusHookBindings` is added.
- Antigravity hook config merge preserves user entries.
- Opt-out behavior matches other hook-capable hosts.
- Existing `specrew start --host antigravity` path remains as fallback.
- Remove or rewrite stale Antigravity-no-hooks wording.
- Antigravity real-host validation is required before stable promotion if this
  FR ships. If support cannot be validated in time, it must be explicitly split
  or deferred rather than claimed.

### A3 — Degraded Behavior

- Hook config present but not firing: `specrew hooks status` should surface
  missing/stale/failed or a diagnostic where detectable.
- Hook fires but cannot inject model context: do not claim direct-launch
  bootstrap parity; keep `specrew start --host antigravity` as governed fallback.
- Stop/post-invocation cannot capture useful transcript/context: do not claim
  rolling-handover parity; persist only what the hook can honestly observe.
- Unknown/changed Antigravity hook schema: fail open, preserve user config,
  report unsupported shape, and leave launcher fallback intact.

### A4 — Implementation Posture

- Reuse `deploy-refocus-hooks.ps1` and the registry-driven
  `RefocusHookBindings` model.
- Add Antigravity via manifest capability, not by treating all supported hosts as
  hook-capable.
- Add an Antigravity arm only where schema/output/event differences require it.
- Keep ownership detection based on Specrew dispatcher/launcher command tokens.
- Replace “Antigravity excluded” assertions with positive hook-capable and
  provisioning assertions once the binding is implemented.
- Use no new dependencies.

## Integration Evidence

- Synthetic SessionStart event fixture covers missing/malformed session ID.
- Provider-failure fixture covers stdout fallback and exit 0.
- Over-cap fixture covers bootstrap-preserved/refocus-dropped behavior.
- Closeout fixture covers no-upstream messaging and `.specify` dirty
  classification.
- Dashboard fixture covers auto-detect regeneration.
- Mirror parity check covers touched source vs `.specify` extension files.
- Antigravity hook fixture covers config merge/preserve/remove/opt-out behavior.
- Antigravity event contract tests cover only verified events.
- Antigravity real-host validation proves dispatcher/provider behavior before
  stable.
- Feature-closeout record links fixing commits to #2446, #1627, and #1761.
