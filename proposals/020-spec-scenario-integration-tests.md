---
proposal: 020
title: Spec-Scenario Integration Test Mandate
status: candidate
phase: phase-2
estimated-sp: 15
discussion: tbd
---

# Spec-Scenario Integration Test Mandate

## Why

Specs declare scenarios ("as a user, I want X so that Y") but there's no mechanical link between the declared scenarios and the integration tests that should exercise them. Empirically: features ship with implementation evidence but without integration tests that mirror the declared scenarios. The spec scenarios become aspirational; the tests test what the developer found convenient.

This proposal closes that gap by mandating that each declared scenario has a corresponding integration test.

## What

Mechanical scenario-to-test mapping:

- Validator scans `spec.md` for scenario declarations (e.g., "Scenario 1: ...", "User Story X: ...", or structured user-story sections)
- Validator scans `tests/integration/` for tests tagged or named per-scenario
- Mismatches emit hard-fail: scenarios without tests, or tests not mapped to scenarios

Test format conventions:

- Test file naming: `scenario-NNN-<descriptor>.ps1` (or stack-equivalent)
- Test frontmatter / docstring includes `scenario-ref: NNN` linkage
- Scenario sections in `spec.md` include `test-ref:` pointing to the integration test file

Integration tests follow scaffold-replay-path patterns (per established Specrew test-integrity corpus row) — real surface execution, not helper-only mocks.

## Effort

~15 SP across 1-2 iterations.

- **Iteration 1**: Validator scanning + test/scenario mapping + hard-fail rule
- **Iteration 2**: Test scaffolding helper to generate test stubs from declared scenarios

## Phase placement

Phase 2 — strategic quality lift. Composes with Source-Spec Fidelity Contract; the ClipBridge re-test (Phase 2 gate) measures this empirically.

## Open questions

1. Scenario declaration format — structured (user-story headings) or free-text with heuristic detection?
2. Stack-aware test naming — TypeScript `*.test.ts`, Python `test_*.py`, PowerShell `*.ps1` — how does the validator detect?
3. Test-stub generation — opt-in or default?
4. Backward compatibility — do existing features without scenario-test mapping grandfather?
5. Granularity — one test per scenario, or N tests per scenario allowed?

## Risks

- **Test-as-checkbox**: developers might add minimal tests to satisfy the rule without exercising the scenario. Mitigation: combined with code review; this rule ensures the LINK exists, not test quality.
- **Scenario format diversity**: specs may declare scenarios in many ways. Mitigation: validator accepts structured + heuristic detection; start strict, loosen via corpus rows.
- **Stack diversity**: cross-stack test discovery is hard. Mitigation: stack-aware catalog (similar to NFR Governance pattern).

## Cross-references

- Composes with: Proposal 018 (Source-Spec Fidelity Contract) — both close fidelity gaps
- Composes with: Proposal 019 (Spec-Arithmetic Mechanical Check) — together they form the Phase 2 quality-lift trilogy
- Foundation: existing test-integrity corpus row (scaffold-replay-path patterns)

## Status history

- 2026-05-13: candidate captured during quality-lift strategy review
