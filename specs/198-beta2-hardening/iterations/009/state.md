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

The verifying review `run-f198-i009-5117c807-codex` then completed against digest
`9d21b1dbc02058471369555e0ffd5333d672b41b` with containment verified, validation
valid, currentness current, and completion complete. It accepted the machinery
classification and containment corrections and reported three further defects,
all in the path-identity class and each one level deeper than the fix before it:
DRIFT-198-I009-015 (blocking; case semantics read from the OS family rather than
the volume, which the DRIFT-198-I009-012 correction itself introduced),
DRIFT-198-I009-016, and DRIFT-198-I009-017.

The maintainer then authorized the systematic sweep. DRIFT-198-I009-027 found the ROOT CAUSE of the
whole non-convergence pattern — a same-named duplicate function shadowing the path-identity
primitive, so every call site "routed through the primitive" was still receiving the OS-family
answer. Rounds 4 and 5 (`run-f198-i009-aab37c3b-codex-2`, `run-f198-i009-2c6d7cb8-sweep`) produced
DRIFT-198-I009-022 through 026 and 030, all corrected, the last of them applying the sweep to the
canonical `extensions/` source rather than only the deployed mirror, plus a mirror-parity guard.

The re-certification round `run-f198-i009-0e0048b0-recert` completed on 2026-07-29 against digest
`bd2c663aa19da364f2a5f3746ed58154663a923b` under authorization
`recertification-i009-canonical-2026-07-29`: containment verified, validation valid, currentness
current, completion complete, termination verified, and both controller verification commands green.
It is NOT a clean certification — four major findings, `can_approve_current: false`. One,
`finding-e78c294017b6e4fb`, is the expected DRIFT-198-I009-028 recurrence the maintainer pre-authorized
as a recorded deferral. Three are new and confirmed in source: DRIFT-198-I009-031 (the deployment
containment guard is called from one mutator of five), DRIFT-198-I009-032 (the volume probe misreads
the target — the third defect in that same function), and DRIFT-198-I009-033 (`-CaseSensitive` is
culture-aware, not ordinal, at eight sites). DRIFT-198-I009-034 records that the gate has no
disposition able to express the authorized deferral, so it cannot be honoured without either fixing
DRIFT-198-I009-028 or extending the vocabulary.

T079 remains in-progress; no closeout packet was presented at that point. The three focused
path-identity suites passed 39/39 at `0e0048b0` — including the test written for the exact scenario
DRIFT-198-I009-032 describes — which is recorded as evidence that focused green cannot falsify this
class.

## Instrument change and the one-slice correction (maintainer decision, 2026-07-29)

The maintainer ruled that review-and-fix rounds are no longer the certification instrument for the
path-identity surface: **the oracle becomes the volume.** All four findings were then fixed as ONE
slice using the reviewer's specifics, rather than as another point-fix round.

Delivered:

- **DRIFT-198-I009-028** — fixed rather than deferred (cheaper than deferral vocabulary, and
  consumer-reachable major in its own right). Recording a grant now updates only the addressed row's
  `authorization_ref` plus an explicitly supplied model. `reviewer-host-grant-write-scope.Tests.ps1`
  fails 4/4 against the old writer and passes 4/4 against the fix.
- **DRIFT-198-I009-031** — `Assert-ManagedMutationAllowed` is one containment choke point traversed by
  all five mutators and both recursive host-skill deletes, in the canonical `extensions/` tree AND the
  `.specify/extensions/` mirror. A structural test enumerates the mutators in both trees.
- **DRIFT-198-I009-032** — the probe measures inside the physical target using ENUMERATED names and
  requires both spellings before concluding two real siblings exist; its memo cache is now Ordinal
  rather than case-folding.
- **DRIFT-198-I009-033** — Ordinal dedup and Ordinal ordering at all eight reported sites plus four
  more found in the extensions trees (`conformance-turn-delta.ps1`, `validate-governance.ps1`, both
  copies). The structural test that had ACCEPTED `-CaseSensitive` now rejects `Sort-Object -Unique`
  over paths outright.
