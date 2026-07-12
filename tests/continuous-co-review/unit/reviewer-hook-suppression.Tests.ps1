#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# Root cause of the codex reviewer empty-exit0 failures (diagnosis 2026-07-12): the reviewer subprocess
# inherited the environment, so codex-the-reviewer's OWN global Specrew hooks fired while it reviewed,
# and the codex Stop hook (a decision-block) ran the Specrew dispatcher against the extracted specs/ in
# the reviewer worktree - derailing codex into empty output. The fix sets the launcher/dispatcher kill
# switch SPECREW_REFOCUS_DISABLE=1 on the reviewer subprocess. These two DETERMINISTIC regressions prove
# the two halves of the fix (no live reviewer host required):
#   1. the reviewer launch path passes SPECREW_REFOCUS_DISABLE=1 to its child process, and
#   2. the hook dispatcher, when it INHERITS that env, exits before governance handling.
Describe 'reviewer spawn suppresses the reviewer host''s own Specrew hooks (empty-exit0 root cause)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        # REUSE the SAME governed dispatcher fixture the integration suite uses (no second substitute fixture).
        . (Join-Path $script:RepoRoot 'tests/integration/refocus-dispatcher-fixture.ps1')
    }

    It '1. the reviewer launch path passes SPECREW_REFOCUS_DISABLE=1 to the spawned reviewer child process' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('hooksup-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        try {
            # A stand-in "reviewer host" that just prints the SPECREW_REFOCUS_DISABLE it inherited, then exits.
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{
                    file             = (Get-Process -Id $PID).Path
                    pre_args         = @('-NoProfile', '-NonInteractive', '-Command', '[Console]::Out.Write("RD=[" + $env:SPECREW_REFOCUS_DISABLE + "]")')
                    prompt_via_stdin = $true   # avoid appending the prompt as a positional arg to the -Command script
                }
            }
            $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $wt -Prompt 'ignored-by-the-stub' -HostName 'stub' -TimeoutSeconds 30
            [int]$r.exit_code | Should -Be 0
            [string]$r.stdout | Should -Match 'RD=\[1\]' -Because 'the reviewer child MUST inherit the kill switch so its own Specrew hooks no-op'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It '2. the hook dispatcher, when it INHERITS SPECREW_REFOCUS_DISABLE, exits 0 with the decision-only no-op BEFORE any governance handling' {
        $dispatcher = Join-Path $script:RepoRoot 'scripts/internal/specrew-hook-dispatcher.ps1'
        Test-Path -LiteralPath $dispatcher -PathType Leaf | Should -Be $true
        # The exact codex Stop binding shape (decision-only Stop, decision-block).
        $binding = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"DecisionOnlyEvents":["Stop"],"StopBlockShape":"decision-block"}'))
        $prev = $env:SPECREW_REFOCUS_DISABLE
        try {
            $env:SPECREW_REFOCUS_DISABLE = '1'   # inherited by the child dispatcher process below
            $out = & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File $dispatcher -Event Stop -HostKind codex -HostBinding $binding 2>$null
            $exit = $LASTEXITCODE
            $exit | Should -Be 0 -Because 'a refocus/hook failure may never block a session (fail-open); the kill switch exits 0'
            ([string]($out -join '')).Trim() | Should -Be '{}' -Because 'with the kill switch inherited, the ONLY output is the decision-only no-op - governance never runs (no co-review, no block)'
        }
        finally {
            if ($null -eq $prev) { Remove-Item Env:\SPECREW_REFOCUS_DISABLE -ErrorAction SilentlyContinue } else { $env:SPECREW_REFOCUS_DISABLE = $prev }
        }
    }

    It '2b. CONTROL: the kill-switch path emits the no-op ONLY for a decision-only event - proving test 2''s {} is the decision-only no-op, not a universal exit-0 output' {
        # This control stays INSIDE the kill-switch branch (SPECREW_REFOCUS_DISABLE set) on purpose: it must
        # never enter governance/provider dispatch (slow + needs a governed project). It varies only the
        # binding. With the SAME kill switch but an event that is NOT decision-only, the early no-op writer
        # emits NOTHING - so test 2's '{}' is specifically the decision-only (Stop) no-op, not a bare exit-0
        # artifact every kill-switched call produces. If this ever also printed '{}', test 2 would no longer
        # prove the decision-only shape and both would need revisiting.
        $dispatcher = Join-Path $script:RepoRoot 'scripts/internal/specrew-hook-dispatcher.ps1'
        # Binding whose DecisionOnlyEvents does NOT include the event we pass (Stop): non-decision-only path.
        $binding = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"DecisionOnlyEvents":["SessionStart"]}'))
        $prev = $env:SPECREW_REFOCUS_DISABLE
        try {
            $env:SPECREW_REFOCUS_DISABLE = '1'
            $out = & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File $dispatcher -Event Stop -HostKind codex -HostBinding $binding 2>$null
            $LASTEXITCODE | Should -Be 0 -Because 'the kill switch always exits 0'
            ([string]($out -join '')).Trim() | Should -Be '' -Because 'Stop is not in this binding''s DecisionOnlyEvents, so the early no-op writer emits nothing - the {} in test 2 is the decision-only no-op'
        }
        finally {
            if ($null -eq $prev) { Remove-Item Env:\SPECREW_REFOCUS_DISABLE -ErrorAction SilentlyContinue } else { $env:SPECREW_REFOCUS_DISABLE = $prev }
        }
    }

    # PAIRED CONTRACT via the REAL dispatcher in the SHARED governed fixture (codex finding f1
    # verification-environment-contamination, maintainer-required real-dispatcher proof 2026-07-12). Under
    # SPECREW_REFOCUS_DISABLE=1: (A) the reviewer host's OWN hook inherits suppression and the governed dispatcher
    # emits NO refocus marker; (B) a verification child launched through the engine's OWN bounded-verification
    # helper has the var REMOVED, reaches the REAL dispatcher in the SAME governed fixture, and governance PRODUCES
    # the positive '[specrew-refocus] trigger=b1' marker. This is the ONLY supported governance-sensitive path;
    # arbitrary reviewer-spawned children still inherit suppression by design (reviewer-spawn-contract.md).
    It '3. governed-fixture PAIR: the reviewer host''s own hook inherits suppression (no marker), while a bounded-verification child clears it, reaches the REAL dispatcher, and produces the refocus marker' {
        $fxRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('bvgov-' + [guid]::NewGuid().ToString('N'))
        $fx = New-RefocusDispatcherFixture -ProjectRoot (Join-Path $fxRoot 'project') -RepoRoot $script:RepoRoot
        $pwshPath = (Get-Process -Id $PID).Path
        $prev = $env:SPECREW_REFOCUS_DISABLE
        try {
            $env:SPECREW_REFOCUS_DISABLE = '1'   # a reviewer session: the reviewer process carries this, inherited by children

            # (A) DIRECT reviewer-hook invocation - this IS the reviewer host firing its own hook; it INHERITS the
            #     suppression. SessionStart/compact in the governed fixture would normally emit the refocus marker;
            #     the kill switch silences it before any parsing.
            $psi = [System.Diagnostics.ProcessStartInfo]::new($pwshPath)
            foreach ($a in @('-NoProfile', '-NonInteractive', '-File', $fx.dispatcher, '-Event', 'SessionStart', '-HostKind', 'codex', '-HostBinding', $fx.host_binding, '-EventJson', $fx.event_compact)) { [void]$psi.ArgumentList.Add($a) }
            $psi.WorkingDirectory = $fx.project_root; $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
            # inherit the test env (SPECREW_REFOCUS_DISABLE=1); do NOT remove it - this is the reviewer host's OWN hook
            $pDirect = [System.Diagnostics.Process]::Start($psi)
            $directOut = $pDirect.StandardOutput.ReadToEnd(); $null = $pDirect.StandardError.ReadToEnd(); $pDirect.WaitForExit()
            $pDirect.ExitCode | Should -Be 0 -Because 'the kill switch fails open (a hook failure never blocks the session)'
            [string]$directOut | Should -Not -Match $fx.marker_regex -Because 'the reviewer host''s OWN hook inherits SPECREW_REFOCUS_DISABLE=1 and is SUPPRESSED - the governed dispatcher emits NO refocus marker'

            # (B) THROUGH the bounded-verification helper - it removes SPECREW_REFOCUS_DISABLE from the child, which
            #     then launches the REAL dispatcher in the SAME governed fixture and REACHES governance, so the
            #     refocus marker IS produced. Asserts child env state, exit code, and marker PRESENCE.
            $cmd = @"
`$rd = `$env:SPECREW_REFOCUS_DISABLE
`$out = & '$pwshPath' -NoProfile -NonInteractive -File '$($fx.dispatcher)' -Event SessionStart -HostKind codex -HostBinding '$($fx.host_binding)' -EventJson '$($fx.event_compact)'
[Console]::Out.Write('CHILD_RD=[' + `$rd + '] EXIT=[' + `$LASTEXITCODE + '] MARK ' + (`$out -join ' '))
"@
            $rec = Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $fx.project_root -DeclaredCommands @($cmd) -TimeoutSeconds 60
            $bOut = [string]$rec[0].output
            $bOut | Should -Match 'CHILD_RD=\[\]' -Because 'the bounded helper REMOVED SPECREW_REFOCUS_DISABLE from the verification child (child environment state)'
            $bOut | Should -Match 'EXIT=\[0\]' -Because 'the real governed dispatcher exits 0'
            $bOut | Should -Match $fx.marker_regex -Because 'the bounded-verification child cleared the suppression, reached the REAL governed dispatcher, and governance PRODUCED the refocus marker (no false-green)'
        }
        finally {
            if ($null -eq $prev) { Remove-Item Env:\SPECREW_REFOCUS_DISABLE -ErrorAction SilentlyContinue } else { $env:SPECREW_REFOCUS_DISABLE = $prev }
            Remove-Item -LiteralPath $fxRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
