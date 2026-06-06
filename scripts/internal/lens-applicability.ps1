<#
.SYNOPSIS
  Deterministic design-analysis lens applicability selector (Feature 141 Iteration 4 / FR-025).

  Pure functions: given the decoupled sibling applicability-map (always-on foundational lenses +
  per-question gated specialized lenses) and the recorded questionnaire answers, compute the
  selected lens set. Selection is a deterministic function of (map, answers) — identical answers
  always yield the identical ordered set. No network, no LLM; the only judgment input is the
  recorded answers. The Proposal 156 catalog `index.yml` is NOT read or modified here (decoupled).
#>

Set-StrictMode -Version Latest

function Read-SpecrewLensApplicabilityMap {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try {
        return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    catch {
        return $null
    }
}

function Read-SpecrewLensAnswers {
    # Reads the lens-applicability.json artifact; returns the inner `answers` object (or $null).
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try {
        $doc = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -ne $doc -and $doc.PSObject.Properties['answers']) { return $doc.answers }
        return $null
    }
    catch {
        return $null
    }
}

function Test-SpecrewLensAnswerYes {
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return $false }
    if ($Value -is [bool]) { return [bool]$Value }
    return (([string]$Value).Trim() -match '^(?i:yes|true|y)$')
}

function Get-SpecrewAnswerValue {
    param([AllowNull()]$Answers, [Parameter(Mandatory = $true)][string]$Key)

    if ($null -eq $Answers) { return $null }
    if ($Answers -is [System.Collections.IDictionary]) {
        if ($Answers.Contains($Key)) { return $Answers[$Key] }
        return $null
    }
    $prop = $Answers.PSObject.Properties[$Key]
    if ($prop) { return $prop.Value }
    return $null
}

function Get-SpecrewApplicableLenses {
    # Pure deterministic selector: always-on (foundational) + specialized lenses gated by a yes answer.
    # Order: always-on first (map order), then gated lenses in question order. Deduplicated.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Map,
        [Parameter(Mandatory = $true)][AllowNull()]$Answers
    )

    $selected = [System.Collections.Generic.List[string]]::new()
    # Graceful degradation (SC-006): no map (catalog absent) OR no answers (questionnaire not
    # answered) -> none available. Foundational always-on lenses apply only once the questionnaire
    # has been answered, so an absent questionnaire does not fabricate a selection.
    if ($null -eq $Map -or $null -eq $Answers) { return @() }

    foreach ($lens in @($Map.always_on)) {
        $id = [string]$lens
        if (-not [string]::IsNullOrWhiteSpace($id) -and -not $selected.Contains($id)) {
            $selected.Add($id) | Out-Null
        }
    }

    foreach ($q in @($Map.questions)) {
        if (Test-SpecrewLensAnswerYes -Value (Get-SpecrewAnswerValue -Answers $Answers -Key ([string]$q.id))) {
            foreach ($g in @($q.gates)) {
                $gid = [string]$g
                if (-not [string]::IsNullOrWhiteSpace($gid) -and -not $selected.Contains($gid)) {
                    $selected.Add($gid) | Out-Null
                }
            }
        }
    }

    return $selected.ToArray()
}

function Get-SpecrewLensSelection {
    # Audit wrapper: selected set + per-lens include/exclude rationale (for the JSON + render).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Map,
        [Parameter(Mandatory = $true)][AllowNull()]$Answers
    )

    $selected = @(Get-SpecrewApplicableLenses -Map $Map -Answers $Answers)
    $included = [System.Collections.Generic.List[object]]::new()
    $excluded = [System.Collections.Generic.List[object]]::new()

    if ($null -ne $Map -and $null -ne $Answers) {
        foreach ($lens in @($Map.always_on)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$lens)) {
                $included.Add([pscustomobject]@{ id = [string]$lens; reason = 'always-on (foundational)' }) | Out-Null
            }
        }
        foreach ($q in @($Map.questions)) {
            $qid = [string]$q.id
            $yes = Test-SpecrewLensAnswerYes -Value (Get-SpecrewAnswerValue -Answers $Answers -Key $qid)
            foreach ($g in @($q.gates)) {
                $entry = [pscustomobject]@{ id = [string]$g; reason = ("gated by '{0}' = {1}" -f $qid, $(if ($yes) { 'yes' } else { 'no' })) }
                if ($yes) { $included.Add($entry) | Out-Null } else { $excluded.Add($entry) | Out-Null }
            }
        }
    }

    return [pscustomobject]@{
        selected = $selected
        included = $included.ToArray()
        excluded = $excluded.ToArray()
    }
}

