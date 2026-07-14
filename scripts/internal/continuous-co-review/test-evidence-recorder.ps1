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
            suite                   = $Suite
            passed                  = $Passed
            failed                  = $Failed
            skipped                 = $Skipped
            exit_code               = $ExitCode
            duration_seconds        = [math]::Round($DurationSeconds, 3)
            command                 = if ([string]::IsNullOrWhiteSpace($Command)) { $null } else { $Command }
            # EMBEDDED digest identity (review finding f3, run 20260714T172315119): every embedded entry
            # carries the digest it certifies, so the injectable check can enforce envelope AND embedded.
            reviewed_digest_tree_id = $treeId
            recorded_at             = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
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
        # ENVELOPE AND EVERY EMBEDDED DIGEST (review finding f3, run 20260714T172315119 - the binding T019
        # rule Test-ContinuousCoReviewEvidenceInjectable encodes): a record keyed for digest B carrying an
        # entry recorded at digest A (or carrying NO embedded identity) is REFUSED - fail closed, so the
        # reviewer gets NO evidence rather than wrong evidence. Legacy suite entries without an embedded
        # digest retire with their orphaned digests; the current writers stamp every entry.
        if (-not (Get-Command -Name 'Test-ContinuousCoReviewEvidenceInjectable' -ErrorAction SilentlyContinue)) {
            $ric = Join-Path $PSScriptRoot 'review-identity-contracts.ps1'
            if (Test-Path -LiteralPath $ric -PathType Leaf) { . $ric }
        }
        if (-not (Get-Command -Name 'Test-ContinuousCoReviewEvidenceInjectable' -ErrorAction SilentlyContinue)) { return $null }   # cannot validate -> cannot inject
        $embedded = @()
        if ($hasSuites) { foreach ($s in @($record.suites)) { $embedded += [string]$(if ($null -ne $s -and ($s.PSObject.Properties.Name -contains 'reviewed_digest_tree_id')) { $s.reviewed_digest_tree_id } else { '' }) } }
        if ($hasRuns) { foreach ($r in @($record.runs)) { $embedded += [string]$(if ($null -ne $r -and ($r.PSObject.Properties.Name -contains 'reviewed_digest_tree_id')) { $r.reviewed_digest_tree_id } else { '' }) } }
        $inj = Test-ContinuousCoReviewEvidenceInjectable -EnvelopeDigest ([string]$record.reviewed_digest_tree_id) -ReviewDigest $DigestTreeId -EmbeddedDigests $embedded
        if (-not [bool]$inj.injectable) {
            [Console]::Error.WriteLine("[co-review] WARN EVIDENCE_NOT_INJECTABLE $($inj.classification) for digest $DigestTreeId - refusing the record (fail closed; no evidence beats wrong evidence).")
            return $null
        }
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
        [AllowEmptyString()][string]$DigestTreeId,
        # The ACTUAL SELECTED VerificationPlan (the FR-049 supplier seam; maintainer wiring directive
        # 2026-07-15): plan-run joinability is enforced against ITS command set and NOTHING else - the
        # validating plan is NEVER derived from the evidence itself. Absent (no supplier configured), every
        # plan-identified run is withheld fail-closed as `selected-plan-unavailable`.
        [AllowNull()]$Plan = $null
    )
    try {
        if ([string]::IsNullOrWhiteSpace($DigestTreeId)) { return $false }
        $record = Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $RepoRoot -DigestTreeId $DigestTreeId
        if ($null -eq $record) { return $false }
        $reviewDir = Join-Path $WorktreePath '.review'
        if (-not (Test-Path -LiteralPath $reviewDir -PathType Container)) { return $false }

        # FR-048 JOIN AT THE INJECTION BOUNDARY (review finding f1, run 20260714T201103653; maintainer wiring
        # directive 2026-07-15): the duplicate / joinability contract gates the PRODUCTION copy, not only
        # tests. Plan-identified runs are joined via Test-ContinuousCoReviewPlanEvidenceInjectable against the
        # ACTUAL SELECTED VerificationPlan the caller passes - NEVER a plan derived from the evidence itself
        # (self-derivation would validate any smuggled command_id against its own record). When plan-identified
        # evidence exists and NO selected plan is available, every such run is WITHHELD fail-closed as
        # `selected-plan-unavailable`. Non-injectable runs are surfaced in `withheld_runs` (a reviewer-visible
        # refusal, never a silent drop); attempt-superseded HISTORY stays visible (finding f2: a failure never
        # becomes missing evidence). Identity-less self-evidence runs are not plan evidence and pass through
        # under the envelope + embedded-digest checks the lookup already enforced. Fail-closed if the join
        # validator is missing.
        if (($record.PSObject.Properties.Name -contains 'runs') -and ($null -ne $record.runs)) {
            $idRuns = @(@($record.runs) | Where-Object { $null -ne $_ -and (@($_.PSObject.Properties.Name) -contains 'command_id') -and -not [string]::IsNullOrWhiteSpace([string]$_.command_id) })
            if ($idRuns.Count -gt 0) {
                $joined = $null
                if ($null -ne $Plan) {
                    if (-not (Get-Command -Name 'Test-ContinuousCoReviewPlanEvidenceInjectable' -ErrorAction SilentlyContinue)) {
                        $vpc = Join-Path $PSScriptRoot 'verification-plan-contract.ps1'
                        if (Test-Path -LiteralPath $vpc -PathType Leaf) { . $vpc }
                    }
                    if (-not (Get-Command -Name 'Test-ContinuousCoReviewPlanEvidenceInjectable' -ErrorAction SilentlyContinue)) {
                        [Console]::Error.WriteLine('[co-review] WARN IMPLEMENTER_EVIDENCE_NOT_INJECTED plan-evidence join validator unavailable; refusing to inject unjoined plan runs.')
                        return $false
                    }
                    $joined = @(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence $idRuns -Plan $Plan -CurrentDigest $DigestTreeId)
                }
                $withheld = @()
                $keepRuns = New-Object System.Collections.Generic.List[object]
                foreach ($r in @($record.runs)) {
                    if ($null -eq $r) { continue }
                    $rid = if (@($r.PSObject.Properties.Name) -contains 'command_id') { [string]$r.command_id } else { '' }
                    if ([string]::IsNullOrWhiteSpace($rid)) { $keepRuns.Add($r) | Out-Null; continue }
                    if ($null -eq $Plan) {
                        # plan-identified evidence with NO selected plan: fail-closed, surfaced.
                        $withheld += [pscustomobject]@{ command_id = $rid; classification = 'selected-plan-unavailable' }
                        continue
                    }
                    $jidx = [Array]::IndexOf($idRuns, $r)
                    $cls = if ($jidx -ge 0 -and $jidx -lt $joined.Count) { [string]$joined[$jidx].classification } else { 'unjoined' }
                    if ($cls -in @('exact-digest-command-joined', 'attempt-superseded-history')) { $keepRuns.Add($r) | Out-Null }
                    else { $withheld += [pscustomobject]@{ command_id = $rid; classification = $cls } }
                }
                if (@($withheld).Count -gt 0) {
                    foreach ($w in $withheld) { [Console]::Error.WriteLine(("[co-review] WARN PLAN_RUN_WITHHELD command_id '{0}' ({1}) - refused at the injection boundary (FR-048 join)." -f $w.command_id, $w.classification)) }
                    $record = $record | Select-Object *   # shallow copy: the origin-side durable record stays untouched
                    $record.runs = $keepRuns.ToArray()
                    $record | Add-Member -NotePropertyName 'withheld_runs' -NotePropertyValue @($withheld) -Force
                    $hasSuitesLeft = ($record.PSObject.Properties.Name -contains 'suites') -and (@($record.suites).Count -gt 0)
                    if ((@($record.runs).Count -eq 0) -and (-not $hasSuitesLeft)) { return $false }
                }
            }
        }
        # FR-009/SC-002 ORIGIN-PATH HYGIENE (review finding f5, run 20260714T190233598): the injected COPY is
        # reviewer-visible, so every origin-absolute path in it (working_directory, argument vectors like a
        # docker volume mount, artifact paths) is relativized to '<project>' against the governance AND git
        # origin roots - identity hygiene plus no origin route for the confined reviewer. The origin-side
        # durable record is untouched. Fail-closed: if the relativizer is unavailable, inject NOTHING (a leak
        # is worse than absent evidence).
        if (-not (Get-Command -Name 'ConvertTo-ContinuousCoReviewOriginRelativized' -ErrorAction SilentlyContinue)) {
            $wr = Join-Path $PSScriptRoot 'worktree-reviewer.ps1'
            if (Test-Path -LiteralPath $wr -PathType Leaf) { . $wr }
        }
        if (-not (Get-Command -Name 'ConvertTo-ContinuousCoReviewOriginRelativized' -ErrorAction SilentlyContinue)) {
            [Console]::Error.WriteLine('[co-review] WARN IMPLEMENTER_EVIDENCE_NOT_INJECTED origin-relativizer unavailable; refusing to inject an unscrubbed evidence copy.')
            return $false
        }
        $originRoots = @((Resolve-Path -LiteralPath $RepoRoot).Path)
        try {
            $gitTop = (& git -C $RepoRoot rev-parse --show-toplevel 2>$null)
            if (-not [string]::IsNullOrWhiteSpace([string]$gitTop)) { $originRoots += ([string]$gitTop) }
        }
        catch { $null = $_ }
        $scrubbed = ConvertTo-ContinuousCoReviewOriginRelativized -Content ($record | ConvertTo-Json -Depth 8) -OriginRoots $originRoots
        [System.IO.File]::WriteAllText((Join-Path $reviewDir 'implementer-evidence.json'), $scrubbed)
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
    if ($props -contains 'counts') {
        # PRESENCE-based null rejection (review finding f3, run 20260714T180554025): the schema types counts
        # as an OBJECT when present - a present-but-null counts is schema-INVALID, never treated as absent
        # (which would grant structured-result standing to a malformed artifact).
        if ($null -eq $Object.counts) { return @{ valid = $false; reason = 'counts-null-not-object' } }
        if ($Object.counts -isnot [System.Management.Automation.PSCustomObject]) { return @{ valid = $false; reason = 'counts-not-an-object' } }
        $cprops = @($Object.counts.PSObject.Properties.Name)
        if (@($cprops | Where-Object { $_ -notin @('passed', 'failed', 'skipped') }).Count -gt 0) { return @{ valid = $false; reason = 'unknown-count' } }
        $counts = [ordered]@{}
        foreach ($k in @('passed', 'failed', 'skipped')) {
            if ($cprops -contains $k) {
                $v = $Object.counts.$k
                # BEYOND the authoritative maximum (review finding f1, run 20260714T193411985): PS parses a
                # JSON integer past Int64.MaxValue as BigInteger. The contract now carries an EXPLICIT
                # maximum (Int64.MaxValue) so every schema-valid count is representable + serializable
                # verbatim; a beyond-range count is a NAMED contract violation, never a confusing
                # non-integer rejection and never a lossy narrowing.
                if ($v -is [System.Numerics.BigInteger]) {
                    if ($v -lt 0) { return @{ valid = $false; reason = "negative-count:$k" } }
                    return @{ valid = $false; reason = "count-exceeds-authoritative-maximum:$k" }
                }
                if (($v -isnot [int]) -and ($v -isnot [long])) { return @{ valid = $false; reason = "non-integer-count:$k" } }
                if ([long]$v -lt 0) { return @{ valid = $false; reason = "negative-count:$k" } }
                # PRESERVE the schema-valid range verbatim (finding f3, run 20260714T180554025): a count
                # beyond Int32 is recorded as-is - narrowing to [int] threw instead of recording.
                $counts[$k] = [long]$v
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

# ============================ HARNESS / CORE SEAM (harness-purity refactor 2026-07-15) ============================
# The recorded-run runner was one function doing seven jobs (spawn, bounded drain, result lifecycle, artifact
# digesting, identity tagging, record assembly, persistence) - high cyclomatic complexity + harness (process/IO)
# welded to the CORE honesty semantics, so the observation semantics could not be unit-tested without spawning a
# real process. It is now split:
#   - Invoke-ContinuousCoReviewBoundedProcess : the HARNESS primitive - launch + bounded-memory concurrent drain,
#     returns RAW observed facts (exit/timing + byte counts/hashes/bounded raw tails). No honesty semantics.
#   - Get-ContinuousCoReviewOutputMetaFromFacts + New-ContinuousCoReviewRunRecordObject : the PURE core - map raw
#     facts to the durable record (redaction, disclosure labeling, command_succeeded, classification, identity).
#     No process, no clock, no filesystem - fully unit-testable over synthetic facts.
#   - Invoke-ContinuousCoReviewRecordedRun : thin glue - digest-bind, stale-result guard, call the harness, read
#     + validate the result file, digest artifacts, call the pure assembler, persist. The observable behavior is
#     byte-for-byte the pre-refactor behavior (the existing recorded-run + plan-runner suites are the safety net;
#     new pure-core suites cover the assembler without spawning).

function Invoke-ContinuousCoReviewBoundedProcess {
    <#
        HARNESS PRIMITIVE (no honesty semantics): launch a process and drain BOTH pipes with BOUNDED MEMORY -
        a running UTF-8 byte count, an incremental SHA-256 (surrogate-pair carry keeps whole-stream hash
        fidelity), and a bounded shift-buffer holding only the last TailBytes bytes (everything past the bounds
        is read + DISCARDED so the child never blocks). Kills the whole process tree on the deadline. Returns
        RAW observed facts only: { exit_code; timed_out; duration_seconds; stdout=@{byte_count;sha256;truncated;
        raw_tail}; stderr=@{...} }. The raw_tail is UNREDACTED bounded diagnostic text - redaction/disclosure
        labeling is a CORE concern applied downstream, never here. FAILS LOUD only on process START failure.
    #>
    param(
        [Parameter(Mandatory)][string]$Executable,
        [string[]]$Arguments = @(),
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [int]$TimeoutSeconds = 0,
        [System.Collections.IDictionary]$ChildEnvironment,
        [int]$TailBytes = 0
    )
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Executable
    foreach ($a in @($Arguments)) { [void]$psi.ArgumentList.Add([string]$a) }
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    # CHILD-ENVIRONMENT ALLOWLIST with EXECUTION semantics (review finding f2, run 20260714T123137002): a
    # CONSTRUCTED environment CLEARS the inherited ambient first, so every unlisted ambient value (hence every
    # ambient secret) is structurally ABSENT from the child. Absent parameter -> the child inherits the ambient
    # environment unchanged (the legacy T018 self-evidence behavior).
    if ($PSBoundParameters.ContainsKey('ChildEnvironment') -and $null -ne $ChildEnvironment) {
        $psi.Environment.Clear()
        foreach ($k in @($ChildEnvironment.Keys)) {
            if ([string]::IsNullOrWhiteSpace([string]$k)) { continue }
            $psi.Environment[[string]$k] = [string]$ChildEnvironment[$k]
        }
    }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = [System.Diagnostics.Process]::new(); $proc.StartInfo = $psi
    try { [void]$proc.Start() } catch { throw "bounded-process: failed to START '$Executable' (fail-loud): $($_.Exception.Message)" }

    $utf8 = [System.Text.Encoding]::UTF8
    $cap = Get-ContinuousCoReviewMaxOutputTailBytes
    $tailKeep = if ($TailBytes -gt 0) { [Math]::Min($TailBytes, $cap) } else { 0 }   # ENGINE CAP: no unbounded retained tail.
    $bufOut = [char[]]::new(8192); $bufErr = [char[]]::new(8192)
    $outEof = $false; $errEof = $false
    $bytesOut = 0L; $bytesErr = 0L
    $hashOut = [System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::SHA256)
    $hashErr = [System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::SHA256)
    # Direct assignment, NEVER via an if-expression: a byte[] returned from an if/scriptblock ENUMERATES into a
    # boxed Object[], and every later [byte[]] binding then converts it to a FRESH COPY - the ring writes land in
    # the copy and the tail reads back as NULs (the enumeration trap the contract's RawProp accessor documents).
    $tailOut = $null; $tailErr = $null
    if ($tailKeep -gt 0) { $tailOut = [byte[]]::new($tailKeep); $tailErr = [byte[]]::new($tailKeep) }
    $tailOutFill = 0; $tailErrFill = 0
    $carryOut = ''; $carryErr = ''
    $appendTail = {
        param([byte[]]$Ring, [int]$Fill, [byte[]]$Chunk)
        $c = $Ring.Length
        if ($Chunk.Length -ge $c) { [System.Buffer]::BlockCopy($Chunk, $Chunk.Length - $c, $Ring, 0, $c); return $c }
        $overflow = ($Fill + $Chunk.Length) - $c
        if ($overflow -gt 0) { [System.Buffer]::BlockCopy($Ring, $overflow, $Ring, 0, $Fill - $overflow); $Fill -= $overflow }
        [System.Buffer]::BlockCopy($Chunk, 0, $Ring, $Fill, $Chunk.Length)
        return $Fill + $Chunk.Length
    }
    $tOut = $proc.StandardOutput.ReadAsync($bufOut, 0, $bufOut.Length)
    $tErr = $proc.StandardError.ReadAsync($bufErr, 0, $bufErr.Length)
    $timedOut = $false
    $deadlineMs = if ($TimeoutSeconds -gt 0) { [long]$TimeoutSeconds * 1000 } else { [long]::MaxValue }
    while (-not ($outEof -and $errEof)) {
        if ($sw.ElapsedMilliseconds -ge $deadlineMs) { $timedOut = $true; break }
        $pending = @(); if (-not $outEof) { $pending += $tOut }; if (-not $errEof) { $pending += $tErr }
        $slice = if ($deadlineMs -eq [long]::MaxValue) { 250 } else { [int][Math]::Max(1, [Math]::Min(250, $deadlineMs - $sw.ElapsedMilliseconds)) }
        $idx = [System.Threading.Tasks.Task]::WaitAny([System.Threading.Tasks.Task[]]$pending, $slice)
        if ($idx -lt 0) { continue }
        $done = $pending[$idx]
        if (-not $outEof -and $done -eq $tOut) {
            $n = 0; try { $n = $tOut.GetAwaiter().GetResult() } catch { $n = 0 }
            if ($n -le 0) { $outEof = $true }
            else {
                $text = $carryOut + [string]::new($bufOut, 0, $n); $carryOut = ''
                if ($text.Length -gt 0 -and [char]::IsHighSurrogate($text[$text.Length - 1])) { $carryOut = [string]$text[$text.Length - 1]; $text = $text.Substring(0, $text.Length - 1) }
                if ($text.Length -gt 0) {
                    $chunk = $utf8.GetBytes($text); $bytesOut += $chunk.Length; $hashOut.AppendData($chunk)
                    if ($tailKeep -gt 0) { $tailOutFill = & $appendTail $tailOut $tailOutFill $chunk }
                }
                $tOut = $proc.StandardOutput.ReadAsync($bufOut, 0, $bufOut.Length)
            }
        }
        elseif (-not $errEof -and $done -eq $tErr) {
            $n = 0; try { $n = $tErr.GetAwaiter().GetResult() } catch { $n = 0 }
            if ($n -le 0) { $errEof = $true }
            else {
                $text = $carryErr + [string]::new($bufErr, 0, $n); $carryErr = ''
                if ($text.Length -gt 0 -and [char]::IsHighSurrogate($text[$text.Length - 1])) { $carryErr = [string]$text[$text.Length - 1]; $text = $text.Substring(0, $text.Length - 1) }
                if ($text.Length -gt 0) {
                    $chunk = $utf8.GetBytes($text); $bytesErr += $chunk.Length; $hashErr.AppendData($chunk)
                    if ($tailKeep -gt 0) { $tailErrFill = & $appendTail $tailErr $tailErrFill $chunk }
                }
                $tErr = $proc.StandardError.ReadAsync($bufErr, 0, $bufErr.Length)
            }
        }
    }
    if ($timedOut) {
        try { $proc.Kill($true) } catch { $null = $_ }   # ENTIRE process tree
        try { [void]$proc.WaitForExit(5000) } catch { $null = $_ }
    }
    else { $proc.WaitForExit() }
    $sw.Stop()
    # Flush any dangling high surrogate (stream ended mid-pair) - encodes as the replacement bytes, exactly like
    # the old whole-string GetBytes of a lone surrogate.
    foreach ($flush in @(@($carryOut, $true), @($carryErr, $false))) {
        $c = [string]$flush[0]
        if (-not [string]::IsNullOrEmpty($c)) {
            $chunk = $utf8.GetBytes($c)
            if ([bool]$flush[1]) { $bytesOut += $chunk.Length; $hashOut.AppendData($chunk); if ($tailKeep -gt 0) { $tailOutFill = & $appendTail $tailOut $tailOutFill $chunk } }
            else { $bytesErr += $chunk.Length; $hashErr.AppendData($chunk); if ($tailKeep -gt 0) { $tailErrFill = & $appendTail $tailErr $tailErrFill $chunk } }
        }
    }
    $shaOut = [System.BitConverter]::ToString($hashOut.GetHashAndReset()).Replace('-', '').ToLowerInvariant(); $hashOut.Dispose()
    $shaErr = [System.BitConverter]::ToString($hashErr.GetHashAndReset()).Replace('-', '').ToLowerInvariant(); $hashErr.Dispose()
    $exitCode = if ($timedOut) { $null } else { try { [int]$proc.ExitCode } catch { $null } }
    try { $proc.Dispose() } catch { $null = $_ }
    $rawTailOut = if ($tailKeep -gt 0 -and $tailOutFill -gt 0) { $utf8.GetString($tailOut, 0, $tailOutFill) } else { '' }
    $rawTailErr = if ($tailKeep -gt 0 -and $tailErrFill -gt 0) { $utf8.GetString($tailErr, 0, $tailErrFill) } else { '' }
    return [pscustomobject]@{
        exit_code        = $exitCode
        timed_out        = $timedOut
        duration_seconds = [math]::Round($sw.Elapsed.TotalSeconds, 3)
        stdout           = [pscustomobject]@{ byte_count = $bytesOut; sha256 = $shaOut; truncated = ($bytesOut -gt $tailKeep); raw_tail = $rawTailOut }
        stderr           = [pscustomobject]@{ byte_count = $bytesErr; sha256 = $shaErr; truncated = ($bytesErr -gt $tailKeep); raw_tail = $rawTailErr }
    }
}

function Get-ContinuousCoReviewOutputMetaFromFacts {
    # PURE: raw stream facts (byte_count/sha256/raw_tail from the harness) + the effective tail policy -> the
    # persisted stdout/stderr meta. TailBytes<=0 SUPPRESSES text (count/hash only); >0 keeps a REDACTED bounded
    # tail. Same shape + semantics as Get-ContinuousCoReviewBoundedOutputMeta, over already-bounded facts.
    param([Parameter(Mandatory)]$Facts, [int]$TailBytes = 0, [string]$TailDisclosureLabel = 'bounded-redacted-tail')
    $byteCount = [long]$Facts.byte_count
    if ($TailBytes -le 0) {
        return [ordered]@{ byte_count = $byteCount; sha256 = [string]$Facts.sha256; truncated = ($byteCount -gt 0); truncated_tail = ''; tail_disclosure = 'suppressed' }
    }
    return [ordered]@{ byte_count = $byteCount; sha256 = [string]$Facts.sha256; truncated = [bool]$Facts.truncated; truncated_tail = (Get-ContinuousCoReviewRedactedOutputText -Text ([string]$Facts.raw_tail)); tail_disclosure = $TailDisclosureLabel }
}

function New-ContinuousCoReviewRunRecordObject {
    <#
        PURE record ASSEMBLER (no process, no clock, no filesystem): given the harness-observed facts + the
        run identity + the validated-result outcome + the disclosure decision, build the durable record object.
        This is the CORE honesty logic - command_succeeded, missing-diagnostics surfacing, required-result
        classification, the auditable disclosure record, and plan identity - made unit-testable over synthetic
        facts. Returns the ordered record hashtable (the caller persists it).
    #>
    param(
        [Parameter(Mandatory)][string]$Executable,
        [AllowNull()][string]$DeclaredExecutable,
        [string[]]$Arguments = @(),
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$TreeId,
        [Parameter(Mandatory)][datetime]$StartedAt,
        [Parameter(Mandatory)][datetime]$Now,
        [Parameter(Mandatory)]$Process,   # the Invoke-...BoundedProcess result
        [int]$EffectiveTailBytes = 0,
        [string]$TailLabel = 'bounded-redacted-tail',
        [AllowNull()]$TestResult = $null,
        [AllowNull()]$RequiredResultFailure = $null,   # UNTYPED: a [string] default of $null coerces to '' and '' -ne $null is TRUE (a false required-result failure). Untyped keeps a real $null.
        [object[]]$Artifacts = @(),
        [AllowNull()]$DisclosureInfo = $null,   # applied only when non-null
        [AllowNull()][string]$CommandId = $null,
        [AllowNull()]$Provenance = $null,
        [AllowNull()][string[]]$EnvRefs = $null
    )
    $exitCode = $Process.exit_code
    $timedOut = [bool]$Process.timed_out
    $hasRequiredFailure = -not [string]::IsNullOrEmpty([string]$RequiredResultFailure)
    $commandSucceeded = ((-not $timedOut) -and ($null -ne $exitCode) -and ([int]$exitCode -eq 0))
    if ($hasRequiredFailure) { $commandSucceeded = $false }   # a required-result miss is NEVER success

    $commandBlock = [ordered]@{ executable = $Executable; arguments = @($Arguments); working_directory = $WorkingDirectory }
    if (-not [string]::IsNullOrWhiteSpace($DeclaredExecutable) -and ([string]$DeclaredExecutable -ne [string]$Executable)) {
        $commandBlock['declared_executable'] = [string]$DeclaredExecutable
    }
    $entry = [ordered]@{
        command                 = $commandBlock
        reviewed_digest_tree_id = $TreeId
        started_at              = $StartedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        ended_at                = $StartedAt.AddSeconds([double]$Process.duration_seconds).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        duration_seconds        = [math]::Round([double]$Process.duration_seconds, 3)
        exit_code               = $exitCode
        timed_out               = $timedOut
        command_succeeded       = $commandSucceeded
        stdout_meta             = (Get-ContinuousCoReviewOutputMetaFromFacts -Facts $Process.stdout -TailBytes $EffectiveTailBytes -TailDisclosureLabel $TailLabel)
        stderr_meta             = (Get-ContinuousCoReviewOutputMetaFromFacts -Facts $Process.stderr -TailBytes $EffectiveTailBytes -TailDisclosureLabel $TailLabel)
        artifacts               = @($Artifacts)
        counts_available        = ($null -ne $TestResult)
        test_result             = $TestResult
        recorded_at             = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
    # HONEST MISSING-DIAGNOSTICS (maintainer decision 2026-07-14): a FAILED command whose output text was
    # suppressed states it cannot be diagnosed from this record alone - the failure stays a failure; missing
    # diagnostics NEVER become a clean result.
    if ((-not $commandSucceeded) -and ($EffectiveTailBytes -le 0)) { $entry['failure_diagnostics'] = 'insufficient-without-disclosure' }
    # REQUIRED-RESULT FAILURE CLASSIFICATION on the REAL record (finding f1, run 20260714T215545754).
    if ($hasRequiredFailure) {
        $entry['classification'] = 'required-result-missing-or-invalid'
        $entry['failure_reason'] = [string]$RequiredResultFailure
    }
    # AUDITABLE DISCLOSURE RECORD (durable BY DESIGN - the audit trail the reviewer reads; labeled sensitive).
    if ($null -ne $DisclosureInfo) {
        $entry['diagnostic_disclosure'] = [ordered]@{
            authorized_by         = [string]$DisclosureInfo.authorized_by
            reason                = [string]$DisclosureInfo.disclosure_reason
            command_id            = [string]$DisclosureInfo.command_id
            disclosed_at          = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            tail_bytes            = [int]$DisclosureInfo.max_tail_bytes
            potentially_sensitive = $true
            durability            = 'durable-digest-bound'
        }
    }
    # PLAN IDENTITY persisted INTO the durable record (review finding f5, run 20260714T123137002): the T019
    # join binds on command_id + reviewed digest, so identity/provenance/env_ref NAMES must survive serialization.
    if (-not [string]::IsNullOrWhiteSpace($CommandId)) { $entry['command_id'] = [string]$CommandId }
    if ($null -ne $Provenance) { $entry['provenance'] = $Provenance }
    if ($null -ne $EnvRefs) { $entry['env_refs'] = @(@($EnvRefs) | Where-Object { $_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_) }) }
    return $entry
}

function Invoke-ContinuousCoReviewRecordedRun {
    <#
        The universal, language/framework-NEUTRAL recorded-run runner (FR-015). Thin glue over the HARNESS
        (Invoke-...BoundedProcess) and the PURE CORE (New-...RunRecordObject): binds evidence to the exact
        reviewed-tree digest, guards the stale result, executes, reads + validates the run-produced
        SpecrewTestResult, digests artifacts, assembles the record, and persists it. No console parsing; no
        caller counts; FAIL-LOUD on digest-unavailable, start failure, a REQUIRED-but-missing/invalid result,
        or a recording failure.
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
    # as this run's. A rich claim must come from a result THIS run produced. DELETION IS VERIFIED (review finding
    # f1, run 20260714T182921446): an undeletable stale result (lock/permission) previously survived the silent
    # delete and could be accepted as this run's rich result - now the run REFUSES to execute (fail-loud, zero
    # side effects) rather than risk a stale claim.
    $resultFull = $null
    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) {
        $resultFull = if ([System.IO.Path]::IsPathRooted($ResultPath)) { $ResultPath } else { Join-Path $cwd $ResultPath }
        if (Test-Path -LiteralPath $resultFull -PathType Leaf) {
            Remove-Item -LiteralPath $resultFull -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $resultFull -PathType Leaf) {
                throw "recorded-run: a PRE-EXISTING result at '$ResultPath' could not be deleted before the run - refusing to execute (an undeletable stale result could be read as this run's; fail-loud, FR-015)."
            }
        }
    }

    # EXECUTE via the HARNESS primitive (process-tree contained via Kill(entireProcessTree) on timeout; the
    # bounded-memory concurrent drain lives entirely in Invoke-...BoundedProcess). It returns RAW observed
    # facts; all honesty semantics (redaction, disclosure, classification) are applied by the pure assembler.
    $startedAt = $Now
    $procParams = @{ Executable = $Executable; Arguments = @($Arguments); WorkingDirectory = $cwd; TimeoutSeconds = $TimeoutSeconds; TailBytes = $effectiveTailBytes }
    if ($PSBoundParameters.ContainsKey('ChildEnvironment') -and $null -ne $ChildEnvironment) { $procParams.ChildEnvironment = $ChildEnvironment }
    $procFacts = try { Invoke-ContinuousCoReviewBoundedProcess @procParams } catch { throw "recorded-run: $($_.Exception.Message)" }

    # OPTIONAL SpecrewTestResult - rich counts ONLY from a schema-valid result THIS run produced.
    # OBSERVED-FACTS PRESERVATION (review finding f1, run 20260714T215545754): a REQUIRED-result miss/invalid
    # no longer throws away the process observation - the failure is NOTED here, the FULL real record
    # (timestamps, duration, exit code, output byte counts/hashes) is built and PERSISTED with
    # command_succeeded=$false + the required-result classification, and THEN the fail-loud throw fires.
    # FR-015's directly-observed facts and FR-048's record-every-attempt both survive the failure.
    $testResult = $null
    $requiredResultFailure = $null
    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) {
        if (-not (Test-Path -LiteralPath $resultFull -PathType Leaf)) {
            if ($RequireResult) { $requiredResultFailure = "recorded-run: a SpecrewTestResult was REQUIRED at '$ResultPath' but the command produced none - failing loudly (FR-015), never inferring counts from console output." }
        }
        else {
            $obj = $null
            try { $obj = Get-Content -LiteralPath $resultFull -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $obj = $null }
            # TRANSIENT RESULT LIFECYCLE (review finding f3, run 20260714T182921446): the reviewed digest is
            # bound BEFORE execution, so a result file LEFT in the tree flips the current digest the moment the
            # evidence is recorded - orphaning the very evidence it carried. The result file is a TRANSPORT: its
            # validated content persists in the durable record; the file itself is deleted right after reading
            # (valid OR invalid), restoring the tree to the digest the evidence certifies. A cleanup failure
            # only WARNS - the digest then flips and this evidence honestly orphans itself (a digest mismatch is
            # never wrong evidence), rather than failing a completed run.
            try { Remove-Item -LiteralPath $resultFull -Force -ErrorAction Stop }
            catch { [Console]::Error.WriteLine("[co-review] WARN RESULT_FILE_NOT_CLEANED '$ResultPath' could not be deleted after reading; the reviewed digest will differ from the bound digest and this evidence orphans itself.") }
            $v = Test-ContinuousCoReviewSpecrewTestResult -Object $obj
            if (-not $v.valid) {
                if ($RequireResult) { $requiredResultFailure = "recorded-run: the SpecrewTestResult at '$ResultPath' is INVALID ($($v.reason)) - failing loudly rather than degrading to a richer pass claim (FR-015)." }
            }
            else { $testResult = [ordered]@{ result = $v.result; counts = $v.counts; source = 'specrew-test-result' } }
        }
    }

    # OUTPUT-ARTIFACT digests (I/O; the pure assembler receives the finished digest records).
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

    # ASSEMBLE the durable record via the PURE core (no process/clock/filesystem in there).
    $recordParams = @{
        Executable = $Executable; Arguments = @($Arguments); WorkingDirectory = $cwd; TreeId = $treeId
        StartedAt = $startedAt; Now = $Now; Process = $procFacts
        EffectiveTailBytes = $effectiveTailBytes; TailLabel = $tailLabel
        TestResult = $testResult; RequiredResultFailure = $requiredResultFailure; Artifacts = @($artifacts)
    }
    if ($disclosureApplies) { $recordParams.DisclosureInfo = $disclosureInfo }
    if ($PSBoundParameters.ContainsKey('DeclaredExecutable')) { $recordParams.DeclaredExecutable = $DeclaredExecutable }
    if ($PSBoundParameters.ContainsKey('CommandId') -and -not [string]::IsNullOrWhiteSpace($CommandId)) { $recordParams.CommandId = $CommandId }
    if ($PSBoundParameters.ContainsKey('Provenance') -and $null -ne $Provenance) { $recordParams.Provenance = $Provenance }
    if ($PSBoundParameters.ContainsKey('EnvRefs') -and $null -ne $EnvRefs) { $recordParams.EnvRefs = $EnvRefs }
    $entry = New-ContinuousCoReviewRunRecordObject @recordParams
    $commandSucceeded = [bool]$entry.command_succeeded
    if ($PSBoundParameters.ContainsKey('Provenance') -and $null -ne $Provenance) { $entry['provenance'] = $Provenance }
    if ($PSBoundParameters.ContainsKey('EnvRefs') -and $null -ne $EnvRefs) { $entry['env_refs'] = @(@($EnvRefs) | Where-Object { $_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_) }) }

    # WRITE bound to the digest, into the digest-keyed store's `runs` array. FAIL LOUD if recording fails.
    try {
        Save-ContinuousCoReviewRunRecord -RepoRoot $resolved -TreeId $treeId -Entry ([pscustomobject]$entry) -CommandId $CommandId -Executable $Executable -Arguments @($Arguments) -WorkingDirectory $cwd -RecordedAt ([string]$entry.recorded_at)
    }
    catch {
        throw "recorded-run: evidence RECORDING failed for '$Executable' bound to ${treeId} (fail-loud, FR-015): $($_.Exception.Message)"
    }
    # FAIL LOUD on a required-result miss - AFTER the real observed record persisted (finding f1).
    if ($null -ne $requiredResultFailure) {
        throw ($requiredResultFailure + ' (the full observed process record was persisted with command_succeeded=false)')
    }
    return [pscustomobject]$entry
}

