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

## Execution order (maintainer instruction at the tasks verdict, 2026-08-10)

**Cheap durable wins land FIRST**: T009 (codex review window), T011 (banner prerelease
version), T013 (markdownlint CI install) — then the economics core T001, T002, T003,
then the remainder as listed (T004, T005, T006, T007, T008, T010, T012).

**Recorded rationale (maintainer)**: the CI lane goes green before heavy work, and the
codex review window is in place before codex reviews this feature.

The phase headings below keep their authoring order; this execution order governs.

## Iteration 001 — Phase 1: review-loop economics (bridge, 5.0 SP)

- [x] T001 [owner: Implementer] [sp: 3.0] **Pause core** — the round terminal becomes
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
- [x] T002 [owner: Implementer] [sp: 1.0] **Composed stop-here landing** — one
  orchestrator action chains frozen-tree verification -> identity-bound residual
  acceptance -> gate sync; the T067 wedge (accepted-residuals-on-an-unreviewed-tree)
  is the RED reproduction; landing completes sign-off with zero manual gate
  untangling (Trace: FR-005, SC-004; depends: T001; owns: orchestrator landing
  action, `tests/continuous-co-review/unit/stop-here-landing.Tests.ps1`)
- [x] T003 [owner: Implementer] [sp: 1.0] **Single-authority stop surface** — the
  stale classifier consults `.specrew/review/signoff-gate/latest.json` before any
  block and never contradicts a recorded decision; an authorized in-flight run
  suppresses the block; governance/records-only deltas never stale; a pending
  PendingPauseFact reads as quiet (no review demand, no disposition demand). RED
  reproductions from the ledger F5 evidence — the stop-gate blindness finding
  (Trace: FR-007, FR-008, FR-009, SC-003; depends: T001 (pause-fact read); owns:
  `review-signoff-evidence-gate.ps1` emit sites,
  `tests/continuous-co-review/unit/stop-authority.Tests.ps1`)

## Iteration 001 — Phase 2: capture + reviewer contract (2.0 SP)

- [x] T004 [owner: Implementer] [sp: 1.5] **Verdict capture contract** — leading
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
- [x] T005 [owner: Implementer] [sp: 0.5] **Verdict-goal reviewer prompt contract** —
  the reviewer determines whether the artifact is safe to proceed on: a justified
  clean verdict naming what was verified is a blessed output; every finding states a
  concrete failure scenario or is not a finding; output ranked by severity and
  capped. Paired abuse test: a finding without a failure scenario is rejected at
  ingest classification (consequence tags stay beta4) (Trace: FR-006; owns:
  `worktree-reviewer.ps1` prompt assembly, ingest classification,
  `tests/continuous-co-review/unit/reviewer-prompt-contract.Tests.ps1`)

## Iteration 001 — Phase 3: install + bootstrap (2.75 SP)

- [x] T006 [owner: Implementer] [sp: 1.75] **Reparse-tag discrimination** — the
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
- [x] T007 [owner: Implementer] [sp: 1.0] **Init verification-plan bootstrap** —
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

- [x] T008 [owner: Implementer] [sp: 0.5] **Reviewer-invoked-only spend** — the
  campaign engine's pre-invocation-failure path (`preflight-failed`,
  `claim-contended`, `launch-failed`) publishes run records but never consumes the
  allowance, aligned to the legacy spend-class rule. RED: the T067 three-infra-
  failure sequence leaves the allowance intact (Trace: FR-014, SC-008; owns:
  `review-campaign-orchestrator.ps1` `Complete-ReviewPreInvocationFailure` path,
  `review-authority-core.ps1` spend decisions,
  `tests/continuous-co-review/unit/spend-accounting.Tests.ps1`)
- [x] T009 [owner: Implementer] [sp: 0.5] **Codex window 900 s** — the catalog row's
  default window becomes 900 seconds (other hosts untouched); the timeout message
  follows the consumer shape and names `co_review_timeout_seconds` (Trace: FR-018;
  owns: `reviewer-host-catalog.ps1` codex row, timeout message surfaces,
  `tests/continuous-co-review/unit/review-window.Tests.ps1`)

## Iteration 001 — Phase 5: language, version, records, CI (2.35 SP)

