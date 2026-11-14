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

## T025 green, regression and copies

Run on 2026-11-13 between 19:50 and 20:00 local. The home hook files (10) were hashed and backed up to the session
scratchpad before the run; they matched the known-good set before and after every step.

- **Copies**: refreshed with `deploy-speckit-extension.ps1 -ProjectPath . -RefreshExisting` and
  `deploy-squad-runtime.ps1 -ProjectPath .` (home clean before, between and after). The restamps they made outside
  this task (the `.squad` charters, ceremonies, routing, team, `.github/agents/squad.agent.md` line endings, and
  the version stamp of `scripts/internal/continuous-co-review/.specrew-runtime.json`) were restored by exact path.
  In `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json` only the nine refreshed copies' hashes
  change, each checked against its file; the version stamp stays at `0.40.0-beta4` as iteration 001 left it.
- **Extractor counts (SC-010)**: `lens-order-parity.tests.ps1` expects each touched lens's count to grow by exactly
  its added questions: requirements-nfr 6 to 9, ui-ux 6 to 7, security-compliance 6 to 8, data-storage 7 to 10,
  integration-api 7 to 9, devops-operations 7 to 8; the other five unchanged. **lens-order-parity: all checks passed**
  (5 full surfaces, 428 swept files, 11 lens files, 22 deployed copies).
- **CI step**: `Workshop length budget and question consumers (FR-028/FR-029)` added to `specrew-ci.yml`.
- **Workshop regression**: the same screened set as iteration 001's T017 baseline (every workshop, lens, agenda,
  design-analysis, product-domain and code-implementation test), plus the new test: **32 of 32 PASS**.

| Test | Result | Time |
| --- | --- | --- |
| `tests/bootstrap/HandoverGateWorkshop.Tests.ps1` | PASS | 1s |
| `tests/bootstrap/WorkshopDecisionRecap.Tests.ps1` | PASS | 1s |
| `tests/bootstrap/WorkshopHostDetection.Tests.ps1` | PASS | 12s |
| `tests/integration/agent-led-workshop-replay.tests.ps1` | PASS | 72s |
| `tests/integration/design-analysis-boundary.tests.ps1` | PASS | 24s |
| `tests/integration/design-workshop-claude-tool-safety.tests.ps1` | PASS | 8s |
| `tests/integration/governed-feature-workshop-controller.tests.ps1` | PASS | 3s |
| `tests/integration/product-domain-multihost.tests.ps1` | PASS | 1s |
| `tests/integration/specify-workshop-routing.tests.ps1` | PASS | 5s |
| `tests/integration/workshop-agenda-confirmation.tests.ps1` | PASS | 20s |
| `tests/integration/workshop-agenda-vocabulary.tests.ps1` | PASS | 6s |
| `tests/integration/workshop-controller-initialization.tests.ps1` | PASS | 1s |
| `tests/integration/workshop-intake-completion-survives-agenda.tests.ps1` | PASS | 1s |
| `tests/integration/workshop-lens-checkpoint.tests.ps1` | PASS | 16s |
| `tests/integration/workshop-material-packet-language.tests.ps1` | PASS | 15s |
| `tests/integration/workshop-resolve-prefers-open-feature.tests.ps1` | PASS | 3s |
| `tests/integration/workshop-state-transition-table.tests.ps1` | PASS | 1s |
| `tests/integration/workshop-typed-turn-authority.tests.ps1` | PASS | 5s |
| `tests/unit/code-implementation-lens.tests.ps1` | PASS | 1s |
| `tests/unit/cross-host-workshop.tests.ps1` | PASS | 29s |
| `tests/unit/design-analysis-gate-refusal.tests.ps1` | PASS | 1s |
| `tests/unit/design-analysis-gate.tests.ps1` | PASS | 2s |
| `tests/unit/design-gate-code-implementation-artifact.tests.ps1` | PASS | 1s |
| `tests/unit/lens-acknowledgment.tests.ps1` | PASS | 1s |
| `tests/unit/lens-applicability-selector.tests.ps1` | PASS | 1s |
| `tests/unit/lens-conduct-delivery.tests.ps1` | PASS | 1s |
| `tests/unit/product-domain-lens.tests.ps1` | PASS | 1s |
| `tests/unit/workshop-confirm-not-bound.tests.ps1` | PASS | 4s |
| `tests/unit/workshop-delegation.tests.ps1` | PASS | 50s |
| `tests/unit/workshop-length-budget.tests.ps1` | PASS | 1s |
| `tests/unit/workshop-question-tool.tests.ps1` | PASS | 1s |
| `tests/unit/workshop-refusal-contract.tests.ps1` | PASS | 1s |

The length test, green on the tree:

```text
--- workshop-length-budget: self-tests ---
--- workshop-length-budget: repository check ---
Reference profile: product-domain, agenda, requirements-nfr, architecture-core, component-design, code-implementation, security-compliance, data-storage, integration-api
Per lens (Light points/replies/rec | Standard | Deep):
  product-domain             9/1/5 | 14/1/0 | 14/1/0
  agenda                     0/1/0 | 0/1/0 | 0/1/0
  requirements-nfr           6/2/4 | 9/2/1 | 9/2/1
  architecture-core          4/2/0 | 4/2/0 | 4/2/0
  component-design           5/2/0 | 5/2/0 | 5/2/0
  code-implementation        7/2/0 | 7/2/0 | 7/2/0
  security-compliance        6/2/4 | 8/2/2 | 8/2/2
  data-storage               7/2/5 | 10/2/2 | 10/2/2
  integration-api            7/2/3 | 9/2/1 | 9/2/1
Light    must-answer points 51 (recorded 51), typed replies 16 (recorded 16), recommendation lines 21 (recorded 21)
Standard must-answer points 66 (recorded 66), typed replies 16 (recorded 16), recommendation lines 6 (recorded 6)
Deep     must-answer points 66 (recorded 66), typed replies 16 (recorded 16), recommendation lines 6 (recorded 6)
Light caps: 51 points, 18 replies
workshop-length-budget: all checks passed
```

## T026 recorded Light workshop run (SC-012)

The run, who answered, the SC-012 results, the counts against the budget and what the run found are in
[t026-recorded-run.md](t026-recorded-run.md); the visible transcript is [t026-transcript.md](t026-transcript.md), and
the scratch feature's records are in [t026-records/](t026-records/). The four replies were sent by the reviewer session,
each confirmed by the maintainer first (DRIFT-011). This pass: 17 must-answer questions shown (budget 21), 4 typed
replies (budget 6), 13 recommendation lines (budget 13). The home hook files matched the known-good set before and after.

## Review round 1 findings fixed (DRIFT-018)

The three round 1 findings in `tests/unit/workshop-length-budget.tests.ps1` were each fixed failing test first:

| Finding | Red commit | Self-tests failing | Fix commit |
| --- | --- | --- | --- |
| 1. SC-009 checked fact by fact (the reviewer's swap leaves every total unchanged) | `8347d9d5` | 6 | `598d0836` |
| 3. A `lens:` consumer must receive the answer | `3a13eaa4` | 4 | `22c0a583` |
| 2. Exempt questions by identity, not count | `335de732` | 3 | `398e9520` |

After the fixes, every self-test passes and the shipped lens files pass unchanged.
