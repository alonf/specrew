$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T091/FR-037 + T100/FR-039: ONE process manager for the reviewer spawn - the same OS-native containment
# primitives the isolated-task supervisor uses (process-tree.ps1: Job Object / setsid+PGID / snapshot-walk
# fallback). Loaded here; REQUIRED at spawn time (Invoke-ContinuousCoReviewAgentInWorktree refuses to spawn
# an uncontainable reviewer - the divergent $proc.Kill fallback is deleted per design N1).
$specrewProcessTreeHelper = Join-Path (Split-Path -Parent $PSScriptRoot) 'agent-tasks/process-tree.ps1'
if (Test-Path -LiteralPath $specrewProcessTreeHelper -PathType Leaf) { . $specrewProcessTreeHelper }

# iter-008 — the worktree-based, agentic, see-all/run-all reviewer (NEW, built alongside the old curated-diff
# path; the old path keeps working until this is proven + cut over). The reviewer runs in an ephemeral,
# read-only-source git-tree worktree of the project with the methodology machinery stripped, reads
# .review/changes.diff as its entry point, browses + runs to verify, and emits a FindingsResult. It CANNOT fix
# the source (the worktree is discarded). See specs/197-continuous-co-review/iterations/008/design-analysis.md.

function Test-ContinuousCoReviewSpecrewSourceRepo {
    param([AllowNull()][string]$RepoRoot)

    if ([string]::IsNullOrWhiteSpace($RepoRoot)) { return $false }
    try {
        $resolved = (Resolve-Path -LiteralPath $RepoRoot -ErrorAction Stop).Path
    }
    catch {
        return $false
    }

    return (
        (Test-Path -LiteralPath (Join-Path $resolved 'Specrew.psd1') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $resolved 'scripts/internal/continuous-co-review/_load.ps1') -PathType Leaf)
    )
}

