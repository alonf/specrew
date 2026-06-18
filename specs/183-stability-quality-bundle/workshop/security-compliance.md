# Security and Compliance Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-16
**Depth**: Light
**Confirmation**: human-confirmed (lens-question scope)

## Trust Boundaries

```text
Host hook input
  Boundary: external host event JSON -> Specrew dispatcher/provider scripts
  Control: validate/sanitize session ID; fail open with governed fallback; do not trust host payload shape.

Generated stdout directive
  Boundary: Specrew script output -> AI host model context
  Control: keep fallback directive minimal, explicit, and under cap; never emit empty-on-error.

Local filesystem state
  Boundary: scripts read/write .specrew, .specify, specs, tests
  Control: constrain writes to intended project paths; tests use scratch repos for destructive/dirty-state scenarios.

Shell/git execution in tests
  Boundary: Pester tests invoke git/scripts
  Control: isolate scratch git context; do not let test gates act on the real worktree accidentally.

Release/promote path
  Boundary: local implementation -> published module
  Control: beta-before-stable plus manual real-host validation; no direct stable promotion.

Antigravity hook configuration
  Boundary: Specrew hook deployment -> Antigravity project-scoped .agents/hooks.json
  Control: merge Specrew-owned entries only, preserve user hooks, and never enable privileged behavior from unverified events.
```

No new secrets, tokens, PII, auth, or network credentials are introduced by this
feature.

## Security Failure Modes

- **Provider exception** — must fail loud but non-blocking: stdout fallback,
  exit 0, no stack trace or empty output as the user-facing result.
- **Malformed/missing session ID** — must not poison shared state under global
  `unknown`; sanitize or generate a per-launch fallback token.
- **Oversized hook output** — must preserve governance bootstrap rather than
  letting the host drop the whole payload.
- **Dirty-state test fixtures** — must not accidentally classify or mutate the
  real repo when exercising closeout gates.
- **Release target confusion** — must check current beta/tag/publish state before
  deciding the next beta target.
- **Antigravity hook over-claim** — must not claim hook parity for Antigravity
  events until the current official event and output/capture semantics are
  verified and tested.

## Audit and Evidence

- Tests prove malformed hook/session input is sanitized or safely substituted.
- Tests prove provider failure emits safe, minimal fallback output rather than
  raw exception/no output.
- Tests prove scratch git fixtures do not act on the real repo.
- Release evidence records the checked current beta state before tag/publish
  decisions.
- Antigravity hook evidence records the official hook contract used, tests config
  merge/remove/opt-out behavior, and includes a real-host validation before
  stable promotion.
- Review checks touched logs/artifacts for accidental secret/path leakage only if
  new logging is added.

No separate threat model, permission model, or compliance mapping is required.
