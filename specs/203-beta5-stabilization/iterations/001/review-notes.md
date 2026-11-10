# Iteration 001: notes for the iteration review

Points the maintainer asked the reviewer to check, beside the iteration's own scope. Each names the commit and what to
look at.

## Test and test-harness changes made while building T006

1. **The dispatcher's visible-line guard** (`ed7cd1b5`, `extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1`
   and its twins). `Write-InjectionOutput` and `Write-StopBlockOutput` call `Add-DispatcherVisibleLineField` only when
   the host binding names a visible field and there are lines to show. The guard was added because
   `codex-stop-gate-fail-open` lifts the two emitters out of the dispatcher's syntax tree without the helper, and every
   call failed there. Check: that the guard never drops a line on a host with a field (`not-recorded-report` case 8 is
   the end-to-end case), and that the lifted-emitter suite is not hiding a real dependency, since it now never runs the
   field path.
2. **`tests/bootstrap/DeployedHostConfig.Tests.ps1`** (`ed7cd1b5`). Red since T002's project launcher (DRIFT-016) and in
   no lane, so nothing ran it. It reads the committed `.claude/settings.local.json`; the deployed command now runs
   `.claude/specrew-hook-launch.ps1`, so the check follows the decoded command to the launcher it names and looks for
   the dispatcher there. Check: that this still proves what the suite is for (the on-disk config dispatches Stop and
   PostToolUse), and that it cannot pass when the command names no launcher (it then reads the command alone, as before).

Also changed by T006, for the same review:

3. **`message-identity` (3 cases) and `verdict-pairing` case 6** (`ed7cd1b5`): a report a turn end writes is now said at
   that turn end (FR-026), so these read the line from the turn end's output and check the next message does not repeat
   it, where they used to read it from the next message.
4. **`hook-command-length`** (committed with this note): the launcher's missing-dispatcher refusal is plain text
   with new words (DRIFT-018 follow-up), and the assertion matches them.
5. **The already-approved line** (DRIFT-039 item a; committed with this note) says "nothing was recorded from this reply", which `verdict-pairing`
   case 4b reads as a report.

## Demoted findings count at the reviewer's severity (maintainer ruling, 2026-11-10; DRIFT-052)

This review runs on the pinned engine (`bd4635df`). Its reviewer prompt never asks for the literal `Failure scenario:`
clause its ingest requires (B5F-017; fixed on this branch in `d3ab3f21`, live only at T014), so a blocking or major
finding that states its scenario in prose is recorded as minor. For this review:

1. Every demoted finding is treated at the severity the reviewer reported: the result's `demoted_from`, which the
   sign-off listing also shows ("the reviewer reported it as ...").
2. The crew fixes each one within the approved tasks, as it would a finding recorded at that severity.
3. The crew does not ask for review sign-off while any demoted finding is unfixed.