function Get-ContinuousCoReviewMachineryPaths {
    # SINGLE SOURCE of "the methodology's deployed machinery" (the de-fragilization point — one function,
    # consumed by BOTH the worktree-strip AND the diff-exclude). Two parts, both authoritative-by-construction,
    # NOT a hand-maintained host-mirror array:
    #   (a) the core methodology dirs + host-instruction files Specrew/Spec-Kit/Squad own unambiguously, and
    #   (b) SELF-DESCRIBING detection: every dir Specrew DEPLOYS into a host carries a `.specrew-managed` marker
    #       (written by Set-ManagedFile at deploy), so its parent dir is machinery. This catches the host-mirror
    #       skill/rule/agent dirs (.github/skills/specrew-*, .claude/skills/specrew-*, .cursor/rules/specrew-*, ...)
    #       across every host WITHOUT enumerating them, and keeps user config (.github/workflows,
    #       .claude/settings — no marker). Returns project-relative paths. -RepoRoot enables (b); omit for the
    #       core-only list.
    param([string]$RepoRoot)
    $core = @(
        '.specrew', '.specify', '.squad', '.agents', '.git',
        'CLAUDE.md', 'AGENTS.md', 'GEMINI.md'
    )
    if (-not (Test-ContinuousCoReviewSpecrewSourceRepo -RepoRoot $RepoRoot)) {
        # In a DEPLOYED project these are inert deployed machinery to strip. In the Specrew SOURCE repo they ARE
        # the feature under review: continuous-co-review/** AND the iter-009 tree-kill/supervisor that live under
        # agent-tasks/** + atomic-write.ps1. Stripping them unconditionally made every self-review BLIND to T091's
        # central (security-critical) implementation - the gate could PASS a run that never saw the tree-kill.
        # Same hole class as the navigator-dark deploy-drift (D-197-I009-001) + the T084 continuous-co-review fix.
        $core += 'scripts/internal/continuous-co-review'
        $core += 'scripts/internal/agent-tasks'
        $core += 'scripts/internal/atomic-write.ps1'
    }
    if ([string]::IsNullOrWhiteSpace($RepoRoot)) { return $core }
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    $marked = @(Get-ChildItem -LiteralPath $resolved -Recurse -Force -File -Filter '.specrew-managed' -ErrorAction SilentlyContinue |
        ForEach-Object { [System.IO.Path]::GetRelativePath($resolved, (Split-Path -Parent $_.FullName)).Replace('\', '/') })
    # (c) Agent-framework MIRROR subdirs under the AI-host dirs. Specrew/Spec-Kit/host frameworks deploy
    # agent/skill/command/chatmode/prompt/rule mirrors here, and they are marked INCONSISTENTLY (skills/rules
    # carry .specrew-managed; agents/prompts do not; some are symlinks, some plain files) - so (b) alone misses
    # them. These subdir NAMES are a stable agent-tooling vocabulary, NOT a per-project path guess; user config
    # in these host dirs (workflows, settings, ISSUE_TEMPLATE) is NEVER one of them and is kept. (The durable
    # single-source is the deploy marking ALL deployed content; this vocabulary bridges already-deployed projects.)
    $hostDirs = @('.github', '.claude', '.cursor', '.copilot', '.gemini', '.antigravity')
    $frameworkSubdirs = @('agents', 'skills', 'commands', 'chatmodes', 'prompts', 'rules', 'instructions')
    $mirrors = foreach ($h in $hostDirs) {
        foreach ($s in $frameworkSubdirs) {
            $rel = "$h/$s"
            if (Test-Path -LiteralPath (Join-Path $resolved $rel) -PathType Container) { $rel }
        }
    }
    return @($core + $marked + $mirrors | Where-Object { $_ -and $_ -ne '.' } | Sort-Object -Unique)
}

function Write-ContinuousCoReviewProcessContext {
    # Curated PROCESS / PROGRESS context for the reviewer (under .review/process/) so it can review progress
    # conformance - right task? on-plan? drift recorded? progress honest? - WITHOUT the raw, noisy .specrew
    # tree (which is stripped). Distilled from the REAL project (read from $RepoRoot before the worktree strip):
    # the active feature + iteration + phase, plus snapshots of the progress artifacts (tasks-progress / drift /
    # state) and the plan/tasks. Fail-soft: a missing piece is just omitted.
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$ReviewDir)
    $procDir = Join-Path $ReviewDir 'process'
    New-Item -ItemType Directory -Path $procDir -Force | Out-Null

    $featureDir = $null; $phase = $null
    $fj = Join-Path $RepoRoot '.specify/feature.json'
    if (Test-Path -LiteralPath $fj -PathType Leaf) {
        try { $featureDir = ([string]((Get-Content $fj -Raw -Encoding UTF8 | ConvertFrom-Json).feature_directory)).Replace('\', '/').TrimEnd('/') } catch { $null = $_ }
    }
    $sc = Join-Path $RepoRoot '.specrew/start-context.json'
    if (Test-Path -LiteralPath $sc -PathType Leaf) {
        try {
            $scj = Get-Content $sc -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($scj.PSObject.Properties['boundary_enforcement']) { $phase = [string]$scj.boundary_enforcement.last_authorized_boundary }
        }
        catch { $null = $_ }
    }

    $copied = New-Object System.Collections.Generic.List[string]
    $iterPhase = $null
    if (-not [string]::IsNullOrWhiteSpace($featureDir)) {
        $featureFull = Join-Path $RepoRoot $featureDir
        $latestIter = $null
        $iterRoot = Join-Path $featureFull 'iterations'
        if (Test-Path -LiteralPath $iterRoot -PathType Container) {
            $latestIter = @(Get-ChildItem -LiteralPath $iterRoot -Directory -EA SilentlyContinue | Where-Object { $_.Name -match '^\d+$' } | Sort-Object { [int]$_.Name } -Descending | Select-Object -First 1)
        }
        $progressFiles = @((Join-Path $featureFull 'tasks.md'), (Join-Path $featureFull 'plan.md'))
        if ($latestIter) {
            foreach ($n in @('tasks-progress.yml', 'drift-log.md', 'state.md')) { $progressFiles += (Join-Path $latestIter[0].FullName $n) }
            $iterPlanPath = Join-Path $latestIter[0].FullName 'plan.md'
            if (Test-Path -LiteralPath $iterPlanPath -PathType Leaf) {
                foreach ($ln in (Get-Content -LiteralPath $iterPlanPath -Encoding UTF8)) {
                    if ($ln -match '^\s*\*\*Status\*\*\s*:\s*(?<s>[A-Za-z-]+)') { $iterPhase = $Matches['s']; break }
                }
            }
        }
        foreach ($pf in $progressFiles) {
            if (Test-Path -LiteralPath $pf -PathType Leaf) { Copy-Item -LiteralPath $pf -Destination $procDir -Force; [void]$copied.Add((Split-Path $pf -Leaf)) }
        }
    }

    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('# Process / progress context (curated)')
    [void]$lines.Add('')
    [void]$lines.Add("Active feature: $featureDir")
    [void]$lines.Add("Last human-authorized boundary: $phase")
    if (-not [string]::IsNullOrWhiteSpace($iterPhase)) { [void]$lines.Add("Current iteration phase (from iteration plan.md Status): $iterPhase") }
    [void]$lines.Add('')
    [void]$lines.Add('Lifecycle note: the human-authorized boundary gates the START of the next work, not its end. The')
    [void]$lines.Add('implementation AND its review artifacts are produced AFTER the before-implement gate and BEFORE the')
    [void]$lines.Add('review-signoff gate, so an increment that implements the feature and updates review/iteration state')
    [void]$lines.Add('while the last authorized boundary is before-implement is EXPECTED and in-scope -- not a phase')
    [void]$lines.Add('violation. Flag only genuine scope creep beyond plan.md, or dishonest status (work marked done/tested')
    [void]$lines.Add('that is not actually done/tested).')
    [void]$lines.Add('')
    [void]$lines.Add('Snapshots of the real project process state (read these for progress review):')
    foreach ($c in $copied) { [void]$lines.Add("- .review/process/$c") }
    [void]$lines.Add('')
    [void]$lines.Add('The full plan / tasks / spec also live under specs/ in your worktree.')
    [void]$lines.Add('')
    [void]$lines.Add('Review the increment for PROCESS/PROGRESS conformance (in addition to design conformance):')
    [void]$lines.Add('- Does the change implement the task(s) it claims (trace to tasks.md)?')
    [void]$lines.Add('- Is it consistent with plan.md (no unplanned scope, no deferred work absorbed)?')
    [void]$lines.Add('- Is drift recorded in drift-log.md where the implementation diverged from spec/plan?')
    [void]$lines.Add('- Is tasks-progress / state HONEST (nothing marked done that is not actually done/tested)?')
    [void]$lines.Add('- Does the work stay within planned scope for this lifecycle position (see the lifecycle note)?')
    [System.IO.File]::WriteAllText((Join-Path $procDir 'process-context.md'), ($lines -join "`n"))
}

function New-ContinuousCoReviewStrippedWorktree {
    # Materialize an EPHEMERAL git-tree worktree of the project's reviewed subtree, machinery stripped, with the
    # review context written under .review/. Returns @{ worktree_path; tree_id; changed_count }.
    # Nested-project aware (governance root may be a subdir of the git repo). git archive of the TRACKED tree
    # already excludes .git + gitignored content (node_modules/dist/build), so only the committed machinery dirs
    # need stripping. Read-only SOURCE: the reviewer may write build/test output into its disposable copy but the
    # real repo is never touched.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$BaselineRef,
        [string[]]$DesignContextFiles = @(),
        [string]$EphemeralRoot
    )
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    $gitRoot = (& git -C $resolved rev-parse --show-toplevel 2>$null).Trim()
    $prefix = (& git -C $resolved rev-parse --show-prefix 2>$null).Trim().TrimEnd('/')   # '' when project == git root
    # Resolve the reviewed subtree's TREE id (HEAD:path is already a tree; HEAD needs ^{tree} to peel the commit).
    $treeId = if ([string]::IsNullOrWhiteSpace($prefix)) {
        (& git -C $gitRoot rev-parse 'HEAD^{tree}' 2>$null).Trim()
    }
    else {
        (& git -C $gitRoot rev-parse "HEAD:$prefix" 2>$null).Trim()
    }

    if ([string]::IsNullOrWhiteSpace($EphemeralRoot)) { $EphemeralRoot = [System.IO.Path]::GetTempPath() }
    $worktree = Join-Path $EphemeralRoot ('ccr-worktree-' + [guid]::NewGuid().ToString('N'))
    $tarPath = "$worktree.tar"
    New-Item -ItemType Directory -Path $worktree -Force | Out-Null

    # Archive the subtree tree to a FILE then extract (no native->native pipe; byte-exact, cross-platform).
    & git -C $gitRoot archive --format=tar --output $tarPath $treeId 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Remove-Item -LiteralPath $worktree -Recurse -Force -EA SilentlyContinue; throw "git archive failed for tree $treeId" }
    $tarExe = if ($IsWindows) { $s = Join-Path $env:SystemRoot 'System32\tar.exe'; if (Test-Path $s) { $s } else { 'tar' } } else { 'tar' }
    $tarOut = (& $tarExe -xf $tarPath -C $worktree 2>&1)
    $tarExit = $LASTEXITCODE
    Remove-Item -LiteralPath $tarPath -Force -EA SilentlyContinue
    # The extract MUST be exit-checked + the worktree non-empty: a failed/partial extract (e.g. the iter-007 MSYS-tar
    # class) would otherwise leave a HOLLOW worktree the agentic reviewer 'browses', and the run would report
    # done/no_findings INDISTINGUISHABLE from a real clean pass. Fail loudly instead of green-lighting un-reviewed code.
    if ($tarExit -ne 0) {
        Remove-Item -LiteralPath $worktree -Recurse -Force -EA SilentlyContinue
        throw "tar extract failed (exit $tarExit) materializing tree ${treeId}: $($tarOut -join ' ')"
    }
    if (-not (@(Get-ChildItem -LiteralPath $worktree -Force -ErrorAction SilentlyContinue)).Count) {
        Remove-Item -LiteralPath $worktree -Recurse -Force -EA SilentlyContinue
        throw "materialized worktree is empty after extracting tree ${treeId} (refusing to review a hollow worktree)"
    }

    # Strip the methodology machinery (the single-source set, computed ONCE from the real project: core dirs +
    # marker-detected host-mirror dirs). Reused below for the diff-exclude.
    $machinery = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $resolved)
    foreach ($m in $machinery) {
        $p = Join-Path $worktree $m
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force -EA SilentlyContinue }
    }

    # Write the review context under .review/ (the entry point + the design).
    $reviewDir = Join-Path $worktree '.review'
    New-Item -ItemType Directory -Path (Join-Path $reviewDir 'design') -Force | Out-Null
    # Change-set diff = the subtree, MINUS the machinery churn (the SAME single-source set as the worktree
    # strip — a known list, NOT a heuristic). So the reviewer's entry point is the user's changes, consistent
    # with the stripped worktree. Paths made subtree-relative so they match the worktree root.
    $scope = if ([string]::IsNullOrWhiteSpace($prefix)) { @() } else { @("$prefix/") }
    $machineryExcludes = foreach ($m in $machinery) {
        if ($m -eq '.git') { continue }
        $mp = if ([string]::IsNullOrWhiteSpace($prefix)) { $m } else { "$prefix/$m" }
        ":(exclude)$mp"
    }
    $diffPathspec = @($scope) + @($machineryExcludes)
    $diff = (& git -C $gitRoot diff --no-ext-diff --src-prefix=a/ --dst-prefix=b/ $BaselineRef HEAD -- @diffPathspec 2>$null) -join "`n"
    if (-not [string]::IsNullOrWhiteSpace($prefix)) { $diff = $diff -replace ([regex]::Escape("$prefix/")), '' }
    [System.IO.File]::WriteAllText((Join-Path $reviewDir 'changes.diff'), $diff)
    $changed = @((& git -C $gitRoot diff --name-only $BaselineRef HEAD -- @diffPathspec 2>$null) | Where-Object { $_ })
    foreach ($d in @($DesignContextFiles)) {
        $full = if ([System.IO.Path]::IsPathRooted($d)) { $d } else { Join-Path $resolved $d }
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
        # Formal contracts go under design/contracts/ (grouped + obviously the AUTHORITY); prose goes flat in design/.
        $destDir = if ($d -match '(^|/)contracts/') { Join-Path $reviewDir 'design/contracts' } else { Join-Path $reviewDir 'design' }
        if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item -LiteralPath $full -Destination $destDir -Force
    }

    # Curated process/progress context (distilled from the real project; the raw .specrew is stripped).
    Write-ContinuousCoReviewProcessContext -RepoRoot $resolved -ReviewDir $reviewDir

    return [pscustomobject]@{ worktree_path = $worktree; tree_id = $treeId; changed_count = $changed.Count; changed_paths = @($changed); diff_bytes = [int]$diff.Length }
}

