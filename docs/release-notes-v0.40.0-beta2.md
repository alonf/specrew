# Specrew v0.40.0-beta2 Release Notes

`v0.40.0-beta2` is the Beta2 prerelease for the `0.40.0` line. It combines Continuous Co-Review
(Feature 197) with the Beta2 hardening and release finish line from Feature 198. It is a prerelease,
not a stable promotion.

## Highlights

- Boundary authorization integrity works end to end on a brand-new project: the first lifecycle
  boundary is recorded before any approval is demanded, every approval prompt is generated from
  recorded state (never inferred by the agent), and every recorded approval binds to a crossing
  that actually exists. One approval advances exactly one boundary, captured from your actual
  typed reply.
- Repository-owned verification plans run against a frozen disposable target and join evidence only at an exact
  commit and canonical reviewed-state digest.
- Claude, Codex, Copilot, Cursor, and Antigravity reviewer adapters share a strict file-primary JSON contract,
  immutable run accounting, bounded runtime, verified containment/termination, and explicit currentness.
- Downstream setup and update are provider-aware and deny-by-default, with hash-guarded healing and separate
  greenfield/brownfield behavior.
- Stop/capture ownership is isolated across concurrent sessions, and material-change reporting compares live Git
  and content fingerprints instead of treating all existing worktree dirt as work from the current turn.
- Cross-platform path identity derives case sensitivity from the actual volume, verified in CI on
  three real filesystems (NTFS, APFS, ext4), behind a single shared primitive and a differential
  harness whose oracle is the filesystem itself.

## Review Proof

The independently reviewed implementation is commit `9a6b88540088be2ff82fec145079b3f8765e863e`
at canonical digest `eb9643d51780361d1009ba3267e7e14cb011b385`. Claude run
`run-t066-claude-windows-9a6b8854-eb9643d5-11` completed with valid, current, zero-finding
evidence under verified containment and termination. The controller-owned six-file evidence finalization is
commit `3fb3a1fc4640b1e2a468a56d8dbad91a8cc67466`, whose exact CI run `29785802064` passed all
eight jobs. Review signoff was then recorded in commit `923b16b4fb03db7eea0f61ad1538504e387cc605`.

The Beta2 tag candidate itself was certified by three consecutive independent reviews culminating
in `run-f198-beta2-0fa26271-certify` at commit `0fa26271`, canonical digest `4928a36f` —
completion `complete`, currentness `current`, five findings, each adjudicated under the
maintainer's 2026-08-09 trajectory ruling: two long-known documented residuals, one re-report
against the documented link limitation, and two routed to beta3 design owners as release-claim
limitations 12 and 13. Findings from the two prior rounds (`run-f198-beta2-c0c3cda6-certify`,
`run-f198-beta2-4e7d002c-certify`) were fixed in-tree with instance-pinned regression suites
before this terminal. The tree from certified head `0fa26271` to tag commit `67a5d7bc` differs by
15 files, zero of them code — all documentation plus the repository-governance record
(`.specrew/repository-governance.yml`) carried by the merge target's own reviewed history.

*Correction, 2026-08-10: the sentence above is the measured statement, transcribed from the
post-merge measurement recorded on PR #3318. The copy of these notes pinned at tag
`v0.40.0-beta2` predates the correction and reads "differs by documentation only".*

## Known issues in this beta

Each item lists the impact and the working way around it. The full technical record — detection
commands, the threat model, and who exactly is affected — lives in the release claim inside the
repository (`specs/198-beta2-hardening/beta2-release-claim.md` on this tag).

1. **The review evidence store can follow filesystem links during enumeration.** Impact: entries
   reached through a link (symlink, junction, or cloud placeholder) beneath the review evidence
   store can be read as evidence even when they point outside it — and a branch you check out can
   carry such links in its commits. Workaround: keep the project tree, especially
   `.specrew/review/`, free of links and junctions; check with `git ls-files -s | grep 120000`
   (POSIX) or `dir /AL /S` (Windows); avoid checking out untrusted branches into governed projects.
2. **Filesystem-link states are not covered by the path test harness.** Impact: behavior around
   symlinks and dangling links rests on untested paths, so link-heavy trees carry extra risk.
   Workaround: the same as issue 1 — avoid links inside the project tree.
3. **Files whose names differ only by letter case may be scanned as one.** Impact: the governance
   advisor may miss a case-distinct duplicate of a policy file. Workaround: avoid case-only
   filename distinctions, especially under `docs/`, `specs/`, and `.github/`.
4. **A configured reviewer model is recorded, not enforced.** Impact: the reviewer host may run a
   different model than the one recorded in your configuration. Workaround: when the model matters,
   verify it in the review run's own report.
5. **A defect you already accepted cannot be marked "known" for a fresh reviewer.** Impact: a new
   review round may re-report a defect you have deliberately accepted, and the review gate has no
   way to record that acceptance. Workaround: keep the acceptance note in your project record and
   expect the re-report until this gains first-class support.
6. **Review rounds share one budget across all checkpoints.** Impact: a lifecycle that produces
   findings at two or more checkpoints spends every round from one shared allowance, so you can
   reach the ceiling sooner than per-checkpoint arithmetic suggests — possibly on every run.
   Workaround: see issue 7 for the working escape when you halt.
7. **The ceiling-halt message suggests a command that fails in the shipped mode.** Impact: at the
   review ceiling, the suggested `specrew review --remediate more-time` throws; six of the seven
   advertised remediation choices fail in the shipped campaign mode. Workaround: start a new
   explicitly authorized review run with a fresh `--authorization-ref <your-new-reference>` — a
   reference you have not used before mints a new grant with a review slot. This is deliberately a
   human decision, because the allowance guards real AI spend.
8. **Closeout checks may not converge unattended.** Impact: findings below the blocking bar route
   to a human turn instead of closing with recorded residuals, and a closeout that writes state
   files can re-trigger its own check. Workaround: budget a human decision at closeout rather than
   expecting it to finish on its own.
9. **Design-decision approvals are transcribed, not hook-captured.** Impact: at the design-analysis
   stop, the approval record is written by the agent (with disclosure) rather than captured from
   your typed reply, because the crossing cannot be created before your decision exists.
   Workaround: read the committed Human Decision text back and confirm it says what you actually
   chose before approving the plan boundary.
10. **A second feature in the same project gets no first-boundary approval prompt.** Impact: after
    a feature closes, the next feature's first boundary cannot create its approval demand, so the
    prompt never appears. Workaround: start the next feature from a fresh checkout or worktree —
    fresh project state initializes the boundary ledger cleanly.
11. **Approval capture is blocked only when missing evidence is confirmed, not when it cannot be
    checked.** Impact: if a stage's evidence is verified absent, your approval is refused and you
    are re-asked once the evidence exists — but when the evidence *cannot be checked at all*
    (degraded or unreadable project state), your approval is still recorded. Workaround: before
    approving, confirm the approval prompt cites concrete committed artifacts; if it says the
    evidence could not be verified, fix the project state before approving rather than approving
    through it.
12. **Folder-name case checks follow the operating system's default, not the disk's.** Impact: on
    a disk whose case sensitivity differs from the platform default (case-sensitive folders on
    Windows, case-sensitive APFS on macOS), two sibling checkouts whose names differ only by
    letter case can be treated as the same location by containment checks. Workaround: avoid
    sibling folders that differ only by case next to governed projects on such disks.

## Beta posture

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
