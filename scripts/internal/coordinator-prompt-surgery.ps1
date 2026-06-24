# Coordinator-prompt surgery — registry-driven rules engine (Phase C.3 refactor)
#
# Originally a 123-line file with hardcoded per-host switches (FR-011 header,
# FR-012 strip non-Copilot, FR-014 Codex pwsh-form). Now a thin rules engine
# that loads hosts/<kind>/coordinator-rules.psd1 and applies declared Rules in order.
#
# The universal header rewrite (FR-011) stays here as a built-in baseline because
# the literal IS the same across all hosts (it's the spec invariant). Per-host
# rule files declare ADDITIONAL surgery on top.
#
# To change a per-host rule: edit hosts/<kind>/coordinator-rules.psd1.
# To add a new host: create hosts/<kind>/coordinator-rules.psd1 — no edits to this engine.

Set-StrictMode -Version Latest

$script:RegistryPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'hosts\_registry.ps1'
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    # Module-mode lookup
    $script:RegistryPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'hosts\_registry.ps1'
}
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    throw "Host registry not found. Searched: $script:RegistryPath"
}
. $script:RegistryPath

$script:CoordinatorRulesCache = @{}

function Get-SpecrewUniversalCoordinatorHeader {
    # FR-011 invariant: same literal for every host.
    return 'You are the Crew team coordinator running inside a Specrew-bootstrapped repository.'
}

function Get-SpecrewOriginalCoordinatorHeaderPattern {
    # Matches the original Squad header that gets replaced uniformly.
    return '(?m)^You are Squad running inside a Specrew-bootstrapped repository\.'
}

function Get-SpecrewHostOrientationMarker {
    return '<<SPECREW_HOST_ORIENTATION_BLOCK>>'
}

function Get-SpecrewHostInteractionGuidanceMarker {
    return '<<SPECREW_HOST_INTERACTION_GUIDANCE_BLOCK>>'
}

function Get-SpecrewRuntimeClass {
    param([AllowNull()][string]$CrewRuntimeStatus)

    if ([string]$CrewRuntimeStatus -eq 'squad-runtime') {
        return 'Squad'
    }

    return 'non-Squad'
}

