# T019 / FR-048 — the framework-NEUTRAL, ORDERED verification-PLAN contract (amended 2026-07-13).
#
# WHAT THIS IS: the contract layer for the verification plan a downstream command-plan SUPPLIER
# produces and the universal T018 recorded-run runner EXECUTES (see verification-plan-runner.ps1).
# Given a plan or a command object these functions return a DECISION. NOTHING here discovers, infers,
# selects, or invents a command — command DISCOVERY/inference is a SEPARATE downstream concern this
# layer deliberately does NOT do. All functions are PURE except Test-...VerificationPathSafe, which
# consults the filesystem ONLY to dereference an existing symlink/junction for the escape check.
#
# THE INVARIANTS this contract encodes (maintainer amendment 2026-07-13):
#  1. FRAMEWORK-NEUTRAL: a command is just { command_id, executable, arguments, provenance, ... }.
#     pytest / cargo test / dotnet test / a custom shell script are all equally acceptable — this
#     layer carries NO per-framework knowledge and never privileges one technology over another.
#  2. ORDER IS LOAD-BEARING: commands execute in DECLARED order and this layer NEVER sorts them.
#  3. STABLE IDENTITY: the plan carries a `plan_id`; each command carries a `command_id` that is
#     REQUIRED and UNIQUE within the plan (evidence joins bind on command_id + reviewed-tree digest).
#  4. ARGUMENTS ARE A STRING ARRAY, NOT A SHELL STRING: shell behaviour must be an explicit
#     interpreter invocation (pwsh -File ... / bash -lc ...). A single-string `arguments` is REJECTED.
#  5. PATH SAFETY: working_directory / result_path MUST be repository-relative + canonical; a rooted
#     path, a `..` escape, or a symlink/junction resolving outside RepoRoot is REJECTED.
#  6. TIMEOUT IS BOUNDED BY ENGINE POLICY: a supplier can NEVER request an unlimited run. A requested
#     0/absent resolves to the engine DEFAULT; a request over the engine MAX is clamped.
#  7. AUDITABLE PROVENANCE OBJECT: provenance is { kind, source, provider?, profile? } — not a bare
#     enum — so every command records HOW it entered the plan.
#  8. NO SECRETS: neither a plan nor recorded evidence may embed literal env VALUES. Env customization
#     is declared as `env_refs` (env var NAMES only); a literal `env`/`environment` map is REJECTED.
#  9. AN EMPTY PLAN IS NEVER A SILENT SUCCESS: a null/empty/all-invalid plan resolves to the EXPLICIT
#     `verification-not-configured` state, never a fabricated pass.
#
# Reuses Get-ContinuousCoReviewContractProp (StrictMode-safe property read) from review-identity-
# contracts.ps1; bootstraps it if this file is dot-sourced before that one.

if (-not (Get-Command -Name 'Get-ContinuousCoReviewContractProp' -ErrorAction SilentlyContinue)) {
    $ricPath = Join-Path $PSScriptRoot 'review-identity-contracts.ps1'
    if (Test-Path -LiteralPath $ricPath -PathType Leaf) { . $ricPath }
}

# StrictMode-safe property read that PRESERVES array-ness. The shared Get-ContinuousCoReviewContractProp
# returns $prop.Value directly, which PowerShell ENUMERATES on return — so an empty-array property reads
# back as $null and a single-element array reads back as a scalar. That is fatal to the array-vs-string
# type checks below (arguments / env_refs / commands), so those reads use this accessor, whose `, $val`
# wrapper stops the enumeration and keeps @() as @(), @('x') as a 1-element array, and 'x' as a string.
function Get-ContinuousCoReviewVerificationRawProp {
    param([Parameter(Mandatory)][AllowNull()]$Object, [Parameter(Mandatory)][string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return , $Object[$Name] }
        return $null
    }
    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) { return $null }
    return , $prop.Value
}

