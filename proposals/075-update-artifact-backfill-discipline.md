---
proposal: 075
title: Specrew Update Artifact Backfill Discipline
status: draft
priority: high
phase: phase-2
estimated-sp: 10-15
discussion: promoted candidate → draft + priority:high on 2026-05-25 — empirical motivation expanded by F-044 closeout dashboard-backfill cleanup (10 closed iterations missing `dashboard.md` because their closeouts were orchestrated by a non-Specrew session that bypassed the `sync-boundary-state.ps1` auto-render trigger). Pattern recurs for any project where non-Specrew sessions produce Specrew-shaped artifacts (multi-host expansion makes this universal). User direction "do we need a process that auto-fixes it" answered: Yes — Proposal 075 IS that process; promote and ship.
---

# Specrew Update Artifact Backfill Discipline

## Why

Specrew evolves: new validators ship (F-013, F-028, future Proposal 030), new artifacts get generated (`review-diagrams.md`, `code-map.md`, `dependency-report.md`, `closeout-dashboard.md`, future `cost.yml` from Proposal 070), new conventions land (F-029 Code Commentary Standards). Each shipment improves NEW iterations created post-upgrade — but **existing iterations from prior Specrew versions don't automatically gain these benefits**.

Today's behavior is intentional and correct as a default:

- `specrew update` updates the module, extensions, and templates so NEW iterations use the latest conventions
- `specrew update` does NOT modify existing iteration artifacts — preserves the audit trail of "what was the methodology in force when this iteration shipped"
- Proposal 059 (Legacy-State Read-Tolerance) ensures validators don't fail on old iterations that lack newer artifact types — the "tolerance floor"

But the gap is real: a maintainer who upgrades Specrew from v0.24 → v0.30 (when proposals 028/030/074 have all shipped) gets:

- New iterations: full benefit of new validators, diagrams, commentary standards
- Existing 50+ iterations: lack the new artifacts entirely. No `review-diagrams.md` for iterations created before F-026, no form-vs-meaning verdicts on iterations created before F-028, no commentary-coverage data on iterations created before F-029

The only manual recourse today is per-iteration: invoke `scaffold-reviewer-artifacts.ps1 -Force` (shipping in F-028) on each iteration to refresh review evidence. For a project with 50+ iterations, that's tedious and error-prone, with no record of which iterations were refreshed when or by whom.

### User question (2026-05-21 chat session)

> "When we update Specrew, will it go back and update the missing diagrams/documents?"

The honest answer is "no, not automatically — and that's deliberate, but there's no good batch refresh mechanism either." This proposal fills that gap with an opt-in backfill discipline that preserves the audit trail while letting maintainers selectively refresh existing iterations.

## What (4 Pillars)

### Pillar 1: Backfill policy taxonomy

Not every iteration artifact is safe to regenerate. The taxonomy must be explicit so the backfill command knows what to touch, what to leave alone, and what requires explicit opt-in.

| Artifact category | Safety | Reason |
|---|---|---|
| `review-diagrams.md`, `code-map.md`, `dependency-report.md`, `reviewer-index.md` | **Safe to regenerate** | Pure functions of current code state + iteration metadata. Re-deriving produces the same result every time |
| `closeout-dashboard.md` (velocity snapshot) | **Safe to regenerate IF historical-snapshot semantics preserved** | The dashboard captures a moment in time. Re-running produces a different snapshot. Backfill must respect the "Historical Notice" field and either skip these OR record that they've been re-snapshotted |
| `coverage-evidence.md` | **Unsafe to regenerate without care** | Depends on what tests existed at iteration close. Re-running tests against current code yields different coverage |
| `review.md`, `retro.md`, `closeout.md` | **NEVER regenerate** | Authored content with human verdicts, reflections, decisions. Backfill skips these entirely |
| `state.md`, `plan.md`, `tasks.md`, `spec.md` | **NEVER regenerate** | Declared iteration metadata; the audit trail itself |

The taxonomy ships as a YAML config at `extensions/specrew-speckit/data/backfill-policy.yml` so it's editable per-project if a downstream maintainer has special-case needs.

### Pillar 2: `specrew refresh-iteration <iter-path>` command

Single-iteration backfill. Composes with Proposal 033 (Specrew Governance CLI) as a subcommand under the `specrew` CLI surface.

Behavior:

- Default mode: **report-only**. Shows what would change. No file writes
- `--write` flag: actually performs the regeneration via the F-028 `-Force` mechanism on each safe-to-regenerate artifact
- `--policy <path>` override: use a custom backfill policy YAML for this run
- Records the operation in `.specrew/refresh-log.yml` (per Pillar 4) when `--write` is used
- Honors the policy taxonomy from Pillar 1 — refuses to touch never-regenerate artifacts

