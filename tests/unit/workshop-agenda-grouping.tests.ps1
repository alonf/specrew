[CmdletBinding()]
param(
    # The repository whose agenda writer and lens catalog are checked. Defaults to this checkout.
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

# Feature 205 (proposal 220, iteration 3): the grouped workshop agenda (FR-032, Amendment A2).
#
# The agenda that confirm-workshop-agenda.ps1 renders for confirmation shows its selected lenses under three headings
# taken from each lens's `space` tag in index.yml - problem space, both spaces, solution space, in that order - with
# index.yml order inside each heading and a heading with no selected lens left out. Each heading carries its text label
# and one marker for its group. The `Selected lenses:` and `Skipped lenses:` lines and the closing question are kept,
# and the block reaches the reader as UTF-8 even when the console's encoding is not UTF-8.
#
# Checks, per lens and per heading (iteration 002 retro action 1: per item, not totals):
# - on the real index.yml, each selected lens sits under the heading of its space, in index.yml order;
# - a heading with no selected lens is left out;
# - on a fixture index.yml where one lens's `space` changes, that lens moves group;
# - the kept lines are present;
# - the block read back from a child process whose console encoding is Latin-1 equals the stored canonical_text.
#
# Self-tests over synthetic agenda text run first and prove each check can fail, naming the lens or the heading. A
# probe proves the child process really writes with a non-UTF-8 console encoding, so the round trip is not vacuous.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:WriterRelative = 'extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1'
$script:InitializerRelative = 'extensions/specrew-speckit/scripts/initialize-workshop-controller-state.ps1'
$script:AuthorityRelative = 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
$script:YamlReaderRelative = 'extensions/specrew-speckit/scripts/intake/helpers/Read-IntakeYaml.ps1'
$script:IndexRelative = 'extensions/specrew-speckit/knowledge/design-lenses/index.yml'
$script:DeployedLensDir = '.specify/extensions/specrew-speckit/knowledge/design-lenses'
$script:ProposalRelative = '.specrew/handover/workshop-agenda-proposal.json'
$script:FeatureRef = '001-agenda-grouping'

$script:Headings = [ordered]@{
    problem  = ([char]::ConvertFromUtf32(0x1F7E6) + ' Problem space')
    both     = ([char]::ConvertFromUtf32(0x1F7EA) + ' Both spaces')
    solution = ([char]::ConvertFromUtf32(0x1F7E7) + ' Solution space')
}
$script:SelectedLine = 'Selected lenses:'
$script:SkippedLine = 'Skipped lenses:'
$script:ClosingQuestion = 'Does this complete selected + skipped agenda look right? Reply with confirm or tell me what to change.'
$script:SelfTestFailures = 0

#region helpers

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host "PASS: $Message" -ForegroundColor Green }
    else { Write-Host "FAIL: $Message" -ForegroundColor Red; $script:SelfTestFailures++ }
}

function New-Problem {
    param([string]$Item, [string]$Check, [string]$Detail)
    [pscustomobject]@{ Item = $Item; Check = $Check; Detail = $Detail }
}

function Format-Problem {
    param($Problem)
    '{0} [{1}]: {2}' -f $Problem.Item, $Problem.Check, $Problem.Detail
}

function Get-IndexSpaces {
    # Ordered lens id -> space, read from index.yml with a plain line scan (independent of the writer's parser).
    param([string]$IndexPath)
    $spaces = [ordered]@{}
    $current = $null
    foreach ($line in [IO.File]::ReadAllLines($IndexPath)) {
        if ($line -match '^\s*-\s+id:\s*"?([a-z][a-z0-9-]*)"?\s*$') { $current = $Matches[1]; continue }
        if ($null -ne $current -and $line -match '^\s+space:\s*"?(problem|both|solution)"?\s*$') {
            $spaces[$current] = $Matches[1]
            $current = $null
        }
    }
    return $spaces
}

#endregion

#region the grouping check