# ENGINE-POLICY timeout bounds. A supplier's requested timeout is always resolved through these — a
# request can never buy an unlimited run. (Module constants, read through the accessors below.)
$script:ContinuousCoReviewMaxVerificationTimeoutSeconds = 3600
$script:ContinuousCoReviewDefaultVerificationTimeoutSeconds = 900

function Get-ContinuousCoReviewMaxVerificationTimeoutSeconds { return $script:ContinuousCoReviewMaxVerificationTimeoutSeconds }
function Get-ContinuousCoReviewDefaultVerificationTimeoutSeconds { return $script:ContinuousCoReviewDefaultVerificationTimeoutSeconds }

# The FOUR — and only four — valid provenance KIND values a supplier may stamp on a command, naming
# HOW the command entered the plan. This layer validates membership only; it never RESOLVES provenance.
function Get-ContinuousCoReviewVerificationProvenanceValues {
    return @('project-config', 'project-detected', 'profile-selected', 'provider-gated')
}

# Resolve a supplier's REQUESTED timeout to the effective, ENGINE-BOUNDED seconds. A requested 0/absent
# (or negative) becomes the engine DEFAULT — NEVER unlimited; a request over the engine MAX is clamped
# to the max and flagged. Pure; returns { effective_seconds; clamped; source; reason }.
function Resolve-ContinuousCoReviewVerificationTimeout {
    param([int]$Requested = 0)
    $max = Get-ContinuousCoReviewMaxVerificationTimeoutSeconds
    $default = Get-ContinuousCoReviewDefaultVerificationTimeoutSeconds
    if ($Requested -le 0) {
        return [pscustomobject]@{ effective_seconds = $default; clamped = $false; source = 'engine-default'; reason = "requested 0/absent -> engine default ${default}s (a supplier can never request an unlimited run)" }
    }
    if ($Requested -gt $max) {
        return [pscustomobject]@{ effective_seconds = $max; clamped = $true; source = 'engine-max-clamp'; reason = "requested ${Requested}s exceeds the engine max ${max}s -> clamped to ${max}s" }
    }
    return [pscustomobject]@{ effective_seconds = $Requested; clamped = $false; source = 'supplier-requested'; reason = $null }
}

# PATH SAFETY (FR-048 amendment 4). A working_directory / result_path MUST be repository-relative and
# resolve INSIDE RepoRoot. REJECTED when: null-safe-empty is fine; a rooted/absolute path; a `..`
# escape (checked lexically via GetFullPath so a not-yet-created path is still guarded); or — for a
# path that already exists — a symlink/junction whose real target resolves OUTSIDE RepoRoot. Returns
# { safe; reason; canonical_relative }.
function Test-ContinuousCoReviewVerificationPathSafe {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][AllowEmptyString()][AllowNull()][string]$Path
    )
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return [pscustomobject]@{ safe = $true; reason = $null; canonical_relative = '' }
    }
    # Rooted/absolute (drive-letter, UNC, or leading slash) is rejected up front for a crisp reason.
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [pscustomobject]@{ safe = $false; reason = "path '$Path' is absolute/rooted; must be repository-relative"; canonical_relative = $null }
    }
    $rootFull = ([System.IO.Path]::GetFullPath($RepoRoot)).TrimEnd([char]'\', [char]'/')
    $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    $combined = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $Path))
    # LEXICAL escape guard: after canonicalizing '..', the path must still sit under the root prefix.
    if (-not ($combined.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or $combined.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase))) {
        return [pscustomobject]@{ safe = $false; reason = "path '$Path' escapes the repository root via '..'"; canonical_relative = $null }
    }
    # SYMLINK/JUNCTION escape guard: only resolvable when the target already exists on disk. Follow the
    # link chain to its final real target and require it to stay inside RepoRoot.
    if (Test-Path -LiteralPath $combined) {
        try {
            $item = Get-Item -LiteralPath $combined -Force -ErrorAction Stop
            $target = $item.ResolveLinkTarget($true)
            if ($null -ne $target) {
                $real = ([System.IO.Path]::GetFullPath($target.FullName)).TrimEnd([char]'\', [char]'/')
                if (-not ($real.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or ($real + [System.IO.Path]::DirectorySeparatorChar).StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase))) {
                    return [pscustomobject]@{ safe = $false; reason = "path '$Path' resolves via a symlink/junction OUTSIDE the repository root"; canonical_relative = $null }
                }
            }
        }
        catch { $null = $_ }
    }
    $canonical = $combined.Substring($rootFull.Length).TrimStart([char]'\', [char]'/').Replace('\', '/')
    return [pscustomobject]@{ safe = $true; reason = $null; canonical_relative = $canonical }
}

