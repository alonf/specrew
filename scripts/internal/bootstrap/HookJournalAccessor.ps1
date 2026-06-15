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
