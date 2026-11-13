# Quality Evidence: Iteration 002

**Profile Ref**: `quality-profile.pending`
**Preset Refs**: (pending preset selection)
**Findings Ref**: `specs/205-workshop-lens-order/iterations/002/quality/mechanical-findings.json`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-11-13T10:27:01Z

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| `dead-field` | mechanical quality bar, unused-state hygiene | `specs/205-workshop-lens-order/iterations/002/quality/mechanical-findings.json` | `planned` | `—` |
| `anti-pattern` | mechanical quality bar, deterministic anti-pattern scan | `specs/205-workshop-lens-order/iterations/002/quality/mechanical-findings.json` | `planned` | `—` |
| `test-integrity` | mechanical quality bar, assertion-driven tests | `specs/205-workshop-lens-order/iterations/002/quality/mechanical-findings.json` | `planned` | `—` |
| `stack-tooling-evidence` | stack tooling evidence | `specs/205-workshop-lens-order/iterations/002/quality/quality-evidence.md` | `planned` | `—` |
| `quality-lens-review` | quality-lens review | `specs/205-workshop-lens-order/iterations/002/quality/quality-evidence.md` | `planned` | `—` |

## T018 red first: `tests/unit/workshop-length-budget.tests.ps1` on today's tree

Run on 2026-11-13 at 19:35 local, on `6aaa946f` plus the new test file (no lens, skill or template change yet). The home
hook files were hashed before and after; both matched the known-good set of 10 files.

- Self-tests: 22 of 22 passed (lines not repeated below). They prove each failure the test can report: Light over 51
  points, Light over 18 replies, a changed Light recommendation-line count or Standard/Deep number, a consumer that is
  not a spec template line, not a later lens or not a consumer at all, a recommendation or hand-forward with no reason,
  a split suffix, a hand-forward key that product-domain does not define, and a question added without a suffix. All
  9 consumer problems in one fixture are reported in one run.
- The repository check reproduces the research page's baseline exactly (Light 50 points, 16 replies, 0 recommendation
  lines) and fails on the 5 recorded numbers that iteration 002 must reach. Exit code 1.
- The consumer check passes on today's tree: no lens carries a suffix or a hand-forward line yet.

```text
--- workshop-length-budget: self-tests ---
--- workshop-length-budget: repository check ---
Reference profile: product-domain, agenda, requirements-nfr, architecture-core, component-design, code-implementation, security-compliance, data-storage, integration-api
Per lens (Light points/replies/rec | Standard | Deep):
  product-domain             8/1/0 | 8/1/0 | 8/1/0
  agenda                     0/1/0 | 0/1/0 | 0/1/0
  requirements-nfr           6/2/0 | 6/2/0 | 6/2/0
  architecture-core          4/2/0 | 4/2/0 | 4/2/0
  component-design           5/2/0 | 5/2/0 | 5/2/0
  code-implementation        7/2/0 | 7/2/0 | 7/2/0
  security-compliance        6/2/0 | 6/2/0 | 6/2/0
  data-storage               7/2/0 | 7/2/0 | 7/2/0
  integration-api            7/2/0 | 7/2/0 | 7/2/0
Light    must-answer points 50 (recorded 51), typed replies 16 (recorded 16), recommendation lines 0 (recorded 18)
Standard must-answer points 50 (recorded 63), typed replies 16 (recorded 16), recommendation lines 0 (recorded 6)
Deep     must-answer points 50 (recorded 63), typed replies 16 (recorded 16), recommendation lines 0 (recorded 6)
Light caps: 51 points, 18 replies
workshop-length-budget: 5 problem(s):
  tests/unit/workshop-length-budget.tests.ps1:0: expected Light RecLines = 18 (recorded); found 0; fix: if the change is intended, update the recorded value in this test and in plan.md in the same change
  tests/unit/workshop-length-budget.tests.ps1:0: expected Standard Points = 63 (recorded); found 50; fix: if the change is intended, update the recorded value in this test and in plan.md in the same change
  tests/unit/workshop-length-budget.tests.ps1:0: expected Standard RecLines = 6 (recorded); found 0; fix: if the change is intended, update the recorded value in this test and in plan.md in the same change
  tests/unit/workshop-length-budget.tests.ps1:0: expected Deep Points = 63 (recorded); found 50; fix: if the change is intended, update the recorded value in this test and in plan.md in the same change
  tests/unit/workshop-length-budget.tests.ps1:0: expected Deep RecLines = 6 (recorded); found 0; fix: if the change is intended, update the recorded value in this test and in plan.md in the same change
EXIT 1
```
