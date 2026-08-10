$ErrorActionPreference = 'Stop'

# Trace: T006 / FR-011, FR-023 / SC-006.
#
# THE DISCRIMINATION. The integrity checks refused EVERY reparse point, which is right for a symlink or
# a junction - those redirect a write outside the store, and that is the containment class the checks
# exist for - and wrong for a cloud placeholder, which redirects nothing. A placeholder IS the file;
# its content merely is not local yet. Refusing it is what made Specrew unusable on the default
# CurrentUser install, and DRIFT-199-I001-005 is the sharp version: the refusal blocked the sanctioned
# REMEDIATION door, so a consumer on OneDrive could not even record a governance decision.
#
# The policy is an ALLOWLIST and its fail direction is REFUSAL - the mirror of FR-009's allowlist,
# where the safe direction was nagging. Here an unrecognised tag must refuse, because admitting an
# unknown redirect is how the containment class returns.
#
# SPLIT ON PURPOSE: the DECISION is a pure function over (attributes, link type) so the cloud branch is
# testable without a real placeholder, which no agent can materialise on a local volume. The path
# reader is the thin shell that asks the filesystem. The end-to-end hydration leg is a MANUAL
# measurement on the T067-class environment and is recorded as a limit of the evidence, never implied
# by this suite passing.
Describe 'Reparse-tag policy (T006/FR-011)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reparse-tag-policy.ps1')

        # REAL Windows constants, not invented names. The classifier keys on attributes rather than on
        # the tag (reading the tag needs a subprocess per component, which this repo has already been
        # burned by), so these pin that the vocabulary describes the real tags.
        $script:TagSymlink = 0xA000000C
        $script:TagMountPoint = 0xA0000003
        $script:TagCloud = 0x9000001A
        $script:TagCloudMask = 0x0000F000
        $script:TagWci = 0x80000018

        $script:AttrDirectory = 0x00000010
        $script:AttrArchive = 0x00000020
        $script:AttrReparsePoint = 0x00000400
        $script:AttrOffline = 0x00001000
        $script:AttrRecallOnOpen = 0x00040000
        $script:AttrRecallOnDataAccess = 0x00400000
    }

    Context 'the redirecting family still refuses - unchanged behaviour' {
        It 'refuses a symlink' {
            $d = Resolve-SpecrewReparseDisposition -Attributes ($script:AttrArchive -bor $script:AttrReparsePoint) -LinkType 'SymbolicLink'
            $d.disposition | Should -Be 'refuse-link'
        }

        It 'refuses a junction' {
            $d = Resolve-SpecrewReparseDisposition -Attributes ($script:AttrDirectory -bor $script:AttrReparsePoint) -LinkType 'Junction'
            $d.disposition | Should -Be 'refuse-link'
        }

        It 'the refusal is keyed on the link family, whatever else the attributes say' {
            # A symlink that ALSO carries a recall attribute is still a redirect. Cloud-ness never
            # promotes a link out of the refusal family - that would be the containment hole reopening.
            $d = Resolve-SpecrewReparseDisposition -Attributes ($script:AttrArchive -bor $script:AttrReparsePoint -bor $script:AttrRecallOnDataAccess) -LinkType 'SymbolicLink'
            $d.disposition | Should -Be 'refuse-link'
        }
    }

    Context 'the cloud-files family hydrates instead of refusing' {
        It 'admits a placeholder for hydration on each recall attribute' -ForEach @(
            @{ name = 'recall-on-data-access'; attr = 0x00400000 }
            @{ name = 'recall-on-open'; attr = 0x00040000 }
            @{ name = 'offline'; attr = 0x00001000 }
        ) {
            $d = Resolve-SpecrewReparseDisposition -Attributes ($script:AttrArchive -bor $script:AttrReparsePoint -bor $attr) -LinkType $null
            $d.disposition | Should -Be 'hydrate-cloud' -Because "$name marks a placeholder, which redirects nothing"
        }
    }

    Context 'anything else FAILS CLOSED' {
        It 'refuses an unrecognised reparse tag (allowlist, not blocklist)' {
            # e.g. IO_REPARSE_TAG_WCI (0x80000018) - a container-isolation tag. Not a link we recognise
            # and not a placeholder, so it is refused rather than admitted.
            $d = Resolve-SpecrewReparseDisposition -Attributes ($script:AttrArchive -bor $script:AttrReparsePoint) -LinkType $null
            $d.disposition | Should -Be 'refuse-unknown'
        }
    }

    Context 'an ordinary path is not a reparse point at all' {
        It 'returns none for an ordinary file and an ordinary directory' -ForEach @(
            @{ name = 'file'; attr = 0x00000020 }
            @{ name = 'directory'; attr = 0x00000010 }
        ) {
            $d = Resolve-SpecrewReparseDisposition -Attributes $attr -LinkType $null
            $d.disposition | Should -Be 'none'
        }

        It 'an OFFLINE ordinary file is still not a reparse point' {
            # Offline alone is not a placeholder: without the reparse bit there is nothing to hydrate,
            # and treating it as cloud would route an ordinary file through the hydration path.
            $d = Resolve-SpecrewReparseDisposition -Attributes ($script:AttrArchive -bor $script:AttrOffline) -LinkType $null
            $d.disposition | Should -Be 'none'
        }
    }

    Context 'the path reader agrees with the live filesystem' {
        It 'classifies a real symlink and a real junction as refuse-link, and real ordinary paths as none' {
            $scratch = Join-Path ([IO.Path]::GetTempPath()) ('reparse-policy-' + [guid]::NewGuid().ToString('n'))
            New-Item -ItemType Directory -Path $scratch -Force | Out-Null
            try {
                $realDir = Join-Path $scratch 'real-dir'; New-Item -ItemType Directory -Path $realDir -Force | Out-Null
                $realFile = Join-Path $scratch 'real.txt'; Set-Content -LiteralPath $realFile -Value 'hello' -Encoding UTF8

                (Get-SpecrewReparseTagDisposition -Path $realFile).disposition | Should -Be 'none'
                (Get-SpecrewReparseTagDisposition -Path $realDir).disposition | Should -Be 'none'

                $sym = Join-Path $scratch 'sym-file'
                $symMade = $true
                try { New-Item -ItemType SymbolicLink -Path $sym -Target $realFile -ErrorAction Stop | Out-Null } catch { $symMade = $false }
                if ($symMade) { (Get-SpecrewReparseTagDisposition -Path $sym).disposition | Should -Be 'refuse-link' }
                else { Set-ItResult -Skipped -Because 'this environment cannot create a symbolic link' }

                $junction = Join-Path $scratch 'junction-dir'
                $junctionMade = $true
                try { New-Item -ItemType Junction -Path $junction -Target $realDir -ErrorAction Stop | Out-Null } catch { $junctionMade = $false }
                if ($junctionMade) { (Get-SpecrewReparseTagDisposition -Path $junction).disposition | Should -Be 'refuse-link' }
            }
            finally { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'a missing path reports none rather than throwing (callers skip what does not exist)' {
            (Get-SpecrewReparseTagDisposition -Path (Join-Path ([IO.Path]::GetTempPath()) 'no-such-path-xyz')).disposition | Should -Be 'none'
        }
    }

    # A classifier nothing calls changes nothing. These pin that each integrity check ROUTES THROUGH it
    # rather than keeping its own private attribute test - the failure this feature keeps re-learning is
    # that the wiring is what drifts, not the primitive.
    #
    # The cloud branch is exercised by MOCKING the classifier, because no agent can materialise a real
    # placeholder on a local volume. That is a genuine limit: these cases prove each site HONOURS a
    # hydrate-cloud answer, and the live symlink/junction cases above plus the untouched refusal suites
    # prove the refusing direction on the real filesystem. The end-to-end hydration leg remains the
    # maintainer's manual measurement on the T067-class install.
    Context 'every integrity check consults the ONE classifier' {
        BeforeAll {
            . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-store.ps1')
            . (Join-Path $script:RepoRoot 'scripts/internal/review-engine-resolution.ps1')
        }

        It 'the authority store admits a cloud placeholder root instead of refusing it' {
            Mock Get-SpecrewReparseDispositionForItem { [pscustomobject]@{ disposition = 'hydrate-cloud'; family = 'cloud-files'; link_type = $null } }
            $store = Join-Path $TestDrive 'cloud-store'
            New-Item -ItemType Directory -Path $store -Force | Out-Null

            { Get-ReviewAuthorityStorePath -StoreRoot $store -RelativePath 'campaigns/cmp-x/grant.json' } | Should -Not -Throw
            Should -Invoke Get-SpecrewReparseDispositionForItem -Times 1 -Scope It -Because 'the site must ASK the classifier, not decide for itself'
        }

        It 'the module-install containment walk admits a cloud placeholder component' {
            Mock Get-SpecrewReparseDispositionForItem { [pscustomobject]@{ disposition = 'hydrate-cloud'; family = 'cloud-files'; link_type = $null } }
            $root = Join-Path $TestDrive 'cloud-runtime'
            New-Item -ItemType Directory -Path (Join-Path $root 'sub') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'sub/f.ps1') -Value 'x' -Encoding UTF8

            { Assert-SpecrewReviewRuntimePathContained -Path (Join-Path $root 'sub/f.ps1') -Root $root } | Should -Not -Throw
        }

        It 'the managed-file hash READS a cloud placeholder - DRIFT-199-I001-005 is this exact line' {
            Mock Get-SpecrewReparseDispositionForItem { [pscustomobject]@{ disposition = 'hydrate-cloud'; family = 'cloud-files'; link_type = $null } }
            $file = Join-Path $TestDrive 'placeholder.ps1'
            Set-Content -LiteralPath $file -Value 'hello' -Encoding UTF8

            Get-SpecrewReviewRuntimeManagedTextSha256 -Path $file | Should -Match '^[a-f0-9]{64}$' -Because 'opening the file IS the hydration; refusing it is what took the remediation door down'
        }

        It 'an unrecognised tag still refuses at every site (allowlist, fail closed)' {
            Mock Get-SpecrewReparseDispositionForItem { [pscustomobject]@{ disposition = 'refuse-unknown'; family = 'unknown'; link_type = $null } }
            $store = Join-Path $TestDrive 'unknown-store'
            New-Item -ItemType Directory -Path $store -Force | Out-Null
            $file = Join-Path $TestDrive 'unknown.ps1'
            Set-Content -LiteralPath $file -Value 'hello' -Encoding UTF8

            { Get-ReviewAuthorityStorePath -StoreRoot $store -RelativePath 'campaigns/c.json' } | Should -Throw '*review-store-root-link-unsupported*'
            { Get-SpecrewReviewRuntimeManagedTextSha256 -Path $file } | Should -Throw '*review-runtime-managed-file-link-unsupported*'
        }
    }

    Context 'the refusal a consumer reads (FR-011 / FR-015)' {
        It 'keeps the machine-readable code FIRST and then says what to do about it' {
            # The code stays because fixtures and callers match on it; a containment refusal is not the
            # place to break a contract for prose. Everything after it is the part a person can act on.
            $message = Get-SpecrewReparseRefusalMessage -Code 'review-store-root-link-unsupported' `
                -Path 'C:\x\store' -Disposition 'refuse-link' -LinkType 'Junction'

            $message | Should -BeLike 'review-store-root-link-unsupported:C:\x\store*'
            $message | Should -Match '(?i)junction'
            $message | Should -Match '(?i)run the command again'
            $message | Should -Match '(?i)OneDrive' -Because 'the consumer whose install this refuses must be told that cloud storage is NOT the problem'
        }

        It 'names a symbolic link as a symbolic link, not as a junction' {
            $message = Get-SpecrewReparseRefusalMessage -Code 'review-runtime-managed-file-link-unsupported' `
                -Path 'C:\x\f.ps1' -Disposition 'refuse-link' -LinkType 'SymbolicLink'
            $message | Should -Match '(?i)symbolic link'
            $message | Should -Not -Match '(?i)junction'
        }

        It 'an unknown tag says so plainly rather than guessing a family' {
            $message = Get-SpecrewReparseRefusalMessage -Code 'review-store-path-link-unsupported' `
                -Path 'campaigns/x' -Disposition 'refuse-unknown' -LinkType $null
            $message | Should -Match '(?i)does not recognise'
        }

        It 'a placeholder that cannot be downloaded says THAT, not a raw file error' {
            # The other half of the cloud story: hydration is the read, and the read can fail. Left bare
            # the consumer gets an IO error about a path inside a module directory they never chose.
            Mock Get-SpecrewReparseDispositionForItem { [pscustomobject]@{ disposition = 'hydrate-cloud'; family = 'cloud-files'; link_type = $null } }
            . (Join-Path $script:RepoRoot 'scripts/internal/review-engine-resolution.ps1')
            $directoryStandingInForAnUnreadablePlaceholder = Join-Path $TestDrive 'unreadable'
            New-Item -ItemType Directory -Path $directoryStandingInForAnUnreadablePlaceholder -Force | Out-Null

            { Get-SpecrewReviewRuntimeManagedTextSha256 -Path $directoryStandingInForAnUnreadablePlaceholder } |
                Should -Throw '*review-runtime-managed-file-hydration-unavailable*'
        }

        It 'the hydration failure tells the consumer what to check' {
            Mock Get-SpecrewReparseDispositionForItem { [pscustomobject]@{ disposition = 'hydrate-cloud'; family = 'cloud-files'; link_type = $null } }
            . (Join-Path $script:RepoRoot 'scripts/internal/review-engine-resolution.ps1')
            $unreadable = Join-Path $TestDrive 'unreadable-2'
            New-Item -ItemType Directory -Path $unreadable -Force | Out-Null

            $message = ''
            try { Get-SpecrewReviewRuntimeManagedTextSha256 -Path $unreadable } catch { $message = $_.Exception.Message }
            $message | Should -Match '(?i)online'
            $message | Should -Match '(?i)always keep on this device'
            $message | Should -Match '(?i)underlying error was'
        }
    }
}
