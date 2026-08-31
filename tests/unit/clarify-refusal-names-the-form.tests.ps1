# Iteration 003 (DRIFT-199-I003-011): a content contract's refusal must name the form it accepts.
#
# FIELD CASE, Copilot walk, 2026-08-31. A hand-authored, semantically-correct zero-question Clarifications
# record was refused by the clarify boundary sync while `validate-governance` passed on the same tree. The
# refusal said only "spec.md required content" - naming neither the expected form nor the mismatch - so the
# agent recovered by running the validator and re-running the governed flow rather than by reading the
# message. The markers the contract actually enforces are regexes; a human cannot be asked to read them.
#
# The validator passing is NOT the DRIFT-199-I002-038 family (two readers with jointly unsatisfiable
# requirements). It is simpler and, for a reader, worse: `validate-governance.ps1` contains ZERO mentions of
# clarify, Clarifications or Clarify Disposition. It passed because it never looked, and "the validator
# passed" reads as "governance is satisfied".
#
# Mutations that turn this file red: drop AcceptedForms from the clarify contract; restore the bare
# "required content" entry; drop either accepted form from the text.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-ClarifyFixture {
    param([string]$SpecBody)
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("clarify-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = Join-Path $root 'specs/001-feat'
    New-Item -ItemType Directory -Force -Path $feature | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value $SpecBody -Encoding UTF8
    return $root
}

Write-Host 'Case 1: THE FIELD CASE - a hand-authored zero-question record is refused, and the refusal names the form'
$body1 = "# Feature Specification: Feat`n`n## Clarifications`n`nNo questions were needed.`n"
$r1 = New-ClarifyFixture -SpecBody $body1
$m1 = @((Test-SpecrewBoundaryOwedArtifactsOnDisk -ProjectRoot $r1 -Boundary 'clarify' -FromBoundary 'specify' -FeatureRef '001-feat' -IterationNumber '').Missing) -join ' '
Assert-True (-not [string]::IsNullOrWhiteSpace($m1)) 'the semantically-correct but unrecognised record is still refused - the contract is not weakened'
Assert-True ($m1 -notmatch '^spec\.md required content$') 'the refusal is no longer the bare "spec.md required content"'
Assert-True ($m1 -match '### Session') 'it names the dated Session-subheading form the governed flow writes'
Assert-True ($m1 -match 'Clarify Disposition') 'and the recorded-skip form'
Assert-True ($m1 -match 'at least 20 characters') 'including the constraint that is invisible in the regex - the reason length'
Assert-True ($m1 -match 'nothing you wrote is lost') 'and it tells the human their content is safe, per the refusal standard'

Write-Host 'Case 2: each accepted form actually satisfies the contract - the message is not describing a form that fails'
$body2 = "# Feature Specification: Feat`n`n## Clarifications`n`n### Session 2026-08-31`n`n- Q: scope? A: one feature.`n"
$r2 = New-ClarifyFixture -SpecBody $body2
Assert-True (@((Test-SpecrewBoundaryOwedArtifactsOnDisk -ProjectRoot $r2 -Boundary 'clarify' -FromBoundary 'specify' -FeatureRef '001-feat' -IterationNumber '').Missing).Count -eq 0) 'the dated Session form passes'
$body3 = "# Feature Specification: Feat`n`n- **Clarify Disposition**: skip - the spec has no ambiguous requirement worth a question`n"
$r3 = New-ClarifyFixture -SpecBody $body3
Assert-True (@((Test-SpecrewBoundaryOwedArtifactsOnDisk -ProjectRoot $r3 -Boundary 'clarify' -FromBoundary 'specify' -FeatureRef '001-feat' -IterationNumber '').Missing).Count -eq 0) 'the recorded-skip form passes'

Write-Host 'Case 3: the validator is SILENT on clarify - the reason the two readers disagreed'
# Pinned as a fact, not as a defect in the validator: a human reading "validate-governance passed" must not
# infer that the clarify boundary is satisfied, because that file never examines it.
$validator = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1') -Raw -Encoding UTF8
Assert-True ($validator -notmatch 'Clarify Disposition') 'validate-governance does not check the clarify skip-disposition form'
Assert-True ($validator -notmatch '## Clarifications') 'nor the Clarifications session form - it passes because it never looks'

foreach ($r in @($r1, $r2, $r3)) { try { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("clarify-refusal-names-the-form: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'clarify-refusal-names-the-form: all assertions passed' -ForegroundColor Green
