# Hardening Gate: Iteration 003

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/140-unix-native-install/spec.md`
**Iteration Ref**: `specs/140-unix-native-install/iterations/003`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Crew coordinator (planning-time)
**Reviewed At**: 2026-06-02T20:30:00Z

<!--
  Concern Review schema (validator-enforced):
  - Status MUST be one of: `addressed` | `not-applicable` | `deferred-with-approval`.
  - `addressed`: EvidenceBasis = `planning-time-analysis`, RuntimeEvidenceStatus = `pending-post-implementation`, ExpectedControls = concrete controls.
  - `not-applicable`: EvidenceBasis = `not-applicable`, RuntimeEvidenceStatus = `not-needed`, ExpectedControls = `—`. Rationale explains WHY.
  - `deferred-with-approval`: same evidence fields as `addressed`, AND Approval references a recorded human approval.
  - Overall Verdict is `ready` when every concern is addressed/not-applicable/deferred-with-approval; else `blocked`.
  - Iteration-2 closeout commitment: re-raise security-surface / error-handling / test-integrity as Blocking:true for the NEW macOS + prerelease surfaces; close only with recorded evidence (CI where reachable, manual where not).
-->

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | `macOS pwsh auto-install (T018) uses ONLY the vendor-recommended source — Homebrew (brew install --cask powershell) — never an ad-hoc curl\|bash of an untrusted script; the ONLY trusted curl\|sh remains the Specrew bootstrap the user explicitly invoked. brew runs AS THE INVOKING USER (never sudo brew). install-only-if-absent (prefer an existing working pwsh). idempotent re-run. For --prerelease (T019): -AllowPrerelease fetches the PUBLISHED PSGallery beta (same trusted gallery as stable); a version/source mismatch (installed module lacks the specrew wrapper surface) fails closed. Release gate (T024) installs only the maintainer-authorized published beta.` | `true` | `macOS/Homebrew is a NEW supply-chain surface (new package source + a prerelease channel) not covered by Iteration 2's Ubuntu/apt proof. Controls: vendor-source-only provenance, brew-as-user, install-if-absent, idempotent, and prerelease-from-the-trusted-gallery with a fail-closed mismatch check. Re-raised Blocking:true per the Iteration-2 closeout commitment; closes with recorded evidence (macOS wrapper runtime via CI; the install.sh auto-install + prerelease install are MANUAL per test-integrity).` | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | `Homebrew absent (or brew install fails) -> fail CLOSED with a clear message + manual-dependency-docs link; NO partial/half-installed state reported as success (FR-007/FR-016). Detection runs before any mutation. The --prerelease version/source-mismatch (installed module lacks the specrew surface) -> fail closed non-zero with an incompatibility message (FR-017). Wrapper pwsh-missing-at-runtime still errors non-zero with a hint and never installs pwsh (FR-004, unchanged). Positive + negative paths asserted: macOS wrapper runtime + pwsh-missing negative on CI (T020); Homebrew-absent + prerelease-mismatch negatives via the manual proof / unit checks (T021, T019 tests).` | `true` | `An installer that adds a package source and an init path that installs a prerelease must never leave a broken half-state or claim success on failure. Fail-closed + manual-docs fallback + detect-before-mutate + the prerelease mismatch check are the controls. Re-raised Blocking:true for the new surfaces.` | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `install.sh stays idempotent on macOS: re-running skips the pwsh install when a working pwsh is present (install-if-absent), and re-runs install-shell-wrappers without duplication. brew itself is idempotent for an already-installed cask. The --prerelease re-run installs/updates without duplication. Idempotency is proven by the manual re-run in T021 (a second install.sh run asserting no duplicate work).` | `false` | `Idempotency is required and DESIGN-asserted; macOS full re-run proof is MANUAL (T021) since macOS runners cannot give a clean controlled env. Network retry/reconnect is N/A (brew + Install-Module are user-re-runnable one-shots). Blocking:false — does not gate closure.` | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | `Per-path CI-vs-manual proof enumerated (no blanket "CI-validated"): (a) macOS WRAPPER runtime (forwarding/symlink/pwsh-missing/passthrough + specrew version/start --help) = CI-proven via the extended validate-macos job (T020); (b) macOS install.sh Homebrew auto-install END-TO-END (clean no-pwsh) + interactive elevation = NOT CI-reachable on macOS runners -> MANUAL proof (T021); (c) --prerelease install + version/source-mismatch fail-closed = proven at the release gate against a real PUBLISHED beta (T024) [unit-level mismatch check also asserted in T019]; (d) greenfield + brownfield + Spec Kit 0.9.0 = MANUAL on a real macOS host (T024). FR -> named test/evidence mapping recorded in the plan task table. Git-Bash-on-Windows is a development proxy, never the verdict.` | `true` | `The project's anti-form discipline applied to the macOS + prerelease surfaces: each path is labeled CI-proven vs manual so closeout cannot claim runtime proof CI never produced. Re-raised Blocking:true; closes only with the recorded CI (macOS wrapper) + recorded manual (auto-install, prerelease, release gate) evidence.` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `No server, SLO, telemetry, oncall, or runtime service ships — the deliverable is a one-shot installer + docs + CI. There is nothing to operate.` | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/003/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/140-unix-native-install/iterations/003/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/140-unix-native-install/iterations/003/quality/lenses/test-integrity.md` |

