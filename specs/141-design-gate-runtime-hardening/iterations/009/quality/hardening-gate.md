# Hardening Gate: Iteration 009

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/009`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-05T09:00:00Z

**Pre-Implementation Readiness**: Iteration 9 builds the collaborative architecture & design capability
(Amendment A6, Option B): three prompt-conduct rules (9a phase-framing, 9b surfacing strengthened to
MUST-in-band, 9c collaborative co-design at design-analysis), a design-method decision point added to the
architecture-core lens (data feeding the existing agenda generator), and a marker-gated, grandfather-safe
co-design-record gate floor (SC-025) wired into the pre-plan design-analysis gate. 18/20 SP. Same
behavioral-content / deterministic-floor split as i7/i8; the co-design floor reuses the SC-021 placeholder
helper and the FR-026 artifact-resolution pattern; `index.yml` stays pure; no release/push. SC-024 (the
co-design experience) is behavioral → the runtime **co-design dogfood** is the acceptance gate; SC-025 (the
co-design-record floor) is the unit-tested floor. Authorized by the maintainer ("Continue, fix all, as much
time as it take", after dispositioning A6 inside 141).

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The change is prompt-conduct text + a deterministic markdown/JSON gate check + a lens-data edit; no auth, secrets, network, eval, or credential persistence. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The co-design floor MUST degrade gracefully (missing/invalid lens-applicability.json or absent co_design marker → no-op, never throw) and MUST be grandfather-safe (pre-A6 artifacts never retroactively fail), mirroring Test-SpecrewLensWorkshopRecords. | `true` | Defect class is the gate over-firing on pre-A6 artifacts or throwing on malformed input; controls are marker-gating + graceful-default, covered by tests (T005). | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The change is prompt-conduct text + a deterministic gate check + a lens-data edit; no retries, transactions, or idempotency surface; the gate re-render overwrites deterministically. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Tests (T005) MUST assert the floor: co_design-marked + complete record PASSES; marked + placeholder/missing FAILS naming the gap; unmarked (pre-A6) no-ops — modelling the real feature-vs-iteration layout (the i7 lesson). PLUS the **SC-024 co-design dogfood** — collaboration quality is NOT unit-provable. | `true` | The floor + agenda addition are pure/deterministic → unit-testable; the co-design conduct + the in-band surfacing must be exercised in a real run (SC-024). | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The gate floor + agenda generator MUST be LLM/network-free; `index.yml` stays pure (the design-method is a decision point inside the architecture-core lens file); the conduct rules are prompt text only; no release/publish/push; the deferred Proposal 156 scope stays out. | `true` | A6/FR-010 require deterministic, decoupled, honestly-scoped behavior; operability = no network/LLM in the gate, pure index, honest framing that collaboration quality is the dogfood's. | `—` |

## Release-Blocking Items

- No beta/stable publishing in scope; no push/PR while Feature 141 is in progress.
- Implementation review must confirm the co-design floor is marker-gated + grandfather-safe (i1-i8, Feature
  140, and the testLenses4 run no-op), the helpers are LLM/network-free, `index.yml` was NOT modified, and
  the deferred Proposal 156 scope stays out.
- The review MUST include the **SC-024 runtime co-design dogfood** — a real run where the design-analysis is
  conducted as a co-design and per-lens diagrams surface in-band — not only the SC-025 unit tests.
- Persisted `.md` uses markdown links / inline mermaid; console uses visible `file:///` URLs (FR-028/FR-037).

## Notes

- The three `addressed` concerns are `planning-time-analysis`; promoted to `runtime-evidence` / `recorded`
  at review-signoff once the SC-025 tests AND the SC-024 co-design dogfood run.
- Overall Verdict `ready` (planning-time); the collaboration-quality bar is the dogfood, not the unit tests
  (the i6/i7/i8 lesson — a behavioral capability needs the dogfood as its acceptance gate).
