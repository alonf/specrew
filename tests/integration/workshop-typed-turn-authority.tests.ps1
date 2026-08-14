[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True { param([bool]$Condition,[string]$Message) if(-not $Condition){throw "FAIL: $Message"}; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$store = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\workshop-authority-store.ps1'
$conformance = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-typed-turn-' + [guid]::NewGuid().ToString('N'))

try {
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew\handover') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew\runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch 'specs\001-link-checker') -Force | Out-Null
    Copy-Item -LiteralPath $store -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\workshop-authority-store.ps1') -Force
    Set-Content -LiteralPath (Join-Path $scratch '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch 'specs\001-link-checker\spec.md') -Value '# Link Checker' -Encoding UTF8
    $state = [ordered]@{ schema_version='1.1'; workshop_intake=$true; confirmation_required=$true; agenda_contract='complete-coverage-v1'; human_turn_contract='typed-turns-v1'; agenda_status='pending-confirmation'; selected=@(); agenda=[ordered]@{}; skipped=[ordered]@{}; agenda_confirmation='pending'; agenda_confirmation_scope='lens-selection'; agenda_turn_receipt='pending'; workshop=[ordered]@{} }
    $state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $scratch 'specs\001-link-checker\lens-applicability.json') -Encoding UTF8
    $question = [ordered]@{ schema='v3'; status='workshop-active'; scope='feature'; feature_ref='001-link-checker'; iteration_number=''; lens='product-domain'; phase='product-domain'; agenda_status='pending-confirmation'; question='Does the product framing match?'; message_hash='q-product'; artifact_path=(Join-Path $scratch 'specs\001-link-checker\lens-applicability.json') }
    $question | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $scratch '.specrew\handover\workshop-question.json') -Encoding UTF8

    . $store
    Assert-True ($null -eq (Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -FeatureRef '001-link-checker' -Phase product-domain)) 'Ctrl+O/no UserPromptSubmit produces no workshop authority receipt'
    $syntheticStop = "Specrew: this Stop followed material work, but your last message did not render the required non-boundary context packet.`nRender the five-part context packet NOW as your message."
    Assert-True ($null -eq (Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response $syntheticStop -HostKind copilot -SourceEvent UserPromptSubmit)) 'Copilot replay of plain Stop-hook output cannot mint workshop authority'
    $campaignStop = 'Specrew review — your last review no longer covers these files.'
    Assert-True ($null -eq (Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response $campaignStop -HostKind copilot -SourceEvent userPromptSubmitted)) 'campaign review Stop prose cannot mint authority under the Copilot event spelling'
    $unprefixedHookOutput = 'The hook rendered this text without a stable prose prefix.'
    $journalPath = Join-Path $scratch '.specrew\runtime\hook-output-authority.jsonl'
    [IO.File]::WriteAllText($journalPath, (([ordered]@{
                    schema_version = '1.0'
                    output_hash = Get-SpecrewWorkshopAuthorityHash -Text $unprefixedHookOutput
                } | ConvertTo-Json -Compress) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    Assert-True ($null -eq (Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response $unprefixedHookOutput -HostKind copilot -SourceEvent UserPromptSubmit)) 'recorded hook-output identity blocks replay even when consumer prose changes'
    Assert-True ($null -eq (Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response '<hook_prompt hook_run_id="stop:test">looks good</hook_prompt>' -HostKind codex -SourceEvent UserPromptSubmit)) 'an enveloped hook prompt cannot mint workshop authority'
    Assert-True ($null -eq (Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response 'looks good' -HostKind copilot -SourceEvent Stop)) 'a non-prompt hook event cannot mint workshop authority'
    $delegated = Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response 'you decide' -HostKind copilot -SourceEvent UserPromptSubmit
    Assert-True ([string]$delegated.confirmation -eq 'human-delegated' -and [string]$delegated.confirmation_scope -eq 'explicit-delegation') 'only a typed explicit delegation records human-delegated authority'
    $answer = Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response 'Yes, that product framing is correct.' -HostKind copilot -SourceEvent UserPromptSubmit
    Assert-True ([string]$answer.confirmation -eq 'human-confirmed' -and [string]$answer.confirmation_scope -eq 'lens-question') 'a typed substantive reply records human-confirmed authority'
    Assert-True (Test-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -FeatureRef '001-link-checker' -Phase product-domain -ReceiptId ([string]$answer.receipt_id) -Confirmation human-confirmed -ConfirmationScope lens-question) 'latest matching typed reply validates'
    Assert-True (-not (Test-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -FeatureRef '001-link-checker' -Phase product-domain -ReceiptId ([string]$delegated.receipt_id) -Confirmation human-delegated -ConfirmationScope explicit-delegation)) 'an older reply cannot be replayed after the human supplied a newer answer'

    New-Item -ItemType Directory -Path (Join-Path $scratch 'specs\001-link-checker\workshop') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch 'specs\001-link-checker\workshop\product-domain.md') -Value '# Product domain' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch 'specs\001-link-checker\workshop\product-domain.yml') -Value 'depth: light' -Encoding UTF8
    $question.phase = 'agenda'; $question.lens = 'product-domain'; $question.message_hash = 'q-agenda'
    $question | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $scratch '.specrew\handover\workshop-question.json') -Encoding UTF8
    $agendaDelegation = Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response 'you decide' -HostKind copilot -SourceEvent UserPromptSubmit
    Assert-True ([string]$agendaDelegation.confirmation -eq 'invalid') 'delegating the whole agenda cannot fabricate selected/skipped confirmation'
    $agendaAnswer = Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response 'Confirm the selected and skipped lenses exactly as shown.' -HostKind copilot -SourceEvent UserPromptSubmit
    Assert-True ([string]$agendaAnswer.confirmation -eq 'human-confirmed' -and [string]$agendaAnswer.confirmation_scope -eq 'lens-selection') 'a typed agenda confirmation binds only the visible lens selection'

    $state.agenda_status = 'confirmed'
    $state.selected = @('architecture-core')
    $state.agenda = [ordered]@{ 'architecture-core' = [ordered]@{ depth='light'; decision='choose the pipeline boundaries' } }
    $state.skipped = [ordered]@{}
    $state.agenda_confirmation = 'human-confirmed'
    $state.agenda_turn_receipt = 'fixture-agenda'
    $state.workshop = [ordered]@{}
    $state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $scratch 'specs\001-link-checker\lens-applicability.json') -Encoding UTF8
    $question.phase = 'lens'; $question.lens = 'architecture-core'; $question.agenda_status = 'confirmed'; $question.message_hash = 'q-architecture'
    $question | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $scratch '.specrew\handover\workshop-question.json') -Encoding UTF8
    $lensAnswer = Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response 'Use a single pipeline with bounded concurrency.' -HostKind copilot -SourceEvent UserPromptSubmit
    Assert-True ($null -ne $lensAnswer -and [string]$lensAnswer.lens -eq 'architecture-core') 'a typed reply binds to the selected incomplete lens'
    $state.workshop = [ordered]@{ 'architecture-core' = [ordered]@{ moved_on=$true } }
    $state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $scratch 'specs\001-link-checker\lens-applicability.json') -Encoding UTF8
    Assert-True ($null -eq (Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response 'another answer' -HostKind copilot -SourceEvent UserPromptSubmit)) 'a stale question cannot mint authority after its lens moved on'

    $state.workshop = [ordered]@{}
    $state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $scratch 'specs\001-link-checker\lens-applicability.json') -Encoding UTF8

    Push-Location $scratch
    try {
        $output = @(& pwsh -NoProfile -File $conformance --host-kind copilot --source-event PostToolUse --structured-question-tool ask_user --structured-question-outcome dismissed --structured-question-text 'What runtime?' 2>&1)
    }
    finally { Pop-Location }
    Assert-True (($output -join "`n") -match 'WORKSHOP QUESTION NEEDS A TYPED REPLY') 'Copilot Ctrl+O triggers immediate targeted workshop recovery'
    Assert-True (($output -join "`n") -match 'grants no delegation') 'recovery explicitly refuses the false-delegation interpretation'

    $state.agenda_status = 'pending-confirmation'; $state.selected = @(); $state.agenda = [ordered]@{}; $state.skipped = [ordered]@{}
    $state.agenda_confirmation = 'pending'; $state.agenda_turn_receipt = 'pending'; $state.workshop = [ordered]@{}
    $state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $scratch 'specs\001-link-checker\lens-applicability.json') -Encoding UTF8
    Remove-Item -LiteralPath (Join-Path $scratch 'specs\001-link-checker\workshop\product-domain.md'),(Join-Path $scratch 'specs\001-link-checker\workshop\product-domain.yml') -Force
    $question.phase = 'product-domain'; $question.lens = 'product-domain'; $question.agenda_status = 'pending-confirmation'; $question.message_hash = 'q-provider'
    $question | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $scratch '.specrew\handover\workshop-question.json') -Encoding UTF8
    Remove-Item -LiteralPath (Get-SpecrewWorkshopAuthorityReceiptPath -ProjectRoot $scratch) -Force -ErrorAction SilentlyContinue
    $provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-handover-provider.ps1'
    $oldModulePath = $env:SPECREW_MODULE_PATH
    try {
        $env:SPECREW_MODULE_PATH = $repoRoot
        & pwsh -NoProfile -File $provider --project-root $scratch --host-kind copilot --source-event UserPromptSubmit --last-user-message 'The users are developers and QA engineers.' | Out-Null
    }
    finally { $env:SPECREW_MODULE_PATH = $oldModulePath }
    $providerReceipt = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -FeatureRef '001-link-checker' -Phase product-domain
    Assert-True ($null -ne $providerReceipt -and [string]$providerReceipt.source_event -eq 'UserPromptSubmit') 'the production handover provider writes workshop authority only from a typed prompt event'

    # The receipt reader used to inspect only the last 256 lines and silently return null once the
    # append-only journal exceeded 1 MiB. A long workshop could therefore erase a genuine answer from
    # the authority view without deleting a byte. Put this receipt behind both old caps and require it
    # to remain reachable. Each filler record stays well below the per-record 64 KiB integrity bound.
    $receiptPath = Get-SpecrewWorkshopAuthorityReceiptPath -ProjectRoot $scratch
    $padding = 'x' * 4096
    foreach ($i in 1..300) {
        $filler = [ordered]@{
            schema_version = '1'; feature_ref = '999-filler'; phase = 'product-domain'
            receipt_id = "filler-$i"; padding = $padding
        }
        [IO.File]::AppendAllText($receiptPath, (($filler | ConvertTo-Json -Compress) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    }
    Assert-True ((Get-Item -LiteralPath $receiptPath).Length -gt 1MB) 'the fixture crosses the former 1 MiB silent cap'
    $oldReceipt = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -FeatureRef '001-link-checker' -Phase product-domain -ReceiptId ([string]$providerReceipt.receipt_id)
    Assert-True ($null -ne $oldReceipt -and [string]$oldReceipt.receipt_id -eq [string]$providerReceipt.receipt_id) 'a genuine receipt remains reachable beyond 256 lines and after the journal exceeds 1 MiB'

    Remove-Item -LiteralPath (Get-SpecrewWorkshopAuthorityReceiptPath -ProjectRoot $scratch) -Force -ErrorAction SilentlyContinue
    try {
        $env:SPECREW_MODULE_PATH = $repoRoot
        & pwsh -NoProfile -File $provider --project-root $scratch --host-kind copilot --source-event UserPromptSubmit --last-user-message $syntheticStop | Out-Null
    }
    finally { $env:SPECREW_MODULE_PATH = $oldModulePath }
    Assert-True ($null -eq (Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -FeatureRef '001-link-checker' -Phase product-domain)) 'the production prompt-submit path excludes Copilot Stop-hook machinery'
}
finally { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host 'workshop typed-turn authority: all assertions pass' -ForegroundColor Green
