# Iteration 005 Closeout Validation

**Feature**: 197-continuous-co-review
**Iteration**: 005 (Phase B part 2 — async co-review navigator on the general isolated-task launcher)
**Date**: 2026-06-24

## Scope delivered

| Task | Outcome |
| ---- | ------- |
| T076 | Spike — detached self-limiting cross-platform spawn PROVEN (Windows + Linux/WSL). |
| T077 | The general isolated-task launcher (Proposal 139 foundation); review path built, `merge`/`preserve`/`read-write` seamed. Cross-platform verified. |
| T078/T079 | The async navigator provider + registry + reaper + SessionStart sweep; host-neutral via `refocus-scopes.json`. |
| T080 | `TrunkName` threaded through the signoff gate (non-`main`-trunk repos no longer fail closed). |
| T081 | This closeout-validation + the comprehensive suite + the Proposal 145 review. |
| Hardening | The 4 dogfood-review findings (supersede ordering, conservative reap, outer fail-open, InlineReap cleanup). |
| PASS->gate | Auto-fired non-blocking PASS promotes to `.specrew/review/inline/` gate evidence; STUB excluded (flag 2). |
| FileList | The 37 missing `continuous-co-review/**` + `agent-tasks/**` files added to `Specrew.psd1` (closeout blocker). |
| Dispatcher F-184 | 2 gaps closed (codex clean-args, stop-block merge), maintainer-authorized, scoped guard exception, 3 copies in sync. |

## Evidence (runtime, not file-existence)

### The DOGFOOD — the mechanism reviewing its own code

Ran the navigator on iteration 005's own navigator code with a REAL `claude -p` reviewer: FIRED ->
materialized the live tree in a `$TEMP` worktree -> a real 51s review -> a substantive verdict
(4 findings) -> reaped. The mechanism works end-to-end. It also CAUGHT + FIXED 2 production bugs the
unit tests missed (both only manifest in the redirected-provider context on a real repo): the `& git`
encoding error (-> explicit `System.Diagnostics.Process`) and the huge git-diff arg (-> batched paths).
Detail: [dogfood-result.md](dogfood-result.md).

### Cross-platform

T076 + T077 validated on Windows 10 AND WSL Ubuntu 24.04 (pwsh 7.6.1): provider returns ~1.7s,
launcher detached + self-limiting + no orphan on both. The Linux-blocking stdio-inheritance defect was
caught (and fixed via stdio redirect) BEFORE shipping — a Windows-only spike would have hung the Stop
hook on Linux/macOS. macOS inferred (same Unix/.NET model); a CI/Mac leg is the honest residual.

### Test suites (all green)

Full continuous-co-review suite + key integration: **216/0** across 41 CCR files. Navigator 16/0
(incl. the stub-NOT-promoted guard), gate 11/0, run-index 6/0, launcher 4/4, diff-provider 6/0,
dispatcher-stop-block, conformance-detection 40, DispatcherLargeEvent, protected-surface-guard 1/0,
ProviderMirrorParity (3 dispatcher copies byte-identical), filelist-completeness green (350 entries).
No F-184 surface touched by the navigator/launcher; the dispatcher edits are maintainer-authorized with
a SCOPED `protected-surface-guard` exception (removed once on main).

## Flagged items — all resolved

- Implementer gaps: FileList (DONE), stop-block collision + `--event-json` codex (DONE, F-184).
- Navigator flags: inline/-vs-runs/ (the gate reads `inline/`; corrected + comments fixed); the STUB
  auto-satisfies the gate (FIXED — a stub is advisory-only, never promotes; guard test added).

## Honest residual (the fast-follow, NOT a blocker)

The navigator currently fires the DEFAULT verdict-emitting STUB (the spawn+review+verdict+reap plumbing
is the deliverable). Wiring the REAL reviewer — calling `Select-ContinuousCoReviewReviewerCandidate`
(code-writer-independent host) and running it through the launcher against the worktree — is the next
concrete iteration. Until then: the gate is NOT auto-satisfied (the stub does not promote); the manual
`specrew review --live` path (Phase A, fully wired) produces real gate evidence. The maintainer's e2e
test exercises the navigator plumbing + the manual real-review gate path.

**Findings-reporting surface (must ship WITH the real reviewer, not after):** today the navigator
surfaces only a SUMMARY — a one-line `N finding(s): <first comment>` for a pass, and blocking-severity
findings only for a block (`continuous-co-review-navigator.ps1:516-526`) — and `Clear-...Entry` DELETES
the full verdict run dir after the reap (`:258-260`); the durable `inline/` record is gate evidence
(tree-id/status/refs), NOT the findings. With the stub (no real findings) this loses nothing, but the
dogfood's real reviewer emitted 4 non-blocking findings — through the navigator the user would see only
`4 finding(s): <first>` and lose the other 3. So the real-reviewer wiring MUST also persist a per-run
full-findings report (all findings, all severities) durably and point the inject note at it; surfacing
only a summary is acceptable ONLY while the reviewer is the no-findings stub.

## Proposal 145 review

Two adversarial read-only reviewers (gate-integrity/stub-exclusion; dispatcher F-184), both PASS for
the delivered scope, both zero-footprint. Each surfaced ONE real finding, both FIXED (not deferred):

- **G-197-I005-01** (gate soundness): the promotion fired on mere absence-of-blocking, so a
  non-blocking non-pass verdict could launder to a gate `pass`. FIXED `d31f4cb8` — promote only on an
  affirmative pass disposition allow-list. Guard test added.
- **MAJOR catalog drift** (file-presence != runtime): the `co-review-navigator` row was missing from
  `.specify/extensions/.../refocus-scopes.json` (loaded first), so the navigator was INERT on live
  dispatch while fixtures stayed green. FIXED `938731eb` — row synced + a catalog-parity guard added.

Carried (pre-existing, not blockers, recorded in [review.md](review.md)): the deploy mechanism does not
re-sync `refocus-scopes.json` on `specrew update` (-> proposal + beta validation); a dormant guard
exception; the 4 `probe`-authored F-185 commits needing author-rewrite before main. Full detail +
dispositions: [review.md](review.md).
