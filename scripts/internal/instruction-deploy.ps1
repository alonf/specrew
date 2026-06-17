Set-StrictMode -Version Latest

# F-184 iteration 002 (T003; FR-011 / FR-015 / FR-016): manifest-driven, host-neutral
# deployment of the Specrew coordinator instruction section into every supported host's
# manifest-declared InstructionsFile.
#
# Host-neutral (FR-015): the InstructionsFile location comes from host.psd1; there are NO
# host-name (`agy`/Antigravity/claude/...) branches here. Used by `specrew init` (deploy),
# `specrew update` (refresh), and `specrew start` (heal). The host registry
# (Get-RegisteredHostKinds / Get-HostManifest from hosts/_registry.ps1) must be loaded by
# the caller; the merge primitive is dot-sourced below.

. (Join-Path $PSScriptRoot 'instruction-file-merge.ps1')

function Deploy-SpecrewCoordinatorInstructions {
    # Deploy/refresh/heal the coordinator managed section into each supported host's
    # InstructionsFile under $ProjectRoot. Idempotent (init/update/start-heal converge).
    # Hosts that share an InstructionsFile (e.g. AGENTS.md across codex/antigravity/cursor)
    # are written once. Returns one result row per supported host:
    # { Kind, InstructionsFile, Path, Changed, Created, SharedWith }.
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$HostKind
    )

    if (-not (Get-Command -Name Get-RegisteredHostKinds -ErrorAction SilentlyContinue)) {
        throw "Deploy-SpecrewCoordinatorInstructions requires the host registry (hosts/_registry.ps1) to be loaded."
    }

    $fragment = Get-SpecrewCoordinatorFragment
    $kinds = if (-not [string]::IsNullOrWhiteSpace($HostKind)) { @($HostKind.ToLowerInvariant()) } else { @(Get-RegisteredHostKinds) }

    $results = [System.Collections.Generic.List[object]]::new()
    $deployedPaths = @{}

    foreach ($kind in $kinds) {
        $manifest = Get-HostManifest -Kind $kind

        $status = if ($manifest.ContainsKey('Status')) { [string]$manifest['Status'] } else { '' }
        if ($status -ne 'supported') { continue }

        $instructionsFile = if ($manifest.ContainsKey('InstructionsFile')) { [string]$manifest['InstructionsFile'] } else { '' }
        if ([string]::IsNullOrWhiteSpace($instructionsFile)) { continue }  # host declares no InstructionsFile -> skip gracefully

        $target = Join-Path $ProjectRoot $instructionsFile
        $key = $target.ToLowerInvariant()

        if ($deployedPaths.ContainsKey($key)) {
            # Another supported host shares this InstructionsFile; the section is already there.
            $results.Add([pscustomobject]@{
                    Kind = $kind; InstructionsFile = $instructionsFile; Path = $target
                    Changed = $false; Created = $false; SharedWith = $deployedPaths[$key]
                }) | Out-Null
            continue
        }

        $res = Set-SpecrewInstructionFileSection -Path $target -ManagedContent $fragment
        $deployedPaths[$key] = $kind
        $results.Add([pscustomobject]@{
                Kind = $kind; InstructionsFile = $instructionsFile; Path = $target
                Changed = $res.Changed; Created = $res.Created; SharedWith = $null
            }) | Out-Null
    }

    return $results.ToArray()
}

function Invoke-SpecrewInstructionDeployment {
    # Integration entry point for `specrew init` (deploy), `specrew update` (refresh), and
    # `specrew start` (heal). Self-loads the host registry with a fail-open ladder, deploys
    # the coordinator section into every supported host's InstructionsFile, and returns
    # action rows for the caller to report. Fail-open: instruction-deploy problems NEVER fail
    # init/update/start.
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath
    )
    $actions = [System.Collections.Generic.List[object]]::new()

    if (-not (Get-Command -Name Get-RegisteredHostKinds -ErrorAction SilentlyContinue)) {
        $registryPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'hosts/_registry.ps1'
        if (Test-Path -LiteralPath $registryPath -PathType Leaf) {
            try { . $registryPath } catch { $null = $_ }
        }
    }
    if (-not (Get-Command -Name Get-RegisteredHostKinds -ErrorAction SilentlyContinue)) {
        $actions.Add([pscustomobject]@{ HostKind = '(registry)'; Action = 'coordinator-instructions-skipped'; Detail = 'host registry unavailable' }) | Out-Null
        return $actions.ToArray()
    }

    try {
        foreach ($r in @(Deploy-SpecrewCoordinatorInstructions -ProjectRoot $ProjectPath)) {
            $detail = if ($r.SharedWith) { ('{0} (shared with {1})' -f $r.InstructionsFile, $r.SharedWith) }
            elseif ($r.Created) { ('{0} created' -f $r.InstructionsFile) }
            elseif ($r.Changed) { ('{0} refreshed' -f $r.InstructionsFile) }
            else { ('{0} already current' -f $r.InstructionsFile) }
            $actions.Add([pscustomobject]@{ HostKind = $r.Kind; Action = 'coordinator-instructions'; Detail = $detail }) | Out-Null
        }
    }
    catch {
        $actions.Add([pscustomobject]@{ HostKind = '(all)'; Action = 'coordinator-instructions-failed'; Detail = $_.Exception.Message }) | Out-Null
    }
    return $actions.ToArray()
}
