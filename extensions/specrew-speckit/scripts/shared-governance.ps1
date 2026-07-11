Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ProjectPath {
    # Resolve a project path argument against PowerShell's current location rather than the
    # .NET process CurrentDirectory, which on Windows often stays at the shell startup dir
    # (e.g. $HOME) even after Set-Location/cd. Without this, [System.IO.Path]::GetFullPath('.')
    # returns the wrong absolute path and entry-point scripts falsely report "Missing config.yml".
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    $cwd = (Get-Location).Path
    return [System.IO.Path]::GetFullPath((Join-Path -Path $cwd -ChildPath $Path))
}

function Get-SpecrewSupportedStateSchemas {
    return @('v1', 'v2')
}

function Get-SpecrewStateSchemaVersion {
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$State,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ($null -eq $State -or -not $State.Contains('schema') -or [string]::IsNullOrWhiteSpace([string]$State['schema'])) {
        Write-Debug "schema-implied-v0 for $Path"
        return 'v0'
    }

    $schema = [string]$State['schema']
    if ($schema -notin (Get-SpecrewSupportedStateSchemas)) {
        throw "Unsupported schema '$schema' in '$Path'. Supported schemas: v0 (implied), $((Get-SpecrewSupportedStateSchemas) -join ', ')."
    }

    return $schema
}

function Test-IsUnsupportedSpecrewSchemaError {
    param([AllowNull()][System.Management.Automation.ErrorRecord]$ErrorRecord)

    return $null -ne $ErrorRecord -and
        $null -ne $ErrorRecord.Exception -and
        $ErrorRecord.Exception.Message -like "Unsupported schema '*"
}

function Get-SpecrewValidatorSummaryPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    return Join-Path (Resolve-ProjectPath -Path $ProjectRoot) '.specrew\last-validator-summary.json'
}

function Write-SpecrewValidatorSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Command,

        [int]$SoftWarnings = 0,
        [int]$MediumWarnings = 0,
        [int]$HardWarnings = 0,

        [AllowNull()]
        [string]$RecordedAt,

        [int]$DurationMs = 0
    )

    $summaryPath = Get-SpecrewValidatorSummaryPath -ProjectRoot $ProjectRoot
    $effectiveRecordedAt = if ([string]::IsNullOrWhiteSpace($RecordedAt)) {
        (Get-Date).ToUniversalTime().ToString('o')
    }
    else {
        $RecordedAt
    }

    $summary = [ordered]@{
        schema      = 'v1'
        warnings    = [ordered]@{
            total  = ($SoftWarnings + $MediumWarnings + $HardWarnings)
            soft   = $SoftWarnings
            medium = $MediumWarnings
            hard   = $HardWarnings
        }
        command     = $Command
        duration_ms = $DurationMs
        recorded_at = $effectiveRecordedAt
    }

    Write-Utf8FileAtomic -Path $summaryPath -Content (([pscustomobject]$summary | ConvertTo-Json -Depth 6) + [Environment]::NewLine)
    return $summaryPath
}

function Invoke-WithFileLock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [int]$RetryCount = 50,
        [int]$RetryDelayMilliseconds = 100
    )

    $resolvedPath = Resolve-ProjectPath -Path $Path
    $directory = Split-Path -Parent $resolvedPath
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $lockPath = "$resolvedPath.lock"
    $lockStream = $null
    for ($attempt = 0; $attempt -lt $RetryCount; $attempt++) {
        try {
            $lockStream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
            break
        }
        catch [System.IO.IOException] {
            if ($attempt -ge ($RetryCount - 1)) {
                throw "Could not acquire file lock for '$resolvedPath'."
            }

            Start-Sleep -Milliseconds $RetryDelayMilliseconds
        }
    }

    try {
        & $ScriptBlock
    }
    catch {
        throw "Locked update failed for '$resolvedPath': $($_.Exception.Message)"
    }
    finally {
        if ($null -ne $lockStream) {
            $lockStream.Dispose()
        }

        if (Test-Path -LiteralPath $lockPath -PathType Leaf) {
            Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Remove-OrphanedAtomicWriteArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowNull()]
        [string]$TempPath
    )

    $resolvedPath = Resolve-ProjectPath -Path $Path
    $lockPath = "$resolvedPath.lock"

    if (-not [string]::IsNullOrWhiteSpace($TempPath) -and (Test-Path -LiteralPath $TempPath -PathType Leaf)) {
        Remove-Item -LiteralPath $TempPath -Force -ErrorAction SilentlyContinue
    }

    $directory = Split-Path -Parent $resolvedPath
    $fileName = Split-Path -Leaf $resolvedPath
    if (-not [string]::IsNullOrWhiteSpace($directory) -and (Test-Path -LiteralPath $directory -PathType Container)) {
        Get-ChildItem -LiteralPath $directory -Filter "$fileName.*.tmp" -File -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path -LiteralPath $lockPath -PathType Leaf) {
        Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
    }
}

function Write-Utf8FileAtomic {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    $resolvedPath = Resolve-ProjectPath -Path $Path
    $directory = Split-Path -Parent $resolvedPath
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $tempPath = '{0}.{1}.tmp' -f $resolvedPath, ([guid]::NewGuid().ToString('N'))
    try {
        [System.IO.File]::WriteAllText($tempPath, $Content, [System.Text.UTF8Encoding]::new($false))
        if (-not (Test-Path -LiteralPath $tempPath -PathType Leaf)) {
            throw "Atomic write did not create the temp file '$tempPath'."
        }

        Move-Item -LiteralPath $tempPath -Destination $resolvedPath -Force -ErrorAction Stop
    }
    catch {
        Remove-OrphanedAtomicWriteArtifacts -Path $resolvedPath -TempPath $tempPath
        throw "Atomic write to '$resolvedPath' failed: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Update-LockedFileContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Transform
    )

    Invoke-WithFileLock -Path $Path -ScriptBlock {
        $currentContent = if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        }
        else {
            ''
        }

        $updatedContent = & $Transform $currentContent
        if ($null -eq $updatedContent) {
            throw "Transform for '$Path' returned null."
        }

        Write-Utf8FileAtomic -Path $Path -Content $updatedContent
        return $updatedContent
    }
}

function Get-DecisionsLedgerPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    return Join-Path (Resolve-ProjectPath -Path $ProjectRoot) '.squad\decisions.md'
}

function Get-ValidatorCachePath {
    # Proposal 086 Pillar 1: returns the path to the validator memoization cache file.
    # Lives under .specrew/.cache/ (gitignored, per-developer).
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $cacheDir = Join-Path -Path $resolvedProjectRoot -ChildPath '.specrew\.cache'
    return Join-Path -Path $cacheDir -ChildPath 'validator-cache.json'
}

function Get-SpecrewPrReviewResolutionPath {
    # Proposal 089: returns the conventional path for the PR review resolution
    # artifact for a given iteration.
    # Example: specs/030-validator-speedup/iterations/001/pr-review-resolution.md
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationPath
    )
    return Join-Path -Path $IterationPath -ChildPath 'pr-review-resolution.md'
}

function Get-SpecrewAutomatedReviewOptIn {
    # Feature 182 (FR-019): read the project's review_gate.automated_review OPT-IN from
    # .specrew/repository-governance.yml. Forge-neutral default: OFF — human review is always-available;
    # an automated reviewer is active ONLY when the project explicitly opted in. Returns
    # @{ Enabled = <bool>; ProviderSuggestion = <string|null> }. Fail-open to disabled.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    $govPath = Join-Path -Path (Resolve-ProjectPath -Path $ProjectRoot) -ChildPath '.specrew' -AdditionalChildPath 'repository-governance.yml'
    $result = @{ Enabled = $false; ProviderSuggestion = $null }
    if (-not (Test-Path -LiteralPath $govPath -PathType Leaf)) { return $result }
    $inAutomated = $false
    foreach ($line in (Get-Content -LiteralPath $govPath -ErrorAction SilentlyContinue)) {
        if ($line -match '^\s{4}automated_review:\s*(#.*)?$') { $inAutomated = $true; continue }
        if ($inAutomated -and $line -match '^\s{0,4}\S') { $inAutomated = $false }   # left the block (sibling/parent key)
        if ($inAutomated -and $line -match '^\s{6,}enabled:\s*(?<v>\S+)') {
            $result.Enabled = ([string]$Matches['v'] -match '^(?i:true)$')
        }
        if ($inAutomated -and $line -match '^\s{6,}provider_suggestion:\s*(?<v>\S+)') {
            $result.ProviderSuggestion = ([string]$Matches['v']).Trim()
        }
    }
    return $result
}

function Test-HostProvidesAutomatedPrReview {
    # Proposal 089 + Feature 182 (FR-019): reports the project's automated-PR-review reviewer, which is
    # OPT-IN and forge-neutral. Specrew NEVER bakes in a forge or a reviewer: an automated reviewer is
    # active ONLY when (a) the project opted in via review_gate.automated_review.enabled AND (b) the
    # configured provider's capability is actually present. v1 ships the GitHub adapter's Copilot
    # suggestion; other forges report Active = $false until a verified adapter is synthesized (honest —
    # no baked-in reviewer). Returns @{ Active, Host, Reviewer }.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    $resolvedRoot = Resolve-ProjectPath -Path $ProjectRoot

    # Opt-in gate (FR-019): no governance / not opted in -> human review only (never a baked-in reviewer).
    $optIn = Get-SpecrewAutomatedReviewOptIn -ProjectRoot $resolvedRoot
    if (-not $optIn.Enabled) {
        return @{ Active = $false }
    }
    $provider = if (-not [string]::IsNullOrWhiteSpace($optIn.ProviderSuggestion)) { $optIn.ProviderSuggestion } else { 'copilot' }

    $ghAvailable = $false
    try {
        $ghCmd = Get-Command -Name 'gh' -ErrorAction Stop
        if ($null -ne $ghCmd) { $ghAvailable = $true }
    }
    catch { $ghAvailable = $false }

    $remoteIsGitHub = $false
    try {
        Push-Location -LiteralPath $resolvedRoot
        $remoteUrl = (& git remote get-url origin 2>$null) -join ''
        if (-not [string]::IsNullOrWhiteSpace($remoteUrl) -and $remoteUrl -match 'github\.com') {
            $remoteIsGitHub = $true
        }
    }
    catch { }
    finally {
        Pop-Location -ErrorAction SilentlyContinue
    }

    # Opted in + the GitHub adapter's capability is present -> the configured reviewer (GitHub: Copilot).
    if ($ghAvailable -and $remoteIsGitHub) {
        return @{
            Active   = $true
            Host     = 'github'
            Reviewer = "$provider-pull-request-reviewer"
        }
    }
    # Opted in, but the forge capability isn't present (no gh / non-GitHub forge) -> honest inactive.
    return @{ Active = $false }
}

function Get-SpecrewCommandLogPath {
    # Proposal 086 Pillar 5: returns the path to the command invocation log.
    # Lives under .specrew/.cache/ (gitignored, per-developer; same parent as
    # validator memoization cache from Pillar 1).
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $cacheDir = Join-Path -Path $resolvedProjectRoot -ChildPath '.specrew\.cache'
    return Join-Path -Path $cacheDir -ChildPath 'last-commands.log'
}

function Add-SpecrewCommandInvocation {
    # Proposal 086 Pillar 5: appends {target_hash, code_hash, invoked_at, command}
    # to last-commands.log (JSON Lines). FIFO eviction at 20 entries. File-locked
    # for concurrent safety across parallel subprocesses.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string]$TargetHash,

        [Parameter(Mandatory = $true)]
        [string]$CodeHash
    )
    $logPath = Get-SpecrewCommandLogPath -ProjectRoot $ProjectRoot
    $logDir = Split-Path -Parent $logPath
    if (-not (Test-Path -LiteralPath $logDir -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $logDir -Force
    }

    Invoke-WithFileLock -Path $logPath -ScriptBlock {
        $entries = New-Object System.Collections.Generic.List[hashtable]
        if (Test-Path -LiteralPath $logPath -PathType Leaf) {
            try {
                foreach ($line in (Get-Content -LiteralPath $logPath -Encoding UTF8)) {
                    if ([string]::IsNullOrWhiteSpace($line)) { continue }
                    try {
                        $entry = $line | ConvertFrom-Json -AsHashtable -Depth 4
                        if ($null -ne $entry) { $null = $entries.Add($entry) }
                    }
                    catch { continue }
                }
            }
            catch {
                # Corrupt log file — start fresh; non-fatal per FR-005
                $entries.Clear()
            }
        }

        $newEntry = @{
            command     = $Command
            target_hash = $TargetHash
            code_hash   = $CodeHash
            invoked_at  = (Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
        }
        $null = $entries.Add($newEntry)

        # FIFO eviction at 20 entries
        while ($entries.Count -gt 20) {
            $entries.RemoveAt(0)
        }

        $serialized = ($entries | ForEach-Object { ConvertTo-Json -InputObject $_ -Depth 4 -Compress }) -join [Environment]::NewLine
        Set-Content -LiteralPath $logPath -Value $serialized -Encoding UTF8
    }
}

function Get-SpecrewRecentCommandInvocations {
    # Proposal 086 Pillar 5: reads last-commands.log and returns the N most-recent
    # entries (default 5). Returns empty array if file missing or corrupt.
    # Per Copilot review on PR #695: read inside Invoke-WithFileLock so concurrent
    # writers (Set-Content rewrites the whole file) can't observe partial state.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [int]$Last = 5
    )
    $logPath = Get-SpecrewCommandLogPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) { return ,@() }

    $entries = New-Object System.Collections.Generic.List[hashtable]
    Invoke-WithFileLock -Path $logPath -ScriptBlock {
        try {
            foreach ($line in (Get-Content -LiteralPath $logPath -Encoding UTF8)) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                try {
                    $entry = $line | ConvertFrom-Json -AsHashtable -Depth 4
                    if ($null -ne $entry) { $null = $entries.Add($entry) }
                }
                catch { continue }
            }
        }
        catch {
            $entries.Clear()
        }
    }

    # Leading comma prevents PowerShell auto-unrolling when there's a single entry
    if ($entries.Count -le $Last) { return ,@($entries.ToArray()) }
    return ,@($entries.GetRange($entries.Count - $Last, $Last).ToArray())
}

function Test-SpecrewCommandRepetition {
    # Proposal 086 Pillar 5: counts CONSECUTIVE most-recent invocations matching
    # the given (target_hash, code_hash). Returns 0 if streak broken (different
    # hashes appeared between this call and the most recent same-hash invocation).
    # Use to detect "user ran validator N times against unchanged code."
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetHash,

        [Parameter(Mandatory = $true)]
        [string]$CodeHash
    )
    $recent = Get-SpecrewRecentCommandInvocations -ProjectRoot $ProjectRoot -Last 10
    if ($recent.Count -eq 0) { return 0 }
    # Walk from most-recent backwards; count matches until first mismatch.
    $count = 0
    for ($i = $recent.Count - 1; $i -ge 0; $i--) {
        $e = $recent[$i]
        if ([string]$e.target_hash -eq $TargetHash -and [string]$e.code_hash -eq $CodeHash) {
            $count++
        }
        else {
            break
        }
    }
    return $count
}

function Get-SpecrewClosedIterationIndexPath {
    # Proposal 085: returns the path to the closed-iteration index file.
    # Lives under .specrew/ and is COMMITTED to the repo (not gitignored).
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    return Join-Path -Path $resolvedProjectRoot -ChildPath '.specrew\closed-iterations.yml'
}

function Get-SpecrewClosedIterationIndex {
    # Proposal 085: reads .specrew/closed-iterations.yml; returns a hashtable
    # keyed by "<feature>/<iteration>" with values @{ closed_at = '<ISO8601>' }.
    # Returns an empty hashtable when the file is missing or empty.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    $indexPath = Get-SpecrewClosedIterationIndexPath -ProjectRoot $ProjectRoot
    $result = @{}
    if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
        return $result
    }
    $content = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($content)) {
        return $result
    }
    # Lightweight YAML parser: lines like
    #   - feature: 034
    #     iteration: 001
    #     closed_at: 2026-05-22T07:05:00Z
    $current = $null
    foreach ($rawLine in ($content -split "`r?`n")) {
        $line = $rawLine.TrimEnd()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) { continue }
        if ($line -match '^\s*-\s+feature:\s*(.+?)\s*$') {
            if ($null -ne $current -and $current.ContainsKey('feature') -and $current.ContainsKey('iteration')) {
                $key = "$($current['feature'])/$($current['iteration'])"
                $result[$key] = @{ closed_at = $current['closed_at'] }
            }
            $current = @{ feature = $Matches[1].Trim('"').Trim("'") }
            continue
        }
        if ($null -eq $current) { continue }
        if ($line -match '^\s*iteration:\s*(.+?)\s*$') {
            $current['iteration'] = $Matches[1].Trim('"').Trim("'")
            continue
        }
        if ($line -match '^\s*closed_at:\s*(.+?)\s*$') {
            $current['closed_at'] = $Matches[1].Trim('"').Trim("'")
            continue
        }
    }
    if ($null -ne $current -and $current.ContainsKey('feature') -and $current.ContainsKey('iteration')) {
        $key = "$($current['feature'])/$($current['iteration'])"
        $result[$key] = @{ closed_at = $current['closed_at'] }
    }
    return $result
}

function Normalize-SpecrewIterationNumber {
    param([AllowNull()][string]$IterationNumber)

    if ($null -eq $IterationNumber) { return $null }
    $trimmed = $IterationNumber.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) { return $trimmed }
    if ($trimmed -match '^\d+$') {
        return ([int]$trimmed).ToString('000')
    }
    return $trimmed
}

function Test-SpecrewIterationClosed {
    # Proposal 085: returns $true if the (feature, iteration) tuple is recorded
    # in the closed-iteration index.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Feature,

        [Parameter(Mandatory = $true)]
        [string]$Iteration
    )
    $normalizedIteration = Normalize-SpecrewIterationNumber -IterationNumber $Iteration
    $index = Get-SpecrewClosedIterationIndex -ProjectRoot $ProjectRoot
    $key = "$Feature/$normalizedIteration"
    return $index.ContainsKey($key)
}

function Add-SpecrewClosedIterationEntry {
    # Proposal 085: appends a {feature, iteration, closed_at} entry to the index.
    # Idempotent: if an entry already exists, no-op. Uses Invoke-WithFileLock to
    # serialize concurrent writes (multi-dev safety).
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Feature,

        [Parameter(Mandatory = $true)]
        [string]$Iteration,

        [string]$ClosedAt
    )
    $normalizedIteration = Normalize-SpecrewIterationNumber -IterationNumber $Iteration
    if ([string]::IsNullOrWhiteSpace($ClosedAt)) {
        $ClosedAt = (Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')
    }
    $indexPath = Get-SpecrewClosedIterationIndexPath -ProjectRoot $ProjectRoot
    $indexDir = Split-Path -Parent $indexPath
    if (-not (Test-Path -LiteralPath $indexDir -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $indexDir -Force
    }

    Invoke-WithFileLock -Path $indexPath -ScriptBlock {
        $existing = Get-SpecrewClosedIterationIndex -ProjectRoot $ProjectRoot
        $key = "$Feature/$normalizedIteration"
        if ($existing.ContainsKey($key)) {
            return
        }
        $newEntryLines = @(
            "  - feature: $Feature",
            "    iteration: $normalizedIteration",
            "    closed_at: $ClosedAt"
        )
        $needsHeader = -not (Test-Path -LiteralPath $indexPath -PathType Leaf) -or [string]::IsNullOrWhiteSpace((Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8))
        if ($needsHeader) {
            $header = @(
                '# Specrew closed-iteration index (Proposal 085).',
                '# Append-only. Append at iteration-closeout boundary via Add-SpecrewClosedIterationEntry.',
                '# Regenerate from state.md walk via: validate-governance.ps1 -RebuildClosedIndex',
                'closed:'
            )
            $combined = ($header + $newEntryLines) -join [Environment]::NewLine
            Set-Content -LiteralPath $indexPath -Value $combined -Encoding UTF8
        }
        else {
            Add-Content -LiteralPath $indexPath -Value ($newEntryLines -join [Environment]::NewLine) -Encoding UTF8
        }
    }
}

function Get-SpecrewClosedIterationFromStateFile {
    # Proposal 085: heuristic detector — given a state.md path, returns
    # @{ feature, iteration, closed_at } if the iteration is closed, else $null.
    # Closed signals: phase=feature-closeout|iteration-closeout, or status=complete,
    # or body contains 'RETRO COMPLETE'.
    param(
        [Parameter(Mandatory = $true)]
        [string]$StatePath
    )
    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) { return $null }
    $content = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8
    $isClosed = $false
    if ($content -match 'Current Phase[*\s]*:\s*(feature-closeout|iteration-closeout|complete|closed)') { $isClosed = $true }
    elseif ($content -match 'RETRO COMPLETE') { $isClosed = $true }
    elseif ($content -match '\bStatus[*\s]*:\s*complete\b') { $isClosed = $true }
    elseif ($content -match 'iteration[\s-]*closed\b') { $isClosed = $true }
    elseif ($content -match 'Retrospective complete') { $isClosed = $true }
    if (-not $isClosed) { return $null }

    # Path pattern: specs/<feature>/iterations/<iteration>/state.md
    # Use a portable separator pattern. Resolve to absolute paths to be safe.
    $normalized = $StatePath -replace '\\', '/'
    if ($normalized -notmatch 'specs/([^/]+)/iterations/([^/]+)/state\.md$') { return $null }
    $feature = $Matches[1]
    $iteration = Normalize-SpecrewIterationNumber -IterationNumber $Matches[2]
    # Strip leading numeric prefix from feature (e.g., "034-validator-memoization" → keep full slug)
    return @{ feature = $feature; iteration = $iteration; closed_at = (Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ') }
}

function Get-ValidatorCodeHash {
    # Proposal 086 Pillar 1: SHA256 hash of validator scripts + governance config
    # files. Per Copilot review on PR #594: governance config files (e.g.,
    # .specrew/iteration-config.yml) are included because rules invoked by
    # validator depend on them. Without folding them into the hash, changing
    # those files would yield stale cache hits.
    #
    # Validator scripts must exist (return $null otherwise). Governance config
    # files are optional — missing files contribute the literal 'missing' marker,
    # which is still deterministic and shifts when the file appears/disappears.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )
    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $hashSources = @(
        (Join-Path -Path $resolvedProjectRoot -ChildPath 'extensions\specrew-speckit\scripts\validate-governance.ps1'),
        (Join-Path -Path $resolvedProjectRoot -ChildPath 'extensions\specrew-speckit\scripts\shared-governance.ps1'),
        (Join-Path -Path $resolvedProjectRoot -ChildPath '.specrew\iteration-config.yml'),
        (Join-Path -Path $resolvedProjectRoot -ChildPath '.specrew\config.yml'),
        (Join-Path -Path $resolvedProjectRoot -ChildPath '.specrew\constitution.md'),
        (Join-Path -Path $resolvedProjectRoot -ChildPath '.specrew\role-assignments.yml'),
        (Join-Path -Path $resolvedProjectRoot -ChildPath '.specrew\roadmap.yml'),
        (Join-Path -Path $resolvedProjectRoot -ChildPath '.squad\identity\wisdom.md')
    )

    $validatorPath = $hashSources[0]
    $sharedPath = $hashSources[1]
    if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $sharedPath -PathType Leaf)) {
        return $null
    }

    $componentHashes = New-Object System.Collections.Generic.List[string]
    foreach ($source in $hashSources) {
        if (Test-Path -LiteralPath $source -PathType Leaf) {
            $null = $componentHashes.Add((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash)
        }
        else {
            $null = $componentHashes.Add('missing')
        }
    }
    $combinedHashInput = $componentHashes -join ':'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($combinedHashInput)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
        return -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
    }
    finally {
        $sha.Dispose()
    }
}

