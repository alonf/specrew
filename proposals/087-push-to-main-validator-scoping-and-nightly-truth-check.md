---
proposal: 087
title: Push-to-Main Validator Scoping + Nightly Truth-Check (Stop O(corpus) Cost on Every Push)
status: candidate
phase: phase-2
estimated-sp: 3
discussion: tbd
---

# Push-to-Main Validator Scoping + Nightly Truth-Check (Stop O(corpus) Cost on Every Push)

## Why

The PR-CI `validate-governance.ps1` invocation is scoped to changed files via `-ChangedOnly` (per the `ci(lint-scoping)` chore). The push-to-main invocation, however, runs **full-repo** with no scoping flag — meaning every push to main re-validates every iteration in `specs/<feature>/iterations/<NNN>/`. The current workflow even has a `timeout-minutes: 25` budget on this step, which is itself the smoking gun that the original author anticipated this would scale up.

### The cost-growth curve

| Corpus size | Push-to-main validator wall-clock |
|---|---|
| 44 iterations (today) | ~3-5 min |
| ~100 iterations (~6 months at current cadence) | ~8-15 min |
| ~200 iterations (~1 year) | ~15-30 min (hits the 25-min timeout budget) |
| ~300+ iterations | exceeds budget; push-to-main CI breaks |

Every push to main pays this cost — whether the push is a 1-file typo fix in a proposal, a 1-iteration small-fix slice, or a multi-iteration feature merge. The validator doesn't care.

### Why the "truth-check" defense doesn't hold

The historical defense for full-repo on push-to-main is "truth-check semantics — catches drift in closed iterations." On inspection this is mostly hypothetical:

- **Closed iterations are immutable** — their files don't change between pushes. Re-validating them on every push catches nothing 99%+ of the time.
- **Schema migration IS the legitimate truth-check use case** — but schema migration is a deliberate event (a new validator rule, a new required artifact). It's not a routine push.
- **Routine push events** (proposal commits, doc fixes, lint chores, small-fix slices) touch zero closed iterations. The truth-check cost on these is pure waste.
- **Linear cost growth is the real cost.** It compounds across every push, every day, forever.

A better design preserves truth-check semantics while moving the cost off the routine-push critical path: scope every push to its actual diff, and run the full-repo truth-check on a scheduled cadence (nightly) where wall-clock doesn't matter.

### Empirical motivation (2026-05-22)

On 2026-05-22 the v0.24.2 bundle work surfaced this issue empirically:

1. The maintainer noticed push-to-main `Specrew CI` jobs were completing suspiciously fast (~16-20s) and asked "are we testing anything?" — the answer was no, because push-to-main Lint was failing on accumulated markdownlint violations and the failure cascaded to SKIP the Deterministic gate + Contract lane (see commit `2c2ef23` for the cascade fix).
2. Once Lint was repaired, the validator step ran full-repo as designed — and the maintainer correctly asked "are you sure that going over very old iterations and checking each file is what we want? It will expand to hours."

This proposal is the answer: no, that is not what we want. The push step must scope, and the truth-check must move to a cadence-driven workflow.

### User direction (2026-05-22)

> "We spent today and in the last week hours of revalidating. I also think that running them concurrently will speed up the nightly test."

This proposal addresses the scoping half (immediate). Concurrent execution inside the validator ships in [Proposal 084 (Validator Iteration Parallelization)](084-validator-iteration-parallelization.md); when 084 lands, every validator invocation — PR-CI, push-to-main, local, AND this proposal's nightly truth-check — gets the parallelization for free, without any workflow change.

## What (3 Pillars)

### Pillar 1 — Push-to-main validator scoping

Change `.github/workflows/specrew-ci.yml` so the push-to-main step invokes the validator with `-ChangedOnly` and sets `GITHUB_BASE_REF` to the parent commit SHA via `github.event.before`:

```yaml
- name: Validate iteration governance (push)
  if: github.event_name != 'pull_request'
  timeout-minutes: 25
  shell: pwsh
  env:
    GITHUB_BASE_REF: ${{ github.event.before }}
  run: ./extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -ChangedOnly
```

This works because Proposal 083 introduces SHA-aware base-ref resolution in `Resolve-SpecrewGitBaseRefCandidate` (its regex matches `^[0-9a-fA-F]{7,40}$`). Until 083 merges, the pre-083 validator falls back to full-repo when it can't resolve the SHA — same behavior as today, no regression. Once 083 merges, scoping activates automatically without further workflow edits.

