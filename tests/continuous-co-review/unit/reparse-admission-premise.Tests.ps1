#Requires -Modules Pester

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# THE PREMISE GUARD for the maintainer's ruling of 2026-08-11 (DRIFT-199-I001-024, -031).
#
# The ruling admits a reparse point that is neither a link nor a cloud placeholder, and rests the trust
# on the hash of the bytes actually read. That is only sound while ONE premise holds:
#
#     nothing downstream of the classifier EXECUTES what the classifier admitted.
#
# Read a redirected file and the hash describes the bytes you read - it is self-consistent whatever the
# reparse point pointed at, and containment still bounds where you looked. EXECUTE it and the hash
# describes something you have already run. The whole argument turns on that one word, and until this
# file existed the word lived only in a comment. Rule 3: comments record intent, they do not enforce it.
#
# WHAT DEFINES THE SET (rule 2). Not a list of files. The set is derived: every function, in every engine
# script, whose body calls the classifier. A new consumer written next month is covered without anyone
# remembering this file exists, and the count is asserted as a FLOOR - an exact count over a discovered
# set is the defect the fourth rule names.
#
# WHY THE AST AND NOT A REGEX. Two source guards this iteration were rewritten after failing to guard
# what they claimed; the first sliced a function body with `.*?\n\}` and stopped at the first nested
# brace. A parser knows where a function ends. It also gets the two hardest cases right for free: the
# file-scope `. (Join-Path $PSScriptRoot 'reparse-tag-policy.ps1')` dot-source is NOT inside a consuming
# function and must not trip the guard, while a `&` or `.` invocation inside one must.
#
# AND IT ASSERTS WHAT MUST HAPPEN, NOT ONLY WHAT MUST NOT (rule 4). A file of pure prohibitions is
# satisfied by silence - delete the reading code and every "must not execute" passes. So the positive
# half is pinned too: the admitted path must still read, hash, and containment-check.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $script:ClassifierCommands = @(
        'Get-SpecrewReparseDispositionForItem',
        'Resolve-SpecrewReparseDisposition',
        'Test-SpecrewReparseRefusesRead'
    )

    # Execution primitives. Anything here turns "we hashed the bytes" into "we ran the bytes".
    $script:ExecutionCommands = @(
        'Invoke-Expression', 'iex', 'Invoke-Command', 'Start-Process', 'Start-Job',
        'Import-Module', 'Add-Type', 'New-Module', 'Invoke-Item'
    )

    function script:Get-EngineScriptPaths {
        Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal') -Recurse -File -Filter '*.ps1' |
            ForEach-Object { $_.FullName }
    }

    function script:Get-FunctionsCallingClassifier {
        # Returns every FunctionDefinitionAst, across the engine, that reaches the classifier - excluding
        # the policy file itself, which DEFINES the classifier rather than consuming its verdict.
        $found = New-Object System.Collections.Generic.List[object]
        foreach ($path in script:Get-EngineScriptPaths) {
            if ((Split-Path -Leaf $path) -eq 'reparse-tag-policy.ps1') { continue }
            $tokens = $null; $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
            if ($null -eq $ast) { continue }
            foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
                $calls = $fn.FindAll({
                        param($n)
                        $n -is [System.Management.Automation.Language.CommandAst] -and
                        $null -ne $n.GetCommandName() -and
                        $script:ClassifierCommands -contains $n.GetCommandName()
                    }, $true)
                if (@($calls).Count -gt 0) {
                    $found.Add([pscustomobject]@{
                            File = (($path.Substring($script:RepoRoot.Length + 1)) -replace '\\', '/')
                            Name = $fn.Name
                            Ast  = $fn
                        }) | Out-Null
                }
            }
        }
        return $found
    }

    $script:Consumers = @(script:Get-FunctionsCallingClassifier)
}

