# Feature 203 T008 step (iv) (DRIFT-041 item 3, DRIFT-045 item 3): a decision record's dates are written once, with their
# offset, and recording a new decision leaves every earlier record byte-identical.
#
# record-design-decision.ps1 read the existing decisions back through ConvertFrom-Json, which turns an ISO date string into
# a local DateTime, and wrote the whole document again: every earlier record's dates came back in the writer's local offset.
# Measured on 1782a5a8: B5F-029's record went from +00:00 to +02:00, the same instant, different bytes. The earlier
# record here carries a +05:45 offset on purpose, so the case is red on any machine, a UTC runner included.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1'
$cli = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\record-design-decision.ps1'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function Send-TypedMessage {
    # The prompt hook, and the transcript record the host writes for a typed message (iteration review round C, finding 2:
    # the decision writer reads who sent it from that record).
    param([string]$Root, [string]$Text)
    $env:SPECREW_MODULE_PATH = $repoRoot
    $messageId = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
    $transcript = Join-Path $Root ('transcript-{0}.jsonl' -f $messageId)
    $record = [ordered]@{ type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = $messageId; sessionId = 's1'; timestamp = [DateTimeOffset]::UtcNow.ToString('o'); message = [ordered]@{ role = 'user'; content = $Text }; turnOrigin = 'human'; promptSource = 'typed'; origin = [ordered]@{ kind = 'human' }; entrypoint = 'cli'; version = '2.1.322' }
    [IO.File]::WriteAllText($transcript, (($record | ConvertTo-Json -Depth 6 -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
    & pwsh -NoProfile -File $provider --project-root $Root --host-kind claude --source-event UserPromptSubmit --last-user-message $Text `
        --turn-origin typed-user --message-identity declared --message-id $messageId --session-id s1 --transcript-path $transcript *> $null
}

function Invoke-Record {
    param([string]$Root, [string]$Key, [string]$Chosen)
    & $cli -ProjectRoot $Root -FeatureRef '001-feat' -Key $Key -Question ('Which ' + $Key + '?') `
        -OptionId '1', '2' -OptionSummary 'the first way', 'the second way' -Chosen $Chosen `
        -Rationale 'it fits the tests' -HumanTurn ('design decision: option ' + $Chosen) -AsJson *> $null
}

function Get-RecordBlock {
    # The record's own bytes in the document: from its key to the brace that closes it.
    param([string]$Text, [string]$Key)
    return [regex]::Match($Text, '(?s)"' + [regex]::Escape($Key) + '": \{.*?\r?\n    \}').Value
}

$root = Join-Path ([IO.Path]::GetTempPath()) ('specrew-dddates-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
New-Item -ItemType Directory -Force -Path (Join-Path $root 'specs/001-feat'), (Join-Path $root '.specrew') | Out-Null
Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
& git init -q -b 001-feat $root 2>&1 | Out-Null
$path = Join-Path $root 'specs/001-feat/design-decisions.json'
try {
    Send-TypedMessage -Root $root -Text 'design decision: option 2'
    Invoke-Record -Root $root -Key 'decomposition-style' -Chosen '2'
    $first = [IO.File]::ReadAllText($path)
    $iso = '"(?:turn_observed_at|recorded_at)": "\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?[+-]\d\d:\d\d"'
    Assert-True (@([regex]::Matches($first, $iso)).Count -eq 2) 'a new record writes both dates as ISO 8601 with an explicit offset'

    # The earlier record as another writer or another machine may have left it: the same instant in another offset.
    $seeded = [regex]::Replace($first, '"turn_observed_at": "[^"]+"', '"turn_observed_at": "2026-11-07T05:55:24.2686599+05:45"')
    [IO.File]::WriteAllText($path, $seeded, [Text.UTF8Encoding]::new($false))
    $before = Get-RecordBlock -Text $seeded -Key 'decomposition-style'
    Assert-True ($before -match '\+05:45') 'the earlier record carries its own offset before the next decision'

    Send-TypedMessage -Root $root -Text 'design decision: option 1'
    Invoke-Record -Root $root -Key 'storage-shape' -Chosen '1'
    $after = [IO.File]::ReadAllText($path)
    Assert-True ($after.Contains('"storage-shape"')) 'the second decision is recorded'
    Assert-True ((Get-RecordBlock -Text $after -Key 'decomposition-style') -ceq $before) 'recording a new decision leaves the earlier record byte-identical, its dates included'
}
finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }

if ($script:failCount -gt 0) { Write-Host "design-decision-dates-kept: $script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'design-decision-dates-kept: all cases passed' -ForegroundColor Green
