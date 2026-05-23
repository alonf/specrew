---
proposal: 107
title: Host-Aware Routing Plan Fallback (F-040 Follow-Up)
status: candidate
phase: phase-2
estimated-sp: 3-5
slice-type: small-fix
discussion: empirical 2026-05-23 — F-040 real-launch test caught role-routing falling back to copilot inside a Claude-host session
depends-on:
  - 069  # F-040 Multi-Host Launch Path (foundation)
composes-with:
  - 024  # Multi-Host CORE (this is a stepping stone toward it)
  - 104  # Multi-Host Onboarding (which agents are routable per host)
---

# Host-Aware Routing Plan Fallback

## Why

F-040 (Multi-Host Launch Path) ships interactive launching of Claude / Codex / Copilot as the **host CLI**, but `Get-DelegatedRoutingPlan` (scripts/specrew-start.ps1:1218) does not know about the host selection. It computes `$enabledAgents` purely from `iteration-config.yml` enable flags, then falls back with a hard-coded copilot-first priority chain.

Empirical reproduction (2026-05-23, calculator-v2 test):

```text
$ specrew init -NoAgents          # claude/codex marked available/disabled
$ specrew start --host claude "Build a web based calculator..."
...
Selected host: claude
...
Final team composition:
  Spec Steward      copilot (requested codex; fell back — codex not enabled)
  Planner           copilot (requested claude; fell back — claude not enabled in routing)
  Implementer       copilot
  Reviewer          copilot (requested claude; fell back)
  Retro Facilitator copilot
```

Every role wanting claude/codex falls back to copilot — but **copilot cannot be invoked from inside a Claude or Codex session**. The routing plan is nonsensical.

The visible symptom in the calculator test was cosmetic (a misleading table). The functional risk surfaces when Multi-Host CORE (Proposal 024) wires per-role agent invocation: roles will get dispatched to an unrunnable host.

## What

Two interlocking changes to `scripts/specrew-start.ps1`:

### Change 1: Host promotion into the enabled-agents set

When the launch host (`--host claude|codex|copilot`) is selected, that host is **enabled-by-virtue-of-being-host** even when `iteration-config.yml` marks it disabled. The reasoning:

- The user explicitly chose to run in this host (via `--host`).
- The host process IS this host — any role routing to "claude" or "codex" while running inside Claude/Codex is literally the same process.
- The `iteration-config.yml` enable flag governs "should Squad consider this agent in its multi-agent routing decisions", not "is this agent runnable right now".

Implementation:

```powershell
function Get-DelegatedRoutingPlan {
    param(
        [object[]]$RoleAssignments,
        [System.Collections.IDictionary]$AgentLookup,
        [string]$SelectedHost = 'copilot'   # NEW: from --host (or default)
    )

    $enabledAgents = @(
        foreach ($agentName in @('copilot', 'claude', 'codex')) {
            if ($AgentLookup.Contains($agentName) -and $AgentLookup[$agentName].enabled -and $AgentLookup[$agentName].availability -eq 'available') {
                $agentName
            }
        }
    )

    # F-040 promotion: the launch host is always enabled-for-routing
    if ($SelectedHost -and ($enabledAgents -notcontains $SelectedHost)) {
        $enabledAgents = @($SelectedHost) + $enabledAgents
    }

    if ($enabledAgents.Count -eq 0) {
        $enabledAgents = @('copilot')
    }
    # ... rest unchanged
}
```

### Change 2: Host-first fallback priority

When fallback occurs, prefer the launch host over copilot:

```powershell
function Resolve-RoleAgentPlan {
    param(
        # ... existing params
        [string]$SelectedHost = 'copilot'   # NEW
    )

    # ... requested-agent check unchanged

    if (-not $effectiveAgent) {
        # F-040: host-first, not copilot-first
        $fallbackPriority = @($SelectedHost, 'copilot', 'claude', 'codex') | Select-Object -Unique
        $effectiveAgent = Get-PreferredEnabledAgent -EnabledAgents $EnabledAgents -Priority $fallbackPriority -Exclude $null
    }
    # ... rest unchanged
}
```

### Change 3: Routing-evidence wording

When the launch host is the effective agent due to being-host-promotion (not config-enable), the routing ledger should say so:

```text
Spec Steward      claude (host-promoted; codex not config-enabled)
Planner           claude (honored — host)
```

Instead of:

```text
Spec Steward      copilot (requested codex; fell back — codex not enabled)
```

So the table accurately reflects what will actually run.

## Acceptance Criteria

| ID | Description |
|---|---|
| AC1 | When `--host claude` is passed and claude is `available/disabled` in `iteration-config.yml`, `$enabledAgents` includes `claude` after promotion |
| AC2 | When `--host claude` is passed and a role requests `codex` (also disabled), fallback resolves to `claude` (the host), not `copilot` |
| AC3 | When `--host copilot` (the default), behavior is unchanged from current — backwards-compatible with all existing tests |
| AC4 | Routing ledger output distinguishes "host-promoted" from "config-enabled" via the `fallback_reason` field |
| AC5 | The independent-oversight constraint (Spec Steward / Reviewer must differ from Implementer) still holds — if implementer is the host, Spec Steward must fall to another enabled agent or document an oversight gap |
| AC6 | Existing unit tests for `Resolve-RoleAgentPlan` continue to pass; new tests cover the three host-launch scenarios (claude, codex, copilot) crossed with disabled/enabled config |

## Out of Scope

- Cross-host actual invocation (one host launching another's CLI as a subprocess). That's Multi-Host CORE / Proposal 024 territory. This proposal only fixes the **routing-plan correctness** so that when 024 ships, the plan it consumes is sensible.
- The `independent-oversight` constraint's interaction with single-host runs. When `--host claude` is the only enabled agent, oversight separation is structurally impossible; that's a documented gap, not this proposal's scope.

## Notes

This is a small-fix slice (per Proposal 067 pattern): code change + unit tests + CHANGELOG entry + this proposal entry. Estimated ~3-5 SP. Eligible for the lightweight lifecycle.

Empirical motivation: F-040 calculator-v2 test on 2026-05-23 caught the misleading routing table during real-launch validation. The cosmetic symptom now will become a functional bug as soon as Multi-Host CORE wires per-role agent invocation.
