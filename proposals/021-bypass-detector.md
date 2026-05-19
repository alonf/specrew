---
proposal: 021
title: Bypass Detector
status: candidate
phase: phase-2
estimated-sp: 10
discussion: tbd
---

# Bypass Detector

## Why

Specrew's lifecycle requires that code changes in source surfaces (`extensions/`, `scripts/`, `.specify/`, similar) trace to a task in an active iteration's `tasks.md`. Without enforcement, code can be modified outside the lifecycle — bypassing the spec → plan → tasks → implement → review chain.

The corpus row "no direct idea-to-code bypass" exists in the prompt but isn't validator-enforced. This proposal graduates it to enforced rule.

## What

A new validator rule that, when files under tracked source surfaces are modified in a commit, checks that:

- An active iteration directory exists (e.g., `specs/<feature>/iterations/<NNN>/`)
- The active iteration's `plan.md` references a task whose owner-file-globs match the modified file paths
- The task is in `planned` or `in-progress` status

When checks fail: validator emits hard-fail with a clear remediation hint ("modify this file as part of task TNNN, or scope the change into a new iteration").

Grandfathers pre-rule commits (the bypass detector only applies to commits after the rule lands).

## Effort

~10 SP, 1 iteration.

## Phase placement

Phase 2 — graduation candidate. One of two graduation candidates (alongside Spec-Reconciliation Detector) that formalize prompt-only invariants as validator-enforced rules.

## Open questions

1. Which file paths are tracked? Initial set: `extensions/`, `scripts/`, `.specify/`. Configurable?
2. Owner-file-globs — strict match or fuzzy?
3. Bookkeeping commits (Scribe / agent history) — exempted? How?
4. Repair commits (non-canonical subjects) — exempted?
5. Multi-task changes — does one commit need to trace to ONE task or can it trace to multiple?

## Risks

- **Pre-rule commit grandfathering**: too generous = bypass attacks; too strict = breaks legitimate historical work. Mitigation: explicit cutoff date in rule config; grandfathered commits exempt; new commits subject to rule.
- **Repair-commit handling**: bookkeeping/repair commits don't trace to tasks but are legitimate. Mitigation: subject-line heuristic to classify; explicit exemption set documented.

## Cross-references

- Source: corpus row "no direct idea-to-code bypass" (currently passive guidance)
- Composes with: Proposal 022 (Spec-Reconciliation Detector) — pair of graduation candidates
- Composes with: Feature 016 boundary-discipline rules

## Status history

- 2026-05-12: candidate captured following validator-hardening retro
- 2026-05-13: queued for Phase 2 alongside spec-reconciliation detector
