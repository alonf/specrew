# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/177-software-development-rules-lens/spec.md`
**Iteration Ref**: `specs/177-software-development-rules-lens/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-10T01:40:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `not-needed` | No auth, secrets, PII, or network surface in iteration 001 (catalog + schema + lens md + registration + manifest writer). The catalog's secure-coding rules (rules 35/36) are lens CONTENT it captures/surfaces, not the feature's own surface. Manifest/overlay paths are repo-relative under `specs/<feature>/` and the design-lens catalog (no session-id or external path injection). | `true` | The capture substrate introduces no privilege/secret/network; the security concern reduces to content-vs-feature-surface, confirmed at review (light). | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `not-needed` | Fail-open everywhere, never a silent skip: a missing/malformed manifest, catalog, or overlay surfaces a `[code-rules] WARN` and degrades to the shipped catalog / baseline (T005, T008); `schema_version` mismatch is a fail-open WARN (additive). The overlay merge never silently drops a shipped rule (T008). | `true` | The robustness driver is "the substrate never crashes and never silently drops a rule"; T005 (writer fail-open) + T008 (schema + overlay-never-drops) fixture-prove it. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | No retry logic and no concurrent writers. The manifest writer is synchronous + single-writer; re-running rewrites an equivalent record (UTF-8 no-BOM); no network, queue, or shared mutable runtime state. | `false` | Iteration 001 is a design-time artifact writer + data catalog; retry/idempotency-keys/conflict-detection have no material surface (recorded so the omission stays reviewable). | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `not-needed` | Behavior-proving Pester, not file-presence: catalog integrity — baseline + the 3 F-177 additions + per-stack present, unique/stable IDs, schema-valid, grouped + scope-tagged (T007); manifest schema + overlay-never-drops + `dependency_policy` + provenance (T008); registration presence across `index.yml` / `applicability-map.json` / lens map / `$lensIds` (T009). PSScriptAnalyzer + mechanical-checks + the governance validator round out the bar. | `true` | The plan's verification gate names each suite to a behavior; SC-001/SC-002/SC-005/SC-008 are the i1 acceptance bars, so "passes" cannot mean "file exists". | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `not-needed` | Iteration 001 ships catalog + schema + lens md + registration **with the module** (FileList + `.specify/` mirror parity); the multi-host guidance-skill deploy + parity test is iteration 002 (T011/T016). For i1 the only operational failure mode is a missing FileList entry, caught by the F-176-class release check. | `true` | The i1 operational surface is packaging (FileList + mirror); the multi-host skill fan-out + parity is explicitly iteration 002, recorded so the split stays reviewable. | `—` |

## Notes

- Authored as a PLANNING-TIME pre-implementation gate for **iteration 001 (i1 — capture substrate)**.
  **At iteration-001 closeout** the runtime-bearing concerns are recorded **Runtime Evidence Status:
  `not-needed`** — i1 has **no runtime surface** (it ships data files + a PowerShell writer; the
  workshop conduct + the guidance skill are i2). The i1 evidence is unit/static (Pester 38 assertions +
  mechanical-checks 0 + the governance validator). The **runtime dogfood (SC-004/SC-007/SC-008) + the
  multi-host parity are iteration-002 obligations** (T015–T017), tracked in tasks.md + the retro.
- The `retry-idempotency` row is `not-applicable` with explicit rationale (synchronous single-writer
  design-time writer), recorded so the omission stays reviewable.
- Iteration 002 (delivery + guidance skill + ingestion + wiring + dogfood + release) carries the
  SC-004 / SC-007 / SC-008 **dogfood** (runtime) evidence (T015–T017) and the multi-host parity (T016).
- Deferred (not blocking): Proposals 156 / 162 / 145 forward-compatible shape only; the dependency-report
  automation (097 / 122 / planned 178) is out of scope.
- No product code is written until the human's explicit "start implementation" go-ahead at the
  before-implement boundary.
