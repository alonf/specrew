[CmdletBinding()]
param(
    # The repository whose lens files are measured. Defaults to this checkout.
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

# Feature 205 (proposal 220, iteration 2): the workshop length budget and the question consumers.
#
# (a) Length (FR-028, SC-007). For the reference profile (product-domain, the agenda, the always-on lenses from
#     applicability-map.json, code-implementation, security-compliance, data-storage, integration-api) the test
#     computes, at Light, Standard and Deep: must-answer decision points, minimum typed replies and recommendation
#     lines. It fails when Light goes over 51 points or 18 replies, and when any other number differs from the value
#     recorded below. A changed number is accepted only by updating its recorded value in the same change.
# (b) Consumers (FR-029, FR-026, SC-008). Every suffix names an existing `## Problem Context` line in the spec template
#     or a later lens; every hand-forward line names an earlier lens and a key that lens defines; every recommendation
#     has a reason; no question is added without a suffix.
#
# Self-tests over scratch fixtures run first, so every check is proven able to fail, and every problem is reported in
# one run with its fix.
#
# How an item is counted (the baseline model of the iteration 002 research page, lens files at d4c11236):
# - A decision item is a bullet or numbered item under `### Problem questions` or `### Solution questions` inside
#   `## Design Decision Points`.
# - An item with no suffix, or with the suffix "— Light: ask → ...", is a must-answer point at every depth.
# - An item with the suffix "— Light: recommend "<answer>" (<reason>) → ..." is a recommendation line at Light and a
#   must-answer point at Standard and Deep.
# - A hand-forward line (under `## Handed Forward From Earlier Lenses`) is a recommendation line at every depth. It
#   names the earlier lens that asked the question and the answer's key, which that lens defines as "(`key`)" on the
#   item (product-domain's areas 9 to 14; the observability placement ruling of 2026-11-13 for the others).
# - Typed replies: product-domain 1, the agenda 1, and each technical lens 2 when it has a must-answer point (the
#   answer and "move on"), 1 when it shows only recommendation lines ("accept"), 0 when it shows nothing. A lens's
#   recommendation block is closed by the same reply as its answers.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:LensCatalogRelative = 'extensions/specrew-speckit/knowledge/design-lenses'
$script:SpecTemplateRelative = 'templates/specify/templates/spec-template.md'
$script:ProductDomainId = 'product-domain'
$script:AgendaId = 'agenda'
$script:HandForwardHeading = 'Handed Forward From Earlier Lenses'
$script:Depths = @('Light', 'Standard', 'Deep')

# The reference profile: product-domain, the agenda, the always-on lenses (read from applicability-map.json), then these.
$script:ProfileExtraLenses = @('code-implementation', 'security-compliance', 'data-storage', 'integration-api')

# FR-028 caps at Light.
$script:LightCaps = [ordered]@{ Points = 51; Replies = 18 }

# The recorded numbers. Light points and replies are held by the caps; every other number must equal its record.
$script:Recorded = [ordered]@{
    Light    = [ordered]@{ Points = 51; Replies = 16; RecLines = 21 }
    Standard = [ordered]@{ Points = 66; Replies = 16; RecLines = 6 }
    Deep     = [ordered]@{ Points = 66; Replies = 16; RecLines = 6 }
}

# Decision items without a suffix, per lens, at d4c11236 (iteration 001's extractor counts plus product-domain's 8
# numbered areas). An item beyond these must carry a suffix that names its consumer (FR-029).
$script:UnsuffixedBaseline = [ordered]@{
    'product-domain' = 8; 'requirements-nfr' = 6; 'ui-ux' = 6; 'security-compliance' = 6; 'data-storage' = 7
    'integration-api' = 7; 'devops-operations' = 7; 'architecture-core' = 4; 'component-design' = 5
    'observability-resilience' = 6; 'code-implementation' = 7
}

# The suffix and hand-forward grammar (plan, "The question suffix"). One physical line, at the end of its item.
$script:SuffixMarker = ' — Light:'
$script:SuffixPattern = ' — Light: (?:(?<ask>ask)|recommend "(?<answer>[^"]+)" \((?<reason>[^()]*\S[^()]*)\)) → (?<consumer>\S.*?)\s*$'
$script:HandForwardPattern = '^\s*[-*]\s+(?<source>[a-z][a-z0-9-]*) `(?<key>[^`]+)` — recommend "(?<answer>[^"]+)" \((?<reason>[^()]*\S[^()]*)\) → (?<consumer>\S.*?)\s*$'
$script:ConsumerSpecPattern = '^spec\.md Problem Context: (?<name>\S.*)$'
$script:ConsumerLensPattern = '^lens: (?<lens>[a-z][a-z0-9-]*)$'
$script:AreaKeyPattern = '\(`(?<key>[a-z][a-z0-9_]*)`\)'

#region Assertion and report helpers

$script:SelfTestFailures = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host "PASS: $Message" -ForegroundColor Green }
    else { Write-Host "FAIL: $Message" -ForegroundColor Red; $script:SelfTestFailures++ }
}

