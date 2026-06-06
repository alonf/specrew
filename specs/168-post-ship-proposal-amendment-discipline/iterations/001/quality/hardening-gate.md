# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/168-post-ship-proposal-amendment-discipline/spec.md`
**Iteration Ref**: `specs/168-post-ship-proposal-amendment-discipline/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `tasks -> before-implement human approval, 2026-06-06`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-06T12:30:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `fr-006-delta-from-shipped-behavior` | `governance-integrity` | `addressed` | `planning-time-analysis` | `pending-implementation` | Every shipped-proposal amendment implementation path must state amendment id or superseding proposal, delta summary, shipped behavior to preserve, and tests required before review signoff. | `true` | FR-006 is release-blocking because the feature exists to prevent future crews from treating a shipped proposal body as fresh execution truth. The iteration plan and tasks carry this requirement into implementation and review evidence. | `human-approved` |
| `fr-015-no-shipped-body-rewrite` | `scope-control` | `addressed` | `planning-time-analysis` | `pending-implementation` | Use synthetic fixtures for shipped/superseded proposal examples; do not rewrite real shipped proposal bodies, bulk-migrate historical proposals, or reimplement shipped behavior. Final review must perform a delta-only diff audit. | `true` | FR-015 is release-blocking because rewriting historical proposal bodies would directly violate Proposal 167 and could hide new work or regress shipped behavior. | `human-approved` |
| `branch-hygiene-and-dirty-drift` | `governance-integrity` | `addressed` | `planning-time-analysis` | `pending-implementation` | Before T001, confirm branch/upstream parity and record dirty paths. Use path-limited staging. Keep existing .codex, .github, .squad config/casting, Feature 140, .cursor, and version-cache drift out of Feature 168 commits unless explicitly approved. | `true` | Dirty drift was present before this feature's implementation phase. Capturing it now prevents unrelated runtime/session changes from entering boundary evidence. | `human-approved` |
| `security-surface-analysis` | `security` | `addressed` | `planning-time-analysis` | `pending-implementation` | Parser and validator warnings must not fabricate approval, implementation ownership, or amendment disposition. Malformed records must be reported rather than silently accepted. | `true` | Governance validation is authorization-adjacent; inaccurate warnings or false ownership claims could mislead maintainers. | `—` |
| `error-handling-and-malformed-input` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-implementation` | Missing proposal status, unknown status, malformed amendments, and invalid amendment statuses must produce clear findings distinct from unsafe body-edit warnings. | `true` | Feature 168 depends on structural proposal parsing; malformed inputs are expected and must not collapse into vague warnings. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-implementation` | Tests must cover shipped/superseded unsafe edits, valid amendments, candidate/draft no-warning paths, allowed corrections, active proposal exclusion, malformed records, reviewer guidance, and status surfacing. | `true` | The validator must avoid both false confidence and false positives; synthetic positive and negative fixtures are required before review. | `—` |
| `proposal-145-review-discipline` | `review-quality` | `addressed` | `planning-time-analysis` | `pending-implementation` | Review must include a claim-to-evidence ledger, delta-only diff audit, branch hygiene proof, and over-strong-claim checks. | `true` | Proposal 145 discipline is necessary because this feature changes governance rules and the review must prove claims against committed evidence. | `human-approved` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | — | `true` | The slice does not introduce retries, queues, background work, or recovery workflows. Deterministic validator output is covered under test-integrity and robustness controls. | `—` |
| `operational-runtime-resilience` | `operational` | `not-applicable` | `not-applicable` | `not-needed` | — | `true` | This is a docs/validator/test governance slice with no service runtime or production deployment surface. | `—` |

## Notes

- This artifact is a planning-readiness gate. Runtime proof remains pending until implementation and review.
- FR-006 and FR-015 are explicitly release-blocking.
- No implementation code is authorized by this artifact; implementation still requires explicit human approval after the before-implement stop.
- If T002 discovers that validator/status work exceeds the bounded slice, implementation must stop for a human deferral decision.
