# Dependency Report: Iteration 008

**Schema**: v1
**Reviewed**: 2026-07-21
**Baseline Ref**: `364fbe88ef29cce5ac74d8086c1d78d8b8363197`
**Reviewed HEAD**: `9a6b88540088be2ff82fec145079b3f8765e863e`

## Dependency Delta

| Ecosystem | Change | Review conclusion |
| --- | --- | --- |
| PowerShell module | Verification-plan, conformance-delta, and containment scripts added to file:///C:/Dev/specrew-beta2-hardening/Specrew.psd1 | Packaging-only; no new external library |
| GitHub Actions distribution | Consumer allowlist reduced to methodology-gate and work-kind | Deny-by-default; repository workflows are not consumer dependencies |
| GitHub Actions validation | Existing cross-platform workflow exercises deterministic contracts on three OSes | No live provider secret or spend |
| Reviewer CLI | Claude uses the existing host catalog with empty MCP/settings sources and bounded tools | Operator prerequisite, not package dependency |
| OS containment | Windows Job Objects and native read-only protection; Linux/macOS deterministic coverage | Native facilities; no daemon, broker, lock server, or database |
| Verification execution | PowerShell and Git create exact disposable verification and external evidence paths | Existing prerequisites; no third-party service |
| Host prompt adapters | Five hook manifests expose genuine per-prompt events | Capability metadata only; no SDK dependency |
| Finalization classifier | Canonical `.claude/settings.local.json` joins existing machinery policy; ordinary settings stay reviewable | Uses existing file-classification semantics; no dependency added |
| Finalization envelope | Existing validator, CreateNew fact writer, and signoff wiring | Reuses Git and authority store; no new service |

## New-to-Project Packages

None. No lockfile or third-party application library is introduced. PowerShell 7, Git, GitHub CLI for operator inspection, Claude Code for authorized review, and native OS controls remain runtime/operator prerequisites.

## Security and Operations Signal

- No provider credential or Actions provider secret was added.
- Reviewer authentication stays local and is never copied into the repository or frozen target.
- The launch uses an empty inherited environment plus declared plan environment, isolated settings, no MCP, no session persistence, and read/search plus candidate-file write capability.
- Verification runs before spend in a disposable target; the untouched reviewer target is byte-checked and OS-protected before launch.
- Canonical machine-local Claude settings are excluded from product identity but remain protected by target-integrity checks; ordinary Claude project settings remain reviewable.
- Release credentials, tag creation, and publication remain unavailable until separate T029 authorization.
