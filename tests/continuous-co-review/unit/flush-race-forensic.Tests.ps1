#requires -Version 7.0
# T109 / FR-040 + SC-025 (design N7, D-197-I009-003): the flush-race forensic ANALYZER.
# The suspicion was a flush/read race in the conformance Stop-provider (a valid packet on disk
# evaluating packetPresent=false -> spurious block / double render). The 2026-07-08 forensic on the
# real self-host corpus REFUTED it (see specs/197-continuous-co-review/iterations/010/quality/
# flush-race-forensic.md). This analyzer re-runs the classification on whatever journal corpus exists
# on THIS machine: if the race signature ever appears, it FAILS with the captured dx record — the
# reproduction the reverted 4x-tail-200 mitigation was waiting for. Skips honestly when no corpus.

Describe 'T109 flush-race forensic analyzer (D-197-I009-003 refuted; reopens on a real signature)' {

    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:JournalPath = Join-Path $script:RepoRoot '.specrew/runtime/conformance-journal.jsonl'
    }

    It 'the captured corpus contains NO flush/read race signature' {
        if (-not (Test-Path -LiteralPath $script:JournalPath -PathType Leaf)) {
            Set-ItResult -Skipped -Because 'no conformance-journal corpus on this machine (the forensic ran on the self-host corpus 2026-07-08: refuted)'
            return
        }
        $records = @(Get-Content -LiteralPath $script:JournalPath -Encoding UTF8 | ForEach-Object {
                try { $_ | ConvertFrom-Json } catch { $null }
            } | Where-Object { $null -ne $_ })
        if ($records.Count -eq 0) {
            Set-ItResult -Skipped -Because 'journal present but empty/unparseable'
            return
        }

        $suspects = New-Object System.Collections.Generic.List[string]
        foreach ($r in ($records | Where-Object { $_.event -in @('stop-block', 'stop-block-capped') })) {
            $len = if ($r.PSObject.Properties.Name -contains 'dx_lat_len') { [int]$r.dx_lat_len } else { -1 }
            $ccLoaded = if ($r.PSObject.Properties.Name -contains 'dx_cc_loaded') { [bool]$r.dx_cc_loaded } else { $true }
            $hits = if ($r.PSObject.Properties.Name -contains 'dx_lat_hits') { [int]$r.dx_lat_hits } else { -1 }
            # Race signature (a): the provider blocked while its read of the last assistant message was
            # EMPTY or unreadable - i.e. it decided "packet absent" without a real read. (The provider
            # fail-opens on a null read, so a 0-length read that still BLOCKED is exactly the race.)
            if ($len -eq 0 -or -not $ccLoaded) {
                $suspects.Add(("{0}: blocked on an empty/unreadable read (dx_lat_len={1}, dx_cc_loaded={2})" -f $r.recorded_at, $len, $ccLoaded)) | Out-Null
            }
            # Race signature (b): near-miss header count (1-3 of 6) suggests a TRUNCATED/partially
            # flushed packet read - the packet was mid-flush when read.
            if ($hits -ge 1 -and $hits -le 3) {
                $suspects.Add(("{0}: blocked on a PARTIAL header read (dx_lat_hits={1} of 6, dx_lat_len={2}) - possible mid-flush truncation" -f $r.recorded_at, $hits, $len)) | Out-Null
            }
        }
        ($suspects -join "`n") | Should -BeNullOrEmpty -Because 'a flush/read race signature would reopen D-197-I009-003 with the captured dx record (re-add a CHEAP re-read variant per the iter-009 revert note)'
    }
}
