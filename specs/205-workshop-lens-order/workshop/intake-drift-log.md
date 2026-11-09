# Intake drift record: 205-workshop-lens-order

## DRIFT-205-INTAKE-001 — co-review retry test failed once in the Deterministic gate on a docs-only commit

**Observed**: 2026-11-09 (local 2026-11-10 00:55), Specrew CI run 42715079692, attempt 1, on commit `700e6127`.

**Evidence**:

- In the Deterministic gate job, the "F-198 honesty regression suite (NFR-007)" step failed 1 of 131 files: `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1`, case "retries once and recovers when the second attempt produces the result". The exact assertion was: `Expected regular expression '"run_id":"t108"' to match <empty>, because the retry recovered the result, but it did not match.`
- The Contract lane was skipped as a consequence.
- `700e6127` changed only `specs/205-workshop-lens-order/` documents and four `.squad` state files written by the specify sync. No script or test changed.
- The same suite passed in Specrew CI run 42713878979 on `7a4e6d7a`, about an hour earlier.

**Impact**: a red gate on a commit that cannot have caused it. Clarify was held until the maintainer decided.

**Disposition**: the maintainer approved one rerun of the failed jobs, with no further reruns if it fails the same way. Rerun result: attempt 2 of run 42715079692 concluded **success**. Deterministic gate, Lint, Self-leak firewall and Contract lane all passed, and no job was skipped. A single failure that passes on rerun with an unchanged tree points to an intermittent test, which this record does not prove.

**Not this feature's to fix.** The test belongs to the continuous co-review engine. The finding is a candidate for `docs/beta5-findings.md`, filed under the next free B5F id after feature 203 merges, since 203's branch owns ids B5F-016 to B5F-036 and editing that register here would collide with it.

## DRIFT-205-INTAKE-002 — specify-sync claim with user@machine was committed and pushed

**Observed**: 2026-11-10. Commit `700e6127` (pushed to origin `205-workshop-lens-order`, public repo) includes `.squad/active-features.yml`. The specify sync added a 205 claim with `claimed_by: "alon@ALONBLADE"`, which is the B5F-022 shape. main already carries ten claims in that form.

**Disposition (maintainer, option 1)**: `700e6127` is left as it is. `.squad/active-features.yml` is not committed again on this branch. If a boundary step refuses to run while that file is uncommitted, the crew stops and asks, and does not commit the file to get past the step. The identity fix belongs to B5F-022 (the 203/204 line).

## DRIFT-205-INTAKE-003 — B5F-005 recurred: a stale working directory produced a wrong-cause refusal

**Observed**: 2026-11-10, while closing the code-implementation lens. `confirm-workshop-lens.ps1 -ProjectRoot .` was invoked while the process working directory was `specs/205-workshop-lens-order` (the PowerShell location had been reset to the root, but the .NET current directory had not). It refused with "This feature has no recorded workshop plan yet ... confirm its agenda first", although the agenda was confirmed. Retrying once with an absolute `-ProjectRoot` closed the lens. This is the same shape as B5F-005 (already recorded on main). No new finding, recurrence evidence only.
