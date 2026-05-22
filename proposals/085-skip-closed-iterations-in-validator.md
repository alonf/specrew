---
proposal: 085
title: Skip Closed Iterations in Validator (Fallback-Path Optimization via Closed-Iteration Index)
status: shipped
shipped-as: feature-036
shipped-at: 2026-05-22
phase: phase-2
estimated-sp: 5
actual-sp: 5
discussion: tbd
---

# Skip Closed Iterations in Validator (Fallback-Path Optimization via Closed-Iteration Index)

## Why

Specrew's validator (`validate-governance.ps1`) iterates over EVERY iteration directory on full-repo runs. The corpus today is 44+ iterations; ~85% are CLOSED (shipped, immutable, no longer changing). Re-validating them is wasted work.

Proposal 083 (Local Validator Speedup) ships **git-diff auto-scope** for the common path — feature branches automatically validate only the iterations whose files changed. **In that common path, closed iterations are skipped naturally without needing any status check** (their files aren't in the diff).

However, several legitimate paths still trigger full-repo validation:

1. `-IncludeClosed` flag (truth-check)
2. CI push-to-main runs (truth-check semantics)
3. `-FullRun` opt-out flag (debugging, schema migration)
4. No git base ref available (cold-start, missing remote)
5. Global config change forcing full-repo (e.g., `.specrew/iteration-config.yml` edited)

On these paths, the validator walks ALL iterations and re-validates closed ones unnecessarily. This proposal optimizes the **full-repo fallback path** using a closed-iteration index file.

### Rejected approaches

These were considered and rejected:

| Approach | Why rejected |
|---|---|
| **Read `state.md` per iteration to determine status** | Reading N state.md files is itself O(N) overhead. As corpus grows, the status check becomes the new bottleneck. |
| **Modify-time (mtime) heuristic** | Fragile. Git operations (clone, checkout, reset) don't preserve mtimes deterministically. Two clones of same repo have different mtimes. |
| **Threshold-based: scan git-diff first, fall back to status if too many** | Threshold heuristic is brittle (hard to pick a value); adds dispatch complexity. |
| **Time-based pruning (skip iterations older than 90 days)** | Status, not time, is the right discriminator. Old iterations might still be relevant. |

### Empirical motivation

The 2026-05-22 Crew building Proposal 083 burned ~80 minutes on FOUR validator integration test runs, each re-validating the full 44-iteration corpus. Of that, ~50+ minutes was re-validating closed iterations that hadn't changed in months.

### User direction (2026-05-22)

> "I do not understand why do we validate old iterations, I hope that the fix that only looks at git diff files will change this behavior and running validation in parallel will shorten it even more. The problem now is that we add more and more files to validate in each release."

Answer: Proposal 083 handles the common path via git-diff. This proposal handles the remaining full-repo fallback path via a closed-iteration index.

## What (3 Pillars)

### Pillar 1 — Closed-iteration Index File

Maintain `.specrew/closed-iterations.yml` (committed to repo; append-only):

```yaml
# Append-only list. Multi-dev merge resolves via union.
closed:
  - feature: 029
    iteration: 001
    closed_at: 2026-05-21T14:32:00Z
  - feature: 028
    iteration: 001
    closed_at: 2026-05-20T11:15:00Z
  - feature: 027
    iteration: 002
    closed_at: 2026-05-19T16:48:00Z
  # ...
```

**Maintenance**: `Invoke-SpecrewBoundaryStateSync` appends the closed iteration's entry at iteration-closeout boundary. Single append per iteration; no deletes.

**Lookup**: O(1) hashmap from `<feature>/<iteration>` → closed/active. Replaces N `state.md` reads with one index file read.

**Multi-dev merge**: append-only design means concurrent appends from two developers' iteration-closeouts merge trivially via union. Custom git merge driver optional; default conflict-marker resolution is trivial.

**Cold-start / corruption recovery**: `validate-governance.ps1 -RebuildClosedIndex` walks `state.md` files once across the corpus and recreates the index from scratch. Run on any commit where index appears missing or stale.

### Pillar 2 — Index Lookup in Fallback Path

The full-repo fallback path consults the index before validating each iteration:

```powershell
# Pseudo-code (full-repo fallback path)
$closedIndex = Get-SpecrewClosedIterationIndex
foreach ($iteration in $allIterations) {
    if (-not $IncludeClosed -and $closedIndex.IsClosed($iteration)) {
        continue  # skip; iteration is immutable per index
    }
    Test-IterationGovernance -Path $iteration
}
```

On the common path (post-083 git-diff auto-scope), this lookup is never reached because the iteration set is already filtered. **085 contributes nothing on the common path** — it's a no-op there. Only the fallback path benefits.

### Pillar 3 — `-IncludeClosed` Opt-in + CI Truth-Check

Existing `-IncludeClosed` flag (added by this proposal) overrides the skip:

- **Local truth-check**: `validate-governance.ps1 -IncludeClosed` validates all iterations including closed
- **CI push-to-main**: workflow runs `-IncludeClosed` to catch any drift in shipped artifacts
- **Schema migration**: when a new validator rule is added that needs to apply retroactively, `-IncludeClosed` surfaces drift

```yaml
# .github/workflows/<relevant>.yml
- name: Validator full-repo truth check
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  run: pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -IncludeClosed
```

Same pattern as `ci(lint-scoping)`: PR-CI uses scoped/skip-closed for speed; push-to-main runs full truth check.

## How (implementation plan)

This slice ships AFTER Proposal 084 lands (both touch the validator iteration loop; sequencing avoids merge conflict).

| Step | File | Effort |
|---|---|---|
| Add `Get-SpecrewClosedIterationIndex` helper (reads/writes `.specrew/closed-iterations.yml`) | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) | 0.75 SP |
| Modify `Invoke-SpecrewBoundaryStateSync` to append at iteration-closeout boundary | `scripts/internal/sync-boundary-state.ps1` (+ helpers) | 0.5 SP |
| Index lookup in validator full-repo fallback path | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror) | 0.5 SP |
| `-IncludeClosed` switch parameter | same | 0.25 SP |
| `-RebuildClosedIndex` flag + walker | same | 0.5 SP |
| `[validator-scope]` banner extension showing N active + M closed-skipped | same | 0.25 SP |
| CI workflow yaml: push-to-main runs `-IncludeClosed` | `.github/workflows/<relevant>.yml` | 0.25 SP |
| Initial backfill of `closed-iterations.yml` for existing 44 iterations | one-time data migration | 0.25 SP |
| Tests: index lookup; -IncludeClosed opt-in; -RebuildClosedIndex; multi-dev merge | `tests/integration/validator-closed-iteration-index.tests.ps1` (new) | 1 SP |
| Mirror parity sweep | both mirrors | 0.25 SP |
| CHANGELOG entry + INDEX update | docs | 0.25 SP |

