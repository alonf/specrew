# Regression test for B4F-007: the workshop resolve must select the feature whose INTAKE controller is
# open, not the feature the start context happens to name.
#
# The defect: .specrew/start-context.json carries the LIFECYCLE's feature, which after any completed
# feature is the PREVIOUS one - stale by construction from feature creation until the first boundary sync.
# The resolve selected from it, looked up a completed workshop (or an iteration absent under the new
# feature), and returned nothing active. Measured consequence: every SECOND and later feature in a project
# could not register a workshop question, so no receipt could mint and no lens could close. A project's
# FIRST feature worked, because there was no predecessor to name - which is why this survived months.
#
# WHY THIS TEST DRIVES THE RESOLVE INSTEAD OF WRITING workshop-question.json:
# every existing fixture for this area hand-writes .specrew/handover/workshop-question.json
# (conformance-detection, workshop-agenda-confirmation, workshop-material-packet-language,
# workshop-typed-turn-authority). That is exactly why no test noticed: they fabricate the artifact whose
# PRODUCTION is broken. This one never writes it, and asserts on what the resolve returns.
#
# WHY THERE IS A POSITIVE CONTROL IN THIS FILE:
# a test that sets up the stale ref and asserts "not active" passes just as happily when it never reached
# the function at all - and would join the fixtures that could not notice. Case 1 asserts that an OPEN
# feature resolves ACTIVE in the same run. If Case 1 fails, every other verdict here is void.

$ErrorActionPreference = 'Stop'
$script:Failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ("  PASS: {0}" -f $Message) }
    else { Write-Host ("  FAIL: {0}" -f $Message); $script:Failures++ }
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$providerPath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
$accessorPath = Join-Path $repoRoot 'scripts/internal/bootstrap/ProjectMetadataAccessor.ps1'

Write-Host 'workshop-resolve-prefers-open-feature'
Write-Host '  --- preconditions (printed, not assumed) ---'
Assert-True (Test-Path -LiteralPath $providerPath -PathType Leaf) 'provider source is present'
Assert-True (Test-Path -LiteralPath $accessorPath -PathType Leaf) 'metadata accessor is present'
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE: sources missing'; exit 1 }

# Extract the subject by AST rather than dot-sourcing the provider: the provider has a top-level argument
# parser and would RUN. Same technique, and same reason, as guard-exemptions-still-fire (DRIFT-199-I003-062).
$tokens = $null; $errors = $null
$providerAst = [System.Management.Automation.Language.Parser]::ParseFile($providerPath, [ref]$tokens, [ref]$errors)
Assert-True ($errors.Count -eq 0) 'provider source parses without error'
$fnAst = $providerAst.FindAll({
        param($n)
        $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $n.Name -eq 'Resolve-SpecrewWorkshopQuestionPause'
    }, $true) | Select-Object -First 1
Assert-True ($null -ne $fnAst) 'Resolve-SpecrewWorkshopQuestionPause is defined in the provider'
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE: subject not extractable'; exit 1 }

. $accessorPath
. ([scriptblock]::Create($fnAst.Extent.Text))
Assert-True ([bool](Get-Command Resolve-SpecrewWorkshopQuestionPause -ErrorAction SilentlyContinue)) 'subject function is loaded'
Assert-True ([bool](Get-Command Get-SpecrewWorkshopLifecycleState -ErrorAction SilentlyContinue)) 'lifecycle accessor is loaded'
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE: subject not loaded'; exit 1 }