function Get-ValidatorCacheKey {
    # Proposal 086 Pillar 1: computes the cache key for a given iteration path.
    # Key = SHA256(iteration content hash + validator code hash). Iteration content
    # hash is composed from SHA256 of every regular file under the iteration
    # directory. Validator code hash invalidates the whole cache when scripts
    # change, so we fold it into the per-iteration key for transparency.
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationPath,

        [Parameter(Mandatory = $true)]
        [string]$ValidatorCodeHash
    )

    if (-not (Test-Path -LiteralPath $IterationPath -PathType Container)) {
        return $null
    }

    $files = @(Get-ChildItem -LiteralPath $IterationPath -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName)
    if ($files.Count -eq 0) {
        $contentHash = 'empty'
    }
    else {
        $perFileHashes = New-Object System.Collections.Generic.List[string]
        foreach ($file in $files) {
            try {
                $fileHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
                $relPath = $file.FullName.Substring($IterationPath.Length).TrimStart('\','/')
                $null = $perFileHashes.Add(("{0}:{1}" -f $relPath, $fileHash))
            }
            catch {
                # Skip unreadable files
            }
        }
        $combined = ($perFileHashes -join "`n")
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($combined)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hashBytes = $sha.ComputeHash($bytes)
            $contentHash = -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
        }
        finally {
            $sha.Dispose()
        }
    }

    $keyInput = "$contentHash`:$ValidatorCodeHash"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($keyInput)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
        return -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
    }
    finally {
        $sha.Dispose()
    }
}

function Get-ValidatorCacheEntry {
    # Proposal 086 Pillar 1: returns the cached entry for the given key, or $null
    # if absent. The entry shape is { errors: @(...), validated_at: '...' }.
    #
    # Per Copilot review on PR #594: this function is READ-ONLY. It does NOT
    # update last_access_at or rewrite the cache file. Concurrent reads from
    # parallel validator runs would corrupt the cache if we wrote on read.
    # LRU eviction bookkeeping uses validated_at (write timestamp) on Set; that
    # gives us "least-recently-validated" semantics which is functionally
    # equivalent for our use case (we re-validate cache misses, so "validated"
    # tracks usage).
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$CacheKey
    )

    $cachePath = Get-ValidatorCachePath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $cachePath -PathType Leaf)) {
        return $null
    }

    try {
        $cache = Get-Content -LiteralPath $cachePath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 10
    }
    catch {
        return $null
    }

    if ($null -eq $cache -or -not $cache.ContainsKey('entries')) {
        return $null
    }

    if (-not $cache['entries'].ContainsKey($CacheKey)) {
        return $null
    }

    return $cache['entries'][$CacheKey]
}

function Set-ValidatorCacheEntry {
    # Proposal 086 Pillar 1: writes an entry to the cache file with LRU eviction
    # at 500 entries. Creates .specrew/.cache/ if missing.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$CacheKey,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Errors,

        [Parameter(Mandatory = $true)]
        [string]$ValidatorCodeHash
    )

    $cachePath = Get-ValidatorCachePath -ProjectRoot $ProjectRoot
    $cacheDir = Split-Path -Parent $cachePath
    if (-not (Test-Path -LiteralPath $cacheDir -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $cacheDir -Force
    }

    # Proposal 084: file lock protects concurrent writes from parallel subprocesses.
    # Read → mutate → write happens atomically inside the lock so no entries get lost.
    # Reuses the existing Invoke-WithFileLock helper (defined earlier in this file).
    Invoke-WithFileLock -Path $cachePath -ScriptBlock {
        $cache = $null
        if (Test-Path -LiteralPath $cachePath -PathType Leaf) {
            try {
                $cache = Get-Content -LiteralPath $cachePath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 10
            }
            catch {
                $cache = $null
            }
        }
        if ($null -eq $cache) {
            $cache = @{
                schema             = 'v1'
                validator_code_hash = $ValidatorCodeHash
                entries            = @{}
            }
        }

        if (-not $cache.ContainsKey('validator_code_hash') -or $cache['validator_code_hash'] -ne $ValidatorCodeHash) {
            $cache = @{
                schema             = 'v1'
                validator_code_hash = $ValidatorCodeHash
                entries            = @{}
            }
        }

        $now = (Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
        $cache['entries'][$CacheKey] = @{
            errors       = @($Errors)
            validated_at = $now
        }

        # LRU eviction at 500 entries (validated_at write timestamp as LRU key per Copilot review PR #594)
        if ($cache['entries'].Keys.Count -gt 500) {
            $sortedKeys = $cache['entries'].GetEnumerator() | Sort-Object { $_.Value['validated_at'] } | Select-Object -ExpandProperty Key
            $excess = $cache['entries'].Keys.Count - 500
            for ($i = 0; $i -lt $excess; $i++) {
                $null = $cache['entries'].Remove($sortedKeys[$i])
            }
        }

        try {
            ConvertTo-Json -InputObject $cache -Depth 10 | Set-Content -LiteralPath $cachePath -Encoding UTF8
        }
        catch {
            # Cache write failure is non-fatal — validation continues
        }
    }
}

function Get-SpecrewCanonicalBoundaryTypes {
    # Canonical Specrew boundary types per scripts/internal/sync-boundary-state.ps1
    # ValidateSet. Used by Test-SessionStateBoundaryCanonical (Proposal 090) to
    # detect non-canonical strings like 'feature-closed' or 'iteration-closed'
    # that the Crew has been writing into state files when bypassing the canonical
    # Invoke-SpecrewBoundaryStateSync script.
    return @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')
}

function Get-SpecrewClosureBoundaryTypes {
    # Subset of canonical boundary types that mark feature closure (terminal/inactive
    # state). When session_state_active=true is combined with any of these, the
    # state files are in a contradictory state and the canonical sync was bypassed.
    # Note: 'iteration-closeout' is NOT in this set because the FEATURE remains
    # active across iteration closeouts (only feature-closeout sets active=false
    # per sync-boundary-state.ps1 line 253).
    return @('feature-closeout')
}

function Get-SpecrewBoundaryOrder {
    return @(Get-SpecrewCanonicalBoundaryTypes)
}

function Get-SpecrewPendingBoundaryCrossing {
    # Derive the ONE boundary crossing the human can authorize next from the authoritative cursor state.
    # `intake` is marker-only: it names the pre-specify side of the first rendered verdict marker, but it is not
    # persisted as a canonical lifecycle boundary.
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [string]$LastAuthorizedBoundary,

        [AllowNull()]
        [string]$WorkingBoundary
    )

    $result = [pscustomobject]@{
        HasPendingVerdict         = $false
        LastAuthorizedBoundary    = $null
        WorkingBoundary           = $null
        PendingFromBoundary       = $null
        PendingToBoundary         = $null
        PendingFromMarkerBoundary = $null
        PendingToMarkerBoundary   = $null
        IsFirstBoundary           = $false
        IsMultiBoundaryGap        = $false
    }

    try {
        if ([string]::IsNullOrWhiteSpace($WorkingBoundary)) { return $result }

        $order = @(Get-SpecrewBoundaryOrder)
        $workingCanonical = Normalize-SpecrewCanonicalBoundaryType -Boundary $WorkingBoundary
        $lastAuthCanonical = if ([string]::IsNullOrWhiteSpace($LastAuthorizedBoundary)) { $null } else { Normalize-SpecrewCanonicalBoundaryType -Boundary $LastAuthorizedBoundary }

        $result.WorkingBoundary = $workingCanonical
        $result.LastAuthorizedBoundary = $lastAuthCanonical

        $workingIdx = [Array]::IndexOf($order, $workingCanonical)
        $authIdx = if ([string]::IsNullOrWhiteSpace($lastAuthCanonical)) { -1 } else { [Array]::IndexOf($order, $lastAuthCanonical) }
        if ($workingIdx -lt 0) { return $result }

        # ITERATION CYCLE RESET (FR-004 of the hardening feature, field-found 2026-07-11): the canonical order is
        # linear but iterations LOOP - after an authorized `iteration-closeout`, the next
        # iteration re-enters at an earlier-phase boundary (plan/tasks/...). The old
        # `workingIdx -le authIdx` guard read that as "backward", so NO pending artifact was
        # written for any new-cycle crossing and the verdict capture refused with
        # MARKER_CURSOR_MISMATCH (two live instances: this feature's own iteration-002 plan and
        # before-implement). When the cursor sits at iteration-closeout and the working
        # boundary is an earlier-phase crossing, the pending ask is the new cycle's earliest
        # un-authorized boundary, from-side iteration-closeout.
        $planIdx = [Array]::IndexOf($order, 'plan')
        $isCycleReset = ($lastAuthCanonical -eq 'iteration-closeout' -and $workingIdx -le $authIdx -and $workingIdx -ge $planIdx)
        if ($workingIdx -le $authIdx -and -not $isCycleReset) { return $result }

        if ($isCycleReset) {
            $result.HasPendingVerdict = $true
            $result.PendingFromBoundary = 'iteration-closeout'
            $result.PendingToBoundary = $order[$planIdx]
            $result.PendingFromMarkerBoundary = 'iteration-closeout'
            $result.PendingToMarkerBoundary = $order[$planIdx]
            $result.IsFirstBoundary = $false
            $result.IsMultiBoundaryGap = ($workingIdx -gt $planIdx)
            return $result
        }

        $toIdx = $authIdx + 1
        if ($toIdx -lt 0 -or $toIdx -ge $order.Count) { return $result }

        $fromBoundary = if ($authIdx -ge 0) { $order[$authIdx] } else { $null }
        $fromMarkerBoundary = if ($authIdx -ge 0) { $order[$authIdx] } else { 'intake' }
        $toBoundary = $order[$toIdx]

        $result.HasPendingVerdict = $true
        $result.PendingFromBoundary = $fromBoundary
        $result.PendingToBoundary = $toBoundary
        $result.PendingFromMarkerBoundary = $fromMarkerBoundary
        $result.PendingToMarkerBoundary = $toBoundary
        $result.IsFirstBoundary = ($authIdx -lt 0)
        $result.IsMultiBoundaryGap = (($workingIdx - $authIdx) -gt 1)
    }
    catch { $null = $_ }

    return $result
}

function Normalize-SpecrewCanonicalBoundaryType {
    param([AllowNull()][string]$Boundary)

    if ([string]::IsNullOrWhiteSpace($Boundary)) {
        return $null
    }

    $normalized = $Boundary.Trim().ToLowerInvariant()
    $normalized = $normalized -replace '\s+', '-'
    $normalized = $normalized -replace '[^a-z0-9\-]+', '-'
    $normalized = $normalized.Trim('-')

    switch -Regex ($normalized) {
        '^specify(?:-boundary)?$' { return 'specify' }
        '^clarify(?:-boundary)?$' { return 'clarify' }
        '^plan(?:ning)?(?:-boundary)?$' { return 'plan' }
        '^tasks?(?:-boundary(?:-entry)?)?$' { return 'tasks' }
        '^before-implement(?:-boundary(?:-entry)?)?$' { return 'before-implement' }
        '^implementation(?:-boundary(?:-entry)?)?$' { return 'before-implement' }
        '^review(?:-boundary)?$' { return 'review-signoff' }
        '^review-signoff(?:-boundary)?$' { return 'review-signoff' }
        '^retro(?:spective)?(?:-boundary)?$' { return 'retro' }
        '^iteration-closeout(?:-boundary)?$' { return 'iteration-closeout' }
        '^feature-closeout(?:-boundary)?$' { return 'feature-closeout' }
        default { return $normalized }
    }
}

function Test-SpecrewCanonicalBoundaryType {
    param([AllowNull()][string]$Boundary)

    $normalized = Normalize-SpecrewCanonicalBoundaryType -Boundary $Boundary
    return (-not [string]::IsNullOrWhiteSpace($normalized) -and $normalized -in (Get-SpecrewCanonicalBoundaryTypes))
}

function Resolve-SpecrewCanonicalBoundaryType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Boundary,

        [string]$ParameterName = 'Boundary'
    )

    $normalized = Normalize-SpecrewCanonicalBoundaryType -Boundary $Boundary
    if (-not (Test-SpecrewCanonicalBoundaryType -Boundary $normalized)) {
        throw "$ParameterName value '$Boundary' is not a canonical Specrew boundary. Canonical: $((Get-SpecrewCanonicalBoundaryTypes) -join ', ')."
    }

    return $normalized
}

function Get-SpecrewBoundaryEnforcementRecognizedVerdicts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequestedBoundary
    )

    $canonicalBoundary = Resolve-SpecrewCanonicalBoundaryType -Boundary $RequestedBoundary -ParameterName 'RequestedBoundary'
    return @(
        "approved for $canonicalBoundary-boundary entry"
        "approved for $canonicalBoundary"
        "rejected for $canonicalBoundary"
        'parked'
    )
}

function Get-SpecrewBoundaryEnforcementSnippet {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $normalized = (($Value -replace '\s+', ' ').Trim())
    if ($normalized.Length -le 200) {
        return $normalized
    }

    return $normalized.Substring(0, 200)
}

function Test-SpecrewBoundaryBypassAttemptSnippet {
    param([AllowNull()][string]$Snippet)

    if ([string]::IsNullOrWhiteSpace($Snippet)) {
        return $false
    }

    $normalized = $Snippet.ToLowerInvariant()
    return (
        $normalized -match 'approved\s+for' -or
        $normalized -match '/speckit\.' -or
        $normalized -match '\bcontinue\b' -or
        $normalized -match '\bproceed\b' -or
        $normalized -match '->'
    )
}

function Get-SpecrewStartContextPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    return Join-Path (Resolve-ProjectPath -Path $ProjectRoot) '.specrew\start-context.json'
}

function Get-SpecrewStartContextState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $path = Get-SpecrewStartContextPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return [pscustomobject]@{
            Path    = $path
            Exists  = $false
            Schema  = 'v0'
            Context = [ordered]@{}
        }
    }

    $context = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 24
    return [pscustomobject]@{
        Path    = $path
        Exists  = $true
        Schema  = Get-SpecrewStateSchemaVersion -State $context -Path $path
        Context = $context
    }
}

function Get-SpecrewStartContextBoundary {
    # THE CANONICAL v1/v2-tolerant reader for the ACTIVE boundary in start-context.json. v1 stored it at
    # session_state.boundary_type; the v2 schema migration moved it to boundary_enforcement.last_authorized_
    # boundary (a v2 file has NO session_state). Reading only v1 -> $null on a v2 project -> silent no-op
    # (iter-007 real-host dogfood: the navigator never fired + the handover hollowed). This is the ONE home
    # for that logic. The self-contained hot-path providers (refocus / hook-dispatcher / navigator) cannot
    # load shared-governance, so each carries a THIN local mirror; all are pinned identical to this function
    # by tests/continuous-co-review/unit/boundary-reader-conformance.Tests.ps1 (drift fails CI).
    # Accepts a parsed context (PSCustomObject OR hashtable) or a path. Returns $null when absent/unreadable.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()] $StartContext)
    if ($null -eq $StartContext) { return $null }
    $ctx = $StartContext
    if ($StartContext -is [string]) {
        if (-not (Test-Path -LiteralPath $StartContext -PathType Leaf)) { return $null }
        try { $ctx = Get-Content -LiteralPath $StartContext -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return $null }
    }
    $getp = {
        param($o, $n)
        if ($null -eq $o) { return $null }
        if ($o -is [System.Collections.IDictionary]) { if ($o.Contains($n)) { return $o[$n] } else { return $null } }
        $p = $o.PSObject.Properties[$n]; if ($p) { return $p.Value } else { return $null }
    }
    $b = [string](& $getp (& $getp $ctx 'session_state') 'boundary_type')          # v1
    if (-not [string]::IsNullOrWhiteSpace($b)) { return $b }
    $b = [string](& $getp (& $getp $ctx 'boundary_enforcement') 'last_authorized_boundary')  # v2
    if (-not [string]::IsNullOrWhiteSpace($b)) { return $b }
    return $null
}

function New-SpecrewBoundaryEnforcementState {
    param(
        [AllowNull()]
        [string]$CurrentBoundary,

        [AllowNull()]
        [string]$ProjectRoot
    )

    $normalizedCurrentBoundary = if ([string]::IsNullOrWhiteSpace($CurrentBoundary)) {
        $null
    }
    else {
        Resolve-SpecrewCanonicalBoundaryType -Boundary $CurrentBoundary -ParameterName 'CurrentBoundary'
    }

    return [ordered]@{
        enabled                  = $true
        last_authorized_boundary = $normalizedCurrentBoundary
        pending_next_boundary    = $null
        policy_classes           = Get-SpecrewBoundaryPolicyClassMap -ProjectRoot $ProjectRoot
        verdict_history          = @()
        bypass_history           = @()
    }
}

function Get-SpecrewBoundaryPolicyClassMap {
    param(
        [AllowNull()]
        [string]$ProjectRoot
    )

    $map = [ordered]@{}
    foreach ($boundary in (Get-SpecrewCanonicalBoundaryTypes)) {
        $map[$boundary] = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
            'human-judgment-required'
        }
        else {
            Get-SpecrewBoundaryPolicyClass -ProjectRoot $ProjectRoot -Boundary $boundary
        }
    }

    return $map
}

function Test-SpecrewBoundaryEnforcementStateShape {
    param(
        [AllowNull()]
        [object]$BoundaryEnforcement
    )

    $issues = New-Object System.Collections.Generic.List[string]
    if ($null -eq $BoundaryEnforcement) {
        $issues.Add('boundary_enforcement section is missing.') | Out-Null
        return $issues.ToArray()
    }

    $state = if ($BoundaryEnforcement -is [System.Collections.IDictionary]) {
        $BoundaryEnforcement
    }
    else {
        try {
            $BoundaryEnforcement | ConvertTo-Json -Depth 24 | ConvertFrom-Json -AsHashtable -Depth 24
        }
        catch {
            $issues.Add('boundary_enforcement section is not object-shaped.') | Out-Null
            return $issues.ToArray()
        }
    }

    foreach ($requiredKey in @('enabled', 'last_authorized_boundary', 'pending_next_boundary', 'verdict_history', 'bypass_history')) {
        if (-not $state.Contains($requiredKey)) {
            $issues.Add("boundary_enforcement.$requiredKey is missing.") | Out-Null
        }
    }

    if ($issues.Count -gt 0) {
        return $issues.ToArray()
    }

    if ($state['enabled'] -isnot [bool]) {
        $issues.Add('boundary_enforcement.enabled must be a boolean.') | Out-Null
    }

    foreach ($boundaryField in @('last_authorized_boundary', 'pending_next_boundary')) {
        $value = $state[$boundaryField]
        if ($null -ne $value -and -not [string]::IsNullOrWhiteSpace([string]$value)) {
            $normalized = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$value)
            if ($normalized -notin (Get-SpecrewCanonicalBoundaryTypes)) {
                $issues.Add("boundary_enforcement.$boundaryField value '$value' is not canonical.") | Out-Null
            }
        }
    }

    foreach ($arrayField in @('verdict_history', 'bypass_history')) {
        if ($null -eq $state[$arrayField] -or $state[$arrayField] -is [string]) {
            $issues.Add("boundary_enforcement.$arrayField must be an array.") | Out-Null
        }
    }

    if ($state.Contains('policy_classes')) {
        $policyClasses = $state['policy_classes']
        if ($null -eq $policyClasses -or $policyClasses -is [string]) {
            $issues.Add('boundary_enforcement.policy_classes must be an object.') | Out-Null
        }
        else {
            $policyMap = if ($policyClasses -is [System.Collections.IDictionary]) {
                $policyClasses
            }
            else {
                $policyClasses | ConvertTo-Json -Depth 12 | ConvertFrom-Json -AsHashtable -Depth 12
            }

            foreach ($boundary in (Get-SpecrewCanonicalBoundaryTypes)) {
                if (-not $policyMap.Contains($boundary)) {
                    $issues.Add("boundary_enforcement.policy_classes.$boundary is missing.") | Out-Null
                    continue
                }

                $value = [string]$policyMap[$boundary]
                if ($value -notin @('human-judgment-required', 'future-policy')) {
                    $issues.Add("boundary_enforcement.policy_classes.$boundary value '$value' is not recognized.") | Out-Null
                }
            }
        }
    }

    foreach ($verdict in @($state['verdict_history'])) {
        $verdictMap = if ($verdict -is [System.Collections.IDictionary]) {
            $verdict
        }
        else {
            $verdict | ConvertTo-Json -Depth 12 | ConvertFrom-Json -AsHashtable -Depth 12
        }

        foreach ($field in @('from_boundary', 'to_boundary', 'verdict_text', 'authorizing_human', 'recorded_at', 'auth_commit_hash')) {
            if (-not $verdictMap.Contains($field)) {
                $issues.Add("boundary_enforcement.verdict_history entry is missing '$field'.") | Out-Null
            }
        }

        foreach ($field in @('from_boundary', 'to_boundary')) {
            if ($verdictMap.Contains($field) -and -not [string]::IsNullOrWhiteSpace([string]$verdictMap[$field])) {
                $normalized = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$verdictMap[$field])
                if ($normalized -notin (Get-SpecrewCanonicalBoundaryTypes)) {
                    $issues.Add("boundary_enforcement.verdict_history.$field value '$($verdictMap[$field])' is not canonical.") | Out-Null
                }
            }
        }
    }

    foreach ($bypass in @($state['bypass_history'])) {
        $bypassMap = if ($bypass -is [System.Collections.IDictionary]) {
            $bypass
        }
        else {
            $bypass | ConvertTo-Json -Depth 12 | ConvertFrom-Json -AsHashtable -Depth 12
        }

        foreach ($field in @('session_id', 'reason', 'recorded_at', 'boundary', 'launch_mode', 'agent_response_snippet', 'auth_commit_hash')) {
            if (-not $bypassMap.Contains($field)) {
                $issues.Add("boundary_enforcement.bypass_history entry is missing '$field'.") | Out-Null
            }
        }

        if ($bypassMap.Contains('reason') -and [string]::IsNullOrWhiteSpace([string]$bypassMap['reason'])) {
            $issues.Add('boundary_enforcement.bypass_history.reason cannot be blank.') | Out-Null
        }

        if ($bypassMap.Contains('boundary') -and -not [string]::IsNullOrWhiteSpace([string]$bypassMap['boundary'])) {
            $normalized = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$bypassMap['boundary'])
            if ($normalized -notin (Get-SpecrewCanonicalBoundaryTypes)) {
                $issues.Add("boundary_enforcement.bypass_history.boundary value '$($bypassMap['boundary'])' is not canonical.") | Out-Null
            }
        }

        if ($bypassMap.Contains('agent_response_snippet') -and -not [string]::IsNullOrWhiteSpace([string]$bypassMap['agent_response_snippet']) -and ([string]$bypassMap['agent_response_snippet']).Length -gt 200) {
            $issues.Add('boundary_enforcement.bypass_history.agent_response_snippet must be 200 chars or fewer.') | Out-Null
        }
    }

    return $issues.ToArray()
}

