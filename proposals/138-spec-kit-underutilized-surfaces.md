---
proposal: 138
title: Spec Kit Underutilized Surfaces — /speckit.checklist + /speckit.analyze + (optional) /speckit.taskstoissues Activation Bundle
status: candidate
phase: phase-2
estimated-sp: 8-15
priority-tier: 2
discussion: surfaced 2026-05-27 during F-049 iter-3 planning conversation. Audit of `file:///C:/Dev/Specrew/.specify/extensions.yml` + agent definitions in `.github/agents/speckit.*.agent.md` revealed Specrew uses 5 of 9 Spec Kit commands (specify, clarify, plan, tasks, implement) + hooks before/after each. The 4 unused commands (constitution, analyze, checklist, taskstoissues) have varying value — checklist + analyze provide capabilities Specrew's validator does NOT cover (requirements-writing quality + vague-adjective/placeholder/terminology-drift detection); taskstoissues is niche; constitution is replaced by Specrew's own .specrew/constitution.md discipline.
---

# Spec Kit Underutilized Surfaces — Activation Bundle

## Why

Audit of Spec Kit surface area (2026-05-27) revealed Specrew uses 5 of 9 Spec Kit commands actively (specify, clarify, plan, tasks, implement) + hooks before/after each. The remaining 4 commands have varying value:

| Spec Kit Command | Currently Used? | Value If Activated |
|---|---|---|
| `/speckit.constitution` | No — Specrew uses `.specrew/constitution.md` directly | Low — we manage constitution outside Spec Kit's command surface |
| `/speckit.analyze` | No — Specrew uses `validate-governance.ps1` | **Medium-High** — covers vague-adjective + placeholder + terminology-drift detection that our validator does NOT |
| `/speckit.checklist` | No — no equivalent | **High** — "unit tests for English"; requirements-writing quality validator we do NOT have anywhere |
| `/speckit.taskstoissues` | No — Specrew uses `tasks.md` directly | Low-Medium niche — useful for external visibility (GitHub issues integration); composes with Proposal 089 + Proposal 010 |

This proposal activates the high-value commands (`checklist`, `analyze`) as lifecycle gates + offers the niche command (`taskstoissues`) as opt-in. Documents the decision to skip `constitution` with explicit rationale.

### Big miss: `/speckit.checklist` — "Unit Tests for English"

Per `file:///C:/Dev/Specrew/.github/agents/speckit.checklist.agent.md`: "Checklists are **UNIT TESTS FOR REQUIREMENTS WRITING** — they validate the quality, clarity, and completeness of requirements in a given domain."

Concrete examples of what `/speckit.checklist` validates:

- "Are visual hierarchy requirements defined for all card types?" (completeness)
- "Is 'prominent display' quantified with specific sizing/positioning?" (clarity)
- "Are hover state requirements consistent across all interactive elements?" (consistency)
- "Are accessibility requirements defined for keyboard navigation?" (coverage)
- "Does the spec define what happens when logo image fails to load?" (edge cases)

Explicitly NOT for implementation/testing verification ("verify the button clicks correctly" is OUT of scope).

**This directly fills a gap our validator doesn't cover.** `validate-governance.ps1` checks STRUCTURAL quality (FR-IDs present, TG mapping complete, capacity arithmetic, mirror parity, boundary state). It does NOT check REQUIREMENTS-WRITING quality (is "fast" quantified? does the spec define logo-load-failure behavior? are hover states consistent?). `/speckit.checklist` generates a per-feature, **domain-aware custom checklist** that catches exactly this class of issue.

### Valuable overlap: `/speckit.analyze`

Per `file:///C:/Dev/Specrew/.github/agents/speckit.analyze.agent.md`: "non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation."

We have `validate-governance.ps1` (broader, stricter), but `/speckit.analyze` catches things our validator does NOT:

| Detection | `validate-governance.ps1` | `/speckit.analyze` |
|---|---|---|
| FR coverage / TG mapping | ✓ | ✓ |
| Capacity arithmetic | ✓ | ✗ |
| Mirror parity | ✓ | ✗ |
| Boundary state | ✓ | ✗ |
| Slice-type catalog enforcement | ✓ | ✗ |
| **Vague adjectives** ("fast", "scalable", "secure" without measurable criteria) | ✗ | ✓ |
| **Unresolved placeholders** (TODO, TKTK, ???, `<placeholder>`) | ✗ | ✓ |
| **Terminology drift** (same concept named differently across files) | ✗ | ✓ |
| **Coverage % calculation** (requirements with zero tasks; tasks with no requirement) | partial | ✓ |
| **Conflicting requirements** (one says Next.js, another says Vue) | ✗ | ✓ |
| Data entities in plan but absent in spec (or vice versa) | ✗ | ✓ |

