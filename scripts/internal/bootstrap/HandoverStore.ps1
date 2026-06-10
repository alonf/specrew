<#
.SYNOPSIS
  Read/write the Proposal 130 session handover (schema:v1) and its index.
.DESCRIPTION
  Resource accessor (IDesign). COMPOSES Proposal 130's already-specified handover schema - it does
  NOT re-author it. F-174 is Proposal 130's first implementation; the authoritative spec is
  proposals/130-specrew-switch-to-host-handover.md (Pillar 2 body + Pillar 4a SessionEnd path).
  Do not diverge from 130:
    - frontmatter `schema: v1` + source / from_host / recorded_at / from_commit / active_feature /
      active_boundary
    - the six Pillar-2 body sections (order fixed by Get-SpecrewHandoverSectionOrder)
  The LIVE write/read path is the Stop-event ROLLING handover (`.specrew/handover/session-handover.md`,
  one always-latest file overwritten in place; see below). The timestamped SessionEnd write/read path
  (`<timestamp>-session-end-...` + an index.yml) is SUPERSEDED and removed (F-174 T041). This accessor
  only does the I/O; reads fail open. Feature 174 (FR-009, FR-010, FR-021).
#>

function Get-SpecrewHandoverSectionOrder {
    # The Proposal 130 Pillar-2 handover body, in order (verbatim section titles).
    return @(
        'What I just did (last 3-5 turns or last boundary work)',
        "Why I'm stopping (the switch trigger)",
        'Open questions / pending clarifications',
        "Agent's working hypothesis / mental model",
        'Recommended next-immediate-step',
        "Context the receiving host needs that artifacts don't carry"
    )
}

function Get-SpecrewHandoverPlaceholderMarker {
    # The body-section placeholder the HOOK writes when the agent has not authored a section for the
    # current boundary. Starts with "(placeholder" so the structural detector recognizes it without an
    # exact-string dependency (F-174 iter-5, failure-mode B).
    [OutputType([string])]
    param([Parameter()][AllowNull()][string] $Boundary)
    $b = if ([string]::IsNullOrWhiteSpace($Boundary)) { 'this boundary' } else { $Boundary }
    return ("(placeholder - the agent has not authored this section for {0} yet; the next session falls back to the artifact-derived orientation)" -f $b)
}

function Test-SpecrewHandoverSectionAuthored {
    # PURE: is a body section rich AGENT content vs a hook placeholder? Structural (no exact-marker
    # dependency): empty/whitespace, the iter-5 "(placeholder ..." marker, and the legacy
    # "(no relevant content)" all count as NOT authored. F-174 iter-5.
    [OutputType([bool])]
    param([Parameter()][AllowNull()][string] $Content)
    if ([string]::IsNullOrWhiteSpace($Content)) { return $false }
    $t = $Content.Trim()
    if ($t -like '(placeholder*') { return $false }
    if ($t -ieq '(no relevant content)') { return $false }
    return $true
}

function ConvertFrom-SpecrewHandoverFile {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $Path)
    try { $lines = @(Get-Content -LiteralPath $Path -ErrorAction Stop) } catch { return $null }
    $fm = @{}
    $bodyStart = 0
    if ($lines.Count -gt 0 -and $lines[0].Trim() -eq '---') {
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq '---') { $bodyStart = $i + 1; break }
            $kv = $lines[$i] -split ':\s*', 2
            if ($kv.Count -eq 2) { $fm[$kv[0].Trim()] = $kv[1].Trim() }
        }
    }
    # Parse the Pillar-2 body sections (## <title> ... until the next ## or EOF). F-174 iter-5: the body
    # is read back so consumers surface the rich agent-authored content + the detector can flag a
    # placeholder. The H1 (# Session Handover ...) is skipped (single #; the regex requires exactly ##).
    $sections = [ordered]@{}
    $curTitle = $null
    $curLines = New-Object System.Collections.Generic.List[string]
    for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^##\s+(.*\S)\s*$') {
            if ($null -ne $curTitle) { $sections[$curTitle] = (($curLines -join "`n").Trim()) }
            $curTitle = $Matches[1].Trim()
            $curLines = New-Object System.Collections.Generic.List[string]
        }
        elseif ($null -ne $curTitle) { $curLines.Add($line) | Out-Null }
    }
    if ($null -ne $curTitle) { $sections[$curTitle] = (($curLines -join "`n").Trim()) }

    [pscustomobject]@{
        schema          = $fm['schema']; source = $fm['source']; from_host = $fm['from_host']
        recorded_at     = $fm['recorded_at']; active_feature = $fm['active_feature']
        active_boundary = $fm['active_boundary']; sections = $sections
    }
}

