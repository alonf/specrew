# Feature 202 T004 (FR-007, FR-009, FR-010; B4F-108 defect 3): a reply that is not recorded is SAID, in the same
# turn, with its actual cause and whether it was used - and never attributed to a channel the human did not use.
#
# Through the REAL handover provider at UserPromptSubmit, with the deployed-store layout it loads from (the same
# harness as workshop-confirm-not-bound). The provider's inject stdout is what the agent receives that turn.
#
# RED before T004: every refusal below returned $null in silence (case 1 is the product-records refusal the
# acceptance names); the conformance repair message asserted a picker or dismissed question UI for any
# unreceipted product record; no health line; no recovery question.
#
# Mutations that turn this file red: restore any bare `return $null` in Write-SpecrewWorkshopAuthorityReceipt;
# drop the outcome disclosure from the prompt-entry branch; reintroduce the selection-channel sentence; let the
# recovery "yes" also mint a workshop receipt; delete instead of setting the stuck record aside.
$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'scripts/internal/specrew-handover-provider.ps1'
$storeSource = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
. $storeSource
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
. (Join-Path $repoRoot 'scripts/internal/specrew-consumer-language.ps1')

function New-WorkshopFixture {
    param([ValidateSet('product-domain', 'agenda')][string]$Phase = 'product-domain', [switch]$ProductRecorded)
    $root = Join-Path ([IO.Path]::GetTempPath()) ('rdis-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $feature = '001-mail-summary'
    foreach ($d in @('.specrew/handover', '.specrew/runtime', '.specify/extensions/specrew-speckit/scripts', "specs/$feature/workshop")) {
        New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null
    }
    Copy-Item -LiteralPath $storeSource -Destination (Join-Path $root '.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1') -Force
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "specs/$feature/spec.md") -Value '# Mail Summary' -Encoding UTF8
    if ($ProductRecorded) {
        Set-Content -LiteralPath (Join-Path $root "specs/$feature/workshop/product-domain.md") -Value "# Product`n`ndone" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $root "specs/$feature/workshop/product-domain.yml") -Value "schema: v1`n" -Encoding UTF8
    }
    $controller = [ordered]@{ human_turn_contract = 'typed-turns-v1'; agenda_contract = 'complete-coverage-v1'; agenda_status = 'pending-confirmation'; selected = @('architecture-core'); workshop = @{} }
    [IO.File]::WriteAllText((Join-Path $root "specs/$feature/lens-applicability.json"), ($controller | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $question = [ordered]@{ schema = 'v3'; status = 'workshop-active'; scope = 'feature'; feature_ref = $feature; iteration_number = ''; lens = ''
        phase = $Phase; agenda_status = 'pending-confirmation'; question = 'Who is this for?'; message_hash = ('a' * 64); artifact_path = '' }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/handover/workshop-question.json'), ($question | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $ctx = [ordered]@{ schema = 'v2'; session_state = [ordered]@{ active = $true; feature_ref = $feature; boundary_type = 'specify'; host = 'claude' } }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    return $root
}
function Invoke-Provider { param([string]$Root, [string]$Reply, [string]$Origin, [string]$Session) $extra = @(if ($Origin) { "--turn-origin", $Origin }) + @(if ($Session) { "--session-id", $Session }); return ((& pwsh -NoProfile -File $provider --project-root $Root --host-kind claude --source-event UserPromptSubmit --last-user-message $Reply @extra 2>&1 | ForEach-Object { [string]$_ }) -join "`n") }
function Read-Outcomes { param([string]$Root) $p = Join-Path $Root '.specrew/runtime/workshop-receipt-outcomes.jsonl'; if (-not (Test-Path -LiteralPath $p)) { return @() }; return @(Get-Content -LiteralPath $p -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }) }
function Test-Receipt { param([string]$Root) return (Test-Path -LiteralPath (Join-Path $Root '.specrew/runtime/workshop-authority.jsonl')) }
function Get-ReceiptCount { param([string]$Root) $p = Join-Path $Root '.specrew/runtime/workshop-authority.jsonl'; if (-not (Test-Path -LiteralPath $p)) { return 0 }; return @(Get-Content -LiteralPath $p | Where-Object { $_.Trim() }).Count }
function Get-HashOf { param([string]$Text) return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text.Trim())))).ToLowerInvariant() }
function Test-NoBannedNoun { param([string]$Text, [string]$Label) $found = @(Get-SpecrewBannedConsumerNoun -Text $Text); Assert-True ($found.Count -eq 0) ("{0}: no internal noun reaches the human ({1})" -f $Label, ($found -join ',')) }

