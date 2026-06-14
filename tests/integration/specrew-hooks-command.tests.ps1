# F-174 iteration 011 (T011, FR-028 layer 2, SC-017): the `specrew hooks status|install|remove [--host]`
# repair surface. Drives the REAL command (scripts/specrew-hooks.ps1 -> deploy-refocus-hooks.ps1) against a
# scratch project + a scratch user-home (so user-level writes never touch the real home). Proves the per-host
# states (installed/missing/stale/opted-out/failed), the install/remove opt-out semantics, --host validation,
# and that status runs WITHOUT a project-setup gate.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$hooksScript = Join-Path $repoRoot 'scripts\specrew-hooks.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\specrew-hooks-cmd'
$projectRoot = Join-Path $scratchRoot 'project'
$fakeHome = Join-Path $scratchRoot 'home'

function Reset-Scratch {
    if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
    New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path $fakeHome -Force | Out-Null
}
function Invoke-Hooks {
    param([string[]]$CmdArgs)
    $all = @($CmdArgs) + @('--project-path', $projectRoot, '--user-home-override', $fakeHome)
    return @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $hooksScript @all 2>&1 | ForEach-Object { [string]$_ })
}
function Status-Line { param([string[]]$Out, [string]$HostKind) return (@($Out | Where-Object { $_ -match ("^\s*{0}\s" -f [regex]::Escape($HostKind)) }) -join ' ') }

# --- 1. status on a fresh project: every hook-capable host is 'missing' (NO project-setup gate) -------------
Reset-Scratch
$out = Invoke-Hooks @('status')
Assert-True ($LASTEXITCODE -eq 0) 'status: exits 0 with no .specrew/config.yml present (no project-setup gate)'
foreach ($h in @('claude', 'codex', 'copilot', 'cursor')) {
    Assert-True ((Status-Line -Out $out -HostKind $h) -match 'missing') "status (fresh): $h reported missing"
}

# --- 2. install (bare): provisions all hosts -----------------------------------------------------------------
$out = Invoke-Hooks @('install')
Assert-True ($LASTEXITCODE -eq 0) 'install: exits 0'
Assert-True (Test-Path -LiteralPath (Join-Path $projectRoot '.claude\settings.local.json')) 'install: claude config written'
Assert-True (Test-Path -LiteralPath (Join-Path $fakeHome '.codex\hooks.json')) 'install: codex config written'
Assert-True (Test-Path -LiteralPath (Join-Path $fakeHome '.copilot\hooks\specrew-refocus.json')) 'install: copilot config written'
Assert-True (Test-Path -LiteralPath (Join-Path $fakeHome '.cursor\hooks.json')) 'install: cursor config written'

# --- 3. status after install: all installed ------------------------------------------------------------------
$out = Invoke-Hooks @('status')
foreach ($h in @('claude', 'codex', 'copilot', 'cursor')) {
    Assert-True ((Status-Line -Out $out -HostKind $h) -match 'installed') "status (post-install): $h reported installed"
}

# --- 4. remove --host codex: records opt-out -----------------------------------------------------------------
$out = Invoke-Hooks @('remove', '--host', 'codex')
Assert-True (Test-Path -LiteralPath (Join-Path $projectRoot '.specrew\runtime\refocus-hooks-optout-codex')) 'remove --host codex: opt-out marker recorded'
$out = Invoke-Hooks @('status')
Assert-True ((Status-Line -Out $out -HostKind 'codex') -match 'opted-out') 'status: codex reported opted-out after remove'

# --- 5. install (bare) RESPECTS the opt-out (no silent re-enable) --------------------------------------------
$out = Invoke-Hooks @('install')
$out = Invoke-Hooks @('status')
Assert-True ((Status-Line -Out $out -HostKind 'codex') -match 'opted-out') 'bare install: codex opt-out RESPECTED (still opted-out, no silent re-enable)'
Assert-True ((Status-Line -Out $out -HostKind 'cursor') -match 'installed') 'bare install: a non-opted-out host (cursor) stays installed'

# --- 6. install --host codex: CLEARS the opt-out and re-installs ---------------------------------------------
$out = Invoke-Hooks @('install', '--host', 'codex')
Assert-True (-not (Test-Path -LiteralPath (Join-Path $projectRoot '.specrew\runtime\refocus-hooks-optout-codex'))) 'install --host codex: opt-out marker cleared'
$out = Invoke-Hooks @('status', '--host', 'codex')
Assert-True ((Status-Line -Out $out -HostKind 'codex') -match 'installed') 'status --host codex: codex installed after explicit re-install'

# --- 7. stale detection: a legacy dispatcher entry (no launcher token) on a user-level host ------------------
$cursorCfg = Join-Path $fakeHome '.cursor\hooks.json'
$legacy = '{"version":1,"hooks":{"sessionStart":[{"command":"pwsh -File .specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 -Event SessionStart -HostKind cursor"}]}}'
[System.IO.File]::WriteAllText($cursorCfg, $legacy, [System.Text.UTF8Encoding]::new($false))
$out = Invoke-Hooks @('status', '--host', 'cursor')
Assert-True ((Status-Line -Out $out -HostKind 'cursor') -match 'stale') 'status: a legacy dispatcher entry (no per-machine launcher) is reported stale'

# --- 8. failed detection: unparsable config -----------------------------------------------------------------
[System.IO.File]::WriteAllText((Join-Path $fakeHome '.codex\hooks.json'), '{not valid json', [System.Text.UTF8Encoding]::new($false))
$out = Invoke-Hooks @('status', '--host', 'codex')
Assert-True ((Status-Line -Out $out -HostKind 'codex') -match 'failed') 'status: an unparsable config is reported failed'

# --- 9. --host validation: an unknown / hookless host errors ------------------------------------------------
$out = Invoke-Hooks @('install', '--host', 'bogus')
Assert-True ($LASTEXITCODE -ne 0) 'install --host bogus: unknown host errors (non-zero exit)'
$out = Invoke-Hooks @('install', '--host', 'antigravity')
Assert-True ($LASTEXITCODE -ne 0) 'install --host antigravity: hookless host rejected (non-zero exit)'

# --- summary -------------------------------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "specrew-hooks-command tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'specrew-hooks-command tests: all passed' -ForegroundColor Green
exit 0
