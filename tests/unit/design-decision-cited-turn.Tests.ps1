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

$decision = 'design decision: option 2 - I want the concerns testable on their own'

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
    param([string]$Root, [string]$HumanTurn)
    try {
        $out = & $cli -ProjectRoot $Root -FeatureRef '001-feat' -Key 'decomposition-style' -Question 'How is the checker decomposed?' `
            -OptionId '1', '2' -OptionSummary 'one script', 'a module per concern' -Chosen '2' `
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
}
finally {
    foreach ($root in $roots) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:failCount -gt 0) { Write-Host "$script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'design-decision-cited-turn: all passed' -ForegroundColor Green
exit 0
