# A GIT WARNING ON STDERR IS NOT A STATUS LINE, AND IT MUST NOT KILL THE FEATURE-CLOSEOUT SYNC.
#
# Found running the nine-boundary harness against a package from a deep scratch path: `git status --porcelain
# 2>&1` carried "warning: could not open directory ..." as ErrorRecords, and Invoke-PreFeatureCloseoutWorkingTreeGate
# read `.Length` on one of them under StrictMode - "The property 'Length' cannot be found on this object" - and
# the feature-closeout sync died. Any git warning at closeout (long paths, a hook's stderr) reached a consumer
# the same way. The gate is extracted from the sync script's AST and run against a repository whose `git status`
# warns (a path past 260 characters under core.longpaths=false, the shape that found it); the warning is skipped
# and the dirty file is still gated. The fixture proves it carries a stderr record before anything is asserted.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$syncScript = Join-Path $repoRoot 'scripts/internal/sync-boundary-state.ps1'
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($syncScript, [ref]$tokens, [ref]$errors)
$fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Invoke-PreFeatureCloseoutWorkingTreeGate' }, $true) | Select-Object -First 1
$helpers = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in @('Resolve-ProjectPath', 'Get-SpecrewGitUpstreamBranch') }, $true))

Write-Host 'closeout-gate-git-warnings'
Assert-True ($null -ne $fn) 'the gate function is present in the sync script'
if ($null -eq $fn) { exit 1 }
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
foreach ($helper in $helpers) { Invoke-Expression $helper.Extent.Text }
Invoke-Expression $fn.Extent.Text
Set-StrictMode -Version Latest

$root = Join-Path ([IO.Path]::GetTempPath()) ('cgw-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path (Join-Path $root '.specrew'), (Join-Path $root 'scripts') -Force | Out-Null
$longPrefix = '\\?\'
try {
    & git -C $root init -q
    & git -C $root config core.longpaths false
    & git -C $root config core.autocrlf false
    & git -C $root config user.email 'f@f'; & git -C $root config user.name 'f'
    [IO.File]::WriteAllText((Join-Path $root 'scripts/app.ps1'), "one`ntwo`n", [Text.UTF8Encoding]::new($false))
    & git -C $root add -A 2>$null; & git -C $root commit -q -m base 2>$null
    # a directory whose path is longer than git will open without core.longpaths: git status WARNS on stderr
    $deep = $root
    for ($i = 0; $i -lt 6; $i++) { $deep = Join-Path $deep ('segment-' + ('x' * 45) + '-' + $i) }
    [IO.Directory]::CreateDirectory($longPrefix + $deep) | Out-Null
    [IO.File]::WriteAllText($longPrefix + (Join-Path $deep 'deep.txt'), "deep`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $root 'scripts/app.ps1'), "one`ntwo`nthree`n", [Text.UTF8Encoding]::new($false))
    Push-Location $root
    try { $captured = @(& git status --porcelain 2>&1) } finally { Pop-Location }
    $records = @($captured | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
    Assert-True ($records.Count -ge 1) ('the fixture is real: git status carries {0} stderr record(s) inside the 2>&1 capture ({1})' -f $records.Count, $(if ($records.Count -gt 0) { ([string]$records[0]).Substring(0, [Math]::Min(60, ([string]$records[0]).Length)) } else { 'none' }))
    $threw = $null
    try { Invoke-PreFeatureCloseoutWorkingTreeGate -ProjectPath $root -BoundaryType 'feature-closeout' } catch { $threw = $_.Exception.Message }
    Assert-True ($null -ne $threw -and $threw -notmatch "property 'Length'") ("the gate does not die on the warning; it gates the dirty tree (got: " + ([string]$threw).Substring(0, [Math]::Min(140, ([string]$threw).Length)) + ')')
    Assert-True ($null -ne $threw -and $threw -match 'scripts/app.ps1') 'and names the uncommitted file, so the warning did not hide it'
}
finally {
    try { Remove-Item -LiteralPath ($longPrefix + $root) -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:Failures -gt 0) { Write-Host ("closeout-gate-git-warnings: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'closeout-gate-git-warnings: all cases passed'
exit 0
