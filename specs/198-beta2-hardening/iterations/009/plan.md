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

## Scope Summary

Iteration 009 addresses the candidate-fidelity dependency first: F13/F16,
F12, F6, and F15, plus Proposal 209 W1/W2. Review-finality and lifecycle
semantics remain assigned to Iterations 010–012.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- |
| T072 | Proposal 209 W1 per-suite timing | P209-W1 | Verification cost | 0.5 | Implementer | tests/f198-regression-suite.ps1, tests/unit/regression-harness-isolation.tests.ps1 | done | Implementer | 0.5 | passed |
| T073 | Proposal 209 W2 bounded parallel registry | P209-W2 | Verification cost | 1.5 | Implementer | tests/f198-regression-suite.ps1, tests/unit/regression-harness-isolation.tests.ps1 | done | Implementer | 1.5 | passed |
| T074 | Canonical candidate inclusion and exclusion identity | F13, F16 | Candidate fidelity | 5.0 | Implementer | scripts/internal/continuous-co-review/reviewed-state-digest.ps1, scripts/internal/continuous-co-review/review-target-port.ps1, scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1, scripts/specrew-review.ps1, tests/continuous-co-review/** | done | Implementer | 5.0 | passed |
| T075 | Codex file-primary delivery without duplicate invocation | F12 | Provider delivery | 1.5 | Implementer | scripts/internal/continuous-co-review/review-codex-harness-port.ps1, tests/continuous-co-review/** | done | Implementer | 1.5 | passed |
| T076 | Review-engine version handshake | F6 | Runtime identity | 2.5 | Implementer | scripts/internal/review-engine-resolution.ps1, scripts/specrew-review.ps1, scripts/internal/distribution-module-init.ps1, tests/** | done | Implementer | 2.5 | passed |
| T077 | Consumer review-runtime ignore classification | F15 | Consumer hygiene | 0.5 | Implementer | scripts/internal/file-classification.ps1, tests/** | done | Implementer | 0.5 | passed |
| T078 | Candidate fidelity frozen-evidence regression | F13, F16 | Frozen replay | 4.0 | Implementer | specs/198-beta2-hardening/iterations/009/evidence/**, tests/continuous-co-review/** | done | Implementer | 4.0 | passed |
| T079 | Integrated verification and independent review | F6, F12, F13, F15, F16, P209-W1, P209-W2 | Release confidence | 4.5 | Reviewer | tests/**, specs/198-beta2-hardening/iterations/009/** | in-progress | Reviewer | 4.5 | registry, serial parity, and both controller verification commands green; re-certification `run-f198-i009-0e0048b0-recert` completed but NOT clean — 4 major, `can_approve_current: false`. NOT closed; awaiting the maintainer's convergence decision |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Restored project baseline; the historical F197 override is discharged at this closeout. |
| Iteration Bounding | scope | The approved finding cluster is fixed. |
| Time Limit (hours) | n/a | Scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit allowed. |
| Defer Strategy | manual | No approved finding is silently dropped. |
| Calibration Enabled | true | Retro records engineering and verification variance. |

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

## Triaged to the Next Replan

Recorded here because a drift-ledger entry alone is not a disposition
(maintainer instruction 2026-07-28). These carry a named owner and a required
action into the next replan; they are not closed by this iteration.

| Item | Severity | Required action at replan |
| --- | --- | --- |
| DRIFT-198-I009-028 — recording a reviewer grant clobbers unrelated host policy | **major, consumer-reachable** | Size and schedule a corrective task: update only the addressed row's `authorization_ref`, preserving every other field and row verbatim, plus a regression asserting that recording a grant for one host leaves all other rows byte-identical. The defect silently nulled a deliberate reviewer-INDEPENDENCE suspension, so it is a governance-integrity item, not cosmetic. |
| DRIFT-198-I009-029 — a verification command inherits the operator's ambient PATH | minor | Decide whether to distinguish an execution-environment failure from a command that ran and returned non-zero in the stable reason. The fail-closed behaviour and output privacy are correct and must not be traded away for diagnosability. |
| DRIFT-198-I009-020 — retroactive closeout has no first-class boundary crossing | minor | Specrew product backlog: give the verdict record an explicit subject distinct from the cursor it advances. |
| DRIFT-198-I009-021 — closure artifacts cannot express successor-iteration evidence | minor | Specrew product backlog: a concern-level disposition meaning "runtime evidence recorded by a named successor iteration". |
| Structural path-identity tests are grep-based, not AST-based | accepted residual **— trigger now met** | The residual was accepted on the condition "revisit only if the path-identity class recurs" (maintainer decision 2026-07-28). It recurred at round 6: DRIFT-198-I009-031/032/033. Re-decide rather than carry forward. |
| DRIFT-198-I009-031 — deployment containment guard covers one mutator of five | **major, consumer-reachable** | Size a corrective task placing the containment check at a single choke point every read and mutation traverses, including directory creation and deletion. Third appearance of this class after 011 and 025. |
| DRIFT-198-I009-032 — the volume probe misreads the target directory | **major; the primitive every other correction depends on** | Size a corrective task requiring BOTH spellings to be enumerated before concluding two real siblings exist, probing inside the physical target. Third defect in the same function. The fixture must be able to FAIL — built from a known on-disk spelling, not from the probe's own answer. |
| DRIFT-198-I009-033 — `-CaseSensitive` is culture-aware, not ordinal | **major, review-integrity** | Size a corrective task replacing all eight `Sort-Object -Unique -CaseSensitive` sites with a `HashSet` on the same comparer as the maps, sorting only for presentation. Falsifies DRIFT-198-I009-023's recorded reasoning. |
| DRIFT-198-I009-034 — the gate cannot express a human deferral for a freshly discovered finding | **major governance-mechanism gap** | Decide: fix DRIFT-198-I009-028 (the reviewer supplied the exact correction, and it is smaller than the alternative) or add a first-class deferral disposition that survives across campaigns and reaches fresh rounds. Until one happens, `can_approve_current` cannot become true and the authorized deferral is unrepresentable. |
| Whether this surface is certifiable by review-and-fix rounds | **open question for the maintainer** | Six rounds, three of them after the root cause was found and a systematic sweep applied. Decide between continuing rounds, a different instrument (property/differential tests against real volumes, AST enumeration), or a narrowed release claim that does not assert cross-platform path identity. See the convergence assessment in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/drift-log.md |

## Verification

- Focused unit/integration tests for T072–T078.
- Serial/parallel registry parity and repeated-green W2 proof.
- Full `tests/f198-regression-suite.ps1`.
- Iteration governance validation.
- Exact-commit hosted CI.
- Independent review of the exact candidate.
