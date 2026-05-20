---
proposal: 067
title: Small-Fix Slice Type (Lightweight Lifecycle for 2-3 SP Changes)
status: draft
phase: phase-2
estimated-sp: 5
discussion: ad-hoc 2026-05-20 session
---

# Small-Fix Slice Type

## Why

Specrew today has effectively two slice shapes for delivering changes:

1. **Full feature lifecycle** (specify → clarify → plan → tasks → implement → review → retro → iteration-closeout → feature-closeout) — designed for 7+ SP work where design decisions and acceptance criteria need to be captured upfront.
2. **Raw chore commit** — direct edit to main with only a commit message, used informally for 1-3 SP fixes.

The middle is empty. Two-to-three-SP changes — fixing a typo, changing an icon, flipping a default flag, updating a tagline, swapping one asset for another — fall into a gap. Running them through the full lifecycle is ceremony out of proportion to the work; landing them as raw chores skips the documentation discipline Specrew explicitly stands for.

User direction (2026-05-20 ad-hoc session):

> "Small fixes. I mean very small like 2-3 SP, change the icon, fix typo, or even a flag do not need a full cycle of spec, plan, ... But we do need documentation and running tests. They can join a later release or be released in a minor release. Add a proposal for such a changes."

The empirical motivation is fresh: in the past 24 hours, three changes shipped that should have used this slice type but had no formal home —

- Commit `c55ec92` (gate-respecting default + `--autonomous` flag) — shipped as raw chore, retroactively documented at commit `ecd7b6d` after the user flagged the methodology gap
- Commit `d288286` (logo asset addition + README reference) — shipped as raw chore with no proposal entry
- Commit `da2ca7f` + `1838034` (ASCII banner art) — shipped as raw chores with no proposal entry

Each was 1-3 SP. None warranted a feature lifecycle. All three should have followed the slice contract this proposal defines.

## What

A formal **small-fix** slice type with a defined lightweight contract. Composes with Proposal 055 (Always-In-Flow Discipline + Slice-Type Catalog) — when 055 ships, the catalog absorbs this slice; until then, this proposal stands alone as the contract.

### Eligibility criteria

A change qualifies as a small-fix slice if all of the following hold:

| Criterion | Threshold |
|---|---|
| **Effort** | ≤ 3 SP (typically 1-3 hours of work) |
| **Surface** | Touches few files (typically 1-5); no new architectural concepts |
| **Risk** | No new public API contract (or only adding a new opt-in flag/option); no breaking changes; no migration step |
| **Reversibility** | Trivially revertable via `git revert` if it goes wrong |
| **Independence** | Does not require coordinated changes across multiple components or repos |

Examples that qualify:

- Typo or wording fix in docs
- Icon, logo, or asset swap (with updated references)
- Adding a new opt-in CLI flag with backward-compatible default
- Flipping a default value (when the alternative is preserved as opt-in)
- Updating a tagline, brand element, or color
- Adding a test case to existing test surface
- Bumping a dependency version (no breaking change)
- Adding documentation references / cross-links

Examples that do NOT qualify (must use full feature lifecycle):

- New CLI command or skill
- New validator rule
- New lifecycle phase or gate
- Schema change that requires migration
- Behavior change that affects multiple integration points
- Anything that needs design discussion or acceptance criteria captured before implementation

### Required artifacts (the contract)

A small-fix slice MUST produce all of the following at ship time:

| Artifact | Where | Why |
|---|---|---|
| **Code change** | Wherever applies | The actual fix |
| **Test update or new test** | `tests/integration/...` or `tests/unit/...` | Proves the fix works AND prevents regression. If the surface has no existing test coverage, a minimum smoke test must be added. |
| **CHANGELOG.md entry** under `## Unreleased` | `CHANGELOG.md` | Records the change for the next release |
| **Proposal entry** (this proposal's pattern) | `proposals/NNN-<slug>.md` with `status: shipped` and `shipped-as: chore <commit-sha>` | Design rationale + cross-references; future-readable |
| **INDEX.md update** | `proposals/INDEX.md` Shipped section | Discoverability |
| **Commit message** | Git history | Standard substantive commit message with WHY + WHAT |

A small-fix slice does NOT require:

- spec.md, plan.md, tasks.md, research.md, data-model.md, contracts/ — these are feature-lifecycle artifacts
- `specrew start`-driven Squad orchestration — direct commits are sanctioned
- Feature branch + PR — direct commits to main are sanctioned (developer judgment per memory `feedback-check-branch-before-chore-commit`)
- Retro artifact — the methodology learning, if any, goes into the proposal's body or a memory entry
- Iteration-closeout dashboard — N/A for non-iteration work

### Release coupling

Small-fixes ride along on the next minor release. They DO bump the patch version of the next release but do NOT trigger a release on their own:

- If a feature is in flight (e.g., F-024 → v0.24.0), small-fixes that land on main between now and F-024's closeout ship as part of v0.24.0.
- If no feature is in flight and the small-fix is urgent (security, regression, critical bug), the maintainer can trigger a patch release (v0.X.Y → v0.X.(Y+1)) immediately. Small-fix proposals can include a `release-urgency: immediate | next-minor | next-major` field to signal intent.
- The `## Unreleased` section of CHANGELOG.md accumulates small-fix bullets until the next release rolls them into a versioned heading.

### Slice tracking

For visibility into what's queued under `## Unreleased`:

```text
proposals/INDEX.md Shipped section gains a "shipped-as" column that
distinguishes feature-NNN entries from chore-SHA entries. Filter on
"chore" prefix to enumerate all small-fix slices that have shipped
since the last release.
```

This makes `git log` redundant for the typical maintainer question "what small-fixes have shipped since v0.23.0?"

## How

### Phase 1 — Contract documentation (this proposal serves as the contract)

This proposal IS the contract. No additional documentation work needed beyond:

- Cross-linking from `docs/user-guide.md` (developer-facing guide on when to use small-fix vs feature lifecycle)
- Adding the contract reference to the feedback memory at `feedback_always_in_flow_universal_evidence.md`
- When Proposal 055 ships, fold this slice type into its catalog

### Phase 2 — Tooling (optional, defer to follow-up)

Optional automation that would make the small-fix slice more discoverable and consistent:

- `specrew propose --small-fix <title>` — scaffolds a proposal file with the right frontmatter
- `specrew changelog --unreleased` — lists current `## Unreleased` entries
- Validator rule that warns if a commit on main touches code without an accompanying CHANGELOG and proposal entry, and the commit author is not flagged as exempt (release commits, merge commits, etc.)

These are nice-to-have, not blocking the slice-type adoption.

### Phase 3 — Composition with Proposal 055

When Proposal 055 ships, its slice-type catalog absorbs this proposal as one of N defined slice types. The catalog will likely include:

- **small-fix** (this proposal) — 1-3 SP, no spec/plan
- **bug-fix** (per Proposal 055's `bug-fix` slice) — defect repair with explicit reproduction + regression test
- **refactor** (per Proposal 055) — code-quality slice that doesn't change behavior
- **doc** (per Proposal 055) — pure documentation
- **test-add** (per Proposal 055) — new test coverage
- **upgrade** (per Proposal 055) — dependency or tooling version bump
- **feature** (existing full lifecycle) — 7+ SP user-facing capability
- **hot-fix** (per Proposal 055) — urgent regression repair

When 055 ships, this proposal's status updates to "absorbed" and points at 055's catalog entry.

## Acceptance criteria

| AC | Statement |
|---|---|
| AC1 | A maintainer making a 2-3 SP change has clear guidance on which slice type to use, what artifacts are required at ship time, and how the change rolls into the next release |
| AC2 | The artifact contract (code + tests + CHANGELOG + proposal + INDEX) is documented in a single discoverable place (this proposal, until Proposal 055 absorbs it) |
| AC3 | Existing small-fix shipped changes (logo addition, banner ASCII, gate-respecting default) have proposal entries that demonstrate the pattern (commits `d288286`, `1838034`, `c55ec92`/`ecd7b6d` covered) |
| AC4 | The pattern reduces the latency from "user identifies fix" → "shipped on main with full documentation" to ≤ 1 hour for changes that fit the eligibility criteria |
| AC5 | Future small-fix slices can be referenced by their proposal number rather than only by commit SHA (e.g., "see Proposal 067" rather than "see commit c55ec92") |

## Out of scope

- Automation for the slice (`specrew propose --small-fix`, `specrew changelog --unreleased`) — defer to Phase 2
- Validator rule enforcing the artifact contract — defer to Phase 2
- Migration of pre-2026-05-20 chore-only commits into retroactive proposal entries — only commits where the design rationale is non-trivial warrant retroactive documentation; trivial chores stay as commit-only

## Composition

| Proposal | Relationship |
|---|---|
| **055 (Always-In-Flow Discipline + Slice-Type Catalog)** | When 055 ships, its catalog absorbs this proposal. Until then, this proposal stands alone as the small-fix contract. The empirical evidence for 055's catalog (proposals 066 + 067 themselves) demonstrates the gap 055 closes. |
| **066 (Gate-Respecting Default)** | Shipped as small-fix slice retroactively (after the user flagged the methodology gap). Proposal 067 formalizes what 066 demonstrated. |
| **033 (Specrew Governance CLI)** | Phase 2 tooling for small-fix slices (e.g., `specrew propose --small-fix`) could fold into 033's CLI surface. |
| **028 (Public Proposals Surface)** | Auto-generation of INDEX.md from per-proposal frontmatter would simplify the small-fix INDEX update step (currently manual). |

## Cross-references

- Empirical evidence: commits `d288286` (logo), `1838034` (banner), `c55ec92` (gate-respecting), `ecd7b6d` (retroactive docs for c55ec92), and this proposal's own ship commit
- Memory: `[[feedback-always-in-flow-universal-evidence]]` — 2026-05-18 feedback that motivated formalization
- Memory: `[[project-f024-boundary-compaction-breach-2026-05-20]]` — the specific incident whose fix exposed the gap
- file:///C:/Dev/Specrew/proposals/055-always-in-flow-bug-fix-lifecycle.md
- file:///C:/Dev/Specrew/proposals/066-gate-respecting-default.md
- file:///C:/Dev/Specrew/proposals/INDEX.md
