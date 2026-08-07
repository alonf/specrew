# Post-bootstrap output helpers for specrew-init.ps1 (extracted via Proposal 108 Slice 8)
#
# Depends on: scripts/init/_utilities.ps1 (Get-SpecrewExecutionLayout)
#
# Functions:
#   - Write-PostBootstrapGuidance  130-line bootstrap-success splash (greeting, usage flow, next steps,
#                                  slash-command surface, team extension instructions, PATH guidance)
#   - Write-BootstrapSummary       final action-table summary (single-line outcomes per step)
#
# Host-coupling notes (Phase D / Slice 9+ follow-up):
# Write-PostBootstrapGuidance is now Crew-generic — "the Crew" instead of "Squad" — since F-044
# Slice 9 ships per-host Crew runtimes for Claude, Codex, and Antigravity in addition to Copilot.
# Host-specific runtime paths (.squad/team.md customization, /specrew-* surface availability per
# host) remain Copilot-default at init time; per-host runtime team customization is queued behind
# the `specrew team` CLI rewire follow-up (see specs/044-per-host-architecture-refactor/spec.md).

Set-StrictMode -Version Latest

function Write-SpecrewBootstrapBaselineRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('automatic', 'offered', 'declined')]
        [string]$Decision
    )

    $specrewRoot = Join-Path $ProjectPath '.specrew'
    if (-not (Test-Path -LiteralPath $specrewRoot -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $specrewRoot -Force
    }

    $recordPath = Join-Path $specrewRoot 'bootstrap-baseline.json'
    $record = [ordered]@{
        schema_version = '1.0'
        mode = if ($Decision -eq 'automatic') { 'greenfield' } else { 'brownfield' }
        decision = $Decision
        commit_message = 'chore(specrew): bootstrap scaffold'
        recorded_at = [DateTime]::UtcNow.ToString('o')
    }
    $json = $record | ConvertTo-Json -Depth 4
    $temporaryPath = '{0}.{1}.tmp' -f $recordPath, [Guid]::NewGuid().ToString('N')
    [System.IO.File]::WriteAllText($temporaryPath, ($json + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $recordPath -Force
    return $recordPath
}

function Invoke-SpecrewBootstrapBaseline {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('greenfield', 'brownfield')]
        [string]$BootstrapMode,

        [Parameter(Mandatory = $true)]
        [ValidateSet('offer', 'decline')]
        [string]$BrownfieldDecision,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    $commitMessage = 'chore(specrew): bootstrap scaffold'
    $recordPath = Join-Path $ProjectPath '.specrew\bootstrap-baseline.json'
    $existingDecision = $null
    if (Test-Path -LiteralPath $recordPath -PathType Leaf) {
        try {
            $existingRecord = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            $existingDecision = [string]$existingRecord.decision
        }
        catch {
            throw "Bootstrap baseline record is malformed: '$recordPath'."
        }
    }

    if ($existingDecision -eq 'automatic') {
        Add-Action -Actions $Actions -Step 'bootstrap-commit' -Outcome 'preserved recorded greenfield bootstrap baseline'
        return [pscustomobject]@{ Mode = 'greenfield'; Decision = 'automatic'; Commit = $null; RecordPath = $recordPath }
    }

    if ($BootstrapMode -eq 'brownfield') {
        $decision = if ($existingDecision -eq 'declined' -and $BrownfieldDecision -eq 'offer') { 'declined' } elseif ($BrownfieldDecision -eq 'decline') { 'declined' } else { 'offered' }
        if ($PreviewOnly) {
            Add-Action -Actions $Actions -Step 'bootstrap-commit' -Outcome ("would record brownfield bootstrap-commit {0}; no commit would be created" -f $decision)
            return [pscustomobject]@{ Mode = 'brownfield'; Decision = $decision; Commit = $null; RecordPath = $recordPath }
        }

        $recordPath = Write-SpecrewBootstrapBaselineRecord -ProjectPath $ProjectPath -Decision $decision
        if ($decision -eq 'declined') {
            Write-Host ("Brownfield bootstrap commit declined and recorded at {0}; no commit was created." -f $recordPath) -ForegroundColor Yellow
        }
        else {
            Write-Host 'Brownfield repository detected; Specrew did not create a surprise commit.' -ForegroundColor Yellow
            Write-Host ("Bootstrap commit offer recorded at {0}. Review 'git status', stage the scaffold you accept, then commit it as '{1}'. To record a decline, rerun init with --brownfield-bootstrap-commit decline." -f $recordPath, $commitMessage) -ForegroundColor Yellow
        }
        Add-Action -Actions $Actions -Step 'bootstrap-commit' -Outcome ("brownfield {0}; no commit created; record={1}" -f $decision, $recordPath)
        return [pscustomobject]@{ Mode = 'brownfield'; Decision = $decision; Commit = $null; RecordPath = $recordPath }
    }

    if ($PreviewOnly) {
        Add-Action -Actions $Actions -Step 'bootstrap-commit' -Outcome ("would create and announce greenfield commit '{0}'" -f $commitMessage)
        return [pscustomobject]@{ Mode = 'greenfield'; Decision = 'automatic'; Commit = $null; RecordPath = $recordPath }
    }

    $insideWorkTree = @(& git -C $ProjectPath rev-parse --is-inside-work-tree 2>$null)
    if ($LASTEXITCODE -ne 0 -or ($insideWorkTree -join '').Trim() -ne 'true') {
        $null = & git -C $ProjectPath init --quiet 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Greenfield bootstrap completed, but Git repository initialization failed for '$ProjectPath'."
        }
    }

    $createdRecord = $false
    try {
        $recordPath = Write-SpecrewBootstrapBaselineRecord -ProjectPath $ProjectPath -Decision 'automatic'
        $createdRecord = $true
        $addOutput = @(& git -C $ProjectPath add --all 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw ("Greenfield bootstrap staging failed: {0}" -f ($addOutput -join [Environment]::NewLine))
        }

        $configuredUserName = (@(& git -C $ProjectPath config --get user.name 2>$null) | Select-Object -First 1)
        $configuredUserEmail = (@(& git -C $ProjectPath config --get user.email 2>$null) | Select-Object -First 1)
        $identityArguments = @()
        if ([string]::IsNullOrWhiteSpace($configuredUserName) -or [string]::IsNullOrWhiteSpace($configuredUserEmail)) {
            # Keep the bootstrap reliable on brand-new machines and CI without mutating global or local Git config.
            # A configured user identity always wins; this command-scoped identity is only the no-config fallback.
            $identityArguments = @('-c', 'user.name=Specrew Bootstrap', '-c', 'user.email=specrew-bootstrap@example.invalid')
        }
        $commitOutput = @(& git -C $ProjectPath @identityArguments commit --quiet -m $commitMessage 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw ("Greenfield bootstrap commit failed: {0}" -f ($commitOutput -join [Environment]::NewLine))
        }

        $commit = (@(& git -C $ProjectPath rev-parse HEAD 2>&1) | Select-Object -First 1).Trim()
        if ($LASTEXITCODE -ne 0 -or $commit -notmatch '^[0-9a-f]{40}$') {
            throw 'Greenfield bootstrap commit was created, but its full Git identity could not be resolved.'
        }

        Write-Host ("Created bootstrap commit {0}: {1}" -f $commit, $commitMessage) -ForegroundColor Green
        Add-Action -Actions $Actions -Step 'bootstrap-commit' -Outcome ("created and announced {0}: {1}" -f $commit, $commitMessage)
        return [pscustomobject]@{ Mode = 'greenfield'; Decision = 'automatic'; Commit = $commit; RecordPath = $recordPath }
    }
    catch {
        $null = & git -C $ProjectPath rm --cached -r --ignore-unmatch . 2>$null
        if ($createdRecord -and (Test-Path -LiteralPath $recordPath -PathType Leaf)) {
            Remove-Item -LiteralPath $recordPath -Force -ErrorAction SilentlyContinue
        }
        throw
    }
}

