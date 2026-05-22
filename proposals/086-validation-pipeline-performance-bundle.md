---
proposal: 086
title: Validation Pipeline Performance Bundle (Memoization, Rule-Applicability, Process-Level Optimization)
status: partially-shipped
pillar-1-shipped-as: feature-034
pillar-1-shipped-in: v0.24.3
pillar-1-actual-sp: 7.0
phase: phase-2
estimated-sp: 18-26
remaining-pillars: 2-5
discussion: tbd
---

# Validation Pipeline Performance Bundle (Memoization, Rule-Applicability, Process-Level Optimization)

## Why

The implementation + validation pipeline is Specrew's most-invoked surface and its slowest. Empirical data from the 2026-05-22 Crew session implementing Proposal 083 (Local Validator Speedup):

- `speckit.implement: Execute Proposal 083 slice` ran **113 minutes total**
- Within that, FOUR validator integration test runs accounted for **~80 minutes**:
  - `Re-run validator integration tests` (23m 37s)
  - `Run final validator integration tests` (25m 2s)
  - `Run final validator integration suite` (23m 32s)
  - `Run regression suite after verbose fix` (9m 27s)
- Three of the four runs were re-runs after small fixes (verbose flag, etc.) — the **same test surface re-executed against barely-changed code**
- Step-naming was inconsistent ("tests" vs "suite" vs "regression suite") indicating UX gap

Proposals 083, 084, 085 already address three axes (scope, concurrency, pruning). This proposal **consolidates the strategy** and adds **five new optimization pillars** addressing the remaining axes — primarily the edit-validate-edit loop that dominated 083's implementation phase.

### Strategic motivation

Per memory `[[project-velocity-tracking-post-v0-24-2-2026-05-22]]`, the September 2026 external-adoption window assumes Specrew velocity is sustainable. The validator runtime growth curve (linear with corpus age) is one of two structural bottlenecks (the other is Crew quota cost). This bundle flattens the validator runtime curve to **essentially constant**.

### User direction (2026-05-22)

> "I want to do next the entire optimization for the implementing/validation process. Skipping unchanged file, using concurrent loops to speedup, and checking if there any other tasks that can be either eliminated (no change) or runs concurrently. So consolidate all of it from the different proposals, and even analyze for more options."

This proposal is that consolidation.

## The Six Axes of Pipeline Speedup

| Axis | What it changes | Existing slice | This proposal |
|---|---|---|---|
| **A. Scope** | Validate fewer iterations per invocation | Proposal 083 (git-diff auto-scope) | — |
| **B. Concurrency** | Validate iterations in parallel | Proposal 084 (`ForEach-Object -Parallel`) | — |
| **C. Pruning** | Skip immutable iterations | Proposal 085 refined (closed-iteration index) | — |
| **D. Memoization** | Reuse validation results when files unchanged | — | **Pillar 1** |
| **E. Rule applicability** | Skip rules that don't apply to a file type | — | **Pillar 2** |
| **F. Process-level** | Optimize non-validator pipeline steps | — | **Pillars 3, 4, 5** |

This proposal owns Axes D, E, and F. Axes A, B, C are owned by 083, 084, 085 respectively.

## What (Five Pillars)

### Pillar 1 — Validator Result Memoization (HIGHEST ROI)

**Problem**: The Crew's edit-validate-edit loop on Proposal 083's implementation re-validated unchanged iterations ~4×. Each iteration's per-rule outcomes are deterministic functions of `(iteration content, validator code, rules definitions)`. Caching avoids redundant work entirely.

**Solution**: Cache file at `.specrew/.cache/validator-cache.json` mapping iteration cache key → result hash + pass/fail + timestamp.