# PROVENANCE OBJECT validation (FR-048 amendment 6). provenance MUST be an object (never a bare string):
# { kind (one of the four values), source (required non-empty), provider (required when
# kind='provider-gated'), profile (required when kind='profile-selected') }. Returns { valid; reason }.
function Test-ContinuousCoReviewVerificationProvenance {
    param([Parameter(Mandatory)][AllowNull()]$Provenance)
    if ($null -eq $Provenance) {
        return [pscustomobject]@{ valid = $false; reason = 'provenance is required (an object { kind, source, ... })' }
    }
    if ($Provenance -is [string]) {
        return [pscustomobject]@{ valid = $false; reason = 'provenance must be an OBJECT { kind, source, ... }, not a bare string/enum' }
    }
    $kind = [string](Get-ContinuousCoReviewContractProp -Object $Provenance -Name 'kind')
    if ($kind -notin (Get-ContinuousCoReviewVerificationProvenanceValues)) {
        return [pscustomobject]@{ valid = $false; reason = "provenance.kind '$kind' is not one of: $((Get-ContinuousCoReviewVerificationProvenanceValues) -join ', ')" }
    }
    $source = [string](Get-ContinuousCoReviewContractProp -Object $Provenance -Name 'source')
    if ([string]::IsNullOrWhiteSpace($source)) {
        return [pscustomobject]@{ valid = $false; reason = 'provenance.source is required (the config path / detection signal / profile name / provider id)' }
    }
    if ($kind -eq 'provider-gated') {
        $provider = [string](Get-ContinuousCoReviewContractProp -Object $Provenance -Name 'provider')
        if ([string]::IsNullOrWhiteSpace($provider)) {
            return [pscustomobject]@{ valid = $false; reason = "provenance.provider is required when kind='provider-gated'" }
        }
    }
    if ($kind -eq 'profile-selected') {
        $profile = [string](Get-ContinuousCoReviewContractProp -Object $Provenance -Name 'profile')
        if ([string]::IsNullOrWhiteSpace($profile)) {
            return [pscustomobject]@{ valid = $false; reason = "provenance.profile is required when kind='profile-selected'" }
        }
    }
    return [pscustomobject]@{ valid = $true; reason = $null }
}

