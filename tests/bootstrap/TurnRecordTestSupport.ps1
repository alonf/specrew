# Feature 202 T002: the bootstrap consumes the hook dispatcher's standard turn record, never a raw host payload.
# Tests build that record the way the dispatcher hands it over (base64 v1 JSON) and decode it through the same
# adapter the bootstrap provider uses, so the decode path stays under test.

function ConvertTo-SpecrewTestTurnRecordArgument {
    # The exact --turn-record argument the dispatcher passes a provider. No session id -> a per-launch token,
    # as the dispatcher does. Needs nothing loaded, for tests that drive the provider process directly.
    param([AllowNull()][string]$SessionId, [AllowNull()][string]$Source = 'startup', [string]$HostName = 'claude')
    $safe = if ([string]::IsNullOrWhiteSpace($SessionId)) { 'launch-' + [guid]::NewGuid().ToString('N') } else { ((([string]$SessionId) -replace '[^a-zA-Z0-9-]+', '-').Trim('-')) }
    $record = [ordered]@{
        schema = 'specrew-turn-record/v1'; event = 'SessionStart'; host = $HostName
        session_id = if ([string]::IsNullOrWhiteSpace($SessionId)) { $null } else { $SessionId }
        safe_session_id = $safe; source = $Source; origin = 'unknown'; transcript_path = $null; stop_hook_active = $false
    }
    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($record | ConvertTo-Json -Compress)))
}

# Requires HostEventAdapter.ps1.
function New-SpecrewTestTurnRecord {
    param([AllowNull()][string]$SessionId, [AllowNull()][string]$Source = 'startup', [string]$HostName = 'claude')
    $safe = if ([string]::IsNullOrWhiteSpace($SessionId)) { 'launch-' + [guid]::NewGuid().ToString('N') } else { ConvertTo-SpecrewFilesystemSafeSessionId -RawSessionId $SessionId }
    $record = [ordered]@{
        schema           = 'specrew-turn-record/v1'
        event            = 'SessionStart'
        host             = $HostName
        session_id       = if ([string]::IsNullOrWhiteSpace($SessionId)) { $null } else { $SessionId }
        safe_session_id  = $safe
        source           = $Source
        origin           = 'unknown'
        transcript_path  = $null
        stop_hook_active = $false
    }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($record | ConvertTo-Json -Compress)))
    return (ConvertFrom-SpecrewTurnRecordArgument -Encoded $encoded)
}
