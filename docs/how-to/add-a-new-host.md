# How to add a new host to Specrew

> **Audience**: contributors wanting to add support for a new agent host CLI (e.g., Cursor, Windsurf, Grok Code, Aider, etc.)
> **Read first**: [host-package-architecture.md](../architecture/host-package-architecture.md) to understand WHY this works
> **Time required**: ~30-60 minutes for a fully working host package; ~10 minutes for a `Status: deferred` placeholder

## What you'll create

Adding a host means creating one new directory with 3 small files:

```text
hosts/
└── <kind>/                          # NEW — folder name is the canonical kind (lowercase)
    ├── host.psd1                    # Declarative manifest
    ├── handlers.ps1                 # 4 contract functions
    └── coordinator-rules.psd1       # Per-host coordinator-prompt surgery (may be empty Rules = @())
```

Plus 1-2 line edits to:

- `Specrew.psd1` — add the 3 new files to `FileList`
- A few `[ValidateSet(...)]` parameter attributes (until Phase D registry-driven validation lands)

That's it. No other file edits.

## Step-by-step: adding **Cursor** as a worked example

### Step 1 — pick the canonical `Kind` name

Lowercase, single-word, the canonical enum value used everywhere. `cursor`. Folder name must match exactly.

### Step 2 — research the host CLI

Before writing any code, gather these facts from the host's official docs (write them down — you'll need them in the manifest):

| Question | Cursor example answer |
|---|---|
| What's the binary name on PATH? | `cursor` |
| What's the official install URL? | `https://cursor.sh/install` (replace with the real one) |
| What's the launch invocation shape? | `cursor [--add-dir <path>] [--prompt <s>]` (whatever the real flags are) |
| What's the equivalent of Copilot's `--allow-all`? | `--auto-edit` (made-up; verify against docs) |
| Does it have user-defined slash commands? | yes (= `HasUserSlashCommandSurface: $true`) |
| Where does it look for skills? | `.cursor/skills/` (made-up; verify) |
| Where does it look for instructions? | `.cursor/instructions.md` (made-up; verify) |
| Does spec-kit's `--ai` flag accept this host? | Check `specify init --help`; if not, set `SpeckitAiFlag = $null` |
| What env vars does the host set when running? | `CURSOR_SESSION_ID`, etc. (verify) |
| Does it have a Crew-runtime convention (like Claude's `.claude/agents/`)? | Check Cursor docs for agent file convention |

**Do NOT guess.** Wrong flag names break the launch on first use. Always verify against the host's official docs AND test by running `cursor --help` locally.

### Step 3 — create the manifest (`hosts/cursor/host.psd1`)

```powershell
@{
    # Identity
    Kind          = 'cursor'
    DisplayName   = 'Cursor IDE CLI'
    Status        = 'supported'      # or 'deferred' if you're staging support (see "Adding a deferred host" below)
    SchemaVersion = 1

    # Binary detection
    Binary        = 'cursor'
    InstallUrl    = 'https://cursor.sh/install'

    # Runtime layout (per Step 2 research)
    SkillRoot                  = '.cursor/skills'
    HasUserSlashCommandSurface = $true
    SettingsPath               = '.cursor/settings.json'
    AgentDir                   = '.cursor/agents/'
    InstructionsFile           = '.cursor/instructions.md'

    # Spec-kit + Squad coupling
    SpeckitAiFlag  = $null           # spec-kit's --ai doesn't accept cursor (until it does)
    PreferredAgent = 'cursor'

    # Handler file references
    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'
}
```

Full field reference: see [`hosts/_contract.md`](../../hosts/_contract.md).

### Step 4 — implement the 5 contract functions (`hosts/cursor/handlers.ps1`)

Each handler is a small function (~10-80 lines). Copy from an existing host (e.g., `hosts/claude/handlers.ps1`) as a starting template. The functions to export:

| Function | Purpose |
|---|---|
| `New-CursorLaunchInvocation` | Build argv to launch Cursor with Specrew's bootstrap |
| `ConvertTo-CursorFlag` | Translate Specrew-side flags (`--remote`, `--allow-all`, `--autopilot`) to Cursor's equivalents |
| `Test-CursorRuntimeInstalled` | Check if Cursor's Crew runtime is already deployed in this project |
| `Get-CursorSignals` | Detect Cursor-set env vars (when running INSIDE a Cursor session) |
| `Install-CursorCrewRuntime` *(Proposal 108 Slice 9)* | Read `.specrew/team/agents/<role>.md` and write to Cursor's native subagent location (per Cursor's docs) |

The 5th function is what makes `specrew start --host cursor` actually deploy the 5-agent Crew. **Skipping it means Cursor launches with NO team** — same problem the user observed with Claude pre-Slice 9. So this is required for `Status: 'supported'`.

