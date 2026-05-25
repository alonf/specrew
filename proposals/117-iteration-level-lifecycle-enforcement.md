---
proposal: 117
title: Iteration-Level Lifecycle Enforcement — Populated state.md/review.md/retro.md Per Iteration Directory
status: candidate
phase: phase-2
estimated-sp: 10-15
priority-tier: 1
type: methodology+tooling
discussion: tbd
depends-on:
  - 073 # Review Evidence Integrity (shipped F-028) — provides form-vs-meaning gate this proposal extends to iteration-level
composes-with:
  - 030 # Quality Hardening Bundle (Form-vs-Meaning Verification)
  - 088 # Markdown Lint Pre-Boundary Auto-Fix Discipline
  - 113 # Empirical User-Acceptance Gate (review.md must contain Acceptance Evidence — this proposal enforces review.md is populated at all)
  - 112 # Quality-Tier Routing Bundle (Pillar 2 Runtime Verification — review.md must contain runtime evidence)
blocks: []
audience: methodology
---

# Iteration-Level Lifecycle Enforcement — Populated state.md/review.md/retro.md Per Iteration Directory

## Why

The 2026-05-25 dice-projects re-audit (5 projects across 4 hosts with the AntigravityStrong stronger-model data point added) revealed a **universal gap that affects every host**, not host-specific behavior:

> All 5 projects had EMPTY `specs/<NNN>-<slug>/iterations/<III>/` directories — none populated `state.md`, `review.md`, or `retro.md` per iteration. All projects are single-iteration (001 only).

This is striking because it's not a quality difference between hosts — it's a Specrew-wide enforcement gap. The methodology layer creates the iteration directory scaffold via `scaffold-reviewer-artifacts.ps1` and similar machinery, but **doesn't enforce that the scaffolded artifacts get populated with meaningful content before boundaries advance**.

Today's behavior:

- Validator checks for FILE EXISTENCE of iteration artifacts at certain boundaries
- Validator does NOT check that the files contain populated content (only the form-vs-meaning gate in Proposal 073 partially covers this, and only for specific commit-evidence cases)
- A host's autopilot can scaffold the directory + skip the iteration ceremony entirely + still reach feature-closeout

The empirical consequence: every dice project shows iteration directories that exist on disk but have no `state.md` tracking iteration phase, no `review.md` with reviewer sign-off, no `retro.md` with lessons. The audit-trail surface is structurally present but informationally empty.

### Specific gap pattern observed across all 5 hosts

For each of `Antigravity-dice`, `AntigravityStong-dice`, `Claude-dice`, `Codex-dice`, `Copilot-dice`:

| Iteration artifact | Expected per Specrew lifecycle | Observed in dice audit |
|---|---|---|
| `iterations/001/state.md` | Phase markers (specify → clarify → plan → tasks → implement → review-signoff → retro → closeout) | Empty or absent |
| `iterations/001/review.md` | Reviewer sign-off + form-vs-meaning verdict + Acceptance Evidence (per Proposal 113) | Empty or absent |
| `iterations/001/retro.md` | Lessons + trap-reapplication + corpus updates | Empty or absent |
| `iterations/001/code-map.md` | File-by-file change attribution (per Proposal 073) | Empty or absent (where present) |
| `iterations/001/coverage-evidence.md` | Per-iteration test/coverage tracking | Empty or absent |

The disparity: feature-level artifacts (`spec.md`, `plan.md`, `tasks.md`, `closeout-dashboard.md`) ARE populated in all 5 projects. The iteration-level artifacts are NOT. This pattern suggests:

1. Hosts perceive iteration-ceremony as optional/skippable
2. The methodology's scaffolding creates directories without enforcing content
3. Closeout can proceed without per-iteration sign-off because the validator doesn't gate on populated content

### Why this matters beyond audit completeness

