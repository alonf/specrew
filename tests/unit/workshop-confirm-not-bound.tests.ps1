# PRED-BETA4-053: A WORKSHOP CONFIRMATION THAT CANNOT BIND IS SAID AT PROMPT ENTRY, WITH THE REMEDY.
#
# Field, the walk project on e9334af1: the canonical agenda block was rendered only as a tool result, the
# assistant turn before the confirm did not contain it, the Stop hook bound no agenda digest, and the typed
# confirm was dropped at prompt time without a word - the coordinator learned of it when its persist call threw.
# The verdict path got its disclosure in beta4; this is the workshop path's. Through the REAL handover provider
# at UserPromptSubmit, with the deployed-store layout the provider loads from.
# Mutation (recorded, not a switch): the disclosure call dropped from the prompt-entry branch reds case 1's
# line and journal assertions and nothing else.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'scripts/internal/specrew-handover-provider.ps1'
$storeSource = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
. $storeSource

function New-AgendaFixture {
    param([switch]$Visible)
    $root = Join-Path ([IO.Path]::GetTempPath()) ('wcnb-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $feature = '001-mail-summary'
    foreach ($d in @('.specrew/handover', '.specrew/runtime', '.specify/extensions/specrew-speckit/scripts', "specs/$feature/workshop")) {
        New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null
    }
    Copy-Item -LiteralPath $storeSource -Destination (Join-Path $root '.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1') -Force
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "specs/$feature/spec.md") -Value '# Mail Summary' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "specs/$feature/workshop/product-domain.md") -Value "# Product`n`ndone" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "specs/$feature/workshop/product-domain.yml") -Value "schema: v1`n" -Encoding UTF8
    $controller = [ordered]@{ human_turn_contract = 'typed-turns-v1'; agenda_contract = 'complete-coverage-v1'; agenda_status = 'pending-confirmation'; selected = @('architecture-core'); workshop = @{} }
    [IO.File]::WriteAllText((Join-Path $root "specs/$feature/lens-applicability.json"), ($controller | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $binding = [ordered]@{ selected = @(@{ lens = 'architecture-core'; depth = 'light'; decision = 'the shape' }); skipped = @() }
    $digest = Get-SpecrewWorkshopAgendaDigest -Binding ([pscustomobject]$binding)
    $question = [ordered]@{ schema = 'v3'; status = 'workshop-active'; scope = 'feature'; feature_ref = $feature; iteration_number = ''; lens = ''
        phase = 'agenda'; agenda_status = 'pending-confirmation'; question = 'Confirm the agenda?'; message_hash = ('a' * 64); artifact_path = '' }
    if ($Visible) { $question['agenda_digest'] = $digest; $question['agenda_binding'] = $binding }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/handover/workshop-question.json'), ($question | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $ctx = [ordered]@{ schema = 'v2'; session_state = [ordered]@{ active = $true; feature_ref = $feature; boundary_type = 'specify'; host = 'claude' } }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    return $root
}
function Invoke-Provider { param([string]$Root, [string]$Reply) return ((& pwsh -NoProfile -File $provider --project-root $Root --host-kind claude --source-event UserPromptSubmit --last-user-message $Reply 2>&1 | ForEach-Object { [string]$_ }) -join "`n") }
function Read-Journal { param([string]$Root) $p = Join-Path $Root '.specrew/runtime/handover-journal.jsonl'; if (-not (Test-Path -LiteralPath $p)) { return @() }; return @(Get-Content -LiteralPath $p -Encoding UTF8 | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.event -eq 'workshop-confirmation-not-bound-disclosed' }) }
function Test-Receipt { param([string]$Root) return (Test-Path -LiteralPath (Join-Path $Root '.specrew/runtime/workshop-authority.jsonl')) }

Write-Host 'workshop-confirm-not-bound'
$fNot = New-AgendaFixture
$fVis = New-AgendaFixture -Visible
try {
    Write-Host '  --- case 1: the walk''s shape - agenda active, block NOT in the previous assistant message, the human confirms ---'
    $out1 = Invoke-Provider -Root $fNot -Reply 'confirm the agenda'
    $expected = "Specrew: your agenda confirmation was received but NOT bound - the canonical agenda block was not in the assistant's previous message (a tool result is not a message), so nothing was recorded. Render the block in your message, then ask again."
    Assert-True ($out1.Contains($expected)) ('the provider''s inject stdout carries the disclosure verbatim (got: ' + (($out1 -replace '\s+', ' ')).Substring(0, [Math]::Min(140, ($out1 -replace '\s+', ' ').Length)) + ')')
    Assert-True (@(Read-Journal -Root $fNot).Count -eq 1) 'and the handover journal carries the row'
    Assert-True (-not (Test-Receipt -Root $fNot)) 'and no receipt was written - the confirmation bound nothing, as before'

    Write-Host '  --- case 2: the block WAS in the message (digest bound) - the receipt records, nothing is disclosed ---'
    $out2 = Invoke-Provider -Root $fVis -Reply 'confirm the agenda'
    Assert-True ($out2 -notmatch 'NOT bound') 'no disclosure when the confirmation binds'
    Assert-True ((Test-Receipt -Root $fVis) -and @(Read-Journal -Root $fVis).Count -eq 0) 'the receipt is written and the journal has no row'

    Write-Host '  --- case 3: an ordinary question is not a confirmation ---'
    $fNot2 = New-AgendaFixture
    $out3 = Invoke-Provider -Root $fNot2 -Reply 'what does the architecture lens cover?'
    Assert-True ($out3 -notmatch 'NOT bound' -and @(Read-Journal -Root $fNot2).Count -eq 0) 'a question ending in ? produces no disclosure and no row'
    Remove-Item -LiteralPath $fNot2 -Recurse -Force -ErrorAction SilentlyContinue
}
finally {
    foreach ($d in @($fNot, $fVis)) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:Failures -gt 0) { Write-Host ("workshop-confirm-not-bound: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'workshop-confirm-not-bound: all cases passed'
exit 0