function Test-ContinuousCoReviewExplicitTimeoutConfigured {
    # T092/R2 (FR-034): was co_review_timeout_seconds EXPLICITLY set in .specrew/config.yml? An explicit budget is
    # human intent and MUST NOT be silently overridden by the generous-budget heuristic (FR-034: not a silent
    # auto-extend). Mirrors the navigator's config read.
    param([string]$RepoRoot)
    if ([string]::IsNullOrWhiteSpace($RepoRoot)) { return $false }
    $cfg = Join-Path $RepoRoot '.specrew/config.yml'
    if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) { return $false }
    try {
        foreach ($line in (Get-Content -LiteralPath $cfg -Encoding UTF8 -ErrorAction SilentlyContinue)) {
            if ($line -match '^\s*co_review_timeout_seconds:\s*[''"]?[^''"#\s]') { return $true }
        }
    }
    catch { $null = $_ }
    return $false
}

function Get-ContinuousCoReviewGenerousBudget {
    # T092/R2 (FR-034): a threshold-based GENEROUS budget for a large change-set, so a big diff (the EnglishIntake
    # 72-min case) is less likely to be killed mid-read. Scales the DEFAULT up in tiers to a hard cap. A small or
    # medium change-set keeps the default unchanged. Pure (diff size -> budget) so it is unit-testable.
    param([int]$DiffBytes, [int]$ChangedCount, [Parameter(Mandatory)][int]$DefaultSeconds, [int]$CapSeconds = 1800)
    $factor = 1.0
    if ($DiffBytes -ge 200000 -or $ChangedCount -ge 40) { $factor = 1.5 }
    if ($DiffBytes -ge 500000 -or $ChangedCount -ge 100) { $factor = 2.0 }
    if ($DiffBytes -ge 1000000 -or $ChangedCount -ge 200) { $factor = 3.0 }
    return [math]::Min([int]($DefaultSeconds * $factor), $CapSeconds)
}

