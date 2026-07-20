# Dependency Report: Iteration 008

**Schema**: v1
**Reviewed**: 2026-07-20
**Baseline Ref**: `364fbe88ef29cce5ac74d8086c1d78d8b8363197`
**Reviewed HEAD**: `659bec289646a2fa6f062973a94d2cbd3249632f`

## Dependency Delta

| Ecosystem | Change | Review conclusion |
| --- | --- | --- |
| PowerShell module | New verification-plan, conformance-delta, and review-containment scripts added to file:///C:/Dev/specrew-beta2-hardening/Specrew.psd1 | Packaging-only; no new external library |
| GitHub Actions distribution | Consumer allowlist reduced to methodology-gate and work-kind workflows | Deny-by-default distribution; removed self-host project workflows are not consumer dependencies |
| GitHub Actions validation | Existing cross-platform workflow exercises deterministic contracts on Windows, Ubuntu, and macOS | No live provider secret or hosted provider spend |
| Reviewer CLI | Claude Code is launched through the existing host catalog with empty MCP/settings sources and bounded file-primary tools | Operator prerequisite, not a project package dependency |
| Operating-system containment | Windows Job Objects plus native read-only file protection; Linux/macOS paths remain deterministic CI coverage | Native OS facilities; no daemon, broker, lock server, or database |
| Verification execution | PowerShell and Git create an exact disposable verification worktree and external evidence path | Reuses existing runtime prerequisites; no third-party service |
| Host prompt adapters | Claude, Codex, Copilot, Cursor, and Antigravity hook manifests expose their genuine per-prompt event | Host capability metadata only; no SDK dependency |
| Finalization envelope | Existing validator, CreateNew fact writer, and signoff-gate wiring | Reuses Git and the campaign authority store; no new service |

## New-to-Project Packages

None. No package lockfile or third-party application library is introduced. PowerShell 7, Git, GitHub CLI for operator inspection, Claude Code for the authorized live review, and native OS controls are runtime/operator prerequisites already handled by preflight and truthful evidence.

## Security and Operations Signal

- No provider credential or GitHub Actions provider secret was added.
- Reviewer authentication remains local to the CLI and is never copied into the repository or frozen target.
- The reviewer launch uses an empty inherited environment plus explicitly declared plan environment, isolated settings, no MCP servers, no session persistence, and only read/search plus candidate-file write capability.
- Verification commands run before spend in a disposable target; the untouched reviewer target is byte-checked and OS-protected before harness launch.
- The finalization fact is controller-owned, `CreateNew`, outside the reviewed digest, and cannot form an envelope chain.
- Release credentials, tag creation, and beta publication remain unavailable until separate T029 authorization.
