# Iteration State: 011

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T001 (agent-callable handover authoring command `specrew handover author` — DF-7; the reachable replacement for the un-exported `Write-SpecrewHandoverContext`, drift D-005), proven end-to-end + green (HandoverAuthorCommand.Tests, 6 cases incl. SC-012 round-trip + SC-015 clobber-guard preservation + --stdin)
**Tasks Remaining**: T007 (deterministic test consolidation — SC-012/013/014/015, substantially covered by HandoverAuthorCommand + HookPacketCapture + HookVerdictCapture; confirm each SC has explicit proof), T008 + T009 (DF-1/DF-2, small) — plus the cross-host marker residual (drift-log D-001)
**In Progress**: (checkpointed, working tree clean) — T007 (deterministic test consolidation) is next
**Baseline Ref**: iteration-010 HEAD (`c5756473`)
**Updated**: 2026-06-14T05:05:00Z

## Charter

Iteration 011 fixes the **DF-3/4/5/7 boundary-authoring + verdict-integrity cluster** the
iteration-010 multi-host round-robin dogfood surfaced
(`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/010/dogfood-multihost-handover.md`).
Locked design + maintainer decisions:
`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/011/fix-plan-draft.md`
— **A3 hybrid authoring** (agent-callable command + mechanical Stop-hook backstop), **captured
human verdict-evidence** (not a forgeable param), **committed ≠ authorized** on resume. Core
principle: *do NOT rely on agent compliance for integrity-critical state.* Deferral recorded:
`f174-i010-defer-integrity-cluster-to-011`.

**Causal chain (one coherent fix):** `Write-SpecrewHandoverContext` is not agent-callable (DF-7) →
the boundary packet + `active_boundary` never persist (DF-3) → a resume reads committed-as-approved
(DF-4) → a bare "continue" advanced two un-authorized boundaries + the sync FABRICATED a human
verdict (DF-5). The committed tree is durable truth (antigravity recovered with no data loss), so
this is an integrity + UX + audit fix, not data-recovery.

**Sequence (from the fix plan):** Fix A (authoring + clobber) → Fix C (verdict capture) → Fix B
(committed ≠ authorized resume) → Fix D/E (DF-1 recap synthesis + DF-2 version/branch, small).
**Acceptance = a focused re-dogfood** of the DF-3/4/5/7 scenario (real-host behavior is the gate,
per the iteration-010 falsification lesson). **Out of this iteration:** DF-6 (cursor continuity)
stays WITHIN F-174 but a LATER iteration; DF-8 (agent-edits-governance) is a separate proposal.

## Specify (this boundary)

The feature spec
(`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/spec.md`) is
amended at the specify boundary:

- **FR-022 persist-clause refinement** (capture ≠ author): the agent still renders/authors the
  packet; persistence becomes mechanical (the transcript-capable Stop hook and/or an exposed
  command), grounded in T002's Stop-hook transcript access. The agent-authored + not-forced
  guarantees are unchanged.
- **FR-026 (new)** — verdict-integrity: the recorded boundary verdict derives from captured human
  input; no fabrication, no git-committer attribution; absent capture → recorded un-authorized.
- **FR-027 (new)** — committed ≠ authorized on resume; complements FR-017 on the authorization axis.
- **SC-012 / SC-013 / SC-014** — the acceptance for the above.

Guarantee-level only; mechanism (capture timing, match-strictness, the Antigravity fallback
specifics) is the plan boundary's job. DF-1 / DF-2 trace to existing FR-002 / FR-022 (no new FR).
**Specify APPROVED WITH INSTRUCTIONS** (2026-06-13, `f174-i011-specify-clarify-approved`).

## Clarify (this boundary)

Specify approved with 5 instructions (1+2 confirmed the FR-022-amendment + FR-026/027-split choices;
3+4 tightened the spec; 5 is a plan-carry). Resolutions logged in the spec Clarifications
(Session 2026-06-13 clarify boundary):

