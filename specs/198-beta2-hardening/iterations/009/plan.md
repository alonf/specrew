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

**Reconciled at closeout (2026-07-29).** This paragraph previously stated that the
repository "mechanically still carries `capacity_per_iteration: 26`" from the
grandfathered F197 override, and that the revert to 20 would happen at this
closeout. That is stale: the `f197-i010-cap-revert-obligation` is already
DISCHARGED. file:///C:/Dev/specrew-beta2-hardening/.specrew/iteration-config.yml
carries `capacity_per_iteration: 20`, changed from 26 in commit `b3e2960e`, and
the file's own comment records the closure. The override had been raised in
`7d4230a5` on 2026-07-02.

One date correction for the record: the revert landed **2026-07-26**, not
2026-07-27 — `b3e2960e` is dated 2026-07-26 and its comment reads "CLOSED
2026-07-26 at F-198 iteration 009 closeout". No obligation remains outstanding,
and this iteration's planning figures were always stated against 20 rather than
26, so nothing downstream shifts.

### Actual capacity consumed — restated honestly (maintainer instruction, 2026-07-29)

The planned figure was **24.5 SP** across T072–T079 against a stated capacity of
20. The delivered figure is far higher and pretending otherwise would corrupt the
calibration this effort model exists to feed. What actually landed, none of it in
the original plan:

| Unplanned work | Rough SP | Why it was not plannable |
| --- | --- | --- |
| DRIFT-198-I009-001 through -014 corrections | ~12 | Fourteen defects found by review rounds 1–3, each corrected in-flight. |
| DRIFT-198-I009-018 / -019 — loader scope + the reverted ignore filter | ~5 | Included three CI cycles spent on a Linux "hang" that never existed; `gh run view --log` truncation was read as silence. |
| DRIFT-198-I009-022 through -026 — round 4 | ~8 | Five further defects, including one introduced by the -018 correction hours earlier. |
| DRIFT-198-I009-027 — the shadowing duplicate | ~4 | The ROOT CAUSE of the whole class, found by a directed sweep rather than by review. Unknowable at plan time. |
| DRIFT-198-I009-030 — canonical vs mirror | ~3 | A correction verified against the wrong artifact; the shipped product never received it. |
| DRIFT-198-I009-031 / -032 / -033 + the differential harness | ~8 | Round 6, plus the instrument change that replaced review rounds as the certification mechanism. |
| Review infrastructure repair (-008, -009, -029) and six paid review rounds | ~6 | Reviewing this iteration required repairing the reviewer. |

**Honest total: on the order of 70 SP delivered against a 20 SP capacity —
roughly 3.5x.** Iteration 009 was not a 24.5 SP iteration that ran long; it
became a different iteration. The single largest driver is recorded in the
convergence assessment: five consecutive rounds of point corrections that could
not converge because a shadowing duplicate made every "fix" a no-op, which no
amount of planning discipline would have exposed.

What the calibration should carry forward, stated as signal rather than excuse:
an iteration whose scope is "correct the defects an independent reviewer finds"
has no knowable size at plan time, because the work is defined by what the
reviewer has not looked at yet. Bounding such an iteration by SCOPE ("the
approved finding cluster is fixed") does not bound it at all when each fix
reveals the next defect. Future review-correction iterations should be bounded by
ROUNDS or by budget, with a replan forced at the boundary, rather than by a
finding cluster that grows as it is worked.

## Triaged to the Next Replan

Recorded here because a drift-ledger entry alone is not a disposition
(maintainer instruction 2026-07-28). These carry a named owner and a required
action into the next replan; they are not closed by this iteration.

| Item | Severity | Required action at replan |
| --- | --- | --- |
| ~~DRIFT-198-I009-028 — recording a reviewer grant clobbers unrelated host policy~~ | ~~major, consumer-reachable~~ | **CLOSED 2026-07-29, not deferred.** The maintainer chose fixing over building deferral vocabulary to carry it. Now updates only the addressed row's `authorization_ref` (and an explicitly supplied model), preserving every other field and row; `reviewer-host-grant-write-scope.Tests.ps1` asserts other rows stay byte-identical and fails 4/4 against the old writer. |
| DRIFT-198-I009-029 — a verification command inherits the operator's ambient PATH | minor | Decide whether to distinguish an execution-environment failure from a command that ran and returned non-zero in the stable reason. The fail-closed behaviour and output privacy are correct and must not be traded away for diagnosability. |
| DRIFT-198-I009-020 — retroactive closeout has no first-class boundary crossing | minor | Specrew product backlog: give the verdict record an explicit subject distinct from the cursor it advances. |
| DRIFT-198-I009-021 — closure artifacts cannot express successor-iteration evidence | minor | Specrew product backlog: a concern-level disposition meaning "runtime evidence recorded by a named successor iteration". |
| AST-based structural enforcement via the PowerShell parser | **scheduled replan task — no longer an accepted residual** | Trigger fired TWICE (DRIFT-198-I009-037 too narrow a scan root; -040 too narrow a pattern), so the 2026-07-28 acceptance is withdrawn (maintainer decision 2026-07-29). The differential harness proves the primitive's ANSWERS and cannot police spellings across the tree; grep-based rules have now been widened three times, each after a real escape. Size a task using `[System.Management.Automation.Language.Parser]` to find dedup/comparison call sites structurally instead of textually. Explicitly NOT part of the final slice. |
| ~~DRIFT-198-I009-031 / -032 / -033~~ | ~~major~~ | **CLOSED 2026-07-29 as one slice**, per the maintainer's instruction, using the reviewer's specifics. -031: one containment choke point every mutator and both recursive deletes traverse, in canonical AND mirror. -032: probe measures inside the target from enumerated names, both spellings required. -033: Ordinal dedup and Ordinal ordering at all eight sites plus four more found in the extensions trees. |
| DRIFT-198-I009-034 — the gate cannot express a human deferral for a freshly discovered finding | **major governance-mechanism gap** | **Iteration 012 finality scope, explicitly** (maintainer decision 2026-07-29) — not the general backlog. Not needed for iteration 009 any more, because -028 was fixed rather than deferred, but any future iteration that ships with a known accepted defect hits this wall. Give the deferral record a subject that survives across campaigns and is surfaced to FRESH rounds, not only to carried prior-round findings. |
| Beta2 release claim if the surface will not stabilize | **decided in advance, deliberately** | If the differential harness shows the path-identity surface cannot stabilize before the tag, NARROW the beta2 release claim and document the known path-identity limitations rather than spending further review rounds. Beta is the correct vehicle for that honesty. Decided 2026-07-29 so it is not decided under time pressure at the tag. |

## Verification

- Focused unit/integration tests for T072–T078.
- Serial/parallel registry parity and repeated-green W2 proof.
- Full `tests/f198-regression-suite.ps1`.
- Iteration governance validation.
- Exact-commit hosted CI.
- Independent review of the exact candidate.
