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
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Equal {
    param(
        [AllowNull()][object]$Actual,
        [AllowNull()][object]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Actual -is [System.Array] -or $Expected -is [System.Array]) {
        $actualJson = ConvertTo-Json @($Actual) -Depth 10 -Compress
        $expectedJson = ConvertTo-Json @($Expected) -Depth 10 -Compress
        if ($actualJson -ne $expectedJson) {
            throw "$Message (expected: $expectedJson, actual: $actualJson)"
        }

        return
    }

    if ($Actual -ne $Expected) {
        throw "$Message (expected: $Expected, actual: $Actual)"
    }
}

function Assert-Null {
    param(
        [AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($null -ne $Value) {
        throw "$Message (actual: $Value)"
    }
}

function Assert-Match {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

function Assert-ThrowsLike {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    try {
        & $ScriptBlock
    }
    catch {
        if ($_.Exception.Message -match $Pattern) {
            return
        }

        throw "$Message (actual: $($_.Exception.Message))"
    }

    throw "$Message (no exception thrown)"
}

function Import-FunctionsFromFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw "Failed to parse '$Path': $($parseErrors[0].Message)"
    }

    foreach ($name in $Names) {
        $functionAst = @(
            $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
                }, $true)
        ) | Select-Object -First 1

        if ($null -eq $functionAst) {
            throw "Could not find function '$name' in '$Path'."
        }

        $definition = [regex]::Replace($functionAst.Extent.Text, ('^function\s+{0}\b' -f [regex]::Escape($name)), "function global:$name")
        Invoke-Expression $definition
    }
}

function New-TestWorkspace {
    param(
        [Parameter(Mandatory = $true)][string]$FixtureName,
        [Parameter(Mandatory = $true)][string]$WorkspaceName
    )

    $source = Join-Path $fixtureRoot $FixtureName
    $destination = Join-Path $scratchRoot $WorkspaceName
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $destination -Force
    foreach ($item in Get-ChildItem -LiteralPath $source -Force) {
        Copy-Item -LiteralPath $item.FullName -Destination $destination -Recurse -Force
    }

    return $destination
}

