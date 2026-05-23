---
proposal: 088
title: Markdown Lint Pre-Boundary Auto-Fix Discipline (Boundary-State-Sync Integration)
status: shipped
shipped-as: feature-033 (initial) + fix-bundle a45232af (brownfield gap closure, 2026-05-23)
shipped-in: v0.24.3 + v0.26.0
phase: phase-2
estimated-sp: 5-8
actual-sp: 5.25 (initial) + 0.5 (brownfield gap closure)
discussion: tbd
---

# Markdown Lint Pre-Boundary Auto-Fix Discipline (Boundary-State-Sync Integration)

## 2026-05-23 — Brownfield gap closure (commit `a45232af`)

F-040 calc-v2 dogfooding surfaced a real gap in the original F-033 implementation:
`Get-ChangedMarkdownFiles` used `git diff $baseRef...HEAD -- '*.md'` and went no-op
when the base ref couldn't resolve OR when HEAD didn't exist. Both conditions trigger
simultaneously on greenfield-new projects (no remote, no commits), so the gate was a
permanent no-op for the entire pre-first-commit scaffolding phase — the exact phase
where the model writes the most markdown.

The fix added a working-tree fallback (`git ls-files -m -o --exclude-standard -- '*.md'`)
that fires when (a) base-ref or HEAD is unavailable OR (b) the diff path returned empty
but uncommitted edits may exist. The original committed-diff path is preserved for
normal feature-branch iterations.

The same root-cause pattern was found in `Get-ReviewerCloseoutDiffArtifacts`
(see `proposals/INDEX.md` reference to the reviewer-artifact gate) and fixed in commit
`162bcdb9` with the same working-tree-union pattern.

## Why

Markdown lint violations are catching the Crew (and Claude when authoring directly) at PR-CI time after every authoring session. The catch-fix-retry cycle costs:

- ~10-15 min wall-clock per cycle (CI run + fix + push + CI rerun)
- 1-2 CI runs per feature
- Crew quota when the Crew has to fix and re-validate
- Cognitive disruption that breaks flow

Empirical instances in the 2026-05-22 session alone:

| Cycle | Violations | Cost |
|---|---|---|
| PR #424 (Proposal 082 Tier 1, Claude-authored) | 15× MD032 in spec artifacts | ~10 min + fix + CI rerun |
| Commit `2c2ef23` (proposals 078/081/086, Claude-authored direct-to-main) | 10× MD027 + MD032 | ~5 min + push (silently broke main CI for ~12h before discovery) |
| PR #462 (Feature 030 / Proposal 083, Crew-authored) | 22× MD047 + MD009 + MD032 across spec artifacts | ~15 min + fix + CI rerun |

**~30 minutes wall-clock in ONE day**, all entirely preventable by mechanical lint-before-commit discipline. The pattern is asymmetric: Claude-authored content fails because Claude doesn't run markdownlint pre-commit by default; Crew-authored content fails because no boundary gate runs markdownlint either. Both surfaces need a fix.

### Key insight: ~95% of violations are auto-fixable

Inspection of the violations across all three cycles:

| Rule | Auto-fixable by `markdownlint-cli --fix`? | Frequency |
|---|---|---|
| MD009 (no-trailing-spaces) | ✅ Yes | Common |
| MD027 (no-multiple-space-blockquote) | ✅ Yes | Common |
| MD032 (blanks-around-lists) | ✅ Yes | **Most common** |
| MD047 (single-trailing-newline) | ✅ Yes | Common |
| MD013 (line-length) | ⚠️ Not auto-fixable (semantic) | Rare |
| MD024 (duplicate-heading) | ❌ Not auto-fixable | Rare |
| MD025 (multiple-top-level-headings) | ❌ Not auto-fixable | Rare |

**The mechanical fix path is: run `markdownlint-cli --fix` at boundary-state-sync time, restage the auto-fixed files, and require the Crew to commit them.** The unfixable semantic violations (MD013, MD024, MD025) hard-fail with clear `file:line: rule` messages — no auto-fix, but the failure is immediately actionable.

### User direction (2026-05-22)

