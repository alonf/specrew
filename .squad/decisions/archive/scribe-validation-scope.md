---
author: Scribe
date: 2026-05-20T01:15:00Z
type: methodology-lesson
scope: team-wide
---

# Validation Scope Asymmetry: Local vs. CI Full-Repo Coverage

## Observation

**Feature 024 Iteration 001** validation during development was scoped to a single iteration:
- Local pre-push validation checked Feature 024's own artifacts only
- CI/review gates validated the full repository state

This asymmetry surfaces a correctness hazard: developers may pass local validation while inadvertently breaking full-repo patterns.

## The Lesson

**Pre-push local validation must mirror CI's full-repo scope.**

When development validation is narrower than CI's validation:
- Local gates provide false confidence ("my validation passed")
- CI gates catch real breakage ("but the full repo has a problem")
- Developers don't learn the full-repo impact until review or merge

## Implication for Future Work

Validation tooling and pre-push hooks should adopt CI's validation scope, not a feature-scoped or iteration-scoped subset.

**Examples:**
- A skill-metadata validator should check all YAML frontmatter across all skill locations (`.claude/`, `.github/`, `.agents/`), not just Feature 024's additions.
- A governance validator should check all state artifacts and boundaries, not just the current iteration's state.
- A schema validator should check repo-wide schema consistency, not feature-local schema correctness.

## Context

This lesson emerges from Feature 024's multi-host deployment pattern and governance evolution. The feature itself validated successfully, but the asymmetry between local and CI validation is now visible and actionable for future validators and pre-push hooks.

## Team Action

When designing validators, pre-push hooks, or CI gates going forward:
- Audit whether local validation covers the same scope as CI validation.
- If local scope is narrower, document the asymmetry and adjust.
- If asymmetry is intentional (e.g., for speed), ensure the reduced local scope doesn't mask real issues.