function New-SpecrewLensApplicabilityTemplate {
    # T002: emit a lens-applicability.json template (questions + empty answers) from the map for the
    # design-analysis questionnaire. Does not overwrite an existing file unless -Force. Returns the path.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Map,
        [Parameter(Mandatory = $true)][string]$OutPath,
        [switch]$Force
    )

    if ($null -eq $Map) { return $null }
    if ((Test-Path -LiteralPath $OutPath -PathType Leaf) -and -not $Force) { return $OutPath }

    $answers = [ordered]@{}
    $questions = [System.Collections.Generic.List[object]]::new()
    foreach ($q in @($Map.questions)) {
        $answers[[string]$q.id] = $false
        $questions.Add([ordered]@{ id = [string]$q.id; prompt = [string]$q.prompt }) | Out-Null
    }

    $doc = [ordered]@{
        schema    = 'v1'
        note      = 'Answer each question true/false (the design-analysis applicability questionnaire). Lens selection is then a deterministic function of these answers + the sibling applicability-map.json.'
        questions = $questions.ToArray()
        answers   = $answers
        selected  = @()
    }

    $parent = Split-Path -Parent $OutPath
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }
    [System.IO.File]::WriteAllText($OutPath, ($doc | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))
    return $OutPath
}

function Get-SpecrewLensDecisionPoints {
    # T001 (FR-009): pure extractor of a lens file's "## Design Decision Points" bullets so the
    # design analysis can be genuinely informed by the lens knowledge (not just named). Returns an
    # ordered string[] of decision points with continuation lines folded into their bullet. Graceful
    # @() when the catalog dir, the lens file, or the section is absent. No network/LLM; read-only.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$LensId,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$CatalogDir
    )

    if ([string]::IsNullOrWhiteSpace($LensId) -or [string]::IsNullOrWhiteSpace($CatalogDir)) { return @() }
    $path = Join-Path $CatalogDir ('{0}.md' -f $LensId)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @() }

    $content = ''
    try { $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8 }
    catch { return @() }
    if ([string]::IsNullOrWhiteSpace($content)) { return @() }

    # Isolate the "## Design Decision Points" section body (until the next ## heading or EOF).
    $section = [regex]::Match($content, '(?ims)^##\s+Design\s+Decision\s+Points\s*$\r?\n(?<body>.*?)(?=^##\s+|\z)')
    if (-not $section.Success) { return @() }

    $points = [System.Collections.Generic.List[string]]::new()
    $current = $null
    foreach ($rawLine in ($section.Groups['body'].Value -split '\r?\n')) {
        if ($rawLine -match '^\s*[-*]\s+(.*)$') {
            if ($null -ne $current) { $points.Add(($current -replace '\s+', ' ').Trim()) | Out-Null }
            $current = $Matches[1].Trim()
        }
        elseif ($null -ne $current -and $rawLine -match '^\s+\S') {
            # Indented continuation of the current bullet -> fold it in.
            $current = ('{0} {1}' -f $current, $rawLine.Trim())
        }
        else {
            # Blank line or non-indented prose ends the current bullet.
            if ($null -ne $current) { $points.Add(($current -replace '\s+', ' ').Trim()) | Out-Null }
            $current = $null
        }
    }
    if ($null -ne $current) { $points.Add(($current -replace '\s+', ' ').Trim()) | Out-Null }

    return $points.ToArray()
}

function Get-SpecrewLensQuestionDepth {
    # T001 (FR-025 / SC-018): map a material lens-question area + the user-profile expertise dials to
    # an interaction depth, so the lens intake adapts question depth to the human's expertise (the
    # F-016 interaction model). Returns 'expert-terse' (dial >= 8 — ask a concise expert question and
    # assume the human decides), 'guided-explain' (dial <= 3 — explain the area and recommend a
    # default), or 'moderate' (in between, or as the fail-safe when the dial/profile is absent).
    # Pure + deterministic; no network/LLM.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$ExpertiseDials,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Area
    )

    # Each material lens area maps to the most-relevant persona-lens dial; architect is the technical
    # default for areas without a dedicated dial.
    $areaToPersona = @{
        ui          = 'ux-ui-specialist'
        security    = 'architect'
        data        = 'architect'
        integration = 'architect'
        ops         = 'ai-researcher-project-manager'
        perf        = 'architect'
        architecture = 'architect'
    }

    $key = if ([string]::IsNullOrWhiteSpace($Area)) { '' } else { $Area.Trim().ToLowerInvariant() }
    $persona = if ($areaToPersona.ContainsKey($key)) { $areaToPersona[$key] } else { 'architect' }

    $dial = $null
    if ($null -ne $ExpertiseDials) {
        if ($ExpertiseDials -is [System.Collections.IDictionary]) {
            if ($ExpertiseDials.Contains($persona)) { $dial = $ExpertiseDials[$persona] }
        }
        else {
            $prop = $ExpertiseDials.PSObject.Properties[$persona]
            if ($prop) { $dial = $prop.Value }
        }
    }

    $value = 0
    if ($null -ne $dial -and [int]::TryParse([string]$dial, [ref]$value)) {
        if ($value -ge 8) { return 'expert-terse' }
        if ($value -le 3) { return 'guided-explain' }
        return 'moderate'
    }
    return 'moderate'  # fail-safe: absent/unparseable dial -> moderate depth
}

