[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\file-classification.ps1')

$pattern = '.claude/settings.local.json'
Assert-True ($pattern -cin @(Get-SpecrewPerSessionPattern)) 'T024: Claude machine-local config is a canonical per-session pattern'

$initSource = [IO.File]::ReadAllText((Join-Path $repoRoot 'scripts\specrew-init.ps1'))
$ignoreCall = $initSource.IndexOf('Update-GitignoreForSession -ProjectRoot $resolvedProjectPath', [StringComparison]::Ordinal)
$deployCall = $initSource.IndexOf('Invoke-RefocusHookDeployment -ProjectPath $resolvedProjectPath', [StringComparison]::Ordinal)
Assert-True ($ignoreCall -ge 0 -and $deployCall -gt $ignoreCall) 'T024: real init writes ignore rules before deploying machine-local hook config'

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-t024-' + [guid]::NewGuid().ToString('N'))
try {
    $null = New-Item -ItemType Directory -Path (Join-Path $scratch '.claude') -Force
    git -C $scratch init --quiet
    git -C $scratch config user.email 't024@example.invalid'
    git -C $scratch config user.name 'T024 fixture'
    [IO.File]::WriteAllText((Join-Path $scratch 'README.md'), "# fixture`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $scratch $pattern), "{}`n", [Text.UTF8Encoding]::new($false))
    git -C $scratch add README.md
    git -C $scratch add -f $pattern
    git -C $scratch commit --quiet -m 'tracked local config fixture'

    $added = @(Update-GitignoreForSession -ProjectRoot $scratch)
    Assert-True ($pattern -cin $added) 'T024: gitignore update reports the newly added local-config pattern'
    $removed = @(Remove-TrackedPerSessionFiles -ProjectRoot $scratch)
    Assert-True ($pattern -cin $removed) 'T024: previously tracked local config is removed from the index'
    Assert-True (Test-Path -LiteralPath (Join-Path $scratch $pattern) -PathType Leaf) 'T024: untracking preserves the machine-local config on disk'

    git -C $scratch check-ignore --quiet $pattern
    Assert-True ($LASTEXITCODE -eq 0) 'T024: Git confirms the deployed local config is ignored'
    $tracked = @(git -C $scratch ls-files -- $pattern)
    Assert-True ($tracked.Count -eq 0) 'T024: deployed local config is not tracked'

    $second = @(Update-GitignoreForSession -ProjectRoot $scratch)
    Assert-True ($second.Count -eq 0) 'T024: repeated init is idempotent for the local-config ignore'
    $gitignore = [IO.File]::ReadAllText((Join-Path $scratch '.gitignore'))
    Assert-True ([regex]::Matches($gitignore, [regex]::Escape($pattern)).Count -eq 1) 'T024: gitignore contains exactly one local-config entry'

    Write-Pass 'T024 production helper, real-init ordering, Git ignore, untracking, and idempotence passed'
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
}

exit 0
