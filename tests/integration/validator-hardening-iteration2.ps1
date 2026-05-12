[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if (-not $Condition) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-Match {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if ($Text -notmatch $Pattern) {
        Write-Fail ("{0}`nObserved output:`n{1}" -f $FailureMessage, $Text)
        return $false
    }

    return $true
}

function Assert-NotMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if ($Text -match $Pattern) {
        Write-Fail ("{0}`nObserved output:`n{1}" -f $FailureMessage, $Text)
        return $false
    }

    return $true
}

function Assert-Equal {
    param(
        [AllowNull()][Parameter(Mandatory = $true)]$Actual,
        [AllowNull()][Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if ($Actual -cne $Expected) {
        Write-Fail ("{0}`nExpected: {1}`nActual: {2}" -f $FailureMessage, $Expected, $Actual)
        return $false
    }

    return $true
}

function Set-ContentUtf8 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Get-FixtureContent {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    return Get-Content -LiteralPath (Join-Path $fixtureRoot $RelativePath) -Raw -Encoding UTF8
}

function Replace-MarkdownSection {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Heading,
        [Parameter(Mandatory = $true)][string]$Body
    )

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $pattern = '(?s)(##\s+' + [regex]::Escape($Heading) + '\s*\r?\n)(.*?)(?=\r?\n##\s+|\z)'
    $replacementBody = $Body.TrimEnd()
    if ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, { param($match) $match.Groups[1].Value + $replacementBody + [Environment]::NewLine }, 1)
    }
    else {
        $content = $content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + "## $Heading" + [Environment]::NewLine + $replacementBody + [Environment]::NewLine
    }

    Set-ContentUtf8 -Path $Path -Content $content
}

function New-Workspace {
    param([Parameter(Mandatory = $true)][string]$WorkspaceName)

    $workspaceRoot = Join-Path $scratchRoot $WorkspaceName
    if (Test-Path -LiteralPath $workspaceRoot) {
        Remove-Item -LiteralPath $workspaceRoot -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $workspaceRoot -Force

    foreach ($item in @('.specrew', '.squad', '.github')) {
        $source = Join-Path $repoRoot $item
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination $workspaceRoot -Recurse -Force
        }
    }

    $featureDestination = Join-Path $workspaceRoot 'specs\013-validator-hardening'
    $featureParent = Split-Path -Parent $featureDestination
    if (-not (Test-Path -LiteralPath $featureParent)) {
        $null = New-Item -ItemType Directory -Path $featureParent -Force
    }
    Copy-Item -LiteralPath $featureSource -Destination $featureParent -Recurse -Force

    return $workspaceRoot
}

function Initialize-GitWorkspace {
    param([Parameter(Mandatory = $true)][string]$WorkspaceRoot)

    $null = & git -C $WorkspaceRoot init --quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to initialize git repository at $WorkspaceRoot"
    }

    $null = & git -C $WorkspaceRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $WorkspaceRoot config user.name 'Test User' 2>&1
}

function Commit-Workspace {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $null = & git -C $WorkspaceRoot add -A 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to stage workspace changes at $WorkspaceRoot"
    }

    $null = & git -C $WorkspaceRoot commit -m $Message --quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to commit workspace changes at $WorkspaceRoot"
    }
}

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string[]]$IterationPaths
    )

    $escapedValidatorScriptPath = $validatorScriptPath.Replace("'", "''")
    $escapedProjectPath = $ProjectPath.Replace("'", "''")
    $iterationArrayLiteral = ($IterationPaths | ForEach-Object { "'" + $_.Replace("'", "''") + "'" }) -join ', '
    $command = "& '$escapedValidatorScriptPath' -ProjectPath '$escapedProjectPath' -IterationPath @($iterationArrayLiteral)"
    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -Command $command 2>&1)

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Text     = ($output -join "`n")
    }
}

