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

function Format-SpecrewApplicableLensesSection {
    # T004: render the "## Applicable Lenses" markdown section from the selector. Read-only; graceful
    # degradation to "none available" when the map or answers are absent.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Map,
        [Parameter(Mandatory = $true)][AllowNull()]$Answers,
        [string]$CatalogRelativeDir = 'extensions/specrew-speckit/knowledge/design-lenses'
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
    foreach ($id in $sel.selected) {
        $lines.Add(('- **{0}** - `{1}/{2}.md`' -f $id, $rel, $id)) | Out-Null
    }

    if (@($sel.excluded).Count -gt 0) {
        $notSel = (@($sel.excluded) | ForEach-Object { '{0} ({1})' -f $_.id, ($_.reason -replace "gated by '", '' -replace "' = ", '=') }) -join ', '
        $lines.Add('') | Out-Null
        $lines.Add(('*Not selected: {0}.*' -f $notSel)) | Out-Null
    }

    return (($lines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
}
