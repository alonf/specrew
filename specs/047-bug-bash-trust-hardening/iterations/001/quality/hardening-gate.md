# Hardening Gate: Iteration 001

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/047-bug-bash-trust-hardening/spec.md`  
**Iteration Ref**: `specs/047-bug-bash-trust-hardening/iterations/001`  
**Requested Review Class**: `phase-1-custom-composition`  
**Effective Review Class**: phase-1-custom-composition  
**Overall Verdict**: ready  
**Approval Ref**: —  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-26  
**Post-Implementation Verification**: ⏳ PENDING (planning-time gate)  
**Verified At**: —

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | — | `false` | F-047 is lifecycle-tooling: validator WARN rules, a scaffolder skeleton, prose audits of `installed-instructions/`, a content-based skill-catalog check, and a `tasks-progress.yml` regeneration. No authentication boundaries, privilege checks, secret handling, or user-controlled trust crossings are introduced. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-analysis` | `planned` | `Test-SpecrewHandoffBlockPresent` returns `$false` on absent/unparseable input and never throws (per contract); the internal-reference regex tolerates empty prose; the `tasks-progress.yml` regenerator handles missing/malformed `tasks.md`/`state.md` by surfacing divergence rather than crashing. | `false` | Planning-time analysis: every new code path has a defined non-throwing failure mode; integration fixtures will exercise empty/malformed inputs. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-analysis` | `planned` | All new validator checks are stateless (pure detection over commit/file/session inputs). `tasks-progress.yml` regeneration derives state from `tasks.md` each run, so repeated `specrew start` invocations converge to the same output. | `false` | Planning-time analysis: no persisted mutable state is introduced; re-running validation or regeneration is safe and deterministic. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-analysis` | `planned` | Tests-first per item: each FR has a fixture asserting on real runtime output (WARN findings, scaffolder content, regenerated YAML) — not artifact-shape checks. Negative fixtures guard against false positives (no-WARN when a Mermaid block is present; version/year tokens do not trip the internal-reference regex). | `true` | Planning-time analysis: the FR→test map (plan.md §5) binds every requirement to an assertion-driven fixture; the post-compaction case is a dedicated regression lock (Item 2). | — |
| `operational-resilience-concerns` | `operational-resilience` | `addressed` | `planning-analysis` | `planned` | All new detection is WARN-only (FR-016): existing repos do not begin FAILing governance on update. Mirror parity (FR-014) keeps `extensions/` and `.specify/extensions/` from diverging. Internal-reference regex is anchored to avoid false positives. | `false` | Planning-time analysis: backward compatibility is the dominant resilience concern for a tooling patch shipped to existing downstream repos; WARN-only + parity + anchored regex address it. | — |
| `backward-compatibility-warn-only` | `specification-compliance` | `addressed` | `planning-analysis` | `planned` | Every new validator rule (handoff-presence, dashboard-diagnosis, wrong-location, mermaid-absence, internal-reference) emits WARN; none escalate to FAIL. | `true` | Planning-time analysis: FR-016 is a hard design constraint; fixtures assert severity == WARN. | — |
| `regex-false-positive-safety` | `specification-compliance` | `addressed` | `planning-analysis` | `planned` | The `\bF-\d{3,}\b` / `\bProposal \d{3,}\b` / `\bFeature \d{3,}\b` patterns are anchored to internal-reference prefixes + ≥3 digits and exclude version strings (`v0.27.3`) and years. | `false` | Planning-time analysis: negative fixtures (T008) lock the no-false-positive behavior. | — |
| `mirror-parity-integrity` | `governance-compliance` | `addressed` | `planning-analysis` | `planned` | Every `extensions/specrew-speckit/scripts/*` edit is mirrored byte-identical to `.specify/extensions/...`, verified by `diff -q` at review (T018). | `true` | Planning-time analysis: mirror divergence is the recurring failure mode for this script family; T018 makes parity a review gate. | — |

## Planning Evidence Notes

- This is a planning-time gate: `Runtime Evidence Status` is `planned` for all addressed concerns; runtime evidence will be recorded after implementation.
- The five canonical concerns (`security-surface`, `error-handling-expectations`, `retry-idempotency-requirements`, `test-integrity-targets`, `operational-resilience-concerns`) appear first in the required order.
- Three feature-specific concerns follow: `backward-compatibility-warn-only`, `regex-false-positive-safety`, `mirror-parity-integrity`.
- Not-applicable risk dimensions per the resolved Phase 1 profile: concurrency-correctness, resiliency, retry-idempotency-and-recovery (no shared-state/realtime/retry workflow). The `retry-idempotency-requirements` concern is nonetheless addressed because the new checks must be safely re-runnable.

## Hardening-Gate Status

**Overall Verdict**: ready — planning artifacts (spec, plan, tasks, data-model, contract, review-diagrams, findings skeleton) are complete and traceable; all hardening concerns are addressed or not-applicable at planning time, pending human before-implement approval.

**Scope**: Iteration 001 — the 7-item v0.27.3 trust-hardening bundle (T001-T019, 20 story_points).
