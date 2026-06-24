# Iteration 005 Review (Proposal 145)

**Feature**: 197-continuous-co-review
**Iteration**: 005 (async co-review navigator on the isolated-task launcher)
**Date**: 2026-06-24
**Reviewers**: two adversarial, read-only, fresh-context reviewers (gate-integrity; dispatcher F-184),
each told to BREAK the work; both confirmed **zero repo footprint** (no git-identity leak, no stray
commits — the F-197 incident axes specifically checked).

## Reviewer A — gate-integrity + stub-exclusion: PASS for scope; 1 real finding FIXED

Verified: the stub-exclusion holds (the default stub's `reviewer='stub'` survives the
emit->result.out->parse round-trip and is excluded), no real-pass-fails-to-promote, the 3 gate
fields correct (freshness/lineage/coverage), the promotion fails CLOSED for the gate on error,
blocking-not-promoted. 16/16 navigator + 11/11 gate green.

- **G-197-I005-01 (real soundness hole, demonstrated):** the reap promoted on mere
  absence-of-blocking and `New-...GateVerdict` hard-codes `status='pass'`, so any non-blocking
  verdict without `reviewer='stub'` (`needs-work`/`partial`/`{foo:bar}`->null) would launder to a
  gate `pass`. Not production-reachable today (only the self-marked stub fires), but a soundness
  hole for the real reviewer. **FIXED (`d31f4cb8`)**, not deferred: promote ONLY on an affirmative
  pass disposition allow-list (`pass|approved|clean|no-findings`); everything else is advisory.
  Stub marker also trimmed. Guard test added (17/17). The dummy-override promotion tests (which emit
  `disposition='pass'`) are unaffected.

## Reviewer B — dispatcher F-184: PASS on both fixes; 1 MAJOR FIXED + carried items

Verified the two fixes are correct at source + by 5 suites + 4 direct adversarial edge-probes: the
clean-args strip is provider-id-keyed so the navigator never gets `--event-json` on ANY event (incl.
SessionStart); the stop-block merge loses/dups nothing and single-provider output is byte-identical;
the protected-surface exception is exact-match-scoped to the one dispatcher path; the 3 dispatcher
copies are byte-identical (`2f977ec6`). dispatcher-stop-block 27, conformance 40, DispatcherLargeEvent
15, protected-surface-guard 1, ProviderMirrorParity — all green.

- **MAJOR (the headline — file-presence != runtime):** the `co-review-navigator` row was in
  `extensions/refocus-scopes.json` but NOT `.specify/extensions/refocus-scopes.json`, and
  `Get-DispatcherCatalog` loads `.specify` FIRST -> **the navigator never fired via this repo's real
  dispatcher** (the dogfood worked only by calling the navigator function directly). Every
  fixture-catalog test stayed green while the live surface was inert. **FIXED (`938731eb`)**: synced
  the row (copies now byte-identical) so the navigator actually fires; added a `refocus-scopes.json`
  catalog-parity guard to ProviderMirrorParity (the blind spot that let it drift). Required before
  the e2e test exercises the navigator.

### Carried (NOT blockers; recorded)

- **SECONDARY (deploy mechanism, pre-existing, all providers):** `specrew update` + the manual deploy
  fallback do not sync `refocus-scopes.json` into an existing `.specify` (only fresh-init's full-tree
  copy does). So a downstream project that UPDATES may not receive a new provider row. -> File a
  proposal; **COORDINATE with Proposal 198 (self-host + dependency currency)** — this is the same
  self-host-currency class as the `extensions.yml` drift just fixed on the Devin worktree; verify at
  beta validation. Out of 197's scope.
- **MINOR:** the `F197AuthorizedSurfaceExceptions` guard exception is dormant (the guard keys on the
  working-tree diff; a committed edit shows a clean tree). Harmless; remove the exception once landed
  on main.
- **Pre-existing main blemish (ACCEPT + DOCUMENT — do NOT rewrite):** 4 commits authored `probe <a@b.c>`
  (`79d98d52`/`e2bc975a`/`27c25b13`/`ce3b2f88`, Jun 20, F-185 work) are **already on `origin/main`**
  (merged via F-185), NOT 197-only — so they cannot be author-rewritten "before this branch merges"
  without rewriting **protected main history**. Maintainer ruling (2026-06-24): accept as a pre-existing
  cosmetic blemish and document it; do NOT rewrite protected main for 4 author labels. (The 2026-06-20
  git-identity sandbox discipline still binds FUTURE fan-outs — this iteration's were clean.)

## Disposition

All blocker/major findings RESOLVED (G-197-I005-01 affirmative-pass `d31f4cb8`; the catalog-row
MAJOR `938731eb`). Carried items are pre-existing/out-of-scope and recorded. The delivered async
navigator + gate promotion + the dispatcher fixes are sound and green. **Iteration 005 is
ready-for-closeout**, with one honest residual: the navigator fires the verdict-emitting STUB today
(it never satisfies the gate); wiring the REAL reviewer is the post-closeout fast-follow.
