# Manual Real-Host Validation: Iteration 001

**Schema**: v1
**Feature**: 197-continuous-co-review
**Iteration**: 001
**Purpose**: Maintainer-performed real-host acceptance for SC-012 before feature closeout. This is not automated live cross-host CI; Proposal 181 plus Proposal 194 own that future lane.

## Prerequisites

- Work in a clean checkout of this feature branch with the development tree module loaded:
  `Import-Module 'C:\Dev\197-continuous-co-review\Specrew.psd1' -Force`
- Set the self-host path for this repository:
  `$env:SPECREW_MODULE_PATH='C:\Dev\197-continuous-co-review'`
- Install and authenticate only the host CLI being tested.
- Use the planted fixture at:
  `file:///C:/Dev/197-continuous-co-review/specs/197-continuous-co-review/iterations/001/planted-design-violation.diff`
- Expected result for every available host: a parseable blocking finding that names the violated design decision: "reviewer host behavior must be reached through the reviewer-host-adapter interface, not direct host-condition branching."

## Per-Host Commands

Replace `<reviewer-command>` with the implemented Proposal 197 reviewer entry point once T043 wires the orchestrator. The maintainer runs the same planted fixture through each available host adapter.

| Host | CLI version command | Reviewer command |
| ---- | ------------------- | ---------------- |
| Claude | `claude --version` | `<reviewer-command> --adapter claude --diff specs/197-continuous-co-review/iterations/001/planted-design-violation.diff` |
| Codex | `codex --version` | `<reviewer-command> --adapter codex --diff specs/197-continuous-co-review/iterations/001/planted-design-violation.diff` |
| Copilot | `copilot --version` | `<reviewer-command> --adapter copilot --diff specs/197-continuous-co-review/iterations/001/planted-design-violation.diff` |
| Cursor | `cursor-agent --version` | `<reviewer-command> --adapter cursor --diff specs/197-continuous-co-review/iterations/001/planted-design-violation.diff` |
| Antigravity | `antigravity --version` | `<reviewer-command> --adapter antigravity --diff specs/197-continuous-co-review/iterations/001/planted-design-violation.diff` |

## Pass/Fail Rule

Pass only when the host returns a valid `FindingsResult` with at least one unresolved `blocking` finding that names the violated design decision. A crash, empty output, malformed output, infrastructure failure, or non-finding result is recorded as fail or not-run with notes.

## Results Table

| Host | CLI Version | Result | Finding ID / Evidence | Notes | Date |
| ---- | ----------- | ------ | --------------------- | ----- | ---- |
| Claude | | | | | |
| Codex | | | | | |
| Copilot | | | | | |
| Cursor | | | | | |
| Antigravity | | | | | |
