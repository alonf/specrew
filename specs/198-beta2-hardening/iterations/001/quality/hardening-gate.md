# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner
**Reviewed At**: 2026-07-10T00:00:00Z
**Post-Implementation Verification**: pending (runtime evidence recorded at iteration close)

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planned-controls` | `pending` | The deny-list lint (T005) is itself a security control: the author-time firewall arm of Proposal 205. Toolchain probes (T001, T003) run in SCRATCH directories ONLY — never the governed cwd (standing constraint; init probes mutate lifecycle state). Probe evidence files carry CLI output only: no env vars, no credentials, no ambient state. The lint's exit-2 path (unreadable deny-list) fails the lane LOUD — a broken rule file can never produce a silent green. | `true` | The firewall lands FIRST (born-clean custom rule) so every surface iterations 002–004 touch is scanned from its first commit; secure-coding-defaults from implementation-rules.yml bind the evidence files. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planned-controls` | `pending` | Lint exit-code contract 0/1/2 with 2 = fails loud (never silently green on a broken list). A failed 0.12.9 probe or fixture suite BLOCKS the migration (T002) rather than shipping an untested pin; version-check keeps its warn-with-exact-instruction shape for consumers. Init migration failure is a hard fail naming the flag change — no fallback to the removed `--ai` syntax. | `true` | Expected-failure paths are structured outcomes (idiomatic-error-handling rule); the W14/W16 teaching shapes arrive in iteration 002 — this iteration only needs its own failures loud. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planned-controls` | `pending` | The lint is a pure read-only scan — re-runs are idempotent by construction. Pin updates are idempotent edits applied together (no split-brain version state between surfaces). Probes are single-shot per scratch dir; a re-probe uses a fresh dir, never mutates a prior one. No retry loops anywhere in the slice (careful-retries rule: schema/invariant defects are never retried). | `true` | Idempotence claims are cheap to verify here (pure scan + edits); the write-conflict semantics rule covers the evidence files (new run id per re-probe). | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planned-controls` | `pending` | Tests prove BEHAVIOR, not file presence: paired fixtures per deny-list class (seeded leak → red; annotated → green WITH the reason surfaced; clean → green); a surface-enumeration test asserts the lint's derived scan surface == the deploy allowlist (scanned == shipped by construction); integration suites run against a REAL 0.12.9-initialized fixture (not mocks); probe evidence records the ACTUAL CLI transcript. Caller-asserted results are not evidence (NFR-006). | `true` | The paired-honesty-tests custom rule is a review enforcement item; the T005 fixture set includes the missing-reason-annotation edge (treated unannotated → red). | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planned-controls` | `pending` | The blocking posture applies to the SELF-HOST lane only (consumer gateway posture is iteration 004 scope; advisory-first there). All pin surfaces move together in T002/T003 so no consumer can observe a split-brain toolchain claim. KNOWN CONDITION: the existing `templates/github/workflows/*` carry the very self-facts the deny-list targets (the 204/#2909 debt, fixed by the iteration 004 surgery) — T005 annotates them `specrew-self-ok: tracked debt, proposal 204 / #2909, surgery in iteration 004` so the lane lands green-with-recorded-reasons instead of blocking CI for three iterations; the 004 surgery removes the annotations with the templates. Capacity 5.0/26 with wide headroom; probe surprises absorb into the headroom or STOP for a human split. | `true` | Landing the lane green-with-honest-annotations preserves both the blocking posture and CI viability; the annotations are self-documenting debt markers whose removal is already scheduled (T023/T025). | `—` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-human-authorization` | `met` | The `tasks -> before-implement` boundary stop is being presented now; implementation MUST NOT start until the human authorizes it. The plan approval (Option B, `ff67fe8a`) and tasks approval (`3740c570`) do NOT authorize implementation. | Implementation starts only on the explicit `tasks -> before-implement` verdict. |
| `condition-b-scratch-probe-only` | `met` | T001/T003 probes run in scratch directories only (standing constraint: agentic/init CLI probes mutate lifecycle state in a governed cwd). | If any probe would need to run in a governed cwd, STOP — redesign the probe. |
| `condition-c-born-clean-with-honest-debt` | `met` | T005 lands the lane blocking AND green: pre-existing template self-facts get `specrew-self-ok` annotations naming the tracked fix (proposal 204 / #2909, iteration 004 surgery). New/edited surfaces from this feature must pass WITHOUT new annotations. | If annotating the existing debt explodes T005's scope (deny-list matches far more than the known class), STOP for a human scope decision instead of silently widening the seed. |
| `condition-d-capacity-discipline` | `met` | Capacity 5.0/26 story_points. If the T001 probe demonstrates an extension dependency, T002 absorbs it within headroom; beyond that, STOP for a human split/defer decision. | Do not silently expand the iteration past its planned slice. |

## Notes

- Planning-time gate; per-concern Runtime Evidence Status flips to
  `recorded` with run evidence at iteration close (the 197 iteration-010
  precedent shape).
- The 002-scope machinery (ratchet, honesty check, budgets) is
  deliberately absent here — this gate covers only the 001 slice.