function Test-GroupedAgenda {
    # Problems in one rendered agenda: kept lines, headings (exact text, order, none empty), and for each selected lens
    # its heading and its order inside the heading.
    param([string]$Text, [Collections.IDictionary]$Spaces, [string[]]$Selected)
    $lines = @(($Text -replace "`r`n", "`n") -split "`n")
    foreach ($kept in @($script:SelectedLine, $script:SkippedLine, $script:ClosingQuestion)) {
        $count = @($lines | Where-Object { $_ -ceq $kept }).Count
        if ($count -ne 1) { New-Problem $kept 'kept-line' ("expected the line once, found it {0} time(s)" -f $count) }
    }
    $start = [array]::IndexOf($lines, $script:SelectedLine)
    $end = [array]::IndexOf($lines, $script:SkippedLine)
    if ($start -lt 0 -or $end -le $start) { return }

    $spaceOfHeading = @{}
    foreach ($key in $script:Headings.Keys) { $spaceOfHeading[$script:Headings[$key]] = $key }
    $headingOrder = [Collections.Generic.List[string]]::new()
    $lensHeading = @{}
    $lensesUnder = @{}
    $orphans = [Collections.Generic.HashSet[string]]::new()
    $heading = $null
    for ($i = $start + 1; $i -lt $end; $i++) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($spaceOfHeading.ContainsKey($line)) {
            $heading = $spaceOfHeading[$line]
            $headingOrder.Add($heading)
            $lensesUnder[$heading] = [Collections.Generic.List[string]]::new()
            continue
        }
        if ($line -match '^- ([a-z][a-z0-9-]*) \(') {
            $lens = $Matches[1]
            if ($null -eq $heading) { [void]$orphans.Add($lens); New-Problem $lens 'grouping' 'listed before any group heading'; continue }
            $lensHeading[$lens] = $heading
            $lensesUnder[$heading].Add($lens)
            continue
        }
        New-Problem $line 'unexpected-line' 'not a group heading (marker and label) or a lens line'
    }

    $canonical = @($script:Headings.Keys)
    $positions = @($headingOrder | ForEach-Object { [array]::IndexOf($canonical, $_) })
    for ($i = 1; $i -lt $positions.Count; $i++) {
        if ($positions[$i] -le $positions[$i - 1]) {
            New-Problem $script:Headings[$headingOrder[$i]] 'heading-order' ("comes after '{0}'; the order is problem, both, solution, each once" -f $script:Headings[$headingOrder[$i - 1]])
        }
    }
    foreach ($key in $headingOrder) {
        if ($lensesUnder[$key].Count -eq 0) { New-Problem $script:Headings[$key] 'empty-heading' 'a heading with no selected lens must be left out' }
    }
    $indexOrder = @($Spaces.Keys)
    foreach ($lens in $Selected) {
        $want = $Spaces[$lens]
        if ($orphans.Contains($lens)) { continue }
        if (-not $lensHeading.ContainsKey($lens)) { New-Problem $lens 'grouping' ("not listed under '{0}'" -f $script:Headings[$want]); continue }
        if ($lensHeading[$lens] -ne $want) {
            New-Problem $lens 'grouping' ("listed under '{0}'; its index.yml space is {1}, so it belongs under '{2}'" -f $script:Headings[$lensHeading[$lens]], $want, $script:Headings[$want])
        }
    }
    foreach ($key in $headingOrder) {
        $under = @($lensesUnder[$key])
        for ($i = 1; $i -lt $under.Count; $i++) {
            if ([array]::IndexOf($indexOrder, $under[$i]) -lt [array]::IndexOf($indexOrder, $under[$i - 1])) {
                New-Problem $under[$i] 'order-in-heading' ("listed after {0}; index.yml puts it first" -f $under[$i - 1])
            }
        }
    }
}

#endregion

#region rendering in a scratch project

