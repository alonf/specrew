# Feature 203 T002 (DA-8): the live-engine pin. In the Specrew self-host repo the live hooks load engine code
# (scripts/internal/bootstrap, scripts/internal/continuous-co-review, hosts/) from the project working tree first,
# so an unreviewed edit would judge the maintainer's next approval. A pin is a detached checkout of the last
# reviewed commit OUTSIDE the worktree; when one is configured, every engine lookup resolves to it.
#
# Inert until configured: with no `.specrew/runtime/live-engine.json`, Get-SpecrewLiveEnginePin reports
# Configured=$false and every caller keeps today's resolution. A configured pin that is missing or corrupt is
# never silently replaced by the worktree source or an installed module: callers refuse, in plain words.
# The record is machine-local (.specrew/runtime/ is git-ignored) and written only by scripts/internal/live-engine-pin.ps1.

$script:SpecrewLiveEngineRequiredFiles = @(
    'scripts/internal/bootstrap/HandoverStore.ps1',
    'scripts/internal/bootstrap/HumanAuthorityStore.ps1',
    'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1',
    'scripts/internal/continuous-co-review/worktree-navigator.ps1',
    'extensions/specrew-speckit/scripts/shared-governance.ps1',
    '.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1'
)

function Get-SpecrewLiveEngineRecordPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    return (Join-Path $ProjectRoot '.specrew/runtime/live-engine.json')
}

function Get-SpecrewLiveEngineBindingsPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    return (Join-Path $ProjectRoot '.specrew/runtime/live-engine-bindings.json')
}

function Write-SpecrewLiveEngineBindings {
    # Review round 3, finding 1: with a pin, the hooks use host bindings taken from the pin and stamped with its commit.
    # A binding holds the rules for what counts as a typed approval, so one baked into the hook settings by a later,
    # unreviewed deploy must not apply to the pinned engine. Written by the pin script at Create and Advance; the
    # launchers refuse a binding whose stamp is not the pin's commit, before any pin code runs.
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PinRoot,
        [Parameter(Mandatory = $true)][string]$Commit
    )
    $deploy = Join-Path $PinRoot 'extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1'
    if (-not (Test-Path -LiteralPath $deploy -PathType Leaf)) {
        throw ("The pinned copy at {0} has no deploy-refocus-hooks.ps1, so its host settings cannot be written." -f $PinRoot)
    }
    $bindings = [ordered]@{}
    foreach ($dir in @(Get-ChildItem -LiteralPath (Join-Path $PinRoot 'hosts') -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
        $manifestPath = Join-Path $dir.FullName 'host.psd1'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { continue }
        $hookBindings = (Import-PowerShellDataFile -LiteralPath $manifestPath)['RefocusHookBindings']
        if ($null -eq $hookBindings -or $null -eq $hookBindings['DispatcherRuntime']) { continue }
        # The pin's own deployer computes the binding, so it is exactly what a deploy from the pin would bake.
        $out = @(& pwsh -NoProfile -File $deploy -ProjectPath $ProjectRoot -HostKind $dir.Name -EmitBindingOnly 2>&1)
        $binding = ([string]($out | Select-Object -Last 1)).Trim()
        if ($LASTEXITCODE -ne 0 -or $binding -notmatch '^[A-Za-z0-9+/=]+$') {
            throw ("The pinned copy's host settings for {0} could not be read: {1}" -f $dir.Name, (($out | Out-String).Trim()))
        }
        $bindings[$dir.Name] = $binding
    }
    if ($bindings.Count -eq 0) { throw ("The pinned copy at {0} declares no host settings." -f $PinRoot) }
    $path = Get-SpecrewLiveEngineBindingsPath -ProjectRoot $ProjectRoot
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $record = [ordered]@{ schema_version = '1'; commit = $Commit.ToLowerInvariant(); bindings = $bindings }
    $tmp = "$path.tmp"
    Set-Content -LiteralPath $tmp -Value ($record | ConvertTo-Json -Depth 4) -Encoding UTF8
    Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-SpecrewLiveEngineCheckoutHead {
    # The pin is a `git worktree`, so its `.git` is a file naming the gitdir; a detached HEAD there is a bare sha.
    # Read directly rather than spawning git: this runs on every hook fire. $null when it is not a detached checkout.
    param([Parameter(Mandatory = $true)][string]$PinPath)
    $dotGit = Join-Path $PinPath '.git'
    $gitDir = $null
    if (Test-Path -LiteralPath $dotGit -PathType Leaf) {
        $line = [string](Get-Content -LiteralPath $dotGit -TotalCount 1 -ErrorAction Stop)
        if ($line -notmatch '^gitdir:\s*(?<dir>.+)$') { return $null }
        $gitDir = $Matches['dir'].Trim()
        if (-not [System.IO.Path]::IsPathRooted($gitDir)) { $gitDir = Join-Path $PinPath $gitDir }
    }
    elseif (Test-Path -LiteralPath $dotGit -PathType Container) { $gitDir = $dotGit }
    else { return $null }
    $headPath = Join-Path $gitDir 'HEAD'
    if (-not (Test-Path -LiteralPath $headPath -PathType Leaf)) { return $null }
    $head = ([string](Get-Content -LiteralPath $headPath -TotalCount 1 -ErrorAction Stop)).Trim()
    if ($head -notmatch '^[0-9a-f]{40}$') { return $null }
    return $head
}

function Get-SpecrewLiveEnginePin {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $recordPath = Get-SpecrewLiveEngineRecordPath -ProjectRoot $ProjectRoot
    $result = [ordered]@{ Configured = $false; Valid = $false; Root = $null; Commit = $null; Reason = $null; Detail = $null }
    if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf)) { return [pscustomobject]$result }
    $result.Configured = $true

    $record = $null
    try { $record = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
    catch { $record = $null }
    $path = if ($null -ne $record -and $record.PSObject.Properties['path']) { [string]$record.path } else { '' }
    $commit = if ($null -ne $record -and $record.PSObject.Properties['commit']) { ([string]$record.commit).ToLowerInvariant() } else { '' }
    if ([string]::IsNullOrWhiteSpace($path) -or $commit -notmatch '^[0-9a-f]{40}$') {
        $result.Reason = 'record-unreadable'
        return [pscustomobject]$result
    }
    $result.Root = $path
    $result.Commit = $commit
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { $result.Reason = 'pin-missing'; return [pscustomobject]$result }

    $head = $null
    try { $head = Get-SpecrewLiveEngineCheckoutHead -PinPath $path } catch { $head = $null }
    if ($null -eq $head) { $result.Reason = 'pin-not-a-checkout'; return [pscustomobject]$result }
    if ($head -ne $commit) { $result.Reason = 'pin-commit-mismatch'; $result.Detail = $head; return [pscustomobject]$result }
    foreach ($rel in $script:SpecrewLiveEngineRequiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $path $rel) -PathType Leaf)) {
            $result.Reason = 'pin-engine-file-missing'
            $result.Detail = $rel
            return [pscustomobject]$result
        }
    }
    $result.Valid = $true
    return [pscustomobject]$result
}

