[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 177 (code-implementation lens) iteration 001 unit tests:
#   T007 catalog integrity, T008 manifest schema + overlay, T009 registration.
# Pure unit tests against the shipped catalog/schema + the writer/validator.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\code-implementation-lens.ps1')

$catalogDir = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses'
$catalogPath = Join-Path $catalogDir 'code-rules.yml'
$schemaPath = Join-Path $catalogDir 'implementation-rules.schema.json'
$lensMdPath = Join-Path $catalogDir 'code-implementation.md'
$indexPath = Join-Path $catalogDir 'index.yml'
$mapPath = Join-Path $catalogDir 'applicability-map.json'

# ---------------------------------------------------------------------------
# T007 — catalog integrity (FR-002, SC-005)
# ---------------------------------------------------------------------------
Assert-True (Test-Path -LiteralPath $catalogPath) 'T007: code-rules.yml catalog exists'
$catalogRaw = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8
$ids = @(Get-SpecrewCodeRuleIds -Path $catalogPath)
Assert-True ($ids.Count -ge 50) "T007: catalog has a substantial rule set (got $($ids.Count) ids, expect >= 50)"
$uniq = @($ids | Sort-Object -Unique)
Assert-True ($uniq.Count -eq $ids.Count) "T007: catalog rule ids are unique (no duplicates) ($($ids.Count) ids, $($uniq.Count) unique)"

# The 3 F-177 additions are present.
foreach ($add in @('code-rule.solid-baseline', 'code-rule.strategy-state-over-repeated-conditionals', 'code-rule.polymorphism-mechanism')) {
    Assert-True ($ids -contains $add) "T007: F-177 addition present: $add"
}
# Stable maintainer-baseline anchors are present.
foreach ($base in @('code-rule.intent-revealing-names', 'code-rule.dependency-injection', 'code-rule.object-invariants', 'code-rule.no-magic-numbers')) {
    Assert-True ($ids -contains $base) "T007: maintainer baseline rule present: $base"
}
# Grouping vocabulary present.
foreach ($grp in @('baseline-default', 'decision-prompt', 'applicability-filtered')) {
    Assert-True ($catalogRaw -match [regex]::Escape("group: $grp")) "T007: catalog uses the '$grp' group"
}
# Per-stack (language-scoped) rules present for the 6 researched stacks.
foreach ($stack in @('csharp-dotnet', 'c-cpp', 'typescript-javascript', 'python', 'go', 'java')) {
    Assert-True ($catalogRaw -match [regex]::Escape("language:$stack")) "T007: per-stack rule present for language:$stack"
}
# Cross-language scope + enforcement_mode present.
Assert-True ($catalogRaw -match 'scope:\s*cross-language') 'T007: cross-language scope present'
Assert-True ($catalogRaw -match 'enforcement_mode:') 'T007: enforcement_mode metadata present (informational)'

# ---------------------------------------------------------------------------
# T008 — manifest schema + overlay (FR-004, FR-012, FR-013, SC-002)
# ---------------------------------------------------------------------------
Assert-True (Test-Path -LiteralPath $schemaPath) 'T008: implementation-rules.schema.json exists'

function New-TempManifestDir {
    $d = Join-Path ([System.IO.Path]::GetTempPath()) ("f177-ci-{0}" -f ([System.Guid]::NewGuid().ToString('N')))
    New-Item -ItemType Directory -Path $d -Force | Out-Null
    return $d
}

# Round-trip: emit -> read -> fields preserved (including nested dependency_policy,
# reviewer_preference, and enforcement list).
$manifest = [ordered]@{
    schema_version = '1.0'; context_scope = 'feature_standalone'; resolved_stack = 'csharp-dotnet'; product_id = $null; product_context_ref = $null
    selections     = @(
        [ordered]@{ id = 'code-rule.intent-revealing-names'; checked = $true },
        [ordered]@{ id = 'code-rule.copy-semantics'; checked = $true; decision = 'DTO projection across services'; enforcement = @('plan', 'review') }
    )
    custom_rules   = @( [ordered]@{ id = 'custom.no-static-singletons'; text = 'No static singletons'; provenance = 'from-example-project' } )
    dependency_policy = [ordered]@{ stance = 'approved-new-dependencies'; selected = @( [ordered]@{ name = 'Polly'; version = '8.x'; license = 'BSD-3-Clause'; coupling_weight = 'low'; replaceability = 'high' } ) }
    reviewer_preference = [ordered]@{
        mode = 'human-selected'
        host = 'codex'
        model = 'chatgpt'
        effort = 'max'
        source = 'code-implementation-workshop'
        authorization_ref = 'decision-2026-06-20-reviewer'
        rationale = 'Code author was Claude, so Codex gives an independent strong review.'
    }
    provenance     = [ordered]@{ confirmation = 'human-confirmed'; confirmation_scope = 'lens-question' }
}
$yaml = ConvertTo-SpecrewImplementationRulesYaml -Manifest $manifest
$back = ConvertFrom-SpecrewImplementationRulesYaml -Text $yaml
Assert-True (@($back.selections).Count -eq 2) 'T008: round-trip preserves selections'
Assert-True ((@($back.selections[1].enforcement) -join '+') -eq 'plan+review') 'T008: round-trip preserves the enforcement inline list'
Assert-True (@($back.dependency_policy.selected).Count -eq 1 -and $back.dependency_policy.selected[0].name -eq 'Polly') 'T008: round-trip preserves dependency_policy.selected'
Assert-True ($back.reviewer_preference.host -eq 'codex' -and $back.reviewer_preference.model -eq 'chatgpt' -and $back.reviewer_preference.effort -eq 'max') 'T008: round-trip preserves reviewer_preference host/model/effort'
Assert-True ($back.reviewer_preference.source -eq 'code-implementation-workshop' -and $back.reviewer_preference.authorization_ref -eq 'decision-2026-06-20-reviewer') 'T008: round-trip preserves reviewer_preference source/authorization'
Assert-True ($back.custom_rules[0].provenance -eq 'from-example-project') 'T008: round-trip preserves from-example-project provenance'

# Regression (F-177 deployed-module dogfood): a SINGLE-element enforcement list must round-trip as an
# array AND survive the JSON projection as an array, not a scalar string. The original round-trip above
# only used a two-element list, so the single-element function-return unwrap slipped past unit-green and
# surfaced only on the deployed-module dogfood. The leading-comma idiom in ConvertFrom-SpecrewCodeInlineList
# guards it.
$single = [ordered]@{
    schema_version = '1.0'; context_scope = 'feature_standalone'; resolved_stack = 'csharp-dotnet'
    selections     = @( [ordered]@{ id = 'code-rule.idiomatic-error-handling'; checked = $true; enforcement = @('review') } )
    custom_rules   = @(); provenance = [ordered]@{ confirmation = 'human-confirmed'; confirmation_scope = 'lens-question' }
}
$sd = New-TempManifestDir
try {
    New-SpecrewImplementationRulesManifest -FeatureDir $sd -Manifest $single | Out-Null
    $sback = ConvertFrom-SpecrewImplementationRulesYaml -Text (Get-Content -LiteralPath (Join-Path $sd 'implementation-rules.yml') -Raw)
    Assert-True (@($sback.selections[0].enforcement).Count -eq 1 -and $sback.selections[0].enforcement[0] -eq 'review') 'T008 regression: single-element enforcement round-trips as a 1-item array'
    $errs = @(Test-SpecrewImplementationRulesManifest -Path (Join-Path $sd 'implementation-rules.yml') -SchemaPath $schemaPath -CatalogPath $catalogPath)
    Assert-True ($errs.Count -eq 0) "T008 regression: single-element enforcement passes schema validation (errors: $($errs -join '; '))"
}
finally { Remove-Item -LiteralPath $sd -Recurse -Force -ErrorAction SilentlyContinue }

# Positive validation: a valid manifest against the schema + catalog -> 0 errors.
$pd = New-TempManifestDir
try {
    New-SpecrewImplementationRulesManifest -FeatureDir $pd -Manifest $manifest | Out-Null
    Assert-True (Test-Path -LiteralPath (Join-Path $pd 'implementation-rules.yml')) 'T008: writer persists implementation-rules.yml'
    Assert-True (Test-Path -LiteralPath (Join-Path $pd 'workshop\code-implementation.md')) 'T008: writer persists the human-readable record'
    $recordRaw = Get-Content -LiteralPath (Join-Path $pd 'workshop\code-implementation.md') -Raw -Encoding UTF8
    Assert-True ($recordRaw -match 'Continuous co-review preference' -and $recordRaw -match 'Codex|codex') 'T008: human-readable record includes reviewer preference'
    $errs = @(Test-SpecrewImplementationRulesManifest -Path (Join-Path $pd 'implementation-rules.yml') -SchemaPath $schemaPath -CatalogPath $catalogPath)
    Assert-True ($errs.Count -eq 0) "T008: a valid manifest passes validation (errors: $($errs -join '; '))"
}
finally { Remove-Item -LiteralPath $pd -Recurse -Force -ErrorAction SilentlyContinue }

# Negative: unknown selection id -> failure (not in catalog/overlay/custom set).
$nd = New-TempManifestDir
try {
    $bad = [ordered]@{ schema_version = '1.0'; context_scope = 'feature_standalone'; resolved_stack = 'go'; selections = @([ordered]@{ id = 'code-rule.DOES-NOT-EXIST'; checked = $true }); custom_rules = @(); provenance = [ordered]@{ confirmation = 'human-confirmed'; confirmation_scope = 'lens-question' } }
    New-SpecrewImplementationRulesManifest -FeatureDir $nd -Manifest $bad | Out-Null
    $errs = @(Test-SpecrewImplementationRulesManifest -Path (Join-Path $nd 'implementation-rules.yml') -SchemaPath $schemaPath -CatalogPath $catalogPath)
    Assert-True ($errs.Count -ge 1 -and ($errs -join ' ') -match 'unknown rule id') 'T008: an unknown selection id fails validation'
}
finally { Remove-Item -LiteralPath $nd -Recurse -Force -ErrorAction SilentlyContinue }

# Negative: a human-selected reviewer preference must name the host.
$rd = New-TempManifestDir
try {
    $badReviewer = [ordered]@{
        schema_version = '1.0'; context_scope = 'feature_standalone'; resolved_stack = 'go'
        selections = @(); custom_rules = @()
        reviewer_preference = [ordered]@{ mode = 'human-selected'; source = 'code-implementation-workshop'; model = 'chatgpt' }
        provenance = [ordered]@{ confirmation = 'human-confirmed'; confirmation_scope = 'lens-question' }
    }
    New-SpecrewImplementationRulesManifest -FeatureDir $rd -Manifest $badReviewer | Out-Null
    $errs = @(Test-SpecrewImplementationRulesManifest -Path (Join-Path $rd 'implementation-rules.yml') -SchemaPath $schemaPath -CatalogPath $catalogPath)
    Assert-True (($errs -join ' ') -match 'reviewer_preference.host is required') 'T008: a human-selected reviewer without a host fails validation'
}
finally { Remove-Item -LiteralPath $rd -Recurse -Force -ErrorAction SilentlyContinue }

# Negative: bad provenance pairing -> failure.
$pp = New-TempManifestDir
try {
    $badp = [ordered]@{ schema_version = '1.0'; context_scope = 'feature_standalone'; resolved_stack = 'go'; selections = @(); custom_rules = @(); provenance = [ordered]@{ confirmation = 'human-confirmed'; confirmation_scope = 'explicit-skip' } }
    New-SpecrewImplementationRulesManifest -FeatureDir $pp -Manifest $badp | Out-Null
    $errs = @(Test-SpecrewImplementationRulesManifest -Path (Join-Path $pp 'implementation-rules.yml') -SchemaPath $schemaPath -CatalogPath $catalogPath)
    Assert-True (($errs -join ' ') -match 'confirmation_scope must be') 'T008: a mismatched confirmation/confirmation_scope fails (batch approval is not lens-question)'
}
finally { Remove-Item -LiteralPath $pp -Recurse -Force -ErrorAction SilentlyContinue }

# Overlay merge (FR-012): additive + override, NEVER drops a shipped id.
$ov = Join-Path ([System.IO.Path]::GetTempPath()) ("f177-ov-{0}.yml" -f ([System.Guid]::NewGuid().ToString('N')))
try {
    Set-Content -LiteralPath $ov -Encoding UTF8 -Value @"
schema_version: "1.0"
added_rules:
  - id: org.no-print-debugging
    group: baseline-default
overrides:
  - id: code-rule.intent-revealing-names
"@
    $merge = Merge-SpecrewCodeRuleCatalog -CatalogPath $catalogPath -OverlayPath $ov
    Assert-True (@($merge.dropped).Count -eq 0) 'T008: overlay merge never drops a shipped rule'
    Assert-True (@($merge.added) -contains 'org.no-print-debugging') 'T008: overlay merge adds a new overlay rule'
    Assert-True (@($merge.merged) -contains 'code-rule.intent-revealing-names') 'T008: overlay merge retains an overridden shipped rule'
    Assert-True (@($merge.merged).Count -ge ($ids.Count)) 'T008: merged set is at least the shipped set (additive)'
}
finally { Remove-Item -LiteralPath $ov -Force -ErrorAction SilentlyContinue }

# ---------------------------------------------------------------------------
# T009 — registration (FR-001, SC-001)
# ---------------------------------------------------------------------------
Assert-True (Test-Path -LiteralPath $lensMdPath) 'T009: code-implementation.md lens md exists'
$indexRaw = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
Assert-True ($indexRaw -match '(?m)^\s*-\s*id:\s*code-implementation\s*$') 'T009: index.yml registers the code-implementation lens id'
Assert-True ($indexRaw -match 'file:\s*code-implementation\.md') 'T009: index.yml points the lens at code-implementation.md'
# The lens md carries the required schema sections.
$lensRaw = Get-Content -LiteralPath $lensMdPath -Raw -Encoding UTF8
foreach ($h in @('## Design Decision Points', '## Workshop Conduct', '## Run Cadence', '## Artifacts')) {
    Assert-True ($lensRaw -match [regex]::Escape($h)) "T009: lens md has the '$h' section"
}
# Conduct-driven (drift D-001): the lens is NOT in the deterministic applicability-map.
$mapRaw = Get-Content -LiteralPath $mapPath -Raw -Encoding UTF8
Assert-True ($mapRaw -notmatch 'code-implementation') 'T009: code-implementation is NOT in the deterministic applicability-map (conduct-driven, drift D-001)'

Write-Host ''
Write-Host 'All code-implementation-lens (F-177 i1) unit tests passed.' -ForegroundColor Green
exit 0