# --- F-174 iteration 4: Stop-event ROLLING handover (supersedes the timestamped SessionEnd model) ---

function Get-SpecrewRollingHandoverPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $HandoverDir)
    return (Join-Path $HandoverDir 'session-handover.md')
}

function Write-SpecrewRollingHandoverContent {
    # Shared writer (F-174 iter-5 floor/body split): frontmatter FLOOR + the 6 Pillar-2 body sections
    # from $Sections (a missing/blank section -> the placeholder marker). Used by BOTH the hook
    # floor-writer (Write-SpecrewRollingHandover) and the agent body-author (Write-SpecrewHandoverContext).
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $Source,
        [Parameter(Mandatory)][string] $FromHost,
        [Parameter(Mandatory)][string] $RecordedAt,
        [Parameter()][string] $FromCommit,
        [Parameter()][string] $ActiveFeature,
        [Parameter()][string] $ActiveBoundary,
        [Parameter()][System.Collections.IDictionary] $Sections = @{}
    )
    $marker = Get-SpecrewHandoverPlaceholderMarker -Boundary $ActiveBoundary
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($l in @(
            '---', 'schema: v1', "source: $Source", "from_host: $FromHost", "recorded_at: $RecordedAt",
            "from_commit: $FromCommit", "active_feature: $ActiveFeature", "active_boundary: $ActiveBoundary",
            '---', '', '# Session Handover (rolling)', '')) { $out.Add($l) | Out-Null }
    foreach ($title in (Get-SpecrewHandoverSectionOrder)) {
        $content = if ($Sections.Contains($title) -and -not [string]::IsNullOrWhiteSpace([string]$Sections[$title])) {
            [string]$Sections[$title]
        }
        else { $marker }
        $out.Add("## $title") | Out-Null; $out.Add('') | Out-Null
        $out.Add($content) | Out-Null; $out.Add('') | Out-Null
    }
    # Crash-safe replace (F-174 T050, maintainer finding): a kill landing mid-write (or between an agent's
    # delete+recreate) must never lose the handover. Write the full content to a sidecar, then promote it
    # ATOMICALLY, keeping the previous version as session-handover.md.old ([IO.File]::Replace = Win32
    # ReplaceFile - swap + backup in one atomic call). A crash mid-write leaves the intact current file; a
    # crash between write and promote leaves current + a complete .new; after promote, .old is the backup the
    # reader falls back to. Fallback to plain Set-Content only if the atomic path fails (exotic FS).
    $newPath = "$Path.new"
    Set-Content -LiteralPath $newPath -Value ($out -join "`n") -Encoding UTF8
    try {
        if (Test-Path -LiteralPath $Path) {
            [System.IO.File]::Replace($newPath, $Path, "$Path.old")
        }
        else {
            Move-Item -LiteralPath $newPath -Destination $Path -Force
        }
    }
    catch {
        try {
            Set-Content -LiteralPath $Path -Value ($out -join "`n") -Encoding UTF8
            Remove-Item -LiteralPath $newPath -Force -ErrorAction SilentlyContinue
        }
        catch { $null = $_ }
    }
    return $Path
}

