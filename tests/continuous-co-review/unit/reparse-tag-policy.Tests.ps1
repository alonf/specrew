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
        $script:AttrPinned = 0x00080000
        $script:AttrUnpinned = 0x00100000

        # MEASURED ON THE MAINTAINER'S MACHINE, 2026-08-10, against the installed module at
        # Documents\PowerShell\Modules\Specrew\0.40.0 - CHANGELOG.md, install.sh and LICENSE all
        # reported this exact value. Kept as a literal rather than composed from the constants above,
        # because it is EVIDENCE: it is what a real hydrated OneDrive file looks like, and the first
        # version of this classifier refused all three as refuse-unknown.
        $script:MeasuredHydratedOneDriveAttrs = 0x00080420
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

    # THE DEFECT THIS CONTEXT EXISTS FOR (maintainer measurement, 2026-08-10). The first classifier
    # keyed the cloud family on OFFLINE / RECALL_ON_OPEN / RECALL_ON_DATA_ACCESS - all three of which
    # describe a file that is NOT CURRENTLY DOWNLOADED. That is a TRANSIENT STATE, not the stable
    # property the predicate means to test, which is "is this file cloud-backed". A file stops matching
    # the moment anyone reads it.
    #
    # Which is exactly why the original fixtures passed: they SYNTHESISED the dehydrated shape, so they
    # could only ever confirm the shape they invented. On the real install every file was hydrated and
    # fell through to refuse-unknown, so T006 did not fix DRIFT-199-I001-005 on the machine that
    # produced it. Snapshot-versus-state, in a new place.
    # REBUILT FROM MEASURED VALUES (maintainer ruling, 2026-08-10). The previous version of this context
    # composed its four states by attribute arithmetic, and twice that produced shapes the filesystem
    # does not actually make - it asserted unpinned+hydrated as 0x100420 when the real value is 0x420,
    # and it never included FILE_ATTRIBUTE_SPARSE_FILE (0x200), which a real evicted file carries and no
    # amount of reasoning from the constant list would have suggested.
    #
    # Every value below is TRANSCRIBED from the maintainer's install (LICENSE, evicted and re-hydrated
    # under the half-2 proof). Provenance is on each row. Constructed arithmetic is not used here.
    Context 'the THREE MEASURED OneDrive states, transcribed not synthesised' {
        It 'classifies each measured state as the ruling requires' -ForEach @(
            @{ name = 'pinned + hydrated'; attrs = 0x00080420; expect = 'hydrate-cloud'; family = 'cloud-files'
                provenance = 'CHANGELOG.md / install.sh / LICENSE / _load.ps1 on the installed module, half 1' }
            @{ name = 'unpinned + evicted'; attrs = 0x00501620; expect = 'hydrate-cloud'; family = 'cloud-files'
                provenance = 'LICENSE immediately after attrib -p +u, half 2 - note SPARSE (0x200), which synthesis missed' }
            @{ name = 'unpinned + hydrated'; attrs = 0x00000420; expect = 'admit-nonlinking'; family = 'non-linking'
                provenance = 'LICENSE after the read hydrated it, stable at +2s/+5s/+10s, half 2 step 4' }
        ) {
            $d = Resolve-SpecrewReparseDisposition -Attributes $attrs -LinkType $null
            $d.disposition | Should -Be $expect -Because "$name was measured as 0x$('{0:X}' -f $attrs) ($provenance)"
            $d.family | Should -Be $family
        }

        It 'the evicted state carries SPARSE, which no synthesised shape included' {
            # Kept as its own case because it is the concrete evidence for why this context stopped
            # composing values: the constant list gives you no reason to expect 0x200 here.
            (0x00501620 -band 0x00000200) | Should -Not -Be 0
        }
    }

    # THE RULING (maintainer, 2026-08-10), and the correction that produced it. The earlier warning -
    # "allow-by-default would admit an AppExecLink, so the allowlist stays" - was right in general and
    # WRONG about these call sites. An AppExecLink redirects EXECUTION. None of the three sites executes
    # anything: they read text, hash it, and walk path components for containment.
    #
    # So refusal is now EXACTLY the linking family. For a READ the only redirection that matters is
    # "this path returns some OTHER file's bytes", which is precisely what LinkType and LinkTarget name,
    # and .NET names it reliably for symlink and junction (both measured live in this file). Every
    # plausible non-linking tag in a module tree or authority store is content VIRTUALIZATION rather than
    # path redirection - cloud files, Server dedup, ProjFS - where the file IS the file and the bytes
    # merely arrive later. Trust rests on the HASH of the bytes actually read (the S1 principle already
    # ratified for the cloud family); this applies it consistently instead of carving an exception around
    # one vendor's attribute bits.
    Context 'refusal is EXACTLY the linking family - a non-linking tag is admitted and the hash carries the trust' {
        It 'an AppExecLink is now ADMITTED, and that is the considered answer rather than an oversight' {
            # MEASURED: LOCALAPPDATA\Microsoft\WindowsApps\winget.exe reports attrs 0x420, LinkType EMPTY,
            # no LinkTarget - identical on every signal to a hydrated-unpinned OneDrive file, which is why
            # attributes cannot separate them. Pinned deliberately asserting what NOW HAPPENS to it, so a
            # later reader sees the case was decided, not missed.
            $d = Resolve-SpecrewReparseDisposition -Attributes 0x00000420 -LinkType $null
            $d.disposition | Should -Be 'admit-nonlinking'
        }

        It 'THE BOUNDARY: this rule is for READ, HASH and CONTAINMENT - never for a site that EXECUTES' {
            # An AppExecLink genuinely redirects execution, and there the hash proves nothing. The
            # disposition stays DISTINCT from hydrate-cloud precisely so a future execute-site can refuse
            # it without reopening the read decision.
            $exec = Resolve-SpecrewReparseDisposition -Attributes 0x00000420 -LinkType $null
            $cloud = Resolve-SpecrewReparseDisposition -Attributes 0x00080420 -LinkType $null
            $exec.disposition | Should -Not -Be $cloud.disposition -Because 'collapsing these two would erase the only signal a future execute-site could refuse on'
            Test-SpecrewReparseRefusesRead -Disposition $exec.disposition | Should -BeFalse
            Test-SpecrewReparseRefusesRead -Disposition 'refuse-link' | Should -BeTrue
        }

        It 'THE RESIDUAL, stated as not-known rather than impossible' {
            # This is a WIDENING. An unknown tag that redirects a READ without .NET naming it would now
            # pass. No such tag is known, and the hash still catches wrong bytes - but the honest
            # statement is "not known", not "impossible". The durable fix is reading the real reparse
            # tag, which routes to beta4 with the path-identity consolidation.
            $d = Resolve-SpecrewReparseDisposition -Attributes 0x00000420 -LinkType $null
            $d.family | Should -Be 'non-linking' -Because 'the family name records that this was admitted WITHOUT the tag being identified'
        }

        It 'a link carrying a cloud marker is STILL refused, on both new markers' -ForEach @(
            @{ name = 'pinned symlink'; attr = 0x00080000; link = 'SymbolicLink' }
            @{ name = 'unpinned junction'; attr = 0x00100000; link = 'Junction' }
        ) {
            $d = Resolve-SpecrewReparseDisposition -Attributes ($script:AttrArchive -bor $script:AttrReparsePoint -bor $attr) -LinkType $link
            $d.disposition | Should -Be 'refuse-link' -Because 'cloud-ness never promotes a link out of refusal - that would reopen the containment hole through the new branch'
        }

        It 'a LinkTarget with no LinkType blocks the cloud branch even when a cloud marker is set' {
            # The requirement is that LinkType and LinkTarget are BOTH absent before anything reaches
            # the cloud branch. A host that exposes a target but not a type still proves redirection.
            $d = Resolve-SpecrewReparseDisposition -Attributes 0x00080420 -LinkType $null -LinkTarget 'D:\elsewhere\CHANGELOG.md'
            $d.disposition | Should -Not -Be 'hydrate-cloud' -Because 'a path that points elsewhere is a redirect whatever its attributes say'
        }
    }

    Context 'a non-linking tag is admitted for a READ, and refusal stays keyed on redirection' {
        It 'an unidentified non-linking tag is admitted rather than refused' {
            # e.g. IO_REPARSE_TAG_WCI (0x80000018), Server dedup, ProjFS - content virtualization, not
            # path redirection. The file IS the file; the bytes merely arrive later. Refusing these buys
            # nothing for a read, and the hash still catches wrong bytes.
            $d = Resolve-SpecrewReparseDisposition -Attributes ($script:AttrArchive -bor $script:AttrReparsePoint) -LinkType $null
            $d.disposition | Should -Be 'admit-nonlinking'
        }

        It 'a LinkTarget with NO LinkType still refuses - redirection is what refusal is keyed on' {
            $d = Resolve-SpecrewReparseDisposition -Attributes ($script:AttrArchive -bor $script:AttrReparsePoint) -LinkType $null -LinkTarget 'D:\elsewhere\f.txt'
            $d.disposition | Should -Be 'refuse-link' -Because 'a host that exposes a target without a type still proves the path returns another file''s bytes'
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

        It 'classifies a REAL cloud-backed file as cloud, on any machine that has one' {
            # The standing guard for DRIFT-199-I001-023. Every other cloud case in this file synthesises
            # its attributes, and synthesis is exactly how the original defect survived: the fixtures
            # invented the dehydrated shape and proved only that. This case invents nothing - it finds a
            # real cloud-backed file if the machine has one and asks the classifier about it.
            #
            # Skips where no such file exists (CI, a local-only volume) rather than failing, because the
            # environment is the thing under observation here, not the code.
            $candidates = @(
                (Join-Path $env:USERPROFILE 'OneDrive - Zionet LTD\Documents\PowerShell\Modules')
                (Join-Path $env:USERPROFILE 'OneDrive\Documents\PowerShell\Modules')
                (Join-Path $env:USERPROFILE 'Documents\PowerShell\Modules')
            ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

            $cloudFile = $null
            foreach ($root in $candidates) {
                $cloudFile = Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction SilentlyContinue |
                    Where-Object {
                        # A reparse point carrying any cloud marker: pinned, unpinned, or not-yet-local.
                        ((([int]$_.Attributes) -band 0x00000400) -ne 0) -and
                        ((([int]$_.Attributes) -band (0x00080000 -bor 0x00100000 -bor 0x00001000 -bor 0x00040000 -bor 0x00400000)) -ne 0)
                    } | Select-Object -First 1
                if ($cloudFile) { break }
            }

            if (-not $cloudFile) {
                Set-ItResult -Skipped -Because 'this machine has no cloud-backed module file to observe; nothing real to classify here'
                return
            }

            $d = Get-SpecrewReparseDispositionForItem -Item $cloudFile
            $d.disposition | Should -Be 'hydrate-cloud' -Because (
                'a real cloud-backed file at {0} (attrs 0x{1:X}) must be read, not refused - refusing these is what made the product unusable on the default install' -f $cloudFile.FullName, [int]$cloudFile.Attributes
            )
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

        It 'a REDIRECTING tag still refuses at every site' {
            Mock Get-SpecrewReparseDispositionForItem { [pscustomobject]@{ disposition = 'refuse-link'; family = 'redirecting'; link_type = 'SymbolicLink' } }
            $store = Join-Path $TestDrive 'link-store'
            New-Item -ItemType Directory -Path $store -Force | Out-Null
            $file = Join-Path $TestDrive 'linked.ps1'
            Set-Content -LiteralPath $file -Value 'hello' -Encoding UTF8

            { Get-ReviewAuthorityStorePath -StoreRoot $store -RelativePath 'campaigns/c.json' } | Should -Throw '*review-store-root-link-unsupported*'
            { Get-SpecrewReviewRuntimeManagedTextSha256 -Path $file } | Should -Throw '*review-runtime-managed-file-link-unsupported*'
        }

        It 'a NON-LINKING tag is admitted at every site (the ruling, at the sites it governs)' {
            Mock Get-SpecrewReparseDispositionForItem { [pscustomobject]@{ disposition = 'admit-nonlinking'; family = 'non-linking'; link_type = $null } }
            $store = Join-Path $TestDrive 'nonlinking-store'
            New-Item -ItemType Directory -Path $store -Force | Out-Null
            $file = Join-Path $TestDrive 'nonlinking.ps1'
            Set-Content -LiteralPath $file -Value 'hello' -Encoding UTF8

            { Get-ReviewAuthorityStorePath -StoreRoot $store -RelativePath 'campaigns/c.json' } | Should -Not -Throw
            Get-SpecrewReviewRuntimeManagedTextSha256 -Path $file | Should -Match '^[a-f0-9]{64}$' -Because 'the hash of the bytes actually read is what carries the trust'
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
