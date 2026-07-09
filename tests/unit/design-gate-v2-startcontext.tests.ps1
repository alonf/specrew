[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Proposal-145 review fix (iter-007, 2026-06-26): the v1->v2 start-context migration left
# Test-SpecrewDesignAnalysisGateRequired bailing on `session_state -eq $null`, so the design-analysis
# (plan-boundary) gate was SILENTLY DISABLED on every v2 project (a v2 start-context has no session_state;
# the active feature lives in .specify/feature.json, the boundary in boundary_enforcement). This pins the
# fix: v1 keeps the full session_state cross-check; v2 resolves the active feature from feature.json + the
# boundary from boundary_enforcement. Fails on the PRE-fix gate (v2 -> false), passes after.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 } Write-Pass $m }

. (Join-Path $PSScriptRoot '..\..\scripts\internal\design-analysis-gate.ps1')

function New-DesignGateProject {
    param([string]$Boundary, [string]$FeatureDir = '001-test-feature', [switch]$V1)
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('dgv2-' + [guid]::NewGuid().ToString('N'))
    $u = [System.Text.UTF8Encoding]::new($false)
    $mapDir = Join-Path $root 'extensions\specrew-speckit\knowledge\design-lenses'
    $featDir = Join-Path $root "specs\$FeatureDir"
    $null = New-Item -ItemType Directory -Path $mapDir, $featDir, (Join-Path $root '.specrew'), (Join-Path $root '.specify') -Force
    [System.IO.File]::WriteAllText((Join-Path $mapDir 'applicability-map.json'), '{"always_on":["architecture-core"],"questions":[]}', $u)
    [System.IO.File]::WriteAllText((Join-Path $featDir 'spec.md'), "# Spec`nThis governance lifecycle feature changes boundary enforcement, helper validation, and state behavior.", $u)
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew\config.yml'), "specrew_version: `"0.39.0`"`n", $u)
    [System.IO.File]::WriteAllText((Join-Path $root '.specify\feature.json'), ('{"feature_directory":"specs/' + $FeatureDir + '"}'), $u)
    $sc = if ($V1) {
        '{"schema":"v1","session_state":{"active":true,"feature_ref":"' + $FeatureDir + '","boundary_type":"' + $Boundary + '"}}'
    }
    else {
        # v2: NO session_state; boundary in boundary_enforcement (the real shape that disabled the gate).
        '{"schema":"v2","boundary_enforcement":{"last_authorized_boundary":"' + $Boundary + '"}}'
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew\start-context.json'), $sc, $u)
    return $root
}

try {
    # (1) THE FIX: a v2 project at a pre-plan boundary, no design-analysis artifact yet -> gate REQUIRED.
    #     Before the fix this returned FALSE (session_state-null bail) -> the gate was silently dead on v2.
    $v2 = New-DesignGateProject -Boundary 'specify'
    Assert-True (Test-SpecrewDesignAnalysisGateRequired -ProjectRoot $v2 -FeatureRef '001-test-feature') 'v2: the design-analysis gate is REQUIRED on a v2 project at a pre-plan boundary (was silently DEAD before the fix)'

    # (2) the feature.json cross-check still holds on v2: a non-active feature does NOT trigger the gate.
    Assert-True (-not (Test-SpecrewDesignAnalysisGateRequired -ProjectRoot $v2 -FeatureRef '999-other-feature')) 'v2: the gate does NOT apply for a feature that is not the active one (feature.json cross-check)'

    # (3) past the pre-plan window (v2 boundary = implement) -> NOT required.
    $v2post = New-DesignGateProject -Boundary 'implement'
    Assert-True (-not (Test-SpecrewDesignAnalysisGateRequired -ProjectRoot $v2post -FeatureRef '001-test-feature')) 'v2: the gate does NOT apply once past the pre-plan boundary window'

    # (4) regression: the v1 path is unchanged - an active v1 session at pre-plan still requires the gate.
    $v1 = New-DesignGateProject -Boundary 'specify' -V1
    Assert-True (Test-SpecrewDesignAnalysisGateRequired -ProjectRoot $v1 -FeatureRef '001-test-feature') 'v1: the full session_state cross-check path still requires the gate (no regression)'

    # (5) regression: an INACTIVE v1 session -> not required (the session_state.active check still works).
    $v1inactive = Join-Path ([System.IO.Path]::GetTempPath()) ('dgv1i-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path (Join-Path $v1inactive '.specrew') -Force
    Copy-Item -Recurse -Force (Join-Path $v1 '*') $v1inactive
    [System.IO.File]::WriteAllText((Join-Path $v1inactive '.specrew\start-context.json'), '{"schema":"v1","session_state":{"active":false,"feature_ref":"001-test-feature","boundary_type":"specify"}}', [System.Text.UTF8Encoding]::new($false))
    Assert-True (-not (Test-SpecrewDesignAnalysisGateRequired -ProjectRoot $v1inactive -FeatureRef '001-test-feature')) 'v1: an inactive session does NOT require the gate (session_state.active still honored)'

    Write-Host "`n=== design-gate-v2-startcontext.tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally {
    Get-ChildItem ([System.IO.Path]::GetTempPath()) -Directory -Filter 'dgv*' -ErrorAction SilentlyContinue | Where-Object { $_.CreationTime -gt (Get-Date).AddMinutes(-5) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
