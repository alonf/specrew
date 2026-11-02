# Feature 203 iteration 001, T001 (FR-016; DA-2; research.md R1): one typed prompt has one identity on Copilot.
#
# Copilot delivers each prompt to two hook channels: its own userPromptSubmitted hook and the Claude UserPromptSubmit
# hook in .claude/settings.local.json, which it also runs. T001 captured both firings of one prompt on Copilot 1.0.103
# (tests/fixtures/hook-payloads/copilot/one-prompt-two-firings, provenance there). They carry the same session id,
# the same prompt text and the same instant to the millisecond, in two encodings (epoch ms and ISO 8601). The hooks
# themselves ran 727 ms apart.
#
# Copilot sends no message id, so today its binding declares message identity 'none' and the prompt path keys the
# turn on the time the HOOK RAN (TurnArrival = now). Two firings, or the same payload seen twice, are then two
# identities. R1's decision: Copilot's identity is derived from the payload alone (session id, the instant
# normalized to UTC epoch ms, the prompt text) and declared in the binding, so every path that sees the prompt
# computes the same key.
#
# RED before T003:
#   - the deployed Copilot hook hands the handover provider message identity 'none' and no message id;
#   - so the same payload replayed later, and a payload one millisecond later, cannot be told apart from it or
#     matched to it.
# Green today, and kept: the two captured firings agree on the inputs the identity is built from, and the Claude
# hook run by Copilot stands down (B4F-129), so only one channel carries the prompt to a provider.
#
# Not in a per-round lane until T003 turns it green (.specrew/release-gate-suites.txt until then).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pairRoot = Join-Path $repoRoot 'tests\fixtures\hook-payloads\copilot\one-prompt-two-firings'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

. (Join-Path $repoRoot 'tests\host-probes\deployed-hook-harness.ps1')

function Get-ArgValue {
    param([string[]]$ArgList, [string]$Name)
    for ($i = 0; $i -lt $ArgList.Count - 1; $i++) { if ($ArgList[$i] -ceq $Name) { return $ArgList[$i + 1] } }
    return $null
}

function ConvertTo-EpochMs {
    # The raw JSON text is read, not ConvertFrom-Json's DateTime, which drops the offset and the format.
    param([string]$Json)
    $m = [regex]::Match($Json, '"timestamp"\s*:\s*("([^"]+)"|(\d+))')
    if (-not $m.Success) { return $null }
    if ($m.Groups[3].Success) { return [int64]$m.Groups[3].Value }
    return [DateTimeOffset]::Parse($m.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal).ToUnixTimeMilliseconds()
}

function Invoke-CopilotPrompt {
    param($Fixture, [byte[]]$Bytes)
    $r = Invoke-DeployedHook -Fixture $Fixture -NativeEvent 'userPromptSubmitted' -StdinBytes $Bytes
    $hand = $r.Calls['specrew-handover-provider.ps1']
    return [pscustomobject]@{
        ExitCode = $r.ExitCode
        Ran      = ($null -ne $hand)
        Identity = if ($null -ne $hand) { Get-ArgValue $hand '--message-identity' } else { $null }
        Id       = if ($null -ne $hand) { Get-ArgValue $hand '--message-id' } else { $null }
    }
}

$nativeBytes = [IO.File]::ReadAllBytes((Join-Path $pairRoot 'native-userpromptsubmitted.json'))
$claudeBytes = [IO.File]::ReadAllBytes((Join-Path $pairRoot 'claude-hooks-userpromptsubmit.json'))
$nativeText = [Text.Encoding]::UTF8.GetString($nativeBytes)
$claudeText = [Text.Encoding]::UTF8.GetString($claudeBytes)
$native = $nativeText | ConvertFrom-Json
$claude = $claudeText | ConvertFrom-Json

Write-Host '--- the host fact: both firings of one prompt carry the same inputs ---'
Assert-True ([string]$native.sessionId -ceq [string]$claude.session_id) 'both firings carry the same session id'
Assert-True ([string]$native.prompt -ceq [string]$claude.prompt) 'both firings carry the same prompt text'
$nativeMs = ConvertTo-EpochMs $nativeText
$claudeMs = ConvertTo-EpochMs $claudeText
Assert-True ($null -ne $nativeMs -and $nativeMs -eq $claudeMs) ("both firings carry the same instant to the millisecond (native {0}, Claude hook {1})" -f $nativeMs, $claudeMs)

$projects = @{}
try {
    foreach ($h in 'claude', 'copilot') { $projects[$h] = New-TurnRecordProject -HostKind $h }

    Write-Host '--- the Claude hook run by Copilot stands down (B4F-129): one channel reaches a provider ---'
    $r = Invoke-DeployedHook -Fixture $projects['claude'] -NativeEvent 'UserPromptSubmit' -StdinBytes $claudeBytes
    Assert-True ($r.ExitCode -eq 0) 'the Claude hook exits 0 on the Copilot-run payload'
    Assert-True (@($r.Calls.Keys).Count -eq 0) 'the Claude hook run by Copilot runs no provider'

    Write-Host '--- the Copilot firing carries an identity built from the payload alone (RED before T003) ---'
    $first = Invoke-CopilotPrompt -Fixture $projects['copilot'] -Bytes $nativeBytes
    Assert-True ($first.ExitCode -eq 0 -and $first.Ran) 'the Copilot hook exits 0 and the handover provider runs'
    Assert-True ([string]$first.Identity -ceq 'declared') ("the binding declares a message identity for Copilot (got '{0}')" -f $first.Identity)
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$first.Id)) 'the handover provider receives a message id'

    # The same bytes seen again later (a second path, a retry): the hook runs at a different time, the identity
    # must not change.
    Start-Sleep -Milliseconds 1100
    $again = Invoke-CopilotPrompt -Fixture $projects['copilot'] -Bytes $nativeBytes
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$again.Id) -and [string]$again.Id -ceq [string]$first.Id) 'the same payload seen again later has the same message id'

    # SYNTHETIC: the same prompt typed again one millisecond later is a different act.
    $laterText = $nativeText -replace ('"timestamp":' + $nativeMs), ('"timestamp":' + ($nativeMs + 1))
    $later = Invoke-CopilotPrompt -Fixture $projects['copilot'] -Bytes ([Text.UTF8Encoding]::new($false).GetBytes($laterText))
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$later.Id) -and [string]$later.Id -cne [string]$first.Id) 'SYNTHETIC: the same prompt one millisecond later has a different message id'
}
finally {
    foreach ($p in $projects.Values) { Remove-Item -LiteralPath $p.Base -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:failCount -gt 0) { Write-Host "typed-turn-identity: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'typed-turn-identity: all passed' -ForegroundColor Green
exit 0
