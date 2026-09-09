# Regression test for B4F-041 / B4F-035 - fix 1 of the beta4 reopen: the post-agenda repair trap.
#
# THE TRAP. confirm-workshop-agenda.ps1 CLEARS the controller's `workshop` map when it writes the confirmed
# agenda, so a healthy post-agenda controller shows an empty topic list with `product-domain` nowhere in it
# (DRIFT-199-I003-092). Three crews in a row read that emptiness as silent data loss. One left it alone, one
# was talked out of acting, and one re-ran confirm-workshop-lens.ps1 for `product-domain` to "restore" the
# entry - which wrote a key that is not in `selected` and left the whole feature reading
# `workshop-record-not-selected`, so every lens stopped. The outcome depended on the agent's discipline, and
# discipline is not a control.
#
# THE FIX HAS TWO HALVES AND THEY ARE TESTED TOGETHER BECAUSE THEY SHIP TOGETHER:
#   (a) the READER tolerates the intake key, so already-corrupted beta3 controllers read valid again on
#       update with no repair run to perform, and surfaces `intake_completed` from the durable records so the
#       empty list is no longer the only thing on screen;
#   (b) the WRITER refuses to reopen the intake topic once the agenda is confirmed, so the corrupting write
#       cannot happen again.
#
# WHY THE FIXTURE IS THE FIELD STATE AND NOT A POSED ONE. tests/fixtures/beta4-agenda-clearing/ was copied
# out of the failed beta4-mdlink walk before the project was discarded. The batch's most quoted finding is
# "the fixture wrote the precondition the product denies" - a control proved against a state only the test
# could create. This state was written by the product, in the field, before anyone knew it would be needed.
#
# WHY CASE 1 NAMES ITS PATH. A control that reports "intake is complete" without saying WHERE that came from
# can certify a path it never took (B4F-028). Case 1 asserts the value came from the two records on disk
# WHILE the controller's `workshop` map is empty - so the map cannot have supplied it.

$ErrorActionPreference = 'Stop'
$script:Failures = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host ("  PASS: {0}" -f $Message) }
    else { Write-Host ("  FAIL: {0}" -f $Message); $script:Failures++ }
}

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$accessorPath = Join-Path $repoRoot 'scripts/internal/bootstrap/ProjectMetadataAccessor.ps1'
$storePath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
$writerPath = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1'
$catalogPath = Join-Path $repoRoot '.specify/extensions/specrew-speckit/knowledge/design-lenses/index.yml'
$fixturePath = Join-Path $repoRoot 'tests/fixtures/beta4-agenda-clearing/001-mdlink-checker'
$featureRef = '001-mdlink-checker'

Write-Host 'workshop-intake-completion-survives-agenda'
Write-Host '  --- preconditions (printed, not assumed) ---'
foreach ($required in @($accessorPath, $storePath, $writerPath, $catalogPath, $fixturePath)) {
    Assert-True (Test-Path -LiteralPath $required) ("present: {0}" -f ($required.Substring($repoRoot.Length + 1) -replace '\\', '/'))
}
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE: sources or fixture missing'; exit 1 }

. $storePath
. $accessorPath
Assert-True ([bool](Get-Command Get-SpecrewWorkshopLifecycleState -ErrorAction SilentlyContinue)) 'lifecycle accessor is loaded'
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE: subject not loaded'; exit 1 }

$script:Roots = New-Object System.Collections.Generic.List[string]

