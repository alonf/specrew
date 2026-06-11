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

function Get-SpecrewHandoverAgentOwnedSections {
    # F-174 iter-9: the INTERPRETIVE sections only the agent can author (via Write-SpecrewHandoverContext);
    # the hook never writes interpretive content, so a non-placeholder interpretive section IS the agent
    # provenance (no schema field needed). The hook PRESERVES these across stops within a boundary.
    return @(
        'Open questions / pending clarifications',
        "Agent's working hypothesis / mental model"
    )
}

function Get-SpecrewHandoverMechanicalSections {
    # F-174 iter-9: the HOOK-owned sections - refreshed every material stop from the git/fs session delta
    # (they describe "now"). Derived as the complement of the agent-owned set within the fixed order, so a
    # title rename in Get-SpecrewHandoverSectionOrder cannot silently desync the two lists.
    $agent = Get-SpecrewHandoverAgentOwnedSections
    return @(Get-SpecrewHandoverSectionOrder | Where-Object { $agent -notcontains $_ })
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
        recorded_at     = $fm['recorded_at']; from_commit = $fm['from_commit']
        active_feature  = $fm['active_feature']
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
        [Parameter()][string] $ActiveBoundary,
        # F-174 iter-9 (hook-primary): the hook passes the freshly-computed MECHANICAL section content (the
        # git/fs session delta) here as title -> content. Mechanical sections are HOOK-OWNED and written
        # fresh every material stop; a missing/blank mechanical title falls to the placeholder marker (the
        # truly-empty / git-unavailable case). Interpretive sections stay AGENT-owned (preserved below).
        [Parameter()][System.Collections.IDictionary] $MechanicalSections = @{}
    )
    if (-not (Test-Path -LiteralPath $HandoverDir)) { New-Item -ItemType Directory -Path $HandoverDir -Force | Out-Null }
    $path = Get-SpecrewRollingHandoverPath -HandoverDir $HandoverDir

    # F-174 iter-9 SECTION OWNERSHIP (supersedes the iter-5 all-or-nothing preserve). Merge the body by
    # ownership so it is NEVER hollow as long as the hook captured a delta, while an agent overlay survives:
    #   - MECHANICAL (What I just did / Why I'm stopping / Recommended next / Context): written FRESH from
    #     $MechanicalSections every stop - they describe "now", so the hook owns them.
    #   - INTERPRETIVE (Open questions / Working hypothesis): AGENT-owned - preserve the EXISTING content iff
    #     it is authored (non-placeholder) AND for the CURRENT boundary; else leave it to the placeholder
    #     marker. The hook never writes interpretive content, so non-placeholder == the agent authored it
    #     (the placeholder state IS the provenance; no schema field needed). A boundary change resets them.
    $bodySections = @{}
    foreach ($mt in (Get-SpecrewHandoverMechanicalSections)) {
        if ($MechanicalSections.Contains($mt) -and -not [string]::IsNullOrWhiteSpace([string]$MechanicalSections[$mt])) {
            $bodySections[$mt] = [string]$MechanicalSections[$mt]
        }
    }
    if ((Test-Path -LiteralPath $path) -or (Test-Path -LiteralPath "$path.old")) {
        # Same .old crash-fallback as the reader: keep an agent overlay even if the live file was lost mid-write.
        $existing = if (Test-Path -LiteralPath $path) { ConvertFrom-SpecrewHandoverFile -Path $path } else { $null }
        if ($null -eq $existing) { $existing = ConvertFrom-SpecrewHandoverFile -Path "$path.old" }
        if ($null -ne $existing -and $existing.sections -and $existing.sections.Count -gt 0 -and
            (([string]$existing.active_boundary) -eq ([string]$ActiveBoundary))) {
            foreach ($it in (Get-SpecrewHandoverAgentOwnedSections)) {
                if ($existing.sections.Contains($it) -and (Test-SpecrewHandoverSectionAuthored -Content ([string]$existing.sections[$it]))) {
                    $bodySections[$it] = [string]$existing.sections[$it]
                }
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

function Update-SpecrewRollingHandover {
    # F-174 iter-9.1: THE single handover-save orchestration. Every trigger source - the Stop hook, the
    # PostToolUse hook, and the design-workshop skill - calls THIS; none re-implement the save. It resolves
    # the current feature/boundary/host from committed session state (+ the branch fallback for the
    # anchorless workshop window), runs the material-change gate (so it is cheap to call on EVERY tool call),
    # computes the git/fs delta, authors the MECHANICAL sections (accumulating "What I just did" newest-first
    # across the boundary window, reset on a boundary change), writes via the atomic writer, and records a
    # true-empty hollow. Composes ClassificationEngine (Test-SpecrewHandoverMaterialChange) +
    # ProjectMetadataAccessor (Resolve-SpecrewBranchFeatureRef, Get-SpecrewSessionDelta) - all co-loaded by
    # the caller. Returns a result object; callers stay fail-open. (F-174 iter-9.1.)
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter()][AllowNull()][string] $HostKind,                 # authoritative current host (--host-kind); else resolved
        [Parameter()][string] $Source = 'stop',                       # trigger label: stop | agentStop | PostToolUse | workshop
        [Parameter()][string] $NowUtc = ((Get-Date).ToUniversalTime().ToString('o'))
    )

    $getProp = {
        param($o, $n)
        if ($null -eq $o) { return $null }
        $p = $o.PSObject.Properties[$n]
        if ($p) { return $p.Value } else { return $null }
    }

    # Current context from the committed session state (the orchestrator is transcript-blind by design).
    $feature = $null; $boundary = $null; $fromHost = 'host'
    $ctxPath = Join-Path $ProjectRoot '.specrew/start-context.json'
    if (Test-Path -LiteralPath $ctxPath) {
        try {
            $ctx = Get-Content -LiteralPath $ctxPath -Raw | ConvertFrom-Json
            $ss = & $getProp $ctx 'session_state'
            $feature = & $getProp $ss 'feature_ref'
            $boundary = & $getProp $ss 'boundary_type'
            $h = & $getProp $ss 'host'; if ([string]::IsNullOrWhiteSpace($h)) { $h = & $getProp $ctx 'host' }
            if (-not [string]::IsNullOrWhiteSpace($h)) { $fromHost = [string]$h }
        }
        catch { $null = $_ }
    }
    # Anchorless workshop window: resolve the feature from the branch so the handover is surfaceable (T050).
    if ([string]::IsNullOrWhiteSpace([string]$feature)) { $feature = Resolve-SpecrewBranchFeatureRef -ProjectRoot $ProjectRoot }
    # The trigger passes the authoritative host; prefer it over the start-context value or the 'host' default.
    if (-not [string]::IsNullOrWhiteSpace($HostKind)) { $fromHost = $HostKind }

    $handoverDir = Join-Path $ProjectRoot '.specrew/handover'

    # Material-change gate (the call-cheapness guarantee - PostToolUse fires on every tool call): refresh only
    # when the boundary moved OR there is a tracked-file change since the last write.
    $existing = Get-SpecrewRollingHandover -HandoverDir $handoverDir -NowUtc $NowUtc
    $lastBoundary = if ($null -ne $existing) { $existing.active_boundary } else { $null }
    $hasChange = $false
    try { $st = (& git -C $ProjectRoot status --porcelain 2>$null); $hasChange = -not [string]::IsNullOrWhiteSpace(($st -join "`n")) } catch { $null = $_ }
    $mc = Test-SpecrewHandoverMaterialChange -CurrentBoundary $boundary -LastBoundary $lastBoundary -HasTrackedChange $hasChange -HandoverExists ($null -ne $existing)
    if (-not $mc.material) { return [pscustomobject]@{ wrote = $false; reason = $mc.reason; source = $Source; feature = $feature; boundary = $boundary } }

    $head = ''
    try { $head = ([string](& git -C $ProjectRoot rev-parse --short HEAD 2>$null)).Trim() } catch { $null = $_ }
    $sinceCommit = if ($null -ne $existing) { [string]$existing.from_commit } else { $null }
    $delta = Get-SpecrewSessionDelta -ProjectRoot $ProjectRoot -SinceCommit $sinceCommit

    $featureLabel = if ([string]::IsNullOrWhiteSpace([string]$feature)) { '(no active feature)' } else { [string]$feature }
    $boundaryLabel = if ([string]::IsNullOrWhiteSpace([string]$boundary)) { '(pre-boundary / workshop)' } else { [string]$boundary }

    # One activity line for THIS refresh, accumulated newest-first across the boundary window.
    $fileNote = if ($delta.has_uncommitted) {
        $shown = (@($delta.uncommitted_files) -join ', ')
        if ($delta.uncommitted_truncated) { $shown = "$shown, +more" }
        " [$shown]"
    }
    else { '' }
    $commitNote = if ($delta.new_commit_count -gt 0) { ("; {0} new commit(s): {1}" -f $delta.new_commit_count, ((@($delta.new_commits)) -join ' | ')) } else { '' }
    $stamp = if ($NowUtc.Length -ge 19) { ($NowUtc.Substring(0, 19) + 'Z') } else { $NowUtc }
    $stopBullet = ("- [{0}] ({1}) {2} uncommitted file(s){3}; HEAD {4} ({5}){6}" -f $stamp, $Source, $delta.uncommitted_count, $fileNote, $delta.head_short, $delta.head_subject, $commitNote)

    $activityTitle = 'What I just did (last 3-5 turns or last boundary work)'
    $priorBullets = @()
    if ($null -ne $existing -and ([string]$existing.active_boundary -eq [string]$boundary) -and $existing.sections -and $existing.sections.Contains($activityTitle)) {
        $prev = [string]$existing.sections[$activityTitle]
        if (-not [string]::IsNullOrWhiteSpace($prev) -and $prev -notlike '(placeholder*') {
            $priorBullets = @($prev -split "`n" | Where-Object { $_ -match '^\s*-\s' })
        }
    }
    $activity = ((@($stopBullet) + $priorBullets) | Select-Object -First 6) -join "`n"

    $whyStopping = ("Hook-captured at trigger '{0}' (the agent did not author a handover this turn). Boundary: {1}. Refresh reason: {2}." -f $Source, $boundaryLabel, $mc.reason)
    $recNext = if ($delta.has_uncommitted) {
        ("Resume feature {0} at boundary {1}. {2} uncommitted file(s) are NOT in git history yet - review/commit them before advancing." -f $featureLabel, $boundaryLabel, $delta.uncommitted_count)
    }
    else {
        ("Resume feature {0} at boundary {1}. Working tree is clean; continue the next lifecycle step." -f $featureLabel, $boundaryLabel)
    }
    $uncommittedNote = if ($delta.has_uncommitted) { (" Uncommitted work NOT yet committed: {0}." -f ((@($delta.uncommitted_files) -join ', '))) } else { '' }
    $context = ("branch {0}, HEAD {1} ({2}). Active feature {3}, boundary {4}.{5}" -f $delta.branch, $delta.head_short, $delta.head_subject, $featureLabel, $boundaryLabel, $uncommittedNote)

    $mechanical = @{
        $activityTitle                                                = $activity
        "Why I'm stopping (the switch trigger)"                       = $whyStopping
        'Recommended next-immediate-step'                             = $recNext
        "Context the receiving host needs that artifacts don't carry" = $context
    }

    Write-SpecrewRollingHandover -HandoverDir $handoverDir -Source $Source -FromHost $fromHost `
        -RecordedAt $NowUtc -FromCommit $head -ActiveFeature $feature -ActiveBoundary $boundary `
        -MechanicalSections $mechanical | Out-Null

    $mechAuthored = @($mechanical.Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count
    $hollow = ($mechAuthored -eq 0)
    if ($hollow) {
        [Console]::Error.WriteLine(("[specrew-handover] WARN HOLLOW_HANDOVER boundary='{0}' reason='{1}' - the hook captured no session delta (git unavailable?); the next session inherits a hollow handover." -f $boundary, $mc.reason))
        try {
            $jpath = Join-Path $ProjectRoot '.specrew/runtime/handover-journal.jsonl'
            $jdir = Split-Path -Parent $jpath
            if ($jdir -and -not (Test-Path -LiteralPath $jdir)) { New-Item -ItemType Directory -Path $jdir -Force | Out-Null }
            $rec = [pscustomobject]@{ event = 'hollow-handover-at-stop'; recorded_at = $NowUtc; boundary = $boundary; feature = $feature; from_host = $fromHost; material_reason = $mc.reason; source = $Source }
            ($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $jpath -Encoding UTF8
        }
        catch { $null = $_ }
    }

    return [pscustomobject]@{ wrote = $true; reason = $mc.reason; source = $Source; feature = $feature; boundary = $boundary; from_host = $fromHost; hollow = $hollow }
}