These are **complementary, not substitutes**. `/speckit.analyze` is read-only and can run as an **additional check before implement** — composes with Specrew's `before-implement` boundary without conflict.

### Niche: `/speckit.taskstoissues`

Per `file:///C:/Dev/Specrew/.github/agents/speckit.taskstoissues.agent.md`: "Convert existing tasks into actionable, dependency-ordered GitHub issues for the feature based on available design artifacts."

We don't use GitHub issues as a tracking surface; `tasks.md` IS the tracker. But this could matter for:

- External tester visibility into Specrew progress (Proposal 010 multi-developer story territory)
- Issue-tracker-driven workflows in downstream projects
- Composing with Proposal 089 (PR Review Integration) — issues + PRs form a complete review surface

Skip from default lifecycle; offer as opt-in for projects that use GitHub issues for tracking.

### Skip with rationale: `/speckit.constitution`

Specrew has its own constitution at `file:///C:/Dev/Specrew/.specrew/constitution.md` with established editing discipline. Spec Kit's `/speckit.constitution` provides interactive template-driven editing with placeholder substitution + propagation to dependent artifacts. The features overlap; our discipline is more mature for our domain. Documented decision: skip from default lifecycle.

## What — Four Pillars

### Pillar 1: Activate `/speckit.checklist` as quality gate (~3-5 SP)