function New-ScratchProject {
    # A minimal governed project whose feature awaits agenda confirmation, with the product-domain receipt and records
    # the writer requires. The index.yml copied in is the one given (the real catalog or a fixture).
    param([string]$IndexSource)
    $scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-agenda-grouping-' + [guid]::NewGuid().ToString('N'))
    $feature = Join-Path $scratch ('specs/' + $script:FeatureRef)
    foreach ($dir in @('.specrew/handover', $script:DeployedLensDir, ('specs/' + $script:FeatureRef + '/workshop'))) {
        New-Item -ItemType Directory -Path (Join-Path $scratch $dir) -Force | Out-Null
    }
    Set-Content -LiteralPath (Join-Path $scratch '.specrew/config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value '# Agenda grouping fixture' -Encoding UTF8
    Copy-Item -LiteralPath $IndexSource -Destination (Join-Path $scratch ($script:DeployedLensDir + '/index.yml')) -Force
    & (Join-Path $RepoRoot $script:InitializerRelative) -ProjectRoot $scratch -FeatureRef $script:FeatureRef | Out-Null

    . (Join-Path $RepoRoot $script:AuthorityRelative)
    $messageHash = Get-SpecrewWorkshopAuthorityHash -Text ('feature|' + $script:FeatureRef + '||product-domain|Fixture question?')
    [ordered]@{
        schema = 'v3'; status = 'workshop-active'; scope = 'feature'; feature_ref = $script:FeatureRef; iteration_number = ''
        lens = 'product-domain'; phase = 'product-domain'; agenda_status = 'pending-confirmation'; question = 'Fixture question?'
        message_hash = $messageHash; artifact_path = (Join-Path $feature 'lens-applicability.json')
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $scratch '.specrew/handover/workshop-question.json') -Encoding UTF8
    $null = Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response 'The product framing matches.' -HostKind 'test' -SourceEvent 'UserPromptSubmit'
    Set-Content -LiteralPath (Join-Path $feature 'workshop/product-domain.md') -Value '# Product domain' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $feature 'workshop/product-domain.yml') -Value 'depth: light' -Encoding UTF8
    return $scratch
}

function New-AgendaJson {
    param([Collections.IDictionary]$Spaces, [string[]]$Selected)
    $technical = @($Spaces.Keys | Where-Object { $_ -ne 'product-domain' })
    [ordered]@{
        selected = @($technical | Where-Object { $_ -in $Selected } | ForEach-Object { [ordered]@{ lens = $_; depth = 'light'; decision = "Decide $_ for the fixture." } })
        skipped  = @($technical | Where-Object { $_ -notin $Selected } | ForEach-Object { [ordered]@{ lens = $_; reason = "$_ does not apply to the fixture." } })
    } | ConvertTo-Json -Depth 6 -Compress
}

function Write-ChildDriver {
    # The child process sets a non-UTF-8 (Latin-1) console encoding, then runs the writer the way an agent's shell
    # would, or (probe) writes one marker itself to prove the encoding is in effect.
    param([string]$Path)
    $driver = @'
param([string]$Mode, [string]$Writer, [string]$ProjectRoot, [string]$FeatureRef, [string]$AgendaPath)
[Console]::OutputEncoding = [Text.Encoding]::Latin1
$OutputEncoding = [Text.Encoding]::Latin1
if ($Mode -eq 'probe') { Write-Output ([char]::ConvertFromUtf32(0x1F7E6) + ' probe'); exit 0 }
$json = [IO.File]::ReadAllText($AgendaPath)
& $Writer -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -AgendaJson $json -RenderOnly
exit $LASTEXITCODE
'@
    [IO.File]::WriteAllText($Path, $driver, [Text.UTF8Encoding]::new($false))
}

function Invoke-Child {
    # Runs the driver in a separate pwsh and decodes its stdout as UTF-8, as a reader expecting UTF-8 would.
    param([string]$Driver, [string[]]$Arguments)
    $psi = [Diagnostics.ProcessStartInfo]::new([Environment]::ProcessPath)
    foreach ($argument in @('-NoProfile', '-NonInteractive', '-File', $Driver) + $Arguments) { $psi.ArgumentList.Add($argument) }
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $process = [Diagnostics.Process]::Start($psi)
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    [pscustomobject]@{ ExitCode = $process.ExitCode; Stdout = $stdout; Stderr = $stderr }
}

function Invoke-Render {
    # Renders one agenda in a scratch project through the child driver; returns the decoded output and the stored
    # canonical_text. The scratch folder is removed by its exact path.
    param([string]$IndexSource, [string[]]$Selected, [string]$Driver)
    $scratch = New-ScratchProject -IndexSource $IndexSource
    try {
        $spaces = Get-IndexSpaces -IndexPath $IndexSource
        $agendaPath = Join-Path $scratch 'agenda.json'
        [IO.File]::WriteAllText($agendaPath, (New-AgendaJson -Spaces $spaces -Selected $Selected), [Text.UTF8Encoding]::new($false))
        $child = Invoke-Child -Driver $Driver -Arguments @('-Mode', 'render', '-Writer', (Join-Path $RepoRoot $script:WriterRelative),
            '-ProjectRoot', $scratch, '-FeatureRef', $script:FeatureRef, '-AgendaPath', $agendaPath)
        $canonical = $null
        $proposalPath = Join-Path $scratch $script:ProposalRelative
        if (Test-Path -LiteralPath $proposalPath) {
            $canonical = ([IO.File]::ReadAllText($proposalPath, [Text.UTF8Encoding]::new($false)) | ConvertFrom-Json).canonical_text
        }
        [pscustomobject]@{ Child = $child; Canonical = $canonical; Spaces = $spaces }
    }
    finally {
        if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
    }
}

