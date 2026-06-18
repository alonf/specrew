# UI and UX Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-16
**Depth**: Light
**Confirmation**: human-confirmed (lens-question scope)

## User-Visible Text Surfaces

```text
Fail-loud fallback directive
  - short, direct, and clearly degraded-but-governed
  - names recovery commands: specrew where, /specrew-refocus
  - if hook health is relevant, names specrew hooks status
  - avoids stack traces or vague "something failed" language

Closeout push/commit wording
  - "must be pushed" only when an upstream exists
  - no-upstream case says commit is enough locally, or tells the user to set/push upstream if release flow requires it

Antigravity docs/messages
  - no stale Antigravity-no-hooks blanket statement
  - say hooks are supported only for verified Specrew mappings
  - keep specrew start --host antigravity as fallback wording

Dashboard auto-detect
  - regenerated dashboard should show the current closeout state, not stale previous content
```

## Interaction Fallback Wording

General fallback shape:

```text
Specrew hook bootstrap is degraded for <host>.
Governance is still active.

Try:
  1. specrew where
  2. /specrew-refocus
  3. specrew hooks status
  4. specrew start --host <host>
```

Antigravity-specific fallback shape:

```text
Antigravity hook support is available only for verified Specrew hook mappings.
If this session did not receive the bootstrap banner, run:
  specrew start --host antigravity
```