function Get-SpecrewHostOrientationBlock {
    <#
    .SYNOPSIS
    Renders the visible first-output orientation block for the selected launch host.

    .DESCRIPTION
    The shared start prompt owns lifecycle requirements only. Host-facing identity
    text is rendered here from the selected host manifest plus the runtime status
    recorded into start-context.json, so the visible orientation cannot drift into
    a stale hard-coded host/runtime claim.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-SpecrewRegisteredHostKind -Kind $_ })]
        [string]$HostKind,

        [string]$CrewRuntimeStatus = 'bootstrap_only',

        [AllowNull()][string]$SpecrewVersion,

        [AllowNull()][string]$LifecycleMode,

        [AllowNull()][string]$FeatureRef,

        [AllowNull()][string]$BoundaryType,

        # FR-025 transparency half: a pre-rendered one-line expertise summary ("I'll treat you as
        # expert on X, mid-level on Y - correct me if that's off"). The integration layer renders it
        # from the current Crew Interaction Profile and passes it in, so this stays a pure renderer.
        [AllowNull()][string]$ExpertiseLine
    )

    $manifest = Get-HostManifest -Kind $HostKind
    $displayName = if ($manifest.ContainsKey('DisplayName') -and -not [string]::IsNullOrWhiteSpace([string]$manifest.DisplayName)) {
        [string]$manifest.DisplayName
    }
    else {
        $HostKind
    }

    $hasSquadRuntime = ([string]$CrewRuntimeStatus -eq 'squad-runtime')
    $runtimeClass = Get-SpecrewRuntimeClass -CrewRuntimeStatus $CrewRuntimeStatus
    $runtimeName = if ($manifest.ContainsKey('CrewRuntimeDisplayName') -and -not [string]::IsNullOrWhiteSpace([string]$manifest.CrewRuntimeDisplayName)) {
        [string]$manifest.CrewRuntimeDisplayName
    }
    else {
        'Crew role runtime'
    }

    $versionLine = if ([string]::IsNullOrWhiteSpace($SpecrewVersion)) {
        'Specrew: unknown'
    }
    else {
        "Specrew: $SpecrewVersion"
    }
    $hostLine = "Host: $($HostKind.ToLowerInvariant()) ($displayName); runtime: $runtimeClass"
    $isResume = ($LifecycleMode -eq 'resume-feature' -or -not [string]::IsNullOrWhiteSpace($FeatureRef))
    $featurePart = if ([string]::IsNullOrWhiteSpace($FeatureRef)) { 'current feature' } else { "feature $FeatureRef" }
    $boundaryPart = if ([string]::IsNullOrWhiteSpace($BoundaryType)) { 'intake' } else { $BoundaryType }
    $openingLine = if ($isResume) {
        "Welcome back - resuming $featurePart at $boundaryPart."
    }
    else {
        "Welcome - I'm your Specrew Crew coordinator."
    }
    $lifecycleLine = if ($isResume) {
        "Lifecycle: $featurePart at $boundaryPart."
    }
    else {
        'Lifecycle: new feature intake.'
    }

    $howThisWorks = if ($hasSquadRuntime) {
        "How this works: Specrew governs the spec -> plan -> implement -> review -> retro`nlifecycle. The $runtimeName runtime coordinates the Spec Steward, Planner,`nImplementer, Reviewer, and Retro Facilitator roles for this session."
    }
    else {
        "How this works: Specrew governs the spec -> plan -> implement -> review -> retro`nlifecycle. This session follows the saved lifecycle prompt and structured start`ncontext directly; a separate role runtime is not active for this launch."
    }

    # FR-011: when no feature exists yet (greenfield/intake) do NOT emit a file:/// browse URL with a
    # <feature> segment — the coordinator substitutes <feature> per Rule 48, and with no feature that
    # collapses to `specs//`. Emit explicit-placeholder guidance instead; surface the concrete file:///
    # browse paths only on a resolved-feature resume (where the substituted feature segment is non-empty).
    $browseLine = if ([string]::IsNullOrWhiteSpace($FeatureRef)) {
        'What you can browse: no feature exists yet — once you create one, its artifacts land under `specs/<feature-id>/` (spec.md, plan.md, tasks.md) with per-iteration files under `specs/<feature-id>/iterations/<NNN>/`. Open another terminal and run `code .` to browse the workspace; I will share the exact file:/// paths once the feature is scaffolded.'
    }
    else {
        'What you can browse: artifacts land under file:///<project-root-url>/specs/<feature>/ — spec file file:///<project-root-url>/specs/<feature>/spec.md, plan file file:///<project-root-url>/specs/<feature>/plan.md, tasks file file:///<project-root-url>/specs/<feature>/tasks.md, plus the iteration artifacts under file:///<project-root-url>/specs/<feature>/iterations/001/. Open another terminal and run `code .` to browse them while I work. After each iteration close, your dashboard lives at file:///<project-root-url>/specs/<feature>/iterations/<NNN>/dashboard.md.'
    }

    # FR-025 transparency half: surface the assumed expertise (and invite correction) right after the
    # "how this works" framing, so the human sees the level Specrew adapts to before any questions. Omit
    # the whole line gracefully when no profile was passed (back-compat: block is otherwise unchanged).
    $expertiseBlock = if ([string]::IsNullOrWhiteSpace($ExpertiseLine)) {
        ''
    }
    else {
        "$ExpertiseLine`n`n"
    }

    return @"
``````markdown
$openingLine
$versionLine
$hostLine
$lifecycleLine

$howThisWorks

${expertiseBlock}What I'll ask from you: clarify questions when something is genuinely ambiguous
(2-3 max per phase), and an approve/redirect verdict at each boundary stop. I'll
emit a clear human re-entry packet every time I need you.

$browseLine

Starting now: <one specific action — e.g. "creating feature 001-tip-calculator
and drafting the spec">.
``````
"@
}