> "We have lint, but it cost us time and money. We may need to provide a better instructions to prevent violation, and maybe run lint after each change to let the agent fix the problem before moving to the next phase."

This proposal is the "run lint after each change" half. The "better instructions" half ships as a separate Tier 1 chore that updates agent charters with the explicit markdownlint-pre-commit instruction (composing with Proposal 082 Tier 1's boundary commit discipline).

## What (3 Pillars)

### Pillar 1 — Boundary-state-sync auto-fix gate

`Invoke-SpecrewBoundaryStateSync` gains a pre-sync step that runs `markdownlint-cli --fix` on changed `.md` files (auto-scoped via Proposal 083's git-diff base-ref resolution). Behavior:

```powershell
# Pseudo-code in scripts/internal/sync-boundary-state.ps1

$changedMarkdownFiles = Get-ChangedMarkdownFiles -BaseRef (Get-SpecrewLocalScopeBaseRef -ProjectRoot $resolvedProjectPath)

if ($changedMarkdownFiles.Count -gt 0) {
    Write-Host "[markdownlint] Running --fix on $($changedMarkdownFiles.Count) changed .md file(s)..."

    $lintResult = & npx --yes markdownlint-cli --fix @changedMarkdownFiles 2>&1
    $lintExitCode = $LASTEXITCODE

    $filesActuallyChanged = @(
        $changedMarkdownFiles | Where-Object { (& git diff --quiet $_ 2>$null; -not $? -eq 0) }
    )

    if ($filesActuallyChanged.Count -gt 0) {
        throw @"
[markdownlint] Auto-fixed lint violations in $($filesActuallyChanged.Count) file(s):
$($filesActuallyChanged -join "`n  ")

These files have been MODIFIED in your working tree. Please:
  1. Review the diff: git diff
  2. Stage the fixes: git add $($filesActuallyChanged -join ' ')
  3. Commit: git commit -m 'chore(lint): auto-fix markdownlint violations'
  4. Push: git push
  5. Re-run boundary-state-sync

Boundary-state-sync HALTED until the lint fixes are committed.
"@
    }

    if ($lintExitCode -ne 0) {
        # Unfixable violations remain
        throw @"
[markdownlint] Unfixable violations remain in changed .md files:
$lintResult

These violations are semantic (e.g., MD013 line-length, MD024 duplicate-heading)
and require manual editing. Boundary-state-sync HALTED.
"@
    }
}

