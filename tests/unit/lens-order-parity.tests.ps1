[CmdletBinding()]
param(
    # The repository whose lens order is checked. Defaults to this checkout.
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

# Feature 205 (proposal 220, iteration 1): index.yml is the only definition of the lens order and of each lens's
# space. This test proves every other surface agrees with it (FR-001), that every lens file tags its questions by
# space (FR-005), that the skill states index.yml wins (FR-018), and it reports EVERY mismatch in one run with the
# fix for each (FR-019). Self-tests over scratch fixtures run first, so the checks are proven able to fail.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:MinimumRunLength = 3
$script:LensCatalogRelative = 'extensions/specrew-speckit/knowledge/design-lenses'
$script:CopyRefreshFix = 'refresh the copies (writes inside this project only, never your home folder): ' +
    'pwsh -File extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1 -ProjectPath . -RefreshExisting; ' +
    'pwsh -File extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 -ProjectPath . ' +
    '(these also restamp .squad runtime files; review git status and commit only the copies you meant to refresh)'
$script:OrderFix = 'edit index.yml, or make this surface match it'

. (Join-Path $RepoRoot 'extensions/specrew-speckit/scripts/intake/helpers/Read-IntakeYaml.ps1')
. (Join-Path $RepoRoot 'scripts/internal/lens-applicability.ps1')

#region Surfaces named by this test

# Full surfaces: each must list exactly the index.yml lenses, in order. The region is the lines between Start
# (inclusive) and End (exclusive); Rows, when set, keeps only matching lines (e.g. table rows); Within, when set, keeps
# only its named group 'list' of the joined region. Each entry is read by the surface's own Item rule (capture group
# 1), never by a pattern built from index.yml, so an entry the catalog does not know (an extra lens, or one removed
# from the catalog but still listed) is seen and reported (round-1 review finding, FR-001 "no more and no fewer").
$script:KebabToken = '(?<![A-Za-z0-9_/.-])([a-z][a-z0-9]*(?:-[a-z0-9]+)+)(?![A-Za-z0-9_/.-])'
$script:FullSurfaces = @(
    @{ Name = 'workshop skill lens list'; Path = 'extensions/specrew-speckit/squad-templates/skills/design-workshop.md'; Start = 'The lenses live in'; End = '^\s*$'; Rows = $null; Within = $null; Item = '`([a-z][a-z0-9]*(?:-[a-z0-9]+)+)`' }
    @{ Name = 'methodology catalog tables (Band 1-3)'; Path = 'docs/methodology/design-workshop-methodology.md'; Start = '^\*\*Band 1'; End = '^## Lens Catalog Evolution'; Rows = '^\|\s*`[a-z][a-z0-9-]*`\s*\|'; Within = $null; Item = '^\|\s*`([a-z][a-z0-9-]*)`\s*\|' }
    @{ Name = 'methodology visual-vocabulary table'; Path = 'docs/methodology/design-workshop-methodology.md'; Start = 'Each lens has a native visual vocabulary'; End = '^The agent should offer to draw'; Rows = '^\|\s*`[a-z][a-z0-9-]*`\s*\|'; Within = $null; Item = '^\|\s*`([a-z][a-z0-9-]*)`\s*\|' }
    @{ Name = 'catalog README lens list'; Path = "$($script:LensCatalogRelative)/README.md"; Start = '^- `[a-z][a-z0-9-]*\.md` - '; End = '^\s*$'; Rows = $null; Within = $null; Item = '^- `([a-z][a-z0-9-]*)\.md` - ' }
    @{ Name = 'before-specify command lens list'; Path = 'extensions/specrew-speckit/commands/speckit.specrew-speckit.before-specify.md'; Start = 'Invoke the `specrew-design-workshop` skill'; End = '^\s*$'; Rows = $null; Within = 'as applicable:(?<list>.*?) last\.'; Item = $script:KebabToken }
)

# Runs that must differ from index.yml, each with its reason. A stale entry (matching no run) fails the test.
$script:Exemptions = @(
    @{ Path = 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'; Pattern = '\(\?:[a-z-]+\|'; Reason = 'Order has no meaning in a regex alternation; the file is owned by feature 203 T011 and is not edited here.' }
    @{ Path = 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1'; Pattern = 'workshop holds architecture-core, requirements-nfr, security-compliance, product-domain'; Reason = 'A comment naming lenses a workshop holds, not an order; the file is under active change in feature 203 (T008) and is not edited here. Temporary: after feature 203 merges, reorder the comment and remove this exemption.' }
    @{ Path = 'scripts/internal/continuous-co-review/worktree-reviewer.ps1'; Pattern = 'requirements/NFR, data-storage, security-compliance, integration/API'; Reason = 'The reviewer''s prompt text (a short-name lens list, recorded for iteration 3); feature 203''s folder, where a changed file can make the review launch refuse with a runtime-drift error (203 DRIFT-051). Not edited here.' }
)

# The shipped-text sweep: roots, file types, and the accepted exclusions (plan verdict 2026-11-10).
$script:SweepRoots = @('extensions', 'docs', 'scripts', 'templates', 'hosts')
$script:SweepExtensions = @('.md', '.ps1', '.psm1', '.psd1', '.json', '.yml', '.yaml')
$script:SweepExclusions = @('^specs/', '^proposals/', '^tests/', '^CHANGELOG\.md$', '^docs/release-notes-[^/]*\.md$', '^docs/beta[^/]*-findings\.md$', "^$([regex]::Escape($script:LensCatalogRelative))/index\.yml$")
$script:CodeExtensions = @('.ps1', '.psm1', '.psd1', '.json', '.yml', '.yaml')

# Sources and their deployed copies. Markdown copies are compared after their frontmatter (the deploy wrapper).
$script:SkillCopies = @(
    '.specify/extensions/specrew-speckit/squad-templates/skills/design-workshop.md'
    '.claude/skills/specrew-design-workshop/SKILL.md'
    '.agents/skills/specrew-design-workshop/SKILL.md'
    '.github/skills/specrew-design-workshop/SKILL.md'
    '.cursor/rules/specrew-design-workshop/SKILL.md'
)

# SC-002: the extractor's decision-point count per lens after this feature.
$script:ExpectedExtractorCounts = [ordered]@{
    'product-domain' = 0; 'requirements-nfr' = 6; 'ui-ux' = 6; 'security-compliance' = 6; 'data-storage' = 7
    'integration-api' = 7; 'devops-operations' = 7; 'architecture-core' = 4; 'component-design' = 5
    'observability-resilience' = 6; 'code-implementation' = 7
}

$script:SkillSentences = @('index.yml wins', 'a confirmed agenda keeps the order it was confirmed in')

#endregion

#region Assertion helpers

$script:SelfTestFailures = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host "PASS: $Message" -ForegroundColor Green }
    else { Write-Host "FAIL: $Message" -ForegroundColor Red; $script:SelfTestFailures++ }
}

function New-Mismatch {
    param([string]$Path, [int]$Line, [string]$Expected, [string]$Found, [string]$Fix)
    [pscustomobject]@{ Path = $Path; Line = $Line; Expected = $Expected; Found = $Found; Fix = $Fix }
}

function Format-Mismatch {
    param($Mismatch)
    '{0}:{1}: expected {2}; found {3}; fix: {4}' -f $Mismatch.Path, $Mismatch.Line, $Mismatch.Expected, $Mismatch.Found, $Mismatch.Fix
}

function Get-MismatchReport {
    # The lines the repository check prints when it fails: a count, then every mismatch with its fix (FR-019).
    param([object[]]$Mismatches)
    $list = @($Mismatches)
    if ($list.Count -eq 0) { return @() }
    @(('lens-order-parity: {0} mismatch(es):' -f $list.Count)) + @($list | ForEach-Object { '  ' + (Format-Mismatch $_) })
}

#endregion

#region Reading text

function Get-NormalizedLines {
    param([string]$Path)
    $text = [IO.File]::ReadAllText($Path) -replace "`r`n", "`n"
    return , ($text.TrimEnd("`n") -split "`n")
}

function Get-LensIdPattern {
    param([string[]]$LensIds)
    $alternation = ($LensIds | Sort-Object Length -Descending | ForEach-Object { [regex]::Escape($_) }) -join '|'
    return "(?<![A-Za-z0-9_-])(?:$alternation)(?![A-Za-z0-9_-])"
}

function Get-DistinctLensIds {
    # Lens ids in reading order, keeping the first occurrence of each.
    param([string[]]$Lines, [string]$Pattern)
    $seen = [Collections.Generic.List[string]]::new()
    foreach ($line in $Lines) {
        foreach ($match in [regex]::Matches($line, $Pattern)) {
            if (-not $seen.Contains($match.Value)) { $seen.Add($match.Value) }
        }
    }
    return , $seen.ToArray()
}

function Test-RelativeOrder {
    param([string[]]$Found, [string[]]$Order)
    $positions = @($Found | ForEach-Object { [array]::IndexOf($Order, $_) })
    for ($i = 1; $i -lt $positions.Count; $i++) {
        if ($positions[$i] -lt $positions[$i - 1]) { return $false }
    }
    return $true
}

#endregion

#region Blocks (the sweep's scanning unit, plan.md "The sweep")

function Get-MarkdownLineKind {
    param([string]$Line)
    if ($Line -match '^\s*$') { return 'blank' }
    if ($Line -match '^\s*(```|~~~)') { return 'fence' }
    if ($Line -match '^#{1,6}\s') { return 'heading' }
    if ($Line -match '^\s*\|') { return 'table' }
    if ($Line -match '^\s{0,3}([-*+]|\d+\.)\s+') { return 'item' }
    if ($Line -match '^\s{2,}\S') { return 'continuation' }
    return 'prose'
}

function Get-MarkdownBlocks {
    # Prose line = one block; consecutive list items (+ indented continuations) = one block; consecutive table
    # rows = one block; each fenced-code line = its own block. Headings and blank lines end a block.
    param([string[]]$Lines)
    $blocks = [Collections.Generic.List[object]]::new()
    $current = $null; $currentKind = $null; $inFence = $false
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $kind = Get-MarkdownLineKind -Line $Lines[$i]
        if ($kind -eq 'fence') { $inFence = -not $inFence; $current = $null; continue }
        if ($inFence) { $blocks.Add([pscustomobject]@{ Start = $i + 1; Lines = @($Lines[$i]) }); continue }
        $joins = ($null -ne $current) -and (($kind -eq 'item' -and $currentKind -eq 'list') -or ($kind -eq 'continuation' -and $currentKind -eq 'list') -or ($kind -eq 'table' -and $currentKind -eq 'table'))
        if ($joins) { $current.Lines += $Lines[$i]; continue }
        $current = $null
        if ($kind -in @('blank', 'heading')) { continue }
        $current = [pscustomobject]@{ Start = $i + 1; Lines = @($Lines[$i]) }
        $currentKind = switch ($kind) { 'item' { 'list' } 'table' { 'table' } default { 'prose' } }
        $blocks.Add($current)
        if ($currentKind -eq 'prose') { $current = $null }
    }
    return $blocks.ToArray()
}

function Get-CodeBlocks {
    # Consecutive lines that each carry a lens id form one block (plan verdict); an id-free line ends it.
    param([string[]]$Lines, [string]$Pattern)
    $blocks = [Collections.Generic.List[object]]::new()
    $current = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch $Pattern) { $current = $null; continue }
        if ($null -eq $current) {
            $current = [pscustomobject]@{ Start = $i + 1; Lines = @() }
            $blocks.Add($current)
        }
        $current.Lines += $Lines[$i]
    }
    return $blocks.ToArray()
}