function Get-SpecrewHostInteractionGuidanceBlock {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-SpecrewRegisteredHostKind -Kind $_ })]
        [string]$HostKind
    )

    $manifest = Get-HostManifest -Kind $HostKind
    $displayName = if ($manifest.ContainsKey('DisplayName') -and -not [string]::IsNullOrWhiteSpace([string]$manifest.DisplayName)) {
        [string]$manifest.DisplayName
    }
    else {
        $HostKind
    }

    # Feature 165: on the Claude host the AskUserQuestion picker COLLAPSES the Rule 46 six-section
    # packet into its short header/option fields, so the human is asked to approve what they cannot
    # read. This is not a conduct gap that another instruction can close -- six conduct amendments
    # and even a runtime PreToolUse hook-deny were gamed (the model reworded the menu to claim
    # content was "shown above" that it never rendered). The deterministic fix is to remove the
    # picker at the stop: boundary VERDICT stops route through the specrew-gate-stop skill, whose
    # frontmatter `disallowed-tools: AskUserQuestion` deletes the tool for the stop, so there is
    # nothing to collapse into and the packet MUST render as Markdown. The design workshop and
    # clarify questions are UNAFFECTED -- they keep the AskUserQuestion picker because their skills
    # do not disable it; only boundary verdict stops route through specrew-gate-stop.
    if ($HostKind -eq 'claude') {
        return @"
Host-rendered interaction guidance for ${displayName}:
At every human-verdict boundary stop, invoke the specrew-gate-stop skill to PERFORM the stop. That skill's frontmatter disallows the AskUserQuestion tool, so for the stop you have no picker to collapse into: render the FULL Rule 46 six-section re-entry packet -- What I Just Did / Why I Stopped / What Needs Your Review / What Happens Next / Discussion Prompts / What I Need From You, with every artifact reference a visible bare file:/// URL -- followed by the four verdict options as a numbered Markdown list, then stop for the human's typed choice. Do NOT call AskUserQuestion directly for a boundary verdict on this host: it collapses the packet into the picker's short fields, so the human is asked to approve content they cannot read -- that is a Rule 46 violation, not a valid stop. The design workshop and clarify questions are UNAFFECTED -- they keep the AskUserQuestion picker (their skills do not disable it); ONLY boundary verdict stops route through specrew-gate-stop. Render the four choices from the response contract exactly: approve as-is, approve with instructions, send back, and discuss prompt #N. Initial feature intake may remain free-form.
"@
    }

    $primitive = if ($manifest.ContainsKey('StructuredQuestionPrimitive')) { [string]$manifest.StructuredQuestionPrimitive } else { '' }
    $guidance = if ($manifest.ContainsKey('StructuredQuestionGuidance')) { [string]$manifest.StructuredQuestionGuidance } else { '' }

    if (-not [string]::IsNullOrWhiteSpace($primitive)) {
        if ([string]::IsNullOrWhiteSpace($guidance)) {
            $guidance = "Use the $displayName structured user-input/menu primitive for human approval gates when it is available in the current session."
        }

        return @"
Host-rendered interaction guidance for ${displayName}:
$guidance
Structured primitive: $primitive.
Render the Rule 46 six-section re-entry packet as PROSE in your message FIRST, then call the structured primitive only for the verdict selection. The primitive's fields are short labels by design (a ~12-character header, 1-to-5-word option labels) and CANNOT carry the packet -- the What I Just Did / Why I Stopped / What Needs Your Review / What Happens Next / Discussion Prompts content, with its file:/// links, lives in your prose ABOVE the call. A verdict menu raised without the full packet rendered above it (a bare "What's your verdict?" that skipped the packet) is a Rule 46 violation, not a valid stop -- the menu is only the short picker that follows the rendered packet. Render the four choices from the response contract exactly: approve as-is, approve with instructions, send back, and discuss prompt #N. If the structured primitive is unavailable in the running host session, emit the textual "What's your verdict?" options exactly as shown above. Initial feature intake may remain free-form. Clarify questions should use structured choices when the expected answer set is known; otherwise ask a concise free-form question.
"@
    }

    return @"
Host-rendered interaction guidance for ${displayName}:
No structured question/menu primitive is declared for this host package. Emit the textual "What's your verdict?" options exactly as shown above at every approval boundary. Initial feature intake may remain free-form. Clarify questions should use structured choices when the expected answer set is known and a structured primitive is available; otherwise ask a concise free-form question.
"@
}

function Get-SpecrewHostCoordinatorRules {
    <#
    .SYNOPSIS
    Loads the declarative coordinator-prompt surgery rules for a given host.
    .OUTPUTS
    array of hashtables, each with @{ Kind = 'Strip'|'Replace'; Pattern; Replacement?; Description }
    Returns empty array if the host has no per-host rules (e.g., Copilot).
    #>
    param([Parameter(Mandatory = $true)][string]$HostKind)

    $kindLower = $HostKind.ToLowerInvariant()
    if ($script:CoordinatorRulesCache.ContainsKey($kindLower)) {
        return $script:CoordinatorRulesCache[$kindLower]
    }

    $manifest = Get-HostManifest -Kind $kindLower
    $rulesFile = if ($manifest.ContainsKey('CoordinatorRulesFile') -and -not [string]::IsNullOrWhiteSpace([string]$manifest.CoordinatorRulesFile)) { $manifest.CoordinatorRulesFile } else { 'coordinator-rules.psd1' }
    $hostsRoot = Get-SpecrewHostsRoot
    $rulesPath = Join-Path (Join-Path $hostsRoot $kindLower) $rulesFile

    if (-not (Test-Path -LiteralPath $rulesPath -PathType Leaf)) {
        # Hosts may legitimately have no per-host rules (e.g., Copilot only needs the engine's universal header)
        $script:CoordinatorRulesCache[$kindLower] = @()
        return @()
    }

    try {
        $rulesData = Import-PowerShellDataFile -LiteralPath $rulesPath
    }
    catch {
        throw "Failed to load coordinator rules for host '$HostKind' at '$rulesPath': $($_.Exception.Message)"
    }

    if (-not $rulesData.ContainsKey('Rules')) {
        $script:CoordinatorRulesCache[$kindLower] = @()
        return @()
    }

    $rules = @($rulesData.Rules)
    $script:CoordinatorRulesCache[$kindLower] = $rules
    return $rules
}

