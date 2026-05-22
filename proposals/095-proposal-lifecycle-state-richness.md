---
proposal: 095
title: Proposal Lifecycle State Richness (Partial, Frozen, In-Conflict, Per-Component, Multi-Dimension)
status: candidate
phase: phase-2
estimated-sp: 8-12
discussion: ad-hoc 2026-05-22 session
---

# Proposal Lifecycle State Richness (Partial, Frozen, In-Conflict, Per-Component, Multi-Dimension)

> **Profile scope**: This proposal is a **component of the `proposal-driven-design` profile** (Proposal 096). The schema extensions, validator rules, INDEX rendering, and `specrew proposal *` CLI commands described here apply only to projects that have activated the profile (Specrew itself, plus any downstream project that opts in). For non-activated projects, no `proposals/` directory exists and none of this machinery is loaded.

## Why

The current proposal lifecycle uses a single `status` field with six values: `candidate | draft | active | shipped | superseded | withdrawn`. This is too coarse for the proposal shapes Specrew has actually evolved:

### Empirical pattern 1 — bundle proposals with per-component status

**Proposal 086** (Validation Pipeline Performance Bundle): 5 pillars. Pillar 1 shipped as Feature 034. Pillars 2-5 remain candidate. The current schema cannot express this with a single `status` value. The workaround: the proposal is listed **twice in INDEX.md** — once under Shipped with title `"— Pillar 1 only (Validator Result Memoization)"` and once under Candidate with the title rewritten to describe just the unshipped pillars. The actual partial-ship state lives in prose, not data.

**Proposal 082** (Boundary Commit + Upstream Push Discipline): 3 tiers. Tier 1 shipped. Tiers 2+3 remain candidate. Same prose-in-INDEX workaround. Same fragility.

### Empirical pattern 2 — frozen-by-decision

There is currently no way to encode: *"we shipped Tier 1 of this proposal and have deliberately decided **not** to ship Tier 2 or Tier 3 — those are dead, not deferred."* Today the only honest expressions are: edit the proposal body to declare this (no schema enforcement; future readers may miss the note) OR add a new proposal that "supersedes" the un-shipped tiers (semantically wrong — nothing replaced them). Neither is satisfying.

### Empirical pattern 3 — in-conflict between proposals

When two candidates propose mutually exclusive approaches to the same problem (e.g., one proposes folding capability X into proposal A; another proposes a sibling proposal B for the same X), there is no way to flag the conflict in either proposal's schema. The conflict lives in memory or in discussion comments — easily lost.

### Empirical pattern 4 — merged-into is not superseded

When a smaller proposal is absorbed into a larger one (e.g., "this proposal's idea was folded into Proposal 033"), the semantics differ from supersession: supersession means *"X is replaced by Y"*; merger means *"X's content now lives inside Y"*. Today both collapse to `status: superseded` with a `superseded-by` field. Two distinct relationships, one expression.

### Empirical pattern 5 — orthogonal lifecycle dimensions are conflated

The current `status` field actually conflates four orthogonal dimensions:

1. **Discussion state** — has design conversation happened? (Proposal 093 starts to fix this)
2. **Spec state** — does an on-disk spec exist in `specs/`? Is it active or shipped?
3. **Implementation state** — has the proposed work been built and shipped?
4. **Conflict / relationship state** — is this proposal in conflict, blocked by, or merged into another?

A proposal can plausibly be `draft` (full source spec written) without an `active` spec on disk; or it can be `shipped` in part with other components still in `candidate`. The single `status` field cannot express this richness, so it picks a winner — and important state is lost.

User-stated motivation (2026-05-22):

> "How can I easily know if a proposal is already discussed, has a spec, implemented? How do I know if only part of the proposal is implemented? and which part? Do we have the notion of close|done|rejected|partially done but the rest will not be implemented|in conflict with other spec or proposal."

The current schema cannot answer these questions cleanly. INDEX.md prose can — partially, fragilely, and only by reading carefully. This proposal closes the gap by extending the schema, augmenting INDEX rendering, and adding a query command.

## What (4 Pillars)

### Pillar 1 — Extended status enum

The single `status` field is extended with three additional values:

| Value | Semantics |
|---|---|
| `candidate` | (unchanged) Idea captured, light description |
| `draft` | (unchanged) Full source spec drafted |
| `active` | (unchanged) Feature being implemented |
| `shipped` | (unchanged) Fully shipped |
| **`partially-shipped`** | One or more components shipped; one or more components still open. Required to be paired with a `components:` list (Pillar 2) so the partial state is queryable. |
| **`frozen`** | Some or all components shipped; explicit decision **not** to ship the remainder. Functionally complete from the project's standpoint. Required to be paired with a `frozen-reason:` field. |
| `superseded` | (unchanged) Replaced by a newer proposal. `superseded-by:` field required. |
| **`merged-into`** | Content absorbed by another proposal. `merged-into:` field required (distinct from `superseded-by`). This proposal's body becomes a historical pointer. |
| `withdrawn` | (unchanged) Explicit decision not to proceed. |
| **`in-conflict`** | Cannot advance until conflict resolved. `conflict-with:` field required. May resolve back to `candidate` / `draft` once the other proposal is decided. |

The validator rule (composes with Proposal 028) enforces that the auxiliary fields are present when their corresponding status value is used.

### Pillar 2 — Per-component lifecycle (the `components:` list)

For multi-tier / multi-pillar proposals, a `components:` list in frontmatter encodes per-component state:

```yaml
---
proposal: 086
title: Validation Pipeline Performance Bundle
status: partially-shipped
phase: phase-2
estimated-sp: 35
components:
  - id: pillar-1
    title: Validator Result Memoization
    status: shipped
    shipped-as: feature-034
    estimated-sp: 7
  - id: pillar-2
    title: Rule-Applicability Cache
    status: candidate
    estimated-sp: 8
  - id: pillar-3
    title: Validator Metadata Cache
    status: candidate
    estimated-sp: 6
  - id: pillar-4
    title: Batched State Writes
    status: candidate
    estimated-sp: 5
  - id: pillar-5
    title: Repetition Detector
    status: candidate
    estimated-sp: 9
---
```

Component-level status values use a subset of the top-level enum: `candidate | draft | active | shipped | frozen | withdrawn | merged-into`. A component cannot itself be `partially-shipped` (would imply unbounded recursion); if a component needs sub-decomposition, it should be promoted to its own proposal.

**Top-level `status` is derived from `components:`** with a clear rule (defined in the validator):

- All components `shipped` → top-level `shipped`
- All components `frozen` or `shipped` (mix) → top-level `frozen`
- Mix of `shipped` + open (`candidate|draft|active`) → top-level `partially-shipped`
- All components `candidate|draft|active` (none shipped) → top-level matches the most-advanced component (`draft` if any draft; `active` if any active)
- All components `withdrawn` → top-level `withdrawn`
- All components `merged-into` → top-level `merged-into`

The validator catches drift between top-level and derived state and fails (or warns; see open questions).

### Pillar 3 — Multi-dimension lifecycle (orthogonal status dimensions)

Four orthogonal dimensions are tracked separately so they can answer separate questions:

```yaml
---
status: partially-shipped              # implementation dimension (Pillar 1+2)
discussion-status: ad-hoc              # discussion dimension (composes with 093)
spec-status: on-disk-active            # spec dimension (new)
relationship-status: clean             # relationship dimension (new)
---
```

| Dimension | Values | Question answered |
|---|---|---|
| `status` | candidate / draft / active / shipped / partially-shipped / frozen / superseded / merged-into / withdrawn / in-conflict | "What is the implementation state?" |
| `discussion-status` | none / ad-hoc / public-thread | "Has design conversation happened? Where?" (subsumes Proposal 093) |
| `spec-status` | none / source-spec-drafted / on-disk-draft / on-disk-active / on-disk-shipped | "Does a spec exist? At what stage?" |
| `relationship-status` | clean / blocks / blocked-by / conflicts-with / merged-from / depends-on | "Does this proposal have unresolved relationship dependencies?" |

Each dimension can be queried independently. The CLI surface (Pillar 4) exposes filters per dimension.

The `spec-status` field deserves special attention: it answers "does an actual `specs/NNN-*` directory exist for this?" — which today requires manual cross-reference between proposal `shipped-as:` and filesystem state.

### Pillar 4 — INDEX rendering + query CLI