function Get-SpecrewBoundaryEnforcementState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $contextState = Get-SpecrewStartContextState -ProjectRoot $ProjectRoot
    $context = $contextState.Context
    $boundaryEnforcement = if ($context.Contains('boundary_enforcement')) { $context['boundary_enforcement'] } else { $null }
    $shapeIssues = @(Test-SpecrewBoundaryEnforcementStateShape -BoundaryEnforcement $boundaryEnforcement)

    return [pscustomobject]@{
        Path           = $contextState.Path
        Exists         = $contextState.Exists
        Schema         = $contextState.Schema
        Context        = $context
        State          = $boundaryEnforcement
        NeedsMigration = ($contextState.Exists -and $contextState.Schema -in @('v0', 'v1') -and $null -eq $boundaryEnforcement)
        Issues         = $shapeIssues
    }
}

function Get-SpecrewPendingVerdictState {
    # F-174 iteration 011 (T006, FR-027 / decision f174-i011-verdict-authority-stop-hook): is the session's
    # WORKING boundary ahead of the last HUMAN-AUTHORIZED boundary? A committed / in-progress boundary is NOT an
    # authorized one. session_state.boundary_type (the working position) is advanced MECHANICALLY by boundary-sync;
    # boundary_enforcement.last_authorized_boundary is advanced ONLY by a captured human verdict (the Stop/UPS hook
    # or the explicit re-confirm). When working is AHEAD of last-authorized, the crossing(s) between them are
    # AWAITING the human's verdict — the resume + `specrew where` SURFACE this and ask; they never auto-advance.
    # The wording names the crash-window possibility so a human who DID approve knows why they are asked again.
    # Fail-open: any read/parse problem returns "no pending" — it must never FABRICATE a pending state either.
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $result = [pscustomobject]@{
        HasPendingVerdict      = $false
        WorkingBoundary        = $null
        LastAuthorizedBoundary = $null
        PendingFromBoundary    = $null
        PendingToBoundary      = $null
        PendingFromMarkerBoundary = $null
        PendingToMarkerBoundary   = $null
        IsFirstBoundary        = $false
        IsMultiBoundaryGap     = $false
        Message                = $null
    }
    try {
        $enforcement = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot
        if ($null -eq $enforcement -or $null -eq $enforcement.State -or -not [bool]$enforcement.State['enabled']) { return $result }

        $lastAuth = [string]$enforcement.State['last_authorized_boundary']
        $working = $null
        $ctx = $enforcement.Context
        if ($null -ne $ctx -and $ctx.Contains('session_state') -and $null -ne $ctx['session_state']) {
            $ss = $ctx['session_state']
            if ($ss.Contains('boundary_type')) { $working = [string]$ss['boundary_type'] }
        }
        $crossing = Get-SpecrewPendingBoundaryCrossing -LastAuthorizedBoundary $lastAuth -WorkingBoundary $working
        $result.LastAuthorizedBoundary = $crossing.LastAuthorizedBoundary
        $result.WorkingBoundary = $crossing.WorkingBoundary
        $result.PendingFromBoundary = $crossing.PendingFromBoundary
        $result.PendingToBoundary = $crossing.PendingToBoundary
        $result.PendingFromMarkerBoundary = $crossing.PendingFromMarkerBoundary
        $result.PendingToMarkerBoundary = $crossing.PendingToMarkerBoundary
        $result.IsFirstBoundary = [bool]$crossing.IsFirstBoundary
        $result.IsMultiBoundaryGap = [bool]$crossing.IsMultiBoundaryGap
        if ([string]::IsNullOrWhiteSpace($working)) { return $result }

        if ([bool]$crossing.HasPendingVerdict) {
            $result.HasPendingVerdict = $true
            $authLabel = if ([string]::IsNullOrWhiteSpace([string]$crossing.LastAuthorizedBoundary)) { '(none recorded yet)' } else { [string]$crossing.LastAuthorizedBoundary }
            $result.Message = ("AWAITING YOUR VERDICT: '{0}' is committed / in-progress but NOT human-authorized (last authorized: {1}). A committed boundary is not an approved one — the gate advances only when you confirm. Give the boundary verdict to authorize it; if you already approved, the session may have ended before your verdict was captured, so please re-confirm." -f $crossing.WorkingBoundary, $authLabel)
        }
    }
    catch { $null = $_ }
    return $result
}

function Set-SpecrewBoundaryEnforcementState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$BoundaryEnforcement,

        [AllowNull()]
        [System.Collections.IDictionary]$Context
    )

    $contextState = Get-SpecrewStartContextState -ProjectRoot $ProjectRoot
    $effectiveContext = [ordered]@{}
    if ($null -ne $Context) {
        foreach ($entry in $Context.GetEnumerator()) {
            $effectiveContext[$entry.Key] = $entry.Value
        }
    }
    else {
        foreach ($entry in $contextState.Context.GetEnumerator()) {
            $effectiveContext[$entry.Key] = $entry.Value
        }
    }

    $effectiveContext['schema'] = 'v2'
    $policyClasses = if ($BoundaryEnforcement.Contains('policy_classes')) {
        $policyMap = [ordered]@{}
        $sourcePolicy = if ($BoundaryEnforcement['policy_classes'] -is [System.Collections.IDictionary]) {
            $BoundaryEnforcement['policy_classes']
        }
        else {
            $BoundaryEnforcement['policy_classes'] | ConvertTo-Json -Depth 12 | ConvertFrom-Json -AsHashtable -Depth 12
        }

        foreach ($boundary in (Get-SpecrewCanonicalBoundaryTypes)) {
            $policyMap[$boundary] = if ($sourcePolicy.Contains($boundary) -and [string]$sourcePolicy[$boundary] -in @('human-judgment-required', 'future-policy')) {
                [string]$sourcePolicy[$boundary]
            }
            else {
                Get-SpecrewBoundaryPolicyClass -ProjectRoot $ProjectRoot -Boundary $boundary
            }
        }
        $policyMap
    }
    else {
        Get-SpecrewBoundaryPolicyClassMap -ProjectRoot $ProjectRoot
    }

    $effectiveContext['boundary_enforcement'] = [ordered]@{
        enabled                  = [bool]$BoundaryEnforcement['enabled']
        last_authorized_boundary = if ([string]::IsNullOrWhiteSpace([string]$BoundaryEnforcement['last_authorized_boundary'])) { $null } else { Resolve-SpecrewCanonicalBoundaryType -Boundary ([string]$BoundaryEnforcement['last_authorized_boundary']) -ParameterName 'last_authorized_boundary' }
        pending_next_boundary    = if ([string]::IsNullOrWhiteSpace([string]$BoundaryEnforcement['pending_next_boundary'])) { $null } else { Resolve-SpecrewCanonicalBoundaryType -Boundary ([string]$BoundaryEnforcement['pending_next_boundary']) -ParameterName 'pending_next_boundary' }
        policy_classes           = $policyClasses
        verdict_history          = @($BoundaryEnforcement['verdict_history'])
        bypass_history           = @($BoundaryEnforcement['bypass_history'])
    }

    if (-not $effectiveContext.Contains('generated_at_utc') -or [string]::IsNullOrWhiteSpace([string]$effectiveContext['generated_at_utc'])) {
        $effectiveContext['generated_at_utc'] = (Get-Date).ToUniversalTime().ToString('o')
    }

    Write-Utf8FileAtomic -Path $contextState.Path -Content (([pscustomobject]$effectiveContext | ConvertTo-Json -Depth 24) + [Environment]::NewLine)
    return $contextState.Path
}

function Initialize-SpecrewBoundaryEnforcementState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [string]$CurrentBoundary
    )

    $contextState = Get-SpecrewStartContextState -ProjectRoot $ProjectRoot
    $effectiveCurrentBoundary = if (-not [string]::IsNullOrWhiteSpace($CurrentBoundary)) {
        $CurrentBoundary
    }
    elseif ($contextState.Context.Contains('session_state') -and $null -ne $contextState.Context['session_state'] -and -not [string]::IsNullOrWhiteSpace([string]$contextState.Context['session_state']['boundary_type'])) {
        [string]$contextState.Context['session_state']['boundary_type']
    }
    else {
        $null
    }

    $initialized = New-SpecrewBoundaryEnforcementState -CurrentBoundary $effectiveCurrentBoundary -ProjectRoot $ProjectRoot
    Set-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot -BoundaryEnforcement $initialized -Context $contextState.Context | Out-Null
    return $initialized
}

function Get-SpecrewBoundaryPolicyClass {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Boundary
    )

    $defaultPolicy = 'human-judgment-required'
    $canonicalBoundary = Resolve-SpecrewCanonicalBoundaryType -Boundary $Boundary -ParameterName 'Boundary'
    $configPath = Join-Path (Resolve-ProjectPath -Path $ProjectRoot) '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $defaultPolicy
    }

    try {
        $lines = @(Get-Content -LiteralPath $configPath -Encoding UTF8)
    }
    catch {
        return $defaultPolicy
    }

    $inBoundaryEnforcement = $false
    $inPolicyClasses = $false
    foreach ($line in $lines) {
        if ($line -match '^\S') {
            $inPolicyClasses = $false
        }

        if ($line -match '^\s*boundary_enforcement:\s*$') {
            $inBoundaryEnforcement = $true
            $inPolicyClasses = $false
            continue
        }

        if (-not $inBoundaryEnforcement) {
            continue
        }

        if ($line -match '^\s{2}policy_classes:\s*$') {
            $inPolicyClasses = $true
            continue
        }

        if (-not $inPolicyClasses) {
            continue
        }

        if ($line -match ('^\s{4}' + [regex]::Escape($canonicalBoundary) + ':\s*"?(?<value>[^"#]+?)"?\s*$')) {
            $value = $Matches['value'].Trim()
            if ($value -in @('human-judgment-required', 'future-policy')) {
                return $value
            }

            return $defaultPolicy
        }
    }

    return $defaultPolicy
}

function Add-SpecrewBoundaryEnforcementLedgerEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Boundary,

        [Parameter(Mandatory = $true)]
        [ValidateSet('blocked', 'authorized', 'bypassed', 'migration')]
        [string]$EnforcementAction,

        [AllowNull()]
        [string]$CurrentBoundary,

        [AllowNull()]
        [string]$RequestedBoundary,

        [AllowNull()]
        [string]$LaunchMode,

        [AllowNull()]
        [string]$AgentResponseSnippet,

        [AllowNull()]
        [string]$Reason
    )

    $featureRef = $null
    $contextState = Get-SpecrewStartContextState -ProjectRoot $ProjectRoot
    if ($contextState.Context.Contains('session_state') -and $null -ne $contextState.Context['session_state']) {
        $featureRef = [string]$contextState.Context['session_state']['feature_ref']
    }

    $lines = @(
        ('- **Feature**: {0}' -f (Get-DecisionLedgerOptionalValue -Value $featureRef))
        ('- **Boundary Type**: {0}' -f (Resolve-SpecrewCanonicalBoundaryType -Boundary $Boundary -ParameterName 'Boundary'))
        ('- **Current Boundary**: {0}' -f (Get-DecisionLedgerOptionalValue -Value $CurrentBoundary))
        ('- **Requested Boundary**: {0}' -f (Get-DecisionLedgerOptionalValue -Value $RequestedBoundary))
        ('- **Enforcement Action**: {0}' -f $EnforcementAction)
        ('- **Launch Mode**: {0}' -f (Get-DecisionLedgerOptionalValue -Value $LaunchMode))
        ('- **Agent Response Snippet**: {0}' -f (Get-DecisionLedgerOptionalValue -Value (Get-SpecrewBoundaryEnforcementSnippet -Value $AgentResponseSnippet)))
        ('- **Reason**: {0}' -f (Get-DecisionLedgerOptionalValue -Value $Reason))
    )

    Add-DecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title ('Boundary enforcement: {0}' -f (Resolve-SpecrewCanonicalBoundaryType -Boundary $Boundary -ParameterName 'Boundary')) -Lines $lines | Out-Null
}

function Parse-SpecrewBoundaryVerdict {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VerdictText,

        [string[]]$CanonicalBoundaries = @(Get-SpecrewCanonicalBoundaryTypes)
    )

    $trimmedVerdict = if ($null -eq $VerdictText) { '' } else { $VerdictText.Trim() }
    $lowerVerdict = $trimmedVerdict.ToLowerInvariant()

    if ([string]::IsNullOrWhiteSpace($trimmedVerdict)) {
        return [pscustomobject]@{
            Authorized        = $false
            Action            = 'unrecognized'
            Boundaries        = @()
            NormalizedVerdict = $null
            DirectiveSentinel = 'SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED'
            FailureReason     = 'Verdict did not match a recognized boundary authorization shape.'
        }
    }

    if ($lowerVerdict -eq 'parked') {
        return [pscustomobject]@{
            Authorized        = $false
            Action            = 'parked'
            Boundaries        = @()
            NormalizedVerdict = 'parked'
            DirectiveSentinel = 'SPECREW_BOUNDARY_BLOCKED'
            FailureReason     = 'Verdict parked the boundary instead of authorizing it.'
        }
    }

    if ($lowerVerdict -match '^rejected\s+for\s+(.+)$') {
        $boundary = Normalize-SpecrewCanonicalBoundaryType -Boundary $Matches[1]
        if ($boundary -in $CanonicalBoundaries) {
            return [pscustomobject]@{
                Authorized        = $false
                Action            = 'rejected'
                Boundaries        = @($boundary)
                NormalizedVerdict = "rejected for $boundary"
                DirectiveSentinel = 'SPECREW_BOUNDARY_BLOCKED'
                FailureReason     = 'Verdict explicitly rejected the requested boundary.'
            }
        }
    }

    if ($lowerVerdict -match '^approved\s+for\s+(.+)$') {
        $payload = $Matches[1].Trim()
        if ($payload -match '\band\b') {
            $parts = @($payload -split '\s+and\s+' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            $normalizedParts = New-Object System.Collections.Generic.List[string]
            foreach ($part in $parts) {
                $normalizedBoundary = Normalize-SpecrewCanonicalBoundaryType -Boundary $part
                if ($normalizedBoundary -notin $CanonicalBoundaries) {
                    return [pscustomobject]@{
                        Authorized        = $false
                        Action            = 'unrecognized'
                        Boundaries        = @()
                        NormalizedVerdict = $null
                        DirectiveSentinel = 'SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED'
                        FailureReason     = 'Verdict did not match a recognized boundary authorization shape.'
                    }
                }

                if ($normalizedBoundary -notin $normalizedParts) {
                    $normalizedParts.Add($normalizedBoundary) | Out-Null
                }
            }

            return [pscustomobject]@{
                Authorized        = $true
                Action            = 'approved'
                Boundaries        = @($normalizedParts.ToArray())
                NormalizedVerdict = ('approved for ' + ($normalizedParts -join ' AND '))
                DirectiveSentinel = 'SPECREW_BOUNDARY_AUTHORIZED'
                FailureReason     = $null
            }
        }

        $boundary = Normalize-SpecrewCanonicalBoundaryType -Boundary $payload
        if ($boundary -in $CanonicalBoundaries) {
            return [pscustomobject]@{
                Authorized        = $true
                Action            = 'approved'
                Boundaries        = @($boundary)
                NormalizedVerdict = "approved for $boundary-boundary entry"
                DirectiveSentinel = 'SPECREW_BOUNDARY_AUTHORIZED'
                FailureReason     = $null
            }
        }
    }

    return [pscustomobject]@{
        Authorized        = $false
        Action            = 'unrecognized'
        Boundaries        = @()
        NormalizedVerdict = $null
        DirectiveSentinel = 'SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED'
        FailureReason     = 'Verdict did not match a recognized boundary authorization shape.'
    }
}

function Test-SpecrewBoundaryAuthorization {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$CurrentBoundary,

        [Parameter(Mandatory = $true)]
        [string]$RequestedBoundary,

        [AllowNull()]
        [string]$SessionId,

        [AllowNull()]
        [string]$AgentResponseSnippet,

        [switch]$EmergencyBypassActive
    )

    $currentCanonical = Resolve-SpecrewCanonicalBoundaryType -Boundary $CurrentBoundary -ParameterName 'CurrentBoundary'
    $requestedCanonical = Resolve-SpecrewCanonicalBoundaryType -Boundary $RequestedBoundary -ParameterName 'RequestedBoundary'
    $contextState = Get-SpecrewStartContextState -ProjectRoot $ProjectRoot
    $policyClass = Get-SpecrewBoundaryPolicyClass -ProjectRoot $ProjectRoot -Boundary $requestedCanonical
    $launchMode = if ($contextState.Context.Contains('launch_mode')) { [string]$contextState.Context['launch_mode'] } else { $null }
    $snippet = Get-SpecrewBoundaryEnforcementSnippet -Value $AgentResponseSnippet
    $bypassAttemptDetected = Test-SpecrewBoundaryBypassAttemptSnippet -Snippet $snippet

    $enforcementState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot
    if ($enforcementState.NeedsMigration) {
        throw "Boundary enforcement state is missing from '$($enforcementState.Path)'. Run the migration flow from specrew start before crossing '$requestedCanonical'."
    }

    if ($enforcementState.Issues.Count -gt 0) {
        throw "Boundary enforcement state is malformed: $($enforcementState.Issues -join '; ')"
    }

    if ($EmergencyBypassActive) {
        Add-SpecrewBoundaryEnforcementLedgerEntry -ProjectRoot $ProjectRoot -Boundary $requestedCanonical -EnforcementAction 'bypassed' -CurrentBoundary $currentCanonical -RequestedBoundary $requestedCanonical -LaunchMode $launchMode -AgentResponseSnippet $snippet -Reason 'Emergency bypass is active for this session.'
        return [pscustomobject]@{
            Authorized            = $true
            Decision              = 'bypassed'
            CurrentBoundary       = $currentCanonical
            RequestedBoundary     = $requestedCanonical
            MatchedVerdict        = $null
            DirectiveSentinel     = 'SPECREW_BOUNDARY_BYPASS_ACTIVE'
            BypassAttemptDetected = $bypassAttemptDetected
            Reason                = 'Emergency bypass is active for this session.'
            PolicyClass           = $policyClass
        }
    }

    # DEC-198-GOV-002 (run-2594b7b5 review catch): this live gate matched (from, to) by NAME
    # across the ENTIRE unscoped history, so a prior iteration cycle's approval silently
    # authorized the current cycle's same-named crossing with zero human involvement. It now
    # consumes THE shared cycle-scoped matcher the unreconciled primitive uses - one read,
    # no per-site copy to drift.
    $matchedVerdict = Find-SpecrewCycleScopedAuthorization -History @($enforcementState.State['verdict_history']) -ToBoundary $requestedCanonical -FromBoundary $currentCanonical -LastAuthorizedBoundary ([string]$enforcementState.State['last_authorized_boundary'])

    if ($null -ne $matchedVerdict) {
        Add-SpecrewBoundaryEnforcementLedgerEntry -ProjectRoot $ProjectRoot -Boundary $requestedCanonical -EnforcementAction 'authorized' -CurrentBoundary $currentCanonical -RequestedBoundary $requestedCanonical -LaunchMode $launchMode -AgentResponseSnippet $snippet -Reason 'Persisted authorization matched the requested boundary.'
        return [pscustomobject]@{
            Authorized            = $true
            Decision              = 'authorized'
            CurrentBoundary       = $currentCanonical
            RequestedBoundary     = $requestedCanonical
            MatchedVerdict        = [pscustomobject]$matchedVerdict
            DirectiveSentinel     = 'SPECREW_BOUNDARY_AUTHORIZED'
            BypassAttemptDetected = $bypassAttemptDetected
            Reason                = 'Persisted authorization matched the requested boundary.'
            PolicyClass           = $policyClass
        }
    }

    $mutableState = [ordered]@{
        enabled                  = [bool]$enforcementState.State['enabled']
        last_authorized_boundary = $enforcementState.State['last_authorized_boundary']
        pending_next_boundary    = $requestedCanonical
        verdict_history          = @($enforcementState.State['verdict_history'])
        bypass_history           = @($enforcementState.State['bypass_history'])
    }
    Set-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot -BoundaryEnforcement $mutableState -Context $enforcementState.Context | Out-Null
    Add-SpecrewBoundaryEnforcementLedgerEntry -ProjectRoot $ProjectRoot -Boundary $requestedCanonical -EnforcementAction 'blocked' -CurrentBoundary $currentCanonical -RequestedBoundary $requestedCanonical -LaunchMode $launchMode -AgentResponseSnippet $snippet -Reason "No persisted authorization matched $currentCanonical -> $requestedCanonical."
    return [pscustomobject]@{
        Authorized            = $false
        Decision              = 'blocked'
        CurrentBoundary       = $currentCanonical
        RequestedBoundary     = $requestedCanonical
        MatchedVerdict        = $null
        DirectiveSentinel     = 'SPECREW_BOUNDARY_BLOCKED'
        BypassAttemptDetected = $bypassAttemptDetected
        Reason                = "No persisted authorization matched $currentCanonical -> $requestedCanonical."
        PolicyClass           = $policyClass
    }
}

