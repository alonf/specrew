$ErrorActionPreference = 'Stop'

# HARNESS-PURITY REFACTOR (2026-07-15): the recorded-run runner was split into a HARNESS primitive
# (Invoke-...BoundedProcess) and a PURE CORE (Get-...OutputMetaFromFacts + New-...RunRecordObject). This suite
# exercises the PURE CORE over SYNTHETIC facts - NO process is spawned, NO clock, NO filesystem - proving the
# honesty semantics (command_succeeded, redaction/suppression, required-result classification, disclosure
# record, plan identity) are correct in isolation. The behavior-parity with the pre-refactor recorder is
# guarded by the existing recorded-run.Tests.ps1 (which drives the full glue against real processes).
Describe 'Recorded-run PURE CORE (no spawn): output-meta + record assembly' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/test-evidence-recorder.ps1')
        $script:Now = [datetime]::Parse('2026-07-15T00:00:00Z').ToUniversalTime()
        function New-Facts {
            param([int]$Exit = 0, [bool]$TimedOut = $false, [double]$Dur = 1.5, [long]$OutBytes = 0, [string]$OutTail = '', [bool]$OutTrunc = $false, [long]$ErrBytes = 0, [string]$ErrTail = '')
            [pscustomobject]@{
                exit_code = $(if ($TimedOut) { $null } else { $Exit }); timed_out = $TimedOut; duration_seconds = $Dur
                stdout = [pscustomobject]@{ byte_count = $OutBytes; sha256 = ('a' * 64); truncated = $OutTrunc; raw_tail = $OutTail }
                stderr = [pscustomobject]@{ byte_count = $ErrBytes; sha256 = ('b' * 64); truncated = $false; raw_tail = $ErrTail }
            }
        }
        function New-Record {
            param($Facts, [hashtable]$Extra = @{})
            $p = @{ Executable = 'pwsh'; Arguments = @('-c'); WorkingDirectory = 'C:/wd'; TreeId = ('d' * 40); StartedAt = $script:Now; Now = $script:Now; Process = $Facts }
            foreach ($k in $Extra.Keys) { $p[$k] = $Extra[$k] }
            New-ContinuousCoReviewRunRecordObject @p
        }
    }

    Context 'Get-ContinuousCoReviewOutputMetaFromFacts (pure)' {
        It 'SUPPRESSES the tail by default (TailBytes<=0): count/hash only' {
            $m = Get-ContinuousCoReviewOutputMetaFromFacts -Facts ([pscustomobject]@{ byte_count = 42L; sha256 = 'h'; truncated = $true; raw_tail = 'secret-tail' }) -TailBytes 0
            [long]$m.byte_count | Should -Be 42
            [string]$m.truncated_tail | Should -Be ''
            [string]$m.tail_disclosure | Should -Be 'suppressed'
            $m.truncated | Should -BeTrue -Because 'byte_count>0 with suppression is still "truncated" (nothing kept)'
        }
        It 'REDACTS the raw tail when an explicit tail is opted into' {
            $m = Get-ContinuousCoReviewOutputMetaFromFacts -Facts ([pscustomobject]@{ byte_count = 20L; sha256 = 'h'; truncated = $false; raw_tail = 'MY_API_TOKEN=hunter2' }) -TailBytes 2048 -TailDisclosureLabel 'bounded-redacted-tail'
            [string]$m.truncated_tail | Should -Not -Match 'hunter2' -Because 'credential-shaped content is redacted'
            [string]$m.truncated_tail | Should -Match '\[redacted\]'
            [string]$m.tail_disclosure | Should -Be 'bounded-redacted-tail'
        }
    }

    Context 'New-ContinuousCoReviewRunRecordObject (pure)' {
        It 'exit 0, not timed out -> command_succeeded (the [string]-default $null->'''' gotcha the refactor fixed)' {
            $e = New-Record (New-Facts -Exit 0)
            $e.command_succeeded | Should -BeTrue
            $e.exit_code | Should -Be 0
            $e.timed_out | Should -BeFalse
            $e.PSObject.Properties.Name | Should -Not -Contain 'classification'
        }
        It 'non-zero exit -> command_succeeded false; timed out -> null exit + false' {
            (New-Record (New-Facts -Exit 7)).command_succeeded | Should -BeFalse
            $t = New-Record (New-Facts -TimedOut $true)
            $t.command_succeeded | Should -BeFalse
            $t.exit_code | Should -BeNullOrEmpty
            $t.timed_out | Should -BeTrue
        }
        It 'a required-result failure forces command_succeeded=false + the classification, and stays a failure regardless of exit 0' {
            $e = New-Record (New-Facts -Exit 0) @{ RequiredResultFailure = 'the result was REQUIRED but missing' }
            $e.command_succeeded | Should -BeFalse -Because 'a required-result miss is never a successful command even at exit 0'
            [string]$e.classification | Should -Be 'required-result-missing-or-invalid'
            [string]$e.failure_reason | Should -Match 'REQUIRED'
        }
        It 'a FAILED + suppressed run surfaces failure_diagnostics=insufficient-without-disclosure' {
            (New-Record (New-Facts -Exit 3)).failure_diagnostics | Should -Be 'insufficient-without-disclosure'
            # ...but NOT when a tail is disclosed (there is diagnosable text).
            (New-Record (New-Facts -Exit 3) @{ EffectiveTailBytes = 2048 }).PSObject.Properties.Name | Should -Not -Contain 'failure_diagnostics'
        }
        It 'the auditable disclosure record is stamped only when DisclosureInfo is supplied' {
            $disc = [pscustomobject]@{ authorized_by = 'Alon'; disclosure_reason = 'r'; command_id = 'c1'; max_tail_bytes = 4096 }
            $e = New-Record (New-Facts -Exit 0) @{ DisclosureInfo = $disc; EffectiveTailBytes = 4096; TailLabel = 'authorized-diagnostic' }
            [string]$e.diagnostic_disclosure.authorized_by | Should -Be 'Alon'
            $e.diagnostic_disclosure.potentially_sensitive | Should -BeTrue
            [string]$e.diagnostic_disclosure.durability | Should -Be 'durable-digest-bound'
            (New-Record (New-Facts -Exit 0)).PSObject.Properties.Name | Should -Not -Contain 'diagnostic_disclosure'
        }
        It 'plan identity (command_id/provenance/env_refs) is persisted only when supplied' {
            $e = New-Record (New-Facts -Exit 0) @{ CommandId = 'plan-cmd'; Provenance = [pscustomobject]@{ kind = 'project-config' }; EnvRefs = @('CI', '', 'HOME') }
            [string]$e.command_id | Should -Be 'plan-cmd'
            [string]$e.provenance.kind | Should -Be 'project-config'
            @($e.env_refs) | Should -Be @('CI', 'HOME') -Because 'blank names are dropped'
            $bare = New-Record (New-Facts -Exit 0)
            $bare.PSObject.Properties.Name | Should -Not -Contain 'command_id'
        }
        It 'a DeclaredExecutable different from the resolved executable is recorded on the command block' {
            $e = New-Record (New-Facts -Exit 0) @{ DeclaredExecutable = 'pwsh'; }   # same as Executable -> not recorded
            $e.command.PSObject.Properties.Name | Should -Not -Contain 'declared_executable'
            $e2 = (New-ContinuousCoReviewRunRecordObject -Executable 'C:/full/path/pwsh.exe' -DeclaredExecutable 'pwsh' -Arguments @('-c') -WorkingDirectory 'C:/wd' -TreeId ('d' * 40) -StartedAt $script:Now -Now $script:Now -Process (New-Facts -Exit 0))
            [string]$e2.command.declared_executable | Should -Be 'pwsh'
        }
        It 'the ended_at derives from started_at + duration; the record binds the tree id' {
            $e = New-Record (New-Facts -Exit 0 -Dur 2.0)
            [string]$e.reviewed_digest_tree_id | Should -Be ('d' * 40)
            [string]$e.started_at | Should -Be '2026-07-15T00:00:00Z'
            [string]$e.ended_at | Should -Be '2026-07-15T00:00:02Z'
            [double]$e.duration_seconds | Should -Be 2.0
        }
    }
}
