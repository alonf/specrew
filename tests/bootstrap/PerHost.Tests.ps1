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

# All four hosts normalize the snake_case (Claude-style) SessionStart event.
foreach ($h in 'claude', 'codex', 'copilot', 'cursor') {
    $e = ConvertFrom-SpecrewHostHookEvent -RawEvent '{"source":"startup","session_id":"abc-123","hook_event_name":"SessionStart","cwd":"C:/proj"}' -HostName $h
    Assert-Equal $e.host $h "host recorded ($h)"
    Assert-Equal $e.source 'startup' "source normalized ($h)"
    Assert-Equal $e.session_id 'abc-123' "session_id normalized ($h)"
    Assert-Equal $e.project_root 'C:/proj' "cwd -> project_root ($h)"
}

# A camelCase host convention normalizes through the multi-key extraction.
$cc = ConvertFrom-SpecrewHostHookEvent -RawEvent '{"trigger":"resume","sessionId":"S-9","workspaceRoot":"D:/w"}' -HostName codex
Assert-Equal $cc.source 'resume' 'camelCase trigger -> source'
Assert-Equal $cc.session_id 'S-9' 'camelCase sessionId -> session_id'
Assert-Equal $cc.project_root 'D:/w' 'camelCase workspaceRoot -> project_root'

# session_id is sanitized to a filename-safe token before any path use.
$san = ConvertFrom-SpecrewHostHookEvent -RawEvent '{"source":"startup","session_id":"a/b\\c:d"}' -HostName claude
Assert-Equal $san.safe_session_id 'a-b-c-d' 'session_id sanitized to filename-safe token'

# Garbage payload fails open (parsed=false), host still recorded.
$bad = ConvertFrom-SpecrewHostHookEvent -RawEvent 'not json at all' -HostName cursor
Assert-True (-not $bad.parsed) 'garbage event -> parsed=false (fail-open)'
Assert-Equal $bad.host 'cursor' 'host still recorded on a garbage event'

Write-Host 'PerHost: all tests passed.' -ForegroundColor Green