- [x] T010 [owner: Implementer] [sp: 1.75] **Consumer-language layer** — the gloss
  helper (id + title required; an unglossed ID in a consumer surface is a failing
  test); the banned-machinery-noun check (crossing, mint, marker, digest, boundary
  sync, verdict capture, controller truth, ratchet, claim-ordered, terminalize —
  lifecycle stage names and approval phrases stay by design); the surface pass over
  packet templates, stop messages, skill instructions, and the orientation banner;
  the one-message decision-stop rule and the never-sync-in-the-verdict-turn defense
  rule land in the instruction layer (Trace: FR-015, FR-016, FR-017, SC-009; owns:
  navigator prose builders, gloss helper, packet templates, `specrew-gate-stop` and
  sync skill instructions, `tests/integration/consumer-language.Tests.ps1`)
- [x] T011 [owner: Implementer] [sp: 0.25] **Banner full prerelease version** — the
  bootstrap provider composes `{ModuleVersion}-{Prerelease}` (reference:
  `Get-ManifestSpecrewVersionText`); `coordinator-prompt-surgery.ps1` likewise; the
  deployed mirror updates in lockstep. RED: banner fixture asserts `0.40.0-beta3`
  (Trace: FR-019, SC-010; owns: `specrew-bootstrap-provider.ps1:438` + mirror,
  `coordinator-prompt-surgery.ps1:105-110`, `tests/bootstrap/BannerVersion.Tests.ps1`)
- [x] T012 [owner: Spec Steward] [sp: 0.25] **Records: 009/010 wording + release
  notes** — resolve the flagged 009/010 registry-vs-claim wording inconsistency
  (records-only; specifics pulled from the 198 records); draft the release notes
  carrying the review-loop fixes, the updated known-issues list, and the explicit
  sentence that the evidence-pipeline and path-identity consolidations named in the
  beta2 claim ship in beta4 (Trace: FR-020, FR-021; owns: records + release-notes
  draft; verified by review, no code)
- [x] T013 [owner: Implementer] [sp: 0.1] **markdownlint CI install** — the one-line
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

## Iteration 002 — the beta3 tag batch (19.0 SP; plan verdict 2026-08-29)

Ten items from two field walks and their live reproductions, plus one defect against the existing
FR-010. Every task carries the mutation that turns its own case red, asserting observable state
(FR-033); every refusal touched meets the refusal standard; every mirrored copy lands
byte-identical in the same commit. Execution order: the crossing family first (T014, T021, T023,
T015, T024), then the two one-file fixes (T016, T022), then the workshop family (T017, T018, T019,
T020), then the sweep (T025). Review (3.0 SP) and rework (2.5 SP) are planned at the direct
estimate with the parity floor beside them as a check and a visible 2x tripwire (plan.md Notes).

### Phase 1: the crossing family (10.5 SP)

- [x] T014 [owner: Implementer] [sp: 3.0] **Mint gate and marker identity** — a crossing is not
  opened until the stage it leaves has its owed artifacts on the live filesystem, at all three
  minting mechanisms (`Set-SpecrewPendingBoundaryCrossingScope`, the `$nextScope` rebind in
  `Add-SpecrewBoundaryAuthorization`, `Sync-SpecrewPendingVerdictArtifactAfterAuthorization`); the
  verdict marker carries the crossing identity. Mutations: the KeyContextAI ladder replays at one
  commit when the gate is removed; a marker for a superseded identity captures when the identity
  check is removed. PERMIT side, in the same commit: a real mint against a throwaway fixture where
  the from-stage's artifacts are present opens its crossing (the check goes red when the gate is
  made too strict) - PreflightOnly never reaches the mint path, and without this the permit side
  would stay unproven until review-signoff. (Trace: FR-024, FR-033, SC-011; owns: `shared-governance.ps1` + mirror,
  `HandoverStore.ps1`, `ConversationCaptureAccessor.ps1`)
- [x] T021 [owner: Implementer] [sp: 2.0] **Crossing mirrors** — the authorization writer writes
  `state.md` Current Phase and `plan.md` Status in each file's existing vocabulary and sets
  `state.md` Iteration Status to `complete` at closeout; the sync re-mirrors the copies; the truth
  gate compares every enumerated mirror at every iteration-scoped boundary and refuses a copy ahead
  of the store. Mutations: DRIFT-199-I001-152 reproduced on a fixture then green; a hand-advanced
  `plan.md` Status refused. Folded in (DRIFT-199-I002-009): `Set-TaskStatus` writes `done` for
  completion (accepting `complete` as an input alias) so the ledger speaks the word every consumer
  reads; mutation: a task completed through `Set-TaskComplete` passes the boundary preflight's
  task-state check, red when the writer is reverted. (Trace: FR-030, FR-033, SC-016; owns:
  `shared-governance.ps1` + mirror, `sync-boundary-state.ps1`, `task-progress.ps1`)
