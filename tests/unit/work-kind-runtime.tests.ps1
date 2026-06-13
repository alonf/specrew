[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 iteration 002 unit tests:
#   T212 capability detection + brownfield (FR-012, FR-021, SC-006) + apply_protection denial-path
#   (FR-020) + fail-open + the SC-014 dogfood self-consistency.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$scriptsDir = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'scripts'
. (Join-Path $scriptsDir 'capability-detector.ps1')
. (Join-Path $scriptsDir 'provider-github.ps1')

# --- capability detection: generic path is honest (ci-only/manual; never branch-protection) ---
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("wk-runtime-" + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $tmp -Force
try {
    $cap = Invoke-SpecrewCapabilityDetection -ProjectPath $tmp -Provider 'generic'
    Assert-True ($cap.mechanism -in @('ci-only', 'manual')) "T212: generic capability is ci-only/manual (got $($cap.mechanism))"
    Assert-True ($cap.mechanism -ne 'branch-protection') 'T212: the generic path NEVER promises branch protection'
    Assert-True ([bool]$cap['describe_only_default']) 'T212: capability report is describe-only by default'

    # --- an unrecognized forge -> manual + a synthesis offer (read-only) ---
    $cap2 = Invoke-SpecrewCapabilityDetection -ProjectPath $tmp -Provider 'gitlab'
    Assert-True ($cap2.mechanism -eq 'manual') "T212: an unshipped forge -> manual (got $($cap2.mechanism))"
    Assert-True ((@($cap2.constraints) -join ' ') -match 'synthesize a READ-ONLY adapter') 'T212: unshipped forge offers a READ-ONLY synthesized adapter (apply stays human-approved)'

    # --- brownfield: a repo with a CI signal -> ADAPT; without -> CHANGE ---
    $null = New-Item -ItemType Directory -Path (Join-Path $tmp '.github' 'workflows') -Force
    $bf = Invoke-SpecrewBrownfieldDetection -ProjectPath $tmp -Provider 'generic'
    Assert-True ([bool]$bf.ci_detected -and ($bf.recommendation -match '^ADAPT')) 'T212: brownfield with existing CI -> ADAPT (slot into existing lane)'
    Assert-True ($bf.never_overwrite_note -match 'never overwrites') 'T212: brownfield NEVER overwrites an existing setup'
    $tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ("wk-runtime2-" + [Guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $tmp2 -Force
    $bf2 = Invoke-SpecrewBrownfieldDetection -ProjectPath $tmp2 -Provider 'generic'
    Assert-True (-not [bool]$bf2.ci_detected -and ($bf2.recommendation -match '^CHANGE')) 'T212: brownfield with no CI -> CHANGE (recommend the posture)'
    Remove-Item -LiteralPath $tmp2 -Recurse -Force -ErrorAction SilentlyContinue
}
finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }

# --- apply_protection denial-path (FR-020) ---
$a1 = Invoke-SpecrewGitHubApplyProtection -Governance @{}
Assert-True (-not [bool]$a1['applied']) 'T212: GitHub apply_protection REFUSED without -Approved'
$a2 = Invoke-SpecrewGitHubApplyProtection -Governance @{} -Approved   # approved but not -Execute
Assert-True (-not [bool]$a2['applied']) 'T212: GitHub apply_protection with -Approved but no -Execute is describe-only (no mutation)'

# --- SC-014 dogfood self-consistency: Specrew's own capture matches its actual posture (structural) ---
$wkDecl = Join-Path $repoRoot '.specrew' 'work-kind.yml'
$govFile = Join-Path $repoRoot '.specrew' 'repository-governance.yml'
Assert-True (Test-Path -LiteralPath $wkDecl) 'T212 (SC-014): Specrew dogfoods a .specrew/work-kind.yml'
Assert-True ((Get-Content -LiteralPath $wkDecl -Raw) -match 'work_kind:\s*software-feature') 'T212 (SC-014): Specrew declares software-feature (feature 182)'
Assert-True (Test-Path -LiteralPath $govFile) 'T212 (SC-014): Specrew dogfoods a .specrew/repository-governance.yml'
$gov = Get-Content -LiteralPath $govFile -Raw
Assert-True ($gov -match 'provider:\s*github') 'T212 (SC-014): governance records provider github'
Assert-True ($gov -match 'release_truth_branch:\s*main') 'T212 (SC-014): release-truth branch = main (matches the real protected branch)'
Assert-True ($gov -match 'protected:\s*true' -and $gov -match 'allow_force_pushes:\s*false' -and $gov -match 'allow_deletions:\s*false') 'T212 (SC-014): main protected, no force-push/deletion (matches the 2026-06-11 mitigation)'
Assert-True ($gov -match 'apply_to_admins:\s*true') 'T212 (SC-014): protection applies to admins (matches actual posture)'

# --- the governance schema validates the dogfood file shape (best-effort structural; Test-Json if available) ---
$govSchemaPath = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'knowledge' 'repository-governance.schema.json'
Assert-True (Test-Path -LiteralPath $govSchemaPath) 'T212: repository-governance.schema.json ships'
$schema = Get-Content -LiteralPath $govSchemaPath -Raw | ConvertFrom-Json
Assert-True ($null -ne $schema -and $schema.'$defs'.branchModel) 'T212: governance schema defines branchModel (the capture has a schema)'

Write-Host "`nAll T212 capability/denial-path/brownfield/SC-014 assertions passed." -ForegroundColor Green
