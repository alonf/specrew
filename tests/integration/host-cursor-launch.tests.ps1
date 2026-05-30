[CmdletBinding()]
param()

# F-050 iter-002 (FR-006): integration smoke for the `specrew start --host cursor` launch path.
# Exercises the full dispatch: Get-SpecrewHostLaunchInvocation (the specrew-start.ps1 wrapper,
# whose -HostKind ValidateSet must accept 'cursor') -> Invoke-HostHandler -> New-CursorLaunchInvocation.
# Real-binary assertions are skip-guarded when cursor-agent is not on PATH (CI runners).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Write-Skip { param([string]$Message) Write-Host "SKIP: $Message" -ForegroundColor Yellow }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
. (Join-Path $repoRoot 'hosts\_registry.ps1')
. (Join-Path $repoRoot 'scripts\internal\host-flag-translation.ps1')

# Extract Get-SpecrewHostLaunchInvocation from specrew-start.ps1 (too large to dot-source) —
# this proves the wrapper's -HostKind ValidateSet accepts 'cursor' end-to-end (the DRIFT-001 fix).
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$startContent = Get-Content -LiteralPath $startScript -Raw
$match = [regex]::Match($startContent, '(?s)function Get-SpecrewHostLaunchInvocation \{.*?^\}', 'Multiline')
if (-not $match.Success) { Write-Fail "Could not extract Get-SpecrewHostLaunchInvocation from specrew-start.ps1" }
Invoke-Expression $match.Value

# Test 1: the wrapper accepts --host cursor (ValidateSet) and dispatches to the cursor handler
$inv = Get-SpecrewHostLaunchInvocation -HostKind cursor -ResolvedProjectPath 'C:\proj' -BootstrapPrompt 'BOOT' -Agent 'Squad' -AllowAll $false -UseAutopilot $false -UseRemote $false
if ($inv.HostKind -ne 'cursor') { Write-Fail "Launch dispatch returned HostKind='$($inv.HostKind)' (expected cursor)" }
Write-Pass "specrew-start Get-SpecrewHostLaunchInvocation accepts --host cursor and dispatches to the cursor handler"

# Test 2: default launch is interactive (prompt + --workspace), no auto-approve, no headless flags
$dArgs = @($inv.Args)
if ('BOOT' -notin $dArgs) { Write-Fail "Default launch missing positional prompt. Args: $($dArgs -join ' ')" }
if ('--workspace' -notin $dArgs) { Write-Fail "Default launch missing --workspace. Args: $($dArgs -join ' ')" }
if ('C:\proj' -notin $dArgs) { Write-Fail "Default launch missing workspace path. Args: $($dArgs -join ' ')" }
if ('--print' -in $dArgs) { Write-Fail "Default launch must be interactive, not --print. Args: $($dArgs -join ' ')" }
if ('--force' -in $dArgs) { Write-Fail "Default launch must not auto-approve. Args: $($dArgs -join ' ')" }
if ('--trust' -in $dArgs) { Write-Fail "Default launch must not include headless-only --trust. Args: $($dArgs -join ' ')" }
Write-Pass "Default cursor launch is interactive (BOOT --workspace C:\proj), no auto-approve/headless flags"

# Test 3: AllowAll adds --force (run-everything), still no --trust
$invAllow = Get-SpecrewHostLaunchInvocation -HostKind cursor -ResolvedProjectPath 'C:\proj' -BootstrapPrompt 'BOOT' -Agent 'Squad' -AllowAll $true -UseAutopilot $false -UseRemote $false
$aArgs = @($invAllow.Args)
if ('--force' -notin $aArgs) { Write-Fail "AllowAll launch should add --force. Args: $($aArgs -join ' ')" }
if ('--trust' -in $aArgs) { Write-Fail "AllowAll launch should still NOT add headless-only --trust. Args: $($aArgs -join ' ')" }
Write-Pass "AllowAll cursor launch adds --force (no --trust)"

# Test 4 (real-binary, skip-guarded): when cursor-agent is on PATH, Binary resolves to its real path
$cursorOnPath = Get-Command 'cursor-agent' -ErrorAction SilentlyContinue
if ($null -eq $cursorOnPath) {
    Write-Skip "cursor-agent not on PATH — skipping real-binary resolution assertion"
}
else {
    if ([string]::IsNullOrWhiteSpace([string]$inv.Binary)) { Write-Fail "Launch Binary is empty despite cursor-agent on PATH" }
    if ($inv.Binary -notmatch 'cursor-agent') { Write-Fail "Launch Binary should reference cursor-agent; got '$($inv.Binary)'" }
    Write-Pass "Real cursor-agent on PATH resolves into the launch Binary ($($inv.Binary))"
}

Write-Host "`nHost cursor launch smoke: all assertions pass" -ForegroundColor Green
