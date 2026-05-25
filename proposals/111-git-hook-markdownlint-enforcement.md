---
proposal: 111
title: Git-Hook-Level Markdownlint Enforcement (Pre-Commit + Pre-Push)
status: candidate
phase: phase-2
estimated-sp: 5-8
discussion: 2026-05-25 PR #844 iter-011 CI lint failure on scaffolder-generated current-architecture.md missing trailing newline — Proposal 088's boundary-sync gate didn't fire because the commit was ad-hoc, not boundary-routed
depends-on:
  - 088  # Markdown Lint Pre-Boundary Auto-Fix Discipline (this proposal complements 088 with hook-level coverage)
composes-with:
  - 034  # Markdown Lint Cleanup and Strict-Defaults Restoration
  - 067  # Small-Fix Slice Type (this proposal is itself a small-fix slice exemplar)
blocks: []
---

# Git-Hook-Level Markdownlint Enforcement (Pre-Commit + Pre-Push)

## Why

Proposal 088 (F-033, v0.24.3) shipped a markdownlint auto-fix gate that runs inside `Invoke-SpecrewBoundaryStateSync`. It catches lint violations at every lifecycle boundary (specify, clarify, plan, tasks, review-signoff, retro, iteration-closeout, feature-closeout). That's working as designed for boundary-routed commits.

**The gap**: ad-hoc commits — chores, bug fixes, scaffolder regenerations, hand-edits to artifacts between boundaries — bypass the gate entirely. The pre-boundary gate doesn't fire on `git commit -m "chore: …"` or any direct `git add && git commit` flow.

Empirical motivation (the bug that prompted this proposal): PR #844 iter-011 commit included a scaffolder-generated `current-architecture.md` that was missing a single trailing newline. Markdownlint MD047 caught it in CI Lint after a 15-second run. Cascaded failures: Contract lane + Deterministic gate both skipped because Lint failed. Required a follow-up `chore` commit to add one byte of newline.

The cascade matters: when CI Lint fails, the gates that DEPEND on Lint (Contract lane, Deterministic gate) silently skip. That means a single missing newline becomes "silent truth-check disable" until the next push. Captured in maintainer memory `feedback_lint_proposals_locally_2026_05_22.md` — but the memory is a behavior rule for the maintainer, not a methodology guarantee for the system.

For downstream projects: same gap, worse impact. A user committing a quick doc fix or hand-editing a spec gets the same bypass. Their CI also has the cascade. Their users feel it as "Specrew is supposed to lint markdown but it didn't catch this".

## What

A git pre-commit hook deployed by `specrew init` that runs `markdownlint --fix` on staged `.md` files. The hook composes with Proposal 088's boundary-sync gate as defense in depth:

| Layer | When it runs | What it catches |
|---|---|---|
| **Pre-commit hook** (NEW — this proposal) | Every `git commit` (boundary-routed OR ad-hoc) | Lint violations in staged `.md` files BEFORE they enter history |
| **Boundary-sync auto-fix gate** (existing, Proposal 088) | Every `Invoke-SpecrewBoundaryStateSync` invocation | Lint violations across the iteration's full MD surface AT boundary advancement time |
| **CI Lint job** (existing, GitHub Actions) | Every push to PR / main | Full-repo full-rule lint as final guard |

Each layer catches issues the others might miss. Pre-commit is the cheapest and fastest layer.

### Pre-commit hook behavior

```text
On `git commit`:
  1. Resolve staged *.md files: `git diff --cached --name-only --diff-filter=ACM -- '*.md'`
  2. If no staged MD files → exit 0 (no-op, fast path)
  3. Run `markdownlint --fix <staged.md>` on each
  4. If auto-fix modified files:
     a. Re-stage the auto-fixed files: `git add <files>`
     b. Print: "[pre-commit] markdownlint auto-fixed N file(s); proceeding with commit"
     c. Continue commit (allow auto-fix-and-go)
  5. If unfixable violations remain (markdownlint exit != 0):
     a. Print file:line:rule per violation
     b. Exit non-zero → block commit
     c. Print actionable next step: "Fix manually, then re-commit. Or commit with --no-verify to bypass (records bypass in audit trail)"
```

