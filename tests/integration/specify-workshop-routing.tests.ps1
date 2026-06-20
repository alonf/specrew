[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

# Feature 185 FR-010: the specify entry must route through the Specrew design workshop. Spec Kit's
# speckit-specify reads `.specify/extensions.yml` -> hooks.before_specify before generating. Specrew
# registered before_plan / after_tasks / before_implement but NOT before_specify, so once FR-013
# deployed the speckit commands the host ran raw speckit-specify (workshop-less spec generation) —
# dogfood test-f185. Fix: register a before_specify hook -> a command that routes to specrew-design-workshop.
# Verified end-to-end on 2026-06-20: a fresh init aggregates the hook into the project extensions.yml.

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$ext = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/extension.yml') -Raw

if ($ext -notmatch '(?m)^\s*before_specify:') { Write-Fail 'extension.yml must register a before_specify hook (FR-010)' }
if ($ext -notmatch 'speckit\.specrew-speckit\.before-specify') { Write-Fail 'before_specify hook + command registration must reference speckit.specrew-speckit.before-specify (FR-010)' }

$cmd = Join-Path $repoRoot 'extensions/specrew-speckit/commands/speckit.specrew-speckit.before-specify.md'
if (-not (Test-Path -LiteralPath $cmd)) { Write-Fail 'before-specify command file must exist (FR-010)' }
$cmdContent = Get-Content -LiteralPath $cmd -Raw
if ($cmdContent -notmatch 'specrew-design-workshop') { Write-Fail 'before-specify command must route to the specrew-design-workshop skill (FR-010)' }
if ($cmdContent -notmatch 'lens') { Write-Fail 'before-specify command must require the lens workshop with the human (FR-010)' }

# Source <-> .specify mirror parity (the deployed copy must match).
$srcHash = (Get-FileHash -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/extension.yml')).Hash
$mirHash = (Get-FileHash -LiteralPath (Join-Path $repoRoot '.specify/extensions/specrew-speckit/extension.yml')).Hash
if ($srcHash -ne $mirHash) { Write-Fail 'extension.yml source/.specify mirror drift (FR-010)' }

Write-Pass 'FR-010: before_specify hook registered -> before-specify command routes speckit-specify through specrew-design-workshop (lens workshop with the human); source/mirror parity holds'

Write-Host ''
Write-Host 'Specify workshop-routing (feature 185 FR-010): all assertions pass'
exit 0