function Find-SpecrewCycleScopedAuthorization {
    # DEC-198-GOV-002 (+ the run-2594b7b5 review catch): THE cycle-scoped reconciliation read,
    # shared by every consumer that asks "does a recorded human authorization cover this
    # crossing IN THE CURRENT iteration cycle?" (the unreconciled primitive, the live
    # Test-SpecrewBoundaryAuthorization gate). Lifecycles loop, so boundary names recur every
    # iteration: a bare name match across unscoped history re-uses a PRIOR cycle's approval.
    # Rules, walking the append-ordered history newest-to-oldest:
    #   - The cursor invariant first: every authorization write moves last_authorized_boundary,
    #     so cursor == 'iteration-closeout' proves NO post-closeout authorization exists - a
    #     closed cycle authorizes nothing further; only its own closeout crossing may match.
    #   - An entry whose to_boundary cannot be read canonically ends the walk: unreadable
    #     identity fails CLOSED (no match), never open.
    #   - An entry with to == 'iteration-closeout' terminates a cycle: it may itself match
    #     (the current cycle's own closeout, only when nothing mid-cycle is newer), and
    #     everything older belongs to a closed cycle - stop.
    #   - A cycle-reset edge (from == 'iteration-closeout' into plan-or-later-before-closeout)
    #     starts the current cycle: the edge itself may match, and everything older stops.
    param(
        [AllowNull()]
        [object[]]$History,

        [Parameter(Mandatory = $true)]
        [string]$ToBoundary,

        [AllowNull()]
        [string]$FromBoundary,

        [switch]$RequireAuthorizingHuman,

        [AllowNull()]
        [string]$LastAuthorizedBoundary
    )

    $boundaryOrder = @(Get-SpecrewBoundaryOrder)
    $planIdx = [Array]::IndexOf($boundaryOrder, 'plan')
    $closeoutIdx = [Array]::IndexOf($boundaryOrder, 'iteration-closeout')
    $targetTo = Normalize-SpecrewCanonicalBoundaryType -Boundary $ToBoundary
    $targetFrom = if ([string]::IsNullOrWhiteSpace($FromBoundary)) { $null } else { Normalize-SpecrewCanonicalBoundaryType -Boundary $FromBoundary }
    $cursor = if ([string]::IsNullOrWhiteSpace($LastAuthorizedBoundary)) { $null } else { Normalize-SpecrewCanonicalBoundaryType -Boundary $LastAuthorizedBoundary }
    if ($cursor -eq 'iteration-closeout' -and $targetTo -ne 'iteration-closeout') { return $null }

    $items = @($History)
    $walkedMidCycle = $false
    for ($i = $items.Count - 1; $i -ge 0; $i--) {
        $entryMap = if ($items[$i] -is [System.Collections.IDictionary]) { $items[$i] } else { $items[$i] | ConvertTo-Json -Depth 12 | ConvertFrom-Json -AsHashtable -Depth 12 }
        $to = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$entryMap['to_boundary'])
        if ([string]::IsNullOrWhiteSpace($to) -or $to -notin $boundaryOrder) { return $null }
        $from = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$entryMap['from_boundary'])
        $human = [string]$entryMap['authorizing_human']
        $entryMatches = ($to -eq $targetTo) -and
        ($null -eq $targetFrom -or $from -eq $targetFrom) -and
        ((-not $RequireAuthorizingHuman) -or (-not [string]::IsNullOrWhiteSpace($human)))
        if ($to -eq 'iteration-closeout') {
            if (-not $walkedMidCycle -and $entryMatches) { return $entryMap }
            return $null
        }
        if ($entryMatches) { return $entryMap }
        $toIdx = [Array]::IndexOf($boundaryOrder, $to)
        if ($from -eq 'iteration-closeout' -and $toIdx -ge $planIdx -and $toIdx -lt $closeoutIdx) { return $null }
        if ($toIdx -lt $closeoutIdx) { $walkedMidCycle = $true }
    }
    return $null
}

function Get-SpecrewUnreconciledBoundary {
    # FR-001/FR-002: the ONE shared read answering "is there a human-judgment boundary
    # crossing that was mechanically recorded but never human-authorized?" Consumed by the sync
    # ratchet, the governance validator, the resume/start re-confirm surface, and the hard gates
    # (the A2 covering set) so the answer cannot drift between call sites. Pure read - never
    # mutates state. Returns $null when clean, else a pscustomobject:
    #   Boundary        - the unauthorized crossing (canonical name)
    #   LastAuthorized  - the cursor (canonical name or $null)
    #   RevertAnchor    - the auth_commit_hash of the newest authorization (the rollback target)
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $enforcementState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot
    if ($enforcementState.NeedsMigration) { return $null }
    # DEC-198-GOV-002 (with the cycle fix below): malformed enforcement state must fail
    # CLOSED at every consumer of this read, not read as "nothing unreconciled". A corrupt
    # ledger passing the ratchet is the same fail-open class as the cycle blindness.
    if ($enforcementState.Issues.Count -gt 0) {
        throw ("The boundary approval ledger cannot be read ({0}). Fix the recorded state before advancing; no boundary step can be verified while the ledger is unreadable." -f (@($enforcementState.Issues) -join '; '))
    }

    $contextState = Get-SpecrewStartContextState -ProjectRoot $ProjectRoot
    $working = $null
    if ($contextState.Context.Contains('session_state')) {
        $session = $contextState.Context['session_state']
        if ($session -is [System.Collections.IDictionary] -and $session.Contains('boundary_type')) {
            $working = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$session['boundary_type'])
        }
    }
    if ([string]::IsNullOrWhiteSpace($working)) { return $null }
    # A session boundary that does not normalize to a canonical human-judgment boundary
    # (e.g. a legacy 'implement' alias) cannot be a skipped APPROVAL - the ratchet only
    # guards the policy-classed gates. Malformed enforcement STATE still hard-fails
    # upstream (the enforcement-state Issues path).
    if ($working -notin @(Get-SpecrewCanonicalBoundaryTypes)) { return $null }

    $policyClass = Get-SpecrewBoundaryPolicyClass -ProjectRoot $ProjectRoot -Boundary $working
    if ($policyClass -ne 'human-judgment-required') { return $null }

    $lastAuthorized = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$enforcementState.State['last_authorized_boundary'])
    if ($lastAuthorized -eq $working) { return $null }

    $history = @($enforcementState.State['verdict_history'])
    $revertAnchor = $null
    foreach ($entry in $history) {
        $entryMap = if ($entry -is [System.Collections.IDictionary]) { $entry } else { $entry | ConvertTo-Json -Depth 12 | ConvertFrom-Json -AsHashtable -Depth 12 }
        if (-not [string]::IsNullOrWhiteSpace([string]$entryMap['auth_commit_hash'])) {
            $revertAnchor = [string]$entryMap['auth_commit_hash']   # newest wins (history is append-ordered)
        }
    }

    # DEC-198-GOV-002: reconciliation binds to the CURRENT iteration cycle and ordered
    # occurrence, never the bare boundary name - lifecycles loop, so every boundary name
    # recurs each iteration and iteration N-1's same-named approval must not satisfy
    # iteration N's crossing (field failure: 001's retro entry satisfied 002's retro).
    # The cycle scoping lives in Find-SpecrewCycleScopedAuthorization, THE shared matcher
    # this primitive and the live authorization gate both consume (run-2594b7b5 review
    # catch: a per-site copy of the scan is exactly how the gate stayed cycle-blind).
    $reconciledEntry = Find-SpecrewCycleScopedAuthorization -History $history -ToBoundary $working -RequireAuthorizingHuman -LastAuthorizedBoundary $lastAuthorized
    if ($null -ne $reconciledEntry) { return $null }

    return [pscustomobject]@{
        Boundary       = $working
        LastAuthorized = $lastAuthorized
        RevertAnchor   = $revertAnchor
    }
}

function Invoke-SpecrewBoundaryRatchetGate {
    # FR-002: the ratchet. On a host whose agent never stops, the FIRST unapproved
    # crossing still records mechanically (F-174 preserved - a human was not present to ask),
    # but a SECOND advance while that crossing is unapproved is refused here, loudly. The
    # refusal message is consumer-legible by contract (FR-018 as amended): it names the waiting
    # step and both ways forward, tells the assistant to ask an approve/decline question, and
    # carries no internal rule identifiers. Re-recording the SAME boundary is not an advance
    # (idempotent re-sync stays allowed).
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$RequestedBoundary
    )

    $requestedCanonical = Resolve-SpecrewCanonicalBoundaryType -Boundary $RequestedBoundary -ParameterName 'RequestedBoundary'
    $unreconciled = Get-SpecrewUnreconciledBoundary -ProjectRoot $ProjectRoot
    if ($null -eq $unreconciled) { return $true }
    if ($unreconciled.Boundary -eq $requestedCanonical) { return $true }

    $contextState = Get-SpecrewStartContextState -ProjectRoot $ProjectRoot
    $launchMode = if ($contextState.Context.Contains('launch_mode')) { [string]$contextState.Context['launch_mode'] } else { $null }
    Add-SpecrewBoundaryEnforcementLedgerEntry -ProjectRoot $ProjectRoot -Boundary $requestedCanonical -EnforcementAction 'blocked' -CurrentBoundary $unreconciled.Boundary -RequestedBoundary $requestedCanonical -LaunchMode $launchMode -AgentResponseSnippet $null -Reason ("Ratchet refusal: '{0}' is recorded but not human-approved; a second advance to '{1}' is refused until it is reconciled." -f $unreconciled.Boundary, $requestedCanonical)

    $anchorText = if ([string]::IsNullOrWhiteSpace([string]$unreconciled.RevertAnchor)) { 'the last approved commit' } else { ("commit {0}" -f ([string]$unreconciled.RevertAnchor).Substring(0, [Math]::Min(8, ([string]$unreconciled.RevertAnchor).Length))) }
    throw ("Cannot continue to '{0}': the earlier '{1}' step is still waiting for your approval. One approval advances one step, so the assistant must not move past an unapproved step. Two ways forward: (1) approve the waiting '{1}' step - the assistant will ask you to approve or decline it; or (2) roll back to the last approved point ({2}) - the assistant will ask for your explicit confirmation first, because rolling back discards the unapproved work. Re-running the same command will not bypass this stop." -f $requestedCanonical, $unreconciled.Boundary, $anchorText)
}

function Add-SpecrewBoundaryAuthorization {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$CurrentBoundary,

        [Parameter(Mandatory = $true)]
        [string]$AuthorizedBoundary,

        [Parameter(Mandatory = $true)]
        [string]$AuthorizingHuman,

        [Parameter(Mandatory = $true)]
        [string]$VerdictText,

        [AllowNull()]
        [string]$AuthCommitHash,

        [AllowNull()]
        [string]$RecordedAt,

        # F-174 iteration 011 (T004, FR-026): the provenance of THIS authorization's evidence —
        # 'hook-captured-from-transcript' (the Stop/UPS hook read the human's actual typed verdict) |
        # 'human-confirmed-at-resume' (the human explicitly re-confirmed a surfaced-pending boundary) |
        # 'unspecified'. Recorded on the verdict_history entry so the audit trail is honest about each
        # authorization's provenance strength. It is NEVER 'fabricated' — sync no longer writes authorizations.
        [AllowNull()]
        [string]$EvidenceSource,

        # FR-005: 'standard' (the verdict answered the live pending ask) | 'retroactive'
        # (the human reconciled an already-crossed boundary after the fact - the resume/re-confirm
        # surface, or a capture that missed its original stop). Recorded on the entry so
        # retroactive approvals are auditably distinct.
        [AllowNull()]
        [string]$Kind
    )

    $currentCanonical = if ([string]::IsNullOrWhiteSpace($CurrentBoundary)) { $null } else { Resolve-SpecrewCanonicalBoundaryType -Boundary $CurrentBoundary -ParameterName 'CurrentBoundary' }
    $authorizedCanonical = Resolve-SpecrewCanonicalBoundaryType -Boundary $AuthorizedBoundary -ParameterName 'AuthorizedBoundary'
    $boundaryOrder = @(Get-SpecrewBoundaryOrder)
    $currentIndex = if ([string]::IsNullOrWhiteSpace($currentCanonical)) { -1 } else { [Array]::IndexOf($boundaryOrder, $currentCanonical) }
    $authorizedIndex = [Array]::IndexOf($boundaryOrder, $authorizedCanonical)
    # Iteration cycle reset (FR-004): authorizing an earlier-phase boundary FROM
    # iteration-closeout is the next iteration beginning, not a backward move.
    $isCycleReset = ($currentCanonical -eq 'iteration-closeout' -and $authorizedIndex -ge [Array]::IndexOf($boundaryOrder, 'plan') -and $authorizedIndex -lt $currentIndex)
    if ($authorizedIndex -lt $currentIndex -and -not $isCycleReset) {
        throw "Cannot authorize '$authorizedCanonical' from '$currentCanonical' because it moves backward in the canonical order."
    }

    $parseResult = Parse-SpecrewBoundaryVerdict -VerdictText $VerdictText
    if (-not $parseResult.Authorized) {
        throw "Verdict '$VerdictText' did not parse into an authorized boundary verdict."
    }

    $effectiveRecordedAt = if ([string]::IsNullOrWhiteSpace($RecordedAt)) { (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') } else { $RecordedAt.Trim() }
    $effectiveAuthCommitHash = if ([string]::IsNullOrWhiteSpace($AuthCommitHash)) {
        $resolvedHead = @(& git -C (Resolve-ProjectPath -Path $ProjectRoot) rev-parse --verify HEAD 2>$null)
        if ($LASTEXITCODE -eq 0 -and $resolvedHead.Count -gt 0) { [string]$resolvedHead[0] } else { $null }
    }
    else {
        $AuthCommitHash.Trim()
    }

    $enforcementState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot
    if ($enforcementState.NeedsMigration) {
        Initialize-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot -CurrentBoundary $currentCanonical | Out-Null
        $enforcementState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot
    }

    if ($enforcementState.Issues.Count -gt 0) {
        throw "Boundary enforcement state is malformed: $($enforcementState.Issues -join '; ')"
    }

    # Idempotence (FR-005): a re-fired authorization for the boundary the cursor ALREADY sits on
    # (same to_boundary as the newest entry) is a duplicate capture of the same verdict - a
    # no-op, never a duplicate history entry. Narrow by design: in a new iteration cycle the
    # cursor is 'iteration-closeout', so re-authorizing 'plan' for the NEXT iteration still
    # appends (the cursor differs).
    $existingHistory = @($enforcementState.State['verdict_history'])
    $cursorBoundary = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$enforcementState.State['last_authorized_boundary'])
    if ($cursorBoundary -eq $authorizedCanonical -and $existingHistory.Count -gt 0) {
        $newestEntry = $existingHistory[-1]
        $newestMap = if ($newestEntry -is [System.Collections.IDictionary]) { $newestEntry } else { $newestEntry | ConvertTo-Json -Depth 12 | ConvertFrom-Json -AsHashtable -Depth 12 }
        if ((Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$newestMap['to_boundary'])) -eq $authorizedCanonical) {
            return [pscustomobject]@{
                AuthorizedBoundary = $authorizedCanonical
                StoredVerdict      = [string]$newestMap['verdict_text']
                RecordedAt         = [string]$newestMap['recorded_at']
                DirectiveSentinel  = 'SPECREW_BOUNDARY_AUTHORIZED'
            }
        }
    }

    $verdictHistory = New-Object System.Collections.Generic.List[object]
    foreach ($entry in @($enforcementState.State['verdict_history'])) {
        $verdictHistory.Add($entry) | Out-Null
    }
    $effectiveEvidenceSource = if ([string]::IsNullOrWhiteSpace($EvidenceSource)) { 'unspecified' } else { $EvidenceSource.Trim() }
    $effectiveKind = if ([string]::IsNullOrWhiteSpace($Kind)) { 'standard' } else { $Kind.Trim().ToLowerInvariant() }
    if ($effectiveKind -notin @('standard', 'retroactive')) {
        throw "Authorization kind '$Kind' is not recognized (standard | retroactive)."
    }
    $verdictHistory.Add([ordered]@{
        from_boundary     = $currentCanonical
        to_boundary       = $authorizedCanonical
        verdict_text      = $VerdictText
        authorizing_human = $AuthorizingHuman.Trim()
        recorded_at       = $effectiveRecordedAt
        auth_commit_hash  = $effectiveAuthCommitHash
        evidence_source   = $effectiveEvidenceSource
        kind              = $effectiveKind
    }) | Out-Null

    $updatedState = [ordered]@{
        enabled                  = [bool]$enforcementState.State['enabled']
        last_authorized_boundary = $authorizedCanonical
        pending_next_boundary    = if ((Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$enforcementState.State['pending_next_boundary'])) -eq $authorizedCanonical) { $null } else { $enforcementState.State['pending_next_boundary'] }
        verdict_history          = @($verdictHistory.ToArray())
        bypass_history           = @($enforcementState.State['bypass_history'])
    }
    Set-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot -BoundaryEnforcement $updatedState -Context $enforcementState.Context | Out-Null

    return [pscustomobject]@{
        AuthorizedBoundary = $authorizedCanonical
        StoredVerdict      = $VerdictText
        RecordedAt         = $effectiveRecordedAt
        DirectiveSentinel  = 'SPECREW_BOUNDARY_AUTHORIZED'
    }
}

function Write-SpecrewBoundaryAuthorizationDirective {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentBoundary,

        [Parameter(Mandatory = $true)]
        [string]$RequestedBoundary,

        [Parameter(Mandatory = $true)]
        [string]$DirectiveSentinel,

        [AllowNull()]
        [pscustomobject]$ParseResult,

        [AllowNull()]
        [string]$BypassReason
    )

    $currentCanonical = Resolve-SpecrewCanonicalBoundaryType -Boundary $CurrentBoundary -ParameterName 'CurrentBoundary'
    $requestedCanonical = Resolve-SpecrewCanonicalBoundaryType -Boundary $RequestedBoundary -ParameterName 'RequestedBoundary'
    $sentinel = $DirectiveSentinel.Trim()
    if ($sentinel -notin @('SPECREW_BOUNDARY_BLOCKED', 'SPECREW_BOUNDARY_AUTHORIZED', 'SPECREW_BOUNDARY_BYPASS_ACTIVE', 'SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED')) {
        throw "DirectiveSentinel '$DirectiveSentinel' is not recognized."
    }

    switch ($sentinel) {
        'SPECREW_BOUNDARY_AUTHORIZED' {
            return @(
                'SPECREW_BOUNDARY_AUTHORIZED'
                "Boundary `$currentCanonical -> $requestedCanonical` is authorized."
            ) -join [Environment]::NewLine
        }
        'SPECREW_BOUNDARY_BYPASS_ACTIVE' {
            return @(
                'SPECREW_BOUNDARY_BYPASS_ACTIVE'
                'Boundary enforcement is bypassed for this session.'
                ('Reason: {0}' -f (Get-DecisionLedgerOptionalValue -Value $BypassReason))
            ) -join [Environment]::NewLine
        }
        'SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED' {
            return @(
                'SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED'
                "Boundary `$currentCanonical -> $requestedCanonical` still requires explicit human authorization."
                'Recognized verdicts:'
            ) + @(Get-SpecrewBoundaryEnforcementRecognizedVerdicts -RequestedBoundary $requestedCanonical | ForEach-Object { "- $_" }) -join [Environment]::NewLine
        }
        default {
            return @(
                'SPECREW_BOUNDARY_BLOCKED'
                "Boundary `$currentCanonical -> $requestedCanonical` requires explicit human authorization."
                'Recognized verdicts:'
            ) + @(Get-SpecrewBoundaryEnforcementRecognizedVerdicts -RequestedBoundary $requestedCanonical | ForEach-Object { "- $_" }) -join [Environment]::NewLine
        }
    }
}

function Add-SpecrewBoundaryBypassRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$SessionId,

        [Parameter(Mandatory = $true)]
        [string]$Reason,

        [AllowNull()]
        [string]$Boundary,

        [AllowNull()]
        [string]$LaunchMode,

        [AllowNull()]
        [string]$AgentResponseSnippet,

        [AllowNull()]
        [string]$AuthCommitHash
    )

    $enforcementState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot
    if ($enforcementState.NeedsMigration) {
        Initialize-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot -CurrentBoundary $null | Out-Null
        $enforcementState = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot
    }

    if ($enforcementState.Issues.Count -gt 0) {
        throw "Boundary enforcement state is malformed: $($enforcementState.Issues -join '; ')"
    }

    $bypassHistory = New-Object System.Collections.Generic.List[object]
    foreach ($entry in @($enforcementState.State['bypass_history'])) {
        $bypassHistory.Add($entry) | Out-Null
    }

    $canonicalBoundary = if ([string]::IsNullOrWhiteSpace($Boundary)) { $null } else { Resolve-SpecrewCanonicalBoundaryType -Boundary $Boundary -ParameterName 'Boundary' }
    $bypassHistory.Add([ordered]@{
        session_id              = $SessionId
        reason                  = $Reason.Trim()
        recorded_at             = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        boundary                = $canonicalBoundary
        launch_mode             = $LaunchMode
        agent_response_snippet  = Get-SpecrewBoundaryEnforcementSnippet -Value $AgentResponseSnippet
        auth_commit_hash        = $AuthCommitHash
    }) | Out-Null

    $updatedState = [ordered]@{
        enabled                  = [bool]$enforcementState.State['enabled']
        last_authorized_boundary = $enforcementState.State['last_authorized_boundary']
        pending_next_boundary    = $enforcementState.State['pending_next_boundary']
        verdict_history          = @($enforcementState.State['verdict_history'])
        bypass_history           = @($bypassHistory.ToArray())
    }
    Set-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot -BoundaryEnforcement $updatedState -Context $enforcementState.Context | Out-Null
    return $updatedState
}

function Get-SpecrewBoundaryEnforcementSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $state = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ProjectRoot
    if ($state.NeedsMigration -or $state.Issues.Count -gt 0 -or $null -eq $state.State) {
        return [pscustomobject]@{
            Enabled                = $false
            LastAuthorizedBoundary = $null
            PendingNextBoundary    = $null
            LastEnforcementAt      = $null
            EnforcementEventCount  = 0
            BypassEventCount       = 0
        }
    }

    $verdictHistory = @($state.State['verdict_history'])
    $bypassHistory = @($state.State['bypass_history'])
    $latestTimestamp = @(
        $verdictHistory | ForEach-Object { [string]($_.recorded_at) }
        $bypassHistory | ForEach-Object { [string]($_.recorded_at) }
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object | Select-Object -Last 1

    return [pscustomobject]@{
        Enabled                = [bool]$state.State['enabled']
        LastAuthorizedBoundary = $state.State['last_authorized_boundary']
        PendingNextBoundary    = $state.State['pending_next_boundary']
        LastEnforcementAt      = $latestTimestamp
        EnforcementEventCount  = ($verdictHistory.Count + $bypassHistory.Count)
        BypassEventCount       = $bypassHistory.Count
    }
}

function Get-ValidatorGlobalStatePathspecs {
    # NOTE: `.specify/feature.json` was previously in this list but is purely a
    # "current feature pointer" consumed only by scaffold-feature-closeout-dashboard.ps1
    # for path resolution — no validator rule depends on it. Including it forced
    # every feature-transitioning PR (e.g., feature-closeout PRs) to fall back to
    # full-repo validation, multiplying the wait time on PR-CI. Removed per the
    # 2026-05-22 push-to-main scoping work (companion to Proposal 087).
    return @(
        '.specrew/config.yml'
        '.specrew/constitution.md'
        '.specrew/iteration-config.yml'
        '.specrew/role-assignments.yml'
        '.specrew/presets/'
        '.specrew/presets/**'
        '.specrew/lenses/'
        '.specrew/lenses/**'
        '.specrew/roadmap.yml'
        '.squad/identity/wisdom.md'
    )
}

