$ErrorActionPreference = 'Stop'

# FR-008 (203 W1) / SC-002 — reviewer worktree containment (F-198 iteration 003, T013):
# the stripped reviewer worktree MUST materialize OUTSIDE the origin root so no upward
# directory/git walk from inside the confined worktree can resolve the real project. Paired:
# the default (temp) path materializes outside origin; an EphemeralRoot inside origin is REFUSED.
Describe 'reviewer worktree containment (FR-008 / SC-002)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        # _load.ps1 brings the shared leaf modules (Invoke-ContinuousCoReviewGit etc.); the
        # orchestrator dot-sources worktree-reviewer.ps1 which DEFINES New-ContinuousCoReviewStrippedWorktree.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')

        function script:New-OriginRepo {
            $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-origin-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'origin content' -Encoding UTF8 -NoNewline
            & git -C $repo -c user.name='ccr' -c user.email='ccr@test.local' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='ccr' -c user.email='ccr@test.local' commit -q -m 'seed' 2>&1 | Out-Null
            return $repo
        }
    }

    It 'materializes OUTSIDE the origin root and no upward git-walk resolves origin' {
        $origin = script:New-OriginRepo
        try {
            $wt = New-ContinuousCoReviewStrippedWorktree -RepoRoot $origin -BaselineRef 'HEAD'
            $wt.worktree_path | Should -Not -BeNullOrEmpty
            $originFull = [System.IO.Path]::GetFullPath($origin).TrimEnd([char]'\', [char]'/')
            $wtFull = [System.IO.Path]::GetFullPath($wt.worktree_path).TrimEnd([char]'\', [char]'/')
            $wtFull.StartsWith($originFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) |
                Should -Be $false -Because 'the confined worktree must live outside origin'
            # Upward git-walk from inside the worktree must NOT resolve the origin repo.
            $top = (& git -C $wt.worktree_path rev-parse --show-toplevel 2>$null)
            if ($top) {
                ([System.IO.Path]::GetFullPath($top.Trim()).TrimEnd([char]'\', [char]'/')) |
                    Should -Not -Be $originFull -Because 'no upward walk may resolve origin'
            }
            Remove-Item -LiteralPath $wt.worktree_path -Recurse -Force -ErrorAction SilentlyContinue
        }
        finally { Remove-Item -LiteralPath $origin -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'REFUSES to materialize inside the origin root (containment guard, paired abuse)' {
        $origin = script:New-OriginRepo
        try {
            $inside = Join-Path $origin 'nested-eph'
            { New-ContinuousCoReviewStrippedWorktree -RepoRoot $origin -BaselineRef 'HEAD' -EphemeralRoot $inside } |
                Should -Throw -ExpectedMessage '*containment*'
        }
        finally { Remove-Item -LiteralPath $origin -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'REFUSES an EphemeralRoot that IS the origin root itself' {
        $origin = script:New-OriginRepo
        try {
            { New-ContinuousCoReviewStrippedWorktree -RepoRoot $origin -BaselineRef 'HEAD' -EphemeralRoot $origin } |
                Should -Throw -ExpectedMessage '*containment*'
        }
        finally { Remove-Item -LiteralPath $origin -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'REFUSES an EphemeralRoot JUNCTION whose target is inside origin (symlink/junction escape, finding 3b5ae645)' {
        if (-not $IsWindows) { Set-ItResult -Skipped -Because 'directory-junction creation is Windows-specific'; return }
        $origin = script:New-OriginRepo
        $link = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-jn-' + [guid]::NewGuid().ToString('N'))
        try {
            $insideTarget = Join-Path $origin 'nested-target'
            New-Item -ItemType Directory -Path $insideTarget -Force | Out-Null
            # The link path is LEXICALLY outside origin, but its TARGET is inside origin - the lexical-only
            # check passed it, then materialization would physically create the worktree under origin.
            New-Item -ItemType Junction -Path $link -Target $insideTarget | Out-Null
            { New-ContinuousCoReviewStrippedWorktree -RepoRoot $origin -BaselineRef 'HEAD' -EphemeralRoot $link } |
                Should -Throw -ExpectedMessage '*containment*'
        }
        finally {
            if (Test-Path -LiteralPath $link) { try { [System.IO.Directory]::Delete($link) } catch { $null = $_ } }   # remove the junction, not its target contents
            Remove-Item -LiteralPath $origin -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'shared physical-path canonicalizer (Get-ContinuousCoReviewPhysicalPath) - the ONE primitive for T013 + strict design-context (co-review 44760c20)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    }

    It 'follows an INTERMEDIATE directory junction to its real target (physical path leaves the lexical base)' {
        if (-not $IsWindows) { Set-ItResult -Skipped -Because 'directory-junction creation is Windows-specific'; return }
        $base = Join-Path ([System.IO.Path]::GetTempPath()) ('pp-base-' + [guid]::NewGuid().ToString('N'))
        $outside = Join-Path ([System.IO.Path]::GetTempPath()) ('pp-out-' + [guid]::NewGuid().ToString('N'))
        $link = Join-Path $base 'link'
        try {
            New-Item -ItemType Directory -Path $base -Force | Out-Null
            New-Item -ItemType Directory -Path $outside -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $outside 'f.txt') -Value 'x' -Encoding UTF8
            New-Item -ItemType Junction -Path $link -Target $outside | Out-Null
            $real = Get-ContinuousCoReviewPhysicalPath -Path (Join-Path $link 'f.txt')
            $baseReal = Get-ContinuousCoReviewPhysicalPath -Path $base
            $outsideReal = Get-ContinuousCoReviewPhysicalPath -Path $outside
            $real | Should -Be (Join-Path $outsideReal 'f.txt') -Because 'the intermediate junction is followed to the real physical target, not the lexical alias'
            $real.StartsWith($baseReal + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) | Should -Be $false -Because 'the resolved physical path is NOT under the lexical base'
        }
        finally {
            if (Test-Path -LiteralPath $link) { try { [System.IO.Directory]::Delete($link) } catch { $null = $_ } }
            Remove-Item -LiteralPath $base, $outside -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'an IN-scope junction to a target UNDER the root stays under the root (documented policy: in-scope links pass)' {
        if (-not $IsWindows) { Set-ItResult -Skipped -Because 'directory-junction creation is Windows-specific'; return }
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ('pp-root-' + [guid]::NewGuid().ToString('N'))
        $link = Join-Path $root 'link'
        try {
            New-Item -ItemType Directory -Path (Join-Path $root 'real') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'real/f.txt') -Value 'x' -Encoding UTF8
            New-Item -ItemType Junction -Path $link -Target (Join-Path $root 'real') | Out-Null
            $real = Get-ContinuousCoReviewPhysicalPath -Path (Join-Path $link 'f.txt')
            $rootReal = Get-ContinuousCoReviewPhysicalPath -Path $root
            $real.StartsWith($rootReal + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) | Should -Be $true -Because 'a link whose physical target is under the root stays under the root - allowed'
        }
        finally {
            if (Test-Path -LiteralPath $link) { try { [System.IO.Directory]::Delete($link) } catch { $null = $_ } }
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'resolves a plain (link-free) existing path to its normalized physical path' {
        $d = Join-Path ([System.IO.Path]::GetTempPath()) ('pp-plain-' + [guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $d 'f.txt') -Value 'x' -Encoding UTF8
            (Get-ContinuousCoReviewPhysicalPath -Path (Join-Path $d 'f.txt')) | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $d 'f.txt')).TrimEnd([char]'\', [char]'/'))
        }
        finally { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'Test-...PathUnderRoot uses PLATFORM-APPROPRIATE case sensitivity: exact-case child is under root; a case-distinct SIBLING is NOT under root on POSIX (co-review 40365de9)' {
        $parent = Join-Path ([System.IO.Path]::GetTempPath()) ('csp-' + [guid]::NewGuid().ToString('N'))
        try {
            $root = Join-Path $parent 'Repo'
            New-Item -ItemType Directory -Path (Join-Path $root 'Sub') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'Sub/f.txt') -Value 'x' -Encoding UTF8
            (Test-ContinuousCoReviewPathUnderRoot -Path (Join-Path $root 'Sub/f.txt') -Root $root) | Should -Be $true -Because 'an exact-case descendant is under root on every platform'
            $siblingLower = Join-Path $parent 'repo'   # case-distinct sibling of 'Repo'
            New-Item -ItemType Directory -Path $siblingLower -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $siblingLower 'f.txt') -Value 'x' -Encoding UTF8
            $underRoot = Test-ContinuousCoReviewPathUnderRoot -Path (Join-Path $siblingLower 'f.txt') -Root $root
            if ($IsWindows) { $underRoot | Should -Be $true -Because 'NTFS is case-insensitive: parent/repo and parent/Repo are the SAME dir' }
            else { $underRoot | Should -Be $false -Because 'POSIX is case-sensitive: parent/repo is a DIFFERENT dir from parent/Repo, not under it' }
        }
        finally { Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# FR-011 / SC-003 (T016) — the containment-violation DETECTOR: MONITORED confinement (not OS-enforced). The
# reviewer tree must stay under the disposable worktree; observed ORIGIN access is a LOUD, ORIGIN-SIDE
# `containment-violated` record carrying ONLY bounded/redacted path/process metadata (never the raw command
# line/prompt/env/creds), and the detector NEVER kills the reviewer mid-flight (paired legit/abuse + false-kill
# guard, NFR-007).
Describe 'T016 containment-violation detector (FR-011 / SC-003)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/agent-tasks/process-tree.ps1')   # so Get-SpecrewProcessTreeDescendants is mockable

        $script:Origin = Join-Path ([System.IO.Path]::GetTempPath()) ('t16-origin-' + [guid]::NewGuid().ToString('N'))
        $script:Worktree = Join-Path ([System.IO.Path]::GetTempPath()) ('t16-wt-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:Origin -Force | Out-Null
        New-Item -ItemType Directory -Path $script:Worktree -Force | Out-Null
        $script:OriginSecret = Join-Path $script:Origin 'secret.md'; Set-Content -LiteralPath $script:OriginSecret -Value 'origin' -NoNewline
        $script:OriginOther = Join-Path $script:Origin 'realtarget.md'; Set-Content -LiteralPath $script:OriginOther -Value 'origin2' -NoNewline
        $script:WtSource = Join-Path $script:Worktree 'src.ps1'; Set-Content -LiteralPath $script:WtSource -Value 'wt' -NoNewline
    }
    AfterAll {
        Remove-Item -LiteralPath $script:Origin, $script:Worktree -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'ABUSE (SC-003): a sampled path under origin becomes a containment-violated record with bounded/redacted metadata (no raw command line, prompt, env, or creds)' {
        $samples = @(
            @{ pid = 201; image = 'C:\Program Files\codex\codex.exe'; source = 'arg'; path = $script:OriginSecret }  # VIOLATION
            @{ pid = 201; image = 'codex.exe'; source = 'exe'; path = $script:WtSource }                              # legit (under worktree)
        )
        $v = Test-ContinuousCoReviewContainmentViolations -Samples $samples -OriginRoots @($script:Origin) -RunId 'RUN-A'
        @($v).Count | Should -Be 1 -Because 'exactly the origin-resolving sample is a violation; the in-worktree one is not'
        $rec = $v[0]
        $rec.run_id | Should -Be 'RUN-A'
        $rec.source | Should -Be 'arg'
        [string]$rec.path | Should -Match 'secret\.md' -Because 'the origin-access evidence path is recorded (origin-side record only)'
        [string]$rec.process | Should -Match 'pid=201'
        [string]$rec.process | Should -Match 'image=codex\.exe' -Because 'the process metadata is the image BASENAME, bounded'
        [string]$rec.process | Should -Not -Match '\\' -Because 'no full executable path in the record (bounded process metadata)'
        [string]$rec.command_line | Should -Match 'redacted' -Because 'command_line is a REDACTED marker, never the raw command line'
        [string]$rec.observed_at | Should -Not -BeNullOrEmpty
        # REDACTION: no record field may carry the raw command line / prompt / env / credential content
        ($rec | ConvertTo-Json -Depth 5) | Should -Not -Match 'dangerously|--allow|Program Files|SECRET_TOKEN'
    }

    It 'LEGIT (SC-003): a full in-worktree sample set produces ZERO violations (no false-positive)' {
        $samples = @(
            @{ pid = 301; image = 'pwsh'; source = 'cwd'; path = $script:Worktree }
            @{ pid = 301; image = 'pwsh'; source = 'arg'; path = $script:WtSource }
            @{ pid = 302; image = 'codex'; source = 'exe'; path = (Join-Path $script:Worktree 'bin/tool') }
        )
        $v = Test-ContinuousCoReviewContainmentViolations -Samples $samples -OriginRoots @($script:Origin) -RunId 'RUN-L'
        @($v).Count | Should -Be 0
    }

    It 'REDACTION at source: only ABSOLUTE path tokens are extracted from a command line - flags and the prompt text are NOT treated as paths' {
        $cmd = ('codex exec --dangerously-bypass-approvals-and-sandbox -p "review this SECRET_TOKEN prompt then do X" {0}' -f $script:OriginSecret)
        # NB: the helper returns a `, (...)`-preserved array; assign directly (no @()) so a single token is not double-wrapped.
        $tokens = Get-ContinuousCoReviewPathLikeTokens -CommandLine $cmd
        $tokens | Should -Contain $script:OriginSecret -Because 'the absolute origin path IS a candidate path token'
        (($tokens -join '|')) | Should -Not -Match 'dangerously|SECRET_TOKEN|prompt|exec' -Because 'flags and prompt words are NOT path-like and are never extracted (so they can never reach a record)'
    }

    It 'FALSE-KILL GUARD (never mid-flight kill): detecting a violation RECORDS it but does NOT terminate the process' {
        $child = Start-Process pwsh -ArgumentList '-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 30' -PassThru -WindowStyle Hidden
        try {
            $samples = @(@{ pid = $child.Id; image = 'pwsh'; source = 'arg'; path = $script:OriginSecret })
            $v = Test-ContinuousCoReviewContainmentViolations -Samples $samples -OriginRoots @($script:Origin) -RunId 'RUN-K'
            @($v).Count | Should -Be 1
            (Get-Process -Id $child.Id -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty -Because 'the detector records the violation but NEVER kills the reviewer mid-flight (monitored confinement, not enforcement)'
        }
        finally { try { $child.Kill($true) } catch { $null = $_ } }
    }

    It 'SAMPLER is read-only: it rides the process tree and returns path samples for a live child without terminating it' {
        $child = Start-Process pwsh -ArgumentList '-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 30' -PassThru -WindowStyle Hidden
        try {
            $samples = Get-ContinuousCoReviewContainmentSamples -RootPid $child.Id
            @($samples).Count | Should -BeGreaterThan 0 -Because 'a live child has at least an executable path / command line to sample'
            (Get-Process -Id $child.Id -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty -Because 'sampling is strictly read-only - it never terminates the sampled process'
        }
        finally { try { $child.Kill($true) } catch { $null = $_ } }
    }

    It 'PROMPT-MENTION SUBTRACTION (pure helper): host prompt mentions subtract, real operation targets survive (count-based, superset-gated)' {
        $A = $script:OriginSecret; $B = $script:OriginOther; $C = $script:WtSource
        # prompt-only host -> nothing survives (the classic false positive is gone)
        @(Get-ContinuousCoReviewOperationTargetTokens -ArgTokens @($A) -PromptTokens @($A)).Count | Should -Be 0
        # a REAL extra origin target beyond the prompt SURVIVES (host access stays observable)
        $r1 = @(Get-ContinuousCoReviewOperationTargetTokens -ArgTokens @($A, $B) -PromptTokens @($A))
        $r1 | Should -Contain $B
        $r1 | Should -Not -Contain $A
        # a real access to a path the prompt ALSO names survives - its COUNT exceeds the prompt's
        $r2 = @(Get-ContinuousCoReviewOperationTargetTokens -ArgTokens @($A, $A) -PromptTokens @($A))
        $r2.Count | Should -Be 1; $r2 | Should -Contain $A
        # NON-superset (a worker carrying only a real arg, not the whole prompt) is left UNCHANGED - its arg is kept
        $r3 = @(Get-ContinuousCoReviewOperationTargetTokens -ArgTokens @($A) -PromptTokens @($A, $C))
        $r3.Count | Should -Be 1; $r3 | Should -Contain $A
        # no prompt tokens -> unchanged
        @(Get-ContinuousCoReviewOperationTargetTokens -ArgTokens @($A, $B) -PromptTokens @()).Count | Should -Be 2
    }

    It 'HOST PROMPT-ARG DISAMBIGUATION (DRIFT-198-I003-004): a host prompt MENTION of origin is subtracted (no false positive), but a REAL origin operation target in the host argv AND a non-host descendant''s origin arg BOTH stay observable (FR-011)' -Skip:(-not $IsWindows) {
        # The HOST (codex.exe = RootPid) is launched as `codex exec "<prompt>"`; the prompt legitimately NAMES an
        # origin path (OriginSecret). The launcher passes the prompt's path tokens so the sampler SUBTRACTS that
        # mention - but a REAL origin operation target the host argv ALSO carries (OriginOther, NOT in the prompt)
        # must SURVIVE, and a descendant git''s origin arg (OriginSecret) must be sampled in full (subtraction is
        # HOST-scoped). This is the codex-found gap: the earlier blanket exemption would have hidden OriginOther.
        Mock -CommandName Get-SpecrewProcessTreeDescendants -MockWith { @(777) }
        Mock -CommandName Get-CimInstance -MockWith {
            @(
                [pscustomobject]@{ ProcessId = 666; Name = 'codex.exe'; CommandLine = ('codex exec "review {0} then stop" --root {1}' -f $script:OriginSecret, $script:OriginOther); ExecutablePath = 'C:\Users\dev\.codex\bin\codex.exe' }
                [pscustomobject]@{ ProcessId = 777; Name = 'git.exe'; CommandLine = ('git --no-pager show {0}' -f $script:OriginSecret); ExecutablePath = 'C:\Program Files\Git\cmd\git.exe' }
            )
        }
        $samples = Get-ContinuousCoReviewContainmentSamples -RootPid 666 -PromptMentionTokens @($script:OriginSecret)
        $argHostTokens = @($samples | Where-Object { $_.source -eq 'arg' -and $_.image -eq 'codex.exe' } | ForEach-Object { $_.path })
        $argHostTokens | Should -Not -Contain $script:OriginSecret -Because 'the prompt MENTION is subtracted from the host argv (the false positive that failed a real codex review is gone)'
        $argHostTokens | Should -Contain $script:OriginOther -Because 'a REAL origin operation target beyond the prompt SURVIVES subtraction - host command-line access stays OBSERVABLE (FR-011, the codex-found gap)'
        @($samples | Where-Object { $_.source -eq 'exe' -and $_.image -eq 'codex.exe' }).Count | Should -BeGreaterThan 0 -Because 'exe-source is still sampled for the host'
        $argChildTokens = @($samples | Where-Object { $_.source -eq 'arg' -and $_.image -eq 'git.exe' } | ForEach-Object { $_.path })
        $argChildTokens | Should -Contain $script:OriginSecret -Because 'prompt subtraction is HOST-scoped; a NON-host descendant is sampled in full'
        # End-to-end through the pure checker: TWO violations (host real target + descendant), never the host prompt mention.
        $v = Test-ContinuousCoReviewContainmentViolations -Samples $samples -OriginRoots @($script:Origin) -RunId 'RUN-DISAMBIG'
        @($v).Count | Should -Be 2 -Because 'the host real-target (OriginOther) AND the descendant (OriginSecret) resolve to violations; the host PROMPT mention does not'
        (($v | ForEach-Object { [string]$_.process }) -join '|') | Should -Match 'codex\.exe'
        (($v | ForEach-Object { [string]$_.process }) -join '|') | Should -Match 'git\.exe'
    }
}
