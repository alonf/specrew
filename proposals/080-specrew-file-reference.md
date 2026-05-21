---
proposal: 080
title: Specrew File Reference (Lifecycle Catalog for All Specrew-Managed Files)
status: candidate
phase: phase-2
estimated-sp: 10-15
discussion: tbd
---

# Specrew File Reference (Lifecycle Catalog for All Specrew-Managed Files)

## Why

Specrew is a methodology that lives by its state files. A Specrew-managed project carries ~30-40 files across `.specrew/`, `.squad/`, `specs/`, `.specify/`, and the top-level repo root — every one of them with a specific purpose, lifecycle, expected schema, and "green status" condition.

Today, none of this is centrally documented. What exists is partial:

| Surface | Coverage |
|---|---|
| `docs/data-contracts.md` | Schema versioning conventions only (v0/v1 markers, reader/writer rules). Enumerates 6 files; no per-file purpose/lifecycle. |
| `specs/020-session-state-durability/contracts/session-state-schema.yml` | One schema (session state). The other ~30+ files have no schema artifact. |
| Inline script comments | Scattered, per-script context. No central index. |
| `docs/api-reference.md`, `docs/user-guide.md` | User-facing CLI surface; not a file-by-file reference. |

The gap manifests when:

- A downstream user (new or experienced) opens `.specrew/last-start-prompt.md` and asks "what is this?"
- A maintainer needs to know "which files should I commit at feature-closeout vs leave untouched?"
- The F-011 / F-022 stale-state detectors fire and the user needs to know which file is canonical
- An external contributor wants to understand the state model before contributing
- A future automated `specrew doctor` (Tier 3) wants to know what "green" means per file

The Sept 2026 external-adoption window makes this urgent — first-time users encountering 30+ state files without a guide hit a wall.

### User direction (2026-05-21)

> "Do we have a documentation for each Specrew file — i.e. what it is for, when is it used, what is considered a green status, does it have a known schema"

Answer (today): no central reference. This proposal is the answer for tomorrow.

## What (Tier 1 scope per 2026-05-21 user direction)

A single documentation surface: `docs/file-reference.md`. Each Specrew-managed file gets a structured entry. Per-file template:

```markdown
## <relative path> (e.g., .specrew/config.yml)

**Purpose**: One-sentence description of what this file represents.

**Written by**:
- `<script-path>` at `<lifecycle moment>` (e.g., `scripts/specrew-init.ps1` at bootstrap)
- `<script-path>` at `<other moment>` (if multi-writer)

**Read by**:
- `<script-path>` for `<purpose>` (e.g., `scripts/specrew-start.ps1` line 2466 for F-011 baseline)
- ...

**Green status**:
- File present (Y/N)
- Schema field present (`schema: v1`)
- Required fields populated (list)
- Cross-file consistency (e.g., matches `.squad/identity/now.md` session_state_*)

**Schema**:
- Location: `<path to schema artifact>` (or `inline below` if not yet extracted)
- Format: YAML frontmatter / JSON / YAML body / markdown body

**Related**:
- `[[<other file>]]` — composes with / supersedes / mirrors
- `[[<proposal>]]` — proposal that introduced or governs this file

**Lifecycle classification**:
- audit-trail (Squad's decisions, agent history) — preserve, never delete
- ephemeral (caches, summaries) — regenerated on demand; safe to delete
- canonical state (config, role-assignments) — required; loss breaks the project
- artifact (specs/iterations content) — feature-bounded; lifecycle follows the feature
```

Organization: by directory tree, in this order:

1. **Top-level repo files** — `Specrew.psd1`, `Specrew.psm1`, `CHANGELOG.md`, etc.
2. **`.specrew/`** — Specrew project state (~12 files)
3. **`.squad/`** — Squad operating state (~15 files)
4. **`specs/<feature>/`** — feature-bounded artifacts (~10 file shapes)
5. **`specs/<feature>/iterations/<N>/`** — iteration-bounded artifacts (~10 file shapes)
6. **`.specify/`** — Spec Kit's working directory (smaller surface; mostly mirrors)
7. **`.github/agents/`**, **`.github/skills/`**, **`.claude/skills/`**, **`.agents/skills/`** — host-side multi-host slash-command surface
8. **`extensions/specrew-speckit/`** — module-side Spec Kit extension files
9. **`scripts/internal/`** — internal helper scripts and their data files

