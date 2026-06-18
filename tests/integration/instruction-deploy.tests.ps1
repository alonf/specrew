[CmdletBinding()]
param()

# Integration tests for scripts/internal/instruction-deploy.ps1 (F-184 iteration 002 / T003).
# Drives the REAL host registry + the real host manifests: manifest-driven, host-neutral
# deploy/refresh/heal of the coordinator section into each supported host's InstructionsFile,
# with seeded pre-existing user content proving byte-for-byte preservation
# (FR-011/FR-012/FR-015/FR-016; SC-011/SC-012/SC-013/SC-019).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repoRoot 'hosts/_registry.ps1')
. (Join-Path $repoRoot 'scripts/internal/instruction-deploy.ps1')

function Write-NoBom { param([string]$Path, [string]$Text) [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false)) }

$nl = [Environment]::NewLine
$proj = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-instrdeploy-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $proj -Force | Out-Null
try {
    $agentsUser = "# My AGENTS" + $nl + $nl + "USER-AGENTS-CONTENT keep me." + $nl
    $claudeUser = "# My CLAUDE" + $nl + $nl + "USER-CLAUDE-CONTENT keep me." + $nl
    $copilotUser = "# Copilot Project" + $nl + $nl + "USER-COPILOT-CONTENT keep me." + $nl

    $agentsPath = Join-Path $proj 'AGENTS.md'
    $claudePath = Join-Path $proj 'CLAUDE.md'
    $ghDir = Join-Path $proj '.github'
    New-Item -ItemType Directory -Path $ghDir -Force | Out-Null
    $copilotPath = Join-Path $ghDir 'copilot-instructions.md'

    Write-NoBom -Path $agentsPath -Text $agentsUser
    Write-NoBom -Path $claudePath -Text $claudeUser
    Write-NoBom -Path $copilotPath -Text $copilotUser

    # 1. deploy across all supported hosts
    $res = @(Deploy-SpecrewCoordinatorInstructions -ProjectRoot $proj)
    if ($res.Count -lt 3) { Write-Fail "expected >=3 supported-host entries, got $($res.Count)" }
    Write-Pass "deploy enumerated supported hosts ($($res.Count) host entries)"

    # 2. each InstructionsFile got the section + exact FR-013 guard, user content byte-for-byte
    foreach ($pair in @(
            @{ File = $agentsPath; User = $agentsUser },
            @{ File = $claudePath; User = $claudeUser },
            @{ File = $copilotPath; User = $copilotUser }
        )) {
        $onDisk = Get-Content -LiteralPath $pair.File -Raw -Encoding UTF8
        if ($onDisk -notmatch 'specrew-managed coordinator') { Write-Fail "$($pair.File) missing managed section" }
        if ($onDisk -notmatch [regex]::Escape('Do NOT run the raw specify.exe workflow / bundled SDD engine')) { Write-Fail "$($pair.File) missing the exact FR-013 guard" }
        if (-not $onDisk.StartsWith($pair.User)) { Write-Fail "$($pair.File) did not preserve user content byte-for-byte" }
    }
    Write-Pass "every InstructionsFile got the section + exact guard; user content byte-for-byte preserved (FR-011/FR-012/SC-013)"

    # 3. AGENTS.md is shared by codex/antigravity/cursor -> deployed once (dedupe), exactly one block
    $agents = Get-Content -LiteralPath $agentsPath -Raw -Encoding UTF8
    $blocks = ([regex]::Matches($agents, 'specrew-managed coordinator >>>')).Count
    if ($blocks -ne 1) { Write-Fail "AGENTS.md should hold exactly 1 managed block, got $blocks" }
    Write-Pass "shared AGENTS.md deployed once across the 3 AGENTS.md hosts (dedupe, 1 block)"

    # 4. update refresh is idempotent: re-deploy rewrites nothing
    $before = @{ a = (Get-Content -LiteralPath $agentsPath -Raw -Encoding UTF8); c = (Get-Content -LiteralPath $claudePath -Raw -Encoding UTF8) }
    $null = Deploy-SpecrewCoordinatorInstructions -ProjectRoot $proj
    if ((Get-Content -LiteralPath $agentsPath -Raw -Encoding UTF8) -ne $before.a) { Write-Fail "AGENTS.md changed on idempotent re-deploy" }
    if ((Get-Content -LiteralPath $claudePath -Raw -Encoding UTF8) -ne $before.c) { Write-Fail "CLAUDE.md changed on idempotent re-deploy" }
    Write-Pass "re-deploy (update refresh) is idempotent - no InstructionsFile rewritten"

    # 5. start-heal: a missing/stale managed section is restored, user content preserved
    Write-NoBom -Path $agentsPath -Text $agentsUser  # wipe the section back to user-only (stale)
    $null = Deploy-SpecrewCoordinatorInstructions -ProjectRoot $proj
    $healed = Get-Content -LiteralPath $agentsPath -Raw -Encoding UTF8
    if ($healed -notmatch 'specrew-managed coordinator') { Write-Fail "heal did not restore the managed section" }
    if (-not $healed.StartsWith($agentsUser)) { Write-Fail "heal did not preserve user content" }
    Write-Pass "start-heal restores a missing managed section, preserves user content (FR-016/SC-019)"

    # 6. the integration wrapper (init/update/start entry point) deploys + reports on a fresh project
    $proj2 = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-instrwrap-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $proj2 -Force | Out-Null
    try {
        $acts = @(Invoke-SpecrewInstructionDeployment -ProjectPath $proj2)
        if ($acts.Count -lt 1) { Write-Fail "wrapper returned no actions" }
        if (-not ($acts | Where-Object { $_.Action -eq 'coordinator-instructions' })) { Write-Fail "wrapper returned no coordinator-instructions action" }
        if (-not (Test-Path -LiteralPath (Join-Path $proj2 'CLAUDE.md'))) { Write-Fail "wrapper did not create CLAUDE.md" }
        Write-Pass "Invoke-SpecrewInstructionDeployment wrapper deploys + reports (init/update/start entry point)"
    }
    finally {
        if (Test-Path -LiteralPath $proj2) { Remove-Item -LiteralPath $proj2 -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Write-Host ""
    Write-Host "All instruction-deploy integration tests passed." -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $proj) { Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue }
}
