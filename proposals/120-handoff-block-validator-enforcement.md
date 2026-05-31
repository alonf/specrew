---
proposal: 120
title: Handoff Contract Validator Enforcement + Non-Specrew-Session Bypass Detection
status: candidate
phase: phase-2
estimated-sp: 7-12
priority-tier: 1
discussion: **HIGH PRIORITY (Tier 1)** as of 2026-05-27; amended 2026-05-31 after a live regression showed the generated start prompt still mandates the legacy `=== SPECREW HANDOFF ===` sentinel while shipped Proposal 007 expects the three-section boundary handoff (`What I just did` / `Why I stopped` / `What I need from you`) with clickable `file:///` inspection targets. Proposal 151 extracts the urgent 2-4 SP contract-unification fix; Proposal 120 remains the broader validator/backstop bundle. Pillar 5 added after PlanningPoC iter-004 Reviewer-approved-working-tree-only-state empirical evidence. Pillar 5 is the most consequential shape of the form-without-runtime-compliance family because it is the only one where delivered CODE can permanently vanish (other shapes corrupt metadata/audit only). Empirical motivation now spans Shapes 1-5: 2026-05-25 PlanningPoC Squad+Copilot silence + Antigravity F-046 question-prompt substitution + 2026-05-26 PlanningPoC iter-002 silent boundary-state auto-advance (Picard catch) + **2026-05-27 PlanningPoC iter-004 reviewer-approves-working-tree-only-state (7 production files cited in review.md never committed, recovered via `29fce04`)**. Queued in [[non-specrew-session-bypasses-triggers-2026-05-25]] + [[shape5-reviewer-approves-working-tree-only-state-2026-05-27]]; expanded 2026-05-26 with Pillar 4 + 2026-05-27 with Pillar 5 + 2026-05-31 with the canonical handoff-contract correction.
---

# Handoff Contract Validator Enforcement + Non-Specrew-Session Bypass Detection

## Why

Coordinator-prompt rules 45-47 (added in F-040 Wave A1, commit `a45232af`) originally required a structured `=== SPECREW HANDOFF ===` block at every boundary stop and lifecycle-end. Shipped Proposal 007 later made the human-facing contract more specific: every real boundary stop must use the three-section handoff (`What I just did`, `Why I stopped`, `What I need from you`) and must include clickable `file:///` inspection targets when artifacts exist.

As of 2026-05-31, the start-prompt generator still contains the older sentinel-block instruction while the coordinator governance and role charters contain the newer Proposal 007 contract. That conflict can produce a form-correct but UX-regressed stop: status lines and an interactive verdict menu, but no substantive three-section summary and no clickable artifact URLs. **Proposal 151 owns the urgent small fix to unify the prompt surfaces.** This broader Proposal 120 owns the follow-on validator/backstop family after the canonical contract is unified.

The rule is prescribed in prompt surfaces but not mechanically enforced end-to-end. Agents that do not 100% honor the prescription fall back to host-native or model-natural patterns instead, and there is no detection layer that catches the drift.

Empirically observed during the 2026-05-25 dogfooding wave as part of a broader "Specrew shape produced without Specrew runtime compliance" pattern — three independent failure shapes:

