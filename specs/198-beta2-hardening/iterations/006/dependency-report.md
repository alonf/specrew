# Dependency Report: Iteration 006

**Schema**: v1
**Reviewed**: 2026-07-16
**Baseline Ref**: `5adc9d8cc9667fa15ea7537108d6be94396dc716`

## Dependency Delta

| Ecosystem | Dependency | Change | Owning task |
| --- | --- | --- | --- |
| PowerShell module package | Internal review authority scripts added to `Specrew.psd1` FileList | Packaging-only; no external dependency | T049, T050 |

## New-to-Project

- None. The authority foundation uses PowerShell/.NET, Git, and the existing reviewer-host catalog.
- No database, event store, lock service, CAS framework, network service, or third-party package was added.

## Runtime Boundaries

- Git supplies shared-object external worktrees for code review targets.
- Existing OS containment supplies Windows Job Objects; Linux/macOS production adapters remain Iteration 007.
- Claude Code is the selected external reviewer harness for T050; its candidate is ingested through the common versioned file contract.

## Vulnerability Signal

- Status: not applicable to package-version scanning; no external dependency version or lockfile changed.
- Security-relevant behavior is instead covered by external-target integrity, minimized reviewer environment, strict identity/schema ingress, fail-closed containment, and v6 independent review.
