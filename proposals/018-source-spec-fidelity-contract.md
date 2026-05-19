---
proposal: 018
title: Source-Spec Fidelity Contract
status: candidate
phase: phase-2
estimated-sp: 30
discussion: tbd
---

# Source-Spec Fidelity Contract

## Why

Two recurring failure modes when generating implementations from spec.md:

**Half 1: source-to-spec fidelity** — When the user supplies a source document (e.g., a customer requirements doc), the generated `spec.md` from `/speckit.specify` drops concrete contracts. Patterns like "see source at line 122" appear; specific schemas, message types, or magic numbers get summarized away into generic prose.

**Half 2: spec-to-implementation fidelity** — Comparative analysis across 7 Clipboard projects on 2026-05-13 revealed that even when the spec is correct, the agent renames protocol messages, swaps libraries, skips prescribed magic numbers, uses wrong directory naming. ClipBoard6 ranked 1st on engineering quality but 5th of 6 on spec compliance (~62%).

Both halves represent fidelity gaps where the implementation diverges from declared contracts.

## What

A two-direction fidelity contract:

**Source → spec**: When `/speckit.specify` ingests a source document, the generated spec MUST either preserve concrete contracts verbatim OR fail closed with a structured completeness diff naming dropped sections. No silent simplification.

**Spec → implementation**: Mechanical extraction of prescribed identifiers from spec.md (protocol message names, library/dependency names, magic-number constants, directory/structural conventions, DOM/UI conventions). Validator scans implementation against the extracted prescriptions; mismatches emit hard-fail.

Five categories of prescription verification:

1. Protocol/identifier (spec.md → implementation source code)
2. Library/dependency (spec.md → package.json / equivalent)
3. Magic-number/constant (spec.md → source code constants)
4. Directory/structural-convention (spec.md → repo layout)
5. DOM/UI structural-convention (spec.md → component tree)

## Effort

~30 SP across 2-3 iterations.

- **Iteration 1**: Source-to-spec fidelity contract + completeness-diff format
- **Iteration 2**: Spec-to-implementation prescription extractor + scanner + hard-fail rule
- **Iteration 3**: Integration tests + corpus seeding for both halves

## Phase placement

Phase 2 — the most strategically important quality-lift feature. The ClipBridge re-test (Phase 2 gate) measures this empirically.

## Open questions

1. Source-document parsing — what formats supported (markdown, plain text, PDF)?
2. Completeness-diff format — structured (JSON) or prose markdown?
3. Prescription extraction — keyword-based, schema-based, or LLM-based?
4. Stack-aware prescription mapping — how to detect TypeScript magic numbers vs Python constants?
5. Hard-fail severity — initial soft-warning then promote, or hard-fail from start?
6. Backward compatibility for existing specs without prescriptions?

## Risks

- **False positives on prescription extraction**: validator may flag legitimate refactoring as prescription drift. Mitigation: extraction is conservative (literal-only); refactor-friendly with explicit aliases.
- **Source document quality**: bad source → bad spec → bad implementation regardless. Mitigation: this feature catches drift, doesn't fix bad sources.
- **Prescription rigidity**: forcing verbatim preservation may prevent legitimate clarification. Mitigation: completeness-diff format makes drops explicit, allowing review and acceptance.

## Cross-references

- Composes with: Proposal 019 (Spec-Arithmetic Mechanical Check) — both extend the validator
- Composes with: Proposal 020 (Spec-Scenario Integration Tests) — both close fidelity gaps
- Justified by: ClipBoard6 dogfooding evidence (~62% spec compliance)

## Status history

- 2026-05-09: candidate emerged from ClipBridge failure mode analysis
- 2026-05-13: scope expanded from source-to-spec only to include spec-to-implementation half
