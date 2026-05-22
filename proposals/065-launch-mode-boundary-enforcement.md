---
proposal: 065
title: Launch-Mode Boundary Enforcement (Tool-Call-Layer Intercept for Lifecycle Boundaries)
status: candidate
phase: phase-2
estimated-sp: 5-7
discussion: ad-hoc 2026-05-22 session
---

# Launch-Mode Boundary Enforcement (Tool-Call-Layer Intercept for Lifecycle Boundaries)

## Why

Specrew's lifecycle methodology depends on a hard contract: **the Crew stops at every approval boundary and waits for explicit human authorization before crossing**. The boundaries are: `specify`, `clarify`, `plan`, `tasks`, `before-implement`, `review-signoff`, `retro`, `iteration-closeout`, `feature-closeout`. This contract is what differentiates Specrew from vanilla autopilot CLI tooling — it is the methodology guarantee.

The contract is currently enforced **by prose alone**: agent charters tell the Crew to stop, coordinator prompts tell the Crew to wait, kickoff briefs from the maintainer reinforce the discipline. **The prose has no mechanical teeth at the layer where it matters**, and four empirical incidents in five days have made the gap unignorable.

### Empirical incident sequence

| Date | Project | Pattern | Severity |
|---|---|---|---|
| 2026-05-18 | WSL trial (Moment20) | Squad silently auto-resolved scope decisions (50 balls max, materials, etc.) without asking. Form: "best guess on autopilot." Meaning: bypassed clarify. | Documented (memory `project-wsl-trial-autopilot-clarify-gap-2026-05-18`); motivated Proposal 053 |
| 2026-05-19 | Gym subscription test (`C:\Temp\spec023\test`) | Squad ran full lifecycle with only 2 human pauses; auto-resolved tech stack, permission model, db, frontend, auth, hosting. | Documented (memory `project-gym-test-intake-questioning-gap-2026-05-19`); motivated Proposal 063 |
| 2026-05-20 | F-024 (this repo, planning→implementation) | Squad EXPLICITLY printed the most-emphatic prose boundary message yet ("I stopped at the implementation-approval boundary because Specrew's lifecycle requires explicit human authorization"). Copilot CLI's autopilot continued anyway. | Documented (memory `project-f024-boundary-compaction-breach-2026-05-20`); motivated Proposal 066 (shipped 2026-05-20) |
| 2026-05-22 | **F-039 in-flight implementation of THIS PROPOSAL** | Squad's `--autopilot` was already off (Proposal 066 default). Yet the agent's single response after `/speckit.clarify` chained `/speckit.specrew-speckit.before-plan → /speckit.plan → /speckit.specrew-speckit.sync-plan → /speckit.tasks` without surfacing a single human approval prompt. The plan→tasks boundary was crossed by autopilot mid-feature. | Documented inline in `specs/039-launch-mode-boundary-enforcement/iterations/001/drift-log.md` |

The 2026-05-22 incident is meta-conclusive: it happened **while the Crew was implementing the very feature designed to prevent it**. It also happened in `gate-respecting` mode — the mode Proposal 066 introduced specifically to stop the prior incidents. That means Proposal 066's `gate-respecting` default closed one gap (host-level `--autopilot` no longer auto-continues between turns) but exposed a deeper one: **the agent can emit multiple tool calls in a single turn**, and the host's turn-boundary gating doesn't see across them.

### The structural defect

Three layers are in play, each with its own notion of "continuation":

1. **Agent layer** (the LLM, e.g., `claude-sonnet-4.5`): emits zero or more tool calls per response turn. The agent reads charters + prompts + briefs and *tries* to respect boundaries. But the agent's choice of how many tool calls to chain in one turn is a prose-level inference. There is no programmatic floor on how much the agent can pack into a single turn.

2. **Host layer** (the CLI runtime, e.g., Copilot CLI, Claude Code, Codex): receives the agent's response, executes the tool calls one by one, returns results to the agent, and decides when to elicit user input. `--autopilot` lets the host auto-advance between **turns** without user input. `gate-respecting` (Proposal 066) waits for user input between **turns**. **Neither mode intercepts between tool calls inside the same turn.**