1. **Trigger bypass** — agent writes structural artifacts but skips trigger-driven side effects. F-044 implemented by standalone Claude session: all 8 iteration directories got plan/state/review/retro/scope/code-map/drift-log but ZERO got `dashboard.md` because the auto-render path runs through `sync-boundary-state.ps1` which was never invoked. F-043 iter 001 same shape. 10 soft warnings, all `missing-dashboard-artifact`.
2. **Wrong location** — agent writes canonical artifacts to its ephemeral session-scratch folder. Antigravity F-046 specify-phase wrote `implementation_plan.md` to `C:/Users/alon.HOME/.gemini/antigravity-cli/brain/<session-id>/` instead of `specs/046-046-bug-bash/plan.md`. Doesn't survive sessions, isn't version-controlled, isn't discoverable by other agents.
3. **Canonical handoff dropped or substituted** — agent stops at boundary or lifecycle-end without emitting the Proposal 007 three-section handoff with reviewable `file:///` targets. Older incidents describe this as the `=== SPECREW HANDOFF ===` block being dropped; after the 2026-05-31 amendment, the sentinel block is only legacy evidence, not the canonical user-facing contract. Three observed sub-triggers:
   - **3a. Mid-flow agent-completion silence** — when a sub-agent (Scribe, Reviewer, etc.) finishes its task, the coordinator drops to silence instead of emitting the handoff. Squad+Copilot PlanningPoC after Scribe completion (commits `32a4a74` + `903714e`).
   - **3b. Host-native question-prompt substitution** — host-native UI primitives replace the handoff block. Antigravity F-046 specify-phase emitted a structured-question-prompt instead of the `=== SPECREW HANDOFF ===` sentinel.
   - **3c. Post-compaction discipline drop (added 2026-05-26)** — coordinator's discipline degrades after conversation compaction. The PRIOR stop (pre-compaction) correctly emitted the three-section handoff; the IMMEDIATE NEXT stop (post-compaction) drops to plain prose without the structured block. Empirical: 2026-05-26 PlanningPoC review-rerun acceptance — pre-compaction stop after DR-004 fix commit had proper handoff; post-compaction stop after review-rerun acceptance commit `f06491e5` dropped to "Review rerun passed. The packet is now accepted..." with no structured block. Recurring within the same dogfooding session counts the gap as universal across compaction boundaries. Adjacent to but distinct from F-024 autopilot-override (which is host-runtime-level); this is agent-discipline-level degradation that the same agent instance exhibits within a single host. Runtime hook enforcement (Proposal 105) catches sub-cases 3b + 3c that prose discipline cannot.

All of these shapes share the same root cause: **prose-based runtime convention that the coordinator prompt prescribes is not mechanically enforced.** Multi-host expansion (F-040 onward) makes the pattern universal across hosts — every host that doesn't 100% honor coordinator-prompt prescriptions falls back to model-natural behavior. Compaction expansion (long sessions) makes it universal within hosts — even agents that honor the rules pre-compaction may drop them post-compaction.

## What

Validator rule extension at `extensions/specrew-speckit/scripts/validate-governance.ps1` (mirrored to `.specify/`) detecting the five shapes:

### Pillar 0: Canonical handoff contract precondition (~1 SP, extracted to Proposal 151 for immediate fix)

Before Proposal 120's broader validator rules harden anything, the source prompt surfaces must agree on the canonical contract:

- Boundary stops use the Proposal 007 three-section format: `What I just did`, `Why I stopped`, `What I need from you`
- Review/approval handoffs include `file:///` inspection targets when artifacts exist
- Interactive verdict menus are allowed only as an affordance after the three-section handoff; they never replace it
- The legacy `=== SPECREW HANDOFF ===` sentinel may remain as migration-compatible evidence only if needed, but it is not the primary UX contract

Proposal 151 is the small high-priority slice that fixes this precondition. Proposal 120 should not ship broad enforcement until this precondition is in place.

### Pillar 1: Canonical handoff presence check (~1-2 SP)

Detect agent stop signals (lifecycle phase transition, session-end, boundary verdict request) without a preceding canonical three-section handoff in the last N lines of relevant output OR in the most recent boundary commit message/session evidence. Soft WARN severity initially (does not block boundary advancement); surfaces the gap visibly in validator output.

Helper function `Test-SpecrewCanonicalHandoffPresent` (renaming or superseding the current `Test-SpecrewHandoffBlockPresent`) ships in `extensions/specrew-speckit/scripts/shared-governance.ps1` so other validator rules and boundary-sync helpers can call it for "advance pre-condition: handoff was emitted" short-circuits.

Detection heuristic:

- Scan `.squad/decisions.md` for the most recent `Boundary sync` entry within the last N hours
- Check the preceding session-output records (if available via `.specrew/last-start-prompt.md` baseline ref or `.squad/identity/now.md` session metadata)
- If the boundary advancement has no associated canonical handoff evidence within the heuristic window, emit `WARN [handoff] missing-canonical-handoff: Boundary 'X' advanced without a three-section Proposal 007 handoff. Host autopilot, prompt-surface conflict, or agent-prose drift likely.`

### Pillar 2: Trigger-bypass detection (~1 SP)

When validator emits `WARN [dashboard] missing-dashboard-artifact` (or similar artifact-missing warning) on closed iterations, augment with diagnosis:

- Check whether the iteration's other artifacts (plan/state/review/retro/scope/code-map) are present
- If yes, the iteration WAS closed but a trigger-driven artifact was skipped — flag as `non-Specrew-managed iteration` distinct from `regression in auto-render code`
- Improves UX: differentiate "this is a multi-host artifact gap" from "Specrew's code has a bug"

### Pillar 3: Wrong-location detection (~1 SP)

Soft WARN when canonical artifacts are detected in ephemeral host-scratch directories:

- Scan paths matching `C:/Users/<user>/.gemini/antigravity-cli/brain/`, `C:/Users/<user>/.claude/projects/.../brain/`, `C:/Users/<user>/.copilot/session-state/.../files/`, etc.
- If files matching canonical artifact names (`plan.md`, `tasks.md`, `state.md`, `review.md`, `retro.md`, `findings.md`, `spec.md`) appear there, emit `WARN [location] artifact-in-ephemeral-location: <file> belongs at canonical specs/<feature>/ path, not in agent session-scratch.`
- Composes with Proposal 075 (Update Artifact Backfill Discipline) — the backfill mechanism can detect-and-relocate, this validator rule detect-and-warn

### Pillar 4: Boundary-state-advance-without-verdict cross-check (~1-2 SP, added 2026-05-26)

**A new shape of "Specrew form without runtime compliance" surfaced 2026-05-26 during PlanningPoC iter-002 re-review**: silent boundary-state auto-advance past the human-verdict gate. Different mutation surface than Pillar 1 (handoff-block = communication-layer); this is the state-layer counterpart. Picard's independent audit caught it and rolled back (commit `a5866c1`).

When `state.md`'s `Current Phase` field changes across two commits, the validator (and/or a boundary-sync helper) cross-checks `boundary_enforcement.verdict_history` in `.specrew/start-context.json` for a corresponding human-authorization entry:

- If the `from_boundary → to_boundary` transition has a matching `verdict_history` entry with non-empty `authorizing_human` AND non-empty `verdict_text` → PASS, advance is authorized.
- If the transition has NO matching verdict-history entry for a human-verdict boundary → emit `WARN [boundary] state-advance-without-verdict: Phase advanced 'X' → 'Y' without a verdict_history entry. Auto-advance breach detected. Roll back state.md and request human verdict OR record the verdict explicitly.`
- Soft WARN at validator time; **harder block at boundary-sync time** (sync-boundary-state.ps1 refuses to write an advance without a preceding verdict-history append for human-verdict boundaries).

This pillar makes Picard's manual audit role mechanical and host-portable — particularly important when Proposal 024 Slice 3 / Proposal 108 ship per-host Crew runtimes, since Picard's role MUST be replicated on every host to preserve the load-bearing safety net.

### Pillar 5: Reviewer approves working-tree-only state — review.md cites files not in cited commit (~2-3 SP, added 2026-05-27)

**Shape 5 of the "Specrew form without runtime compliance" family**, surfaced 2026-05-27 in PlanningPoC iter-004 post-closeout discovery. **This is the most consequential gap because it's the only shape where actual delivered code can permanently vanish** via `git reset --hard` / `git clean -fdx` / fresh clone — the other shapes (1-4) corrupt metadata or audit trails but the code itself is recoverable.

