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
        # An origin path with SPACES in the directory AND file names - the whitespace-split bypass (codex
        # 20260712T192442732) would fragment its quoted form; the structured-argv parser must keep it one token.
        $script:OriginSpacedDir = Join-Path $script:Origin 'a b'; New-Item -ItemType Directory -Path $script:OriginSpacedDir -Force | Out-Null
        $script:OriginSpaced = Join-Path $script:OriginSpacedDir 'secret file.md'; Set-Content -LiteralPath $script:OriginSpaced -Value 'spaced' -NoNewline
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

    It 'STRUCTURED ARGV: a QUOTED path with spaces stays ONE token (whitespace-split bypass fix), the single-arg prompt naming origin yields NO path token, and flags are not paths' {
        # A QUOTED absolute path with spaces must survive as ONE structured-argv token - the whitespace-split bypass
        # (codex run 20260712T192442732) fragmented "C:\Origin Project\x" into C:\Origin + Project\x, neither under origin.
        $spaced = 'C:\Origin Project\secret file.md'
        $cmd = ('git --no-pager show "{0}" --dangerously-ignored' -f $spaced)
        $tokens = @(Get-ContinuousCoReviewPathLikeTokens -CommandLine $cmd)
        $tokens | Should -Contain $spaced -Because 'a QUOTED absolute path with spaces is ONE structured-argv token, not two fragments'
        (($tokens -join '|')) | Should -Not -Match 'dangerously|show|git' -Because 'flags and the sub-command are NOT absolute paths and are never extracted'
        # The WHOLE prompt passed as a SINGLE positional arg is one non-path token, so a prompt that merely NAMES an
        # origin path yields NO path token (the DRIFT-198-I003-004 false positive is structurally impossible now).
        $promptTokens = @(Get-ContinuousCoReviewPathLikeTokens -CommandLine ('codex exec "review the changes under {0} carefully"' -f $script:OriginSecret))
        $promptTokens | Should -Not -Contain $script:OriginSecret -Because 'the prompt is ONE positional arg = one non-path token; naming origin in prose is not a path arg'
    }

    It 'FALSE-KILL GUARD (never mid-flight kill): detecting a violation RECORDS it but does NOT terminate the process' {
        $start = @{ FilePath = 'pwsh'; ArgumentList = @('-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 30'); PassThru = $true }
        if ($IsWindows) { $start.WindowStyle = 'Hidden' }
        $child = Start-Process @start
        try {
            $samples = @(@{ pid = $child.Id; image = 'pwsh'; source = 'arg'; path = $script:OriginSecret })
            $v = Test-ContinuousCoReviewContainmentViolations -Samples $samples -OriginRoots @($script:Origin) -RunId 'RUN-K'
            @($v).Count | Should -Be 1
            (Get-Process -Id $child.Id -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty -Because 'the detector records the violation but NEVER kills the reviewer mid-flight (monitored confinement, not enforcement)'
        }
        finally { try { $child.Kill($true) } catch { $null = $_ } }
    }

    It 'SAMPLER is read-only: it rides the process tree and returns path samples for a live child without terminating it' {
        $start = @{ FilePath = 'pwsh'; ArgumentList = @('-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 30'); PassThru = $true }
        if ($IsWindows) { $start.WindowStyle = 'Hidden' }
        $child = Start-Process @start
        try {
            $samples = Get-ContinuousCoReviewContainmentSamples -RootPid $child.Id
            @($samples).Count | Should -BeGreaterThan 0 -Because 'a live child has at least an executable path / command line to sample'
            (Get-Process -Id $child.Id -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty -Because 'sampling is strictly read-only - it never terminates the sampled process'
        }
        finally { try { $child.Kill($true) } catch { $null = $_ } }
    }

    It 'STRUCTURED-ARGV sampler (DRIFT-198-I003-004): a QUOTED origin path with spaces is DETECTED (not bypassed), the single-arg prompt naming origin is NOT flagged, and a same-image worker + descendant with real origin args stay observable' -Skip:(-not $IsWindows) {
        # The whole DRIFT-004 arc resolved to ONE root cause - the whitespace-split tokenizer. With structured-argv
        # parsing: (a) the ROOT host''s prompt (a SINGLE positional arg naming OriginSecret) is one non-path token, so
        # no false positive; (b) a QUOTED origin path with spaces (OriginSpaced) stays one token and is DETECTED,
        # closing the bypass (codex 20260712T192442732); (c) a same-image worker(888) and a descendant(777) with real
        # origin args are sampled in FULL, so they stay observable (no false negative). No prompt-token plumbing.
        Mock -CommandName Get-SpecrewProcessTreeDescendants -MockWith { @(777, 888) }
        Mock -CommandName Get-CimInstance -MockWith {
            @(
                [pscustomobject]@{ ProcessId = 666; Name = 'codex.exe'; CommandLine = ('codex exec --skip-git-repo-check "review the changes under {0} and do not touch origin"' -f $script:OriginSecret); ExecutablePath = 'C:\Users\dev\.codex\bin\codex.exe' }
                [pscustomobject]@{ ProcessId = 777; Name = 'git.exe'; CommandLine = ('git --no-pager show "{0}"' -f $script:OriginSpaced); ExecutablePath = 'C:\Program Files\Git\cmd\git.exe' }
                [pscustomobject]@{ ProcessId = 888; Name = 'codex.exe'; CommandLine = ('codex exec --add-dir {0}' -f $script:OriginOther); ExecutablePath = 'C:\Users\dev\.codex\bin\codex.exe' }
            )
        }
        $samples = Get-ContinuousCoReviewContainmentSamples -RootPid 666
        $argRoot = @($samples | Where-Object { $_.source -eq 'arg' -and $_.pid -eq 666 } | ForEach-Object { $_.path })
        $argRoot | Should -Not -Contain $script:OriginSecret -Because 'the prompt is ONE positional arg (a non-path token); naming origin in prose is not access - no false positive, no subtraction'
        $argChild = @($samples | Where-Object { $_.source -eq 'arg' -and $_.pid -eq 777 } | ForEach-Object { $_.path })
        $argChild | Should -Contain $script:OriginSpaced -Because 'a QUOTED origin path with spaces stays ONE structured-argv token and is DETECTED (containment-detection-bypass fix)'
        $argWorker = @($samples | Where-Object { $_.source -eq 'arg' -and $_.pid -eq 888 } | ForEach-Object { $_.path })
        $argWorker | Should -Contain $script:OriginOther -Because 'a same-image worker''s REAL origin arg is sampled in full and stays observable (no false negative)'
        $v = Test-ContinuousCoReviewContainmentViolations -Samples $samples -OriginRoots @($script:Origin) -RunId 'RUN-ARGV'
        @($v).Count | Should -Be 2 -Because 'the descendant''s quoted spaced path (OriginSpaced) + the worker''s real arg (OriginOther) are violations; the ROOT prompt mention (OriginSecret) is not'
        (($v | ForEach-Object { [string]$_.path }) -join '|') | Should -Match 'secret file\.md'
    }

    It 'RELATIVE-TRAVERSAL abuse (SC-003, DRIFT-198-I003-004): a descendant invoked with a RELATIVE `..` path escaping the worktree to an origin file is DETECTED (resolved against the reviewer cwd), not silently dropped' -Skip:(-not $IsWindows) {
        # codex run 20260712T195149281: an ABSOLUTE-only filter dropped a relative traversal (`git show ..\..\<origin>\x`),
        # so the run could complete without containment-violated. The sampler now resolves relative path-like args
        # against the reviewer cwd (here the worktree) and checks under-origin.
        $rel = [System.IO.Path]::GetRelativePath($script:Worktree, $script:OriginSecret)   # e.g. ..\t16-origin-xxx\secret.md
        $rel | Should -Match '\.\.' -Because 'the sibling origin file is reached from the worktree by a `..` traversal (test integrity)'
        Mock -CommandName Get-SpecrewProcessTreeDescendants -MockWith { @(777) }
        Mock -CommandName Get-CimInstance -MockWith {
            @(
                [pscustomobject]@{ ProcessId = 666; Name = 'codex.exe'; CommandLine = 'codex exec "review the changes"'; ExecutablePath = 'C:\Users\dev\.codex\bin\codex.exe' }
                [pscustomobject]@{ ProcessId = 777; Name = 'git.exe'; CommandLine = ('git --no-pager show "{0}"' -f $rel); ExecutablePath = 'C:\Program Files\Git\cmd\git.exe' }
            )
        }
        # WITHOUT a cwd the relative token cannot resolve (documented fail-closed); WITH the worktree cwd it MUST be caught.
        $noCwd = Get-ContinuousCoReviewContainmentSamples -RootPid 666
        $v0 = Test-ContinuousCoReviewContainmentViolations -Samples $noCwd -OriginRoots @($script:Origin) -RunId 'RUN-REL0'
        @($v0).Count | Should -Be 0 -Because 'a relative token has no meaning without a cwd (fail-closed, documented)'
        $samples = Get-ContinuousCoReviewContainmentSamples -RootPid 666 -WorktreeCwd $script:Worktree
        $v = Test-ContinuousCoReviewContainmentViolations -Samples $samples -OriginRoots @($script:Origin) -RunId 'RUN-REL'
        @($v).Count | Should -BeGreaterThan 0 -Because 'the relative `..` traversal to an origin file resolves against the reviewer cwd and is flagged (not dropped)'
        (($v | ForEach-Object { [string]$_.path }) -join '|') | Should -Match 'secret\.md'
    }

    It 'OPTION-ATTACHED path (--name=value) is expanded and DETECTED as a best-effort arg candidate (codex run 20260712T171701083): absolute AND relative option values' -Skip:(-not $IsWindows) {
        $relDir = [System.IO.Path]::GetRelativePath($script:Worktree, $script:OriginSpacedDir)   # ..\t16-origin-x\a b  (relative option value)
        Mock -CommandName Get-SpecrewProcessTreeDescendants -MockWith { @(777, 888) }
        Mock -CommandName Get-CimInstance -MockWith {
            @(
                [pscustomobject]@{ ProcessId = 666; Name = 'codex.exe'; CommandLine = 'codex exec "review"'; ExecutablePath = 'C:\Users\dev\.codex\bin\codex.exe' }
                [pscustomobject]@{ ProcessId = 777; Name = 'git.exe'; CommandLine = ('git --git-dir="{0}" status' -f $script:OriginSpacedDir); ExecutablePath = 'C:\Program Files\Git\cmd\git.exe' }   # ABSOLUTE option value
                [pscustomobject]@{ ProcessId = 888; Name = 'git.exe'; CommandLine = ('git --git-dir="{0}" log' -f $relDir); ExecutablePath = 'C:\Program Files\Git\cmd\git.exe' }   # RELATIVE option value
            )
        }
        $samples = Get-ContinuousCoReviewContainmentSamples -RootPid 666 -WorktreeCwd $script:Worktree
        $v = Test-ContinuousCoReviewContainmentViolations -Samples $samples -OriginRoots @($script:Origin) -RunId 'RUN-OPT'
        @($v).Count | Should -BeGreaterThan 0 -Because 'the option-attached origin path (absolute + relative) is expanded past the `=` and DETECTED (best-effort argv coverage)'
        (@($v | ForEach-Object { $_.source }) | Select-Object -Unique) | Should -Be 'arg' -Because 'an option-value match is an argv match -> a diagnostic WARNING (source=arg), never a hard fail'
    }

    It 'SAMPLER HEALTH: a sampling failure is RECORDED (degraded + reason), never silent inactivity (FR-011 amended)' -Skip:(-not $IsWindows) {
        Mock -CommandName Get-SpecrewProcessTreeDescendants -MockWith { @() }
        Mock -CommandName Get-CimInstance -MockWith { throw 'simulated CIM failure' }
        $h = $null
        $null = Get-ContinuousCoReviewContainmentSamples -RootPid 4242 -WorktreeCwd $script:Worktree -Health ([ref]$h)
        $h | Should -Not -BeNullOrEmpty -Because 'the monitor always reports its health'
        [bool]$h.degraded | Should -BeTrue -Because 'a CIM query failure is recorded as DEGRADED visibility, not silent'
        [string]$h.reason | Should -Be 'cim-query-failed'
    }

    It 'ALTERNATE CHILD CWD: relative-arg classification DEPENDS on the process cwd - the same relative token reaches origin from one cwd but not another' {
        $rel = [System.IO.Path]::GetRelativePath($script:Worktree, $script:OriginSecret)   # ..\t16-origin-x\secret.md
        $fromWorktree = @(Resolve-ContinuousCoReviewRelativeOriginTokens -Argv @($rel) -Cwd $script:Worktree)
        $fromWorktree | Should -Contain $script:OriginSecret -Because 'from the reviewer worktree cwd the `..` traversal reaches the origin file'
        $fromElsewhere = @(Resolve-ContinuousCoReviewRelativeOriginTokens -Argv @($rel) -Cwd ([System.IO.Path]::GetTempPath()))
        $fromElsewhere | Should -Not -Contain $script:OriginSecret -Because 'from a DIFFERENT cwd the SAME relative token resolves elsewhere - an alternate child cwd changes classification (POSIX uses the exact /proc/<pid>/cwd; Windows the assumed worktree, documented best-effort)'
    }
}
