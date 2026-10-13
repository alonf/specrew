# Feature 202 T002 (plan risk "Twin copies"): the hook dispatcher and the bootstrap, handover and refocus
# providers (and the hook deployer) exist as two byte-identical copies - the module source under
# scripts/internal/ and the extension copy under extensions/specrew-speckit/scripts/ that `specify extension add`
# deploys into projects. A fix applied to one copy only ships to half the installs. This test fails on any
# byte of drift, and proves it can: a one-byte mutation of a real twin must be reported.
#
# Mutation that turns this file red: edit either copy of any pair below without the other.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$twins = @(
    'specrew-hook-dispatcher.ps1',
    'specrew-bootstrap-provider.ps1',
    'specrew-handover-provider.ps1',
    'refocus.ps1',
    'deploy-refocus-hooks.ps1'
)

function Get-TwinDrift {
    # $null when the two files are byte-identical; otherwise the first differing byte offset and both lengths.
    param([string]$Left, [string]$Right)
    $a = [IO.File]::ReadAllBytes($Left)
    $b = [IO.File]::ReadAllBytes($Right)
    $limit = [Math]::Min($a.Length, $b.Length)
    for ($i = 0; $i -lt $limit; $i++) {
        if ($a[$i] -ne $b[$i]) { return [pscustomobject]@{ Offset = $i; LeftLength = $a.Length; RightLength = $b.Length } }
    }
    if ($a.Length -ne $b.Length) { return [pscustomobject]@{ Offset = $limit; LeftLength = $a.Length; RightLength = $b.Length } }
    return $null
}

foreach ($leaf in $twins) {
    $source = Join-Path $repoRoot "scripts\internal\$leaf"
    $extension = Join-Path $repoRoot "extensions\specrew-speckit\scripts\$leaf"
    Assert-True ((Test-Path -LiteralPath $source -PathType Leaf) -and (Test-Path -LiteralPath $extension -PathType Leaf)) "$leaf exists in both copies"
    $drift = Get-TwinDrift -Left $source -Right $extension
    Assert-True ($null -eq $drift) $(if ($null -eq $drift) { "$leaf is byte-identical in both copies" } else { "$leaf drifted at byte $($drift.Offset) (lengths $($drift.LeftLength) / $($drift.RightLength))" })
}

# The check can fail: flip one byte of a real twin in a temp copy and it must be reported.
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('twin-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $original = Join-Path $repoRoot 'scripts\internal\specrew-hook-dispatcher.ps1'
    $mutant = Join-Path $tmp 'specrew-hook-dispatcher.ps1'
    $bytes = [IO.File]::ReadAllBytes($original)
    $offset = [int]($bytes.Length / 2)
    $bytes[$offset] = [byte]($bytes[$offset] -bxor 0x01)
    [IO.File]::WriteAllBytes($mutant, $bytes)
    $drift = Get-TwinDrift -Left $original -Right $mutant
    Assert-True ($null -ne $drift -and $drift.Offset -eq $offset) 'a one-byte twin drift is reported at the exact offset'
    [IO.File]::WriteAllBytes($mutant, ([IO.File]::ReadAllBytes($original) + [byte]0x0A))
    Assert-True ($null -ne (Get-TwinDrift -Left $original -Right $mutant)) 'a twin that only gained a trailing byte is reported'
}
finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }

if ($script:failCount -gt 0) { Write-Host "twin-copy-parity: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'twin-copy-parity: all passed' -ForegroundColor Green
