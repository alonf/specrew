---
name: "runtime-surface-contract-alignment"
description: "Keep source docs, deferred stubs, and deployed runtime surfaces aligned"
domain: "governance"
confidence: "high"
source: "earned"
---

## Context
Use this when a repo has template sources, deployment scripts, and a spec/contract that must describe the same runtime surface.

## Patterns
- Distinguish **deployed runtime artifacts** from **source-only stubs** tied to future requirements.
- If the authoritative spec says a platform built-in behavior is reused, document Specrew-owned files as guidance, not as replacement runtime definitions.
- Fix the contract/README/template language first when implementation already matches the scoped requirement window.

## Examples
- FR-019 deferred to Iteration 2: keep `iteration-resume.md` in source, but do not describe it as deployed in MVP.
- FR-005 reuses Squad's built-in retrospective: keep `retro.md` as guidance, not as an appended Specrew ceremony.

## Anti-Patterns
- Documenting a deferred stub as live runtime behavior.
- Shadowing a platform built-in feature with a duplicate custom surface without a tracked source-of-truth change.
- Hardcoding project-specific titles into downstream baseline templates.