function Get-ChangedMarkdownFiles {
    # Proposal 088: identifies .md files that the lint gate should check at boundary-sync time.
    #
    # Resolution order (Fix following F-040 calc-v2 dogfooding 2026-05-23):
    #   1. If a base ref AND HEAD are available, return `git diff <baseRef>...HEAD -- '*.md'`
    #      (committed changes since the branch diverged).
    #   2. Otherwise fall back to working-tree status: `git ls-files -m -o --exclude-standard -- '*.md'`
    #      (uncommitted modified + untracked-but-not-ignored .md files).
    #
    # The fallback is necessary because the original implementation went no-op when:
    #   - the repo has zero commits (greenfield-new), so `git rev-parse HEAD` fails AND
    #     `git diff baseRef...HEAD` has no HEAD to diff against;
    #   - the repo has no remote/origin (so `Get-SpecrewLocalScopeBaseRef` returns null).
    # Both conditions ride on top of any fresh-project run, defeating the lint gate during the
    # entire pre-first-commit scaffolding phase — exactly when the model writes the most markdown.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot

    $markdownFiles = New-Object System.Collections.Generic.List[string]

    $baseRef = Get-SpecrewLocalScopeBaseRef -ProjectRoot $resolvedProjectRoot
    $usedDiffPath = $false
    if (-not [string]::IsNullOrWhiteSpace($baseRef)) {
        # Confirm HEAD exists before attempting the two-dot diff. Greenfield repos have a branch
        # ref but no commits, in which case `git diff baseRef...HEAD` fails fatally (128).
        $null = & git -C $resolvedProjectRoot rev-parse --verify --quiet HEAD 2>$null
        $headExists = ($LASTEXITCODE -eq 0)
        $global:LASTEXITCODE = 0

        if ($headExists) {
            $diffOutput = @(& git -C $resolvedProjectRoot diff --name-only --diff-filter=d "$baseRef...HEAD" -- '*.md' 2>$null)
            $diffExit = $LASTEXITCODE
            $global:LASTEXITCODE = 0
            if ($diffExit -eq 0) {
                $usedDiffPath = $true
                foreach ($relPath in $diffOutput) {
                    $trimmed = [string]$relPath
                    if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
                    $absPath = Join-Path -Path $resolvedProjectRoot -ChildPath $trimmed.Trim()
                    if (Test-Path -LiteralPath $absPath -PathType Leaf) {
                        $null = $markdownFiles.Add($absPath)
                    }
                }
            }
        }
    }

    # Fallback: include working-tree changes (modified, added-but-uncommitted, untracked-not-ignored).
    # Activates when base-ref or HEAD is unavailable, OR when the diff path returned zero matches and
    # there might still be uncommitted edits the model just wrote.
    if (-not $usedDiffPath -or $markdownFiles.Count -eq 0) {
        $statusOutput = @(& git -C $resolvedProjectRoot ls-files -m -o --exclude-standard -- '*.md' 2>$null)
        $statusExit = $LASTEXITCODE
        $global:LASTEXITCODE = 0
        if ($statusExit -eq 0) {
            foreach ($relPath in $statusOutput) {
                $trimmed = [string]$relPath
                if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
                $absPath = Join-Path -Path $resolvedProjectRoot -ChildPath $trimmed.Trim()
                if (Test-Path -LiteralPath $absPath -PathType Leaf) {
                    # Dedupe against anything already collected from the diff path.
                    if ($markdownFiles -notcontains $absPath) {
                        $null = $markdownFiles.Add($absPath)
                    }
                }
            }
        }
    }

    # Closeout-gate false-positive fix (2026-06-03): exclude the .squad/ append-only runtime logs
    # (decisions.md, identity/now.md, …) from the lint gate. Those embed YAML decision-blocks whose
    # `---` separators markdownlint mis-reads as setext heading underlines (MD003) — unfixable false
    # positives that otherwise HALT every boundary-sync / feature closeout. They are append-only
    # runtime logs, not prose docs the gate should enforce; iteration artifacts + repo docs still lint.
    $filtered = @($markdownFiles.ToArray() | Where-Object {
        $keep = $true
        if ([string]::IsNullOrWhiteSpace($_)) {
            $keep = $false
        }
        elseif ($_.StartsWith($resolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relative = $_.Substring($resolvedProjectRoot.Length).TrimStart('\', '/')
            if ((($relative -split '[\\/]', 2)[0]) -eq '.squad') { $keep = $false }
        }
        $keep
    })
    return @($filtered)
}

function Invoke-MarkdownLintAutoFix {
    # Proposal 088: runs `markdownlint-cli --fix` against the supplied .md files,
    # detects which were auto-fixed (via `git diff --quiet`), and collects any
    # remaining unfixable violations via a follow-up no-fix pass.
    #
    # Returns:
    #   AutoFixedFiles       array of file paths modified by --fix
    #   UnfixableViolations  array of "file:line: rule" strings
    #   MarkdownLintUnavailable  boolean — true when npx/markdownlint-cli can't launch
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$MarkdownFiles,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $result = [pscustomobject]@{
        AutoFixedFiles          = @()
        UnfixableViolations     = @()
        MarkdownLintUnavailable = $false
    }

    if (-not $MarkdownFiles -or $MarkdownFiles.Count -eq 0) {
        return $result
    }

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot

    if ($null -eq (Get-Command npx -ErrorAction SilentlyContinue)) {
        $result.MarkdownLintUnavailable = $true
        return $result
    }

    # Capture SHA256 hashes BEFORE invoking --fix so we can detect content
    # changes from --fix (regardless of git tracking state).
    $hashesBefore = @{}
    foreach ($file in $MarkdownFiles) {
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            $hashesBefore[$file] = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
        }
    }

    # Pass 1: invoke markdownlint-cli --fix
    $fixArgs = @('--yes', 'markdownlint-cli', '--fix') + $MarkdownFiles
    $fixOutput = & npx @fixArgs 2>&1
    $fixOutputText = ($fixOutput | ForEach-Object { [string]$_ }) -join "`n"

    # Detect "command not found" / launch failure (graceful degradation)
    if ($fixOutputText -match 'ENOENT|command not found|is not recognized|cannot find') {
        $result.MarkdownLintUnavailable = $true
        return $result
    }

    # Detect auto-fixed files by comparing content hash before/after --fix.
    $autoFixed = New-Object System.Collections.Generic.List[string]
    foreach ($file in $MarkdownFiles) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
        $hashAfter = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
        if ($hashesBefore.ContainsKey($file) -and $hashesBefore[$file] -ne $hashAfter) {
            $null = $autoFixed.Add($file)
        }
    }
    $result.AutoFixedFiles = @($autoFixed.ToArray())

    # Pass 2: run markdownlint-cli without --fix to detect unfixable violations
    $checkArgs = @('--yes', 'markdownlint-cli') + $MarkdownFiles
    $checkOutput = & npx @checkArgs 2>&1
    $checkExit = $LASTEXITCODE

    if ($checkExit -ne 0) {
        $checkText = ($checkOutput | ForEach-Object { [string]$_ }) -join "`n"
        $violations = New-Object System.Collections.Generic.List[string]
        foreach ($line in ($checkText -split "`r?`n")) {
            if ($line -match '^(.+\.md):(\d+)(?::\d+)?\s+(MD\d+/\S+)') {
                $null = $violations.Add(("{0}:{1}: {2}" -f $matches[1], $matches[2], $matches[3]))
            }
        }
        $result.UnfixableViolations = @($violations.ToArray())
    }

    return $result
}

function Resolve-SpecrewGitBaseRefCandidate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [string]$Candidate
    )

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        return $null
    }

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $normalizedCandidate = [string]$Candidate
    $normalizedCandidate = $normalizedCandidate.Trim()

    if ($normalizedCandidate -match '^refs/remotes/') {
        $normalizedCandidate = $normalizedCandidate -replace '^refs/remotes/', ''
    }
    elseif ($normalizedCandidate -match '^refs/heads/') {
        $normalizedCandidate = 'origin/{0}' -f ($normalizedCandidate -replace '^refs/heads/', '')
    }
    elseif ($normalizedCandidate -notmatch '^origin/' -and
        $normalizedCandidate -notmatch '^[0-9a-fA-F]{7,40}$' -and
        $normalizedCandidate -notmatch '^HEAD(?:[~^].*)?$') {
        $normalizedCandidate = "origin/$normalizedCandidate"
    }

    $null = @(& git -C $resolvedProjectRoot rev-parse --verify "$normalizedCandidate" 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return $normalizedCandidate
}

function Get-SpecrewLocalScopeBaseRef {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot

    # Guard: only auto-scope when the project root IS a git repo's top-level.
    # If $ProjectRoot is a subdirectory of a different git repo (e.g., a test
    # fixture under .scratch/, or a nested working tree), the surrounding repo's
    # diff doesn't reflect the fixture's iteration state — auto-scoping against
    # it returns zero changed iterations and the validator silently skips work.
    # Refuse to auto-scope in that case; caller falls back to full-repo.
    $gitTopLevelOutput = & git -C $resolvedProjectRoot rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$gitTopLevelOutput)) {
        return $null
    }

    try {
        $gitTopLevelNormalized = (Resolve-Path -LiteralPath ([string]$gitTopLevelOutput).Trim()).Path
        $projectRootNormalized = (Resolve-Path -LiteralPath $resolvedProjectRoot).Path
    }
    catch {
        return $null
    }

    if (-not [string]::Equals($gitTopLevelNormalized, $projectRootNormalized, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    $candidates = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_BASE_REF)) {
        $null = $candidates.Add([string]$env:GITHUB_BASE_REF)
    }

    $originHeadRefs = @(
        & git -C $resolvedProjectRoot symbolic-ref refs/remotes/origin/HEAD 2>$null |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    foreach ($originHeadRef in $originHeadRefs) {
        $null = $candidates.Add($originHeadRef)
    }

    $originFallbackRefs = @(
        & git -C $resolvedProjectRoot for-each-ref --format='%(refname:short)' refs/remotes/origin/main refs/remotes/origin/master 2>$null |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    foreach ($originFallbackRef in $originFallbackRefs) {
        $null = $candidates.Add($originFallbackRef)
    }

    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        $resolvedCandidate = Resolve-SpecrewGitBaseRefCandidate -ProjectRoot $resolvedProjectRoot -Candidate $candidate
        if (-not [string]::IsNullOrWhiteSpace($resolvedCandidate)) {
            return $resolvedCandidate
        }
    }

    return $null
}

function Get-ChangedIterations {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [string]$BaseBranch
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $explicitBaseRequested = -not [string]::IsNullOrWhiteSpace($BaseBranch)
    $resolvedBaseRef = if ($explicitBaseRequested) {
        Resolve-SpecrewGitBaseRefCandidate -ProjectRoot $resolvedProjectRoot -Candidate $BaseBranch
    }
    else {
        Get-SpecrewLocalScopeBaseRef -ProjectRoot $resolvedProjectRoot
    }

    if ([string]::IsNullOrWhiteSpace($resolvedBaseRef)) {
        return [pscustomobject]@{
            UseScopedTargets = $false
            BaseRef          = $null
            IterationPaths   = @()
            DiffFileCount    = 0
            Reason           = if ($explicitBaseRequested) { 'base-ref-unresolved' } else { 'base-ref-undetectable' }
        }
    }

    $allDiffFiles = @(
        & git -C $resolvedProjectRoot diff --name-only "$resolvedBaseRef...HEAD" -- 2>$null |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]@{
            UseScopedTargets = $false
            BaseRef          = $resolvedBaseRef
            IterationPaths   = @()
            DiffFileCount    = 0
            Reason           = 'diff-failed'
        }
    }

    $diffFileCount = $allDiffFiles.Count
    $globalStateArgs = @('diff', '--name-only', "$resolvedBaseRef...HEAD", '--') + @(Get-ValidatorGlobalStatePathspecs)
    $globalStateChanges = @(
        & git -C $resolvedProjectRoot @globalStateArgs 2>$null |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]@{
            UseScopedTargets = $false
            BaseRef          = $resolvedBaseRef
            IterationPaths   = @()
            DiffFileCount    = $diffFileCount
            Reason           = 'global-state-diff-failed'
        }
    }

    if ($globalStateChanges.Count -gt 0) {
        return [pscustomobject]@{
            UseScopedTargets = $false
            BaseRef          = $resolvedBaseRef
            IterationPaths   = @()
            DiffFileCount    = $diffFileCount
            Reason           = 'global-state-changed'
        }
    }

    $changedIterationFiles = @(
        $allDiffFiles |
            Where-Object { $_ -match '^specs/[^/]+/iterations/' }
    )

    $iterationPaths = New-Object System.Collections.Generic.List[string]
    foreach ($changedFile in $changedIterationFiles) {
        $match = [regex]::Match($changedFile.Trim(), '^(specs/[^/]+/iterations/[^/]+)(?:/|$)')
        if (-not $match.Success) {
            continue
        }

        $iterationPath = Join-Path $resolvedProjectRoot $match.Groups[1].Value
        if ((Test-Path -LiteralPath $iterationPath -PathType Container) -and -not $iterationPaths.Contains($iterationPath)) {
            $null = $iterationPaths.Add($iterationPath)
        }
    }

    return [pscustomobject]@{
        UseScopedTargets = $true
        BaseRef          = $resolvedBaseRef
        IterationPaths   = @($iterationPaths | Sort-Object)
        DiffFileCount    = $diffFileCount
        Reason           = 'scoped'
    }
}

function Get-NormalizedKeyword {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $normalized = $Value.ToLowerInvariant()
    if ($normalized -match '(planning|executing|reviewing|retro|complete|abandoned)') {
        return $Matches[1]
    }

    if ($normalized -match '(accepted|needs-rework|blocked)') {
        return $Matches[1]
    }

    return $normalized.Trim()
}

function Get-DeclaredCompletedTaskCount {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$PlanLines,

        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$StateLines
    )

    $planTasks = @(Get-MarkdownSectionTable -Lines $PlanLines -Heading 'Tasks')
    if ($planTasks.Count -gt 0) {
        return @(
            $planTasks |
                Where-Object {
                    $_.PSObject.Properties['Status'] -and
                    (Normalize-MarkdownCell ([string]$_.Status)).ToLowerInvariant() -eq 'done'
                }
        ).Count
    }

    $stateTasks = @(Get-MarkdownSectionTable -Lines $StateLines -Heading 'Task Status')
    if ($stateTasks.Count -eq 0) {
        $stateTasks = @(Get-MarkdownSectionTable -Lines $StateLines -Heading 'Tasks')
    }

    return @(
        $stateTasks |
            Where-Object {
                if (-not $_.PSObject.Properties['Status']) { return $false }
                $normalizedStatus = Get-NormalizedKeyword ([string]$_.Status)
                $normalizedStatus -in @('done', 'pass')
            }
    ).Count
}

function Add-DecisionsLedgerEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    $ledgerPath = Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot
    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $entryBody = @(
        "## $timestamp — $Title"
        ''
    ) + @($Lines | Where-Object { $null -ne $_ }) + @('')
    $entryText = ($entryBody -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine

    Invoke-WithFileLock -Path $ledgerPath -ScriptBlock {
        $existingContent = if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
            Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
        }
        else {
            "# Decisions Ledger{0}{0}" -f [Environment]::NewLine
        }

        $updatedContent = $existingContent.TrimEnd()
        if (-not [string]::IsNullOrWhiteSpace($updatedContent)) {
            $updatedContent += [Environment]::NewLine + [Environment]::NewLine
        }

        $updatedContent += $entryText
        Write-Utf8FileAtomic -Path $ledgerPath -Content $updatedContent
    } | Out-Null

    return $ledgerPath
}

function Get-DecisionLedgerOptionalValue {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return '(none)'
    }

    return $Value.Trim()
}

function New-DecisionsLedgerEntryId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    $prefix = ($Type.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    return ('{0}-{1}' -f $prefix, ([guid]::NewGuid().ToString('N').Substring(0, 12)))
}

function Add-StructuredDecisionsLedgerEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [ValidateSet('decision', 'defer', 'escalation', 'routing-evidence', 'clarify-skip', 'review-gap')]
        [string]$Type,

        [string]$DecisionId,
        [string]$AffectedRequirement,
        [string]$AffectedIteration,
        [string]$ApprovingHuman,
        [string]$NextAction = 'none',
        [string]$Rationale,
        [string[]]$DetailLines
    )

    $recordedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $effectiveDecisionId = if ([string]::IsNullOrWhiteSpace($DecisionId)) {
        New-DecisionsLedgerEntryId -Type $Type
    }
    else {
        $DecisionId.Trim()
    }

    $lines = @(
        "- **Decision ID**: $effectiveDecisionId"
        "- **Type**: $Type"
        "- **Affected Requirement**: $(Get-DecisionLedgerOptionalValue -Value $AffectedRequirement)"
        "- **Affected Iteration**: $(Get-DecisionLedgerOptionalValue -Value $AffectedIteration)"
        "- **Approving Human**: $(Get-DecisionLedgerOptionalValue -Value $ApprovingHuman)"
        "- **Recorded At**: $recordedAt"
        "- **Next Action**: $(Get-DecisionLedgerOptionalValue -Value $NextAction)"
        "- **Rationale**: $(Get-DecisionLedgerOptionalValue -Value $Rationale)"
    )

    if ($null -ne $DetailLines -and $DetailLines.Count -gt 0) {
        $lines += @('') + @($DetailLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    return Add-DecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title $Title -Lines $lines
}

function Get-DecisionsLedgerEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $ledgerPath = Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
        return @()
    }

    $lines = @(Get-Content -LiteralPath $ledgerPath -Encoding UTF8)
    $entries = New-Object System.Collections.Generic.List[object]
    $entryRegex = '^(?:##|###)\s+(\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2}Z)?)\s*[—:-]\s*(.+?)\s*$'

    $currentTimestamp = $null
    $currentTitle = $null
    $currentLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        $entryMatch = [regex]::Match($line, $entryRegex)
        if ($entryMatch.Success) {
            if ($null -ne $currentTimestamp) {
                $entries.Add((New-DecisionsLedgerParsedEntry -Timestamp $currentTimestamp -Title $currentTitle -EntryLines $currentLines)) | Out-Null
            }

            $currentTimestamp = $entryMatch.Groups[1].Value.Trim()
            $currentTitle = $entryMatch.Groups[2].Value.Trim()
            $currentLines = New-Object System.Collections.Generic.List[string]
            continue
        }

        if ($null -ne $currentTimestamp) {
            $currentLines.Add($line) | Out-Null
        }
    }

    if ($null -ne $currentTimestamp) {
        $entries.Add((New-DecisionsLedgerParsedEntry -Timestamp $currentTimestamp -Title $currentTitle -EntryLines $currentLines)) | Out-Null
    }

    return $entries.ToArray()
}

