[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$registryScript = Join-Path $repoRoot 'hosts\_registry.ps1'
$detectHostsScript = Join-Path $repoRoot 'scripts\internal\detect-hosts.ps1'

if (-not (Test-Path -LiteralPath $registryScript)) {
    Write-Fail "Missing host registry: $registryScript"
}
if (-not (Test-Path -LiteralPath $detectHostsScript)) {
    Write-Fail "Missing legacy detect-hosts.ps1: $detectHostsScript"
}

. $registryScript
. $detectHostsScript

# Test 1: registry discovers 4 host packages
Reset-HostManifestCache
$registered = @(Get-RegisteredHostKinds)
if ($registered.Count -ne 4) {
    Write-Fail "Expected 4 registered hosts; got $($registered.Count): $($registered -join ',')"
}
$expectedKinds = @('antigravity', 'claude', 'codex', 'copilot')   # sorted by Get-RegisteredHostKinds
if (($registered -join ',') -ne ($expectedKinds -join ',')) {
    Write-Fail "Registered host kinds drift. Got: $($registered -join ','). Expected: $($expectedKinds -join ',')"
}
Write-Pass "Registry discovers all 4 host packages (copilot, claude, codex, antigravity)"

# Test 2: every registered host has a valid manifest
foreach ($kind in $registered) {
    $manifest = Get-HostManifest -Kind $kind
    $validation = Test-HostManifestValid -Manifest $manifest
    if (-not $validation.IsValid) {
        Write-Fail "Manifest for '$kind' is invalid: $($validation.Errors -join '; ')"
    }
}
Write-Pass "All 4 manifests pass Test-HostManifestValid"

# Test 3: registry parity with legacy Get-SpecrewSupportedHostKinds
$legacy = @(Get-SpecrewSupportedHostKinds | Sort-Object)
$registry = @(Get-RegisteredHostKinds | Sort-Object)
if (($legacy -join ',') -ne ($registry -join ',')) {
    Write-Fail "Parity drift: legacy=$($legacy -join ',') vs registry=$($registry -join ',')"
}
Write-Pass "Registry matches legacy Get-SpecrewSupportedHostKinds (parity OK)"

# Test 4: per-host manifest field parity with legacy lookup functions
foreach ($kind in $registered) {
    $manifest = Get-HostManifest -Kind $kind
    $legacyBinary = Get-SpecrewHostBinary -HostKind $kind
    if ($manifest.Binary -ne $legacyBinary) {
        Write-Fail "Binary drift for '$kind': manifest='$($manifest.Binary)' legacy='$legacyBinary'"
    }
}
Write-Pass "Per-host Binary field matches Get-SpecrewHostBinary across all 4 hosts"

# Test 5: per-host SkillRoot field parity with legacy lookup
# Use the temp dir as a sacrificial project path to avoid PowerShell drive-validation noise
$tempProject = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), 'specrew-skill-root-parity')
foreach ($kind in $registered) {
    $manifest = Get-HostManifest -Kind $kind
    $legacyAbs = Get-SpecrewHostSkillRoot -HostKind $kind -ProjectPath $tempProject
    # strip the project-prefix to get the relative skill-root; normalize separators to forward slashes
    $expectedAbs = Join-Path $tempProject ($manifest.SkillRoot -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if ($legacyAbs -ne $expectedAbs) {
        Write-Fail "SkillRoot drift for '$kind': manifest yields '$expectedAbs' legacy yields '$legacyAbs'"
    }
}
Write-Pass "Per-host SkillRoot field matches Get-SpecrewHostSkillRoot across all 4 hosts"

# Test 6: status filter helpers work
$supported = @(Get-SpecrewHostsByStatus -Status supported)
if ($supported.Count -ne 4) {
    Write-Fail "Expected 4 supported hosts post-antigravity-followup; got $($supported.Count): $($supported -join ',')"
}
Write-Pass "Get-SpecrewHostsByStatus -Status supported returns all 4 (antigravity promoted)"

$deferred = @(Get-SpecrewHostsByStatus -Status deferred)
if ($deferred.Count -ne 0) {
    Write-Fail "Expected 0 deferred hosts; got $($deferred.Count): $($deferred -join ',')"
}
Write-Pass "Get-SpecrewHostsByStatus -Status deferred returns empty (no host currently deferred)"

# Test 7: contract folder-name vs Kind parity
foreach ($kind in $registered) {
    $manifest = Get-HostManifest -Kind $kind
    if ($manifest.Kind -ne $kind) {
        Write-Fail "Folder/Kind drift: folder='$kind' manifest.Kind='$($manifest.Kind)'"
    }
}
Write-Pass "All 4 host folder names match their manifest Kind field (lowercase)"

# Test 8: unknown host throws
try {
    Get-HostManifest -Kind 'cursor' | Out-Null
    Write-Fail "Get-HostManifest -Kind cursor should throw but did not"
}
catch {
    if ($_.Exception.Message -notmatch 'Unknown host kind') {
        Write-Fail "Unexpected error from Get-HostManifest -Kind cursor: $($_.Exception.Message)"
    }
}
Write-Pass "Get-HostManifest -Kind <unknown> throws with clear error"

# Test 9: Resolve-HostHandler returns the right per-host function name
$expectedFunctionNames = @{
    'copilot|NewLaunchInvocation'     = 'New-CopilotLaunchInvocation'
    'claude|ConvertFlag'              = 'ConvertTo-ClaudeFlag'
    'codex|TestRuntimeInstalled'      = 'Test-CodexRuntimeInstalled'
    'antigravity|GetSignals'          = 'Get-AntigravitySignals'
}
foreach ($kv in $expectedFunctionNames.GetEnumerator()) {
    $parts = $kv.Key -split '\|'
    $resolved = Resolve-HostHandler -Kind $parts[0] -ContractFunction $parts[1]
    if ($resolved -ne $kv.Value) {
        Write-Fail "Resolve-HostHandler drift: $($kv.Key) resolved to '$resolved' (expected '$($kv.Value)')"
    }
}
Write-Pass "Resolve-HostHandler returns correct per-host function names for all 4 hosts"

# Test 10: Invoke-HostHandler dispatches the right per-host launch invocation
foreach ($kind in @('copilot', 'claude', 'codex', 'antigravity')) {
    $invocation = Invoke-HostHandler -Kind $kind -ContractFunction NewLaunchInvocation -Arguments @{
        ProjectPath = 'C:\proj'
        Prompt      = 'BOOT'
        Agent       = 'Squad'
    }
    if ($invocation.HostKind -ne $kind) {
        Write-Fail "Invoke-HostHandler dispatched wrong host: returned HostKind='$($invocation.HostKind)' for Kind='$kind'"
    }
}
Write-Pass "Invoke-HostHandler dispatches NewLaunchInvocation for all 4 hosts"

# Test 11: Per-host launch argv parity with legacy Get-SpecrewHostLaunchInvocation (copilot, claude, codex; antigravity is NEW)
. (Join-Path $repoRoot 'scripts\internal\host-flag-translation.ps1')   # required by legacy
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
# specrew-start.ps1 is too big to dot-source — extract just Get-SpecrewHostLaunchInvocation via regex
$startContent = Get-Content -LiteralPath $startScript -Raw
$match = [regex]::Match($startContent, '(?s)function Get-SpecrewHostLaunchInvocation \{.*?^\}', 'Multiline')
if (-not $match.Success) {
    Write-Fail "Could not extract Get-SpecrewHostLaunchInvocation from specrew-start.ps1"
}
# Dot-source the extracted function into current scope
Invoke-Expression $match.Value

$flagPermutations = @(
    @{ AllowAll = $false; UseAutopilot = $false; UseRemote = $false },
    @{ AllowAll = $true;  UseAutopilot = $false; UseRemote = $false },
    @{ AllowAll = $false; UseAutopilot = $true;  UseRemote = $false },
    @{ AllowAll = $true;  UseAutopilot = $true;  UseRemote = $true  }
)
foreach ($kind in @('copilot', 'claude', 'codex')) {
    foreach ($perm in $flagPermutations) {
        $legacy = Get-SpecrewHostLaunchInvocation `
            -HostKind $kind `
            -ResolvedProjectPath 'C:\proj' `
            -BootstrapPrompt 'BOOT' `
            -Agent 'Squad' `
            -AllowAll $perm.AllowAll `
            -UseAutopilot $perm.UseAutopilot `
            -UseRemote $perm.UseRemote
        $package = Invoke-HostHandler -Kind $kind -ContractFunction NewLaunchInvocation -Arguments @{
            ProjectPath  = 'C:\proj'
            Prompt       = 'BOOT'
            Agent        = 'Squad'
            AllowAll     = $perm.AllowAll
            UseAutopilot = $perm.UseAutopilot
            UseRemote    = $perm.UseRemote
        }
        $legacyArgs = $legacy.Args -join '|'
        $packageArgs = $package.Args -join '|'
        if ($legacyArgs -ne $packageArgs) {
            Write-Fail "Launch-invocation argv drift for kind=$kind perm=$(($perm.Keys | ForEach-Object { "$_=$($perm[$_])" }) -join ','): legacy='$legacyArgs' package='$packageArgs'"
        }
    }
}
Write-Pass "Per-host launch-invocation argv matches legacy Get-SpecrewHostLaunchInvocation across 12 permutations (3 hosts × 4 flag combinations)"

# Test 12: Per-host flag translation parity with legacy Get-HostFlagTranslation (3 hosts in legacy switch)
foreach ($kind in @('copilot', 'claude', 'codex', 'antigravity')) {
    foreach ($flag in @('--remote', '--allow-all', '--autopilot')) {
        $legacy = Get-HostFlagTranslation -HostKind $kind -SpecrewFlag $flag
        $package = Invoke-HostHandler -Kind $kind -ContractFunction ConvertFlag -Arguments @{ SpecrewFlag = $flag }
        if (($legacy.Args -join '|') -ne ($package.Args -join '|')) {
            Write-Fail ("Flag-translation Args drift for kind={0} flag={1}: legacy='{2}' package='{3}'" -f $kind, $flag, ($legacy.Args -join '|'), ($package.Args -join '|'))
        }
        if ([string]$legacy.Notice -ne [string]$package.Notice) {
            Write-Fail ("Flag-translation Notice drift for kind={0} flag={1}: legacy='{2}' package='{3}'" -f $kind, $flag, [string]$legacy.Notice, [string]$package.Notice)
        }
    }
}
Write-Pass "Per-host flag-translation matches legacy Get-HostFlagTranslation across 12 cells (4 hosts × 3 flags)"

# Test 13: Unknown contract function throws
try {
    Resolve-HostHandler -Kind copilot -ContractFunction 'GibberishFunction' | Out-Null
    Write-Fail "Resolve-HostHandler should throw on unknown contract function but did not"
}
catch {
    if ($_.Exception.Message -notmatch 'Unknown contract function') {
        Write-Fail "Unexpected error: $($_.Exception.Message)"
    }
}
Write-Pass "Resolve-HostHandler throws on unknown contract function"

Write-Host "`nHost registry: all assertions pass" -ForegroundColor Green