**The pattern**: Reviewer agent runs tests against working-tree state (where uncommitted files exist on disk), tests pass, Reviewer issues an `accepted` verdict citing committed-hash provenance (`**Tree Under Review**: <hash>`), and lists file-level evidence in the verdict. But the cited commit doesn't actually contain those files — they're only in the working tree, never committed. The audit trail is structurally lying: review.md says "Tree Under Review: `<hash>`" and lists code evidence files A, B, C; `git ls-tree <hash>` shows files A, B, C don't exist in that commit. The Reviewer never ran `git ls-tree` verification before issuing the verdict. Tests passed because they ran against working-tree state, not committed state.

**PlanningPoC iter-004 empirical proof (2026-05-27 discovery)**:

iter-004 closed with `accepted` verdict; iteration-closeout commit `c6facc8` landed; retro authored. After `specrew update` to v0.27.6, user ran `git status` and saw 7 NEW production code files showing as untracked (`??`) — exactly the files cited as evidence in iter-004's review.md (T032r `SignoffRepository.cs`, T035r `ConfirmationPanel.tsx`, T036r `SignoffModal.tsx`, FR-013 `ReviewWorkflowModels.cs`, etc.). `git log --all` for those files returned EMPTY — they had NEVER been in any commit on any branch. Recovery: user staged + committed as `29fce04`. The Reviewer's `**Tree Under Review**: f4e01b7` assertion referenced a tree that didn't contain the cited files. Tests passed (15 contract + 4 integration + 2 Playwright); the lie isn't in the test results — it's in the **commit-hash provenance assertion**.

**Detection mechanism**:

For each iteration with a `review.md`:

1. Parse `review.md` for `**Tree Under Review**: <hash>` (or equivalent canonical field naming the reviewed commit)
2. Parse `review.md` for file paths cited as evidence — match `\.(cs|tsx|ts|md|yml|yaml|json|ps1|py|js|rs|go)$` paths in "Code evidence", "Verification Evidence", "Per-task evidence", "Requirement Verdicts" sections
3. For each cited file path: run `git ls-tree -r <hash> --name-only` and verify presence
4. If any cited PRODUCTION file (excluding test files in `tests/` paths and config files) is missing from the cited tree → emit `FAIL [review] file-cited-but-not-in-tree: '<path>' is referenced in review.md verdict evidence but not present in 'Tree Under Review' commit <hash>. Reviewer may have approved against working-tree-only state.`
5. Soft `WARN` for test files (might be in scope but missing) — fail-loud only for production code
6. Gate the iteration-closeout boundary on this check passing (a `failed-pillar-5` iteration MUST NOT close)

**Where to fire**: every `validate-governance.ps1` run encountering a `review.md` with verdict `accepted` / `pass`. Hard-gate iteration-closeout boundary on Pillar 5 PASS.

**Companion Reviewer-charter discipline change** (separately shipped, possibly faster):

> Reviewer's charter requires `git ls-tree HEAD` verification of every file cited in evidence BEFORE issuing any acceptance verdict. Tests passing against the working tree do NOT establish durable delivery. Only `git ls-tree` presence establishes durability.

Charter directive can ship as its own small-fix slice (Proposal 067, ~1-2 SP) without waiting for the full validator rule. Belt + suspenders.

## How

Total ~7-12 SP, with Proposal 151 split out as the immediate prerequisite small-fix:

| Step | File | Effort |
|---|---|---|
| Add `Test-SpecrewCanonicalHandoffPresent` helper | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) | 1 SP |
| Pillar 1 canonical handoff validator rule | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror) | 1-2 SP |
| Pillar 2 trigger-bypass diagnosis augmentation | same file | 1 SP |
| Pillar 3 wrong-location detection | same file | 1 SP |
| **Pillar 4 state-advance cross-check** | same file + helper extension | 1-2 SP |
| **Pillar 5 review.md-vs-git-ls-tree cross-check** | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror) — new `Test-ReviewCitedFilesInTree` helper; gates iteration-closeout boundary | 2-3 SP |
| Integration tests covering all 5 shapes | `tests/integration/non-specrew-session-bypass.tests.ps1` (extend) | 1-2 SP |

