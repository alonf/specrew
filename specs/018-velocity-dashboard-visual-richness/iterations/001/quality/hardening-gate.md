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
**Post-Implementation Verification**: pending-post-implementation

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Keep the slice limited to repository-local PowerShell, Markdown, YAML, JSON, and git-tracked artifact generation. Do not introduce secrets, network I/O, or new trust boundaries. | `false` | Feature 018 stays inside local renderer, CLI, validator, closeout scaffold, fixture, and documentation surfaces. The execution scaffold introduces no new credential, auth, or external service behavior. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Missing roadmap/history inputs, unsupported terminal capability, malformed fixture data, or closeout-artifact write issues must degrade to bounded warnings or truthful empty states rather than crashes or silent success. | `true` | The feature’s value depends on graceful degradation. Planning now fixes the expectation that the renderer and scaffold scripts keep warning-oriented behavior when data or terminal capability is incomplete. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Re-running `specrew where`, `specrew status`, or the closeout scaffold paths must be safe on the same tree and must not silently rewrite historical dashboard artifacts. | `true` | Snapshot immutability is part of the shipped contract. Planning records repeat-safe execution as a required control before implementation begins. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Runtime proof must come from the real unit, integration, render-budget, and validator entrypoints named in `tasks.md`, including rich-mode, monochrome-mode, artifact, and replay-path fixtures. | `true` | This slice changes presentation, fallback behavior, closeout artifacts, and validator expectations. Planning therefore treats the replay path and fixture coverage as implementation-blocking quality evidence. | — |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Live rendering, stored snapshots, and validator/scaffold warnings must stay additive and operator-readable, especially when rich-mode capability is absent or a closeout artifact is missing. | `true` | The dashboard is a trust surface. Planning makes operator-facing resilience explicit so the feature does not trade clarity for polish. | — |
| `terminal-capability-decision-precedence` | `terminal-compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Verification must prove one deterministic precedence chain across `--ASCII`, `NO_UNICODE`, redirected output, UTF-8 capability, `LANG`, and Windows virtual-terminal checks, with the same result from `specrew where`, `specrew status`, and `specrew-where.ps1`. | `true` | This is the reviewer’s first explicit concern. If precedence diverges across entry points or capability signals, the default-rich promise becomes untrustworthy immediately. | — |
| `windows-vt-fallback-truthfulness` | `compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Verification must show that missing `$Host.UI.SupportsVirtualTerminal` support disables ANSI emphasis cleanly while preserving the same underlying meaning, markers, and sparkline intent in ASCII-safe form. | `true` | This is the reviewer’s second explicit concern. Windows fallback is the highest-risk real-world degradation path for this richer console feature. | — |
| `render-budget-stop-ship-evidence` | `performance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Verification must record a green `<= 1.5s` render-budget result on the representative 16-feature repository and treat a miss as stop-ship evidence until explicitly reconciled. | `true` | This is the reviewer’s third explicit concern and the main performance boundary for the feature. Richer output is not acceptable if it violates NFR-001. | — |
| `ansi-stripping-with-unicode-preservation` | `artifact-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Verification must prove stored dashboard artifacts strip ANSI escape sequences while preserving readable Unicode glyphs and line endings across the closeout/validator path. | `true` | This is the reviewer’s fourth explicit concern. The persisted artifact contract is central because the richer mode intentionally adds ANSI and Unicode in live output. | — |
| `closeout-dashboard-artifact-rendering` | `governance-compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Verification must show that both iteration-closeout and feature-closeout dashboard scaffolds apply the same rendering/fallback rules, preserve immutability, and remain validator-compatible. | `true` | This is the reviewer’s fifth explicit concern. The richer presentation must not fork the closeout path away from the live dashboard contract. | — |
| `flag-surface-and-doc-guidance-alignment` | `documentation-accuracy` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Verification should confirm that help text, docs, README, and manual quickstart all describe `--ASCII`, `--RecentCount`, `--BarWidth`, eligibility rules, and snapshot behavior exactly as implemented. | `false` | This is a lower-risk but still necessary follow-through concern. Operators cannot trust the richer dashboard if the control surface is documented inaccurately. | — |
| `roadmap-density-and-empty-state-clarity` | `user-experience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Verification should confirm roadmap descriptions, empty states, and 80-character truncation remain explicit and readable in both rich and monochrome modes. | `false` | This is a lower-risk clarity concern that protects the feature’s one-screen comprehension goal without widening scope beyond the approved presentation layer. | — |

## Risk-Tier Verification Focus

### High-Risk Concerns

| Concern Label | Expected Verification Focus |
| --- | --- |
| `terminal-capability-decision-precedence` | Cross-entry-point precedence proof for `--ASCII`, environment overrides, redirected output, UTF-8 capability, and Windows VT eligibility |
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

- The review boundary comes later. This artifact records planning-time concerns and expected controls only.
- Runtime evidence will be recorded here after implementation, review, and validation replay are actually completed.
- No `review.md` or `retro.md` placeholder should be created at this boundary.

## Hardening-Gate Status

**Overall Verdict**: ready

**Scope**: Iteration 001 pre-implementation readiness for the full Feature 018 single-iteration slice,
covering renderer richness, fallback truthfulness, snapshot integrity, closeout parity, regression safety,
performance budget preservation, and operator guidance.

**Pre-Implementation Planning Summary**: Planning is complete for the single-iteration execution slice.
The five canonical concerns appear first in the required order, the reviewer’s five explicit concern labels
are preserved verbatim as additional blocking rows, and two lower-risk follow-through concerns capture the
docs/clarity work without reopening scope. Runtime evidence is intentionally deferred to implementation and
later review.

## Sign-Off Evidence

**Authority**: human hardening-gate sign-off and implementation authorization recorded on 2026-05-15 for
Feature 018 Iteration 001  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-15  
**Evidence Statement**: The iteration-scoped hardening gate now exists under
`specs/018-velocity-dashboard-visual-richness/iterations/001/quality/hardening-gate.md`, carries the five
canonical concerns first, preserves the reviewer-requested labels
(`terminal-capability-decision-precedence`, `windows-vt-fallback-truthfulness`,
`render-budget-stop-ship-evidence`, `ansi-stripping-with-unicode-preservation`,
`closeout-dashboard-artifact-rendering`), and keeps the review boundary separate from this planning-only
execution scaffold.

---

**Hardening-Gate Planning Status**: signed off on 2026-05-15; bundled implementation authorization is
already recorded, but execution still waits on `/speckit.specrew-speckit.before-implement`.