function Get-SpecrewLensWorkshopAgenda {
    # Iteration 7 T001 (FR-009 / FR-025, Amendment A4): produce the per-lens workshop AGENDA — the
    # ordered design questions the Crew raises for one lens during the facilitated intake. The agenda IS
    # the lens's "## Design Decision Points" (reused via Get-SpecrewLensDecisionPoints) surfaced as the
    # discussion the coordinator runs; the architecture-book phrasing lives in the lens files, so this
    # stays a pure, deterministic, LLM/network-free surfacing — no new parallel question bank. Graceful
    # @() when the lens/section/catalog is absent. This agenda is what the SC-021 per-lens record stores.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$LensId,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$CatalogDir
    )

    return @(Get-SpecrewLensDecisionPoints -LensId $LensId -CatalogDir $CatalogDir)
}

function Format-SpecrewLensWorkshopAgenda {
    # Iteration 7 T001 (FR-025, Amendment A4): render the human-visible "## Workshop Agenda" the Crew
    # surfaces during the per-lens facilitated intake — for each selected lens, its decision-point
    # questions as a numbered discussion agenda, with a per-lens decision/agreement line to capture and
    # a "move on" marker. Markdownlint-safe (asterisk emphasis; no '+'-at-line-start). Graceful
    # "None available" when nothing is selectable. Pure + deterministic; no network/LLM.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$SelectedLenses,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$CatalogDir
    )

    $lenses = @($SelectedLenses | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('## Workshop Agenda')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('For each applicable lens the Crew raises these design questions, adapts depth to your expertise, and records your decision and explicit agreement before moving on to the next lens.')
    [void]$sb.AppendLine('')

    if ($lenses.Count -eq 0) {
        [void]$sb.AppendLine('*None available* (no lenses selected, or the catalog is absent).')
        return $sb.ToString().TrimEnd()
    }

    foreach ($lens in $lenses) {
        [void]$sb.AppendLine(('### {0}' -f $lens))
        [void]$sb.AppendLine('')
        $agenda = @(Get-SpecrewLensWorkshopAgenda -LensId ([string]$lens) -CatalogDir $CatalogDir)
        if ($agenda.Count -eq 0) {
            [void]$sb.AppendLine('*No decision points found for this lens* (discuss its scope directly).')
        }
        else {
            $n = 1
            foreach ($item in $agenda) {
                [void]$sb.AppendLine(('{0}. {1}' -f $n, $item))
                $n++
            }
        }
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('- Decision / agreement: <captured during the workshop>')
        [void]$sb.AppendLine('- Depth used: <expert-terse | moderate | guided-explain>')
        [void]$sb.AppendLine('- Moved on: <yes, on the human''s confirmation>')
        [void]$sb.AppendLine('')
    }

    return $sb.ToString().TrimEnd()
}

