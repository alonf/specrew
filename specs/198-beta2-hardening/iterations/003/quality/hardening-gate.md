# Hardening Gate: Iteration 003

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/003`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner
**Reviewed At**: 2026-07-11T16:10:00Z
**Post-Implementation Verification**: pending (runtime evidence recorded at iteration close)

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Two trust boundaries move this iteration. (1) Reviewer containment: the reviewer stays trusted-but-confined — worktrees materialize OUTSIDE the origin root, origin-absolute paths are stripped from its context, the confinement contract REQUIRES the bounded in-worktree verification (declared test commands, timeout/process containment, bounded output, post-run mutation detection — never an unrestricted suite), and the detector records violations loud origin-side without ever killing mid-flight. (2) Verdict-capture integrity: machinery-turn exclusion, tokenizer tightening with the temporal-ordering + cursor-invariant guards, exact-sequence fabrication fixtures, and the APPEND-ONLY correction door under explicit human authority; the pending-artifact fallback stays DISABLED until T030-T033 acceptance passes (DEC-198-GOV-003). T034b semantic conflicts touching containment/authorization/evidence/fail-closed ESCALATE — never auto-resolved (maintainer-typed doctrine). | `true` | Paired tests per invariant; the two live fabrications replay verbatim as fixtures; message-content assertions on every teaching surface. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Every failure direction is loud and recorded: containment violation → origin-side `containment-violated` record (never a silent pass, never a kill); recorded-run wrapper → caller-supplied numbers rejected/labeled; allowance halt → consumer-legible spend-guard text with zero internal identifiers; unresolvable design-context refs keep the Devin crew's loud-warn precedent; unreadable ledger identity stays a hard fail (the 002 rework's direction preserved by the shared matcher). | `true` | Fixtures for violation records, rejected caller numbers, halt message content, and the fail-closed ledger paths; each proves the loud direction. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Worktree materialization is idempotent per run id (re-runs land fresh, never half-reused); detector sampling is re-entrant read-only; in-flight dedup per lineage (T019) makes re-fired reviews converge instead of stacking; the correction door is append-only with a same-target re-fire no-op (no duplicate invalidation entries); T034b cherry-pick executes once with its verification recorded. | `true` | Idempotence tests: double-materialize, double-correct, re-fired review lineage. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The two 002 test-integrity lessons are BINDING here: every new test builds its own fixture (hermeticity lens — no ambient repo state), and the in-worktree verification the contract requires is exactly the mechanism that caught Test 5. The fabrication fixtures (T032) replay the live GOV-001/GOV-003 sequences verbatim and are the fallback re-enable acceptance surface; the recorded-run wrapper retires hand-typed counts (ledger counts derive from run output). C10-C16's interim contract flips to the redesigned expectations ONLY when T030-T033 pass. | `true` | The paired-honesty-tests custom rule is the review enforcement item; fixture hermeticity is a named review lens this iteration. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Worktrees in system temp keep CI checkouts and origin-tree scans clean; the ONE machinery list is a single versioned data file both strips consume by construction (drift impossible, the deny-list precedent); mirror parity per extension-script change; the two-crew seam is managed by T034a's recorded inspection + T034b's at-landing checkpoint with regression set + live-round compat proof; capacity 12/26 with the recorded defer order (T033 then T032; never containment/T020/T030/T031). | `true` | The four containment components land behind the existing suites; the integration checkpoint has its own verification contract; the W14/W16 budget surfaces are untouched. | `—` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-human-authorization` | `met` | The `tasks -> before-implement` boundary stop is being presented next; implementation MUST NOT start until the human authorizes it. The design approval (Option B, maintainer-typed) and the tasks approval do NOT authorize implementation (maintainer instruction at the planning approval: "This approval authorizes planning only"). | Implementation starts only on the explicit before-implement verdict. |
| `condition-b-live-state-safety` | `met` | T030-T033 modify the very capture machinery THIS session runs on. All changes land behind fixtures on temp project roots (the 002 discipline); the session's own boundary state is never hand-edited as development convenience; the DISABLED fallback is not re-enabled even transiently during development — the redesigned path is proven on fixtures, and the C10-C16 contract flips only at the recorded acceptance decision. | If a change would require mutating this session's live boundary state to test, STOP — build the fixture instead. |
| `condition-c-fail-direction-review` | `met` | Every new check's fail direction is pinned before code: detector violation → loud record, never kill; wrapper caller-numbers → reject; machinery-turn ambiguity → exclude (fail-closed); tokenizer ambiguity → not-approval; correction-door malformed target → refuse; T034b semantic conflict → escalate and halt; unreadable ledger → hard fail (preserved). | A fail-direction change during implementation is spec drift — record it in drift-log.md with the FR citation before proceeding. |
| `condition-d-capacity-discipline` | `met` | Capacity 12/26 story_points planned (partition verified: 0.25 discovery + 11.75 implementation); Review 1.0 / Rework 0.25 are wall-clock allowances above planned SP (floor 13.25). Defer order: T033 first, then T032; never T013-T017/T020 (priority instruction) nor T030/T031 (live fabrication class). | Do not silently expand past the planned slice; a spill triggers the human split/defer decision. |

## Notes

- Planning-time gate; per-concern Runtime Evidence Status flips to
  `recorded` with `runtime-evidence` basis at iteration close (the
  iteration-001/002 precedent shape).
- The Option B ordering and the conflict-escalation doctrine carry the
  maintainer's typed decisions (design-analysis.md Human Decision;
  DEC-198-I003-001 ratification of 49082762).
