# T014: The Held Scripts, Read and Run (Stop for the Maintainer)

Feature 206, iteration 001, task T014 (FR-012; SC-001, SC-007). Written 2026-11-12 on `257bc79c` (T013).

The 36 scripts are the census's held list (`tests/support/test-census.ps1`): tests that no lane, CI step or registry
ran. They are the bug list's 35 integration scripts less the empty `_ctl-spec.ps1` (now a listed exclusion), plus two
manual scripts. Each was read before anything ran: for the home folder (any write, and above all the hook files), for
`specrew-update`, for hook deployment and for `specrew start` and `init`. Every script that ran was run alone, with the
home hook files hashed before and after it and `git status` compared. Nothing is registered before the maintainer
rules.

## Summary

| Group | Count | Run here |
| --- | --- | --- |
| Read safe, green | 18 | yes |
| Read safe, red | 1 | yes |
| Read safe, held for the maintainer (path previously unread) | 2 | no |
| Writes the home folder | 10 | no |
| Unsure | 1 | no |
| On the never-run list | 4 | no |
| **Total** | **36** | 19 run |

The home hook files were unchanged after each of the 19 runs (SC-007), and the repository's `git status` was unchanged
after each.

## Read Safe and Run

Durations are wall-clock on this machine, each script alone.

| Script (`tests/integration/`) | Result | Seconds |
| --- | --- | --- |
| `brownfield-merge.ps1` | green | 3 |
| `carry-forward-closed-iteration.ps1` | green | 1 |
| `concurrency-sizing.ps1` | green | 7 |
| `descriptive-reference-authored-prose.ps1` | green | 1 |
| `descriptive-reference-excluded-surfaces.ps1` | green | 1 |
| `feature-018-render-budget.ps1` | green | 3 |
| `gap-governance.ps1` | green | 12 |
| `hardening-gate-contract.ps1` | green | 1 |
| `lockout-chain-cap.ps1` | green | 1 |
| `mechanical-findings-contract.ps1` | green | 1 |
| `quality-evidence-governance.ps1` | green | 15 |
| `quality-profile-foundation.ps1` | green | 2 |
| `reviewer-artifacts.ps1` | green | 8 |
| `reviewer-closeout-governance.ps1` | green | 10 |
| `reviewer-regression-event.ps1` | green | 4 |
| `reviewer-regression-ledger.ps1` | green | 6 |
| `reviewer-regression-withdrawal.ps1` | green | 2 |
| `validator-hardening-iteration1.ps1` | green | 98 |
| `substantive-interaction-model-iteration2.ps1` | **red** | 1 |

What they reach: the validator, the scaffold scripts, the reviewer-regression ledger, the hardening and lens readers,
on copies in `.scratch/` (gitignored) or a temp folder; local `git init` and commits with `-c` identity, never
`--global`. One read-only touch of the home folder: when a scratch project has no dashboard renderer, the validator and
the scaffolds load the installed Specrew module's renderer (0.40.0, in the Documents module folder). That code was read
and writes nothing.

**Per-push time if all 18 green scripts were registered:** 176 seconds serial on this machine;
`validator-hardening-iteration1.ps1` alone is 98 of them, the other 17 take 78. CI runners are slower than this machine.

## Red

- **`substantive-interaction-model-iteration2.ps1`**: "Docs/template truth scenario missing expected pattern 'Feature
  016 Interaction Model' in README.md". The README section was removed by `b27f35c4` ("docs: refresh README +
  getting-started + user-guide", 2026-05-22); the test still expects it. The script stops at its first failure, so
  later assertions are unmeasured. The cause is not one of this feature's items, so it is not fixed here.

## Not Run

### Read safe, held for the maintainer

| Script | Why held |
| --- | --- |
| `feature-017-dashboard-core.ps1` | On the maintainer's "not run (unread path)" list: it runs `scripts/specrew.ps1`. Now read: `where`/`status`, the validator, the scaffolds and the feature-closeout dashboard scaffold, which calls `sync-boundary-state.ps1` and `refocus.ps1`. `sync-boundary-state.ps1` loads feature 203's co-review gate only at the `review-signoff` boundary (`signoff-gate-wiring.ps1:105`), not at feature closeout. `SPECREW_MODULE_PATH` is unset here, so `specrew.ps1` does not dispatch to another tree. No home write found. |
| `feature-018-rich-dashboard.ps1` | Not on the list, but the same `sync-boundary-state.ps1` path; held with it. |

### Writes the home folder