Example invocation:

```text
specrew refresh-iteration specs/021-specrew-slash-commands/iterations/001
# Report-only by default; prints planned changes:
#   - WOULD regenerate: review-diagrams.md, code-map.md, dependency-report.md
#   - WOULD SKIP: review.md, retro.md, closeout.md (authored content)
#   - WOULD SKIP: coverage-evidence.md (unsafe without retest)

specrew refresh-iteration specs/021-specrew-slash-commands/iterations/001 --write
# Performs the regeneration and logs the operation
```

### Pillar 3: `specrew refresh-all` batch command

Repo-wide opt-in backfill. Same semantics as Pillar 2 but iterates over every closed iteration.

Behavior:

- Default mode: **report-only**. Prints planned changes across all iterations. No file writes
- `--write` flag: performs regeneration across the entire iteration set
- `--filter <pattern>` flag: limit to iterations matching a glob (e.g., `--filter 'specs/02*'` to refresh feature-020 onward)
- `--since-version <version>` flag: limit to iterations created before that Specrew version (so you only refresh what would benefit from the upgrade)
- All operations recorded individually in `.specrew/refresh-log.yml`

Performance: should batch-execute reasonably across 50-100 iterations. The current `scaffold-reviewer-artifacts.ps1` runs in <30s per iteration; the batch tool should complete a 50-iteration refresh in a few minutes wall-clock.

### Pillar 4: Audit trail — `.specrew/refresh-log.yml`

Every `--write` operation appends a record:

```yaml
refreshes:
  - timestamp: 2026-06-15T14:23:11Z
    invoked_by: specrew refresh-iteration --write
    iteration: specs/021-specrew-slash-commands/iterations/001
    specrew_version: 0.31.0
    triggering_event: post-upgrade-backfill
    artifacts_regenerated:
      - review-diagrams.md
      - code-map.md
      - dependency-report.md
    artifacts_skipped_per_policy:
      - review.md (authored)
      - retro.md (authored)
      - coverage-evidence.md (unsafe-without-retest)
    artifacts_skipped_no_change:
      - reviewer-index.md (output identical to existing)
    operator: alon@local
```

The audit log preserves the post-hoc nature of the operation. Anyone inspecting an iteration later can verify which artifacts were original-from-iteration-time vs refreshed-post-hoc and when. This is itself a form-vs-meaning guarantee: the artifact's recency is declared explicitly rather than assumed.

The log file is committed; it's part of the project's methodology history.

## How (one-iteration plan)

This proposal can ship as a single iteration once its dependencies are met (F-028 ships AND Proposal 033 enters the lifecycle, or has a known shape). Pre-conditions:

- F-028 ships `-Force` mechanism on `scaffold-reviewer-artifacts.ps1` (in progress; expected within days)
- Proposal 033 (Specrew Governance CLI) has a sketched CLI surface so this slice can register subcommands cleanly. If 033 hasn't shipped yet, the `refresh-iteration`/`refresh-all` commands can ship as standalone scripts (e.g., `scripts/refresh-iteration.ps1`) with the intention to fold into `specrew` later. Squad's spec-steward decides at clarify-time which path to take

Implementation:

- Feature branch from main (`029-update-artifact-backfill` or matching feature-number)
- Squad drives the full lifecycle
- New files:
  - `extensions/specrew-speckit/data/backfill-policy.yml` — policy taxonomy
  - `extensions/specrew-speckit/scripts/refresh-iteration.ps1` (or fold into the governance CLI per Proposal 033)
  - `extensions/specrew-speckit/scripts/refresh-all.ps1` (same caveat)
  - `tests/integration/refresh-iteration.tests.ps1` — covers report-only, --write, policy skips, audit log writes
- Modified files:
  - `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` — minor: surface a structured "what would change" report so refresh-iteration can render its report-only output
  - `CHANGELOG.md` — `## Unreleased` → `### Added`
  - `docs/user-guide.md` — explain when to invoke `specrew refresh-*` and the audit trail
