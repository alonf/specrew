[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:SPECREW_MODULE_PATH = $repoRoot
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\boundary-sync-atomic'
$projectRoot = Join-Path $scratchRoot 'project'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = & git -C $projectRoot init --quiet 2>&1
$null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
$null = & git -C $projectRoot config user.name 'Test User' 2>&1

foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\046-046-bug-bash\iterations\001')) {
    $null = New-Item -ItemType Directory -Path (Join-Path $projectRoot $relativeDirectory) -Force
}

[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/046-046-bug-bash`"`n}", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'specs\046-046-bug-bash\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Seed repository' --quiet 2>&1
$null = & git -C $projectRoot branch -M main 2>&1
$null = & git -C $projectRoot checkout -b 046-046-bug-bash 2>&1

$contextPath = Join-Path $projectRoot '.specrew\start-context.json'

# Let's seed start-context.json with boundary_enforcement schema v2
$seededContext = [ordered]@{
    schema = 'v2'
    feature_path = Join-Path $projectRoot 'specs\046-046-bug-bash'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    session_state = [ordered]@{
        active           = $true
        boundary_type    = 'before-implement'
        feature_ref      = '046-046-bug-bash'
        feature_path     = Join-Path $projectRoot 'specs\046-046-bug-bash'
        iteration_number = '001'
        task_id          = $null
        auth_commit_hash = 'SEEDHASH'
        recorded_at      = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
    boundary_enforcement = [ordered]@{
        enabled = $true
        last_authorized_boundary = 'before-implement'
        pending_next_boundary = $null
        verdict_history = @(
            [ordered]@{
                from_boundary = 'tasks'
                to_boundary = 'before-implement'
                verdict_text = 'approved for before-implement'
                authorizing_human = 'Test User'
                recorded_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
                auth_commit_hash = 'SEEDHASH'
            }
        )
        bypass_history = @()
    }
}
[System.IO.File]::WriteAllText($contextPath, ($seededContext | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))

# Commit the context file
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Seed start-context.json' --quiet 2>&1
$authCommit = (@(& git -C $projectRoot rev-parse HEAD 2>&1))[0].ToString().Trim()

# Run the boundary sync helper to sync to 'retro' (was review-signoff: the F-197 co-review gate now
# correctly fail-closes that boundary without promoted evidence, and this test's subject is WRITE
# ATOMICITY - boundary-agnostic - not the gate).
$syncResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $projectRoot,
    '-BoundaryType', 'retro',
    '-FeatureRef', '046-046-bug-bash',
    '-IterationNumber', '001',
    '-AuthCommitHash', $authCommit
)

if ($syncResult.ExitCode -ne 0) {
    Write-Fail ("Boundary sync to retro failed:`n{0}" -f ($syncResult.Output -join [Environment]::NewLine))
    exit 1
}

# F-174 iteration 011 (T005, FR-026 / decision f174-i011-verdict-authority-stop-hook) — RECONCILED + now a
# FALSIFICATION guard. boundary-sync records ONLY the MECHANICAL crossing: it advances the session_state cursor
# (the working position) but MUST NOT assert authorization. A params-only, agent-invoked sync has no
# agent-unforgeable human-verdict signal, so it must NEVER advance last_authorized_boundary and NEVER append
# (let alone fabricate) a verdict_history entry — that fabrication, attributed to the git committer with no
# human signal, was DF-5. Authorization is captured by the Stop/UserPromptSubmit hook (real human verdict) or
# the explicit re-confirm; never here. (Previously this test asserted sync ADVANCED all three atomically — that
# asserted the fabrication itself.)
$context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12

if ($context.session_state.boundary_type -ne 'retro') {
    Write-Fail ("Cursor in session_state.boundary_type did not advance. Expected 'retro', found '{0}'" -f $context.session_state.boundary_type)
    exit 1
}

# FALSIFICATION 1: last_authorized_boundary must NOT have moved — sync never asserts authorization.
if ($context.boundary_enforcement.last_authorized_boundary -ne 'before-implement') {
    Write-Fail ("FABRICATION REGRESSION (DF-5): sync advanced last_authorized_boundary to '{0}' with NO captured human verdict. It MUST stay 'before-implement' — only the hook / explicit re-confirm authorizes." -f $context.boundary_enforcement.last_authorized_boundary)
    exit 1
}

# FALSIFICATION 2: verdict_history must NOT have grown — no invented entry, no git-committer-as-approver.
$history = @($context.boundary_enforcement.verdict_history)
if ($history.Count -ne 1) {
    Write-Fail ("FABRICATION REGRESSION (DF-5): sync appended a verdict_history entry (length {0}, expected the 1 seeded). Sync must record no verdict without captured human evidence." -f $history.Count)
    exit 1
}

# The single surviving entry is the SEEDED one (tasks -> before-implement), untouched.
$seeded = $history[0]
if ($seeded.to_boundary -ne 'before-implement') {
    Write-Fail ("the seeded verdict_history entry was mutated. Expected to_boundary 'before-implement', found '{0}'" -f $seeded.to_boundary)
    exit 1
}

Write-Pass 'Boundary sync advanced the mechanical cursor (session_state) but did NOT advance last_authorized_boundary or fabricate a verdict_history entry (T005/FR-026 — sync never invents an approval)'
exit 0
