#!/usr/bin/env pwsh
# EXAMPLE synthesized provider adapter (Feature 182, FR-016).
#
# When a downstream developer names a forge Specrew does not ship an adapter for (e.g. GitLab), the
# Crew SYNTHESISES an adapter on the fly from the ProviderAdapter contract + the GitHub reference,
# and captures it at the project under `.specrew/providers/<forge>.ps1`. This file is the SHAPE such
# a synthesized adapter takes — it is an example, not a shipped GitLab adapter.
#
# SAFETY (DP-S3): a synthesized adapter is READ-ONLY until a human verifies it. It implements
# detect_capability + describe_protection (read-only) only; apply_protection is intentionally a
# refusal stub until a human reviews the generated code and unlocks it. Provenance is recorded.

# provenance: synthesized 2026-06-11 from the ProviderAdapter contract + the github reference; forge=gitlab
# verified: false   # a human MUST review + flip this before apply_protection is permitted

function Get-SpecrewGitLabCapability {
    # read_only. detect_capability for GitLab. Mirrors the GitHub adapter shape but for GitLab's API.
    # Fail-open: no glab/token -> ci-only with an honest constraint.
    [CmdletBinding()] param([string]$ProjectPath = '.')
    if (-not (Get-Command glab -ErrorAction SilentlyContinue)) {
        return [ordered]@{ provider = 'gitlab'; mechanism = 'ci-only'; constraints = @('glab CLI not available; cannot detect GitLab protected-branch capability — the CI work-kind check still runs (ci-only).') }
    }
    # A verified adapter would query the GitLab API (protected branches, MR approvals) here.
    return [ordered]@{ provider = 'gitlab'; mechanism = 'ci-only'; constraints = @('synthesized GitLab adapter is READ-ONLY until human-verified; reporting ci-only honestly until then.') }
}

function Invoke-SpecrewGitLabApplyProtection {
    # GUARDED + read-only-until-verified: a synthesized, unverified adapter ALWAYS refuses apply.
    [CmdletBinding()] param($Governance, [switch]$Approved, [switch]$Execute)
    return [ordered]@{ applied = $false; reason = 'synthesized GitLab adapter is unverified + read-only by default; apply_protection refused until a human reviews this generated code and sets verified=true (DP-S3).' }
}
