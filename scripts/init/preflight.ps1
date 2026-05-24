# Preflight + usage helpers for specrew-init.ps1 (extracted via Proposal 108 Slice 2)
#
# Depends on: scripts/init/_utilities.ps1 (Get-NativeExitCode used inside dependency probes)
#
# Functions:
#   - Test-PreFlightDependencies   probe pwsh7/uv/node/npm/git/gh + collect outdated/missing
#   - Show-Usage                   print specrew init usage text

Set-StrictMode -Version Latest

function Test-PreFlightDependencies {
    param(
        [switch]$IncludeOptional
    )

    $missingDeps = @()
    $outdatedDeps = @()

    # PowerShell 7+
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $missingDeps += [pscustomobject]@{
            Tool = 'PowerShell'
            Current = "$($PSVersionTable.PSVersion)"
            Required = '7.0+'
            Platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
            InstallHint = if ($IsWindows) {
                'Install from https://aka.ms/powershell-release?tag=stable or via winget: winget install Microsoft.PowerShell'
            } elseif ($IsLinux) {
                'Install via package manager or from https://aka.ms/powershell-release?tag=stable'
            } elseif ($IsMacOS) {
                'Install via Homebrew: brew install powershell'
            } else {
                'Install from https://aka.ms/powershell-release?tag=stable'
            }
        }
    }

    # uv (required for Spec Kit)
    $uvCommand = Get-Command 'uv' -ErrorAction SilentlyContinue
    if (-not $uvCommand) {
        $missingDeps += [pscustomobject]@{
            Tool = 'uv'
            Current = 'not installed'
            Required = 'any'
            Platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
            InstallHint = if ($IsWindows) {
                'Install via PowerShell: irm https://astral.sh/uv/install.ps1 | iex'
            } elseif ($IsLinux -or $IsMacOS) {
                'Install via shell: curl -LsSf https://astral.sh/uv/install.sh | sh'
            } else {
                'Install from https://docs.astral.sh/uv/getting-started/installation/'
            }
        }
    }

    # Node.js 24+
    $nodeCommand = Get-Command 'node' -ErrorAction SilentlyContinue
    if (-not $nodeCommand) {
        $missingDeps += [pscustomobject]@{
            Tool = 'Node.js'
            Current = 'not installed'
            Required = '24.0+'
            Platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
            InstallHint = if ($IsWindows) {
                'Install from https://nodejs.org/ or via winget: winget install OpenJS.NodeJS.LTS'
            } elseif ($IsLinux) {
                'Install via package manager or from https://nodejs.org/'
            } elseif ($IsMacOS) {
                'Install via Homebrew: brew install node'
            } else {
                'Install from https://nodejs.org/'
            }
        }
    } else {
        try {
            $nodeVersion = & node --version 2>$null
            if ($nodeVersion -match 'v(\d+)\.') {
                $nodeMajor = [int]$Matches[1]
                if ($nodeMajor -lt 24) {
                    $outdatedDeps += [pscustomobject]@{
                        Tool = 'Node.js'
                        Current = $nodeVersion
                        Required = '24.0+'
                        Platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
                        InstallHint = 'Update from https://nodejs.org/'
                    }
                }
            }
        } catch {}
    }

    # npm 10+
    $npmCommand = Get-Command 'npm' -ErrorAction SilentlyContinue
    if (-not $npmCommand) {
        $missingDeps += [pscustomobject]@{
            Tool = 'npm'
            Current = 'not installed'
            Required = '10.0+'
            Platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
            InstallHint = 'Included with Node.js; install Node.js first'
        }
    } else {
        try {
            $npmVersion = & npm --version 2>$null
            if ($npmVersion -match '(\d+)\.') {
                $npmMajor = [int]$Matches[1]
                if ($npmMajor -lt 10) {
                    $outdatedDeps += [pscustomobject]@{
                        Tool = 'npm'
                        Current = $npmVersion
                        Required = '10.0+'
                        Platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
                        InstallHint = 'Update via: npm install -g npm@latest'
                    }
                }
            }
        } catch {}
    }

    # git 2.30+
    $gitCommand = Get-Command 'git' -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        $missingDeps += [pscustomobject]@{
            Tool = 'git'
            Current = 'not installed'
            Required = '2.30+'
            Platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
            InstallHint = if ($IsWindows) {
                'Install from https://git-scm.com/ or via winget: winget install Git.Git'
            } elseif ($IsLinux) {
                'Install via package manager (e.g., apt install git, yum install git)'
            } elseif ($IsMacOS) {
                'Install via Homebrew: brew install git or Xcode Command Line Tools'
            } else {
                'Install from https://git-scm.com/'
            }
        }
    } else {
        try {
            $gitVersion = & git --version 2>$null
            if ($gitVersion -match 'git version (\d+)\.(\d+)') {
                $gitMajor = [int]$Matches[1]
                $gitMinor = [int]$Matches[2]
                if ($gitMajor -lt 2 -or ($gitMajor -eq 2 -and $gitMinor -lt 30)) {
                    $outdatedDeps += [pscustomobject]@{
                        Tool = 'git'
                        Current = $gitVersion
                        Required = '2.30+'
                        Platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
                        InstallHint = 'Update from https://git-scm.com/ or your package manager'
                    }
                }
            }
        } catch {}
    }

    # gh CLI (optional but recommended)
    if ($IncludeOptional) {
        $ghCommand = Get-Command 'gh' -ErrorAction SilentlyContinue
        if (-not $ghCommand) {
            $missingDeps += [pscustomobject]@{
                Tool = 'gh'
                Current = 'not installed'
                Required = 'any (optional)'
                Platform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
                InstallHint = if ($IsWindows) {
                    'Optional: Install from https://cli.github.com/ or via winget: winget install GitHub.cli'
                } elseif ($IsLinux) {
                    'Optional: Install via package manager or from https://cli.github.com/'
                } elseif ($IsMacOS) {
                    'Optional: Install via Homebrew: brew install gh'
                } else {
                    'Optional: Install from https://cli.github.com/'
                }
            }
        }
    }

    return [pscustomobject]@{
        MissingDeps = @($missingDeps)
        OutdatedDeps = @($outdatedDeps)
        AllOk = ($missingDeps.Count -eq 0 -and $outdatedDeps.Count -eq 0)
    }
}

function Show-Usage {
    @'
specrew init [options]

Options:
  -ProjectPath | --project-path <path>
                         Target project directory (defaults to current directory)
  -DryRun | --dry-run     Show planned changes without writing
  -Force | --force        Skip interactive prompts and use default selections
  -SpecKitVersion | --speckit-version
                         Minimum Spec Kit version (default: 0.8.4)
  -SquadVersion | --squad-version
                         Minimum Squad version (default: 0.9.1)
  -Agents | --agents      Optional DELEGATED agents (orthogonal to --host launch selection): claude | codex | comma list | all. The launch host stays as selected via `specrew start --host <kind>` (default: copilot)
  -NoAgents | --no-agents Disable optional delegated agents. The launch host stays as selected via `specrew start --host <kind>`
  -SkipUpdateCheck | --skip-update-check
                         Skip the PSGallery latest-version check for this run
  -Help | --help          Show usage
'@ | Write-Host
}