function Get-TextBlocks {
    param([string[]]$Lines, [string]$Extension, [string]$Pattern)
    if ($Extension -in $script:CodeExtensions) { return Get-CodeBlocks -Lines $Lines -Pattern $Pattern }
    return Get-MarkdownBlocks -Lines $Lines
}

#endregion

#region Checks

function Get-LensCatalog {
    param([string]$Root)
    $indexPath = Join-Path $Root "$($script:LensCatalogRelative)/index.yml"
    return @(Read-IntakeYamlDocument -Path $indexPath -Kind lenses)
}

function Get-FullSurfaceRegion {
    param([string[]]$Lines, $Surface)
    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match $Surface.Start) { $start = $i; break } }
    if ($start -lt 0) { return $null }
    $end = $Lines.Count
    for ($i = $start + 1; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match $Surface.End) { $end = $i; break } }
    $region = @($Lines[$start..($end - 1)])
    if ($Surface.Rows) { $region = @($region | Where-Object { $_ -match $Surface.Rows }) }
    return [pscustomobject]@{ StartLine = $start + 1; EndLine = $end; Lines = $region }
}

function Get-SurfaceEntries {
    # Every entry of a full surface, in reading order and with duplicates kept, read by the surface's own Item rule.
    # The catalog is not consulted, so the list compared with index.yml is the surface's real membership.
    param([string[]]$Lines, $Surface)
    if ([string]::IsNullOrWhiteSpace([string]$Surface.Item)) { throw "Full surface '$($Surface.Name)' has no Item rule." }
    $chunks = @($Lines)
    if ($Surface.Within) {
        $within = [regex]::Match(($Lines -join ' '), $Surface.Within)
        if (-not $within.Success) { return , @("(the list named by /$($Surface.Within)/ was not found)") }
        $chunks = @($within.Groups['list'].Value)
    }
    $entries = [Collections.Generic.List[string]]::new()
    foreach ($chunk in $chunks) {
        foreach ($match in [regex]::Matches($chunk, $Surface.Item)) { $entries.Add($match.Groups[1].Value) }
    }
    return , $entries.ToArray()
}

