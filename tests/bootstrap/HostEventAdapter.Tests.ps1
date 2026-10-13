Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 202 T002: the bootstrap no longer normalizes host payloads; it decodes the standard turn record the
# hook dispatcher hands it (--turn-record). These cases pin the decoder: it accepts only a v1 record, and it
# never trusts the record's safe id for a filename.
. "$PSScriptRoot/../../scripts/internal/bootstrap/HostEventAdapter.ps1"

function Assert-Equal {
    param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function New-EncodedRecord {
    param([hashtable]$Fields)
    $record = [ordered]@{ schema = 'specrew-turn-record/v1'; event = 'SessionStart'; host = 'claude'; source = 'startup'; origin = 'unknown' }
    foreach ($k in $Fields.Keys) { $record[$k] = $Fields[$k] }
    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($record | ConvertTo-Json -Compress)))
}

# A valid record decodes with its fields intact.
$r = ConvertFrom-SpecrewTurnRecordArgument -Encoded (New-EncodedRecord @{ session_id = 'abc-123'; safe_session_id = 'abc-123' })
Assert-Equal $r.host 'claude' 'host decoded'
Assert-Equal $r.source 'startup' 'source decoded'
Assert-Equal $r.session_id 'abc-123' 'session id decoded'
Assert-Equal $r.safe_session_id 'abc-123' 'safe session id decoded'

# The safe id is re-derived from the raw id, never trusted: a hostile safe id cannot reach a filename.
$hostile = ConvertFrom-SpecrewTurnRecordArgument -Encoded (New-EncodedRecord @{ session_id = 'a/b\c:d'; safe_session_id = '../../etc' })
Assert-Equal $hostile.safe_session_id 'a-b-c-d' 'safe id re-derived from the raw id'

# No host session id: a well-formed per-launch token is kept; anything else is replaced with a fresh one.
$token = 'launch-' + [guid]::NewGuid().ToString('N')
$kept = ConvertFrom-SpecrewTurnRecordArgument -Encoded (New-EncodedRecord @{ session_id = $null; safe_session_id = $token })
Assert-Equal $kept.safe_session_id $token 'the dispatcher''s per-launch token is kept, so both sides share one key'
$replaced = ConvertFrom-SpecrewTurnRecordArgument -Encoded (New-EncodedRecord @{ session_id = $null; safe_session_id = 'unknown' })
Assert-True ($replaced.safe_session_id -match '^launch-[a-f0-9]{32}$') 'a malformed per-launch token is replaced, never a global bucket'

# Absent, garbage, or wrong-schema input yields $null (the bootstrap then degrades to full mode).
Assert-True ($null -eq (ConvertFrom-SpecrewTurnRecordArgument -Encoded '')) 'empty argument -> $null'
Assert-True ($null -eq (ConvertFrom-SpecrewTurnRecordArgument -Encoded 'not base64 at all!')) 'garbage argument -> $null'
$otherSchema = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('{"schema":"something-else","session_id":"x"}'))
Assert-True ($null -eq (ConvertFrom-SpecrewTurnRecordArgument -Encoded $otherSchema)) 'a record of another schema -> $null'
$rawPayload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('{"session_id":"x","source":"startup"}'))
Assert-True ($null -eq (ConvertFrom-SpecrewTurnRecordArgument -Encoded $rawPayload)) 'a raw host payload is not a record -> $null'

# The second normalizer is gone: the adapter exposes no payload parser.
Assert-True ($null -eq (Get-Command ConvertFrom-SpecrewHostHookEvent -ErrorAction SilentlyContinue)) 'ConvertFrom-SpecrewHostHookEvent no longer exists'

Write-Host 'HostEventAdapter: all tests passed.' -ForegroundColor Green
