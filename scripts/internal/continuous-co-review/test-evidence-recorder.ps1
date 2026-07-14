$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T111 (DEC-197-I010-004, maintainer send-back 2026-07-08): implementer TEST EVIDENCE for the reviewer.
#
# ROOT CAUSE this closes: the outbound budget policy told the reviewer to "use implementer validation
# evidence first" while the worktree carried NO such evidence, and the falsification stance (rightly)
# forbids trusting prose claims - so on a large change-set the reviewer re-ran the full test pyramid
# and died at the harness budget ceiling (four consecutive budget/quota deaths on 2026-07-08).
#
# The fix: the implementer's ACTUAL test runs are recorded here as MACHINE-OBSERVED evidence
# (suite, counts, exit code, duration, timestamp) bound to the reviewed-state DIGEST of the tree the
# tests ran against. The orchestrator injects the record into the reviewer worktree ONLY on an exact
# digest match (.review/implementer-evidence.json), and the slim prompt lets digest-matched evidence
# substitute for re-running those suites. Hand-written claims never gain evidence standing - only
# this recorder's output does, and only for the exact tree under review (a post-evidence edit changes
# the digest and orphans the record). Evidence lives under .specrew/review/ (digest-EXCLUDED runtime
# state), so recording evidence never changes the tree identity it certifies.

function Get-ContinuousCoReviewTestEvidenceDirectory {
    param([Parameter(Mandatory)][string]$RepoRoot)
    return (Join-Path $RepoRoot '.specrew/review/test-evidence')
}

function Write-ContinuousCoReviewTestEvidence {
    <#
        Records one MACHINE-OBSERVED suite run against the CURRENT working-tree digest. Call this
        right after the real test invocation, in the same session, with the numbers the runner
        reported (never hand-typed). FAIL-SOFT by contract: the recorder must never break a test
        run - any internal failure warns and returns $null.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$Suite,
        [Parameter(Mandatory)][int]$Passed,
        [int]$Failed = 0,
        [int]$Skipped = 0,
        [Parameter(Mandatory)][int]$ExitCode,
        [double]$DurationSeconds = 0,
        [string]$Command,
        [datetime]$Now = [datetime]::UtcNow
    )
    try {
        $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
        if (-not (Get-Command -Name 'Get-ContinuousCoReviewReviewedStateDigest' -ErrorAction SilentlyContinue)) {
            $lp = Join-Path $PSScriptRoot '_load.ps1'
            if (Test-Path -LiteralPath $lp -PathType Leaf) { . $lp }
        }
        $dg = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $resolved
        if ($null -eq $dg -or -not [bool]$dg.ok) {
            $reason = if ($null -ne $dg) { [string]$dg.failure_reason } else { 'digest-unavailable' }
            [Console]::Error.WriteLine("[co-review] WARN TEST_EVIDENCE_NOT_RECORDED reviewed-state digest failed ($reason); the run stays valid but leaves no reviewer evidence.")
            return $null
        }
        $treeId = [string]$dg.tree_id

        $dir = Get-ContinuousCoReviewTestEvidenceDirectory -RepoRoot $resolved
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $dir -Force
        }
        $path = Join-Path $dir ($treeId + '.json')

        $record = $null
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            try { $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } catch { $record = $null }
        }
        if ($null -eq $record -or -not ($record.PSObject.Properties.Name -contains 'suites')) {
            $record = [pscustomobject]@{
                schema_version          = '1.0'
                reviewed_digest_tree_id = $treeId
                recorded_at             = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
                suites                  = @()
            }
        }

        $entry = [pscustomobject]@{
            suite            = $Suite
            passed           = $Passed
            failed           = $Failed
            skipped          = $Skipped
            exit_code        = $ExitCode
            duration_seconds = [math]::Round($DurationSeconds, 3)
            command          = if ([string]::IsNullOrWhiteSpace($Command)) { $null } else { $Command }
            recorded_at      = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        }
        # Same-suite re-record REPLACES (the latest run for this exact tree wins); others accumulate.
        $kept = @(@($record.suites) | Where-Object { $null -ne $_ -and [string]$_.suite -ne $Suite })
        $record.suites = @($kept + $entry)
        $record.recorded_at = $entry.recorded_at

        [System.IO.File]::WriteAllText($path, ($record | ConvertTo-Json -Depth 8))
        return $record
    }
    catch {
        [Console]::Error.WriteLine("[co-review] WARN TEST_EVIDENCE_NOT_RECORDED $($_.Exception.Message)")
        return $null
    }
}

