[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 176 — Product & Problem Domain Lens unit tests (T006-T013, T015).
# House standalone style (matches lens-applicability-selector.tests.ps1): Assert-True + exit 1.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\product-domain-lens.ps1')
. (Join-Path $repoRoot 'scripts\internal\design-analysis-gate.ps1')

$catalogDir = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses'
$schemaSrc = Join-Path $repoRoot 'specs\176-product-domain-lens\contracts\product-domain.schema.json'

function New-TempFeature {
    param([string]$Name)
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("pdtest-" + $Name + "-" + [System.IO.Path]::GetRandomFileName())
    $featDir = Join-Path $root 'specs\999-demo'
    $null = New-Item -ItemType Directory -Path (Join-Path $featDir 'contracts') -Force
    # A substantive spec so the gate's substantive test fires.
    Set-Content -LiteralPath (Join-Path $featDir 'spec.md') -Value "# Spec`nThis feature touches lifecycle governance and architecture." -Encoding UTF8
    Copy-Item $schemaSrc (Join-Path $featDir 'contracts\product-domain.schema.json') -Force
    # Mirror the catalog so the gate sees product-domain registered.
    $catDest = Join-Path $root 'extensions\specrew-speckit\knowledge\design-lenses'
    $null = New-Item -ItemType Directory -Path $catDest -Force
    Copy-Item (Join-Path $catalogDir 'product-domain.md') (Join-Path $catDest 'product-domain.md') -Force
    return [pscustomobject]@{ Root = $root; FeatureDir = $featDir }
}

function New-ValidRecord {
    param([string]$Depth = 'standard', [string]$Confirmation = 'human-confirmed', [string]$Scope = 'lens-question', [string]$ContextScope = 'feature_standalone', $Statements = $null)
    $st = if ($null -ne $Statements) { $Statements } else {
        @(
            [ordered]@{ text = 'direct users are developers'; area = 'users_stakeholders'; evidence = 'known' },
            [ordered]@{ text = 'adoption rate is unverified'; area = 'outcomes'; evidence = 'research-needed'; load_bearing = $false }
        )
    }
    return [ordered]@{
        schema_version = '1.0'; depth = $Depth; depth_reason = 'normal feature'; context_scope = $ContextScope
        product_id = $null; product_context_ref = $null
        areas = [ordered]@{ users_stakeholders = 'devs'; pain_job = 'manual today'; mvp = 'first slice'; out_of_scope = 'not a suite'; constraints = 'reuse machinery' }
        statements = $st
        skipped = @([ordered]@{ area = 'alternatives'; reason = 'light' })
        follow_up_research = @('confirm adoption')
        confirmation = $Confirmation; confirmation_scope = $Scope
    }
}

# --- T006 / SC-001: product-domain runs BEFORE the applicability questionnaire (first-stage) ---
$indexRaw = Get-Content -LiteralPath (Join-Path $catalogDir 'index.yml') -Raw -Encoding UTF8
Assert-True ($indexRaw -match '(?im)^\s*- id:\s*product-domain\s*$') 'T006: product-domain is registered in the lens catalog index.yml'
Assert-True ($indexRaw -match '(?im)default_phase:\s*intake-product-domain') 'T006: product-domain carries the first-stage default_phase intake-product-domain'
$mapRaw = Get-Content -LiteralPath (Join-Path $catalogDir 'applicability-map.json') -Raw -Encoding UTF8
Assert-True ($mapRaw -notmatch 'product-domain') 'T006/SC-001: product-domain is NOT in the question-gated applicability-map (it runs FIRST, before the questionnaire)'

# --- T007 / SC-002: adaptive depth Light / Standard / Deep ---
Assert-True ((Get-SpecrewProductDomainDepth -Risk 'high' -Novelty 'new-product') -eq 'deep') 'T007: new-product/high-risk -> deep'
Assert-True ((Get-SpecrewProductDomainDepth -Risk 'low' -Novelty 'tiny bugfix') -eq 'light') 'T007: tiny bugfix -> light'
Assert-True ((Get-SpecrewProductDomainDepth -Risk 'moderate' -Novelty 'normal feature') -eq 'standard') 'T007: a normal feature (no light/deep signal) -> standard'
Assert-True ((Get-SpecrewProductDomainDepth -Risk 'low' -Novelty 'incremental, known product') -eq 'light') 'T007: later feature in a known product -> light'
Assert-True ((Get-SpecrewProductDomainDepth -Risk '' -Novelty '') -eq 'standard') 'T007: ambiguous -> standard (safe middle, never silently light)'

# --- T009 / SC-004: dual-artifact persistence (both .yml and .md) ---
$t9 = New-TempFeature 't9'
$ymlPath = New-SpecrewProductDomainRecord -FeatureDir $t9.FeatureDir -Record (New-ValidRecord) -Force
$mdPath = Join-Path $t9.FeatureDir 'workshop\product-domain.md'
Assert-True (Test-Path -LiteralPath $ymlPath -PathType Leaf) 'T009: product-domain.yml is persisted'
Assert-True (Test-Path -LiteralPath $mdPath -PathType Leaf) 'T009: product-domain.md is persisted'
# Idempotent re-write with -Force yields an equivalent file.
$first = Get-Content -LiteralPath $ymlPath -Raw -Encoding UTF8
$null = New-SpecrewProductDomainRecord -FeatureDir $t9.FeatureDir -Record (New-ValidRecord) -Force
Assert-True ((Get-Content -LiteralPath $ymlPath -Raw -Encoding UTF8) -eq $first) 'T009: record write is idempotent (same inputs -> equivalent file)'

# --- T008 / SC-003 / SC-006: evidence tags + conditional research-needed blocking ---
$schemaPath = Join-Path $t9.FeatureDir 'contracts\product-domain.schema.json'
Assert-True ((@(Test-SpecrewProductDomainRecord -Path $ymlPath -SchemaPath $schemaPath)).Count -eq 0) 'T008: a valid evidence-tagged record passes validation'

# untagged/empty statement fails
$bad = New-ValidRecord -Statements @([ordered]@{ text = ''; area = 'users_stakeholders'; evidence = 'known' })
$badYml = New-SpecrewProductDomainRecord -FeatureDir (New-TempFeature 't8a').FeatureDir -Record $bad -Force
Assert-True ((@(Test-SpecrewProductDomainRecord -Path $badYml -SchemaPath $schemaPath)).Count -gt 0) 'T008: an empty/untagged material statement fails validation'

# invalid evidence tag fails
$bad2 = New-ValidRecord -Statements @([ordered]@{ text = 'x'; area = 'users_stakeholders'; evidence = 'made-up' })
$bad2Yml = New-SpecrewProductDomainRecord -FeatureDir (New-TempFeature 't8b').FeatureDir -Record $bad2 -Force
Assert-True ((@(Test-SpecrewProductDomainRecord -Path $bad2Yml -SchemaPath $schemaPath)).Count -gt 0) 'T008: an invalid evidence tag fails validation'

# load-bearing research-needed blocks the plan boundary; non-load-bearing does not
$lbYml = New-SpecrewProductDomainRecord -FeatureDir (New-TempFeature 't8c').FeatureDir -Record (New-ValidRecord -Statements @([ordered]@{ text = 'feasibility unknown'; area = 'constraints'; evidence = 'research-needed'; load_bearing = $true })) -Force
Assert-True ((@(Test-SpecrewProductDomainResearchBlock -Path $lbYml)).Count -eq 1) 'T008/SC-006: a load-bearing research-needed statement blocks the plan boundary'
$nlbYml = New-SpecrewProductDomainRecord -FeatureDir (New-TempFeature 't8d').FeatureDir -Record (New-ValidRecord -Statements @([ordered]@{ text = 'minor unknown'; area = 'constraints'; evidence = 'research-needed'; load_bearing = $false })) -Force
Assert-True ((@(Test-SpecrewProductDomainResearchBlock -Path $nlbYml)).Count -eq 0) 'T008/SC-006: a non-load-bearing research-needed statement does NOT block (recorded + carried)'

# --- T011 / SC-005: batch "confirm all" cannot satisfy product-domain confirmation (FR-009) ---
$batch = New-ValidRecord -Confirmation 'human-confirmed' -Scope 'batch-approval'
$batchYml = New-SpecrewProductDomainRecord -FeatureDir (New-TempFeature 't11').FeatureDir -Record $batch -Force
$batchErrs = @(Test-SpecrewProductDomainRecord -Path $batchYml -SchemaPath $schemaPath)
Assert-True ($batchErrs.Count -gt 0 -and ($batchErrs -join ' ') -match 'confirmation_scope') 'T011/FR-009: a batch confirmation_scope is rejected (lens approval is not product-domain confirmation)'
$delegated = New-ValidRecord -Confirmation 'human-delegated' -Scope 'explicit-delegation'
$delYml = New-SpecrewProductDomainRecord -FeatureDir (New-TempFeature 't11b').FeatureDir -Record $delegated -Force
Assert-True ((@(Test-SpecrewProductDomainRecord -Path $delYml -SchemaPath $schemaPath)).Count -eq 0) 'T011: an honest human-delegated/explicit-delegation record is accepted'

# --- T013 / SC-008 / SC-009: schema hooks (product_id / product_context_ref / context_scope) ---
$rt = ConvertFrom-SpecrewProductDomainYaml -Text (Get-Content -LiteralPath $ymlPath -Raw -Encoding UTF8)
Assert-True ($rt.Contains('product_id') -and $rt.Contains('product_context_ref') -and $rt.Contains('context_scope')) 'T013: the record carries the product_id / product_context_ref / context_scope hooks'
Assert-True ([string]$rt['context_scope'] -eq 'feature_standalone') 'T013/SC-009: V1 writes context_scope=feature_standalone'
$badScope = New-ValidRecord -ContextScope 'made_up_scope'
$badScopeYml = New-SpecrewProductDomainRecord -FeatureDir (New-TempFeature 't13').FeatureDir -Record $badScope -Force
Assert-True ((@(Test-SpecrewProductDomainRecord -Path $badScopeYml -SchemaPath $schemaPath)).Count -gt 0) 'T013/SC-009: an invalid context_scope is rejected (enum-constrained)'

# --- T015: graceful degradation — no silent skip ---
# (a) Catalog present + substantive feature + record MISSING -> the gate FAILS CLOSED (loud), not silent.
$t15 = New-TempFeature 't15'
$threw = $false
try { $null = Test-SpecrewProductDomainGate -ProjectRoot $t15.Root -FeatureRef '999-demo' } catch { $threw = $true; $msg = $_.Exception.Message }
Assert-True ($threw -and $msg -match 'MISSING') 'T015: an absent product-domain record on a substantive feature FAILS the gate CLOSED (no silent skip)'

# (b) Catalog ABSENT -> graceful skip ($null), the lens does not apply in a project without it.
$noCatRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("pdtest-nocat-" + [System.IO.Path]::GetRandomFileName())
$null = New-Item -ItemType Directory -Path (Join-Path $noCatRoot 'specs\999-demo') -Force
Set-Content -LiteralPath (Join-Path $noCatRoot 'specs\999-demo\spec.md') -Value "# Spec`nlifecycle governance architecture." -Encoding UTF8
Assert-True ($null -eq (Test-SpecrewProductDomainGate -ProjectRoot $noCatRoot -FeatureRef '999-demo')) 'T015: with the lens catalog absent, the gate gracefully skips (downstream project without the lens)'

# (c) Catalog present + valid record -> gate passes.
$null = New-SpecrewProductDomainRecord -FeatureDir $t15.FeatureDir -Record (New-ValidRecord) -Force
$gateOk = Test-SpecrewProductDomainGate -ProjectRoot $t15.Root -FeatureRef '999-demo'
Assert-True ($null -ne $gateOk -and $gateOk.Valid) 'T015: a present + valid record passes the gate'

Write-Host "`nAll product-domain lens unit tests passed." -ForegroundColor Green
