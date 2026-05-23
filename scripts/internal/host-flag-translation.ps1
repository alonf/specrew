# Per-host flag translation for Specrew multi-host launch path (F-040)
#
# Implements FR-007 (--remote), FR-008 (--allow-all / --autopilot), and the
# host-side mappings documented in specs/040-multi-host-launch-path/research.md
# Task 2.
#
# Translation table (per research.md Task 2):
#
#  | Specrew-side flag | Copilot                    | Claude                              | Codex                       |
#  |-------------------|----------------------------|-------------------------------------|-----------------------------|
#  | --remote          | --remote                   | --remote-control                    | warn-and-continue, drop     |
#  | --allow-all       | --allow-all                | --dangerously-skip-permissions      | --full-auto                 |
#  | --autopilot       | --autopilot                | drop with informational notice      | --full-auto (folds into --allow-all) |
#  | --autonomous      | (Specrew-side only — handled by lifecycle boundary enforcement; not translated per-host)        |
#
# Each translation arm returns:
#   - Args: string[] — argv tokens to inject (may be empty for drop/warn cases)
#   - Notice: string — human-readable note for the user/dashboard (may be empty)
#   - SuppressWarning: bool — true means do NOT print a console warning even if Args is empty
#
# Get-HostFlagTranslation returns a hashtable keyed by Specrew-side flag with
# the resolved translation object per host. Callers compose Args into the final
# launch invocation.

Set-StrictMode -Version Latest

function Get-HostFlagTranslation {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('copilot', 'claude', 'codex')]
        [string]$HostKind,

        [Parameter(Mandatory = $true)]
        [ValidateSet('--remote', '--allow-all', '--autopilot')]
        [string]$SpecrewFlag
    )

    $hostLower = $HostKind.ToLowerInvariant()

    switch ("$hostLower|$SpecrewFlag") {
        # --remote arms
        'copilot|--remote' {
            return [pscustomobject]@{ Args = @('--remote'); Notice = ''; SuppressWarning = $true }
        }
        'claude|--remote' {
            return [pscustomobject]@{ Args = @('--remote-control'); Notice = "Translated --remote to Claude's --remote-control flag."; SuppressWarning = $true }
        }
        'codex|--remote' {
            return [pscustomobject]@{
                Args = @()
                Notice = "Codex CLI does not expose a remote-control flag today; continuing launch without remote-control wiring."
                SuppressWarning = $false
            }
        }

        # --allow-all arms
        'copilot|--allow-all' {
            return [pscustomobject]@{ Args = @('--allow-all'); Notice = ''; SuppressWarning = $true }
        }
        'claude|--allow-all' {
            return [pscustomobject]@{
                Args = @('--dangerously-skip-permissions')
                Notice = "Translated --allow-all to Claude's --dangerously-skip-permissions flag."
                SuppressWarning = $true
            }
        }
        'codex|--allow-all' {
            return [pscustomobject]@{
                Args = @('--full-auto')
                Notice = "Translated --allow-all to Codex's --full-auto flag."
                SuppressWarning = $true
            }
        }

        # --autopilot arms
        'copilot|--autopilot' {
            return [pscustomobject]@{ Args = @('--autopilot'); Notice = ''; SuppressWarning = $true }
        }
        'claude|--autopilot' {
            return [pscustomobject]@{
                Args = @()
                Notice = "Claude Code has no direct equivalent of Copilot's --autopilot. For unattended runs use --autonomous (Specrew's own flag for lifecycle boundary control)."
                SuppressWarning = $false
            }
        }
        'codex|--autopilot' {
            # Folds into --full-auto (the Codex --allow-all equivalent); avoid double-injection
            return [pscustomobject]@{
                Args = @()
                Notice = "Codex's autopilot equivalent is --full-auto, which is already mapped from --allow-all. --autopilot is a no-op when --allow-all is also set."
                SuppressWarning = $true
            }
        }

        default {
            throw "Unsupported flag translation: HostKind=$HostKind, Flag=$SpecrewFlag"
        }
    }
}