**Augmented INDEX rendering** (composes with Proposal 028's auto-rendering):

INDEX.md is generated from frontmatter. The table gains columns for the four dimensions. Multi-component proposals appear once with their `components:` list expanded as a sub-table. Partial-ship state is visible at a glance.

Conceptual rendering:

```text
| # | Title | Status | Discussion | Spec | SP (shipped/total) | Notes |
|---|---|---|---|---|---|---|
| 086 | Validation Pipeline Performance Bundle | partially-shipped | ad-hoc | on-disk-active | 7/35 | 1 of 5 pillars shipped |
|   └─ pillar-1 | Validator Result Memoization | shipped (feature-034) |   |   | 7 |   |
|   └─ pillar-2 | Rule-Applicability Cache | candidate |   |   | 8 |   |
|   └─ pillar-3 | Validator Metadata Cache | candidate |   |   | 6 |   |
|   └─ pillar-4 | Batched State Writes | candidate |   |   | 5 |   |
|   └─ pillar-5 | Repetition Detector | candidate |   |   | 9 |   |
```

The current twice-listed-with-prose workaround disappears.

**`specrew proposal` CLI surface** (folds into Proposal 033 when 033 ships; standalone otherwise):

| Command | Purpose |
|---|---|
| `specrew proposal status <NNN>` | Full lifecycle picture for a proposal: all 4 dimensions, components, relationships |
| `specrew proposal list --status=partially-shipped` | All proposals matching a status |
| `specrew proposal list --has-spec` | All proposals with `spec-status != none` |
| `specrew proposal list --no-discussion` | All proposals with `discussion-status = none` (or `tbd` legacy) |
| `specrew proposal list --conflicts` | All proposals with relationship issues |
| `specrew proposal list --frozen` | All proposals where parts were deliberately not shipped (audit surface for "what did we decide not to do?") |
| `specrew proposal components <NNN>` | Per-component status table for a multi-pillar proposal |

The CLI surface answers each of the user's original questions in one command.

### Sub-pillar — Composition with other proposals

This proposal sits at the intersection of several others. Each composition seam:

- **Proposal 028** (Public Proposals Surface) — owns auto-transition + discussion integration. This proposal owns the richer state schema. 028's auto-transition logic must be extended to handle component-level transitions: when a feature ships that maps to a *component* (via the component's `shipped-as` field), only that component transitions, and the top-level status is re-derived.
- **Proposal 062** (Reciprocal Dependency Metadata + Impact Analysis) — owns `depends-on` / `composes-with` / `blocks` cross-references. This proposal's `relationship-status` dimension is a *summary roll-up* of 062's per-relationship metadata. Composition: `relationship-status` is derived (any unresolved `blocked-by` → `blocked-by`; any unresolved conflict → `conflicts-with`; otherwise `clean`).
- **Proposal 093** (Discussion-Field Discipline) — owns the three valid `discussion:` field values. This proposal's `discussion-status` dimension is a normalization of 093's free-text field into a canonical enum. Composition: `discussion-status` is derived from the `discussion:` field (`tbd` → `none`; `ad-hoc *` → `ad-hoc`; URL → `public-thread`).
- **Proposal 091** (Technology Debt Control) — when a component transitions to `frozen`, optionally auto-create a debt entry capturing "we decided not to ship X". This is opt-in via the `frozen-reason:` field carrying a `create-debt-entry: true` hint. Useful for re-evaluation later.
- **Proposal 092** (Dashboard Web App) — primary consumer of the richer state. The roadmap view (#2) renders components + dimensions; query views (#29 search) filter on dimensions.

## Functional Requirements

- **FR-001**: Extended top-level `status` enum supports `partially-shipped`, `frozen`, `merged-into`, `in-conflict`
- **FR-002**: Frontmatter `components:` list with per-component fields: `id`, `title`, `status`, `shipped-as` (optional), `estimated-sp`, `frozen-reason` (optional)
- **FR-003**: Frontmatter dimensions: `discussion-status`, `spec-status`, `relationship-status` (each with its own enum)
- **FR-004**: Validator rule: top-level `status` matches derivation from `components:` (or explicit override with justification comment)
- **FR-005**: Validator rule: each status value's required auxiliary fields are present (`frozen` requires `frozen-reason`; `merged-into` requires `merged-into`; `in-conflict` requires `conflict-with`)
- **FR-006**: Validator rule: `spec-status` matches filesystem reality (`specs/NNN-*` directory exists if `on-disk-*`)
- **FR-007**: INDEX.md rendering shows the four dimensions + component breakdown for multi-pillar proposals
- **FR-008**: `specrew proposal status <NNN>` CLI command displays the full lifecycle picture
- **FR-009**: `specrew proposal list --<filter>` CLI command supports filtering on each dimension
- **FR-010**: Backfill migration: existing proposals with prose partial-ship encoding (082, 086) get `components:` lists populated during this proposal's ship
- **FR-011**: Self-applied: this proposal carries `discussion-status: ad-hoc`, `spec-status: none`, `relationship-status: clean` at ship — dogfoods its own schema
- **FR-012**: Documentation: README.md + `_template.md` updated to describe all 4 dimensions

## Out of scope

- Sub-component nested decomposition (components having sub-components) — promote to own proposal if needed
- Cross-proposal merge transactions (atomically merging one into another) — manual edit + validator catches inconsistency for now
- Time-travel queries ("what did this proposal look like 3 months ago?") — git log answers this; not a schema concern
- Voting / opinion-aggregation on proposals — out of scope; that's discussion-thread territory
- Multi-language proposal content
- Automated conflict-detection across proposals (heuristic-based) — relies on author marking `in-conflict` explicitly for now; auto-detection is a future enhancement

## Effort

- **Pillar 1 (extended enum + auxiliary field validation)**: ~1.5 SP — small schema change + validator rule additions
- **Pillar 2 (components list + derivation logic)**: ~3 SP — frontmatter parsing, derivation rule, validator check
- **Pillar 3 (four-dimension schema + derivation hooks)**: ~2 SP — schema + composition adapters with 093/062
- **Pillar 4 (INDEX rendering + CLI commands)**: ~2-3 SP — folds into 033's CLI if 033 has shipped; otherwise standalone PowerShell script
- **Backfill migration (082 + 086 + any others)**: ~1 SP — populate `components:` lists from existing prose
- **Docs update**: ~0.5 SP — README + template
- **Total**: ~8-12 SP, single iteration

## Phase placement

**Phase 2 — Tier 1 methodology**. Proposal-lifecycle clarity is foundational for everything that depends on knowing what's shipped, what's planned, and what was decided not to do. Composes with 028 + 062 + 091 + 092 + 093.

Sequencing recommendation: ships **after 028 + 093**, since both contribute primitives this proposal builds on (auto-transition mechanism from 028; discussion-status normalization from 093). Ships **before 092** dashboard work, since 092 consumes the richer state model.

## Open questions

1. **Severity of the top-level/derived `status` mismatch validator rule** — hard fail or soft warning? Recommendation: soft warning at MVP (since the rule is heuristic; sometimes the author has a reason to keep top-level distinct from the derivation), promote to hard fail once stable.
2. **Should `partially-shipped` proposals split rather than stay as bundles?** Counter-argument: bundles are coherent groupings (Proposal 086's 5 pillars share a design philosophy). Forcing them to split loses that. Recommendation: bundles stay; the `components:` list is the splitting-without-splitting mechanism.
3. **How does `frozen` interact with retros?** When a component is frozen, retro-of-the-shipped-half should capture *why* the rest was frozen. Recommendation: standard retro template addition; the `frozen-reason:` field is the durable record.
4. **What if a component is `frozen` and later un-frozen** (revisited decision)? Recommendation: status transitions `frozen → candidate` with `unfrozen-at` + `unfrozen-reason` recorded in status history. Rare but legitimate.
5. **Should `relationship-status` be auto-derived from 062's per-relationship metadata, or manually set?** Recommendation: auto-derived; manual override allowed for edge cases.
6. **Are the four dimensions enough?** Could imagine a 5th: `audience-status` (who is this for? users / contributors / maintainers / internal). Recommendation: out of scope for this proposal; revisit if pattern emerges.
7. **CLI output format for `specrew proposal status <NNN>`** — terse table or rich multi-section? Recommendation: terse table for `--quiet`, rich multi-section by default.
8. **What's the migration plan for proposals 082, 086 that already use prose partial-ship?** Recommendation: backfill during this proposal's iteration; both are well-documented enough that the `components:` list write-down is mechanical.
9. **Does `withdrawn` need any auxiliary fields** (reason, by whom)? Recommendation: yes — `withdrawn-reason:` should be required, parallel to `frozen-reason:`. Backfill scan for existing withdrawn proposals.
10. **Should there be a `defer` status** distinct from `candidate`? Argument: candidate is "we haven't decided"; defer is "we decided not yet, with a target horizon." Recommendation: out of scope; phase placement already conveys timing.

## Risks

1. **Schema sprawl** — adding three dimensions to frontmatter may feel heavy for simple proposals. *Mitigation*: all three dimensions have sensible defaults (`discussion-status: none`, `spec-status: none`, `relationship-status: clean`); simple proposals can omit them.
2. **Derivation rule disagreements** — author intends one state, derivation rule computes another. *Mitigation*: validator warns rather than blocks; author can override with explicit comment; rule is documented.
3. **Backfill regret** — existing proposals (especially 082, 086) get `components:` lists added that don't quite match the original intent. *Mitigation*: backfill happens with author review per proposal; not bulk-automated.
4. **Component fragmentation** — every multi-pillar proposal grows a long `components:` list; readability suffers. *Mitigation*: keep components to 3-7; if more, split into sibling proposals.
5. **Dimension proliferation** — once 4 dimensions exist, pressure mounts to add more. *Mitigation*: explicit "4 is enough for now; revisit if pattern emerges" stance; open question 6 makes this an explicit guard.
6. **INDEX rendering complexity** — auto-rendering with per-component breakdown is harder than the current flat table. *Mitigation*: ship rendering as a separate small chore after the schema lands; flat-with-status-only is acceptable interim state.
7. **CLI command divergence from dashboard (092)** — both surfaces query the same data; risk of formatting drift. *Mitigation*: shared data layer; CLI is a textual rendering of the same data the dashboard renders graphically.
8. **`merged-into` vs `superseded` confusion in practice** — authors may pick the wrong one. *Mitigation*: validator surfaces choice with prompt at status transition; documentation includes decision-help examples.

## Cross-references

- **Component of**:
  - [096 Proposal-Driven Design Profile](096-proposal-driven-design-profile.md) — this proposal is one of the components bundled under the `proposal-driven-design` profile umbrella; the schema + CLI surface described here is profile-gated, not Specrew core
- **Composes with**:
  - [028 Public Proposals Surface](028-public-proposals-surface.md) — owns auto-transition + validator; this proposal extends what 028 enforces
  - [033 Specrew Governance CLI](033-specrew-governance-cli.md) — `specrew proposal status / list` commands fold into 033's surface
  - [062 Reciprocal Dependency Metadata + Impact Analysis](062-reciprocal-dependency-metadata-impact-analysis.md) — provides per-relationship metadata; this proposal's `relationship-status` is a roll-up
  - [091 Technology Debt Control](091-tech-debt-control.md) — frozen components optionally auto-record as debt entries
  - [092 Specrew Dashboard Web App](092-specrew-dashboard-web-app.md) — primary consumer of the richer state in roadmap + query views
  - [093 Proposal Discussion-Field Discipline](093-proposal-discussion-field-discipline.md) — supplies the discussion-status enum normalization
- **Addresses gap raised by**:
  - User question (2026-05-22): "How can I easily know if a proposal is already discussed, has a spec, implemented? How do I know if only part of the proposal is implemented? and which part?"
- **Backfill targets**:
  - [082 Boundary Commit + Upstream Push Discipline](082-boundary-commit-and-upstream-push-discipline.md) — Tier 1 shipped (feature-031); Tiers 2+3 candidate → becomes `partially-shipped` with `components:` list
  - [086 Validation Pipeline Performance Bundle](086-validation-pipeline-performance-bundle.md) — Pillar 1 shipped (feature-034); Pillars 2-5 candidate → becomes `partially-shipped` with `components:` list
  - Other historical proposals with similar shape (scan during backfill)

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to user observation that the current schema cannot answer "is this discussed / has a spec / partially implemented / which part / frozen / in-conflict" cleanly. Four-dimension model proposed with backward-compatible enum extension and per-component breakdown. Awaiting clarify-time decisions on validator severity, derivation rule strictness, and CLI output format.