function Save-ContinuousCoReviewRunRecord {
    <#
        Persist ONE run/attempt entry into the digest-keyed store's `runs` array. SHARED by the real
        recorded-run writer AND the synthetic verification-failure records (review finding f4, run
        20260714T182921446): FR-048's record-every-attempt means the DURABLE store, not only an in-memory
        return - an unpersisted attempted-failure is missing reviewer evidence. IDENTITY (finding f5 run
        20260714T123137002 + finding f2 run 20260714T201103653): command_id when present is the plan JOIN
        key and (command_id, attempt) is the durable identity - same-id re-runs APPEND with an increasing
        attempt sequence so a failure is never erased by a later success; two distinct ids with the same
        invocation both persist. Identity-less runs (implementer self-evidence) keep latest-run-wins on
        executable + arguments + working_directory. Throws on write failure.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$TreeId,
        [Parameter(Mandatory)]$Entry,
        [AllowNull()][AllowEmptyString()][string]$CommandId,
        [Parameter(Mandatory)][string]$Executable,
        [string[]]$Arguments = @(),
        [AllowNull()][AllowEmptyString()][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$RecordedAt
    )
    $dir = Get-ContinuousCoReviewTestEvidenceDirectory -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $null = New-Item -ItemType Directory -Path $dir -Force }
    $path = Join-Path $dir ($TreeId + '.json')
    $record = $null
    if (Test-Path -LiteralPath $path -PathType Leaf) { try { $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } catch { $record = $null } }
    if ($null -eq $record) { $record = [pscustomobject]@{ schema_version = '1.0'; reviewed_digest_tree_id = $TreeId; recorded_at = $RecordedAt } }
    $existingRuns = @()
    if (($record.PSObject.Properties.Name -contains 'runs') -and ($null -ne $record.runs)) { $existingRuns = @($record.runs) }
    if (-not [string]::IsNullOrWhiteSpace($CommandId)) {
        # ATTEMPT HISTORY for plan-identified runs (review finding f2, run 20260714T201103653): a re-run of the
        # SAME command_id at the same digest APPENDS with a monotonically increasing per-id `attempt` sequence -
        # it never replaces the prior record, so an earlier non-zero/timeout/required-result FAILURE can never
        # be erased by a later success (FR-048: every attempt recorded; a failure never becomes missing
        # evidence). command_id stays the plan JOIN key; (command_id, attempt) is the durable identity, and the
        # join treats the LATEST attempt as authoritative with earlier attempts surfaced as history.
        $maxAttempt = 0
        foreach ($er in $existingRuns) {
            if ($null -eq $er) { continue }
            $erProps = @($er.PSObject.Properties.Name)
            if (($erProps -contains 'command_id') -and ([string]$er.command_id -ceq $CommandId)) {
                $erAttempt = if ($erProps -contains 'attempt') { [int]$er.attempt } else { 1 }
                if ($erAttempt -gt $maxAttempt) { $maxAttempt = $erAttempt }
            }
        }
        $entryObj = [pscustomobject]$Entry
        $entryObj | Add-Member -NotePropertyName 'attempt' -NotePropertyValue ($maxAttempt + 1) -Force
        $record | Add-Member -NotePropertyName 'runs' -NotePropertyValue @(@($existingRuns | Where-Object { $null -ne $_ }) + @($entryObj)) -Force
    }
    else {
        # Identity-less runs (the implementer's OWN dev-loop self-evidence, e.g. the recorded registry runs)
        # keep the T111-style LATEST-RUN-WINS replacement on the invocation key - they are not plan attempts,
        # and the freshest run for this exact tree is the record's meaning.
        $entryKey = 'invocation:' + $Executable + ' ' + (@($Arguments) -join ' ') + '|wd:' + [string]$WorkingDirectory
        $kept = @($existingRuns | Where-Object {
                if ($null -eq $_) { return $false }
                $exId = ''
                if (@($_.PSObject.Properties | ForEach-Object { $_.Name }) -contains 'command_id') { $exId = [string]$_.command_id }
                if (-not [string]::IsNullOrWhiteSpace($exId)) { return $true }   # plan attempts are never displaced by an identity-less run
                $exWd = ''
                try { $exWd = [string]$_.command.working_directory } catch { $exWd = '' }
                $exKey = 'invocation:' + [string]$_.command.executable + ' ' + (@($_.command.arguments) -join ' ') + '|wd:' + $exWd
                return ($exKey -ne $entryKey)
            })
        $record | Add-Member -NotePropertyName 'runs' -NotePropertyValue @(@($kept) + @([pscustomobject]$Entry)) -Force
    }
    $record | Add-Member -NotePropertyName 'reviewed_digest_tree_id' -NotePropertyValue $TreeId -Force
    $record | Add-Member -NotePropertyName 'recorded_at' -NotePropertyValue $RecordedAt -Force
    [System.IO.File]::WriteAllText($path, ($record | ConvertTo-Json -Depth 12))
}