function New-Problem {
    param([string]$Path, [int]$Line, [string]$Expected, [string]$Found, [string]$Fix)
    [pscustomobject]@{ Path = $Path; Line = $Line; Expected = $Expected; Found = $Found; Fix = $Fix }
}

function Format-Problem {
    param($Problem)
    '{0}:{1}: expected {2}; found {3}; fix: {4}' -f $Problem.Path, $Problem.Line, $Problem.Expected, $Problem.Found, $Problem.Fix
}

#endregion

#region Reading the lens files

function Get-NormalizedLines {
    param([string]$Path)
    $text = [IO.File]::ReadAllText($Path) -replace "`r`n", "`n"
    return , ($text.TrimEnd("`n") -split "`n")
}

function Get-SectionRange {
    # The line range (0-based, End exclusive) of a `## <Heading>` section, or $null.
    param([string[]]$Lines, [string]$Heading)
    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match ('^##\s+{0}\s*$' -f [regex]::Escape($Heading))) { $start = $i; break } }
    if ($start -lt 0) { return $null }
    $end = $Lines.Count
    for ($i = $start + 1; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match '^##\s+') { $end = $i; break } }
    return [pscustomobject]@{ Start = $start; End = $end }
}

function Get-LensItems {
    # The decision items of a lens file, each with its physical lines (number + text), in reading order.
    param([string[]]$Lines)
    $items = [Collections.Generic.List[object]]::new()
    $range = Get-SectionRange -Lines $Lines -Heading 'Design Decision Points'
    if ($null -eq $range) { return , $items.ToArray() }
    $inQuestions = $false
    $current = $null
    for ($i = $range.Start + 1; $i -lt $range.End; $i++) {
        $line = $Lines[$i]
        if ($line -match '^###\s+(Problem|Solution) questions\s*$') { $inQuestions = $true; $current = $null; continue }
        if ($line -match '^###\s') { $inQuestions = $false; $current = $null; continue }
        if (-not $inQuestions) { continue }
        if ($line -match '^\s*([-*]|\d+\.)\s+') {
            $current = [pscustomobject]@{ Lines = [Collections.Generic.List[object]]::new() }
            $current.Lines.Add([pscustomobject]@{ Number = $i + 1; Text = $line })
            $items.Add($current)
            continue
        }
        if ($null -ne $current -and $line -match '^\s+\S') { $current.Lines.Add([pscustomobject]@{ Number = $i + 1; Text = $line }); continue }
        $current = $null
    }
    return , $items.ToArray()
}

function Get-HandForwardLines {
    # Every non-blank line of the hand-forward section, with its number.
    param([string[]]$Lines)
    $range = Get-SectionRange -Lines $Lines -Heading $script:HandForwardHeading
    if ($null -eq $range) { return @() }
    $found = [Collections.Generic.List[object]]::new()
    for ($i = $range.Start + 1; $i -lt $range.End; $i++) {
        if ($Lines[$i] -match '^\s*[-*]\s+') { $found.Add([pscustomobject]@{ Number = $i + 1; Text = $Lines[$i] }) }
    }
    return $found.ToArray()
}