function Test-FullSurfaces {
    param([string]$Root, [object[]]$Surfaces, [string[]]$Order)
    $mismatches = [Collections.Generic.List[object]]::new()
    $regions = [Collections.Generic.List[object]]::new()
    $expected = $Order -join ', '
    foreach ($surface in $Surfaces) {
        $path = Join-Path $Root $surface.Path
        if (-not (Test-Path -LiteralPath $path)) { $mismatches.Add((New-Mismatch $surface.Path 0 $expected '(file missing)' $script:OrderFix)); continue }
        $region = Get-FullSurfaceRegion -Lines (Get-NormalizedLines -Path $path) -Surface $surface
        if ($null -eq $region) { $mismatches.Add((New-Mismatch $surface.Path 0 $expected "(anchor '$($surface.Start)' not found for $($surface.Name))" $script:OrderFix)); continue }
        $regions.Add([pscustomobject]@{ Path = $surface.Path; StartLine = $region.StartLine; EndLine = $region.EndLine })
        $found = Get-SurfaceEntries -Lines $region.Lines -Surface $surface
        if (($found -join ', ') -cne $expected) {
            $mismatches.Add((New-Mismatch $surface.Path $region.StartLine "$expected (full list: $($surface.Name))" ($found -join ', ') $script:OrderFix))
        }
    }
    return [pscustomobject]@{ Mismatches = $mismatches.ToArray(); Regions = $regions.ToArray() }
}

function Get-SweepFiles {
    param([string]$Root)
    Push-Location $Root
    try { $tracked = @(git -c core.quotepath=false ls-files 2>$null) } finally { Pop-Location }
    return @($tracked | Where-Object {
            $relative = $_
            $inRoot = ($script:SweepRoots | Where-Object { $relative -like "$_/*" }) -or ($relative -notmatch '/' -and $relative -like '*.md')
            $typed = [IO.Path]::GetExtension($relative) -in $script:SweepExtensions
            $excluded = $script:SweepExclusions | Where-Object { $relative -match $_ }
            $inRoot -and $typed -and -not $excluded
        })
}

function Test-InRegion {
    param([object[]]$Regions, [string]$Path, [int]$Line)
    return [bool]($Regions | Where-Object { $_.Path -eq $Path -and $Line -ge $_.StartLine -and $Line -le $_.EndLine })
}

function Test-Sweep {
    param([string]$Root, [string[]]$Files, [string[]]$Order, [string]$Pattern, [object[]]$Regions, [object[]]$Exemptions)
    $mismatches = [Collections.Generic.List[object]]::new()
    $usedExemptions = [Collections.Generic.HashSet[int]]::new()
    $runCount = 0
    foreach ($relative in $Files) {
        $lines = Get-NormalizedLines -Path (Join-Path $Root $relative)
        foreach ($block in @(Get-TextBlocks -Lines $lines -Extension ([IO.Path]::GetExtension($relative)) -Pattern $Pattern)) {
            $found = Get-DistinctLensIds -Lines $block.Lines -Pattern $Pattern
            if ($found.Count -lt $script:MinimumRunLength) { continue }
            if (Test-InRegion -Regions $Regions -Path $relative -Line $block.Start) { continue }
            $runCount++
            $exemptIndex = -1
            for ($e = 0; $e -lt $Exemptions.Count; $e++) {
                $exemption = $Exemptions[$e]
                if ($exemption.Path -eq $relative -and @($block.Lines | Where-Object { $_ -match $exemption.Pattern }).Count -gt 0) { $exemptIndex = $e; break }
            }
            if ($exemptIndex -ge 0) { [void]$usedExemptions.Add($exemptIndex); continue }
            if (-not (Test-RelativeOrder -Found $found -Order $Order)) {
                $mismatches.Add((New-Mismatch $relative $block.Start "index.yml relative order ($(@($Order | Where-Object { $_ -in $found }) -join ', '))" ($found -join ', ') $script:OrderFix))
            }
        }
    }
    for ($e = 0; $e -lt $Exemptions.Count; $e++) {
        if (-not $usedExemptions.Contains($e)) {
            $mismatches.Add((New-Mismatch $Exemptions[$e].Path 0 'an exemption that matches a run' 'a stale exemption (no run matches it)' 'remove the exemption, or fix its pattern'))
        }
    }
    return [pscustomobject]@{ Mismatches = $mismatches.ToArray(); RunCount = $runCount }
}

function Get-MarkdownBody {
    # The deploy wrapper is the frontmatter; compare what follows it.
    param([string[]]$Lines)
    if ($Lines.Count -gt 0 -and $Lines[0] -eq '---') {
        for ($i = 1; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -eq '---') { return , @($Lines[($i + 1)..($Lines.Count - 1)]) } }
    }
    return , $Lines
}

function Get-CopyMap {
    param([string[]]$LensFiles)
    $map = [Collections.Generic.List[object]]::new()
    $catalogFiles = @('index.yml', 'README.md', 'applicability-map.json', 'diagram-vocabulary.json') + $LensFiles
    foreach ($file in $catalogFiles) {
        $map.Add(@{ Source = "$($script:LensCatalogRelative)/$file"; Copy = ".specify/$($script:LensCatalogRelative)/$file" })
    }
    $map.Add(@{ Source = 'extensions/specrew-speckit/commands/speckit.specrew-speckit.before-specify.md'; Copy = '.specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-specify.md' })
    $map.Add(@{ Source = 'extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1'; Copy = '.specify/extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1' })
    foreach ($copy in $script:SkillCopies) { $map.Add(@{ Source = 'extensions/specrew-speckit/squad-templates/skills/design-workshop.md'; Copy = $copy }) }
    return , $map.ToArray()
}

