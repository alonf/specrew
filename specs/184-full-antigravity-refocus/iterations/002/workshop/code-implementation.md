# Code Implementation Lens: Iteration 002

**Depth**: medium  
**Confirmation**: human-confirmed / lens-question

## Decision

Use existing Specrew PowerShell, JSON/YAML manifest, Markdown, and Pester-style
test patterns. Do not add a dependency unless a later human decision approves
one. Implementation must follow the workshop decisions, not just create files
that happen to pass shallow checks.

## Implementation Posture

- Prefer one focused instruction-delivery helper over scattering file merge
  logic through init/start/update scripts.
- Reuse or extract the existing managed-block merge pattern when practical;
  minimal duplication is acceptable only if extraction would create larger
  churn.
- Read target paths from host manifest `InstructionsFile`; do not hardcode a
  shared-core host tuple.
- Add one packaged static coordinator template/fragment and include it in
  `Specrew.psd1` `FileList`.
- Keep the managed section delimiters stable and testable.
- Keep generated text shared or source-adjacent so persistent instructions and
  bootstrap do not drift.
- Extend existing host/deploy/bootstrap test suites rather than inventing a new
  harness.

## Test Targets

```text
Instruction deployment tests
    + create missing file
    + preserve user content
    + replace managed section
    + source path from manifest
    + project same Specrew section into AGENTS.md / CLAUDE.md / copilot instructions
    + update refreshes changed managed content
    + start heals missing/stale managed section

Bootstrap tests
    + exact guard present
    + immediate action front-loaded

Firewall tests
    + no shared-core agy literal
    + no shared-core Antigravity routing branch
```