function ConvertTo-Lf {
    param([string]$Text)
    (($Text -replace "`r`n", "`n").TrimEnd("`n"))
}

function Test-Render {
    # Problems for one rendered agenda: the writer's exit, the round trip, and the grouping.
    param([string]$Name, $Render, [string[]]$Selected)
    if ($Render.Child.ExitCode -ne 0 -or $null -eq $Render.Canonical) {
        New-Problem $Name 'render' ("the writer did not render (exit {0}): {1}" -f $Render.Child.ExitCode, $Render.Child.Stderr.Trim())
        return
    }
    $decoded = ConvertTo-Lf $Render.Child.Stdout
    if ($decoded -cne (ConvertTo-Lf $Render.Canonical)) {
        New-Problem $Name 'utf8-round-trip' 'the block read back from a Latin-1 console is not the stored canonical_text'
    }
    foreach ($problem in @(Test-GroupedAgenda -Text $Render.Canonical -Spaces $Render.Spaces -Selected $Selected)) {
        New-Problem ('{0}: {1}' -f $Name, $problem.Item) $problem.Check $problem.Detail
    }
}

#endregion

#region self-tests

function Get-SyntheticAgenda {
    # A valid grouped agenda over a small synthetic catalog, as lines.
    @(
        'Workshop agenda', '', $script:SelectedLine, '',
        $script:Headings.problem, '- requirements-nfr (light): r', '',
        $script:Headings.both, '- data-storage (light): d', '- devops-operations (light): o', '',
        $script:Headings.solution, '- architecture-core (light): a', '- code-implementation (light): c', '',
        $script:SkippedLine, '- ui-ux: u', '', $script:ClosingQuestion
    )
}

function Invoke-SyntheticCase {
    param([string]$Name, [scriptblock]$Mutate, [string]$Item, [string]$Check)
    $spaces = [ordered]@{ 'requirements-nfr' = 'problem'; 'ui-ux' = 'both'; 'data-storage' = 'both'; 'devops-operations' = 'both'; 'architecture-core' = 'solution'; 'code-implementation' = 'solution' }
    $selected = @('requirements-nfr', 'data-storage', 'devops-operations', 'architecture-core', 'code-implementation')
    $lines = [Collections.Generic.List[string]]::new([string[]](Get-SyntheticAgenda))
    if ($null -ne $Mutate) { & $Mutate $lines $spaces }
    $problems = @(Test-GroupedAgenda -Text ($lines -join "`n") -Spaces $spaces -Selected $selected)
    if ([string]::IsNullOrEmpty($Item)) {
        Assert-True ($problems.Count -eq 0) ("{0}: no problems (got: {1})" -f $Name, (($problems | ForEach-Object { Format-Problem $_ }) -join '; '))
    }
    else {
        $hit = @($problems | Where-Object { $_.Item -eq $Item -and $_.Check -eq $Check }).Count -gt 0
        Assert-True $hit ("{0}: a problem names {1} [{2}]" -f $Name, $Item, $Check)
    }
}

