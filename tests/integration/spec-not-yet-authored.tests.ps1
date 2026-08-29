# Iteration 002, T020 (FR-029, SC-015): the specification does not exist before the workshop that decides it.
#
# CLAUDE.md states the rule: "A spec written before the workshop skips the part that decides what the spec
# should say." The scaffolding created exactly that artifact - the upstream create-new-feature copies
# spec-template to specs/<ref>/spec.md, Specrew initializes the workshop controller AFTERWARDS, and
# create-governed-feature then prints SPEC_FILE as a headline output, pointing the agent at a file full of
# `[Brief Title]` and `FR-001: System MUST [specific capability]` before lens 1 has run.
#
# Measured in one walk: the template sat in the tree through the whole workshop; writing into it mid-workshop
# was the outside work that triggered the lens re-ask; and at the end the agent did not edit it - it DELETED
# it (151 lines) and wrote a fresh 441-line spec. Delete-and-recreate is the measurement: the scaffolded file
# carried nothing into what replaced it. Its lint state then produced another boundary stop.
#
# Mutations that turn this file red: remove the stub replacement (case 1 - the placeholders return); remove
# the sentinel check from the specify gate (case 3 - the stub crosses specify); make the replacement
# unconditional (case 2 - an AUTHORED spec is destroyed, which would be far worse than the defect).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\design-analysis-gate.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$templateBody = @'
# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

## Requirements *(mandatory)*

- **FR-001: System MUST [specific capability]**
'@

function New-SpecFixture {
    param([string]$Body)
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("specstub-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = [System.IO.Path]::GetFullPath((Join-Path $root (Join-Path 'specs' '001-feat')))
    New-Item -ItemType Directory -Force -Path $feature | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $feature 'spec.md'), $Body, [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Root = $root; Feature = $feature; Spec = (Join-Path $feature 'spec.md') }
}

# The stub-writing block is the tail of create-governed-feature.ps1. Running the whole script needs the
# upstream scaffold and a git branch; this exercises the SAME block against a scaffolded spec.md, which is
# what the block itself operates on.
function Invoke-StubReplacement {
    param([string]$SpecFile)
    $source = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\create-governed-feature.ps1') -Raw -Encoding UTF8
    $startMarker = '$specStub = @('
    $endMarker = "        [System.IO.File]::WriteAllText(`$specFile, (`$specStub + [Environment]::NewLine), [System.Text.UTF8Encoding]::new(`$false))`n    }`n}`nelse {`n    [System.IO.File]::WriteAllText(`$specFile, (`$specStub + [Environment]::NewLine), [System.Text.UTF8Encoding]::new(`$false))`n}"
    $start = $source.IndexOf($startMarker)
    $end = $source.IndexOf($endMarker)
    if ($start -lt 0 -or $end -lt 0) { throw 'the stub block could not be located in create-governed-feature.ps1' }
    $block = $source.Substring($start, ($end - $start) + $endMarker.Length)
    $scriptText = "param([string]`$specFile, [string]`$featureRef)`n" + $block
    $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("stubblock-{0}.ps1" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
    [System.IO.File]::WriteAllText($temp, $scriptText, [System.Text.UTF8Encoding]::new($false))
    try { & pwsh -NoProfile -File $temp -specFile $SpecFile -featureRef '001-feat' | Out-Null }
    finally { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
}

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 1: the scaffolded TEMPLATE is replaced by a stub that says what it is'
$f1 = New-SpecFixture -Body $templateBody
Invoke-StubReplacement -SpecFile $f1.Spec
$stub = Get-Content -LiteralPath $f1.Spec -Raw -Encoding UTF8
Assert-True ($stub -match '<!--\s*specrew:spec-not-yet-authored\s*-->') 'the stub carries the sentinel the specify gate reads'
Assert-True ($stub -notmatch '\[Brief Title\]' -and $stub -notmatch 'FR-001: System MUST' -and $stub -notmatch '\[FEATURE NAME\]') 'no requirement placeholders remain to be written into mid-workshop'
Assert-True ($stub -match 'has not been written yet, and that is deliberate') 'it says plainly that this is intended, not a failure'
Assert-True ($stub -match 'Nothing is missing and nothing has failed') 'and reassures the reader'
Assert-True ($stub -match 'do not write' -and $stub -match 'do not delete it') 'and names what NOT to do - the two things the walk did'

Write-Host 'Case 2: an AUTHORED specification is never replaced'
$authored = "# Feature Specification: A Real Feature`n`n**Status**: Draft`n`n## Requirements`n`n- **FR-001**: The tracker records one person's reading.`n"
$f2 = New-SpecFixture -Body $authored
Invoke-StubReplacement -SpecFile $f2.Spec
$after2 = Get-Content -LiteralPath $f2.Spec -Raw -Encoding UTF8
Assert-True ($after2 -ceq $authored) 'a written specification is left byte-for-byte alone - the replacement is template-only, never a way to lose a spec'

Write-Host 'Case 3: the specify gate refuses while the sentinel stands, and says what to do'
$f3 = New-SpecFixture -Body $templateBody
Invoke-StubReplacement -SpecFile $f3.Spec
$refused = $false
$message = ''
try { Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $f3.Root -FeatureRef '001-feat' | Out-Null }
catch { $refused = $true; $message = [string]$_.Exception.Message }
Assert-True $refused 'the specify boundary is refused while the stub stands'
Assert-True ($message -match 'still the placeholder created with the feature') 'the refusal names what the file actually is'
Assert-True ($message -match 'workshop answers are safe') 'it says the human''s answers are safe - the sentence the walk''s refusals kept omitting'
Assert-True ($message -match 'Author the specification from the completed workshop') 'and names the one action'

Write-Host 'Case 4: once the specification is authored, the sentinel check lets it through'
$f4 = New-SpecFixture -Body $templateBody
Invoke-StubReplacement -SpecFile $f4.Spec
[System.IO.File]::WriteAllText($f4.Spec, $authored, [System.Text.UTF8Encoding]::new($false))
$stubRefusal = $false
try { Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $f4.Root -FeatureRef '001-feat' | Out-Null }
catch { $stubRefusal = ([string]$_.Exception.Message -match 'still the placeholder created with the feature') }
Assert-True (-not $stubRefusal) 'an authored specification is not refused by the stub check (other gates may still apply)'

foreach ($f in @($f1, $f2, $f3, $f4)) { try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("spec-not-yet-authored: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'spec-not-yet-authored: all assertions passed' -ForegroundColor Green
