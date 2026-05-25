# Design: Per-Host Package Architecture (Open-Closed Host Extension)

**Status**: DRAFT — awaiting user approval before refactor begins
**Branch**: `multi-host-integration-refactor`
**Drives**: refactor of F-040 + F-043 / F-041 / F-042 implementation work
**Companion audit**: Host-Coupling Audit Report (above session, 2026-05-24)

## Goal

> "Be host-agnostic in most of the code and MD files. Reference host-specific implementation details in a host package (folder per host). Adding Cursor, Windsurf, or Grok Code in the future should NOT open existing files." — user directive 2026-05-24

Translation: apply the Open-Closed Principle to host support. Specrew core is **closed for modification** when adding a host. The host package is **open for extension** — new host = new folder, zero edits to existing files.

## Current state (per audit)

- 4 internal scripts already concentrate host logic: `detect-hosts.ps1` (255 lines), `host-flag-translation.ps1` (131 lines), `coordinator-prompt-surgery.ps1` (123 lines), `host-runtime-inventory.ps1` (109 lines). All four are ~100% host-coupled — "the per-host package today in everything-but-name."
- `scripts/specrew-start.ps1` has 400 lines spread across 5 host-coupled clusters (launch dispatch + agent registry + role routing + model selection + display strings)
- 12 user-facing doc files mention specific hosts in prose
- ~28 total in-scope source files have host coupling
- Mirror burden: `.specify/extensions/specrew-speckit/scripts/*` doubles 5 files
- **10 surprising/risky couplings** including filename-baked host names (`Test-CopilotInstructionsChangeType.ps1`), shipped paths (`.github/copilot-instructions.md`), hardcoded args (`--ai copilot` to spec-kit init), template defaults (`preferred_agent: copilot|claude|codex`), and at least 2 latent inconsistencies (antigravity missing from `coordinator-prompt-surgery.ps1` ValidateSet and from `Invoke-HostLaunch` switch despite the antigravity follow-up spec being merged here)

## Target architecture

### Directory structure

```text
hosts/
├── _registry.ps1           # discovery + dispatcher; the ONLY file core code calls
├── _contract.md            # the contract every host package must satisfy
├── copilot/
│   ├── host.psd1           # manifest (declarative metadata)
│   ├── handlers.ps1        # function implementations (the contract)
│   ├── coordinator-rules.md # surgery directives in declarative form
│   └── docs/
│       ├── install.md      # install guidance (prose)
│       └── deferred.md     # (only if status=deferred)
├── claude/
│   └── ... (same shape)
├── codex/
│   └── ... (same shape)
└── antigravity/
    └── ... (same shape; status=supported after antigravity-followup merges)
```

### Manifest schema (`host.psd1`)

```powershell
@{
    # Identity
    Kind          = 'copilot'                            # canonical lowercase enum value
    DisplayName   = 'GitHub Copilot CLI'                 # user-facing
    Status        = 'supported'                          # supported | deferred | experimental
    Version       = '1.0.0'                              # manifest schema version

    # Binary detection
    Binary        = 'copilot'                            # command name on PATH
    BinaryAliases = @()                                  # alternate names if any (e.g., 'agy' for Antigravity)
    InstallUrl    = 'https://docs.github.com/en/copilot/how-tos/copilot-cli'
    DeferredReason = $null                               # required string if Status=deferred

    # Runtime layout (where this host expects files in a downstream project)
    SkillRoot     = '.github/skills'                     # primary skill dir
    LegacySkillRoots = @('.copilot/skills')              # migration sources
    SettingsPath  = $null                                # e.g. '.claude/settings.json' or $null
    AgentDir      = $null                                # e.g. '.claude/agents/' for per-host agent files

    # Spec-kit + Squad coupling
    SpeckitAiFlag = 'copilot'                            # what --ai arg to pass to `specify init`
    PreferredAgent = 'copilot'                           # for role-assignments.yml default

    # Coordinator-prompt surgery
    SurgeryRulesFile = 'coordinator-rules.md'            # declarative rule set (see below)

    # Handler module
    HandlersFile  = 'handlers.ps1'                       # dot-sourced by _registry.ps1
    HandlersExports = @(
        'New-CopilotLaunchInvocation',
        'ConvertTo-CopilotFlag',
        'Test-CopilotRuntimeInstalled',
        'Get-CopilotSignals'
    )
}
```

### Handler contract (`handlers.ps1`)

Each host MUST export functions matching the contract. Names use the host Kind in PascalCase:

| Function | Signature | Returns | Used by |
|---|---|---|---|
| `New-<Kind>LaunchInvocation` | `-ProjectPath <p> -Prompt <s> -Flags <hashtable>` | `[pscustomobject]@{Binary; Args[]; Notice}` | `Invoke-HostLaunch` dispatcher in core |
| `ConvertTo-<Kind>Flag` | `-SpecrewFlag <flag>` (e.g., `--remote`, `--allow-all`, `--autopilot`) | `[pscustomobject]@{Args[]; Notice; SuppressWarning}` | `Build-HostLaunchArgs` in core |
| `Test-<Kind>RuntimeInstalled` | `-ProjectPath <p>` | `[bool]` + `[pscustomobject]@{InstalledMarkers[]; MissingMarkers[]}` | `Get-HostRuntimeInventory` in core |
| `Get-<Kind>Signals` | (no params; reads env vars) | `[pscustomobject]@{IsActive; SessionId; Version}` | `Get-CurrentHostContext` in core |

(Future contract additions are additive — old hosts get default no-op behavior so they don't break.)

### Coordinator-prompt rules (`coordinator-rules.md`)

Declarative — each rule has a `kind` (Replace / Strip / Append) + match pattern + replacement. Loaded at launch time, applied in order by `Invoke-SpecrewCoordinatorPromptSurgery` (which becomes host-neutral). Example for Codex:

```markdown
---
host: codex
rules:
  - kind: Replace
    description: Universal Crew-coordinator header (FR-011)
    match: '^You are Squad running inside a Specrew-bootstrapped repository\.'
    replace: 'You are the Crew team coordinator running inside a Specrew-bootstrapped repository.'
    flags: 'Multiline'
  - kind: Strip
    description: Squad-runtime-path directives (FR-012)
    pattern: '<paragraph regex for the Squad rules block>'
  - kind: Replace
    description: Codex pwsh-form rewrite for boundary-advance (FR-014)
    match: '/speckit\.specrew-speckit\.sync-(\w+)'
    replace: 'pwsh -File .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 -BoundaryType $1'
---
```

### Registry (`_registry.ps1`)

The ONE file host-neutral core code calls.

```powershell
function Get-RegisteredHostKinds {
    # Returns @('copilot', 'claude', 'codex', 'antigravity')
    # Discovered by enumerating hosts/*/host.psd1 files
}

function Get-HostManifest { param([string]$Kind) }
    # Loads hosts/<kind>/host.psd1 via Import-PowerShellDataFile
}

function Resolve-HostHandler { param([string]$Kind, [string]$ContractFunction) }
    # Returns the per-host function name for a contract slot
    # e.g. Resolve-HostHandler -Kind claude -ContractFunction 'NewLaunchInvocation' returns 'New-ClaudeLaunchInvocation'
}

function Invoke-HostHandler { param([string]$Kind, [string]$ContractFunction, [hashtable]$Args) }
    # Convenience wrapper: dot-source handlers, resolve, invoke with $Args
}

function Get-AvailableHostsViaPath {
    # Iterates registered kinds, runs Get-Command on Binary, returns available set
}

function Get-HostInstallGuidance { param([string]$Kind) }
    # Reads manifest InstallUrl + doc/install.md
}
```

### Host-neutral core (refactor targets)

What stays in core (becomes host-neutral via registry iteration):

- `scripts/specrew-start.ps1` — `Invoke-HostLaunch` becomes `$handler = Resolve-HostHandler -Kind $HostKind -ContractFunction NewLaunchInvocation; & $handler ...` (no per-host switch arms)
- `scripts/specrew-init.ps1` — agent enum guards iterate `Get-RegisteredHostKinds`; `Get-CopilotSignals` extracts to `hosts/copilot/handlers.ps1` and replaced in init with `Get-CurrentHostContext` (registry-driven)
- `scripts/internal/coordinator-prompt-surgery.ps1` — loads `hosts/<kind>/coordinator-rules.md`, applies declarative rules; the switch goes away
- `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` — `Get-ActiveSkillRoots` returns `Get-RegisteredHostKinds | ForEach-Object { (Get-HostManifest $_).SkillRoot }` plus legacy roots
- `extensions/specrew-speckit/templates/role-assignments.yml` — generated at scaffold time from registry, not statically hardcoded

What stays per-host (moves to packages):

- Binary names + install URLs + deferred reasons (manifest)
- Launch argv builders (handlers.ps1)
- Flag-translation tables (handlers.ps1)
- Coordinator-prompt surgery directives (coordinator-rules.md)
- Skill catalog paths (manifest)
- Runtime-installed detection (handlers.ps1)
- Env-var signal probes (handlers.ps1)
- Install guidance prose (docs/install.md)
- Deferred guidance prose (docs/deferred.md)

What's documentation (per-host doc-templating):

- README.md / docs/getting-started.md / docs/user-guide.md per-host sections become **generated** from `hosts/<kind>/docs/install.md` content via a doc-generator script at release time. Source-of-truth shifts to per-host docs; aggregated docs become artifacts. (Stretch goal — could defer.)

### Anti-couplings to fix during refactor

From audit's "surprising/risky" list:

1. **Rename `Test-CopilotInstructionsChangeType.ps1`** → host-neutral `Test-HostInstructionsChangeType.ps1` (parameter `-HostKind`); per-host instruction-file path comes from manifest
2. **Abstract `.github/copilot-instructions.md` shipped path** — manifest declares `InstructionsFile` per host (Copilot: `.github/copilot-instructions.md`, Claude: `CLAUDE.md`, etc.); validator reads via registry not literal path
3. **Make `--ai copilot` configurable** — derived from `SpeckitAiFlag` in selected host's manifest at init time
4. **Generate `preferred_agent` defaults** — `role-assignments.yml` template uses placeholder `<default_preferred_agent>` filled at scaffold time from default-host manifest
5. **`Specrew.psd1` FileList enumeration** — keep static for module-publish reasons, but add a Rule-15-style validator that asserts FileList includes every `hosts/*/handlers.ps1` and `hosts/*/host.psd1`
6. **Move/rename `.squad/skills/copilot-launch-contract-divergence/`** — either to `hosts/copilot/skills/launch-contract-divergence/` (host-specific skill) or rename to host-neutral with a per-host body
7. **Add antigravity to coordinator-prompt-surgery** — `ValidateSet` goes away when surgery becomes registry-driven (the declarative rules approach makes ValidateSet a non-concept)
8. **Add antigravity arm to `Invoke-HostLaunch`** — same: the switch arms go away, replaced by `Invoke-HostHandler -ContractFunction NewLaunchInvocation`
9. **Rework F-043 draft helpers** — `host-history.ps1` and `host-runtime-inventory.ps1` currently hardcode host enum in schema constructors; rewrite to iterate registry
10. **`.specify/` mirror update** — every change to a refactored file must also update its `.specify/extensions/specrew-speckit/scripts/*` twin (existing discipline; mirror-parity test enforces)

### Adding a new host (acceptance scenario)

To add Cursor support:

1. `mkdir hosts/cursor/`
2. Write `hosts/cursor/host.psd1` with manifest fields (including `AgentDir = '.cursor/agents/'` per host docs)
3. Write `hosts/cursor/handlers.ps1` exporting the 5 contract functions (incl. `Install-CursorCrewRuntime`)
4. Write `hosts/cursor/coordinator-rules.psd1` with per-host surgery rules
5. Write `hosts/cursor/docs/install.md` with prose install guidance
6. Add `hosts/cursor/*` to `Specrew.psd1` FileList
7. Done — `specrew start --host cursor` works; `specrew where`, `specrew help`, `specrew host list` all show Cursor; validator works; tests use Cursor fixture; no existing file edited

The Rule-15 validator + mirror-parity test catches drift; no behavior change to copilot / claude / codex / antigravity packages.

### Migration plan (refactor sequencing)

**Phase A — registry + manifests (no behavior change):**

1. Create `hosts/_registry.ps1` + `hosts/_contract.md`
2. Create `hosts/copilot/host.psd1`, `hosts/claude/host.psd1`, `hosts/codex/host.psd1`, `hosts/antigravity/host.psd1` — manifests only, no handler files yet
3. Add registry-discovery test (asserts 4 hosts discovered)
4. Add `Get-RegisteredHostKinds` callsite ONE place in `detect-hosts.ps1` — assert parity with existing hardcoded enum

**Phase B — extract handlers (per-host, one at a time):**

5. Copilot first (smallest surface; default host): extract `Get-CopilotSignals` from `specrew-init.ps1` + Copilot's launch argv from `specrew-start.ps1` + Copilot flag translation from `host-flag-translation.ps1` + Copilot runtime detection from `host-runtime-inventory.ps1` into `hosts/copilot/handlers.ps1`. Replace original code with `Invoke-HostHandler` calls. Run integration tests after each extraction.
6. Claude: same pattern
7. Codex: same pattern
8. Antigravity: extract from antigravity-followup draft into `hosts/antigravity/handlers.ps1`; this is where the antigravity follow-up "graduate-from-deferred" work lands cleanly

**Phase C — coordinator-prompt rules declarative format:**

9. Convert `Invoke-SpecrewCoordinatorPromptSurgery` to load `hosts/<kind>/coordinator-rules.md`
10. Write per-host coordinator-rules.md files; delete the per-host switch arms
11. Verify all golden tests still pass

**Phase D — anti-coupling fixes:**

12. Rename `Test-CopilotInstructionsChangeType.ps1` → host-neutral
13. Abstract `.github/copilot-instructions.md` path via manifest `InstructionsFile`
14. Make `--ai copilot` configurable via manifest `SpeckitAiFlag`
15. Generate `preferred_agent` in template scaffolding
16. Update `Specrew.psd1` FileList for `hosts/*` + add validator rule
17. Move/rename Copilot-specific skill dir

**Phase E — docs aggregation (stretch / can defer):**

18. Write doc-generator script that aggregates `hosts/*/docs/install.md` into README/getting-started/user-guide sections
19. Convert existing per-host sections in those docs into generated content

**Phase F — F-043 / F-041 / F-042 implementation in new architecture:**

20. F-043 (Multi-Host Onboarding) — `host-history.ps1` rewritten to iterate registry; `specrew host list/use/status` uses registry; first-run probe uses registry
21. F-041 (Cost-Aware Routing) — per-host model catalog refresh is a manifest field
22. F-042 (Token Economy MVP) — per-host cost attribution uses registry

### Risk + tradeoffs

**Risks:**

- Refactor surface is broad (~28 source files + mirrors); high diff churn
- PowerShell dot-sourcing semantics: registry must dot-source handler files into the caller's scope to make functions visible. Need consistent pattern + tests for this
- Integration tests must be regenerated for any test that hardcoded per-host expectations
- Mirror parity (.specify/) doubles the work for some files

**Tradeoffs:**

- Pro: Future host additions are zero-touch on existing files. Open-Closed satisfied
- Pro: Per-host bugs (e.g., today's Antigravity missing from ValidateSet + Invoke-HostLaunch) become structurally impossible — the registry IS the source of truth
- Pro: Doc-prose templating reduces per-host prose drift
- Con: One-time refactor cost is substantial (~30-50 SP estimate; needs decomposition)
- Con: Slight indirection cost — every host lookup goes through registry. Acceptable for the architectural benefit
- Con: Declarative coordinator-rules.md is a new schema to maintain + validate (mitigation: schema validator + tests)

### Out of scope for this refactor

- Spec Kit host-agnosticism (`specify init --ai <kind>` — spec-kit only accepts Copilot/Claude/Codex/Cursor/Cline today; we adapt around it via manifest field but don't fix spec-kit)
- Multi-host CORE / concurrent execution (Proposal 024 full scope; this refactor is Slice 2 of that ladder)
- Host-native runtime hook enforcement (Proposal 105)

## Open design questions for user approval

1. **Folder location**: `hosts/` at repo root (sibling to `scripts/`, `extensions/`)? Or `scripts/hosts/`? Or `extensions/hosts/`?
2. **Handler file format**: dot-sourced `.ps1` (simple), or proper PowerShell module `.psm1` per host (more isolation, more setup)?
3. **Doc-templating Phase E**: in-scope for this refactor, or split out as separate proposal (Proposal 058 distribution-related)?
4. **Test reorganization**: move per-host integration tests to `hosts/<kind>/tests/` so each host package owns its tests? Or keep `tests/integration/` host-iterative?
5. **F-040 changes already merged**: refactor undoes some of the per-host switch arms in `Invoke-HostLaunch` etc. Is the user OK with this churn?
6. **Antigravity status**: refactor lands antigravity as `Status: supported` in its manifest. Does that mean the antigravity-followup feature is considered "shipped via the refactor"? Or do we keep antigravity `Status: deferred` and ship the followup feature separately?

## Estimated effort

- Phase A (registry + manifests): 2-3 SP
- Phase B (extract handlers per host): 6-10 SP (1.5-2.5 SP per host × 4 hosts)
- Phase C (declarative coordinator-rules): 4-6 SP
- Phase D (anti-coupling fixes): 5-8 SP
- Phase E (doc aggregation): 3-5 SP (defer-able)
- Phase F (F-043 + F-041 + F-042 implementation): scope unchanged, ~25-30 SP combined; refactor reduces complexity per feature

**Total refactor**: ~20-32 SP for Phases A-D; +3-5 for Phase E; then F-043/F-041/F-042 land in new architecture.

## Next step

Present this design to user. If approved, begin Phase A. Each phase commits independently so progress is visible + reversible.