function Get-ContinuousCoReviewTestEvidenceForDigest {
    <# The digest-keyed lookup: returns the record ONLY when it certifies exactly this tree id and carries at least
       one non-empty evidence array. Accepts BOTH the T111 `suites` array (implementer-supplied counts) AND the T018
       `runs` array (universal recorded-run records written by Invoke-ContinuousCoReviewRecordedRun) - the T019
       step-6 unblock so exact-digest recorded runs are injectable as reviewer-visible evidence, not just suites. #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$DigestTreeId
    )
    $dir = Get-ContinuousCoReviewTestEvidenceDirectory -RepoRoot $RepoRoot
    $path = Join-Path $dir ($DigestTreeId + '.json')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        if ($null -eq $record) { return $null }
        if (-not ($record.PSObject.Properties.Name -contains 'reviewed_digest_tree_id')) { return $null }
        if ([string]$record.reviewed_digest_tree_id -ne $DigestTreeId) { return $null }
        $hasSuites = ($record.PSObject.Properties.Name -contains 'suites') -and (@($record.suites).Count -gt 0)
        $hasRuns = ($record.PSObject.Properties.Name -contains 'runs') -and (@($record.runs).Count -gt 0)
        if (-not ($hasSuites -or $hasRuns)) { return $null }
        return $record
    }
    catch { return $null }
}

function Copy-ContinuousCoReviewImplementerEvidence {
    <#
        Injects digest-matched evidence into the reviewer worktree as .review/implementer-evidence.json.
        Returns $true only when a matching record was injected; a mismatch, a missing record, or any
        failure returns $false (the reviewer then simply has no evidence - never wrong evidence).
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$WorktreePath,
        [AllowEmptyString()][string]$DigestTreeId
    )
    try {
        if ([string]::IsNullOrWhiteSpace($DigestTreeId)) { return $false }
        $record = Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $RepoRoot -DigestTreeId $DigestTreeId
        if ($null -eq $record) { return $false }
        $reviewDir = Join-Path $WorktreePath '.review'
        if (-not (Test-Path -LiteralPath $reviewDir -PathType Container)) { return $false }
        [System.IO.File]::WriteAllText((Join-Path $reviewDir 'implementer-evidence.json'), ($record | ConvertTo-Json -Depth 8))
        return $true
    }
    catch {
        [Console]::Error.WriteLine("[co-review] WARN IMPLEMENTER_EVIDENCE_NOT_INJECTED $($_.Exception.Message)")
        return $false
    }
}

# ============================ T018 — universal recorded-run runner (FR-015 amended 2026-07-13) ============================
# LANGUAGE/FRAMEWORK-NEUTRAL: executes ANY declared verification command and records only DIRECT observations, bound to
# the exact reviewed-tree digest. Rich test counts come ONLY from a schema-valid SpecrewTestResult the command PRODUCED
# during the run (never from console-output parsing; there is NO caller-supplied-count parameter). FAIL-LOUD. The
# Specrew self-review is just ONE downstream - the core runner carries NO Pester/pytest/Jest/etc. knowledge.

