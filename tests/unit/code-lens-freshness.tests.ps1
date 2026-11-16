[CmdletBinding()]
param(
    # The repository whose code lens is checked. Defaults to this checkout.
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

# Feature 205 (proposal 220, iteration 3): the code-implementation lens's freshness (FR-030, SC-011, Amendment A3).
#
# Per item, never totals (iteration 002 retro action 1). For each of the six per-stack rules in code-rules.yml:
# - the rule carries a valid `sources_checked` date and a non-empty `current` field;
# - neither its `title` nor its `default` holds a version number (versions live only in `current`, which the dated
#   line shows, and in the lens's Source Notes);
# - the line function shows "<stack> — sources last checked <date>: <current>", with no stale marker 90 days after
#   `sources_checked` and with it 91 days after;
# - the lens's Source Notes name the stack with a URL and a date.
# For the lens's Workshop Conduct: it tells the agent to show the lines, it carries the confirm-at-the-point-of-choice
# rule and its no-lookup fallback (Amendment A3). For the workshop skill: its "not invoked mid-workshop" sentence names
# the line function as the one read-only exception.
#
# Self-tests over a scratch fixture run first and prove every check able to fail, naming the rule or the sentence.
# Every problem is reported in one run.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CatalogRelative = 'extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml'
$script:LensRelative = 'extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md'
$script:SkillRelative = 'extensions/specrew-speckit/squad-templates/skills/design-workshop.md'
$script:HelperRelative = 'scripts/internal/code-implementation-lens.ps1'
$script:LineFunction = 'Get-SpecrewCodeStackFreshnessLines'
$script:StaleAfterDays = 90
$script:StaleMarker = ' — stale: check the release notes before relying on it'
$script:DateFormat = 'yyyy-MM-dd'

# The six per-stack rules and the stack label each line and Source Notes entry uses.
$script:Stacks = [ordered]@{
    'code-rule.csharp.langversion-posture'         = 'C#/.NET'
    'code-rule.cpp.standard-and-safety-posture'    = 'C/C++'
    'code-rule.ts.strictness-posture'              = 'TypeScript/JavaScript'
    'code-rule.python.typing-and-layout-posture'   = 'Python'
    'code-rule.go.boundaries-and-tooling-posture'  = 'Go'
    'code-rule.java.baseline-and-tooling-posture'  = 'Java'
}
# The catalog scope of each per-stack rule (the line function finds a stack's rule by its scope).
$script:StackScopes = [ordered]@{
    'code-rule.csharp.langversion-posture'         = 'language:csharp-dotnet'
    'code-rule.cpp.standard-and-safety-posture'    = 'language:c-cpp'
    'code-rule.ts.strictness-posture'              = 'language:typescript-javascript'
    'code-rule.python.typing-and-layout-posture'   = 'language:python'
    'code-rule.go.boundaries-and-tooling-posture'  = 'language:go'
    'code-rule.java.baseline-and-tooling-posture'  = 'language:java'
}

# A version number in rule text: a dotted number (8.0, 3.12), a language standard (C11, C++20, the "/17" of
# "C11/17"), or a product name followed by a number (.NET 9, Java 21, Python 3, ES2022).
$script:VersionPattern = '\b\d+\.\d+(?:\.\d+)*\b|\bC\+\+\s?\d{2}\b|\bC\d{2}\b|(?<=/)\d{2}\b|(?:\.NET|\bC#|\bJava|\bJDK|\bPython|\bGo|\bTypeScript|\bNode(?:\.js)?|\bECMAScript|\bES)\s?\d+\b'

# The conduct sentences, each identified by the phrases it must contain (all of them, inside ## Workshop Conduct).
$script:ConductSentences = [ordered]@{
    'show-the-lines'               = @($script:LineFunction)
    'confirm-at-the-point-of-choice' = @('depends on a version', 'confirm it against the official source', 'the source and the date', 'not stale')
    'no-lookup-fallback'           = @('cannot look a source up', 'unconfirmed', 'never guess')
}
$script:SkillExceptionAnchor = 'not invoked mid-workshop'
$script:SkillExceptionWindow = 400
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

function Get-NormalizedLines {
    param([string]$Path)
    @(([IO.File]::ReadAllText($Path) -replace "`r`n", "`n") -split "`n")
}

function Get-RuleBlock {
    # The lines of one catalog rule, from its `- id:` line to the next `- id:` line.
    param([string[]]$Lines, [string]$RuleId)
    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\s*-\s+id:\s*"?([^"\s]+)"?\s*$') {
            if ($start -ge 0) { return @($Lines[$start..($i - 1)]) }
            if ($Matches[1] -eq $RuleId) { $start = $i }
        }
    }
    if ($start -ge 0) { return @($Lines[$start..($Lines.Count - 1)]) }
    return @()
}

