[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 051 Iteration 1 (US2) acceptance tests — file classification, gitignore, git-rm-cached.
# Plain-PowerShell test convention (Assert-* helpers, exit 1 on failure).
# T014 (FR-005): gitignore generation excludes all per-session patterns, idempotent, preserves existing.
# T015 (FR-006): previously tracked per-session files removed from git index WITHOUT deleting working copy.
# Also covers FR-004 classification rule set (4 categories + canonical patterns).

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }
function Assert-True {
    param([Parameter(Mandatory = $true)][bool]$Condition, [Parameter(Mandatory = $true)][string]$Message)
    if (-not $Condition) { Write-Fail $Message; exit 1 }
    Write-Pass $Message
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$helper = Join-Path $repoRoot 'scripts/internal/file-classification.ps1'
Assert-True (Test-Path -LiteralPath $helper) "file-classification.ps1 exists at $helper"
. $helper

function New-TempDir {
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-f051-fc-{0}" -f ([System.Guid]::NewGuid().ToString('N')))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

$canonicalPerSession = @(
    '.specrew/last-*', '.specify/feature.json', '.specrew/start-context.json',
    '.specrew/host-history.json', '.specrew/.cache/', '.squad/sessions/',
    '.squad/decisions/inbox/', '.specrew/last-validator-summary.json'
)

# --- FR-004: classification rule set has all four categories + canonical per-session patterns ---
$rules = Get-FileClassification
$categories = @($rules | ForEach-Object { $_.category } | Sort-Object -Unique)
foreach ($cat in @('shared', 'per-session', 'append-only-shared', 'regenerable')) {
    Assert-True ($categories -contains $cat) "FR-004: classification includes category '$cat'"
}
$perSessionPatterns = @($rules | Where-Object { $_.category -eq 'per-session' } | ForEach-Object { $_.pattern })
foreach ($p in $canonicalPerSession) {
    Assert-True ($perSessionPatterns -contains $p) "FR-004: per-session rule set includes '$p'"
}

# --- T014 (FR-005): gitignore generation ---
$projA = New-TempDir
try {
    $gitignore = Join-Path $projA '.gitignore'
    # Pre-existing content with a comment + one already-present per-session pattern.
    Set-Content -LiteralPath $gitignore -Value @('# existing user rules', 'node_modules/', '.specrew/last-*') -Encoding UTF8

    Update-GitignoreForSession -ProjectRoot $projA
    $content1 = Get-Content -LiteralPath $gitignore -Raw

    foreach ($p in $canonicalPerSession) {
        Assert-True ($content1 -match [regex]::Escape($p)) "T014: .gitignore contains per-session pattern '$p'"
    }
    Assert-True ($content1 -match '# existing user rules') "T014: pre-existing comment preserved"
    Assert-True ($content1 -match 'node_modules/') "T014: pre-existing unrelated entry preserved"

    # Idempotent: re-run adds no duplicates.
    Update-GitignoreForSession -ProjectRoot $projA
    $content2 = Get-Content -LiteralPath $gitignore -Raw
    $occurrences = ([regex]::Matches($content2, [regex]::Escape('.specrew/last-*'))).Count
    Assert-True ($occurrences -eq 1) "T014: re-run does not duplicate '.specrew/last-*' (count=$occurrences)"
}
finally {
    Remove-Item -LiteralPath $projA -Recurse -Force -ErrorAction SilentlyContinue
}

# --- T015 (FR-006): git rm --cached removes from index, keeps working copy ---
$projB = New-TempDir
try {
    Push-Location $projB
    git init --quiet 2>$null
    git config user.email "test@example.com" 2>$null
    git config user.name "Test" 2>$null

    New-Item -ItemType Directory -Path (Join-Path $projB '.specrew') -Force | Out-Null
    $tracked = Join-Path $projB '.specrew/last-start-prompt.md'
    Set-Content -LiteralPath $tracked -Value 'session prompt' -Encoding UTF8
    $keep = Join-Path $projB 'README.md'
    Set-Content -LiteralPath $keep -Value '# project' -Encoding UTF8
    git add -A 2>$null
    git commit --quiet -m "initial (per-session file tracked)" 2>$null

    $beforeTracked = @(git ls-files)
    Assert-True ($beforeTracked -contains '.specrew/last-start-prompt.md') "T015: per-session file is initially tracked"

    $removed = Remove-TrackedPerSessionFiles -ProjectRoot $projB

    $afterTracked = @(git ls-files)
    Assert-True ($afterTracked -notcontains '.specrew/last-start-prompt.md') "T015: per-session file removed from git index"
    Assert-True ($afterTracked -contains 'README.md') "T015: unrelated tracked file (README.md) untouched"
    Assert-True (Test-Path -LiteralPath $tracked) "T015: working-tree copy of per-session file still present (not deleted)"
    Assert-True ($removed -contains '.specrew/last-start-prompt.md') "T015: function reports the removed path"
}
finally {
    Pop-Location
    Remove-Item -LiteralPath $projB -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "All Feature-051 file-classification (US2) acceptance tests passed." -ForegroundColor Green
exit 0
