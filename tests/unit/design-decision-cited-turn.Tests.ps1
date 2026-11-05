# Feature 203 iteration 001, T004 (FR-014, FR-022; maintainer's decision 2026-11-04, option 1): a writer CLI cites the
# newest typed turn itself.
#
# record-design-decision.ps1 took the agent's word for what the human typed: -HumanTurn was any sentence in the design
# decision family, and the record said so ('crew-declared-human-reply'). An agent could record a decision the human never
# made. After T004 the CLI reads the prompt hook's record of the newest typed message (the exhausted-turn ledger's
# reservation: the act identity, the content hash, the origin), takes no turn identity from the agent, and records the
# decision only when the text it was given is that message, typed by the human. Otherwise nothing is recorded, and the
# refusal says which message it read.
#
# RED before T004: cases 2 to 4 record the decision.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1'
$cli = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\record-design-decision.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

# Co-review round 11: the decision alone. The reason is the record's rationale, never free text in the human's sentence.
$decision = 'design decision: option 2'

function New-DecisionProject {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('specrew-ddcite-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'specs/001-feat'), (Join-Path $root '.specrew') | Out-Null
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
    & git init -q -b 001-feat $root 2>&1 | Out-Null
    return $root
}

function Send-TypedMessage {
    # The prompt hook, as the dispatcher runs it for a Claude prompt.
    param([string]$Root, [string]$Text, [string]$Origin = 'typed-user')
    $env:SPECREW_MODULE_PATH = $repoRoot
    & pwsh -NoProfile -File $provider --project-root $Root --host-kind claude --source-event UserPromptSubmit --last-user-message $Text `
        --turn-origin $Origin --message-identity declared --message-id ('prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12)) --session-id s1 *> $null
}

function Invoke-RecordDecision {
    param([string]$Root, [string]$HumanTurn, [string]$Chosen = '2')
    try {
        $out = & $cli -ProjectRoot $Root -FeatureRef '001-feat' -Key 'decomposition-style' -Question 'How is the checker decomposed?' `
            -OptionId '1', '2' -OptionSummary 'one script', 'a module per concern' -Chosen $Chosen `
            -Rationale 'the concerns are tested separately' -HumanTurn $HumanTurn -AsJson
        return [pscustomobject]@{ Recorded = $true; Message = (@($out) -join "`n") }
    }
    catch { return [pscustomobject]@{ Recorded = $false; Message = [string]$_.Exception.Message } }
}

function Get-Decision {
    param([string]$Root)
    $path = Join-Path $Root 'specs/001-feat/design-decisions.json'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $doc = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -Depth 12
    if ($null -eq $doc.decisions -or -not $doc.decisions.PSObject.Properties['decomposition-style']) { return $null }
    return $doc.decisions.'decomposition-style'
}

