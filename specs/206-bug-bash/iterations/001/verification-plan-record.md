# Feature 206's Review Plan: The Record

Approved by the maintainer on 2026-11-13 (option 1). The review round reads only `.specrew/verification-plan.json`
(`review-target-port.ps1:160, 328`), so the tracked file changed:

- `.specrew/verification-plan.json` now names 206's five lanes (plan id `f206.i001.review.v1`), in `54fcfc1c`.
- The ten lanes it named at the branch base `d3e33550` (feature 202's six, feature 199's four) are parked unchanged in
  `.specrew/verification-plan.signoff-lanes.json`, to be restored for the signoff round. The lane guard reads that
  file, so their suites stay named, and it checks that the parked lanes equal the base's (RED 3/58 in `f5dc847b`,
  GREEN in `54fcfc1c`).

| Lane | Runs | Limit | Measured (Windows, alone) |
| --- | --- | --- | --- |
| `f206-unit-suites` | the 8 Pester suites 206's tasks wrote (T001, T002, T003, T006, T008, T009, T011, T012) | 1200 s | 408 s |
| `f206-changed-integration` | `closed-iterations-are-history`, `non-specrew-session-bypass` | 120 s | 23 s |
| `f206-census-guard` | the lane guard on the test census, and `full-sweep-direct-exit` | 120 s | 9 s |
| `f206-governance-206` | `validate-governance.ps1` on `specs/206-bug-bash/iterations/001` | 120 s | 14 s |
| `f206-deployed-hash-record` | every file under `.specify/extensions/specrew-speckit/` against its hash record | 60 s | 1 s |

Total 455 s. The home hook files and the repository were unchanged after each lane.

Left out: all ten base lanes (features 202 and 199; two of them run files on the maintainer's not-run list), the 16
home-writing files, and the 206-touched scripts that are not 206's own suites (the 23 per-push scripts CI runs on
every push, `validator-hardening-iteration2.ps1`, red for SC-002, and `project-path-resolution-regression.ps1`, which
refuses to run).

## Not a Lane: `validate-governance-changed-only.tests.ps1`

Six tasks changed the validator: T002 `6acb84aa`, T006 `4c543c1a` and `ba2d1d8b`, T008 `ad31b2d5`, T009 `54cb8e18`
and `3b5dcadf`, T011 `85f62dc4`, T012 `ff0e78b9`. This suite covers the validator's scoping and is not a lane (about
13 minutes; release cadence).

- **Last green: 2026-11-13, on `cb9e8eca`**, after the last validator change (`ff0e78b9`): 14 of 14, 757 s, run alone,
  home hook files unchanged, repository unchanged.
- Before that, every green run was during a task, on an uncommitted fix tree. The last one was 2026-11-12 04:53, on
  T012's RED commit with T012's fix not yet committed.

## T002's Unix Evidence

By the maintainer's option (a), `tests/unit/overclaim-dirty-check-separator.tests.ps1` runs in Specrew CI's per-push
step on Ubuntu, through Pester (`6b2fa5e1`). Green on the runner: Specrew CI run 43411715314 (attempt 2) on `75ddb2b9`,
job 131847705487, "3 passed, 0 failed in 310 s". T002 is done. The 310 s on the runner adds to the step's per-push time
(the 23 scripts took 123 s on the first T015 run).