function Get-ContinuousCoReviewSlimPrompt {
    # The SLIM prompt (a few KB) — the reviewer reads the diff + design + browses/runs the project itself.
    # Round-aware: round 1 reviews; later rounds verify the prior findings are resolved; at the FINAL round the
    # reviewer escalates (the counter is a safety ceiling, the reviewer's judgement is the brains).
    param([Parameter(Mandatory)][string]$RunId, [int]$RoundNumber = 1, [int]$MaxRounds = 2, [string]$PriorFindings, [string]$HumanScope)
    # T096/FR-038: the human-directed scope (remediation choice 3) narrows THIS review. The run is
    # labelled completeness=partial by the orchestrator, so the narrowed evidence can never silently
    # satisfy the full-signoff gate (T094).
    $scopeBlock = if (-not [string]::IsNullOrWhiteSpace($HumanScope)) {
        $scopeText = switch -Regex ($HumanScope) {
            '^code$' { 'ONLY the CODE changes (skip process/progress conformance).'; break }
            '^process$' { 'ONLY the PROCESS/PROGRESS conformance (.review/process/; skip code-level review).'; break }
            '^path:(.+)$' { "ONLY the file/path '$($Matches[1])' (findings elsewhere are out of scope this round)."; break }
            '^function:(.+)$' { "ONLY the function/symbol '$($Matches[1])' and its direct call sites."; break }
            default { "ONLY: $HumanScope" }
        }
        "`nHUMAN-DIRECTED SCOPE (a remediation choice - honour it): review $scopeText`n"
    }
    else { '' }
    $roundBlock = if ($RoundNumber -gt 1 -and -not [string]::IsNullOrWhiteSpace($PriorFindings)) {
        "This is review round $RoundNumber of at most $MaxRounds. The PRIOR round produced these findings - verify each is RESOLVED in this change (a prior blocking finding still present is a failed fix):`n$PriorFindings`n`nIf this is the FINAL round ($RoundNumber of $MaxRounds) and a prior BLOCKING finding is STILL unresolved, return ONE finding with kind 'escalation' + severity 'blocking' calling for a HUMAN decision (stop the autonomous review->fix loop) - do not merely repeat the unresolved finding."
    }
    else {
        "This is review round $RoundNumber of at most $MaxRounds (initial review of this change)."
    }
    return @"
You are the Specrew continuous co-reviewer (a fresh-context, design- AND process-conformance reviewer).
$scopeBlock
Your current working directory IS the reviewed project. You are TRUSTED and may READ any file and RUN any
command (tests, build, lint, search) you need to verify the change — but you are READ-ONLY on the source: do
NOT modify, fix, or patch any file. Your job is to find issues, not fix them.

1. Read .review/changes.diff — this is the change-set under review (what changed).
2. Read .review/design/ — the spec + design-analysis (PROSE intent) the change must conform to, AND
   .review/design/contracts/ — the FORMAL contracts (JSON Schema / OpenAPI / proto) that are the AUTHORITY for
   machine formats. The prose and the contract MAY differ on machine details; see the AUTHORITY RULE below.
3. Read .review/process/ — the curated process/progress context (active task, phase, tasks-progress, drift-log,
   plan/tasks). The full plan/tasks/spec also live under specs/ in your worktree.
4. Browse the real project files around the changes for context. Prefer the implementer's recorded validation
   evidence when it is present and coherent (commands, exit codes, logs, durations). Run tests/build only when
   the evidence is absent, suspicious, too narrow for the risk, or a targeted rerun would materially change your
   confidence. Do not spend broad-suite time on low-value questions, but do spend time on important correctness,
   security, governance, or boundary risks.

AUTHORITY RULE (apply before judging ANY format/conformance question): A formal contract/schema — in
.review/design/contracts/, or any schema / proto / OpenAPI / typed-interface / enum table you can browse in the
project — is AUTHORITATIVE over prose. The spec + design narrative describe intent INFORMALLY and may differ from
the contract on machine details (casing, field names, types, allowed values, required-ness). Before raising ANY
conformance / format / casing / field-name / type / enum finding, CONSULT the formal contract. If the code matches
the contract but not the prose, the CODE IS CORRECT and the prose is loose — do not raise a blocking code finding
(at most a low-severity spec-prose-drift nit against the narrative). NEVER rule a machine-format question from the
narrative spec alone.

5. Judge the change on BOTH axes, citing the strongest reference for each finding:
   - DESIGN conformance: requirement/SC trace, architecture/boundaries, security, test confidence, operations.
   - PROCESS/PROGRESS conformance: does it implement the claimed task (trace to tasks.md), stay consistent with
     plan.md (no unplanned scope / absorbed deferred work), record drift in drift-log.md where it diverged, keep
     tasks-progress/state HONEST (nothing marked done that is not actually done/tested), and fit the current phase?

REPORT-FALSIFICATION STANCE (your core posture): actively SEEK evidence that the implementer's claims are FALSE
before accepting them. Challenge pass claims; treat an empty or substitute prompt, a stale mirror, a fake-only
assertion, hidden mutation, or a schema mismatch as falsification risks to verify, never to accept. A compliance
claim WITHOUT a traceable basis is itself a finding. Verify that a changed test connects to the implementation it
claims to cover - not merely to a fixture-owned substitute.

WORKSHOP-DECISION CONFORMANCE: the workshop records + design-analysis are BINDING. Raise a conflict when a change
bypasses approved seams, absorbs deferred work, edits protected surfaces, or changes host/runtime assumptions - do
not accept convenience over agreement. Validate against EACH applicable design lens (architecture, component
design, requirements/NFR, data-storage, security-compliance, integration/API, devops/operations,
observability/resilience, code-implementation; UI/UX only when supplied) and NAME the violated lens on every
blocking finding.

REVIEW PHASES (apply each, in order):
  (1) Requirement conformance - every material change is justified by an in-scope FR/SC/TG/SEC/INT/OBS/IMPL or
      data-contract reference.
  (2) Architecture and separation - transport, policy, contract, and persistence responsibilities stay separate;
      do not collapse them.
  (3) Security and privacy - secret exclusion, safe invocation, redaction; no exposure of prompts, transcripts,
      tokens, env values, or ambient state; never request, infer, persist, or echo secrets or sensitive content.
  (4) Verification confidence - tests prove the changed behavior; not empty, bypassed, or fixture-owned
      substitutes.
  (5) Operations and observability - failures are deterministic and diagnosable (provenance, hashes, timestamps);
      no live-CI dependence and no new dependencies.
  (6) Review decision - an unresolved design-contract violation MUST be a blocking finding.

NEVER-FALSE-GREEN: an infrastructure failure, invalid JSON, empty stdout, an empty prompt, a missing diff, or
unreadable context is NEVER "no findings" - report the failure as a finding, not a clean pass. Do not use live
web search, do not add dependencies, and do not invoke paid/non-default providers or hidden host tools.

## Review round
$roundBlock

INCREMENTAL EMISSION (so a review cut short by a timeout still surfaces what you found): the MOMENT you confirm a
finding, APPEND it as a single-line JSON object (one finding per line, the per-finding shape shown below) to
.review/findings.jsonl in your working directory — before you move on. This is IN ADDITION to the final object
below. If your review is interrupted, the harvested .review/findings.jsonl is what the implementer sees, so emit
findings there as you go, not only at the end.

Then, at the end, output ONLY one JSON object satisfying FindingsResult.v1 (no markdown, no prose around it):
{ "schema_version":"1.0", "run_id":"$RunId", "status":"findings"|"no_findings",
  "findings":[ { "finding_id":"f1", "source_run_id":"$RunId",
    "location":{"path":"relative/path","line_start":<int|null>,"line_end":<int|null>},
    "severity":"blocking"|"advisory"|"nit", "kind":"<short>", "design_reference":"<FR/SC/rule/file>",
    "comment":"<specific, actionable>", "disposition":"open",
    "resolution":{"state":"unresolved","fix_evidence_ref":null,"rationale":null} } ],
  "created_at":"<iso8601>" }
"@
}