```powershell
# Cursor host package — handler implementations
# Per hosts/_contract.md.

Set-StrictMode -Version Latest

function New-CursorLaunchInvocation {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)][string]$Agent,    # ignored if Cursor has no --agent flag
        [bool]$AllowAll = $false,
        [bool]$UseAutopilot = $false,
        [bool]$UseRemote = $false
    )

    $hostCmd = Get-Command 'cursor' -ErrorAction SilentlyContinue
    $resolvedBinary = if ($null -ne $hostCmd) { $hostCmd.Source } else { 'cursor' }

    $argList = New-Object System.Collections.Generic.List[string]
    $notices = New-Object System.Collections.Generic.List[string]

    # Build the argv per Cursor's launch shape (Step 2 research)
    $argList.Add('--add-dir') | Out-Null
    $argList.Add($ProjectPath) | Out-Null

    if ($AllowAll) {
        $t = ConvertTo-CursorFlag -SpecrewFlag '--allow-all'
        foreach ($a in $t.Args) { $argList.Add($a) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace($t.Notice)) { $notices.Add($t.Notice) | Out-Null }
    }
    # ... repeat for $UseAutopilot, $UseRemote

    # Positional prompt last (or wherever Cursor expects it)
    $argList.Add($Prompt) | Out-Null

    return [pscustomobject]@{
        Binary   = $resolvedBinary
        Args     = $argList.ToArray()
        Notices  = $notices.ToArray()
        HostKind = 'cursor'
    }
}

function ConvertTo-CursorFlag {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('--remote', '--allow-all', '--autopilot')]
        [string]$SpecrewFlag
    )

    switch ($SpecrewFlag) {
        '--remote'    { return [pscustomobject]@{ Args = @(); Notice = 'Cursor does not expose a remote-control flag; continuing without remote wiring.'; SuppressWarning = $false } }
        '--allow-all' { return [pscustomobject]@{ Args = @('--auto-edit'); Notice = "Translated --allow-all to Cursor's --auto-edit flag."; SuppressWarning = $true } }
        '--autopilot' { return [pscustomobject]@{ Args = @(); Notice = 'Cursor has no autopilot equivalent; use --autonomous for unattended lifecycle runs.'; SuppressWarning = $false } }
    }
}

function Test-CursorRuntimeInstalled {
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $agentsDir = Join-Path $ProjectPath '.cursor\agents'
    if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) { return $false }
    $agentFiles = Get-ChildItem -Path $agentsDir -ErrorAction SilentlyContinue
    return ([bool]$agentFiles) -and ($agentFiles.Count -gt 0)
}

function Get-CursorSignals {
    $signals = @()
    foreach ($variableName in @('CURSOR_SESSION_ID', 'CURSOR_CLI_VERSION')) {
        $value = [Environment]::GetEnvironmentVariable($variableName)
        if (-not [string]::IsNullOrWhiteSpace($value)) { $signals += $variableName }
    }
    return $signals
}

function Install-CursorCrewRuntime {
    # Per Proposal 108 Slice 9: read canonical .specrew/team/agents/<role>.md
    # and translate to Cursor's native subagent location + format.
    # Reference an existing host for the translation pattern (Claude is closest if Cursor uses md+YAML).
    param([Parameter(Mandatory = $true)][string]$ProjectPath, [switch]$DryRun)

    $actions = New-Object System.Collections.Generic.List[hashtable]
    $notices = New-Object System.Collections.Generic.List[string]
    $cursorAgentsRoot = Join-Path $ProjectPath '.cursor\agents'   # adjust to Cursor's actual subagent dir
    if (-not (Test-Path -LiteralPath $cursorAgentsRoot -PathType Container) -and -not $DryRun) {
        New-Item -ItemType Directory -Path $cursorAgentsRoot -Force | Out-Null
    }

    foreach ($role in (Get-SpecrewCanonicalAgentRoles -ProjectPath $ProjectPath)) {
        $content = Get-SpecrewCanonicalCharterContent -ProjectPath $ProjectPath -RoleName $role
        if ([string]::IsNullOrWhiteSpace($content)) {
            $notices.Add("Skipping role '$role': no canonical charter found.") | Out-Null
            continue
        }

        # Translate $content to Cursor's native format here.
        # IMPORTANT: parenthesize each + concatenation OR use -f format strings inside @() literals;
        # see "Common pitfalls" below for why.
        $target = Join-Path $cursorAgentsRoot ("{0}.md" -f $role)
        if ($DryRun) {
            $actions.Add(@{ Action = 'would-write'; Path = $target; Role = $role }) | Out-Null
        } else {
            [System.IO.File]::WriteAllText($target, $content, [System.Text.UTF8Encoding]::new($false))
            $actions.Add(@{ Action = 'written'; Path = $target; Role = $role }) | Out-Null
        }
    }

    return [pscustomobject]@{
        Actions          = $actions.ToArray()
        CrewRuntimePath  = $cursorAgentsRoot
        Notices          = $notices.ToArray()
    }
}
```

