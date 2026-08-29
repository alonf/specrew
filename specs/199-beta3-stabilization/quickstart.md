# Quickstart: Beta3 Stabilization

**Feature**: 199-beta3-stabilization
**Last verified**: 2026-08-13 — all 105 suites in the explicit F-198 honesty registry passed on the
working tree after `97c6ec49`. That registry covers the signoff decision and wiring, active-campaign
evidence, workshop routing and packet behavior, reviewer setup/write scope, production harness contracts,
and the installed PowerShell wrapper's Windows drive-path forwarding. The fresh, blind consumer walk
remains the release gate.

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

## Iteration 002: try the tag-batch scenarios

1. Empty stage: authorize `iteration-closeout` on a fixture with no next iteration directory; the
   store shows no `iteration-closeout -> plan` crossing, the journal names `plan.md` as owed, and no
   packet offers a verdict.
2. Second session: with a crossing pending, end a turn in another session on any topic; you see one
   line naming the pending crossing and its owner, and no packet demand.
3. Greenfield remote: record `release_model: pr-flow`, `enforcement_mode: manual`, no origin; sync
   `specify`; `pushed-head` and `verdict-commit-durable` both report not-applicable with their
   messages, and the sync proceeds.
4. JSON lens record: write `workshop/product-domain.yml` as JSON and close the lens with
   `confirm-workshop-lens`; the refusal names JSON in one line and keeps the answers.
5. Mirrors: after any crossing on a fixture, open `state.md` and `plan.md`; both agree with the
   store. Hand-edit `plan.md` Status one boundary ahead; the next sync refuses and names it.
6. Closeout: sync `iteration-closeout` on a fixture, then run the validator; no
   `closed-iteration-edited` finding.
7. Leading quote bar: paste `▎ approved for <to>` as a verdict; the capture says what it received
   and what would capture, instead of recording nothing.
