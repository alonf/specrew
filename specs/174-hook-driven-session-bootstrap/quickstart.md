# Quickstart: Hook-Driven Session Bootstrap

**Feature**: 174-hook-driven-session-bootstrap
**Last verified**: 2026-06-08 (planning artifact — verified at implementation)

## Run it

```text
# unit + contract tests
Invoke-Pester tests/specrew/bootstrap

# exercise the real surface: launch a supported host directly (NOT via specrew start)
# in a Specrew project, and observe the SessionStart bootstrap
```

## Try the canonical scenario

1. Launch Claude directly in a Specrew project with **no valid active anchor**.
   → Expected: the SessionStart hook injects the bootstrap directive; the agent renders
   **prose** orientation (version · host · project · lifecycle) then the
   **Resume / New / Pick-feature** menu — before any structured picker.
2. End the session cleanly. → Expected: a Proposal 130-compatible handover is written to
   disk (no git commit by default).
3. Relaunch. → Expected: a **welcome-back** that surfaces the handover timestamp and its
   recommended next step.

## Verify the edge cases

- **Stale anchor**: seed session state anchored to a merged/closed feature, or with an
  absolute path to another worktree, then launch. → Expected: "Cleared a stale anchor to
  &lt;feature&gt;" + full menu (the anchor is never offered as resume).
- **Launcher + hook**: run `specrew start` into a hook-bound host. → Expected: exactly
  **one** bootstrap surface in the session (dedupe).
- **Unclean prior exit**: leave a SessionStart marker newer than the latest handover, then
  launch. → Expected: an advisory "prior session may have exited uncleanly" line; the
  bootstrap still proceeds (fail-open).
