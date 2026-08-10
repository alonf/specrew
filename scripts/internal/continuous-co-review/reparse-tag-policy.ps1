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

# Windows file attributes that mark a cloud placeholder. Not in [IO.FileAttributes] as named members
# across all targets, so they are declared here once rather than re-spelled at each call site.
$script:SpecrewAttrReparsePoint = 0x00000400
$script:SpecrewAttrOffline = 0x00001000
$script:SpecrewAttrRecallOnOpen = 0x00040000
$script:SpecrewAttrRecallOnDataAccess = 0x00400000
# PINNED and UNPINNED are the STABLE half of the cloud family, and leaving them out was the defect
# (DRIFT-199-I001-023). The three attributes above all describe a file that is NOT CURRENTLY
# DOWNLOADED - a transient state a file leaves the moment anyone reads it. These two describe the
# consumer's RETENTION CHOICE for a cloud-backed file and survive hydration, which is the property
# this predicate actually means to test.
$script:SpecrewAttrPinned = 0x00080000
$script:SpecrewAttrUnpinned = 0x00100000

function Resolve-SpecrewReparseDisposition {
    # PURE decision over (attributes, link type). Pure on purpose: no agent can materialise a cloud
    # placeholder on a local volume, so the cloud branch would otherwise be untestable. Splitting the
    # decision from the filesystem read makes it testable by attribute synthesis, and leaves the
    # END-TO-END hydration leg as the human measurement it has to be.
    #
    # Returns: none | refuse-link | hydrate-cloud | refuse-unknown.
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Attributes,
        [AllowNull()][AllowEmptyString()][string]$LinkType,
        [AllowNull()][AllowEmptyString()][string]$LinkTarget
    )

    if (($Attributes -band $script:SpecrewAttrReparsePoint) -eq 0) {
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
    $cloudMask = $script:SpecrewAttrRecallOnDataAccess -bor $script:SpecrewAttrRecallOnOpen -bor
    $script:SpecrewAttrOffline -bor $script:SpecrewAttrPinned -bor $script:SpecrewAttrUnpinned
    # BOTH link signals must be absent before anything reaches this branch. LinkType is already known
    # not to be a symlink or junction by the check above, but "not a family we name" is not the same as
    # "not a link at all", and a host that exposes a TARGET without a TYPE still proves the path
    # redirects. Widening the cloud markers makes this guard load-bearing rather than theoretical:
    # without it, a redirect carrying a pinned bit would now be admitted.
    $redirects = (-not [string]::IsNullOrWhiteSpace($LinkType)) -or (-not [string]::IsNullOrWhiteSpace($LinkTarget))
    if ((-not $redirects) -and (($Attributes -band $cloudMask) -ne 0)) {
        return [pscustomobject]@{ disposition = 'hydrate-cloud'; family = 'cloud-files'; link_type = $null }
    }

    # ALLOWLIST, so the fail direction is REFUSAL. An unrecognised reparse tag - a container-isolation
    # tag, a filter driver's own - is refused rather than admitted. This is the mirror of FR-009's
    # allowlist, where the safe direction was nagging; here admitting an unknown redirect is how the
    # containment class returns, so the safe direction is to refuse.
    return [pscustomobject]@{ disposition = 'refuse-unknown'; family = 'unknown'; link_type = $null }
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
        [Parameter(Mandatory)][ValidateSet('refuse-link', 'refuse-unknown')][string]$Disposition,
        [AllowNull()][AllowEmptyString()][string]$LinkType
    )
    $what = if ($Disposition -ceq 'refuse-link') {
        $kind = if ([string]$LinkType -ceq 'Junction') { 'a junction' } else { 'a symbolic link' }
        "This path is $kind, so writing through it would put your review's records somewhere other than where they appear to be."
    }
    else {
        'This path is a kind of link this version does not recognise, and it is refused rather than followed blindly.'
    }
    return ('{0}:{1} - {2} Move the folder onto ordinary storage, or point the review at a path that is not a link, and run the command again. A cloud-synced folder such as OneDrive is fine; this refusal is specifically about links.' -f $Code, $Path, $what)
}
