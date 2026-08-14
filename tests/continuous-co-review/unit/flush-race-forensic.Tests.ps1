#requires -Version 7.0
# T109 / FR-040 + SC-025 (design N7, D-197-I009-003): the flush-race forensic ANALYZER.
# The suspicion was a flush/read race in the conformance Stop-provider (a valid packet on disk
# evaluating packetPresent=false -> spurious block / double render). The 2026-07-08 forensic on the
# real self-host corpus REFUTED it (see specs/197-continuous-co-review/iterations/010/quality/
# flush-race-forensic.md). This analyzer re-runs the classification on whatever journal corpus exists
# on THIS machine: if the race signature ever appears, it FAILS with the captured dx record — the
# reproduction the reverted 4x-tail-200 mitigation was waiting for. Beta3 now uses one bounded tail-8
# recovery read only on that measured signature; old corpus records remain evidence, not current failures.

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
        $historicalEvidence = New-Object System.Collections.Generic.List[string]
        foreach ($r in ($records | Where-Object { $_.event -in @('stop-block', 'stop-block-capped') })) {
            $len = if ($r.PSObject.Properties.Name -contains 'dx_lat_len') { [int]$r.dx_lat_len } else { -1 }
            $ccLoaded = if ($r.PSObject.Properties.Name -contains 'dx_cc_loaded') { [bool]$r.dx_cc_loaded } else { $true }
            $hits = if ($r.PSObject.Properties.Name -contains 'dx_lat_hits') { [int]$r.dx_lat_hits } else { -1 }
            # Race signature (a): the provider blocked while its read of the last assistant message was
            # EMPTY or unreadable - i.e. it decided "packet absent" without a real read. (The provider
            # fail-opens on a null read, so a 0-length read that still BLOCKED is exactly the race.)
            $hasMitigationTelemetry = $r.PSObject.Properties.Name -contains 'dx_reread_attempted'
            $rereadAttempted = if ($hasMitigationTelemetry) { [bool]$r.dx_reread_attempted } else { $false }
            $rereadRecovered = if ($r.PSObject.Properties.Name -contains 'dx_reread_recovered') { [bool]$r.dx_reread_recovered } else { $false }
            if ($len -eq 0 -or -not $ccLoaded) {
                $message = ("{0}: blocked on an empty/unreadable read (dx_lat_len={1}, dx_cc_loaded={2})" -f $r.recorded_at, $len, $ccLoaded)
                if ($hasMitigationTelemetry) { $suspects.Add($message) | Out-Null } else { $historicalEvidence.Add($message) | Out-Null }
            }
            # Race signature (b): near-miss header count (1-3 of 6) suggests a TRUNCATED/partially
            # flushed packet read - the packet was mid-flush when read.
            if ($hits -ge 1 -and $hits -le 3) {
                $message = ("{0}: blocked on a PARTIAL header read (dx_lat_hits={1} of 6, dx_lat_len={2}, reread_attempted={3}, reread_recovered={4})" -f $r.recorded_at, $hits, $len, $rereadAttempted, $rereadRecovered)
                if (-not $hasMitigationTelemetry) { $historicalEvidence.Add($message) | Out-Null }
                elseif (-not $rereadAttempted -or -not $rereadRecovered) { $suspects.Add($message) | Out-Null }
            }
        }
        ($suspects -join "`n") | Should -BeNullOrEmpty -Because 'post-mitigation partial reads must attempt and recover through the bounded tail-8 reread; pre-mitigation records remain preserved evidence'
    }

    It 'implements the measured-signature recovery as one bounded tail-8 reread with telemetry' {
        $provider = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1') -Raw
        $provider | Should -Match '\$initialHeaderHits\s+-ge\s+1'
        $provider | Should -Match 'Get-Content[^\r\n]+-Tail\s+8'
        $provider | Should -Match 'dx_reread_attempted\s*=\s*\$transcriptRereadAttempted'
        $provider | Should -Match 'dx_reread_recovered\s*=\s*\$transcriptRereadRecovered'
    }
}
