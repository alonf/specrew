$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

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
        'scripts/internal/agent-tasks', 'scripts/internal/atomic-write.ps1',
        'CLAUDE.md', 'AGENTS.md', 'GEMINI.md'
    )
    if (-not (Test-ContinuousCoReviewSpecrewSourceRepo -RepoRoot $RepoRoot)) {
        $core += 'scripts/internal/continuous-co-review'
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
    if (-not [string]::IsNullOrWhiteSpace($featureDir)) {
        $featureFull = Join-Path $RepoRoot $featureDir
        $latestIter = $null
        $iterRoot = Join-Path $featureFull 'iterations'
        if (Test-Path -LiteralPath $iterRoot -PathType Container) {
            $latestIter = @(Get-ChildItem -LiteralPath $iterRoot -Directory -EA SilentlyContinue | Where-Object { $_.Name -match '^\d+$' } | Sort-Object { [int]$_.Name } -Descending | Select-Object -First 1)
        }
        $progressFiles = @((Join-Path $featureFull 'tasks.md'), (Join-Path $featureFull 'plan.md'))
        if ($latestIter) { foreach ($n in @('tasks-progress.yml', 'drift-log.md', 'state.md')) { $progressFiles += (Join-Path $latestIter[0].FullName $n) } }
        foreach ($pf in $progressFiles) {
            if (Test-Path -LiteralPath $pf -PathType Leaf) { Copy-Item -LiteralPath $pf -Destination $procDir -Force; [void]$copied.Add((Split-Path $pf -Leaf)) }
        }
    }

    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('# Process / progress context (curated)')
    [void]$lines.Add('')
    [void]$lines.Add("Active feature: $featureDir")
    [void]$lines.Add("Current phase / last-authorized boundary: $phase")
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
    [void]$lines.Add('- Does the work fit the current phase/boundary?')
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

    return [pscustomobject]@{ worktree_path = $worktree; tree_id = $treeId; changed_count = $changed.Count; changed_paths = @($changed) }
}

function Get-ContinuousCoReviewSlimPrompt {
    # The SLIM prompt (a few KB) — the reviewer reads the diff + design + browses/runs the project itself.
    # Round-aware: round 1 reviews; later rounds verify the prior findings are resolved; at the FINAL round the
    # reviewer escalates (the counter is a safety ceiling, the reviewer's judgement is the brains).
    param([Parameter(Mandatory)][string]$RunId, [int]$RoundNumber = 1, [int]$MaxRounds = 2, [string]$PriorFindings)
    $roundBlock = if ($RoundNumber -gt 1 -and -not [string]::IsNullOrWhiteSpace($PriorFindings)) {
        "This is review round $RoundNumber of at most $MaxRounds. The PRIOR round produced these findings - verify each is RESOLVED in this change (a prior blocking finding still present is a failed fix):`n$PriorFindings`n`nIf this is the FINAL round ($RoundNumber of $MaxRounds) and a prior BLOCKING finding is STILL unresolved, return ONE finding with kind 'escalation' + severity 'blocking' calling for a HUMAN decision (stop the autonomous review->fix loop) - do not merely repeat the unresolved finding."
    }
    else {
        "This is review round $RoundNumber of at most $MaxRounds (initial review of this change)."
    }
    return @"
You are the Specrew continuous co-reviewer (a fresh-context, design- AND process-conformance reviewer).

Your current working directory IS the reviewed project. You are TRUSTED and may READ any file and RUN any
command (tests, build, lint, search) you need to verify the change — but you are READ-ONLY on the source: do
NOT modify, fix, or patch any file. Your job is to find issues, not fix them.

1. Read .review/changes.diff — this is the change-set under review (what changed).
2. Read .review/design/ — the spec + design-analysis (PROSE intent) the change must conform to, AND
   .review/design/contracts/ — the FORMAL contracts (JSON Schema / OpenAPI / proto) that are the AUTHORITY for
   machine formats. The prose and the contract MAY differ on machine details; see the AUTHORITY RULE below.
3. Read .review/process/ — the curated process/progress context (active task, phase, tasks-progress, drift-log,
   plan/tasks). The full plan/tasks/spec also live under specs/ in your worktree.
4. Browse the real project files around the changes for context; run tests/build if it helps you verify.

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

## Review round
$roundBlock

Output ONLY one JSON object satisfying FindingsResult.v1 (no markdown, no prose around it):
{ "schema_version":"1.0", "run_id":"$RunId", "status":"findings"|"no_findings",
  "findings":[ { "finding_id":"f1", "source_run_id":"$RunId",
    "location":{"path":"relative/path","line_start":<int|null>,"line_end":<int|null>},
    "severity":"blocking"|"advisory"|"nit", "kind":"<short>", "design_reference":"<FR/SC/rule/file>",
    "comment":"<specific, actionable>", "disposition":"open",
    "resolution":{"state":"unresolved","fix_evidence_ref":null,"rationale":null} } ],
  "created_at":"<iso8601>" }
"@
}

