# Iteration 002, T018 (FR-027, SC-013, SC-014): the governed lens-checkpoint writer.
#
# F-1, measured on the WinUI walk: the human confirms a lens, the agent writes the artifacts, and the
# controller stays on the same phase because NOTHING runs the transition. `moved_on` was the agent
# hand-editing lens-applicability.json per skill instruction; later, outside work plus an open topic
# re-asks a lens the human already answered - which reads to a newcomer as "the system lost my answer".
# Roughly nine of those per full workshop, and it is the friction a first-time user meets before they have
# any reason to trust the tool.
#
# B-6 rides with it, scoped as ruled: the lens's ALREADY-EXISTING validator runs at its own checkpoint,
# with the human still in the room, instead of at the specify boundary in reverse order of creation. No new
# validators; the boundary gate keeps its calls as defense in depth.
#
# Mutations that turn this file red (added 2026-08-29, from the covering round's `workshop-receipt-contract`
# finding): write the receipt as `turn_receipt` again (cases 2, 2b, 2c - the canonical reader rejects it and
# the workshop stops advancing); derive confirmation_scope from a table in the writer instead of persisting
# the receipt's own (case 2c); drop `human_turn_contract` from the fixture (the reader's receipt check
# switches off and cases 2b/2c go green against a defect, which is exactly how the original bug survived).
# Mutations that turn this file red: remove the controller write (case 2 - the lens never advances, F-1
# returns); remove the receipt check (3); remove the record check (4); remove the validator call (5 - a
# JSON-shaped product-domain record closes the lens and the boundary finds it lenses later).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\workshop-authority-store.ps1')
. (Join-Path $repoRoot 'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1')
$writer = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\confirm-workshop-lens.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-WorkshopFixture {
    param([string[]]$Selected = @('architecture-core', 'ui-ux'), [switch]$SkipRecord)
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("lenscp-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = [System.IO.Path]::GetFullPath((Join-Path $root (Join-Path 'specs' '001-feat')))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $feature 'workshop') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat" -Encoding UTF8
    if (-not $SkipRecord) {
        foreach ($lens in $Selected) {
            Set-Content -LiteralPath (Join-Path $feature (Join-Path 'workshop' ($lens + '.md'))) -Value ("# {0}`n`nWhat we agreed, in the human's words." -f $lens) -Encoding UTF8
        }
    }
    $agenda = [ordered]@{}
    foreach ($lens in $Selected) { $agenda[$lens] = @(('An open question for {0}?' -f $lens)) }
    $controller = [ordered]@{
        schema_version        = '1.1'
        workshop_intake       = $true
        confirmation_required = $true
        agenda_status         = 'confirmed'
        selected              = @($Selected)
        agenda                = $agenda
        skipped               = [ordered]@{}
        agenda_confirmation   = 'human-confirmed'
        human_turn_contract   = 'typed-turns-v1'
        workshop              = [ordered]@{}
    }
    [System.IO.File]::WriteAllText((Join-Path $feature 'lens-applicability.json'), ($controller | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Root = $root; Feature = $feature; Controller = (Join-Path $feature 'lens-applicability.json') }
}
function Write-LensReceipt {
    # The typed-turn receipt the prompt-submit hook mints when the human answers a lens question.
    param([string]$Root, [string]$Lens, [string]$Confirmation = 'human-confirmed', [string]$Scope = 'lens-question')
    $path = Join-Path $Root '.specrew/runtime/workshop-authority.jsonl'
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    $record = [ordered]@{
        schema_version = '1'; receipt_id = ('receipt-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
        feature_ref = '001-feat'; iteration_number = ''; phase = 'lens'; lens = $Lens
        question_hash = 'q'; response_hash = 'r'; confirmation = $Confirmation; confirmation_scope = $Scope
        source_event = 'UserPromptSubmit'; host_kind = 'claude'; recorded_at = '2026-08-29T00:00:00Z'
    }
    ($record | ConvertTo-Json -Compress) | Add-Content -LiteralPath $path -Encoding UTF8
    return [string]$record.receipt_id
}
function Read-Controller { param([string]$Path) return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json) }
function Invoke-Writer {
    param([string]$Root, [string]$Lens, [string[]]$Agenda = @('An open question?'), [string]$Decision = 'We agreed to keep the existing layering.', [string]$Depth = 'medium', [string]$Confirmation = 'human-confirmed')
    $out = & pwsh -NoProfile -File $writer -ProjectRoot $Root -FeatureRef '001-feat' -Lens $Lens -Decision $Decision -Depth $Depth -Agenda $Agenda -Confirmation $Confirmation 2>&1
    # PowerShell's native-error renderer wraps a long throw across lines and pads it; the CONTRACT is the
    # sentence, not its column width, so collapse whitespace before matching.
    # The console renderer wraps a long throw, pads it with box-drawing gutters, and colours it with ANSI
    # escapes. The CONTRACT is the sentence, not its presentation, so strip both before matching.
    $joined = (($out | ForEach-Object { [string]$_ }) -join " ")
    $plain = [regex]::Replace($joined, "`e\[[0-9;]*m", '')
    $plain = $plain -replace '\|', ' '
    $normalized = ($plain -replace '\s+', ' ').Trim()
    return [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Text = $normalized }
}

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 1: F-1 reproduced - before the writer runs, the lens is NOT closed'
$f1 = New-WorkshopFixture
$null = Write-LensReceipt -Root $f1.Root -Lens 'architecture-core'
$before = Read-Controller -Path $f1.Controller
Assert-True (@($before.workshop.PSObject.Properties).Count -eq 0) 'the controller starts with no closed lens - the human has answered, nothing has advanced'

Write-Host 'Case 2: the writer closes the lens - moved_on and the confirmation fields, written by the machinery'
$r2 = Invoke-Writer -Root $f1.Root -Lens 'architecture-core'
Assert-True $r2.Ok ('the writer succeeds: ' + $r2.Text)
$after = Read-Controller -Path $f1.Controller
$entry = $after.workshop.'architecture-core'
Assert-True ($null -ne $entry -and [bool]$entry.moved_on) 'moved_on is true - the transition ran, and not by hand'
Assert-True ([string]$entry.confirmation -eq 'human-confirmed' -and [string]$entry.confirmation_scope -eq 'lens-question') 'the confirmation fields are written together with it, so they cannot disagree'
Assert-True ([string]$entry.decision -match 'existing layering' -and [string]$entry.depth -eq 'medium' -and @($entry.agenda).Count -ge 1) 'the lens content is recorded in the same atomic write'
# Property-EXISTENCE, not property-access: under StrictMode a missing property throws and aborts the
# file, so the round-trip cases below would never report. A mutation must produce a readable FAIL.
$receiptProp = $entry.PSObject.Properties['human_turn_receipt']
Assert-True ($null -ne $receiptProp -and [string]$receiptProp.Value -match '^receipt-') 'the entry carries the receipt id under the name the CANONICAL READER reads - this assertion previously named `turn_receipt`, the writer''s own invention, and so certified the defect it was meant to catch'
Assert-True ($null -eq $entry.PSObject.Properties['turn_receipt']) 'and the writer-only name is gone entirely, so no reader can be split between two spellings'

# Case 2b is the WRITER-TO-READER CONTRACT, and it is the case that should have caught the
# `turn_receipt` defect and did not. It ran against a fixture with no `human_turn_contract`, so the
# canonical reader skipped its receipt validation and the mismatched field name was invisible. The
# lesson the maintainer drew from it (2026-08-29) is a rule, not an observation: mutation proving shows
# a control is wired to its OWN TEST, never that it is wired to the system. A seam needs one case that
# runs the writer and the reader together - which is what this now is.
Write-Host 'Case 2b: THE ROUND TRIP - what the writer wrote, the canonical reader accepts and advances on'
$state = Get-SpecrewWorkshopLifecycleState -ProjectRoot $f1.Root -FeatureRef '001-feat'
Assert-True ([string]$state.status -ne 'invalid') ('the reader accepts the entry the writer produced (status: ' + [string]$state.status + '/' + [string]$state.reason + ')')
Assert-True ([string]$state.reason -ne 'workshop-completed-human-turn-receipt-invalid') 'and specifically does NOT reject the receipt - the exact rejection the field-name mismatch produced'
Assert-True ([string]$state.current_lens -eq 'ui-ux') 'the current lens advanced to the next selected topic'
Assert-True (@($state.completed) -contains 'architecture-core') 'and the closed lens is reported complete'

Write-Host 'Case 2c: a SKIPPED lens round-trips too - the scope comes from the receipt, not from a table in the writer'
$f2c = New-WorkshopFixture
$null = Write-LensReceipt -Root $f2c.Root -Lens 'architecture-core' -Confirmation 'human-skipped' -Scope 'explicit-skip'
$r2c = Invoke-Writer -Root $f2c.Root -Lens 'architecture-core' -Confirmation 'human-skipped'
Assert-True $r2c.Ok ('the writer closes a skipped topic: ' + $r2c.Text)
$entry2c = (Read-Controller -Path $f2c.Controller).workshop.'architecture-core'
Assert-True ([string]$entry2c.confirmation_scope -eq 'explicit-skip') 'the scope written is the receipt''s own `explicit-skip`, not the `lens-question` a local table produced for every answer alike'
$state2c = Get-SpecrewWorkshopLifecycleState -ProjectRoot $f2c.Root -FeatureRef '001-feat'
Assert-True ([string]$state2c.reason -ne 'workshop-completed-human-turn-receipt-invalid') 'and the reader accepts it - a derived scope that disagreed with the receipt made the entry unreadable'
Assert-True (@($state2c.completed) -contains 'architecture-core') 'the skipped topic is complete, so the workshop moves on rather than re-asking'

Write-Host 'Case 3: no typed reply on record - the topic stays open, and the refusal says what is needed'
$f3 = New-WorkshopFixture
$r3 = Invoke-Writer -Root $f3.Root -Lens 'architecture-core'
Assert-True (-not $r3.Ok) 'the writer refuses without a receipt'
Assert-True ($r3.Text -match 'No typed reply from you is on record' -and $r3.Text -match 'Reply to the open question') 'the refusal names what is missing and the one action'
Assert-True ($r3.Text -notmatch 'controller|lens-applicability\.json|governed writer') 'and speaks in the human''s vocabulary, not the machinery''s'
Assert-True (@((Read-Controller -Path $f3.Controller).workshop.PSObject.Properties).Count -eq 0) 'nothing was written'

Write-Host 'Case 4: no written record - the topic stays open, and the answers are preserved'
$f4 = New-WorkshopFixture -SkipRecord
$null = Write-LensReceipt -Root $f4.Root -Lens 'architecture-core'
$r4 = Invoke-Writer -Root $f4.Root -Lens 'architecture-core'
Assert-True (-not $r4.Ok -and $r4.Text -match 'has no written record yet') 'the writer refuses when the discussion record is missing'
Assert-True ($r4.Text -match 'workshop/architecture-core\.md') 'and names the exact file to write'

Write-Host 'Case 5 (B-6): the lens''s OWN validator runs at ITS checkpoint - the JSON product-domain record, caught here'
$f5 = New-WorkshopFixture -Selected @('product-domain', 'architecture-core')
$null = Write-LensReceipt -Root $f5.Root -Lens 'product-domain'
$jsonRecord = '{ "depth": "standard", "confirmation": "human-confirmed" }'
[System.IO.File]::WriteAllText((Join-Path $f5.Feature (Join-Path 'workshop' 'product-domain.yml')), $jsonRecord, [System.Text.UTF8Encoding]::new($false))
$r5 = Invoke-Writer -Root $f5.Root -Lens 'product-domain' -Depth 'standard'
Assert-True (-not $r5.Ok) 'the writer refuses to close a lens whose own record does not pass its checks'
Assert-True ($r5.Text -match 'did not pass its own checks' -and $r5.Text -match 'reads as JSON') 'the refusal carries the validator''s own words - naming JSON, at the checkpoint, not at the boundary'
Assert-True (@((Read-Controller -Path $f5.Controller).workshop.PSObject.Properties).Count -eq 0) 'and the lens stays open, so lenses 2-6 do not run on top of an unreadable artifact'

Write-Host 'Case 5b: the same lens closes once its record is valid'
# The record's REAL vocabulary (the validator's own enums), not an invented one: context_scope is
# feature_standalone|product_baseline|feature_delta, evidence is known|assumed|unknown|research-needed,
# and human-confirmed pairs with confirmation_scope lens-question.
$validRecord = "depth: standard`ndepth_reason: a first feature on a new stack`ncontext_scope: feature_standalone`nconfirmation: human-confirmed`nconfirmation_scope: lens-question`nstatements:`n  - text: One person tracks their own reading.`n    evidence: known`n"
[System.IO.File]::WriteAllText((Join-Path $f5.Feature (Join-Path 'workshop' 'product-domain.yml')), $validRecord, [System.Text.UTF8Encoding]::new($false))
$r5b = Invoke-Writer -Root $f5.Root -Lens 'product-domain' -Depth 'standard'
Assert-True $r5b.Ok ('the writer closes the lens once the record validates: ' + $r5b.Text)
Assert-True ([bool](Read-Controller -Path $f5.Controller).workshop.'product-domain'.moved_on) 'and moved_on is written'

Write-Host 'Case 6: a lens outside the agreed agenda cannot be closed'
$f6 = New-WorkshopFixture
$null = Write-LensReceipt -Root $f6.Root -Lens 'security-compliance'
$r6 = Invoke-Writer -Root $f6.Root -Lens 'security-compliance'
Assert-True (-not $r6.Ok -and $r6.Text -match 'not one of the topics this workshop agreed to cover') 'the writer refuses a lens the agenda never selected'
Assert-True ($r6.Text -match 'architecture-core') 'and names the topics that ARE open'

foreach ($f in @($f1, $f2c, $f3, $f4, $f5, $f6)) { try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("workshop-lens-checkpoint: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'workshop-lens-checkpoint: all assertions passed' -ForegroundColor Green