function Invoke-WithDebugCapture {
    param([Parameter(Mandatory = $true)][scriptblock]$ScriptBlock)

    $previousDebugPreference = $DebugPreference
    $DebugPreference = 'Continue'
    try {
        $output = @(& $ScriptBlock 5>&1)
    }
    finally {
        $DebugPreference = $previousDebugPreference
    }

    $debugMessages = @(
        $output |
            Where-Object { $_ -is [System.Management.Automation.DebugRecord] } |
            ForEach-Object { $_.Message }
    )
    $values = @($output | Where-Object { $_ -isnot [System.Management.Automation.DebugRecord] })

    return [pscustomobject]@{
        Value = if ($values.Count -gt 0) { $values[0] } else { $null }
        Debug = $debugMessages
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\fixtures\legacy-versions'
$scratchRoot = Join-Path $repoRoot '.scratch\legacy-state-readers'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$syncBoundaryStatePath = Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1'
$specrewStartPath = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$worktreeAwarenessPath = Join-Path $repoRoot 'scripts\internal\worktree-awareness.ps1'
$coordinatorResumePath = Join-Path $repoRoot 'scripts\internal\coordinator-resume.ps1'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

. $sharedGovernancePath
Import-FunctionsFromFile -Path $syncBoundaryStatePath -Names @(
    'Get-SpecrewSessionStatePaths',
    'ConvertFrom-SpecrewFrontmatter',
    'Get-SpecrewSessionStateFromFrontmatter'
)
Import-FunctionsFromFile -Path $specrewStartPath -Names @(
    'Get-SpecrewIdentitySessionState',
    'Get-SpecrewStartContextSessionState',
    'Get-SpecrewConfigValue'
)
Import-FunctionsFromFile -Path $worktreeAwarenessPath -Names @(
    'ConvertFrom-SpecrewFrontmatterBlock',
    'Get-WorktreeSessionState',
    'Get-WorktreeFeatureRef'
)
Import-FunctionsFromFile -Path $coordinatorResumePath -Names @(
    'Get-ValidatorSummaryPath',
    'Get-ValidatorWarningSummary'
)

try {
    New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null

    foreach ($fixtureName in @('0.18.0', '0.19.0', '0.20.0', '0.21.0', '0.22.0', '0.23.0')) {
        $workspace = New-TestWorkspace -FixtureName $fixtureName -WorkspaceName $fixtureName.Replace('.', '-')

        $configValue = Get-SpecrewConfigValue -ProjectRoot $workspace -Key 'specrew_version'
        if ($fixtureName -in @('0.18.0', '0.19.0', '0.20.0', '0.23.0')) {
            Assert-True -Condition (-not [string]::IsNullOrWhiteSpace([string]$configValue)) -Message "Fixture $fixtureName should expose .specrew/config.yml through Get-SpecrewConfigValue."
        }

        if (Test-Path -LiteralPath (Join-Path $workspace '.specrew\start-context.json') -PathType Leaf) {
            $startContextResult = Invoke-WithDebugCapture { Get-SpecrewStartContextSessionState -ProjectRoot $workspace }
            if ($fixtureName -eq '0.23.0') {
                Assert-Equal -Actual $startContextResult.Value.feature_ref -Expected '023-legacy-state-read-tolerance' -Message 'Schema v1 start-context fixture should preserve feature_ref.'
                Assert-Equal -Actual @($startContextResult.Debug).Count -Expected 0 -Message 'Schema v1 start-context fixture should not emit schema-implied-v0 debug output.'
            }
            else {
                Assert-Equal -Actual @($startContextResult.Debug | Where-Object { $_ -match 'schema-implied-v0' }).Count -Expected 1 -Message "Legacy start-context fixture $fixtureName should emit schema-implied-v0 exactly once."
            }
        }

        if (Test-Path -LiteralPath (Join-Path $workspace '.specify\feature.json') -PathType Leaf) {
            $featureResult = Invoke-WithDebugCapture { Get-WorktreeFeatureRef -WorktreePath $workspace }
            if ($fixtureName -eq '0.23.0') {
                Assert-Equal -Actual $featureResult.Value -Expected '023-legacy-state-read-tolerance' -Message 'Schema v1 feature.json fixture should resolve the feature ref.'
                Assert-Equal -Actual @($featureResult.Debug).Count -Expected 0 -Message 'Schema v1 feature.json fixture should not emit schema-implied-v0 debug output.'
            }
            else {
                Assert-Equal -Actual @($featureResult.Debug | Where-Object { $_ -match 'schema-implied-v0' }).Count -Expected 1 -Message "Legacy feature.json fixture $fixtureName should emit schema-implied-v0 exactly once."
                if ($fixtureName -eq '0.18.0') {
                    Assert-Equal -Actual $featureResult.Value -Expected '018-example-feature' -Message '0.18.0 feature.json should still resolve the legacy feature ref.'
                }
            }
        }

        if (Test-Path -LiteralPath (Join-Path $workspace '.squad\identity\now.md') -PathType Leaf) {
            $identityState = Get-SpecrewIdentitySessionState -ProjectRoot $workspace
            Assert-Equal -Actual $identityState.feature_ref -Expected '023-legacy-state-read-tolerance' -Message 'Identity fixture should preserve feature_ref.'
            $identityContent = Get-Content -LiteralPath (Join-Path $workspace '.squad\identity\now.md') -Raw -Encoding UTF8
            Assert-Match -Text $identityContent -Pattern '(?m)^schema:\s*v1\s*$' -Message 'Identity fixture should carry schema: v1 in frontmatter.'
        }

        if (Test-Path -LiteralPath (Join-Path $workspace '.specrew\last-validator-summary.json') -PathType Leaf) {
            $summaryResult = Invoke-WithDebugCapture { Get-ValidatorWarningSummary -ProjectRoot $workspace }
            if ($fixtureName -eq '0.22.0') {
                Assert-Equal -Actual $summaryResult.Value.total -Expected 3 -Message 'Legacy validator summary fixture should parse warning totals.'
                Assert-Equal -Actual @($summaryResult.Debug | Where-Object { $_ -match 'schema-implied-v0' }).Count -Expected 1 -Message 'Legacy validator summary fixture should emit schema-implied-v0 exactly once.'
            }
            else {
                Assert-Equal -Actual $summaryResult.Value.total -Expected 0 -Message 'Schema v1 validator summary fixture should preserve warning totals.'
                Assert-Equal -Actual @($summaryResult.Debug).Count -Expected 0 -Message 'Schema v1 validator summary fixture should not emit schema-implied-v0 debug output.'
            }
        }

        if (Test-Path -LiteralPath (Join-Path $workspace '.specify\extensions\specrew-speckit\extension.yml') -PathType Leaf) {
            $extensionContent = Get-Content -LiteralPath (Join-Path $workspace '.specify\extensions\specrew-speckit\extension.yml') -Raw -Encoding UTF8
            Assert-Match -Text $extensionContent -Pattern '(?m)^schema:\s*"v1"\s*$' -Message 'Schema v1 extension manifest fixture should carry schema: v1.'
        }

        if ($fixtureName -eq '0.21.0') {
            $tasksProgressPath = Join-Path $workspace 'tasks-progress.yml'
            $tasksProgressText = Get-Content -LiteralPath $tasksProgressPath -Raw -Encoding UTF8
            Assert-Match -Text $tasksProgressText -Pattern '(?m)^schema:\s*v1\s*$' -Message 'tasks-progress.yml fixture should remain readable.'
        }
    }

    $missingWorkspace = Join-Path $scratchRoot 'missing-files'
    $null = New-Item -ItemType Directory -Path $missingWorkspace -Force
    Assert-Null -Value (Get-SpecrewConfigValue -ProjectRoot $missingWorkspace -Key 'specrew_version') -Message 'Missing config should return null.'
    Assert-Null -Value (Get-SpecrewStartContextSessionState -ProjectRoot $missingWorkspace) -Message 'Missing start-context should return null.'
    Assert-Null -Value (Get-SpecrewIdentitySessionState -ProjectRoot $missingWorkspace) -Message 'Missing identity should return null.'
    Assert-Null -Value (Get-ValidatorWarningSummary -ProjectRoot $missingWorkspace) -Message 'Missing validator summary should return null.'
    Assert-Null -Value (Get-WorktreeFeatureRef -WorktreePath $missingWorkspace) -Message 'Missing feature.json should return null.'

    $malformedWorkspace = Join-Path $scratchRoot 'malformed-json'
    $null = New-Item -ItemType Directory -Path (Join-Path $malformedWorkspace '.specrew') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $malformedWorkspace '.specify') -Force
    '{ "session_state": ' | Set-Content -LiteralPath (Join-Path $malformedWorkspace '.specrew\start-context.json') -Encoding UTF8
    '{ "warnings": ' | Set-Content -LiteralPath (Join-Path $malformedWorkspace '.specrew\last-validator-summary.json') -Encoding UTF8
    '{ "feature_directory": ' | Set-Content -LiteralPath (Join-Path $malformedWorkspace '.specify\feature.json') -Encoding UTF8
    Assert-Null -Value (Get-SpecrewStartContextSessionState -ProjectRoot $malformedWorkspace) -Message 'Malformed start-context should return null.'
    Assert-Null -Value (Get-ValidatorWarningSummary -ProjectRoot $malformedWorkspace) -Message 'Malformed validator summary should return null.'
    Assert-Null -Value (Get-WorktreeFeatureRef -WorktreePath $malformedWorkspace) -Message 'Malformed feature.json should return null.'

    $unsupportedFeatureWorkspace = Join-Path $scratchRoot 'unsupported-feature'
    $null = New-Item -ItemType Directory -Path (Join-Path $unsupportedFeatureWorkspace '.specify') -Force
    @'
{
  "schema": "v2",
  "feature_directory": "specs/999-test"
}
'@ | Set-Content -LiteralPath (Join-Path $unsupportedFeatureWorkspace '.specify\feature.json') -Encoding UTF8
    Assert-ThrowsLike -ScriptBlock { Get-WorktreeFeatureRef -WorktreePath $unsupportedFeatureWorkspace | Out-Null } -Pattern "Unsupported schema 'v2'" -Message 'Unsupported feature.json schema should fail fast.'

    $unsupportedContextWorkspace = Join-Path $scratchRoot 'unsupported-context'
    $null = New-Item -ItemType Directory -Path (Join-Path $unsupportedContextWorkspace '.specrew') -Force
    @'
{
  "schema": "v2",
  "session_state": {
    "feature_ref": "999-test"
  }
}
'@ | Set-Content -LiteralPath (Join-Path $unsupportedContextWorkspace '.specrew\start-context.json') -Encoding UTF8
    Assert-ThrowsLike -ScriptBlock { Get-SpecrewStartContextSessionState -ProjectRoot $unsupportedContextWorkspace | Out-Null } -Pattern "Unsupported schema 'v2'" -Message 'Unsupported start-context schema should fail fast.'

    $unsupportedSummaryWorkspace = Join-Path $scratchRoot 'unsupported-summary'
    $null = New-Item -ItemType Directory -Path (Join-Path $unsupportedSummaryWorkspace '.specrew') -Force
    @'
{
  "schema": "v2",
  "warnings": {
    "total": 1,
    "soft": 1,
    "medium": 0,
    "hard": 0
  },
  "command": "validate-governance",
  "recorded_at": "2026-05-19T12:00:00Z"
}
'@ | Set-Content -LiteralPath (Join-Path $unsupportedSummaryWorkspace '.specrew\last-validator-summary.json') -Encoding UTF8
    Assert-ThrowsLike -ScriptBlock { Get-ValidatorWarningSummary -ProjectRoot $unsupportedSummaryWorkspace | Out-Null } -Pattern "Unsupported schema 'v2'" -Message 'Unsupported validator summary schema should fail fast.'
}
catch {
    Write-Fail $_.Exception.Message
    exit 1
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Pass 'Legacy state readers tolerate v0 fixtures, preserve v1 schema markers, and reject unsupported schemas'
exit 0
