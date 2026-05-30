---
proposal: 148
title: Collision-Aware Feature Selection + File-Surface Conflict Analysis (Layers 2+3 of Multi-Session Coordination)
status: candidate
phase: phase-2
estimated-sp: 20-35
priority-tier: 1
discussion: surfaced 2026-05-30 during F-051 design conversation about multi-developer + multi-session coordination; Layer 1 (basic claim model + same-feature warning) ships in F-051; this proposal extends to file-surface overlap warning (Layer 2) + predictive feature-pair selection (Layer 3)
---

# Collision-Aware Feature Selection + File-Surface Conflict Analysis (Layers 2+3 of Multi-Session Coordination)

## Why

The 2026-05-26 -> 2026-05-30 dogfooding window repeatedly required manual collision-risk analysis when pairing features for concurrent work:

- F-049 + F-050 (parallel-development pilot per Proposal 114 Charter Item 5) — manually picked because they shared minimal file surfaces
- F-051 + Proposal 138 (the first 2-concurrent-Crew pair launching 2026-05-30) — manually analyzed; F-051 touches `scripts/specrew-start.ps1` + Squad infrastructure; Proposal 138 touches Spec-Kit command surface; judged orthogonal

The manual analysis is the right intuition but doesn't scale. Soon-to-be-stressed: N developers × M Crews each = N*M concurrent sessions all potentially fighting over shared files. Multi-dev coordination requires a STRUCTURAL collision-prevention layer, not just human judgment + after-the-fact merge conflict resolution.

## Three-layer coordination model

