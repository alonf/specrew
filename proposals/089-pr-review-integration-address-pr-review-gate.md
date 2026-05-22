---
proposal: 089
title: PR Review Integration — Address-PR-Review Lifecycle Gate (Multi-Host Aware)
status: candidate
phase: phase-2
estimated-sp: 5-8
discussion: tbd
---

# PR Review Integration — Address-PR-Review Lifecycle Gate (Multi-Host Aware)

## Why

Automated PR review tools (GitHub Copilot review, GitLab Code Suggestions, etc.) catch a meaningful class of issues that Specrew's automated layers don't catch today. Empirical evidence from PR #462 (Feature 030 / Proposal 083, 2026-05-22):

GitHub Copilot's review caught **8 substantive findings** that all passed Specrew's PR-CI:

| # | Finding | Class | Caught by Specrew automation? |
|---|---|---|---|
| 1 | `.specify/feature.json` not cleared at feature-closeout | Lifecycle-state bug (Crew bypassed canonical sync) | ❌ no |
| 2 | `file:///C:/...` absolute URI in spec.md (won't work on GitHub) | Markdown link rot | ❌ no |
| 3-8 | 13 references to non-existent `scripts/internal/{shared,validate}-governance.ps1` path | LLM hallucination in spec authoring | ❌ no |
| 9 | plan.md effort math: 5.0 SP claimed total vs 6.5 SP actual phase sum | Spec arithmetic inconsistency | ❌ no |
| 10 | Unused `ElapsedMs` field in test helper | Dead code | ❌ no |
| 11 | Typo "conveniente" → "convenient" | Pure manual catch | ❌ no |

Of these, ~5 would have shipped to main and rotted into the codebase if Copilot hadn't surfaced them.

**Specrew's lifecycle currently has no formal step for processing automated PR review feedback.** PR-merge is the maintainer's final action; if the maintainer forgets to read Copilot's review (easy to do — it's posted as PR comments, not as a CI gate), the feedback gets lost. The 2026-05-22 PR #462 incident was caught only because the maintainer was actively prompted by the user to check Copilot's review.

This proposal formalizes the discipline as an explicit lifecycle gate between PR-open and merge: **address-pr-review**. The gate is host-conditional — it activates only when the host provides automated review, and auto-passes on hosts without such tooling.

### User direction (2026-05-22)

> "Add to memory always check the GitHub Copilot review of PRs. Do we need to add to the Specrew flow the ability (optional if using GitHub) to address GitHub PR reviews?"

This proposal is the formal flow addition. Memory `[[feedback-check-github-copilot-pr-review-2026-05-22]]` captures the per-maintainer discipline; this proposal captures the methodology-level enforcement.

## What (4 Pillars)

### Pillar 1 — New lifecycle gate: `address-pr-review`

Insert a new boundary between `pr-open` and `pr-merge`:

```text
... → feature-closeout → pr-open → address-pr-review → pr-merge
```

The gate's contract: before the maintainer (or Crew, depending on authorization) merges the PR, all automated reviews on the PR must be **resolved** — each finding has either:

- A fix commit on the PR branch (outcome resolved)
- A documented root-cause fix queued (e.g., new validator rule scheduled in INDEX)
- An explicit "won't fix" determination with rationale

The gate is enforced by Specrew governance (validator rule + boundary state) when a host that supports automated review is detected. On hosts without automated review, the gate auto-passes.

### Pillar 2 — Multi-host detection and conditional firing

A new helper detects whether the current host provides automated PR reviews:

```powershell
# Pseudo-code in shared-governance.ps1
function Test-HostProvidesAutomatedPrReview {
    param([string]$ProjectRoot)

    # GitHub: detect via .github/dependabot.yml or .github/copilot/ presence,
    # OR via gh api detection of Copilot bot on the repo
    if (Test-GitHubHostWithCopilot -ProjectRoot $ProjectRoot) {
        return @{ Host = 'github'; Reviewer = 'copilot-pull-request-reviewer'; Active = $true }
    }

    # GitLab: detect via .gitlab-ci.yml + GitLab Code Suggestions config
    if (Test-GitLabHostWithCodeSuggestions -ProjectRoot $ProjectRoot) {
        return @{ Host = 'gitlab'; Reviewer = 'gitlab-code-suggestions'; Active = $true }
    }

    # No automated reviewer detected
    return @{ Active = $false }
}
```

When `Active = $false`, the address-pr-review gate auto-passes — Crew can advance directly from pr-open to pr-merge. This makes the proposal **multi-host friendly out of the box** and composes with Proposal 024 (Multi-Host Runtime Abstraction).

