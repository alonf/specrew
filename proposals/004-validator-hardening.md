---
proposal: 004
title: Validator Hardening
status: shipped
phase: phase-1
estimated-sp: 18
shipped-as: feature-013
discussion: tbd
---

# Validator Hardening

## Why

`validate-governance.ps1` had accumulated six categories of validator-rigor gaps where passive corpus guidance (in `.specrew/quality/known-traps.md`) wasn't enforced mechanically. Without enforcement, the gaps recurred across features — relying on attention rather than tooling.

The six gaps:

1. No canonical schema for FAIL/WARN output (each rule formatted findings differently)
2. Graceful error handling on malformed inputs (crashes leaked stack traces)
3. Over-claim detection (rules claiming PASS without examining the input)
4. Approval-reuse detection (single human approval being cited for multiple boundaries)
5. Bookkeeping-vs-substantive-commit classification (subagent history commits being mistaken for boundary work)
6. Structured exit codes (CI gates couldn't distinguish FAIL severity)

## What

A two-iteration overhaul of the validator surface:

**Iteration 1**: Canonical FAIL/WARN schema + structured output format. Each finding now carries: file path, line number, category, message, remediation hint, severity. Tested against synthetic fixtures.

**Iteration 2**: Five new validator rules graduated from corpus to enforced:

- Over-claim detection: rule must examine input artifacts; emitting PASS without examination → FAIL
- Approval-reuse detection: single decision ID cited by multiple boundary commits → FAIL
- Bookkeeping classifier: subagent history commits identified and separated from substantive boundary commits
- Graceful error: malformed inputs produce structured warnings instead of stack traces
- CI-aware exit codes: non-zero exit on FAIL; specific codes per severity

See `specs/013-validator-hardening/spec.md` for full detail.

## Effort

~18 SP across 2 iterations.

## Phase placement

Phase 1 — foundational for every subsequent validator-enforced feature. Feature 016's three-pillar rules build on this infrastructure.

## Cross-references

- Specification: `specs/013-validator-hardening/spec.md`
- Foundation for: Proposal 005 (Handoff Format Scoping), Proposal 007 (Substantive Interaction Model)
- Validates: hard-fail and soft-warning rules across the validator surface

## Status history

- 2026-05-11: candidate captured following accumulated gap analysis
- 2026-05-12: status → draft
- 2026-05-12: status → active → shipped (both iterations)
