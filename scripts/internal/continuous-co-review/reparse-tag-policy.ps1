$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T006 / FR-011, FR-023 / SC-006 - THE ONE REPARSE-TAG POLICY.
#
# The integrity checks that protect the authority store, the module install, and the frozen snapshot
# all refused EVERY reparse point. That is right for a symlink or a junction: they redirect a write
# outside the intended root, and that containment class has now appeared five times in this codebase
# (DRIFT-198-I009-011, -025, -031, -041, and the store hardening). It is WRONG for a cloud placeholder,
# which redirects nothing at all - the placeholder IS the file, its content merely is not local yet.
#
# Refusing placeholders is what makes the product unusable on the default CurrentUser install, and
# DRIFT-199-I001-005 is the sharp version: the refusal blocked the sanctioned REMEDIATION door, so a
# consumer on a OneDrive-backed Documents folder could not even record a governance decision about it.
#
# THE DISCRIMINATOR IS ALREADY IN .NET, and that choice is load-bearing rather than convenient.
# `FileSystemInfo.LinkType` names the redirecting family exactly ('SymbolicLink' | 'Junction') and
# `LinkTarget` is non-null only for those. Measured on Windows before this was written:
#
#     symlink   attrs=0x420  reparse=yes  LinkType=SymbolicLink  (real tag 0xa000000c)
#     junction  attrs=0x410  reparse=yes  LinkType=Junction      (real tag 0xa0000003)
#     ordinary  attrs=0x20/0x10  reparse=no  LinkTarget=null
#
# Reading the REAL tag needs `fsutil` or P/Invoke. `fsutil` would put a SUBPROCESS inside a loop that
# walks every existing component of every path - and a subprocess on a per-path loop is exactly what
# silently hung the Linux CI review suite once already (the `git config core.ignorecase` call the
# path-identity primitive exists to keep out). The tag constants are pinned in the fixture as data so
# the vocabulary stays honest; the runtime keys on attributes.

