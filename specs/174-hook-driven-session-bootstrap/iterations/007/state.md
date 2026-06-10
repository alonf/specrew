# Iteration State: 007

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T047 — manual dogfood protocol written + getting-started honesty sweep finished. ALL iter-7 tasks T043–T047 code-complete + automated-verified.
**Tasks Remaining**: (none in code) — the MANUAL DOGFOOD (the gate's disqualifier, Ruling Prompt 3) is the maintainer's to run at review-signoff; parity is NOT re-claimed until it passes.
**In Progress**: review-signoff stop — presenting the implementation for the verdict, with the manual dogfood as the outstanding gate item
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
- **T044 DONE** (read-and-follow / inline): `Format-BootstrapDirective` now INLINES the contract body into
  the injected directive (the provider captures the path, reads the body, passes it); the skip-inducing
  "READ {file} BEFORE acting" framing is replaced by an in-context contract bracketed by BEGIN/END markers,
  with the file kept as the durable reference. Smoke: directive ~47 KB, the coordinator framing + the
  "expert on Software Architecture" line now in-context, the READ-before-acting skip GONE; all 4 bootstrap
  tests green. **Design decision (within Ruling b):** the contract's parity-relevant content is interleaved
  (coordinator head L1-8, expertise L198 inside rule 48, gates in the quick-ref/rule 46), so a clean
  lead-up-core line-extraction would be fragile and risk deferring parity content — I inlined the FULL
  contract (= exactly what `specrew start`'s agent reads; the safe "expand toward full" end of the ruling),
  with the file as the re-consult reference. The side-by-side (T046) is the arbiter; a leaner core (trimming
  the artifact-template tail) is a safe follow-optimization if size warrants. HONEST: proves the directive
  CARRIES the contract in-context — NOT that the agent reads+follows it (that is the manual dogfood gate).
- **T045 DONE** (deploy-source sync + mirror guard, deployed-verified): synced the EXTENSION-SOURCE provider
  (`extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1`) to be BYTE-IDENTICAL to the MODULE
  copy (both 148 lines) — so deploy-speckit-extension now ships iter-7 (T036/T037/T043/T044), not the iter-4
  stub. Added `tests/bootstrap/ProviderMirrorParity.Tests.ps1` (asserts byte-identity + the iter-7 markers,
  line-ending-normalized) so the divergence cannot recur silently. DEPLOYED GROUND-TRUTH (the proof T038
  missed): deploy this branch into a fresh Spec-Kit project → deployed provider iter6=True →
  last-start-prompt.md WRITTEN → the contract INLINED in the deployed directive (all False/absent before the
  sync). HONEST: the deploy LAYER gap is closed (the deployed provider executes iter-7); full content PARITY
  (T046) + read-and-follow (the manual dogfood) remain the gate.
- **T046 DONE** (side-by-side, automatable half — GREEN): `tests/integration/contract-parity-side-by-side.tests.ps1`
  asserts the hook's written contract is BYTE-IDENTICAL to specrew start's generation path (`Get-StartPrompt`
  and `Invoke-SpecrewCoordinatorPromptSurgery`, reconstructed from specrew-start.ps1 L3332-3356) plus the parity
  content present (expertise line, coordinator framing, 7 invariant markers). `specrew start` needs
  `specrew init` (a full launcher in a test is fragile), so the reference encodes the launcher's GENERATION
  pattern independently of the hook — any divergence is a real parity gap. HONEST: proves the CONTRACT is
  equivalent, NOT that the agent reads+follows it (the manual dogfood, T047).
- **T047 DONE** (manual dogfood protocol + docs sweep): wrote `manual-dogfood-protocol.md` (the gate's
  disqualifier per Ruling Prompt 3 — the maintainer runs the hook-vs-`specrew start` lead-up comparison; PASS
  only if the hook session's agent renders the coordinator contract + expertise adaptation + drives the
  lifecycle on its first reply, matching `specrew start`). Finished the getting-started honesty sweep (the
  "Direct launch on Claude" bullet now states content-parity is automated-verified but read-and-follow is
  under manual verification — prefer `specrew start` until the side-by-side passes).

## Notes

- Rulings (a)/(b)/(c)/(d) settled at before-implement; plan validator-green (EXIT 0). Capacity 18/20 (SPLIT,
  do not exceed).
- Next: T044 inline-core → T045 deploy-sync + mirror guard → T046 side-by-side acceptance test → T047 manual
  dogfood protocol. Parity is NOT re-claimed until the side-by-side (incl. the manual dogfood) passes.
