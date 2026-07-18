# Dependency Report: Iteration 007

**Schema**: v1
**Reviewed**: 2026-07-18
**Baseline Ref**: `d9cdd16457e322628957ea74de959a5457358852`

## Dependency Delta

| Ecosystem | Change | Review conclusion |
| --- | --- | --- |
| PowerShell module | Internal review scripts added to file:///C:/Dev/specrew-beta2-hardening/Specrew.psd1 package inventory | Packaging-only; no new external library |
| GitHub Actions | Deterministic review-runtime job added to file:///C:/Dev/specrew-beta2-hardening/.github/workflows/cross-platform-validation.yml | Uses existing checkout/PowerShell/Pester mechanisms; no live provider secret |
| Reviewer CLIs | Claude, Codex, Copilot, Cursor, and Antigravity characterized through the existing host catalog | Runtime prerequisites, not project package dependencies |
| Operating-system containment | Windows Job Objects, Linux cgroup v2, macOS process groups | Native OS facilities; no daemon, broker, database, or lock service added |

## New-to-Project Packages

None. No package lockfile or third-party application library is introduced. PowerShell 7, Git, the five external reviewer CLIs, and native containment are operator/runtime prerequisites already modeled by preflight and truthful support status.

## Security and Operations Signal

- No hosted macOS provider credential or GitHub Actions provider secret was added.
- Reviewer authentication remains local to each CLI and is inspected only through bounded status/preflight commands.
- Strict file-primary ingress, minimized reviewer environment, external targets, and OS containment are the security boundary.
- Cursor paid on-demand use is not claimed; the observed Free quota exhaustion remains visible.
