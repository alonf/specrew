---
proposal: 062
title: Dependency Metadata + Reason Mapping + Impact-Analysis Propagation
status: candidate
phase: phase-2
estimated-sp: 18
discussion: tbd
---

# Dependency Metadata + Reason Mapping + Impact-Analysis Propagation

## Why

### The AI-agent argument (primary motivation)

Specrew's value proposition increasingly depends on AI agents making code changes safely. Human maintainers carry dependency context in their head — they know which features assume which contracts, why a particular abstraction was introduced, which test was load-bearing for which migration. **AI agents don't carry this context and there's no way to retrofit it.** Every AI-driven code change today is a coin-toss between "agent reads the surrounding code well enough to preserve the implicit contract" and "agent makes a locally-correct change that silently invalidates a contract in a sibling feature nobody is testing for."

A dependency graph with explicit reasons is the missing surface that lets an AI agent reason about side-effects BEFORE making a change. The workflow becomes:

1. Agent is asked to modify feature X
2. Agent runs `specrew dep show X` — sees what X depends on (incoming) and what depends on X (outgoing)
3. Each dependency has a stated reason: "F-Y depends on X because X provides the canonical `Resolve-ProjectPath` API; F-Y assumes the return value is always rooted"
4. Agent reads X, makes its change, and checks whether the change preserves each declared reason
5. If a reason is invalidated, the agent surfaces the breakage explicitly: "this change breaks the F-Y assumption that ... — should we (a) preserve the contract, (b) update F-Y too, or (c) propose deprecation?"

This is *exactly* the methodology surface that compounds value with every AI-driven change. Today the contract is invisible. After this proposal, it's a first-class artifact.

### The human-maintainer argument (secondary motivation)

Specrew's proposal and feature corpus has grown to ~40 candidate proposals + 10 draft proposals + 10 shipped feature specs. Cross-references are captured in prose only — every proposal has a "Cross-references" section listing related work with informal "composes with", "depends on", "sibling of" language. **There is no machine-readable graph, no reason recorded per dependency, and no propagation when a feature changes.**

The 2026-05-19 WSL trial made this gap concrete:

1. **F-021 contract assumption hidden**: Proposal 058 (Plugin-Based Distribution) assumed F-021's slash-command surface design was correct. When F-021's deployment path (`.copilot/skills/`) turned out to be wrong, 058's design assumptions were silently invalidated. No system flagged 058 for re-review.

2. **F-019 cross-platform claim load-bearing**: Proposals 042, 044, 045, 054, 058, 060, 061 all assume F-019 produced a cross-platform validation baseline. When the 5-bug Linux cluster surfaced, that baseline was empirically invalid — but no system listed which dependents needed assumption re-validation.

3. **F-020 schema contract proliferation**: Proposal 059 (Legacy-State Read-Tolerance) was authored assuming F-020's session-state schema was stable. Proposals 042, 054, 061 all implicitly depend on that same schema. If F-020's schema is revised, no system flags the dependent proposals for re-review.

4. **Reciprocal references partial**: when Proposal 059 was written, it listed 030, 035, 042, 054, 057 as composers. Did those proposals get reverse-edited to list 059? Manual check; no validator.

5. **Reasons missing**: even when proposal X lists "Composes with Y", the *reason* is sometimes spelled out and sometimes not. When future-you reads the cross-reference, the rationale must be reconstructed from memory.

The cost is *invisible drift*: assumptions made by proposal Y about feature X become wrong over time, and there's no mechanism to detect the divergence.

## What

Three coupled components: **(A)** extended frontmatter schema with `reason` per dependency, **(B)** validator + reciprocal-check, **(C)** propagation tooling for impact analysis. **Proposal-optional by design** — the discipline works for projects that don't use the proposals pattern.

### Proposal optionality (clarified scope)

The dependency graph is anchored in artifacts that exist in *every* Specrew project, with optional sources for projects that use richer planning surfaces:

| Source | When present | Role |
|---|---|---|
| `specs/<feature>/spec.md` frontmatter | **Always** (every Specrew project has feature specs once `/speckit.specify` runs) | **Universal anchor.** Feature-to-feature dependencies. The minimum coverage every project gets. |
| `.specrew/roadmap.yml` entries | When [057](057-roadmap-spine-input-adapter-pattern.md) ships | Project-wide planning-level dependencies. Edges between roadmap entries (e.g., "F-005 is blocked by F-003"). |
| `proposals/*.md` frontmatter | Only when the `proposal-driven-design` profile (per [052](052-specrew-profile-system.md)) is active | Design-stage dependencies (pre-spec). Edges between proposals before they promote to features. |