- **The differential volume harness** — `path-identity-volume-differential.Tests.ps1` creates real
  fixture trees (case-distinct siblings, case-flipped lookups, composed vs decomposed Unicode) and
  asserts the primitive against the OS's observed enumeration behavior, wired into the three-OS matrix
  in `cross-platform-validation.yml`. Validated by falsification: 3 of 6 fail against the pre-fix
  primitive, 6 of 6 pass against the corrected one. Its FIRST revision did not fail, because the old
  case-folding memo cache served the second probe from the first probe's key — recorded under
  DRIFT-198-I009-032 as the clearest available argument for measuring rather than asserting.

DRIFT-198-I009-015 and -016 are now resolved: routing and answer both hold, with the honest residual
that local proof is Windows/NTFS only and the macOS case (POSIX host, case-insensitive volume — the
combination this class was reported for) is proven only when the three-volume CI job runs.

Also recorded: DRIFT-198-I009-034 moves into **iteration 012's finality scope** explicitly; AST-based
enumeration is backlog because the harness dominates it; iteration 009's actual capacity is restated
honestly in plan.md at roughly **70 SP against a 20 SP capacity**, with the bounding lesson that a
"fix what the reviewer finds" iteration cannot be bounded by scope; and the **fallback is decided in
advance** — if the harness shows the surface cannot stabilize before the tag, the beta2 release claim
narrows and the limitations are documented rather than spending further rounds.

Two further findings came out of executing the slice, both recorded: DRIFT-198-I009-035 (a port
scriptblock cannot resolve ambient function names — caught by the registry, not by review or by the
focused suites, and a concrete limit on what the new instrument certifies: the harness proves the
primitive's ANSWERS, not that every caller can reach it) and DRIFT-198-I009-036 (the registry's
caller-contamination guard correctly fired on a concurrent edit made while it ran in the background —
a process lesson, not a product defect).

## Final slice and the agreed termination rule (maintainer decision, 2026-07-29)

The certifying review `run-f198-i009-f738f5cf-certify` completed against digest `0e912d6d` with
containment verified, validation valid, currentness current, completion complete, and both controller
verification commands green — but did NOT certify: two findings,
`can_approve_current: false`. DRIFT-198-I009-039 (blocking) found that the three-OS lane designated as
the certification instrument gated on `FailedCount` alone, so a `BeforeAll`/`AfterAll` container
failure left a leg green with the measurement absent; DRIFT-198-I009-040 (major, consumer-reachable)
found `Sort-Object FullName -Unique` folding file identities in a shipped consumer scanner, in a
spelling the structural rule could not see.

The maintainer approved one final hard-scoped slice: the lane rule becomes `Result -eq 'Passed'`
(the rule `tests/f198-regression-suite.ps1:209-211` already used), the two dedup sites are fixed in
BOTH trees, and the structural pattern is widened.

**Termination rule, agreed in advance:** if that final round reports ANY new blocking or major finding
of this class — in these fixes or anywhere else — execution stops and the beta2 release claim narrows
per the pre-decided fallback. Note-severity findings become recorded residuals and do not block
certification. **There is no round nine.**

Also decided: the "grep-based, not AST-based" residual is withdrawn as an accepted residual after its
trigger fired twice, and becomes a scheduled replan task for AST-based enforcement via the PowerShell
parser — explicitly not part of this slice. And the direct-reading habit stands: even with the lane
rule fixed, the `[volume-oracle]` measurements are to be read out of the job logs rather than inferred
from a green conclusion.

Certification evidence status against the maintainer's 2026-07-29 bar:

| Required | Status |
| --- | --- |
| Differential harness green on all three CI volumes | **outstanding** — green locally on Windows/NTFS; needs the pushed `cross-platform-validation.yml` matrix run for ext4 and APFS |
| Registry green | **met** — all 82 suites green in 566.6s at a quiescent tree |
| ONE certifying review | **outstanding** — not yet requested; no slot spent since `run-f198-i009-0e0048b0-recert` |

Execution was previously paused after round 3. Four consecutive rounds had found path-identity defects,
and direct measurement shows four OS-family case shortcuts and twelve or more
files carrying independent path comparison, wildcard, or dedup logic. There is
no single path-identity primitive, so point corrections can only ever repair the
site the reviewer happened to reach. The convergence assessment and the durable
correction are recorded in drift-log.md and await the human's decision; the
authorized slot is spent.