function Format-SpecrewLensWorkshopDecisions {
    # Iteration 7 T004 (FR-009, Amendment A4): surface the RECORDED per-lens workshop decisions from a
    # lens-applicability.json so the workshop output concretely flows into the design analysis and plan
    # (not only the decision points). Reads the `workshop` records for the `selected` lenses. Graceful
    # "None recorded" when absent. Pure + deterministic; no network/LLM; markdownlint-safe.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$ArtifactPath
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('## Lens Decisions (recorded in the workshop)')
    [void]$sb.AppendLine('')

    $doc = $null
    if (-not [string]::IsNullOrWhiteSpace($ArtifactPath) -and (Test-Path -LiteralPath $ArtifactPath -PathType Leaf)) {
        try { $doc = Get-Content -LiteralPath $ArtifactPath -Raw -Encoding UTF8 | ConvertFrom-Json }
        catch { $doc = $null }
    }

    $selected = @()
    if ($null -ne $doc -and $doc.PSObject.Properties['selected']) {
        $selected = @($doc.selected | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    $workshop = if ($null -ne $doc -and $doc.PSObject.Properties['workshop']) { $doc.workshop } else { $null }

    if ($selected.Count -eq 0 -or $null -eq $workshop) {
        [void]$sb.AppendLine('*None recorded* (no workshop decisions in the intake artifact).')
        return $sb.ToString().TrimEnd()
    }

    foreach ($id in $selected) {
        $rec = if ($workshop.PSObject.Properties[$id]) { $workshop.$id } else { $null }
        $decision = if ($null -ne $rec -and $rec.PSObject.Properties['decision'] -and -not [string]::IsNullOrWhiteSpace([string]$rec.decision)) { [string]$rec.decision } else { '*not recorded*' }
        $depth = if ($null -ne $rec -and $rec.PSObject.Properties['depth'] -and -not [string]::IsNullOrWhiteSpace([string]$rec.depth)) { [string]$rec.depth } else { 'unknown' }
        [void]$sb.AppendLine(('- **{0}** (depth: {1}): {2}' -f $id, $depth, $decision))
    }

    return $sb.ToString().TrimEnd()
}

function Get-SpecrewLensDiagramType {
    # Iteration 8 T001 (FR-030, Amendment A5): read the per-lens diagram vocabulary
    # (diagram-vocabulary.json, a sibling to applicability-map.json) and return the diagram type + default
    # render form for a lens, so a lens's workshop discussion can be made concrete with its native diagram.
    # Graceful $null when the catalog dir, the file, or the lens entry is absent. Pure + deterministic; no
    # network/LLM. index.yml stays pure (the vocabulary is a decoupled sibling).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$LensId,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$CatalogDir
    )

    if ([string]::IsNullOrWhiteSpace($LensId) -or [string]::IsNullOrWhiteSpace($CatalogDir)) { return $null }
    $path = Join-Path $CatalogDir 'diagram-vocabulary.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }

    $doc = $null
    try { $doc = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { return $null }
    if ($null -eq $doc) { return $null }

    $key = $LensId.Trim()
    foreach ($group in @('lenses', 'cross_cutting')) {
        if ($doc.PSObject.Properties[$group] -and $doc.$group.PSObject.Properties[$key]) {
            $entry = $doc.$group.$key
            $dt = if ($entry.PSObject.Properties['diagram_type']) { [string]$entry.diagram_type } else { $null }
            $rf = if ($entry.PSObject.Properties['render_form']) { [string]$entry.render_form } else { $null }
            return [pscustomobject]@{ LensId = $key; DiagramType = $dt; RenderForm = $rf }
        }
    }
    return $null
}

function Format-SpecrewWorkshopVisual {
    # Iteration 8 T002 (FR-031/FR-033, Amendment A5): the deterministic emit half of the visuals whiteboard.
    # The agent authors the diagram CONTENT (behavioral); THIS surfaces it in one of three tiers:
    #   inline    -> a fenced block for quick console display (mermaid/text fence; a table is emitted raw)
    #   temp      -> writes Content to DestinationPath (under .specrew/workshop-visuals/) and returns a
    #                clickable file:/// reference (FR-028 console form — forward slashes)
    #   persisted -> a keeper: mermaid/ascii/table return the inline block to embed in the design doc;
    #                svg/html are written to DestinationPath and returned as a markdown link (FR-028 persisted)
    # Pure for inline; writes a file for temp / persisted-svg-html. LLM/network-free. Throws CLEARLY when a
    # destination is required but absent (no silent no-op).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Content,
        [Parameter(Mandatory = $true)][ValidateSet('mermaid', 'ascii', 'table', 'svg', 'html')][string]$RenderForm,
        [Parameter(Mandatory = $true)][ValidateSet('inline', 'temp', 'persisted')][string]$Tier,
        [AllowNull()][string]$DestinationPath
    )

    $fence = {
        param($c, $rf)
        switch ($rf) {
            'mermaid' { "``````mermaid`n$c`n``````" }
            'table' { $c }
            default { "``````text`n$c`n``````" }
        }
    }

    if ($Tier -eq 'inline') { return (& $fence $Content $RenderForm) }

    if ($Tier -eq 'persisted') {
        if ($RenderForm -in @('svg', 'html')) {
            if ([string]::IsNullOrWhiteSpace($DestinationPath)) { throw 'Format-SpecrewWorkshopVisual: persisted svg/html requires -DestinationPath.' }
            $pdir = Split-Path -Parent $DestinationPath
            if (-not [string]::IsNullOrWhiteSpace($pdir) -and -not (Test-Path -LiteralPath $pdir -PathType Container)) { $null = New-Item -ItemType Directory -Path $pdir -Force }
            [System.IO.File]::WriteAllText($DestinationPath, $Content, [System.Text.UTF8Encoding]::new($false))
            return ('[diagram]({0})' -f ($DestinationPath -replace '\\', '/'))
        }
        return (& $fence $Content $RenderForm)
    }

    # temp tier
    if ([string]::IsNullOrWhiteSpace($DestinationPath)) { throw 'Format-SpecrewWorkshopVisual: temp tier requires -DestinationPath (under .specrew/workshop-visuals/).' }
    $tdir = Split-Path -Parent $DestinationPath
    if (-not [string]::IsNullOrWhiteSpace($tdir) -and -not (Test-Path -LiteralPath $tdir -PathType Container)) { $null = New-Item -ItemType Directory -Path $tdir -Force }
    [System.IO.File]::WriteAllText($DestinationPath, $Content, [System.Text.UTF8Encoding]::new($false))
    return ('file:///{0}' -f ($DestinationPath -replace '\\', '/'))
}

function Format-SpecrewVisualIntakeReference {
    # Iteration 8 T003 (FR-032, Amendment A5): the bring-your-own half of the bidirectional intake. Records a
    # human-provided artifact (an existing diagram, doc, Figma export, or whiteboard photo) as a referenced
    # design input — returns a clickable file:/// reference for the path (FR-028 console form), with an
    # optional note. Accept-a-path/image only (no fetch/API). Graceful $null when the path is empty.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$ArtifactPath,
        [AllowNull()][AllowEmptyString()][string]$Note
    )

    if ([string]::IsNullOrWhiteSpace($ArtifactPath)) { return $null }
    $ref = 'file:///{0}' -f ($ArtifactPath.Trim() -replace '\\', '/')
    if (-not [string]::IsNullOrWhiteSpace($Note)) { return ('{0} — {1}' -f $ref, $Note.Trim()) }
    return $ref
}

