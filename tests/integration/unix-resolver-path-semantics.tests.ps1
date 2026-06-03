[CmdletBinding()]
param()

# Feature 160 (Proposal 160) — Unix resolver path-semantics probe.
#
# Suspected issue: the boundary-sync wrapper resolver builds candidate paths with
# hardcoded backslash separators ('scripts\internal\sync-boundary-state.ps1',
# '.specrew\config.yml'), hypothesized to make Path 0/1/2 unable to match on
# Linux/macOS.
#
# REAL-HOST REFINEMENT (Ubuntu CI, 2026-06-03): the first real-Linux execution of
# this probe REFUTED the runtime half of that hypothesis — PowerShell provider
# cmdlets (Join-Path/Test-Path, which the wrapper uses) normalize '\' to '/' on
# POSIX, so the wrapper resolves even with the old construction. What remains
# true and proven: (a) at the STRING level '\' is not a POSIX separator, and
# (b) raw .NET IO APIs do NOT normalize — so embedded-backslash paths are a real
# hazard in non-provider contexts. The applied multi-segment Join-Path fix is
# platform-hygiene hardening, not the repair of a reproduced runtime failure.
#
# This probe is REPRO-FIRST (FR-001/FR-002): the SEMANTIC and BEHAVIORAL sections
# document the platform interpretation per layer; the SOURCE REGRESSION section
# asserts the live resolver uses separator-safe construction (FAILED pre-fix).
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
            "Windows: embedded-backslash candidate resolves ('\' is the native separator)"
    }
    else {
        # REAL-HOST REFINEMENT (Ubuntu CI run 26907556536, 2026-06-03): PowerShell
        # PROVIDER cmdlets (Join-Path / Test-Path) normalize '\' to '/' on POSIX,
        # so the embedded-backslash candidate RESOLVES at the provider layer —
        # refuting the original hypothesis that the wrapper's Test-Path probes
        # could never match on Unix. The residual portability hazard is limited to
        # NON-provider contexts: raw .NET IO APIs, string comparisons/splits, and
        # paths handed to native commands.
        Write-Info ("POSIX buggy candidate string: '{0}' (string still contains backslash: {1})" -f $buggyCandidate, $buggyCandidate.Contains([char]92))
        Assert-True ($buggyResolves -eq $true) `
            "POSIX: provider cmdlets NORMALIZE the embedded-backslash candidate (resolves at runtime; original never-matches hypothesis refuted on a real host)"

        # The hazard that DOES survive on POSIX: the raw .NET IO layer treats the
        # embedded backslash as a literal filename character. Build the candidate
        # by plain string interpolation (no provider involvement) to prove it.
        $rawCandidate = "$scratch/$buggyChildPath"
        Assert-True (-not [System.IO.File]::Exists($rawCandidate)) `
            "POSIX: raw .NET [IO.File]::Exists does NOT resolve the embedded-backslash path (the residual non-provider hazard class)"
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