function Test-ContinuousCoReviewSpecrewTestResult {
    # Validate a parsed object against contracts/specrew-test-result.schema.json (lightweight in-code validator - no
    # external JSON-schema engine). Returns @{ valid; reason; result; counts }.
    param([Parameter(Mandatory)][AllowNull()]$Object)
    if ($null -eq $Object) { return @{ valid = $false; reason = 'null-result' } }
    if ($Object -isnot [System.Management.Automation.PSCustomObject]) { return @{ valid = $false; reason = 'not-an-object' } }
    $props = @($Object.PSObject.Properties.Name)
    if (@($props | Where-Object { $_ -notin @('schema_version', 'result', 'counts') }).Count -gt 0) { return @{ valid = $false; reason = 'unknown-property' } }
    if (($props -notcontains 'schema_version') -or ([string]$Object.schema_version -ne '1.0')) { return @{ valid = $false; reason = 'bad-schema_version' } }
    if ($props -notcontains 'result') { return @{ valid = $false; reason = 'missing-result' } }
    if (([string]$Object.result) -notin @('passed', 'failed', 'errored', 'skipped')) { return @{ valid = $false; reason = 'bad-result-enum' } }
    $counts = $null
    if (($props -contains 'counts') -and ($null -ne $Object.counts)) {
        if ($Object.counts -isnot [System.Management.Automation.PSCustomObject]) { return @{ valid = $false; reason = 'counts-not-an-object' } }
        $cprops = @($Object.counts.PSObject.Properties.Name)
        if (@($cprops | Where-Object { $_ -notin @('passed', 'failed', 'skipped') }).Count -gt 0) { return @{ valid = $false; reason = 'unknown-count' } }
        $counts = [ordered]@{}
        foreach ($k in @('passed', 'failed', 'skipped')) {
            if ($cprops -contains $k) {
                $v = $Object.counts.$k
                if (($v -isnot [int]) -and ($v -isnot [long])) { return @{ valid = $false; reason = "non-integer-count:$k" } }
                if ([long]$v -lt 0) { return @{ valid = $false; reason = "negative-count:$k" } }
                $counts[$k] = [int]$v
            }
        }
    }
    return @{ valid = $true; reason = 'ok'; result = [string]$Object.result; counts = $counts }
}

# ENGINE CAP on any persisted output tail (maintainer decision 2026-07-14): no caller - and no authorized
# diagnostic disclosure - can persist more than this many bytes of (redacted) output text per stream.
$script:ContinuousCoReviewMaxOutputTailBytes = 8192
function Get-ContinuousCoReviewMaxOutputTailBytes { return $script:ContinuousCoReviewMaxOutputTailBytes }

function Test-ContinuousCoReviewDiagnosticDisclosure {
    <#
        Validate a HUMAN-AUTHORIZED diagnostic-disclosure request (maintainer decision 2026-07-14, run
        20260714T130410888 finding f1): raw verification output is PRIVATE BY DEFAULT; a reviewer who cannot
        reach an accurate conclusion without diagnostics may request disclosure, and a HUMAN authorizes it.
        The object is REQUIRED to carry: authorized_by (the human identity), reason (why the absence blocks
        an accurate conclusion), and command_id (the ONE named command it is scoped to). max_tail_bytes is
        optional and always clamped to the engine cap. Returns { valid; reason; authorized_by;
        disclosure_reason; command_id; max_tail_bytes }.
    #>
    param([Parameter(Mandatory)][AllowNull()]$Disclosure)
    if ($null -eq $Disclosure) { return [pscustomobject]@{ valid = $false; reason = 'disclosure is null' } }
    $get = {
        param($Name)
        if ($Disclosure -is [System.Collections.IDictionary]) { if ($Disclosure.Contains($Name)) { return $Disclosure[$Name] } return $null }
        $p = $Disclosure.PSObject.Properties[$Name]; if ($null -ne $p) { return $p.Value } return $null
    }
    $by = [string](& $get 'authorized_by')
    if ([string]::IsNullOrWhiteSpace($by)) { return [pscustomobject]@{ valid = $false; reason = 'authorized_by is required (the HUMAN who authorized the disclosure; disclosure is never automatic)' } }
    $why = [string](& $get 'reason')
    if ([string]::IsNullOrWhiteSpace($why)) { return [pscustomobject]@{ valid = $false; reason = 'reason is required (why the absence of diagnostics prevents an accurate conclusion)' } }
    $cid = [string](& $get 'command_id')
    if ([string]::IsNullOrWhiteSpace($cid)) { return [pscustomobject]@{ valid = $false; reason = 'command_id is required (disclosure is scoped to ONE named command, never blanket)' } }
    $cap = Get-ContinuousCoReviewMaxOutputTailBytes
    $reqBytes = & $get 'max_tail_bytes'
    $bytes = $cap
    if ($null -ne $reqBytes) {
        try { $bytes = [int]$reqBytes } catch { return [pscustomobject]@{ valid = $false; reason = 'max_tail_bytes must be an integer when supplied' } }
        if ($bytes -le 0) { return [pscustomobject]@{ valid = $false; reason = 'max_tail_bytes must be positive (a zero/negative disclosure discloses nothing - omit the disclosure instead)' } }
        if ($bytes -gt $cap) { $bytes = $cap }   # BOUNDED: a request can never buy an unbounded dump.
    }
    return [pscustomobject]@{ valid = $true; reason = $null; authorized_by = $by; disclosure_reason = $why; command_id = $cid; max_tail_bytes = $bytes }
}