function Resolve-SpecrewReparseDisposition {
    # PURE decision over (attributes, link type). Pure on purpose: no agent can materialise a cloud
    # placeholder on a local volume, so the cloud branch would otherwise be untestable. Splitting the
    # decision from the filesystem read makes it testable by attribute synthesis, and leaves the
    # END-TO-END hydration leg as the human measurement it has to be.
    #
    # Returns: none | refuse-link | hydrate-cloud | admit-nonlinking.
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Attributes,
        [AllowNull()][AllowEmptyString()][string]$LinkType,
        [AllowNull()][AllowEmptyString()][string]$LinkTarget
    )

    # Keep the constants inside the pure decision function. A guarded consumer can observe this
    # function from another dot-source scope while the policy file's `$script:` variables belong to
    # the loader that created them; the deployed review-engine hit exactly that split and failed under
    # StrictMode before it could hash its runtime. Local constants make the function self-contained.
    $attrReparsePoint = 0x00000400
    $attrOffline = 0x00001000
    $attrRecallOnOpen = 0x00040000
    $attrRecallOnDataAccess = 0x00400000
    # PINNED and UNPINNED are the stable half of the cloud family: unlike recall/offline, they survive
    # hydration and retain the consumer's cloud-storage choice.
    $attrPinned = 0x00080000
    $attrUnpinned = 0x00100000

    if (($Attributes -band $attrReparsePoint) -eq 0) {
        # No reparse bit means nothing to discriminate - and in particular an OFFLINE ordinary file is
        # NOT a placeholder: there is no reparse point to hydrate, and routing it through the hydration
        # path would be treating an ordinary file as cloud state.
        return [pscustomobject]@{ disposition = 'none'; family = 'ordinary'; link_type = $null }
    }

    # The redirecting family FIRST, and unconditionally. A link that also carries a recall attribute is
    # still a redirect; cloud-ness must never promote a link out of refusal, or the containment class
    # this check exists for reopens through the new branch.
    if (-not [string]::IsNullOrWhiteSpace($LinkType) -and $LinkType -in @('SymbolicLink', 'Junction')) {
        return [pscustomobject]@{ disposition = 'refuse-link'; family = 'redirecting'; link_type = $LinkType }
    }

    # The cloud family is BOTH halves: the retention choice (pinned/unpinned), which is stable and
    # survives hydration, and the not-yet-local markers, which are transient. Keying on the transient
    # half alone meant a file stopped being recognised as cloud-backed the moment it was downloaded -
    # so on a real install, where everything was hydrated, every file fell through to refuse-unknown.
    $cloudMask = $attrRecallOnDataAccess -bor $attrRecallOnOpen -bor $attrOffline -bor $attrPinned -bor $attrUnpinned
    # BOTH link signals must be absent before anything reaches this branch. LinkType is already known
    # not to be a symlink or junction by the check above, but "not a family we name" is not the same as
    # "not a link at all", and a host that exposes a TARGET without a TYPE still proves the path
    # redirects. Widening the cloud markers makes this guard load-bearing rather than theoretical:
    # without it, a redirect carrying a pinned bit would now be admitted.
    $redirects = (-not [string]::IsNullOrWhiteSpace($LinkType)) -or (-not [string]::IsNullOrWhiteSpace($LinkTarget))
    if ($redirects) {
        # A target without a named type still proves the path returns another file's bytes. Refusal is
        # keyed on REDIRECTION, which is the only property that matters to a read.
        return [pscustomobject]@{ disposition = 'refuse-link'; family = 'redirecting'; link_type = $LinkType }
    }
    if (($Attributes -band $cloudMask) -ne 0) {
        return [pscustomobject]@{ disposition = 'hydrate-cloud'; family = 'cloud-files'; link_type = $null }
    }

    # MAINTAINER RULING 2026-08-10 - refusal is EXACTLY the linking family, and a NON-LINKING reparse
    # point is ADMITTED with the HASH carrying the trust. Recorded in full because the reversal reads
    # like a loosening of a containment rule, and it is not:
    #
    #  - For a READ the only redirection that matters is "this path returns some OTHER file's bytes",
    #    which is exactly what LinkType and LinkTarget name - and .NET names it reliably for the
    #    redirecting family, symlink and junction, both measured live in this suite.
    #  - Every plausible non-linking tag in a module tree or an authority store is content
    #    VIRTUALIZATION rather than path redirection: cloud files, Windows Server dedup, ProjFS. The
    #    file IS the file; the bytes merely arrive later. Refusing them buys nothing.
    #  - Trust already rests on the hash of the bytes actually read (the security lens's S1 principle,
    #    ratified for the cloud family). Extending it to any non-linking tag applies that principle
    #    CONSISTENTLY instead of carving an exception around one vendor's attribute bits.
    #  - The "this would admit an AppExecLink" objection is true in general and does not reach these
    #    sites: an AppExecLink redirects EXECUTION, and none of the three call sites executes anything -
    #    they read text, hash it, and walk components for containment.
    #
    # THE RESIDUAL, stated as NOT KNOWN rather than impossible: an unknown tag that redirects a READ
    # without .NET naming it would now pass. No such tag is known, and the hash still catches wrong
    # bytes - but that is the honest wording. The durable fix is reading the REAL reparse tag, which
    # genuinely separates these; it needs P/Invoke and routes to BETA4 with the path-identity
    # consolidation, rather than being added to a shipped safety-critical hot path at the tail of an
    # over-scope feature.
    #
    # THE BOUNDARY: safe for READ, HASH and CONTAINMENT. NOT safe for a future call site that EXECUTES a
    # path, where an AppExecLink genuinely redirects and the hash proves nothing. This stays a DISTINCT
    # disposition from hydrate-cloud precisely so such a site can refuse it without reopening this
    # decision - ask Test-SpecrewReparseRefusesRead, never a bare equality against this value.
    return [pscustomobject]@{ disposition = 'admit-nonlinking'; family = 'non-linking'; link_type = $null }
}