# proceed with normal boundary-state-sync
```

The boundary fails fast with a clear directive when auto-fixes were applied. The Crew sees the diff, commits the fixes, re-runs sync. Clean.

### Pillar 2 — markdownlint-cli availability

For this to work on every Crew machine and CI runner, `markdownlint-cli` must be available. Options:

- **Best (already true today)**: `npx --yes markdownlint-cli` works in any Node.js environment. The PR-CI Lint workflow already uses this pattern. Crew machines need Node.js (which they already have for Squad CLI). No new install required.
- **Optional**: `specrew init` could verify Node.js + markdownlint-cli availability and warn if missing.
- **Fallback**: if `markdownlint-cli` invocation fails (e.g., offline machine, npm registry blocked), the gate emits a warning and proceeds — same as the validator's graceful degradation when git is unavailable.

### Pillar 3 — Memoization composition (post-086)

Once Proposal 086 Pillar 1 (memoization) ships, the markdownlint gate composes:

- Each `.md` file's content hash + markdownlint-cli version + `.markdownlint.json` rules-config hash forms a cache key
- Cache file: `.specrew/.cache/markdownlint-cache.json` (gitignored, per-developer)
- Cache hits return ~1 ms instead of ~50-200 ms per file
- Cache invalidates on any of: file content change, markdownlint-cli version change, `.markdownlint.json` rules change

For the initial 088 ship (before 086 P1), the gate runs markdownlint un-memoized. Even un-memoized, the cost is ~50-200 ms per file × handful of changed files = under 2 seconds total. Modest.

## How (implementation plan)

This is a small slice. Required artifacts per Proposal 067 (Small-Fix Slice Type): code + tests + CHANGELOG + this proposal + INDEX.

| Step | File | Effort |
|---|---|---|
| Add `Get-ChangedMarkdownFiles` helper (reuses Proposal 083's `Get-SpecrewLocalScopeBaseRef`) | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) | 0.5 SP |
| Add `Invoke-MarkdownLintAutoFix` helper that runs markdownlint-cli --fix + detects auto-fixed files via `git diff --quiet` | same | 1 SP |
| Integrate into `Invoke-SpecrewBoundaryStateSync` (pre-sync gate) | `scripts/internal/sync-boundary-state.ps1` | 1 SP |
| Graceful degradation when markdownlint-cli is unavailable (warn + proceed) | same | 0.25 SP |
| Tests: gate behavior on (a) clean .md files (no-op), (b) auto-fixable violations (fails with directive), (c) unfixable violations (fails with file:line), (d) markdownlint-cli unavailable (warns + proceeds) | `tests/integration/boundary-sync-markdownlint-gate.tests.ps1` (new) | 1.5 SP |
| Mirror parity sweep | both mirrors | 0.25 SP |
| CHANGELOG entry + INDEX update | docs | 0.25 SP |
| Agent charter updates (extends Proposal 082 Tier 1's commit discipline section) — REUSE: this part is a TIER 1 CHORE that ships separately if 088 doesn't ship soon | `extensions/specrew-speckit/squad-templates/agents/*/charter.md` + mirror | 0.5 SP |

**Total**: ~5-8 SP. Small slice (would be 2-3 SP if not for the test coverage; tests are essential for a gate that blocks all boundary advances).

**Ship target**: v0.24.3 performance bundle (or v0.25.0), as part of the process-optimization bundle locked at 2026-05-22.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 082 Tier 1** (Boundary Commit + Upstream Push Discipline) | 088 EXTENDS the boundary commit ritual — markdownlint-fix becomes an additional pre-commit step. The Tier 1 chore that updates agent charters with the explicit markdownlint instruction belongs in this proposal's companion chore. |
| **Proposal 082 Tier 2** (validator rule for `boundary-wip-uncommitted`) | 088 is the sibling for markdown-lint — extends the same "validator-rule-at-boundary" pattern to a different concern. Both share the design pattern of "gate at boundary, hard-fail with actionable directive." |
| **Proposal 083** (Local Validator Auto-Scope) | 088 REUSES 083's `Get-SpecrewLocalScopeBaseRef` to identify the diff scope for "changed .md files". This is why 088 must ship after 083. |
| **Proposal 086 Pillar 1** (Memoization) | 088 composes — markdownlint results cache by `(file-content-hash, lint-rules-hash, lint-cli-version)`. Pre-086-P1, 088 runs un-memoized (still fast enough). Post-086-P1, markdownlint gate is essentially free on cache hits. |
| **Proposal 034** (Markdown Lint Cleanup + Strict-Defaults Restoration) | 034 fixes the ~1,565 existing backlog violations + restores strict defaults in `.markdownlint.json`. 088 prevents new violations from accumulating going forward. 088 ships BEFORE 034 is recommended because 088 prevents 034 from being undone. |
| **`ci(lint-scoping)` chore** | Already scopes PR-CI markdownlint to changed files. 088 extends the SAME scoping pattern to the local boundary gate. Compose cleanly. |

## Acceptance signals

- **AC1**: When a Crew commit introduces auto-fixable markdownlint violations and the Crew invokes `Invoke-SpecrewBoundaryStateSync`, the sync fails with a clear directive listing the auto-fixed files and the next steps. Verified by integration test.
- **AC2**: When a Crew commit introduces unfixable semantic violations (e.g., MD013 line-too-long), the sync fails with a `file:line: rule` message and does NOT modify files. Verified by integration test.
- **AC3**: When the Crew's commit has clean `.md` files, the sync proceeds normally with no markdownlint output beyond a `[markdownlint] PASS (N files checked)` summary line. Verified by integration test.
- **AC4**: When `npx markdownlint-cli` is unavailable (e.g., offline runner), the sync emits a warning and proceeds rather than hard-failing. Verified by integration test (mocked unavailable npx).
- **AC5**: The gate is auto-scoped via Proposal 083's base-ref resolution — only `.md` files in the current diff are checked. Verified by integration test (commit touching no `.md` files → markdownlint not invoked).
- **AC6**: Mirror parity across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/` for both `shared-governance.ps1` and `sync-boundary-state.ps1`.
- **AC7**: Empirical perf — markdownlint gate runtime under 5s for a typical boundary commit (handful of changed `.md` files). Captured in CHANGELOG with before/after numbers.

## Out of scope

- **Backlog cleanup**: the ~1,565 existing violations in legacy spec/proposal files are out of scope. They ship in Proposal 034.
- **Auto-fix for PSScriptAnalyzer violations**: PSScriptAnalyzer has limited auto-fix support; out of scope for this slice. Could compose with 088 later if PSScriptAnalyzer's auto-fix maturity improves.
- **Pre-push or pre-commit git hooks**: out of scope. Hooks require per-clone installation and are bypassable with `--no-verify`. The boundary-sync gate is the Specrew-managed enforcement point.
- **CI-side enforcement of the gate**: PR-CI already runs markdownlint via `ci(lint-scoping)`. 088 is the LOCAL counterpart — it prevents violations from reaching the PR in the first place. Both layers compose; neither is redundant.
- **Markdownlint configuration changes**: `.markdownlint.json` rule set is out of scope; this proposal only enforces the existing rules. Rule set changes belong in Proposal 034.
- **Auto-fix THEN auto-commit**: the gate intentionally requires the Crew to commit the fixes manually rather than auto-committing. Auto-commit would obscure the fixes from the audit trail; manual commit makes the lint-fix step visible in git history (clean `chore(lint):` commits).

## Tier 1 companion chore (ships independently if 088 slips)

The "better instructions" half of the user's 2026-05-22 direction is a separate Tier 1 chore:

- Update `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` Rule 14B (per Proposal 082) to include: "Before each commit, the Crew SHOULD run `npx --yes markdownlint-cli --fix <changed-files>` to auto-fix common violations. Boundary-state-sync will enforce this gate when Proposal 088 ships; until then, run it manually."
- Update Implementer, Spec Steward, Reviewer, Retro Facilitator, Planner charters with similar instruction
- Mirror parity in `.specify/extensions/specrew-speckit/`
- ~1-2 SP, no proposal entry needed (it's a charter update chore similar to Proposal 082 T1 itself)

If 088 ships within the next few v0.24.x bundles, the Tier 1 chore can skip — 088's hard enforcement subsumes the instruction. If 088 slips into v0.25.0 or later, ship the Tier 1 chore standalone for the soft-discipline interim.

## Cross-references

- **User direction (2026-05-22)**: "We have lint, but it cost us time and money. We may need to provide a better instructions to prevent violation, and maybe run lint after each change to let the agent fix the problem before moving to the next phase."
- **Empirical motivation**: PR #424 + commit `2c2ef23` + PR #462 — three lint-catch-and-fix cycles in one day, ~30 min total wall-clock waste plus CI run costs.
- **Memory `[[feedback-lint-proposals-locally-2026-05-22]]`**: the Claude-side discipline lesson. 088 is the Specrew-side enforcement that makes that lesson hold even when discipline lapses.
- **Memory `[[project-validation-pipeline-optimization-framework-2026-05-22]]`**: 088 extends the framework to cover markdown-lint as a process-optimization axis.
- [Proposal 082](082-boundary-commit-and-upstream-push-discipline.md): file:///C:/Dev/Specrew/proposals/082-boundary-commit-and-upstream-push-discipline.md
- [Proposal 083](083-local-validator-speedup.md): file:///C:/Dev/Specrew/proposals/083-local-validator-speedup.md
- [Proposal 086](086-validation-pipeline-performance-bundle.md): file:///C:/Dev/Specrew/proposals/086-validation-pipeline-performance-bundle.md
- [Proposal 087](087-push-to-main-validator-scoping-and-nightly-truth-check.md): file:///C:/Dev/Specrew/proposals/087-push-to-main-validator-scoping-and-nightly-truth-check.md
- [Proposal 034](034-markdown-lint-strict-defaults-restoration.md): file:///C:/Dev/Specrew/proposals/034-markdown-lint-strict-defaults-restoration.md
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
