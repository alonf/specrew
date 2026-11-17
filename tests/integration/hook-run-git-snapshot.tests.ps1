# Feature 203 T025 (F3, the hook cost; DRIFT-073): every Stop run paid for the same read-only git questions three times
# over, because each provider - its own pwsh process - asked them again: is this a work tree, what is the prefix, what
# is HEAD, which branch, what is the working tree's status. Measured on 3ced8938b: 23 git processes per Stop run, each
# 0.17 to 0.21 s on the maintainer's machine. The design (iteration 002, Option A): the dispatcher takes ONE git
# snapshot per hook run and hands it to the providers, which stay separate processes; every hook check still runs.
#
# Entered as the host enters it: the real dispatcher, with its real provider catalog, on a scratch clone of this
# repository, the Stop payload on stdin, a redirected home, and GIT_TRACE logging every git process the run starts.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('hook-git-snapshot-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force

    # A scratch clone of this repository at HEAD (objects shared, so it is quick), with a start context naming an active
    # feature and iteration of its own so the providers do their ordinary work.
    $script:Project = Join-Path $script:Work 'proj'
    $null = & git clone -q --shared --no-checkout $script:RepoRoot $script:Project 2>&1
    $null = & git -C $script:Project -c advice.detachedHead=false checkout -q --detach ([string](& git -C $script:RepoRoot rev-parse HEAD)) 2>&1
    # The checkout's uncommitted changes to tracked files ride along, so the case judges the code as it stands (in a sweep
    # or in CI the tree is committed and this applies nothing).
    $pending = Join-Path $script:Work 'pending.patch'
    & git -C $script:RepoRoot diff HEAD --binary | Set-Content -LiteralPath $pending -Encoding utf8NoBOM
    if ((Get-Item -LiteralPath $pending).Length -gt 0) { $null = & git -C $script:Project apply --whitespace=nowarn $pending 2>&1 }
    $context = [ordered]@{
        schema_version       = '1.0'
        session_state        = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '203-beta5-stabilization'; iteration_number = '002' }
        boundary_enforcement = [ordered]@{
            enabled = $true; last_authorized_boundary = 'before-implement'; pending_next_boundary = $null; pending_crossing = $null
            policy_classes = @{}; verdict_history = @(); correction_history = @(); bypass_history = @()
        }
    }
    $null = New-Item -ItemType Directory -Path (Join-Path $script:Project '.specrew/runtime') -Force
    Set-Content -LiteralPath (Join-Path $script:Project '.specrew/start-context.json') -Value ($context | ConvertTo-Json -Depth 6) -Encoding utf8NoBOM

    $script:HomeDir = Join-Path $script:Work 'home'
    $null = New-Item -ItemType Directory -Path $script:HomeDir -Force
    $script:Transcript = Join-Path $script:Work 'transcript.jsonl'
    $lines = @(
        '{"type":"user","message":{"role":"user","content":"status"},"uuid":"u-1","promptId":"p-1"}',
        '{"type":"assistant","message":{"id":"msg_1","role":"assistant","content":[{"type":"text","text":"Nothing changed."}]},"uuid":"a-1"}'
    )
    Set-Content -LiteralPath $script:Transcript -Value $lines -Encoding utf8NoBOM

    function script:Invoke-StopRun {
        $trace = Join-Path $script:Work ('git-trace-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.txt')
        $payload = [ordered]@{ session_id = 'hook-git-snapshot'; transcript_path = $script:Transcript; cwd = $script:Project; hook_event_name = 'Stop'; stop_hook_active = $false }
        $dispatcher = Join-Path $script:Project 'extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
        $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
        foreach ($a in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', 'Stop', '-HostKind', 'claude', '-ProviderTimeoutSeconds', '180')) { $psi.ArgumentList.Add($a) }
        $psi.WorkingDirectory = $script:Project; $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
        $psi.Environment['GIT_TRACE'] = $trace
        $psi.Environment['SPECREW_USER_HOME_OVERRIDE'] = $script:HomeDir
        $process = [Diagnostics.Process]::new(); $process.StartInfo = $psi
        [void]$process.Start()
        $process.StandardInput.Write(($payload | ConvertTo-Json -Compress)); $process.StandardInput.Close()
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $calls = @(if (Test-Path -LiteralPath $trace) { Get-Content -LiteralPath $trace | Where-Object { $_ -match 'trace: built-in: git ' } | ForEach-Object { $_ -replace '^.*trace: built-in: git ', '' } })
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Calls = $calls; StdErr = $stderr.Result }
    }

    $script:Run = script:Invoke-StopRun
}

AfterAll {
    if ((Split-Path -Leaf $script:Work) -like 'hook-git-snapshot-*') { Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'T025: one git snapshot per Stop run (DRIFT-073)' {
    It 'the run completes and every provider ran (no provider skipped or timed out)' {
        $script:Run.ExitCode | Should -Be 0
        $script:Run.StdErr | Should -Not -Match 'timed out|budget exhausted' -Because 'a skipped provider would hide its git calls and make the count meaningless'
    }

    It 'asks whether this is a work tree, and for the prefix, at most once' {
        @($script:Run.Calls | Where-Object { $_ -match '^rev-parse .*--is-inside-work-tree' }).Count | Should -BeLessOrEqual 1
        @($script:Run.Calls | Where-Object { $_ -match '^rev-parse .*--show-prefix' }).Count | Should -BeLessOrEqual 1
    }

    It 'reads HEAD, the short HEAD, the branch and the last subject at most once each' {
        @($script:Run.Calls | Where-Object { $_ -ceq 'rev-parse HEAD' }).Count | Should -Be 0 -Because 'the snapshot carries HEAD'
        @($script:Run.Calls | Where-Object { $_ -ceq 'rev-parse --short HEAD' }).Count | Should -Be 0 -Because 'the snapshot carries the short HEAD'
        @($script:Run.Calls | Where-Object { $_ -match '^rev-parse .*--abbrev-ref HEAD' }).Count | Should -BeLessOrEqual 1
        @($script:Run.Calls | Where-Object { $_ -match '^log -1 ' }).Count | Should -BeLessOrEqual 1
    }

    It 'scans the project''s working tree status once for the providers (the navigator''s whole-repository scan aside)' {
        @($script:Run.Calls | Where-Object { $_ -match '^status .*-- \.' }).Count | Should -BeLessOrEqual 1
    }

    It 'starts no more than 13 git processes in all (23 on 3ced8938b)' {
        $script:Run.Calls.Count | Should -BeLessOrEqual 13 -Because ("the calls were:`n" + ($script:Run.Calls -join "`n"))
    }
}
