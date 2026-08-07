# Specrew v0.40.0-beta2 Release Notes

`v0.40.0-beta2` is the Beta2 prerelease for the `0.40.0` line. It combines Continuous Co-Review
(Feature 197) with the Beta2 hardening and release finish line from Feature 198. It is a prerelease,
not a stable promotion.

## Highlights

- Repository-owned verification plans run against a frozen disposable target and join evidence only at an exact
  commit and canonical reviewed-state digest.
- Claude, Codex, Copilot, Cursor, and Antigravity reviewer adapters share a strict file-primary JSON contract,
  immutable run accounting, bounded runtime, verified containment/termination, and explicit currentness.
- Downstream setup and update are provider-aware and deny-by-default, with hash-guarded healing and separate
  greenfield/brownfield behavior.
- Stop/capture ownership is isolated across concurrent sessions, and material-change reporting compares live Git
  and content fingerprints instead of treating all existing worktree dirt as work from the current turn.

## Review Proof

The independently reviewed implementation is commit `9a6b88540088be2ff82fec145079b3f8765e863e`
at canonical digest `eb9643d51780361d1009ba3267e7e14cb011b385`. Claude run
`run-t066-claude-windows-9a6b8854-eb9643d5-11` completed with valid, current, zero-finding
evidence under verified containment and termination. The controller-owned six-file evidence finalization is
commit `3fb3a1fc4640b1e2a468a56d8dbad91a8cc67466`, whose exact CI run `29785802064` passed all
eight jobs. Review signoff was then recorded in commit `923b16b4fb03db7eea0f61ad1538504e387cc605`.

## Known Beta Limitations

- **Copilot and Cursor turn attribution is degraded.** Beta2 uses session-baseline semantics over a baseline
  refreshed from live Git state at SessionStart. Degraded output says **currently dirty in the worktree**, never
  **this turn**, and owner-attribution suppression remains active.
- **Cursor clean-current signoff was not obtained.** Free-credit live runs proved adapter and runtime behavior,
  but did not produce clean current approval of the final release candidate. The independent signoff for this
  candidate is the clean Claude run above.
- **Stable promotion is out of scope.** T067 must install and exercise the actually published Beta2 package in a
  fresh consumer and record its result before any separate stable-release decision.

## Install After Publication

```powershell
Install-Module Specrew -RequiredVersion 0.40.0-beta2 -AllowPrerelease -Scope CurrentUser
```

To inspect the Gallery listing without installing:

```powershell
Find-Module Specrew -RequiredVersion 0.40.0-beta2 -AllowPrerelease
```
