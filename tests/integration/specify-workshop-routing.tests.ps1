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
# NOTE (145 review): this test STATICALLY guards the SOURCE registration (the hook in extension.yml + the
# command file) and the deterministic gate (below). A one-time fresh-init dogfood confirmed the hook
# aggregates into a project's consumed .specify/extensions.yml; this body does NOT run init or inspect the
# consumed manifest - the maintainer re-test must confirm `before_specify: ...before-specify` actually lands.

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

# FR-010 (instruction route): the design-workshop must be the SINGLE intake — first action, no self-asked
# grounding questions, no speckit-specify until after. The before_specify hook is only a backstop inside
# speckit-specify's soft pre-exec check; a model that skims it bypasses the workshop and pre-grounds
# (dogfood test-f185). The coordinator instruction + specify digest are the primary route.
$coord = Get-Content -LiteralPath (Join-Path $repoRoot 'templates/coordinator-instructions.md') -Raw
if ($coord -notmatch 'specrew-design-workshop') { Write-Fail 'coordinator instruction must name specrew-design-workshop as the new-feature intake (FR-010)' }
if ($coord -notmatch '(?i)do NOT ask your own') { Write-Fail 'coordinator instruction must forbid self-asked grounding questions before the workshop (FR-010)' }
if ($coord -notmatch '(?i)until the workshop is complete') { Write-Fail 'coordinator instruction must forbid speckit-specify / spec-writing before the workshop completes (FR-010)' }
$dig = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/refocus/specify.md') -Raw
if ($dig -notmatch '(?i)IS the intake') { Write-Fail 'specify digest must declare the workshop is the intake, run first (FR-010)' }
if ($dig -notmatch '(?i)do NOT pre-ground') { Write-Fail 'specify digest must forbid pre-grounding with self-asked questions (FR-010)' }
Write-Pass 'FR-010 (instruction route): coordinator + specify digest make the design-workshop the single intake (first, no pre-grounding, no speckit-specify until after)'

# FR-010 (DETERMINISTIC gate — the non-probabilistic backstop): the design workshop is MANDATORY. The
# sync-specify boundary command refuses to advance without the workshop's lens records via the
# fail-closed Test-SpecrewWorkshopRecordsPresent check, BEFORE the authorization check. This is the
# piece that turns "please do the workshop" into "you cannot finish specify without it."
$gov = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1') -Raw
if ($gov -notmatch 'function Test-SpecrewWorkshopRecordsPresent') { Write-Fail 'shared-governance must define the deterministic workshop-records gate Test-SpecrewWorkshopRecordsPresent (FR-010)' }
$syncSpecify = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md') -Raw
if ($syncSpecify -notmatch 'Test-SpecrewWorkshopRecordsPresent') { Write-Fail 'sync-specify must invoke the workshop-records gate before advancing (FR-010)' }
if ($syncSpecify -notmatch 'SPECREW WORKSHOP GATE') { Write-Fail 'sync-specify must throw the workshop gate when the records are missing (FR-010)' }
Write-Pass 'FR-010 (deterministic gate): sync-specify refuses to advance the specify boundary without the workshop lens records (Test-SpecrewWorkshopRecordsPresent, fail-closed before the authorization check)'

# FR-010 (FUNCTIONAL fail-closed regression): a selected lens with NO workshop record must BLOCK
# (Present=$false), not fail open. The first cut threw under StrictMode on the missing property and fell
# into a fail-open catch (caught on the test-f185 live run). This guards that exact regression, and that
# an explicit human-skipped decision still counts as coverage.
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("f185gate-" + [System.Guid]::NewGuid().ToString('N'))
$tmpSpecs = Join-Path $tmpRoot 'specs/001-x'
New-Item -ItemType Directory -Path $tmpSpecs -Force | Out-Null
try {
    '{ "selected": ["architecture-core"], "workshop": { "product-domain": { "confirmation": "human-confirmed" } } }' | Set-Content -LiteralPath (Join-Path $tmpSpecs 'lens-applicability.json') -Encoding UTF8
    $r1 = Test-SpecrewWorkshopRecordsPresent -ProjectRoot $tmpRoot -FeatureRef '001-x'
    if ($r1.Present) { Write-Fail 'gate must FAIL-CLOSED when a selected lens has no workshop record (StrictMode fail-open regression)' }
    '{ "selected": ["architecture-core"], "workshop": { "architecture-core": { "confirmation": "human-skipped" } } }' | Set-Content -LiteralPath (Join-Path $tmpSpecs 'lens-applicability.json') -Encoding UTF8
    $r2 = Test-SpecrewWorkshopRecordsPresent -ProjectRoot $tmpRoot -FeatureRef '001-x'
    if (-not $r2.Present) { Write-Fail 'gate must PASS when every selected lens has a recorded decision (an explicit human-skipped counts as coverage)' }
}
finally { Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue }
Write-Pass 'FR-010 (functional fail-closed): a selected lens with no record BLOCKS; all-recorded (incl. explicit human-skipped) PASSES'

Write-Host ''
Write-Host 'Specify workshop-routing (feature 185 FR-010): all assertions pass'
exit 0
