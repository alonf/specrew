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
#  - Each record binds to the reviewed-tree DIGEST and its COMMAND_ID; the recorder PERSISTS command_id +
#    provenance (the object) + env_ref NAMES into the digest-keyed store (the T019 join identity).
#  - working_directory + result_path are REPOSITORY-relative (the schema semantics) and are anchored
#    against RepoRoot before execution - never against the caller process CWD.
#  - env_refs have EXECUTION semantics AND are the AUTHORITATIVE allowlist: the child environment is built
#    from an EMPTY map + the normative (currently empty) engine baseline + the declared env_ref NAMES
#    (values resolved from the ambient environment at spawn) - every unlisted ambient value is structurally
#    absent from the child. The executable is resolved to a full path BEFORE the environment is constructed,
#    so an inherited PATH is never implicitly required. Env VALUES are NEVER recorded; persisted records
#    carry NO output text for plan commands unless a HUMAN-AUTHORIZED, command-scoped diagnostic disclosure
#    is supplied (count/hash only by default), so printed output cannot leak into evidence.
#
# WHAT THIS NEVER DOES: it never discovers, infers, selects, or invents a command — it executes EXACTLY
# what the plan declares. Command DISCOVERY is a separate downstream supplier's job; T018 executes and
# T019 injects, neither selects.

# The NORMATIVE, platform-specific ENGINE baseline (maintainer decision 2026-07-14, run 20260714T130410888
# finding f1): the ONLY variable names the engine may pass to a plan child WITHOUT a declared env_ref, and
# ONLY because runtime evidence proves the ENGINE ITSELF (constructed-environment process launch) requires
# them at spawn. CURRENT EVIDENCE (the paired 'engine baseline evidence' tests in
# verification-plan-runner.Tests.ps1, run on Windows AND Linux): a resolved-full-path child launches and
# exits 0 with a COMPLETELY EMPTY constructed environment on BOTH platforms - so the baseline is EMPTY on
# both. HOME / USERPROFILE / APPDATA / LOCALAPPDATA are excluded by maintainer ruling; PSModulePath, locale,
# terminal, and tool-specific variables are supplier-declared env_refs, never implicit baseline. Any future
# addition to this list MUST land together with a paired runtime-evidence test proving the engine fails to
# LAUNCH a child without it on that platform.
function Get-ContinuousCoReviewVerificationEngineBaseline {
    if ($IsWindows) { return @() }
    return @()
}

