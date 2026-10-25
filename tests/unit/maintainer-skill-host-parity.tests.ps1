#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 2026-08-21: the maintainer skills in this repo are mirrored across four host directories BY HAND, with
# no generator and, until now, nothing checking it. `specrew-local-build` shipped Claude-only for the
# same reason most such things do - that is where the session writing it happened to be - and the crew
# that would most need it implements on Codex, which could not see it.
#
# There is already a convention for a DELIBERATE exception: `specrew-gate-stop` carries `host-scope: claude`
# in its front matter, because it exists to disable Claude's AskUserQuestion picker and means nothing
# elsewhere. So the rule is not "everything everywhere" - it is "everything everywhere unless it SAYS
# otherwise", and saying otherwise is a line in the file rather than an entry in a list here.
#
# These skills are maintainer-only and must never reach a consumer, which the first case below pins:
# nothing under a host directory is in the module FileList, so no install and no `specrew update` can
# carry our own build machinery into someone's workspace.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    # .copilot/skills carries a different family entirely - zero specrew-* skills - so it is not a
    # mirror target. Checked rather than assumed.
    $script:HostRoots = @('.agents/skills', '.claude/skills', '.cursor/rules', '.github/skills')
    $script:Canonical = '.claude/skills'
    # THE REVIEW SNAPSHOT STRIPS THESE DIRECTORIES. worktree-reviewer.ps1 freezes a tree with the
    # methodology machinery removed, and the deployed host skill mirrors are machinery - all four
    # of them. This suite checks the MAINTAINER REPO's layout, so in a stripped tree there is
    # nothing to check and it must say so rather than fail. Two unconditional assertions here did
    # fail that way and killed a review round at preflight, twice.
    $script:HostDirsPresent = Test-Path -LiteralPath (Join-Path $script:RepoRoot $script:Canonical) -PathType Container

    function script:Get-SkillNames {
        param([Parameter(Mandatory)][string]$HostRoot)
        $full = Join-Path $script:RepoRoot $HostRoot
        if (-not (Test-Path -LiteralPath $full -PathType Container)) { return @() }
        return @(Get-ChildItem -LiteralPath $full -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like 'specrew-*' } |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf } |
                ForEach-Object { $_.Name })
    }
    function script:Get-HostScope {
        param([Parameter(Mandatory)][string]$SkillName)
        $path = Join-Path $script:RepoRoot (Join-Path $script:Canonical (Join-Path $SkillName 'SKILL.md'))
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return '' }
        foreach ($line in @(Get-Content -LiteralPath $path -Encoding UTF8)) {
            $trimmed = $line.Trim()
            if ($trimmed.StartsWith('host-scope:')) {
                return $trimmed.Substring('host-scope:'.Length).Trim().Trim([char]34).Trim([char]39)
            }
        }
        return ''
    }
}

Describe 'maintainer skills stay out of consumer projects' {
    It 'ships none of them, so our build machinery cannot leak into a workspace' {
        # The self-leak class: a skill about building Specrew is meaningless in a project that has no
        # Specrew checkout, and its presence there would be a defect rather than a feature.
        $fileList = @((Import-PowerShellDataFile -LiteralPath (Join-Path $script:RepoRoot 'Specrew.psd1')).FileList)
        $leaked = @($fileList | Where-Object {
                $normalized = ([string]$_).Replace([char]92, [char]47)
                $normalized -like '.claude/*' -or $normalized -like '.agents/*' -or
                $normalized -like '.cursor/*' -or $normalized -like '.github/skills/*'
            })
        @($leaked).Count | Should -Be 0 -Because "maintainer host directories must not be packaged (leaked: $($leaked -join ', '))"
    }
}