`specrew dep` reads from whichever sources exist in the project and merges them into a unified graph:

- **Minimum project** (just feature specs): two-source graph — only feature-to-feature edges. Still highly valuable for AI agents reasoning about feature change impact.
- **Roadmap-spine project** (specs + roadmap.yml per [057](057-roadmap-spine-input-adapter-pattern.md)): adds planning-level edges and the human-facing roadmap view.
- **Proposal-driven project** (specs + roadmap + proposals): full coverage including pre-spec design-stage edges.

Specrew itself uses all three sources. Most downstream projects will use one or two. **No downstream project is required to adopt proposals to benefit from this proposal.**

### A. Extended frontmatter schema

Every traced artifact (feature spec; roadmap entry; proposal — in that order of universality) gains a `dependencies:` block with the same schema:

```yaml
---
proposal: 062
title: Dependency Metadata + Reason Mapping + Impact-Analysis Propagation
status: candidate
phase: phase-2
estimated-sp: 18
dependencies:
  - target: proposal-028
    kind: depends-on
    reason: "028 provides the machine-readable proposal frontmatter foundation that this proposal extends. Without 028's metadata schema in place, the validator and tooling in this proposal have nothing structural to operate on."
    bidirectional: false
  - target: proposal-033
    kind: composes-with
    reason: "033's `specrew` CLI surface is where the impact-analysis commands (specrew dep) live. 033 already plans `specrew proposal` and `specrew roadmap`; this proposal extends with `specrew dep`."
    bidirectional: true
  - target: proposal-057
    kind: composes-with
    reason: "057's `roadmap.yml` can become the canonical materialized form of the dependency graph for the human-facing roadmap view. Without 057 the graph stays in frontmatter only."
    bidirectional: true
  - target: proposal-061
    kind: composes-with
    reason: "Dependency metadata is itself persisted state that should be exercised by 061's init/update convergence test (the graph file written at one version must be readable by the next version's tooling)."
    bidirectional: true
---
```

Dependency object schema (identical across all three sources):

| Field | Type | Required | Description |
|---|---|---|---|
| `target` | string | yes | The proposal-NNN, feature-NNN, spec-NNN, or roadmap-entry-id being referenced. Must resolve to an existing artifact in any of the three sources. |
| `kind` | enum | yes | Relationship type. v1 enum: `depends-on`, `composes-with`, `blocks`, `superseded-by`, `bundle-with`, `precondition`, `extends`. |
| `reason` | string | yes | Free-form prose, 1-3 sentences, explaining WHY this dependency exists. Required per the principle "every dependency must justify itself." This is the field AI agents read to know what invariant they must preserve. |
| `bidirectional` | boolean | no (default `true` for `composes-with`/`extends`, `false` otherwise) | If true, the target must declare the reverse dependency. Validator enforces. |
| `as-of-version` | string | no | If the dependency is on a specific shipped version (e.g., "depends on F-019 at v0.19.0 cross-platform claim"), the version pin. Lets us detect when a dependent's assumption is invalidated by a later version. |

**Cross-source references work**: a feature spec can declare a dependency on a roadmap entry, a proposal can declare a dependency on a shipped feature, etc. The validator resolves targets across all available sources.

### B. Validator (CI gate)

