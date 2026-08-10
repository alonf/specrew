$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Trace: T007 / FR-012, FR-013 / SC-007.
#
# THE BOOTSTRAP DEADLOCK, end to end. DRIFT-199-I001-008 is this exact sequence on the maintainer's own
# repository: a governed project matched nothing in the verification catalog, the campaign preflight
# died with `verification-not-configured`, and the stop surface simultaneously demanded a review that
# could not start. A project is none of the catalog's cases simply by not being an npm project, which is
# most of them - this repository included.
#
# SCOPE OF THIS FIXTURE, stated precisely rather than implied. It drives the REAL materializer (the same
# function `specrew init` and `specrew update` call) and then the REAL selected-plan resolver, which is
# the exact gate that failed in DRIFT-199-I001-008 - `no supplier output at
# .specrew/verification-plan.json`. It does NOT stand up a git worktree, a harness, or a runtime port,
# so it is not the whole campaign preflight; it is the plan-resolution gate that preflight fails at.
# Anything beyond that is the live acceptance measurement, not a unit of this suite.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/verification-plan-materializer.ps1')
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/verification-plan-runner.ps1')

$failures = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) $script:failures++; Write-Host "FAIL: $m" -ForegroundColor Red }

function New-GovernedProject {
    # A realistic consumer tree: governed (init has deployed the validator) but with no package.json and
    # no declared quality profile - which is what every non-npm project looks like.
    param([Parameter(Mandatory)][string]$Root)
    $validator = Join-Path $Root '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path $validator -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $validator 'validate-governance.ps1'), 'exit 0', [Text.UTF8Encoding]::new($false))
    return $Root
}

function Get-PlanPath { param([string]$Root) Join-Path $Root '.specrew/verification-plan.json' }

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('init-verification-plan-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
try {
    # ---------------------------------------------------------------- 1. the deadlock is gone
    $project = New-GovernedProject -Root (Join-Path $scratch 'fresh')
    $before = Get-ContinuousCoReviewSelectedVerificationPlan -RepoRoot $project
    if (-not $before.available -and ([string]$before.reason) -match 'verification-plan\.json') {
        Write-Pass 'BEFORE init the plan gate refuses, and names the file (the DRIFT-199-I001-008 state)'
    }
    else { Fail "expected the pre-init gate to refuse naming the plan file; got available=$($before.available) reason=$($before.reason)" }

    if (([string]$before.reason) -match '(?i)specrew init') {
        Write-Pass 'FR-013: that refusal names the command that fixes it, not just the requirement it violates'
    }
    else { Fail "the absent-plan refusal does not name `specrew init`: $($before.reason)" }

    $materialized = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project
    if ([string]$materialized.action -eq 'created-starter-plan' -and (Test-Path -LiteralPath (Get-PlanPath $project))) {
        Write-Pass 'init materializes a starter plan for a governed project that matches no catalog entry'
    }
    else { Fail "expected created-starter-plan; got action=$($materialized.action) state=$($materialized.state)" }

    # THE ACCEPTANCE POINT: the same gate that refused now resolves.
    $after = Get-ContinuousCoReviewSelectedVerificationPlan -RepoRoot $project
    if ([bool]$after.available -and $null -ne $after.plan) {
        Write-Pass 'AFTER init the plan gate RESOLVES - the bootstrap deadlock is broken'
    }
    else { Fail "expected the plan gate to resolve after init; got available=$($after.available) reason=$($after.reason)" }

    $structural = Test-ContinuousCoReviewVerificationPlan -Plan $after.plan -RepoRoot $project
    if ([bool]$structural.valid -and [int]$structural.command_count -ge 1) {
        Write-Pass "the scaffolded plan validates through the SHIPPED contract ($($structural.command_count) command)"
    }
    else { Fail "the scaffolded plan does not validate: $($structural.reason)" }

    # ---------------------------------------------------------------- 2. each broken piece NAMES itself
    # FR-013's independent test: break each named piece, verify the error names it rather than sealing.
    $planPath = Get-PlanPath $project
    $good = Get-Content -LiteralPath $planPath -Raw

    # (a) plan schema element
    $noVersion = $good -replace '"schema_version"\s*:\s*"1\.0"\s*,?', ''
    [IO.File]::WriteAllText($planPath, $noVersion, [Text.UTF8Encoding]::new($false))
    $broken = Get-ContinuousCoReviewSelectedVerificationPlan -RepoRoot $project
    if (-not $broken.available -and ([string]$broken.reason) -match 'schema_version') {
        Write-Pass 'a missing schema element NAMES the element (schema_version), not a generic failure'
    }
    else { Fail "expected schema_version to be named; got available=$($broken.available) reason=$($broken.reason)" }

    # (b) env_refs - a literal NAME=value is the secret-bearing shape the contract forbids
    $planObject = $good | ConvertFrom-Json
    $planObject.commands[0].env_refs = @('PATH', 'SECRET=hunter2')
    [IO.File]::WriteAllText($planPath, ($planObject | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
    $brokenEnv = Get-ContinuousCoReviewSelectedVerificationPlan -RepoRoot $project
    if (-not $brokenEnv.available -and ([string]$brokenEnv.reason) -match 'env_refs') {
        Write-Pass 'a secret-shaped env_refs entry NAMES env_refs and says only NAMES are allowed'
    }
    else { Fail "expected env_refs to be named; got available=$($brokenEnv.available) reason=$($brokenEnv.reason)" }

    # ---------------------------------------------------------------- 3. the consumer owns the file
    [IO.File]::WriteAllText($planPath, $good, [Text.UTF8Encoding]::new($false))
    $edited = $good.Replace('"timeout_seconds": 180', '"timeout_seconds": 240')
    [IO.File]::WriteAllText($planPath, $edited, [Text.UTF8Encoding]::new($false))
    $second = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project
    if ([string]$second.action -eq 'preserved-explicit-plan' -and (Get-Content -LiteralPath $planPath -Raw) -eq $edited) {
        Write-Pass 'a second init PRESERVES the consumer''s edits byte-for-byte'
    }
    else { Fail "expected preserved-explicit-plan with edits intact; got action=$($second.action)" }

    # ---------------------------------------------------------------- 4. NOT governed -> no scaffolding
    # The gate is the deployed validator's presence. Scaffolding a plan whose only command is a missing
    # script would fail on first review while LOOKING configured - worse than no plan.
    $bare = Join-Path $scratch 'bare'
    New-Item -ItemType Directory -Path $bare -Force | Out-Null
    $bareResult = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $bare
    if (-not (Test-Path -LiteralPath (Get-PlanPath $bare)) -and [string]$bareResult.state -eq 'verification-not-configured') {
        Write-Pass 'a NON-governed directory gets no starter - a plan whose command cannot run is worse than none'
    }
    else { Fail "expected no scaffolding in a non-governed directory; got state=$($bareResult.state) action=$($bareResult.action)" }
}
finally { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }

if ($failures -gt 0) { Write-Host "$failures failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'All init verification-plan bootstrap tests passed.' -ForegroundColor Green
exit 0
