---
proposal: 109
title: Open-Feature Awareness + Multi-Feature Switching Discipline + Long-Running Feature Methodology
status: candidate
phase: phase-2
estimated-sp: 15-22
discussion: 2026-05-25 v0.27.0 release-readiness user feedback (alongside F-044 iter-008 closeout-docs work) — three coupled concerns about open-feature state-tracking surface
depends-on:
  - 035  # Session-State Durability & In-Flight Progress Tracking — supplies the persisted state model this proposal queries
  - 057  # Roadmap Spine + Input Adapter Pattern — supplies the feature-list anchor `.specrew/roadmap.yml`
composes-with:
  - 009  # Velocity Dashboard ("Where Am I?") — `specrew where` is the natural surface for open-feature listing
  - 010  # Multi-Developer Reconciliation — same FR-provenance machinery applies to multi-developer + multi-feature concurrency
  - 028  # Lifecycle Hardening / Governance CLI absorbs — `specrew feature` command surface is the natural place to expose feature-list operations
  - 066  # Gate-Respecting Default — informs the "park vs continue" UX at re-entry
blocks: []
---

# Open-Feature Awareness + Multi-Feature Switching Discipline + Long-Running Feature Methodology

## Why

User raised three coupled concerns at v0.27.0 release-readiness review (alongside F-044 iter-008 closeout-docs work). All three share the same underlying machinery — open-feature state tracking — but Specrew today addresses none of them as first-class methodology surface:

### Concern A — Specrew doesn't surface open work at session start

When the user runs `specrew start "<new feature description>"` against a project with one or more in-flight features, Specrew's current behavior:

- Reads `.specrew/start-context.json` for the last `session_state_boundary`
- If `session_state_boundary` is not `feature-closeout`, resumes the in-flight feature instead of starting a new one (per F-016 session-state durability)
- Does NOT explicitly tell the user "you have N open features; here they are; which one do you mean?"

The user can be ambushed: they intended to start a new feature; Specrew silently resumed an old one. The closeout-vs-pause distinction documented in iter-008's getting-started Step 5 + user-guide "Closing iterations + features" section LANDS the methodology — but doesn't yet surface the state at re-entry. Knowing about the gap is necessary but not sufficient; the tooling should surface it.

### Concern B — No mechanism to list all open iterations + features

`specrew where` today renders the velocity dashboard for the **active** feature. It does not list all open features the project has, their boundary states, or their relative priorities.

If a project has 3 features in flight (one paused at clarify, one paused at implement, one paused at retro), the user has no command to surface them all. They have to navigate `specs/` manually, read each plan.md, infer state from artifacts. The methodology promise is "the on-disk artifact is the source of truth" — but the human-facing surface should query that truth, not require manual navigation.

### Concern C — Multi-feature switching has no methodology stance

Is it allowed to switch to a new feature without closing the current one? Today the answer is implicit (yes, by `session_state_boundary` resume logic) but there is NO ceremony for it. The user can:

- Type `specrew start "<other feature>"` and get a confusing resume
- Edit `.specrew/start-context.json` manually to "park" the current feature (not documented)
- Force-close the current feature with stub artifacts (methodology violation)

None of these are documented or supported. The methodology should either:

1. Forbid multi-feature switching and require closeout-or-abandon before starting new
2. Permit it via an explicit `parked` ceremony at the current boundary, with re-find mechanics later

Picking (2) is correct (forbidding multi-feature switching is too restrictive for real projects with parallel concerns), but it needs an explicit ceremony, persistence, and re-find surface.

### Concern D — Features may never close

Some features genuinely do not finish in the canonical sense:

- **Long-running spikes**: exploration that produced learning but no shippable code
- **Abandoned explorations**: research that didn't pan out; the spec should record "why we stopped" rather than be force-closed with empty artifacts
- **Deferred-to-rewrite**: feature was paused because the better path is to start over; current branch should be parked + traced from the rewrite spec
- **Indefinite deferral**: blocked on external decisions (legal, partner integration, vendor capability) for months

Specrew today implicitly assumes every feature reaches `feature-closeout`. The closed-iteration-index and roadmap.yml schemas don't have a slot for "abandoned" or "indefinite-park" states. Reviewers (and the user themselves at retro time) have no methodology stance for "this feature legitimately never closes".

The user's exact phrasing (2026-05-25): "We also need to think about features that may not be closed forever, is it possible and part of the methodology?"

### Why the three concerns share machinery

A → B → C → D is a single methodology arc:

- A's "surface open features" needs the same state-query as B's "list open features"
- B's listing operation is the input to C's switching ceremony
- C's switching ceremony needs the same persistence as D's abandon ceremony
- D's abandoned-feature artifact (closeout-dashboard with abandonment reason) is just a closeout variant

A single proposal that designs the open-feature state model + surfaces + ceremonies + lifecycle states closes all four concerns coherently. Splitting them risks designing 4 incompatible state machines.

## What

A three-slice proposal. Each slice ships independently, but the state model is designed up front so later slices don't require schema migration.

### Slice 1 — Open-feature state model + dashboard surfacing

