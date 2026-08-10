# Tasks: Beta3 Stabilization (v0.40.0-beta3)

**Feature**: 199-beta3-stabilization
**Plan**: file:///C:/Dev/specrew-beta3-stabilization/specs/199-beta3-stabilization/plan.md
**Date**: 2026-08-10
**Effort unit**: story points (20 SP iteration convention; 13.1 SP planned — the
corrected plan total, drift event DRIFT-199-I001-004)

Single iteration (001). Tasks are feature-globally numbered and mirror plan work
items W1–W13 one-to-one (W1 stays one item per the maintainer's plan-verdict
instruction). Every task lands RED-first through the shipped entry point (FR-023 — the
method rule binds every task); mirror parity and psd1 FileList ride every commit
(inherited custom rules).

## Iteration 001 — Phase 1: review-loop economics (bridge, 5.0 SP)

- [ ] T001 [owner: Implementer] [sp: 3.0] **Pause core** — the round terminal becomes
  the pause: orchestrator writes the PendingPauseFact (atomic CreateNew) after every
  ingest and exits; navigator renders the decision surface (severity groups with
  locations, visibly non-gating minors, cost in rounds/minutes, budget position,
  severity-derived one-line recommendation, three numbered options with consequences,
  the nothing-runs-until-you-answer line); the human's numbered reply writes the
  PauseDecisionFact — the sole continuation authority (single-run grants; agents
  cannot mint continuation); per-CAMPAIGN budget default 4 counted by
  reviewer-invoked rounds only, exhaustion refuses until explicit human reset; minors
  auto-carry as recorded follow-ups and never gate. RED fixtures through
  `Invoke-ReviewCampaignCommand` in a fixture project; paired honesty tests per
  economics invariant (Trace: FR-001, FR-002, FR-003, FR-004, FR-023, SC-001,
  SC-002; owns: `scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1`,
  `review-authority-core.ps1`, `review-authority-store.ps1`, navigator renderers,
  `tests/continuous-co-review/unit/pause-terminal.Tests.ps1`)
- [ ] T002 [owner: Implementer] [sp: 1.0] **Composed stop-here landing** — one
  orchestrator action chains frozen-tree verification -> identity-bound residual
  acceptance -> gate sync; the T067 wedge (accepted-residuals-on-an-unreviewed-tree)
  is the RED reproduction; landing completes sign-off with zero manual gate
  untangling (Trace: FR-005, SC-004; depends: T001; owns: orchestrator landing
  action, `tests/continuous-co-review/unit/stop-here-landing.Tests.ps1`)
- [ ] T003 [owner: Implementer] [sp: 1.0] **Single-authority stop surface** — the
  stale classifier consults `.specrew/review/signoff-gate/latest.json` before any
  block and never contradicts a recorded decision; an authorized in-flight run
  suppresses the block; governance/records-only deltas never stale; a pending
  PendingPauseFact reads as quiet (no review demand, no disposition demand). RED
  reproductions from the ledger F5 evidence — the stop-gate blindness finding
  (Trace: FR-007, FR-008, FR-009, SC-003; depends: T001 (pause-fact read); owns:
  `review-signoff-evidence-gate.ps1` emit sites,
  `tests/continuous-co-review/unit/stop-authority.Tests.ps1`)

## Iteration 001 — Phase 2: capture + reviewer contract (2.0 SP)

- [ ] T004 [owner: Implementer] [sp: 1.5] **Verdict capture contract** — leading
  recognized approval phrase wins over trailing instruction wording
  (approve-with-instructions captures; classifier and response contract agree);
  capture scans marker-forward past non-verdict turns (first verdict-bearing human
  turn wins); boundary-name words as plain English never flip classification
  (iteration 011 reproductions as RED fixtures); prompt-submit capture primary with
  Stop-time fallback; hooks deploy reconciles a settings file missing a newly
  registered event and `hooks status` flags wiring drift (the live 2026-08-10
  diagnosis) (Trace: FR-010, SC-005; owns:
  `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`,
  `scripts/internal/deploy-refocus-hooks.ps1`, hooks status/doctor,
  `tests/bootstrap/ConversationCapture.Tests.ps1`,
  `tests/integration/hooks-reconcile.Tests.ps1`)
- [ ] T005 [owner: Implementer] [sp: 0.5] **Verdict-goal reviewer prompt contract** —
  the reviewer determines whether the artifact is safe to proceed on: a justified
  clean verdict naming what was verified is a blessed output; every finding states a
  concrete failure scenario or is not a finding; output ranked by severity and
  capped. Paired abuse test: a finding without a failure scenario is rejected at
  ingest classification (consequence tags stay beta4) (Trace: FR-006; owns:
  `worktree-reviewer.ps1` prompt assembly, ingest classification,
  `tests/continuous-co-review/unit/reviewer-prompt-contract.Tests.ps1`)

## Iteration 001 — Phase 3: install + bootstrap (2.75 SP)

- [ ] T006 [owner: Implementer] [sp: 1.75] **Reparse-tag discrimination** — the
  integrity check discriminates tags: cloud-files family hydrate-then-hash-verify;
  junction/symlink refusal untouched with fixtures green; unknown tags fail closed
  (allowlist); symmetric across module install, authority store, frozen snapshot;
  refusal and hydration-unavailable messages in the consumer shape; docs keep the
  AllUsers alternative plus the one synced-folders advisory sentence. Tag-classifier
  fixtures use real tag constants; the OneDrive hydration leg is a manual
  measurement on the recorded T067-class environment with the proof line transcribed
  and scoped (Trace: FR-011, FR-023, SC-006; owns: `review-authority-store.ps1`
  link checks, refusal messages, install docs,
  `tests/continuous-co-review/unit/reparse-tag-policy.Tests.ps1`)
