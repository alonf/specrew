# Iteration 002, T019 (FR-028, SC-014): what was received, and what is still needed.
#
# F-3 as CORRECTED at source. The brief reported "yes rejected where move on is required, and the message does
# not say what is missing". Verified: there is NO code recognizer for the lens-closing phrase -
# Get-SpecrewWorkshopResponseAuthority classifies any non-skip, non-delegated lens reply (including a bare
# "yes") as human-confirmed and mints a receipt. The refusals the walk recorded were AGENT-RENDERED from the
# instruction text. That makes this finding larger than the one it replaced: instruction-layer friction is
# invisible to every control that measures gate behaviour, so both walks' stop counts are a FLOOR
# (DRIFT-199-I002-008, and the maintainer's ruling that beta4's friction measurement must read the walk
# transcript, not the gate log).
#
# So the fix lands on TWO surfaces, and neither widens a recognizer:
#   * the instruction layer - the workshop skill (3 copies) and every lens md carry the acknowledgment line;
#   * the one CODE-level sibling with the same defect shape - the repair authorization gate, which threw the
#     bare token 'workshop-repair-human-authorization-missing' with no reader.
#
# Mutations that turn this file red: drop the acknowledgment clause from any skill copy or lens md (cases 1,
# 2); restore either bare throw in the repair script (3, 4); widen the -cne phrase check (5).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\workshop-authority-store.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

Write-Host 'Case 1: every workshop skill copy carries the acknowledgment line, and does NOT widen the phrase'
$skillCopies = @(
    '.claude\skills\specrew-design-workshop\SKILL.md',
    'extensions\specrew-speckit\squad-templates\skills\design-workshop.md',
    '.specify\extensions\specrew-speckit\squad-templates\skills\design-workshop.md'
)
foreach ($relative in $skillCopies) {
    $text = Get-Content -LiteralPath (Join-Path $repoRoot $relative) -Raw -Encoding UTF8
    $hasAck = $text -match 'SAY WHAT YOU RECORDED AND WHAT IS STILL NEEDED'
    $hasTemplate = $text -match 'This lens stays open until you type "move on"'
    $keepsPhrase = $text -match 'Do NOT widen what counts as closing the lens'
    Assert-True ($hasAck -and $hasTemplate -and $keepsPhrase) ("{0}: names what was recorded, what is still needed, and keeps the typed phrase load-bearing" -f $relative)
}
$hashes = @($skillCopies | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $repoRoot $_) -Algorithm SHA256).Hash })
Assert-True (@($hashes | Select-Object -Unique).Count -le 2) 'the template copies stay in step (the Claude copy carries its own host-specific header)'
$templateHashes = @(@($skillCopies[1], $skillCopies[2]) | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $repoRoot $_) -Algorithm SHA256).Hash })
Assert-True (@($templateHashes | Select-Object -Unique).Count -eq 1) 'the deployed template mirror is byte-identical to its source'

Write-Host 'Case 2: every lens that says "iterate until they say move on" also says what to do when they do not'
$lensFiles = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses') -Filter '*.md' -File)
$withPhrase = @($lensFiles | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -match 'iterate until they say "move on"' })
Assert-True ($withPhrase.Count -ge 3) ("the lens catalog still instructs the closing phrase ({0} lenses)" -f $withPhrase.Count)
$missingAck = @($withPhrase | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -notmatch 'the lens stays open until they type' })
Assert-True ($missingAck.Count -eq 0) ("every one of them carries the acknowledgment contract (missing in: {0})" -f (($missingAck | ForEach-Object { $_.Name }) -join ', '))

Write-Host 'Case 3: the repair refusal names what was received and the exact phrase - no bare token'
$repairSource = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\repair-workshop-controller-state.ps1') -Raw -Encoding UTF8
Assert-True ($repairSource -notmatch "throw 'workshop-repair-human-authorization-missing'") 'the bare machine token is gone from the authorization refusal'
Assert-True ($repairSource -notmatch "throw 'workshop-repair-proposal-stale'") 'and from its sibling, the stale-proposal refusal'
Assert-True ($repairSource -match 'No typed authorization is on record for this repair' -and $repairSource -match 'type: approved for workshop repair') 'the refusal names what is missing and the exact phrase to type'
Assert-True ($repairSource -match 'New-SpecrewWorkshopRepairRefusal') 'both refusals route through one builder, so they cannot drift apart'

Write-Host 'Case 4: the refusal carries the shared contract shape - reassurance included, no machinery nouns'
$contract = Get-SpecrewWorkshopRefusalContractText -AnswerState 'preserved'
Assert-True ($contract -match '(?i)safe|unchanged|nothing has been lost') 'the shared contract text reassures that the human''s answers are safe'
Assert-True ($contract -notmatch '(?i)\bcontroller\b|lens-applicability\.json|governed writer') 'and carries no machinery vocabulary'

Write-Host 'Case 5: the recognizer is NOT widened - the exact phrase still decides'
$storeSource = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\workshop-authority-store.ps1') -Raw -Encoding UTF8
Assert-True ($storeSource -match "Trim\(\) -cne 'approved for workshop repair'") 'the phrase check is untouched: exact, whole-string and case-sensitive (-cne)'
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("repairphrase-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path (Join-Path $scratch '.specrew/runtime') | Out-Null
Assert-True ($null -eq (Write-SpecrewWorkshopRepairAuthorization -ProjectRoot $scratch -Response 'yes, repair it')) 'ordinary assent still does not authorize a workshop repair'
Assert-True ($null -eq (Write-SpecrewWorkshopRepairAuthorization -ProjectRoot $scratch -Response 'Approved For Workshop Repair')) 'and neither does a case-different near miss'
Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue

Write-Host 'Case 6: a lens reply of "yes" still mints a receipt - the code path is untouched, only the SILENCE was the defect'
$authority = Get-SpecrewWorkshopResponseAuthority -Phase 'lens' -Response 'yes'
Assert-True ([string]$authority.confirmation -eq 'human-confirmed' -and [string]$authority.confirmation_scope -eq 'lens-question') '"yes" is still recorded as the human''s own confirmed reply, exactly as before'

if ($script:failCount -gt 0) { throw ("lens-acknowledgment: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'lens-acknowledgment: all assertions passed' -ForegroundColor Green
