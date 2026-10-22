# Iteration 003 review round 3: the files to read

This round reads two sets of changes. The reviewer may not be able to run `git diff`, so the files are listed here.
The task text is in `specs/202-beta4-1-ux-stabilization/tasks.md`.

## Round 8's fixes: commit `ac87d96c` (iteration 002)

The maintainer's plan instruction for iteration 003: the review round also reads the round-8 fixes. No reviewer has
read them line by line. The commit message names the two findings it fixes.

1. The approval form checked for a condition beside the authority line only on hosts that mark pastes. On Codex and
   Copilot, a partial sign-off above a condition reached the writer and was saved with the condition in its reason.
   The check now runs on every host.
2. The boundary verdict readers classified the raw message. On Claude, an approval on its own line beside a paste was
   refused (FR-029). Both readers now read the message through the approval form for the host.

Files:

- `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`
- `scripts/internal/bootstrap/HandoverStore.ps1`
- `scripts/internal/bootstrap/HumanAuthorityStore.ps1`
- `tests/unit/approval-form.tests.ps1` (the partial sign-off case on all three hosts)
- `tests/integration/verdict-capture-blocks.tests.ps1` (W45: seven cases through both readers)

Later commits `fcc62934` and `cb5be72f` also changed some of these files. Read the files as they are now.

## Round 2's fixes: commit `c503d405`

- `scripts/internal/specrew-hook-dispatcher.ps1` and its twin `extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1`:
  `Test-DispatcherIsSubAgentStop` and its call after the foreign-host stand-down
- `tests/unit/host-binding-match.tests.ps1`: part 1b (a sub-agent's stop stands down) and part 4 (fixtures)
- `tests/host-probes/host-payload-capture-probe.ps1`: the sub-agent stop check, the ISO capture time, the redaction
- `tests/host-probes/probe-fixture-redaction.ps1` (new)
- `tests/unit/closeout-records-on-approval.tests.ps1`: case 8's default-route check
- `tests/fixtures/hook-payloads/probe/*/provenance.json` and the redacted fixtures beside them