## How (implementation plan)

| Step | Effort |
|---|---|
| Inventory: walk a fresh Specrew-managed project + the Specrew repo itself; enumerate every file that's NOT just code | 1 SP |
| Categorize by lifecycle classification (audit-trail / ephemeral / canonical / artifact) | 0.5 SP |
| Per-file write-up: ~50-150 words per file × ~30-40 files | 6-8 SP |
| Cross-link from `README.md`, `docs/user-guide.md`, `docs/getting-started.md` | 0.5 SP |
| Add discoverability: link from `specrew-help` skill, `specrew --help` output (one-liner: "See `docs/file-reference.md` for the file lifecycle catalog") | 0.5 SP |
| markdownlint compliance | 0.5 SP |
| Final review: cross-reference each entry against the actual scripts that write/read the file (spot-check 20%) | 1 SP |

Total: ~10-12 SP. Small-fix slice candidate if it lands under 10 SP at final tally; otherwise feature slice.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Tier 2 evolution (future)** | Per-file machine-readable schemas in `docs/schemas/<filename>.schema.yml`. References from this doc point there once written. Could be a follow-up proposal 081 |
| **Tier 3 evolution (future)** | `specrew doctor` (or `specrew validate`) CLI that walks the project and validates against schemas. Composes with Proposal 030 (Quality Hardening Bundle) |
| **Proposal 030 (Quality Hardening Bundle)** | This doc becomes the truth source 030's runtime checks validate against |
| **Proposal 028 (Public Proposals Surface)** | Both are documentation surfaces. 028 is the proposals index; this is the state-file index. Sibling docs |
| **Proposal 077 (Session Resume UX)** | 077 governs the state files; this doc documents them. 077's deeper change-detection logic benefits from 080's clear "what's canonical vs what's ephemeral" classification |
| **`docs/data-contracts.md`** | Schema-versioning conventions extend into per-file context here. 080 should reference data-contracts.md for the v0/v1 schema discipline, not duplicate it |
| **Proposal 047 (Project Governance Profile)** | 047's profile dials affect which files are present; 080 documents the matrix |

## Acceptance signals

- **AC1**: `docs/file-reference.md` exists and enumerates every Specrew-managed file across the project surfaces listed in "What" section
- **AC2**: Each entry has all required template sections (Purpose, Written by, Read by, Green status, Schema, Related, Lifecycle classification)
- **AC3**: Cross-referenced from `README.md`, `docs/user-guide.md`, `docs/getting-started.md`
- **AC4**: Discoverable via `specrew --help` (one-liner pointing at the reference) and via `/specrew-help` skill catalog
- **AC5**: markdownlint clean (no rule disables)
- **AC6**: Spot-check of 20% of entries against actual code paths confirms accuracy (no "written by X" claims that X doesn't actually write)
- **AC7**: At least one external new-comer test: hand the doc to someone unfamiliar with Specrew, confirm they can answer "what is `<random file>` for" within 30 seconds

## Out of scope (deferred to follow-up proposals)

- Per-file machine-readable schemas (`docs/schemas/*.schema.{yml,json}`) — future proposal 081
- Runtime validation harness (`specrew doctor` / `specrew validate`) — future proposal, composes with Proposal 030
- Auto-generation from per-file frontmatter — composable future work; for v1 the doc is hand-maintained
- Per-feature documentation (which lives in `specs/<feature>/spec.md` already; not a Specrew-file-reference concern)
- Spec Kit's own files (governed by Spec Kit's upstream docs)

## Cross-references

- **User direction**: 2026-05-21 conversation, "Do we have a documentation for each Specrew file"
- `docs/data-contracts.md`: file:///C:/Dev/Specrew/docs/data-contracts.md
- `specs/020-session-state-durability/contracts/session-state-schema.yml`: file:///C:/Dev/Specrew/specs/020-session-state-durability/contracts/session-state-schema.yml
- Proposal 030 (Quality Hardening Bundle): file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- Proposal 028 (Public Proposals Surface): file:///C:/Dev/Specrew/proposals/028-public-proposals-surface.md
- Proposal 077 (Session Resume UX): file:///C:/Dev/Specrew/proposals/077-session-resume-ux.md
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
