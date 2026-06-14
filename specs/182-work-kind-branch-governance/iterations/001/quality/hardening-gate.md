# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/182-work-kind-branch-governance/spec.md`
**Iteration Ref**: `specs/182-work-kind-branch-governance/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-11T17:10:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `not-needed` | Iteration 001 ships the methodology + data substrate (catalog + schemas + lens + templates + docs) + the `ProviderAdapter` CONTRACT + the GenericFallbackAdapter. The privileged `apply_protection` is DEFINED in the contract as guarded (human-approved) but is NOT exercised in i1; the generic fallback is read-only (git-diff `read_pr_context`, `ci-only`/`manual` reporting). No secrets, no network, no token use in i1 — Specrew holds no secret (T009, T010). Branch protection (access control) is captured as a project-level decision schema, not applied at runtime in i1. | `true` | The security surface (apply_protection, capability detection, bypass audit) is an iteration-002 runtime concern (T017/T018); i1 ships only the read-only contract + fallback, so the i1 security concern reduces to "no privileged action, no secret" — confirmed at review (light). | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `not-needed` | Fail-open + WARN everywhere, never a silent skip or crash: a missing/malformed catalog, declaration, or governance file surfaces a WARN and degrades to neutral/baseline; the generic fallback + `git diff` are the never-crash path so the core runs with no adapter; `schema_version` mismatch is a fail-open WARN (additive) (T009, T010, T015). | `true` | The robustness driver (NFR #5) is "never spuriously block, never crash, degrade honestly"; T009 (adapter fallback) + T010 (generic fallback) + T015 (no-adapter + fail-open tests) fixture-prove it. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | No retry logic and no concurrent writers in i1: the adapter contract + generic fallback are synchronous, single-pass, read-only; the catalog/schemas/templates are static data; no network, queue, or shared mutable runtime state. | `false` | Iteration 001 is a data substrate + a read-only contract/fallback; retry/idempotency-keys/conflict-detection have no material surface (recorded so the omission stays reviewable). The validator runtime (i2) is also single-pass per PR. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `not-needed` | Behavior-proving Pester, not file-presence: catalog + schema integrity — 4 kinds present, unique/stable IDs, catalog + declaration + governance schemas validate their fixtures (T014); provider-neutral core + generic fallback — the core imports no forge tool, the fallback returns `ci-only`/`manual`, `read_pr_context` works with no adapter via git-diff (T015). PSScriptAnalyzer + mechanical-checks + the governance validator round out the bar. | `true` | The plan's verification gate names each suite to a behavior; SC-001 + SC-010 are the i1 acceptance bars, so "passes" cannot mean "file exists". | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `not-needed` | Iteration 001 ships the catalog + schemas + lens + templates + adapter + fallback + methodology doc **with the module** (FileList + `.specify/` mirror parity + `extension.yml` version bump, T013). The runtime validator + CI workflow + capability detection + the dogfood are iteration 002 (T016–T019); the forge-neutralization migration is iteration 003 (T021). For i1 the only operational failure mode is a missing FileList/mirror entry, caught by the F-176-class release check. | `true` | The i1 operational surface is packaging (FileList + mirror + version bump); the runtime CI + multi-host parity + dogfood are explicitly i2, recorded so the split stays reviewable. | `—` |

## Notes

- Authored as a PLANNING-TIME pre-implementation gate for **iteration 001 (i1 — methodology + seam
  contract + audit)**. The runtime-bearing concerns are recorded **Runtime Evidence Status:
  `not-needed`** because i1 has **no runtime enforcement surface** (it ships data files + methodology
  surfaces + a read-only adapter contract + the generic fallback + the coupling inventory). The i1
  evidence is unit/static (Pester catalog-integrity, provider-neutral-core/fallback, mechanical-checks,
  and the governance validator).
- The **runtime security/enforcement concerns** (`apply_protection` safety, capability detection,
  emergency-bypass audit, the CI validator) are **iteration-002 obligations** (T016–T020); the
  **forge-neutralization decouple** is **iteration-003** (T021–T022).
- The `retry-idempotency` row is `not-applicable` with explicit rationale (synchronous single-pass,
  read-only design-time surface), recorded so the omission stays reviewable.
- **Phased enforcement (FR-010/SC-008)**: the validator defaults to advisory; no enforcement is
  over-claimed; partial enforcement is labeled phased/deferred in the shipped surfaces (T011).
- No product code is written until the human's explicit "start implementation" go-ahead at the
  before-implement boundary.