**Important:** the function names MUST follow `<Verb>-<PascalKind><Suffix>` exactly — this is how the registry's `Resolve-HostHandler` finds them. For `Kind=cursor`:

- `New-CursorLaunchInvocation`
- `ConvertTo-CursorFlag`
- `Test-CursorRuntimeInstalled`
- `Get-CursorSignals`
- `Install-CursorCrewRuntime` (Proposal 108 Slice 9)

### Step 5 — declare coordinator-prompt rules (`hosts/cursor/coordinator-rules.psd1`)

Decide: does this host need any prompt rewrites beyond Specrew's universal FR-011 header?

- If the host has its own slash-command surface AND should retain Squad-runtime-path directives (like Copilot): `Rules = @()`
- If the host should strip Squad-runtime-path directives (like Claude): copy Claude's 4 Strip rules
- If the host has no slash-command surface (like Codex): copy Codex's 4 Strip rules + the 1 Replace rule

```powershell
@{
    Rules = @(
        @{
            Kind        = 'Strip'
            Description = 'FR-012: Squad-runtime-path directive — .squad/decisions.md reference'
            Pattern     = '(?m)^\s*\d+\.\s+.*\.squad[\\/]decisions\.md.*$'
        }
        # ... see hosts/claude/coordinator-rules.psd1 for the canonical set
    )
}
```

### Step 6 — update `Specrew.psd1` FileList

Open `Specrew.psd1`, find the `FileList` array, add 3 lines (sorted alphabetically within the `hosts/cursor/*` block):

```powershell
'hosts/cursor/host.psd1',
'hosts/cursor/handlers.ps1',
'hosts/cursor/coordinator-rules.psd1',
```

Verify the manifest still parses:

```powershell
Test-ModuleManifest -Path .\Specrew.psd1
```

### Step 7 — update ValidateSet attributes (Phase D will eliminate this step)

Until Phase D ships registry-driven ValidateSet generation, three places have static enum lists you'll need to extend:

1. `scripts/specrew-start.ps1` — find `[ValidateSet('copilot', 'claude', 'codex', 'antigravity')]` in the `Get-SpecrewHostLaunchInvocation` param block. Add `'cursor'`.
2. `scripts/internal/host-flag-translation.ps1` — same ValidateSet in `Get-HostFlagTranslation` param block. Add `'cursor'`.
3. `scripts/internal/coordinator-prompt-surgery.ps1` — same ValidateSet in `Invoke-SpecrewCoordinatorPromptSurgery` param block. Add `'cursor'`.

(After Phase D, these become `[ValidateScript({ $_ -in (Get-RegisteredHostKinds) })]` or similar registry-driven validators, and this step disappears.)

### Step 8 — run the tests

```powershell
pwsh -File tests/integration/host-registry.tests.ps1
pwsh -File tests/integration/multi-host-launch-path.tests.ps1
```

The host-registry test should pick up Cursor automatically (the test asserts `Get-RegisteredHostKinds` count matches the number of folders under `hosts/`). The multi-host-launch-path test may need its golden expectations extended for Cursor — that's the only test edit needed.

### Step 9 — smoke test

If you have Cursor installed locally:

```powershell
# List shows Cursor
pwsh -File scripts/specrew-host.ps1 list -ProjectPath .

# Select Cursor
pwsh -File scripts/specrew-host.ps1 use cursor -ProjectPath .

# Status shows Cursor's runtime install state
pwsh -File scripts/specrew-host.ps1 status -ProjectPath .

# Launch (--no-launch verifies the argv is built; doesn't actually invoke Cursor)
pwsh -File scripts/specrew-start.ps1 -HostKind cursor -NoLaunch -ProjectPath . "test prompt"
```

You should see Cursor in the list, the status shows whether Cursor's `.cursor/agents/` exists, the start command builds the right argv.

### Step 10 — open a PR

Title: `feat(hosts/cursor): add Cursor IDE CLI as a supported host`

PR body should include:

- Link to Cursor's official CLI docs
- Output of `cursor --help` showing the flags you mapped
- Output of `specrew host list` showing Cursor recognized
- A `tests/integration/multi-host-launch-path.tests.ps1` golden update if needed

## Adding a `Status: deferred` host (placeholder)

Useful when you want to reserve the namespace + add a `--host <kind>` rejection message before full implementation is ready.