function Get-ItemSuffix {
    # Classifies an item: Kind none | ask | recommend | malformed, with the parsed parts and the problem when malformed.
    param($Item)
    $markerLines = @($Item.Lines | Where-Object { $_.Text.Contains($script:SuffixMarker) })
    $joined = ($Item.Lines | ForEach-Object { $_.Text.Trim() }) -join ' '
    if ($markerLines.Count -eq 0) {
        if ($joined.Contains($script:SuffixMarker)) {
            return [pscustomobject]@{ Kind = 'malformed'; Line = $Item.Lines[0].Number; Problem = 'the suffix split across lines'; Fix = 'keep " — Light: ... → <consumer>" on one line at the end of the item' }
        }
        return [pscustomobject]@{ Kind = 'none'; Line = $Item.Lines[0].Number }
    }
    $suffixLine = $markerLines[-1]
    $text = $suffixLine.Text.Substring($suffixLine.Text.LastIndexOf($script:SuffixMarker))
    $match = [regex]::Match($text, '^' + $script:SuffixPattern)
    if (-not $match.Success) {
        $problem = if ($text -match ' — Light: recommend "[^"]+"\s*→') { 'a recommendation with no reason' }
        elseif ($text -notmatch '→') { 'a suffix with no consumer on its line (split, or missing)' }
        else { 'a suffix that does not follow the form' }
        return [pscustomobject]@{ Kind = 'malformed'; Line = $suffixLine.Number; Problem = $problem; Fix = 'use " — Light: ask → <consumer>" or " — Light: recommend "<answer>" (<reason>) → <consumer>"' }
    }
    if ($suffixLine.Number -ne $Item.Lines[-1].Number) {
        return [pscustomobject]@{ Kind = 'malformed'; Line = $suffixLine.Number; Problem = 'text after the suffix on a later line'; Fix = 'end the item with its suffix' }
    }
    $kind = if ($match.Groups['ask'].Success) { 'ask' } else { 'recommend' }
    return [pscustomobject]@{ Kind = $kind; Line = $suffixLine.Number; Answer = $match.Groups['answer'].Value; Reason = $match.Groups['reason'].Value; Consumer = $match.Groups['consumer'].Value }
}

function Read-Catalog {
    # index.yml lens ids in order, with their files. A small reader: the index is a flat list of id/file pairs.
    param([string]$Root)
    $indexPath = Join-Path $Root "$($script:LensCatalogRelative)/index.yml"
    $lenses = [Collections.Generic.List[object]]::new()
    $current = $null
    foreach ($line in (Get-NormalizedLines -Path $indexPath)) {
        if ($line -match '^\s*-\s+id:\s*(\S+)\s*$') { $current = [pscustomobject]@{ id = $Matches[1]; file = "$($Matches[1]).md" }; $lenses.Add($current); continue }
        if ($null -ne $current -and $line -match '^\s+file:\s*(\S+)\s*$') { $current.file = $Matches[1] }
    }
    return , $lenses.ToArray()
}

function Get-ReferenceProfile {
    param([string]$Root)
    $map = Get-Content -LiteralPath (Join-Path $Root "$($script:LensCatalogRelative)/applicability-map.json") -Raw | ConvertFrom-Json
    $profileIds = [Collections.Generic.List[string]]::new()
    foreach ($id in @($script:ProductDomainId, $script:AgendaId) + @($map.always_on) + $script:ProfileExtraLenses) {
        if (-not $profileIds.Contains([string]$id)) { $profileIds.Add([string]$id) }
    }
    return , $profileIds.ToArray()
}

function Get-ProblemContextNames {
    param([string]$Root)
    $path = Join-Path $Root $script:SpecTemplateRelative
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    $lines = Get-NormalizedLines -Path $path
    $range = Get-SectionRange -Lines $lines -Heading 'Problem Context'
    if ($null -eq $range) { return @() }
    $names = [Collections.Generic.List[string]]::new()
    for ($i = $range.Start + 1; $i -lt $range.End; $i++) {
        if ($lines[$i] -match '^\s*[-*]\s+\*\*(?<name>[^*]+?):?\*\*') { $names.Add($Matches['name'].Trim().TrimEnd(':')) }
    }
    return , $names.ToArray()
}

#endregion

#region (a) Length

function Measure-WorkshopLength {
    # Per depth, per lens in the profile: must-answer points, typed replies, recommendation lines.
    param([string]$Root, [string[]]$ProfileIds)
    $catalog = Read-Catalog -Root $Root
    $rows = [Collections.Generic.List[object]]::new()
    foreach ($id in $ProfileIds) {
        $counts = [ordered]@{}
        foreach ($depth in $script:Depths) { $counts[$depth] = [ordered]@{ Points = 0; Replies = 0; RecLines = 0 } }
        if ($id -eq $script:AgendaId) {
            foreach ($depth in $script:Depths) { $counts[$depth].Replies = 1 }
            $rows.Add([pscustomobject]@{ Lens = $id; Counts = $counts }); continue
        }
        $entry = @($catalog | Where-Object { $_.id -eq $id })
        if ($entry.Count -eq 0) { throw "reference profile lens '$id' is not in index.yml" }
        $lines = Get-NormalizedLines -Path (Join-Path $Root "$($script:LensCatalogRelative)/$($entry[0].file)")
        $items = Get-LensItems -Lines $lines
        $handForward = @(Get-HandForwardLines -Lines $lines)
        foreach ($item in $items) {
            $suffix = Get-ItemSuffix -Item $item
            foreach ($depth in $script:Depths) {
                if ($suffix.Kind -eq 'recommend' -and $depth -eq 'Light') { $counts[$depth].RecLines++ } else { $counts[$depth].Points++ }
            }
        }
        foreach ($depth in $script:Depths) {
            $counts[$depth].RecLines += $handForward.Count
            $c = $counts[$depth]
            $c.Replies = if ($id -eq $script:ProductDomainId) { 1 } elseif ($c.Points -gt 0) { 2 } elseif ($c.RecLines -gt 0) { 1 } else { 0 }
        }
        $rows.Add([pscustomobject]@{ Lens = $id; Counts = $counts })
    }
    $totals = [ordered]@{}
    foreach ($depth in $script:Depths) {
        $totals[$depth] = [ordered]@{
            Points   = ($rows | ForEach-Object { $_.Counts[$depth].Points } | Measure-Object -Sum).Sum
            Replies  = ($rows | ForEach-Object { $_.Counts[$depth].Replies } | Measure-Object -Sum).Sum
            RecLines = ($rows | ForEach-Object { $_.Counts[$depth].RecLines } | Measure-Object -Sum).Sum
        }
    }
    return [pscustomobject]@{ Rows = $rows.ToArray(); Totals = $totals }
}

