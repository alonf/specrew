# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/140-unix-native-install/spec.md`
**Iteration Ref**: `specs/140-unix-native-install/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Crew coordinator (planning-time)
**Reviewed At**: 2026-06-02T00:02:00Z

<!--
  Concern Review schema (validator-enforced):
  - Status MUST be one of: `addressed` | `not-applicable` | `deferred-with-approval`.
  - `addressed`: EvidenceBasis = `planning-time-analysis`, RuntimeEvidenceStatus = `pending-post-implementation`, ExpectedControls = concrete controls.
  - `not-applicable`: EvidenceBasis = `not-applicable`, RuntimeEvidenceStatus = `not-needed`, ExpectedControls = `—`. Rationale explains WHY.
  - Overall Verdict is `ready` when every concern is addressed/not-applicable/deferred-with-approval; else `blocked`.
-->

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `install-shell-wrappers writes ONLY inside -BinDir (default ~/.local/bin) and refuses to create a missing dir without -Force; never edits shell profiles; wrappers run pwsh with -ExecutionPolicy Bypass scoped to a single specrew.ps1 exec; no eval of user input; install.sh verifies pwsh and never auto-installs it.` | `true` | `Trust boundary = install-time filesystem writes + the curl\|sh bootstrap. No secrets; the only network call is Install-Module from PSGallery. Privilege model: user-scoped bin dir only; no sudo/system paths by default.` | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `pwsh missing -> non-zero + clear "PowerShell Core (pwsh) is required" + install hint (FR-004); missing bin dir without -Force -> refuse (FR-006); bootstrap aborts if pwsh absent; installer prints installed commands + PATH warning. Positive + negative tests asserted (T002 template behavior, T008 installer).` | `true` | `All failure paths exit non-zero with an actionable message (no silent failure); no partial/garbled bin dir on failure; wrappers exec exactly the PS entrypoint and propagate its exit code.` | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `install-shell-wrappers is idempotent (re-run yields no duplication/partial state); -WhatIf changes nothing; the generator is deterministic (byte-identical re-run). Verified by T008 (installer idempotency) + T005 (generator idempotency).` | `true` | `Installer + generator idempotency is required and tested. Network retry/reconnect/recovery is N/A: Install-Module is a user-re-runnable one-shot; no long-lived connections or transactional state.` | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `FR -> named-test mapping (tasks.md Traceability Matrix); negative paths required (pwsh-missing, missing-bin-dir, unknown-option passthrough); Ubuntu+macOS CI is the authoritative runtime surface (Iteration 2 T011); PS unit + parity evidence under iterations/001/quality/. Smoke-only disallowed for failure-mode FRs.` | `true` | `Positive + negative coverage per FR; generator/installer/parity unit-tested in Iteration 1; cross-platform runtime proof in Iteration 2. Git-Bash-on-Windows is a development proxy, not the verdict.` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `No server, SLO, telemetry pipeline, oncall surface, or operational dependency ships in this iteration — it is a CLI wrapper generator + installer. There is no runtime service to operate.` | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/140-unix-native-install/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- All five concerns carry planning-time analysis + expected controls; runtime evidence (lens execution, test counts, mechanical-findings) is collected after implementation lands — that deferral is intentional for a planning-time gate.
- Verdict is `ready`: four concerns `addressed`, one `not-applicable`. No `deferred-with-approval` rows, so no human deferral approval is required at this gate.