function Get-ContinuousCoReviewHarvestedPartialResult {
    # T090/R1: when the final FindingsResult blob is empty/unparseable (a timeout / cut-short run), HARVEST what
    # the reviewer DID produce rather than discarding the run as "no-parseable-findings-json" (any review > nothing):
    #   1. the incremental .review/findings.jsonl (one JSON finding per line) - take the clean prefix, skip a
    #      truncated trailing line;
    #   2. PROSE-SALVAGE floor - if nothing structured, surface the reviewer's raw reasoning tail as ONE advisory note.
    # Returns a SCHEMA-CONFORMANT FindingsResult JSON string (status 'findings'), or $null if there is genuinely
    # nothing to harvest. The run's completeness=partial is recorded by the orchestrator on status.json (the
    # FindingsResult schema is additionalProperties:false, so it must not carry a completeness field); the gate
    # (R4) reads completeness from status.json.
    param(
        [Parameter(Mandatory)][string]$WorktreePath,
        [AllowNull()][string]$RawStdout,
        [Parameter(Mandatory)][string]$RunId
    )
    $findings = [System.Collections.Generic.List[object]]::new()
    $jsonlPath = Join-Path $WorktreePath '.review/findings.jsonl'
    if (Test-Path -LiteralPath $jsonlPath -PathType Leaf) {
        foreach ($line in @(Get-Content -LiteralPath $jsonlPath -ErrorAction SilentlyContinue)) {
            $t = ([string]$line).Trim()
            if ([string]::IsNullOrWhiteSpace($t)) { continue }
            try {
                $obj = $t | ConvertFrom-Json -ErrorAction Stop
                if ($null -ne $obj -and $null -ne $obj.PSObject.Properties['comment']) { $findings.Add($obj) }
            }
            catch { $null = $_ }   # a truncated / garbled trailing line is expected on a killed run - skip it
        }
    }
    if ($findings.Count -eq 0) {
        $prose = if ($null -ne $RawStdout) { $RawStdout.Trim() } else { '' }
        if ([string]::IsNullOrWhiteSpace($prose)) { return $null }
        $tail = if ($prose.Length -gt 2000) { $prose.Substring($prose.Length - 2000) } else { $prose }
        $findings.Add([pscustomobject]@{
                finding_id      = 'partial-1'
                source_run_id   = $RunId
                location        = [pscustomobject]@{ line_start = $null; line_end = $null }   # f1: path OMITTED (schema types it string, not null)
                severity        = 'advisory'
                kind            = 'partial-unverified-notes'
                design_reference = 'partial-review-salvage'   # f1: schema requires a non-empty string, not null
                comment         = ('Review was cut short before a structured verdict; UNVERIFIED reviewer notes salvaged: ' + $tail)
                disposition     = 'open'
                resolution      = [pscustomobject]@{ state = 'unresolved'; fix_evidence_ref = $null; rationale = $null }
            })
    }
    # f1: the FindingsResult schema is additionalProperties:false, so `completeness` does NOT belong here -
    # the run's completeness=partial is recorded on status.json by the orchestrator (where the gate reads it).
    $result = [pscustomobject]@{
        schema_version = '1.0'
        run_id         = $RunId
        status         = 'findings'
        findings       = $findings.ToArray()
        created_at     = (ConvertTo-ContinuousCoReviewReviewerIsoTimestamp)
    }
    return ($result | ConvertTo-Json -Depth 100 -Compress)
}

