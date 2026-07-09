# Iteration 006 Review (Proposal 145)

**Feature**: 197-continuous-co-review
**Iteration**: 006 (real reviewer + full-findings reporting)
**Date**: 2026-06-24
**Reviewer**: one adversarial, read-only, fresh-context reviewer; zero repo footprint (git identity
clean, zero commits authored).
**Overall Verdict**: accepted

> Closeout status (honest): iteration 006 reached the review phase with this accepted verdict and the
> live-dispatcher e2e PASSED (`069b21b0`), but review-signoff was never formally executed — iteration 006
> was **superseded by iteration 007** (real-reviewer wiring on a real deployed project) before formal
> retro/closeout. The NEEDS-WORK MAJOR (M1) + minor (M2) are both FIXED.

## Verdict trail

The reviewer returned **NEEDS-WORK** with one MAJOR (M1) + two minor (M2, M3); the maintainer chose
Option 1 (fix M1 + M2, then the live e2e). Both are now fixed.

## M1 (MAJOR) — code-writer-independence not wired end-to-end — FIXED `ecf7c768`

The headline "code-writer-independent" selection's independence depended on `$codeWriterHost`, read from
`SPECREW_HOST`/`SPECREW_ACTIVE_HOST` — which **Specrew never sets**. The dispatcher passed `--host-kind`
to the provider, but the provider DISCARDED it, so in production `$codeWriterHost=$null` -> the policy
tiebroke alphabetically -> could pick **claude to review claude's own code**. It held only by
authorization config (codex-only authorized), not by logic. Empirically demonstrated both legs.

**FIX:** the provider (both copies) threads `--host-kind` -> the navigator's new `-CodeWriterHost` param
-> `New-...ReviewerPlan` -> the policy; `SPECREW_HOST`/`SPECREW_ACTIVE_HOST` are fallback-only.
Independence is now real-by-logic. A param-path test proves it with the env UNSET (the production
reality). 233/0 CCR, provider copies in sync.

## M2 (minor) — non-hermetic CONTROL test — FIXED `ecf7c768`

The real-guard CONTROL test snapshotted the LIVE Specrew repo, so concurrent writes between the guard's
before/after snapshots flipped `mutated` true (the iter-005 hermeticity lesson). FIXED to a hermetic
throwaway git repo.

## M3 (minor, out of scope) — the `probe`-authored commits

The known pre-existing main blemish (F-185), already documented in iterations/VALIDATOR-LAG.md and the
iter-005 review; accept + document, do not rewrite protected main. Branch-history hygiene at feature-closeout.

## Probed — no defect (the reviewer's evidence)

A **21/21 no-mocks durability+surfacing harness through the real writer** confirms the core requirement:
all severities persist unfiltered; run_id normalizes to the registry id; blackboard + gate record
co-locate; stub writes nothing; malformed FindingsResult writes nothing and does not throw; the surfaced
ref equals the on-disk dir; the inline thread survives the pending cleanup; promotion is
affirmative-pass-only. Plus: the mutation-guard SKIP is honest (explicit posture marker, not silent);
Hazards A (module-base in the detached worktree) + B (candidate threading, Win+Linux) resolved;
fail-OPEN (never fail-closed, never a stub); the 300s timeout applied to both the navigator + the adapter
per-candidate legs; no reap-ordering regression.

## Task Verdicts

