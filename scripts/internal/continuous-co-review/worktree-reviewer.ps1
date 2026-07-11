$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T091/FR-037 + T100/FR-039: ONE process manager for the reviewer spawn - the same OS-native containment
# primitives the isolated-task supervisor uses (process-tree.ps1: Job Object / setsid+PGID / snapshot-walk
# fallback). Loaded here; REQUIRED at spawn time (Invoke-ContinuousCoReviewAgentInWorktree refuses to spawn
# an uncontainable reviewer - the divergent $proc.Kill fallback is deleted per design N1).
$specrewProcessTreeHelper = Join-Path (Split-Path -Parent $PSScriptRoot) 'agent-tasks/process-tree.ps1'
if (Test-Path -LiteralPath $specrewProcessTreeHelper -PathType Leaf) { . $specrewProcessTreeHelper }

function Invoke-WorktreeReviewerGitCapture {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    # Robust git invocation IMMUNE to the ambient [Console]::OutputEncoding state: PowerShell's
    # `& git` throws "StandardOutputEncoding is only supported when standard output is redirected"
    # in hook/supervised contexts (F-197 iter-005 lesson, same pattern as
    # Invoke-ContinuousCoReviewGit in checkpoint-diff-provider.ps1; this call site was never
    # migrated - caught blocking the F-198 iteration-001 signoff review, runs 6e5a8dab/cc6e2018/
    # 1a752eea). Local copy keeps this file self-contained across the detached load orders.
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'git'
    foreach ($a in $Arguments) { [void]$psi.ArgumentList.Add([string]$a) }
    $psi.WorkingDirectory = $RepoRoot
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $psi.StandardErrorEncoding = [System.Text.UTF8Encoding]::new($false)

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi
    [void]$proc.Start()
    $stdout = $proc.StandardOutput.ReadToEnd()
    [void]$proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $proc.Dispose()
    return $stdout
}

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

