# Hardening Gate: Iteration 004

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/182-work-kind-branch-governance/spec.md`
**Iteration Ref**: `specs/182-work-kind-branch-governance/iterations/004`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-12T15:00:00Z
**Post-Implementation Verification**: complete — runtime evidence recorded for every blocking concern (work-kind-lifecycle 6 + forge-neutralization-sweep all groups incl. the F-174 regression fixture + capability-provider-resolution + work-kind-validator + work-kind-runtime PASS; PSScriptAnalyzer the 4 edited production `.ps1` 0 errors / 0 new warnings; markdownlint 0; validate-governance PASS on iters 001–004 on the closeout state). The four runtime-bearing concerns move from `pending-post-implementation` (`planning-time-analysis`) to `recorded` (`runtime-evidence`). See Concern Review.
**Verified At**: 2026-06-13T04:30:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | No new privileged action: T401–T402 are sweep + prose/agent-file neutralization; T403–T404 add a catalog field + intake wiring (read-only resolution); T405–T407 are lens prose + a detector field read. No new secret, token, or network call. The load-bearing control: neutralizing runtime/deployed surfaces must NOT drop a governance control — `review_gate` stays present, the own-GitHub flow stays as a labeled example (T402/T408). **Verified:** the sweep all-groups-PASS confirms the own gh+PSGallery steps are preserved as a labeled example; the refocus surface is additive + read-only (no privileged surface added). | `true` | The only risk is accidentally weakening governance or breaking Specrew's own flow while neutralizing the runtime layer; T408 own-flow guard + SC-015 sweep are the controls. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Fail-open: the widened sweep degrades to PASS-with-no-false-positive via the explicit allowlist + labeled-example semantics (T401); capability detection's `provider.name` read falls back for older/simpler schema shapes (T407, FR-026); the lifecycle-template resolution (T403) degrades gracefully when a kind has no template; the refocus lifecycle surface is guarded + fail-open (a missing helper / missing declaration emits a `SOURCE_MISSING` warn, never a false pointer). Tests: sweep allowlist/labeled-example (T401/T408); detector fallback across 4 shapes (T407); template-resolution Declared=true/Exists=false on a missing template + no-declaration→silent surface (T404). | `true` | NFR #5 fail-open: a widened sweep must not false-positive on host-adapter/own-infra, and the detector must not break on the iter-2 schema shape. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | Prose/agent-file edits + a catalog field + a read-only detector field are idempotent; the sweep + resolution are single-pass, read-only; no retry logic, concurrent writers, or shared mutable runtime state introduced. | `false` | Recorded so the omission stays reviewable; the iteration adds no retry/concurrency surface. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | **Confound-proof, artifact-level** (per the dogfood test-validity rule): SC-015 = the widened sweep FAILS on unlabeled mandates across `.ps1` + deployed-agent + lifecycle + methodology + coordinator surfaces (deterministic, pattern-based — not agent behavior); SC-016 = work_kind→`<kind>-lifecycle.md` resolution is asserted by **runtime resolution in the deployed `.specify` shape**, not file-presence (a missing template resolves Exists=false), and the **refocus session-start surface** is asserted end-to-end. T407 detector test reads real fixtures across 4 shapes. **Verified (send-back rework):** the SC-016 proof was hardened from the dev-repo shape to the deployed shape + the real intake surface (F1/F2); the sweep `gh pr` `.md` scan is section-aware (F3). | `true` | SC-015/SC-016 are the i4 acceptance bars; behavior-level "the agent did the right thing" is discounted (confound) — the gates must check artifacts + deterministic scripts. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | The migrated surfaces are dogfooded by Specrew; the operational risk is breaking Specrew's own closeout/launch. Mitigated by: T402 keeps the own-GitHub flow as a labeled example; T408 own-flow parity; the F-174 reconciliation obligation is met by landing the widened sweep (catches `launch-contract.ps1` at rebase) WITHOUT F-182 editing F-174's file. `scripts/specrew-start.ps1` neutralized current-tree-only, documented as F-174-superseded. **Verified:** the F-174 regression fixture proves the `.ps1` scan flags a synthetic `scripts/internal/launch-contract.ps1` mandate (2 hits) — the obligation is landed, not just intended; no F-174 worktree touched. | `true` | The i4 operational surface is "don't break Specrew's own usage / the F-174 release train while neutralizing the runtime layer"; the labeled-example + the sweep-as-reconciliation-guard are the controls. | `—` |

## Notes

- Authored as a PLANNING-TIME pre-implementation gate for **iteration 004 (dogfood-findings completion,
  FR-022–FR-026)**, then **closed at iteration-closeout with post-implementation runtime evidence
  recorded**: the four runtime-bearing concerns moved from `pending-post-implementation`
  (`planning-time-analysis`) to `recorded` (`runtime-evidence`) once T401–T408 were built and the
  review send-back's F1/F2/F3 reworked + proven (work-kind-lifecycle 6 + forge-neutralization-sweep all
  groups incl. the F-174 fixture + capability-provider-resolution + work-kind-validator + work-kind-runtime
  PASS; 0 new analyzer warnings).
- **Binding scope guardrail (maintainer-set):** work-kind / forge-neutral governance ONLY — NOT F-174's
  session-bootstrap rewrite or `launch-contract.ps1`, NOT DF-006, NOT session-state. Specrew's own GitHub
  release workflow changes ONLY as a labeled Specrew-own example.
- **F-174 handoffs (recorded, NOT i4 tasks):** DF-006 regression test; `launch-contract.ps1` neutralization
  (F-174 owns); DF-010 merge reconciliation. F-182's obligation = land the widened sweep so it catches
  F-174's site at reconciliation.
- **Sync origin/main before implementation** (F-182 is behind); set the Baseline Ref then.
- No product code is written until the maintainer's explicit "start implementation" go-ahead at this
  before-implement boundary.
