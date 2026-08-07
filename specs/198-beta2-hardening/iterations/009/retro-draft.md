# Retrospective: Iteration 009

**Feature**: 198-beta2-hardening
**Iteration**: 009
**Closed**: 2026-07-30
**Disposition of record**:
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md

## What Went Well

**The root cause was found, and it explains five rounds at once.** DRIFT-198-I009-027 — a
same-named duplicate function shadowing the path-identity primitive, declaring no
`param()` block so it silently swallowed the arguments its callers passed. Every call site
"routed through the primitive" was still getting the OS-family answer. It was invisible at
every individual call site and only enumerating definitions across the tree exposed it.
That is why five rounds of locally-correct point fixes could not converge.

**The certification instrument changed from opinion to measurement.** The differential
harness creates real fixture trees and asserts the primitive against the OS's observed
enumeration behaviour. Nothing in it is authored; nothing is skipped for platform. On a
three-OS matrix the same assertions have different measured right answers.

**The instrument was proven able to fail before being trusted.** The mutation gate runs the
harness against deliberately-broken primitives and requires failures. This mattered
concretely: the harness's FIRST revision passed against a broken probe, because the old
case-folding memo cache served the second probe the first probe's answer. Isolating each
spelling per fixture is what made it capable of failing at all.

**Findings were verified before acceptance, and corrections went wider than the report when
measurement justified it.** -033 was reported at one line; measurement found eight sites
plus four more in the extensions trees. -037's fix widened a scan root and immediately
exposed a seventh OS-family site on a delete-authorizing path.

## What Didn't Go Well

**Every fix was a candidate defect.** -026 was introduced by -018. -032 was introduced by
-026. -042 was introduced by -032. -039 and -040 landed on instrumentation written the same
day. The dominant cost was not finding defects but not introducing them while fixing.

**"Green" meant three different things and I conflated them.** The registry did not contain
the path-identity family (so "82 suites green" was true through six rounds of path-identity
defects); the bootstrap suites run in a separate CI step the registry does not enumerate;
and markdownlint is a third gate. Three CI-only failures were discovered by pushing, each
right after declaring a locally-assembled gate clean.

**A single point of truth becomes a single point of total failure.** Centralising every path
decision on one primitive removed "every call site re-decides" and replaced it with a
comparer that, when wrong, is wrong everywhere at once — containment, authority store,
verification paths, machinery, digests. Four of this primitive's defects were about
*reaching* it correctly, not about its logic.

**Concurrency discipline cost a wasted run.** Editing artifacts while the registry ran in
the background tripped the caller-contamination guard, producing a failure that looked like
a regression at first glance.

## Lessons learned

1. **Bound review-correction iterations by ROUNDS or BUDGET, never by scope.** "The approved
   finding cluster is fixed" does not bound anything when each fix reveals the next defect.
   This is the transferable lesson: 70 SP delivered against a 20 SP capacity, ~3.5x, because
   the scope was defined by what the reviewer had not looked at yet.
2. **A test that cannot fail proves nothing.** Verify falsifiability by running the check
   against known-broken input. Pin historically-escaped inputs so a matcher cannot be
   silently narrowed — this rule was widened three times, each after a real escape.
3. **Read the gate, don't infer it.** The gate is what the workflow files execute. Assembling
   a plausible local subset produced three consecutive false "clean" declarations.
4. **Enumerate the definition space, not the call sites.** A shadowing duplicate, a too-narrow
   scan root, and a too-narrow pattern all hid defects that per-site inspection could not see.
5. **An oracle is only as good as the state space its fixtures span.** "The volume is the
   oracle" was right and still missed dangling links, because no fixture had one.
6. **Read measurements directly, even from a green run.** A passing Pester line does not say
   which assertion branch executed. Emitting the measurement per leg is what makes a
   three-volume matrix mean something.
7. **Terminal ≠ done.** A task whose verification ran green but whose certification failed is
   `deferred`, not `done`. Recording it otherwise would assert confidence the evidence does
   not support.

## Estimation Accuracy

| Measure | Value |
| --- | --- |
| Stated capacity | 20 SP |
| Planned (T072–T079) | 24.5 SP — already over capacity at plan time |
| Delivered | on the order of **70 SP** |
| Variance | **~3.5x** against capacity, ~2.9x against plan |

The variance is not an estimation error in the ordinary sense. T072–T078 were estimated at
19.5 SP and delivered at 19.5 SP — those estimates were accurate. The entire overrun sits in
T079, estimated at 4.5 SP and consuming roughly 50, because its scope was "correct the
defects an independent reviewer finds" and that has no knowable size at plan time.

Breakdown of the unplanned work, none of which was estimable when the plan was written:

| Unplanned work | Rough SP |
| --- | --- |
| DRIFT-198-I009-001 through -014 corrections (rounds 1–3) | ~12 |
| -018 / -019 loader scope and the reverted ignore filter, incl. three CI cycles on a hang that never existed | ~5 |
| -022 through -026 (round 4), one of them introduced by -018 | ~8 |
| -027, the shadowing duplicate — the root cause, found by directed sweep | ~4 |
| -030 canonical vs mirror | ~3 |
| -031 / -032 / -033 plus the differential harness and mutation gate | ~8 |
| -037 / -039 / -040 / -041 / -042 and the final slice | ~6 |
| Review infrastructure repair (-008, -009, -029) and eight paid rounds | ~6 |

**Calibration signal**: estimate review-correction work by ROUNDS, not by story points over
a finding cluster. A round has a knowable cost; a cluster that grows as it is worked does not.

## Drift Summary

Forty-three drift entries were recorded in this iteration
(file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/drift-log.md).
By disposition at closeout:

| Disposition | Count | Notes |
| --- | --- | --- |
| Resolved with runtime evidence | 30 | Includes -027, the root cause of five non-converging rounds |
| Open, carried to Iteration 010 | 3 | -041, -042 (both major), -043 (minor residual) |
| Open, carried to Iteration 012 | 1 | -034, deferral vocabulary |
| Open, product backlog | 3 | -020, -021, -029 |
| Recorded residuals / process notes | 6 | Incl. -036 (contamination guard), -038 (registry ≠ CI) |

By class, which is the more useful cut:

- **Cross-platform path identity** — the dominant class: -010, -012, -015, -016, -017, -018,
  -019, -023, -024, -026, -030, -032, -033, -037, -040, -042. Root cause -027.
- **Path containment** — four appearances: -011 (deletion), -025 (managed write), -031
  (deployment mutators), -041 (authority store). Each correction guarded the door the
  reviewer had reached.
- **Review-gate and evidence integrity** — -007, -008, -009, -022, -034, -035, -038, -039.
- **Candidate membership / hygiene** — -013, -014, -028.

**The signal in the shape**: four defects were introduced by this iteration's own
corrections (-026 by -018, -032 by -026, -042 by -032, and -039/-040 on instrumentation
written the same day). That is what ended the campaign, not any single defect.

## Improvement Actions

| Action | Owner | Vehicle |
| --- | --- | --- |
| Bound review-correction iterations by ROUNDS or BUDGET, with a replan forced at the boundary — never by a finding cluster | Planner | Iteration 010 planning boundary |
| Fix authority-store containment (-041) as the first task; it touches the evidence chain itself | Implementer | Iteration 010, first task |
| Make the case probe link-aware (-042) alongside -041 | Implementer | Iteration 010 |
| Add link-state fixtures to the differential harness, and the case-distinct firewall fixture (-043) | Implementer | Iteration 010 |
| Replace grep-based structural rules with AST enforcement via the PowerShell parser | Implementer | Scheduled replan task |
| Give the review gate a deferral disposition that reaches fresh rounds (-034) | Implementer | Iteration 012 finality scope |
| Establish one local command that runs exactly what CI runs (lint + registry + bootstrap), or state per-claim that "registry green" excludes them | Reviewer | Iteration 010 |
| Use `validate-governance.ps1 -IterationPath <dir>` for closeout checks — 11s scoped versus 440s unscoped | Reviewer | Immediate, adopted |

## Process Notes

- **Run the governance validator scoped, early, and before committing a closeout.** The
  unscoped run costs 440s and discourages iteration; `-IterationPath` costs 11s. Two closeout
  defects (a stale `plan.md` status, four missing reviewer artifacts) were caught only
  because the validator ran before the commit rather than after.
- **The registry requires a quiescent tree.** Editing artifacts while it runs in the
  background trips the caller-contamination guard and produces a failure that reads like a
  regression (-036).
- **Filter tool output carefully.** Piping a long run through `Select-String` twice discarded
  the very detail needed to diagnose a failure, costing a re-run each time.
- **Read measurements directly even from green runs.** A passing Pester line does not reveal
  which assertion branch executed; emitting per-leg measurements is what makes a three-volume
  matrix meaningful.
- **Eight paid review rounds** were spent, plus two that failed pre-spend and correctly
  consumed no provider budget. Spend accounting closed balanced.

## Signals for the next iteration

- **Iteration 010 opens with containment-class #4** (DRIFT-198-I009-041) in the authority
  store — the store holding the evidence chain for all eight rounds. Its sibling -042 lands
  alongside because a hardened store behind a wrong comparer is not hardened.
- **Test coverage for link states is the gap to close first**, not more comparison sites:
  -042 and -043 are both fixture-coverage defects, and limitation 3 of the narrowed claim
  names the same hole.
- **The grep-based structural residual is withdrawn**; AST-based enforcement via the
  PowerShell parser is scheduled. Three widenings after three escapes is enough evidence.
- **Watch for the "fix introduces the next defect" pattern early.** If Iteration 010's first
  correction produces a finding in itself, treat that as the signal it was here — the loop is
  not converging — rather than spending rounds to rediscover it.
- **The narrowed claim is a live document.** If -041/-042/-043 land in 010, limitations 1-4
  should be revised there rather than left standing.