Describe 'a maintainer skill is visible on every host unless it says otherwise' {
    It 'mirrors every host-neutral skill to all four host directories' {
        $missing = [System.Collections.Generic.List[string]]::new()
        foreach ($skill in (Get-SkillNames -HostRoot $script:Canonical)) {
            $scope = Get-HostScope -SkillName $skill
            if (-not [string]::IsNullOrWhiteSpace($scope)) { continue }
            foreach ($hostRoot in $script:HostRoots) {
                $path = Join-Path $script:RepoRoot (Join-Path $hostRoot (Join-Path $skill 'SKILL.md'))
                if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { [void]$missing.Add("$skill missing from $hostRoot") }
            }
        }
        @($missing).Count | Should -Be 0 -Because "a skill only the author's host can see is invisible to the crew that needs it (missing: $($missing -join '; '))"
    }

    It 'keeps the GUIDANCE identical across mirrors, allowing only host-capability declarations to differ' {
        # Byte-identity was the first rule here and it was WRONG, which the guard said immediately:
        # .claude/specrew-design-workshop carries one extra front-matter line, `disallowed-tools:
        # AskUserQuestion`, because Claude's picker collapses a workshop question and no other host has
        # that problem. That is a deliberate host adaptation, not drift.
        #
        # So the invariant is that the GUIDANCE is the same everywhere and only the host-capability
        # declaration differs. Those lines are enumerated, so a new one has to be added here
        # deliberately rather than quietly widening what counts as "the same".
        $capabilityKeys = @('disallowed-tools:', 'host-scope:', 'allowed-tools:')
        function script:Get-GuidanceText {
            param([Parameter(Mandatory)][string]$Path)
            $kept = foreach ($line in @(Get-Content -LiteralPath $Path -Encoding UTF8)) {
                $trimmed = $line.Trim()
                $isCapability = $false
                foreach ($key in $capabilityKeys) { if ($trimmed.StartsWith($key)) { $isCapability = $true } }
                if (-not $isCapability) { $line }
            }
            return ($kept -join "`n")
        }

        $drifted = [System.Collections.Generic.List[string]]::new()
        foreach ($skill in (Get-SkillNames -HostRoot $script:Canonical)) {
            $canonicalPath = Join-Path $script:RepoRoot (Join-Path $script:Canonical (Join-Path $skill 'SKILL.md'))
            $canonicalText = Get-GuidanceText -Path $canonicalPath
            foreach ($hostRoot in $script:HostRoots) {
                if ($hostRoot -eq $script:Canonical) { continue }
                $path = Join-Path $script:RepoRoot (Join-Path $hostRoot (Join-Path $skill 'SKILL.md'))
                if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
                if ((Get-GuidanceText -Path $path) -cne $canonicalText) {
                    [void]$drifted.Add("$skill differs in $hostRoot")
                }
            }
        }
        @($drifted).Count | Should -Be 0 -Because "mirrored guidance must match (drifted: $($drifted -join '; '))"
    }

    It 'honours a declared single-host scope instead of demanding mirrors' {
        # specrew-gate-stop exists to disable Claude's AskUserQuestion picker; mirroring it would be
        # wrong, and the file says so in its own front matter rather than in an allowlist here.
        if (-not $script:HostDirsPresent) { Set-ItResult -Skipped -Because 'the host skill directories are machinery and are stripped from a review snapshot'; return }
        (Get-HostScope -SkillName 'specrew-gate-stop') | Should -Be 'claude'
        foreach ($hostRoot in @('.agents/skills', '.cursor/rules', '.github/skills')) {
            $path = Join-Path $script:RepoRoot (Join-Path $hostRoot 'specrew-gate-stop/SKILL.md')
            (Test-Path -LiteralPath $path -PathType Leaf) | Should -BeFalse -Because 'a claude-scoped skill is not mirrored'
        }
    }

    It 'sees the newly added local-build skill on every host' {
        if (-not $script:HostDirsPresent) { Set-ItResult -Skipped -Because 'the host skill directories are machinery and are stripped from a review snapshot'; return }
        foreach ($hostRoot in $script:HostRoots) {
            $path = Join-Path $script:RepoRoot (Join-Path $hostRoot 'specrew-local-build/SKILL.md')
            (Test-Path -LiteralPath $path -PathType Leaf) | Should -BeTrue -Because "the crew implements on Codex and needs this one most"
        }
    }
}
