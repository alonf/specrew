# T070: host-independent conformance turn-delta core.
#
# Host adapters supply only lifecycle events. This core owns the live Git snapshot, dirty-path content
# fingerprints, owner-scoped baseline record, deterministic delta, and material packet-demand classification.
# It intentionally contains no Claude/Codex/Copilot/Cursor/Antigravity branching.

$script:SpecrewTurnManagedPathPattern = '^\.(agents|claude|copilot|cursor|github|specify|squad|specrew)[/\\]|^\.(gitattributes|gitignore|markdownlint\.json)$'
$script:SpecrewTurnStartEvents = @('userpromptsubmit', 'preinvocation')

function Get-SpecrewHookGitSnapshot {
    # Feature 203 T025 (DRIFT-073): the git snapshot the hook dispatcher took once for this hook run, found through
    # SPECREW_HOOK_GIT_SNAPSHOT, when it describes $ProjectRoot; $null otherwise, and the caller asks git itself exactly as
    # before. A snapshot about another root, an unreadable file or an unknown schema is never used. The same reader lives
    # in scripts/internal/bootstrap/ProjectMetadataAccessor.ps1 for the bootstrap side; a test keeps the two identical.
    [OutputType([pscustomobject])]
    param([AllowNull()][AllowEmptyString()][string]$ProjectRoot)
    $path = [string]$env:SPECREW_HOOK_GIT_SNAPSHOT
    if ([string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($ProjectRoot)) { return $null }
    try {
        $cached = Get-Variable -Name 'SpecrewHookGitSnapshotCache' -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        $snapshot = if ($null -ne $cached -and [string]$cached.path -ceq $path) { $cached.snapshot } else { $null }
        if ($null -eq $snapshot) {
            if (-not [System.IO.File]::Exists($path)) { return $null }
            $snapshot = [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false)) | ConvertFrom-Json -ErrorAction Stop
            Set-Variable -Name 'SpecrewHookGitSnapshotCache' -Scope Script -Value ([pscustomobject]@{ path = $path; snapshot = $snapshot })
        }
        $wanted = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd([char]'\', [char]'/')
        if ([string]$snapshot.schema -cne '1' -or [string]$snapshot.project_root -cne $wanted) { return $null }
        return $snapshot
    }
    catch { return $null }
}

function Get-SpecrewHookTranscriptTailLines {
    # Feature 203 T025 (DRIFT-073): the transcript tail the hook dispatcher read once for this hook run, found through
    # SPECREW_HOOK_TRANSCRIPT_TAIL; $null whenever it cannot answer exactly what reading $Path now would, and the caller
    # reads the file itself as before: another transcript, a transcript that has grown since (a host still flushing the
    # turn), a wider byte window than was handed over, an unknown schema, or anything unreadable.
    #   -MaxBytes: the backward byte window Get-SpecrewTranscriptTailLines reads (the same clamp, the same dropped partial
    #              first line when the window starts mid-file); the lines come back as that reader returns them.
    #   -MinLines: Get-Content -Tail semantics instead - the last MinLines complete lines, answered only when the window
    #              holds that many complete lines or the whole file.
    # The same reader lives in scripts/internal/bootstrap/ConversationCaptureAccessor.ps1 for the bootstrap side; a test
    # keeps the two identical.
    [OutputType([string[]])]
    param([AllowNull()][string]$Path, [int]$MaxBytes = 2097152, [int]$MinLines = 0)
    $metaPath = [string]$env:SPECREW_HOOK_TRANSCRIPT_TAIL
    if ([string]::IsNullOrWhiteSpace($metaPath) -or [string]::IsNullOrWhiteSpace($Path)) { return $null }
    try {
        $cached = Get-Variable -Name 'SpecrewHookTranscriptTailCache' -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        $handOver = if ($null -ne $cached -and [string]$cached.meta_path -ceq $metaPath) { $cached } else { $null }
        if ($null -eq $handOver) {
            if (-not [System.IO.File]::Exists($metaPath)) { return $null }
            $meta = [System.IO.File]::ReadAllText($metaPath, [System.Text.UTF8Encoding]::new($false)) | ConvertFrom-Json -ErrorAction Stop
            if ([string]$meta.schema -cne '1' -or -not [System.IO.File]::Exists([string]$meta.tail_path)) { return $null }
            $handOver = [pscustomobject]@{ meta_path = $metaPath; meta = $meta; bytes = [System.IO.File]::ReadAllBytes([string]$meta.tail_path) }
            Set-Variable -Name 'SpecrewHookTranscriptTailCache' -Scope Script -Value $handOver
        }
        $meta = $handOver.meta
        if ([string]$meta.source_path -cne [System.IO.Path]::GetFullPath($Path)) { return $null }
        $sourceLength = [int64]$meta.source_length
        if (-not [System.IO.File]::Exists($Path) -or [System.IO.FileInfo]::new($Path).Length -ne $sourceLength) { return $null }
        $window = [int64]$handOver.bytes.Length
        if ($window -ne [int64]$meta.window_bytes -or $window -gt $sourceLength) { return $null }
        $bytesToRead = if ($MinLines -gt 0) { $window } else { [int64][Math]::Min($sourceLength, [int64][Math]::Max(4096, $MaxBytes)) }
        if ($bytesToRead -gt $window -or $bytesToRead -le 0) { return $null }
        $text = [System.Text.Encoding]::UTF8.GetString($handOver.bytes, [int]($window - $bytesToRead), [int]$bytesToRead)
        $parts = @($text -split "`r?`n")
        $wholeFile = ($bytesToRead -ge $sourceLength)
        if (-not $wholeFile -and $parts.Count -gt 1) { $parts = @($parts | Select-Object -Skip 1) }
        if ($MinLines -le 0) { return , @($parts) }
        if ($parts.Count -gt 0 -and $parts[-1] -eq '') { $parts = @($parts | Select-Object -First ($parts.Count - 1)) }
        if (-not $wholeFile -and $parts.Count -lt $MinLines) { return $null }
        return , @($parts | Select-Object -Last $MinLines)
    }
    catch { return $null }
}

function Get-SpecrewTurnHash {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Text)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return (-join ($hash | ForEach-Object { $_.ToString('x2') }))
}