- **(3) FR-022 backstop is load-bearing** — the non-skippable Stop-hook capture is the integrity
  guarantee on hook-capable hosts; the exposed command is only a fast-path, never "remember to call
  it." FR-022 tightened.
- **(4) FR-026 identity** — record the approver only from a host surface that proves it; else
  unknown/unattributed (never git-committer/env, never fabricated). FR-026 tightened.
- **Match-strictness (open, proposed)** — a recognized verdict token tied to the named boundary, not
  "any human turn"; to CONFIRM at the clarify verdict.
- **Antigravity fallback** — record un-authorized + reconcile via `specrew start` (in FR-026 scope).
- **(5) DF-1 / DF-2 plan-carry** — explicit plan tasks + evidence checks under FR-002 / FR-022.

**Clarify APPROVED WITH INSTRUCTIONS** (2026-06-13, `f174-i011-clarify-plan-approved`): match-strictness
default confirmed (recognized token tied to the boundary; ambiguous → un-authorized), antigravity
fallback confirmed (un-authorized, don't block), SC-013 tightened + SC-015 (clobber) added, DF-1/DF-2
tasked.

## Plan (this boundary)

Task breakdown drafted in
`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/011/plan.md`,
fully traced to FR-022/FR-026/FR-027 + SC-012/013/014/015 (+ DF-1/DF-2 under FR-002/FR-022).

**Plan APPROVED WITH INSTRUCTIONS** (2026-06-13, `f174-i011-plan-tasks-approved`): cap RAISED to a
human-approved 22, DF-1/DF-2 (T008/T009) folded into the committed table (22/22, validator PASS),
T001 tightened (prove/export the callable surface), the re-dogfood made an explicit acceptance gate,
defer-priority recorded (T008/T009 first on overrun). Estimates not deflated.

## Tasks (this boundary)

Executable task tracking generated:
`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/011/tasks-progress.yml`
— T001–T009, all `planned`, mirroring the plan table (22/22).

**Tasks APPROVED WITH INSTRUCTIONS** (2026-06-13, `f174-i011-tasks-before-implement-approved`): cap raise +
DF-1/DF-2 fold confirmed; the cap revert filed as a closeout OBLIGATION (`f174-i011-cap-revert-obligation`).

## Before-implement (this boundary)

Readiness verified for implementation (Fix A → C → B → D/E):

- **Order CONFIRMED** (instruction 3): Fix A (T001–T003 authoring + clobber) → Fix C (T004–T005 verdict
  capture + integrity) → Fix B (T006 committed ≠ authorized resume) → tests (T007) → D/E (T008/T009). A
  before C/B because the authored packet must land before it can be verified or read.
- **Defer-priority CONFIRMED**: T008/T009 (DF-1/DF-2) FIRST on overrun; the integrity core (T001–T006), the
  T007 deterministic tests, and the real-host re-dogfood acceptance are **NON-deferrable**.
- **Target surfaces present**: `HandoverStore.ps1`, `sync-boundary-state.ps1`,
  `specrew-bootstrap-provider.ps1`, `specrew-where.ps1`, `Specrew.psd1` (the export surface for T001),
  `tests/bootstrap/`. Baseline `a1dbae5d` clean.
- **Cap-revert obligation filed**: `f174-i011-cap-revert-obligation` — restore the global cap 22→20 + rerun
  the validator at/after iter-011 closeout (a tracked closeout step, not a memory note).

**PAUSE POINT** (instruction 4): implementation is a fresh, substantial body of work; the durable plan +
tasks support a clean-context start next session. STOP at before-implement → implement for the maintainer's
implement go. No push / PR (instruction 5).

## Implement (this boundary)

Maintainer gave the implement go. A load-bearing under-specified decision was RESURFACED before writing
T004/T005 (per the before-implement instruction) and settled with the maintainer:
**`f174-i011-verdict-authority-stop-hook`** — the Stop/UserPromptSubmit hook is the PRIMARY verdict authority;
a second-chance explicit re-confirm covers hook-misses + hookless antigravity (the maintainer's two-mechanism
correction); honest antigravity limit (agent-relayed, no deterministic surface); no new command (reuse
`Add-SpecrewBoundaryAuthorization`); evidence-source tag per `verdict_history` entry; safety rule: prefer
losing a real approval over inventing one.

**Verdict-integrity CORE — DONE + green (T004/T005/T006):**

- **T005** (`2e1a78fb`) — boundary-sync STOPS fabricating (`approved for <X>` + git-committer DELETED);
  records the mechanical crossing only. `boundary-sync-atomic` reconciled into a falsification guard.
- **T006** (`fa6ab2e1` + `ec709f09`) — `Get-SpecrewPendingVerdictState`; `specrew where` + the bootstrap
  resume directive surface "AWAITING YOUR VERDICT" when committed ≠ authorized (FR-027), every host.
- **T004** (`115f98d9` + `d35c92c2` + `be93c771`; **contiguity fix `f29333d6`**) — the hook captures the
  human's typed verdict from the transcript (recognizer + reader tied to the packet marker), advances the gate
  with evidence-source `hook-captured-from-transcript`, identity `unattributed`. Proven end-to-end
  (`HookVerdictCapture.Tests`). **Post-"done" the maintainer falsified a HIGH from-skip hole** (forward-only was
  not one-boundary-at-a-time: a real approval for a non-contiguous marker advanced a later gate while an earlier
  one was never authorized). Fixed with a **gate-contiguity guard** (marker FROM == authorized cursor AND TO ==
  FROM's immediate successor, else reject + journal `marker-cursor-mismatch`); 5 falsification cases green.

**Enabling prerequisite (maintainer-directed):** the central hook-cwd-resolution fix (`ff34e776`,
`f174-i011-hook-cwd-central-resolution`) — claude `${CLAUDE_PROJECT_DIR}` placeholder + per-machine launcher
for codex/copilot/cursor; the SessionStart bootstrap + Stop handover ride these hooks.

**Authoring side — DONE + green (T002/T003):**

- **T002** (mechanical VERBATIM packet capture, FR-022/DF-3) — `Get-SpecrewCapturedBoundaryPacket` reads the host
  transcript for the agent's ACTUALLY-RENDERED boundary packet (marker-tied; a new `-Raw` transcript read so the six
  `## ` headers + newlines survive verbatim; a substantive-content floor, NOT six exact headers — the
  form-without-runtime-compliance trap). It lands in a NEW THIRD section-ownership category (`Get-SpecrewHandover`
  `CapturedSections`, excluded from BOTH the mechanical and agent-owned sets). The handover-file parser
  (`ConvertFrom-SpecrewHandoverFile`) was made captured-section-verbatim-aware (the maintainer/advisor BLOCKER: the
  packet's own `## ` would otherwise shred it on read-back) — inside a captured section a `## ` line closes it ONLY on
  an EXACT canonical title. `active_boundary` is the forward-most of {session working position, prior file value, the
  marker FROM} — set from the marker, NEVER regressing; the packet is WRITTEN only when the active boundary is within
  the marker's `[FROM..TO]` range (a stale packet from a boundary already passed is dropped). Wired into
  `Update-SpecrewRollingHandover`, fully fail-open.
- **T003** (clobber guard, SC-015) — CENTRALIZED in the shared `Write-SpecrewRollingHandoverContent` so BOTH writers
  (the hook floor-writer AND the agent body-author `Write-SpecrewHandoverContext`, which T001 exposes) honor it (the
  advisor's both-writers catch). A later generic / no-marker / duplicate Stop PRESERVES the authored packet within its
  boundary; a forward boundary change REPLACES the stale one.
- **Tests**: `HookPacketCapture.Tests` — 8 falsification cases end-to-end against the real Stop-hook provider with a
  REALISTIC six-section packet (1 verbatim round-trip, 2 resume-inherits-authored, 3 no-marker-no-capture, 4
  stale-no-regress, 5 no-packet-preserves, 6 generic-Stop-preserves, 8 idempotent, 9 forward-change-replaces). The
  `HandoverHookPrimary` partition test updated to the THREE-way ownership partition (test 7 = mirror parity stays
  green; the two changed files are module-shipped, no mirror). Caught + fixed: the single-element-array return unwrap
  (the documented gotcha — callers must `@()`-wrap; a leading-comma "fix" NESTS the array and breaks `-contains`).

**Comprehensive regression: 43/43 suites, 0 failed** across the hook / dispatcher / parity / boundary / handover /
refocus / gate-stop / verdict-capture surface.

**FR-028 hook install/discovery hardening — DONE + green (T010/T011/T012, mid-implement scope amendment
`f174-i011-hook-deploy-hardening`, maintainer pre-approved; cap RAISED 22→32):** the maintainer surfaced that
hook-driven startup is now the primary path while hooks deploy only for PATH-detected hosts — a silent-degradation
hole when a user adds codex/copilot/cursor AFTER `specrew init`. Three layers, each with folded tests:
- **T010** (`1f9b83fb`, SC-016) — proactive provisioning at init+update for ALL hook-capable registry hosts
  (`Get-SpecrewHookCapableHosts` keyed on the manifest `RefocusHookBindings` capability, not PATH detection);
  preserve user entries, replace only Specrew-owned, respect opt-outs, fail open.
- **T011** (`dea3540c`, SC-017) — the `specrew hooks status|install|remove [--host]` repair surface
  (dispatcher-only, no project-setup gate) + the non-mirrored `Get-SpecrewHooksStatus` inspector
  (installed/missing/stale/opted-out/failed).
- **T012** (`457a398d`, SC-018) — the always-loaded degradation diagnostic (`Get-SpecrewHookDegradationWarning`
  warn-once gate + `Test-SpecrewBootstrapDirectiveArrived`); surfaced on the copilot template + `specrew hooks status`.
- **145-review fixes** (`1aa8b2df`) — `install` no longer reports a false "installed" on a deploy failure
  (defect-001) + 3 cheap hardenings; governance-validator pipe fix (`603a639a`); D-004 capacity drift parked.

**Authoring fast-path — DONE + green (T001, DF-7):** `specrew handover author` (`scripts/specrew-handover.ps1`,
registered in `specrew.ps1` + Show-Usage + FileList) is the reachable, agent-callable replacement for the
un-exported `Write-SpecrewHandoverContext`. It parses a markdown body (`--from <file>` | `--stdin`) into the
Pillar-2 handover sections via the SAME `ConvertFrom-SpecrewHandoverFile` reader a resume uses (tolerant
lead-phrase header matching; unrecognized headers reported + ignored), resolves feature/boundary/host from
committed session state (flag-overridable), and writes through `Write-SpecrewHandoverContext` → the shared atomic
writer, so the centralized clobber guard holds (a hook-captured boundary packet and the agent's interpretive body
coexist). The FR-022 bootstrap directive (all 3 mirror copies) now NAMES this reachable command. Shipped as a
COMMAND, not a module export (drift D-005 — agents invoke `specrew ...`, never module functions). Proven by
`HandoverAuthorCommand.Tests` (round-trip incl. interpretive sections SC-012, tolerant headers, dispatch arm,
unrecognized-skip, clobber-guard preservation SC-015, --stdin).

**REMAINING:** T007 (deterministic test consolidation — substantially covered by HandoverAuthorCommand +
HookPacketCapture + HookVerdictCapture; confirm each of SC-012/013/014/015 has explicit proof), T008/T009
(DF-1/DF-2, small, first-to-defer), the cross-host marker residual (drift-log D-001). Then the closeout cap-revert
(32→20) + the real-host re-dogfood acceptance gate.

**Process note (honest):** task-implementation commits this phase used the `feat/fix(174):` conventional-commit
prefix with the T0NN reference in the body, rather than the `boundary(implement): T0NN` prefix; focused-per-task
discipline held (one task per commit, tests riding with code). `boundary(implement): T0NN` adopted going forward.
