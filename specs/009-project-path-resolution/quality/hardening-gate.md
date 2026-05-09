# Hardening Gate: Feature 009

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/009-project-path-resolution/spec.md`
**Scope Ref**: `specs/009-project-path-resolution`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `Human developer request on 2026-05-09 to run feature 009 through the full lifecycle including implementation (current session)`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-05-09T19:45:35Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `not-needed` | Keep the change bounded to local PowerShell CLI/governance scripts; add no network calls, auth flows, secrets, or runtime services; require explicit human review before any exemption widens the audited surface. | `true` | Feature 009 changes path normalization plus governance artifacts only. The meaningful risk is CLI compatibility and audit completeness, not a new network or runtime-service boundary, so no separate runtime-service hardening proof is needed if implementation stays inside the audited scripts. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Preserve the exact user-facing errors (`Project path does not exist`, `Project is not Specrew-managed`, `Project is not fully bootstrapped`); preserve rooted/UNC pass-through; verify mirrored source and `.specify` scripts fail closed on unresolved relative-path handling. | `true` | The main failure risk is silent compatibility drift while replacing raw `GetFullPath` calls. Runtime evidence is still pending because implementation has not started and the regression lane plus contract review must later prove message fidelity and mirrored-script parity. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | — | `true` | This slice introduces no network retries, queue replay, or duplicate-write hazard. Re-running the bounded CLI/governance scripts should remain deterministic file-based behavior rather than a new idempotency contract. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Keep the existing governance baseline green; add `tests/integration/project-path-resolution-regression.ps1`; include the static anti-pattern scan; seed the known-traps corpus and record trap reapplication before closure. | `true` | The quality bar depends on both behavioral proof and mechanical proof: CLI compatibility must be verified under diverged PowerShell/.NET working directories, and the historical anti-pattern must fail closed if it reappears. Those artifacts are planned but not yet executed, so runtime evidence remains pending. | `—` |
| `operational-resilience-concerns` | `operational` | `not-applicable` | `not-applicable` | `not-needed` | — | `true` | No long-lived daemon, network endpoint, or background service is added by this feature. Operational review is therefore limited to bounded CLI behavior through the existing validation lanes; dedicated runtime-service resilience evidence is not applicable. | `—` |

## Notes

- This artifact is intentionally a planning-readiness review for feature 009: implementation has not started, so executable evidence remains pending until the audited script changes, regression lane, static scan, and trap artifacts exist.
- Human sign-off is recorded via the current-session request to run feature 009 through the full lifecycle including implementation; unresolved critical concerns are not deferred.
- No human deferral approval is requested in this draft. If any audited call site later seeks exemption, if trap seeding scope changes, or if the regression/static-scan plan cannot be delivered as specified, implementation must stop for explicit human approval and recorded evidence.