function Get-SpecrewTurnPathFingerprint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    try {
        $nativePath = $RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
        $fullPath = Join-Path $ProjectRoot $nativePath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { return 'missing' }
        return (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
    }
    catch { return 'unreadable' }
}

function Get-SpecrewTurnSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $empty = [pscustomobject]@{
        available = $false
        reason = 'git-state-unavailable'
        head = ''
        key = ''
        dirty_user_file_count = 0
        entries = @()
    }

    try {
        # Feature 203 T025: the hook run's one git snapshot answers these when it describes this project; its listing is
        # the exact command below (porcelain v1, every untracked file, core.quotepath=false, `-- .`).
        $hookSnapshot = Get-SpecrewHookGitSnapshot -ProjectRoot $ProjectRoot
        if ($null -ne $hookSnapshot -and [bool]$hookSnapshot.rev_parse_ok -and [bool]$hookSnapshot.status_ok) {
            $prefix = ([string]$hookSnapshot.prefix).Trim() -replace '\\', '/'
            $head = if ([bool]$hookSnapshot.head_ok) { [string]$hookSnapshot.head } else { '(unborn)' }
            $statusLines = @($hookSnapshot.status_lines | ForEach-Object { [string]$_ })
        }
        else {
            $inside = ([string](& git -C $ProjectRoot rev-parse --is-inside-work-tree 2>$null)).Trim()
            if ($LASTEXITCODE -ne 0 -or $inside -ne 'true') { return $empty }
            $prefix = ([string](& git -C $ProjectRoot rev-parse --show-prefix 2>$null)).Trim() -replace '\\', '/'
            if ($LASTEXITCODE -ne 0) { return $empty }

            $head = ([string](& git -C $ProjectRoot rev-parse HEAD 2>$null)).Trim()
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($head)) { $head = '(unborn)' }

            $statusLines = @(& git -c core.quotepath=false -C $ProjectRoot status --porcelain=v1 --untracked-files=all -- . 2>$null)
            if ($LASTEXITCODE -ne 0) { return $empty }
        }

        $entries = [System.Collections.Generic.List[object]]::new()
        foreach ($rawLine in $statusLines) {
            $line = [string]$rawLine
            if ($line.Length -lt 4) { continue }
            $status = $line.Substring(0, 2)
            $path = $line.Substring(3).Trim()
            if ($path -match ' -> ') { $path = ($path -split ' -> ')[-1] }
            $path = $path.Trim('"') -replace '\\', '/'
            if (-not [string]::IsNullOrWhiteSpace($prefix) -and $path.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $path = $path.Substring($prefix.Length)
            }
            $path = $path.TrimStart('/')
            if ([string]::IsNullOrWhiteSpace($path) -or $path -match $script:SpecrewTurnManagedPathPattern) { continue }
            $entries.Add([pscustomobject]@{
                    path = $path
                    status = $status
                    fingerprint = Get-SpecrewTurnPathFingerprint -ProjectRoot $ProjectRoot -RelativePath $path
                }) | Out-Null
        }

        $sorted = @($entries | Sort-Object path, status)
        $canonical = [System.Collections.Generic.List[string]]::new()
        $canonical.Add(('head={0}' -f $head)) | Out-Null
        foreach ($entry in $sorted) {
            $canonical.Add(('{0}|{1}|{2}' -f [string]$entry.path, [string]$entry.status, [string]$entry.fingerprint)) | Out-Null
        }
        return [pscustomobject]@{
            available = $true
            reason = 'live-git-snapshot'
            head = $head
            key = Get-SpecrewTurnHash -Text ($canonical -join "`n")
            dirty_user_file_count = $sorted.Count
            entries = $sorted
        }
    }
    catch { return $empty }
}