Add a new validator rule (gap #N continuing Proposal 004's series):

1. **Required fields**: every dependency entry MUST have `target`, `kind`, and `reason`. Empty `reason` fields fail with remediation hint: "Spell out why this dependency exists; the value is for future readers."
2. **Reference integrity**: `target` MUST resolve to an existing proposal/feature/spec file. Dangling refs fail.
3. **Reciprocal check**: when `bidirectional: true` (explicit or default), the target proposal MUST declare a reverse dependency. Validator reads both files; missing reverse fails with the suggested reverse-frontmatter to paste.
4. **Kind enum**: `kind` MUST be from the v1 enum. Free-form types fail.
5. **As-of-version validity**: when `as-of-version` is set, it MUST match a shipped tag. Misspelled or future versions fail.

Validator runs on every PR that touches `proposals/*.md` or `specs/*/spec.md`.

### C. Propagation tooling (`specrew dep` CLI surface)

New CLI subsurface, lives alongside `specrew roadmap`, `specrew proposal`, `specrew feature` (per [033](033-specrew-governance-cli.md)). **Reads from whichever sources are present in the project and merges them.**

| Command | Behavior |
|---|---|
| `specrew dep sources` | Reports which sources are active (feature specs / roadmap.yml / proposals) and how many edges each contributes. Useful for confirming the graph is reading what you expect. |
| `specrew dep graph [--format=mermaid\|dot\|json] [--source=specs\|roadmap\|proposals\|all]` | Emits the dependency graph in the requested format from the requested source(s). Mermaid for embedding in docs; DOT for Graphviz; JSON for tooling. Default `--source=all`. |
| `specrew dep show <target>` | Lists dependencies of `<target>` (outgoing) and dependents on `<target>` (incoming). Each row shows kind + reason. Aggregates across all sources. |
| `specrew dep impact <target>` | When `<target>` is being modified, lists every dependent that may need re-review. Output format: per-dependent, "this dependent depends on <target> for <reason>; verify the reason still holds after your change." **This is the primary surface AI agents call before modifying a feature.** |
| `specrew dep validate` | Runs the validator rules from component B locally. Useful before pushing a PR. |
| `specrew dep check-orphans` | Lists features/proposals/roadmap entries with no incoming dependencies. Orphans aren't bugs but flag candidate-for-supersession or candidate-for-withdraw. |
| `specrew dep transitives <target> [--max-depth=N]` | Lists transitive dependencies (depth-N). Useful for understanding the full assumption chain. |

### Impact-analysis at feature-update boundary

Add a closeout-template requirement (per Proposal 028's lifecycle hardening): at feature-closeout, if the feature changed a `specs/<feature>/spec.md` that has incoming dependencies, the closeout must include a "Dependency impact ledger" section listing each affected dependent and how the change was handled:

- "Affected: not impacted — change preserves the assumption"
- "Affected: updated — reverse-edited the dependent's reason field"
- "Affected: superseded — opened follow-up issue/proposal"

The validator enforces presence; the maintainer enforces honesty.

### Backfill

For Specrew itself (which uses all three sources):

- ~50 existing proposals + ~10 shipped feature specs → convert prose "Cross-references" sections into structured `dependencies:` blocks
- Roadmap.yml entries (when 057 ships) — add `dependencies:` to each entry

Maintainer reviews and blesses reasons per row.

Estimated Specrew backfill: ~6-10 hours across two evenings (each proposal/feature touched 3-5 references; ~250 dependency rows total).

For downstream projects (proposal-optional): the backfill is feature-spec-only and runs as a one-time `specrew dep init` migration that scaffolds empty `dependencies:` blocks for the project's existing spec.md files; the maintainer then fills in reasons over time as features evolve. No prerequisite proposal corpus required.

The prose Cross-references section can stay as a human-readable summary, OR be auto-generated from the structured frontmatter at the time `specrew dep show` is run.

## Effort

- **Iteration 1 (~10 SP)**: extended frontmatter schema documented (universal — works on specs/roadmap/proposals); validator rules implemented + tested; Specrew-side backfill of existing proposals + features; `specrew dep init` migration for downstream projects; documentation in `docs/dependency-graph-discipline.md`.
- **Iteration 2 (~10 SP)**: `specrew dep` CLI surface implemented (all seven subcommands including the new `sources`); multi-source merge logic with graceful degradation when sources are absent; closeout-template integration with impact ledger; cross-platform CI tests.

**Total: ~20 SP across two iterations** (revised up from 18 to account for multi-source merge logic and the `dep init` migration for proposal-optional projects).

## Phase placement

**Phase 2, Tier 2** (UX/methodology emphasis). After the bug-prevention quartet ships, this slots in as a methodology surface enhancement.

Recommended sequencing:

1. F-023 = 059 — Legacy-State Read-Tolerance (in progress)
2. Post-F-023 chore — slash-command path fix (~3 SP)
3. F-024 = 060 — Prerelease channel
4. F-025 = 061 — Init/Update Convergence Test
5. F-026 = 042 Iter 1 — Linux Command-Lifecycle E2E
6. **F-027 = this proposal (062)** — Dependency Metadata + Reason + Propagation

**Proposal 028 is no longer a hard prerequisite.** Because 062 is proposal-optional and carries its own minimal metadata schema (the `dependencies:` block, scoped to feature specs and roadmap entries at minimum), it can ship standalone. If Proposal 028 (Public Proposals Surface) ships first or concurrently, the proposal-source becomes fully covered too; if 028 ships later, 062's proposal-source is degraded but feature-source and roadmap-source remain fully functional.

For Specrew itself, ship 028 alongside or just ahead of 062 to get full three-source coverage. For downstream projects that never adopt proposals, 062 ships standalone with feature-source-only (plus roadmap-source if 057 is active in the project).

## Open questions

1. **Backfill ownership**: who writes the reason text for the ~250 backfill rows? Maintainer-only (deepest contextual knowledge) or contributor-assist (faster but inconsistent)? Recommend maintainer-only for v1; community contribution after Proposal 028 ships the contribution model.

2. **Reason quality enforcement**: validator can check "field present" but not "reason is meaningful". Should we add a minimum-length heuristic (e.g., reason must be ≥30 chars)? Or trust review? Recommend trust review, no length minimum.

3. **Auto-derivation vs explicit**: can the validator auto-derive `composes-with` reciprocals (if A→B is composes-with, generate B→A pointing to A)? Yes, easily. Should it auto-generate or require explicit? Recommend require explicit so the reason is captured at each end.

4. **Versioned dependencies**: `as-of-version` lets us record "depends on F-019 cross-platform validation AT v0.19.0". When v0.20.0 ships and invalidates that, do we flag the dependency automatically, or just preserve as historical record? Recommend flag with `specrew dep impact --target=F-019 --version=0.20.0` produces a warning ledger.

5. **`dep impact` heuristics**: at PR time, when the validator detects a change to a feature/proposal with incoming dependencies, should it FAIL the PR or just warn? Recommend warn at PR time, FAIL at merge time if the closeout-template Impact Ledger section is missing/empty.

6. **Graph visualization**: should `specrew dep graph` produce just text formats (mermaid/dot/json), or also render a PNG/SVG? Recommend text-only for v1 — Mermaid renders natively in GitHub, DOT renders with `dot -Tpng`.

7. **External dependencies**: should we capture dependencies on EXTERNAL artifacts (Spec Kit, Squad, PowerShell version, dotnet version)? Yes, useful, but probably as a separate `external-dependencies:` block per spec, not via the same mechanism. Defer to a follow-up proposal.

8. **Performance**: for a 50-proposal corpus, `specrew dep graph` should be sub-second. AST parsing + frontmatter extraction per file × 50 = ~5s on cold cache. Cache the parsed metadata in `.specrew/dep-cache.json` (a state file — itself subject to Proposals 059 and 061 disciplines).

## Risks

- **Backfill drudgery**: ~250 dependency rows × maintainer-blessed reasons = ~6-10 hours. Mitigation: split across multiple evenings; backfill in the same PR as 028 (the prerequisite ships the frontmatter foundation).
- **Reason rot**: reasons become stale as features evolve. Mitigation: every feature-closeout that touches a dependent must update the reason if applicable (impact ledger discipline).
- **Over-engineering**: ~250 dependency rows for ~50 proposals is high effort relative to "just write prose". Mitigation: the cost is paid once; the value compounds — every future feature-update gets impact analysis "for free" after this is in place.
- **Tooling complexity**: `specrew dep` CLI surface adds ~6 subcommands. Mitigation: keep each subcommand single-purpose; share parsing logic.
- **Validator false-positives at backfill time**: existing proposals have prose-only cross-references; the validator runs against frontmatter only. Mitigation: do not enforce until backfill is complete; ship as warnings during backfill, errors after.

## Cross-references

(Reasons captured per the discipline this proposal establishes; this section will be auto-generated from frontmatter once 028+062 ship.)

- **[028](028-public-proposals-surface.md) (Public Proposals Surface)** — `depends-on`: 028 provides the machine-readable metadata foundation; this proposal extends with reason+propagation. Must ship before or alongside this proposal.
- **[033](033-specrew-governance-cli.md) (Specrew Governance CLI)** — `composes-with`: 033 is the home for `specrew dep` CLI surface; this proposal extends 033's command surface.
- **[057](057-roadmap-spine-input-adapter-pattern.md) (Roadmap Spine)** — `composes-with`: 057's `roadmap.yml` can become the canonical materialized form of the dependency graph for human-facing roadmap views.
- **[059](059-legacy-state-read-tolerance.md) (Legacy-State Read-Tolerance)** — `composes-with`: the dependency cache file (`.specrew/dep-cache.json`) is persistent state subject to 059's reader-tolerance discipline.
- **[061](061-init-update-convergence-test.md) (Init/Update Convergence Test)** — `composes-with`: the metadata-cache file and the impact-ledger artifacts must converge across init/update paths.
- **[004](004-validator-hardening.md) (Validator Hardening, shipped F-013)** — `extends`: adds new validator rules to the surface F-013 established.

## Status history

- 2026-05-19: candidate captured during F-023 review session. Maintainer surfaced the gap directly: "We really need metadata of each feature/proposal to have the dependencies mapping and the reason of each dependency to make sure when we update or create a feature we know to fix and check all the dependencies." Empirical motivation: the 6-bug WSL trial included multiple cases (F-021 contract assumption hidden, F-019 cross-platform claim load-bearing, F-020 schema contract proliferation) where dependent proposals' assumptions were silently invalidated.
