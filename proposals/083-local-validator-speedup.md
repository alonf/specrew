---
proposal: 083
title: Local Validator Speedup — Auto-Scoped Default for Feature-Branch Invocations
status: candidate
phase: phase-2
estimated-sp: 5
discussion: tbd
---

# Local Validator Speedup — Auto-Scoped Default for Feature-Branch Invocations

## Why

`ci(lint-scoping)` shipped earlier and gave PR-CI a ~15× speedup by scoping markdownlint, PSScriptAnalyzer, and `validate-governance.ps1` to files changed in the PR diff. PR #384's `chore(validator-perf-dedupe)` narrowed the global-state pathspec list (load-bearing surfaces only) so the `-ChangedOnly` fallback to full-repo only fires for true global-state changes.

The mechanism exists end-to-end. But **local invocations still run full-repo by default**.

### Empirical motivation (F-029 session, 2026-05-21)

During F-029's review-boundary handling, the Crew invoked `validate-governance.ps1` multiple times per boundary transition. Each invocation looked like:

```
pwsh -NoProfile -ExecutionPolicy Bypass -File ...\validate-governance.ps1 
     -ProjectPath C:\Dev\Specrew 
     -IterationPath C:\Dev\Specrew\specs\029-baseline-hygiene\iterations\001
```

No `-ChangedOnly` flag. No `-BaseBranch`. Result: full-repo validation across all 44+ iterations every single time. Each lifecycle boundary triggered minutes of cumulative validator runtime that would have been seconds with auto-scope.

This applies to:

- The Crew's lifecycle validation calls at every boundary
- Manual local debug invocations by maintainers
- Test harnesses that shell out to the validator
- Any local consumer of `validate-governance.ps1`

### The wiring gap

`ci(lint-scoping)` added `-ChangedOnly` as an OPT-IN flag invoked explicitly by the GitHub Actions workflow when `GITHUB_BASE_REF` is set. Outside that explicit path, the validator defaults to full-repo. Local invocations have no equivalent auto-detection.

### User direction (2026-05-21)

> "Did we already fix the speedup of the local verification as we did with the CI?"

Answer: no. The infrastructure is in place (the `-ChangedOnly` flag, the narrowed global-state list, the `Get-ChangedIterations` helper). The defaults aren't wired up. This proposal closes that gap.

## What

### Pillar 1: Auto-detected base branch for local invocations

A new helper `Get-SpecrewLocalScopeBaseRef` resolves the base branch using a priority chain:

1. `$env:GITHUB_BASE_REF` if set (CI path; already used by the lint workflow)
2. `git symbolic-ref refs/remotes/origin/HEAD` if it resolves (default branch upstream pointer)
3. `git for-each-ref refs/remotes/origin/main refs/remotes/origin/master` as a fallback
4. Return `$null` if none of the above resolve (e.g., no remote configured, detached HEAD with no upstream)

### Pillar 2: Default auto-scope when on a feature branch

`validate-governance.ps1` gains a default behavior change:

| Invocation | Behavior |
|---|---|
| `-ChangedOnly` explicitly passed | Honor the existing flag (current behavior) |
| `-FullRun` explicitly passed (new flag) | Run full repo, bypass auto-scope |
| Neither flag passed AND on feature branch AND base detectable | **Auto-apply `-ChangedOnly` against the detected base** (new default) |
| Neither flag passed AND on main/master | Run full repo (no surprise unscope on the truth branch) |
| Neither flag passed AND base undetectable | Run full repo + emit `[validator-scope] base-undetectable; full-repo run` info banner |

### Pillar 3: Transparent scope reporting

Every validator run emits a `[validator-scope]` stdout line as the first informational output:

```
[validator-scope] auto-scoped to origin/main...HEAD (3 iterations, 5 files in diff)
```

or

```
[validator-scope] full-repo (on main; 44 iterations)
```

or

```
[validator-scope] full-repo (base-undetectable; 44 iterations)
```

This lets users (and Squad audit trails) see exactly what scope ran without having to read the logs. Composes naturally with the existing `[validator-timing]` line from PR #384.

### Pillar 4: Squad governance prompt + Reviewer charter alignment

A short note in the coordinator governance prompt + Reviewer charter explains that local validator runs now self-scope by default. The Crew doesn't need to remember to pass `-ChangedOnly`; the default does the right thing on a feature branch.

When a Squad agent needs a deliberate full-repo run (e.g., during feature-closeout to ensure no cross-feature drift), they pass `-FullRun` explicitly. That keeps the discipline visible in the audit trail.

## How (implementation plan)

| Step | File | Effort |
|---|---|---|
| Add `Get-SpecrewLocalScopeBaseRef` helper with the priority chain | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror + `scripts/internal/`) | 1 SP |
| Modify `validate-governance.ps1` default behavior: detect → auto-scope OR full-repo | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror) | 1 SP |
| Add `-FullRun` opt-out flag with explicit precedence over auto-scope | same | 0.5 SP |
| Emit `[validator-scope]` stdout line at the top of every run | same | 0.5 SP |
| Update Squad coordinator governance prompt: note that local validator runs self-scope by default; `-FullRun` for explicit full-repo | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (+ mirror) | 0.25 SP |
| Update Reviewer charter: note auto-scope default | `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` (+ mirror) | 0.25 SP |
| Tests: detection logic across edge cases (on main, on feature branch with detectable base, no remote, detached HEAD, multiple remotes) | `tests/integration/validate-governance-changed-only.tests.ps1` (extend existing) | 1 SP |
| CHANGELOG entry under Changed | `CHANGELOG.md` | 0.25 SP |
| Mirror parity sweep | both mirrors | 0.25 SP |

