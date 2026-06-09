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
    - SessionEnd path `.specrew/handover/<timestamp>-session-end-<source>-from-<host>.md`
    - index `.specrew/handover/index.yml`
    - the six Pillar-2 body sections (order fixed by Get-SpecrewHandoverSectionOrder)
  Source-discrimination (compact best-effort / clear|exit full / startup|resume minimal) is the
  CALLER's concern (SessionEndHandoverManager); this accessor only does the I/O. Reads fail open.
  Feature 174 (FR-009, FR-010, FR-021).
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

function Write-SpecrewHandover {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string] $HandoverDir,
        [Parameter(Mandatory)][string] $Source,          # startup | resume | clear | compact | exit
        [Parameter(Mandatory)][string] $FromHost,
        [Parameter(Mandatory)][string] $RecordedAt,       # ISO-8601 (caller-supplied; keeps writes deterministic)
        [Parameter()][string] $FromCommit,
        [Parameter()][string] $ActiveFeature,
        [Parameter()][string] $ActiveBoundary,
        [Parameter()][hashtable] $Sections = @{}          # section-title -> content; missing -> "(no relevant content)"
    )

    $stamp = $RecordedAt -replace '[:]', '-'
    $safeHost = $FromHost -replace '[^a-zA-Z0-9-]', '-'
    $safeSource = $Source -replace '[^a-zA-Z0-9-]', '-'
    $fileName = "$stamp-session-end-$safeSource-from-$safeHost.md"
    if (-not (Test-Path -LiteralPath $HandoverDir)) { New-Item -ItemType Directory -Path $HandoverDir -Force | Out-Null }
    $path = Join-Path $HandoverDir $fileName

    $out = New-Object System.Collections.Generic.List[string]
    foreach ($l in @(
            '---', 'schema: v1', "source: $Source", "from_host: $FromHost", "recorded_at: $RecordedAt",
            "from_commit: $FromCommit", "active_feature: $ActiveFeature", "active_boundary: $ActiveBoundary",
            '---', '', '# Session-End Handover', '')) { $out.Add($l) | Out-Null }
    foreach ($title in (Get-SpecrewHandoverSectionOrder)) {
        $content = if ($Sections.ContainsKey($title) -and -not [string]::IsNullOrWhiteSpace([string]$Sections[$title])) {
            [string]$Sections[$title]
        }
        else { '(no relevant content)' }
        $out.Add("## $title") | Out-Null; $out.Add('') | Out-Null
        $out.Add($content) | Out-Null; $out.Add('') | Out-Null
    }
    Set-Content -LiteralPath $path -Value ($out -join "`n") -Encoding UTF8

    $indexPath = Join-Path $HandoverDir 'index.yml'
    if (-not (Test-Path -LiteralPath $indexPath)) { Set-Content -LiteralPath $indexPath -Value 'handovers:' -Encoding UTF8 }
    Add-Content -LiteralPath $indexPath -Encoding UTF8 -Value (@(
            "  - file: $fileName", "    recorded_at: $RecordedAt", "    from_host: $FromHost",
            "    source: $Source", "    active_feature: $ActiveFeature", "    active_boundary: $ActiveBoundary"
        ) -join "`n")

    return $path
}

function ConvertFrom-SpecrewHandoverFile {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $Path)
    try { $lines = @(Get-Content -LiteralPath $Path -ErrorAction Stop) } catch { return $null }
    $fm = @{}
    if ($lines.Count -gt 0 -and $lines[0].Trim() -eq '---') {
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq '---') { break }
            $kv = $lines[$i] -split ':\s*', 2
            if ($kv.Count -eq 2) { $fm[$kv[0].Trim()] = $kv[1].Trim() }
        }
    }
    [pscustomobject]@{
        schema          = $fm['schema']; source = $fm['source']; from_host = $fm['from_host']
        recorded_at     = $fm['recorded_at']; active_feature = $fm['active_feature']
        active_boundary = $fm['active_boundary']
    }
}

function Get-SpecrewHandover {
    # Return the most-recent SessionEnd handover, with a `fresh` flag vs the freshness window.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $HandoverDir,
        [Parameter(Mandatory)][string] $NowUtc,           # ISO-8601 (caller-supplied; deterministic)
        [Parameter()][int] $FreshnessHours = 24
    )
    if (-not (Test-Path -LiteralPath $HandoverDir)) { return $null }
    $files = @(Get-ChildItem -LiteralPath $HandoverDir -Filter '*-session-end-*.md' -File -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending)
    if ($files.Count -eq 0) { return $null }

    $parsed = ConvertFrom-SpecrewHandoverFile -Path $files[0].FullName
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
    $parsed | Add-Member -NotePropertyName path -NotePropertyValue $files[0].FullName -Force
    return $parsed
}

# --- F-174 iteration 4: Stop-event ROLLING handover (supersedes the timestamped SessionEnd model) ---

function Get-SpecrewRollingHandoverPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $HandoverDir)
    return (Join-Path $HandoverDir 'session-handover.md')
}

function Write-SpecrewRollingHandover {
    # ONE local, always-latest handover, OVERWRITTEN in place on each material Stop (no timestamped
    # files, no index, no archive). Reuses the Proposal-130 schema:v1 + 6-section body. The file is
    # LOCAL + gitignored (never pushed). Returns the path. (f174-i004-design-settled)
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string] $HandoverDir,
        [Parameter(Mandatory)][string] $Source,          # the host stop event: stop | agentStop | Stop
        [Parameter(Mandatory)][string] $FromHost,
        [Parameter(Mandatory)][string] $RecordedAt,       # ISO-8601 (caller-supplied; deterministic)
        [Parameter()][string] $FromCommit,
        [Parameter()][string] $ActiveFeature,
        [Parameter()][string] $ActiveBoundary,
        [Parameter()][hashtable] $Sections = @{}
    )
    if (-not (Test-Path -LiteralPath $HandoverDir)) { New-Item -ItemType Directory -Path $HandoverDir -Force | Out-Null }
    $path = Get-SpecrewRollingHandoverPath -HandoverDir $HandoverDir

    $out = New-Object System.Collections.Generic.List[string]
    foreach ($l in @(
            '---', 'schema: v1', "source: $Source", "from_host: $FromHost", "recorded_at: $RecordedAt",
            "from_commit: $FromCommit", "active_feature: $ActiveFeature", "active_boundary: $ActiveBoundary",
            '---', '', '# Session Handover (rolling)', '')) { $out.Add($l) | Out-Null }
    foreach ($title in (Get-SpecrewHandoverSectionOrder)) {
        $content = if ($Sections.ContainsKey($title) -and -not [string]::IsNullOrWhiteSpace([string]$Sections[$title])) {
            [string]$Sections[$title]
        }
        else { '(no relevant content)' }
        $out.Add("## $title") | Out-Null; $out.Add('') | Out-Null
        $out.Add($content) | Out-Null; $out.Add('') | Out-Null
    }
    Set-Content -LiteralPath $path -Value ($out -join "`n") -Encoding UTF8
    return $path
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
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $parsed = ConvertFrom-SpecrewHandoverFile -Path $path
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
