# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/140-unix-native-install/spec.md`
**Iteration Ref**: `specs/140-unix-native-install/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Crew coordinator (planning-time)
**Reviewed At**: 2026-06-02T07:10:00Z

<!--
  Concern Review schema (validator-enforced):
  - Status MUST be one of: `addressed` | `not-applicable` | `deferred-with-approval`.
  - `addressed`: EvidenceBasis = `planning-time-analysis`, RuntimeEvidenceStatus = `pending-post-implementation`, ExpectedControls = concrete controls.
  - `not-applicable`: EvidenceBasis = `not-applicable`, RuntimeEvidenceStatus = `not-needed`, ExpectedControls = `—`. Rationale explains WHY.
  - Overall Verdict is `ready` when every concern is addressed/not-applicable/deferred-with-approval; else `blocked`.
  - Iteration-1 closeout commitment: security-surface / error-handling / test-integrity are re-raised here as Blocking:true and close only with `recorded` runtime evidence.
-->

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `install.sh installs pwsh ONLY from the vendor-recommended source (Microsoft apt repo + its verified signing key; Homebrew on macOS = Iter 3) — never an ad-hoc curl\|bash of an untrusted script; the ONLY trusted curl\|sh is the Specrew bootstrap the user explicitly invoked. Install-only-if-absent (prefer an existing working pwsh; never clobber/upgrade silently). Idempotent repo-add (re-run adds no duplicate apt source). Privilege escalation is surfaced through the normal sudo / package-manager prompt — never silent; the curl\|sh non-tty elevation path is handled explicitly (FR-016 / T012 / T013 / T016).` | `true` | `Auto-install is the new load-bearing trust surface: it adds a package repository, imports a signing key, and elevates to root. The controls are vendor-source-only provenance, key trust, install-if-absent, idempotent repo-add, and surfaced (never silent) elevation. Re-raised Blocking:true per the Iteration-1 closeout commitment; closes only with recorded Ubuntu-CI runtime evidence.` | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Unsupported platform/package manager OR a failed pwsh auto-install -> fail CLOSED with a clear message + a link to manual dependency-install docs; NO partial/half-installed state reported as success (FR-007/FR-016). Detection runs before any mutation (T011). Wrapper pwsh-missing-at-runtime still errors non-zero with a hint and never installs pwsh (FR-004, unchanged). Positive + negative paths asserted on Ubuntu CI (T014) and via os-release fixtures (T011).` | `true` | `An installer that elevates and adds repos must never leave a broken half-state or claim success on failure. Fail-closed + manual-docs fallback + detect-before-mutate are the controls. Re-raised Blocking:true; closes only with recorded runtime evidence.` | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `install.sh is idempotent: re-running adds no duplicate apt source, skips pwsh install when a working pwsh is present, and re-runs Install-Module + install-shell-wrappers without duplication/partial state. Verified by the Ubuntu CI re-run (T014) + os-release fixtures (T011).` | `false` | `Idempotency is required and Ubuntu-CI-verified; network retry/reconnect is N/A (apt + Install-Module are user-re-runnable one-shots, no long-lived connection or transactional state). Not a hard closure gate on its own — folded under security/error-handling.` | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Per-path CI-vs-manual proof is enumerated (no blanket "CI-validated"): (a) Ubuntu/Debian apt auto-install END-TO-END = CI/clean-no-pwsh-container-proven THIS iteration (T014); (b) Ubuntu wrapper runtime (forwarding/symlink/pwsh-missing/passthrough) = CI-proven this iteration (T014); (c) os-release detection + fail-closed = table-driven-fixture-proven (T011); (d) macOS/Homebrew + interactive-sudo (real user, non-tty) = NOT CI-reachable -> Iteration 3 / MANUAL proof, explicitly out of this iteration's claim. Git-Bash-on-Windows is a development proxy, never the verdict.` | `true` | `The project's anti-form discipline applied to the new surface: each auto-install path is labeled CI-proven vs manual so closeout cannot claim runtime proof CI never produced. Re-raised Blocking:true; closes only with recorded Ubuntu-CI evidence for the in-scope (Ubuntu) paths.` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `No server, SLO, telemetry, oncall, or runtime service ships — the deliverable is a one-shot installer + CI. There is nothing to operate.` | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/002/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/002/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/140-unix-native-install/iterations/002/quality/lenses/test-integrity.md` |

## Notes

- Planning-time gate: each concern carries planning-time analysis + expected controls; runtime evidence is recorded at implementation/closeout. The three re-raised concerns (`security-surface`, `error-handling-expectations`, `test-integrity-targets`) are `Blocking: true` and will close only with `recorded` Ubuntu-CI runtime evidence — discharging the Iteration-1 deferral on the in-scope (Ubuntu) paths.
- Scope honesty: macOS/Homebrew + interactive-`sudo` auto-install is **not** claimed by this iteration; it is Iteration 3 manual/CI proof. The `test-integrity-targets` controls enumerate this so closeout cannot overstate coverage.
- Verdict `ready`: four concerns `addressed`, one `not-applicable`; no `deferred-with-approval` rows, so no gate-level Approval Ref is present (required absent at `ready`).
