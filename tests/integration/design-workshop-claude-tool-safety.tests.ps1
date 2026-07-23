[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { Write-Fail $Message }
    Write-Pass $Message
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$skillRelativePath = 'extensions\specrew-speckit\squad-templates\skills\design-workshop.md'
$skillPath = Join-Path $repoRoot $skillRelativePath
$mirrorPath = Join-Path $repoRoot (Join-Path '.specify' $skillRelativePath)
$deployScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\design-workshop-claude-tool-safety'

Assert-True (Test-Path -LiteralPath $skillPath -PathType Leaf) 'canonical design-workshop skill exists'
Assert-True (Test-Path -LiteralPath $mirrorPath -PathType Leaf) 'project-side design-workshop mirror exists'

$canonical = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
$mirror = Get-Content -LiteralPath $mirrorPath -Raw -Encoding UTF8
Assert-True ($canonical -eq $mirror) 'canonical and project-side design-workshop sources are byte-identical'
Assert-True ($canonical -match '(?m)^claude-disallowed-tools:\s*AskUserQuestion\s*$') 'canonical skill declares Claude-only AskUserQuestion removal'
Assert-True ($canonical -notmatch '(?m)^disallowed-tools:\s*AskUserQuestion\s*$') 'canonical skill does not disable another host before materialization'
Assert-True ($canonical -match '(?i)numbered prose list answered by typing') 'workshop conduct tells Claude to use visible typed choices'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

try {
    New-Item -ItemType Directory -Path (Join-Path $scratchRoot '.squad') -Force | Out-Null
    & $deployScript -ProjectPath $scratchRoot | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "deploy-squad-runtime exited $LASTEXITCODE"
    }

    $surfaces = @(
        [pscustomobject]@{ Host = 'claude'; Path = (Join-Path $scratchRoot '.claude\skills\specrew-design-workshop\SKILL.md') },
        [pscustomobject]@{ Host = 'cursor'; Path = (Join-Path $scratchRoot '.cursor\rules\specrew-design-workshop\SKILL.md') },
        [pscustomobject]@{ Host = 'github'; Path = (Join-Path $scratchRoot '.github\skills\specrew-design-workshop\SKILL.md') },
        [pscustomobject]@{ Host = 'agents'; Path = (Join-Path $scratchRoot '.agents\skills\specrew-design-workshop\SKILL.md') }
    )

    foreach ($surface in $surfaces) {
        Assert-True (Test-Path -LiteralPath $surface.Path -PathType Leaf) "$($surface.Host) workshop skill was deployed"
        $actual = Get-Content -LiteralPath $surface.Path -Raw -Encoding UTF8
        $expected = if ($surface.Host -eq 'claude') {
            $canonical -replace '(?m)^claude-disallowed-tools:', 'disallowed-tools:'
        }
        else {
            $canonical -replace '(?m)^claude-disallowed-tools:[^\r\n]*(\r?\n)', ''
        }

        Assert-True ($actual -eq $expected) "$($surface.Host) receives the exact host-materialized workshop skill"
        Assert-True ($actual -notmatch '(?m)^claude-disallowed-tools:') "$($surface.Host) does not receive canonical-only deployment metadata"

        if ($surface.Host -eq 'claude') {
            Assert-True ($actual -match '(?m)^disallowed-tools:\s*AskUserQuestion\s*$') 'Claude cannot call the picker that swallows the rendered workshop agenda'
        }
        else {
            Assert-True ($actual -notmatch '(?m)^disallowed-tools:\s*AskUserQuestion\s*$') "$($surface.Host) retains its structured-question capability"
        }
    }
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Host "`ndesign-workshop Claude tool-safety: all assertions pass" -ForegroundColor Green
exit 0
