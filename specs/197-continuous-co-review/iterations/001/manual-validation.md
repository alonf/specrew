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

These commands are maintainer-run only. They keep automated live cross-host CI out of Iteration 001 scope and exercise each real host directly with the same planted design violation prompt. Save each host's parseable JSON response as local evidence if your environment allows it; do not commit raw transcripts, credentials, token stores, or environment dumps.

Use this common prompt text, replacing `<fixture-diff>` with the file content from `specs/197-continuous-co-review/iterations/001/planted-design-violation.diff`:

```text
You are validating Specrew Proposal 197 continuous co-review. Review the following planted diff against specs/197-continuous-co-review/implementation-rules.yml and return only a FindingsResult-compatible JSON object. Expected behavior: report one unresolved blocking finding that names the violated design decision, "reviewer host behavior must be reached through the reviewer-host-adapter interface, not direct host-condition branching." Do not require network, model training, repository auth, or paid services beyond the already-authorized local CLI invocation.

<fixture-diff>
```

| Host | CLI version command | Exact validation command |
| ---- | ------------------- | ------------------------ |
| Claude | `claude --version` | `claude -p "<common prompt text with planted-design-violation.diff content>"` |
| Codex | `codex --version` | `codex exec "<common prompt text with planted-design-violation.diff content>"` |
| Copilot | `copilot --version` | `copilot -p "<common prompt text with planted-design-violation.diff content>"` |
| Cursor | `cursor-agent --version` | `cursor-agent -p "<common prompt text with planted-design-violation.diff content>"` |
| Antigravity | `antigravity --version` | `antigravity -p "<common prompt text with planted-design-violation.diff content>"` |

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
