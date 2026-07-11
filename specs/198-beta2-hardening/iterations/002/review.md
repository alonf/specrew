# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-07-11
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T007 | FR-001, FR-002, FR-003, FR-006 | pass | Get-SpecrewUnreconciledBoundary as THE pure delta primitive; sync ratchet refuses a second unapproved advance (consumer-legible refusal: both boundaries, both doors, revert anchor, zero internal identifiers - message-content asserted); validator skipped-boundary FAIL branch; hooks untouched for enforcement. 11 paired assertions green (tests/unit/boundary-ratchet.tests.ps1). |
| T008 | FR-005, FR-007 | pass | Retroactive approvals recorded distinctly (kind=retroactive) with a re-fire no-op guard; the honest one-boundary limit taught in the refusal text; revert stays behind explicit human confirm (conduct + anchor in the refusal). |
| T009 | FR-004 | pass | The re-confirm surface extended with ITERATION CYCLE RESET (new-cycle crossings now produce pending artifacts and capture correctly) - live-proven THIS session: the machinery retroactively walked the missed 002 plan/tasks/before-implement verdicts one boundary at a time. |
| T010 | FR-020 | pass | tracker-honesty-check.ps1: fail-closed claims parser verified against the accepted review record INSIDE the reviewed tree; signoff gate grants the bypass ANNOUNCED, stale block teaches claims-increasing causes. 6 paired cases green on real git-tree fixtures (tests/unit/tracker-honesty-check.tests.ps1). |
| T011 | FR-021, FR-022 | pass | Catalog rows claude 600 / codex 600 / copilot 300 / antigravity 900 (field-measured, maintainer-approved incl. the self-host-measurement reading); resolution chain explicit -> config -> catalog -> 600 floor; W14 warning at resolution time off the RESOLVED value; timeout failure teaches the approve-and-re-run door (amended UX). 11 assertions green (tests/unit/budget-resolution.tests.ps1). |
| T012 | FR-023 | pass | The reviewer-resolution layer applies the SPECREW_HOST/SPECREW_ACTIVE_HOST cascade when the flag is absent and records independence_source (flag / env / unverified) into every run status write; SEC-004 fail-closed treatment unchanged. Provenance assertions green incl. the env-upgrades-to-independent case - hermetically, on a fixture, after the run-485cbb03 catch (see Gap Ledger). |
| T019a | FR-017 | pass | Pulled forward by maintainer decision: reviewed_tree_id stamped into findings-result via the blackboard route (persistence proven on a fixture run); the navigator digest-matches before blocking - stale verdicts surface as ADVISORY stale-vs-current, unknown ids keep blocking (fail-closed). Parser-clean. |

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements (FR-001..FR-007, FR-020..FR-023, FR-017 partial per the approved pull-forward) verified with paired tests and recorded evidence: fixed-now.
- Independent-review catch (run 20260710T213312228, codex): the repo-side deny-list reader accepted any non-empty schema_version - version-locked to the supported set with the exit-2 abuse test (697d7de5): fixed-now.
- Independent-review catch (run 20260711T101138452-485cbb03, copilot): provenance Test 5 resolved hosts against the live repo root, silently depending on the untracked .specrew/reviewer-hosts.json - green here, failing in any clean checkout (the reviewer ran the suite inside the stripped worktree and proved it). Made hermetic with its own authorized-host fixture like Tests 2-4; suite proven green in a tracked-files-only worktree (14222c86): fixed-now.
- Born-clean applied to this iteration's own code: F-19x self ids in deployed governance-script comments red-flagged by the firewall and reworded to project-relative references (025373cd): fixed-now.
- Field discovery beyond plan: the boundary-order model assumed a linear lifecycle; new-iteration crossings never produced pending artifacts, so their verdicts were never captured (the root cause of every re-confirm this feature experienced). Fixed as the cycle-reset in T009's surface with paired tests: fixed-now.
- Maintainer-relayed Devin-crew diagnosis (stale-review pipeline) folded into FR-017/T019; the navigator-surfacing half pulled forward as T019a (this iteration), baseline threading + in-flight dedup carried in T019 (iteration 003) - scheduled, not silent: fixed-now.
- Post-signoff closeout send-back (maintainer, DEC-198-GOV-002): the shipped T007 primitive reconciled crossings by boundary NAME, so a prior iteration's same-named approval satisfied the current cycle's crossing (field: 001's retro satisfied 002's; the closeout sync passed a gate that had to refuse) - and the same read treated a malformed ledger as clean (fail-open via the Issues path). Fixed before closeout per maintainer instruction: reconciliation now binds to the current cycle via the newest cycle-reset edge in the append-ordered history, and an unreadable ledger hard-fails loud. Paired tests 10-12 added (the exact field regression; same-cycle replay incl. lagging cursor; fail-closed identity at both the primitive and the gate); Test 5b's fixture corrected to the real policy seam (config.yml) after the new hard-fail exposed it as green-through-fail-open; governance validator PASS on both iterations; fresh independent co-review rounds run on the fixed tree at closeout: fixed-now.
- Independent-review catch on the GOV-002 fix itself (run 20260711T122827245-2594b7b5, copilot, blocking): the FIRST fix corrected only the new primitive - `Test-SpecrewBoundaryAuthorization`, the LIVE gate behind every sync command, still name-matched (from, to) across unscoped history (the reviewer live-reproduced a prior-cycle approval authorizing a new cycle's crossing with zero human involvement), and the validator's FR-003 branch reimplemented its own inline check instead of consuming the primitive (advisory, same per-site-copy class the design rejected). An earlier Gap Ledger line's "at every consumer" claim was therefore overbroad - corrected here. Fix: ONE shared cycle-scoped matcher (`Find-SpecrewCycleScopedAuthorization`, with the cursor invariant: a closed-cycle cursor authorizes nothing further) now consumed by the primitive AND the live gate; the validator's state-advance/skipped-boundary checks route through the primitive. Paired tests 13-15 (the reviewer's exact gate repro + legit same-cycle pair; first-crossing-of-new-cycle with no reset edge; prior-cycle closeout terminator + legit own-closeout pair). Same run's second finding (drift-log zero-events contradiction) resolved as DRIFT-198-I002-001 plus a dated retro annotation; sync-script trailing-newline nit restored: fixed-now.

## Evidence

- **Machine evidence**: three new paired suites, all green -
  tests/unit/boundary-ratchet.tests.ps1 (23 assertions after the
  closeout-send-back extensions: Tests 1-9 original incl. the
  zero-internal-identifiers message test, Tests 10-15 the
  DEC-198-GOV-002 cycle-scoping/fail-closed/live-gate regressions),
  tests/unit/tracker-honesty-check.tests.ps1
  (6 real-git-tree cases), tests/unit/budget-resolution.tests.ps1 (11
  chain + provenance assertions, Test 5 hermetic after run-485cbb03);
  tests/unit/self-leak-lint.tests.ps1
  regression-extended twice (bare-prose + version-lock abuse paths, now
  23 assertions) and green; deploy-surface lint green (198 files, 25
  reason-carrying annotations).
- **Live machinery proof**: the cycle-reset + capture pipeline
  retroactively recorded this iteration's own missed plan/tasks/
  before-implement verdicts one boundary at a time during this session -
  the F-174 walk executed by the new code on its own lifecycle.
- **Mechanical checks**: quality/mechanical-findings.json - zero findings.
- **Co-review**: codex round de8951f5 (real catch, fixed same-stop);
  stale threaded rounds 7634fabc etc. dispositioned with fix-commit
  evidence - the exact mechanism T019a now surfaces as advisory.
- **Pre-existing noted**: tests/unit/boundary-authorization-prompt-truth.tests.ps1
  fails on a fixture-path setup issue that reproduces WITHOUT this
  iteration's changes (stash-verified) - not gating, carried to triage.
- **Drift**: drift-log.md - zero events (the cycle-reset discovery was
  in-scope FR-004 work, not spec drift).

## Notes

- The signoff evidence for THIS iteration is itself produced by the new
  machinery: the budget chain resolves the reviewer's catalog budget, the
  independence label carries its provenance, and any tracker-only
  reconcile after acceptance will exercise the announced bypass.
