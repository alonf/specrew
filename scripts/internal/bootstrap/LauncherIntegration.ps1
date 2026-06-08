<#
.SYNOPSIS
  Launcher <-> hook dedupe: at most one bootstrap surface per session.
.DESCRIPTION
  Adapter (IDesign, volatile). `specrew start` remains a retained launcher (FR-006); when it ran,
  it wrote `.specrew/last-start-prompt.md` with a recent `session_state_recorded_at`. The
  SessionStart hook bootstrap provider checks this: if the launcher bootstrapped within the dedupe
  window, the hook stays SILENT, so a launcher-then-hook startup yields exactly one bootstrap
  (FR-007, SC-002). No lock semantics - a freshness window, not a stuck flag. Feature 174.
#>

function Get-SpecrewLastStartRecordedAt {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $ProjectRoot)
    $path = Join-Path $ProjectRoot '.specrew/last-start-prompt.md'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try { $lines = @(Get-Content -LiteralPath $path -ErrorAction Stop) } catch { return $null }
    $inFrontmatter = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($i -eq 0 -and $line.Trim() -eq '---') { $inFrontmatter = $true; continue }
        if ($inFrontmatter -and $line.Trim() -eq '---') { break }
        if ($inFrontmatter -and $line -match '^\s*session_state_recorded_at:\s*(.+?)\s*$') {
            return $matches[1].Trim()
        }
    }
    return $null
}

function Test-SpecrewLauncherBootstrapRecent {
    # True when `specrew start` bootstrapped within the dedupe window -> the hook must stay silent.
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $NowUtc,           # ISO-8601 (deterministic for tests; Get-Date live)
        [Parameter()][int] $WindowSeconds = 120
    )
    $rec = Get-SpecrewLastStartRecordedAt -ProjectRoot $ProjectRoot
    if ([string]::IsNullOrWhiteSpace($rec)) { return $false }
    try {
        $r = [datetime]::Parse($rec).ToUniversalTime()
        $n = [datetime]::Parse($NowUtc).ToUniversalTime()
        $age = ($n - $r).TotalSeconds
        return ($age -ge 0 -and $age -le $WindowSeconds)
    }
    catch { return $false }
}
