# Iteration 002 Scope

**Feature**: F-044 | **Iteration**: 002 — Deep-Analysis Bug-Fix Slice

## Finding-by-finding closure

### BUG (3 + 1 cross-feature)

| ID | Finding | Fix |
|---|---|---|
| A-1 | host-gate aborts before `last-start-prompt.md` write under `-NoLaunch` + no `--host`; 3 pre-existing tests regress | `-NoLaunch` carve-out at `scripts/specrew-start.ps1` lines 3719-3745: `non-interactive-no-default` and `no-hosts-available` branches fall back to `selectedHost='copilot'` + `host_resolution='no-launch-default'` when `-NoLaunch` is set. Also updates `specrew-start-auto-continue-preservation.ps1` to use a sentinel string surviving F-040 coordinator-prompt surgery. **Cross-feature incidental fix** — bug introduced by F-043 `755c87f1`, fix lives in F-044 iter-002. |
| B-1 | Copilot `Install-CopilotCrewRuntime` returns `.squad` (parent) instead of `.squad/agents` | `hosts/copilot/handlers.ps1` returns `$squadAgentsRoot` (now `.squad/agents`). Regression test added in `crew-bootstrap-contract.tests.ps1` (Test 4). |
| B-2 | Hardcoded `if ($kind -eq 'copilot')` in "manifest-driven" iterator (Open-Closed regression) | Added `AgentDir = '.squad/agents/'` to `hosts/copilot/host.psd1`. Deleted the special-case from `scripts/internal/host-runtime-inventory.ps1`. |
| B-3 | Install handlers hardcode agent root path instead of reading `$manifest.AgentDir` (Open-Closed seam broken) | New helper `Get-SpecrewHostAgentRoot` in `hosts/_team-canonical.ps1`. All 4 `Install-<Kind>CrewRuntime` handlers now read manifest. Validator (`Test-HostManifestValid`) updated to enforce AgentDir for `Status='supported'`. |

### WARN (11)

| ID | Finding | Fix |
|---|---|---|
| W-1 | `hosts/_contract.md` Phase-A-only, 5 drift counts | Full rewrite — Phase A-D + Slice 9, correct signatures, correct file extensions, `InstallGuidance` documented |
| W-2 | Fragile 2-level `Split-Path -Parent` in `scripts/init/{crew-bootstrap,agent-detection}.ps1` | Both files migrated to marker-walk on `Specrew.psd1` |
| W-3 | `specrew start` without `init` contradicts "user edits canonical" docs | `Invoke-CrewBootstrap` auto-seeds `.specrew/team/agents/` if missing |
| W-4 | Specrew-managed sentinel unenforced; user edits silently clobbered | `Test-SpecrewManagedFile` checks file content for inline marker OR sidecar marker file. All 4 Install handlers gate writes on this check. **Advisor-flagged risk addressed**: Copilot uses sidecar pattern (`<path>.specrew-managed`) so `charter.md` stays byte-identical to canonical (Squad CLI parse safety) |
| W-5 | Antigravity `Get-ChildItem` missing `*.md` filter | Filter added |
| W-6 | No contract-presence tests; `.scratch/` E2E untracked | 3 new asserts in `host-registry.tests.ps1` (`InstallCrewRuntime` map presence, every supported host exports `Install-<Kind>CrewRuntime`, every supported host declares `AgentDir`). Promoted E2E to `tests/integration/crew-bootstrap-contract.tests.ps1` (9 assertions). |
| W-7 | Proposal 108 file missing on branch (per "proposals to main only" rule, will arrive via merge) | Deferred until branch merges to main — proposal is on main at commit `1698b08e`; will reach this branch via merge-from-main |
| W-8 | `proposals/INDEX.md` missing entry for Proposal 108 | Deferred (depends on W-7 — INDEX update is on-main work per "proposals to main only" rule) |
| W-9 | Architecture doc shows 4-entry `HostContractFunctionMap` (should be 5) | Updated to 5 entries in both `docs/architecture/host-package-architecture.md` and `docs/design/host-package-architecture.md` |
| W-10 | `docs/how-to/add-a-new-host.md` internal contradiction ("4 vs 5 contract functions") | Line 15 corrected to "5 contract functions" |
| W-11 | `docs/user-guide.md` describes team as `.squad/team.md` only | New paragraph describes canonical `.specrew/team/agents/<role>.md` source-of-truth + per-host translation flow |

### NIT (8)

| ID | Finding | Fix |
|---|---|---|
| N-1 | Duplicate `Set-StrictMode` + stale line-number comments + dead `Get-CopilotSignals` fallback in `agent-detection.ps1` | All removed; comments scoped to current reality |
| N-2 | `_registry.ps1:10` comment references nonexistent `Test-RegistryParityWithLegacy` | Comment scoped to actual shipped state |
| N-3 | 3× duplicated `ConvertTo-<Kind>AgentDescription` helpers | Consolidated into `Get-SpecrewCharterTagline` in `hosts/_team-canonical.ps1`; each handler now a 2-line wrapper |
| N-4 | `Get-SpecrewShippedCharterPath` fallback returns wrong path on cap-exhaustion (false positive from agent — already fixed) | No-op; verified |
| N-5 | `squad-deploy.ps1` transition note stale post-Slice 9 | Scope-note rewritten to reflect post-Slice 9 reality (Initialize-SquadFallbackScaffold stays source-of-truth for non-charter `.squad/` skeleton) |
| N-6 | Asymmetric `SharedSkillRootWith` declaration | Informational only; not changed (advisor noted as cosmetic) |
| N-7 | Concurrent `specrew start` race | Out-of-scope; tracked for Proposal 010 multi-developer work |
| Validator gap | `Test-HostManifestValid` didn't enforce `AgentDir` for supported hosts (advisor catch) | Added `Status='supported'` requires `AgentDir` check |

## Single-commit close

iter-002 ships as one commit `dcc4beb7` with title `chore(F-044 iter-002): deep-analysis bug-fix bundle (22 findings)`. Single-commit close is the correct shape for a focused fix slice — every change is in service of the iter-001-review-identified gaps. Splitting into multiple commits would have fragmented the "this is the cleanup slice" narrative.

## A-1 cross-feature incidental fix

The host-gate `-NoLaunch` carve-out (finding A-1) fixes a bug introduced by F-043 commit `755c87f1`. The fix logically belongs to F-043, but it lands in F-044 iter-002 because:

1. Deep-review-agent A discovered it during F-044's iter-001 review.
2. The fix is one-line in scope and trivially bundled with the other F-044 iter-002 changes.
3. F-043 is closing on the same PR; no value to splitting the commit.

Both F-043 and F-044 iteration artifacts cross-reference this incidental fix:
- F-043 iter-001 → see [`../../../043-multi-host-onboarding/iterations/001/drift-log.md`](../../../043-multi-host-onboarding/iterations/001/drift-log.md) § Drift #4
- F-044 iter-002 → this file (above)
