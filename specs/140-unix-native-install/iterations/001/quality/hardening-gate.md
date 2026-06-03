# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/140-unix-native-install/spec.md`
**Iteration Ref**: `specs/140-unix-native-install/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Crew coordinator (planning-time) + closeout disposition at review-signoff
**Reviewed At**: 2026-06-02T06:30:00Z

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
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `install-shell-wrappers writes ONLY inside -BinDir (default ~/.local/bin) and refuses to create a missing dir without -Force; never edits shell profiles; wrappers run pwsh with -ExecutionPolicy Bypass scoped to a single specrew.ps1 exec; no eval of user input; install.sh (Iteration 2, FR-007/FR-014) verifies pwsh and never auto-installs it.` | `false` | `Closeout: the platform-agnostic security controls (bin-dir confinement, missing-dir-needs-Force, no shell-profile mutation, Windows no-op) are unit-test-verified (installer decision matrix). The Unix RUNTIME proof (real symlink write into ~/.local/bin, the curl\|sh bootstrap, live pwsh -ExecutionPolicy Bypass exec) has NOT executed yet — bash -n is syntax-only, install.sh does not exist yet — so this stays pending-post-implementation. It is maintainer-approved Iteration 2 scope (FR-015 release gate, T011 CI), gating release not this closeout; Blocking:false for THIS iteration by that explicit verdict. Trust boundary = install-time fs writes + curl\|sh; no secrets; only network call is Install-Module from PSGallery; user-scoped bin dir, no sudo.` | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `pwsh missing -> non-zero + clear "PowerShell Core (pwsh) is required" + install hint (FR-004); missing bin dir without -Force -> refuse (FR-006); bootstrap aborts if pwsh absent; installer prints installed commands + PATH warning. Missing-bin-dir refusal is unit-tested (T008); the pwsh-missing wrapper path is template-asserted via bash -n only (runtime exec deferred).` | `false` | `Closeout: the installer failure paths (missing-dir refusal, PATH warn-only, Windows no-op) are unit-test-verified. The wrapper RUNTIME failure paths (actual pwsh-missing exit-127 + message, exit-code propagation through a real exec) have NOT run — bash -n is syntax-only, not the runtime verdict — so this stays pending-post-implementation. Maintainer-approved Iteration 2 scope (T011 Ubuntu/macOS CI), gating release not this closeout; Blocking:false for THIS iteration by that verdict. No silent failure by design.` | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `runtime-evidence` | `recorded` | `The generator is deterministic (byte-identical re-run) and the installer idempotency DECISION (re-run yields skip/replace, never duplicate/partial state) + -WhatIf no-op are exercised by executed unit tests T005 (generator idempotency) + T008 (installer idempotency + dry-run), which run the real scripts on Windows.` | `true` | `Idempotency is a property of the generator output + the installer decision plan, both of which execute and are asserted in Iteration 1 (recorded — not deferred). Network retry/reconnect/recovery is N/A: Install-Module is a user-re-runnable one-shot; no long-lived connections or transactional state. (The trivial on-disk symlink re-creation under the skip plan is exercised by Iteration 2 CI.)` | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `FR -> named-test mapping (tasks.md Traceability Matrix); Iteration-1 negative paths asserted (missing-bin-dir, unknown-option passthrough, all four drift modes); 22 assertion-driven checks over the real scripts; mechanical findings 0. The pwsh-missing negative path + Ubuntu/macOS CI are the authoritative RUNTIME surface, deferred to Iteration 2 (T011).` | `false` | `Closeout: Iteration-1 test integrity is verified (assertion-driven not smoke; negative paths for the platform-agnostic surfaces; tests run the real scripts). The cross-platform runtime negative paths (pwsh-missing exec, wrapper run on Ubuntu/macOS) have NOT run — so this stays pending-post-implementation. Maintainer-approved Iteration 2 scope (T011), gating release not this closeout; Blocking:false for THIS iteration by that verdict. Git-Bash-on-Windows is a development proxy, not the verdict.` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `No server, SLO, telemetry pipeline, oncall surface, or operational dependency ships in this iteration — it is a CLI wrapper generator + installer. There is no runtime service to operate.` | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/140-unix-native-install/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- Planning-time origin: all concerns carried planning-time analysis + expected controls at the pre-implementation gate.
- Closeout dispositions (2026-06-02, review-signoff **APPROVE WITH DEFERRED RUNTIME PROOF**), set per-concern by the "did this concern's evidence actually execute?" test:
  - `retry-idempotency-requirements` → runtime evidence **recorded** (generator determinism T005 + installer-decision idempotency T008 executed the real scripts on Windows; no Unix-only dimension).
  - `security-surface`, `error-handling-expectations`, `test-integrity-targets` → platform-agnostic controls unit-test-verified, but the Unix RUNTIME proof has **not executed** (bash -n is syntax-only; install.sh does not exist yet). Runtime Evidence Status stays `pending-post-implementation` (truthfully not-yet-recorded — deliberately **not** `recorded`, **not** `not-needed`). `Blocking: false` for THIS iteration because the maintainer reclassified the Unix runtime as Iteration 2 scope; it gates feature release (FR-015), not Iteration-1 closeout.
  - `operational-resilience-concerns` → `not-applicable` (no service ships).
- **Iteration 2 obligation (must not evaporate)**: Iteration 2's hardening gate MUST re-raise `security-surface`, `error-handling-expectations`, and `test-integrity-targets` as `Blocking: true` and close them only with `runtime-evidence` / `recorded` from the Ubuntu/macOS CI lane (T011) + the greenfield/brownfield release gate (FR-015). Tracked in spec FR-015, tasks `T011`, and `retro.md` → Signals for Next Iteration.
- Verdict stays `ready`: every concern is `addressed` or `not-applicable`; no `deferred-with-approval` rows, so no gate-level Approval Ref is present (required to be absent at `ready`).
