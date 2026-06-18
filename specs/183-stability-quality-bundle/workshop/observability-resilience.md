# Observability and Resilience Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-16
**Depth**: Medium
**Confirmation**: human-confirmed (lens-question scope)

## Signals and Diagnostics

```text
Dispatcher cap handling
  - record/log when refocus is dropped or shrunk because bootstrap has priority
  - include enough detail to prove the bootstrap survived under cap

Provider failure fallback
  - emit fallback directive to stdout
  - write diagnostic to stderr or journal without exposing raw stack text to the model

Session ID fallback
  - journal/status should show the generated per-launch token, not `unknown`
  - enough context to distinguish missing host ID from normal host-provided ID

Closeout sync
  - output names the dirty classification and whether upstream exists
  - dashboard regeneration path is visible in test/evidence

Hook provisioning
  - specrew hooks status reports installed/missing/stale/opted-out/failed per host
  - Antigravity partial capability reports verified vs unverified behavior

Release
  - record current tag/published-state check before selecting beta target
  - record real-host validation PASS/FAIL before stable promotion
```

## Recovery Behavior

Oversized payload:

- Preserve bootstrap fragment.
- Drop/shrink lower-priority refocus.
- Warn diagnostically, but do not block startup.

Provider failure:

- Emit governed fallback.
- Exit 0.
- Tell agent/user repair commands: `specrew where`, `/specrew-refocus`, and
  where relevant `specrew hooks status`.

Missing session ID:

- Generate per-launch fallback token.
- Avoid global state collision.
- No migration of historical unknown files required.

Hook config failure:

- Preserve user config.
- Fail open.
- Surface repair and `specrew start --host <host>` fallback.

Antigravity partial hooks:

- Use verified subset only.
- Fallback to `.agents/skills`, `AGENTS.md`, `specrew where`,
  `/specrew-refocus`, and `specrew start --host antigravity`.

Real-host validation failure:

- Do not promote stable.
- Record failure.
- Fix and publish next beta.

## Review Evidence

- Test output proving cap handling and fallback behavior.
- Journal/status evidence proving session ID fallback does not use global
  `unknown`.
- Closeout evidence proving dirty classification, no-upstream wording, and
  dashboard regeneration.
- Hook status/deploy evidence including Antigravity if FR-007 remains in scope.
- Mirror parity evidence for touched extension files.
- Release evidence showing current beta-state check and real-host validation
  result.
