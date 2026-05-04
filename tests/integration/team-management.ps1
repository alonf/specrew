[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Write-Skip {
    param([string]$Message)
    Write-Host "SKIP: $Message" -ForegroundColor Yellow
}

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    $exitCode = $LASTEXITCODE
    
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $exitCode
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$teamScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-team.ps1'

if (-not (Test-Path -Path $teamScript -PathType Leaf)) {
    Write-Fail "Missing team management script: $teamScript"
    exit 1
}

$missingTools = @()
if (-not (Get-Command -Name 'specify' -ErrorAction SilentlyContinue)) {
    $missingTools += 'specify'
}
if (-not (Get-Command -Name 'squad' -ErrorAction SilentlyContinue)) {
    $missingTools += 'squad'
}

if ($missingTools.Count -gt 0) {
    Write-Skip ("Team management tests require tools not available in this environment: {0}" -f ($missingTools -join ', '))
    exit 0
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\team-management'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'

if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

$null = New-Item -Path $projectRoot -ItemType Directory -Force

$gitInitOutput = @(& git -C $projectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $gitInitOutput) {
        Write-Host $line
    }
    Write-Fail "Failed to initialize git repository in scratch project: $projectRoot"
    exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path -Path $projectRoot -ChildPath '.git'))) {
    Write-Fail "Git initialization did not create .git directory"
    exit 1
}

Write-Host "Initializing Specrew project..."
$initScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-init.ps1'
$initResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $projectRoot, '-Force', '-NoAgents')

if ($initResult.ExitCode -ne 0) {
    Write-Host "Bootstrap output:"
    foreach ($line in $initResult.Output) {
        Write-Host $line
    }
    Write-Fail "Bootstrap failed"
    exit 1
}

$teamPath = Join-Path -Path $projectRoot -ChildPath '.squad\team.md'
if (-not (Test-Path -LiteralPath $teamPath)) {
    Write-Fail "Bootstrap did not create .squad\team.md"
    exit 1
}

Write-Pass "Bootstrap created Squad team file"

Write-Host "`nTest 1: List baseline team members"
$listResult = Invoke-TestScript -ScriptPath $teamScript -ArgumentList @('list', '-ProjectPath', $projectRoot)
if ($listResult.ExitCode -ne 0) {
    Write-Fail "List command failed"
    exit 1
}

$listOutput = $listResult.Output -join "`n"
$baselineRoles = @('Spec Steward', 'Planner', 'Implementer', 'Reviewer', 'Retro Facilitator')
$allPresent = $true
foreach ($role in $baselineRoles) {
    if ($listOutput -notmatch [regex]::Escape($role)) {
        Write-Fail "Baseline role '$role' not found in list output"
        $allPresent = $false
    }
}

if ($allPresent) {
    Write-Pass "All baseline roles listed correctly"
}

Write-Host "`nTest 2: Add a domain-specific team member"
$addResult = Invoke-TestScript -ScriptPath $teamScript -ArgumentList @(
    'add', 'security-analyst',
    '--role', 'Security Analyst',
    '--charter', 'Review code for security vulnerabilities and ensure secure coding practices.',
    '-ProjectPath', $projectRoot
)

if ($addResult.ExitCode -ne 0) {
    Write-Fail "Add command failed"
    foreach ($line in $addResult.Output) {
        Write-Host $line
    }
    exit 1
}

$agentDir = Join-Path -Path $projectRoot -ChildPath '.squad\agents\security-analyst'
if (-not (Test-Path -LiteralPath $agentDir)) {
    Write-Fail "Add command did not create agent directory"
    exit 1
}

$charterPath = Join-Path -Path $agentDir -ChildPath 'charter.md'
if (-not (Test-Path -LiteralPath $charterPath)) {
    Write-Fail "Add command did not create charter.md"
    exit 1
}

$historyPath = Join-Path -Path $agentDir -ChildPath 'history.md'
if (-not (Test-Path -LiteralPath $historyPath)) {
    Write-Fail "Add command did not create history.md"
    exit 1
}

$teamContent = Get-Content -LiteralPath $teamPath -Raw
if ($teamContent -notmatch 'Security Analyst') {
    Write-Fail "Add command did not update team.md with new member"
    exit 1
}

Write-Pass "Successfully added Security Analyst member"

Write-Host "`nTest 3: Verify member appears in list"
$listResult2 = Invoke-TestScript -ScriptPath $teamScript -ArgumentList @('list', '-ProjectPath', $projectRoot)
if ($listResult2.ExitCode -ne 0) {
    Write-Fail "List command failed after adding member"
    exit 1
}