function New-DecisionsLedgerParsedEntry {
    param(
        [string]$Timestamp,
        [string]$Title,
        [System.Collections.Generic.List[string]]$EntryLines
    )

    $rawText = $EntryLines -join "`n"
    $authorizationTextLines = New-Object System.Collections.Generic.List[string]
    $captureAuthorizationText = $false
    foreach ($line in $EntryLines) {
        if (-not $captureAuthorizationText) {
            if ($line -match '^\s*-\s+\*\*Authorization Text\*\*:\s*$') {
                $captureAuthorizationText = $true
            }
            continue
        }

        if ($line -match '^\s*-\s+\*\*[^*]+\*\*:' -or $line -match '^##\s+') {
            break
        }

        if ($line.TrimStart().StartsWith('>')) {
            $authorizationTextLines.Add($line.Trim()) | Out-Null
            continue
        }

        if ([string]::IsNullOrWhiteSpace($line) -and $authorizationTextLines.Count -gt 0) {
            $authorizationTextLines.Add('') | Out-Null
            continue
        }

        break
    }

    $authorizationText = if ($authorizationTextLines.Count -gt 0) { ($authorizationTextLines -join "`n").Trim() } elseif (($rawText -match '(?ms)^-\s+\*\*Authorization Text\*\*:\s*(?<text>.+)$')) { $Matches['text'].Trim() } else { $null }
    return [pscustomobject]@{
        Timestamp           = $Timestamp
        Title               = $Title
        DecisionId          = if (($rawText -match '(?m)^-\s+\*\*Decision ID\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        Type                = if (($rawText -match '(?m)^-\s+\*\*Type\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        Boundary            = if (($rawText -match '(?m)^-\s+\*\*Boundary\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        AffectedRequirement = if (($rawText -match '(?m)^-\s+\*\*Affected Requirement\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        AffectedIteration   = if (($rawText -match '(?m)^-\s+\*\*Affected Iteration\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        ApprovingHuman      = if (($rawText -match '(?m)^-\s+\*\*Approving Human\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        RecordedAt          = if (($rawText -match '(?m)^-\s+\*\*Recorded At\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $Timestamp }
        CommitReference     = if (($rawText -match '(?m)^-\s+\*\*Commit Reference\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        AuthorizationText   = $authorizationText
        NextAction          = if (($rawText -match '(?m)^-\s+\*\*Next Action\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        RawLines            = $EntryLines.ToArray()
        RawText             = $rawText
        RoutingStatus       = if (($rawText -match 'status=(honored|fell-back)')) { $Matches[1] } else { $null }
        FallbackReason      = if (($rawText -match 'fallback=([^\r\n]+)')) { $Matches[1].Trim() } else { $null }
    }
}

function Get-InteractionModelBoundaryCatalog {
    return @(
        [pscustomobject]@{ Name = 'planning'; StopLabel = 'planning'; SubjectPatterns = @('^Feature \d+.* iteration \d+ planning boundary(?:\s|$)') },
        [pscustomobject]@{ Name = 'hardening-gate-and-implementation-auth'; StopLabel = 'hardening-gate-and-implementation-auth'; SubjectPatterns = @('^Feature \d+.* iteration \d+: record hardening-gate sign-off and implementation authorization(?:\s|$)') },
        [pscustomobject]@{ Name = 'implementation'; StopLabel = 'implementation'; SubjectPatterns = @('^Feature \d+.* iteration \d+: implement(?:\s|$)', '^Feature \d+.* iteration \d+: bounded(?:\s|$)', '^Feature \d+.* iteration \d+: implementation(?:\s|$)') },
        [pscustomobject]@{ Name = 'review-boundary'; StopLabel = 'review-boundary'; SubjectPatterns = @('^Feature \d+.* iteration \d+ review boundary(?:\s|$)') },
        [pscustomobject]@{ Name = 'review-verdict-signoff'; StopLabel = 'review-verdict-signoff'; SubjectPatterns = @('^Feature \d+.* iteration \d+ review-verdict-signoff boundary(?:\s|$)') },
        [pscustomobject]@{ Name = 'retro-boundary'; StopLabel = 'retro-boundary'; SubjectPatterns = @('^Feature \d+.* iteration \d+ retrospective boundary(?:\s|$)') },
        [pscustomobject]@{ Name = 'iteration-closeout'; StopLabel = 'iteration-closeout'; SubjectPatterns = @('^Feature \d+.* iteration \d+ closeout boundary(?:\s|$)') },
        [pscustomobject]@{ Name = 'feature-closeout'; StopLabel = 'feature-closeout'; SubjectPatterns = @('^Feature \d+.*: feature-closeout boundary(?:\s|$)') }
    )
}

function Normalize-InteractionModelBoundaryName {
    param([AllowNull()][string]$Boundary)

    if ([string]::IsNullOrWhiteSpace($Boundary)) {
        return $null
    }

    $normalized = $Boundary.Trim().ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    switch -Regex ($normalized) {
        '^planning$' { return 'planning' }
        '^hardening-gate(?:-and-implementation-auth)?$' { return 'hardening-gate-and-implementation-auth' }
        '^hardening-gate-sign-?off$' { return 'hardening-gate-signoff' }
        '^hardening-gate-signoff$' { return 'hardening-gate-signoff' }
        '^implementation(?:-authorization)?$' { return 'implementation' }
        '^review$' { return 'review-boundary' }
        '^review-boundary$' { return 'review-boundary' }
        '^review-verdict-signoff$' { return 'review-verdict-signoff' }
        '^retro(?:spective)?(?:-boundary)?$' { return 'retro-boundary' }
        '^iteration-closeout$' { return 'iteration-closeout' }
        '^feature-closeout$' { return 'feature-closeout' }
        default { return $normalized.Trim('-') }
    }
}

function Get-InteractionModelSectionMap {
    param([AllowEmptyString()][string]$Text)

    $sectionMap = [ordered]@{}
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $sectionMap
    }

    $lines = $Text -replace "`r`n", "`n" -split "`n"
    $currentHeading = $null
    $currentLines = New-Object System.Collections.Generic.List[string]
    $headingPattern = '^(?:#{1,6}\s*)?(?:\*\*)?(What I just did|Why I stopped|What needs your review|What happens next|Discussion prompts|What I need from you)(?:\*\*)?\s*$'
    $canonicalHeadings = @{
        'what i just did'        = 'What I just did'
        'why i stopped'          = 'Why I stopped'
        'what needs your review' = 'What needs your review'
        'what happens next'      = 'What happens next'
        'discussion prompts'     = 'Discussion prompts'
        'what i need from you'   = 'What I need from you'
    }

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match $headingPattern) {
            if ($null -ne $currentHeading) {
                $sectionMap[$currentHeading] = ($currentLines -join "`n").Trim()
                $currentLines.Clear()
            }

            $currentHeading = $canonicalHeadings[$Matches[1].ToLowerInvariant()]
            continue
        }

        if ($null -ne $currentHeading) {
            $null = $currentLines.Add($line)
        }
    }

    if ($null -ne $currentHeading) {
        $sectionMap[$currentHeading] = ($currentLines -join "`n").Trim()
    }

    return $sectionMap
}

function Get-InteractionModelSections {
    param([AllowEmptyString()][string]$Text)

    $sectionMap = Get-InteractionModelSectionMap -Text $Text
    if ($sectionMap.Count -eq 0) {
        return @($(if ([string]::IsNullOrWhiteSpace($Text)) { '' } else { $Text.Trim() }))
    }

    return @($sectionMap.GetEnumerator() | ForEach-Object { [string]$_.Value })
}

function Get-InteractionModelBoundaryCommitMatch {
    param([AllowNull()][string]$Subject)

    if ([string]::IsNullOrWhiteSpace($Subject)) {
        return $null
    }

    foreach ($boundary in Get-InteractionModelBoundaryCatalog) {
        foreach ($pattern in $boundary.SubjectPatterns) {
            if ($Subject -match $pattern) {
                $featureNumber = if ($Subject -match 'Feature\s+(?<feature>\d+)') { [int]$Matches['feature'] } else { $null }
                $iterationNumber = if ($Subject -match 'iteration\s+(?<iteration>\d+)') { [int]$Matches['iteration'] } else { $null }
                return [pscustomobject]@{
                    Boundary      = $boundary.Name
                    StopLabel     = $boundary.StopLabel
                    FeatureNumber = $featureNumber
                    IterationNumber = $iterationNumber
                    Subject       = $Subject.Trim()
                }
            }
        }
    }

    return $null
}

function Get-InteractionModelSettings {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $settings = [ordered]@{
        BarePathBoundaryHandoffSeverity = 'soft-warning'
        ExemptionExtensions = @()
        ConfigIssues = @()
    }

    $configPath = Join-Path $ProjectRoot '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return [pscustomobject]$settings
    }

    $lines = @(Get-MarkdownContent -Path $configPath)
    $inInteractionModel = $false
    $inExemptions = $false
    $currentEntry = $null
    $extensions = New-Object System.Collections.Generic.List[object]

    foreach ($line in $lines) {
        if ($line -match '^\S') {
            if ($line -match '^interaction_model:\s*$') {
                $inInteractionModel = $true
                $inExemptions = $false
                continue
            }

            if ($inInteractionModel) {
                break
            }
        }

        if (-not $inInteractionModel) {
            continue
        }

        if ($line -match '^\s{2}bare_path_boundary_handoff_severity:\s*(?<value>\S.*?)\s*$') {
            $severity = $Matches['value'].Trim(" `t`r`n'`"")
            if ($severity -in @('soft-warning', 'validation-fail')) {
                $settings.BarePathBoundaryHandoffSeverity = $severity
            }
            else {
                $settings.ConfigIssues += "interaction_model bare_path_boundary_handoff_severity '$severity' is invalid; expected soft-warning or validation-fail."
            }
            continue
        }

        if ($line -match '^\s{2}exemption_extensions:\s*$') {
            $inExemptions = $true
            continue
        }

        if (-not $inExemptions) {
            continue
        }

        if ($line -match '^\s{4}-\s*id:\s*(?<value>\S.*?)\s*$') {
            if ($null -ne $currentEntry) {
                $extensions.Add([pscustomobject]$currentEntry) | Out-Null
            }

            $currentEntry = [ordered]@{
                Id = $Matches['value'].Trim(" `t`r`n'`"")
                Pattern = $null
                Approver = $null
                Rationale = $null
            }
            continue
        }

        if ($null -eq $currentEntry) {
            continue
        }

        if ($line -match '^\s{6}pattern:\s*(?<value>\S.*?)\s*$') {
            $currentEntry.Pattern = $Matches['value'].Trim(" `t`r`n'`"")
            continue
        }

        if ($line -match '^\s{6}approver:\s*(?<value>\S.*?)\s*$') {
            $currentEntry.Approver = $Matches['value'].Trim(" `t`r`n'`"")
            continue
        }

        if ($line -match '^\s{6}rationale:\s*(?<value>\S.*?)\s*$') {
            $currentEntry.Rationale = $Matches['value'].Trim(" `t`r`n'`"")
            continue
        }
    }

    if ($null -ne $currentEntry) {
        $extensions.Add([pscustomobject]$currentEntry) | Out-Null
    }

    foreach ($entry in $extensions) {
        if ([string]::IsNullOrWhiteSpace($entry.Pattern) -or [string]::IsNullOrWhiteSpace($entry.Approver) -or [string]::IsNullOrWhiteSpace($entry.Rationale)) {
            $settings.ConfigIssues += "interaction_model exemption extension '$($entry.Id)' must include pattern, approver, and rationale."
            continue
        }

        $settings.ExemptionExtensions += $entry
    }

    return [pscustomobject]$settings
}

function New-InteractionModelAuthorizationDecisionId {
    param(
        [Parameter(Mandatory = $true)][int]$FeatureNumber,
        [Parameter(Mandatory = $true)][int]$IterationNumber,
        [Parameter(Mandatory = $true)][string]$Boundary
    )

    $normalizedBoundary = (Normalize-InteractionModelBoundaryName -Boundary $Boundary) -replace '[^a-z0-9-]+', '-'
    return ('authorization-feature-{0:d3}-iter-{1:d3}-{2}' -f $FeatureNumber, $IterationNumber, $normalizedBoundary)
}

function Add-InteractionModelAuthorizationEntry {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][int]$FeatureNumber,
        [Parameter(Mandatory = $true)][int]$IterationNumber,
        [Parameter(Mandatory = $true)][string]$Boundary,
        [Parameter(Mandatory = $true)][ValidateSet('authorization', 'sign-off')][string]$Type,
        [Parameter(Mandatory = $true)][string]$ApprovingHuman,
        [Parameter(Mandatory = $true)][string]$AuthorizationText,
        [string]$CommitReference = 'pending',
        [string]$RecordedAt,
        [string]$DecisionId
    )

    $normalizedBoundary = Normalize-InteractionModelBoundaryName -Boundary $Boundary
    $effectiveDecisionId = if ([string]::IsNullOrWhiteSpace($DecisionId)) {
        New-InteractionModelAuthorizationDecisionId -FeatureNumber $FeatureNumber -IterationNumber $IterationNumber -Boundary $normalizedBoundary
    }
    else {
        $DecisionId.Trim()
    }

    $effectiveRecordedAt = if ([string]::IsNullOrWhiteSpace($RecordedAt)) {
        (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
    else {
        $RecordedAt.Trim()
    }

    $lines = @(
        "- **Decision ID**: $effectiveDecisionId"
        "- **Type**: $Type"
        "- **Boundary**: $normalizedBoundary"
        "- **Approving Human**: $ApprovingHuman"
        "- **Recorded At**: $effectiveRecordedAt"
        "- **Commit Reference**: $(Get-DecisionLedgerOptionalValue -Value $CommitReference)"
        '- **Authorization Text**:'
    ) + @($AuthorizationText -replace "`r`n", "`n" -split "`n" | ForEach-Object { "  > $_" })

    return Add-DecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title "Authorization: $normalizedBoundary" -Lines $lines
}

function Get-InteractionModelAuthorizationEntries {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [int]$FeatureNumber,
        [int]$IterationNumber
    )

    return @(
        Get-DecisionsLedgerEntries -ProjectRoot $ProjectRoot |
            Where-Object {
                $_.Type -in @('authorization', 'sign-off') -and
                (-not $PSBoundParameters.ContainsKey('FeatureNumber') -or [string]$_.DecisionId -match ("authorization-feature-{0:d3}\b" -f $FeatureNumber)) -and
                (-not $PSBoundParameters.ContainsKey('IterationNumber') -or [string]$_.DecisionId -match ("iter-{0:d3}\b" -f $IterationNumber))
            }
    )
}

function ConvertTo-InteractionModelUtcSeconds {
    param([Parameter(Mandatory = $true)][string]$Timestamp)

    if ([string]::IsNullOrWhiteSpace($Timestamp)) {
        throw 'Timestamp cannot be blank.'
    }

    try {
        $parsed = [datetimeoffset]::Parse(
            $Timestamp.Trim(),
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal
        )
    }
    catch {
        throw "Timestamp '$Timestamp' is not a valid ISO 8601 value."
    }

    return $parsed.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
}

function Set-InteractionModelAuthorizationMetadata {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$DecisionId,
        [AllowNull()][string]$CommitReference,
        [AllowNull()][string]$RecordedAt
    )

    if ([string]::IsNullOrWhiteSpace($DecisionId)) {
        throw 'DecisionId cannot be blank.'
    }

    $ledgerPath = Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
        throw "Decisions ledger not found at '$ledgerPath'."
    }

    $normalizedDecisionId = $DecisionId.Trim()
    $normalizedCommitReference = if ($PSBoundParameters.ContainsKey('CommitReference')) {
        if ([string]::IsNullOrWhiteSpace($CommitReference)) { 'pending' } else { $CommitReference.Trim() }
    }
    else {
        $null
    }

    $normalizedRecordedAt = if ($PSBoundParameters.ContainsKey('RecordedAt')) {
        ConvertTo-InteractionModelUtcSeconds -Timestamp $RecordedAt
    }
    else {
        $null
    }
    $updateCommitReference = $PSBoundParameters.ContainsKey('CommitReference')
    $updateRecordedAt = $PSBoundParameters.ContainsKey('RecordedAt')

    $updated = $false

    Update-LockedFileContent -Path $ledgerPath -Transform {
        param([string]$Content)

        $lines = @($Content -replace "`r`n", "`n" -split "`n")
        $insideTargetEntry = $false
        $foundDecision = $false
        $commitLineFound = $false
        $recordedAtLineFound = $false

        for ($index = 0; $index -lt $lines.Count; $index++) {
            $line = $lines[$index]

            if ($line -match '^##\s+') {
                if ($insideTargetEntry) {
                    break
                }

                $insideTargetEntry = $false
            }

            if ($line -match '^\s*-\s+\*\*Decision ID\*\*:\s*(.+?)\s*$' -and $Matches[1].Trim() -eq $normalizedDecisionId) {
                $insideTargetEntry = $true
                $foundDecision = $true
                continue
            }

            if (-not $insideTargetEntry) {
                continue
            }

            if ($updateRecordedAt -and $line -match '^\s*-\s+\*\*Recorded At\*\*:\s*.+$') {
                $lines[$index] = "- **Recorded At**: $normalizedRecordedAt"
                $recordedAtLineFound = $true
                $updated = $true
                continue
            }

            if ($updateCommitReference -and $line -match '^\s*-\s+\*\*Commit Reference\*\*:\s*.+$') {
                $lines[$index] = "- **Commit Reference**: $normalizedCommitReference"
                $commitLineFound = $true
                $updated = $true
                continue
            }
        }

        if (-not $foundDecision) {
            throw "Decision entry '$normalizedDecisionId' was not found in '$ledgerPath'."
        }

        if ($updateRecordedAt -and -not $recordedAtLineFound) {
            throw "Decision entry '$normalizedDecisionId' is missing a Recorded At line."
        }

        if ($updateCommitReference -and -not $commitLineFound) {
            throw "Decision entry '$normalizedDecisionId' is missing a Commit Reference line."
        }

        return (($lines -join "`n").TrimEnd() + "`n")
    } | Out-Null

    return [pscustomobject]@{
        DecisionId       = $normalizedDecisionId
        CommitReference  = $normalizedCommitReference
        RecordedAt       = $normalizedRecordedAt
        Updated          = $updated
        DecisionsLedger  = $ledgerPath
    }
}

function Sync-InteractionModelAuthorizationCommitReference {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$DecisionId,
        [Parameter(Mandatory = $true)][string]$CommitHash,
        [switch]$UseShortHash,
        [ValidateRange(7, 40)][int]$ShortHashLength = 7
    )

    if ([string]::IsNullOrWhiteSpace($CommitHash)) {
        throw 'CommitHash cannot be blank.'
    }

    $normalizedHash = $CommitHash.Trim()
    if ($normalizedHash -notmatch '^[a-fA-F0-9]{7,40}$') {
        throw "CommitHash '$CommitHash' is not a valid git hash."
    }

    $effectiveCommitReference = if ($UseShortHash) {
        if ($ShortHashLength -gt $normalizedHash.Length) {
            throw "ShortHashLength $ShortHashLength exceeds commit hash length $($normalizedHash.Length)."
        }

        $normalizedHash.Substring(0, $ShortHashLength)
    }
    else {
        $normalizedHash
    }

    return Set-InteractionModelAuthorizationMetadata -ProjectRoot $ProjectRoot -DecisionId $DecisionId -CommitReference $effectiveCommitReference
}

function Get-InteractionModelFileUris {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    return @(
        [regex]::Matches($Text, '(?i)file:///[^\s)`"''<>]+') |
            ForEach-Object { $_.Value.TrimEnd(',', '.', ';', ':') } |
            Select-Object -Unique
    )
}

function Convert-InteractionModelFileUriToWindowsPath {
    param([Parameter(Mandatory = $true)][string]$FileUri)

    try {
        $uri = [System.Uri]::new($FileUri)
    }
    catch {
        throw "File URI '$FileUri' is invalid."
    }

    if (-not $uri.IsAbsoluteUri -or $uri.Scheme -ne 'file') {
        throw "URI '$FileUri' is not an absolute file:/// URI."
    }

    return [System.IO.Path]::GetFullPath($uri.LocalPath)
}

function Invoke-InteractionModelStaleReferenceScan {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowEmptyString()][string]$Text
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $missingReferences = New-Object System.Collections.Generic.List[string]
    $checkedReferences = New-Object System.Collections.Generic.List[string]

    foreach ($fileUri in @(Get-InteractionModelFileUris -Text $Text)) {
        $checkedReferences.Add($fileUri) | Out-Null
        try {
            $path = Convert-InteractionModelFileUriToWindowsPath -FileUri $fileUri
        }
        catch {
            $missingReferences.Add($fileUri) | Out-Null
            continue
        }

        if (-not $path.StartsWith($resolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $missingReferences.Add($fileUri) | Out-Null
            continue
        }

        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $missingReferences.Add($fileUri) | Out-Null
        }
    }

    return [pscustomobject]@{
        Status            = if ($missingReferences.Count -gt 0) { 'needs-fix' } else { 'clean' }
        CheckedReferences = $checkedReferences.ToArray()
        MissingReferences = $missingReferences.ToArray()
    }
}

function Get-MarkdownContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-MarkdownMetadataValue {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $pattern = '^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(.+?)\s*$'
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }

    return $null
}

function Get-MarkdownSectionTable {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [string]$Heading
    )

    $headingPattern = '^#{2,3}\s+' + [regex]::Escape($Heading) + '\b'
    $startIndex = -1

    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $headingPattern) {
            $startIndex = $index
            break
        }
    }

    if ($startIndex -lt 0) {
        return @()
    }

    $tableLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        $currentLine = $Lines[$index]
        if ($currentLine -match '^#{2,3}\s+') {
            break
        }

        if ($currentLine.Trim().StartsWith('|')) {
            $null = $tableLines.Add($currentLine)
        }
    }

    if ($tableLines.Count -lt 2) {
        return @()
    }

    $headers = ($tableLines[0].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
    $rows = New-Object System.Collections.Generic.List[object]

    for ($rowIndex = 1; $rowIndex -lt $tableLines.Count; $rowIndex++) {
        $cells = ($tableLines[$rowIndex].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
        $isSeparator = $true

        foreach ($cell in $cells) {
            if ($cell -notmatch '^:?-{3,}:?$') {
                $isSeparator = $false
                break
            }
        }

        if ($isSeparator) {
            continue
        }

        $row = [ordered]@{}
        for ($cellIndex = 0; $cellIndex -lt $headers.Count; $cellIndex++) {
            $value = if ($cellIndex -lt $cells.Count) { $cells[$cellIndex] } else { '' }
            $row[$headers[$cellIndex]] = $value
        }

        $rows.Add([pscustomobject]$row)
    }

    return $rows.ToArray()
}

function Get-MarkdownSectionLines {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [string]$Heading
    )

    $headingPattern = '^#{2,3}\s+' + [regex]::Escape($Heading) + '\b'
    $startIndex = -1

    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $headingPattern) {
            $startIndex = $index
            break
        }
    }

    if ($startIndex -lt 0) {
        return @()
    }

    $sectionLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        $currentLine = $Lines[$index]
        if ($currentLine -match '^#{2,3}\s+') {
            break
        }

        $null = $sectionLines.Add($currentLine)
    }

    return $sectionLines.ToArray()
}

function Normalize-MarkdownCell {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return $Value.Trim().Trim('`')
}

function Get-ObjectPropertyString {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$PropertyNames
    )

    foreach ($propertyName in $PropertyNames) {
        $property = $InputObject.PSObject.Properties[$propertyName]
        if ($null -ne $property) {
            return [string]$property.Value
        }
    }

    return $null
}

function Test-IsNullish {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    return $Value.Trim() -match '^(?:—|-|none|null|n/a|\(none\)|blank|tbd|unknown)$'
}

function Find-LineNumberByPattern {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines,
        [string]$Pattern,
        [switch]$CaseSensitive
    )

    if ($null -eq $Lines -or [string]::IsNullOrWhiteSpace($Pattern)) {
        return $null
    }

    for ($index = 0; $index -lt $Lines.Count; $index++) {
        $isMatch = if ($CaseSensitive) {
            $Lines[$index] -cmatch $Pattern
        }
        else {
            $Lines[$index] -match $Pattern
        }

        if ($isMatch) {
            return ($index + 1)
        }
    }

    return $null
}

function New-StructuredValidationFailureText {
    param(
        [AllowNull()][string]$FilePath,
        [AllowNull()][int]$LineNumber,
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$RemediationHint
    )

    $resolvedFilePath = if ([string]::IsNullOrWhiteSpace($FilePath)) { '(none)' } else { $FilePath.Trim() }
    $resolvedLineNumber = if ($null -eq $LineNumber -or $LineNumber -le 0) { '(none)' } else { [string]$LineNumber }
    return 'file_path={0} | line_number={1} | category={2} | message={3} | remediation_hint={4}' -f $resolvedFilePath, $resolvedLineNumber, $Category.Trim(), $Message.Trim(), $RemediationHint.Trim()
}

function Add-StructuredValidationFailure {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Errors,

        [AllowNull()][string]$FilePath,
        [AllowNull()][int]$LineNumber,
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$RemediationHint
    )

    $Errors.Add((New-StructuredValidationFailureText -FilePath $FilePath -LineNumber $LineNumber -Category $Category -Message $Message -RemediationHint $RemediationHint)) | Out-Null
}

function Get-FeatureOrdinalFromIterationDirectory {
    param([AllowNull()][string]$IterationDirectory)

    if ([string]::IsNullOrWhiteSpace($IterationDirectory)) {
        return $null
    }

    $normalized = $IterationDirectory -replace '/', '\'
    $match = [regex]::Match($normalized, '[\\/]specs[\\/](?<feature>\d+)-[^\\/]+[\\/]iterations[\\/]')
    if ($match.Success) {
        return [int]$match.Groups['feature'].Value
    }

    return $null
}

function Test-IterationRequiresCanonicalStateSchema {
    param([AllowNull()][string]$IterationDirectory)

    $featureOrdinal = Get-FeatureOrdinalFromIterationDirectory -IterationDirectory $IterationDirectory
    if ($null -eq $featureOrdinal) {
        return $true
    }

    return $featureOrdinal -ge 13
}

function Test-IterationRequiresCanonicalHardeningConcerns {
    param([AllowNull()][string]$IterationDirectory)

    $featureOrdinal = Get-FeatureOrdinalFromIterationDirectory -IterationDirectory $IterationDirectory
    if ($null -eq $featureOrdinal) {
        return $true
    }

    return $featureOrdinal -ge 13
}