function Get-RuleField {
    param([string[]]$Block, [string]$Field)
    foreach ($line in $Block) {
        if ($line -match ('^\s+{0}:\s*(.*?)\s*$' -f [regex]::Escape($Field))) {
            return ($Matches[1] -replace '^"(.*)"$', '$1')
        }
    }
    return $null
}

function Get-SectionLines {
    # The lines under a `## <Heading>`, up to the next `## ` heading.
    param([string[]]$Lines, [string]$Heading)
    $inside = $false
    $result = [Collections.Generic.List[string]]::new()
    foreach ($line in $Lines) {
        if ($line -match '^##\s+(.+?)\s*$' -and $line -notmatch '^###') {
            $inside = ($Matches[1] -eq $Heading)
            continue
        }
        if ($inside) { $result.Add($line) }
    }
    return @($result)
}

function ConvertTo-CheckedDate {
    param([string]$Text)
    $parsed = [datetime]::MinValue
    $ok = [datetime]::TryParseExact($Text, $script:DateFormat, [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None, [ref]$parsed)
    if ($ok) { return $parsed }
    return $null
}

#endregion

#region checks

function Test-RuleFields {
    param([string]$CatalogPath)
    $lines = Get-NormalizedLines $CatalogPath
    foreach ($ruleId in $script:Stacks.Keys) {
        $block = Get-RuleBlock -Lines $lines -RuleId $ruleId
        if ($block.Count -eq 0) { New-Problem $ruleId 'rule-present' 'the rule is missing from code-rules.yml'; continue }
        $checked = Get-RuleField -Block $block -Field 'sources_checked'
        if ([string]::IsNullOrWhiteSpace($checked)) {
            New-Problem $ruleId 'sources-checked' 'no sources_checked date; add the date its sources were checked (yyyy-MM-dd)'
        }
        elseif ($null -eq (ConvertTo-CheckedDate $checked)) {
            New-Problem $ruleId 'sources-checked' ("sources_checked '{0}' is not a yyyy-MM-dd date" -f $checked)
        }
        $current = Get-RuleField -Block $block -Field 'current'
        if ([string]::IsNullOrWhiteSpace($current)) {
            New-Problem $ruleId 'current' 'no current field; put the confirmed versions there'
        }
        foreach ($field in @('title', 'default')) {
            $text = Get-RuleField -Block $block -Field $field
            if ($null -eq $text) { continue }
            $found = @([regex]::Matches($text, $script:VersionPattern) | ForEach-Object Value)
            if ($found.Count -gt 0) {
                New-Problem $ruleId 'no-version-in-text' ("{0} holds version number(s) {1}; move them to current" -f $field, ($found -join ', '))
            }
        }
    }
}

function Test-FreshnessLines {
    param([string]$CatalogPath)
    $command = Get-Command -Name $script:LineFunction -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        New-Problem $script:LineFunction 'line-function' ("{0} is not defined in {1}" -f $script:LineFunction, $script:HelperRelative)
        return
    }
    $lines = Get-NormalizedLines $CatalogPath
    foreach ($ruleId in $script:Stacks.Keys) {
        $label = $script:Stacks[$ruleId]
        $block = Get-RuleBlock -Lines $lines -RuleId $ruleId
        $checkedText = Get-RuleField -Block $block -Field 'sources_checked'
        $checked = if ($checkedText) { ConvertTo-CheckedDate $checkedText } else { $null }
        if ($null -eq $checked) { New-Problem $ruleId 'stale-marker' 'cannot test the line without a valid sources_checked date'; continue }
        $current = Get-RuleField -Block $block -Field 'current'
        $expected = '{0} — sources last checked {1}: {2}' -f $label, $checkedText, $current
        foreach ($case in @(@{ Days = $script:StaleAfterDays; Stale = $false }, @{ Days = $script:StaleAfterDays + 1; Stale = $true })) {
            $today = $checked.AddDays($case.Days)
            $output = @(& $command -CatalogPath $CatalogPath -Today $today)
            $line = @($output | Where-Object { ([string]$_).StartsWith("$label — ") })
            $want = if ($case.Stale) { $expected + $script:StaleMarker } else { $expected }
            if ($line.Count -ne 1) {
                New-Problem $ruleId 'stale-marker' ("{0} days on: expected one line for {1}, got {2}" -f $case.Days, $label, $line.Count)
            }
            elseif ([string]$line[0] -cne $want) {
                New-Problem $ruleId 'stale-marker' ("{0} days on: expected '{1}', got '{2}'" -f $case.Days, $want, $line[0])
            }
        }
    }
}