function New-FixtureProject {
    # The preserved fixture is the FEATURE directory only. The strict accessor also needs the lens catalog and
    # the agenda receipt the controller cites, so those are supplied from the repo's own copies rather than
    # invented - the controller's stored agenda digest has to recompute against the real catalog, and Case 1
    # would be meaningless if this helper quietly relaxed that.
    #
    # -WithIntakeReceipt exists because of what the mutation proof found. Without a `product-domain` receipt,
    # removing the guard does not make the corrupting write happen - the writer simply refuses one check
    # later, at the typed-reply lookup. So "the controller is byte-unchanged" passed in the mutant too, and
    # the loudest assertion in Case 5 was proving nothing about the guard. The field project HAD that receipt:
    # its intake topic was genuinely closed. Case 5 now carries it, so the guard is the only thing standing
    # between the writer and the write.
    param([switch] $WithIntakeReceipt)
    $root = Join-Path ([IO.Path]::GetTempPath()) ('specrew-intake-' + [guid]::NewGuid().ToString('n').Substring(0, 10))
    $script:Roots.Add($root) | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'specs') -Force | Out-Null
    Copy-Item -LiteralPath $fixturePath -Destination (Join-Path $root "specs/$featureRef") -Recurse -Force

    $catalogDir = Join-Path $root '.specify/extensions/specrew-speckit/knowledge/design-lenses'
    New-Item -ItemType Directory -Path $catalogDir -Force | Out-Null
    Copy-Item -LiteralPath $catalogPath -Destination (Join-Path $catalogDir 'index.yml') -Force

    $controller = Get-Content -LiteralPath (Join-Path $root "specs/$featureRef/lens-applicability.json") -Raw | ConvertFrom-Json -Depth 20
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
    $receipts = @(
        ([ordered]@{
            schema_version     = '1'
            feature_ref        = $featureRef
            phase              = 'agenda'
            receipt_id         = [string]$controller.agenda_turn_receipt
            confirmation       = 'human-confirmed'
            confirmation_scope = 'lens-selection'
            agenda_digest      = [string]$controller.agenda_digest
        } | ConvertTo-Json -Depth 6 -Compress)
    )
    if ($WithIntakeReceipt) {
        $receipts += ([ordered]@{
            schema_version     = '1'
            feature_ref        = $featureRef
            phase              = 'product-domain'
            lens               = 'product-domain'
            receipt_id         = ('a' * 64)
            confirmation       = 'human-confirmed'
            confirmation_scope = 'lens-question'
        } | ConvertTo-Json -Depth 6 -Compress)
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/runtime/workshop-authority.jsonl'), (($receipts -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
    return $root
}

function Get-ControllerPath { param([string]$Root) Join-Path $Root "specs/$featureRef/lens-applicability.json" }

