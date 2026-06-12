$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (T002 fix F2). REGRESSION floor for the reviewer finding: "agent-authored handover can
# erase the conversation section". The 'Recent conversation' section is HOOK-owned - only the Stop/PostToolUse
# hook captures it from the host transcript; the agent body-author (Write-SpecrewHandoverContext) never
# supplies it. Before the fix the shared writer placeholdered every section the agent omitted, so authoring
# the boundary packet WIPED the captured conversation. This pins the hook->agent->read flow: the conversation
# survives an agent author, the agent still overrides sections it DID author, and a no-prior-file author does
# NOT invent a conversation. Hermetic: HandoverStore I/O + temp files only (no git/provider/subprocess).

. "$PSScriptRoot/../../scripts/internal/bootstrap/HandoverStore.ps1"
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$convoTitle = 'Recent conversation (last few exchanges, hook-captured)'
$didTitle = 'What I just did (last 3-5 turns or last boundary work)'
$openTitle = 'Open questions / pending clarifications'

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("f2-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ("f2b-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp2 -Force | Out-Null
try {
    $convoBody = "- **user:** CANARY-USER ship the fix`n- **assistant:** CANARY-ASSISTANT shipped it"

    # 1. HOOK writes the rolling handover carrying the captured conversation (a mechanical section).
    Write-SpecrewRollingHandover -HandoverDir $tmp -Source 'Stop' -FromHost 'claude' -RecordedAt '2026-06-12T00:00:00Z' `
        -ActiveBoundary 'implement' -ActiveFeature 'feat-x' `
        -MechanicalSections @{ $convoTitle = $convoBody; $didTitle = 'hook: committed F2' } | Out-Null
    $p1 = ConvertFrom-SpecrewHandoverFile -Path (Get-SpecrewRollingHandoverPath -HandoverDir $tmp)
    Assert-True ($p1.sections[$convoTitle] -like '*CANARY-ASSISTANT*') 'setup: the hook wrote the conversation section'

    # 2. AGENT body-author persists its rich packet WITHOUT a conversation section (it never captures one).
    Write-SpecrewHandoverContext -HandoverDir $tmp -FromHost 'claude' -RecordedAt '2026-06-12T01:00:00Z' `
        -ActiveBoundary 'implement' -ActiveFeature 'feat-x' -Sections @{
            $didTitle  = 'agent: authored the boundary packet'
            $openTitle = 'an agent question'
        } | Out-Null

    # 3. READ back: the hook-captured conversation SURVIVES (the core fix), the agent's own sections wrote.
    $p2 = ConvertFrom-SpecrewHandoverFile -Path (Get-SpecrewRollingHandoverPath -HandoverDir $tmp)
    Assert-True ($p2.sections[$convoTitle] -like '*CANARY-ASSISTANT*') 'F2: the agent author PRESERVES the hook-captured conversation (not erased)'
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content $p2.sections[$convoTitle]) 'F2: the preserved conversation is authored content, not a placeholder'
    Assert-True ($p2.sections[$didTitle] -like '*agent: authored*') 'F2: the agent still OVERRIDES a mechanical section it DID author'
    Assert-True ($p2.sections[$openTitle] -eq 'an agent question') 'F2: the agent interpretive section wrote through'

    # 4. NEGATIVE: with NO prior file, the agent author must NOT invent a conversation (stays a placeholder).
    Write-SpecrewHandoverContext -HandoverDir $tmp2 -FromHost 'claude' -RecordedAt '2026-06-12T01:00:00Z' `
        -ActiveBoundary 'implement' -ActiveFeature 'feat-x' -Sections @{ $openTitle = 'q' } | Out-Null
    $p3 = ConvertFrom-SpecrewHandoverFile -Path (Get-SpecrewRollingHandoverPath -HandoverDir $tmp2)
    Assert-True (-not (Test-SpecrewHandoverSectionAuthored -Content $p3.sections[$convoTitle])) 'F2: no prior file -> the conversation stays a placeholder (no fabrication)'

    Write-Host "`n=== HandoverConversationPreserve.Tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp2 -Recurse -Force -ErrorAction SilentlyContinue
}
