# T070: host-independent conformance turn-delta core.
#
# Host adapters supply only lifecycle events. This core owns the live Git snapshot, dirty-path content
# fingerprints, owner-scoped baseline record, deterministic delta, and material packet-demand classification.
# It intentionally contains no Claude/Codex/Copilot/Cursor/Antigravity branching.

$script:SpecrewTurnManagedPathPattern = '^\.(agents|claude|copilot|cursor|github|specify|squad|specrew)[/\\]|^\.(gitattributes|gitignore|markdownlint\.json)$'
$script:SpecrewTurnStartEvents = @('userpromptsubmit', 'preinvocation')

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
        $inside = ([string](& git -C $ProjectRoot rev-parse --is-inside-work-tree 2>$null)).Trim()
        if ($LASTEXITCODE -ne 0 -or $inside -ne 'true') { return $empty }
        $prefix = ([string](& git -C $ProjectRoot rev-parse --show-prefix 2>$null)).Trim() -replace '\\', '/'
        if ($LASTEXITCODE -ne 0) { return $empty }

        $head = ([string](& git -C $ProjectRoot rev-parse HEAD 2>$null)).Trim()
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($head)) { $head = '(unborn)' }

        $statusLines = @(& git -c core.quotepath=false -C $ProjectRoot status --porcelain=v1 --untracked-files=all -- . 2>$null)
        if ($LASTEXITCODE -ne 0) { return $empty }

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
        $baselineMap = @{}
        foreach ($entry in @($Baseline.entries)) {
            $baselineMap[[string]$entry.path] = ('{0}|{1}' -f [string]$entry.status, [string]$entry.fingerprint)
        }
        $currentMap = @{}
        foreach ($entry in @($Current.entries)) {
            $currentMap[[string]$entry.path] = ('{0}|{1}' -f [string]$entry.status, [string]$entry.fingerprint)
        }
        $paths = @(@($baselineMap.Keys) + @($currentMap.Keys) | Sort-Object -Unique)
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
        [AllowNull()]$OwnerRecord,
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
    if (-not [string]::IsNullOrWhiteSpace($Owner) -and $null -ne $OwnerRecord -and
        [string]$OwnerRecord.key -eq [string]$Delta.key -and [string]$OwnerRecord.owner -ne $Owner) {
        $age = $NowEpoch - [long]$OwnerRecord.epoch
        if ($age -ge 0 -and $age -le $OwnerMaxAgeSeconds) {
            $decision.reason = 'turn-delta-owned-by-foreign-session'
            $decision.foreign_owner_suppressed = $true
            return $decision
        }
    }
    $decision.demand = $true
    $decision.reason = 'turn-delta-demands-packet'
    return $decision
}
