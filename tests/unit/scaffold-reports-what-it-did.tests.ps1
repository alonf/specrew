[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# CLASS GUARD: AN OPERATION THAT REPORTS SUCCESS WHILE ONE OF ITS EFFECTS SILENTLY DID NOT OCCUR.
#
# Measured 2026-09-05 on a fresh walk project. The scaffold printed `BRANCH_NAME: 001-csv-to-json`, the
# agent reported the feature as scaffolded, and the project sat on `master` with no such branch anywhere.
# Neither statement was false: BRANCH_NAME is the feature reference, and it is also the name a branch WOULD
# have had. The reader had no way to tell which they were being told, and the agent then spent three
# minutes reading Spec Kit source trying to work out why the branch was missing.
#
# WHY IT WAS MISSING, and it is not a failure: Spec Kit 0.12.9 moved branch creation out of
# create-new-feature.ps1 into its OPTIONAL `git` extension, and `specrew init` installs only
# specrew-speckit. So no component in a project created today makes branches. This repository still
# branches because its .specify copies date from 2026-04-17 and predate that split - which is exactly why
# it went unseen for so long: the tree Specrew is developed in is not shaped like the trees it creates.
#
# The fix is a sentence, not a boolean. A field named after an effect, printed whether or not the effect
# happened, is not a report. This guard asserts the sentence is present, correct for each state, and fully
# rendered.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scaffoldPath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/create-governed-feature.ps1'
Assert-True (Test-Path -LiteralPath $scaffoldPath -PathType Leaf) 'the governed feature scaffold exists to be read'

# Extracted by AST rather than dot-sourced: the scaffold creates features when it runs.
$errors = $null
$scaffoldAst = [System.Management.Automation.Language.Parser]::ParseFile($scaffoldPath, [ref] $null, [ref] $errors)
if ($errors -and $errors.Count -gt 0) { throw "FAIL: the scaffold has $($errors.Count) parse errors" }
$reporterAst = $scaffoldAst.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Get-SpecrewFeatureBranchOutcomeLine'
    }, $true)
Assert-True ($null -ne $reporterAst) 'the scaffold still defines Get-SpecrewFeatureBranchOutcomeLine'
. ([scriptblock]::Create($reporterAst.Extent.Text))

# And it must actually be CALLED, or the report exists and is never emitted - which is the same silence.
$scaffoldText = Get-Content -LiteralPath $scaffoldPath -Raw -Encoding UTF8
Assert-True ($scaffoldText.Contains('Write-Output (Get-SpecrewFeatureBranchOutcomeLine')) 'the scaffold EMITS the branch outcome rather than merely defining it'

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("specrew-branch-report-{0}" -f ([guid]::NewGuid().ToString('N')))
$null = New-Item -ItemType Directory -Path $scratch -Force

function New-Repo {
    param([string] $Name)
    $root = Join-Path $scratch $Name
    $null = New-Item -ItemType Directory -Path $root -Force
    & git -C $root init -q
    & git -C $root -c user.email='t@example.invalid' -c user.name='t' commit -q --allow-empty -m 'base'
    return $root
}

try {
    $lines = [Collections.Generic.List[string]]::new()

    # 1. No repository at all.
    $plain = Join-Path $scratch 'not-a-repo'
    $null = New-Item -ItemType Directory -Path $plain -Force
    $noRepoLine = Get-SpecrewFeatureBranchOutcomeLine -ProjectRoot $plain -FeatureRef '004-none'
    [void] $lines.Add($noRepoLine)
    Assert-True ($noRepoLine -match 'not a git repository') 'a non-repository says so, rather than reporting a branch name'

    # 2. On the feature branch - the effect DID occur.
    $onBranch = New-Repo -Name 'on-feature-branch'
    & git -C $onBranch checkout -q -b '002-demo'
    $onLine = Get-SpecrewFeatureBranchOutcomeLine -ProjectRoot $onBranch -FeatureRef '002-demo'
    [void] $lines.Add($onLine)
    Assert-True ($onLine -match 'created and checked out') 'a project standing on the feature branch is told the branch was created and checked out'
    Assert-True ($onLine -match '002-demo') 'the created-and-checked-out line names the branch'

    # 3. The branch exists but HEAD is elsewhere - a partial effect, and it must not read as success.
    $elsewhere = New-Repo -Name 'branch-exists-elsewhere'
    $baseBranch = (& git -C $elsewhere rev-parse --abbrev-ref HEAD).Trim()
    & git -C $elsewhere checkout -q -b '003-other'
    & git -C $elsewhere checkout -q $baseBranch
    $existsLine = Get-SpecrewFeatureBranchOutcomeLine -ProjectRoot $elsewhere -FeatureRef '003-other'
    [void] $lines.Add($existsLine)
    Assert-True ($existsLine -match 'exists but is not checked out') 'an existing but unchecked-out branch is reported as exactly that'
    Assert-True ($existsLine -match [regex]::Escape($baseBranch)) 'the partial-effect line names the branch actually in use'

    # 4. THE MEASURED CASE. A repository where nothing created a branch.
    $noBranch = New-Repo -Name 'no-branch-created'
    $noBranchBase = (& git -C $noBranch rev-parse --abbrev-ref HEAD).Trim()
    $missingLine = Get-SpecrewFeatureBranchOutcomeLine -ProjectRoot $noBranch -FeatureRef '001-csv-to-json'
    [void] $lines.Add($missingLine)
    Assert-True ($missingLine -match 'not created') 'THE MEASURED CASE: a branch that was never created is reported as not created, in words'
    Assert-True ($missingLine -match [regex]::Escape($noBranchBase)) 'the not-created line names the branch the project is actually on'
    Assert-True ($missingLine -match "Nothing failed") 'the not-created line says plainly that nothing failed, so it does not read as an error'
    Assert-True ($missingLine -match '001-csv-to-json') 'the not-created line still names the feature, which is what the reader needs next'

    # The four states must be distinguishable from one another, or the report is decoration.
    $distinct = @($lines | Select-Object -Unique)
    Assert-True (@($distinct).Count -eq 4) 'the four outcomes produce four DIFFERENT sentences - a constant string would pass every check above'

    # Rendering regression: an unrendered {0} means the format operator bound to the wrong operand.
    foreach ($line in $lines) {
        Assert-True ($line -notmatch '\{\d+\}') ("every outcome line is fully rendered, with no literal placeholder left in it: {0}" -f $line.Substring(0, [Math]::Min(60, $line.Length)))
    }
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host 'scaffold reports what it did: all assertions pass' -ForegroundColor Green
