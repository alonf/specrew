Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

# A valid Claude SessionStart payload is normalized and the session id is sanitized.
$raw = '{"session_id":"abc/12 3","source":"startup","hook_event_name":"SessionStart","cwd":"C:/proj"}'
$r = ConvertFrom-SpecrewHostHookEvent -RawEvent $raw -HostName claude
Assert-Equal $r.host 'claude' 'host normalized to claude'
Assert-Equal $r.source 'startup' 'source extracted'
Assert-Equal $r.event_name 'SessionStart' 'event name extracted'
Assert-Equal $r.safe_session_id 'abc-12-3' 'session id sanitized to filename-safe token'
Assert-Equal $r.project_root 'C:/proj' 'project root taken from cwd'
Assert-True $r.parsed 'parsed=true for valid JSON'

# Malformed JSON fails open (parsed=false, no throw).
$r2 = ConvertFrom-SpecrewHostHookEvent -RawEvent 'not json' -HostName claude
Assert-True (-not $r2.parsed) 'parsed=false for malformed JSON (fail-open)'
Assert-Equal $r2.host 'claude' 'host still set on malformed JSON'

# Explicit ProjectRoot is used when the event carries no cwd.
$r3 = ConvertFrom-SpecrewHostHookEvent -RawEvent '' -HostName claude -ProjectRoot 'C:/x'
Assert-Equal $r3.project_root 'C:/x' 'explicit ProjectRoot used when event empty'
Assert-True ($r3.safe_session_id -match '^launch-[a-f0-9]{32}$') 'empty event gets a per-launch fallback session token'

# Blank or malformed IDs do not collapse into a global unknown bucket.
$r4 = ConvertFrom-SpecrewHostHookEvent -RawEvent '{"session_id":"   ","source":"startup"}' -HostName claude
$r5 = ConvertFrom-SpecrewHostHookEvent -RawEvent '{"session_id":"!!!","source":"startup"}' -HostName claude
Assert-True ($r4.safe_session_id -match '^launch-[a-f0-9]{32}$') 'blank session id gets a per-launch fallback token'
Assert-True ($r5.safe_session_id -match '^launch-[a-f0-9]{32}$') 'malformed session id gets a per-launch fallback token'
Assert-True ($r4.safe_session_id -ne $r5.safe_session_id) 'fallback tokens are per launch, not shared'
Assert-True ($r4.safe_session_id -ne 'unknown' -and $r5.safe_session_id -ne 'unknown') 'fallback tokens never use global unknown'

Write-Host 'HostEventAdapter: all tests passed.' -ForegroundColor Green