- [x] T023 [owner: Implementer] [sp: 2.5] **The owing actor** — `pending_crossing.owner` recorded
  at mint (`host|session` or `unknown`); the conformance provider's boundary demand fires only for
  the owner; other sessions get one informational line; `owner: unknown` keeps today's behavior
  and the packet names the gap out loud; the capture verifies the marker's crossing identity.
  **Resume/compaction constraint (maintainer, tasks verdict 2026-08-29)**: a session that resumes
  or compacts can come back with a new session id, and the owner must never become un-matchable in
  a way that locks a session out of its own crossing - that is rule 12's outage side and a worse
  defect than the one being fixed. When the current session id does not match the recorded owner
  and no other live session claims it, the demand FAILS OPEN with disclosure, the same shape as
  owner-unknown: keep today's behavior and say plainly that ownership could not be confirmed.
  Only a positive mismatch - this session is demonstrably a different, live session - suppresses
  the demand to the informational line. Mutations: a second session's Stop demands a packet when
  the owner check is removed; an unknown-owner packet omits the gap sentence when the disclosure
  is removed; a resumed session with a new id is LOCKED OUT of its own crossing when the fail-open
  branch is removed. (Trace: FR-032, FR-024, FR-033, SC-019; owns: `shared-governance.ps1` +
  mirror, `specrew-conformance-provider.ps1` + mirror, `HandoverStore.ps1`)
- [x] T015 [owner: Implementer] [sp: 2.0] **The withhold discipline, stated once** — the
  post-capture packet re-mint gains the sync-side evidence guard; the gate-stop skill (3 copies),
  Rule 53, `refocus/general.md` (2) and `lifecycle-discipline.md` carry the conformance provider's
  counter-discipline as the one wording of record; `gate-stop-skill.tests.ps1` gains the
  withhold assertions; `multi-host-launch-path` and `fr068` HALF 2 pass unchanged, the latter because
  it characterises a different composition (DRIFT-199-I002-010). Mutation: an
  evidence-less next stage re-mints `pending-verdict-stop.md` with an approval phrase when the guard
  is removed. (Trace: FR-024, FR-033, SC-011; owns: `HandoverStore.ps1`, the skill copies,
  `launch-contract.ps1`, `refocus/general.md` + mirror, `docs/methodology/lifecycle-discipline.md`)
- [x] T024 [owner: Implementer] [sp: 1.0] **Capture disclosure** — when a pending crossing exists
  and the last human turn is verdict-shaped but not accepted, the capture emits one visible line
  naming the classification, the leading text that decided it, and that the phrase must be the
  FIRST CHARACTERS OF THE MESSAGE - not the first of the verdict lines, which is how a careful
  reader takes "bare phrase first" until a recap says otherwise; journaled. Fixtures: the leading
  quote bar; leading prose ("Don't confirm ..." before `approved for plan`) - both the
  maintainer's own text, both retried by the maintainer. Folded in (DRIFT-199-I002-008): the
  disclosure fires at PROMPT-ENTRY, where the phrase first appears, in that turn's injected
  context; and every prompt-entry capture outcome is journaled (`captured`, `not-approval:<action>`,
  `no-pending-state`, `machinery-envelope`) so a verdict that reaches Stop unrecorded is
  diagnosable. Mutation: with the prompt-entry disclosure removed, a rejected verdict-shaped prompt
  produces no line until the recap. Mutation: the line disappears when the disclosure is removed and
  the turn is silently skipped. (Trace: FR-010, FR-033, SC-020; owns: `HandoverStore.ps1`)

### Phase 2: gate-preflight and the seal (2.0 SP)

- [x] T016 [owner: Implementer] [sp: 1.5] **Split `pushed-head`** — delivery at closeouts reading
  `release_model` and `enforcement_mode` (manual or absent with no origin = declared-future,
  not-applicable with the owed-when message; active mode with no origin = fail naming the
  contradiction); `verdict-commit-durable` at every boundary (origin: `origin/<branch>` at HEAD;
  none: not-applicable with the honest note). Fixtures: the HelloWinUIReactive posture at specify;
  this repository's posture; pushed-but-stale retargeted to `iteration-closeout` and kept at
  `specify` under the durability name. Mutation: an unpushed HEAD passes specify when the
  durability check is removed. (Trace: FR-025, FR-033, SC-012; owns: `gate-preflight.ps1`,
  `tests/unit/gate-preflight.Tests.ps1`)
