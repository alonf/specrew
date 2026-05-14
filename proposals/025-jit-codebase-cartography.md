---
proposal: 025
title: JIT Codebase Cartography
status: candidate
phase: phase-7
estimated-sp: 100
discussion: tbd
---

# JIT Codebase Cartography

## Why

Specrew today assumes greenfield or near-greenfield projects. For brownfield codebases — 1000+ project codebases with deep history, undocumented architectural decisions, and scattered knowledge — Specrew's spec-first lifecycle has nowhere to start.

The methodology needs an entry point for engaging existing codebases without requiring a full retrospective audit. Just-in-time cartography is the answer: distributed context files that surface relevant code locations as the developer encounters them, with structured zones distinguishing human-curated insights from auto-generated context.

## What

Three components:

1. **Distributed `specrew-context.md` files**: placed in directories with non-obvious architectural context. Two zones per file:
   - Human zone: curated context (decisions, conventions, gotchas)
   - Auto zone: generated context (imports, callers, callees from static analysis)

2. **Pre-directory-read hook**: when Specrew's lifecycle requires reading code from a directory, the hook first reads the directory's `specrew-context.md` (if present) to surface relevant context

3. **`specrew-indexer` CLI**: parses project files using stack-appropriate tooling:
   - `.csproj`/`.sln` for .NET (via Roslyn)
   - `CMakeLists.txt`/`Makefile` for C/C++ (via libclang)
   - General code structure via Tree-sitter
   
   Builds the auto-zone content; humans curate the human-zone.

## Effort

~80-120 SP across 5-8 iterations. Substantial multi-iteration feature.

## Phase placement

Phase 7 — LATE in the roadmap. Specrew needs to be mature for greenfield first; brownfield support comes after.

## Open questions

1. Context file granularity — every directory, or only architecturally-significant?
2. Auto-zone refresh frequency — on-demand, scheduled, or commit-triggered?
3. Stack-aware tool selection — Roslyn for .NET, libclang for C++, Tree-sitter as fallback?
4. Privacy: should auto-zone include code snippets or only references?
5. Adoption path for existing brownfield: bulk-generate or incremental?

## Risks

- **Context-file maintenance burden**: stale human-zone content. Mitigation: explicit "last-curated-at" timestamps; suggest re-curation when underlying code changes significantly.
- **Stack diversity**: each language ecosystem needs different parsers. Mitigation: prioritize the 3-5 most common stacks; Tree-sitter fallback for others.
- **Privacy on auto-zone**: code snippets may expose IP. Mitigation: configurable include/exclude patterns.

## Cross-references

- Targets: brownfield 1000+ project codebases
- Composes with: Proposal 008 (NFR Governance) — architectural intent + context files form a rich design surface

## Status history

- 2026-05-12: candidate captured during brownfield support discussion
- 2026-05-13: Phase 7 placement confirmed (LATE in roadmap)