function Get-ContinuousCoReviewAgentCommand {
    # Per-host AGENTIC invocation for the worktree reviewer (read + RUN in the cwd; read-only on the real source —
    # the worktree is ephemeral so a write-capable sandbox is safe). LOOKED UP from the host CATALOG
    # (Get-ContinuousCoReviewHostAgenticCommand, data in reviewer-host-catalog.ps1) — this core is host-NEUTRAL, so
    # adding a reviewer host is a catalog-ROW edit, never a change here. The reviewer-host SELECTION (which host,
    # authorized, code-writer-independent) is the policy's job.
    param([Parameter(Mandatory)][string]$HostName)
    # The DETACHED pipeline dot-sources _load.ps1 only INSIDE Resolve-...ReviewerHost's function scope, so the
    # catalog is gone by the time this runs — without this lazy-load, a SELECTED codex reviewer would silently fall
    # through to the claude default below (wrong binary + flags, and status.json would mislabel it as codex).
    # Dot-source _load into THIS scope and use the catalog immediately (the host-NEUTRALity is intact: data is in
    # the catalog, this just reaches it).
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewHostAgenticCommand' -ErrorAction SilentlyContinue)) {
        $loadPath = Join-Path $PSScriptRoot '_load.ps1'
        if (Test-Path -LiteralPath $loadPath -PathType Leaf) { try { . $loadPath } catch { $null = $_ } }
    }
    if (Get-Command -Name 'Get-ContinuousCoReviewHostAgenticCommand' -ErrorAction SilentlyContinue) {
        $cmd = Get-ContinuousCoReviewHostAgenticCommand -HostName $HostName
        if ($null -ne $cmd -and -not [string]::IsNullOrWhiteSpace([string]$cmd.file)) { return $cmd }
    }
    # Last-resort fallback ONLY if the catalog is genuinely unreachable.
    return [pscustomobject]@{ file = 'claude'; pre_args = @('-p', '--permission-mode', 'bypassPermissions'); prompt_via_stdin = $true }
}

function Invoke-ContinuousCoReviewAgentInWorktree {
    # Run the SELECTED agentic host in the worktree cwd with a GIVEN prompt (read + run; read-only on source).
    # SHARED by the REVIEW path (slim review prompt) AND the ASK path (follow-up-question prompt), so a future
    # MCP `ask_reviewer` tool reuses the EXACT same trusted agent invocation. Returns @{ exit_code; stdout; stderr }.
    param(
        [Parameter(Mandatory)][string]$WorktreePath,
        [Parameter(Mandatory)][string]$Prompt,
        [string]$HostName = 'claude',
        [int]$TimeoutSeconds = 600
    )
    $cmd = Get-ContinuousCoReviewAgentCommand -HostName $HostName
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $cmd.file
    foreach ($a in @($cmd.pre_args)) { [void]$psi.ArgumentList.Add($a) }
    if (-not $cmd.prompt_via_stdin) { [void]$psi.ArgumentList.Add($Prompt) }   # codex exec takes the prompt as a positional arg
    $psi.WorkingDirectory = $WorktreePath
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.StandardInputEncoding = [System.Text.UTF8Encoding]::new($false)
    $proc = [System.Diagnostics.Process]::new(); $proc.StartInfo = $psi
    [void]$proc.Start()
    $outTask = $proc.StandardOutput.ReadToEndAsync(); $errTask = $proc.StandardError.ReadToEndAsync()
    if ($cmd.prompt_via_stdin) { $proc.StandardInput.Write($Prompt) }
    $proc.StandardInput.Close()
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) { try { $proc.Kill($true) } catch { }; return [pscustomobject]@{ exit_code = $null; stdout = ''; stderr = 'timeout' } }
    $out = if ($outTask.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion) { $outTask.Result } else { '' }
    $err = if ($errTask.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion) { $errTask.Result } else { '' }
    $code = $proc.ExitCode; $proc.Dispose()
    return [pscustomobject]@{ exit_code = $code; stdout = $out; stderr = $err }
}

function Invoke-ContinuousCoReviewWorktreeReviewer {
    # The REVIEW invocation: the slim design+process-review prompt (round-aware), via the shared agent-in-worktree,
    # on the SELECTED (independent, authorized) reviewer host.
    param(
        [Parameter(Mandatory)][string]$WorktreePath, [Parameter(Mandatory)][string]$RunId,
        [string]$HostName = 'claude', [int]$RoundNumber = 1, [int]$MaxRounds = 2, [string]$PriorFindings,
        [int]$TimeoutSeconds = 600
    )
    $prompt = Get-ContinuousCoReviewSlimPrompt -RunId $RunId -RoundNumber $RoundNumber -MaxRounds $MaxRounds -PriorFindings $PriorFindings
    return (Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $WorktreePath -Prompt $prompt -HostName $HostName -TimeoutSeconds $TimeoutSeconds)
}
