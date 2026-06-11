[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 iteration 001 unit tests:
#   T015 provider-neutral core + generic fallback + apply_protection guard (FR-014, FR-015, FR-020, SC-010).

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptsDir = Join-Path $repoRoot 'extensions\specrew-speckit\scripts'
. (Join-Path $scriptsDir 'provider-adapter.ps1')

# --- read-only posture (DP-S2/S3) ---
$gen = New-SpecrewProviderAdapter -Provider 'generic'
Assert-True ([bool]$gen['read_only']) 'T015: the generic fallback is read-only'
$gh = New-SpecrewProviderAdapter -Provider 'github'
Assert-True (-not [bool]$gh['read_only']) 'T015: the github reference adapter is not read-only'
$synU = New-SpecrewProviderAdapter -Provider 'gitlab' -Synthesized
Assert-True ([bool]$synU['read_only']) 'T015: an UNVERIFIED synthesized adapter is read-only'
$synV = New-SpecrewProviderAdapter -Provider 'gitlab' -Synthesized -Verified
Assert-True (-not [bool]$synV['read_only']) 'T015: a human-VERIFIED synthesized adapter is not read-only'

# --- generic fallback capability is honest (ci-only when CI present, else manual) ---
$cap = Invoke-SpecrewDetectCapability -Adapter $gen -ProjectPath $repoRoot
Assert-True ($cap.mechanism -in @('ci-only', 'manual')) "T015: generic capability is ci-only/manual (got $($cap.mechanism))"
Assert-True ($cap.mechanism -ne 'branch-protection') 'T015: the generic fallback NEVER promises branch protection'
Assert-True (@($cap.constraints).Count -ge 1) 'T015: capability report carries honest constraints'

# --- apply_protection guard (FR-020) ---
$a1 = Invoke-SpecrewApplyProtection -Adapter $gen -Governance @{} -Approved
Assert-True (-not [bool]$a1['applied']) 'T015: apply_protection is REFUSED for a read-only generic adapter even with -Approved'
$a2 = Invoke-SpecrewApplyProtection -Adapter $gh -Governance @{}
Assert-True (-not [bool]$a2['applied']) 'T015: apply_protection is REFUSED without explicit -Approved'
$a3 = Invoke-SpecrewApplyProtection -Adapter $synU -Governance @{} -Approved
Assert-True (-not [bool]$a3['applied']) 'T015: apply_protection is REFUSED for an unverified synthesized adapter'

# --- read_pr_context git-diff fallback works with NO adapter + is fail-open ---
$ctx = Get-SpecrewPrContext -ProjectPath $repoRoot -BaseRef 'HEAD' -HeadRef 'HEAD'
Assert-True ($ctx.Contains('changed_files')) 'T015: read_pr_context returns a changed_files set'
Assert-True (@($ctx.changed_files).Count -eq 0) 'T015: HEAD..HEAD diff is empty (no spurious changes)'
$bogus = Get-SpecrewPrContext -ProjectPath $repoRoot -BaseRef 'no-such-ref-xyz'
Assert-True (@($bogus.changed_files).Count -eq 0) 'T015: a bogus base ref fails-open to an empty set (no crash)'

# --- describe_protection is read-only + renders the captured governance ---
$gov = [ordered]@{ branch_model = [ordered]@{ style = 'trunk'; release_truth_branch = 'master'; branches = @([ordered]@{ name = 'master'; role = 'release-truth'; require_pull_request = $true; required_checks = @('tests'); allow_force_pushes = $false; allow_deletions = $false }) } }
$desc = Invoke-SpecrewDescribeProtection -Adapter $gh -Governance $gov
Assert-True ($desc -match "protect 'master'") 'T015: describe_protection honors the USER-NAMED release-truth branch (master, not main)'
Assert-True ($desc -match 'describe-only by default') 'T015: describe_protection states it is read-only by default'

# --- the forge-neutral CORE invokes no forge CLI/API (FR-014) ---
$coreFiles = @('work-kind-common.ps1', 'provider-adapter.ps1', 'provider-generic.ps1')
foreach ($f in $coreFiles) {
    $txt = Get-Content -LiteralPath (Join-Path $scriptsDir $f) -Raw -Encoding UTF8
    Assert-True (-not ($txt -match '(?m)(^|[^A-Za-z])gh\s+(pr|api|release|repo|auth)\b')) "T015: core '$f' invokes no gh CLI (forge-neutral)"
    Assert-True (-not ($txt -match 'api\.github\.com')) "T015: core '$f' calls no GitHub API URL (forge-neutral)"
}

Write-Host "`nAll T015 provider-adapter + forge-neutral-core assertions passed." -ForegroundColor Green
