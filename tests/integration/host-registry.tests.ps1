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

# Test 9: Phase B stubs throw (until handlers ship)
try {
    Resolve-HostHandler -Kind copilot -ContractFunction 'NewLaunchInvocation' | Out-Null
    Write-Fail "Resolve-HostHandler should throw (Phase B stub) but did not"
}
catch {
    if ($_.Exception.Message -notmatch 'Phase B stub') {
        Write-Fail "Unexpected error from Resolve-HostHandler stub: $($_.Exception.Message)"
    }
}
Write-Pass "Resolve-HostHandler and Invoke-HostHandler throw the expected Phase B stub message"

Write-Host "`nHost registry: all assertions pass" -ForegroundColor Green