function Invoke-SelfTests {
    $h = $script:Headings
    $sel = $script:SelectedLine
    Invoke-SyntheticCase -Name 'valid grouped agenda' -Mutate $null
    Invoke-SyntheticCase -Name 'lens under the wrong heading' -Item 'data-storage' -Check 'grouping' -Mutate {
        param($l, $s) $l.Remove('- data-storage (light): d') | Out-Null; $l.Insert($l.IndexOf('- architecture-core (light): a'), '- data-storage (light): d')
    }
    Invoke-SyntheticCase -Name 'tag changed, text not regrouped' -Item 'devops-operations' -Check 'grouping' -Mutate {
        param($l, $s) $s['devops-operations'] = 'solution'
    }
    Invoke-SyntheticCase -Name 'headings out of order' -Item $h.problem -Check 'heading-order' -Mutate {
        param($l, $s) $at = $l.IndexOf($h.problem); $l.RemoveRange($at, 3); $l.InsertRange($l.IndexOf($h.solution) + 3, [string[]]@('', $h.problem, '- requirements-nfr (light): r'))
    }.GetNewClosure()
    Invoke-SyntheticCase -Name 'empty heading kept' -Item $h.problem -Check 'empty-heading' -Mutate {
        param($l, $s) $l.Remove('- requirements-nfr (light): r') | Out-Null; $s['requirements-nfr'] = 'problem'
    }
    Invoke-SyntheticCase -Name 'marker removed from a heading' -Item 'Both spaces' -Check 'unexpected-line' -Mutate {
        param($l, $s) $l[$l.IndexOf($h.both)] = 'Both spaces'
    }.GetNewClosure()
    Invoke-SyntheticCase -Name 'order inside a heading swapped' -Item 'data-storage' -Check 'order-in-heading' -Mutate {
        param($l, $s) $at = $l.IndexOf('- data-storage (light): d'); $l[$at] = '- devops-operations (light): o'; $l[$at + 1] = '- data-storage (light): d'
    }
    Invoke-SyntheticCase -Name 'Selected lenses line removed' -Item $sel -Check 'kept-line' -Mutate {
        param($l, $s) $l.Remove($sel) | Out-Null
    }.GetNewClosure()
    Invoke-SyntheticCase -Name 'closing question reworded' -Item $script:ClosingQuestion -Check 'kept-line' -Mutate {
        param($l, $s) $l[$l.Count - 1] = 'Does this look right?'
    }
}

#endregion

$probeDir = Join-Path ([IO.Path]::GetTempPath()) ('specrew-agenda-grouping-driver-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
$driver = Join-Path $probeDir 'render-driver.ps1'
try {
    Write-ChildDriver -Path $driver

    Write-Host '--- workshop-agenda-grouping: self-tests ---'
    Invoke-SelfTests
    $probe = Invoke-Child -Driver $driver -Arguments @('-Mode', 'probe')
    $probeMarker = [char]::ConvertFromUtf32(0x1F7E6) + ' probe'
    Assert-True ($probe.ExitCode -eq 0 -and (ConvertTo-Lf $probe.Stdout) -cne $probeMarker) 'probe: the child really writes with a non-UTF-8 console encoding (an unforced marker does not survive)'

    Write-Host '--- workshop-agenda-grouping: repository check ---'
    $realIndex = Join-Path $RepoRoot $script:IndexRelative
    $threeGroups = @('requirements-nfr', 'data-storage', 'devops-operations', 'architecture-core', 'code-implementation')
    $noBoth = @('requirements-nfr', 'architecture-core', 'code-implementation')
    $problems = @(Test-Render -Name 'real catalog, three groups' -Render (Invoke-Render -IndexSource $realIndex -Selected $threeGroups -Driver $driver) -Selected $threeGroups) +
        @(Test-Render -Name 'real catalog, no both-spaces lens' -Render (Invoke-Render -IndexSource $realIndex -Selected $noBoth -Driver $driver) -Selected $noBoth)

    $fixtureIndex = Join-Path $probeDir 'index-data-storage-solution.yml'
    $indexText = [IO.File]::ReadAllText($realIndex)
    $moved = [regex]::Replace($indexText, '(?ms)(^\s*-\s+id:\s*data-storage\s*$.*?^\s+space:\s*)both', '${1}solution', [Text.RegularExpressions.RegexOptions]::None)
    if ($moved -ceq $indexText) { throw 'fixture: could not change data-storage''s space in index.yml' }
    [IO.File]::WriteAllText($fixtureIndex, $moved, [Text.UTF8Encoding]::new($false))
    $fixtureRender = Invoke-Render -IndexSource $fixtureIndex -Selected $threeGroups -Driver $driver
    $problems += @(Test-Render -Name 'fixture, data-storage tagged solution' -Render $fixtureRender -Selected $threeGroups)
}
finally {
    if (Test-Path -LiteralPath $probeDir) { Remove-Item -LiteralPath $probeDir -Recurse -Force }
}

foreach ($problem in $problems) { Write-Host ('  ' + (Format-Problem $problem)) -ForegroundColor Red }
if ($script:SelfTestFailures -gt 0 -or $problems.Count -gt 0) {
    Write-Host ('workshop-agenda-grouping: {0} self-test(s) failed, {1} repository problem(s)' -f $script:SelfTestFailures, $problems.Count) -ForegroundColor Red
    exit 1
}
Write-Host 'workshop-agenda-grouping: all checks passed' -ForegroundColor Green
exit 0
