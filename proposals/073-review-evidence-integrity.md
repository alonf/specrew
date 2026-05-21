---
proposal: 073
title: Review Evidence Integrity (Pre-Review Commit Gate + Form-vs-Meaning Detection)
status: shipped
shipped-as: feature-028 (2026-05-21)
phase: phase-2
estimated-sp: 15-20
discussion: tbd
---

# Review Evidence Integrity

## Why

The review phase produces evidence artifacts that downstream reviewers (human and agent) rely on to understand what changed in an iteration: `review-diagrams.md`, `code-map.md`, `dependency-report.md`, `coverage-evidence.md`. Today those artifacts are computed via `git diff baseline...HEAD` — which assumes implementation work is committed by the time review runs. **That assumption is not enforced.**

### Empirical evidence (2026-05-21 smoke trial)

A fresh `specrew init` snake-game smoke test on v0.24.1 ran the full lifecycle (specify → clarify → plan → tasks → implement → review) and produced an iteration where:

- `state.md` declared `Status: completed`, `Last Completed Task: T011`, `Tasks Remaining: 0`
- `review.md` recorded 11 task verdicts, all `pass`, with build/test evidence
- Working tree contained 20+ C# files implementing the snake game (visible via `find src tests -name '*.cs'`)
- **`review-diagrams.md` emitted: "Structure diagram omitted: modules touched (0) below threshold (3). Flow diagram omitted: entrypoints changed (0) below threshold (1)."**
- `git log` showed only Squad session-state commits (Scribe agent); none of the implementation files were tracked
- `git status --short` showed every implementation file as `??` (untracked)

This is a textbook **form-vs-meaning gap**:

| Layer | Signal |
|---|---|
| **Form** (declared) | T001-T011 completed; 11/11 task verdicts pass; build + test evidence captured |
| **Meaning** (committed) | `git diff baseline...HEAD` is empty; review-evidence scripts see zero changes |
| **Gap** | The review system silently accepted the form without detecting the meaning. Diagrams omitted with a message ("below threshold") that looks normal but is actually masking an upstream contract violation |

### Why this matters for reviewers

The diagram, code-map, dependency-report, and coverage-evidence artifacts are not decorations — they are how a reviewer understands what the iteration changed. A reviewer (human or agent) seeing empty review-diagrams.md alongside "11 task verdicts pass" gets a structurally false picture: the work looks complete and structurally trivial, when in fact it's substantial work that's just invisible to the evidence pipeline. This is the worst kind of review failure — confident-looking but blind.

### Why this matters for the methodology

Specrew's value proposition is **substantive, evidence-grounded review**. If review evidence is silently empty whenever the implementation phase forgets (or defers) to commit, the entire review boundary loses its load-bearing function. Reviewers approve based on declared verdicts rather than observed reality. This is the form-correct/meaning-blind bug class Proposal 030 (Quality Hardening Bundle) was created to address — and 073 is the first concrete slice with empirical motivation.

## What (5 Pillars)

### Pillar 1: Pre-review commit gate (validator rule)