function Format-SpecrewApplicableLensesSection {
    # Iteration 4 T004 + Iteration 5 T002 (FR-009): render the "## Applicable Lenses" markdown
    # section from the selector. Read-only; graceful degradation to "none available" when the map or
    # answers are absent. When -CatalogDir (absolute path to the lens files) is supplied, ENRICH each
    # selected lens with its Design Decision Points (via Get-SpecrewLensDecisionPoints) plus an
    # "Addressed:" coverage placeholder the author fills by pointing into the option comparison, so
    # the analysis is genuinely lens-informed (FR-009) and the FR-026 gate has a coverage entry to
    # check. With no -CatalogDir the legacy name-list render is preserved (back-compat).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Map,
        [Parameter(Mandatory = $true)][AllowNull()]$Answers,
        [string]$CatalogRelativeDir = 'extensions/specrew-speckit/knowledge/design-lenses',
        [AllowNull()][AllowEmptyString()][string]$CatalogDir
    )

    $sel = Get-SpecrewLensSelection -Map $Map -Answers $Answers
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('## Applicable Lenses') | Out-Null
    $lines.Add('') | Out-Null

    if (@($sel.selected).Count -eq 0) {
        $lines.Add('None available - no design-lens catalog or no recorded questionnaire answers for this project.') | Out-Null
        return (($lines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
    }

    $lines.Add('Selected by the applicability questionnaire (recorded in `lens-applicability.json`):') | Out-Null
    $lines.Add('') | Out-Null
    $rel = $CatalogRelativeDir.TrimEnd('/')
    $enrich = -not [string]::IsNullOrWhiteSpace($CatalogDir)
    foreach ($id in $sel.selected) {
        $lines.Add(('- **{0}** - `{1}/{2}.md`' -f $id, $rel, $id)) | Out-Null
        if ($enrich) {
            $points = @(Get-SpecrewLensDecisionPoints -LensId $id -CatalogDir $CatalogDir)
            if ($points.Count -gt 0) {
                $lines.Add(('  - Decision points: {0}' -f ($points -join '; '))) | Out-Null
            }
            $lines.Add('  - Addressed: <how these decision points shaped the option comparison — name the option(s) and Trade-offs>') | Out-Null
        }
    }

    if (@($sel.excluded).Count -gt 0) {
        $notSel = (@($sel.excluded) | ForEach-Object { '{0} ({1})' -f $_.id, ($_.reason -replace "gated by '", '' -replace "' = ", '=') }) -join ', '
        $lines.Add('') | Out-Null
        $lines.Add(('*Not selected: {0}.*' -f $notSel)) | Out-Null
    }

    return (($lines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
}
