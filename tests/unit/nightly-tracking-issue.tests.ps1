# Feature 206, T012 (FR-009; design condition 4): the Nightly Truth-Check notifies through one tracking issue.
#   - .github/scripts/nightly-tracking-issue.ps1 (workflow-only, never shipped in the module), with its `gh` calls injected and recorded here: the first red
#     opens the issue, the same failures stay quiet, changed failures comment, green closes.
#   - The rendered title, body and comments carry iteration ids, rule names, severities, the run id and the
#     commit only: no path, no user or machine name.
#   - validate-governance.ps1 -FindingsJsonPath writes the findings file the notifier reads.
#   - The workflow's default permission stays `contents: read`; the notifier job alone holds `issues: write`.
#
# No real `gh` call is made: every call goes to a recorder. The validator runs on temp-folder projects.
# No specrew start, update or init; no hooks; nothing written to the home folder.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Notifier = Join-Path $script:RepoRoot '.github\scripts\nightly-tracking-issue.ps1'
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
    $script:Workflow = Join-Path $script:RepoRoot '.github\workflows\specrew-nightly-truth-check.yml'
    $script:Work = Join-Path ([System.IO.Path]::GetTempPath()) ('nightly-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $script:Work -Force

    function New-FindingsFile {
        param([string]$Name, [object[]]$Findings)
        $path = Join-Path $script:Work $Name
        ([ordered]@{ schema = 'v1'; findings = @($Findings) } | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $path -Encoding UTF8
        return $path
    }

    # A recorder standing in for `gh`. $OpenIssues is what `gh issue list` returns.
    function New-GhRecorder {
        param([object[]]$OpenIssues = @())
        $state = [pscustomobject]@{ Calls = New-Object System.Collections.Generic.List[object]; OpenIssues = @($OpenIssues) }
        $gh = {
            param([string[]]$GhArgs)
            $state.Calls.Add(@($GhArgs)) | Out-Null
            if ($GhArgs[0] -eq 'issue' -and $GhArgs[1] -eq 'list') {
                return (ConvertTo-Json -InputObject @($state.OpenIssues) -Depth 5 -Compress)
            }
            return ''
        }.GetNewClosure()
        return [pscustomobject]@{ State = $state; Gh = $gh }
    }

    function Get-WriteCalls {
        param($Recorder)
        return @($Recorder.State.Calls | Where-Object { -not ($_[0] -eq 'issue' -and $_[1] -eq 'list') })
    }

    function Get-ArgValue {
        param([string[]]$CallArgs, [string]$Name)
        $i = [array]::IndexOf($CallArgs, $Name)
        if ($i -ge 0 -and $i + 1 -lt $CallArgs.Count) { return $CallArgs[$i + 1] }
        return $null
    }

    $script:RedFindings = @(
        @{ iteration = '198-beta2-hardening/011'; rule = 'review-verdict-accepted'; severity = 'error' },
        @{ iteration = '206-bug-bash/001'; rule = 'uncategorized'; severity = 'error'; message_hash = 'a1b2c3d4e5f60718' }
    )
    $script:RedFile = New-FindingsFile -Name 'red.json' -Findings $script:RedFindings
    $script:ChangedFile = New-FindingsFile -Name 'changed.json' -Findings @(
        @{ iteration = '198-beta2-hardening/011'; rule = 'review-verdict-accepted'; severity = 'error' }
    )
    $script:GreenFile = New-FindingsFile -Name 'green.json' -Findings @()
    $script:LeakyFile = New-FindingsFile -Name 'leaky.json' -Findings @(
        @{ iteration = 'C:\Users\someone\repo\specs\x\iterations\001'; rule = 'review-verdict-accepted'; severity = 'error' },
        @{ iteration = '/home/runner/work/specrew/specs/x/iterations/002'; rule = 'stale/../status'; severity = 'error' }
    )

    function Invoke-Notifier {
        param($Recorder, [string]$Outcome, [string]$FindingsPath, [string]$RunId = '4242', [string]$Commit = '0123456789abcdef0123456789abcdef01234567')
        return (& $script:Notifier -ValidatorOutcome $Outcome -FindingsJsonPath $FindingsPath -RunId $RunId -Commit $Commit -Gh $Recorder.Gh)
    }
}

AfterAll {
    if ($script:Work -and (Test-Path -LiteralPath $script:Work)) {
        Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'T012: the tracking issue follows the nightly' {
    It 'the first red night opens one issue labelled nightly-truth-check, with the finding table and the fingerprint' {
        $rec = New-GhRecorder
        $action = Invoke-Notifier -Recorder $rec -Outcome 'failure' -FindingsPath $script:RedFile
        $action | Should -Be 'opened'
        $create = @(Get-WriteCalls $rec | Where-Object { $_[0] -eq 'issue' -and $_[1] -eq 'create' })
        $create.Count | Should -Be 1
        (Get-ArgValue $create[0] '--label') | Should -Be 'nightly-truth-check'
        $body = Get-ArgValue $create[0] '--body'
        $body | Should -Match '198-beta2-hardening/011'
        $body | Should -Match 'review-verdict-accepted'
        $body | Should -Match 'nightly-fingerprint: [0-9a-f]{64}'
        $body | Should -Match '4242'
    }

    It 'a red night with the same failures sends nothing' {
        $first = New-GhRecorder
        $null = Invoke-Notifier -Recorder $first -Outcome 'failure' -FindingsPath $script:RedFile
        $body = Get-ArgValue (@(Get-WriteCalls $first | Where-Object { $_[0] -eq 'issue' -and $_[1] -eq 'create' })[0]) '--body'
        $rec = New-GhRecorder -OpenIssues @(@{ number = 7; body = $body })
        $action = Invoke-Notifier -Recorder $rec -Outcome 'failure' -FindingsPath $script:RedFile -RunId '4243'
        $action | Should -Be 'none'
        @(Get-WriteCalls $rec).Count | Should -Be 0
    }

    It 'a red night with a different failure set comments with the new table and stores the new fingerprint' {
        $first = New-GhRecorder
        $null = Invoke-Notifier -Recorder $first -Outcome 'failure' -FindingsPath $script:RedFile
        $body = Get-ArgValue (@(Get-WriteCalls $first | Where-Object { $_[0] -eq 'issue' -and $_[1] -eq 'create' })[0]) '--body'
        $rec = New-GhRecorder -OpenIssues @(@{ number = 7; body = $body })
        $action = Invoke-Notifier -Recorder $rec -Outcome 'failure' -FindingsPath $script:ChangedFile -RunId '4244'
        $action | Should -Be 'commented'
        $comment = @(Get-WriteCalls $rec | Where-Object { $_[1] -eq 'comment' })
        $comment.Count | Should -Be 1
        $comment[0][2] | Should -Be '7'
        (Get-ArgValue $comment[0] '--body') | Should -Match '4244'
        $edit = @(Get-WriteCalls $rec | Where-Object { $_[1] -eq 'edit' })
        $edit.Count | Should -Be 1
        $newBody = Get-ArgValue $edit[0] '--body'
        $newBody | Should -Match 'nightly-fingerprint: [0-9a-f]{64}'
        ([regex]::Match($newBody, 'nightly-fingerprint: ([0-9a-f]{64})').Groups[1].Value) | Should -Not -Be ([regex]::Match($body, 'nightly-fingerprint: ([0-9a-f]{64})').Groups[1].Value)
    }

    It 'a green night closes the open issue with a comment naming the run' {
        $rec = New-GhRecorder -OpenIssues @(@{ number = 7; body = 'x <!-- nightly-fingerprint: 0000000000000000000000000000000000000000000000000000000000000000 -->' })
        $action = Invoke-Notifier -Recorder $rec -Outcome 'success' -FindingsPath $script:GreenFile -RunId '4245'
        $action | Should -Be 'closed'
        $close = @(Get-WriteCalls $rec | Where-Object { $_[1] -eq 'close' })
        $close.Count | Should -Be 1
        $close[0][2] | Should -Be '7'
        (Get-ArgValue $close[0] '--comment') | Should -Match '4245'
    }

    It 'a green night with no open issue sends nothing' {
        $rec = New-GhRecorder
        Invoke-Notifier -Recorder $rec -Outcome 'success' -FindingsPath $script:GreenFile | Should -Be 'none'
        @(Get-WriteCalls $rec).Count | Should -Be 0
    }

    It 'a red night with no findings file still opens the issue, naming that the file is missing' {
        $rec = New-GhRecorder
        Invoke-Notifier -Recorder $rec -Outcome 'failure' -FindingsPath (Join-Path $script:Work 'absent.json') | Should -Be 'opened'
        $body = Get-ArgValue (@(Get-WriteCalls $rec | Where-Object { $_[0] -eq 'issue' -and $_[1] -eq 'create' })[0]) '--body'
        $body | Should -Match 'findings-file-missing'
    }

    It 'a cancelled or skipped validator job sends nothing' {
        foreach ($outcome in 'cancelled', 'skipped') {
            $rec = New-GhRecorder -OpenIssues @(@{ number = 7; body = 'x' })
            Invoke-Notifier -Recorder $rec -Outcome $outcome -FindingsPath $script:RedFile | Should -Be 'none'
            @(Get-WriteCalls $rec).Count | Should -Be 0
        }
    }

    It 'the fingerprint does not depend on the order of the findings' {
        $reversed = New-FindingsFile -Name 'reversed.json' -Findings @($script:RedFindings[1], $script:RedFindings[0])
        $a = New-GhRecorder; $null = Invoke-Notifier -Recorder $a -Outcome 'failure' -FindingsPath $script:RedFile
        $b = New-GhRecorder; $null = Invoke-Notifier -Recorder $b -Outcome 'failure' -FindingsPath $reversed
        $fa = [regex]::Match((Get-ArgValue (@(Get-WriteCalls $a | Where-Object { $_[0] -eq 'issue' -and $_[1] -eq 'create' })[0]) '--body'), 'nightly-fingerprint: ([0-9a-f]{64})').Groups[1].Value
        $fb = [regex]::Match((Get-ArgValue (@(Get-WriteCalls $b | Where-Object { $_[0] -eq 'issue' -and $_[1] -eq 'create' })[0]) '--body'), 'nightly-fingerprint: ([0-9a-f]{64})').Groups[1].Value
        $fa | Should -Be $fb
    }
}

Describe 'T012 (condition 4): nothing private in the issue' {
    It 'title, body and comments carry no path, no user name and no machine name' {
        $texts = New-Object System.Collections.Generic.List[string]
        $open = New-GhRecorder
        $null = Invoke-Notifier -Recorder $open -Outcome 'failure' -FindingsPath $script:LeakyFile
        $body = $null
        foreach ($call in @(Get-WriteCalls $open)) {
            foreach ($name in '--title', '--body', '--comment') { $v = Get-ArgValue $call $name; if ($v) { $texts.Add($v) | Out-Null } }
            if ($call[1] -eq 'create') { $body = Get-ArgValue $call '--body' }
        }
        $changed = New-GhRecorder -OpenIssues @(@{ number = 7; body = $body })
        $null = Invoke-Notifier -Recorder $changed -Outcome 'failure' -FindingsPath $script:RedFile
        $close = New-GhRecorder -OpenIssues @(@{ number = 7; body = $body })
        $null = Invoke-Notifier -Recorder $close -Outcome 'success' -FindingsPath $script:GreenFile
        foreach ($rec in $changed, $close) {
            foreach ($call in @(Get-WriteCalls $rec)) {
                foreach ($name in '--title', '--body', '--comment') { $v = Get-ArgValue $call $name; if ($v) { $texts.Add($v) | Out-Null } }
            }
        }
        $texts.Count | Should -BeGreaterThan 3
        $names = @($env:USERNAME, $env:USER, $env:COMPUTERNAME, [System.Environment]::MachineName) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
        foreach ($text in $texts) {
            $text | Should -Not -Match '\\'
            $text | Should -Not -Match '(?i)[a-z]:/'
            $text | Should -Not -Match '(?i)/(home|users|runner|tmp|var|work)/'
            $text | Should -Not -Match '\.\./'
            $text | Should -Not -Match 'someone'
            foreach ($n in $names) { $text | Should -Not -Match ('(?i)\b' + [regex]::Escape($n) + '\b') }
        }
    }
}

Describe 'T012: the validator writes the findings file' {
    BeforeAll {
        function New-ValidatorFixture {
            param([string]$Name, [switch]$NoTeam, [switch]$Failing)
            $root = Join-Path $script:Work $Name
            $null = New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force
            $null = New-Item -ItemType Directory -Path (Join-Path $root 'scripts\internal') -Force
            $null = New-Item -ItemType Directory -Path (Join-Path $root 'extensions\specrew-speckit\scripts') -Force
            Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\dashboard-renderer.ps1') -Destination (Join-Path $root 'scripts\internal\dashboard-renderer.ps1')
            Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1') -Destination (Join-Path $root 'extensions\specrew-speckit\scripts\shared-governance.ps1')
            if (-not $NoTeam) {
                $null = New-Item -ItemType Directory -Path (Join-Path $root '.squad') -Force
                Copy-Item -LiteralPath (Join-Path $script:RepoRoot '.squad\team.md') -Destination (Join-Path $root '.squad\team.md')
            }
            $dir = Join-Path $root 'specs\905-findings\iterations\001'
            $null = New-Item -ItemType Directory -Path $dir -Force
            Set-Content -LiteralPath (Join-Path $root 'specs\905-findings\spec.md') -Value '# Feature Specification: 905-findings' -Encoding UTF8
            $status = if ($Failing) { 'retro' } else { 'planning' }
            Set-Content -LiteralPath (Join-Path $dir 'plan.md') -Value "# Plan`n`n**Status**: $status`n" -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $dir 'state.md') -Value "# Iteration State: 001`n`n**Schema**: v2`n**Iteration Status**: $status`n" -Encoding UTF8
            if ($Failing) {
                Set-Content -LiteralPath (Join-Path $dir 'drift-log.md') -Value "# Drift Log`n" -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $dir 'retro.md') -Value "# Retro`n" -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $dir 'review.md') -Value "# Review`n`n**Overall Verdict**: needs-rework`n" -Encoding UTF8
            }
            elseif (-not $NoTeam) {
                # Green: the iteration is frozen (T008), so the run judges nothing and exits 0.
                Set-Content -LiteralPath (Join-Path $root '.specrew\legacy-frozen.yml') -Encoding UTF8 -Value "schema: v1`nclosed_on: 2026-11-10`nentries:`n  - iteration: 905-findings/001`n    reason: fixture`n"
            }
            return [pscustomobject]@{ Root = $root; Iteration = $dir }
        }

        function Invoke-ValidatorWithFindings {
            param($Fixture, [string]$FindingsPath)
            $output = (@(& pwsh -NoProfile -File $script:Validator -ProjectPath $Fixture.Root -IterationPath $Fixture.Iteration -FindingsJsonPath $FindingsPath 2>&1 | ForEach-Object { [string]$_ }) -join "`n")
            return [pscustomobject]@{ Exit = $LASTEXITCODE; Output = $output }
        }
    }

    It 'a failing iteration is written as iteration id, rule and severity; an uncategorized message only as a hash' {
        $fixture = New-ValidatorFixture -Name 'v-fail' -Failing
        $path = Join-Path $script:Work 'v-fail.json'
        $run = Invoke-ValidatorWithFindings -Fixture $fixture -FindingsPath $path
        $run.Exit | Should -Be 1
        Test-Path -LiteralPath $path | Should -BeTrue
        $raw = Get-Content -LiteralPath $path -Raw
        $doc = $raw | ConvertFrom-Json
        $doc.schema | Should -Be 'v1'
        @($doc.findings).Count | Should -BeGreaterThan 0
        foreach ($f in @($doc.findings)) {
            $f.iteration | Should -Be '905-findings/001'
            $f.severity | Should -Be 'error'
            $f.rule | Should -Match '^[a-z0-9][a-z0-9-]*$'
            if ($f.rule -eq 'uncategorized') { $f.message_hash | Should -Match '^[0-9a-f]{16}$' }
        }
        $raw | Should -Not -Match 'Retro iterations require'
        $raw | Should -Not -Match ([regex]::Escape(($script:Work -replace '\\', '\\')))
        $raw | Should -Not -Match '\\\\'
    }

    It 'a green run writes an empty findings list' {
        $fixture = New-ValidatorFixture -Name 'v-green'
        $path = Join-Path $script:Work 'v-green.json'
        $run = Invoke-ValidatorWithFindings -Fixture $fixture -FindingsPath $path
        $run.Exit | Should -Be 0 -Because $run.Output
        $doc = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $doc.schema | Should -Be 'v1'
        @($doc.findings).Count | Should -Be 0
    }

    It 'a repository-level stop (the Squad team check) is written as a repository finding, never an empty red' {
        $fixture = New-ValidatorFixture -Name 'v-team' -NoTeam
        $path = Join-Path $script:Work 'v-team.json'
        $run = Invoke-ValidatorWithFindings -Fixture $fixture -FindingsPath $path
        $run.Exit | Should -Be 1
        $doc = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        @($doc.findings).Count | Should -BeGreaterThan 0
        @($doc.findings)[0].iteration | Should -Be '(repository)'
        @($doc.findings)[0].rule | Should -Be 'squad-team'
    }
}

