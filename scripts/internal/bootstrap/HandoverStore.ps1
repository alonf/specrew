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
    # The Proposal 130 Pillar-2 handover body, in order (verbatim section titles). F-174 iter-10 (T002,
    # FR-022) appends a 7th HOOK-OWNED section, 'Recent conversation ...', extending 130's fixed-6 with the
    # best-effort transcript tail (recorded as drift D-017 - a 174-authorized additive extension; 174 already
    # evolved this schema in iter-9 with the mechanical/interpretive ownership split). Mechanical by default
    # (it is not in the agent-owned set), so the complement logic includes it automatically.
    return @(
        'What I just did (last 3-5 turns or last boundary work)',
        "Why I'm stopping (the switch trigger)",
        'Open questions / pending clarifications',
        "Agent's working hypothesis / mental model",
        'Recommended next-immediate-step',
        "Context the receiving host needs that artifacts don't carry",
        'Recent conversation (last few exchanges, hook-captured)',
        # F-174 iter-11 (T002, DF-3): the VERBATIM rendered boundary VERDICT packet, captured from the transcript
        # by the Stop hook so a resume inherits the AUTHORED packet (not placeholders). A THIRD ownership category
        # (Get-SpecrewHandoverCapturedSections) - written when the hook captures a marker-bearing packet, PRESERVED
        # otherwise (the clobber guard, T003). It is NEITHER mechanical (it must not be refreshed/placeholdered
        # every stop) NOR agent-owned (the hook writes it, so the "non-placeholder == agent-authored" provenance
        # invariant must NOT include it).
        'Authored boundary packet (captured at stop)'
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

function Get-SpecrewHandoverCapturedSections {
    # F-174 iter-11 (T002, DF-3): the THIRD ownership category - sections the HOOK populates by CAPTURING the
    # agent's actually-rendered boundary packet verbatim from the transcript (not synthesizing it, not the agent
    # calling a function). Excluded from BOTH the agent-owned set (so the "non-placeholder == agent-authored"
    # provenance invariant stays true) AND the mechanical complement (so a generic Stop with no new packet does
    # NOT refresh/placeholder it - the clobber guard preserves the last captured packet within its boundary).
    # NOTE: this returns a single-element list; PowerShell unwraps it to a bare string on return, so EVERY caller
    # must re-wrap with @(...) (or iterate with foreach, which treats a scalar as one item) before indexing [0] or
    # using -contains. All in-tree callers do; do NOT add a leading-comma "fix" - it nests the array and breaks
    # -contains (the element becomes Object[], not the title string).
    return @('Authored boundary packet (captured at stop)')
}

function Get-SpecrewHandoverMechanicalSections {
    # F-174 iter-9: the HOOK-owned sections - refreshed every material stop from the git/fs session delta
    # (they describe "now"). Derived as the complement of the agent-owned set AND the captured set (iter-11 T002)
    # within the fixed order, so a title rename in Get-SpecrewHandoverSectionOrder cannot silently desync the
    # lists, and the captured-packet section can never fall back into the refreshed-every-stop mechanical bucket.
    $reserved = @(Get-SpecrewHandoverAgentOwnedSections) + @(Get-SpecrewHandoverCapturedSections)
    return @(Get-SpecrewHandoverSectionOrder | Where-Object { $reserved -notcontains $_ })
}

function Get-SpecrewHandoverTimeScopedSections {
    # F-174 iter-10: the HOOK-owned sections that are TIME-scoped, not BOUNDARY-scoped - i.e. "recent
    # exchanges", which should carry across a boundary change (cross-session continuity is the whole point of
    # capturing them), unlike the era-scoped narrative mechanicals ("What I just did" / "Context ...") which a
    # boundary change resets. Used by the agent body-author preserve to boundary-gate the narrative mechanicals
    # while keeping the conversation tail. Currently just the conversation section (the only hook-ONLY section
    # the agent never authors). Matched against the canonical title in Get-SpecrewHandoverSectionOrder.
    return @(Get-SpecrewHandoverSectionOrder | Where-Object { $_ -like 'Recent conversation*' })
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
    # F-174 iter-11 (T002, DF-3): the captured-packet section (Get-SpecrewHandoverCapturedSections) embeds the
    # agent's VERBATIM boundary packet, which is itself six '## ' headers (## What I Just Did, ...). A flat '^##'
    # split would shred it on read-back - every inner '## ' starting a bogus section, so the captured section keeps
    # only the (near-empty) text before its first inner header -> Test-SpecrewHandoverSectionAuthored returns false
    # -> placeholder -> the clobber guard AND the resume both break. So once INSIDE a captured section, a '## ' line
    # closes it ONLY when it EXACTLY matches another KNOWN canonical handover title (the packet's own headers like
    # '## What I Just Did' do NOT match the canonical '## What I just did (last 3-5 turns ...)'); otherwise the line
    # is captured-body content. Non-captured sections parse EXACTLY as before (no behavior change off this path).
    $knownTitles = @(Get-SpecrewHandoverSectionOrder)
    $capturedTitles = @(Get-SpecrewHandoverCapturedSections)
    $sections = [ordered]@{}
    $curTitle = $null
    $inCaptured = $false
    $capturedIdx = -1
    $curLines = New-Object System.Collections.Generic.List[string]
    for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^##\s+(.*\S)\s*$') {
            $candidate = $Matches[1].Trim()
            # F-174 iter-11 (review-signoff P2-1) TERMINAL-AWARE captured-section close. Once INSIDE the captured
            # (verbatim boundary packet) section, a '## ' line closes it ONLY if it is a canonical title that sorts
            # AFTER the captured section in Get-SpecrewHandoverSectionOrder. The captured section is the LAST entry,
            # so nothing sorts after it -> the packet's OWN '## ' headers are all swallowed as captured body, even
            # ones that EXACTLY match a canonical handover title (e.g. '## What I just did (last 3-5 turns ...)').
            # The old `-notcontains` guard closed the section on ANY canonical-title collision, shredding the packet
            # to its bare marker (the resume then inherited a useless stub - the exact SC-012/SC-015 failure). This
            # self-corrects if the order ever grows a real section after the captured one.
            if ($inCaptured) {
                $candIdx = [Array]::IndexOf($knownTitles, $candidate)
                if ($candIdx -lt 0 -or $candIdx -le $capturedIdx) { $curLines.Add($line) | Out-Null; continue }
            }
            if ($null -ne $curTitle) { $sections[$curTitle] = (($curLines -join "`n").Trim()) }
            $curTitle = $candidate
            $inCaptured = ($capturedTitles -contains $candidate)
            $capturedIdx = if ($inCaptured) { [Array]::IndexOf($knownTitles, $candidate) } else { -1 }
            $curLines = New-Object System.Collections.Generic.List[string]
        }
        elseif ($null -ne $curTitle) { $curLines.Add($line) | Out-Null }
    }
    if ($null -ne $curTitle) { $sections[$curTitle] = (($curLines -join "`n").Trim()) }

    [pscustomobject]@{
        schema          = $fm['schema']; source = $fm['source']; from_host = $fm['from_host']
        recorded_at     = $fm['recorded_at']; from_commit = $fm['from_commit']
        active_feature  = $fm['active_feature']
        active_boundary = $fm['active_boundary']
        # F-174 iter-10 (T003): the AUTHORIZED-gate + workshop-phase frontmatter (distinct from active_boundary,
        # which is the WORKING position). Present only when applicable; $null otherwise.
        last_authorized_boundary = $fm['last_authorized_boundary']
        last_verdict    = $fm['last_verdict']
        workshop_done   = $fm['workshop_done']
        workshop_remaining = $fm['workshop_remaining']
        sections        = $sections
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
        # F-174 iter-10 (T003): the AUTHORIZED-gate + workshop-phase frontmatter. HOOK-computed (the hook passes
        # them explicitly, even empty = clear); the agent body-author does NOT pass them -> they are PRESERVED
        # from the existing file (so authoring the body never strips this hook-derived state). The
        # $PSBoundParameters check distinguishes "preserve" (unbound) from "clear" (bound-but-empty).
        [Parameter()][AllowNull()][string] $LastAuthorizedBoundary,
        [Parameter()][AllowNull()][string] $LastVerdict,
        [Parameter()][AllowNull()][string] $WorkshopDone,
        [Parameter()][AllowNull()][string] $WorkshopRemaining,
        [Parameter()][System.Collections.IDictionary] $Sections = @{}
    )
    # T003 preserve: a caller that did not supply a gate/workshop field inherits the existing file's value.
    $prevFm = $null
    if (Test-Path -LiteralPath $Path) {
        $prevFm = ConvertFrom-SpecrewHandoverFile -Path $Path
        if ($null -ne $prevFm) {
            if (-not $PSBoundParameters.ContainsKey('LastAuthorizedBoundary')) { $LastAuthorizedBoundary = [string]$prevFm.last_authorized_boundary }
            if (-not $PSBoundParameters.ContainsKey('LastVerdict')) { $LastVerdict = [string]$prevFm.last_verdict }
            if (-not $PSBoundParameters.ContainsKey('WorkshopDone')) { $WorkshopDone = [string]$prevFm.workshop_done }
            if (-not $PSBoundParameters.ContainsKey('WorkshopRemaining')) { $WorkshopRemaining = [string]$prevFm.workshop_remaining }
        }
    }
    # F-174 iter-11 (T003, SC-015) CLOBBER GUARD, CENTRALIZED so BOTH callers (the hook floor-writer AND the agent
    # body-author Write-SpecrewHandoverContext) honor it. The captured-packet section (the THIRD ownership category)
    # is HOOK-captured verbatim; neither caller's own per-writer preserve touches it (it is excluded from both the
    # mechanical and agent-owned sets). So if THIS write does not supply a fresh captured packet, carry the existing
    # one forward UNCHANGED - but ONLY while it is authored AND still belongs to the CURRENT active_boundary. A
    # forward boundary change leaves it absent -> it falls to the placeholder (the prior boundary's packet is stale);
    # a later generic Stop / a placeholder refresh / the agent authoring its own sections all PRESERVE it. Mutates a
    # LOCAL copy, never the caller's dict.
    $writeSections = @{}
    foreach ($k in $Sections.Keys) { $writeSections[$k] = $Sections[$k] }
    if ($null -ne $prevFm -and $prevFm.sections -and $prevFm.sections.Count -gt 0 -and
        (([string]$prevFm.active_boundary) -eq ([string]$ActiveBoundary))) {
        foreach ($ct in (Get-SpecrewHandoverCapturedSections)) {
            $freshSupplied = $writeSections.Contains($ct) -and -not [string]::IsNullOrWhiteSpace([string]$writeSections[$ct])
            if ($freshSupplied) { continue }
            if ($prevFm.sections.Contains($ct) -and (Test-SpecrewHandoverSectionAuthored -Content ([string]$prevFm.sections[$ct]))) {
                $writeSections[$ct] = [string]$prevFm.sections[$ct]
            }
        }
    }
    # Frontmatter values are single-line key: value; collapse any newline so a value never breaks the block.
    $clean = { param($v) if ([string]::IsNullOrWhiteSpace([string]$v)) { '' } else { (([string]$v) -replace '\s+', ' ').Trim() } }
    $marker = Get-SpecrewHandoverPlaceholderMarker -Boundary $ActiveBoundary
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($l in @(
            '---', 'schema: v1', "source: $Source", "from_host: $FromHost", "recorded_at: $RecordedAt",
            "from_commit: $FromCommit", "active_feature: $ActiveFeature", "active_boundary: $ActiveBoundary")) { $out.Add($l) | Out-Null }
    # T003: emit the gate + workshop lines ONLY when present, so the frontmatter stays quiet outside the
    # intake window / on legacy contexts. active_boundary above is the WORKING position; these are distinct.
    if (-not [string]::IsNullOrWhiteSpace($LastAuthorizedBoundary)) { $out.Add("last_authorized_boundary: $(& $clean $LastAuthorizedBoundary)") | Out-Null }
    if (-not [string]::IsNullOrWhiteSpace($LastVerdict)) { $out.Add("last_verdict: $(& $clean $LastVerdict)") | Out-Null }
    if (-not [string]::IsNullOrWhiteSpace($WorkshopDone)) { $out.Add("workshop_done: $(& $clean $WorkshopDone)") | Out-Null }
    if (-not [string]::IsNullOrWhiteSpace($WorkshopRemaining)) { $out.Add("workshop_remaining: $(& $clean $WorkshopRemaining)") | Out-Null }
    foreach ($l in @('---', '', '# Session Handover (rolling)', '')) { $out.Add($l) | Out-Null }
    foreach ($title in (Get-SpecrewHandoverSectionOrder)) {
        $content = if ($writeSections.Contains($title) -and -not [string]::IsNullOrWhiteSpace([string]$writeSections[$title])) {
            [string]$writeSections[$title]
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
    # M3 (iter-10): per-PROCESS sidecar so two hooks firing at once (e.g. PostToolUse + Stop) don't race on a
    # shared "$Path.new". The .old backup name stays fixed (best-effort backup).
    $newPath = "$Path.$PID.new"
    try {
        Set-Content -LiteralPath $newPath -Value ($out -join "`n") -Encoding UTF8
        if (Test-Path -LiteralPath $Path) {
            [System.IO.File]::Replace($newPath, $Path, "$Path.old")
        }
        else {
            Move-Item -LiteralPath $newPath -Destination $Path -Force
        }
    }
    catch {
        $primaryErr = $_
        try {
            # Exotic-FS fallback: plain in-place write (loses the .old backup but keeps the handover current).
            Set-Content -LiteralPath $Path -Value ($out -join "`n") -Encoding UTF8
            Remove-Item -LiteralPath $newPath -Force -ErrorAction SilentlyContinue
        }
        catch {
            # M3: a TOTAL write failure (atomic Replace AND the in-place fallback both failed - read-only /
            # locked / AV'd / network-locked file) must NOT be swallowed: the handover silently stops updating
            # and the next session inherits stale content with NO signal. Surface to stderr + the
            # handover-journal (best-effort), mirroring the hollow path, so a frozen handover is diagnosable.
            [Console]::Error.WriteLine(("[specrew-handover] WARN HANDOVER_WRITE_FAILED path='{0}' primary='{1}' fallback='{2}' - the handover did NOT update this stop." -f $Path, $primaryErr.Exception.Message, $_.Exception.Message))
            try {
                $jpath = Join-Path (Split-Path -Parent (Split-Path -Parent $Path)) 'runtime/handover-journal.jsonl'
                $jdir = Split-Path -Parent $jpath
                if ($jdir -and -not (Test-Path -LiteralPath $jdir)) { New-Item -ItemType Directory -Path $jdir -Force | Out-Null }
                $rec = [pscustomobject]@{ event = 'handover-write-failed'; recorded_at = $RecordedAt; path = $Path; primary_error = $primaryErr.Exception.Message; fallback_error = $_.Exception.Message }
                ($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $jpath -Encoding UTF8
            }
            catch { $null = $_ }
            Remove-Item -LiteralPath $newPath -Force -ErrorAction SilentlyContinue
        }
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
        [Parameter()][System.Collections.IDictionary] $MechanicalSections = @{},
        # F-174 iter-10 (T003): the HOOK-computed gate + workshop frontmatter, passed through (bound, even
        # empty = authoritative clear) to the shared writer. The agent body-author does not set these.
        [Parameter()][AllowNull()][string] $LastAuthorizedBoundary,
        [Parameter()][AllowNull()][string] $LastVerdict,
        [Parameter()][AllowNull()][string] $WorkshopDone,
        [Parameter()][AllowNull()][string] $WorkshopRemaining,
        # F-174 iter-11 (T002, DF-3): the VERBATIM boundary packet the hook captured from the transcript this stop.
        # Passed ONLY when the caller (Update-SpecrewRollingHandover) judged it a FRESH, CURRENT packet (its marker
        # range brackets the active boundary). When supplied it OVERWRITES the captured section; when absent the
        # shared writer's centralized clobber guard PRESERVES the existing one (within its boundary). Blank = no
        # fresh packet this stop (the common case), not an authoritative clear.
        [Parameter()][AllowNull()][string] $CapturedPacket
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
    # F-174 iter-11 (T002): inject a FRESH captured packet (the caller already judged it current). It is the third
    # ownership category, so it goes STRAIGHT into the body (not via the mechanical/agent-owned merges above);
    # when absent, the shared writer PRESERVES the existing captured section (the centralized clobber guard).
    if (-not [string]::IsNullOrWhiteSpace($CapturedPacket)) {
        foreach ($ct in (Get-SpecrewHandoverCapturedSections)) { $bodySections[$ct] = [string]$CapturedPacket }
    }

    return (Write-SpecrewRollingHandoverContent -Path $path -Source $Source -FromHost $FromHost -RecordedAt $RecordedAt `
            -FromCommit $FromCommit -ActiveFeature $ActiveFeature -ActiveBoundary $ActiveBoundary -Sections $bodySections `
            -LastAuthorizedBoundary $LastAuthorizedBoundary -LastVerdict $LastVerdict `
            -WorkshopDone $WorkshopDone -WorkshopRemaining $WorkshopRemaining)
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
    # F-174 iter-10 (T002 fix F2): the agent body-author does NOT capture the HOOK-owned mechanical sections -
    # notably 'Recent conversation', which only the Stop/PostToolUse hook reads from the host transcript. Left
    # alone, the shared writer would placeholder any section the agent's packet omits, so authoring the
    # boundary packet ERASES the hook-captured conversation. Mirror Write-SpecrewRollingHandover's overlay
    # preserve in reverse: carry forward any AUTHORED hook-owned mechanical section the agent omitted. Scoped
    # to the mechanical complement + gated on authored (surgical, NOT a blanket preserve-on-missing -
    # interpretive sections the agent intentionally clears stay cleared).
    $merged = @{}
    foreach ($k in $Sections.Keys) { $merged[$k] = $Sections[$k] }
    if (Test-Path -LiteralPath $path) {
        $existing = ConvertFrom-SpecrewHandoverFile -Path $path
        if ($null -ne $existing -and $existing.sections -and $existing.sections.Count -gt 0) {
            # BOUNDARY GATING (Prop-145 P2 finding): a narrative mechanical the agent omits is ERA-scoped, so it
            # must NOT be resurrected from a PRIOR boundary (that would leak stale "What I just did" / "Context"
            # across a boundary change) - same boundary-gate the sibling hook writer applies to its preserve.
            # The TIME-scoped conversation tail is the exception: it carries across boundaries (cross-session
            # continuity is the point), so it is preserved regardless of the existing file's boundary.
            $sameBoundary = (([string]$existing.active_boundary) -eq ([string]$ActiveBoundary))
            $timeScoped = Get-SpecrewHandoverTimeScopedSections
            foreach ($mt in (Get-SpecrewHandoverMechanicalSections)) {
                $agentSupplied = $merged.Contains($mt) -and -not [string]::IsNullOrWhiteSpace([string]$merged[$mt])
                if ($agentSupplied) { continue }
                if (-not ($existing.sections.Contains($mt) -and (Test-SpecrewHandoverSectionAuthored -Content ([string]$existing.sections[$mt])))) { continue }
                if (($timeScoped -contains $mt) -or $sameBoundary) {
                    $merged[$mt] = [string]$existing.sections[$mt]
                }
            }
        }
    }
    return (Write-SpecrewRollingHandoverContent -Path $path -Source $Source -FromHost $FromHost -RecordedAt $RecordedAt `
            -FromCommit $FromCommit -ActiveFeature $ActiveFeature -ActiveBoundary $ActiveBoundary -Sections $merged)
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
    # M3 (iter-10): treat a STRUCTURALLY-INVALID parse (a truncated/corrupt file whose frontmatter has no
    # recorded_at) the SAME as missing/unparseable and fall back to .old - previously only a fully-null parse
    # triggered the fallback, so a partially-written file was accepted as a valid (but broken) handover.
    $isValid = { param($p) ($null -ne $p) -and -not [string]::IsNullOrWhiteSpace([string]$p.recorded_at) }
    if (-not (& $isValid $parsed) -and (Test-Path -LiteralPath "$path.old")) {
        $oldParsed = ConvertFrom-SpecrewHandoverFile -Path "$path.old"
        if (& $isValid $oldParsed) { $parsed = $oldParsed }
    }
    if (-not (& $isValid $parsed)) { return $null }
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

function Get-SpecrewRuntimeHostFromEnv {
    # F-174 iter-10 (T004): best-effort detection of which AI host is running THIS process, from its env
    # signals. The design-workshop refresh runs the handover provider WITHOUT --host-kind (it is invoked by
    # the agent, not the per-host hook dispatcher) and, in the pre-specify window, the anchor has no committed
    # host either - so from_host fell back to the literal 'host' sentinel (dogfood 2026-06-12). Detecting the
    # LIVE host here is correct-by-construction across the shared .agents skill root (codex vs antigravity
    # resolve by their DISTINCT session vars, which per-host skill baking could not), never stale (live env,
    # not a stored marker), and degrades to $null -> the honest 'host' when nothing matches (never a deceptive
    # value). Mirrors the per-host signal sets in hosts/<kind>/handlers.ps1 (Get-<Kind>Signals) - keep in sync;
    # the credential-only vars (CODEX_API_KEY etc., often globally set) are deliberately excluded to avoid a
    # false match in a different host's session. Returns the host kind or $null.
    [CmdletBinding()]
    [OutputType([string])]
    param()
    $signals = [ordered]@{
        codex       = @('CODEX_SESSION_ID', 'OPENAI_CODEX_CLI')
        claude      = @('CLAUDECODE', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_PROJECT_DIR')
        copilot     = @('COPILOT_AGENT_SESSION_ID', 'COPILOT_CLI', 'COPILOT_CLI_BINARY_VERSION')
        cursor      = @('CURSOR_AGENT', 'CURSOR_TRACE_ID')
        antigravity = @('ANTIGRAVITY_SESSION_ID')
    }
    foreach ($kind in $signals.Keys) {
        foreach ($var in $signals[$kind]) {
            if (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($var))) { return $kind }
        }
    }
    return $null
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
        [Parameter()][string] $NowUtc = ((Get-Date).ToUniversalTime().ToString('o')),
        [Parameter()][AllowNull()][string] $TranscriptPath = $null,   # F-174 iter-10 (T002): host transcript_path for conversation capture
        [Parameter()][AllowNull()][string] $LastAssistantMessage = $null
    )

    $getProp = {
        param($o, $n)
        if ($null -eq $o) { return $null }
        $p = $o.PSObject.Properties[$n]
        if ($p) { return $p.Value } else { return $null }
    }

    # Current context from the committed session state. (F-174 iter-10: T002 adds best-effort transcript
    # capture and T003 surfaces the authorized gate + workshop phase - all read from this same committed state.)
    $feature = $null; $boundary = $null; $fromHost = 'host'
    $lastAuthBoundary = $null; $lastVerdict = $null
    $ctxPath = Join-Path $ProjectRoot '.specrew/start-context.json'
    if (Test-Path -LiteralPath $ctxPath) {
        try {
            $ctx = Get-Content -LiteralPath $ctxPath -Raw | ConvertFrom-Json
            $ss = & $getProp $ctx 'session_state'
            $feature = & $getProp $ss 'feature_ref'
            $boundary = & $getProp $ss 'boundary_type'
            $h = & $getProp $ss 'host'; if ([string]::IsNullOrWhiteSpace($h)) { $h = & $getProp $ctx 'host' }
            if (-not [string]::IsNullOrWhiteSpace($h)) { $fromHost = [string]$h }
            # T003: the AUTHORIZED gate (deterministic governance state, not agent behavior) - DISTINCT from
            # session_state.boundary_type (the WORKING position above). last_authorized_boundary + the richest
            # human-legible proof from verdict_history[-1].
            $be = & $getProp $ctx 'boundary_enforcement'
            if ($null -ne $be) {
                $lab = & $getProp $be 'last_authorized_boundary'
                if (-not [string]::IsNullOrWhiteSpace($lab)) { $lastAuthBoundary = [string]$lab }
                $vhArr = @(& $getProp $be 'verdict_history')
                if ($vhArr.Count -gt 0) {
                    $lastV = $vhArr[$vhArr.Count - 1]
                    $vtext = & $getProp $lastV 'verdict_text'
                    if (-not [string]::IsNullOrWhiteSpace($vtext)) {
                        $lastVerdict = [string]$vtext
                        $vhuman = & $getProp $lastV 'authorizing_human'
                        $vcommit = & $getProp $lastV 'auth_commit_hash'
                        if (-not [string]::IsNullOrWhiteSpace($vhuman)) { $lastVerdict += " by $vhuman" }
                        if (-not [string]::IsNullOrWhiteSpace($vcommit)) { $lastVerdict += " @$vcommit" }
                    }
                }
            }
        }
        catch { $null = $_ }
    }
    # Anchorless workshop window: resolve the feature from the branch so the handover is surfaceable (T050).
    if ([string]::IsNullOrWhiteSpace([string]$feature)) { $feature = Resolve-SpecrewBranchFeatureRef -ProjectRoot $ProjectRoot }
    # T004: when neither the trigger nor the committed session-state named a host (the pre-specify workshop
    # refresh, where the anchor is not yet committed), detect the LIVE host from its env signals before
    # falling back to the literal 'host' sentinel. Only fills the gap (runs when $fromHost is still 'host'),
    # so it never overrides a known session-state host; --host-kind below still wins as the authoritative source.
    if ($fromHost -eq 'host') {
        $envHost = Get-SpecrewRuntimeHostFromEnv
        if (-not [string]::IsNullOrWhiteSpace($envHost)) { $fromHost = $envHost }
    }
    # The trigger passes the authoritative host; prefer it over the start-context value or the 'host' default.
    if (-not [string]::IsNullOrWhiteSpace($HostKind)) { $fromHost = $HostKind }

    # T003: the workshop phase, surfaced ONLY while in-flight (the pre-specify intake window); quiet otherwise.
    # Reads the SAME deterministic disk truth the bootstrap directive uses (Get-SpecrewWorkshopProgress);
    # guarded because the workshop-skill/test paths may not have co-loaded ProjectMetadataAccessor.
    $workshopDone = $null; $workshopRemaining = $null
    if (-not [string]::IsNullOrWhiteSpace([string]$feature) -and (Get-Command Get-SpecrewWorkshopProgress -ErrorAction SilentlyContinue)) {
        try {
            $wp = Get-SpecrewWorkshopProgress -ProjectRoot $ProjectRoot -FeatureRef ([string]$feature)
            if ($null -ne $wp -and $wp.in_flight) {
                $wd = @($wp.done); $wr = @($wp.remaining)
                if ($wd.Count -gt 0) { $workshopDone = ($wd -join ', ') }
                if ($wr.Count -gt 0) { $workshopRemaining = ($wr -join ', ') }
            }
        }
        catch { $null = $_ }
    }

    $handoverDir = Join-Path $ProjectRoot '.specrew/handover'

    # Material-change gate (the call-cheapness guarantee - PostToolUse fires on every tool call): refresh only
    # when the boundary moved OR there is a tracked-file change since the last write.
    $existing = Get-SpecrewRollingHandover -HandoverDir $handoverDir -NowUtc $NowUtc
    $lastBoundary = if ($null -ne $existing) { $existing.active_boundary } else { $null }
    $hasChange = $false
    # Prop-145 round-6 (HIGH, write-path half of Finding 1): this `git status` is the HOTTER instance of the
    # parent-repo-scan defect - it fires on EVERY PostToolUse, not once per session-start. Gate it on the SAME
    # repo-root check Get-SpecrewSessionDelta uses: from a nested / non-repo root under a parent git repo or
    # worktree, an ungated `git status` walks the whole parent tree (unbounded -> hangs the hook; try/catch
    # cannot bound a hung process) AND would report the PARENT'S dirty files as this project's change. Not a
    # repo root -> no tracked change to detect here (consistent with the empty Get-SpecrewSessionDelta below).
    if (Test-SpecrewIsGitRepoRoot -ProjectRoot $ProjectRoot) {
        try { $st = (& git -C $ProjectRoot status --porcelain 2>$null); $hasChange = -not [string]::IsNullOrWhiteSpace(($st -join "`n")) } catch { $null = $_ }
    }
    $mc = Test-SpecrewHandoverMaterialChange -CurrentBoundary $boundary -LastBoundary $lastBoundary -HasTrackedChange $hasChange -HandoverExists ($null -ne $existing)
    # Prop-145 round-4 (HIGH): a conversation-only turn (clean tree, same boundary) is NOT a git/boundary "material
    # change", but it IS new context that T002 promises to capture. END-OF-TURN events (Stop/agentStop/stop) fire
    # once per turn, so refresh on them regardless - capturing the latest transcript tail + recorded_at. PostToolUse
    # (per-tool-call) and the workshop refresh STAY gated (the call-cheapness guarantee). The activity-bullet logic
    # below stays delta-gated so a no-delta refresh never flushes real work out of the 6-bullet window.
    $isEndOfTurn = $Source -in @('Stop', 'agentStop', 'stop')
    if (-not $mc.material -and -not $isEndOfTurn) { return [pscustomobject]@{ wrote = $false; reason = $mc.reason; source = $Source; feature = $feature; boundary = $boundary } }
    $refreshReason = if ($mc.material) { $mc.reason } else { 'end-of-turn conversation refresh (no git/boundary delta)' }

    $head = ''
    try { $head = ([string](& git -C $ProjectRoot rev-parse --short HEAD 2>$null)).Trim() } catch { $null = $_ }
    $sinceCommit = if ($null -ne $existing) { [string]$existing.from_commit } else { $null }
    $delta = Get-SpecrewSessionDelta -ProjectRoot $ProjectRoot -SinceCommit $sinceCommit

    $featureLabel = if ([string]::IsNullOrWhiteSpace([string]$feature)) { '(no active feature)' } else { [string]$feature }
    $boundaryLabel = if ([string]::IsNullOrWhiteSpace([string]$boundary)) { '(pre-boundary / workshop)' } else { [string]$boundary }

    # One activity line for THIS refresh, accumulated newest-first across the boundary window. Lead with the
    # user's REAL changed files; the Specrew-managed scaffolding is noted by count, never listed (dogfood:
    # the ~53 managed paths were drowning the real work + filling the file cap).
    $userShownList = @($delta.user_files)
    $userShown = if ($userShownList.Count -gt 0) { ($userShownList -join ', ') } else { '(none)' }
    if (([int]$delta.user_file_count) -gt $userShownList.Count) { $userShown = "$userShown, +more" }
    $managedNote = if (([int]$delta.managed_file_count) -gt 0) { (" (+{0} Specrew-managed)" -f $delta.managed_file_count) } else { '' }
    $fileNote = " [$userShown]$managedNote"
    $commitNote = if ($delta.new_commit_count -gt 0) { ("; {0} new commit(s): {1}" -f $delta.new_commit_count, ((@($delta.new_commits)) -join ' | ')) } else { '' }
    $stamp = if ($NowUtc.Length -ge 19) { ($NowUtc.Substring(0, 19) + 'Z') } else { $NowUtc }
    $stopBullet = ("- [{0}] ({1}) {2} changed user file(s){3}; HEAD {4} ({5}){6}" -f $stamp, $Source, $delta.user_file_count, $fileNote, $delta.head_short, $delta.head_subject, $commitNote)

    $activityTitle = 'What I just did (last 3-5 turns or last boundary work)'
    $priorBullets = @()
    if ($null -ne $existing -and ([string]$existing.active_boundary -eq [string]$boundary) -and $existing.sections -and $existing.sections.Contains($activityTitle)) {
        $prev = [string]$existing.sections[$activityTitle]
        if (-not [string]::IsNullOrWhiteSpace($prev) -and $prev -notlike '(placeholder*') {
            $priorBullets = @($prev -split "`n" | Where-Object { $_ -match '^\s*-\s' })
        }
    }
    # Only PREPEND a new activity bullet when this refresh did REAL work (changed user files or new commits). A
    # no-delta end-of-turn refresh (a pure analysis/conversation turn) carries the prior bullets forward UNCHANGED,
    # so a run of conversation-only turns cannot flush the last real-work bullet out of the 6-bullet window with
    # "0 changed" noise (Prop-145 round-4). With nothing prior + no real work, the single bullet is the floor.
    $hasRealWork = (([int]$delta.user_file_count) -gt 0) -or (([int]$delta.new_commit_count) -gt 0)
    $activity = if ($hasRealWork) {
        ((@($stopBullet) + $priorBullets) | Select-Object -First 6) -join "`n"
    }
    elseif ($priorBullets.Count -gt 0) {
        (@($priorBullets) | Select-Object -First 6) -join "`n"
    }
    else {
        $stopBullet
    }

    $whyStopping = ("Hook-captured at trigger '{0}' (the agent did not author a handover this turn). Boundary: {1}. Refresh reason: {2}." -f $Source, $boundaryLabel, $refreshReason)
    $recNext = if (([int]$delta.user_file_count) -gt 0) {
        ("Resume feature {0} at boundary {1}. {2} of YOUR file(s) are uncommitted [{3}]{4} - review/commit them before advancing." -f $featureLabel, $boundaryLabel, $delta.user_file_count, $userShown, $managedNote)
    }
    elseif ($delta.has_uncommitted) {
        ("Resume feature {0} at boundary {1}. Only Specrew-managed scaffolding is uncommitted ({2} file(s)) - that is the init baseline; commit it at a boundary." -f $featureLabel, $boundaryLabel, $delta.managed_file_count)
    }
    else {
        ("Resume feature {0} at boundary {1}. Working tree is clean; continue the next lifecycle step." -f $featureLabel, $boundaryLabel)
    }
    $uncommittedNote = if (([int]$delta.user_file_count) -gt 0) {
        $mn = if (([int]$delta.managed_file_count) -gt 0) { (" ({0} Specrew-managed files also uncommitted.)" -f $delta.managed_file_count) } else { '' }
        (" Your uncommitted work: {0}.{1}" -f $userShown, $mn)
    }
    elseif ($delta.has_uncommitted) { (" No user files changed; {0} Specrew-managed scaffolding file(s) uncommitted." -f $delta.managed_file_count) }
    else { '' }
    $context = ("branch {0}, HEAD {1} ({2}). Active feature {3}, boundary {4}.{5}" -f $delta.branch, $delta.head_short, $delta.head_subject, $featureLabel, $boundaryLabel, $uncommittedNote)

    # F-174 iter-10 (T002, FR-022): the best-effort conversation tail. Fail-open + additive - only when the
    # capture component is loaded (the handover provider co-loads it; the workshop-skill/test paths may not)
    # and it yields content. Bounded inside Get-SpecrewConversationTail; never grows with the session.
    $conversation = $null
    if (Get-Command Get-SpecrewConversationTail -ErrorAction SilentlyContinue) {
        try { $conversation = Get-SpecrewConversationTail -HostKind $fromHost -TranscriptPath $TranscriptPath -LastAssistantMessage $LastAssistantMessage } catch { $conversation = $null }
    }

    # F-174 iter-11 (T002, FR-022 / DF-3): capture the VERBATIM rendered boundary packet + compute the forward-only
    # working boundary. The agent renders/authors the packet; PERSISTING it is mechanical here so a resume inherits
    # the AUTHORED packet, not placeholders (DF-3). Guarded on the same helpers the verdict capture needs (the Stop
    # handover provider co-loads shared-governance; the workshop-skill / test paths do not and correctly skip both
    # the packet capture AND the marker-based active-boundary advance, falling back to the session-state boundary).
    # active_boundary = the forward-MOST of {the session-state working position, the prior file value, the marker's
    # FROM} - the marker is a forward-only floor (the maintainer's "set active_boundary from the captured marker"),
    # and it NEVER regresses an already-forward boundary. The packet is WRITTEN only when the new active boundary is
    # NOT already PAST the marker's TO (the freshness/stale guard): a packet from a boundary we have moved beyond is
    # dropped to the placeholder, while a forward boundary change naturally REPLACES the prior packet. Fail-open.
    $activeBoundary = $boundary
    $capturedPacketBody = $null
    if (-not [string]::IsNullOrWhiteSpace($TranscriptPath) -and
        (Get-Command Get-SpecrewCapturedBoundaryPacket -ErrorAction SilentlyContinue) -and
        (Get-Command Get-SpecrewBoundaryOrder -ErrorAction SilentlyContinue) -and
        (Get-Command Normalize-SpecrewCanonicalBoundaryType -ErrorAction SilentlyContinue)) {
        try {
            $pkt = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $TranscriptPath
            if ($pkt.Found) {
                $bOrder = @(Get-SpecrewBoundaryOrder)
                $idxOf = { param($b) if ([string]::IsNullOrWhiteSpace([string]$b)) { -1 } else { [Array]::IndexOf($bOrder, (Normalize-SpecrewCanonicalBoundaryType -Boundary $b)) } }
                $boundaryIdx = & $idxOf $boundary
                $priorIdx = & $idxOf $lastBoundary
                $fromIdx = & $idxOf $pkt.FromBoundary
                $toIdx = & $idxOf $pkt.ToBoundary
                # forward-most; a -1 (unrecognized boundary) never bumps the cursor (mirrors the T004 -ge 0 guards).
                $newActiveIdx = ([int[]]@($boundaryIdx, $priorIdx, $fromIdx) | Measure-Object -Maximum).Maximum
                if ($newActiveIdx -ge 0 -and $newActiveIdx -lt $bOrder.Count) { $activeBoundary = $bOrder[$newActiveIdx] }
                # FRESHNESS: write iff the active boundary is within the marker's [FROM..TO] range, i.e. not already
                # past TO. A -1 on either side fails OPEN (cannot rank -> do not reject), mirroring T004.
                $isFresh = ($toIdx -lt 0) -or ($newActiveIdx -lt 0) -or ($newActiveIdx -le $toIdx)
                if ($isFresh) { $capturedPacketBody = [string]$pkt.PacketBody }
            }
        }
        catch { [Console]::Error.WriteLine("[specrew-handover] WARN PACKET_CAPTURE_FAILED $($_.Exception.Message)") }
    }

    $mechanical = @{
        $activityTitle                                                = $activity
        "Why I'm stopping (the switch trigger)"                       = $whyStopping
        'Recommended next-immediate-step'                             = $recNext
        "Context the receiving host needs that artifacts don't carry" = $context
    }
    if (-not [string]::IsNullOrWhiteSpace($conversation)) {
        $mechanical['Recent conversation (last few exchanges, hook-captured)'] = $conversation
    }

    Write-SpecrewRollingHandover -HandoverDir $handoverDir -Source $Source -FromHost $fromHost `
        -RecordedAt $NowUtc -FromCommit $head -ActiveFeature $feature -ActiveBoundary $activeBoundary `
        -MechanicalSections $mechanical -CapturedPacket $capturedPacketBody `
        -LastAuthorizedBoundary $lastAuthBoundary -LastVerdict $lastVerdict `
        -WorkshopDone $workshopDone -WorkshopRemaining $workshopRemaining | Out-Null

    # F-174 iteration 011 (T004, FR-026 / decision f174-i011-verdict-authority-stop-hook): THE HOOK IS THE
    # VERDICT AUTHORITY. On an end-of-turn stop, read the transcript for the human's verdict on the most recently
    # rendered boundary packet (Get-SpecrewCapturedBoundaryVerdict, tied to the packet marker) and, if it is a
    # CLEAR approval that advances the gate FORWARD, record the authorization with the captured verdict +
    # evidence-source 'hook-captured-from-transcript'. This is what replaces boundary-sync's DELETED fabrication
    # (T005): the gate advances ONLY on a real, captured human verdict - never invented. Guarded: runs only when
    # BOTH the reader and the writer are loaded (the Stop-hook handover provider co-loads shared-governance; the
    # design-workshop-refresh / test paths do not and correctly skip the authorization). Identity is left
    # UNATTRIBUTED unless a host surface proves it (none reliably does yet) - honest over invented. CONTIGUOUS
    # one-boundary-at-a-time (the gate-contiguity guard below; the reader's contradiction/ambiguity guards already
    # gate Found); fully fail-open - a capture failure degrades to "un-authorized", surfaced by the resume (T006),
    # and NEVER blocks the stop.
    if ($isEndOfTurn -and -not [string]::IsNullOrWhiteSpace($TranscriptPath) -and
        (Get-Command Get-SpecrewCapturedBoundaryVerdict -ErrorAction SilentlyContinue) -and
        (Get-Command Add-SpecrewBoundaryAuthorization -ErrorAction SilentlyContinue) -and
        (Get-Command Get-SpecrewBoundaryOrder -ErrorAction SilentlyContinue) -and
        (Get-Command Get-SpecrewPendingBoundaryCrossing -ErrorAction SilentlyContinue)) {
        try {
            $captured = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $TranscriptPath
            if ($captured.Found) {
                $bOrder = @(Get-SpecrewBoundaryOrder)
                $authIdx = if ([string]::IsNullOrWhiteSpace([string]$lastAuthBoundary)) { -1 } else { [Array]::IndexOf($bOrder, (Normalize-SpecrewCanonicalBoundaryType -Boundary $lastAuthBoundary)) }
                $toIdx = [Array]::IndexOf($bOrder, (Normalize-SpecrewCanonicalBoundaryType -Boundary $captured.ToBoundary))
                $pendingCrossing = Get-SpecrewPendingBoundaryCrossing -LastAuthorizedBoundary $lastAuthBoundary -WorkingBoundary $captured.ToBoundary
                $actualFrom = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$captured.FromBoundary)
                $actualTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$captured.ToBoundary)
                $expectedFrom = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pendingCrossing.PendingFromMarkerBoundary)
                $expectedTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pendingCrossing.PendingToMarkerBoundary)
                # GATE CONTIGUITY (one-boundary-at-a-time). The expected crossing is derived once from
                # last_authorized_boundary; the transcript marker must match that exact rendered crossing. This covers
                # both normal gates (plan -> tasks) and the first gate's marker-only sentinel (intake -> specify).
                if ([bool]$pendingCrossing.HasPendingVerdict -and $actualFrom -eq $expectedFrom -and $actualTo -eq $expectedTo) {
                    Add-SpecrewBoundaryAuthorization -ProjectRoot $ProjectRoot `
                        -CurrentBoundary $pendingCrossing.PendingFromBoundary -AuthorizedBoundary $pendingCrossing.PendingToBoundary `
                        -AuthorizingHuman 'unattributed' -VerdictText $captured.VerdictText `
                        -EvidenceSource 'hook-captured-from-transcript' | Out-Null
                }
                elseif ($toIdx -gt $authIdx) {
                    # A CLEAR approval whose marker is forward but NON-CONTIGUOUS with the cursor: refuse to apply it
                    # (applying it would skip an earlier unauthorized gate). Record the mismatch for forensics; the
                    # gate stays put and the resume (T006) surfaces awaiting-verdict for the contiguous boundary.
                    [Console]::Error.WriteLine(("[specrew-handover] WARN MARKER_CURSOR_MISMATCH captured '{0}->{1}' but expected '{2}->{3}' from authorized cursor '{4}'; NOT authorizing (one-boundary-at-a-time)." -f $captured.FromBoundary, $captured.ToBoundary, $expectedFrom, $expectedTo, $lastAuthBoundary))
                    try {
                        $mmJournal = Join-Path $ProjectRoot '.specrew/runtime/handover-journal.jsonl'
                        $mmDir = Split-Path -Parent $mmJournal
                        if ($mmDir -and -not (Test-Path -LiteralPath $mmDir)) { New-Item -ItemType Directory -Path $mmDir -Force | Out-Null }
                        (([pscustomobject]@{ event = 'marker-cursor-mismatch'; recorded_at = $NowUtc; captured_from = $captured.FromBoundary; captured_to = $captured.ToBoundary; expected_from = $expectedFrom; expected_to = $expectedTo; authorized_cursor = [string]$lastAuthBoundary; source = $Source }) | ConvertTo-Json -Compress) | Add-Content -LiteralPath $mmJournal -Encoding UTF8
                    }
                    catch { $null = $_ }
                }
            }
        }
        catch { [Console]::Error.WriteLine("[specrew-handover] WARN VERDICT_CAPTURE_FAILED $($_.Exception.Message)") }
    }

    # M2 (iter-10): hollow = the git delta GENUINELY produced nothing (git unavailable / the fail-safe empty
    # shape), NOT the formatted-section count. The old check counted $mechanical.Values, which are always-
    # non-empty formatted strings, so $mechAuthored was always >=4 and $hollow was always false -> the WARN +
    # journal backstop below was dead code, and a genuinely information-poor handover surfaced as authoritative.
    $hollow = ([string]::IsNullOrWhiteSpace([string]$delta.branch) -and `
        [string]::IsNullOrWhiteSpace([string]$delta.head_short) -and `
        (-not $delta.has_uncommitted) -and `
        (([int]$delta.new_commit_count) -eq 0))
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