function Invoke-Classifier {
    param(
        [Parameter(Mandatory = $true)][string]$BeforePath,
        [Parameter(Mandatory = $true)][string]$AfterPath
    )

    $json = @(
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $classifierScriptPath -BeforePath $BeforePath -AfterPath $AfterPath -AsJson 2>&1
    ) -join "`n"

    if ($LASTEXITCODE -ne 0) {
        throw "Classifier helper failed: $json"
    }

    return $json | ConvertFrom-Json
}

function Assert-Classifier {
    param(
        [Parameter(Mandatory = $true)][string]$AfterFixture,
        [Parameter(Mandatory = $true)][string]$ExpectedClassification,
        [Parameter(Mandatory = $true)][bool]$ExpectedRestart
    )

    $result = Invoke-Classifier -BeforePath $classifierBeforePath -AfterPath (Join-Path $fixtureRoot "copilot-instructions\$AfterFixture")
    if (-not (Assert-Equal -Actual $result.Classification -Expected $ExpectedClassification -FailureMessage "$AfterFixture classification mismatch.")) {
        return $false
    }

    if (-not (Assert-Equal -Actual ([bool]$result.RequiresRestart) -Expected $ExpectedRestart -FailureMessage "$AfterFixture restart requirement mismatch.")) {
        return $false
    }

    return $true
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$classifierScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\Test-CopilotInstructionsChangeType.ps1'
$startScriptPath = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$featureSource = Join-Path $repoRoot 'specs\013-validator-hardening'
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\013-validator-hardening'
$scratchRoot = Join-Path $repoRoot '.scratch\validator-hardening-iteration2'
$classifierBeforePath = Join-Path $fixtureRoot 'copilot-instructions\before.md'

foreach ($requiredPath in @($validatorScriptPath, $classifierScriptPath, $startScriptPath, $featureSource, $fixtureRoot, $classifierBeforePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing validator-hardening iteration 002 dependency: $requiredPath"
        exit 1
    }
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$allChecksPassed = $true

# Approval-reuse duplicate detection
$approvalDuplicateRoot = New-Workspace -WorkspaceName 'approval-reuse-duplicate'
Replace-MarkdownSection -Path (Join-Path $approvalDuplicateRoot 'specs\013-validator-hardening\iterations\001\plan.md') -Heading 'Implementation Authorization' -Body (Get-FixtureContent 'approval-reuse\iter001-source.md')
Replace-MarkdownSection -Path (Join-Path $approvalDuplicateRoot 'specs\013-validator-hardening\iterations\002\plan.md') -Heading 'Implementation Authorization' -Body (Get-FixtureContent 'approval-reuse\iter002-duplicate.md')
Initialize-GitWorkspace -WorkspaceRoot $approvalDuplicateRoot
Commit-Workspace -WorkspaceRoot $approvalDuplicateRoot -Message 'Seed approval reuse duplicate fixture'
$approvalDuplicateResult = Invoke-Validator -ProjectPath $approvalDuplicateRoot -IterationPaths @(
    (Join-Path $approvalDuplicateRoot 'specs\013-validator-hardening\iterations\001'),
    (Join-Path $approvalDuplicateRoot 'specs\013-validator-hardening\iterations\002')
)
if (-not (Assert-True -Condition ($approvalDuplicateResult.ExitCode -ne 0) -FailureMessage 'Duplicate approval evidence should fail validate-governance.ps1.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $approvalDuplicateResult.Text -Pattern 'category=approval-reuse' -FailureMessage 'Duplicate approval evidence should emit an approval-reuse failure.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $approvalDuplicateResult.Text -Pattern 'iterations/001/plan\.md' -FailureMessage 'Approval-reuse failure should name the first artifact.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $approvalDuplicateResult.Text -Pattern 'iterations/002/plan\.md' -FailureMessage 'Approval-reuse failure should name the second artifact.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $approvalDuplicateResult.Text -Pattern 'bounded implementation slice' -FailureMessage 'Approval-reuse failure should include the normalized quote text.')) { $allChecksPassed = $false }
if (-not (Assert-NotMatch -Text $approvalDuplicateResult.Text -Pattern 'CategoryInfo:|FullyQualifiedErrorId|at .*validate-governance\.ps1' -FailureMessage 'Approval-reuse failure should not leak raw PowerShell exception formatting.')) { $allChecksPassed = $false }
Write-Pass 'Approval-reuse duplicate fixture fails with structured normalized-quote output.'

# Approval-reuse blanket exemption
$approvalBlanketRoot = New-Workspace -WorkspaceName 'approval-reuse-blanket'
Replace-MarkdownSection -Path (Join-Path $approvalBlanketRoot 'specs\013-validator-hardening\iterations\001\plan.md') -Heading 'Implementation Authorization' -Body (Get-FixtureContent 'approval-reuse\iter001-source.md')
Replace-MarkdownSection -Path (Join-Path $approvalBlanketRoot 'specs\013-validator-hardening\iterations\002\plan.md') -Heading 'Implementation Authorization' -Body (Get-FixtureContent 'approval-reuse\iter002-blanket.md')
Initialize-GitWorkspace -WorkspaceRoot $approvalBlanketRoot
Commit-Workspace -WorkspaceRoot $approvalBlanketRoot -Message 'Seed approval reuse blanket fixture'
$approvalBlanketResult = Invoke-Validator -ProjectPath $approvalBlanketRoot -IterationPaths @(
    (Join-Path $approvalBlanketRoot 'specs\013-validator-hardening\iterations\001'),
    (Join-Path $approvalBlanketRoot 'specs\013-validator-hardening\iterations\002')
)
if (-not (Assert-True -Condition ($approvalBlanketResult.ExitCode -eq 0) -FailureMessage 'Blanket multi-iteration authorization should pass approval reuse validation.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $approvalBlanketResult.Text -Pattern 'PASS .*iterations\\002' -FailureMessage 'Blanket authorization fixture should emit PASS output.')) { $allChecksPassed = $false }
Write-Pass 'Approval-reuse blanket authorization fixture passes.'

# Approval-reuse distinct quote
$approvalDistinctRoot = New-Workspace -WorkspaceName 'approval-reuse-distinct'
Replace-MarkdownSection -Path (Join-Path $approvalDistinctRoot 'specs\013-validator-hardening\iterations\001\plan.md') -Heading 'Implementation Authorization' -Body (Get-FixtureContent 'approval-reuse\iter001-source.md')
Replace-MarkdownSection -Path (Join-Path $approvalDistinctRoot 'specs\013-validator-hardening\iterations\002\plan.md') -Heading 'Implementation Authorization' -Body (Get-FixtureContent 'approval-reuse\iter002-distinct.md')
Initialize-GitWorkspace -WorkspaceRoot $approvalDistinctRoot
Commit-Workspace -WorkspaceRoot $approvalDistinctRoot -Message 'Seed approval reuse distinct fixture'
$approvalDistinctResult = Invoke-Validator -ProjectPath $approvalDistinctRoot -IterationPaths @(
    (Join-Path $approvalDistinctRoot 'specs\013-validator-hardening\iterations\001'),
    (Join-Path $approvalDistinctRoot 'specs\013-validator-hardening\iterations\002')
)
if (-not (Assert-True -Condition ($approvalDistinctResult.ExitCode -eq 0) -FailureMessage 'Distinct approval evidence should pass validation.')) { $allChecksPassed = $false }
Write-Pass 'Approval-reuse distinct quote fixture passes.'

# Over-claim pass baseline
$overclaimPassRoot = New-Workspace -WorkspaceName 'overclaim-pass'
Initialize-GitWorkspace -WorkspaceRoot $overclaimPassRoot
Commit-Workspace -WorkspaceRoot $overclaimPassRoot -Message 'Seed overclaim pass fixture'
$overclaimPassIteration = Join-Path $overclaimPassRoot 'specs\013-validator-hardening\iterations\001'
$overclaimPassResult = Invoke-Validator -ProjectPath $overclaimPassRoot -IterationPaths @($overclaimPassIteration)
if (-not (Assert-True -Condition ($overclaimPassResult.ExitCode -eq 0) -FailureMessage 'Closed iteration with full evidence should pass validation.')) { $allChecksPassed = $false }
Write-Pass 'Closed iteration with review, retro, and verified hardening gate passes.'

# Over-claim missing review
$overclaimMissingReviewRoot = New-Workspace -WorkspaceName 'overclaim-missing-review'
Initialize-GitWorkspace -WorkspaceRoot $overclaimMissingReviewRoot
Commit-Workspace -WorkspaceRoot $overclaimMissingReviewRoot -Message 'Seed overclaim missing review fixture'
Remove-Item -LiteralPath (Join-Path $overclaimMissingReviewRoot 'specs\013-validator-hardening\iterations\001\review.md') -Force
$overclaimMissingReviewResult = Invoke-Validator -ProjectPath $overclaimMissingReviewRoot -IterationPaths @((Join-Path $overclaimMissingReviewRoot 'specs\013-validator-hardening\iterations\001'))
if (-not (Assert-True -Condition ($overclaimMissingReviewResult.ExitCode -ne 0) -FailureMessage 'Closed iteration missing review.md should fail validation.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $overclaimMissingReviewResult.Text -Pattern 'category=over-claim' -FailureMessage 'Missing review should surface an over-claim failure.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $overclaimMissingReviewResult.Text -Pattern 'review\.md is missing' -FailureMessage 'Missing review over-claim should explain the missing artifact.')) { $allChecksPassed = $false }
Write-Pass 'Closed iteration missing review.md fails with over-claim output.'

# Over-claim missing retro
$overclaimMissingRetroRoot = New-Workspace -WorkspaceName 'overclaim-missing-retro'
Initialize-GitWorkspace -WorkspaceRoot $overclaimMissingRetroRoot
Commit-Workspace -WorkspaceRoot $overclaimMissingRetroRoot -Message 'Seed overclaim missing retro fixture'
Remove-Item -LiteralPath (Join-Path $overclaimMissingRetroRoot 'specs\013-validator-hardening\iterations\001\retro.md') -Force
$overclaimMissingRetroResult = Invoke-Validator -ProjectPath $overclaimMissingRetroRoot -IterationPaths @((Join-Path $overclaimMissingRetroRoot 'specs\013-validator-hardening\iterations\001'))
if (-not (Assert-True -Condition ($overclaimMissingRetroResult.ExitCode -ne 0) -FailureMessage 'Closed iteration missing retro.md should fail validation.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $overclaimMissingRetroResult.Text -Pattern 'retro\.md is missing' -FailureMessage 'Missing retro over-claim should explain the missing artifact.')) { $allChecksPassed = $false }
Write-Pass 'Closed iteration missing retro.md fails with over-claim output.'

# Over-claim pending hardening evidence
$overclaimGatePendingRoot = New-Workspace -WorkspaceName 'overclaim-gate-pending'
Initialize-GitWorkspace -WorkspaceRoot $overclaimGatePendingRoot
Commit-Workspace -WorkspaceRoot $overclaimGatePendingRoot -Message 'Seed overclaim gate pending fixture'
Set-ContentUtf8 -Path (Join-Path $overclaimGatePendingRoot 'specs\013-validator-hardening\iterations\001\quality\hardening-gate.md') -Content (Get-FixtureContent 'overclaim\hardening-gate-pending.md')
$overclaimGatePendingResult = Invoke-Validator -ProjectPath $overclaimGatePendingRoot -IterationPaths @((Join-Path $overclaimGatePendingRoot 'specs\013-validator-hardening\iterations\001'))
if (-not (Assert-True -Condition ($overclaimGatePendingResult.ExitCode -ne 0) -FailureMessage 'Pending hardening-gate evidence should fail closed-iteration validation.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $overclaimGatePendingResult.Text -Pattern 'pending post-implementation verification|lacks recorded post-implementation evidence' -FailureMessage 'Pending hardening gate should explain the missing closeout evidence.')) { $allChecksPassed = $false }
Write-Pass 'Closed iteration with pending hardening-gate verification fails with over-claim output.'

# Over-claim dirty-tree scoped to iteration artifacts
$overclaimDirtyRoot = New-Workspace -WorkspaceName 'overclaim-dirty-tree'
Initialize-GitWorkspace -WorkspaceRoot $overclaimDirtyRoot
Commit-Workspace -WorkspaceRoot $overclaimDirtyRoot -Message 'Seed overclaim dirty tree fixture'
Add-Content -LiteralPath (Join-Path $overclaimDirtyRoot 'specs\013-validator-hardening\iterations\001\plan.md') -Value "`nDirty change" -Encoding UTF8
$overclaimDirtyResult = Invoke-Validator -ProjectPath $overclaimDirtyRoot -IterationPaths @((Join-Path $overclaimDirtyRoot 'specs\013-validator-hardening\iterations\001'))
if (-not (Assert-True -Condition ($overclaimDirtyResult.ExitCode -ne 0) -FailureMessage 'Dirty iteration artifacts should fail closed-iteration validation.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $overclaimDirtyResult.Text -Pattern 'uncommitted changes: specs\\013-validator-hardening\\iterations\\001\\plan\.md' -FailureMessage 'Dirty-tree failure should name the canonical iteration artifact path.')) { $allChecksPassed = $false }
Write-Pass 'Dirty iteration artifacts fail closed-iteration validation.'

# Over-claim repo-level evidence-only dirt is ignored
$overclaimRepoDirtyRoot = New-Workspace -WorkspaceName 'overclaim-repo-dirty'
Initialize-GitWorkspace -WorkspaceRoot $overclaimRepoDirtyRoot
Commit-Workspace -WorkspaceRoot $overclaimRepoDirtyRoot -Message 'Seed overclaim repo dirty fixture'
Add-Content -LiteralPath (Join-Path $overclaimRepoDirtyRoot '.squad\decisions.md') -Value "`nUncommitted evidence-only note" -Encoding UTF8
$overclaimRepoDirtyResult = Invoke-Validator -ProjectPath $overclaimRepoDirtyRoot -IterationPaths @((Join-Path $overclaimRepoDirtyRoot 'specs\013-validator-hardening\iterations\001'))
if (-not (Assert-True -Condition ($overclaimRepoDirtyResult.ExitCode -eq 0) -FailureMessage 'Repo-level evidence-only dirt should not fail closed-iteration validation.')) { $allChecksPassed = $false }
Write-Pass 'Repo-level evidence-only dirt stays outside the over-claim dirty-tree filter.'

# Classifier direct coverage
if (-not (Assert-Classifier -AfterFixture 'after-timestamp.md' -ExpectedClassification 'bookkeeping' -ExpectedRestart $false)) { $allChecksPassed = $false } else { Write-Pass 'Timestamp-only classifier fixture is bookkeeping.' }
if (-not (Assert-Classifier -AfterFixture 'after-active-technologies.md' -ExpectedClassification 'bookkeeping' -ExpectedRestart $false)) { $allChecksPassed = $false } else { Write-Pass 'Active Technologies-only classifier fixture is bookkeeping.' }
if (-not (Assert-Classifier -AfterFixture 'after-recent-changes.md' -ExpectedClassification 'bookkeeping' -ExpectedRestart $false)) { $allChecksPassed = $false } else { Write-Pass 'Recent Changes-only classifier fixture is bookkeeping.' }
if (-not (Assert-Classifier -AfterFixture 'after-behavior.md' -ExpectedClassification 'behavior' -ExpectedRestart $true)) { $allChecksPassed = $false } else { Write-Pass 'Behavior-affecting classifier fixture requires restart.' }
if (-not (Assert-Classifier -AfterFixture 'after-mixed.md' -ExpectedClassification 'behavior' -ExpectedRestart $true)) { $allChecksPassed = $false } else { Write-Pass 'Mixed bookkeeping and behavior fixture stays conservative.' }

# specrew-start integration with classifier
$startRoot = Join-Path $scratchRoot 'specrew-start-classifier'
if (Test-Path -LiteralPath $startRoot) {
    Remove-Item -LiteralPath $startRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $startRoot -Force
$null = New-Item -ItemType Directory -Path (Join-Path $startRoot '.specrew') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $startRoot '.specify') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $startRoot '.squad') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $startRoot '.github\agents') -Force
Set-ContentUtf8 -Path (Join-Path $startRoot '.specrew\config.yml') -Content "version: 1`n"
Set-ContentUtf8 -Path (Join-Path $startRoot '.squad\team.md') -Content "# Team`n"
Set-ContentUtf8 -Path (Join-Path $startRoot '.squad\config.json') -Content "{}"
Set-ContentUtf8 -Path (Join-Path $startRoot '.squad\decisions.md') -Content "# Decisions`n"
Set-ContentUtf8 -Path (Join-Path $startRoot '.github\agents\squad.agent.md') -Content "# Squad Agent`n"
Set-ContentUtf8 -Path (Join-Path $startRoot '.github\copilot-instructions.md') -Content (Get-FixtureContent 'copilot-instructions\before.md')
Initialize-GitWorkspace -WorkspaceRoot $startRoot
Commit-Workspace -WorkspaceRoot $startRoot -Message 'Seed specrew-start classifier fixture'
$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScriptPath -ProjectPath $startRoot -NoLaunch 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Baseline specrew-start run failed in classifier fixture.'
    exit 1
}
$promptPath = Join-Path $startRoot '.specrew\last-start-prompt.md'

Set-ContentUtf8 -Path (Join-Path $startRoot '.github\copilot-instructions.md') -Content (Get-FixtureContent 'copilot-instructions\after-timestamp.md')
Commit-Workspace -WorkspaceRoot $startRoot -Message 'Bookkeeping-only copilot instructions update'
$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScriptPath -ProjectPath $startRoot -NoLaunch 2>&1
$bookkeepingExitCode = $LASTEXITCODE
$bookkeepingOutput = $null
if ($bookkeepingExitCode -ne 0) {
    Write-Fail 'Bookkeeping-only specrew-start run failed in classifier fixture.'
    exit 1
}
$bookkeepingPrompt = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
if (-not (Assert-NotMatch -Text $bookkeepingPrompt -Pattern 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed' -FailureMessage 'Bookkeeping-only copilot-instructions changes should not trigger pause-and-confirm.')) { $allChecksPassed = $false }
Write-Pass 'specrew-start ignores bookkeeping-only copilot-instructions updates.'

Set-ContentUtf8 -Path (Join-Path $startRoot '.github\copilot-instructions.md') -Content (Get-FixtureContent 'copilot-instructions\after-behavior.md')
Commit-Workspace -WorkspaceRoot $startRoot -Message 'Behavioral copilot instructions update'
$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScriptPath -ProjectPath $startRoot -NoLaunch 2>&1
$behaviorExitCode = $LASTEXITCODE
if ($behaviorExitCode -ne 0) {
    Write-Fail 'Behavior specrew-start run failed in classifier fixture.'
    exit 1
}
$behaviorPrompt = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
if (-not (Assert-Match -Text $behaviorPrompt -Pattern 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed' -FailureMessage 'Behavior-affecting copilot-instructions changes should trigger pause-and-confirm.')) { $allChecksPassed = $false }
if (-not (Assert-Match -Text $behaviorPrompt -Pattern '\.github[/\\]copilot-instructions\.md' -FailureMessage 'Pause-and-confirm output should name .github/copilot-instructions.md when behavior changes.')) { $allChecksPassed = $false }
Write-Pass 'specrew-start pauses when copilot-instructions changes affect behavior.'

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Validator hardening Iteration 002 fixtures exercise approval-reuse, over-claim, classifier, and compatibility paths through validate-governance.ps1 and specrew-start.ps1'
exit 0