function Test-DeployedCopies {
    param([string]$Root, [object[]]$CopyMap)
    $mismatches = [Collections.Generic.List[object]]::new()
    foreach ($pair in $CopyMap) {
        $sourcePath = Join-Path $Root $pair.Source; $copyPath = Join-Path $Root $pair.Copy
        if (-not (Test-Path -LiteralPath $copyPath)) { continue }  # a host copy not deployed in this project
        $source = Get-MarkdownBody -Lines (Get-NormalizedLines -Path $sourcePath)
        $copy = Get-MarkdownBody -Lines (Get-NormalizedLines -Path $copyPath)
        $line = 0
        $limit = [Math]::Max($source.Count, $copy.Count)
        for ($i = 0; $i -lt $limit; $i++) {
            $s = if ($i -lt $source.Count) { $source[$i] } else { $null }
            $c = if ($i -lt $copy.Count) { $copy[$i] } else { $null }
            if ($s -cne $c) { $line = $i + 1; break }
        }
        if ($line -gt 0) {
            $mismatches.Add((New-Mismatch $pair.Copy $line "the same content as $($pair.Source) (body line $line)" 'a different line (stale deployed copy)' $script:CopyRefreshFix))
        }
    }
    return , $mismatches.ToArray()
}

function Get-DecisionSection {
    param([string[]]$Lines)
    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match '^##\s+Design\s+Decision\s+Points\s*$') { $start = $i; break } }
    if ($start -lt 0) { return $null }
    $end = $Lines.Count
    for ($i = $start + 1; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match '^##\s+') { $end = $i; break } }
    return [pscustomobject]@{ StartLine = $start + 1; Lines = @($Lines[($start + 1)..($end - 1)]) }
}

function Get-SpaceSections {
    # Splits the Design Decision Points body into untagged / problem / solution parts. Decision points are bullet
    # items (the extractor's rule, any indentation) and numbered items (counted here, the plan verdict).
    param([string[]]$SectionLines)
    $parts = @{ untagged = @(); problem = @(); solution = @(); problemNone = $false; solutionNone = $false; problemHeading = $false; solutionHeading = $false }
    $current = 'untagged'
    foreach ($line in $SectionLines) {
        if ($line -match '^###\s+Problem questions\s*$') { $current = 'problem'; $parts.problemHeading = $true; continue }
        if ($line -match '^###\s+Solution questions\s*$') { $current = 'solution'; $parts.solutionHeading = $true; continue }
        if ($line -match '^###\s') { $current = 'untagged'; continue }
        if ($current -ne 'untagged' -and $line -match ('^No {0} questions:\s*\S' -f $current)) { $parts["$($current)None"] = $true; continue }
        if ($line -match '^\s*([-*]|\d+\.)\s+') { $parts[$current] += $line }
    }
    return $parts
}

function Test-LensTagging {
    param([string]$Root, [object[]]$Catalog)
    $mismatches = [Collections.Generic.List[object]]::new()
    foreach ($lens in $Catalog) {
        $relative = "$($script:LensCatalogRelative)/$($lens.file)"
        $space = if ($lens.PSObject.Properties['space']) { [string]$lens.space } else { '' }
        if ($space -notin @('problem', 'solution', 'both')) {
            $mismatches.Add((New-Mismatch "$($script:LensCatalogRelative)/index.yml" 0 "space problem|solution|both for $($lens.id)" "'$space'" 'set the lens''s space in index.yml'))
        }
        $section = Get-DecisionSection -Lines (Get-NormalizedLines -Path (Join-Path $Root $relative))
        if ($null -eq $section) { $mismatches.Add((New-Mismatch $relative 0 '## Design Decision Points' '(missing)' 'restore the section')); continue }
        $parts = Get-SpaceSections -SectionLines $section.Lines
        foreach ($name in @('problem', 'solution')) {
            $heading = $parts["$($name)Heading"]; $hasItems = @($parts[$name]).Count -gt 0; $hasNone = $parts["$($name)None"]
            if (-not $heading) { $mismatches.Add((New-Mismatch $relative $section.StartLine "### $((Get-Culture).TextInfo.ToTitleCase($name)) questions inside ## Design Decision Points" '(missing)' 'add the sub-heading (FR-005 a)')) }
            elseif ($hasItems -eq $hasNone) { $mismatches.Add((New-Mismatch $relative $section.StartLine "### $name questions: items, or exactly one 'No $name questions: <reason>' line" $(if ($hasItems) { 'both items and a No-questions line' } else { 'neither' }) 'keep one (FR-005 a)')) }
        }
        if (@($parts.untagged).Count -gt 0) { $mismatches.Add((New-Mismatch $relative $section.StartLine 'every decision point under one sub-heading' "$(@($parts.untagged).Count) untagged point(s)" 'file each point under its space, without rewording (FR-005 b)')) }
        $filled = @(@('problem', 'solution') | Where-Object { @($parts[$_]).Count -gt 0 })
        $expectedFilled = switch ($space) { 'problem' { @('problem') } 'solution' { @('solution') } 'both' { @('problem', 'solution') } default { @() } }
        if (($filled -join ',') -ne ($expectedFilled -join ',')) {
            $mismatches.Add((New-Mismatch $relative $section.StartLine "filled spaces '$($expectedFilled -join ',')' (index.yml space: $space)" "'$($filled -join ',')'" 'bring the tag to the maintainer; never refile a question to pass (FR-005 c, FR-015)'))
        }
    }
    return , $mismatches.ToArray()
}

function Test-Extractor {
    param([string]$Root, [object[]]$Catalog, [System.Collections.IDictionary]$ExpectedCounts)
    $mismatches = [Collections.Generic.List[object]]::new()
    $catalogDir = Join-Path $Root $script:LensCatalogRelative
    foreach ($lens in $Catalog) {
        $relative = "$($script:LensCatalogRelative)/$($lens.file)"
        $points = @(Get-SpecrewLensDecisionPoints -LensId $lens.id -CatalogDir $catalogDir)
        if ($ExpectedCounts.Contains($lens.id) -and $points.Count -ne $ExpectedCounts[$lens.id]) {
            $mismatches.Add((New-Mismatch $relative 0 "$($ExpectedCounts[$lens.id]) extracted decision points (SC-002)" "$($points.Count)" 'restore the lost or extra questions; the extractor must keep returning every tagged point'))
        }
        $section = Get-DecisionSection -Lines (Get-NormalizedLines -Path (Join-Path $Root $relative))
        if ($null -eq $section) { continue }
        $parts = Get-SpaceSections -SectionLines $section.Lines
        $bullets = @(@($parts.problem) + @($parts.solution) + @($parts.untagged) | Where-Object { $_ -match '^\s*[-*]\s+' })
        if ($bullets.Count -ne $points.Count) {
            $mismatches.Add((New-Mismatch $relative $section.StartLine "the extractor returning all $($bullets.Count) bullet points under both sub-headings" "$($points.Count)" 'keep the points as bullets inside ## Design Decision Points'))
        }
    }
    return , $mismatches.ToArray()
}