- [ ] T007 [owner: Implementer] [sp: 1.0] **Init verification-plan bootstrap** —
  `specrew init` scaffolds the starter verification-plan.json (governance validator +
  dotnet/npm build-test templates) with the default env_refs allowlist (N4 list
  including TMPDIR); verification failures name the missing piece (env_refs with the
  exact line to add, plan schema element, defer-record format) instead of a sealed
  generic failure. RED: fresh-project fixture passes campaign preflight after init;
  each broken piece names itself (Trace: FR-012, FR-013, SC-007; owns:
  `verification-plan-materializer.ps1`, `verification-plan-contract.ps1`,
  `verification-plan-runner.ps1`, orchestrator error surfaces at :441-449,
  `tests/integration/init-verification-plan.Tests.ps1`)

## Iteration 001 — Phase 4: accounting + windows (1.0 SP)

- [ ] T008 [owner: Implementer] [sp: 0.5] **Reviewer-invoked-only spend** — the
  campaign engine's pre-invocation-failure path (`preflight-failed`,
  `claim-contended`, `launch-failed`) publishes run records but never consumes the
  allowance, aligned to the legacy spend-class rule. RED: the T067 three-infra-
  failure sequence leaves the allowance intact (Trace: FR-014, SC-008; owns:
  `review-campaign-orchestrator.ps1` `Complete-ReviewPreInvocationFailure` path,
  `review-authority-core.ps1` spend decisions,
  `tests/continuous-co-review/unit/spend-accounting.Tests.ps1`)
- [ ] T009 [owner: Implementer] [sp: 0.5] **Codex window 900 s** — the catalog row's
  default window becomes 900 seconds (other hosts untouched); the timeout message
  follows the consumer shape and names `co_review_timeout_seconds` (Trace: FR-018;
  owns: `reviewer-host-catalog.ps1` codex row, timeout message surfaces,
  `tests/continuous-co-review/unit/review-window.Tests.ps1`)

## Iteration 001 — Phase 5: language, version, records, CI (2.35 SP)

- [ ] T010 [owner: Implementer] [sp: 1.75] **Consumer-language layer** — the gloss
  helper (id + title required; an unglossed ID in a consumer surface is a failing
  test); the banned-machinery-noun check (crossing, mint, marker, digest, boundary
  sync, verdict capture, controller truth, ratchet, claim-ordered, terminalize —
  lifecycle stage names and approval phrases stay by design); the surface pass over
  packet templates, stop messages, skill instructions, and the orientation banner;
  the one-message decision-stop rule and the never-sync-in-the-verdict-turn defense
  rule land in the instruction layer (Trace: FR-015, FR-016, FR-017, SC-009; owns:
  navigator prose builders, gloss helper, packet templates, `specrew-gate-stop` and
  sync skill instructions, `tests/integration/consumer-language.Tests.ps1`)
- [ ] T011 [owner: Implementer] [sp: 0.25] **Banner full prerelease version** — the
  bootstrap provider composes `{ModuleVersion}-{Prerelease}` (reference:
  `Get-ManifestSpecrewVersionText`); `coordinator-prompt-surgery.ps1` likewise; the
  deployed mirror updates in lockstep. RED: banner fixture asserts `0.40.0-beta3`
  (Trace: FR-019, SC-010; owns: `specrew-bootstrap-provider.ps1:438` + mirror,
  `coordinator-prompt-surgery.ps1:105-110`, `tests/bootstrap/BannerVersion.Tests.ps1`)
- [ ] T012 [owner: Spec Steward] [sp: 0.25] **Records: 009/010 wording + release
  notes** — resolve the flagged 009/010 registry-vs-claim wording inconsistency
  (records-only; specifics pulled from the 198 records); draft the release notes
  carrying the review-loop fixes, the updated known-issues list, and the explicit
  sentence that the evidence-pipeline and path-identity consolidations named in the
  beta2 claim ship in beta4 (Trace: FR-020, FR-021; owns: records + release-notes
  draft; verified by review, no code)
- [ ] T013 [owner: Implementer] [sp: 0.1] **markdownlint CI install** — the one-line
  markdownlint-cli install in the CI workflow so the Deterministic gate /
  generator-markdown-parity lane stops going INCONCLUSIVE (198-carried chore, ruled
  in scope as release hygiene). Evidence: the lane green on this feature's PR,
  measured not drafted (Trace: FR-022; owns: `.github/workflows/**`)

## Traceability summary

- FR-001..004 -> T001 · FR-005 -> T002 · FR-006 -> T005 · FR-007..009 -> T003 ·
  FR-010 -> T004 · FR-011 -> T006 · FR-012..013 -> T007 · FR-014 -> T008 ·
  FR-015..017 -> T010 · FR-018 -> T009 · FR-019 -> T011 · FR-020..021 -> T012 ·
  FR-022 -> T013 · FR-023 -> every task (method rule; named in T001/T006 where the
  evidence shape is non-obvious).
- SC-001/002 -> T001 · SC-003 -> T003 · SC-004 -> T002 · SC-005 -> T004 · SC-006 ->
  T006 · SC-007 -> T007 · SC-008 -> T008 · SC-009 -> T010 · SC-010 -> T011.
- Every task maps to at least one FR/SC; every FR and SC has at least one task.
