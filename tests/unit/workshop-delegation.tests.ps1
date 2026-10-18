# Feature 202 iteration 002, T020 (FR-031, DA-4; B4F-130): delegating the remaining lenses.
#
# The walk's case, on all three hosts: "you decide the remaining lenses" recorded ONE delegation, for the lens open at the
# time, and each later lens asked "you decide this lens" again - 1 extra stop on Claude, 2 on Codex, 3 on Copilot. On
# Claude the reviewer answer then left a lens with a confirmed receipt and no delegation, so its close asked once more.
#
# Through the REAL handover provider at UserPromptSubmit, with the deployed-store layout it loads from (the
# receipt-disclosure harness), and the real lens checkpoint writer for the close.
#
# Mutations that turn this file red: drop the wide-form branch (case 1 records one lens); treat "the rest" as wide
# (case 3); remove the narrow line (case 4); close a lens only from its newest receipt again (case 6).
$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'scripts/internal/specrew-handover-provider.ps1'
$storeSource = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
$lensWriter = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1'
. $storeSource
. (Join-Path $repoRoot 'scripts/internal/specrew-consumer-language.ps1')

$feature = '001-mail-summary'
function New-LensFixture {
    param([string[]]$Selected = @('architecture-core', 'ui-ux', 'code-implementation'), [string]$OpenLens = 'architecture-core', [string[]]$Closed = @())
    $root = Join-Path ([IO.Path]::GetTempPath()) ('wdel-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    foreach ($d in @('.specrew/handover', '.specrew/runtime', '.specify/extensions/specrew-speckit/scripts', "specs/$feature/workshop")) {
        New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null
    }
    Copy-Item -LiteralPath $storeSource -Destination (Join-Path $root '.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1') -Force
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "specs/$feature/spec.md") -Value '# Feature Specification: Mail Summary' -Encoding UTF8
    foreach ($lens in $Selected) {
        Set-Content -LiteralPath (Join-Path $root "specs/$feature/workshop/$lens.md") -Value ("# {0}`n`nWhat we agreed, in the human's words." -f $lens) -Encoding UTF8
    }
    $workshop = [ordered]@{}
    foreach ($lens in $Closed) { $workshop[$lens] = [ordered]@{ moved_on = $true; confirmation = 'human-confirmed'; confirmation_scope = 'lens-question' } }
    $agenda = [ordered]@{}
    foreach ($lens in $Selected) { $agenda[$lens] = @(('An open question for {0}?' -f $lens)) }
    $controller = [ordered]@{
        schema_version = '1.1'; workshop_intake = $true; confirmation_required = $true
        human_turn_contract = 'typed-turns-v1'; agenda_contract = 'complete-coverage-v1'
        agenda_status = 'confirmed'; selected = @($Selected); agenda = $agenda; skipped = [ordered]@{}
        agenda_confirmation = 'human-confirmed'; agenda_confirmation_scope = 'lens-selection'; agenda_turn_receipt = 'receipt-fixture'
        workshop = $workshop
    }
    [IO.File]::WriteAllText((Join-Path $root "specs/$feature/lens-applicability.json"), ($controller | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    $question = [ordered]@{ schema = 'v3'; status = 'workshop-active'; scope = 'feature'; feature_ref = $feature; iteration_number = ''; lens = $OpenLens
        phase = 'lens'; agenda_status = 'confirmed'; question = 'How should we approach this?'; message_hash = ('b' * 64); artifact_path = '' }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/handover/workshop-question.json'), ($question | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $ctx = [ordered]@{ schema = 'v2'; session_state = [ordered]@{ active = $true; feature_ref = $feature; boundary_type = 'specify'; host = 'claude' } }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    return $root
}
function Invoke-Provider {
    param([string]$Root, [string]$Reply, [string]$MessageId)
    $extra = @('--turn-origin', 'typed-user', '--session-id', 'wdel-session') + @(if ($MessageId) { '--message-identity', 'declared', '--message-id', $MessageId })
    return ((& pwsh -NoProfile -File $provider --project-root $Root --host-kind claude --source-event UserPromptSubmit --last-user-message $Reply @extra 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
}
function Get-Receipts { param([string]$Root) $p = Join-Path $Root '.specrew/runtime/workshop-authority.jsonl'; if (-not (Test-Path -LiteralPath $p)) { return @() }; return @(Get-Content -LiteralPath $p | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }) }
function Get-DelegatedLenses { param([string]$Root) return @(Get-Receipts $Root | Where-Object { [string]$_.confirmation -eq 'human-delegated' } | ForEach-Object { [string]$_.lens }) }

Write-Host 'workshop-delegation'
$roots = New-Object System.Collections.Generic.List[string]
try {
    Write-Host '  --- case 1: "you decide the remaining lenses" covers every lens left on the agenda (B4F-130) ---'
    $r1 = New-LensFixture; $roots.Add($r1)
    $out1 = Invoke-Provider -Root $r1 -Reply 'You decide the remaining lenses.' -MessageId 'msg-wide'
    $lenses1 = @(Get-DelegatedLenses $r1)
    Assert-True ($lenses1.Count -eq 3 -and @(Compare-Object $lenses1 @('architecture-core', 'ui-ux', 'code-implementation')).Count -eq 0) ("case 1: one delegation per remaining lens ({0})" -f ($lenses1 -join ', '))
    Assert-True (@(Get-Receipts $r1 | Where-Object { -not $_.PSObject.Properties['message_id'] -or [string]$_.message_id -ne 'msg-wide' }).Count -eq 0) 'case 1: every delegation is bound to the message that gave it'
    Assert-True ($out1 -match 'architecture-core, ui-ux and code-implementation') 'case 1: the turn names the lenses covered, in one line'
    $found1 = @(Get-SpecrewBannedConsumerNoun -Text $out1)
    Assert-True ($found1.Count -eq 0) ('case 1: no internal noun reaches the human (' + ($found1 -join ',') + ')')

    Write-Host '  --- case 2: "all remaining lenses" is the other wide form; a closed lens is not covered again ---'
    $r2 = New-LensFixture -Closed @('ui-ux'); $roots.Add($r2)
    $null = Invoke-Provider -Root $r2 -Reply 'you decide all remaining lenses' -MessageId 'msg-all'
    $lenses2 = @(Get-DelegatedLenses $r2)
    Assert-True ($lenses2.Count -eq 2 -and $lenses2 -notcontains 'ui-ux') ("case 2: the lenses still open are covered, the closed one is not ({0})" -f ($lenses2 -join ', '))

    Write-Host '  --- case 3: "the rest" is not a wide form - it can mean the rest of this lens ---'
    $r3 = New-LensFixture; $roots.Add($r3)
    $out3 = Invoke-Provider -Root $r3 -Reply 'you decide the rest' -MessageId 'msg-rest'
    $lenses3 = @(Get-DelegatedLenses $r3)
    Assert-True ($lenses3.Count -eq 1 -and $lenses3[0] -eq 'architecture-core') 'case 3: only the open lens is delegated'
    Assert-True ($out3 -match 'you decide the remaining lenses') 'case 3: the turn names the phrase that covers the rest'

    Write-Host '  --- case 4: a narrow delegation with lenses pending says so, and names the wide phrase ---'
    $r4 = New-LensFixture; $roots.Add($r4)
    $out4 = Invoke-Provider -Root $r4 -Reply 'you decide' -MessageId 'msg-narrow'
    Assert-True (@(Get-DelegatedLenses $r4).Count -eq 1) 'case 4: one lens delegated'
    Assert-True ($out4 -match 'covers only architecture-core' -and $out4 -match 'ui-ux and code-implementation' -and $out4 -match 'you decide the remaining lenses') 'case 4: the turn says it covers only this lens, names the lenses still open and the phrase'
    $r4b = New-LensFixture -Selected @('architecture-core'); $roots.Add($r4b)
    $out4b = Invoke-Provider -Root $r4b -Reply 'you decide' -MessageId 'msg-last'
    Assert-True ($out4b -notmatch 'covers only') 'case 4: with no other lens open, nothing more is said'

    Write-Host '  --- case 5: an ordinary answer is not a delegation of anything ---'
    $r5 = New-LensFixture; $roots.Add($r5)
    $out5 = Invoke-Provider -Root $r5 -Reply 'Keep the remaining lenses light; one pipeline is enough.' -MessageId 'msg-answer'
    Assert-True (@(Get-DelegatedLenses $r5).Count -eq 0 -and @(Get-Receipts $r5).Count -eq 1) 'case 5: one confirmed answer for the open lens, no delegation'
    Assert-True ($out5 -notmatch 'covers only|you decide the remaining lenses') 'case 5: no delegation line'

    Write-Host '  --- case 6: delegated craft decisions plus a confirmed reviewer pick close the lens without a question ---'
    # The walk's lens was code-implementation, whose close also checks its rules manifest; the receipt rule is the same
    # for every lens, so a lens without a manifest check carries the case.
    $r6 = New-LensFixture -Selected @('ui-ux', 'architecture-core') -OpenLens 'architecture-core'; $roots.Add($r6)
    $null = Invoke-Provider -Root $r6 -Reply 'you decide the remaining lenses' -MessageId 'msg-wide-6'
    $null = Invoke-Provider -Root $r6 -Reply 'Use codex as the reviewer.' -MessageId 'msg-reviewer-6'
    $code6 = @(Get-Receipts $r6 | Where-Object { [string]$_.lens -eq 'architecture-core' })
    Assert-True ($code6.Count -eq 2 -and [string]$code6[1].confirmation -eq 'human-confirmed') 'case 6: the lens holds the delegation and, after it, the confirmed reviewer pick'
    $close6 = & pwsh -NoProfile -File $lensWriter -ProjectRoot $r6 -FeatureRef $feature -Lens 'architecture-core' -Decision 'Delegated; the reviewer is codex.' -Depth 'light' -Agenda @('An open question?') -Confirmation 'human-delegated' 2>&1
    $ok6 = ($LASTEXITCODE -eq 0)
    Assert-True $ok6 ('case 6: the lens closes as delegated: ' + ((@($close6) | ForEach-Object { [string]$_ }) -join ' '))
    if ($ok6) {
        $entry6 = (Get-Content -LiteralPath (Join-Path $r6 "specs/$feature/lens-applicability.json") -Raw | ConvertFrom-Json).workshop.'architecture-core'
        Assert-True ([string]$entry6.confirmation -eq 'human-delegated' -and [string]$entry6.human_turn_receipt -eq [string]$code6[0].receipt_id) 'case 6: closed on the delegation receipt'
        Assert-True (Test-SpecrewWorkshopAuthorityReceipt -ProjectRoot $r6 -FeatureRef $feature -Phase 'lens' -Lens 'architecture-core' -ReceiptId ([string]$entry6.human_turn_receipt) -Confirmation 'human-delegated' -ConfirmationScope 'explicit-delegation') 'case 6: the reader that checks a closed lens accepts it'
    }
    # Only confirmed answers may stand after the delegation: a later skip is the newest act and wins.
    $r6b = New-LensFixture -Selected @('ui-ux', 'architecture-core') -OpenLens 'architecture-core'; $roots.Add($r6b)
    $null = Invoke-Provider -Root $r6b -Reply 'you decide the remaining lenses' -MessageId 'msg-wide-6b'
    $null = Invoke-Provider -Root $r6b -Reply 'skip' -MessageId 'msg-skip-6b'
    $null = & pwsh -NoProfile -File $lensWriter -ProjectRoot $r6b -FeatureRef $feature -Lens 'architecture-core' -Decision 'Delegated.' -Depth 'light' -Agenda @('An open question?') -Confirmation 'human-delegated' 2>&1
    Assert-True ($LASTEXITCODE -ne 0) 'case 6: a delegation followed by a skip does not close as delegated'
    # A narrow "you decide" followed by an answer is a changed mind: the newer answer wins, and the older reply cannot
    # be replayed (workshop-typed-turn-authority pins the same rule for the product-domain phase).
    $r6c = New-LensFixture -Selected @('ui-ux', 'architecture-core') -OpenLens 'architecture-core'; $roots.Add($r6c)
    $null = Invoke-Provider -Root $r6c -Reply 'you decide' -MessageId 'msg-narrow-6c'
    $null = Invoke-Provider -Root $r6c -Reply 'Actually, keep one pipeline with bounded concurrency.' -MessageId 'msg-answer-6c'
    $null = & pwsh -NoProfile -File $lensWriter -ProjectRoot $r6c -FeatureRef $feature -Lens 'architecture-core' -Decision 'Delegated.' -Depth 'light' -Agenda @('An open question?') -Confirmation 'human-delegated' 2>&1
    Assert-True ($LASTEXITCODE -ne 0) 'case 6: a narrow delegation followed by an answer does not close as delegated'

    Write-Host '  --- case 7: the workshop skill asks the reviewer choice once, at agenda confirmation, outside delegation ---'
    $skill = [IO.File]::ReadAllText((Join-Path $repoRoot 'extensions/specrew-speckit/squad-templates/skills/design-workshop.md'))
    Assert-True ($skill -match 'reviewer choice' -and $skill -match 'at agenda confirmation' -and $skill -match 'default') 'case 7: the reviewer choice is asked at agenda confirmation, with the default named'
    Assert-True ($skill -match 'outside delegation') 'case 7: and stays outside delegation'
    Assert-True ($skill -match '"the remaining lenses"' -and $skill -match '"all remaining lenses"' -and $skill -match '"the rest"') 'case 7: the skill names the two wide forms and says "the rest" is not one'
}
finally {
    foreach ($d in $roots) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:Failures -gt 0) { Write-Host ("workshop-delegation: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'workshop-delegation: all cases passed'
exit 0