For force-pushes or initial pushes where `github.event.before` is `0000000000000000000000000000000000000000` (the all-zeros sentinel), the validator's fallback path engages and the push validates full-repo — that's correct behavior for those edge cases.

### Pillar 2 — Nightly full-repo truth-check (new workflow)

New file `.github/workflows/specrew-nightly-truth-check.yml`:

```yaml
name: Specrew Nightly Truth-Check
on:
  schedule:
    - cron: '0 6 * * *'   # daily at 06:00 UTC
  workflow_dispatch:       # allow manual trigger for schema-migration events

jobs:
  full-repo-validator:
    name: Full-repo governance validation
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Validate full repo
        shell: pwsh
        run: ./extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

Why daily at 06:00 UTC: catches any drift within ~24 hours of it landing, doesn't conflict with peak maintainer activity hours (which on US/Europe schedules tend to be 14:00-22:00 UTC), and is consistent with industry-standard nightly-build cadence.

Why `workflow_dispatch`: lets the maintainer manually trigger the full-repo truth-check on demand — useful when shipping a schema-migration commit that adds a new validator rule, or for ad-hoc audits.

When [Proposal 085 (refined)](085-skip-closed-iterations-in-validator.md) ships, this workflow will gain `-IncludeClosed` so the nightly genuinely covers the full corpus including iterations that the routine paths skip. Until 085 ships, the nightly is functionally identical to today's push-to-main behavior — just running on a schedule instead of on every push.

### Pillar 3 — Composable with future proposals

This proposal's workflow changes are designed to compose forward without rework:

- **Proposal 083 (Local Validator Auto-Scope)**: Activates the SHA-aware base-ref resolution that makes Pillar 1's scoping functional. Until 083 lands, Pillar 1 is a no-op (falls back to full-repo); after 083 lands, Pillar 1 activates automatically.
- **Proposal 084 (Validator Iteration Parallelization)**: Parallelizes the validator's iteration loop. When 084 lands, EVERY validator invocation gets faster — including this proposal's nightly truth-check — with no workflow edit required.
- **Proposal 085 refined (Closed-Iteration Index)**: Adds `-IncludeClosed` flag. When 085 lands, this proposal's nightly workflow gains `-IncludeClosed` for genuine full-corpus truth-check (and the routine paths gain the closed-iteration skip via the index file).
- **Proposal 086 (Validation Pipeline Performance Bundle)**: Memoization, rule-applicability filter, metadata cache. All apply uniformly across PR-CI, push-to-main, local, and the new nightly path.

The compounding effect across 083 + 084 + 085 + 086 reduces the nightly truth-check from today's ~3-5 min (44 iterations) to ~30-60 seconds even at 200+ iterations.

## How (implementation plan)

This is a small-fix slice per [Proposal 067](067-small-fix-slice-type.md). Required artifacts: code + tests + CHANGELOG + this proposal + INDEX.

| Step | File | Effort |
|---|---|---|
| Edit push-to-main step (add env: GITHUB_BASE_REF + -ChangedOnly) | `.github/workflows/specrew-ci.yml` | 0.5 SP |
| Create new nightly truth-check workflow | `.github/workflows/specrew-nightly-truth-check.yml` (new) | 1 SP |
| CHANGELOG entry under `Changed` | `CHANGELOG.md` | 0.25 SP |
| INDEX update (this proposal entry) | `proposals/INDEX.md` | 0.25 SP |
| Markdownlint check before commit (per [[feedback-lint-proposals-locally]]) | n/a | 0.25 SP |
| Verify CI behavior post-push: push to main, observe validator step, expect full-repo fallback until 083 merges then scoped after | observation only | 0.5 SP |
| Document the 083-merge activation in commit message | commit message | 0.25 SP |

**Total: ~3 SP.** Small-fix slice. No code-behavior tests required (this is workflow YAML; behavior is binary — works or fails — verified by CI observation post-merge).

**Ship target**: v0.24.2 bundle (insert between 083's merge and 081 Pillar 6).

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| [Proposal 083](083-local-validator-speedup.md) (Local Validator Auto-Scope) | **Hard prerequisite** for Pillar 1's scoping to activate. Until 083 merges, the new push-to-main workflow falls back to full-repo (same as today). After 083 merges, scoping activates automatically. |
| [Proposal 084](084-validator-iteration-parallelization.md) (Validator Iteration Parallelization) | Composes uniformly. When 084 lands, EVERY validator invocation (PR-CI, push-to-main, local, this nightly) gets parallel execution. The nightly truth-check goes from serial-over-200-iterations to parallel-over-200-iterations. |
| [Proposal 085 refined](085-skip-closed-iterations-in-validator.md) (Closed-Iteration Index) | The nightly workflow will gain `-IncludeClosed` once 085 ships; routine paths gain the index-based skip. |
| [Proposal 086](086-validation-pipeline-performance-bundle.md) (Validation Pipeline Performance Bundle) | All five 086 pillars (memoization, rule-applicability, metadata cache, batched state writes, repetition detector) apply uniformly. |
| `ci(lint-scoping)` chore | Predecessor for PR-CI scoping. This proposal extends the same scoping model to push-to-main + adds the nightly truth-check as the safety net. |
| [Proposal 045](045-ci-watchdog-recurrence-prevention.md) (CI Watchdog & Recurrence Prevention) | Adjacent — 045 watches for silent CI failures; this proposal prevents one specific class of CI burn. |

## Acceptance signals

- **AC1**: `.github/workflows/specrew-ci.yml` push-to-main step uses `-ChangedOnly` with `GITHUB_BASE_REF: ${{ github.event.before }}`. Verified by file inspection + first push observing the new step.
- **AC2**: After Proposal 083 merges to main, push-to-main validator wall-clock drops from ~3-5 min to under 1 min for typical pushes (verified by observing CI step duration on a routine push post-083-merge).
- **AC3**: `.github/workflows/specrew-nightly-truth-check.yml` exists and is scheduled at `0 6 * * *` UTC. Manual `workflow_dispatch` trigger is supported. Verified by workflow listing in GitHub Actions UI.
- **AC4**: First scheduled nightly run completes successfully (no flag errors, runs full-repo validator, exit 0 if corpus is clean).
- **AC5**: Force-push or initial-push edge cases (zero-SHA `github.event.before`) gracefully fall back to full-repo. Verified by validator code path — the `Resolve-SpecrewGitBaseRefCandidate` returns null when SHA can't be resolved, triggering the fallback.
- **AC6**: No regression to PR-CI scoping behavior (still uses `-ChangedOnly` against PR target branch).

## Out of scope

- **Concurrent execution inside the validator**: that's Proposal 084. This proposal is workflow-only.
- **`-IncludeClosed` flag**: that's Proposal 085. This proposal can't use it because it doesn't exist yet.
- **Closed-iteration index file**: that's Proposal 085. Until 085 ships, nightly truth-check redundantly re-validates closed iterations — same as today's push-to-main does on every push.
- **Replacing the timeout-minutes: 25 budget**: leave the budget in place as a sanity check. Once 084 + 085 land, the typical run will be well under 1 min and the budget becomes a non-binding ceiling.
- **Auto-issue-opening on nightly failure**: out of scope for this slice. If a nightly fails, it shows in the Actions tab. Future enhancement could auto-open a GitHub issue (composable with [Proposal 045 (CI Watchdog)](045-ci-watchdog-recurrence-prevention.md)).
- **GitHub Actions matrix splitting** to parallelize the nightly across multiple jobs: deferred. Path B (Proposal 084 internal parallelization) provides the same wall-clock benefit without workflow complexity. If 084 slips badly, this is a reasonable backup; otherwise skip.

## Cross-references

- **User direction**: 2026-05-22 conversation: "Are you sure that it is what we want, to go over very old iterations and check each file? It will expand to hours."
- **Maintainer reaffirmation**: "I want you to draft it, and to implement it, ASAP. We spent today and in the last week hours of revalidating."
- **Commit `2c2ef23`** (2026-05-22): The cascading-skip catch-up fix that surfaced this discussion.
- **Memory `[[feedback-lint-proposals-locally-2026-05-22]]`**: companion lesson from the same investigation.
- **Memory `[[project-validation-pipeline-optimization-framework-2026-05-22]]`**: this slice is one tile of the 6-axis optimization framework.
- [Proposal 083](083-local-validator-speedup.md): file:///C:/Dev/Specrew/proposals/083-local-validator-speedup.md
- [Proposal 084](084-validator-iteration-parallelization.md): file:///C:/Dev/Specrew/proposals/084-validator-iteration-parallelization.md
- [Proposal 085 refined](085-skip-closed-iterations-in-validator.md): file:///C:/Dev/Specrew/proposals/085-skip-closed-iterations-in-validator.md
- [Proposal 086](086-validation-pipeline-performance-bundle.md): file:///C:/Dev/Specrew/proposals/086-validation-pipeline-performance-bundle.md
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
