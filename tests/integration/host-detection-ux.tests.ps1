[CmdletBinding()]
param()

# F-044 iter-004/005 regression tests for host detection + UX surfaces.
# Promotes the .scratch/iter004-smoke.ps1 verification to CI-tracked integration.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
. (Join-Path $repoRoot 'hosts\_registry.ps1')
. (Join-Path $repoRoot 'scripts\internal\detect-hosts.ps1')
. (Join-Path $repoRoot 'scripts\internal\host-history.ps1')

# Test 1: Test-SpecrewHostBinaryAvailable exists (iter-004 helper extraction)
if (-not (Get-Command Test-SpecrewHostBinaryAvailable -ErrorAction SilentlyContinue)) {
    Write-Fail "Test-SpecrewHostBinaryAvailable helper missing — iter-004 T001 regression."
}
Write-Pass "Test-SpecrewHostBinaryAvailable helper exists (iter-004 T001)"

# Test 2: Test-SpecrewHostAvailable + Test-SpecrewHostBinaryAvailable agree per kind
foreach ($kind in @(Get-SpecrewHostsByStatus -Status supported)) {
    $available = Test-SpecrewHostAvailable -HostKind $kind
    $resolvedBinary = Test-SpecrewHostBinaryAvailable -Kind $kind
    $helperAvailable = ($null -ne $resolvedBinary)
    if ($available -ne $helperAvailable) {
        Write-Fail "Detection mismatch for '$kind': Test-SpecrewHostAvailable=$available vs Test-SpecrewHostBinaryAvailable=$helperAvailable. Both must agree (iter-004 T003)."
    }
}
Write-Pass "Test-SpecrewHostAvailable + Test-SpecrewHostBinaryAvailable agree per supported host (iter-004 T003 consumer/helper parity)"

# Test 3: BinaryAliases is OPTIONAL but at least one manifest declares it (contract canary).
# Hosts that need alternate command names use this field; if zero manifests declare it,
# the field is dead and the iter-004 T003 probe logic is untested. (Antigravity declares
# BinaryAliases = @() — empty array — as the canonical canary.)
$kindsDeclaringAliases = @()
foreach ($kind in @(Get-RegisteredHostKinds)) {
    $manifest = Get-HostManifest -Kind $kind
    if ($manifest.ContainsKey('BinaryAliases')) {
        $kindsDeclaringAliases += $kind
    }
}
if ($kindsDeclaringAliases.Count -eq 0) {
    Write-Fail "No manifest declares BinaryAliases — iter-004 T003 probe logic untested at runtime. Antigravity should declare it (even if empty array) as the canary."
}
Write-Pass ("BinaryAliases declared by {0} host(s) — probe logic exercised" -f $kindsDeclaringAliases.Count)

# Test 4: First-run probe non-interactive returns documented Source values
$probe = Invoke-SpecrewFirstRunHostProbe -NonInteractive $true
$validSources = @('auto-single-available', 'non-interactive-no-default', 'no-hosts-available')
if ($probe.Source -notin $validSources) {
    Write-Fail "First-run probe non-interactive returned unexpected Source '$($probe.Source)'. Valid: $($validSources -join ', ')"
}
Write-Pass ("First-run probe non-interactive Source = '{0}' (in valid set)" -f $probe.Source)

# Test 5: First-run probe Available array contains only supported kinds
$supportedKinds = @(Get-SpecrewHostsByStatus -Status supported)
foreach ($avail in @($probe.Available)) {
    if ($avail -notin $supportedKinds) {
        Write-Fail "First-run probe Available contains '$avail' which is not a supported host kind"
    }
}
Write-Pass "First-run probe Available contains only supported host kinds"

