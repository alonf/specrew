[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 (work-kind + branch governance) iteration 001 unit tests:
#   T014 catalog + schema integrity (FR-001, FR-003, FR-009, SC-001).
# Pure unit tests against the shipped catalog + schemas + the focused readers.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$knowledgeDir = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge'
$scriptsDir = Join-Path $repoRoot 'extensions\specrew-speckit\scripts'
. (Join-Path $scriptsDir 'work-kind-common.ps1')

$catalogPath = Join-Path $knowledgeDir 'work-kinds.yml'
$catalogSchemaPath = Join-Path $knowledgeDir 'work-kinds.schema.json'
$govSchemaPath = Join-Path $knowledgeDir 'repository-governance.schema.json'

# --- catalog presence + parse ---
Assert-True (Test-Path -LiteralPath $catalogPath) 'T014: work-kinds.yml catalog exists'
$cat = ConvertFrom-SpecrewWorkKindCatalog -Text (Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8)
Assert-True ($null -ne $cat) 'T014: catalog parses via the dependency-free reader'
Assert-True ($cat.schema_version -eq '1.0') 'T014: catalog declares schema_version 1.0'

# --- exactly the 4 canonical, unique, stable ids ---
$ids = @($cat.work_kinds | ForEach-Object { $_.id })
Assert-True ($ids.Count -eq 4) "T014: catalog has 4 work kinds (got $($ids.Count))"
$expected = @('software-feature', 'bug-bash', 'docs-only', 'devops')
foreach ($e in $expected) { Assert-True ($ids -contains $e) "T014: catalog contains '$e'" }
$uniq = @($ids | Sort-Object -Unique)
Assert-True ($uniq.Count -eq $ids.Count) 'T014: work-kind ids are unique (no duplicates)'

# --- each kind has the required fields populated ---
foreach ($wk in $cat.work_kinds) {
    Assert-True (-not [string]::IsNullOrWhiteSpace($wk.lifecycle_weight)) "T014: '$($wk.id)' has lifecycle_weight"
    Assert-True (@($wk.required_evidence).Count -ge 1) "T014: '$($wk.id)' has >=1 required_evidence"
    Assert-True (@($wk.allowed_scope).Count -ge 1) "T014: '$($wk.id)' has >=1 allowed_scope glob"
}

# --- docs-only scope EXCLUDES runtime source (the load-bearing classification) ---
$docs = $cat.work_kinds | Where-Object { $_.id -eq 'docs-only' }
$runtimeInDocsScope = $false
foreach ($g in $docs.allowed_scope) { if (Test-SpecrewWorkKindGlob -Path 'extensions/specrew-speckit/scripts/work-kind-validator.ps1' -Pattern $g) { $runtimeInDocsScope = $true } }
Assert-True (-not $runtimeInDocsScope) 'T014: a runtime .ps1 is OUTSIDE docs-only allowed_scope (mismatch detectable)'
$mdInDocsScope = $false
foreach ($g in $docs.allowed_scope) { if (Test-SpecrewWorkKindGlob -Path 'docs/methodology/work-kinds.md' -Pattern $g) { $mdInDocsScope = $true } }
Assert-True $mdInDocsScope 'T014: a .md doc IS inside docs-only allowed_scope'

# --- global_allowlist exempts repository-global files ---
Assert-True (@($cat.global_allowlist).Count -ge 1) 'T014: catalog has a global_allowlist'
Assert-True (Test-SpecrewWorkKindAllowlisted -Path 'CHANGELOG.md' -Allowlist $cat.global_allowlist) 'T014: CHANGELOG.md is allow-listed'
Assert-True (-not (Test-SpecrewWorkKindAllowlisted -Path 'src/app.ps1' -Allowlist $cat.global_allowlist)) 'T014: a normal source file is NOT allow-listed'

# --- schemas are valid JSON + enum agrees with the catalog ---
Assert-True (Test-Path -LiteralPath $catalogSchemaPath) 'T014: work-kinds.schema.json exists'
$catSchema = Get-Content -LiteralPath $catalogSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-True ($null -ne $catSchema) 'T014: work-kinds.schema.json is valid JSON'
$enum = @($catSchema.'$defs'.workKindId.enum)
foreach ($e in $expected) { Assert-True ($enum -contains $e) "T014: schema enum includes '$e' (catalog<->schema agree)" }
Assert-True (Test-Path -LiteralPath $govSchemaPath) 'T014: repository-governance.schema.json exists'
$govSchema = Get-Content -LiteralPath $govSchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-True ($null -ne $govSchema) 'T014: repository-governance.schema.json is valid JSON'

# --- declaration reader: a minimal valid declaration parses; a bodyless one fails-open to null ---
$decl = ConvertFrom-SpecrewWorkKindDeclaration -Text "work_kind: devops`nschema_version: `"1.0`""
Assert-True ($decl.work_kind -eq 'devops') 'T014: declaration reader parses work_kind'
$bad = ConvertFrom-SpecrewWorkKindDeclaration -Text "schema_version: `"1.0`""
Assert-True ($null -eq $bad) 'T014: a declaration with no work_kind fails-open to $null (caller decides)'

Write-Host "`nAll T014 catalog + schema integrity assertions passed." -ForegroundColor Green