# --- fixture: one COMPLETED feature and one OPEN intake feature, in one project ---
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('specrew-b4f007-' + [guid]::NewGuid().ToString('N'))
$doneRef = '100-completed-feature'
$openRef = '101-open-feature'
try {
    $bootstrapDir = Join-Path $repoRoot 'scripts/internal/bootstrap'
    New-Item -ItemType Directory -Path (Join-Path $fixture ('specs/' + $doneRef)) -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fixture ('specs/' + $openRef)) -Force | Out-Null

    # The completed feature: an AUTHORED spec (no sentinel) and a confirmed, fully-recorded controller.
    Set-Content -LiteralPath (Join-Path $fixture ("specs/$doneRef/spec.md")) -Encoding UTF8 -Value @(
        '# Feature Specification: 100-completed-feature'
        ''
        'Authored. This feature is past intake.'
    )
    $doneController = [ordered]@{
        schema_version        = '1.1'
        workshop_intake       = $true
        confirmation_required = $true
        agenda_contract       = 'complete-coverage-v1'
        human_turn_contract   = 'typed-turns-v1'
        agenda_status         = 'confirmed'
        selected              = @('architecture-core')
        agenda                = @{ 'architecture-core' = @{ depth = 'light' } }
        skipped               = @{}
        agenda_confirmation   = 'human-confirmed'
        agenda_confirmation_scope = 'lens-selection'
        agenda_turn_receipt   = 'receipt-done'
        workshop              = [ordered]@{
            'architecture-core' = [ordered]@{
                agenda = @('q1'); decision = 'decided'; depth = 'light'; moved_on = $true
                confirmation = 'human-confirmed'; confirmation_scope = 'lens-question'
                human_turn_receipt = 'receipt-done'
            }
        }
    }
    $doneController | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath (Join-Path $fixture ("specs/$doneRef/lens-applicability.json")) -Encoding UTF8

    # The open feature: the governed not-yet-authored stub and the pre-agenda controller, exactly as
    # create-governed-feature.ps1 leaves them.
    Set-Content -LiteralPath (Join-Path $fixture ("specs/$openRef/spec.md")) -Encoding UTF8 -Value @(
        '<!-- specrew:spec-not-yet-authored -->'
        '# Feature Specification: 101-open-feature'
        ''
        '**Status**: not yet authored'
    )
    $openController = [ordered]@{
        schema_version        = '1.1'
        workshop_intake       = $true
        confirmation_required = $true
        agenda_contract       = 'complete-coverage-v1'
        human_turn_contract   = 'typed-turns-v1'
        agenda_status         = 'pending-confirmation'
        selected              = @()
        agenda                = @{}
        skipped               = @{}
        agenda_confirmation   = 'pending'
        agenda_confirmation_scope = 'lens-selection'
        agenda_turn_receipt   = 'pending'
        workshop              = @{}
    }
    $openController | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath (Join-Path $fixture ("specs/$openRef/lens-applicability.json")) -Encoding UTF8

    $ask = 'Which of these should the first release optimise for?'

    Write-Host '  --- CASE 1: POSITIVE CONTROL - the open feature must resolve ACTIVE ---'
    $c1 = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $fixture -BootstrapDir $bootstrapDir `
        -ActiveFeatureRef $openRef -ActiveIterationNumber $null -HasActiveLifecycleBoundary $false `
        -StartContextState 'readable' -LastAssistantText $ask -HasPendingVerdict $false `
        -WorkshopFeatureCandidates @($openRef)
    Assert-True ($null -ne $c1 -and [bool]$c1.valid) 'CONTROL: an open intake workshop resolves valid'
    Assert-True ($null -ne $c1 -and [string]$c1.feature_ref -eq $openRef) 'CONTROL: it resolves to the open feature'
    $controlHeld = ($null -ne $c1 -and [bool]$c1.valid)
    if (-not $controlHeld) {
        Write-Host '  INCONCLUSIVE: the positive control did not hold, so every verdict below is void.'
        exit 1
    }

    Write-Host '  --- CASE 2: THE REGRESSION - a STALE ref naming the completed feature ---'
    # This is the shape that shipped: the start context still names the previous, completed feature, and
    # even carries its iteration number, while the workshop is open on a different feature.
    $c2 = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $fixture -BootstrapDir $bootstrapDir `
        -ActiveFeatureRef $doneRef -ActiveIterationNumber '003' -HasActiveLifecycleBoundary $true `
        -StartContextState 'readable' -LastAssistantText $ask -HasPendingVerdict $false `
        -WorkshopFeatureCandidates @($openRef)
    Assert-True ($null -ne $c2 -and [bool]$c2.valid) 'a stale ref no longer blocks the open workshop'
    Assert-True ($null -ne $c2 -and [string]$c2.feature_ref -eq $openRef) 'it resolves to the OPEN feature, not the stale one'
    Assert-True ($null -ne $c2 -and [string]$c2.scope -eq 'feature') 'and at FEATURE scope, not the stale iteration scope'

    Write-Host '  --- CASE 3: the resolve VALIDATES its candidate rather than trusting it ---'
    # A candidate whose workshop is complete must not be activated just because it was offered.
    $c3 = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $fixture -BootstrapDir $bootstrapDir `
        -ActiveFeatureRef $doneRef -ActiveIterationNumber '003' -HasActiveLifecycleBoundary $true `
        -StartContextState 'readable' -LastAssistantText $ask -HasPendingVerdict $false `
        -WorkshopFeatureCandidates @($doneRef)
    Assert-True ($null -ne $c3 -and -not [bool]$c3.valid) 'a COMPLETED feature offered as a candidate is not activated'

    Write-Host '  --- CASE 4: NEGATIVE CONTROL - the test can still fail ---'
    # With no candidate the pre-fix behaviour is preserved exactly: a stale ref resolves nothing valid.
    # If this ever passes as valid, the fix has started inventing workshops rather than finding them.
    $c4 = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $fixture -BootstrapDir $bootstrapDir `
        -ActiveFeatureRef $doneRef -ActiveIterationNumber '003' -HasActiveLifecycleBoundary $true `
        -StartContextState 'readable' -LastAssistantText $ask -HasPendingVerdict $false `
        -WorkshopFeatureCandidates @()
    Assert-True ($null -ne $c4 -and -not [bool]$c4.valid) 'with no open workshop offered, nothing is resolved'

    Write-Host '  --- CASE 5: ambiguity is NOT guessed at ---'
    # Two open intake workshops cannot tell us which one this turn belongs to. Falling back is correct;
    # picking one would manufacture a binding the human never made.
    $c5 = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $fixture -BootstrapDir $bootstrapDir `
        -ActiveFeatureRef $doneRef -ActiveIterationNumber '003' -HasActiveLifecycleBoundary $true `
        -StartContextState 'readable' -LastAssistantText $ask -HasPendingVerdict $false `
        -WorkshopFeatureCandidates @($openRef, '102-another-open')
    Assert-True ($null -ne $c5 -and -not [bool]$c5.valid) 'two open workshops are ambiguous and are not guessed at'

    # --- fixture 2: a SECOND feature whose own workshop is genuinely ACTIVE ---
    # It is built in the shape CASE 1 already proved active, so no authority receipt is fabricated. An
    # active CONFIRMED agenda requires a receipt that validates against the real hook-owned store, and
    # writing one here would be the same fixture defect this file exists to avoid - the precondition
    # assertion below is what caught that on the first attempt.
    $otherRef = '102-other-active-feature'
    New-Item -ItemType Directory -Path (Join-Path $fixture ('specs/' + $otherRef)) -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $fixture ("specs/$otherRef/spec.md")) -Encoding UTF8 -Value @(
        '<!-- specrew:spec-not-yet-authored -->'
        '# Feature Specification: 102-other-active-feature'
        ''
        '**Status**: not yet authored'
    )
    $openController | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath (Join-Path $fixture ("specs/$otherRef/lens-applicability.json")) -Encoding UTF8

    Write-Host '  --- CASE 7: a candidate must NOT displace the start context''s OWN active workshop ---'
    # PRECONDITION: the second workshop must itself be active, or this case asserts nothing.
    $otherState = Get-SpecrewWorkshopLifecycleState -ProjectRoot $fixture -FeatureRef $otherRef
    Assert-True ($null -ne $otherState -and [string]$otherState.status -eq 'active') 'PRECONDITION: the second workshop is genuinely active'

    # The start context names a feature whose workshop IS active, and a DIFFERENT feature is offered as the
    # intake candidate. Nothing can tell which one the human is answering. Binding a typed reply to the
    # wrong question is worse than resolving nothing, so this must fall through rather than pick - the same
    # refusal the fix already makes between two candidates, applied between the candidate and the start
    # context. The candidate list is an input to this function, so the contract must hold for whatever it
    # is given, not only for lists production happens to produce.
    $c7 = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $fixture -BootstrapDir $bootstrapDir `
        -ActiveFeatureRef $otherRef -ActiveIterationNumber $null -HasActiveLifecycleBoundary $false `
        -StartContextState 'readable' -LastAssistantText $ask -HasPendingVerdict $false `
        -WorkshopFeatureCandidates @($openRef)
    Assert-True ($null -ne $c7 -and -not [bool]$c7.valid) 'two active workshops on different features are ambiguous, not picked'
    Assert-True ($null -ne $c7 -and [string]$c7.feature_ref -ne $openRef) 'the intake candidate does NOT displace the active workshop the start context names'
    Assert-True ($null -ne $c7 -and [string]$c7.reason -eq 'workshop-resolve-ambiguous') 'and the refusal names why, rather than looking like an ordinary miss'

    Write-Host '  --- CASE 8: the ambiguity guard must not weaken the fix ---'
    # The stale case from CASE 2 has a NON-active start-context path, so there is no ambiguity and the
    # candidate must still win. If this regresses, the guard has undone the thing it is guarding.
    $c8 = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $fixture -BootstrapDir $bootstrapDir `
        -ActiveFeatureRef $doneRef -ActiveIterationNumber '003' -HasActiveLifecycleBoundary $true `
        -StartContextState 'readable' -LastAssistantText $ask -HasPendingVerdict $false `
        -WorkshopFeatureCandidates @($openRef)
    Assert-True ($null -ne $c8 -and [bool]$c8.valid) 'a non-active start-context path still yields to the candidate'
    Assert-True ($null -ne $c8 -and [string]$c8.feature_ref -eq $openRef) 'and still resolves the open feature'

    Write-Host '  --- CASE 6: the call site actually supplies candidates (both call sites) ---'
    # The parameter is useless if nothing passes it, and the provider calls the resolve TWICE. A fix
    # applied to the first call site only would be silently half-applied - the two-writers family.
    $callLines = @([IO.File]::ReadAllLines($providerPath) |
            Where-Object { $_ -like '*Resolve-SpecrewWorkshopQuestionPause -ProjectRoot*' })
    $withParam = @($callLines | Where-Object { $_ -like '*-WorkshopFeatureCandidates*' })
    Assert-True ($callLines.Count -ge 1) 'the provider calls the resolve at least once'
    Assert-True ($callLines.Count -eq $withParam.Count) 'EVERY call site passes -WorkshopFeatureCandidates'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host ''
if ($script:Failures -gt 0) {
    Write-Host ("FAILED: {0} assertion(s)" -f $script:Failures)
    exit 1
}
Write-Host 'OK: workshop-resolve-prefers-open-feature'
exit 0