```yaml
# Cache entry shape (conceptual)
"iterations/031/001":
  iteration_content_hash: "sha256:..."     # hash of all files in iteration dir
  validator_code_hash: "sha256:..."        # hash of validate-governance.ps1 + shared-governance.ps1
  rules_hash: "sha256:..."                 # hash of governance rules manifest
  validated_at: "2026-05-22T18:42:11Z"
  result: pass
  rule_results:
    rule-iteration-state-frontmatter: pass
    rule-tasks-checked-off-at-closeout: pass
    # ...
```

**Cache lookup logic**:

```powershell
$cacheKey = Get-IterationCacheKey -Path $iteration
$cached = Get-ValidatorCacheEntry -Key $cacheKey
if ($cached -and $cached.iteration_content_hash -eq $currentContentHash `
            -and $cached.validator_code_hash -eq $currentValidatorHash `
            -and $cached.rules_hash -eq $currentRulesHash) {
    return $cached.result  # ~1 ms vs ~30s full validation
}
Test-IterationGovernance -Path $iteration
Set-ValidatorCacheEntry -Key $cacheKey -Result $result
```

**Invalidation triggers**:

- Any file content change in iteration directory → invalidates that iteration's entry
- Any change to validator code (`validate-governance.ps1`, `shared-governance.ps1`) → wipes entire cache
- Any change to rules definition → wipes entire cache
- Explicit `validate-governance.ps1 -NoCacheRead` flag for forced re-validation

