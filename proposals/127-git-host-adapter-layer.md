---
proposal: 127
title: Git-Host Adapter Layer (GitHub / GitLab / Bitbucket / Gitea / Local)
status: candidate
phase: phase-2
estimated-sp: 12-18 (adapter + 1-2 host implementations + callsite refactor); +10-15 SP for skill-template host-neutralization (could split)
priority-tier: 3
discussion: queued 2026-05-22 audit task; ~30 production files reference `gh`; biggest debt is GitHub-themed skill templates installed to every project; Proposal 089's detection pattern is the good extension model
---

# Git-Host Adapter Layer

## Why

Specrew increasingly assumes GitHub via the `gh` CLI in feature work and installed skill templates. Specs say it should support local-git and alternative hosts (GitLab, Bitbucket, Gitea); implementation drifts toward GitHub-first. The 2026-05-22 investigation captured the gap:

- **~5 production files** invoke `gh` directly. Of those, `extensions/specrew-speckit/scripts/shared-governance.ps1` (Proposal 089 reviewer detection) is ALREADY multi-host-aware by design — checks `gh` AND `git remote -v` for `github.com` substring; non-GitHub falls through to `Active = $false`. This is the **good pattern** to generalize.
- **~25 agent-installed skill templates** are GitHub-themed: `.copilot/skills/gh-auth-isolation/`, `.copilot/skills/github-multi-account/`, `.copilot/skills/git-workflow/`, `.copilot/skills/cross-squad/`, etc. These get installed to EVERY downstream project regardless of git host. GitLab/Bitbucket/Gitea/local-only projects receive content as if they're on GitHub. **This is the largest debt concentration.**
- **Proposals 089 / 092 / spec 038** explicitly name future GitLab/Bitbucket support but no abstraction layer exists.

This drift is becoming a real debt. Either Specrew commits to git-host-agnosticism with a proper adapter layer, OR explicitly accepts GitHub-only with documented limitations. The choice should be deliberate.

This proposal scopes the git-host-agnostic path. It's distinct from agent-host abstraction (Proposals 024 / 058 / 069 / 124 cover Copilot vs Claude vs Codex vs Antigravity vs Aider etc.); git-host abstraction is a **different dimension** (GitHub vs GitLab vs Bitbucket vs Gitea vs local).

## What

Three pillars. Pillar 3 (skill-template host-neutralization) is large enough it could split into a sibling proposal if effort proves too big.

### Pillar 1: `Get-GitHostAdapter` helper + adapter interface (~3-5 SP)

Shared helper at `extensions/specrew-speckit/scripts/git-host-adapter.ps1` (mirror to `.specify/`) that:

1. Detects host from `git remote -v` URL patterns:
   - `github.com` → `github` adapter (uses `gh`)
   - `gitlab.com` / `gitlab.*` → `gitlab` adapter (uses `glab` CLI)
   - `bitbucket.org` / `bitbucket.*` → `bitbucket` adapter (uses `bb` or REST API)
   - `gitea.*` → `gitea` adapter
   - Local-only / `file:///` / no remote → `local` adapter (no PR/discussion features available)
   - Unknown → `none` (features that need a host gracefully degrade)

2. Returns an adapter object with a uniform interface:

```powershell
$adapter = Get-GitHostAdapter -ProjectRoot $resolvedProjectRoot

$adapter.Kind                           # 'github' / 'gitlab' / 'bitbucket' / 'gitea' / 'local' / 'none'
$adapter.IsActive                       # $true if host CLI present + remote matches
$adapter.SupportsPullRequests            # capability flag
$adapter.SupportsDiscussions             # capability flag
$adapter.SupportsCodeReview              # capability flag (matters for Proposal 089)

# Methods (per-adapter implementations; null/throw on unsupported):
$adapter.OpenPullRequest($title, $body)
$adapter.GetPullRequestComments($prNumber)
$adapter.CreateDiscussion($category, $title, $body)
$adapter.GetRepoMetadata()
```

Each adapter implements what its host supports; the rest return `$null` or throw a clear "not supported on `<host>` adapter" error.

### Pillar 2: Refactor existing callsites (~3-5 SP)

