---
proposal: 149
title: Merge-Brief Extraction Surface + Commit-Discipline Boost (Cross-Dev Coordination Artifacts from Existing Intent)
status: candidate
phase: phase-2
estimated-sp: 10-17
priority-tier: 1
discussion: surfaced 2026-05-30 during F-051 design conversation about whether per-edit logs are needed for cross-dev merge coordination; conclusion is NO — existing artifacts already capture intent; what's missing is EXTRACTION + DISCIPLINE, not new capture
---

# Merge-Brief Extraction Surface + Commit-Discipline Boost (Cross-Dev Coordination Artifacts from Existing Intent)

## Why

Cross-developer merge conversations are real: when two devs are about to merge work, they verbally exchange intent ("what did you change in `Get-X`, and why?") to build shared mental model BEFORE the technical merge. Git diff shows WHAT changed but not WHY.

Design discussion 2026-05-30 surfaced the question: "do we keep a record of changes + reasons when editing files, so not just use git diff?"

### The wrong answer: per-edit log

Adding a per-edit log mechanism (every file modification writes `file + timestamp + reason + function_or_block` to a central log) is tempting but wrong:

- **Goodhart's law:** agent will produce shallow rationales to satisfy the log requirement
- **Wrong granularity:** edit-level is too noisy (thousands of edits per feature); commit-level is the right unit of intent
- **Heavy infrastructure:** every Crew × every host × every IDE context needs the mechanism; single-Crew-doesn't-write-log = blindspot
- **Storage explosion:** large features generate tens of thousands of edits; log dwarfs the code
- **Existing artifacts already capture intent at the right granularity** — the gap is EXTRACTION not new CAPTURE

### What Specrew already captures (intent-wise)

| Layer | Artifact | What it captures |
| ----- | -------- | ---------------- |
| Feature | `spec.md` | Why this feature exists |
| Plan | `plan.md`, `tasks.md` | Task decomposition + FR traceability + file-glob ownership |
| Iteration | `state.md`, `drift-log.md`, `retro.md` | Phase state + spec/plan drift events + lessons |
| Team | `.squad/decisions.md` | Decisions worth team-wide visibility |
| Boundary | `review.md` | Per-task verdicts + provenance |
| Code | `code-map.md` | Files touched per iteration |
| Commit | commit message | Semantic intent per commit |
| Cross-deps | `dependency-report.md` | What deps added + why |

Substantial intent coverage. The gap is the EXTERNAL-FACING EXTRACTION for cross-dev conversations.

## Three pillars

### Pillar A — Commit-message "Why" discipline (~1-2 SP)

Coordinator-governance rule: every implementer commit message includes a one-line "Why" beyond the imperative summary. Standardized format:

```text
boundary(implement): T012 add session-mode dispatch

Why: F-051 multi-session foundation requires mode flag at launch time so the
auto-detection recommendation surface can read the user's explicit preference
before applying detection signals.
```

Already partially enforced via semantic commit groups (Implementer charter). Tighten via:

- Reviewer Phase 2/4 ([Proposal 145](145-structured-multi-phase-reviewer.md) F-052) checks commit-message quality as part of review-signoff
- `specrew status --merge-ready` precheck (Pillar C) verifies all commits in the in-flight range have Why lines
- Coordinator-governance prompt rule reinforces format expectation

Methodology-only delivery; minimal code change.

### Pillar B — `specrew merge-brief` command (~5-10 SP)

Pure extraction. Aggregates existing artifacts into structured markdown for PR descriptions, Slack, or dev-to-dev conversation:

```powershell
specrew merge-brief --against main
```

Output format:

```markdown
# Merge Brief: <feature> -> main

## What this feature does (1 paragraph)
<extracted from spec.md "Why" section>

## Files touched + why (grouped by feature concern)
- scripts/specrew-start.ps1 - added --session-mode flag handling (T003)
  Recent commits in this file:
  - 4a2b1c3: "boundary(implement): add session-mode dispatch"
    Why: F-051 multi-session foundation requires mode flag at launch time
  - 7d3e5f1: "fix: edge case when mode=auto and lock-file stale"
    Why: empirical test surfaced stale-lock false positive

## Decisions worth flagging
<from .squad/decisions.md filtered to this feature>

## Drift events resolved
<from drift-log.md with classification>

## Known follow-ups / incomplete work
<from retro.md + tasks.md status=deferred>

## Cross-cutting touches (heads-up for other devs)
<files touched outside this feature's plan owner_file_globs, with why-line per file>

## Function-level highlights
<git log -L for top-3 most-modified functions, with commit messages>
```