function Write-SpecrewRollingHandover {
    # The HOOK floor-writer (F-174 iter-5). Refreshes the frontmatter FLOOR on each material Stop and
    # PRESERVES the agent-authored body WHEN it exists FOR THE CURRENT boundary; otherwise writes the
    # placeholder body (so a boundary-cross without authoring yields a DETECTABLE hollow body, not stale
    # content). The agent authors the rich body via Write-SpecrewHandoverContext. ONE local, gitignored,
    # always-latest file, overwritten in place. Returns the path. (supersedes the iter-4 direct-write)
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string] $HandoverDir,
        [Parameter(Mandatory)][string] $Source,          # the host stop event: stop | agentStop | Stop
        [Parameter(Mandatory)][string] $FromHost,
        [Parameter(Mandatory)][string] $RecordedAt,       # ISO-8601 (caller-supplied; deterministic)
        [Parameter()][string] $FromCommit,
        [Parameter()][string] $ActiveFeature,
        [Parameter()][string] $ActiveBoundary
    )
    if (-not (Test-Path -LiteralPath $HandoverDir)) { New-Item -ItemType Directory -Path $HandoverDir -Force | Out-Null }
    $path = Get-SpecrewRollingHandoverPath -HandoverDir $HandoverDir

    # Preserve the existing body ONLY when it was authored AND for the current boundary; else placeholder
    # (an empty $bodySections lets the shared writer fill every section with the placeholder marker).
    $bodySections = @{}
    if ((Test-Path -LiteralPath $path) -or (Test-Path -LiteralPath "$path.old")) {
        # Same .old crash-fallback as the reader: preserve an authored body even when the live file was lost.
        $existing = if (Test-Path -LiteralPath $path) { ConvertFrom-SpecrewHandoverFile -Path $path } else { $null }
        if ($null -eq $existing) { $existing = ConvertFrom-SpecrewHandoverFile -Path "$path.old" }
        if ($null -ne $existing -and $existing.sections -and $existing.sections.Count -gt 0) {
            $sameBoundary = (([string]$existing.active_boundary) -eq ([string]$ActiveBoundary))
            $authored = $false
            foreach ($k in $existing.sections.Keys) {
                if (Test-SpecrewHandoverSectionAuthored -Content ([string]$existing.sections[$k])) { $authored = $true; break }
            }
            if ($authored -and $sameBoundary) {
                foreach ($k in $existing.sections.Keys) { $bodySections[$k] = [string]$existing.sections[$k] }
            }
        }
    }

    return (Write-SpecrewRollingHandoverContent -Path $path -Source $Source -FromHost $FromHost -RecordedAt $RecordedAt `
            -FromCommit $FromCommit -ActiveFeature $ActiveFeature -ActiveBoundary $ActiveBoundary -Sections $bodySections)
}

function Write-SpecrewHandoverContext {
    # The AGENT body-author (F-174 iter-5, failure-mode B). The agent persists its rich re-entry/boundary
    # packet AS the handover body, then renders the packet FROM the file - so what the human sees at the
    # boundary == what the next session inherits (the render==persist integrity property). Writes the
    # floor + the agent's rich sections via the shared writer. Returns the path.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string] $HandoverDir,
        [Parameter(Mandatory)][string] $FromHost,
        [Parameter(Mandatory)][string] $RecordedAt,       # ISO-8601 (caller-supplied; deterministic)
        [Parameter()][string] $Source = 'agent',
        [Parameter()][string] $FromCommit,
        [Parameter()][string] $ActiveFeature,
        [Parameter()][string] $ActiveBoundary,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Sections   # the agent's rich 6-section content
    )
    if (-not (Test-Path -LiteralPath $HandoverDir)) { New-Item -ItemType Directory -Path $HandoverDir -Force | Out-Null }
    $path = Get-SpecrewRollingHandoverPath -HandoverDir $HandoverDir
    return (Write-SpecrewRollingHandoverContent -Path $path -Source $Source -FromHost $FromHost -RecordedAt $RecordedAt `
            -FromCommit $FromCommit -ActiveFeature $ActiveFeature -ActiveBoundary $ActiveBoundary -Sections $Sections)
}

function Get-SpecrewRollingHandover {
    # Read the single rolling handover (session-handover.md) with a `fresh` flag. Fail open.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $HandoverDir,
        [Parameter(Mandatory)][string] $NowUtc,
        [Parameter()][int] $FreshnessHours = 24
    )
    $path = Get-SpecrewRollingHandoverPath -HandoverDir $HandoverDir
    # Crash-recovery fallback (F-174 T050): if the live file is missing or unparseable (a kill landed inside
    # an agent's delete+recreate window, or mid-write), fall back to the .old backup the atomic writer keeps.
    # One version stale beats nothing - the resume rides it plus the in-flight disk scan.
    $parsed = $null
    if (Test-Path -LiteralPath $path) { $parsed = ConvertFrom-SpecrewHandoverFile -Path $path }
    if ($null -eq $parsed -and (Test-Path -LiteralPath "$path.old")) {
        $parsed = ConvertFrom-SpecrewHandoverFile -Path "$path.old"
    }
    if ($null -eq $parsed) { return $null }
    $fresh = $false
    try {
        $rec = [datetime]::Parse($parsed.recorded_at).ToUniversalTime()
        $now = [datetime]::Parse($NowUtc).ToUniversalTime()
        $age = ($now - $rec).TotalHours
        $fresh = ($age -ge 0 -and $age -le $FreshnessHours)
    }
    catch { $fresh = $false }
    $parsed | Add-Member -NotePropertyName fresh -NotePropertyValue $fresh -Force
    $parsed | Add-Member -NotePropertyName path -NotePropertyValue $path -Force
    return $parsed
}
