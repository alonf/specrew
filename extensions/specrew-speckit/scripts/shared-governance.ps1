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
    return @('v1')
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
    $index = Get-SpecrewClosedIterationIndex -ProjectRoot $ProjectRoot
    $key = "$Feature/$Iteration"
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
        $key = "$Feature/$Iteration"
        if ($existing.ContainsKey($key)) {
            return
        }
        $newEntryLines = @(
            "  - feature: $Feature",
            "    iteration: $Iteration",
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
    $iteration = $Matches[2]
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
    return @('specify', 'clarify', 'plan', 'tasks', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')
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
    # Proposal 088: identifies .md files in the current git diff scoped via
    # Proposal 083's base-ref resolution. Returns an empty array if base ref
    # is undetectable (caller handles the no-op case).
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot

    $baseRef = Get-SpecrewLocalScopeBaseRef -ProjectRoot $resolvedProjectRoot
    if ([string]::IsNullOrWhiteSpace($baseRef)) {
        return @()
    }

    $diffOutput = @(& git -C $resolvedProjectRoot diff --name-only --diff-filter=d "$baseRef...HEAD" -- '*.md' 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return @()
    }

    $markdownFiles = New-Object System.Collections.Generic.List[string]
    foreach ($relPath in $diffOutput) {
        $trimmed = [string]$relPath
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        $absPath = Join-Path -Path $resolvedProjectRoot -ChildPath $trimmed.Trim()
        if (Test-Path -LiteralPath $absPath -PathType Leaf) {
            $null = $markdownFiles.Add($absPath)
        }
    }

    return @($markdownFiles.ToArray())
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
    $headingPattern = '^(?:#{1,6}\s*)?(?:\*\*)?(What I just did|Why I stopped|What I need from you)(?:\*\*)?\s*$'

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match $headingPattern) {
            if ($null -ne $currentHeading) {
                $sectionMap[$currentHeading] = ($currentLines -join "`n").Trim()
                $currentLines.Clear()
            }

            $currentHeading = $Matches[1]
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
