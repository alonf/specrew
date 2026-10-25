# Iteration 003 review round 2: the files to read

Round 1 (`run-20261021-160210288-728ad1a0`) came back partial because it could not run `git diff` to list the
changes, and it did not read T025, T027 or T029 line by line. This round reads the files below. The task text is
in `specs/202-beta4-1-ux-stabilization/tasks.md` (T025 to T029 and T031's round-1 note).

T025 to T029 landed together in commit `2fd7f2d6`. No later commit changed their product or test files. The
round-1 fix is commit `0f04b5cd`. Round 8's fixes (`ac87d96c`) are not part of this round; they get their own round.

## T025: capture the real payloads (B4F-145)

- `tests/host-probes/host-payload-capture-probe.ps1` (new)
- `tests/host-probes/deployed-hook-harness.ps1` (new; moved out of the binding suite)
- `tests/host-probes/walk-capture-hook.ps1` (new; the capture hook for T030's re-walk)
- `tests/fixtures/hook-payloads/probe/claude/` (fixtures and `provenance.json`)
- `tests/fixtures/hook-payloads/probe/codex/` (fixtures and `provenance.json`)
- `tests/fixtures/hook-payloads/probe/copilot/` (fixtures and `provenance.json`)
- `tests/fixtures/hook-payloads/probe/copilot-claude-hooks/` (fixtures and `provenance.json`)

## T026 and T028 (round 1 spot-checked these; they share files with T027 and T029)

- `hosts/claude/host.psd1`, `hosts/codex/host.psd1`, `hosts/copilot/host.psd1`
- `scripts/internal/specrew-hook-dispatcher.ps1` and its twin `extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1`
- `scripts/internal/deploy-refocus-hooks.ps1` and its twin `extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1`
- `tests/unit/subagent-prompt-authority.tests.ps1` (new; T028)

## T027: a reader for the unrecognized-payload record

- `tests/unit/host-binding-match.tests.ps1` (parts 1 and 1b fail on any record from a recorded payload)
- `tests/host-probes/host-payload-capture-probe.ps1` (fails on any record from a capture)
- `specs/202-beta4-1-ux-stabilization/iterations/002/copilot-rewalk.md` (the re-walk's disk checks count the records)

## T029: product-domain questions in prose (B4F-131)

- `hosts/claude/host.psd1`, `hosts/codex/host.psd1`, `hosts/copilot/host.psd1` (question-tool guidance; Copilot's `QuestionTool`)
- `scripts/internal/coordinator-prompt-surgery.ps1`
- `scripts/internal/launch-contract.ps1`
- `templates/github/agents/squad.agent.md`
- `extensions/specrew-speckit/knowledge/design-lenses/product-domain.md`
- `tests/unit/workshop-question-tool.tests.ps1` (new)

## Round 1's fix: commit `0f04b5cd` (finding `finding-e1a26d059e3c7e32`)

- `extensions/specrew-speckit/scripts/shared-governance.ps1`: `Resolve-SpecrewModuleInternalDirectory`
- `tests/unit/closeout-records-on-approval.tests.ps1`: case 8 (the consumer layout)
- `docs/beta4-findings.md` and `specs/202-beta4-1-ux-stabilization/tasks.md`: records only

## Copies in this project's deployed runtime

The `.specify/extensions/specrew-speckit/...` copies of the dispatcher, the hook deployer and the product-domain
lens were refreshed in `2fd7f2d6`. The runtime refresh for T031 and T032 waits until after this review, so the
deployed `shared-governance.ps1` does not yet match the source; that is expected.