Replace direct `gh` invocations with adapter calls. Target sites (from 2026-05-22 audit):

| Site | Current | After |
|---|---|---|
| `extensions/specrew-speckit/scripts/shared-governance.ps1` Proposal 089 reviewer detection | Direct `gh` + URL substring check | `Get-GitHostAdapter` returns `Kind='github'` + `SupportsCodeReview=$true` |
| `scripts/specrew-init.ps1` (line ~1483 `gh api /user` string label) | String literal | Adapter-derived label |
| Future Proposal 089 expansion to GitLab/Bitbucket | Would require duplicated code per host | Single adapter call; per-host implementation behind interface |
| Future PR-at-feature-close SDLC implementations on non-GitHub hosts | Currently undefined | Adapter knows how to open PR per host |

Keep `.github/scripts/sync-specrew-board.ps1` as-is — that's legitimately GitHub-specific by location (lives in `.github/`).

### Pillar 3: Skill-template host-neutralization (~10-15 SP — could split)

Audit + refactor the ~25 GitHub-themed installed skill templates. Three buckets:

| Bucket | Action |
|---|---|
| **Host-neutral content** mistakenly using GitHub-specific terms | Rewrite to be host-neutral |
| **Genuinely GitHub-specific skills** (gh-auth-isolation, github-multi-account) | Stay GitHub-only but install ONLY for projects where adapter returns `Kind='github'` |
| **Concept skills that need per-host variants** (PR review, release process) | Author per-host variants; `specrew init` installs the variant matching the detected adapter |

`specrew init` updates to query the adapter at install time and only deploy host-applicable skills. Local-only projects get the host-neutral subset.

### Pillar 4 (optional bundle): Documentation alignment (~1-2 SP)

- Update README + docs/user-guide to either claim "git-host-agnostic via adapter layer" (target after this proposal ships) or "GitHub-first with limited multi-host support" (current state)
- Add a "Git Host Compatibility Matrix" section showing which features work on which hosts (Github = full; GitLab/Bitbucket = PR support; Local = no PR/discussion)

## How

Total ~12-18 SP for Pillars 1+2+4. Pillar 3 adds ~10-15 SP and could split.

| Step | File | Effort |
|---|---|---|
| Pillar 1 adapter helper + interface contract | `extensions/specrew-speckit/scripts/git-host-adapter.ps1` (+ mirror) | 3-5 SP |
| Pillar 1 GitHub adapter implementation | `extensions/specrew-speckit/scripts/git-hosts/github-adapter.ps1` (new) | 2 SP |
| Pillar 1 Local adapter implementation (degraded-mode reference) | `extensions/specrew-speckit/scripts/git-hosts/local-adapter.ps1` (new) | 1 SP |
| Pillar 1 GitLab adapter (optional in v1) | `extensions/specrew-speckit/scripts/git-hosts/gitlab-adapter.ps1` (new) | 2-3 SP |
| Pillar 2 callsite refactor + tests | multiple files | 3-5 SP |
| Pillar 3 skill-template audit + per-host variants | `.squad/templates/skills/` + scaffolder | 10-15 SP (could split) |
| Pillar 4 docs alignment | README, docs/user-guide.md | 1-2 SP |
| Integration tests covering adapter detection + capability flags | `tests/integration/git-host-adapter.tests.ps1` (new) | 2 SP |

## Acceptance criteria

- **AC1**: `Get-GitHostAdapter` returns the correct `Kind` for projects with GitHub / GitLab / Bitbucket / Gitea / local-only remotes
- **AC2**: GitHub adapter's `OpenPullRequest` invokes `gh pr create`; equivalent on GitLab via `glab`
- **AC3**: Local adapter exposes `SupportsPullRequests = $false`; calls to `OpenPullRequest` throw clear "not supported on local adapter" error
- **AC4**: Proposal 089's reviewer-detection helper refactored to use adapter; existing GitHub behavior unchanged; GitLab projects now correctly detect `glab` instead of falling through to `Active=$false`
- **AC5**: `specrew init` on a GitLab project does NOT install GitHub-themed skill templates (per Pillar 3)
- **AC6**: `specrew init` on a local-only project (no remote) installs the host-neutral skill subset only
- **AC7**: Mirror parity preserved
- **AC8**: README + docs/user-guide accurately describe the git-host adapter and capability matrix