# Test 6: iter-005 antigravity launch shape — Binary=agy, Args contains -i + --add-dir (NOT -p, --output-format, --cwd)
$invocation = Invoke-HostHandler -Kind antigravity -ContractFunction NewLaunchInvocation -Arguments @{
    ProjectPath = 'C:\test\proj'
    Prompt      = 'test prompt'
    Agent       = 'Squad'
    AllowAll    = $true
}
$argsArray = @($invocation.Args)
if ('-i' -notin $argsArray) { Write-Fail "Antigravity launch missing -i (interactive) flag. Args: $($argsArray -join ' ')" }
if ('--add-dir' -notin $argsArray) { Write-Fail "Antigravity launch missing --add-dir flag. Args: $($argsArray -join ' ')" }
if ('-p' -in $argsArray) { Write-Fail "Antigravity launch should NOT include -p (non-interactive). Args: $($argsArray -join ' ')" }
if ('--output-format' -in $argsArray) { Write-Fail "Antigravity launch should NOT include --output-format (agy CLI rejects it). Args: $($argsArray -join ' ')" }
if ('--cwd' -in $argsArray) { Write-Fail "Antigravity launch should NOT include --cwd (use --add-dir). Args: $($argsArray -join ' ')" }
if ('--dangerously-skip-permissions' -notin $argsArray) { Write-Fail "Antigravity AllowAll=true should add --dangerously-skip-permissions. Args: $($argsArray -join ' ')" }
Write-Pass "Antigravity launch shape correct: -i + --add-dir + --dangerously-skip-permissions (iter-005 T001)"

# Test 7: Antigravity Binary is resolved from the host manifest Binary field.
$antiManifest = Get-HostManifest -Kind antigravity
$expectedAntiBinary = [string]$antiManifest.Binary
$actualAntiBinary = [System.IO.Path]::GetFileNameWithoutExtension([string]$invocation.Binary)
if ($actualAntiBinary -ne $expectedAntiBinary) {
    Write-Fail "Antigravity Binary should resolve from manifest Binary='$expectedAntiBinary'; got '$($invocation.Binary)'"
}
Write-Pass "Antigravity Binary resolves from manifest Binary field"

# Test 8 (F-050 iter-002): cursor is in the detection matrix as a supported host
$supportedKinds = @(Get-SpecrewHostsByStatus -Status supported)
if ('cursor' -notin $supportedKinds) {
    Write-Fail "Cursor missing from supported-host detection matrix. Got: $($supportedKinds -join ',')"
}
Write-Pass "Cursor is in the supported-host detection matrix (F-050 iter-002)"

# Test 9 (F-050 iter-002): cursor launch shape — INTERACTIVE "<prompt>" --workspace; --force under AllowAll;
# NOT --print (headless-only) and NOT --trust (headless-only)
$cursorInv = Invoke-HostHandler -Kind cursor -ContractFunction NewLaunchInvocation -Arguments @{
    ProjectPath = 'C:\test\proj'
    Prompt      = 'test prompt'
    Agent       = 'Squad'
    AllowAll    = $true
}
$cursorArgs = @($cursorInv.Args)
if ('--workspace' -notin $cursorArgs) { Write-Fail "Cursor launch missing --workspace. Args: $($cursorArgs -join ' ')" }
if ('test prompt' -notin $cursorArgs) { Write-Fail "Cursor launch missing positional prompt. Args: $($cursorArgs -join ' ')" }
if ('--print' -in $cursorArgs) { Write-Fail "Cursor launch must be INTERACTIVE, not --print/headless. Args: $($cursorArgs -join ' ')" }
if ('--trust' -in $cursorArgs) { Write-Fail "Cursor launch should NOT include --trust (headless-only). Args: $($cursorArgs -join ' ')" }
if ('--force' -notin $cursorArgs) { Write-Fail "Cursor AllowAll=true should add --force. Args: $($cursorArgs -join ' ')" }
if ($cursorInv.Binary -notmatch 'cursor-agent') { Write-Fail "Cursor Binary should resolve to cursor-agent; got '$($cursorInv.Binary)'" }
Write-Pass "Cursor launch shape correct: interactive prompt + --workspace + --force (no --print/--trust); Binary=cursor-agent (F-050 iter-002)"

Write-Host "`nHost detection UX: all assertions pass" -ForegroundColor Green