### Pillar 3 — `pr-review-resolution.md` artifact

When the gate is active, Crew (or maintainer) produces `specs/<feature>/iterations/<N>/pr-review-resolution.md`:

```markdown
# PR Review Resolution

**PR**: #462
**Host**: github
**Reviewer**: copilot-pull-request-reviewer
**Captured At**: 2026-05-22T01:32:00Z

## Findings

### Finding 1: `.specify/feature.json` not cleared at feature-closeout

- **Type**: lifecycle-state-bug
- **Severity**: real (would have shipped to main)
- **Outcome fix**: commit 28f938f cleared feature_directory + added schema field
- **Root-cause fix**: QUEUED — validator rule "feature_directory MUST be empty at feature-closeout" → small-fix slice in Proposal 030 Quality Hardening Bundle
- **Won't fix**: N/A

### Finding 2: file:/// URI in spec.md

- **Type**: markdown-link-rot
- **Severity**: would-not-work-on-github
- **Outcome fix**: commit 28f938f replaced with repo-relative link
- **Root-cause fix**: TIGHTENED memory `[[feedback-file-url-format-for-paths]]` scope to handoff prose only
- **Won't fix**: N/A

# ... etc for each finding
```

The artifact serves three purposes:

1. **Audit trail**: future maintainers/code archaeologists can see why a finding was resolved a particular way
2. **Root-cause tracking**: explicit "outcome fix" vs "root-cause fix" columns prevent the form-vs-meaning trap (a problem can look fixed when only the symptom is addressed)
3. **Won't-fix transparency**: when a finding is dismissed, the rationale is recorded for review

### Pillar 4 — Validator gate on the resolution artifact

A new validator rule fires at the address-pr-review boundary:

- If `Test-HostProvidesAutomatedPrReview` returns `Active = $true` for the current host
- AND a PR is open for the current branch
- AND at least one automated review with findings exists on the PR
- THEN `specs/<feature>/iterations/<N>/pr-review-resolution.md` MUST exist AND each PR finding MUST appear in the artifact's Findings section with one of {outcome-fix, root-cause-fix, won't-fix} resolution.

When the gate fails, the boundary halts with a clear directive listing the unresolved finding IDs. Composes with Proposal 030 (Quality Hardening Bundle) and Proposal 088 (markdownlint pre-boundary auto-fix discipline) as another "fail at boundary with clear directive" gate.

## How (implementation plan)

This is a medium small-fix slice per Proposal 067. Required artifacts: code + tests + CHANGELOG + this proposal + INDEX.

| Step | File | Effort |
|---|---|---|
| Add `Test-HostProvidesAutomatedPrReview` helper | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) | 1 SP |
| Add `Get-PrReviewFindings` helper that calls `gh api` to fetch review + inline comments | same | 1.5 SP |
| Add `Test-PrReviewResolutionGate` validator rule | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror) | 1.5 SP |
| Boundary integration: add `address-pr-review` to known boundary types in `sync-boundary-state.ps1` | `scripts/internal/sync-boundary-state.ps1` | 0.5 SP |
| New artifact template: `pr-review-resolution.template.md` | `extensions/specrew-speckit/templates/` (+ mirror) | 0.5 SP |
| Update Reviewer + Spec Steward charters with address-pr-review responsibilities | `extensions/specrew-speckit/squad-templates/agents/{reviewer,spec-steward}/charter.md` (+ mirror) | 0.5 SP |
| Update Coordinator governance rule 5 (gate phase transitions) to include the new boundary | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (+ mirror) | 0.25 SP |
| Tests: gate behavior — host detection (github vs other), unresolved findings → fail with directive, all resolved → pass, auto-pass on non-automated-review hosts | `tests/integration/pr-review-resolution-gate.tests.ps1` (new) | 1.5 SP |
| Mirror parity sweep | both mirrors | 0.25 SP |
| CHANGELOG + INDEX update | docs | 0.5 SP |

**Total**: ~7-8 SP. Medium small-fix slice.

