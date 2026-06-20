$ErrorActionPreference = 'Stop'

# Trace: T065, FR-025, SEC-002, NFR-001, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T065 content-addressed reviewed-state digest (FR-025/SEC-002)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    }

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

    It 'is deterministic for identical content' {
        $repo = New-DigestRepo 'determinism'
        $d1 = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d2 = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d1.ok | Should Be $true
        $d1.tree_id | Should Be $d2.tree_id
        $d1.tree_id | Should Match '^[0-9a-f]{40}$'
    }

    It 'includes gitignored SOURCE in the digest tree' {
        $repo = New-DigestRepo 'gitignored'
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d.ok | Should Be $true
        $d.included_ignored_count | Should BeGreaterThan 0
        $names = Get-TreeNames -Root $repo -TreeId $d.tree_id
        ($names -contains 'gen/logic.py') | Should Be $true
    }

    It 'keeps the .env secret OUT of the digest tree' {
        $repo = New-DigestRepo 'secret-out'
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $names = Get-TreeNames -Root $repo -TreeId $d.tree_id
        ($names -contains '.env') | Should Be $false
    }

    It 'detects a TRACKED change (tree-id flips)' {
        $repo = New-DigestRepo 'tracked-drift'
        $before = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'tracked v1' -Encoding UTF8
        $after = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $after | Should Not Be $before
    }

    It 'detects a GITIGNORED-SOURCE change (closes HOLE A)' {
        $repo = New-DigestRepo 'gitignored-drift'
        $before = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        Set-Content -LiteralPath (Join-Path $repo 'gen/logic.py') -Value 'def src(): evil()' -Encoding UTF8
        $after = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $after | Should Not Be $before
    }

    It 'ignores a change to an excluded secret (no noise, no leak)' {
        $repo = New-DigestRepo 'secret-stable'
        $before = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        Set-Content -LiteralPath (Join-Path $repo '.env') -Value 'SECRET=changed' -Encoding UTF8
        $after = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $after | Should Be $before
    }

    It 'reports the empty-tree id for a repo with no reviewable content' {
        $repo = Join-Path $TestDrive 'empty'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Invoke-DigestGit $repo @('init', '-q')
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $d.ok | Should Be $true
        $d.tree_id | Should Be (Get-ContinuousCoReviewEmptyTreeId)
        $d.is_empty | Should Be $true
    }

    It 'denylist excludes true secret FILES and ambient dirs, but NOT source named like a secret (F1)' {
        $deny = Get-ContinuousCoReviewSecretAmbientDenylist
        # excluded: true secret files + ambient dirs
        (Test-ContinuousCoReviewDigestPathDenied -Path '.env' -Denylist $deny) | Should Be $true
        (Test-ContinuousCoReviewDigestPathDenied -Path 'conf/app.key' -Denylist $deny) | Should Be $true
        (Test-ContinuousCoReviewDigestPathDenied -Path 'node_modules/left-pad/index.js' -Denylist $deny) | Should Be $true
        # F1: legitimately-named SOURCE must NOT be over-matched out of the gate identity
        (Test-ContinuousCoReviewDigestPathDenied -Path 'src/credentials.ts' -Denylist $deny) | Should Be $false
        (Test-ContinuousCoReviewDigestPathDenied -Path 'lib/secret-rotation.go' -Denylist $deny) | Should Be $false
        (Test-ContinuousCoReviewDigestPathDenied -Path 'app/components/CredentialForm.tsx' -Denylist $deny) | Should Be $false
        (Test-ContinuousCoReviewDigestPathDenied -Path 'gen/logic.py' -Denylist $deny) | Should Be $false
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
        ($names -contains 'bin/tool.sh') | Should Be $true        # script source, NOT stripped
        ($names -contains 'src/keymap.key') | Should Be $true     # *.key source, NOT stripped
        ($names -contains 'src/lexer/scan.token') | Should Be $true
        $before = $d.tree_id
        Set-Content -LiteralPath (Join-Path $repo 'bin/tool.sh') -Value 'echo evil' -Encoding UTF8
        (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id | Should Not Be $before   # drift detected -> no false-allow
    }

    It 'F1 regression: source named like a secret stays in the tree-id and its drift flips the digest' {
        $repo = New-DigestRepo 'f1-source'
        Set-Content -LiteralPath (Join-Path $repo 'credentials.ts') -Value 'export const auth = () => ok()' -Encoding UTF8
        Invoke-DigestGit $repo @('add', 'credentials.ts'); Invoke-DigestGit $repo @('commit', '-q', '-m', 'add source')
        $d = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        (Get-TreeNames -Root $repo -TreeId $d.tree_id) -contains 'credentials.ts' | Should Be $true   # NOT stripped
        $before = $d.tree_id
        Set-Content -LiteralPath (Join-Path $repo 'credentials.ts') -Value 'export const auth = () => evil()' -Encoding UTF8
        (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id | Should Not Be $before   # drift detected
    }
}
