---
proposal: 108
title: specrew-init Refactor + Per-Host Crew-Runtime Abstraction
status: shipped
shipped-as: feature-044
shipped-in-version: 0.27.0
phase: phase-2
estimated-sp: 22-25
actual-sp: 50  # 7 iterations: 18 (architectural payoff) + 6 (deep-analysis cleanup) + 4 (manual-test repair) + 3 (UX) + 8 (Antigravity launch fix + release prep) + 4 (dispatch hardening) + 7 (Linux portability + PR readiness)
spec: specs/044-per-host-architecture-refactor/spec.md
discussion: 2026-05-24 multi-host integration refactor closeout + user observation that --host claude lacks the 5-agent Crew that Squad provides under Copilot
depends-on:
  - 069  # F-040 Multi-Host Launch Path (host registry + 4 contract functions exist)
  - 104  # F-043 Multi-Host Onboarding (host-history + onboarding flow)
composes-with:
  - 024  # Multi-Host Runtime Abstraction (this proposal IS the Slice 3 enabler)
  - 058  # Plugin-Based Multi-Host Distribution (per-host packaging)
  - 105  # Host-Native Hook Deployment for Runtime Boundary Enforcement
blocks: []
---

# specrew-init Refactor + Per-Host Crew-Runtime Abstraction

## Why

Two empirical observations converge on the same refactor:

**Concern A — `scripts/specrew-init.ps1` is a 2,428-line monolith with 45 functions.** It mixes preflight checks, template deployment, Spec-Kit install, Squad install + fallback scaffold, agent detection, governance scaffold, and post-bootstrap user output in a single file. Every change to one concern risks regression in another. Empirical evidence: every Specrew CI failure traced to specrew-init.ps1 in the past three weeks (F-022 FileList omission, F-023 FileList omission, the 2026-05-24 Phase D firewall-test finding of two hardcoded host enums) involved this file's tangled responsibilities. The host-coupling firewall test (added 2026-05-24) is forced to allow-list the entire file because the Squad-specific work cannot be cleanly separated from the host-neutral work.

**Concern B — the host-package refactor (2026-05-24) stopped short of the agent-team layer.** The `hosts/<kind>/` packages now abstract launch invocation, flag translation, runtime detection, environment-signal probes, and coordinator-prompt surgery. They do NOT abstract Crew-runtime installation. Squad — the 5-agent baseline (Spec Steward / Planner / Implementer / Reviewer / Retro Facilitator) deployed under `.squad/` — remains hardcoded as Copilot-only. User-observed gap (2026-05-24, in a separate `--host claude` session): "I tried it with Claude and I didn't see a team of agents as we have with Squad. Is this deferred to later iterations?" — the answer is yes, deferred to Proposal 024 Slice 3. This proposal IS that slice.

The two concerns are not independent: **specrew-init.ps1 IS where the Squad bootstrap happens**. The two functions that deploy Squad (`Initialize-SquadFallbackScaffold` lines 1275-1417; `squad init` invocation around line 2259) live inside the 2,428-line monolith. Splitting the file correctly **requires** designing the per-host Crew-runtime-install abstraction at the same time. Doing them separately would mean two rounds of touching the same code.

The cost of doing nothing: every `specrew start --host claude` session loses the multi-specialist perspective diversity that catches different defects at different roles. Cost-management alternation (F-041 + F-042 work) silently degrades reviewer independence — saving money but accepting thinner review. That's a real methodology degradation, not a fake one. Slice 3 closes it.

## What

A two-part proposal:

### Part 1 — File split (no behavior change; pure refactor)

Break `scripts/specrew-init.ps1` (2,428 lines, 45 functions, all internal-only) into:

```text
scripts/
├── specrew-init.ps1                  # ~250 lines — thin orchestrator (was 2,428)
└── init/
    ├── _utilities.ps1                # ~140 lines — Get-NativeExitCode, ConvertTo-YamlBoolean,
    │                                 #   Test-ConsoleInputRedirected, Write-Step, Invoke-NativeCommand*,
    │                                 #   Invoke-WithNativeCommandEncoding, Add-Action,
    │                                 #   Ensure-DirectoryExists, Get-SpecrewExecutionLayout,
    │                                 #   Write-MissingUtf8File
    ├── preflight.ps1                 # ~180 lines — Test-PreFlightDependencies, Show-Usage
    ├── template-deploy.ps1           # ~155 lines — Copy-TemplateTree, Invoke-BundledTemplateDeployment,
    │                                 #   Test-BootstrappedProjectState
    ├── spec-kit-deploy.ps1           # ~210 lines — Get-SpecKitGitReference + InstallArguments/CommandText,
    │                                 #   Test-SpecifyReleaseAssetBlocker, Get-FirstNonEmptyOutputLine,
    │                                 #   Test-SpecifyExtensionAddAvailable, Test-SpecifyInitPreflight,
    │                                 #   Get-SpecifyInitPreflightResult, Invoke-SpecKitExtensionDeployment
    ├── dependency-install.ps1        # ~165 lines — Install-MissingDependency, Invoke-VersionValidation,
    │                                 #   Get-DependencyValidationIssue, Resolve-DependencyValidationIssue
    ├── agent-detection.ps1           # ~280 lines — New-AgentRecord, Get-AgentLookup, Get-AgentDetection,
    │                                 #   Get-AgentSelectionMode, Resolve-AgentSelection, Format-AgentSummary,
    │                                 #   Get-DelegatedAgentMetadata, Get-GitHubAuthContext
    │                                 #   (Get-CopilotSignals DELETED — moved to hosts/copilot/handlers.ps1)
    ├── squad-deploy.ps1              # ~100 lines — Test-SquadInitSupportsNonInteractive, Get-SquadInitPlan
    │                                 #   (BOTH eventually move to hosts/copilot/handlers.ps1; transition window)
    ├── crew-bootstrap.ps1            # NEW — ~70 lines — thin dispatch via Invoke-HostHandler -ContractFunction
    │                                 #   InstallCrewRuntime; absorbs Initialize-SquadFallbackScaffold's
    │                                 #   role-and-template inventory as the spec for the copilot handler's body
    └── post-bootstrap-output.ps1     # ~210 lines — Write-PostBootstrapGuidance, Write-BootstrapSummary
```

Dependency graph: `_utilities.ps1` is leaf; every other split file dot-sources it; `crew-bootstrap.ps1` additionally dot-sources `hosts/_registry.ps1`; the orchestrator dot-sources all of `init/*.ps1`. Behavior is bit-identical to today for the Copilot-default path. Verified via the function inventory: every one of the 45 functions has zero external callers — splitting is safe.

### Part 2 — 5th contract function: `InstallCrewRuntime`

Add to the host-package contract (`hosts/_contract.md`):

| Function (template) | Signature | Returns | Used by |
|---|---|---|---|
| `Install-<Kind>CrewRuntime` | `-ProjectPath <p> -AgentCharters <hashtable> -CoordinatorGovernance <string> -Ceremonies <hashtable> [-DryRun]` | `[pscustomobject]@{Actions[]; Warnings[]; CrewRuntimePath}` | `init/crew-bootstrap.ps1` dispatcher |

