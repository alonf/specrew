# Design Analysis: Hook-Driven Session Bootstrap (Iteration 001)

**Feature**: 174-hook-driven-session-bootstrap
**Date**: 2026-06-08
**Boundary**: design-analysis (pre-plan)
**Builds on**: the 8-lens design workshop (see `../../lens-applicability.json` and
`../../workshop/`).

## Problem Framing

Proposal 172 turns the F-171 SessionStart B2 hook into the **primary** session
bootstrap path while keeping `specrew start` as a compatibility/host-selection
launcher. The design must add B2 bootstrap behavior without disturbing the F-171
dispatcher, round-trip the Proposal 130 handover, and clear stale/non-portable
session anchors (the merged-Feature-171 stale-recovery incident). The workshop
resolved the substantive design questions; this stop fixes the component
decomposition and physical structure before `plan.md`.

## Key Design Decision Points

- `specrew start` vs hook division of labor → launcher preface + hook bootstrap
  (architecture-core d1).
- B2 classification → handover-first, two-stage, validated against current project
  state before anchor classification (architecture-core d2).
- Render-first enforcement → mechanical via a `disallowed-tools` skill on Claude,
  prose floor everywhere (ui-ux d1/d2).
- Decomposition method → **IDesign volatility-based** (architecture-core d4).
- Deployment → reuse the F-171 loop, no new install path (devops d1).

## Alternatives

### Option A - Simplest: minimal patch

Add conditional bootstrap logic directly to the existing F-171 B2 path and the
`specrew start` launcher; no separate components. **Principle**: minimize moving
parts. **Cost**: classification, validation, stale-anchor clearing, and directive
construction all entangle with host/event handling — untestable in isolation,
exactly the silent-wrong-resume blind spot we are trying to remove.

### Option B - Reasonable: IDesign volatility-based (recommended)

Isolate volatile host/event/picker/file behavior behind stable
classification/validation/directive engines, orchestrated by two managers, over
resource accessors, reusing the F-171 dispatcher. **Principle**: encapsulate
volatility; keep the stable core pure and testable. **Cost**: more named
components, but each is small and independently testable, and the mode decision
stays pure (serves observability d2).

### Option C - By the book: layered + distributed coordination

Option B plus a remote lease/coordination layer for cross-machine same-feature
work. **Principle**: full correctness including distributed mutual exclusion.
**Cost**: remote state, identity, leases, expiry, conflict policy — violates the
thin-synthesis scope; explicitly deferred to a future proposal (security +
architecture-core d3).

## Applicable Lenses

*(FR-026 anti-omission coverage — each selected lens from
`../../lens-applicability.json`, pointing into the option comparison; full per-lens
records in `../../workshop/`.)*

- **architecture-core**
  Addressed: the option axis IS this lens's decision (launcher/hook division +
  decomposition); Option B realizes the volatility cut (stable classify/validate/
  directive engines), Option A entangles them in the F-171 path, Option C adds
  distributed coordination. Binding: IDesign volatility-based (architecture-core d4).
- **integration-api**
  Addressed: the data-oriented directive contract + SessionStart marker + fail-open
  error envelope are option-invariant; Option B isolates them in DirectiveEngine +
  accessors, Option A inlines them, Option C adds a remote contract (out of scope).
- **ui-ux**
  Addressed: render-first enforcement via the disallowed-tools skill + prose floor is
  identical across options; Option B gives it a clean seam (DirectiveEngine
  `render_first` + agent render), Option A buries it in the patch.
- **data-storage**
  Addressed: write-only exit hook, event/state-first staleness, and project-local
  resolution live in SessionStateAccessor/HandoverStore/ProjectMetadataAccessor under
  all options; Option B keeps them as testable accessors, Option A scatters the I/O.
- **security-compliance**
  Addressed: local-tree trust boundary + advisory-not-authorizing external state +
  fail-open/fail-closed posture are option-invariant; only Option C introduces a new
  remote trust surface (deferred to a separate proposal).
- **observability-resilience**
  Addressed: the structured journal record + per-path tests require the pure
  ClassificationEngine/DirectiveEngine that Option B provides; Option A's entangled
  logic makes per-path journal assertions hard — the deciding factor here.
- **requirements-nfr**
  Addressed: backward compatibility + idempotency + B1/B3 regression safety are met
  only by options that keep the F-171 dispatcher untouched; Option B/C preserve it
  cleanly, Option A patches into it and raises regression risk.
- **devops-operations**
  Addressed: reuse of the F-171 deploy loop + kill switch + no-new-install-path is
  option-invariant; Option B/C register components through it, and the file=component
  FileList obligation applies.

## Crew Recommendation

**Option B (IDesign volatility-based).** It delivers the testability the
observability and NFR lenses require, keeps the F-171 dispatcher untouched
(B1/B3 regression safety), and holds the thin-synthesis scope by deferring
distributed coordination to a separate proposal.

## Co-Design Record

**Human-agreed: yes (2026-06-08, Alon Fliess).** Co-designed interactively at the
design-analysis stop.

### Design method (binding constraint)

IDesign volatility-based decomposition. Volatility axis = how the outside world
varies (host event shapes, picker behavior, handover/state file presence); the
stable core is what bootstrap always does (classify → validate → build directive).

