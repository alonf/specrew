$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T019 / FR-048 — the EXECUTION side of the framework-NEUTRAL verification plan (amended 2026-07-13).
# The thin, order-preserving wrapper that drives the universal T018 recorded-run runner
# (Invoke-ContinuousCoReviewRecordedRun) over the ORDERED commands a downstream command-plan SUPPLIER
# declared, and returns per-command, digest+command_id-bound, provenance-tagged evidence.
#
# WHAT THIS DOES (maintainer amendment 2026-07-13):
#  - Consults the PURE state contract. A `verification-not-configured` plan (null/empty/all-invalid)
#    runs NOTHING and fabricates NO success — { state='verification-not-configured'; command_count=0;
#    evidence=@(); all_succeeded=$false }. all_succeeded is NEVER $true when nothing ran.
#  - A `configured` plan executes COMMAND-BY-COMMAND IN DECLARED ORDER (never sorted). It RECORDS AN
#    EVIDENCE RECORD FOR EVERY ATTEMPTED COMMAND, including failures: a non-zero exit / timeout /
#    structurally-un-runnable command / required-result miss is recorded with command_succeeded=$false
#    and a distinct reason — NEVER dropped and NEVER promoted to a clean result.
#  - Timeout is ALWAYS the ENGINE-BOUNDED value (Resolve-ContinuousCoReviewVerificationTimeout) — never
#    the raw 0/unlimited a supplier requested.
#  - Each record binds to the reviewed-tree DIGEST and its COMMAND_ID; provenance (the object) and the
#    env_ref NAMES are tagged. Env VALUES are NEVER read or recorded (redaction by construction).
#
# WHAT THIS NEVER DOES: it never discovers, infers, selects, or invents a command — it executes EXACTLY
# what the plan declares. Command DISCOVERY is a separate downstream supplier's job; T018 executes and
# T019 injects, neither selects.

# One digest+command_id-bound FAILURE record for an attempted-but-unsuccessful command. Shaped close to
# a real recorded-run record so the T019 evidence-join validator and downstream readers treat it
# uniformly; command_succeeded is ALWAYS $false and the reason/classification name why.
function New-ContinuousCoReviewVerificationFailureRecord {
    param(
        [string]$Executable,
        [string[]]$Arguments = @(),
        [string]$CommandId,
        $Provenance,
        [string[]]$EnvRefs = @(),
        [AllowNull()][string]$DigestTreeId,
        [string]$Classification,
        [string]$Reason,
        [datetime]$Now = [datetime]::UtcNow
    )
    $stamp = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    return [pscustomobject]@{
        command                 = [pscustomobject]@{ executable = [string]$Executable; arguments = @($Arguments); working_directory = $null }
        command_id              = [string]$CommandId
        provenance              = $Provenance
        env_refs                = @($EnvRefs)
        reviewed_digest_tree_id = $DigestTreeId
        started_at              = $stamp
        ended_at                = $stamp
        duration_seconds        = 0
        exit_code               = $null
        timed_out               = $false
        command_succeeded       = $false
        counts_available        = $false
        test_result             = $null
        attempted               = $true
        classification          = $Classification
        failure_reason          = $Reason
        recorded_at             = $stamp
    }
}