function Get-CanonicalIterationStateFields {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $contractPath = Join-Path $ProjectRoot 'specs\013-validator-hardening\contracts\iteration-state-schema.md'
    if (Test-Path -LiteralPath $contractPath -PathType Leaf) {
        $rows = @(Get-MarkdownSectionTable -Lines (Get-MarkdownContent -Path $contractPath) -Heading 'Canonical Fields')
        if ($rows.Count -gt 0) {
            return @(
                $rows |
                    ForEach-Object {
                        [pscustomobject]@{
                            FieldName = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Field Name'))
                        }
                    } |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_.FieldName) }
            )
        }
    }

    return @(
        [pscustomobject]@{ FieldName = 'Schema' },
        [pscustomobject]@{ FieldName = 'Last Completed Task' },
        [pscustomobject]@{ FieldName = 'Tasks Remaining' },
        [pscustomobject]@{ FieldName = 'In Progress' },
        [pscustomobject]@{ FieldName = 'Baseline Ref' },
        [pscustomobject]@{ FieldName = 'Updated' },
        [pscustomobject]@{ FieldName = 'Current Phase' },
        [pscustomobject]@{ FieldName = 'Iteration Status' }
    )
}

function Get-CanonicalHardeningConcernDefinitions {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $contractPath = Join-Path $ProjectRoot 'specs\013-validator-hardening\contracts\hardening-gate-concerns.md'
    if (Test-Path -LiteralPath $contractPath -PathType Leaf) {
        $rows = @(Get-MarkdownSectionTable -Lines (Get-MarkdownContent -Path $contractPath) -Heading 'Canonical Concerns')
        if ($rows.Count -gt 0) {
            return @(
                $rows |
                    ForEach-Object {
                        $positionText = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Position'))
                        $position = $null
                        if ($positionText -match '^\d+$') {
                            $position = [int]$positionText
                        }

                        [pscustomobject]@{
                            Position  = $position
                            ConcernId = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Concern ID'))
                        }
                    } |
                    Where-Object { $null -ne $_.Position -and -not [string]::IsNullOrWhiteSpace($_.ConcernId) } |
                    Sort-Object Position
            )
        }
    }

    return @(
        [pscustomobject]@{ Position = 1; ConcernId = 'security-surface' },
        [pscustomobject]@{ Position = 2; ConcernId = 'error-handling-expectations' },
        [pscustomobject]@{ Position = 3; ConcernId = 'retry-idempotency-requirements' },
        [pscustomobject]@{ Position = 4; ConcernId = 'test-integrity-targets' },
        [pscustomobject]@{ Position = 5; ConcernId = 'operational-resilience-concerns' }
    )
}

function Normalize-ApprovalEvidenceQuote {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    $normalized = $Value.Trim()
    $normalized = $normalized -replace '[*_]', ''
    $normalized = $normalized -replace '\s+', ' '
    return $normalized.Trim(" `t`r`n'`"")
}

function Test-BlanketAuthorizationScopeDeclared {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    foreach ($line in @($Lines)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $normalized = $line.ToLowerInvariant()
        if ($normalized.Contains('blanket') -and $normalized.Contains('multi-iteration authorization')) {
            return $true
        }
    }

    return $false
}

function Test-SpecrewHandoffBlockPresent {
    param(
        [AllowEmptyString()]
        [AllowNull()]
        [string]$CommitMessage = '',

        [AllowNull()]
        [object]$SessionMetadata = $null
    )

    $candidateTexts = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($CommitMessage)) {
        $candidateTexts.Add([string]$CommitMessage) | Out-Null
    }

    if ($null -ne $SessionMetadata) {
        foreach ($propertyName in @('response_text', 'ResponseText', 'handoff_text', 'HandoffText', 'text', 'Text')) {
            $property = $SessionMetadata.PSObject.Properties[$propertyName]
            if ($null -ne $property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                $candidateTexts.Add([string]$property.Value) | Out-Null
            }
        }
    }

    foreach ($candidateText in $candidateTexts) {
        if ($candidateText -match '(?ms)===\s*SPECREW HANDOFF\s*===.+?===\s*END SPECREW HANDOFF\s*===') {
            return $true
        }
    }

    return $false
}

function Add-SpecrewHandoffEvidence {
    <#
    .SYNOPSIS
    Pillar 1 live producer (Proposal 120 / FR-018): append a boundary_event to
    .specrew/handoff-evidence.json recording whether a === SPECREW HANDOFF === block accompanied a
    boundary/lifecycle stop, so Test-HandoffEvidenceGovernance detects missing handoffs in REAL runs
    rather than only against the synthesized F-047 fixture.

    .DESCRIPTION
    The coordinator passes its emitted handoff block via -HandoffText at boundary-sync time. An event
    whose response_text lacks the sentinel surfaces a missing-handoff WARN. Idempotent per
    (commit, boundary): re-syncing the same crossing replaces that event rather than duplicating, so a
    later handoff-bearing sync supersedes an earlier empty one (and vice versa) — no stale false-pass.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Boundary,
        [AllowNull()][string]$Commit,
        [AllowNull()][string]$HandoffText,
        [AllowNull()][string]$RecordedAt
    )

    $resolvedRoot = Resolve-ProjectPath -Path $ProjectRoot
    $specrewDir = Join-Path $resolvedRoot '.specrew'
    if (-not (Test-Path -LiteralPath $specrewDir -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $specrewDir -Force
    }
    $evidencePath = Join-Path $specrewDir 'handoff-evidence.json'

    $events = New-Object System.Collections.Generic.List[object]
    if (Test-Path -LiteralPath $evidencePath -PathType Leaf) {
        try {
            $parsed = Get-Content -LiteralPath $evidencePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
            $existing = if ($parsed -is [array]) { $parsed }
            elseif ($null -ne $parsed -and $null -ne $parsed.PSObject.Properties['boundary_events']) { $parsed.boundary_events }
            else { @() }
            foreach ($e in @($existing)) { if ($null -ne $e) { $events.Add($e) | Out-Null } }
        }
        catch {
            # Corrupt evidence file: start fresh (the detector warns separately on unreadable input).
        }
    }

    $commitValue = if ([string]::IsNullOrWhiteSpace($Commit)) { '' } else { $Commit.Trim() }
    $recordedValue = if ([string]::IsNullOrWhiteSpace($RecordedAt)) { (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') } else { $RecordedAt.Trim() }
    $textValue = if ($null -eq $HandoffText) { '' } else { [string]$HandoffText }
    $hasBlock = Test-SpecrewHandoffBlockPresent -CommitMessage $textValue

    $filtered = New-Object System.Collections.Generic.List[object]
    foreach ($e in $events) {
        $ec = ''; $eb = ''
        $pc = $e.PSObject.Properties['commit']; if ($pc) { $ec = [string]$pc.Value }
        $pb = $e.PSObject.Properties['boundary']; if ($pb) { $eb = [string]$pb.Value }
        if ($ec -eq $commitValue -and $eb -eq $Boundary) { continue }
        $filtered.Add($e) | Out-Null
    }
    $filtered.Add([pscustomobject][ordered]@{
            commit          = $commitValue
            boundary        = $Boundary
            response_text   = $textValue
            handoff_present = $hasBlock
            recorded_at     = $recordedValue
        }) | Out-Null

    $payload = [ordered]@{ schema = 'v1'; boundary_events = @($filtered.ToArray()) }
    $payload | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $evidencePath -Encoding UTF8
}

function Test-ReviewCitedFilesInTree {
    <#
    .SYNOPSIS
    Pillar 5 (Proposal 120 / FR-022): verify production files cited as delivered evidence in a
    review.md actually exist in the cited "Tree Under Review" commit.

    .DESCRIPTION
    Parses `**Tree Under Review**: <hash>` and the file paths cited in the review prose, then runs
    `git ls-tree -r <hash>` (read-only) to confirm presence. The dangerous Shape-5 case (PlanningPoC
    iter-004) is a production file cited as delivered that is present in the WORKING TREE but absent
    from the cited commit — i.e., accepted against working-tree-only state that can vanish via
    `git reset`/`clean`/fresh clone. That precise shape is returned as MissingProduction (FAIL-worthy);
    keying on working-tree presence avoids false hard-fails on paths merely mentioned in prose.

    Returns a [pscustomobject]:
      TreeHash          : parsed commit hash, or $null when review.md cites none
      TreeResolved      : $true when `git ls-tree` resolved the hash
      CheckedCount      : number of distinct cited code/config/doc paths examined
      MissingProduction : production files cited + absent from the tree + present in the working tree (FAIL)
      MissingTest       : test files cited + absent from the tree (WARN, AC10)
      UnresolvedCited   : cited production files absent from BOTH the tree and the working tree (WARN)
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowNull()][AllowEmptyString()][string[]]$ReviewLines,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $result = [pscustomobject]@{
        TreeHash          = $null
        TreeResolved      = $false
        CheckedCount      = 0
        MissingProduction = @()
        MissingTest       = @()
        UnresolvedCited   = @()
    }

    $reviewText = (@($ReviewLines) -join "`n")
    if ([string]::IsNullOrWhiteSpace($reviewText)) { return $result }

    $treeMatch = [regex]::Match($reviewText, '(?im)^\s*\*\*Tree Under Review\*\*\s*:\s*`?([0-9a-fA-F]{7,40})`?')
    if (-not $treeMatch.Success) { return $result }
    $treeHash = $treeMatch.Groups[1].Value
    $result.TreeHash = $treeHash

    $tracked = @()
    try {
        $lsTree = & git -C $ProjectRoot ls-tree -r --name-only $treeHash 2>$null
        if ($LASTEXITCODE -eq 0 -and $null -ne $lsTree) {
            $tracked = @($lsTree | ForEach-Object { ($_ -replace '\\', '/').Trim() } | Where-Object { $_ })
            $result.TreeResolved = $true
        }
    }
    catch {
        # git unavailable or bad hash: leave TreeResolved = $false; caller decides severity.
    }
    if (-not $result.TreeResolved) { return $result }

    $trackedSet = @{}
    foreach ($t in $tracked) { $trackedSet[$t] = $true }

    $citedSet = @{}
    $pathRegex = [regex]'(?<path>(?:[\w.\-]+/)+[\w.\-]+\.(?:cs|tsx|ts|jsx|js|py|rs|go|ps1|psm1|psd1|java|rb|php|sql|md|ya?ml|json))'
    foreach ($m in $pathRegex.Matches($reviewText)) {
        $p = ($m.Groups['path'].Value -replace '\\', '/').Trim()
        $p = $p -replace '^\./', ''
        if ($p) { $citedSet[$p] = $true }
    }

    $productionExt = @('.cs', '.tsx', '.ts', '.jsx', '.js', '.py', '.rs', '.go', '.ps1', '.psm1', '.java', '.rb', '.php')
    $missingProd = New-Object System.Collections.Generic.List[string]
    $missingTest = New-Object System.Collections.Generic.List[string]
    $unresolved = New-Object System.Collections.Generic.List[string]

    foreach ($cited in $citedSet.Keys) {
        $result.CheckedCount++
        if ($trackedSet.ContainsKey($cited)) { continue }

        $ext = [System.IO.Path]::GetExtension($cited).ToLowerInvariant()
        $isTest = ($cited -match '(?i)(^|/)tests?/') -or ($cited -match '(?i)\.(test|spec|tests)\.')
        $onDisk = Test-Path -LiteralPath (Join-Path $ProjectRoot ($cited -replace '/', [System.IO.Path]::DirectorySeparatorChar)) -PathType Leaf

        if ($isTest) {
            $missingTest.Add($cited) | Out-Null
        }
        elseif ($productionExt -contains $ext) {
            if ($onDisk) { $missingProd.Add($cited) | Out-Null }
            else { $unresolved.Add($cited) | Out-Null }
        }
        # non-production, non-test (docs/config) absent → ignored (often illustrative references)
    }

    $result.MissingProduction = $missingProd.ToArray()
    $result.MissingTest = $missingTest.ToArray()
    $result.UnresolvedCited = $unresolved.ToArray()
    return $result
}

function Get-ImplementationApprovalEvidenceRecords {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $records = New-Object System.Collections.Generic.List[object]
    $artifacts = @('plan.md', 'state.md')
    $headings = @('Implementation Authorization', 'Implementation Approval')
    $evidenceLabels = @(
        'Recorded Evidence',
        'Implementation Approval Evidence',
        'Implementation Approval',
        'Approval Evidence',
        'Evidence Statement',
        'Recorded Quote',
        'Authorization Quote'
    )

    foreach ($artifactName in $artifacts) {
        $artifactPath = Join-Path $IterationDirectory $artifactName
        if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
            continue
        }

        $lines = @(Get-MarkdownContent -Path $artifactPath)
        $relativeArtifactPath = ([System.IO.Path]::GetRelativePath($ProjectRoot, $artifactPath)) -replace '/', '\'

        foreach ($heading in $headings) {
            $sectionLines = @(Get-MarkdownSectionLines -Lines $lines -Heading $heading)
            if ($sectionLines.Count -eq 0) {
                continue
            }

            $blanketScopeDeclared = Test-BlanketAuthorizationScopeDeclared -Lines $sectionLines
            foreach ($sectionLine in $sectionLines) {
                $trimmedLine = $sectionLine.Trim()
                if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
                    continue
                }

                $rawText = $null
                foreach ($label in $evidenceLabels) {
                    $pattern = '^(?:-\s*)?\*\*' + [regex]::Escape($label) + '\*\*:\s*(.+?)\s*$'
                    if ($trimmedLine -match $pattern) {
                        $rawText = $Matches[1].Trim()
                        break
                    }
                }

                if ([string]::IsNullOrWhiteSpace($rawText) -and $trimmedLine -match '^(?:-\s*)?["“](.+?)["”]\s*$') {
                    $rawText = $Matches[1].Trim()
                }

                if ([string]::IsNullOrWhiteSpace($rawText)) {
                    continue
                }

                $normalizedText = Normalize-ApprovalEvidenceQuote -Value $rawText
                if ([string]::IsNullOrWhiteSpace($normalizedText)) {
                    continue
                }

                $escapedLine = [regex]::Escape($sectionLine)
                $lineNumber = Find-LineNumberByPattern -Lines $lines -Pattern ('^\s*' + $escapedLine + '\s*$')

                $records.Add([pscustomobject]@{
                        ArtifactPath          = $artifactPath
                        RelativeArtifactPath  = $relativeArtifactPath
                        Heading               = $heading
                        RawText               = $rawText
                        NormalizedText        = $normalizedText
                        BlanketScopeDeclared  = $blanketScopeDeclared
                        LineNumber            = $lineNumber
                    }) | Out-Null
            }
        }
    }

    return $records.ToArray()
}

function Test-ClosedIterationStatus {
    param([AllowNull()][string]$IterationStatus)

    if (Test-IsNullish $IterationStatus) {
        return $false
    }

    $normalized = $IterationStatus.ToLowerInvariant()
    return ($normalized -match '\bclosed\b') -or
        ($normalized -match '\bcloseout complete\b') -or
        ($normalized -match '\bclosure complete\b')
}

function Convert-ToDecisionReferenceId {
    param([AllowNull()][string]$ApprovalRef)

    $normalized = Normalize-MarkdownCell $ApprovalRef
    if (Test-IsNullish $normalized) {
        return $null
    }

    if ($normalized -match '(?i)\.squad\\decisions\.md#(?<id>[a-z0-9][a-z0-9-]*)') {
        return $Matches['id'].Trim()
    }

    if ($normalized -match '(?i)#(?<id>[a-z0-9][a-z0-9-]*)$') {
        return $Matches['id'].Trim()
    }

    if ($normalized -match '(?i)\b(?<id>(?:decision|defer|escalation|routing-evidence|clarify-skip|review-gap)-[a-f0-9]{12})\b') {
        return $Matches['id'].Trim()
    }

    return $normalized
}

function Get-ApprovalReferenceRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()][string]$ApprovalRef,

        [string[]]$AllowedTypes = @()
    )

    $normalizedRef = Normalize-MarkdownCell $ApprovalRef
    if (Test-IsNullish $normalizedRef) {
        return $null
    }

    $decisionId = Convert-ToDecisionReferenceId -ApprovalRef $normalizedRef
    $matches = @(
        Get-DecisionsLedgerEntries -ProjectRoot $ProjectRoot |
            Where-Object {
                ($_.DecisionId -eq $decisionId -or $_.Title -eq $normalizedRef) -and
                ($AllowedTypes.Count -eq 0 -or $_.Type -in $AllowedTypes)
            } |
            Select-Object -First 1
    )

    if ($matches.Count -eq 0) {
        return [pscustomobject]@{
            ApprovalRef      = $normalizedRef
            DecisionId       = $decisionId
            Entry            = $null
            HasHumanApproval = $false
            ApprovingHuman   = $null
            Type             = $null
        }
    }

    $entry = $matches[0]
    return [pscustomobject]@{
        ApprovalRef      = $normalizedRef
        DecisionId       = $entry.DecisionId
        Entry            = $entry
        HasHumanApproval = -not (Test-IsNullish $entry.ApprovingHuman)
        ApprovingHuman   = $entry.ApprovingHuman
        Type             = $entry.Type
    }
}

function Test-ApprovalReferenceHasHumanApproval {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()][string]$ApprovalRef,

        [string[]]$AllowedTypes = @()
    )

    $record = Get-ApprovalReferenceRecord -ProjectRoot $ProjectRoot -ApprovalRef $ApprovalRef -AllowedTypes $AllowedTypes
    return $null -ne $record -and $record.HasHumanApproval
}

function ConvertTo-BooleanMarkdownValue {
    param([AllowNull()][string]$Value)

    $normalized = Normalize-MarkdownCell $Value
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $false
    }

    return $normalized.ToLowerInvariant() -in @('true', 'yes', '1')
}

function Get-HardeningConcernEvidenceProjection {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Concern
    )

    $status = (Normalize-MarkdownCell ([string]$Concern.Status)).ToLowerInvariant()
    $explicitEvidenceBasis = Normalize-MarkdownCell ([string]$Concern.EvidenceBasis)
    $explicitRuntimeEvidenceStatus = Normalize-MarkdownCell ([string]$Concern.RuntimeEvidenceStatus)
    $explicitExpectedControls = Normalize-MarkdownCell ([string]$Concern.ExpectedControls)
    $hasExplicitEvidenceFields = -not (
        (Test-IsNullish $explicitEvidenceBasis) -and
        (Test-IsNullish $explicitRuntimeEvidenceStatus) -and
        (Test-IsNullish $explicitExpectedControls)
    )

    $evidenceBasis = $explicitEvidenceBasis
    $runtimeEvidenceStatus = $explicitRuntimeEvidenceStatus
    $expectedControls = $explicitExpectedControls

    if (-not $hasExplicitEvidenceFields) {
        switch ($status) {
            'addressed' {
                $evidenceBasis = 'planning-time-analysis'
                $runtimeEvidenceStatus = 'pending-post-implementation'
                $expectedControls = Normalize-MarkdownCell ([string]$Concern.Rationale)
            }
            'deferred-with-approval' {
                $evidenceBasis = 'planning-time-analysis'
                $runtimeEvidenceStatus = 'pending-post-implementation'
                $expectedControls = Normalize-MarkdownCell ([string]$Concern.Rationale)
            }
            'not-applicable' {
                $evidenceBasis = 'not-applicable'
                $runtimeEvidenceStatus = 'not-needed'
                $expectedControls = '—'
            }
            default {
                $evidenceBasis = '—'
                $runtimeEvidenceStatus = '—'
                $expectedControls = '—'
            }
        }
    }

    return [pscustomobject]@{
        Status                     = $status
        EvidenceBasis              = $evidenceBasis
        RuntimeEvidenceStatus      = $runtimeEvidenceStatus
        ExpectedControls           = $expectedControls
        HasExplicitEvidenceFields  = $hasExplicitEvidenceFields
    }
}

function Get-HardeningConcernEvaluation {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Concern,

        [string]$ProjectRoot
    )

    $issues = New-Object System.Collections.Generic.List[string]
    $status = (Normalize-MarkdownCell ([string]$Concern.Status)).ToLowerInvariant()
    $rationale = Normalize-MarkdownCell ([string]$Concern.Rationale)
    $approvalRef = Normalize-MarkdownCell ([string]$Concern.Approval)
    $evidence = Get-HardeningConcernEvidenceProjection -Concern $Concern
    $evidenceBasis = (Normalize-MarkdownCell ([string]$evidence.EvidenceBasis)).ToLowerInvariant()
    $runtimeEvidenceStatus = (Normalize-MarkdownCell ([string]$evidence.RuntimeEvidenceStatus)).ToLowerInvariant()
    $expectedControls = Normalize-MarkdownCell ([string]$evidence.ExpectedControls)
    $approvalRecord = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $null
    }
    else {
        Get-ApprovalReferenceRecord -ProjectRoot $ProjectRoot -ApprovalRef $approvalRef -AllowedTypes @('decision', 'defer')
    }

    if (Test-IsNullish $rationale) {
        $issues.Add('must record rationale for the current hardening disposition') | Out-Null
    }

    switch ($status) {
        'addressed' {
            if ($evidence.HasExplicitEvidenceFields) {
                if ($evidenceBasis -notin @('planning-time-analysis', 'runtime-evidence')) {
                    $issues.Add("must use Evidence Basis 'planning-time-analysis' before closure or 'runtime-evidence' once runtime proof is recorded") | Out-Null
                }

                if (Test-IsNullish $expectedControls) {
                    $issues.Add('must record Expected Controls before implementation can proceed') | Out-Null
                }

                switch ($evidenceBasis) {
                    'planning-time-analysis' {
                        if ($runtimeEvidenceStatus -notin @('pending-post-implementation', 'not-needed')) {
                            $issues.Add("must keep Runtime Evidence Status 'pending-post-implementation' or 'not-needed' when Evidence Basis is planning-time-analysis") | Out-Null
                        }
                    }
                    'runtime-evidence' {
                        if ($runtimeEvidenceStatus -ne 'recorded') {
                            $issues.Add("must keep Runtime Evidence Status 'recorded' when Evidence Basis is runtime-evidence") | Out-Null
                        }
                    }
                }
            }
        }
        'not-applicable' {
            if ($evidence.HasExplicitEvidenceFields) {
                if ($evidenceBasis -ne 'not-applicable') {
                    $issues.Add("must use Evidence Basis 'not-applicable' when Status is not-applicable") | Out-Null
                }

                if ($runtimeEvidenceStatus -ne 'not-needed') {
                    $issues.Add("must use Runtime Evidence Status 'not-needed' when Status is not-applicable") | Out-Null
                }
            }
        }
        'deferred-with-approval' {
            if ($evidence.HasExplicitEvidenceFields) {
                if ($evidenceBasis -ne 'planning-time-analysis') {
                    $issues.Add("must keep Evidence Basis 'planning-time-analysis' when Status is deferred-with-approval") | Out-Null
                }

                if ($runtimeEvidenceStatus -ne 'pending-post-implementation') {
                    $issues.Add("must keep Runtime Evidence Status 'pending-post-implementation' when Status is deferred-with-approval") | Out-Null
                }

                if (Test-IsNullish $expectedControls) {
                    $issues.Add('must keep Expected Controls visible when Status is deferred-with-approval') | Out-Null
                }
            }

            if (Test-IsNullish $approvalRef) {
                $issues.Add('must record a human-approved Approval reference when Status is deferred-with-approval') | Out-Null
            }
            elseif (-not [string]::IsNullOrWhiteSpace($ProjectRoot) -and ($null -eq $approvalRecord -or -not $approvalRecord.HasHumanApproval)) {
                $issues.Add(("approval reference '{0}' is missing explicit human approval evidence" -f $approvalRef)) | Out-Null
            }
        }
        default {
            $issues.Add('must resolve the concern before implementation can proceed') | Out-Null
            if ($evidenceBasis -ne 'planning-time-analysis') {
                $issues.Add("must record planning-time analysis before implementation can proceed") | Out-Null
            }
            if (Test-IsNullish $expectedControls) {
                $issues.Add('must record Expected Controls before implementation can proceed') | Out-Null
            }
        }
    }

    $blocksClosure = $false
    switch ($status) {
        'addressed' {
            $blocksClosure = $runtimeEvidenceStatus -eq 'pending-post-implementation'
        }
        'deferred-with-approval' {
            $blocksClosure = $true
        }
        'not-applicable' {
            $blocksClosure = $false
        }
        default {
            $blocksClosure = $true
        }
    }

    return [pscustomobject]@{
        Status                    = $status
        EvidenceBasis             = $evidence.EvidenceBasis
        RuntimeEvidenceStatus     = $evidence.RuntimeEvidenceStatus
        ExpectedControls          = $evidence.ExpectedControls
        HasExplicitEvidenceFields = $evidence.HasExplicitEvidenceFields
        ApprovalRecord            = $approvalRecord
        Issues                    = $issues.ToArray()
        BlocksImplementation      = $issues.Count -gt 0
        BlocksClosure             = $blocksClosure
        HasHumanApproval          = -not [string]::IsNullOrWhiteSpace($approvalRef) -and ($null -ne $approvalRecord -and $approvalRecord.HasHumanApproval)
    }
}

