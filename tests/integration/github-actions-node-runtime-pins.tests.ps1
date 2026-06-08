# Validates repository-owned GitHub Actions pins stay on Node 24 action majors.
# Historical fixtures under tests/ are intentionally out of scope.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Pass $Message } else { Write-Fail $Message }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workflowRoots = @(
    Join-Path $repoRoot '.github\workflows'
    Join-Path $repoRoot '.squad\templates\workflows'
)

$workflowFiles = @(
    foreach ($root in $workflowRoots) {
        Get-ChildItem -LiteralPath $root -Filter '*.yml' -File -ErrorAction Stop
    }
)

Assert-True ($workflowFiles.Count -gt 0) 'workflow files were discovered'

$forbiddenPins = @(
    'actions/checkout@v4'
    'actions/checkout@v5'
    'actions/setup-node@v4'
    'actions/setup-node@v5'
    'actions/upload-artifact@v4'
    'actions/upload-artifact@v5'
    'actions/upload-artifact@v6'
    'actions/github-script@v7'
    'actions/github-script@v8'
)

$requiredPins = @(
    'actions/checkout@v6'
    'actions/setup-node@v6'
    'actions/upload-artifact@v7'
    'actions/github-script@v9'
)

$allContent = ''
foreach ($file in $workflowFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $relative = [System.IO.Path]::GetRelativePath($repoRoot, $file.FullName)
    foreach ($pin in $forbiddenPins) {
        Assert-True (-not $content.Contains($pin)) "$relative does not use stale $pin"
    }
    $allContent += "`n$content"
}

foreach ($pin in $requiredPins) {
    Assert-True ($allContent.Contains($pin)) "repository workflows include current Node 24 pin $pin"
}

if ($script:Failures -gt 0) {
    Write-Host "GitHub Actions Node runtime pin tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}

Write-Host 'GitHub Actions Node runtime pin tests: all passed' -ForegroundColor Green
exit 0
