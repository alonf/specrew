#requires -Version 7.0
# Issue-1 ROOT FIX (the 20-minute Stop): the auto-review must spawn inheriting NOTHING, so it cannot hold the
# dispatcher's - and TRANSITIVELY the HOST's - stdout pipe open. The HOST (Claude Code) reads the dispatcher's
# stdout to EOF with NO drain cap, so an inherited pipe blocks the host until the review exits (~the budget).
#
# This replicates the REAL 4-level chain (host -> dispatcher -> provider -> review), NOT an isolated boundary (the
# isolated harness is what fooled an earlier `-11/-12` fix into "passing" while the real chain still hung). It
# compares the two spawn methods against a 6s "review":
#   A = Start-Process -RedirectStandardOutput + clear -11/-12  -> review STILL holds the host pipe (Start-Process
#       forces bInheritHandles=TRUE -> inherits EVERY handle) -> host hangs ~6s.
#   B = Win32_Process.Create (the fix) -> inherits NOTHING / reparented -> host returns promptly.

Describe 'detached review does not block the HOST read (Issue-1 root fix, 4-level chain)' {

    BeforeAll {
        $script:tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ccr-b2-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:tmp -Force | Out-Null
        $pwsh = (Get-Command pwsh).Source
        $review = Join-Path $script:tmp 'review.ps1'; Set-Content -LiteralPath $review -Value 'Start-Sleep -Seconds 6'
        $rOut = Join-Path $script:tmp 'r.out.log'; $rErr = Join-Path $script:tmp 'r.err.log'
        Set-Content -LiteralPath (Join-Path $script:tmp 'provA.ps1') -Value @"
`$sig = '[DllImport("kernel32.dll", SetLastError=true)] public static extern IntPtr GetStdHandle(int n); [DllImport("kernel32.dll", SetLastError=true)] public static extern bool SetHandleInformation(IntPtr h, uint mask, uint flags);'
Add-Type -Name H -Namespace B2A -MemberDefinition `$sig
foreach (`$s in @(-11,-12)) { [void][B2A.H]::SetHandleInformation([B2A.H]::GetStdHandle(`$s),1,0) }
Start-Process -FilePath '$pwsh' -ArgumentList @('-NoProfile','-File','$review') -PassThru -WindowStyle Hidden -RedirectStandardOutput '$rOut' -RedirectStandardError '$rErr' | Out-Null
Write-Output 'A-DONE'
"@
        Set-Content -LiteralPath (Join-Path $script:tmp 'provB.ps1') -Value @"
`$startup = New-CimInstance -ClassName Win32_ProcessStartup -ClientOnly -Property @{ ShowWindow = [uint16]0 }
`$null = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = ('\"' + '$pwsh' + '\" -NoProfile -File \"' + '$review' + '\"'); ProcessStartupInformation = `$startup }
Write-Output 'B-DONE'
"@
        Set-Content -LiteralPath (Join-Path $script:tmp 'disp.ps1') -Value @'
param([string]$Provider)
$psi = [System.Diagnostics.ProcessStartInfo]::new(); $psi.FileName = (Get-Command pwsh).Source
foreach ($a in @('-NoProfile','-File',$Provider)) { [void]$psi.ArgumentList.Add($a) }
$psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true; $psi.UseShellExecute=$false
$p=[System.Diagnostics.Process]::Start($psi)
$ot=$p.StandardOutput.ReadToEndAsync(); $et=$p.StandardError.ReadToEndAsync()
[void]$p.WaitForExit(20000)
[void][System.Threading.Tasks.Task]::WaitAll(@($ot,$et),5000)
Write-Output 'DISP-DONE'
'@
    }
    AfterAll { Remove-Item -LiteralPath $script:tmp -Recurse -Force -ErrorAction SilentlyContinue }

    It 'Win32_Process.Create lets the HOST read return promptly (the fix)' {
        if (-not $IsWindows) { Set-ItResult -Skipped -Because 'Unix detaches cleanly via -Redirect* (verified 2.8s on WSL); the WMI spawn is Windows-only'; return }
        $disp = Join-Path $script:tmp 'disp.ps1'; $prov = Join-Path $script:tmp 'provB.ps1'
        $psi = [System.Diagnostics.ProcessStartInfo]::new(); $psi.FileName = (Get-Command pwsh).Source
        foreach ($a in @('-NoProfile', '-File', $disp, '-Provider', $prov)) { [void]$psi.ArgumentList.Add($a) }
        $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $p = [System.Diagnostics.Process]::Start($psi); $null = $p.StandardOutput.ReadToEnd(); [void]$p.WaitForExit(20000); $sw.Stop()
        $sw.Elapsed.TotalSeconds | Should -BeLessThan 4 -Because 'a zero-inheritance (reparented) review cannot hold the host pipe; the host read returns when the dispatcher exits, not the 6s review'
    }

    It 'documents that Start-Process + handle-clear is INSUFFICIENT (the review still blocks the host ~6s)' {
        if (-not $IsWindows) { Set-ItResult -Skipped -Because 'Windows-only handle-inheritance behavior'; return }
        $disp = Join-Path $script:tmp 'disp.ps1'; $prov = Join-Path $script:tmp 'provA.ps1'
        $psi = [System.Diagnostics.ProcessStartInfo]::new(); $psi.FileName = (Get-Command pwsh).Source
        foreach ($a in @('-NoProfile', '-File', $disp, '-Provider', $prov)) { [void]$psi.ArgumentList.Add($a) }
        $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $p = [System.Diagnostics.Process]::Start($psi); $null = $p.StandardOutput.ReadToEnd(); [void]$p.WaitForExit(20000); $sw.Stop()
        $sw.Elapsed.TotalSeconds | Should -BeGreaterThan 5 -Because 'Start-Process forces bInheritHandles=TRUE so the review inherits the host pipe transitively despite clearing -11/-12 - this is WHY the fix is Win32_Process.Create, not a handle-clear'
    }
}