function Test-SourceNotes {
    param([string]$LensPath)
    # One entry per bullet, its wrapped continuation lines joined to it.
    $entries = [Collections.Generic.List[string]]::new()
    foreach ($line in (Get-SectionLines -Lines (Get-NormalizedLines $LensPath) -Heading 'Source Notes')) {
        if ($line -match '^\s*-\s') { $entries.Add($line.Trim()) }
        elseif ($entries.Count -gt 0 -and $line -match '^\s+\S') { $entries[$entries.Count - 1] += ' ' + $line.Trim() }
    }
    $notes = @($entries)
    foreach ($ruleId in $script:Stacks.Keys) {
        $label = $script:Stacks[$ruleId]
        # The label as a whole word: "Go" must not match "Google".
        $labelPattern = '(?<![\w/#+.]){0}(?![\w/#+])' -f [regex]::Escape($label)
        $hit = @($notes | Where-Object {
                $_ -match $labelPattern -and $_ -match 'https?://\S+' -and $_ -match '\b\d{4}-\d{2}-\d{2}\b'
            })
        if ($hit.Count -eq 0) {
            New-Problem $ruleId 'source-notes' ("Source Notes have no entry naming '{0}' with a URL and a date" -f $label)
        }
    }
}

function Test-ConductSentences {
    param([string]$LensPath)
    $conduct = (Get-SectionLines -Lines (Get-NormalizedLines $LensPath) -Heading 'Workshop Conduct') -join ' '
    $conduct = $conduct -replace '\s+', ' '
    foreach ($name in $script:ConductSentences.Keys) {
        $missing = @($script:ConductSentences[$name] | Where-Object { -not $conduct.Contains($_) })
        if ($missing.Count -gt 0) {
            New-Problem $name 'conduct' ("Workshop Conduct lacks: {0}" -f (($missing | ForEach-Object { "'$_'" }) -join ', '))
        }
    }
}

function Test-SkillException {
    param([string]$SkillPath)
    $text = ([IO.File]::ReadAllText($SkillPath) -replace '\s+', ' ')
    $at = $text.IndexOf($script:SkillExceptionAnchor)
    if ($at -lt 0) { New-Problem 'skill-exception' 'skill' ("the skill no longer says '{0}'" -f $script:SkillExceptionAnchor); return }
    $window = $text.Substring($at, [Math]::Min($script:SkillExceptionWindow, $text.Length - $at))
    if (-not $window.Contains($script:LineFunction)) {
        New-Problem 'skill-exception' 'skill' ("the '{0}' sentence does not name {1} as its read-only exception" -f $script:SkillExceptionAnchor, $script:LineFunction)
    }
}

function Invoke-AllChecks {
    param([string]$Root)
    $catalog = Join-Path $Root $script:CatalogRelative
    $lens = Join-Path $Root $script:LensRelative
    $skill = Join-Path $Root $script:SkillRelative
    @(Test-RuleFields -CatalogPath $catalog) +
    @(Test-FreshnessLines -CatalogPath $catalog) +
    @(Test-SourceNotes -LensPath $lens) +
    @(Test-ConductSentences -LensPath $lens) +
    @(Test-SkillException -SkillPath $skill)
}