$roots = [System.Collections.Generic.List[string]]::new()
try {
    # 1. The human typed the decision: it is recorded, citing the turn the prompt hook recorded.
    $r1 = New-DecisionProject; $roots.Add($r1)
    Send-TypedMessage -Root $r1 -Text $decision
    $o1 = Invoke-RecordDecision -Root $r1 -HumanTurn $decision
    $d1 = Get-Decision -Root $r1
    Assert-True ($o1.Recorded -and $null -ne $d1) "1 the decision the human typed is recorded ($($o1.Message))"
    $ledger = @(Get-Content -LiteralPath (Join-Path $r1 '.specrew/authority/exhausted-turns.jsonl') | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    $cited = if ($null -ne $d1 -and $d1.PSObject.Properties['turn_identity']) { [string]$d1.turn_identity } else { '' }
    Assert-True (-not [string]::IsNullOrWhiteSpace($cited) -and @($ledger | Where-Object { [string]$_.turn_id -ceq $cited }).Count -gt 0) '1 and the record carries the identity of the typed turn the prompt hook recorded'

    # 2. No typed turn: the agent supplies a decision the human never typed.
    $r2 = New-DecisionProject; $roots.Add($r2)
    $o2 = Invoke-RecordDecision -Root $r2 -HumanTurn $decision
    Assert-True (-not $o2.Recorded -and $null -eq (Get-Decision -Root $r2)) '2 with no typed turn recorded, nothing is recorded'
    Assert-True ($o2.Message -match '(?i)no message') "2 and the refusal says no typed message was recorded ($($o2.Message))"

    # 3. The newest typed message is another one: the decision was not this turn's reply.
    $r3 = New-DecisionProject; $roots.Add($r3)
    Send-TypedMessage -Root $r3 -Text $decision
    Start-Sleep -Milliseconds 50
    Send-TypedMessage -Root $r3 -Text 'ok, and what about the tests?'
    $o3 = Invoke-RecordDecision -Root $r3 -HumanTurn $decision
    Assert-True (-not $o3.Recorded -and $null -eq (Get-Decision -Root $r3)) '3 when a later message is the newest typed turn, nothing is recorded'
    Assert-True ($o3.Message -match '(?i)newest message') "3 and the refusal says which message it read ($($o3.Message))"

    # 4. The newest message was not typed by the human.
    $r4 = New-DecisionProject; $roots.Add($r4)
    Send-TypedMessage -Root $r4 -Text $decision -Origin 'host-injected'
    $o4 = Invoke-RecordDecision -Root $r4 -HumanTurn $decision
    Assert-True (-not $o4.Recorded -and $null -eq (Get-Decision -Root $r4)) "4 a decision the human did not type is not recorded ($($o4.Message))"

    # 5 (co-review round 8, finding 4): the reply is cited, but the record names another option. The human chose option 2.
    $r5 = New-DecisionProject; $roots.Add($r5)
    Send-TypedMessage -Root $r5 -Text $decision
    $o5 = Invoke-RecordDecision -Root $r5 -HumanTurn $decision -Chosen '1'
    Assert-True (-not $o5.Recorded -and $null -eq (Get-Decision -Root $r5)) '5 a record of option 1 from a reply that chose option 2 is not recorded'
    Assert-True ($o5.Message -match "chose option '2'") "5 and the refusal names the option the reply chose ($($o5.Message))"

    # 6: a reply in the family that names no option is no decision between them.
    $r6 = New-DecisionProject; $roots.Add($r6)
    $undecided = 'design decision: let me think about it first'
    Send-TypedMessage -Root $r6 -Text $undecided
    $o6 = Invoke-RecordDecision -Root $r6 -HumanTurn $undecided
    Assert-True (-not $o6.Recorded -and $null -eq (Get-Decision -Root $r6)) "6 a reply that names no option records no decision ($($o6.Message))"

    # 7 (co-review round 9, finding 3): a reply that names an option but asks, rejects, conditions or is still deciding is
    # no decision. Each was recorded as option 2.
    foreach ($notDecided in @(
            'design decision: option 2?'
            'design decision: option 2? I have not decided yet'
            'design decision: option 2 is not acceptable'
            'design decision: option 2 - not decided'
            'design decision: option 2 if the tests stay fast'
            'design decision: maybe option 2'
            # Co-review round 10, finding 3: a rejection no list of words names. Only the affirmative form decides.
            'design decision: option 2 - rejected'
            'design decision: option 2 - I reject this option'
            'design decision: option 2, over my objection to it'
            # Text after the option that is not introduced as a reason is not read as assent, whatever it says.
            'design decision: option 2 - the concerns are testable on their own'
            # Co-review round 11, finding 2: a reason connector proves nothing; the sentence is the decision alone.
            'design decision: option 2, so reject this option'
            'design decision: option 2 because the concerns are tested apart'
        )) {
        $r7 = New-DecisionProject; $roots.Add($r7)
        Send-TypedMessage -Root $r7 -Text $notDecided
        $o7 = Invoke-RecordDecision -Root $r7 -HumanTurn $notDecided
        Assert-True (-not $o7.Recorded -and $null -eq (Get-Decision -Root $r7)) "7 '$notDecided' records no decision ($($o7.Message))"
        Assert-True ($o7.Message -match '(?i)not a decision') "7 and the refusal says the reply is not a decision"
    }
    # The plain forms still decide.
    foreach ($decided in @('design decision: 2', 'design decision: option 2.', 'design decision - option 2', 'Design decision: Option 2', '  design decision:option 2!  ')) {
        $r7b = New-DecisionProject; $roots.Add($r7b)
        Send-TypedMessage -Root $r7b -Text $decided
        $o7b = Invoke-RecordDecision -Root $r7b -HumanTurn $decided
        Assert-True ($o7b.Recorded -and $null -ne (Get-Decision -Root $r7b)) "7 '$decided' is recorded ($($o7b.Message))"
    }

    # 8 (co-review round 9, finding 4): a later message that the authority capture reduces to nothing (a paste and no typed
    # text) is still the human's newest message. It reserved nothing, so the decision before it read as the newest.
    $r8 = New-DecisionProject; $roots.Add($r8)
    Send-TypedMessage -Root $r8 -Text $decision
    Start-Sleep -Milliseconds 50
    Send-TypedMessage -Root $r8 -Text "<pasted_content id=`"1`">`nerror: build failed at step 4`n</pasted_content id=`"1`">"
    $o8 = Invoke-RecordDecision -Root $r8 -HumanTurn $decision
    Assert-True (-not $o8.Recorded -and $null -eq (Get-Decision -Root $r8)) "8 after a paste-only message, the earlier decision is not recorded ($($o8.Message))"
    Assert-True ($o8.Message -match '(?i)newest message') "8 and the refusal says which message it read"
}
finally {
    foreach ($root in $roots) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:failCount -gt 0) { Write-Host "$script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'design-decision-cited-turn: all passed' -ForegroundColor Green
exit 0