# Validate ONE VerificationCommand. Invalid when: the object is null; command_id is null/empty;
# executable is null/empty; arguments is present but NOT a string array (a single shell string is
# rejected); provenance fails Test-...VerificationProvenance; a literal env/environment map is present
# (secrets forbidden); env_refs is present but not an array of non-empty NAMES (no 'NAME=value'
# literals); or a working_directory/result_path is path-UNSAFE. -RepoRoot enables real path resolution;
# when omitted, path safety falls back to a non-existent sentinel root so lexical escapes are still
# caught. Pure (except the path-safety filesystem symlink check). Returns { valid; reason }.
function Test-ContinuousCoReviewVerificationCommand {
    param(
        [Parameter(Mandatory)][AllowNull()]$Command,
        [string]$RepoRoot
    )
    if ($null -eq $Command) {
        return [pscustomobject]@{ valid = $false; reason = 'command is null' }
    }
    $commandId = [string](Get-ContinuousCoReviewContractProp -Object $Command -Name 'command_id')
    if ([string]::IsNullOrWhiteSpace($commandId)) {
        return [pscustomobject]@{ valid = $false; reason = 'command_id is required (a stable id, unique within the plan)' }
    }
    $executable = [string](Get-ContinuousCoReviewContractProp -Object $Command -Name 'executable')
    if ([string]::IsNullOrWhiteSpace($executable)) {
        return [pscustomobject]@{ valid = $false; reason = 'executable is null or empty (a command MUST name a non-empty executable)' }
    }

    # ARGUMENTS: strictly a string ARRAY. A single string is the shell-string smell and is rejected.
    $argsRaw = Get-ContinuousCoReviewVerificationRawProp -Object $Command -Name 'arguments'
    if ($null -ne $argsRaw) {
        if (($argsRaw -is [string]) -or ($argsRaw -isnot [System.Collections.IEnumerable]) -or ($argsRaw -is [System.Collections.IDictionary])) {
            return [pscustomobject]@{ valid = $false; reason = 'arguments must be a string ARRAY, not a shell string (use an explicit interpreter, e.g. pwsh -File ... / bash -lc ...)' }
        }
        foreach ($a in @($argsRaw)) {
            if ($a -isnot [string]) {
                return [pscustomobject]@{ valid = $false; reason = 'every arguments entry must be a string' }
            }
        }
    }

    # PROVENANCE object.
    $prov = Get-ContinuousCoReviewContractProp -Object $Command -Name 'provenance'
    $provCheck = Test-ContinuousCoReviewVerificationProvenance -Provenance $prov
    if (-not $provCheck.valid) {
        return [pscustomobject]@{ valid = $false; reason = $provCheck.reason }
    }

    # NO SECRETS: a literal env/environment map is forbidden; only env_refs (NAMES) are allowed.
    foreach ($forbidden in @('env', 'environment')) {
        $literal = Get-ContinuousCoReviewContractProp -Object $Command -Name $forbidden
        if ($null -ne $literal) {
            return [pscustomobject]@{ valid = $false; reason = "a literal '$forbidden' map is forbidden (no secret values in a plan); declare env var NAMES via env_refs instead" }
        }
    }
    $envRefs = Get-ContinuousCoReviewVerificationRawProp -Object $Command -Name 'env_refs'
    if ($null -ne $envRefs) {
        if (($envRefs -is [string]) -or ($envRefs -isnot [System.Collections.IEnumerable]) -or ($envRefs -is [System.Collections.IDictionary])) {
            return [pscustomobject]@{ valid = $false; reason = 'env_refs must be an ARRAY of env var NAMES' }
        }
        foreach ($n in @($envRefs)) {
            if (($n -isnot [string]) -or [string]::IsNullOrWhiteSpace([string]$n)) {
                return [pscustomobject]@{ valid = $false; reason = 'each env_refs entry must be a non-empty env var NAME' }
            }
            if (([string]$n).Contains('=')) {
                return [pscustomobject]@{ valid = $false; reason = "env_refs entry '$n' looks like a literal 'NAME=value' — only NAMES are allowed (no secret values)" }
            }
        }
    }

    # PATH SAFETY for working_directory + result_path.
    $sentinelRoot = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), '__ccr_nonexistent_repo_root__') } else { $RepoRoot }
    foreach ($pathField in @('working_directory', 'result_path')) {
        $pv = [string](Get-ContinuousCoReviewContractProp -Object $Command -Name $pathField)
        if (-not [string]::IsNullOrWhiteSpace($pv)) {
            $safe = Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $sentinelRoot -Path $pv
            if (-not $safe.safe) {
                return [pscustomobject]@{ valid = $false; reason = "$pathField unsafe: $($safe.reason)" }
            }
        }
    }

    return [pscustomobject]@{ valid = $true; reason = $null }
}

