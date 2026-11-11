# B5F-040 (maintainer ruling 2026-11-11): no git command on the hook path takes an optional lock.
#
# The conformance provider runs `git status` in the project on every PostToolUse, UserPromptSubmit and Stop. Plain
# `git status` may take .git/index.lock to write refreshed stat data back to the index; when the host kills the hook
# mid-run the lock stays, and the next commit in the project fails. That is what most likely left the empty
# index.lock of 2026-11-10 16:08:07 in the 203 worktree, when Claude Code cancelled a PostToolUse hook. The hook
# dispatcher now sets GIT_OPTIONAL_LOCKS=0 for itself and every provider it starts.
#
# Each dispatcher copy (scripts/internal and the extension's) runs a stub provider in a fixture repository whose
# tracked file has new stat data only. The stub records the variable it was given and runs the same `git status` the
# turn snapshot runs. RED before the fix: the variable is empty, and the fixture's index is rewritten.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$dispatchers = [ordered]@{
    'scripts/internal'                    = Join-Path $repoRoot 'scripts/internal/specrew-hook-dispatcher.ps1'
    'extensions/specrew-speckit/scripts'  = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
}
$savedLocks = $env:GIT_OPTIONAL_LOCKS
Remove-Item Env:\GIT_OPTIONAL_LOCKS -ErrorAction SilentlyContinue
try {
    foreach ($entry in $dispatchers.GetEnumerator()) {
        foreach ($event in @('PostToolUse', 'UserPromptSubmit')) {
            $proj = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('gol-' + [guid]::NewGuid().ToString('N').Substring(0, 10))))
            $scriptsDir = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
            New-Item -ItemType Directory -Force -Path $scriptsDir, (Join-Path $proj '.specrew/runtime') | Out-Null
            try {
                Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n.specify/`nevent.json`nd.out`nd.err" -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $proj 'a.txt') -Value 'tracked' -Encoding UTF8
                $null = & git -C $proj init -q 2>&1
                $null = & git -C $proj add -A 2>&1
                $null = & git -C $proj -c user.name=t -c user.email=t@example.invalid commit -qm base 2>&1

                $envFile = Join-Path $proj '.specrew/runtime/provider-env.txt'
                $stub = @"
Set-Content -LiteralPath '$envFile' -Value ("[" + [string]`$env:GIT_OPTIONAL_LOCKS + "]") -Encoding UTF8
`$null = & git -c core.quotepath=false -C '$proj' status --porcelain=v1 --untracked-files=all -- . 2>`$null
exit 0
"@
                Set-Content -LiteralPath (Join-Path $scriptsDir 'stub-git.ps1') -Value $stub -Encoding UTF8
                $catalog = @{ schema_version = '1'; providers = @(@{ id = 'stub-git'; kind = 'inject'; events = @('PostToolUse', 'UserPromptSubmit'); order = 40; budget_share = 1.0; command = 'stub-git.ps1' }) } | ConvertTo-Json -Depth 6
                Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8

                # New stat data for the tracked file, content unchanged: plain `git status` would write the refreshed
                # stat back to the index.
                (Get-Item -LiteralPath (Join-Path $proj 'a.txt')).LastWriteTime = (Get-Date).AddMinutes(-7)
                $indexPath = Join-Path $proj '.git/index'
                $indexBefore = (Get-Item -LiteralPath $indexPath).LastWriteTimeUtc.Ticks
                Start-Sleep -Milliseconds 1100

                $evt = @{ session_id = 'gol1'; hook_event_name = $event; tool_name = 'Bash'; prompt = 'continue'; prompt_id = 'p1' }
                $eventFile = Join-Path $proj 'event.json'
                Set-Content -LiteralPath $eventFile -Value ($evt | ConvertTo-Json -Compress) -Encoding UTF8 -NoNewline
                $p = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $entry.Value, '-Event', $event, '-HostKind', 'claude') `
                    -WorkingDirectory $proj -NoNewWindow -PassThru -Wait `
                    -RedirectStandardInput $eventFile -RedirectStandardOutput (Join-Path $proj 'd.out') -RedirectStandardError (Join-Path $proj 'd.err')

                $seen = if (Test-Path -LiteralPath $envFile) { ([string](Get-Content -LiteralPath $envFile -Raw)).Trim() } else { '(the provider did not run)' }
                $indexAfter = (Get-Item -LiteralPath $indexPath).LastWriteTimeUtc.Ticks
                Assert-True ($p.ExitCode -eq 0) ("{0} {1}: the dispatcher exits 0" -f $entry.Key, $event)
                Assert-True ($seen -eq '[0]') ("{0} {1}: the provider runs with GIT_OPTIONAL_LOCKS=0 (saw {2})" -f $entry.Key, $event, $seen)
                Assert-True ($indexAfter -eq $indexBefore) ("{0} {1}: its git status leaves the project's index unwritten" -f $entry.Key, $event)
                Assert-True (-not (Test-Path -LiteralPath (Join-Path $proj '.git/index.lock'))) ("{0} {1}: no index.lock is left" -f $entry.Key, $event)
            }
            finally { Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}
finally {
    if ($null -ne $savedLocks) { $env:GIT_OPTIONAL_LOCKS = $savedLocks }
}
if ($script:failCount -gt 0) { Write-Host ("hook-git-optional-locks: {0} failure(s)" -f $script:failCount) -ForegroundColor Red; exit 1 }
Write-Host 'hook-git-optional-locks: all passed' -ForegroundColor Green