function Test-LengthBudget {
    param([System.Collections.IDictionary]$Totals, [System.Collections.IDictionary]$Caps, [System.Collections.IDictionary]$Recorded, [string]$TestPath)
    $problems = [Collections.Generic.List[object]]::new()
    foreach ($name in @('Points', 'Replies')) {
        if ($Totals['Light'][$name] -gt $Caps[$name]) {
            $problems.Add((New-Problem $TestPath 0 "Light $name at most $($Caps[$name]) (FR-028 cap)" "$($Totals['Light'][$name])" 'move added questions to recommendation lines, or drop them; the cap is the spec''s, not this test''s'))
        }
    }
    foreach ($depth in $script:Depths) {
        foreach ($name in @('Points', 'Replies', 'RecLines')) {
            if ($depth -eq 'Light' -and $name -in @('Points', 'Replies')) { continue }
            if ($Totals[$depth][$name] -ne $Recorded[$depth][$name]) {
                $problems.Add((New-Problem $TestPath 0 "$depth $name = $($Recorded[$depth][$name]) (recorded)" "$($Totals[$depth][$name])" 'if the change is intended, update the recorded value in this test and in plan.md in the same change'))
            }
        }
    }
    return $problems.ToArray()
}

#endregion

#region (b) Consumers

function Test-Consumer {
    param([string]$Consumer, [string]$LensId, [string[]]$Order, [string[]]$ContextNames)
    $spec = [regex]::Match($Consumer, $script:ConsumerSpecPattern)
    if ($spec.Success) {
        if ($ContextNames -contains $spec.Groups['name'].Value.Trim()) { return $null }
        return "spec template ## Problem Context has no line '$($spec.Groups['name'].Value.Trim())'"
    }
    $lens = [regex]::Match($Consumer, $script:ConsumerLensPattern)
    if ($lens.Success) {
        $target = $lens.Groups['lens'].Value
        $at = [array]::IndexOf($Order, $target)
        if ($at -lt 0) { return "no lens '$target' in index.yml" }
        if ($at -le [array]::IndexOf($Order, $LensId)) { return "lens '$target' does not come after $LensId" }
        return $null
    }
    return "'$Consumer' is neither 'spec.md Problem Context: <line>' nor 'lens: <later lens>'"
}

