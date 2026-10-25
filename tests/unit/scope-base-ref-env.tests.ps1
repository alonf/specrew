# PRED-BETA4-039 / B4F-079: THE PUSH GOVERNANCE STEP NEVER RECEIVED ITS BASE.
#
# GitHub does not let a workflow overwrite its own GITHUB_* variables, so the CI's `env: GITHUB_BASE_REF:
# ${{ github.event.before }}` was inert: the step read an empty string and every push validation scoped to
# origin/main - full-repo on a branch whose .specrew/config.yml differs from main, which then validated 155
# iterations including sealed ones that fail rules added after they closed. The validator's scope base now
# takes a Specrew-owned variable first, SPECREW_SCOPE_BASE_REF, then GITHUB_BASE_REF (pull requests, where
# GitHub sets it), then origin/HEAD, then origin/main. Exercised here in a scratch repository with a real
# origin. Mutation (recorded, not a switch): the Specrew candidate removed reds cases 1 and 2.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')

$priorSpecrew = $env:SPECREW_SCOPE_BASE_REF
$priorGithub = $env:GITHUB_BASE_REF
$root = Join-Path ([IO.Path]::GetTempPath()) ('sbr-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$origin = Join-Path ([IO.Path]::GetTempPath()) ('sbr-origin-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
Write-Host 'scope-base-ref-env'
try {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    & git init -q --bare $origin
    & git -C $root init -q -b main
    & git -C $root config user.email 'f@f'; & git -C $root config user.name 'f'; & git -C $root config core.autocrlf false
    [IO.File]::WriteAllText((Join-Path $root 'a.txt'), "one`n"); & git -C $root add -A; & git -C $root commit -q -m one
    & git -C $root remote add origin $origin; & git -C $root push -q -u origin main 2>$null
    & git -C $root checkout -q -b feature
    [IO.File]::WriteAllText((Join-Path $root 'b.txt'), "two`n"); & git -C $root add -A; & git -C $root commit -q -m two
    $before = (& git -C $root rev-parse HEAD).Trim()
    [IO.File]::WriteAllText((Join-Path $root 'c.txt'), "three`n"); & git -C $root add -A; & git -C $root commit -q -m three
    & git -C $root push -q -u origin feature 2>$null

    # 1. the Specrew-owned variable carries the base (what the push step sends)
    $env:SPECREW_SCOPE_BASE_REF = $before; $env:GITHUB_BASE_REF = ''
    $r1 = Get-SpecrewLocalScopeBaseRef -ProjectRoot $root
    Assert-True ($r1 -eq $before) ("SPECREW_SCOPE_BASE_REF set to the previous push SHA resolves to that SHA (got '{0}')" -f $r1)
    $scope1 = Get-ChangedIterations -ProjectRoot $root -BaseBranch $null
    Assert-True ($scope1.BaseRef -eq $before -and $scope1.DiffFileCount -eq 1) ("and the changed-set is scoped to it: base={0} files={1}" -f $scope1.BaseRef, $scope1.DiffFileCount)

    # 2. both set: the Specrew one wins
    $env:SPECREW_SCOPE_BASE_REF = $before; $env:GITHUB_BASE_REF = 'main'
    $r2 = Get-SpecrewLocalScopeBaseRef -ProjectRoot $root
    Assert-True ($r2 -eq $before) ("with GITHUB_BASE_REF also set, the Specrew-owned variable wins (got '{0}')" -f $r2)

    # 3. a pull request: only GITHUB_BASE_REF, as GitHub sets it
    $env:SPECREW_SCOPE_BASE_REF = ''; $env:GITHUB_BASE_REF = 'main'
    $r3 = Get-SpecrewLocalScopeBaseRef -ProjectRoot $root
    Assert-True ($r3 -eq 'origin/main') ("only GITHUB_BASE_REF (a pull request) resolves as before (got '{0}')" -f $r3)

    # 4. neither: origin/main, as before
    $env:SPECREW_SCOPE_BASE_REF = ''; $env:GITHUB_BASE_REF = ''
    $r4 = Get-SpecrewLocalScopeBaseRef -ProjectRoot $root
    Assert-True ($r4 -eq 'origin/main') ("neither set resolves to origin/main as before (got '{0}')" -f $r4)

    # 5. an unresolvable Specrew value falls through to the next candidate
    $env:SPECREW_SCOPE_BASE_REF = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'; $env:GITHUB_BASE_REF = ''
    $r5 = Get-SpecrewLocalScopeBaseRef -ProjectRoot $root
    Assert-True ($r5 -eq 'origin/main') ("an unresolvable Specrew value falls through to origin/main (got '{0}')" -f $r5)
}
finally {
    if ($null -eq $priorSpecrew) { Remove-Item Env:\SPECREW_SCOPE_BASE_REF -ErrorAction SilentlyContinue } else { $env:SPECREW_SCOPE_BASE_REF = $priorSpecrew }
    if ($null -eq $priorGithub) { Remove-Item Env:\GITHUB_BASE_REF -ErrorAction SilentlyContinue } else { $env:GITHUB_BASE_REF = $priorGithub }
    foreach ($d in @($root, $origin)) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:Failures -gt 0) { Write-Host ("scope-base-ref-env: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'scope-base-ref-env: all cases passed'
exit 0
