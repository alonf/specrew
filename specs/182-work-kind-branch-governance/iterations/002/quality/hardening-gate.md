# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/182-work-kind-branch-governance/spec.md`
**Iteration Ref**: `specs/182-work-kind-branch-governance/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-11T20:10:00Z
**Post-Implementation Verification**: complete — runtime evidence recorded for every blocking concern (88 unit assertions incl. denial-path + fail-open + dogfood self-consistency; PSScriptAnalyzer 0 errors / 0 warnings; markdownlint 0 errors repo-wide; validate-governance PASS). See Concern Review (Runtime Evidence Status `recorded`).
**Verified At**: 2026-06-12T01:55:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | Iteration 002 introduces the real privileged surface: capability detection (read scope) and `apply_protection` (admin scope). Controls: `apply_protection` is human-approved and refused for read-only/unverified/unapproved adapters (Iter-1 guard, now exercised); `gh`/GitHub API confined to `provider-github.ps1`; **Specrew holds no secret** (token from CI `GITHUB_TOKEN` or the user's `gh auth`); the dogfood is describe-only (no auto-apply against the real repo); the emergency bypass writes a durable audit artifact. Denial-path tests required (T212). | `true` | The privileged action lands this iteration; the safety guard + no-secret + describe-only-dogfood + denial-path tests are the controls. Live GitHub apply is human-approved, validated at dogfood/beta. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Fail-open + WARN: the validator defaults to advisory (warns, never blocks); malformed declaration/catalog/governance → WARN + neutral; missing/insufficient token → degrade to `ci-only`/`manual` (never fail-closed-blocking); no adapter → git-diff fallback. Tests: fail-open + missing-token paths (T212). | `true` | NFR #5 (fail-open) is load-bearing for a CI check; T201/T204/T212 fixture-prove it. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | The validator runs once per PR, single-pass, read-only; capability detection is a single read. No retry/concurrent writers; no shared mutable runtime state. | `false` | Recorded so the omission stays reviewable; the runtime is single-pass per PR. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Behaviour-proving Pester: validator per-kind pass/fail + scope mismatch + missing evidence + no-declaration (T211); capability detection mechanism mapping + ci-only/manual fallback (T211); brownfield adapt-or-change (T211); denial-path (too-broad bypass, missing token, apply-without-approval) + fail-open + multi-host parity (T212). Not file-presence. | `true` | SC-005/SC-006/SC-009/SC-012 are the i2 acceptance bars; "passes" cannot mean "file exists". | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | The validator runs as a CI check via a provider-neutral script + a GitHub Actions wrapper (T207); honest capability reporting prevents false confidence; the deployed-catalog location (the carried Iter-1 design item) is resolved this iteration so the deployed validator can read the catalog. The dogfood (T210) validates Specrew's own posture (describe-only). | `true` | The i2 operational surface is the CI lane + the deployed-catalog location; both are addressed; live apply + beta validation are the human-approved/dogfood layer. | `—` |

## Notes

- Authored as a PLANNING-TIME pre-implementation gate for **iteration 002 (i2 — runtime layer)**, then
  closed at iteration-closeout with **post-implementation runtime evidence recorded**: the runtime-bearing
  concerns moved from `pending-post-implementation` to `recorded` (Evidence Basis `runtime-evidence`) once
  the validator, capability detection, the GitHub adapter, synthesis, and the dogfood were built and their
  behaviour proven (88 unit assertions incl. denial-path + fail-open + dogfood self-consistency).
- **apply_protection live mutation** against a real repo stays a **human-approved** action and is NOT
  auto-run by the dogfood; its logic is unit-tested with mocks and validated at dogfood/beta.
- The validator **core stays forge-neutral**; `gh`/GitHub API is confined to `provider-github.ps1`.
- T013b (extension.yml bump + deploy-time `.specify` coverage) is the release/deploy step (D-001),
  resolved at feature-closeout — not this iteration's implementation.