**Ship target**: post-v0.24.2 performance bundle, slot AFTER Proposal 088 ships (since 088 establishes the "gate at boundary with directive" pattern this proposal reuses). Targets v0.24.3 or v0.25.0.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 024** (Multi-Host Runtime Abstraction) | This proposal is multi-host-aware from day one. When 024 ships, host detection moves into 024's host abstraction layer; this proposal's detection helper becomes a thin shim. |
| **Proposal 030** (Quality Hardening Bundle) | The root-cause fixes the address-pr-review gate REVEALS (e.g., validator rule for feature.json state, validator rule for plan.md effort math) naturally land in Proposal 030. |
| **Proposal 014** (Red Team Agent) | Adjacent — Red Team is internal adversarial review; address-pr-review is external automated review. Together they form a two-layer review defense. |
| **Proposal 088** (Markdown Lint Pre-Boundary Auto-Fix Discipline) | Same architectural pattern: gate at boundary with clear directive on failure. 088 establishes the pattern; 089 reuses it. |
| **Proposal 045** (CI Watchdog & Recurrence Prevention) | 045 watches for silent CI failures; this proposal catches PR-review feedback specifically. Both are "external signal absorption" gates. |
| **Memory `[[feedback-check-github-copilot-pr-review-2026-05-22]]`** | The per-maintainer discipline; this proposal is the methodology-level enforcement. When 089 ships, the memory becomes redundant — the discipline is mechanical. |

## Acceptance signals

- **AC1**: On a GitHub repo where Copilot is the automated reviewer, `Test-HostProvidesAutomatedPrReview` returns `Active = $true` with `Reviewer = 'copilot-pull-request-reviewer'`. Verified by integration test.
- **AC2**: When PR has Copilot review with findings AND `pr-review-resolution.md` is missing, address-pr-review boundary halts with directive listing unresolved findings. Verified by integration test.
- **AC3**: When PR has Copilot review with findings AND `pr-review-resolution.md` exists and lists every finding with one of {outcome-fix, root-cause-fix, won't-fix}, boundary passes. Verified by integration test.
- **AC4**: When PR has Copilot review and NO findings (rare; clean PR), boundary auto-passes. Verified by integration test.
- **AC5**: On a host without automated review (e.g., a vanilla git remote without Copilot), boundary auto-passes regardless of artifact presence. Verified by integration test.
- **AC6**: `pr-review-resolution.md` artifact survives a feature-closeout sync (it's a per-iteration artifact, not session state). Verified by lifecycle test.
- **AC7**: Mirror parity across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/`.
- **AC8**: Reviewer + Spec Steward charters updated with address-pr-review responsibilities. Verified by methodology-surface verification test (similar to Proposal 082 Tier 1's verification pattern).

## Out of scope

- **Automated response posting**: this proposal records the resolution locally as an artifact; it does NOT automatically reply to Copilot's review comments on GitHub. Maintainer can still leave a manual reply summarizing fixes. Future enhancement (post-089): a `specrew pr resolve --post-summary` CLI that posts a structured summary back to the PR thread.
- **Per-finding AI categorization**: the proposal records findings as the human classified them. It does NOT use an LLM to auto-classify findings as outcome-fix vs root-cause-fix. Human judgment stays in the loop.
- **Auto-fix application**: this proposal does NOT auto-apply Copilot's suggested fixes. Maintainer (or Crew) decides what to change. Auto-fix is a separate future proposal.
- **PR review BEFORE PR-open**: this proposal scopes to review on the EXISTING PR. Pre-PR review (e.g., a local "specrew pr preview" that asks Copilot to review uncommitted work) is out of scope.
- **Cross-PR root-cause aggregation**: e.g., "this CLASS of finding has appeared on the last 3 PRs; promote to a validator rule." That's a Proposal 030 sub-component (form-vs-meaning verification) or a future feature.
- **Self-hosted Copilot or on-prem GitLab AI reviewers**: detection is via host-API; this proposal scopes to public GitHub.com and GitLab.com APIs in v1. Self-hosted variants are a future enhancement (composes with Proposal 024 multi-host).

## Cross-references

- **Empirical motivation**: PR #462 (Feature 030 / Proposal 083) — Copilot's review caught 8 substantive findings on 2026-05-22, all real, all undetected by Specrew automation
- **Memory `[[feedback-check-github-copilot-pr-review-2026-05-22]]`**: per-maintainer discipline that this proposal's methodology gate replaces
- [Proposal 024](024-multi-host-runtime-abstraction.md): host abstraction layer — composes with this proposal's host detection
- [Proposal 030](030-quality-hardening-bundle.md): natural home for the root-cause validator rules that PR reviews surface
- [Proposal 088](088-markdown-lint-pre-boundary-auto-fix-discipline.md): architectural pattern (gate-at-boundary-with-directive) that this proposal reuses
- [Proposal 014](014-red-team-agent.md): internal adversarial review complement
- [Proposal 045](045-ci-watchdog-recurrence-prevention.md): adjacent external-signal-absorption gate
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