# StrictMode-safe test: is the value an ordered list (not a string, not a dictionary)?
function Test-ContinuousCoReviewVerificationIsCommandList {
    param([AllowNull()]$Value)
    return ($Value -is [System.Collections.IEnumerable]) -and ($Value -isnot [string]) -and ($Value -isnot [System.Collections.IDictionary])
}

# Validate a whole VerificationPlan STRUCTURALLY. Invalid when: the plan is null; plan_id is null/empty;
# commands is not a list; ANY command is invalid; or command_ids are DUPLICATED across the plan. ORDER
# is preserved (walked as declared; the first invalid command is reported by its index) and NEVER
# sorted. Pure (path safety aside). Returns { valid; reason; command_count }.
function Test-ContinuousCoReviewVerificationPlan {
    param(
        [Parameter(Mandatory)][AllowNull()]$Plan,
        [string]$RepoRoot
    )
    if ($null -eq $Plan) {
        return [pscustomobject]@{ valid = $false; reason = 'plan is null'; command_count = 0 }
    }
    $planId = [string](Get-ContinuousCoReviewContractProp -Object $Plan -Name 'plan_id')
    if ([string]::IsNullOrWhiteSpace($planId)) {
        return [pscustomobject]@{ valid = $false; reason = 'plan_id is required (a stable plan identity)'; command_count = 0 }
    }
    $commands = Get-ContinuousCoReviewVerificationRawProp -Object $Plan -Name 'commands'
    if (-not (Test-ContinuousCoReviewVerificationIsCommandList -Value $commands)) {
        return [pscustomobject]@{ valid = $false; reason = 'plan commands is not a list (a VerificationPlan MUST carry an ordered commands array)'; command_count = 0 }
    }
    $ordered = @($commands)   # preserve DECLARED order; never sort
    $seenIds = @{}
    for ($i = 0; $i -lt $ordered.Count; $i++) {
        $check = Test-ContinuousCoReviewVerificationCommand -Command $ordered[$i] -RepoRoot $RepoRoot
        if (-not $check.valid) {
            return [pscustomobject]@{ valid = $false; reason = "command at index $i is invalid: $($check.reason)"; command_count = $ordered.Count }
        }
        $cid = [string](Get-ContinuousCoReviewContractProp -Object $ordered[$i] -Name 'command_id')
        if ($seenIds.ContainsKey($cid)) {
            return [pscustomobject]@{ valid = $false; reason = "duplicate command_id '$cid' (command_id must be unique within the plan)"; command_count = $ordered.Count }
        }
        $seenIds[$cid] = $true
    }
    return [pscustomobject]@{ valid = $true; reason = $null; command_count = $ordered.Count }
}

# Resolve the CONFIGURATION STATE of a plan: is there any runnable verification, or not? This is the
# gate the executor consults. `verification-not-configured` when the plan is null, its commands are not
# a list, the list is EMPTY, or NO command is valid — an empty plan is the EXPLICIT not-configured
# state, NEVER a silent success. `configured` when at least one command is valid. Pure (path safety
# aside). Returns { state; command_count; reason }.
function Resolve-ContinuousCoReviewVerificationPlanState {
    param(
        [Parameter(Mandatory)][AllowNull()]$Plan,
        [string]$RepoRoot
    )
    if ($null -eq $Plan) {
        return [pscustomobject]@{ state = 'verification-not-configured'; command_count = 0; reason = 'plan is null' }
    }
    $commands = Get-ContinuousCoReviewVerificationRawProp -Object $Plan -Name 'commands'
    if (-not (Test-ContinuousCoReviewVerificationIsCommandList -Value $commands)) {
        return [pscustomobject]@{ state = 'verification-not-configured'; command_count = 0; reason = 'plan declares no commands list' }
    }
    $ordered = @($commands)
    if ($ordered.Count -eq 0) {
        return [pscustomobject]@{ state = 'verification-not-configured'; command_count = 0; reason = 'plan declares zero commands (an empty plan is the explicit verification-not-configured state, never a silent success)' }
    }
    $validCount = 0
    foreach ($c in $ordered) {
        if ((Test-ContinuousCoReviewVerificationCommand -Command $c -RepoRoot $RepoRoot).valid) { $validCount++ }
    }
    if ($validCount -eq 0) {
        return [pscustomobject]@{ state = 'verification-not-configured'; command_count = $ordered.Count; reason = 'plan declares commands but none are valid' }
    }
    return [pscustomobject]@{ state = 'configured'; command_count = $ordered.Count; reason = $null }
}