function Test-Consumers {
    param([string]$Root, [System.Collections.IDictionary]$Baseline)
    $problems = [Collections.Generic.List[object]]::new()
    $catalog = Read-Catalog -Root $Root
    $order = @($catalog | ForEach-Object { $_.id })
    $contextNames = Get-ProblemContextNames -Root $Root
    $consumerFix = 'name a line under ## Problem Context in ' + $script:SpecTemplateRelative + ' (add it there), or a later lens as "lens: <id>"'

    # Each lens's answer keys, from its decision items: "(`key`)".
    $keysByLens = @{}
    foreach ($lens in $catalog) {
        $keys = [Collections.Generic.List[string]]::new()
        foreach ($item in (Get-LensItems -Lines (Get-NormalizedLines -Path (Join-Path $Root "$($script:LensCatalogRelative)/$($lens.file)")))) {
            $joined = ($item.Lines | ForEach-Object { $_.Text }) -join ' '
            foreach ($m in [regex]::Matches($joined, $script:AreaKeyPattern)) { $keys.Add($m.Groups['key'].Value) }
        }
        $keysByLens[$lens.id] = $keys
    }

    foreach ($lens in $catalog) {
        $relative = "$($script:LensCatalogRelative)/$($lens.file)"
        $lines = Get-NormalizedLines -Path (Join-Path $Root $relative)
        $unsuffixed = 0
        $lastUnsuffixedLine = 0
        foreach ($item in (Get-LensItems -Lines $lines)) {
            $suffix = Get-ItemSuffix -Item $item
            switch ($suffix.Kind) {
                'none' { $unsuffixed++; $lastUnsuffixedLine = $suffix.Line }
                'malformed' { $problems.Add((New-Problem $relative $suffix.Line 'a valid question suffix' $suffix.Problem $suffix.Fix)) }
                default {
                    $why = Test-Consumer -Consumer $suffix.Consumer -LensId $lens.id -Order $order -ContextNames $contextNames
                    if ($why) { $problems.Add((New-Problem $relative $suffix.Line 'a consumer that exists (FR-029)' $why $consumerFix)) }
                }
            }
        }
        if ($Baseline.Contains($lens.id) -and $unsuffixed -gt $Baseline[$lens.id]) {
            $problems.Add((New-Problem $relative $lastUnsuffixedLine "at most $($Baseline[$lens.id]) questions without a suffix (the d4c11236 baseline)" "$unsuffixed" 'give each added question its suffix: recommendation, reason and consumer (FR-026, FR-029)'))
        }
        foreach ($hf in (Get-HandForwardLines -Lines $lines)) {
            $match = [regex]::Match($hf.Text, $script:HandForwardPattern)
            if (-not $match.Success) {
                $found = if ($hf.Text -match 'recommend "[^"]+"\s*→') { 'a hand-forward with no reason' } else { 'a hand-forward line that does not follow the form' }
                $problems.Add((New-Problem $relative $hf.Number 'a valid hand-forward line' $found 'use "- <earlier lens> `<key>` — recommend "<earlier lens>: <answer>" (<reason>) → <consumer>"'))
                continue
            }
            $source = $match.Groups['source'].Value
            $key = $match.Groups['key'].Value
            $sourceAt = [array]::IndexOf($order, $source)
            if ($sourceAt -lt 0 -or $sourceAt -ge [array]::IndexOf($order, $lens.id)) {
                $found = if ($sourceAt -lt 0) { "no lens '$source' in index.yml" } else { "lens '$source' does not come before $($lens.id)" }
                $problems.Add((New-Problem $relative $hf.Number 'a source lens earlier in index.yml (FR-024)' $found 'hand an answer forward only from a lens that runs earlier'))
            }
            elseif (-not $keysByLens[$source].Contains($key)) {
                $problems.Add((New-Problem $relative $hf.Number "a key that $source defines (FR-024)" "'$key'" "name one of $($source)'s keys: $(@($keysByLens[$source]) -join ', '); or define it as (``$key``) on the question there"))
            }
            elseif (-not $match.Groups['answer'].Value.StartsWith("${source}: ")) {
                $problems.Add((New-Problem $relative $hf.Number "the answer shown as ""${source}: <answer>""" "'$($match.Groups['answer'].Value)'" 'name the source lens in the shown answer'))
            }
            $why = Test-Consumer -Consumer $match.Groups['consumer'].Value -LensId $lens.id -Order $order -ContextNames $contextNames
            if ($why) { $problems.Add((New-Problem $relative $hf.Number 'a consumer that exists (FR-029)' $why $consumerFix)) }
        }
    }
    return $problems.ToArray()
}

#endregion

#region Self-tests

function New-FixtureTree {
    # A three-lens catalog: product-domain (problem), beta-lens (both), gamma-lens (solution); profile = all three.
    param([string]$Root, [string]$ProductDomain, [string]$Beta, [string]$Gamma, [string]$Template)
    $catalog = Join-Path $Root $script:LensCatalogRelative
    New-Item -ItemType Directory -Force -Path $catalog, (Join-Path $Root (Split-Path $script:SpecTemplateRelative)) | Out-Null
    Set-Content -LiteralPath (Join-Path $catalog 'index.yml') -Value "lenses:`n  - id: product-domain`n    file: product-domain.md`n  - id: beta-lens`n    file: beta-lens.md`n  - id: gamma-lens`n    file: gamma-lens.md`n"
    Set-Content -LiteralPath (Join-Path $catalog 'applicability-map.json') -Value '{ "always_on": ["beta-lens", "gamma-lens"] }'
    Set-Content -LiteralPath (Join-Path $catalog 'product-domain.md') -Value $ProductDomain
    Set-Content -LiteralPath (Join-Path $catalog 'beta-lens.md') -Value $Beta
    Set-Content -LiteralPath (Join-Path $catalog 'gamma-lens.md') -Value $Gamma
    Set-Content -LiteralPath (Join-Path $Root $script:SpecTemplateRelative) -Value $Template
}

