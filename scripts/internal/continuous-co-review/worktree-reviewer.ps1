$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T091/FR-037 + T100/FR-039: ONE process manager for the reviewer spawn - the same OS-native containment
# primitives the isolated-task supervisor uses (process-tree.ps1: Job Object / setsid+PGID / snapshot-walk
# fallback). Loaded here; REQUIRED at spawn time (Invoke-ContinuousCoReviewAgentInWorktree refuses to spawn
# an uncontainable reviewer - the divergent $proc.Kill fallback is deleted per design N1).
$specrewProcessTreeHelper = Join-Path (Split-Path -Parent $PSScriptRoot) 'agent-tasks/process-tree.ps1'
if (Test-Path -LiteralPath $specrewProcessTreeHelper -PathType Leaf) { . $specrewProcessTreeHelper }
if (-not (Get-Command -Name 'Resolve-ContinuousCoReviewDesignContextSelection' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-design-context.ps1') }

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
    #       across every host WITHOUT enumerating them. Ordinary user config stays reviewable; the one exception is
    #       `.claude/settings.local.json`, the canonical machine-local/per-session hook config that init untracks and
    #       ignores. Returns project-relative paths. -RepoRoot enables (b); omit for the core-only list.
    param([string]$RepoRoot)
    $core = @(
        '.specrew', '.specify', '.squad', '.agents', '.git', '.claude/settings.local.json',
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
        # A review bundle can contain an origin captured on another OS. Do not ask the current platform to
        # resolve a foreign Windows absolute root: on Linux GetFullPath('C:\Dev\repo') prefixes the current
        # Unix directory and prevents the real origin from being scrubbed.
        $foreignWindowsAbsolute = $root -match '^[A-Za-z]:[\\/]' -or $root -match '^\\\\'
        $full = $(if ($foreignWindowsAbsolute) { $root } else { [System.IO.Path]::GetFullPath($root) }).TrimEnd([char]'\', [char]'/')
        $fwd = $full.Replace('\', '/')
        $bwd = $full.Replace('/', '\')
        # file:/// URL form first (most specific), then the JSON-ESCAPED backslash form (review finding f5,
        # run 20260714T190233598: a serialized JSON evidence copy carries 'C:\\Dev\\...' - the doubled form
        # must relativize too or the origin leaks through every JSON artifact), then the bare absolute path
        # in either separator form.
        $out = [regex]::Replace($out, ('file:///' + [regex]::Escape($fwd)), 'file:///<project>', $ci)
        $out = [regex]::Replace($out, [regex]::Escape($bwd.Replace('\', '\\')), '<project>', $ci)
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

# ============================ T016 — containment-violation detector (FR-011 / SC-003) ============================
# MONITORED confinement, NOT OS-enforced isolation: the reviewer is trusted-but-confined; its process tree must
# stay under the disposable worktree (T013 materialized it OUTSIDE origin) and never reach back to origin. This
# detector RIDES the T100 process registry (Get-SpecrewProcessTreeDescendants) to SAMPLE the tree's paths and,
# on observed origin access, records a LOUD, ORIGIN-SIDE `containment-violated` finding. It is strictly
# READ-ONLY: it samples nothing sensitive into a reviewer-visible artifact and NEVER mutates or kills the
# reviewer mid-flight (the only kill remains the end-of-run Stop-SpecrewProcessContainment). The record carries
# ONLY bounded, redacted path/process metadata - never the raw command line, prompt, env, or credentials
# (maintainer 2026-07-12).

function Select-ContinuousCoReviewAbsolutePathTokens {
    # Filter an ALREADY-SPLIT argv array to its ABSOLUTE path tokens (drive-rooted, UNC, or POSIX-rooted). argv is
    # STRUCTURED - one full argument per element - so a quoted path containing spaces is a single element and is
    # NEVER re-split. Only absolute tokens are returned: a relative token would need the process cwd to resolve
    # (Windows has no cheap cwd), and an absolute origin path is the natural SC-003 seed. Residual wrapping quotes
    # are trimmed defensively. The command line is NEVER persisted; the checker re-confirms under-origin before it
    # records anything.
    param([AllowNull()][string[]]$Argv)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($raw in @($Argv)) {
        if ($null -eq $raw) { continue }
        $t = ([string]$raw).Trim().Trim('"', "'")
        if ([string]::IsNullOrWhiteSpace($t)) { continue }
        if (($t -match '^[A-Za-z]:[\\/]') -or $t.StartsWith('\\') -or $t.StartsWith('/')) { [void]$out.Add($t) }
    }
    return $out.ToArray()
}

function Resolve-ContinuousCoReviewRelativeOriginTokens {
    # A descendant launched from the disposable worktree (its cwd) can reach an origin sibling via a RELATIVE
    # traversal arg (e.g. `git show ..\..\<origin>\secret`) - an ABSOLUTE-only token filter drops it, so the
    # containment run could complete without a violation (codex run 20260712T195149281). Resolve each RELATIVE
    # path-like argv token against the process cwd (POSIX `/proc/<pid>/cwd`; Windows: the known worktree the reviewer
    # was launched in) and return the NORMALIZED ABSOLUTE path - the checker then confirms under-origin, so only a
    # traversal that actually ESCAPES the worktree up to origin flags (a relative path that stays under the worktree
    # normalizes to a non-origin path and is harmless). A token is "path-like" if it carries a path separator or a
    # `..`/`.` traversal segment; a bare flag or sub-command has neither and is skipped. Absolute tokens are handled
    # by Select-ContinuousCoReviewAbsolutePathTokens and skipped here. Fail-closed: no cwd → nothing resolved.
    param([AllowNull()][string[]]$Argv, [AllowEmptyString()][string]$Cwd)
    $out = [System.Collections.Generic.List[string]]::new()
    if ([string]::IsNullOrWhiteSpace($Cwd)) { return $out.ToArray() }
    foreach ($raw in @($Argv)) {
        if ($null -eq $raw) { continue }
        $t = ([string]$raw).Trim().Trim('"', "'")
        if ([string]::IsNullOrWhiteSpace($t)) { continue }
        if (($t -match '^[A-Za-z]:[\\/]') -or $t.StartsWith('\\') -or $t.StartsWith('/')) { continue }   # absolute: handled elsewhere
        $looksLikePath = ($t -match '[\\/]') -or ($t -match '(^|[\\/])\.\.($|[\\/])') -or ($t -eq '..')
        if (-not $looksLikePath) { continue }
        $resolved = try { [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($Cwd, $t)) } catch { $null }
        if (-not [string]::IsNullOrWhiteSpace($resolved)) { [void]$out.Add($resolved) }
    }
    return $out.ToArray()
}

function Expand-ContinuousCoReviewArgvPathCandidates {
    # Best-effort expansion of argv tokens into candidate PATH strings. A path can hide in an OPTION-ATTACHED value
    # (`--git-dir=C:\origin\.git`, `--git-dir=..\origin\.git`): the option prefix makes the whole token neither
    # absolute nor a resolvable relative path, so it evades both filters (codex run 20260712T171701083). For each token
    # we therefore ALSO yield the substring after the FIRST `=`. This is explicitly BEST-EFFORT and NOT complete -
    # response files (`@argfile`), env-var expansion, and other path-bearing forms remain uncovered - which is exactly
    # why an argv match is a DIAGNOSTIC WARNING, never a hard review-fail (FR-011 amended, maintainer review 2026-07-12).
    param([AllowNull()][string[]]$Argv)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($raw in @($Argv)) {
        if ($null -eq $raw) { continue }
        $t = [string]$raw
        [void]$out.Add($t)
        $eq = $t.IndexOf('=')
        if ($eq -ge 0 -and $eq -lt ($t.Length - 1)) { [void]$out.Add($t.Substring($eq + 1)) }
    }
    return $out.ToArray()
}

function Get-ContinuousCoReviewCommandLineArgv {
    # Parse a raw command-line STRING into argv using PLATFORM-APPROPRIATE quoting (containment-detection-bypass fix,
    # codex run 20260712T192442732): a QUOTED argument containing spaces (e.g. "C:\Origin Project\secret.md") stays
    # ONE token instead of being whitespace-split into fragments that resolve nowhere. Windows uses the OS parser
    # CommandLineToArgvW - it also honours \" escapes, so the reviewer's OWN quoted prompt collapses to a single
    # non-path arg (which is WHY a prompt that merely NAMES origin is never mistaken for access - no token-subtraction
    # workaround needed). Elsewhere this string entry point is a FALLBACK only (the POSIX sampler reads STRUCTURED
    # argv from /proc/<pid>/cmdline directly); a quote-aware scan keeps a quoted-with-spaces token intact there.
    param([AllowEmptyString()][string]$CommandLine)
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return @() }
    if ($IsWindows) {
        if (-not ([System.Management.Automation.PSTypeName]'Specrew.CoReview.NativeArgv').Type) {
            try {
                Add-Type -Namespace 'Specrew.CoReview' -Name 'NativeArgv' -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("shell32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
public static extern System.IntPtr CommandLineToArgvW(string lpCmdLine, out int pNumArgs);
[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern System.IntPtr LocalFree(System.IntPtr hMem);
'@
            }
            catch { $null = $_ }
        }
        if (([System.Management.Automation.PSTypeName]'Specrew.CoReview.NativeArgv').Type) {
            $ptr = [System.IntPtr]::Zero
            try {
                $count = 0
                $ptr = [Specrew.CoReview.NativeArgv]::CommandLineToArgvW($CommandLine, [ref]$count)
                if ($ptr -ne [System.IntPtr]::Zero -and $count -gt 0) {
                    $argv = [System.Collections.Generic.List[string]]::new()
                    for ($i = 0; $i -lt $count; $i++) {
                        $strPtr = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($ptr, $i * [System.IntPtr]::Size)
                        $s = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($strPtr)
                        if ($null -ne $s) { [void]$argv.Add($s) }
                    }
                    return $argv.ToArray()
                }
            }
            catch { $null = $_ }
            finally { if ($ptr -ne [System.IntPtr]::Zero) { [void][Specrew.CoReview.NativeArgv]::LocalFree($ptr) } }
        }
    }
    # Portable quote-aware fallback: a run of (double-quoted segment | non-whitespace char) is ONE token.
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($CommandLine, '(?:"[^"]*"|\S)+')) { [void]$out.Add(($m.Value -replace '"', '')) }
    return $out.ToArray()
}

function Get-ContinuousCoReviewPathLikeTokens {
    # Extract ABSOLUTE path tokens from a raw command line, QUOTE-AWARE. The line is parsed into STRUCTURED argv first
    # (Get-ContinuousCoReviewCommandLineArgv) and each argument tested for an absolute path - so a quoted
    # "C:\Origin Project\x" is ONE token, not two fragments (the whitespace-split BYPASS fix), AND the reviewer's
    # PROMPT - passed as a SINGLE positional arg - is one non-path token, so a prompt that merely NAMES origin paths
    # is never mistaken for origin ACCESS (the DRIFT-198-I003-004 false positive; the earlier token-subtraction
    # workaround is no longer needed). The command line itself is NEVER persisted; only a matched token can become a
    # record's `path`, and the checker still confirms it resolves under origin before recording anything.
    param([AllowEmptyString()][string]$CommandLine)
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return @() }
    return Select-ContinuousCoReviewAbsolutePathTokens -Argv (Get-ContinuousCoReviewCommandLineArgv -CommandLine $CommandLine)
}

function Get-ContinuousCoReviewContainmentSamples {
    # Sample the reviewer PROCESS TREE (root + descendants) for the path observations the checker judges. Rides
    # Get-SpecrewProcessTreeDescendants (the T100 registry) for the pid list, then reads per-pid metadata
    # BEST-EFFORT + READ-ONLY (never mutates/kills): Windows CIM Win32_Process (executable path + command-line
    # tokens; Windows exposes no cheap cwd, so detection there is exe/command-line-primary per FR-011's
    # "cwd/command-line sampling"); Linux /proc (cwd, exe, cmdline); macOS Get-Process + BSD ps (executable +
    # command line, with the known worktree as the relative-argv cwd fallback). Returns @({pid; image; source; path}).
    #
    # PROMPT vs ACCESS (DRIFT-198-I003-004): the reviewer HOST is handed the review PROMPT as a SINGLE positional
    # command-line arg (`codex exec "<prompt>"`). Because the command line is parsed into STRUCTURED argv with
    # platform-appropriate quoting (Get-ContinuousCoReviewPathLikeTokens → CommandLineToArgvW on Windows; NUL-split
    # /proc/<pid>/cmdline on Linux; quote-aware BSD ps fallback on macOS), that whole prompt is ONE non-path token - so a prompt that merely NAMES origin
    # paths is never mistaken for origin ACCESS, while a REAL origin path passed as its OWN arg (by the host or any
    # descendant) IS observed. This SUPERSEDED the earlier prompt-token-subtraction workaround, whose whitespace-split
    # tokenizer both false-positived on prompt mentions AND could be BYPASSED by a quoted origin path with spaces
    # (codex runs …181010372 / …190522932 / …192442732). RELATIVE traversal args (e.g. `git show ..\..\<origin>\x`)
    # are ALSO caught: each relative path-like token is resolved against the process cwd
    # (Resolve-ContinuousCoReviewRelativeOriginTokens; POSIX `/proc/<pid>/cwd`, Windows the -WorktreeCwd the reviewer
    # was launched in) and the normalized absolute path is checked under-origin (codex run …195149281). AMENDED design
    # (maintainer review 2026-07-12, FR-011 amended): a cwd/exe-under-origin sample is a STRONG signal (hard
    # `containment-violated`); a command-line ARGUMENT under origin is a BEST-EFFORT diagnostic warning only (argv
    # coverage is inherently incomplete — option-attached `--name=value` is expanded, but response files / env expansion
    # remain uncovered) and NEVER by itself discards a valid review. The STRUCTURAL guarantee is FR-008/T013. Returns the
    # samples and, via the optional -Health [ref], the monitor's own health (procs seen, sample count, degraded + reason)
    # so weak visibility is RECORDED, never silent inactivity.
    param([Parameter(Mandatory)][int]$RootPid, [AllowEmptyString()][string]$WorktreeCwd, [ref]$Health)
    $samples = [System.Collections.Generic.List[object]]::new()
    $degraded = $false; $degradedReason = ''; $procsSeen = 0
    if (-not (Get-Command -Name 'Get-SpecrewProcessTreeDescendants' -ErrorAction SilentlyContinue)) {
        $helper = Join-Path (Split-Path -Parent $PSScriptRoot) 'agent-tasks/process-tree.ps1'
        if (Test-Path -LiteralPath $helper -PathType Leaf) { try { . $helper } catch { $null = $_ } }
    }
    $procIds = @($RootPid)
    try { $procIds += @(Get-SpecrewProcessTreeDescendants -RootPid $RootPid) } catch { $degraded = $true; $degradedReason = 'process-tree-enumeration-failed' }
    $procIds = @($procIds | Where-Object { $_ -gt 0 } | Select-Object -Unique)
    # STRONG signals (cwd/exe under origin) hard-fail; a command-line ARGUMENT under origin is a best-effort DIAGNOSTIC
    # WARNING (FR-011 amended). Path candidates are EXPANDED so an option-attached value (`--git-dir=<path>`) is seen
    # (best-effort, NOT complete). The monitor tracks its own HEALTH (degraded reason + counts) so weak visibility is
    # RECORDED, never silent. A sampling failure sets degraded rather than silently returning nothing.
    if ($IsWindows) {
        $procs = @()
        try { $procs = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $procIds -contains [int]$_.ProcessId } | Select-Object ProcessId, Name, CommandLine, ExecutablePath) } catch { $degraded = $true; $degradedReason = 'cim-query-failed'; $procs = @() }
        $procsSeen = @($procs).Count
        foreach ($p in $procs) {
            $procId = [int]$p.ProcessId; $image = [string]$p.Name
            if (-not [string]::IsNullOrWhiteSpace([string]$p.ExecutablePath)) { [void]$samples.Add(@{ pid = $procId; image = $image; source = 'exe'; path = [string]$p.ExecutablePath }) }
            $argv = Expand-ContinuousCoReviewArgvPathCandidates -Argv (Get-ContinuousCoReviewCommandLineArgv -CommandLine ([string]$p.CommandLine))
            foreach ($tok in (Select-ContinuousCoReviewAbsolutePathTokens -Argv $argv)) { [void]$samples.Add(@{ pid = $procId; image = $image; source = 'arg'; path = $tok }) }
            # Windows has no cheap per-process cwd: resolve RELATIVE traversal args against the worktree the reviewer was
            # launched in (descendants inherit that cwd). This assumed-cwd is BEST-EFFORT (a child that chdir'd elsewhere
            # is not precisely resolved) - acceptable because argv is a diagnostic WARNING, not a hard fail.
            foreach ($tok in (Resolve-ContinuousCoReviewRelativeOriginTokens -Argv $argv -Cwd $WorktreeCwd)) { [void]$samples.Add(@{ pid = $procId; image = $image; source = 'arg'; path = $tok }) }
        }
        if ($procsSeen -eq 0 -and $procIds.Count -gt 0 -and -not $degraded) { $degraded = $true; $degradedReason = 'no-process-metadata-read' }
    }
    elseif ($IsMacOS) {
        foreach ($procId in $procIds) {
            $process = try { Get-Process -Id $procId -ErrorAction Stop } catch { $null }
            if ($null -eq $process) { continue }
            $procsSeen++
            $image = try { [string]$process.ProcessName } catch { '' }
            $exe = try { [string]$process.Path } catch { '' }
            if (-not [string]::IsNullOrWhiteSpace($exe)) {
                if ([string]::IsNullOrWhiteSpace($image)) { $image = [System.IO.Path]::GetFileName($exe) }
                [void]$samples.Add(@{ pid = $procId; image = $image; source = 'exe'; path = $exe })
            }
            $commandLine = try { (& ps -p $procId -o command= 2>$null | Out-String).Trim() } catch { '' }
            $argv = Expand-ContinuousCoReviewArgvPathCandidates -Argv (Get-ContinuousCoReviewCommandLineArgv -CommandLine $commandLine)
            foreach ($tok in (Select-ContinuousCoReviewAbsolutePathTokens -Argv $argv)) { [void]$samples.Add(@{ pid = $procId; image = $image; source = 'arg'; path = $tok }) }
            # macOS exposes no /proc cwd. Descendants inherit the reviewer worktree unless they chdir; argv remains
            # a best-effort diagnostic signal, so use the known launch cwd without upgrading it to a strong signal.
            foreach ($tok in (Resolve-ContinuousCoReviewRelativeOriginTokens -Argv $argv -Cwd $WorktreeCwd)) { [void]$samples.Add(@{ pid = $procId; image = $image; source = 'arg'; path = $tok }) }
        }
        if ($procsSeen -eq 0 -and $procIds.Count -gt 0 -and -not $degraded) { $degraded = $true; $degradedReason = 'no-process-metadata-read' }
    }
    else {
        foreach ($procId in $procIds) {
            $image = ''
            $exe = try { $it = Get-Item -LiteralPath "/proc/$procId/exe" -Force -ErrorAction Stop; $tg = $it.ResolveLinkTarget($true); if ($tg) { $tg.FullName } else { $null } } catch { $null }
            if ($exe) { $procsSeen++; $image = [System.IO.Path]::GetFileName($exe); [void]$samples.Add(@{ pid = $procId; image = $image; source = 'exe'; path = $exe }) }
            $cwd = try { $it = Get-Item -LiteralPath "/proc/$procId/cwd" -Force -ErrorAction Stop; $tg = $it.ResolveLinkTarget($true); if ($tg) { $tg.FullName } else { $null } } catch { $null }
            if ($cwd) { [void]$samples.Add(@{ pid = $procId; image = $image; source = 'cwd'; path = $cwd }) }   # STRONG signal - always sampled
            # STRUCTURED argv: /proc/<pid>/cmdline is NUL-delimited, so split on NUL (do NOT join to a string - that
            # would re-introduce the whitespace-split bypass for a path arg containing spaces).
            $argv = try { @(((Get-Content -LiteralPath "/proc/$procId/cmdline" -Raw -ErrorAction Stop) -split "`0") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) } catch { @() }
            $argv = Expand-ContinuousCoReviewArgvPathCandidates -Argv $argv
            foreach ($tok in (Select-ContinuousCoReviewAbsolutePathTokens -Argv $argv)) { [void]$samples.Add(@{ pid = $procId; image = $image; source = 'arg'; path = $tok }) }
            # RELATIVE traversal args resolved against the process cwd (EXACT on POSIX; worktree fallback) -> under-origin.
            $effectiveCwd = if (-not [string]::IsNullOrWhiteSpace($cwd)) { $cwd } else { $WorktreeCwd }
            foreach ($tok in (Resolve-ContinuousCoReviewRelativeOriginTokens -Argv $argv -Cwd $effectiveCwd)) { [void]$samples.Add(@{ pid = $procId; image = $image; source = 'arg'; path = $tok }) }
        }
        if ($procsSeen -eq 0 -and $procIds.Count -gt 0 -and -not $degraded) { $degraded = $true; $degradedReason = 'no-process-metadata-read' }
    }
    if ($null -ne $Health) { $Health.Value = @{ procs_expected = $procIds.Count; procs_seen = $procsSeen; sample_count = $samples.Count; degraded = $degraded; reason = $degradedReason } }
    return , ($samples.ToArray())
}

function Test-ContinuousCoReviewContainmentViolations {
    # THE pure containment-violation checker (FR-011 / SC-003). A SAMPLE {pid; image; source(cwd|exe|arg); path}
    # is a VIOLATION when its path physically resolves UNDER an origin root (observed origin access), via the
    # SAME shared canonicalizer + predicate T013 uses (semantics cannot drift). Returns a BOUNDED, REDACTED
    # ContainmentRecord per distinct (pid, source, origin-path): run_id, process (pid + image BASENAME only),
    # command_line (a REDACTED marker - NEVER the raw command line/prompt/env/creds), the origin `path`
    # (canonicalized, length-capped), the source signal, and observed_at. PURE + read-only: samples nothing,
    # kills nothing - the loud fail is applied by the caller at the run's natural end, never mid-flight.
    param(
        [Parameter(Mandatory)][AllowNull()][object[]]$Samples,
        [Parameter(Mandatory)][string[]]$OriginRoots,
        [Parameter(Mandatory)][string]$RunId,
        [string]$ObservedAt
    )
    if ([string]::IsNullOrWhiteSpace($ObservedAt)) { $ObservedAt = ConvertTo-ContinuousCoReviewReviewerIsoTimestamp }
    $roots = @($OriginRoots | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $violations = [System.Collections.Generic.List[object]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($s in @($Samples)) {
        if ($null -eq $s) { continue }
        $path = try { [string]$s.path } catch { '' }
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        $under = $false
        foreach ($root in $roots) { if (Test-ContinuousCoReviewPathUnderRoot -Path $path -Root $root) { $under = $true; break } }
        if (-not $under) { continue }
        $resolved = Get-ContinuousCoReviewPhysicalPath -Path $path
        if ([string]::IsNullOrWhiteSpace($resolved)) { $resolved = $path }
        $procId = try { [int]$s.pid } catch { 0 }
        $image = try { [string]$s.image } catch { '' }
        # A fixture or cross-host observation may carry either separator style. Path.GetFileName only
        # recognizes the current platform's separator, so split both styles to preserve the basename-
        # only redaction contract on every CI OS.
        $imageLeaf = if (-not [string]::IsNullOrWhiteSpace($image)) { @($image -split '[\\/]' | Where-Object { $_ -ne '' })[-1] } else { 'unknown' }
        $source = try { [string]$s.source } catch { '' }; if ([string]::IsNullOrWhiteSpace($source)) { $source = 'unknown' }
        $boundedPath = if ($resolved.Length -gt 256) { $resolved.Substring(0, 256) + '...[truncated]' } else { $resolved }
        $key = "$procId|$source|$boundedPath"
        if (-not $seen.Add($key)) { continue }
        [void]$violations.Add([pscustomobject][ordered]@{
                run_id       = $RunId
                process      = ("pid={0} image={1}" -f $procId, $imageLeaf)
                command_line = ("[redacted - raw command line withheld; origin access observed via {0}]" -f $source)
                path         = $boundedPath
                source       = $source
                observed_at  = $ObservedAt
            })
    }
    return , ($violations.ToArray())
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
    # FR-008 (203 W1) / SC-002 containment: the reviewer worktree MUST materialize OUTSIDE the origin so
    # no upward directory/git walk from inside the confined worktree can resolve the real project. Reject
    # an EphemeralRoot that resolves AT or UNDER the origin git root (or the governance RepoRoot).
    # SYMLINK/JUNCTION SAFE (findings 3b5ae645, 44760c20): compare COMPONENT-WISE PHYSICAL paths via the
    # SHARED Get-ContinuousCoReviewPhysicalPath (the SAME helper the strict design-context validation
    # uses, so containment semantics cannot drift) - not lexical strings, and not final-component-only. An
    # EphemeralRoot, or an INTERMEDIATE directory component, that is a junction/symlink whose target is
    # inside origin would otherwise pass and materialize physically under origin. FAIL-CLOSED: an
    # unresolvable candidate is refused.
    $assertOutsideOrigin = {
        param([string]$candidatePath, [string]$context)
        # FAIL-CLOSED: an unresolvable candidate is refused. Containment (under-origin) uses the SHARED
        # Test-ContinuousCoReviewPathUnderRoot - same physical resolution AND platform-appropriate case
        # semantics as the strict design-context gate, so a case-distinct path can't slip on POSIX.
        if ([string]::IsNullOrEmpty((Get-ContinuousCoReviewPhysicalPath -Path $candidatePath))) {
            throw "[co-review] refusing to materialize the reviewer worktree $context - its physical path could not be resolved reliably (fail-closed, FR-008 containment)."
        }
        foreach ($originPath in @($gitRoot, $resolved)) {
            if ([string]::IsNullOrWhiteSpace($originPath)) { continue }
            if (Test-ContinuousCoReviewPathUnderRoot -Path $candidatePath -Root $originPath) {
                $originFull = Get-ContinuousCoReviewPhysicalPath -Path $originPath
                throw "[co-review] refusing to materialize the reviewer worktree $context inside the origin ('$originFull'): the confined worktree must live outside the project so no upward walk can resolve it (FR-008 containment)."
            }
        }
    }
    & $assertOutsideOrigin $EphemeralRoot "root ('$EphemeralRoot')"
    $worktree = Join-Path $EphemeralRoot ('ccr-worktree-' + [guid]::NewGuid().ToString('N'))
    $tarPath = "$worktree.tar"
    New-Item -ItemType Directory -Path $worktree -Force | Out-Null
    # Verify the FINAL created worktree's physical path is outside origin too (defense in depth: a link at
    # the leaf, or the root swapped for a junction between the check and the create, would otherwise slip).
    & $assertOutsideOrigin $worktree "path ('$worktree')"

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
    # FR-009 / SC-002 (finding 9e3a44f1): the change-set diff CONTENT can carry ORIGIN-ABSOLUTE paths - a
    # committed doc that references file:///<origin>, or committed review-evidence echoing an earlier run -
    # and that is a real leak in the reviewer bundle (and hands the reviewer a route toward the origin).
    # Relativize the diff to <project> against BOTH the governance root and the git root, exactly as the
    # context copies are (T014). Structure is preserved; only the origin PREFIX is neutralized, so a genuine
    # hardcoded-absolute-path change still shows as <project>/... and stays reviewable.
    $diffOriginRoots = @($resolved); if (-not [string]::IsNullOrWhiteSpace($gitRoot)) { $diffOriginRoots += $gitRoot }
    $diff = ConvertTo-ContinuousCoReviewOriginRelativized -Content $diff -OriginRoots $diffOriginRoots
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

# Volatile reviewer-HOST runtime directories: an agentic reviewer host writes ephemeral session state
# into its cwd. A NEW file it creates under one of these during a review is churn, not tampering. But a
# PRE-EXISTING file there (e.g. project-tracked config the archive extracted) that is MODIFIED or DELETED
# IS tampering (finding 3b5ae645) - so these dirs are HASHED, not skipped; only NEW files under them are
# exempted, and ONLY by the integrity check's new-file branch, never wholesale.
$script:ContinuousCoReviewVolatileHostDirs = @('.antigravitycli', '.codex', '.claude', '.cursor', '.gemini', '.copilot')
# CHARACTERIZED EPHEMERAL allowlist (DRIFT-198-I003-006, maintainer ruling 2026-07-12): only KNOWN transient
# reviewer-host outputs are exempt churn. A recognized ephemeral SUBDIR segment OR ephemeral FILE pattern under a
# host dir passes; an UNKNOWN file, a CONFIG file, or persistent state FAILS integrity - a reviewer must NOT add
# .codex/config.toml or .claude/settings.json and still get a valid result (only .review/findings.jsonl is writable).
$script:ContinuousCoReviewEphemeralHostSegments = @('sessions', 'history', 'logs', 'log', 'cache', 'tmp', 'temp', 'todos', 'shell-snapshots', 'statsig', 'projects', 'ide', 'versions', 'updates')
$script:ContinuousCoReviewEphemeralHostFilePatterns = @('*.log', '*.lock', '*.pid', '*.tmp', '*.jsonl', '*.sock', 'session*.json', 'history*.json', '*.session')
$script:ContinuousCoReviewPersistentHostFilePatterns = @('config.*', 'settings.*', '*.toml', '*.yaml', '*.yml', '*.ini', '*.config', 'credentials*', 'auth*')

function Test-ContinuousCoReviewIsHostChurnPath {
    # Is a NEW file legitimate, transient reviewer-host session state (exempt churn) - or unknown/persistent content
    # that must FAIL the integrity check? (DRIFT-198-I003-006: the old exemption passed ANY new file under a host dir,
    # so a reviewer could add .codex/config.toml / .claude/settings.json and still get a valid result.) Now the
    # top-level dir MUST be a volatile host dir AND the path must match the CHARACTERIZED EPHEMERAL allowlist - a
    # recognized ephemeral SUBDIR segment or ephemeral FILE pattern - and must NOT match a persistent/config pattern.
    # Anything else under a host dir (unknown file, config, persistent state) is NOT churn. Used ONLY for new files;
    # a modified/deleted PRE-EXISTING file under a host dir is always tampering (finding 3b5ae645).
    param([Parameter(Mandatory)][AllowEmptyString()][string]$RelativePath)
    $segments = @(($RelativePath -split '[\\/]') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($segments.Count -eq 0) { return $false }
    if ($script:ContinuousCoReviewVolatileHostDirs -notcontains $segments[0]) { return $false }   # not under a host dir
    $leaf = [string]$segments[-1]
    # EXPLICIT DENY: a config/persistent-looking file under a host dir is NEVER exempt churn (adding it is tampering).
    foreach ($pat in $script:ContinuousCoReviewPersistentHostFilePatterns) { if ($leaf -like $pat) { return $false } }
    # ALLOW: a recognized ephemeral SUBDIR segment...
    for ($i = 1; $i -lt $segments.Count; $i++) { if ($script:ContinuousCoReviewEphemeralHostSegments -contains ([string]$segments[$i]).ToLowerInvariant()) { return $true } }
    # ...OR a recognized ephemeral FILE pattern.
    foreach ($pat in $script:ContinuousCoReviewEphemeralHostFilePatterns) { if ($leaf -like $pat) { return $true } }
    return $false   # under a host dir but NOT a characterized ephemeral output -> tampering
}

function Get-ContinuousCoReviewWorktreeSourceHashes {
    # Integrity-evidence helper: a map { relative-path -> sha256 } of the worktree's existing files.
    # Comparing this before vs after execution makes any MUTATION of an existing file visible; a caller
    # applies its own allowlist for legitimately-created NEW files (verification output, reviewer findings,
    # host session churn). SCOPE: source AND the REVIEWER-AUTHORITY inputs under .review/ (changes.diff,
    # design/, contracts, process context, implementer-evidence) AND any host-runtime dir contents are
    # hashed - rewriting the authority the review depends on, or a tracked config under a host dir, is
    # exactly the tampering this must catch. Only .git/ is skipped (git-archive extract has no .git anyway;
    # kept for the opt-in helper).
    param([Parameter(Mandatory)][string]$WorktreePath)
    $map = @{}
    $rootFull = (Resolve-Path -LiteralPath $WorktreePath).Path.TrimEnd([char]'\', [char]'/')
    foreach ($f in @(Get-ChildItem -LiteralPath $WorktreePath -Recurse -File -Force -ErrorAction SilentlyContinue)) {
        $rel = [System.IO.Path]::GetRelativePath($rootFull, $f.FullName).Replace('\', '/')
        if (($rel -replace '/.*$', '') -eq '.git') { continue }
        try { $map[$rel] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash } catch { $map[$rel] = 'unreadable' }
    }
    return $map
}

function Invoke-ContinuousCoReviewBoundedVerification {
    # OPT-IN API ONLY (maintainer's option-1 simplification 2026-07-11): a focused bounded runner for
    # EXPLICIT caller-supplied commands. It is NOT wired into the automatic review flow and MUST NEVER
    # run automatically - the orchestrator does not call it (automatic per-review reruns were removed
    # because they could not be confined in-process; see reviewer-spawn-contract.md). Runner-observed
    # verification for a review is T018's job (commands run ONCE through the recorded-run wrapper; the
    # digest-bound evidence is injected for the reviewer to read).
    #
    # Runs the DECLARED commands in the given directory, each with (1) a TIMEOUT and process CONTAINMENT
    # (the whole child process tree is killed on timeout), (2) a byte-bounded, zero-disk CAPPED output
    # capture, and (3) PRE/POST MUTATION EVIDENCE (existing-file hashes before vs after). Returns one
    # record per command. The caller owns confinement of the directory it points this at.
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
        # STRICT BOUNDED CONTRACT (codex finding f1 verification-environment-contamination, 2026-07-12; completed
        # for the event-scoped suppression by Antigravity finding 934e5314, 2026-07-17): the reviewer process runs
        # with both broad and event-scoped hook suppression so the reviewer host's OWN lifecycle hooks no-op (a
        # reviewer must not govern itself). Those vars are inherited by ANY child. This helper is the ONLY SUPPORTED
        # path for governance-sensitive verification launched under a reviewer session, so it EXPLICITLY REMOVES
        # both suppressions from every verification child's environment - a governance/hook the child invokes then
        # executes NORMALLY (no false-green). ProcessStartInfo.Environment is pre-seeded from this process; dropping
        # the keys means the child never inherits the reviewer's suppression. (This does NOT claim complete
        # isolation: an arbitrary reviewer-spawned child that is NOT launched through this helper still inherits
        # suppression - intentional, to prevent recursive governance; see reviewer-spawn-contract.md.)
        [void]$psi.Environment.Remove('SPECREW_REFOCUS_DISABLE')
        [void]$psi.Environment.Remove('SPECREW_DISABLE_EVENTS')
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
    param([Parameter(Mandatory)][string]$RunId, [int]$RoundNumber = 1, [int]$MaxRounds = 2, [string]$PriorFindings, [string]$HumanScope, [switch]$DesignContextEmpty, [switch]$ImplementerEvidencePresent)
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
$scopeBlock$designContextBlock$evidenceBlock
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

VERIFICATION — STRICTLY READ-ONLY (your tree is under integrity check): this working directory is hashed
immediately BEFORE and AFTER your review, and the ONLY file you may create or modify is .review/findings.jsonl
(your output). ANY other change to the tree — editing/adding/deleting source, rewriting a .review/ input, or
leaving build/test artifacts behind — FAILS the whole review. So do NOT run builds or tests that write into this
directory. Use the implementer's digest-matched test evidence (above, when present) as your runtime evidence and
SPOT-CHECK it by READING — the diff, the code, the recorded commands and exit codes — not by re-running. A
read-only inspection command that writes nothing here (reading files, git log, grep) is fine; anything that writes
into the tree is not. A claim you cannot confirm without mutating the tree is reported as a finding, never acted on.

GOVERNANCE-SENSITIVE CHECKS — REPORT AS UNVERIFIABLE, DO NOT SELF-TEST: you run under a reviewer session whose
environment suppresses Specrew's own hooks (so a reviewer never governs itself). Do NOT run a governance/hook-behavior
test directly, and do NOT alter your own environment to try to change that — a governance check you launch from here
is environment-contaminated and could FALSE-GREEN. If some governance or hook behavior is not already covered by the
digest-matched implementer evidence, report it as UNVERIFIABLE-HERE (a finding, never a pass) rather than running it
yourself.

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

function Get-ContinuousCoReviewFilePrimaryResult {
    # FILE-PRIMARY acceptance (maintainer option-1 with strict qualification, 2026-07-12). Some reviewer hosts
    # (codex exec) DELIVER their review by APPENDING to .review/findings.jsonl and exit 0 with EMPTY stdout - the
    # engine's stdout-primary assumption then misfires on every such review: a wasteful T108 retry (a second full
    # provider run), a 'partial' completeness mislabel, and a failure-looking EMPTY_EXIT0 WARN - even though the
    # reviewer produced a COMPLETE review on disk. This returns a FULLY contract-validated FindingsResult JSON
    # built from that file ONLY when EVERY strict condition holds; otherwise $null (FAIL-CLOSED - the caller then
    # keeps the retry / lenient-harvest / partial path unchanged).
    #
    # STRICT, unlike the LENIENT Get-ContinuousCoReviewHarvestedPartialResult (which salvages a cut-short/timeout
    # run and SKIPS malformed lines): here a single malformed/truncated line, a foreign/absent source_run_id, an
    # empty file, or ANY schema miss => $null. The CALLER enforces the two conditions not checkable here: a CLEAN
    # reviewer exit (0, not timed out) BEFORE calling, and the reviewer-tree INTEGRITY check (the orchestrator's
    # pre/post-hash) before trusting the result.
    #
    # A ZERO-finding review is DELIBERATELY not acceptable via this path: file-only delivery cannot PROVE
    # 'no_findings' (an empty/absent file is indistinguishable from a lost result), so a clean no-findings verdict
    # must arrive as the stdout FindingsResult - never a bare empty file (maintainer rule; matches the prompt's
    # NEVER-FALSE-GREEN: empty output is never a clean pass).
    param(
        [Parameter(Mandatory)][string]$WorktreePath,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][datetime]$RunStartUtc,
        [bool]$ExistedBefore,
        [string]$SchemaRoot
    )
    $jsonlPath = Join-Path $WorktreePath '.review/findings.jsonl'
    if (-not (Test-Path -LiteralPath $jsonlPath -PathType Leaf)) { return $null }
    # (2) CREATED / WRITTEN during THIS run. A file that did not exist at run start and exists now was created by
    # this run; a PRE-EXISTING file counts only if its write time advanced past run start (a stale leftover with
    # an older mtime is refused). Doubly-guarded by the per-finding source_run_id check (5) below.
    $fi = Get-Item -LiteralPath $jsonlPath -ErrorAction SilentlyContinue
    if ($null -eq $fi) { return $null }
    $createdThisRun = (-not $ExistedBefore) -or ($fi.LastWriteTimeUtc -ge $RunStartUtc)
    if (-not $createdThisRun) { return $null }
    # (3)/(4)/(5) EVERY nonblank line must parse (no truncated/malformed tail tolerated) AND carry THIS run's
    # source_run_id. A single failure fails the WHOLE file closed - there is no partial accept on this path.
    $findings = [System.Collections.Generic.List[object]]::new()
    foreach ($line in @(Get-Content -LiteralPath $jsonlPath -ErrorAction Stop)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $obj = $null
        try { $obj = ([string]$line).Trim() | ConvertFrom-Json -Depth 100 -ErrorAction Stop }
        catch { return $null }   # (4) malformed / truncated line -> fail closed
        if ($null -eq $obj) { return $null }
        if (($null -eq $obj.PSObject.Properties['source_run_id']) -or ([string]$obj.source_run_id -ne $RunId)) { return $null }   # (5) current run only
        $findings.Add($obj)
    }
    if ($findings.Count -eq 0) { return $null }   # (3) empty file -> cannot prove a zero-finding review -> fail closed
    # (6) assemble the FindingsResult envelope and run FULL contract validation against findings-result.schema.json.
    $result = [pscustomobject][ordered]@{
        schema_version = '1.0'
        run_id         = $RunId
        status         = 'findings'
        findings       = $findings.ToArray()
        created_at     = (ConvertTo-ContinuousCoReviewReviewerIsoTimestamp)
    }
    if (-not (Get-Command -Name 'Test-ReviewerContractObject' -ErrorAction SilentlyContinue)) {
        $contractsHelper = Join-Path $PSScriptRoot 'reviewer-contracts.ps1'
        if (Test-Path -LiteralPath $contractsHelper -PathType Leaf) { try { . $contractsHelper } catch { $null = $_ } }
    }
    if (-not (Get-Command -Name 'Test-ReviewerContractObject' -ErrorAction SilentlyContinue)) { return $null }   # cannot validate -> fail closed
    $root = try { Get-ContinuousCoReviewContractRoot -SchemaRoot $SchemaRoot } catch { $null }
    if ([string]::IsNullOrWhiteSpace($root)) { return $null }
    $validation = try { Test-ReviewerContractObject -ContractName 'FindingsResult' -InputObject $result -SchemaRoot $root } catch { $null }
    if (($null -eq $validation) -or (-not $validation.Valid)) { return $null }   # (6) any schema miss -> fail closed
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
    # ROOT-CAUSE FIX (empty-exit0 diagnosis 2026-07-12): the reviewer host inherits the environment, so its
    # OWN global Specrew hooks (e.g. ~/.codex/hooks.json -> specrew-hook-launch.ps1) fire while it reviews.
    # The codex Stop hook is a DECISION-BLOCK that runs the Specrew dispatcher against the extracted specs/
    # in the reviewer worktree and can block/derail the reviewer into producing NOTHING (the intermittent
    # empty-exit0 / no-parseable-findings-json class). Set the launcher's documented kill switch so the
    # reviewer subprocess AND its hook children no-op every Specrew hook: a reviewer must never trigger the
    # governance machinery on itself. (The kill switch is inherited by codex's hook child processes.)
    $psi.Environment['SPECREW_REFOCUS_DISABLE'] = '1'
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
        # FINAL best-effort sample after the run loop (FR-011 amended, maintainer review 2026-07-12): a short-lived
        # descendant may briefly linger, and on a TIMED-OUT reviewer this fires BEFORE the kill so a last origin access
        # is still observed. running=false marks it FINAL so the monitor records it as taken without treating the
        # (expected) vanished tree as a sampling failure. Never silent inactivity.
        if ($Heartbeat) {
            try { & $Heartbeat (New-ContinuousCoReviewReviewerInvocationTelemetry -HostName $HostName -Command $cmd -StartedAt $startedAt -Stopwatch $sw -TimeoutSeconds $TimeoutSeconds -Running $false -Containment $containment) } catch { $null = $_ }
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
        [switch]$ImplementerEvidencePresent
    )
    $prompt = Get-ContinuousCoReviewSlimPrompt -RunId $RunId -RoundNumber $RoundNumber -MaxRounds $MaxRounds -PriorFindings $PriorFindings -HumanScope $HumanScope -DesignContextEmpty:$DesignContextEmpty -ImplementerEvidencePresent:$ImplementerEvidencePresent
    # FILE-PRIMARY (2026-07-12): capture whether the reviewer's output file pre-exists + a run-start instant BEFORE
    # the reviewer runs, so Get-ContinuousCoReviewFilePrimaryResult can prove the file was written by THIS run.
    $findingsJsonlPath = Join-Path $WorktreePath '.review/findings.jsonl'
    $runStartUtc = [datetime]::UtcNow
    $existedBefore = Test-Path -LiteralPath $findingsJsonlPath -PathType Leaf
    $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $WorktreePath -Prompt $prompt -HostName $HostName -TimeoutSeconds $TimeoutSeconds -Heartbeat $Heartbeat

    # T108/FR-033 (D-197-I009-015): retry ONCE on an EMPTY exit-0 result before the run can be declared
    # no-parseable-findings - the field failure was ~50% empty-but-successful exits on one reviewer host,
    # but the guard is host-GENERIC (any host can drop its final blob). The DIAGNOSTIC distinguishes the
    # two suspect causes: incremental findings PRESENT in the worktree = the reviewer worked and the
    # final stdout was lost (finalization/capture gap); ABSENT = the run produced nothing at all.
    # NEVER-FALSE-GREEN is preserved: a still-empty retry returns empty and the orchestrator fails the
    # run loudly (no-parseable-findings-json) - the retry can only ADD a real result, never fake one.
    #
    # FILE-PRIMARY (2026-07-12): an EMPTY exit-0 result is EITHER a host that DELIVERED its review by writing
    # .review/findings.jsonl and exited 0 with empty stdout (codex exec - a COMPLETE review on disk), OR a
    # genuinely empty run. Distinguish them BEFORE retrying: if the reviewer produced a fully-contract-validated,
    # current-run findings.jsonl, ACCEPT it as file-primary - NO retry, NO WARN (retrying would only burn a second
    # provider run for the same review, the codex empty-stdout misfire). Only a genuinely empty result (no valid
    # file) retries once, and only THEN is the WARN emitted. A NON-empty stdout is the stdout-primary path, left
    # ENTIRELY unchanged (claude): $emptyExit0 is false, so neither the file-primary check nor the retry runs.
    $filePrimary = $null
    $emptyExit0 = ($null -ne $r) -and ($r.exit_code -eq 0) -and [string]::IsNullOrWhiteSpace([string]$r.stdout)
    if ($emptyExit0) {
        $filePrimary = Get-ContinuousCoReviewFilePrimaryResult -WorktreePath $WorktreePath -RunId $RunId -RunStartUtc $runStartUtc -ExistedBefore $existedBefore
    }
    if ($emptyExit0 -and (-not $filePrimary)) {
        $jsonlPresent = Test-Path -LiteralPath $findingsJsonlPath -PathType Leaf
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
        # the retry is a fresh reviewer run in the SAME worktree - if IT too delivered via the file with empty
        # stdout, accept that; a NON-empty retry stdout is the stdout-primary path (left unchanged).
        $emptyExit0Retry = ($null -ne $r) -and ($r.exit_code -eq 0) -and [string]::IsNullOrWhiteSpace([string]$r.stdout)
        if ($emptyExit0Retry) {
            $filePrimary = Get-ContinuousCoReviewFilePrimaryResult -WorktreePath $WorktreePath -RunId $RunId -RunStartUtc $runStartUtc -ExistedBefore $existedBefore
        }
    }

    # Tag a COMPLETE file-delivered review so the orchestrator records completeness='full' + source=file-primary
    # (instead of the empty-stdout -> lenient-harvest -> 'partial' path). The orchestrator's tamper check still runs
    # AFTER this and can still fail the run; this only carries the validated result forward.
    if ($filePrimary) {
        $r | Add-Member -NotePropertyName 'file_primary_result' -NotePropertyValue $filePrimary -Force
        if ($null -ne $r.telemetry) { $r.telemetry | Add-Member -NotePropertyName 'result_source' -NotePropertyValue 'file-primary' -Force }
    }
    return $r
}
