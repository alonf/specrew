# Contract: Canonical Hardening-Gate Concerns

**Date**: 2026-05-12
**Feature**: `specs/013-validator-hardening`
**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Requirement**: FR-002, FR-009

## Purpose

This contract defines the five canonical concerns that must appear as the first five rows of the `Concern Review` table in every `quality/hardening-gate.md`. The validator rule introduced by FR-002 uses this document as its normative reference. Future concern additions or reorderings must update both this contract and the corresponding validator logic.

## Canonical Concerns

The `Concern Review` table in `quality/hardening-gate.md` MUST begin with these five rows in this exact order:

| Position | Concern ID | Category |
| --- | --- | --- |
| 1 | `security-surface` | `security` |
| 2 | `error-handling-expectations` | `error-handling` |
| 3 | `retry-idempotency-requirements` | `retry-idempotency` |
| 4 | `test-integrity-targets` | `test-integrity` |
| 5 | `operational-resilience-concerns` | `operational` |

## Table Location

The validator identifies the `Concern Review` table by looking for a Markdown section heading matching `Concern Review` (at `##` or `###` level) followed by a pipe-delimited table. The concern identifier is read from the first column of each data row.

## Enforcement Rules

1. **Presence check**: All five canonical concern IDs must appear in the `Concern Review` table.
2. **Order check**: The five canonical concerns must appear as rows 1 through 5 in the order defined above. Any concern in a position other than its required position triggers a FAIL.
3. **Additional concerns allowed**: Feature-specific or iteration-specific concerns may follow after position 5 without triggering a failure.
4. **Case-insensitive matching**: Concern IDs are compared case-insensitively after trimming whitespace.
5. **Partial tables**: A table with fewer than five data rows automatically fails both the presence and order checks for the missing rows.

## FAIL Output Contract

When the canonical concerns check fails, the validator MUST emit a `Structured Validator FAIL Output` (see `data-model.md`) with:

- `file_path`: relative path to the `hardening-gate.md` file
- `line_number`: line number of the `Concern Review` heading or the first incorrect row, when detectable
- `category`: `concern-order`
- `message`: names the missing concern and/or the incorrect position with expected vs. actual values
- `remediation_hint`: instructs the author to ensure the five canonical concerns appear as the first five rows in the required order

## Relationship to Known-Traps Corpus

This contract formalizes the corpus trap recorded in `.specrew/quality/known-traps.md` (governance trap: "hardening gate for feature 008 iteration 003 initially authored with six feature-specific concerns but missing the five canonical concerns"). After feature 013 Iteration 2 implementation, the corpus row for this trap will be updated to `validator-enforced` with a citation to FR-002 and the proving fixture test.

## Change Control

Changes to this contract require:

1. An updated `validate-governance.ps1` rule implementation.
2. Updated fixture coverage in `tests/integration/validator-hardening-iteration1.ps1`.
3. Updated corpus row in `.specrew/quality/known-traps.md` if the enforcement citation changes.
4. A revision note in this file naming the change, the requirement, and the date.

## Revision History

| Date | Change | Requirement |
| --- | --- | --- |
| 2026-05-12 | Initial contract created | FR-002, FR-009 |
