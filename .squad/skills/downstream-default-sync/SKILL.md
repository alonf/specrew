---
name: "downstream-default-sync"
description: "Keep downstream scaffold defaults and the repo's dogfooded config aligned when a governed default evolves."
domain: "governance"
confidence: "medium"
source: "earned"
tools:
  - name: "view"
    description: "Read the scaffold entrypoint, shipped template, and local dogfood config together."
    when: "When a change must land consistently across bootstrap output and repo-local defaults."
  - name: "apply_patch"
    description: "Update the three surfaces in one pass."
    when: "When the same governed default must stay aligned across script, template, and checked-in config."
  - name: "powershell"
    description: "Run existing contract tests or validators."
    when: "When proving the synchronized defaults did not break scaffolded flows."
---

## Context

Use this when Specrew changes a downstream default that is represented in both a scaffold template and the repo's own checked-in `.specrew` configuration.

## Patterns

- Treat the scaffold entrypoint, shipped template, and repo-local dogfood config as one contract surface; update all three in the same task.
- Keep the script change minimal unless behavior must change; a documentation or load-path note is enough when the template carries the real default.
- Validate both the bootstrap flow and the relevant governance path after the sync so template drift is caught immediately.

## Anti-Patterns

- Updating only the template and leaving the repo's `.specrew` config stale.
- Adding enforcement logic in the same task when the approved slice only seeds defaults.