**State model**: extend `.specrew/start-context.json` with an explicit `open_features` array:

```yaml
session:
  active_feature_dir: "specs/043-multi-host-onboarding"
  session_state_boundary: "iteration-closeout"
  session_state_active: true

open_features:
  - feature_dir: "specs/043-multi-host-onboarding"
    title: "Multi-Host Onboarding"
    last_boundary: "iteration-closeout"
    last_iteration: "001"
    status: "active"  # active | parked | abandoned | indefinite
    last_session_at: "2026-05-25T14:00:00Z"
    parked_reason: null
  - feature_dir: "specs/044-per-host-architecture-refactor"
    title: "Per-Host Architecture Refactor"
    last_boundary: "iteration-closeout"
    last_iteration: "008"
    status: "active"
    last_session_at: "2026-05-25T20:00:00Z"
    parked_reason: null
```

The `open_features` list is the canonical truth for what's in-flight. State is derived from on-disk artifacts (each feature's `state.md` + `plan.md` Status), not authored manually — a `Update-OpenFeaturesIndex` helper rebuilds it from scratch when invoked.

**`specrew where` surfacing**: add an "Open features" section to the velocity dashboard:

```text
=== Open Features ===

| Feature | Last boundary | Last iter | Status | Last session |
|---|---|---|---|---|
| F-043 Multi-Host Onboarding | iteration-closeout | 001 | active | 2026-05-25 14:00 |
| F-044 Per-Host Architecture Refactor | iteration-closeout | 008 | active | 2026-05-25 20:00 (current session)|
```

The user can scan all open work at a glance. Closed features (those past `feature-closeout`) drop off the list automatically. This is the missing piece in concern B.

**`specrew start` ambush prevention**: when the user types `specrew start "<new feature description>"` and `open_features` has 1+ entries with `status != closed`, surface a three-section handoff:

```text
## What I just did

Detected 2 open features in this project that have not yet been closed:
- F-043 Multi-Host Onboarding (last boundary: iteration-closeout, iter 001)
- F-044 Per-Host Architecture Refactor (last boundary: iteration-closeout, iter 008, this session)

## Why I stopped

I stopped before starting a new feature because Specrew needs to know whether your "<new feature description>"
prompt is intended to start a fresh feature alongside the open ones, or to add a new iteration to one of them.

## What I need from you

Choose one:
- `new feature` — start a fresh feature ("<new feature description>") alongside the open ones (concern C path)
- `continue F-NNN` — add a new iteration to feature F-NNN (resume the existing feature)
- `close F-NNN as <variant>` — close feature F-NNN with one of: shipped | abandoned | indefinite-park
```

The user is no longer ambushed. This closes concern A.

### Slice 2 — Multi-feature switching ceremony + `specrew feature` command

**`parked` feature state**: when the user explicitly says "I'm pausing F-NNN to work on something else", the current feature transitions to `status: parked` with a `parked_reason`. Parked features remain in `open_features` but don't auto-resume on next `specrew start` — they wait for explicit `specrew feature resume F-NNN` invocation.

**`specrew feature` command surface** (composes with Proposal 028 lifecycle-hardening CLI):

```text
specrew feature list             # show all features (open + closed); equivalent to `specrew where` Open Features section
specrew feature park F-NNN       # current feature → parked; requires --reason
specrew feature resume F-NNN     # parked feature → active; sets as session active
specrew feature close F-NNN      # invokes feature-closeout for F-NNN even from non-active session
specrew feature abandon F-NNN    # transitions to status=abandoned (concern D); writes abandonment closeout-dashboard variant
specrew feature indefinite F-NNN # transitions to status=indefinite; writes indefinite-deferral closeout-dashboard variant
```

The ceremony for park: explicit verdict shape (`approved for park`), `--reason` mandatory, audit-trail entry in `.squad/decisions.md` recording the park reason + commit SHA at park time.

This closes concern C with explicit semantics rather than implicit silent resume.

### Slice 3 — Long-running feature lifecycle (abandoned + indefinite-park as first-class closeout variants)

**Three closeout variants** (extend feature-closeout to be a closeout-with-disposition):

| Disposition | When | closeout-dashboard variant | roadmap.yml status |
|---|---|---|---|
| `shipped` | Standard happy-path: all iterations closed, FRs delivered, AC verified | Standard closeout-dashboard.md | `complete` |
| `abandoned` | Exploration didn't pan out; spec records "why we stopped" | `closeout-dashboard.md` with **Abandonment** section explaining the learning, what was tried, what was kept, what wasn't | `abandoned` |
| `indefinite-park` | Blocked on external decision (legal, partner, vendor, etc.); may resume later | `closeout-dashboard.md` with **Indefinite Deferral** section explaining the block + expected revisit conditions | `indefinite-park` |

The verdict shapes:

- `approved for feature-closeout as shipped`
- `approved for feature-closeout as abandoned --reason "<learning summary>"`
- `approved for feature-closeout as indefinite-park --reason "<block summary>" --revisit-when "<condition>"`

