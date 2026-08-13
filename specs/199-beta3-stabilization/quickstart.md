# Quickstart: Beta3 Stabilization

**Feature**: 199-beta3-stabilization
**Last verified**: 2026-08-13 — all 103 committed-tree regression suites passed at `182db92b`;
the fresh, blind consumer walk remains the release gate.

## Run it

```powershell
# in a fresh consumer project
specrew init                      # scaffolds .specrew/verification-plan.json (FR-012)
specrew review --host <claude|codex|copilot|cursor-agent|antigravity> --authorization-ref workshop-<feature>
                                  # one-time reviewer setup; no provider spend
specrew review --live --approve-round
                                  # human-authorized provider spend: exactly one campaign round
```

The full lifecycle walk is not unattended. The code-implementation workshop selects and authorizes the
reviewer before specify; it stops again at review and waits for the `--approve-round` command above.
That pause is expected, and every round needs its own authorization.

## Try the canonical scenario (the pause)

1. Run a review campaign round in a project with findings.
2. Expected after the round: the decision surface renders — findings by severity with
   locations, minors marked as saved follow-ups, "Cost so far: N rounds, M minutes",
   budget position "N of 4 used", a one-line recommendation, and three numbered
   options — and the engine EXITS. Nothing runs until you reply.
3. Reply `2` (stop here). Expected: one action completes the final check on your
   files, saves remaining findings as follow-ups, and finishes review sign-off — no
   manual gate untangling.

## Verify the edge cases

- **Budget fuse**: drive 4 reviewer-invoked rounds; the 5th continuation is refused
  until you explicitly reset the allowance.
- **Records-only commit**: after a reviewed state, commit a governance/records file;
  no stale-review block fires.
- **OneDrive install**: with the module under a OneDrive path, a campaign runs
  (placeholders hydrate + verify); a junction inside the tree is still refused with a
  plain-language message.
- **Installed build marker**: resolve the installed module root, dot-source its packaged governance
  library, then resolve the new helper. Use this marker to prove the install contains the beta3 campaign
  gate; the prerelease version string alone does not distinguish stale beta3 builds:

  ```powershell
  $specrewModuleRoot = (Get-Module Specrew -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
  . (Join-Path $specrewModuleRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
  Get-Command Get-SpecrewReviewCampaignEvidenceState -ErrorAction Stop
  ```

- **Broken env_refs**: remove `PATH` from env_refs and run verification; the error
  names `env_refs` and shows the exact line to add.