function New-ContinuousCoReviewCeilingEscalationResult {
    # D-197-I009-010 (false-green hardening): the round CEILING halts the auto-loop to stop the spin (the round-9
    # fix) — but a halt is NOT a clean pass. The old ceiling wrote an EMPTY result, so the run read as
    # 'done / 0 findings / clean' and SILENTLY passed an UNREVIEWED increment (the false-green that fooled a dogfood
    # coordinator into signing off code the reviewer never saw). Instead, emit a VISIBLE escalation finding so the
    # run can NEVER be read as clean: kind='escalation' (Option A keeps it parked as escalated_to_human, so the
    # signoff gate does NOT deadlock on it) + severity 'blocking' (so the navigator surfaces a NOT-REVIEWED stop-
    # block) + a plain-words comment. Schema-conformant FindingsResult (findings-result.schema.json). Returns JSON.
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][int]$Round,
        [Parameter(Mandatory)][int]$MaxRounds
    )
    $comment = (
        ("CO-REVIEW CEILING REACHED (round {0} > max_rounds {1}) with an unresolved blocking finding still open from a " -f $Round, $MaxRounds) +
        'prior round. This increment was NOT REVIEWED -- the auto-loop stopped here to avoid spinning. This is an ' +
        'ESCALATION, not a clean pass: resolve the open blocking finding, or raise co_review_max_rounds / reset the ' +
        "co-review round state, so review resumes. Reading this run as '0 findings / clean' is a FALSE-GREEN."
    )
    $result = [pscustomobject]@{
        schema_version = '1.0'
        run_id         = $RunId
        status         = 'findings'
        findings       = @(
            [pscustomobject]@{
                finding_id       = 'co-review-ceiling-escalation'
                source_run_id    = $RunId
                location         = [pscustomobject]@{ path = '.review/changes.diff' }
                severity         = 'blocking'
                kind             = 'escalation'
                design_reference = 'co-review round ceiling (co_review_max_rounds)'
                comment          = $comment
                disposition      = 'escalated_to_human'
                resolution       = [pscustomobject]@{ state = 'escalated'; fix_evidence_ref = $null; rationale = $null }
            }
        )
        created_at     = (ConvertTo-ContinuousCoReviewReviewerIsoTimestamp)
    }
    return ($result | ConvertTo-Json -Depth 100 -Compress)
}

function Get-ContinuousCoReviewAgentCommand {
    # Per-host AGENTIC invocation for the worktree reviewer (read + RUN in the cwd; read-only on the real source —
    # the worktree is ephemeral so a write-capable sandbox is safe). LOOKED UP from the host CATALOG
    # (Get-ContinuousCoReviewHostAgenticCommand, data in reviewer-host-catalog.ps1) — this core is host-NEUTRAL, so
    # adding a reviewer host is a catalog-ROW edit, never a change here. The reviewer-host SELECTION (which host,
    # authorized, code-writer-independent) is the policy's job.
    param([Parameter(Mandatory)][string]$HostName)
    # The DETACHED pipeline dot-sources _load.ps1 only INSIDE Resolve-...ReviewerHost's function scope, so the
    # catalog is gone by the time this runs — without this lazy-load, the SELECTED reviewer's command could not
    # resolve and the run would fail loud (see the throw below). Dot-source _load into THIS scope and use the
    # catalog immediately (host-NEUTRALity: the catalog is the ONLY host-data source; this just reaches it).
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewHostAgenticCommand' -ErrorAction SilentlyContinue)) {
        $loadPath = Join-Path $PSScriptRoot '_load.ps1'
        if (Test-Path -LiteralPath $loadPath -PathType Leaf) { try { . $loadPath } catch { $null = $_ } }
    }
    if (Get-Command -Name 'Get-ContinuousCoReviewHostAgenticCommand' -ErrorAction SilentlyContinue) {
        $cmd = Get-ContinuousCoReviewHostAgenticCommand -HostName $HostName
        if ($null -ne $cmd -and -not [string]::IsNullOrWhiteSpace([string]$cmd.file)) { return $cmd }
    }
    # D-197-I010-002 (host-neutral core): NO hardcoded harness fallback. An unreachable catalog is a
    # deploy gap - fail LOUD (the orchestrator surfaces the failed run) rather than silently invoking
    # a wrong host. Host specifics (binary, flags, prompt transport) live ONLY in the catalog.
    throw "co-review: the reviewer host catalog is unreachable, so the agentic command for host '$HostName' cannot be resolved (host specifics live only in reviewer-host-catalog.ps1; check the module deploy)."
}