function Write-SpecrewTurnBaseline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Snapshot,
        [Parameter(Mandatory)][string]$CaptureEvent
    )

    if ($null -eq $Snapshot -or -not [bool]$Snapshot.available -or [string]::IsNullOrWhiteSpace([string]$Snapshot.key)) { return $false }
    $temp = $null
    try {
        $directory = Split-Path -Parent $Path
        if ($directory -and -not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
        $record = New-SpecrewTurnBaselineRecord -Snapshot $Snapshot -CaptureEvent $CaptureEvent
        $temp = $Path + '.tmp-' + [guid]::NewGuid().ToString('N')
        [System.IO.File]::WriteAllText($temp, ($record | ConvertTo-Json -Depth 8 -Compress), [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $Path, $true)
        $back = Read-SpecrewTurnBaseline -Path $Path
        return ($null -ne $back -and [string]$back.key -eq [string]$Snapshot.key -and [string]$back.capture_event -eq $CaptureEvent)
    }
    catch { return $false }
    finally {
        if (-not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -PathType Leaf)) {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-SpecrewTurnBaselineRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Snapshot,
        [Parameter(Mandatory)][string]$CaptureEvent
    )

    if ($null -eq $Snapshot -or -not [bool]$Snapshot.available -or [string]::IsNullOrWhiteSpace([string]$Snapshot.key)) { return $null }
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        capture_event = $CaptureEvent
        captured_at = [DateTimeOffset]::UtcNow.ToString('o')
        head = [string]$Snapshot.head
        key = [string]$Snapshot.key
        dirty_user_file_count = [int]$Snapshot.dirty_user_file_count
        entries = @($Snapshot.entries)
    }
}

function New-SpecrewDegradedTurnBaseline {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Current)

    if ($null -eq $Current -or -not [bool]$Current.available) { return $null }
    $head = [string]$Current.head
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        capture_event = 'capability-absent'
        captured_at = [DateTimeOffset]::UtcNow.ToString('o')
        head = $head
        key = Get-SpecrewTurnHash -Text ("head={0}" -f $head)
        dirty_user_file_count = 0
        entries = @()
    }
}

function Read-SpecrewTurnBaseline {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
        $record = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ([string]$record.schema_version -ne '1.0' -or [string]::IsNullOrWhiteSpace([string]$record.key) -or
            [string]::IsNullOrWhiteSpace([string]$record.capture_event) -or $null -eq $record.entries) { return $null }
        return $record
    }
    catch { return $null }
}