Position: ideally at **design-analysis boundary** (per Proposal 137) OR at **clarify completion** (if 137 hasn't shipped yet). Composes naturally with either.

Mechanism: hook `before_plan` (or `before_design_analysis` if 137 ships first) gains an entry that prompts the user to optionally run `/speckit.checklist` against the spec; Crew generates per-feature custom checklist; surfaces issues; user addresses critical ones before proceeding.

Specrew adds:

- `extensions/specrew-speckit/scripts/specrew-speckit.checklist-integration.ps1` (mirrored to `.specify/extensions/`)
- Hook entry in `.specify/extensions.yml`:

  ```yaml
  before_plan:
    - extension: specrew-speckit
      command: speckit.checklist
      enabled: true
      optional: true
      prompt: "Generate requirements-quality checklist before planning?"
      description: "Validate spec requirements writing quality (vague adjectives, completeness, edge cases)"
      condition: null
  ```

- Slice-type-aware: optional for chore/small-fix/bug-fix/doc-only; recommended for substantive slices per Proposal 055 catalog

Checklist output lands at `specs/<F>/checklist.md` (or `specs/<F>/iterations/<NNN>/checklist.md` if iteration-scoped). Findings categorized by severity (CRITICAL / HIGH / MEDIUM / LOW); CRITICAL issues block boundary advancement; HIGH/MEDIUM surface as warnings; LOW informational.

Composes with Proposal 088 (markdown lint pre-boundary) — lint catches markdown-structure issues; checklist catches requirements-writing-quality issues; orthogonal but both feed the same "quality before boundary" model.

### Pillar 2: Activate `/speckit.analyze` as additive before-implement check (~2-4 SP)

Position: at Specrew's `before-implement` boundary. Composes with `validate-governance.ps1` — runs AFTER our validator passes; catches the qualitative-quality issues our validator doesn't.

Mechanism: hook `before_implement` gains an entry:

```yaml
before_implement:
  - extension: specrew-speckit
    command: speckit.analyze
    enabled: true
    optional: false
    prompt: "Execute cross-artifact consistency analysis?"
    description: "Detect vague adjectives, placeholders, terminology drift, coverage gaps across spec/plan/tasks"
    condition: null
```

Findings recorded at `specs/<F>/iterations/<NNN>/analyze-findings.md`. CRITICAL findings block before-implement boundary; HIGH surface as warnings requiring acknowledgment; MEDIUM/LOW informational.

Specrew's `validate-governance.ps1` remains the primary structural validator; `/speckit.analyze` is the additive quality layer. Both must pass for `before-implement` verdict.

### Pillar 3: Optional `/speckit.taskstoissues` opt-in (~2-3 SP)

Position: post-`tasks` boundary, opt-in per project configuration.

Mechanism: new section in `.specrew/config.yml`:

```yaml
github_issues_integration:
  enabled: false  # default false; opt-in per project
  default_labels: ["specrew", "auto-generated"]
  default_assignee: ""  # optional
  parent_issue_per_feature: true  # creates one parent issue per F-NNN + sub-issues per task
```

When `enabled: true`, Specrew adds `after_tasks` hook:

```yaml
after_tasks:
  - extension: specrew-speckit
    command: speckit.taskstoissues
    enabled: true  # gated by config
    optional: true
    prompt: "Sync tasks to GitHub issues?"
    description: "Convert tasks.md to dependency-ordered GitHub issues for external visibility"
    condition: github_issues_integration.enabled
```

Composes with:

- Proposal 089 (PR Review Integration) — issues complete the review surface picture (issues for tracking + PRs for review + merge)
- Proposal 010 (Multi-Developer Reconciliation) — issues are the natural coordination surface for multi-dev work
- Proposal 127 (Git-Host Adapter Layer) — taskstoissues should be git-host-agnostic via adapter; GitHub-specific impl ships first, GitLab/Bitbucket as follow-up

Per-project opt-in keeps the default lifecycle clean; downstream projects that want GitHub-issue tracking can enable it without forcing it on everyone.

### Pillar 4: Skip `/speckit.constitution` with documented rationale (~1 SP)

Add to `docs/user-guide.md` (or new `docs/spec-kit-integration.md`) explicit documentation:

> **Spec Kit `/speckit.constitution` is not integrated into Specrew's default lifecycle.** Specrew uses `.specrew/constitution.md` directly with its own editing discipline (commit-driven updates, validator enforcement of constitution principles, propagation through governance scripts). The overlap with Spec Kit's interactive template-driven editing is recognized; the decision to maintain Specrew's own discipline is deliberate.
>
> Downstream projects MAY use `/speckit.constitution` for ad-hoc constitution updates if preferred; the command remains available since it's part of Spec Kit's base install. Specrew's `validate-governance.ps1` will not interfere with constitutions edited via either path.

Documentation captures the deliberate skip so future maintainers don't re-litigate the question.

## How

Single-iteration feature (recommended) OR small bundle of 2 iterations:

| Iter | Scope | SP |
|---|---|---|
| 1 (recommended single iter) | All 4 pillars: checklist activation + analyze activation + taskstoissues opt-in + constitution skip documentation | 8-15 |

Alternative split if scope feels tight:

| Iter | Scope | SP |
|---|---|---|
| 1 | Pillars 1+2: checklist + analyze activation (high-value gates) | 5-9 |
| 2 | Pillars 3+4: taskstoissues opt-in + constitution skip documentation | 3-6 |

Single-iteration recommended because the work is structurally homogeneous (extensions.yml hook additions + scripts + docs) and small.

## Acceptance criteria

- **AC1**: `before_plan` (or `before_design_analysis` if Proposal 137 ships first) hook added invoking `/speckit.checklist` (optional, slice-type-aware applicability)
- **AC2**: `/speckit.checklist` output lands at `specs/<F>/checklist.md` or per-iteration equivalent; severity-categorized findings; CRITICAL blocks boundary advance
- **AC3**: `before_implement` hook added invoking `/speckit.analyze` (mandatory; complements `validate-governance.ps1`)
- **AC4**: `/speckit.analyze` output lands at `specs/<F>/iterations/<NNN>/analyze-findings.md`; CRITICAL blocks before-implement verdict
- **AC5**: `.specrew/config.yml` gains `github_issues_integration` section with `enabled: false` default
- **AC6**: When `github_issues_integration.enabled: true`, `after_tasks` hook invokes `/speckit.taskstoissues`; per-feature parent issue + per-task child issues created with configured labels + assignees
- **AC7**: `docs/user-guide.md` (or `docs/spec-kit-integration.md`) documents the deliberate skip of `/speckit.constitution` with rationale
- **AC8**: All Specrew validator rules + lifecycle behavior continue working unchanged (additive activation; no regression)
- **AC9**: Integration tests cover checklist generation + analyze findings parsing + taskstoissues invocation (with mocked GitHub API) + constitution-skip behavior preserved
- **AC10**: Mirror parity preserved across `extensions/specrew-speckit/scripts/` ↔ `.specify/extensions/specrew-speckit/scripts/`

## Out of scope

- **Replacing `validate-governance.ps1`** — `/speckit.analyze` is additive; our validator remains the primary structural check
- **Rewriting `/speckit.checklist` or `/speckit.analyze` agent definitions** — use Spec Kit's existing definitions as-is; Specrew adds lifecycle integration only
- **Cross-host slash-command deployment of checklist/analyze** — these are Spec Kit commands; they ship via Spec Kit's existing surface; not part of F-021 multi-host slash-command machinery
- **`/speckit.taskstoissues` cross-host issue tracker support** (Linear, Jira, etc.) — GitHub-only for v1; cross-host issue trackers compose with Proposal 101 (External Tracker Sync Provider) and Proposal 127 (Git-Host Adapter Layer)
- **Re-enabling `/speckit.constitution`** — skip is deliberate per Pillar 4 rationale; future re-evaluation possible but not in this proposal's scope

## Composition

| Proposal | Relationship |
|---|---|
| **Proposal 137 (Design Alternatives Analysis Gate)** | Direct synergy — Pillar 1 checklist hook fits cleanly at design-analysis boundary if 137 ships; or at `before_plan` if 137 hasn't shipped yet. Sequencing-flexible composition |
| **Proposal 088 (Markdown Lint Pre-Boundary)** | Orthogonal — lint catches markdown-structure issues; checklist catches requirements-writing-quality issues; both feed same "quality before boundary" model |
| **Proposal 030 (Quality Hardening Bundle)** | Natural absorption target — 030 already addresses form-vs-meaning quality; this proposal could fold into 030 as a sub-pillar. Standalone version proposed here for clarity; bundle absorption decision deferred |
| **Proposal 089 (PR Review Integration)** | Direct composer for Pillar 3 — issues complete the review surface (issues for tracking + PRs for review + merge) |
| **Proposal 010 (Multi-Developer Reconciliation)** | Direct composer for Pillar 3 — issues are the natural coordination surface for multi-dev work |
| **Proposal 127 (Git-Host Adapter Layer)** | Direct composer for Pillar 3 — taskstoissues should ultimately be git-host-agnostic via adapter; GitHub-only v1; GitLab/Bitbucket follow-up |
| **Proposal 101 (External Tracker Sync Provider)** | Sibling to Pillar 3 — taskstoissues is GitHub-issue-specific; 101 abstracts to Linear/Jira/etc. as additional providers |
| **Proposal 055 (Slice-Type Catalog)** | Applicability driver — slice-type catalog determines which slices trigger checklist (substantive: yes; chore/small-fix/bug-fix/doc-only: optional) |
| **Proposal 039 (Squad Upstream Reconciliation)** | Strategic — this proposal is Specrew INTERNALIZING more of Spec Kit's surface area; demonstrates active use of Spec Kit's mature features rather than reinventing. Useful framing for upstream conversation with Brady Gaster |
| **Memory `[[reference-brady-gaster-squad-inventor-2026-05-25]]`** | Strategic channel — proposing 138 shows Specrew actively dogfooding Spec Kit's full surface, which strengthens the upstream-contribution narrative for Proposal 137 |

## Strategic upside

Activating these surfaces demonstrates **Specrew actively uses Spec Kit's mature features rather than reinventing them**. That's directly valuable for Brady Gaster channel per `[[reference-brady-gaster-squad-inventor-2026-05-25]]`:

- Strengthens the "Specrew is a nice evolution of spec-kit" narrative Brady already accepts
- Reduces NIH-syndrome perception risk in upstream conversation
- Provides concrete examples of "we use your `/speckit.checklist` for X" + "we use your `/speckit.analyze` for Y" that make Spec Kit team's investment visible in Specrew's lifecycle

Bundles naturally with Proposal 137 upstream-contribution narrative — together they say "we use your full surface AND we contribute design-alternatives gate back."

## Risks

- **Checklist generation overhead** — `/speckit.checklist` may produce noisy or overly-broad checklists for trivial features. Mitigation: slice-type-aware applicability (Pillar 1) makes checklist optional for trivial slices; substantive slices get the gate
- **Analyze findings overlap with our validator** — risk of duplicate findings cluttering output. Mitigation: AC4 specifies severity-aware boundary behavior; our validator stays primary structural check; analyze fills the qualitative gap
- **GitHub issues sync drift** — issues created via Pillar 3 may drift from `tasks.md` over time. Mitigation: opt-in only; downstream projects choose to enable; sync is one-way (tasks → issues) with manual reconciliation guidance
- **Constitution skip ambiguity** — future contributors may not know constitution.md is the source of truth vs `/speckit.constitution`. Mitigation: Pillar 4 documentation; validator surfacing
- **Spec Kit version drift** — `/speckit.checklist` and `/speckit.analyze` agent definitions may change in upstream Spec Kit releases. Mitigation: pin Spec Kit version in `.specify/extensions.yml`; integration tests cover the version pinned; upgrade path explicit

## Acceptance signals (operational)

- **Signal 1**: Spec quality issues caught at boundary via checklist (vs caught at review or post-implementation) — measure CRITICAL+HIGH findings rate; expect material catches in early adopters
- **Signal 2**: `/speckit.analyze` findings at before-implement boundary catch ≥1 issue per 5 features on average (vague adjectives, terminology drift, coverage gaps)
- **Signal 3**: Downstream projects with `github_issues_integration.enabled: true` report improved external visibility / multi-dev coordination
- **Signal 4**: Upstream Spec Kit conversation includes Specrew use cases for `/speckit.checklist` + `/speckit.analyze` as evidence of mature adoption

## Status history

- 2026-05-27: candidate proposal drafted after Spec Kit surface audit during F-049 iter-3 planning. Audit revealed Specrew uses 5 of 9 commands actively; 4 unused commands evaluated for activation value. High-value: checklist + analyze (capability gaps our validator doesn't cover). Niche: taskstoissues (opt-in for GitHub-issue-driven projects). Skip: constitution (own discipline mature). Four pillars; single-iteration or 2-iteration split; 8-15 SP.

## Cross-references

- **Empirical motivation**: 2026-05-27 Spec Kit surface audit during F-049 iter-3 planning conversation
- file:///C:/Dev/Specrew/.github/agents/speckit.checklist.agent.md — Pillar 1 source
- file:///C:/Dev/Specrew/.github/agents/speckit.analyze.agent.md — Pillar 2 source
- file:///C:/Dev/Specrew/.github/agents/speckit.taskstoissues.agent.md — Pillar 3 source
- file:///C:/Dev/Specrew/.github/agents/speckit.constitution.agent.md — Pillar 4 documented skip
- file:///C:/Dev/Specrew/.specify/extensions.yml — hook integration target
- file:///C:/Dev/Specrew/.specrew/constitution.md — Specrew's own constitution surface (Pillar 4 rationale)
- file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/validate-governance.ps1 — primary structural validator (analyze is additive)
- file:///C:/Dev/Specrew/proposals/137-design-alternatives-analysis-gate.md — direct synergy (Pillar 1 hook position)
- file:///C:/Dev/Specrew/proposals/088-markdown-lint-pre-boundary-auto-fix-discipline.md — orthogonal quality gate
- file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md — natural absorption target
- file:///C:/Dev/Specrew/proposals/089-pr-review-integration-address-pr-review-gate.md — direct composer for Pillar 3
- file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md — direct composer for Pillar 3
- file:///C:/Dev/Specrew/proposals/127-git-host-adapter-layer.md — git-host-agnostic taskstoissues
- file:///C:/Dev/Specrew/proposals/101-external-tracker-sync-provider.md — sibling cross-tracker abstraction
- file:///C:/Dev/Specrew/proposals/055-always-in-flow-bug-fix-lifecycle.md — slice-type applicability driver
- file:///C:/Dev/Specrew/proposals/039-squad-upstream-reconciliation.md — Spec Kit upstream-contribution pattern
- Memory: [[reference-brady-gaster-squad-inventor-2026-05-25]] (strategic upstream channel)
- Spec Kit upstream verification: `file:///C:/Dev/Specrew/.specify/extensions.yml` shows hook surface area; `.github/agents/speckit.*.agent.md` files show command definitions; audit performed 2026-05-27
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