| Layer | What | Scope | Ship target |
| ----- | ---- | ----- | ----------- |
| Layer 1 | `.squad/active-features.yml` claim file + warn if SAME feature claimed by another session | F-051 minimal scope | F-051 |
| **Layer 2** | **File-surface overlap warning at `specrew start` for new feature** (compare plan `Owner File Globs` to active branches' git-diff surfaces) | **THIS PROPOSAL** | F-054+ |
| **Layer 3** | **Predictive feature-pair selection** (rank N candidates by collision likelihood, recommend safest pair) | **THIS PROPOSAL** | F-054+ |

## Detection mechanism: git-branch-based (NOT Crew-notify)

Decided during design discussion 2026-05-30. Three approaches considered:

| Approach | Pros | Cons |
| -------- | ---- | ---- |
| **A. Git-branch diff** (CHOSEN) | Zero coordination overhead; authoritative (real file edits); works across all hosts; survives Crew crashes; already aggregated on origin | Only sees PUSHED state; file-level granularity only |
| B. Crew-notify central place | Real-time WIP awareness; logical-block info possible | Coordination dependency; per-host implementation overhead; file lock / concurrency issues; breaks "Specrew is a tool, not a service" property |
| C. Hybrid (A primary + B supplemental) | Best of both | Two systems to design; defer |

The "PUSHED state only" limitation is the exact push-discipline gap (`[[project-codex-branch-push-discipline-gap-2026-05-26]]`) being addressed elsewhere; collision-detection becomes another forcing function for the same discipline. Crew-notify is a v2 evolution if file-level proves insufficient.

## Layer 2 design: file-surface overlap warning

Trigger points:

- `specrew start` for a NEW feature
- Plan boundary completion (when plan's `Owner File Globs` is first populated)
- `specrew status --collisions` on-demand

Algorithm:

1. `git fetch --all`
2. List active feature branches: `git branch -r | grep -E 'origin/[0-9]{3}-'`
3. For each: `git diff main..origin/<branch> --name-only` -> file set
4. Build inverse map: file -> list of branches touching it
5. Compare new feature's plan `Owner File Globs` to inverse map
6. Classify overlap: clean / overlap-on-low-risk / overlap-on-high-risk
7. Surface warning with branch attribution + suggested action

Noise filtering via `scripts/internal/collision-detection.yml`:

```yaml
always_excluded_paths:
  - "CHANGELOG.md"
  - ".squad/decisions.md"
  - ".squad/team.md"
  - ".squad/routing.md"
  - "proposals/INDEX.md"
  - "specs/*/iterations/*/dashboard.md"

always_high_risk_paths:
  - "scripts/specrew-start.ps1"
  - "Specrew.psd1"
  - "extensions/specrew-speckit/extension.yml"
  - "scripts/internal/sync-boundary-state.ps1"
  - "extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md"
```

## Layer 3 design: predictive feature-pair selection

Trigger points:

- `specrew where --recommend-next` (when user is deciding what to start next)
- `specrew status --pair-recommend` (when user has 1 in-flight feature and is picking the second)

Algorithm:

1. For each candidate proposal: extract expected file surfaces (from proposal text, OR from past similar features, OR human-annotated `expected_surfaces` field)
2. For each in-flight feature: known file surfaces (from active branches per Layer 2)
3. Compute pairwise collision matrix
4. Score: weight by file count + high-risk-path flags + dependency-on-shared-functions
5. Recommend lowest-risk pair with rationale

Output format (markdown, terminal-friendly):

```text
Concurrent-Pair Recommendations (for in-flight F-051)

LOW COLLISION RISK:
  - Proposal 138 (Spec Kit Underutilized) — touches Spec-Kit command surface; orthogonal to F-051
  - Proposal 146 (Refocus Slash Command) — touches per-host skill catalogs; minor adjacency

MODERATE COLLISION RISK:
  - Proposal 147 (Host Options) — both touch scripts/specrew-start.ps1; merge-resolvable but coordinate

HIGH COLLISION RISK (AVOID):
  - Proposal 134 (Tooling-Version full slice) — overlaps with F-051's session-mode + multi-dev work
```

## Architecture (deliverable shape)

- `scripts/internal/collision-detection.ps1` — core git-branch-diff logic + noise filtering
- `scripts/internal/collision-detection.yml` — `always_excluded_paths` + `always_high_risk_paths` config
- `specrew start --check-collisions` flag (default-on; skip with `--no-check-collisions`)
- `specrew status --collisions` (on-demand surface)
- `specrew where --recommend-next` (Layer 3 surface)
- Coordinator-governance rule: warn at plan-boundary completion when overlap detected

## Composition map

- F-051 (Multi-Session Foundation) — ships Layer 1 (claim model); prerequisite for Layer 2
- [Proposal 145](145-structured-multi-phase-reviewer.md) (F-052 Multi-Phase Reviewer) — Phase 1 branch hygiene composes with collision-detection
- [Proposal 139](139-multi-agent-subagent-orchestration.md) (F-053 Multi-Agent Subagent) — could split collision-analysis to sub-agents per layer for richer dispatch
- [Proposal 149](149-merge-brief-extraction.md) — sibling cross-dev coordination (this proposal = pre-coordination; 149 = at-merge coordination)
- [Proposal 010](010-multi-developer-reconciliation.md) — parent multi-dev work
- [Proposal 134](134-tooling-version-reconciliation-multi-dev.md) — sibling tooling-version multi-dev

## Sizing + sequencing

**Size: ~20-35 SP, single-iteration or 2-iteration split**

| Work | SP estimate |
| ---- | ----------- |
| Layer 2: file-surface overlap warning + integration at start/plan boundary | ~5-10 SP |
| Layer 3: predictive scoring + recommendation surface | ~10-20 SP |
| Noise filtering config (always_excluded/high_risk) | ~1-2 SP |
| Tests (collision scenarios + multi-branch fixtures) | ~3 SP |
| Docs | ~1 SP |

**Sequencing:** F-054 or later candidate. Multi-Agent Subagent (F-053) enables per-layer sub-agent dispatch; Multi-Phase Reviewer (F-052) provides branch-hygiene context that collision-detection augments. Could ship parallel to or after Proposal 149 (Merge Brief).

## Open questions

- Where do expected file surfaces for CANDIDATE proposals come from? Auto-extract from proposal text (heuristic), human-curated `expected_surfaces` field in proposal frontmatter, or learned from past-similar-feature patterns?
- How often should Layer 2 re-evaluate? On every `specrew start`, or only at plan-boundary completion?
- Line-level analysis: when to add? Trigger when same file flagged 3+ times in 30 days as collision point?
- Cross-host adapter: does Crew-notify ever ship (v2), or is git-branch always sufficient?
- Function-level analysis: `git log -L:function:file` already exists; surface it in Layer 2 output for high-risk paths?

## Risks

- **False positives:** noise filtering miscategorizes; user fatigue from too many warnings -> ignored. Mitigate via tunable noise lists + per-project overrides.
- **False negatives:** semantic collisions (two devs editing different functions in same file that conceptually conflict) not caught by file-level analysis. Mitigate via Layer 3 high-risk-path emphasis + cross-dev merge brief (Proposal 149) as second-line defense.
- **Stale branch noise:** old unmerged feature branches inflate collision warnings. Mitigate via branch-age filter (default: only consider branches with commits in last 30 days).
- **Push-discipline dependency:** invisible to Layer 2 if devs don't push. Tied to broader push-discipline methodology work (Proposal 082 Tiers 2+3, F-051 multi-session collision detection at lock-file level).
