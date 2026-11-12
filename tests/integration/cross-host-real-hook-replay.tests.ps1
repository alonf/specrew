# Feature 203 T013 (FR-042; maintainer ruling 2026-11-13): A VERDICT TYPED AFTER A COMPACTION, THROUGH CLAUDE'S REAL HOOK.
#
# FR-042 asks for cross-host tests through each host's real adapter with recorded payloads, including a compaction between
# packet and reply. This suite builds what the existing recordings allow on Claude: the packet, then the recorded automatic
# compaction (tests/fixtures/hook-payloads/claude/compaction, Claude Code 2.1.312: the last prompt, the compact boundary and
# the summary that quotes approval phrases), then the human's typed verdict, delivered as the recorded UserPromptSubmit
# payload (tui-userpromptsubmit-typed.json, its prompt replaced) through the command the real deployer wrote, to the real
# dispatcher and providers. The host writes the message's transcript record after the hook (measured 2026-11-12), so the
# record is appended after the hook runs; the recorded verdict is then used through the shared matcher, which runs the
# sender check against that record.
#
# Copilot and Codex have no compaction recording, so their compaction replay moves to the iteration-002 three-host walk
# (maintainer ruling 2026-11-13).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$fixtures = Join-Path $repoRoot 'tests\fixtures\hook-payloads\claude'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

# The base folder is this suite's own, under the temp folder, and is the only thing it removes.
$base = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('xhost-replay-' + [guid]::NewGuid().ToString('N').Substring(0, 8))))
$proj = Join-Path $base 'proj'
$userHome = Join-Path $base 'home'
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $proj '.specrew'), (Join-Path $proj '.specify\extensions'), $userHome | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit') -Destination (Join-Path $proj '.specify\extensions\specrew-speckit') -Recurse -Force
    # A project at implement's door: tasks authorized, before-implement waiting for the human's verdict.
    $ctx = [ordered]@{
        schema               = 'v2'
        feature_path         = (Join-Path $proj 'specs\046-test')
        session_state        = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '046-test'; iteration_number = '001'; recorded_at = '2026-11-13T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))

    $deployLog = Join-Path $base 'deploy.log'
    & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1') -ProjectPath $proj -HostKind 'claude' -UserHomeOverride $userHome *> $deployLog
    Assert-True ($LASTEXITCODE -eq 0) ('the real deployer wrote Claude''s hooks for the project ({0})' -f ((Get-Content -LiteralPath $deployLog -Raw -ErrorAction SilentlyContinue) -replace '\s+', ' ').Trim())
    $settings = Get-Content -LiteralPath (Join-Path $proj '.claude\settings.local.json') -Raw | ConvertFrom-Json
    $command = [string]$settings.hooks.UserPromptSubmit[0].hooks[0].command

    # The transcript as the host holds it when the verdict's prompt hook fires: the packet, then the recorded compaction.
    $transcript = Join-Path $base 'session.jsonl'
    $packet = [ordered]@{ type = 'assistant'; uuid = [guid]::NewGuid().ToString(); message = [ordered]@{ role = 'assistant'; content = @(@{ type = 'text'; text = ("Packet body: the tasks are ready.`n`n<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->") }) } }
    $lines = @(($packet | ConvertTo-Json -Depth 8 -Compress)) + @(Get-Content -LiteralPath (Join-Path $fixtures 'compaction\tui-compaction-transcript-excerpt.jsonl'))
    [IO.File]::WriteAllText($transcript, (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
    $summary = @(Get-Content -LiteralPath $transcript | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.PSObject.Properties['isCompactSummary'] -and $_.isCompactSummary })
    Assert-True ($summary.Count -eq 1) 'the recorded compaction summary sits between the packet and the reply'

    # The recorded prompt payload, carrying the typed verdict.
    $payload = Get-Content -LiteralPath (Join-Path $fixtures 'tui-userpromptsubmit-typed.json') -Raw | ConvertFrom-Json
    $verdict = 'approved for before-implement'
    $payload.prompt = $verdict
    $payload.transcript_path = $transcript
    $payload.cwd = $proj
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($payload | ConvertTo-Json -Compress -Depth 5))

    $tokens = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($command, '"((?:[^"\\]|\\.)*)"|(\S+)')) { if ($m.Groups[1].Success) { $tokens.Add($m.Groups[1].Value.Replace('\"', '"')) } else { $tokens.Add($m.Groups[2].Value) } }
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $tokens[0]
    foreach ($a in $tokens[1..($tokens.Count - 1)]) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $proj
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.Environment['CLAUDE_PROJECT_DIR'] = $proj
    $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
    $psi.Environment['SPECREW_USER_HOME_OVERRIDE'] = $userHome
    $proc = [System.Diagnostics.Process]::Start($psi)
    $outTask = $proc.StandardOutput.ReadToEndAsync(); $errTask = $proc.StandardError.ReadToEndAsync()
    $proc.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length); $proc.StandardInput.Close()
    if (-not $proc.WaitForExit(120000)) { $proc.Kill($true); throw 'the deployed prompt hook timed out' }
    $null = $outTask.Result; $hookErr = $errTask.Result
    Assert-True ($proc.ExitCode -eq 0) ('the deployed prompt hook exits 0 ({0})' -f ($hookErr -replace '\s+', ' ').Trim())

    $history = @((Get-Content -LiteralPath (Join-Path $proj '.specrew\start-context.json') -Raw | ConvertFrom-Json -Depth 12).boundary_enforcement.verdict_history)
    Assert-True ($history.Count -eq 1) ("the typed verdict after the compaction is recorded once, and the summary quoting approval phrases records nothing (got {0})" -f $history.Count)
    $entry = if ($history.Count -ge 1) { $history[-1] } else { $null }
    Assert-True ($null -ne $entry -and [string]$entry.to_boundary -eq 'before-implement' -and [string]$entry.evidence_source -match '^hook-captured' -and -not [string]::IsNullOrWhiteSpace([string]$entry.turn_identity)) 'the verdict is captured from the prompt, names before-implement and carries its turn'

    # The host writes the message's record after the hook; then the verdict is used through the shared matcher.
    $record = [ordered]@{ type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = [string]$payload.prompt_id; sessionId = [string]$payload.session_id; timestamp = '2026-11-13T00:00:01.000Z'
        turnOrigin = 'human'; promptSource = 'typed'; origin = [ordered]@{ kind = 'human' }; message = [ordered]@{ role = 'user'; content = $verdict } }
    [IO.File]::AppendAllText($transcript, (($record | ConvertTo-Json -Depth 6 -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
    $prior = $env:SPECREW_MODULE_PATH
    try {
        $env:SPECREW_MODULE_PATH = $repoRoot
        . (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
        $covers = if ($null -ne $entry) { Find-SpecrewCycleScopedAuthorization -ProjectRoot $proj -History @($entry) -ToBoundary 'before-implement' -FromBoundary 'tasks' -LastAuthorizedBoundary 'tasks' 2>$null } else { $null }
    }
    finally { $env:SPECREW_MODULE_PATH = $prior }
    Assert-True ($null -ne $covers) 'the verdict is used: its turn is found and the transcript record says the human typed it'
}
finally {
    if ($base.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $base) -like 'xhost-replay-*') {
        Remove-Item -LiteralPath $base -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($script:failCount -gt 0) { Write-Host "cross-host-real-hook-replay: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'cross-host-real-hook-replay: all passed' -ForegroundColor Green
exit 0