function Test-SkillSentences {
    param([string]$Root, [string[]]$Paths)
    $mismatches = [Collections.Generic.List[object]]::new()
    foreach ($relative in $Paths) {
        $path = Join-Path $Root $relative
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $text = [IO.File]::ReadAllText($path)
        foreach ($sentence in $script:SkillSentences) {
            if ($text -notmatch [regex]::Escape($sentence)) {
                $mismatches.Add((New-Mismatch $relative 0 "the sentence '$sentence' (FR-018)" '(absent)' 'state it in the skill source, then refresh the copies'))
            }
        }
    }
    return , $mismatches.ToArray()
}

function Test-ComputedOrders {
    # Orders that code COMPUTES never appear as text, so the shipped-text sweep cannot see them (round-1 review
    # finding: the applicability selector put the always-on lenses before the gated ones). This runs the selector
    # and its rendered section for all-no, each single yes, and all-yes answers, and reports any result that is not
    # in index.yml's relative order. -Select and -Render default to the shipped functions, called with no catalog
    # parameter, so the default path is the one proven.
    param(
        [object]$Map, [string[]]$Order,
        [scriptblock]$Select = { param($m, $a) Get-SpecrewApplicableLenses -Map $m -Answers $a },
        [scriptblock]$Render = { param($m, $a) Format-SpecrewApplicableLensesSection -Map $m -Answers $a },
        [string]$Path = 'scripts/internal/lens-applicability.ps1'
    )
    $fix = 'order the computed selection by index.yml (the selector must not define its own order)'
    $keys = @($Map.questions | ForEach-Object { [string]$_.id })
    $cases = [ordered]@{ 'all no' = @{} }
    foreach ($k in $keys) { $cases['all no'][$k] = $false }
    foreach ($k in $keys) { $one = @{}; foreach ($j in $keys) { $one[$j] = ($j -eq $k) }; $cases["only $k yes"] = $one }
    $all = @{}; foreach ($k in $keys) { $all[$k] = $true }; $cases['all yes'] = $all
    $mismatches = [Collections.Generic.List[object]]::new()
    # An error from the selector or the render (e.g. a lens the map gates but index.yml no longer lists) is one more
    # mismatch for that case, never the end of the run: every other mismatch must still be reported (FR-019).
    $errorFix = 'make index.yml and the applicability map name the same lenses (the error above says which), then rerun'
    foreach ($case in $cases.Keys) {
        try {
            $selected = @(& $Select $Map $cases[$case])
            if (-not (Test-RelativeOrder -Found $selected -Order $Order)) {
                $mismatches.Add((New-Mismatch $Path 0 "index.yml relative order (selector, $case)" ($selected -join ', ') $fix))
            }
        }
        catch { $mismatches.Add((New-Mismatch $Path 0 "a selection in index.yml order (selector, $case)" "an error: $($_.Exception.Message)" $errorFix)) }
        try { $rendered = [string](& $Render $Map $cases[$case]) }
        catch {
            $mismatches.Add((New-Mismatch $Path 0 "a rendered section in index.yml order (render, $case)" "an error: $($_.Exception.Message)" $errorFix))
            continue
        }
        $listed = @([regex]::Matches($rendered, '(?m)^- \*\*([a-z][a-z0-9-]*)\*\*') | ForEach-Object { $_.Groups[1].Value })
        $notSelected = [regex]::Match($rendered, '\*Not selected: (?<list>[^*]*)\*')
        $skipped = if ($notSelected.Success) { @([regex]::Matches($notSelected.Groups['list'].Value, '([a-z][a-z0-9-]*) \(') | ForEach-Object { $_.Groups[1].Value }) } else { @() }
        foreach ($pair in @(@{ Name = 'rendered Applicable Lenses'; Ids = $listed }, @{ Name = 'rendered Not selected'; Ids = $skipped })) {
            if (-not (Test-RelativeOrder -Found $pair.Ids -Order $Order)) {
                $mismatches.Add((New-Mismatch $Path 0 "index.yml relative order ($($pair.Name), $case)" ($pair.Ids -join ', ') $fix))
            }
        }
    }
    return $mismatches.ToArray()
}

function Invoke-LensOrderParity {
    param([string]$Root, [object[]]$FullSurfaces, [object[]]$Exemptions, [System.Collections.IDictionary]$ExpectedCounts, [switch]$SkipCopies, [string[]]$SweepFiles, [switch]$SkipComputed,
        # Self-tests only: a selector/render that reads a scratch catalog. The repository check uses the shipped defaults.
        [scriptblock]$ComputedSelect, [scriptblock]$ComputedRender)
    $catalog = Get-LensCatalog -Root $Root
    $order = @($catalog | ForEach-Object { [string]$_.id })
    $pattern = Get-LensIdPattern -LensIds $order
    $all = [Collections.Generic.List[object]]::new()
    $full = Test-FullSurfaces -Root $Root -Surfaces $FullSurfaces -Order $order
    $all.AddRange([object[]]$full.Mismatches)
    $files = @(if ($PSBoundParameters.ContainsKey('SweepFiles')) { $SweepFiles } else { Get-SweepFiles -Root $Root })
    $sweep = Test-Sweep -Root $Root -Files $files -Order $order -Pattern $pattern -Regions $full.Regions -Exemptions $Exemptions
    $all.AddRange([object[]]$sweep.Mismatches)
    $all.AddRange([object[]](Test-LensTagging -Root $Root -Catalog $catalog))
    $all.AddRange([object[]](Test-Extractor -Root $Root -Catalog $catalog -ExpectedCounts $ExpectedCounts))
    if (-not $SkipComputed) {
        $mapPath = Join-Path $Root "$($script:LensCatalogRelative)/applicability-map.json"
        $map = Read-SpecrewLensApplicabilityMap -Path $mapPath
        if ($null -eq $map) { $all.Add((New-Mismatch "$($script:LensCatalogRelative)/applicability-map.json" 0 'a readable applicability map' '(missing or unreadable)' 'restore applicability-map.json beside index.yml')) }
        else {
            $computedArgs = @{ Map = $map; Order = $order }
            if ($ComputedSelect) { $computedArgs.Select = $ComputedSelect }
            if ($ComputedRender) { $computedArgs.Render = $ComputedRender }
            $all.AddRange([object[]]@(Test-ComputedOrders @computedArgs))
        }
    }
    $copyCount = 0
    if (-not $SkipCopies) {
        $copyMap = Get-CopyMap -LensFiles @($catalog | ForEach-Object { [string]$_.file })
        $copyCount = @($copyMap | Where-Object { Test-Path -LiteralPath (Join-Path $Root $_.Copy) }).Count
        $all.AddRange([object[]](Test-DeployedCopies -Root $Root -CopyMap $copyMap))
        $all.AddRange([object[]](Test-SkillSentences -Root $Root -Paths (@('extensions/specrew-speckit/squad-templates/skills/design-workshop.md') + $script:SkillCopies)))
    }
    return [pscustomobject]@{
        Mismatches = $all.ToArray(); Order = $order; FullSurfaceCount = $FullSurfaces.Count; SweepFileCount = $files.Count
        RunCount = $sweep.RunCount; LensCount = $catalog.Count; CopyCount = $copyCount
    }
}

