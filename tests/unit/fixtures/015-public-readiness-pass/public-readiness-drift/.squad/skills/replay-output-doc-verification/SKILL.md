---
name: "replay-output-doc-verification"
description: "Keep reviewer-facing documentation examples aligned with actual scaffold and replay output."
domain: "documentation"
confidence: "high"
source: "earned"
---

# replay-output-doc-verification

## Purpose

Prevent user-facing docs from drifting away from the real reviewer replay surfaces.

## When to Use

- A README, guide, or runbook shows `specrew review` output or reviewer-index summary lines.
- A change adds lockout-cap, routing-fallback, or other handoff-visible state to reviewer artifacts.
- A task explicitly says examples must be verified against actual runtime output instead of handwritten text.

## Pattern

1. Copy the relevant fixture or project into a scratch workspace inside the repo.
2. Run `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1` for the target iteration.
3. Run `scripts\specrew.ps1 review --project-path <scratch-project>` (or `scripts\specrew-review.ps1`) and capture the emitted summary/digest lines.
4. Paste only exact, still-relevant lines into docs; avoid paraphrasing output examples.
5. Re-check the documentation file against the captured output before finishing the task.