function Get-ContinuousCoReviewRedactedOutputText {
    # SECRET-PATTERN REDACTION for output text destined for a persisted, reviewer-visible record (review finding
    # f3, run 20260714T123137002): credential-shaped content is masked BEFORE serialization so a command that
    # prints a token/password/credential-URL does not persist it into digest-bound evidence. Pattern-based
    # redaction is inherently a best-effort layer - the STRUCTURAL guarantees are the child-environment
    # allowlist (secrets never reach a plan child) and full tail SUPPRESSION for supplier-declared plan
    # commands (-TailBytes 0); this masks the recognizable credential shapes in the tails that remain.
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $t = [string]$Text
    # KEY=VALUE / KEY: VALUE where the key smells like a credential - keep the name, mask the value.
    $t = [regex]::Replace($t, '(?im)([A-Z0-9_\-\.]*(?:TOKEN|SECRET|PASSWORD|PASSWD|PWD|API[_-]?KEY|ACCESS[_-]?KEY|CLIENT[_-]?SECRET|CREDENTIAL|AUTH)[A-Z0-9_\-\.]*\s*[=:]\s*)(\S+)', '$1[redacted]')
    # Authorization headers + bearer/basic tokens.
    $t = [regex]::Replace($t, '(?im)\b(authorization\s*:\s*)(\S.*)$', '$1[redacted]')
    $t = [regex]::Replace($t, '(?i)\b(bearer|basic)\s+[A-Za-z0-9+/=_\-\.]{8,}', '$1 [redacted]')
    # URL userinfo credentials (scheme://user:password@host).
    $t = [regex]::Replace($t, '(?i)\b([a-z][a-z0-9+.\-]*://[^/\s:@]+):([^@\s/]+)@', '$1:[redacted]@')
    return $t
}

function Get-ContinuousCoReviewBoundedOutputMeta {
    # BOUNDED + REDACTED metadata for a captured output stream: byte count + sha256 + a bounded, REDACTED tail -
    # never the full raw dump (an unbounded reviewer-visible artifact + potential secret leak). TailBytes <= 0 is
    # the SUPPRESSION mode (review finding f3; the DEFAULT since the 2026-07-14 maintainer decision): NO output
    # text is persisted at all - count/hash only - because arbitrary output may carry secrets no pattern can
    # recognize. byte_count/sha256 always describe the RAW output (the integrity facts); the tail, when present,
    # is a REDACTED excerpt, so it is diagnostic text - not a hash preimage. tail_disclosure states HONESTLY what
    # happened to the text: 'suppressed' (private by default), 'bounded-redacted-tail' (an explicit caller
    # opt-in), or 'authorized-diagnostic' (a human-authorized, command-scoped disclosure; potentially sensitive).
    param([AllowNull()][string]$Text, [int]$TailBytes = 0, [string]$TailDisclosureLabel = 'bounded-redacted-tail')
    $t = if ($null -eq $Text) { '' } else { [string]$Text }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($t)
    $sha = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData($bytes)).Replace('-', '').ToLowerInvariant()
    if ($TailBytes -le 0) {
        return [ordered]@{ byte_count = $bytes.Length; sha256 = $sha; truncated = ($bytes.Length -gt 0); truncated_tail = ''; tail_disclosure = 'suppressed' }
    }
    $cap = Get-ContinuousCoReviewMaxOutputTailBytes
    if ($TailBytes -gt $cap) { $TailBytes = $cap }   # ENGINE CAP: no caller persists an unbounded tail.
    $truncated = $bytes.Length -gt $TailBytes
    $rawTail = if (-not $truncated) { $t } else { [System.Text.Encoding]::UTF8.GetString($bytes, $bytes.Length - $TailBytes, $TailBytes) }
    return [ordered]@{ byte_count = $bytes.Length; sha256 = $sha; truncated = $truncated; truncated_tail = (Get-ContinuousCoReviewRedactedOutputText -Text $rawTail); tail_disclosure = $TailDisclosureLabel }
}