Per-host bodies (Proposal 108 ships only Copilot's body; Slice 3 follow-ups ship the rest):

| Host | Body sketch |
|---|---|
| **copilot** | Wraps `Initialize-SquadFallbackScaffold` (now relocated to `hosts/copilot/handlers.ps1`) — writes `.squad/agents/<role>/charter.md`, `.squad/team.md`, `.squad/ceremonies.md`, `.squad/decisions.md`, `.squad/routing.md`, `.squad/casting/registry.json`, `.squad/identity/{now,wisdom}.md`. Plus `.github/agents/squad.agent.md` coordinator overlay. **Existing behavior preserved.** |
| **claude** | Writes `.claude/agents/<role>.md` (one Markdown file per agent; YAML frontmatter declares `name:`, `description:`, `model:`; body is the charter). Coordinator block embedded in `CLAUDE.md` (manifest `InstructionsFile`). Per-agent invocation via Task tool + `subagent_type` parameter — exactly the primitive Claude Code provides natively. |
| **codex** | Writes `.codex/agents/<role>.toml` (TOML frontmatter per Codex convention). Coordinator block in `AGENTS.md`. **Caveat**: Codex has no user-defined slash-command surface (FR-013), so delegation is prose-only — coordinator says "Implementer: write the code" and the agent file declares the role's charter. |
| **antigravity** | Writes `.agents/agents/<role>.md` (mirrors Claude shape; Antigravity reads same root-level convention as Codex per manifest `InstructionsFile = 'AGENTS.md'`). Caveat-light Slice 3 deliverable — Antigravity host is itself preview-grade until Gemini-deadline resolution (2026-06-18). |

The hard part is NOT file-format conversion (mechanical). It's **invocation semantics per host**: how does the coordinator delegate to a specialist? Squad uses its own role-routing in Copilot CLI. Claude has the Task tool + subagent files. Codex has no user slash-command surface. Antigravity is closer to Claude. Proposal 024 Category D (the 45 numbered coordinator directives that orchestrate the Crew) is where these semantics live and must be host-translated — that's the bigger Slice 3 scope beyond Proposal 108.

**Existing manifest field `AgentDir` (already declared in 3/4 manifests but unused) becomes load-bearing here.** Copilot manifest gets `AgentDir = '.squad/agents/'` (currently omitted because Squad is npm-installed; for the registry to drive uniformly, manifest declares the directory). Claude already has `.claude/agents/`. Codex already has `.codex/agents/`. Antigravity already has `.agents/agents/`. After this proposal, every host's `Install-<Kind>CrewRuntime` writes to its declared `AgentDir`.

## Architecture

### Contract addition

`hosts/_contract.md` grows one row in the contract-function table:

```text
InstallCrewRuntime  → Install-<Kind>CrewRuntime  → returns @{Actions; Warnings; CrewRuntimePath}
```

`hosts/_registry.ps1` `$script:HostContractFunctionMap` grows one entry:

```powershell
$script:HostContractFunctionMap = @{
    'NewLaunchInvocation'    = 'New-{0}LaunchInvocation'
    'ConvertFlag'            = 'ConvertTo-{0}Flag'
    'TestRuntimeInstalled'   = 'Test-{0}RuntimeInstalled'
    'GetSignals'             = 'Get-{0}Signals'
    'InstallCrewRuntime'     = 'Install-{0}CrewRuntime'   # NEW (Proposal 108)
}
```

### Caller pattern (in `init/crew-bootstrap.ps1`)

```powershell
function Invoke-CrewBootstrap {
    param([string]$ProjectPath, [string]$HostKind, [switch]$DryRun)

    # Load the canonical agent charters + coordinator overlay from extensions/
    $charters = Get-SpecrewAgentCharterCatalog
    $coordinator = Get-SpecrewCoordinatorGovernance
    $ceremonies = Get-SpecrewCeremonyCatalog

    return Invoke-HostHandler -Kind $HostKind -ContractFunction InstallCrewRuntime -Arguments @{
        ProjectPath           = $ProjectPath
        AgentCharters         = $charters
        CoordinatorGovernance = $coordinator
        Ceremonies            = $ceremonies
        DryRun                = $DryRun
    }
}
```

Source of truth for the catalogs stays at `extensions/specrew-speckit/squad-templates/agents/<role>/charter.md` (host-neutral content). Per-host handlers translate format only.

### Idempotency + dry-run

Every `Install-<Kind>CrewRuntime` handler MUST:

- Be idempotent: re-running on a project that already has the Crew runtime preserves user customizations (uses the `Copy-TemplateTree` diff pattern from `init/template-deploy.ps1`).
- Honor `-DryRun`: return the action list without writing files.
- Return structured Actions: same shape as today's `Add-Action` records — `@{Action='created|preserved|updated|skipped'; Path='<file>'}` — feeding `Write-BootstrapSummary`.

### Composition with existing systems

| System | Today | After Proposal 108 |
|---|---|---|
| Squad CLI install | hardcoded `npm install -g '@bradygaster/squad-cli'` in `Install-MissingDependency` | gated on `selected_host == 'copilot'` (existing behavior preserved); Claude/Codex/Antigravity host packages have no CLI install (they use native host primitives) |
| `Initialize-SquadFallbackScaffold` (Squad-CLI-missing path) | 142-line hardcoded `.squad/` write | becomes the body of `Install-CopilotCrewRuntime` — no longer Squad-CLI-fallback, but the primary deployer for Copilot host |
| `deploy-squad-runtime.ps1` (663 lines, Squad-only) | writes managed blocks into `.squad/agents/*/charter.md`, `.squad/team.md`, `.squad/ceremonies.md`, etc. | invoked by `Install-CopilotCrewRuntime`; other hosts invoke per-host equivalents (e.g., `deploy-claude-runtime.ps1` if extracted, or inline in handlers.ps1 if compact) |
| `.specify/feature.json` (Spec-Kit feature pointer) | written by `specify init --ai copilot` | now reads `SpeckitAiFlag` from the selected host's manifest (Claude=`claude`, Codex=`codex`; Antigravity manifest has `SpeckitAiFlag = $null` → host package skips spec-kit init for now, awaits spec-kit upstream support) |
| Slash-command skills (`/specrew-where` etc.) | already multi-host via `Get-ActiveSkillRoots` | unchanged — DO NOT conflate with Crew-runtime install |
| Coordinator-prompt surgery (FR-011/012/014) | declarative `hosts/<kind>/coordinator-rules.psd1` (Phase C.3) | unchanged — surgery runs on whichever `InstructionsFile` the host declares |

## Implementation slices

Ten ordered PRs, each independently shippable with all tests green at every step:

| # | Slice | Files touched | SP | Risk |
|---|---|---|---|---|
| 1 | Extract `init/_utilities.ps1` | new file; specrew-init.ps1 dot-sources | 2 | Low — pure leaf, no behavior change |
| 2 | Extract `init/preflight.ps1` | new file; specrew-init.ps1 dot-sources | 1 | Low |
| 3 | Extract `init/template-deploy.ps1` | new file | 2 | Low |
| 4 | Extract `init/spec-kit-deploy.ps1` | new file (8 internal cross-references; extract as unit) | 2 | Med |
| 5 | Extract `init/dependency-install.ps1` | new file (depends on slice 4) | 2 | Med |
| 6 | Extract `init/agent-detection.ps1` + DELETE duplicate `Get-CopilotSignals` (already in `hosts/copilot/handlers.ps1`) + rewrite `Get-AgentDetection` to dispatch via registry | new file; `hosts/copilot/handlers.ps1` consulted | 3 | High — touches the 1642+1730 hardcoded enums; firewall allow-list narrows |
| 7 | Extract `init/squad-deploy.ps1` (transition file; eventual move to `hosts/copilot/handlers.ps1` in Slice 3) | new file | 2 | Med |
| 8 | Extract `init/post-bootstrap-output.ps1` | new file (Squad-only strings stay; multi-host messaging is Slice 3 follow-up) | 2 | Low |
| 9 | Add 5th contract function + `init/crew-bootstrap.ps1` + `Install-CopilotCrewRuntime` body (wraps existing scaffold logic) + new `tests/integration/crew-bootstrap-contract.tests.ps1` | `hosts/_contract.md`, `hosts/_registry.ps1`, `hosts/copilot/handlers.ps1`, new init file, new test | 5-7 | Med — adds contract surface; Copilot body wraps existing code so behavior preserved |
| 10 | Reduce `specrew-init.ps1` to thin orchestrator (~250 lines: dot-sources + the 17-phase main flow extracted from current `function-free` tail of the file lines 1795-2428) | specrew-init.ps1 | 1 | Low — defensive |

**Out of Proposal 108 (handed off to Proposal 024 Slice 3)**: per-host `Install-<Kind>CrewRuntime` BODIES for Claude/Codex/Antigravity. Each is ~8 SP because (a) format conversion is mechanical but (b) per-host invocation semantics (how coordinator delegates to specialists on that host) requires the Category D coordinator-directive translation work that's Proposal 024 Slice 3 scope.

Total Proposal 108: **22-25 SP**. Slice 3 follow-up (the three non-Copilot crew-runtime bodies + the Category D directive translation): **15-20 SP**. Together they close the user-observed gap.

### Test plan per slice

- **Each slice 1-8**: run `tests/integration/bootstrap-to-iteration.ps1` end-to-end — greenfield bootstrap must complete identically.
- **Each slice 1-8**: run `tests/integration/host-coupling-firewall.tests.ps1` — allow-list shrinks as each split file proves host-neutral.
- **Slice 9**: new `tests/integration/crew-bootstrap-contract.tests.ps1` (~10 assertions): contract-function map includes `InstallCrewRuntime`; `Resolve-HostHandler` returns the right name per host; `Invoke-HostHandler -ContractFunction InstallCrewRuntime -Kind copilot` produces the same actions today's `Initialize-SquadFallbackScaffold` produces; idempotency on rerun; `-DryRun` honored.
- **Slice 10**: full `host-registry.tests.ps1` + `multi-host-launch-path.tests.ps1` + `bootstrap-to-iteration.ps1` + new `crew-bootstrap-contract.tests.ps1` all PASS.

## Risks

| Risk | Mitigation |
|---|---|
| `Specrew.psd1` `FileList` drift — Rule 15 has caught FileList omissions twice (F-022 + F-023 per memory). Adding 9 new `scripts/init/*.ps1` files multiplies the drift surface | Every slice's PR includes the `FileList` update in the same commit; the host-coupling-firewall test gains a complementary assertion that `FileList` enumerates every `scripts/init/*.ps1` |
| Sibling-script duplication of `Write-Step`/`Add-Action`/`Invoke-NativeCommand*` (every `scripts/specrew-*.ps1` has its own copy) | Proposal 108 keeps utilities in `scripts/init/_utilities.ps1` (init-only). A follow-up cleanup proposal can promote to `scripts/common/_utilities.ps1` and de-duplicate siblings. Not blocking |
| Brownfield-merge path (107 inline lines, 2036-2142) is too small for its own file but too tangled to keep in the orchestrator | Optional 10th split candidate: `init/brownfield-merge.ps1` (2 SP). Defer the choice to implementation time |
| Each intermediate split state must keep `specrew init` green end-to-end (matters because module distribution publishes from main on tag push) | Every PR runs the full test suite as a gate; PR titles flag the slice number so the maintainer can hold publishing if needed |
| The 5th contract function's signature might need to evolve once non-Copilot handlers are written (Slice 3) | Schema-version the contract: add `ContractSchemaVersion = 1` to manifests; bump when contract surface changes; today the registry treats unknown versions as legacy |
| `Initialize-SquadFallbackScaffold` (the canonical Category B inventory) becomes the spec for what other hosts' handlers must produce | Document the equivalence in `_contract.md`: any `Install-<Kind>CrewRuntime` must deploy functional analogs of the 5 charters + coordinator overlay + ceremonies — even if the on-disk shape differs |
| Reviewer-independence regression on `--host claude` — the user's empirical concern that motivated this proposal — is not fully closed by Proposal 108 (Proposal 108 ships the abstraction, not the Claude body) | CHANGELOG + getting-started.md call out: "Until Proposal 024 Slice 3 ships Claude/Codex/Antigravity crew-runtime bodies, treat review-signoff on non-Copilot hosts with extra scrutiny because there's no independent Reviewer running" |
| Phase D allow-list (host-coupling firewall) currently excludes `specrew-init.ps1` wholesale; each slice must shrink the allow-list incrementally — easy to forget | The firewall test prints `(allow-list: N known)` count; reviewers can spot a stalled refactor by watching N decrease across PRs |

## Out of scope

- Non-Copilot per-host `Install-<Kind>CrewRuntime` BODIES (Claude / Codex / Antigravity) — those are Proposal 024 Slice 3 deliverables. Proposal 108 ships the abstraction surface + Copilot body only.
- Category B vs Category A state-file relocation per Proposal 104 Question 5 (`.squad/decisions.md` → `.specrew/team-state/decisions.md`?) — out of scope; Proposal 108 preserves today's `.squad/` location for Copilot's Crew runtime.
- Coordinator → specialist invocation protocol translation per host (the Category D 45 numbered directives) — Proposal 024 Slice 3 scope.
- Spec-Kit upstream changes to accept `--ai claude|codex|antigravity` — out of scope; if upstream doesn't support a host's `SpeckitAiFlag`, the manifest declares `$null` and the host package skips spec-kit init for that host. Tracked separately.
- Common utilities promotion (`scripts/common/_utilities.ps1` shared across all `specrew-*.ps1` siblings) — separate cleanup proposal; Proposal 108 keeps init-only utilities to bound scope.
- Cross-host Crew-runtime migration tooling (user-initiated `specrew host migrate --from copilot --to claude`) — out of scope; deferred to Proposal 010 Multi-Developer Reconciliation territory.

## Composition

- **[069](069-multi-host-launch-path.md) (shipped as F-040)** — provides the host registry + 4 existing contract functions (`NewLaunchInvocation`, `ConvertFlag`, `TestRuntimeInstalled`, `GetSignals`). Proposal 108 adds the 5th (`InstallCrewRuntime`).
- **[104](104-multi-host-onboarding-and-selection-flow.md) (F-043 in progress)** — `.specrew/host-history.json` + `specrew host` command + first-run probe. Proposal 108 builds on F-043's host-selection chain — `crew-bootstrap.ps1` reads `selected_host` and dispatches the right `Install-<Kind>CrewRuntime`.
- **[024](024-multi-host-runtime-abstraction.md)** — the umbrella for multi-host architecture. Proposal 108 explicitly delivers **part of Slice 3 (the abstraction surface + Copilot body)**. The remaining Slice 3 work (Claude/Codex/Antigravity bodies + coordinator-directive translation) ships as separate follow-ups against Proposal 024.
- **[058](058-plugin-based-multi-host-distribution.md)** — when 058 ships, each host package gets independent distribution (each is a discoverable plugin). Proposal 108's `Install-<Kind>CrewRuntime` is the install entry point per package.
- **[105](105-host-native-hook-deployment.md)** — host-native hooks (Claude `PreToolUse` / `SubagentStart` / `Stop`). When 105 ships, those hooks are deployed alongside the Crew runtime — `Install-<Kind>CrewRuntime` becomes the natural site to add hook registration per host.
- **[067](067-small-fix-slice-type.md)** — slices 1-3 of Proposal 108 are individually small-fix-shaped (~2 SP each). Use the small-fix slice contract.

## Open questions

1. **Slice 9 sub-scope**: should Copilot's body live as a function in `hosts/copilot/handlers.ps1` (matches contract pattern) or stay in `init/squad-deploy.ps1` (smaller diff)? Recommendation: relocate to `handlers.ps1` so the contract pattern is uniform across hosts. ~+2 SP vs deferring.
2. **Charter format**: agent charters are markdown today (`extensions/specrew-speckit/squad-templates/agents/<role>/charter.md`). Should `Install-<Kind>CrewRuntime` accept the raw markdown strings (current proposal) or a structured representation (parsed front-matter + body)? Recommendation: pass raw markdown; let each host's handler parse what it needs. Lower coupling.
3. **`squad init` (CLI) vs `Initialize-SquadFallbackScaffold` (no-CLI)**: today specrew-init prefers `squad init` and falls back to the scaffold if Squad CLI is missing. After Proposal 108, does `Install-CopilotCrewRuntime` always use the in-Specrew scaffold (deterministic, no external dependency), or still defer to `squad init` if available? Recommendation: prefer the in-Specrew scaffold for determinism + version stability; treat `squad init` as a "user prefers their own Squad CLI" opt-in. Lowers the Squad-CLI install surface for new users.
4. **Antigravity body in this proposal or Slice 3?**: Antigravity's spec-kit support is `null` (manifest), its slash-command surface is uncertain, and the Gemini-deadline (2026-06-18) destabilizes the host. Recommendation: ship Antigravity body in Slice 3 alongside Claude+Codex, not in Proposal 108. Antigravity's tests deferred until host stabilizes.
5. **CHANGELOG note for the "team degradation" gap during the transition window**: how prominently should we surface "until Slice 3 ships, --host claude has no independent Reviewer"? Recommendation: section in `docs/getting-started.md` "Multi-host status" + line in v0.27.0 CHANGELOG `### Known limitations`.

## Success criteria

- `scripts/specrew-init.ps1` shrinks from 2,428 lines to ~250 lines.
- 9 new files under `scripts/init/` each <300 lines, each independently testable.
- `tests/integration/host-coupling-firewall.tests.ps1` allow-list shrinks from `specrew-init.ps1` (wholesale) to a documented set of files (zero in best case; allow-list narrows monotonically per slice).
- New `tests/integration/crew-bootstrap-contract.tests.ps1` exercises the 5th contract function for the Copilot host with bit-identical output to today's bootstrap.
- `hosts/_contract.md` `InstallCrewRuntime` contract row is documented with the per-host body sketches.
- `docs/how-to/add-a-new-host.md` updated with the new Step 5b: "implement `Install-<Kind>CrewRuntime` to deploy the 5-agent Crew baseline using your host's native primitives."
- Greenfield `specrew init` + `specrew start --host copilot` end-to-end produces bit-identical state (`.squad/*` + `.github/agents/squad.agent.md`) to today.
- After Slice 3 follow-ups: greenfield `specrew init` + `specrew start --host claude` deploys `.claude/agents/spec-steward.md` (et al) + CLAUDE.md coordinator overlay; a session running on Claude has independent Reviewer perspective via Task tool subagent invocation.
