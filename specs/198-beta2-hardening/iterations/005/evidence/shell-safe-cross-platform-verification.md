# Cross-platform verification (F-198 Prop-145 hook-health redesign)

Execution record for the Prop-145 hook-health redesign: INDEPENDENT hook-liveness + a NON-PROMOTING
`ambient-path-binding` version diagnostic; a byte-capped, shell-safe, cross-platform probe; the System32 cmd.exe
interpreter for Windows shims. Hook health is MONITORING evidence, not authentication — the receipt store is
project-writable and the dispatcher can be invoked directly, so `healthy` is operational confidence, never proof of
the host process.

Every claim here is bounded by the digest-bound MACHINE record — the T018 recorded runs written by
`Invoke-ContinuousCoReviewRecordedRun` to the co-review evidence store keyed by the committed reviewed digest and
INJECTED into the reviewer worktree as `.review/implementer-evidence.json`. This document does NOT restate machine
fields (command/args/timestamps/exit-codes/output-hashes/reviewed-digest) as prose; those live in the injected
record and are spot-checkable there. It records the REPLAYABLE COMMANDS and a summary no stronger than that record.

## Replayable commands (committed; replayable from a fresh checkout)

- **Windows + Linux, focused:** `pwsh -File tests/cross-platform-verify.ps1` — runs the hook-health unit suites
  (`hook-health-receipt`, `codex-headless-preflight`, `host-support-reconciliation`, `test-evidence-recorder`) plus
  the production-path integration script, and exits 0 iff all are green. Recorded via T018 as two runs (Windows and
  Linux, keyed distinctly by `-Label`) against the committed reviewed digest.
- **Windows, full:** `pwsh -File tests/f198-regression-suite.ps1` — the full F-198 honesty regression suite.
- **Linux execution:** the committed `pwsh -File tests/cross-platform-verify.ps1 -Label linux` is run against the
  SAME committed tree in `mcr.microsoft.com/powershell:latest` (pwsh 7.4.2) with the repository mounted at `/repo`
  and cwd `/repo` (`git` + Pester 5.6.1 provisioned in the container; a normal dev checkout / the ubuntu CI already
  have both) — proving the committed command replays from a fresh checkout.

## What the runs verify (no stronger than the injected record)

- The redesign passes on BOTH Windows and Linux: hook-liveness (`healthy | stale | malformed | conflicting |
  absent`) is INDEPENDENT of the version diagnostic (`diagnostic-match | diagnostic-drift | unavailable |
  untrusted-source`); a substituted PATH shim stays a non-promoting diagnostic and cannot move hook-liveness or
  readiness; a fresh receipt is operational-`healthy` even when the version is `unavailable`; malformed / stale /
  conflicting / wrong-host / wrong-contract receipts never read healthy; the byte-cap fails closed on oversized
  stdout/stderr and kills the process tree on timeout; the Windows interpreter-hijack + injection-guard hold; and
  no report/preflight output describes the receipt as authenticated, unforgeable, or proof of the host process.
- The Windows-only interpreter/injection-guard falsifications are `-Skip`ped on Linux (no `.cmd`/cmd.exe there); the
  probe there is genuinely shell-free (native binary / shebang script exec'd directly).

## Verifying the injected evidence

At review time `Copy-ContinuousCoReviewImplementerEvidence` reads the digest-keyed record from the real repository and
writes it to `.review/implementer-evidence.json` (the reviewer-visible, integrity-hashed bridge across the stripped
runtime store). The reader now accepts T018 `runs` records (the T019 step-6 unblock), so the recorded Windows + Linux
runs are the reviewer's authoritative machine evidence — spot-checkable there, not restated in this prose.