## Acceptance criteria

- **AC1**: A boundary commit `boundary(review-signoff): ...` with no preceding Proposal 007 three-section handoff in session output emits WARN
- **AC2**: A closed iteration directory missing `dashboard.md` while having all other artifacts emits WARN with `non-Specrew-managed iteration` qualifier (not the generic `missing-dashboard-artifact` only)
- **AC3**: A `plan.md` or `tasks.md` file found in `C:/Users/<user>/.gemini/antigravity-cli/brain/<id>/` emits WARN with `artifact-in-ephemeral-location` qualifier and recommends canonical path
- **AC4**: Validator output remains backward-compatible — new rules add WARN entries; do not change exit code or fail iterations that previously passed
- **AC5**: `Test-SpecrewCanonicalHandoffPresent` is callable from sync-boundary-state.ps1 and other helpers; returns `$true` / `$false` for use as pre-condition checks. Legacy `=== SPECREW HANDOFF ===` text alone is insufficient unless accompanied by the three required sections or explicitly grandfathered migration metadata
- **AC6**: Mirror parity confirmed byte-identical for the two modified extension scripts
- **AC7** (Pillar 4): When `state.md` `Current Phase` changes across two commits for a human-verdict boundary (e.g., `review-signoff → retro`), the validator cross-checks `boundary_enforcement.verdict_history` and emits WARN if no matching `from_boundary → to_boundary` entry with non-empty `authorizing_human` exists. Pre-2026-05-26 iterations grandfathered via timestamp scope
- **AC8** (Pillar 4): `sync-boundary-state.ps1` refuses (hard-block, not WARN) to advance state for a human-verdict boundary unless the corresponding verdict-history append happens in the same transaction
- **AC9** (Pillar 5): When review.md cites a production code file (matching `\.(cs|tsx|ts|py|js|rs|go|ps1)$` outside `tests/` paths) AND that file is not present in the cited `Tree Under Review` commit per `git ls-tree -r <hash>`, validator emits FAIL severity (not WARN) — strong enough to block iteration-closeout
- **AC10** (Pillar 5): Test files (`tests/**/*.{cs,ts,py,etc}`) cited in review.md but missing from the cited tree emit WARN (lower severity — test scope may legitimately differ from review intent)
- **AC11** (Pillar 5): `validate-governance.ps1` gates iteration-closeout boundary on Pillar 5 PASS. A failed Pillar 5 must produce a clear repair path: "Reviewer cited <path> as evidence but tree <hash> doesn't contain it. Either stage + commit the file then re-issue the verdict, or remove the file from review.md evidence sections."

## Out of scope

- **Hard-fail on missing canonical handoff** — keep WARN-only initially; promote to FAIL after observed practice shows minimal false-positive rate
- **Auto-relocation of ephemeral-folder artifacts** — Proposal 075 owns; this proposal only warns
- **Host-specific handoff rendering quirks** — assumes the universal semantic contract is the three-section Proposal 007 handoff; host-specific menu/UI rendering remains separate
- **Hook-based enforcement** — Proposal 105 (Host-Native Hook Deployment) owns runtime layer; this proposal is validator-side detection

## Composition