function Invoke-ContinuousCoReviewVerificationPlan {
    <#
        Execute a framework-neutral VerificationPlan in DECLARED order. Returns
        { state; command_count; evidence[]; all_succeeded }.

        - verification-not-configured -> { state='verification-not-configured'; command_count=0;
          evidence=@(); all_succeeded=$false } WITHOUT executing anything and WITHOUT fabricating success.
        - configured -> each command executed IN ORDER via the universal recorded-run runner with an
          ENGINE-BOUNDED timeout; EVERY attempt is recorded (successes AND failures) in order, each
          tagged with its command_id, provenance object, and env_ref NAMES; all_succeeded is $true only
          when at least one command ran and EVERY record has command_succeeded=$true.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][AllowNull()]$Plan,
        [datetime]$Now = [datetime]::UtcNow
    )

    # Load guard (same pattern as test-evidence-recorder.ps1): make the universal recorded-run runner +
    # the reviewed-state digest available when this file is used standalone.
    if (-not (Get-Command -Name 'Invoke-ContinuousCoReviewRecordedRun' -ErrorAction SilentlyContinue) -or
        -not (Get-Command -Name 'Get-ContinuousCoReviewReviewedStateDigest' -ErrorAction SilentlyContinue)) {
        $lp = Join-Path $PSScriptRoot '_load.ps1'; if (Test-Path -LiteralPath $lp -PathType Leaf) { . $lp }
    }
    # The PURE plan contract + the StrictMode-safe property reader.
    if (-not (Get-Command -Name 'Resolve-ContinuousCoReviewVerificationPlanState' -ErrorAction SilentlyContinue)) {
        $cp = Join-Path $PSScriptRoot 'verification-plan-contract.ps1'; if (Test-Path -LiteralPath $cp -PathType Leaf) { . $cp }
    }

    $resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

    # STATE GATE: an unconfigured plan runs NOTHING and fabricates NO success.
    $state = Resolve-ContinuousCoReviewVerificationPlanState -Plan $Plan -RepoRoot $resolvedRoot
    if ($state.state -eq 'verification-not-configured') {
        return [pscustomobject]@{ state = 'verification-not-configured'; command_count = 0; evidence = @(); all_succeeded = $false }
    }

    # Best-effort current digest, used to STAMP synthetic failure records so every record (real +
    # synthetic) binds to the same reviewed-tree identity. Real records carry their own (identical) id.
    $digestTreeId = $null
    try {
        $dg = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $resolvedRoot
        if (($null -ne $dg) -and [bool]$dg.ok) { $digestTreeId = [string]$dg.tree_id }
    }
    catch { $digestTreeId = $null }

    # CONFIGURED: execute each declared command IN ORDER (never sorted); RECORD EVERY ATTEMPT.
    # Array-preserving read (NO @() wrapper — the accessor's `, $val` return would otherwise nest as a
    # single wrapper element; the bare assignment captures the real command array, 1 or N elements).
    $commands = Get-ContinuousCoReviewVerificationRawProp -Object $Plan -Name 'commands'
    $evidence = @()
    foreach ($cmd in $commands) {
        # StrictMode-safe field reads: every field except command_id/executable/provenance is optional.
        $commandId = [string](Get-ContinuousCoReviewContractProp -Object $cmd -Name 'command_id')
        $executable = [string](Get-ContinuousCoReviewContractProp -Object $cmd -Name 'executable')
        $argsRaw = Get-ContinuousCoReviewContractProp -Object $cmd -Name 'arguments'
        $arguments = if ($null -eq $argsRaw) { @() } else { @($argsRaw) }
        $workingDir = [string](Get-ContinuousCoReviewContractProp -Object $cmd -Name 'working_directory')
        $timeoutRaw = Get-ContinuousCoReviewContractProp -Object $cmd -Name 'timeout_seconds'
        $requestedTimeout = if ($null -eq $timeoutRaw) { 0 } else { [int]$timeoutRaw }
        $resultPath = [string](Get-ContinuousCoReviewContractProp -Object $cmd -Name 'result_path')
        $requireResult = [bool](Get-ContinuousCoReviewContractProp -Object $cmd -Name 'require_result')
        $provenance = Get-ContinuousCoReviewContractProp -Object $cmd -Name 'provenance'
        $envRefsRaw = Get-ContinuousCoReviewContractProp -Object $cmd -Name 'env_refs'
        # env_ref NAMES only — the VALUES are never read or recorded (redaction by construction).
        $envRefs = @(@($envRefsRaw) | Where-Object { $_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [string]$_ })

        # STRUCTURALLY UN-RUNNABLE: an invalid command (bad id/executable/args/provenance/env/path) is
        # recorded as a failed attempt and skipped — never executed, never dropped, never made clean.
        $cmdCheck = Test-ContinuousCoReviewVerificationCommand -Command $cmd -RepoRoot $resolvedRoot
        if (-not $cmdCheck.valid) {
            $evidence += New-ContinuousCoReviewVerificationFailureRecord -Executable $executable -Arguments $arguments -CommandId $commandId -Provenance $provenance -EnvRefs $envRefs -DigestTreeId $digestTreeId -Classification 'structurally-un-runnable' -Reason $cmdCheck.reason -Now $Now
            continue
        }

        # require_result with nowhere to write the result can NEVER be satisfied -> verification failure.
        if ($requireResult -and [string]::IsNullOrWhiteSpace($resultPath)) {
            $evidence += New-ContinuousCoReviewVerificationFailureRecord -Executable $executable -Arguments $arguments -CommandId $commandId -Provenance $provenance -EnvRefs $envRefs -DigestTreeId $digestTreeId -Classification 'required-result-missing-or-invalid' -Reason 'require_result=true but no result_path declared to satisfy it' -Now $Now
            continue
        }

        # ENGINE-BOUNDED timeout — never the raw 0/unlimited a supplier requested.
        $boundedTimeout = (Resolve-ContinuousCoReviewVerificationTimeout -Requested $requestedTimeout).effective_seconds

        $runParams = @{
            RepoRoot       = $resolvedRoot
            Executable     = $executable
            Arguments      = $arguments
            TimeoutSeconds = $boundedTimeout
            RequireResult  = $requireResult
            Now            = $Now
        }
        if (-not [string]::IsNullOrWhiteSpace($workingDir)) { $runParams.WorkingDirectory = $workingDir }
        if (-not [string]::IsNullOrWhiteSpace($resultPath)) { $runParams.ResultPath = $resultPath }

        try {
            # Execute EXACTLY what the command declares (never inferred/invented) via the universal runner.
            $ev = Invoke-ContinuousCoReviewRecordedRun @runParams
            # Tag the digest-bound evidence with its identity + auditable provenance + env_ref NAMES.
            $ev | Add-Member -NotePropertyName 'command_id' -NotePropertyValue $commandId -Force
            $ev | Add-Member -NotePropertyName 'provenance' -NotePropertyValue $provenance -Force
            $ev | Add-Member -NotePropertyName 'env_refs' -NotePropertyValue @($envRefs) -Force
            $ev | Add-Member -NotePropertyName 'attempted' -NotePropertyValue $true -Force
            $ev | Add-Member -NotePropertyName 'classification' -NotePropertyValue 'executed' -Force
            $evidence += $ev
        }
        catch {
            # The universal runner FAILS LOUD (a REQUIRED-but-missing/invalid result, a start failure, or
            # a digest-unavailable bind). Amendment 8/9: that failure is RECORDED as a failed command,
            # never thrown away and never promoted to a clean result.
            $msg = [string]$_.Exception.Message
            $cls = if ($requireResult -and (($msg -match 'REQUIRED') -or ($msg -match 'INVALID'))) { 'required-result-missing-or-invalid' } else { 'recorded-run-failed' }
            $evidence += New-ContinuousCoReviewVerificationFailureRecord -Executable $executable -Arguments $arguments -CommandId $commandId -Provenance $provenance -EnvRefs $envRefs -DigestTreeId $digestTreeId -Classification $cls -Reason $msg -Now $Now
        }
    }

    $failedCount = @($evidence | Where-Object { -not [bool]$_.command_succeeded }).Count
    $allSucceeded = (@($evidence).Count -gt 0) -and ($failedCount -eq 0)
    return [pscustomobject]@{ state = 'configured'; command_count = @($commands).Count; evidence = @($evidence); all_succeeded = $allSucceeded }
}