function Invoke-ContinuousCoReviewRecordedRun {
    <#
        The universal, language/framework-NEUTRAL recorded-run runner (FR-015). Executes the declared command,
        records DIRECT facts bound to the exact reviewed-tree digest, and (ONLY if the command produced a schema-valid
        SpecrewTestResult at -ResultPath during this run) records its counts. No console parsing; no caller counts;
        FAIL-LOUD on digest-unavailable, start failure, a REQUIRED-but-missing/invalid result, or a recording failure.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$Executable,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory,
        [int]$TimeoutSeconds = 0,
        [string]$ResultPath,          # OPTIONAL: where the command WRITES its SpecrewTestResult JSON (produced THIS run)
        [switch]$RequireResult,       # a missing/invalid result at -ResultPath then FAILS LOUD (never a richer claim)
        [string[]]$ArtifactPath = @(),
        [int]$OutputTailBytes = 0,    # DEFAULT 0 (maintainer decision 2026-07-14): output text is PRIVATE BY DEFAULT - count/hash only. >0 is an explicit caller opt-in, clamped to the engine cap.
        [string]$CommandId,           # OPTIONAL plan identity - persisted INTO the durable record (the T019 join key)
        $Provenance,                  # OPTIONAL provenance object - persisted INTO the durable record
        [string[]]$EnvRefs,           # OPTIONAL env var NAMES (never values) - persisted INTO the durable record
        [System.Collections.IDictionary]$ChildEnvironment,   # OPTIONAL constructed child environment (allowlist semantics)
        [string]$DeclaredExecutable,  # OPTIONAL supplier-declared executable name (the resolved full path is what executes)
        [AllowNull()]$DiagnosticDisclosure = $null,          # OPTIONAL human-authorized, command_id-scoped disclosure { authorized_by; reason; command_id; max_tail_bytes? } - NEVER automatic
        [datetime]$Now = [datetime]::UtcNow
    )
    # DIAGNOSTIC DISCLOSURE (maintainer decision 2026-07-14): validated FAIL-LOUD (a malformed authorization
    # is a caller error, never silently ignored and never silently honored), and applied ONLY when its
    # command_id EXACTLY matches THIS run's CommandId - scoped to the one named command, never blanket.
    $disclosureApplies = $false; $disclosureInfo = $null
    if ($null -ne $DiagnosticDisclosure) {
        $disclosureInfo = Test-ContinuousCoReviewDiagnosticDisclosure -Disclosure $DiagnosticDisclosure
        if (-not [bool]$disclosureInfo.valid) {
            throw "recorded-run: the supplied DiagnosticDisclosure is INVALID ($($disclosureInfo.reason)) - failing loudly rather than guessing at a disclosure authorization."
        }
        $disclosureApplies = (-not [string]::IsNullOrWhiteSpace($CommandId)) -and ([string]$disclosureInfo.command_id -ceq [string]$CommandId)
    }
    $effectiveTailBytes = if ($disclosureApplies) { [int]$disclosureInfo.max_tail_bytes } else { $OutputTailBytes }
    $tailLabel = if ($disclosureApplies) { 'authorized-diagnostic' } else { 'bounded-redacted-tail' }
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    $cwd = if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) { $resolved } else { (Resolve-Path -LiteralPath $WorkingDirectory).Path }
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewReviewedStateDigest' -ErrorAction SilentlyContinue)) {
        $lp = Join-Path $PSScriptRoot '_load.ps1'; if (Test-Path -LiteralPath $lp -PathType Leaf) { . $lp }
    }
    # DIGEST BINDING (fail-loud): evidence binds to the exact reviewed-tree digest of the tree the command runs against.
    $dg = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $resolved
    if (($null -eq $dg) -or (-not [bool]$dg.ok)) {
        $reason = if ($null -ne $dg) { [string]$dg.failure_reason } else { 'digest-unavailable' }
        throw "recorded-run: cannot bind evidence - reviewed-state digest failed ($reason); refusing to record unbound evidence (fail-loud, FR-015)."
    }
    $treeId = [string]$dg.tree_id

    # STALE-RESULT REJECTION: delete any PRE-EXISTING result file BEFORE the run, so a stale result can never be read
    # as this run's. A rich claim must come from a result THIS run produced.
    $resultFull = $null
    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) {
        $resultFull = if ([System.IO.Path]::IsPathRooted($ResultPath)) { $ResultPath } else { Join-Path $cwd $ResultPath }
        if (Test-Path -LiteralPath $resultFull -PathType Leaf) { Remove-Item -LiteralPath $resultFull -Force -ErrorAction SilentlyContinue }
    }

    # EXECUTE (process-tree contained via Kill(entireProcessTree) on timeout).
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Executable
    foreach ($a in @($Arguments)) { [void]$psi.ArgumentList.Add([string]$a) }
    $psi.WorkingDirectory = $cwd
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    # CHILD-ENVIRONMENT ALLOWLIST with EXECUTION semantics (review finding f2, run 20260714T123137002): when a
    # caller supplies a CONSTRUCTED environment, the child receives EXACTLY that map - the inherited ambient
    # environment is CLEARED first, so every unlisted ambient value (hence every ambient secret) is structurally
    # ABSENT from the child. The VALUES pass through process creation only and are never recorded. When the
    # parameter is absent the child inherits the ambient environment unchanged (the legacy T018 self-evidence
    # behavior, where the recorder wraps the implementer's own dev commands).
    if ($PSBoundParameters.ContainsKey('ChildEnvironment') -and $null -ne $ChildEnvironment) {
        $psi.Environment.Clear()
        foreach ($k in @($ChildEnvironment.Keys)) {
            if ([string]::IsNullOrWhiteSpace([string]$k)) { continue }
            $psi.Environment[[string]$k] = [string]$ChildEnvironment[$k]
        }
    }
    $startedAt = $Now
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = [System.Diagnostics.Process]::new(); $proc.StartInfo = $psi
    try { [void]$proc.Start() } catch { throw "recorded-run: failed to START '$Executable' (fail-loud): $($_.Exception.Message)" }
    $outTask = $proc.StandardOutput.ReadToEndAsync(); $errTask = $proc.StandardError.ReadToEndAsync()
    $timedOut = $false
    if ($TimeoutSeconds -gt 0) {
        if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
            $timedOut = $true
            try { $proc.Kill($true) } catch { $null = $_ }   # ENTIRE process tree
            try { [void]$proc.WaitForExit(5000) } catch { $null = $_ }
        }
    }
    else { $proc.WaitForExit() }
    $sw.Stop()
    $stdout = try { $outTask.GetAwaiter().GetResult() } catch { '' }
    $stderr = try { $errTask.GetAwaiter().GetResult() } catch { '' }
    $exitCode = if ($timedOut) { $null } else { try { [int]$proc.ExitCode } catch { $null } }
    $commandSucceeded = ((-not $timedOut) -and ($null -ne $exitCode) -and ($exitCode -eq 0))
    try { $proc.Dispose() } catch { $null = $_ }

    # OPTIONAL SpecrewTestResult - rich counts ONLY from a schema-valid result THIS run produced.
    $testResult = $null
    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) {
        if (-not (Test-Path -LiteralPath $resultFull -PathType Leaf)) {
            if ($RequireResult) { throw "recorded-run: a SpecrewTestResult was REQUIRED at '$ResultPath' but the command produced none - failing loudly (FR-015), never inferring counts from console output." }
        }
        else {
            $obj = $null
            try { $obj = Get-Content -LiteralPath $resultFull -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $obj = $null }
            $v = Test-ContinuousCoReviewSpecrewTestResult -Object $obj
            if (-not $v.valid) {
                if ($RequireResult) { throw "recorded-run: the SpecrewTestResult at '$ResultPath' is INVALID ($($v.reason)) - failing loudly rather than degrading to a richer pass claim (FR-015)." }
            }
            else { $testResult = [ordered]@{ result = $v.result; counts = $v.counts; source = 'specrew-test-result' } }
        }
    }

    # OUTPUT-ARTIFACT digests.
    $artifacts = @()
    foreach ($ap in @($ArtifactPath)) {
        if ([string]::IsNullOrWhiteSpace($ap)) { continue }
        $apFull = if ([System.IO.Path]::IsPathRooted($ap)) { $ap } else { Join-Path $cwd $ap }
        if (Test-Path -LiteralPath $apFull -PathType Leaf) {
            $fbytes = [System.IO.File]::ReadAllBytes($apFull)
            $fsha = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData($fbytes)).Replace('-', '').ToLowerInvariant()
            $artifacts += [ordered]@{ path = $ap; sha256 = $fsha; byte_count = $fbytes.Length }
        }
    }

    $commandBlock = [ordered]@{ executable = $Executable; arguments = @($Arguments); working_directory = $cwd }
    if ($PSBoundParameters.ContainsKey('DeclaredExecutable') -and -not [string]::IsNullOrWhiteSpace($DeclaredExecutable) -and ([string]$DeclaredExecutable -ne [string]$Executable)) {
        $commandBlock['declared_executable'] = [string]$DeclaredExecutable
    }
    $entry = [ordered]@{
        command                 = $commandBlock
        reviewed_digest_tree_id = $treeId
        started_at              = $startedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        ended_at                = $startedAt.AddSeconds($sw.Elapsed.TotalSeconds).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        duration_seconds        = [math]::Round($sw.Elapsed.TotalSeconds, 3)
        exit_code               = $exitCode
        timed_out               = $timedOut
        command_succeeded       = $commandSucceeded
        stdout_meta             = (Get-ContinuousCoReviewBoundedOutputMeta -Text $stdout -TailBytes $effectiveTailBytes -TailDisclosureLabel $tailLabel)
        stderr_meta             = (Get-ContinuousCoReviewBoundedOutputMeta -Text $stderr -TailBytes $effectiveTailBytes -TailDisclosureLabel $tailLabel)
        artifacts               = @($artifacts)
        counts_available        = ($null -ne $testResult)
        test_result             = $testResult
        recorded_at             = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
    # HONEST MISSING-DIAGNOSTICS SURFACING (maintainer decision 2026-07-14): a FAILED command whose output
    # text was suppressed states explicitly that it cannot be diagnosed from this record alone - the failure
    # stays a failure (command_succeeded=$false is untouched; missing diagnostics NEVER become a clean
    # result), and the reviewer's remedy is a human-authorized diagnostic disclosure, not a guess.
    if ((-not $commandSucceeded) -and ($effectiveTailBytes -le 0)) {
        $entry['failure_diagnostics'] = 'insufficient-without-disclosure'
    }
    # AUDITABLE DISCLOSURE RECORD (durable BY DESIGN - the disclosure exists to reach the reviewer through
    # the digest-keyed evidence store, and durability is what makes it auditable; clearly labeled sensitive).
    if ($disclosureApplies) {
        $entry['diagnostic_disclosure'] = [ordered]@{
            authorized_by         = [string]$disclosureInfo.authorized_by
            reason                = [string]$disclosureInfo.disclosure_reason
            command_id            = [string]$disclosureInfo.command_id
            disclosed_at          = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            tail_bytes            = [int]$disclosureInfo.max_tail_bytes
            potentially_sensitive = $true
            durability            = 'durable-digest-bound'
        }
    }
    # PLAN IDENTITY persisted INTO the durable record (review finding f5, run 20260714T123137002): the T019
    # evidence join binds on command_id + reviewed digest, so identity/provenance/env_ref NAMES must survive
    # serialization - an in-memory-only tag is invisible to any reader of the digest-keyed store.
    if ($PSBoundParameters.ContainsKey('CommandId') -and -not [string]::IsNullOrWhiteSpace($CommandId)) { $entry['command_id'] = [string]$CommandId }
    if ($PSBoundParameters.ContainsKey('Provenance') -and $null -ne $Provenance) { $entry['provenance'] = $Provenance }
    if ($PSBoundParameters.ContainsKey('EnvRefs') -and $null -ne $EnvRefs) { $entry['env_refs'] = @(@($EnvRefs) | Where-Object { $_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_) }) }

    # WRITE bound to the digest, into the digest-keyed store's `runs` array. FAIL LOUD if recording fails.
    try {
        $dir = Get-ContinuousCoReviewTestEvidenceDirectory -RepoRoot $resolved
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $null = New-Item -ItemType Directory -Path $dir -Force }
        $path = Join-Path $dir ($treeId + '.json')
        $record = $null
        if (Test-Path -LiteralPath $path -PathType Leaf) { try { $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } catch { $record = $null } }
        if ($null -eq $record) { $record = [pscustomobject]@{ schema_version = '1.0'; reviewed_digest_tree_id = $treeId; recorded_at = $entry.recorded_at } }
        $existingRuns = @()
        if (($record.PSObject.Properties.Name -contains 'runs') -and ($null -ne $record.runs)) { $existingRuns = @($record.runs) }
        # DURABLE UNIQUENESS KEY (review finding f5): a command_id, when present, IS the identity - two distinct
        # plan commands with the SAME invocation must both persist (separately joinable), while a re-run of the
        # SAME command_id replaces its prior record. Identity-less (legacy) runs key on executable + arguments +
        # working_directory, so the same invocation from different working directories no longer clobbers.
        $entryKey = if (-not [string]::IsNullOrWhiteSpace($CommandId)) { 'command-id:' + $CommandId }
        else { 'invocation:' + $Executable + ' ' + (@($Arguments) -join ' ') + '|wd:' + $cwd }
        $kept = @($existingRuns | Where-Object {
                if ($null -eq $_) { return $false }
                $exId = ''
                if (@($_.PSObject.Properties | ForEach-Object { $_.Name }) -contains 'command_id') { $exId = [string]$_.command_id }
                $exKey = if (-not [string]::IsNullOrWhiteSpace($exId)) { 'command-id:' + $exId }
                else {
                    $exWd = ''
                    try { $exWd = [string]$_.command.working_directory } catch { $exWd = '' }
                    'invocation:' + [string]$_.command.executable + ' ' + (@($_.command.arguments) -join ' ') + '|wd:' + $exWd
                }
                return ($exKey -ne $entryKey)
            })
        $record | Add-Member -NotePropertyName 'runs' -NotePropertyValue @(@($kept) + @([pscustomobject]$entry)) -Force
        $record | Add-Member -NotePropertyName 'reviewed_digest_tree_id' -NotePropertyValue $treeId -Force
        $record | Add-Member -NotePropertyName 'recorded_at' -NotePropertyValue $entry.recorded_at -Force
        [System.IO.File]::WriteAllText($path, ($record | ConvertTo-Json -Depth 12))
    }
    catch {
        throw "recorded-run: evidence RECORDING failed for '$Executable' bound to ${treeId} (fail-loud, FR-015): $($_.Exception.Message)"
    }
    return [pscustomobject]$entry
}