## Notes

- **Planning-time gate.** Every concern is `addressed`/`not-applicable` with `planning-time-analysis` /
  `pending-post-implementation` evidence; runtime evidence (lens execution, test counts, mechanical
  findings, the macOS CI run, and the manual macOS proofs) is collected after implementation lands and
  recorded at iteration closeout — the honest inverse of overstating proof up front.
- **Iteration-2 re-raise honored.** The Iteration-2 closeout explicitly required this gate to re-raise
  `security-surface` / `error-handling-expectations` / `test-integrity-targets` as `Blocking: true` for the
  NEW macOS/Homebrew supply-chain, interactive-elevation, and `--prerelease` provenance surfaces. Done.
- **CI-vs-manual split is load-bearing.** macOS wrapper runtime is CI-proven (`validate-macos`, T020); the
  clean `install.sh` Homebrew auto-install, interactive elevation, `--prerelease` install, and the
  greenfield/brownfield release gate are **manual** (T021/T024) — macOS runners cannot provide a clean
  no-`pwsh` env. The `test-integrity-targets` controls enumerate this so closeout cannot overstate coverage.
- Verdict `ready`: four concerns `addressed`, one `not-applicable`; no `deferred-with-approval` rows, so no
  gate-level Approval Ref is present (required absent at `ready`).
- **Closeout (2026-06-03, review-signoff APPROVE — macOS manual WAIVED).** The three `Blocking: true`
  concerns flip to `runtime-evidence`/`recorded`. **RECORDED SCOPE** (real evidence): the `validate-macos`
  CI lane (wrapper runtime + native command surface) + the interactive-`start` **PTY TTY-survival**
  regression (Ubuntu *and* macOS lanes) + the Ubuntu detection/clean-container + `--prerelease` mismatch
  unit checks + the **`0.31.0-beta4` LINUX release-gate validation** (interactive `specrew start` opens;
  `specrew version` → `0.31.0-beta4`; prerelease install from the trusted PSGallery). **WAIVED — NOT
  recorded** (maintainer decision, reactive-fix): the macOS **live** Homebrew `pwsh` auto-install on a clean
  no-`pwsh` Mac + a macOS real-terminal interactive session. `recorded` therefore means *recorded for the
  CI + Linux paths*; the macOS-live paths are waived, not validated. `retry-idempotency-requirements`
  stays `Blocking:false` / pending (macOS full re-run unproven; does not gate closure).