| Task | Verdict | Evidence |
| ---- | ------- | -------- |
| T082 | pass | `4bbbaf93` wired the REAL reviewer into the navigator (replaced the stub): in-repo code-writer-independent host selection, detached `-Command` dot-sourcing the resolved module base, `Invoke-...ReviewerExecution` against the read-only worktree emitting FindingsResult.v1, co-review timeout raised to 300s (nav + adapter legs), honest explicit `SkipMutationGuard` on the isolated-worktree path; 12 wiring tests, CCR 229/0. |
| T083 | pass | `18557e80` routes the complete FindingsResult (ALL severities) to the durable blackboard `.specrew/review/inline/<run-id>/` via `Write-...BlackboardThread`, run_id normalized to the registry id so findings co-locate with the gate record; stub excluded; fail-open on malformed/absent result; +3 reporting tests, CCR 232/0. |
| T084 | pass | `18557e80` (coupled commit) points the reap inject_note + the blocking STOP-BLOCK directive at the durable thread ("Full findings (all severities): `.specrew/review/inline/<run-id>/`"), replacing the one-line `N finding(s): <first>` summary; the no-thread/stub path keeps the summary note. |
| T085 | pass | Live-dispatcher e2e PASSED all 6 maintainer conditions (`069b21b0`): codex fired via the LIVE dispatcher; 6 findings at two severities (blocking + advisory) landed in `inline/<run-id>/findings-result.json` AND surfaced as the stop-block; codex selected independent of the claude code-writer; `src/payment.py` UNMUTATED (honest SKIP). Preceded by the 145 review + closeout-validation (`7333f2b5`), the M1/M2 fixes (`ecf7c768`), and the three first-live-run failures fixed (`289addba` load-order + composer schema-root; `97b4eb91` digest perf); CCR 234/0. |
| T086 | pass | `6a24838b` added the persisted human-authorization seam: `specrew review --host/--authorization-ref` (HUMAN path) persists its catalog to `.specrew/reviewer-hosts.json` (`allowed=true` + `authorization_ref`); `New-...ReviewerPlan` loads it READ-ONLY -> `Get-...ReviewerHostCatalog -Configuration` (absent -> default -> fail-open, never self-authorize); NON-MOCKED test proves the un-mocked policy selects codex from a real config; CCR 234/0. |

## Gap Ledger

- G-197-I006-01 (M1: code-writer-independence not wired end-to-end — the provider discarded `--host-kind` and Specrew never sets `SPECREW_HOST`, so the policy tiebroke alphabetically and could pick the code-writer's own host): fixed-now, commit `ecf7c768` (provider threads `--host-kind` -> the navigator's `-CodeWriterHost` param -> the policy; env vars fallback-only; param-path test with env UNSET).
- G-197-I006-02 (M2: the real-guard CONTROL test snapshotted the live repo and flaked on concurrent writes): fixed-now, commit `ecf7c768` (hermetic throwaway git repo).
- G-197-I006-03 (T086: no persisted human-authorization — the real reviewer could never select a host in production; the 12 deterministic tests + the 145 accept had MOCKED `Select-...ReviewerCandidate`, hiding it): fixed-now, commit `6a24838b` (persisted-authorization seam + NON-MOCKED selection test).
- G-197-I006-04 (two first-live-run failures the LIVE e2e surfaced — `_load` load-order left the navigator no-op'ing on every live Stop, and the composer's missing SchemaRoot let codex emit schema-mismatched output that silently lost a real review): fixed-now, commit `289addba` (dot-source `_load`; composer resolves the default contract root; locked by fresh-process + no-SchemaRoot tests).
- G-197-I006-05 (dedup digest ran a git subprocess per path — ~24s on a deployed `.specify`, blowing the dispatcher budget so the navigator never fired in real projects): fixed-now, commit `97b4eb91` (batched git calls, 24s -> 1.5s, identity-preserving).

## Carried / Out of scope (not an iteration-006 gap)

- M3 (the `probe`-authored commits) is a pre-existing `origin/main` blemish (F-185), out of scope — tracked in iterations/VALIDATOR-LAG.md and the iter-005 review; accept + document as branch-history hygiene at feature-closeout, not an iteration-006 gap.

## Disposition

The NEEDS-WORK MAJOR (M1) + minor (M2) are FIXED and verified (233/0 CCR). The delivered real reviewer +
full-findings reporting is sound. The one remaining acceptance step at the time this review was written —
the LIVE-dispatcher multi-severity e2e (codex), the meaningful proof that real findings land durably AND
surface to the developer through the live hook path — **subsequently PASSED** (`069b21b0`, all 6
maintainer conditions; recorded in closeout-validation.md and state.md). All five delivered tasks
(T082–T086) are `done` with a `pass` verdict. Iteration 006 was then **superseded by iteration 007**
(real-reviewer wiring on a real deployed project) before a formal review-signoff/retro was executed — that
supersession is the honest closeout status for this iteration; no gaps remain open.