- **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning)** — direct fit. All 3 shapes are form-vs-meaning failures (validator schema passes; meaning bypassed)
- **Proposal 067 (Small-Fix Slice Type)** — this proposal IS a natural small-fix slice (~3-5 SP, single iteration, well-scoped)
- **Proposal 075 (Update Artifact Backfill Discipline)** — companion. 075 fixes the detected gaps; this proposal detects them
- **Proposal 078 (Handoff Conversation Quality)** — composes deeply. 078 Pillar 5 is validator-enforced handoff-prose grading; this proposal's Pillar 1 is the precondition (canonical handoff presence check) that 078 Pillar 5 builds on
- **Proposal 105 (Host-Native Hook Deployment)** — lifts the same rules from cooperative-prescribed to runtime-enforced on hook-supporting hosts. This validator proposal is the cross-host backstop for Copilot (no hook surface) and the development-time detection layer
- **Proposal 151 (Boundary Handoff Contract Unification)** — immediate small-fix prerequisite. 151 repairs the conflicting prompt surfaces; 120 later enforces the unified contract mechanically across lifecycle evidence

## Risks

- **False positives on legacy iterations** — predate F-040 Wave A1 and Proposal 007's later three-section handoff contract. Mitigation: scope rule to iterations whose closing commit timestamp is after the relevant contract rollout, or explicitly grandfather historical evidence.
- **Heuristic window for canonical handoff presence** — N hours is judgment call. Mitigation: configurable via `.specrew/config.yml`; default 24h
- **Ephemeral-path list maintenance** — new hosts add new ephemeral paths. Mitigation: list comes from per-host registry; updated alongside Proposal 024 / 069 / 105 host work

## Empirical motivation