Describe 'T012: workflow permissions' {
    BeforeAll {
        $script:WorkflowText = Get-Content -LiteralPath $script:Workflow -Raw
        # Top-level block: from "permissions:" at column 0 to the next column-0 key.
        $script:TopPermissions = [regex]::Match($script:WorkflowText, '(?m)^permissions:[ \t]*\r?\n((?:[ \t]+[^\r\n]*\r?\n)+)').Groups[1].Value
        $jobsText = $script:WorkflowText.Substring($script:WorkflowText.IndexOf("`njobs:"))
        $script:Jobs = @{}
        foreach ($m in [regex]::Matches($jobsText, '(?ms)^  ([A-Za-z0-9_-]+):\s*\r?\n(.*?)(?=^  [A-Za-z0-9_-]+:\s*\r?\n|\z)')) {
            $script:Jobs[$m.Groups[1].Value] = $m.Groups[2].Value
        }
    }

    It 'the workflow default stays contents: read' {
        $script:TopPermissions | Should -Match 'contents:\s*read'
        $script:TopPermissions | Should -Not -Match 'issues:'
    }

    It 'the notifier job alone holds issues: write, runs after the validator whatever its result, and passes the findings file' {
        $script:Jobs.ContainsKey('notify') | Should -BeTrue
        $script:Jobs['notify'] | Should -Match 'issues:\s*write'
        $script:Jobs['notify'] | Should -Match 'needs:\s*full-repo-validator'
        $script:Jobs['notify'] | Should -Match 'if:\s*always\(\)'
        $script:Jobs['notify'] | Should -Match '\./\.github/scripts/nightly-tracking-issue\.ps1'
        foreach ($name in @($script:Jobs.Keys | Where-Object { $_ -ne 'notify' })) {
            $script:Jobs[$name] | Should -Not -Match 'issues:\s*write' -Because "$name must not hold issues: write"
        }
        $script:Jobs['full-repo-validator'] | Should -Match '-FindingsJsonPath'
    }
}

