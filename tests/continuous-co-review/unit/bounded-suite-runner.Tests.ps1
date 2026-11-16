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
        $script:Runner = Join-Path $script:RepoRoot 'tests/continuous-co-review/invoke-bounded-suites.ps1'
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
}
