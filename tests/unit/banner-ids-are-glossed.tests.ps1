[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# FR-016 / W22 (2026-08-17): the consumer-language layer shipped with its detector and gloss helper
# written, tested in isolation, and wired to nothing. The orientation banner - the first prose a human
# reads in any hook-started session - still emitted bare `FR-004`, `FR-020`, `FR-022`, `FR-023`,
# `FR-025` and `FR-027`, each an identifier the reader must go and look up before the sentence means
# anything. That is the exact failure the layer's own header names.
#
# Recorded as a round-5 major and deferred to beta4 on 2026-08-11 as "does not block the bar"; a later
# campaign round raised it again against the frozen UI/UX design context, which requires every
# requirement reference in human-visible prose to carry both the identifier and a short description.
# Fixed rather than deferred a second time, on the maintainer directive to fix all issues.
#
# ENFORCEMENT IS THE POINT. A helper nobody calls guards nothing, so this runs the project's OWN
# detector over the lines the banner actually emits. It covers strings written by anyone, including the
# ones nobody has written yet - which a per-call-site convention could not.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\specrew-consumer-language.ps1')
Assert-True ($null -ne (Get-Command Get-SpecrewUnglossedId -ErrorAction SilentlyContinue)) 'the consumer-language detector loads'

# All three shipped copies: the module source, the extension source, and the deployed mirror. A gloss
# applied to one and missed in another still reaches a consumer through whichever copy their host runs.
$bannerFiles = @(
    'scripts\internal\specrew-bootstrap-provider.ps1'
    'extensions\specrew-speckit\scripts\specrew-bootstrap-provider.ps1'
    '.specify\extensions\specrew-speckit\scripts\specrew-bootstrap-provider.ps1'
) | ForEach-Object { Join-Path $repoRoot $_ }

function Get-EmittedStringLiterals {
    # The strings the banner puts in front of a human: arguments to the line collector and to direct
    # console writes. Read structurally so a comment mentioning an id is not mistaken for output.
    param([Parameter(Mandatory)][string]$Path)
    $tokens = $null; $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    if ($null -ne $parseErrors -and @($parseErrors).Count -gt 0) { throw "banner provider does not parse: $($parseErrors[0].Message)" }

    $emitted = [Collections.Generic.List[string]]::new()
    foreach ($node in @($ast.FindAll({
                    param($n)
                    ($n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and [string]$n.Member.Extent.Text -eq 'Add') -or
                    ($n -is [System.Management.Automation.Language.CommandAst] -and [string]$n.GetCommandName() -in @('Write-Output', 'Write-Host'))
                }, $true))) {
        foreach ($literal in @($node.FindAll({
                        param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
                        $n -is [System.Management.Automation.Language.ExpandableStringExpressionAst]
                    }, $true))) {
            $emitted.Add([string]$literal.Extent.Text) | Out-Null
        }
    }
    return @($emitted)
}

$totalEmitted = 0
foreach ($file in $bannerFiles) {
    Assert-True (Test-Path -LiteralPath $file -PathType Leaf) ("banner copy exists: {0}" -f (Split-Path $file -Leaf))
    $emitted = Get-EmittedStringLiterals -Path $file
    $totalEmitted += @($emitted).Count
    $offenders = [Collections.Generic.List[string]]::new()
    foreach ($line in $emitted) {
        foreach ($id in @(Get-SpecrewUnglossedId -Text $line)) {
            $offenders.Add(("{0} in: {1}" -f $id, $line.Substring(0, [Math]::Min(90, $line.Length)))) | Out-Null
        }
    }
    Assert-True (@($offenders).Count -eq 0) ("no bare requirement id reaches the reader from {0}{1}" -f (Split-Path (Split-Path $file -Parent) -Leaf), $(if (@($offenders).Count -gt 0) { " -> $($offenders -join ' | ')" } else { '' }))
}
Assert-True ($totalEmitted -ge 50) ("the banner's emitted prose was actually read, not silently empty (found {0} strings)" -f $totalEmitted)

# W46 (2026-08-22) SUPERSEDES THE GLOSS REQUIREMENT WITH THE STRONGER FORM. W22 required each cited id
# to carry its meaning in brackets; the maintainer then ruled the ids themselves out of emitted strings
# entirely (internal requirement ids are Specrew's inside voice, and they collide with the consumer's
# own FR namespace). So the pin flips: the MEANING must survive in the banner prose, and the id must be
# GONE from it - it now lives in the adjacent comment, the sanctioned half of the provenance rule.
$sourceText = Get-Content -LiteralPath $bannerFiles[0] -Raw -Encoding UTF8
foreach ($pair in @(
        @{ Id = 'FR-027'; Gloss = 'a committed boundary is not an approved one' }
        @{ Id = 'FR-022'; Gloss = 'you author the handover body' }
        @{ Id = 'FR-023'; Gloss = 'identical launch contract' }
        @{ Id = 'FR-025'; Gloss = 'expertise dials' }
        @{ Id = 'FR-004'; Gloss = 'shown as prose before any picker' })) {
    Assert-True ($sourceText -match [regex]::Escape($pair.Gloss)) ("the meaning behind {0} still reaches the reader in consumer terms" -f $pair.Id)
    # Every remaining occurrence of the id must sit inside a comment: on each line that carries it, a
    # '#' must precede it. That is exactly where the citation belongs - and only there.
    $outsideComment = @(Get-Content -LiteralPath $bannerFiles[0] -Encoding UTF8 | Where-Object {
            $_.Contains($pair.Id) -and ($_.IndexOf('#') -lt 0 -or $_.IndexOf($pair.Id) -lt $_.IndexOf('#'))
        })
    Assert-True (@($outsideComment).Count -eq 0) ("{0} no longer appears outside a comment - the id lives in comments now" -f $pair.Id)
}

# MUTATION PROOF: a newly added bare id must fail this guard, or it certifies text nobody checked.
$mutatedLine = '$lines.Add(''Read the plan before you approve FR-999.'')'
$mutatedOffenders = @(Get-SpecrewUnglossedId -Text $mutatedLine)
Assert-True (@($mutatedOffenders).Count -eq 1 -and $mutatedOffenders[0] -eq 'FR-999') 'mutation proof: a bare requirement id added to a banner line is detected'
$glossedLine = '$lines.Add(''Read the plan before you approve FR-999 (the thing it requires).'')'
Assert-True (@(Get-SpecrewUnglossedId -Text $glossedLine).Count -eq 0) 'the same line with a real description passes, so the guard is not simply banning ids'

Write-Host 'banner ids are glossed: all assertions pass' -ForegroundColor Green