# The CONSTRUCTED child environment for a supplier-declared verification command (review findings f2 run
# 20260714T123137002 + f1 run 20260714T130410888 - env_refs are the AUTHORITATIVE allowlist): built from an
# EMPTY map, then EXACTLY the normative engine baseline (above; currently empty) + the plan-declared env_ref
# NAMES, each copied from the ambient environment AT SPAWN when present there. Every other ambient value -
# hence every ambient secret AND every implicit infrastructure value (HOME, PATH, TEMP, PSModulePath, ...) -
# is structurally ABSENT from the child process. A command that needs such a variable declares it as an
# env_ref (least privilege + reproducibility; the contract, not the engine, decides what flows). Values pass
# through process creation only; the evidence records env_ref NAMES separately and VALUES never.
function Get-ContinuousCoReviewVerificationChildEnvironment {
    param([string[]]$EnvRefs = @())
    $map = @{}
    $names = @(Get-ContinuousCoReviewVerificationEngineBaseline) + @(@($EnvRefs) | Where-Object { $_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($n in $names) {
        $v = [System.Environment]::GetEnvironmentVariable([string]$n)
        if ($null -ne $v) { $map[[string]$n] = [string]$v }
    }
    return $map
}

# EXECUTABLE RESOLUTION BEFORE SPAWN (maintainer decision 2026-07-14): the declared executable is resolved
# to a full path AGAINST THE AMBIENT PARENT ENVIRONMENT before the child environment is constructed, so the
# child never needs an inherited PATH just to be launched. A rooted path must exist; a relative path with a
# directory separator anchors to RepoRoot and must resolve INSIDE it; a bare name resolves via Get-Command
# (the parent's PATH, at spawn). An unresolvable executable is a RECORDED failure - never a silent skip.
function Resolve-ContinuousCoReviewVerificationExecutable {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string]$RepoRoot
    )
    if ([System.IO.Path]::IsPathRooted($Executable)) {
        if (Test-Path -LiteralPath $Executable -PathType Leaf) {
            return [pscustomobject]@{ resolved = $true; path = ([System.IO.Path]::GetFullPath($Executable)); method = 'rooted-path'; reason = $null }
        }
        return [pscustomobject]@{ resolved = $false; path = $null; method = 'rooted-path'; reason = "declared executable '$Executable' does not exist" }
    }
    if ($Executable -match '[\\/]') {
        $rootFull = ([System.IO.Path]::GetFullPath($RepoRoot)).TrimEnd([char]'\', [char]'/')
        $full = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $Executable))
        $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
        if (-not $full.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return [pscustomobject]@{ resolved = $false; path = $null; method = 'repo-relative'; reason = "declared executable '$Executable' resolves outside the repository root" }
        }
        if (Test-Path -LiteralPath $full -PathType Leaf) {
            return [pscustomobject]@{ resolved = $true; path = $full; method = 'repo-relative'; reason = $null }
        }
        return [pscustomobject]@{ resolved = $false; path = $null; method = 'repo-relative'; reason = "declared executable '$Executable' does not exist under the repository root" }
    }
    $cmd = @(Get-Command -Name $Executable -CommandType Application -ErrorAction SilentlyContinue) | Select-Object -First 1
    if ($null -ne $cmd -and -not [string]::IsNullOrWhiteSpace([string]$cmd.Source)) {
        return [pscustomobject]@{ resolved = $true; path = [string]$cmd.Source; method = 'ambient-path-resolution'; reason = $null }
    }
    return [pscustomobject]@{ resolved = $false; path = $null; method = 'ambient-path-resolution'; reason = "declared executable '$Executable' is not resolvable on the engine's PATH" }
}

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
        # OPTIONAL human-authorized, command-scoped diagnostic disclosure (maintainer decision 2026-07-14):
        # { authorized_by; reason; command_id; max_tail_bytes? }. NEVER automatic - absent means every plan
        # command persists NO output text. Validated FAIL-FAST here (a structurally invalid authorization is
        # a caller error and runs ZERO commands); scoping to the named command_id is enforced by the recorder.
        [AllowNull()]$DiagnosticDisclosure = $null,
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
        return [pscustomobject]@{ state = 'verification-not-configured'; command_count = 0; evidence = @(); all_succeeded = $false; reason = $state.reason }
    }

    # STRUCTURAL GATE (maintainer decision 2026-07-13): a structurally-invalid plan - a malformed IDENTITY GRAPH,
    # e.g. a DUPLICATE command_id - is rejected FAIL-FAST, BEFORE any command executes, so it produces ZERO command
    # side effects. (T019's evidence-join duplicate rejection stays as DEFENSE-IN-DEPTH for records that still
    # arrive somehow.) command_id uniqueness is part of the plan schema, so it belongs at the validation boundary.
    $structural = Test-ContinuousCoReviewVerificationPlan -Plan $Plan -RepoRoot $resolvedRoot
    if (-not $structural.valid) {
        return [pscustomobject]@{ state = 'verification-plan-invalid'; command_count = $structural.command_count; evidence = @(); all_succeeded = $false; reason = $structural.reason }
    }

    # DIAGNOSTIC-DISCLOSURE GATE (fail-fast, zero side effects): a structurally invalid authorization object
    # is a CALLER error - refuse it BEFORE any command executes, exactly like the malformed-identity gate.
    if ($null -ne $DiagnosticDisclosure) {
        $dv = Test-ContinuousCoReviewDiagnosticDisclosure -Disclosure $DiagnosticDisclosure
        if (-not [bool]$dv.valid) {
            throw "verification-plan: the supplied DiagnosticDisclosure is INVALID ($($dv.reason)) - refusing to run ANY command under a malformed disclosure authorization (never automatic, never degraded)."
        }
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

        # RESOLVE THE EXECUTABLE BEFORE SPAWN (maintainer decision 2026-07-14): full-path resolution against
        # the AMBIENT parent environment happens here, so the constructed child environment never needs an
        # inherited PATH for launch. Unresolvable -> a RECORDED failure; the plan continues (never dropped).
        $exeResolution = Resolve-ContinuousCoReviewVerificationExecutable -Executable $executable -RepoRoot $resolvedRoot
        if (-not [bool]$exeResolution.resolved) {
            $evidence += New-ContinuousCoReviewVerificationFailureRecord -Executable $executable -Arguments $arguments -CommandId $commandId -Provenance $provenance -EnvRefs $envRefs -DigestTreeId $digestTreeId -Classification 'executable-not-resolvable' -Reason $exeResolution.reason -Now $Now
            continue
        }

        $runParams = @{
            RepoRoot           = $resolvedRoot
            Executable         = $exeResolution.path
            DeclaredExecutable = $executable
            Arguments          = $arguments
            TimeoutSeconds   = $boundedTimeout
            RequireResult    = $requireResult
            # IDENTITY INTO THE DURABLE RECORD (review finding f5, run 20260714T123137002): the recorder
            # persists command_id + provenance + env_ref NAMES into the digest-keyed store BEFORE
            # serialization, so the persisted run joins on the authoritative command_id + reviewed digest.
            CommandId        = $commandId
            Provenance       = $provenance
            EnvRefs          = @($envRefs)
            # NO PERSISTED OUTPUT TEXT for supplier-declared commands (review finding f3 + maintainer
            # decision 2026-07-14): arbitrary plan output may carry secrets no pattern can recognize, so
            # tails are SUPPRESSED (count/hash only); the recorded facts (exit code, duration, digest,
            # optional SpecrewTestResult) carry the verdict. The ONLY door is the human-authorized,
            # command_id-scoped DiagnosticDisclosure the recorder enforces - never automatic.
            OutputTailBytes  = 0
            # ENV ALLOWLIST EXECUTION SEMANTICS (review findings f2 + f1 run 20260714T130410888): the child
            # receives an EMPTY-map-constructed environment - the normative engine baseline + the declared
            # env_refs only, resolved from the ambient environment at spawn - every unlisted ambient value
            # is structurally absent. Values are never recorded.
            ChildEnvironment = (Get-ContinuousCoReviewVerificationChildEnvironment -EnvRefs $envRefs)
            Now              = $Now
        }
        if ($null -ne $DiagnosticDisclosure) { $runParams.DiagnosticDisclosure = $DiagnosticDisclosure }
        # REPO-ROOT ANCHORING (review finding f4): the schema defines working_directory AND result_path as
        # REPOSITORY-relative. Anchor BOTH against RepoRoot here so execution is independent of the caller
        # process CWD and result_path never silently re-anchors to the working directory. (Path safety was
        # validated above; the anchored absolute paths are inside RepoRoot by construction.)
        if (-not [string]::IsNullOrWhiteSpace($workingDir)) { $runParams.WorkingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($resolvedRoot, $workingDir)) }
        if (-not [string]::IsNullOrWhiteSpace($resultPath)) { $runParams.ResultPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($resolvedRoot, $resultPath)) }

        try {
            # Execute EXACTLY what the command declares (never inferred/invented) via the universal runner.
            $ev = Invoke-ContinuousCoReviewRecordedRun @runParams
            # command_id/provenance/env_refs are persisted INTO the durable record by the recorder (finding
            # f5); only the runner-level annotations are tagged here (in-memory, per-attempt).
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
    return [pscustomobject]@{ state = 'configured'; command_count = @($commands).Count; evidence = @($evidence); all_succeeded = $allSucceeded; reason = $null }
}