function ConvertTo-ContinuousCoReviewOriginRelativized {
    # FR-009 (203 W2) origin-path hygiene: strip/relativize ORIGIN-ABSOLUTE paths from the
    # reviewer-visible context so the confined reviewer never sees the real project location (an
    # information leak that also hands it an upward path out of the worktree). RELATIVIZES rather
    # than removes - the path STRUCTURE stays reviewable (e.g. specs/.../state.md), only the origin
    # PREFIX is neutralized to '<project>'. Case-insensitive (Windows paths); covers file:/// URLs
    # and both separator forms. Composes with the Devin design-ref plumbing: a supplied design-context
    # path is relativized, never dropped.
    param(
        [AllowNull()][string]$Content,
        [Parameter(Mandatory)][string[]]$OriginRoots
    )
    if ([string]::IsNullOrWhiteSpace($Content)) { return $Content }
    $out = $Content
    $ci = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    foreach ($root in ($OriginRoots | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object { $_.Length } -Descending)) {
        $full = [System.IO.Path]::GetFullPath($root).TrimEnd([char]'\', [char]'/')
        $fwd = $full.Replace('\', '/')
        $bwd = $full.Replace('/', '\')
        # file:/// URL form first (most specific), then the bare absolute path in either separator form.
        $out = [regex]::Replace($out, ('file:///' + [regex]::Escape($fwd)), 'file:///<project>', $ci)
        $out = [regex]::Replace($out, [regex]::Escape($fwd), '<project>', $ci)
        $out = [regex]::Replace($out, [regex]::Escape($bwd), '<project>', $ci)
    }
    return $out
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
    # FR-009 origin-path hygiene: the origin roots whose absolute form must never appear in the
    # reviewer's context - the governance RepoRoot AND the git top-level (nested-project safe).
    $originRoots = @($RepoRoot)
    try { $gitTop = (& git -C $RepoRoot rev-parse --show-toplevel 2>$null); if (-not [string]::IsNullOrWhiteSpace($gitTop)) { $originRoots += $gitTop.Trim() } } catch { $null = $_ }

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
            if (Test-Path -LiteralPath $pf -PathType Leaf) {
                # FR-009: relativize origin-absolute paths (file:/// URLs, bare paths) IN THE COPY the
                # reviewer sees - the snapshot content stays reviewable, the origin location does not leak.
                $leaf = Split-Path $pf -Leaf
                $scrubbed = ConvertTo-ContinuousCoReviewOriginRelativized -Content (Get-Content -LiteralPath $pf -Raw -Encoding UTF8) -OriginRoots $originRoots
                [System.IO.File]::WriteAllText((Join-Path $procDir $leaf), $scrubbed)
                [void]$copied.Add($leaf)
            }
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
    [System.IO.File]::WriteAllText((Join-Path $procDir 'process-context.md'), (ConvertTo-ContinuousCoReviewOriginRelativized -Content ($lines -join "`n") -OriginRoots $originRoots))
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
        [string]$EphemeralRoot,
        [AllowEmptyString()][string]$SourceTreeId
    )
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    $gitRoot = (& git -C $resolved rev-parse --show-toplevel 2>$null).Trim()
    $prefix = (& git -C $resolved rev-parse --show-prefix 2>$null).Trim().TrimEnd('/')   # '' when project == git root
    # IDENTITY UNIFICATION (escalation 20260708T211331029, FR-025 class): when the orchestrator passes the
    # reviewed-state digest tree (-SourceTreeId), materialize FROM THAT TREE - the reviewed content and the
    # gate-certified content are then the SAME git object by construction, so uncommitted working-tree changes
    # are REVIEWED, never silently certified. Without it (digest failure / legacy callers) fall back to HEAD;
    # the orchestrator's reviewed_digest_error then says why the identities may differ.
    $reviewSource = if (-not [string]::IsNullOrWhiteSpace($SourceTreeId)) { $SourceTreeId } else { 'HEAD' }
    # Resolve the reviewed subtree's TREE id (<src>:path is already a tree; a commit-ish needs ^{tree} to peel).
    $treeId = if ([string]::IsNullOrWhiteSpace($prefix)) {
        (& git -C $gitRoot rev-parse "$reviewSource^{tree}" 2>$null).Trim()
    }
    else {
        (& git -C $gitRoot rev-parse "${reviewSource}:$prefix" 2>$null).Trim()
    }

    if ([string]::IsNullOrWhiteSpace($EphemeralRoot)) { $EphemeralRoot = [System.IO.Path]::GetTempPath() }
    # FR-008 (203 W1) / SC-002 containment: the reviewer worktree MUST materialize OUTSIDE the
    # origin so no upward directory/git walk from inside the confined worktree can resolve the real
    # project. Reject an EphemeralRoot that resolves AT or UNDER the origin git root (or the
    # governance RepoRoot) - a worktree nested in origin would defeat the confinement by
    # construction. Fails LOUD and early, before any archive/extract.
    $ephemeralFull = [System.IO.Path]::GetFullPath($EphemeralRoot).TrimEnd([char]'\', [char]'/')
    foreach ($originPath in @($gitRoot, $resolved)) {
        if ([string]::IsNullOrWhiteSpace($originPath)) { continue }
        $originFull = [System.IO.Path]::GetFullPath($originPath).TrimEnd([char]'\', [char]'/')
        if ($ephemeralFull -eq $originFull -or $ephemeralFull.StartsWith($originFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "[co-review] refusing to materialize the reviewer worktree inside the origin ('$originFull'): the confined worktree must live outside the project so no upward walk can resolve it (FR-008 containment)."
        }
    }
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
    # Collapse same-parent `specrew-*` mirror dirs into ONE glob exclude per parent: the marker
    # scan yields hundreds of sibling dirs (398 in the self-host repo) and the literal exclude
    # list crossed the Windows 32K command-line limit mid-F-198 ("The filename or extension is
    # too long", run fe3a695a). Semantics preserved: every collapsed sibling matches its parent
    # glob; an unmarked `specrew-*` dir under the same parent is machinery by naming anyway.
    $literalMachinery = [System.Collections.Generic.List[string]]::new()
    $globParents = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($m in $machinery) {
        if ($m -eq '.git') { continue }
        if ($m -match '^(?<parent>.+)/(?<leaf>specrew-[^/]+)$') {
            [void]$globParents.Add($Matches['parent'])
        }
        else {
            [void]$literalMachinery.Add($m)
        }
    }
    $machineryExcludes = @(
        foreach ($m in $literalMachinery) {
            $mp = if ([string]::IsNullOrWhiteSpace($prefix)) { $m } else { "$prefix/$m" }
            ":(exclude)$mp"
        }
        foreach ($p in $globParents) {
            $pp = if ([string]::IsNullOrWhiteSpace($prefix)) { $p } else { "$prefix/$p" }
            ":(exclude)$pp/specrew-*"
        }
    )
    # The change-set diff runs baseline -> the SAME review source as the materialized tree (git diff accepts
    # tree objects), so .review/changes.diff shows exactly what the reviewer's worktree contains - including
    # uncommitted changes when the digest tree is the source.
    $diffPathspec = @($scope) + @($machineryExcludes)
    # Console-state-immune invocations (see Invoke-WorktreeReviewerGitCapture above); the glob
    # collapse above keeps the pathspec far below the Windows command-line limit (git diff has
    # no --pathspec-from-file, so the command line is the only channel).
    $diffArgs = @('diff', '--no-ext-diff', '--src-prefix=a/', '--dst-prefix=b/', $BaselineRef, $reviewSource, '--') + @($diffPathspec)
    $diff = Invoke-WorktreeReviewerGitCapture -RepoRoot $gitRoot -Arguments $diffArgs
    if (-not [string]::IsNullOrWhiteSpace($prefix)) { $diff = $diff -replace ([regex]::Escape("$prefix/")), '' }
    [System.IO.File]::WriteAllText((Join-Path $reviewDir 'changes.diff'), $diff)
    $namesArgs = @('diff', '--name-only', $BaselineRef, $reviewSource, '--') + @($diffPathspec)
    $namesRaw = Invoke-WorktreeReviewerGitCapture -RepoRoot $gitRoot -Arguments $namesArgs
    $changed = @((($namesRaw -replace "`r`n", "`n") -split "`n") | Where-Object { $_ })
    $designOriginRoots = @($resolved); if (-not [string]::IsNullOrWhiteSpace($gitRoot)) { $designOriginRoots += $gitRoot }
    foreach ($d in @($DesignContextFiles)) {
        $full = if ([System.IO.Path]::IsPathRooted($d)) { $d } else { Join-Path $resolved $d }
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
        # Formal contracts go under design/contracts/ (grouped + obviously the AUTHORITY); prose goes flat in design/.
        $destDir = if ($d -match '(^|/)contracts/') { Join-Path $reviewDir 'design/contracts' } else { Join-Path $reviewDir 'design' }
        if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        # FR-009: relativize origin-absolute paths (e.g. file:/// spec/design URLs) in the design
        # snapshot the reviewer sees - the design content stays authoritative, the origin does not leak.
        # Composes with the Devin design-ref plumbing: the supplied ref is relativized, never dropped.
        $scrubbed = ConvertTo-ContinuousCoReviewOriginRelativized -Content (Get-Content -LiteralPath $full -Raw -Encoding UTF8) -OriginRoots $designOriginRoots
        [System.IO.File]::WriteAllText((Join-Path $destDir (Split-Path $full -Leaf)), $scrubbed)
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

function Get-ContinuousCoReviewWorktreeSourceHashes {
    # FR-010 mutation-evidence helper: a map { relative-path -> sha256 } of the worktree's existing
    # files. Comparing this before vs after a verification run makes any MUTATION of an existing file
    # visible - new files (legitimate test output) do not perturb existing entries, so the delta
    # isolates the read-only violation.
    # SCOPE (finding 90173dc6-1): the REVIEWER-AUTHORITY inputs under .review/ (changes.diff, design/,
    # contracts, process context) ARE hashed - a verification command that rewrites the very authority
    # it verifies against can manufacture a pass, so such a mutation MUST be reported. Excluded are
    # ONLY .git/ and the narrow engine-owned output area .review/verification/ (where the orchestrator
    # itself records results - never a command's legitimate write target, never source).
    param([Parameter(Mandatory)][string]$WorktreePath)
    $map = @{}
    $rootFull = (Resolve-Path -LiteralPath $WorktreePath).Path.TrimEnd([char]'\', [char]'/')
    foreach ($f in @(Get-ChildItem -LiteralPath $WorktreePath -Recurse -File -Force -ErrorAction SilentlyContinue)) {
        $rel = [System.IO.Path]::GetRelativePath($rootFull, $f.FullName).Replace('\', '/')
        if ($rel -like '.git/*' -or $rel -like '.review/verification/*') { continue }
        try { $map[$rel] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash } catch { $map[$rel] = 'unreadable' }
    }
    return $map
}

function Copy-ContinuousCoReviewVerificationSandbox {
    # T015 (findings 97a93603-2 / 4b124d0e-1): a DISPOSABLE copy of the reviewer worktree in which the
    # declared verification runs, so an output-writing or read-only verification does its work WITHOUT
    # perturbing the tree the reviewer is handed. This is NOT a security boundary - a command has ambient
    # filesystem authority and can still reach the reviewer tree by absolute/.. path; the ORCHESTRATOR
    # therefore hashes the certified reviewer tree before/after and REFUSES the run if it changed.
    # ROBUST against concurrent reviewer-host churn (finding c9abe16d, where Copy-Item -Recurse died when
    # a transient .antigravitycli/*.json vanished mid-copy): volatile host-runtime dirs and .git are
    # skipped, and a file that vanishes mid-copy is tolerated - the stable SOURCE the verification needs
    # is what matters, not another run's ephemeral host state.
    param([Parameter(Mandatory)][string]$SourceWorktree, [Parameter(Mandatory)][string]$DestRoot)
    $srcRoot = (Resolve-Path -LiteralPath $SourceWorktree).Path.TrimEnd([char]'\', [char]'/')
    [void][System.IO.Directory]::CreateDirectory($DestRoot)
    $skipTop = @('.git', '.antigravitycli', '.codex', '.claude', '.cursor', '.gemini')
    foreach ($item in @(Get-ChildItem -LiteralPath $srcRoot -Recurse -Force -ErrorAction SilentlyContinue)) {
        $rel = [System.IO.Path]::GetRelativePath($srcRoot, $item.FullName)
        $top = ($rel -replace '[\\/].*$', '')
        if ($skipTop -contains $top) { continue }
        $dest = Join-Path $DestRoot $rel
        try {
            if ($item.PSIsContainer) { [void][System.IO.Directory]::CreateDirectory($dest) }
            else {
                $destDir = [System.IO.Path]::GetDirectoryName($dest)
                if (-not [string]::IsNullOrEmpty($destDir)) { [void][System.IO.Directory]::CreateDirectory($destDir) }
                Copy-Item -LiteralPath $item.FullName -Destination $dest -Force -ErrorAction Stop
            }
        }
        catch { $null = $_ }   # a file vanished mid-copy (concurrent host churn) - tolerated
    }
    return $DestRoot
}

function Invoke-ContinuousCoReviewBoundedVerification {
    # FR-010 (203 W3) + the maintainer's REQUIRED bounded in-worktree verification: run the DECLARED
    # verification commands INSIDE the confined worktree, each with (1) a TIMEOUT and process
    # CONTAINMENT (the whole child process tree is killed on timeout), (2) CAPPED output capture, and
    # (3) PRE/POST MUTATION EVIDENCE (existing-file hashes before vs after, so a verification that
    # mutated the read-only source is recorded). It runs ONLY the declared command set - never an
    # unrestricted whole-repository suite. Returns one record per command.
    param(
        [Parameter(Mandatory)][string]$WorktreePath,
        [string[]]$DeclaredCommands = @(),
        # Glob patterns for LEGITIMATE output paths (e.g. '*.log', 'coverage/*'). A NEW file is exempt
        # from the mutation record ONLY if it matches one of these; every other add/delete/modify of
        # the read-only source is a mutation.
        [string[]]$AllowedOutputPaths = @(),
        [int]$TimeoutSeconds = 120,
        [int]$MaxOutputBytes = 65536
    )
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($cmd in @($DeclaredCommands)) {
        if ([string]::IsNullOrWhiteSpace($cmd)) { continue }
        $preHashes = Get-ContinuousCoReviewWorktreeSourceHashes -WorktreePath $WorktreePath
        # Process containment via ProcessStartInfo (ArgumentList passes each arg ATOMICALLY - Start-Process
        # would re-quote and split a command containing spaces/quotes). Both pipes are PUMPED on this
        # thread into FIXED byte buffers capped at MaxOutputBytes each (findings bfc7b5c5-2 + 06cb3c64-1):
        # overflow past the cap is READ AND DISCARDED - the child is always drained so it can never block
        # on a full pipe, reviewer memory stays bounded at ~2x cap + the read buffers, and NOTHING is
        # written to disk (no temp-storage exhaustion vector). Kill($true) reaps the ENTIRE tree on
        # deadline; after a kill a short grace window collects the EOFs the kill releases.
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = (Get-Process -Id $PID).Path
        foreach ($a in @('-NoProfile', '-NonInteractive', '-Command', $cmd)) { [void]$psi.ArgumentList.Add($a) }
        $psi.WorkingDirectory = $WorktreePath
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $proc = [System.Diagnostics.Process]::Start($psi)
        $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        $timedOut = $false
        $killIssued = $false
        $pumps = @(
            [pscustomobject]@{ reader = $proc.StandardOutput.BaseStream; buf = (New-Object byte[] 81920); cap = (New-Object byte[] $MaxOutputBytes); task = $null; done = $false; written = 0; overflow = $false },
            [pscustomobject]@{ reader = $proc.StandardError.BaseStream; buf = (New-Object byte[] 81920); cap = (New-Object byte[] $MaxOutputBytes); task = $null; done = $false; written = 0; overflow = $false }
        )
        foreach ($p in $pumps) { $p.task = $p.reader.ReadAsync($p.buf, 0, $p.buf.Length) }
        while ($true) {
            $active = @($pumps | Where-Object { -not $_.done })
            if ($active.Count -eq 0) { break }
            $now = [DateTime]::UtcNow
            if ($now -ge $deadline) {
                if ($killIssued) { break }   # post-kill grace expired; abandon the remaining reads
                $timedOut = $true
                $killIssued = $true
                try { $proc.Kill($true) } catch { $null = $_ }
                $deadline = $now.AddSeconds(3)
                continue
            }
            $taskArr = [System.Threading.Tasks.Task[]]@($active | ForEach-Object { $_.task })
            $idx = [System.Threading.Tasks.Task]::WaitAny($taskArr, [int][Math]::Max(50, [Math]::Min(500, ($deadline - $now).TotalMilliseconds)))
            if ($idx -lt 0) { continue }
            $p = $active[$idx]
            $n = 0
            try { $n = [int]$p.task.Result } catch { $p.done = $true; continue }   # faulted read (pipe closed by the kill) = EOF
            if ($n -le 0) { $p.done = $true; continue }
            $room = $MaxOutputBytes - $p.written
            if ($room -gt 0) {
                $take = [int][Math]::Min($n, $room)
                [Array]::Copy($p.buf, 0, $p.cap, $p.written, $take)
                $p.written += $take
                if ($take -lt $n) { $p.overflow = $true }
            }
            else { $p.overflow = $true }
            $p.task = $p.reader.ReadAsync($p.buf, 0, $p.buf.Length)
        }
        if (-not $timedOut) {
            # Streams hit EOF; the child should be exiting - a bounded wait, else it is a hang after EOF.
            if (-not $proc.WaitForExit(5000)) { $timedOut = $true; try { $proc.Kill($true) } catch { $null = $_ }; [void]$proc.WaitForExit() }
        }
        else { try { $null = $proc.WaitForExit(2000) } catch { $null = $_ } }
        $exit = if ($timedOut) { $null } else { [int]$proc.ExitCode }
        # Byte-bounded record assembly: stdout first, then stderr into the remaining TOTAL room. The pump
        # already bounded each stream at MaxOutputBytes, so the record can never exceed the cap; a
        # truncated trailing multibyte char degrades to U+FFFD - acceptable for a bounded capture.
        $truncated = ([bool]$pumps[0].overflow -or [bool]$pumps[1].overflow)
        $outBuilder = New-Object System.Text.StringBuilder
        $roomTotal = $MaxOutputBytes
        foreach ($p in $pumps) {
            if ($p.written -le 0) { continue }
            if ($roomTotal -le 0) { $truncated = $true; continue }
            $take = [int][Math]::Min($p.written, $roomTotal)
            if ($take -lt $p.written) { $truncated = $true }
            [void]$outBuilder.Append([System.Text.Encoding]::UTF8.GetString($p.cap, 0, $take))
            $roomTotal -= $take
        }
        $out = $outBuilder.ToString()
        $postHashes = Get-ContinuousCoReviewWorktreeSourceHashes -WorktreePath $WorktreePath
        # Mutation evidence: the reviewer is READ-ONLY, so ADDED, DELETED, and MODIFIED files ALL count
        # as mutations. A NEW file is exempt ONLY when it matches the explicit output-path allowlist -
        # otherwise a reviewer could plant new source that steers the very verification it then runs.
        $mutatedPaths = New-Object System.Collections.Generic.List[string]
        foreach ($k in $preHashes.Keys) {
            if (-not $postHashes.ContainsKey($k) -or $postHashes[$k] -ne $preHashes[$k]) { [void]$mutatedPaths.Add($k) }   # deleted or modified
        }
        foreach ($k in $postHashes.Keys) {
            if ($preHashes.ContainsKey($k)) { continue }
            $allowed = $false
            foreach ($pat in @($AllowedOutputPaths)) { if (-not [string]::IsNullOrWhiteSpace($pat) -and ($k -like $pat)) { $allowed = $true; break } }
            if (-not $allowed) { [void]$mutatedPaths.Add($k) }   # unexplained new file
        }
        $results.Add([pscustomobject]@{
                command               = $cmd
                exit_code             = $exit
                timed_out             = $timedOut
                output                = [string]$out
                output_truncated      = $truncated
                # Bytes actually RETAINED per stream (each pump-bounded at MaxOutputBytes): the
                # observable proof that a sustained flood never lands in memory or on disk beyond the cap.
                captured_stdout_bytes = [int]$pumps[0].written
                captured_stderr_bytes = [int]$pumps[1].written
                source_mutated        = ($mutatedPaths.Count -gt 0)
                mutated_paths         = $mutatedPaths.ToArray()
            }) | Out-Null
    }
    return $results.ToArray()
}

function Get-ContinuousCoReviewSlimPrompt {
    # The SLIM prompt (a few KB) — the reviewer reads the diff + design + browses/runs the project itself.
    # Round-aware: round 1 reviews; later rounds verify the prior findings are resolved; at the FINAL round the
    # reviewer escalates (the counter is a safety ceiling, the reviewer's judgement is the brains).
    param([Parameter(Mandatory)][string]$RunId, [int]$RoundNumber = 1, [int]$MaxRounds = 2, [string]$PriorFindings, [string]$HumanScope, [switch]$DesignContextEmpty, [switch]$ImplementerEvidencePresent, [switch]$VerificationResultsPresent)
    # f1 (codex 2026-07-08): when NO design context resolved, say so HONESTLY - the reviewer must not
    # silently skip design conformance; it reviews code/process and RAISES the gap as a finding.
    $designContextBlock = if ($DesignContextEmpty) {
        "`nNOTE - NO DESIGN CONTEXT RESOLVED: .review/design/ is EMPTY for this run (no spec, design-analysis, or contracts could be resolved from the project). Design-conformance CANNOT be validated this round: review the code + process axes only, RAISE the missing design context itself as a finding (severity per impact), and treat this review as PARTIAL (the run is labelled accordingly).`n"
    }
    else { '' }
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
    # T111 (DEC-197-I010-004): digest-matched implementer-recorded evidence substitutes for broad re-runs.
    # The block renders ONLY when the orchestrator actually injected the file (exact digest match with the
    # tree under review), so the reviewer is never told to trust a file that is absent or stale.
    # HONESTY (codex finding f1, run 20260708T235143936 / 203-W8): the recorder persists CALLER-SUPPLIED
    # numbers - it does not independently observe the run - so the prompt says IMPLEMENTER-RECORDED (never
    # "machine-observed") and arms the spot-check as forgery detection. The runner-observed wrapper is the
    # 203-W8 fast-follow. Never-false-green survives: prose claims still have zero standing.
    $evidenceBlock = if ($ImplementerEvidencePresent) {
        "`nIMPLEMENTER TEST EVIDENCE (implementer-recorded, digest-matched): .review/implementer-evidence.json was recorded by the implementer's tooling and injected ONLY because its reviewed-state digest matches EXACTLY the tree you are reviewing (any later edit changes the digest and orphans the record). It is IMPLEMENTER-SUPPLIED, not independently observed: treat the recorded suites (names, pass/fail counts, exit codes, durations) as strong prior evidence for budget purposes - do NOT re-run whole covered suites by default - but SPOT-CHECK a small targeted sample (a suite subset or a handful of named tests) where your findings depend on that evidence. ANY mismatch between a spot-check and the record is itself a BLOCKING honesty finding. Hand-written claims in review.md, quality notes, or commit messages remain claims with zero evidence standing, and the falsification stance applies to them unchanged.`n"
    }
    else { '' }
    # T015 (FR-010): the orchestrator ran the DECLARED verification commands through the bounded wrapper and
    # injected the HOST-OBSERVED results. Gated on the same flag the orchestrator sets when it actually wrote
    # the file, so the reviewer is never pointed at an absent record. Unlike implementer evidence, THIS is
    # independently observed by the engine (timeout + process-tree kill + byte-capped output + pre/post
    # mutation hash), so it needs no forgery spot-check - a recorded mutation or non-zero exit IS a finding.
    $verificationBlock = if ($VerificationResultsPresent) {
        "`nBOUNDED VERIFICATION RESULTS (orchestrator-observed, host-run): .review/verification/results.json holds the DECLARED verification commands the engine ran FOR you before you were spawned - each with a per-command timeout + full process-tree kill on expiry, a byte-capped captured output (output_truncated flags the cap), and a pre/post worktree hash (source_mutated / mutated_paths). These are INDEPENDENTLY host-observed, not implementer-supplied: treat a recorded clean pass as strong evidence and do NOT re-run that same command by default. A record whose source_mutated is true, or whose exit_code is non-zero where a pass was claimed, is itself a finding to report.`n"
    }
    else { '' }
    # RESOLVED-BY-DEFERRAL (the missing half of the T106 human-close, found by DEC-197-I010-008's own
    # first exercise: a round-4 reviewer READ the deferral decision and still escalated because this
    # teaching had no deferral vocabulary - and a full+independent block is not overridable by design
    # (D5), so human-deferred findings could NEVER converge). A finding covered by a RECORDED human
    # deferral is resolved for round purposes - the record must be verifiable IN THE TREE, never a
    # prose claim (never-false-green holds: the reviewer verifies the record, not testimony).
    $roundBlock = if ($RoundNumber -gt 1 -and -not [string]::IsNullOrWhiteSpace($PriorFindings)) {
        "This is review round $RoundNumber of at most $MaxRounds. The PRIOR round produced these findings - verify each is RESOLVED in this change (a prior blocking finding still present is a failed fix):`n$PriorFindings`n`nRESOLVED-BY-DEFERRAL: a prior finding is ALSO resolved when a RECORDED HUMAN DEFERRAL covers it - a decision record in a WORKTREE-VISIBLE artifact (an iteration drift-log event, a specs decision artifact, or a proposal work item) that (a) names or unmistakably describes the finding, (b) records the approving human, and (c) states where the work is carried. Governance-machinery paths (.squad/, .specrew/, .specify/) are STRIPPED from your worktree - a record only there is UNVERIFIABLE-HERE, and the implementer must mirror it into a worktree-visible artifact. VERIFY the record exists in your worktree and covers the finding - a deferral CLAIM without a verifiable worktree-visible record is itself a blocking finding. For a deferral-covered finding: mark it resolved, cite the decision id in your findings notes, and do NOT re-raise or escalate it.`n`nIf this is the FINAL round ($RoundNumber of $MaxRounds) and a prior BLOCKING finding is STILL unresolved AND not covered by a verified recorded deferral, return ONE finding with kind 'escalation' + severity 'blocking' calling for a HUMAN decision (stop the autonomous review->fix loop) - do not merely repeat the unresolved finding."
    }
    else {
        "This is review round $RoundNumber of at most $MaxRounds (initial review of this change)."
    }
    return @"
You are the Specrew continuous co-reviewer (a fresh-context, design- AND process-conformance reviewer).
$scopeBlock$designContextBlock$evidenceBlock$verificationBlock
Your current working directory IS the reviewed project. You are TRUSTED and may READ any file and RUN
verification you need — but you are READ-ONLY on the source: do NOT modify, fix, or patch any file. Your job is
to find issues, not fix them.

WORKTREE CONFINEMENT: this working directory is a DISPOSABLE, ISOLATED SNAPSHOT — NOT the real project. It is
materialized OUTSIDE the origin repository (an upward walk does not resolve the origin), the governance machinery
(.squad/, .specrew/, .specify/) is stripped, and origin-absolute paths are relativized to <project>. This isolation
is a snapshot with origin references REMOVED — not an OS-enforced sandbox — so confinement is a BINDING RULE of your
engagement, and a violation is treated as a blocking finding when detected. Stay INSIDE it: do not try to locate,
read, or reach the origin project, and do not depend on absolute paths. Anything intentionally absent here — the
stripped machinery, a relativized path — is EXPECTED; treat a reference to it as unverifiable-here, never as a defect.

BOUNDED VERIFICATION: prefer the orchestrator-observed verification results above (when present) over re-running
their commands; when NO results file is present, the engine declared and ran NOTHING — your own targeted runs are
then the only runtime evidence this round. When you DO run tests/build yourself to verify a claim, run ONLY the
DECLARED verification commands the change says validate it — never an unrestricted whole-repository sweep — and
keep each run SHORT and targeted. Your own runs are bounded by the WORKTREE CONFINEMENT contract above (an isolated
snapshot, not an OS-enforced sandbox): honoring it is part of the review itself. You are READ-ONLY on the source: a
command that edits, adds, or deletes files is a mutation you have caused — do not run it, and report a claimed
verification that requires one as a finding.

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

RECORDED HUMAN DEFERRALS (applies on EVERY round): before raising a blocking finding, check whether a RECORDED
human deferral in the tree already covers it - a decision record in a WORKTREE-VISIBLE artifact (an iteration
drift-log event, a specs decision artifact, or a proposal work item) that names or unmistakably describes the
issue, records the approving human, and states where the work is carried. NOTE: governance-machinery paths
(.squad/, .specrew/, .specify/) are intentionally STRIPPED from your worktree, so a record living ONLY in
.squad/decisions.md is invisible to you - treat references to it as UNVERIFIABLE-HERE (not false) and look for
the mirror record in the drift-log/specs/proposals; the implementer is required to mirror deferrals into a
worktree-visible artifact. A deferral-covered issue is reported (if at all) as ADVISORY with the decision id
cited, never blocking. A deferral CLAIM without a verifiable worktree-visible record is itself a blocking
finding. A prior-round item of kind 'escalation' is itself RESOLVED once every finding underneath it is fixed or
deferral-covered - do not copy an escalation forward.

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
        $harvestIdx = 0
        foreach ($line in @(Get-Content -LiteralPath $jsonlPath -ErrorAction SilentlyContinue)) {
            $t = ([string]$line).Trim()
            if ([string]::IsNullOrWhiteSpace($t)) { continue }
            try {
                $obj = $t | ConvertFrom-Json -ErrorAction Stop
                if ($null -eq $obj -or $null -eq $obj.PSObject.Properties['comment'] -or [string]::IsNullOrWhiteSpace([string]$obj.comment)) { continue }
                $harvestIdx++
                # f2 (codex 2026-07-08): NORMALIZE every harvested line into the FindingsResult ITEM
                # schema - a cut-short reviewer's partial line keeps its content but gets schema-valid
                # defaults for whatever is missing/invalid, and is never embedded raw. source_run_id is
                # FORCED to this run (a harvested line cannot claim another run's identity), and the
                # disposition/resolution are forced open/unresolved (an in-flight finding is never
                # pre-resolved by the line that reported it).
                $sev = if ($null -ne $obj.PSObject.Properties['severity'] -and ([string]$obj.severity -in @('blocking', 'advisory', 'nit'))) { [string]$obj.severity } else { 'advisory' }
                $kind = if ($null -ne $obj.PSObject.Properties['kind'] -and -not [string]::IsNullOrWhiteSpace([string]$obj.kind)) { [string]$obj.kind } else { 'partial-harvest' }
                $designRef = if ($null -ne $obj.PSObject.Properties['design_reference'] -and -not [string]::IsNullOrWhiteSpace([string]$obj.design_reference)) { [string]$obj.design_reference } else { 'partial-review-salvage' }
                $findingId = if ($null -ne $obj.PSObject.Properties['finding_id'] -and -not [string]::IsNullOrWhiteSpace([string]$obj.finding_id)) { [string]$obj.finding_id } else { ('partial-{0}' -f $harvestIdx) }
                $loc = [pscustomobject]@{ line_start = $null; line_end = $null }
                if ($null -ne $obj.PSObject.Properties['location'] -and $null -ne $obj.location) {
                    $p = if ($null -ne $obj.location.PSObject.Properties['path']) { [string]$obj.location.path } else { '' }
                    $ls = $null; $le = $null
                    if ($null -ne $obj.location.PSObject.Properties['line_start'] -and $null -ne $obj.location.line_start) { try { $ls = [int]$obj.location.line_start } catch { $ls = $null } }
                    if ($null -ne $obj.location.PSObject.Properties['line_end'] -and $null -ne $obj.location.line_end) { try { $le = [int]$obj.location.line_end } catch { $le = $null } }
                    # f2 residual (codex verification round 2026-07-08): the contract types line numbers
                    # as integer minimum 1 - a 0/negative harvested line is INVALID, not "line zero".
                    if ($null -ne $ls -and $ls -lt 1) { $ls = $null }
                    if ($null -ne $le -and $le -lt 1) { $le = $null }
                    if ($null -ne $ls -and $null -ne $le -and $le -lt $ls) { $le = $ls }
                    $loc = if (-not [string]::IsNullOrWhiteSpace($p)) { [pscustomobject]@{ path = $p; line_start = $ls; line_end = $le } } else { [pscustomobject]@{ line_start = $ls; line_end = $le } }
                }
                $findings.Add([pscustomobject]@{
                        finding_id       = $findingId
                        source_run_id    = $RunId
                        location         = $loc
                        severity         = $sev
                        kind             = $kind
                        design_reference = $designRef
                        comment          = [string]$obj.comment
                        disposition      = 'open'
                        resolution       = [pscustomobject]@{ state = 'unresolved'; fix_evidence_ref = $null; rationale = $null }
                    })
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
        [Parameter(Mandatory)][int]$MaxRounds,
        [int]$ResolvedAgainstDiskCount = 0
    )
    # T020 (FR-018/FR-019): the halt message is CONSUMER-LEGIBLE - plain words, the review-spend
    # guard explained, N-of-M rounds, the resolved-vs-open state from the disposition trail, and the
    # exact command that grants more review budget. It carries ZERO internal identifiers (no rule,
    # feature, proposal, or task codenames; no engine field names) so a downstream human who never
    # saw this project's internals can act on it. The maintainer amendment keeps every round counting
    # (the guard is a spend allowance), and the naming of the command is transparency - a person may
    # run it, or approve the agent running it.
    $resolvedNote = if ($ResolvedAgainstDiskCount -gt 0) {
        (" (Along the way {0} earlier blocking item(s) were confirmed fixed and cleared, so those are not what stopped it.) " -f $ResolvedAgainstDiskCount)
    }
    else { ' ' }
    $comment = (
        ("This automated code review reached its spending limit for this change: it has run {0} review rounds (the limit is {1}) and a blocking item is still open." -f $Round, $MaxRounds) +
        ' The limit is a budget guard - it caps how much AI-usage a single review can spend before a person decides whether to keep going - so the review PAUSED here instead of continuing to spend.' +
        $resolvedNote +
        'This is not a clean pass: the latest change was not reviewed, and treating it as "no findings" would be wrong.' +
        ' To continue, a person can approve more review budget for this change (run `specrew review --remediate more-time`, or approve the assistant doing it), or fix the open blocking item so the next review passes on its own.'
    )
    $result = [pscustomobject]@{
        schema_version = '1.0'
        run_id         = $RunId
        status         = 'findings'
        findings       = @(
            [pscustomobject]@{
                finding_id       = 'review-spending-limit-reached'
                source_run_id    = $RunId
                location         = [pscustomobject]@{ path = '.review/changes.diff' }
                severity         = 'blocking'
                kind             = 'escalation'
                design_reference = 'review spending limit reached'
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
        # The catalog ANSWERED - this host simply has no agentic vector defined (or no row). Say
        # THAT: the old text blamed an "unreachable catalog" and sent the human debugging the module
        # deploy instead of the row (wrong-diagnosis message, F-198 FR-018 class - cost a real
        # debugging detour on 2026-07-10, run c0a4479b).
        throw "co-review: reviewer host '$HostName' has no agentic invocation defined in its reviewer-host-catalog.ps1 row (the host may be probe-validated only). Complete the row's agentic_args, or choose a host whose row defines one."
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
        [string]$HumanScope,
        [switch]$DesignContextEmpty,
        [switch]$ImplementerEvidencePresent,
        [switch]$VerificationResultsPresent
    )
    $prompt = Get-ContinuousCoReviewSlimPrompt -RunId $RunId -RoundNumber $RoundNumber -MaxRounds $MaxRounds -PriorFindings $PriorFindings -HumanScope $HumanScope -DesignContextEmpty:$DesignContextEmpty -ImplementerEvidencePresent:$ImplementerEvidencePresent -VerificationResultsPresent:$VerificationResultsPresent
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