# ============================================================================
# Reviewer-Regression Governance Functions (Spec 008 Extension)
# ============================================================================

function Get-ReviewerRegressionLedgerPath {
    <#
    .SYNOPSIS
    Returns the path to the reviewer-regression ledger.
    
    .PARAMETER ProjectRoot
    The root directory of the project.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    return Join-Path $ProjectRoot '.specrew\reviewer-regression-log.md'
}

function Get-ReviewerRegressionLedgerEntries {
    <#
    .SYNOPSIS
    Parses the reviewer-regression ledger and returns all event entries.
    
    .PARAMETER ProjectRoot
    The root directory of the project.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $ledgerPath = Get-ReviewerRegressionLedgerPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
        return @()
    }

    $lines = @(Get-Content -LiteralPath $ledgerPath -Encoding UTF8)
    $entries = New-Object System.Collections.Generic.List[object]
    $eventRegex = '^#{3}\s+(RRE-\d{3,})\s*$'

    $currentEventId = $null
    $currentLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        $eventMatch = [regex]::Match($line, $eventRegex)
        if ($eventMatch.Success) {
            if ($null -ne $currentEventId) {
                $entries.Add((New-ReviewerRegressionEventEntry -EventId $currentEventId -EntryLines $currentLines)) | Out-Null
            }

            $currentEventId = $eventMatch.Groups[1].Value.Trim()
            $currentLines = New-Object System.Collections.Generic.List[string]
            continue
        }

        if ($null -ne $currentEventId) {
            $currentLines.Add($line) | Out-Null
        }
    }

    if ($null -ne $currentEventId) {
        $entries.Add((New-ReviewerRegressionEventEntry -EventId $currentEventId -EntryLines $currentLines)) | Out-Null
    }

    return $entries.ToArray()
}

function New-ReviewerRegressionEventEntry {
    <#
    .SYNOPSIS
    Creates a parsed reviewer-regression event object from ledger lines.
    
    .PARAMETER EventId
    The event identifier (e.g., RRE-001).
    
    .PARAMETER EntryLines
    The raw lines from the ledger entry.
    #>
    param(
        [string]$EventId,
        [System.Collections.Generic.List[string]]$EntryLines
    )

    $rawText = $EntryLines -join "`n"
    
    return [pscustomobject]@{
        EventId                = $EventId
        Feature                = Get-LedgerFieldValue -RawText $rawText -Label 'Feature'
        Iteration              = Get-LedgerFieldValue -RawText $rawText -Label 'Iteration'
        Slice                  = Get-LedgerFieldValue -RawText $rawText -Label 'Slice'
        PriorReviewerVerdict   = Get-LedgerFieldValue -RawText $rawText -Label 'Prior Reviewer Verdict'
        PriorReviewerClass     = Get-LedgerFieldValue -RawText $rawText -Label 'Prior Reviewer Class'
        PriorReviewerOwner     = Get-LedgerFieldValue -RawText $rawText -Label 'Prior Reviewer Owner'
        DefectDescription      = Get-LedgerFieldValue -RawText $rawText -Label 'Defect Description'
        DefectSourceLocation   = Get-LedgerFieldValue -RawText $rawText -Label 'Defect Source Location'
        EventStatus            = Get-LedgerFieldValue -RawText $rawText -Label 'Event Status'
        Severity               = Get-LedgerFieldValue -RawText $rawText -Label 'Severity'
        EscalationAction       = Get-LedgerFieldValue -RawText $rawText -Label 'Escalation Action'
        EscalatedToClass       = Get-LedgerFieldValue -RawText $rawText -Label 'Escalated To Class'
        SelectedReviewerOwner  = Get-LedgerFieldValue -RawText $rawText -Label 'Selected Reviewer Owner'
        SameClassFallbackOwner = Get-LedgerFieldValue -RawText $rawText -Label 'Same-Class Fallback Owner'
        CarryForwardIteration  = Get-LedgerFieldValue -RawText $rawText -Label 'Carry Forward Iteration'
        CandidateTrapStatus    = Get-LedgerFieldValue -RawText $rawText -Label 'Candidate Trap Status'
        WithdrawalReference    = Get-LedgerFieldValue -RawText $rawText -Label 'Withdrawal Reference'
        DeEscalationOutcome    = Get-LedgerFieldValue -RawText $rawText -Label 'De-Escalation Outcome'
        RecordedAt             = Get-LedgerFieldValue -RawText $rawText -Label 'Recorded At'
        RawLines               = $EntryLines.ToArray()
        RawText                = $rawText
    }
}

function Get-LedgerFieldValue {
    <#
    .SYNOPSIS
    Extracts a field value from ledger entry text.
    
    .PARAMETER RawText
    The raw text content of the ledger entry.
    
    .PARAMETER Label
    The field label to extract.
    #>
    param(
        [string]$RawText,
        [string]$Label
    )

    $pattern = '(?m)^-\s+\*\*' + [regex]::Escape($Label) + '\*\*:\s*`?(.+?)`?\s*$'
    if ($RawText -match $pattern) {
        $value = $Matches[1].Trim()
        if ($value -eq '(none)' -or $value -eq '(pending)' -or [string]::IsNullOrWhiteSpace($value)) {
            return $null
        }
        return $value
    }

    return $null
}

function Get-ActiveReviewerRegressionChain {
    <#
    .SYNOPSIS
    Returns the active reviewer-regression chain for a specific feature.
    
    .PARAMETER ProjectRoot
    The root directory of the project.
    
    .PARAMETER Feature
    The feature path to filter by.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        
        [Parameter(Mandatory = $true)]
        [string]$Feature
    )

    $entries = Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot
    $activeEntries = @($entries | Where-Object { 
        $_.Feature -eq $Feature -and 
        $_.EventStatus -eq 'active' 
    })

    if ($activeEntries.Count -eq 0) {
        return [pscustomobject]@{
            Status                     = 'inactive'
            Feature                    = $Feature
            ActiveEventIds             = @()
            StrongestUnresolvedAction  = $null
            CurrentReviewerClass       = $null
            PriorReviewerClass         = $null
            CurrentReviewerOwner       = $null
            CleanPassesRequired        = 1
            CleanPassesObserved        = 0
            CarryForwardFromIteration  = $null
            Notes                      = $null
        }
    }

    # Find the strongest unresolved escalation action
    $strongestAction = $null
    $currentClass = $null
    $priorClass = $null
    $currentOwner = $null
    $carryForward = $null

    foreach ($entry in $activeEntries) {
        if ($entry.EscalationAction -eq 'human-direction-hold') {
            $strongestAction = 'human-direction-hold'
            $currentClass = $entry.EscalatedToClass
            $priorClass = $entry.PriorReviewerClass
            $currentOwner = $null
            break
        }
        elseif ($entry.EscalationAction -eq 'stronger-class') {
            $strongestAction = 'stronger-class'
            $currentClass = $entry.EscalatedToClass
            $priorClass = $entry.PriorReviewerClass
            $currentOwner = $entry.SelectedReviewerOwner
        }
        elseif ($strongestAction -ne 'stronger-class' -and $entry.EscalationAction -eq 'same-class-independent-owner') {
            $strongestAction = 'same-class-independent-owner'
            $currentClass = $entry.PriorReviewerClass
            $priorClass = $entry.PriorReviewerClass
            $currentOwner = $entry.SameClassFallbackOwner
        }

        if (-not [string]::IsNullOrWhiteSpace([string]$entry.CarryForwardIteration)) {
            $carryForward = $entry.Iteration
        }
    }

    return [pscustomobject]@{
        Status                     = if ($strongestAction -eq 'human-direction-hold') { 'held' } else { 'active' }
        Feature                    = $Feature
        ActiveEventIds             = @($activeEntries | ForEach-Object { $_.EventId })
        StrongestUnresolvedAction  = $strongestAction
        CurrentReviewerClass       = $currentClass
        PriorReviewerClass         = $priorClass
        CurrentReviewerOwner       = $currentOwner
        CleanPassesRequired        = 1
        CleanPassesObserved        = 0
        CarryForwardFromIteration  = $carryForward
        Notes                      = $null
    }
}

function Add-StructuredDecisionsLedgerEntry {
    <#
    .SYNOPSIS
    Adds a structured decision entry to the decisions ledger with extended type support.
    
    .PARAMETER Type
    The decision type. Spec 008 adds: reviewer-regression-escalation, reviewer-regression-withdrawal, lockout-cap.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [ValidateSet('decision', 'defer', 'escalation', 'routing-evidence', 'clarify-skip', 'review-gap', 
                     'reviewer-regression-escalation', 'reviewer-regression-withdrawal', 'lockout-cap')]
        [string]$Type,

        [string]$DecisionId,
        [string]$AffectedRequirement,
        [string]$AffectedIteration,
        [string]$ApprovingHuman,
        [string]$NextAction = 'none',
        [string]$Rationale,
        [string[]]$DetailLines
    )

    $recordedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $effectiveDecisionId = if ([string]::IsNullOrWhiteSpace($DecisionId)) {
        New-DecisionsLedgerEntryId -Type $Type
    }
    else {
        $DecisionId.Trim()
    }

    $lines = @(
        "- **Decision ID**: $effectiveDecisionId"
        "- **Type**: $Type"
        "- **Affected Requirement**: $(Get-DecisionLedgerOptionalValue -Value $AffectedRequirement)"
        "- **Affected Iteration**: $(Get-DecisionLedgerOptionalValue -Value $AffectedIteration)"
        "- **Approving Human**: $(Get-DecisionLedgerOptionalValue -Value $ApprovingHuman)"
        "- **Recorded At**: $recordedAt"
        "- **Next Action**: $(Get-DecisionLedgerOptionalValue -Value $NextAction)"
        "- **Rationale**: $(Get-DecisionLedgerOptionalValue -Value $Rationale)"
    )

    if ($null -ne $DetailLines -and $DetailLines.Count -gt 0) {
        $lines += @('') + @($DetailLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    return Add-DecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title $Title -Lines $lines
}

function Test-HardeningConcernBlocksImplementation {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Concern,

        [string]$ProjectRoot
    )

    if (-not (ConvertTo-BooleanMarkdownValue -Value ([string]$Concern.Blocking))) {
        return $false
    }

    $evaluation = Get-HardeningConcernEvaluation -Concern $Concern -ProjectRoot $ProjectRoot
    return [bool]$evaluation.BlocksImplementation
}

function Test-HardeningConcernBlocksClosure {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Concern,

        [string]$ProjectRoot
    )

    if (-not (ConvertTo-BooleanMarkdownValue -Value ([string]$Concern.Blocking))) {
        return $false
    }

    $evaluation = Get-HardeningConcernEvaluation -Concern $Concern -ProjectRoot $ProjectRoot
    return [bool]$evaluation.BlocksClosure
}

function Get-HardeningGateState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$ProjectRoot
    )

    $lines = @(Get-MarkdownContent -Path $Path)
    $metadata = [ordered]@{
        Schema               = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Schema')
        GateId               = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Gate ID')
        FeatureRef           = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Feature Ref')
        IterationRef         = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Iteration Ref')
        RequestedReviewClass = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Requested Review Class')
        EffectiveReviewClass = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Effective Review Class')
        OverallVerdict       = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Overall Verdict')
        ApprovalRef          = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Approval Ref')
        ReviewedBy           = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Reviewed By')
        ReviewedAt           = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Reviewed At')
    }

    $concerns = @(
        Get-MarkdownSectionTable -Lines $lines -Heading 'Concern Review' |
            ForEach-Object {
                [pscustomobject]@{
                    Concern               = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Concern'))
                    Category              = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Category'))
                    Status                = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Status'))
                    EvidenceBasis         = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Evidence Basis'))
                    RuntimeEvidenceStatus = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Runtime Evidence Status'))
                    ExpectedControls      = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Expected Controls'))
                    Blocking              = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Blocking'))
                    Rationale             = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Rationale'))
                    Approval              = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Approval'))
                }
            }
    )

    $blockingConcerns = @(
        $concerns |
            Where-Object {
                Test-HardeningConcernBlocksImplementation -Concern $_ -ProjectRoot $ProjectRoot
            }
    )

    return [pscustomobject]@{
        Path                       = $Path
        Metadata                   = [pscustomobject]$metadata
        ConcernRows                = $concerns
        BlockingConcerns           = $blockingConcerns
        BlocksImplementation       = $blockingConcerns.Count -gt 0
        ApprovalRecord             = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
            $null
        }
        else {
            Get-ApprovalReferenceRecord -ProjectRoot $ProjectRoot -ApprovalRef $metadata.ApprovalRef -AllowedTypes @('decision', 'defer')
        }
    }
}

function Get-RoutingEvidenceRecords {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [string]$IterationRelativePath
    )

    $pattern = '(?im)^\s*-\s+\*\*Routing Evidence\*\*:\s*(?<actor>[^|]+?)\s*\|\s*requested=(?<requested>[^|]+?)\s*\|\s*actual=(?<actual>[^|]+?)\s*\|\s*model=(?<model>[^|]+?)\s*\|\s*status=(?<status>[^|\r\n]+?)(?:\s*\|\s*fallback=(?<fallback>[^\r\n]+))?\s*$'
    return @(
        Get-DecisionsLedgerEntries -ProjectRoot $ProjectRoot |
            Where-Object {
                $_.Type -eq 'routing-evidence' -and
                (
                    [string]::IsNullOrWhiteSpace($IterationRelativePath) -or
                    [string]$_.AffectedIteration -eq $IterationRelativePath
                )
            } |
            ForEach-Object {
                $entry = $_
                $match = [regex]::Match($entry.RawText, $pattern)
                [pscustomobject]@{
                    DecisionId     = $entry.DecisionId
                    AffectedIteration = $entry.AffectedIteration
                    Actor          = if ($match.Success) { $match.Groups['actor'].Value.Trim() } else { $null }
                    RequestedClass = if ($match.Success) { $match.Groups['requested'].Value.Trim() } else { $null }
                    EffectiveClass = if ($match.Success) { $match.Groups['actual'].Value.Trim() } else { $null }
                    Model          = if ($match.Success) { $match.Groups['model'].Value.Trim() } else { $null }
                    Status         = if ($match.Success) { $match.Groups['status'].Value.Trim() } else { $entry.RoutingStatus }
                    FallbackReason = if ($match.Success -and $match.Groups['fallback'].Success) { $match.Groups['fallback'].Value.Trim() } else { $entry.FallbackReason }
                    Entry          = $entry
                }
            }
    )
}

<#
.SYNOPSIS
Tests form-vs-meaning parity by comparing declared and observed metrics.

.DESCRIPTION
Compares a declared count/metric (form) against an observed count/metric (meaning) 
and returns structured result indicating gap and severity level.

This is a purely functional helper with no I/O side effects, designed for composition
by validator rules and governance scripts.

.PARAMETER Declared
Count/metric from declared state (form). Must be >= 0.
Example: Number of tasks marked complete in state.md.

.PARAMETER Observed
Count/metric from observed reality (meaning). Must be >= 0.
Example: Number of files in git diff baseline...HEAD.

.OUTPUTS
PSCustomObject with fields:
- Declared [int]: Echo of Declared parameter
- Observed [int]: Echo of Observed parameter  
- Gap [bool]: $true if Declared != Observed; $false otherwise
- Severity [string]: 'error' | 'warning' | 'info'

Severity Logic:
- 'error': Declared > 0 AND Observed = 0 (zero-diff, hard failure boundary)
- 'warning': Declared != Observed AND both > 0 (partial mismatch, non-blocking)
- 'info': Declared = Observed (no gap detected)

.EXAMPLE
$result = Test-FormMeaningParity -Declared 11 -Observed 0
# Returns: @{ Declared=11; Observed=0; Gap=$true; Severity='error' }

.EXAMPLE
$result = Test-FormMeaningParity -Declared 5 -Observed 3
# Returns: @{ Declared=5; Observed=3; Gap=$true; Severity='warning' }

.EXAMPLE
$result = Test-FormMeaningParity -Declared 0 -Observed 0
# Returns: @{ Declared=0; Observed=0; Gap=$false; Severity='info' }

.NOTES
Feature: F-028 (Review Evidence Integrity)
Contract: specs/028-review-evidence-integrity/contracts/test-formmeaningparity-contract.md
API Version: 1.0 (immutable per Q6 decision)
#>
function Test-FormMeaningParity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Declared,
        
        [Parameter(Mandatory=$true)]
        [int]$Observed
    )
    
    # Determine gap presence
    $gap = $Declared -ne $Observed
    
    # Determine severity level per Q1 resolution
    $severity = if (-not $gap) {
        # No gap: declared matches observed
        'info'
    }
    elseif ($Declared -gt 0 -and $Observed -eq 0) {
        # Zero-diff: declared work but nothing observed (hard failure)
        'error'
    }
    elseif ($Declared -gt $Observed -and $Observed -gt 0) {
        # Partial implementation: both > 0 but mismatch (non-blocking)
        'warning'
    }
    elseif ($Declared -eq 0 -and $Observed -eq 0) {
        # Legitimate empty state (no gap, spec-only iteration)
        'info'
    }
    else {
        # Other mismatches (e.g., over-delivery: observed > declared)
        'warning'
    }
    
    # Return structured result per contract
    return [PSCustomObject]@{
        Declared = $Declared
        Observed = $Observed
        Gap = $gap
        Severity = $severity
    }
}

function Test-SpecrewWorkshopRecordsPresent {
    # Feature 185: deterministic governance gate. The design workshop is MANDATORY before the specify
    # boundary can advance. Fail-CLOSED when the workshop output is missing/unworked; fail-OPEN only on
    # this check's own error (do not block a session on our bug).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$FeatureRef
    )
    try {
        $featureDir = $null
        $featureJsonPath = Join-Path $ProjectRoot '.specify/feature.json'
        if ([string]::IsNullOrWhiteSpace($FeatureRef) -and (Test-Path -LiteralPath $featureJsonPath)) {
            $fj = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $FeatureRef = Split-Path -Leaf ([string]$fj.feature_directory)
        }
        if (-not [string]::IsNullOrWhiteSpace($FeatureRef)) {
            $candidate = Join-Path (Join-Path $ProjectRoot 'specs') $FeatureRef
            if (Test-Path -LiteralPath $candidate) { $featureDir = $candidate }
        }
        if ($null -eq $featureDir) {
            return [pscustomobject]@{ Present = $false; Reason = 'Cannot resolve the active feature directory to verify the design workshop ran.' }
        }
        $lensFile = Join-Path $featureDir 'lens-applicability.json'
        if (-not (Test-Path -LiteralPath $lensFile)) {
            return [pscustomobject]@{ Present = $false; Reason = "The design workshop has not run - 'lens-applicability.json' is missing under the feature directory." }
        }
        # -AsHashtable so missing keys return $null (fail-CLOSED) instead of throwing under StrictMode.
        # A not-yet-recorded selected lens previously threw on `$workshop.$lensName` -> hit the catch ->
        # failed OPEN, silently waving an incomplete workshop through (caught on the test-f185 live run).
        $lens = Get-Content -LiteralPath $lensFile -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
        $workshop = $lens['workshop']
        if ($null -eq $workshop -or @($workshop.Keys).Count -eq 0) {
            return [pscustomobject]@{ Present = $false; Reason = 'lens-applicability.json has no per-lens workshop records - the workshop was not worked with the human.' }
        }
        foreach ($lensName in @($lens['selected'])) {
            $rec = $workshop[$lensName]
            if ($null -eq $rec -or [string]::IsNullOrWhiteSpace([string]$rec['confirmation'])) {
                return [pscustomobject]@{ Present = $false; Reason = ("Lens '{0}' has no recorded confirmation (or no workshop record at all) - every selected lens must be answered WITH the human in the design workshop (confirmed / delegated / skipped all count; silent omission does not)." -f $lensName) }
            }
        }
        return [pscustomobject]@{ Present = $true; Reason = 'Workshop lens records present and confirmed.' }
    }
    catch {
        # Fail-CLOSED on an unexpected error: a force-governance gate must block + report, never silently
        # pass. The prior fail-OPEN here is exactly what let a StrictMode property-access bug defeat the gate.
        [Console]::Error.WriteLine("[specrew-governance] WARN WORKSHOP_RECORDS_CHECK_FAILED $($_.Exception.Message)")
        return [pscustomobject]@{ Present = $false; Reason = ("Workshop-records check could not complete ({0}) - blocking; verify the workshop ran and lens-applicability.json is valid." -f $_.Exception.Message) }
    }
}