function ConvertTo-ContinuousCoReviewReviewerIsoTimestamp {
    param([datetime]$Timestamp = [datetime]::UtcNow)
    return $Timestamp.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

function New-ContinuousCoReviewReviewerInvocationTelemetry {
    param(
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)]$Command,
        [Parameter(Mandatory)][datetime]$StartedAt,
        [Parameter(Mandatory)]$Stopwatch,
        [Parameter(Mandatory)][int]$TimeoutSeconds,
        [bool]$TimedOut = $false,
        [bool]$Running = $false,
        [AllowNull()]$Containment
    )

    return [pscustomobject][ordered]@{
        reviewer_host               = $HostName
        command_file                = [string]$Command.file
        command_args                = @($Command.pre_args)
        prompt_via_stdin            = [bool]$Command.prompt_via_stdin
        timeout_seconds             = $TimeoutSeconds
        started_at                  = ConvertTo-ContinuousCoReviewReviewerIsoTimestamp -Timestamp $StartedAt
        updated_at                  = ConvertTo-ContinuousCoReviewReviewerIsoTimestamp
        elapsed_seconds             = [math]::Round($Stopwatch.Elapsed.TotalSeconds, 3)
        running                     = $Running
        timed_out                   = $TimedOut
        # T091/N1 instrumentation: WHICH containment held the reviewer + the pids the reaper needs to
        # kill the tree of a dead detached-entry (flows into status.json via the heartbeat).
        containment                 = if ($null -ne $Containment) { [string]$Containment.mode } else { $null }
        child_pid                   = if ($null -ne $Containment) { $Containment.child_pid } else { $null }
        child_pgid                  = if ($null -ne $Containment) { $Containment.child_pgid } else { $null }
        containment_degraded_reason = if ($null -ne $Containment) { $Containment.degraded_reason } else { $null }
    }
}

function Invoke-ContinuousCoReviewAgentInWorktree {
    # Run the SELECTED agentic host in the worktree cwd with a GIVEN prompt (read + run; read-only on source).
    # SHARED by the REVIEW path (slim review prompt) AND the ASK path (follow-up-question prompt), so a future
    # MCP `ask_reviewer` tool reuses the EXACT same trusted agent invocation. Returns @{ exit_code; stdout; stderr }.
    param(
        [Parameter(Mandatory)][string]$WorktreePath,
        [Parameter(Mandatory)][string]$Prompt,
        # MANDATORY (D-197-I010-002): the host comes from the SELECTION policy over the catalog -
        # the core never defaults to a named harness.
        [Parameter(Mandatory)][string]$HostName,
        [int]$TimeoutSeconds = 600,
        [scriptblock]$Heartbeat
    )
    $cmd = Get-ContinuousCoReviewAgentCommand -HostName $HostName
    $startedAt = [datetime]::UtcNow
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # T091/N1 (FR-037): the reviewer spawn is managed by the SAME OS-native containment the isolated-task
    # supervisor uses (T100: Job Object w/ KILL_ON_JOB_CLOSE on Windows, setsid+PGID group on Unix, the
    # snapshot walk as the helper-internal fallback). REQUIRED: a reviewer we cannot contain is a reviewer
    # we refuse to spawn - a deploy gap fails LOUD (the orchestrator surfaces the reason) instead of the
    # old divergent single-pid .NET kill fallback (deleted per N1: ONE kill mechanism, not two).
    if (-not (Get-Command -Name 'New-SpecrewProcessContainment' -ErrorAction SilentlyContinue)) {
        $helper = Join-Path (Split-Path -Parent $PSScriptRoot) 'agent-tasks/process-tree.ps1'
        if (Test-Path -LiteralPath $helper -PathType Leaf) { try { . $helper } catch { $null = $_ } }
    }
    if (-not (Get-Command -Name 'New-SpecrewProcessContainment' -ErrorAction SilentlyContinue)) {
        throw 'co-review: the OS-native containment helper (agent-tasks/process-tree.ps1) is unavailable - refusing to spawn an uncontainable reviewer (T091/FR-037; check the module deploy).'
    }
    # Compile the containment runtime BEFORE the spawn: the first-use Add-Type takes seconds, and paying
    # it after Start() opens the pre-assignment escape window (empirically caught - the grandchild forked
    # during the compile and outlived every kill).
    Initialize-SpecrewProcessContainmentRuntime

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $cmd.file
    foreach ($a in @($cmd.pre_args)) { [void]$psi.ArgumentList.Add($a) }
    if (-not $cmd.prompt_via_stdin) { [void]$psi.ArgumentList.Add($Prompt) }   # codex exec takes the prompt as a positional arg
    if (-not $IsWindows) {
        # setsid exec (same trick as the supervisor spawn): the reviewer becomes its own session/group
        # leader so one group signal reaches its whole tree; exec-in-place keeps the PID + the redirected
        # stdio pipes. The containment probe below VERIFIES leadership and degrades honestly if not.
        $setsidBin = Get-Command -Name 'setsid' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($setsidBin) {
            $inner = @($psi.FileName) + @($psi.ArgumentList)
            $psi.ArgumentList.Clear()
            foreach ($a in $inner) { [void]$psi.ArgumentList.Add($a) }
            $psi.FileName = $setsidBin.Source
        }
    }
    $psi.WorkingDirectory = $WorktreePath
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.StandardInputEncoding = [System.Text.UTF8Encoding]::new($false)
    $proc = [System.Diagnostics.Process]::new(); $proc.StartInfo = $psi
    [void]$proc.Start()
    # Contain BEFORE handing the reviewer its prompt: a stdin-prompted host is still blocked reading stdin
    # here, so the tree is contained before the reviewer can have forked anything (zero escape window).
    $containment = New-SpecrewProcessContainment -ChildPid $proc.Id
    try {
        $outTask = $proc.StandardOutput.ReadToEndAsync(); $errTask = $proc.StandardError.ReadToEndAsync()
        # T108 hardening: a reviewer that exits (or closes stdin) BEFORE consuming the prompt breaks the
        # pipe - that IOException must not crash the invocation (it IS the empty-exit0 failure class the
        # retry exists for); the child's own exit code + captured output still tell the truth.
        if ($cmd.prompt_via_stdin) {
            try { $proc.StandardInput.Write($Prompt) } catch { $null = $_ }
        }
        try { $proc.StandardInput.Close() } catch { $null = $_ }
        $exited = $false
        while (-not $exited) {
            $remainingMs = [int][math]::Ceiling(($TimeoutSeconds * 1000) - $sw.ElapsedMilliseconds)
            if ($remainingMs -le 0) { break }
            $sliceMs = [math]::Min(5000, $remainingMs)
            $exited = $proc.WaitForExit($sliceMs)
            if (-not $exited -and $Heartbeat) {
                try {
                    & $Heartbeat (New-ContinuousCoReviewReviewerInvocationTelemetry -HostName $HostName -Command $cmd -StartedAt $startedAt -Stopwatch $sw -TimeoutSeconds $TimeoutSeconds -Running $true -Containment $containment)
                }
                catch { $null = $_ }
            }
        }
        if (-not $exited) {
            # THE one kill (T091/N1): graceful TERM (flush window for the in-flight finding, R1) ->
            # atomic OS kill (job / group) -> snapshot-walk sweep, all inside the shared helper.
            Stop-SpecrewProcessContainment -Containment $containment -GraceSeconds 5
            $sw.Stop()
            # BLOCKING co-review finding (T090/R1): the reviewer's stdout captured BEFORE the kill (including anything
            # flushed during the graceful window) lives in $outTask. Return it as the partial result so prose-salvage
            # has the in-pipe reasoning to fall back on. WITHOUT this, every timeout returned stdout='' and the salvage
            # floor was inert on the EXACT failure (timeout) the iteration was built for. The pipe closes when the
            # killed process exits, so the bounded await resolves promptly.
            $partialOut = ''
            try { if ($outTask.Wait(3000)) { $partialOut = [string]$outTask.Result } } catch { $null = $_ }
            return [pscustomobject]@{
                exit_code        = $null
                stdout           = $partialOut
                stderr           = 'timeout'
                telemetry        = (New-ContinuousCoReviewReviewerInvocationTelemetry -HostName $HostName -Command $cmd -StartedAt $startedAt -Stopwatch $sw -TimeoutSeconds $TimeoutSeconds -TimedOut $true -Containment $containment)
            }
        }
        $out = if ($outTask.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion) { $outTask.Result } else { '' }
        $err = if ($errTask.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion) { $errTask.Result } else { '' }
        $code = $proc.ExitCode; $proc.Dispose()
        $sw.Stop()
        return [pscustomobject]@{
            exit_code = $code
            stdout    = $out
            stderr    = $err
            telemetry = (New-ContinuousCoReviewReviewerInvocationTelemetry -HostName $HostName -Command $cmd -StartedAt $startedAt -Stopwatch $sw -TimeoutSeconds $TimeoutSeconds -Containment $containment)
        }
    }
    finally {
        # Straggler reap + handle release, same semantics as the supervisor's finally: a background
        # process the reviewer left behind must not outlive the run, even on a clean exit.
        try { Close-SpecrewProcessContainment -Containment $containment } catch { $null = $_ }
    }
}