```powershell
@{
    Kind             = 'windsurf'
    DisplayName      = 'Codeium Windsurf CLI'
    Status           = 'deferred'
    SchemaVersion    = 1
    Binary           = 'windsurf'
    InstallUrl       = 'https://codeium.com/windsurf'
    SkillRoot        = '.windsurf/skills'   # best-guess; refine in real implementation
    HasUserSlashCommandSurface = $true
    DeferredReason   = 'Awaiting handler implementation; tracked under issue #NNN.'
    DeferredGuidance = 'Windsurf support is planned but not yet implemented. Use --host copilot|claude|codex|antigravity for now.'
    # Handler files not required while Status=deferred
}
```

A deferred host:

- Appears in `specrew host list` as `[deferred]`
- Is REJECTED by `specrew host use windsurf` with the `DeferredGuidance` text
- Is REJECTED by `specrew start --host windsurf` (when wired in F-043 follow-up)
- Does NOT need `handlers.ps1` or `coordinator-rules.psd1` until promotion to `Status: supported`

## Common pitfalls

- **Function name mismatch.** `Resolve-HostHandler -Kind cursor -ContractFunction NewLaunchInvocation` returns `New-CursorLaunchInvocation`. If you defined `New-CursorLaunch` or `Start-Cursor`, dispatch fails. Use the exact template from `_contract.md`.
- **Forgetting `Kind` matches folder name.** The registry rejects manifests where `Kind` ≠ folder-name (lowercase). `hosts/Cursor/host.psd1` with `Kind = 'cursor'` works (folder is auto-lowercased on read), but `hosts/cursor/host.psd1` with `Kind = 'Cursor'` fails validation.
- **Hardcoding the binary path.** Always use `Get-Command` lookup so installed-elsewhere users still work. See `New-CopilotLaunchInvocation` for the canonical pattern.
- **Per-host wrapper functions in shim files.** Do NOT define a wrapper like `Test-CursorRuntimeInstalled` in a shim file (e.g., `host-runtime-inventory.ps1`) — it'll collide with the handler in the same scope and cause infinite recursion. The shim files use the host-neutral iterator pattern instead. (Lesson learned the hard way in the Phase C refactor.)
- **Forgetting `coordinator-rules.psd1`.** Empty `@{ Rules = @() }` is valid — Copilot uses it. But the FILE must exist if the manifest's `CoordinatorRulesFile` field points to it (default `coordinator-rules.psd1`). If the file is missing, the engine treats it as zero rules (graceful).
- **Skipping Step 7 ValidateSet updates.** Tests will fail with "ValidateSet doesn't allow value 'cursor'" — the error is clear; just add the value.
- **PowerShell `,` binds tighter than `+` inside `@(...)` literals** (lesson from Slice 9 implementation):

  ```powershell
  # WRONG — parses as one big concat string, not a 2-element array:
  $arr = @(
      'a' + $role + '.md',
      'b' + $role + '.md'
  )
  # Result: $arr.Count == 1; PowerShell parsed it as 'a' + ('.md', 'b') + $role + '.md'

  # CORRECT — parenthesize each element OR use -f format:
  $arr = @(
      ('a{0}.md' -f $role),
      ('b{0}.md' -f $role)
  )
  ```

  This bit me on all 3 non-Copilot Install-<Kind>CrewRuntime bodies during Slice 9. The fix is a habit: use `-f` format strings inside array literals when interpolating variables.

- **`@(...) -join "`n"` on a single expression returns ZERO LFs.** Use the two-step form:

  ```powershell
  # WRONG — silent: joined string has no LF separators
  $x = @('a', 'b', 'c') -join "`n"

  # CORRECT — explicit:
  $lines = @('a', 'b', 'c')
  $x = $lines -join "`n"
  ```

  Same root cause as the previous gotcha — PowerShell's comma-vs-plus precedence inside the single expression. Two-step pattern dodges it.

## When Phase D lands

The Phase D refactor will eliminate the Step 7 ValidateSet manual updates by introducing `[ValidateScript({ $_ -in (Get-RegisteredHostKinds) })]` on every host-kind parameter. At that point, adding a new host is genuinely 1 mkdir + 3 files + 1 manifest update + 1 PR. No other file edits.

Until then, Step 7 is the one piece of "open-closed violation residue" that remains.

## Where to ask for help

- The host package contract: [`hosts/_contract.md`](../../hosts/_contract.md)
- The architecture overview: [`docs/architecture/host-package-architecture.md`](../architecture/host-package-architecture.md)
- The original design doc with rationale: [`docs/design/host-package-architecture.md`](../design/host-package-architecture.md)
- Existing host packages as reference templates: [`hosts/copilot/`](../../hosts/copilot/), [`hosts/claude/`](../../hosts/claude/), [`hosts/codex/`](../../hosts/codex/), [`hosts/antigravity/`](../../hosts/antigravity/)
- Tests that verify the contract: [`tests/integration/host-registry.tests.ps1`](../../tests/integration/host-registry.tests.ps1)
