# Design Analysis: Specrew Refocus — Slash Command + Event-Driven Auto-Refocus

**Feature**: 171-specrew-refocus
**Iteration**: 001
**Date**: 2026-06-06
**Status**: awaiting human option verdict

## Problem Framing

Methodology drift is empirically born at three moments: compaction destroys the corpus in context; cold/bypass launches never load it; long sessions cross lifecycle gates with stale discipline. The shipped answer (coordinator advisory + human awareness) is discretionary — it asks a possibly-drifted agent or a busy human to notice drift. Proposal 146 (amended `2199a8dd`) demands a reactive manual surface AND mechanical re-injection from triggers that live outside the model's context, multi-host honest.

## Decision Points (resolved in the intake workshop, human-confirmed per lens)

1. Engine placement → deployed extension script (downstream-capable, no module import per fire)
2. Trigger delivery → host-neutral contract + 3 channels (lifecycle stdout / primer floor / host hooks)
3. B3 detection → watch the state (boundary-cursor diff), never the actor
4. Scope mapping → data-driven catalog with schema_version + provider registry
5. Payload → general + per-stage digest family with drift guardrail
6. Hook multiplexing → ONE dispatcher per event, ordered/budgeted registry
7. Runtime state → per-session files keyed by sanitized host session id
8. Safety → automatic circuit breaker + 3 manual kill-switch levels + journal + reason codes
9. Compaction → managed compaction points (`--compact-instructions`); auto-compact steering research-gated

## Options

### Option A — Simplest: manual surface + host-neutral channels only

Pillar A slash command, wrapper-stdout boundary emission, primer pointer, digests + catalog. NO hook layer, no breaker (no automation to guard). ~8-10 SP, 1 iteration.

- **Design-principle rationale**: smallest thing that delivers value everywhere; zero new host coupling.
- **Explicit future cost**: the two empirically worst drift events — compaction and bypass launches — stay uncovered; the feature's central thesis (non-discretionary triggers) is unrealized; hooks arrive later as a second feature paying re-integration cost.

### Option B — Reasonable: A + Claude hook binding only

Everything in A, plus the dispatcher/provider/registry machinery bound on Claude (B1/B2/B3), breaker, journal, compaction points. Antigravity/Cursor/Codex bindings deferred to research-gated fast-follow slices. ~15-18 SP, 2 iterations.

- **Design-principle rationale**: ship the non-discretionary layer where the surface is documented today; defer unverified surfaces.
- **Explicit future cost**: multi-host parity (the product's load-bearing promise) ships asymmetric; per-host follow-ups re-open the same code three times; the maintainer explicitly rejected Claude-first framing during the workshop.

### Option C — By the book: B + research-verified bindings for ALL hook-capable hosts (workshop-bound scope)

The full workshop-bound scope: trigger contract + channels + digest family + dispatcher/registry + per-session state + breaker/kill-switches/journal + compaction points + a research-matrix artifact per host, with verified bindings for Claude, Antigravity, Cursor, and Codex-where-expressible inside this feature; Copilot documented-variance on channels 1+2. ~18-25 SP, 2 iterations (research tasks lead iteration 002).

- **Design-principle rationale**: matches the architecture's volatility cut (per-host adapters over one engine) and the product's host-neutrality guarantee; research gates keep unverified surfaces honest rather than excluded.
- **Cost**: largest scope; schedule risk concentrated in per-host research (bounded by the research-matrix gate: a host that fails verification ships channels-only with documented variance, not a slipped feature).

## Crew Recommendation

**Option C** — it is the scope the human already bound during the intake workshop (architecture-core decision 2: "All hook-capable hosts in this feature"), it is the only option consistent with the recorded multi-host correction, and its schedule risk is structurally bounded (research-matrix verification gates each binding; failure degrades that host to channels 1+2 with documented variance instead of blocking the feature).

## Co-Design Record

**Design method (human-bound, lens 1)**: repo-established layering = IDesign-style volatility cut — volatile per-host trigger adapters over a stable host-neutral engine over versioned data.

**Component-to-responsibility map (co-designed and human-agreed at the component-design lens; re-confirmed at this stop):**

```text
                        TRIGGER ADAPTERS (volatile, per-host)
  +----------------+  +--------------------------------------+  +---------------------+
  | RefocusSkill   |  | SpecrewHookDispatcher                |  | CoordinatorAdvisory |
  +-------+--------+  +------+-----------------+-------------+  +----------+----------+
          |                  v                 v                           |
          |        +------------------+ +----------------------------+    |
          |        | RefocusProvider  | | RefocusRuntimeState        |    |
          |        +--------+---------+ +----------------------------+    |
          v                 v                                             v
  +--------------------------------------------------------------------------+
  |                         RefocusEngine (stable)                           |
  +------+------------------------------+------------------------------------+
         v                              v
  +---------------------+   +----------------------------------+
  | RefocusScopeCatalog |   | RefocusDigests                   |
  +---------------------+   +----------------------------------+
         ^
  +------+--------------------------------------------+
  | WrapperEmission (channel 1, all hosts)            |
  +---------------------------------------------------+
  Cross-cutting: HostHookBindings · DeployIntegration · DigestDriftCheck
```

- `RefocusSkill` — the `/specrew-refocus` manual surface per host
- `SpecrewHookDispatcher` — the ONE registered handler per host event; provider ordering, budget arbitration, dedupe, fail-open
- `RefocusProvider` — registry row #1; event/source → engine scope routing (B1/B2/B3)
- `CoordinatorAdvisory` — fallback suggestion surface + boundary-packet compact hygiene
- `RefocusEngine` — scope → catalog → digests → banner + payload; pure; never dedupes humans
- `RefocusScopeCatalog` — scopes, triggers, budgets, provider registry (data, versioned)
- `RefocusDigests` — general + 10 per-stage purpose-authored digests with declared sources
- `RefocusRuntimeState` — per-session dedupe + breaker + journal files
- `WrapperEmission` — boundary-sync wrapper stdout payload (every host)
- `HostHookBindings` — per-host binding declarations (research-gated)
- `DeployIntegration` — managed mirrors + managed-with-overlay catalog + merge-aware hook config
- `DigestDriftCheck` — test-lane currency warn

**Agreed key flow (dedupe-correct B3):** boundary-sync advances cursor → WrapperEmission appends `general + <next-stage>` payload to stdout (all hosts) and fingerprints it → next hook event on a hook-bound host: Dispatcher → RefocusProvider state-diffs per-session RuntimeState → fingerprint present → silent (journal: deduped); wrapper path bypassed → un-fingerprinted crossing detected → inject now (journal: injected).

**Human-agreed**: yes — co-designed across the 7-lens intake workshop 2026-06-06 (architecture and component map iterated with three human-raised design changes: multi-host trigger contract; dispatcher + provider registry; managed compaction points + breaker semantics). Re-presented and re-confirmed at this design-analysis stop.

## Human Decision

- **Chosen option**: PENDING — awaiting verdict in the shape `approved for plan with Option <X>`
- **Reason / modifications**: PENDING
- **Commit**: PENDING (the commit carrying this verdict record)