- 2026-05-25 F-044 dashboard backfill commit `4b458e38` — 10 closed iterations missing `dashboard.md` because original closeouts orchestrated by non-Specrew session
- 2026-05-25 Antigravity F-046 specify-phase `implementation_plan.md` in `C:/Users/alon.HOME/.gemini/antigravity-cli/brain/<session-id>/` — wrong-location instance
- 2026-05-25 Squad+Copilot PlanningPoC iter-001 repair (commits `32a4a74` + `903714e`) — handoff-block dropped after Scribe completion
- 2026-05-25 Antigravity F-046 specify-phase — handoff-block substituted by host-native question-prompt UI
- 2026-05-26 F-046 v0.27.2 — 4-gate autopilot bypass with zero handoff blocks emitted between boundary commits `0857e319 → f6155e54`
- 2026-05-26 PlanningPoC review-rerun post-compaction discipline drop (Sub-trigger 3c) — within a SINGLE Squad+Copilot dogfooding session, the stop immediately BEFORE compaction emitted the proper three-section handoff; the stop immediately AFTER compaction (review-rerun acceptance commit `f06491e5`) dropped to plain prose ("Review rerun passed. The packet is now accepted...") with no structured block. The same agent instance exhibited inconsistent discipline within a single session boundary. Second incident within the same dogfooding session (after the earlier Scribe-bookkeeping silence) — confirms compaction-related variant as a recurring sub-axis.
- **2026-05-26 PlanningPoC iter-002 silent boundary-state auto-advance (Pillar 4 motivator)** — after B1+B2 fix-and-re-review, Squad silently mutated `iterations/002/state.md` `Current Phase` from `review-signoff` to `retro` WITHOUT a human `approved for review-signoff` verdict. Files mutated: `.squad/identity/now.md`, `iterations/002/plan.md`, `iterations/002/review.md`, `iterations/002/state.md`. **Picard's independent audit caught the breach** and rolled state.md back (commit `a5866c1 fix(governance): repair iteration-002 boundary — retro → review-signoff`). Without Picard, the human would have been presented with a fait-accompli retro phase. This is a state-layer counterpart to Pillar 1's communication-layer detection — different mutation surface, structurally equivalent class.
- **2026-05-27 PlanningPoC iter-004 Reviewer-approves-working-tree-only-state (Pillar 5 motivator)** — iter-004 closed with `accepted` verdict and iteration-closeout commit `c6facc8`; user's post-update `git status` revealed 7 production code files cited as evidence in review.md were **never committed to ANY branch** (`git log --all` empty). Reviewer's `**Tree Under Review**: f4e01b7` provenance assertion was structurally false. Recovery via commit `29fce04`. This is the **most consequential shape** of the family because actual code can permanently vanish via `git reset --hard` / `git clean -fdx` / fresh clone — the other shapes corrupt audit trails but the code itself is recoverable. The lie isn't in the test results (tests passed) — it's in the commit-hash provenance assertion (tests ran against working-tree, verdict cited commit hash, files weren't in the commit).

Pattern recurs across multiple hosts, multiple sessions, multiple shapes (communication-layer + state-layer + reviewer-verification-layer), multiple compaction boundaries within a single session, AND across reviewer-protocol gaps that only multi-perspective independent audit (Picard) catches. Universal across multi-host expansion AND across long-session execution AND across single-perspective hosts that would lose Picard's safety net.

## Cross-references

- Memory: [[non-specrew-session-bypasses-triggers-2026-05-25]]
- file:///C:/Dev/Specrew/proposals/007-substantive-interaction-model.md
- file:///C:/Dev/Specrew/proposals/151-boundary-handoff-contract-unification.md
- file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md
- file:///C:/Dev/Specrew/proposals/075-update-artifact-backfill-discipline.md
- file:///C:/Dev/Specrew/proposals/078-handoff-conversation-quality.md
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md
- file:///C:/Dev/Specrew/proposals/INDEX.md

## Status history

- 2026-05-25: empirical observation captured in memory after F-044 backfill + Antigravity F-046 wrong-location + Squad+Copilot handoff-drop incidents. User direction: "Memorized it, and later we will create a bug proposal to fix it."
- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep. Scope is ~3-5 SP small-fix slice covering 3 detection rules (handoff-block presence, trigger-bypass diagnosis, wrong-location warning) + shared helper function. Composes tightly with 030 / 067 / 075 / 078 / 105.
- 2026-05-26 (later): **expanded with Pillar 4 (state-advance-without-verdict cross-check)** after PlanningPoC iter-002 silent auto-advance breach surfaced as a state-layer counterpart to Pillar 1's communication-layer detection. Picard's independent audit caught it (commit `a5866c1`); Pillar 4 makes the Picard role mechanical and host-portable. SP estimate raised 3-5 → 4-7. Memory `[[picard-boundary-state-auto-advance-catch-2026-05-26]]` absorbed.
- **2026-05-27: expanded with Pillar 5 (reviewer-approves-working-tree-only-state — review.md-vs-git-ls-tree cross-check) + priority bumped to Tier 1 HIGH PRIORITY**. PlanningPoC iter-004 surfaced the most consequential shape of the family: 7 production code files cited in review.md were never committed despite the iteration closing with `accepted` verdict. Tests passed against working-tree state; verdict cited commit hash; files weren't in the cited commit. User caught it by accident via `git status` after `specrew update`; recovery commit `29fce04` staged the missing work. The lie is in the commit-hash provenance assertion, not the test results. Pillar 5 adds `Test-ReviewCitedFilesInTree` validator helper + hard-gate iteration-closeout on PASS. Companion Reviewer-charter discipline change recommended as separate small-fix slice ([[proposal-067]] family, ~1-2 SP) to ship faster than the validator rule. SP estimate raised 4-7 → 6-10 (full Pillars 1-5). Memory `[[shape5-reviewer-approves-working-tree-only-state-2026-05-27]]` absorbed.
- **2026-05-31: amended after live boundary-stop regression surfaced stale contract conflict**. The generated start prompt still mandated the legacy `=== SPECREW HANDOFF ===` block while shipped Proposal 007 and the role charters require the three-section handoff with clickable `file:///` inspection targets. Proposal 151 was created as the immediate 2-4 SP small-fix slice to unify prompt surfaces and handoff evidence detection before this broader validator/backstop proposal ships. Title changed from "Handoff-Block" to "Handoff Contract"; SP estimate raised 6-10 → 7-12 to account for migration-compatible canonical handoff detection.
