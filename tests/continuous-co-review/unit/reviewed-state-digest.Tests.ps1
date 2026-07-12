$ErrorActionPreference = 'Stop'

# Trace: T065, FR-025, SEC-002, NFR-001, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T065 content-addressed reviewed-state digest (FR-025/SEC-002)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')   # T017: the ONE machinery source (Get-ContinuousCoReviewMachineryPaths) both strips consume
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Invoke-DigestGit {
                param([string] $Root, [string[]] $GitArgs)
                Push-Location -LiteralPath $Root
                try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location }
            }

        function New-DigestRepo {
                param([string] $Name)
                $repo = Join-Path $TestDrive $Name
                New-Item -ItemType Directory -Path $repo -Force | Out-Null
                Invoke-DigestGit $repo @('init', '-q')
                Invoke-DigestGit $repo @('config', 'user.email', 't@e.c')
                Invoke-DigestGit $repo @('config', 'user.name', 'Test')
                Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'tracked v0' -Encoding UTF8
                New-Item -ItemType Directory -Path (Join-Path $repo 'gen') -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $repo 'gen/logic.py') -Value 'def src(): pass' -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $repo '.env') -Value 'SECRET=topsecret' -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $repo '.gitignore') -Value "gen/`n.env`n" -Encoding UTF8
                Invoke-DigestGit $repo @('add', 'a.txt', '.gitignore')
                Invoke-DigestGit $repo @('commit', '-q', '-m', 'base')   # gen/ and .env are gitignored
                return $repo
            }

        function Get-TreeNames {
                param([string] $Root, [string] $TreeId)
                Push-Location -LiteralPath $Root
                try { return @(& git ls-tree -r $TreeId --name-only 2>$null) } finally { Pop-Location }
            }
}

    

    

    

    It 'is deterministic for identical content' {
        $repo = New-DigestRepo 'determinism'
        $d1 = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d2 = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d1.ok | Should -Be $true
        $d1.tree_id | Should -Be $d2.tree_id
        $d1.tree_id | Should -Match '^[0-9a-f]{40}$'
    }

    It 'includes gitignored SOURCE in the digest tree' {
        $repo = New-DigestRepo 'gitignored'
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d.ok | Should -Be $true
        $d.included_ignored_count | Should -BeGreaterThan 0
        $names = Get-TreeNames -Root $repo -TreeId $d.tree_id
        ($names -contains 'gen/logic.py') | Should -Be $true
    }

    It 'keeps the .env secret OUT of the digest tree' {
        $repo = New-DigestRepo 'secret-out'
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $names = Get-TreeNames -Root $repo -TreeId $d.tree_id
        ($names -contains '.env') | Should -Be $false
    }

    It 'T017/FR-012: methodology MACHINERY (from the ONE Get-ContinuousCoReviewMachineryPaths source) is OUT of the digest identity, while .github/workflows + ordinary source stay IN (reviewer-can-still-see-it)' {
        $repo = New-DigestRepo 't17-machinery'
        # HOST MACHINERY (host-mirror subdirs) - the worktree strip removes these, so the identity must too (FR-012):
        New-Item -ItemType Directory -Path (Join-Path $repo '.claude/skills/specrew-foo') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo '.claude/skills/specrew-foo/skill.md') -Value 'machinery' -Encoding UTF8
        New-Item -ItemType Directory -Path (Join-Path $repo '.github/agents') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo '.github/agents/agent.md') -Value 'machinery' -Encoding UTF8
        # NON-machinery that MUST stay reviewable in BOTH strips:
        New-Item -ItemType Directory -Path (Join-Path $repo '.github/workflows') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo '.github/workflows/ci.yml') -Value 'on: push' -Encoding UTF8
        New-Item -ItemType Directory -Path (Join-Path $repo 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'src/app.ps1') -Value 'Write-Host hi' -Encoding UTF8
        Invoke-DigestGit $repo @('add', '.claude', '.github', 'src')
        Invoke-DigestGit $repo @('commit', '-q', '-m', 'machinery + workflows + src')

        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d.ok | Should -Be $true
        $names = @(Get-TreeNames -Root $repo -TreeId $d.tree_id)
        ($names -join '|') | Should -Not -Match '\.claude/skills/specrew-foo/skill\.md' -Because 'host-mirror machinery is excluded from the identity via the SAME source the worktree strips (FR-012, no drift)'
        ($names -join '|') | Should -Not -Match '\.github/agents/agent\.md' -Because '.github/agents is host machinery, excluded from both'
        ($names -contains '.github/workflows/ci.yml') | Should -Be $true -Because '.github/workflows is NOT machinery - it stays in the identity, reviewable (reviewer-can-still-see-it)'
        ($names -contains 'src/app.ps1') | Should -Be $true -Because 'ordinary source stays in the identity'
        # BY CONSTRUCTION: the machinery the digest excludes IS the worktree-strip source (they cannot drift).
        $machinery = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)
        ($machinery -contains '.claude/skills') | Should -Be $true -Because 'the single source is Get-ContinuousCoReviewMachineryPaths - digest strip == worktree strip'
        ($machinery -contains '.github/agents') | Should -Be $true
        ($machinery -contains '.github/workflows') | Should -Be $false -Because 'workflows is NOT in the machinery source, so BOTH strips keep it'
    }

    It 'T017/FR-012: a MACHINERY-only change does NOT flip the digest (not reviewed), but a SOURCE change DOES (no false-allow of source)' {
        $repo = New-DigestRepo 't17-invariant'
        New-Item -ItemType Directory -Path (Join-Path $repo '.claude/skills/specrew-foo') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo '.claude/skills/specrew-foo/skill.md') -Value 'v0' -Encoding UTF8
        New-Item -ItemType Directory -Path (Join-Path $repo 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'src/app.ps1') -Value 'v0' -Encoding UTF8
        Invoke-DigestGit $repo @('add', '.claude', 'src'); Invoke-DigestGit $repo @('commit', '-q', '-m', 'base')
        $d0 = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        Set-Content -LiteralPath (Join-Path $repo '.claude/skills/specrew-foo/skill.md') -Value 'v1-machinery-edit' -Encoding UTF8
        (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id | Should -Be $d0 -Because 'a machinery-only change is not reviewed, so it does NOT flip the identity'
        Set-Content -LiteralPath (Join-Path $repo 'src/app.ps1') -Value 'v1-source-edit' -Encoding UTF8
        (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id | Should -Not -Be $d0 -Because 'a SOURCE edit MUST flip the identity (no false-allow of un-reviewed source)'
    }

    It 'detects a TRACKED change (tree-id flips)' {
        $repo = New-DigestRepo 'tracked-drift'
        $before = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'tracked v1' -Encoding UTF8
        $after = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $after | Should -Not -Be $before
    }

    It 'detects a GITIGNORED-SOURCE change (closes HOLE A)' {
        $repo = New-DigestRepo 'gitignored-drift'
        $before = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        Set-Content -LiteralPath (Join-Path $repo 'gen/logic.py') -Value 'def src(): evil()' -Encoding UTF8
        $after = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $after | Should -Not -Be $before
    }

    It 'ignores a change to an excluded secret (no noise, no leak)' {
        $repo = New-DigestRepo 'secret-stable'
        $before = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        Set-Content -LiteralPath (Join-Path $repo '.env') -Value 'SECRET=changed' -Encoding UTF8
        $after = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $after | Should -Be $before
    }

    It 'reports the empty-tree id for a repo with no reviewable content' {
        $repo = Join-Path $TestDrive 'empty'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Invoke-DigestGit $repo @('init', '-q')
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d.ok | Should -Be $true
        $d.tree_id | Should -Be (Get-ContinuousCoReviewEmptyTreeId)
        $d.is_empty | Should -Be $true
    }

    It 'denylist excludes true secret FILES and ambient dirs, but NOT source named like a secret (F1)' {
        $deny = Get-ContinuousCoReviewSecretAmbientDenylist
        # excluded: true secret files + ambient dirs
        (Test-ContinuousCoReviewDigestPathDenied -Path '.env' -Denylist $deny) | Should -Be $true
        (Test-ContinuousCoReviewDigestPathDenied -Path 'conf/app.key' -Denylist $deny) | Should -Be $true
        (Test-ContinuousCoReviewDigestPathDenied -Path 'node_modules/left-pad/index.js' -Denylist $deny) | Should -Be $true
        # F1: legitimately-named SOURCE must NOT be over-matched out of the gate identity
        (Test-ContinuousCoReviewDigestPathDenied -Path 'src/credentials.ts' -Denylist $deny) | Should -Be $false
        (Test-ContinuousCoReviewDigestPathDenied -Path 'lib/secret-rotation.go' -Denylist $deny) | Should -Be $false
        (Test-ContinuousCoReviewDigestPathDenied -Path 'app/components/CredentialForm.tsx' -Denylist $deny) | Should -Be $false
        (Test-ContinuousCoReviewDigestPathDenied -Path 'gen/logic.py' -Denylist $deny) | Should -Be $false
    }

    It 'T017: the SIX named review-closeout scaffolder artifacts under specs/*/iterations/*/ are excluded, but any OTHER ignored .pending (real source, or an unlisted iteration .pending) STAYS in the digest (path+name specific, no false-allow)' {
        $deny = Get-ContinuousCoReviewSecretAmbientDenylist
        # (1) the six known closeout scaffolder artifacts under an iteration dir ARE excluded (must not enter the
        # digest identity NOR the reviewer worktree materialized from the digest tree).
        (Test-ContinuousCoReviewDigestPathDenied -Path 'specs/198-beta2-hardening/iterations/001/code-map.md.pending' -Denylist $deny) | Should -Be $true
        (Test-ContinuousCoReviewDigestPathDenied -Path 'specs/198-beta2-hardening/iterations/003/coverage-evidence.md.pending' -Denylist $deny) | Should -Be $true
        (Test-ContinuousCoReviewDigestPathDenied -Path 'specs/foo/iterations/002/dashboard.md.pending' -Denylist $deny) | Should -Be $true
        (Test-ContinuousCoReviewDigestPathDenied -Path 'specs/foo/iterations/002/dependency-report.md.pending' -Denylist $deny) | Should -Be $true
        (Test-ContinuousCoReviewDigestPathDenied -Path 'specs/foo/iterations/002/review-diagrams.md.pending' -Denylist $deny) | Should -Be $true
        (Test-ContinuousCoReviewDigestPathDenied -Path 'specs/foo/iterations/002/reviewer-index.md.pending' -Denylist $deny) | Should -Be $true
        # (2) a genuine ignored SOURCE file ending in .pending STILL changes the digest (NOT excluded) - the exact
        # false-allow the global *.pending rule would have introduced.
        (Test-ContinuousCoReviewDigestPathDenied -Path 'src/schema.pending' -Denylist $deny) | Should -Be $false
        # (3) an UNLISTED custom .pending under an iteration dir ALSO stays in the digest (only the six known
        # closeout names are excluded, not the .pending extension nor the iteration path wholesale).
        (Test-ContinuousCoReviewDigestPathDenied -Path 'specs/198-beta2-hardening/iterations/001/custom.md.pending' -Denylist $deny) | Should -Be $false
        # (4) other ignored SOURCE (merely mentioning 'pending', or unrelated) remains reviewable in the identity.
        (Test-ContinuousCoReviewDigestPathDenied -Path 'src/pending-queue.ts' -Denylist $deny) | Should -Be $false
        (Test-ContinuousCoReviewDigestPathDenied -Path 'lib/pending.go' -Denylist $deny) | Should -Be $false
    }

    It 'correctness: tracked source under bin/ or named *.key/*.token stays in the identity and its drift flips it (false-allow fix)' {
        $repo = New-DigestRepo 'identity-source'
        New-Item -ItemType Directory -Path (Join-Path $repo 'bin') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'bin/tool.sh') -Value 'echo ok' -Encoding UTF8
        New-Item -ItemType Directory -Path (Join-Path $repo 'src/lexer') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'src/keymap.key') -Value 'KEY=A' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repo 'src/lexer/scan.token') -Value 'TOK=1' -Encoding UTF8
        Invoke-DigestGit $repo @('add', '-A'); Invoke-DigestGit $repo @('commit', '-q', '-m', 'source')
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $names = Get-TreeNames -Root $repo -TreeId $d.tree_id
        ($names -contains 'bin/tool.sh') | Should -Be $true        # script source, NOT stripped
        ($names -contains 'src/keymap.key') | Should -Be $true     # *.key source, NOT stripped
        ($names -contains 'src/lexer/scan.token') | Should -Be $true
        $before = $d.tree_id
        Set-Content -LiteralPath (Join-Path $repo 'bin/tool.sh') -Value 'echo evil' -Encoding UTF8
        (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id | Should -Not -Be $before   # drift detected -> no false-allow
    }

    It 'strips a LARGE .specify subtree via CHUNKED batched git (identity-preserving at >ChunkSize)' {
        # iter-006 live-e2e PERF fix: the strip step ran one `git rm --cached` PER path -> ~24s on a
        # deployed .specify (172 files) -> the navigator blew the dispatcher's ~20s budget and NEVER fired
        # in any real project. Now batched + chunked (ChunkSize 200). Adding a 250-file .specify subtree
        # (TWO chunks) must leave the tree-id UNCHANGED - the chunked strip removes EXACTLY .specify and
        # nothing else (identity-preserving).
        $repo = New-DigestRepo 'large-specify'
        $before = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $specDir = Join-Path $repo '.specify/extensions'
        New-Item -ItemType Directory -Path $specDir -Force | Out-Null
        1..250 | ForEach-Object { Set-Content -LiteralPath (Join-Path $specDir ("f$_.md")) -Value "gov $_" -Encoding UTF8 }
        Invoke-DigestGit $repo @('add', '-A'); Invoke-DigestGit $repo @('commit', '-q', '-m', '250 .specify files')
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d.ok | Should -Be $true
        $names = Get-TreeNames -Root $repo -TreeId $d.tree_id
        @($names | Where-Object { $_ -like '.specify/*' }).Count | Should -Be 0   # ALL 250 stripped (chunked)
        $d.tree_id | Should -Be $before                                          # identity-preserving at scale
    }

    It 'F1 regression: source named like a secret stays in the tree-id and its drift flips the digest' {
        $repo = New-DigestRepo 'f1-source'
        Set-Content -LiteralPath (Join-Path $repo 'credentials.ts') -Value 'export const auth = () => ok()' -Encoding UTF8
        Invoke-DigestGit $repo @('add', 'credentials.ts'); Invoke-DigestGit $repo @('commit', '-q', '-m', 'add source')
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        (Get-TreeNames -Root $repo -TreeId $d.tree_id) -contains 'credentials.ts' | Should -Be $true   # NOT stripped
        $before = $d.tree_id
        Set-Content -LiteralPath (Join-Path $repo 'credentials.ts') -Value 'export const auth = () => evil()' -Encoding UTF8
        (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id | Should -Not -Be $before   # drift detected
    }

    It 'filemode=false regression: tracked 100755 entrypoints keep the executable bit in the digest tree (no fabricated mode diff)' {
        # The recurring co-review phantom / DRIFT-198-I001-001: on core.filemode=false hosts the digest
        # staged into a FRESH index, so tracked 100755 entrypoints (bin/*, install.sh) silently became
        # 100644 and the baseline->digest diff fabricated a mode regression on every shipped wrapper.
        # (Regression reused from Devin ec90e1b6, T034b partial.)
        $repo = New-DigestRepo 'filemode-exec'
        Invoke-DigestGit $repo @('config', 'core.filemode', 'false')
        Set-Content -LiteralPath (Join-Path $repo 'run.sh') -Value "#!/bin/sh`necho ok" -Encoding UTF8
        Invoke-DigestGit $repo @('add', 'run.sh')
        Invoke-DigestGit $repo @('update-index', '--chmod=+x', 'run.sh')
        Invoke-DigestGit $repo @('commit', '-q', '-m', 'exec entrypoint')
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d.ok | Should -Be $true
        Push-Location -LiteralPath $repo
        try {
            $mode = ([string](@(& git ls-tree $d.tree_id run.sh 2>$null) | Select-Object -First 1)).Split(' ')[0]
            $mode | Should -Be '100755'
            @(& git diff HEAD $d.tree_id 2>$null | Where-Object { $_ -like 'old mode*' }).Count | Should -Be 0
        }
        finally { Pop-Location }
    }
}