$listOutput2 = $listResult2.Output -join "`n"
if ($listOutput2 -notmatch 'Security Analyst') {
    Write-Fail "New member not found in list output"
    exit 1
}

Write-Pass "New member appears in list"

Write-Host "`nTest 4: Update member charter"
$updateResult = Invoke-TestScript -ScriptPath $teamScript -ArgumentList @(
    'update', 'security-analyst',
    '--charter', 'Updated charter: Perform comprehensive security reviews including penetration testing.',
    '-ProjectPath', $projectRoot
)

if ($updateResult.ExitCode -ne 0) {
    Write-Fail "Update command failed"
    foreach ($line in $updateResult.Output) {
        Write-Host $line
    }
    exit 1
}

$charterContent = Get-Content -LiteralPath $charterPath -Raw
if ($charterContent -notmatch 'penetration testing') {
    Write-Fail "Update command did not modify charter content"
    exit 1
}

Write-Pass "Successfully updated member charter"

Write-Host "`nTest 5: Attempt to remove baseline role (should fail)"
$removeBaselineResult = Invoke-TestScript -ScriptPath $teamScript -ArgumentList @(
    'remove', 'Implementer',
    '-ProjectPath', $projectRoot
)

if ($removeBaselineResult.ExitCode -eq 0) {
    Write-Fail "Remove command should have failed for baseline role"
    exit 1
}

$removeOutput = $removeBaselineResult.Output -join "`n"
if ($removeOutput -notmatch 'protected') {
    Write-Fail "Remove command did not provide appropriate error message for baseline role"
    exit 1
}

Write-Pass "Baseline role protection works correctly"

Write-Host "`nTest 6: Remove domain-specific member"
$removeResult = Invoke-TestScript -ScriptPath $teamScript -ArgumentList @(
    'remove', 'security-analyst',
    '-ProjectPath', $projectRoot
)

if ($removeResult.ExitCode -ne 0) {
    Write-Fail "Remove command failed for domain-specific member"
    foreach ($line in $removeResult.Output) {
        Write-Host $line
    }
    exit 1
}

if (Test-Path -LiteralPath $agentDir) {
    Write-Fail "Remove command did not delete agent directory"
    exit 1
}

$teamContent2 = Get-Content -LiteralPath $teamPath -Raw
if ($teamContent2 -match 'Security Analyst') {
    Write-Fail "Remove command did not remove member from team.md"
    exit 1
}

Write-Pass "Successfully removed domain-specific member"

Write-Host "`nTest 7: Attempt to add baseline role (should fail)"
$addBaselineResult = Invoke-TestScript -ScriptPath $teamScript -ArgumentList @(
    'add', 'implementer',
    '-Role', 'Implementer',
    '-Charter', 'Duplicate baseline role',
    '-ProjectPath', $projectRoot
)

if ($addBaselineResult.ExitCode -eq 0) {
    Write-Fail "Add command should have failed for baseline role name"
    exit 1
}

$addBaselineOutput = $addBaselineResult.Output -join "`n"
if ($addBaselineOutput -notmatch 'protected') {
    Write-Fail "Add command did not provide appropriate error message for baseline role"
    exit 1
}

Write-Pass "Cannot add member with baseline role name"

Write-Host "`nTest 8: Add multiple domain-specific members"
$roles = @(
    @{ Name = 'ux-designer'; Role = 'UX Designer'; Charter = 'Design user interfaces and user experiences.' }
    @{ Name = 'dba'; Role = 'Database Administrator'; Charter = 'Manage database schema, performance, and backups.' }
)

foreach ($roleInfo in $roles) {
    $addResult = Invoke-TestScript -ScriptPath $teamScript -ArgumentList @(
        'add', $roleInfo.Name,
        '-Role', $roleInfo.Role,
        '-Charter', $roleInfo.Charter,
        '-ProjectPath', $projectRoot
    )
    
    if ($addResult.ExitCode -ne 0) {
        Write-Fail "Failed to add member: $($roleInfo.Role)"
        exit 1
    }
}

$listResult3 = Invoke-TestScript -ScriptPath $teamScript -ArgumentList @('list', '-ProjectPath', $projectRoot)
$listOutput3 = $listResult3.Output -join "`n"

$allAdded = $true
foreach ($roleInfo in $roles) {
    if ($listOutput3 -notmatch [regex]::Escape($roleInfo.Role)) {
        Write-Fail "Member not found in list: $($roleInfo.Role)"
        $allAdded = $false
    }
}

if ($allAdded) {
    Write-Pass "Successfully added and listed multiple domain-specific members"
}

Write-Host "`nAll tests passed!" -ForegroundColor Green
Write-Host "Cleaning up test artifacts..."

if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

exit 0
