# Design Analysis: Iteration 004 (Phase B — Always-On, post-185-merge)

**Feature**: 197-continuous-co-review
**Iteration**: 004
**Date**: 2026-06-23
**Base**: merge `6c502c20` (origin/main = F-185 host-neutral hook surface + 0.39.0-beta1)

## Headline finding: NO F-184 protected-surface edits required

Two read-only investigations of the merged code confirm every Phase B piece is reachable
without editing an F-184-protected surface (`specrew-hook-dispatcher.ps1`,
`shared-governance.ps1`, refocus discipline, host manifests are the protected set):

- The 185 dispatcher discovers Stop providers from the `refocus-scopes.json` REGISTRY
  (config, not protected) + a provider script under `scripts/internal/continuous-co-review/`
  (197-owned). 197 registers its navigator there — no dispatcher edit.
- The #2885 latency fix lives in `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`
  (NOT protected, NOT mirrored). Only the dispatcher + shared-governance are protected, and
  the fix touches neither.

## The four pieces

### A. #2885 — Stop-hook latency fix (parse-once-and-share)

The Stop hook is ~16s: ~11s is three INDEPENDENT transcript parses in
`Update-SpecrewRollingHandover` (verdict + packet + conversation-tail, each re-reading
`-Tail 500` and running `ConvertFrom-Json -Depth 40` per line); ~4s is the conformance
provider's own re-reads. Fix: a shared turns helper in `ConversationCaptureAccessor.ps1` —
parse the tail ONCE at the top of `Update-SpecrewRollingHandover`, pass the parsed turns to
all three consumers (each still applies its own raw/flattened transform + the synthetic
last-user-turn append, so the shared array is copied not mutated); plus a module-scope
`(path, mtime)` memo for the conformance provider's intra-process re-reads. **Cross-feature
(F-174/185 code) but non-F-184; authorized under "fix the critical issues."** Critical gap:
these bootstrap parse functions have ZERO unit tests today — the refactor MUST add them (a
parse-once correctness + a timing guard so the regression cannot silently return).

### B. Async Stop-hook co-review navigator (FR-026/030/031)

Register a `co-review-navigator` provider (`events: [Stop, agentStop, stop]`) in
`refocus-scopes.json` + `continuous-co-review-provider.ps1`. Stop providers run
SYNCHRONOUSLY within a shared ~20s budget, and a co-review spawns a reviewer (30s+), so the
provider MUST be ASYNC: on a real implement checkpoint (the Phase A dispatcher already
decides this) it FIRES the review in the BACKGROUND and returns immediately (fail-open,
exit 0); on a casual/unregistered stop it is a fast no-op. The background verdict surfaces
two ways: (1) at the NEXT stop the provider surfaces the prior checkpoint's verdict and, if
blocking, emits 185's `<<<SPECREW-STOP-BLOCK>>>` sentinel to force-continue; (2) the gate
floor (C) enforces at signoff. This respects #2885 (197 adds ~no synchronous cost).

### C. Gate enforcement wiring (FR-025)

Wire `Assert-ContinuousCoReviewSignoffGate` into `Invoke-SpecrewBoundaryStateSync` at the
review-signoff boundary (`scripts/internal/sync-boundary-state.ps1` — non-protected; 185
does not touch it). Behind a config flag (opt-in initially) so it does not abruptly block
every governed project's signoff before the auto-fire is validated.

### D. Reviewer-runs-in-repo execution model

The spawned reviewer's working directory becomes the repo (read-only by contract + the
mutation guard) so it can read config + run tests on the real host (Proposal 145 runtime
evidence; enables the maintainer smoke test). Design question: live repo with the mutation
guard scoped to tracked SOURCE (test-output/temp/.specrew allowed) vs an isolated checkout.

## F-184 footprint

NONE. All edits are on non-protected surfaces (`refocus-scopes.json` registry,
`scripts/internal/continuous-co-review/*`, `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`,
`specrew-handover-provider.ps1`, `specrew-conformance-provider.ps1`, `sync-boundary-state.ps1`).

## Capacity / sequencing

Four substantial pieces (~est 6/6/4/5 SP + the #2885 unit-test debt) likely exceed one
iteration's cap. Candidate split: **004a** = #2885 fix (A) + reviewer-execution model (D)
(both unblock + de-risk, independently shippable); **004b** = the async navigator (B) + gate
wiring (C) (the always-on auto-fire). To be set at plan time per the maintainer's scope call.

## Key decisions (pending maintainer input)

1. **#2885 scope**: do the full parse-once-and-share (A, ~11s) + conformance memo (~4s) +
   the new unit tests — yes/no.
2. **Async surfacing**: fire-at-checkpoint, surface-verdict-at-next-stop (+ STOP-BLOCK on
   blocking) AND gate-enforces-at-signoff — confirm the shape.
3. **Reviewer-execution**: live repo + source-scoped mutation guard (recommended) vs checkout.
4. **Iteration scope**: one big iteration vs the 004a/004b split.
