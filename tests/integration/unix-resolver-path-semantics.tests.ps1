[CmdletBinding()]
param()

# Feature 160 (Proposal 160) — Unix resolver path-semantics probe.
#
# Suspected issue: the boundary-sync wrapper resolver builds candidate paths with
# hardcoded backslash separators ('scripts\internal\sync-boundary-state.ps1',
# '.specrew\config.yml'). On Windows '\' is the path separator so this works; on
# Unix PowerShell does NOT rewrite an embedded '\', so the candidate becomes a
# single literal filename containing backslashes and Test-Path returns $false —
# Path 0/1/2 of the resolver can never match on Linux/macOS.
#
# This probe is REPRO-FIRST (FR-001/FR-002): the SEMANTIC and BEHAVIORAL sections
# document the interpretation and pass on every platform; the SOURCE REGRESSION
# section asserts the live resolver uses separator-safe construction. That section
# FAILS before the fix (bug present) and PASSES after (FR-003/FR-004).
#
# Runs identically on Windows, Linux, and macOS PowerShell (Proposal 160 AC4).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "INFO: $Message" -ForegroundColor Cyan }

$script:Failures = New-Object System.Collections.Generic.List[string]
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Pass $Message } else { $script:Failures.Add($Message) | Out-Null; Write-Host "FAIL: $Message" -ForegroundColor Red }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$isWindowsHost = ($null -ne ([System.Char]([System.IO.Path]::DirectorySeparatorChar))) -and ([System.IO.Path]::DirectorySeparatorChar -eq '\')
Write-Info ("Host DirectorySeparatorChar = '{0}' (treated as {1})" -f [System.IO.Path]::DirectorySeparatorChar, ($(if ($isWindowsHost) { 'Windows' } else { 'POSIX' })))

# The exact relative segment the resolver embeds.
$buggyChildPath = 'scripts\internal\sync-boundary-state.ps1'
$buggyConfigChildPath = '.specrew\config.yml'

# ----------------------------------------------------------------------------
# Section 1 — SEMANTIC proof (host-independent): an embedded-backslash ChildPath
# is a single path segment under POSIX '/' separation, and a multi-segment path
# only under Windows '\' separation. This holds on every platform.
# ----------------------------------------------------------------------------
Assert-True (($buggyChildPath -split '/').Count -eq 1) `
    "POSIX semantics: '$buggyChildPath' is ONE literal segment when '/' is the separator (no nested resolution)"
Assert-True (($buggyChildPath -split '\\').Count -eq 3) `
    "Windows semantics: '$buggyChildPath' is 3 segments when '\' is the separator"
Assert-True ($buggyChildPath.Contains([char]92) -and -not $buggyChildPath.Contains('/')) `
    "Embedded-backslash ChildPath carries only '\' separators, which POSIX does not interpret"

# ----------------------------------------------------------------------------
# Section 2 — BEHAVIORAL repro with REAL files. The separator-safe (FIX) form
# resolves on every platform; the embedded-backslash (BUGGY) form resolves only
# where '\' is the platform separator (Windows). On POSIX it fails — the bug.
# ----------------------------------------------------------------------------
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-resolver-probe-" + [System.Guid]::NewGuid().ToString('N'))
try {
    $nestedDir = Join-Path $scratch 'scripts' 'internal'   # multi-segment Join-Path (separator-safe)
    New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null
    $realLeaf = Join-Path $nestedDir 'sync-boundary-state.ps1'
    Set-Content -LiteralPath $realLeaf -Value '# probe target' -Encoding UTF8

    # FIX form: multi-segment Join-Path. Must resolve on Windows AND Unix.
    $fixedCandidate = Join-Path $scratch 'scripts' 'internal' 'sync-boundary-state.ps1'
    Assert-True (Test-Path -LiteralPath $fixedCandidate -PathType Leaf) `
        "Separator-safe multi-segment Join-Path resolves the real nested file on this host (FR-003 shape)"

    # BUGGY form: single embedded-backslash ChildPath.
    $buggyCandidate = Join-Path $scratch $buggyChildPath
    $buggyResolves = Test-Path -LiteralPath $buggyCandidate -PathType Leaf
    if ($isWindowsHost) {
        Assert-True ($buggyResolves -eq $true) `
            "Windows: embedded-backslash candidate resolves (bug is LATENT on Windows — why it went unnoticed)"
    }
    else {
        Assert-True ($buggyResolves -eq $false) `
            "POSIX: embedded-backslash candidate does NOT resolve (CONFIRMS the resolver bug on Unix)"
    }
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
}

# ----------------------------------------------------------------------------
# Section 3 — SOURCE REGRESSION (the fix gate). The live resolver (source +
# deployed .specify mirror) must use separator-safe candidate construction. This
# FAILS before the fix (embedded-backslash literals present) and PASSES after.
# ----------------------------------------------------------------------------
$resolverFiles = @(
    (Join-Path $repoRoot 'extensions' 'specrew-speckit' 'scripts' 'sync-boundary-state.ps1'),
    (Join-Path $repoRoot '.specify' 'extensions' 'specrew-speckit' 'scripts' 'sync-boundary-state.ps1')
)
foreach ($resolverFile in $resolverFiles) {
    if (-not (Test-Path -LiteralPath $resolverFile -PathType Leaf)) {
        Write-Info "resolver file not present (mirror may be optional): $resolverFile"
        continue
    }
    $src = Get-Content -LiteralPath $resolverFile -Raw -Encoding UTF8
    $rel = $resolverFile.Substring($repoRoot.Length).TrimStart('\','/')
    Assert-True (-not $src.Contains($buggyChildPath)) `
        "$rel does not embed '$buggyChildPath' as a single backslash ChildPath (separator-safe)"
    Assert-True (-not $src.Contains($buggyConfigChildPath)) `
        "$rel does not embed '$buggyConfigChildPath' as a single backslash ChildPath (separator-safe)"
}

# ----------------------------------------------------------------------------
if ($script:Failures.Count -gt 0) {
    Write-Host ("`n{0} assertion(s) failed:" -f $script:Failures.Count) -ForegroundColor Red
    foreach ($f in $script:Failures) { Write-Host "  - $f" -ForegroundColor Red }
    exit 1
}
Write-Host "`nunix-resolver-path-semantics: all assertions pass" -ForegroundColor Green
