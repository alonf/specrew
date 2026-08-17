[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# Beta3 Copilot walk regression (2026-08-17, W18): a retro-calculator workshop was interrupted by the
# generic material-work packet demand. The enforcement was correct - the agent had edited the feature
# spec.md during the product-domain turn, which costs the turn its workshop-record-only exemption - but
# the correction said only "render a packet", named nothing the human could act on, and did not require
# the pending workshop question to survive. The human got an engineering interrupt mid-conversation and
# lost their place. Enforcement is unchanged here; the surface is what these assertions pin.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
$providerMirror = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
$initializer = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\initialize-workshop-controller-state.ps1'
$authoritySource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\workshop-authority-store.ps1'
$accessorSource = Join-Path $repoRoot 'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1'
$captureSource = Join-Path $repoRoot 'scripts\internal\bootstrap\ConversationCaptureAccessor.ps1'
$catalogSource = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses\index.yml'
$yamlReaderSource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\intake\helpers\Read-IntakeYaml.ps1'

Assert-True (Test-Path -LiteralPath $provider -PathType Leaf) 'conformance provider source exists'
Assert-True ((Get-Content -LiteralPath $provider -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $providerMirror -Raw -Encoding UTF8)) 'conformance provider source and deployed mirror are byte-identical'

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-workshop-material-' + [guid]::NewGuid().ToString('N'))
$feature = '001-retro-calculator'
try {
    New-Item -ItemType Directory -Path $scratch -Force | Out-Null
    foreach ($dir in @(
            '.specrew\handover', '.specrew\runtime',
            '.specify\extensions\specrew-speckit\scripts\intake\helpers',
            '.specify\extensions\specrew-speckit\knowledge\design-lenses',
            '.specify\templates',
            'scripts\internal\bootstrap',
            "specs\$feature\workshop")) {
        New-Item -ItemType Directory -Path (Join-Path $scratch $dir) -Force | Out-Null
    }
    Set-Content -LiteralPath (Join-Path $scratch '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    Copy-Item -LiteralPath $authoritySource -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\workshop-authority-store.ps1') -Force
    Copy-Item -LiteralPath $yamlReaderSource -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\intake\helpers\Read-IntakeYaml.ps1') -Force
    Copy-Item -LiteralPath $catalogSource -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\knowledge\design-lenses\index.yml') -Force
    Copy-Item -LiteralPath $accessorSource -Destination (Join-Path $scratch 'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1') -Force
    Copy-Item -LiteralPath $captureSource -Destination (Join-Path $scratch 'scripts\internal\bootstrap\ConversationCaptureAccessor.ps1') -Force
    Set-Content -LiteralPath (Join-Path $scratch '.specify\templates\spec-template.md') -Value '# Feature Specification (template)' -Encoding UTF8

    # The walk shape exactly: the workshop notes are recorded AND the feature spec.md carries agent-authored
    # content, so it is no longer the untouched scaffold the pre-agenda exemption covers.
    Set-Content -LiteralPath (Join-Path $scratch "specs\$feature\spec.md") -Value "# Retro Calculator`n`nAgent-authored product framing written during the workshop." -Encoding UTF8
    & $initializer -ProjectRoot $scratch -FeatureRef $feature | Out-Null

    # A confirmed agenda opens the first technical topic, which is where the walk was interrupted. The
    # controller is built by the production writers off genuine typed-turn receipts: a hand-written
    # receipt id is refused by the controller reader, which is the W2 guard behaving correctly.
    . (Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\workshop-authority-store.ps1')
    $controllerPath = Join-Path $scratch "specs\$feature\lens-applicability.json"
    $questionPath = Join-Path $scratch '.specrew\handover\workshop-question.json'

    function Add-TypedReply {
        param(
            [Parameter(Mandatory)][ValidateSet('product-domain', 'agenda')][string]$Phase,
            [Parameter(Mandatory)][string]$Reply,
            [AllowNull()]$AgendaDigest,
            [AllowNull()]$AgendaBinding
        )
        $question = [ordered]@{
            schema = 'v3'; status = 'workshop-active'; scope = 'feature'; feature_ref = $feature
            iteration_number = ''; lens = 'product-domain'; phase = $Phase
            agenda_status = 'pending-confirmation'; question = 'Fixture question?'
            message_hash = (Get-SpecrewWorkshopAuthorityHash -Text ($Phase + '|' + $Reply))
            artifact_path = $controllerPath
        }
        if ($Phase -eq 'agenda') {
            $question['agenda_digest'] = [string]$AgendaDigest
            $question['agenda_binding'] = $AgendaBinding
        }
        [IO.File]::WriteAllText($questionPath, ($question | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
        return Write-SpecrewWorkshopAuthorityReceipt -ProjectRoot $scratch -Response $Reply -HostKind 'test' -SourceEvent 'UserPromptSubmit'
    }

    # Receipt first, records second: the store refuses a product-domain receipt once both records
    # already exist, because the typed answer has to precede what it authorizes.
    Assert-True ($null -ne (Add-TypedReply -Phase 'product-domain' -Reply 'A retro calculator demo for my kids.')) 'fixture mints a genuine product-domain receipt'
    Set-Content -LiteralPath (Join-Path $scratch "specs\$feature\workshop\product-domain.md") -Value '# Product domain' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch "specs\$feature\workshop\product-domain.yml") -Value 'depth: light' -Encoding UTF8

    $agendaJson = [ordered]@{
        selected = @([ordered]@{ lens = 'architecture-core'; depth = 'medium'; decision = 'Choose the shape.' })
        skipped  = @(
            [ordered]@{ lens = 'data-storage'; reason = 'No durable data.' }
            [ordered]@{ lens = 'ui-ux'; reason = 'Terminal only.' }
            [ordered]@{ lens = 'security-compliance'; reason = 'No secrets.' }
            [ordered]@{ lens = 'integration-api'; reason = 'No services.' }
            [ordered]@{ lens = 'devops-operations'; reason = 'No pipeline.' }
            [ordered]@{ lens = 'observability-resilience'; reason = 'No runtime targets.' }
            [ordered]@{ lens = 'component-design'; reason = 'Pipeline supplies it.' }
            [ordered]@{ lens = 'requirements-nfr'; reason = 'Demo only.' }
            [ordered]@{ lens = 'code-implementation'; reason = 'Conventions inherited.' }
        )
    } | ConvertTo-Json -Depth 6 -Compress

    $agendaWriter = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\confirm-workshop-agenda.ps1'
    & $agendaWriter -ProjectRoot $scratch -FeatureRef $feature -AgendaJson $agendaJson -RenderOnly | Out-Null
    $proposal = Get-Content -LiteralPath (Join-Path $scratch '.specrew\handover\workshop-agenda-proposal.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
    Assert-True ($null -ne (Add-TypedReply -Phase 'agenda' -Reply 'I approve the whole agenda.' -AgendaDigest $proposal.agenda_digest -AgendaBinding $proposal.agenda_binding)) 'fixture mints a genuine agenda receipt bound to the rendered agenda'
    & $agendaWriter -ProjectRoot $scratch -FeatureRef $feature -AgendaJson $agendaJson | Out-Null

    . (Join-Path $scratch 'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1')
    $lifecycle = Get-SpecrewWorkshopLifecycleState -ProjectRoot $scratch -FeatureRef $feature
    Assert-True ([string]$lifecycle.status -eq 'active' -and [string]$lifecycle.current_lens -eq 'architecture-core') 'fixture puts the workshop on its first technical topic'

    # Material work needs live Git state: a real repo whose changed set is the untracked feature files.
    Push-Location $scratch
    try {
        & git init --quiet 2>&1 | Out-Null
        & git -c user.email='t@t' -c user.name='t' commit --allow-empty -m 'scaffold' --quiet 2>&1 | Out-Null
    }
    finally { Pop-Location }

    function Invoke-ProviderStop {
        param([Parameter(Mandatory)][string]$AssistantText)
        $transcriptPath = Join-Path $scratch ('.specrew\runtime\t-' + [guid]::NewGuid().ToString('N') + '.jsonl')
        $line = [pscustomobject]@{
            type = 'assistant'
            message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $AssistantText }) }
        } | ConvertTo-Json -Depth 8 -Compress
        [IO.File]::WriteAllText($transcriptPath, $line + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        $priorModulePath = $env:SPECREW_MODULE_PATH
        $env:SPECREW_MODULE_PATH = $repoRoot
        try {
            Push-Location $scratch
            try { $out = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $provider --host-kind claude --source-event Stop --transcript-path $transcriptPath 2>&1) }
            finally { Pop-Location }
        }
        finally { $env:SPECREW_MODULE_PATH = $priorModulePath }
        return ($out -join "`n")
    }

    $lensQuestion = @'
Now we are on topic 1 of 1: architecture-core.

This topic decides the structural baseline for the retro calculator demo.

For pacing, choose one: 1) all at once, or 2) one by one. Which do you prefer?
'@
    $blocked = Invoke-ProviderStop -AssistantText $lensQuestion

    Assert-True ($blocked -match 'SPECREW-STOP-BLOCK') 'work outside the workshop notes still owes the packet: enforcement is unchanged'
    Assert-True ($blocked -match '(?i)design workshop is still open') 'the correction says the workshop is still open instead of only demanding a packet'
    Assert-True ($blocked -match "architecture-core") 'the correction names the topic the human is standing on'
    Assert-True ($blocked -match [regex]::Escape("specs/$feature/spec.md")) 'the correction names the exact work that cost the turn its workshop exemption'
    Assert-True ($blocked -match '(?i)asking the SAME workshop question again') 'the packet must not take the human''s place in the conversation with it'
    Assert-True ($blocked -match '(?i)do not open the next topic') 'the correction forbids skipping ahead while the question is unanswered'
    Assert-True ($blocked -match '(?i)specification is written after the workshop finishes') 'spec authoring during the workshop is named as premature rather than left implicit'
    Assert-True ($blocked -match '## What I Just Did') 'the five-heading packet is still required'
    Assert-True ($blocked -notmatch 'SPECREW-VERDICT-BOUNDARY: ') 'a non-boundary material stop still emits no boundary verdict marker'
    Assert-True ($blocked -notmatch '(?i)lens-applicability|controller|digest|material surface') 'the workshop-aware correction keeps machinery vocabulary out of the human-facing text'

    # The generic material directive must survive untouched where no workshop is open: this change is a
    # surface for the workshop case only, never a softening of ordinary material-work enforcement.
    Remove-Item -LiteralPath (Join-Path $scratch "specs\$feature") -Recurse -Force
    New-Item -ItemType Directory -Path (Join-Path $scratch 'src') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch 'src\calculator.js') -Value 'export const add = (a, b) => a + b;' -Encoding UTF8
    $noWorkshop = Invoke-ProviderStop -AssistantText 'I refactored the calculation engine and tidied the display formatter.'
    Assert-True ($noWorkshop -match 'SPECREW-STOP-BLOCK') 'ordinary material work still blocks with no workshop open'
    Assert-True ($noWorkshop -match '(?i)this Stop followed material work') 'the ordinary material directive is unchanged when no workshop is open'
    Assert-True ($noWorkshop -notmatch '(?i)design workshop is still open') 'the workshop-aware wording never fires without an active workshop'
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'workshop material packet language: all assertions pass' -ForegroundColor Green
