# Iteration State: 009

**Schema**: v1
**Current Phase**: review-signoff
**Iteration Status**: in_progress
**Last Completed Task**: T078
**Tasks Remaining**: T079
**In Progress**: T079
**Baseline Ref**: afb3eda731d35ae922e92d9acf200f80e32e9580
**Updated**: 2026-07-26T10:16:00Z

## Objective

Deliver candidate/source identity before the later review-convergence work.
Article Amplifier is immutable evidence: all reproductions use disposable
copies.

## Authorization

- Five-iteration plan approved by the maintainer on 2026-07-26.
- Proposal 209 amendment corrected to W1/W2 only.
- Standing grant covers in-scope fix/test/review correction cycles.
- Merge, tag, publication, and the final human manual test remain outside this
  iteration.

## Current Work

T072–T078 are implemented and focused-green. The frozen Article Amplifier
round-15 replay proves that the historical 164-path candidate no longer admits
the explicitly excluded `.claude/settings.local.json` or review-runtime
evidence, while preserving consumer HEAD and status. T079 is running the
serial/parallel parity, repeated-green registry, governance, and independent
review gates. DRIFT-198-I009-001 captured and corrected the blocking native
cleanup deadlock and long-path disposal failures. DRIFT-198-I009-002 corrected
two measured near-zero-margin suite ceilings and one load-sensitive POSIX
assertion exposed by exact-commit preflight. DRIFT-198-I009-003 captured and
corrected the shared-prompt mismatch that left Codex without a permitted
inspection tool; its single valid result remained honestly incomplete and
cannot approve the candidate. The corrected exact-commit review completed with
both controller verification commands green and reported three current product
defects: DRIFT-198-I009-004 (blocking symlink snapshot escape),
DRIFT-198-I009-005 (major recovery-fact compatibility), and
DRIFT-198-I009-006 (major non-convergent managed-runtime update). The immutable
result is preserved under `evidence/`; T079 and iteration signoff remain blocked
pending correction and another exact-commit review.