- INDEX update at feature closeout (candidate → shipped)

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **F-028 (in progress)** | **HARD PREREQUISITE.** This proposal orchestrates the `-Force` mechanism shipping in F-028. Cannot implement without F-028's idempotent scaffolders |
| **033 (Specrew Governance CLI, draft)** | The natural home for `specrew refresh-*` subcommands. Soft prerequisite — if 033 hasn't shipped, this proposal's commands ship as standalone scripts to be absorbed into 033 later |
| **059 (Legacy-State Read-Tolerance, candidate)** | The "tolerance floor" — validators don't fail on iterations lacking newer artifacts. This proposal is the "active layer" — opt-in regeneration of those missing artifacts. Complementary |
| **061 (Init/Update Convergence Test, candidate)** | 061 tests `specrew init` == `specrew update` for TEMPLATES. This proposal addresses ITERATION ARTIFACTS (a different scope). Both are needed for full update discipline |
| **010 (Multi-Developer Reconciliation, draft)** | Multi-developer scenarios amplify the need: one dev upgrades Specrew; other devs' in-flight iterations need a consistent view. Refresh commands give them an opt-in way to align |
| **030 (Quality Hardening Bundle, draft)** | When 030 ships richer form-vs-meaning rules and new validator outputs, existing iterations need a way to backfill those too. This proposal's mechanism applies generically |
| **F-029 (Proposal 074, queued)** | Code Commentary Standards establishes new conventions for NEW code. This proposal does NOT retroactively add comments — that's a separate optional human effort |

## Acceptance signals

- **AC1**: `specrew refresh-iteration <path>` (or the standalone script equivalent) in default report-only mode prints a clear "would-change" report listing safe-to-regenerate artifacts, never-regenerate skips, and unsafe-without-care skips. No file writes
- **AC2**: `specrew refresh-iteration <path> --write` regenerates only the safe-to-regenerate artifacts per policy, leaves all others untouched, and appends a record to `.specrew/refresh-log.yml`
- **AC3**: `specrew refresh-all` and `specrew refresh-all --write` behave identically to AC1/AC2 but across the entire iteration set, with `--filter` and `--since-version` flags working as documented
- **AC4**: The backfill policy YAML at `extensions/specrew-speckit/data/backfill-policy.yml` is honored — moving an artifact between categories (e.g., adding a new artifact type) changes refresh behavior accordingly
- **AC5**: `refresh-log.yml` records all `--write` operations with timestamp, operator, triggering event, artifacts regenerated, and artifacts skipped per policy
- **AC6**: Running `refresh-iteration` against an iteration that was created under the current Specrew version produces "no changes" (idempotency floor) — refreshing already-fresh artifacts is a no-op
- **AC7**: Refreshing the 2026-05-21 smoke snake-game iteration (which had empty `review-diagrams.md` due to uncommitted implementation) produces non-empty diagrams matching the iteration's actual code footprint, AFTER the implementation has been committed at feature-closeout
- **AC8**: The integration test suite covers all categories: safe-regenerate iterations, never-regenerate skips, unsafe-with-care skips, audit-log correctness, and the --filter / --since-version flags

## Out of scope

- Retroactively adding code comments per F-029 Code Commentary Standards — that's a separate optional human-curated effort, not algorithmic backfill
- Regenerating coverage evidence by re-running tests — too tangled with code state at iteration time; the safe option is to skip these per policy
- Auto-running `specrew refresh-*` as part of `specrew update` — explicitly NOT done. The maintainer must opt in. Auto-backfill would destroy the audit-trail invariant
- Adding new artifact types to existing iterations (e.g., adding a `cost.yml` to iterations created before F-070) — out of scope; new artifact types only apply to iterations created after they ship
- Multi-developer reconciliation of refresh operations (e.g., two devs both refresh the same iteration) — Proposal 010 territory; this proposal assumes single-developer use

## Cross-references

- **User question motivation**: 2026-05-21 chat session, "When we update Specrew, will it go back and update the missing diagrams/documents?"
- **F-028 prerequisite**: file:///C:/Dev/Specrew/proposals/073-review-evidence-integrity.md
- **Proposal 033 (Governance CLI, draft)**: file:///C:/Dev/Specrew/proposals/033-specrew-governance-cli.md
- **Proposal 059 (Legacy-State Read-Tolerance, candidate)**: file:///C:/Dev/Specrew/proposals/059-legacy-state-read-tolerance.md
- **Proposal 061 (Init/Update Convergence Test, candidate)**: file:///C:/Dev/Specrew/proposals/061-init-update-convergence-test.md
- **Proposal 010 (Multi-Developer Reconciliation, draft)**: file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md
- **Proposal 030 (Quality Hardening Bundle, draft)**: file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- **Proposal 074 (Code Commentary Standards, draft)**: file:///C:/Dev/Specrew/proposals/074-code-commentary-standards.md
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