Describe 'T012 (ruling 2026-11-12): the tracking issue belongs to the default branch' {
    BeforeAll {
        $text = Get-Content -LiteralPath $script:Workflow -Raw
        $jobsText = $text.Substring($text.IndexOf("`njobs:"))
        $script:BranchJobs = @{}
        foreach ($m in [regex]::Matches($jobsText, '(?ms)^  ([A-Za-z0-9_-]+):\s*\r?\n(.*?)(?=^  [A-Za-z0-9_-]+:\s*\r?\n|\z)')) {
            $script:BranchJobs[$m.Groups[1].Value] = $m.Groups[2].Value
        }

        # Evaluates a job's `if:` expression for one trigger. Only the tokens the condition needs are known;
        # any other token fails the test rather than being guessed at. Comparison is case-insensitive, as in
        # Actions. Parenthesize mixed && and ||: -and and -or share one precedence in PowerShell.
        function Test-JobCondition {
            param([string]$Expression, [hashtable]$Context)
            $e = $Expression.Trim()
            if ($e -match '^\$\{\{\s*(.*?)\s*\}\}$') { $e = $Matches[1] }
            $contextMap = @{
                'github.event_name' = 'event_name'
                'github.ref' = 'ref'
                'github.ref_name' = 'ref_name'
                'github.event.repository.default_branch' = 'default_branch'
            }
            $out = New-Object System.Text.StringBuilder
            $tokens = [regex]::Matches($e, "\s+|'(?:[^']|'')*'|\(|\)|,|==|!=|&&|\|\||!|[A-Za-z_][A-Za-z0-9_.\-]*|.")
            for ($i = 0; $i -lt $tokens.Count; $i++) {
                $t = $tokens[$i].Value
                if ($t -match '^\s+$') { [void]$out.Append(' '); continue }
                if ($t.StartsWith("'")) { [void]$out.Append($t); continue }
                switch -CaseSensitive ($t) {
                    '(' { [void]$out.Append('('); continue }
                    ')' { [void]$out.Append(')'); continue }
                    ',' { [void]$out.Append(','); continue }
                    '==' { [void]$out.Append(' -eq '); continue }
                    '!=' { [void]$out.Append(' -ne '); continue }
                    '&&' { [void]$out.Append(' -and '); continue }
                    '||' { [void]$out.Append(' -or '); continue }
                    '!' { [void]$out.Append(' -not '); continue }
                    'always' {
                        if ($i + 2 -lt $tokens.Count -and $tokens[$i + 1].Value -eq '(' -and $tokens[$i + 2].Value -eq ')') {
                            [void]$out.Append('$true'); $i += 2; continue
                        }
                        throw "always must be called as always()"
                    }
                    'format' { [void]$out.Append('[string]::Format'); continue }
                    default {
                        if ($contextMap.ContainsKey($t)) { [void]$out.Append(('([string]$Context[''{0}''])' -f $contextMap[$t])); continue }
                        throw "Unknown token in the job condition: '$t'"
                    }
                }
            }
            return [bool](& ([scriptblock]::Create("param(`$Context) $($out.ToString())")) $Context)
        }
    }

    It 'notifies for the scheduled run and a manual run on main, never for a manual run on another branch; the validator still runs anywhere' {
        $script:BranchJobs.ContainsKey('notify') | Should -BeTrue
        $ifMatch = [regex]::Match($script:BranchJobs['notify'], '(?m)^    if:[ \t]*(.+?)[ \t]*\r?$')
        $ifMatch.Success | Should -BeTrue -Because 'the notify job needs a job-level condition'
        $condition = $ifMatch.Groups[1].Value
        $condition | Should -Match '\balways\(\)' -Because 'a red validator night must still reach the notifier'

        $cases = @(
            # A scheduled run is always on the default branch; its event carries no repository object.
            @{ Name = 'schedule (no repository in the event)'; Expected = $true; Context = @{ event_name = 'schedule'; ref = 'refs/heads/main'; ref_name = 'main'; default_branch = '' } }
            @{ Name = 'schedule'; Expected = $true; Context = @{ event_name = 'schedule'; ref = 'refs/heads/main'; ref_name = 'main'; default_branch = 'main' } }
            @{ Name = 'manual run on main'; Expected = $true; Context = @{ event_name = 'workflow_dispatch'; ref = 'refs/heads/main'; ref_name = 'main'; default_branch = 'main' } }
            @{ Name = 'manual run on a feature branch'; Expected = $false; Context = @{ event_name = 'workflow_dispatch'; ref = 'refs/heads/206-bug-bash'; ref_name = '206-bug-bash'; default_branch = 'main' } }
            @{ Name = 'manual run on a branch named like main'; Expected = $false; Context = @{ event_name = 'workflow_dispatch'; ref = 'refs/heads/main-copy'; ref_name = 'main-copy'; default_branch = 'main' } }
            @{ Name = 'manual run on a tag named main'; Expected = $false; Context = @{ event_name = 'workflow_dispatch'; ref = 'refs/tags/main'; ref_name = 'main'; default_branch = 'main' } }
        )
        foreach ($case in $cases) {
            Test-JobCondition -Expression $condition -Context $case.Context | Should -Be $case.Expected -Because "notify on '$($case.Name)' (condition: $condition)"
        }

        $script:BranchJobs['full-repo-validator'] | Should -Not -Match '(?m)^    if:' -Because 'the validator job runs on any branch'
    }
}