function Invoke-SelfTests {
    $savedExtra = $script:ProfileExtraLenses
    $script:ProfileExtraLenses = @()
    $fixtureProfile = @('product-domain', 'agenda', 'beta-lens', 'gamma-lens')
    $baseline = [ordered]@{ 'product-domain' = 1; 'beta-lens' = 2; 'gamma-lens' = 1 }
    $template = "# Spec`n`n## Problem Context`n`n- **Regulation and compliance**: the regime.`n- **Data inventory**: the data.`n`n## Requirements`n"
    $pdValid = @"
# PD

## Design Decision Points

### Problem questions

1. **Users** — who uses it.
2. **Compliance regime** (``compliance_regime``) — the regulation, or "none". — Light: ask → spec.md Problem Context: Regulation and compliance
3. **Data residency** (``data_residency``) — where data must stay. — Light: recommend "not stated" (nothing shows it) → spec.md Problem Context: Data inventory

### Solution questions

No solution questions: pre-technical.
"@
    $betaValid = @"
# B

## Design Decision Points

### Problem questions

- What data exists?
- How sensitive is it? — Light: recommend "as product-domain's regime implies" (the regime is already answered) → spec.md Problem Context: Data inventory
- Who reads it later? (``reader``) — Light: recommend "not stated" (nothing to infer it from) → lens: gamma-lens

### Solution questions

- Which store?

## Handed Forward From Earlier Lenses

- product-domain ``compliance_regime`` — recommend "product-domain: <its answer, or not stated>" (answered there) → spec.md Problem Context: Regulation and compliance
"@
    $gammaValid = "# G`n`n## Design Decision Points`n`n### Problem questions`n`nNo problem questions: solution lens.`n`n### Solution questions`n`n- Which protocol?`n`n## Handed Forward From Earlier Lenses`n`n- beta-lens ``reader`` — recommend `"beta-lens: <its answer, or not stated>`" (answered there) → spec.md Problem Context: Data inventory`n"

    $scratch = Join-Path ([IO.Path]::GetTempPath()) ("wlb-selftest-" + [guid]::NewGuid().ToString('N'))
    try {
        # The valid forms are accepted, and the counting model gives the expected numbers.
        $valid = Join-Path $scratch 'valid'
        New-FixtureTree -Root $valid -ProductDomain $pdValid -Beta $betaValid -Gamma $gammaValid -Template $template
        $consumerProblems = @(Test-Consumers -Root $valid -Baseline $baseline)
        Assert-True ($consumerProblems.Count -eq 0) "consumers: the valid suffix forms (ask; recommend → spec line; recommend → later lens; hand-forward) are accepted [found: $(($consumerProblems | ForEach-Object { Format-Problem $_ }) -join ' | ')]"
        $measured = Measure-WorkshopLength -Root $valid -ProfileIds $fixtureProfile
        $t = $measured.Totals
        # Light: pd 2 points (users, regime) + 1 rec; beta 2 points (data, store) + 2 rec + 1 hand-forward; gamma 1 point.
        Assert-True ($t.Light.Points -eq 5 -and $t.Light.RecLines -eq 5 -and $t.Light.Replies -eq 6) "length: Light counts recommendation lines apart from must-answer points (5/6/5, found $($t.Light.Points)/$($t.Light.Replies)/$($t.Light.RecLines))"
        Assert-True ($t.Standard.Points -eq 8 -and $t.Standard.RecLines -eq 2 -and $t.Standard.Replies -eq 6) "length: Standard asks the recommended items and keeps the hand-forwards as lines (8/6/2, found $($t.Standard.Points)/$($t.Standard.Replies)/$($t.Standard.RecLines))"
        Assert-True ($t.Deep.Points -eq $t.Standard.Points -and $t.Deep.RecLines -eq $t.Standard.RecLines) 'length: Deep counts as Standard in this iteration'

        # A lens that shows only recommendation lines needs one reply ("accept"); one with nothing needs none.
        $recOnly = Join-Path $scratch 'reconly'
        $gammaRecOnly = "# G`n`n## Design Decision Points`n`n### Problem questions`n`n- Who operates it? — Light: recommend `"not stated`" (never a guess) → spec.md Problem Context: Data inventory`n`n### Solution questions`n`nNo solution questions: none.`n"
        New-FixtureTree -Root $recOnly -ProductDomain $pdValid -Beta $betaValid -Gamma $gammaRecOnly -Template $template
        $g = @((Measure-WorkshopLength -Root $recOnly -ProfileIds $fixtureProfile).Rows | Where-Object { $_.Lens -eq 'gamma-lens' })[0]
        Assert-True ($g.Counts.Light.Replies -eq 1 -and $g.Counts.Standard.Replies -eq 2) 'length: a recommendation-only lens takes one reply at Light, two once it asks'

        # The caps: Light over 51 points or 18 replies fails, each on its own.
        $caps = [ordered]@{ Points = 51; Replies = 18 }
        $ok = [ordered]@{ Light = [ordered]@{ Points = 51; Replies = 16; RecLines = 18 }; Standard = [ordered]@{ Points = 63; Replies = 16; RecLines = 6 }; Deep = [ordered]@{ Points = 63; Replies = 16; RecLines = 6 } }
        $overPoints = [ordered]@{ Light = [ordered]@{ Points = 52; Replies = 16; RecLines = 18 }; Standard = $ok.Standard; Deep = $ok.Deep }
        $overReplies = [ordered]@{ Light = [ordered]@{ Points = 51; Replies = 19; RecLines = 18 }; Standard = $ok.Standard; Deep = $ok.Deep }
        Assert-True (@(Test-LengthBudget -Totals $ok -Caps $caps -Recorded $ok -TestPath 'x').Count -eq 0) 'length: numbers at their caps and records pass'
        $p = @(Test-LengthBudget -Totals $overPoints -Caps $caps -Recorded $ok -TestPath 'x')
        Assert-True ($p.Count -eq 1 -and $p[0].Expected -match 'Light Points at most 51') 'length: Light over 51 must-answer points fails'
        $p = @(Test-LengthBudget -Totals $overReplies -Caps $caps -Recorded $ok -TestPath 'x')
        Assert-True ($p.Count -eq 1 -and $p[0].Expected -match 'Light Replies at most 18') 'length: Light over 18 typed replies fails'
        $underLight = [ordered]@{ Light = [ordered]@{ Points = 49; Replies = 15; RecLines = 18 }; Standard = $ok.Standard; Deep = $ok.Deep }
        Assert-True (@(Test-LengthBudget -Totals $underLight -Caps $caps -Recorded $ok -TestPath 'x').Count -eq 0) 'length: Light points and replies under their caps pass'

        # Every other number must equal its record, and every difference is reported in one run.
        $drift = [ordered]@{ Light = [ordered]@{ Points = 51; Replies = 16; RecLines = 17 }; Standard = [ordered]@{ Points = 64; Replies = 16; RecLines = 6 }; Deep = [ordered]@{ Points = 63; Replies = 17; RecLines = 5 } }
        $p = @(Test-LengthBudget -Totals $drift -Caps $caps -Recorded $ok -TestPath 'x')
        Assert-True ($p.Count -eq 4) "length: Light recommendation lines and every Standard/Deep number must equal the record; all 4 differences reported in one run (found $($p.Count))"
        Assert-True (@($p | Where-Object { $_.Fix -match 'update the recorded value' }).Count -eq 4) 'length: each difference names the fix (update the record in the same change)'

        # Consumers: every failure shape, all reported in one run.
        $bad = Join-Path $scratch 'bad'
        $betaBad = @"
# B

## Design Decision Points

### Problem questions

- What data exists?
- Unknown section? — Light: recommend "x" (a reason) → spec.md Problem Context: Nowhere
- No reason? — Light: recommend "x" → spec.md Problem Context: Data inventory
- Split suffix? — Light: recommend "x" (a reason)
  → spec.md Problem Context: Data inventory
- Earlier lens? — Light: ask → lens: product-domain
- Missing lens? — Light: ask → lens: no-such-lens
- Not a consumer? — Light: ask → Plan Obligations
- Added without a suffix?

### Solution questions

- Which store?

## Handed Forward From Earlier Lenses

- product-domain ``budget_typo`` — recommend "product-domain: not stated" (answered there) → spec.md Problem Context: Data inventory
- product-domain ``compliance_regime`` — recommend "product-domain: not stated" → spec.md Problem Context: Data inventory
- gamma-lens ``reader`` — recommend "gamma-lens: not stated" (answered there) → spec.md Problem Context: Data inventory
- product-domain ``data_residency`` — recommend "not stated" (answered there) → spec.md Problem Context: Data inventory
"@
        New-FixtureTree -Root $bad -ProductDomain $pdValid -Beta $betaBad -Gamma $gammaValid -Template $template
        $p = @(Test-Consumers -Root $bad -Baseline $baseline)
        $text = ($p | ForEach-Object { Format-Problem $_ }) -join "`n"
        Assert-True ($text -match "no line 'Nowhere'") 'consumers: a spec.md Problem Context line that does not exist fails'
        Assert-True ($text -match 'a recommendation with no reason') 'consumers: a recommendation with no reason fails'
        Assert-True ($text -match 'no consumer on its line') 'consumers: a suffix split onto a second line fails'
        Assert-True ($text -match "lens 'product-domain' does not come after beta-lens") 'consumers: a consumer lens that is not later fails'
        Assert-True ($text -match "no lens 'no-such-lens'") 'consumers: a consumer lens that does not exist fails'
        Assert-True ($text -match "'Plan Obligations' is neither") 'consumers: "Plan Obligations" is not a consumer'
        Assert-True ($text -match 'at most 2 questions without a suffix') 'consumers: a question added without a suffix fails'
        Assert-True ($text -match "'budget_typo'") 'consumers: a hand-forward naming a key its source lens does not define fails'
        Assert-True ($text -match 'a hand-forward with no reason') 'consumers: a hand-forward with no reason fails'
        Assert-True ($text -match "lens 'gamma-lens' does not come before beta-lens") 'consumers: a hand-forward from a later lens fails'
        Assert-True ($text -match 'the answer shown as "product-domain: <answer>"') 'consumers: a hand-forward whose shown answer does not name its source fails'
        # The 12th: gamma-lens's otherwise valid hand-forward names beta-lens's key `reader`, which the bad beta-lens drops.
        Assert-True ($text -match "a key that beta-lens defines .*'reader'") 'consumers: a hand-forward whose key its source no longer defines fails'
        Assert-True ($p.Count -eq 12) "consumers: all 12 problems reported in one run (found $($p.Count))"
        Assert-True (@($p | Where-Object { -not $_.Fix -or $_.Line -le 0 }).Count -eq 0) 'consumers: every problem names its line and its fix'
    }
    finally {
        $script:ProfileExtraLenses = $savedExtra
        if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
    }
}

