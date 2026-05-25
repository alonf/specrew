[CmdletBinding()]
param()

# F-044 iter-003 regression test for Bug 2 — all skill templates must have YAML frontmatter
# so Claude/Antigravity (and likely Copilot's stricter loader) accept them at install time.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$skillsRoot = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\skills'

if (-not (Test-Path -LiteralPath $skillsRoot -PathType Container)) {
    Write-Fail "Skill templates root not found at expected path: $skillsRoot"
}

# Two template shapes are supported:
#   1. Directory-style: skills/<name>/SKILL.md with --- frontmatter at top
#   2. Generic-file-style: skills/<name>.md with --- frontmatter at top (deployed as specrew-<name>/SKILL.md)
# Both must have valid YAML frontmatter (closing iter-003 Bug 2).

$failures = @()

# Directory-style: every */SKILL.md must have frontmatter
$dirStyleSkills = @(Get-ChildItem -LiteralPath $skillsRoot -Directory -ErrorAction SilentlyContinue)
foreach ($dir in $dirStyleSkills) {
    $skillFile = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
        $failures += "$($dir.Name)/SKILL.md missing"
        continue
    }
    $content = Get-Content -LiteralPath $skillFile -Raw -Encoding UTF8
    if ($content -notmatch '^---\s*[\r\n]+name:\s') {
        $failures += "$($dir.Name)/SKILL.md missing YAML frontmatter (--- + name: ...)"
    }
}

# Generic-file-style: every <name>.md (except README.md) must have frontmatter
$genericStyleSkills = @(Get-ChildItem -LiteralPath $skillsRoot -Filter '*.md' -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'README.md' })
foreach ($file in $genericStyleSkills) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($content -notmatch '^---\s*[\r\n]+name:\s') {
        $failures += "$($file.Name) missing YAML frontmatter (--- + name: ...) — closes iter-003 Bug 2 regression"
    }
}

if ($failures.Count -gt 0) {
    foreach ($f in $failures) {
        Write-Host "  FAIL: $f" -ForegroundColor Red
    }
    Write-Fail ("{0} skill template(s) missing YAML frontmatter — iter-003 Bug 2 regression." -f $failures.Count)
}

$totalSkills = $dirStyleSkills.Count + $genericStyleSkills.Count
Write-Pass ("All {0} skill template(s) have YAML frontmatter ({1} directory-style + {2} generic-style)" -f $totalSkills, $dirStyleSkills.Count, $genericStyleSkills.Count)

Write-Host "`nSkill templates: all assertions pass" -ForegroundColor Green