When the dashboard surfaces "iteration 001 closed", it's making a claim that didn't actually happen at the methodology layer. The form-vs-meaning gap (Proposal 030's central concern) is happening at the iteration boundary too, not just at the bigger feature boundary. Compounding effect across longer projects: a 10-iteration feature with empty iteration directories renders a dashboard showing "10 iterations closed cleanly" when the actual sign-off content doesn't exist.

For external testers about to onboard, this would silently mask quality issues. The dashboard would say "all iterations green" while having no actual reviewer-sign-off content backing the claim.

## What — Three Enforcement Layers

### Layer 1: Boundary-Gate Population Validation

At each lifecycle boundary that should produce an iteration artifact, the validator checks that the corresponding file:

- Exists at the canonical path (existing behavior)
- Has populated content beyond the scaffold template (new check)
- Contains the required structured fields populated with non-template values (new check)

Specific gate triggers:

| Boundary | Iteration artifact | Required-populated fields |
|---|---|---|
| `plan` → `tasks` | `iterations/<NNN>/state.md` | `phase: plan-complete`, `last-updated: <ISO-8601 not template default>` |
| `tasks` → `before-implement` | `iterations/<NNN>/state.md` | `phase: tasks-complete`, `task-count: N` (non-zero) |
| `implement` → `review-signoff` | `iterations/<NNN>/state.md` + `iterations/<NNN>/review.md` | `state.md` shows `phase: implement-complete`; `review.md` has populated form-vs-meaning verdict + Acceptance Evidence (per Proposal 113) |
| `review-signoff` → `retro` | `iterations/<NNN>/review.md` | Reviewer sign-off recorded (date, verdict, evidence) |
| `retro` → `iteration-closeout` | `iterations/<NNN>/retro.md` | Lessons section populated (non-empty + non-template) |
| `iteration-closeout` → next | All above | All three artifacts have `closed-at: <ISO-8601>` |

### Layer 2: Template-Default Detection

Scaffold templates contain placeholder text (`<TBD>`, `<populate-this>`, `<reviewer-signature-here>`). The validator detects unfilled placeholders + rejects the boundary advance. Specific patterns to detect:

- Angle-bracket placeholders: `<.*>` (except in code blocks)
- TBD literal: `\bTBD\b` (case-insensitive)
- Empty header sections: `## <header>\n\n##` (no content between adjacent headers)
- Scaffold sentinel comment: `<!-- specrew-scaffold-placeholder -->` (template marker; should be removed when content is populated)

### Layer 3: Audit-Trail Surfacing

`specrew where` + dashboard renderer surface populated-state explicitly:

```text
Feature 045: v0.27.1 patch bundle
  Iteration 001:
    state.md     [✓ populated — phase: review-signoff-complete]
    review.md    [✓ populated — verdict: APPROVE; acceptance-evidence: verified]
    retro.md     [⚠ scaffold-only — lessons section empty]
    code-map.md  [✓ populated]
    
  Iteration 002:
    state.md     [✓ populated]
    review.md    [✗ MISSING — boundary block: cannot enter review-signoff]
```

This makes the gap visible to the user BEFORE they attempt to advance the boundary — turning a hidden form-vs-meaning issue into a surfaced one.

## How — Implementation Surface + Effort

| Component | File | Effort |
|---|---|---|
| Validator population-check rule for state.md per boundary | `extensions/specrew-speckit/scripts/validate-governance.ps1` | 2 SP |
| Validator population-check rule for review.md (composes with 113's Acceptance Evidence requirements) | `extensions/specrew-speckit/scripts/validate-governance.ps1` | 1 SP |
| Validator population-check rule for retro.md | `extensions/specrew-speckit/scripts/validate-governance.ps1` | 1 SP |
| Template-default placeholder detection logic | `extensions/specrew-speckit/scripts/internal/detect-template-defaults.ps1` (new) | 2 SP |
| Boundary-state-sync integration (block boundary on missing population) | `extensions/specrew-speckit/scripts/sync-boundary-state.ps1` (existing) | 1 SP |
| `specrew where` + dashboard renderer iteration-artifact status column | `scripts/internal/dashboard-renderer.ps1` | 1-2 SP |
| Tests with empty-iteration, scaffold-only, half-populated, fully-populated fixtures | `tests/iteration-population-validator.tests.ps1` (new) | 2 SP |
| Documentation + migration guidance for existing projects | `docs/user-guide.md` + migration notes | 1 SP |

**Total estimate**: ~10-15 SP. Single iteration, single feature.

### Phased rollout (mirror Proposal 113's approach)

1. **v0.28.x**: ship validator population check as WARN-level (not blocking). Surfaces gaps without breaking existing in-flight iterations.
2. **v0.29.0**: promote to ERROR-level (blocking). Backwards-incompatible — existing projects need iteration-artifact backfill OR explicit "legacy iteration" marker.
3. **v0.30.0**: surface populated-state in `specrew where` + dashboard renderer first-class.

## Composition Notes

### With Proposal 073 (Review Evidence Integrity — shipped F-028)

073 introduced the form-vs-meaning verdict + pre-review commit gate for review.md SPECIFICALLY. 117 generalizes the same form-vs-meaning lens to ALL iteration-level artifacts (state.md, review.md, retro.md, code-map.md, coverage-evidence.md). Same conceptual lens, broader surface.

### With Proposal 113 (Empirical User-Acceptance Gate)

113 mandates the `Acceptance Evidence` section in review.md. 117 enforces that review.md exists + is populated at all. They compose: 113 says WHAT content review.md must contain at a structural level; 117 says review.md MUST be populated (with 113's required structure) before boundaries advance.

### With Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning Verification)

030 addresses the form-vs-meaning bug class (tests-pass-but-behavior-wrong). 117 addresses the form-vs-meaning bug class at the METHODOLOGY layer (artifact-exists-but-content-empty). They're sibling proposals addressing the same epistemic gap at different abstraction levels.

### With Proposal 088 (Markdown Lint Pre-Boundary Auto-Fix Discipline)

088 added auto-fix for markdown lint errors at boundary-sync. 117 extends boundary-sync with population validation. Both are pre-boundary gates; could share infrastructure.

## Open Questions

1. **How to detect "populated" vs "scaffold" for free-form text sections?** Heuristics: minimum word count per section, absence of template sentinel, presence of section-specific required keywords. Risk: false positives (genuine short content rejected as scaffold). Recommend: start lenient (≥10 words OR explicit sentinel removed) + tune from telemetry.

2. **What about single-iteration features?** If a feature has only iteration 001 + no plans for additional iterations, do we still require state.md tracking implementation phases? Recommend: yes, but allow `feature-closed-in-one-iteration: true` flag in state.md that signals fewer required state transitions.

3. **Backfill for existing projects?** When 117 ships, what about projects with already-empty iteration directories from prior versions? Options: (a) require manual backfill before next feature; (b) auto-backfill from `closeout-dashboard.md` if available; (c) mark as "legacy iteration" + accept the data loss + start enforcement going forward. Recommend (c) for pragmatism.

4. **Iteration artifacts that are genuinely not applicable?** Some iterations may not produce a `code-map.md` (pure-docs iteration, no code changes). Recommend: per-iteration `applicable-artifacts:` declaration at iteration-start; validator checks only declared artifacts. Default: all artifacts applicable unless explicitly opted out.

5. **Host autopilot adversarial behavior?** A host's autopilot could theoretically populate the artifacts with token-cheap text that passes the population check but lacks meaning. Mitigation: 117 plus Proposal 073's form-vs-meaning lens; combined they catch shallow-population attacks. Future work: spec-driven content quality check (Proposal 099 / similar) — out of scope for 117.

## Not in Scope

- Validating SUBSTANTIVE content quality of populated artifacts (Proposal 030 + 073 territory)
- Specific iteration artifact templates (those exist in `extensions/specrew-speckit/squad-templates/`)
- Closeout-dashboard rendering (Proposal 046 + downstream)
- Backfill machinery for existing projects (covered by Proposal 075 from a different angle)
- Cross-iteration consistency checks (Proposal 010 territory)

## Empirical Motivation Captured

- **2026-05-25** — Dice-projects re-audit (5 projects: Antigravity, AntigravityStong, Claude, Codex, Copilot) revealed universal pattern of empty iteration directories. All 5 hosts/host-modes exhibited the gap; not host-specific. Suggests the methodology's scaffold-creation step is decoupled from content-population enforcement, allowing autopilots to skip iteration ceremony entirely.
- **Audit evidence**: see file:///C:/Temp/SpecrewProjectMultipleHost/ across all 5 dice projects. Each shows `specs/<NNN>/iterations/001/` directory with empty or absent state.md/review.md/retro.md while feature-level artifacts (spec.md, plan.md, closeout-dashboard.md) ARE populated.
- **Pattern recognition**: this is form-vs-meaning at a different scale than what Proposal 030 + 073 caught. The artifact's FILE EXISTS (form satisfied); the artifact's CONTENT is absent (meaning unfilled). Identical bug class, different scope.

## Status History

- **2026-05-25** — Drafted from empirical motivation surfaced during dice-projects re-audit (with AntigravityStrong stronger-model data point added). Candidate status. Sequencing recommendation: HIGH PRIORITY — address before significant external-tester onboarding because the gap silently masks quality issues at the dashboard layer.