# T019 EVIDENCE-JOIN validator (FR-048 amendment 10). Given the plan's per-command execution evidence,
# the plan, and the CURRENT reviewed-tree digest, decide per record whether it is injectable. REJECTS a
# record that is: DIGEST-MISMATCHED (record digest empty or != current — absolute precedence, matching
# the review-identity evidence contract); UNJOINABLE (command_id empty or not a command in the plan); or
# a DUPLICATE (its command_id appears more than once in the evidence — ambiguous, so EVERY occurrence is
# refused). Returns an ordered array of { command_id; injectable; classification }.
function Test-ContinuousCoReviewPlanEvidenceInjectable {
    param(
        [Parameter(Mandatory)][AllowNull()]$PlanEvidence,
        [Parameter(Mandatory)][AllowNull()]$Plan,
        [Parameter(Mandatory)][AllowEmptyString()][AllowNull()][string]$CurrentDigest
    )
    # The plan's declared command_id set (the only ids a record may join to).
    $planIds = @{}
    $planCommands = Get-ContinuousCoReviewVerificationRawProp -Object $Plan -Name 'commands'
    foreach ($c in @($planCommands)) {
        if ($null -eq $c) { continue }
        $cid = [string](Get-ContinuousCoReviewContractProp -Object $c -Name 'command_id')
        if (-not [string]::IsNullOrWhiteSpace($cid)) { $planIds[$cid] = $true }
    }
    # Pre-count command_ids present in the evidence so a duplicated id refuses ALL its occurrences.
    $idCounts = @{}
    foreach ($rec in @($PlanEvidence)) {
        if ($null -eq $rec) { continue }
        $cid = [string](Get-ContinuousCoReviewContractProp -Object $rec -Name 'command_id')
        if ([string]::IsNullOrWhiteSpace($cid)) { continue }
        if ($idCounts.ContainsKey($cid)) { $idCounts[$cid] = $idCounts[$cid] + 1 } else { $idCounts[$cid] = 1 }
    }

    $results = @()
    foreach ($rec in @($PlanEvidence)) {
        $cid = [string](Get-ContinuousCoReviewContractProp -Object $rec -Name 'command_id')
        $recDigest = [string](Get-ContinuousCoReviewContractProp -Object $rec -Name 'reviewed_digest_tree_id')
        $injectable = $false
        if ([string]::IsNullOrWhiteSpace($CurrentDigest) -or [string]::IsNullOrWhiteSpace($recDigest) -or ($recDigest -cne $CurrentDigest)) {
            $classification = 'digest-mismatch-not-injected'
        }
        elseif ([string]::IsNullOrWhiteSpace($cid) -or (-not $planIds.ContainsKey($cid))) {
            $classification = 'unjoinable-no-matching-command'
        }
        elseif ($idCounts.ContainsKey($cid) -and ($idCounts[$cid] -gt 1)) {
            $classification = 'duplicate-command-id-surfaced'
        }
        else {
            $injectable = $true
            $classification = 'exact-digest-command-joined'
        }
        $results += [pscustomobject]@{ command_id = $cid; injectable = $injectable; classification = $classification }
    }
    # Emit the per-record results ENUMERATED so a caller's @(...) collects them FLAT (a `, @(...)` wrap
    # would surface as a single nested array object and collapse the count for multi-record inputs).
    return @($results)
}
