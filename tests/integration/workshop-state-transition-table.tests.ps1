[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function New-PendingController {
    return [pscustomobject]@{
        schema_version = '1.1'
        workshop_intake = $true
        confirmation_required = $true
        agenda_contract = 'complete-coverage-v1'
        human_turn_contract = 'typed-turns-v1'
        agenda_status = 'pending-confirmation'
        selected = @()
        agenda = [pscustomobject]@{}
        skipped = [pscustomobject]@{}
        agenda_confirmation = 'pending'
        agenda_confirmation_scope = 'lens-selection'
        agenda_turn_receipt = 'pending'
        workshop = [pscustomobject]@{}
    }
}

function Copy-Controller {
    param([Parameter(Mandatory)][object]$Controller)
    return $Controller | ConvertTo-Json -Depth 20 | ConvertFrom-Json -Depth 20
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$authoritySource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\workshop-authority-store.ps1'
$authorityMirror = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\workshop-authority-store.ps1'
$repairSource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\repair-workshop-controller-state.ps1'
$repairMirror = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\repair-workshop-controller-state.ps1'
$manifestPath = Join-Path $repoRoot 'Specrew.psd1'

Assert-True ((Get-Content -LiteralPath $authoritySource -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $authorityMirror -Raw -Encoding UTF8)) 'workshop authority source and deployed mirror are byte-identical'
Assert-True ((Get-Content -LiteralPath $repairSource -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $repairMirror -Raw -Encoding UTF8)) 'workshop repair source and deployed mirror are byte-identical'
Assert-True ((Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8) -match [regex]::Escape('extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1')) 'module FileList ships the governed workshop repair surface'

. $authoritySource

$pendingEmpty = New-PendingController
$pendingProduct = Copy-Controller $pendingEmpty
$pendingProduct.workshop | Add-Member -NotePropertyName 'product-domain' -NotePropertyValue ([pscustomobject]@{ moved_on = $true })
$pendingTechnical = Copy-Controller $pendingEmpty
$pendingTechnical.workshop | Add-Member -NotePropertyName 'architecture-core' -NotePropertyValue ([pscustomobject]@{ moved_on = $true })
$pendingSelected = Copy-Controller $pendingEmpty
$pendingSelected.selected = @('architecture-core')
$pendingCoverage = Copy-Controller $pendingEmpty
$pendingCoverage.agenda | Add-Member -NotePropertyName 'architecture-core' -NotePropertyValue ([pscustomobject]@{ depth = 'light'; decision = 'Choose structure.' })
$confirmedIncomplete = Copy-Controller $pendingEmpty
$confirmedIncomplete.agenda_status = 'confirmed'
$confirmedIncomplete.agenda_confirmation = 'human-confirmed'
$confirmedComplete = Copy-Controller $confirmedIncomplete
$confirmedComplete.selected = @('architecture-core')
$confirmedComplete.agenda | Add-Member -NotePropertyName 'architecture-core' -NotePropertyValue ([pscustomobject]@{ depth = 'light'; decision = 'Choose structure.' })

$states = [ordered]@{
    'missing'                    = $null
    'pending-empty'              = $pendingEmpty
    'pending-product-projection' = $pendingProduct
    'pending-technical-record'   = $pendingTechnical
    'pending-selected'           = $pendingSelected
    'pending-coverage'           = $pendingCoverage
    'confirmed-incomplete'       = $confirmedIncomplete
    'confirmed-complete'         = $confirmedComplete
}
$operations = @('initialize', 'read', 'render-agenda', 'confirm-agenda', 'confirm-lens', 'request-repair', 'apply-repair')
$allowedCells = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($cell in @(
    'missing|initialize',
    'pending-empty|read', 'pending-empty|render-agenda', 'pending-empty|confirm-agenda',
    'pending-product-projection|read', 'pending-product-projection|render-agenda', 'pending-product-projection|confirm-agenda',
    'pending-technical-record|request-repair', 'pending-technical-record|apply-repair',
    'pending-selected|request-repair', 'pending-selected|apply-repair',
    'pending-coverage|request-repair', 'pending-coverage|apply-repair',
    'confirmed-complete|read',
    # FR-027 (T018): a lens closes only from a confirmed, complete agenda - the one new allowed cell.
    'confirmed-complete|confirm-lens'
)) { $null = $allowedCells.Add($cell) }

$evaluatedCells = 0
foreach ($stateEntry in $states.GetEnumerator()) {
    foreach ($operation in $operations) {
        $result = Resolve-SpecrewWorkshopStateTransition -Controller $stateEntry.Value -Operation $operation
        $cell = '{0}|{1}' -f $stateEntry.Key, $operation
        $expected = $allowedCells.Contains($cell)
        Assert-True ($result.allowed -eq $expected) "transition cell $cell is $(@('refused','allowed')[[int]$expected])"
        $evaluatedCells++
    }
}
Assert-True ($evaluatedCells -eq 56) 'finite workshop table evaluates all 8 states x 7 operations (56 cells)'

# The transition contract is not a test-only model. Pin every production consumer whose drift would reopen the
# illegal-transition class, plus the hook capture that makes repair authority genuinely human-authored.
$consumerPins = [ordered]@{
    'extensions\specrew-speckit\scripts\initialize-workshop-controller-state.ps1' = "-Operation 'initialize'"
    'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1' = "-Operation 'read'"
    'extensions\specrew-speckit\scripts\confirm-workshop-agenda.ps1' = 'Resolve-SpecrewWorkshopStateTransition'
    'extensions\specrew-speckit\scripts\confirm-workshop-lens.ps1' = "-Operation 'confirm-lens'"
    'extensions\specrew-speckit\scripts\repair-workshop-controller-state.ps1' = 'Resolve-SpecrewWorkshopStateTransition'
    'scripts\internal\bootstrap\HandoverStore.ps1' = 'Write-SpecrewWorkshopRepairAuthorization'
}
foreach ($pin in $consumerPins.GetEnumerator()) {
    $content = Get-Content -LiteralPath (Join-Path $repoRoot $pin.Key) -Raw -Encoding UTF8
    Assert-True ($content.Contains([string]$pin.Value)) "production consumer $($pin.Key) uses the shared transition/authority control"
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-workshop-repair-' + [guid]::NewGuid().ToString('N'))
try {
    $featureRef = '001-repair-fixture'
    $featureRoot = Join-Path $scratch "specs\$featureRef"
    $projectAuthority = Join-Path $scratch '.specify\extensions\specrew-speckit\scripts\workshop-authority-store.ps1'
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $projectAuthority) -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $featureRoot 'workshop') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureRoot 'spec.md') -Value '# Repair fixture' -Encoding UTF8
    Copy-Item -LiteralPath $authoritySource -Destination $projectAuthority -Force
    $productMarkdownPath = Join-Path $featureRoot 'workshop\product-domain.md'
    $productStructuredPath = Join-Path $featureRoot 'workshop\product-domain.yml'
    [IO.File]::WriteAllText($productMarkdownPath, "# Product domain`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($productStructuredPath, "depth: light`n", [Text.UTF8Encoding]::new($false))
    $productMarkdownHash = (Get-FileHash -LiteralPath $productMarkdownPath -Algorithm SHA256).Hash
    $productStructuredHash = (Get-FileHash -LiteralPath $productStructuredPath -Algorithm SHA256).Hash

    $repairState = Copy-Controller $pendingTechnical
    $statePath = Join-Path $featureRoot 'lens-applicability.json'
    [IO.File]::WriteAllText($statePath, (($repairState | ConvertTo-Json -Depth 20) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    $beforeStateBytes = [IO.File]::ReadAllBytes($statePath)

    $proposal = & $repairSource -ProjectRoot $scratch -FeatureRef $featureRef -Request -PassThru
    Assert-True ([string]$proposal.state -eq 'awaiting-human-authorization' -and [string]$proposal.proposal_id -match '^[a-f0-9]{64}$') 'repair request creates an immutable proposal without changing workshop state'
    Assert-True ([string]$proposal.message -notmatch '(?i)controller|plumbing|lens-applicability') 'human repair proposal uses calm project language without internal machinery or fault attribution'
    Assert-True ([Convert]::ToBase64String($beforeStateBytes) -eq [Convert]::ToBase64String([IO.File]::ReadAllBytes($statePath))) 'repair request preserves workshop state byte-for-byte'

    # T019 (FR-028): this used to match the bare machine token 'workshop-repair-human-authorization-missing'.
    # The REFUSAL is unchanged in strength - the repair is still refused without the typed phrase - but it now
    # has a reader: what was received, the exact phrase, and the standing reassurance. Asserting the contract
    # rather than the token is what keeps the message from silently regressing to a label.
    $noAuthorityRefused = $false
    $noAuthorityMessage = ''
    try { & $repairSource -ProjectRoot $scratch -FeatureRef $featureRef -Apply | Out-Null }
    catch { $noAuthorityMessage = [string]$_.Exception.Message; $noAuthorityRefused = $true }
    Assert-True $noAuthorityRefused 'repair apply refuses before typed human authorization'
    Assert-True ($noAuthorityMessage -match 'No typed authorization is on record for the repair proposed for') 'the refusal says plainly what is missing, and for which feature, rather than throwing a machine token'
    Assert-True ($noAuthorityMessage -match 'type: approved for workshop repair') 'and names the exact phrase to type'
    Assert-True ($noAuthorityMessage -notmatch '(?i)controller|lens-applicability|governed writer') 'in project language, with no machinery vocabulary'

    . $projectAuthority
    $wrongReply = Write-SpecrewWorkshopRepairAuthorization -ProjectRoot $scratch -Response 'yes, repair it' -HostKind 'test' -SourceEvent 'UserPromptSubmit'
    Assert-True ($null -eq $wrongReply) 'ordinary assent cannot authorize a workshop repair'
    $authorization = Write-SpecrewWorkshopRepairAuthorization -ProjectRoot $scratch -Response 'approved for workshop repair' -HostKind 'test' -SourceEvent 'UserPromptSubmit'
    Assert-True ($null -ne $authorization -and [string]$authorization.proposal_id -eq [string]$proposal.proposal_id) 'exact typed human reply authorizes only the bound repair proposal'

    [IO.File]::AppendAllText($statePath, ' ', [Text.UTF8Encoding]::new($false))
    # T019 (FR-028): the sibling bare token 'workshop-repair-proposal-stale' gained a reader too. The refusal
    # is unchanged in strength - a proposal whose records moved underneath it is still refused - and now says
    # what happened and what to do next.
    $staleRefused = $false
    $staleMessage = ''
    try { & $repairSource -ProjectRoot $scratch -FeatureRef $featureRef -Apply | Out-Null }
    catch { $staleMessage = [string]$_.Exception.Message; $staleRefused = $true }
    Assert-True $staleRefused 'repair refuses when workshop state changes after human authorization'
    Assert-True ($staleMessage -match 'changed after this repair was proposed') 'the stale refusal says what changed rather than throwing a machine token'
    Assert-True ($staleMessage -match 'proposed again') 'and names the one action that resolves it'
    [IO.File]::WriteAllBytes($statePath, $beforeStateBytes)

    $applied = & $repairSource -ProjectRoot $scratch -FeatureRef $featureRef -Apply -PassThru
    Assert-True ([string]$applied.state -eq 'repaired') 'authorized repair returns the unfinished agenda to canonical pending state'
    $repairedState = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    $repairedTransition = Resolve-SpecrewWorkshopStateTransition -Controller $repairedState -Operation 'read'
    Assert-True ($repairedTransition.allowed -and $repairedTransition.state_class -eq 'pending-empty') 'repaired state is accepted by the shared reader transition'
    Assert-True ((Get-FileHash -LiteralPath $productMarkdownPath -Algorithm SHA256).Hash -eq $productMarkdownHash -and
        (Get-FileHash -LiteralPath $productStructuredPath -Algorithm SHA256).Hash -eq $productStructuredHash) 'authorized repair preserves both product-domain records byte-for-byte'
    Assert-True (Test-Path -LiteralPath (Join-Path $scratch '.specrew\runtime\workshop-controller-repair-history.jsonl') -PathType Leaf) 'authorized repair writes an audit record'
    Assert-True (-not (Test-Path -LiteralPath (Get-SpecrewWorkshopRepairProposalPath -ProjectRoot $scratch))) 'successful repair consumes the one-time proposal'

    [IO.File]::WriteAllBytes($statePath, $beforeStateBytes)
    $secondProposal = & $repairSource -ProjectRoot $scratch -FeatureRef $featureRef -Request -PassThru
    Assert-True ([string]$secondProposal.proposal_id -cne [string]$proposal.proposal_id) 'the same later inconsistency receives a fresh proposal id rather than replaying old human authority'
    # T019 (FR-028): same refusal, now with a reader. The one-time property is what is under test here, and
    # it is unchanged: a consumed authorization does not carry to a fresh proposal, whatever the bytes say.
    $oldAuthorityRefused = $false
    $oldAuthorityMessage = ''
    try { & $repairSource -ProjectRoot $scratch -FeatureRef $featureRef -Apply | Out-Null }
    catch { $oldAuthorityMessage = [string]$_.Exception.Message; $oldAuthorityRefused = ($oldAuthorityMessage -match 'No typed authorization is on record for the repair proposed for') }
    Assert-True $oldAuthorityRefused 'a consumed authorization cannot approve a later repair of identical bytes'
    Assert-True ($oldAuthorityMessage -match 'type: approved for workshop repair') 'and the refusal names the phrase that would authorize the NEW proposal'
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'workshop state transition table: all assertions pass' -ForegroundColor Green
