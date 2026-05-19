---
proposal: 019
title: Spec-Arithmetic Mechanical Check
status: candidate
phase: phase-2
estimated-sp: 10
discussion: tbd
---

# Spec-Arithmetic Mechanical Check

## Why

Specs occasionally contain internally-contradictory mathematical claims that no one notices because the math feels reasonable in isolation. Example from a 2026-05-09 dogfooding run: a spec required `^[a-z0-9]{16}$` AND ≥96 bits entropy — but 16 base-36 characters carry only ~82.7 bits, making the requirement internally impossible. The spec passed all gates and shipped.

These contradictions are mechanically detectable but require explicit arithmetic checking. The current validator doesn't do this.

## What

A new mechanical-check rule that catches deterministic math contradictions in specs:

- Entropy bits vs character set size and length (regex-based detection)
- Byte size vs algorithm assumptions (e.g., AES key sizes)
- Rate-limit math (requests per X timeframe vs realistic throughput)
- Similar finite-arithmetic claims

Extends the validator's mechanical-checks tier. Composes with corpus row 5 (canonical-concern-enumeration, already validator-enforced).

## Effort

~10 SP, 1 iteration.

## Phase placement

Phase 2 — small focused addition to validator's mechanical checks. Sooner is better since the failure mode is real and recurring.

## Open questions

1. Heuristic catalog — which math patterns to detect initially? (Entropy is the most-cited; what else?)
2. Stack-aware variations — do JavaScript Number limits matter differently than Rust u64?
3. False-positive tolerance — strict (any apparent inconsistency) vs lenient (clear contradictions only)?
4. Spec-author override — explicit "yes I know this looks contradictory" annotation?

## Risks

- **False positives on legitimate trade-offs**: a spec saying "use 8-char IDs for usability despite 47-bit entropy" is intentional. Mitigation: explicit override annotation.
- **Heuristic limits**: not all math contradictions are detectable mechanically. Mitigation: this catches the deterministic class; non-deterministic class is for human review.

## Cross-references

- Justified by: 2026-05-09 ClipBridge failure mode analysis (entropy math contradiction)
- Composes with: Proposal 018 (Source-Spec Fidelity Contract) — both extend validator's mechanical-checks tier

## Status history

- 2026-05-09: candidate emerged from ClipBridge failure mode analysis
- 2026-05-12: scope refined; queued for Phase 2
