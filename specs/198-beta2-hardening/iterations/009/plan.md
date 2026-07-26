# Iteration Plan: 009 — Review Candidate Fidelity

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 20.0/20 story_points
**Started**: 2026-07-26
**Completed**:
**Planning Baseline**: `afb3eda731d35ae922e92d9acf200f80e32e9580`

## Human Authorization

The maintainer approved Iterations 009–013 as one bounded Beta2 bug-bash on
2026-07-26. The standing grant covers autonomous fix, deterministic test, and
independent-review correction cycles. It does not authorize a merge, tag,
publication, paid-provider action outside an existing grant, or changes beyond
the approved finding set.

The authorization was amended to pull the faithful minimal Proposal 209 slice
into this iteration:

- W1: per-suite timing instrumentation.
- W2: throttled parallel dispatch with a serial escape hatch, explicitly
  serial-tagged race-sensitive suites, and repeated-green proof.

Proposal 209 does not define verification-evidence reuse or ceiling
auto-scaling. Those are not part of this iteration. F10 round-ceiling
semantics remain assigned to Iteration 011.

## Objective

Make the reviewed candidate equal the authorized audited source before
changing review finality policy. The candidate must include tracked source and
untracked non-ignored product files, exclude Git-ignored/runtime content, honor
persisted human path exclusions in both digest and materialization, and expose
one exact composition manifest. Ensure the matching project engine performs
the review and that Codex file delivery does not cause a duplicate invocation.

## Scope

| Task | Finding/Proposal | Effort |
| --- | --- | ---: |
| T072 | Proposal 209 W1 timing | 0.5 |
| T073 | Proposal 209 W2 bounded dispatch | 1.5 |
| T074 | F13/F16 candidate inclusion/exclusion identity | 5.0 |
| T075 | F12 Codex file-primary delivery | 1.5 |
| T076 | F6 review-engine version handshake | 2.5 |
| T077 | F15 consumer review-runtime classification | 0.5 |
| T078 | Focused and frozen-evidence regression | 4.0 |
| T079 | Full verification, independent review, expected rework | 4.5 |
| **Total** | | **20.0** |

## Design Decisions

### Candidate membership

The source set is computed once and reused:

1. tracked files from the frozen reviewed digest;
2. untracked, non-ignored files reported by Git;
3. minus Git-ignored paths;
4. minus canonical machinery paths;
5. minus explicit exclusions whose decision and provenance are persisted in
   the review request/scope record.

Untracked non-ignored files remain reviewable because new product source must
not disappear. Gitignored files do not become product source merely because
they exist in the working directory.

The same included-path set drives the reviewed-state digest, candidate
materialization, `changes.diff`, composition counts, and candidate manifest.
No later layer may independently rediscover or expand the source set.

### Exclusion authority

Explicit exclusions are auditable inputs. The engine records pattern,
resolved paths, decision source, and resulting candidate identity. A path
excluded from the diff is also absent from the materialized candidate.
Exclusion cannot silently convert an otherwise reviewable tracked product path
into a clean result.

### Proposal 209 safety

Parallelism changes scheduling only:

- every suite still executes in an isolated child process;
- output remains buffered per suite;
- timeout and exit-code semantics are unchanged;
- race-sensitive suites run serially after the parallel pool drains;
- `-Serial` preserves the original execution path;
- the complete registry remains the only acceptable boundary/signoff evidence.

## Acceptance Criteria

1. A fixture containing tracked source, untracked source, ignored `bin/obj`,
   ignored SQLite files, `.claude/settings.local.json`, and one explicit
   exclusion produces an exact expected candidate set.
2. The explicit exclusion is absent from both `changes.diff` and the candidate.
3. Untracked non-ignored source is included.
4. Candidate manifest, digest, diff, and materialized paths agree exactly.
5. A Codex invocation that exits zero with empty stdout and a valid current-run
   result file invokes the provider exactly once.
6. A stale installed engine cannot silently run when a different project
   engine is authoritative.
7. Consumer templates ignore/classify `.specrew/review/` runtime evidence.
8. W1 reports deterministic per-suite timings and optional machine-readable
   output.
9. W2 proves serial parity and at least three consecutive complete parallel
   registry passes without evidence loss.
10. A read-only copy of the Article Amplifier end state no longer admits
    `.claude/settings.local.json` into the candidate when its recorded
    exclusion applies.

## Capacity and Closeout

The repository mechanically still carries `capacity_per_iteration: 26` from
the grandfathered F197 override. This plan does not use that capacity. The
maintainer explicitly requires the `f197-i010-cap-revert-obligation` to execute
at the next closeout; Iteration 009 closeout restores the configured capacity
to 20 after historical iterations have been grandfathered.

## Verification

- Focused unit/integration tests for T072–T078.
- Serial/parallel registry parity and repeated-green W2 proof.
- Full `tests/f198-regression-suite.ps1`.
- Iteration governance validation.
- Exact-commit hosted CI.
- Independent review of the exact candidate.
