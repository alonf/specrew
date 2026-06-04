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
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The catalog reader MUST degrade gracefully (missing file/lens → null/none, never throw); the emit helper MUST create the temp dir as needed and fail clearly (not silently) when a temp/persisted destination is required but absent. | `true` | Defect class is missing catalog/lens + missing destination; controls are graceful-default + explicit-throw, covered by tests (T004). | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries/transactions; emit writes a file deterministically; re-render overwrites. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Tests MUST assert: catalog resolves diagram-type + render-form per lens and degrades gracefully; the emit helper returns a fenced block (inline), writes a file + returns a `file:///` ref (temp), and returns mermaid-inline / a referenced link (persisted). PLUS the **SC-022 visual dogfood** — diagram quality is NOT unit-provable. | `true` | The catalog + emit helper are pure/deterministic → unit-testable; the diagram content + the whiteboard experience must be exercised in a real run (SC-022). | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The catalog + emit helper MUST be LLM/network-free; temp visuals MUST live under `.specrew/workshop-visuals/` (gitignored, ephemeral); keepers are mermaid-inline (versioned); the emit helper reuses the FR-028 console form; `index.yml` stays pure. | `true` | A5/FR-010 require deterministic, decoupled, honestly-scoped behavior; operability = no network/LLM in the helpers, ephemeral temp, honest framing that diagram quality is the dogfood's. | `—` |

## Release-Blocking Items

- No beta/stable publishing in scope; no push/PR while Feature 141 is in progress.
- Implementation review must confirm the helpers are LLM/network-free, `index.yml` was NOT modified (catalog is a sibling), and the deferred Proposal 156 scope stays out.
- The review MUST include the **SC-022 runtime visual dogfood** — a real run rendering per-lens diagrams — not only the SC-023 unit tests.
- Persisted `.md` uses markdown links / inline mermaid; console uses visible `file:///` URLs (FR-028).

## Notes

- The three `addressed` concerns are `planning-time-analysis`; promoted to `runtime-evidence` / `recorded` at review-signoff once the SC-023 tests AND the SC-022 visual dogfood run.
- Overall Verdict `ready` (planning-time); the diagram-quality bar is the dogfood, not the unit tests.
