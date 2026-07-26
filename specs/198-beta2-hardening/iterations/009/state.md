# Iteration State: 009

**Schema**: v1
**Current Phase**: review-signoff
**Iteration Status**: in_progress
**Last Completed Task**: T078
**Tasks Remaining**: T079
**In Progress**: T079
**Baseline Ref**: afb3eda731d35ae922e92d9acf200f80e32e9580
**Updated**: 2026-07-26T16:20:00Z

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
result is preserved under `evidence/`. All three are now corrected in commits
`4641bea8` (tree-wide symlink containment before snapshot and verification-copy
materialization, `.antigravitycli` machinery classification), `0b5d0199`
(explicit historical-v1/current-v1 recovery binding shapes with fail-closed
currentness), and `78908cd9` (manifest-bound managed-runtime deployment with
safe retirement and post-copy identity verification); the six-suite focused
correction set passes 78/78. The exact-commit registry passed all 82 suites in
383.1 seconds and scoped governance passed in 27.9 seconds with historical
warnings only.

The maintainer pinned reviewer independence on 2026-07-26: while the
implementation host is Claude, codex is the reviewer of record and every review
invocation declares `code_writer_host=claude`. Copilot is not selectable because
its single catalog row carries an ambiguous claude-4.8 arm that no per-run
mechanism can narrow.

Three exact-commit review attempts followed. The first two failed closed with
zero provider spend and exposed two blocking review-infrastructure defects,
DRIFT-198-I009-008 and DRIFT-198-I009-009, both corrected. The third,
`run-f198-i009-178a3772-codex`, completed: one immutable slot spent, containment
verified, validation valid, currentness current, completion complete, and both
controller verification commands green on target digest
`b6ef0626a86323dce8598966d8434c0fec85243d`. It reported one major
candidate-membership defect, DRIFT-198-I009-010, in the immediately preceding
correction; that is now fixed with exact ordinal path identity and paired
regressions. The immutable result is preserved under `evidence/`.

The serial-lane parity gate then passed all 82 suites in 861.3 seconds against
the parallel lane's 383.1 seconds, so registry parity and repeated-green are
satisfied at the corrected tree.

The maintainer authorized one further slot, and the confirming review
`run-f198-i009-d2b786e6-codex` completed against digest
`cf2d67b679a5c56045af43fefa92be9438559af0` with containment verified, validation
valid, currentness current, and completion complete. It accepted the
DRIFT-198-I009-010 correction and reported four new defects:
DRIFT-198-I009-011 (blocking path-containment escape in the retired-runtime
cleanup introduced by this iteration's own DRIFT-198-I009-006 correction),
DRIFT-198-I009-012 (the same case-folding class one layer downstream in digest
stripping), DRIFT-198-I009-013 (generated Codex agent mirrors inside the
candidate), and DRIFT-198-I009-014 (a machine-local test report disclosing
origin details inside the candidate).

The maintainer then authorized the recommended systematic slice. Both classes
are corrected in one pass rather than four point fixes. Path identity: every
existing component of a retirement target is contained and any reparse-point
ancestor is refused before hashing or deletion, and digest denial takes its case
rule from the host instead of folding case everywhere. Machinery classification:
`.codex` joins the host-mirror vocabulary so generated Codex agent mirrors are
stripped, and the machine-local `testResults.xml` report is classified and
ignored so it cannot enter the candidate or disclose origin details.

All four corrections are green, including a real-symlink regression proving a
reparse-point ancestor is refused while the external file is left untouched.
T079 now awaits the verifying independent review under the authorized slot.
