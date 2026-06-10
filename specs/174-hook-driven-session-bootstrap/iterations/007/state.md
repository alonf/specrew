# Iteration State: 007

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T043 — hook applies the coordinator-surgery step (content-parity wiring); manager floor green + smoke-confirmed the user-profile/expertise line now injects
**Tasks Remaining**: T044 (inline-core), T045 (deploy-sync + mirror guard), T046 (side-by-side acceptance test), T047 (manual dogfood protocol + docs)
**In Progress**: T044 — inline the self-sufficient contract core in the injected directive
**Baseline Ref**: (iter-6 HEAD)
**Updated**: 2026-06-10T00:00:00Z

## Execution Summary

- **Iteration 007 opened as the iter-6 parity REWORK** (maintainer direction, 2026-06-10). iter-6 was sent
  back at review-signoff (parity disproven by a side-by-side); iter-6 closed honestly-qualified with the
  T035 generator extraction KEPT and parity deferred here.
- **Design pass authored** (`plan.md`), settling the maintainer's four points:
  - (a) TRACED the user-profile/coordinator content to `Invoke-SpecrewCoordinatorPromptSurgery`'s
    `-ExpertiseLine` step (between `Get-StartPrompt` and `Save-StartArtifacts`), which the iter-6 hook path
    skips. Fix = the hook applies the SAME surgery step (refinement: surgery-step reuse over a new
    `Get-StartPrompt` param — preserves "one generator, no drift"). Maintainer ruling wanted.
  - (b) DECIDED inline-the-contract for read-and-follow (the test agent never read the file). Maintainer
    ruling wanted on inline-everything vs inline-core-with-file-reference.
  - (c) Both layers together: self-host surgery+inline AND deploy-source sync (port the module provider into
    the iter-4 extension-source copy + a mirror-parity guard).
  - (d) Acceptance gate = the side-by-side (automatable content-diff in a deployed layout + a manual
    read-and-follow dogfood); T038 demoted to a supporting check.
- **Bookkeeping done this turn:** the T042 `specrew start` repositioning reverted in `docs/getting-started.md`
  (hook ORIENTS not drives; `specrew start` is THE contract driver) — stays reverted until the side-by-side
  passes.

- **T043 DONE** (content-parity wiring): the hook path (`Write-SpecrewLaunchContractArtifact`) now applies
  the SAME `Invoke-SpecrewCoordinatorPromptSurgery` step `specrew start` does — `-ExpertiseLine
  (Get-SpecrewProfileOrientationLine)` + host/runtime/lifecycle/feature/boundary — after `Get-StartPrompt`;
  provider dot-sources coordinator-prompt-surgery.ps1 + user-profile.ps1 (3-tier); `-HostKind` param added
  (default claude). Smoke-confirmed the user-profile/expertise line ("expert on Software Architecture") now
  appears in the hook's contract (the iter-6 gap); LaunchContractWrite floor green (all 7 invariant markers
  survive the surgery — no regression). HONEST scope: proves the surgery INJECTS the content in the dev tree
  — NOT full parity (T046 side-by-side is the arbiter), NOT read-and-follow (T044 + the manual dogfood), NOT
  deployed (T045 sync + the surgery's per-host-rules deployed resolution).

## Notes

- Rulings (a)/(b)/(c)/(d) settled at before-implement; plan validator-green (EXIT 0). Capacity 18/20 (SPLIT,
  do not exceed).
- Next: T044 inline-core → T045 deploy-sync + mirror guard → T046 side-by-side acceptance test → T047 manual
  dogfood protocol. Parity is NOT re-claimed until the side-by-side (incl. the manual dogfood) passes.
