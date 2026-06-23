[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

# Feature 185 FR-013: the coordinator instruction must distinguish the FORBIDDEN raw specify.exe workflow
# from the ALLOWED Specrew-governed scripts/commands. The #2884 4th-face dogfood (test-f197, Claude host):
# a willing host was blocked because the over-broad guard conflated the governed create-new-feature.ps1
# scaffold script with the raw SDD engine, while its native speckit commands were never deployed.

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$ci = Get-Content -LiteralPath (Join-Path $repoRoot 'templates/coordinator-instructions.md') -Raw

# The raw, un-governed engine is STILL forbidden.
if ($ci -notmatch 'specify\.exe workflow') { Write-Fail 'coordinator instruction must still name the forbidden raw specify.exe workflow' }
# The governed scaffold script is explicitly blessed (so the guard / auto-mode classifier does not block it).
if ($ci -notmatch 'create-new-feature\.ps1') { Write-Fail 'coordinator instruction must bless the governed scaffold script (create-new-feature.ps1) so the guard does not block it (FR-013)' }
# The two are explicitly distinguished.
if ($ci -notmatch 'are NOT that') { Write-Fail 'coordinator instruction must explicitly state the governed scripts/commands are NOT the raw automation (FR-013)' }
# The Specrew-coordinator / Spec-Kit-SDD division is stated.
if ($ci -notmatch 'Specrew governs the lifecycle gates') { Write-Fail 'coordinator instruction must state the Specrew-coordinator / Spec-Kit-SDD division' }
# It points at the per-host entry-point reality (commands where exposed, else the governed scripts).
if ($ci -notmatch 'where your host exposes them') { Write-Fail 'coordinator instruction must name the per-host entry-point reality (commands where exposed, else governed scripts)' }
Write-Pass 'FR-013 guard precision: coordinator instruction blesses the governed scripts/commands, forbids only the raw specify.exe workflow, states the coordinator/SDD division, and names the per-host entry point'

Write-Host ''
Write-Host 'Coordinator instruction guard precision (feature 185 FR-013): all assertions pass'
exit 0