#endregion

#region Self-tests (T002): the checks are proven able to fail before they are trusted

function Invoke-SelfTests {
    $ids = @('alpha-lens', 'beta-lens', 'gamma-lens', 'delta-lens')
    $pattern = Get-LensIdPattern -LensIds $ids
    $runIds = { param([string[]]$Lines, [string]$Extension) @(@(Get-TextBlocks -Lines $Lines -Extension $Extension -Pattern $pattern) | ForEach-Object { , (Get-DistinctLensIds -Lines $_.Lines -Pattern $pattern) } | Where-Object { $_.Count -ge $script:MinimumRunLength }) }

    # Matches (plan.md): one prose line; consecutive list items; consecutive table rows; one code line; a multi-line array.
    Assert-True (@(& $runIds @('alpha-lens first, then gamma-lens, beta-lens and delta-lens') '.md').Count -eq 1) 'match 1: one prose line with 4 ids is a run'
    Assert-True (@(& $runIds @('- `alpha-lens`', '- `beta-lens`', '- `gamma-lens`') '.md').Count -eq 1) 'match 2: consecutive list items form one run'
    Assert-True (@(& $runIds @('| `alpha-lens` | x |', '| `beta-lens` | y |', '| `gamma-lens` | z |') '.md').Count -eq 1) 'match 3: consecutive table rows form one run'
    Assert-True (@(& $runIds @('$x -match ''(?:alpha-lens|beta-lens|gamma-lens)''') '.ps1').Count -eq 1) 'match 4: one code line is a run'
    Assert-True (@(& $runIds @('$ids = @(', '  ''alpha-lens'',', '  ''beta-lens'',', '  ''gamma-lens'')') '.ps1').Count -eq 1) 'match 5: a multi-line array (consecutive id-carrying code lines) is a run'

    # Does not match.
    Assert-True (@(& $runIds @('beta-lens and alpha-lens') '.md').Count -eq 0) 'non-match 1: two ids only'
    Assert-True (@(& $runIds @('alpha-lens here', '', 'gamma-lens and beta-lens') '.md').Count -eq 0) 'non-match 2: separate blocks never join'
    Assert-True (@(& $runIds @('## About alpha-lens', '- beta-lens', '- gamma-lens') '.md').Count -eq 0) 'non-match 3: a heading ends the block'
    Assert-True (@(& $runIds @('alpha-lens-v2, my-beta-lens, gamma-lens-x') '.md').Count -eq 0) 'non-match 4: ids must be whole tokens'
    Assert-True (@(& $runIds @('''alpha-lens'',', '$sep = 1', '''beta-lens'',', '$sep = 2', '''gamma-lens''') '.ps1').Count -eq 0) 'non-match 5: an id-free code line ends the block'

    Assert-True (Test-RelativeOrder -Found @('alpha-lens', 'gamma-lens') -Order $ids) 'relative order: a subset in order passes'
    Assert-True (-not (Test-RelativeOrder -Found @('gamma-lens', 'alpha-lens') -Order $ids)) 'relative order: a subset out of order fails'

    # A seeded scratch tree: every mismatch must be reported in one run.
    $scratch = Join-Path ([IO.Path]::GetTempPath()) ('lens-parity-selftest-' + [guid]::NewGuid().ToString('N'))
    try {
        New-SelfTestTree -Root $scratch
        $surfaces = @(@{ Name = 'fixture full list'; Path = 'docs/full.md'; Start = '^Lenses:'; End = '^\s*$'; Rows = $null; Within = $null; Item = $script:KebabToken })
        $counts = [ordered]@{ 'alpha-lens' = 1; 'beta-lens' = 1 }
        $result = Invoke-LensOrderParity -Root $scratch -FullSurfaces $surfaces -Exemptions @() -ExpectedCounts $counts -SkipCopies -SkipComputed -SweepFiles @('docs/full.md', 'docs/partial.md', 'docs/fine.md')
        $text = ($result.Mismatches | ForEach-Object { Format-Mismatch $_ }) -join "`n"
        Assert-True ($text -match 'docs/full\.md') 'seeded: the out-of-order full list is reported'
        Assert-True ($text -match 'docs/partial\.md') 'seeded: the out-of-order partial list is reported'
        Assert-True ($text -notmatch 'docs/fine\.md') 'seeded: an in-order subset is not reported'
        Assert-True ($text -match 'beta-lens\.md.*untagged') 'seeded: an untagged decision point is reported'
        Assert-True ($text -match "gamma-lens\.md.*filled spaces") 'seeded: a lens whose filled space disagrees with its tag is reported'
        Assert-True ($text -match "index\.yml.*space problem\|solution\|both for gamma-lens" -or $text -match 'gamma-lens\.md') 'seeded: the gamma lens problem is reported'
        Assert-True (@($result.Mismatches).Count -ge 5) ('seeded: at least 5 mismatches reported in one run (got {0})' -f @($result.Mismatches).Count)
        Assert-True (@($result.Mismatches | Where-Object { $_.Fix }).Count -eq @($result.Mismatches).Count) 'seeded: every mismatch carries a fix'
    }
    finally { if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force } }

    # Membership (round-1 review finding): a full list is read independently of the catalog, so an entry the catalog
    # does not know is reported. Both cases keep the known lenses in index.yml order, so order alone cannot flag them.
    $memberScratch = Join-Path ([IO.Path]::GetTempPath()) ('lens-parity-member-' + [guid]::NewGuid().ToString('N'))
    try {
        New-SelfTestTree -Root $memberScratch
        $memberSurface = @{ Name = 'fixture full list'; Path = 'docs/member.md'; Start = '^Lenses:'; End = '^\s*$'; Rows = $null; Within = $null; Item = $script:KebabToken }
        $memberCounts = [ordered]@{ 'alpha-lens' = 1; 'beta-lens' = 1 }

        Set-Content -LiteralPath (Join-Path $memberScratch 'docs/member.md') -Value "Lenses: alpha-lens, beta-lens, gamma-lens, omega-lens`n"
        $extra = Invoke-LensOrderParity -Root $memberScratch -FullSurfaces @($memberSurface) -Exemptions @() -ExpectedCounts $memberCounts -SkipCopies -SkipComputed -SweepFiles @('docs/member.md')
        $extraText = ($extra.Mismatches | Where-Object { $_.Path -eq 'docs/member.md' } | ForEach-Object { Format-Mismatch $_ }) -join "`n"
        Assert-True ($extraText -match 'found alpha-lens, beta-lens, gamma-lens, omega-lens') 'membership: an extra lens the catalog does not know is reported'

        $indexPath = Join-Path $memberScratch "$($script:LensCatalogRelative)/index.yml"
        Set-Content -LiteralPath $indexPath -Value ((Get-Content -LiteralPath $indexPath -Raw) -replace '(?s)\s*- id: gamma-lens.*$', "`n")
        Set-Content -LiteralPath (Join-Path $memberScratch 'docs/member.md') -Value "Lenses: alpha-lens, beta-lens, gamma-lens`n"
        $removed = Invoke-LensOrderParity -Root $memberScratch -FullSurfaces @($memberSurface) -Exemptions @() -ExpectedCounts $memberCounts -SkipCopies -SkipComputed -SweepFiles @('docs/member.md')
        $removedText = ($removed.Mismatches | Where-Object { $_.Path -eq 'docs/member.md' } | ForEach-Object { Format-Mismatch $_ }) -join "`n"
        Assert-True (($removed.Order -join ', ') -eq 'alpha-lens, beta-lens') 'membership fixture: gamma-lens is removed from the catalog'
        Assert-True ($removedText -match 'found alpha-lens, beta-lens, gamma-lens') 'membership: a lens removed from the catalog but still listed is reported'
    }
    finally { if (Test-Path -LiteralPath $memberScratch) { Remove-Item -LiteralPath $memberScratch -Recurse -Force } }

    # Computed orders (round-1 review finding): a selector that puts its own order on the result is reported; one that
    # follows the catalog is not. The fixture selector returns the always-on lens first, like the shipped one did.
    $fixtureMap = [pscustomobject]@{ always_on = @('gamma-lens'); questions = @([pscustomobject]@{ id = 'q'; gates = @('alpha-lens') }) }
    $ownOrder = { param($m, $a) $out = @('gamma-lens'); if ($a['q']) { $out += 'alpha-lens' }; $out }
    $catalogOrder = { param($m, $a) $out = @(); if ($a['q']) { $out += 'alpha-lens' }; $out += 'gamma-lens'; $out }
    $noRender = { param($m, $a) '' }
    $computedBad = @(Test-ComputedOrders -Map $fixtureMap -Order $ids -Select $ownOrder -Render $noRender)
    Assert-True ($computedBad.Count -ge 1 -and (($computedBad | ForEach-Object { Format-Mismatch $_ }) -join "`n") -match 'found gamma-lens, alpha-lens') 'computed: a selector with its own order is reported'
    Assert-True (@(Test-ComputedOrders -Map $fixtureMap -Order $ids -Select $catalogOrder -Render $noRender).Count -eq 0) 'computed: a selector in catalog order is not reported'
    $badRender = { param($m, $a) "- **gamma-lens** - x`n- **alpha-lens** - y`n" }
    Assert-True (@(Test-ComputedOrders -Map $fixtureMap -Order $ids -Select $catalogOrder -Render $badRender).Count -ge 1) 'computed: a rendered section out of catalog order is reported'

    # Catalog removal with the computed check ON (round-2 review finding, FR-019): a lens removed from index.yml but
    # still gated by the applicability map makes the shipped selector throw. That error must become a mismatch record,
    # and the run must still print every other mismatch, rather than end the check with the error alone.
    $removalScratch = Join-Path ([IO.Path]::GetTempPath()) ('lens-parity-removal-' + [guid]::NewGuid().ToString('N'))
    try {
        New-SelfTestTree -Root $removalScratch
        $removalCatalog = Join-Path $removalScratch $script:LensCatalogRelative
        Set-Content -LiteralPath (Join-Path $removalCatalog 'applicability-map.json') -Value '{ "always_on": ["alpha-lens"], "questions": [ { "id": "q", "gates": ["gamma-lens"] } ] }'
        $removalIndex = Join-Path $removalCatalog 'index.yml'
        Set-Content -LiteralPath $removalIndex -Value ((Get-Content -LiteralPath $removalIndex -Raw) -replace '(?s)\s*- id: gamma-lens.*$', "`n")
        Set-Content -LiteralPath (Join-Path $removalScratch 'docs/member.md') -Value "Lenses: alpha-lens, beta-lens, gamma-lens`n"
        $removalSurface = @{ Name = 'fixture full list'; Path = 'docs/member.md'; Start = '^Lenses:'; End = '^\s*$'; Rows = $null; Within = $null; Item = $script:KebabToken }
        $catalogLiteral = $removalCatalog.Replace("'", "''")
        $scratchSelect = [scriptblock]::Create("param(`$m, `$a) Get-SpecrewApplicableLenses -Map `$m -Answers `$a -CatalogDir '$catalogLiteral'")
        $scratchRender = [scriptblock]::Create("param(`$m, `$a) Format-SpecrewApplicableLensesSection -Map `$m -Answers `$a -CatalogDir '$catalogLiteral'")
        $removalReport = @()
        $removalError = $null
        try {
            $removalRun = Invoke-LensOrderParity -Root $removalScratch -FullSurfaces @($removalSurface) -Exemptions @() -ExpectedCounts ([ordered]@{ 'alpha-lens' = 1; 'beta-lens' = 1 }) -SkipCopies -SweepFiles @('docs/member.md') -ComputedSelect $scratchSelect -ComputedRender $scratchRender
            $removalReport = @(Get-MismatchReport -Mismatches $removalRun.Mismatches)
        }
        catch { $removalError = $_.Exception.Message }
        $removalText = $removalReport -join "`n"
        Assert-True ($null -eq $removalError) ('removal + computed: the check completes instead of stopping on the selector error (error: {0})' -f $removalError)
        Assert-True ($removalText -match 'docs/member\.md:\d+: expected .*found alpha-lens, beta-lens, gamma-lens') 'removal + computed: the printed report still carries the full-list mismatch'
        Assert-True ($removalText -match 'lens-applicability\.ps1.*only q yes.*gamma-lens' -and $removalText -match 'lens-applicability\.ps1.*all yes.*gamma-lens') 'removal + computed: each selector error is printed as a mismatch naming the unknown lens'
        Assert-True ($removalReport.Count -gt 0 -and $removalReport[0] -match ('^lens-order-parity: {0} mismatch' -f ($removalReport.Count - 1))) 'removal + computed: the report count matches every printed mismatch'
    }
    finally { if (Test-Path -LiteralPath $removalScratch) { Remove-Item -LiteralPath $removalScratch -Recurse -Force } }

    # A stale deployed copy is reported with the project-only refresh commands.
    $copyScratch = Join-Path ([IO.Path]::GetTempPath()) ('lens-parity-copy-' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Force -Path (Join-Path $copyScratch 'src'), (Join-Path $copyScratch 'dst') | Out-Null
        Set-Content -LiteralPath (Join-Path $copyScratch 'src/a.md') -Value "---`nname: x`n---`nline one`nline two"
        Set-Content -LiteralPath (Join-Path $copyScratch 'dst/a.md') -Value "---`nname: wrapped`ntool: y`n---`nline one`nline TWO"
        Set-Content -LiteralPath (Join-Path $copyScratch 'dst/b.md') -Value "---`nother: wrapper`n---`nline one`nline two"
        $copyResult = @(Test-DeployedCopies -Root $copyScratch -CopyMap @(@{ Source = 'src/a.md'; Copy = 'dst/a.md' }, @{ Source = 'src/a.md'; Copy = 'dst/b.md' }))
        Assert-True ($copyResult.Count -eq 1 -and $copyResult[0].Path -eq 'dst/a.md') 'copies: a stale body is reported; a differing wrapper alone is not'
        Assert-True ($copyResult.Count -eq 1 -and $copyResult[0].Fix -match 'deploy-speckit-extension\.ps1 -ProjectPath \. -RefreshExisting' -and $copyResult[0].Fix -match 'deploy-squad-runtime\.ps1 -ProjectPath \.' -and $copyResult[0].Fix -match 'never your home folder') 'copies: the fix names both project-only deploy commands'
    }
    finally { if (Test-Path -LiteralPath $copyScratch) { Remove-Item -LiteralPath $copyScratch -Recurse -Force } }
}

function New-SelfTestTree {
    param([string]$Root)
    $catalog = Join-Path $Root $script:LensCatalogRelative
    New-Item -ItemType Directory -Force -Path $catalog, (Join-Path $Root 'docs') | Out-Null
    Set-Content -LiteralPath (Join-Path $catalog 'index.yml') -Value @'
schema_version: "1.0"
description: "fixture"
lenses:
  - id: alpha-lens
    file: alpha-lens.md
    space: problem
  - id: beta-lens
    file: beta-lens.md
    space: solution
  - id: gamma-lens
    file: gamma-lens.md
    space: problem
'@
    Set-Content -LiteralPath (Join-Path $catalog 'alpha-lens.md') -Value "# A`n`n## Design Decision Points`n`n### Problem questions`n`n- What hurts?`n`n### Solution questions`n`nNo solution questions: pre-technical.`n"
    Set-Content -LiteralPath (Join-Path $catalog 'beta-lens.md') -Value "# B`n`n## Design Decision Points`n`n- An untagged point?`n`n### Problem questions`n`nNo problem questions: solution lens.`n`n### Solution questions`n`n- Which store?`n"
    Set-Content -LiteralPath (Join-Path $catalog 'gamma-lens.md') -Value "# G`n`n## Design Decision Points`n`n### Problem questions`n`nNo problem questions: wrong.`n`n### Solution questions`n`n- Which protocol?`n"
    Set-Content -LiteralPath (Join-Path $Root 'docs/full.md') -Value "Lenses: gamma-lens, alpha-lens, beta-lens`n"
    Set-Content -LiteralPath (Join-Path $Root 'docs/partial.md') -Value "Run beta-lens, then alpha-lens, then gamma-lens.`n"
    Set-Content -LiteralPath (Join-Path $Root 'docs/fine.md') -Value "Run alpha-lens, beta-lens and gamma-lens.`n"
}

#endregion

Write-Host '--- lens-order-parity: self-tests ---'
Invoke-SelfTests
if ($script:SelfTestFailures -gt 0) {
    Write-Host ("lens-order-parity: {0} self-test(s) FAILED; the repository check was not run." -f $script:SelfTestFailures) -ForegroundColor Red
    exit 1
}

Write-Host '--- lens-order-parity: repository check ---'
$result = Invoke-LensOrderParity -Root $RepoRoot -FullSurfaces $script:FullSurfaces -Exemptions $script:Exemptions -ExpectedCounts $script:ExpectedExtractorCounts
Write-Host ("index.yml order: {0}" -f ($result.Order -join ', '))
Write-Host 'Exemptions:'
foreach ($exemption in $script:Exemptions) { Write-Host ("  {0} /{1}/ - {2}" -f $exemption.Path, $exemption.Pattern, $exemption.Reason) }
Write-Host ("Checked: {0} full surfaces, {1} swept files ({2} runs), {3} lens files, {4} deployed copies." -f $result.FullSurfaceCount, $result.SweepFileCount, $result.RunCount, $result.LensCount, $result.CopyCount)

if (@($result.Mismatches).Count -gt 0) {
    foreach ($line in (Get-MismatchReport -Mismatches $result.Mismatches)) { Write-Host $line -ForegroundColor Red }
    exit 1
}
Write-Host 'lens-order-parity: all checks passed' -ForegroundColor Green
exit 0