- [x] T022 [owner: Implementer] [sp: 0.5] **Seal last** — the closeout sync writes the seal after
  the dashboard render; a test asserts the seal hashes the rendered dashboard. Mutation: reorder
  the writes and the test goes red on the timestamped dashboard. (Trace: FR-031, FR-033, SC-017;
  owns: `sync-boundary-state.ps1`)

### Phase 3: the workshop family (5.75 SP)

- [x] T017 [owner: Implementer] [sp: 1.0] **Zero-construct detection** — both constrained readers
  return unparseable on a non-empty document with no recognized construct; the validators' message
  names the representation (JSON by first character), states the answers are intact, names the
  re-write. Mutation: a JSON-shaped record produces backstop lines when the detection is removed.
  (Trace: FR-026, FR-033, SC-013; owns: `product-domain-lens.ps1`, `code-implementation-lens.ps1`)
- [ ] T018 [owner: Implementer] [sp: 3.0] **The lens checkpoint writer** — `confirm-workshop-lens`
  consumes the receipt, requires the record, runs the two existing validators, writes `moved_on`
  and the confirmation fields, refreshes the handover; `confirm-lens` joins the transition table
  (56 pinned cells); the skill's step 7 invokes it; refusals through the refusal contract.
  Mutations: a confirmed lens stays current when the writer's state write is disabled; a
  JSON-shaped product-domain record closes the lens when the validator call is disabled. (Trace: FR-027, FR-033, SC-013, SC-014; owns: `confirm-workshop-lens.ps1` + mirror,
  `workshop-authority-store.ps1` + mirror, `specrew-design-workshop/SKILL.md` copies)
- [ ] T019 [owner: Implementer] [sp: 0.75] **What was received, what is still needed** — the
  acknowledgment line in the skill and lens texts; the repair gate's refusal through the refusal
  contract naming the received reply and `approved for workshop repair`; recognizers untouched.
  Mutations: the text-presence test and the refusal-contract AST guard go red when either is
  reverted. (Trace: FR-028, FR-033, SC-014; owns: the skill copies, `design-lenses/*.md`,
  `repair-workshop-controller-state.ps1` + mirror)
- [ ] T020 [owner: Implementer] [sp: 1.0] **The not-yet-authored stub** — feature creation replaces
  the template copy with the sentinel stub; the specify gate refuses while it stands, saying the
  workshop answers are safe. Mutations: `[Brief Title]` reappears when the replacement is
  reverted; the stub crosses specify when the sentinel check is removed. (Trace: FR-029, FR-033,
  SC-015; owns: `create-governed-feature.ps1` + mirror, `design-analysis-gate.ps1`)

### Phase 4: the sweep (0.5 SP)

- [ ] T025 [owner: Spec Steward] [sp: 0.75] **Method sweep** — mirror byte-identity across every
  touched copy; the mutation audit per fix; the refusal-standard pass over every touched message;
  the release-notes draft; the covering-round request over the delta since `1b50ae60`; and the
  coverage line names the campaign its figure belongs to and, when the current iteration has no
  campaign yet, says so instead of reporting the previous campaign's remainder
  (DRIFT-199-I002-006, folded in by ruling as honest labelling - what the line SAYS, not what the
  function computes; if it turns out to need campaign-selection logic, it stops and goes to beta4).
  (Trace: FR-033, SC-018; owns: `docs/release-notes-v0.40.0-beta3.md`, `specs/**`,
  `shared-governance.ps1` coverage line + mirror)

### Traceability summary (both directions)

- Requirements to tasks: FR-024 -> T014, T015 · FR-025 -> T016 · FR-026 -> T017 · FR-027 -> T018 ·
  FR-028 -> T019 · FR-029 -> T020 · FR-030 -> T021 · FR-031 -> T022 · FR-032 -> T023 · FR-033 ->
  T025 and every task's mutation clause · FR-010 -> T024. No FR in the iteration's scope is
  uncovered.
- Success criteria to tasks: SC-011 -> T014, T015 · SC-012 -> T016 · SC-013 -> T017, T018 ·
  SC-014 -> T018, T019 · SC-015 -> T020 · SC-016 -> T021 · SC-017 -> T022 · SC-018 -> T025 (and
  the covering round) · SC-019 -> T023 · SC-020 -> T024. No SC uncovered.
- Tasks to requirements: every task above names at least one FR and one SC in its Trace clause;
  no task traces to nothing.
