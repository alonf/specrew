# Iteration 002, T016 (FR-025, SC-012) and T022 (FR-031, SC-017).
#
# T016 - ONE CHECK, ONE JOB. `pushed-head` carried two: release-model DELIVERY (what its own schema says it
# governs - "release_model controls only applicable closeout delivery steps") and, unnamed, the DURABILITY of
# the commit a verdict binds to. Aimed at delivery it fired at `specify` and asked a greenfield project to
# publish a repository to clear a SPECIFICATION - the HelloWinUIReactive walk, blocked there, with the
# pressure pointing at an irreversible outward-facing act. Split into two named checks.
#
# The durability job is REAL, not bookkeeping (the maintainer's question at the report review): every
# boundary records an auth_commit_hash and three readers resolve it back against git. So it keeps today's
# strength wherever an origin exists - this repository's every-boundary push requirement is unchanged - and
# says something honest, not a demand to publish, where none does.
#
# T022 - the closeout seal is the sync's LAST write. It ran before the dashboard re-render, whose `Captured
# At` timestamp guarantees changed bytes, so the seal never matched and the validator refused the closeout it
# had just produced (DRIFT-199-I002-003). Guaranteed, not conditional: every tester's first closeout.
#
# Mutations that turn this file red: restore the boundary-blind pushed-head (cases 1, 2); drop the
# enforcement_mode read (2); remove the durability check (3, 4); put the seal back before the dashboard
# render (6).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
. (Join-Path $repoRoot 'scripts\internal\gate-preflight.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }
function Get-Check {
    # A check that does not exist yet is the pre-fix shape this suite must REPORT, not throw on.
    param($Result, [string]$Name)
    $matches = @($Result.checks | Where-Object { $_.name -eq $Name })
    if ($matches.Count -eq 0) { return [pscustomobject]@{ name = $Name; status = '(absent)'; message = ''; evidence = $null } }
    return $matches[0]
}

function New-PostureFixture {
    # $Governance: the recorded posture. $Origin: create and wire a bare remote. $Push: push the branch.
    param([string]$Governance, [switch]$Origin, [switch]$Push)
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("posture-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = [System.IO.Path]::GetFullPath((Join-Path $root (Join-Path 'specs' '001-feat')))
    $iter = [System.IO.Path]::GetFullPath((Join-Path $feature (Join-Path 'iterations' '001')))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $root '.specrew/repository-governance.yml') -Value $Governance -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: executing" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 001`n`n**Tasks Remaining**: (none)`n**In Progress**: (none)`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'quality/hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'review.md') -Value "# Review`n`n**Overall Verdict**: accepted" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    if ($Origin) {
        $bare = $root + '-origin.git'
        & git init --bare -q $bare
        & git -C $root remote add origin $bare
        if ($Push) { & git -C $root push -q -u origin main }
    }
    return [pscustomobject]@{ Root = $root; Head = ([string](& git -C $root rev-parse HEAD)).Trim() }
}

$greenfield = @'
# The DevOps lens records the agreed FUTURE posture, and says honestly in the same file that it is not active.
release_model: pr-flow
release_model_provenance: recorded
publish_target: null

repository_governance:
  provider: github
  branch_model:
    style: trunk
    release_truth_branch: main
    branches:
      - name: main
        role: release-truth
        protected: false
  review_gate:
    human_review:
      required_approvals: 0
  enforcement_mode: manual
'@
$active = @'
release_model: pr-flow
release_model_provenance: recorded
publish_target: null

repository_governance:
  provider: github
  branch_model:
    style: trunk
    release_truth_branch: main
    branches:
      - name: main
        role: release-truth
        protected: true
  review_gate:
    human_review:
      required_approvals: 1
  enforcement_mode: branch-protection
'@
$localOnly = "release_model: local-only`nrelease_model_provenance: recorded`npublish_target: null`n"

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 1: the HelloWinUIReactive posture clears SPECIFY - the walk that was blocked'
$f1 = New-PostureFixture -Governance $greenfield
$r1 = Invoke-SpecrewGatePreflight -ProjectRoot $f1.Root -BoundaryType specify -FeatureRef '001-feat'
$ph1 = Get-Check -Result $r1 -Name 'pushed-head'
$vd1 = Get-Check -Result $r1 -Name 'verdict-commit-durable'
Assert-True ([string]$ph1.status -eq 'not-applicable') 'pushed-head is not-applicable at specify: delivery is a closeout job, per the schema its own description names'
Assert-True ([string]$ph1.message -match "governs closeout delivery only") 'and it says so, naming the boundary rather than demanding a remote'
Assert-True ([string]$vd1.status -eq 'not-applicable' -and [string]$vd1.message -match 'this local history is the only copy') 'durability is honest with no origin: it names the risk instead of demanding publication'
Assert-True (@($r1.checks | Where-Object { $_.status -eq 'fail' -and $_.name -in @('pushed-head', 'verdict-commit-durable') }).Count -eq 0) 'neither check blocks the specification boundary'

Write-Host 'Case 2: the same posture at a DELIVERY boundary is still not owed - declared future, not active'
$f2 = New-PostureFixture -Governance $greenfield
$r2 = Invoke-SpecrewGatePreflight -ProjectRoot $f2.Root -BoundaryType iteration-closeout -FeatureRef '001-feat' -IterationNumber '001'
$ph2 = Get-Check -Result $r2 -Name 'pushed-head'
Assert-True ([string]$ph2.status -eq 'not-applicable') 'pushed-head reads enforcement_mode: manual and does not demand a remote that does not exist'
Assert-True ([string]$ph2.message -match 'declared intention, not an active obligation' -and [string]$ph2.message -match 'becomes owed at the first closeout after the remote exists') 'the message says when delivery becomes owed, and that the recorded decision needs no change'