| Script | What writes home |
| --- | --- |
| `specrew-start-auto-continue-preservation.ps1`, `specrew-start-baseline-tracking.ps1`, `specrew-start-change-detector.ps1`, `specrew-start-end-to-end.ps1`, `specrew-start-parameter-handling.ps1`, `specrew-start-pause-and-confirm.ps1` | `scripts/specrew-start.ps1 -NoLaunch` creates `~/.specrew/user-profile.yml` when it is missing (`specrew-start.ps1:3009-3015`, path from `$env:USERPROFILE` in `user-profile.ps1:336-347`); with an interactive console it can also wait on a hidden prompt. The tests do not set `SPECREW_USER_PROFILE_PATH`, the seam that redirects it. No hook deployment, no `specrew-update`, no `specrew-init` on this path. |
| `validator-hardening-iteration2.ps1` (**SC-002**) | The validator part is safe; three cases (lines 378, 387, 400) run `specrew-start.ps1 -NoLaunch`: the same profile write. |
| `project-path-resolution-regression.ps1` (**SC-001**) | Its three paths, read as the plan requires. `specrew-update.ps1 -InfoMode` is the only update mode it uses, and it exits (line 1327) before hook deployment (lines 1357, 1422); it writes nothing to the home folder (`npm view` may write npm's own cache). `specrew start -NoLaunch`: the profile write above. `specrew init -DryRun`: no Specrew home write (hook deployment and profile capture only record "would"), but its Squad capability probe runs a real `squad init --non-interactive` in a probe folder even in a dry run (`squad-deploy.ps1`, `Test-SquadInitSupportsNonInteractive`), plus `copilot`, `gh`, `specify` and `npm` probes: third-party writes to the home folder cannot be ruled out. It also runs `specrew-team.ps1 list` and `specrew-review.ps1 -Json` (not in the plan's description; no home path found). |
| `distribution-module-init.ps1` | Runs `specrew-init` on a scratch copy of the module: `Invoke-RefocusHookDeployment` writes `~/.specrew/specrew-hook-launch.ps1` and the per-host hook files (`specrew-init.ps1:961`). Its skip guard only fires when `specify` or `squad` is missing; both are installed here. |
| `tests/manual/multi-host-smoke.ps1` | Runs the installed `specrew init -NoAgents` and `specrew start`; init deploys hooks. Probable separate bug: `foreach ($host in $Hosts)` assigns to PowerShell's read-only `$Host`. |

The profile write is conditional: `~/.specrew/user-profile.yml` exists on this machine, so today those paths would only
read it. They are still home writers by the rule.

### Unsure

- **`distribution-module-publish.ps1`**: the repository code never touches the home folder, but PowerShellGet's
  `Publish-Module -WhatIf` runs its NuGet bootstrap before the `-WhatIf` check, and that can write under
  `%LOCALAPPDATA%`. **Hazard:** its last case runs `publish-stable` with a valid tag and does not clear
  `PSGALLERY_API_KEY`, which the release script reads by default: in a shell with that variable set, it would publish to
  PSGallery for real.

### On the never-run list

`team-management.ps1`, `update-command.ps1`, `validate-baseline-team.ps1`, `tests/manual/copilot-squad-smoke.ps1`.

## The Census Exclusions

From `tests/support/test-census.ps1`. Fixtures and `tests/support/` are left out by the one listed rule.

| File | Reason |
| --- | --- |
| `tests/full-powershell-test-sweep.ps1` | runner, not a suite: the release full sweep; it runs this census |
| `tests/f198-regression-suite.ps1` | runner, not a suite: the curated F-198 registry; Specrew CI runs it, so the scripts it lists count as named |
| `tests/f198-iteration006-foundation.ps1` | runner, not a suite: runs a fixed list of suites that are each named in their own right |
| `tests/cross-platform-verify.ps1` | runner, not a suite: the cross-platform verification entry point |
| `tests/bootstrap/TurnRecordTestSupport.ps1` | support helper outside `tests/support/`: dot-sourced by the bootstrap suites |
| `tests/integration/refocus-dispatcher-fixture.ps1` | support helper outside `tests/support/`: the governed-project fixture of the refocus suites |
| `tests/host-probes/deployed-hook-harness.ps1` | support helper: dot-sourced by the host-binding suites and the probes |
| `tests/host-probes/probe-fixture-redaction.ps1` | support helper: dot-sourced by the payload probe and its fixture checks |
| `tests/host-probes/codex-stop-contract-probe.ps1` | live host probe, run by hand: drives the real Codex CLI |
| `tests/host-probes/copilot-hook-firing-probe.ps1` | live host probe, run by hand: drives the real Copilot CLI |
| `tests/host-probes/host-payload-capture-probe.ps1` | live host probe, run by hand: records real host payloads |
| `tests/host-probes/walk-capture-hook.ps1` | not a test: a capture hook installed for a live walk |
| `tests/integration/_ctl-spec.ps1` | empty 0-byte file; deleted by T016 (iteration 002) |

## Files Feature 203 Also Changed

206's changes to them so far, against the branch base `d3e33550`:

- `.specrew/release-gate-suites.txt`: 11 added lines, nothing removed: a two-line comment naming 206's tasks, a blank
  line, and 8 suites (`recovery-choice-no-console`, `overclaim-dirty-check-separator`,
  `instruction-classifier-managed-blocks`, `iteration-closed-definition`, `legacy-frozen-judged-by-nothing`,
  `closed-check-since-and-ruling`, `review-verdict-names-status`, `nightly-tracking-issue`, all
  `tests/unit/*.tests.ps1`).
- `.specrew/verification-plan.json`: unchanged.
