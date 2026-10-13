$ErrorActionPreference = 'Stop'

# Feature 202 T002 (DA-1 option B): each host's input contract is DATA in hosts/<host>/host.psd1. Before 202 this
# file asserted that every host accepted every key spelling - the permissive multi-key read that let two
# normalizers disagree. Now each host declares exactly where its fields are, and this file checks every
# declaration against that host's RECORDED payloads (tests/fixtures/hook-payloads/<host>/). The end-to-end
# delivery through the deployed hook is tests/unit/turn-record-contract.tests.ps1.
$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Resolve-DeclaredPath {
    param($Payload, [string[]]$Paths)
    foreach ($path in $Paths) {
        $node = $Payload
        foreach ($segment in $path.Split('.')) {
            if ($null -eq $node -or $null -eq $node.PSObject.Properties[$segment]) { $node = $null; break }
            $node = $node.PSObject.Properties[$segment].Value
        }
        if ($null -ne $node -and -not [string]::IsNullOrWhiteSpace([string]$node)) { return $node }
    }
    return $null
}

foreach ($h in 'claude', 'codex', 'copilot', 'cursor', 'antigravity') {
    $runtime = (Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot "hosts/$h/host.psd1")).RefocusHookBindings.DispatcherRuntime
    foreach ($field in 'SessionId', 'Prompt', 'TranscriptPath', 'Source') {
        Assert-True (@($runtime.InputFieldMap[$field]).Count -gt 0) "[$h] declares InputFieldMap.$field"
    }
    $rules = @($runtime.OriginRules)
    Assert-True ($rules.Count -gt 0 -and [string]$rules[-1].Rule -eq 'prompt-present' -and [string]$rules[-1].Origin -eq 'typed-user') "[$h] the last origin rule makes an unmatched prompt typed-user (FR-006: typed replies stay authority)"
    Assert-True (@($rules | Where-Object { $_.Rule -eq 'hook-output-journal' }).Count -eq 1) "[$h] the journal-match rule is declared (FR-005: every reply is matched)"
}

# Every declared path resolves on that host's recorded payloads (validated hosts only; experimental hosts have none).
foreach ($h in 'claude', 'codex', 'copilot') {
    $runtime = (Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot "hosts/$h/host.psd1")).RefocusHookBindings.DispatcherRuntime
    $prov = Get-Content -LiteralPath (Join-Path $repoRoot "tests/fixtures/hook-payloads/$h/provenance.json") -Raw | ConvertFrom-Json
    foreach ($entry in @($prov.fixtures | Where-Object { $_.PSObject.Properties['origin'] -and $_.origin -eq 'recorded' })) {
        $payload = [IO.File]::ReadAllText((Join-Path $repoRoot "tests/fixtures/hook-payloads/$h/$($entry.fixture)"), [Text.Encoding]::UTF8) | ConvertFrom-Json
        Assert-True ($null -ne (Resolve-DeclaredPath $payload @($runtime.InputFieldMap.SessionId))) "[$h $($entry.fixture)] the declared SessionId path resolves"
        if ($entry.event -eq 'UserPromptSubmit') {
            Assert-True ($null -ne (Resolve-DeclaredPath $payload @($runtime.InputFieldMap.Prompt))) "[$h $($entry.fixture)] the declared Prompt path resolves"
        }
        if ($entry.event -eq 'SessionStart') {
            Assert-True ($null -ne (Resolve-DeclaredPath $payload @($runtime.InputFieldMap.Source))) "[$h $($entry.fixture)] the declared Source path resolves"
        }
    }
}

Write-Host 'PerHost: all tests passed.' -ForegroundColor Green