function Get-SpecrewLiveEngineRefusalMessage {
    # Human-facing: what could not be done, that nothing was recorded and earlier approvals stand, one recovery
    # action and a request for approval. No internal codes; the reason code goes to the caller's journal.
    param([Parameter(Mandatory = $true)]$Pin)
    $where = if ([string]::IsNullOrWhiteSpace([string]$Pin.Root)) { 'the pinned copy' } else { ('the pinned copy at {0}' -f [string]$Pin.Root) }
    $problem = switch ([string]$Pin.Reason) {
        'record-unreadable' { 'Its settings file (.specrew/runtime/live-engine.json) could not be read.' }
        'pin-missing' { ('{0} does not exist.' -f $where) }
        'pin-not-a-checkout' { ('{0} is not a checked-out copy of the repository.' -f $where) }
        'pin-commit-mismatch' { ('{0} is not at the reviewed commit it was set to.' -f $where) }
        'pin-engine-file-missing' { ('{0} is missing {1}.' -f $where, [string]$Pin.Detail) }
        default { ('{0} could not be used.' -f $where) }
    }
    $short = if ([string]$Pin.Commit -match '^[0-9a-f]{40}$') { ([string]$Pin.Commit).Substring(0, 8) } else { 'the last reviewed commit' }
    return ("Specrew could not load its reviewed engine for this project, so it recorded nothing from this turn. {0} Your earlier approvals and answers are unchanged. To fix it, the crew can re-create the pinned copy at {1} with scripts/internal/live-engine-pin.ps1. Should it do that?" -f $problem, $short)
}

function Resolve-SpecrewLiveEngineInternalRoot {
    # The scripts/internal root engine code is loaded from. Returns an object: Refused ($true when a configured pin
    # is unusable), Root (the pin's scripts/internal when valid; the project's when no pin is configured; $null when
    # refused), and Pin.
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $pin = Get-SpecrewLiveEnginePin -ProjectRoot $ProjectRoot
    if (-not [bool]$pin.Configured) {
        return [pscustomobject]@{ Refused = $false; Root = (Join-Path $ProjectRoot 'scripts/internal'); Pin = $pin }
    }
    if (-not [bool]$pin.Valid) { return [pscustomobject]@{ Refused = $true; Root = $null; Pin = $pin } }
    return [pscustomobject]@{ Refused = $false; Root = (Join-Path ([string]$pin.Root) 'scripts/internal'); Pin = $pin }
}