#endregion

#region self-tests

function New-FixtureTree {
    # A synthetic, fully valid lens tree: six dated rules with no version in their text, Source Notes for each stack,
    # the three conduct sentences and the skill exception.
    param([string]$Root)
    $catalogLines = [Collections.Generic.List[string]]::new()
    $catalogLines.Add('rules:')
    $notes = [Collections.Generic.List[string]]::new()
    foreach ($ruleId in $script:Stacks.Keys) {
        $label = $script:Stacks[$ruleId]
        $catalogLines.Add("  - id: $ruleId")
        $catalogLines.Add('    group: decision-prompt')
        $catalogLines.Add("    scope: `"$($script:StackScopes[$ruleId])`"")
        $catalogLines.Add("    title: `"$label`: posture`"")
        $catalogLines.Add('    default: "strictness, layout and tooling posture"')
        $catalogLines.Add('    sources_checked: "2026-01-10"')
        $catalogLines.Add("    current: `"$label fixture release, supported`"")
        $catalogLines.Add('    enforcement_mode: [review]')
        $notes.Add("- $label — https://example.invalid/$($ruleId) (checked 2026-01-10)")
    }
    $lens = @(
        '# Code & Implementation', '', '## Workshop Conduct', '',
        "- When the stack is resolved, show the lines from $($script:LineFunction).",
        '- When the human''s choice depends on a version, confirm it against the official source at that point and show the source and the date, even when the line is not stale.',
        '- When the host cannot look a source up, say so in plain words and mark the version unconfirmed; never guess.',
        '', '## Source Notes', ''
    ) + @($notes) + @('')
    $skill = "The lens helper validates, it is not invoked mid-workshop, except $($script:LineFunction), the read-only line call."
    foreach ($pair in @(@($script:CatalogRelative, ($catalogLines -join "`n")), @($script:LensRelative, ($lens -join "`n")), @($script:SkillRelative, $skill))) {
        $path = Join-Path $Root $pair[0]
        New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null
        [IO.File]::WriteAllText($path, $pair[1] + "`n", [Text.UTF8Encoding]::new($false))
    }
}

function Edit-FixtureFile {
    param([string]$Root, [string]$Relative, [string]$Find, [string]$Replace)
    $path = Join-Path $Root $Relative
    $text = [IO.File]::ReadAllText($path)
    if (-not $text.Contains($Find)) { throw "fixture edit: '$Find' not found in $Relative" }
    $at = $text.IndexOf($Find)
    $text = $text.Substring(0, $at) + $Replace + $text.Substring($at + $Find.Length)
    [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}

function Test-HasProblem {
    param($Problems, [string]$Item, [string]$Check)
    @($Problems | Where-Object { $_.Item -eq $Item -and $_.Check -eq $Check }).Count -gt 0
}

function Invoke-SelfTest {
    param([string]$Name, [scriptblock]$Mutate, [string]$Item, [string]$Check)
    $scratch = Join-Path ([IO.Path]::GetTempPath()) ('code-lens-freshness-' + [guid]::NewGuid().ToString('N'))
    try {
        New-FixtureTree -Root $scratch
        if ($null -ne $Mutate) { & $Mutate $scratch }
        $problems = @(Invoke-AllChecks -Root $scratch)
        if ([string]::IsNullOrEmpty($Item)) {
            Assert-True ($problems.Count -eq 0) ("{0}: the valid fixture has no problems (got: {1})" -f $Name, (($problems | ForEach-Object { Format-Problem $_ }) -join '; '))
        }
        else {
            Assert-True (Test-HasProblem $problems $Item $Check) ("{0}: a problem names {1} [{2}]" -f $Name, $Item, $Check)
        }
    }
    finally {
        if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
    }
}

function Invoke-SelfTests {
    $cpp = 'code-rule.cpp.standard-and-safety-posture'
    $go = 'code-rule.go.boundaries-and-tooling-posture'
    $py = 'code-rule.python.typing-and-layout-posture'
    $cat = $script:CatalogRelative
    $lensRel = $script:LensRelative
    $skillRel = $script:SkillRelative
    $fn = $script:LineFunction
    Invoke-SelfTest -Name 'valid fixture' -Mutate $null
    Invoke-SelfTest -Name 'date swapped for a non-date' -Item $cpp -Check 'sources-checked' -Mutate {
        param($r) Edit-FixtureFile $r $cat "    sources_checked: `"2026-01-10`"`n    current: `"C/C++ fixture release, supported`"" "    sources_checked: `"2026-02-30`"`n    current: `"C/C++ fixture release, supported`""
    }.GetNewClosure()
    Invoke-SelfTest -Name 'date removed' -Item $go -Check 'sources-checked' -Mutate {
        param($r) Edit-FixtureFile $r $cat "    title: `"Go: posture`"`n    default: `"strictness, layout and tooling posture`"`n    sources_checked: `"2026-01-10`"`n" "    title: `"Go: posture`"`n    default: `"strictness, layout and tooling posture`"`n"
    }.GetNewClosure()
    Invoke-SelfTest -Name 'version put back into the default' -Item $cpp -Check 'no-version-in-text' -Mutate {
        param($r) Edit-FixtureFile $r $cat "    title: `"C/C++: posture`"`n    default: `"strictness, layout and tooling posture`"" "    title: `"C/C++: posture`"`n    default: `"C11/17 or C++20; strictness, layout and tooling posture`""
    }.GetNewClosure()
    Invoke-SelfTest -Name 'version put back into the title' -Item $py -Check 'no-version-in-text' -Mutate {
        param($r) Edit-FixtureFile $r $cat 'title: "Python: posture"' 'title: "Python 3.13: posture"'
    }.GetNewClosure()
    Invoke-SelfTest -Name 'current removed' -Item $go -Check 'current' -Mutate {
        param($r) Edit-FixtureFile $r $cat '    current: "Go fixture release, supported"' '    current: ""'
    }.GetNewClosure()
    Invoke-SelfTest -Name 'Source Notes line removed' -Item $py -Check 'source-notes' -Mutate {
        param($r) Edit-FixtureFile $r $lensRel "- Python — https://example.invalid/$py (checked 2026-01-10)`n" ''
    }.GetNewClosure()
    Invoke-SelfTest -Name 'show-the-lines sentence removed' -Item 'show-the-lines' -Check 'conduct' -Mutate {
        param($r) Edit-FixtureFile $r $lensRel "- When the stack is resolved, show the lines from $fn.`n" ''
    }.GetNewClosure()
    Invoke-SelfTest -Name 'confirm-at-the-point-of-choice sentence removed' -Item 'confirm-at-the-point-of-choice' -Check 'conduct' -Mutate {
        param($r) Edit-FixtureFile $r $lensRel "- When the human's choice depends on a version, confirm it against the official source at that point and show the source and the date, even when the line is not stale.`n" ''
    }.GetNewClosure()
    Invoke-SelfTest -Name 'no-lookup fallback removed' -Item 'no-lookup-fallback' -Check 'conduct' -Mutate {
        param($r) Edit-FixtureFile $r $lensRel "- When the host cannot look a source up, say so in plain words and mark the version unconfirmed; never guess.`n" ''
    }.GetNewClosure()
    Invoke-SelfTest -Name 'skill exception removed' -Item 'skill-exception' -Check 'skill' -Mutate {
        param($r) Edit-FixtureFile $r $skillRel ", except $fn, the read-only line call" ''
    }.GetNewClosure()
}

#endregion

$helperPath = Join-Path $RepoRoot $script:HelperRelative
. $helperPath

Write-Host '--- code-lens-freshness: self-tests ---'
Invoke-SelfTests

Write-Host '--- code-lens-freshness: repository check ---'
$problems = @(Invoke-AllChecks -Root $RepoRoot)
foreach ($problem in $problems) { Write-Host ('  ' + (Format-Problem $problem)) -ForegroundColor Red }

if ($script:SelfTestFailures -gt 0 -or $problems.Count -gt 0) {
    Write-Host ('code-lens-freshness: {0} self-test(s) failed, {1} repository problem(s)' -f $script:SelfTestFailures, $problems.Count) -ForegroundColor Red
    exit 1
}
Write-Host 'code-lens-freshness: all checks passed' -ForegroundColor Green
exit 0
