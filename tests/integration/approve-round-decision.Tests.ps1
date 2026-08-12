$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T014 / scope exception ruled 2026-08-11.
#
# APPROVING A ROUND IS A DECISION, NOT AN IDENTIFIER. `--authorization-ref` accepted any non-empty
# string, nothing validated it, and its one real property - reuse the same string and no new approval is
# spent - was never explained anywhere a consumer reads. So there was nothing to know AND no way to
# discover there was nothing to know. The maintainer, holding full context, could not work out what to
# type. That is the acceptance bar failing on the person who designed the system.
#
# EVERY TEST HERE RUNS THE REAL SCRIPT, per the fifth method rule: assert the capability from the
# command a consumer types, not the function that implements it. The whole defect was in what the
# command asks for, so a fixture calling the engine directly could not have seen it.
#
# NO PROVIDER SPEND IS POSSIBLE HERE, by construction rather than by hope: each project declares a
# reviewer whose command does not exist on any machine, so a round can be APPROVED and reserved but
# never invoked. The spend-fact count is asserted at zero rather than assumed.

Describe 'T014: approving a round is a decision the system files, not an identifier the human invents' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        $script:Cli = Join-Path $script:RepoRoot 'scripts/specrew-review.ps1'

        function script:New-ApprovalProject {
            param([Parameter(Mandatory)][string]$Root, [string]$AuthorizationRef = '')
            New-Item -ItemType Directory -Path (Join-Path $Root 'specs/001-demo/iterations/007') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $Root '.specrew') -Force | Out-Null
            & git -C $Root init -q 2>&1 | Out-Null
            & git -C $Root branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Root 'app.txt'), 'review me', [Text.UTF8Encoding]::new($false))
            [IO.File]::WriteAllText((Join-Path $Root 'specs/001-demo/spec.md'), '# ctx', [Text.UTF8Encoding]::new($false))
            & git -C $Root -c user.name=t -c user.email=t@example.invalid add -A 2>&1 | Out-Null
            & git -C $Root -c user.name=t -c user.email=t@example.invalid commit -qm init 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Root '.specrew/review-authority.json'),
                '{"schema_version":"1.0","mode":"campaign"}', [Text.UTF8Encoding]::new($false))
            # A cataloged, allowed reviewer whose COMMAND cannot exist. The round can be approved and
            # reach preflight; it can never invoke anything. An EMPTY authorization_ref is the point of
            # the fixture: a project that has not already recorded a standing approval is exactly the
            # state a new consumer is in.
            $hosts = [ordered]@{
                schema_version = '1.0'
                hosts = @([ordered]@{
                        host = 'codex'; model = 'm'; adapter_id = 'reviewer-host-adapter-codex-exec'
                        allowed = $true; installed = $true; review_class_rank = 80
                        model_source = 'human-entered'; cost_class = 'non-default'
                        authorization_ref = $AuthorizationRef; fallback_allowed = $false; timeout_seconds = 0
                    })
            }
            [IO.File]::WriteAllText((Join-Path $Root '.specrew/reviewer-hosts.json'),
                ($hosts | ConvertTo-Json -Depth 6 -Compress), [Text.UTF8Encoding]::new($false))
            return $Root
        }

        function script:Invoke-Cli {
            param([Parameter(Mandatory)][string]$Root, [string[]]$Extra = @())
            $arguments = @('-NoProfile', '-File', $script:Cli, '-Live', '-ProjectPath', $Root,
                '-FeatureId', '001-demo', '-IterationNumber', '007') + $Extra
            return (& pwsh @arguments 2>&1 | Out-String)
        }

        function script:Get-Facts {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Kind)
            $store = Join-Path $Root '.specrew/review/authority'
            if (-not (Test-Path -LiteralPath $store)) { return @() }
            return @(Get-ChildItem -LiteralPath $store -Recurse -File -Filter '*.json' |
                    Where-Object { $_.FullName -match "[\\/]$Kind[\\/]" } |
                    ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })
        }
    }

    It 'THE HUMAN SUPPLIES APPROVAL AND THE SYSTEM FILES THE IDENTIFIER' {
        $root = script:New-ApprovalProject -Root (Join-Path $TestDrive 'approve')
        $output = script:Invoke-Cli -Root $root -Extra @('-ApproveRound')

        $grants = @(script:Get-Facts -Root $root -Kind 'grants')
        @($grants).Count | Should -Be 1 -Because 'one approval mints exactly one slot'

        # THE PROTECTION WAS NEVER THE STRING'S UNGUESSABILITY. It is that a human decided and the
        # ledger records that fact. Dropping the ceremony must not drop the record.
        [string]$grants[0].authority_kind | Should -Be 'human'
        [int]$grants[0].slots | Should -Be 1

        # Derived from the campaign and the round position, NOT from a clock or a random value - so
        # re-running the same approved round reuses the same one-slot grant instead of minting a second.
        # That is the property --authorization-ref always had and never explained; here it falls out of
        # how the string is built, so nobody has to be told.
        [string]$grants[0].authorization_ref | Should -Be 'cmp-001-demo-i007-round-1'

        @(script:Get-Facts -Root $root -Kind 'spend').Count | Should -Be 0 -Because 'the reviewer command does not exist, so nothing can be spent'
        $output | Should -Match '(?i)Round approved' -Because 'the human should see that their approval was recorded, and under what'
    }

    It 'APPROVING TWICE REUSES THE SAME SLOT - the reference is stable for one round' {
        # The property that made --authorization-ref safe, now observable instead of folklore.
        $root = script:New-ApprovalProject -Root (Join-Path $TestDrive 'approve-twice')
        script:Invoke-Cli -Root $root -Extra @('-ApproveRound') | Out-Null
        $firstRef = [string]@(script:Get-Facts -Root $root -Kind 'grants')[0].authorization_ref

        script:Invoke-Cli -Root $root -Extra @('-ApproveRound') | Out-Null
        $grants = @(script:Get-Facts -Root $root -Kind 'grants')

        @($grants).Count | Should -Be 1 -Because 'the same round approved again is the SAME approval, not a second one'
        [string]$grants[0].authorization_ref | Should -Be $firstRef
        @(script:Get-Facts -Root $root -Kind 'spend').Count | Should -Be 0
    }

    It 'WITH NO APPROVAL AT ALL, the refusal names APPROVAL and the exact next command' {
        # The defect that produced this task. A missing approval used to surface as
        # "requested-host-not-available: 'codex' is not installed+authorized+cataloged", which reads as
        # a missing TOOL and sends the consumer to reinstall something that works.
        $root = script:New-ApprovalProject -Root (Join-Path $TestDrive 'no-approval')
        $output = script:Invoke-Cli -Root $root

        $output | Should -Match '(?i)needs your approval'
        $output | Should -Match ([regex]::Escape('specrew review --live --approve-round')) -Because 'a refusal must name the exact command that clears it'

        # THE NEGATIVE THAT MATTERS: it must not read as a broken installation.
        $output | Should -Not -Match '(?i)not installed' -Because 'this is the sentence that sent the maintainer to reinstall a working tool'
        $output | Should -Not -Match '(?i)installed\+authorized\+cataloged' -Because 'three unrelated conditions must never share one sentence again'

        @(script:Get-Facts -Root $root -Kind 'grants').Count | Should -Be 0 -Because 'refusing must not mint an approval nobody gave'
        @(script:Get-Facts -Root $root -Kind 'spend').Count | Should -Be 0
    }

    It 'A STANDING approval in project config still works - the old interface is not removed' {
        # --authorization-ref and a recorded standing reference keep working. A working interface is not
        # removed to add a friendlier one; scripts depend on it.
        $root = script:New-ApprovalProject -Root (Join-Path $TestDrive 'explicit') -AuthorizationRef 'my-own-label'
        script:Invoke-Cli -Root $root | Out-Null

        $grants = @(script:Get-Facts -Root $root -Kind 'grants')
        @($grants).Count | Should -Be 1
        [string]$grants[0].authorization_ref | Should -Be 'my-own-label' -Because 'a label the human chose must be kept verbatim'
        [string]$grants[0].authority_kind | Should -Be 'human'
    }

    It '--approve-round OUTRANKS a stale reference already on file' {
        # Found while preparing the next round in the Specrew repo itself. The engine writes the last
        # used reference back into .specrew/reviewer-hosts.json, so after a round that row holds a SPENT
        # reference - reusing it mints no new slot. The first version of T014 let the file win, so an
        # explicit human approval would have silently done nothing.
        #
        # A RECORDED VALUE MUST NOT OUTRANK AN ACT PERFORMED NOW: the file describes the past, the human
        # is deciding in the present. Same shape as the consent gate.
        $root = script:New-ApprovalProject -Root (Join-Path $TestDrive 'stale-ref') -AuthorizationRef 'already-spent-last-round'
        script:Invoke-Cli -Root $root -Extra @('-ApproveRound') | Out-Null

        $grants = @(script:Get-Facts -Root $root -Kind 'grants')
        @($grants).Count | Should -Be 1
        [string]$grants[0].authorization_ref | Should -Be 'cmp-001-demo-i007-round-1' -Because 'the approval given NOW must mint its own slot, not silently reuse a spent one from the file'
        [string]$grants[0].authorization_ref | Should -Not -Be 'already-spent-last-round'

        # ...and an EXPLICIT label still outranks both - but since 2026-08-12 it must DECLARE itself.
        # A hand-supplied reference is out-of-band by definition: the human may have approved something,
        # but not necessarily THIS round. Measured on both dogfood runs, an agent passed the reviewer-HOST
        # reference from the design workshop and the ledger recorded a human-authorized spend.
        $explicit = script:New-ApprovalProject -Root (Join-Path $TestDrive 'stale-ref-explicit') -AuthorizationRef 'on-file'
        $refused = script:Invoke-Cli -Root $explicit -Extra @('-AuthorizationRef', 'i-named-this-one')
        $refused | Should -Match '(?i)not created by approving this review round'
        @(script:Get-Facts -Root $explicit -Kind 'grants').Count | Should -Be 0 -Because 'an undeclared hand-supplied reference must not become a human grant'

        # `--ack-reason`, not `-AckReason`: only the unix-style form exists, which is exactly what the
        # product's refusal message tells the user to type. The first draft of this line used the
        # PowerShell form and failed - the test was not sending what the message advertises.
        script:Invoke-Cli -Root $explicit -Extra @('-AuthorizationRef', 'i-named-this-one', '--ack-reason', 'approved in the release checklist') | Out-Null
        [string]@(script:Get-Facts -Root $explicit -Kind 'grants')[0].authorization_ref | Should -Be 'i-named-this-one' -Because 'a DECLARED label is still honoured verbatim - the interface is kept, not removed'
    }

    It 'AN UNKNOWN REVIEWER says the reviewer is unknown - not that approval is missing' {
        # The other half of splitting the three conditions. Each now names itself, so the consumer is
        # sent to the thing that is actually wrong.
        $root = script:New-ApprovalProject -Root (Join-Path $TestDrive 'unknown-host')
        $output = script:Invoke-Cli -Root $root -Extra @('-ApproveRound', '-ReviewerHost', 'not-a-real-reviewer')

        $output | Should -Match '(?i)does not recognise the reviewer|not-cataloged'
        $output | Should -Not -Match '(?i)needs your approval' -Because 'approval was given; the reviewer name is the problem'
        @(script:Get-Facts -Root $root -Kind 'spend').Count | Should -Be 0
    }
}