**Validator check**: abandoned + indefinite features still produce closeout-dashboard.md (so the work is durably recorded), but the validator's FR-coverage rule changes from "all FRs must be implemented" to "FRs must be implemented OR explicitly marked abandoned with audit-trail entry".

This closes concern D — features can legitimately never reach the shipping state, but they ALWAYS reach a closeout (with disposition). Never-closing in the methodology sense (open forever in `start-context.json`) is not a state Specrew supports; abandoned/indefinite-park ARE supported, and both are closeouts with disposition.

## How

| Slice | Implementation surface | Effort |
|---|---|---|
| Slice 1: open-feature state model | `Update-OpenFeaturesIndex` helper (new) + `.specrew/start-context.json` schema extension + `specrew where` rendering + `specrew start` ambush-prevention prompt | 6-8 SP |
| Slice 2: switching ceremony + `specrew feature` CLI | `specrew feature {list,park,resume,close,abandon,indefinite}` dispatch + park/resume verdict shapes + audit-trail entries + tests | 5-7 SP |
| Slice 3: closeout variants | `sync-feature-closeout` extended with `-Disposition` parameter (values: shipped, abandoned, indefinite-park) + closeout-dashboard variant rendering + validator FR-coverage rule extension + tests | 4-7 SP |

**Total estimate**: 15-22 SP across three slices. Methodology-fundamental enough to justify a multi-iteration feature; not so large that it must wait for a major-version arc.

## Open Questions

1. **Sequencing relative to other Phase 2 work**: this proposal is methodology-fundamental but not blocking. Should it sequence ahead of Substantive Intake Questioning (Proposal 063 / F-029) and Cost-Aware Routing (Proposal 068 / F-031)? Probably no — those are also user-flagged urgent. Likely sequence Slice 1 alone before F-029 (so multi-host trial sessions show their feature backlog), then Slices 2/3 after.
2. **Migration path**: existing projects (Specrew itself, ClipBoard, calculator-walkthrough) don't have `open_features` in their `start-context.json`. The helper must back-fill on first run by scanning `specs/*/iterations/*/plan.md` Status fields. Cost should be ~seconds.
3. **Abandoned-feature retro mechanics**: do abandoned features still produce a retro? Probably yes (the learning IS the deliverable) — but the validator should accept a retro that records "what we learned and why we stopped" without the standard "what shipped" sections.
4. **Indefinite-park revisit semantics**: when does an indefinite-parked feature become abandoned? Should there be a configurable timeout (`indefinite_park_max_days`), or is that the user's call at re-review time? Lean toward "user's call" — automated timeouts add complexity without clear value.
5. **`specrew where` Open Features section: always-on or flag-gated?** Probably always-on when `open_features` has 2+ entries, hidden when 0-1. Avoids cluttering single-feature projects.

## Empirical Motivation Captured

User exact phrasing (2026-05-25, during v0.27.0 release-readiness review): "Also we need to check that if the user restart Specrew and ask to restart a new feature, older iterations and feature are closed or at least the user know if they are not, and we need a mechanism to tell the user about all open iterations and features if we allow to switch to another feature without closing this one. We also need to think about features that may not be closed forever, is it possible and part of the methodology?"

The three concerns in one sentence cover Concerns A + B + C + D respectively. Authoring as a single bundled proposal preserves the design coherence.

## Composition Notes

- **Proposal 035 (Session-State Durability)** supplies the persisted-state model this proposal extends. If 035 hasn't shipped at slice-1 implementation time, this proposal can author the `open_features` slot inside `start-context.json` as a first user of the extended schema.
- **Proposal 057 (Roadmap Spine)** supplies `.specrew/roadmap.yml` as the canonical feature-list anchor. This proposal's `open_features` array is the in-flight subset of roadmap.yml entries.
- **Proposal 009 (Velocity Dashboard)** is the natural rendering surface for Open Features (concern B). Slice 1 lands an extension to `specrew where` that respects 009's existing dashboard structure.
- **Proposal 028 (Governance CLI)** is the natural home for the `specrew feature` command surface. Slice 2 can ship its dispatch as a stand-alone, then merge into the 028 CLI when 028 lands.
- **Proposal 010 (Multi-Developer Reconciliation)** uses the same FR-provenance machinery for cross-developer conflict; this proposal's `open_features` state is single-developer multi-feature. 010 extends to multi-developer multi-feature, which is strictly more general.
- **Proposal 066 (Gate-Respecting Default)** informs the "park vs continue" UX: when re-entering a parked feature, gate-respecting mode applies the same boundary stops as a fresh feature would — the park doesn't relax discipline, just records a session-pause.

## Not in Scope

- Concurrent multi-host execution (Scenario B of Proposal 024 Multi-Host Runtime Abstraction). Multi-feature switching with single-host is this proposal; multi-feature + multi-host is 024.
- Cross-project feature awareness. This proposal is single-project multi-feature; multi-project state would require a global Specrew config layer (out of scope until empirical demand surfaces).
- Validator-driven enforcement of feature-closeout cadence (e.g., "warn if a feature has been parked > 30 days"). Methodology-evolution decision; revisit after this proposal ships.