Write-Host 'Case 3: an ACTIVE enforcement mode with no origin is a contradiction, and fails'
$f3 = New-PostureFixture -Governance $active
$r3 = Invoke-SpecrewGatePreflight -ProjectRoot $f3.Root -BoundaryType iteration-closeout -FeatureRef '001-feat' -IterationNumber '001'
$ph3 = Get-Check -Result $r3 -Name 'pushed-head'
Assert-True ([string]$ph3.status -eq 'fail' -and [string]$ph3.message -match 'cannot be true without a remote') 'a record claiming active remote enforcement with no remote is refused, naming the contradiction'
Assert-True ([string]$ph3.message -match "record enforcement_mode: manual until it exists") 'and it names the one in-project action that resolves it'

Write-Host 'Case 4: with an origin, an unpushed HEAD still fails - at EVERY boundary, under the durability name'
$f4 = New-PostureFixture -Governance $active -Origin -Push
Set-Content -LiteralPath (Join-Path $f4.Root 'README.md') -Value 'local only' -Encoding UTF8
& git -C $f4.Root add README.md
& git -C $f4.Root commit -q -m 'unpushed'
$r4 = Invoke-SpecrewGatePreflight -ProjectRoot $f4.Root -BoundaryType specify -FeatureRef '001-feat'
$vd4 = Get-Check -Result $r4 -Name 'verdict-commit-durable'
Assert-True ([string]$vd4.status -eq 'fail') 'this repository''s every-boundary requirement is unchanged in strength - only renamed to its job'
Assert-True ([string]$vd4.message -match 'later gates resolve it back' -and [string]$vd4.message -match 'git push origin ') 'the durability message names why the commit must survive and the exact command'
Assert-True ([string](Get-Check -Result $r4 -Name 'pushed-head').status -eq 'not-applicable') 'while delivery stays silent at specify'

Write-Host 'Case 5: a pushed branch passes both, and local-only is not-applicable for delivery'
$f5 = New-PostureFixture -Governance $active -Origin -Push
$r5 = Invoke-SpecrewGatePreflight -ProjectRoot $f5.Root -BoundaryType iteration-closeout -FeatureRef '001-feat' -IterationNumber '001'
Assert-True ([string](Get-Check -Result $r5 -Name 'pushed-head').status -eq 'pass' -and [string](Get-Check -Result $r5 -Name 'verdict-commit-durable').status -eq 'pass') 'a pushed branch at a delivery boundary passes both checks'
$f5b = New-PostureFixture -Governance $localOnly
$r5b = Invoke-SpecrewGatePreflight -ProjectRoot $f5b.Root -BoundaryType iteration-closeout -FeatureRef '001-feat' -IterationNumber '001'
Assert-True ([string](Get-Check -Result $r5b -Name 'pushed-head').status -eq 'not-applicable' -and [string](Get-Check -Result $r5b -Name 'pushed-head').message -match 'local-only') 'local-only keeps its own not-applicable message at a delivery boundary'

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 6 (T022): the closeout sync writes the seal AFTER the dashboard it seals'
$syncSource = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1') -Raw -Encoding UTF8
$dashIdx = $syncSource.IndexOf('Invoke-SpecrewAutoRenderDashboard -ProjectRoot $paths.ProjectRoot -OutputPath $iterationDashboardPath')
$sealIdx = $syncSource.IndexOf('Write-SpecrewIterationSeal -IterationDirectory $sealIterationDir')
Assert-True ($dashIdx -gt 0 -and $sealIdx -gt 0 -and $sealIdx -gt $dashIdx) 'the seal write comes after the dashboard render in the closeout path'

Write-Host 'Case 6b: and the seal it writes actually matches the rendered dashboard on disk'
$f6 = New-PostureFixture -Governance $localOnly
$iter6 = Join-Path $f6.Root (Join-Path 'specs' (Join-Path '001-feat' (Join-Path 'iterations' '001')))
# The real ordering hazard: a timestamped file written between the seal and the check. Sealing LAST is what
# makes the first validation of a closed iteration pass, so the seal is taken after the render, as the sync does.
Set-Content -LiteralPath (Join-Path $iter6 'dashboard.md') -Value ("# Velocity Dashboard Snapshot`n`n**Captured At**: {0}`n" -f ((Get-Date).ToUniversalTime().ToString('o'))) -Encoding UTF8
$null = Write-SpecrewIterationSeal -IterationDirectory $iter6 -Feature '001-feat' -Iteration '001'
$integrity = Test-SpecrewIterationSealIntegrity -IterationDirectory $iter6
Assert-True ([bool]$integrity.checked -and @($integrity.drifted).Count -eq 0 -and @($integrity.missing).Count -eq 0 -and @($integrity.added).Count -eq 0) 'a seal taken after the render validates clean - nothing drifted, missing or added'
$sealPayload = Get-Content -LiteralPath (Join-Path $iter6 '.specrew-iteration-seal.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-True (@($sealPayload.sealed_files | Where-Object { $_.path -eq 'dashboard.md' }).Count -eq 1) 'and the manifest includes the rendered dashboard, which is what the closeout freezes'

foreach ($f in @($f1, $f2, $f3, $f4, $f5, $f5b, $f6)) {
    try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
    try { Remove-Item -LiteralPath ($f.Root + '-origin.git') -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
}
if ($script:failCount -gt 0) { throw ("delivery-durability-seal: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'delivery-durability-seal: all assertions passed' -ForegroundColor Green
