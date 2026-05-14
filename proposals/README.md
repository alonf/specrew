# Specrew Proposals

This directory is Specrew's public design pipeline. Each markdown file is a **proposal** for a feature, refactor, or methodology evolution. Following the pattern of [Rust RFCs](https://github.com/rust-lang/rfcs), [Python PEPs](https://peps.python.org/), and [TC39 proposals](https://github.com/tc39/proposals), this surface makes Specrew's roadmap transparent and discussable.

## Why this exists

Specrew governs lifecycle through enforced gates (`validate-governance.ps1`, hardening gates, retros, corpus rows). But the **design** of those features — what's coming next, what was considered and deferred, what's being debated — has historically lived in private memory. This directory makes that surface public.

Visitors can:
- See what's coming next without reading commit history
- Comment on proposed features before they ship
- Propose new features via PR
- Trace why a feature exists in its shipped form back to its original motivation

## Proposal lifecycle

Each proposal has a `status` in its frontmatter that transitions through:

| Status | Meaning |
|---|---|
| `candidate` | Idea captured, light description, no full source spec yet. Open for discussion. |
| `draft` | Full source spec drafted, ready for `/speckit.specify` ingestion when prioritized. Discussion is active. |
| `active` | Feature is being implemented in the main Specrew lifecycle (`feature.json` points at it). |
| `shipped` | Feature is complete, merged to main. Proposal retained for historical reference. |
| `superseded` | A newer proposal replaces this one. See `superseded-by:` field. |
| `withdrawn` | Explicit decision not to proceed. Reason in the proposal body. |

A proposal can move backward (e.g., `draft` → `candidate` if scope expands beyond what was specified). All transitions are recorded in the proposal's body section under "Status history."

## Proposal anatomy

Each proposal file has:

- **Frontmatter** — `proposal`, `title`, `status`, `phase`, `estimated-sp`, optional `discussion`, optional `shipped-as`, optional `superseded-by`
- **Why** — the problem this addresses or the value it adds
- **What** — the proposed solution (brief for candidates, full source-spec format for drafts)
- **Effort** — story-point estimate and iteration breakdown
- **Phase placement** — where this slots into the consolidated development plan
- **Open questions** — what needs clarification at `/speckit.clarify` time
- **Cross-references** — related proposals, memory entries, source artifacts
- **Status history** — append-only log of status transitions

See `_template.md` for the full structure.

## Discussion

Each proposal links to a discussion thread in this repo's GitHub Discussions under the "Methodology" category. Threads are created on-demand when a proposal reaches `draft` status; `candidate` proposals can skip discussion until they mature.

To comment on a proposal:
1. Open the linked discussion thread
2. Comment with concrete feedback, alternative designs, or implementation concerns
3. The maintainer reviews comments before any status transition

To propose changes to an existing proposal:
1. Open a PR with proposed edits to the proposal file
2. Reference the related discussion thread
3. The PR review is part of the proposal-evolution record

## How to propose a new feature

1. Open an issue using the **Feature Request** template, describing the problem and rough shape
2. Maintainer (or community contributor) drafts a proposal file with status `candidate`
3. Discussion happens in the linked thread; the proposal evolves
4. When the proposal reaches `draft` status, the source spec is detailed enough for `/speckit.specify` ingestion
5. When prioritized, the proposal transitions to `active` and the feature enters the Specrew lifecycle
6. When shipped, status transitions to `shipped`

External contributors are welcome to draft proposals. Maintainer accepts proposals via PR with the expectation that high-quality candidates are eventually picked up by Specrew's lifecycle.

## Numbering

Proposals are numbered sequentially in the order they enter this directory (NOT aligned with feature numbers in `specs/`). The `shipped-as:` frontmatter field links a shipped proposal to its corresponding feature directory.

Numbers are never reused; withdrawn or superseded proposals retain their number for historical reference.

## Relationship to other surfaces

- **`specs/NNN-<name>/`**: the canonical on-disk spec for shipped/active features. The proposal's `shipped-as:` field points here once a feature activates.
- **`docs/`**: user-facing documentation for shipped features. Proposals are for the design pipeline; docs are for usage.
- **`CHANGELOG.md`**: shipped-feature summaries. Proposals are forward-looking; the changelog is backward-looking.
- **`.specrew/quality/known-traps.md`**: corpus rows graduate to enforced rules; proposals can mature from corpus-row candidates if they need full feature implementation.
- **GitHub Discussions** (Methodology category): per-proposal discussion threads.

## Index

The index of current proposals — sorted by status, then number — is maintained as a separate file: see `INDEX.md` (auto-generated; do not edit directly).

For a roadmap-style view of phase placement, see the consolidated development plan referenced in proposal cross-references.