Write-Host 'receipt-disclosure'
$roots = New-Object System.Collections.Generic.List[string]
try {
    Write-Host '  --- case 1: the product-records refusal is said with its cause (was silent) ---'
    $r1 = New-WorkshopFixture -Phase 'product-domain' -ProductRecorded; $roots.Add($r1)
    $reply = 'It is for support staff who read the shared inbox.'
    $out = Invoke-Provider -Root $r1 -Reply $reply
    Assert-True ($out -match 'your last reply was not used as your workshop answer, because the product-domain answers for this feature are already recorded') 'case 1: the turn says the reply was not used, and why'
    Assert-True ($out -match 'The question is still open, and your earlier answers are unchanged\.') 'case 1: it says the question is still open and nothing earlier changed'
    $rows = @(Read-Outcomes $r1)
    Assert-True ($rows.Count -eq 1 -and $rows[0].reason -eq 'product-answers-already-recorded' -and -not [bool]$rows[0].consumed) 'case 1: the outcome is journaled: refused, not consumed'
    Assert-True ($rows.Count -eq 1 -and $rows[0].response_hash -eq (Get-HashOf $reply) -and -not ((Get-Content (Join-Path $r1 '.specrew/runtime/workshop-receipt-outcomes.jsonl') -Raw).Contains('support staff'))) 'case 1: the journal holds the reply hash, never the reply text'
    Assert-True (-not (Test-Receipt $r1)) 'case 1: no receipt'
    Test-NoBannedNoun -Text $out -Label 'case 1'

    Write-Host '  --- case 2: a reply that repeats recorded hook output names that cause, never a channel ---'
    $r2 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r2)
    $replayed = 'Specrew asks: who is this for, and what is their pain?'
    $line = ([ordered]@{ schema_version = '1.0'; output_hash = (Get-HashOf $replayed); event = 'Stop'; host = 'claude'; output_kind = 'payload'; observed_at = '2026-10-13T00:00:00Z' } | ConvertTo-Json -Compress) + "`n"
    [IO.File]::WriteAllText((Join-Path $r2 '.specrew/runtime/hook-output-authority.jsonl'), $line, [Text.UTF8Encoding]::new($false))
    $out = Invoke-Provider -Root $r2 -Reply $replayed
    Assert-True ($out -match 'because it repeats text Specrew itself showed') 'case 2: the actual cause is named'
    Assert-True ($out -notmatch '(?i)picker|selection channel|question UI') 'case 2: no channel is attributed'
    Assert-True (-not (Test-Receipt $r2)) 'case 2: no receipt'

    Write-Host '  --- case 3: records that cannot be read this turn: degraded, said, nothing implied lost ---'
    $r3 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r3)
    [IO.File]::WriteAllText((Join-Path $r3 '.specrew/runtime/hook-output-authority.jsonl'), '', [Text.UTF8Encoding]::new($false))
    $holder = [IO.File]::Open((Join-Path $r3 '.specrew/runtime/hook-output-authority.jsonl'), 'Open', 'ReadWrite', 'None')
    try { $out = Invoke-Provider -Root $r3 -Reply 'It is for support staff.' } finally { $holder.Dispose() }
    Assert-True ($out -match 'because Specrew could not read its own records to check the reply this turn') 'case 3: the cause is named'
    Assert-True ($out -match 'Nothing is deleted; they can send the same answer again next turn\.') 'case 3: the remedy, with no implied loss'
    $rows = @(Read-Outcomes $r3)
    Assert-True ($rows.Count -eq 1 -and $rows[0].status -eq 'degraded' -and $rows[0].reason -eq 'record-check-unavailable') 'case 3: journaled as degraded, not as a replay'

    Write-Host '  --- case 4: ordinary conversation (no open workshop question) stays silent ---'
    $r4 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r4)
    Remove-Item -LiteralPath (Join-Path $r4 '.specrew/handover/workshop-question.json') -Force
    $out = Invoke-Provider -Root $r4 -Reply 'What does the next stage do?'
    Assert-True ($out -notmatch 'was not used as your workshop answer') 'case 4: no disclosure'
    Assert-True (@(Read-Outcomes $r4).Count -eq 0) 'case 4: nothing journaled'

    Write-Host '  --- case 5: the conformance repair message names the real cause, never a selection channel ---'
    $conformance = [IO.File]::ReadAllText((Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'))
    Assert-True ($conformance -notmatch '(?i)selection channel') 'case 5: the provider no longer carries the selection-channel sentence'
    Assert-True ($conformance -match 'Get-SpecrewWorkshopLatestRefusal' -and $conformance -match 'Get-SpecrewWorkshopRefusalCauseText') 'case 5: the repair message reads the journaled cause'
    $latest = Get-SpecrewWorkshopLatestRefusal -ProjectRoot $r1 -FeatureRef '001-mail-summary' -Phase 'product-domain'
    Assert-True ($null -ne $latest -and (Get-SpecrewWorkshopRefusalCauseText -Reason $latest.reason) -eq 'the product-domain answers for this feature are already recorded') 'case 5: the cause the repair message would show is the real one'

    Write-Host '  --- case 6: every disclosure sentence passes the banned-noun check ---'
    foreach ($reason in 'matches-hook-output', 'not-typed-by-human', 'record-check-unavailable', 'product-answers-already-recorded', 'product-answers-missing', 'agenda-not-shown', 'agenda-changed', 'agenda-already-confirmed', 'lens-not-on-agenda', 'lens-already-closed', 'question-record-invalid', 'question-record-unreadable', 'workshop-records-missing', 'workshop-records-incompatible', 'reply-write-failed', 'unknown-reason') {
        $text = Get-SpecrewWorkshopReceiptOutcomeDisclosure -Outcome ([pscustomobject]@{ status = 'refused'; reason = $reason })
        Assert-True ($text -match 'was not used as your workshop answer' -and $text -notmatch '(?i)lost|selection channel') ("case 6 [{0}]: says not used, implies no loss" -f $reason)
        Test-NoBannedNoun -Text $text -Label ("case 6 [{0}]" -f $reason)
    }

    Write-Host '  --- case 7: the health line shows only while degraded ---'
    $r7 = New-WorkshopFixture; $roots.Add($r7)
    Assert-True ($null -eq (Get-SpecrewReplyRecordingHealthLine -ProjectRoot $r7)) 'case 7: healthy -> no line'
    New-Item -ItemType Directory -Force -Path (Join-Path $r7 '.specrew/runtime/hook-output-buffer') | Out-Null
    [IO.File]::WriteAllText((Join-Path $r7 '.specrew/runtime/hook-output-buffer/123-abc.jsonl'), '{"schema_version":"1.0","output_hash":"00"}' + "`n")
    $health = Get-SpecrewReplyRecordingHealthLine -ProjectRoot $r7
    Assert-True ($health -match '^Reply recording: degraded since' -and $health -match 'nothing is lost') 'case 7: a pending buffer -> the degraded line'
    Test-NoBannedNoun -Text $health -Label 'case 7'
    $where = Get-Content (Join-Path $repoRoot 'scripts/specrew-where.ps1') -Raw
    Assert-True ($where -match 'Get-SpecrewReplyRecordingHealthLine') 'case 7: where (and status, its alias) shows the line'
    $boot = Get-Content (Join-Path $repoRoot 'scripts/internal/specrew-bootstrap-provider.ps1') -Raw
    Assert-True ($boot -match 'Get-SpecrewReplyRecordingHealthLine' -and $boot -match 'ReplyHealthLine') 'case 7: the session orientation carries the line'

    Write-Host '  --- case 8: self-recovery failed -> ONE question in the reference wording; a typed yes sets the record aside ---'
    $r8 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r8)
    $journal8 = Join-Path $r8 '.specrew/runtime/hook-output-authority.jsonl'
    [IO.File]::WriteAllText($journal8, (([ordered]@{ schema_version = '1.0'; output_hash = (Get-HashOf 'an old hook output'); event = 'Stop'; host = 'claude'; output_kind = 'payload'; observed_at = '2026-10-13T00:00:00Z' } | ConvertTo-Json -Compress) + "`n"))
    $firstSeen = [DateTimeOffset]::UtcNow.AddMinutes(-20).ToString('o')
    [IO.File]::WriteAllText((Join-Path $r8 '.specrew/runtime/hook-output-health.jsonl'), (([ordered]@{ schema_version = '1.0'; state = 'degraded'; class = 'journal-append-failed'; error = 'in use'; first_seen = $firstSeen; count = 1 } | ConvertTo-Json -Compress) + "`n"))
    $out = Invoke-Provider -Root $r8 -Reply 'What is the status?'
    $question = "Specrew couldn't record your reply safely. May I clear the stuck error so it can record again? Nothing is deleted."
    Assert-True ($out.Contains($question)) 'case 8: the recovery question, in the reference wording verbatim'
    Assert-True (Test-Path -LiteralPath (Join-Path $r8 '.specrew/runtime/reply-recording-recovery-request.json')) 'case 8: the open question is recorded'
    $again = Invoke-Provider -Root $r8 -Reply 'Hmm, let me think.'
    Assert-True (-not $again.Contains($question)) 'case 8: asked once, not every turn'
    $receiptsBefore = Get-ReceiptCount $r8
    $yes = Invoke-Provider -Root $r8 -Reply 'yes'
    Assert-True ($yes -match 'set aside, not deleted') 'case 8: the typed yes is acted on and said'
    Assert-True (-not (Test-Path -LiteralPath $journal8) -and @(Get-ChildItem (Join-Path $r8 '.specrew/runtime') -Filter 'hook-output-authority.set-aside-*.jsonl').Count -eq 1) 'case 8: the stuck record was moved aside, not deleted'
    $recovery = @(Get-Content (Join-Path $r8 '.specrew/runtime/reply-recording-recovery.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
    Assert-True ($recovery.Count -eq 2 -and $recovery[0].response_hash -eq (Get-HashOf 'yes') -and $recovery[0].result -eq 'approved' -and $recovery[1].action -eq 'set-aside-stuck-record' -and $recovery[1].result -eq 'recovered') 'case 8: the approving reply is recorded first, then the action taken'
    Assert-True ((Get-ReceiptCount $r8) -eq $receiptsBefore) 'case 8: the recovery yes was not also taken as a workshop answer (no receipt added)'
    Assert-True (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $r8 -Response 'an old hook output') 'case 8: output recorded in the set-aside file is still refused as a reply'
    Test-NoBannedNoun -Text ($out + "`n" + $yes) -Label 'case 8'

    # --- Co-review round 1 (202) findings, each pinned through the real provider where it has a turn ---
    Write-Host '  --- case 9: only a typed-user prompt produces a receipt (FR-006, enforced, not only passed along) ---'
    $r9 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r9)
    $out = Invoke-Provider -Root $r9 -Reply 'User skipped question' -Origin 'host-injected'
    Assert-True (-not (Test-Receipt $r9)) 'case 9: a host-injected prompt produces no receipt, whatever its text'
    $rows = @(Read-Outcomes $r9)
    Assert-True ($rows.Count -eq 1 -and $rows[0].reason -eq 'not-typed-by-human' -and -not [bool]$rows[0].consumed) 'case 9: refused as not typed by the human, not consumed'
    Assert-True ($out -match 'because it was added by the assistant''s host, not typed by you') 'case 9: the turn says so, with that cause'
    Assert-True ($out -notmatch '(?i)picker|selection channel|question UI') 'case 9: no channel is attributed'
    $null = Invoke-Provider -Root $r9 -Reply 'It is for support staff who read the shared inbox.' -Origin 'unknown'
    Assert-True (-not (Test-Receipt $r9)) 'case 9: an unknown-origin prompt produces no receipt either'
    $null = Invoke-Provider -Root $r9 -Reply 'It is for support staff who read the shared inbox.' -Origin 'typed-user'
    Assert-True ((Get-ReceiptCount $r9) -eq 1) 'case 9: the same text typed by the human is recorded'
    Test-NoBannedNoun -Text $out -Label 'case 9'

    Write-Host '  --- case 10: a malformed record line never silences the turn or refuses every later reply ---'
    $r10 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r10)
    $journal10 = Join-Path $r10 '.specrew/runtime/hook-output-authority.jsonl'
    [IO.File]::WriteAllText($journal10, ('{"schema_version":"1.0","output_hash":"' + (Get-HashOf 'shown by the hook') + '"}' + "`n" + '{"schema_versi' + "`n" + '{"schema_version":"9"}' + "`n"))
    $threw = $false
    try { $isHook = Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $r10 -Response 'shown by the hook' } catch { $threw = $true }
    Assert-True (-not $threw -and $isHook) 'case 10: the check does not throw, and a readable record still matches'
    $out = Invoke-Provider -Root $r10 -Reply 'It is for support staff who read the shared inbox.' -Origin 'typed-user'
    Assert-True ((Get-ReceiptCount $r10) -eq 1) 'case 10: a typed reply is recorded despite the malformed lines (no permanent refusal)'
    Assert-True ($out -notmatch 'PROVIDER_FAILED') 'case 10: the provider does not fail'

    Write-Host '  --- case 11: a reply that declines is never read as recovery approval ---'
    foreach ($decline in 'okay, do not clear it.', 'yes, but leave the error alone.', "ok don't", 'yes, wait', 'no', 'sure, later', 'yes?') {
        Assert-True (-not (Test-SpecrewReplyRecordingRecoveryApproval -Response $decline)) ("case 11: '{0}' is not approval" -f $decline)
    }
    foreach ($approve in 'yes', 'Yes, go ahead.', 'ok', 'approved', 'please do') {
        Assert-True (Test-SpecrewReplyRecordingRecoveryApproval -Response $approve) ("case 11: '{0}' approves" -f $approve)
    }
    $r11 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r11)
    $journal11 = Join-Path $r11 '.specrew/runtime/hook-output-authority.jsonl'
    [IO.File]::WriteAllText($journal11, '{"schema_version":"1.0","output_hash":"00"}' + "`n")
    [IO.File]::WriteAllText((Join-Path $r11 '.specrew/runtime/hook-output-health.jsonl'), (([ordered]@{ schema_version = '1.0'; state = 'degraded'; class = 'journal-append-failed'; first_seen = [DateTimeOffset]::UtcNow.AddMinutes(-20).ToString('o'); count = 1 } | ConvertTo-Json -Compress) + "`n"))
    $null = Invoke-Provider -Root $r11 -Reply 'What is the status?'
    $no = Invoke-Provider -Root $r11 -Reply 'okay, do not clear it.'
    Assert-True ((Test-Path -LiteralPath $journal11) -and $no -notmatch 'set aside') 'case 11: through the provider, a declining reply moves nothing'

    Write-Host '  --- case 12: after automatic recovery, a later "yes" is not taken as recovery approval ---'
    $r12 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r12)
    $journal12 = Join-Path $r12 '.specrew/runtime/hook-output-authority.jsonl'
    [IO.File]::WriteAllText($journal12, '{"schema_version":"1.0","output_hash":"00"}' + "`n")
    $health12 = Join-Path $r12 '.specrew/runtime/hook-output-health.jsonl'
    $first12 = [DateTimeOffset]::UtcNow.AddMinutes(-20).ToString('o')
    [IO.File]::WriteAllText($health12, (([ordered]@{ schema_version = '1.0'; state = 'degraded'; class = 'journal-append-failed'; first_seen = $first12; count = 1 } | ConvertTo-Json -Compress) + "`n"))
    $null = Invoke-Provider -Root $r12 -Reply 'What is the status?'
    Assert-True (Test-Path -LiteralPath (Join-Path $r12 '.specrew/runtime/reply-recording-recovery-request.json')) 'case 12: the question was asked'
    [IO.File]::AppendAllText($health12, (([ordered]@{ schema_version = '1.0'; state = 'recovered'; class = 'journal-append-failed'; first_seen = $first12; recovered_at = [DateTimeOffset]::UtcNow.ToString('o'); count = 1 } | ConvertTo-Json -Compress) + "`n"))
    $receipts12 = Get-ReceiptCount $r12
    $yes12 = Invoke-Provider -Root $r12 -Reply 'yes' -Origin 'typed-user'
    Assert-True ((Test-Path -LiteralPath $journal12) -and $yes12 -notmatch 'set aside') 'case 12: nothing is moved once recording recovered on its own'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $r12 '.specrew/runtime/reply-recording-recovery-request.json'))) 'case 12: the stale question is closed'
    Assert-True ((Get-ReceiptCount $r12) -eq ($receipts12 + 1)) 'case 12: the "yes" went to the open workshop question instead'

    Write-Host '  --- case 13: no action without the approval''s receipt (FR-009) ---'
    $r13 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r13)
    $journal13 = Join-Path $r13 '.specrew/runtime/hook-output-authority.jsonl'
    [IO.File]::WriteAllText($journal13, '{"schema_version":"1.0","output_hash":"00"}' + "`n")
    [IO.File]::WriteAllText((Join-Path $r13 '.specrew/runtime/hook-output-health.jsonl'), (([ordered]@{ schema_version = '1.0'; state = 'degraded'; class = 'journal-append-failed'; first_seen = [DateTimeOffset]::UtcNow.AddMinutes(-20).ToString('o'); count = 1 } | ConvertTo-Json -Compress) + "`n"))
    $null = Invoke-Provider -Root $r13 -Reply 'What is the status?'
    New-Item -ItemType Directory -Force -Path (Join-Path $r13 '.specrew/runtime/reply-recording-recovery.jsonl') | Out-Null  # the receipt cannot be written
    $yes13 = Invoke-Provider -Root $r13 -Reply 'yes'
    Assert-True (Test-Path -LiteralPath $journal13 -PathType Leaf) 'case 13: the record was not moved'
    Assert-True ($yes13 -match 'could not be recorded this turn, so nothing was changed' -and $yes13 -notmatch 'your approval was recorded') 'case 13: the turn says the approval was not recorded and nothing changed'
    Assert-True (Test-Path -LiteralPath (Join-Path $r13 '.specrew/runtime/reply-recording-recovery-request.json')) 'case 13: the question stays open'
    Test-NoBannedNoun -Text $yes13 -Label 'case 13'

    Write-Host '  --- case 14: while degraded, the affected turn says so and whether the reply was used (FR-007) ---'
    $r14 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r14)
    [IO.File]::WriteAllText((Join-Path $r14 '.specrew/runtime/hook-output-health.jsonl'), (([ordered]@{ schema_version = '1.0'; state = 'degraded'; class = 'journal-append-failed'; first_seen = [DateTimeOffset]::UtcNow.AddMinutes(-2).ToString('o'); count = 1 } | ConvertTo-Json -Compress) + "`n"))
    $out14 = Invoke-Provider -Root $r14 -Reply 'It is for support staff who read the shared inbox.' -Origin 'typed-user'
    Assert-True ((Get-ReceiptCount $r14) -eq 1 -and $out14 -match 'your reply was used as your workshop answer, and nothing is lost') 'case 14: degraded and used: said in the same turn'
    $r14b = New-WorkshopFixture -Phase 'product-domain' -ProductRecorded; $roots.Add($r14b)
    [IO.File]::WriteAllText((Join-Path $r14b '.specrew/runtime/hook-output-health.jsonl'), (([ordered]@{ schema_version = '1.0'; state = 'degraded'; class = 'journal-append-failed'; first_seen = [DateTimeOffset]::UtcNow.AddMinutes(-2).ToString('o'); count = 1 } | ConvertTo-Json -Compress) + "`n"))
    $out14b = Invoke-Provider -Root $r14b -Reply 'It is for support staff who read the shared inbox.' -Origin 'typed-user'
    Assert-True ($out14b -match 'your reply was not used as your workshop answer, and nothing is lost') 'case 14: degraded and not used: said in the same turn'
    $r14c = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r14c)
    $out14c = Invoke-Provider -Root $r14c -Reply 'It is for support staff who read the shared inbox.' -Origin 'typed-user'
    Assert-True ($out14c -notmatch 'fallback record') 'case 14: healthy recording says nothing'
    Test-NoBannedNoun -Text ($out14 + "`n" + $out14b) -Label 'case 14'

    # --- Co-review round 2 (202) findings ---
    Write-Host '  --- case 15: an unknown origin is an unreadable record check, not a host-added reply (FR-010) ---'
    # The dispatcher gives a typed prompt origin 'unknown' when it cannot read the hook-output records. The old guard
    # told the human their typed reply "was added by the assistant's host".
    $r15 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r15)
    $out15 = Invoke-Provider -Root $r15 -Reply 'It is for support staff who read the shared inbox.' -Origin 'unknown'
    $rows15 = @(Read-Outcomes $r15)
    Assert-True (-not (Test-Receipt $r15)) 'case 15: still no receipt this turn'
    Assert-True ($rows15.Count -eq 1 -and $rows15[0].reason -eq 'record-check-unavailable' -and $rows15[0].status -eq 'degraded') 'case 15: recorded as the record check being unavailable (degraded), not as host-added'
    Assert-True ($out15 -match 'could not read its own records' -and $out15 -notmatch 'added by the assistant''s host') 'case 15: the turn names the actual cause'
    Test-NoBannedNoun -Text $out15 -Label 'case 15'

    Write-Host '  --- case 16: only the session that was asked can approve the recovery ---'
    $r16 = New-WorkshopFixture -Phase 'product-domain'; $roots.Add($r16)
    $journal16 = Join-Path $r16 '.specrew/runtime/hook-output-authority.jsonl'
    [IO.File]::WriteAllText($journal16, (([ordered]@{ schema_version = '1.0'; output_hash = (Get-HashOf 'an old hook output'); event = 'Stop'; host = 'claude'; output_kind = 'payload'; observed_at = '2026-10-13T00:00:00Z' } | ConvertTo-Json -Compress) + "`n"))
    [IO.File]::WriteAllText((Join-Path $r16 '.specrew/runtime/hook-output-health.jsonl'), (([ordered]@{ schema_version = '1.0'; state = 'degraded'; class = 'journal-append-failed'; error = 'in use'; first_seen = [DateTimeOffset]::UtcNow.AddMinutes(-20).ToString('o'); count = 1 } | ConvertTo-Json -Compress) + "`n"))
    $asked16 = Invoke-Provider -Root $r16 -Reply 'What is the status?' -Origin 'typed-user' -Session 'session-a'
    Assert-True ($asked16.Contains($question)) 'case 16: session A is asked the recovery question'
    $other16 = Invoke-Provider -Root $r16 -Reply 'yes' -Origin 'typed-user' -Session 'session-b'
    Assert-True ((Test-Path -LiteralPath $journal16) -and $other16 -notmatch 'set aside') 'case 16: a yes typed in session B, which was never asked, changes nothing'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $r16 '.specrew/runtime/reply-recording-recovery.jsonl'))) 'case 16: and is not recorded as an approval'
    $own16 = Invoke-Provider -Root $r16 -Reply 'yes' -Origin 'typed-user' -Session 'session-a'
    Assert-True ($own16 -match 'set aside, not deleted' -and -not (Test-Path -LiteralPath $journal16)) 'case 16: the yes typed in session A, which was asked, is acted on'
}
finally {
    foreach ($d in $roots) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:Failures -gt 0) { Write-Host ("receipt-disclosure: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'receipt-disclosure: all cases passed'
exit 0