Total: ~5 SP. Small-fix-slice candidate per Proposal 067.

**Ship target**: v0.24.2 bundle alongside 082 Tier 1 + 081 Pillar 6 if F-029 closes in time; otherwise v0.24.3 as a fast follow-up.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **`ci(lint-scoping)` chore (shipped)** | This proposal is the local-side counterpart. CI got the speedup; this closes the same gap on local. Both share the `-ChangedOnly` + `Get-ChangedIterations` machinery. |
| **PR #384 `chore(validator-perf-dedupe)` (shipped)** | PR #384 narrowed the global-state pathspec list to load-bearing surfaces only. That narrowing is the precondition that makes auto-scope safe — fewer false fallbacks to full-repo. |
| **Proposal 082 (Boundary Commit + Upstream Push Discipline)** | Sibling methodology integrity slice. Both ship in v0.24.2 bundle if F-029 closes in time. 082 enforces commit-at-boundary discipline; 083 makes the validator at every boundary fast. Together they make the per-boundary cost (commit + validate + push) low enough that the discipline is sustainable. |
| **Proposal 081 (Reviewer Visual Evidence — Multi-Type Diagrams + Mermaid Mandate)** | Sibling small-fix slice in v0.24.2 bundle if F-029 closes in time. Both are methodology integrity. |
| **Proposal 030 (Quality Hardening Bundle)** | Could absorb if shipped together later. 083 is small enough to ship independently. |
| **Proposal 045 (CI Watchdog & Recurrence Prevention)** | 045 watches for regressions in CI; 083 speeds up local detection. Related but orthogonal. |
| **Proposal 042 (Specrew Integration Test Suite)** | 042's test runs benefit from a faster validator. Composes. |

## Acceptance signals

- **AC1**: `Get-SpecrewLocalScopeBaseRef` helper exists in `shared-governance.ps1` (and mirror) with the documented priority chain.
- **AC2**: `validate-governance.ps1` default behavior on a feature branch auto-applies `-ChangedOnly` against the detected base. Verified by running the validator on `029-baseline-hygiene` (or equivalent test branch) without any flags and observing scoped output.
- **AC3**: `-FullRun` flag bypasses auto-scope and forces full-repo. Verified by test.
- **AC4**: `-ChangedOnly` explicit flag continues to work (current behavior preserved).
- **AC5**: On `main`/`master`, defaults to full-repo (no auto-scope). Verified by test.
- **AC6**: `[validator-scope]` stdout line appears at the top of every run with accurate scope info (mode, iteration count, file count in diff if scoped).
- **AC7**: When base ref is undetectable (no remote, detached HEAD with no upstream), validator falls back to full-repo cleanly + emits a clear info banner explaining why.
- **AC8**: Squad governance prompt + Reviewer charter mention the auto-scope default + the `-FullRun` opt-out.
- **AC9**: Empirical perf: validator on `029-baseline-hygiene` (touching 1 iteration) drops from ~1+ minute full-repo to seconds auto-scoped. Captured in tests or in CHANGELOG entry.

## Out of scope

- **CI-side scope changes**: `ci(lint-scoping)` already handles CI; this proposal does not modify the workflow yaml.
- **Cross-platform path handling beyond what `git diff` already provides**: `Get-ChangedIterations` already handles Windows/Linux path differences correctly.
- **Validator output caching**: not in scope; the speedup comes from running less, not from caching results.
- **Multi-remote scenarios with non-`origin` upstreams**: v1 assumes the conventional `origin` remote. Users with non-conventional remote names can pass `-ChangedOnly -BaseBranch <ref>` explicitly. Future work could detect alternative upstreams.

## Cross-references

- **User direction**: 2026-05-21 conversation, "Did we already fix the speedup of the local verification as we did with the CI?"
- **Empirical evidence**: F-029 session validator invocations (multiple per boundary, all unscoped, all full-repo)
- **`ci(lint-scoping)` CHANGELOG entry**: file:///C:/Dev/Specrew/CHANGELOG.md (Unreleased section, ci(lint-scoping))
- **PR #384 `chore(validator-perf-dedupe)` CHANGELOG entry**: same file
- **`Get-ValidatorGlobalStatePathspecs` (the load-bearing pathspec list)**: file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/shared-governance.ps1
- **Memory: `[[project-validator-scoping-chore-queued-2026-05-20]]`** (the chore that shipped as ci(lint-scoping))
- **Memory: `[[project-f029-boundary-discipline-incidents-2026-05-21]]`** (F-029 validator invocation context)
- Proposal 082 (Boundary Commit + Upstream Push Discipline): file:///C:/Dev/Specrew/proposals/082-boundary-commit-and-upstream-push-discipline.md
- Proposal 081 (Reviewer Visual Evidence): file:///C:/Dev/Specrew/proposals/081-reviewer-visual-evidence.md
- Proposal 045 (CI Watchdog & Recurrence Prevention): file:///C:/Dev/Specrew/proposals/045-ci-watchdog-recurrence-prevention.md
- Proposal 030 (Quality Hardening Bundle): file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
