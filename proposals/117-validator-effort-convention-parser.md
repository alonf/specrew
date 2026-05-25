---
proposal: 117
title: Validator Effort Convention Parser — Honor S/M/L Iteration Effort Values
status: candidate
phase: unphased
estimated-sp: 2-3
discussion: tbd
---

# Validator Effort Convention Parser — Honor S/M/L Iteration Effort Values

## Why

`validate-governance.ps1` currently parses iteration task effort with numeric-only `TryParse(...)` logic. Iteration plans in this repo commonly document effort with bounded letter conventions such as `S` and `M`, so the validator mis-sums planned effort as `0` even when the human-readable effort model is correct.

This surfaced during **F-045 iteration 001, the v0.27.1 bug-fix bundle**, where the task table used `S`/`M` values and the validator rejected `Capacity 20/20` because every effort cell failed numeric parsing. The current workaround is to store numeric effort in that one iteration plan, but the framework parser remains inconsistent with the repo's documented convention.

## What

Update the governance validator so it accepts both numeric effort values and the repo's documented bounded letter convention when summing planned effort and enforcing overcommit logic.

### Functional requirements

- The validator MUST accept numeric effort cells such as `1`, `2`, and `3` exactly as it does today.
- The validator MUST also accept canonical bounded values such as `S`, `M`, `L`, and `XL` using the repo mapping.
- The effort parser MUST be shared by both capacity summation and overcommit/defer logic so the two paths cannot drift.
- The mirrored validator at `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` MUST remain identical to `extensions/specrew-speckit/scripts/validate-governance.ps1`.
- Test coverage MUST prove backwards compatibility for numeric values and correct summation for letter-based values.

### Out of scope

- Changing F-045 user-facing bug-fix scope or rebundling its iteration work.
- Reworking task numbering, capacity policy, or iteration planning conventions.
- Introducing new effort semantics beyond the documented bounded convention.

## Effort

- **Iteration 1 (~2-3 SP)**: Add shared effort parser, update both validator code paths, mirror the change, and add regression coverage.
- **Total**: ~2-3 SP

## Phase placement

Unphased small-fix slice. This is framework tech debt discovered while unblocking F-045 and should land independently rather than inside the v0.27.1 bug-fix bundle.

## Open questions

1. Is `XL=5` already the canonical repo mapping, or is the validator change only required to support `S=1`, `M=2`, and `L=3` for now?
2. Should the canonical mapping be documented in one shared repo surface beyond per-iteration prose notes so future validator/tooling code reads from a single source?

## Risks

- If the mapping is implemented in only one validator path, capacity and overcommit logic could disagree.
- If mirror parity is missed, `extensions/` and `.specify/` copies will drift and future scoped validation will become unreliable.
- If tests cover only letter values, a regression could break existing numeric iteration plans.

## Cross-references

- Related proposals: `067-small-fix-slice-type.md`, `004-validator-hardening.md`
- Source artifacts: `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `specs/045-v0271-bugfix-bundle/iterations/001/plan.md`
- Composability with: future iteration planning and validator reliability work

## Status history

- 2026-05-25: status transitioned from none to candidate. Captured as a separate small-fix slice after validator code inspection revealed numeric-only effort parsing.