function Test-SpecrewReparseRefusesRead {
    # The ONE question a READ / HASH / CONTAINMENT call site asks. A function rather than each site
    # spelling out its own set, because three hand-written sets are three things that drift apart - and
    # it gives a future EXECUTE site somewhere to add a stricter sibling instead of editing these
    # callers and rediscovering the whole argument.
    [OutputType([bool])]
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Disposition)
    return ($Disposition -ceq 'refuse-link')
}

function Get-SpecrewReparseDispositionForItem {
    # Classify an ALREADY-READ filesystem item. The containment walks hold a `Get-Item` handle for every
    # existing component already, so re-reading the path here would double the filesystem cost of the
    # hot loop these checks live in. More importantly it keeps the LinkType/LinkTarget extraction in ONE
    # place: a call site that re-derived "is this a link" for itself is precisely how a policy grows a
    # second, divergent answer.
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Item)

    $linkType = $null
    $linkTarget = $null
    # LinkType is absent on older hosts; its absence must not throw under StrictMode and must not be
    # read as "not a link" without also considering LinkTarget.
    if ($Item.PSObject.Properties['LinkType']) { $linkType = [string]$Item.LinkType }
    if ($Item.PSObject.Properties['LinkTarget']) { $linkTarget = [string]$Item.LinkTarget }
    if ([string]::IsNullOrWhiteSpace($linkType) -and -not [string]::IsNullOrWhiteSpace($linkTarget)) {
        # A host that exposes a target but not a type still proves the path REDIRECTS. Treated as the
        # refusing family rather than as unknown, because what matters is that it points elsewhere.
        $linkType = 'SymbolicLink'
    }
    # The raw target is passed through as well, not just folded into the type above: the cloud branch
    # requires BOTH signals absent, and it should not depend on this shim's inference to stay closed.
    return Resolve-SpecrewReparseDisposition -Attributes ([int]$Item.Attributes) -LinkType $linkType -LinkTarget $linkTarget
}

function Get-SpecrewReparseTagDisposition {
    # The thin shell that asks the filesystem, so every caller classifies the same way. A path that does
    # not exist reports 'none': the containment walks skip components that have not been created, and a
    # missing component cannot redirect a write that has not reached it.
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return [pscustomobject]@{ disposition = 'none'; family = 'ordinary'; link_type = $null } }
    if (-not (Test-Path -LiteralPath $Path)) { return [pscustomobject]@{ disposition = 'none'; family = 'ordinary'; link_type = $null } }

    return Get-SpecrewReparseDispositionForItem -Item (Get-Item -LiteralPath $Path -Force -ErrorAction Stop)
}

function Get-SpecrewReparseRefusalMessage {
    # The consumer half of FR-011, kept beside the policy so the words and the decision cannot drift.
    #
    # The MACHINE-READABLE code stays first and unchanged - existing refusal fixtures and callers match
    # on it, and a containment refusal is not the place to break a contract for prose. What follows is
    # the part a person can act on: what was found, why it is refused, and what to do instead. The old
    # message was the code alone, which told a consumer nothing about either.
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Path,
        [Parameter(Mandatory)][ValidateSet('refuse-link')][string]$Disposition,
        [AllowNull()][AllowEmptyString()][string]$LinkType
    )
    $kind = if ([string]$LinkType -ieq 'Junction') { 'a junction' } else { 'a symbolic link' }
    $what = "This path is $kind, so writing through it would put your review's records somewhere other than where they appear to be."
    return ('{0}:{1} - {2} Move the folder onto ordinary storage, or point the review at a path that is not a link, and run the command again. A cloud-synced folder such as OneDrive is fine; this refusal is specifically about links.' -f $Code, $Path, $what)
}
