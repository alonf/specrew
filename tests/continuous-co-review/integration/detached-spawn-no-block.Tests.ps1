#requires -Version 7.0
# Issue-1 LEAK FIX (scripts/internal/continuous-co-review/co-review-service.ps1): a detached review spawned via
# Start-Process must NOT make a parent that reads this provider's stdout (the dispatcher) block until the REVIEW
# exits. Root cause: the child inherits the parent's stdout PIPE (Start-Process forces bInheritHandles=true), so
# the dispatcher's ReadToEnd hangs until the review closes it - the 35-min Stop. The fix clears HANDLE_FLAG_INHERIT
# on stdout/stderr before the spawn (Windows; Unix detaches cleanly via -Redirect*, verified 2.8s on WSL).
# This pins the MECHANISM the real spawn uses: with the clear, the parent's piped read returns when the PROVIDER
# exits, not when the detached grandchild (a 6s sleeper) exits. Harness baseline was 11.4s without -> 1.8s with.

Describe 'detached spawn does not block the parent piped read (Issue-1 leak fix)' {

    It 'a provider that clears stdio inheritance + spawns a detached child returns to the parent fast' {
        if (-not $IsWindows) {
            Set-ItResult -Skipped -Because 'Unix detaches cleanly via -Redirect* (verified 2.8s baseline on WSL, no leak); the handle-clear is Windows-only'
            return
        }
        $d = Join-Path ([System.IO.Path]::GetTempPath()) ("ccr-detach-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        try {
            Set-Content -LiteralPath (Join-Path $d 'gc.ps1') -Value 'Start-Sleep -Seconds 6'
            $prov = Join-Path $d 'prov.ps1'
            # Provider mirrors co-review-service.ps1: clear HANDLE_FLAG_INHERIT, THEN Start-Process -RedirectStandardOutput.
            $provBody = @'
param([string]$Gc, [string]$GcOut, [string]$GcErr)
$sig = '[DllImport("kernel32.dll", SetLastError=true)] public static extern IntPtr GetStdHandle(int n); [DllImport("kernel32.dll", SetLastError=true)] public static extern bool SetHandleInformation(IntPtr h, uint mask, uint flags);'
Add-Type -Name HandleHelper -Namespace SpecrewCoReviewTest -MemberDefinition $sig
foreach ($std in @(-11, -12)) { [void][SpecrewCoReviewTest.HandleHelper]::SetHandleInformation([SpecrewCoReviewTest.HandleHelper]::GetStdHandle($std), 1, 0) }
$p = Start-Process -FilePath (Get-Command pwsh).Source -ArgumentList @('-NoProfile','-File',$Gc) -PassThru -WindowStyle Hidden -RedirectStandardOutput $GcOut -RedirectStandardError $GcErr
Write-Output 'PROVIDER-DONE'
'@
            Set-Content -LiteralPath $prov -Value $provBody
            $psi = [System.Diagnostics.ProcessStartInfo]::new(); $psi.FileName = (Get-Command pwsh).Source
            foreach ($a in @('-NoProfile', '-File', $prov, '-Gc', (Join-Path $d 'gc.ps1'), '-GcOut', (Join-Path $d 'gc.out.log'), '-GcErr', (Join-Path $d 'gc.err.log'))) { [void]$psi.ArgumentList.Add($a) }
            $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $proc = [System.Diagnostics.Process]::Start($psi)
            $out = $proc.StandardOutput.ReadToEnd(); [void]$proc.WaitForExit(15000); $sw.Stop()
            $out.Trim() | Should -Be 'PROVIDER-DONE' -Because 'the provider still writes its OWN stdout to the parent (the clear only blocks inheritance)'
            $sw.Elapsed.TotalSeconds | Should -BeLessThan 4 -Because 'the parent returns when the PROVIDER exits, NOT when the 6s detached child exits (the leak would block ~6s)'
        }
        finally { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
