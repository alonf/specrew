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

Specrew's proposal and feature corpus has grown to ~40 candidate proposals + 10 draft proposals + 10 shipped feature specs. Cross-references between them are captured in prose only — every proposal has a "Cross-references" section listing related work with informal "composes with", "depends on", "sibling of" language. **There is no machine-readable graph, no reason recorded per dependency, and no propagation when a feature changes.**

The 2026-05-19 WSL trial made this gap concrete in multiple ways:

1. **F-021 contract assumption hidden**: Proposal 058 (Plugin-Based Distribution) assumed F-021's slash-command surface design was correct. When F-021's deployment path (`.copilot/skills/`) turned out to be wrong, 058's design assumptions were silently invalidated. No system flagged that 058 needed re-review.

2. **F-019 cross-platform claim load-bearing**: Proposals 042, 044, 045, 054, 058, 060, 061 all assume F-019 produced a cross-platform validation baseline. When the 5-bug Linux cluster surfaced, that baseline was empirically invalid — but no system listed which dependents needed assumption re-validation.

3. **F-020 schema contract proliferation**: Proposal 059 (Legacy-State Read-Tolerance) was authored under the assumption that F-020's session-state schema was stable. Proposals 042, 054, 061 all implicitly depend on that same schema. If F-020's schema is revised (e.g., a future schema v2), no system flags the dependent proposals for re-review.

4. **Reciprocal references partial**: when Proposal 059 was written, it listed 030, 035, 042, 054, 057 as composers. Did those proposals get reverse-edited to list 059 back? Manual check; no validator.

5. **Reasons missing**: even when proposal X lists "Composes with Y", the *reason* is sometimes spelled out and sometimes not. When future-you reads the cross-reference, the rationale must be reconstructed from memory.

The cost is *invisible drift*: assumptions made by proposal Y about feature X become wrong over time, and there's no mechanism to detect the divergence.

This proposal builds on the work in [028](028-public-proposals-surface.md) (which adds machine-readable metadata) to add the **dependency graph, reason capture, and impact-analysis propagation** layer on top.

## What

Three coupled components: **(A)** extended frontmatter schema with `reason` per dependency, **(B)** validator + reciprocal-check, **(C)** propagation tooling for impact analysis.

### A. Extended frontmatter schema

Build on Proposal 028's metadata expansion. Every proposal and feature-spec frontmatter gains a `dependencies:` block:

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

Dependency object schema:

| Field | Type | Required | Description |
|---|---|---|---|
| `target` | string | yes | The proposal-NNN, feature-NNN, or spec-NNN being referenced. Must resolve to an existing artifact. |
| `kind` | enum | yes | Relationship type. v1 enum: `depends-on`, `composes-with`, `blocks`, `superseded-by`, `bundle-with`, `precondition`, `extends`. |
| `reason` | string | yes | Free-form prose, 1-3 sentences, explaining WHY this dependency exists. Required per the principle "every dependency must justify itself." |
| `bidirectional` | boolean | no (default `true` for `composes-with`/`extends`, `false` otherwise) | If true, the target proposal must declare the reverse dependency. Validator enforces. |
| `as-of-version` | string | no | If the dependency is on a specific shipped version (e.g., "depends on F-019 at v0.19.0 cross-platform claim"), the version pin. Lets us detect when a dependent's assumption is invalidated by a later version. |

### B. Validator (CI gate)