Describe 'the reparse admission premise: admitted content is read, never executed' {

    It 'the consuming set is DISCOVERED, not listed, and is not empty' {
        # A FLOOR, never an exact count. Its only job is to catch the AST query silently matching nothing,
        # which would make every assertion below vacuously true - the precise way a guard lies.
        #
        # THE NUMBER IS MEASURED, NOT ASSUMED, and the first draft of this line proves why that matters:
        # it said 4, from counting call sites in a grep, and the parser said 3. Two of the sites in
        # review-engine-resolution.ps1 sit in the SAME function (the containment walk checks the root and
        # then each segment), and both authority-store sites are in Get-ReviewAuthorityStorePath. Ten call
        # sites, three functions, none at file scope.
        @($script:Consumers).Count | Should -BeGreaterOrEqual 3 -Because 'zero would mean the query broke, not that the risk went away'

        # Membership, not exhaustiveness: a NEW consumer must extend this set silently and still be
        # governed by the prohibitions below. These three must never quietly leave it.
        $names = @($script:Consumers | ForEach-Object { "$($_.File)::$($_.Name)" })
        $names | Should -Contain 'scripts/internal/review-engine-resolution.ps1::Assert-SpecrewReviewRuntimePathContained'
        $names | Should -Contain 'scripts/internal/review-engine-resolution.ps1::Get-SpecrewReviewRuntimeManagedTextSha256'
        $names | Should -Contain 'scripts/internal/continuous-co-review/review-authority-store.ps1::Get-ReviewAuthorityStorePath'
    }

    It 'NO consuming function invokes anything via & or . (the operator form)' {
        foreach ($consumer in $script:Consumers) {
            $invocations = $consumer.Ast.FindAll({
                    param($n)
                    $n -is [System.Management.Automation.Language.CommandAst] -and
                    $n.InvocationOperator -ne [System.Management.Automation.Language.TokenKind]::Unknown
                }, $true)
            foreach ($invocation in $invocations) {
                # A call operator here would execute a path the classifier just admitted.
                throw "$($consumer.File)::$($consumer.Name) invokes via '$($invocation.InvocationOperator)': $($invocation.Extent.Text)"
            }
        }
        # Reached only when no consuming function contains a call-operator invocation at all.
        $true | Should -BeTrue
    }

    It 'NO consuming function calls an execution primitive by name' {
        $offenders = New-Object System.Collections.Generic.List[string]
        foreach ($consumer in $script:Consumers) {
            $commands = $consumer.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
            foreach ($command in $commands) {
                $name = $command.GetCommandName()
                if ($null -ne $name -and $script:ExecutionCommands -contains $name) {
                    $offenders.Add("$($consumer.File)::$($consumer.Name) -> $name") | Out-Null
                }
            }
        }
        @($offenders) -join '; ' | Should -BeExactly '' -Because 'admitted content may be read and hashed; running it is the one thing the ruling does not license'
    }

    It 'NO consuming function builds a scriptblock or invokes a member that runs code' {
        $offenders = New-Object System.Collections.Generic.List[string]
        foreach ($consumer in $script:Consumers) {
            $members = $consumer.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] }, $true)
            foreach ($member in $members) {
                $memberName = [string]$member.Member.Extent.Text
                if ($memberName -in @('Create', 'Invoke', 'InvokeReturnAsIs', 'NewScriptBlock')) {
                    $offenders.Add("$($consumer.File)::$($consumer.Name) -> .$memberName(): $($member.Extent.Text)") | Out-Null
                }
            }
            $blocks = $consumer.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ScriptBlockExpressionAst] }, $true)
            foreach ($block in $blocks) {
                # A scriptblock LITERAL is fine and common (Where-Object/ForEach-Object predicates). What is
                # not fine is composing one from content, which the .Create() check above already covers.
                $null = $block
            }
        }
        @($offenders) -join '; ' | Should -BeExactly '' -Because 'composing a scriptblock from admitted content is executing it by another name'
    }

    It 'THE POSITIVE HALF: the admitted path still reads, hashes, and containment-checks' {
        # Without this, the four prohibitions above are satisfied by deleting the code that reads the file.
        $resolution = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/review-engine-resolution.ps1') -Raw

        $resolution | Should -Match 'ReadAllText' -Because 'the trust rests on the bytes actually read, so they must actually be read'
        $resolution | Should -Match 'SHA256|Sha256' -Because 'the hash is what carries the trust the tag no longer does'
        $resolution | Should -Match 'review-runtime-managed-path-escapes-root' -Because 'containment is the OTHER half of the boundary: read/hash is safe only while it is bounded'
    }

    It 'the REFUSING dispositions still refuse - the ruling narrowed the refusal, it did not remove it' {
        # The ruling admits non-linking reparse points. It does not admit links, and this is the assertion
        # that would fail if a future edit widened admit-nonlinking into admit-everything.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reparse-tag-policy.ps1')

        Test-SpecrewReparseRefusesRead -Disposition 'refuse-link' | Should -BeTrue -Because 'a symlink or junction redirects the read to somewhere containment never checked'
        Test-SpecrewReparseRefusesRead -Disposition 'admit-nonlinking' | Should -BeFalse
        Test-SpecrewReparseRefusesRead -Disposition 'hydrate-cloud' | Should -BeFalse
    }
}