function Invoke-SpecrewCoordinatorPromptSurgery {
    <#
    .SYNOPSIS
    Applies multi-host coordinator-prompt surgery — registry-driven rules engine.

    .DESCRIPTION
    Two surgeries applied in order:
      1. Universal header rewrite (FR-011 invariant; built-in baseline applied to ALL hosts).
      2. Per-host declarative rules from hosts/<kind>/coordinator-rules.psd1 applied in declared order.

    Per-host rules are hashtables with:
      - Kind = 'Strip' | 'Replace'
      - Pattern = regex string
      - Replacement = string (required only for Replace; supports regex backreferences like `$1`)
      - Description = human-readable label (for diagnostics)

    Returns the rewritten prompt body.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-SpecrewRegisteredHostKind -Kind $_ })]
        [string]$HostKind,

        [string]$CrewRuntimeStatus = 'bootstrap_only',

        [AllowNull()][string]$SpecrewVersion,

        [AllowNull()][string]$LifecycleMode,

        [AllowNull()][string]$FeatureRef,

        [AllowNull()][string]$BoundaryType,

        # FR-025 transparency half: pre-rendered expertise summary, threaded straight to the
        # orientation renderer (the start script renders it from the current profile).
        [AllowNull()][string]$ExpertiseLine
    )

    if ([string]::IsNullOrEmpty($Prompt)) {
        return $Prompt
    }

    $result = $Prompt

    # Surgery 1: universal header rewrite (FR-011) — applies to ALL hosts as a built-in baseline.
    $result = [regex]::Replace($result, (Get-SpecrewOriginalCoordinatorHeaderPattern), (Get-SpecrewUniversalCoordinatorHeader))

    # Surgery 1b: host-facing orientation block rendered from the selected host package.
    $orientationMarker = [regex]::Escape((Get-SpecrewHostOrientationMarker))
    $orientationBlock = Get-SpecrewHostOrientationBlock -HostKind $HostKind -CrewRuntimeStatus $CrewRuntimeStatus -SpecrewVersion $SpecrewVersion -LifecycleMode $LifecycleMode -FeatureRef $FeatureRef -BoundaryType $BoundaryType -ExpertiseLine $ExpertiseLine
    $result = [regex]::Replace($result, $orientationMarker, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $orientationBlock })

    # Surgery 1c: host-facing interaction guidance rendered from the selected host package.
    $interactionMarker = [regex]::Escape((Get-SpecrewHostInteractionGuidanceMarker))
    $interactionBlock = Get-SpecrewHostInteractionGuidanceBlock -HostKind $HostKind
    $result = [regex]::Replace($result, $interactionMarker, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $interactionBlock })

    # Surgery 2: per-host declarative rules
    $rules = Get-SpecrewHostCoordinatorRules -HostKind $HostKind
    $appliedStrip = $false
    foreach ($rule in $rules) {
        if (-not $rule.ContainsKey('Kind') -or -not $rule.ContainsKey('Pattern')) {
            Write-Warning ("Skipping malformed coordinator rule for host '{0}': missing Kind or Pattern" -f $HostKind)
            continue
        }
        switch ($rule.Kind) {
            'Strip' {
                $result = [regex]::Replace($result, $rule.Pattern, '')
                $appliedStrip = $true
            }
            'Replace' {
                if (-not $rule.ContainsKey('Replacement')) {
                    Write-Warning ("Skipping malformed Replace rule for host '{0}': missing Replacement" -f $HostKind)
                    continue
                }
                $result = [regex]::Replace($result, $rule.Pattern, [string]$rule.Replacement)
            }
            default {
                Write-Warning ("Unknown rule Kind '{0}' for host '{1}'; skipping" -f $rule.Kind, $HostKind)
            }
        }
    }

    # If any Strip rules fired, tidy up blank-line clusters that get left behind.
    if ($appliedStrip) {
        $result = [regex]::Replace($result, '(?m)(^\s*$\r?\n){3,}', "`r`n`r`n")
    }

    return $result
}

# Phase D cleanup 2026-05-24: removed back-compat helpers Get-SpecrewSquadRuntimePathDirectivePatterns
# and Get-SpecrewSlashCommandToPwshFormMap — both had zero callers across scripts/, hosts/, extensions/,
# Specrew.psm1, and tests (verified via deep-review agent). Introspection of per-host rules now goes
# directly through Get-SpecrewHostCoordinatorRules -HostKind <kind>.
