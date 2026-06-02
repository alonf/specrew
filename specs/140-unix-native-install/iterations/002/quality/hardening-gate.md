# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/140-unix-native-install/spec.md`
**Iteration Ref**: `specs/140-unix-native-install/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Crew coordinator (planning-time) + closeout disposition (review-signoff APPROVE)
**Reviewed At**: 2026-06-02T10:45:00Z

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
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | `install.sh installs pwsh ONLY from the vendor-recommended source (Microsoft apt repo + its verified signing key; Homebrew on macOS = Iter 3) — never an ad-hoc curl\|bash of an untrusted script; the ONLY trusted curl\|sh is the Specrew bootstrap the user explicitly invoked. Install-only-if-absent (prefer an existing working pwsh; never clobber/upgrade silently). Idempotent repo-add (re-run adds no duplicate apt source). Privilege escalation is surfaced through the normal sudo / package-manager prompt — never silent; the curl\|sh non-tty elevation path is decided in T010 and handled explicitly (FR-016 / T010 / T013 / T014 / T017).` | `true` | `Auto-install is the new load-bearing trust surface: it adds a package repository, imports a signing key, and elevates to root. The controls are vendor-source-only provenance, key trust, install-if-absent, idempotent repo-add, and surfaced (never silent) elevation. Re-raised Blocking:true per the Iteration-1 closeout commitment; closes with recorded Ubuntu-CI runtime evidence. RECORDED SCOPE: vendor-source install (MS repo), fail-closed detection (5/5), and the ROOT-path elevation ran on Ubuntu CI. The NON-ROOT surfaced-sudo path and the re-run idempotent-repo-add are DESIGN-asserted only (the single root CI run took the $SUDO-empty path and ran once) — manual / Iteration-3, consistent with the test-integrity CI-vs-manual enumeration and the retry-idempotency concern.` | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | `Unsupported platform/package manager OR a failed pwsh auto-install -> fail CLOSED with a clear message + a link to manual dependency-install docs; NO partial/half-installed state reported as success (FR-007/FR-016). Detection runs before any mutation (T012). Wrapper pwsh-missing-at-runtime still errors non-zero with a hint and never installs pwsh (FR-004, unchanged). Positive + negative paths asserted on Ubuntu CI (T015) and via os-release fixtures (T012).` | `true` | `An installer that elevates and adds repos must never leave a broken half-state or claim success on failure. Fail-closed + manual-docs fallback + detect-before-mutate are the controls. Re-raised Blocking:true; closes only with recorded runtime evidence.` | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `install.sh is DESIGNED idempotent: re-running adds no duplicate apt source, skips pwsh install when a working pwsh is present, re-runs Install-Module + install-shell-wrappers without duplication. The single CI install (T015) exercised the MODULE install-if-absent (pre-seeded -> "already available, skipping the gallery") but NOT a second run / apt repo-add idempotency / pwsh-skip-if-present (pwsh was absent, so the install path ran). Full idempotency proof — a second install.sh run asserting no duplicate apt source — is a cheap Iteration-3 add.` | `false` | `Idempotency is required and DESIGN-asserted; not fully CI-exercised this iteration (single run, pwsh absent, root). Network retry/reconnect is N/A (apt + Install-Module are user-re-runnable one-shots). Blocking:false — does not gate closure; full runtime proof deferred to Iteration 3.` | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | `Per-path CI-vs-manual proof is enumerated (no blanket "CI-validated"): (a) **Ubuntu** apt auto-install END-TO-END = CI/clean-no-pwsh-container-proven THIS iteration (T015) [Debian = detection-proven + shared code path; PMC install not exercised]; (b) Ubuntu wrapper runtime (forwarding/symlink/pwsh-missing/passthrough) = CI-proven this iteration (T015); (c) os-release detection + fail-closed = table-driven-fixture-proven (T012); (d) macOS/Homebrew + interactive-sudo (real user, non-tty) = NOT CI-reachable -> Iteration 3 / MANUAL proof, explicitly out of this iteration's claim. Git-Bash-on-Windows is a development proxy, never the verdict.` | `true` | `The project's anti-form discipline applied to the new surface: each auto-install path is labeled CI-proven vs manual so closeout cannot claim runtime proof CI never produced. Re-raised Blocking:true; closes only with recorded Ubuntu-CI evidence for the in-scope (Ubuntu) paths.` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `No server, SLO, telemetry, oncall, or runtime service ships — the deliverable is a one-shot installer + CI. There is nothing to operate.` | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/002/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/002/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/140-unix-native-install/iterations/002/quality/lenses/test-integrity.md` |

## Notes

- **Closeout (2026-06-02, review-signoff APPROVE)**: the four addressed concerns are flipped to `runtime-evidence`/`recorded` against **Ubuntu CI run 26812981387** (clean no-`pwsh` container end-to-end; wrapper runtime `4 passed, 0 failed`; detection/fail-closed `5 passed`) — the three `Blocking: true` concerns (`security-surface`, `error-handling-expectations`, `test-integrity-targets`) are thereby satisfied with REAL recorded runtime evidence, **discharging the Iteration-1 deferral on the Ubuntu paths** (the honest inverse of Iteration 1, which recorded nothing and deferred).
- **Scope of "recorded" + Iteration-3 re-raise**: `recorded` covers the **Ubuntu in-scope** controls only. The **macOS/Homebrew** supply-chain, **interactive-`sudo`** (real human, non-tty), and **`--prerelease`** provenance are NEW surfaces, unproven until Iteration 3. The Iteration-3 hardening gate MUST re-raise `security-surface` / `error-handling-expectations` / `test-integrity-targets` for those surfaces as `Blocking: true`, closeable only with their own recorded proof (a published beta + a macOS surface). The `test-integrity-targets` controls enumerate the CI-vs-manual split so this closeout does not overstate coverage.
- Verdict `ready`: four concerns `addressed`, one `not-applicable`; no `deferred-with-approval` rows, so no gate-level Approval Ref is present (required absent at `ready`).
