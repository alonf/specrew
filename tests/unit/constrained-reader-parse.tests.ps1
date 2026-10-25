# Iteration 002, T017 (FR-026, SC-013): a document that matches no construct is UNPARSEABLE, and the refusal
# names the representation instead of the fields.
#
# Field case (the WinUI walk): product-domain.yml - written by the product-domain LENS itself, the first
# artifact of the workshop - contained JSON. The constrained reader matched no line and returned an
# initialized-but-empty record, so every field backstop fired at once:
#     depth must be one of ... (got '')
#     confirmation must be one of human-confirmed | human-delegated | human-skipped (got '');
#     a batch 'confirm all' is NOT valid provenance.
# Both named fields WERE present, correctly filled, human-confirmed. The message described missing
# provenance and invited the reader to conclude the human's confirmation had been lost or improperly
# batched; the agent resolved it only by opening the schema. The backstops are a robustness net for a
# MISSING schema - they were never meant to be the primary error surface.
#
# The right shape already existed one file over (code-implementation's 'could not be parsed'), but it fired
# only when the converter returned $null, which a JSON document did not - so the sibling carried the same
# hole and is fixed here too.
#
# Mutations that turn this file red: remove the recognized-line count from either reader (cases 1, 3 - the
# backstops return); revert either validator's message to the bare 'could not be parsed' (2, 3).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\product-domain-lens.ps1')
. (Join-Path $repoRoot 'scripts\internal\code-implementation-lens.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

# The walk's actual artifact shape: a VALID, human-confirmed record - written as JSON.
$jsonRecord = @'
{
  "depth": "standard",
  "depth_reason": "a first feature on a new stack",
  "context_scope": "feature",
  "confirmation": "human-confirmed",
  "confirmation_scope": "product-domain",
  "statements": [
    { "text": "The app helps one person track their own reading.", "evidence": "human-stated" }
  ]
}
'@
$yamlRecord = @'
depth: standard
depth_reason: a first feature on a new stack
context_scope: feature
confirmation: human-confirmed
confirmation_scope: product-domain
statements:
  - text: The app helps one person track their own reading.
    evidence: human-stated
'@

Write-Host 'Case 1: the JSON-shaped product-domain record reads as UNPARSEABLE, not as an empty record'
$parsed = ConvertFrom-SpecrewProductDomainYaml -Text $jsonRecord
Assert-True ($null -eq $parsed) 'the reader returns $null for a non-empty document that matches none of its constructs'
$parsedYaml = ConvertFrom-SpecrewProductDomainYaml -Text $yamlRecord
Assert-True ($null -ne $parsedYaml -and [string]$parsedYaml['depth'] -eq 'standard' -and [string]$parsedYaml['confirmation'] -eq 'human-confirmed') 'and the SAME record in constrained YAML still parses, with its fields intact'

Write-Host 'Case 2: the refusal names the representation, keeps the answers, and names one action'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("pdlens-{0}.yml" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
[System.IO.File]::WriteAllText($tmp, $jsonRecord, [System.Text.UTF8Encoding]::new($false))
$errors = @(Test-SpecrewProductDomainRecord -Path $tmp -SchemaPath $null)
Assert-True ($errors.Count -eq 1) 'exactly ONE error is reported - not a wall of field backstops'
$only = [string]$errors[0]
Assert-True ($only -match 'could not be parsed' -and $only -match 'reads as JSON') 'it names the parse failure AND the representation found'
Assert-True ($only -match 'not lost and nothing was mis-confirmed') 'it says the recorded answers are intact - the sentence whose absence sent the walk to the schema'
Assert-True ($only -match 'Re-write it as the YAML product-domain\.schema\.json describes') 'it names one reachable action'
Assert-True ($only -notmatch 'depth must be one of' -and $only -notmatch 'confirmation must be one of') 'and NO field backstop fires on an unparsed record'
Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue

Write-Host 'Case 3: the sibling reader (implementation-rules) has the same behaviour - the hole is closed in both'
$jsonManifest = @'
{
  "context_scope": "feature",
  "resolved_stack": "dotnet",
  "selections": [ { "id": "di-stable-services-only" } ],
  "provenance": { "confirmation": "human-confirmed", "confirmation_scope": "code-implementation" }
}
'@
Assert-True ($null -eq (ConvertFrom-SpecrewImplementationRulesYaml -Text $jsonManifest)) 'the implementation-rules reader also returns $null for a JSON document'
$tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ("cilens-{0}.yml" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
[System.IO.File]::WriteAllText($tmp2, $jsonManifest, [System.Text.UTF8Encoding]::new($false))
$errors2 = @(Test-SpecrewImplementationRulesManifest -Path $tmp2 -SchemaPath $null -CatalogPath $null -OverlayPath $null)
Assert-True ($errors2.Count -eq 1 -and ([string]$errors2[0]) -match 'reads as JSON' -and ([string]$errors2[0]) -match 'not lost and nothing was mis-confirmed') 'and its validator gives the same one-line refusal, naming the representation'
Assert-True (([string]$errors2[0]) -notmatch 'context_scope must be one of' -and ([string]$errors2[0]) -notmatch 'resolved_stack is required') 'with no field backstops on an unparsed manifest'
Remove-Item -LiteralPath $tmp2 -Force -ErrorAction SilentlyContinue

Write-Host 'Case 4: a genuinely EMPTY record still reports missing, and a valid record still validates'
$tmp3 = Join-Path ([System.IO.Path]::GetTempPath()) ("pdlens-{0}.yml" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
[System.IO.File]::WriteAllText($tmp3, $yamlRecord, [System.Text.UTF8Encoding]::new($false))
$errors3 = @(Test-SpecrewProductDomainRecord -Path $tmp3 -SchemaPath $null)
Assert-True (@($errors3 | Where-Object { $_ -match 'could not be parsed' }).Count -eq 0) 'a well-formed constrained-YAML record does not report a parse failure'
Remove-Item -LiteralPath $tmp3 -Force -ErrorAction SilentlyContinue
$missing = @(Test-SpecrewProductDomainRecord -Path (Join-Path ([System.IO.Path]::GetTempPath()) 'does-not-exist-pdlens.yml') -SchemaPath $null)
Assert-True ($missing.Count -eq 1 -and ([string]$missing[0]) -match 'is missing') 'a MISSING record still reports missing - the graceful path is unchanged'

Write-Host 'Case 5: other representations are named too, and the trigger is not JSON-only'
Assert-True ((Get-SpecrewConstrainedYamlRepresentation -Text "<root/>") -eq 'XML or HTML') 'an XML document is named as XML or HTML'
Assert-True ((Get-SpecrewConstrainedYamlRepresentation -Text $yamlRecord) -eq 'not the constrained YAML this record uses') 'constrained YAML itself is not mislabelled'
$prose = "This file was written by hand and never followed the schema at all."
$proseMsg = Get-SpecrewConstrainedYamlParseFailureMessage -FileName 'product-domain.yml' -Text $prose -SchemaName 'product-domain.schema.json'
Assert-True ($proseMsg -match 'no line in it matches the constrained YAML' -and $proseMsg -notmatch 'reads as') 'free prose gets the plain no-construct-matched reason, with no invented representation'

if ($script:failCount -gt 0) { throw ("constrained-reader-parse: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'constrained-reader-parse: all assertions passed' -ForegroundColor Green
