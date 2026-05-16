# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/018-velocity-dashboard-visual-richness/spec.md`
**Iteration Ref**: `specs/018-velocity-dashboard-visual-richness/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: ready
**Approval Ref**: `—`
**Reviewed By**: Alon Fliess
**Reviewed At**: 2026-05-15
**Post-Implementation Verification**: complete
**Verified At**: 2026-05-15

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Keep the slice limited to repository-local PowerShell, Markdown, YAML, JSON, and git-tracked artifact generation. Do not introduce secrets, network I/O, or new trust boundaries. | `false` | Feature 018 stays inside local renderer, CLI, validator, closeout scaffold, fixture, and documentation surfaces. The execution scaffold introduces no new credential, auth, or external service behavior. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Missing roadmap/history inputs, unsupported terminal capability, malformed fixture data, or closeout-artifact write issues must degrade to bounded warnings or truthful empty states rather than crashes or silent success. | `true` | Replay stayed warning-oriented and bounded; the feature did not introduce crash-on-missing-data behavior. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `runtime-evidence` | `recorded` | Re-running `specrew where`, `specrew status`, or the closeout scaffold paths must be safe on the same tree and must not silently rewrite historical dashboard artifacts. | `true` | Closeout replay kept historical artifact immutability intact while preserving parity with live rendering. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Runtime proof must come from the real unit, integration, render-budget, and validator entrypoints named in `tasks.md`, including rich-mode, monochrome-mode, artifact, and replay-path fixtures. | `true` | The dashboard-specific replay lane is green across the named unit, integration, and budget entrypoints. | — |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | Live rendering, stored snapshots, and validator/scaffold warnings must stay additive and operator-readable, especially when rich-mode capability is absent or a closeout artifact is missing. Diagnostics must stay truthful about why fallback occurred. | `true` | Rich mode remained additive; fallback warnings now stay bounded to explicit operator controls and directly verifiable terminal constraints. | — |
| `terminal-capability-decision-precedence` | `terminal-compatibility` | `addressed` | `runtime-evidence` | `recorded` | Verification must prove one deterministic precedence chain across `--ASCII`, `NO_UNICODE`, `TERM=dumb`, UTF-8 capability, `LANG`, and Windows virtual-terminal checks, with the same result from `specrew where`, `specrew status`, and `specrew-where.ps1`. | `true` | Shared render-profile helpers now own the precedence chain for all entry points, and the misleading `[Console]::IsOutputRedirected` fallback branch has been removed. | — |
| `windows-vt-fallback-truthfulness` | `compatibility` | `addressed` | `runtime-evidence` | `recorded` | Verification must show that missing `$Host.UI.SupportsVirtualTerminal` support disables ANSI emphasis cleanly while preserving the same underlying meaning, markers, and sparkline intent in ASCII-safe form. | `true` | Monochrome replay proved semantic parity without ANSI dependence. | — |
| `render-budget-stop-ship-evidence` | `performance` | `addressed` | `runtime-evidence` | `recorded` | Verification must record a green `<= 1.5s` render-budget result on the representative 16-feature repository and treat a miss as stop-ship evidence until explicitly reconciled. | `true` | The render-budget harness passed and live current-shell `specrew where --no-color` on the Specrew repo measured 1043.86 ms / 1028.64 ms / 1040.12 ms after one warmup run. | — |
| `ansi-stripping-with-unicode-preservation` | `artifact-integrity` | `addressed` | `runtime-evidence` | `recorded` | Verification must prove stored dashboard artifacts strip ANSI escape sequences while preserving readable Unicode glyphs and line endings across the closeout/validator path. | `true` | Artifact content now strips ANSI via regex while preserving Unicode glyphs, and validator coverage checks for regressions. | — |
| `closeout-dashboard-artifact-rendering` | `governance-compatibility` | `addressed` | `runtime-evidence` | `recorded` | Verification must show that both iteration-closeout and feature-closeout dashboard scaffolds apply the same rendering/fallback rules, preserve immutability, and remain validator-compatible. | `true` | Scaffold scripts now pass `CaptureKind` only when supported, preserving compatibility and parity. | — |
| `flag-surface-and-doc-guidance-alignment` | `documentation-accuracy` | `addressed` | `runtime-evidence` | `recorded` | Verification should confirm that help text, docs, README, and manual quickstart all describe `--ASCII`, `--RecentCount`, `--BarWidth`, eligibility rules, and snapshot behavior exactly as implemented. | `false` | User-facing guidance now matches the shipped CLI surface and snapshot rules. | — |
| `roadmap-density-and-empty-state-clarity` | `user-experience` | `addressed` | `runtime-evidence` | `recorded` | Verification should confirm roadmap descriptions, empty states, and 80-character truncation remain explicit and readable in both rich and monochrome modes. | `false` | Unit and integration replay kept roadmap clarity bounded in both render modes. | — |

## Risk-Tier Verification Focus

### High-Risk Concerns

| Concern Label | Expected Verification Focus |
| --- | --- |
| `terminal-capability-decision-precedence` | Cross-entry-point precedence proof for `--ASCII`, environment overrides, `TERM=dumb`, UTF-8 capability, and Windows VT eligibility |
| `windows-vt-fallback-truthfulness` | Windows fallback replay proving semantic parity without ANSI dependence |
| `render-budget-stop-ship-evidence` | Measured `<= 1.5s` render-budget result on the representative 16-feature repository |

### Medium-Risk Concerns

| Concern Label | Expected Verification Focus |
| --- | --- |
| `ansi-stripping-with-unicode-preservation` | Stored snapshot checks proving ANSI removal with Unicode glyph retention |
| `closeout-dashboard-artifact-rendering` | Iteration-closeout and feature-closeout scaffold replay against the richer rendering contract |

### Lower-Risk Concerns

| Concern Label | Expected Verification Focus |
| --- | --- |
| `flag-surface-and-doc-guidance-alignment` | Help/docs/manual sync for rich mode defaults, overrides, and snapshot semantics |
| `roadmap-density-and-empty-state-clarity` | Rich/monochrome output readability for roadmap descriptions and empty-state guidance |

## Pre-Implementation Planning Evidence

### Requirement Traceability

- **Shared rendering policy and terminal eligibility**: FR-004, FR-005, FR-008, FR-014, FR-019 via T003-T005 and T016-T019
- **Rich dashboard density and sparkline**: FR-006 through FR-013 via T006-T013
- **Feature 017 compatibility and artifact parity**: FR-001, FR-004, FR-010, FR-015, FR-016, FR-017, FR-018 via T014-T025 and T028-T029
- **Documentation and manual verification**: FR-019, FR-020 via T026-T027 and T030

### Stack-Ready Analysis

| Stack Surface | Path | In Scope | Evidence |
| --- | --- | --- | --- |
| `dashboard-renderer-core` | `scripts/internal/dashboard-renderer.ps1` | Yes | T004-T019 |
| `dashboard-cli-surface` | `scripts/specrew.ps1`, `scripts/specrew-where.ps1` | Yes | T003-T004 |
| `closeout-and-validator-paths` | `extensions/specrew-speckit/scripts/*.ps1`, `.specify/extensions/specrew-speckit/scripts/*.ps1` | Yes | T020, T022-T023, T029 |
| `fixture-replay-harness` | `tests/unit/*.ps1`, `tests/integration/*.ps1`, `tests/integration/fixtures/feature-018-dashboard/**` | Yes | T006-T007, T013-T015, T021-T024, T028 |
| `docs-and-discovery` | `docs/dashboard-guide.md`, `README.md`, `tests/manual/feature-017-dashboard-quickstart.md`, `specs/018-velocity-dashboard-visual-richness/quickstart.md` | Yes | T026-T027, T030 |

## Deferral Note

- Runtime evidence is recorded for the implementation boundary.
- Review is now accepted in the linked `review.md`; this artifact still does not claim retro completion.
- No `retro.md` placeholder should be created before that later boundary is explicitly authorized.

## Hardening-Gate Status

**Overall Verdict**: ready

**Scope**: Iteration 001 pre-implementation readiness for the full Feature 018 single-iteration slice,
covering renderer richness, fallback truthfulness, snapshot integrity, closeout parity, regression safety,
performance budget preservation, and operator guidance.

**Implementation Summary**: The single-iteration execution slice completed with green dashboard-specific
replay, live current-shell render timing inside NFR-001, ANSI-free persisted artifacts, closeout
scaffold parity preserved, and bounded repair `R-018-V2` implemented without widening scope. Deferred
scope remained excluded.

## Sign-Off Evidence

**Authority**: human hardening-gate sign-off and implementation authorization recorded on 2026-05-15 for
Feature 018 Iteration 001  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-15  
**Review-Verdict-Signoff Ref**: `specs/018-velocity-dashboard-visual-richness/iterations/001/review.md`  
**Evidence Statement**: The iteration-scoped hardening gate preserved the approved concern set through
implementation, and post-implementation verification is complete based on the green replay lane,
validator updates, closeout-parity replay, live current-shell timing evidence, repaired direct-entrypoint
UTF-8 priming proof, and the accepted review verdict that records Alon Fliess's direct-terminal rich-mode
confirmation after `R-018-V2`. The deferred `roadmap-phase-status-marker-uniformity` observation is logged
as a cosmetic follow-up in `.specrew/quality/known-traps.md` and does not reopen this gate.

---

**Hardening-Gate Status**: signed off on 2026-05-15 and verified post-implementation on 2026-05-15; the
accepted review-verdict-signoff now records absorbed `R-018-V1` / `R-018-V2` evidence plus direct-terminal
rich-mode confirmation, and retro remains unopened pending explicit authorization.
