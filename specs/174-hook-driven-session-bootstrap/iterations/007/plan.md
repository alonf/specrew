# Iteration Plan: 007

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 18/20 story_points
**Started**: 2026-06-10
**Completed**:

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity `<consumed>/<cap> <unit>`. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Scope Summary

Iteration 007 is the **rework of iteration 006's disproven parity claim**. iter-6 extracted the shared
launch-contract generator (T035, byte-identical — KEPT) but did NOT achieve hook ↔ `specrew start` parity.
A maintainer side-by-side (same prompt, hook vs `specrew start`) showed: with `specrew start` the agent's
first act is to READ `last-start-prompt.md` and render the full Crew-coordinator contract (user-profile /
expertise adaptation, clarify-budget, re-entry-packet promise) before the workshop; with the hook the agent
NEVER reads `last-start-prompt.md` — it self-orients and reaches the workshop on baseline discipline alone.
iter-6's value-add was absent.

**Goal:** the hook delivers the SAME contract `specrew start` does AND the agent actually reads + follows it
— proven by a **side-by-side equivalence** of the agent's lead-up (modulo genuinely launcher-only bits),
not an on-disk file check. Fix BOTH layers (self-host experience + downstream deploy); fixing one alone
still fails.

## Rulings (before-implement, 2026-06-10 — settled; implementation carries them)

- **(a) Surgery-step reuse.** The hook applies the SAME `Invoke-SpecrewCoordinatorPromptSurgery` step
  `specrew start` does (`Get-StartPrompt` → surgery with `-ExpertiseLine (Get-SpecrewProfileOrientationLine)`
  + host/runtime/lifecycle args). NO `Get-StartPrompt` signature change → one generator, no drift. (Supersedes
  the maintainer's earlier "add a `UserProfile` param" wording — the content enters via the surgery step.)
- **(b) Inline the core, made SELF-SUFFICIENT.** The inlined core MUST contain everything the side-by-side
  compares — coordinator framing + the expertise/user-profile line + the drive-into-lifecycle/workshop + the
  don't-bypass-gates instruction. Do NOT defer any parity-relevant content to the file ("see the file for X"
  reintroduces the skip being fixed). The file carries only deeper detail consumed at later boundaries. The
  side-by-side is the arbiter: a lead-up gap in its diff means the core was insufficient → expand toward full.
- **(c/gate — Prompt 3) The manual read-and-follow dogfood MUST pass for the acceptance gate.** The
  automatable content-diff proves contract equivalence but CANNOT prove the agent reads + follows it (the exact
  iter-6 failure) — necessary but NOT sufficient. Both must pass; the manual dogfood is the disqualifier.
  Advancing on the content-diff alone repeats the build≠live trap one level up.
- **(d — Prompt 4) SPLIT, do not exceed 20.** If (a)+(b) grow past the cap, split into a follow slice; do
  not raise the cap.

## Design / Architecture (the design pass)

### (a) Where `specrew start`'s user-profile + coordinator content enters — TRACED

`specrew start` assembles `last-start-prompt.md` in THREE steps (`scripts/specrew-start.ps1` L3332–3360):

1. **`Get-StartPrompt`** (L3332) — the base ~48-rule contract from the blocks (roster / routing /
   projectstate / sessionstate / brownfield / delivery-guidance / boundary-policy). The hook ALREADY calls
   this (iter-6 T036).
2. **`Invoke-SpecrewCoordinatorPromptSurgery`** (L3348) — `-HostKind`, `-CrewRuntimeStatus`,
   `-SpecrewVersion`, `-LifecycleMode`, `-FeatureRef`, `-BoundaryType`, and **`-ExpertiseLine
   (Get-SpecrewProfileOrientationLine)`**. THIS injects the **user-profile / expertise adaptation** and the
   **per-host coordinator framing + host-accurate orientation / runtime status**.
3. **`Save-StartArtifacts`** (L3358) — writes the surgery-applied prompt + writes `user_profile` into
   `start-context.json`.

**Root cause (confirmed):** the iter-6 hook path (`Write-SpecrewLaunchContractArtifact` in
`SessionBootstrapManager.ps1`) calls **`Get-StartPrompt` only** — it never applies step 2. There is no
`Invoke-SpecrewCoordinatorPromptSurgery` call in the manager, and the provider does not dot-source
`coordinator-prompt-surgery.ps1` / `internal/user-profile.ps1`. So the user-profile + coordinator framing
are absent and the contract is thin. (`Get-StartPrompt` has NO expertise/user-profile param — the content
lives in the surgery step, not the generator. The iter-6 "null launcher-only inputs" decision is a
SECONDARY contributor — thin roster/routing/projectstate blocks — not the primary miss.)

**Fix (Ruling a):** the hook path becomes `Get-StartPrompt` → `Invoke-SpecrewCoordinatorPromptSurgery` (with
the real `-ExpertiseLine (Get-SpecrewProfileOrientationLine)` + `-HostKind claude` + the runtime/version/
lifecycle/feature/boundary args) → write. Dot-source `coordinator-prompt-surgery.ps1` +
`internal/user-profile.ps1` via the SAME 3-tier resolution chain the bootstrap components use. Re-classify
the genuinely session-available inputs (user-profile, host, runtime status, lifecycle/boundary) as threaded;
leave the genuinely launcher-only inputs (casting roster/routing) defaulted. No `Get-StartPrompt` signature
change.

