# Iteration 006 State

**Schema**: v1
**Feature**: 197-continuous-co-review
**Iteration**: 006
**Baseline Ref**: 7333f2b5
**Current Phase**: review
**Iteration Status**: reviewing
**Last Completed Task**: T082–T086 all delivered (done); T085 live-dispatcher e2e — PASSED (all 6 conditions); 3 first-run failures FIXED
**Tasks Remaining**: review-signoff never formally executed — iteration 006 was SUPERSEDED by iteration 007 (real-reviewer wiring on a real deployed project) before formal retro/closeout (+ a lingering-child watch-item carried to the maintainer's real-host e2e)
**In Progress**: — (e2e complete)
**Updated**: 2026-06-24

## T085 live-dispatcher e2e — PASSED; 3 first-run failures FIXED (2026-06-24)

The scoped synthetic live e2e (codex, `C:\temp\specrewTrials\f197-e2e`, tiered `payment.py`) ran the
navigator through the LIVE dispatcher (`-Event Stop -HostKind claude`) and PROVED the full path — after
surfacing and fixing THREE real first-live-run failures that every mocked test hid:

1. **_load load-order (FIXED, 289addba):** the provider dot-sources only the navigator; its checkpoint
   detection needs the CCR engine (in `_load`) it never loaded, so it no-op'd on every live Stop. Fix: the
   navigator top dot-sources `_load`. Locked by a fresh-process load test.
2. **composer schema-root (FIXED, 289addba):** the detached harness composes the prompt with NO SchemaRoot;
   the composer only embedded the full schema for an explicit one, falling back to weak prose, so codex
   0.142/gpt-5.5 emitted string location/resolution and an out-of-enum "must_fix" disposition ->
   FindingsResult schema-mismatch -> a real review silently lost. Fix: resolve the default contract root.
   Locked by a no-SchemaRoot composer test.
3. **digest perf (FIXED, 97b4eb91):** the dedup digest ran a git subprocess PER path -> ~24s on a deployed
   `.specify` (172 files) -> the navigator blew the dispatcher's ~20s budget and NEVER fired in any real
   project. Fix: batched git calls (24s -> 1.5s, identity-preserving). Locked by a >ChunkSize identity test.

PROVEN end-to-end through the LIVE dispatcher, all 6 maintainer conditions held: (1) codex fired via the
dispatcher; (2) 6 findings at TWO severities (blocking and advisory), conformant shape, LANDED in
`inline/<run-id>/findings-result.json` AND SURFACED as the stop-block (every finding, the durable-thread
pointer, the honest-SKIP note); (3) codex selected independent of the claude code-writer; (4)
`src/payment.py` UNMUTATED and the surface note states "nothing was changed in your tree" (honest SKIP);
(5) the three first-run failures fixed; (6) synthetic project deleted.

WATCH ITEM (NOT a confirmed bug — an advisor-caught confound): a lingering-child WARN. codex's detached
supervisor inherits the navigator provider's stdout handle, so under FILE-REDIRECT capture the parent
waits ~codex's review time. The SURFACE and DEDUP are NOT affected — proven clean once the e2e logs were
moved OUTSIDE the watched project (root-level logs had been polluting the reviewed-state tree-id, which is
what produced the apparent re-fire and cutoff). Whether the REAL Claude host's hook-stdout read blocks is
for the maintainer's manual e2e; if it does, a fully-detached spawn (e.g. WMI `Win32_Process.Create`) is
the candidate fix.

## T086 — persisted human-authorization seam (the iter-002-class gap the LIVE e2e found, 2026-06-24)

## T086 — persisted human-authorization seam (the iter-002-class gap the LIVE e2e found, 2026-06-24)

Setting up the live-NOT-mocked e2e uncovered that T082's "real reviewer" could NEVER select a host in
production: the default catalog ships every host `allowed=$false`, the plan-builder called the catalog
with NO config, and nothing persisted a runtime authorization -> fail-open, no review. T082's 12
deterministic tests (and the 145 accept) had MOCKED `Select-...ReviewerCandidate`, hiding it. Maintainer
ruling: FIX IN 006 (the honest completion of T082), Option A, all conditions held. FIX: (1)
`specrew review --host/--authorization-ref` (the HUMAN path) now PERSISTS its built catalog to
`.specrew/reviewer-hosts.json` (`allowed=$true` + `authorization_ref` = the human-provenance anchor);
(2) `New-...ReviewerPlan` LOADS it READ-ONLY -> the catalog (absent -> default -> fail-open, never a
stub; the navigator never writes/self-authorizes). NON-MOCKED test (condition d): a real config -> the
UN-MOCKED policy selects codex; absent -> fail-open. Also fixed a dangling `$codeWriterHost` ref from the
M1 rename. 234/0 CCR; provider copies in sync. The Pester-3.4 mock-leak that masked the test was caught
and isolated (T086 in its own Context).

## T085 145 review + M1/M2 fixes (2026-06-24)

One adversarial 145 reviewer: NEEDS-WORK, 1 MAJOR + 2 minor; everything else probed clean (incl. a 21/21
no-mocks durability+surfacing harness confirming the core). M1 (MAJOR, maintainer chose fix-it): the
code-writer-INDEPENDENT selection was not wired end-to-end — the provider received `--host-kind` but
discarded it, and Specrew never sets `SPECREW_HOST`, so production fell to an alphabetical tiebreak that
could pick the code-writer's own host. FIXED: the provider threads `--host-kind` -> the navigator's new
`-CodeWriterHost` param -> the policy (env vars are fallback-only now); independence is real-by-logic, not
config-incidental. Param-path test added (proves it with the env UNSET). M2 (minor): the real-guard CONTROL
test snapshotted the LIVE repo -> flaked on concurrent writes; FIXED to a hermetic temp repo. M3 (the probe
commits) is the known pre-existing main blemish. 233/0 CCR; provider copies in sync.

## Before-implement verdict — APPROVED (2026-06-24)

Maintainer APPROVED for before-implement (iteration 006), artifact-level verified (all foldings landed
with real reasoning). Guardrails to HOLD during implementation: (1) STOP if neither mutation-guard
posture (skip vs re-aim) is honest — the plan reasoned SKIP (the guard hashes Specrew-own roots + reads
git status, both absent in the detached worktree; the read-only export is the primary guarantee);
(2) raise the co-review timeout above ~300s BEFORE the live e2e; (3) the T085 e2e MUST fire through the
LIVE dispatcher (not a direct call). Specrew-repo carries FILED: validator-grandfathering = alonf/specrew#2902;
refocus-scopes deploy-sync (coordinate with 198) = alonf/specrew#2903. Hardening gate stays Planner-authored
(the independent Reviewer's value is at review-signoff).

## Scope (the payoff: real reviewer + full-findings reporting)

Iteration 005 shipped the async navigator foundation (the isolated-task launcher, the pending registry,
the reaper, the SessionStart sweep, the host-neutral provider registration) but the navigator fires a
verdict-emitting STUB. Iteration 006 is the PAYOFF: replace the stub with the REAL policy-driven reviewer
and surface its COMPLETE findings (all severities) durably, so the developer actually sees them.

Three moves, all WIRING (not building) the Phase A reviewer infrastructure:

1. **Real reviewer (T082):** select a code-writer-independent host in-repo at fire
   (`Select-ContinuousCoReviewReviewerCandidate`), run it through the launcher against the materialized
   worktree (`Invoke-ContinuousCoReviewReviewerExecution`; settle the mutation-guard posture — the
   read-only export is the primary guarantee), emit a real FindingsResult.v1. Raise the co-review
   timeout so a real run completes.
2. **Full-findings report (T083):** in the reap, route the complete parsed FindingsResult to the
   existing blackboard writer (`.specrew/review/inline/<run-id>/`), run_id normalized to the registry
   run-id, fail-open.
3. **Surface (T084):** point the reap inject note at the blackboard thread so the developer sees ALL
   findings, not the one-line `N finding(s): <first>` summary.

## Carried context from iteration 005

- **The residual that opened 006** (iteration-005 closeout-validation, "Findings-reporting surface"):
  the navigator surfaces only a summary and the real reviewer would lose all but the first finding; the
  real-reviewer wiring MUST also persist a per-run full-findings report and point the inject note at it.
- **Load-bearing (proven):** `pending/<run-id>/` (reaped/deleted) is SEPARATE from `inline/<run-id>/`
  (the durable blackboard) — no reap-ordering change needed.
- **Timeout:** iteration 002's live codex review needed ~300s (a 120s rerun timed out); the navigator
  default is 120s.
- **Deploy carry (OUT of 006):** `refocus-scopes.json` is not re-synced on `specrew update` — a separate
  proposal coordinated with Proposal 198.

## Next

- Plan-boundary verdict -> tasks -> before-implement, then execute T082..T085.
- The meaningful E2E (T085) fires through the LIVE DISPATCHER on a real host (codex), not a direct call.