### Engine call-rule (binding constraint)

An Engine minimizes outbound calls to stay stable, **but may call an Accessor when
it can predict exactly which data it needs, or when the data is too large to pass
across the interface**; otherwise the Manager passes the small, fully-known data
in. Applied: ValidationEngine calls accessors directly (predictable, large reads);
ClassificationEngine and DirectiveEngine stay pure (Manager passes small objects).

### Component-to-responsibility map

```text
        direct host launch / session end
                     |
                     v
     ┌─────────────────────────────────────────┐
     │  F-171 HookDispatcher  (EXISTING, reused) │  ingest · kill-switch · breaker · dedupe · journal
     └───────────────┬───────────────┬───────────┘
            SessionStart B2           SessionEnd
                     v                 v
  Managers:  SessionBootstrapManager   SessionEndHandoverManager
                     |                        |
       ┌─────────────┼─────────────┐          v
       v             v             v     (handover write-only)
 ValidationEngine ClassificationEngine DirectiveEngine
       |  (pure)            (pure)
       v
 HandoverStore · ProjectMetadataAccessor · SessionStateAccessor · HookJournalAccessor
 Adapters (volatile): HostEventAdapter · LauncherIntegration
```

Managers (orchestrate, stable):

- **SessionBootstrapManager** — orchestrate SessionStart B2: gather → classify →
  build directive → dedupe → emit. Non-interactive.
- **SessionEndHandoverManager** — orchestrate SessionEnd: write handover
  (write-only); optional scoped local commit only if the off-by-default flag is set.

Engines (volatile logic behind stable contracts):

- **ClassificationEngine** (pure) — handover-first two-stage mode decision
  (full / welcome-back / cleared-anchor) + resolution chain.
- **ValidationEngine** — validate handover and anchor vs current project state
  (commit reachability, open/closed, portability, freshness, artifact match);
  clear stale anchors; emit `validation_findings`. Calls accessors directly.
- **DirectiveEngine** (pure) — build the data-oriented directive (mode, sources,
  required_reads, render_first, menu_intent, validation_findings, dedupe metadata).

ResourceAccessors (volatile I/O):

- **HandoverStore** — read/write the Proposal 130 handover (.md + index).
- **SessionStateAccessor** — read/write the session anchor + local-only SessionStart
  marker + active-session signals.
- **ProjectMetadataAccessor** — read specs/, .squad/active-features.yml, artifact
  status, and git merged-status.
- **HookJournalAccessor** — write the classification record through F-171's journal.

Adapters (most volatile, host-specific):

- **HostEventAdapter** — normalize per-host SessionStart/SessionEnd payloads.
- **LauncherIntegration** — `specrew start` preface + launcher↔hook dedupe handshake.

### Physical structure (file = component)

One `.ps1` file per component under `scripts/internal/bootstrap/` (paths pinned in
plan/tasks), dot-sourced into the module. A component's related functions live in
the same file; module export list controls visibility (public funcs exported,
helpers file-local); the contract (param + returned `PSCustomObject` shape) is
documented in comment-based help. One Pester `<Component>.Tests.ps1` per component.
Every new file MUST be added to the module FileList (recurring install-break gotcha).

### Agreed flow — full bootstrap that clears a stale anchor (original-incident path)

```text
direct launch
  -> HookDispatcher (B2) -> SessionBootstrapManager
  -> ValidationEngine: HandoverStore reads handover; ProjectMetadataAccessor says feature MERGED
                       -> handover not authoritative; SessionStateAccessor anchor absolute-path/closed -> CLEARED
  -> ClassificationEngine: no valid resume -> mode = full bootstrap (reason: cleared stale anchor)
  -> DirectiveEngine: directive{ mode:full, render_first:true, findings:[anchor cleared: merged] }
  -> HookJournalAccessor: record{ mode:full, anchor_cleared:merged }
  -> agent renders prose orientation + "Cleared a stale anchor to 171" + Resume/New/Pick
```

### Agreed UI layout (render-first sequence; ui-ux d1)

```text
[1] Orientation       Specrew version · host · project · lifecycle position
[2] Handover summary   only if validated; else omit or "(historical, not current)"
[3] State line         Welcome back | Full bootstrap | Cleared a stale anchor | unclean-exit warning
[4] Menu (TEXT first)  Resume - <feature> at <boundary> | New | Pick
---------------------------------------------------------------
[5] Structured picker  only after [1]-[4] visibly rendered, only where the picker is safe
```

## Human Decision

- **Chosen option**: Option B — IDesign volatility-based decomposition (the
  co-designed component map, engine call-rule, and file=component layout above).
- **Verdict**: "approved for plan with Option B" — Alon Fliess, 2026-06-08.
- **Rationale**: delivers the testability the observability and NFR lenses require
  (the pure ClassificationEngine/DirectiveEngine keep every mode path unit-testable),
  keeps the F-171 dispatcher untouched (B1/B3 regression safety), and holds the
  thin-synthesis scope by deferring distributed coordination (Option C) to a
  separate proposal.
- **Authorizing human**: Alon Fliess (structured verdict menu, 2026-06-08).
- **Design-analysis draft commit**: `b4be99ae`
- **Decision recorded in commit**: `fa33aff8`
