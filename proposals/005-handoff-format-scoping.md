---
proposal: 005
title: Handoff Format Scoping
status: shipped
phase: phase-1
estimated-sp: 8
shipped-as: feature-014
discussion: tbd
---

# Handoff Format Scoping

## Why

Feature 007 introduced a three-section boundary-handoff format ("What I just did" / "Why I stopped" / "What I need from you"). Squad applied this format to BOTH genuine stop points AND in-flight transitions where the format wasn't useful — producing verbose narration where a single sentence sufficed.

A recurring observation: Squad outputs like "What I need from you: Nothing yet" appeared in mid-iteration progress updates, where the format added overhead without adding value.

## What

Introduced a response-type selector distinguishing final-stop messages (full three-section format) from single-line in-flight progress updates (terse).

Added two soft-warning validator rules:
- `empty-user-action-section` — fires when "What I need from you" is empty or a placeholder
- `transitional-stop-claim` — fires when the three-section format is used for an in-flight transition that should have been terse

Coordinator-prompt updates clarify when each format applies. Template surfaces show worked examples for both.

See `specs/014-handoff-format-scoping/spec.md` for full detail.

## Effort

~8 SP, 1 iteration.

## Phase placement

Phase 1 — handoff signal-to-noise ratio. Foundation for Feature 016's essence-in-console Pillar 2 rules.

## Cross-references

- Specification: `specs/014-handoff-format-scoping/spec.md`
- Foundation for: Proposal 007 (Substantive Interaction Model) Pillar 2 thresholds
- Composes with: Proposal 003 (descriptive IDs in handoffs)

## Status history

- 2026-05-12: candidate captured following recurring "Nothing yet" placeholder observations
- 2026-05-12: status → draft → active → shipped