function Write-PostBootstrapGuidance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $baselineRoles = 'Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator'
    $canonicalTeamPath = Join-Path $ProjectPath '.specrew\team\agents\'
    # Use the execution layout's scripts dir (one level below RootPath), NOT $PSScriptRoot.
    # After Slice 8, $PSScriptRoot here is scripts/init/, but the PATH guidance must point to
    # scripts/ (where specrew.ps1 lives). Resolve from the layout to stay location-independent.
    $executionLayout = Get-SpecrewExecutionLayout
    $isModuleContext = ($executionLayout.Mode -eq 'module')
    $specrewScriptsPath = Join-Path $executionLayout.RootPath 'scripts'

    Write-Host ''
    Write-Host '         ╱─────────────────╲' -ForegroundColor Cyan
    Write-Host '        ╱  ●━━●━━●          ╲' -ForegroundColor Cyan
    Write-Host '       │       ╲             │' -ForegroundColor Cyan
    Write-Host '       │   ●━━●━━●           │' -ForegroundColor Blue
    Write-Host '       │        ╲            │' -ForegroundColor Blue
    Write-Host '        ╲  ●━━●━━●          ╱' -ForegroundColor Blue
    Write-Host '         ╲─────────────────╱' -ForegroundColor Blue
    Write-Host ''
    Write-Host '         S  P  E  C  R  E  W' -ForegroundColor White
    Write-Host '    ─── GOVERNED AGENTIC SDLC ───' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '         Bootstrap Complete' -ForegroundColor Green
    Write-Host ''
    Write-Host ("Baseline Specrew crew installed: {0}." -f $baselineRoles) -ForegroundColor White
    Write-Host ''
    Write-Host '=== Usage Flow ===' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Baseline Crew → specrew start → the Crew drives specify → clarify for new specs (or recorded skip on resumed clarified work) → plan → tasks → implement → review → retro' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '=== Next Steps ===' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '1. Start spec authoring (Spec Kit workflows):' -ForegroundColor Yellow
    Write-Host '   - Run specrew start from the project root (optionally add a short feature request)' -ForegroundColor White
    Write-Host '   - Specrew launches the selected host CLI (default: Copilot; `--host claude`, `--host codex`, `--host antigravity`, or `--host cursor` available) from the project directory in the current terminal by default, stays out of autopilot until intake is grounded, and supports --new-window or --prompt-approvals when you want them' -ForegroundColor White
    Write-Host '   - Specrew hands off to the selected host CLI with full lifecycle context auto-loaded' -ForegroundColor White
    Write-Host '   - The Crew drives specify -> clarify -> plan -> tasks -> implement (skip clarify only for resumed clarified work with a recorded rationale)' -ForegroundColor White
    Write-Host ''
    Write-Host '2. Resuming work later:' -ForegroundColor Yellow
    Write-Host '   - Every later session also starts with specrew start from the project root' -ForegroundColor White
    Write-Host '   - specrew start regenerates the runtime handoff before launch' -ForegroundColor White
    Write-Host '   - Do not run the host CLI directly (e.g., `copilot ...` / `claude ...` / `codex ...`); going around `specrew start` skips the bootstrap refresh and leaves the launch contract stale' -ForegroundColor White
    Write-Host ''
    Write-Host '3. Run the iteration lifecycle:' -ForegroundColor Yellow
    Write-Host '   - Materialize iteration artifacts under specs/<feature>/iterations/<NNN>/' -ForegroundColor White
    Write-Host '   - Keep plan.md, state.md, drift-log.md, review.md, and retro.md current by phase' -ForegroundColor White
    Write-Host '   - Run validate-governance.ps1 before phase transitions' -ForegroundColor White
    Write-Host ''
    Write-Host 'Slash-command surface provisioned:' -ForegroundColor Green
    Write-Host '   - /specrew-where, /specrew-status, /specrew-update, /specrew-team, /specrew-review, /specrew-help, /specrew-version' -ForegroundColor White
    Write-Host '   - Deployed to .claude/skills/, .github/skills/, and .agents/skills/ with identical SKILL.md content' -ForegroundColor White
    Write-Host '   - If host-native /specrew- discovery is unavailable, use /specrew-help as the catalog fallback' -ForegroundColor White
    Write-Host ''
    Write-Host '4. (Optional) Add domain-specific team members:' -ForegroundColor Yellow
    Write-Host '   Add extra Crew members (Security Analyst, UX Designer, DBA, or other specialists)' -ForegroundColor White
    Write-Host '   using Specrew team management commands. Custom agents are stored at the canonical' -ForegroundColor White
    Write-Host ('   location ({0}) and re-translated to each host' -f $canonicalTeamPath) -ForegroundColor White
    Write-Host '   on the next `specrew start`:' -ForegroundColor White
    Write-Host ''

    if ($isModuleContext) {
        Write-Host '  specrew team add <member-name> --role <role> --charter "<charter-text>"' -ForegroundColor White
        Write-Host '  specrew start' -ForegroundColor White
        Write-Host '  specrew team list' -ForegroundColor White
        Write-Host '  specrew team update <member-name> --charter "<new-charter>"' -ForegroundColor White
        Write-Host '  specrew team remove <member-name>' -ForegroundColor White
    } else {
        Write-Host '  pwsh -File <specrew-repo>/scripts/specrew.ps1 team add <member-name> --role <role> --charter "<charter-text>"' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>/scripts/specrew.ps1 start' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>/scripts/specrew.ps1 team list' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>/scripts/specrew.ps1 team update <member-name> --charter "<new-charter>"' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>/scripts/specrew.ps1 team remove <member-name>' -ForegroundColor White
    }

    Write-Host ''
    Write-Host ('   Keep the Specrew-managed baseline charters intact under {0}.' -f $canonicalTeamPath) -ForegroundColor Yellow
    Write-Host '   (Generated host-native files under .squad/, .claude/, .codex/, .agents/ are re-synced' -ForegroundColor DarkGray
    Write-Host '   from canonical on every specrew start; delete the .specrew-managed sidecar to opt out.)' -ForegroundColor DarkGray
    Write-Host ''

    if (-not $isModuleContext) {
        Write-Host 'Replace <specrew-repo> with the actual path where you cloned Specrew.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '=== Optional: Add Specrew to PATH for Convenience ===' -ForegroundColor Cyan
        Write-Host ''
        Write-Host 'To use the short form (e.g., "specrew team list") instead of full paths,' -ForegroundColor White
        Write-Host 'you can add the scripts directory to your PATH.' -ForegroundColor White
        Write-Host ''

        if ($IsWindows) {
            Write-Host 'OPTION 1: Current Session Only (Windows)' -ForegroundColor Yellow
            Write-Host 'Run this command in your current PowerShell session:' -ForegroundColor White
            Write-Host ''
            Write-Host ('  $env:PATH = "$env:PATH;{0}"' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ''
            Write-Host '(This only affects the current shell and is lost when you close it.)' -ForegroundColor DarkGray
            Write-Host ''
            Write-Host 'OPTION 2: Persistent (All Future Sessions, Windows)' -ForegroundColor Yellow
            Write-Host 'To make this permanent for your user account, run:' -ForegroundColor White
            Write-Host ''
            Write-Host ('  $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")') -ForegroundColor Green
            Write-Host ('  $pathEntries = $currentPath -split "";""') -ForegroundColor Green
            Write-Host ('  if ($pathEntries -notcontains ""{0}"") {{' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ('      [Environment]::SetEnvironmentVariable("PATH", "$currentPath;{0}", "User")' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ('      Write-Host "Added Specrew scripts to user PATH. Restart your shell to apply." -ForegroundColor Green') -ForegroundColor Green
            Write-Host ('  }') -ForegroundColor Green
            Write-Host ''
            Write-Host '(This adds the path to your user-level environment and persists across sessions.' -ForegroundColor DarkGray
            Write-Host ' Restart your shell after running this command.)' -ForegroundColor DarkGray
        } elseif ($IsLinux -or $IsMacOS) {
            $shellProfile = if ($IsMacOS) { '~/.zshrc or ~/.bash_profile' } else { '~/.bashrc or ~/.profile' }
            Write-Host 'Adding Specrew to PATH (Linux/macOS)' -ForegroundColor Yellow
            Write-Host ('Add this line to your shell profile ({0}):' -f $shellProfile) -ForegroundColor White
            Write-Host ''
            Write-Host ('  export PATH="$PATH:{0}"' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ''
            Write-Host 'Then reload your shell:' -ForegroundColor White
            Write-Host ''
            Write-Host ('  source {0}' -f $shellProfile) -ForegroundColor Green
            Write-Host ''
            Write-Host 'Or restart your terminal.' -ForegroundColor DarkGray
        }

        Write-Host ''
    }

    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Documentation:' -ForegroundColor White
    Write-Host '  - Getting Started: docs/getting-started.md' -ForegroundColor DarkGray
    Write-Host '  - User Guide: docs/user-guide.md' -ForegroundColor DarkGray
    Write-Host ''
}

function Write-BootstrapSummary {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [bool]$DryRunMode,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [bool]$ShowGuidance
    )

    Write-Host ''
    Write-Host 'Bootstrap summary' -ForegroundColor Green
    $Actions | Format-Table -AutoSize

    if ($DryRunMode) {
        Write-Host 'Dry run complete. No files were changed.' -ForegroundColor Yellow
        return
    }

    Write-Host ("Bootstrap completed for {0}." -f $ProjectPath) -ForegroundColor Green
    if ($ShowGuidance) {
        Write-PostBootstrapGuidance -ProjectPath $ProjectPath
    }
}

