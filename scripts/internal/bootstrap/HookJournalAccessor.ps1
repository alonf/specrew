<#
.SYNOPSIS
  Read the advisory bootstrap journal (JSONL) the SessionBootstrapManager appends.
.DESCRIPTION
  Resource accessor (IDesign): reads the one-record-per-bootstrap JSONL journal so tests and
  tooling can assert SC-007 - that each bootstrap mode (full | welcome-back | cleared-anchor)
  and signal (handover_valid, concurrent_session, dedupe_key) produces a DISTINGUISHABLE record.
  Fail open: a missing journal or an unparseable line yields no record, never an error. Feature 174
  (SC-007, observability decision 2).
#>

function Get-SpecrewBootstrapJournal {
    [CmdletBinding()]
    [OutputType([object[]])]
    param([Parameter(Mandatory)][string] $JournalPath)
    if (-not (Test-Path -LiteralPath $JournalPath)) { return @() }
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($line in (Get-Content -LiteralPath $JournalPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try { $records.Add(($line | ConvertFrom-Json)) } catch { $null = $_ }
    }
    return , $records.ToArray()
}

function Add-SpecrewBootstrapJournalRecord {
    <#
    .SYNOPSIS
      Append one bootstrap record without losing a concurrent provider fire.
    .DESCRIPTION
      Atomically creates a short-lived sidecar claim, seeks the journal to EOF, and writes one UTF-8
      JSONL record. CreateNew is the same cross-platform single-winner primitive used by the render
      claim. A competing writer retries within one short bounded allowance, and a claim older than the
      stale threshold is reclaimed by atomic rename. The journal is advisory, so exhaustion or an
      unexpected I/O failure returns false instead of blocking or failing the host bootstrap.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string] $JournalPath,
        [Parameter(Mandatory)][psobject] $Record,
        [Parameter()][ValidateRange(1, 1000)][int] $RetryCount = 40,
        [Parameter()][ValidateRange(0, 1000)][int] $RetryDelayMilliseconds = 25,
        [Parameter()][ValidateRange(1, 3600)][int] $StaleClaimSeconds = 30
    )

    try {
        $directory = Split-Path -Parent $JournalPath
        if ($directory -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $directory -Force
        }

        $claimPath = "$JournalPath.append.lock"
        $claimStream = $null
        $ownsClaim = $false
        for ($attempt = 0; $attempt -lt $RetryCount; $attempt++) {
            try {
                $claimStream = [System.IO.File]::Open(
                    $claimPath,
                    [System.IO.FileMode]::CreateNew,
                    [System.IO.FileAccess]::Write,
                    [System.IO.FileShare]::None
                )
                $claimBytes = [System.Text.UTF8Encoding]::new($false).GetBytes(
                    "$PID|$([DateTime]::UtcNow.ToString('o'))"
                )
                $claimStream.Write($claimBytes, 0, $claimBytes.Length)
                $claimStream.Flush()
                $ownsClaim = $true
                break
            }
            catch [System.IO.IOException] {
                # A killed owner can leave a claim behind. Only a sufficiently old path is eligible, and
                # atomic rename elects one reclaimer. On Windows a live owner's open handle rejects the move;
                # on POSIX the age threshold prevents renaming a normal millisecond-scale live append.
                try {
                    if ([System.IO.File]::Exists($claimPath)) {
                        # The path can disappear between these two calls when its owner completes. File's static
                        # timestamp reader is race-safe here (it returns the platform sentinel, never emits a
                        # PowerShell error record that would poison a background job's result stream).
                        $lastWriteUtc = [System.IO.File]::GetLastWriteTimeUtc($claimPath)
                        $ageSeconds = ([DateTime]::UtcNow - $lastWriteUtc).TotalSeconds
                        if ($ageSeconds -ge $StaleClaimSeconds) {
                            $stalePath = "$claimPath.stale.$([guid]::NewGuid().ToString('N'))"
                            [System.IO.File]::Move($claimPath, $stalePath)
                            Remove-Item -LiteralPath $stalePath -Force -ErrorAction SilentlyContinue
                            continue
                        }
                    }
                }
                catch { $null = $_ }

                if ($attempt -ge ($RetryCount - 1)) { return $false }
                if ($RetryDelayMilliseconds -gt 0) {
                    Start-Sleep -Milliseconds $RetryDelayMilliseconds
                }
            }
            catch { return $false }
        }

        if (-not $ownsClaim) { return $false }

        $line = ($Record | ConvertTo-Json -Compress) + [Environment]::NewLine
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($line)
        $stream = $null
        try {
            $stream = [System.IO.File]::Open(
                $JournalPath,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::Read
            )
            $null = $stream.Seek(0, [System.IO.SeekOrigin]::End)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush()
            return $true
        }
        finally {
            if ($null -ne $stream) { $stream.Dispose() }
            if ($null -ne $claimStream) { $claimStream.Dispose() }
            if ($ownsClaim -and (Test-Path -LiteralPath $claimPath -PathType Leaf)) {
                Remove-Item -LiteralPath $claimPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        return $false
    }

    return $false
}
