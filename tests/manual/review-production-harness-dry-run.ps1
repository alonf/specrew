#requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$RequireAll
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\continuous-co-review\_load.ps1')

$hosts = @('claude', 'codex', 'copilot', 'cursor-agent', 'antigravity')
$scratchRoot = Join-Path ([IO.Path]::GetTempPath()) ('specrew-production-harness-dry-run-' + [guid]::NewGuid().ToString('N'))
$results = [Collections.Generic.List[object]]::new()
$failures = [Collections.Generic.List[string]]::new()

try {
    $null = New-Item -ItemType Directory -Path $scratchRoot -Force
    foreach ($hostName in $hosts) {
        $definition = Get-ContinuousCoReviewProductionHarnessDefinition -HostName $hostName
        if ($null -eq $definition) {
            $failures.Add(("{0}: no production harness definition" -f $hostName)) | Out-Null
            continue
        }

        $commandName = [string]$definition.command
        $command = Get-Command -Name $commandName -CommandType Application -ErrorAction SilentlyContinue
        if ($null -eq $command) {
            $message = ("{0}: executable '{1}' is not installed" -f $hostName, $commandName)
            if ($RequireAll) { $failures.Add($message) | Out-Null }
            $results.Add([pscustomobject]@{ host = $hostName; installed = $false; preflight = 'not-run'; process_spec = 'not-built'; provider_invoked = $false }) | Out-Null
            continue
        }

        $hostRoot = Join-Path $scratchRoot $hostName
        $snapshot = Join-Path $hostRoot 'snapshot'
        $stage = Join-Path $hostRoot 'stage'
        $null = New-Item -ItemType Directory -Path $snapshot, $stage -Force
        $invocation = [pscustomobject][ordered]@{
            schema_version = '1.0'
            campaign_id = 'cmp-production-dry-run'
            run_id = ('run-dry-' + $hostName)
            target_digest = ('digest-dry-' + $hostName)
            snapshot_path = $snapshot
            review_scope = 'Build and validate the bounded production process specification without invoking the reviewer.'
            prompt_path = (Join-Path $repoRoot 'scripts\internal\continuous-co-review\reviewer-candidate-prompt.md')
            candidate_result_path = (Join-Path $stage 'candidate.json')
            candidate_report_path = (Join-Path $stage 'candidate.md')
            deadline = ([DateTimeOffset]::UtcNow.AddMinutes(20).ToString('o'))
        }

        $port = New-ReviewProductionHarnessPort -HostName $hostName
        $preflight = & $port.preflight $invocation
        if (-not [bool]$preflight.ok) {
            $failures.Add(("{0}: production preflight failed ({1})" -f $hostName, $preflight.reason)) | Out-Null
            continue
        }

        # Deliberately call build_process, never invoke. This exercises the real catalog constructor,
        # installed-executable probe, bounded file-primary prompt, argument/stdin transport and runtime
        # process contract without spending a reviewer round or launching a provider.
        $spec = & $port.build_process $invocation ([ordered]@{
                SPECREW_REFOCUS_DISABLE = '1'
                SPECREW_DISABLE_EVENTS = 'SessionStart,UserPromptSubmit,Stop'
            })
        $validation = Test-ReviewRuntimeProcessSpec -Spec $spec -Invocation $invocation
        if (-not [bool]$validation.valid) {
            $failures.Add(("{0}: process specification invalid ({1})" -f $hostName, ($validation.errors -join ', '))) | Out-Null
            continue
        }
        if ([IO.File]::Exists([string]$invocation.candidate_result_path)) {
            $failures.Add(("{0}: dry-run unexpectedly produced candidate.json" -f $hostName)) | Out-Null
            continue
        }

        $results.Add([pscustomobject]@{
                host = $hostName
                installed = $true
                executable = [string]$command.Source
                harness_id = [string]$port.id
                prompt_transport = [string]$spec.prompt_transport
                argument_count = @($spec.argument_list).Count
                timeout_seconds = [int]$spec.timeout_seconds
                preflight = [string]$preflight.reason
                process_spec = 'valid'
                provider_invoked = $false
            }) | Out-Null
    }

    $results | Format-Table -AutoSize | Out-String | Write-Host
    if ($failures.Count -gt 0) {
        foreach ($failure in $failures) { Write-Error $failure }
        exit 1
    }

    $installedCount = @($results | Where-Object installed).Count
    Write-Host ("Production harness dry-run: {0}/{1} installed harnesses passed preflight + process-spec validation; provider invocations: 0." -f $installedCount, $hosts.Count) -ForegroundColor Green
}
finally {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
}