Add a new validator rule (gap #N continuing Proposal 004's series):

1. **Required fields**: every dependency entry MUST have `target`, `kind`, and `reason`. Empty `reason` fields fail with remediation hint: "Spell out why this dependency exists; the value is for future readers."
2. **Reference integrity**: `target` MUST resolve to an existing proposal/feature/spec file. Dangling refs fail.
3. **Reciprocal check**: when `bidirectional: true` (explicit or default), the target proposal MUST declare a reverse dependency. Validator reads both files; missing reverse fails with the suggested reverse-frontmatter to paste.
4. **Kind enum**: `kind` MUST be from the v1 enum. Free-form types fail.
5. **As-of-version validity**: when `as-of-version` is set, it MUST match a shipped tag. Misspelled or future versions fail.

Validator runs on every PR that touches `proposals/*.md` or `specs/*/spec.md`.

### C. Propagation tooling (`specrew dep` CLI surface)

New CLI subsurface, lives alongside `specrew roadmap`, `specrew proposal`, `specrew feature` (per [033](033-specrew-governance-cli.md)):

| Command | Behavior |
|---|---|
| `specrew dep graph [--format=mermaid\|dot\|json]` | Emits the full dependency graph in the requested format. Mermaid for embedding in docs; DOT for Graphviz; JSON for tooling. |
| `specrew dep show <target>` | Lists dependencies of `<target>` (outgoing) and dependents on `<target>` (incoming). Each row shows kind + reason. |
| `specrew dep impact <target>` | When `<target>` is being modified, lists every dependent that may need re-review. Output format: per-dependent, "this dependent depends on <target> for <reason>; verify the reason still holds after your change." |
| `specrew dep validate` | Runs the validator rules from component B locally. Useful before pushing a PR. |
| `specrew dep check-orphans` | Lists proposals/features with no incoming dependencies. Orphans aren't bugs but flag candidate-for-supersession or candidate-for-withdraw. |
| `specrew dep transitives <target> [--max-depth=N]` | Lists transitive dependencies (depth-N). Useful for understanding the full assumption chain. |

### Impact-analysis at feature-update boundary

Add a closeout-template requirement (per Proposal 028's lifecycle hardening): at feature-closeout, if the feature changed a `specs/<feature>/spec.md` that has incoming dependencies, the closeout must include a "Dependency impact ledger" section listing each affected dependent and how the change was handled:

- "Affected: not impacted — change preserves the assumption"
- "Affected: updated — reverse-edited the dependent's reason field"
- "Affected: superseded — opened follow-up issue/proposal"

The validator enforces presence; the maintainer enforces honesty.

### Backfill

Walk all ~50 existing proposals + ~10 shipped feature specs. Convert prose "Cross-references" sections into structured `dependencies:` blocks. Maintainer reviews and blesses reasons per row.

Estimated backfill: ~6-10 hours across two evenings (each proposal touched 3-5 references; ~250 dependency rows total).

The prose Cross-references section can stay as a human-readable summary, OR be auto-generated from the structured frontmatter at the time `specrew dep show` is run.

## Effort

- **Iteration 1 (~10 SP)**: extended frontmatter schema documented; validator rules implemented + tested; backfill of existing proposals + features; documentation in `docs/proposal-metadata.md` and `docs/dependency-graph-discipline.md`.
- **Iteration 2 (~8 SP)**: `specrew dep` CLI surface implemented (all six subcommands); closeout-template integration with impact ledger; cross-platform CI tests.

**Total: ~18 SP across two iterations.**

## Phase placement

**Phase 2, Tier 2** (UX/methodology emphasis). After the bug-prevention quartet ships, this slots in as a methodology surface enhancement.

Recommended sequencing:

1. F-023 = 059 — Legacy-State Read-Tolerance (in progress)
2. Post-F-023 chore — slash-command path fix (~3 SP)
3. F-024 = 060 — Prerelease channel
4. F-025 = 061 — Init/Update Convergence Test
5. F-026 = 042 Iter 1 — Linux Command-Lifecycle E2E
6. **F-027 = this proposal (062)** — Dependency Metadata + Reason + Propagation
7. F-028 = 028 (Public Proposals Surface; this proposal's prerequisite for metadata foundation gets folded in here, or 028 ships JUST AHEAD of 062 as its prerequisite)

Note the sequencing tension: 062 depends on 028 (metadata foundation) for its frontmatter. Two options:

- **Option A: Ship 028 first.** 028 was sequenced earlier in the candidate queue; bring it forward to before 062.
- **Option B: 062 carries the minimal metadata schema needed for its own purposes**, defers the rest of 028's expansion. Cleaner separation but more work in 062.

**Recommended Option A** — ship 028 first so 062 has a clean foundation. 028 is ~13 SP; combined with 062 ~18 SP that's ~31 SP across two features, both Phase 2.

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
