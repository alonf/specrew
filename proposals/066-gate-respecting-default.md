---
proposal: 066
title: Gate-Respecting Default + --autonomous Opt-In
status: shipped
phase: phase-2
estimated-sp: 3
shipped-as: chore commit c55ec92 (2026-05-20)
discussion: ad-hoc 2026-05-20 session
---

# Gate-Respecting Default + `--autonomous` Opt-In

## Why

Squad's lifecycle approval boundaries (specify, clarify, plan, tasks, implement, review, retro) were being bypassed without human input. Three independent empirical incidents over three days revealed the same root cause:

| Date | Project | Symptom |
|---|---|---|
| 2026-05-18 | WSL trial (Moment20) | Squad silently auto-resolved scope decisions (50 balls max, materials, etc.) without asking — captured in `[[project-wsl-trial-autopilot-clarify-gap-2026-05-18]]` |
| 2026-05-19 | Gym subscription test (`C:\Temp\spec023\test`) | Squad ran full lifecycle with only 2 human pauses; auto-resolved tech stack from a 13-line `.vscode/settings.json` hint, plus permission model, db, frontend, auth, hosting — captured in `[[project-gym-test-intake-questioning-gap-2026-05-19]]` |
| 2026-05-20 | F-024 (this repo, planning-to-implementation) | Squad EXPLICITLY printed the most-emphatic prose boundary message yet ("I stopped at the implementation-approval boundary because Specrew's lifecycle requires explicit human authorization"). Copilot CLI continued anyway — captured in `[[project-f024-boundary-compaction-breach-2026-05-20]]` |

The pattern escalated across the three incidents: the more emphatic Squad's prose boundary got, the more starkly the gap was exposed. There is no prose form Copilot CLI's `--autopilot` mode will respect, because `--autopilot` does not parse agent prose for boundary semantics.

### Root cause

`scripts/specrew-start.ps1:3348` previously contained:

```powershell
$useAutopilot = -not $requiresInteractiveIntake
```

This auto-enabled Specrew's `copilot_autopilot` flag (which propagates to Copilot CLI's `--autopilot` launch flag) once feature scope was grounded. Introduced in commit `8453767` (2026-05-06) and made platform-uniform in commit `872b5a8` (2026-05-17). Once `--autopilot` was on, Squad's "I am stopping for human verdict" prose handoffs were inert at the host runtime layer.

### What the user actually wanted

Verbatim from the 2026-05-20 ad-hoc session:

> "We must stop on each gate unless we are in a fast mode (like when I go to sleep)."

Three modes are needed, only two existed:

| Mode | Behavior | Trigger |
|---|---|---|
| Interactive | Every interaction prompts user | Pre-intake (existing) |
| **Gate-respecting** (was missing as the default) | Tools run freely between gates; STOP at lifecycle approval boundaries | Should be default for post-intake work |
| Autonomous | Tools run freely AND lifecycle gates auto-advance | Explicit opt-in for overnight unattended runs |

## What

`scripts/specrew-start.ps1:3348` now reads:

```powershell
$useAutopilot = $Autonomous -and -not $requiresInteractiveIntake
```

Default for post-intake work: `$Autonomous = $false` → `$useAutopilot = $false` → no `--autopilot` flag passed to Copilot CLI → Squad stops at every lifecycle approval boundary.

New `-Autonomous` PowerShell switch parameter and `--autonomous` CLI argument enable autopilot opt-in for unattended runs.

Intake stage stays interactive regardless of `--autonomous` so initial scope grounding is never auto-resolved.

`--allow-all` (tool-call approval) and `--autonomous` (lifecycle-gate advancement) are now documented as independent concerns. Approval-operator-note text expanded to four cases reflecting the four mode combinations:

- gate-respecting + allow-all (new default)
- gate-respecting + prompt-approvals
- autonomous + allow-all (`--autonomous`)
- autonomous + prompt-approvals (`--autonomous --prompt-approvals`)

## How (already shipped)

Single commit on main: `c55ec92` (2026-05-20).