**Cache file mergeability**: JSON object keyed by iteration path; multi-dev conflicts resolve by union with last-validated-wins (the newer timestamp's entry replaces the older). Mergeable via custom git merge driver OR by simple "regenerate on conflict" policy.

**Cache size discipline**: cap at 500 entries; LRU eviction. Cache lives in `.specrew/.cache/` which is gitignored (not committed; per-developer).

**Expected impact**:

- First validator run on iteration N: same as today
- Subsequent runs with unchanged iteration N: ~1 ms (cache hit)
- For the Crew's edit-validate-edit loop on 083: would have cut ~71 min of redundant test work to ~seconds

### Pillar 2 — Per-file Rule Applicability Filter

**Problem**: Today the validator runs ALL rules against ALL files. Markdown-lint rules run on `.ps1` files (skipping internally); PSScriptAnalyzer rules run on `.md` files (skipping internally). The skip is correct but the rule-invocation overhead is wasted.

**Solution**: Each rule declares its file-type applicability in its metadata:

```powershell
@{
    name = 'rule-markdown-frontmatter-required'
    applies_to = @('*.md')           # NEW field
    severity = 'error'
    invoke = { ... }
}
```

The dispatcher pre-filters files by `applies_to` before invoking rules. Rules that don't match the file's extension are never invoked for that file.

**Expected impact**: ~15-30% reduction in rule-invocation overhead. Modest but cumulative across thousands of file-rule pairs per validation pass.

### Pillar 3 — Single-pass Artifact Metadata Cache

**Problem**: `state.md`, `spec.md`, `plan.md`, `tasks.md` are read multiple times within a single validation pass by different rules. Each rule independently calls `Get-Content` + parses frontmatter. For 5-10 rules touching state.md, that's 5-10 file reads + 5-10 parses.

**Solution**: Pre-parse all canonical artifacts ONCE per iteration validation; cache the parsed objects in a hashtable keyed by file path. Rules read from the in-memory cache.

```powershell
# Today (per rule):
$state = Get-Content "$iteration/state.md" | ConvertFrom-SpecrewFrontmatter
# Times N rules = N reads

# This proposal:
$artifactCache = Read-IterationArtifacts -Path $iteration    # one-shot
foreach ($rule in $rules) {
    $rule.Invoke($artifactCache)    # in-memory dictionary lookup
}
```

**Expected impact**: ~10× reduction in file I/O within an iteration's validation. Compounds with Pillar 1 (memoization) since the cache key calculation also benefits from cached parses.

### Pillar 4 — Batched Boundary State Writes

**Problem**: `Invoke-SpecrewBoundaryStateSync` writes multiple state files sequentially with implicit fsync between writes. On boundaries that update 5-7 files (`.specrew/now.md`, `.squad/identity/now.md`, `.specrew/prompts/now.md`, drift-log entries, etc.), the cumulative fsync cost adds up.

**Solution**: Buffer all state-file writes in memory during boundary processing; flush all writes at the end of `Invoke-SpecrewBoundaryStateSync` in a single transaction-style batch. On Windows, group writes to minimize fsync cycles.

**Expected impact**: Modest individually (~50-200ms saved per boundary); cumulative across ~7 boundaries per feature = ~1-2s per feature lifecycle. More importantly: reduces risk of half-written boundary state on interrupt (atomicity property).

### Pillar 5 — Repetition Detector (Diagnostic Pillar)

**Problem**: The 2026-05-22 Crew exhibited 4× redundant test runs of essentially the same target. This was visible to the user but invisible to the Crew. No mechanism exists to flag "you ran the same expensive command N times in a row."

**Solution**: Lightweight runtime detector (not blocker): `Invoke-SpecrewBoundaryStateSync` or a dedicated `.specrew/last-commands.log` tracker records the last 20 invocations of expensive commands (validator, integration tests, pester runs). On any repeated invocation against unchanged code, emit a warning:

```
[specrew-warning] Detected 3rd consecutive invocation of 'pwsh -File validate-governance.ps1' against unchanged code.
                  Consider: results unchanged from 18:42:11; re-running may not surface new findings.
                  To force fresh run: -NoCacheRead
```

**Expected impact**: Methodology hygiene. Catches the edit-validate-edit loop pathology before it consumes 80 minutes. Composes with Proposal 078 (Handoff Conversation Quality) — the warning text becomes part of the Crew's "what I just did / why I stopped" preamble.

## How (implementation plan)

This bundle ships AFTER 083, 084, 085 land. Each pillar can be a separate PR or bundled:

| Pillar | File(s) | Effort | Bundle suggestion |
|---|---|---|---|
| 1 Memoization | `extensions/specrew-speckit/scripts/validate-governance.ps1` + `shared-governance.ps1` + new `validator-cache.ps1` helper module | 6-8 SP | Standalone PR (largest single win) |
| 2 Rule applicability | rule definitions + dispatcher | 3-4 SP | Combine with Pillar 3 |
| 3 Metadata cache | `validate-governance.ps1` + `shared-governance.ps1` | 3-4 SP | Combine with Pillar 2 |
| 4 Batched state writes | `Invoke-SpecrewBoundaryStateSync` callers | 2-3 SP | Standalone or combine with Pillar 5 |
| 5 Repetition detector | new `command-repetition-detector.ps1` + integration into validator entry point | 3-4 SP | Standalone or combine with Pillar 4 |
| Tests | `tests/integration/validator-cache.tests.ps1` + others | 4-5 SP | Per pillar |
| Mirror parity + CHANGELOG + INDEX | docs + sync | 1 SP | Per pillar |

**Total**: ~18-26 SP. Two-PR bundle suggested: `(Pillar 1)` + `(Pillars 2 + 3 + 4 + 5)`.

**Ship target**: v0.24.3 fast follow-up to v0.24.2 OR roll into v0.24.2 bundle if timeline permits.

### Recommended sequencing

| Sequence | Slice | Status |
|---|---|---|
| 1 | **083** Local Validator Speedup | Crew, in flight |
| 2 | **084** Validator Iteration Parallelization | Queued (Claude-authored post-083 merge) |
| 3 | **085 refined** Closed-iteration Index | Queued (Claude-authored post-084) |
| 4 | **086 Pillar 1** Memoization | Highest ROI; ships next |
| 5 | **086 Pillar 3** Metadata cache | Independent; can parallel-author |
| 6 | **086 Pillars 2 + 4 + 5** | Smaller wins; bundle into one PR |

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 083** (Local Validator Speedup) | Axis A (scope). Predecessor; foundation. |
| **Proposal 084** (Validator Iteration Parallelization) | Axis B (concurrency). Predecessor; compounds. |
| **Proposal 085 refined** (Closed-iteration Index) | Axis C (pruning). Predecessor; compounds. |
| **Proposal 042** (Specrew Integration Test Suite) | Already absorbs Contract lane parallelization. Sibling work for non-validator test surfaces. |
| **Proposal 078** (Handoff Conversation Quality) | Pillar 5 (repetition detector) composes with 078's preamble format. |
| **Proposal 030** (Quality Hardening Bundle) | Could fold the smaller pillars (4, 5) if shipped together later. |
| **Proposal 040/070** (Token Economy) | Memoization saves both wall-clock AND token cost — Crew doesn't re-invoke validator skill against unchanged code. Direct cost reduction. |
| **Proposal 045** (CI Watchdog & Recurrence Prevention) | Pillar 5 (repetition detector) is local-side complement to 045's CI-side detector. |

## Acceptance signals

- **AC1**: Validator on unchanged iteration N completes in <100 ms on second invocation (cache hit). Verified by Pester test that runs validator twice and times the second run.
- **AC2**: Any file content change in iteration N invalidates only that iteration's cache entry. Verified by editing one file, observing only N's entry rewritten.
- **AC3**: Change to `validate-governance.ps1` content wipes entire cache. Verified by modifying validator, observing cache file truncated.
- **AC4**: `-NoCacheRead` flag forces fresh validation. Verified by Pester test.
- **AC5**: `.specrew/.cache/` directory is gitignored. Verified by `.gitignore` content.
- **AC6**: Rule-applicability filter: a markdown-only rule never invokes against `.ps1` files. Verified by trace test counting rule invocations per file extension.
- **AC7**: Metadata cache: each canonical artifact (`state.md`, `spec.md`, etc.) read once per iteration validation. Verified by file-system trace test.
- **AC8**: Batched state writes: a feature-closeout boundary that updates 5+ state files completes its writes in a single batch. Verified by file-system trace counting fsync calls.
- **AC9**: Repetition detector emits warning on 3rd consecutive validator invocation against unchanged code. Verified by integration test.
- **AC10**: Empirical perf — edit-validate-edit loop on a single iteration's typo fix completes in ~10s for the validator portion (vs ~30+ minutes today). Captured in CHANGELOG with before/after numbers.
- **AC11**: Mirror parity across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/`.

## Out of scope

- **Cross-repo validator caching** (sharing cache between developers via committed cache files): out of scope; per-developer cache is simpler and avoids merge complexity.
- **Distributed/parallel validator across multiple machines**: out of scope (sibling work in Proposal 042 Contract lane parallelization).
- **Per-rule parallelization within an iteration**: out of scope; per-iteration parallelization (Proposal 084) is sufficient for now.
- **Cache replication to CI**: CI runs always run with `-NoCacheRead` for truth-check semantics; CI doesn't benefit directly from local cache.
- **Specrew SDK / web service for centralized rule execution**: way out of scope; far-future Phase 4+ work.

## Cross-references

- **User direction**: 2026-05-22 conversation requesting consolidated optimization plan
- **Empirical evidence**: 2026-05-22 Crew session on Proposal 083 — 113 min total, ~80 min in 4× redundant validator integration test runs
- **Proposal 083** (Local Validator Speedup): file:///C:/Dev/Specrew/proposals/083-local-validator-speedup.md
- **Proposal 084** (Validator Iteration Parallelization): file:///C:/Dev/Specrew/proposals/084-validator-iteration-parallelization.md
- **Proposal 085 refined** (Closed-iteration Index): file:///C:/Dev/Specrew/proposals/085-skip-closed-iterations-in-validator.md
- **Memory `[[project-velocity-tracking-post-v0-24-2-2026-05-22]]`**: empirical baseline that 086 will improve dramatically
- **Memory `[[project-post-f029-sequencing-2026-05-21]]`**: current canonical queue; 086 slots post-085
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