### Pre-push hook (companion, second slice)

```text
On `git push`:
  1. Resolve commits being pushed: `git rev-list <remote>..HEAD`
  2. If no commits to push → exit 0
  3. Resolve `.md` files touched in those commits: `git diff --name-only <remote>..HEAD -- '*.md'`
  4. Run `markdownlint` (no --fix) on each
  5. If violations → block push with diagnostic
```

Pre-push is heavier than pre-commit (full lint, not just staged) and adds push latency. Optional second slice; pre-commit is the primary value.

### Cross-platform via PowerShell

Hooks ship as PowerShell scripts (not bash) because:

- Specrew's existing scripts/CLI surface is pwsh-based
- Windows-first usage profile (Specrew's primary platform)
- PowerShell 7+ works on macOS + Linux + Windows
- Existing markdownlint invocation pattern matches Specrew's other PS scripts

Implementation: `.specrew/hooks/pre-commit.ps1` (source) → copied to `.git/hooks/pre-commit` (executable shim that invokes pwsh) by `specrew init`.

The `.git/hooks/pre-commit` is a 3-line shim:

```bash
#!/usr/bin/env bash
exec pwsh -NoProfile -File "$(git rev-parse --show-toplevel)/.specrew/hooks/pre-commit.ps1" "$@"
```

`.git/hooks/` is per-repo and not in source control. The shim is regenerated by `specrew init` / `specrew update` from the canonical pwsh source. Users can edit the shim or replace it; Specrew rewrites it on next `init`/`update` unless an opt-out marker exists.

### Opt-out mechanism

`.specrew/config.yml` adds:

```yaml
hooks:
  markdownlint_pre_commit:
    enabled: true     # default; set false to skip hook installation
    auto_fix: true    # default; set false to halt on any violation (no auto-fix)
    bypass_marker: '.git/hooks/.specrew-markdownlint-disabled'
```

Disabling is opt-in friction. Most projects want the gate.

## How

| Step | Implementation surface | Effort |
|---|---|---|
| Author `.specrew/hooks/pre-commit.ps1` canonical hook script | New file in Specrew module distribution | 2 SP |
| Add hook deployment to `scripts/init/template-deploy.ps1` (or new `init/hooks-deploy.ps1` slice) | Existing init pipeline gains hook-deploy step | 1.5 SP |
| Add opt-out config field to `.specrew/config.yml` schema + reading logic | Specrew config layer gains hooks section | 1 SP |
| Add integration test: `tests/integration/git-hooks.tests.ps1` | New test scaffold proves hook fires, auto-fixes, halts | 1 SP |
| Self-install hook in Specrew dev repo + update CONTRIBUTING.md | Specrew dogfoods its own hook | 0.5 SP |
| Validator rule: warn if `.git/hooks/pre-commit` is missing but config says `enabled: true` (detects manual hook deletion) | `validate-governance.ps1` adds a new rule | 1 SP |

**Total**: 7 SP. Small-fix slice (~1-2 hours wall-clock).

### Sequencing

- **Slice 1 (this proposal, primary)**: pre-commit hook + opt-out + tests + dogfood. 5-7 SP.
- **Slice 2 (optional follow-up)**: pre-push hook + tests. +2-3 SP. Can ship later when value justifies the latency.

### Empirical reference: the iter-011 incident

PR #844 commit `aafba6fc` included `current-architecture.md` without trailing newline. CI Lint exit 1 at 15s. Cascade: Contract lane + Deterministic gate skipped. Follow-up commit `0c67a1e5` added one newline. Total wasted: ~2 minutes maintainer time + ~6 minutes CI re-run + cascade-skipped truth-checks until next push.

With pre-commit hook: caught at `git commit` time, auto-fixed locally, re-staged, commit proceeds. **Zero maintainer time, zero CI cost, zero cascade.**

## Open questions

1. **PowerShell-required prerequisite**: hooks require pwsh on PATH. Most Specrew users have it (it's a documented dependency). Edge case: a user who clones a Specrew project without pwsh installed gets a commit-time error from the hook. Mitigation: hook shim detects pwsh-missing and prints "pwsh not on PATH; either install PowerShell 7+ or disable the hook via `.specrew/config.yml`". Acceptable degradation.
2. **`--no-verify` bypass discoverability**: users who hit a halt may want to bypass. Should the halt message mention `--no-verify` explicitly? Argument for: workflow continuity. Argument against: encourages bypass habit. Recommend: mention `--no-verify` but explicitly note "bypass is recorded as an event the next boundary-sync will surface". Soft-discouragement, not hard-prevention.
3. **Cross-OS shebang for the shim**: `#!/usr/bin/env bash` works on macOS/Linux + WSL but Windows native git uses git-bash which works too. Edge case: Windows git installed without bash. Mitigation: fall back to a `.cmd` shim that runs `pwsh -File ...`. `specrew init` detects platform and installs the right shim.
4. **Race condition: user opens commit in editor while hook re-stages files**: if hook auto-fixes after staging but before editor opens, are the re-staged changes visible? Typical git behavior: auto-staging happens BEFORE the commit message editor opens. Should work as expected, but test on multiple git versions.
5. **Hook propagation on team projects**: `.git/hooks/` is per-clone. New team members cloning the repo don't get the hook automatically; they need `specrew init` (or `specrew update`) to materialize it. Document this in onboarding flow. (Same constraint as husky / lefthook — git-hooks-as-source-of-truth is a known git limitation.)

## Composition Notes

- **Proposal 088 (F-033 Markdown Lint Pre-Boundary Auto-Fix)** stays untouched. The boundary-sync gate is still the lifecycle-aware layer. This proposal adds the commit-aware layer underneath.
- **Proposal 034 (Markdown Lint Cleanup + Strict-Defaults Restoration)** composes naturally — when strict defaults restore, the pre-commit hook prevents new violations from entering history while 034 cleans up existing ones.
- **Proposal 067 (Small-Fix Slice Type)** — this proposal IS itself a small-fix slice exemplar. Single concern, ~7 SP, validator rule + hook script + test + doc update. Could become the reference implementation for what a "small-fix slice" looks like in canonical form.
- **F-039 / Proposal 065 boundary enforcement** is orthogonal. F-039 enforces lifecycle gates; this enforces lint at commit time. Both can be bypassed (F-039 via `--bypass-boundary-enforcement`, hook via `--no-verify`), both record the bypass.

## Empirical Motivation Captured

User exact phrasing (2026-05-25, after PR #844 iter-011 CI lint failure): "How come we fail in lint is it should run locally before commit? In Specrew we supposed to have a hook/gate that run local lint on all changes md files. It is also important for downstream project."

Investigation confirmed:

- Specrew has the boundary-sync gate (Proposal 088 / F-033) — works for lifecycle commits
- Specrew does NOT have a git pre-commit hook — gap for ad-hoc commits
- Specrew's own repo doesn't dogfood a pre-commit hook either
- The maintainer memory `feedback_lint_proposals_locally_2026_05_22.md` is a behavior rule, not a system guarantee
- Downstream projects have the same gap

This proposal closes the gap at the cheapest layer (pre-commit) with optional follow-up at the second-cheapest layer (pre-push). The boundary-sync gate remains the authoritative lifecycle-aware layer.

## Not in Scope

- Replacing the boundary-sync gate (Proposal 088 stays as the lifecycle layer)
- PowerShell-script lint hooks (PSScriptAnalyzer pre-commit) — separate proposal candidate, similar pattern
- Other languages' linters (rustfmt, ruff, prettier, eslint) — out of scope unless Specrew adds first-class support for those domains
- Hook framework adoption (husky, lefthook) — Specrew's pwsh-first pattern doesn't need an extra dependency for this surface area
