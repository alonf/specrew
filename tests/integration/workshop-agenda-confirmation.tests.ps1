[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$initializer = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\initialize-workshop-controller-state.ps1'
$writer = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\confirm-workshop-agenda.ps1'
$mirror = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\confirm-workshop-agenda.ps1'
$accessor = Join-Path $repoRoot 'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1'
$catalogSource = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses\index.yml'
$authoritySource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\workshop-authority-store.ps1'
$yamlReaderSource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\intake\helpers\Read-IntakeYaml.ps1'
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'

Assert-True (Test-Path -LiteralPath $writer -PathType Leaf) 'agenda confirmation writer exists'
Assert-True (Test-Path -LiteralPath $mirror -PathType Leaf) 'agenda confirmation deployed mirror exists'
Assert-True ((Get-Content -LiteralPath $writer -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $mirror -Raw -Encoding UTF8)) 'agenda confirmation source and deployed mirror are byte-identical'

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-agenda-confirmation-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specify\extensions\specrew-speckit\knowledge\design-lenses') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\intake\helpers') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew\handover') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch 'specs\001-url-checker') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch 'specs\001-url-checker\spec.md') -Value '# URL Checker' -Encoding UTF8
    Copy-Item -LiteralPath $catalogSource -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\knowledge\design-lenses\index.yml') -Force
    Copy-Item -LiteralPath $authoritySource -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\workshop-authority-store.ps1') -Force
    Copy-Item -LiteralPath $yamlReaderSource -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\intake\helpers\Read-IntakeYaml.ps1') -Force
    . (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\workshop-authority-store.ps1')

    function Add-TypedReply {
        param([string]$FeatureRef, [ValidateSet('product-domain','agenda','lens')][string]$Phase, [string]$Lens, [string]$Reply, [string]$MessageText = 'Fixture question?')
        $messageHash = Get-SpecrewWorkshopAuthorityHash -Text ('feature|' + $FeatureRef + '||' + $Lens + '|' + $MessageText)
        $question = [ordered]@{ schema='v3'; status='workshop-active'; scope='feature'; feature_ref=$FeatureRef; iteration_number=''; lens=$Lens; phase=$Phase; agenda_status='pending-confirmation'; question='Fixture question?'; message_hash=$messageHash; artifact_path=(Join-Path $scratch "specs\$FeatureRef\lens-applicability.json") }
        $question | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $scratch '.specrew\handover\workshop-question.json') -Encoding UTF8
        return Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response $Reply -HostKind 'test' -SourceEvent 'UserPromptSubmit'
    }

    function Add-AgendaReplyThroughShippedProvider {
        param(
            [Parameter(Mandatory)][string]$AssistantText,
            [Parameter(Mandatory)][string]$Reply,
            [ValidateSet('lf','crlf')][string]$LineEnding = 'lf'
        )
        $visible = if ($LineEnding -eq 'crlf') {
            (($AssistantText -replace "`r`n", "`n") -replace "`n", "`r`n")
        }
        else { $AssistantText -replace "`r`n", "`n" }
        $transcriptPath = Join-Path $scratch ('.specrew\runtime\agenda-' + [guid]::NewGuid().ToString('N') + '.jsonl')
        New-Item -ItemType Directory -Path (Split-Path -Parent $transcriptPath) -Force | Out-Null
        $line = [pscustomobject]@{
            type = 'assistant'
            message = [pscustomobject]@{
                content = @([pscustomobject]@{ type = 'text'; text = $visible })
            }
        } | ConvertTo-Json -Depth 8 -Compress
        [IO.File]::WriteAllText($transcriptPath, $line + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

        $priorModulePath = $env:SPECREW_MODULE_PATH
        $env:SPECREW_MODULE_PATH = $repoRoot
        try {
            Push-Location $scratch
            try { $providerOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $provider --host-kind claude --source-event Stop --transcript-path $transcriptPath 2>&1) }
            finally { Pop-Location }
        }
        finally { $env:SPECREW_MODULE_PATH = $priorModulePath }
        Assert-True ($LASTEXITCODE -eq 0 -and ($providerOutput -join "`n") -notmatch 'SPECREW-STOP-BLOCK') 'real conformance provider accepts the visible agenda as the active workshop question'
        $questionPath = Join-Path $scratch '.specrew\handover\workshop-question.json'
        Assert-True (Test-Path -LiteralPath $questionPath -PathType Leaf) 'real conformance provider writes the agenda question handover'
        $question = Get-Content -LiteralPath $questionPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
        Assert-True ([string]$question.phase -eq 'agenda' -and -not [string]::IsNullOrWhiteSpace([string]$question.agenda_digest)) 'real conformance provider binds the rendered agenda content independently of transcript prose hashing'
        return Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response $Reply -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
    }

    & $initializer -ProjectRoot $scratch -FeatureRef '001-url-checker'
    $missingAuthorityRefused = $false
    try { & $writer -ProjectRoot $scratch -FeatureRef '001-url-checker' -SelectedLens @('architecture-core') -SelectedDepth @('light') -SelectedDecision @('Choose structure.') -SkippedLens @() -SkippedReason @() | Out-Null }
    catch { $missingAuthorityRefused = ($_.Exception.Message -match 'typed human reply receipt') }
    Assert-True $missingAuthorityRefused 'writer refuses model-authored agenda state when no typed human response receipt exists'
    $null = Add-TypedReply -FeatureRef '001-url-checker' -Phase 'product-domain' -Lens 'product-domain' -Reply 'The product framing matches.'

    # Beta3 Copilot walk regression (2026-08-15): the model showed the technical agenda before it persisted the
    # product-domain records. Every subsequent typed "confirmed" was therefore correctly classified as another
    # product-domain answer and the later agenda writer prescribed an impossible retry. RenderOnly owns the earliest
    # deterministic boundary: it must not show an agenda that the prompt hook cannot classify as agenda authority.
    $prematureAgendaRefused = $false
    $prematureAgendaMessage = ''
    try {
        & $writer -ProjectRoot $scratch -FeatureRef '001-url-checker' `
            -SelectedLens @('architecture-core') -SelectedDepth @('light') -SelectedDecision @('Choose structure.') `
            -SkippedLens @() -SkippedReason @() -RenderOnly | Out-Null
    }
    catch {
        $prematureAgendaMessage = $_.Exception.Message
        $prematureAgendaRefused = ($prematureAgendaMessage -match 'product-domain\.md' -and
            $prematureAgendaMessage -match 'product-domain\.yml' -and
            $prematureAgendaMessage -match '(?i)before.*agenda|agenda.*before')
    }
    Assert-True $prematureAgendaRefused "render-only refuses before both product-domain records exist and names the real prerequisite: $prematureAgendaMessage"

    New-Item -ItemType Directory -Path (Join-Path $scratch 'specs\001-url-checker\workshop') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch 'specs\001-url-checker\workshop\product-domain.md') -Value '# Product domain' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch 'specs\001-url-checker\workshop\product-domain.yml') -Value 'depth: light' -Encoding UTF8
    $statePath = Join-Path $scratch 'specs\001-url-checker\lens-applicability.json'
    # Walk 4 / W14 (2026-08-16): a weaker host redundantly projected the completed product-domain phase into the
    # pre-agenda workshop map. The durable authority is still the two product records plus the typed receipt. This
    # projection must neither wedge agenda rendering nor become technical-lens authority; the canonical writer
    # discards it when the human-confirmed agenda is persisted.
    $preAgendaWithProductProjection = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    $preAgendaWithProductProjection.workshop | Add-Member -NotePropertyName 'product-domain' -NotePropertyValue ([pscustomobject]@{
        moved_on = $true
        confirmation = 'human-confirmed'
        human_turn_receipt = 'pending'
    })
    $preAgendaWithProductProjection | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $statePath -Encoding UTF8
    . $accessor
    $preAgendaLifecycle = Get-SpecrewWorkshopLifecycleState -ProjectRoot $scratch -FeatureRef '001-url-checker'
    Assert-True ($preAgendaLifecycle.status -eq 'active' -and $preAgendaLifecycle.reason -eq 'workshop-pre-agenda-active') 'redundant product-domain projection remains a valid pre-agenda state and is never treated as a technical decision'
    $before = [IO.File]::ReadAllBytes($statePath)
    $incompleteRefused = $false
    try {
        & $writer -ProjectRoot $scratch -FeatureRef '001-url-checker' `
            -SelectedLens @('architecture-core', 'requirements-nfr') `
            -SelectedDepth @('medium', 'light') `
            -SelectedDecision @('Choose the processing pipeline.', 'Choose timeouts and exit codes.') `
            -SkippedLens @('data-storage') `
            -SkippedReason @('No persistent state.') | Out-Null
    }
    catch { $incompleteRefused = ($_.Exception.Message -match 'Every technical lens must be selected or visibly skipped') }
    $afterRefusal = [IO.File]::ReadAllBytes($statePath)
    Assert-True $incompleteRefused 'writer refuses an agenda that hides omitted lenses'
    Assert-True ([Convert]::ToBase64String($before) -eq [Convert]::ToBase64String($afterRefusal)) 'incomplete-coverage refusal preserves pending controller state byte-for-byte'

    $selected = @('architecture-core', 'requirements-nfr', 'integration-api', 'code-implementation')
    $depths = @('medium', 'light', 'medium', 'medium')
    $decisions = @(
        'Choose the processing pipeline and concurrency boundary.',
        'Choose timeouts, error output, and exit codes.',
        'Choose HTTP behavior for external reference checks.',
        'Choose C# implementation and dependency rules.'
    )
    $skipped = @('data-storage', 'ui-ux', 'devops-operations', 'security-compliance', 'observability-resilience', 'component-design')
    $reasons = @(
        'The checker stores no durable data.',
        'The interface is terminal-only.',
        'The feature changes no deployment or release pipeline.',
        'The tool handles no auth, secrets, PII, or compliance data.',
        'The local CLI has no long-running service operations.',
        'The architecture pipeline already supplies the needed component boundary.'
    )
    $agendaJson = [ordered]@{
        selected = @(for ($i = 0; $i -lt $selected.Count; $i++) { [ordered]@{ lens = $selected[$i]; depth = $depths[$i]; decision = $decisions[$i] } })
        skipped = @(for ($i = 0; $i -lt $skipped.Count; $i++) { [ordered]@{ lens = $skipped[$i]; reason = $reasons[$i] } })
    } | ConvertTo-Json -Depth 6 -Compress

    $renderedAgenda = @(& $writer -ProjectRoot $scratch -FeatureRef '001-url-checker' -AgendaJson $agendaJson -RenderOnly) -join [Environment]::NewLine
    Assert-True ($renderedAgenda -match 'Selected lenses:' -and $renderedAgenda -match 'Skipped lenses:' -and $renderedAgenda -match 'ui-ux: The interface is terminal-only') 'render-only emits the complete canonical selected + skipped agenda the human must see'
    Assert-True (Test-SpecrewWorkshopAgendaVisibleInText -Text ("Agenda follows.`n`n" + $renderedAgenda) -CanonicalAgendaText $renderedAgenda) 'whitespace-normalized exact agenda remains visible'
    $bulletSwappedAgenda = [regex]::Replace($renderedAgenda, '(?m)^- ', ([string][char]0x2022 + ' '))
    Assert-True ($bulletSwappedAgenda -ne $renderedAgenda -and $bulletSwappedAgenda -match ([string][char]0x2022)) 'fixture actually substitutes the canonical dash bullets'
    Assert-True (-not (Test-SpecrewWorkshopAgendaVisibleInText -Text $bulletSwappedAgenda -CanonicalAgendaText $renderedAgenda)) 'a dash-to-bullet rewrite is not the visible canonical agenda'

    function Invoke-ShippedWorkshopProvider {
        param([Parameter(Mandatory)][string]$AssistantText)
        $transcriptPath = Join-Path $scratch ('.specrew\runtime\agenda-' + [guid]::NewGuid().ToString('N') + '.jsonl')
        New-Item -ItemType Directory -Path (Split-Path -Parent $transcriptPath) -Force | Out-Null
        $line = [pscustomobject]@{
            type = 'assistant'
            message = [pscustomobject]@{
                content = @([pscustomobject]@{ type = 'text'; text = $AssistantText })
            }
        } | ConvertTo-Json -Depth 8 -Compress
        [IO.File]::WriteAllText($transcriptPath, $line + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        $priorModulePath = $env:SPECREW_MODULE_PATH
        $env:SPECREW_MODULE_PATH = $repoRoot
        try {
            Push-Location $scratch
            try { $providerOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $provider --host-kind claude --source-event Stop --transcript-path $transcriptPath 2>&1) }
            finally { Pop-Location }
        }
        finally { $env:SPECREW_MODULE_PATH = $priorModulePath }
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = ($providerOutput -join "`n")
            QuestionPath = (Join-Path $scratch '.specrew\handover\workshop-question.json')
        }
    }

    $reformatted = Invoke-ShippedWorkshopProvider -AssistantText ("Agenda follows.`n`n" + $bulletSwappedAgenda + "`n`nPlease answer above.")
    Assert-True ($reformatted.ExitCode -eq 0 -and $reformatted.Output -match 'SPECREW-STOP-BLOCK') 'reformatted agenda is refused at the Stop that showed it'
    Assert-True ($reformatted.Output -match '(?i)agenda you showed was reformatted' -and
        $reformatted.Output -match '(?i)send the command''s output exactly as printed' -and
        $reformatted.Output -match '(?i)without changing bullets or spacing') 'reformatted-agenda refusal names the rewrite and the exact-output retry'
    Assert-True ($reformatted.Output -notmatch '(?i)lens-applicability|controller|digest') 'reformatted-agenda refusal keeps workshop machinery out of the human-facing correction'
    $reformattedQuestion = Get-Content -LiteralPath $reformatted.QuestionPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
    Assert-True ([string]$reformattedQuestion.phase -eq 'agenda' -and -not $reformattedQuestion.PSObject.Properties['agenda_digest']) 'reformatted agenda does not bind confirmation identity'

    $notYetShown = Invoke-ShippedWorkshopProvider -AssistantText 'Product grounding is recorded. I will show the technical topics next.'
    Assert-True ($notYetShown.ExitCode -eq 0 -and $notYetShown.Output -notmatch 'agenda you showed was reformatted') 'an agenda-phase turn that has not shown the agenda is not accused of reformatting it'

    $null = Add-AgendaReplyThroughShippedProvider -AssistantText ("Agenda follows.`n`n" + $renderedAgenda + "`n`nPlease answer above.") `
        -Reply 'Confirm this selected and skipped agenda.' -LineEnding lf

    $changedAgenda = $agendaJson.Replace('Choose the processing pipeline and concurrency boundary.', 'Choose a different architecture.')
    $mismatchRefused = $false
    try { & $writer -ProjectRoot $scratch -FeatureRef '001-url-checker' -AgendaJson $changedAgenda | Out-Null }
    catch { $mismatchRefused = ($_.Exception.Message -match 'architecture-core' -and $_.Exception.Message -match 'changed') }
    Assert-True $mismatchRefused 'a receipt for agenda A cannot authorize changed agenda B and names the changed lens'

    $result = & $writer -ProjectRoot $scratch -FeatureRef '001-url-checker' -AgendaJson $agendaJson -PassThru
    Assert-True ([string]$result.state -eq 'confirmed' -and $result.selected_count -eq 4 -and $result.skipped_count -eq 6) 'writer reports the exact confirmed agenda coverage'

    $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    Assert-True ([string]$state.agenda_status -eq 'confirmed' -and [string]$state.agenda_confirmation -eq 'human-confirmed' -and
        [string]$state.agenda_confirmation_scope -eq 'lens-selection') 'confirmed state records typed human authority for the lens selection'
    Assert-True (@($state.selected).Count -eq 4 -and @($state.agenda.PSObject.Properties).Count -eq 4 -and
        @($state.skipped.PSObject.Properties).Count -eq 6) 'confirmed state makes both selected and skipped sets reviewable'
    Assert-True (@($state.workshop.PSObject.Properties).Count -eq 0) 'confirmed agenda discards the redundant product-domain projection instead of promoting it to technical authority'
    Assert-True ([string]$state.skipped.'ui-ux' -eq 'The interface is terminal-only.') 'each skipped lens carries its feature-specific reason'

    $lifecycle = Get-SpecrewWorkshopLifecycleState -ProjectRoot $scratch -FeatureRef '001-url-checker'
    Assert-True ($lifecycle.status -eq 'active' -and $lifecycle.current_lens -eq 'architecture-core') 'strict controller opens lens 1 only after complete coverage and human confirmation'

    $validStateJson = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
    $forgedShape = $validStateJson | ConvertFrom-Json -Depth 20
    $forgedShape.skipped.'ui-ux' = [pscustomobject]@{ reason = 'The interface is terminal-only.' }
    $forgedShape | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $statePath -Encoding UTF8
    $forgedShapeResult = Get-SpecrewWorkshopLifecycleState -ProjectRoot $scratch -FeatureRef '001-url-checker'
    Assert-True ($forgedShapeResult.status -eq 'invalid' -and $forgedShapeResult.reason -eq 'workshop-agenda-skipped-entry-invalid') 'a hand-written nested skipped entry is rejected by the production controller reader'

    [IO.File]::WriteAllText($statePath, $validStateJson, [Text.UTF8Encoding]::new($false))
    $forgedContent = $validStateJson | ConvertFrom-Json -Depth 20
    $forgedContent.agenda.'architecture-core'.decision = 'Choose an architecture the human did not confirm.'
    $forgedContent | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $statePath -Encoding UTF8
    $forgedContentResult = Get-SpecrewWorkshopLifecycleState -ProjectRoot $scratch -FeatureRef '001-url-checker'
    Assert-True ($forgedContentResult.status -eq 'invalid' -and $forgedContentResult.reason -eq 'workshop-agenda-digest-mismatch') 'a plausible flat controller whose content does not match its receipt is rejected'
    [IO.File]::WriteAllText($statePath, $validStateJson, [Text.UTF8Encoding]::new($false))

    # Keep the shipped provider's active-feature discovery unambiguous for the independent
    # CRLF/external-shell case below. The first feature's assertions and authority facts are
    # already complete; removing this scratch-only controller cannot affect their evidence.
    Remove-Item -LiteralPath (Join-Path $scratch 'specs\001-url-checker') -Recurse -Force
    $shellFeature = '002-shell-call'
    New-Item -ItemType Directory -Path (Join-Path $scratch "specs\$shellFeature") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch "specs\$shellFeature\spec.md") -Value '# Shell Call' -Encoding UTF8
    & $initializer -ProjectRoot $scratch -FeatureRef $shellFeature
    $null = Add-TypedReply -FeatureRef $shellFeature -Phase 'product-domain' -Lens 'product-domain' -Reply 'The product framing matches.'
    New-Item -ItemType Directory -Path (Join-Path $scratch "specs\$shellFeature\workshop") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch "specs\$shellFeature\workshop\product-domain.md") -Value '# Product domain' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch "specs\$shellFeature\workshop\product-domain.yml") -Value 'depth: light' -Encoding UTF8
    $shellRenderedAgenda = @(& $writer -ProjectRoot $scratch -FeatureRef $shellFeature -AgendaJson $agendaJson -RenderOnly) -join [Environment]::NewLine
    $null = Add-AgendaReplyThroughShippedProvider -AssistantText ("`r`n" + $shellRenderedAgenda + "`r`n") -Reply 'Confirm this selected and skipped agenda.' -LineEnding crlf
    $shellOutput = @(& pwsh -NoProfile -File $writer -ProjectRoot $scratch -FeatureRef $shellFeature -AgendaJson $agendaJson -PassThru 2>&1)
    Assert-True ($LASTEXITCODE -eq 0) "pwsh -File accepts the single JSON agenda payload: $($shellOutput -join ' ')"
    $shellState = Get-Content -LiteralPath (Join-Path $scratch "specs\$shellFeature\lens-applicability.json") -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    Assert-True ([string]$shellState.agenda_status -eq 'confirmed' -and @($shellState.skipped.PSObject.Properties).Count -eq 6) 'external shell invocation preserves complete selected/skipped coverage'

    # Beta3 Sonnet-5 Copilot walk regression (2026-08-17, W17): eleven workshop questions were consumed
    # through the host's structured picker, so the typed-turn store correctly minted nothing - and then
    # said nothing. Both product records were persisted with zero authority behind them, and the next
    # turn misdiagnosed the silence as broken hook wiring. Picker-only hosts never fire a per-tool-call
    # event that could catch this earlier, so the Stop lane must name the selection channel itself.
    Remove-Item -LiteralPath (Join-Path $scratch "specs\$shellFeature") -Recurse -Force
    $pickerFeature = '003-picker-walk'
    New-Item -ItemType Directory -Path (Join-Path $scratch "specs\$pickerFeature") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch "specs\$pickerFeature\spec.md") -Value '# Picker Walk' -Encoding UTF8
    & $initializer -ProjectRoot $scratch -FeatureRef $pickerFeature
    New-Item -ItemType Directory -Path (Join-Path $scratch "specs\$pickerFeature\workshop") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch "specs\$pickerFeature\workshop\product-domain.md") -Value '# Product domain' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch "specs\$pickerFeature\workshop\product-domain.yml") -Value 'depth: light' -Encoding UTF8
    $unreceipted = Invoke-ShippedWorkshopProvider -AssistantText 'Product grounding captured. Preparing the technical agenda next.'
    Assert-True ($unreceipted.ExitCode -eq 0 -and $unreceipted.Output -match 'SPECREW-STOP-BLOCK') 'product records persisted without any typed receipt are refused at the Stop instead of passing as an intermediate workshop turn'
    Assert-True ($unreceipted.Output -match '(?i)selection channel' -and
        $unreceipted.Output -match '(?i)type their answer' -and
        $unreceipted.Output -match '(?i)visible prose') 'unreceipted-records refusal names the selection channel and the typed prose re-ask'
    Assert-True ($unreceipted.Output -match '(?i)answers are preserved' -and
        $unreceipted.Output -match '(?i)ask approval') 'unreceipted-records refusal keeps the answers safe and routes the record set-aside through human approval'
    Assert-True ($unreceipted.Output -notmatch '(?i)lens-applicability|controller|digest|jsonl|hook') 'unreceipted-records refusal keeps workshop machinery out of the correction'

    # The same durable state behind a genuine typed turn stays quiet: receipt first, records second.
    Remove-Item -LiteralPath (Join-Path $scratch "specs\$pickerFeature") -Recurse -Force
    $typedFeature = '004-typed-walk'
    New-Item -ItemType Directory -Path (Join-Path $scratch "specs\$typedFeature") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch "specs\$typedFeature\spec.md") -Value '# Typed Walk' -Encoding UTF8
    & $initializer -ProjectRoot $scratch -FeatureRef $typedFeature
    Assert-True ($null -ne (Add-TypedReply -FeatureRef $typedFeature -Phase 'product-domain' -Lens 'product-domain' -Reply 'The product framing matches.')) 'typed-walk fixture mints a genuine product-domain receipt before the records exist'
    New-Item -ItemType Directory -Path (Join-Path $scratch "specs\$typedFeature\workshop") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch "specs\$typedFeature\workshop\product-domain.md") -Value '# Product domain' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch "specs\$typedFeature\workshop\product-domain.yml") -Value 'depth: light' -Encoding UTF8
    $typedRecords = Invoke-ShippedWorkshopProvider -AssistantText 'Product grounding captured. Preparing the technical agenda next.'
    Assert-True ($typedRecords.ExitCode -eq 0 -and $typedRecords.Output -notmatch '(?i)selection channel') 'product records backed by a typed receipt are not accused of arriving through a selection channel'
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'workshop agenda confirmation: all assertions pass' -ForegroundColor Green
