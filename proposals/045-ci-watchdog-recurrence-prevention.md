---
proposal: 045
title: CI Watchdog & Recurrence Prevention
status: candidate
phase: phase-2
estimated-sp: 8
discussion: tbd
---

# CI Watchdog & Recurrence Prevention

## Why

Specrew's own CI was red for 3+ days in mid-May 2026 (1,565 markdown lint violations + various PowerShell lint warnings + missing macOS PowerShell install + bogus specrew-init flags in CI workflow) before any contributor noticed. The user only discovered it when investigating an unrelated branch-protection question.

A methodology project that allows its own CI to silently degrade undermines the credibility of "spec-governed AI" claims. Need a four-layer prevention so CI red can't go undetected for >24 hours.

## What

### Four-layer prevention

1. **Branch protection on `main`** — require status checks (Ubuntu Validation, macOS Validation, test, Lint) before merging. Forces CI green for protected merges. Already configurable in GitHub settings; needs explicit policy + setup.

2. **Squad coordinator rule at feature-closeout** — explicitly check CI state on the merging branch before authorizing feature-closeout (Boundary 6). If CI is red, surface the failures + ask for explicit user override before proceeding to PR creation. Integrates with [038](038-adaptive-boundary-discipline.md) mechanical-execution boundary class (the check is automatic, the override decision is human-judgment).

3. **Validator Hardening gap #10** — `validate-governance.ps1` adds a "CI status check" rule that queries the current branch's last CI run state and reports as WARN if red. Promote to FAIL after Layer 1 (branch protection) lands so the rule never gates locally without recourse.

4. **Dashboard surface** — `specrew where` adds a "CI" row in the Recent/Active section showing red/yellow/green state with link to failing run. Visible on every dashboard render, so chronic red can't be silently tolerated.

### Out of scope

- Auto-fixing CI failures (lint cleanups go through their own proposals: [034](034-markdown-lint-strict-defaults-restoration.md), [037](037-psscriptanalyzer-lint-cleanup.md))
- Pre-commit hooks (separate concern; addressed by `specrew init` quality baseline in [044](044-downstream-quality-baseline-bootstrap.md))

## Effort

- **Iteration 1** (~4-5 SP): Layer 1 branch protection setup + Layer 2 Squad coordinator rule
- **Iteration 2** (~3-4 SP): Layer 3 validator rule + Layer 4 dashboard CI row

**Total**: ~7-9 SP

Can split: Layer 1+2 ship together as a small chore + coordinator-prompt update; Layer 3+4 as a separate iteration with validator + dashboard work.

## Phase placement

**Phase 2**, after [035](035-session-state-durability.md). Strongest predecessor to [037](037-psscriptanalyzer-lint-cleanup.md) and [034](034-markdown-lint-strict-defaults-restoration.md) (the cleanup features) — without watchdog, the cleanups don't stay clean.

## Open questions

1. Branch protection: required status checks include only the lifecycle-critical lanes (Ubuntu + macOS Validation) or also the lint lanes (which currently fail)?
2. Squad coordinator rule severity: hard-block on CI red, or soft-warn with explicit override available?
3. Validator gap #10 severity: WARN initially, FAIL after branch protection lands?
4. Dashboard CI row: query CI on every `specrew where` invocation (slow, network) or cache daily (fast, may be stale)?
5. CI red threshold: any failing lane fails the check, or N-of-M lanes pattern?

## Risks

- Layer 1 + Layer 2 are coordination work, not code; risk is forgetting to enable branch protection. Mitigation: add to public-flip checklist.
- Network-dependent dashboard query may slow `specrew where`; needs caching design (composes with [035](035-session-state-durability.md) version-check caching).

## Cross-references

- Composes with [004](004-validator-hardening.md) (validator gap #10)
- Composes with [009](009-velocity-dashboard.md) (dashboard CI row)
- Composes with [038](038-adaptive-boundary-discipline.md) (coordinator-rule at feature-closeout boundary)
- Predecessor for [037](037-psscriptanalyzer-lint-cleanup.md), [034](034-markdown-lint-strict-defaults-restoration.md) (cleanup features need watchdog to stay green)

## Status history

- 2026-05-16: captured as memory after CI red discovered to have persisted 3+ days
- 2026-05-18: promoted to candidate proposal during memory→proposals consolidation
