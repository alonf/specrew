# Iteration State: 007

**Schema**: v1
**Current Phase**: implement (review-signoff — PARITY ACHIEVED via the deployed dogfood; pending merge test-triage before retro)
**Iteration Status**: executing
**Last Completed Task**: the DEPLOYED manual dogfood PASSED (2026-06-10, live in `C:\Temp\SpecrewTrials\iter7-dogfood2`, real installed-module layout). The hook fired; the agent oriented (read the contract), rendered the coordinator contract + the "expert on Software Architecture" expertise line + clarify-budget + re-entry-packet promise + file:/// paths, and DROVE into the governed lifecycle — invoked the specrew-design-workshop skill and ran the 9-lens intake (with the FR-040 agenda-as-assignment), instead of going straight to the task. Matches specrew start. The 47 KB inline COMPELLED read-and-follow deployed. iter-6's failure is fixed; PARITY ACHIEVED.
**Tasks Remaining**: triage the merge test-sweep failures (~10, all in UNRELATED areas — dashboards / host-registry / sync-boundary-state / distribution — while every iter-7 + launch-contract test PASSES); separate pre-existing branch drift from merge-introduced, fix only the latter. THEN advance review-signoff → retro.
**In Progress**: merge test-sweep triage (background sweep). Captured follow-on (NOT iter-7): the design-workshop FR-040 prep-message should emit BEFORE the heavy per-lens prep — the dogfood showed a ~3-min silent wait before the agenda surfaced, so the human had nothing to do.
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
- **review-signoff HELD (maintainer verdict, 2026-06-10) — NOT approved as parity-confirmed.** Code/flow
  passed a deep review (deploy gap closed: byte-identical + deps in FileList + deployed-floor + anti-stale-green;
  surgery+inline correct) but parity is UNPROVEN; per Ruling Prompt 3 the manual dogfood is the disqualifier,
  and T046 green is hook-vs-a-RECONSTRUCTION of specrew start, not hook-vs-LIVE.
  - **#3 hardening DONE:** captured a REAL specrew start contract (`specrew init` + `specrew start --no-launch`)
    and diffed it against the hook's — 326 vs 308 lines; a 38-line diff that is ALL launcher-only/context
    (frontmatter `baseline_commit_hash`; the feature request; the casting roster/routing/projectstate stubs) +
    one cosmetic (`Specrew: unknown` — the manager omits `SpecrewVersion` from the surgery; fixable, not
    parity-critical). All 5 parity markers present + matching in the real contract → the reconstruction is FAITHFUL.
  - **THE GATE (the maintainer runs it):** the DEPLOYED dogfood — install this branch (the dev module is 0.34.0,
    so it WINS over the published 0.33.0 via tier-3) as the resolvable module, `specrew init` a fresh project,
    run the anti-stale-green check (deployed provider greps `Write-SpecrewLaunchContractArtifact`; launch-contract.ps1
    resolves), THEN launch `claude` and observe the first reply. NOT the dev-tree `SPECREW_MODULE_PATH` fast-path
    (the iter-6 failure was downstream). PASS = the hook agent renders the coordinator contract + the
    expert-on-Software-Architecture line + drives the lifecycle, matching specrew start.
  - On GREEN → parity achieved, record honestly, advance to retro. On RED → the 47 KB inline is the first
    suspect (additionalContext cap / skim) → trim to core per Ruling b; second suspect is a deployed dependency
    not resolving. No parity claim until green.
  - Carried prompt answers: #2 keep full-inline FOR the dogfood (trim only if it skims); #4 Proposal-145
    promotion at FEATURE-CLOSEOUT (bundle the main commit), not mid-iteration.

## Notes

- Rulings (a)/(b)/(c)/(d) settled at before-implement; plan validator-green (EXIT 0). Capacity 18/20 (SPLIT,
  do not exceed).
- Next: T044 inline-core → T045 deploy-sync + mirror guard → T046 side-by-side acceptance test → T047 manual
  dogfood protocol. Parity is NOT re-claimed until the side-by-side (incl. the manual dogfood) passes.
