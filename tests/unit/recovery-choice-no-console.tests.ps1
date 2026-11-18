# Feature 206, T001 (FR-001, bug list item 1): with stale session state and no console input,
# Read-SpecrewRecoveryChoice must not prompt or loop. It returns no choice, and specrew start prints a plain
# refusal and exits non-zero. An interactive console gets at most three invalid answers.
#
# Each case runs the function in a child pwsh with a hard time limit, so the old endless loop shows as a
# timeout instead of hanging this suite. The child only dot-sources scripts/internal/session-recovery.ps1 (a
# function library) and calls the function: nothing is written anywhere, no hooks are deployed.

BeforeAll {
    $script:RecoveryScript = (Resolve-Path (Join-Path $PSScriptRoot '..\..\scripts\internal\session-recovery.ps1')).Path
    $script:StartScript = (Resolve-Path (Join-Path $PSScriptRoot '..\..\scripts\specrew-start.ps1')).Path
    $script:PwshPath = (Get-Process -Id $PID).Path

    function Invoke-RecoveryChild {
        param(
            [Parameter(Mandatory = $true)][string]$Body,
            [switch]$NonInteractive,
            [int]$TimeoutMs = 20000
        )

        $prologue = ". '{0}'`n" -f $script:RecoveryScript.Replace("'", "''")
        $command = $prologue + $Body
        $psi = [System.Diagnostics.ProcessStartInfo]::new($script:PwshPath)
        $psi.ArgumentList.Add('-NoProfile')
        if ($NonInteractive) { $psi.ArgumentList.Add('-NonInteractive') }
        $psi.ArgumentList.Add('-Command')
        $psi.ArgumentList.Add($command)
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false

        $process = [System.Diagnostics.Process]::Start($psi)
        # No console input: stdin is redirected and closed at once.
        $process.StandardInput.Close()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $exited = $process.WaitForExit($TimeoutMs)
        if (-not $exited) {
            try { $process.Kill($true) } catch { }
            $process.WaitForExit()
        }

        [pscustomobject]@{
            Exited = $exited
            Stdout = $stdoutTask.GetAwaiter().GetResult()
            Stderr = $stderrTask.GetAwaiter().GetResult()
        }
    }
}

Describe 'Read-SpecrewRecoveryChoice without console input (FR-001)' {
    It 'returns no choice and never loops when stdin is redirected and empty' {
        $result = Invoke-RecoveryChild -Body @'
$choice = Read-SpecrewRecoveryChoice
'CHOICE=[{0}]' -f $choice
'@
        $result.Exited | Should -BeTrue -Because 'a no-console run must end, not loop on Read-Host'
        $result.Stdout | Should -Match 'CHOICE=\[\]'
        $result.Stdout | Should -Not -Match 'Invalid recovery choice'
    }

    It 'returns no choice in a -NonInteractive host instead of failing on Read-Host' {
        $result = Invoke-RecoveryChild -NonInteractive -Body @'
$choice = Read-SpecrewRecoveryChoice
'CHOICE=[{0}]' -f $choice
'@
        $result.Exited | Should -BeTrue
        $result.Stdout | Should -Match 'CHOICE=\[\]'
        $result.Stderr | Should -Not -Match 'NonInteractive'
    }

    It 'still honours a preferred choice without reading anything' {
        $result = Invoke-RecoveryChild -Body @'
$choice = Read-SpecrewRecoveryChoice -PreferredChoice 'b'
'CHOICE=[{0}]' -f $choice
'@
        $result.Exited | Should -BeTrue
        $result.Stdout | Should -Match 'CHOICE=\[B\]'
    }
}

Describe 'Read-SpecrewRecoveryChoice with an interactive console (FR-001)' {
    It 'stops after three invalid answers and returns no choice' {
        $result = Invoke-RecoveryChild -Body @'
function Test-SpecrewConsoleInputAvailable { $true }
$script:reads = 0
function Read-Host { param($Prompt) $script:reads++; 'x' }
$choice = Read-SpecrewRecoveryChoice
'CHOICE=[{0}] READS={1}' -f $choice, $script:reads
'@
        $result.Exited | Should -BeTrue -Because 'invalid answers must not loop forever'
        $result.Stdout | Should -Match 'CHOICE=\[\] READS=3'
    }

    It 'returns a valid answer on the first read' {
        $result = Invoke-RecoveryChild -Body @'
function Test-SpecrewConsoleInputAvailable { $true }
$script:reads = 0
function Read-Host { param($Prompt) $script:reads++; ' c ' }
$choice = Read-SpecrewRecoveryChoice
'CHOICE=[{0}] READS={1}' -f $choice, $script:reads
'@
        $result.Exited | Should -BeTrue
        $result.Stdout | Should -Match 'CHOICE=\[C\] READS=1'
    }
}

Describe 'The refusal specrew start prints (FR-001)' {
    It 'says what could not be completed, that the work is safe, and the one recovering command' {
        $result = Invoke-RecoveryChild -Body @'
Get-SpecrewRecoveryRefusalMessage
'@
        $result.Exited | Should -BeTrue
        $result.Stdout | Should -Match 'stale session state'
        $result.Stdout | Should -Match 'safe'
        $result.Stdout | Should -Match '--recovery-choice A'
        $result.Stdout | Should -Not -Match '(?i)broken|bug|fault'
    }

    It 'is printed by specrew start, which then exits non-zero, when no choice comes back' {
        $source = Get-Content -LiteralPath $script:StartScript -Raw
        $pattern = '\$selectedRecoveryChoice\s*=\s*Read-SpecrewRecoveryChoice[^\r\n]*\r?\n\s*if\s*\(\s*\[string\]::IsNullOrWhiteSpace\(\$selectedRecoveryChoice\)\s*\)\s*\{\s*Write-Output\s*\(Get-SpecrewRecoveryRefusalMessage\)\s*exit\s+1'
        $source | Should -Match $pattern
    }
}