Implementation: pure git + file reads. No external services. Local + cheap.

### Pillar C — `specrew status --merge-ready` precheck (~3-5 SP)

Before opening a PR, dev runs:

```powershell
specrew status --merge-ready
```

Specrew checks:

- All commits have "Why" lines? (quality gate)
- All drift events have resolution classification?
- All planned tasks have status=done OR status=deferred with retro action?
- No uncommitted WIP?
- Any cross-cutting touches outside plan owner_file_globs?

Surfaces issues at the dev's keyboard BEFORE the colleague's review burden.

## Function-level history is FREE from git

The question about line-range / class / function granularity is solved without new infrastructure:

```powershell
git log -L:Get-SpecrewHostLaunchInvocation:scripts/specrew-start.ps1 origin/main..HEAD
```

Shows every commit that touched that function. `merge-brief` automatically surfaces top-3 most-modified functions per file. No edit-log required.

## Architecture (deliverable shape)

- `scripts/specrew-merge-brief.ps1` — Pillar B extraction engine
- `scripts/internal/merge-readiness-check.ps1` — Pillar C precheck rules
- `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` — Pillar A rule (Why-line in commits)
- `extensions/specrew-speckit/squad-templates/agents/implementer/charter.md` — commit-message format guidance
- Optional: `scripts/internal/function-level-history.ps1` — wrapper around `git log -L` for top-N most-modified functions

## Composition map

- [Proposal 145](145-structured-multi-phase-reviewer.md) (F-052 Multi-Phase Reviewer) — Phase 2/4 enforces commit-message quality discipline (Pillar A)
- [Proposal 139](139-multi-agent-subagent-orchestration.md) (F-053 Multi-Agent Subagent) — sub-agent per merge-brief section enables richer extraction (decisions subagent / cross-cutting analysis subagent / etc.)
- [Proposal 148](148-collision-aware-feature-selection.md) — sibling cross-dev coordination (148 = pre-coordination; 149 = at-merge coordination)
- [Proposal 010](010-multi-developer-reconciliation.md) — parent multi-dev work
- [Proposal 074](074-code-commentary-standards.md) — commit-message standards overlap with code commentary standards

## Sizing + sequencing

**Size: ~10-17 SP, single-iteration small-fix slice candidate OR feature-scale**

| Pillar | SP |
| ------ | -- |
| Pillar A: commit-discipline (methodology + F-052 enforcement) | ~1-2 |
| Pillar B: `specrew merge-brief` command | ~5-10 |
| Pillar C: `specrew status --merge-ready` precheck | ~3-5 |

**Sequencing:** post-F-053. Could ship in either order with Proposal 148 (no hard dependency); both are cross-dev coordination work. Pillar A can ship as F-052 inclusion (no separate slice needed); Pillars B+C ship as a small-fix slice or paired feature.

## Open questions

- Merge-brief output format: markdown only, or also Slack-mrkdwn / GitHub-PR-template formats?
- Caching strategy: re-run from scratch each invocation, or cache per-iteration?
- Cross-cutting touches detection: based on plan owner_file_globs + actual git-diff intersection, or also include "files touched in this branch that NO planned task owns"?
- Pillar A enforcement strength: hard-block boundary on missing Why lines, or soft warning?
- Top-3-functions heuristic: by commit count, by line-change count, by both?
- Integration with PR description auto-population: `gh pr create --body "$(specrew merge-brief --format pr)"` convention?

## Risks

- **Extraction quality depends on capture quality.** If commit messages are weak, merge-brief is weak. Pillar A is the input-quality forcing function.
- **Goodhart's law on commit messages.** If Pillar A enforcement is mechanical (regex for "Why:"), agents will write shallow Whys. Mitigate via Reviewer Phase 4 (Proposal 145) checking commit-message MEANING, not just presence.
- **Brief becomes too long for large features.** Default: summarize per-section to N items; full output with `--verbose`.
- **Cross-platform git command differences:** `git log -L` behavior varies across versions; pin to git >= 2.30.
- **Stale extraction:** if dev runs merge-brief mid-iteration before all artifacts are populated, output is incomplete. Mitigate via Pillar C precheck warning "incomplete state: <reasons>".

## Philosophical anchor

The right framing isn't "force more data capture" — it's "make the existing data conversational." Merge-brief is a STRUCTURED CONVERSATION OPENER between developers, much closer to how humans actually coordinate than a wall of diffs would be. Per-edit logging would optimize for the wrong thing (audit completeness) at the expense of the right thing (clear inter-human handoff).