function Compare-SpecrewTurnSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Baseline,
        [Parameter(Mandatory)]$Current,
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $result = [pscustomobject]@{
        material = $false
        reason = 'turn-delta-unavailable'
        key = ''
        user_file_count = 0
        current_dirty_user_file_count = 0
        new_commit_count = 0
        changed_paths = @()
        baseline_key = ''
        current_key = ''
        capture_event = ''
        attribution_mode = 'degraded'
    }
    if ($null -eq $Baseline -or $null -eq $Current -or -not [bool]$Current.available) { return $result }

    try {
        # ORDINAL path keys. A plain PowerShell hashtable folds case in its string keys, so on a
        # case-sensitive repository `Foo` and `foo` overwrote each other here: an edit to the
        # shadowed path could yield an empty changed set, material=false, and NO required
        # conformance packet. Ordinal is correct in both directions - on a case-folding volume the
        # two spellings name one file and only one entry is ever produced (co-review finding, run
        # run-f198-i009-2c6d7cb8-sweep).
        $baselineMap = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
        foreach ($entry in @($Baseline.entries)) {
            $baselineMap[[string]$entry.path] = ('{0}|{1}' -f [string]$entry.status, [string]$entry.fingerprint)
        }
        $currentMap = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
        foreach ($entry in @($Current.entries)) {
            $currentMap[[string]$entry.path] = ('{0}|{1}' -f [string]$entry.status, [string]$entry.fingerprint)
        }
        # Ordinal, matching the two maps above. `Sort-Object -Unique -CaseSensitive` flips only the
        # case flag and leaves the comparison culture-aware, so composed versus decomposed Unicode
        # spellings that the Ordinal maps deliberately keep apart collapsed again right here - and an
        # edit confined to the dropped path could yield an empty changed set, material=false, and NO
        # required conformance packet. DRIFT-198-I009-033; the same shape as DRIFT-198-I009-030's
        # second defect, which fixed these maps and left their union.
        $pathOrder = [Collections.Generic.List[string]]::new()
        $pathSeen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($pathKey in (@($baselineMap.Keys) + @($currentMap.Keys))) {
            if ($pathSeen.Add([string]$pathKey)) { $pathOrder.Add([string]$pathKey) }
        }
        $pathOrder.Sort([StringComparer]::Ordinal)
        $paths = @($pathOrder)
        $changed = @($paths | Where-Object {
                -not $baselineMap.ContainsKey($_) -or -not $currentMap.ContainsKey($_) -or
                [string]$baselineMap[$_] -ne [string]$currentMap[$_]
            })

        $commitCount = 0
        $baselineHead = [string]$Baseline.head
        $currentHead = [string]$Current.head
        if (-not [string]::IsNullOrWhiteSpace($baselineHead) -and $baselineHead -ne '(unborn)' -and
            -not [string]::IsNullOrWhiteSpace($currentHead) -and $currentHead -ne '(unborn)' -and
            $baselineHead -ne $currentHead) {
            try {
                $countText = ([string](& git -C $ProjectRoot rev-list --count ("{0}..{1}" -f $baselineHead, $currentHead) -- . 2>$null)).Trim()
                if ($LASTEXITCODE -eq 0 -and $countText -match '^\d+$') { $commitCount = [int]$countText }
                if ($commitCount -le 0) { $commitCount = 1 }
            }
            catch { $commitCount = 1 }
        }

        $captureEvent = [string]$Baseline.capture_event
        $attributionMode = if ($captureEvent.ToLowerInvariant() -in $script:SpecrewTurnStartEvents) { 'exact-turn' } else { 'degraded-worktree' }
        $material = ($changed.Count -gt 0 -or $commitCount -gt 0)
        $key = if ($material) { 'material|turn|' + (Get-SpecrewTurnHash -Text ('{0}|{1}' -f [string]$Baseline.key, [string]$Current.key)) } else { '' }
        return [pscustomobject]@{
            material = $material
            reason = $(if ($material) { 'live-turn-delta' } else { 'no-live-turn-delta' })
            key = $key
            user_file_count = $changed.Count
            current_dirty_user_file_count = [int]$Current.dirty_user_file_count
            new_commit_count = $commitCount
            changed_paths = $changed
            baseline_key = [string]$Baseline.key
            current_key = [string]$Current.key
            capture_event = $captureEvent
            attribution_mode = $attributionMode
        }
    }
    catch { return $result }
}

function Resolve-SpecrewTurnPacketDemand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Delta,
        [AllowNull()][string]$SatisfiedKey,
        [AllowNull()][string]$Owner,
        [int]$OwnerMaxAgeSeconds = 300,
        [long]$NowEpoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    )

    $decision = [pscustomobject]@{
        demand = $false
        reason = 'no-turn-delta'
        already_satisfied = $false
        foreign_owner_suppressed = $false
    }
    if ($null -eq $Delta -or -not [bool]$Delta.material -or [string]::IsNullOrWhiteSpace([string]$Delta.key)) { return $decision }
    if (-not [string]::IsNullOrWhiteSpace($SatisfiedKey) -and [string]$Delta.key -eq $SatisfiedKey) {
        $decision.reason = 'turn-delta-already-satisfied'
        $decision.already_satisfied = $true
        return $decision
    }
    # THE FOREIGN-OWNER SUPPRESSION IS RETIRED WITH THE RECORD IT READ.
    #
    # It suppressed a packet demand when a PROJECT-WIDE attribution record said another session owned this
    # material surface. The record answered "who did this work" from a diff of the shared worktree and
    # credited whichever session's hook observed it first - so the independent review reproduced a read-only
    # session being recorded as the owner of an edit another session made, after which THIS branch would
    # suppress the demand on the session that actually did it.
    #
    # The parameter is removed rather than left unpassed: an unreachable branch with a live signature is an
    # invitation to revive it, and this whole family exists because inference-from-shared-state looked
    # reasonable each time. `foreign_owner_suppressed` stays on the returned object as a permanent $false so
    # existing readers keep their shape while the mechanism behind it is gone.
    $decision.demand = $true
    $decision.reason = 'turn-delta-demands-packet'
    return $decision
}
# specrew-self-provenance-ok: DRIFT-198-I009-033; implementation history is recorded for maintainers and is never emitted as consumer instruction