Add a new validator rule that runs at the implement→review transition (or as part of `before-review` governance gate when 011's checkpoint pattern is generalized):

- Read the iteration task tables (`plan.md` first, `state.md` as legacy fallback) to find declared completed work in the current iteration
- Run `git diff --name-only <baseline_ref>...HEAD` for the iteration
- If iteration artifacts declare one or more tasks completed AND the diff is empty → emit a HARD validation failure with category `review-evidence-integrity` and severity `error`
- Failure message must include the baseline ref and a remediation hint: "Implementation tasks were marked complete but no files have been committed since the baseline. Commit the implementation work before review can produce meaningful evidence."

This gate composes with the existing validator hardening (Proposal 004) and runs at the same governance plane.

### Pillar 2: Form-vs-meaning detection rule (broader)

Generalize Pillar 1 into a reusable form-vs-meaning helper that can be invoked from multiple validator rules:

- `Test-FormMeaningParity` (or similar) compares declared state against observed git diff
- Initial use: pre-review commit gate (Pillar 1)
- Follow-on uses: any future validator rule that needs to verify declared completion matches observed reality
- Returns a structured result: `{ Declared: <count>, Observed: <count>, Gap: <bool>, Severity: <error|warning|info> }`

This is the empirical seed for Proposal 030's broader form-vs-meaning bundle.

### Pillar 3: Reviewer scaffolder defensive warnings

In `scaffold-reviewer-artifacts.ps1`, when computing review evidence:

- If `git diff baseline...HEAD` returns empty BUT the iteration artifacts declare any task complete → emit a LOUD warning at the top of every review artifact:

  > ⚠️ **Review evidence may be misleading**: this iteration declares completed tasks but the git diff against baseline is empty. Implementation work may be uncommitted. See Proposal 073 and the pre-review commit gate.

- Continue to emit the artifact (don't block — the scaffolder is downstream of the validator gate), but make the gap visually obvious to any human reviewer who reads the artifact
- Replace the current silent "below threshold" omission text with the explicit warning when the gap is detected

### Pillar 4: Review-evidence re-runnability

Make the reviewer scaffolders idempotent so they can be re-run after the implementation is committed (e.g., at iteration-closeout or feature-closeout). Specifically:

- All review-evidence artifacts (`review-diagrams.md`, `code-map.md`, `dependency-report.md`) must be safely re-runnable
- The scaffold script should detect existing artifacts and either:
  - Overwrite cleanly when re-invoked with a `-Force` switch, OR
  - Update in place while preserving any human-added annotations
- An optional `specrew review-evidence regenerate` CLI command (composing with Proposal 033 Specrew Governance CLI) lets reviewers refresh evidence after late commits

This ensures that even when the methodology gate fails to fire, the human can manually refresh evidence post-commit and get accurate diagrams.

### Pillar 5: Composes with Proposal 030 (form-vs-meaning bundle)

Proposal 073 is the **first concrete sub-slice** of Proposal 030 (Quality Hardening Bundle for Form-vs-Meaning Verification). Its specific contribution:

- Provides the `Test-FormMeaningParity` helper that 030's broader bundle will compose with
- Provides one fully-implemented form-vs-meaning gap detection (state.md ↔ git diff)
- Documents the empirical case study that justifies 030's broader scope

When 030 ships, it absorbs 073's helpers and adds 3-4 more form-vs-meaning detection rules (review verdicts ↔ test results, plan tasks ↔ implementation tasks, etc.). 073 is not made redundant — it's the foundational layer 030 builds on.

## How (one-iteration plan)

- Feature branch from `main` (`028-review-evidence-integrity` per the feature-numbering convention)
- Squad drives specify → clarify → plan → tasks → implement → review → retro → closeout
- PR-at-feature-close per the SDLC; merge-commit only
- New files:
  - `extensions/specrew-speckit/scripts/shared-governance.ps1` — `Test-FormMeaningParity` helper
  - `extensions/specrew-speckit/scripts/validate-governance.ps1` — new validator rule invoking the helper
  - `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1` — defensive warning emission when gap detected; idempotent re-runnability
  - `tests/integration/review-evidence-integrity.tests.ps1` — integration test covering (a) gap detected when state.md declares completion + git diff empty, (b) gap NOT raised when both are empty (legitimate skip), (c) re-runnability after late commits
- CHANGELOG entry under `## Unreleased` → `### Added` (new validator rule + helper)
- INDEX update (status: shipped after feature closes)
- Documentation update in `docs/user-guide.md` — add a troubleshooting note explaining the new validator failure mode

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **030 (Quality Hardening Bundle, draft)** | This proposal is 030's first concrete sub-slice; provides the `Test-FormMeaningParity` foundation that 030 expands with additional form-vs-meaning rules |
| **004 (Validator Hardening, shipped F-013)** | New validator rule plugs into the same validator-governance plane that 004 established |
| **042 (Specrew Integration Test Suite, candidate)** | New integration test folds into 042's broader matrix when 042 ships |
| **033 (Specrew Governance CLI, draft)** | Pillar 4's optional `specrew review-evidence regenerate` CLI surface composes with 033's `specrew` command structure |
| **054 (Pre-Merge End-to-End Lifecycle Verification Gate, candidate)** | 054 catches drift at PR-merge time across the lifecycle; 073 catches the implementation→review gap before merge is even attempted. Complementary lifecycle-stage coverage |
| **F-016 / F-066 (boundary discipline, shipped)** | The review boundary is one of the lifecycle boundaries. 073 sharpens what it means for that boundary to advance: review can't advance until implementation is committed |
| **F-026 (PR-CI lint scoping, shipped)** | The validator rule that 073 adds operates at the same plane as 026's scoping work. Both contribute to the validate-governance.ps1 surface |
| **011 (Architecture Intent Checkpoint, draft)** | 011's 8th-boundary-checkpoint pattern in `/speckit.plan` is structurally similar to the pre-review gate here. Could share governance-gate infrastructure |

## Acceptance signals

- **AC1**: Running `validate-governance.ps1` against an iteration whose `state.md` declares completed tasks AND has an empty git diff against baseline produces a validation failure with category `review-evidence-integrity` and a remediation hint pointing to file:/// URLs
- **AC2**: The same validator on a clean iteration (declared completion + non-empty diff) produces no false-positive failures
- **AC3**: The same validator on an empty iteration (no declared completion + empty diff — e.g. spec/clarify only) produces no false-positive failures
- **AC4**: `scaffold-reviewer-artifacts.ps1` writes a loud warning at the top of `review-diagrams.md` (and other review artifacts) when the form-vs-meaning gap is detected, replacing the current silent "below threshold" message
- **AC5**: Re-running `scaffold-reviewer-artifacts.ps1` on a previously-scaffolded iteration produces accurate output (idempotent; safe to re-invoke post-commit)
- **AC6**: The integration test at `tests/integration/review-evidence-integrity.tests.ps1` passes all three scenarios (gap detected, no false positive, re-runnability)
- **AC7**: The 2026-05-21 smoke project at `specs/001-console-snake-game/iterations/001/` — when replayed under this gate — would block at review-boundary advance with a clear "implementation appears uncommitted" message instead of silently producing empty diagrams
- **AC8**: Existing iterations in the Specrew dev repo (F-009 through F-072) continue to validate cleanly — no regression of the established baseline
- **AC9**: When 030 (Quality Hardening Bundle) ships later, it absorbs the `Test-FormMeaningParity` helper from this proposal without modification — 073's API is the seed for 030's broader scope

## Cross-references

- **Empirical motivation**: 2026-05-21 smoke trial in fresh-init snake-game project; see `specs/001-console-snake-game/iterations/001/review-diagrams.md` showing "0 modules touched" while `state.md` declared T001-T011 complete
- Proposal 030 (Quality Hardening Bundle): file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- Proposal 004 (Validator Hardening, shipped): file:///C:/Dev/Specrew/proposals/004-validator-hardening.md
- Proposal 011 (Architecture Intent Checkpoint, draft): file:///C:/Dev/Specrew/proposals/011-architecture-intent-checkpoint.md
- Proposal 033 (Specrew Governance CLI, draft): file:///C:/Dev/Specrew/proposals/033-specrew-governance-cli.md
- Proposal 042 (Integration Test Suite): file:///C:/Dev/Specrew/proposals/042-specrew-integration-test-suite.md
- Proposal 054 (Pre-Merge Lifecycle Verification Gate): file:///C:/Dev/Specrew/proposals/054-pre-merge-lifecycle-verification-gate.md
- Validator script: file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/validate-governance.ps1
- Reviewer scaffolder: file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1
- Shared governance helpers: file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/shared-governance.ps1
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
