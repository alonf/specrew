#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# Feature 203 T015 (DRIFT-005, 206's DRIFT-206-I002-012): the Cross-Platform step "Run bounded deterministic review
# fault and conformance suites" ran its suites one after another in one pwsh with no per-suite limit; a Windows hang
# ran until the job's limit cancelled the whole job and the log was lost, so nothing named the suite. The runner
# below runs each suite in its own pwsh under a wall-clock limit, names a suite that exceeds it, stops its process
# tree, and fails. These cases drive the real runner script with small fixture suites.
Describe 'the bounded deterministic suite runner (T015)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:Runner = Join-Path $script:RepoRoot 'tools/ci/invoke-bounded-suites.ps1'
        $script:PwshPath = (Get-Process -Id $PID).Path
        $script:FixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('bounded-runner-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:FixtureRoot -Force | Out-Null

        function New-FixtureSuite {
            param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Body)
            $path = Join-Path $script:FixtureRoot $Name
            Set-Content -LiteralPath $path -Value ("Describe 'fixture' {{ It 'case' {{ {0} }} }}" -f $Body) -Encoding UTF8
            return $path
        }

        function Invoke-Runner {
            param([Parameter(Mandatory)][string[]]$Suite, [Parameter(Mandatory)][int]$SuiteTimeoutSeconds)
            $output = & $script:PwshPath -NoProfile -NonInteractive -File $script:Runner -Suite $Suite -SuiteTimeoutSeconds $SuiteTimeoutSeconds 2>&1
            return [pscustomobject]@{ exit_code = $LASTEXITCODE; text = (@($output) | ForEach-Object { [string]$_ }) -join "`n" }
        }
    }

    AfterAll { Remove-Item -LiteralPath $script:FixtureRoot -Recurse -Force -ErrorAction SilentlyContinue }

    It 'the runner script exists' {
        Test-Path -LiteralPath $script:Runner -PathType Leaf | Should -BeTrue
    }

    It 'passes when every suite passes' {
        $pass = New-FixtureSuite -Name 'pass.Tests.ps1' -Body '1 | Should -Be 1'
        $r = Invoke-Runner -Suite @($pass) -SuiteTimeoutSeconds 120
        $r.exit_code | Should -Be 0 -Because $r.text
        $r.text | Should -Match ([regex]::Escape('--- deterministic suite: ' + $pass))
    }

    It 'fails and names a suite whose result is not Passed' {
        $fail = New-FixtureSuite -Name 'fail.Tests.ps1' -Body '1 | Should -Be 2'
        $r = Invoke-Runner -Suite @($fail) -SuiteTimeoutSeconds 120
        $r.exit_code | Should -Not -Be 0
        $r.text | Should -Match ([regex]::Escape('review-fault-suite-failed:' + $fail))
    }

    It 'names a suite that exceeds its limit, stops its process tree, and fails' {
        $pidFile = Join-Path $script:FixtureRoot 'hang.pid'
        $hang = New-FixtureSuite -Name 'hang.Tests.ps1' -Body ("Set-Content -LiteralPath '{0}' -Value `$PID; Start-Sleep -Seconds 120" -f ($pidFile -replace "'", "''"))
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-Runner -Suite @($hang) -SuiteTimeoutSeconds 8
        $sw.Stop()
        $r.exit_code | Should -Not -Be 0
        $r.text | Should -Match ([regex]::Escape('deterministic-suite-timeout:' + $hang))
        $sw.Elapsed.TotalSeconds | Should -BeLessThan 60 -Because 'the limit, not the suite, decides when the step ends'
        $hangPid = [int](Get-Content -LiteralPath $pidFile -Raw).Trim()
        $alive = $null; try { $alive = Get-Process -Id $hangPid -ErrorAction Stop } catch { $alive = $null }
        if ($null -ne $alive) { try { Stop-Process -Id $hangPid -Force } catch { $null = $_ } }
        $alive | Should -BeNullOrEmpty -Because 'the hung suite''s process tree is stopped, not left running'
    }

    # Feature 203 (CI 43981760363 on 0e8ccd890, all three legs): the workflow passed its suite ARRAY through
    # `pwsh -File ... -Suite $suites`, where an array does not bind to [string[]]: the runner refused "A positional
    # parameter cannot be found that accepts argument '<third suite>'" and no suite ran. The cases above always passed
    # ONE suite, so they held on a form the workflow never relied on. These cases run the workflow step's own call line
    # and its exit check, read from the workflow file, with two or more suites, so they test what CI executes.
    Context 'called exactly as the Cross-Platform workflow step calls it' {
        BeforeAll {
            $workflow = Get-Content -LiteralPath (Join-Path $script:RepoRoot '.github/workflows/cross-platform-validation.yml')
            $callIndexes = @(for ($n = 0; $n -lt $workflow.Count; $n++) { if ($workflow[$n] -match 'invoke-bounded-suites\.ps1') { $n } })
            $script:WorkflowCallCount = $callIndexes.Count
            $script:WorkflowCall = if ($callIndexes.Count -eq 1) { $workflow[$callIndexes[0]].Trim() } else { '' }
            $script:WorkflowCheck = if ($callIndexes.Count -eq 1) { $workflow[$callIndexes[0] + 1].Trim() } else { '' }

            function Invoke-AsWorkflow {
                # A child pwsh in the repository root runs the step's two lines as written, with the step's own
                # variables set; its exit code is the step's: non-zero when the check line throws.
                param([Parameter(Mandatory)][string[]]$Suite, [Parameter(Mandatory)][int]$SuiteTimeoutSeconds)
                $quoted = ($Suite | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ', '
                $child = Join-Path $script:FixtureRoot ('as-workflow-' + [guid]::NewGuid().ToString('N') + '.ps1')
                Set-Content -LiteralPath $child -Encoding UTF8 -Value @(
                    '$ErrorActionPreference = ''Stop'''
                    ('Set-Location -LiteralPath ''{0}''' -f ($script:RepoRoot -replace "'", "''"))
                    ('$suites = @({0})' -f $quoted)
                    ('$suiteTimeoutSeconds = {0}' -f $SuiteTimeoutSeconds)
                    $script:WorkflowCall
                    $script:WorkflowCheck
                )
                $output = & $script:PwshPath -NoProfile -NonInteractive -File $child 2>&1
                return [pscustomobject]@{ exit_code = $LASTEXITCODE; text = (@($output) | ForEach-Object { [string]$_ }) -join "`n" }
            }
        }

        It 'the workflow has one call of the runner (the three matrix legs share one step) and it uses the step''s variables' {
            $script:WorkflowCallCount | Should -Be 1
            $script:WorkflowCall | Should -Match '-Suite \$suites\b'
            $script:WorkflowCall | Should -Match '-SuiteTimeoutSeconds \$suiteTimeoutSeconds\b'
            $script:WorkflowCheck | Should -Match '^if \(\$LASTEXITCODE -ne 0\) \{ throw '
        }

        It 'runs every suite of two or more, and the step ends 0 when all pass' {
            $a = New-FixtureSuite -Name 'wf-pass-a.Tests.ps1' -Body '1 | Should -Be 1'
            $b = New-FixtureSuite -Name 'wf-pass-b.Tests.ps1' -Body '2 | Should -Be 2'
            $c = New-FixtureSuite -Name 'wf-pass-c.Tests.ps1' -Body '3 | Should -Be 3'
            $r = Invoke-AsWorkflow -Suite @($a, $b, $c) -SuiteTimeoutSeconds 120
            $r.exit_code | Should -Be 0 -Because $r.text
            foreach ($s in @($a, $b, $c)) { $r.text | Should -Match ([regex]::Escape('--- deterministic suite: ' + $s)) }
        }

        It 'names a failing suite among several, and the step ends non-zero' {
            $a = New-FixtureSuite -Name 'wf-ok.Tests.ps1' -Body '1 | Should -Be 1'
            $bad = New-FixtureSuite -Name 'wf-fail.Tests.ps1' -Body '1 | Should -Be 2'
            $r = Invoke-AsWorkflow -Suite @($a, $bad) -SuiteTimeoutSeconds 120
            $r.exit_code | Should -Not -Be 0 -Because 'the step must go red, not print a failure and end 0'
            $r.text | Should -Match ([regex]::Escape('review-fault-suite-failed:' + $bad))
        }

        It 'names a suite that times out among several, and the step ends non-zero' {
            $a = New-FixtureSuite -Name 'wf-ok2.Tests.ps1' -Body '1 | Should -Be 1'
            $hang = New-FixtureSuite -Name 'wf-hang.Tests.ps1' -Body 'Start-Sleep -Seconds 120'
            $r = Invoke-AsWorkflow -Suite @($a, $hang) -SuiteTimeoutSeconds 8
            $r.exit_code | Should -Not -Be 0
            $r.text | Should -Match ([regex]::Escape('deterministic-suite-timeout:' + $hang))
        }
    }
}