## Out of scope

- **Replacing `gh` for `.github/scripts/sync-specrew-board.ps1`** — that script is legitimately GitHub-specific by location; not a debt to fix
- **Auto-discovery of host CLIs beyond the known list** — adapter list is curated; new hosts add by extending the registry (similar pattern to Proposal 024 host registry)
- **Cross-host PR/Issue migration** — adapter abstracts operations on a single host; cross-host is its own concern
- **OAuth/authentication abstraction** — each adapter delegates to its CLI's auth (gh auth, glab auth, etc.); a unified auth layer is separate
- **Pillar 3 can split if effort exceeds appetite** — Pillars 1+2+4 land as the adapter foundation; Pillar 3 as a sibling proposal if needed

## Composition

- **Proposal 089 (PR Review Integration)** — direct beneficiary; current detection helper is the model; adapter generalizes it
- **Proposal 092 (Specrew Dashboard)** — integrations view (referenced GitLab as future) can now use adapter
- **Proposal 081 (Reviewer Visual Evidence)** — multi-host considerations get a real seam
- **Proposal 024 (Multi-Host Runtime Abstraction)** — orthogonal dimension (agent-host vs git-host); both can ship independently
- **Proposal 067 (Small-Fix Slice Type)** — too big for small-fix; this is a full small Phase 2 feature

## Risks

- **Skill-template refactor scope creep** — Pillar 3 may be larger than estimated. Mitigation: ship Pillars 1+2+4 first; Pillar 3 as sibling proposal if needed
- **`glab` / `bb` / Gitea CLI maturity** — non-GitHub CLIs have different stability / feature parity. Mitigation: implement GitHub + Local first (highest ROI); GitLab as second adapter; others as community-contributed extensions
- **Capability flag drift** — features added per host may not be reflected in flags. Mitigation: capability flags are conservative (default `$false`); adapters opt-in per feature; integration tests cover flag accuracy
- **Authentication divergence** — each host CLI has its own auth flow; users may not have the right CLI installed. Mitigation: TestRuntimeInstalled per adapter; clear "install `glab` first" guidance when GitLab adapter is needed but `glab` is absent
- **Documentation ambiguity** — "git-host-agnostic" is a strong claim; partial support muddies messaging. Mitigation: Pillar 4 explicitly lists per-host capability matrix; no overpromising

## Empirical motivation

2026-05-22 user observation that the parallel claude session (working on F-038 / Proposal 089 PR Review Integration) uses `gh` directly. The intent vs implementation gap was identified. Memory captured at `[[project-github-coupling-investigation-2026-05-22]]` with the file-count audit (~30 production references; ~25 of those are agent-installed skill templates that get distributed to every downstream project regardless of git host).

The decision point flagged in memory: investigate, then either commit to agnosticism (this proposal) OR explicitly declare Specrew GitHub-only with documented limitations. This proposal scopes the agnostic path; if effort proves too high, the alternative is a deliberate documentation update declaring GitHub-only.

## Cross-references

- file:///C:/Dev/Specrew/proposals/089-pr-review-integration.md
- file:///C:/Dev/Specrew/proposals/092-specrew-dashboard-and-board-integration.md
- file:///C:/Dev/Specrew/proposals/081-reviewer-visual-evidence-mermaid-mandate.md
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md
- file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/shared-governance.ps1 (good detection-pattern reference)
- file:///C:/Dev/Specrew/.github/scripts/sync-specrew-board.ps1 (intentionally GitHub-specific; out of scope)
- file:///C:/Dev/Specrew/.squad/templates/skills/ (Pillar 3 audit target)
- Memory: [[project-github-coupling-investigation-2026-05-22]]

## Status history

- 2026-05-22: investigation queued after user observation that parallel feature work uses `gh` directly; audit captured ~30 file references with ~25 in skill templates.
- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep. Pillars 1+2+4 scoped as v1; Pillar 3 marked as splittable sibling if effort exceeds appetite.