#endregion

Write-Host '--- workshop-length-budget: self-tests ---'
Invoke-SelfTests
if ($script:SelfTestFailures -gt 0) {
    Write-Host ("workshop-length-budget: {0} self-test(s) FAILED; the repository check was not run." -f $script:SelfTestFailures) -ForegroundColor Red
    exit 1
}

Write-Host '--- workshop-length-budget: repository check ---'
$testRelative = 'tests/unit/workshop-length-budget.tests.ps1'
$profileIds = Get-ReferenceProfile -Root $RepoRoot
$measured = Measure-WorkshopLength -Root $RepoRoot -ProfileIds $profileIds
Write-Host ("Reference profile: {0}" -f ($profileIds -join ', '))
Write-Host 'Per lens (Light points/replies/rec | Standard | Deep):'
foreach ($row in $measured.Rows) {
    $cells = $script:Depths | ForEach-Object { '{0}/{1}/{2}' -f $row.Counts[$_].Points, $row.Counts[$_].Replies, $row.Counts[$_].RecLines }
    Write-Host ('  {0,-26} {1}' -f $row.Lens, ($cells -join ' | '))
}
foreach ($depth in $script:Depths) {
    $t = $measured.Totals[$depth]; $r = $script:Recorded[$depth]
    Write-Host ('{0,-8} must-answer points {1} (recorded {2}), typed replies {3} (recorded {4}), recommendation lines {5} (recorded {6})' -f $depth, $t.Points, $r.Points, $t.Replies, $r.Replies, $t.RecLines, $r.RecLines)
}
Write-Host ('Light caps: {0} points, {1} replies' -f $script:LightCaps.Points, $script:LightCaps.Replies)

$problems = @(Test-LengthBudget -Totals $measured.Totals -Caps $script:LightCaps -Recorded $script:Recorded -TestPath $testRelative) + @(Test-Consumers -Root $RepoRoot -Baseline $script:UnsuffixedBaseline)
if ($problems.Count -gt 0) {
    Write-Host ('workshop-length-budget: {0} problem(s):' -f $problems.Count) -ForegroundColor Red
    foreach ($problem in $problems) { Write-Host ('  ' + (Format-Problem $problem)) -ForegroundColor Red }
    exit 1
}
Write-Host 'workshop-length-budget: all checks passed' -ForegroundColor Green
exit 0