| File | Change |
|---|---|
| `scripts/specrew-start.ps1` | Added `-Autonomous` switch parameter (line 23); added `--autonomous` CLI parser case (line ~150); flipped `$useAutopilot` default logic (line 3348); rewrote help text section; expanded `$approvalOperatorNote` to four cases |
| `tests/integration/start-command.ps1` | Flipped line 454 (live-launch should NOT have `--autopilot` by default); flipped line 539 (`copilot_autopilot` should be FALSE by default); added Test 3c exercising `--autonomous` opt-in; updated operator-note substring match |
| `docs/user-guide.md` | Documents gate-respecting default + independence of `--allow-all` and `--autonomous` |
| `docs/getting-started.md` | Three usage examples (default / `--prompt-approvals` / `--autonomous`) |

Functional smoke test verified in a clean sandbox:

```text
specrew start "feature" --no-launch
  → copilot_autopilot: false  ✓
  → launch args have NO --autopilot flag  ✓

specrew start "feature" --no-launch --autonomous
  → copilot_autopilot: true  ✓
  → launch args have --autopilot  ✓
```

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **055 (Always-In-Flow Discipline + Slice-Type Catalog)** | This proposal's documentation gap (initially shipped as chore commit without proposal entry) is precisely the kind of pattern 055 is meant to govern. Retroactive documentation at proposal 066 closes the methodology loop. Future similar fixes should ship through the appropriate slice from 055's catalog. |
| **038 (F-016 Adaptive Boundary Discipline)** | Proposal 038 refines F-016 form-vs-meaning into three boundary classes. This proposal addresses the immediate symptom; 038 addresses the deeper architecture. They compose. |
| **053 (Autopilot Decision Transparency)** | When `--autonomous` is opted into, gate auto-advances are themselves auto-resolution events that 053's discipline should surface in artifacts. |
| **063 (Substantive Intake Questioning)** | F-025 (intake protocol) ships into a runtime where its 12-category interview can actually elicit input because gate-respecting is now the default. Without this proposal shipping first, F-025's intake would still be bypassed by autopilot. |
| **065 (Hook-Enforced Boundaries) — candidate** | This proposal solves the immediate behavioral problem via flag default. Proposal 065 adds defense in depth via tool-level hooks so even a future misbehaving Squad cannot bypass a boundary. They are complementary: 066 fixes the urgent case; 065 is the architectural reinforcement. |

## Acceptance evidence

- Integration test `tests/integration/start-command.ps1` Test 3c added and passes
- Functional smoke verified `copilot_autopilot` default false; `--autonomous` opt-in produces true
- Existing assertions at lines 337, 614, 718 (intake-unresolved should keep autopilot off) continue to pass without modification — the new default is consistent with the pre-existing intake-only-interactive contract

## Methodology learning (for 055's evidence corpus)

This proposal was shipped as a chore commit BEFORE its proposal entry existed. That was the wrong order under Proposal 055's "always-in-flow discipline." Retroactive documentation closes the gap but does not erase the lesson:

**Even one-hour fixes that change user-facing default behavior should produce a proposal-level artifact at ship time, not after the fact.** The proposal does not need to be heavy (this one is ~80 lines) but it must exist so that future readers searching the proposals/ surface find the design rationale, not just a commit message.

When Proposal 055 ships, the slice-type catalog should explicitly include a `behavior-default-change` slice with mandatory proposal-entry + CHANGELOG-entry + decision-ledger artifacts, even when the code change is small.

## Cross-references

- Commit: `c55ec92` on main, 2026-05-20
- Memory: `[[project-f024-boundary-compaction-breach-2026-05-20]]`
- Memory: `[[project-gym-test-intake-questioning-gap-2026-05-19]]`
- Memory: `[[project-wsl-trial-autopilot-clarify-gap-2026-05-18]]`
- file:///C:/Dev/Specrew/proposals/055-always-in-flow-bug-fix-lifecycle.md
- file:///C:/Dev/Specrew/proposals/063-substantive-intake-questioning.md
- file:///C:/Dev/Specrew/proposals/INDEX.md