3. **Methodology layer** (Specrew's lifecycle): defines a set of boundary-advancing tool invocations (`/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, etc.). Each of these is a tool call from the host's perspective and from the agent's perspective. **From Specrew's perspective, each crosses a boundary that requires human authorization. From the host's and agent's perspective, they are ordinary tool calls.**

The defect: there is no mechanism that intercepts **between tool calls within one turn** to refuse a boundary-advancing invocation when the previous boundary's authorization hasn't been recorded. Prose instructions to the agent can shift the agent's choice probabilistically. They cannot guarantee it. Methodology guarantees that rely on agent compliance with prose are decorative.

### What the user said (2026-05-22)

> "I think we need visibility to the configuration of Specrew. Maybe at `specrew start` we can provide the configuration to the user? Like started in auto approve mode or something? Also at the first `specrew start` we should do as part of the intake these questions about the level of review and guidance we want the user to do."

The visibility ask (companion Proposal 098 "Launch Posture Visibility") and the intake-cadence ask (composition with Proposals 015 and 063) are both real, but they are *adjacent* surfaces. They reduce the probability of incidents. They don't fix the structural defect that this proposal addresses: **per-tool-call mechanical enforcement of lifecycle boundary contracts, independent of any prompt prose or host-level autopilot mode**.

## What (Four Pillars)

### Pillar 1 — Skill-Level Authorization Gate

Each Specrew-managed boundary-advancing skill — currently:

- `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md`
- `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-clarify.md`
- `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-plan.md`
- `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-tasks.md`
- `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-review-signoff.md`
- `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-retro.md`
- `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-iteration-closeout.md`
- `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-feature-closeout.md`

…and the corresponding `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks` upstream commands (Spec Kit's own commands which Specrew composes with) — runs a **first-line authorization gate** before executing any of its body:

```powershell
# Inside each boundary-advancing skill, before any other work:
$gateResult = Test-SpecrewBoundaryAuthorization `
    -ProjectRoot $resolvedProjectPath `
    -CurrentBoundary 'plan' `
    -RequestedBoundary 'tasks'

if (-not $gateResult.Authorized) {
    Write-SpecrewBoundaryAuthorizationDirective `
        -CurrentBoundary $gateResult.CurrentBoundary `
        -RequestedBoundary $gateResult.RequestedBoundary `
        -AuthorizationFormat $gateResult.AuthorizationFormat
    throw $gateResult.RejectionMessage
}
```

`Test-SpecrewBoundaryAuthorization` reads `.specrew/start-context.json` (extended schema, Pillar 3) and returns `Authorized = $false` unless the maintainer's most recent verdict explicitly authorizes the requested boundary. The skill **throws** on `$false`, terminating execution before any boundary advancement happens.

This is the mechanical teeth. The host runs the skill; the skill refuses to advance; the host returns the failure to the agent; the agent surfaces the directive to the maintainer; the maintainer types the verdict; the verdict is parsed and persisted; the next skill invocation passes the gate. **The agent cannot chain past a refusal, because the chain literally stops at the failed tool call.**

### Pillar 2 — Verdict Parser + Authorization Persistence

The maintainer's authorization verdict is a structured string. Per memory `feedback_verdict_boundary_naming_2026_05_22.md`, the verdict MUST name the exact target boundary. Recognized verdict shapes:

- `approved for <boundary>-boundary entry` — authorizes advancement INTO the named boundary
- `approved for <boundary>` (short form, equivalent)
- `approved for review-boundary AND review-signoff` (compound — covers a substantive-review verdict that legitimately progresses two boundaries)
- `rejected for <boundary>` — explicit refusal; agent must surface a re-plan or re-clarify
- `parked` — no advancement; explicitly hold the current state

The Crew (during regular operation, after parsing the maintainer's message containing one of these strings) calls:

```powershell
Add-SpecrewBoundaryAuthorization `
    -ProjectRoot $resolvedProjectPath `
    -CurrentBoundary 'plan' `
    -AuthorizedBoundary 'tasks' `
    -AuthorizingHuman 'Alon Fliess (typed verdict in interactive session)' `
    -VerdictText 'approved for tasks-boundary entry'
```

This writes the authorization into `.specrew/start-context.json` (extended schema). Subsequent boundary skills consult the same store to determine whether they may advance.

A pre-existing helper `Resolve-SpecrewBoundaryAuthCommitHash` already extracts a commit-hash-anchor for the authorization. This proposal extends the persistence to include the **verdict text** and the **timestamp at which the verdict was parsed**, so the audit trail is reconstructible.

### Pillar 3 — `.specrew/start-context.json` Schema Extension

Add a `boundary_enforcement` section:

```json
{
  "schema": "v2",
  "boundary_enforcement": {
    "enabled": true,
    "last_authorized_boundary": "plan",
    "pending_next_boundary": null,
    "verdict_history": [
      {
        "from_boundary": "clarify",
        "to_boundary": "plan",
        "verdict_text": "approved for plan-boundary entry",
        "authorizing_human": "Alon Fliess",
        "recorded_at": "2026-05-22T11:42:18Z",
        "auth_commit_hash": "ad1a970a"
      },
      ...
    ],
    "bypass_history": []
  }
}
```

Schema versioning ensures backward compatibility — older Specrew installs without the section default to `enabled = false` (legacy permissive mode), and the validator's Test-SessionStateBoundaryCanonical rule (Proposal 090) is extended to detect schema-version drift.

### Pillar 4 — Emergency Bypass + Audit Trail

For genuine emergencies (debugging a stuck enforcement, batch-replaying iterations for migration, etc.), `specrew start --bypass-boundary-enforcement --reason "<text>"` disables the gate for the session.

Hard constraints on the bypass:

- **`--reason` is MANDATORY**. `specrew start --bypass-boundary-enforcement` without `--reason` exits with error and a directive that explains why bypass is dangerous.
- **Session-scoped, not boundary-scoped**. One bypass invocation disables enforcement for the entire session. There is no "bypass this one boundary, then resume enforcement" mode — the user accepts the consequences for the whole session, which discourages casual bypass.
- **Audit trail**: every bypassed boundary writes an entry to `.squad/decisions.md` with the bypass reason, timestamp, the boundary that was bypassed, and the session ID. The validator (extending Test-SessionStateBoundaryCanonical) checks the bypass entries against the verdict history for reconciliation.
- **Bypass entries decay the trust posture**: the launch banner (companion Proposal 098 candidate) shows a prominent `[BYPASS ACTIVE]` indicator. The next `specrew start` without `--bypass-boundary-enforcement` returns to enforcement.

## How (Implementation Plan)

This proposal ships as F-039 (the in-flight feature). Sequencing:

| Step | What | Files | Effort |
|---|---|---|---|
| 1 | Schema extension | `.specrew/start-context.json` schema, validator rule (Proposal 090's Test-SessionStateBoundaryCanonical) | 0.5 SP |
| 2 | Authorization helpers | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror): `Test-SpecrewBoundaryAuthorization`, `Add-SpecrewBoundaryAuthorization`, `Get-SpecrewBoundaryAuthorizationHistory`, `Write-SpecrewBoundaryAuthorizationDirective` | 1.5 SP |
| 3 | Verdict parser | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror): `Parse-SpecrewBoundaryVerdict` recognizes the verdict shapes; returns structured `{Action, Boundary, Authorized}` object | 0.75 SP |
| 4 | Skill-level gate insertion | All 8 sync-* command files + the 4 upstream `/speckit.*` commands. Gate is identical across skills; pre-existing Get-SpecrewBoundaryOrder dictates which boundary comes next | 1.5 SP |
| 5 | Bypass mechanism | `scripts/specrew-start.ps1`: parse `--bypass-boundary-enforcement` + `--reason`; persist bypass state; write audit-trail entries to `.squad/decisions.md` | 1.0 SP |
| 6 | Tests | `tests/integration/boundary-enforcement.tests.ps1`: every verdict shape recognized; every skill blocks without authorization; bypass requires reason; audit trail integrity; schema-version drift detection | 1.5 SP |
| 7 | Mirror parity + CHANGELOG + INDEX | both mirrors; entry under `### Added`; proposal status → shipped | 0.5 SP |

**Total**: ~7 SP. Single iteration.

### Required quality gates

The hardening-gate must address:

| Concern | Why blocking |
|---|---|
| **Security**: bypass-mechanism privilege escalation | `--bypass-boundary-enforcement` is the only escape hatch; without mandatory `--reason` it becomes a silent skip |
| **Correctness**: zero false-negatives | A single missed boundary block undermines the entire methodology guarantee. Test every skill blocks. |
| **Fail-safe**: hook failure must BLOCK, not skip | If `Test-SpecrewBoundaryAuthorization` throws an unhandled exception, the skill must surface the failure (skill exits non-zero) — not catch and continue. |
| **State integrity**: corrupt `.specrew/start-context.json` | Permissive degradation is unacceptable — a corrupted store must surface a recovery directive, not silently treat enforcement as disabled |
| **Schema migration**: pre-065 sessions without `boundary_enforcement` section | First `specrew start` after upgrade surfaces a migration directive; after acknowledgment, the section is written with `enabled = true` and empty history |

### Multi-host coverage

The skill-level gate is host-agnostic — Claude Code, Copilot CLI, Codex CLI, VS Code Chat all execute the same skill files. The gate works identically across hosts. No host-specific shimming required.

This composes with **Proposal 069** (Multi-Host Launch Path) — F-039's skill gates become the methodology guarantee that survives a `--host` switch.

## Composition with Other Proposals

| Proposal | Relationship |
|---|---|
| **Proposal 066** (Gate-Respecting Default, shipped 2026-05-20) | Predecessor. 066 made `--autopilot` opt-in at the host level; 065 institutes mechanical enforcement at the tool-call level. Together: 066 prevents host-level continuation between turns; 065 prevents agent-driven chaining across turns. |
| **Proposal 063** (Substantive Intake Questioning, F-040 next) | Hard prerequisite consumer. Without 065, 063's intake questions can be auto-chained past by the agent in a single turn. 065 ships FIRST. |
| **Proposal 038** (Adaptive Boundary Discipline) | Future composition. 038 introduces per-boundary classes (human-judgment-required / mechanical-execution / strategic-progression). 065 MVP treats all eight as human-judgment-required. When 038 ships, 065's gate consults the class map from `.specrew/config.yml`. |
| **Proposal 090** (Closeout Lifecycle Sync Commands, shipped 2026-05-22) | Composes with the schema validator. Test-SessionStateBoundaryCanonical (added by 090) extends to validate the new `boundary_enforcement` section. |
| **Proposal 098** (Launch Posture Visibility, candidate) | Companion. 098 surfaces enforcement state at launch (e.g., `[BYPASS ACTIVE]` banner). Composable; 065 ships without 098. |
| **Proposal 015** (Expertise-Aware Adaptive Interaction) | Future composition. 015's expertise dial may modulate verbosity of directive messages — concise for experts, explanatory for beginners. 065 ships with a fixed directive shape and lets 015 modulate it later. |
| **Proposal 069** (Multi-Host Launch Path) | Host-agnostic by design (Pillar 1 is at skill level, not host level). When 069 ships, 065's mechanism extends to Claude Code and Codex without modification. |

## Acceptance Signals

- **AC1**: Agent emits a chained response containing `/speckit.plan → /speckit.tasks` in one turn. The plan skill succeeds. The tasks skill FAILS with the authorization directive. The agent's next response surfaces the directive to the maintainer. Verified by integration test simulating chained tool calls.

- **AC2**: Maintainer types `approved for tasks-boundary entry` in response. `Parse-SpecrewBoundaryVerdict` parses correctly; `Add-SpecrewBoundaryAuthorization` writes the authorization; next `/speckit.tasks` invocation passes the gate. Verified by integration test.

- **AC3**: Maintainer types ambiguous verdict ("looks good" / "yep" / "continue"). Parser returns `Authorized = $false`. Skill blocks. Directive surfaces with the recognized verdict shapes. Verified by integration test against ambiguous inputs.

- **AC4**: `specrew start --bypass-boundary-enforcement` (no `--reason`) exits with error. Verified by integration test.

- **AC5**: `specrew start --bypass-boundary-enforcement --reason "schema migration replay"` succeeds. Subsequent boundary advances are unblocked. Every bypassed boundary writes an audit entry to `.squad/decisions.md`. Verified by integration test.

- **AC6**: Existing session-state files without `boundary_enforcement` section: first `specrew start` after upgrade surfaces a migration directive; after acknowledgment, writes the section with `enabled = true` and empty history. Verified by integration test against a pre-065 fixture.

- **AC7**: Corrupted `start-context.json` (invalid JSON, missing required fields): `specrew start` surfaces a recovery directive; the boundary-enforcement gate does NOT silently degrade to permissive mode. Verified by integration test against corrupted fixtures.

- **AC8**: Hook failure (e.g., `Test-SpecrewBoundaryAuthorization` throws) propagates as skill failure. The skill exits non-zero. The agent surfaces the failure. The boundary is NOT crossed. Verified by integration test injecting a hook fault.

- **AC9**: Compound verdict `approved for review-boundary AND review-signoff` authorizes advancement from review-boundary INTO review-signoff. The verdict parser recognizes the AND form. Verified by integration test.

- **AC10**: Mirror parity across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/`. Verified by SHA256 check on touched files.

- **AC11**: Empirical replay of the 2026-05-22 F-039 incident: simulated agent chains `clarify → plan → tasks` in one turn. Plan executes successfully. Tasks blocks. Drift-log entry generated. Verified by integration test.

## Out of Scope

- **Per-boundary classification** (human-judgment vs mechanical-execution vs strategic-progression): owned by Proposal 038. 065 MVP treats all eight as human-judgment-required. When 038 ships, 065's gate becomes class-aware via a config lookup.

- **Verdict-shape autocomplete or natural-language tolerance**: 065 requires precise verdict shapes (per memory `feedback_verdict_boundary_naming_2026_05_22.md`). Natural-language tolerance would weaken the audit trail. Future enhancement could add a confirmation pass for ambiguous verdicts, but the core mechanism requires exactness.

- **Cross-feature enforcement coordination**: 065's scope is a single feature's lifecycle. If a maintainer runs two features concurrently in two terminals, each session has independent enforcement state. Multi-feature coordination is Proposal 010 (Multi-Developer Reconciliation) territory.

- **Bypass-bypass detection**: detecting "the maintainer typed an authorization without actually reviewing the artifacts" is a meaning-vs-form problem that 065 cannot solve mechanically. Proposal 030 (Quality Hardening Bundle) addresses form-vs-meaning verification more broadly.

- **CI enforcement**: 065's gate fires during interactive `specrew start` sessions. CI runs (PR-CI, push-to-main) don't interact with the boundary skills directly; they invoke `validate-governance.ps1` which is unaffected. CI enforcement of the audit trail is Proposal 089's territory (PR Review Integration, partially shipped F-038).

- **Launch posture visibility**: companion Proposal 098 (candidate). 065 ships without 098; 098 reads 065's state at launch.

## Cross-References

- **Empirical motivation**: 4 incidents in 5 days; all four memories captured in `C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/`
- **In-flight implementation**: F-039 at `specs/039-launch-mode-boundary-enforcement/` (parked at plan boundary pending this proposal landing)
- **Drift-log evidence**: `specs/039-launch-mode-boundary-enforcement/iterations/001/drift-log.md` records the 2026-05-22 chain-past-plan incident
- **Predecessor**: Proposal 066 (shipped 2026-05-20)
- **Companion**: Proposal 098 candidate (Launch Posture Visibility — to be drafted)
- **Hard-prerequisite-for**: Proposal 063 (F-040), Proposal 069 (Multi-Host Launch Path)
- **Composes-with**: Proposals 038, 090, 015
- **INDEX**: file:///C:/Dev/Specrew/proposals/INDEX.md