### (b) Read-and-follow — INLINE the contract core, self-sufficient (Ruling b)

The test agent NEVER read `last-start-prompt.md`; a "go READ this file" directive is an extra hop the agent
skips in favor of self-orienting. The injected `additionalContext` IS already in the agent's context. The
hook's injected directive **carries the contract's parity-relevant core inline** — coordinator framing + the
expertise/user-profile line + the drive-into-lifecycle/workshop + don't-bypass-gates — with NO "see the file"
deferral of any parity-relevant content. The full `last-start-prompt.md` is STILL written (for `specrew
start` parity + the deeper detail consumed at later boundaries), but delivery does not depend on the agent
opening it. The side-by-side diff is the arbiter: a lead-up gap means the core was insufficient → expand it
toward full.

### (c) Fix BOTH layers together

1. **Self-host experience** — (a) surgery-step parity + (b) inline delivery, in the module provider
   (`scripts/internal/`).
2. **Deploy-source sync** — port the iter-6 + iter-7 provider changes INTO the extension-source copy
   `extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1` (currently the iter-4 version, 88
   lines, no contract-writer — the copy `Resolve-ProviderCommandPath` resolves FIRST downstream), PLUS a
   **mirror-parity guard** (a test asserting the two provider copies stay in sync) so they cannot diverge
   again silently. Self-host green ≠ downstream; deploy ≠ read-and-follow — both must land together.

### (d) Acceptance gate — the SIDE-BY-SIDE (replaces T038's on-disk check as the disqualifier)

The disqualifier is a **hook-vs-`specrew start` equivalence of the agent's lead-up**, in BOTH halves (Ruling
Prompt 3 — both mandatory):

- **Automatable half** — generate the hook's contract (via the deployed provider) AND `specrew start`'s
  contract (`Get-StartPrompt` + surgery), DIFF them, and assert **equivalence modulo genuinely
  launcher-only bits** (host selection, casting roster/routing) — in particular the user-profile / expertise
  adaptation + coordinator framing present in BOTH. Runs in a DEPLOYED layout (so it exercises the
  extension-source copy, the gap T038 missed). NECESSARY but not sufficient.
- **Manual half (dogfood) — the disqualifier** — a real Claude session launched via the hook reads + follows
  the contract (renders the coordinator contract before acting), matching a `specrew start` session. This is
  what the content-diff cannot prove; the gate is met only when it passes.

T038's on-disk existence check is **demoted** from the gate to a supporting plumbing check.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T043 | Hook applies `Invoke-SpecrewCoordinatorPromptSurgery` + `-ExpertiseLine (Get-SpecrewProfileOrientationLine)` + host/runtime/lifecycle args; dot-source coordinator-prompt-surgery.ps1 + internal/user-profile.ps1 (3-tier); thread session-available inputs, default launcher-only; no Get-StartPrompt signature change | FR-023, FR-002 | US-1 | 5 | Implementer | done |
| T044 | Inline the SELF-SUFFICIENT contract core in the injected directive (read-and-follow fix); no "see the file" deferral of parity-relevant content; keep writing last-start-prompt.md as the durable deeper reference | FR-002, FR-001 | US-1 | 4 | Implementer | planned |
| T045 | Deploy-source sync: port the module provider into the extension-source copy + add a mirror-parity guard test | FR-009 | US-1 | 3 | Implementer | planned |
| T046 | Side-by-side acceptance test — automatable content-diff (deployed layout): hook contract vs `specrew start` contract, equivalence modulo launcher-only; demote T038 to a supporting check | FR-024, SC-011 | US-1 | 4 | Implementer | planned |
| T047 | Manual side-by-side dogfood protocol (the gate disqualifier) + honest read-and-follow record; finish the T042 getting-started honesty sweep | FR-024, FR-008 | US-2 | 2 | Implementer | planned |

**Capacity: 18/20** (rulings settled; per-task SP T043 5 + T044 4 + T045 3 + T046 4 + T047 2 = 18; SPLIT, do
not exceed).

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments. |

## Traceability Summary

- Requirements: FR-023 (contract parity via surgery-step reuse), FR-002/FR-001 (driving directive +
  read-and-follow via inline core), FR-024/SC-011 (side-by-side acceptance + deployed coverage), FR-009
  (deploy-source sync + mirror guard), FR-008 (docs reconciled when parity holds).
- Carried from iter-6: T035 generator extraction (KEPT); the Proposal-145 evidence_locus draft still pends
  promotion to `proposals/` on main; the T042 `specrew start` repositioning stays reverted until the
  side-by-side passes.

## Notes

- iter-6 KEPT: T035 generator extraction (byte-identical, validator-green). iter-6 closed honestly-qualified;
  parity deferred here (iter-5 precedent).
- Acceptance is the side-by-side, NOT on-disk existence — T038 passing while the experiences diverged is the
  build≠live trap this iteration exists to close. Per Ruling Prompt 3 the manual dogfood is the disqualifier.
- Maintainer authorized implementation once the plan is validator-green — no re-present for a verbal verdict;
  rulings (a)/(b)/(c)/(d) carried into T043–T047.
