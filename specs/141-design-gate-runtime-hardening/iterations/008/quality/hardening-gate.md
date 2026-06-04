# Hardening Gate: Iteration 008

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/008`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-04T14:05:00Z

**Pre-Implementation Readiness**: Iteration 8 builds the workshop-visuals capability (Amendment A5, Option B — workshop-settled): a per-lens diagram catalog (data) + a deterministic emit helper (tiered inline/temp/persisted, FR-028 console form) + an intake-reference helper + a conduct-rule addition. 17/20 SP. Same behavioral-content / deterministic-emit split as i7; `index.yml` stays pure (catalog is a sibling); no release/push. SC-022 (the diagram content/experience) is behavioral → the runtime **visual dogfood** is the acceptance gate; SC-023 (catalog + emit helper) is the unit-tested floor. Authorized by the maintainer ("yes, lets build it").

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The catalog reader + emit helper read a data file and write temp/persisted visual files; no auth, secrets, network, eval, or credential persistence. Intake references a provided path (no fetch). | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | The catalog reader degrades gracefully (missing file/lens → null/none, never throw); the emit helper creates the temp dir as needed and throws clearly when a temp/persisted destination is required but absent. | `true` | Defect class is missing catalog/lens + missing destination; controls verified by the T004 suite (graceful-null + explicit-throw assertions, green). | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries/transactions; emit writes a file deterministically; re-render overwrites. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | The T004 suite asserts: catalog resolves diagram-type + render-form per lens and degrades gracefully; the emit helper returns a fenced block (inline), writes a file + returns a `file:///` ref (temp), and returns mermaid-inline / a referenced link (persisted) — 15 assertions green. The **SC-022 visual dogfood** ran (testLenses4): it confirmed the capability fires AND surfaced that the conduct under-drove in-band surfacing → carried to i9/A6. | `true` | The catalog + emit helper are pure/deterministic → unit-tested green; the behavioral surfacing was exercised in the dogfood and found wanting (SC-022 surfacing clause carried). | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | The catalog + emit helper are LLM/network-free; temp visuals live under `.specrew/workshop-visuals/` (gitignored, ephemeral — verified in the file-classification suite); keepers are mermaid-inline (versioned); the emit helper reuses the FR-028 console form; `index.yml` was NOT modified (catalog is a sibling). | `true` | A5/FR-010 require deterministic, decoupled, honestly-scoped behavior; operability verified — no network/LLM in the helpers, ephemeral temp gitignored, index.yml pure. | `—` |

## Release-Blocking Items

- No beta/stable publishing in scope; no push/PR while Feature 141 is in progress.
- Implementation review must confirm the helpers are LLM/network-free, `index.yml` was NOT modified (catalog is a sibling), and the deferred Proposal 156 scope stays out.
- The review MUST include the **SC-022 runtime visual dogfood** — a real run rendering per-lens diagrams — not only the SC-023 unit tests.
- Persisted `.md` uses markdown links / inline mermaid; console uses visible `file:///` URLs (FR-028).

## Notes

- The three `addressed` concerns were promoted to `runtime-evidence` / `recorded` at review-signoff (2026-06-05): the SC-023 tests ran green (15 assertions) AND the SC-022 visual dogfood ran (testLenses4). The dogfood confirmed the capability fires and surfaced that the conduct under-drove in-band surfacing → SC-022 surfacing clause carried to iteration 009 / Amendment A6 (`.squad\decisions.md`).
- Overall Verdict `ready` was the planning-time pre-implementation verdict; at signoff the deterministic floor is verified and the behavioral surfacing is carried (not a blocker to closing i8 — maintainer-dispositioned to i9).