function Import-SpecrewAuthorizationSenderCheck {
    # Feature 203 T013 (B5F-066) and iteration review round C, finding 1: loads the check that confirms the human typed the
    # message an authorization came from (Test-SpecrewAuthorizationRecordSender, from the bootstrap store), for the readers
    # that run without the bootstrap store (shared-governance, workshop-authority-store, record-design-decision). Returns
    # $true when the check is available.
    # A configured live-engine pin is the only engine the check may come from: the rules for what counts as a typed approval
    # are engine code, so a development tree named by SPECREW_MODULE_PATH must not decide them before the pin advances. A
    # configured pin that cannot be used (or whose record cannot be resolved) resolves no check, and the caller refuses.
    # With no pin configured, the order is today's: SPECREW_MODULE_PATH; the project this file sits in, walking up (the
    # working tree in the self-host repo; extensions/ or the deployed .specify/ copy, at different depths); the installed
    # module. The first store that holds the check is loaded once, into a global module, so later calls reuse it.
    [OutputType([bool])]
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    if (Get-Command Test-SpecrewAuthorizationRecordSender -ErrorAction SilentlyContinue) { return $true }
    $engine = $null
    try { $engine = Resolve-SpecrewLiveEngineInternalRoot -ProjectRoot $ProjectRoot } catch { return $false }
    $candidates = [System.Collections.Generic.List[string]]::new()
    if ([bool]$engine.Pin.Configured) {
        if ([bool]$engine.Refused) { return $false }
        $candidates.Add((Join-Path ([string]$engine.Root) 'bootstrap'))
    }
    else {
        if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH)) { $candidates.Add((Join-Path $env:SPECREW_MODULE_PATH 'scripts\internal\bootstrap')) }
        $walk = $PSScriptRoot
        for ($depth = 0; $depth -lt 8 -and -not [string]::IsNullOrWhiteSpace($walk); $depth++) {
            $candidates.Add((Join-Path $walk 'scripts\internal\bootstrap'))
            $walk = Split-Path -Parent $walk
        }
        foreach ($module in @(Get-Module -Name Specrew) + @(Get-Module -ListAvailable -Name Specrew | Sort-Object Version -Descending)) {
            if ($null -ne $module) { $candidates.Add((Join-Path $module.ModuleBase 'scripts\internal\bootstrap')) }
        }
    }
    foreach ($dir in $candidates) {
        $store = Join-Path $dir 'HumanAuthorityStore.ps1'
        $accessor = Join-Path $dir 'ConversationCaptureAccessor.ps1'
        if (-not ((Test-Path -LiteralPath $store -PathType Leaf) -and (Test-Path -LiteralPath $accessor -PathType Leaf))) { continue }
        if (-not (Select-String -LiteralPath $store -Pattern 'function Test-SpecrewAuthorizationRecordSender\b' -Quiet)) { continue }
        try {
            $null = New-Module -Name 'SpecrewAuthorizationSenderCheck' -ArgumentList $accessor, $store -ScriptBlock {
                param($AccessorPath, $StorePath)
                . $AccessorPath
                . $StorePath
                Export-ModuleMember -Function *
            } | Import-Module -Global -Force -DisableNameChecking -PassThru
        }
        catch { $null = $_ }
        if (Get-Command Test-SpecrewAuthorizationRecordSender -ErrorAction SilentlyContinue) { return $true }
    }
    return $false
}

function Resolve-SpecrewLiveEngineExtensionScript {
    # A script from the deployed extension tree that the hooks load as code (not data): the pin's copy when a pin is
    # configured and usable, the project's .specify copy when none is configured (today's resolution), and $null when
    # a configured pin is unusable. The hooks run from the pin's .specify, so the project's copy is unreviewed code.
    param([Parameter(Mandatory = $true)][string]$ProjectRoot, [Parameter(Mandatory = $true)][string]$Name)
    $pin = Get-SpecrewLiveEnginePin -ProjectRoot $ProjectRoot
    $base = if (-not [bool]$pin.Configured) { $ProjectRoot } elseif ([bool]$pin.Valid) { [string]$pin.Root } else { return $null }
    return (Join-Path $base (Join-Path '.specify/extensions/specrew-speckit/scripts' $Name))
}