function Add-WorkshopRecord {
    # Writes a lens entry into the controller's `workshop` map - the exact shape the unsanctioned repair
    # produced in the field.
    param([string]$Root, [string]$Lens)
    $path = Get-ControllerPath -Root $Root
    $controller = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -Depth 20
    $controller.workshop | Add-Member -NotePropertyName $Lens -NotePropertyValue ([pscustomobject]@{
            agenda             = @('what are we building and for whom')
            decision           = 'a link checker for the docs folder'
            depth              = 'full'
            moved_on           = $true
            confirmation       = 'human-confirmed'
            confirmation_scope = 'lens-question'
        }) -Force
    [IO.File]::WriteAllText($path, ($controller | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
}

function Invoke-LensWriter {
    # Returns the refusal text, or $null when the writer did not refuse.
    param([string]$Root, [string]$Lens)
    try {
        & $writerPath -ProjectRoot $Root -FeatureRef $featureRef -Lens $Lens `
            -Decision 'a decision' -Depth 'full' -Agenda @('a question') 2>&1 | Out-Null
        return $null
    }
    catch { return [string]$_.Exception.Message }
}

try {
    # === Case 1 - POSITIVE CONTROL, AND IT NAMES ITS PATH =====================================
    Write-Host '  --- Case 1: the preserved field state reports intake complete, from the records ---'
    $root1 = New-FixtureProject
    $controller1 = Get-Content -LiteralPath (Get-ControllerPath -Root $root1) -Raw | ConvertFrom-Json -Depth 20
    $mapKeys1 = @($controller1.workshop.PSObject.Properties | ForEach-Object { [string]$_.Name })
    Assert-True ($mapKeys1.Count -eq 0) 'the fixture controller carries an EMPTY workshop map (the state the crews read as data loss)'

    $state1 = Get-SpecrewWorkshopLifecycleState -ProjectRoot $root1 -FeatureRef $featureRef
    Assert-True ($state1.status -eq 'active' -and [bool]$state1.valid) 'the post-agenda controller reads active and valid'
    Assert-True (@($state1.completed).Count -eq 0) 'completed is still EMPTY - the technical-lens list is untouched by this fix'
    Assert-True (@($state1.remaining) -join ',' -ceq 'architecture-core,code-implementation') 'remaining is unchanged'
    Assert-True ([bool]$state1.intake_completed) 'intake_completed is TRUE - the intake topic is reported complete'
    Assert-True ([string]$state1.intake_evidence -clike '*workshop/product-domain.md*') 'intake_evidence NAMES workshop/product-domain.md'
    Assert-True ([string]$state1.intake_evidence -clike '*workshop/product-domain.yml*') 'intake_evidence NAMES workshop/product-domain.yml'

    # === Case 2 - NEGATIVE CONTROL: the field is derived, not a constant ======================
    Write-Host '  --- Case 2: remove one record and intake completion goes away ---'
    $root2 = New-FixtureProject
    Remove-Item -LiteralPath (Join-Path $root2 "specs/$featureRef/workshop/product-domain.md") -Force
    $state2 = Get-SpecrewWorkshopLifecycleState -ProjectRoot $root2 -FeatureRef $featureRef
    Assert-True (-not [bool]$state2.intake_completed) 'intake_completed is FALSE when a record is missing'
    Assert-True ($null -eq $state2.intake_evidence) 'intake_evidence is null when there is nothing to name'
    Assert-True ($state2.status -eq 'active') 'and the rest of the state is unaffected by the missing record'

    # === Case 3 - THE READER HEALS AN ALREADY-CORRUPTED CONTROLLER ============================
    Write-Host '  --- Case 3: the corrupted beta3 shape reads VALID under the tolerance ---'
    $root3 = New-FixtureProject
    Add-WorkshopRecord -Root $root3 -Lens 'product-domain'
    $state3 = Get-SpecrewWorkshopLifecycleState -ProjectRoot $root3 -FeatureRef $featureRef
    Assert-True ([string]$state3.reason -cne 'workshop-record-not-selected') 'the intake key no longer invalidates the controller'
    Assert-True ([bool]$state3.valid -and $state3.status -eq 'active') 'the project the unsanctioned repair bricked reads valid again, with no repair run'
    Assert-True (@($state3.remaining) -join ',' -ceq 'architecture-core,code-implementation') 'and the technical agenda is unchanged by the tolerated key'

    # === Case 4 - THE TOLERANCE IS EXACTLY ONE KEY WIDE (the scoping assertion) ===============
    Write-Host '  --- Case 4: a TECHNICAL lens outside the agenda still invalidates ---'
    $root4 = New-FixtureProject
    Add-WorkshopRecord -Root $root4 -Lens 'ui-ux'
    $state4 = Get-SpecrewWorkshopLifecycleState -ProjectRoot $root4 -FeatureRef $featureRef
    Assert-True ([string]$state4.reason -ceq 'workshop-record-not-selected') 'a technical lens outside selected still reads workshop-record-not-selected'
    Assert-True (-not [bool]$state4.valid) 'and the controller is still invalid, so the check kept its job'

    # === Case 5 - THE GUARD: healthy post-agenda intake close is REFUSED ======================
    Write-Host '  --- Case 5: the writer refuses to reopen the intake topic, and says why ---'
    # WITH the intake receipt: everything downstream of the guard would let this write through, so the guard
    # is the only thing that stops it. That is what makes the byte-unchanged assertion below mean something.
    $root5 = New-FixtureProject -WithIntakeReceipt
    $before5 = (Get-FileHash (Get-ControllerPath -Root $root5) -Algorithm SHA256).Hash
    $refusal5 = Invoke-LensWriter -Root $root5 -Lens 'product-domain'
    Assert-True ($null -ne $refusal5) 'the writer refuses rather than writing the key that corrupts the controller'
    Assert-True ([string]$refusal5 -clike '*already complete*') 'the refusal says the discussion is already complete'
    Assert-True ([string]$refusal5 -clike '*workshop/product-domain.md*') 'the refusal NAMES the durable record'
    Assert-True ([string]$refusal5 -clike '*normal state*') 'the refusal states that the empty topic list is normal, not lost work'
    Assert-True ([string]$refusal5 -clike '*architecture-core*') 'the refusal names the next agreed topic - a legal move'
    $after5 = (Get-FileHash (Get-ControllerPath -Root $root5) -Algorithm SHA256).Hash
    Assert-True ($before5 -eq $after5) 'THE CONTROLLER IS BYTE-UNCHANGED - the corrupting write did not happen'

    # === Case 6 - THE RESIDUAL: confirmed agenda, records absent ==============================
    Write-Host '  --- Case 6: the deleted-records residual refuses without naming a remedy that refuses ---'
    $root6 = New-FixtureProject
    Remove-Item -LiteralPath (Join-Path $root6 "specs/$featureRef/workshop/product-domain.md") -Force
    Remove-Item -LiteralPath (Join-Path $root6 "specs/$featureRef/workshop/product-domain.yml") -Force
    $before6 = (Get-FileHash (Get-ControllerPath -Root $root6) -Algorithm SHA256).Hash
    $refusal6 = Invoke-LensWriter -Root $root6 -Lens 'product-domain'
    Assert-True ($null -ne $refusal6) 'the writer refuses here too'
    Assert-True ([string]$refusal6 -clike '*cannot be reopened*') 'the refusal states the topic cannot be reopened after the agenda is confirmed'
    Assert-True ([string]$refusal6 -clike '*product-domain.md*' -and [string]$refusal6 -clike '*product-domain.yml*') 'the refusal names BOTH missing records'
    Assert-True ([string]$refusal6 -clike '*has not been confirmed yet*') 'the refusal states the governed repair does not cover a confirmed agenda, instead of sending the reader to it'
    $after6 = (Get-FileHash (Get-ControllerPath -Root $root6) -Algorithm SHA256).Hash
    # Deliberately NOT claimed as proof of the guard: with the records gone the writer would stop downstream
    # anyway. Case 5 is where the write is pinned; here it is a companion invariant, and its wording says so.
    Assert-True ($before6 -eq $after6) 'nothing is written on this path either (a companion invariant - Case 5 is what pins the write)'

    # === Case 7 - THE GUARD DOES NOT TOUCH THE PRE-AGENDA PATH ================================
    Write-Host '  --- Case 7: a pre-agenda intake close is not what this guard stops ---'
    $root7 = New-FixtureProject
    $pending = [ordered]@{
        schema_version            = '1.1'
        workshop_intake           = $true
        confirmation_required     = $true
        agenda_contract           = 'complete-coverage-v1'
        human_turn_contract       = 'typed-turns-v1'
        agenda_status             = 'pending-confirmation'
        selected                  = @()
        agenda                    = [ordered]@{}
        skipped                   = [ordered]@{}
        agenda_confirmation       = 'pending'
        agenda_confirmation_scope = 'lens-selection'
        agenda_turn_receipt       = 'pending'
        workshop                  = [ordered]@{}
    }
    [IO.File]::WriteAllText((Get-ControllerPath -Root $root7), ($pending | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
    $refusal7 = Invoke-LensWriter -Root $root7 -Lens 'product-domain'
    Assert-True ($null -ne $refusal7) 'the pre-agenda close still stops (no receipt has been minted in this fixture)'
    # Positive, not just an absence: the pre-agenda close reaches the RECEIPT check, which is downstream of the
    # guard. Asserting only that two strings are missing would pass just as happily if it had failed earlier.
    Assert-True ([string]$refusal7 -clike '*No typed reply from you is on record*') 'and it stops at the typed-reply check, which is DOWNSTREAM of the guard - so the guard let it through'
    Assert-True ([string]$refusal7 -cnotlike '*already complete*') 'not on the guard - the pre-agenda path is untouched by it'
    Assert-True ([string]$refusal7 -cnotlike '*cannot be reopened*') 'and not on the residual branch either'

    # === Case 8 - THE TECHNICAL REFUSAL NAMES HOW THE AGENDA CHANGES ==========================
    Write-Host '  --- Case 8: a technical lens outside the agenda is told what can be done about it ---'
    $root8 = New-FixtureProject
    $refusal8 = Invoke-LensWriter -Root $root8 -Lens 'ui-ux'
    Assert-True ($null -ne $refusal8) 'a lens outside the agreed topics is refused'
    Assert-True ([string]$refusal8 -clike '*architecture-core, code-implementation*') 'the refusal lists the agreed topics'
    Assert-True ([string]$refusal8 -clike '*fixed once it has been confirmed*') 'the refusal says how the agenda changes: it does not, once confirmed'
    Assert-True ([string]$refusal8 -clike '*nearest agreed topic*') 'and it names what to do with the decision instead'
}
finally {
    foreach ($root in $script:Roots) {
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ($script:Failures -gt 0) {
    Write-Host ("workshop-intake-completion-survives-agenda: {0} FAILED" -f $script:Failures)
    exit 1
}
Write-Host 'workshop-intake-completion-survives-agenda: all cases passed'
exit 0