function Invoke-ContinuousCoReviewWorktreeReviewer {
    # The REVIEW invocation: the slim design+process-review prompt (round-aware), via the shared agent-in-worktree,
    # on the SELECTED (independent, authorized) reviewer host.
    param(
        [Parameter(Mandatory)][string]$WorktreePath, [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$HostName, [int]$RoundNumber = 1, [int]$MaxRounds = 2, [string]$PriorFindings,
        [int]$TimeoutSeconds = 600,
        [scriptblock]$Heartbeat,
        [string]$HumanScope
    )
    $prompt = Get-ContinuousCoReviewSlimPrompt -RunId $RunId -RoundNumber $RoundNumber -MaxRounds $MaxRounds -PriorFindings $PriorFindings -HumanScope $HumanScope
    $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $WorktreePath -Prompt $prompt -HostName $HostName -TimeoutSeconds $TimeoutSeconds -Heartbeat $Heartbeat

    # T108/FR-033 (D-197-I009-015): retry ONCE on an EMPTY exit-0 result before the run can be declared
    # no-parseable-findings - the field failure was ~50% empty-but-successful exits on one reviewer host,
    # but the guard is host-GENERIC (any host can drop its final blob). The DIAGNOSTIC distinguishes the
    # two suspect causes: incremental findings PRESENT in the worktree = the reviewer worked and the
    # final stdout was lost (finalization/capture gap); ABSENT = the run produced nothing at all.
    # NEVER-FALSE-GREEN is preserved: a still-empty retry returns empty and the orchestrator fails the
    # run loudly (no-parseable-findings-json) - the retry can only ADD a real result, never fake one.
    $emptyExit0 = ($null -ne $r) -and ($r.exit_code -eq 0) -and [string]::IsNullOrWhiteSpace([string]$r.stdout)
    if ($emptyExit0) {
        $jsonlPresent = Test-Path -LiteralPath (Join-Path $WorktreePath '.review/findings.jsonl') -PathType Leaf
        $firstAttempt = [pscustomobject][ordered]@{
            exit_code                    = $r.exit_code
            stdout_length                = ([string]$r.stdout).Length
            stderr_length                = ([string]$r.stderr).Length
            elapsed_seconds              = if ($null -ne $r.telemetry) { $r.telemetry.elapsed_seconds } else { $null }
            incremental_findings_present = $jsonlPresent
            probable_cause               = if ($jsonlPresent) { 'finalization-or-capture-gap' } else { 'no-output-produced' }
        }
        [Console]::Error.WriteLine(("[co-review] WARN EMPTY_EXIT0_RESULT reviewer host '{0}' returned exit 0 with EMPTY stdout (probable cause: {1}); retrying once (T108/D-197-I009-015)." -f $HostName, $firstAttempt.probable_cause))
        $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $WorktreePath -Prompt $prompt -HostName $HostName -TimeoutSeconds $TimeoutSeconds -Heartbeat $Heartbeat
        if ($null -ne $r.telemetry) {
            $r.telemetry | Add-Member -NotePropertyName 'empty_result_retry' -NotePropertyValue ([pscustomobject][ordered]@{
                    retried              = $true
                    first_attempt        = $firstAttempt
                    retry_stdout_length  = ([string]$r.stdout).Length
                    retry_still_empty    = [string]::IsNullOrWhiteSpace([string]$r.stdout)
                }) -Force
        }
    }
    return $r
}
