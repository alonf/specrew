---
proposal: 029
title: Handoff Format Scoping Refinement
status: candidate
phase: phase-2
estimated-sp: 5
discussion: tbd
---

# Handoff Format Scoping Refinement

## Why

Feature 014 (handoff-format-scoping) ships a three-section format for boundary handoffs. Empirically observed 2026-05-12: Squad applies the three-section format to IN-FLIGHT TRANSITIONS, not just genuine stop points. The format is heavy for transitions (where a single sentence suffices) and produces patterns like:

- "What I need from you: Nothing yet" placeholder
- "Why I stopped: continuing to next step" non-information

The refinement narrows the format application to actual stops and adds soft-validator detection for placeholder-only handoffs.

## What

Small refinement to existing Feature 014:

1. **Coordinator-prompt update**: clarify that the three-section format applies ONLY to boundary stops (planning, hardening-gate-signoff, implementation, review, etc.), NOT to in-flight transitions between work units within a phase.

2. **Soft-validator rule**: `placeholder-only-handoff` — fires when a three-section handoff contains only placeholders like "Nothing yet" or "continuing".

3. **Worked example update**: coordinator-prompt examples show terse in-flight format alongside substantive boundary format.

## Effort

~5-10 SP, single iteration.

## Phase placement

Phase 2 — small refinement of existing Feature 014. Composes with Feature 016's substantive-content rules.

## Open questions

1. Definition of "boundary stop" vs "in-flight transition" — list-based or semantic?
2. Soft-warning severity — initial soft, eventually hard?
3. Placeholder detection — pattern-list ("Nothing yet", "continuing", etc.) or semantic?

## Risks

- **False positives on legitimate brevity**: a substantive handoff can be brief. Mitigation: pattern-based detection of specific placeholder phrases, not length-based.

## Cross-references

- Refines: Proposal 005 (Handoff Format Scoping, Feature 014 shipped)
- Composes with: Proposal 007 (Substantive Interaction Model, Feature 016 — Pillar 2 substantive-content rules complement this)

## Status history

- 2026-05-12: candidate captured following recurring observation of "Nothing yet" placeholders
