[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    # The boundary the readiness check is for. before-implement is the one that reached a consumer with its
    # verdict summarized away (B4F-071); the rule is the same for any human-judgment boundary.
    [string]$Boundary = 'before-implement',
    [switch]$AsJson
)

# THE OVERALL VERDICT LINE, DERIVED FROM THE LEDGER, NOT FROM THE AGENT'S REPORT (B4F-071, 2026-09-10).
#
# On the router-skill project the before-implement readiness sub-agent read the ledger correctly and wrote
# "Overall verdict: BLOCKED for implementation - no tasks -> before-implement authorization exists". The crew
# summarized the passing artifact checks as PASS, dropped that line, and announced implementation. The only
# thing between BLOCKED and the first product-source task was the maintainer reading the packet.
#
# This script prints that one line from the ledger. The governed before-implement command runs it and its
# output is the FIRST line of the readiness report, verbatim; the coordinator quotes it verbatim in the
# packet. A summary can drop a sentence an agent wrote; it has no reason to drop a line a script printed
# whose absence the packet rule names. Exit 0 either way: the line is the evidence, not a gate - the gate
# that cannot be summarized away is the Stop hook's source-write guard (beta5 first item).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) { throw "Missing shared governance helper '$sharedGovernancePath'." }
. $sharedGovernancePath

$root = Resolve-ProjectPath -Path $ProjectPath
$canonical = Normalize-SpecrewCanonicalBoundaryType -Boundary $Boundary
if ([string]::IsNullOrWhiteSpace($canonical)) { throw "Unrecognized boundary '$Boundary'." }
$order = @(Get-SpecrewBoundaryOrder)
$targetIdx = [Array]::IndexOf($order, $canonical)

$lastAuthorized = ''
$pendingText = 'no crossing is pending'
$ledgerReadable = $true
try {
    $state = Get-SpecrewBoundaryEnforcementState -ProjectRoot $root
    if ($null -eq $state -or $null -eq $state.EffectiveState) { $ledgerReadable = $false }
    else {
        $lastAuthorized = [string]$state.EffectiveState['last_authorized_boundary']
        if ($state.State.Contains('pending_crossing') -and $null -ne $state.State['pending_crossing']) {
            $scope = ConvertTo-SpecrewBoundaryMap -Value $state.State['pending_crossing']
            if ($null -ne $scope) { $pendingText = ("the pending crossing is '{0} -> {1}'" -f [string]$scope['from_boundary'], [string]$scope['to_boundary']) }
        }
    }
}
catch { $ledgerReadable = $false }

$lastIdx = if ([string]::IsNullOrWhiteSpace($lastAuthorized)) { -1 } else { [Array]::IndexOf($order, (Normalize-SpecrewCanonicalBoundaryType -Boundary $lastAuthorized)) }
$authorized = ($ledgerReadable -and $targetIdx -ge 0 -and $lastIdx -ge $targetIdx)
$lastText = if ([string]::IsNullOrWhiteSpace($lastAuthorized)) { 'no boundary is authorized yet' } else { ("the ledger's last authorized boundary is '{0}'" -f $lastAuthorized) }
$line = if (-not $ledgerReadable) {
    ("Overall verdict: BLOCKED for implementation - the boundary ledger (.specrew/start-context.json) could not be read, so '{0}' cannot be shown as authorized." -f $canonical)
}
elseif ($authorized) {
    ("Overall verdict: READY for implementation - '{0}' is authorized ({1})." -f $canonical, $lastText)
}
else {
    ("Overall verdict: BLOCKED for implementation - '{0}' is not authorized: {1}; {2}. The human's typed 'approved for {0}' against the presented crossing is what clears this; nothing else does." -f $canonical, $lastText, $pendingText)
}

if ($AsJson) {
    [pscustomobject]@{ boundary = $canonical; authorized = $authorized; last_authorized_boundary = $lastAuthorized; pending = $pendingText; line = $line } | ConvertTo-Json -Compress
}
else {
    Write-Output $line
}
exit 0