Total: **~4-5 SP**. Small-fix slice candidate per Proposal 067.

**Ship target**: v0.24.2 bundle if timeline permits, OR v0.24.3 fast follow-up to v0.24.2 (with 084).

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 083 (Local Validator Speedup)** | 083 handles common path via git-diff; 085 handles only the full-repo fallback path. The two are complementary, not overlapping. When 083 falls back to full-repo, 085 prevents the closed-iteration cost. |
| **Proposal 084 (Validator Iteration Parallelization)** | Orthogonal: 084 parallelizes the validation loop; 085 reduces the loop's input set in fallback. Combined: ~6× parallelization × N× scope-reduction = bounded fallback runtime. |
| **Proposal 086 (Validation Pipeline Performance Bundle)** | 085 is one of the listed slices in 086's framework (Axis C: pruning). 086 covers axes D, E, F (memoization, rule-applicability, process-level). |
| **Proposal 042 (Specrew Integration Test Suite)** | 042's integration suite can use `-IncludeClosed=false` for routine CI runs (matches push-to-main truth-check semantics inverted for PR-CI). |
| **Proposal 030 (Quality Hardening Bundle)** | Could absorb 085 if shipped together later; standalone is cleaner. |

## Acceptance signals

- **AC1**: `.specrew/closed-iterations.yml` populated on iteration-closeout boundary. Verified by integration test running iteration-closeout and inspecting index file.
- **AC2**: Full-repo fallback validator skips closed iterations by default. Verified by running fallback path on multi-iteration repo and observing `[validator-scope]` banner.
- **AC3**: `-IncludeClosed` flag overrides skip. Verified by Pester test.
- **AC4**: `-RebuildClosedIndex` regenerates index correctly. Verified by deleting index, running flag, observing index recreated.
- **AC5**: Multi-dev append-only merge works without manual resolution. Verified by simulating two-developer concurrent closeout scenarios.
- **AC6**: CI push-to-main workflow runs `-IncludeClosed`. Verified by workflow yaml inspection.
- **AC7**: `[validator-scope]` banner shows accurate "N active validated, M closed-skipped" breakdown.
- **AC8**: Cold-start: missing `closed-iterations.yml` triggers `-RebuildClosedIndex` automatically (or emits warning to run manually).
- **AC9**: Empirical perf — full-repo fallback on a 44-iteration corpus with 39 closed + 5 active completes in ~5-iteration time (proportional to active count). Captured in CHANGELOG.
- **AC10**: Mirror parity across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/`.

## Out of scope

- **Cross-iteration validation rules**: rules that check consistency ACROSS iterations (e.g., proposal-to-feature mapping) need to inspect ALL iterations regardless of status. Those rules opt out of the closed-skip path. This proposal scopes only per-iteration validation; cross-iteration rules are unaffected.
- **Cache-based per-content-hash validation**: that's Proposal 086 Pillar 1 (Memoization). 085 is status-based pruning, not content-based caching. They compose.
- **Time-based pruning**: rejected (see Why section).
- **mtime-based pruning**: rejected (see Why section).
- **Modifying closed iterations**: out of scope. If a closed iteration needs editing, the developer must explicitly invoke `-IncludeClosed` AND understand they're editing immutable history.

## Cross-references

- **User direction**: 2026-05-22, "I do not understand why do we validate old iterations..."
- **Refined design discussion**: 2026-05-22 conversation analyzing 4 options (index file, git-diff first, git-diff alone, mtime); refined to "trust 083 on common path + index file on fallback path"
- **Proposal 083** (Local Validator Speedup): file:///C:/Dev/Specrew/proposals/083-local-validator-speedup.md
- **Proposal 084** (Validator Iteration Parallelization): file:///C:/Dev/Specrew/proposals/084-validator-iteration-parallelization.md
- **Proposal 086** (Validation Pipeline Performance Bundle): file:///C:/Dev/Specrew/proposals/086-validation-pipeline-performance-bundle.md
- **Memory `[[project-velocity-tracking-post-v0-24-2-2026-05-22]]`**: empirical baseline
- **Memory `[[project-post-f029-sequencing-2026-05-21]]`**: current canonical queue
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
